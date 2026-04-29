const prisma = require('../lib/prisma');
const { fmtAccount, fmtTransaction } = require('../lib/format');
const { startOfMonth, endOfMonth, subMonths, format } = require('date-fns');

exports.getDashboard = async (req, res) => {
  try {
    const userId = req.user._id;
    const now = new Date();
    const thisMonthStart = startOfMonth(now);
    const thisMonthEnd = endOfMonth(now);
    const lastMonthStart = startOfMonth(subMonths(now, 1));
    const lastMonthEnd = endOfMonth(subMonths(now, 1));

    const [accounts, recentTransactions, thisMoTxns, lastMoTxns] = await Promise.all([
      prisma.account.findMany({ where: { userId, isActive: true } }),
      prisma.transaction.findMany({
        where: { userId },
        include: {
          account: { select: { id: true, name: true, color: true, icon: true, currency: true } },
          toAccount: { select: { id: true, name: true, color: true, icon: true, currency: true } },
          category: { select: { id: true, name: true, color: true, icon: true } },
        },
        orderBy: { date: 'desc' },
        take: 10,
      }),
      prisma.transaction.findMany({
        where: { userId, date: { gte: thisMonthStart, lte: thisMonthEnd }, type: { in: ['income', 'expense'] } },
        select: { type: true, amount: true, account: { select: { currency: true } } },
      }),
      prisma.transaction.findMany({
        where: { userId, date: { gte: lastMonthStart, lte: lastMonthEnd }, type: { in: ['income', 'expense'] } },
        select: { type: true, amount: true, account: { select: { currency: true } } },
      }),
    ]);

    const aggregateByCurrency = (rows) => {
      const byCur = {};
      for (const r of rows) {
        const cur = r.account?.currency || 'IDR';
        if (!byCur[cur]) byCur[cur] = { income: 0, expense: 0, savings: 0 };
        if (r.type === 'income') byCur[cur].income += r.amount;
        else byCur[cur].expense += r.amount;
      }
      for (const c of Object.values(byCur)) c.savings = c.income - c.expense;
      return byCur;
    };

    const sumAll = (rows, type) => rows.filter((r) => r.type === type).reduce((s, r) => s + r.amount, 0);

    const sumByType = (rows) => {
      const income = sumAll(rows, 'income');
      const expense = sumAll(rows, 'expense');
      return { income, expense, savings: income - expense };
    };

    const totalBalance = accounts.reduce((s, a) => s + a.balance, 0);

    const balancesByCurrency = {};
    accounts.forEach((a) => {
      const cur = a.currency || 'IDR';
      balancesByCurrency[cur] = (balancesByCurrency[cur] || 0) + a.balance;
    });

    res.json({
      accounts: accounts.map(fmtAccount),
      totalBalance,
      balancesByCurrency,
      thisMonth: sumByType(thisMoTxns),
      lastMonth: sumByType(lastMoTxns),
      thisMonthByCurrency: aggregateByCurrency(thisMoTxns),
      recentTransactions: recentTransactions.map(fmtTransaction),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getBalanceHistory = async (req, res) => {
  try {
    const userId = req.user._id;
    const now = new Date();

    const accounts = await prisma.account.findMany({
      where: { userId, isActive: true },
      select: { balance: true },
    });
    const currentBalance = accounts.reduce((s, a) => s + a.balance, 0);

    // Get all transactions for the last 12 months
    const from = startOfMonth(subMonths(now, 11));
    const txns = await prisma.transaction.findMany({
      where: { userId, date: { gte: from } },
      select: { type: true, amount: true, date: true },
    });

    // Build month buckets
    const months = Array.from({ length: 12 }, (_, i) => {
      const d = subMonths(now, 11 - i);
      return {
        start: startOfMonth(d),
        end: endOfMonth(d),
        label: format(d, 'MMM yyyy'),
      };
    });

    // Compute balance at end of each month going backwards from current
    // balance[i] = currentBalance - net(transactions after months[i].end)
    let cumulativeNet = 0;
    const history = new Array(12);
    for (let i = 11; i >= 0; i--) {
      history[i] = { month: months[i].label, balance: currentBalance - cumulativeNet };
      const monthNet = txns
        .filter((tx) => tx.date >= months[i].start && tx.date <= months[i].end)
        .reduce((s, tx) => s + (tx.type === 'income' ? tx.amount : -tx.amount), 0);
      cumulativeNet += monthNet;
    }

    res.json(history);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
