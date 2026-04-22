import { useEffect, useState } from 'react';
import {
  Tabs, Row, Col, Card, Button, Modal, Form, Input, Select,
  Typography, Avatar, Popconfirm, message, Tag, Empty,
} from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, TagOutlined } from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { fetchCategories, createCategory, updateCategory, deleteCategory } from '../store/slices/categorySlice';

const { Title, Text } = Typography;

const COLORS = [
  '#1890ff', '#52c41a', '#fa541c', '#faad14', '#722ed1',
  '#eb2f96', '#13c2c2', '#ff7a45', '#bae637', '#36cfc9',
];

export default function Categories() {
  const dispatch = useDispatch();
  const { list: categories, loading } = useSelector((s) => s.categories);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [activeTab, setActiveTab] = useState('expense');
  const [form] = Form.useForm();

  useEffect(() => { dispatch(fetchCategories()); }, [dispatch]);

  const filtered = categories.filter((c) => c.type === activeTab);

  const openCreate = () => {
    setEditing(null);
    form.resetFields();
    form.setFieldsValue({ type: activeTab, color: '#1890ff' });
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
        message.success('Category updated');
      } else {
        await dispatch(createCategory(values)).unwrap();
        message.success('Category created');
      }
      setOpen(false);
    } catch (err) {
      if (err?.message) message.error(err.message);
    }
  };

  const onDelete = async (id) => {
    try {
      await dispatch(deleteCategory(id)).unwrap();
      message.success('Category deleted');
    } catch (err) {
      message.error(err?.message || 'Delete failed');
    }
  };

  const renderList = () => {
    if (loading) return <div style={{ padding: 20, textAlign: 'center' }}>Loading...</div>;
    if (!filtered.length) return (
      <Empty description={`No ${activeTab} categories`} extra={<Button type="primary" onClick={openCreate}>Add category</Button>} />
    );
    return (
      <Row gutter={[12, 12]}>
        {filtered.map((cat) => (
          <Col xs={12} sm={8} md={6} lg={4} key={cat._id}>
            <Card
              size="small"
              style={{ textAlign: 'center', borderTop: `3px solid ${cat.color}` }}
              actions={[
                <EditOutlined key="edit" onClick={() => openEdit(cat)} />,
                !cat.isDefault && (
                  <Popconfirm key="del" title="Delete category?" onConfirm={() => onDelete(cat._id)} okText="Yes">
                    <DeleteOutlined style={{ color: '#ff4d4f' }} />
                  </Popconfirm>
                ),
              ].filter(Boolean)}
            >
              <Avatar size={40} style={{ background: cat.color, marginBottom: 8 }} icon={<TagOutlined />} />
              <div>
                <Text strong style={{ display: 'block', fontSize: 13 }}>{cat.name}</Text>
                {cat.isDefault && <Tag style={{ marginTop: 4, fontSize: 10 }}>Default</Tag>}
              </div>
            </Card>
          </Col>
        ))}
      </Row>
    );
  };

  return (
    <div className="page-container">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <Title level={4} style={{ margin: 0 }}>Categories</Title>
        <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>Add Category</Button>
      </div>

      <Tabs
        activeKey={activeTab}
        onChange={setActiveTab}
        items={[
          { key: 'expense', label: `Expense (${categories.filter((c) => c.type === 'expense').length})` },
          { key: 'income', label: `Income (${categories.filter((c) => c.type === 'income').length})` },
        ]}
      />

      <div style={{ marginTop: 16 }}>{renderList()}</div>

      <Modal
        title={editing ? 'Edit Category' : 'New Category'}
        open={open}
        onOk={onSubmit}
        onCancel={() => setOpen(false)}
        okText={editing ? 'Update' : 'Create'}
      >
        <Form form={form} layout="vertical">
          <Form.Item name="name" label="Category Name" rules={[{ required: true }]}>
            <Input placeholder="e.g. Food & Drink" />
          </Form.Item>
          <Form.Item name="type" label="Type" rules={[{ required: true }]}>
            <Select>
              <Select.Option value="income">Income</Select.Option>
              <Select.Option value="expense">Expense</Select.Option>
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
