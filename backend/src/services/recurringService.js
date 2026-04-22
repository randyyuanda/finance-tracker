const prisma = require('../lib/prisma');
const dayjs = require('dayjs');

/**
 * Processes all active recurring transactions for a user.
 * Creates new transactions for any missed occurrences since the last run.
 */
const processRecurringTransactions = async (userId) => {
  try {
    const recurring = await prisma.recurringTransaction.findMany({
      where: {
        userId,
        isActive: true,
        nextDue: { lte: new Date() }
      }
    });

    for (const rt of recurring) {
      let nextDue = dayjs(rt.nextDue);
      const now = dayjs();
      let lastRun = rt.lastRun ? dayjs(rt.lastRun) : null;

      // Keep creating transactions until nextDue is in the future
      while (nextDue.isBefore(now) || nextDue.isSame(now, 'day')) {
        // Create the transaction
        await prisma.transaction.create({
          data: {
            userId: rt.userId,
            accountId: rt.accountId,
            categoryId: rt.categoryId,
            amount: rt.amount,
            type: rt.type,
            date: nextDue.toDate(),
            note: rt.note,
            description: `Recurring: ${rt.note || ''}`,
          }
        });

        // Update account balance
        const account = await prisma.account.findUnique({ where: { id: rt.accountId } });
        if (account) {
          const newBalance = rt.type === 'income' 
            ? account.balance + rt.amount 
            : account.balance - rt.amount;
          
          await prisma.account.update({
            where: { id: rt.accountId },
            data: { balance: newBalance }
          });
        }

        // Calculate next occurrence
        lastRun = nextDue;
        if (rt.frequency === 'daily') nextDue = nextDue.add(1, 'day');
        else if (rt.frequency === 'weekly') nextDue = nextDue.add(1, 'week');
        else if (rt.frequency === 'monthly') nextDue = nextDue.add(1, 'month');
        else if (rt.frequency === 'yearly') nextDue = nextDue.add(1, 'year');
        else break; // Should not happen if frequency is valid
      }

      // Update the recurring transaction state
      await prisma.recurringTransaction.update({
        where: { id: rt.id },
        data: {
          nextDue: nextDue.toDate(),
          lastRun: lastRun.toDate()
        }
      });
    }
  } catch (error) {
    console.error('Error processing recurring transactions:', error);
  }
};

module.exports = { processRecurringTransactions };
