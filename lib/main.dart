import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/assets/Cilalutask_logo_data.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/splash_screen.dart';
import 'state/app_state_controller.dart';
import 'state/app_state_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await precacheLogoBytes();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init fallback: $e');
  }

  final appStateController = AppStateController();
  await appStateController.initStorage();

  runApp(CilulataskApp(controller: appStateController));
}

class CilulataskApp extends StatefulWidget {
  final AppStateController controller;
  final bool showSplash;

  const CilulataskApp({
    super.key,
    required this.controller,
    this.showSplash = true,
  });

  @override
  State<CilulataskApp> createState() => _CilulataskAppState();
}

class _CilulataskAppState extends State<CilulataskApp> {
  late bool _isSplashCompleted;

  @override
  void initState() {
    super.initState();
    _isSplashCompleted = !widget.showSplash;
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      controller: widget.controller,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return MaterialApp(
            title: 'Cilulatask Mobile',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: !_isSplashCompleted
                ? SplashScreen(
                    onCompleted: () {
                      if (mounted) {
                        setState(() {
                          _isSplashCompleted = true;
                        });
                      }
                    },
                  )
                : (widget.controller.isAuthenticated
                      ? const MainNavigationScreen()
                      : const LoginScreen()),
          );
        },
      ),
    );
  }
}
