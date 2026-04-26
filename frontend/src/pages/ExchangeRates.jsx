import { useState, useEffect, useCallback } from 'react';
import { Card, Select, InputNumber, Typography, Row, Col, Spin, Tag, Divider, Button, message } from 'antd';
import { SwapOutlined, ReloadOutlined } from '@ant-design/icons';

const { Title, Text } = Typography;

const CURRENCIES = ['IDR', 'USD', 'EUR', 'SGD', 'JPY', 'GBP', 'AUD', 'MYR'];
const FLAGS = { IDR: '🇮🇩', USD: '🇺🇸', EUR: '🇪🇺', SGD: '🇸🇬', JPY: '🇯🇵', GBP: '🇬🇧', AUD: '🇦🇺', MYR: '🇲🇾' };

const fmtRate = (n) => {
  if (n >= 1000) return new Intl.NumberFormat('id-ID', { maximumFractionDigits: 0 }).format(n);
  if (n >= 1) return new Intl.NumberFormat('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 4 }).format(n);
  return new Intl.NumberFormat('en-US', { minimumSignificantDigits: 3, maximumSignificantDigits: 4 }).format(n);
};

const fmtAmt = (n) => {
  if (n >= 1000) return new Intl.NumberFormat('id-ID', { maximumFractionDigits: 0 }).format(n);
  return new Intl.NumberFormat('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 4 }).format(n);
};

export default function ExchangeRates() {
  const [base, setBase] = useState('USD');
  const [amount, setAmount] = useState(1);
  const [rates, setRates] = useState({});
  const [date, setDate] = useState('');
  const [loading, setLoading] = useState(false);

  const fetchRates = useCallback(async (currency) => {
    setLoading(true);
    try {
      const b = currency.toLowerCase();
      const url = `https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/${b}.min.json`;
      const res = await fetch(url);
      const data = await res.json();
      const raw = data[b] || {};
      const filtered = {};
      CURRENCIES.forEach((c) => {
        const key = c.toLowerCase();
        if (key !== b && raw[key] != null) filtered[c] = raw[key];
      });
      setRates(filtered);
      setDate(data.date || '');
    } catch {
      message.error('Failed to fetch exchange rates. Please try again.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchRates(base); }, [base, fetchRates]);

  return (
    <div className="page-container">
      <Row gutter={[16, 16]} align="middle" style={{ marginBottom: 24 }}>
        <Col flex="auto">
          <Title level={4} style={{ margin: 0 }}>Exchange Rates</Title>
          {date && <Text type="secondary" style={{ fontSize: 12 }}>Updated: {date}</Text>}
        </Col>
        <Col>
          <Button icon={<ReloadOutlined />} onClick={() => fetchRates(base)} loading={loading}>
            Refresh
          </Button>
        </Col>
      </Row>

      <Card style={{ marginBottom: 24, borderRadius: 16 }}>
        <Row gutter={[16, 16]} align="middle">
          <Col xs={24} sm={8}>
            <Text type="secondary" style={{ fontSize: 12, display: 'block', marginBottom: 4 }}>Base Currency</Text>
            <Select
              value={base}
              onChange={(v) => setBase(v)}
              style={{ width: '100%' }}
              size="large"
            >
              {CURRENCIES.map((c) => (
                <Select.Option key={c} value={c}>
                  {FLAGS[c]} {c}
                </Select.Option>
              ))}
            </Select>
          </Col>
          <Col xs={24} sm={8}>
            <Text type="secondary" style={{ fontSize: 12, display: 'block', marginBottom: 4 }}>Amount</Text>
            <InputNumber
              value={amount}
              onChange={(v) => setAmount(v || 1)}
              min={0.01}
              style={{ width: '100%' }}
              size="large"
              formatter={(v) => `${v}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')}
              parser={(v) => Number((v || '').replace(/[^\d.]/g, '')) || 1}
            />
          </Col>
          <Col xs={24} sm={8} style={{ display: 'flex', alignItems: 'center', paddingTop: 20 }}>
            <SwapOutlined style={{ fontSize: 24, color: '#1890ff', margin: '0 auto' }} />
          </Col>
        </Row>
      </Card>

      {loading ? (
        <div style={{ display: 'flex', justifyContent: 'center', padding: 64 }}>
          <Spin size="large" />
        </div>
      ) : (
        <Row gutter={[16, 16]}>
          {CURRENCIES.filter((c) => c !== base).map((c) => {
            const rate = rates[c];
            if (rate == null) return null;
            const converted = rate * amount;
            return (
              <Col xs={24} sm={12} lg={8} xl={6} key={c}>
                <Card
                  size="small"
                  style={{ borderRadius: 14, height: '100%' }}
                  bodyStyle={{ padding: '16px 20px' }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <div>
                      <Text style={{ fontSize: 22, marginRight: 8 }}>{FLAGS[c]}</Text>
                      <Tag style={{ borderRadius: 6, fontWeight: 600 }}>{c}</Tag>
                    </div>
                  </div>
                  <Divider style={{ margin: '10px 0' }} />
                  <Text type="secondary" style={{ fontSize: 11, display: 'block' }}>
                    1 {base} = {fmtRate(rate)} {c}
                  </Text>
                  <Text strong style={{ fontSize: 18, display: 'block', marginTop: 4 }}>
                    {fmtAmt(converted)} {c}
                  </Text>
                  <Text type="secondary" style={{ fontSize: 11 }}>
                    for {amount} {base}
                  </Text>
                </Card>
              </Col>
            );
          })}
        </Row>
      )}
    </div>
  );
}
