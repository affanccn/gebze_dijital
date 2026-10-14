import 'screens/auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/news/municipal_news_screen.dart';
import 'core/services/push_service.dart';
import 'firebase_options.dart';
import 'screens/guest_home_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/app_strings.dart';
import 'core/accessibility/font_scale_provider.dart';
import 'features/profile/models/user_profile.dart';
import 'features/profile/services/profile_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushService.init(
        onNewsOpened: () {
          final navigator = navigatorKey.currentState;

          if (navigator == null) return;

          navigator.push(
            MaterialPageRoute(
              builder: (_) => const MunicipalNewsScreen(),
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Firestore'daki profil dili ve büyük yazı tercihi yüklendiğinde provider'ları eşitle
    ref.listen<AsyncValue<UserProfile>>(profileProvider, (prev, next) {
      final lang = next.value?.language;
      if (lang != null && lang.isNotEmpty && lang != ref.read(appLanguageProvider)) {
        ref.read(appLanguageProvider.notifier).setLanguage(lang);
      }
      final isLarge = next.value?.isLargeFont;
      if (isLarge != null && isLarge != ref.read(appLargeFontProvider)) {
        ref.read(appLargeFontProvider.notifier).setLargeFont(isLarge);
      }
    });

    final activeLang = ref.watch(appLanguageProvider);
    final isLargeFont = ref.watch(appLargeFontProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Gebze Dijital',
      locale: Locale(activeLang),
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0B5FA5),
        // Yaşlılar ve az görenler için buton dokunma alanlarını ve yazılarını büyütme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: isLargeFont ? const Size(64, 52) : const Size(64, 44),
            padding: isLargeFont
                ? const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: isLargeFont ? const Size(64, 52) : const Size(64, 44),
            padding: isLargeFont
                ? const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: isLargeFont ? const Size(64, 52) : const Size(64, 44),
            padding: isLargeFont
                ? const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: isLargeFont ? const Size(48, 48) : const Size(40, 40),
            padding: isLargeFont
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // Büyük yazı modu: Tüm uygulama genelinde metinleri %25 oranında büyütür
        final textScaler = isLargeFont
            ? const TextScaler.linear(1.25)
            : const TextScaler.linear(1.0);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: textScaler,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthGate(),
    );
  }
}

