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
    const { name, email, password, contactIdd, contactNumber } = req.body;
    if (!name || !email || !password)
      return res.status(400).json({ message: 'Name, email, and password are required' });

    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) return res.status(400).json({ message: 'Email already registered' });
    
    if (contactNumber) {
      const existingPhone = await prisma.user.findUnique({ where: { contactNumber } });
      if (existingPhone) return res.status(400).json({ message: 'Contact number already registered' });
    }

    const hashed = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({ data: { name, email, password: hashed, contactIdd, contactNumber } });
    await seedUserDefaults(user.id);

    // Send verification OTP automatically
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expires = new Date(Date.now() + 15 * 60000);
    await prisma.user.update({
      where: { id: user.id },
      data: { otpCode: await bcrypt.hash(otp, 10), otpExpires: expires },
    });
    await sendOtpEmail(email, otp);

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

exports.saveFcmToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) return res.status(400).json({ message: 'fcmToken required' });
    await prisma.user.update({ where: { id: req.user.id }, data: { fcmToken } });
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const { name, avatar, language, currency } = req.body;
    const userId = req.user.id || req.user._id;

    const data = {};
    if (name && name.trim()) data.name = name.trim();
    if (avatar !== undefined) data.avatar = avatar;
    if (language) data.language = language;
    if (currency) data.currency = currency;

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

exports.setPassword = async (req, res) => {
  try {
    const { password, contactIdd, contactNumber } = req.body;
    
    const existingUser = await prisma.user.findUnique({ where: { id: req.user.id } });
    
    if (!existingUser.password && !password) {
      return res.status(400).json({ message: 'Password is required' });
    }

    const data = {};
    if (password) data.password = await bcrypt.hash(password, 10);
    if (contactIdd) data.contactIdd = contactIdd;
    if (contactNumber) data.contactNumber = contactNumber;

    if (contactNumber && contactNumber !== existingUser.contactNumber) {
      const existingPhone = await prisma.user.findUnique({ where: { contactNumber } });
      if (existingPhone) return res.status(400).json({ message: 'Contact number already registered' });
    }

    const user = await prisma.user.update({
      where: { id: req.user.id },
      data,
    });
    res.json(fmtUser(user));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

const { sendOtpEmail } = require('../services/emailService');

exports.requestOtp = async (req, res) => {
  try {
    const { email } = req.body;
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) return res.status(404).json({ message: 'User not found' });

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expires = new Date(Date.now() + 15 * 60000); // 15 mins

    await prisma.user.update({
      where: { id: user.id },
      data: { otpCode: await bcrypt.hash(otp, 10), otpExpires: expires },
    });

    const sent = await sendOtpEmail(email, otp);
    if (!sent) return res.status(500).json({ message: 'Failed to send OTP email' });

    res.json({ message: 'OTP sent to email' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.verifyOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !user.otpCode || !user.otpExpires)
      return res.status(400).json({ message: 'Invalid or expired OTP' });

    if (user.otpExpires < new Date())
      return res.status(400).json({ message: 'OTP has expired' });

    const match = await bcrypt.compare(otp, user.otpCode);
    if (!match) return res.status(400).json({ message: 'Invalid OTP' });

    res.json({ message: 'OTP verified successfully', token: generateToken(user.id) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.resetPassword = async (req, res) => {
  try {
    // We expect the user to pass the token obtained from verifyOtp in the header,
    // so this is a protected route. Or they can reset it immediately after verification.
    const { password } = req.body;
    if (!password) return res.status(400).json({ message: 'Password is required' });

    const hashed = await bcrypt.hash(password, 10);
    const user = await prisma.user.update({
      where: { id: req.user.id },
      data: { password: hashed, otpCode: null, otpExpires: null },
    });

    res.json(fmtUser(user));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
