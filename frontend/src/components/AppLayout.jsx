import { useState, useEffect, useMemo } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import { Layout, Menu, Avatar, Dropdown, Button, Drawer, Typography, Badge, List, Popover } from 'antd';
import {
  DashboardOutlined,
  WalletOutlined,
  TagsOutlined,
  SwapOutlined,
  FileTextOutlined,
  LogoutOutlined,
  UserOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined,
  BankOutlined,
  SettingOutlined,
  AimOutlined,
  SyncOutlined,
  CalendarOutlined,
  BellOutlined,
  ClockCircleOutlined,
  ExclamationCircleOutlined,
} from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { logout } from '../store/slices/authSlice';
import { fetchReminders } from '../store/slices/reminderSlice';
import useT from '../i18n/useT';
import useReminderNotifications from '../hooks/useReminderNotifications';
import dayjs from 'dayjs';

const { Sider, Header, Content, Footer } = Layout;
const { Text } = Typography;

export default function AppLayout() {
  const t = useT();
  const navigate = useNavigate();
  const location = useLocation();
  const dispatch = useDispatch();
  const { user } = useSelector((s) => s.auth);
  const primaryColor = useSelector((s) => s.settings.primaryColor);
  const themeMode = useSelector((s) => s.settings.themeMode);
  
  const { reminders } = useSelector((s) => s.reminders);
  useReminderNotifications();
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [isMobile, setIsMobile] = useState(window.innerWidth < 768);

  useEffect(() => { dispatch(fetchReminders()); }, [dispatch]);

  const alertReminders = useMemo(() => {
    const now = dayjs();
    return reminders
      .filter((r) => !r.isCompleted && dayjs(r.reminderDate).isBefore(now.add(7, 'day')))
      .slice(0, 5);
  }, [reminders]);

  const overdueCount = useMemo(
    () => reminders.filter((r) => !r.isCompleted && dayjs(r.reminderDate).isBefore(dayjs())).length,
    [reminders]
  );

  const NAV_ITEMS = [
    { key: '/', icon: <DashboardOutlined />, label: t('nav_dashboard') },
    { key: '/accounts', icon: <WalletOutlined />, label: t('nav_accounts') },
    { key: '/categories', icon: <TagsOutlined />, label: t('nav_categories') },
    { key: '/transactions', icon: <SwapOutlined />, label: t('nav_transactions') },
    { key: '/reports', icon: <FileTextOutlined />, label: t('nav_reports') },
    { key: '/calendar', icon: <CalendarOutlined />, label: t('nav_calendar') || 'Calendar' },
    { key: '/goals', icon: <AimOutlined />, label: t('nav_goals') || 'Goals' },
    { key: '/recurring', icon: <SyncOutlined />, label: t('nav_recurring') || 'Recurring' },
    { key: '/reminders', icon: <BellOutlined />, label: 'Reminders' },
    { key: '/settings', icon: <SettingOutlined />, label: t('nav_settings') },
  ];

  useEffect(() => {
    const handler = () => setIsMobile(window.innerWidth < 768);
    window.addEventListener('resize', handler);
    return () => window.removeEventListener('resize', handler);
  }, []);

  const handleNav = (key) => {
    navigate(key);
    if (isMobile) setMobileOpen(false);
  };

  const userMenu = {
    items: [
      { key: 'settings', icon: <UserOutlined />, label: t('nav_settings') },
      { key: 'logout', icon: <LogoutOutlined />, label: t('logout'), danger: true },
    ],
    onClick: ({ key }) => {
      if (key === 'logout') dispatch(logout());
      else if (key === 'settings') navigate('/settings');
    },
  };

  const menuContent = (
    <Menu
      theme="dark"
      mode="inline"
      selectedKeys={[location.pathname]}
      items={NAV_ITEMS}
      onClick={({ key }) => handleNav(key)}
      style={{ borderRight: 'none', flex: 1, paddingTop: 8 }}
    />
  );

  return (
    <Layout style={{ minHeight: '100vh' }}>
      {!isMobile && (
        <Sider
          collapsible
          collapsed={collapsed}
          onCollapse={setCollapsed}
          theme="dark"
          width={240}
          style={{ position: 'sticky', top: 0, height: '100vh', overflow: 'auto' }}
        >
          <div style={{ padding: collapsed ? '20px 8px' : '20px 24px', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <BankOutlined style={{ color: primaryColor, fontSize: 24 }} />
              {!collapsed && <Text strong style={{ color: '#fff', fontSize: 18, letterSpacing: 0.5 }}>BuxBux</Text>}
            </div>
          </div>
          {menuContent}
        </Sider>
      )}

      <Drawer
        placement="left"
        open={mobileOpen}
        onClose={() => setMobileOpen(false)}
        width={250}
        styles={{ body: { padding: 0, background: '#001529' } }}
        headerStyle={{ display: 'none' }}
      >
        <div style={{ padding: '24px 24px', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <BankOutlined style={{ color: primaryColor, fontSize: 24 }} />
            <Text strong style={{ color: '#fff', fontSize: 20 }}>BuxBux</Text>
          </div>
        </div>
        {menuContent}
      </Drawer>

      <Layout>
        <Header
          style={{
            background: 'var(--header-bg, #fff)',
            padding: '0 24px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            boxShadow: '0 2px 8px rgba(0,0,0,0.05)',
            position: 'sticky',
            top: 0,
            zIndex: 100,
            height: 64,
          }}
        >
          <Button
            type="text"
            icon={isMobile ? <MenuUnfoldOutlined /> : collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
            onClick={() => isMobile ? setMobileOpen(true) : setCollapsed(!collapsed)}
            style={{ fontSize: 18 }}
          />
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <Popover
              placement="bottomRight"
              trigger="click"
              title={
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span>Reminders</span>
                  <Button type="link" size="small" onClick={() => navigate('/reminders')} style={{ padding: 0 }}>
                    View all
                  </Button>
                </div>
              }
              content={
                alertReminders.length === 0 ? (
                  <div style={{ padding: '12px 0', textAlign: 'center', color: '#999' }}>No upcoming reminders</div>
                ) : (
                  <List
                    size="small"
                    style={{ width: 280 }}
                    dataSource={alertReminders}
                    renderItem={(r) => {
                      const isOverdue = dayjs(r.reminderDate).isBefore(dayjs());
                      return (
                        <List.Item style={{ padding: '8px 0', cursor: 'pointer' }} onClick={() => navigate('/reminders')}>
                          <List.Item.Meta
                            avatar={isOverdue
                              ? <ExclamationCircleOutlined style={{ color: '#ff4d4f', fontSize: 16, marginTop: 2 }} />
                              : <ClockCircleOutlined style={{ color: primaryColor, fontSize: 16, marginTop: 2 }} />
                            }
                            title={<span style={{ fontSize: 13 }}>{r.title}</span>}
                            description={<span style={{ fontSize: 12 }}>{dayjs(r.reminderDate).format('MMM D, HH:mm')}</span>}
                          />
                        </List.Item>
                      );
                    }}
                  />
                )
              }
            >
              <Badge count={overdueCount} size="small">
                <Button type="text" icon={<BellOutlined style={{ fontSize: 18 }} />} />
              </Badge>
            </Popover>
          <Dropdown menu={userMenu} placement="bottomRight" trigger={['click']}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer', padding: '6px 12px', borderRadius: 12, transition: 'background 0.3s' }} className="user-dropdown-hover">
              <Avatar 
                src={user?.avatar} 
                icon={<UserOutlined />} 
                style={{ background: primaryColor, boxShadow: `0 2px 6px ${primaryColor}40` }} 
                size={34} 
              />
              <Text className="desktop-only" strong style={{ fontSize: 14 }}>
                {user?.name}
              </Text>
            </div>
          </Dropdown>
          </div>
        </Header>

        <Content style={{ padding: isMobile ? '12px' : '24px', minHeight: 'calc(100vh - 128px)', overflow: 'auto' }}>
          <Outlet />
        </Content>
        <Footer style={{ textAlign: 'center', padding: '16px 24px', background: 'transparent' }}>
          <Text type="secondary" style={{ fontSize: 13, opacity: 0.7 }}>
            Randy Yuanda © 2026
          </Text>
        </Footer>
      </Layout>
    </Layout>
  );
}

