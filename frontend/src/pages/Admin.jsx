import { useEffect, useState, useMemo } from 'react';
import {
  Layout, Typography, Button, Card, Row, Col, Table, Avatar, Tag, Modal,
  Form, Input, DatePicker, Select, Space, Badge, Statistic, Checkbox,
  Popconfirm, message, Divider, Segmented,
} from 'antd';
import {
  UserOutlined, LogoutOutlined, BellOutlined, TeamOutlined,
  SwapOutlined, SendOutlined, CrownOutlined, CheckCircleOutlined,
  SearchOutlined,
} from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { logout } from '../store/slices/authSlice';
import api from '../api/axios';
import dayjs from 'dayjs';

const { Header, Content } = Layout;
const { Title, Text } = Typography;


const REPEAT_OPTIONS = [
  { value: 'none', label: 'One time' },
  { value: 'daily', label: 'Every day' },
  { value: 'weekly', label: 'Every week' },
  { value: 'monthly', label: 'Every month' },
];

export default function Admin() {
  const dispatch = useDispatch();
  const { user } = useSelector((s) => s.auth);
  const primaryColor = '#1677ff';

  const [stats, setStats] = useState(null);
  const [users, setUsers] = useState([]);
  const [loadingUsers, setLoadingUsers] = useState(false);
  const [search, setSearch] = useState('');

  // Broadcast modal
  const [broadcastOpen, setBroadcastOpen] = useState(false);
  const [broadcastLoading, setBroadcastLoading] = useState(false);
  const [targetMode, setTargetMode] = useState('all'); // 'all' | 'select'
  const [selectedUserIds, setSelectedUserIds] = useState([]);
  const [singleTargetId, setSingleTargetId] = useState(null); // for "send to one user" action
  const [form] = Form.useForm();

  const fetchAll = async () => {
    setLoadingUsers(true);
    try {
      const [statsRes, usersRes] = await Promise.all([
        api.get('/admin/stats'),
        api.get('/admin/users'),
      ]);
      setStats(statsRes.data);
      setUsers(usersRes.data);
    } catch {
      message.error('Failed to load admin data');
    }
    setLoadingUsers(false);
  };

  useEffect(() => { fetchAll(); }, []);

  const filteredUsers = useMemo(() =>
    users.filter((u) =>
      u.name.toLowerCase().includes(search.toLowerCase()) ||
      u.email.toLowerCase().includes(search.toLowerCase())
    ), [users, search]);

  const openBroadcast = (userId = null) => {
    setSingleTargetId(userId);
    setTargetMode(userId ? 'select' : 'all');
    setSelectedUserIds(userId ? [userId] : []);
    form.resetFields();
    form.setFieldsValue({ repeatType: 'none' });
    setBroadcastOpen(true);
  };

  const handleBroadcast = async () => {
    try {
      const values = await form.validateFields();
      setBroadcastLoading(true);

      let targetUserIds;
      if (targetMode === 'all') {
        targetUserIds = 'all';
      } else {
        targetUserIds = selectedUserIds;
        if (targetUserIds.length === 0) {
          message.warning('Select at least one user');
          setBroadcastLoading(false);
          return;
        }
      }

      const res = await api.post('/admin/reminders/broadcast', {
        title: values.title,
        note: values.note,
        scheduledAt: values.scheduledAt.toISOString(),
        repeatType: values.repeatType || 'none',
        targetUserIds,
      });

      message.success(res.data.message);
      setBroadcastOpen(false);
      fetchAll();
    } catch (err) {
      if (err?.response) message.error(err.response?.data?.message || 'Failed');
    }
    setBroadcastLoading(false);
  };

  const columns = [
    {
      title: 'User',
      key: 'user',
      render: (_, row) => (
        <Space>
          <Avatar style={{ background: primaryColor }} icon={<UserOutlined />} src={row.avatar} size={36} />
          <div>
            <div style={{ fontWeight: 600, fontSize: 14 }}>{row.name}</div>
            <div style={{ fontSize: 12, color: '#888' }}>{row.email}</div>
          </div>
        </Space>
      ),
      filteredValue: [search],
      onFilter: () => true,
    },
    {
      title: 'Joined',
      dataIndex: 'createdAt',
      render: (v) => dayjs(v).format('MMM D, YYYY'),
      width: 130,
    },
    {
      title: 'Transactions',
      dataIndex: ['_count', 'transactions'],
      align: 'center',
      width: 120,
      render: (v) => <Tag color="blue">{v}</Tag>,
    },
    {
      title: 'Reminders',
      dataIndex: ['_count', 'reminders'],
      align: 'center',
      width: 110,
      render: (v) => <Tag color={v > 0 ? 'orange' : 'default'}>{v}</Tag>,
    },
    {
      title: 'Accounts',
      dataIndex: ['_count', 'accounts'],
      align: 'center',
      width: 100,
      render: (v) => <Tag>{v}</Tag>,
    },
    {
      title: 'Action',
      key: 'action',
      width: 140,
      render: (_, row) => (
        <Button
          size="small"
          icon={<BellOutlined />}
          onClick={() => openBroadcast(row.id)}
          style={{ borderRadius: 6 }}
        >
          Notify
        </Button>
      ),
    },
  ];

  return (
    <Layout style={{ minHeight: '100vh', background: '#f5f7fa' }}>
      <Header style={{
        background: '#001529',
        padding: '0 24px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        position: 'sticky',
        top: 0,
        zIndex: 100,
      }}>
        <Space size={12}>
          <CrownOutlined style={{ color: '#faad14', fontSize: 22 }} />
          <Text strong style={{ color: '#fff', fontSize: 18 }}>FinTrack Admin</Text>
          <Tag color="gold" style={{ marginLeft: 4 }}>Superadmin</Tag>
        </Space>
        <Space>
          <Text style={{ color: 'rgba(255,255,255,0.65)', fontSize: 13 }}>{user?.email}</Text>
          <Popconfirm title="Sign out?" onConfirm={() => dispatch(logout())}>
            <Button type="text" icon={<LogoutOutlined />} style={{ color: 'rgba(255,255,255,0.65)' }}>
              Sign Out
            </Button>
          </Popconfirm>
        </Space>
      </Header>

      <Content style={{ padding: '28px 32px' }}>
        {/* Stats */}
        <Row gutter={[20, 20]} style={{ marginBottom: 28 }}>
          {[
            { title: 'Total Users', value: stats?.totalUsers ?? '—', icon: <TeamOutlined />, color: primaryColor },
            { title: 'Total Transactions', value: stats?.totalTransactions ?? '—', icon: <SwapOutlined />, color: '#52c41a' },
            { title: 'Total Reminders Sent', value: stats?.totalReminders ?? '—', icon: <BellOutlined />, color: '#fa8c16' },
          ].map((s) => (
            <Col xs={24} sm={8} key={s.title}>
              <Card style={{ borderRadius: 14, borderTop: `3px solid ${s.color}` }}>
                <Statistic
                  title={s.title}
                  value={s.value}
                  prefix={<span style={{ color: s.color, marginRight: 6 }}>{s.icon}</span>}
                  valueStyle={{ fontWeight: 700, fontSize: 28 }}
                />
              </Card>
            </Col>
          ))}
        </Row>

        {/* Users table */}
        <Card
          style={{ borderRadius: 14 }}
          title={
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 12 }}>
              <Space>
                <TeamOutlined />
                <span style={{ fontWeight: 700, fontSize: 16 }}>Registered Users</span>
                <Badge count={users.length} style={{ background: primaryColor }} />
              </Space>
              <Space>
                <Input
                  prefix={<SearchOutlined style={{ color: '#bbb' }} />}
                  placeholder="Search name or email…"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  style={{ width: 220, borderRadius: 8 }}
                  allowClear
                />
                <Button
                  type="primary"
                  icon={<SendOutlined />}
                  onClick={() => openBroadcast()}
                  style={{ borderRadius: 8 }}
                >
                  Broadcast to All
                </Button>
              </Space>
            </div>
          }
        >
          <Table
            dataSource={filteredUsers}
            columns={columns}
            rowKey="id"
            loading={loadingUsers}
            pagination={{ pageSize: 10, showSizeChanger: false }}
            scroll={{ x: 700 }}
          />
        </Card>
      </Content>

      {/* Broadcast Modal */}
      <Modal
        title={
          <Space>
            <BellOutlined style={{ color: primaryColor }} />
            {singleTargetId
              ? `Send Notification to ${users.find((u) => u.id === singleTargetId)?.name ?? 'User'}`
              : 'Broadcast Notification'}
          </Space>
        }
        open={broadcastOpen}
        onOk={handleBroadcast}
        onCancel={() => setBroadcastOpen(false)}
        confirmLoading={broadcastLoading}
        okText={<Space><SendOutlined />Send</Space>}
        okButtonProps={{ style: { borderRadius: 8 } }}
        cancelButtonProps={{ style: { borderRadius: 8 } }}
        width={560}
        destroyOnClose
      >
        <Form form={form} layout="vertical" style={{ marginTop: 16 }}>
          <Form.Item name="title" label="Notification Title" rules={[{ required: true, message: 'Enter a title' }]}>
            <Input placeholder="e.g. Monthly payment due, App update available" />
          </Form.Item>

          <Row gutter={16}>
            <Col span={14}>
              <Form.Item name="scheduledAt" label="Scheduled Date & Time" rules={[{ required: true, message: 'Select date' }]}>
                <DatePicker showTime style={{ width: '100%' }} format="YYYY-MM-DD HH:mm" />
              </Form.Item>
            </Col>
            <Col span={10}>
              <Form.Item name="repeatType" label="Repeat" initialValue="none">
                <Select options={REPEAT_OPTIONS} />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item name="note" label="Message (optional)">
            <Input.TextArea rows={2} placeholder="Optional message shown with the notification…" />
          </Form.Item>

          {/* Target selection — hidden when sending to a single user */}
          {!singleTargetId && (
            <>
              <Divider style={{ margin: '12px 0' }} />
              <div style={{ marginBottom: 12 }}>
                <Text strong>Send to</Text>
              </div>
              <Segmented
                value={targetMode}
                onChange={setTargetMode}
                options={[
                  { label: `All Users (${users.length})`, value: 'all' },
                  { label: 'Select Specific', value: 'select' },
                ]}
                style={{ marginBottom: 16 }}
              />

              {targetMode === 'select' && (
                <div style={{
                  border: '1px solid #f0f0f0',
                  borderRadius: 10,
                  maxHeight: 220,
                  overflowY: 'auto',
                  padding: '8px 12px',
                }}>
                  <div style={{ marginBottom: 8 }}>
                    <Checkbox
                      indeterminate={selectedUserIds.length > 0 && selectedUserIds.length < users.length}
                      checked={selectedUserIds.length === users.length}
                      onChange={(e) => setSelectedUserIds(e.target.checked ? users.map((u) => u.id) : [])}
                    >
                      <Text strong>Select all</Text>
                    </Checkbox>
                  </div>
                  <Divider style={{ margin: '6px 0' }} />
                  {users.map((u) => (
                    <div key={u.id} style={{ padding: '6px 0' }}>
                      <Checkbox
                        checked={selectedUserIds.includes(u.id)}
                        onChange={(e) => {
                          setSelectedUserIds((prev) =>
                            e.target.checked ? [...prev, u.id] : prev.filter((id) => id !== u.id)
                          );
                        }}
                      >
                        <Space size={8}>
                          <Avatar size={24} icon={<UserOutlined />} style={{ background: primaryColor }} />
                          <span style={{ fontSize: 13 }}>{u.name}</span>
                          <Text type="secondary" style={{ fontSize: 12 }}>{u.email}</Text>
                        </Space>
                      </Checkbox>
                    </div>
                  ))}
                </div>
              )}

              {targetMode === 'all' && (
                <div style={{ background: '#fff7e6', border: '1px solid #ffd591', borderRadius: 8, padding: '10px 14px' }}>
                  <Space>
                    <CheckCircleOutlined style={{ color: '#fa8c16' }} />
                    <Text style={{ fontSize: 13 }}>
                      This reminder will be sent to all <strong>{users.length}</strong> registered user(s).
                    </Text>
                  </Space>
                </div>
              )}
            </>
          )}
        </Form>
      </Modal>
    </Layout>
  );
}
