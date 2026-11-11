import { Request, Response, NextFunction } from 'express';
import { gateService, GateService } from './gate.service.js';
import { ApiResponse } from '../../core/response/api-response.js';

export class GateController {
  constructor(private readonly service: GateService = gateService) {}

  listGates = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      // @ts-expect-error query parsed
      const { gates, meta } = await this.service.listGates(req.query);
      ApiResponse.success(res, gates, 'Daftar pintu irigasi berhasil diambil', 200, meta);
    } catch (error) {
      next(error);
    }
  };

  getGateById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const gate = await this.service.getGateById(req.params.id as string);
      ApiResponse.success(res, gate, 'Detail pintu irigasi berhasil diambil');
    } catch (error) {
      next(error);
    }
  };

  createGate = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const gate = await this.service.createGate(req.body);
      ApiResponse.created(res, gate, 'Pintu irigasi berhasil didaftarkan');
    } catch (error) {
      next(error);
    }
  };

  updateGate = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const updated = await this.service.updateGate(req.params.id as string, req.body);
      ApiResponse.success(res, updated, 'Informasi pintu irigasi berhasil diperbarui');
    } catch (error) {
      next(error);
    }
  };

  updateGateStatus = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const updated = await this.service.updateGateStatus(
        req.params.id as string,
        req.body
      );
      ApiResponse.success(res, updated, 'Status operasional pintu berhasil diperbarui');
    } catch (error) {
      next(error);
    }
  };
}

export const gateController = new GateController();

