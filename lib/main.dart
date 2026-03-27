import 'package:flutter/material.dart';
import 'package:parvexglobal/pages/add_instrument.dart';
import 'package:parvexglobal/pages/auth/login_screen.dart';
import 'package:parvexglobal/pages/auth/otp_verification.dart';
import 'package:parvexglobal/pages/auth/register_screen.dart';
import 'package:parvexglobal/pages/home_screen.dart';
import 'package:parvexglobal/pages/instrument_detail.dart';
import 'package:parvexglobal/pages/onboarding/onboarding.dart';
import 'package:parvexglobal/pages/profile.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: SplashScreen()
    );
  }
}


