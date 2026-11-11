import { prisma } from '../../core/database/prisma.client.js';
import { Prisma } from '@prisma/client';

export class DeviceRepository {
  async findDevices(params: {
    skip: number;
    take: number;
    where: Prisma.DeviceWhereInput;
  }) {
    return prisma.device.findMany({
      skip: params.skip,
      take: params.take,
      where: params.where,
      orderBy: { createdAt: 'desc' },
      include: {
        sensors: {
          select: { id: true, sensorCode: true, type: true, isActive: true },
        },
        gate: {
          select: { id: true, gateCode: true, name: true, operationalStatus: true },
        },
      },
    });
  }

  async countDevices(where: Prisma.DeviceWhereInput): Promise<number> {
    return prisma.device.count({ where });
  }

  async findDeviceById(id: string) {
    return prisma.device.findUnique({
      where: { id },
      include: {
        sensors: true,
        gate: true,
        credentials: {
          where: { revokedAt: null },
          select: { id: true, createdAt: true, expiresAt: true },
        },
      },
    });
  }

  async findDeviceByCode(deviceCode: string) {
    return prisma.device.findUnique({
      where: { deviceCode },
      include: {
        credentials: {
          where: { revokedAt: null },
        },
      },
    });
  }

  async createDeviceWithCredential(data: {
    deviceCode: string;
    name: string;
    description?: string | null;
    location: string;
    createdBy: string;
    secretHash: string;
  }) {
    return prisma.$transaction(async (tx) => {
      const device = await tx.device.create({
        data: {
          deviceCode: data.deviceCode,
          name: data.name,
          description: data.description || null,
          location: data.location,
          createdBy: data.createdBy,
        },
      });

      await tx.deviceCredential.create({
        data: {
          deviceId: device.id,
          secretHash: data.secretHash,
          createdBy: data.createdBy,
        },
      });

      return device;
    });
  }

  async rotateCredential(deviceId: string, newSecretHash: string, adminId: string) {
    return prisma.$transaction(async (tx) => {
      // Revoke any existing active credentials
      await tx.deviceCredential.updateMany({
        where: {
          deviceId,
          revokedAt: null,
        },
        data: {
          revokedAt: new Date(),
        },
      });

      // Create new active credential
      return tx.deviceCredential.create({
        data: {
          deviceId,
          secretHash: newSecretHash,
          createdBy: adminId,
        },
      });
    });
  }

  async updateDevice(id: string, data: Prisma.DeviceUpdateInput) {
    return prisma.device.update({
      where: { id },
      data,
    });
  }

  async updateDeviceStatus(id: string, isActive: boolean) {
    return prisma.device.update({
      where: { id },
      data: { isActive },
    });
  }
}

export const deviceRepository = new DeviceRepository();

