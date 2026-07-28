import { drizzle } from 'drizzle-orm/libsql';
import { createClient } from '@libsql/client';
import * as schema from './schema.js';
import { eq } from 'drizzle-orm';

const client = createClient({
  url: 'file:sqlite.db',
});

export const db = drizzle(client, { schema });

// Auto-seed function to make testing plug-and-play
export async function seedDatabase() {
  try {
    // 1. Seed Demo User if not exists
    const existingUser = await db.query.users.findFirst({
      where: eq(schema.users.username, 'demo'),
    });

    if (!existingUser) {
      console.log('Database empty. Seeding default demo data...');
      
      const userId = 'user_demo_123';
      const portfolioId = 'portfolio_demo_123';

      await db.insert(schema.users).values({
        id: userId,
        username: 'demo',
        passwordHash: 'password123', // stored in plain text for POC simplicity
        fullName: 'Demo Investor',
      });

      await db.insert(schema.portfolios).values({
        id: portfolioId,
        userId: userId,
        currency: 'EUR',
        netPortfolioValue: 124580.50,
        dailyReturnAmount: 1845.20,
        dailyReturnPercentage: 1.50,
      });

      await db.insert(schema.positions).values([
        {
          id: 'pos_1',
          portfolioId: portfolioId,
          symbol: 'SPY',
          name: 'S&P 500 ETF Trust',
          shares: 120,
          avgPrice: 420.50,
          currentPrice: 485.20,
          totalValue: 58224.00,
          dailyChange: 0.85,
        },
        {
          id: 'pos_2',
          portfolioId: portfolioId,
          symbol: 'TLT',
          name: 'iShares 20+ Year Treasury Bond ETF',
          shares: 410,
          avgPrice: 98.10,
          currentPrice: 100.00,
          totalValue: 41000.00,
          dailyChange: -0.12,
        },
        {
          id: 'pos_3',
          portfolioId: portfolioId,
          symbol: 'EUR.CASH',
          name: 'Euro Cash Account',
          shares: 15450,
          avgPrice: 1.00,
          currentPrice: 1.00,
          totalValue: 15450.00,
          dailyChange: 0.00,
        },
        {
          id: 'pos_4',
          portfolioId: portfolioId,
          symbol: 'IUSA',
          name: 'iShares Core S&P 500 UCITS ETF',
          shares: 220,
          avgPrice: 38.00,
          currentPrice: 45.03,
          totalValue: 9906.50,
          dailyChange: 1.10,
        },
      ]);
      console.log('Seeding completed successfully!');
    }
  } catch (error) {
    console.error('Failed to seed database:', error);
  }
}
