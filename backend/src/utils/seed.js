require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const bcrypt = require('bcryptjs');
const prisma = require('../lib/prisma');
const { DEFAULT_CATEGORIES } = require('../config/passport');

const randomBetween = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const daysAgo = (n) => new Date(Date.now() - n * 24 * 60 * 60 * 1000);

async function seed() {
  console.log('Seeding database...');

  await prisma.transaction.deleteMany({ where: { user: { isDummy: true } } });
  await prisma.account.deleteMany({ where: { user: { isDummy: true } } });
  await prisma.category.deleteMany({ where: { user: { isDummy: true } } });
  await prisma.user.deleteMany({ where: { isDummy: true } });

  const password = await bcrypt.hash('password123', 10);
  const user = await prisma.user.create({
    data: { name: 'John Doe', email: 'john@example.com', password, isDummy: true },
  });

  await prisma.category.createMany({
    data: DEFAULT_CATEGORIES.map((c) => ({ ...c, userId: user.id, isDefault: true })),
  });

  const accounts = await Promise.all([
    prisma.account.create({ data: { userId: user.id, name: 'Cash', type: 'cash', balance: 500000, color: '#52c41a', icon: 'wallet' } }),
    prisma.account.create({ data: { userId: user.id, name: 'BCA Bank', type: 'bank', balance: 15000000, color: '#1890ff', icon: 'bank' } }),
    prisma.account.create({ data: { userId: user.id, name: 'GoPay', type: 'e-wallet', balance: 300000, color: '#00aa5b', icon: 'mobile' } }),
    prisma.account.create({ data: { userId: user.id, name: 'OVO', type: 'e-wallet', balance: 150000, color: '#4c3494', icon: 'mobile' } }),
  ]);

  const categories = await prisma.category.findMany({ where: { userId: user.id } });
  const incomeCats = categories.filter((c) => c.type === 'income');
  const expenseCats = categories.filter((c) => c.type === 'expense');

  const txData = [];
  for (let i = 90; i >= 0; i--) {
    const date = daysAgo(i);
    if (date.getDate() === 1 || date.getDate() === 15) {
      txData.push({
        userId: user.id,
        accountId: accounts[1].id,
        categoryId: incomeCats[0].id,
        amount: 8000000,
        type: 'income',
        date,
        note: 'Monthly salary',
      });
    }
    if (randomBetween(0, 1)) {
      txData.push({
        userId: user.id,
        accountId: accounts[randomBetween(0, accounts.length - 1)].id,
        categoryId: expenseCats[randomBetween(0, expenseCats.length - 1)].id,
        amount: randomBetween(15000, 350000),
        type: 'expense',
        date,
        note: '',
      });
    }
    if (i % 7 === 0) {
      txData.push({
        userId: user.id,
        accountId: accounts[randomBetween(0, accounts.length - 1)].id,
        categoryId: expenseCats[randomBetween(0, 3)].id,
        amount: randomBetween(50000, 500000),
        type: 'expense',
        date,
        note: 'Weekly expense',
      });
    }
  }

  await prisma.transaction.createMany({ data: txData });

  // Recalculate balances from seed transactions
  const balanceMap = {};
  accounts.forEach((a) => { balanceMap[a.id] = a.balance; });
  txData.forEach((tx) => {
    balanceMap[tx.accountId] = (balanceMap[tx.accountId] || 0) + (tx.type === 'income' ? tx.amount : -tx.amount);
  });
  await Promise.all(
    accounts.map((a) =>
      prisma.account.update({ where: { id: a.id }, data: { balance: balanceMap[a.id] } })
    )
  );

  console.log(`Seeded: user=${user.email}, accounts=${accounts.length}, transactions=${txData.length}`);
  await prisma.$disconnect();
}

seed().catch(async (err) => {
  console.error(err);
  await prisma.$disconnect();
  process.exit(1);
});
