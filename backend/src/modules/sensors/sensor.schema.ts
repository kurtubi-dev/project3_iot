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

export const createSensorSchema = z
  .object({
    deviceId: z.string().uuid('ID perangkat harus berupa UUID yang valid'),
    sensorCode: z
      .string()
      .min(3, 'Kode sensor minimal 3 karakter')
      .max(50, 'Kode sensor maksimal 50 karakter')
      .regex(/^[A-Z0-9_-]+$/i, 'Kode sensor hanya boleh huruf, angka, strip, dan underscore'),
    name: z.string().optional(),
    type: z.nativeEnum(SensorType).optional(),
    sensorType: z.nativeEnum(SensorType).optional(),
    parameter: z.string().optional(),
    unit: z.string().min(1, 'Unit pengukuran wajib diisi').max(30).default('cm'),
    minThreshold: z.number().optional(),
    maxThreshold: z.number().optional(),
    model: z.string().optional(),
  })
  .transform((data) => {
    const type = data.type || data.sensorType || SensorType.WATER_LEVEL;
    const name =
      data.name ||
      (data.model ? `Sensor ${data.model}` : `Sensor ${type === SensorType.WATER_LEVEL ? 'Ketinggian Air' : 'Curah Hujan'}`);
    const parameter =
      data.parameter || (type === SensorType.WATER_LEVEL ? 'water_level_cm' : 'rainfall_mm');

    return {
      deviceId: data.deviceId,
      sensorCode: data.sensorCode,
      name,
      type,
      parameter,
      unit: data.unit,
    };
  });

export const updateSensorSchema = z
  .object({
    name: z.string().min(1).max(150).optional(),
    parameter: z.string().min(1).max(100).optional(),
    unit: z.string().min(1).max(30).optional(),
    minThreshold: z.number().optional(),
    maxThreshold: z.number().optional(),
    notes: z.string().optional(),
  })
  .transform((data) => ({
    name: data.name,
    parameter: data.parameter,
    unit: data.unit,
  }));

export const updateSensorStatusSchema = z
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

export type ListSensorsQuery = z.infer<typeof listSensorsQuerySchema>;
export type CreateSensorInput = z.infer<typeof createSensorSchema>;
export type UpdateSensorInput = z.infer<typeof updateSensorSchema>;
export type UpdateSensorStatusInput = z.infer<typeof updateSensorStatusSchema>;

