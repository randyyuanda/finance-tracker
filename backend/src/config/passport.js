const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const prisma = require('../lib/prisma');

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
  await prisma.category.createMany({
    data: DEFAULT_CATEGORIES.map((c) => ({ ...c, userId, isDefault: true })),
  });
  await prisma.account.create({
    data: { userId, name: 'Cash', type: 'cash', balance: 0, color: '#52c41a', icon: 'wallet' },
  });
};

if (process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET) {
  passport.use(
    new GoogleStrategy(
      {
        clientID: process.env.GOOGLE_CLIENT_ID,
        clientSecret: process.env.GOOGLE_CLIENT_SECRET,
        callbackURL: process.env.GOOGLE_CALLBACK_URL,
      },
      async (accessToken, refreshToken, profile, done) => {
        try {
          let user = await prisma.user.findUnique({ where: { googleId: profile.id } });
          if (!user) {
            user = await prisma.user.findUnique({ where: { email: profile.emails[0].value } });
            if (user) {
              user = await prisma.user.update({
                where: { id: user.id },
                data: {
                  googleId: profile.id,
                  avatar: user.avatar || profile.photos?.[0]?.value,
                  emailVerified: true,
                },
              });
            } else {
              user = await prisma.user.create({
                data: {
                  name: profile.displayName,
                  email: profile.emails[0].value,
                  googleId: profile.id,
                  avatar: profile.photos?.[0]?.value,
                  emailVerified: true,
                },
              });
              await seedUserDefaults(user.id);
            }
          }
          done(null, user);
        } catch (err) {
          done(err, null);
        }
      }
    )
  );
}

passport.serializeUser((user, done) => done(null, user.id));
passport.deserializeUser(async (id, done) => {
  try {
    const user = await prisma.user.findUnique({ where: { id } });
    done(null, user);
  } catch (err) {
    done(err, null);
  }
});

module.exports = { seedUserDefaults, DEFAULT_CATEGORIES };
