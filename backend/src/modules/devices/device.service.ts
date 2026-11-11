import { deviceRepository, DeviceRepository } from './device.repository.js';
import {
  ListDevicesQuery,
  CreateDeviceInput,
  UpdateDeviceInput,
  UpdateDeviceStatusInput,
} from './device.schema.js';
import { TokenUtil } from '../../core/utils/token.util.js';
import { NotFoundError, ConflictError } from '../../core/errors/app-error.js';
import { logger } from '../../core/logger/logger.js';
import { Prisma } from '@prisma/client';
import crypto from 'crypto';

export class DeviceService {
  constructor(private readonly repo: DeviceRepository = deviceRepository) {}

  async listDevices(query: ListDevicesQuery) {
    const page = query.page;
    const limit = query.limit;
    const skip = (page - 1) * limit;

    const where: Prisma.DeviceWhereInput = {};

    if (query.connectionStatus) {
      where.connectionStatus = query.connectionStatus;
    }

    if (query.isActive !== undefined) {
      where.isActive = query.isActive;
    }

    if (query.search) {
      where.OR = [
        { name: { contains: query.search, mode: 'insensitive' } },
        { deviceCode: { contains: query.search, mode: 'insensitive' } },
        { location: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const [devices, total] = await Promise.all([
      this.repo.findDevices({ skip, take: limit, where }),
      this.repo.countDevices(where),
    ]);

    return {
      devices,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getDeviceById(id: string) {
    const device = await this.repo.findDeviceById(id);
    if (!device) {
      throw new NotFoundError('Perangkat tidak ditemukan', 'DEVICE_NOT_FOUND');
    }
    return device;
  }

  async createDevice(input: CreateDeviceInput, adminId: string) {
    const existing = await this.repo.findDeviceByCode(input.deviceCode);
    if (existing) {
      throw new ConflictError(
        `Perangkat dengan kode '${input.deviceCode}' sudah terdaftar`,
        'DEVICE_CODE_ALREADY_EXISTS'
      );
    }

    // Generate strong 64-char random hex secret
    const rawSecret = crypto.randomBytes(32).toString('hex');
    const secretHash = TokenUtil.hashToken(rawSecret);

    const device = await this.repo.createDeviceWithCredential({
      ...input,
      createdBy: adminId,
      secretHash,
    });

    logger.info(
      { deviceId: device.id, deviceCode: device.deviceCode, adminId },
      'New IoT device registered'
    );

    return {
      device,
      initialSecret: rawSecret, // Displayed once upon creation
    };
  }

  async rotateCredential(deviceId: string, adminId: string) {
    const device = await this.repo.findDeviceById(deviceId);
    if (!device) {
      throw new NotFoundError('Perangkat tidak ditemukan', 'DEVICE_NOT_FOUND');
    }

    const newRawSecret = crypto.randomBytes(32).toString('hex');
    const newSecretHash = TokenUtil.hashToken(newRawSecret);

    await this.repo.rotateCredential(deviceId, newSecretHash, adminId);

    logger.info({ deviceId, adminId }, 'IoT device credentials rotated');

    return {
      deviceId,
      deviceCode: device.deviceCode,
      newSecret: newRawSecret, // Displayed once upon rotation
    };
  }

  async updateDevice(id: string, input: UpdateDeviceInput) {
    const device = await this.repo.findDeviceById(id);
    if (!device) {
      throw new NotFoundError('Perangkat tidak ditemukan', 'DEVICE_NOT_FOUND');
    }

    return this.repo.updateDevice(id, input);
  }

  async updateDeviceStatus(id: string, input: UpdateDeviceStatusInput) {
    const device = await this.repo.findDeviceById(id);
    if (!device) {
      throw new NotFoundError('Perangkat tidak ditemukan', 'DEVICE_NOT_FOUND');
    }

    return this.repo.updateDeviceStatus(id, input.isActive);
  }
}

export const deviceService = new DeviceService();

