import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'logic/auth_provider.dart';

import 'presentation/screens/auth/login_screen.dart';
import 'presentation/navigation/nav_bar.dart';

void main() async {
  // flutter bind
  WidgetsFlutterBinding.ensureInitialized();

  // init local storage for jwt
  final sharedPreferences = await SharedPreferences.getInstance();

  // local db SQLite
  // await DatabaseService().database;

  runApp(
    ProviderScope(
      overrides: [
        // share provider SharedPreferences in Riverpod
        sharedPrefsProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // check auth state in real time
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      // main navigation logic
      home: _getHome(authState),
    );
  }

  Widget _getHome(AuthState authState) {
    // if its loading
    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // if user authorized - show navbar
    if (authState.user != null) {
      return const MainNavBar();
    }

    // if not authorized - login screen
    return const LoginScreen();
  }
}
