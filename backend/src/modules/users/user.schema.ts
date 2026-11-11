import { z } from 'zod';
import { UserRole, UserStatus } from '@prisma/client';

export const listUsersQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  role: z.nativeEnum(UserRole).optional(),
  status: z.nativeEnum(UserStatus).optional(),
  search: z.string().optional(),
});

export const updateUserSchema = z.object({
  name: z.string().min(1).max(150).optional(),
  phone: z.string().max(30).optional().nullable(),
  role: z.nativeEnum(UserRole).optional(),
});

export const updateUserStatusSchema = z.object({
  status: z.nativeEnum(UserStatus),
});

export const inviteUserSchema = z.object({
  email: z.string().email('Format email tidak valid').max(255),
  name: z.string().min(1, 'Nama wajib diisi').max(150),
  role: z.nativeEnum(UserRole),
});

export type ListUsersQuery = z.infer<typeof listUsersQuerySchema>;
export type UpdateUserInput = z.infer<typeof updateUserSchema>;
export type UpdateUserStatusInput = z.infer<typeof updateUserStatusSchema>;
export type InviteUserInput = z.infer<typeof inviteUserSchema>;

