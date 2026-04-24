import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'data/favorites_store.dart';
import 'providers/app_settings.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  await FavoritesStore.instance.load(); // load saved favorites
  runApp(const AddisCinemaApp());
}

class AddisCinemaApp extends StatelessWidget {
  const AddisCinemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: FavoritesStore.instance),
        ChangeNotifierProvider.value(value: AppSettings.instance),
      ],
      child: Consumer<AppSettings>(
        builder: (_, settings, __) => MaterialApp(
          title: 'AddisCinema',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          // Dark theme
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0D0D0D),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE5383B),
              surface: Color(0xFF1A1A1A),
            ),
            appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
          ),
          // Light theme
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE5383B),
              surface: Colors.white,
            ),
            appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
            cardColor: Colors.white,
          ),
          // Localization
          locale: settings.isAmharic ? const Locale('am') : const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('am')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
