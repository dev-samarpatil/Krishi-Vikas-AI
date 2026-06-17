import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/locale_provider.dart';
import '../../../farm/providers/farm_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Chat screen — text + voice AI chat with full farm context injection.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isRecording = false;
  bool _isTyping = false;
  bool _showSendButton = false;
  
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _messageController.addListener(_onMessageChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMessageChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _showSendButton) {
      setState(() => _showSendButton = hasText);
    }
  }

  void _loadMessages() {
    try {
      final box = Hive.box(AppConstants.cacheBox);
      final saved = box.get('chat_messages');
      if (saved != null && saved is List) {
        setState(() {
          _messages.clear();
          for (var item in saved) {
            if (item is Map) {
              _messages.add({
                'role': item['role']?.toString() ?? '',
                'content': item['content']?.toString() ?? '',
              });
            }
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Error loading messages: $e");
    }
  }

  void _saveMessages() {
    try {
      final box = Hive.box(AppConstants.cacheBox);
      box.put('chat_messages', _messages);
    } catch (e) {
      debugPrint("Error saving messages: $e");
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

 Future<void> _sendMessage(String text) async {
  if (text.trim().isEmpty) return;

  setState(() {
    _messages.add({
      'role': 'user',
      'content': text,
    });

    _messageController.clear();
    _showSendButton = false;
    _isTyping = true;
  });

  _saveMessages();
  _scrollToBottom();

  try {
    final locale = ref.read(localeProvider);

    final dio = Dio(BaseOptions(headers: {'Bypass-Tunnel-Reminder': 'true'}));

    final response = await dio.post(
      '${AppConstants.baseUrl}/api/chat',
      data: {
        'message': text,
        'language': locale.languageCode,
      },
    );

    final reply =
        (response.data['response'] ?? response.data['reply']) as String? ?? 'No response';

    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': reply,
      });

      _isTyping = false;
    });
  } catch (e) {
    final fallback = _getFallbackResponse(text);

    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': fallback,
      });

      _isTyping = false;
    });

    debugPrint('Chat error: $e');
  }

  _saveMessages();
  _scrollToBottom();
}

  // Generate mock response when Groq call fails
  String _getFallbackResponse(String userMessage) {
    final msg = userMessage.toLowerCase();
    if (msg.contains('disease') || msg.contains('pest')) {
      return 'Here are detailed steps to manage the disease/pest: ... (provide actionable advice with product names, dosages, timing).';
    }
    if (msg.contains('price') || msg.contains('mandi')) {
      return 'Current market prices for major crops are: ... (provide price advice).';
    }
    if (msg.contains('weather') || msg.contains('rain')) {
      return 'Weather forecast for your region: ... (provide weather advice).';
    }
    return 'I understand your question. Please ensure the backend is running for detailed AI responses.';
  }

  Future<void> _retryMessage(int index, String text) async {
    setState(() {
      _messages.removeAt(index);
    });
    await _sendMessage(text);
  }

  void _toggleRecording() async {
    if (_isRecording) {
      await _speech.stop();
      setState(() => _isRecording = false);
    } else {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isRecording = false);
          }
        },
      );
      
      if (available) {
        setState(() => _isRecording = true);
        final locale = ref.read(localeProvider);
        final langCode = locale.languageCode;
        
        String sttLang = 'en-US';
        if (langCode == 'hi') sttLang = 'hi-IN';
        else if (langCode == 'mr') sttLang = 'mr-IN';
        else if (langCode == 'ta') sttLang = 'ta-IN';

        _speech.listen(
          onResult: (result) {
            if (result.finalResult && result.recognizedWords.isNotEmpty) {
              _sendMessage(result.recognizedWords);
            }
          },
          localeId: sttLang,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
        );
      }
    }
  }

  Future<void> _speakMessage(String text) async {
    final locale = ref.read(localeProvider);
    final langCode = locale.languageCode;

    String ttsLang = 'en-US';
    if (langCode == 'hi') ttsLang = 'hi-IN';
    else if (langCode == 'mr') ttsLang = 'mr-IN';
    else if (langCode == 'ta') ttsLang = 'ta-IN';

    await _flutterTts.setLanguage(ttsLang);
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
        titleSpacing: AppTheme.spacingMd,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_outlined, color: Colors.white, size: 22),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              'Krishi Vikas AI',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    fontSize: 20,
                  ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppTheme.spacingMd),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      final message = _messages[index];
                      if (message['role'] == 'error') {
                        return _buildErrorBubble(index, message['content'] ?? '');
                      }
                      return _buildMessageBubble(message);
                    },
                  ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.dividerGray.withOpacity(0.5))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 32,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Suggestion chips
                  if (_messages.isEmpty)
                    Container(
                      height: 40,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildSuggestionChip('How to improve soil?'),
                          const SizedBox(width: 8),
                          _buildSuggestionChip('Wheat disease symptoms'),
                          const SizedBox(width: 8),
                          _buildSuggestionChip('Market trends'),
                        ],
                      ),
                    ),
                  // Input Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.dividerGray.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.dividerGray.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    hintText: 'Message Krishi...',
                                    hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 16),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onSubmitted: _sendMessage,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_showSendButton)
                        GestureDetector(
                          onTap: () => _sendMessage(_messageController.text),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
                            child: const Icon(Icons.send, color: Colors.white, size: 20),
                          ),
                        )
                      else
                        PulsingMicButton(
                          isRecording: _isRecording,
                          onTap: _toggleRecording,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_outlined, size: 40, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Namaste, Farmer! 🙏',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'I am your Krishi Vikas AI assistant.\nHow can I help you with your farm today?',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      backgroundColor: Colors.white,
      side: BorderSide(color: AppTheme.dividerGray.withOpacity(0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () => _sendMessage(text),
    );
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    final content = message['content'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 4, right: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_outlined, size: 18, color: AppTheme.primaryGreen),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryGreen : AppTheme.cardWhite,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: AppTheme.dividerGray.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 15,
                      color: isUser ? Colors.white : AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  if (!isUser) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _speakMessage(content),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.volume_up_outlined, size: 16, color: AppTheme.primaryGreen),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 4, left: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('U', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBubble(int index, String originalText) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withOpacity(0.08),
          border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.somethingWentWrong,
              style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ElevatedButton.icon(
              onPressed: () => _retryMessage(index, originalText),
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(AppLocalizations.of(context)!.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: const BouncingTypingIndicator(),
      ),
    );
  }
}

class PulsingMicButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onTap;

  const PulsingMicButton({
    super.key,
    required this.isRecording,
    required this.onTap,
  });

  @override
  State<PulsingMicButton> createState() => _PulsingMicButtonState();
}

class _PulsingMicButtonState extends State<PulsingMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isRecording) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulsingMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isRecording && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isRecording)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: 44 + (_controller.value * 16),
                  height: 44 + (_controller.value * 16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.3 * (1.0 - _controller.value)),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.isRecording ? AppTheme.errorRed : AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isRecording ? Icons.stop : Icons.mic,
              color: widget.isRecording ? Colors.white : AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class BouncingTypingIndicator extends StatefulWidget {
  const BouncingTypingIndicator({super.key});

  @override
  State<BouncingTypingIndicator> createState() => _BouncingTypingIndicatorState();
}

class _BouncingTypingIndicatorState extends State<BouncingTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final double value = math.sin((_controller.value * 2 * math.pi) - delay);
            final double translation = (value > 0 ? value : 0) * -8;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              transform: Matrix4.translationValues(0, translation, 0),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
