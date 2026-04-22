import { useState } from 'react';
import { Card, Button, Select, Typography, Row, Col, Alert, Space, Divider } from 'antd';
import { DownloadOutlined, FileExcelOutlined } from '@ant-design/icons';
import { useSelector } from 'react-redux';
import api from '../api/axios';

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

export default function Reports() {
  const { list: accounts } = useSelector((s) => s.accounts);
  const [period, setPeriod] = useState('1month');
  const [accountId, setAccountId] = useState('');
  const [type, setType] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

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

  return (
    <div className="page-container">
      <Title level={4} style={{ marginBottom: 16 }}>Reports</Title>

      <Row gutter={[16, 16]}>
        <Col xs={24} md={14} lg={10}>
          <Card className="stat-card" title={<Space><FileExcelOutlined style={{ color: '#52c41a' }} /> Download Report</Space>}>
            {error && <Alert message={error} type="error" showIcon style={{ marginBottom: 16 }} closable onClose={() => setError('')} />}

            <div style={{ marginBottom: 16 }}>
              <Text strong style={{ display: 'block', marginBottom: 6 }}>Period</Text>
              <Select value={period} onChange={setPeriod} style={{ width: '100%' }} size="large">
                {PERIODS.map((p) => <Option key={p.value} value={p.value}>{p.label}</Option>)}
              </Select>
            </div>

            <div style={{ marginBottom: 16 }}>
              <Text strong style={{ display: 'block', marginBottom: 6 }}>Account</Text>
              <Select value={accountId} onChange={setAccountId} style={{ width: '100%' }} size="large">
                <Option value="">All Accounts</Option>
                {accounts.map((a) => <Option key={a._id} value={a._id}>{a.name}</Option>)}
              </Select>
            </div>

            <div style={{ marginBottom: 20 }}>
              <Text strong style={{ display: 'block', marginBottom: 6 }}>Transaction Type</Text>
              <Select value={type} onChange={setType} style={{ width: '100%' }} size="large">
                {TYPES.map((t) => <Option key={t.value} value={t.value}>{t.label}</Option>)}
              </Select>
            </div>

            <Button
              type="primary"
              icon={<DownloadOutlined />}
              size="large"
              block
              loading={loading}
              onClick={download}
              style={{ height: 48 }}
            >
              Download Excel Report
            </Button>
          </Card>
        </Col>

        <Col xs={24} md={10} lg={14}>
          <Card className="stat-card" title="Report Info">
            <Paragraph>The Excel report includes:</Paragraph>
            <ul style={{ paddingLeft: 20, lineHeight: 2 }}>
              <li><Text strong>Transactions sheet</Text> — date, account, category, type, amount, note</li>
              <li><Text strong>Summary sheet</Text> — total income, expense, net savings, and transaction count</li>
            </ul>
            <Divider />
            <Paragraph type="secondary" style={{ fontSize: 13 }}>
              Filter by account and transaction type to generate targeted reports.
              All amounts are in IDR format.
            </Paragraph>
          </Card>
        </Col>
      </Row>
    </div>
  );
}
