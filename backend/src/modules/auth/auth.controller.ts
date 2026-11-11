import { Request, Response, NextFunction } from 'express';
import { authService, AuthService } from './auth.service.js';
import { ApiResponse } from '../../core/response/api-response.js';
import { UnauthorizedError } from '../../core/errors/app-error.js';

export class AuthController {
  constructor(private readonly service: AuthService = authService) {}

  login = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const result = await this.service.login(req.body, {
        ipAddress: req.ip,
        userAgent: req.get('user-agent'),
      });

      ApiResponse.success(res, result, 'Login berhasil');
    } catch (error) {
      next(error);
    }
  };

  refreshToken = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { refreshToken } = req.body;
      const result = await this.service.refreshToken(refreshToken, {
        ipAddress: req.ip,
        userAgent: req.get('user-agent'),
      });

      ApiResponse.success(res, result, 'Token berhasil diperbarui');
    } catch (error) {
      next(error);
    }
  };

  logout = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user?.sessionId) {
        throw new UnauthorizedError('Sesi tidak ditemukan');
      }

      await this.service.logout(req.user.sessionId);
      ApiResponse.success(res, null, 'Logout berhasil');
    } catch (error) {
      next(error);
    }
  };

  changePassword = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user?.id) {
        throw new UnauthorizedError('Autentikasi diperlukan');
      }

      await this.service.changePassword(req.user.id, req.body);
      ApiResponse.success(res, null, 'Password berhasil diperbarui, silakan login kembali');
    } catch (error) {
      next(error);
    }
  };
}

export const authController = new AuthController();

