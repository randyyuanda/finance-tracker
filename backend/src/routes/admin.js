const router = require('express').Router();
const { getStats, getUsers, broadcastReminder } = require('../controllers/adminController');
const { protect } = require('../middleware/auth');

const adminOnly = (req, res, next) => {
  if (!req.user?.isAdmin) return res.status(403).json({ message: 'Admin access required' });
  next();
};

router.use(protect, adminOnly);

router.get('/stats', getStats);
router.get('/users', getUsers);
router.post('/reminders/broadcast', broadcastReminder);

module.exports = router;
