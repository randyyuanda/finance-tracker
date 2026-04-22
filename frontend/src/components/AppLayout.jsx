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
} from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { logout } from '../store/slices/authSlice';

const { Sider, Header, Content } = Layout;
const { Text } = Typography;

const NAV_ITEMS = [
  { key: '/', icon: <DashboardOutlined />, label: 'Dashboard' },
  { key: '/accounts', icon: <WalletOutlined />, label: 'Accounts' },
  { key: '/categories', icon: <TagsOutlined />, label: 'Categories' },
  { key: '/transactions', icon: <SwapOutlined />, label: 'Transactions' },
  { key: '/reports', icon: <FileTextOutlined />, label: 'Reports' },
];

export default function AppLayout() {
  const navigate = useNavigate();
  const location = useLocation();
  const dispatch = useDispatch();
  const { user } = useSelector((s) => s.auth);
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [isMobile, setIsMobile] = useState(window.innerWidth < 768);

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
      { key: 'logout', icon: <LogoutOutlined />, label: 'Logout', danger: true },
    ],
    onClick: ({ key }) => {
      if (key === 'logout') dispatch(logout());
    },
  };

  const menuContent = (
    <Menu
      theme="dark"
      mode="inline"
      selectedKeys={[location.pathname]}
      items={NAV_ITEMS}
      onClick={({ key }) => handleNav(key)}
      style={{ borderRight: 'none', flex: 1 }}
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
          width={220}
          style={{ position: 'sticky', top: 0, height: '100vh', overflow: 'auto' }}
        >
          <div style={{ padding: collapsed ? '20px 8px' : '20px 16px', borderBottom: '1px solid rgba(255,255,255,0.1)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <BankOutlined style={{ color: '#1890ff', fontSize: 22 }} />
              {!collapsed && <Text strong style={{ color: '#fff', fontSize: 16 }}>FinTrack</Text>}
            </div>
          </div>
          {menuContent}
        </Sider>
      )}

      <Drawer
        placement="left"
        open={mobileOpen}
        onClose={() => setMobileOpen(false)}
        width={220}
        bodyStyle={{ padding: 0, background: '#001529' }}
        headerStyle={{ display: 'none' }}
      >
        <div style={{ padding: '20px 16px', borderBottom: '1px solid rgba(255,255,255,0.1)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <BankOutlined style={{ color: '#1890ff', fontSize: 22 }} />
            <Text strong style={{ color: '#fff', fontSize: 16 }}>FinTrack</Text>
          </div>
        </div>
        {menuContent}
      </Drawer>

      <Layout>
        <Header
          style={{
            background: '#fff',
            padding: '0 16px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            boxShadow: '0 1px 4px rgba(0,21,41,0.08)',
            position: 'sticky',
            top: 0,
            zIndex: 100,
          }}
        >
          <Button
            type="text"
            icon={isMobile ? <MenuUnfoldOutlined /> : collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
            onClick={() => isMobile ? setMobileOpen(true) : setCollapsed(!collapsed)}
            style={{ fontSize: 16 }}
          />
          <Dropdown menu={userMenu} placement="bottomRight" trigger={['click']}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', padding: '4px 8px', borderRadius: 8 }}>
              <Avatar src={user?.avatar} icon={<UserOutlined />} style={{ background: '#1890ff' }} size={32} />
              <Text className="desktop-only" strong style={{ maxWidth: 120, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                {user?.name}
              </Text>
            </div>
          </Dropdown>
        </Header>

        <Content style={{ padding: '16px', minHeight: 'calc(100vh - 64px)', overflow: 'auto' }}>
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  );
}
