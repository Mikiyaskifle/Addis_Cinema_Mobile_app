import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../data/favorites_store.dart';
import '../data/movies_data.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../providers/app_settings.dart';
import 'movie_detail_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _aboutTapCount = 0;
  Map<String, dynamic>? _user;
  List<dynamic> _bookings = [];
  List<dynamic> _payments = [];
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      setState(() => _user = jsonDecode(userStr));
    }
    // Try to fetch fresh from API
    try {
      final profile = await ApiService.getProfile();
      if (profile['_id'] != null) {
        setState(() => _user = profile);
        await prefs.setString('user', jsonEncode(profile));
      }
      final bookings = await ApiService.getBookings();
      final payments = await ApiService.getPaymentMethods();
      setState(() { _bookings = bookings; _payments = payments; });
    } catch (_) {}
    setState(() => _loadingProfile = false);
  }

  void _onAboutTap() {
    setState(() => _aboutTapCount++);
    if (_aboutTapCount >= 5) {
      _aboutTapCount = 0;
      showDialog(context: context, builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.code, color: Color(0xFFE5383B), size: 22),
          SizedBox(width: 8),
          Text('Developer', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 70, height: 70,
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF2A2A2A),
              border: Border.all(color: const Color(0xFFE5383B), width: 2)),
            child: const Icon(Icons.person, color: Colors.white38, size: 40)),
          const SizedBox(height: 16),
          const Text('Mikiyas Kifle', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _devInfoRow(Icons.email_outlined, 'mykeykifle@gmail.com'),
          const SizedBox(height: 10),
          _devInfoRow(Icons.phone_outlined, '+251941162079'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Color(0xFFE5383B), fontWeight: FontWeight.bold)))],
      ));
    }
  }

  Widget _devInfoRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, color: const Color(0xFFE5383B), size: 18),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ]),
    );
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    await FavoritesStore.instance.clear(); // clear favorites on logout
    if (mounted) Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _showEditProfile() {
    final nameCtrl = TextEditingController(text: _user?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: _user?['phone'] ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _sheetField('Full Name', nameCtrl, Icons.person_outline),
          const SizedBox(height: 14),
          _sheetField('Phone', phoneCtrl, Icons.phone_outlined),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final updated = await ApiService.updateProfile({'name': nameCtrl.text, 'phone': phoneCtrl.text});
                setState(() => _user = updated);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user', jsonEncode(updated));
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated'), backgroundColor: Color(0xFF1C1C1E), behavior: SnackBarBehavior.floating));
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5383B),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _showChangePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Change Password', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _sheetField('Current Password', currentCtrl, Icons.lock_outline, obscure: true),
          const SizedBox(height: 14),
          _sheetField('New Password', newCtrl, Icons.lock_outline, obscure: true),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final res = await ApiService.changePassword(currentPassword: currentCtrl.text, newPassword: newCtrl.text);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['message'] ?? 'Password changed'),
                    backgroundColor: const Color(0xFF1C1C1E), behavior: SnackBarBehavior.floating));
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5383B),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            child: const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _sheetField(String label, TextEditingController ctrl, IconData icon, {bool obscure = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          filled: true, fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5383B))),
        )),
    ]);
  }

  void _showThemePicker(AppSettings s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.t('Theme'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _themeOption(s, 'Dark', Icons.dark_mode_outlined),
          const SizedBox(height: 10),
          _themeOption(s, 'Light', Icons.light_mode_outlined),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _themeOption(AppSettings s, String theme, IconData icon) {
    final selected = (s.isDark && theme == 'Dark') || (!s.isDark && theme == 'Light');
    return GestureDetector(
      onTap: () { s.setTheme(theme); Navigator.pop(context); },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE5383B).withOpacity(0.1) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? const Color(0xFFE5383B) : Colors.transparent)),
        child: Row(children: [
          Icon(icon, color: selected ? const Color(0xFFE5383B) : Colors.white54, size: 22),
          const SizedBox(width: 14),
          Text(s.t(theme), style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 15, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          if (selected) const Icon(Icons.check_circle, color: Color(0xFFE5383B), size: 20),
        ]),
      ),
    );
  }

  void _showLanguagePicker(AppSettings s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.t('Language'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _langOption(s, 'English', '🇬🇧'),
          const SizedBox(height: 10),
          _langOption(s, 'Amharic', '🇪🇹'),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _langOption(AppSettings s, String lang, String flag) {
    final selected = s.language == lang;
    return GestureDetector(
      onTap: () { s.setLanguage(lang); Navigator.pop(context); },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE5383B).withOpacity(0.1) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? const Color(0xFFE5383B) : Colors.transparent)),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Text(lang, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 15, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          if (selected) const Icon(Icons.check_circle, color: Color(0xFFE5383B), size: 20),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return ListenableBuilder(
      listenable: FavoritesStore.instance,
      builder: (context, _) {
        final favs = FavoritesStore.instance;
        final allMovies = [...nowShowingMovies, ...comingSoonMovies];
        final savedMovies = favs.getFavorites(allMovies);
        final isLoggedIn = _user != null;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          appBar: AppBar(
            backgroundColor: Colors.transparent, elevation: 0,
            title: Text(s.t('Profile'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            centerTitle: true,
            actions: [
              if (isLoggedIn) IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white54, size: 20),
                onPressed: _loadUser,
              ),
            ],
          ),
          body: _loadingProfile
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5383B)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    const SizedBox(height: 12),
                    _buildAvatar(isLoggedIn),
                    const SizedBox(height: 16),
                    Text(isLoggedIn ? (_user!['name'] ?? 'User') : 'Guest',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(isLoggedIn ? (_user!['email'] ?? '') : 'Sign in to access your profile',
                      style: TextStyle(color: Colors.white38, fontSize: 14)),
                    if (isLoggedIn && (_user!['phone'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(_user!['phone'], style: TextStyle(color: Colors.white38, fontSize: 13)),
                    ],
                    const SizedBox(height: 24),
                    if (!isLoggedIn) _buildGuestButtons() else ...[
                      _buildStatsRow(savedMovies.length),
                      const SizedBox(height: 24),
                      if (savedMovies.isNotEmpty) ...[
                        _buildSavedMovies(context, savedMovies),
                        const SizedBox(height: 24),
                      ],
                      if (_bookings.isNotEmpty) ...[
                        _buildBookingHistory(),
                        const SizedBox(height: 24),
                      ],
                      _buildSection(s.t('Account'), [
                        _MenuItem(Icons.person_outline, s.t('Edit Profile'), onTap: _showEditProfile),
                        _MenuItem(Icons.notifications_outlined, s.t('Notifications'),
                          trailing: (_user?['notifications'] == true) ? 'On' : 'Off',
                          onTap: () async {
                            final newVal = !(_user?['notifications'] ?? true);
                            final updated = await ApiService.updateProfile({'notifications': newVal});
                            setState(() => _user = updated);
                          }),
                        _MenuItem(Icons.lock_outline, s.t('Change Password'), onTap: _showChangePassword),
                      ]),
                      const SizedBox(height: 20),
                      _buildPaymentSection(),
                      const SizedBox(height: 20),
                      _buildSection(s.t('Preferences'), [
                        _MenuItem(Icons.language_outlined, s.t('Language'),
                          trailing: s.t(s.language),
                          onTap: () => _showLanguagePicker(s)),
                        _MenuItem(Icons.dark_mode_outlined, s.t('Theme'),
                          trailing: s.t(s.isDark ? 'Dark' : 'Light'),
                          onTap: () => _showThemePicker(s)),
                      ]),
                      const SizedBox(height: 20),
                      _buildSection(s.t('Support'), [
                        _MenuItem(Icons.help_outline, s.t('Help & FAQ'), onTap: () {}),
                        _MenuItem(Icons.privacy_tip_outlined, s.t('Privacy Policy'), onTap: () {}),
                        _MenuItem(Icons.info_outline, s.t('About'), onTap: _onAboutTap),
                      ]),
                      const SizedBox(height: 20),
                      _buildLogoutButton(),
                    ],
                    const SizedBox(height: 32),
                  ]),
                ),
        );
      },
    );
  }

  Widget _buildGuestButtons() {
    return Column(children: [
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5383B),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
        child: const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      )),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: OutlinedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
        child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      )),
    ]);
  }

  Future<void> _pickAndUploadAvatar() async {
    // Request permission first
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      final storage = await Permission.storage.request();
      if (!storage.isGranted) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery permission denied'),
            backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
        return;
      }
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null) return;

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading...'),
        backgroundColor: Color(0xFF1C1C1E), behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 10)));

    try {
      final res = await ApiService.uploadAvatar(picked.path);
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (res['user'] != null) {
        setState(() => _user = res['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(res['user']));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile photo updated!'),
            backgroundColor: Color(0xFF1C1C1E), behavior: SnackBarBehavior.floating));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${res['message'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red.shade900, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'),
            backgroundColor: Colors.red.shade900, behavior: SnackBarBehavior.floating));
      }
    }
  }

  Widget _buildAvatar(bool isLoggedIn) {
    final avatarUrl = _user?['avatar'] ?? '';
    return Stack(children: [
      Container(width: 90, height: 90,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: const Color(0xFF2A2A2A),
          border: Border.all(color: const Color(0xFFE5383B), width: 2)),
        child: ClipOval(
          child: avatarUrl.isNotEmpty
              ? CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(Icons.person, color: Colors.white38, size: 48))
              : const Icon(Icons.person, color: Colors.white38, size: 48),
        )),
      if (isLoggedIn) Positioned(bottom: 0, right: 0,
        child: GestureDetector(
          onTap: _pickAndUploadAvatar,
          child: Container(width: 28, height: 28,
            decoration: const BoxDecoration(color: Color(0xFFE5383B), shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14)))),
    ]);
  }

  Widget _buildStatsRow(int savedCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _statItem('${_bookings.length}', 'Bookings'),
        Container(width: 1, height: 40, color: Colors.white12),
        _statItem('$savedCount', 'Saved'),
        Container(width: 1, height: 40, color: Colors.white12),
        _statItem('${_payments.length}', 'Payments'),
      ]),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
    ]);
  }

  Widget _buildSavedMovies(BuildContext context, List<Movie> movies) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Saved Movies', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text('${movies.length} movies', style: const TextStyle(color: Colors.white38, fontSize: 13)),
      ]),
      const SizedBox(height: 12),
      SizedBox(height: 160, child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final m = movies[i];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: m))),
            child: Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(imageUrl: m.posterUrl, width: 110, height: 160, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(width: 110, height: 160, color: const Color(0xFF2A2A2A),
                    child: const Icon(Icons.movie, color: Colors.white30)))),
              Positioned(top: 6, right: 6,
                child: GestureDetector(
                  onTap: () => FavoritesStore.instance.toggle(m.id),
                  child: Container(width: 28, height: 28,
                    decoration: const BoxDecoration(color: Color(0xFFE5383B), shape: BoxShape.circle),
                    child: const Icon(Icons.bookmark, color: Colors.white, size: 14)))),
            ]),
          );
        },
      )),
    ]);
  }

  Widget _buildBookingHistory() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Booking History', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Container(decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
        child: Column(children: _bookings.take(3).toList().asMap().entries.map((e) {
          final b = e.value;
          final isLast = e.key == (_bookings.length > 3 ? 2 : _bookings.length - 1);
          return Column(children: [
            Padding(padding: const EdgeInsets.all(14), child: Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFFE5383B).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.confirmation_number_outlined, color: Color(0xFFE5383B), size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b['movieTitle'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${b['date']} · ${b['time']} · ${b['screenType']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ])),
              Text('ETB ${b['totalPrice']?.toStringAsFixed(0) ?? '0'}', style: const TextStyle(color: Color(0xFFE5383B), fontWeight: FontWeight.bold, fontSize: 13)),
            ])),
            if (!isLast) Divider(height: 1, color: Colors.white.withOpacity(0.06), indent: 66),
          ]);
        }).toList()),
      ),
    ]);
  }

  Widget _buildPaymentSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Payment Methods', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
        GestureDetector(
          onTap: _showAddPayment,
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFE5383B).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: const Text('+ Add', style: TextStyle(color: Color(0xFFE5383B), fontSize: 12, fontWeight: FontWeight.bold))),
        ),
      ]),
      const SizedBox(height: 10),
      Container(decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
        child: _payments.isEmpty
            ? const Padding(padding: EdgeInsets.all(16),
                child: Text('No payment methods added', style: TextStyle(color: Colors.white38, fontSize: 13)))
            : Column(children: _payments.asMap().entries.map((e) {
                final p = e.value;
                final isLast = e.key == _payments.length - 1;
                return Column(children: [
                  ListTile(
                    leading: Container(width: 40, height: 40,
                      decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.credit_card, color: Colors.white54, size: 20)),
                    title: Text(p['type']?.toString().toUpperCase() ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(p['accountNumber'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    trailing: p['isDefault'] == true
                        ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFE5383B).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                            child: const Text('Default', style: TextStyle(color: Color(0xFFE5383B), fontSize: 10, fontWeight: FontWeight.bold)))
                        : IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 18),
                            onPressed: () async {
                              await ApiService.removePaymentMethod(p['_id']);
                              _loadUser();
                            }),
                  ),
                  if (!isLast) Divider(height: 1, color: Colors.white.withOpacity(0.06), indent: 66),
                ]);
              }).toList()),
      ),
    ]);
  }

  void _showAddPayment() {
    final accountCtrl = TextEditingController();
    String selectedType = 'telebirr';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Payment Method', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Wrap(spacing: 8, children: ['telebirr', 'cbe', 'awash', 'abyssinia'].map((t) =>
            GestureDetector(
              onTap: () => setS(() => selectedType = t),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selectedType == t ? const Color(0xFFE5383B) : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(t.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
            )).toList()),
          const SizedBox(height: 16),
          _sheetField('Account Number / Phone', accountCtrl, Icons.numbers),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.addPaymentMethod({'type': selectedType, 'accountNumber': accountCtrl.text, 'isDefault': _payments.isEmpty});
              _loadUser();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5383B),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            child: const Text('Add Method', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
          const SizedBox(height: 20),
        ]),
      )),
    );
  }

  Widget _buildSection(String title, List<_MenuItem> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 10),
      Container(decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
        child: Column(children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(children: [
            e.value,
            if (!isLast) Divider(height: 1, color: Colors.white.withOpacity(0.06), indent: 52),
          ]);
        }).toList())),
    ]);
  }

  Widget _buildLogoutButton() {
    return Container(decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
      child: _MenuItem(Icons.logout, 'Log Out',
        iconColor: const Color(0xFFE5383B), textColor: const Color(0xFFE5383B),
        showArrow: false, onTap: _logout));
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final Color iconColor;
  final Color textColor;
  final bool showArrow;
  final VoidCallback onTap;

  const _MenuItem(this.icon, this.label, {
    this.trailing, this.iconColor = Colors.white60,
    this.textColor = Colors.white, this.showArrow = true, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(color: textColor, fontSize: 15))),
          if (trailing != null) Text(trailing!, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          if (showArrow) ...[const SizedBox(width: 6), const Icon(Icons.chevron_right, color: Colors.white24, size: 18)],
        ])),
    );
  }
}
