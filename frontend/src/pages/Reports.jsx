import { useState, useEffect, useCallback } from 'react';
import { Card, Button, Select, Typography, Row, Col, Alert, Space, Divider, Skeleton, Empty } from 'antd';
import { DownloadOutlined, FileExcelOutlined, PieChartOutlined } from '@ant-design/icons';
import { useSelector } from 'react-redux';
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import api from '../api/axios';
import useT from '../i18n/useT';

const { Title, Text, Paragraph } = Typography;
const { Option } = Select;

const PERIODS = [
  { value: 'alltime', label: 'All Time' },
  { value: '1month', label: 'Last 1 Month' },
  { value: '3months', label: 'Last 3 Months' },
  { value: '1year', label: 'Last 1 Year' },
  { value: '2years', label: 'Last 2 Years' },
];

const TYPES = [
  { value: '', label: 'All (Income + Expense)' },
  { value: 'income', label: 'Income Only' },
  { value: 'expense', label: 'Expense Only' },
];

const fmt = (n) => new Intl.NumberFormat('id-ID').format(Math.round(n));

export default function Reports() {
  const t = useT();
  const { list: accounts } = useSelector((s) => s.accounts);
  const [period, setPeriod] = useState('1month');
  const [accountId, setAccountId] = useState('');
  const [type, setType] = useState('');
  const [loading, setLoading] = useState(false);
  const [dataLoading, setDataLoading] = useState(false);
  const [error, setError] = useState('');
  const [breakdown, setBreakdown] = useState({ income: [], expense: [] });

  const fetchData = useCallback(async () => {
    setDataLoading(true);
    try {
      const params = { period };
      if (accountId) params.accountId = accountId;
      const res = await api.get('/reports/summary', { params });
      setBreakdown(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setDataLoading(false);
    }
  }, [period, accountId]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const download = async () => {
    setLoading(true);
    setError('');
    try {
      const params = { period };
      if (accountId) params.accountId = accountId;
      if (type) params.type = type;

      const res = await api.get('/reports/download', {
        params,
        responseType: 'blob',
      });

      const blob = new Blob([res.data], {
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `finance-report-${period}.xlsx`;
      a.click();
      window.URL.revokeObjectURL(url);
    } catch {
      setError('Failed to generate report. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const renderChart = (data, title, color) => (
    <Card className="stat-card" style={{ height: '100%' }} title={<Text strong>{title}</Text>}>
      {dataLoading ? <Skeleton active /> : data.length === 0 ? <Empty description={t('noData')} image={Empty.PRESENTED_IMAGE_SIMPLE} /> : (
        <div style={{ height: 300 }}>
          <ResponsiveContainer width="100%" height="100%">
            <PieChart>
              <Pie
                data={data}
                dataKey="total"
                nameKey="name"
                cx="50%"
                cy="50%"
                innerRadius={60}
                outerRadius={80}
                paddingAngle={5}
              >
                {data.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip formatter={(v) => `IDR ${fmt(v)}`} />
              <Legend verticalAlign="bottom" height={36}/>
            </PieChart>
          </ResponsiveContainer>
        </div>
      )}
    </Card>
  );

  return (
    <div className="page-container">
      <Title level={4} style={{ marginBottom: 24 }}>{t('nav_reports')}</Title>

      <Row gutter={[24, 24]}>
        <Col xs={24} lg={8}>
          <Card className="stat-card" title={<Space><FileExcelOutlined style={{ color: '#52c41a' }} /> {t('downloadReport')}</Space>}>
            {error && <Alert message={error} type="error" showIcon style={{ marginBottom: 16 }} closable onClose={() => setError('')} />}

            <div style={{ marginBottom: 16 }}>
              <Text strong style={{ display: 'block', marginBottom: 6 }}>{t('period')}</Text>
              <Select value={period} onChange={setPeriod} style={{ width: '100%' }} size="large">
                {PERIODS.map((p) => <Option key={p.value} value={p.value}>{t(`last${p.value === 'alltime' ? 'AllTime' : p.value.charAt(0).toUpperCase() + p.value.slice(1)}`) || p.label}</Option>)}
              </Select>
            </div>

            <div style={{ marginBottom: 16 }}>
              <Text strong style={{ display: 'block', marginBottom: 6 }}>{t('account')}</Text>
              <Select value={accountId} onChange={setAccountId} style={{ width: '100%' }} size="large">
                <Option value="">{t('allAccounts')}</Option>
                {accounts.map((a) => <Option key={a._id} value={a._id}>{a.name}</Option>)}
              </Select>
            </div>

            <div style={{ marginBottom: 24 }}>
              <Text strong style={{ display: 'block', marginBottom: 6 }}>{t('transactionType')}</Text>
              <Select value={type} onChange={setType} style={{ width: '100%' }} size="large">
                <Option value="">{t('allIncomeExpense')}</Option>
                <Option value="income">{t('incomeOnly')}</Option>
                <Option value="expense">{t('expenseOnly')}</Option>
              </Select>
            </div>

            <Button
              type="primary"
              icon={<DownloadOutlined />}
              size="large"
              block
              loading={loading}
              onClick={download}
              style={{ height: 48, borderRadius: 12, fontWeight: 600 }}
            >
              {t('downloadExcel')}
            </Button>
            
            <Divider style={{ margin: '24px 0 16px 0' }} />
            
            <Text type="secondary" style={{ fontSize: 13 }}>
              {t('reportIncludes')}
              <ul style={{ marginTop: 8, paddingLeft: 20 }}>
                <li>{t('reportSheet1')}</li>
                <li>{t('reportSheet2')}</li>
                <li>{t('reportSheet3')}</li>
                <li>{t('reportSheet4')}</li>
              </ul>
            </Text>
          </Card>
        </Col>

        <Col xs={24} lg={16}>
          <Row gutter={[16, 16]}>
            <Col xs={24} md={12}>
              {renderChart(breakdown.expense, t('expenseByCategory'))}
            </Col>
            <Col xs={24} md={12}>
              {renderChart(breakdown.income, t('incomeByCategory'))}
            </Col>
          </Row>
          
          <Card className="stat-card" style={{ marginTop: 16 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{ background: '#e6f7ff', padding: 12, borderRadius: 12 }}>
                <PieChartOutlined style={{ fontSize: 24, color: '#1890ff' }} />
              </div>
              <div>
                <Title level={5} style={{ margin: 0 }}>{t('reportInfo')}</Title>
                <Text type="secondary">{t('noData') === 'No data' ? 'Analyze your spending patterns with interactive category charts.' : 'Analisis pola pengeluaran Anda dengan grafik kategori interaktif.'}</Text>
              </div>
            </div>
          </Card>
        </Col>
      </Row>
    </div>
  );
}

