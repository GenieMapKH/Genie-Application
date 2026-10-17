import 'package:flutter/material.dart';

/// Shown instead of the app when a debug run was started without the env
/// file, so it never quietly talks to the production server.
///
/// Developer-facing, so it is plain English and depends on nothing that
/// has not been loaded yet (no theme, no translations, no providers).
class MissingConfigApp extends StatelessWidget {
  static const debugCommand = 'flutter run --dart-define-from-file=.env';

  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.settings_suggest_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  'No API server is set',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'The API server is compiled into the app from an env file. '
                  'Start the app with:',
                ),
                const SizedBox(height: 12),
                const SelectableText(
                  debugCommand,
                  style: TextStyle(fontFamily: 'monospace'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'In VS Code, press F5 and pick "Genie (debug, .env)". '
                  'Copy .env.example to .env first if you have no .env.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
