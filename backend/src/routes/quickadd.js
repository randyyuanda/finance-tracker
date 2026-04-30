const router = require('express').Router();
const { getConfigs, saveConfigs } = require('../controllers/quickAddController');
const { protect } = require('../middleware/auth');

router.use(protect);
router.get('/', getConfigs);
router.put('/', saveConfigs);

module.exports = router;
