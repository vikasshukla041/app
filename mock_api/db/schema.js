import { sqliteTable, text, integer, real } from 'drizzle-orm/sqlite-core';

export const users = sqliteTable('users', {
  id: text('id').primaryKey(),
  username: text('username').notNull().unique(),
  passwordHash: text('password_hash').notNull(),
  fullName: text('full_name').notNull(),
});

export const userTokens = sqliteTable('user_tokens', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  userId: text('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  fcmToken: text('fcm_token').notNull().unique(),
});

export const portfolios = sqliteTable('portfolios', {
  id: text('id').primaryKey(),
  userId: text('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  currency: text('currency').notNull().default('EUR'),
  netPortfolioValue: real('net_portfolio_value').notNull(),
  dailyReturnAmount: real('daily_return_amount').notNull(),
  dailyReturnPercentage: real('daily_return_percentage').notNull(),
});

export const positions = sqliteTable('positions', {
  id: text('id').primaryKey(),
  portfolioId: text('portfolio_id').notNull().references(() => portfolios.id, { onDelete: 'cascade' }),
  symbol: text('symbol').notNull(),
  name: text('name').notNull(),
  shares: real('shares').notNull(),
  avgPrice: real('avg_price').notNull(),
  currentPrice: real('current_price').notNull(),
  totalValue: real('total_value').notNull(),
  dailyChange: real('daily_change').notNull(),
});
