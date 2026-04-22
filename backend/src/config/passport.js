const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const User = require('../models/User');
const Category = require('../models/Category');
const Account = require('../models/Account');

const DEFAULT_CATEGORIES = [
  { name: 'Salary', type: 'income', color: '#52c41a', icon: 'money-collect' },
  { name: 'Freelance', type: 'income', color: '#13c2c2', icon: 'laptop' },
  { name: 'Investment', type: 'income', color: '#faad14', icon: 'rise' },
  { name: 'Gift', type: 'income', color: '#eb2f96', icon: 'gift' },
  { name: 'Other Income', type: 'income', color: '#722ed1', icon: 'plus-circle' },
  { name: 'Food & Drink', type: 'expense', color: '#fa541c', icon: 'coffee' },
  { name: 'Transport', type: 'expense', color: '#faad14', icon: 'car' },
  { name: 'Shopping', type: 'expense', color: '#eb2f96', icon: 'shopping-cart' },
  { name: 'Bills & Utilities', type: 'expense', color: '#1890ff', icon: 'file-text' },
  { name: 'Entertainment', type: 'expense', color: '#722ed1', icon: 'play-circle' },
  { name: 'Healthcare', type: 'expense', color: '#52c41a', icon: 'medicine-box' },
  { name: 'Education', type: 'expense', color: '#13c2c2', icon: 'read' },
  { name: 'Other Expense', type: 'expense', color: '#8c8c8c', icon: 'minus-circle' },
];

const seedUserDefaults = async (userId) => {
  await Category.insertMany(DEFAULT_CATEGORIES.map((c) => ({ ...c, userId, isDefault: true })));
  await Account.create({ userId, name: 'Cash', type: 'cash', balance: 0, color: '#52c41a', icon: 'wallet' });
};

passport.use(
  new GoogleStrategy(
    {
      clientID: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
      callbackURL: process.env.GOOGLE_CALLBACK_URL,
    },
    async (accessToken, refreshToken, profile, done) => {
      try {
        let user = await User.findOne({ googleId: profile.id });
        if (!user) {
          user = await User.findOne({ email: profile.emails[0].value });
          if (user) {
            user.googleId = profile.id;
            if (!user.avatar) user.avatar = profile.photos?.[0]?.value;
            await user.save();
          } else {
            user = await User.create({
              name: profile.displayName,
              email: profile.emails[0].value,
              googleId: profile.id,
              avatar: profile.photos?.[0]?.value,
            });
            await seedUserDefaults(user._id);
          }
        }
        done(null, user);
      } catch (err) {
        done(err, null);
      }
    }
  )
);

passport.serializeUser((user, done) => done(null, user._id));
passport.deserializeUser(async (id, done) => {
  try {
    const user = await User.findById(id);
    done(null, user);
  } catch (err) {
    done(err, null);
  }
});

module.exports = { seedUserDefaults, DEFAULT_CATEGORIES };
