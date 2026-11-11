import { Router } from 'express';
import { authController } from './auth.controller.js';
import { validateBody } from '../../core/middlewares/validate.middleware.js';
import { authenticate } from '../../core/middlewares/auth.middleware.js';
import {
  loginSchema,
  refreshSchema,
  changePasswordSchema,
} from './auth.schema.js';

export const authRouter = Router();

authRouter.post('/login', validateBody(loginSchema), authController.login);
authRouter.post('/refresh', validateBody(refreshSchema), authController.refreshToken);
authRouter.post('/logout', authenticate, authController.logout);
authRouter.post(
  '/change-password',
  authenticate,
  validateBody(changePasswordSchema),
  authController.changePassword
);

