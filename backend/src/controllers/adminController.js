const prisma = require('../lib/prisma');
const fcmService = require('../services/fcmService');

exports.getStats = async (req, res) => {
  try {
    const [totalUsers, totalReminders, totalTransactions] = await Promise.all([
      prisma.user.count({ where: { isAdmin: false } }),
      prisma.adminNotification.count(),
      prisma.transaction.count(),
    ]);
    res.json({ totalUsers, totalReminders, totalTransactions });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getUsers = async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      where: { isAdmin: false },
      select: {
        id: true,
        name: true,
        email: true,
        avatar: true,
        createdAt: true,
        _count: {
          select: {
            transactions: true,
            reminders: true,
            accounts: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.broadcastReminder = async (req, res) => {
  try {
    const { title, note, scheduledAt, repeatType, targetUserIds } = req.body;
    if (!title || !scheduledAt) {
      return res.status(400).json({ message: 'title and scheduledAt are required' });
    }

    let userIds;
    if (!targetUserIds || targetUserIds === 'all') {
      const users = await prisma.user.findMany({
        where: { isAdmin: false },
        select: { id: true },
      });
      userIds = users.map((u) => u.id);
    } else {
      userIds = Array.isArray(targetUserIds) ? targetUserIds : [targetUserIds];
    }

    if (userIds.length === 0) {
      return res.json({ message: 'No users to notify', count: 0 });
    }

    // Save to DB (for polling fallback when app is open)
    await prisma.adminNotification.createMany({
      data: userIds.map((userId) => ({
        userId,
        title,
        note: note || null,
        scheduledAt: new Date(scheduledAt),
        repeatType: repeatType || 'none',
      })),
    });

    // FCM push: delivers instantly even when app is closed/background
    const usersWithTokens = await prisma.user.findMany({
      where: { id: { in: userIds }, fcmToken: { not: null } },
      select: { fcmToken: true },
    });
    const tokens = usersWithTokens.map((u) => u.fcmToken).filter(Boolean);
    if (tokens.length > 0) {
      await fcmService.sendToTokens(tokens, {
        title: `📢 ${title}`,
        body: note || 'New announcement from BuxBux',
      });
    }

    res.json({ message: `Notification sent to ${userIds.length} user(s)`, count: userIds.length });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
