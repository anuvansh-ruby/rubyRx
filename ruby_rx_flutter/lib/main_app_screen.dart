import 'package:flutter/material.dart';
import 'common/color_pallet/color_pallet.dart';
import 'common/widgets/app_text.dart';

class MainAppScreen extends StatelessWidget {
  const MainAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.heading5('Ruby AI'),
        backgroundColor: RubyColors.blue,
        foregroundColor: RubyColors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rocket_launch, size: 80, color: RubyColors.blue),
            SizedBox(height: 20),
            AppText.heading3('Welcome to Ruby AI!', color: RubyColors.black),
            SizedBox(height: 10),
            AppText.bodyLarge(
              'Your AI-powered Flutter app is ready',
              color: RubyColors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
