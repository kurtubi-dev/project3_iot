import { prisma } from '../../core/database/prisma.client.js';
import { Prisma } from '@prisma/client';

export class GateRepository {
  async findGates(params: {
    skip: number;
    take: number;
    where: Prisma.GateWhereInput;
  }) {
    return prisma.gate.findMany({
      skip: params.skip,
      take: params.take,
      where: params.where,
      orderBy: { createdAt: 'desc' },
      include: {
        device: {
          select: {
            id: true,
            deviceCode: true,
            name: true,
            connectionStatus: true,
            isActive: true,
          },
        },
      },
    });
  }

  async countGates(where: Prisma.GateWhereInput): Promise<number> {
    return prisma.gate.count({ where });
  }

  async findGateById(id: string) {
    return prisma.gate.findUnique({
      where: { id },
      include: {
        device: true,
        commands: {
          take: 5,
          orderBy: { createdAt: 'desc' },
        },
      },
    });
  }

  async findGateByCode(gateCode: string) {
    return prisma.gate.findUnique({
      where: { gateCode },
    });
  }

  async findGateByDeviceId(deviceId: string) {
    return prisma.gate.findUnique({
      where: { deviceId },
    });
  }

  async createGate(data: Prisma.GateCreateInput) {
    return prisma.gate.create({
      data,
      include: {
        device: {
          select: {
            id: true,
            deviceCode: true,
            name: true,
          },
        },
      },
    });
  }

  async updateGate(id: string, data: Prisma.GateUpdateInput) {
    return prisma.gate.update({
      where: { id },
      data,
      include: {
        device: {
          select: {
            id: true,
            deviceCode: true,
            name: true,
          },
        },
      },
    });
  }
}

export const gateRepository = new GateRepository();

