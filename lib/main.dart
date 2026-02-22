import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'overlay_entry_point.dart'; // Import the overlay entry point
import 'services/accessibility_service.dart';

// Define the global entry point for the overlay
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const OverlayApp());
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screen Chat Overlay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _overlayPermission = false;
  bool _accessibilityPermission = false;
  
  // Instance of our service
  final ScreenAccessService _screenService = ScreenAccessService();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _screenService.startListening();
    
    // Listen to screen text updates and send them to the overlay
    _screenService.textStream.listen((text) {
      // Send the text to the overlay window
      FlutterOverlayWindow.shareData(text);
      print("Shared text with overlay: ${text.substring(0, text.length > 50 ? 50 : text.length)}...");
    });
  }

  Future<void> _checkPermissions() async {
    final overlay = await FlutterOverlayWindow.isPermissionGranted();
    final accessibility = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
    setState(() {
      _overlayPermission = overlay;
      _accessibilityPermission = accessibility;
    });
  }

  Future<void> _requestOverlayPermission() async {
    final status = await FlutterOverlayWindow.requestPermission();
    setState(() {
      _overlayPermission = status ?? false;
    });
  }

  Future<void> _requestAccessibilityPermission() async {
    await FlutterAccessibilityService.requestAccessibilityPermission();
    // User needs to go to settings. We can't know immediately if they granted it.
    // In a real app, use `didChangeAppLifecycleState` to re-check when app resumes.
  }

  Future<void> _startOverlay() async {
    if (_overlayPermission && _accessibilityPermission) {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "Screen Chat",
        overlayContent: "Chat Head",
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.centerRight,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: 150, // Initial small size
        width: 150,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please grant all permissions first.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Screen Chat Setup"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Required Permissions:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Overlay Permission Tile
            ListTile(
              leading: Icon(
                _overlayPermission ? Icons.check_circle : Icons.error,
                color: _overlayPermission ? Colors.green : Colors.red,
              ),
              title: const Text("Overlay Window Permission"),
              subtitle: const Text("Required to show the chat head."),
              trailing: ElevatedButton(
                onPressed: _requestOverlayPermission,
                child: const Text("Grant"),
              ),
            ),

            // Accessibility Permission Tile
            ListTile(
              leading: Icon(
                _accessibilityPermission ? Icons.check_circle : Icons.error,
                color: _accessibilityPermission ? Colors.green : Colors.red,
              ),
              title: const Text("Accessibility Service"),
              subtitle: const Text("Required to read screen content."),
              trailing: ElevatedButton(
                onPressed: _requestAccessibilityPermission,
                child: const Text("Grant"),
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: _startOverlay,
              icon: const Icon(Icons.play_arrow),
              label: const Text("Start Chat Overlay"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
