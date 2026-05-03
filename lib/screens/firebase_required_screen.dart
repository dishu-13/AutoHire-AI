import 'package:flutter/material.dart';

import '../widgets/modern_ui.dart';

class FirebaseRequiredScreen extends StatelessWidget {
  const FirebaseRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PurpleHero(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ModernIconBox(
                      icon: Icons.cloud_off,
                      background: Colors.white24,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Firebase setup required',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Connect Firebase Spark to enable login, profile sync, saved jobs, tracker data, and resume history.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const ModernCard(
                child: SelectableText(
                  'Firebase Android config is embedded for autohire-ai-8f5f6. If this screen appears, check that the app is running on Android and that Email/Password Auth is enabled.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
