import { sensorRepository, SensorRepository } from './sensor.repository.js';
import {
  ListSensorsQuery,
  CreateSensorInput,
  UpdateSensorInput,
  UpdateSensorStatusInput,
} from './sensor.schema.js';
import { NotFoundError, ConflictError, BadRequestError } from '../../core/errors/app-error.js';
import { logger } from '../../core/logger/logger.js';
import { prisma } from '../../core/database/prisma.client.js';
import { Prisma } from '@prisma/client';

export class SensorService {
  constructor(private readonly repo: SensorRepository = sensorRepository) {}

  async listSensors(query: ListSensorsQuery) {
    const page = query.page;
    const limit = query.limit;
    const skip = (page - 1) * limit;

    const where: Prisma.SensorWhereInput = {};

    if (query.deviceId) {
      where.deviceId = query.deviceId;
    }

    if (query.type) {
      where.type = query.type;
    }

    if (query.isActive !== undefined) {
      where.isActive = query.isActive;
    }

    if (query.search) {
      where.OR = [
        { name: { contains: query.search, mode: 'insensitive' } },
        { sensorCode: { contains: query.search, mode: 'insensitive' } },
        { parameter: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const [sensors, total] = await Promise.all([
      this.repo.findSensors({ skip, take: limit, where }),
      this.repo.countSensors(where),
    ]);

    return {
      sensors,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getSensorById(id: string) {
    const sensor = await this.repo.findSensorById(id);
    if (!sensor) {
      throw new NotFoundError('Sensor tidak ditemukan', 'SENSOR_NOT_FOUND');
    }
    return sensor;
  }

  async createSensor(input: CreateSensorInput) {
    // 1. Verify parent device
    const device = await prisma.device.findUnique({
      where: { id: input.deviceId },
    });

    if (!device) {
      throw new NotFoundError('Perangkat target tidak ditemukan', 'DEVICE_NOT_FOUND');
    }

    if (!device.isActive) {
      throw new BadRequestError(
        'Tidak dapat mendaftarkan sensor pada perangkat yang sedang tidak aktif'
      );
    }

    // 2. Check sensorCode uniqueness
    const existing = await this.repo.findSensorByCode(input.sensorCode);
    if (existing) {
      throw new ConflictError(
        `Sensor dengan kode '${input.sensorCode}' sudah terdaftar`,
        'SENSOR_CODE_ALREADY_EXISTS'
      );
    }

    const sensor = await this.repo.createSensor({
      sensorCode: input.sensorCode,
      name: input.name,
      type: input.type,
      parameter: input.parameter,
      unit: input.unit,
      device: { connect: { id: input.deviceId } },
    });

    logger.info(
      { sensorId: sensor.id, sensorCode: sensor.sensorCode, deviceId: input.deviceId },
      'New sensor registered'
    );

    return sensor;
  }

  async updateSensor(id: string, input: UpdateSensorInput) {
    const sensor = await this.repo.findSensorById(id);
    if (!sensor) {
      throw new NotFoundError('Sensor tidak ditemukan', 'SENSOR_NOT_FOUND');
    }

    return this.repo.updateSensor(id, input);
  }

  async updateSensorStatus(id: string, input: UpdateSensorStatusInput) {
    const sensor = await this.repo.findSensorById(id);
    if (!sensor) {
      throw new NotFoundError('Sensor tidak ditemukan', 'SENSOR_NOT_FOUND');
    }

    return this.repo.updateSensorStatus(id, input.isActive);
  }
}

export const sensorService = new SensorService();

