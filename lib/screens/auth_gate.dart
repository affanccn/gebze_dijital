import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_screen.dart';
import 'auth_service.dart';
import 'guest_home_screen.dart';

/// Dosya yolu: lib/screens/auth_gate.dart
///
/// Uygulamanın kök ekranı (main.dart > home).
/// - Oturum açık                       → ana sayfa
/// - "Üye olmadan devam et" seçilmiş   → ana sayfa (kısıtlı)
/// - Aksi halde                        → giriş ekranı
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final guest = ref.watch(guestModeProvider);

    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => const AuthScreen(),
      data: (user) => (user != null || guest)
          ? const GuestHomeScreen()
          : const AuthScreen(),
    );
  }
}
