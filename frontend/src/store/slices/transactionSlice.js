import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../api/axios';

export const fetchTransactions = createAsyncThunk('transactions/fetch', async (params, { rejectWithValue }) => {
  try {
    const res = await api.get('/transactions', { params });
    return res.data;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message);
  }
});

export const createTransaction = createAsyncThunk('transactions/create', async (data, { rejectWithValue }) => {
  try {
    const res = await api.post('/transactions', data);
    return res.data;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message);
  }
});

export const updateTransaction = createAsyncThunk('transactions/update', async ({ id, data }, { rejectWithValue }) => {
  try {
    const res = await api.put(`/transactions/${id}`, data);
    return res.data;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message);
  }
});

export const deleteTransaction = createAsyncThunk('transactions/delete', async (id, { rejectWithValue }) => {
  try {
    await api.delete(`/transactions/${id}`);
    return id;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message);
  }
});

const transactionSlice = createSlice({
  name: 'transactions',
  initialState: { list: [], total: 0, page: 1, pages: 1, loading: false, error: null },
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchTransactions.pending, (state) => { state.loading = true; })
      .addCase(fetchTransactions.fulfilled, (state, action) => {
        state.loading = false;
        state.list = action.payload.transactions;
        state.total = action.payload.total;
        state.page = action.payload.page;
        state.pages = action.payload.pages;
      })
      .addCase(fetchTransactions.rejected, (state, action) => { state.loading = false; state.error = action.payload; })
      .addCase(createTransaction.fulfilled, (state, action) => {
        state.list.unshift(action.payload);
        state.total += 1;
      })
      .addCase(updateTransaction.fulfilled, (state, action) => {
        const idx = state.list.findIndex((t) => t._id === action.payload._id);
        if (idx !== -1) state.list[idx] = action.payload;
      })
      .addCase(deleteTransaction.fulfilled, (state, action) => {
        state.list = state.list.filter((t) => t._id !== action.payload);
        state.total -= 1;
      });
  },
});

export default transactionSlice.reducer;
