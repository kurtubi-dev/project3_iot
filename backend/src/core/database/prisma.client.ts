import { PrismaClient } from '@prisma/client';
import { env } from '../../config/env.js';
import { logger } from '../logger/logger.js';

declare global {
  // eslint-disable-next-line no-var
  var prismaInstance: PrismaClient | undefined;
}

export const prisma =
  global.prismaInstance ||
  new PrismaClient({
    log:
      env.NODE_ENV === 'development'
        ? [
            { emit: 'event', level: 'query' },
            { emit: 'event', level: 'error' },
            { emit: 'event', level: 'warn' },
          ]
        : [{ emit: 'event', level: 'error' }],
  });

if (env.NODE_ENV === 'development') {
  // @ts-expect-error Prisma query event typing
  prisma.$on('query', (e: { query: string; params: string; duration: number }) => {
    logger.debug({ duration: `${e.duration}ms`, query: e.query }, 'Prisma Query');
  });

  global.prismaInstance = prisma;
}

// @ts-expect-error Prisma error event typing
prisma.$on('error', (e: { message: string }) => {
  logger.error({ err: e.message }, 'Prisma Database Error');
});

