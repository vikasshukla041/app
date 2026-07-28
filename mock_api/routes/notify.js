import { OpenAPIHono, createRoute, z } from '@hono/zod-openapi';
import { eq } from 'drizzle-orm';
import { db } from '../db/index.js';
import * as schema from '../db/schema.js';
import { sendMulticastNotification } from '../services/firebase.js';
import { CommonErrorSchema, SimpleSuccessSchema } from './schemas.js';

const notifyRouter = new OpenAPIHono();

// Schemas
const NotifySendRequestSchema = z.object({
  username: z.string().openapi({ example: 'demo' }),
  title: z.string().openapi({ example: 'Market Alert' }),
  body: z.string().openapi({ example: 'EUR/USD has broken through resistance!' }),
});

// Routes Specifications
const sendNotificationRoute = createRoute({
  method: 'post',
  path: '/send', // Mounted under /api/notify in server.js
  request: {
    body: {
      content: {
        'application/json': {
          schema: NotifySendRequestSchema,
        },
      },
    },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: SimpleSuccessSchema } },
      description: 'Push notification successfully triggered',
    },
    404: {
      content: { 'application/json': { schema: CommonErrorSchema } },
      description: 'Target user or active device tokens not found',
    },
  },
});

// Handlers
notifyRouter.openapi(sendNotificationRoute, async (c) => {
  const { username, title, body } = c.req.valid('json');

  const user = await db.query.users.findFirst({
    where: eq(schema.users.username, username),
  });
  if (!user) {
    return c.json({ success: false, message: 'User profile not found' }, 404);
  }

  const tokens = await db.query.userTokens.findMany({
    where: eq(schema.userTokens.userId, user.id),
  });

  if (tokens.length === 0) {
    return c.json({ success: false, message: 'No registered devices found for this account' }, 404);
  }

  console.log(`\n--- Dispatching Push Notification to user "${username}" ---`);
  console.log(`Payload: ${JSON.stringify({ notification: { title, body } }, null, 2)}`);

  const result = await sendMulticastNotification({
    tokens: tokens.map(t => t.fcmToken),
    title,
    body
  });

  return c.json({
    success: result.success,
    message: result.message
  }, 200);
});

export default notifyRouter;
