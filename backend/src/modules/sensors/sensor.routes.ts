import { Router } from 'express';
import { sensorController } from './sensor.controller.js';
import { authenticate } from '../../core/middlewares/auth.middleware.js';
import { requireRoles } from '../../core/middlewares/role.middleware.js';
import {
  validateBody,
  validateQuery,
} from '../../core/middlewares/validate.middleware.js';
import {
  listSensorsQuerySchema,
  createSensorSchema,
  updateSensorSchema,
  updateSensorStatusSchema,
} from './sensor.schema.js';
import { UserRole } from '@prisma/client';

export const sensorRouter = Router();

// All sensor routes require authentication
sensorRouter.use(authenticate);

// Read routes available to all roles (ADMIN, PETUGAS_LAPANGAN, PENGELOLA)
sensorRouter.get('/', validateQuery(listSensorsQuerySchema), sensorController.listSensors);
sensorRouter.get('/:id', sensorController.getSensorById);

// Admin-only management routes
sensorRouter.post(
  '/',
  requireRoles(UserRole.ADMIN),
  validateBody(createSensorSchema),
  sensorController.createSensor
);
sensorRouter.patch(
  '/:id',
  requireRoles(UserRole.ADMIN),
  validateBody(updateSensorSchema),
  sensorController.updateSensor
);
sensorRouter.patch(
  '/:id/status',
  requireRoles(UserRole.ADMIN),
  validateBody(updateSensorStatusSchema),
  sensorController.updateSensorStatus
);

