import 'package:flutter/material.dart';
import '../home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 1. Create a boolean variable to track the checkbox state
  bool _isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.30,
            width: double.infinity,
            child: Image.asset(
              "assets/images/authbg.png",
              alignment: Alignment.topCenter,
           //   fit: BoxFit.cover, // Added fit to ensure background looks right
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.78,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
                  ]
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('FIRST NAME', 'Arjun')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('LAST NAME', 'Sharma')),
                      ],
                    ),
                    const SizedBox(height: 25),
                    _buildTextField('EMAIL ADDRESS', 'arjun@email.com'),
                    const SizedBox(height: 25),
                    _buildTextField('MOBILE NUMBER', '+91  |  98765 43210'),
                    const SizedBox(height: 40),

                    // --- FUNCTIONAL CHECKBOX SECTION ---
                    Row(
                      children: [
                        Checkbox(
                          value: _isAgreed, // Use the variable
                          activeColor: Colors.blue.shade600,
                          onChanged: (bool? value) {
                            // 2. Update state when clicked
                            setState(() {
                              _isAgreed = value ?? false;
                            });
                          },
                        ),
                        const Expanded(
                            child: Text(
                                'I agree to the Terms of Service and Privacy Policy',
                                style: TextStyle(fontSize: 12)
                            )
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      // 3. Conditional onPressed: only navigate if _isAgreed is true
                      onPressed: _isAgreed
                          ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()))
                          : null, // Disables button if false
                      style: ElevatedButton.styleFrom(
                        // If disabled, it will automatically use a greyish color
                        backgroundColor: Colors.blue.shade600,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Create Account ', style: TextStyle(color: Colors.white)),
                          const SizedBox(width: 10,),
                          Image.asset("assets/images/arrow1.png", scale: 3,)
                        ],
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

  Widget _buildTextField(String label, String hint, {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}