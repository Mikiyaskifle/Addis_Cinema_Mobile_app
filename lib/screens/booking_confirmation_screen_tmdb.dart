import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import '../services/tmdb_service.dart';
import '../models/concession_item.dart';
import '../services/api_service.dart';
import 'main_shell.dart';

class BookingConfirmationScreenTmdb extends StatefulWidget {
  final TmdbMovieDetail detail;
  final String date, time, screenType;
  final List<int> seatIndices;
  final double totalPrice;
  final List<ConcessionItem> concessionItems;

  const BookingConfirmationScreenTmdb({super.key, required this.detail, required this.date,
    required this.time, required this.screenType, required this.seatIndices,
    required this.totalPrice, this.concessionItems = const []});

  @override
  State<BookingConfirmationScreenTmdb> createState() => _BookingConfirmationScreenTmdbState();
}

class _BookingConfirmationScreenTmdbState extends State<BookingConfirmationScreenTmdb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _downloading = false;
  late final String _bookingId;

  List<String> get _seatLabels {
    const rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    return widget.seatIndices.map((i) => '${rows[i ~/ 9]}${(i % 9) + 1}').toList();
  }

  String get _qrData => 'AddisCinema|${widget.detail.title}|${widget.date}|${widget.time}|${_seatLabels.join(",")}|ETB${widget.totalPrice.toStringAsFixed(0)}';

  @override
  void initState() {
    super.initState();
    _bookingId = 'CN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 9)}-01';
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _saveBooking();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _saveBooking() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) return;
      await ApiService.addBooking({
        'movieTitle': widget.detail.title,
        'moviePoster': widget.detail.posterUrl,
        'date': widget.date, 'time': widget.time,
        'screenType': widget.screenType, 'seats': _seatLabels,
        'totalPrice': widget.totalPrice, 'bookingId': _bookingId,
      });
    } catch (_) {}
  }

  Future<void> _shareTicket() async {
    try {
      final imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (imageBytes == null) return;
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/addiscinema_ticket.png');
      await file.writeAsBytes(imageBytes);
      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')],
        text: '🎬 My AddisCinema Ticket — ${widget.detail.title}', subject: 'AddisCinema Ticket');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share: $e'), backgroundColor: Colors.red.shade900, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _downloadTicket() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      PermissionStatus status;
      if (Platform.isAndroid) {
        try { final sdk = int.parse(Platform.operatingSystemVersion.split('SDK ').last.split(')').first); status = sdk >= 33 ? await Permission.photos.request() : await Permission.storage.request(); }
        catch (_) { status = await Permission.storage.request(); }
      } else { status = await Permission.photos.request(); }
      if (!status.isGranted) { setState(() => _downloading = false); return; }
      final imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (imageBytes == null) throw Exception('Failed to capture');
      final dir = await getExternalStorageDirectory();
      final path = dir?.path.replaceAll('Android/data/com.addiscinema.app/files', 'Download') ?? (await getApplicationDocumentsDirectory()).path;
      final fileName = 'AddisCinema_Ticket_${DateTime.now().millisecondsSinceEpoch}.png';
      await File('$path/$fileName').writeAsBytes(imageBytes);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.green, size: 18), const SizedBox(width: 8), Expanded(child: Text('Saved to Downloads/$fileName'))]), backgroundColor: const Color(0xFF1C1C1E), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red.shade900, behavior: SnackBarBehavior.floating));
    } finally { if (mounted) setState(() => _downloading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        leading: GestureDetector(onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainShell()), (_) => false),
          child: const Icon(Icons.arrow_back, color: Colors.white)),
        title: const Text('Booking Confirmation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)), centerTitle: true),
      body: FadeTransition(opacity: _fadeAnim, child: SlideTransition(position: _slideAnim,
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), child: Column(children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Screenshot(controller: _screenshotController, child: _buildTicketCard()),
          const SizedBox(height: 16),
          _buildDownloadBtn(),
          const SizedBox(height: 10),
          _buildShareBtn(),
          const SizedBox(height: 16),
          _buildInfoTile(Icons.directions_car_outlined, 'Parking Validated', 'Level B2, Zone 4 reserved.'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildSmallTile(Icons.restaurant_menu_outlined, 'Pre-order', widget.concessionItems.isNotEmpty ? '${widget.concessionItems.length} items added' : 'Snacks to seat')),
            const SizedBox(width: 12),
            Expanded(child: _buildSmallTile(Icons.calendar_today_outlined, 'Calendar', 'Add reminder')),
          ]),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainShell()), (_) => false),
            icon: const Icon(Icons.home_rounded, size: 20),
            label: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5383B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 8, shadowColor: const Color(0xFFE5383B).withOpacity(0.4)))),
        ])))),
    );
  }

  Widget _buildHeader() {
    return Column(children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1E1E2E), border: Border.all(color: const Color(0xFF4A90D9).withOpacity(0.4), width: 2)),
        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4A90D9), size: 32)),
      const SizedBox(height: 12),
      const Text('Tickets Confirmed!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text('Order #$_bookingId', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
    ]);
  }

  Widget _buildTicketCard() {
    return Container(decoration: BoxDecoration(color: const Color(0xFF161625), borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(children: [
        ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Stack(children: [
            CachedNetworkImage(imageUrl: widget.detail.backdropUrl.isNotEmpty ? widget.detail.backdropUrl : widget.detail.posterUrl, height: 160, width: double.infinity, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(height: 160, color: const Color(0xFF1E1E2E), child: const Icon(Icons.movie, color: Colors.white24, size: 60))),
            Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, const Color(0xFF161625).withOpacity(0.95)], stops: const [0.3, 1.0])))),
            Positioned(bottom: 14, left: 16, right: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.detail.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFE5383B).withOpacity(0.85), borderRadius: BorderRadius.circular(6)),
                child: Text(widget.screenType.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
            ])),
          ])),
        Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Row(children: [Expanded(child: _detailCol('DATE', widget.date)), Expanded(child: _detailCol('TIME', widget.time, align: TextAlign.right))]),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: _detailCol('HALL', 'Screen 04')), Expanded(child: _detailCol('SEAT', _seatLabels.join(', '), valueColor: const Color(0xFFE5C84A), align: TextAlign.right))]),
          if (widget.concessionItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 6),
            Row(children: [const Icon(Icons.fastfood_outlined, color: Color(0xFFE5383B), size: 16), const SizedBox(width: 8), const Text('Food & Drinks', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600))]),
            const SizedBox(height: 8),
            ...widget.concessionItems.map((item) => Padding(padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [const Icon(Icons.circle, color: Color(0xFFE5383B), size: 6), const SizedBox(width: 8), Expanded(child: Text('${item.name} × ${item.quantity}', style: const TextStyle(color: Colors.white70, fontSize: 12))), Text('ETB ${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))]))),
          ],
        ])),
        _dashedDivider(),
        Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          const Text('Scan at Entry', style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16)]),
            child: QrImageView(data: _qrData, version: QrVersions.auto, size: 140, backgroundColor: Colors.white)),
          const SizedBox(height: 16),
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE5383B), Color(0xFFB71C1C)]), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [const Text('TOTAL AMOUNT', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2)), const SizedBox(height: 4), Text('ETB ${widget.totalPrice.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))])),
        ])),
      ]));
  }

  Widget _detailCol(String label, String value, {Color valueColor = Colors.white, TextAlign align = TextAlign.left}) {
    return Column(crossAxisAlignment: align == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
      Text(label, textAlign: align, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10, letterSpacing: 1.5)),
      const SizedBox(height: 4),
      Text(value, textAlign: align, style: TextStyle(color: valueColor, fontSize: 15, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _dashedDivider() {
    return Row(children: [
      Container(width: 22, height: 22, decoration: const BoxDecoration(color: Color(0xFF0E0E1A), borderRadius: BorderRadius.only(topRight: Radius.circular(11), bottomRight: Radius.circular(11)))),
      Expanded(child: LayoutBuilder(builder: (_, c) { const dw = 5.0, ds = 4.0; final count = (c.maxWidth / (dw + ds)).floor(); return Row(children: List.generate(count, (_) => Container(width: dw, height: 1.5, margin: const EdgeInsets.only(right: ds), color: Colors.white.withOpacity(0.1)))); })),
      Container(width: 22, height: 22, decoration: const BoxDecoration(color: Color(0xFF0E0E1A), borderRadius: BorderRadius.only(topLeft: Radius.circular(11), bottomLeft: Radius.circular(11)))),
    ]);
  }

  Widget _buildDownloadBtn() {
    return Container(width: double.infinity, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3A3A6A), Color(0xFF2A2A4A)]), borderRadius: BorderRadius.circular(30)),
      child: ElevatedButton.icon(onPressed: _downloading ? null : _downloadTicket,
        icon: _downloading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.download_outlined, size: 18),
        label: Text(_downloading ? 'Saving...' : 'Download Ticket', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: Colors.white, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))));
  }

  Widget _buildShareBtn() {
    return SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _shareTicket,
      icon: const Icon(Icons.share_outlined, size: 18),
      label: const Text('Share Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))));
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: const Color(0xFF161625), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF4A90D9), size: 20)), const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12))])]));
  }

  Widget _buildSmallTile(IconData icon, String title, String subtitle) {
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF161625), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: const Color(0xFF4A90D9), size: 22), const SizedBox(height: 10), Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11))]));
  }
}
