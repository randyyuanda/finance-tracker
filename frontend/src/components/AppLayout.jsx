import { useState, useEffect } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import { Layout, Menu, Avatar, Dropdown, Button, Drawer, Typography } from 'antd';
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
  TargetOutlined,
  SyncOutlined,
} from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { logout } from '../store/slices/authSlice';
import useT from '../i18n/useT';

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
  
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [isMobile, setIsMobile] = useState(window.innerWidth < 768);

  const NAV_ITEMS = [
    { key: '/', icon: <DashboardOutlined />, label: t('nav_dashboard') },
    { key: '/accounts', icon: <WalletOutlined />, label: t('nav_accounts') },
    { key: '/categories', icon: <TagsOutlined />, label: t('nav_categories') },
    { key: '/transactions', icon: <SwapOutlined />, label: t('nav_transactions') },
    { key: '/reports', icon: <FileTextOutlined />, label: t('nav_reports') },
    { key: '/goals', icon: <TargetOutlined />, label: t('nav_goals') || 'Goals' },
    { key: '/recurring', icon: <SyncOutlined />, label: t('nav_recurring') || 'Recurring' },
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
              {!collapsed && <Text strong style={{ color: '#fff', fontSize: 18, letterSpacing: 0.5 }}>FinTrack</Text>}
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
            <Text strong style={{ color: '#fff', fontSize: 20 }}>FinTrack</Text>
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

