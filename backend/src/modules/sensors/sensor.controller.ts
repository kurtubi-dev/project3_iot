import { Request, Response, NextFunction } from 'express';
import { sensorService, SensorService } from './sensor.service.js';
import { ApiResponse } from '../../core/response/api-response.js';

export class SensorController {
  constructor(private readonly service: SensorService = sensorService) {}

  listSensors = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      // @ts-expect-error parsed query
      const { sensors, meta } = await this.service.listSensors(req.query);
      ApiResponse.success(res, sensors, 'Daftar sensor berhasil diambil', 200, meta);
    } catch (error) {
      next(error);
    }
  };

  getSensorById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const sensor = await this.service.getSensorById(req.params.id as string);
      ApiResponse.success(res, sensor, 'Detail sensor berhasil diambil');
    } catch (error) {
      next(error);
    }
  };

  createSensor = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const sensor = await this.service.createSensor(req.body);
      ApiResponse.created(res, sensor, 'Sensor berhasil didaftarkan');
    } catch (error) {
      next(error);
    }
  };

  updateSensor = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const updated = await this.service.updateSensor(req.params.id as string, req.body);
      ApiResponse.success(res, updated, 'Informasi sensor berhasil diperbarui');
    } catch (error) {
      next(error);
    }
  };

  updateSensorStatus = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const updated = await this.service.updateSensorStatus(
        req.params.id as string,
        req.body
      );
      ApiResponse.success(res, updated, 'Status sensor berhasil diperbarui');
    } catch (error) {
      next(error);
    }
  };
}

export const sensorController = new SensorController();

