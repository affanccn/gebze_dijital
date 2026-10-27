import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/chat_action.dart';
import '../../domain/chat_message.dart';

class BotMessageWidget extends ConsumerWidget {
  final ChatMessage message;
  final Function(String) onSuggestionTap;
  final Function(String)? onNavigate;

  const BotMessageWidget({
    super.key,
    required this.message,
    required this.onSuggestionTap,
    this.onNavigate,
  });

  String _getNavigationLabel(String route) {
    final r = route.toLowerCase();
    if (r.contains('register') || r.contains('kayit')) return 'Kayıt Ol / Üye Ol';
    if (r.contains('auth') || r.contains('login') || r.contains('giris')) {
      return 'Giriş Yap';
    }
    if (r.contains('my_requests')) return 'Taleplerimi Görüntüle';
    if (r.contains('disruptions') || r.contains('outages')) {
      return 'Kesintileri Görüntüle';
    }
    if (r.contains('pharmacies')) return 'Nöbetçi Eczaneleri Gör';
    if (r.contains('weather')) return 'Hava Durumunu Aç';
    if (r.contains('content') || r.contains('news') || r.contains('haber')) return 'Haberleri Oku';
    if (r.contains('etkinlik') || r.contains('events')) return 'Etkinlikleri Gör';
    if (r.contains('lokanta')) return 'Kent Lokantalarını Aç';
    if (r.contains('pazar')) return 'Semt Pazarlarını Gör';
    if (r.contains('park')) return 'Park ve Bahçeleri Gör';
    if (r.contains('spor')) return 'Spor Tesislerini Gör';
    if (r.contains('kultur')) return 'Kültür Merkezlerini Gör';
    if (r.contains('mezarlik') || r.contains('vefat')) return 'Mezarlık Hizmetlerini Gör';
    if (r.contains('kres') || r.contains('akcem')) return 'Kreş ve AKÇEM Merkezleri';
    if (r.contains('doga') || r.contains('piknik')) return 'Doğa ve Piknik Alanlarını Gör';
    if (r.contains('tarihi')) return 'Tarihi Yerleri Keşfet';
    if (r.contains('places') || r.contains('guide') || r.contains('rehber')) {
      return 'Gebze Rehberini Aç';
    }
    if (r.contains('report')) return 'Talep Oluştur (Çek & Gönder)';
    if (r.contains('neighborhood')) return 'Mahalle Çalışmalarını Gör';
    if (r.contains('parking')) return 'Otopark Doluluklarını Gör';
    if (r.contains('animals') || r.contains('pati')) return 'Gebze Pati\'yi Aç';
    if (r.contains('emergency')) return 'Acil Toplanma Alanları';
    if (r.contains('ebelediye') ||
        r.contains('payment') ||
        r.contains('vergi')) {
      return 'E-Belediye Portalına Git';
    }
    if (r.contains('soz_sende')) return 'Söz Sende / Anketlere Git';
    if (r.contains('profile')) return 'Profil & Ayarları Aç';
    return 'İlgili Sayfayı Aç';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRoute =
        message.action?.type == ChatActionType.navigate &&
        message.action?.route != null;
    final hasSuggestions =
        message.suggestions != null && message.suggestions!.isNotEmpty;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE4E9F2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 30 : 12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0A1F44),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (hasRoute)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A00),
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: const Color(0xFFFF7A00).withAlpha(100),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: () {
                if (onNavigate != null) {
                  onNavigate!(message.action!.route!);
                }
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(
                _getNavigationLabel(message.action!.route!),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        if (hasSuggestions) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: message.suggestions!.map((suggestion) {
              return ActionChip(
                elevation: 0,
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF1E5BC6),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                label: Text(
                  suggestion,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFF0A2A66),
                  ),
                ),
                onPressed: () => onSuggestionTap(suggestion),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
