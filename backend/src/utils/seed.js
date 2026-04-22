require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Account = require('../models/Account');
const Category = require('../models/Category');
const Transaction = require('../models/Transaction');
const { DEFAULT_CATEGORIES } = require('../config/passport');

const randomBetween = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const daysAgo = (n) => new Date(Date.now() - n * 24 * 60 * 60 * 1000);

async function seed() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to MongoDB');

  await User.deleteMany({ isDummy: true });

  const password = await bcrypt.hash('password123', 10);
  const user = await User.create({
    name: 'John Doe',
    email: 'john@example.com',
    password,
    isDummy: true,
  });

  const existingCats = await Category.find({ userId: user._id });
  let categories = existingCats;
  if (!existingCats.length) {
    categories = await Category.insertMany(
      DEFAULT_CATEGORIES.map((c) => ({ ...c, userId: user._id, isDefault: true }))
    );
  }

  const existingAccounts = await Account.find({ userId: user._id });
  let accounts = existingAccounts;
  if (!existingAccounts.length) {
    accounts = await Account.insertMany([
      { userId: user._id, name: 'Cash', type: 'cash', balance: 500000, color: '#52c41a', icon: 'wallet' },
      { userId: user._id, name: 'BCA Bank', type: 'bank', balance: 15000000, color: '#1890ff', icon: 'bank' },
      { userId: user._id, name: 'GoPay', type: 'e-wallet', balance: 300000, color: '#00aa5b', icon: 'mobile' },
      { userId: user._id, name: 'OVO', type: 'e-wallet', balance: 150000, color: '#4c3494', icon: 'mobile' },
    ]);
  }

  const incomeCategories = categories.filter((c) => c.type === 'income');
  const expenseCategories = categories.filter((c) => c.type === 'expense');

  const transactions = [];
  for (let i = 90; i >= 0; i--) {
    const date = daysAgo(i);
    if (date.getDate() === 1 || date.getDate() === 15) {
      transactions.push({
        userId: user._id,
        accountId: accounts[1]._id,
        categoryId: incomeCategories[0]._id,
        amount: 8000000,
        type: 'income',
        date,
        note: 'Monthly salary',
      });
    }
    if (randomBetween(0, 1)) {
      transactions.push({
        userId: user._id,
        accountId: accounts[randomBetween(0, accounts.length - 1)]._id,
        categoryId: expenseCategories[randomBetween(0, expenseCategories.length - 1)]._id,
        amount: randomBetween(15000, 350000),
        type: 'expense',
        date,
        note: '',
      });
    }
    if (i % 7 === 0) {
      transactions.push({
        userId: user._id,
        accountId: accounts[randomBetween(0, accounts.length - 1)]._id,
        categoryId: expenseCategories[randomBetween(0, 3)]._id,
        amount: randomBetween(50000, 500000),
        type: 'expense',
        date,
        note: 'Weekly expense',
      });
    }
  }

  await Transaction.deleteMany({ userId: user._id });
  await Transaction.insertMany(transactions);

  const balanceMap = {};
  accounts.forEach((a) => { balanceMap[a._id.toString()] = 0; });
  transactions.forEach((tx) => {
    const id = tx.accountId.toString();
    if (tx.type === 'income') balanceMap[id] += tx.amount;
    else balanceMap[id] -= tx.amount;
  });
  await Promise.all(
    accounts.map((a) =>
      Account.findByIdAndUpdate(a._id, { $inc: { balance: balanceMap[a._id.toString()] } })
    )
  );

  console.log(`Seeded: user=${user.email}, accounts=${accounts.length}, transactions=${transactions.length}`);
  await mongoose.disconnect();
}

seed().catch((err) => { console.error(err); process.exit(1); });
