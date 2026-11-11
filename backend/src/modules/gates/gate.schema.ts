import { z } from 'zod';
import { GateOperationalStatus } from '@prisma/client';

export const listGatesQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  operationalStatus: z.nativeEnum(GateOperationalStatus).optional(),
  search: z.string().optional(),
});

export const createGateSchema = z
  .object({
    gateCode: z
      .string()
      .min(3, 'Kode pintu minimal 3 karakter')
      .max(50, 'Kode pintu maksimal 50 karakter')
      .regex(/^[A-Z0-9_-]+$/i, 'Kode pintu hanya boleh huruf, angka, strip, dan underscore'),
    deviceId: z.string().uuid('ID perangkat harus berupa UUID yang valid'),
    name: z.string().min(1, 'Nama pintu wajib diisi').max(150),
    location: z.string().min(1, 'Lokasi pintu wajib diisi').max(255),
    actualOpening: z.number().min(0).max(100).optional(),
    currentOpening: z.number().min(0).max(100).optional(),
    maxOpening: z.number().optional(),
    motorType: z.string().optional(),
    operationalStatus: z.nativeEnum(GateOperationalStatus).optional(),
  })
  .transform((data) => ({
    gateCode: data.gateCode,
    deviceId: data.deviceId,
    name: data.name,
    location: data.location,
    actualOpening: data.actualOpening ?? data.currentOpening ?? 0,
    operationalStatus: data.operationalStatus ?? GateOperationalStatus.NORMAL,
  }));

export const updateGateSchema = z.object({
  name: z.string().min(1).max(150).optional(),
  location: z.string().min(1).max(255).optional(),
  deviceId: z.string().uuid('ID perangkat harus berupa UUID yang valid').optional(),
});

export const updateGateStatusSchema = z
  .object({
    operationalStatus: z.nativeEnum(GateOperationalStatus).optional(),
    status: z.string().optional(),
    actualOpening: z.number().min(0).max(100).optional(),
  })
  .transform((data) => {
    let opStatus = data.operationalStatus;
    if (!opStatus && data.status) {
      if (['NORMAL', 'MOVING', 'ERROR', 'OFFLINE'].includes(data.status)) {
        opStatus = data.status as GateOperationalStatus;
      } else {
        opStatus = GateOperationalStatus.NORMAL;
      }
    }
    return {
      operationalStatus: opStatus ?? GateOperationalStatus.NORMAL,
      actualOpening: data.actualOpening,
    };
  });

export type ListGatesQuery = z.infer<typeof listGatesQuerySchema>;
export type CreateGateInput = z.infer<typeof createGateSchema>;
export type UpdateGateInput = z.infer<typeof updateGateSchema>;
export type UpdateGateStatusInput = z.infer<typeof updateGateStatusSchema>;

