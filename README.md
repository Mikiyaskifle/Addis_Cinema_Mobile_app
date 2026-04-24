# 🎬 AddisCinema

A full-stack mobile cinema booking application built for the Ethiopian market using **Flutter** and **Node.js**. AddisCinema allows users to browse movies, watch trailers, book seats, order food & drinks, pay using Ethiopian payment methods, and receive digital QR-coded tickets.

---

## 📱 Screenshots

> Coming soon

---

## 🎯 Problem Statement

Cinema booking in Ethiopia is mostly done manually — people go to the cinema, stand in line, and buy tickets at the counter. There is no digital platform that allows Ethiopians to browse movies, book seats in advance, pay using local methods like TeleBirr or CBE Birr, and receive a digital ticket. **AddisCinema solves all of these problems.**

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
- Buy Tickets requires login

### 💺 Seat Selection
- Interactive 8×9 seat grid (72 seats)
- Time slots & screen types (Extreme 3D, Realt 3D, etc.)
- Live price calculation in **ETB (Ethiopian Birr)** — 150 ETB/seat

### 🍿 Food & Drinks
- Pre-order Ethiopian & international snacks and drinks
- Items: Popcorn, Samosa, Injera & Tibs, Avocado Juice, Ethiopian Coffee, Ambo Water
- Real food photos, prices in ETB

### 💳 Payment
- 4 Ethiopian payment methods:
  - **TeleBirr** — Ethio Telecom Mobile Money
  - **CBE Birr** — Commercial Bank of Ethiopia
  - **Awash Bank** — Awash Mobile Banking
  - **Bank of Abyssinia** — BOA Mobile Banking
- SSL security badge, branded method cards

### 🎫 Booking Confirmation
- Movie poster banner with full booking details
- QR code generated from booking data
- Download ticket as PNG to Downloads folder
- Share ticket as screenshot image (WhatsApp, Telegram, etc.)
- Booking saved to MongoDB automatically

### ❤️ Favorites
- Bookmark any movie
- Favorites saved per user account (cleared on logout, restored on login)
- 2-column grid view with remove button

### 🎟 My Tickets
- All bookings fetched from MongoDB (login required)
- Delete ticket with confirmation dialog
- Refresh to sync with server

### 👤 Profile & Auth
- Register / Login with JWT authentication
- Upload profile photo from gallery
- Edit name & phone number
- Change password
- Booking history from database
- Add / remove payment methods
- Notifications toggle
- **Light / Dark theme** toggle
- **Amharic (አማርኛ) / English** language support
- Log Out (clears token and favorites)
- **Easter Egg**: tap About 5 times → developer info

---

## 🏗 System Architecture

```
┌─────────────────────────────────────────┐
│         Flutter Mobile App (Android)    │
└──────────────────┬──────────────────────┘
                   │ HTTP REST API
┌──────────────────▼──────────────────────┐
│       Node.js + Express Backend         │
│  /auth  /profile  /bookings  /upload    │
└──────────────────┬──────────────────────┘
                   │ Mongoose ODM
┌──────────────────▼──────────────────────┐
│         MongoDB Atlas (Cloud)           │
└─────────────────────────────────────────┘
```

---

## 🛠 Tech Stack

### Frontend
| Tool | Usage |
|------|-------|
| Flutter / Dart | Mobile UI framework |
| Provider | Theme & language state management |
| SharedPreferences | Local storage (token, favorites, settings) |
| youtube_player_flutter | Inline YouTube trailer |
| cached_network_image | Movie poster loading |
| qr_flutter | QR code generation |
| share_plus | Share ticket as image |
| screenshot | Capture ticket as PNG |
| path_provider | Downloads folder path |
| permission_handler | Storage & camera permissions |
| image_picker | Profile photo from gallery |
| http | REST API calls |

### Backend
| Tool | Usage |
|------|-------|
| Node.js + Express | REST API server |
| MongoDB Atlas | Cloud NoSQL database |
| Mongoose | Database modeling |
| JWT | Authentication tokens |
| bcryptjs | Password hashing |
| Multer | Profile image upload |
| dotenv | Environment variables |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- Node.js `>=18.x`
- MongoDB Atlas account (free tier)
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
SERVER_IP=YOUR_PC_IP_ADDRESS
MONGODB_URI=mongodb+srv://USERNAME:PASSWORD@cluster.mongodb.net/addiscinema
JWT_SECRET=your_secret_key
JWT_EXPIRES_IN=30d
```

```bash
npm run dev
```

> Make sure your phone and PC are on the same WiFi network.

---

## 📁 Project Structure

```
├── lib/
│   ├── data/
│   │   ├── movies_data.dart         # 14 movies
│   │   └── favorites_store.dart     # Persistent per-user favorites
│   ├── models/
│   │   ├── movie.dart
│   │   ├── ticket.dart
│   │   └── concession_item.dart
│   ├── providers/
│   │   └── app_settings.dart        # Theme + Amharic language
│   ├── services/
│   │   └── api_service.dart         # All backend API calls
│   └── screens/
│       ├── splash_screen.dart
│       ├── main_shell.dart          # 4-tab floating bottom nav
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

## 🔗 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login |
| GET | `/api/profile` | Get user profile |
| PUT | `/api/profile` | Update profile |
| PUT | `/api/profile/password` | Change password |
| GET | `/api/profile/bookings` | Get booking history |
| POST | `/api/profile/bookings` | Save new booking |
| DELETE | `/api/profile/bookings/:id` | Delete booking |
| GET | `/api/profile/payments` | Get payment methods |
| POST | `/api/profile/payments` | Add payment method |
| DELETE | `/api/profile/payments/:id` | Remove payment method |
| POST | `/api/upload/avatar` | Upload profile photo |

---

## 📊 Project Statistics

| Item | Count |
|------|-------|
| Screens | 13 |
| Movies | 14 (8 Now Showing, 6 Coming Soon) |
| Food & drink items | 16 |
| Ethiopian payment methods | 4 |
| API endpoints | 12 |
| Lines of code | ~3,500+ |

---

## 🔐 Security

- Passwords hashed with **bcryptjs** (12 salt rounds)
- JWT tokens expire after 30 days
- All profile/booking routes protected by auth middleware
- Buy Tickets requires authentication
- Favorites tied to user account

---

## 🔮 Future Improvements

- Deploy backend to cloud (Render / Railway)
- Real payment gateway integration
- Push notifications for booking reminders
- Movie search functionality
- Admin dashboard for cinema management
- iOS support

---

## 🔐 Easter Egg

Profile → Support → **About** — tap 5 times to reveal developer info.

---

## 👨‍💻 Developer

**Mikiyas Kifle**
- 📧 mykeykifle@gmail.com
- 📞 +251941162079
- 🔗 [GitHub](https://github.com/Mikiyaskifle/Addis_Cinema_Mobile_app)

---

## 📄 License

This project is for educational and portfolio purposes.
