# 🎬 AddisCinema

A full-featured cinema booking mobile app built with Flutter. AddisCinema lets users browse movies, watch trailers inline, select seats, and receive QR-coded tickets — all in a sleek dark-themed UI.

---

## ✨ Features

- **Splash Screen** — Animated cinematic intro with spinning film reels and light beams
- **Movies Screen** — Horizontal carousel with dynamic background color per movie, Now Showing / Coming Soon tabs, and genre filter chips
- **Movie Detail** — Inline YouTube trailer, ratings (IMDB / Rotten Tomatoes / IGN), cast, storyline, and "More like this" section
- **Seat Selection** — Interactive seat grid with time slots, screen types (Extreme 3D, Realt 3D, etc.), and live price calculation
- **Booking Confirmation** — Full ticket card with movie info, seat labels, booking ID, QR code for entry, and a Share button
- **Favorites** — Bookmark any movie and view them in a 2-column grid
- **My Tickets** — View all booked tickets with dashed ticket card design
- **Profile** — User stats, saved movies, booking history, payment methods, settings, and a hidden developer easter egg
- **App Icon** — Custom film-strip ticket icon for Android and Chrome

---

## 📱 Screenshots

> Coming soon

---

## 🛠 Tech Stack

| Tool | Usage |
|------|-------|
| Flutter | UI framework |
| youtube_player_flutter | Inline YouTube trailer playback |
| cached_network_image | Efficient image loading |
| qr_flutter | QR code generation for tickets |
| share_plus | Native share sheet for tickets |
| url_launcher | Open links externally |
| flutter_launcher_icons | App icon generation |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- Android device or emulator (minSdk 21)

### Run the app

```bash
git clone https://github.com/YOUR_USERNAME/addis-cinema.git
cd addis-cinema
flutter pub get
flutter run
```

---

## 📁 Project Structure

```
lib/
├── data/
│   ├── movies_data.dart       # Movie data (14 movies)
│   └── favorites_store.dart   # Global favorites state
├── models/
│   ├── movie.dart             # Movie & CastMember models
│   └── ticket.dart            # Ticket model
└── screens/
    ├── splash_screen.dart
    ├── main_shell.dart        # Bottom nav shell
    ├── movies_screen.dart
    ├── movie_detail_screen.dart
    ├── select_seats_screen.dart
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
