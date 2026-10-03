import 'package:flutter/widgets.dart';

/// Observer du navigateur racine, branché sur `GoRouter.observers`.
///
/// Permet à un écran de réagir quand on y **revient** après avoir poussé un
/// flux par-dessus (`RouteAware.didPopNext`). On le type sur `PageRoute` pour
/// n'écouter que les transitions de pages : les bottom sheets / dialogs
/// (`PopupRoute`) ne déclenchent pas `didPopNext`, donc fermer une feuille ne
/// provoque pas de refetch inutile.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

/// **Un observer par branche du shell** (Navigation v2) : chaque onglet a son
/// navigateur, et un `NavigatorObserver` ne s'attache qu'à un seul. Le router
/// les pose sur ses `StatefulShellBranch.observers`, dans l'ordre des branches.
final List<RouteObserver<PageRoute<dynamic>>> brancheRouteObservers =
    List<RouteObserver<PageRoute<dynamic>>>.unmodifiable([
  for (var i = 0; i < 4; i++) RouteObserver<PageRoute<dynamic>>(),
]);

Iterable<RouteObserver<PageRoute<dynamic>>> get _observers =>
    [appRouteObserver, ...brancheRouteObservers];

/// **Abonne [aware] au retour sur l'écran de [context]**, quel que soit le
/// navigateur qui le porte.
///
/// 🛑 Un écran d'une branche vit sur le navigateur de son onglet ; les flux
/// plein écran (runner, briefing, résultats) sont poussés sur le navigateur
/// **racine**, au-dessus du shell. On s'abonne donc deux fois : à sa propre
/// page (un écran dépilé dans la branche) **et** à la page du shell (un flux
/// plein écran refermé). Sans la seconde, un écran de branche ne saurait
/// jamais qu'une production vient d'être rendue au-dessus de lui.
///
/// À appeler en `didChangeDependencies` (idempotent), avec
/// [cesserDeSuivreLeRetour] en `dispose`.
void suivreLeRetour(RouteAware aware, BuildContext context) {
  final route = ModalRoute.of(context);
  if (route is! PageRoute<dynamic>) return;
  _abonner(aware, route);
  final navigateur = route.navigator;
  if (navigateur == null) return;
  final hote = ModalRoute.of(navigateur.context);
  if (hote is PageRoute<dynamic> && hote != route) _abonner(aware, hote);
}

void cesserDeSuivreLeRetour(RouteAware aware) {
  for (final observer in _observers) {
    observer.unsubscribe(aware);
  }
}

void _abonner(RouteAware aware, PageRoute<dynamic> route) {
  for (final observer in _observers) {
    if (observer.navigator != null && observer.navigator == route.navigator) {
      observer.subscribe(aware, route);
      return;
    }
  }
}
