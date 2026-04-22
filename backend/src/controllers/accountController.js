const Account = require('../models/Account');

exports.getAccounts = async (req, res) => {
  try {
    const accounts = await Account.find({ userId: req.user._id, isActive: true }).sort('name');
    res.json(accounts);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createAccount = async (req, res) => {
  try {
    const account = await Account.create({ ...req.body, userId: req.user._id });
    res.status(201).json(account);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateAccount = async (req, res) => {
  try {
    const { balance, ...rest } = req.body;
    const account = await Account.findOneAndUpdate(
      { _id: req.params.id, userId: req.user._id },
      rest,
      { new: true, runValidators: true }
    );
    if (!account) return res.status(404).json({ message: 'Account not found' });
    res.json(account);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteAccount = async (req, res) => {
  try {
    const account = await Account.findOneAndUpdate(
      { _id: req.params.id, userId: req.user._id },
      { isActive: false },
      { new: true }
    );
    if (!account) return res.status(404).json({ message: 'Account not found' });
    res.json({ message: 'Account deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
