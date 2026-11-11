import { prisma } from '../../core/database/prisma.client.js';
import { AuthProvider } from '@prisma/client';

export class AuthRepository {
  async findUserByEmail(email: string) {
    return prisma.user.findUnique({
      where: { email },
    });
  }

  async findUserWithAuth(email: string, provider: AuthProvider = 'LOCAL') {
    return prisma.user.findUnique({
      where: { email },
      include: {
        authAccounts: {
          where: { provider },
        },
      },
    });
  }

  async createSession(data: {
    userId: string;
    refreshTokenHash: string;
    expiresAt: Date;
    ipAddress?: string | null;
    userAgent?: string | null;
  }) {
    return prisma.session.create({
      data: {
        userId: data.userId,
        refreshTokenHash: data.refreshTokenHash,
        expiresAt: data.expiresAt,
        ipAddress: data.ipAddress || null,
        userAgent: data.userAgent || null,
      },
    });
  }

  async findSessionByHash(refreshTokenHash: string) {
    return prisma.session.findFirst({
      where: {
        refreshTokenHash,
        revokedAt: null,
      },
      include: {
        user: true,
      },
    });
  }

  async revokeSession(id: string) {
    return prisma.session.update({
      where: { id },
      data: { revokedAt: new Date() },
    });
  }

  async revokeAllUserSessions(userId: string) {
    return prisma.session.updateMany({
      where: {
        userId,
        revokedAt: null,
      },
      data: { revokedAt: new Date() },
    });
  }

  async updatePasswordHash(userId: string, passwordHash: string) {
    return prisma.authAccount.updateMany({
      where: {
        userId,
        provider: 'LOCAL',
      },
      data: {
        passwordHash,
      },
    });
  }
}

export const authRepository = new AuthRepository();

