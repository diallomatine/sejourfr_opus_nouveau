import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import 'analytics.dart';
import 'tracked_screens.dart';

/// `SCREEN_VIEWED` à chaque changement d'écran — un seul écouteur, branché
/// sur le `routerDelegate` du `GoRouter` (`routerProvider`). Miroir web :
/// `ActivityTracker` (`usePathname`).
///
/// - Le chemin envoyé vient du **gabarit** de la route affichée
///   (`GoRouterState.fullPath`, route poussée comprise), traduit par
///   [TrackedScreen] : jamais l'adresse concrète.
/// - **Une vue par adresse affichée** : une nouvelle notification du routeur
///   pour la même adresse (rafraîchissement d'auth, reconstruction) n'est pas
///   une nouvelle vue, ni un changement de seuls paramètres de requête. Le
///   retour sur un écran après un dépilement en est une, comme le « précédent »
///   du navigateur sur le web.
/// - Les feuilles et dialogues ne sont pas des routes : ils ne comptent pas.
class ScreenViewTracker {
  ScreenViewTracker(this._analytics);

  final AnalyticsService _analytics;
  String? _lastLocation;

  /// Écran d'attente du démarrage : affiché avant toute décision de route, il
  /// n'est pas un écran consulté.
  static const Set<String> _technicalRoutes = {AppRoutes.splash};

  void onRouteChanged(GoRouter router) {
    final GoRouterState state;
    try {
      state = router.state;
    } catch (_) {
      return;
    }
    final template = state.fullPath;
    if (template == null ||
        template.isEmpty ||
        _technicalRoutes.contains(template)) {
      return;
    }
    final location = state.uri.path;
    if (location == _lastLocation) return;
    _lastLocation = location;
    _analytics.track(
      AnalyticsEvent.screenViewed,
      path: TrackedScreen.pathForRoute(template),
    );
  }
}
