import { PrismaClient, UserRole, UserStatus, SensorType, RiskLevel, ThresholdOperator } from '@prisma/client';
import argon2 from 'argon2';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seeding...');

  // 1. Seed Initial Admin User
  const adminEmail = 'admin@irrigation.local';
  const existingAdmin = await prisma.user.findUnique({
    where: { email: adminEmail },
  });

  let adminUser = existingAdmin;

  if (!existingAdmin) {
    adminUser = await prisma.user.create({
      data: {
        name: 'Super Administrator',
        email: adminEmail,
        phone: '+6281234567890',
        role: UserRole.ADMIN,
        status: UserStatus.ACTIVE,
      },
    });

    const defaultPassword = 'AdminPassword123!';
    const passwordHash = await argon2.hash(defaultPassword, {
      type: argon2.argon2id,
      memoryCost: 65536,
      timeCost: 3,
      parallelism: 4,
    });

    await prisma.authAccount.create({
      data: {
        userId: adminUser.id,
        provider: 'LOCAL',
        providerUserId: adminEmail,
        passwordHash,
      },
    });

    console.log(`✅ Admin user seeded: ${adminEmail} (Password: ${defaultPassword})`);
  } else {
    console.log(`ℹ️ Admin user already exists: ${adminEmail}`);
  }

  // 2. Seed Default Runtime Configurations
  const defaultConfigs = [
    {
      key: 'ews_interval_minutes',
      value: { interval: 5 },
      description: 'Interval periodic evaluasi Early Warning System dalam menit',
    },
    {
      key: 'recommendation_interval_minutes',
      value: { interval: 10 },
      description: 'Interval periodic permintaan rekomendasi AI dalam menit',
    },
    {
      key: 'recommendation_expiry_minutes',
      value: { expiry: 30 },
      description: 'Masa kedaluwarsa rekomendasi status PENDING dalam menit',
    },
    {
      key: 'mqtt_retry_limit',
      value: { limit: 3 },
      description: 'Batas maksimal retry pengiriman perintah pintu via MQTT',
    },
    {
      key: 'mqtt_retry_interval_seconds',
      value: { interval: 10 },
      description: 'Jeda waktu antar percobaan retry pengiriman MQTT dalam detik',
    },
    {
      key: 'mqtt_command_timeout_seconds',
      value: { timeout: 60 },
      description: 'Batas waktu command sebelum dianggap TIMEOUT dalam detik',
    },
  ];

  for (const config of defaultConfigs) {
    await prisma.runtimeConfig.upsert({
      where: { key: config.key },
      update: {},
      create: {
        key: config.key,
        value: config.value,
        description: config.description,
        updatedBy: adminUser?.id,
      },
    });
  }
  console.log(`✅ Seeded ${defaultConfigs.length} default runtime configurations.`);

  // 3. Seed Default Warning Rules
  if (adminUser) {
    const defaultRules = [
      {
        name: 'Siaga 1 Curah Hujan Sangat Lebat',
        sensorType: SensorType.RAINFALL,
        parameter: 'rainfall_rate',
        unit: 'mm/h',
        riskLevel: RiskLevel.CRITICAL,
        operator: ThresholdOperator.GTE,
        thresholdValue: 100.0,
      },
      {
        name: 'Siaga 2 Curah Hujan Lebat',
        sensorType: SensorType.RAINFALL,
        parameter: 'rainfall_rate',
        unit: 'mm/h',
        riskLevel: RiskLevel.HIGH,
        operator: ThresholdOperator.GTE,
        thresholdValue: 50.0,
      },
      {
        name: 'Waspada Tinggi Muka Air Kritis',
        sensorType: SensorType.WATER_LEVEL,
        parameter: 'water_level',
        unit: 'm',
        riskLevel: RiskLevel.CRITICAL,
        operator: ThresholdOperator.GTE,
        thresholdValue: 4.5,
      },
      {
        name: 'Waspada Tinggi Muka Air Tinggi',
        sensorType: SensorType.WATER_LEVEL,
        parameter: 'water_level',
        unit: 'm',
        riskLevel: RiskLevel.HIGH,
        operator: ThresholdOperator.GTE,
        thresholdValue: 3.5,
      },
    ];

    for (const rule of defaultRules) {
      const existing = await prisma.warningRule.findFirst({
        where: { name: rule.name },
      });

      if (!existing) {
        await prisma.warningRule.create({
          data: {
            ...rule,
            isActive: true,
            createdBy: adminUser.id,
            updatedBy: adminUser.id,
          },
        });
      }
    }
    console.log(`✅ Seeded default EWS warning rules.`);
  }

  console.log('🌾 Database seeding finished successfully.');
}

main()
  .catch((e) => {
    console.error('❌ Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

