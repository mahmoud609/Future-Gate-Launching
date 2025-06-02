import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat.dart';
import 'exit_confirmation_dialog.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({Key? key}) : super(key: key);

  @override
  ChatBotState createState() => ChatBotState();
}

class ChatBotState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final String apiKey = 'AIzaSyCjvC-6HvVw7gUJEDdAD6HvUo8LaSYlD24';
  final String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  List<Map<String, dynamic>> messages = [];
  bool _isWaitingForResponse = false;
  bool _isComposing = false;
  bool _showTypingIndicator = false;
  bool _firstLoad = true; // New flag to track first load

  // Reduced typing indicator duration
  static const int typingIndicatorDurationMs = 50; // Reduced from 1500ms
  static const int minResponseTimeMs = 50; // Minimum time to show typing indicator

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return await showExitDialog(context);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        try {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (e) {
          debugPrint('Scroll error: ${e.toString()}');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'ChatBot',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.black),
          centerTitle: true,
        ),
        body: GestureDetector(
          onTap: () {
            // Only request focus when user taps on the screen (not on first load)
            if (!_firstLoad) {
              _focusNode.requestFocus();
            }
            _firstLoad = false;
          },
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: MessagesScreen(
                    messages: messages,
                    scrollController: _scrollController,
                    onSuggestionTap: _handleSuggestionTap,
                    showTypingIndicator: _showTypingIndicator,
                  ),
                ),
                _buildInputArea(),
              ],
            ),
          ),
        ),
      ),
    );

  }

  void _handleSuggestionTap(String suggestion) {
    setState(() {
      _controller.text = suggestion;
      _isComposing = true;
    });
    _focusNode.requestFocus();
    _firstLoad = false; // User has interacted, no longer first load

  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (text) {
                  setState(() {
                    _isComposing = text.isNotEmpty;
                  });
                },
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                onSubmitted: (text) => _sendMessageIfValid(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isComposing ? Colors.blueAccent : Colors.grey.shade400,
            ),
            child: IconButton(
              onPressed: _sendMessageIfValid,
              icon: const Icon(Icons.send, color: Colors.white),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessageIfValid() {
    if (_controller.text.isNotEmpty && !_isWaitingForResponse) {
      final message = _controller.text.trim();
      sendMessage(message);
      _controller.clear();
      setState(() {
        _isComposing = false;
      });
      _focusNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  Future<void> sendMessage(String text) async {
    final tempId = DateTime.now().millisecondsSinceEpoch;

    setState(() {
      messages.add({
        'message': {'text': {'text': [text]}},
        'isUserMessage': true,
        'timestamp': DateTime.now(),
        'id': tempId,
      });
      _isWaitingForResponse = true;
      _showTypingIndicator = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [{"text": text}]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final aiResponse = responseData['candidates'][0]['content']['parts'][0]['text'];

        // Simulate typing delay
        await Future.delayed(const Duration(milliseconds: 1500));

        setState(() {
          _showTypingIndicator = false;
          messages.add({
            'message': {'text': {'text': [aiResponse]}},
            'isUserMessage': false,
            'timestamp': DateTime.now(),
            'id': tempId + 1,
          });
          _isWaitingForResponse = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        throw Exception('Failed to load response: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _showTypingIndicator = false;
        messages.add({
          'message': {'text': {'text': ['Sorry, I encountered an error. Please try again.']}},
          'isUserMessage': false,
          'timestamp': DateTime.now(),
          'id': tempId + 1,
        });
        _isWaitingForResponse = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }
}