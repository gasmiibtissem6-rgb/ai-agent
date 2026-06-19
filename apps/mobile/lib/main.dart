import 'package:flutter/material.dart';

import 'core/config/api_config.dart';
import 'core/network/api_client.dart';
import 'core/network/api_endpoints.dart';

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

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const _apiClient = ApiClient();

  _ProbeState _configurationProbe = const _ProbeState.idle();
  _ProbeState _dealProbe = const _ProbeState.idle();

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

  Future<void> _runProbe({
    required String endpoint,
    required void Function(_ProbeState state) update,
  }) async {
    update(const _ProbeState.loading());

    try {
      final response = await _apiClient.getJson(endpoint);
      final label = response['message'] ?? response['module'] ?? 'Connected';

      update(_ProbeState.success(label.toString()));
    } catch (error) {
      update(_ProbeState.error(error.toString()));
    }
  }

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
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backend API foundation',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(ApiConfig.baseUrl),
                    const SizedBox(height: 12),
                    _ApiProbeButton(
                      label: 'Test configuration',
                      endpoint: ApiEndpoints.configurationStatus,
                      state: _configurationProbe,
                      onPressed: () => _runProbe(
                        endpoint: ApiEndpoints.configurationStatus,
                        update: (state) =>
                            setState(() => _configurationProbe = state),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ApiProbeButton(
                      label: 'Test deal readiness',
                      endpoint: ApiEndpoints.dealFoundation,
                      state: _dealProbe,
                      onPressed: () => _runProbe(
                        endpoint: ApiEndpoints.dealFoundation,
                        update: (state) => setState(() => _dealProbe = state),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
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

class _ApiProbeButton extends StatelessWidget {
  const _ApiProbeButton({
    required this.endpoint,
    required this.label,
    required this.onPressed,
    required this.state,
  });

  final String endpoint;
  final String label;
  final VoidCallback onPressed;
  final _ProbeState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = state.status == _ProbeStatus.loading;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        endpoint,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: isLoading ? null : onPressed,
                  child: Text(isLoading ? 'Testing...' : 'Test'),
                ),
              ],
            ),
            if (state.message != null) ...[
              const SizedBox(height: 10),
              Text(
                state.message!,
                style: TextStyle(
                  color: switch (state.status) {
                    _ProbeStatus.success => Colors.green.shade800,
                    _ProbeStatus.error => Colors.red.shade800,
                    _ => Colors.black54,
                  },
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _ProbeStatus { idle, loading, success, error }

class _ProbeState {
  const _ProbeState._(this.status, [this.message]);

  const _ProbeState.idle() : this._(_ProbeStatus.idle);

  const _ProbeState.loading()
    : this._(_ProbeStatus.loading, 'Waiting for backend response...');

  const _ProbeState.success(String message)
    : this._(_ProbeStatus.success, 'Connected: $message');

  const _ProbeState.error(String message)
    : this._(_ProbeStatus.error, 'Failed: $message');

  final _ProbeStatus status;
  final String? message;
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
