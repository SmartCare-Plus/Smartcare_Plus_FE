/// SMARTCARE+ Flutter Application
///
/// AI-Powered Elderly Care Ecosystem
/// Dark Futuristic Theme with Glassmorphism
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/config/theme.dart';
import 'core/config/routes.dart';
import 'core/services/notification_service.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set background message handler (must be set before any other Firebase Messaging calls)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationService().initialize();

  // Lock to portrait mode (better for elderly users)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: SmartCarePlusApp(),
    ),
  );
}

class SmartCarePlusApp extends StatelessWidget {
  const SmartCarePlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AppShell();
  }
}

class _AppShell extends ConsumerWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'SMARTCARE+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightFuturistic,
      darkTheme: AppTheme.darkFuturistic,
      themeMode: themeMode,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
      builder: (context, child) {
        final isLight = Theme.of(context).brightness == Brightness.light;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isLight ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
            systemNavigationBarIconBrightness:
                isLight ? Brightness.dark : Brightness.light,
          ),
        );

        return child ?? const SizedBox.shrink();
      },
    );
  }
}
