/// « Mes favoris », ouvert depuis le Profil : les questions que le candidat a
/// épinglées pendant un entraînement.
///
/// 🛑 **Miroir mot pour mot** de `web_sejoufr/lib/favoris.ts`. Un texte qui
/// bouge ici bouge là-bas dans la même passe.
///
/// Remplace le hub « Mon entraînement » (historique, mes questions, favoris),
/// supprimé le 2026-09-24 avec l'historique et la liste des erreurs (décision
/// du propriétaire : la progression suffit pour voir son avancement).
library;

import '../../core/models/enums.dart';

const String kFavorisTitle = 'Mes favoris';
const String kFavorisLead = 'Retrouvez les questions que vous avez marquées.';

/// Sous-titre de la ligne du Profil.
const String kFavorisRowSub = "Questions épinglées pendant l'entraînement";

String favorisModuleLabel(AppModule module) =>
    module == AppModule.tcf ? 'TCF' : 'Civique';

const String kFavorisEmptyTitle = 'Aucun favori';
const String kFavorisEmptyHint =
    "Pendant un entraînement, appuyez sur l'icône marque-page pour épingler une question.";
const String kFavorisEmptyCta = 'Lancer un entraînement';
const String kFavorisRetry = 'Réessayer';

/// Taille de fenêtre de la liste, et palier du bouton « Afficher plus ».
const int kFavorisPageSize = 20;

String favorisShowMore(int remaining) =>
    'Afficher plus ($remaining restante${remaining > 1 ? 's' : ''})';

// ── Détail d'un favori ──────────────────────────────────────────────────
const String kFavoriOn = 'Favori';
const String kFavoriAdd = 'Ajouter aux favoris';
