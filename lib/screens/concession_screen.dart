import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../models/concession_item.dart';
import 'payment_screen.dart';

class ConcessionScreen extends StatefulWidget {
  final Movie movie;
  final String date;
  final String time;
  final String screenType;
  final List<int> seatIndices;
  final double ticketTotal;

  const ConcessionScreen({
    super.key,
    required this.movie,
    required this.date,
    required this.time,
    required this.screenType,
    required this.seatIndices,
    required this.ticketTotal,
  });

  @override
  State<ConcessionScreen> createState() => _ConcessionScreenState();
}

class _ConcessionScreenState extends State<ConcessionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, int> _quantities = {};

  final List<ConcessionItem> _allItems = [
    ConcessionItem(id: 'f1', name: 'Popcorn Large', imageUrl: 'https://images.unsplash.com/photo-1585647347483-22b66260dfff?w=400', price: 45, category: 'Food'),
    ConcessionItem(id: 'f2', name: 'Popcorn Small', imageUrl: 'https://images.unsplash.com/photo-1578849278619-e73505e9610f?w=400', price: 25, category: 'Food'),
    ConcessionItem(id: 'f3', name: 'Samosa', imageUrl: 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400', price: 30, category: 'Food'),
    ConcessionItem(id: 'f4', name: 'French Fries', imageUrl: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400', price: 35, category: 'Food'),
    ConcessionItem(id: 'f5', name: 'Hot Dog', imageUrl: 'https://images.unsplash.com/photo-1612392062631-94b7f959e2e5?w=400', price: 50, category: 'Food'),
    ConcessionItem(id: 'f6', name: 'Nachos', imageUrl: 'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?w=400', price: 55, category: 'Food'),
    ConcessionItem(id: 'f7', name: 'Injera & Tibs', imageUrl: 'https://images.unsplash.com/photo-1567364816519-cbc9c4ffe1eb?w=400', price: 120, category: 'Food'),
    ConcessionItem(id: 'f8', name: 'Candy Mix', imageUrl: 'https://images.unsplash.com/photo-1582058091505-f87a2e55a40f?w=400', price: 20, category: 'Food'),
    ConcessionItem(id: 'd1', name: 'Coca-Cola', imageUrl: 'https://images.unsplash.com/photo-1554866585-cd94860890b7?w=400', price: 25, category: 'Drinks'),
    ConcessionItem(id: 'd2', name: 'Pepsi', imageUrl: 'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=400', price: 25, category: 'Drinks'),
    ConcessionItem(id: 'd3', name: 'Ambo Water', imageUrl: 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=400', price: 15, category: 'Drinks'),
    ConcessionItem(id: 'd4', name: 'Avocado Juice', imageUrl: 'https://images.unsplash.com/photo-1623065422902-30a2d299bbe4?w=400', price: 40, category: 'Drinks'),
    ConcessionItem(id: 'd5', name: 'Mango Juice', imageUrl: 'https://images.unsplash.com/photo-1546173159-315724a31696?w=400', price: 35, category: 'Drinks'),
    ConcessionItem(id: 'd6', name: 'Ethiopian Coffee', imageUrl: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400', price: 30, category: 'Drinks'),
    ConcessionItem(id: 'd7', name: 'Sprite', imageUrl: 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=400', price: 25, category: 'Drinks'),
    ConcessionItem(id: 'd8', name: 'Orange Juice', imageUrl: 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400', price: 35, category: 'Drinks'),
  ];

  List<ConcessionItem> get _food => _allItems.where((i) => i.category == 'Food').toList();
  List<ConcessionItem> get _drinks => _allItems.where((i) => i.category == 'Drinks').toList();
  int _qty(String id) => _quantities[id] ?? 0;
  double get _concessionTotal => _allItems.fold(0, (s, i) => s + i.price * _qty(i.id));
  double get _grandTotal => widget.ticketTotal + _concessionTotal;

  List<ConcessionItem> get _selectedItems {
    return _allItems.where((i) => _qty(i.id) > 0).map((i) {
      i.quantity = _qty(i.id);
      return i;
    }).toList();
  }

  void _inc(String id) => setState(() => _quantities[id] = _qty(id) + 1);
  void _dec(String id) { if (_qty(id) > 0) setState(() => _quantities[id] = _qty(id) - 1); }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: const Text('Food & Drinks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE5383B),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [Tab(text: '🍿  Food'), Tab(text: '🥤  Drinks')],
        ),
      ),
      body: Column(
        children: [
          if (_concessionTotal > 0) _buildSummaryBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildGrid(_food), _buildGrid(_drinks)],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5383B).withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.shopping_bag_outlined, color: Color(0xFFE5383B), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _selectedItems.map((i) => '${i.name} x${i.quantity}').join(', '),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text('ETB ${_concessionTotal.toStringAsFixed(0)}',
          style: const TextStyle(color: Color(0xFFE5383B), fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }

  Widget _buildGrid(List<ConcessionItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.78,
        crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final qty = _qty(item.id);
        return _ConcessionCard(
          item: item, quantity: qty,
          onIncrement: () => _inc(item.id),
          onDecrement: () => _dec(item.id),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Tickets', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          Text('ETB ${widget.ticketTotal.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
        if (_concessionTotal > 0) ...[
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Food & Drinks', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
            Text('ETB ${_concessionTotal.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ],
        const Divider(color: Colors.white12, height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text('ETB ${_grandTotal.toStringAsFixed(0)}',
            style: const TextStyle(color: Color(0xFFE5383B), fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: _proceed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                side: const BorderSide(color: Colors.white12),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Skip'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: ElevatedButton.icon(
              onPressed: _proceed,
              icon: const Icon(Icons.credit_card, size: 18),
              label: Text(
                _concessionTotal == 0 ? 'Continue' : 'Confirm Order',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5383B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  void _proceed() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PaymentScreen(
        movie: widget.movie,
        date: widget.date,
        time: widget.time,
        screenType: widget.screenType,
        seatIndices: widget.seatIndices,
        totalPrice: _grandTotal,
        concessionItems: _selectedItems,
      ),
    ));
  }
}

class _ConcessionCard extends StatelessWidget {
  final ConcessionItem item;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  const _ConcessionCard({required this.item, required this.quantity, required this.onIncrement, required this.onDecrement});

  @override
  Widget build(BuildContext context) {
    final hasQty = quantity > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: hasQty ? const Color(0xFF2A1A1A) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasQty ? const Color(0xFFE5383B).withOpacity(0.6) : Colors.white.withOpacity(0.06),
          width: hasQty ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: const Color(0xFF2A2A2A),
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFFE5383B), strokeWidth: 2))),
                errorWidget: (_, __, ___) => Container(color: const Color(0xFF2A2A2A),
                  child: const Icon(Icons.fastfood, color: Colors.white30, size: 40)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('ETB ${item.price.toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFFE5383B), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                _QtyBtn(icon: Icons.remove, onTap: onDecrement, active: hasQty),
                Expanded(child: Center(child: Text('$quantity',
                  style: TextStyle(color: hasQty ? Colors.white : Colors.white38,
                    fontSize: 14, fontWeight: FontWeight.bold)))),
                _QtyBtn(icon: Icons.add, onTap: onIncrement, active: true),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _QtyBtn({required this.icon, required this.onTap, required this.active});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE5383B) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: active ? Colors.white : Colors.white24, size: 16),
      ),
    );
  }
}
