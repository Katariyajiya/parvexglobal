
import 'package:flutter/material.dart';
import 'package:parvexglobal/pages/AlertHistoryScreen.dart';
import 'package:parvexglobal/pages/home_screen.dart';
import 'package:parvexglobal/pages/profile.dart';
import 'package:parvexglobal/pages/trade_ledger_screen.dart';

class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  int _currentTabIndex = 0;

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
      ],
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