import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/news/municipal_news_screen.dart';
import 'core/services/push_service.dart';
import 'firebase_options.dart';
import 'screens/guest_home_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/app_strings.dart';
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
    // Firestore'daki profil dili yüklendiğinde appLanguageProvider'ı eşitle
    ref.listen<AsyncValue<UserProfile>>(profileProvider, (prev, next) {
      final lang = next.value?.language;
      if (lang != null && lang.isNotEmpty && lang != ref.read(appLanguageProvider)) {
        ref.read(appLanguageProvider.notifier).setLanguage(lang);
      }
    });

    final activeLang = ref.watch(appLanguageProvider);

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
      ),
      home: const GuestHomeScreen(),
    );
  }
}
