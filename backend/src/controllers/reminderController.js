const prisma = require('../lib/prisma');

exports.getReminders = async (req, res) => {
  try {
    const { status } = req.query;
    const now = new Date();
    let where = { userId: req.user.id };

    if (status === 'completed') {
      where.isCompleted = true;
    } else if (status === 'overdue') {
      where.isCompleted = false;
      where.reminderDate = { lt: now };
    } else if (status === 'upcoming') {
      where.isCompleted = false;
      where.reminderDate = { gte: now };
    }

    const reminders = await prisma.reminder.findMany({
      where,
      orderBy: { reminderDate: 'asc' },
    });
    res.json(reminders);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createReminder = async (req, res) => {
  try {
    const { title, note, reminderDate, type, relatedId, repeatType } = req.body;
    const reminder = await prisma.reminder.create({
      data: {
        userId: req.user.id,
        title,
        note,
        reminderDate: new Date(reminderDate),
        type: type || 'custom',
        relatedId: relatedId || null,
        repeatType: repeatType || 'none',
      },
    });
    res.status(201).json(reminder);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateReminder = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, note, reminderDate, type, relatedId, isCompleted, repeatType } = req.body;
    const reminder = await prisma.reminder.update({
      where: { id, userId: req.user.id },
      data: {
        ...(title !== undefined && { title }),
        ...(note !== undefined && { note }),
        ...(reminderDate !== undefined && { reminderDate: new Date(reminderDate) }),
        ...(type !== undefined && { type }),
        ...(relatedId !== undefined && { relatedId }),
        ...(isCompleted !== undefined && { isCompleted }),
        ...(repeatType !== undefined && { repeatType }),
      },
    });
    res.json(reminder);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.toggleComplete = async (req, res) => {
  try {
    const { id } = req.params;
    const existing = await prisma.reminder.findFirst({ where: { id, userId: req.user.id } });
    if (!existing) return res.status(404).json({ message: 'Reminder not found' });
    const reminder = await prisma.reminder.update({
      where: { id },
      data: { isCompleted: !existing.isCompleted },
    });
    res.json(reminder);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteReminder = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.reminder.delete({ where: { id, userId: req.user.id } });
    res.json({ message: 'Reminder deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
