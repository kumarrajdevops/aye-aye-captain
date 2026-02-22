import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';
import 'services/accessibility_service.dart';
import 'services/llm_service.dart';

// This is the entry point for the overlay process.
void overlayMain() {
  runApp(const OverlayApp());
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const OverlayChatWidget(),
    );
  }
}

class OverlayChatWidget extends StatefulWidget {
  const OverlayChatWidget({super.key});

  @override
  State<OverlayChatWidget> createState() => _OverlayChatWidgetState();
}

class _OverlayChatWidgetState extends State<OverlayChatWidget> {
  bool _isExpanded = false;
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> _messages = []; // "user" or "ai"
  bool _isLoading = false;

  final ScreenAccessService _accessibilityService = ScreenAccessService();
  final LLMService _llmService = LLMService();

  @override
  void initState() {
    super.initState();
    // Initialize LLM with a placeholder key. 
    // In a real app, you'd pass this via arguments or secure storage.
    _llmService.initialize("YOUR_GEMINI_API_KEY"); 
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event == "close") {
        FlutterOverlayWindow.closeOverlay();
      }
    });
  }

  void _sendMessage() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": question});
      _questionController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    // Get context from Accessibility Service
    // Note: Since this is running in a separate isolate/process, 
    // real-time syncing of the exact same singleton instance might require 
    // platform channels or shared preferences. 
    // For simplicity here, we assume the service can access the latest system state 
    // or we pass it via overlay data update sharing.
    // 
    // *Critical Implementation Note*: The accessibility service runs in the main app process.
    // The overlay runs in a separate view. To get data, the main app should stream 
    // data to the overlay using `FlutterOverlayWindow.shareData()`.
    // 
    // For this MVP code structure, we will assume the main app is pushing context 
    // via shareData updates which we listen to here.
    
    // Placeholder context for MVP if not connected via stream
    String context = "Screen context placeholder. (Requires main app stream integration)"; 
    
    // In a full implementation, you would use:
    // context = await FlutterOverlayWindow.shareData.currentValue;

    final answer = await _llmService.askGemini(question, context);

    if (mounted) {
      setState(() {
        _messages.add({"sender": "ai", "text": answer});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return _buildFloatingHead();
    }
    return _buildExpandedChat();
  }

  Widget _buildFloatingHead() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await FlutterOverlayWindow.resizeOverlay(800, 1200); // Expand
          setState(() {
            _isExpanded = true;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                spreadRadius: 2,
              )
            ],
          ),
          child: const Center(
            child: Icon(Icons.chat_bubble, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedChat() {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Screen Chat AI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () async {
                    setState(() {
                      _isExpanded = false;
                    });
                    await FlutterOverlayWindow.resizeOverlay(150, 150); // Shrink back
                  },
                ),
              ],
            ),
          ),
          
          // Chat Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['text'] ?? ""),
                  ),
                );
              },
            ),
          ),

          // Input Area
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: const InputDecoration(
                      hintText: "Ask about this screen...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
