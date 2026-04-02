import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/favorites_store.dart';
import '../data/movies_data.dart';
import '../models/movie.dart';
import 'movie_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _aboutTapCount = 0;

  void _onAboutTap() {
    setState(() => _aboutTapCount++);
    if (_aboutTapCount >= 5) {
      _aboutTapCount = 0;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.code, color: Color(0xFFE5383B), size: 22),
            SizedBox(width: 8),
            Text('Developer', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2A2A2A),
                  border: Border.all(color: const Color(0xFFE5383B), width: 2),
                ),
                child: const Icon(Icons.person, color: Colors.white38, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('Mikiyas Kifle',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _devInfoRow(Icons.email_outlined, 'mykeykifle@gmail.com'),
              const SizedBox(height: 10),
              _devInfoRow(Icons.phone_outlined, '+251941162079'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFFE5383B), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  Widget _devInfoRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(icon, color: const Color(0xFFE5383B), size: 18),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoritesStore.instance,
      builder: (context, _) {
        final favs = FavoritesStore.instance;
        final allMovies = [...nowShowingMovies, ...comingSoonMovies];
        final savedMovies = favs.getFavorites(allMovies);
        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildAvatar(),
                const SizedBox(height: 16),
                const Text('[User Name]', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('[user@email.com]', style: TextStyle(color: Colors.white38, fontSize: 14)),
                const SizedBox(height: 32),
                _buildStatsRow(savedMovies.length),
                const SizedBox(height: 32),
                if (savedMovies.isNotEmpty) ...[
                  _buildSavedMovies(context, savedMovies),
                  const SizedBox(height: 28),
                ],
                _buildSection('Account', [
                  _MenuItem(Icons.person_outline, 'Edit Profile', onTap: () {}),
                  _MenuItem(Icons.notifications_outlined, 'Notifications', onTap: () {}),
                  _MenuItem(Icons.lock_outline, 'Change Password', onTap: () {}),
                ]),
                const SizedBox(height: 20),
                _buildSection('Booking History', [
                  _MenuItem(Icons.confirmation_number_outlined, 'Spider-Man', trailing: 'Jun 5 · 2 seats', onTap: () {}),
                  _MenuItem(Icons.confirmation_number_outlined, 'Guardians Vol.3', trailing: 'Jun 10 · 3 seats', onTap: () {}),
                ]),
                const SizedBox(height: 20),
                _buildSection('Payment Methods', [
                  _MenuItem(Icons.credit_card_outlined, 'Visa •••• 4242', trailing: 'Default', onTap: () {}),
                  _MenuItem(Icons.add_circle_outline, 'Add Payment Method', onTap: () {}),
                ]),
                const SizedBox(height: 20),
                _buildSection('Preferences', [
                  _MenuItem(Icons.language_outlined, 'Language', trailing: 'English', onTap: () {}),
                  _MenuItem(Icons.dark_mode_outlined, 'Theme', trailing: 'Dark', onTap: () {}),
                ]),
                const SizedBox(height: 20),
                _buildSection('Support', [
                  _MenuItem(Icons.help_outline, 'Help & FAQ', onTap: () {}),
                  _MenuItem(Icons.privacy_tip_outlined, 'Privacy Policy', onTap: () {}),
                  _MenuItem(Icons.info_outline, 'About', onTap: _onAboutTap),
                ]),
                const SizedBox(height: 20),
                _buildLogoutButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2A2A2A),
            border: Border.all(color: const Color(0xFFE5383B), width: 2),
          ),
          child: const Icon(Icons.person, color: Colors.white38, size: 48),
        ),
        Positioned(
          bottom: 0, right: 0,
          child: Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(color: Color(0xFFE5383B), shape: BoxShape.circle),
            child: const Icon(Icons.edit, color: Colors.white, size: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(int savedCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('12', 'Movies\nWatched'),
          Container(width: 1, height: 40, color: Colors.white12),
          _statItem('5', 'Upcoming\nTickets'),
          Container(width: 1, height: 40, color: Colors.white12),
          _statItem('$savedCount', 'Saved\nMovies'),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11), textAlign: TextAlign.center),
    ]);
  }

  Widget _buildSavedMovies(BuildContext context, List<Movie> movies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Saved Movies', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${movies.length} movies', style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final m = movies[i];
              return GestureDetector(
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: m))),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: m.posterUrl,
                        width: 110, height: 160, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 110, height: 160,
                          color: const Color(0xFF2A2A2A),
                          child: const Icon(Icons.movie, color: Colors.white30),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6, right: 6,
                      child: GestureDetector(
                        onTap: () => FavoritesStore.instance.toggle(m.id),
                        child: Container(
                          width: 28, height: 28,
                          decoration: const BoxDecoration(color: Color(0xFFE5383B), shape: BoxShape.circle),
                          child: const Icon(Icons.bookmark, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(children: [
                e.value,
                if (!isLast) Divider(height: 1, color: Colors.white.withOpacity(0.06), indent: 52),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
      child: _MenuItem(Icons.logout, 'Log Out',
        iconColor: const Color(0xFFE5383B),
        textColor: const Color(0xFFE5383B),
        showArrow: false,
        onTap: () {},
      ),
    );
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
    this.trailing,
    this.iconColor = Colors.white60,
    this.textColor = Colors.white,
    this.showArrow = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(color: textColor, fontSize: 15))),
          if (trailing != null) Text(trailing!, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          if (showArrow) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ]),
      ),
    );
  }
}
