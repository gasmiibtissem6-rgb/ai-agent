import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF030712), Color(0xFF0B172E), Color(0xFF030712)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),
                          
                          // Logo with Pulse Animation
                          ScaleTransition(
                            scale: Tween<double>(begin: 0.96, end: 1.04).animate(
                              CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 130,
                              height: 130,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Brand Name
                          const Text(
                            'IDEAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          
                          // Brand Slogan
                          const Text(
                            'Secure Deal Management',
                            style: TextStyle(
                              color: Color(0xFF00B4D8), // Icy blue highlight
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                          
                          const Spacer(flex: 3),
                          
                          // Centered Features List
                          _buildFeatureItem(
                            icon: Icons.shield_outlined,
                            title: 'Secure Contract Management',
                            description: 'Encrypt, verify, and co-sign legal agreements with complete assurance.',
                            theme: theme,
                          ),
                          const SizedBox(height: 28),
                          _buildFeatureItem(
                            icon: Icons.sync_alt_outlined,
                            title: 'Real-Time Collaboration',
                            description: 'Instantly sync updates and co-author terms with partners on the fly.',
                            theme: theme,
                          ),
                          const SizedBox(height: 28),
                          _buildFeatureItem(
                            icon: Icons.edit_note_outlined,
                            title: 'Built-in Negotiation Tools',
                            description: 'Easily track document revisions, audits, and final consensus.',
                            theme: theme,
                          ),
                          
                          const Spacer(flex: 4),
                          
                          // CTA Button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => context.go('/login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF02529C),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 8,
                                shadowColor: Colors.black45,
                              ),
                              child: const Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required ThemeData theme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: const Color(0xFF00B4D8), // Matching primary light cyan
            size: 22,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
