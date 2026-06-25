import 'package:flutter/material.dart';

void main() {
  runApp(const IdealApp());
}

class IdealApp extends StatelessWidget {
  const IdealApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDEAL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const areas = [
    _AreaItem(
      icon: Icons.people_outline,
      title: 'Users',
      description: 'Create accounts, manage profiles, and join deals.',
    ),
    _AreaItem(
      icon: Icons.verified_user_outlined,
      title: 'Identity',
      description: 'Build trust with identity verification flows.',
    ),
    _AreaItem(
      icon: Icons.handshake_outlined,
      title: 'Deals',
      description: 'Create agreements, invite parties, and negotiate terms.',
    ),
    _AreaItem(
      icon: Icons.description_outlined,
      title: 'Contracts',
      description: 'Keep approved deal versions locked and official.',
    ),
    _AreaItem(
      icon: Icons.check_circle_outline,
      title: 'Approvals',
      description:
          'Confirm that every required party accepts the same version.',
    ),
    _AreaItem(
      icon: Icons.notifications_outlined,
      title: 'Notifications',
      description: 'Stay updated on invitations, approvals, and changes.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            const _Logo(),
            const SizedBox(height: 24),
            Text(
              'IDEAL',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Trusted digital deals and contracts for people, companies, and every involved party.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Main areas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...areas.map(
              (area) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AreaCard(area: area),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/logo/ideal-logo.png',
          width: 96,
          height: 96,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area});

  final _AreaItem area;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(area.icon, color: colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    area.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    area.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaItem {
  const _AreaItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
