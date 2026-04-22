import { useEffect, useState } from 'react';
import {
  Row, Col, Card, Button, Modal, Form, Input, Select, InputNumber,
  Typography, Avatar, Popconfirm, message, Skeleton, Empty, Space, Tag
} from 'antd';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, WalletOutlined,
  BankOutlined, CreditCardOutlined, MobileOutlined, SafetyOutlined,
  DollarOutlined, PayCircleOutlined
} from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { fetchAccounts, createAccount, updateAccount, deleteAccount } from '../store/slices/accountSlice';
import useT from '../i18n/useT';

const { Title, Text } = Typography;
const { Option } = Select;

const COLORS = ['#1890ff', '#52c41a', '#fa541c', '#faad14', '#722ed1', '#eb2f96', '#13c2c2', '#00aa5b', '#4c3494'];

const ACCOUNT_ICONS = {
  wallet: WalletOutlined,
  bank: BankOutlined,
  card: CreditCardOutlined,
  mobile: MobileOutlined,
  savings: SafetyOutlined,
  dollar: DollarOutlined,
  pay: PayCircleOutlined,
};

const ACCOUNT_TYPES = [
  { value: 'cash', label: 'Cash' },
  { value: 'bank', label: 'Bank' },
  { value: 'e-wallet', label: 'E-Wallet' },
  { value: 'credit-card', label: 'Credit Card' },
  { value: 'savings', label: 'Savings' },
];

const fmt = (n) => new Intl.NumberFormat('id-ID').format(n);

export default function Accounts() {
  const t = useT();
  const dispatch = useDispatch();
  const { list: accounts, loading } = useSelector((s) => s.accounts);
  const primaryColor = useSelector((s) => s.settings.primaryColor);
  
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form] = Form.useForm();
  const selectedColor = Form.useWatch('color', form);

  useEffect(() => { dispatch(fetchAccounts()); }, [dispatch]);

  const openCreate = () => {
    setEditing(null);
    form.resetFields();
    form.setFieldsValue({ color: primaryColor, type: 'cash', icon: 'wallet', balance: 0, currency: 'IDR' });
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
        message.success(t('updateSuccess'));
      } else {
        await dispatch(createAccount(values)).unwrap();
        message.success(t('createSuccess'));
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
      message.success(t('deleteSuccess'));
    } catch (err) {
      message.error(err?.message || 'Delete failed');
    }
  };

  const totalBalance = accounts.reduce((s, a) => s + a.balance, 0);

  return (
    <div className="page-container">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <Title level={4} style={{ margin: 0 }}>{t('nav_accounts')}</Title>
          <Text type="secondary">{t('totalBalance')}: <Text strong style={{ color: primaryColor }}>IDR {fmt(totalBalance)}</Text></Text>
        </div>
        <Button type="primary" icon={<PlusOutlined />} onClick={openCreate} size="large" style={{ borderRadius: 12 }}>
          {t('addAccount')}
        </Button>
      </div>

      {loading ? (
        <Row gutter={[16, 16]}>{[1,2,3,4].map((i) => <Col xs={24} sm={12} lg={6} key={i}><Skeleton active /></Col>)}</Row>
      ) : accounts.length === 0 ? (
        <Empty description={t('noAccountsYet')} extra={<Button type="primary" onClick={openCreate}>{t('addFirstAccount')}</Button>} />
      ) : (
        <Row gutter={[16, 16]}>
          {accounts.map((acc) => {
            const Icon = ACCOUNT_ICONS[acc.icon] || WalletOutlined;
            return (
              <Col xs={24} sm={12} lg={6} key={acc._id}>
                <Card
                  className="stat-card"
                  style={{ borderTop: `4px solid ${acc.color}`, height: '100%' }}
                  actions={[
                    <EditOutlined key="edit" onClick={() => openEdit(acc)} />,
                    <Popconfirm key="del" title={t('deleteAccountConfirm')} onConfirm={() => onDelete(acc._id)} okText={t('themeLight') === 'Light' ? 'Yes' : 'Ya'}>
                      <DeleteOutlined style={{ color: '#ff4d4f' }} />
                    </Popconfirm>,
                  ]}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
                    <Avatar size={48} style={{ background: acc.color + '20', color: acc.color, border: `1px solid ${acc.color}40` }} icon={<Icon />} />
                    <div>
                      <Text strong style={{ display: 'block', fontSize: 15 }}>{acc.name}</Text>
                      <Tag color={acc.color} style={{ margin: 0, fontSize: 10, textTransform: 'uppercase', borderRadius: 4 }}>
                        {acc.type.replace('-', ' ')}
                      </Tag>
                    </div>
                  </div>
                  <div style={{ padding: '4px 0' }}>
                    <Text type="secondary" style={{ fontSize: 12, display: 'block', marginBottom: 2 }}>{t('balance')}</Text>
                    <Text strong style={{ fontSize: 22, color: acc.balance >= 0 ? 'inherit' : '#ff4d4f', letterSpacing: -0.5 }}>
                      IDR {fmt(acc.balance)}
                    </Text>
                  </div>
                </Card>
              </Col>
            );
          })}
        </Row>
      )}

      <Modal
        title={<Text strong style={{ fontSize: 18 }}>{editing ? t('editAccount') : t('newAccount')}</Text>}
        open={open}
        onOk={onSubmit}
        onCancel={() => setOpen(false)}
        okText={editing ? t('saveProfile') : t('nav_accounts').slice(0,-1)} // Hacky but works for now or just t('createSuccess') minus success
        okButtonProps={{ size: 'large', style: { borderRadius: 10 } }}
        cancelButtonProps={{ size: 'large', style: { borderRadius: 10 } }}
        width={480}
      >
        <Form form={form} layout="vertical" style={{ marginTop: 16 }}>
          <Form.Item name="name" label={t('accountName')} rules={[{ required: true }]}>
            <Input size="large" placeholder="e.g. BCA Bank" />
          </Form.Item>
          
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="type" label={t('type')} rules={[{ required: true }]}>
                <Select size="large">
                  {ACCOUNT_TYPES.map((t) => <Option key={t.value} value={t.value}>{t.label}</Option>)}
                </Select>
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="icon" label={t('icon')} rules={[{ required: true }]}>
                <Select size="large" optionLabelProp="label">
                  {Object.entries(ACCOUNT_ICONS).map(([k, IconComp]) => (
                    <Option key={k} value={k} label={k.charAt(0).toUpperCase() + k.slice(1)}>
                      <Space><IconComp /> {k.charAt(0).toUpperCase() + k.slice(1)}</Space>
                    </Option>
                  ))}
                </Select>
              </Form.Item>
            </Col>
          </Row>

          {!editing && (
            <Form.Item name="balance" label={t('initialBalance')} initialValue={0}>
              <InputNumber
                size="large"
                style={{ width: '100%' }}
                formatter={(v) => `${v}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')}
                parser={(v) => Number((v || '').replace(/[^\d]/g, '')) || 0}
                addonBefore="IDR"
                min={0}
              />
            </Form.Item>
          )}

          <Form.Item name="color" label={t('color')}>
            <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', padding: '8px 0' }}>
              {COLORS.map((c) => (
                <div
                  key={c}
                  onClick={() => form.setFieldValue('color', c)}
                  style={{
                    width: 32, height: 32, borderRadius: 10, background: c, cursor: 'pointer',
                    border: selectedColor === c ? '3px solid #000' : '2px solid rgba(0,0,0,0.05)',
                    transition: 'all 0.2s',
                    transform: selectedColor === c ? 'scale(1.1)' : 'scale(1)',
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

