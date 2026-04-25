const router = require('express').Router();
const passport = require('passport');
const { 
  register, login, getMe, updateProfile, saveFcmToken, googleCallback, 
  setPassword, requestOtp, verifyOtp, resetPassword, 
  verifyEmail, resendVerificationOtp 
} = require('../controllers/authController');
const { protect } = require('../middleware/auth');

router.post('/register', register);
router.post('/login', login);
router.get('/me', protect, getMe);
router.patch('/profile', protect, updateProfile);
router.post('/fcm-token', protect, saveFcmToken);
router.post('/set-password', protect, setPassword);
router.post('/verify-email', protect, verifyEmail);
router.post('/resend-verification', protect, resendVerificationOtp);
router.post('/request-otp', requestOtp);
router.post('/verify-otp', verifyOtp);
router.post('/reset-password', protect, resetPassword);

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
