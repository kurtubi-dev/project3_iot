import { z } from 'zod';
import { GateOperationalStatus } from '@prisma/client';

export const listGatesQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  operationalStatus: z.nativeEnum(GateOperationalStatus).optional(),
  search: z.string().optional(),
});

export const createGateSchema = z.object({
  gateCode: z
    .string()
    .min(3, 'Kode pintu minimal 3 karakter')
    .max(50, 'Kode pintu maksimal 50 karakter')
    .regex(/^[A-Z0-9_-]+$/i, 'Kode pintu hanya boleh huruf, angka, strip, dan underscore'),
  deviceId: z.string().uuid('ID perangkat harus berupa UUID yang valid'),
  name: z.string().min(1, 'Nama pintu wajib diisi').max(150),
  location: z.string().min(1, 'Lokasi pintu wajib diisi').max(255),
  actualOpening: z.number().min(0).max(100).default(0),
  operationalStatus: z.nativeEnum(GateOperationalStatus).default(GateOperationalStatus.OFFLINE),
});

export const updateGateSchema = z.object({
  name: z.string().min(1).max(150).optional(),
  location: z.string().min(1).max(255).optional(),
  deviceId: z.string().uuid('ID perangkat harus berupa UUID yang valid').optional(),
});

export const updateGateStatusSchema = z.object({
  operationalStatus: z.nativeEnum(GateOperationalStatus),
  actualOpening: z.number().min(0).max(100).optional(),
});

export type ListGatesQuery = z.infer<typeof listGatesQuerySchema>;
export type CreateGateInput = z.infer<typeof createGateSchema>;
export type UpdateGateInput = z.infer<typeof updateGateSchema>;
export type UpdateGateStatusInput = z.infer<typeof updateGateStatusSchema>;

