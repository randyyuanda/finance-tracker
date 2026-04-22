const mongoose = require('mongoose');

const accountSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true, trim: true },
  type: {
    type: String,
    enum: ['cash', 'bank', 'e-wallet', 'credit-card', 'savings'],
    default: 'cash',
  },
  balance: { type: Number, default: 0 },
  currency: { type: String, default: 'IDR' },
  color: { type: String, default: '#1890ff' },
  icon: { type: String, default: 'wallet' },
  isActive: { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.model('Account', accountSchema);
