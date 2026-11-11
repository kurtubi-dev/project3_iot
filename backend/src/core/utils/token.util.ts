import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { UserRole } from '@prisma/client';
import { env } from '../../config/env.js';

export interface TokenPayload {
  userId: string;
  email: string;
  role: UserRole;
  sessionId?: string;
}

export class TokenUtil {
  /**
   * Generates a short-lived access JWT token (15 mins)
   */
  static generateAccessToken(payload: TokenPayload): string {
    return jwt.sign(payload, env.JWT_ACCESS_SECRET, {
      expiresIn: env.JWT_ACCESS_EXPIRES_IN as jwt.SignOptions['expiresIn'],
    });
  }

  /**
   * Generates an opaque cryptographically-secure refresh token string
   */
  static generateRefreshToken(): string {
    return crypto.randomBytes(48).toString('hex');
  }

  /**
   * Produces a SHA-256 hash of a refresh token to safely store in the database
   */
  static hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  /**
   * Verifies an access token and returns its decoded payload
   */
  static verifyAccessToken(token: string): TokenPayload {
    return jwt.verify(token, env.JWT_ACCESS_SECRET) as TokenPayload;
  }
}

