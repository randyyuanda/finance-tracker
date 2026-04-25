import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Form, Input, Button, Typography, Space, message } from 'antd';
import { LockOutlined, PhoneOutlined, SafetyOutlined } from '@ant-design/icons';
import { useSelector, useDispatch } from 'react-redux';
import { fetchMe } from '../store/slices/authSlice';
import api from '../api/axios';

const { Title, Text } = Typography;

export default function SetPassword() {
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { user } = useSelector((s) => s.auth);

  const onFinish = async (values) => {
    try {
      setLoading(true);
      await api.post('/auth/set-password', values);
      message.success('Profile updated successfully');
      await dispatch(fetchMe());
      navigate('/', { replace: true });
    } catch (err) {
      message.error(err.response?.data?.message || 'Failed to update profile');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-card-inner">
        <Space direction="vertical" align="center" style={{ width: '100%', marginBottom: 24 }}>
          <div className="auth-logo">
            <SafetyOutlined style={{ fontSize: 28, color: '#fff' }} />
          </div>
          <Title level={2} style={{ margin: 0, color: '#fff' }}>Complete Profile</Title>
          <Text style={{ color: 'rgba(255,255,255,0.7)', fontSize: 14 }}>
            Please set a password and phone number to secure your account.
          </Text>
        </Space>

        <Form layout="vertical" onFinish={onFinish} size="large">
          {!user?.hasPassword && (
            <>
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
                  placeholder="Confirm password"
                  className="auth-input"
                />
              </Form.Item>
            </>
          )}

          {!user?.phone && (
            <Form.Item name="phone" rules={[{ required: true, message: 'Please enter your phone number' }]}>
              <Input
                prefix={<PhoneOutlined style={{ color: 'rgba(255,255,255,0.5)' }} />}
                placeholder="Phone number"
                className="auth-input"
              />
            </Form.Item>
          )}

          <Button
            type="primary"
            htmlType="submit"
            block
            loading={loading}
            size="large"
            style={{ height: 48, borderRadius: 12, fontWeight: 600, fontSize: 15, marginTop: 12 }}
          >
            Complete Setup
          </Button>
        </Form>
      </div>
    </div>
  );
}
