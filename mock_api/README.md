# ActivoTrade Mock Backend Server

This directory contains the lightweight HonoJS mock backend server for the ActivoTrade App. It provides REST endpoint logic, database persistence via SQLite, and local offline API documentation via Stoplight Elements.

---

## Technology Stack

* **Router & Framework:** [HonoJS](https://hono.dev/) running on Node.js.
* **Database & ORM:** [Drizzle ORM](https://orm.drizzle.team/) with `@libsql/client` writing to a local `sqlite.db` database.
* **Interactive API Reference:** [Stoplight Elements](https://stoplight.io/open-source/elements) served 100% offline from local node modules.
* **Push Notifications:** `firebase-admin` (configured with a mock logging fallback).

---

## Getting Started

### 1. Install Dependencies
This project uses `pnpm`. Install the dependencies by running:
```bash
pnpm install
```

### 2. Initialize Database & Push Schema
Sync the SQLite database schema with Drizzle:
```bash
pnpm drizzle-kit push
```
*(This creates the `sqlite.db` file in the current directory and sets up the tables).*

### 3. Run the Server
Launch the server locally:
```bash
pnpm start
```
* The server will boot, automatically seed default mock portfolio data for the `demo` user, and listen on **`http://localhost:3000`**.
* The interactive API documentation console will be hosted locally at **`http://localhost:3000/docs`**.

---

## Testing & Authentication

### User Authorization
Endpoints like fetching portfolio balances require Bearer token authorization:
- **Mock Username:** `demo`
- **Mock Password:** `password123`
- **Bearer Token:** `activotrade_mock_jwt_token_for_user_demo_123`

### Real Firebase Push Config (Optional)
To send real remote push notifications instead of logging payloads to the console:
1. Download a **Service Account Key JSON** file from your Firebase Console.
2. Rename it to `firebase-service-account.json` and save it directly in this `backend/` directory.
3. Restart the Hono server.
