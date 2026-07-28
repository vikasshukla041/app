import { OpenAPIHono, createRoute, z } from '@hono/zod-openapi';
import { eq } from 'drizzle-orm';
import { db } from '../db/index.js';
import * as schema from '../db/schema.js';
import { extractUserId } from '../middleware/auth.js';
import { CommonErrorSchema, SimpleSuccessSchema } from './schemas.js';

const userRouter = new OpenAPIHono();

// Schemas
const RegisterTokenRequestSchema = z.object({
  fcmToken: z.string().openapi({ example: 'fcm_registration_token_123456789' }),
});

const PositionItemSchema = z.object({
  symbol: z.string().openapi({ example: 'SPY' }),
  name: z.string().openapi({ example: 'S&P 500 ETF Trust' }),
  shares: z.number().openapi({ example: 120 }),
  avgPrice: z.number().openapi({ example: 100.50 }),
  currentPrice: z.number().openapi({ example: 485.20 }),
  totalValue: z.number().openapi({ example: 58224.00 }),
  dailyChange: z.number().openapi({ example: 0.85 }),
});

const BalanceResponseSchema = z.object({
  success: z.boolean().openapi({ example: true }),
  data: z.object({
    accountNumber: z.string().openapi({ example: 'AT-12345-X' }),
    currency: z.string().openapi({ example: 'EUR' }),
    netPortfolioValue: z.number().openapi({ example: 124580.50 }),
    dailyReturnAmount: z.number().openapi({ example: 1845.20 }),
    dailyReturnPercentage: z.number().openapi({ example: 1.50 }),
    assetAllocation: z.object({
      cash: z.number().openapi({ example: 15450.00 }),
      mutualFunds: z.number().openapi({ example: 68130.50 }),
      fixedIncome: z.number().openapi({ example: 41000.00 }),
    }),
    positions: z.array(PositionItemSchema),
  }),
});

// Routes Specifications
const registerTokenRoute = createRoute({
  method: 'post',
  path: '/register-token', // Mounted under /api/user in server.js
  security: [{ BearerAuth: [] }],
  request: {
    body: {
      content: {
        'application/json': {
          schema: RegisterTokenRequestSchema,
        },
      },
    },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: SimpleSuccessSchema } },
      description: 'FCM token successfully registered to user account',
    },
    401: {
      content: { 'application/json': { schema: CommonErrorSchema } },
      description: 'Unauthorized access',
    },
  },
});

const balanceRoute = createRoute({
  method: 'get',
  path: '/balance', // Mounted under /api/user in server.js
  security: [{ BearerAuth: [] }],
  responses: {
    200: {
      content: { 'application/json': { schema: BalanceResponseSchema } },
      description: 'Portfolio balance and equity positions details',
    },
    401: {
      content: { 'application/json': { schema: CommonErrorSchema } },
      description: 'Unauthorized access',
    },
    404: {
      content: { 'application/json': { schema: CommonErrorSchema } },
      description: 'Portfolio database entry not found',
    },
  },
});

// Handlers
userRouter.openapi(registerTokenRoute, async (c) => {
  const userId = extractUserId(c.req.header('Authorization'));
  if (!userId) {
    return c.json({ success: false, message: 'Unauthorized access' }, 401);
  }

  const { fcmToken } = c.req.valid('json');

  const existing = await db.query.userTokens.findFirst({
    where: eq(schema.userTokens.fcmToken, fcmToken),
  });

  if (!existing) {
    await db.insert(schema.userTokens).values({ userId, fcmToken });
  } else if (existing.userId !== userId) {
    await db.update(schema.userTokens)
      .set({ userId })
      .where(eq(schema.userTokens.id, existing.id));
  }

  return c.json({
    success: true,
    message: 'FCM Token registered successfully'
  }, 200);
});

userRouter.openapi(balanceRoute, async (c) => {
  const userId = extractUserId(c.req.header('Authorization'));
  if (!userId) {
    return c.json({ success: false, message: 'Unauthorized access' }, 401);
  }

  const portfolio = await db.query.portfolios.findFirst({
    where: eq(schema.portfolios.userId, userId),
  });

  if (!portfolio) {
    return c.json({ success: false, message: 'Portfolio metadata not found' }, 404);
  }

  const posList = await db.query.positions.findMany({
    where: eq(schema.positions.portfolioId, portfolio.id),
  });

  return c.json({
    success: true,
    data: {
      accountNumber: 'AT-882910-X',
      currency: portfolio.currency,
      netPortfolioValue: portfolio.netPortfolioValue,
      dailyReturnAmount: portfolio.dailyReturnAmount,
      dailyReturnPercentage: portfolio.dailyReturnPercentage,
      assetAllocation: {
        cash: posList.filter(p => p.symbol.includes('CASH')).reduce((acc, p) => acc + p.totalValue, 0),
        mutualFunds: posList.filter(p => p.symbol === 'SPY' || p.symbol === 'IUSA').reduce((acc, p) => acc + p.totalValue, 0),
        fixedIncome: posList.filter(p => p.symbol === 'TLT').reduce((acc, p) => acc + p.totalValue, 0),
      },
      positions: posList.map(p => ({
        symbol: p.symbol,
        name: p.name,
        shares: p.shares,
        avgPrice: p.avgPrice,
        currentPrice: p.currentPrice,
        totalValue: p.totalValue,
        dailyChange: p.dailyChange
      }))
    }
  }, 200);
});

export default userRouter;
