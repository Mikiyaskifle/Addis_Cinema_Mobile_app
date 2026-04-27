const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true },
  phone: { type: String, default: '' },
  password: { type: String, required: true, minlength: 6 },
  avatar: { type: String, default: '' },
  bookingHistory: [{
    movieTitle: String,
    moviePoster: String,
    date: String,
    time: String,
    seats: [String],
    screenType: String,
    totalPrice: Number,
    bookingId: String,
    createdAt: { type: Date, default: Date.now }
  }],
  paymentMethods: [{
    type: { type: String }, // telebirr, cbe, awash, abyssinia
    accountNumber: String,
    isDefault: { type: Boolean, default: false }
  }],
  notifications: { type: Boolean, default: true },
  language: { type: String, default: 'English' },
  theme: { type: String, default: 'Dark' },
  createdAt: { type: Date, default: Date.now }
});

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 8); // 8 rounds = fast
  next();
});

// Compare password
userSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
