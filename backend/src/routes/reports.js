const router = require('express').Router();
const { downloadReport, getCategoryBreakdown } = require('../controllers/reportController');
const { protect } = require('../middleware/auth');

router.get('/download', protect, downloadReport);
router.get('/summary', protect, getCategoryBreakdown);

module.exports = router;
