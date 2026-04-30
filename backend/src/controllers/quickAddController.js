const prisma = require('../lib/prisma');

const DEFAULT_CONFIGS = [
  { id: 'q1', type: 'expense', amount: 10000, label: '-10k' },
  { id: 'q2', type: 'expense', amount: 50000, label: '-50k' },
  { id: 'q3', type: 'income', amount: 10000, label: '+10k' },
  { id: 'q4', type: 'income', amount: 50000, label: '+50k' },
];

exports.getConfigs = async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user._id },
      select: { quickAddConfigs: true },
    });
    res.json(user?.quickAddConfigs ?? DEFAULT_CONFIGS);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.saveConfigs = async (req, res) => {
  try {
    const configs = req.body;
    if (!Array.isArray(configs)) return res.status(400).json({ message: 'configs must be an array' });
    await prisma.user.update({
      where: { id: req.user._id },
      data: { quickAddConfigs: configs },
    });
    res.json(configs);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
