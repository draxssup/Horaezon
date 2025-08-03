import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/daily_log.dart';

class BackupService {
  static const String baseUrl = "https://daily-backup-server.onrender.com";

  /// BACKUP: Upload user logs to the Flask backend
  static Future<bool> performBackup(BuildContext context, List<DailyLog> logs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('user_id');

      if (userIdStr == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(" User not logged in.")),
        );
        return false;
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(" Invalid user ID format.")),
        );
        return false;
      }

      final url = Uri.parse('$baseUrl/backup');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'logs': logs.map((log) => log.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(' Backup failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint(" Exception during backup: $e");
      return false;
    }
  }

  /// RESTORE: Download user logs from the Flask backend
  static Future<List<DailyLog>?> restoreLogs(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('user_id');

      if (userIdStr == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(" User not logged in.")),
        );
        return null;
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(" Invalid user ID format.")),
        );
        return null;
      }

      final url = Uri.parse('$baseUrl/restore/$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final logsJson = decoded['logs'] as List<dynamic>;
        return logsJson.map((json) => DailyLog.fromJson(json)).toList();
      } else {
        debugPrint(' Restore failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint(" Exception during restore: $e");
      return null;
    }
  }
}
