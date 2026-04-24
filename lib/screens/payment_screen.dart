import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings.dart';
import '../models/movie.dart';
import '../models/concession_item.dart';
import 'booking_confirmation_screen.dart';

class _PaymentMethod {
  final String id;
  final String name;
  final String subtitle;
  final String assetPath;
  final Color accent;
  final Color bgColor;

  const _PaymentMethod({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.assetPath,
    required this.accent,
    required this.bgColor,
  });
}

const _methods = [
  _PaymentMethod(
    id: 'telebirr',
    name: 'TeleBirr',
    subtitle: 'Ethio Telecom Mobile Money',
    assetPath: 'assets/icons/telebirr.png',
    accent: Color(0xFF1565C0),
    bgColor: Color(0xFF0D1B3E),
  ),
  _PaymentMethod(
    id: 'cbe',
    name: 'CBE Birr',
    subtitle: 'Commercial Bank of Ethiopia',
    assetPath: 'assets/icons/cbe_birr.png',
    accent: Color(0xFF8E24AA),
    bgColor: Color(0xFF2D0A3E),
  ),
  _PaymentMethod(
    id: 'awash',
    name: 'Awash Bank',
    subtitle: 'Awash Mobile Banking',
    assetPath: 'assets/icons/awash.png',
    accent: Color(0xFFE65100),
    bgColor: Color(0xFF3E1A00),
  ),
  _PaymentMethod(
    id: 'abyssinia',
    name: 'Bank of Abyssinia',
    subtitle: 'BOA Mobile Banking',
    assetPath: 'assets/icons/abyssinia.png',
    accent: Color(0xFFF9A825),
    bgColor: Color(0xFF3E2E00),
  ),
];

class PaymentScreen extends StatefulWidget {
  final Movie movie;
  final String date;
  final String time;
  final String screenType;
  final List<int> seatIndices;
  final double totalPrice;
  final List<ConcessionItem> concessionItems;

  const PaymentScreen({
    super.key,
    required this.movie,
    required this.date,
    required this.time,
    required this.screenType,
    required this.seatIndices,
    required this.totalPrice,
    required this.concessionItems,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  String? _selectedId;
  bool _processing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.04)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  _PaymentMethod? get _selected =>
      _selectedId == null ? null : _methods.firstWhere((m) => m.id == _selectedId);

  void _pay() async {
    if (_selectedId == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _processing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _processing = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          movie: widget.movie,
          date: widget.date,
          time: widget.time,
          screenType: widget.screenType,
          seatIndices: widget.seatIndices,
          totalPrice: widget.totalPrice,
          concessionItems: widget.concessionItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildOrderSummary()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(children: [
                Container(width: 3, height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5383B),
                      borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                const Text('Choose Payment Method',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _buildMethodCard(_methods[i]),
              ),
              childCount: _methods.length,
            ),
          ),
          SliverToBoxAdapter(child: _buildSecurityBadge()),
          SliverToBoxAdapter(child: _buildPayButton()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFF0A0A0F),
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
      title: const Text('Secure Payment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.lock, color: Colors.green, size: 12),
            const SizedBox(width: 4),
            const Text('SSL', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE5383B).withOpacity(0.9),
            const Color(0xFF7B0000),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFE5383B).withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(right: -20, top: -20,
            child: Container(width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ))),
          Positioned(right: 30, bottom: -30,
            child: Container(width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.movie_filter_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(widget.movie.title.replaceAll('\n', ' '),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _summaryChip(Icons.calendar_today_outlined, widget.date),
                  const SizedBox(width: 8),
                  _summaryChip(Icons.access_time, widget.time),
                  const SizedBox(width: 8),
                  _summaryChip(Icons.chair_alt_rounded, '${widget.seatIndices.length} seat(s)'),
                ]),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('TOTAL AMOUNT',
                        style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 2)),
                      const SizedBox(height: 4),
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _pulseAnim.value, alignment: Alignment.centerLeft, child: child),
                        child: Text('ETB ${widget.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold,
                              letterSpacing: -0.5)),
                      ),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.receipt_long_outlined, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        const Text('View Details',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Icon(icon, color: Colors.white70, size: 11),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ]),
    );
  }

  Widget _buildMethodCard(_PaymentMethod method) {
    final selected = _selectedId == method.id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedId = method.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? method.bgColor : const Color(0xFF141420),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? method.accent : Colors.white.withOpacity(0.06),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: method.accent.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 6))]
              : [],
        ),
        child: Row(
          children: [
            // Logo with glow
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 60, height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: selected
                    ? [BoxShadow(color: method.accent.withOpacity(0.4), blurRadius: 12, spreadRadius: 1)]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  method.assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: method.accent,
                    child: Center(
                      child: Text(method.name[0],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.name,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(method.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(selected ? 0.55 : 0.35),
                      fontSize: 12)),
                  if (selected) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: method.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: method.accent.withOpacity(0.4)),
                      ),
                      child: Text('Tap Pay to confirm',
                        style: TextStyle(color: method.accent, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),
            // Animated radio
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? method.accent : Colors.transparent,
                border: Border.all(
                  color: selected ? method.accent : Colors.white.withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: method.accent.withOpacity(0.4), blurRadius: 8)]
                    : [],
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withOpacity(0.15)),
        ),
        child: Row(children: [
          const Icon(Icons.verified_user_outlined, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('256-bit SSL Encrypted',
                style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('Your payment info is safe & secure',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
            ]),
          ),
          Row(children: [
            _miniLogo('🔒'),
            const SizedBox(width: 4),
            _miniLogo('🛡️'),
          ]),
        ]),
      ),
    );
  }

  Widget _miniLogo(String emoji) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 14))),
    );
  }

  Widget _buildPayButton() {
    final sel = _selected;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: sel != null
              ? LinearGradient(colors: [sel.accent, sel.accent.withOpacity(0.7)])
              : const LinearGradient(colors: [Color(0xFF2A2A2A), Color(0xFF2A2A2A)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: sel != null
              ? [BoxShadow(color: sel.accent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))]
              : [],
        ),
        child: ElevatedButton(
          onPressed: _selectedId == null || _processing ? null : _pay,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 58),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: _processing
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                  const SizedBox(width: 12),
                  const Text('Processing...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ])
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                    _selectedId == null ? Icons.touch_app_outlined : Icons.lock_outline,
                    color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _selectedId == null
                        ? 'Select a Payment Method'
                        : 'Pay ETB ${widget.totalPrice.toStringAsFixed(0)} via ${sel?.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ]),
        ),
      ),
    );
  }
}
