import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/movie.dart';
import 'main_shell.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Movie movie;
  final String date;
  final String time;
  final String screenType;
  final List<int> seatIndices;
  final double totalPrice;

  const BookingConfirmationScreen({
    super.key,
    required this.movie,
    required this.date,
    required this.time,
    required this.screenType,
    required this.seatIndices,
    required this.totalPrice,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _showTicket = false;

  List<String> get _seatLabels {
    const rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    return widget.seatIndices.map((i) => '${rows[i ~/ 9]}${(i % 9) + 1}').toList();
  }

  String get _qrData =>
      'AddisCinema|${widget.movie.title}|${widget.date}|${widget.time}|${_seatLabels.join(",")}|€${widget.totalPrice.toStringAsFixed(2)}';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _showTicket = true);
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _shareTicket() {
    Share.share(
      'My AddisCinema Ticket 🎬\n'
      'Movie: ${widget.movie.title}\n'
      'Date: ${widget.date}\n'
      'Time: ${widget.time}\n'
      'Seats: ${_seatLabels.join(", ")}\n'
      'Screen: ${widget.screenType}\n'
      'Total: €${widget.totalPrice.toStringAsFixed(2)}\n\n'
      'See you at the cinema!',
      subject: 'AddisCinema Ticket - ${widget.movie.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5383B),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _showTicket ? _buildTicketView() : _buildLoadingView(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      key: ValueKey('loading'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          SizedBox(height: 20),
          Text('Confirming your booking...', style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTicketView() {
    return ScaleTransition(
      key: const ValueKey('ticket'),
      scale: _scaleAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Success icon
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 12),
            const Text('Booking Confirmed!',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Your ticket is ready', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
            const SizedBox(height: 24),
            // Ticket card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  // Movie header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5383B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.movie_filter_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.movie.title,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (widget.movie.subtitle.isNotEmpty)
                                Text(widget.movie.subtitle,
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Ticket details
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _detailRow(Icons.calendar_today_outlined, 'Date', widget.date),
                        const SizedBox(height: 14),
                        _detailRow(Icons.access_time, 'Time', widget.time),
                        const SizedBox(height: 14),
                        _detailRow(Icons.movie_filter_outlined, 'Screen', widget.screenType),
                        const SizedBox(height: 14),
                        _detailRow(Icons.chair_alt_rounded, 'Seats', _seatLabels.join(', ')),
                        const SizedBox(height: 14),
                        _detailRow(Icons.confirmation_number_outlined, 'Booking ID',
                          '#AC${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'),
                      ],
                    ),
                  ),
                  // Dashed divider with notches
                  _dashedDivider(),
                  // QR Code
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('Scan at Entry', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: _qrData,
                            version: QrVersions.auto,
                            size: 160,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Total: €${widget.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareTicket,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainShell()),
                      (_) => false,
                    ),
                    icon: const Icon(Icons.home_outlined, size: 18),
                    label: const Text('Home', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFE5383B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE5383B), size: 18),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _dashedDivider() {
    return Row(
      children: [
        Container(width: 20, height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFFE5383B),
            borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
          )),
        Expanded(
          child: LayoutBuilder(builder: (_, c) {
            const dw = 6.0, ds = 4.0;
            final count = (c.maxWidth / (dw + ds)).floor();
            return Row(children: List.generate(count, (_) =>
              Container(width: dw, height: 1, margin: const EdgeInsets.only(right: ds), color: Colors.white12)));
          }),
        ),
        Container(width: 20, height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFFE5383B),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
          )),
      ],
    );
  }
}
