const prisma = require('../lib/prisma');
const { fmtAccount } = require('../lib/format');

exports.getAccounts = async (req, res) => {
  try {
    const accounts = await prisma.account.findMany({
      where: { userId: req.user._id, isActive: true },
      orderBy: { name: 'asc' },
    });
    res.json(accounts.map(fmtAccount));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createAccount = async (req, res) => {
  try {
    const { name, type, balance, currency, color, icon } = req.body;
    const account = await prisma.account.create({
      data: {
        userId: req.user._id,
        name,
        type: type || 'cash',
        balance: Number(balance) || 0,
        currency: currency || 'IDR',
        color: color || '#1890ff',
        icon: icon || 'wallet',
      },
    });
    res.status(201).json(fmtAccount(account));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateAccount = async (req, res) => {
  try {
    const { userId, balance: newBalanceRaw, ...otherFields } = req.body;
    const existing = await prisma.account.findFirst({
      where: { id: req.params.id, userId: req.user._id },
    });
    if (!existing) return res.status(404).json({ message: 'Account not found' });

    const accountData = { ...otherFields };
    const extraOps = [];

    if (newBalanceRaw !== undefined) {
      const newBalance = Number(newBalanceRaw);
      const diff = newBalance - existing.balance;

      if (Math.abs(diff) > 0.001) {
        const catType = diff > 0 ? 'income' : 'expense';
        let cat = await prisma.category.findFirst({
          where: { userId: req.user._id, name: 'Balance Adjustment', type: catType },
        });
        if (!cat) {
          cat = await prisma.category.create({
            data: { userId: req.user._id, name: 'Balance Adjustment', type: catType, color: '#faad14', icon: 'adjustment', isDefault: true },
          });
        }
        accountData.balance = { increment: diff };
        extraOps.push(
          prisma.transaction.create({
            data: { userId: req.user._id, accountId: req.params.id, categoryId: cat.id, amount: Math.abs(diff), type: catType, date: new Date(), note: 'Balance adjustment' },
          })
        );
      } else {
        accountData.balance = newBalance;
      }
    }

    const [account] = await prisma.$transaction([
      prisma.account.update({ where: { id: req.params.id }, data: accountData }),
      ...extraOps,
    ]);
    res.json(fmtAccount(account));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteAccount = async (req, res) => {
  try {
    const existing = await prisma.account.findFirst({
      where: { id: req.params.id, userId: req.user._id },
    });
    if (!existing) return res.status(404).json({ message: 'Account not found' });

    await prisma.account.update({
      where: { id: req.params.id },
      data: { isActive: false },
    });
    res.json({ message: 'Account deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
