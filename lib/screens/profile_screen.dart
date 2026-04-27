import 'dart:async';
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
      setState(() { _user = jsonDecode(userStr); _loadingProfile = false; });
    } else {
      setState(() => _loadingProfile = false);
    }
    _refreshFromApi();
  }

  Future<void> _refreshFromApi() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) return;
      final profile = await ApiService.getProfile().timeout(const Duration(seconds: 8));
      if (profile['_id'] != null && mounted) {
        setState(() => _user = profile);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(profile));
      }
      final bookings = await ApiService.getBookings().timeout(const Duration(seconds: 8));
      final payments = await ApiService.getPaymentMethods().timeout(const Duration(seconds: 8));
      if (mounted) setState(() { _bookings = bookings; _payments = payments; });
    } catch (_) {}
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
    await FavoritesStore.instance.clear();
    if (mounted) Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _showEditProfile() {
    final nameCtrl = TextEditingController(text: _user?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: _user?['phone'] ?? '');
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: const Color(0xFF161625),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFFE5383B), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
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
                  const SnackBar(content: Text('✅ Profile updated'), backgroundColor: Color(0xFF1C1C1E), behavior: SnackBarBehavior.floating));
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
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: const Color(0xFF161625),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFFE5383B), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            const Text('Change Password', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
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

  Future<void> _pickAndUploadAvatar() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      final storage = await Permission.storage.request();
      if (!storage.isGranted) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery permission denied'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
        return;
      }
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (picked == null) return;
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading...'), backgroundColor: Color(0xFF1C1C1E), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 10)));
    try {
      final res = await ApiService.uploadAvatar(picked.path);
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (res['user'] != null) {
        setState(() => _user = res['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(res['user']));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile photo updated!'), backgroundColor: Color(0xFF1C1C1E), behavior: SnackBarBehavior.floating));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${res['message'] ?? 'Unknown error'}'), backgroundColor: Colors.red.shade900, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red.shade900, behavior: SnackBarBehavior.floating)); }
    }
  }

  void _showThemePicker(AppSettings s) {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF161625),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.t('Theme'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _themeOption(s, 'Dark', Icons.dark_mode_outlined),
          const SizedBox(height: 10),
          _themeOption(s, 'Light', Icons.light_mode_outlined),
          const SizedBox(height: 20),
        ])));
  }

  Widget _themeOption(AppSettings s, String theme, IconData icon) {
    final selected = (s.isDark && theme == 'Dark') || (!s.isDark && theme == 'Light');
    return GestureDetector(
      onTap: () { s.setTheme(theme); Navigator.pop(context); },
      child: Container(padding: const EdgeInsets.all(14),
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
        ])));
  }

  void _showLanguagePicker(AppSettings s) {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF161625),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.t('Language'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _langOption(s, 'English', '🇬🇧'),
          const SizedBox(height: 10),
          _langOption(s, 'Amharic', '🇪🇹'),
          const SizedBox(height: 20),
        ])));
  }

  Widget _langOption(AppSettings s, String lang, String flag) {
    final selected = s.language == lang;
    return GestureDetector(
      onTap: () { s.setLanguage(lang); Navigator.pop(context); },
      child: Container(padding: const EdgeInsets.all(14),
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
        ])));
  }

  void _showAddPayment() {
    final accountCtrl = TextEditingController();
    String selectedType = 'telebirr';
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: const Color(0xFF161625),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Payment Method', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Wrap(spacing: 8, children: ['telebirr', 'cbe', 'awash', 'abyssinia'].map((t) =>
            GestureDetector(onTap: () => setS(() => selectedType = t),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selectedType == t ? const Color(0xFFE5383B) : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(t.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))))).toList()),
          const SizedBox(height: 16),
          _sheetField('Account Number / Phone', accountCtrl, Icons.numbers),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.addPaymentMethod({'type': selectedType, 'accountNumber': accountCtrl.text, 'isDefault': _payments.isEmpty});
              _refreshFromApi();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5383B),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            child: const Text('Add Method', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
          const SizedBox(height: 20),
        ]))));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final favs = FavoritesStore.instance;
    final allMovies = [...nowShowingMovies, ...comingSoonMovies];
    final savedMovies = favs.getFavorites(allMovies);
    final isLoggedIn = _user != null;
    final avatarUrl = _user?['avatar'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5383B)))
          : CustomScrollView(
              slivers: [
                // ── Premium Header ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A0000), Color(0xFF2D0A0A), Color(0xFF0A0A0F)],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                        child: Column(children: [
                          // Avatar
                          Stack(children: [
                            Container(
                              width: 110, height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(colors: [Color(0xFFE5383B), Color(0xFF7B0000)]),
                                boxShadow: [BoxShadow(color: const Color(0xFFE5383B).withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
                              ),
                              padding: const EdgeInsets.all(3),
                              child: ClipOval(
                                child: avatarUrl.isNotEmpty
                                    ? CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Container(color: const Color(0xFF2A2A2A), child: const Icon(Icons.person, color: Colors.white38, size: 52)))
                                    : Container(color: const Color(0xFF2A2A2A), child: const Icon(Icons.person, color: Colors.white38, size: 52)),
                              ),
                            ),
                            if (isLoggedIn) Positioned(bottom: 2, right: 2,
                              child: GestureDetector(
                                onTap: _pickAndUploadAvatar,
                                child: Container(width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5383B), shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF0A0A0F), width: 2)),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 15)))),
                          ]),
                          const SizedBox(height: 14),
                          Text(isLoggedIn ? (_user!['name'] ?? 'User') : 'Welcome!',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          if (isLoggedIn) ...[
                            Text(_user!['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                            if ((_user!['phone'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(_user!['phone'], style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
                            ],
                          ] else
                            Text('Sign in to access your profile', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                          const SizedBox(height: 20),
                          // Stats row
                          if (isLoggedIn) Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _statCard('${_bookings.length}', 'Bookings', Icons.confirmation_number_outlined, const Color(0xFFE5383B)),
                              _statCard('${savedMovies.length}', 'Saved', Icons.bookmark_outlined, const Color(0xFF4A90D9)),
                              _statCard('${_payments.length}', 'Payments', Icons.credit_card_outlined, const Color(0xFF4CAF50)),
                            ],
                          ) else _buildGuestButtons(),
                        ]),
                      ),
                    ),
                  ),
                ),

                if (isLoggedIn) ...[
                  // ── Quick Actions ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Row(children: [
                        _quickAction(Icons.edit_outlined, 'Edit', _showEditProfile),
                        const SizedBox(width: 12),
                        _quickAction(Icons.lock_outline, 'Password', _showChangePassword),
                        const SizedBox(width: 12),
                        _quickAction(Icons.refresh, 'Refresh', () { _refreshFromApi(); }),
                      ]),
                    ),
                  ),

                  // ── Saved Movies ──────────────────────────────────────────
                  if (savedMovies.isNotEmpty) SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _sectionHeader('Saved Movies', '${savedMovies.length}'),
                        const SizedBox(height: 12),
                        SizedBox(height: 150, child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: savedMovies.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final m = savedMovies[i];
                            return GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: m))),
                              child: Stack(children: [
                                ClipRRect(borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(imageUrl: m.posterUrl, width: 100, height: 150, fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(width: 100, height: 150, color: const Color(0xFF2A2A2A), child: const Icon(Icons.movie, color: Colors.white30)))),
                                Positioned(top: 6, right: 6,
                                  child: GestureDetector(onTap: () => FavoritesStore.instance.toggle(m.id),
                                    child: Container(width: 26, height: 26,
                                      decoration: const BoxDecoration(color: Color(0xFFE5383B), shape: BoxShape.circle),
                                      child: const Icon(Icons.bookmark, color: Colors.white, size: 13)))),
                              ]),
                            );
                          },
                        )),
                      ]),
                    ),
                  ),

                  // ── Recent Bookings ───────────────────────────────────────
                  if (_bookings.isNotEmpty) SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _sectionHeader('Recent Bookings', '${_bookings.length}'),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(color: const Color(0xFF161625), borderRadius: BorderRadius.circular(16)),
                          child: Column(children: _bookings.take(3).toList().asMap().entries.map((e) {
                            final b = e.value;
                            final isLast = e.key == (_bookings.length > 3 ? 2 : _bookings.length - 1);
                            return Column(children: [
                              Padding(padding: const EdgeInsets.all(14), child: Row(children: [
                                Container(width: 42, height: 42,
                                  decoration: BoxDecoration(color: const Color(0xFFE5383B).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.confirmation_number_outlined, color: Color(0xFFE5383B), size: 20)),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(b['movieTitle'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('${b['date']} · ${b['time']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                ])),
                                Text('ETB ${(b['totalPrice'] ?? 0).toStringAsFixed(0)}',
                                  style: const TextStyle(color: Color(0xFFE5383B), fontWeight: FontWeight.bold, fontSize: 13)),
                              ])),
                              if (!isLast) Divider(height: 1, color: Colors.white.withOpacity(0.05), indent: 68),
                            ]);
                          }).toList()),
                        ),
                      ]),
                    ),
                  ),

                  // ── Payment Methods ───────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          _sectionHeader('Payment Methods', null),
                          GestureDetector(onTap: _showAddPayment,
                            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(color: const Color(0xFFE5383B).withOpacity(0.12), borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE5383B).withOpacity(0.3))),
                              child: const Text('+ Add', style: TextStyle(color: Color(0xFFE5383B), fontSize: 12, fontWeight: FontWeight.bold)))),
                        ]),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(color: const Color(0xFF161625), borderRadius: BorderRadius.circular(16)),
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
                                              onPressed: () async { await ApiService.removePaymentMethod(p['_id']); _refreshFromApi(); }),
                                    ),
                                    if (!isLast) Divider(height: 1, color: Colors.white.withOpacity(0.05), indent: 66),
                                  ]);
                                }).toList()),
                        ),
                      ]),
                    ),
                  ),

                  // ── Settings ──────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _sectionHeader('Preferences', null),
                        const SizedBox(height: 12),
                        _settingsCard([
                          _SettingsTile(Icons.language_outlined, s.t('Language'), trailing: s.t(s.language), onTap: () => _showLanguagePicker(s)),
                          _SettingsTile(s.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, s.t('Theme'), trailing: s.t(s.isDark ? 'Dark' : 'Light'), onTap: () => _showThemePicker(s)),
                        ]),
                        const SizedBox(height: 20),
                        _sectionHeader('Support', null),
                        const SizedBox(height: 12),
                        _settingsCard([
                          _SettingsTile(Icons.help_outline, s.t('Help & FAQ'), onTap: () {}),
                          _SettingsTile(Icons.privacy_tip_outlined, s.t('Privacy Policy'), onTap: () {}),
                          _SettingsTile(Icons.info_outline, s.t('About'), onTap: _onAboutTap),
                        ]),
                      ]),
                    ),
                  ),

                  // ── Logout ────────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Color(0xFFE5383B), size: 18),
                        label: const Text('Log Out', style: TextStyle(color: Color(0xFFE5383B), fontWeight: FontWeight.bold, fontSize: 15)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5383B), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                  ),
                ],

                if (!isLoggedIn) const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF161625),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(color: const Color(0xFFE5383B).withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: const Color(0xFFE5383B), size: 20)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String? count) {
    return Row(children: [
      Container(width: 3, height: 16, decoration: BoxDecoration(color: const Color(0xFFE5383B), borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      if (count != null) ...[
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFFE5383B), borderRadius: BorderRadius.circular(10)),
          child: Text(count, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
      ],
    ]);
  }

  Widget _settingsCard(List<_SettingsTile> tiles) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF161625), borderRadius: BorderRadius.circular(16)),
      child: Column(children: tiles.asMap().entries.map((e) {
        final isLast = e.key == tiles.length - 1;
        return Column(children: [
          e.value,
          if (!isLast) Divider(height: 1, color: Colors.white.withOpacity(0.05), indent: 52),
        ]);
      }).toList()),
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
      const SizedBox(height: 10),
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
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  const _SettingsTile(this.icon, this.label, {this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white54, size: 18)),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
          if (trailing != null) Text(trailing!, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
        ])),
    );
  }
}
