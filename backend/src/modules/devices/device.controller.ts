import { Request, Response, NextFunction } from 'express';
import { deviceService, DeviceService } from './device.service.js';
import { ApiResponse } from '../../core/response/api-response.js';
import { UnauthorizedError } from '../../core/errors/app-error.js';

export class DeviceController {
  constructor(private readonly service: DeviceService = deviceService) {}

  listDevices = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      // @ts-expect-error parsed query
      const { devices, meta } = await this.service.listDevices(req.query);
      ApiResponse.success(res, devices, 'Daftar perangkat berhasil diambil', 200, meta);
    } catch (error) {
      next(error);
    }
  };

  getDeviceById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const device = await this.service.getDeviceById(req.params.id as string);
      ApiResponse.success(res, device, 'Detail perangkat berhasil diambil');
    } catch (error) {
      next(error);
    }
  };

  createDevice = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Autentikasi diperlukan');
      }

      const result = await this.service.createDevice(req.body, req.user.id);
      ApiResponse.created(
        res,
        result,
        'Perangkat berhasil didaftarkan. Harap simpan initialSecret sekarang karena tidak akan ditampilkan lagi.'
      );
    } catch (error) {
      next(error);
    }
  };

  rotateCredential = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Autentikasi diperlukan');
      }

      const result = await this.service.rotateCredential(
        req.params.id as string,
        req.user.id
      );
      ApiResponse.success(
        res,
        result,
        'Kredensial perangkat berhasil dirotasi. Harap simpan newSecret sekarang.'
      );
    } catch (error) {
      next(error);
    }
  };

  updateDevice = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const updated = await this.service.updateDevice(req.params.id as string, req.body);
      ApiResponse.success(res, updated, 'Informasi perangkat berhasil diperbarui');
    } catch (error) {
      next(error);
    }
  };

  updateDeviceStatus = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const updated = await this.service.updateDeviceStatus(
        req.params.id as string,
        req.body
      );
      ApiResponse.success(res, updated, 'Status perangkat berhasil diperbarui');
    } catch (error) {
      next(error);
    }
  };
}

export const deviceController = new DeviceController();

