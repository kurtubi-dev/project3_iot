import { Router } from 'express';
import { userController } from './user.controller.js';
import { authenticate } from '../../core/middlewares/auth.middleware.js';
import { requireRoles } from '../../core/middlewares/role.middleware.js';
import {
  validateBody,
  validateQuery,
} from '../../core/middlewares/validate.middleware.js';
import {
  listUsersQuerySchema,
  updateUserSchema,
  updateUserStatusSchema,
  inviteUserSchema,
} from './user.schema.js';
import { UserRole } from '@prisma/client';

export const userRouter = Router();

// All user management routes require ADMIN role
userRouter.use(authenticate, requireRoles(UserRole.ADMIN));

userRouter.get('/', validateQuery(listUsersQuerySchema), userController.listUsers);
userRouter.post('/invitations', validateBody(inviteUserSchema), userController.inviteUser);
userRouter.get('/:id', userController.getUserById);
userRouter.patch('/:id', validateBody(updateUserSchema), userController.updateUser);
userRouter.patch('/:id/status', validateBody(updateUserStatusSchema), userController.updateUserStatus);

