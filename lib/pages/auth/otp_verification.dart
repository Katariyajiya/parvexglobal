import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parvexglobal/pages/home_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    this.phoneNumber = "+91 98765 43210"
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  // Timer variables
  int _secondsRemaining = 208; // 3 minutes and 28 seconds
  Timer? _timer;

  // OTP Input Variables
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Format seconds into MM:SS
  String get formattedTime {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Blue Background Header
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            child: Image.asset(
              "assets/images/verifyhero.png",
             // fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Header Text
          // SafeArea(
          //   child: Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         const SizedBox(height: 10),
          //         const Text(
          //           'VERIFICATION',
          //           style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          //         ),
          //         const SizedBox(height: 8),
          //         const Text(
          //           'Enter OTP',
          //           style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          //         ),
          //         const SizedBox(height: 8),
          //         Text(
          //           'We sent a 6-digit code to\n${widget.phoneNumber}',
          //           style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),

          // 2. White Form Card

          SizedBox(height: 15,),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.81,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Info Bubble ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F8FF), // Very light blue
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                text: 'Your OTP has been sent via SMS. It will expire in ',
                                style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
                                children: [
                                  TextSpan(text: '5 minutes', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- OTP Input Row ---
                    const Center(
                      child: Text('ENTER 6-DIGIT OTP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) => _buildOTPBox(index)),
                    ),
                    const SizedBox(height: 24),

                    // --- Timer & Resend ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: 'Expires in ',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                            children: [
                              TextSpan(text: formattedTime, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Row(
                          children: const [
                            Icon(Icons.refresh, color: Colors.grey, size: 16),
                            SizedBox(width: 4),
                            Text('Resend OTP', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () {

                        Navigator.push(context, MaterialPageRoute(builder: (context)=>HomeScreen()));
                        String otp = _otpControllers.map((c) => c.text).join();
                        print("Verifying OTP: $otp");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2979FF),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Verify & Continue ->', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 32),

                    // --- Help Checklist ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Didn't receive the OTP?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                          const SizedBox(height: 16),
                          _buildHelpItem(Icons.check_box, Colors.green, "Check your SMS inbox"),
                          const SizedBox(height: 12),
                          _buildHelpItem(Icons.do_not_disturb_on, Colors.red.shade400, "Make sure DND is not activated"),
                          const SizedBox(height: 12),
                          _buildHelpItem(Icons.refresh, Colors.blue, "Resend OTP (available in $formattedTime)", isLink: true),
                          const SizedBox(height: 12),
                          _buildHelpItem(Icons.call, Colors.blue, "Request via Call instead", isLink: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Bottom Action ---
                    Center(
                      child: RichText(
                        text: const TextSpan(
                          text: 'Wrong number? ',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                          children: [
                            TextSpan(text: 'Change Mobile', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Supporting Widgets ---

  // Individual OTP Box
  Widget _buildOTPBox(int index) {
    return SizedBox(
      width: 45,
      height: 55,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1, // Restrict to 1 character
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
        decoration: InputDecoration(
          counterText: "", // Hides the "0/1" counter
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
        ),
        onChanged: (value) {
          // Auto-shift to next box if filled
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          }
          // Shift backwards if deleted
          if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
        },
      ),
    );
  }

  // Help Checklist Item
  Widget _buildHelpItem(IconData icon, Color iconColor, String text, {bool isLink = false}) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: isLink ? Colors.blue : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: isLink ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}