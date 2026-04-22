const router = require('express').Router();
const passport = require('passport');
const { register, login, getMe, updateProfile, googleCallback } = require('../controllers/authController');
const { protect } = require('../middleware/auth');

router.post('/register', register);
router.post('/login', login);
router.get('/me', protect, getMe);
router.patch('/profile', protect, updateProfile);

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
