import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/push_service.dart';
import 'features/news/presentation/news_screen.dart';
import 'firebase_options.dart';
import 'screens/guest_home_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
    // Navigator hazır olduktan sonra başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushService.init(onNewsOpened: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NewsScreen()),
        );
      });
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