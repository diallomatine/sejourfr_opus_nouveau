import 'package:flutter/widgets.dart';

/// Observer global du navigateur racine, branché sur `GoRouter.observers`.
///
/// Permet à un écran de réagir quand on y **revient** après avoir poussé un
/// flux par-dessus (`RouteAware.didPopNext`). On le type sur `PageRoute` pour
/// n'écouter que les transitions de pages : les bottom sheets / dialogs
/// (`PopupRoute`) ne déclenchent pas `didPopNext`, donc fermer une feuille ne
/// provoque pas de refetch inutile.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
