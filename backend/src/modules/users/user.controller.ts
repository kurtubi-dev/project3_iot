import { Request, Response, NextFunction } from 'express';
import { userService, UserService } from './user.service.js';
import { ApiResponse } from '../../core/response/api-response.js';
import { UnauthorizedError } from '../../core/errors/app-error.js';

export class UserController {
  constructor(private readonly service: UserService = userService) {}

  listUsers = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      // @ts-expect-error query parsed by validateQuery
      const { users, meta } = await this.service.listUsers(req.query);
      ApiResponse.success(res, users, 'Daftar pengguna berhasil diambil', 200, meta);
    } catch (error) {
      next(error);
    }
  };

  getUserById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const user = await this.service.getUserById(req.params.id as string);
      ApiResponse.success(res, user, 'Detail pengguna berhasil diambil');
    } catch (error) {
      next(error);
    }
  };

  updateUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Autentikasi diperlukan');
      }

      const updated = await this.service.updateUser(
        req.params.id as string,
        req.body,
        req.user.id
      );
      ApiResponse.success(res, updated, 'Profil pengguna berhasil diperbarui');
    } catch (error) {
      next(error);
    }
  };

  updateUserStatus = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Autentikasi diperlukan');
      }

      const updated = await this.service.updateUserStatus(
        req.params.id as string,
        req.body,
        req.user.id
      );
      ApiResponse.success(res, updated, 'Status pengguna berhasil diperbarui');
    } catch (error) {
      next(error);
    }
  };

  inviteUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Autentikasi diperlukan');
      }

      const result = await this.service.inviteUser(req.body, req.user.id);
      ApiResponse.created(res, result, 'Undangan pengguna berhasil dibuat');
    } catch (error) {
      next(error);
    }
  };
}

export const userController = new UserController();

