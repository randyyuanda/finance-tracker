const router = require('express').Router();
const { sendReminderPushes } = require('../controllers/cronController');

router.get('/reminders', sendReminderPushes);

module.exports = router;
