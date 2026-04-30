import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings.dart';
import '../services/tmdb_service.dart';
import '../services/api_service.dart';
import '../models/concession_item.dart';
import 'booking_confirmation_screen_tmdb.dart';
import 'login_screen.dart';

class PaymentScreenTmdb extends StatefulWidget {
  final TmdbMovieDetail detail;
  final String date, time, screenType;
  final List<int> seatIndices;
  final double totalPrice;
  final List<ConcessionItem> concessionItems;

  const PaymentScreenTmdb({super.key, required this.detail, required this.date,
    required this.time, required this.screenType, required this.seatIndices,
    required this.totalPrice, required this.concessionItems});

  @override
  State<PaymentScreenTmdb> createState() => _PaymentScreenTmdbState();
}

class _PaymentScreenTmdbState extends State<PaymentScreenTmdb> with TickerProviderStateMixin {
  String? _selectedId;
  bool _processing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const _methods = [
    {'id': 'telebirr', 'name': 'TeleBirr', 'subtitle': 'Ethio Telecom Mobile Money', 'asset': 'assets/icons/telebirr.png', 'color': 0xFF1565C0, 'bg': 0xFF0D1B3E},
    {'id': 'cbe', 'name': 'CBE Birr', 'subtitle': 'Commercial Bank of Ethiopia', 'asset': 'assets/icons/cbe_birr.png', 'color': 0xFF8E24AA, 'bg': 0xFF2D0A3E},
    {'id': 'awash', 'name': 'Awash Bank', 'subtitle': 'Awash Mobile Banking', 'asset': 'assets/icons/awash.png', 'color': 0xFFE65100, 'bg': 0xFF3E1A00},
    {'id': 'abyssinia', 'name': 'Bank of Abyssinia', 'subtitle': 'BOA Mobile Banking', 'asset': 'assets/icons/abyssinia.png', 'color': 0xFFF9A825, 'bg': 0xFF3E2E00},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.04).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pulseController.dispose(); super.dispose(); }

  void _pay() async {
    if (_selectedId == null) return;
    HapticFeedback.mediumImpact();

    // Check login before payment
    final token = await ApiService.getToken();
    if (token == null) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.lock_outline, color: Color(0xFFE5383B), size: 22),
            SizedBox(width: 8),
            Text('Sign In Required', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ]),
          content: const Text('You need to sign in to complete your payment.', style: TextStyle(color: Colors.white70, fontSize: 14)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(returnToPrevious: true)));
                // After login, auto-proceed with payment
                if (!mounted) return;
                final newToken = await ApiService.getToken();
                if (newToken != null) _processPay();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5383B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }
    _processPay();
  }

  void _processPay() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _processing = false);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BookingConfirmationScreenTmdb(
      detail: widget.detail, date: widget.date, time: widget.time,
      screenType: widget.screenType, seatIndices: widget.seatIndices,
      totalPrice: widget.totalPrice, concessionItems: widget.concessionItems)));
  }

  @override
  Widget build(BuildContext context) {
    final sel = _selectedId != null ? _methods.firstWhere((m) => m['id'] == _selectedId) : null;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(slivers: [
        SliverAppBar(backgroundColor: const Color(0xFF0A0A0F), expandedHeight: 0, floating: true, pinned: true, elevation: 0,
          leading: GestureDetector(onTap: () => Navigator.pop(context),
            child: Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20))),
          title: const Text('Secure Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)), centerTitle: true,
          actions: [Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withOpacity(0.3))),
            child: Row(children: [const Icon(Icons.lock, color: Colors.green, size: 12), const SizedBox(width: 4), const Text('SSL', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold))]))]),
        SliverToBoxAdapter(child: _buildAmountCard()),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(children: [Container(width: 3, height: 18, decoration: BoxDecoration(color: const Color(0xFFE5383B), borderRadius: BorderRadius.circular(2))), const SizedBox(width: 10), const Text('Choose Payment Method', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]))),
        SliverList(delegate: SliverChildBuilderDelegate((_, i) => Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: _buildMethodCard(_methods[i])), childCount: _methods.length)),
        SliverToBoxAdapter(child: _buildSecurityBadge()),
        SliverToBoxAdapter(child: _buildPayButton(sel)),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ]),
    );
  }

  Widget _buildAmountCard() {
    return Container(margin: const EdgeInsets.fromLTRB(16, 8, 16, 0), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE5383B), Color(0xFF7B0000)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFFE5383B).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
      child: Row(children: [
        const Icon(Icons.confirmation_number_outlined, color: Colors.white70, size: 28), const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.detail.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${widget.date}  •  ${widget.time}  •  ${widget.seatIndices.length} seat(s)', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('TOTAL', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1)),
          AnimatedBuilder(animation: _pulseAnim, builder: (_, child) => Transform.scale(scale: _pulseAnim.value, alignment: Alignment.centerRight, child: child),
            child: Text('ETB ${widget.totalPrice.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
        ]),
      ]));
  }

  Widget _buildMethodCard(Map<String, Object> method) {
    final selected = _selectedId == method['id'];
    final accent = Color(method['color'] as int);
    final bg = Color(method['bg'] as int);
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedId = method['id'] as String); },
      child: AnimatedContainer(duration: const Duration(milliseconds: 250), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: selected ? bg : const Color(0xFF141420), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? accent : Colors.white.withOpacity(0.06), width: selected ? 1.5 : 1),
          boxShadow: selected ? [BoxShadow(color: accent.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 6))] : []),
        child: Row(children: [
          AnimatedContainer(duration: const Duration(milliseconds: 250), width: 60, height: 60,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: selected ? [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 12, spreadRadius: 1)] : []),
            child: ClipRRect(borderRadius: BorderRadius.circular(16),
              child: Image.asset(method['asset'] as String, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: accent, child: Center(child: Text((method['name'] as String)[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26))))))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(method['name'] as String, style: TextStyle(color: selected ? Colors.white : Colors.white.withOpacity(0.85), fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 3),
            Text(method['subtitle'] as String, style: TextStyle(color: Colors.white.withOpacity(selected ? 0.55 : 0.35), fontSize: 12)),
            if (selected) ...[const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: accent.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: accent.withOpacity(0.4))),
              child: Text('Tap Pay to confirm', style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w600)))],
          ])),
          AnimatedContainer(duration: const Duration(milliseconds: 250), width: 26, height: 26,
            decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? accent : Colors.transparent,
              border: Border.all(color: selected ? accent : Colors.white.withOpacity(0.2), width: 2),
              boxShadow: selected ? [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 8)] : []),
            child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 15) : null),
        ])));
  }

  Widget _buildSecurityBadge() {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.green.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.green.withOpacity(0.15))),
        child: Row(children: [
          const Icon(Icons.verified_user_outlined, color: Colors.green, size: 20), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('256-bit SSL Encrypted', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
            Text('Your payment info is safe & secure', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
          ])),
        ])));
  }

  Widget _buildPayButton(Map<String, Object>? sel) {
    final accent = sel != null ? Color(sel['color'] as int) : null;
    return Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AnimatedContainer(duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: accent != null ? LinearGradient(colors: [accent, accent.withOpacity(0.7)]) : const LinearGradient(colors: [Color(0xFF2A2A2A), Color(0xFF2A2A2A)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: accent != null ? [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))] : []),
        child: ElevatedButton(
          onPressed: _selectedId == null || _processing ? null : _pay,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, disabledBackgroundColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 58), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
          child: _processing
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)), const SizedBox(width: 12), const Text('Processing...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))])
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_selectedId == null ? Icons.touch_app_outlined : Icons.lock_outline, color: Colors.white, size: 20), const SizedBox(width: 10),
                  Text(_selectedId == null ? 'Select a Payment Method' : 'Pay ETB ${widget.totalPrice.toStringAsFixed(0)} via ${sel?['name']}',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ]))));
  }
}
