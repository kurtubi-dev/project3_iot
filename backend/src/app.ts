import express, { Express, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import pinoHttp from 'pino-http';
import { env } from './config/env.js';
import { logger } from './core/logger/logger.js';
import { ApiResponse } from './core/response/api-response.js';
import { errorHandler } from './core/middlewares/error.middleware.js';
import { authRouter } from './modules/auth/auth.routes.js';
import { userRouter } from './modules/users/user.routes.js';
import { deviceRouter } from './modules/devices/device.routes.js';
import { sensorRouter } from './modules/sensors/sensor.routes.js';
import { gateRouter } from './modules/gates/gate.routes.js';

export const createApp = (): Express => {
  const app = express();

  // 1. Security & Standard Middlewares
  app.use(helmet());
  app.use(
    cors({
      origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN.split(','),
      credentials: true,
    })
  );
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true }));

  // 2. Request Logging (skip for test/healthcheck)
  if (env.NODE_ENV !== 'test') {
    app.use(
      pinoHttp({
        logger,
        autoLogging: {
          ignore: (req) => req.url === '/health',
        },
      })
    );
  }

  // 3. Healthcheck Endpoint
  app.get('/health', (_req: Request, res: Response) => {
    return ApiResponse.success(
      res,
      {
        status: 'UP',
        environment: env.NODE_ENV,
        timestamp: new Date().toISOString(),
      },
      'Server is healthy'
    );
  });

  // 4. API v1 Router
  const apiRouter = express.Router();
  apiRouter.get('/', (_req: Request, res: Response) => {
    return ApiResponse.success(
      res,
      {
        name: 'IoT Irrigation Monitoring & AI Gate Recommendation API',
        version: 'v1.0.0',
      },
      'API v1 root'
    );
  });

  // Mount Domain Modules
  apiRouter.use('/auth', authRouter);
  apiRouter.use('/users', userRouter);
  apiRouter.use('/devices', deviceRouter);
  apiRouter.use('/sensors', sensorRouter);
  apiRouter.use('/gates', gateRouter);

  // Mount API Router to /api/v1
  app.use(env.API_PREFIX, apiRouter);

  // 5. 404 Not Found Handler
  app.use((req: Request, res: Response) => {
    return ApiResponse.error(
      res,
      `Endpoint ${req.method} ${req.originalUrl} tidak ditemukan`,
      'ENDPOINT_NOT_FOUND',
      404
    );
  });

  // 6. Centralized Error Handler
  app.use(errorHandler);

  return app;
};
