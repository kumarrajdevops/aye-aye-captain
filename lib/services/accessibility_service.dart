import 'dart:async';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';

class ScreenAccessService {
  static final ScreenAccessService _instance = ScreenAccessService._internal();
  factory ScreenAccessService() => _instance;
  ScreenAccessService._internal();

  String _lastCapturedText = "";
  DateTime _lastCaptureTime = DateTime.now();

  // Stream controller to broadcast updates if needed in the main app
  final _textController = StreamController<String>.broadcast();
  Stream<String> get textStream => _textController.stream;

  /// Starts listening to accessibility events.
  void startListening() {
    FlutterAccessibilityService.accessStream.listen((event) {
      // Filter events to avoid too much noise. 
      // We are interested in text content changes or window state changes.
      if (event.text != null && event.text!.isNotEmpty) {
        _processEventText(event.text!, event.packageName);
      }
      
      // Also check nodes if available (depending on plugin version/capabilities)
      if (event.nodes != null) {
        for (var node in event.nodes!) {
          if (node.text != null && node.text!.isNotEmpty) {
             _processEventText(node.text!, event.packageName);
          }
        }
      }
    });
  }

  void _processEventText(String text, String? packageName) {
    // Simple debouncing/deduplication logic could go here.
    // For now, we just update the last captured text.
    // In a real app, you might want to accumulate text from the whole screen.
    
    // Check if it's a new meaningful text
    if (text != _lastCapturedText) {
      _lastCapturedText = text;
      _lastCaptureTime = DateTime.now();
      print("Captured text from $packageName: $text");
      _textController.add(text);
    }
  }

  Future<bool> requestPermission() async {
    return await FlutterAccessibilityService.requestAccessibilityPermission();
  }

  Future<bool> isAccessibilityPermissionEnabled() async {
    return await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
  }

  /// Returns the most recent relevant text captured from the screen.
  String getCurrentScreenContext() {
    // Logic to clear old context if it's too stale
    if (DateTime.now().difference(_lastCaptureTime).inSeconds > 30) {
      return "No recent screen content captured.";
    }
    return _lastCapturedText;
  }
}
