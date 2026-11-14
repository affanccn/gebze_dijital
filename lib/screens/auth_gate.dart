import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessibility/font_scale_provider.dart';
import '../core/localization/app_strings.dart';
import '../core/theme/theme_provider.dart';
import '../features/profile/models/user_profile.dart';
import '../features/profile/services/profile_service.dart';
import '../core/services/push_service.dart';
import 'auth_screen.dart';
import 'auth_service.dart';
import 'guest_home_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  String? _syncedUid;
  ProviderSubscription<AsyncValue<UserProfile>>? _sub;

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  void _syncPreferences(String uid) {
    _sub?.close();
    var applied = false;
    _sub = ref.listenManual<AsyncValue<UserProfile>>(profileProvider, (
      prev,
      next,
    ) {
      final p = next.value;
      if (applied || p == null || p.id != uid) return;
      applied = true;

      ref.read(appLanguageProvider.notifier).setLanguage(p.language);
      ref.read(appLargeFontProvider.notifier).setLargeFont(p.isLargeFont);
      ref.read(appThemeModeProvider.notifier).setThemeMode(p.themeMode);
      PushService.syncAllPreferences(p.notificationPreferences);

      Future.microtask(() {
        _sub?.close();
        _sub = null;
      });
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final guest = ref.watch(guestModeProvider);
    final isHome = (auth.value != null || guest);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authScreenVisibleProvider.notifier).state = !isHome;
    });

    final uid = auth.value?.uid;
    if (uid != _syncedUid) {
      _syncedUid = uid;
      if (uid == null) {
        _sub?.close();
        _sub = null;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _syncedUid == uid) _syncPreferences(uid);
        });
      }
    }

    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => const AuthScreen(),
      data: (user) => isHome ? const GuestHomeScreen() : const AuthScreen(),
    );
  }
}
