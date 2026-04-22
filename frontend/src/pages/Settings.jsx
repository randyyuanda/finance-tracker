import { useState, useEffect } from 'react';
import { Card, Typography, Form, Input, Button, Radio, Select, Divider, Upload, message, ColorPicker, Space, Avatar } from 'antd';
import { UserOutlined, UploadOutlined, BgColorsOutlined, TranslationOutlined, SmileOutlined, SaveOutlined } from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { updateProfile } from '../store/slices/authSlice';
import { updateSettings } from '../store/slices/settingsSlice';
import useT from '../i18n/useT';

const { Title, Text } = Typography;

export default function Settings() {
  const t = useT();
  const dispatch = useDispatch();
  const { user } = useSelector((s) => s.auth);
  const { themeMode, primaryColor, language } = useSelector((s) => s.settings);
  const [form] = Form.useForm();
  const [saving, setSaving] = useState(false);
  const [avatarUrl, setAvatarUrl] = useState(user?.avatar || '');

  useEffect(() => {
    form.setFieldsValue({
      name: user?.name,
      email: user?.email,
    });
    setAvatarUrl(user?.avatar || '');
  }, [user, form]);

  const onProfileSave = async (values) => {
    setSaving(true);
    try {
      await dispatch(updateProfile({ name: values.name, avatar: avatarUrl })).unwrap();
      message.success(t('profileSaved'));
    } catch (err) {
      message.error(err || t('saveFailed'));
    } finally {
      setSaving(false);
    }
  };

  const onThemeChange = (e) => {
    dispatch(updateSettings({ themeMode: e.target.value }));
  };

  const onColorChange = (color) => {
    dispatch(updateSettings({ primaryColor: color.toHexString() }));
  };

  const onLangChange = (val) => {
    dispatch(updateSettings({ language: val }));
  };

  const handleAvatarChange = (info) => {
    const file = info.file.originFileObj;
    if (!file) return;
    const img = new Image();
    const reader = new FileReader();
    reader.onload = (e) => {
      img.onload = () => {
        const MAX = 200;
        const scale = Math.min(MAX / img.width, MAX / img.height, 1);
        const canvas = document.createElement('canvas');
        canvas.width = img.width * scale;
        canvas.height = img.height * scale;
        canvas.getContext('2d').drawImage(img, 0, 0, canvas.width, canvas.height);
        setAvatarUrl(canvas.toDataURL('image/jpeg', 0.8));
      };
      img.src = e.target.result;
    };
    reader.readAsDataURL(file);
  };

  return (
    <div className="page-container" style={{ maxWidth: 800 }}>
      <Title level={4} style={{ marginBottom: 24 }}>{t('settingsTitle')}</Title>

      <Space direction="vertical" size={24} style={{ width: '100%' }}>
        {/* Profile Section */}
        <Card className="stat-card" title={<Space><UserOutlined /> {t('profileSection')}</Space>}>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', marginBottom: 24 }}>
            <Avatar size={100} src={avatarUrl} icon={<UserOutlined />} style={{ marginBottom: 16, border: `2px solid ${primaryColor}` }} />
            <Upload
              showUploadList={false}
              beforeUpload={() => true}
              customRequest={({ onSuccess }) => setTimeout(() => onSuccess("ok"), 0)}
              onChange={handleAvatarChange}
            >
              <Button icon={<UploadOutlined />}>{t('changePhoto')}</Button>
            </Upload>
          </div>

          <Form form={form} layout="vertical" onFinish={onProfileSave}>
            <Form.Item name="name" label={t('nameLabel')} rules={[{ required: true }]}>
              <Input size="large" />
            </Form.Item>
            <Form.Item name="email" label={t('emailLabel')}>
              <Input size="large" disabled />
            </Form.Item>
            <Button type="primary" htmlType="submit" loading={saving} icon={<SaveOutlined />} size="large" block>
              {t('saveProfile')}
            </Button>
          </Form>
        </Card>

        {/* Appearance Section */}
        <Card className="stat-card" title={<Space><BgColorsOutlined /> {t('appearanceSection')}</Space>}>
          <div style={{ marginBottom: 24 }}>
            <Text strong style={{ display: 'block', marginBottom: 12 }}>{t('themeMode')}</Text>
            <Radio.Group value={themeMode} onChange={onThemeChange} buttonStyle="solid" size="large">
              <Radio.Button value="light">{t('themeLight')}</Radio.Button>
              <Radio.Button value="dark">{t('themeDark')}</Radio.Button>
              <Radio.Button value="system">{t('themeSystem')}</Radio.Button>
            </Radio.Group>
          </div>

          <div>
            <Text strong style={{ display: 'block', marginBottom: 12 }}>{t('primaryColor')}</Text>
            <Space align="center" size={16}>
              <ColorPicker value={primaryColor} onChange={onColorChange} />
              <Text type="secondary">{primaryColor.toUpperCase()}</Text>
            </Space>
          </div>
        </Card>

        {/* Language Section */}
        <Card className="stat-card" title={<Space><TranslationOutlined /> {t('languageSection')}</Space>}>
          <Text strong style={{ display: 'block', marginBottom: 12 }}>{t('languageLabel')}</Text>
          <Select value={language} onChange={onLangChange} size="large" style={{ width: '100%', maxWidth: 300 }}>
            <Select.Option value="en">{t('english')}</Select.Option>
            <Select.Option value="id">{t('indonesian')}</Select.Option>
            <Select.Option value="zh">{t('chinese')}</Select.Option>
          </Select>
        </Card>
      </Space>
    </div>
  );
}
