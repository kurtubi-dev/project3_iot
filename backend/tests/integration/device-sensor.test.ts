import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import { prisma } from '../../src/core/database/prisma.client.js';

describe('Devices & Sensors Integration Tests', () => {
  const app = createApp();
  let adminToken: string;
  let testDeviceId: string;

  beforeAll(async () => {
    // 1. Authenticate as Admin
    const loginRes = await request(app).post('/api/v1/auth/login').send({
      email: 'admin@irrigation.local',
      password: 'AdminPassword123!',
    });

    adminToken = loginRes.body.data.accessToken;
  });

  afterAll(async () => {
    // Cleanup created test records
    if (testDeviceId) {
      await prisma.sensor.deleteMany({ where: { deviceId: testDeviceId } });
      await prisma.deviceCredential.deleteMany({ where: { deviceId: testDeviceId } });
      await prisma.device.delete({ where: { id: testDeviceId } }).catch(() => {});
    }
    await prisma.$disconnect();
  });

  it('POST /api/v1/devices should create device and return initialSecret', async () => {
    const res = await request(app)
      .post('/api/v1/devices')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        deviceCode: 'DEV-TEST-001',
        name: 'Stasiun Bendung Test 1',
        location: 'Bogor KM 12',
        description: 'Stasiun telemetri pengujian sistem',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.device.deviceCode).toBe('DEV-TEST-001');
    expect(res.body.data.initialSecret).toBeDefined();
    expect(typeof res.body.data.initialSecret).toBe('string');

    testDeviceId = res.body.data.device.id;
  });

  it('GET /api/v1/devices should return list of devices', async () => {
    const res = await request(app)
      .get('/api/v1/devices')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBeGreaterThanOrEqual(1);
  });

  it('POST /api/v1/sensors should register a sensor bound to device', async () => {
    const res = await request(app)
      .post('/api/v1/sensors')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        deviceId: testDeviceId,
        sensorCode: 'SNS-TEST-001',
        name: 'Sensor Curah Hujan Test',
        type: 'RAINFALL',
        parameter: 'rainfall_rate',
        unit: 'mm/h',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.sensorCode).toBe('SNS-TEST-001');
    expect(res.body.data.type).toBe('RAINFALL');
  });

  it('POST /api/v1/devices/:id/credentials/rotate should rotate secret', async () => {
    const res = await request(app)
      .post(`/api/v1/devices/${testDeviceId}/credentials/rotate`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.newSecret).toBeDefined();

    // Verify only 1 active credential exists in DB
    const activeCreds = await prisma.deviceCredential.count({
      where: { deviceId: testDeviceId, revokedAt: null },
    });
    expect(activeCreds).toBe(1);
  });

  it('POST /api/v1/devices without token should return 401 Unauthorized', async () => {
    const res = await request(app).post('/api/v1/devices').send({
      deviceCode: 'DEV-UNAUTH',
      name: 'Unauthorized',
      location: 'None',
    });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });
});

