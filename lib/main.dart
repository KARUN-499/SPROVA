import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sprova/core/config/app_config.dart';
import 'package:sprova/features/enrollment/presentation/enrollment_screen.dart';
import 'package:sprova/features/enrollment/presentation/track_payment_screen.dart';
import 'package:sprova/features/auth/login_screen.dart';
import 'package:sprova/features/dashboard/dashboard_screen.dart';
import 'package:sprova/features/admin/admin_screen.dart';

const _adminEmail = 'karun@gmail.com';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
  } else {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  }

  runApp(const SprovaApp());
}

class SprovaApp extends StatefulWidget {
  const SprovaApp({super.key});
  @override
  State<SprovaApp> createState() => _SprovaAppState();
}

class _SprovaAppState extends State<SprovaApp> {
  final _sb = Supabase.instance.client;
  late final StreamSubscription<AuthState> _authSub;
  Widget _home = const _Splash();

  @override
  void initState() {
    super.initState();
    _resolveAndSet();
    

_authSub = _sb.auth.onAuthStateChange.listen((data) {
  if (!mounted) return;
  final event = data.event;
  if (event == AuthChangeEvent.signedIn ||
      event == AuthChangeEvent.tokenRefreshed) {
    Future.delayed(const Duration(milliseconds: 500), _resolveAndSet);
  } else if (event == AuthChangeEvent.signedOut) {
    setState(() => _home = const EnrollmentScreen());
  }

});
  }

  Future<void> _resolveAndSet() async {
    final w = await _resolveHome();
    if (mounted) setState(() => _home = w);
  }

  Future<Widget> _resolveHome() async {
    final session = _sb.auth.currentSession;

    // Not logged in → show landing page (EnrollmentScreen is the hero)
    if (session == null) return const EnrollmentScreen();

    final email = session.user.email ?? '';

    // Admin bypass
    if (email == _adminEmail) return const AdminScreen();

    // Check paid enrollment
    try {
      final enrollment = await _sb
          .from('enrollments')
          .select('id')
          .eq('user_email', email)
          .eq('payment_status', 'completed')
          .maybeSingle();
      if (enrollment != null) return const DashboardScreen();
    } catch (_) {}

    // Logged in but not paid → track selection + payment
    return const TrackPaymentScreen();
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0D0D0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8780A),
          brightness: Brightness.dark,
        ),
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute<void>(builder: (_) => const LoginScreen());
          case '/dashboard':
            return MaterialPageRoute<void>(
              builder: (_) => const DashboardScreen(),
            );
          case '/admin':
            return MaterialPageRoute<void>(builder: (_) => const AdminScreen());
          case '/enroll':
            return MaterialPageRoute<void>(
              builder: (_) => const EnrollmentScreen(),
            );
          default:
            return MaterialPageRoute<void>(
              builder: (_) => const LoginScreen(),
            );
        }
      },
      home: _home,
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF0D0D0F),
    body: Center(
      child: CircularProgressIndicator(
        color: Color(0xFFE8780A),
        strokeWidth: 2,
      ),
    ),
  );
}
