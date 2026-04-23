const prisma = require('../lib/prisma');
const bcrypt = require('bcryptjs');

module.exports = async function seedAdmin() {
  try {
    const existing = await prisma.user.findUnique({ where: { email: 'superadmin@admin.com' } });
    if (!existing) {
      const hashed = await bcrypt.hash('superadmin123', 10);
      await prisma.user.create({
        data: {
          name: 'Super Admin',
          email: 'superadmin@admin.com',
          password: hashed,
          isAdmin: true,
        },
      });
      console.log('[FinTrack] Superadmin account created');
    } else if (!existing.isAdmin) {
      await prisma.user.update({
        where: { email: 'superadmin@admin.com' },
        data: { isAdmin: true },
      });
      console.log('[FinTrack] Superadmin flag set on existing account');
    }
  } catch (err) {
    console.error('[FinTrack] Seed admin error:', err.message);
  }
};
