# Décisions d'implémentation — Admin · Productions IA

Référence de départ : `audit-admin-productions-ia.md` (validé, non modifié) et les arbitrages
F-1 B, F-2 A, F-3 A, F-4 A, F-5 A, F-6 A, F-7 A, F-9 A, F-10 A du propriétaire.
Format : décision · pourquoi · ce que ça change · ce qu'on pourrait modifier plus tard.

---

## Backend (lot 1 + partie back du lot 3) — 2026-10-03

### DI-01 — Migration `V085__schema_signalements_evaluations.sql`, telle que l'audit §E.1
- **Décision** : table `ai_evaluation_flags` reprise mot pour mot de l'audit (états en colonnes,
  retrait soft, index unique partiel « un actif par évaluation », index du filtre par soumission).
- **Pourquoi** : V085 vérifié libre (dernier schéma `V084`, `V879` hors plage). Modèle validé (F-3 A).
- **Change** : prochain numéro de schéma = `V086` (`docs/migrations-flyway.md` mis à jour).
- **Plus tard** : une colonne `motif` élargie passe par une nouvelle contrainte, jamais par une réécriture de V085.

### DI-02 — Une seule expression SQL pour le statut IA et l'état de signalement
- **Décision** : liste = requête native (CTE) + comptage, dans `AdminProductionReadRepository`.
  Le statut IA (F-6 A : `EN_COURS` / `EVALUEE` / `NON_EVALUABLE` / `ECHEC`) et l'état de
  signalement sont calculés dans ce CASE et nulle part ailleurs ; l'en-tête de la fiche relit la
  même requête filtrée sur l'id.
- **Pourquoi** : une règle = une autorité ; filtres, tri par niveau et coût figé (2 requêtes/page,
  verrouillé par égalité) en une passe.
- **Change** : `EVALUATED` sans ligne d'évaluation (cas théorique) est rangé `EVALUEE` sans niveau.
- **Plus tard** : si le volume prod l'exige, index `production_submissions (submitted_at DESC, id DESC)` (audit E.2, non créé).

### DI-03 — Sémantique du filtre « Signalement » : trois états disjoints
- **Décision** : `SIGNALEES` = signalement actif **non vérifié** ; `VERIFIEES` = actif vérifié ;
  `NON_SIGNALEES` = aucun actif (un retiré compte comme non signalé). Absence de filtre = toutes.
  Valeurs servies en ligne : `etatSignalement = AUCUN | SIGNALE | VERIFIE` ; dans l'historique
  d'un signalement : `SIGNALE | VERIFIE | RETIRE`.
- **Pourquoi** : le plus lisible — chaque production tombe dans exactement un filtre, le compteur
  des trois fait le total.
- **Change** : « Signalées » n'inclut pas les vérifiées ; le front libelle « À vérifier » s'il veut.
- **Plus tard** : un 4ᵉ filtre « signalées (toutes) » = `SIGNALE ∪ VERIFIE` s'ajoute sans casser l'existant.

### DI-04 — Le signalement vise la DERNIÈRE évaluation, la liste lit par production
- **Décision** : `evaluation_id` = dernière évaluation (celle que voit le candidat), `submission_id`
  dénormalisé ; la liste lit le signalement actif le plus récent de la production.
- **Pourquoi** : 1 production = 1 évaluation en pratique (audit A.4) ; la règle « au plus un actif
  par évaluation » vient de l'audit.
- **Plus tard** : si les ré-évaluations deviennent réelles, filtrer la liste sur l'évaluation courante.

### DI-05 — Contrat HTTP du signalement
- **Décision** : `POST /{submissionId}/flags` → 201 ; motif absent/inconnu ou commentaire > 1000 → 400 ;
  pas d'évaluation (en cours, échec) → 422 ; déjà actif → 409 ; inconnue/hors périmètre → 404.
  `POST /flags/{id}/verify` idempotent, 409 sur un retiré ; `POST /flags/{id}/remove` idempotent.
  Commentaire vide → `null`. Auteur = `CurrentUser`, jamais le corps.
- **Pourquoi** : chemins de l'audit §D.1 ; codes alignés sur `GlobalExceptionHandler`
  (`BusinessException` 422, `IllegalStateException` 409).
- **Plus tard** : « dé-vérifier » n'existe pas (brief : deux actions seulement).

### DI-06 — F-1 B : suppression de la liste Calibration, ajout du filtre `annotation`
- **Décision** : `GET /api/admin/calibration/submissions` est **supprimé** (404, verrouillé par
  `AdminRoutesSecurityIT`), avec `CalibrationSubmissionDto`, `CalibrationSubmissionMapper`,
  `AdminCalibrationService.listSubmissions`, `ProductionSubmissionManager.findByStatutOrderedBySubmittedAt`,
  `HumanCalibrationNoteManager.findAnnotatedSubmissionIds` et leurs tests. Pour ne pas perdre le
  geste « à annoter / déjà annotées », la liste Productions IA reçoit un filtre
  `annotation=ANNOTEES|NON_ANNOTEES` et chaque ligne porte `annotee`.
- **Pourquoi** : l'admin est le seul consommateur (aucun appel web/mobile) ; refonte = suppression
  de l'ancien ; pas deux listes concurrentes.
- **Change** : le front admin doit migrer (voir « Pour le front » ci-dessous). Sont conservés :
  `GET /stats`, `GET /stats/niveau`, `GET|POST /submissions/{id}/human-note`.
- **Plus tard** : rien — la note humaine reste lue par son endpoint dédié (pas recopiée dans la fiche).

### DI-07 — Lire une grille par version (`ProductionRubricsProvider.grilleDeVersion`)
- **Décision** : le provider expose `Grille` (rubriques, seuils, couplage, plafonds, bandes) pour
  une version donnée, construite par **la même fusion fichier > configuration** que la grille
  active (`construire`, extrait de `load`). Version contrôlée par motif (`v12`, `v4.2`…), fichier
  lu dans le classpath, mis en cache ; `null`, mal formée, non livrée ⇒ vide. Pas de validation de
  contrat de sortie (une grille historique n'appelle aucun modèle).
- **Pourquoi** : F-5 A — relire avec la grille de l'évaluation sans recopier un seuil.
- **Change** : pour v3 → v4.2 (pas de bloc `commun.niveau`), seuils et critères porteurs viennent de
  la **configuration actuelle**, exactement comme la notation les lirait ; servi `seuilsDeLaGrille: false`.
  Idem pour le coupe-circuit et les listes du couplage, et les niveaux max des plafonds (réglages
  de déploiement).
- **Révision du 2026-10-03 (règle conservatrice du propriétaire)** : avant correction,
  `AdminProductionCalculService` concluait `coherent` (y compris `false`) même quand une partie du
  calcul venait de la configuration actuelle — un faux « incohérent » possible sur v3 → v5.
  Désormais :
  - `Grille.parametresDeLaGrille()` = le fichier déclare **ses trois blocs d'échelle**
    (`commun.niveau`, `commun.couplage`, `commun.plafonds`) ; et chaque critère de la tâche porte
    un **poids** déclaré par la grille ;
  - sinon : `statut = CALCUL_PARTIEL`, libellé servi « Calcul partiel — paramètres historiques
    non traçables, cohérence non vérifiable. », tout le calcul reste servi mais **`coherent` vaut
    toujours `null`**, jamais `false`. Concerne en pratique v3, v4, v4.1, v4.2 (aucun bloc) et v5
    (seuils seuls) ; v6 → v15 sont complètes et gardent `CALCULE` avec cohérence conclue.
  - Reste repris du déploiement pour TOUTES les grilles : coupe-circuits, listes de critères du
    couplage, niveaux max des plafonds — aucune grille ne les a jamais déclarés (ce sont des
    réglages de déploiement, pas d'échelle) ; ils ne rendent donc pas une grille partielle. Si le
    propriétaire veut aussi les exiger, aucune grille n'est vérifiable : à trancher avant d'étendre.
    **Validé par le propriétaire le 2026-10-03.** ⚠️ **Limite assumée** : pour v6 → v15, la
    cohérence est vérifiée avec les paramètres versionnés de la grille **et** ces réglages actuels
    jamais historisés. Ce n'est donc **pas** une reproduction certaine de tous les paramètres
    d'exécution historiques ; la fiche le dit sous le verdict de cohérence (`CalculBlock`).
  - Front : `CalculBlock` affiche le calcul avec le libellé servi et « Cohérence non vérifiable ».
- **Plus tard** : persister la configuration effective à l'évaluation (hors V1).

### DI-08 — Autorités de notation rendues appelables, comportement inchangé
- **Décision** : extraits/publics dans `AiEvaluationService` : `weightedNote`, `notesParCode`,
  `plafondCouplage` + `noteRamenee` (corps de `applyCouplage`), `plafondsDeclenches` +
  `PlafondDeclenche` (conditions de `applyPlafonds`), `plafonner`, `PLAFOND_NIVEAU_KEY` ;
  `ProductionBilanService.computeNiveau` / `competence` / `niveauFromCompetence` publics ;
  `LikePattern` public.
- **Pourquoi** : le calcul admin appelle les fonctions qui notent le candidat, jamais une copie.
- **Change** : aucun changement de note, niveau ou avertissement (tests `AiEvaluationService*Test` verts).

### DI-09 — Contenu du bloc « Calcul »
- **Décision** : `noteRecalculee` (Σ note × poids de la grille), `competence` (moyenne des porteurs),
  `niveauAvantPlafonds`, plafonds dont la condition est remplie sur les scores retenus,
  `niveauRecalcule`, `plafondPersiste` (`feedback_json.plafond_niveau`), `niveauPersiste`,
  `coherent` (relu = persisté, `null` si l'un manque). Couplage : plafond relu et
  `criteresAuPlafond` = critères de réalisation **exactement** au plafond (« possiblement
  ramenés » : la note d'origine n'est pas conservée, F-4 A). Libellés `formuleNote` / `regleNiveau` servis.
- **Pourquoi** : répondre à « pourquoi B1 et pas A2/B2 » à partir des scores affichés (critère n° 6).
- **Change** : le niveau affiché reste toujours `ai_evaluations.niveau_cecrl` ; un écart est montré, jamais corrigé.

### DI-10 — `calcul` jamais nul, cinq statuts
- **Décision** : `statut = CALCULE | CALCUL_PARTIEL | REGLE_NON_TRACABLE | NON_EVALUABLE | SANS_EVALUATION` (`CALCUL_PARTIEL` : DI-07) + libellé
  servi. `REGLE_NON_TRACABLE` couvre `rubrics_version` NULL **et** grille non livrée ; seuls les
  versions et `niveauPersiste` / `notePersistee` sont alors servis.
- **Pourquoi** : F-5 A (« indicateur règle historique non traçable ») ; un front n'a qu'un champ à lire.

### DI-11 — `vueCandidat` = le mapper candidat, `planChange` nul
- **Décision** : `ProductionSubmissionMapper.toDto` tel quel (même source que l'endpoint candidat,
  vérifié par égalité JSON du bloc `evaluation` dans l'IT). `planChange` reste nul.
- **Pourquoi** : `planChange` est résolu par le service candidat en lisant le Plan — pas une
  lecture passive, et ce n'est pas un feedback de notation.
- **Plus tard** : servir `planChange` via une lecture sans effet de bord si l'admin en a besoin.

### DI-12 — Pas de titre de repli servi
- **Décision** : `sujet.titre` est servi nullable, sans « Sujet N ».
- **Pourquoi** : le N du repli candidat est un rang dans une liste d'écran ; il n'a pas de sens sur une fiche admin.
- **Change** : le front affiche « Sans titre » (ou la consigne) quand `titre` est nul.

### DI-13 — Contexte de passation servi
- **Décision** : `contexte = EXAMEN_COMPLET` (parent d'attempt) | `EXAMEN_BLANC` (slot) |
  `ENTRAINEMENT`, + libellé ; même prédicat que `ProductionAccessService.isExamSession`, ventilé.
  `source = ASYNC | REALTIME` servi à part.
- **Pourquoi** : audit A.3 / G-6 ; `attempts.type` ne distingue rien.

### DI-14 — Informations techniques : uniquement ce qui existe
- **Décision** : modèle, `promptVersion`, `rubricsVersion`, tokens (in / cache / out — cumul non
  ventilable), `coutMicroUsd` (USD × 10⁻⁶), `coutLegacyCentimesEuro` (colonne legacy mappée en
  **lecture seule** sur `AiEvaluation`, jamais additionnée), `submittedAt`, `evaluatedAt`,
  `delaiSoumissionEvaluationSec`, `relancesManuelles` (`retry_count`), `erreurMessage`. Pas de
  champ `provider` ni `nbRetries` (jamais écrit), ni durée d'appel.
- **Pourquoi** : « n'expose pas de champ qui n'existe pas » ; unités réelles.

### DI-15 — Métadonnées de transcription sans texte
- **Décision** : `TranscriptionManager.findLatestMetaBySubmissionId` rend outil, langue, durée,
  coût, qualité (Whisper + nos taux) **sans le texte** ; le texte sort toujours recollé par
  `findLatestTexteBySubmissionId`. Réponse : `audioConserve: false` + `audioMotif` servi en EO.
- **Pourquoi** : garder l'invariant « le texte cité est le texte affiché » ; aucun audio n'existe.

### DI-16 — Recherche : UUID complet uniquement
- **Décision** : `q` au format UUID ⇒ égalité sur l'id de production **ou** l'id utilisateur ;
  sinon email « contient » (sans casse, jokers échappés via `LikePattern`). Pas de préfixe d'id.
- **Pourquoi** : convention des consoles Utilisateurs/Abonnements (audit A.1).
- **Plus tard** : préfixe de 8 caractères (affichage de la maquette) si le besoin se confirme.

### DI-17 — Période : `periode` ou `from`/`to`, via `FenetreMesure`
- **Décision** : `periode=TODAY|LAST_7_DAYS|LAST_30_DAYS` (jours Europe/Paris glissants, aujourd'hui
  inclus) **ou** `from`/`to` inclus (deux bornes, 365 j max) ; les deux ensemble ⇒ 400. Aucune
  période ⇒ pas de borne.
- **Pourquoi** : `FenetreMesure` est l'autorité des fenêtres admin (Suivi).

### DI-18 — Comptes internes : `users.is_internal`, exclus par défaut
- **Décision** : `includeInternal=false` par défaut, même paramètre et même colonne que le Suivi (V074).
- **Pourquoi** : F-7 A, aucune nouvelle source.

### DI-19 — Valeurs de filtres
- **Décision** : `epreuve` en `EpreuveType` (`TCF_EE`/`TCF_EO`, autre ⇒ 400) ; `tache` 1-3 ;
  `niveau = A1_NON_ATTEINT|A1|A2|B1|B2|SANS_NIVEAU` (C1/C2 jamais produits, non exposés) ;
  tri `EPREUVE` = épreuve, puis tâche, puis plus récente. Lignes sans niveau toujours en dernier.
- **Pourquoi** : valeurs réellement supportées ; `null` ≠ A1.

### DI-20 — Lecture passive : par construction et par test
- **Décision** : services `@Transactional(readOnly = true)` dans `service/adminproduction/`, qui
  n'appellent que des managers, mappers et fonctions pures. Testé : 0 insertion / mise à jour /
  suppression Hibernate et `updated_at` inchangé après liste + fiche (`AdminProductionControllerIT`),
  et aucune dépendance de type client LLM / runner / pipeline / service candidat
  (`AdminProductionCalculServiceTest`).
- **Plus tard** : rien.

### DI-21 — `signalable` servi dans la fiche
- **Décision** : `signalable = évaluation présente ET aucun signalement actif`.
- **Pourquoi** : le front n'a pas à recombiner statut + historique pour afficher le bouton.

---

## Pour le front admin (à migrer)

- **Calibration** : retirer `calibrationApi.submissions`, le type `CalibrationSubmissionDto`, les
  deux requêtes `["calibration","submissions",…]` et les onglets « à annoter / annotées » de
  `CalibrationPage` (la page garde `CalibrationHealth` : `/stats` et `/stats/niveau`).
  L'annotation (`HumanNoteForm`, `GET|POST /api/admin/calibration/submissions/{id}/human-note`)
  s'ouvre depuis la fiche Productions IA. « À annoter » = `GET /api/admin/productions?annotation=NON_ANNOTEES&statut=EVALUEE`.
- Nouveaux types miroirs dans `admin_sejourfr/src/types/api.ts` (contrat : `docs/api-endpoints.md`
  § « Admin — Productions IA »). Aucun type web/mobile ne change.

---

## Front admin (lot 2 + partie front du lot 3) — 2026-10-03

Vérification : `npx tsc --noEmit`, `npm run build`, `npm run lint` (aucune erreur dans les
fichiers touchés ; les erreurs restantes sont antérieures). Aucun test front ajouté (aucun
n'existait dans `admin_sejourfr/`). Aucun bug backend bloquant rencontré : backend inchangé.

### DI-22 — Routes `/productions-ia` et `/productions-ia/:id`, entrée « Génération IA »
- **Décision** : feature `features/productions/`, entrée de nav « Productions IA » juste avant
  « Calibration notation » (F-8), icône `sparkles` ajoutée au jeu local, `detailLabel: "Production"`
  pour le fil d'Ariane.
- **Pourquoi** : chemin parlant et distinct de `/production-titles` (titres des sujets).
- **Change** : deux routes dans `App.tsx`, une entrée dans `navigation.ts`.
- **Plus tard** : renommer le chemin ne demande qu'un remplacement (aucun lien externe connu).

### DI-23 — `useUrlListState(defaultSize)` + `setFilters` multi-clés
- **Décision** : le hook partagé accepte une taille par défaut par écran (50 ici, F-9 ; 25 reste
  le défaut des autres) et un `setFilters(patch)` qui écrit plusieurs clés et ramène en page 1
  dans la même écriture d'URL. `setFilter` en devient un cas particulier.
- **Pourquoi** : passer de « 7 jours » à « Personnalisée » doit retirer `periode` et poser
  `from`/`to` d'un coup — deux écritures successives enverraient une requête invalide (400).
- **Change** : `useProductionListParams` ; aucun changement de comportement pour Utilisateurs /
  Abonnements.

### DI-24 — Période : `periode` OU `from`+`to`, jamais complétée
- **Décision** : « Personnalisée » pose `from = to = aujourd'hui (Paris)` ; une plage illisible
  ou inversée dans l'URL est ignorée (aucun filtre de période), jamais corrigée ni complétée.
  Le contrôle de la borne > 365 j reste serveur (400 affiché en bandeau d'erreur).
  `parisToday()` remonté de `features/suivi/dates.ts` vers `lib/dates.ts` (2ᵉ usage).
- **Pourquoi** : même mécanique que le Suivi ; une seule notion d'« aujourd'hui ».

### DI-25 — Filtres en sélecteurs libellés, libellés des valeurs de filtre locaux
- **Décision** : 8 sélecteurs `Select` (primitive `Form`) en grille responsive (Épreuve, Tâche,
  Niveau observé, Statut IA, Signalement, Annotation humaine, Période, Trier par) + case
  « Inclure les comptes internes » ; pas les pastilles-select de la maquette. « Signalées » est
  libellé « Signalées (à vérifier) » (DI-03 : n'inclut pas les vérifiées). Les libellés des
  VALEURS DE FILTRE sont locaux (`productionLabels.ts`) — rien ne les sert — ; tout ce qui
  qualifie une production affichée (statut, contexte, signalement) reste le libellé servi.
- **Pourquoi** : réutiliser la primitive existante (même forme qu'Abonnements) plutôt qu'un
  nouveau composant ; 8 filtres en `Chips` seraient illisibles à 360 px.
- **Plus tard** : un composant `PillSelect` partagé si le style maquette est voulu partout.

### DI-26 — Colonnes : celles du brief, le reste en sous-ligne
- **Décision** : Date · Candidat · Épreuve (EE/EO) · Tâche · Niveau observé · Statut IA ·
  Signalement. Sous-lignes : heure + 8 premiers caractères de l'id ; id utilisateur court ;
  « Compte interne » ; « Temps réel » sous EO ; contexte servi sous la tâche ; « Annotée » sous
  le statut. Niveau absent = « — » (jamais A1). Repli carte < 720 px (`cardTable`).
- **Pourquoi** : « simple » d'abord ; Mode et Contexte (suggérés par l'audit) sans colonnes en plus.

### DI-27 — Mutualisation et suppression de l'ancien (F-1)
- **Décision** : les helpers de lecture d'une évaluation (libellés niveau / confiance / bande /
  critère, `isNonEvaluable`, `isLegacyEvaluation`, transcription en tours, formats) passent de
  `calibrationHelpers.ts` à `lib/evaluation.ts` ; `calibrationHelpers.ts` ne garde que la
  lecture de santé (biais, dispersion, écart). `EvaluationReport` est **déplacé** en
  `productions/components/CandidateFeedback` ; `ProductionView` (remplacé par `ReponseBlock`,
  même rendu des tours examinateur/candidat) et `SubmissionDetailModal` sont **supprimés**, ainsi
  que `calibrationApi.submissions`, `CalibrationSubmissionDto`, les onglets « à annoter /
  annotées », et `productionTasksApi.list` + `ProductionTaskDto` (route candidat
  `/api/production-tasks`, qui n'avait plus d'appelant). Polices en dur des CSS repris → tokens.
- **Pourquoi** : refonte = suppression immédiate ; 2ᵉ usage ⇒ `lib/`.

### DI-28 — « Feedback candidat » rendu depuis `vueCandidat`, sans doublon
- **Décision** : `CandidateFeedback` rend `vueCandidat.evaluation` : niveau observé (tâche) tel
  que servi au candidat (« Non montré au candidat » s'il est nul), position dans le niveau,
  confiance et raisons, avertissement de niveau, accomplissement, points forts / à améliorer
  (+ blocs legacy). La note /20 n'y figure pas (le candidat ne la voit pas sur une tâche) et le
  détail par critère n'est pas répété : ce sont les mêmes `scores_criteres` que le bloc
  « Évaluation IA » (le mapper candidat ne retire que `niveau_cecrl` et `justification_niveau`).
- **Pourquoi** : « pas de surcharge » ; montrer ce que le candidat a vu sans le réécrire.
- **Plus tard** : réafficher les critères dans ce bloc si l'on veut une copie d'écran fidèle.

### DI-29 — Annotation ouverte depuis la fiche, Calibration recentrée
- **Décision** : `calibration/components/HumanNoteModal` (stats pour le seuil + dernière note +
  `HumanNoteForm`) s'ouvre par « Annoter (calibration) » / « Revoir l'annotation » sur une fiche
  au statut `EVALUEE` (rien à annoter sinon). Enregistrer invalide `["calibration"]` et
  `["adminProductions"]` (drapeau `annotee`). `CalibrationPage` = bandeau de santé + deux liens
  `/productions-ia?annotation=NON_ANNOTEES&statut=EVALUEE` et `?annotation=ANNOTEES`.
- **Pourquoi** : F-1 — Calibration garde la santé et l'annotation, Productions IA la liste.

### DI-30 — Calcul SejourFR : bloc distinct, écart IA ⇄ retenu dedans
- **Décision** : bloc à liseré bleu sur fond `--surface-2` (séparé de l'évaluation IA). En tête,
  le niveau ENREGISTRÉ + pastille de cohérence servie (`coherent` vrai / faux / non vérifiable),
  versions de grille et de schéma ; puis notes recalculée / enregistrée, compétence, porteurs,
  seuils + leur origine, niveaux avant plafonds / recalculé, formule et règle (textes servis),
  plafonds déclenchés + plafond enregistré, couplage. Hors `CALCULE` : le `statutLabel` servi
  et, pour `REGLE_NON_TRACABLE`, niveau / note enregistrés et versions — rien d'autre (F-5).
  « Niveau IA vs retenu » ferme le bloc (masqué pour un non évaluable), écart en crans servi.
  Les critères exactement au plafond de couplage portent « Possiblement ramené » dans
  l'évaluation IA (sans l'affirmer, F-4).
- **Plus tard** : passer l'écart dans un bloc à part si le propriétaire le veut plus visible.

### DI-31 — Informations techniques : unités réelles, rien de converti
- **Décision** : « Fournisseur : non enregistré » (le champ n'existe pas) ; coût `coutMicroUsd`
  formaté en dollars (2 à 6 décimales) ; coût legacy en € sur une ligne séparée, jamais additionné ;
  délai soumission → évaluation (avec la mention « pas une durée d'appel ») ; relances manuelles ;
  erreur en encadré. Les indicateurs de transcription (parts) et le poids d'un critère
  (« poids × 0,25 ») sont affichés tels que servis, sans conversion en pourcentage.
- **Pourquoi** : rien d'inventé, aucune unité supposée.

### DI-32 — Signalement : motifs locaux, un bandeau, historique en fin de fiche
- **Décision** : la modale (primitive `Modal`) propose les 6 motifs en pastilles radio — liste
  locale, miroir de `MotifSignalement` (aucun endpoint ne les sert) — puis affiche le
  `motifLabel` servi. Motif obligatoire, commentaire ≤ 1000 (compteur). 409 ⇒ « déjà actif,
  rechargez », 422 ⇒ « aucune évaluation ». Le signalement actif (au plus un) s'affiche en
  bandeau sous le contexte (date, admin, motif, commentaire ; « Marquer vérifié » si non vérifié,
  « Retirer ») ; l'historique complet, retirés compris, ferme la fiche. Les actions n'ont pas de
  confirmation (idempotentes, retrait soft). Chaque mutation invalide `["adminProductions"]`.
- **Plus tard** : une confirmation avant « Retirer » si des retraits accidentels apparaissent.

### DI-33 — Primitive `Collapsible`, icônes ajoutées
- **Décision** : `components/ui/Collapsible` (carte repliable sur `<details>` natif, fermée par
  défaut) pour « Informations techniques » et « JSON persisté après traitement serveur » (rendu
  `JSON.stringify(…, 2)`, lecture seule). Icônes `sparkles`, `flag`, `chevronDown` ajoutées au jeu.
- **Pourquoi** : aucune primitive n'existait (audit) ; `<details>` donne clavier et lecteur d'écran.

### Écarts assumés vs maquette v3
Sélecteurs libellés au lieu de pastilles-select ; pas de bouton « Actualiser » en topbar ;
bouton « Signaler » en contour rouge (`danger`, pas de variante ambre dans `Button`) ; scores
« x / 20 » sans pastilles ; pas de « résumé » de feedback (le champ n'existe pas) ; hors maquette
mais demandés : filtre annotation, case comptes internes, historique des signalements, accès à
l'annotation.
