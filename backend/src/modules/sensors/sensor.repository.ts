import { prisma } from '../../core/database/prisma.client.js';
import { Prisma } from '@prisma/client';

export class SensorRepository {
  async findSensors(params: {
    skip: number;
    take: number;
    where: Prisma.SensorWhereInput;
  }) {
    return prisma.sensor.findMany({
      skip: params.skip,
      take: params.take,
      where: params.where,
      orderBy: { createdAt: 'desc' },
      include: {
        device: {
          select: { id: true, deviceCode: true, name: true, location: true },
        },
      },
    });
  }

  async countSensors(where: Prisma.SensorWhereInput): Promise<number> {
    return prisma.sensor.count({ where });
  }

  async findSensorById(id: string) {
    return prisma.sensor.findUnique({
      where: { id },
      include: {
        device: true,
      },
    });
  }

  async findSensorByCode(sensorCode: string) {
    return prisma.sensor.findUnique({
      where: { sensorCode },
    });
  }

  async createSensor(data: Prisma.SensorCreateInput) {
    return prisma.sensor.create({
      data,
      include: {
        device: {
          select: { id: true, deviceCode: true, name: true },
        },
      },
    });
  }

  async updateSensor(id: string, data: Prisma.SensorUpdateInput) {
    return prisma.sensor.update({
      where: { id },
      data,
    });
  }

  async updateSensorStatus(id: string, isActive: boolean) {
    return prisma.sensor.update({
      where: { id },
      data: { isActive },
    });
  }
}

export const sensorRepository = new SensorRepository();

