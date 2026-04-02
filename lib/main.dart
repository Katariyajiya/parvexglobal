import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parvexglobal/pages/add_instrument.dart';
import 'package:parvexglobal/pages/auth/login_screen.dart';
import 'package:parvexglobal/pages/home_screen.dart';
import 'package:parvexglobal/pages/onboarding/onboarding.dart';
import 'package:parvexglobal/pages/profile.dart';
import 'package:parvexglobal/utils/user_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hasSession = await UserSession.loadSession();

  runApp(MyApp(hasSession: hasSession));
}

class MyApp extends StatelessWidget {
  final bool hasSession;

  const MyApp({super.key, required this.hasSession});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: hasSession ? HomeScreen() : LoginScreen(),
    );
  }
}
