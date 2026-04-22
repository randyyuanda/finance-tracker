const router = require('express').Router();
const passport = require('passport');
const { register, login, getMe, updateProfile, googleCallback } = require('../controllers/authController');
const { protect } = require('../middleware/auth');

router.post('/register', register);
router.post('/login', login);
router.get('/me', protect, getMe);
router.patch('/profile', protect, updateProfile);

router.get('/debug-env', (req, res) => {
  res.json({
    hasGoogleId: !!process.env.GOOGLE_CLIENT_ID,
    hasGoogleSecret: !!process.env.GOOGLE_CLIENT_SECRET,
    hasCallback: !!process.env.GOOGLE_CALLBACK_URL,
    nodeEnv: process.env.NODE_ENV
  });
});

if (process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET) {
  router.get('/google', passport.authenticate('google', { scope: ['profile', 'email'] }));
  router.get(
    '/google/callback',
    passport.authenticate('google', {
      failureRedirect: `${(process.env.CLIENT_URL || 'http://localhost:3000').split(',')[0].trim()}/login?error=oauth`,
    }),
    googleCallback
  );
}

module.exports = router;
