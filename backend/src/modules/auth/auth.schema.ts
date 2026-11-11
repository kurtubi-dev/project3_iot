import { z } from 'zod';

export const loginSchema = z.object({
  email: z.string().email('Format email tidak valid').max(255),
  password: z.string().min(1, 'Password wajib diisi').max(100),
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token wajib diisi'),
});

export const changePasswordSchema = z.object({
  oldPassword: z.string().min(1, 'Password lama wajib diisi'),
  newPassword: z
    .string()
    .min(8, 'Password baru minimal 8 karakter')
    .max(100, 'Password baru maksimal 100 karakter'),
});

export const googleAuthSchema = z.object({
  idToken: z.string().min(1, 'Google ID Token wajib diisi'),
});

export const acceptInvitationSchema = z.object({
  token: z.string().min(1, 'Token undangan wajib diisi'),
  password: z
    .string()
    .min(8, 'Password minimal 8 karakter')
    .max(100, 'Password maksimal 100 karakter'),
});

export type LoginInput = z.infer<typeof loginSchema>;
export type RefreshInput = z.infer<typeof refreshSchema>;
export type ChangePasswordInput = z.infer<typeof changePasswordSchema>;
export type GoogleAuthInput = z.infer<typeof googleAuthSchema>;
export type AcceptInvitationInput = z.infer<typeof acceptInvitationSchema>;

