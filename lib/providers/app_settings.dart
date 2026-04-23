import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._();
  static AppSettings get instance => _instance;
  AppSettings._();

  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'English'; // 'English' or 'Amharic'

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isAmharic => _language == 'Amharic';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme') ?? 'Dark';
    final lang = prefs.getString('language') ?? 'English';
    _themeMode = theme == 'Light' ? ThemeMode.light : ThemeMode.dark;
    _language = lang;
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    _themeMode = theme == 'Light' ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }

  // Translation helper
  String t(String key) {
    if (!isAmharic) return key;
    return _amharic[key] ?? key;
  }

  static const Map<String, String> _amharic = {
    // Nav
    'Movies': 'ፊልሞች',
    'Favorites': 'ተወዳጆች',
    'Tickets': 'ትኬቶች',
    'Profile': 'መገለጫ',
    // Movies screen
    'Now Showing': 'አሁን በማሳያ',
    'Coming Soon': 'በቅርቡ',
    'Today': 'ዛሬ',
    // Movie detail
    'Buy Tickets': 'ትኬት ግዛ',
    'Storyline': 'ታሪክ',
    'Directors': 'ዳይሬክተሮች',
    'Writers': 'ጸሐፊዎች',
    'More like this': 'ተመሳሳይ ፊልሞች',
    'Tap to play trailer': 'ትሬይለር ለማሳየት ጫን',
    'NEW TRAILER': 'አዲስ ትሬይለር',
    // Seats
    'Select Seats': 'መቀመጫ ምረጥ',
    'Screen': 'ስክሪን',
    'Available': 'ክፍት',
    'Taken': 'የተያዘ',
    'Selected': 'የተመረጠ',
    // Food
    'Food & Drinks': 'ምግብ እና መጠጥ',
    'Skip': 'ዝለል',
    'Confirm Order': 'ትዕዛዝ አረጋግጥ',
    'Continue': 'ቀጥል',
    // Payment
    'Payment': 'ክፍያ',
    'Secure Payment': 'ደህንነቱ የተጠበቀ ክፍያ',
    'Select a Payment Method': 'የክፍያ ዘዴ ምረጥ',
    'Choose Payment Method': 'የክፍያ ዘዴ ምረጥ',
    // Confirmation
    'Booking Confirmation': 'የቦታ ማስያዝ ማረጋገጫ',
    'Tickets Confirmed!': 'ትኬቶች ተረጋግጠዋል!',
    'Download Ticket': 'ትኬት አውርድ',
    'Share Ticket': 'ትኬት አጋራ',
    'Back to Home': 'ወደ መነሻ ተመለስ',
    // Profile
    'Edit Profile': 'መገለጫ አርትዕ',
    'Change Password': 'የይለፍ ቃል ቀይር',
    'Notifications': 'ማሳወቂያዎች',
    'Language': 'ቋንቋ',
    'Theme': 'ገጽታ',
    'Help & FAQ': 'እርዳታ',
    'Privacy Policy': 'የግላዊነት ፖሊሲ',
    'About': 'ስለ',
    'Log Out': 'ውጣ',
    'Sign In': 'ግባ',
    'Create Account': 'መለያ ፍጠር',
    'Saved Movies': 'የተቀመጡ ፊልሞች',
    'Booking History': 'የቦታ ማስያዝ ታሪክ',
    'Payment Methods': 'የክፍያ ዘዴዎች',
    'Account': 'መለያ',
    'Preferences': 'ምርጫዎች',
    'Support': 'ድጋፍ',
    'Dark': 'ጨለማ',
    'Light': 'ብርሃን',
    'Amharic': 'አማርኛ',
    'English': 'እንግሊዝኛ',
  };
}
