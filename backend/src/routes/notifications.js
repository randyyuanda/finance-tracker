const router = require('express').Router();
const { getAdminNotifications } = require('../controllers/notificationController');
const { protect } = require('../middleware/auth');

router.use(protect);

router.get('/admin', getAdminNotifications);

module.exports = router;
