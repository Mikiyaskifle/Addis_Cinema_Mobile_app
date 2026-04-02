import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ticket.dart';

// Sample booked tickets
final List<Ticket> _sampleTickets = [
  Ticket(
    id: '1',
    movieTitle: 'Spider-Man',
    moviePosterUrl: 'https://image.tmdb.org/t/p/w500/8Vt6mWEReuy4Of61Lnj5Xj704m8.jpg',
    date: 'June 5, 2023',
    time: '12:30',
    screenType: 'Extreme 3D',
    seats: ['C4', 'C5'],
    totalPrice: 9.00,
  ),
  Ticket(
    id: '2',
    movieTitle: 'Guardians of the Galaxy',
    moviePosterUrl: 'https://image.tmdb.org/t/p/w500/r2J02Z2OpNTctfOSN1Ydgii51I3.jpg',
    date: 'June 10, 2023',
    time: '18:30',
    screenType: 'Realt 3D',
    seats: ['F2', 'F3', 'F4'],
    totalPrice: 13.50,
  ),
];

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Tickets', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: _sampleTickets.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _sampleTickets.length,
              itemBuilder: (_, i) => _TicketCard(ticket: _sampleTickets[i]),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_number_outlined, color: Colors.white24, size: 72),
          const SizedBox(height: 16),
          const Text('No tickets yet', style: TextStyle(color: Colors.white38, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Book a movie to see your tickets here', style: TextStyle(color: Colors.white24, fontSize: 13)),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Top: poster + info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: ticket.moviePosterUrl,
                    width: 70,
                    height: 100,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 70,
                      height: 100,
                      color: const Color(0xFF2A2A2A),
                      child: const Icon(Icons.movie, color: Colors.white30),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.movieTitle,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _infoRow(Icons.calendar_today_outlined, ticket.date),
                      const SizedBox(height: 4),
                      _infoRow(Icons.access_time, ticket.time),
                      const SizedBox(height: 4),
                      _infoRow(Icons.movie_filter_outlined, ticket.screenType),
                      const SizedBox(height: 4),
                      _infoRow(Icons.chair_alt_rounded, ticket.seats.join(', ')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Dashed divider
          _DashedDivider(),
          // Bottom: price + QR placeholder
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    Text('€ ${ticket.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_2, color: Colors.black, size: 40),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, color: Colors.white38, size: 13),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(color: Colors.white60, fontSize: 12)),
    ]);
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left notch
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFF0D0D0D),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (_, constraints) {
            const dashWidth = 6.0;
            const dashSpace = 4.0;
            final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
            return Row(
              children: List.generate(count, (_) => Container(
                width: dashWidth,
                height: 1,
                margin: const EdgeInsets.only(right: dashSpace),
                color: Colors.white12,
              )),
            );
          }),
        ),
        // Right notch
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFF0D0D0D),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
