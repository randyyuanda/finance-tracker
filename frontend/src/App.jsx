import { useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { Spin } from 'antd';
import { fetchMe } from './store/slices/authSlice';
import AppLayout from './components/AppLayout';
import Login from './pages/Login';
import Register from './pages/Register';
import OAuthCallback from './pages/OAuthCallback';
import Dashboard from './pages/Dashboard';
import Accounts from './pages/Accounts';
import Categories from './pages/Categories';
import Transactions from './pages/Transactions';
import Reports from './pages/Reports';
import Settings from './pages/Settings';
import Goals from './pages/Goals';
import RecurringTransactions from './pages/RecurringTransactions';
import TransactionCalendar from './pages/Calendar';
import Reminders from './pages/Reminders';
import Admin from './pages/Admin';

const Spinner = () => (
  <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
    <Spin size="large" />
  </div>
);

function PrivateRoute({ children, allowIncomplete = false }) {
  const { token, user, loading } = useSelector((s) => s.auth);
  if (loading) return <Spinner />;
  if (!token) return <Navigate to="/login" replace />;
  if (!user) return <Spinner />;
  
  if (!allowIncomplete && !user.hasPassword) {
    return <Navigate to="/set-password" replace />;
  }

  // Admin users must use the /admin route
  if (user.isAdmin) return <Navigate to="/admin" replace />;
  return children;
}

function AdminRoute({ children }) {
  const { token, user, loading } = useSelector((s) => s.auth);
  if (loading) return <Spinner />;
  if (!token) return <Navigate to="/login" replace />;
  if (!user) return <Spinner />;
  if (!user.isAdmin) return <Navigate to="/" replace />;
  return children;
}

function PublicRoute({ children }) {
  const { token, user } = useSelector((s) => s.auth);
  if (!token) return children;
  return <Navigate to={user?.isAdmin ? '/admin' : '/'} replace />;
}

import SetPassword from './pages/SetPassword';

import ForgotPassword from './pages/ForgotPassword';

export default function App() {
  const dispatch = useDispatch();
  const { token } = useSelector((s) => s.auth);

  useEffect(() => {
    if (token) dispatch(fetchMe());
  }, [token, dispatch]);

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<PublicRoute><Login /></PublicRoute>} />
        <Route path="/register" element={<PublicRoute><Register /></PublicRoute>} />
        <Route path="/forgot-password" element={<PublicRoute><ForgotPassword /></PublicRoute>} />
        <Route path="/oauth-callback" element={<OAuthCallback />} />
        <Route path="/set-password" element={<PrivateRoute allowIncomplete={true}><SetPassword /></PrivateRoute>} />

        {/* Admin */}
        <Route path="/admin" element={<AdminRoute><Admin /></AdminRoute>} />

        {/* Regular user app */}
        <Route path="/" element={<PrivateRoute><AppLayout /></PrivateRoute>}>
          <Route index element={<Dashboard />} />
          <Route path="accounts" element={<Accounts />} />
          <Route path="categories" element={<Categories />} />
          <Route path="transactions" element={<Transactions />} />
          <Route path="reports" element={<Reports />} />
          <Route path="settings" element={<Settings />} />
          <Route path="goals" element={<Goals />} />
          <Route path="recurring" element={<RecurringTransactions />} />
          <Route path="calendar" element={<TransactionCalendar />} />
          <Route path="reminders" element={<Reminders />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
