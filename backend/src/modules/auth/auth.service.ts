import { authRepository, AuthRepository } from './auth.repository.js';
import { LoginInput, ChangePasswordInput } from './auth.schema.js';
import { PasswordUtil } from '../../core/utils/password.util.js';
import { TokenUtil } from '../../core/utils/token.util.js';
import { UnauthorizedError, BadRequestError } from '../../core/errors/app-error.js';
import { logger } from '../../core/logger/logger.js';
import { prisma } from '../../core/database/prisma.client.js';

export class AuthService {
  constructor(private readonly repo: AuthRepository = authRepository) {}

  /**
   * Local Email/Password Login
   */
  async login(
    input: LoginInput,
    meta: { ipAddress?: string | null; userAgent?: string | null }
  ) {
    const user = await this.repo.findUserWithAuth(input.email, 'LOCAL');

    if (!user) {
      throw new UnauthorizedError('Email atau password tidak sesuai');
    }

    if (user.status !== 'ACTIVE') {
      throw new UnauthorizedError('Akun pengguna telah dinonaktifkan');
    }

    const localAccount = user.authAccounts[0];
    if (!localAccount || !localAccount.passwordHash) {
      throw new UnauthorizedError(
        'Akun ini tidak memiliki login password lokal. Silakan gunakan metode login yang sesuai.'
      );
    }

    const isPasswordValid = await PasswordUtil.verify(
      localAccount.passwordHash,
      input.password
    );

    if (!isPasswordValid) {
      throw new UnauthorizedError('Email atau password tidak sesuai');
    }

    // Refresh token expiry (7 days)
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    const rawRefreshToken = TokenUtil.generateRefreshToken();
    const refreshTokenHash = TokenUtil.hashToken(rawRefreshToken);

    const session = await this.repo.createSession({
      userId: user.id,
      refreshTokenHash,
      expiresAt,
      ipAddress: meta.ipAddress,
      userAgent: meta.userAgent,
    });

    const accessToken = TokenUtil.generateAccessToken({
      userId: user.id,
      email: user.email,
      role: user.role,
      sessionId: session.id,
    });

    logger.info({ userId: user.id, email: user.email }, 'User logged in successfully');

    return {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
      },
      accessToken,
      refreshToken: rawRefreshToken,
    };
  }

  /**
   * Refresh Token Rotation
   */
  async refreshToken(
    rawRefreshToken: string,
    meta: { ipAddress?: string | null; userAgent?: string | null }
  ) {
    const tokenHash = TokenUtil.hashToken(rawRefreshToken);
    const existingSession = await this.repo.findSessionByHash(tokenHash);

    if (!existingSession) {
      throw new UnauthorizedError('Sesi tidak valid atau telah dicabut');
    }

    if (existingSession.expiresAt < new Date()) {
      await this.repo.revokeSession(existingSession.id);
      throw new UnauthorizedError('Sesi telah kedaluwarsa, silakan login kembali');
    }

    const user = existingSession.user;
    if (user.status !== 'ACTIVE') {
      await this.repo.revokeAllUserSessions(user.id);
      throw new UnauthorizedError('Akun pengguna telah dinonaktifkan');
    }

    // 1. Invalidate/revoke the old session (Rotation)
    await this.repo.revokeSession(existingSession.id);

    // 2. Issue a new refresh token and session
    const newRawRefreshToken = TokenUtil.generateRefreshToken();
    const newRefreshTokenHash = TokenUtil.hashToken(newRawRefreshToken);

    const newExpiresAt = new Date();
    newExpiresAt.setDate(newExpiresAt.getDate() + 7);

    const newSession = await this.repo.createSession({
      userId: user.id,
      refreshTokenHash: newRefreshTokenHash,
      expiresAt: newExpiresAt,
      ipAddress: meta.ipAddress,
      userAgent: meta.userAgent,
    });

    // 3. Issue a new access token
    const newAccessToken = TokenUtil.generateAccessToken({
      userId: user.id,
      email: user.email,
      role: user.role,
      sessionId: newSession.id,
    });

    return {
      accessToken: newAccessToken,
      refreshToken: newRawRefreshToken,
    };
  }

  /**
   * Logout Active Session
   */
  async logout(sessionId?: string) {
    if (sessionId) {
      await this.repo.revokeSession(sessionId);
    }
    return { success: true };
  }

  /**
   * Change Password
   */
  async changePassword(userId: string, input: ChangePasswordInput) {
    const userAccount = await prisma.authAccount.findFirst({
      where: { userId, provider: 'LOCAL' },
    });

    if (!userAccount || !userAccount.passwordHash) {
      throw new BadRequestError('Akun ini tidak memiliki password lokal');
    }

    const isMatch = await PasswordUtil.verify(userAccount.passwordHash, input.oldPassword);
    if (!isMatch) {
      throw new BadRequestError('Password lama tidak sesuai');
    }

    const newHash = await PasswordUtil.hash(input.newPassword);
    await this.repo.updatePasswordHash(userId, newHash);

    // Revoke all sessions to enforce re-login with new password
    await this.repo.revokeAllUserSessions(userId);

    logger.info({ userId }, 'Password updated successfully and all active sessions revoked');
    return { success: true };
  }
}

export const authService = new AuthService();
