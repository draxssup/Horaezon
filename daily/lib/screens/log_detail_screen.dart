import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_log.dart';
import '../utils/log_storage.dart';
import 'full_screen_image_viewer.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LogDetailScreen extends StatefulWidget {
  final DailyLog log;

  const LogDetailScreen({Key? key, required this.log}) : super(key: key);

  @override
  State<LogDetailScreen> createState() => _LogDetailScreenState();
}

class _LogDetailScreenState extends State<LogDetailScreen> {
  List<DailyLog> _relatedLogs = [];

  @override
  void initState() {
    super.initState();
    _loadRelatedLogs();
  }

  Future<void> _loadRelatedLogs() async {
    final allLogs = await LogStorage.loadLogs();
    final currentLogDate = DateTime.parse(widget.log.date);

    final startOfWeek = currentLogDate.subtract(Duration(days: currentLogDate.weekday));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final filtered = allLogs
        .where((l) =>
            l.date != widget.log.date &&
            DateTime.parse(l.date).isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            DateTime.parse(l.date).isBefore(endOfWeek.add(const Duration(days: 1))))
        .toList();

    filtered.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

    setState(() {
      _relatedLogs = filtered;
    });
  }

  Future<void> _deleteLog(BuildContext context) async {
    List<DailyLog> logs = await LogStorage.loadLogs();
    logs.removeWhere((item) => item.date == widget.log.date);
    await LogStorage.saveLogs(logs);
    Navigator.pop(context);
  }

  void _showQRCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('QR Code for Log Text'),
        content: SizedBox(
          height: 200,
          width: 200,
          child: QrImageView(
            data: widget.log.text.isNotEmpty ? widget.log.text : "No content",
            version: QrVersions.auto,
            size: 200.0,
            errorStateBuilder: (ctx, err) => const Center(
              child: Text('Something went wrong.'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(widget.log.date);
    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Detail'),
        backgroundColor: const Color.fromARGB(209, 115, 255, 69),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => _showQRCodeDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Hero(
            tag: 'date_${widget.log.date}',
            child: Material(
              color: Colors.transparent,
              child: Text(
                formattedDate,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (widget.log.city != null && widget.log.city!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                "In ${widget.log.city!}",
                style: const TextStyle(fontSize: 18, color: Colors.black87),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            ["😞", "😕", "😐", "🙂", "😊"][widget.log.mood],
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 16),
          Text(
            widget.log.text,
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          if (widget.log.imagePath != null &&
              widget.log.imagePath!.isNotEmpty &&
              File(widget.log.imagePath!).existsSync())
            GestureDetector(
              onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FullScreenImageViewer(
        imagePath: widget.log.imagePath!,
        log: widget.log,
      ),
    ),
  );
},

            

              child: Hero(
                tag: 'image_${widget.log.date}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(widget.log.imagePath!),
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          if (_relatedLogs.isNotEmpty) ...[
            const Text(
              "Earlier that week…",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _relatedLogs.length,
                itemBuilder: (context, index) {
                  final log = _relatedLogs[index];
                  return GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => LogDetailScreen(log: log)),
                    ),
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('MMM d').format(DateTime.parse(log.date)),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              log.text,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _deleteLog(context),
              icon: const Icon(Icons.delete_outline),
              label: const Text("Delete Log"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
