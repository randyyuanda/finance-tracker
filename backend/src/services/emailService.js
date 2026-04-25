const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT || '587', 10),
  secure: process.env.SMTP_PORT == '465',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

exports.sendOtpEmail = async (to, otp) => {
  try {
    const mailOptions = {
      from: process.env.SMTP_FROM || 'BuxBux <noreply@yourdomain.com>',
      to,
      subject: 'Your BuxBux Password Reset OTP',
      text: `Your OTP for password reset is: ${otp}\nThis OTP is valid for 15 minutes.`,
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h2>Password Reset</h2>
          <p>You requested a password reset. Here is your One-Time Password (OTP):</p>
          <h1 style="color: #1890ff; letter-spacing: 2px;">${otp}</h1>
          <p>This OTP is valid for 15 minutes.</p>
          <p>If you didn't request this, you can safely ignore this email.</p>
        </div>
      `,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('OTP Email sent: ' + info.messageId);
    return true;
  } catch (error) {
    console.error('Error sending OTP email:', error);
    return false;
  }
};
