import 'package:daily/utils/backup_service.dart';
import 'package:daily/utils/log_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'calendar_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  String? _userId;

  final String baseUrl = 'https://daily-backup-server.onrender.com';

  Future<void> signup() async {
    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _email.text.trim(),
          'password': _password.text,
        }),
      );

      setState(() => _loading = false);

      print('Signup Status Code: ${response.statusCode}');
      print('Signup Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = data['user_id'];

        if (userId != null) {
          setState(() {
            _userId = userId.toString();
            _otpSent = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent to your Telegram')),
          );
        }
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? 'Signup failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup error: $e')),
      );
    }
  }

  Future<void> verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _email.text.trim(),
          'otp': otp,
        }),
      );

      setState(() => _loading = false);

      print('OTP Verification Status Code: ${response.statusCode}');
      print('OTP Verification Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = data['user_id'];

        if (userId != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', userId.toString());

          final restoredLogs = await BackupService.restoreLogs(context);
          if (restoredLogs != null) {
            restoredLogs.sort((a, b) =>
                DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
            await LogStorage.saveLogs(restoredLogs);
            debugPrint(" Restored ${restoredLogs.length} logs after signup");
          } else {
            debugPrint(" No logs restored");
          }

          Navigator.of(context, rootNavigator: true).pushReplacement(
            MaterialPageRoute(builder: (_) => const CalendarScreen()),
          );
        }
      } else {
        final errorMsg = jsonDecode(response.body)['message'] ?? 'OTP verification failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verification error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final greenPrimary = Colors.green.shade600;
    final inputFill = Colors.white;

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade100,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(
                  "Create an Account",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: greenPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone),
                    labelText: "Phone",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: inputFill,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock),
                    labelText: "Password",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: inputFill,
                  ),
                ),
                const SizedBox(height: 24),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _otpSent ? null : signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: greenPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                const SizedBox(height: 16),
                if (_otpSent)
                  Column(
                    children: [
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          labelText: "Enter OTP",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: inputFill,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: greenPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          "Verify OTP",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    "Already have an account? Log in",
                    style: TextStyle(
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
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
