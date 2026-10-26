import 'screens/auth_gate.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/news/municipal_news_screen.dart';
import 'core/services/events_service.dart';
import 'core/services/push_service.dart';
import 'core/services/notification_service.dart';
import 'screens/notifications_screen.dart';
import 'firebase_options.dart';
import 'features/chatbot/chatbot.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_strings.dart';
import 'core/accessibility/font_scale_provider.dart';
import 'core/theme/theme_provider.dart';

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

final navigatorKey = GlobalKey<NavigatorState>();
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase.initializeApp failed: $e');
  }
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
    ChatbotNavigator.navigatorKey = navigatorKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationsNotifier.onInAppNotification = (notif) {
        final sm = rootScaffoldMessengerKey.currentState;
        if (sm == null) return;
        sm.hideCurrentSnackBar();
        sm.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0A2A66),
            behavior: SnackBarBehavior.floating,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(notif.icon, color: const Color(0xFFFFB300), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notif.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'GÖR',
              textColor: const Color(0xFFFFB300),
              onPressed: () {
                navigatorKey.currentState?.push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      };

      PushService.init(
        onNewsOpened: () {
          final navigator = navigatorKey.currentState;

          if (navigator == null) return;

          navigator.push(
            MaterialPageRoute(builder: (_) => const MunicipalNewsScreen()),
          );
        },
      );
      EventsService().ensureEventsSeeded();
    });
  }

  ThemeData _buildTheme(bool isLargeFont, bool isDark) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF0A2A66),
      brightness: isDark ? Brightness.dark : Brightness.light,
      surface: isDark ? const Color(0xFF1E293B) : Colors.white,
      onSurface: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0A1F44),
      primary: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0A2A66),
      onPrimary: isDark ? const Color(0xFF0F172A) : Colors.white,
      outline: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );

    final baseTextTheme =
        (isDark ? ThemeData.dark() : ThemeData.light()).textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      textTheme: baseTextTheme.apply(
        bodyColor: isDark ? Colors.white : const Color(0xFF0A1F44),
        displayColor: isDark ? Colors.white : const Color(0xFF0A1F44),
      ),
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF6F8FC),
      cardColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      dividerColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5FD),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF6F8FC),
        foregroundColor: isDark ? Colors.white : const Color(0xFF0A1F44),
        elevation: 0,
        scrolledUnderElevation: 0,
        // NOT: Buraya iconTheme koymayın. AppBar'da appBarTheme.iconTheme,
        // ekrandaki foregroundColor'ı ezer ve geri butonu koyu kalır.
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: isDark ? 0 : 2,
        shadowColor: const Color(0xFF0A2A66).withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark
              ? const BorderSide(color: Color(0xFF334155))
              : BorderSide.none,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: isDark
              ? const BorderSide(color: Color(0xFF334155))
              : BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF1E293B)
            : const Color(0xFF0A2A66),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        textStyle: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0A1F44),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isDark
              ? const BorderSide(color: Color(0xFF334155))
              : BorderSide.none,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: isDark ? Colors.white : const Color(0xFF0A2A66),
        unselectedLabelColor: isDark
            ? const Color(0xFF94A3B8)
            : const Color(0xFF5F6F8A),
        indicatorColor: const Color(0xFFFF7A00),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        selectedColor: const Color(0xFF0A2A66),
        labelStyle: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0A1F44),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE4E9F2),
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : const Color(0xFF0A1F44),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF5F6F8A),
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5F6F8A),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(appThemeModeProvider);

    final activeLang = ref.watch(appLanguageProvider);
    final isLargeFont = ref.watch(appLargeFontProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Gebze Dijital',
      locale: Locale(activeLang),
      supportedLocales: const [Locale('tr'), Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: currentThemeMode,
      theme: _buildTheme(isLargeFont, false),
      darkTheme: _buildTheme(isLargeFont, true),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // Büyük yazı modu: Tüm uygulama genelinde metinleri %25 oranında büyütür
        final textScaler = isLargeFont
            ? const TextScaler.linear(1.25)
            : const TextScaler.linear(1.0);

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: textScaler),
          child: Bot82Overlay(
            navigatorKey: navigatorKey,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const AuthGate(),
    );
  }
}