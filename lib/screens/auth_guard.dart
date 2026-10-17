import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_strings.dart';
import 'auth_screen.dart';
import 'auth_service.dart';

/// Dosya yolu: lib/screens/auth_guard.dart
///
/// Üyelik gerektiren bir bölüme girmeden önce çağırın:
///
/// ```dart
/// if (!requireLogin(context, ref)) return;
/// Navigator.of(context).push(...);
/// ```
/// Giriş yapılmışsa true döner. Misafirse "üye olmanız gerekmektedir"
/// penceresini gösterir ve false döner.
bool requireLogin(BuildContext context, WidgetRef ref) {
  if (ref.read(isLoggedInProvider)) return true;

  final lang = ref.read(appLanguageProvider);
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      icon: const Icon(
        Icons.lock_outline_rounded,
        color: Color(0xFFFF7A00),
        size: 44,
      ),
      title: Text(
        at(lang, 'gate_title'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Text(
        at(lang, 'gate_msg'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, height: 1.4),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(at(lang, 'cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0A2A66),
          ),
          onPressed: () {
            Navigator.of(ctx).pop();
            if (!context.mounted) return;
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AuthScreen()));
          },
          child: Text(at(lang, 'gate_go')),
        ),
      ],
    ),
  );
  return false;
}
