const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const prisma = require('../lib/prisma');
const { seedUserDefaults } = require('../config/passport');
const { fmtUser } = require('../lib/format');
const { processRecurringTransactions } = require('../services/recurringService');

const generateToken = (id) =>
  jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });

exports.register = async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password)
      return res.status(400).json({ message: 'All fields are required' });

    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) return res.status(400).json({ message: 'Email already registered' });

    const hashed = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({ data: { name, email, password: hashed } });
    await seedUserDefaults(user.id);

    res.status(201).json({ token: generateToken(user.id), user: fmtUser(user) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !user.password)
      return res.status(401).json({ message: 'Invalid credentials' });

    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.status(401).json({ message: 'Invalid credentials' });

    // Process recurring transactions
    await processRecurringTransactions(user.id);

    res.json({ token: generateToken(user.id), user: fmtUser(user) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getMe = async (req, res) => {
  res.json(req.user);
};

exports.updateProfile = async (req, res) => {
  try {
    const { name, avatar } = req.body;
    const userId = req.user._id;

    const data = {};
    if (name && name.trim()) data.name = name.trim();
    if (avatar !== undefined) data.avatar = avatar;

    const updated = await prisma.user.update({ where: { id: userId }, data });
    res.json(fmtUser(updated));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.googleCallback = async (req, res) => {
  // Process recurring transactions
  await processRecurringTransactions(req.user.id);

  const token = generateToken(req.user.id);
  const clientUrl = (process.env.CLIENT_URL || 'http://localhost:3000').split(',')[0].trim();
  res.redirect(`${clientUrl}/oauth-callback?token=${token}`);
};
