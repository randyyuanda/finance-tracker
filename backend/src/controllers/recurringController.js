const prisma = require('../lib/prisma');

exports.getRecurringTransactions = async (req, res) => {
  try {
    const rts = await prisma.recurringTransaction.findMany({
      where: { userId: req.user.id },
      include: {
        account: true,
        category: true,
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json(rts);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createRecurringTransaction = async (req, res) => {
  try {
    const { accountId, categoryId, type, amount, note, frequency, nextDue } = req.body;
    const rt = await prisma.recurringTransaction.create({
      data: {
        userId: req.user.id,
        accountId,
        categoryId,
        type,
        amount: parseFloat(amount),
        note,
        frequency,
        nextDue: new Date(nextDue),
      },
      include: {
        account: true,
        category: true,
      },
    });
    res.status(201).json(rt);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateRecurringTransaction = async (req, res) => {
  try {
    const { id } = req.params;
    const { accountId, categoryId, type, amount, note, frequency, nextDue, isActive } = req.body;
    
    const rt = await prisma.recurringTransaction.update({
      where: { id, userId: req.user.id },
      data: {
        accountId,
        categoryId,
        type,
        amount: amount !== undefined ? parseFloat(amount) : undefined,
        note,
        frequency,
        nextDue: nextDue ? new Date(nextDue) : undefined,
        isActive,
      },
      include: {
        account: true,
        category: true,
      },
    });
    res.json(rt);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteRecurringTransaction = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.recurringTransaction.delete({
      where: { id, userId: req.user.id },
    });
    res.json({ message: 'Recurring transaction deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
