import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily/screens/login_screen.dart';
import 'package:daily/screens/calendar_screen.dart';

final DateTime appStartTime = DateTime.now(); // Startup tracking start

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Make sure binding is initialized
  runApp(const MyApp());
  final duration = DateTime.now().difference(appStartTime);
  developer.log(' App launched in ${duration.inMilliseconds} ms');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily',
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: kDebugMode, // Optional performance bars
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Akatab',
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _userId;
  bool _loading = true;
  late DateTime _authStartTime;

  @override
  void initState() {
    super.initState();
    _authStartTime = DateTime.now();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final duration = DateTime.now().difference(_authStartTime);
    developer.log(' AuthGate + SharedPreferences load: ${duration.inMilliseconds} ms');

    _logMemoryUsage();

    setState(() {
      _userId = prefs.getString('user_id');
      _loading = false;
    });
  }

  void _logMemoryUsage() {
    // Simulated logging: you can add real VM service usage for deeper info
    developer.log(' Approx. memory usage (not accurate in debug): use DevTools for full profiling');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalStartupTime = DateTime.now().difference(appStartTime);
    developer.log('App ready & screen rendered in ${totalStartupTime.inMilliseconds} ms');

    return _userId == null ? const LoginScreen() : const CalendarScreen();
  }
}
