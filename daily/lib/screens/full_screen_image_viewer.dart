import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_log.dart';

class FullScreenImageViewer extends StatefulWidget {
  final String imagePath;
  final DailyLog? log; 

  const FullScreenImageViewer({Key? key, required this.imagePath, this.log}) : super(key: key);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> with SingleTickerProviderStateMixin {
  double _verticalDrag = 0.0;

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _verticalDrag += details.delta.dy;
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_verticalDrag > 100) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _verticalDrag = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final captionText = widget.log != null
        ? "Added on ${DateFormat('MMM d, yyyy').format(DateTime.parse(widget.log!.date))}"
          "${widget.log!.city != null && widget.log!.city!.isNotEmpty ? " · 📍 ${widget.log!.city!}" : ""}"
        : "";

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: _handleVerticalDragUpdate,
        onVerticalDragEnd: _handleVerticalDragEnd,
        child: Stack(
          children: [
            // Blurred background layer
            Positioned.fill(
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
            // Centered image with shadow
            Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Image info caption
            if (captionText.isNotEmpty)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    captionText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
