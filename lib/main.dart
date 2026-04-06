import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parvexglobal/pages/add_instrument.dart';
import 'package:parvexglobal/pages/auth/login_screen.dart';
import 'package:parvexglobal/pages/home_screen.dart';
import 'package:parvexglobal/pages/onboarding/onboarding.dart';
import 'package:parvexglobal/pages/profile.dart';
import 'package:parvexglobal/services/auth_service.dart';
import 'package:parvexglobal/utils/user_session.dart';

import 'Mt5SocketTestScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  UserSession.userId = await AuthService.getUserId();
  // UserSession.token = response.token;
  String? userId = UserSession.userId;
  runApp(MyApp(userId));
}

class MyApp extends StatelessWidget {
  final String? userId;

  const MyApp(this.userId, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: GoogleFonts.sourceSans3TextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: userId == null ? LoginScreen() : HomeScreen(),
    );
  }
}
