import 'package:flutter/material.dart';
import 'data/favorites_store.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const AddisCinemaApp());
}

class AddisCinemaApp extends StatelessWidget {
  const AddisCinemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoritesStore.instance,
      builder: (_, __) => MaterialApp(
        title: 'AddisCinema',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE5383B),
            surface: Color(0xFF1A1A1A),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
