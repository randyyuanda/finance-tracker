import { useEffect } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { Form, Input, Button, Divider, Alert, Typography, Space } from 'antd';
import { MailOutlined, LockOutlined, GoogleOutlined, BankOutlined } from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { login, clearError } from '../store/slices/authSlice';

const { Title, Text } = Typography;

export default function Login() {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const { loading, error } = useSelector((s) => s.auth);

  useEffect(() => () => dispatch(clearError()), []);

  const onFinish = async (values) => {
    const result = await dispatch(login(values));
    if (!result.error) navigate('/', { replace: true });
  };

  return (
    <div className="auth-container">
      <div className="auth-card" style={{ background: '#fff', padding: '40px 32px', borderRadius: 20 }}>
        <Space direction="vertical" align="center" style={{ width: '100%', marginBottom: 28 }}>
          <BankOutlined style={{ fontSize: 40, color: '#1890ff' }} />
          <Title level={2} style={{ margin: 0 }}>Welcome back</Title>
          <Text type="secondary">Sign in to your FinTrack account</Text>
        </Space>

        {(error || params.get('error')) && (
          <Alert
            message={error || 'OAuth sign-in failed. Please try again.'}
            type="error"
            showIcon
            style={{ marginBottom: 20 }}
          />
        )}

        <Form layout="vertical" onFinish={onFinish} size="large">
          <Form.Item name="email" rules={[{ required: true, type: 'email', message: 'Valid email required' }]}>
            <Input prefix={<MailOutlined />} placeholder="Email address" />
          </Form.Item>
          <Form.Item name="password" rules={[{ required: true, message: 'Password required' }]}>
            <Input.Password prefix={<LockOutlined />} placeholder="Password" />
          </Form.Item>
          <Button type="primary" htmlType="submit" block loading={loading} style={{ height: 44, marginBottom: 12 }}>
            Sign In
          </Button>
        </Form>

        <Divider plain>or</Divider>

        <Button
          block
          size="large"
          icon={<GoogleOutlined />}
          style={{ height: 44, marginBottom: 20 }}
          onClick={() => { window.location.href = '/api/auth/google'; }}
        >
          Continue with Google
        </Button>

        <Text style={{ display: 'block', textAlign: 'center' }}>
          No account? <Link to="/register">Create one</Link>
        </Text>

        <Divider plain style={{ margin: '16px 0 8px' }}>
          <Text type="secondary" style={{ fontSize: 12 }}>Demo account</Text>
        </Divider>
        <Text type="secondary" style={{ display: 'block', textAlign: 'center', fontSize: 12 }}>
          john@example.com / password123
        </Text>
      </div>
    </div>
  );
}
