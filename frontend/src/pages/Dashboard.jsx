import { useEffect } from 'react';
import { Row, Col, Card, Statistic, Typography, List, Avatar, Tag, Skeleton, Empty } from 'antd';
import {
  ArrowUpOutlined,
  ArrowDownOutlined,
  WalletOutlined,
  BankOutlined,
  MobileOutlined,
} from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { fetchDashboard } from '../store/slices/dashboardSlice';
import dayjs from 'dayjs';

const { Title, Text } = Typography;

const ACCOUNT_ICONS = { cash: WalletOutlined, bank: BankOutlined, 'e-wallet': MobileOutlined, savings: BankOutlined, 'credit-card': BankOutlined };

const fmt = (n) => new Intl.NumberFormat('id-ID').format(n);

export default function Dashboard() {
  const dispatch = useDispatch();
  const { accounts, totalBalance, thisMonth, lastMonth, recentTransactions, loading } = useSelector(
    (s) => s.dashboard
  );

  useEffect(() => { dispatch(fetchDashboard()); }, [dispatch]);

  const expenseDiff = thisMonth.expense - lastMonth.expense;

  return (
    <div className="page-container">
      <Title level={4} style={{ marginBottom: 16 }}>Dashboard</Title>

      {/* Total Balance */}
      <Card className="stat-card" style={{ marginBottom: 16, background: 'linear-gradient(135deg, #1890ff, #096dd9)', border: 'none' }}>
        <Text style={{ color: 'rgba(255,255,255,0.8)', display: 'block', marginBottom: 4 }}>Total Balance</Text>
        {loading ? <Skeleton.Input active size="large" /> : (
          <Title level={2} style={{ color: '#fff', margin: 0 }}>IDR {fmt(totalBalance)}</Title>
        )}
      </Card>

      {/* This month / Last month */}
      <Row gutter={[12, 12]} style={{ marginBottom: 16 }}>
        <Col xs={12} sm={6}>
          <Card className="stat-card" size="small">
            <Statistic
              title="Income (this month)"
              value={thisMonth.income}
              prefix="IDR"
              formatter={(v) => fmt(v)}
              valueStyle={{ color: '#52c41a', fontSize: 18 }}
              loading={loading}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card className="stat-card" size="small">
            <Statistic
              title="Expenses (this month)"
              value={thisMonth.expense}
              prefix="IDR"
              formatter={(v) => fmt(v)}
              valueStyle={{ color: '#ff4d4f', fontSize: 18 }}
              loading={loading}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card className="stat-card" size="small">
            <Statistic
              title="Savings (this month)"
              value={thisMonth.savings}
              prefix="IDR"
              formatter={(v) => fmt(v)}
              valueStyle={{ color: thisMonth.savings >= 0 ? '#52c41a' : '#ff4d4f', fontSize: 18 }}
              loading={loading}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card className="stat-card" size="small">
            <Statistic
              title="vs Last month"
              value={Math.abs(expenseDiff)}
              prefix="IDR"
              formatter={(v) => fmt(v)}
              valueStyle={{ color: expenseDiff > 0 ? '#ff4d4f' : '#52c41a', fontSize: 18 }}
              suffix={expenseDiff > 0 ? <ArrowUpOutlined /> : <ArrowDownOutlined />}
              loading={loading}
            />
            <Text type="secondary" style={{ fontSize: 11 }}>expense change</Text>
          </Card>
        </Col>
      </Row>

      <Row gutter={[12, 12]}>
        {/* Account Cards */}
        <Col xs={24} lg={10}>
          <Card title="My Accounts" className="stat-card" size="small">
            {loading ? <Skeleton active /> : accounts.length === 0 ? <Empty description="No accounts" /> : (
              <Row gutter={[8, 8]}>
                {accounts.map((acc) => {
                  const Icon = ACCOUNT_ICONS[acc.type] || WalletOutlined;
                  return (
                    <Col xs={24} sm={12} key={acc._id}>
                      <div
                        style={{
                          background: acc.color + '18',
                          border: `1px solid ${acc.color}40`,
                          borderRadius: 12,
                          padding: '12px 14px',
                        }}
                      >
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                          <Avatar size={28} style={{ background: acc.color }} icon={<Icon />} />
                          <Text strong style={{ fontSize: 13 }}>{acc.name}</Text>
                        </div>
                        <Text strong style={{ color: acc.color, fontSize: 15 }}>IDR {fmt(acc.balance)}</Text>
                      </div>
                    </Col>
                  );
                })}
              </Row>
            )}
          </Card>
        </Col>

        {/* Recent Transactions */}
        <Col xs={24} lg={14}>
          <Card title="Recent Transactions" className="stat-card" size="small">
            {loading ? <Skeleton active /> : recentTransactions.length === 0 ? <Empty description="No transactions yet" /> : (
              <List
                dataSource={recentTransactions}
                renderItem={(tx) => (
                  <List.Item style={{ padding: '8px 0' }}>
                    <List.Item.Meta
                      avatar={
                        <Avatar
                          size={36}
                          style={{ background: tx.categoryId?.color || '#ccc', fontSize: 14 }}
                        >
                          {tx.categoryId?.name?.[0] || '?'}
                        </Avatar>
                      }
                      title={
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <Text style={{ fontSize: 14 }}>{tx.categoryId?.name}</Text>
                          <Text
                            strong
                            style={{ color: tx.type === 'income' ? '#52c41a' : '#ff4d4f', fontSize: 14 }}
                          >
                            {tx.type === 'income' ? '+' : '-'}IDR {fmt(tx.amount)}
                          </Text>
                        </div>
                      }
                      description={
                        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                          <Tag color={tx.accountId?.color} style={{ margin: 0, fontSize: 11 }}>
                            {tx.accountId?.name}
                          </Tag>
                          <Text type="secondary" style={{ fontSize: 11 }}>
                            {dayjs(tx.date).format('DD MMM YYYY')}
                          </Text>
                          {tx.note && <Text type="secondary" style={{ fontSize: 11 }}>· {tx.note}</Text>}
                        </div>
                      }
                    />
                  </List.Item>
                )}
              />
            )}
          </Card>
        </Col>
      </Row>
    </div>
  );
}
