import { useEffect, useState } from 'react';
import { Row, Col, Card, Table, Button, Modal, Form, Input, InputNumber, Select, DatePicker, Typography, Space, Popconfirm, Tag, Avatar, Badge, Skeleton } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, SyncOutlined, WalletOutlined } from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { fetchRecurring, addRecurring, updateRecurring, deleteRecurring } from '../store/slices/recurringSlice';
import { fetchAccounts } from '../store/slices/accountSlice';
import { fetchCategories } from '../store/slices/categorySlice';
import useT from '../i18n/useT';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';

dayjs.extend(relativeTime);

const { Title, Text } = Typography;
const { Option } = Select;

export default function RecurringTransactions() {
  const dispatch = useDispatch();
  const t = useT();
  const { transactions, loading } = useSelector((s) => s.recurring);
  const { list: accounts } = useSelector((s) => s.accounts);
  const { list: categories } = useSelector((s) => s.categories);
  const primaryColor = useSelector((s) => s.settings.primaryColor);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingRT, setEditingRT] = useState(null);
  const [form] = Form.useForm();

  useEffect(() => {
    dispatch(fetchRecurring());
    dispatch(fetchAccounts());
    dispatch(fetchCategories());
  }, [dispatch]);

  const showModal = (rt = null) => {
    setEditingRT(rt);
    if (rt) {
      form.setFieldsValue({
        ...rt,
        nextDue: dayjs(rt.nextDue),
      });
    } else {
      form.resetFields();
      form.setFieldsValue({ 
        type: 'expense', 
        frequency: 'monthly',
        nextDue: dayjs().add(1, 'month').startOf('day')
      });
    }
    setIsModalOpen(true);
  };

  const handleOk = async () => {
    try {
      const values = await form.validateFields();
      if (editingRT) {
        await dispatch(updateRecurring({ id: editingRT.id, data: values }));
      } else {
        await dispatch(addRecurring(values));
      }
      setIsModalOpen(false);
    } catch (err) {
      console.error(err);
    }
  };

  const fmt = (n) => new Intl.NumberFormat('id-ID').format(n);

  const columns = [
    {
      title: 'Subscription / Transaction',
      dataIndex: 'note',
      key: 'note',
      render: (text, record) => (
        <Space size="middle">
          <Avatar 
            shape="square" 
            style={{ backgroundColor: record.category?.color + '20', color: record.category?.color }}
            icon={<SyncOutlined />}
          />
          <div>
            <Text strong>{text || 'No note'}</Text>
            <div style={{ fontSize: 12, opacity: 0.6 }}>{record.category?.name}</div>
          </div>
        </Space>
      )
    },
    {
      title: 'Frequency',
      dataIndex: 'frequency',
      key: 'frequency',
      render: (freq) => <Tag icon={<SyncOutlined spin={false} />} color="blue">{freq.toUpperCase()}</Tag>
    },
    {
      title: 'Amount',
      dataIndex: 'amount',
      key: 'amount',
      render: (amt, record) => (
        <Text strong style={{ color: record.type === 'income' ? '#52c41a' : '#ff4d4f' }}>
          {record.type === 'income' ? '+' : '-'} IDR {fmt(amt)}
        </Text>
      )
    },
    {
      title: 'Next Due',
      dataIndex: 'nextDue',
      key: 'nextDue',
      render: (date) => (
        <div>
          <Text>{dayjs(date).format('MMM D, YYYY')}</Text>
          <div style={{ fontSize: 11, opacity: 0.5 }}>{dayjs(date).fromNow()}</div>
        </div>
      )
    },
    {
      title: 'Account',
      dataIndex: 'account',
      key: 'account',
      render: (acc) => (
        <Tag icon={<WalletOutlined />} color={acc?.color}>{acc?.name}</Tag>
      )
    },
    {
      title: 'Status',
      dataIndex: 'isActive',
      key: 'isActive',
      render: (active) => (
        <Badge status={active ? "processing" : "default"} text={active ? "Active" : "Paused"} />
      )
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_, record) => (
        <Space>
          <Button type="text" icon={<EditOutlined />} onClick={() => showModal(record)} />
          <Popconfirm title="Delete this?" onConfirm={() => dispatch(deleteRecurring(record.id))}>
            <Button type="text" danger icon={<DeleteOutlined />} />
          </Popconfirm>
        </Space>
      )
    }
  ];

  return (
    <div className="page-container">
      <Row gutter={[16, 16]} align="middle" style={{ marginBottom: 24 }}>
        <Col flex="auto">
          <Title level={3} style={{ margin: 0 }}>{t('nav_recurring') || 'Recurring Transactions'}</Title>
          <Text type="secondary">Manage your subscriptions and recurring payments</Text>
        </Col>
        <Col>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => showModal()} size="large" style={{ borderRadius: 10 }}>
            {t('addRecurring') || 'Add Recurring'}
          </Button>
        </Col>
      </Row>

      <Card className="stat-card" style={{ padding: 0, overflow: 'hidden' }}>
        <Table 
          columns={columns} 
          dataSource={transactions} 
          rowKey="id" 
          loading={loading}
          pagination={{ pageSize: 10 }}
        />
      </Card>

      <Modal
        title={editingRT ? "Edit Recurring Transaction" : "Add Recurring Transaction"}
        open={isModalOpen}
        onOk={handleOk}
        onCancel={() => setIsModalOpen(false)}
        destroyOnClose
        width={600}
        okText={editingRT ? "Update" : "Create"}
        okButtonProps={{ style: { borderRadius: 8 } }}
        cancelButtonProps={{ style: { borderRadius: 8 } }}
      >
        <Form form={form} layout="vertical" style={{ marginTop: 16 }}>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="type" label="Type" rules={[{ required: true }]}>
                <Select>
                  <Option value="expense">Expense</Option>
                  <Option value="income">Income</Option>
                </Select>
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="amount" label="Amount" rules={[{ required: true, message: 'Please enter amount' }]}>
                <InputNumber 
                  style={{ width: '100%' }} 
                  formatter={value => `IDR ${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')}
                  parser={value => value.replace(/IDR\s?|(,*)/g, '')}
                  min={0}
                />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="accountId" label="Account" rules={[{ required: true, message: 'Select account' }]}>
                <Select placeholder="Select account">
                  {accounts.map(acc => (
                    <Option key={acc.id} value={acc.id}>{acc.name}</Option>
                  ))}
                </Select>
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="categoryId" label="Category" rules={[{ required: true, message: 'Select category' }]}>
                <Select placeholder="Select category">
                  {categories.map(cat => (
                    <Option key={cat.id} value={cat.id}>{cat.name}</Option>
                  ))}
                </Select>
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="frequency" label="Frequency" rules={[{ required: true }]}>
                <Select>
                  <Option value="daily">Daily</Option>
                  <Option value="weekly">Weekly</Option>
                  <Option value="monthly">Monthly</Option>
                  <Option value="yearly">Yearly</Option>
                </Select>
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="nextDue" label="Next Due Date" rules={[{ required: true }]}>
                <DatePicker style={{ width: '100%' }} />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item name="note" label="Note / Description">
            <Input placeholder="e.g. Netflix Subscription, Rent, Electric Bill" />
          </Form.Item>

          <Form.Item name="isActive" label="Active Status" valuePropName="checked" initialValue={true}>
            <Select>
              <Option value={true}>Active (Running)</Option>
              <Option value={false}>Paused (Disabled)</Option>
            </Select>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
