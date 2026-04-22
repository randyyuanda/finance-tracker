import { useEffect, useState } from 'react';
import {
  Tabs, Row, Col, Card, Button, Modal, Form, Input, Select,
  Typography, Avatar, Popconfirm, message, Tag, Empty, Space
} from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, TagOutlined } from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { fetchCategories, createCategory, updateCategory, deleteCategory } from '../store/slices/categorySlice';
import useT from '../i18n/useT';

const { Title, Text } = Typography;

const COLORS = [
  '#1890ff', '#52c41a', '#fa541c', '#faad14', '#722ed1',
  '#eb2f96', '#13c2c2', '#ff7a45', '#bae637', '#36cfc9',
];

export default function Categories() {
  const t = useT();
  const dispatch = useDispatch();
  const { list: categories, loading } = useSelector((s) => s.categories);
  const primaryColor = useSelector((s) => s.settings.primaryColor);
  
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [activeTab, setActiveTab] = useState('expense');
  const [form] = Form.useForm();

  useEffect(() => { dispatch(fetchCategories()); }, [dispatch]);

  const filtered = categories.filter((c) => c.type === activeTab);

  const openCreate = () => {
    setEditing(null);
    form.resetFields();
    form.setFieldsValue({ type: activeTab, color: primaryColor });
    setOpen(true);
  };

  const openEdit = (cat) => {
    setEditing(cat);
    form.setFieldsValue(cat);
    setOpen(true);
  };

  const onSubmit = async () => {
    try {
      const values = await form.validateFields();
      if (editing) {
        await dispatch(updateCategory({ id: editing._id, data: values })).unwrap();
        message.success(t('updateSuccess'));
      } else {
        await dispatch(createCategory(values)).unwrap();
        message.success(t('createSuccess'));
      }
      setOpen(false);
    } catch (err) {
      if (err?.message) message.error(err.message);
    }
  };

  const onDelete = async (id) => {
    try {
      await dispatch(deleteCategory(id)).unwrap();
      message.success(t('deleteSuccess'));
    } catch (err) {
      message.error(err?.message || 'Delete failed');
    }
  };

  const renderList = () => {
    if (loading) return <div style={{ padding: 40, textAlign: 'center' }}><Space size="middle"><Typography.Text type="secondary">{t('saving')}</Typography.Text></Space></div>;
    if (!filtered.length) return (
      <Empty style={{ marginTop: 60 }} description={t('noData')} extra={<Button type="primary" onClick={openCreate} style={{ borderRadius: 10 }}>{t('addAccount')}</Button>} />
    );
    return (
      <Row gutter={[16, 16]}>
        {filtered.map((cat) => (
          <Col xs={12} sm={8} md={6} lg={4} key={cat._id}>
            <Card
              className="stat-card"
              size="small"
              style={{ textAlign: 'center', borderTop: `3px solid ${cat.color}`, padding: '12px 0' }}
              actions={[
                <EditOutlined key="edit" onClick={() => openEdit(cat)} />,
                !cat.isDefault && (
                  <Popconfirm key="del" title={t('deleteAccountConfirm')} onConfirm={() => onDelete(cat._id)} okText={t('themeLight') === 'Light' ? 'Yes' : 'Ya'}>
                    <DeleteOutlined style={{ color: '#ff4d4f' }} />
                  </Popconfirm>
                ),
              ].filter(Boolean)}
            >
              <Avatar size={44} style={{ background: cat.color + '15', color: cat.color, marginBottom: 12, border: `1px solid ${cat.color}25` }} icon={<TagOutlined />} />
              <div>
                <Text strong style={{ display: 'block', fontSize: 14 }}>{cat.name}</Text>
                {cat.isDefault && <Tag style={{ marginTop: 8, fontSize: 10, borderRadius: 4 }}>Default</Tag>}
              </div>
            </Card>
          </Col>
        ))}
      </Row>
    );
  };

  return (
    <div className="page-container">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <Title level={4} style={{ margin: 0 }}>{t('nav_categories')}</Title>
        <Button type="primary" icon={<PlusOutlined />} onClick={openCreate} size="large" style={{ borderRadius: 12 }}>
          {t('addAccount')}
        </Button>
      </div>

      <Tabs
        activeKey={activeTab}
        onChange={setActiveTab}
        type="card"
        items={[
          { key: 'expense', label: `${t('expenseThisMonth')} (${categories.filter((c) => c.type === 'expense').length})` },
          { key: 'income', label: `${t('incomeThisMonth')} (${categories.filter((c) => c.type === 'income').length})` },
        ]}
      />

      <div style={{ marginTop: 24 }}>{renderList()}</div>

      <Modal
        title={<Text strong style={{ fontSize: 18 }}>{editing ? t('editAccount') : t('newAccount')}</Text>}
        open={open}
        onOk={onSubmit}
        onCancel={() => setOpen(false)}
        okText={editing ? t('saveProfile') : t('nav_accounts').slice(0,-1)}
        okButtonProps={{ size: 'large', style: { borderRadius: 10 } }}
        cancelButtonProps={{ size: 'large', style: { borderRadius: 10 } }}
      >
        <Form form={form} layout="vertical" style={{ marginTop: 16 }}>
          <Form.Item name="name" label={t('accountName')} rules={[{ required: true }]}>
            <Input size="large" placeholder="e.g. Food & Drink" />
          </Form.Item>
          <Form.Item name="type" label={t('type')} rules={[{ required: true }]}>
            <Select size="large">
              <Select.Option value="income">{t('incomeOnly')}</Select.Option>
              <Select.Option value="expense">{t('expenseOnly')}</Select.Option>
            </Select>
          </Form.Item>
          <Form.Item name="color" label={t('color')}>
            <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', padding: '8px 0' }}>
              {COLORS.map((c) => (
                <div
                  key={c}
                  onClick={() => form.setFieldValue('color', c)}
                  style={{
                    width: 32, height: 32, borderRadius: 10, background: c, cursor: 'pointer',
                    border: form.getFieldValue('color') === c ? '3px solid #000' : '2px solid rgba(0,0,0,0.05)',
                    transition: 'all 0.2s',
                    transform: form.getFieldValue('color') === c ? 'scale(1.1)' : 'scale(1)',
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

