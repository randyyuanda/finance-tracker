import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../api/axios';

export const fetchAccounts = createAsyncThunk('accounts/fetch', async (_, { rejectWithValue }) => {
  try {
    const res = await api.get('/accounts');
    return res.data;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message);
  }
});

export const createAccount = createAsyncThunk('accounts/create', async (data, { rejectWithValue }) => {
  try {
    const res = await api.post('/accounts', data);
    return res.data;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message);
  }
});

export const updateAccount = createAsyncThunk('accounts/update', async ({ id, data }, { rejectWithValue }) => {
  try {
    const res = await api.put(`/accounts/${id}`, data);
    return res.data;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message);
  }
});

export const deleteAccount = createAsyncThunk('accounts/delete', async (id, { rejectWithValue }) => {
  try {
    await api.delete(`/accounts/${id}`);
    return id;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message);
  }
});

const accountSlice = createSlice({
  name: 'accounts',
  initialState: { list: [], loading: false, error: null },
  reducers: {
    updateAccountBalance(state, action) {
      const { id, balance } = action.payload;
      const acc = state.list.find((a) => a._id === id);
      if (acc) acc.balance = balance;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchAccounts.pending, (state) => { state.loading = true; })
      .addCase(fetchAccounts.fulfilled, (state, action) => { state.loading = false; state.list = action.payload; })
      .addCase(fetchAccounts.rejected, (state, action) => { state.loading = false; state.error = action.payload; })
      .addCase(createAccount.fulfilled, (state, action) => { state.list.push(action.payload); })
      .addCase(updateAccount.fulfilled, (state, action) => {
        const idx = state.list.findIndex((a) => a._id === action.payload._id);
        if (idx !== -1) state.list[idx] = action.payload;
      })
      .addCase(deleteAccount.fulfilled, (state, action) => {
        state.list = state.list.filter((a) => a._id !== action.payload);
      });
  },
});

export const { updateAccountBalance } = accountSlice.actions;
export default accountSlice.reducer;
