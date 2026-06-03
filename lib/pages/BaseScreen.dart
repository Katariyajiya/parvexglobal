import 'package:flutter/material.dart';
import 'package:parvexglobal/pages/AlertHistoryScreen.dart';
import 'package:parvexglobal/pages/home_screen.dart';
import 'package:parvexglobal/pages/profile.dart';
import 'package:parvexglobal/pages/trade_ledger_screen.dart';
import 'package:parvexglobal/services/trade_service.dart';

class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  int _currentTabIndex = 0;
  final _tradeService = TradeService.instance;

  @override
  void initState() {
    super.initState();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: RichText(
        text: const TextSpan(
          text: 'Bhav',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          children: [
            TextSpan(
              text: 'Tav',
              style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.circle, size: 9, color: true ? Colors.green : Colors.grey),
              const SizedBox(width: 4),
              Text(true ? 'Live' : '...', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        // Text('12'),
        _buildTotalPnLBanner(),
      ],
    );
  }

  Widget _buildTotalPnLBanner() {
    return ListenableBuilder(
      listenable: _tradeService,
      builder: (_, __) {
        final openMTM = _tradeService.openMTM;
        final realised = _tradeService.realisedPnL;
        final total = _tradeService.totalPnL;
        final isUp = total >= 0;
        final clr = isUp ? const Color(0xFF1E7D3A) : const Color(0xFFCC2929);
        final bgClr = isUp ? const Color(0xFFF0FBF4) : const Color(0xFFFDF0F0);
        final pillBg = isUp ? const Color(0xFFD6F3E0) : const Color(0xFFF9D6D6);
        final pillText = isUp ? const Color(0xFF1A6E33) : const Color(0xFFB82323);
        final icon = isUp ? Icons.trending_up : Icons.trending_down_outlined;

        // Hide the banner entirely when there are no trades
        if (_tradeService.openTrades.isEmpty && _tradeService.closedTrades.isEmpty) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TradeLedgerScreen()),
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgClr,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: clr.withOpacity(0.25),
                width: 0.8,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Left: label + open/realised breakdown ──────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Total P&L',
                      style: TextStyle(
                        fontSize: 11,
                        color: clr.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2, width: 6),
                    Text(
                      '${total >= 0 ? '+' : ''}₹${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: clr,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),

                // ── Right: open MTM + realised chips ───────────────────────
                // Row(
                //   children: [
                //     _pnlChip(
                //       label: 'Open MTM',
                //       value: openMTM,
                //       pillBg: pillBg,
                //       pillText: pillText,
                //     ),
                //     const SizedBox(width: 8),
                //     _pnlChip(
                //       label: 'Realised',
                //       value: realised,
                //       pillBg: pillBg,
                //       pillText: pillText,
                //     ),
                //     const SizedBox(width: 10),
                //     Icon(icon, size: 20, color: clr),
                //   ],
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pnlChip({
    required String label,
    required double value,
    required Color pillBg,
    required Color pillText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: pillText.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${value >= 0 ? '+' : ''}₹${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: pillText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Only show the BhavTav AppBar when on the Home Tab (index 0)
      appBar: _buildAppBar(),

      // IndexedStack keeps your WebSockets alive in the background when switching tabs
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          // Tab 0: Your existing Home Screen layout
          const HomeScreen(),

          // Tab 1: Alerts
          const AlertHistoryScreen(),

          // Tab 2: Trades
          const TradeLedgerScreen(),

          // Tab 3: Profile
          const ProfileScreen(), // Ensure this matches your import ('ProfileScreen' or 'UserProfileScreen')
        ],
      ),

      // ── NEW: Bottom Navigation Bar ─────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1F63FF),
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            activeIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Trades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ... [Keep all your existing widget builder methods: _buildWatchlistCard, _buildAppBar, etc.] ...
}
