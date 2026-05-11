import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth_screen.dart';
import 'screens/firebase_required_screen.dart';
import 'screens/home_shell.dart';
import 'services/app_state.dart';
import 'services/firebase_service.dart';
import 'widgets/modern_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseService = FirebaseService();
  final firebaseInit = firebaseService.initialize();
  final preferencesFuture = SharedPreferences.getInstance();
  await firebaseInit;
  final preferences = await preferencesFuture;

  final appState = AppState(
    firebaseService: firebaseService,
    preferences: preferences,
  );
  await appState.bootstrap();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const SmartJobAssistantApp(),
    ),
  );
}

class SmartJobAssistantApp extends StatelessWidget {
  const SmartJobAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = context.select<AppState, bool>(
      (state) => state.profile.darkMode,
    );

    return MaterialApp(
      title: 'AutoHire AI',
      debugShowCheckedModeBanner: false,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      builder: (context, child) {
        final scale =
            MediaQuery.textScalerOf(context).scale(1.0).clamp(0.9, 1.0);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale.toDouble()),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const _SplashGate(),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final seededScheme = ColorScheme.fromSeed(
      seedColor: ModernColors.purple,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;
    final colorScheme = isDark
        ? seededScheme.copyWith(
            primary: ModernColors.purple,
            secondary: ModernColors.teal,
            tertiary: ModernColors.mint,
            surface: ModernColors.darkSurface,
            surfaceContainerHigh: ModernColors.darkSurfaceHigh,
            surfaceContainerHighest: const Color(0xFF2E2848),
            onSurface: const Color(0xFFF7F3FF),
            onSurfaceVariant: const Color(0xFFC9C2DA),
            outlineVariant: const Color(0xFF3D3558),
            primaryContainer: const Color(0xFF342A78),
            onPrimaryContainer: const Color(0xFFF3EFFF),
            secondaryContainer: const Color(0xFF153E42),
            onSecondaryContainer: const Color(0xFFE4FEFD),
            errorContainer: const Color(0xFF5A1D2A),
            onErrorContainer: const Color(0xFFFFE5EA),
          )
        : seededScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 42, fontWeight: FontWeight.w800),
        displayMedium: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
        displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        headlineSmall: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 15),
        bodyMedium: TextStyle(fontSize: 14),
        bodySmall: TextStyle(fontSize: 12),
      ),
      scaffoldBackgroundColor:
          isDark ? ModernColors.darkPage : ModernColors.page,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ModernColors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ModernColors.purple, width: 1.4),
        ),
      ),
    );
  }
}

class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const _AppGate();

    return Scaffold(
      backgroundColor: ModernColors.darkPage,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AutoHireLogo(size: 86),
                const SizedBox(height: 18),
                Text(
                  'AutoHire AI',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Jobs. Resume. Tracker.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    final firebaseEnabled = context.select<AppState, bool>(
      (state) => state.firebaseEnabled,
    );
    final isAuthenticated = context.select<AppState, bool>(
      (state) => state.isAuthenticated,
    );

    if (!firebaseEnabled) {
      return const FirebaseRequiredScreen();
    }

    if (!isAuthenticated) {
      return const AuthScreen();
    }

    return const HomeShell();
  }
}
