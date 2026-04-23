const prisma = require('../lib/prisma');

exports.getAdminNotifications = async (req, res) => {
  try {
    const notifications = await prisma.adminNotification.findMany({
      where: { userId: req.user.id, isRead: false },
      orderBy: { scheduledAt: 'asc' },
    });

    // One-time notifications are marked read after delivery; repeating ones stay unread
    const oneTimeIds = notifications
      .filter((n) => n.repeatType === 'none')
      .map((n) => n.id);

    if (oneTimeIds.length > 0) {
      await prisma.adminNotification.updateMany({
        where: { id: { in: oneTimeIds } },
        data: { isRead: true },
      });
    }

    res.json(notifications);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
