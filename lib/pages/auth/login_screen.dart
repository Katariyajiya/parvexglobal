import 'package:flutter/material.dart';
import 'package:parvexglobal/pages/auth/otp_verification.dart';

import '../../models/otp_request_model.dart';
import '../../services/RestApiServices.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;
  bool isMobileOTP = true; // State to handle the toggle switch

  Future<void> handleGetOtp() async {
    if (phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter mobile number")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final authApi = RestApiService();

      // ⚠️ IMPORTANT:
      // Your backend currently expects EMAIL
      // So either:
      // 1. Change backend to accept phone
      // OR
      // 2. Send dummy email for now

      final response = await authApi.requestOtp(
        OtpRequestModel(
          email: phoneController.text, // adjust based on backend
        ),
      );

      // SUCCESS
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );

      // Navigate only after success
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OtpVerificationScreen(
           phoneNumber: phoneController.text,
        )),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Blue Background Header
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.40,
            width: double.infinity,
            child: Image.asset(
              "assets/images/siginhero.png", // Reusing your existing background asset
              //fit: BoxFit.,
              alignment: Alignment.topCenter,
            ),
          ),

          // Header Text (Overlaying the blue background)
          // SafeArea(
          //   child: Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: const [
          //         SizedBox(height: 20),
          //         Text(
          //           'WELCOME BACK',
          //           style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          //         ),
          //         SizedBox(height: 8),
          //         Text(
          //           'Sign In to\nMarketWatch',
          //           style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2),
          //         ),
          //         SizedBox(height: 8),
          //         Text(
          //           'Your portfolio is waiting',
          //           style: TextStyle(color: Colors.white70, fontSize: 14),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),

          // 2. White Form Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.78,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Custom Toggle Switch ---
                    // Container(
                    //   height: 50,
                    //   padding: const EdgeInsets.all(4),
                    //   decoration: BoxDecoration(
                    //     color: Colors.grey.shade100,
                    //     borderRadius: BorderRadius.circular(12),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       Expanded(child: _buildTab(title: 'Mobile OTP', icon: Icons.phone_iphone, isActive: isMobileOTP, onTap: () => setState(() => isMobileOTP = true))),
                    //       Expanded(child: _buildTab(title: 'Email', icon: Icons.email_outlined, isActive: !isMobileOTP, onTap: () => setState(() => isMobileOTP = false))),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 10),
                    Text("Verify your Email ID", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),

                    const SizedBox(height: 40),

                    // --- Mobile Number Input Area ---
                    const Text('EMAIL ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Country Code Box
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: const [
                              // Text('🇮🇳', style: TextStyle(fontSize: 16)), // Simple emoji for flag
                              // SizedBox(width: 8),
                              // Text('+91', style: TextStyle(fontWeight: FontWeight.bold)),

                              Icon(Icons.mail_outlined,color: Colors.grey,)
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Phone Number TextField
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              hintText: '@gmail.com',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- Password Input Area ---
                    // const Text('PASSWORD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    // const SizedBox(height: 8),
                    // TextField(
                    //   obscureText: true,
                    //   decoration: InputDecoration(
                    //     hintText: 'Enter your Otp',
                    //     hintStyle: TextStyle(color: Colors.grey.shade400),
                    //     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    //     enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    //     focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue)),
                    //   ),
                    // ),
                    //
                    // // --- Forgot Password Link ---
                    // Align(
                    //   alignment: Alignment.centerRight,
                    //   child: TextButton(
                    //     onPressed: () {},
                    //     child: const Text('Forgot Password?', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                    //   ),
                    // ),
                    const SizedBox(height: 18),

                    // --- Sign In Button ---
                    ElevatedButton(
                      onPressed :isLoading ? null : handleGetOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2979FF),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Get OTP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 24),


                    const SizedBox(height: 32),

                    // --- Register Now Link ---
                    // Center(
                    //   child: GestureDetector(
                    //     onTap: () {},
                    //     child: RichText(
                    //       text: const TextSpan(
                    //         text: "Don't have an account? ",
                    //         style: TextStyle(color: Colors.grey, fontSize: 13),
                    //         children: [
                    //           TextSpan(
                    //             text: 'Register Now',
                    //             style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  // Custom Tab for the Toggle Switch
  Widget _buildTab({required String title, required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isActive ? Colors.blue : Colors.grey),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.blue : Colors.grey,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom Outlined Button for Socials
  Widget _buildSocialButton(String brand) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(brand, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}