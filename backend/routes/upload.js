const express = require('express');
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const User = require('../models/User');
const auth = require('../middleware/auth');
const router = express.Router();

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Use memory storage — no disk needed
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (_, file, cb) => {
    // Accept any image type including octet-stream from Android
    const allowed = ['image/jpeg', 'image/png', 'image/jpg', 'image/webp', 'image/gif', 'application/octet-stream'];
    if (allowed.includes(file.mimetype) || file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(null, true); // accept all for now — Cloudinary will validate
    }
  },
});

// POST /api/upload/avatar
router.post('/avatar', auth, upload.single('avatar'), async (req, res) => {
  try {
    console.log('Upload request received');
    console.log('Files:', req.file ? `${req.file.originalname} (${req.file.mimetype}, ${req.file.size} bytes)` : 'none');
    console.log('Body keys:', Object.keys(req.body));

    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded. Make sure field name is "avatar"' });
    }

    // Upload buffer to Cloudinary
    const result = await new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        {
          folder: 'addiscinema/avatars',
          public_id: `user_${req.user._id}`,
          overwrite: true,
          transformation: [{ width: 400, height: 400, crop: 'fill', gravity: 'face' }],
        },
        (error, result) => {
          if (error) reject(error);
          else resolve(result);
        }
      );
      stream.end(req.file.buffer);
    });

    // Save Cloudinary URL to user
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { avatar: result.secure_url },
      { new: true }
    ).select('-password');

    res.json({ avatarUrl: result.secure_url, user });
  } catch (err) {
    console.error('Upload error:', err);
    res.status(500).json({ message: err.message });
  }
});

// DELETE /api/upload/avatar — remove profile photo
router.delete('/avatar', auth, async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { avatar: '' },
      { new: true }
    ).select('-password');
    res.json({ user });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
