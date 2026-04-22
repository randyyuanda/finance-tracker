import { useEffect } from 'react';
import { Row, Col, Card, Statistic, Typography, List, Avatar, Tag, Skeleton, Empty } from 'antd';
import { ArrowUpOutlined, ArrowDownOutlined, WalletOutlined, BankOutlined, MobileOutlined } from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { fetchDashboard, fetchBalanceHistory } from '../store/slices/dashboardSlice';
import useT from '../i18n/useT';
import dayjs from 'dayjs';

const { Title, Text } = Typography;
const ACCOUNT_ICONS = { cash: WalletOutlined, bank: BankOutlined, 'e-wallet': MobileOutlined, savings: BankOutlined, 'credit-card': BankOutlined };
const fmt = (n) => new Intl.NumberFormat('id-ID').format(Math.round(n));
const fmtCompact = (n) => new Intl.NumberFormat('id-ID', { notation: 'compact', maximumFractionDigits: 1 }).format(n);

function TrendBadge({ curr, prev, positiveIsGood, t }) {
  if (prev === 0 && curr === 0) return null;
  const diff = curr - prev;
  const pct = prev && prev !== 0 ? ((diff / Math.abs(prev)) * 100).toFixed(1) : null;
  const isUp = diff > 0;
  const isGood = positiveIsGood ? isUp : !isUp;
  const color = isGood ? '#52c41a' : '#ff4d4f';
  
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 4, background: color + '15', padding: '2px 8px', borderRadius: 10, width: 'fit-content' }}>
      {isUp ? <ArrowUpOutlined style={{ color, fontSize: 10 }} /> : <ArrowDownOutlined style={{ color, fontSize: 10 }} />}
      <Text style={{ fontSize: 11, color, fontWeight: 600 }}>
        {pct ? `${isUp ? '+' : ''}${pct}%` : (diff > 0 ? '+' : '')}
      </Text>
      <Text style={{ fontSize: 10, color, opacity: 0.8 }}>
        {t('vsLastMonth')}
      </Text>
    </div>
  );
}

export default function Dashboard() {
  const dispatch = useDispatch();
  const t = useT();
  const { accounts, totalBalance, thisMonth, lastMonth, recentTransactions, balanceHistory, loading, historyLoading } =
    useSelector((s) => s.dashboard);
  const primaryColor = useSelector((s) => s.settings.primaryColor);

  useEffect(() => {
    dispatch(fetchDashboard());
    dispatch(fetchBalanceHistory());
  }, [dispatch]);

  const stats = [
    { key: 'income', title: t('incomeThisMonth'), curr: thisMonth.income, prev: lastMonth.income, positiveIsGood: true, color: '#52c41a' },
    { key: 'expense', title: t('expenseThisMonth'), curr: thisMonth.expense, prev: lastMonth.expense, positiveIsGood: false, color: '#ff4d4f' },
    { key: 'savings', title: t('savingsThisMonth'), curr: thisMonth.savings, prev: lastMonth.savings, positiveIsGood: true, color: '#1890ff' },
  ];

  return (
    <div className="page-container">
      <Row gutter={[16, 16]} align="middle" style={{ marginBottom: 20 }}>
        <Col flex="auto">
          <Title level={4} style={{ margin: 0 }}>{t('nav_dashboard')}</Title>
        </Col>
        <Col>
          <Text type="secondary">{dayjs().format('MMMM YYYY')}</Text>
        </Col>
      </Row>

      {/* Main Stats Row */}
      <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
        <Col xs={24} lg={8}>
          <Card
            className="stat-card"
            style={{ 
              height: '100%',
              background: `linear-gradient(135deg, ${primaryColor}, ${primaryColor}dd)`, 
              border: 'none',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'center'
            }}
          >
            <Text style={{ color: 'rgba(255,255,255,0.8)', display: 'block', marginBottom: 4, fontSize: 13 }}>{t('totalBalance')}</Text>
            {loading
              ? <Skeleton.Input active size="large" style={{ width: '80%' }} />
              : <Title level={2} style={{ color: '#fff', margin: 0, letterSpacing: -0.5 }}>IDR {fmt(totalBalance)}</Title>
            }
          </Card>
        </Col>

        {stats.map(({ key, title, curr, prev, positiveIsGood, color }) => (
          <Col xs={24} sm={8} lg={5} key={key}>
            <Card className="stat-card" style={{ height: '100%' }}>
              <Statistic
                title={<Text type="secondary" style={{ fontSize: 12 }}>{title}</Text>}
                value={Math.abs(curr)}
                prefix={<span style={{ fontSize: 12, marginRight: 4, color: 'var(--text-secondary)' }}>IDR</span>}
                formatter={(v) => <span style={{ fontWeight: 700, color: color }}>{fmt(v)}</span>}
                loading={loading}
              />
              {!loading && (
                <TrendBadge curr={curr} prev={prev} positiveIsGood={positiveIsGood} t={t} />
              )}
            </Card>
          </Col>
        ))}
        
        <Col xs={24} sm={8} lg={1} style={{ display: 'none' }} /> {/* Spacer if needed */}
      </Row>

      {/* Balance History Chart */}
      <Card
        className="stat-card"
        title={<Text strong>{t('balanceHistory')}</Text>}
        extra={<Tag color="blue">{t('last1Year')}</Tag>}
        style={{ marginBottom: 24, padding: '4px 0' }}
      >
        {historyLoading || balanceHistory.length === 0
          ? <Skeleton active paragraph={{ rows: 6 }} />
          : (
            <div style={{ width: '100%', height: 300, marginTop: 16 }}>
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={balanceHistory} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                  <defs>
                    <linearGradient id="balGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor={primaryColor} stopOpacity={0.3} />
                      <stop offset="95%" stopColor={primaryColor} stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(0,0,0,0.05)" />
                  <XAxis 
                    dataKey="month" 
                    tick={{ fontSize: 11, fill: 'rgba(0,0,0,0.45)' }} 
                    tickLine={false} 
                    axisLine={false}
                    dy={10}
                  />
                  <YAxis 
                    tickFormatter={fmtCompact} 
                    tick={{ fontSize: 11, fill: 'rgba(0,0,0,0.45)' }} 
                    tickLine={false} 
                    axisLine={false} 
                    width={60} 
                  />
                  <Tooltip
                    contentStyle={{ borderRadius: 12, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
                    formatter={(v) => [<span style={{ fontWeight: 700 }}>IDR {fmt(v)}</span>, t('balance')]}
                  />
                  <Area
                    type="monotone"
                    dataKey="balance"
                    stroke={primaryColor}
                    fill="url(#balGrad)"
                    strokeWidth={3}
                    dot={{ r: 4, fill: primaryColor, strokeWidth: 2, stroke: '#fff' }}
                    activeDot={{ r: 6, strokeWidth: 0 }}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          )}
      </Card>

      <Row gutter={[24, 24]}>
        {/* Account Cards */}
        <Col xs={24} lg={10}>
          <Card title={<Text strong>{t('myAccounts')}</Text>} className="stat-card">
            {loading ? <Skeleton active /> : accounts.length === 0 ? <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description={t('noAccounts')} /> : (
              <Row gutter={[12, 12]}>
                {accounts.map((acc) => {
                  const Icon = ACCOUNT_ICONS[acc.type] || WalletOutlined;
                  return (
                    <Col xs={12} key={acc._id}>
                      <div className="account-card-small" style={{ background: acc.color + '12', border: `1px solid ${acc.color}25`, borderRadius: 16, padding: '16px', height: '100%' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
                          <Avatar size={32} style={{ background: acc.color, boxShadow: `0 2px 6px ${acc.color}40` }} icon={<Icon />} />
                          <Text strong style={{ fontSize: 14 }}>{acc.name}</Text>
                        </div>
                        <Text strong style={{ color: acc.color, fontSize: 18, display: 'block' }}>IDR {fmt(acc.balance)}</Text>
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
          <Card title={<Text strong>{t('recentTransactions')}</Text>} className="stat-card">
            {loading ? <Skeleton active /> : recentTransactions.length === 0 ? <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description={t('noTransactions')} /> : (
              <List
                itemLayout="horizontal"
                dataSource={recentTransactions}
                renderItem={(tx) => (
                  <List.Item style={{ padding: '12px 0' }}>
                    <List.Item.Meta
                      avatar={
                        <Avatar 
                          size={40} 
                          style={{ 
                            background: tx.categoryId?.color + '20', 
                            color: tx.categoryId?.color,
                            fontSize: 16,
                            fontWeight: 700,
                            border: `1px solid ${tx.categoryId?.color}40`
                          }}
                        >
                          {tx.categoryId?.name?.[0] || '?'}
                        </Avatar>
                      }
                      title={
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <Text strong style={{ fontSize: 15 }}>{tx.categoryId?.name}</Text>
                          <Text strong style={{ color: tx.type === 'income' ? '#52c41a' : '#ff4d4f', fontSize: 16 }}>
                            {tx.type === 'income' ? '+' : '-'}IDR {fmt(tx.amount)}
                          </Text>
                        </div>
                      }
                      description={
                        <div style={{ display: 'flex', gap: 12, alignItems: 'center', marginTop: 4 }}>
                          <Tag color={tx.accountId?.color} style={{ margin: 0, borderRadius: 4 }}>{tx.accountId?.name}</Tag>
                          <Text type="secondary" style={{ fontSize: 12 }}>{dayjs(tx.date).format('DD MMM YYYY')}</Text>
                          {tx.note && <Text type="secondary" style={{ fontSize: 12 }}>· {tx.note}</Text>}
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

