import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme.dart';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // Sample responses for demo (replace with actual Dialogflow later)
  final Map<String, String> _responses = {
    'hello': 'Hello! How can I help you with your bus booking today?',
    'hi': 'Hi there! What would you like to know?',
    'book bus': 'To book a bus, go to the Home screen and tap "Buy Ticket".',
    'how to book': 'Tap the "Buy Ticket" button on the home screen, select your route, date, and time.',
    'cancel booking': 'To cancel a booking, go to My Bookings, select the booking, and tap Cancel.',
    'payment': 'We accept Benefit Pay and Apple Pay. All payments are secure.',
    'routes': 'We have routes from Isa Town, Riffa, Hamad Town, City Centre, and UTB Campus.',
    'schedule': 'Buses run at 7:00 AM, 11:00 AM, and 3:00 PM on weekdays.',
    'price': 'Tickets start from 25 BHD. Monthly subscriptions available!',
    'subscription': 'Monthly subscriptions give you unlimited rides for 30 days.',
    'contact': 'You can reach support at 1777-2024 or email support@utb.edu.bh',
    'help': 'I can help with: bookings, payments, schedules, routes, subscriptions, and more!',
    'thanks': 'You\'re welcome! Is there anything else I can help with?',
    'thank you': 'Happy to help! Have a great day!',
  };

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: _messageController.text,
        isUser: true,
      ));
      _isTyping = true;
    });

    String userMessage = _messageController.text.toLowerCase();
    _messageController.clear();

    // Scroll to bottom
    _scrollToBottom();

    // Simulate typing delay
    await Future.delayed(Duration(seconds: 1));

    // Generate response
    String response = _generateResponse(userMessage);

    // Add bot response
    setState(() {
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
      ));
      _isTyping = false;
    });

    _scrollToBottom();
  }

  String _generateResponse(String message) {
    // Simple keyword matching (replace with Dialogflow later)
    if (message.contains('hello') || message.contains('hi')) {
      return _responses['hello']!;
    } else if (message.contains('book') || message.contains('ticket')) {
      return _responses['book bus']!;
    } else if (message.contains('how to')) {
      return _responses['how to book']!;
    } else if (message.contains('cancel')) {
      return _responses['cancel booking']!;
    } else if (message.contains('pay') || message.contains('payment')) {
      return _responses['payment']!;
    } else if (message.contains('route')) {
      return _responses['routes']!;
    } else if (message.contains('schedule') || message.contains('time')) {
      return _responses['schedule']!;
    } else if (message.contains('price') || message.contains('cost')) {
      return _responses['price']!;
    } else if (message.contains('subscription') || message.contains('membership')) {
      return _responses['subscription']!;
    } else if (message.contains('contact') || message.contains('support')) {
      return _responses['contact']!;
    } else if (message.contains('help')) {
      return _responses['help']!;
    } else if (message.contains('thanks') || message.contains('thank you')) {
      return _responses['thanks']!;
    } else {
      return "I'm not sure about that. You can ask me about bookings, payments, schedules, routes, or contact support at 1777-2024.";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UTB Assistant',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage(
                  text: 'Hello! How can I help you with your bus booking today?',
                  isUser: false,
                ));
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index];
              },
            ),
          ),

          // Typing indicator
          if (_isTyping)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Assistant is typing...',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.isUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.grey[200],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser ? Radius.circular(20) : Radius.circular(4),
                  bottomRight: isUser ? Radius.circular(4) : Radius.circular(20),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'You',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}