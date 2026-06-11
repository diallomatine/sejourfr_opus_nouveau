import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/dashboard_models.dart';
import '../router/app_router.dart';

/// Icône canonique d'une catégorie du dashboard (`CategoryStat.code`).
/// Partagé par Accueil, Réviser et Progrès.
IconData dashboardCategoryIcon(String code) => switch (code) {
      'TCF_CO' => LucideIcons.ear,
      'TCF_CE' => LucideIcons.fileText,
      'TCF_STRUCTURE' => LucideIcons.layoutGrid,
      'TCF_EE' => LucideIcons.penLine,
      'TCF_EO' => LucideIcons.mic,
      'CIV_PRINCIPES' => LucideIcons.scale,
      'CIV_INSTITUTIONS' => LucideIcons.landmark,
      'CIV_DROITS_DEVOIRS' => LucideIcons.handshake,
      'CIV_HISTOIRE_GEO' => LucideIcons.map,
      'CIV_SOCIETE' => LucideIcons.house,
      _ => LucideIcons.bookOpen,
    };

/// Route de l'écran détail d'une catégorie du dashboard (« s'entraîner sur
/// cette catégorie »). Les thèmes civique routent vers leur détail via
/// `themeId` ; les épreuves TCF vers leur hub d'épreuve.
String dashboardCategoryRoute(DashboardCategoryStat stat) => switch (stat.code) {
      'TCF_CO' => AppRoutes.tcfCoDetail,
      'TCF_CE' => AppRoutes.tcfCeDetail,
      'TCF_STRUCTURE' => AppRoutes.tcfStructureDetail,
      'TCF_EE' => AppRoutes.tcfEeDetail,
      'TCF_EO' => AppRoutes.tcfEoDetail,
      _ => AppRoutes.civiqueThemeDetail
          .replaceFirst(':themeId', stat.themeId ?? ''),
    };

/// Ordre canonique des 5 épreuves TCF pour l'affichage (le backend renvoie
/// les thèmes QCM puis ajoute EE/EO en synthétique).
const tcfCategoryOrder = [
  'TCF_CO',
  'TCF_CE',
  'TCF_STRUCTURE',
  'TCF_EE',
  'TCF_EO',
];

/// Réordonne les catégories TCF du dashboard selon [tcfCategoryOrder].
List<DashboardCategoryStat> orderedTcfCategories(
  List<DashboardCategoryStat> tcf,
) {
  final byCode = {for (final s in tcf) s.code: s};
  return [
    for (final code in tcfCategoryOrder)
      if (byCode[code] != null) byCode[code]!,
  ];
}
