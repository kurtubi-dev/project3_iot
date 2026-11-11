import { z } from 'zod';
import { SensorType } from '@prisma/client';

export const listSensorsQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  deviceId: z.string().uuid().optional(),
  type: z.nativeEnum(SensorType).optional(),
  isActive: z
    .enum(['true', 'false'])
    .transform((val) => val === 'true')
    .optional(),
  search: z.string().optional(),
});

export const createSensorSchema = z.object({
  deviceId: z.string().uuid('ID perangkat harus berupa UUID yang valid'),
  sensorCode: z
    .string()
    .min(3, 'Kode sensor minimal 3 karakter')
    .max(50, 'Kode sensor maksimal 50 karakter')
    .regex(/^[A-Z0-9_-]+$/i, 'Kode sensor hanya boleh huruf, angka, strip, dan underscore'),
  name: z.string().min(1, 'Nama sensor wajib diisi').max(150),
  type: z.nativeEnum(SensorType),
  parameter: z.string().min(1, 'Parameter sensor wajib diisi').max(100),
  unit: z.string().min(1, 'Unit pengukuran wajib diisi').max(30),
});

export const updateSensorSchema = z.object({
  name: z.string().min(1).max(150).optional(),
  parameter: z.string().min(1).max(100).optional(),
  unit: z.string().min(1).max(30).optional(),
});

export const updateSensorStatusSchema = z.object({
  isActive: z.boolean(),
});

export type ListSensorsQuery = z.infer<typeof listSensorsQuerySchema>;
export type CreateSensorInput = z.infer<typeof createSensorSchema>;
export type UpdateSensorInput = z.infer<typeof updateSensorSchema>;
export type UpdateSensorStatusInput = z.infer<typeof updateSensorStatusSchema>;

