import { useEffect, useState, useMemo } from 'react';
import {
  Row, Col, Card, Button, Modal, Form, Input, DatePicker, Select, Typography,
  Space, Popconfirm, Empty, Skeleton, Tag, Tabs, Checkbox, Tooltip, Badge,
} from 'antd';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, BellOutlined,
  CheckCircleOutlined, ClockCircleOutlined, ExclamationCircleOutlined,
} from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchReminders, addReminder, updateReminder,
  toggleReminderComplete, deleteReminder,
} from '../store/slices/reminderSlice';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
dayjs.extend(relativeTime);

const { Title, Text } = Typography;
const { TextArea } = Input;

const TYPE_OPTIONS = [
  { value: 'custom', label: 'Custom' },
  { value: 'bill', label: 'Bill Payment' },
  { value: 'goal', label: 'Goal' },
  { value: 'recurring', label: 'Recurring' },
];

const REPEAT_OPTIONS = [
  { value: 'none', label: 'No repeat' },
  { value: 'daily', label: 'Daily' },
  { value: 'weekly', label: 'Weekly' },
  { value: 'monthly', label: 'Monthly' },
  { value: 'yearly', label: 'Yearly' },
];

const TYPE_COLORS = {
  custom: 'blue',
  bill: 'volcano',
  goal: 'gold',
  recurring: 'purple',
};

function getStatus(reminder) {
  if (reminder.isCompleted) return 'completed';
  if (dayjs(reminder.reminderDate).isBefore(dayjs())) return 'overdue';
  return 'upcoming';
}

export default function Reminders() {
  const dispatch = useDispatch();
  const { reminders, loading } = useSelector((s) => s.reminders);
  const primaryColor = useSelector((s) => s.settings.primaryColor);

  const [activeTab, setActiveTab] = useState('all');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form] = Form.useForm();

  useEffect(() => {
    dispatch(fetchReminders());
  }, [dispatch]);

  const filtered = useMemo(() => {
    if (activeTab === 'all') return reminders;
    return reminders.filter((r) => getStatus(r) === activeTab);
  }, [reminders, activeTab]);

  const counts = useMemo(() => ({
    all: reminders.length,
    upcoming: reminders.filter((r) => getStatus(r) === 'upcoming').length,
    overdue: reminders.filter((r) => getStatus(r) === 'overdue').length,
    completed: reminders.filter((r) => getStatus(r) === 'completed').length,
  }), [reminders]);

  const showModal = (reminder = null) => {
    setEditing(reminder);
    if (reminder) {
      form.setFieldsValue({
        ...reminder,
        reminderDate: dayjs(reminder.reminderDate),
      });
    } else {
      form.resetFields();
      form.setFieldsValue({ type: 'custom', repeatType: 'none' });
    }
    setIsModalOpen(true);
  };

  const handleOk = async () => {
    try {
      const values = await form.validateFields();
      const data = { ...values, reminderDate: values.reminderDate.toISOString() };
      if (editing) {
        await dispatch(updateReminder({ id: editing.id, data }));
      } else {
        await dispatch(addReminder(data));
      }
      setIsModalOpen(false);
    } catch {}
  };

  const tabItems = [
    { key: 'all', label: <span>All <Badge count={counts.all} style={{ background: '#d9d9d9', color: '#666', boxShadow: 'none' }} /></span> },
    { key: 'upcoming', label: <span>Upcoming <Badge count={counts.upcoming} style={{ background: primaryColor }} /></span> },
    { key: 'overdue', label: <span>Overdue <Badge count={counts.overdue} color="red" /></span> },
    { key: 'completed', label: <span>Completed <Badge count={counts.completed} color="green" /></span> },
  ];

  return (
    <div className="page-container">
      <Row gutter={[16, 16]} align="middle" style={{ marginBottom: 24 }}>
        <Col flex="auto">
          <Title level={3} style={{ margin: 0 }}>Reminders</Title>
          <Text type="secondary">Stay on top of bills, goals, and important dates</Text>
        </Col>
        <Col>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => showModal()} size="large" style={{ borderRadius: 10 }}>
            Add Reminder
          </Button>
        </Col>
      </Row>

      <Tabs activeKey={activeTab} onChange={setActiveTab} items={tabItems} style={{ marginBottom: 16 }} />

      {loading ? (
        <Row gutter={[16, 16]}>
          {[1, 2, 3].map((i) => (
            <Col xs={24} md={12} lg={8} key={i}><Card><Skeleton active /></Card></Col>
          ))}
        </Row>
      ) : filtered.length === 0 ? (
        <Card style={{ textAlign: 'center', padding: '40px 0', borderRadius: 12 }}>
          <Empty
            image={<BellOutlined style={{ fontSize: 64, color: '#d9d9d9' }} />}
            imageStyle={{ height: 80 }}
            description={activeTab === 'all' ? "No reminders yet" : `No ${activeTab} reminders`}
          />
          {activeTab === 'all' && (
            <Button type="primary" ghost icon={<PlusOutlined />} onClick={() => showModal()} style={{ marginTop: 16 }}>
              Create your first reminder
            </Button>
          )}
        </Card>
      ) : (
        <Row gutter={[16, 16]}>
          {filtered.map((reminder) => {
            const status = getStatus(reminder);
            const isOverdue = status === 'overdue';
            const isDone = status === 'completed';

            return (
              <Col xs={24} md={12} lg={8} key={reminder.id}>
                <Card
                  className="stat-card"
                  hoverable
                  style={{
                    borderLeft: `4px solid ${isDone ? '#52c41a' : isOverdue ? '#ff4d4f' : primaryColor}`,
                    opacity: isDone ? 0.75 : 1,
                  }}
                  bodyStyle={{ padding: '16px 20px' }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8 }}>
                    <Space direction="vertical" size={4} style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <Tooltip title={isDone ? 'Mark as incomplete' : 'Mark as done'}>
                          <Checkbox
                            checked={isDone}
                            onChange={() => dispatch(toggleReminderComplete(reminder.id))}
                          />
                        </Tooltip>
                        <Text
                          strong
                          style={{ fontSize: 15, textDecoration: isDone ? 'line-through' : 'none', flex: 1 }}
                          ellipsis
                        >
                          {reminder.title}
                        </Text>
                      </div>

                      <Space size={6} wrap>
                        <Tag color={TYPE_COLORS[reminder.type] || 'blue'} style={{ fontSize: 11, margin: 0 }}>
                          {reminder.type}
                        </Tag>
                        {reminder.repeatType !== 'none' && (
                          <Tag color="cyan" style={{ fontSize: 11, margin: 0 }}>
                            {reminder.repeatType}
                          </Tag>
                        )}
                        {isOverdue && <Tag color="error" style={{ fontSize: 11, margin: 0 }}>Overdue</Tag>}
                        {isDone && <Tag color="success" style={{ fontSize: 11, margin: 0 }}>Done</Tag>}
                      </Space>

                      <Space size={4}>
                        {isOverdue ? (
                          <ExclamationCircleOutlined style={{ color: '#ff4d4f', fontSize: 13 }} />
                        ) : isDone ? (
                          <CheckCircleOutlined style={{ color: '#52c41a', fontSize: 13 }} />
                        ) : (
                          <ClockCircleOutlined style={{ color: primaryColor, fontSize: 13 }} />
                        )}
                        <Text type="secondary" style={{ fontSize: 13 }}>
                          {dayjs(reminder.reminderDate).format('MMM D, YYYY HH:mm')}
                        </Text>
                        <Text type="secondary" style={{ fontSize: 12 }}>
                          ({dayjs(reminder.reminderDate).fromNow()})
                        </Text>
                      </Space>

                      {reminder.note && (
                        <Text type="secondary" style={{ fontSize: 13 }} ellipsis>
                          {reminder.note}
                        </Text>
                      )}
                    </Space>

                    <Space direction="vertical" size={4}>
                      <Button
                        type="text"
                        icon={<EditOutlined />}
                        size="small"
                        onClick={() => showModal(reminder)}
                      />
                      <Popconfirm title="Delete this reminder?" onConfirm={() => dispatch(deleteReminder(reminder.id))}>
                        <Button type="text" icon={<DeleteOutlined style={{ color: '#ff4d4f' }} />} size="small" />
                      </Popconfirm>
                    </Space>
                  </div>
                </Card>
              </Col>
            );
          })}
        </Row>
      )}

      <Modal
        title={editing ? 'Edit Reminder' : 'New Reminder'}
        open={isModalOpen}
        onOk={handleOk}
        onCancel={() => setIsModalOpen(false)}
        destroyOnClose
        okText={editing ? 'Update' : 'Create'}
        okButtonProps={{ style: { borderRadius: 8 } }}
        cancelButtonProps={{ style: { borderRadius: 8 } }}
      >
        <Form form={form} layout="vertical" style={{ marginTop: 16 }}>
          <Form.Item name="title" label="Title" rules={[{ required: true, message: 'Please enter a title' }]}>
            <Input placeholder="e.g. Pay electricity bill" />
          </Form.Item>

          <Form.Item name="reminderDate" label="Reminder Date & Time" rules={[{ required: true, message: 'Please select a date' }]}>
            <DatePicker showTime style={{ width: '100%' }} format="YYYY-MM-DD HH:mm" />
          </Form.Item>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="type" label="Type">
                <Select options={TYPE_OPTIONS} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="repeatType" label="Repeat">
                <Select options={REPEAT_OPTIONS} />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item name="note" label="Note">
            <TextArea rows={3} placeholder="Optional note..." />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
