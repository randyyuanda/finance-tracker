const router = require('express').Router();
const { downloadReport } = require('../controllers/reportController');
const { protect } = require('../middleware/auth');

router.get('/download', protect, downloadReport);

module.exports = router;
