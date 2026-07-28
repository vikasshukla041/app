import { serve } from '@hono/node-server';
import { OpenAPIHono } from '@hono/zod-openapi';
import { seedDatabase } from './db/index.js';
import authRouter from './routes/auth.js';
import userRouter from './routes/user.js';
import notifyRouter from './routes/notify.js';
import docsRouter from './docs/stoplight.js';

// Initialize OpenAPIHono
const app = new OpenAPIHono();

// Logger middleware
app.use('*', async (c, next) => {
  const start = Date.now();
  await next();
  const duration = Date.now() - start;
  console.log(`[${new Date().toISOString()}] ${c.req.method} [${c.res.status}] - ${c.req.url} (${duration}ms)`);
});

// Initialize database data
await seedDatabase();

// ==========================================
// MOUNT SUB-ROUTERS
// ==========================================
app.route('/api/auth', authRouter);
app.route('/api/user', userRouter);
app.route('/api/notify', notifyRouter);
app.route('/', docsRouter);

// ==========================================
// OPENAPI SPECIFICATION CONFIG
// ==========================================

// Register BearerAuth component in the Zod-OpenAPI registry
app.openAPIRegistry.registerComponent('securitySchemes', 'BearerAuth', {
  type: 'http',
  scheme: 'bearer',
  bearerFormat: 'JWT',
  description: 'Input your Bearer token. Use `activotrade_mock_jwt_token_for_user_demo_123` to authorize.',
});

app.doc('/doc', {
  openapi: '3.0.0',
  info: {
    version: '1.0.0',
    title: 'ActivoTrade Backend Mock API Specs',
    description: 'Relational OpenAPI specs for developer testing.',
  },
});

// Start Node server on port 3000
const port = 3000;
console.log(`Starting \x1b[38;5;110mActivoTrade Mock API Server\x1b[39m on port ${port}...`);
console.log(`Interactive API documentation hosted at \x1b[32m[http://localhost:${port}/docs]\x1b[39m`);
serve({
  fetch: app.fetch,
  port: port
});
