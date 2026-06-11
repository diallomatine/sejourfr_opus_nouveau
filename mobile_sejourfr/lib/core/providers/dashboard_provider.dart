import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/repositories.dart';
import '../models/dashboard_models.dart';

/// Agrégat `GET /api/me/dashboard` partagé par Accueil, Réviser et Progrès.
/// autoDispose : revenir sur un onglet recrée le widget et refetch, ce qui
/// garde les stats fraîches après un entraînement.
final dashboardProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) async {
  return ref.read(userContentRepositoryProvider).dashboard();
});
