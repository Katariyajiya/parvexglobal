import 'package:flutter/material.dart';

import '../helper/bottom_navigation_bar.dart';

class Alert extends StatelessWidget {
  const Alert({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 2,),
      body: Center(child: Text("Alert Screen")),
    );
  }
}
