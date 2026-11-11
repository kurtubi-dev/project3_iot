import { prisma } from '../../core/database/prisma.client.js';
import { Prisma, UserRole, UserStatus } from '@prisma/client';

export class UserRepository {
  async findUsers(params: {
    skip: number;
    take: number;
    where: Prisma.UserWhereInput;
  }) {
    return prisma.user.findMany({
      skip: params.skip,
      take: params.take,
      where: params.where,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        status: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  async countUsers(where: Prisma.UserWhereInput): Promise<number> {
    return prisma.user.count({ where });
  }

  async findUserById(id: string) {
    return prisma.user.findUnique({
      where: { id },
      include: {
        authAccounts: {
          select: {
            id: true,
            provider: true,
            providerUserId: true,
            createdAt: true,
          },
        },
      },
    });
  }

  async updateUser(id: string, data: Prisma.UserUpdateInput) {
    return prisma.user.update({
      where: { id },
      data,
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        status: true,
        updatedAt: true,
      },
    });
  }

  async updateUserStatus(id: string, status: UserStatus) {
    return prisma.$transaction(async (tx) => {
      const user = await tx.user.update({
        where: { id },
        data: { status },
        select: {
          id: true,
          name: true,
          email: true,
          role: true,
          status: true,
        },
      });

      // If user is deactivated, revoke all active sessions immediately!
      if (status === UserStatus.INACTIVE) {
        await tx.session.updateMany({
          where: {
            userId: id,
            revokedAt: null,
          },
          data: {
            revokedAt: new Date(),
          },
        });
      }

      return user;
    });
  }

  async createInvitation(data: {
    email: string;
    name: string;
    role: UserRole;
    tokenHash: string;
    expiresAt: Date;
    createdBy: string;
  }) {
    return prisma.invitation.create({
      data,
    });
  }

  async findInvitationById(id: string) {
    return prisma.invitation.findUnique({
      where: { id },
    });
  }
}

export const userRepository = new UserRepository();

