import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import { prisma } from '../../src/core/database/prisma.client.js';

describe('Auth Integration Tests', () => {
  const app = createApp();

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('GET /health should return 200 and UP status', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe('UP');
  });

  it('POST /api/v1/auth/login with valid credentials should succeed', async () => {
    const res = await request(app).post('/api/v1/auth/login').send({
      email: 'admin@irrigation.local',
      password: 'AdminPassword123!',
    });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.email).toBe('admin@irrigation.local');
    expect(res.body.data.user.role).toBe('ADMIN');
    expect(res.body.data.accessToken).toBeDefined();
    expect(res.body.data.refreshToken).toBeDefined();
  });

  it('POST /api/v1/auth/login with invalid password should return 401', async () => {
    const res = await request(app).post('/api/v1/auth/login').send({
      email: 'admin@irrigation.local',
      password: 'WrongPassword!',
    });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('POST /api/v1/auth/login with invalid email format should return 422', async () => {
    const res = await request(app).post('/api/v1/auth/login').send({
      email: 'invalid-email',
      password: 'SomePassword123',
    });

    expect(res.status).toBe(422);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });
});

