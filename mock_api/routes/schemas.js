import { z } from '@hono/zod-openapi';

export const CommonErrorSchema = z.object({
  success: z.boolean().openapi({ example: false }),
  message: z.string().openapi({ example: 'Error description details' }),
});

export const SimpleSuccessSchema = z.object({
  success: z.boolean().openapi({ example: true }),
  message: z.string().openapi({ example: 'Operation completed successfully' }),
});
