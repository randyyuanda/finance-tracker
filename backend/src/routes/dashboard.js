const router = require('express').Router();
const { getDashboard, getBalanceHistory } = require('../controllers/dashboardController');
const { protect } = require('../middleware/auth');

router.get('/', protect, getDashboard);
router.get('/history', protect, getBalanceHistory);

module.exports = router;
