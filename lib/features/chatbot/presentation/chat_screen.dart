import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/bot82_state.dart';
import '../application/chatbot_provider.dart';
import '../domain/chat_message.dart';
import 'chatbot_navigator.dart';
import 'widgets/bot82_chat_avatar.dart';
import 'widgets/bot_message.dart';
import 'widgets/chat_input.dart';
import 'widgets/user_message.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  final bool isMini;
  const ChatbotScreen({super.key, this.isMini = false});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final ScrollController _scrollController = ScrollController();
  late ConfettiController _confettiController;
  Bot82Notifier? _bot82Notifier;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _bot82Notifier = ref.read(bot82Provider.notifier);
        _bot82Notifier?.openChat();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _confettiController.dispose();
    _bot82Notifier?.closeChat();
    super.dispose();
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
    final chatState = ref.watch(chatbotProvider);
    final bot82State = ref.watch(bot82Provider);

    ref.listen(chatbotProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
      if (next.showConfetti && (previous == null || !previous.showConfetti)) {
        _confettiController.play();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF7F9FE),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A2A66), Color(0xFF061B45)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x330A2A66),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF22D3EE).withAlpha(160),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/images/bot82_full.png',
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.smart_toy,
                        color: Color(0xFF22D3EE),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Bot82 Asistan',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF22D3EE),
                              size: 16,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4ADE80),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Gebze Belediyesi Akıllı Çözüm',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.isMini)
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.open_in_full,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      tooltip: 'Tam Ekran',
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChatbotScreen(isMini: false),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 8.0,
                  ),
                  itemCount:
                      chatState.messages.length +
                      (chatState.isProcessing ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == chatState.messages.length) {
                      return Bot82MessageRow(
                        isLatest: true,
                        thinking: true,
                        bubble: Padding(
                          padding: const EdgeInsets.only(right: 40.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Text('...'),
                          ),
                        ),
                      );
                    }

                    final message = chatState.messages[index];
                    if (message.role == MessageRole.user) {
                      return UserMessageWidget(message: message);
                    } else {
                      final isLastBot =
                          index ==
                          chatState.messages.lastIndexWhere(
                            (m) => m.role == MessageRole.bot,
                          );
                      return Bot82MessageRow(
                        isLatest: isLastBot,
                        thinking:
                            isLastBot && bot82State.mode == Bot82Mode.thinking,
                        bubble: BotMessageWidget(
                          message: message,
                          onSuggestionTap: (text) {
                            ref
                                .read(chatbotProvider.notifier)
                                .sendMessage(text);
                          },
                          onNavigate: (route) {
                            if (widget.isMini) {
                              Navigator.of(context).pop();
                            }
                            ChatbotNavigator.navigate(context, route);
                          },
                        ),
                      );
                    }
                  },
                ),
              ),
              // Sıkça Sorulan Sorular / Hızlı Soru-Cevap Çipleri
              Container(
                height: 44,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _QuickFaqChip(
                      label: '💧 Su Kesintisi',
                      onTap: () => ref
                          .read(chatbotProvider.notifier)
                          .sendMessage('Su kesintisi var mı?'),
                    ),
                    const SizedBox(width: 6),
                    _QuickFaqChip(
                      label: '🏥 Nöbetçi Eczaneler',
                      onTap: () => ref
                          .read(chatbotProvider.notifier)
                          .sendMessage('Nöbetçi eczaneler hangileri?'),
                    ),
                    const SizedBox(width: 6),
                    _QuickFaqChip(
                      label: '📅 Etkinlikler',
                      onTap: () => ref
                          .read(chatbotProvider.notifier)
                          .sendMessage('Yaklaşan etkinlikler neler?'),
                    ),
                    const SizedBox(width: 6),
                    _QuickFaqChip(
                      label: '🍲 Kent Lokantası',
                      onTap: () => ref
                          .read(chatbotProvider.notifier)
                          .sendMessage('Kent lokantası menüsü'),
                    ),
                    const SizedBox(width: 6),
                    _QuickFaqChip(
                      label: '⚡ Elektrik Kesintisi',
                      onTap: () => ref
                          .read(chatbotProvider.notifier)
                          .sendMessage('Elektrikler ne zaman gelecek?'),
                    ),
                    const SizedBox(width: 6),
                    _QuickFaqChip(
                      label: '📝 Şikayet Bildir',
                      onTap: () => ref
                          .read(chatbotProvider.notifier)
                          .sendMessage('Şikayet oluşturmak istiyorum'),
                    ),
                    const SizedBox(width: 6),
                    _QuickFaqChip(
                      label: '🐾 Gebze Pati',
                      onTap: () => ref
                          .read(chatbotProvider.notifier)
                          .sendMessage('Gebze pati hayvan sahiplendirme'),
                    ),
                    const SizedBox(width: 6),
                    _QuickFaqChip(
                      label: '🅿️ Otoparklar',
                      onTap: () => ref
                          .read(chatbotProvider.notifier)
                          .sendMessage('Otopark ücretleri ve boş yerler'),
                    ),
                  ],
                ),
              ),
              ChatInput(
                onSend: (text) {
                  ref.read(chatbotProvider.notifier).sendMessage(text);
                },
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickFaqChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickFaqChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0A2A66),
        ),
      ),
      backgroundColor: const Color(0xFFF1F5FD),
      side: const BorderSide(color: Color(0xFFD6E4FF)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onPressed: onTap,
    );
  }
}
