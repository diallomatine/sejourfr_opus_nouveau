import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Concatène les query params courants de la route active à `path`. Utilisé
/// dans le flow EE/EO pour propager `fullExamId` + `subAttemptId` à travers
/// les écrans (briefing → enregistrement → termine → résultats) quand
/// l'utilisateur est dans un examen blanc TCF complet.
String withCurrentQuery(BuildContext context, String path) {
  final qp = GoRouterState.of(context).uri.queryParameters;
  if (qp.isEmpty) return path;
  final separator = path.contains('?') ? '&' : '?';
  final qs = qp.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');
  return '$path$separator$qs';
}
