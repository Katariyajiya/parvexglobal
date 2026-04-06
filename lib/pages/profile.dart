import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((duration) => loadUser());
  }

  Future<void> loadUser() async {
    try {

      showLoader();

      final data = await userService.getUser();

      setState(() {
        name = data["fullName"] ?? "";
        phone = data["phone"] ?? "";
        email = data["email"] ?? "";
        profileImage = data["profileImageUrl"] ?? "";
        loading = false;
      });

    } catch (e) {
      debugPrint("User load error: $e");
    }
    hideLoader();
  }

  void showLoader() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void hideLoader() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),

      body: SingleChildScrollView(
        child: Column(
          children: [

            _buildProfileHeader(),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),

              child: OutlinedButton(
                onPressed: () async {

                  await AuthService.logout();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false,
                  );

                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),

            const SizedBox(height: 80),

          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {

    String initials = "";

    if (name.isNotEmpty) {
      final parts = name.split(" ");
      initials = parts.map((e) => e[0]).take(2).join();
    }

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

          Align(
            alignment: Alignment.topRight,
            child: _buildEditButton(),
          ),

          const SizedBox(height: 10),

          Container(
            height: 90,
            width: 90,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                  color: Colors.white24,
                  width: 2
              ),
            ),

            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            email,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            phone,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEditButton() {

    return GestureDetector(

      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen()));
        loadUser();
      },

      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6
        ),

        decoration: BoxDecoration(
          color: const Color(0xFFFFB74D).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),

        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            Icon(
              Icons.edit,
              color: Color(0xFFFFB74D),
              size: 14,
            ),

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
      ),
    );
  }
}

class _IconPillButton extends StatelessWidget {

  const _IconPillButton({
    required this.icon,
    required this.onTap,
  });

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

        child: Icon(
          icon,
          color: const Color(0xFF0D1B2A),
        ),
      ),
    );
  }
}