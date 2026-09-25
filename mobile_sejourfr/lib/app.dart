import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/analytics/analytics.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class SejourFrApp extends ConsumerWidget {
  const SejourFrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // La file d'événements vit toute la session : l'observer ici la démarre au
    // lancement (envoi de ce qui reste du lancement précédent, reprise,
    // minuterie), même si aucun écran n'émet encore rien.
    ref.watch(analyticsQueueProvider);
    return MaterialApp.router(
      title: 'SejourFR',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.2,
          child: child!,
        );
      },
    );
  }
}
