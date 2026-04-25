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
      <div className="auth-card-inner">
        <Space direction="vertical" align="center" style={{ width: '100%', marginBottom: 28 }}>
          <div className="auth-logo">
            <BankOutlined style={{ fontSize: 28, color: '#fff' }} />
          </div>
          <Title level={2} style={{ margin: 0, color: '#fff' }}>Welcome back</Title>
          <Text style={{ color: 'rgba(255,255,255,0.7)', fontSize: 14 }}>Sign in to your BuxBux account</Text>
        </Space>

        {(error || params.get('error')) && (
          <Alert
            message={error || 'OAuth sign-in failed. Please try again.'}
            type="error"
            showIcon
            style={{ marginBottom: 20, borderRadius: 10 }}
          />
        )}

        <Form layout="vertical" onFinish={onFinish} size="large">
          <Form.Item name="email" rules={[{ required: true, type: 'email', message: 'Valid email required' }]}>
            <Input
              prefix={<MailOutlined style={{ color: 'rgba(255,255,255,0.5)' }} />}
              placeholder="Email address"
              className="auth-input"
            />
          </Form.Item>
          <Form.Item name="password" rules={[{ required: true, message: 'Password required' }]}>
            <Input.Password
              prefix={<LockOutlined style={{ color: 'rgba(255,255,255,0.5)' }} />}
              placeholder="Password"
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
            Sign In
          </Button>
          <div style={{ textAlign: 'right' }}>
            <Link to="/forgot-password" style={{ color: 'rgba(255,255,255,0.7)', fontSize: 13 }}>
              Forgot Password?
            </Link>
          </div>
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
          onClick={() => { window.location.href = `${import.meta.env.VITE_API_URL}/auth/google`; }}
        >
          Continue with Google
        </Button>

        <Text style={{ display: 'block', textAlign: 'center', color: 'rgba(255,255,255,0.7)' }}>
          No account?{' '}
          <Link to="/register" style={{ color: '#fff', fontWeight: 600 }}>Create one</Link>
        </Text>

        <Divider style={{ borderColor: 'rgba(255,255,255,0.15)', margin: '16px 0 8px' }}>
          <Text style={{ color: 'rgba(255,255,255,0.4)', fontSize: 11 }}>Demo account</Text>
        </Divider>
        <Text style={{ display: 'block', textAlign: 'center', fontSize: 12, color: 'rgba(255,255,255,0.55)' }}>
          john@example.com / password123
        </Text>
      </div>
    </div>
  );
}
