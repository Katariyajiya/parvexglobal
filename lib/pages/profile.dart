import 'package:flutter/material.dart';
import 'package:parvexglobal/pages/UserProfileScreen.dart';
import 'package:parvexglobal/services/RestApiServices.dart';

import '../services/auth_service.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final RestApiService userService = RestApiService();

  bool loading = true;

  String name = "";
  String email = "";
  String phone = "";
  String profileImage = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadUser());
  }

  Future<void> loadUser() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final data = await userService.getUser();

      if (mounted) {
        setState(() {
          name = data["fullName"] ?? "";
          phone = data["phone"] ?? "";
          email = data["email"] ?? "";
          profileImage = data["profileImageUrl"] ?? "";
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("User load error: $e");
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F63FF)))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 32),

                  // ── Action Menu / Body ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildMenuCard(),
                        const SizedBox(height: 32),

                        // ── Logout Button ────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await AuthService.logout();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (route) => false,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.redAccent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                // border: Border.all(color: Colors.red.shade200),
                              ),
                            ),
                            icon: const Icon(Icons.logout, size: 20),
                            label: const Text(
                              "Log Out",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Header Widget ──────────────────────────────────────────────────────────
  Widget _buildProfileHeader() {
    String initials = "U";
    if (name.trim().isNotEmpty) {
      initials = name.trim().split(" ").map((e) => e.isNotEmpty ? e[0] : "").take(2).join().toUpperCase();
    }

    final bool canPop = Navigator.canPop(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F63FF), Color(0xFF0A3093)], // Brand blue gradient
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // Top Row: Back Button & Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (canPop)
                _IconPillButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.maybePop(context),
                )
              else
                const SizedBox(width: 46), // Placeholder to keep Edit button right-aligned

              _buildEditButton(),
            ],
          ),
          const SizedBox(height: 10),

          // Avatar
          Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: ClipOval(
              child: profileImage.isNotEmpty
                  ? Image.network(
                      profileImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(child: Text(initials, style: _initialsStyle())),
                    )
                  : Center(child: Text(initials, style: _initialsStyle())),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            name.isNotEmpty ? name : "User Name",
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 0.3),
          ),
          const SizedBox(height: 6),

          // Email
          if (email.isNotEmpty)
            Text(
              email,
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500),
            ),

          // Phone
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              phone,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  TextStyle _initialsStyle() {
    return const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold);
  }

  // ── Info/Menu Card ─────────────────────────────────────────────────────────
  Widget _buildMenuCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildMenuRow(Icons.email_outlined, "Email Address", email.isNotEmpty ? email : "Not provided"),
          Divider(height: 1, color: Colors.grey.shade100),
          _buildMenuRow(Icons.phone_outlined, "Phone Number", phone.isNotEmpty ? phone : "Not provided"),
          Divider(height: 1, color: Colors.grey.shade100),
          _buildMenuRow(Icons.security_outlined, "Privacy & Security", "Manage settings"),
        ],
      ),
    );
  }

  Widget _buildMenuRow(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1F63FF).withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF1F63FF), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
    );
  }

  // ── Buttons ────────────────────────────────────────────────────────────────
  Widget _buildEditButton() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen()));
        loadUser(); // Refresh data after returning from edit screen
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white30, width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'Edit Profile',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30, width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
