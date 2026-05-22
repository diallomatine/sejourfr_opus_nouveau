# Refonte entraînement (en cours)

Bascule progressive d'une nav "Entraîner / Examen" générique vers **2 hubs métier dédiés
Civique et TCF**, calqués sur le design `tcf_entrainement_mobile_design.html` à la racine
(14 écrans, archi hub → détail module → série → questions → feedback → fin de série).

## Statut mobile (lots 1 → 5 faits)

Bottom nav `Accueil · Civique · TCF · Progression · Profil`. Hubs Civique (5 thèmes
officiels) et TCF (CO/CE/EE IA/EO IA) dans `mobile_sejourfr/lib/screens/{civique,tcf}/`,
widgets de hub partagés dans `screens/hub/widgets/hub_widgets.dart`.

Tap module → **écran détail** (`screens/module_detail/`) avec hero, stats et CTA :

- **Thèmes civique + TCF CO/CE** : score de maîtrise + bouton "Commencer l'entraînement"
  → POST attempts → runner. **Le détail TCF CO/CE a en plus 3 onglets
  Séries / Examens / Erreurs**. L'onglet Séries affiche 3 cards niveau (A2 vert / B1 ambre /
  B2 rouge). Tap niveau → push `TcfLevelLotsScreen` (écran dédié, hero coloré au niveau +
  liste des lots chargés depuis `GET /api/lots`, cf. `lots-entrainement.md`). Lot A2 = 15 Q,
  B1 = 20 Q, B2 = 25 Q. Tap d'un lot → `POST /api/attempts {lotNumero}` (réservé premium,
  paywall sinon). Examens et Erreurs sont en placeholder "Bientôt" pour l'instant.
- **TCF EE/EO** : carte "Comment ça marche" + "Voir les tâches" qui push
  `ProductionHubScreen` (sélection T1/T2/T3). Les anciens écrans `TrainingSetupScreen` et
  `ExamSetupScreen` ont été **supprimés**, ainsi que les routes `/training` et `/exam`.
  Sheet paywall réutilisable dans `core/widgets/paywall_sheet.dart`. Carte "Examen blanc
  complet" présente mais inactive.

## Reste à faire mobile (lots suivants)

Orchestrateur Riverpod de l'examen blanc complet (enchaînement CO → CE → EE 3T → EO 3T en
utilisant les sub-attemptIds renvoyés par `POST /api/full-tcf-exams`) + écran progression
"Étape X/4" + bilan final agrégé CECRL plancher (`GET /api/full-tcf-exams/{id}`). Le backend
est prêt — UI 20 slots + briefing sheet aussi. Score par épreuve TCF côté backend (pour
remplacer l'agrégat global affiché actuellement sur CO/CE) reste à faire.

## À reproduire côté web

`web_sejoufr/` une fois le mobile stabilisé : même découpe Civique/TCF dans la nav
principale, mêmes hubs, même paywall. La parité front mobile↔web est un axe produit.

Cf. `mobile_sejourfr/CLAUDE.md` section "Bottom nav et hubs Civique / TCF" pour le détail
technique.
