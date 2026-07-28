import { OpenAPIHono, createRoute, z } from '@hono/zod-openapi';
import { eq } from 'drizzle-orm';
import { db } from '../db/index.js';
import * as schema from '../db/schema.js';
import { CommonErrorSchema } from './schemas.js';

const authRouter = new OpenAPIHono();

// Schemas
const LoginRequestSchema = z.object({
  username: z.string().openapi({ example: 'demo' }),
  password: z.string().openapi({ example: 'password123' }),
});

const LoginResponseSchema = z.object({
  success: z.boolean().openapi({ example: true }),
  token: z.string().openapi({ example: 'mock_jwt_token' }),
  user: z.object({
    username: z.string().openapi({ example: 'demo' }),
    fullName: z.string().openapi({ example: 'Demo Investor' }),
    id: z.string().openapi({ example: 'user_demo_123' }),
  }),
});

// Routes Specifications
const loginRoute = createRoute({
  method: 'post',
  path: '/login', // Mounted under /api/auth in server.js
  request: {
    body: {
      content: {
        'application/json': {
          schema: LoginRequestSchema,
        },
      },
    },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: LoginResponseSchema } },
      description: 'Login successful, token generated',
    },
    401: {
      content: { 'application/json': { schema: CommonErrorSchema } },
      description: 'Invalid credentials provided',
    },
  },
});

// Handlers
authRouter.openapi(loginRoute, async (c) => {
  const { username, password } = c.req.valid('json');
  
  const user = await db.query.users.findFirst({
    where: eq(schema.users.username, username),
  });

  if (user && user.passwordHash === password) {
    return c.json({
      success: true,
      token: `activotrade_mock_jwt_token_for_${user.id}`,
      user: {
        username: user.username,
        fullName: user.fullName,
        id: user.id
      }
    }, 200);
  }

  return c.json({
    success: false,
    message: 'Invalid username or password'
  }, 401);
});

export default authRouter;
