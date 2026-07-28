# Backend Developer Documentation: 

This document provides developer guidelines for extending the  HonoJS backend, including directory structures, adding new API endpoints with OpenAPI specs, and managing database schema updates.

---

## 1. Directory Structure

```
backend/
├── db/
│   ├── index.js            # DB connection client and seeding logic
│   └── schema.js           # Drizzle ORM table schemas (SQLite)
├── docs/
│   └── stoplight.js        # Offline Stoplight Elements routing & HTML page
├── middleware/
│   └── auth.js             # Authentication helpers (e.g. extractUserId)
├── routes/
│   ├── schemas.js          # Shared request/response schemas (e.g. CommonErrorSchema)
│   ├── auth.js             # Authentication endpoint schemas & handlers
│   ├── user.js             # User balance and FCM registration endpoints
│   └── notify.js           # Push notification dispatching endpoints
├── services/
│   └── firebase.js         # Firebase Admin SDK & notifications service
├── drizzle/                # Auto-generated database migration scripts
├── .npmrc                  # Local pnpm environment overrides
├── drizzle.config.js       # Drizzle CLI toolkit configs
├── package.json            # Script definitions and package versions
├── pnpm-workspace.yaml     # Local workspace config file
├── server.js               # Entry point (initializes Hono, mounts routers, starts server)
└── sqlite.db               # Local SQLite database file
```

---

## 2. Adding a New API Endpoint with OpenAPI

To add a new endpoint, follow this three-step process:

### Step A: Determine the Appropriate Router or Create a New One
* If the endpoint is user-related, open [backend/routes/user.js](./backend/routes/user.js).
* If you need to create a new category (e.g., `/api/trades`), create a new file like `backend/routes/trades.js`, initialize it with `const tradesRouter = new OpenAPIHono()`, and export it as default. You must then register it in [backend/server.js](./backend/server.js):
  ```javascript
  import tradesRouter from './routes/trades.js';
  app.route('/api/trades', tradesRouter);
  ```

### Step B: Define the Request/Response Schemas
Define the shape of your request body or response JSON using `z`. If the schemas are shared across routes, declare them in [backend/routes/schemas.js](./backend/routes/schemas.js). Otherwise, place them at the top of your route file:
```javascript
const ProfileResponseSchema = z.object({
  success: z.boolean().openapi({ example: true }),
  profile: z.object({
    id: z.string().openapi({ example: 'user_demo_123' }),
    email: z.string().email().openapi({ example: 'demo@activotrade.com' }),
  }),
});
```

### Step C: Declare the Route Specification and Implement Handler
Define the route specification using `createRoute` and hook the handler using `.openapi()`:
```javascript
const profileRoute = createRoute({
  method: 'get',
  path: '/profile', // Path is relative to where the router is mounted in server.js (e.g. /api/user/profile)
  security: [{ BearerAuth: [] }],
  responses: {
    200: {
      content: { 'application/json': { schema: ProfileResponseSchema } },
      description: 'Profile details fetched successfully',
    },
    401: {
      content: { 'application/json': { schema: CommonErrorSchema } },
      description: 'Unauthorized access',
    },
  },
});

userRouter.openapi(profileRoute, async (c) => {
  const userId = extractUserId(c.req.header('Authorization'));
  if (!userId) {
    return c.json({ success: false, message: 'Unauthorized' }, 401);
  }

  const user = await db.query.users.findFirst({
    where: eq(schema.users.id, userId),
  });

  return c.json({
    success: true,
    profile: {
      id: user.id,
      email: `${user.username}@activotrade.com`
    }
  }, 200);
});
```

---

## 3. Updating the SQLite Database Schema

When you need to add new tables or modify columns, follow this workflow:

### Step 1: Edit the Schema File
Open [`backend/db/schema.js`](/backend/db/schema.js) and update your SQLite tables. For example, adding a `phoneNumber` column:
```javascript
export const users = sqliteTable('users', {
  id: text('id').primaryKey(),
  username: text('username').notNull().unique(),
  passwordHash: text('password_hash').notNull(),
  fullName: text('full_name').notNull(),
  phoneNumber: text('phone_number'), // <-- Added new column
});
```

### Step 2: Sync SQLite (Development environment)
Run the Drizzle push utility in your terminal:
```bash
pnpm drizzle-kit push
```
This inspects the schema file, compares it with the local `sqlite.db` file, and automatically runs the SQL alter commands.

### Step 3: Generate SQL Migrations (Production-ready alternative)
1. **Generate the SQL migration script:**
   ```bash
   pnpm drizzle-kit generate
   ```
2. **Apply the migrations to the database:**
   ```bash
   pnpm drizzle-kit migrate
   ```
