import 'package:flutter/material.dart';

import '../../../screens/auth_screen.dart';
import '../../../screens/emergency_screen.dart';
import '../../../screens/guide_screen.dart';
import '../../../screens/my_requests_screen.dart';
import '../../../screens/neighborhood_screen.dart';
import '../../../screens/outages_screen.dart';
import '../../../screens/profile_screen.dart';
import '../../../screens/report_screen.dart';
import '../../../screens/services_screen.dart';
import '../../../screens/soz_sende_screen.dart';
import '../../ebelediye/presentation/ebelediye_screen.dart';
import '../../news/municipal_news_screen.dart';
import '../../parking/presentation/parking_screen.dart';
import '../../pati/presentation/gebze_pati_screen.dart';
import '../../pharmacy/presentation/pharmacies_screen.dart';
import '../../weather/presentation/weather_screen.dart';

class ChatbotNavigator {
  static GlobalKey<NavigatorState>? navigatorKey;

  static void navigate(BuildContext context, String route) {
    final page = _resolvePage(route);
    if (page != null) {
      final nav = navigatorKey?.currentState ?? Navigator.of(context);
      nav.push(MaterialPageRoute(builder: (_) => page));
    }
  }

  static Widget? _resolvePage(String route) {
    final cleanRoute = route.toLowerCase();

    // Kayıt Ekranı (Misafir modunda üye olma yönlendirmesi)
    if (cleanRoute.contains('register') || cleanRoute.contains('kayit')) {
      return const RegisterScreen();
    }

    // Giriş Ekranı
    if (cleanRoute.contains('auth') ||
        cleanRoute.contains('login') ||
        cleanRoute.contains('giris')) {
      return const AuthScreen();
    }

    // Taleplerim (Özel route)
    if (cleanRoute.contains('my_requests') ||
        cleanRoute.contains('taleplerim')) {
      return const MyRequestsScreen();
    }

    // Kesintiler (Su ve Elektrik)
    if (cleanRoute.contains('disruptions') ||
        cleanRoute.contains('outages') ||
        cleanRoute.contains('kesinti')) {
      return const OutagesScreen();
    }

    // Eczaneler
    if (cleanRoute.contains('pharmacies') || cleanRoute.contains('eczane')) {
      return const PharmaciesScreen();
    }

    // Hava Durumu
    if (cleanRoute.contains('weather') || cleanRoute.contains('hava')) {
      return const WeatherScreen();
    }

    // Haberler & Duyurular
    if (cleanRoute.contains('content') ||
        cleanRoute.contains('news') ||
        cleanRoute.contains('haber')) {
      return const MunicipalNewsScreen();
    }

    // Etkinlikler
    if (cleanRoute.contains('etkinlik') || cleanRoute.contains('events')) {
      return const GuideCategoryScreen(categoryId: 'etkinlikler');
    }

    // Otoparklar ('park' kontrolünden önce gelmeli çünkü 'parking'/'otopark' içinde 'park' geçiyor)
    if (cleanRoute.contains('parking') || cleanRoute.contains('otopark')) {
      return const ParkingScreen();
    }

    // Rehber alt kategorileri
    if (cleanRoute.contains('/places/lokantalar') ||
        cleanRoute.contains('lokanta')) {
      return const GuideCategoryScreen(categoryId: 'lokantalar');
    }
    if (cleanRoute.contains('/places/pazar') || cleanRoute.contains('pazar')) {
      return const GuideCategoryScreen(categoryId: 'pazar');
    }
    if (cleanRoute.contains('/places/parklar') || cleanRoute.contains('park')) {
      return const GuideCategoryScreen(categoryId: 'parklar');
    }
    if (cleanRoute.contains('/places/spor') || cleanRoute.contains('spor')) {
      return const GuideCategoryScreen(categoryId: 'spor');
    }
    if (cleanRoute.contains('/places/kultur') || cleanRoute.contains('kultur')) {
      return const GuideCategoryScreen(categoryId: 'kultur');
    }
    if (cleanRoute.contains('mezarlik') || cleanRoute.contains('vefat')) {
      return const GuideCategoryScreen(categoryId: 'mezarliklar');
    }
    if (cleanRoute.contains('kres') || cleanRoute.contains('akcem')) {
      return const GuideCategoryScreen(categoryId: 'kresler');
    }
    if (cleanRoute.contains('/places/belediye')) {
      return const GuideCategoryScreen(categoryId: 'belediye');
    }

    // Keşfet alt bölümleri (Tarihi Yerler: 0, Yöresel Lezzetler: 1, Doğa & Piknik: 2)
    if (cleanRoute.contains('doga') || cleanRoute.contains('piknik')) {
      return const GuideScreen(initialTab: 1, initialDiscoverSection: 2);
    }
    if (cleanRoute.contains('lezzet') || cleanRoute.contains('yoresel')) {
      return const GuideScreen(initialTab: 1, initialDiscoverSection: 1);
    }
    if (cleanRoute.contains('tarihi')) {
      return const GuideScreen(initialTab: 1, initialDiscoverSection: 0);
    }

    // Genel Rehber / Keşfet
    if (cleanRoute.contains('places') ||
        cleanRoute.contains('guide') ||
        cleanRoute.contains('rehber')) {
      return const GuideScreen(initialTab: 1);
    }

    // Çek & Gönder (Talep Bildirimi)
    if (cleanRoute.contains('report') || cleanRoute.contains('bildir')) {
      return const ReportScreen();
    }

    // Mahallemde (Çalışmalar, Kazı, Altyapı, Asfalt)
    if (cleanRoute.contains('neighborhood') || cleanRoute.contains('mahalle')) {
      return const NeighborhoodScreen();
    }

    // Gebze Pati (Sokak Hayvanları, Ambulans, Sahiplendirme)
    if (cleanRoute.contains('animals') ||
        cleanRoute.contains('pati') ||
        cleanRoute.contains('hayvan')) {
      return const GebzePatiScreen();
    }

    // Acil Durum & Toplanma Alanları
    if (cleanRoute.contains('emergency') || cleanRoute.contains('acil')) {
      return const EmergencyScreen();
    }

    // E-Belediye (Vergi, Beyan, İmar, Ruhsat vb.)
    if (cleanRoute.contains('ebelediye') ||
        cleanRoute.contains('vergi') ||
        cleanRoute.contains('payment')) {
      return const EBelediyeScreen();
    }

    // Söz Sende (Anketler ve Fikirler)
    if (cleanRoute.contains('soz_sende') || cleanRoute.contains('anket')) {
      return const SozSendeScreen();
    }

    // Profil & Ayarlar
    if (cleanRoute.contains('profile') || cleanRoute.contains('ayar')) {
      return const ProfileScreen();
    }

    // Tüm Hizmetler
    if (cleanRoute.contains('services') || cleanRoute.contains('hizmet')) {
      return const ServicesScreen();
    }

    return null;
  }
}
