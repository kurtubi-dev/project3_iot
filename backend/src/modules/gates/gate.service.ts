import { gateRepository, GateRepository } from './gate.repository.js';
import {
  ListGatesQuery,
  CreateGateInput,
  UpdateGateInput,
  UpdateGateStatusInput,
} from './gate.schema.js';
import { NotFoundError, ConflictError, BadRequestError } from '../../core/errors/app-error.js';
import { logger } from '../../core/logger/logger.js';
import { prisma } from '../../core/database/prisma.client.js';
import { Prisma } from '@prisma/client';

export class GateService {
  constructor(private readonly repo: GateRepository = gateRepository) {}

  async listGates(query: ListGatesQuery) {
    const page = query.page;
    const limit = query.limit;
    const skip = (page - 1) * limit;

    const where: Prisma.GateWhereInput = {};

    if (query.operationalStatus) {
      where.operationalStatus = query.operationalStatus;
    }

    if (query.search) {
      where.OR = [
        { name: { contains: query.search, mode: 'insensitive' } },
        { gateCode: { contains: query.search, mode: 'insensitive' } },
        { location: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const [gates, total] = await Promise.all([
      this.repo.findGates({ skip, take: limit, where }),
      this.repo.countGates(where),
    ]);

    return {
      gates,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getGateById(id: string) {
    const gate = await this.repo.findGateById(id);
    if (!gate) {
      throw new NotFoundError('Pintu irigasi tidak ditemukan', 'GATE_NOT_FOUND');
    }
    return gate;
  }

  async createGate(input: CreateGateInput) {
    // 1. Verify parent device
    const device = await prisma.device.findUnique({
      where: { id: input.deviceId },
    });

    if (!device) {
      throw new NotFoundError('Perangkat target tidak ditemukan', 'DEVICE_NOT_FOUND');
    }

    if (!device.isActive) {
      throw new BadRequestError('Tidak dapat menghubungkan pintu ke perangkat yang tidak aktif');
    }

    // 2. Verify 1:1 Gate-Device relationship
    const existingDeviceGate = await this.repo.findGateByDeviceId(input.deviceId);
    if (existingDeviceGate) {
      throw new ConflictError(
        `Perangkat '${device.deviceCode}' sudah terhubung ke pintu irigasi lain (${existingDeviceGate.gateCode})`,
        'DEVICE_ALREADY_ASSIGNED_TO_GATE'
      );
    }

    // 3. Verify gateCode uniqueness
    const existingCode = await this.repo.findGateByCode(input.gateCode);
    if (existingCode) {
      throw new ConflictError(
        `Pintu dengan kode '${input.gateCode}' sudah terdaftar`,
        'GATE_CODE_ALREADY_EXISTS'
      );
    }

    const gate = await this.repo.createGate({
      gateCode: input.gateCode,
      name: input.name,
      location: input.location,
      actualOpening: input.actualOpening,
      operationalStatus: input.operationalStatus,
      device: { connect: { id: input.deviceId } },
    });

    logger.info(
      { gateId: gate.id, gateCode: gate.gateCode, deviceId: input.deviceId },
      'New irrigation gate registered'
    );

    return gate;
  }

  async updateGate(id: string, input: UpdateGateInput) {
    const gate = await this.repo.findGateById(id);
    if (!gate) {
      throw new NotFoundError('Pintu irigasi tidak ditemukan', 'GATE_NOT_FOUND');
    }

    if (input.deviceId && input.deviceId !== gate.deviceId) {
      const assigned = await this.repo.findGateByDeviceId(input.deviceId);
      if (assigned && assigned.id !== id) {
        throw new ConflictError(
          'Perangkat baru tersebut sudah terhubung ke pintu irigasi lain',
          'DEVICE_ALREADY_ASSIGNED_TO_GATE'
        );
      }
    }

    const updateData: Prisma.GateUpdateInput = {
      ...(input.name && { name: input.name }),
      ...(input.location && { location: input.location }),
      ...(input.deviceId && { device: { connect: { id: input.deviceId } } }),
    };

    return this.repo.updateGate(id, updateData);
  }

  async updateGateStatus(id: string, input: UpdateGateStatusInput) {
    const gate = await this.repo.findGateById(id);
    if (!gate) {
      throw new NotFoundError('Pintu irigasi tidak ditemukan', 'GATE_NOT_FOUND');
    }

    const updateData: Prisma.GateUpdateInput = {
      operationalStatus: input.operationalStatus,
      ...(input.actualOpening !== undefined && { actualOpening: input.actualOpening }),
    };

    const updated = await this.repo.updateGate(id, updateData);
    logger.info(
      { gateId: id, status: input.operationalStatus, opening: input.actualOpening },
      'Gate operational status updated'
    );
    return updated;
  }
}

export const gateService = new GateService();

