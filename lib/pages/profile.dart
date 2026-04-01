import 'package:flutter/material.dart';
import 'package:parvexglobal/helper/bottom_navigation_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _priceAlertsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // bottomNavigationBar: CustomBottomNavBar(currentIndex: 3),
      backgroundColor: const Color(0xFFF8F9FE), // Light background for cards
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Blue Profile Header
            _buildProfileHeader(),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Stats Row (Watchlist, Alerts, Categories)
                  _buildStatsRow(),
                  const SizedBox(height: 24),

                  // 3. Account Section
                  // const Text('ACCOUNT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8E99AF), letterSpacing: 1.1)),
                  // const SizedBox(height: 12),
                  // _buildAccountCard(),
                  // const SizedBox(height: 24),

                  // 4. Preferences Section
                  const Text(
                    'PREFERENCES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8E99AF),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPreferencesCard(),
                  const SizedBox(height: 40), // Space for Bottom Nav
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B3E), Color(0xFF1A2A4D)],
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: _IconPillButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.maybePop(context),
            ),
          ),

          Align(alignment: Alignment.topRight, child: _buildEditButton()),
          // Profile Image Avatar
          Container(
            height: 90,
            width: 90,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: const Center(
              child: Text(
                'AS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Arjun Sharma',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            '+91 98765 43210',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          // Pro Member Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'Pro Member',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB74D).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.edit, color: Color(0xFFFFB74D), size: 14),
          SizedBox(width: 4),
          Text(
            'Edit',
            style: TextStyle(
              color: Color(0xFFFFB74D),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem('12', 'Watchlist', Colors.blue),
        _buildStatItem('5', 'Alerts', Colors.green),
        _buildStatItem('4', 'Categories', Colors.orange),
      ],
    );
  }

  Widget _buildStatItem(String val, String label, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.28,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8E99AF), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildSettingsTile(
            Icons.person,
            'Personal Info',
            'Name, email, mobile',
            Colors.blue.shade50,
            Colors.blue,
          ),
          const Divider(height: 1, indent: 60),
          _buildSettingsTile(
            Icons.security,
            'Security',
            'Password, PIN, 2FA',
            Colors.green.shade50,
            Colors.green,
          ),
          const Divider(height: 1, indent: 60),
          _buildSettingsTile(
            Icons.credit_card,
            'Subscription',
            'Pro Plan — Active',
            Colors.orange.shade50,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_active,
              color: Colors.amber,
              size: 20,
            ),
          ),
          title: const Text(
            'Price Alerts',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: const Text(
            'Push notifications',
            style: TextStyle(fontSize: 12, color: Color(0xFF8E99AF)),
          ),
          trailing: Switch(
            value: _priceAlertsEnabled,
            activeTrackColor: const Color(0xFF00C853),
            onChanged: (val) => setState(() => _priceAlertsEnabled = val),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String sub,
    Color bg,
    Color iconCol,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconCol, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        sub,
        style: const TextStyle(fontSize: 12, color: Color(0xFF8E99AF)),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
      onTap: () {},
    );
  }
}

class _IconPillButton extends StatelessWidget {
  const _IconPillButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5FB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: const Color(0xFF0D1B2A)),
      ),
    );
  }
}
