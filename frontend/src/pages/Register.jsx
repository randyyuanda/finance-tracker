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
      <div className="auth-card" style={{ background: '#fff', padding: '40px 32px', borderRadius: 20 }}>
        <Space direction="vertical" align="center" style={{ width: '100%', marginBottom: 28 }}>
          <BankOutlined style={{ fontSize: 40, color: '#1890ff' }} />
          <Title level={2} style={{ margin: 0 }}>Create account</Title>
          <Text type="secondary">Start tracking your finances today</Text>
        </Space>

        {error && <Alert message={error} type="error" showIcon style={{ marginBottom: 20 }} />}

        <Form layout="vertical" onFinish={onFinish} size="large">
          <Form.Item name="name" rules={[{ required: true, message: 'Name required' }]}>
            <Input prefix={<UserOutlined />} placeholder="Full name" />
          </Form.Item>
          <Form.Item name="email" rules={[{ required: true, type: 'email', message: 'Valid email required' }]}>
            <Input prefix={<MailOutlined />} placeholder="Email address" />
          </Form.Item>
          <Form.Item name="password" rules={[{ required: true, min: 6, message: 'Minimum 6 characters' }]}>
            <Input.Password prefix={<LockOutlined />} placeholder="Password (min 6 chars)" />
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
            <Input.Password prefix={<LockOutlined />} placeholder="Confirm password" />
          </Form.Item>
          <Button type="primary" htmlType="submit" block loading={loading} style={{ height: 44, marginBottom: 12 }}>
            Create Account
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
          Sign up with Google
        </Button>

        <Text style={{ display: 'block', textAlign: 'center' }}>
          Already have an account? <Link to="/login">Sign in</Link>
        </Text>
      </div>
    </div>
  );
}
