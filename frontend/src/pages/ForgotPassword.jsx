import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Form, Input, Button, Typography, Space, message } from 'antd';
import { MailOutlined, SafetyCertificateOutlined, LockOutlined } from '@ant-design/icons';
import api from '../api/axios';

const { Title, Text } = Typography;

export default function ForgotPassword() {
  const [step, setStep] = useState(1); // 1: Email, 2: OTP + New Password
  const [loading, setLoading] = useState(false);
  const [email, setEmail] = useState('');
  const navigate = useNavigate();

  const handleRequestOtp = async (values) => {
    try {
      setLoading(true);
      await api.post('/auth/request-otp', { email: values.email });
      setEmail(values.email);
      setStep(2);
      message.success('OTP sent to your email');
    } catch (err) {
      message.error(err.response?.data?.message || 'Failed to send OTP');
    } finally {
      setLoading(false);
    }
  };

  const handleResetPassword = async (values) => {
    try {
      setLoading(true);
      const verifyRes = await api.post('/auth/verify-otp', { email, otp: values.otp });
      // Use the token to reset the password
      await api.post('/auth/reset-password', { password: values.password }, {
        headers: { Authorization: `Bearer ${verifyRes.data.token}` }
      });
      message.success('Password reset successfully');
      navigate('/login', { replace: true });
    } catch (err) {
      message.error(err.response?.data?.message || 'Failed to reset password');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-card-inner">
        <Space direction="vertical" align="center" style={{ width: '100%', marginBottom: 24 }}>
          <div className="auth-logo">
            <SafetyCertificateOutlined style={{ fontSize: 28, color: '#fff' }} />
          </div>
          <Title level={2} style={{ margin: 0, color: '#fff' }}>Reset Password</Title>
          <Text style={{ color: 'rgba(255,255,255,0.7)', fontSize: 14 }}>
            {step === 1 ? 'Enter your email to receive an OTP.' : 'Enter the OTP and your new password.'}
          </Text>
        </Space>

        {step === 1 ? (
          <Form layout="vertical" onFinish={handleRequestOtp} size="large">
            <Form.Item name="email" rules={[{ required: true, type: 'email', message: 'Valid email required' }]}>
              <Input
                prefix={<MailOutlined style={{ color: 'rgba(255,255,255,0.5)' }} />}
                placeholder="Email address"
                className="auth-input"
              />
            </Form.Item>
            <Button
              type="primary"
              htmlType="submit"
              block
              loading={loading}
              size="large"
              style={{ height: 48, borderRadius: 12, fontWeight: 600, fontSize: 15, marginBottom: 12 }}
            >
              Send OTP
            </Button>
            <Text style={{ display: 'block', textAlign: 'center', color: 'rgba(255,255,255,0.7)' }}>
              Remembered your password?{' '}
              <Link to="/login" style={{ color: '#fff', fontWeight: 600 }}>Sign in</Link>
            </Text>
          </Form>
        ) : (
          <Form layout="vertical" onFinish={handleResetPassword} size="large">
            <Form.Item name="otp" rules={[{ required: true, message: 'OTP is required' }]}>
              <Input
                placeholder="6-digit OTP"
                className="auth-input"
                maxLength={6}
              />
            </Form.Item>
            <Form.Item name="password" rules={[{ required: true, min: 6, message: 'Minimum 6 characters' }]}>
              <Input.Password
                prefix={<LockOutlined style={{ color: 'rgba(255,255,255,0.5)' }} />}
                placeholder="New Password (min 6 chars)"
                className="auth-input"
              />
            </Form.Item>
            <Form.Item
              name="confirm"
              dependencies={['password']}
              rules={[
                { required: true, message: 'Please confirm password' },
                ({ getFieldValue }) => ({
                  validator(_, value) {
                    if (!value || getFieldValue('password') === value) return Promise.resolve();
                    return Promise.reject('Passwords do not match');
                  },
                }),
              ]}
            >
              <Input.Password
                prefix={<LockOutlined style={{ color: 'rgba(255,255,255,0.5)' }} />}
                placeholder="Confirm new password"
                className="auth-input"
              />
            </Form.Item>
            <Button
              type="primary"
              htmlType="submit"
              block
              loading={loading}
              size="large"
              style={{ height: 48, borderRadius: 12, fontWeight: 600, fontSize: 15, marginBottom: 12 }}
            >
              Reset Password
            </Button>
          </Form>
        )}
      </div>
    </div>
  );
}
