import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessagesScreen extends StatefulWidget {
  final List messages;
  final ScrollController scrollController;
  final Function(String)? onSuggestionTap;
  final bool showTypingIndicator;

  const MessagesScreen({
    Key? key,
    required this.messages,
    required this.scrollController,
    this.onSuggestionTap,
    required this.showTypingIndicator,
  }) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _typingAnimation = CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
    super.dispose();
  }

  List<TextSpan> _parseText(String text) {
    final List<TextSpan> spans = [];
    final pattern = RegExp(r'\*\*(.*?)\*\*');
    int currentIndex = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
          ),
        ));
      }

      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ));

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
        ),
      ));
    }

    return spans;
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                Icons.smart_toy,
                color: Colors.lightBlue.shade700,
                size: 24,
              ),
              const SizedBox(height: 4),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAnimatedDot(0),
                      const SizedBox(width: 4),
                      _buildAnimatedDot(0.2),
                      const SizedBox(width: 4),
                      _buildAnimatedDot(0.4),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assistant is typing...',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(double delay) {
    return AnimatedBuilder(
      animation: _typingAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _typingAnimation.value > 0.33 + delay
              ? 1.0
              : _typingAnimation.value > delay
              ? _typingAnimation.value
              : 0.0,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUserMessage = message['isUserMessage'];
    final timestamp = message['timestamp'];
    final formattedTime = DateFormat('hh:mm a').format(timestamp);
    final messageText = message['message']['text']['text'][0];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUserMessage)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.smart_toy,
                    color: Colors.lightBlue.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Assistant',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUserMessage) const SizedBox(width: 32),
              Flexible(
                child: isUserMessage
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(200),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        messageText,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 4),
                      child: Text(
                        formattedTime,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: _parseText(messageText),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        formattedTime,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy,
              size: 60,
              color: Colors.lightBlue.shade700,
            ),
            const SizedBox(height: 20),
            Text(
              "How can I help you today?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildSuggestionCard(
                    icon: "💻",
                    title: "Programming Help",
                    subtitle: "Code examples and explanations",
                    color: Colors.blue.shade50,
                  ),
                  const SizedBox(height: 12),
                  _buildSuggestionCard(
                    icon: "📚",
                    title: "Learning Resources",
                    subtitle: "Best tutorials and courses",
                    color: Colors.green.shade50,
                  ),
                  const SizedBox(height: 12),
                  _buildSuggestionCard(
                    icon: "📝",
                    title: "Document Summaries",
                    subtitle: "Summarize technical docs",
                    color: Colors.purple.shade50,
                  ),
                  const SizedBox(height: 15),
                  _buildSuggestionCard(
                    icon: "🔍",
                    title: "Debugging Assistance",
                    subtitle: "Help fix your code errors",
                    color: Colors.orange.shade50,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard({
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => widget.onSuggestionTap?.call(title),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: EdgeInsets.only(
              top: 12,
              bottom: 12 + (bottomInset > 0 ? 12 : 0),
            ),
            children: [
              if (widget.messages.isEmpty)
                _buildWelcomeMessage(),
              ...widget.messages.map((message) => _buildMessageBubble(message)),
              if (widget.showTypingIndicator) _buildTypingIndicator(),
            ],
          ),
        ),
      ],
    );
  }
}