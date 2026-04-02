# 🎬 AddisCinema

A full-featured cinema booking mobile app built with Flutter. AddisCinema lets users browse movies, watch trailers inline, select seats, order food & drinks, and receive QR-coded tickets — all in a sleek dark-themed UI.

---

## ✨ Features

- **Splash Screen** — Animated cinematic intro with spinning film reels and light beams
- **Movies Screen** — Horizontal carousel with dynamic background color per movie, Now Showing / Coming Soon tabs, and genre filter chips
- **Movie Detail** — Inline YouTube trailer, ratings (IMDB / Rotten Tomatoes / IGN), cast, storyline, and "More like this" section
- **Seat Selection** — Interactive seat grid with time slots, screen types (Extreme 3D, Realt 3D, etc.), and live ETB price calculation
- **Food & Drinks** — Pre-order Ethiopian & international snacks and drinks before confirming booking
- **Booking Confirmation** — Movie poster banner, date/time/seat details, QR code for entry, Download & Share ticket buttons, Parking & Calendar tiles
- **Favorites** — Bookmark any movie and view them in a 2-column grid
- **My Tickets** — View all booked tickets with dashed ticket card design
- **Profile** — User stats, saved movies, booking history, payment methods, settings, and a hidden developer easter egg
- **App Icon** — Custom film-strip ticket icon for Android and Chrome
- **ETB Currency** — All prices displayed in Ethiopian Birr

---

## 📱 Screens

| Screen | Description |
|--------|-------------|
| Splash | Animated cinematic intro |
| Movies | Carousel with genre filter |
| Movie Detail | Trailer + full info |
| Select Seats | Interactive seat grid |
| Food & Drinks | Pre-order concessions |
| Booking Confirmation | QR ticket + share |
| Favorites | Saved movies grid |
| My Tickets | Booking history |
| Profile | User settings + easter egg |

---

## � Tech Stack

| Tool | Usage |
|------|-------|
| Flutter | UI framework |
| youtube_player_flutter | Inline YouTube trailer playback |
| cached_network_image | Efficient image loading |
| qr_flutter | QR code generation for tickets |
| share_plus | Native share sheet for tickets |
| url_launcher | Open links externally |
| flutter_launcher_icons | App icon generation |
| flutter_inappwebview | WebView support |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- Android device or emulator (minSdk 21)

### Run the app

```bash
git clone https://github.com/Mikiyaskifle/Addis_Cinema_Mobile_app.git
cd Addis_Cinema_Mobile_app
flutter pub get
flutter run
```

---

## 📁 Project Structure

```
lib/
├── data/
│   ├── movies_data.dart         # 14 movies (8 now showing, 6 coming soon)
│   └── favorites_store.dart     # Global favorites state
├── models/
│   ├── movie.dart               # Movie & CastMember models
│   ├── ticket.dart              # Ticket model
│   └── concession_item.dart     # Food & drinks model
└── screens/
    ├── splash_screen.dart
    ├── main_shell.dart          # 4-tab floating bottom nav
    ├── movies_screen.dart
    ├── movie_detail_screen.dart
    ├── select_seats_screen.dart
    ├── concession_screen.dart   # Food & drinks ordering
    ├── booking_confirmation_screen.dart
    ├── favorites_screen.dart
    ├── tickets_screen.dart
    └── profile_screen.dart
```

---

## 🔐 Easter Egg

Go to **Profile → Support → About** and tap it **5 times** to reveal the developer info.

---

## 👨‍💻 Developer

**Mikiyas Kifle**
- 📧 mykeykifle@gmail.com
- 📞 +251941162079

---

## 📄 License

This project is for educational and portfolio purposes.
