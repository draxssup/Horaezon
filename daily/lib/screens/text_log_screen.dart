import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_log.dart';
import '../utils/log_storage.dart';
import '../utils/location_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'qr_scan_screen.dart';

class TextLogScreen extends StatefulWidget {
  final DateTime selectedDate;
  const TextLogScreen({Key? key, required this.selectedDate}) : super(key: key);

  @override
  _TextLogScreenState createState() => _TextLogScreenState();
}

class _TextLogScreenState extends State<TextLogScreen> {
  int? _selectedMood;
  final TextEditingController _textController = TextEditingController();
  DailyLog? _existingLog;
  File? _imageFile;
  String? _city;

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  Future<void> _loadLog() async {
    List<DailyLog> logs = await LogStorage.loadLogs();
    _existingLog = logs.firstWhere(
      (log) => log.date == widget.selectedDate.toIso8601String().split('T')[0],
      orElse: () => DailyLog(date: widget.selectedDate.toIso8601String().split('T')[0], mood: 2, text: ''),
    );

    if (_existingLog != null) {
      setState(() {
        _selectedMood = _existingLog?.mood;
        _textController.text = _existingLog?.text ?? '';
        _imageFile = _existingLog?.imagePath != null ? File(_existingLog!.imagePath!) : null;
        _city = _existingLog?.city;
      });
    }
  }

  void _saveLog() async {
    if (_selectedMood == null || _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a mood and write something.')),
      );
      return;
    }

    _city ??= await LocationService.getCityFromLocation();

    final log = DailyLog(
      date: widget.selectedDate.toIso8601String().split('T')[0],
      mood: _selectedMood!,
      text: _textController.text.trim(),
      imagePath: _imageFile?.path,
      city: _city,
    );

    List<DailyLog> logs = await LogStorage.loadLogs();
    logs.removeWhere((entry) => entry.date == log.date);
    logs.add(log);
    await LogStorage.saveLogs(logs);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log saved!')),
    );
  }

  Future<void> _saveDraft() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedMood == null && _imageFile == null) return;

    _city ??= await LocationService.getCityFromLocation();

    final draft = DailyLog(
      date: widget.selectedDate.toIso8601String().split('T')[0],
      mood: _selectedMood ?? 2,
      text: text,
      imagePath: _imageFile?.path,
      city: _city,
    );

    List<DailyLog> logs = await LogStorage.loadLogs();
    logs.removeWhere((entry) => entry.date == draft.date);
    logs.add(draft);
    await LogStorage.saveLogs(logs);

    
  }

  void _deleteLog() async {
    List<DailyLog> logs = await LogStorage.loadLogs();
    logs.removeWhere((log) => log.date == widget.selectedDate.toIso8601String().split('T')[0]);
    await LogStorage.saveLogs(logs);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log deleted!')),
    );

    Navigator.pop(context);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file != null) {
      setState(() {
        _imageFile = File(file.path);
      });
    }
  }

  Future<void> _scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScanScreen()),
    );
    if (result != null && result is String) {
      setState(() {
        _textController.text = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMM d, yyyy').format(widget.selectedDate);

    return WillPopScope(
      onWillPop: () async {
        await _saveDraft();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              await _saveDraft();
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: _saveLog),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _deleteLog),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _showImageOptions(context),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16),
                    image: _imageFile != null
                        ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imageFile == null
                      ? const Center(child: Icon(Icons.add_a_photo, color: Colors.grey, size: 50))
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(dateStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (_city != null) Text("📍 $_city", style: const TextStyle(fontSize: 14)),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        List<String> moods = ["😞", "😕", "😐", "🙂", "😊"];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedMood = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _selectedMood == index ? Colors.green.shade100 : Colors.transparent,
                            ),
                            child: Text(moods[index], style: const TextStyle(fontSize: 28)),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        tooltip: 'Scan QR',
                        onPressed: _scanQRCode,
                      ),
                    ),
                    TextField(
                      controller: _textController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Write something...',
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }
}
