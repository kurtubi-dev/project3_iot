import { Response } from 'express';

export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface ApiSuccessResponse<T> {
  success: true;
  message: string;
  data: T;
  meta?: PaginationMeta;
}

export interface ApiErrorResponse {
  success: false;
  message: string;
  error: {
    code: string;
    details?: unknown;
  };
}

export class ApiResponse {
  static success<T>(
    res: Response,
    data: T,
    message = 'Data berhasil diambil',
    statusCode = 200,
    meta?: PaginationMeta
  ): Response {
    const payload: ApiSuccessResponse<T> = {
      success: true,
      message,
      data,
      ...(meta && { meta }),
    };
    return res.status(statusCode).json(payload);
  }

  static created<T>(res: Response, data: T, message = 'Data berhasil dibuat'): Response {
    return this.success(res, data, message, 201);
  }

  static noContent(res: Response): Response {
    return res.status(204).send();
  }

  static error(
    res: Response,
    message: string,
    errorCode: string,
    statusCode = 400,
    details?: unknown
  ): Response {
    const payload: ApiErrorResponse = {
      success: false,
      message,
      error: {
        code: errorCode,
        ...(details !== undefined ? { details } : {}),
      },
    };
    return res.status(statusCode).json(payload);
  }
}
