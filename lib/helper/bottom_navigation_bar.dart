import 'package:flutter/material.dart';
import '../pages/alert.dart';
import '../pages/home_screen.dart';
import '../pages/instrument_detail.dart';
import '../pages/profile.dart';
import '../pages/add_instrument.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _handleNavigation(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const HomeScreen();
        break;
      case 1:
        nextScreen = const InstrumentDetailScreen();
        break;
      case 2:
        nextScreen = const Alert();
        break;
      case 3:
        nextScreen = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => nextScreen,
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: Material is required for InkWell to work inside a BottomAppBar
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              BottomAppBar(
                padding: EdgeInsets.zero,
                color: Colors.white,
                // The notch is what makes the space for the FAB
                shape: const CircularNotchedRectangle(),
                notchMargin: 8.0,
                elevation: 20,
                child: SizedBox(
                  height: 65,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(context, Icons.home_filled, 'Home', 0),
                      _buildNavItem(context, Icons.bar_chart_outlined, 'Markets', 1),
                      const SizedBox(width: 48), // Gap for FAB
                      _buildNavItem(context, Icons.notifications_none, 'Alerts', 2),
                      _buildNavItem(context, Icons.person_outline, 'Profile', 3),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: -25,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddInstrument()),
                    );
                  },
                  backgroundColor: const Color(0xFF2979FF),
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final bool isActive = currentIndex == index;

    return Expanded(
      child: InkWell(
        // Added behavior to ensure the tap is caught even on empty spaces
        onTap: () => _handleNavigation(context, index),
        child: Container(
          // Adding a background color: transparent makes the whole area clickable
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFF2979FF) : const Color(0xFF8E99AF),
                size: 26,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFF2979FF) : const Color(0xFF8E99AF),
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}