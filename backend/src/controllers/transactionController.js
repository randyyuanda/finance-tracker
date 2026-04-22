const Transaction = require('../models/Transaction');
const Account = require('../models/Account');

const applyBalance = async (accountId, type, amount, multiplier) => {
  const delta = type === 'income' ? amount * multiplier : -amount * multiplier;
  await Account.findByIdAndUpdate(accountId, { $inc: { balance: delta } });
};

exports.getTransactions = async (req, res) => {
  try {
    const { accountId, categoryId, type, startDate, endDate, page = 1, limit = 20 } = req.query;
    const filter = { userId: req.user._id };
    if (accountId) filter.accountId = accountId;
    if (categoryId) filter.categoryId = categoryId;
    if (type) filter.type = type;
    if (startDate || endDate) {
      filter.date = {};
      if (startDate) filter.date.$gte = new Date(startDate);
      if (endDate) filter.date.$lte = new Date(new Date(endDate).setHours(23, 59, 59, 999));
    }
    const skip = (Number(page) - 1) * Number(limit);
    const [transactions, total] = await Promise.all([
      Transaction.find(filter)
        .populate('accountId', 'name color icon')
        .populate('categoryId', 'name color icon')
        .sort({ date: -1 })
        .skip(skip)
        .limit(Number(limit)),
      Transaction.countDocuments(filter),
    ]);
    res.json({ transactions, total, page: Number(page), pages: Math.ceil(total / Number(limit)) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createTransaction = async (req, res) => {
  try {
    const { accountId, categoryId, amount, type, date, note, description } = req.body;
    const account = await Account.findOne({ _id: accountId, userId: req.user._id });
    if (!account) return res.status(404).json({ message: 'Account not found' });
    const transaction = await Transaction.create({
      userId: req.user._id,
      accountId,
      categoryId,
      amount,
      type,
      date: date || new Date(),
      note,
      description,
    });
    await applyBalance(accountId, type, amount, 1);
    const populated = await transaction.populate([
      { path: 'accountId', select: 'name color icon' },
      { path: 'categoryId', select: 'name color icon' },
    ]);
    res.status(201).json(populated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateTransaction = async (req, res) => {
  try {
    const old = await Transaction.findOne({ _id: req.params.id, userId: req.user._id });
    if (!old) return res.status(404).json({ message: 'Transaction not found' });

    await applyBalance(old.accountId, old.type, old.amount, -1);

    const { accountId, categoryId, amount, type, date, note, description } = req.body;
    const updated = await Transaction.findByIdAndUpdate(
      req.params.id,
      { accountId, categoryId, amount, type, date, note, description },
      { new: true, runValidators: true }
    )
      .populate('accountId', 'name color icon')
      .populate('categoryId', 'name color icon');

    await applyBalance(updated.accountId._id, updated.type, updated.amount, 1);
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteTransaction = async (req, res) => {
  try {
    const tx = await Transaction.findOneAndDelete({ _id: req.params.id, userId: req.user._id });
    if (!tx) return res.status(404).json({ message: 'Transaction not found' });
    await applyBalance(tx.accountId, tx.type, tx.amount, -1);
    res.json({ message: 'Transaction deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
