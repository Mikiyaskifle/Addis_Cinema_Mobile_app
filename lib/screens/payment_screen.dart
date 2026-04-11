import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/concession_item.dart';
import 'booking_confirmation_screen.dart';

class _PaymentMethod {
  final String id;
  final String name;
  final String subtitle;
  final Color color;
  final Color textColor;
  final String initial;
  final IconData icon;

  const _PaymentMethod({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.color,
    required this.textColor,
    required this.initial,
    required this.icon,
  });
}

const _methods = [
  _PaymentMethod(
    id: 'telebirr',
    name: 'TeleBirr',
    subtitle: 'Ethio Telecom Mobile Money',
    color: Color(0xFF00A651),
    textColor: Colors.white,
    initial: 'T',
    icon: Icons.phone_android,
  ),
  _PaymentMethod(
    id: 'cbe',
    name: 'CBE Birr',
    subtitle: 'Commercial Bank of Ethiopia',
    color: Color(0xFF003087),
    textColor: Colors.white,
    initial: 'C',
    icon: Icons.account_balance,
  ),
  _PaymentMethod(
    id: 'awash',
    name: 'Awash Bank',
    subtitle: 'Awash Mobile Banking',
    color: Color(0xFFE31837),
    textColor: Colors.white,
    initial: 'A',
    icon: Icons.account_balance_wallet,
  ),
  _PaymentMethod(
    id: 'abyssinia',
    name: 'Bank of Abyssinia',
    subtitle: 'BOA Mobile Banking',
    color: Color(0xFF1B4F8A),
    textColor: Colors.white,
    initial: 'B',
    icon: Icons.savings,
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

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedId;
  bool _processing = false;

  void _pay() async {
    if (_selectedId == null) return;
    setState(() => _processing = true);
    // Simulate payment processing
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
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFF1C1C1E), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
        title: const Text('Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Amount summary
          _buildAmountCard(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Select Payment Method',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13,
                  fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _methods.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _buildMethodCard(_methods[i]),
            ),
          ),
          _buildPayButton(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE5383B), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFFE5383B).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number_outlined, color: Colors.white70, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.movie.title.replaceAll('\n', ' '),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${widget.date}  •  ${widget.time}  •  ${widget.seatIndices.length} seat(s)',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('TOTAL', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1)),
              Text('ETB ${widget.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(_PaymentMethod method) {
    final selected = _selectedId == method.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedId = method.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? method.color.withOpacity(0.12) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? method.color : Colors.white.withOpacity(0.07),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: method.color.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: method.color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: method.color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(method.icon, color: Colors.white, size: 20),
                  const SizedBox(height: 2),
                  Text(method.initial,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.name,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(method.subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
                ],
              ),
            ),
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? method.color : Colors.white24,
                  width: 2,
                ),
                color: selected ? method.color : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ElevatedButton(
        onPressed: _selectedId == null || _processing ? null : _pay,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE5383B),
          disabledBackgroundColor: const Color(0xFF2A2A2A),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 8,
          shadowColor: const Color(0xFFE5383B).withOpacity(0.4),
        ),
        child: _processing
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _selectedId == null
                        ? 'Select a Payment Method'
                        : 'Pay ETB ${widget.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
