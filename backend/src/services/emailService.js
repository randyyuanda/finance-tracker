const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT || '587', 10),
  secure: process.env.SMTP_PORT === '465', // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
  tls: {
    rejectUnauthorized: false
  }
});

exports.sendOtpEmail = async (to, otp) => {
  try {
    const mailOptions = {
      from: process.env.SMTP_FROM || 'BuxBux <noreply@yourdomain.com>',
      to,
      subject: 'Your BuxBux Verification Code',
      text: `Your BuxBux verification code is: ${otp}\nThis code is valid for 15 minutes.`,
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
          <h2 style="color: #1677ff;">Security Verification</h2>
          <p>Here is your 6-digit verification code:</p>
          <h1 style="color: #1677ff; letter-spacing: 5px; font-size: 36px; background: #f0f5ff; padding: 10px; display: inline-block; border-radius: 8px;">${otp}</h1>
          <p>This code is valid for 15 minutes.</p>
          <p>If you didn't request this code, you can safely ignore this email.</p>
          <hr style="border: none; border-top: 1px solid #eee; margin-top: 20px;">
          <p style="font-size: 12px; color: #888;">BuxBux Finance Tracker — Secure your finances.</p>
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
