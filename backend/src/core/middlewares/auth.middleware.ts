import { Request, Response, NextFunction } from 'express';
import { TokenUtil } from '../utils/token.util.js';
import { UnauthorizedError } from '../errors/app-error.js';
import { prisma } from '../database/prisma.client.js';

export const authenticate = async (
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedError('Header Authorization Bearer token diperlukan');
    }

    const token = authHeader.split(' ')[1];

    if (!token) {
      throw new UnauthorizedError('Token tidak ditemukan');
    }

    let payload;
    try {
      payload = TokenUtil.verifyAccessToken(token);
    } catch {
      throw new UnauthorizedError('Token tidak valid atau telah kedaluwarsa');
    }

    // Verify user existence and active status in database
    const user = await prisma.user.findUnique({
      where: { id: payload.userId },
      select: { id: true, email: true, role: true, status: true },
    });

    if (!user) {
      throw new UnauthorizedError('Pengguna tidak ditemukan');
    }

    if (user.status !== 'ACTIVE') {
      throw new UnauthorizedError('Akun pengguna telah dinonaktifkan');
    }

    req.user = {
      id: user.id,
      email: user.email,
      role: user.role,
      sessionId: payload.sessionId,
    };

    next();
  } catch (error) {
    next(error);
  }
};

