# QCM — niveau, score et ordre des propositions

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Contenu verbatim, aucune réécriture.**
> Origine : lignes 3039-3176 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier porte la loi de ce sous-système : on l'ouvre **quand on travaille dedans**.
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

## Niveau QCM — plancher A1 dès UNE bonne réponse (2026-08-17)

Sur les trois épreuves QCM (**CO**, **CE**, **STRUCTURE**), `A1_NON_ATTEINT` est
réservé au candidat qui a **zéro** bonne réponse. Dès qu'il en a **au moins une**,
le niveau rendu est au minimum **A1**. Décision produit du propriétaire.

- **La table officielle et la formule calibrée ne bougent pas d'un octet.**
  `BandeNoteTcf` reste en code (donnée officielle, pas réglage), les bandes du
  score calibré (≥400 B2 · ≥300 B1 · ≥200 A2 · ≥101 A1 · sinon A1 non atteint) et
  la correction du hasard à 25 % de `TcfLevelEstimatorService` sont **inchangées
  et gelées par test** (frontières 43/44, 62/63, 81/82 ; valeurs 100 / 233 / 499).
  Le score affiché ne bouge pas non plus : une seule bonne réponse reste
  **100/499**, seul le niveau change. Motif de la règle : sous ~25 % pondéré la
  correction du hasard ramène **tout** à la borne basse, donc 1, 6 ou 12 bonnes
  réponses rendaient le même « A1 non atteint ».
- **Autorité unique : `TcfLevelEstimatorService.plancherA1SiUneBonneReponse`**,
  posée **par-dessus** la bande, appelée par les deux entrées (`estimateQcm`,
  `levelFromWeighted`) et par le repli legacy de `FullTcfExamResponseBuilder`.
  Jamais recopiée : `AttemptScoringService`, `AttemptMapper`, `TcfProfileService`
  et le builder d'examen complet en héritent sans une ligne de règle. Trivial à
  retirer — trois appels et une méthode.
- ⚠️ **Ce garde-fou RELÈVE**, à l'inverse de tous les autres du dépôt
  (`applyCouplage`, `applyPlafonds`, `applyConfiance`,
  `CompetenceLevelEvidenceGuard`, `CoherenceBilan`), qui ne peuvent qu'**abaisser**.
  **L'asymétrie est VOULUE — ne pas la « corriger ».** Elle est sûre parce
  qu'elle est bornée : elle ne relève que **depuis** `A1_NON_ATTEINT` et
  seulement d'**un cran**, vers `A1` ; aucun seuil de bande ne peut être franchi.
- **« Aucune bonne réponse » englobe « aucune réponse donnée »** : un candidat
  qui n'a rien répondu a bien zéro bonne réponse et reste `A1_NON_ATTEINT`. À ne
  pas confondre avec « pas de donnée », qui reste `null` en amont (*null =
  inconnu, jamais mauvais*) et que le plancher ne touche pas non plus. Dans
  `levelFromWeighted`, faute du nombre de bonnes réponses, le signal est
  `weighted > 0` — équivalence stricte sur un examen stratifié, où toute question
  porte une strate A2/B1/B2 donc un poids ≥ 1.
- 🛑 **Les exclusions du plancher d'examen complet sont INTACTES** : une épreuve
  `locked` (freemium), une épreuve à `cecrlLevel` null, et une épreuve **jamais
  ouverte** (`timer_started_at` NULL **et** rien de rendu, règle du 2026-08-15)
  restent hors de `floorOfCecrls`. Aucune n'est « rachetée » à A1 : elles n'ont
  pas de bonne réponse à compter, elles n'ont pas de niveau. En revanche une
  épreuve **ouverte puis abandonnée** reste comptée — 0 bonne réponse ⇒
  `A1_NON_ATTEINT`, comportement voulu. Relever une épreuve QCM peut donc
  relever `finalCecrlLevel` : c'est attendu.
- 🛑 **Aucune migration, aucun recalcul rétroactif** des `attempts.cecrl_level`
  déjà persistés — c'est l'historique. Volume mesuré au moment de la bascule :
  **18 lignes CO/CE/STRUCTURE sur 4 comptes** (13 CO, 4 CE, 1 TCF_CO) auraient
  changé, soit 37,5 % des lignes `A1_NON_ATTEINT` ; 0 sur le repli de lecture.
- ⚠️ **`FullTcfExamResponseBuilder.weightedScoreToCecrl` est une SECONDE table,
  volontairement divergente** (ratio brut 80/60/40/20 %, sans correction du
  hasard) : repli des sous-attempts antérieurs à V416 dont `cecrl_level` est
  NULL. Elle n'est **pas** fusionnée avec l'estimateur — la faire déléguer
  changerait rétroactivement le niveau affiché sur cet historique. Seul le
  **plancher** s'y applique, via l'autorité unique, jamais une copie locale.
- Les 3 fronts n'ont rien à changer : aucun ne dérive un niveau CECRL depuis un
  score ou un nombre de bonnes réponses (vérifié). Le niveau est **calculé
  serveur** et lu tel quel.

## Ordre des propositions QCM et lettres citées dans les explications (2026-08-19)

Les propositions d'une question sont **mélangées** à l'affichage (shuffle
déterministe, graine dérivée de l'`AttemptQuestion`, `QuestionMapper.ordreAffiche`)
pour supprimer le biais de position. Mais les explications sont rédigées sur
l'ordre `display_order` de la base et **citent des lettres** (« Seule B… », « A
indique une durée »). Les deux n'étaient jamais réconciliés : l'explication
désignait des lettres qui ne correspondaient plus à l'écran, sur **439 questions
actives** (CE 395, CO 20, STRUCTURE 24 — le civique n'utilise aucune lettre).

- **Le contenu en base est JUSTE, c'est l'affichage qui décalait.** Ne jamais
  « corriger » une explication ni réordonner un `display_order` pour rattraper ce
  bug : mesuré sur les 20 CO, les 20/20 explications et les 80/80 choix sont
  cohérents avec l'ordre stocké.
- **Autorité unique : `util/ReferenceChoixLettre`.** Elle remappe les lettres
  citées avec **exactement** la permutation appliquée aux propositions
  (`QuestionMapper.permutation`), remplacement **simultané** jamais séquentiel.
  Tout point qui sert une explication à côté de propositions mélangées passe par
  elle — `toPublic`, `toReview`, et `AttemptInteractionService` (correction
  immédiate TRAINING, qui couvre aussi la démo invitée). Une seconde copie
  désignerait deux lettres différentes pour le même choix.
- **Repérage : tout ou rien.** Une seule occurrence indécidable ⇒ le texte entier
  est rendu **intact** (un remappage partiel ferait désigner deux propositions par
  la même lettre). Validé sur les 2 339 explications réelles : 0 abstention, 0 faux
  positif. Sont **ignorés** exprès — paliers CECRL `A1/A2/B1/B2` (l'explication
  type contient « Piège **B1** »), verbe *avoir* capitalisé entre guillemets
  (« A été », 33 cas STRUCTURE), noms de lieu (`bâtiment B`, `permis B`,
  `escalier C`, 24 cas), `C'est` / `D-Day` / `J.-C.`. Une rédaction future
  inattendue tombe en abstention, donc au pire dans l'état d'avant.
- **`toReview` est aligné sur l'ordre du runner** (même graine que
  `toPublic(q, false, q.getId())`). Avant, le même attempt s'affichait dans deux
  ordres différents entre l'entraînement et la revue. `ChoiceReviewResponse
  .displayOrder` porte l'index **d'affichage** : exposer celui de la base
  permettrait de défaire le mélange.
- 🛑 **Une question dont l'AUDIO ÉNONCE les propositions n'est JAMAIS mélangée.**
  `AudioMode.WRITTEN_QUESTION_SPOKEN_CHOICES` (V037 + backfill **V590**) qualifie
  les 20 CO dont la bande dit « A. … B. … » pendant que l'écran affiche aussi le
  texte : elles échappaient à `choicesAreReadAloud` (qui ne détectait que les
  labels réduits à une lettre), donc l'audio annonçait d'autres lettres que
  l'écran — un candidat qui retenait « c'est B » et cliquait B **se trompait
  alors qu'il avait compris**. Ce mode **constate un défaut, il ne se génère
  pas** : `AudioQuestionGenerationService.refuseModeNonGenerable` le refuse avant
  tout appel payant.
  ⚠️ **Dette de contenu assumée** : sur ces 20, la bonne réponse est en A dans
  **13 cas sur 20** (65 %), contre 27 % sur les 610 autres CO, qui restent
  équilibrées. Le mélange avait été ajouté (`ae785f5`) pour ce biais et l'avait
  payé en désynchronisant l'audio. Débiaiser suppose de **régénérer l'audio sans
  les lettres** — bloqué faute d'abonnement Azure Speech. Ne pas « réparer » en
  remélangeant.
- ⚠️ **Piège Flyway** : un backfill de contenu **seedé** se numérote **après ses
  lots**, jamais dans `00_schema`. Flyway ordonne par **numéro**, pas par dossier :
  un `UPDATE` en V0xx passe avant les `INSERT` des questions CO (V500/V530/V560) et
  touche **zéro ligne**.
- **L'ordre servi fait foi — les fronts ne retrient plus rien** (2026-08-19).
  `QuestionMapper.ordreReference` garantit qu'une question à **repères
  alphabétiques** (libellés tous réduits à `A`..`D` / `Réponse A`.., sur un type
  CO ou CO_IMAGE — le contenu vit alors dans l'audio) est servie **dans l'ordre de
  ses lettres**, quel que soit le `display_order` saisi en console, et n'est
  **jamais mélangée** : brasser des lettres ne supprime aucun biais de position et
  ne ferait que décorréler la pastille du libellé. L'explication n'y est donc
  **pas remappée** — l'ordre de référence étant déjà celui des lettres, la
  permutation est identité **par construction**, pas par cas particulier. Le
  garde-fou de **type** est celui que le mobile appliquait déjà : sans lui, une
  STRUCTURE dont les réponses seraient « a »/« d » cesserait d'être mélangée.
- Les fronts dérivent la pastille A/B/C/D de **l'index dans la liste reçue** (web
  `QuestionRunner.tsx`, mobile `choice_tile.dart`) et **plus aucun ne trie** :
  `orderedChoices` (web `lib/types.ts`, qui s'appliquait à **tout** type de
  question) et `orderedDisplayChoices` (mobile, aux seules CO/CO_IMAGE) sont
  **supprimés**, appelants compris — runner, rapport d'examen, modale de détail,
  feuille de détail. Deux rustines d'affichage aux règles **divergentes** pouvaient
  défaire l'ordre servi ; la divergence est maintenant structurellement impossible
  au lieu d'être surveillée. `audioMode`, déclaré sur `QuestionPublicResponse` /
  `QuestionReviewResponse` du miroir **web** alors que le backend ne le sert pas,
  est retiré — avec le type `AudioMode` du web, qui n'avait plus de lecteur. Celui
  de l'admin sert la console des drafts audio et **reste**.
- ⚠️ **La garantie est un FILET, pas une correction de données** : mesuré sur la
  base locale, les **610** questions à repères alphabétiques (540 CO + 70
  CO_IMAGE, seuls types concernés) ont déjà un `display_order` alphabétique,
  1-based et consécutif — **0 question réordonnée**. D'où **aucune migration** de
  normalisation : elle toucherait zéro ligne, et le dépôt interdit par ailleurs de
  réordonner un `display_order` pour rattraper un défaut d'affichage.
