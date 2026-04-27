import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'login_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});
  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  List<dynamic> _bookings = [];
  bool _loading = true;
  bool _isLoggedIn = false;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final token = await ApiService.getToken();
    if (token == null) {
      setState(() { _isLoggedIn = false; _loading = false; });
      return;
    }
    setState(() => _isLoggedIn = true);
    try {
      // Load user name
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      if (userStr != null) {
        final user = jsonDecode(userStr);
        setState(() => _userName = user['name'] ?? '');
      }
      final bookings = await ApiService.getBookings();
      setState(() { _bookings = bookings; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteBooking(int index) async {
    final booking = _bookings[index];
    final id = booking['_id']?.toString();

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Delete your ticket for "${booking['movieTitle']}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _bookings.removeAt(index));
    if (id != null) {
      try { await ApiService.deleteBooking(id); } catch (_) {}
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ticket deleted'),
        backgroundColor: Color(0xFF1C1C1E), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('My Tickets',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white54, size: 20),
              onPressed: () { setState(() => _loading = true); _loadBookings(); },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5383B)))
          : !_isLoggedIn
              ? _buildLoginPrompt()
              : _bookings.isEmpty
                  ? _buildEmpty()
                  : Column(
                  children: [
                    // User greeting
                    if (_userName.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          const Icon(Icons.person_outline, color: Color(0xFFE5383B), size: 20),
                          const SizedBox(width: 10),
                          Text('Welcome, $_userName',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text('${_bookings.length} ticket${_bookings.length != 1 ? 's' : ''}',
                            style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        ]),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookings.length,
                        itemBuilder: (_, i) => _TicketCard(
                          booking: _bookings[i],
                          userName: _userName,
                          onDelete: () => _deleteBooking(i),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock_outline, color: Colors.white24, size: 64),
        const SizedBox(height: 16),
        const Text('Sign in to view your tickets',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Your bookings will appear here after login',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const LoginScreen()))
              .then((_) => _loadBookings()),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE5383B),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.confirmation_number_outlined, color: Colors.white24, size: 72),
        const SizedBox(height: 16),
        const Text('No tickets yet', style: TextStyle(color: Colors.white38, fontSize: 16)),
        const SizedBox(height: 8),
        Text('Book a movie to see your tickets here',
            style: TextStyle(color: Colors.white24, fontSize: 13)),
      ]),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String userName;
  final VoidCallback onDelete;
  const _TicketCard({required this.booking, required this.userName, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final seats = (booking['seats'] as List?)?.join(', ') ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: booking['moviePoster'] != null
                  ? Image.network(booking['moviePoster'], width: 50, height: 70, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(booking['movieTitle'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5383B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(booking['screenType'] ?? '',
                    style: const TextStyle(color: Color(0xFFE5383B), fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ])),
            // Delete button
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade800.withOpacity(0.4)),
                ),
                child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
              ),
            ),
          ]),
        ),
        // Details
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _row(Icons.calendar_today_outlined, 'Date', booking['date'] ?? ''),
            const SizedBox(height: 10),
            _row(Icons.access_time, 'Time', booking['time'] ?? ''),
            const SizedBox(height: 10),
            _row(Icons.chair_alt_rounded, 'Seats', seats),
            const SizedBox(height: 10),
            _row(Icons.confirmation_number_outlined, 'Booking ID', booking['bookingId'] ?? ''),
          ]),
        ),
        _dashedDivider(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            // User info + total
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Ticket Holder', style: TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 4),
                Text(userName.isNotEmpty ? userName : 'Guest',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Total', style: TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 4),
                Text('ETB ${(booking['totalPrice'] ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(color: Color(0xFFE5383B), fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
            ),
            // QR Code
            Column(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: QrImageView(
                  data: 'AddisCinema|${booking['movieTitle'] ?? ''}|${booking['date'] ?? ''}|${booking['time'] ?? ''}|${(booking['seats'] as List?)?.join(",") ?? ''}|${booking['bookingId'] ?? ''}',
                  version: QrVersions.auto,
                  size: 90,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text('Scan at entry', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _placeholder() => Container(width: 50, height: 70, color: const Color(0xFF3A3A3A),
      child: const Icon(Icons.movie, color: Colors.white30, size: 24));

  Widget _row(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: const Color(0xFFE5383B), size: 16),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      const Spacer(),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _dashedDivider() {
    return Row(children: [
      Container(width: 20, height: 20,
          decoration: const BoxDecoration(color: Color(0xFF0D0D0D),
              borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)))),
      Expanded(child: LayoutBuilder(builder: (_, c) {
        const dw = 5.0, ds = 4.0;
        final count = (c.maxWidth / (dw + ds)).floor();
        return Row(children: List.generate(count, (_) =>
            Container(width: dw, height: 1, margin: const EdgeInsets.only(right: ds), color: Colors.white12)));
      })),
      Container(width: 20, height: 20,
          decoration: const BoxDecoration(color: Color(0xFF0D0D0D),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)))),
    ]);
  }
}
