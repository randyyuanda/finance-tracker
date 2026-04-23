import { useEffect, useState, useMemo } from 'react';
import {
  Row, Col, Card, Button, Modal, Form, Input, DatePicker, TimePicker,
  Select, Typography, Space, Popconfirm, Empty, Skeleton, Tag, Tabs,
  Checkbox, Tooltip, Badge,
} from 'antd';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, BellOutlined,
  CheckCircleOutlined, ClockCircleOutlined, ExclamationCircleOutlined,
  CalendarOutlined,
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
  { value: 'bill', label: 'Bill' },
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

const TYPE_COLORS = { custom: 'blue', bill: 'volcano', goal: 'gold', recurring: 'purple' };

function getStatus(r) {
  if (r.isCompleted) return 'completed';
  if (dayjs(r.reminderDate).isBefore(dayjs())) return 'overdue';
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

  useEffect(() => { dispatch(fetchReminders()); }, [dispatch]);

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
      const d = dayjs(reminder.reminderDate);
      form.setFieldsValue({
        ...reminder,
        _date: d,
        _time: d,
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
      const date = values._date;
      const time = values._time;
      const reminderDate = date
        .hour(time.hour())
        .minute(time.minute())
        .second(0)
        .toISOString();

      const data = {
        title: values.title,
        note: values.note,
        type: values.type,
        repeatType: values.repeatType,
        reminderDate,
      };

      if (editing) {
        await dispatch(updateReminder({ id: editing.id, data }));
      } else {
        await dispatch(addReminder(data));
      }
      setIsModalOpen(false);
    } catch {}
  };

  const tabItems = [
    { key: 'all',       label: <><span>All</span>{' '}<Badge count={counts.all} style={{ background: '#d9d9d9', color: '#555', boxShadow: 'none', marginLeft: 4 }} /></> },
    { key: 'upcoming',  label: <><span>Upcoming</span>{' '}<Badge count={counts.upcoming} style={{ background: primaryColor, marginLeft: 4 }} /></> },
    { key: 'overdue',   label: <><span>Overdue</span>{' '}<Badge count={counts.overdue} color="red" style={{ marginLeft: 4 }} /></> },
    { key: 'completed', label: <><span>Done</span>{' '}<Badge count={counts.completed} color="green" style={{ marginLeft: 4 }} /></> },
  ];

  return (
    <div className="page-container">
      <Row gutter={[16, 16]} align="middle" style={{ marginBottom: 20 }}>
        <Col flex="auto">
          <Title level={3} style={{ margin: 0 }}>Reminders</Title>
          <Text type="secondary">Stay on top of bills, goals, and important dates</Text>
        </Col>
        <Col>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => showModal()} style={{ borderRadius: 10 }}>
            Add
          </Button>
        </Col>
      </Row>

      <Tabs
        activeKey={activeTab}
        onChange={setActiveTab}
        items={tabItems}
        style={{ marginBottom: 16 }}
        tabBarStyle={{ marginBottom: 0 }}
      />

      {loading ? (
        <Row gutter={[16, 16]}>
          {[1, 2, 3].map((i) => <Col xs={24} md={12} lg={8} key={i}><Card><Skeleton active /></Card></Col>)}
        </Row>
      ) : filtered.length === 0 ? (
        <Card style={{ textAlign: 'center', padding: '40px 0', borderRadius: 12 }}>
          <Empty
            image={<BellOutlined style={{ fontSize: 56, color: '#d9d9d9' }} />}
            imageStyle={{ height: 70 }}
            description={activeTab === 'all' ? 'No reminders yet' : `No ${activeTab} reminders`}
          />
          {activeTab === 'all' && (
            <Button type="primary" ghost icon={<PlusOutlined />} onClick={() => showModal()} style={{ marginTop: 16 }}>
              Create your first reminder
            </Button>
          )}
        </Card>
      ) : (
        <Row gutter={[12, 12]}>
          {filtered.map((reminder) => {
            const status = getStatus(reminder);
            const isOverdue = status === 'overdue';
            const isDone = status === 'completed';
            const accent = isDone ? '#52c41a' : isOverdue ? '#ff4d4f' : primaryColor;

            return (
              <Col xs={24} md={12} lg={8} key={reminder.id}>
                <Card
                  className="stat-card"
                  hoverable
                  style={{ borderLeft: `4px solid ${accent}`, opacity: isDone ? 0.78 : 1 }}
                  bodyStyle={{ padding: '14px 16px' }}
                >
                  {/* Top row: checkbox + title + actions */}
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: 8 }}>
                    <Tooltip title={isDone ? 'Mark incomplete' : 'Mark done'}>
                      <Checkbox
                        checked={isDone}
                        onChange={() => dispatch(toggleReminderComplete(reminder.id))}
                        style={{ marginTop: 2, flexShrink: 0 }}
                      />
                    </Tooltip>

                    <div style={{ flex: 1, minWidth: 0 }}>
                      <Text
                        strong
                        style={{
                          fontSize: 14,
                          textDecoration: isDone ? 'line-through' : 'none',
                          display: 'block',
                          lineHeight: '20px',
                        }}
                        ellipsis
                      >
                        {reminder.title}
                      </Text>

                      {/* Date row */}
                      <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginTop: 5 }}>
                        {isOverdue && !isDone
                          ? <ExclamationCircleOutlined style={{ color: '#ff4d4f', fontSize: 12, flexShrink: 0 }} />
                          : isDone
                            ? <CheckCircleOutlined style={{ color: '#52c41a', fontSize: 12, flexShrink: 0 }} />
                            : <ClockCircleOutlined style={{ color: accent, fontSize: 12, flexShrink: 0 }} />
                        }
                        <Text type="secondary" style={{ fontSize: 12, lineHeight: '16px' }}>
                          {dayjs(reminder.reminderDate).format('D MMM YYYY, HH:mm')}
                        </Text>
                        <Text type="secondary" style={{ fontSize: 11, lineHeight: '16px', color: isOverdue && !isDone ? '#ff4d4f' : undefined }}>
                          · {dayjs(reminder.reminderDate).fromNow()}
                        </Text>
                      </div>

                      {/* Tags row */}
                      <Space size={4} style={{ marginTop: 6, flexWrap: 'wrap' }}>
                        <Tag color={TYPE_COLORS[reminder.type] || 'blue'} style={{ fontSize: 11, margin: 0, lineHeight: '18px' }}>
                          {reminder.type}
                        </Tag>
                        {reminder.repeatType !== 'none' && (
                          <Tag color="cyan" style={{ fontSize: 11, margin: 0, lineHeight: '18px' }}>↻ {reminder.repeatType}</Tag>
                        )}
                        {isOverdue && !isDone && <Tag color="error" style={{ fontSize: 11, margin: 0, lineHeight: '18px' }}>Overdue</Tag>}
                        {isDone && <Tag color="success" style={{ fontSize: 11, margin: 0, lineHeight: '18px' }}>Done</Tag>}
                      </Space>

                      {reminder.note && (
                        <Text type="secondary" style={{ fontSize: 12, display: 'block', marginTop: 6 }} ellipsis>
                          {reminder.note}
                        </Text>
                      )}
                    </div>

                    {/* Action buttons */}
                    <Space direction="vertical" size={2} style={{ flexShrink: 0 }}>
                      <Button type="text" icon={<EditOutlined />} size="small" onClick={() => showModal(reminder)} />
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

      {/* Add / Edit Modal */}
      <Modal
        title={editing ? 'Edit Reminder' : 'New Reminder'}
        open={isModalOpen}
        onOk={handleOk}
        onCancel={() => setIsModalOpen(false)}
        destroyOnClose
        okText={editing ? 'Update' : 'Create'}
        okButtonProps={{ style: { borderRadius: 8 } }}
        cancelButtonProps={{ style: { borderRadius: 8 } }}
        style={{ top: 20 }}
        styles={{ body: { padding: '16px 24px' } }}
        width="min(520px, 95vw)"
      >
        <Form form={form} layout="vertical">
          <Form.Item name="title" label="Title" rules={[{ required: true, message: 'Enter a title' }]}>
            <Input placeholder="e.g. Pay electricity bill" size="large" />
          </Form.Item>

          {/* Separate date + time pickers — much better on mobile */}
          <Row gutter={12}>
            <Col xs={14} sm={14}>
              <Form.Item
                name="_date"
                label={<><CalendarOutlined style={{ marginRight: 5 }} />Date</>}
                rules={[{ required: true, message: 'Pick a date' }]}
              >
                <DatePicker style={{ width: '100%' }} size="large" format="D MMM YYYY" inputReadOnly />
              </Form.Item>
            </Col>
            <Col xs={10} sm={10}>
              <Form.Item
                name="_time"
                label="Time"
                rules={[{ required: true, message: 'Pick a time' }]}
              >
                <TimePicker style={{ width: '100%' }} size="large" format="HH:mm" minuteStep={5} inputReadOnly />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={12}>
            <Col xs={12}>
              <Form.Item name="type" label="Type">
                <Select options={TYPE_OPTIONS} size="large" />
              </Form.Item>
            </Col>
            <Col xs={12}>
              <Form.Item name="repeatType" label="Repeat">
                <Select options={REPEAT_OPTIONS} size="large" />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item name="note" label="Note" style={{ marginBottom: 0 }}>
            <TextArea rows={2} placeholder="Optional note…" />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
