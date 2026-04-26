import { useEffect, useState, useCallback } from 'react';
import {
  Table, Button, Modal, Form, Input, Select, InputNumber, DatePicker,
  Typography, Tag, Space, Popconfirm, message, Row, Col,
} from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, FilterOutlined, SwapOutlined } from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { fetchTransactions, createTransaction, updateTransaction, deleteTransaction } from '../store/slices/transactionSlice';
import { fetchAccounts } from '../store/slices/accountSlice';
import { fetchCategories } from '../store/slices/categorySlice';
import { fetchDashboard } from '../store/slices/dashboardSlice';
import useT from '../i18n/useT';
import dayjs from 'dayjs';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

const fmt = (n) => new Intl.NumberFormat('id-ID').format(n);

export default function Transactions() {
  const t = useT();
  const dispatch = useDispatch();
  const { list, total, loading } = useSelector((s) => s.transactions);
  const { list: accounts } = useSelector((s) => s.accounts);
  const { list: categories } = useSelector((s) => s.categories);

  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form] = Form.useForm();
  const [filters, setFilters] = useState({ page: 1, limit: 15 });
  const [txType, setTxType] = useState('expense');

  const load = useCallback((f) => dispatch(fetchTransactions(f)), [dispatch]);

  useEffect(() => {
    dispatch(fetchAccounts());
    dispatch(fetchCategories());
    load(filters);
  }, [dispatch]);

  const handleFilter = (changed) => {
    const next = { ...filters, ...changed, page: 1 };
    setFilters(next);
    load(next);
  };

  const openCreate = () => {
    setEditing(null);
    setTxType('expense');
    form.resetFields();
    form.setFieldsValue({ type: 'expense', date: dayjs() });
    setOpen(true);
  };

  const openEdit = (tx) => {
    setEditing(tx);
    setTxType(tx.type);
    form.setFieldsValue({
      ...tx,
      accountId: tx.accountId?._id,
      toAccountId: tx.toAccountId?._id,
      categoryId: tx.categoryId?._id,
      date: dayjs(tx.date),
    });
    setOpen(true);
  };

  const onSubmit = async () => {
    try {
      const values = await form.validateFields();
      const payload = { ...values, date: values.date.toISOString() };
      if (payload.type !== 'transfer') delete payload.toAccountId;
      if (payload.type === 'transfer') delete payload.categoryId;
      if (editing) {
        await dispatch(updateTransaction({ id: editing._id, data: payload })).unwrap();
        message.success(t('transactionUpdated'));
      } else {
        await dispatch(createTransaction(payload)).unwrap();
        message.success(t('transactionAdded'));
      }
      setOpen(false);
      load(filters);
      dispatch(fetchDashboard());
      dispatch(fetchAccounts());
    } catch (err) {
      if (err?.message) message.error(err.message);
    }
  };

  const onDelete = async (id) => {
    try {
      await dispatch(deleteTransaction(id)).unwrap();
      message.success(t('transactionDeleted'));
      load(filters);
      dispatch(fetchDashboard());
      dispatch(fetchAccounts());
    } catch (err) {
      message.error(err?.message || 'Delete failed');
    }
  };

  const filteredCategories = categories.filter((c) => c.type === txType);

  const columns = [
    {
      title: t('date'),
      dataIndex: 'date',
      key: 'date',
      width: 110,
      render: (d) => dayjs(d).format('DD/MM/YYYY'),
    },
    {
      title: t('nav_categories'),
      dataIndex: 'categoryId',
      key: 'category',
      render: (cat, row) => {
        if (row.type === 'transfer') {
          const from = row.accountId?.name || '?';
          const to = row.toAccountId?.name || '?';
          return <Text type="secondary" style={{ fontSize: 12 }}><SwapOutlined style={{ marginRight: 4 }} />{from} → {to}</Text>;
        }
        return cat ? <Tag color={cat.color} style={{ margin: 0 }}>{cat.name}</Tag> : '-';
      },
    },
    {
      title: t('account'),
      dataIndex: 'accountId',
      key: 'account',
      responsive: ['sm'],
      render: (acc, row) => {
        if (row.type === 'transfer') return null;
        return acc ? <Tag color={acc.color} style={{ margin: 0 }}>{acc.name}</Tag> : '-';
      },
    },
    {
      title: t('type'),
      dataIndex: 'type',
      key: 'type',
      width: 90,
      render: (v) => {
        if (v === 'transfer') return <Tag color="blue">Transfer</Tag>;
        return <Tag color={v === 'income' ? 'green' : 'red'}>{v === 'income' ? t('income') : t('expense')}</Tag>;
      },
    },
    {
      title: t('amount'),
      dataIndex: 'amount',
      key: 'amount',
      align: 'right',
      width: 140,
      render: (a, r) => {
        const color = r.type === 'income' ? '#52c41a' : r.type === 'transfer' ? '#1890ff' : '#ff4d4f';
        const prefix = r.type === 'income' ? '+' : r.type === 'transfer' ? '' : '-';
        return <Text style={{ color, fontWeight: 600 }}>{prefix}IDR {fmt(a)}</Text>;
      },
    },
    {
      title: t('note'),
      dataIndex: 'note',
      key: 'note',
      responsive: ['md'],
      render: (n) => n || <Text type="secondary">-</Text>,
    },
    {
      title: '',
      key: 'actions',
      width: 80,
      render: (_, row) => (
        <Space size={4}>
          <Button size="small" type="text" icon={<EditOutlined />} onClick={() => openEdit(row)} />
          <Popconfirm title={t('deleteConfirm')} onConfirm={() => onDelete(row._id)} okText={t('yes')}>
            <Button size="small" type="text" danger icon={<DeleteOutlined />} />
          </Popconfirm>
        </Space>
      ),
    },
  ];

  return (
    <div className="page-container">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <Title level={4} style={{ margin: 0 }}>{t('transactionsTitle')}</Title>
        <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
          {t('addTransaction')}
        </Button>
      </div>

      <Row gutter={[8, 8]} style={{ marginBottom: 12 }}>
        <Col xs={12} sm={6}>
          <Select
            allowClear
            placeholder={<><FilterOutlined /> {t('filterByType')}</>}
            style={{ width: '100%' }}
            onChange={(v) => handleFilter({ type: v })}
          >
            <Select.Option value="income">{t('income')}</Select.Option>
            <Select.Option value="expense">{t('expense')}</Select.Option>
            <Select.Option value="transfer">Transfer</Select.Option>
          </Select>
        </Col>
        <Col xs={12} sm={6}>
          <Select
            allowClear
            placeholder={t('filterByAccount')}
            style={{ width: '100%' }}
            onChange={(v) => handleFilter({ accountId: v })}
          >
            {accounts.map((a) => <Select.Option key={a._id} value={a._id}>{a.name}</Select.Option>)}
          </Select>
        </Col>
        <Col xs={12} sm={6}>
          <Select
            allowClear
            placeholder={t('filterByCategory')}
            style={{ width: '100%' }}
            onChange={(v) => handleFilter({ categoryId: v })}
          >
            {categories.map((c) => <Select.Option key={c._id} value={c._id}>{c.name}</Select.Option>)}
          </Select>
        </Col>
        <Col xs={12} sm={6}>
          <RangePicker
            style={{ width: '100%' }}
            onChange={(dates) => handleFilter({
              startDate: dates?.[0]?.startOf('day').toISOString(),
              endDate: dates?.[1]?.endOf('day').toISOString(),
            })}
          />
        </Col>
      </Row>

      <Table
        columns={columns}
        dataSource={list}
        rowKey="_id"
        loading={loading}
        pagination={{
          total,
          pageSize: filters.limit,
          current: filters.page,
          showTotal: (n) => `${n} ${t('nav_transactions').toLowerCase()}`,
          onChange: (page) => {
            const next = { ...filters, page };
            setFilters(next);
            load(next);
          },
        }}
        size="small"
        scroll={{ x: 600 }}
      />

      <Modal
        title={editing ? t('editTransaction') : t('newTransaction')}
        open={open}
        onOk={onSubmit}
        onCancel={() => setOpen(false)}
        okText={editing ? t('update') : t('add')}
        destroyOnClose
      >
        <Form form={form} layout="vertical">
          <Row gutter={12}>
            <Col span={12}>
              <Form.Item name="type" label={t('type')} rules={[{ required: true }]}>
                <Select onChange={(v) => { setTxType(v); form.setFieldValue('categoryId', undefined); form.setFieldValue('toAccountId', undefined); }}>
                  <Select.Option value="income">{t('income')}</Select.Option>
                  <Select.Option value="expense">{t('expense')}</Select.Option>
                  <Select.Option value="transfer">Transfer</Select.Option>
                </Select>
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="date" label={t('date')} rules={[{ required: true }]}>
                <DatePicker style={{ width: '100%' }} />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="accountId" label={txType === 'transfer' ? 'From Account' : t('account')} rules={[{ required: true }]}>
            <Select placeholder={t('selectAccount')}>
              {accounts.map((a) => <Select.Option key={a._id} value={a._id}>{a.name}</Select.Option>)}
            </Select>
          </Form.Item>
          {txType === 'transfer' ? (
            <Form.Item name="toAccountId" label="To Account" rules={[{ required: true }]}>
              <Select placeholder="Select destination account">
                {accounts.map((a) => <Select.Option key={a._id} value={a._id}>{a.name}</Select.Option>)}
              </Select>
            </Form.Item>
          ) : (
            <Form.Item name="categoryId" label={t('nav_categories')} rules={[{ required: true }]}>
              <Select placeholder={t('selectCategory')}>
                {filteredCategories.map((c) => <Select.Option key={c._id} value={c._id}>{c.name}</Select.Option>)}
              </Select>
            </Form.Item>
          )}
          <Form.Item name="amount" label={t('amountLabel')} rules={[{ required: true }]}>
            <InputNumber
              style={{ width: '100%' }}
              min={1}
              formatter={(v) => `${v}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')}
              parser={(v) => Number((v || '').replace(/[^\d]/g, '')) || 0}
              placeholder="0"
            />
          </Form.Item>
          <Form.Item name="note" label={t('note')}>
            <Input placeholder={t('note')} />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
