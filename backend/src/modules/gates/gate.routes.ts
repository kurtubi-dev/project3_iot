import { Router } from 'express';
import { gateController } from './gate.controller.js';
import { authenticate } from '../../core/middlewares/auth.middleware.js';
import { requireRoles } from '../../core/middlewares/role.middleware.js';
import {
  validateBody,
  validateQuery,
} from '../../core/middlewares/validate.middleware.js';
import {
  listGatesQuerySchema,
  createGateSchema,
  updateGateSchema,
  updateGateStatusSchema,
} from './gate.schema.js';
import { UserRole } from '@prisma/client';

export const gateRouter = Router();

// All gate routes require authentication
gateRouter.use(authenticate);

// Read routes available to all roles (ADMIN, PETUGAS_LAPANGAN, PENGELOLA)
gateRouter.get('/', validateQuery(listGatesQuerySchema), gateController.listGates);
gateRouter.get('/:id', gateController.getGateById);

// Admin-only management routes
gateRouter.post(
  '/',
  requireRoles(UserRole.ADMIN),
  validateBody(createGateSchema),
  gateController.createGate
);
gateRouter.patch(
  '/:id',
  requireRoles(UserRole.ADMIN),
  validateBody(updateGateSchema),
  gateController.updateGate
);
gateRouter.put(
  '/:id',
  requireRoles(UserRole.ADMIN),
  validateBody(updateGateSchema),
  gateController.updateGate
);

// Operational status update (ADMIN, PETUGAS_LAPANGAN)
gateRouter.patch(
  '/:id/status',
  requireRoles(UserRole.ADMIN, UserRole.PETUGAS_LAPANGAN),
  validateBody(updateGateStatusSchema),
  gateController.updateGateStatus
);

