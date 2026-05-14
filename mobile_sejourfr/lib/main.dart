import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'screens/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Verrouillage portrait pour le MVP — on assouplira plus tard si besoin.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Précharge les SharedPreferences pour avoir un accès synchrone dans les
  // redirects du router (sinon l'onboarding se réaffiche à chaque boot le
  // temps que le FutureProvider résolve).
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const SejourFrApp(),
    ),
  );
}
