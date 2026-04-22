import { useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Form, Input, Button, Divider, Alert, Typography, Space } from 'antd';
import { UserOutlined, MailOutlined, LockOutlined, GoogleOutlined, BankOutlined } from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { register, clearError } from '../store/slices/authSlice';

const { Title, Text } = Typography;

export default function Register() {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const { loading, error } = useSelector((s) => s.auth);

  useEffect(() => () => dispatch(clearError()), []);

  const onFinish = async (values) => {
    const result = await dispatch(register(values));
    if (!result.error) navigate('/', { replace: true });
  };

  return (
    <div className="auth-container">
      <div className="auth-card-inner">
        <Space direction="vertical" align="center" style={{ width: '100%', marginBottom: 24 }}>
          <div className="auth-logo">
            <BankOutlined style={{ fontSize: 28, color: '#fff' }} />
          </div>
          <Title level={2} style={{ margin: 0, color: '#fff' }}>Create account</Title>
          <Text style={{ color: 'rgba(255,255,255,0.7)', fontSize: 14 }}>Start tracking your finances today</Text>
        </Space>

        {error && <Alert message={error} type="error" showIcon style={{ marginBottom: 20, borderRadius: 10 }} />}

        <Form layout="vertical" onFinish={onFinish} size="large">
          <Form.Item name="name" rules={[{ required: true, message: 'Name required' }]}>
            <Input
              prefix={<UserOutlined style={{ color: 'rgba(255,255,255,0.5)' }} />}
              placeholder="Full name"
              className="auth-input"
            />
          </Form.Item>
          <Form.Item name="email" rules={[{ required: true, type: 'email', message: 'Valid email required' }]}>
            <Input
              prefix={<MailOutlined style={{ color: 'rgba(255,255,255,0.5)' }} />}
              placeholder="Email address"
              className="auth-input"
            />
          </Form.Item>
          <Form.Item name="password" rules={[{ required: true, min: 6, message: 'Minimum 6 characters' }]}>
            <Input.Password
              prefix={<LockOutlined style={{ color: 'rgba(255,255,255,0.5)' }} />}
              placeholder="Password (min 6 chars)"
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
              placeholder="Confirm password"
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
            Create Account
          </Button>
        </Form>

        <Divider style={{ borderColor: 'rgba(255,255,255,0.2)', margin: '16px 0' }}>
          <Text style={{ color: 'rgba(255,255,255,0.5)', fontSize: 12 }}>or</Text>
        </Divider>

        <Button
          block
          size="large"
          icon={<GoogleOutlined />}
          className="auth-google-btn"
          style={{ height: 48, borderRadius: 12, marginBottom: 20 }}
          onClick={() => { window.location.href = '/api/auth/google'; }}
        >
          Sign up with Google
        </Button>

        <Text style={{ display: 'block', textAlign: 'center', color: 'rgba(255,255,255,0.7)' }}>
          Already have an account?{' '}
          <Link to="/login" style={{ color: '#fff', fontWeight: 600 }}>Sign in</Link>
        </Text>
      </div>
    </div>
  );
}
