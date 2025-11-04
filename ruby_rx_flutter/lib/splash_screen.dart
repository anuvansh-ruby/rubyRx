import 'package:flutter/material.dart';
import 'common/color_pallet/color_pallet.dart';
import 'common/widgets/app_text.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _startSplashSequence();
  }

  void _startSplashSequence() async {
    // Start the fade-in animation
    _animationController.forward();

    // Wait for 3 seconds total (1.5s animation + 1.5s display)
    await Future.delayed(const Duration(milliseconds: 3000));

    // Call the completion callback
    widget.onComplete();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RubyColors.white,
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main Ruby AI Logo
                  Image.asset(
                    'lib/assets/ruby_rx_logo_real.png',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 80),

                  // Powered by text
                  AppText.bodyLarge('Powered by', color: RubyColors.grey),

                  const SizedBox(height: 12),

                  // Anuvansh Logo
                  Image.asset(
                    'lib/assets/anuvansh_logo.png',
                    width: 120,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
