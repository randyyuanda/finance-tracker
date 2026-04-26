const prisma = require('../lib/prisma');
const fcmService = require('../services/fcmService');

exports.sendReminderPushes = async (req, res) => {
  const secret = req.headers['x-cron-secret'] || req.query.secret;
  if (process.env.CRON_SECRET && secret !== process.env.CRON_SECRET) {
    return res.status(401).json({ message: 'Unauthorized' });
  }

  try {
    const now = new Date();
    const windowEnd = new Date(now.getTime() + 65 * 60 * 1000); // next 65 min

    // Find reminders due within the next 65 minutes that aren't completed
    const due = await prisma.reminder.findMany({
      where: {
        isCompleted: false,
        reminderDate: { gte: now, lte: windowEnd },
      },
      include: {
        user: { select: { fcmToken: true } },
      },
    });

    if (due.length === 0) return res.json({ sent: 0 });

    let sent = 0;
    for (const reminder of due) {
      const token = reminder.user?.fcmToken;
      if (!token) continue;
      try {
        await fcmService.sendToTokens([token], {
          title: `⏰ ${reminder.title}`,
          body: reminder.note || 'Tap to view your reminder',
        });
        sent++;
      } catch (_) {}
    }

    res.json({ sent, total: due.length });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
