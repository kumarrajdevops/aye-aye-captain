import 'package:google_generative_ai/google_generative_ai.dart';

class LLMService {
  static final LLMService _instance = LLMService._internal();
  factory LLMService() => _instance;
  LLMService._internal();

  late GenerativeModel _model;
  bool _isInitialized = false;

  void initialize(String apiKey) {
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    _isInitialized = true;
  }

  Future<String> askGemini(String question, String screenContext) async {
    if (!_isInitialized) {
      return "Error: Gemini API key not initialized.";
    }

    final prompt = '''
You are an AI assistant that can read the user's screen.
Here is the text content currently on the screen:
"""
$screenContext
"""

User Question: $question

Answer the user's question based on the screen context provided above. If the context is empty or irrelevant, answer to the best of your general knowledge but mention that you couldn't see the screen content.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "I couldn't generate a response.";
    } catch (e) {
      return "Error communicating with Gemini: $e";
    }
  }
}
