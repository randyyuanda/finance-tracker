import { useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useDispatch } from 'react-redux';
import { Spin } from 'antd';
import { setToken, fetchMe } from '../store/slices/authSlice';

export default function OAuthCallback() {
  const [params] = useSearchParams();
  const dispatch = useDispatch();
  const navigate = useNavigate();

  useEffect(() => {
    const token = params.get('token');
    const error = params.get('error');
    if (token) {
      dispatch(setToken(token));
      dispatch(fetchMe()).then((res) => {
        const user = res.payload;
        if (user && (!user.hasPassword || !user.phone)) {
          navigate('/set-password', { replace: true });
        } else {
          navigate('/', { replace: true });
        }
      });
    } else {
      navigate('/login?error=' + (error || 'oauth'), { replace: true });
    }
  }, []);

  return (
    <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
      <Spin size="large" tip="Signing you in..." />
    </div>
  );
}
