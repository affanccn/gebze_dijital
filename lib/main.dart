import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/news/municipal_news_screen.dart';
import 'core/services/push_service.dart';
import 'firebase_options.dart';
import 'screens/guest_home_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Gebze Dijital',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0B5FA5),
      ),
      home: const GuestHomeScreen(),
    );
  }
}
