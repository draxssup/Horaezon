import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int totalUsers = 0;
  int totalLogs = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final usersResponse = await http.get(Uri.parse('https://daily-backup-server.onrender.com/total_users'));
    final logsResponse = await http.get(Uri.parse('https://daily-backup-server.onrender.com/total_logs'));

    if (usersResponse.statusCode == 200) {
      setState(() {
        totalUsers = jsonDecode(usersResponse.body)['total_users'];
      });
    }

    if (logsResponse.statusCode == 200) {
      setState(() {
        totalLogs = jsonDecode(logsResponse.body)['total_logs'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50, 
      appBar: AppBar(
        title: Text('Admin Dashboard', style: TextStyle(color: Colors.green.shade900)),
        backgroundColor: Colors.green.shade50,
        elevation: 1, 
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.green.shade900),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header for Insights & Analytics Section
            Text(
              'App Insights & Analytics',
              style: TextStyle(
                color: Colors.green.shade900,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            // Usage Statistics Section
            Card(
              color: Colors.green.shade100, 
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow('Total Users:', totalUsers.toString()),
                    _buildStatRow('Total Logs:', totalLogs.toString()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to create stat rows
  Widget _buildStatRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.black87, // Dark text for better contrast on light background
              fontSize: 18,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.green.shade900, // Green for the value to match the light theme
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: AdminScreen(),
  ));
}
