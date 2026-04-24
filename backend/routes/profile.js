const express = require('express');
const User = require('../models/User');
const auth = require('../middleware/auth');
const router = express.Router();

// GET /api/profile — get current user profile
router.get('/', auth, async (req, res) => {
  try {
    res.json(req.user);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /api/profile — update name, phone, language, theme, notifications
router.put('/', auth, async (req, res) => {
  try {
    const { name, phone, language, theme, notifications } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { name, phone, language, theme, notifications },
      { new: true, runValidators: true }
    ).select('-password');
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /api/profile/password — change password
router.put('/password', auth, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const user = await User.findById(req.user._id);
    if (!(await user.comparePassword(currentPassword)))
      return res.status(400).json({ message: 'Current password is incorrect' });

    user.password = newPassword;
    await user.save();
    res.json({ message: 'Password updated successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/profile/bookings — get booking history
router.get('/bookings', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('bookingHistory');
    res.json(user.bookingHistory.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/profile/bookings — add a booking
router.post('/bookings', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    user.bookingHistory.push(req.body);
    await user.save();
    res.status(201).json(user.bookingHistory[user.bookingHistory.length - 1]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// DELETE /api/profile/bookings/:id — delete a booking
router.delete('/bookings/:id', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    user.bookingHistory = user.bookingHistory.filter(
      b => b._id.toString() !== req.params.id
    );
    await user.save();
    res.json({ message: 'Booking deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/profile/payments — get payment methods
router.get('/payments', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('paymentMethods');
    res.json(user.paymentMethods);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/profile/payments — add payment method
router.post('/payments', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (req.body.isDefault) {
      user.paymentMethods.forEach(p => p.isDefault = false);
    }
    user.paymentMethods.push(req.body);
    await user.save();
    res.status(201).json(user.paymentMethods);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// DELETE /api/profile/payments/:id — remove payment method
router.delete('/payments/:id', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    user.paymentMethods = user.paymentMethods.filter(p => p._id.toString() !== req.params.id);
    await user.save();
    res.json({ message: 'Payment method removed' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
