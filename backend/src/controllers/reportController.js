const ExcelJS = require('exceljs');
const prisma = require('../lib/prisma');
const { subMonths, subYears, startOfDay } = require('date-fns');

const PERIODS = {
  '1month': () => subMonths(new Date(), 1),
  '3months': () => subMonths(new Date(), 3),
  '1year': () => subYears(new Date(), 1),
  '2years': () => subYears(new Date(), 2),
  alltime: () => null,
};

exports.downloadReport = async (req, res) => {
  try {
    const { period = 'alltime', accountId, type } = req.query;
    const userId = req.user._id;

    const startFn = PERIODS[period];
    if (!startFn) return res.status(400).json({ message: 'Invalid period' });

    const where = { userId };
    const startDate = startFn();
    if (startDate) where.date = { gte: startOfDay(startDate) };
    if (accountId) where.accountId = accountId;
    if (type) where.type = type;

    const transactions = await prisma.transaction.findMany({
      where,
      include: {
        account: { select: { name: true } },
        category: { select: { name: true } },
      },
      orderBy: { date: 'desc' },
    });

    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'Finance Tracker';

    const txSheet = workbook.addWorksheet('Transactions');
    txSheet.columns = [
      { header: 'Date', key: 'date', width: 15 },
      { header: 'Account', key: 'account', width: 20 },
      { header: 'Category', key: 'category', width: 20 },
      { header: 'Type', key: 'type', width: 12 },
      { header: 'Amount (IDR)', key: 'amount', width: 18 },
      { header: 'Note', key: 'note', width: 30 },
    ];

    const headerRow = txSheet.getRow(1);
    headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    headerRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1890FF' } };

    let totalIncome = 0;
    let totalExpense = 0;

    transactions.forEach((tx) => {
      txSheet.addRow({
        date: new Date(tx.date).toLocaleDateString('id-ID'),
        account: tx.account?.name || '-',
        category: tx.category?.name || '-',
        type: tx.type.charAt(0).toUpperCase() + tx.type.slice(1),
        amount: tx.type === 'income' ? tx.amount : -tx.amount,
        note: tx.note || '',
      });
      if (tx.type === 'income') totalIncome += tx.amount;
      else totalExpense += tx.amount;
    });

    txSheet.getColumn('amount').numFmt = '#,##0';

    const summarySheet = workbook.addWorksheet('Summary');
    summarySheet.columns = [
      { header: 'Metric', key: 'metric', width: 25 },
      { header: 'Amount (IDR)', key: 'amount', width: 20 },
    ];
    summarySheet.getRow(1).font = { bold: true };
    summarySheet.addRows([
      { metric: 'Total Income', amount: totalIncome },
      { metric: 'Total Expense', amount: totalExpense },
      { metric: 'Net Savings', amount: totalIncome - totalExpense },
      { metric: 'Total Transactions', amount: transactions.length },
    ]);
    summarySheet.getColumn('amount').numFmt = '#,##0';

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename=finance-report-${period}.xlsx`);
    await workbook.xlsx.write(res);
    res.end();
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
