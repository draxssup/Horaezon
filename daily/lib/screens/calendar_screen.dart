import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/weather_service.dart';
import 'text_log_screen.dart';
import 'logs_viewer_screen.dart';
import 'admin_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String _emoji = '🌡️';
  String _temperature = '';

  late StreamSubscription<AccelerometerEvent> _accelSub;
  bool _shakeCooldown = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _startManualShakeListener();
  }

  void _startManualShakeListener() {
    const double shakeThreshold = 15.0;

    _accelSub = accelerometerEvents.listen((AccelerometerEvent event) {
      double magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (magnitude > shakeThreshold && !_shakeCooldown) {
        _shakeCooldown = true;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TextLogScreen(selectedDate: DateTime.now()),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          _shakeCooldown = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _accelSub.cancel();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    final weatherService = WeatherService();
    final data = await weatherService.fetchWeather();
    if (data != null) {
      setState(() {
        _emoji =
            weatherService.getWeatherEmoji(data['condition'], data['icon']);
        _temperature = '${data['temp'].round()}°C';
      });
    }
  }

  Future<void> _handleDoubleTap() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (userId == '-1') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LogsViewerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onDoubleTap: _handleDoubleTap,
          child: const Text('Home'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: Text(
                '$_emoji $_temperature',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
        backgroundColor: const Color.fromARGB(209, 115, 255, 69),
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade100,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                enabledDayPredicate: (day) {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final d = DateTime(day.year, day.month, day.day);
                  return !d.isAfter(today);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  final now = DateTime.now();
                  final today =
                      DateTime(now.year, now.month, now.day);
                  final d = DateTime(
                      selectedDay.year, selectedDay.month, selectedDay.day);

                  if (d.isAfter(today)) return;

                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TextLogScreen(selectedDate: selectedDay),
                    ),
                  );
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.green.shade300,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.green.shade500,
                    shape: BoxShape.circle,
                  ),
                  disabledTextStyle:
                      TextStyle(color: Colors.grey.shade400),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 16),
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TextLogScreen(selectedDate: DateTime.now()),
                  ),
                );
              },
              child: const Text(
                'Log Today...',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
