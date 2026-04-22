const prisma = require('../lib/prisma');
const { fmtAccount, fmtTransaction } = require('../lib/format');
const { startOfMonth, endOfMonth, subMonths } = require('date-fns');

exports.getDashboard = async (req, res) => {
  try {
    const userId = req.user._id;
    const now = new Date();
    const thisMonthStart = startOfMonth(now);
    const thisMonthEnd = endOfMonth(now);
    const lastMonthStart = startOfMonth(subMonths(now, 1));
    const lastMonthEnd = endOfMonth(subMonths(now, 1));

    const [accounts, recentTransactions, thisMo, lastMo] = await Promise.all([
      prisma.account.findMany({ where: { userId, isActive: true } }),
      prisma.transaction.findMany({
        where: { userId },
        include: {
          account: { select: { id: true, name: true, color: true, icon: true } },
          category: { select: { id: true, name: true, color: true, icon: true } },
        },
        orderBy: { date: 'desc' },
        take: 10,
      }),
      prisma.transaction.groupBy({
        by: ['type'],
        where: { userId, date: { gte: thisMonthStart, lte: thisMonthEnd } },
        _sum: { amount: true },
      }),
      prisma.transaction.groupBy({
        by: ['type'],
        where: { userId, date: { gte: lastMonthStart, lte: lastMonthEnd } },
        _sum: { amount: true },
      }),
    ]);

    const sumByType = (rows) => {
      const income = rows.find((r) => r.type === 'income')?._sum?.amount || 0;
      const expense = rows.find((r) => r.type === 'expense')?._sum?.amount || 0;
      return { income, expense, savings: income - expense };
    };

    const totalBalance = accounts.reduce((s, a) => s + a.balance, 0);

    res.json({
      accounts: accounts.map(fmtAccount),
      totalBalance,
      thisMonth: sumByType(thisMo),
      lastMonth: sumByType(lastMo),
      recentTransactions: recentTransactions.map(fmtTransaction),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
