import { z } from 'zod';
import { DeviceConnectionStatus } from '@prisma/client';

export const listDevicesQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  connectionStatus: z.nativeEnum(DeviceConnectionStatus).optional(),
  isActive: z
    .enum(['true', 'false'])
    .transform((val) => val === 'true')
    .optional(),
  search: z.string().optional(),
});

export const createDeviceSchema = z.object({
  deviceCode: z
    .string()
    .min(3, 'Kode perangkat minimal 3 karakter')
    .max(50, 'Kode perangkat maksimal 50 karakter')
    .regex(/^[A-Z0-9_-]+$/i, 'Kode perangkat hanya boleh huruf, angka, strip, dan underscore'),
  name: z.string().min(1, 'Nama perangkat wajib diisi').max(150),
  description: z.string().optional().nullable(),
  location: z.string().min(1, 'Lokasi perangkat wajib diisi').max(255),
});

export const updateDeviceSchema = z.object({
  name: z.string().min(1).max(150).optional(),
  description: z.string().optional().nullable(),
  location: z.string().min(1).max(255).optional(),
});

export const updateDeviceStatusSchema = z
  .object({
    isActive: z.boolean().optional(),
    status: z.string().optional(),
  })
  .refine((data) => data.isActive !== undefined || data.status !== undefined, {
    message: 'Harus menyertakan "isActive" (boolean) atau "status" (string)',
  })
  .transform((data) => ({
    isActive: data.isActive !== undefined ? data.isActive : data.status === 'ACTIVE',
  }));

export type ListDevicesQuery = z.infer<typeof listDevicesQuerySchema>;
export type CreateDeviceInput = z.infer<typeof createDeviceSchema>;
export type UpdateDeviceInput = z.infer<typeof updateDeviceSchema>;
export type UpdateDeviceStatusInput = z.infer<typeof updateDeviceStatusSchema>;

