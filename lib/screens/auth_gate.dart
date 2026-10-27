import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessibility/font_scale_provider.dart';
import '../core/localization/app_strings.dart';
import '../core/theme/theme_provider.dart';
import '../features/profile/models/user_profile.dart';
import '../features/profile/services/profile_service.dart';
import 'auth_screen.dart';
import 'auth_service.dart';
import 'guest_home_screen.dart';

/// Dosya yolu: lib/screens/auth_gate.dart
///
/// Uygulamanın kök ekranı (main.dart > home).
/// - Oturum açık                       → ana sayfa
/// - "Üye olmadan devam et" seçilmiş   → ana sayfa (kısıtlı)
/// - Aksi halde                        → giriş ekranı
///
/// Ayrıca kullanıcı giriş yapınca Firestore'daki profilinden dil, yazı tipi
/// ve tema tercihini bir kez okuyup uygulamaya yükler; böylece aynı hesapla
/// başka cihazdan girildiğinde de ayarlar aynı gelir.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  /// Tercihleri en son hangi kullanıcı için senkronladık.
  String? _syncedUid;
  ProviderSubscription<AsyncValue<UserProfile>>? _sub;

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  /// Profil gelince (yalnızca bir kez) tercihleri uygular.
  void _syncPreferences(String uid) {
    _sub?.close();
    var applied = false;
    _sub = ref.listenManual<AsyncValue<UserProfile>>(profileProvider, (
      prev,
      next,
    ) {
      final p = next.value;
      // Döküman henüz yokken üretilen varsayılan profili (id: default_citizen)
      // atla; gerçek kullanıcı dökümanını bekle.
      if (applied || p == null || p.id != uid) return;
      applied = true;

      ref.read(appLanguageProvider.notifier).setLanguage(p.language);
      ref.read(appLargeFontProvider.notifier).setLargeFont(p.isLargeFont);
      ref.read(appThemeModeProvider.notifier).setThemeMode(p.themeMode);

      // Bir kez uygulayınca dinlemeyi bırak.
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

    // Kullanıcı değişti (giriş / çıkış): giriş yaptıysa tercihlerini yükle.
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