import { createApp } from './app.js';
import { env } from './config/env.js';
import { logger } from './core/logger/logger.js';
import { prisma } from './core/database/prisma.client.js';

const startServer = async () => {
  const app = createApp();

  const server = app.listen(env.PORT, () => {
    logger.info(
      `🚀 Main Backend running in ${env.NODE_ENV} mode on port ${env.PORT}`
    );
    logger.info(`📡 API Base URL: http://localhost:${env.PORT}${env.API_PREFIX}`);
    logger.info(`🩺 Health Check: http://localhost:${env.PORT}/health`);
  });

  // Graceful Shutdown Handler
  const shutdown = async (signal: string) => {
    logger.warn(`⚠️ Received ${signal}. Initiating graceful shutdown...`);

    server.close(async () => {
      logger.info('🛑 HTTP server closed.');

      try {
        await prisma.$disconnect();
        logger.info('🗄️ Database connection closed.');
      } catch (err) {
        logger.error({ err }, 'Error during database disconnection');
      }

      process.exit(0);
    });

    // Force exit after 10 seconds if shutdown hangs
    setTimeout(() => {
      logger.error('❌ Forcefully terminating server after timeout.');
      process.exit(1);
    }, 10000);
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
};

startServer().catch((err) => {
  logger.fatal({ err }, 'Failed to start Main Backend server');
  process.exit(1);
});

