import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../screens/auth_service.dart';
import '../data/intent_engine.dart';
import '../domain/chat_action.dart';
import '../domain/chat_message.dart';
import 'bot82_state.dart';

class ChatbotState {
  final List<ChatMessage> messages;
  final bool isProcessing;
  final bool showConfetti;

  const ChatbotState({
    required this.messages,
    this.isProcessing = false,
    this.showConfetti = false,
  });

  ChatbotState copyWith({
    List<ChatMessage>? messages,
    bool? isProcessing,
    bool? showConfetti,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
      showConfetti: showConfetti ?? this.showConfetti,
    );
  }
}

class ChatbotNotifier extends Notifier<ChatbotState> {
  final IntentEngine _engine = IntentEngine();

  ChatbotState _initialState() {
    return ChatbotState(
      messages: [
        ChatMessage.bot(
          'Merhaba 👋\nBen Gebze Dijital Asistanı Bot82. Size nasıl yardımcı olabilirim?',
          action: const ChatAction(type: ChatActionType.suggest),
          suggestions: const [
            'Su Kesintileri',
            'Nöbetçi Eczaneler',
            'Hava Durumu',
            'Belediyeye Ulaş',
            'Talep Bildir',
          ],
        ),
      ],
    );
  }

  @override
  ChatbotState build() {
    _engine.loadConfig();

    // 1. Çıkışta Temizleme (Logout): Oturum değiştiğinde mesaj geçmişi ve cache anında sıfırlanır
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final prevUid = previous?.value?.uid;
      final nextUid = next.value?.uid;
      if (prevUid != nextUid) {
        reset();
      }
    });

    // 2. Mod Geçişlerinde Reset: Misafir -> Üye veya Üye -> Misafir geçişinde sohbet penceresi sıfırlanır
    ref.listen<bool>(guestModeProvider, (previous, next) {
      if (previous != null && previous != next) {
        reset();
      }
    });

    return _initialState();
  }

  /// Tüm mesaj geçmişini ve durumu sıfırlar
  void reset() {
    _engine.loadConfig();
    state = _initialState();
    ref.read(bot82Provider.notifier).setChatOpen(false);
  }

  /// Üyelik gerektiren istekleri belirler
  bool _isAuthRequired(String intentId, String? route) {
    const authRequiredIntents = {
      'ebelediye',
      'my_requests',
      'soz_sende',
      'profile',
    };
    if (authRequiredIntents.contains(intentId)) return true;

    if (route != null) {
      final r = route.toLowerCase();
      if (r.contains('ebelediye') ||
          r.contains('payment') ||
          r.contains('vergi') ||
          r.contains('my_requests') ||
          r.contains('soz_sende') ||
          r.contains('profile')) {
        return true;
      }
    }
    return false;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage.user(text);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isProcessing: true,
    );

    ref.read(bot82Provider.notifier).beginThinking();

    // Küçük bir bekleme efekti (düşünme animasyonu)
    await Future.delayed(const Duration(milliseconds: 350));

    final cleanText = text.trim().toLowerCase();

    // Kullanıcı üyelik yönlendirmesine doğrudan yanıt veriyorsa
    if (cleanText == 'kayıt ol' ||
        cleanText == 'üye ol' ||
        cleanText == 'evet' ||
        cleanText == 'üye olmak istiyorum' ||
        cleanText == 'kayıt olmak istiyorum') {
      final botMsg = ChatMessage.bot(
        'Sizi kayıt ekranına yönlendiriyorum. Lütfen bilgilerinizi doldurun ✍️',
        action: const ChatAction(
          type: ChatActionType.navigate,
          route: '/register',
        ),
      );
      state = state.copyWith(
        messages: [...state.messages, botMsg],
        isProcessing: false,
      );
      ref.read(bot82Provider.notifier).endThinking();
      return;
    }

    if (cleanText == 'giriş yap' || cleanText == 'oturum aç') {
      final botMsg = ChatMessage.bot(
        'Sizi üye giriş ekranına yönlendiriyorum. Lütfen giriş yapın 🔑',
        action: const ChatAction(
          type: ChatActionType.navigate,
          route: '/auth',
        ),
      );
      state = state.copyWith(
        messages: [...state.messages, botMsg],
        isProcessing: false,
      );
      ref.read(bot82Provider.notifier).endThinking();
      return;
    }

    if (cleanText == 'vazgeç' || cleanText == 'hayır') {
      final botMsg = ChatMessage.bot(
        'İşleminiz iptal edildi. Size başka nasıl yardımcı olabilirim?',
        action: const ChatAction(type: ChatActionType.suggest),
        suggestions: const [
          'Su Kesintileri',
          'Nöbetçi Eczaneler',
          'Hava Durumu',
          'Belediyeye Ulaş',
          'Talep Bildir',
        ],
      );
      state = state.copyWith(
        messages: [...state.messages, botMsg],
        isProcessing: false,
      );
      ref.read(bot82Provider.notifier).endThinking();
      return;
    }

    await _engine.loadConfig();
    final intent = _engine.matchIntent(text);

    final isLoggedIn = ref.read(isLoggedInProvider);
    ChatMessage botMsg;

    // Misafir modunda üyelik isteyen isteklerde:
    // "Üye girişi gerekir, üye olmak ister misiniz?" diyerek Kayıt Ekranına yönlendirir.
    if (!isLoggedIn && _isAuthRequired(intent.intentId, intent.route)) {
      botMsg = ChatMessage.bot(
        'Üye girişi gerekir, üye olmak ister misiniz?',
        action: const ChatAction(
          type: ChatActionType.navigate,
          route: '/register',
        ),
        suggestions: const ['Kayıt Ol', 'Giriş Yap', 'Vazgeç'],
      );
    } else {
      ChatAction action;
      if (intent.action == 'navigate' && intent.route != null) {
        action = ChatAction(type: ChatActionType.navigate, route: intent.route);
      } else if (intent.action == 'suggest') {
        action = ChatAction(type: ChatActionType.suggest, route: intent.route);
      } else if (intent.action == 'ask' || intent.action == 'request') {
        action = const ChatAction(type: ChatActionType.suggest);
      } else {
        action = const ChatAction(type: ChatActionType.answer);
      }

      botMsg = ChatMessage.bot(
        intent.response,
        action: action,
        suggestions: intent.suggestions,
      );
    }

    state = state.copyWith(
      messages: [...state.messages, botMsg],
      isProcessing: false,
      showConfetti: intent.intentId == 'easter_egg_82',
    );

    ref.read(bot82Provider.notifier).endThinking();
  }
}

final chatbotProvider = NotifierProvider<ChatbotNotifier, ChatbotState>(() {
  return ChatbotNotifier();
});
