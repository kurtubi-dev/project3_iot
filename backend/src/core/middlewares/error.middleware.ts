import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { AppError } from '../errors/app-error.js';
import { ApiResponse } from '../response/api-response.js';
import { logger } from '../logger/logger.js';
import { env } from '../../config/env.js';

export const errorHandler = (
  err: Error,
  req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  _next: NextFunction
): Response => {
  // 1. Zod Validation Error (HTTP 422)
  if (err instanceof ZodError) {
    const formattedErrors = err.errors.map((e) => ({
      field: e.path.join('.'),
      message: e.message,
    }));

    return ApiResponse.error(
      res,
      'Validasi request gagal',
      'VALIDATION_ERROR',
      422,
      formattedErrors
    );
  }

  // 2. Custom AppError
  if (err instanceof AppError) {
    if (err.statusCode >= 500) {
      logger.error(
        { err, path: req.path, method: req.method },
        `[AppError 5xx]: ${err.message}`
      );
    }

    return ApiResponse.error(res, err.message, err.errorCode, err.statusCode, err.details);
  }

  // 3. PostgreSQL / Prisma Invalid UUID Column Data Error (HTTP 400)
  if (err.message && err.message.includes('Error creating UUID')) {
    return ApiResponse.error(
      res,
      'Format ID parameter tidak valid (harus berformat UUID)',
      'INVALID_UUID_FORMAT',
      400
    );
  }

  // 4. Unhandled Internal Server Error (HTTP 500)
  logger.error(
    { err, path: req.path, method: req.method, body: req.body },
    `[Unhandled Error]: ${err.message}`
  );

  return ApiResponse.error(
    res,
    env.NODE_ENV === 'production'
      ? 'Terjadi kesalahan internal pada server'
      : err.message || 'Terjadi kesalahan internal',
    'INTERNAL_SERVER_ERROR',
    500
  );
};
