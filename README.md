# 🎬 AddisCinema

A full-featured cinema booking mobile app built with **Flutter** and powered by a **Node.js + MongoDB** backend. AddisCinema lets users browse movies, watch trailers, select seats, order food & drinks, pay using Ethiopian payment methods, and receive QR-coded digital tickets.

---

## ✨ Features

### 🎥 Movies
- Horizontal carousel with dynamic background color per movie
- Now Showing / Coming Soon tabs
- Genre filter chips
- 14 movies with real YouTube trailer IDs

### 🎞 Movie Detail
- Inline YouTube trailer (lazy-loaded on tap)
- IMDB / Rotten Tomatoes / IGN ratings
- Cast, Directors, Writers, Storyline
- "More like this" section
- Bookmark to Favorites

### 💺 Seat Selection
- Interactive 8×9 seat grid
- Time slots & screen types (Extreme 3D, Realt 3D, etc.)
- Live price calculation in **ETB (Ethiopian Birr)**

### 🍿 Food & Drinks
- Pre-order Ethiopian & international snacks and drinks
- Real food photos, prices in ETB
- Live order summary

### 💳 Payment
- 4 Ethiopian payment methods: **TeleBirr, CBE Birr, Awash Bank, Bank of Abyssinia**
- Branded logo assets per method
- Simulated payment processing

### 🎫 Booking Confirmation
- Movie poster banner with booking details
- QR code generated from booking data
- **Download ticket** as PNG to Downloads folder
- **Share ticket** as screenshot image via native share sheet
- Back to Home button

### ❤️ Favorites
- Bookmark any movie
- 2-column grid view
- Live count updates

### 👤 Profile (with Backend)
- **Register / Login** with JWT authentication
- **Upload profile photo** from gallery
- Edit name & phone number
- Change password
- Booking history from database
- Add / remove payment methods
- Notifications toggle
- **Light / Dark theme** toggle
- **Amharic / English** language support
- Developer easter egg (tap About 5 times)
- Log Out

### 🌙 Theme & Language
- Full Light and Dark mode
- Amharic (አማርኛ) and English language support
- Settings persist across app restarts

---

## � Tech Stack

### Frontend
| Tool | Usage |
|------|-------|
| Flutter | UI framework |
| Dart 3.x | Language |
| Provider | Theme & language state management |
| youtube_player_flutter | Inline YouTube trailer |
| cached_network_image | Movie poster loading |
| qr_flutter | QR code generation |
| share_plus | Share ticket as image |
| screenshot | Capture ticket as PNG |
| path_provider | Downloads folder path |
| permission_handler | Storage permission |
| image_picker | Profile photo from gallery |
| http | REST API calls |
| shared_preferences | Local storage (token, settings) |
| flutter_localizations | Amharic/English support |

### Backend
| Tool | Usage |
|------|-------|
| Node.js | Runtime |
| Express.js | REST API framework |
| MongoDB Atlas | Cloud database |
| Mongoose | ODM for MongoDB |
| JWT | Authentication tokens |
| bcryptjs | Password hashing |
| multer | Profile image upload |
| dotenv | Environment variables |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- Node.js `>=18.x`
- MongoDB Atlas account (free)
- Android device (minSdk 21 / Android 5.0+)

### Run the Flutter App

```bash
git clone https://github.com/Mikiyaskifle/Addis_Cinema_Mobile_app.git
cd Addis_Cinema_Mobile_app
flutter pub get
flutter run
```

### Run the Backend

```bash
cd backend
npm install
```

Create `backend/.env`:
```env
PORT=3000
MONGODB_URI=mongodb+srv://USERNAME:PASSWORD@cluster.mongodb.net/addiscinema
JWT_SECRET=your_secret_key
JWT_EXPIRES_IN=30d
```

```bash
npm run dev
```

Server runs at `http://localhost:3000`

---

## 📁 Project Structure

```
├── lib/
│   ├── data/
│   │   ├── movies_data.dart         # 14 movies
│   │   └── favorites_store.dart     # Global favorites state
│   ├── models/
│   │   ├── movie.dart
│   │   ├── ticket.dart
│   │   └── concession_item.dart
│   ├── providers/
│   │   └── app_settings.dart        # Theme + language provider
│   ├── services/
│   │   └── api_service.dart         # All backend API calls
│   └── screens/
│       ├── splash_screen.dart
│       ├── main_shell.dart
│       ├── movies_screen.dart
│       ├── movie_detail_screen.dart
│       ├── select_seats_screen.dart
│       ├── concession_screen.dart
│       ├── payment_screen.dart
│       ├── booking_confirmation_screen.dart
│       ├── favorites_screen.dart
│       ├── tickets_screen.dart
│       ├── profile_screen.dart
│       ├── login_screen.dart
│       └── register_screen.dart
├── backend/
│   ├── models/User.js
│   ├── routes/
│   │   ├── auth.js
│   │   ├── profile.js
│   │   └── upload.js
│   ├── middleware/auth.js
│   └── server.js
└── assets/
    ├── icon/                        # App icon
    └── icons/                       # Payment method logos
```

---

## � API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login user |
| GET | `/api/profile` | Get user profile |
| PUT | `/api/profile` | Update profile |
| PUT | `/api/profile/password` | Change password |
| GET | `/api/profile/bookings` | Get booking history |
| POST | `/api/profile/bookings` | Add booking |
| GET | `/api/profile/payments` | Get payment methods |
| POST | `/api/profile/payments` | Add payment method |
| DELETE | `/api/profile/payments/:id` | Remove payment method |
| POST | `/api/upload/avatar` | Upload profile photo |

---

## 📱 Booking Flow

```
Splash → Movies → Movie Detail → Select Seats → Food & Drinks → Payment → Confirmation
```

---

## 🔐 Easter Egg

Profile → Support → **About** — tap 5 times to reveal developer info.

---

## 👨‍💻 Developer

**Mikiyas Kifle**
- 📧 mykeykifle@gmail.com
- 📞 +251941162079

---

## 📄 License

Educational and portfolio purposes.
