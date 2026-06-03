import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:parvexglobal/services/RestApiServices.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final fullName = TextEditingController();
  final phone = TextEditingController();
  final gender = TextEditingController();
  final dob = TextEditingController();
  final address1 = TextEditingController();
  final address2 = TextEditingController();
  final city = TextEditingController();
  final stateField = TextEditingController();
  final pincode = TextEditingController();
  final country = TextEditingController();
  final profileImage = TextEditingController();

  final userId = 1;

  late RestApiService service;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    service = RestApiService();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadUser());
  }

  // Used for saving/updating actions
  void showLoader() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1F63FF)),
        );
      },
    );
  }

  void hideLoader() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> loadUser() async {
    try {
      final data = await service.getUser();

      fullName.text = data["fullName"] ?? "";
      phone.text = data["phone"] ?? "";
      gender.text = data["gender"] ?? "";
      dob.text = data["dateOfBirth"] ?? "";
      address1.text = data["addressLine1"] ?? "";
      address2.text = data["addressLine2"] ?? "";
      city.text = data["city"] ?? "";
      stateField.text = data["state"] ?? "";
      pincode.text = data["pincode"] ?? "";
      country.text = data["country"] ?? "";
      profileImage.text = data["profileImageUrl"] ?? "";

    } catch (xe) {
      debugPrint("Error loading user: $xe");
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    showLoader();
    final body = {
      "fullName": fullName.text,
      "phone": phone.text,
      "gender": gender.text,
      "dateOfBirth": dob.text,
      "addressLine1": address1.text,
      "addressLine2": address2.text,
      "city": city.text,
      "state": stateField.text,
      "pincode": pincode.text,
      "country": country.text,
      "profileImageUrl": profileImage.text,
    };

    try {
      final ok = await service.updateUser(userId, body);
      hideLoader();

      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Profile updated successfully"),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      hideLoader();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update profile: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void logout() {
    Navigator.of(context).pushNamedAndRemoveUntil("/login", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F63FF)))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),

                _buildSectionHeader("Personal Information"),
                _buildTextField("Full Name", fullName, icon: Icons.person_outline),
                _buildTextField("Phone", phone, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                Row(
                  children: [
                    Expanded(child: _buildTextField("Gender", gender)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField("Date Of Birth", dob, icon: Icons.calendar_today_outlined)),
                  ],
                ),

                _buildSectionHeader("Address Details"),
                _buildTextField("Address Line 1", address1, icon: Icons.home_outlined),
                _buildTextField("Address Line 2", address2),
                Row(
                  children: [
                    Expanded(child: _buildTextField("City", city)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField("State", stateField)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildTextField("Pincode", pincode, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField("Country", country)),
                  ],
                ),

                _buildSectionHeader("Account Settings"),
                _buildTextField("Profile Image URL", profileImage, icon: Icons.link_rounded),

                const SizedBox(height: 32),

                // ── Update Button ─────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saveUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F63FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Logout Button ─────────────────────────────────────
                Center(
                  child: TextButton.icon(
                    onPressed: logout,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    label: const Text(
                      "Log Out",
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildProfileHeader() {
    final initials = fullName.text.isNotEmpty
        ? fullName.text.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';

    return Center(
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: const Color(0xFF1F63FF).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1F63FF).withOpacity(0.3), width: 2),
            ),
            child: ClipOval(
              child: profileImage.text.isNotEmpty
                  ? Image.network(
                profileImage.text,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(initials),
              )
                  : _buildAvatarPlaceholder(initials),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fullName.text.isNotEmpty ? fullName.text : "User Profile",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.2),
          ),
          if (phone.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              phone.text,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF1F63FF),
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade400, size: 20) : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1F63FF), width: 1.5),
          ),
        ),
      ),
    );
  }
}