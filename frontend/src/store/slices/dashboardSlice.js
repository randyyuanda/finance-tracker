import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../api/axios';

export const fetchDashboard = createAsyncThunk('dashboard/fetch', async (_, { rejectWithValue }) => {
  try {
    const res = await api.get('/dashboard');
    return res.data;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message);
  }
});

export const fetchBalanceHistory = createAsyncThunk('dashboard/history', async (_, { rejectWithValue }) => {
  try {
    const res = await api.get('/dashboard/history');
    return res.data;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message);
  }
});

const dashboardSlice = createSlice({
  name: 'dashboard',
  initialState: {
    accounts: [],
    totalBalance: 0,
    balancesByCurrency: {},
    thisMonth: { income: 0, expense: 0, savings: 0 },
    lastMonth: { income: 0, expense: 0, savings: 0 },
    recentTransactions: [],
    balanceHistory: [],
    loading: false,
    historyLoading: false,
    error: null,
  },
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchDashboard.pending, (state) => { state.loading = true; })
      .addCase(fetchDashboard.fulfilled, (state, action) => { state.loading = false; Object.assign(state, action.payload); })
      .addCase(fetchDashboard.rejected, (state, action) => { state.loading = false; state.error = action.payload; })
      .addCase(fetchBalanceHistory.pending, (state) => { state.historyLoading = true; })
      .addCase(fetchBalanceHistory.fulfilled, (state, action) => { state.historyLoading = false; state.balanceHistory = action.payload; })
      .addCase(fetchBalanceHistory.rejected, (state) => { state.historyLoading = false; });
  },
});

export default dashboardSlice.reducer;
