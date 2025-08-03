import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_log.dart';
import '../utils/log_storage.dart';
import 'log_detail_screen.dart';
import '../utils/backup_service.dart';
import 'login_screen.dart';

class LogsViewerScreen extends StatefulWidget {
  const LogsViewerScreen({Key? key}) : super(key: key);

  @override
  _LogsViewerScreenState createState() => _LogsViewerScreenState();
}

class _LogsViewerScreenState extends State<LogsViewerScreen> {
  List<DailyLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    List<DailyLog> loadedLogs = await LogStorage.loadLogs();

    loadedLogs.sort((a, b) =>
        DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

    setState(() {
      _logs = loadedLogs;
    });
  }

  Future<void> _handleBackup() async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Backup"),
        content: const Text("Do you want to back up your current logs?"),
        actions: [
          TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
              child: const Text("Backup"),
              onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await BackupService.performBackup(context, _logs);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? ' Logs backed up successfully!'
              : ' Backup failed!'),
        ),
      );
    }
  }

  Future<void> _handleRestore() async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Restore"),
        content: const Text("Restore will overwrite existing logs. Continue?"),
        actions: [
          TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
              child: const Text("Restore"),
              onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirmed == true) {
      final restoredLogs = await BackupService.restoreLogs(context);
      if (restoredLogs != null) {
        restoredLogs.sort((a, b) =>
            DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
        await LogStorage.saveLogs(restoredLogs);
        setState(() {
          _logs = restoredLogs;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(' Logs restored successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(' Restore failed!')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Color _getMoodColor(int mood) {
    switch (mood) {
      case 0:
        return Colors.red.shade100;
      case 1:
        return Colors.orange.shade100;
      case 2:
        return Colors.grey.shade300;
      case 3:
        return Colors.lightBlue.shade100;
      case 4:
        return Colors.green.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        backgroundColor: const Color.fromARGB(209, 115, 255, 69),
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Backup',
            onPressed: _handleBackup,
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined),
            tooltip: 'Restore',
            onPressed: _handleRestore,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _logs.isEmpty
          ? const Center(child: Text("No logs yet!"))
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: _getMoodColor(log.mood),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      DateFormat('EEE, MMM d, yyyy')
                          .format(DateTime.parse(log.date)),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (log.city != null && log.city!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text("📍 ${log.city!}",
                                style: const TextStyle(
                                    color: Color.fromARGB(171, 31, 29, 29),
                                    fontSize: 15)),
                          ),
                        const SizedBox(height: 8),
                        Text(log.text),
                        const SizedBox(height: 8),
                        Text(
                            "Mood: ${["😞", "😕", "😐", "🙂", "😊"][log.mood]}"),
                        if (log.imagePath != null &&
                            log.imagePath!.isNotEmpty &&
                            File(log.imagePath!).existsSync())
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(log.imagePath!),
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LogDetailScreen(log: log),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
