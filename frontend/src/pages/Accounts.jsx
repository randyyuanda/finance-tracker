import { useEffect, useState } from 'react';
import {
  Row, Col, Card, Button, Modal, Form, Input, Select, InputNumber,
  Typography, Avatar, Popconfirm, message, Skeleton, Empty,
} from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, WalletOutlined } from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { fetchAccounts, createAccount, updateAccount, deleteAccount } from '../store/slices/accountSlice';

const { Title, Text } = Typography;
const { Option } = Select;

const COLORS = ['#1890ff', '#52c41a', '#fa541c', '#faad14', '#722ed1', '#eb2f96', '#13c2c2', '#00aa5b', '#4c3494'];

const ACCOUNT_TYPES = [
  { value: 'cash', label: 'Cash' },
  { value: 'bank', label: 'Bank' },
  { value: 'e-wallet', label: 'E-Wallet' },
  { value: 'credit-card', label: 'Credit Card' },
  { value: 'savings', label: 'Savings' },
];

const fmt = (n) => new Intl.NumberFormat('id-ID').format(n);

export default function Accounts() {
  const dispatch = useDispatch();
  const { list: accounts, loading } = useSelector((s) => s.accounts);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form] = Form.useForm();

  useEffect(() => { dispatch(fetchAccounts()); }, [dispatch]);

  const openCreate = () => {
    setEditing(null);
    form.resetFields();
    form.setFieldsValue({ color: '#1890ff', type: 'cash' });
    setOpen(true);
  };

  const openEdit = (acc) => {
    setEditing(acc);
    form.setFieldsValue(acc);
    setOpen(true);
  };

  const onSubmit = async () => {
    try {
      const values = await form.validateFields();
      if (editing) {
        await dispatch(updateAccount({ id: editing._id, data: values })).unwrap();
        message.success('Account updated');
      } else {
        await dispatch(createAccount(values)).unwrap();
        message.success('Account created');
      }
      setOpen(false);
      dispatch(fetchAccounts());
    } catch (err) {
      if (err?.message) message.error(err.message);
    }
  };

  const onDelete = async (id) => {
    try {
      await dispatch(deleteAccount(id)).unwrap();
      message.success('Account deleted');
    } catch (err) {
      message.error(err?.message || 'Delete failed');
    }
  };

  const totalBalance = accounts.reduce((s, a) => s + a.balance, 0);

  return (
    <div className="page-container">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <div>
          <Title level={4} style={{ margin: 0 }}>Accounts</Title>
          <Text type="secondary">Total: IDR {fmt(totalBalance)}</Text>
        </div>
        <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>Add Account</Button>
      </div>

      {loading ? (
        <Row gutter={[12, 12]}>{[1,2,3,4].map((i) => <Col xs={24} sm={12} lg={6} key={i}><Skeleton active /></Col>)}</Row>
      ) : accounts.length === 0 ? (
        <Empty description="No accounts yet" extra={<Button type="primary" onClick={openCreate}>Add your first account</Button>} />
      ) : (
        <Row gutter={[12, 12]}>
          {accounts.map((acc) => (
            <Col xs={24} sm={12} lg={6} key={acc._id}>
              <Card
                className="account-card"
                style={{ borderTop: `4px solid ${acc.color}` }}
                actions={[
                  <EditOutlined key="edit" onClick={() => openEdit(acc)} />,
                  <Popconfirm key="del" title="Delete this account?" onConfirm={() => onDelete(acc._id)} okText="Yes" cancelText="No">
                    <DeleteOutlined style={{ color: '#ff4d4f' }} />
                  </Popconfirm>,
                ]}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
                  <Avatar size={44} style={{ background: acc.color }} icon={<WalletOutlined />} />
                  <div>
                    <Text strong style={{ display: 'block' }}>{acc.name}</Text>
                    <Text type="secondary" style={{ fontSize: 12, textTransform: 'capitalize' }}>{acc.type.replace('-', ' ')}</Text>
                  </div>
                </div>
                <Text strong style={{ fontSize: 20, color: acc.balance >= 0 ? '#262626' : '#ff4d4f' }}>
                  IDR {fmt(acc.balance)}
                </Text>
              </Card>
            </Col>
          ))}
        </Row>
      )}

      <Modal
        title={editing ? 'Edit Account' : 'New Account'}
        open={open}
        onOk={onSubmit}
        onCancel={() => setOpen(false)}
        okText={editing ? 'Update' : 'Create'}
      >
        <Form form={form} layout="vertical">
          <Form.Item name="name" label="Account Name" rules={[{ required: true }]}>
            <Input placeholder="e.g. BCA Bank" />
          </Form.Item>
          <Form.Item name="type" label="Type" rules={[{ required: true }]}>
            <Select>
              {ACCOUNT_TYPES.map((t) => <Option key={t.value} value={t.value}>{t.label}</Option>)}
            </Select>
          </Form.Item>
          {!editing && (
            <Form.Item name="balance" label="Initial Balance" initialValue={0}>
              <InputNumber style={{ width: '100%' }} formatter={(v) => `IDR ${v}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')} min={0} />
            </Form.Item>
          )}
          <Form.Item name="currency" label="Currency" initialValue="IDR">
            <Select>
              <Option value="IDR">IDR - Indonesian Rupiah</Option>
              <Option value="USD">USD - US Dollar</Option>
              <Option value="EUR">EUR - Euro</Option>
            </Select>
          </Form.Item>
          <Form.Item name="color" label="Color">
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              {COLORS.map((c) => (
                <div
                  key={c}
                  onClick={() => form.setFieldValue('color', c)}
                  style={{
                    width: 28, height: 28, borderRadius: '50%', background: c, cursor: 'pointer',
                    border: form.getFieldValue('color') === c ? '3px solid #000' : '2px solid transparent',
                  }}
                />
              ))}
            </div>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
