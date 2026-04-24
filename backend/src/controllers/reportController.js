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

const buildWhere = (userId, { period = 'alltime', accountId, type }) => {
  const startFn = PERIODS[period];
  if (!startFn) return null;
  const where = { userId };
  const startDate = startFn();
  if (startDate) where.date = { gte: startOfDay(startDate) };
  if (accountId) where.accountId = accountId;
  if (type) where.type = type;
  return where;
};

exports.getCategoryBreakdown = async (req, res) => {
  try {
    const userId = req.user._id;
    const where = buildWhere(userId, req.query);
    if (!where) return res.status(400).json({ message: 'Invalid period' });

    const grouped = await prisma.transaction.groupBy({
      by: ['categoryId', 'type'],
      where,
      _sum: { amount: true },
      _count: { id: true },
    });

    const catIds = [...new Set(grouped.map((r) => r.categoryId).filter(Boolean))];
    const cats = catIds.length ? await prisma.category.findMany({ where: { id: { in: catIds } } }) : [];
    const catMap = Object.fromEntries(cats.map((c) => [c.id, c]));

    const income = grouped
      .filter((r) => r.type === 'income')
      .map((r) => ({ name: catMap[r.categoryId]?.name || '-', color: catMap[r.categoryId]?.color || '#ccc', total: r._sum.amount, count: r._count.id }))
      .sort((a, b) => b.total - a.total);

    const expense = grouped
      .filter((r) => r.type === 'expense')
      .map((r) => ({ name: catMap[r.categoryId]?.name || '-', color: catMap[r.categoryId]?.color || '#ccc', total: r._sum.amount, count: r._count.id }))
      .sort((a, b) => b.total - a.total);

    res.json({ income, expense });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

const addCategorySheet = (workbook, name, rows, headerColor) => {
  const sheet = workbook.addWorksheet(name);
  
  // Add BuxBux footer
  sheet.headerFooter.oddFooter = "&C&\"Arial,Bold\"BuxBux &RPage &P of &N";

  sheet.columns = [
    { header: 'Category', key: 'name', width: 28 },
    { header: 'Amount (IDR)', key: 'total', width: 20 },
    { header: 'Transactions', key: 'count', width: 16 },
    { header: 'Visual / %', key: 'pct_val', width: 20 },
  ];

  const hdr = sheet.getRow(1);
  hdr.font = { bold: true, color: { argb: 'FFFFFFFF' } };
  hdr.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: headerColor } };
  hdr.alignment = { vertical: 'middle', horizontal: 'center' };
  hdr.height = 20;

  const grandTotal = rows.reduce((s, r) => s + r.total, 0);

  rows.forEach((row, idx) => {
    const pct = grandTotal > 0 ? (row.total / grandTotal) : 0;
    const r = sheet.addRow({
      name: row.name,
      total: row.total,
      count: row.count,
      pct_val: pct,
    });
    if (idx % 2 === 0) {
      r.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF5F5F5' } };
    }
    r.alignment = { vertical: 'middle' };
  });

  sheet.getColumn('total').numFmt = '#,##0';
  sheet.getColumn('pct_val').numFmt = '0.0%';
  sheet.getColumn('pct_val').alignment = { horizontal: 'center' };

  // Add Data Bar "Chart"
  const lastRow = rows.length + 1;
  sheet.addConditionalFormatting({
    ref: `D2:D${lastRow}`,
    rules: [
      {
        type: 'dataBar',
        color: { argb: headerColor },
        min: { type: 'num', value: 0 },
        max: { type: 'num', value: 1 },
      }
    ]
  });

  const totalRow = sheet.addRow({ name: 'TOTAL', total: grandTotal, count: rows.reduce((s, r) => s + r.count, 0), pct_val: 1 });
  totalRow.font = { bold: true };
  totalRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE6E6E6' } };

  return sheet;
};

exports.downloadReport = async (req, res) => {
  try {
    const userId = req.user._id;
    const { period = 'alltime', accountId, type } = req.query;
    const where = buildWhere(userId, { period, accountId, type });
    if (!where) return res.status(400).json({ message: 'Invalid period' });

    const [transactions, grouped] = await Promise.all([
      prisma.transaction.findMany({
        where,
        include: {
          account: { select: { name: true } },
          category: { select: { name: true } },
        },
        orderBy: { date: 'desc' },
      }),
      prisma.transaction.groupBy({
        by: ['categoryId', 'type'],
        where: { ...where, type: undefined },
        _sum: { amount: true },
        _count: { id: true },
      }),
    ]);

    const catIds = [...new Set(grouped.map((r) => r.categoryId).filter(Boolean))];
    const cats = catIds.length ? await prisma.category.findMany({ where: { id: { in: catIds } } }) : [];
    const catMap = Object.fromEntries(cats.map((c) => [c.id, c]));

    const incomeBreakdown = grouped
      .filter((r) => r.type === 'income')
      .map((r) => ({ name: catMap[r.categoryId]?.name || '-', color: catMap[r.categoryId]?.color || '#ccc', total: r._sum.amount, count: r._count.id }))
      .sort((a, b) => b.total - a.total);

    const expenseBreakdown = grouped
      .filter((r) => r.type === 'expense')
      .map((r) => ({ name: catMap[r.categoryId]?.name || '-', color: catMap[r.categoryId]?.color || '#ccc', total: r._sum.amount, count: r._count.id }))
      .sort((a, b) => b.total - a.total);

    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'BuxBux';

    // Sheet 1: Transactions
    const txSheet = workbook.addWorksheet('Transactions');
    txSheet.headerFooter.oddFooter = "&C&\"Arial,Bold\"BuxBux &RPage &P of &N";
    txSheet.columns = [
      { header: 'Date', key: 'date', width: 15 },
      { header: 'Account', key: 'account', width: 20 },
      { header: 'Category', key: 'category', width: 20 },
      { header: 'Type', key: 'type', width: 12 },
      { header: 'Amount (IDR)', key: 'amount', width: 18 },
      { header: 'Note', key: 'note', width: 30 },
    ];
    const txHdr = txSheet.getRow(1);
    txHdr.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    txHdr.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1890FF' } };

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

    // Sheet 2: Summary
    const summarySheet = workbook.addWorksheet('Summary');
    summarySheet.headerFooter.oddFooter = "&C&\"Arial,Bold\"BuxBux &RPage &P of &N";
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

    // Sheet 3 & 4: Category Breakdown
    if (incomeBreakdown.length > 0) {
      addCategorySheet(workbook, 'Income by Category', incomeBreakdown, 'FF52C41A');
    }
    if (expenseBreakdown.length > 0) {
      addCategorySheet(workbook, 'Expense by Category', expenseBreakdown, 'FFFF4D4F');
    }

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename=finance-report-${period}.xlsx`);
    await workbook.xlsx.write(res);
    res.end();
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
