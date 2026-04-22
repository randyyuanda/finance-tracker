import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../api/axios';

export const fetchRecurring = createAsyncThunk('recurring/fetchAll', async (_, { rejectWithValue }) => {
  try {
    const res = await api.get('/recurring');
    return res.data;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message || 'Failed to fetch recurring transactions');
  }
});

export const addRecurring = createAsyncThunk('recurring/add', async (rtData, { rejectWithValue }) => {
  try {
    const res = await api.post('/recurring', rtData);
    return res.data;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message || 'Failed to add recurring transaction');
  }
});

export const updateRecurring = createAsyncThunk('recurring/update', async ({ id, data }, { rejectWithValue }) => {
  try {
    const res = await api.patch(`/recurring/${id}`, data);
    return res.data;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message || 'Failed to update recurring transaction');
  }
});

export const deleteRecurring = createAsyncThunk('recurring/delete', async (id, { rejectWithValue }) => {
  try {
    await api.delete(`/recurring/${id}`);
    return id;
  } catch (err) {
    return rejectWithValue(err.response?.data?.message || 'Failed to delete recurring transaction');
  }
});

const recurringSlice = createSlice({
  name: 'recurring',
  initialState: { transactions: [], loading: false, error: null },
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchRecurring.pending, (state) => { state.loading = true; })
      .addCase(fetchRecurring.fulfilled, (state, action) => {
        state.loading = false;
        state.transactions = action.payload;
      })
      .addCase(fetchRecurring.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      .addCase(addRecurring.fulfilled, (state, action) => {
        state.transactions.unshift(action.payload);
      })
      .addCase(updateRecurring.fulfilled, (state, action) => {
        const index = state.transactions.findIndex((t) => t.id === action.payload.id);
        if (index !== -1) state.transactions[index] = action.payload;
      })
      .addCase(deleteRecurring.fulfilled, (state, action) => {
        state.transactions = state.transactions.filter((t) => t.id !== action.payload);
      });
  },
});

export default recurringSlice.reducer;
