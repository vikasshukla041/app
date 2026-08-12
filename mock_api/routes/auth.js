import { OpenAPIHono, createRoute, z } from '@hono/zod-openapi';
import { eq } from 'drizzle-orm';
import { db } from '../db/index.js';
import * as schema from '../db/schema.js';
import { issueTokenPair, userIdFromRefreshToken } from '../middleware/auth.js';
import { CommonErrorSchema } from './schemas.js';

const authRouter = new OpenAPIHono();

// Schemas
const LoginRequestSchema = z.object({
  username: z.string().openapi({ example: 'demo' }),
  password: z.string().openapi({ example: 'password123' }),
});

const UserSchema = z.object({
  username: z.string().openapi({ example: 'demo' }),
  fullName: z.string().openapi({ example: 'Demo Investor' }),
  id: z.string().openapi({ example: 'user_demo_123' }),
});

const LoginResponseSchema = z.object({
  success: z.boolean().openapi({ example: true }),
  accessToken: z.string().openapi({ example: 'activotrade_mock_jwt_token_for_user_demo_123' }),
  refreshToken: z.string().openapi({ example: 'activotrade_mock_refresh_token_for_user_demo_123.6f1c...' }),
  user: UserSchema,
});

const RefreshRequestSchema = z.object({
  refreshToken: z.string().openapi({ example: 'activotrade_mock_refresh_token_for_user_demo_123.6f1c...' }),
});

// No `user` field: the client already knows who it is from the session it
// saved at login, so re-sending it would be a second source of truth.
const RefreshResponseSchema = z.object({
  success: z.boolean().openapi({ example: true }),
  accessToken: z.string().openapi({ example: 'activotrade_mock_jwt_token_for_user_demo_123' }),
  refreshToken: z.string().openapi({ example: 'activotrade_mock_refresh_token_for_user_demo_123.9a3e...' }),
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
      description: 'Login successful, token pair generated',
    },
    401: {
      content: { 'application/json': { schema: CommonErrorSchema } },
      description: 'Invalid credentials provided',
    },
  },
});

const refreshRoute = createRoute({
  method: 'post',
  path: '/refresh', // Mounted under /api/auth in server.js
  request: {
    body: {
      content: {
        'application/json': {
          schema: RefreshRequestSchema,
        },
      },
    },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: RefreshResponseSchema } },
      description: 'A new access/refresh pair',
    },
    401: {
      content: { 'application/json': { schema: CommonErrorSchema } },
      description: 'Refresh token missing, malformed, or no longer valid',
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
      ...issueTokenPair(user.id),
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

authRouter.openapi(refreshRoute, async (c) => {
  const { refreshToken } = c.req.valid('json');

  const userId = userIdFromRefreshToken(refreshToken);
  if (!userId) {
    return c.json({ success: false, message: 'Invalid refresh token' }, 401);
  }

  // A token naming a user who no longer exists must not mint a fresh pair.
  const user = await db.query.users.findFirst({
    where: eq(schema.users.id, userId),
  });
  if (!user) {
    return c.json({ success: false, message: 'Invalid refresh token' }, 401);
  }

  return c.json({ success: true, ...issueTokenPair(user.id) }, 200);
});

export default authRouter;
