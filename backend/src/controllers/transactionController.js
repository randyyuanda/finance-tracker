const prisma = require('../lib/prisma');
const { fmtTransaction } = require('../lib/format');

const TX_INCLUDE = {
  account: { select: { id: true, name: true, color: true, icon: true } },
  category: { select: { id: true, name: true, color: true, icon: true } },
};

const balanceDelta = (type, amount) => (type === 'income' ? amount : -amount);

exports.getTransactions = async (req, res) => {
  try {
    const { accountId, categoryId, type, startDate, endDate, page = 1, limit = 20 } = req.query;
    const where = { userId: req.user._id };
    if (accountId) where.accountId = accountId;
    if (categoryId) where.categoryId = categoryId;
    if (type) where.type = type;
    if (startDate || endDate) {
      where.date = {};
      if (startDate) where.date.gte = new Date(startDate);
      if (endDate) where.date.lte = new Date(new Date(endDate).setHours(23, 59, 59, 999));
    }
    const skip = (Number(page) - 1) * Number(limit);
    const [rows, total] = await Promise.all([
      prisma.transaction.findMany({
        where,
        include: TX_INCLUDE,
        orderBy: { date: 'desc' },
        skip,
        take: Number(limit),
      }),
      prisma.transaction.count({ where }),
    ]);
    res.json({
      transactions: rows.map(fmtTransaction),
      total,
      page: Number(page),
      pages: Math.ceil(total / Number(limit)),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createTransaction = async (req, res) => {
  try {
    const { accountId, categoryId, amount, type, date, note, description } = req.body;
    const account = await prisma.account.findFirst({ where: { id: accountId, userId: req.user._id } });
    if (!account) return res.status(404).json({ message: 'Account not found' });

    const [tx] = await prisma.$transaction([
      prisma.transaction.create({
        data: {
          userId: req.user._id,
          accountId,
          categoryId,
          amount: Number(amount),
          type,
          date: date ? new Date(date) : new Date(),
          note,
          description,
        },
        include: TX_INCLUDE,
      }),
      prisma.account.update({
        where: { id: accountId },
        data: { balance: { increment: balanceDelta(type, Number(amount)) } },
      }),
    ]);
    res.status(201).json(fmtTransaction(tx));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateTransaction = async (req, res) => {
  try {
    const old = await prisma.transaction.findFirst({ where: { id: req.params.id, userId: req.user._id } });
    if (!old) return res.status(404).json({ message: 'Transaction not found' });

    const { accountId, categoryId, amount, type, date, note, description } = req.body;
    const newAmount = Number(amount);

    const [tx] = await prisma.$transaction([
      prisma.transaction.update({
        where: { id: req.params.id },
        data: { accountId, categoryId, amount: newAmount, type, date: date ? new Date(date) : undefined, note, description },
        include: TX_INCLUDE,
      }),
      // reverse old balance effect
      prisma.account.update({
        where: { id: old.accountId },
        data: { balance: { increment: -balanceDelta(old.type, old.amount) } },
      }),
      // apply new balance effect
      prisma.account.update({
        where: { id: accountId || old.accountId },
        data: { balance: { increment: balanceDelta(type || old.type, newAmount || old.amount) } },
      }),
    ]);
    res.json(fmtTransaction(tx));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteTransaction = async (req, res) => {
  try {
    const tx = await prisma.transaction.findFirst({ where: { id: req.params.id, userId: req.user._id } });
    if (!tx) return res.status(404).json({ message: 'Transaction not found' });

    await prisma.$transaction([
      prisma.transaction.delete({ where: { id: req.params.id } }),
      prisma.account.update({
        where: { id: tx.accountId },
        data: { balance: { increment: -balanceDelta(tx.type, tx.amount) } },
      }),
    ]);
    res.json({ message: 'Transaction deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
