import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../screens/auth_service.dart';
import '../../application/bot82_state.dart';
import '../chat_screen.dart';
import '../chatbot_navigator.dart';
import 'bot82_fab.dart';

class Bot82Overlay extends ConsumerStatefulWidget {
  const Bot82Overlay({
    super.key,
    required this.child,
    this.navigatorKey,
    this.defaultBottomOffset = 76,
    this.defaultRightOffset = 14,
  });

  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;
  final double defaultBottomOffset;
  final double defaultRightOffset;

  @override
  ConsumerState<Bot82Overlay> createState() => _Bot82OverlayState();
}

class _Bot82OverlayState extends ConsumerState<Bot82Overlay> {
  bool _bubble = false;
  Timer? _showT, _hideT;
  Offset? _position;

  @override
  void initState() {
    super.initState();
    _showT = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _bubble = true);
      _hideT = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _bubble = false);
      });
    });
  }

  @override
  void dispose() {
    _showT?.cancel();
    _hideT?.cancel();
    super.dispose();
  }

  Future<void> _openChat() async {
    final navKey = widget.navigatorKey ?? ChatbotNavigator.navigatorKey;
    final navContext =
        navKey?.currentState?.overlay?.context ??
        navKey?.currentContext ??
        (Navigator.maybeOf(context) != null ? context : null);

    if (navContext == null) return;

    final notifier = ref.read(bot82Provider.notifier);

    setState(() => _bubble = false);
    notifier.setChatOpen(true);

    await showModalBottomSheet<void>(
      context: navContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 480),
        reverseDuration: Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom,
        ),
        child: Container(
          height: MediaQuery.sizeOf(sheetCtx).height * 0.72,
          decoration: BoxDecoration(
            color: Theme.of(sheetCtx).brightness == Brightness.dark
                ? const Color(0xFF0F172A)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            child: ChatbotScreen(isMini: true),
          ),
        ),
      ),
    );

    notifier.setChatOpen(false);
  }

  @override
  Widget build(BuildContext context) {
    // Giriş/Kayıt ekranında Chatbot kesinlikle render edilmemelidir.
    final isAuthVisible = ref.watch(authScreenVisibleProvider);
    if (isAuthVisible) {
      return widget.child;
    }

    final chatOpen = ref.watch(bot82Provider.select((s) => s.chatOpen));
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final hidden = chatOpen || keyboard;
    final screenSize = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);

    const botW = 72.0;
    const clusterW = botW;
    final clusterH = botW / kBot82Aspect;

    final defaultPos = Offset(
      screenSize.width - widget.defaultRightOffset - clusterW,
      screenSize.height -
          safePadding.bottom -
          widget.defaultBottomOffset -
          clusterH,
    );

    final currentPos = _position ?? defaultPos;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            left: currentPos.dx,
            top: currentPos.dy,
            child: IgnorePointer(
              ignoring: hidden,
              child: AnimatedScale(
                scale: hidden ? 0.0 : 1.0,
                duration: Duration(milliseconds: hidden ? 180 : 420),
                curve: hidden ? Curves.easeIn : Curves.easeOutBack,
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final newX = (currentPos.dx + details.delta.dx).clamp(
                        10.0,
                        screenSize.width - clusterW - 10.0,
                      );
                      final newY = (currentPos.dy + details.delta.dy).clamp(
                        safePadding.top + 10.0,
                        screenSize.height -
                            safePadding.bottom -
                            clusterH -
                            10.0,
                      );
                      _position = Offset(newX, newY);
                      _bubble = false;
                    });
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomRight,
                    children: [
                      if (_bubble)
                        Positioned(
                          right: 76,
                          bottom: 18,
                          child: GestureDetector(
                            onTap: _openChat,
                            child: const _GreetingBubble(),
                          ),
                        ),
                      Bot82Fab(width: botW, onTap: _openChat),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingBubble extends StatelessWidget {
  const _GreetingBubble();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(4),
        ),
        border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        'Nasıl yardımcı\nolabilirim?',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: isDark ? Colors.white : const Color(0xFF0A2A66),
        ),
      ),
    );
  }
}
