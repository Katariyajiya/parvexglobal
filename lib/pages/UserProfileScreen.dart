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

    WidgetsBinding.instance.addPostFrameCallback((duration) => loadUser());
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

  Future<void> loadUser() async {
    showLoader();
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

      setState(() {
        loading = false;
      });
    } catch (xe) {}

    hideLoader();
  }

  Future<void> saveUser() async {
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

    final ok = await service.updateUser(userId, body);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated")));
    }
  }

  Widget field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  void logout() {
    Navigator.of(context).pushNamedAndRemoveUntil("/login", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Profile")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                field("Full Name", fullName),
                field("Phone", phone),
                field("Gender", gender),
                field("Date Of Birth", dob),

                field("Address Line 1", address1),
                field("Address Line 2", address2),

                field("City", city),
                field("State", stateField),
                field("Pincode", pincode),
                field("Country", country),

                field("Profile Image URL", profileImage),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: saveUser,
                    child: const Text("Update Profile"),
                  ),
                ),

                const SizedBox(height: 40),

                // SizedBox(
                //   width: double.infinity,
                //   child: ElevatedButton(
                //     style: ElevatedButton.styleFrom(
                //         backgroundColor: Colors.red),
                //     onPressed: logout,
                //     child: const Text("Logout"),
                //   ),
                // )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
