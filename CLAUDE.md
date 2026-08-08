# SejourFR — Guide racine pour Claude Code

Monorepo (4 dossiers indépendants, pas de workspace npm/Maven parent) de **SejourFR**,
plateforme d'entraînement aux examens **civique** (CSP, CR, naturalisation) et **TCF IRN**
(A2/B1/B2), obligatoires depuis le **1ᵉʳ janvier 2026**.

> Avant de coder sur un sous-projet, **toujours lire son `CLAUDE.md` local** : les
> conventions précises (state management, styling, runner, etc.) y vivent. Ce fichier-ci est
> un index transverse, pas un substitut.

## Les 4 sous-projets

| Dossier              | Stack                                                                       | Rôle                                                       | Port dev    |
|----------------------|-----------------------------------------------------------------------------|------------------------------------------------------------|-------------|
| `backend_sejourfr/`  | Spring Boot 4 / Java 21 / PostgreSQL / Flyway / JWT                         | API REST unique pour les 3 fronts                          | 8080        |
| `admin_sejourfr/`    | React 19 + Vite + TS strict + TanStack Query + React Router 7 + CSS Modules | Console admin                                              | 5173 (Vite) |
| `web_sejoufr/` ⚠️    | Next.js 16 App Router + React 19 + Tailwind v4 (tokens seuls)               | Vitrine + parcours user + paiement Stripe + démo gratuite  | 3000        |
| `mobile_sejourfr/`   | Flutter 3.6+ / Dart 3.6+ / Riverpod 2 + Dio + go_router                     | App d'entraînement quotidien (cœur produit)                | —           |

⚠️ Le dossier web est `web_sejoufr` (typo : *sejoufr*, pas *sejourfr*).

**Stratégie business** : le web pousse à l'abonnement (paiement Stripe **hors stores** pour
éviter la commission Apple/Google), puis l'utilisateur s'entraîne principalement sur le
mobile. Web : 1 examen blanc + 10 QCM d'entraînement par module pour convertir.

## Domaine métier (vocabulaire)

- **Module** : `CIVIQUE` ou `TCF`
- **TargetProcedure** (civique) : `CSP` / `CR` / `NAT`
- **TargetLevel** (TCF) : `A2` / `B1` / `B2`
- **AttemptType** : `TRAINING` (correction immédiate) / `MOCK_EXAM` (examen blanc, chrono,
  pas de correction live) / `REVIEW`
- **Epreuve** (granularité fine, orthogonale à `mode`/`module`) : `CIVIQUE` / `TCF_CO` /
  `TCF_CE` / `TCF_STRUCTURE` / `TCF_EO` / `TCF_EE` / `TCF_COMPLET`. `TCF_COMPLET` est un
  conteneur d'examen blanc TCF ; sous-attempts liés via `attempts.parent_attempt_id`.
- **QuestionType** : `CONNAISSANCE` / `MISE_SITUATION` (civique) · `CO` / `CO_IMAGE` / `CE` /
  `STRUCTURE` (TCF). `CO_IMAGE` = format de Compréhension orale « image + 4 propositions
  lues » : `media_id` porte l'image, `audio_media_id` l'audio, choix en lettres A/B/C/D.
  Tiré dans les mêmes pools que `CO` (un filtre `CO` inclut `CO_IMAGE`). Publié depuis un
  `audio_question_draft` portant une image (`inline_svg` ou `image_url`). Image
  remplaçable côté admin via `POST /api/admin/{questions,audio-drafts}/{id}/image` (R2).
- **Difficulty** (questions QCM) : `CSP` / `CR` / `NAT` / `A2` / `B1` / `B2` — c'est l'axe
  « procédure visée **ou** palier CECRL », **pas** une échelle facile/moyen/difficile. Ne pas y
  ajouter `EASY/MEDIUM/HARD` : l'enum irrigue tous les DTO de questions, d'examens et de lots,
  donc les 3 fronts (cf. `SkillDifficulty` ci-dessous, qui existe pour cette raison).
- **MediaType** : `AUDIO` / `IMAGE` / `VIDEO`
- **NiveauCecrl** (eval IA EO/EE) : `A1_NON_ATTEINT` / `A1` / `A2` / `B1` / `B2` / `C1` /
  `C2`. Distinct de `TargetLevel` (palier visé par l'utilisateur).
- **SubmissionStatut** (EO/EE) : `SUBMITTED` → `TRANSCRIBING` (EO) → `EVALUATING` →
  `EVALUATED` | `FAILED`.
- **Compétences TCF** (module de micro-entraînement EE/EO, voie parallèle aux productions
  complètes — cf. la section dédiée plus bas) :
  - **SkillSection** : `EE` / `EO`
  - **SkillTaskCode** : `EE1` / `EE2` / `EE3` / `EO1` / `EO2` / `EO3`. Référentiel officiel
    porté par l'**enum** (section, numéro de tâche, titre, palier cible), **pas** par une table.
  - **SkillDifficulty** : `EASY` / `MEDIUM` / `HARD` (libellés FR *Accessible / Intermédiaire /
    Exigeant*). Difficulté d'un sujet **à l'intérieur de sa compétence**, purement éditoriale :
    aucune règle serveur ne s'y appuie et l'IA ne la reçoit pas. Enum **distinct** de
    `Difficulty`, qui ne contient pas ces valeurs.
  - **SkillReferenceLevel** : `INSUFFICIENT` / `EXPECTED` / `EXCELLENT` — les 3 références
    comparatives d'un sujet, servies **seulement après** une production (403 sinon).
  - **SkillSelfEvaluation** : `REUSSI` / `INCERTAIN` / `DIFFICILE` (« Je pense avoir réussi » /
    « Je ne suis pas sûr » / « J'ai eu du mal »). Déclarative, facultative, **jamais** envoyée
    au correcteur et sans effet sur le verdict.
  - **SkillCriterionStatus** : `VALIDATED` / `PARTIAL` / `NOT_VALIDATED` (« Critère validé » /
    « Critère partiellement atteint » / « **Critère non atteint** ») — le verdict IA sur le
    **critère unique** du sujet. C'est tout ce que rend cette voie : **ni note /20, ni niveau
    CECRL**. `NOT_VALIDATED` ne se dit **pas** « à retravailler » : cette formulation était
    quasi synonyme du statut de sujet `TO_REINFORCE` et confondait le verdict d'**une
    tentative** avec l'état d'**un sujet**.
  - **SkillPromptStatus** : `TODO` / `TREATED` / `VALIDATED` / `TO_REINFORCE` (« À faire » /
    « Fait » / « Validé » / « À renforcer »). **Dérivé serveur** (`SkillStatusResolver`),
    jamais persisté, jamais recalculé par un front.
  - **SkillAttemptStatut** : `RECORDED` (rendu sans analyse — état **final**) · `SUBMITTED` →
    `TRANSCRIBING` (EO) → `EVALUATING` → `EVALUATED` | `FAILED`.
- **Role** : `USER` / `ADMIN`
- **AuthProvider** (exposé dans `/api/auth/me`) : `LOCAL` / `GOOGLE` / `APPLE`. Sur iOS,
  **Google ET Apple côte à côte** (Apple obligatoire d'après les guidelines App Store dès
  qu'un autre social sign-in est proposé). Champ immutable.

Le backend est la **source de vérité** des DTOs. Les 3 fronts maintiennent leurs miroirs
**à la main** :

- `admin_sejourfr/src/types/api.ts`
- `web_sejoufr/lib/types.ts`
- `mobile_sejourfr/lib/core/models/*.dart`

→ Quand un DTO Java change, mettre à jour les 3.

## Freemium (validé 2026-06-06, source backend)

- **Guest (web)** : navigation libre des hubs ; **série 1** offerte par thème
  civique / (épreuve TCF × niveau) et **examen diagnostic complet 1** par
  module (templates free de /examens-blancs), joués en anonyme (attempt
  `user NULL` + `clientIp` — sert d'analytics « combien se testent »). Tirages
  guests déterministes. Série 2+/examen 2+ → inscription. `GET /api/public/lots`
  + `POST /api/public/attempts/demo` (TRAINING lotNumero=1 ou MOCK_EXAM
  template free). **Examens ciblés** (thème civique / épreuve TCF) et EE/EO :
  compte obligatoire — le backend renvoie 403 sur un MOCK_EXAM guest avec
  themeId ou moduleExamQuestionType ; côté web les pages `*/examens` restent
  des vitrines (grille visible, tout verrouillé → GuestGateSheet).
- **Compte gratuit, EE/EO** : 1 essai d'entraînement par épreuve à vie + 1
  examen blanc production offert. L'examen est marqué `attempts.slot_number=1`
  au start (`ProductionAttemptStartRequest.exam`) ; ses soumissions bypassent
  le quota d'entraînement. Refaire l'examen 1 = toléré une fois mais consomme
  les essais d'entraînement restants ; une session ne compte que si ≥ 1 tâche
  soumise. Règles dans `ProductionAccessService` (quota, partagé avec la voie
  temps réel) / `AttemptService.startProductionAttempt`. Une **session d'examen
  production est bornée** : chrono d'épreuve (EE 30 min, EO 15 min = 600 s de
  parole + 50 % de marge) et **une seule soumission par (attempt, tacheNumero)**
  — un examen, c'est 3 tâches, une fois chacune. QCM entraînement : série 1
  gratuite, 2+ premium. **Tous les examens blancs QCM** (`MOCK_EXAM`) :
  **slot 1 offert ET rejouable à volonté** pour tout compte inscrit, slots 2+
  réservés aux abonnés **du module** (Civique → `hasCivique`, TCF → `hasTcf`).
  Vaut pour les examens module TCF (CO / CE / STRUCTURE via
  `moduleExamQuestionType`), les examens civiques globaux (40 Q) et les examens
  de thème (20 Q) — ces deux derniers passent par la branche « legacy » de
  `AttemptService.start`, qui **ne contrôlait rien avant le 2026-08-03** (verrou
  purement client). Verrou unique côté backend :
  `AttemptService.enforceMockExamSlotAccess`, basé sur le `slotNumber` (≠ EE/EO
  qui ont un freebie consommable), miroir des 3 fronts (web `ExamsGrid
  freeSlots=1`, mobile briefing + pages examens). Le `slotNumber` est validé
  **1..20** (`AttemptService.MOCK_EXAM_SLOTS`, aligné sur les grilles des
  fronts) et ne pilote pas la composition (questions tirées du même pool).
- **Compte gratuit, examen blanc TCF complet** (`/api/full-tcf-exams`,
  orchestré CO→CE→EE→EO) : **examen 1 offert** (slot 1, même grille que les
  abonnés) avec **EE + EO évaluées une seule fois à vie**. Au-delà, l'examen 1
  reste rejouable en compréhension (CO+CE) mais ses épreuves EE/EO sont
  **verrouillées** : `FullTcfExamService.start` les pré-termine (finishedAt +
  TERMINE → comptées `A1_NON_ATTEINT` au bilan) et pose
  `attempts.production_locked=true` (V015) sur le parent, exposé en
  `FullTcfExamResponse.SubAttempt.locked` (cadenas + invite abonnement côté
  fronts). Freebie consommé dès qu'une tâche EE/EO a été soumise dans un examen
  complet (`ProductionSubmissionManager.hasFullExamProductionSubmission`) —
  indépendant des freebies EE/EO standalone et des examens module CO/CE
  (le verrou `startModuleExam` ignore les sous-attempts d'un complet). Examens
  complets 2-20 → premium. `start` n'exige plus `hasTcf` ; soumettre vers une
  épreuve déjà terminée est refusé (`enforceQuota`).

### Gardes des soumissions EE/EO (`ProductionAccessService`)

Les **deux** voies de notation d'une production — asynchrone
(`ProductionEvaluationService.submitAndEvaluate`) et temps réel
(`evaluateRealtimeTranscript`, déclenchée par `RealtimeSessionService.finish`) —
passent par le **même** garde `ProductionAccessService.assertCanSubmit` :
propriété de l'attempt (IDOR), `finishedAt`, chrono d'épreuve (+ 60 s de grâce),
**correspondance `attempt.epreuve == task.epreuve`**, et plafond « une
soumission par tâche » en session d'examen. Le quota freemium
(`enforceQuota`) y vit aussi. `RealtimeSessionService.start` applique le même
garde **avant** de consommer un slot de simulation.

Invariants à ne pas casser :
- une tâche EO ne peut pas être notée dans une session EE (et inversement) —
  sinon l'auto-finalisation d'un examen complet clôt la mauvaise sous-épreuve
  avec un `cecrlLevel` faux, or c'est ce niveau qui fait foi ;
- « épreuve terminée ⇒ plus aucune soumission », y compris temps réel ;
- l'auto-finalisation compte les **tâches distinctes de l'épreuve**
  (`countDistinctTachesByAttemptAndEpreuve`), jamais les lignes brutes.

### ⏳ À gérer plus tard — garde-fou attempts guest (`user IS NULL`)

Aujourd'hui la table `attempts` croît normalement (1 ligne / série ou examen,
×5 pour un TCF complet ; tables filles `attempt_questions`/`answers` ~10-25×).
**Ce n'est pas une fuite et Postgres encaisse sans souci** — rien à faire tant
que le trafic est faible. Le **seul** vecteur réellement non borné, c'est la
démo guest : quota supprimé le 2026-05-17 (`PublicAttemptService`), démo
illimitée, aucune dédup, `client_ip` posée mais inexploitée. Un bot qui martèle
l'endpoint démo gonfle la table avec de l'analytics jetable. À faire **avant
l'ouverture publique / montée en trafic**, pas avant :

1. **Rate-limit** sur `POST /api/public/attempts/demo` (et le lot guest) par IP
   — bucket simple en mémoire ou Bucket4j. But : couper l'inflation par bot,
   pas brider un vrai visiteur.
2. **Job de purge** `@Scheduled` (quotidien) supprimant les attempts anonymes
   anciens : `DELETE FROM attempts WHERE user_id IS NULL AND started_at <
   now() - interval '30 to 90 days'`. Les tables filles partent en cascade DB
   (déjà en place). L'index partiel `idx_attempts_demo_quota` (V006, laissé en
   base) couvre déjà ce filtre. Ne touche **jamais** aux attempts d'un user
   connecté — historique, source de vérité freemium.

Plus tard encore (vrai volume) : rétention via **partitionnement par date** ou
archivage des `TERMINE` anciens — surtout pas de suppression d'historique user.

## Identité IP des appelants (rate-limits, attempts invités)

Tout ce qui se compte « par IP » — rate-limits anti-abus (login, inscription,
mot de passe oublié, contact, démo) et `attempts.client_ip` des sessions
invitées — passe par `util/ClientIpResolver`.

- **`X-Forwarded-For` / `X-Real-IP` ne sont lus que si la connexion vient d'un
  proxy déclaré de confiance** (`sejourfr.trusted-proxies.ranges`, env
  `TRUSTED_PROXY_RANGES`, adresses ou CIDR séparés par des virgules).
  **Vide par défaut** → en dev et sans configuration, c'est l'IP de la socket
  qui fait foi. Sans ce garde-fou, n'importe qui remettait ses compteurs à zéro
  en changeant un en-tête, et un invité se fabriquait autant d'identités qu'il
  voulait.
- En production, y mettre les plages du reverse-proxy réel. La valeur spéciale
  `*` fait confiance à tout appelant : à réserver aux hébergements dont le port
  applicatif n'est joignable que par le load balancer.
- Quand le proxy est de confiance, on retient la **dernière adresse non-proxy**
  de la chaîne `X-Forwarded-For` (les valeurs forgées par le client sont à
  gauche de celle ajoutée par notre proxy, donc ignorées).
- Le rate-limit de connexion **se réinitialise sur authentification réussie**
  (`RateLimitGuard.onLoginSuccess`) : on freine l'enchaînement d'échecs, pas
  l'utilisateur qui se reconnecte.

## Mesure d'audience des landings (sans traceur)

Compteur **maison**, sans service tiers, pour savoir combien de visiteurs
consultent une page de campagne (`/reussir`, le lien de bio réseaux) et combien
cliquent son CTA, découpé par réseau de provenance.

- **Table `page_views` (V020)** : agrégat, pas journal — une ligne par
  (page, source, événement, jour), incrémentée par `INSERT … ON CONFLICT DO
  UPDATE` (atomique). La table est donc **bornée** par construction, à
  l'inverse du problème des attempts invités signalé plus haut.
- **Rien n'est stocké côté visiteur** : ni cookie, ni localStorage, ni
  sessionStorage ; et rien de personnel côté serveur : ni IP, ni user-agent, ni
  identifiant. C'est ce qui permet à `/confidentialite` de continuer d'affirmer
  qu'aucun traceur n'est déposé, et de se passer de bandeau de consentement.
  **Ne pas ajouter de déduplication persistante sans repasser sur la page
  légale.** Conséquence assumée : on compte des **vues**, pas des visiteurs
  uniques.
- **Deux listes blanches** dans `PageViewService` (`TRACKED_PATHS`,
  `KNOWN_SOURCES`) : l'endpoint d'écriture étant public, elles sont la seule
  chose qui empêche un tiers de créer des dimensions à volonté. Ajouter une
  landing mesurée = l'ajouter à `TRACKED_PATHS`.
- **Web** : `lib/audience.ts` (`detectTrafficSource`, `trackPageView`,
  `trackCtaClick`) — même détection de provenance que le badge du hero, un seul
  endroit qui décide « ce visiteur vient de TikTok ».
- **Admin** : `features/audience/` — vues, clics, taux de clic par réseau et
  série journalière, sur 7 / 30 / 90 jours.
- Reste à faire avant l'ouverture publique : un **rate-limit par IP** sur
  `POST /api/public/page-views`, même chantier que la démo invitée. Sans lui, un
  bot peut gonfler un compteur — donnée fausse, mais ni fuite ni inflation de
  stockage.

## Notation IA des productions EE/EO — repères

Le « quoi » et le « pourquoi » vivent dans `docs/notation-ia-eo-ee.md` (référence
grand public, **à tenir exhaustive et à jour dans la même passe** — cf. la règle
dédiée plus bas). Ici, uniquement de quoi se repérer.

- **Versions actives** : rubriques `production-rubrics-v13.json`, tool-schema de
  sortie `production-evaluation-tool-schema-v7.json`, persona vocale
  `realtime-personas-v3.json`. **v12/v6, v9/v5, v8/v5, v7/v4, v6/v3, v5/v3, v4.2/v2,
  v4.1/v2, v4/v2 et v3/v2 restent chargeables et validées** : un retour arrière
  change la paire `EVAL_RUBRICS_VERSION` + `EVAL_PROMPT_VERSION`, aucune migration.
  **On versionne, on ne réécrit jamais** une rubrique livrée. **v10 et v11 sont
  chargeables mais MESURÉES MOINS BONNES que v9 — ne pas les réactiver** (détail
  dans le filet de langue étrangère, plus bas).
- **v13 / v7 = LE FRANÇAIS RENDU AU CANDIDAT EST ACCENTUÉ.** v13 est **v12 au bit
  près** (rubriques de tâche, `commun.niveau/couplage/plafonds/bandes_criteres`, les
  16 ancres, les 23 sections — verrouillé par `ProductionEvaluationContractTest`) ;
  elle **appende une 24ᵉ section**, et rien d'autre. Le tool-schema v7 est v6 avec
  ses `description` **réaccentuées** — verrou : égalité **après repli des accents**
  (`fold(v7) == v6`), donc aucune reformulation ne peut s'y glisser ; seules 3
  descriptions s'étoffent (racine + les 2 champs de citation) et elles doivent
  *commencer* par celle de v6. Motif, constaté en production : « Excuse formulee »,
  « le passe compose est maitrise », « J'espere que cette date te convient ».
  **Cause probable : nos propres prompts étaient écrits sans accents** (ratio
  d'accents 0,0002 sur 96 k lettres, contre ~0,03 en français normal) — un LLM imite
  la langue de son prompt. D'où l'ordre des leviers ici : on a d'abord réaccentué le
  **texte lu par le modèle**, la consigne ne vient qu'en second.
  ⚠️ **Exception à ne jamais casser : ce qui est CITÉ se recopie tel quel**, fautes et
  accents manquants compris — `points_a_ameliorer.exemple.avant` et
  `exemples_corriges[].original`. Écrit à 3 endroits (section v13, description racine
  v7, description des 2 champs). Sous le contrat v6+ la preuve est un **numéro**, donc
  aucune citation n'est plus vérifiée mot à mot : un accent ajouté ne peut plus faire
  échouer une soumission — **mais c'était le cas sous v5 et antérieurs**, qui restent
  chargeables en retour arrière.
  **Détecteur serveur : `EvaluationAccentAudit` — il MESURE, il ne refuse RIEN**
  (log `warn` + formes vues). Liste **fermée** de formes sans lecture française valable
  sans accent ; sont exclus les mots encore français sans accent (`tache`, `cote`, `a`,
  `ou`, `regle`), les homographes anglais (`experience`, `different`), les champs de
  citation, les passages entre guillemets et les textes posés par le serveur (`label`,
  `avertissements`). Choix assumé : une soumission perdue coûte plus cher qu'un accent
  manquant — cf. le coût invisible de la contrainte de preuve littérale.
  ⚠️ **Bascule NON mesurée au banc** (aucune règle de notation ne bouge ⇒ aucune
  campagne requise). Retour arrière : `EVAL_RUBRICS_VERSION=v12` + `EVAL_PROMPT_VERSION=v6`.
- **v12 / v6 = LA PREUVE SE DÉSIGNE PAR NUMÉRO, elle n'est plus recopiée.** v12 est
  **v9 au bit près pour tout ce qui note** (échelle, 4 critères, seuils, couplage,
  plafonds, bandes, tests décisifs, les 16 ancres few-shot — verrouillé par
  `ProductionEvaluationContractTest`) ; seules changent les 5 sections qui décrivent
  la preuve. La production part au correcteur **découpée en segments numérotés**
  (`EvaluationProductionSegments` : EO dialogué = un tour `Candidat :` ; EE et EO
  monologue = une phrase). **Les tours `Examinateur :` sont montrés mais SANS
  numéro** → citer l'examinateur devient structurellement impossible.
  `scores_criteres[].preuve` (string) devient `preuve_segment` (entier ≥ 1), et
  `AiEvaluationService.resolvePreuveSegments` **résout le numéro en texte avant
  persistance** : `feedback_json.preuve` reste une chaîne, **aucun miroir DTO à
  propager** sur les 3 fronts (vérifié). **Inventer une preuve devient impossible par
  construction**, pas « interdit » : les seules violations possibles sont un entier
  hors bornes (dégradable après réessai, comme une citation non rattachable) ou un
  non-entier (bloquant, comme une preuve vide). Motif : `PREUVE_NON_RATTACHEE` était
  le premier poste de refus — **42,9 % des appels sur les productions orales**.
  `EvaluationProofMatcher` reste en place pour les contrats ≤ v5 (retour arrière) :
  ne pas le supprimer, mais il n'est plus exercé en production.
  ⚠️ **Bascule NON mesurée au banc** (l'utilisateur interdit les appels payants).
  Défendable sans mesure parce qu'aucune règle de notation ne bouge et que le seul
  changement de prompt **retire** une contrainte. Retour arrière :
  `EVAL_RUBRICS_VERSION=v9` + `EVAL_PROMPT_VERSION=v5`.
- **NOTE /20 MASQUÉE SUR UNE TÂCHE ISOLÉE** (décision produit, 2026-08-08) : le résultat d'une
  tâche n'affiche plus que le **niveau** + sa position dans le palier. Au TCF le correcteur
  attribue un niveau **par tâche**, la note /20 ne porte que sur l'**épreuve entière** ; et sur
  l'échelle officielle (10 = B2), « 3,5/20 » se lit comme un naufrage alors que c'est un A2
  normal. **Aucune règle de calcul ne bouge** : la note reste calculée, persistée et exposée
  (`EvaluationResultDto.noteSurVingt`, bilan d'épreuve, admin, banc). Changement d'**affichage**.
  Remplacement du signal de progression : **`SituationDansNiveau`** (`ENTREE_DE_PALIER` /
  `PALIER_CONFIRME` / `PALIER_SOLIDE`, libellés *Palier atteint / confirmé / solide*, composés
  en « **A2 solide** »). Dérivé **serveur** (`SituationDansNiveau.of`, appelé par
  `ProductionSubmissionMapper`), jamais recalculé par un front — même philosophie que
  `SkillStatusResolver`. Bornes de bande lues dans `commun.niveau` de la **grille active**, pas
  en dur. ⚠️ **Règle de formulation gelée** : le haut de A2 se dit « A2 solide », **jamais
  « presque B1 »** — on vient de retirer le vocabulaire de déficit, on ne le réintroduit pas.
  `null` si pas de note, `A1_NON_ATTEINT` (bande d'un seul point) ou C1/C2. Note hors bande
  (niveau **plafonné**) → ramenée dans la bande affichée. Libellés figés par
  `SituationDansNiveauTest` ; **à mirrorer sur les 3 fronts**.
- **VERSION AU NIVEAU VISÉ — SECOND APPEL LLM SÉPARÉ, EE seulement** (`service/versionciblee/`,
  livré **ACTIF**). Rend au candidat sa réponse **réécrite au palier qu'il VISE**
  (`User.targetLevel`, repli `production_tasks.niveau_cible`) + **2 à 3 leviers** concrets.
  Distinct de `version_amelioree`, qui vise le palier **juste au-dessus**.
  ⚠️ **C'est désormais LE texte modèle affiché sur un résultat EE** : les fronts ont
  retiré `version_amelioree` de l'écran (champ toujours produit et persisté, plus
  aucun lecteur). Motif mesuré en base : elle était **au même niveau que la copie**,
  sans étiquette de palier — recopiée telle quelle et resoumise, elle rendait la
  **même note au dixième près**. `version_ciblee`, elle, **nomme son niveau**.
  ⚠️ **L'appel est séparé de la correction, c'est la raison même du montage** : le prompt de
  notation ne change pas d'un octet et le correcteur n'apprend **jamais** le niveau visé, sinon
  il aligne sa note dessus (v10/v11 ont mesuré qu'un simple bloc ajouté à la grille fait tomber
  l'accord exact de 81,8 % à 75,6 %). **Ne pas fusionner les deux appels.** Verrou :
  `VersionCibleeContractTest`.
  Prompts versionnés `production-version-ciblee-{rubrics,tool-schema}-v1.json`, paire validée au
  boot ; **aucune consigne en dur dans le Java** ; français **accentué** (leçon v13/v7).
  Sortie stricte à 2 champs (`texte`, `ce_qui_manque[2..3]`), `additionalProperties:false`,
  `maxLength` + budget en mots déclaré par la grille (25) + plafond serveur — **aucun champ où
  loger une note ou un niveau**. Le serveur ajoute `niveau_vise` / `niveau_constate`.
  **Best-effort, jamais bloquant** : lancé par `ProductionPipelineAsyncRunner` **après** que
  l'éval est persistée et `EVALUATED`, **hors transaction** (invariant du runner), le service
  avale toute exception, **aucun rejeu** (c'est un confort, pas une correction). Rien n'est
  produit si le niveau visé est **≤** au niveau constaté, à l'oral, ou drapeau éteint.
  Persistance dans `feedback_json.version_ciblee` — **aucune migration**. Tokens/coût du 2ᵉ
  appel **additionnés** à ceux de l'éval. Provider = `production-evaluation.provider` (règle
  « un seul correcteur configurable »), réglages propres sous
  `production-evaluation.version-ciblee` (`enabled`, `max-tokens: 1200`, `max-leviers: 3`).
  Retour arrière : `EVAL_VERSION_CIBLEE_ENABLED=false`. **Aucune campagne requise** : rien de ce
  qui note ne bouge, par construction. Le banc (`CalibrationRunner`) n'emprunte pas ce chemin.
- **v4** = critères propres à chaque tâche (5 par tâche, fini les 4 universels),
  obligatoires vs pistes, bloc accomplissement, confiance, preuve littérale,
  2 priorités max. **v4.1** = correction de l'indulgence du **bas** d'échelle
  mesurée au banc, sans supprimer aucune tolérance (plafonds A1/A2 + test
  décisif A1 vs A2 avec obligation de citation). **v4.2** = même technique
  appliquée au **haut** : `TEST DECISIF B1 vs B2` opposable — deux marqueurs B2
  à citer littéralement, dont un pris dans « objection envisagée puis traitée »
  ou « lexique précis ».
- **v5 = NOTRE grille, alignée sur les dimensions évaluées au TCF**, en
  remplacement de la grille maison précédente. ⚠️ **Ne pas la présenter comme « la
  grille du vrai examen »** : France Éducation international publie ses critères en
  **trois familles** (linguistiques, pragmatiques, sociolinguistiques) et fait
  corriger chaque production par **plusieurs évaluateurs humains indépendants**,
  selon une règle de calcul que nous ne reproduisons pas. Nos quatre critères sont
  une grille **SejourFR**, et notre note une **estimation pédagogique exprimée sur
  l'échelle du TCF IRN**. Formules bannies partout (doc, fronts) : « votre note
  officielle serait », « notre calcul reproduit le calcul officiel », « notre grille
  est celle du vrai examen ». Structure :
  **4 critères équipondérés à 0,25**, **codes identiques sur les 6 tâches** —
  `communiquer` (accomplir la tâche + enchaîner les idées), `interagir`
  (adéquation à la situation et au destinataire), `lexique`, `morphosyntaxe`.
  Ce qui distingue les tâches, ce sont les **descripteurs et consignes**, plus
  les critères. Absorptions : `realisation_consigne`, `chronologie_recit`,
  `prise_position`, `argumentation`, `conduite_echange`,
  `developpement_reponses` **et `coherence`** → `communiquer` ;
  `adequation_destinataire` → `interagir`.
  - **L'accomplissement compte enfin dans le niveau** (il en était explicitement
    exclu jusqu'à v4.2 — d'où des cartes « 11/20 » + « proche du A2 »). Le
    niveau **dérive de la note** : `seuils 16 / 13 / 9` déclarés **dans le
    fichier de rubriques** (`commun.niveau`), lus par
    `ProductionRubricsProvider.niveauCecrl()`, qui l'emporte sur
    `sejourfr.production-evaluation.niveau-cecrl` (celui-ci ne sert plus qu'aux
    grilles v3→v4.2). C'est ce qui garde le retour arrière à **une seule
    variable**.
  - **Garde-fou de couplage — invention SejourFR, PAS une règle TCF** (aucun texte
    de France Éducation international ne le prévoit ; c'est un réglage de
    calibration, ajouté parce qu'un correcteur automatique surévalue
    l'accomplissement, et il ne peut qu'**abaisser**) : `communiquer` et
    `interagir` ne dépassent jamais de plus de **4 points** la moyenne de
    `lexique`+`morphosyntaxe`. Écrit dans le prompt **et** appliqué serveur
    (`AiEvaluationService.applyCouplage`, `sejourfr.production-evaluation.couplage`,
    no-op sur les grilles antérieures). Conséquence : langue A2 → note ≤ 12 → A2,
    un `communiquer` élevé ne peut pas fabriquer un B2.
  - **`note_globale` a UNE décimale** (avant : entier). Avec 4 critères à 0,25 la
    moyenne tombe sur des quarts de point ; arrondir affichait « 13/20 » à côté
    d'un A2 calculé sur 12,5. Arrondir le niveau au lieu de la note a été **mesuré
    comme pire** (38 → 35 classements exacts).
  - **Bilan d'épreuve** : poids des 3 tâches **égaux** (`poids-taches [1,1,1]`,
    réglable) — le TCF publie une seule note d'épreuve et aucune pondération, et
    la difficulté croissante est déjà dans les descripteurs. `noteEpreuve` et
    `bilanEpreuve` partagent le même périmètre (tâches manquantes à 0 des deux
    côtés sur une épreuve terminée), donc note et niveau du bilan racontent la
    même histoire ; `correspondanceTcf` en découle.
  - **Tool-schema v3** (contrat à répercuter sur les 3 fronts) :
    `points_a_ameliorer[]` passe de `string` à **objet**
    `{constat, comment, exemple:{avant, apres}}` — le serveur **normalise
    toujours** vers cette forme, même sur une sortie v2 ou une production
    invalide, pour que les fronts n'aient qu'un seul contrat ;
    `exemples_corriges[]` gagne **`gain`** (ce que la reformulation démontre de
    plus) ; `scores_criteres` est fixé à exactement 4 items énumérés.
  - Mesure (témoin v4.2 rejoué le même jour, même modèle, 5 cas v5 perdus par
    rate-limit du fournisseur) : A1 6/8 → **8/8**, A2 11/13 → 11/13, B1 9/9 et
    B2 6/6 sur les cas mesurés, accord exact 81,3 % → **88,4 % des cas mesurés**
    (79,2 % en comptant les cas perdus), 0 % de sortie invalide, pièges
    identiques. La part de notes dans la fourchette du corpus baisse (83,3 % →
    76,7 %) : **changement d'échelle**, les fourchettes du corpus ont été écrites
    pour une note qui n'incluait pas l'accomplissement. Corpus **jamais**
    retouché.
- **v6 = l'ÉCHELLE réelle du TCF** (v5 avait pris ses critères, v6 prend son
  barème). Les seuils `commun.niveau` sont la **table officielle** : `10 → B2`,
  `6-9 → B1`, `2-5 → A2`, `1 → A1`, `0 → A1 non atteint`. **Chaque critère** se
  note sur cette même table, donc plus aucun décalage critère ⇄ note globale.
  Motif : une carte affichait « 12,5/20 » **et** « proche du B1 », alors que
  12,5 vaut B2 au TCF — deux informations contradictoires.
  - ⚠️ **Ce n'est pas un déplacement de seuils.** Déplacer les seuils seuls
    aurait basculé en B2 une masse de B1. Tous les repères, tous les
    descripteurs et **les 16 ancres few-shot ont été re-scorés** sur la nouvelle
    échelle (un B2 vaut 12-16, plus 16-20 ; un très bon B1 vaut 9, plus 14).
  - **Tout ce qui se lit sur une note est déclaré PAR LA GRILLE** depuis v6, plus
    seulement les seuils : `commun.couplage.ecart_max`, `commun.plafonds`,
    `commun.bandes_criteres`. Résolus par `ProductionRubricsProvider.couplage()`
    / `.plafonds()` / `.bandesCriteres()`, qui l'emportent sur la config. Sans
    ça, le retour arrière demanderait une troisième bascule de seuils en plus
    de la paire rubriques + tool-schema.
  - **Garde-fou de couplage recalculé : 4 → 1 point.** Ce qui se conserve n'est
    pas l'écart mais le **gain maximal concédé à la moyenne** (`ecartMax / 2`).
    À 1 point ce gain plafonne à 0,5 : une langue au **haut** de son palier (5
    pour A2, 9 pour B1) ne peut jamais franchir le seuil suivant. Sous v5,
    l'écart de 4 donnait le même effet parce que les seuils globaux y étaient
    décalés de 2-3 points ; ce décalage n'existe plus.
  - **Seuils des plafonds 5 → 1** (haut de la bande A1 de l'échelle en vigueur,
    même règle transposée) ; **bandes `BandeCritere` 16/11/6 → 10/6/2**
    (`BandeCritere.of(note, bornes)`), sinon un B1 à 8 s'afficherait « en cours
    d'acquisition ». `applyBandesCriteres` est passé **après** `applyCouplage` :
    la bande décrivait la note d'avant plafonnement.
  - **Corpus** : `note_min`/`note_max` **régénérés** depuis `attendu.niveau` par
    la table officielle (verrouillé par `GoldenSetTest`). Niveaux, tolérances,
    confiances, pièges et productions **inchangés** — on ré-exprime la référence,
    on ne l'ajuste pas. Corollaire : `note dans la fourchette` ≈ `accord exact`,
    et la colonne note d'un témoin v5 n'est **pas comparable**.
  - Mesure (témoin v5 rejoué le même jour, même modèle) : accord exact
    86,0 % → **87,0 %**, accord ±1 palier 88,4 % → **100 %**, pièges 6/7 → **8/8**
    (quasi-muet réparé), **A1 non atteint 4/8 → 8/8** (le point faible documenté
    du banc), B2 6/7 → 6/6, B1 8/8 → 10/11, A2 11/12 → 11/13, 0 sortie invalide.
    Seul recul : **A1 8/8 → 5/8**, les 3 cas ressortant A2 — niveau *toléré* par
    la référence sur ces 3 cas, et que le modèle leur donnait **déjà** sous v5
    (langue notée 7/20 = bande A2 de v5) ; c'est le décalage bandes/seuils de v5
    qui affichait A1, pas son jugement. Le palier A1 ne vaut qu'**une valeur**
    sur la grille officielle : c'est la nouvelle zone fragile.
- **v8 = la RESTITUTION, version active (rubriques v8 / tool-schema v5).** Elle
  ne touche à **rien** de ce qui note : échelle, quatre critères, seuils,
  `couplage.ecart_max=1`, plafonds, bandes, tests décisifs A1/A2 et B1/B2 et les
  **16 ancres few-shot** sont ceux de v7, au bit près (verrouillé par
  `ProductionEvaluationContractTest`) — **aucune campagne de banc n'est requise
  pour cette bascule**. Elle corrige le rapport rendu au candidat, jugé
  répétitif, scolaire et contradictoire :
  - **confiance = certitude du correcteur, jamais qualité du candidat** : elle ne
    baisse plus parce que la production est faible ou fautive (EE lisible et
    complète → `HAUTE`), uniquement sur un obstacle à l'**observation**. Les deux
    interdits historiques (confiance ⇏ note ; confiance faible ⇏ hors-sujet) sont
    conservés ;
  - **une erreur, un seul endroit** : `commentaire` caractérise, `points_a_ameliorer`
    enseigne, `exemples_corriges` démontre sur d'**autres** phrases, `suggestions`
    ne reprend rien, `version_amelioree` montre sans réexpliquer ;
  - **aucun reproche sur un moyen que la consigne n'exigeait pas** → « levier de
    progression ». ⚠️ Règle de **formulation** : `justification_niveau` (expurgé
    avant le front) applique la règle de preuve et les plafonds à l'identique ;
  - **cohérence accomplissement ⇄ rapport** : un point demandé mais mal formulé
    est PRÉSENT (`points_traites` + réserve de forme) ; interdit de le déclarer
    absent ailleurs ;
  - **nouveau contrat exposé aux fronts** : `accomplissement.objectif`
    (`ATTEINT|PARTIELLEMENT_ATTEINT|NON_ATTEINT`, enum `ObjectifTache`) +
    `accomplissement.objectif_resume` (phrase candidat), et `version_amelioree`
    (string racine) **obligatoire en EE, absente en EO** (retirée serveur). Le
    verdict ne regarde que les points **obligatoires**, est indépendant de la
    note, et le serveur l'**abaisse** à `PARTIELLEMENT_ATTEINT` s'il vaut
    `ATTEINT` malgré un `points_oublies` `obligatoire=true` (jamais l'inverse,
    même philosophie que `applyConfiance`) ;
  - **plafonds de restitution** : `points_forts` ≤ 2 et `exemples_corriges` ≤ 3,
    `maxItems` schéma + refus validateur + **troncature serveur** (`capListe`),
    comme les 2 priorités ;
  - **legacy non migré** : les ~100 évaluations sans `objectif` restent telles
    quelles, le champ est absent et les fronts n'affichent pas le bloc.
- **v7 = profil TCF IRN strict.** Elle conserve l'échelle et les
  quatre critères de v6, retire C1/C2 de tout ce qui est envoyé au correcteur et
  déclare explicitement `profile=TCF_IRN`, `niveau_max=B2` et
  `tool_schema_version=v4`. Le schéma v4 impose exactement les quatre critères,
  les niveaux `A1_NON_ATTEINT|A1|A2|B1|B2`, toutes les structures requises et
  `additionalProperties=false`. Le serveur valide la sortie **brute avant toute
  normalisation** : note finie dans `[0,20]`, quatre codes exacts sans doublon,
  structure complète et aucun niveau au-dessus de B2. Une sortie invalide est
  rejouée **une seule fois** avec les violations. Après ce retry, l'unique repli
  accepté est une seule preuve non vide mais non rattachable, tous les autres champs et les
  trois autres preuves étant valides : elle est retirée, la confiance plafonnée à
  `MOYENNE` et un avertissement serveur est ajouté. Deux preuves, une preuve vide ou toute
  autre violation font échouer la submission sans note partielle. Sur un retry réparé ou
  dégradé, tokens d'entrée, tokens de sortie et coût des deux appels sont additionnés.
- **Changer de LLM ou de modèle ne touche AUCUN `.java` ni `.yaml`** — exigence du
  propriétaire, verrouillée par les tests. Trois mécanismes : la **forme de requête**
  (`max_tokens` vs `max_completion_tokens`, `temperature` envoyée ou omise) est
  **négociée** (`ChatCompletionDialectNegotiator` : déduit le remplacement du 400 du
  fournisseur, rejoue **une fois**, mémorise par processus ; un **400 métier** ne
  renégocie **jamais** ; les heuristiques par famille ne sont qu'un point de départ) ;
  le **modèle et ses deux tarifs** sont des `${EVAL_*_MODEL/COST_INPUT/COST_OUTPUT}` ;
  le même dialecte sert `CompetenceOpenAiCompatibleClient` — sinon une bascule casse
  le module Compétences en silence. `EvaluationPricingTest` ne fige plus une table
  « tel modèle = tel prix » (elle rendait rouge tout changement de modèle) mais une
  **cohérence** : tarif présent, positif, plausible, **posé dans la même source que le
  modèle**. `CalibrationEnvTest` vérifie un environnement **cohérent**, plus quel
  provider est choisi. `EvaluationProviderSwapTest` prouve qu'un modèle inédit se
  branche sur les 3 providers par 4 variables.
- **Correcteur actif : DeepSeek `deepseek-v4-flash`** (`.env`, défaut YAML aligné) —
  **choix mesuré, pas par défaut**. Trois campagnes v9 sur les 48 cas ont départagé
  `flash`, `deepseek-v4-pro` et `gpt-5.4` :

  | | `flash` | `pro` | `gpt-5.4` |
  |---|---|---|---|
  | **appels refusés — tous cas** | 27,3 % | 17,9 % | **0 %** |
  | **appels refusés — ORAL** | **42,9 %** | 31,2 % | **0 %** |
  | appels refusés — écrit | **0 %** | **0 %** | **0 %** |
  | accord exact | **81,3 %** | 77,1 % | **81,3 %** |
  | pièges | **8/8** | 4/8 | 5/8 |
  | B2 · A1 · A2 | 6/7 · 3/8 · 10/13 | 3/7 · **4/8** · **12/13** | 6/7 · 2/8 · 11/13 |
  | latence médiane / max **par appel** | 16,3 s / 36 s | 28,8 s / 67 s | **12,9 s / 32 s** |
  | coût 48 corrections | **0,91 $** | 1,12 $ | 4,14 $ |

  ⚠️ **La ligne « corrections perdues » de ces campagnes est NON COMPARABLE et a été
  retirée** : `calibration.retries` valait **9 / 3 / 1**. `flash` n'a pas moins perdu,
  il a eu neuf vies. En production il n'y a qu'**un** réessai — figer `retims` entre
  témoin et candidat, et le reporter dans le rapport. Ne jamais rechoisir un modèle
  sur cette colonne.
  ⚠️ **`pro` est plus cher que `flash`** — le nom ne dit rien de l'aptitude à cette
  tâche. `gpt-5.4` est le seul sans aucun appel refusé, mais 4,5× le prix (écarté sur
  le coût, 2026-08-08). **Choix en cours de réexamen.**
  **Le rejet est un problème purement ORAL** : 0 % d'appels refusés en EE chez les
  trois moteurs. Et ce ne sont pas des JSON cassés — ce sont **nos validateurs** qui
  refusent des sorties bien formées. Tarifs relevés le 2026-08-07 sur
  api-docs.deepseek.com : flash 0,14 / 0,28 ; pro 0,435 / 0,87 — **l'ancien
  0,27 / 1,10 du YAML était faux** et surestimait 2 à 4× les coûts déjà persistés.
  `timeout-sec` deepseek 60 → **90** (read timeout **par appel** : pire appel `flash`
  36 s, `pro` 67 s ; les « 5 min » d'un rapport sont un **cas entier**, pas un appel).
  Bascule = un bloc de 3 lignes de `.env`. Détail : `docs/notation-ia-eo-ee.md` §12.6.
- **Une sortie LLM malformée est TRANSITOIRE, donc rejouée** (`@Retryable` des deux
  clients) : absence de `tool_calls`, `finish_reason=length`, arguments vides,
  JSON illisible, réponse vide. Seuls la configuration absente et les 4xx sont
  terminaux. Motif : un unique échantillon corrompu (mesuré : du texte arabe
  glissé au milieu de `scores_criteres`) détruisait la tâche sans recours. Le
  `@Recover` **conserve la cause** dans le message, sinon la ventilation
  `MotifPerte` du banc reclasse une troncature en « fournisseur indisponible ».
- **Un message de réessai ne vaut que s'il est actionnable** — vrai pour les
  preuves (cf. `EvaluationRepairPrompt`) **comme pour le garde-fou oral** :
  une violation orale nomme désormais la notion interdite et cite le passage
  rejeté, et le prompt de réparation donne la sortie sûre. Renvoyer le seul
  libellé brut de la violation ne répare rien (mesuré : 0/8 sur les preuves).
- **Preuves opposables (schémas v4 et v5)** : chaque critère porte une citation non vide. Le
  serveur privilégie le passage contigu exact, puis ne tolère, à partir de 4
  tokens, qu'une seule édition de token : insertion/suppression réservée à une liste
  fermée de mots-outils ; la seule substitution admise est la flexion
  `telle/tels/telles`, explicitement reconnue. Toute autre substitution est refusée.
  Elle exige au moins 3 tokens significatifs identiques, un match unique et aucun écart de
  nombre/négation ; tout token contenant un chiffre est immuable. Les variantes
  Unicode, ligatures, apostrophes, tirets et espaces sont neutralisées. En
  dialogue EO, seuls les tours `Candidat :` sont cherchés. Toute preuve acceptée
  est remplacée avant persistance par la sous-chaîne originale exacte ; une
  preuve inventée ou ambiguë déclenche le retry sémantique. Si une unique preuve
  demeure non rattachable après ce retry, elle n'est jamais persistée : le mode
  dégradé documenté ci-dessus conserve seulement les trois preuves sûres.
  **Élision des disfluences, sens production → citation uniquement**
  (`EvaluationProofMatcher.DISFLUENCES`, liste fermée `euh|heu|hum`, tirée de
  `NON_SIGNIFICANT`) : la production peut porter ces tokens en nombre quelconque
  sans que la citation ait à les recopier. **Aucun token porteur de sens n'est
  dispensé** — une citation contenant un mot absent de la production reste
  refusée, la contiguïté et la tolérance d'une seule édition sont inchangées, une
  disfluence ne peut ni ouvrir ni fermer le passage restitué (qui reste la
  sous-chaîne originale exacte, disfluences comprises). Motif : la transcription
  Whisper est littérale, et le prompt interdit par ailleurs d'évaluer les
  hésitations — sans cette élision, le correcteur ne pouvait pas satisfaire les
  deux consignes.
- **Élision des répétitions immédiates** (`EvaluationProofMatcher`, contrats ≤ v5) :
  même famille que l'élision des disfluences, **sens production → citation
  uniquement**. Un bloc de 1 à 3 tokens **immédiatement répété** dans la production
  peut n'apparaître qu'une fois dans la citation. Motif : le correcteur dédouble les
  bégaiements — ce que la grille lui ordonne par ailleurs de ne pas évaluer — et deux
  citations JUSTES ont été refusées d'affilée sur une même production réelle
  (`une sœur qui se trouve tous tous chez moi`, `j'aime bien les les films les films
  comédies`), soit 2 et 3 suppressions, hors de la tolérance d'**une seule** édition.
  **Deux lectures, jamais mélangées** : la lecture stricte garde le comportement
  historique au bit près et **gagne toujours** ; l'élision n'est tentée que si la
  première ne trouve **rien**. L'élision se fait **avant** l'appariement et ne
  consomme donc pas le budget d'édition. Aucun bloc contenant un nombre, un chiffre
  ou une négation n'est élidable ; ambiguïté = refus ; le passage restitué reste la
  **sous-chaîne originale exacte**, bégaiements compris. Limite assumée : une
  répétition légitime (`très très bien`) est élidable — sans conséquence, le texte
  affiché reste celui du candidat.
- **Message de réessai** (`EvaluationRepairPrompt`) : le retry ne renvoie plus la
  seule liste brute des violations (mesuré : **0 preuve réparée sur 8**, le
  modèle resoumettait la même citation). Il rappelle **la citation refusée,
  critère par critère**, énonce la règle (passage contigu, recopié tel qu'il
  apparaît, pas d'ellipse, pas de recomposition, un seul tour `Candidat :` en EO)
  et suggère de re-citer plus court. **Aucun contrôle serveur n'est relâché** :
  on aide le correcteur à respecter la vérification.
- **Mot coupé par la transcription** (`EvaluationProofMatcher`, 2026-08-07) : un token
  de la citation peut recoller **plusieurs tokens consécutifs de la production** dont
  la concaténation est identique — **sens unique production → citation**, exactement
  comme l'élision des disfluences. Motif : sur une transcription hachée
  (« j'ai ach eté cette ves te »), presque aucun passage n'était citable, et la grille
  ordonne pourtant de « changer de passage » — on demandait l'impossible. Quatre
  garde-fous, tous dans le sens « en cas de doute, on ne fusionne pas » : ≤ 3
  fragments ; **blancs horizontaux seuls** entre fragments (ni apostrophe, ni trait
  d'union, ni ponctuation, ni saut de ligne — donc jamais à travers un tour
  `Examinateur :`) ; aucun fragment négation / nombre / chiffre / disfluence ; le mot
  recollé n'est jamais une négation ni un token chiffré. Contiguïté, match unique,
  écart de nombre/négation, tolérance d'une seule édition, tours `Candidat :` :
  **inchangés** ; le passage restitué reste la **sous-chaîne originale exacte**,
  coupures comprises. La voie *fuzzy* (une édition) n'en bénéficie **pas** :
  mot coupé **plus** édition = cas doublement dégradé. Limite assumée et testée : deux
  mots voisins soudés par la citation passent — sans conséquence, rien n'est inventé
  et le passage affiché reste le texte réel.
- **Garde-fou oral : deux faux positifs corrigés** — `repetition` n'est plus interdit
  que dans ses emplois de **diction** (consigne d'évitement portant sur « les
  répétitions » en bloc, ou voisinage d'un marqueur oral dans la même phrase) : il
  détruisait des évaluations pour des remarques de **morphosyntaxe** et levait une
  **contradiction interne** du dépôt, la rubrique v9 §19 *ordonnant* de peser « a-t-il
  dû faire répéter ? ». `accent` n'est refusé que hors de l'idiome « mettre l'accent
  **sur** ». `fluidite`, `prononciation`, `debit`, `intonation`, `pauses`,
  `hesitation`, `orthographe` : **inchangés** — l'acquis « on ne note jamais sur la
  prononciation » est entier. Aucune campagne requise : rien de ce qui note ne bouge.
- **`EvaluationRefusalMetrics`** : ce que nos contrôles refusent est **compté par
  (phase, motif)**, plus seulement logué, et le refus **après réessai** est logué lui
  aussi (il ne l'était pas). Le banc en tire, par tentative, les violations **et la
  citation refusée** — y compris celles du premier appel, que l'exception ne porte pas.
  Sans ça, 98 % des refus étaient sans motif traçable et toute action sur les contrôles
  était un pari.
- **Banc — deux métriques à ne plus confondre** : `sorties_refusees_pct` (÷ appels LLM,
  ce que refusent nos contrôles) ≠ `echec_production_pct` (`tentativesRatees /
  tentatives`, **la seule qui décrit ce que vit un candidat**, puisqu'en production il
  n'y a qu'**un** réessai). `appels_rates_pct` est supprimé : il comptait les
  tentatives de la boucle externe en se présentant comme un taux par appel, et
  sous-estimait les refus d'un facteur ~2. **`calibration.retries` est figé dans le
  rapport** et `-Dcalibration.temoin=<rapport.json>` fait **échouer** une campagne dont
  le témoin n'a pas tourné au même nombre de réessais.
- **Plafond de tokens de SORTIE = 4000**, identique sur les trois providers
  (`sejourfr.production-evaluation.{openai,anthropic,deepseek}.max-tokens`,
  figé par `EvaluationTokenBudgetTest`). À 2000 — valeur d'avant les quatre
  citations littérales du tool-schema — les corrections EO (1800-2000 tokens)
  arrivaient en `finish_reason=length`, JSON tronqué, submission perdue. C'est un
  plafond, pas une consommation : le relever ne coûte rien sur les sorties
  courtes. Ne pas redescendre sans retirer des champs de la sortie.
- **Transaction du pipeline async** : `ProductionPipelineAsyncRunner` reste
  volontairement **sans transaction englobante**. Whisper et l'évaluation ont
  leurs propres transactions ; `ProductionPipelineFailureRecorder` conserve
  `REQUIRES_NEW` pour rendre `FAILED` durable. Le runner charge la task par
  `findByIdWithTask` avant détachement. Ne pas réintroduire de transaction
  externe : une exception d'un service `REQUIRED` la marquerait rollback-only et
  provoquerait un `UnexpectedRollbackException` après le `catch`.
- **Garde-fou EO opposable** : le correcteur ne reçoit plus la durée et sa sortie
  est rejetée si un champ évaluatif fonde la note ou les conseils sur les
  hésitations, répétitions, faux départs, aisance, fluidité, débit,
  prononciation, accent, intonation, orthographe/ponctuation de la transcription
  ou durée. Seules les `confiance_raisons` peuvent expliquer une transcription
  incertaine.
- **Bornes EE strictes TCF IRN** : T1 `30–60`, **T2/T3 `40–90`**. La tolérance
  historique de 20 % est supprimée : serveur, web, mobile et auto-soumission
  appliquent exactement les bornes DB. Les tâches T2/T3 ont un contexte/destinataire et les neuf exemples
  livrés restent dans la fourchette. Les anciennes submissions sont préservées.
  ⚠️ **Le minimum de T2/T3 a valu 60 par erreur** jusqu'à `V724` (2026-08-08) : une
  copie de **40 à 59 mots**, pourtant recevable à l'examen, était **refusée sur les
  trois surfaces**. `V723` figeait même `mots_min = 60` par contrainte SQL.
  **Source de vérité unique : `production_tasks.mots_min/mots_max`**, injectée dans
  le prompt par `EvaluationPromptBuilder`. Ne jamais réécrire ces bornes en dur —
  ni dans une rubrique, ni dans un tool-schema, ni dans un texte de front : c'est
  exactement ce qui a produit une consigne contradictoire au correcteur.
- **Un seul correcteur configurable** : `sejourfr.production-evaluation.provider`
  dans `application.yaml` (défaut `deepseek`, modèle `deepseek-v4-flash`) pilote
  l'async, la fin de session temps réel, la seconde passe et le banc. La seconde
  passe réutilise obligatoirement le même bean provider/modèle. Gemini reste
  uniquement l'examinateur vocal et le transcripteur temps réel ; il ne note pas.
- **Banc de mesure** (`src/test/java/.../calibration/`, corpus
  `src/test/resources/calibration/golden-set-v1.json`, 48 cas synthétiques) :
  **opt-in strict**, jamais dans `./mvnw verify` (appelle un LLM payant).
  `./mvnw -q test -Dtest=CalibrationBenchTest -DfailIfNoTests=false
  -Dcalibration.enabled=true -Dcalibration.rubrics=v8 -Dcalibration.prompt=v5
  -Dcalibration.label=<nom>` → rapport JSON dans `target/calibration/`. Le banc
  lit obligatoirement le provider et le modèle du runtime dans
  `application.yaml`/`.env` : il n'existe plus de surcharge
  `calibration.provider`, afin d'éviter de mesurer un autre correcteur par erreur.
  Parallélisme ≤ 3 : au-delà le fournisseur renvoie des 429 et des cas se
  perdent (mesuré : 5 cas perdus à 4 en vol, 2 à 2 en vol avec `retries=10`).
  **Ne jamais ajuster le corpus** pour faire passer une version : on corrige le
  système, jamais la référence. Une campagne ≈ 0,45 € ; comparer une nouvelle
  version à un **rerun de l'ancienne le même jour** (le bruit inter-campagnes
  vaut ~1 pt de note / ~2 pts de pourcentage, et un seul cas qui bascule sur 12
  ne prouve rien).
  🛑 **INTERDIT DE LANCER UNE CAMPAGNE SANS DEMANDE EXPLICITE DE L'UTILISATEUR**
  (règle posée le 2026-08-07, elle prime sur tout le reste de ce fichier). Le banc
  appelle un LLM payant, c'est **l'argent de l'utilisateur**. Aucun agent ne le
  déclenche « pour vérifier », « pour mesurer avant/après » ou « parce que la règle
  du dépôt l'exige » : il faut une phrase de l'utilisateur qui le demande. En
  l'absence de campagne, on **livre quand même** — en disant franchement ce qui est
  mesuré et ce qui est estimé. La règle « toute modif d'une consigne de notation se
  mesure avant/après » devient donc : *on propose la mesure, on ne la lance pas.*
  Corollaire : **une bascule de LLM ou de modèle ne demande AUCUNE campagne** — le
  contrat de sortie (tool-schema strict, `additionalProperties:false`, longueurs
  plafonnées) et les **contrôles serveur déterministes** sont ce qui tient la
  qualité, pas la mesure a posteriori.
- **Ce qui tient la qualité, ce sont les CONTRAINTES DURES, pas les consignes.**
  Ordre de préférence, du plus fiable au moins fiable, à respecter quand on veut
  corriger un comportement du correcteur : (1) **le tool-schema** — un champ absent
  du schéma ne peut pas être produit ; (2) **une longueur plafonnée** (`maxLength`,
  budget en mots déclaré par la grille, comme le module Compétences : 20 / 30 /
  35 mots) ; (3) **un contrôle serveur déterministe** qui refuse ou purge
  (`EvaluationOutputValidator`, `EvaluationOralArtifactFilter`, `capListe`) ; (4) en
  **dernier** recours, une consigne dans la rubrique. Une consigne est un vœu : v9
  §17 interdisait déjà d'imputer un artefact de transcription au candidat, et le
  correcteur l'a fait dans 5 évaluations EO sur 72. Ne jamais répondre à un
  comportement indésirable par « on va mieux lui expliquer » quand un plafond ou un
  filtre serveur peut le rendre **impossible**.
  Convention de signe partout : **écart = référence − IA** (négatif = IA trop
  indulgente). **Toute modif d'une consigne de notation ou d'un seuil se mesure
  avant/après** — sinon c'est un pari. La contrainte de preuve littérale a été la
  seule exception à cette règle (livrée sans campagne, sans témoin rejoué) : son
  coût en soumissions perdues est resté invisible des mois. Consigné dans
  `docs/notation-ia-eo-ee.md` §12.3 bis, à ne pas effacer.
  **Motif de perte ventilé** (`CalibrationMetrics.MotifPerte` : troncature JSON /
  rejet de preuve / garde-fou oral / fournisseur indisponible / sortie incomplète
  / autre) : le rapport affiche le **taux de cas perdus à côté du taux de sortie
  invalide**. Avant, un rejet de preuve tombait dans `erreurAppel` et la doc
  affichait « 0 % de sortie invalide » pendant qu'un tiers des cas se perdait.
- **Une seule échelle depuis v6** (0 → A1 non atteint, 1 → A1, 2-5 → A2,
  6-9 → B1, **10-20 → B2**) : notre note **s'exprime sur l'échelle** du TCF — elle
  n'est pas la note officielle, qui est produite par plusieurs correcteurs humains.
  La table
  officielle vit toujours dans l'enum `BandeNoteTcf` (code, pas config — donnée
  officielle, pas réglage) ; la grille active la reprend telle quelle dans
  `commun.niveau`. On ne **convertit** toujours rien : `correspondanceTcf`
  (`{niveau, scoreTcfMin, scoreTcfMax}`, `ProductionBilanResponse`) part du
  **niveau** et n'est affichée qu'au **bilan d'une épreuve entière**. **Jamais
  sur une tâche isolée** — au TCF la note /20 porte sur les 3 tâches ; ce qui
  diffère là n'est plus l'échelle mais le **périmètre**. Détail grand public :
  `docs/notation-ia-eo-ee.md` §6.6.
- **Console de calibration admin** (`features/calibration/` +
  `AdminCalibrationService`) : annotation humaine de vraies productions, biais et
  dispersion vs IA. C'est elle qui doit faire grossir le corpus réel.
- **Fiche de scénario EO T2** : `production_tasks.agent_role_card` (migration
  V743, les 20 sujets couverts), rendue par `RealtimePersonaBuilder` via le
  gabarit `t2Fiche` de la persona v2. Jamais exposée à un client, jamais envoyée
  à l'IA correctrice — **ce n'est pas une check-list de notation**.
- **Recollage des tours EO temps réel** (`util/TranscriptTurnStitcher`, drapeau
  `sejourfr.production-evaluation.recollage-tours.enabled`, livré **ACTIF** —
  c'est une correction, pas une expérimentation). La transcription temps réel
  clôt un tour sur le signal de fin de tour **du modèle**, pas sur la fin de la
  phrase du candidat : un même énoncé ressortait scindé en tours consécutifs.
  Conséquences corrigées : `EvaluationProofMatcher.searchableSegments` construit
  un segment par tour, donc une citation à cheval sur deux tours était
  **introuvable** (et deux preuves refusées = submission en échec sous v7+) ;
  le correcteur jugeait la langue sur un texte haché et baissait sa confiance
  pour une raison venant de nous ; le candidat relisait sa phrase en deux bulles.
  - **Non destructif, un seul point d'application** : rien n'est réécrit
    (`realtime_sessions.transcript` et `transcriptions.texte` intacts), le
    recollage se fait **à la lecture** dans
    `TranscriptionManager.findLatestTexteBySubmissionId` — l'unique accesseur au
    texte, volontairement le seul (aucune méthode ne rend plus l'entité
    `Transcription`). Prompt, contrôle de preuve et DTO servi aux 3 fronts en
    héritent sans une ligne de code côté web/mobile.
  - **Invariant à ne pas casser** : le texte cité par le correcteur EST celui
    affiché au candidat. Deux points d'application = preuves inopposables.
  - **Règle — en cas de doute, on ne fusionne pas.** Le sens de l'erreur est
    assumé : une fusion **fausse** fabrique de la parole, une fusion **manquée**
    ne fait que ramener au comportement d'avant. Trois garde-fous, tous dans ce
    sens : (1) même locuteur uniquement ; (2) **jamais** à travers un tour
    `Examinateur :` ; (3) **jamais** quand une phrase paraît terminée et qu'une
    nouvelle commence — ponctuation forte à gauche **ET** majuscule à droite
    (les deux conditions ; la fragmentation qu'on corrige laisse presque toujours
    le second morceau en minuscule) ; (4) **jamais** autour d'un fragment sans
    aucun caractère alphanumérique (`. . . .`), qui reste un **tour isolé** et
    n'est jamais retiré du texte servi — le recollage n'enlève que des
    *frontières*, jamais du contenu. Jonction : un **espace simple**, aucune
    ponctuation ajoutée ni retirée (une ponctuation forte de fin de fragment est
    **conservée** — elle vient du transcripteur, et le matcher ne tokenise pas la
    ponctuation) ; pas d'espace devant `,.…)]}%` ni après une élision/trait
    d'union. Les **mots** coupés en deux (bug corrigé le 2026-07-04) ne sont
    **jamais** réparés, et les transcriptions ratées de bout en bout (`stanno
    mal.`, marqueurs contenant des lettres comme `<noise>`) ne sont **pas**
    rattrapées : notre découpage ne les a pas cassées.
  - Mesure sur les 35 sessions réelles : 749 → 398 tours (-46,9 %), tours
    candidat 461 → 183 (-60,3 %), médiane 6 → 14 tokens par tour candidat,
    tours candidat sous 4 tokens 26,9 % → 15,3 %. Sur 388 frontières « même
    locuteur », **37 sont refusées** par les garde-fous 3 et 4 (34 + 3).
- **Filet « marqueur A2 vendu comme levier d'un palier supérieur »**
  (`EvaluationPalierMarqueurFilter`, livré **ACTIF** le 2026-08-08, EE **et** EO).
  Purge les phrases de `suggestions`, `points_a_ameliorer` et
  `exemples_corriges[].gain` qui présentent un moyen classé **A2 par la grille
  active** (`et`, `mais`, `alors`, `aussi`, `après`, `parce que`) comme la clé du
  **B1/B2** — verbatims réels : « une subordonnée causale avec « parce que »,
  marqueur attendu au B1 ». Le propriétaire a suivi ce conseil, resoumis, **même
  note** : structurellement incapable de faire progresser. **Ni note, ni niveau, ni
  seuil** (appliqué après `applyPlafonds`, d'où il tire le niveau constaté) ⇒ aucune
  campagne requise. Deux conditions dans la **même phrase** : revendication d'un
  palier **> A2** (B1/B2 nommés, ou formule relative si constaté ≥ A2 — depuis A1
  « gagner un niveau » vise A2, ce que la rubrique **ordonne**) **et** marqueur
  **désigné** (cité seul, ou « parce que » précédé d'un mot de désignation à ≤ 25
  caractères). **Mesuré sur les 707 champs de restitution des 138 évaluations en
  base : 5 phrases purgées, toutes fautives, 0 faux positif** ; deux variantes plus
  larges rejetées sur ces mêmes données (« marqueur dans n'importe quelle citation »
  effaçait un conseil B2 sur l'objection traitée ; « désignation + n'importe quel
  marqueur » effaçait un conseil sur le passé composé). Jamais touchés :
  `justification_niveau`, `exemple.avant`, `exemples_corriges[].original`,
  `scores_criteres[].commentaire`. Liste fermée en Java, **miroir vérifié par
  `EvaluationPalierMarqueurRubriqueTest`** contre la rubrique active. Purges comptées
  par `EvaluationPurgeMetrics` (distinct de `EvaluationRefusalMetrics` : un refus
  coûte la tâche, une purge retire une phrase).
- **Même filet sur `version_ciblee.ce_qui_manque`** (`VersionCibleeLevierFilter`,
  livré **ACTIF** le 2026-08-08). Le défaut existait **aussi** dans le 2ᵉ appel —
  mesuré en base : **2 blocs, 6 leviers, 1 fautif** (« Relier les phrases avec des
  connecteurs simples : « et », « mais », « donc » » sous `niveau_vise: B1`).
  Devenu urgent depuis que les fronts n'affichent plus `version_amelioree` :
  `version_ciblee` est **LE** texte modèle d'un résultat EE, leviers en dessous.
  Détection **partagée** (`EvaluationMarqueursA2.designe`, extraite à la 2ᵉ
  occurrence, porte aussi `MARQUEURS_A2`) ; la condition « palier revendiqué » est
  ici **le champ structuré `niveau_vise`**, pas une devinette dans la phrase → on
  purge dès que `niveau_vise > A2`, jamais si `= A2`. Le levier tombe **en entier**
  (un demi-levier ne s'applique pas). **Nouveau garde-fou commun aux deux filets** :
  tout ce qui suit une formule de **rejet** (`au lieu de`, `plutôt que`, `à la place
  de`, `au-delà de`, `remplacer`, `éviter`) est ignoré — sans lui, notre propre ancre
  few-shot « … au lieu de poser « mais » seul » se purgeait elle-même. Reste < 2
  leviers ⇒ **une** réparation actionnable (`VersionCibleeRepairPrompt.pourLeviers`,
  nomme le levier refusé + les moyens > A2), puis **abandon du bloc** ; **une seule
  réparation par bloc, tous motifs confondus** (longueur ou leviers). Compté
  `EvaluationPurgeMetrics.MARQUEUR_PALIER_LEVIER`, à part de `MARQUEUR_PALIER`.
  Consigne ajoutée en parallèle dans `production-version-ciblee-rubrics-v1.json`
  (prompt récent, non figé par un contrat de notation) — mais c'est le contrôle qui
  tient la règle. Invariant best-effort intact, aucune campagne requise.
- **Bornes de longueur = `ProductionTextBounds`** (`util/`), source unique partagée
  par `ProductionEvaluationService.validateTextWordCount` et le second appel
  « version au niveau visé ». Motif : `version_ciblee.texte` faisait **63 et 64 mots**
  sur une tâche EE T1 à `mots_max=60` — un modèle **non soumettable** sur notre propre
  plateforme, la seule garde étant une consigne de prompt. Désormais bornes injectées
  dans le prompt **et** recomptées serveur (`ProductionPayloadSupport.countWords`,
  **sans tolérance** — celle de 20 % ne vaut que pour les leviers). Hors bornes ⇒
  **une** réparation actionnable (`VersionCibleeRepairPrompt` : compte obtenu, bornes,
  mots à retirer/ajouter, « ne coupe pas en cours de phrase »), puis **abandon du
  bloc** — on ne tronque **jamais** un texte modèle. Une violation **structurelle** ne
  vaut toujours **aucun** second appel payé. Invariant best-effort intact.
- **Filet déterministe de langue étrangère à l'oral** (`EvaluationOralArtifactFilter`,
  volet LANGUE, livré **ACTIF** le 2026-08-07). Le transcripteur temps réel (Gemini
  natif-audio) hallucine des passages en langue/écriture étrangère — **6
  transcriptions realtime sur 39**, contre **0 sur 36** côté Whisper, où la langue est
  imposée ; l'API Live ne permet **pas** de l'imposer à l'entrée, et les modèles
  natif-audio rejettent un code de langue. Le correcteur l'imputait au candidat dans
  **5 évaluations EO sur 72** (« *Éviter de passer à une autre langue pendant
  l'épreuve* »). Le serveur retire ces phrases de `scores_criteres[].commentaire`,
  `points_a_ameliorer`, `suggestions`, `points_forts`,
  `accomplissement.objectif_resume` et `exemples_corriges`, pose
  `AVERTISSEMENT_LANGUE`, et **ne touche ni la note, ni le niveau, ni un seuil**.
  - **Jamais `confiance_raisons`** : « transcription partiellement incertaine
    (passages en russe et en néerlandais) » est le **bon** comportement — là, la
    langue étrangère est une limite d'**observation**. **Jamais en EE** : à l'écrit le
    candidat tape chaque mot, une langue étrangère est une vraie non-réalisation.
    L'asymétrie vient de la **machine**, pas du niveau exigé.
  - **Garde-fou contre la neutralisation d'une VRAIE bascule de langue** (piège
    `AUTRE_LANGUE` du corpus) : deux mesures sur les seuls tours `Candidat :` —
    lettres non latines ≤ **15 %** ET mots-outils étrangers ≤ **6 %**, avec ≥ **40**
    mots exploitables. Au-dessus de l'un **ou** l'autre, ou en cas de doute, **on ne
    purge rien**. Calibré sur les données réelles : artefacts ≤ 6,8 % / ≤ 1,4 %, piège
    espagnol à 12,5 %. ⚠️ **Le ratio de mots-outils FRANÇAIS ne sépare pas** — le
    piège en affiche 36 %, plus que 8 vraies transcriptions françaises (les langues
    romanes partagent trop de petits mots) ; d'où
    `ProductionValidityService.MOTS_OUTILS_ETRANGERS`, miroir de `MOTS_OUTILS_FR`,
    verrouillé par test.
  - **Rubriques v10 et v11 : écrites, mesurées MOINS BONNES que v9, NON ACTIVÉES, ne
    pas réessayer cette voie.** Elles répondaient au même problème par une **consigne**
    — illustration directe de la règle « les contraintes dures priment sur les
    consignes ». Campagne du 2026-08-07, témoin v9 du même jour, même modèle,
    `retries=1` : accord exact 81,8 % (v9) contre 75,6 % et 76,7 % ; échec en
    production 8,33 % contre 14,58 % et 10,42 % ; pièges 7/8 contre 4/8 et 5/8. v10
    remontait en plus un hors-sujet de `A1_NON_ATTEINT` à `A1` : le bloc ajouté
    (+4197 caractères) **diluait la sévérité du reste**. Elles restent chargeables.
  - **Persona `realtime-personas-v3.json`** (défaut) = v2 + verrou de langue dans la
    system instruction. **Biais, pas garantie**, et non mesurable au banc.
  - Frontières assumées : la purge ne se déclenche que sur un marqueur d'une **liste
    fermée** (une formulation qui y échappe passe) ; `MOTS_OUTILS_ETRANGERS` couvre 6
    langues, une vraie production en turc ou polonais n'est protégée que par le
    contrôle amont `ratioMotsOutils < 0,10`.
- **Deux drapeaux livrés ÉTEINTS** (`sejourfr.production-evaluation`) :
  `fluidite.enabled` (débit/pauses, informatif) et `seconde-passe.enabled` (2ᵉ
  lecture en zone floue, même provider/modèle). À `false`, ils ne changent
  **rien**. Les `plafonds`, eux, sont **actifs**.
- **`coherence-bilan.enabled` est ACTIF depuis le 2026-08-05** (défaut `true`
  dans `application.yaml` **et** dans le POJO, pour qu'ils ne divergent pas) :
  pas de B2 au bilan d'épreuve si T3 < B1. Motif : le niveau d'une épreuve est
  la **moyenne pondérée des compétences** des 3 tâches
  (`ProductionBilanService.compute`, qui a remplacé un ancien `min()`), or les
  tâches ne sont pas interchangeables — T3 est la seule qui demande
  d'argumenter, donc la seule qui puisse démontrer un B2. Le garde-fou ne peut
  qu'**abaisser**, jamais relever : c'est ce qui le rend sûr. Généralisable
  palier par palier (liste de couples `tache3-min`/`plafond`) sans réécrire le
  calcul — forme proposée dans le javadoc de `CoherenceBilan`, **non
  implémentée**. ⚠️ **Activé sur du raisonnement, pas sur une mesure** : le
  corpus du banc porte un niveau attendu **par tâche**, il n'a aucune référence
  de niveau d'**épreuve** — il ne peut structurellement pas arbitrer ce choix.
  Le vérifier demanderait un jeu de cas « 3 tâches + niveau d'épreuve attendu »,
  qui n'existe pas. Détail : `docs/notation-ia-eo-ee.md` §6.5 bis.
- **Niveau d'un examen blanc TCF complet** : `finalCecrlLevel` est le **plancher
  ordinal des 4 épreuves** (`FullTcfExamResponseBuilder.floorOfCecrls`), plafonné
  B2 — à ne pas confondre avec le niveau d'une **épreuve**, qui est une moyenne
  (d'où « Niveau global » au bilan d'épreuve, « plancher » au bilan d'examen
  complet ; les deux libellés sont exacts, chacun chez lui). Sont **hors
  périmètre** du plancher une épreuve `locked` (verrou freemium — elle n'a pas
  été passée, la compter `A1_NON_ATTEINT` revenait à dire à un compte gratuit
  qu'il n'atteint pas le A1 parce qu'il n'a pas payé) et une épreuve à
  `cecrlLevel` null (évals FAILED ou en vol) : **null = inconnu, jamais mauvais**.
  Une épreuve **abandonnée sans verrou** (chrono écoulé, rien rendu) reste,
  elle, comptée `A1_NON_ATTEINT` — elle a été passée et ratée. Partialité
  exposée aux fronts par `epreuvesCountedInFinalLevel` / `epreuvesExpected` /
  `finalLevelPartial` (+ `finalLevelPartial` sur le résumé) : aucun front ne doit
  plus écrire « le plus bas de tes 4 épreuves » en dur, ni agréger un examen
  partiel dans un « meilleur niveau » sans l'annoter. V024 a remis à NULL les
  `final_cecrl_level` déjà persistés à tort sur les examens verrouillés.
- **Incohérence de règle connue, non tranchée** : `TcfProfileService`
  (profil par épreuve) applique un **plancher** là où `ProductionBilanService`
  (bilan d'épreuve) applique une **moyenne**. Les deux décrivent pourtant « le
  niveau de l'épreuve ». À arbitrer.

## Module « Compétences TCF » (micro-entraînement EE/EO)

Voie **parallèle** aux productions complètes, pas une réutilisation : le candidat
travaille **une micro-compétence à la fois** sur un « petit sujet » de quelques
phrases, et l'IA ne rend qu'un **verdict sur le critère unique du sujet** —
**aucune note /20, aucun niveau CECRL** (le tool-schema ne prévoit aucun champ
pour les loger). Schéma en `V025`, contenu seedé en `V300..V305`.

**Où ça vit** — tables `skills`, `skill_prompts`, `skill_references`,
`user_skill_attempts` (DDL `00_schema/V025__schema_competences_tcf.sql`, seed
`300_tcf/competences/V300..V305`). Backend : `service/competence/` (analyse IA) +
`SkillService` / `SkillAttemptService` / `SkillStatusResolver` /
`SkillAnalysisAccessService` / `AdminSkillService`. **12 endpoints utilisateur**
(`/api/skills*`, `/api/skill-attempts*`, `/api/skill-prompts*`) et **11 endpoints
admin** (`/api/admin/skills*`, `/api/admin/skill-prompts*`) — détail dans
`docs/api-endpoints.md`. Fronts : web `app/_components/competences/` + routes
`…/entrainement/tcf/{ee,eo}/tache/[n]/competences/…`, mobile
`lib/screens/tcf_production/competences/` + `core/models/skill_models.dart` ;
point d'entrée = 3ᵉ onglet « Compétences » à côté de « Sujets » et « Exemples »,
qui **pousse** vers le nouvel écran au lieu d'ouvrir un onglet local.

- **Contrat de l'analyse IA** : rubriques
  `prompts/competence-analysis-rubrics-v2.json` + tool-schema
  `prompts/competence-analysis-tool-schema-v2.json` (**v2/v2 = v1/v1 plus la règle
  d'accentuation, même technique et mêmes verrous que v13/v7 côté productions** ;
  v1/v1 reste chargeable via `COMPETENCE_RUBRICS_VERSION=v1` +
  `COMPETENCE_TOOL_SCHEMA_VERSION=v1`) (`profile: TCF_IRN`, paire
  `rubrics-version` ⇄ `tool_schema_version` validée au boot, même convention que
  les productions complètes — **aucune consigne de notation en dur dans le Java**).
  Sortie stricte à **5 champs**, `additionalProperties: false` : `status`
  (`VALIDATED|PARTIAL|NOT_VALIDATED`), `verdict`, `success_point`,
  `improvement_priority`, `improved_version`. **Une seule** priorité
  d'amélioration, jamais une liste. Contraintes de longueur **en mots** déclarées
  par la grille (20 / 30 / 35), doublées de `maxLength` en caractères dans le
  schéma ; le validateur tolère ×1,2 avant de rejeter. Sortie invalide → **un seul
  rejeu** avec les violations, puis **échec net** (`FAILED`) — jamais d'analyse
  partielle.
- **Config** : `sejourfr.competences.analysis` (`max-tokens: 600`,
  `temperature: 0`, `free-analyses: 3`, `max-text-words: 400`,
  `max-audio-duration-seconds: 180`), POJO `CompetenceProperties` **aux mêmes
  valeurs par défaut que le YAML**. Le **fournisseur LLM n'a pas de réglage
  propre** : `CompetenceLlmConfig` lit
  `sejourfr.production-evaluation.provider`, comme tout le reste (règle « un seul
  correcteur configurable »). Ne pas lui en donner un second.
- **Volume figé** : 6 tâches (`EE1..EE3`, `EO1..EO3`) × **8 compétences** × **5
  sujets** × **3 références** (`INSUFFICIENT`/`EXPECTED`/`EXCELLENT`) = 48 / 240 /
  720. Les 6 tâches sont un référentiel officiel (**enum `SkillTaskCode`, pas de
  table**). Ce compte est verrouillé par **`SkillSeedIT`**, pas par le DDL : la
  contrainte `display_order BETWEEN 1 AND 8` gelait le catalogue (les 8 rangs
  légaux étant tous seedés, l'admin ne pouvait plus rien créer) — elle est passée
  à **50**, et la règle produit vit désormais dans le test. Ne pas la remettre.
- **Les seeds sont GÉNÉRÉS**, jamais écrits à la main. Le générateur est
  **versionné** dans `backend_sejourfr/tools/competences/` (`generer_seed.py` +
  `contenu/*.json`, une fiche par tâche) et se rejoue par
  `cd backend_sejourfr && python3 tools/competences/generer_seed.py` (Python 3
  seul, aucune dépendance). **On édite le JSON puis on régénère, jamais le SQL** :
  modifier un `V300..V305` à la main désynchronise les deux et la régénération
  suivante écrase le correctif. Le script valide le contenu (8×5×3, cohérence
  EE mots / EO durée, unicité des codes) et **refuse de générer** sur du contenu
  non conforme ; les UUID sont déterministes (uuid5 sur le code métier), donc
  stables d'un environnement à l'autre.
  - Il ne sert qu'à **republier depuis une base propre**. Une fois les migrations
    appliquées, le **contenu vivant s'édite depuis la console d'administration**
    (`admin/features/skills/`) — c'est la base qui fait foi, pas le JSON.
  - Le générateur a vécu hors dépôt jusqu'au 2026-08-06 : les six migrations
    portaient « ne pas éditer à la main » sans que le seul outil autorisé à les
    produire soit trouvable.
- **Deux textes distincts sur une compétence**, à ne jamais rendre au même
  endroit : `skills.description` = la courte explication (encart « Pourquoi cet
  exercice ? »), `skills.general_criterion` = le critère général travaillé (encart
  « Critère travaillé »). Et **ni l'un ni l'autre** n'est
  `skill_prompts.unique_criterion`, qui est le critère précis d'**un** sujet.
- **Freemium** : produire, s'auto-évaluer et lire les 3 références est **gratuit
  et illimité** pour tout compte inscrit — **aucun sujet n'est verrouillé**. Seule
  l'**analyse IA** est premium (`hasTcf`), avec **3 analyses offertes à vie**. Le
  quota se consomme à l'**acceptation** (`analysis_requested = true`), pas au
  succès : sinon un retry après échec fournisseur en offrirait davantage.
- **Statut d'un sujet dérivé serveur**, jamais recalculé par un front
  (`SkillStatusResolver`) : `TODO` / **`TREATED`** / `VALIDATED` / `TO_REINFORCE`.
  `TREATED` (« Fait ») est le 4ᵉ statut qu'impose le freemium — une production
  sans analyse n'a pas de verdict, l'afficher « Validé » ou « À renforcer » serait
  faux.
- **Libellés FR = contrat gelé sur les 4 couches.** Ces chaînes ne transitent pas
  par le réseau : le backend, le web, le mobile et l'admin en tiennent chacun une
  copie écrite à la main, donc rien n'empêche une couche de dériver — et c'est
  arrivé (`NOT_VALIDATED` affiché en trois formulations différentes). Elles sont
  désormais figées par un test **par couche**, sur exactement les mêmes chaînes :
  `SkillLabelsTest` (backend), `lib/skill-labels.test.ts` (web),
  `test/skill_models_test.dart` (mobile). Un libellé qui bouge, ce sont **quatre**
  fichiers à changer dans la même passe. Côté fronts, on lit toujours la constante
  partagée (`SKILL_*_LABEL` en TS, le `label` de l'enum en Dart) — jamais une
  chaîne recopiée dans un composant, qui est exactement la façon dont le web avait
  décroché.
- **Garde des références** : `GET /api/skill-prompts/{id}/references` exige **au
  moins une tentative**, jamais « une tentative réussie » — l'écran de résultat
  d'une tentative `FAILED` est précisément le moment où le candidat en a besoin.
- **`POST /api/skill-attempts/{id}/analyse`** : demande l'analyse d'une production
  déjà `RECORDED` (rendue sans IA), pour le candidat qui produit gratuitement puis
  s'abonne — sans elle, il devait refaire le sujet et **perdait sa production**.
  Refusé (422) sur tout autre statut, sinon le quota serait contournable.
- **`POST .../retry`** ne re-consomme pas le quota (l'échec n'est pas du fait du
  candidat) : c'est ce qui **impose** le plafond persisté `retry_count` ≤ 3,
  appliqué dans le service (422) **et** en base.
- **Transcription Whisper seulement si une analyse est demandée** (on ne paie pas
  pour un audio que personne ne corrigera) ; l'**audio est conservé dans tous les
  cas** — les deux fronts doivent permettre de se réécouter sur l'écran de
  résultat EO. Pipeline async **sans transaction englobante**, même invariant que
  `ProductionPipelineAsyncRunner` (+ `SkillAnalysisFailureRecorder` en
  `REQUIRES_NEW` pour rendre `FAILED` durable).
- **Garde-fou EO, identique à celui des productions complètes** : la **durée n'est
  jamais envoyée** au correcteur, et la grille lui interdit de fonder verdict ou
  conseils sur la prononciation, l'accent, l'intonation, le débit, la fluidité,
  l'aisance, les pauses, les hésitations transcrites, l'orthographe ou la
  ponctuation d'une transcription automatique. Ne pas relâcher d'un côté ce qui
  est verrouillé de l'autre.
- **Rate-limit dédié** `RateLimitGuard.checkSkillAttempt` (`skill-attempt:burst`
  40 / 10 min, `skill-attempt:daily` 400 / jour) : borne le coût LLM **et**
  l'inflation de `user_skill_attempts`. Bornes anti-abus (≠ règles pédagogiques,
  les `recommendedMin/MaxWords` restent **indicatifs et jamais bloquants**) :
  400 mots en EE, 180 s en EO, taille audio max partagée avec
  `production-evaluation`.
- **Libellés gelés du bandeau « Sujet déjà traité »**, une seule action par
  section : EE « Reprendre ma réponse » (préremplit), EO « Écouter ma dernière
  réponse » (ouvre le résultat).
- `SkillPromptDto` porte `skillPromptCount` / `skillDescription` /
  `skillGeneralCriterion` / `skillTargetLevel` **exprès** : l'écran de production
  affiche le fil d'Ariane « Sujet i/5 », l'encart d'explication et le palier
  **sans second appel** à `GET /api/skills/{skillId}`.

## Identité visuelle (résumé)

- Bleu France `#1E3A8C` + Rouge France `#E1372F` (CTAs critiques seulement).
- **Plus Jakarta Sans** (web/mobile) ou **Inter** (admin), **Fraunces** (titres, `<em>`
  toujours rouge), **JetBrains Mono** (labels techniques, badges).
- **Règle absolue** : jamais hardcoder couleur ni font. Toujours passer par les tokens
  locaux (`var(--color-*)`, `AppColors.*`, `AppFonts.*`).

Détails complets (palette, dark/light, logo) → `docs/identite-visuelle.md`.

## API backend partagée

Base : `http://localhost:8080`. CORS dev autorise `localhost:3000` (web) et `localhost:5173`
(admin). Auth JWT Bearer (access ~60 min + refresh 30 j), **refresh automatique** dans le
client HTTP de chaque front.

Liste complète des endpoints → `docs/api-endpoints.md`.

## Démarrage local

```bash
# Backend (depuis backend_sejourfr/)
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
# DB : Postgres local, db = sejourfr_db, user = diallomatine (cf. application-dev.yaml)
# Mail : MailHog sur localhost:1025 (UI http://localhost:8025)
# Tests : ./mvnw verify  (unitaires *Test via surefire + intégration *IT via failsafe).
#   Les *IT tournent sur un Postgres EMBARQUÉ (Zonky, pas de Docker) qui applique les
#   vraies migrations Flyway. Profil `test`, base AbstractIntegrationTest + fabriques
#   TestData. Détails + gabarits : docs/plan-tests-backend.md.

# Admin (depuis admin_sejourfr/)
npm install && npm run dev-admin   # ⚠️ script "dev-admin", pas "dev"

# Web (depuis web_sejoufr/)
npm install && npm run dev-web   # ⚠️ script "dev-web", pas "dev"

# Mobile (depuis mobile_sejourfr/)
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8080   # iOS sim
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080    # Android emu
```

## Comptes seed (profil dev uniquement)

| Email                    | Mot de passe | Rôle  |
|--------------------------|--------------|-------|
| `admin@sejourfr.fr`      | `Admin123!`  | ADMIN |
| `user@sejourfr.fr`       | `User123!`   | USER  |
| `karim.test@sejourfr.fr` | `User123!`   | USER  |

## Architecture mentale par projet

Tous les fronts suivent l'organisation par feature (miroir du backend Java) :

- **Backend Java** : `entity/`, `repository/`, `manager/`, `service/`, `controller/`,
  `dto/`, `mapper/`, `specification/`, `security/`, `config/`, `exception/`, `enums/`
  (+ sous-module historique `audioquestion/` à part)
- **Admin React** : `features/{questions,themes,conversations,dashboard}/` + `api/`,
  `auth/`, `components/ui/`, `routes/`, `types/`
- **Web Next** : `app/{inscription,connexion,examen-blanc,paiement}/` + `app/_components/`
  + `lib/{api,types}.ts`
- **Mobile Flutter** : `screens/{auth,home,training,exam,question_runner,review,profile,…}/`
  + `core/{api,auth,models,router,theme,utils,widgets}/`

Le **runner de questions** (mobile `screens/question_runner/` et web
`examen-blanc/page.tsx`) est le composant le plus complexe — relire son CLAUDE.md local
avant de toucher.

### Convention backend Java : Controller → Service → Manager → Repository (strict)

- **Controllers** : ultra-fins, délèguent tout au service. Pas de logique, pas de mapping
  inline, pas d'accès repo. `@RequiredArgsConstructor` Lombok.
- **Services** : orchestrent un cas d'usage (validations, règles métier, transactions,
  mapping DTO). N'accèdent JAMAIS un `*Repository` directement — passent par les managers.
  Un service peut appeler plusieurs managers et d'autres services.
- **Managers** (`manager/`) : seule couche autorisée à appeler les `*Repository`. Wrappent
  JPA et exposent une API métier. Un manager par agrégat, même pour du CRUD trivial. `int
  limit` au lieu de `Pageable` quand suffisant ; `Specification + Pageable` quand la
  recherche est dynamique.
- **Mappers** : `@Component`, purs. Reçoivent l'entité + compléments en paramètres,
  retournent un DTO. Ne touchent ni repo ni manager. Si un mapping a besoin d'une lookup,
  le service la fait avant.
- **Lombok** : `@RequiredArgsConstructor` sur tous les controllers/services/managers/mappers.
  `@Slf4j` au lieu du `LoggerFactory.getLogger(...)`. Sur les entités JPA : `@Getter/@Setter`
  OK, **jamais `@Data`** ni `@EqualsAndHashCode` automatique (toString/equals + lazy loading
  = bugs).
- **Exception** : `audioquestion/` est un sous-module isolé non migré (refacto reportée).
  Ses services peuvent encore appeler `MediaRepository` direct.

## Préférences de collaboration (durables — à respecter à chaque tâche)

- **Pas de README ni de docs générés automatiquement.** Ne créer un `.md` que si
  l'utilisateur le demande.
- 🛑 **Aucun test ni aucune mesure qui appelle un LLM payant sans demande explicite
  de l'utilisateur.** Vaut pour le banc de calibration (`CalibrationBenchTest`) et
  pour tout script qui interroge un fournisseur. C'est son argent. On propose la
  mesure et son coût estimé, il décide. Un smoke test d'un ou deux appels pour
  vérifier qu'une chaîne technique répond est toléré ; une campagne ne l'est pas.
  Avant de lancer une analyse, se demander d'abord si une **requête SQL sur la base
  locale** répond à la question — c'est gratuit, immédiat, et c'est le plus souvent
  le cas quand il s'agit de regarder ce que l'IA a réellement produit.
- **Code direct + brèves explications.** Pas de récap de fin de message ni de narration
  d'étapes triviales.
- **Décisions structurantes** : proposer des options avec leurs tradeoffs, pas imposer.
- **Pas de Tailwind utility-first dans le markup web** — Tailwind v4 sert uniquement aux
  tokens via `@theme`. Styles dans `globals.css` ou `<style>` JSX scoped.
- **Responsive obligatoire (web + admin)** : tout écran fonctionne du mobile (~360 px) au
  desktop. Tester mentalement 360 / 768 / 1280 minimum. Pas de largeur fixe en px sans
  `max-width: 100%`, pas de grilles à colonnes fixes sans `@media` de repli, pas de
  tableaux sans alternative carte sur petit écran.
- **Admin & runner** : pas d'UI kit, pas de CSS-in-JS, pas de `clsx`. CSS Modules vanilla.
- **Mobile** : Riverpod uniquement (pas de Bloc/Provider/GetX), `context.go/push`
  (jamais `Navigator.push`), `withValues(alpha:)` (pas `withOpacity`).
- **Tous** : TypeScript/Dart strict, pas de `any`/`dynamic`, imports relatifs, pas de
  commentaire qui paraphrase le code.

### Mode agent par défaut — Claude est l'ORCHESTRATEUR (non négociable)

**Toute demande de travail part dans un agent, jamais exécutée inline.** Claude principal ne
code pas, ne fouille pas, ne lit pas les fichiers en masse : il **délègue, suit et
synthétise**. Le but est que l'utilisateur puisse **enchaîner les demandes sans attendre**.

**Règle de dispatch — à appliquer à chaque nouveau message :**

1. **Nouvelle demande ⇒ nouvel agent.** On lance immédiatement, sans demander confirmation.
2. **Avant de lancer, vérifier les collisions** avec les agents **en cours** : même
   sous-projet ? mêmes fichiers ? même surface partagée (DTO, endpoint, règle métier, enum,
   rubrique de notation, migration) ?
   - **Aucune collision** → lancer **en parallèle** tout de suite. Plusieurs agents
     indépendants se lancent dans **un seul message** (appels d'outils groupés).
   - **Collision possible** → **file d'attente**. Ne pas lancer, annoncer explicitement à
     l'utilisateur : *« mis en attente, dépend de l'agent X en cours »*. Démarrer dès que
     l'agent bloquant a rendu.
   - **Dans le doute, on met en attente.** Deux agents qui éditent le même fichier =
     conflit silencieux, c'est le pire cas.
3. **Toujours annoncer l'état** en fin de réponse : ce qui tourne, ce qui attend et pourquoi.
4. **Isolation `worktree`** dès que deux agents écrivent en parallèle sur le même
   sous-projet et qu'on ne peut pas les séquencer.
5. **Modèle** : `opus` par défaut pour tout agent qui touche à une refonte, une règle métier
   ou plusieurs fichiers. `sonnet` acceptable pour les petits agents UI ciblés ou une
   recherche simple.
6. **Restitution** : le rapport d'un agent n'est pas montré à l'utilisateur. Claude en
   extrait **la conclusion utile**, pas les dumps de fichiers.

**Ce qui reste chez Claude principal** (ne pas déléguer) : les réponses conversationnelles et
les demandes de clarification, les **arbitrages et décisions** (on ne délègue pas un choix
produit), la synthèse des retours d'agents, et la mise à jour de ce fichier.

**Ce qui ne change pas** : un agent hérite de **toutes** les règles de ce CLAUDE.md et du
CLAUDE.md local de son sous-projet — parité web ⇄ mobile ⇄ admin, tests dans la même passe,
hygiène d'architecture, pas de `.md` non demandé. C'est à Claude principal de le rappeler
dans le prompt de l'agent et de **vérifier à la restitution** que ça a été respecté.

### Hygiène d'architecture (non négociable)

La plateforme est faite pour durer, chaque ajout doit préserver une archi propre et
lisible — pas de patch rapide qui s'accumule.

- Tout nouveau fichier prend sa place dans l'arbo `feature/` existante (cf. CLAUDE.md
  local). Si une feature grossit, créer un dossier dédié.
- **Duplication = signal** : à la 2ᵉ occurrence, **extraire** un widget/util/service
  partagé (ex: `hub_widgets.dart`, `paywall_sheet.dart`). À 3 occurrences, c'est de la
  dette.
- **Refonte = suppression immédiate de l'ancien**. Quand un écran/route/composant est
  remplacé, supprimer le fichier + tous les imports + toutes les références CTA dans la
  foulée. Pas de cohabitation "au cas où".
- Respecter la convention de couches du backend Java et les conventions par sous-projet
  documentées dans chaque `CLAUDE.md` local. Pas d'exception "juste pour cette fois".
- **Parité mobile ⇄ web (non négociable)** : les 3 fronts consomment le **même backend** et
  le mobile et le web implémentent **les mêmes parcours** (examen blanc TCF complet, runner,
  productions EE/EO, paywall, freemium…). Toute modif d'une surface partagée — **endpoint**
  (chemin, **query params**, méthode, params devenus requis), **DTO**, **règle métier**,
  **enum** — doit être propagée et **vérifiée des deux (trois) côtés** dans la même passe.
  Avant de fermer une tâche, se demander explicitement : *« est-ce que ce changement casse
  l'autre front ? »* et le corriger s'il le faut. Exemple vécu : rendre `?epreuve=` requis
  sur `POST /api/full-tcf-exams/{id}/begin` côté backend aurait silencieusement figé le
  chrono web (appel best-effort avalé en 400) si le web n'avait pas été mis à jour en même
  temps. Quand un comportement est corrigé d'un côté (ex. ancrage de chrono), vérifier que le
  bug n'existe pas, ou n'a pas été réintroduit, de l'autre. Les miroirs DTO à tenir à jour :
  `admin_sejourfr/src/types/api.ts`, `web_sejoufr/lib/types.ts`, `mobile_sejourfr/lib/core/models/*.dart`.
- **Tout bugfix sur une surface partagée se synchronise sur l'autre front (impératif)** :
  dès qu'on corrige un bug côté **mobile** OU **web** sur un parcours commun (freemium,
  paywall, runner, examens, productions EE/EO, chrono…), il faut **systématiquement**
  vérifier le même comportement de l'autre côté et l'aligner dans la **même passe** —
  soit le bug y existe aussi (le corriger), soit il y était déjà correct (s'en servir de
  référence et ne rien casser). Les deux fronts doivent rester **synchronisés en
  permanence** : aucun fix ne se ferme sans s'être posé la question « web et mobile font-ils
  exactement pareil maintenant, sans régression ? ». Exemple vécu : le slot 1 des examens
  blancs module TCF (CO/CE/STRUCTURE) était bloqué par le paywall sur mobile alors que le
  web l'autorisait déjà (rejouable à volonté) — le fix a aligné mobile + backend sur le
  comportement web, pas l'inverse.

### Tests (non négociable)

**Tout code ajouté ou modifié doit être couvert par des tests, dans la même passe.**
Une feature, un bugfix, une règle métier, un endpoint, une migration à impact logique ne
se ferment pas sans test(s) qui verrouillent le comportement. Avant un refactor d'un bloc
existant non couvert : écrire d'abord le filet de tests, puis refactorer. Pas d'exception
« je testerai plus tard ».

Bonnes pratiques pour ce projet (cf. `docs/plan-tests-backend.md`, infra déjà en place) :

- **Lancer la suite** : `./mvnw verify` (unitaires `*Test` via surefire + intégration `*IT`
  via failsafe). Le build doit rester **vert** — un commit ne part pas sur du rouge.
- **Choisir la bonne granularité** :
  - *Unitaire* (`*Test`, Mockito) par défaut pour la logique métier, les branches, les
    validations, le mapping, les appels à des clients externes (toujours **mockés**, jamais
    de vrai réseau). Gabarit : `FullTcfExamServiceFreemiumTest`, `AiEvaluationServiceTest`.
  - *Intégration* (`*IT extends AbstractIntegrationTest`) quand le cas traverse réellement
    la base (requêtes JPA, specifications, contraintes, transactions). Tourne sur un
    **Postgres embarqué** (Zonky, pas de Docker) qui applique les **vraies migrations
    Flyway** → toute contrainte (NOT NULL, FK, CHECK, index unique) est vérifiée pour de
    vrai, et `ddl-auto: validate` valide le mapping JPA.
- **Tester chaque couche** : manager → `*ManagerIT` (vrai PG) ; service → unitaire ou IT ;
  controller → **droits** via la matrice (`AdminRoutes/AuthenticatedRoutes/PublicRoutesSecurityIT`,
  401 anonyme / 403 mauvais rôle / 200 rôle attendu, avec un vrai JWT) **et** comportement ;
  mapper → unitaire pur ; specification → `*IT`. Un nouvel endpoint admin s'ajoute à la
  matrice de droits.
- **Seeder via `TestData`** (fabriques de toutes les entités, déjà validées) plutôt que de
  bâtir les entités à la main — les fabriques respectent toutes les contraintes du schéma.
- **Assertions tolérantes au seed Flyway** : les tables seedées (questions, production_tasks,
  exam_templates, audio_question_drafts) contiennent déjà des lignes → filtrer aux ids créés
  dans le test ou raisonner en delta, **jamais** de total exact sur une table seedée.
- **Pièges connus** : `repository.save()` ne flushe pas (une violation de contrainte passe
  inaperçue → utiliser `saveAndFlush` quand on veut l'attraper) ; ordre `id ASC` Postgres
  (uuid non signé) ≠ `Comparator<UUID>` Java (signé) ; `when(x).thenReturn(helperQuiMock(...))`
  → `UnfinishedStubbing` (extraire le mock en variable avant le `thenReturn`).
- **Parité fronts** : un test backend qui fige une règle partagée (freemium, quotas, droits)
  est le garde-fou de la cohérence mobile ⇄ web — le maintenir à jour quand la règle évolue.

### Maintenir les `CLAUDE.md` à jour

Après une modif structurante (nouvelle feature, nouveau pipeline, changement de convention,
nouvelle migration importante, nouveau dossier `features/*`), mettre à jour le CLAUDE.md
local concerné et celui de la racine si la modif est transverse. Pas de changelog
exhaustif — juste de quoi qu'un futur Claude se repère vite. Inutile d'y consigner les
bugfixes ou les micro-ajustements.

**Exception — la doc de notation IA doit TOUJOURS être exhaustive et à jour.**
`docs/notation-ia-eo-ee.md` est la référence grand public (compréhensible par un
non-informaticien) de la façon dont l'IA note les productions EE/EO. Contrairement aux
CLAUDE.md, elle **n'est pas** un simple aide-mémoire : elle doit rester **complète et
exacte**. Dès qu'on touche une **règle de notation, un barème, un poids de critère, une
consigne donnée à l'IA** (`production-rubrics-*.json`, `production-evaluation-tool-schema-*.json`),
**une tâche EE/EO**, ou le **comportement de l'examinateur vocal** (`realtime-personas-*.json`,
config VAD), on met à jour ce fichier **dans la même passe**, en gardant un langage clair et
sans jargon non expliqué. Ce n'est pas un « bugfix à ne pas consigner » : c'est une exigence.

## Paiements multi-source (Stripe + Apple + Google)

Le statut Premium est centralisé dans `user_subscriptions` (table backend). C'est
**la source de vérité unique**, alimentée par 3 canaux : Stripe (web), Apple
(iOS, IAP) et Google (Android, Play Billing). Le client ne décide JAMAIS s'il est
Premium — il lit le statut auprès du backend.

**Schéma `user_subscriptions`** (cf. migration V103) :
- `source` enum `STRIPE | APPLE | GOOGLE`
- `external_transaction_id` — id de transaction courant (change à chaque renouvellement)
- `original_transaction_id` — **clé de réconciliation**. Apple: `originalTransactionId`,
  Google: `purchaseToken`, Stripe: `subscription_id` ou `session_id` (one-shot).
  Stable sur toute la chaîne de renouvellements pour un même user/produit.
- `product_id` — SKU côté store ou `Plan.code` côté Stripe
- `auto_renew` — true pour les abonnements récurrents (Apple/Google), false en
  one-shot Stripe (changera au lot 4).
- Statuts : `ACTIVE`, `TRIAL`, `IN_GRACE`, `PENDING`, `CANCELED`, `EXPIRED`, `REFUNDED`.

**Index unique `(source, original_transaction_id)`** : un webhook de
renouvellement update la ligne existante, ne crée pas de doublon. Combiné avec
`processed_external_events` (provider, event_id), c'est la double défense contre
les replays.

**Agrégation Premium** : `SubscriptionService.currentSubscription(userId)` retourne
la souscription "qui compte" en cas de cumul — INTEGRAL > CIVIQUE, puis date de
fin la plus tardive. Exposée via `GET /api/billing/subscription-status`.

**Anti-double-paiement** : un user déjà Premium via Stripe télécharge l'app →
`subscription-status` renvoie `isPremium=true, source=STRIPE` → l'app mobile
masque le bouton d'achat IAP. Pareil dans l'autre sens.

**`GET /api/billing/plans`** expose `realtimeEoSessions` (colonne
`plans.realtime_eo_sessions`, V018/V113) : le nombre de simulations orales en
temps réel ouvertes par le pass — 25 (sprint 6 sem) / 60 (3 mois) / 120 (1 an)
sur Intégral, **0** sur Civique et Free. Les fronts l'affichent tel quel sur les
cartes de tarifs (0 = « sans simulation orale ») au lieu de coder le quota en
dur — il reste éditable côté admin. Miroirs : `web_sejoufr/lib/types.ts`,
`mobile_sejourfr/lib/core/models/billing_models.dart`.

**Endpoints** :
- `GET /api/billing/subscription-status` — authentifié, statut agrégé.
- `POST /api/billing/verify-receipt` — authentifié, l'app mobile soumet un reçu
  Apple/Google après achat. Backend re-vérifie côté store avant d'écrire.
- `POST /api/billing/cancel` — authentifié, résiliation de l'abonnement courant.
  Routing selon `source` via `SubscriptionCancellationService` : Stripe →
  `cancel_at_period_end=true` côté API + statut local CANCELED (réponse
  `action=DONE`) ; Apple/Google → réponse `action=REDIRECT` vers
  `apps.apple.com/account/subscriptions` ou `play.google.com/store/account/subscriptions`
  (les stores n'autorisent pas l'annulation serveur). Le statut local Apple/Google
  N'EST PAS modifié — c'est le webhook qui tranche quand l'user confirme côté store.
- `POST /api/admin/subscriptions/{id}/cancel` — admin (ROLE_ADMIN), même routing
  via `cancelSubscriptionById`. Rejette en 409 si statut non cancellable
  (CANCELED / EXPIRED / REFUNDED). Pour Apple/Google l'admin reçoit le `REDIRECT`
  comme l'user — à charge pour le support de transmettre l'URL au client.

**Emails transactionnels Premium** (`MailService.sendSubscriptionActivatedEmail`
+ `sendSubscriptionCanceledEmail`) :
- **Activation** envoyée une fois lors de la première souscription. Triggers :
  Stripe `handleCheckoutCompleted` quand création neuve ; Apple/Google
  `activateFromReceipt` quand la ligne `user_subscriptions` n'existait pas
  encore (les restaurations sur un originalTransactionId connu n'envoient pas).
- **Premier achat vs prolongation (achat unique)** : `OneTimeAccessService`
  distingue les deux selon qu'un accès de module ≥ était déjà en cours
  (`currentEndForAtLeast`). Premier achat → `sendSubscriptionActivatedEmail`
  (bienvenue) ; prolongation → `sendAccessExtendedEmail` (template
  `access-extended.html`, wording « durées cumulées, accès ouvert jusqu'au … »).
- **Résiliation** envoyée sur transition `oldStatus ≠ CANCELED → newStatus = CANCELED`.
  Triggers : `SubscriptionCancellationService.cancelStripe` (cancel via notre
  endpoint, le webhook qui arrive après ne renvoie pas car oldStatus est déjà
  CANCELED) ; webhook Stripe `customer.subscription.updated` (user annule
  directement dans Stripe), Apple `DID_CHANGE_RENEWAL_STATUS`, Google
  `subscriptionsv2.get` → SUBSCRIPTION_STATE_CANCELED. Pas de mail sur
  expiration naturelle ni sur refund/revoke (sémantique différente).
- **Templates HTML externalisés** dans `backend_sejourfr/src/main/resources/mail/`
  (`layout.html` + un fragment par email : `access-activated`, `access-expiring`,
  `subscription-canceled`, `password-reset`, `email-change`), rendus par
  `MailTemplateRenderer` (placeholders `{{escaped}}` / `{{{raw}}}`). Inline CSS
  (compat Gmail/Outlook) + preheader, logo en image inline CID depuis
  `resources/static/mail/logo.png`. **Tous** les emails clients (y compris reset
  mot de passe + changement d'email) passent par ce layout brandé.
- **Wording achat unique** : aucun « abonnement » / « renouvellement automatique »
  côté client. `sendSubscriptionActivatedEmail(..., boolean autoRenew)` —
  `autoRenew=false` (achat unique : « accès ouvert jusqu'au … ») posé par
  `OneTimeAccessService` ; `autoRenew=true` (récurrent dormant : « prochain
  renouvellement… ») posé par les flux Stripe/Apple/Google abonnement.
  `sendSubscriptionCanceledEmail` n'est déclenché que par ces flux dormants.
- Envoi **asynchrone** (`@Async` sur `sendSubscriptionActivatedEmail` /
  `sendSubscriptionCanceledEmail`, `@EnableAsync` global) : le SMTP est hors du
  chemin critique, donc `verify-receipt`/`cancel` répondent sans attendre l'envoi
  (sinon un SMTP lent/injoignable bloquait la requête ~15-20 s). Un mail raté log
  warn sans propager (cf. pattern reset password).
- `POST /api/billing/webhook` — Stripe (signé HMAC).
- `POST /api/billing/webhooks/apple` — Apple ASSN V2 (JWS signé, à vérifier).
- `POST /api/billing/webhooks/google` — Google RTDN via Pub/Sub.

**État des lots** :
- **Lot 1 (✅ fait)** : schéma multi-source, migration V103, agrégateur,
  endpoints `subscription-status` + scaffolds verify-receipt / webhooks.
- **Lot 2 (✅ fait)** : intégration Apple complète — lib
  `app-store-server-library` 5.2.0, vérif JWS (transactions + notifications +
  renewal info), App Store Server API client. `verify-receipt` branch APPLE
  + webhook `/webhooks/apple` opérationnels (idempotence via
  `processed_external_events`, anti-account-stealing en 409, mapping
  `NotificationTypeV2` → `SubscriptionStatus`). Mapping productId → Plan
  via colonnes `plans.apple_product_id` (migration V104).
- **Lot 3 (✅ fait)** : intégration Google Play Billing complète — lib
  `google-api-services-androidpublisher` + `google-auth-library-oauth2-http`,
  Service Account JSON, `purchases.subscriptionsv2.get` pour l'état autoritatif,
  webhook RTDN via Pub/Sub avec vérification du Bearer JWT (signature, audience,
  email SA). `verify-receipt` branch GOOGLE + webhook `/webhooks/google`
  opérationnels (idempotence via `messageId` Pub/Sub, anti-account-stealing en
  409, mapping `subscriptionState` → `SubscriptionStatus`).
- **Lot 4 (✅ backend fait)** : refonte des plans en abonnements récurrents.
  6 SKUs (Civique + Intégral × mensuel/trimestriel/annuel) + Free. Stripe
  passe en mode `SUBSCRIPTION` (Checkout Session). Stripe Price ID stocké
  sur `plans.stripe_price_id` (migration V105). Webhooks étendus :
  `customer.subscription.created/.updated/.deleted` + `charge.refunded`.
  Endpoint `/payment-link?planCode=<string>` (l'enum `BillingPlan` supprimé).
  Logique extraite dans `service/billing/StripeSubscriptionService` par
  symétrie avec Apple/Google.
- **Lot 4b (à faire, web)** : refonte page `/paiement` avec 3 plans × 3
  périodicités (toggle mensuel/trimestriel/annuel), portail client Stripe
  pour gérer l'abonnement (annuler, changer de plan). API existant
  `/api/billing/plans` renvoie déjà tous les plans actifs.
- **Lot 4c (✅ fait, admin)** : `features/plans/` (table + modal d'édition
  prix/active/store IDs) + `features/subscriptions/` (liste paginée avec
  filtres source/status/module + recherche + modal détail). Backend :
  `GET /api/admin/plans` + `PATCH /api/admin/plans/{id}` +
  `GET /api/admin/subscriptions?…` avec Specifications JPA pour les filtres
  dynamiques + UserSubscriptionMapper.
- **Lot 4d (✅ fait, mobile)** : IAP natif Apple StoreKit + Google Play
  Billing via package `in_app_purchase`. Écran paywall plein écran avec
  toggle périodicité (mensuel/trimestriel/annuel) + 2 cards Civique/Intégral.
  `BillingController` orchestre purchaseStream → verify-receipt → refresh
  AuthUser. Restoration via bouton "Restaurer". L'ancien `openSubscriptionWeb`
  (redirect web) est supprimé — non conforme Apple 3.1.1 dès qu'on vend du
  contenu digital. Cf. `mobile_sejourfr/CLAUDE.md` section "In-App Purchase".
- **Lot 4d (à faire, mobile)** : UI paywall mensuel/trimestriel/annuel,
  branchement package `in_app_purchase`, appel `/verify-receipt` après
  achat, lecture `/subscription-status` au boot.

⚠ **Cassure connue après lot 4** : le web `/paiement` actuel envoie
`?plan=BillingPlan` (CIVIQUE_3MOIS / INTEGRAL_3MOIS) ; il sera 400 jusqu'à
ce que le lot 4b mette à jour l'appel en `?planCode=<string>`.

- **Lot 5 (bascule achat unique — feature-flaggée)** : le produit vend des
  **passes d'accès à durée fixe** (paiement unique, sans reconduction), au lieu
  d'abonnements. Catalogue : Civique 3 mois (9,99) / 1 an (29,99) ; Intégral
  sprint 6 sem (19,99) / 3 mois (35,99) / 1 an (79,99). Modèle : paiement →
  `user_subscriptions` `ACTIVE`, `auto_renew=false`, `ends_at = paiement +
  plans.duration_days` (durée posée par le **backend**, pas le store) ;
  expiration **lazy** à la lecture (`SubscriptionService.isCovering`), pas de
  job. Prolongation cumulative par module (`grantOneTimeAccess`), idempotente
  sur `(source, original_transaction_id)`. **Proration** uniquement à l'upgrade
  Civique→Intégral **côté Stripe** (crédit du reste du pass Civique, on facture
  la différence) — Apple/Google vendent à prix fixe, pas de proration.
  - Backend : `PlanPurchaseType` + `plans.purchase_type`/`duration_days` (V417/
    V418, les 6 plans récurrents passent `is_active=FALSE`, conservés) ;
    `BillingProperties` (`billing.mode`) ; `OneTimeAccessService.grantOneTimeAccess`
    (commun aux 3 canaux) ; Stripe Checkout `mode=PAYMENT` + `price_data`
    dynamique (montant = `plans.price`, **aucun Stripe Price à créer**) ; Apple
    accepte Non-Renewing/Consumable (bypass du garde-fou AUTO_RENEWABLE) ; Google
    `purchases.products.get` + acknowledge, RTDN `voidedPurchaseNotification`.
    `SubscriptionStatusResponse.oneTime` expose la nature aux fronts.
  - Mobile : paywall en **grille de passes** (pilotée par `purchaseType`),
    `buyConsumable` (passes ré-achetables), « Mon accès » sans résiliation.
  - **Affichage des prix (les 3 surfaces)** : le **montant réellement débité**
    est le prix principal (« 19,99 € »), l'équivalent mensuel passe en
    sous-texte (« soit 13,33 €/mois »). Un pass se paie une fois — mettre un
    « /mois » en avant laisse croire à un abonnement. Vaut pour `/paiement`
    (`OneTimePasses`), `/tarifs` (`PassModuleCard`) et le paywall mobile
    (`_PassRow`). Ne pas réinverser sur une seule surface.
  - Stores : produits **Consommables** (Apple) / **managed in-app** (Google),
    product IDs = `Plan.code` (Apple MAJ, Google minuscules). Guide pas-à-pas →
    `docs/setup-paiement-one-time.md`.

> **⚠️ RÉVERSIBILITÉ — ne JAMAIS supprimer le code abonnement (lots 2/3/4).** La
> bascule est pilotée par le flag `sejourfr.billing.mode` (`SUBSCRIPTION |
> ONE_TIME`, env `BILLING_MODE`) **+** le drapeau `is_active` : les deux jeux de
> plans coexistent en base. `StripeSubscriptionService`, les handlers webhook
> récurrents Apple/Google, le toggle paywall et l'écran de résiliation restent
> en place, **dormants**. Revenir aux abonnements selon le succès du projet =
> `BILLING_MODE=SUBSCRIPTION` + réactiver les 6 plans récurrents (`V106`) +
> désactiver les 5 passes. Aucune migration destructive, aucun rebuild.

**Setup Apple (lot 2)** :
1. **App Store Connect → Users and Access → Integrations → App Store Server API**
   → générer une clé. Télécharger le P8 (téléchargeable une seule fois). Noter
   l'`Issuer ID` (team-level, UUID) et le `Key ID` (10 caractères).
2. **Root certs Apple** — déposer dans
   `backend_sejourfr/src/main/resources/apple/`, depuis la section *Root
   Certificates* de https://www.apple.com/certificateauthority/ :
   - `AppleRootCA-G3.cer` (**obligatoire**, chaîne de signature actuelle des JWS Apple)
   - `AppleRootCA-G2.cer` (par sécurité)
   - `AppleIncRootCertificate.cer` (legacy, par sécurité)
   ⚠ L'ancien « Apple Computer, Inc. Root Certificate » n'est plus téléchargeable
   (seule sa CRL subsiste) et n'est plus utilisé — ne pas le chercher.
   `SignedDataVerifier` accepte un `Set` de racines ; seul G3 est réellement
   requis. Ne pas commiter de bouchons : le bean `AppleStoreClient` détecte
   l'absence et reste en mode 503.
3. **Variables d'env** : `APPLE_ISSUER_ID`, `APPLE_KEY_ID`,
   `APPLE_PRIVATE_KEY` (contenu du P8 brut), `APPLE_BUNDLE_ID`,
   `APPLE_APP_ID` (numérique, prod uniquement), `APPLE_ENVIRONMENT`
   (`SANDBOX` en dev / TestFlight, `PRODUCTION` en App Store).
4. **App Store Connect → Subscriptions** : créer les produits IAP (SKUs
   définis au lot 4 quand les abonnements récurrents seront en place), puis
   mettre à jour `plans.apple_product_id` en base via SQL.
5. **App Store Connect → App Information → App Store Server Notifications →
   V2** : pointer Production URL et Sandbox URL sur
   `https://<host>/api/billing/webhooks/apple`.

**Notifications Apple gérées** (`NotificationTypeV2`) :
- `SUBSCRIBED`, `DID_RENEW`, `OFFER_REDEEMED` → status ACTIVE, `expiresDate`
  rafraîchi.
- `EXPIRED`, `GRACE_PERIOD_EXPIRED` → status EXPIRED.
- `DID_FAIL_TO_RENEW` + `subtype=GRACE_PERIOD` → status IN_GRACE.
- `DID_FAIL_TO_RENEW` sans subtype → état inchangé (l'abonnement court jusqu'à
  `expiresDate`).
- `DID_CHANGE_RENEWAL_STATUS` + `AUTO_RENEW_DISABLED` → status CANCELED
  (Premium reste ouvert jusqu'à `expiresDate`).
- `DID_CHANGE_RENEWAL_STATUS` + `AUTO_RENEW_ENABLED` → status ACTIVE si on
  était CANCELED.
- `REFUND`, `REVOKE` → status REFUNDED (Premium retiré immédiatement).
- `REFUND_REVERSED` → ACTIVE si `expiresDate` couvre encore.
- `DID_CHANGE_RENEWAL_PREF` → log seulement (changement pour prochain
  renouvellement, pas d'impact courant).
- Autres types (`PRICE_INCREASE`, `METADATA_UPDATE`, `TEST`, `MIGRATION`,
  `PRICE_CHANGE`, `CONSUMPTION_REQUEST`, `RENEWAL_EXTENDED`, ...) → log debug,
  pas d'impact sur l'accès Premium.

**Limites assumées** : Family Sharing pas géré (un `originalTransactionId`
rattaché à User A est verrouillé sur lui — un autre user qui tenterait avec
le même reçu reçoit 409). Seul `AUTO_RENEWABLE_SUBSCRIPTION` est accepté ; les
NON_CONSUMABLE / CONSUMABLE / NON_RENEWING_SUBSCRIPTION renvoient 400.

**Setup Google Play (lot 3)** :
1. **Google Cloud Console → IAM → Service Accounts** : créer un SA dédié,
   générer une clé JSON. Le SA doit avoir le rôle minimal "Service Account
   User".
2. **Play Console → Setup → API access** : lier le compte Google Cloud,
   accorder à ce SA les permissions "View financial data" + "Manage orders
   and subscriptions" (pour pouvoir lire les abonnements et accepter les
   refunds).
3. **Cloud Console → Pub/Sub** : créer un topic (ex: `play-rtdn`), puis une
   subscription **push** :
   - Endpoint : `https://api.sejourfr.fr/api/billing/webhooks/google`
   - Authentication : activer "Enable authentication", choisir un Service
     Account (peut être un SA dédié à Pub/Sub, distinct de celui du Play API)
   - Audience : URL exacte de l'endpoint (claim `aud` du JWT)
4. **Play Console → Monetization setup → Real-time developer notifications** :
   pointer le Cloud project + le topic créé.
5. **Variables d'env** :
   - `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` (contenu JSON brut de la clé SA)
   - `GOOGLE_PLAY_PACKAGE_NAME` (ex: `com.sejourfr.app`)
   - `GOOGLE_PUBSUB_AUDIENCE` = URL du webhook
   - `GOOGLE_PUBSUB_SA_EMAIL` = email du SA configuré sur la push subscription
6. **Play Console → Subscriptions** : créer les produits IAP (SKUs définis au
   lot 4), puis `UPDATE plans SET google_product_id = ...` en base.

**RTDN gérées** (`subscriptionNotification.notificationType` int + état refetché) :
- Tous types (sauf REVOKED) déclenchent un appel `subscriptionsv2.get` qui
  donne l'état autoritatif. Le mapping `subscriptionState` → `SubscriptionStatus` :
  - `SUBSCRIPTION_STATE_ACTIVE` → ACTIVE
  - `SUBSCRIPTION_STATE_CANCELED` → CANCELED (Premium ouvert jusqu'à `expiryTime`)
  - `SUBSCRIPTION_STATE_IN_GRACE_PERIOD` → IN_GRACE
  - `SUBSCRIPTION_STATE_ON_HOLD` / `PAUSED` / `EXPIRED` → EXPIRED
  - `SUBSCRIPTION_STATE_PENDING` → PENDING (pas de Premium)
  - `SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED` → REFUNDED
- `SUBSCRIPTION_REVOKED` (12) → REFUNDED + autoRenew=false **immédiatement**,
  sans attendre le refetch (l'API peut encore renvoyer ACTIVE temporairement).
- `testNotification` → log, no-op.

**Idempotence Google** : Pub/Sub livre at-least-once. On stocke chaque
`message.messageId` traité dans `processed_external_events` (provider=`google`).
Un replay du même messageId est silencieusement skipé.

**Différence sémantique vs Apple** : la RTDN ne porte PAS l'état détaillé —
juste "ça a changé sur ce purchaseToken". On appelle TOUJOURS l'API
`subscriptionsv2.get` pour avoir l'état autoritatif. Côté Apple à l'inverse,
le `signedTransactionInfo` inclus dans la notification est déjà autoritatif
(JWS signé), pas besoin d'appel API.

**Setup Stripe Subscription (lot 4)** :
1. **Stripe Dashboard → Products** : créer 2 Products ("Civique" et
   "Intégral"). Pour chacun, créer 3 prix récurrents (mensuel / trimestriel /
   annuel). Noter les 6 Price IDs (format `price_xxx`).
2. **Base de données** : `UPDATE plans SET stripe_price_id = 'price_xxx'
   WHERE code = 'CIVIQUE_MONTHLY'` etc., pour les 6 plans créés en V106.
3. **Variables d'env Stripe** simplifiées : `STRIPE_SECRET_KEY` +
   `STRIPE_WEBHOOK_SECRET` + `APP_BASE_URL` (les anciens
   `STRIPE_PRICE_*` / `STRIPE_PAYMENT_LINK_*` ne sont plus lus).
4. **Stripe Dashboard → Webhooks → Add endpoint** : pointer
   `https://api.sejourfr.fr/api/billing/webhook`, sélectionner les events :
   `checkout.session.completed`, `customer.subscription.created`,
   `customer.subscription.updated`, `customer.subscription.deleted`,
   `charge.refunded`.

**Events Stripe gérés** (cf. `StripeSubscriptionService`) :
- `checkout.session.completed` (mode=SUBSCRIPTION) → init UserSubscription,
  fetch la Subscription Stripe et applique son état. Les sessions en mode
  PAYMENT (héritage one-shot) sont ignorées.
- `customer.subscription.created/.updated` → mise à jour de l'état :
  - status `active` + `cancel_at_period_end=false` → ACTIVE
  - status `active` + `cancel_at_period_end=true` → CANCELED (Premium ouvert
    jusqu'à `current_period_end`)
  - status `trialing` → TRIAL
  - status `past_due` / `unpaid` → IN_GRACE (Stripe Smart Retries)
  - status `incomplete` → PENDING
  - status `canceled` → CANCELED (ou EXPIRED si ends_at passé)
  - status `paused` → EXPIRED
- `customer.subscription.deleted` → EXPIRED immédiat.
- `charge.refunded` → REFUNDED (Premium retiré).

**Clé d'unicité Stripe** : `(STRIPE, subscription.id)` (sub_xxx). Stable sur
toute la chaîne de renouvellements. Les events arrivant pour un
subscription_id inconnu (race avec checkout.session.completed) sont logués
et ignorés.

## Git

- Remote : `git@github.com:diallomatine/sejourfr_opus_nouveau.git`
- Branche par défaut : `develop` (PRs vers `main`)
- Le repo racine est **un seul git** qui couvre les 4 dossiers — un commit peut toucher
  plusieurs surfaces (utile quand on aligne un DTO backend avec ses miroirs front).

## Documentation détaillée (`docs/`)

Référence à consulter quand le contexte le demande — pas chargé par défaut :

- `docs/api-endpoints.md` — liste complète des endpoints REST
- `docs/identite-visuelle.md` — palette complète, fonts, logo
- `docs/migrations-flyway.md` — convention de numérotation et arbo `db/migration/`
- `docs/lots-entrainement.md` — lots TCF/Civique (calcul dynamique sans schéma)
- `docs/exams-tcf.md` — examens module (CO/CE) et examen blanc TCF complet
- `docs/auth-social.md` — Google/Apple sign-in (backend + front, config env)
- `docs/setup-paiement-one-time.md` — passes achat unique (lot 5) : setup Stripe/Apple/Google pas-à-pas + SKU
- `docs/pipeline-audio-co.md` — génération audio TCF CO (Claude → Azure Speech → R2)
- `docs/pipeline-evaluation-eo-ee.md` — éval EO/EE (audio/transcription → correcteur configuré → R2 privé)
- `docs/notation-ia-eo-ee.md` — **explication grand public** (non technique) de la notation
  IA de TOUTES les tâches EE/EO : les 6 tâches, critères propres à chaque tâche + poids,
  barème /20 et bandes affichées, obligatoires vs pistes, accomplissement, confiance,
  contrôles automatiques, plafonds, niveau par tâche et bilan, limite assumée de l'oral,
  examinateur vocal + fiche de scénario T2, **banc de mesure et ses chiffres réels (y compris
  ce qui reste faible)**, console de calibration, drapeaux éteints. **À TENIR À JOUR À CHAQUE
  CHANGEMENT** de règle de notation, barème, critère, consigne IA, tâche, seuil, ou
  comportement de l'examinateur vocal — dans la même passe que le changement — et à garder
  **toujours compréhensible par un non-informaticien** (voir aussi la règle dédiée ci-dessous).
- `docs/ia/ANALYSE_SPEC_EVALUATION_IA.md` — décisions produit de la refonte de notation et
  leurs raisons (ce qu'on a retenu de la spec externe, ce qu'on a refusé, et pourquoi)
- `docs/skills/SEJOURFR_SPEC_COMPETENCES_EE_EO.md` — spec fonctionnelle du module Compétences
  TCF : les 48 compétences rédigées une par une, règles de création des petits sujets,
  comportement attendu de l'analyse IA. Le contenu publié fait foi (cf. `SkillSeedIT`) ;
  l'explication grand public de cette voie d'évaluation est dans `docs/notation-ia-eo-ee.md`
  §11 bis
- `docs/refonte-entrainement.md` — statut refonte hubs Civique/TCF (mobile + web)
- `docs/roadmap.md` — roadmap commune (Stripe, refresh JWT web, tests, etc.)
- `docs/audio-pipeline/` — spec exhaustive du pipeline audio CO (10 fichiers)
- `docs/plan-tests-backend.md` — stratégie de tests backend (Postgres embarqué Zonky,
  conventions *Test/*IT, gabarits par couche)
