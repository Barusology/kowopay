import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:kowopay/services/ai_service.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/utils/rate_limiter.dart';
import 'package:kowopay/utils/secure_logger.dart';
import 'package:kowopay/widgets/app_surfaces.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = <_ChatMessage>[];

  bool _isLoading = false;
  String? _error;

  static const List<String> _suggestions = <String>[
    'How do I build an emergency fund?',
    'Explain how my spending looks',
    'Tips to reduce monthly bills',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final String text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;
    if (!RateLimiter.allow('ai-send', const Duration(seconds: 2))) return;

    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: text));
      _isLoading = true;
      _error = null;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final String response =
          await ref.read(aiServiceProvider).getFinancialAdvice(text);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: 'ai', text: response));
      });
    } on AiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      SecureLog.error('AI chat', e);
      if (mounted) {
        setState(() =>
            _error = 'The assistant is unavailable. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CinematicScaffold(
      title: 'Money assistant',
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? _emptyState() : _messageList(),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: LinearProgressIndicator(
                color: AppColors.purple,
                backgroundColor: AppColors.lilac,
              ),
            ),
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                    color: AppColors.danger, fontSize: 12),
              ),
            ),
          _inputRow(),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 30),
      children: [
        Center(
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.buttonGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.28),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.white, size: 38),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Ask anything about your money',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Private by design: your question goes through our server, where the '
          'AI key is kept — never in the app.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.inkMuted,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 26),
        for (final String suggestion in _suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              radius: 16,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              onTap: () => _send(suggestion),
              child: Row(
                children: [
                  const Icon(Icons.arrow_outward_rounded,
                      size: 16, color: AppColors.purple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _messageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final _ChatMessage message = _messages[index];
        final bool isUser = message.role == 'user';
        return Align(
          alignment:
              isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            decoration: BoxDecoration(
              gradient: isUser ? AppColors.buttonGradient : null,
              color: isUser ? null : AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: isUser ? null : Border.all(color: AppColors.outline),
              boxShadow: isUser
                  ? [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isUser ? AppColors.white : AppColors.ink,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _inputRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            maxLength: AIService.maxInputLength,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            buildCounter: (_, {required int currentLength,
                    required bool isFocused, int? maxLength}) =>
                null,
            decoration: InputDecoration(
              hintText: 'Ask about saving, bills, budgeting…',
              filled: true,
              fillColor: AppColors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _isLoading ? null : () => _send(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _isLoading ? null : AppColors.buttonGradient,
              color: _isLoading ? AppColors.lilac : null,
            ),
            child: Icon(
              Icons.arrow_upward_rounded,
              color: _isLoading ? AppColors.inkMuted : AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.role, required this.text});
  final String role;
  final String text;
}
