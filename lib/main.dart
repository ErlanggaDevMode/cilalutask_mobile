import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'state/app_state_controller.dart';
import 'state/app_state_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init fallback: $e');
  }

  final appStateController = AppStateController();
  await appStateController.initStorage();

  runApp(CilalutaskApp(controller: appStateController));
}

class CilalutaskApp extends StatelessWidget {
  final AppStateController controller;

  const CilalutaskApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      controller: controller,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return MaterialApp(
            title: 'Cilalutask Mobile',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: controller.isAuthenticated
                ? const MainNavigationScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
