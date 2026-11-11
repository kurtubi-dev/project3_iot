import { userRepository, UserRepository } from './user.repository.js';
import {
  ListUsersQuery,
  UpdateUserInput,
  UpdateUserStatusInput,
  InviteUserInput,
} from './user.schema.js';
import { TokenUtil } from '../../core/utils/token.util.js';
import { NotFoundError, ConflictError, BadRequestError } from '../../core/errors/app-error.js';
import { logger } from '../../core/logger/logger.js';
import { Prisma } from '@prisma/client';

export class UserService {
  constructor(private readonly repo: UserRepository = userRepository) {}

  async listUsers(query: ListUsersQuery) {
    const page = query.page;
    const limit = query.limit;
    const skip = (page - 1) * limit;

    const where: Prisma.UserWhereInput = {};

    if (query.role) {
      where.role = query.role;
    }

    if (query.status) {
      where.status = query.status;
    }

    if (query.search) {
      where.OR = [
        { name: { contains: query.search, mode: 'insensitive' } },
        { email: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const [users, total] = await Promise.all([
      this.repo.findUsers({ skip, take: limit, where }),
      this.repo.countUsers(where),
    ]);

    return {
      users,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getUserById(id: string) {
    const user = await this.repo.findUserById(id);
    if (!user) {
      throw new NotFoundError('Pengguna tidak ditemukan');
    }

    return user;
  }

  async updateUser(id: string, input: UpdateUserInput, adminId: string) {
    const user = await this.repo.findUserById(id);
    if (!user) {
      throw new NotFoundError('Pengguna tidak ditemukan');
    }

    const updated = await this.repo.updateUser(id, input);
    logger.info({ userId: id, updatedBy: adminId }, 'User profile updated by admin');
    return updated;
  }

  async updateUserStatus(id: string, input: UpdateUserStatusInput, adminId: string) {
    if (id === adminId && input.status === 'INACTIVE') {
      throw new BadRequestError('Anda tidak dapat menonaktifkan akun Anda sendiri');
    }

    const user = await this.repo.findUserById(id);
    if (!user) {
      throw new NotFoundError('Pengguna tidak ditemukan');
    }

    const updated = await this.repo.updateUserStatus(id, input.status);
    logger.info(
      { userId: id, newStatus: input.status, updatedBy: adminId },
      'User status changed'
    );
    return updated;
  }

  async inviteUser(input: InviteUserInput, adminId: string) {
    const existingUser = await (await import('../../core/database/prisma.client.js')).prisma.user.findUnique({
      where: { email: input.email },
    });

    if (existingUser) {
      throw new ConflictError('Email sudah terdaftar sebagai pengguna sistem');
    }

    const rawToken = TokenUtil.generateRefreshToken(); // 96-char hex
    const tokenHash = TokenUtil.hashToken(rawToken);

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7-day expiration

    const invitation = await this.repo.createInvitation({
      email: input.email,
      name: input.name,
      role: input.role,
      tokenHash,
      expiresAt,
      createdBy: adminId,
    });

    logger.info(
      { invitationId: invitation.id, email: input.email, createdBy: adminId },
      'User invitation created'
    );

    return {
      invitation: {
        id: invitation.id,
        email: invitation.email,
        name: invitation.name,
        role: invitation.role,
        expiresAt: invitation.expiresAt,
        createdAt: invitation.createdAt,
      },
      inviteToken: rawToken, // Provided so it can be sent via email or copied
    };
  }
}

export const userService = new UserService();

