import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings.dart';
import '../models/movie.dart';
import 'concession_screen.dart';

class SelectSeatsScreen extends StatefulWidget {
  final Movie movie;
  const SelectSeatsScreen({super.key, required this.movie});

  @override
  State<SelectSeatsScreen> createState() => _SelectSeatsScreenState();
}

class _SelectSeatsScreenState extends State<SelectSeatsScreen> {
  int _selectedTimeIndex = 0;
  int _selectedTypeIndex = 0;
  final Set<int> _selectedSeats = {};

  final List<String> _times = ['12:30', '15:00', '18:30', '19:30'];
  final List<String> _types = ['Extreme 3D', 'Realt 3D', 'Extreme 2D', '4DX 3D'];
  final double _pricePerSeat = 150.0;

  // rows x cols = 8x9 = 72 seats; pre-taken seats
  final Set<int> _takenSeats = {5, 6, 14, 15, 23, 24, 31, 32, 40, 41, 49,29,28,1,10, 50};

  @override
  Widget build(BuildContext context) {
    final total = _selectedSeats.length * _pricePerSeat;
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
        title: Text(context.watch<AppSettings>().t('Select Seats'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFF1C1C1E), shape: BoxShape.circle),
            child: const Icon(Icons.bookmark_border, color: Colors.white, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildScreenIndicator(),
          const SizedBox(height: 16),
          _buildDateTimeRow(),
          const SizedBox(height: 12),
          _buildTypeTabs(),
          const SizedBox(height: 20),
          Expanded(child: _buildSeatGrid()),
          _buildLegend(),
          const SizedBox(height: 16),
          _buildBuyButton(total),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildScreenIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: Column(children: [
        Text(context.watch<AppSettings>().t('Screen'),
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.transparent, Colors.white38, Colors.transparent]),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ]),
    );
  }

  Widget _buildDateTimeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(20)),
            child: const Row(children: [
              Text('June 5', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_times.length, (i) {
                  final sel = i == _selectedTimeIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTimeIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFFE5383B) : const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_times[i],
                        style: TextStyle(color: sel ? Colors.white : Colors.white60, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_types.length, (i) {
          final sel = i == _selectedTypeIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedTypeIndex = i),
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(children: [
                Text(_types[i],
                  style: TextStyle(
                    color: sel ? const Color(0xFFE5383B) : Colors.white38,
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  )),
                const SizedBox(height: 4),
                if (sel) Container(width: 20, height: 2, color: const Color(0xFFE5383B)),
              ]),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSeatGrid() {
    const rows = 8;
    const cols = 9;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: rows * cols,
      itemBuilder: (_, index) {
        final isTaken = _takenSeats.contains(index);
        final isSelected = _selectedSeats.contains(index);
        return GestureDetector(
          onTap: isTaken ? null : () => setState(() {
            isSelected ? _selectedSeats.remove(index) : _selectedSeats.add(index);
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFE5383B)
                  : isTaken ? const Color(0xFF3A3A3A) : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.chair_alt_rounded, size: 16,
              color: isSelected ? Colors.white : isTaken ? Colors.white24 : Colors.white60),
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendDot(const Color(0xFF2A2A2A), context.watch<AppSettings>().t('Available')),
          const SizedBox(width: 20),
          _legendDot(const Color(0xFF3A3A3A), context.watch<AppSettings>().t('Taken')),
          const SizedBox(width: 20),
          _legendDot(const Color(0xFFE5383B), context.watch<AppSettings>().t('Selected')),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
    ]);
  }

  Widget _buildBuyButton(double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: _selectedSeats.isEmpty ? null : () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ConcessionScreen(
            movie: widget.movie,
            date: 'June 5, 2023',
            time: _times[_selectedTimeIndex],
            screenType: _types[_selectedTypeIndex],
            seatIndices: _selectedSeats.toList()..sort(),
            ticketTotal: _selectedSeats.length * _pricePerSeat,
          )),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE5383B),
          disabledBackgroundColor: const Color(0xFF3A3A3A),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.credit_card, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(context.watch<AppSettings>().t('Buy Tickets'),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            if (_selectedSeats.isNotEmpty) ...[
              const SizedBox(width: 12),
              Container(width: 1, height: 20, color: Colors.white38),
              const SizedBox(width: 12),
              Text('ETB ${total.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }
}
