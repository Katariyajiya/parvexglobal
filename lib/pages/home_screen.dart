import 'package:flutter/material.dart';
import 'package:parvexglobal/extension/extension_functions.dart';
import 'package:parvexglobal/helper/bottom_navigation_bar.dart';

import 'add_instrument.dart';
import 'instrument_detail.dart';
import 'profile.dart'; // Ensure this matches your profile file name

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: RichText(
          text: const TextSpan(
            text: 'Market ',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            children: [
              TextSpan(
                text: 'Watch',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // _buildAppBarAction(Icons.notifications_none_outlined, () {}),
          _buildAppBarAction(Icons.search, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddInstrument()),
            );
          }),
          const Padding(
            padding: EdgeInsets.only(right: 16, left: 8),
            child: CircleAvatar(
              backgroundColor: Color(0xFF2979FF),
              child: Text(
                'AS',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ).onClick(
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Ticker Tape
            // Container(
            //   height: 45,
            //   color: const Color(0xFF101828),
            //   child: ListView(
            //     scrollDirection: Axis.horizontal,
            //     padding: const EdgeInsets.symmetric(horizontal: 10),
            //     children: [
            //       _buildTickerItem('NIFTY', '22,450', '0.42%', true),
            //       _buildTickerItem('SENSEX', '73,950', '0.34%', true),
            //       _buildTickerItem('GOLD', '62,840', '0.31%', false),
            //       _buildTickerItem('SILVER', '74,130', '1.15%', true),
            //     ],
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Market Pulse Section
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     const Text('Market Pulse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  //     TextButton(onPressed: () {
                  //       Navigator.push(context, MaterialPageRoute(builder: (context) => const AddInstrument()));
                  //     }, child: const Text('See all →', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
                  //   ],
                  // ),
                  // const SizedBox(height: 8),
                  // SizedBox(
                  //   height: 100,
                  //   child: ListView(
                  //     scrollDirection: Axis.horizontal,
                  //     children: [
                  //       _buildPulseCard('NIFTY 50', '22,450', '0.42%', true),
                  //       _buildPulseCard('BANK NIFTY', '47,820', '0.18%', false),
                  //       _buildPulseCard('MCX GOLD', '62,840', '0.31%', false),
                  //     ],
                  //   ),
                  // ),
                  //
                  // const SizedBox(height: 18),

                  // 3. Watchlist Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Watchlist',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddInstrument(),
                            ),
                          );
                        },
                        child: const Text(
                          '+ Add',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Watchlist Card 1 (GOLD)
                  _buildWatchlistCard(
                    context,
                    title: 'GOLD',
                    tags: ['MCX', 'Commodity', 'Dec 2025'],
                    price: '₹62,840',
                    change: '₹204 (0.32%)',
                    isPositive: false,
                    accentColor: Colors.orange,
                    details: {
                      'PREV CLOSE': '₹63,044',
                      'OPEN': '₹62,950',
                      'LOT SIZE': '100g',
                      'DAY HIGH': '₹63,120',
                      'DAY LOW': '₹62,610',
                      'LTP': '₹62,840',
                    },
                  ),

                  // Watchlist Card 2 (NIFTY 50)
                  _buildWatchlistCard(
                    context,
                    title: 'NIFTY 50',
                    tags: ['NFO', 'Futures', '28 Nov 2025'],
                    price: '22,450',
                    change: '93 (0.42%)',
                    isPositive: true,
                    accentColor: Colors.blue,
                    details: {
                      'PREV CLOSE': '22,357',
                      'OPEN': '22,380',
                      'LOT SIZE': '50',
                      'DAY HIGH': '22,510',
                      'DAY LOW': '22,290',
                      'LTP': '22,450',
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // --- UPDATED BOTTOM NAV ---
      // bottomNavigationBar: CustomBottomNavBar(currentIndex: 0),
    );
  }

  // --- ALL YOUR ORIGINAL UI METHODS UNTOUCHED ---

  Widget _buildAppBarAction(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black54, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildTickerItem(
    String name,
    String price,
    String percent,
    bool isPositive,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        children: [
          Text(
            '$name ',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Icon(
            isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: isPositive ? Colors.green : Colors.red,
            size: 18,
          ),
          Text(
            price,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseCard(
    String title,
    String price,
    String percent,
    bool isPositive,
  ) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: isPositive ? Colors.green : Colors.red,
                size: 16,
              ),
              Text(
                percent,
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistCard(
    BuildContext context, {
    required String title,
    required List<String> tags,
    required String price,
    required String change,
    required bool isPositive,
    required Color accentColor,
    required Map<String, String> details,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const InstrumentDetailScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),

                  /// LEFT SIDE
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 4,
                          runSpacing: -6,
                          children: tags.map((t) => _buildTag(t)).toList(),
                        ),
                      ],
                    ),
                  ),

                  /// RIGHT SIDE
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${isPositive ? '▲' : '▼'} $change',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            /// DETAILS GRID
            Container(
              // color: Colors.yellow,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children:
                        details.entries.take(3).map((entry) {
                          return Expanded(
                            child: _buildDetailItem(
                              entry.key,
                              entry.value,
                              isHighlight: entry.key == 'LTP',
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children:
                        details.entries.skip(3).take(3).map((entry) {
                          return Expanded(
                            child: _buildDetailItem(
                              entry.key,
                              entry.value,
                              isHighlight: entry.key == 'LTP',
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    bool isDate = label.contains('2025');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDate ? Colors.orange.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDate ? Colors.orange.shade700 : Colors.blue.shade700,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.red.shade400 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
