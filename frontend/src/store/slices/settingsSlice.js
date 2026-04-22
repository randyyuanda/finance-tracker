import { createSlice } from '@reduxjs/toolkit';

const load = () => {
  try { return JSON.parse(localStorage.getItem('ft_settings') || '{}'); } catch { return {}; }
};

const save = (state) => {
  try { localStorage.setItem('ft_settings', JSON.stringify(state)); } catch { /* ignore */ }
};

const saved = load();

const settingsSlice = createSlice({
  name: 'settings',
  initialState: {
    themeMode: saved.themeMode || 'system',
    primaryColor: saved.primaryColor || '#1890ff',
    language: saved.language || 'en',
  },
  reducers: {
    updateSettings(state, action) {
      Object.assign(state, action.payload);
      save({ themeMode: state.themeMode, primaryColor: state.primaryColor, language: state.language });
    },
  },
});

export const { updateSettings } = settingsSlice.actions;
export default settingsSlice.reducer;
