import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import { prisma } from '../../src/core/database/prisma.client.js';

describe('Gates Integration Tests', () => {
  const app = createApp();
  let adminToken: string;
  let testDeviceId: string;
  let testGateId: string;

  beforeAll(async () => {
    // 1. Authenticate as Admin
    const loginRes = await request(app).post('/api/v1/auth/login').send({
      email: 'admin@irrigation.local',
      password: 'AdminPassword123!',
    });
    adminToken = loginRes.body.data.accessToken;

    // 2. Create a dedicated test device
    const deviceRes = await request(app)
      .post('/api/v1/devices')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        deviceCode: 'DEV-GATE-TEST',
        name: 'Perangkat Gate Test',
        location: 'Saluran Primer Barat',
      });
    testDeviceId = deviceRes.body.data.device.id;
  });

  afterAll(async () => {
    // Cleanup created test records
    if (testGateId) {
      await prisma.gate.delete({ where: { id: testGateId } }).catch(() => {});
    }
    if (testDeviceId) {
      await prisma.deviceCredential.deleteMany({ where: { deviceId: testDeviceId } });
      await prisma.device.delete({ where: { id: testDeviceId } }).catch(() => {});
    }
    await prisma.$disconnect();
  });

  it('POST /api/v1/gates should register a new gate bound to device', async () => {
    const res = await request(app)
      .post('/api/v1/gates')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        gateCode: 'GATE-TEST-001',
        deviceId: testDeviceId,
        name: 'Pintu Air Intake Barat',
        location: 'Bendung Utama KM 3',
        actualOpening: 0,
        operationalStatus: 'NORMAL',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.gateCode).toBe('GATE-TEST-001');
    expect(res.body.data.deviceId).toBe(testDeviceId);

    testGateId = res.body.data.id;
  });

  it('POST /api/v1/gates should reject registering a second gate for the same device (1:1 constraint)', async () => {
    const res = await request(app)
      .post('/api/v1/gates')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        gateCode: 'GATE-TEST-002',
        deviceId: testDeviceId,
        name: 'Pintu Air Kedua (Harus Gagal)',
        location: 'Bendung Utama KM 3',
      });

    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('DEVICE_ALREADY_ASSIGNED_TO_GATE');
  });

  it('GET /api/v1/gates should return list of gates', async () => {
    const res = await request(app)
      .get('/api/v1/gates')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBeGreaterThanOrEqual(1);
  });

  it('GET /api/v1/gates/:id should return gate details', async () => {
    const res = await request(app)
      .get(`/api/v1/gates/${testGateId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.id).toBe(testGateId);
    expect(res.body.data.device).toBeDefined();
  });

  it('PATCH /api/v1/gates/:id/status should update operational status and actualOpening', async () => {
    const res = await request(app)
      .patch(`/api/v1/gates/${testGateId}/status`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        operationalStatus: 'MOVING',
        actualOpening: 45.5,
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.operationalStatus).toBe('MOVING');
    expect(Number(res.body.data.actualOpening)).toBe(45.5);
  });
});

