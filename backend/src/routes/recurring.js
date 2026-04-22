const router = require('express').Router();
const { getRecurringTransactions, createRecurringTransaction, updateRecurringTransaction, deleteRecurringTransaction } = require('../controllers/recurringController');
const { protect } = require('../middleware/auth');

router.use(protect);

router.get('/', getRecurringTransactions);
router.post('/', createRecurringTransaction);
router.patch('/:id', updateRecurringTransaction);
router.delete('/:id', deleteRecurringTransaction);

module.exports = router;
