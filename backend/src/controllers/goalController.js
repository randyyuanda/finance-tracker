const prisma = require('../lib/prisma');

exports.getGoals = async (req, res) => {
  try {
    const goals = await prisma.goal.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
    });
    res.json(goals);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createGoal = async (req, res) => {
  try {
    const { name, targetAmount, deadline, color } = req.body;
    const goal = await prisma.goal.create({
      data: {
        userId: req.user.id,
        name,
        targetAmount: parseFloat(targetAmount),
        deadline: deadline ? new Date(deadline) : null,
        color: color || '#1890ff',
      },
    });
    res.status(201).json(goal);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateGoal = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, targetAmount, currentAmount, deadline, color, isCompleted } = req.body;
    
    const goal = await prisma.goal.update({
      where: { id, userId: req.user.id },
      data: {
        name,
        targetAmount: targetAmount !== undefined ? parseFloat(targetAmount) : undefined,
        currentAmount: currentAmount !== undefined ? parseFloat(currentAmount) : undefined,
        deadline: deadline ? new Date(deadline) : deadline === null ? null : undefined,
        color,
        isCompleted,
      },
    });
    res.json(goal);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteGoal = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.goal.delete({
      where: { id, userId: req.user.id },
    });
    res.json({ message: 'Goal deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
