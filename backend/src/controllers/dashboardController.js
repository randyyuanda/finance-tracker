const Transaction = require('../models/Transaction');
const Account = require('../models/Account');
const { startOfMonth, endOfMonth, subMonths } = require('date-fns');

exports.getDashboard = async (req, res) => {
  try {
    const userId = req.user._id;
    const now = new Date();
    const thisMonthStart = startOfMonth(now);
    const thisMonthEnd = endOfMonth(now);
    const lastMonthStart = startOfMonth(subMonths(now, 1));
    const lastMonthEnd = endOfMonth(subMonths(now, 1));

    const [accounts, thisMonthTx, lastMonthTx, recentTransactions] = await Promise.all([
      Account.find({ userId, isActive: true }),
      Transaction.aggregate([
        { $match: { userId, date: { $gte: thisMonthStart, $lte: thisMonthEnd } } },
        { $group: { _id: '$type', total: { $sum: '$amount' } } },
      ]),
      Transaction.aggregate([
        { $match: { userId, date: { $gte: lastMonthStart, $lte: lastMonthEnd } } },
        { $group: { _id: '$type', total: { $sum: '$amount' } } },
      ]),
      Transaction.find({ userId })
        .populate('accountId', 'name color icon')
        .populate('categoryId', 'name color icon')
        .sort({ date: -1 })
        .limit(10),
    ]);

    const sumByType = (arr) => {
      const income = arr.find((x) => x._id === 'income')?.total || 0;
      const expense = arr.find((x) => x._id === 'expense')?.total || 0;
      return { income, expense, savings: income - expense };
    };

    const totalBalance = accounts.reduce((sum, a) => sum + a.balance, 0);

    res.json({
      accounts,
      totalBalance,
      thisMonth: sumByType(thisMonthTx),
      lastMonth: sumByType(lastMonthTx),
      recentTransactions,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
