import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Form, Input, Button, Typography, Space, message } from 'antd';
import { MailOutlined, SafetyCertificateOutlined } from '@ant-design/icons';
import { useSelector, useDispatch } from 'react-redux';
import { fetchMe } from '../store/slices/authSlice';
import api from '../api/axios';

const { Title, Text } = Typography;

export default function VerifyEmail() {
  const [loading, setLoading] = useState(false);
  const [resending, setResending] = useState(false);
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { user } = useSelector((s) => s.auth);

  useEffect(() => {
    if (user?.emailVerified) {
      navigate('/', { replace: true });
    }
  }, [user, navigate]);

  const onFinish = async (values) => {
    try {
      setLoading(true);
      await api.post('/auth/verify-email', values);
      message.success('Email verified successfully');
      await dispatch(fetchMe());
      navigate('/', { replace: true });
    } catch (err) {
      message.error(err.response?.data?.message || 'Verification failed');
    } finally {
      setLoading(false);
    }
  };

  const resendOtp = async () => {
    try {
      setResending(true);
      await api.post('/auth/resend-verification');
      message.success('Verification code resent to your email');
    } catch (err) {
      message.error('Failed to resend code');
    } finally {
      setResending(false);
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-card-inner">
        <Space direction="vertical" align="center" style={{ width: '100%', marginBottom: 24 }}>
          <div className="auth-logo">
            <MailOutlined style={{ fontSize: 28, color: '#fff' }} />
          </div>
          <Title level={2} style={{ margin: 0, color: '#fff' }}>Verify Email</Title>
          <Text style={{ color: 'rgba(255,255,255,0.7)', fontSize: 14, textAlign: 'center' }}>
            We've sent a 6-digit verification code to <br />
            <b style={{ color: '#fff' }}>{user?.email}</b>
          </Text>
        </Space>

        <Form layout="vertical" onFinish={onFinish} size="large">
          <Form.Item
            name="otp"
            rules={[{ required: true, len: 6, message: 'Please enter 6-digit code' }]}
          >
            <Input
              prefix={<SafetyCertificateOutlined style={{ color: 'rgba(255,255,255,0.5)' }} />}
              placeholder="6-digit code"
              className="auth-input"
              maxLength={6}
            />
          </Form.Item>

          <Button
            type="primary"
            htmlType="submit"
            block
            loading={loading}
            size="large"
            style={{ height: 48, borderRadius: 12, fontWeight: 600, fontSize: 15, marginTop: 12 }}
          >
            Verify Now
          </Button>
        </Form>

        <div style={{ textAlign: 'center', marginTop: 24 }}>
          <Text style={{ color: 'rgba(255,255,255,0.7)' }}>
            Didn't receive the code?{' '}
            <Button 
              type="link" 
              onClick={resendOtp} 
              loading={resending}
              style={{ color: '#fff', padding: 0, fontWeight: 600 }}
            >
              Resend Code
            </Button>
          </Text>
        </div>
      </div>
    </div>
  );
}
