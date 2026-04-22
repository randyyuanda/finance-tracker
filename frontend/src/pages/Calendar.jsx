import { useEffect, useState, useMemo } from 'react';
import { Calendar, Card, Badge, Typography, Row, Col, Statistic, List, Avatar, Tag, Space, Drawer, Empty } from 'antd';
import { ArrowUpOutlined, ArrowDownOutlined, SyncOutlined } from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { fetchTransactions } from '../store/slices/transactionSlice';
import useT from '../i18n/useT';
import dayjs from 'dayjs';

const { Title, Text } = Typography;

export default function TransactionCalendar() {
  const dispatch = useDispatch();
  const t = useT();
  const { list, loading } = useSelector((s) => s.transactions);
  const primaryColor = useSelector((s) => s.settings.primaryColor);
  
  const [selectedDate, setSelectedDate] = useState(dayjs());
  const [drawerVisible, setDrawerVisible] = useState(false);

  useEffect(() => {
    // Fetch a large range of transactions to cover the calendar view
    // For simplicity, we fetch all (with a high limit) or we could fetch by month
    dispatch(fetchTransactions({ limit: 1000 }));
  }, [dispatch]);

  const transactionsByDate = useMemo(() => {
    const map = {};
    list.forEach(tx => {
      const date = dayjs(tx.date).format('YYYY-MM-DD');
      if (!map[date]) map[date] = [];
      map[date].push(tx);
    });
    return map;
  }, [list]);

  const getDayStats = (date) => {
    const dayTransactions = transactionsByDate[date.format('YYYY-MM-DD')] || [];
    const income = dayTransactions.filter(t => t.type === 'income').reduce((sum, t) => sum + t.amount, 0);
    const expense = dayTransactions.filter(t => t.type === 'expense').reduce((sum, t) => sum + t.amount, 0);
    return { income, expense, count: dayTransactions.length };
  };

  const cellRender = (current) => {
    const { income, expense } = getDayStats(current);
    if (income === 0 && expense === 0) return null;

    return (
      <ul className="events" style={{ listStyle: 'none', padding: 0, margin: 0 }}>
        {income > 0 && (
          <li>
            <Badge status="success" text={<Text style={{ fontSize: 10, color: '#52c41a' }}>+{new Intl.NumberFormat('id-ID', { notation: 'compact' }).format(income)}</Text>} />
          </li>
        )}
        {expense > 0 && (
          <li>
            <Badge status="error" text={<Text style={{ fontSize: 10, color: '#ff4d4f' }}>-{new Intl.NumberFormat('id-ID', { notation: 'compact' }).format(expense)}</Text>} />
          </li>
        )}
      </ul>
    );
  };

  const onSelect = (date) => {
    setSelectedDate(date);
    setDrawerVisible(true);
  };

  const fmt = (n) => new Intl.NumberFormat('id-ID').format(n);

  const selectedDayTransactions = transactionsByDate[selectedDate.format('YYYY-MM-DD')] || [];
  const selectedDayStats = getDayStats(selectedDate);

  return (
    <div className="page-container">
      <Row gutter={[16, 16]} align="middle" style={{ marginBottom: 24 }}>
        <Col flex="auto">
          <Title level={3} style={{ margin: 0 }}>{t('nav_calendar') || 'Transaction Calendar'}</Title>
          <Text type="secondary">View your daily financial activity</Text>
        </Col>
      </Row>

      <Card className="stat-card" style={{ padding: 0, overflow: 'hidden' }}>
        <Calendar 
          onSelect={onSelect} 
          cellRender={cellRender}
          style={{ padding: 12 }}
        />
      </Card>

      <Drawer
        title={
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '90%' }}>
            <span>{selectedDate.format('dddd, D MMMM YYYY')}</span>
            <Tag color={primaryColor}>{selectedDayTransactions.length} Transactions</Tag>
          </div>
        }
        placement="right"
        onClose={() => setDrawerVisible(false)}
        open={drawerVisible}
        width={window.innerWidth < 768 ? '100%' : 450}
      >
        <Row gutter={16} style={{ marginBottom: 24 }}>
          <Col span={12}>
            <Card size="small" style={{ textAlign: 'center', background: '#f6ffed', border: '1px solid #b7eb8f' }}>
              <Statistic 
                title="Income" 
                value={selectedDayStats.income} 
                prefix={<ArrowUpOutlined />} 
                valueStyle={{ color: '#52c41a', fontSize: 18 }}
                formatter={fmt}
              />
            </Card>
          </Col>
          <Col span={12}>
            <Card size="small" style={{ textAlign: 'center', background: '#fff1f0', border: '1px solid #ffa39e' }}>
              <Statistic 
                title="Expenses" 
                value={selectedDayStats.expense} 
                prefix={<ArrowDownOutlined />} 
                valueStyle={{ color: '#ff4d4f', fontSize: 18 }}
                formatter={fmt}
              />
            </Card>
          </Col>
        </Row>

        {selectedDayTransactions.length === 0 ? (
          <Empty description="No transactions on this day" style={{ marginTop: 60 }} />
        ) : (
          <List
            itemLayout="horizontal"
            dataSource={selectedDayTransactions}
            renderItem={(tx) => (
              <List.Item>
                <List.Item.Meta
                  avatar={
                    <Avatar 
                      style={{ backgroundColor: tx.categoryId?.color + '20', color: tx.categoryId?.color }}
                      icon={<SyncOutlined />}
                    />
                  }
                  title={
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <Text strong>{tx.categoryId?.name}</Text>
                      <Text strong style={{ color: tx.type === 'income' ? '#52c41a' : '#ff4d4f' }}>
                        {tx.type === 'income' ? '+' : '-'} IDR {fmt(tx.amount)}
                      </Text>
                    </div>
                  }
                  description={
                    <Space direction="vertical" size={0}>
                      <Text type="secondary" style={{ fontSize: 12 }}>{tx.accountId?.name} • {tx.note || 'No note'}</Text>
                    </Space>
                  }
                />
              </List.Item>
            )}
          />
        )}
      </Drawer>
    </div>
  );
}
