import { Router } from 'express';
import { deviceController } from './device.controller.js';
import { authenticate } from '../../core/middlewares/auth.middleware.js';
import { requireRoles } from '../../core/middlewares/role.middleware.js';
import {
  validateBody,
  validateQuery,
} from '../../core/middlewares/validate.middleware.js';
import {
  listDevicesQuerySchema,
  createDeviceSchema,
  updateDeviceSchema,
  updateDeviceStatusSchema,
} from './device.schema.js';
import { UserRole } from '@prisma/client';

export const deviceRouter = Router();

// All device routes require authentication
deviceRouter.use(authenticate);

// Read routes available to all roles (ADMIN, PETUGAS_LAPANGAN, PENGELOLA)
deviceRouter.get('/', validateQuery(listDevicesQuerySchema), deviceController.listDevices);
deviceRouter.get('/:id', deviceController.getDeviceById);

// Admin-only management routes
deviceRouter.post(
  '/',
  requireRoles(UserRole.ADMIN),
  validateBody(createDeviceSchema),
  deviceController.createDevice
);
deviceRouter.patch(
  '/:id',
  requireRoles(UserRole.ADMIN),
  validateBody(updateDeviceSchema),
  deviceController.updateDevice
);
deviceRouter.put(
  '/:id',
  requireRoles(UserRole.ADMIN),
  validateBody(updateDeviceSchema),
  deviceController.updateDevice
);
deviceRouter.patch(
  '/:id/status',
  requireRoles(UserRole.ADMIN),
  validateBody(updateDeviceStatusSchema),
  deviceController.updateDeviceStatus
);
deviceRouter.post(
  '/:id/credentials/rotate',
  requireRoles(UserRole.ADMIN),
  deviceController.rotateCredential
);

