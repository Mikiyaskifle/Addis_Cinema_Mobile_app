import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import '../models/movie.dart';
import '../models/concession_item.dart';
import '../services/api_service.dart';
import 'main_shell.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Movie movie;
  final String date;
  final String time;
  final String screenType;
  final List<int> seatIndices;
  final double totalPrice;
  final List<ConcessionItem> concessionItems;

  const BookingConfirmationScreen({
    super.key,
    required this.movie,
    required this.date,
    required this.time,
    required this.screenType,
    required this.seatIndices,
    required this.totalPrice,
    this.concessionItems = const [],
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _downloading = false;
  late final String _bookingId;

  List<String> get _seatLabels {
    const rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    return widget.seatIndices
        .map((i) => '${rows[i ~/ 9]}${(i % 9) + 1}')
        .toList();
  }

  String get _qrData =>
      'AddisCinema|${widget.movie.title}|${widget.date}|${widget.time}|${_seatLabels.join(",")}|ETB${widget.totalPrice.toStringAsFixed(0)}';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _bookingId = 'CN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 9)}-01';
    _saveBookingToDatabase(); // save to DB on confirmation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveBookingToDatabase() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) return; // not logged in, skip
      await ApiService.addBooking({
        'movieTitle': widget.movie.title.replaceAll('\n', ' '),
        'moviePoster': widget.movie.posterUrl,
        'date': widget.date,
        'time': widget.time,
        'screenType': widget.screenType,
        'seats': _seatLabels,
        'totalPrice': widget.totalPrice,
        'bookingId': _bookingId,
      });
    } catch (_) {} // silent fail — don't block UI
  }

  Future<void> _shareTicket() async {
    try {
      // Capture ticket as image
      final imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (imageBytes == null) throw Exception('Failed to capture ticket');

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/addiscinema_ticket.png');
      await file.writeAsBytes(imageBytes);

      // Share as image file
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: '🎬 My AddisCinema Ticket — ${widget.movie.title.replaceAll("\n", " ")}',
        subject: 'AddisCinema Ticket',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to share ticket: $e'),
          backgroundColor: Colors.red.shade900,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _downloadTicket() async {
    if (_downloading) return;
    setState(() => _downloading = true);

    try {
      // Request permission
      PermissionStatus status;
      if (Platform.isAndroid) {
        final sdkInt = await _getAndroidSdkInt();
        if (sdkInt >= 33) {
          status = await Permission.photos.request();
        } else {
          status = await Permission.storage.request();
        }
      } else {
        status = await Permission.photos.request();
      }

      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission required to download ticket'),
              backgroundColor: Color(0xFF1C1C1E),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _downloading = false);
        return;
      }

      // Capture screenshot
      final imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (imageBytes == null) throw Exception('Failed to capture ticket');

      // Save to downloads
      final dir = await getExternalStorageDirectory();
      final downloadsPath = dir?.path.replaceAll('Android/data/com.addiscinema.app/files', 'Download') 
          ?? (await getApplicationDocumentsDirectory()).path;
      
      final fileName = 'AddisCinema_Ticket_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('$downloadsPath/$fileName');
      await file.writeAsBytes(imageBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Ticket saved to Downloads/$fileName')),
            ]),
            backgroundColor: const Color(0xFF1C1C1E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save ticket: $e'),
            backgroundColor: Colors.red.shade900,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<int> _getAndroidSdkInt() async {
    try {
      return int.parse(Platform.operatingSystemVersion.split('SDK ').last.split(')').first);
    } catch (_) {
      return 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainShell()),
            (_) => false,
          ),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
        title: const Text('Booking Confirmation',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              children: [
                // Check icon + title
                _buildHeader(),
                const SizedBox(height: 20),
                // Main ticket card wrapped for screenshot
                Screenshot(
                  controller: _screenshotController,
                  child: _buildTicketCard(),
                ),
                const SizedBox(height: 16),
                // Download button
                _buildDownloadBtn(),
                const SizedBox(height: 10),
                // Share button
                _buildShareBtn(),
                const SizedBox(height: 16),
                // Parking validated
                _buildInfoTile(
                  Icons.directions_car_outlined,
                  'Parking Validated',
                  'Level B2, Zone 4 reserved.',
                ),
                const SizedBox(height: 12),
                // Pre-order & Calendar row
                Row(children: [
                  Expanded(
                    child: _buildSmallTile(
                      Icons.restaurant_menu_outlined,
                      'Pre-order',
                      widget.concessionItems.isNotEmpty
                          ? '${widget.concessionItems.length} items added'
                          : 'Snacks to seat',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSmallTile(
                      Icons.calendar_today_outlined,
                      'Calendar',
                      'Add reminder',
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                // Go Home button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainShell()),
                      (_) => false,
                    ),
                    icon: const Icon(Icons.home_rounded, size: 20),
                    label: const Text('Back to Home',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5383B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 8,
                      shadowColor: const Color(0xFFE5383B).withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E1E2E),
          border: Border.all(color: const Color(0xFF4A90D9).withOpacity(0.4), width: 2),
        ),
        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4A90D9), size: 32),
      ),
      const SizedBox(height: 12),
      const Text('Tickets Confirmed!',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text('Order #$_bookingId',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
    ]);
  }

  Widget _buildTicketCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161625),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // Movie poster banner
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: widget.movie.posterUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    height: 160,
                    color: const Color(0xFF1E1E2E),
                    child: const Icon(Icons.movie, color: Colors.white24, size: 60),
                  ),
                ),
                // Dark gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, const Color(0xFF161625).withOpacity(0.95)],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                  ),
                ),
                // Movie title + badge
                Positioned(
                  bottom: 14, left: 16, right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.movie.title.replaceAll('\n', ' '),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5383B).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.screenType.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: _detailCol('DATE', widget.date)),
                  Expanded(child: _detailCol('TIME', widget.time, align: TextAlign.right)),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _detailCol('HALL', 'Screen 04')),
                  Expanded(
                    child: _detailCol('SEAT', _seatLabels.join(', '),
                        valueColor: const Color(0xFFE5C84A), align: TextAlign.right),
                  ),
                ]),
              ],
            ),
          ),

          // Dashed divider with notches
          _dashedDivider(),

          // QR Code
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16),
                  ],
                ),
                child: QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 140,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Scan this code at the theater entrance.\nTicket is valid for one entry.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11, height: 1.5),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _detailCol(String label, String value,
      {Color valueColor = Colors.white, TextAlign align = TextAlign.left}) {
    return Column(
      crossAxisAlignment:
          align == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.35), fontSize: 10, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        Text(value,
            textAlign: align,
            style: TextStyle(color: valueColor, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _dashedDivider() {
    return Row(children: [
      Container(
        width: 22, height: 22,
        decoration: const BoxDecoration(
          color: Color(0xFF0E0E1A),
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(11), bottomRight: Radius.circular(11)),
        ),
      ),
      Expanded(
        child: LayoutBuilder(builder: (_, c) {
          const dw = 5.0, ds = 4.0;
          final count = (c.maxWidth / (dw + ds)).floor();
          return Row(
            children: List.generate(
              count,
              (_) => Container(
                  width: dw, height: 1.5,
                  margin: const EdgeInsets.only(right: ds),
                  color: Colors.white.withOpacity(0.1)),
            ),
          );
        }),
      ),
      Container(
        width: 22, height: 22,
        decoration: const BoxDecoration(
          color: Color(0xFF0E0E1A),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(11), bottomLeft: Radius.circular(11)),
        ),
      ),
    ]);
  }

  Widget _buildDownloadBtn() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A3A6A), Color(0xFF2A2A4A)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: ElevatedButton.icon(
        onPressed: _downloading ? null : _downloadTicket,
        icon: _downloading
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.download_outlined, size: 18),
        label: Text(
          _downloading ? 'Saving...' : 'Download Ticket',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  Widget _buildShareBtn() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _shareTicket,
        icon: const Icon(Icons.share_outlined, size: 18),
        label: const Text('Share Ticket',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161625),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4A90D9), size: 20),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _buildSmallTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161625),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: const Color(0xFF4A90D9), size: 22),
        const SizedBox(height: 10),
        Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
      ]),
    );
  }
}
