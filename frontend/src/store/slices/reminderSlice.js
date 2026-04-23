import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../api/axios';

export const fetchReminders = createAsyncThunk('reminders/fetchAll', async (params = {}, { rejectWithValue }) => {
  try {
    const res = await api.get('/reminders', { params });
    return res.data;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message || 'Failed to fetch reminders');
  }
});

export const addReminder = createAsyncThunk('reminders/add', async (data, { rejectWithValue }) => {
  try {
    const res = await api.post('/reminders', data);
    return res.data;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message || 'Failed to add reminder');
  }
});

export const updateReminder = createAsyncThunk('reminders/update', async ({ id, data }, { rejectWithValue }) => {
  try {
    const res = await api.patch(`/reminders/${id}`, data);
    return res.data;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message || 'Failed to update reminder');
  }
});

export const toggleReminderComplete = createAsyncThunk('reminders/toggleComplete', async (id, { rejectWithValue }) => {
  try {
    const res = await api.patch(`/reminders/${id}/complete`);
    return res.data;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message || 'Failed to toggle reminder');
  }
});

export const deleteReminder = createAsyncThunk('reminders/delete', async (id, { rejectWithValue }) => {
  try {
    await api.delete(`/reminders/${id}`);
    return id;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message || 'Failed to delete reminder');
  }
});

const reminderSlice = createSlice({
  name: 'reminders',
  initialState: { reminders: [], loading: false, error: null },
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchReminders.pending, (state) => { state.loading = true; })
      .addCase(fetchReminders.fulfilled, (state, action) => {
        state.loading = false;
        state.reminders = action.payload;
      })
      .addCase(fetchReminders.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      .addCase(addReminder.fulfilled, (state, action) => {
        state.reminders.unshift(action.payload);
      })
      .addCase(updateReminder.fulfilled, (state, action) => {
        const idx = state.reminders.findIndex((r) => r.id === action.payload.id);
        if (idx !== -1) state.reminders[idx] = action.payload;
      })
      .addCase(toggleReminderComplete.fulfilled, (state, action) => {
        const idx = state.reminders.findIndex((r) => r.id === action.payload.id);
        if (idx !== -1) state.reminders[idx] = action.payload;
      })
      .addCase(deleteReminder.fulfilled, (state, action) => {
        state.reminders = state.reminders.filter((r) => r.id !== action.payload);
      });
  },
});

export default reminderSlice.reducer;
