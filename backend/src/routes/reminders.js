const router = require('express').Router();
const {
  getReminders,
  createReminder,
  updateReminder,
  toggleComplete,
  deleteReminder,
} = require('../controllers/reminderController');
const { protect } = require('../middleware/auth');

router.use(protect);

router.get('/', getReminders);
router.post('/', createReminder);
router.patch('/:id', updateReminder);
router.patch('/:id/complete', toggleComplete);
router.delete('/:id', deleteReminder);

module.exports = router;
