import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_strings.dart';

/// Gebze Belediyesi - Güvenli Telefon Arama ve Tuş Takımı Yönlendiricisi
class PhoneLauncher {
  /// Telefon aramasını başlatır ve tuş takımına / arama ekranına yönlendirir.
  /// 
  /// Android 11+ paket kısıtlamaları (package visibility) ve canLaunchUrl()
  /// kaynaklı bloklamaları aşmak için doğrudan launchUrl dener.
  /// Arama desteklenmeyen ortamlarda (emülatör, Wi-Fi tablet vb.) numarayı
  /// panoya kopyalar ve kullanıcıya bilgilendirme gösterir.
  static Future<bool> makeCall(
    BuildContext context,
    String phone, {
    String lang = 'tr',
  }) async {
    // Numarayı temizle: sadece rakamlar ve varsa baştaki '+' kalsın
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return false;

    bool launched = false;

    // 1. Doğrudan externalApplication modunda tel: URL'sini aç (Dialer tuş takımı)
    try {
      final uri = Uri(scheme: 'tel', path: clean);
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    // 2. Başarısız olduysa platform varsayılan moduyla dene
    if (!launched) {
      try {
        final uri = Uri.parse('tel:$clean');
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        launched = false;
      }
    }

    // 3. Fallback: Genel launchUrl
    if (!launched) {
      try {
        launched = await launchUrl(Uri.parse('tel:$clean'));
      } catch (_) {
        launched = false;
      }
    }

    // 4. Eğer hiçbir şekilde arama başlatılamadıysa (emülatör vb.) numarayı panoya kopyala
    if (!launched) {
      try {
        await Clipboard.setData(ClipboardData(text: clean));
      } catch (_) {}

      if (context.mounted) {
        final template = AppStrings.get('call_failed_toast', lang);
        final msg = template.contains('{0}')
            ? template.replaceAll('{0}', phone)
            : '$phone kopyalandı';

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(msg),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF061B45),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Kopyalandı',
                textColor: const Color(0xFFFF7A00),
                onPressed: () {},
              ),
            ),
          );
      }
    }

    return launched;
  }
}
