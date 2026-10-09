import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pre-warm the Python AI Agent on Render (wakes it from sleep if idle)
    // This is fire-and-forget; we don't await it so the splash isn't blocked.
    http.get(Uri.parse('https://chargesync-platform-agentic-ai.onrender.com/docs'))
        .catchError((_) => http.Response('', 500));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for the animation to finish + a little extra time
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background matching the theme
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/chargesync_icon.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
                semanticLabel: 'ChargeSync logo',
              ),
              const SizedBox(height: 20),
              const Text.rich(
                TextSpan(children: [
                  TextSpan(text: 'CHARGE'),
                  TextSpan(
                    text: 'SYNC',
                    style: TextStyle(color: Color(0xFF5EEAD4)),
                  ),
                ]),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'POWERING TOMORROW',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
