import { useEffect, useState } from 'react';
import { Row, Col, Card, Progress, Button, Modal, Form, Input, InputNumber, DatePicker, ColorPicker, Typography, Space, Popconfirm, Empty, Skeleton, Tag } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, AimOutlined, CheckCircleFilled } from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { fetchGoals, addGoal, updateGoal, deleteGoal } from '../store/slices/goalSlice';
import useT from '../i18n/useT';
import dayjs from 'dayjs';

const { Title, Text } = Typography;

export default function Goals() {
  const dispatch = useDispatch();
  const t = useT();
  const { goals, loading } = useSelector((s) => s.goals);
  const primaryColor = useSelector((s) => s.settings.primaryColor);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingGoal, setEditingGoal] = useState(null);
  const [form] = Form.useForm();

  useEffect(() => {
    dispatch(fetchGoals());
  }, [dispatch]);

  const showModal = (goal = null) => {
    setEditingGoal(goal);
    if (goal) {
      form.setFieldsValue({
        ...goal,
        deadline: goal.deadline ? dayjs(goal.deadline) : null,
        color: goal.color,
      });
    } else {
      form.resetFields();
      form.setFieldsValue({ color: primaryColor });
    }
    setIsModalOpen(true);
  };

  const handleOk = async () => {
    try {
      const values = await form.validateFields();
      const data = {
        ...values,
        color: typeof values.color === 'string' ? values.color : values.color?.toHexString(),
      };
      
      if (editingGoal) {
        await dispatch(updateGoal({ id: editingGoal.id, data }));
      } else {
        await dispatch(addGoal(data));
      }
      setIsModalOpen(false);
    } catch (err) {
      console.error(err);
    }
  };

  const fmt = (n) => new Intl.NumberFormat('id-ID').format(n);

  return (
    <div className="page-container">
      <Row gutter={[16, 16]} align="middle" style={{ marginBottom: 24 }}>
        <Col flex="auto">
          <Title level={3} style={{ margin: 0 }}>{t('nav_goals') || 'Financial Goals'}</Title>
          <Text type="secondary">Plan and track your savings goals</Text>
        </Col>
        <Col>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => showModal()} size="large" style={{ borderRadius: 10 }}>
            {t('addGoal') || 'Add New Goal'}
          </Button>
        </Col>
      </Row>

      {loading ? (
        <Row gutter={[20, 20]}>
          {[1, 2, 3].map(i => <Col xs={24} md={12} lg={8} key={i}><Card><Skeleton active /></Card></Col>)}
        </Row>
      ) : goals.length === 0 ? (
        <Card className="stat-card" style={{ textAlign: 'center', padding: '40px 0' }}>
          <Empty description={t('noGoals') || "You haven't set any goals yet"} />
          <Button type="primary" ghost icon={<PlusOutlined />} onClick={() => showModal()} style={{ marginTop: 16 }}>
            Create your first goal
          </Button>
        </Card>
      ) : (
        <Row gutter={[20, 20]}>
          {goals.map((goal) => {
            const percent = Math.min(100, Math.round((goal.currentAmount / goal.targetAmount) * 100));
            const isDone = goal.isCompleted || percent >= 100;

            return (
              <Col xs={24} md={12} lg={8} key={goal.id}>
                <Card 
                  className="stat-card" 
                  hoverable
                  style={{ borderTop: `4px solid ${goal.color}` }}
                  actions={[
                    <EditOutlined key="edit" onClick={() => showModal(goal)} />,
                    <Popconfirm title="Delete this goal?" onConfirm={() => dispatch(deleteGoal(goal.id))}>
                      <DeleteOutlined key="delete" style={{ color: '#ff4d4f' }} />
                    </Popconfirm>
                  ]}
                >
                  <Space direction="vertical" style={{ width: '100%' }} size="middle">
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                      <Space align="center" size="middle">
                        <div style={{ 
                          width: 48, 
                          height: 48, 
                          borderRadius: 12, 
                          background: `${goal.color}15`, 
                          display: 'flex', 
                          alignItems: 'center', 
                          justifyContent: 'center',
                          color: goal.color,
                          fontSize: 24
                        }}>
                          {isDone ? <CheckCircleFilled /> : <AimOutlined />}
                        </div>
                        <div>
                          <Title level={5} style={{ margin: 0 }}>{goal.name}</Title>
                          {goal.deadline && (
                            <Text type="secondary" style={{ fontSize: 12 }}>
                              Target: {dayjs(goal.deadline).format('MMM D, YYYY')}
                            </Text>
                          )}
                        </div>
                      </Space>
                      {isDone && <Tag color="success">Completed</Tag>}
                    </div>

                    <div>
                      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                        <Text strong style={{ fontSize: 16 }}>IDR {fmt(goal.currentAmount)}</Text>
                        <Text type="secondary">of IDR {fmt(goal.targetAmount)}</Text>
                      </div>
                      <Progress 
                        percent={percent} 
                        strokeColor={goal.color} 
                        status={isDone ? "success" : "active"}
                        strokeWidth={10}
                      />
                    </div>
                    
                    <div style={{ background: 'var(--bg-body)', padding: '10px 12px', borderRadius: 10, display: 'flex', justifyContent: 'space-between' }}>
                      <Text type="secondary" style={{ fontSize: 13 }}>Remaining</Text>
                      <Text strong style={{ color: goal.color }}>IDR {fmt(Math.max(0, goal.targetAmount - goal.currentAmount))}</Text>
                    </div>
                  </Space>
                </Card>
              </Col>
            );
          })}
        </Row>
      )}

      <Modal
        title={editingGoal ? "Edit Goal" : "Add New Goal"}
        open={isModalOpen}
        onOk={handleOk}
        onCancel={() => setIsModalOpen(false)}
        destroyOnClose
        okText={editingGoal ? "Update" : "Create"}
        okButtonProps={{ style: { borderRadius: 8 } }}
        cancelButtonProps={{ style: { borderRadius: 8 } }}
      >
        <Form form={form} layout="vertical" style={{ marginTop: 16 }}>
          <Form.Item name="name" label="Goal Name" rules={[{ required: true, message: 'Please enter goal name' }]}>
            <Input placeholder="e.g. New Macbook, Japan Trip" />
          </Form.Item>
          
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="targetAmount" label="Target Amount" rules={[{ required: true, message: 'Please enter target amount' }]}>
                <InputNumber 
                  style={{ width: '100%' }} 
                  formatter={value => `IDR ${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')}
                  parser={value => value.replace(/IDR\s?|(,*)/g, '')}
                  min={0}
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="currentAmount" label="Current Amount" initialValue={0}>
                <InputNumber 
                  style={{ width: '100%' }} 
                  formatter={value => `IDR ${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')}
                  parser={value => value.replace(/IDR\s?|(,*)/g, '')}
                  min={0}
                />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="deadline" label="Target Date">
                <DatePicker style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="color" label="Theme Color">
                <ColorPicker showText />
              </Form.Item>
            </Col>
          </Row>
        </Form>
      </Modal>
    </div>
  );
}
