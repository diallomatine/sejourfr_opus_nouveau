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
- **TargetProcedure** (civique) : `CSP` / `CR` / `NAT`. **Le palier de français exigé
  est porté par l'enum** (`CSP→A2`, `CR→B1`, `NAT→B2`, seuils du 1ᵉʳ janvier 2026) :
  `TargetProcedure.getRequiredTcfLevel()` est LA source de vérité, `TargetProcedure.niveauVise(
  procedure, declare)` applique le **plancher** (`max` sur l'ordre CECRL — NAT+B1 ⇒ B2, CSP+B2
  ⇒ B2, procédure absente ⇒ le déclaré, rien ⇒ null). Ne jamais réécrire cette table ailleurs :
  elle a vécu en 6 copies, d'où un candidat NAT tiré vers le B1. Miroirs **gelés par test de
  chaque côté** — `TargetProcedureTest` ⇄ `web/lib/target-level.test.ts` ⇄
  `mobile/test/target_procedure_levels_test.dart` (technique `SkillLabelsTest`).
  `users.target_level` est **posé par le serveur** au choix de la démarche
  (`MeService.updateTargetProcedure`, seul point d'écriture) et **re-dérivé à la lecture**
  (`AuthenticatedUser.targetLevel`) : aucun front ne peut recevoir un couple contradictoire,
  même sur une ligne héritée. **L'inscription y passe aussi** : `RegisterRequest.targetProcedure`
  est **facultatif** (le web l'envoie depuis l'écran de compte du diagnostic, le mobile a son
  écran `/target-path` dédié) et `AuthService.register` **appelle** `updateTargetProcedure` au
  lieu d'écrire les colonnes — le champ était absent du DTO serveur, donc jeté en silence, et
  les comptes créés en fin de diagnostic sortaient sans démarche ni palier. Une démarche
  inconnue est refusée en **400 nommé** (champ, valeur reçue, valeurs acceptées).
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
    **critère unique** du sujet. **Ni note /20 — jamais —, mais le niveau CECRL est rendu
    depuis le contrat v3** (cf. la section dédiée). `NOT_VALIDATED` ne se dit **pas** « à
    retravailler » : cette formulation était quasi synonyme du statut de sujet `TO_REINFORCE`
    et confondait le verdict d'**une tentative** avec l'état d'**un sujet**.
  - **SkillPromptStatus** : `TODO` / `TREATED` / `VALIDATED` / `TO_REINFORCE` (« À faire » /
    « Fait » / « Validé » / « À renforcer »). **Dérivé serveur** (`SkillStatusResolver`),
    jamais persisté, jamais recalculé par un front.
  - **SituationNiveauVise** : `OBJECTIF_ATTEINT` / `PROCHE` / `EN_CHEMIN` (« Tu as atteint ton
    objectif » / « Tu es proche du niveau visé » / « Encore du chemin vers ton objectif »).
    Compare le `level_reached` d'une micro-production au palier qu'exige la démarche.
    **Dérivé serveur** (`SkillLevelProgressResolver`), jamais persisté, jamais recalculé par un
    front. À ne pas confondre avec `SituationDansNiveau`, qui situe une production **dans son
    propre palier** (« A2 solide ») : celui-ci la situe **par rapport à l'objectif**. Aucun des
    3 libellés ne nomme un manque.
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
  template free). **Examen blanc de MODULE TCF : slot 1 offert aux visiteurs**
  (2026-08-16, `AttemptService.startGuestModuleExam`) — CO / CE / STRUCTURE, un
  seul examen par épreuve, tirage **déterministe** (rejouer redonne le même : on
  n'ouvre pas la banque de questions sans compte). Slots 2-20 → inscription.
  ⚠️ Cette règle **révoque** la précédente (« pages `*/examens` = vitrines,
  tout verrouillé ») **pour ce seul cas**. Restent fermés aux visiteurs, et le
  backend le double d'un 403 : les examens de **thème civique** (`themeId`) et
  **EE/EO**. Ne pas déverrouiller le reste « par symétrie ».
  ⚠️ **Le mobile n'a AUCUN mode invité** (le redirect global renvoie tout
  non-authentifié vers `/login`, allowlist limitée à l'aide, `/about` et le
  diagnostic) : il ne vérifie que l'**abonnement**. L'asymétrie web ouvert /
  mobile compte requis est un **choix**, pas un trou.
- **Purge des attempts invités : écrite, livrée ÉTEINTE**
  (`GuestAttemptPurgeJob` + `sejourfr.guest-attempt-purge.enabled=false`, POJO
  et YAML à la même valeur ; rétention 2 h, lots de 500, cron configurables).
  🛑 **Prérequis avant de l'activer** : ces lignes **sont** la mesure « combien
  de visiteurs se testent ». Les purger sans avoir d'abord un **compteur
  agrégé** (une ligne par jour, patron `page_views` V020) détruit cette donnée
  — le propriétaire a explicitement demandé de la conserver. `user IS NULL` est
  vérifié **deux fois** (sélection puis DELETE), les tables filles partent en
  cascade DB, l'index partiel `idx_attempts_demo_quota` (V006) couvre le
  filtre. Un test vérifie qu'à `false` **rien** n'est supprimé, un autre qu'un
  attempt de compte vieux d'un an est épargné.
- **Compte gratuit, EE/EO** : 1 essai d'entraînement par épreuve à vie + 1
  examen blanc production offert. L'examen est marqué `attempts.slot_number=1`
  au start (`ProductionAttemptStartRequest.exam`) ; ses soumissions bypassent
  le quota d'entraînement. Refaire l'examen 1 = toléré une fois mais consomme
  les essais d'entraînement restants ; une session ne compte que si ≥ 1 tâche
  soumise. Règles dans `ProductionAccessService` (quota, partagé avec la voie
  temps réel) / `AttemptService.startProductionAttempt`. Une **session d'examen
  production est bornée** : chrono d'épreuve **EE 30 min** (l'**EO n'en a plus**,
  elle se chronomètre par tâche — cf. § *Temps des examens blancs*) et **une
  seule soumission par (attempt, tacheNumero)** — un examen, c'est 3 tâches, une
  fois chacune. QCM entraînement : série 1
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
- **Compte gratuit, module Compétences TCF** (micro-entraînement EE/EO) : **une
  seule compétence ouverte par tâche** (la première de sa `SkillTaskCode`, soit
  6 pour les 6 tâches) **+ la compétence de la priorité n°1 du Plan**, et **2
  sujets** par compétence ouverte. Le reste est verrouillé — cadenas côté
  fronts, **403 côté serveur** (`SkillAccessService.assertCanProduce`). Les **3
  analyses IA offertes à vie** sont un verrou distinct, inchangé, qui se cumule.
  Règle posée le **2026-08-10**, elle **révoque** l'ancienne (« aucun sujet n'est
  verrouillé ») ; détail et motif dans la section *Module « Compétences TCF »*.
- **Compte gratuit, Plan personnalisé** : le Plan est **entièrement visible**,
  diagnostic compris. Aucune priorité, aucune compétence observée, aucun
  compteur n'est masqué — seul un `locked` est posé. La compétence de sa
  priorité n°1 reste **ouverte** (cf. ci-dessus), donc l'étape n°1 se
  **commence** sans payer. ⚠️ **Elle ne se termine pas** : une étape vaut 5
  sujets, `FREE_PROMPTS_PER_SKILL` en ouvre 2, donc un compte gratuit plafonne à
  **2/5** et **aucune étape n'est finissable sans abonnement** (arbitré le
  2026-08-11). Cela **révoque** la formulation précédente (« sa priorité n°1 est
  jouable, c'est ce qui garde le Plan utilisable sans abonnement ») : ce qui
  reste gratuit, c'est **lire** son Plan et **commencer** son étape, pas la
  finir. Ne pas « corriger » `FREE_PROMPTS_PER_SKILL` à 5 pour rétablir
  l'ancienne phrase. **Conséquence en cascade, arbitrée le 2026-08-14** : la
  bascule d'une étape en **vérification de progression** exige l'étape
  *terminée*, donc un compte gratuit ne la voit **jamais**, aucune de ses
  compétences n'atteint `SOLID`, et il ne reçoit aucun **jalon** d'examen blanc.
  La vérification est **premium** — c'est un choix produit, détaillé dans la
  section Plan.
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
- **Deux allowlists** dans `PageViewService` : `EVENTS_BY_PATH` borne à la fois
  les chemins et les événements admis sur chaque écran, `KNOWN_SOURCES` borne
  les provenances (tout le reste devient `autre`). L'endpoint d'écriture étant
  public, elles empêchent un tiers de créer des dimensions à volonté. Les pages
  suivies sont `/reussir`, `/diagnostic` et `/plan`.
- **Web** : `lib/audience.ts` garde la détection de provenance ;
  `lib/audience-events.ts` envoie les événements typés. Le funnel diagnostic
  ajoute dix événements : vue/démarrage, fin EE, fin EO, fin d'analyse, vue du
  résultat, ouverture du Plan, lancement de l'exercice recommandé, clic landing
  sociale vers le diagnostic et clic diagnostic/Plan vers Premium.
- **Admin** : `features/audience/` — vues, clics, taux de clic par réseau,
  série journalière et compte brut de chaque événement du funnel, sur 7 / 30 /
  90 jours. `PageViewStatsResponse.events` est un `Map<String, Long>` ; ne pas
  reconstruire le funnel depuis les deux anciens totaux `views`/`ctaClicks`.
- Reste à faire avant l'ouverture publique : un **rate-limit par IP** sur
  `POST /api/public/page-views`, même chantier que la démo invitée. Sans lui, un
  bot peut gonfler un compteur — donnée fausse, mais ni fuite ni inflation de
  stockage.

## Temps des examens blancs — un chrono PAR ÉPREUVE (2026-08-15)

🛑 **Le chrono global de 90 min n'existe plus.** Le temps restant d'une épreuve
**ne se transfère jamais** à la suivante, et l'abandon / reprise entre épreuves
est officiellement supporté : un décompte global devenait absurde (reprendre le
lendemain aurait trouvé l'examen expiré). `FULL_EXAM_TOTAL_SECONDS` est
supprimée, `parent.timer_started_at` survit comme **trace du début réel**, plus
comme ancre d'un décompte. Ne pas la réintroduire.

- **`DureeEpreuve` est la seule autorité** (enum, pas de config : c'est une
  donnée d'examen, pas un réglage) : CO 20 min · **CE 35 min** · EE 30 min ·
  STRUCTURE 20 min. Aucune constante de durée ailleurs.
  `ExamTemplate.durationSeconds` reste prioritaire quand un template pilote
  l'examen. ⚠️ **`FULL_EXAM_CE_SECONDS` est supprimée** : la CE était raccourcie
  à 30 min dans l'examen complet pour tenir dans les 90 min — **une épreuve a la
  même durée où qu'elle soit jouée**, c'est la règle « les conditions
  s'appliquent au module ». Total indicatif ≈ **95 min**, jamais opposable.
- **`FullTcfExamResponse.SubAttempt` porte son temps** : `timeLimitSeconds`,
  `timerStartedAt`, `deadlineAt`. **`deadlineAt` est l'unique base du compte à
  rebours** des 3 fronts — aucun ne recalcule d'échéance, sinon le temps
  cesserait de courir pendant une absence. C'est l'absence de ces champs qui
  avait forcé les durées en dur, et fait diverger web et mobile (CE annoncée
  30 min ici, 35 min là).
- **Un score QCM TCF s'affiche TOUJOURS sur 100-499**, jamais sur le pondéré
  interne. `SubAttempt` porte `calibratedScore` (nullable), rempli par
  `FullTcfExamResponseBuilder` **en déléguant à `TcfLevelEstimatorService`** —
  la formule (correction du hasard 25 %, bornes 100-499) ne se recopie jamais.
  `null` pour EE/EO, pour une épreuve `locked`, et quand le pondéré manque : le
  service rendrait sinon sa borne basse et l'écran afficherait « 100/499 » là où
  on ne sait rien. Repli déclaré une fois par front (`qcmScoreLabel`, miroirs
  `web/lib/exam-levels.ts` ⇄ `mobile/core/models/full_tcf_exam.dart`) : calibré
  ⇒ `x/499`, sinon le brut `x/maxScore`, **jamais un `/499` fabriqué à partir
  d'un pondéré**. `score`/`maxScore` restent servis. ⚠️ Ne vaut que pour le
  **TCF** — le civique se lit sur `/40` ou `/20`.
- **`POST /begin?epreuve=…` est appelé sur les 4 épreuves** (obligatoire pour
  l'EE, qui n'avait **aucune** échéance avant). Idempotent par ancre : reprendre
  une épreuve ne remet pas son chrono à zéro.
- **L'ORAL n'a pas de chrono d'épreuve** (`timeLimitSeconds` = `null`), calqué
  sur le vrai TCF : la consigne s'affiche **sans aucun décompte**, et le temps ne
  part qu'au **lancement de la tâche** (« Je suis prêt · Commencer la tâche »),
  sur `production_tasks.duree_max_sec` (180 / 210 / 210 s). Auto-stop, puis tâche
  suivante. Reste un **garde-fou de session de 2 h**
  (`DureeEpreuve.EO_GARDE_SESSION_SECONDS`), **invisible des fronts et jamais
  présenté comme un chrono** : sans lui une session EO reste ouverte
  indéfiniment et un compte gratuit y accumule des évaluations IA payantes. Il
  ne s'applique pas aux sous-épreuves d'un examen complet.
- **Le chrono QCM est enfin opposable serveur** : `POST /api/attempts/{id}/answers`
  (et sa jumelle publique) rend **422** après échéance + `SUBMIT_GRACE_SECONDS`
  (60 s, réutilisée). Il n'était lu que par les fronts — le respecter était une
  politesse du client. Le refus porte sur **une réponse**, jamais sur la session.
- **Clôture automatique paresseuse à la lecture** (`GET /attempts/{id}`,
  `GET /full-tcf-exams/{id}`), sans job planifié — même mécanique que
  l'expiration des abonnements (`SubscriptionService.isCovering`) : un attempt
  hors délai est terminé + scoré sur les réponses existantes. Un retour dans
  l'app peut donc rendre une épreuve déjà `finishedAt` : **c'est normal**.
- **Abandon / reprise — le temps est la seule autorité, quitter ne suspend
  rien.** Une épreuve terminée est conservée. Revenir **avant** l'échéance rend
  le temps réellement restant ; **après**, l'épreuve est clôturée avec ce qui
  était enregistré. 🛑 **Il n'existe AUCUN flux « recommencer une épreuve
  interrompue » — ne pas en construire** : le chrono qui continue de tourner
  suffit à garantir la fiabilité de la simulation, et faire tout refaire à qui a
  reçu un appel téléphonique serait une punition sans contrepartie.
  **Exception EO** : le temps ne courant que pendant une tâche lancée, quitter
  sur l'écran de consigne ne coûte rien et les tâches rendues sont conservées.
- ⚠️ **Trou connu et assumé : une EE abandonnée se clôture VIDE.** Aucune
  persistance de brouillon n'existe (`production_submissions.texte_soumis` n'est
  écrit qu'à l'envoi final, aucun autosave, aucune table) — « clôturée avec ce
  qui était enregistré » signifie donc *rien* à l'écrit : 3 tâches à 0, bilan
  `A1_NON_ATTEINT`. **Ne pas construire de système de brouillon sans arbitrage
  produit explicite** (colonne + endpoint d'autosave + décision sur ce qu'on
  évalue d'un texte non envoyé).
- **`ContinuiteSimulation`, dérivé serveur et jamais persisté** (philosophie
  `SkillStatusResolver` / `SituationDansNiveau`) : `SESSION_UNIQUE`
  (« Simulation complète — conditions examen ») / `PLUSIEURS_SESSIONS`
  (« Simulation complétée en plusieurs sessions »), **null tant que l'examen
  n'est pas terminé**. Bascule au-delà de `PAUSE_MAX_ENTRE_EPREUVES` = **15 min**
  entre la fin d'une épreuve et le lancement de la suivante. Libellés gelés par
  `ContinuiteSimulationTest`, miroirs manuels web (`FULL_TCF_EXAM_CONTINUITE_LABEL`,
  `lib/types.ts`) et mobile (`label` de l'enum). Le 3ᵉ cas de la spec (« pas de
  résultat global définitif ») **existe déjà** : `finalLevelPartial` /
  `epreuvesCountedInFinalLevel` — **ne pas créer de notion parallèle**.
- **Miroir de durée côté fronts** : `web_sejoufr/lib/exam-durations.ts` et
  `mobile_sejourfr/lib/core/utils/epreuve_duration.dart`, **une seule table
  chacun**, réservée aux écrans **antérieurs à l'examen** (briefings, vitrines —
  aucun DTO n'existe encore à ce moment). Dès qu'un objet serveur existe, c'est
  `timeLimitSeconds` qui fait foi. Le total annoncé est **recalculé**, jamais
  écrit. Le temps conseillé EE (7 / 10 / 13 min) est **éditorial**, purement
  indicatif, et sa somme vaut exactement les 30 min réelles.

## Diagnostic initial TCF et Plan personnalisé

Le diagnostic est un **parcours distinct** des examens blancs et de la notation
standard. Il comporte exactement deux exercices hybrides fixes par
version : une EE de 100–130 mots, puis une EO enregistrée de 2–3 minutes. Ils
vivent dans `production_tasks` pour réutiliser la soumission, R2 et Whisper,
mais portent `diagnostic_code` + `diagnostic_version` ; tous les catalogues,
tirages, historiques, statistiques, quotas, outils admin standard, validateurs
de rubriques et files de calibration doivent garder le filtre
`diagnostic_code IS NULL`. Ce n'est jamais un `TCF_COMPLET`.

- **Parcours : productions en invité → compte → analyse.** Un visiteur fait ses
  **deux productions AVANT** qu'on lui demande un compte, le crée au moment
  d'« Analyser mes réponses », et l'analyse IA ne tourne qu'ensuite. **Les
  productions restent CÔTÉ CLIENT tant qu'il n'y a pas de compte** : aucune
  session diagnostique anonyme, aucune ligne en base, aucun audio d'invité sur
  R2 — `diagnostic_sessions.user_id` reste `NOT NULL`, ne rien rendre nullable.
  Le seul besoin serveur est donc **servir les deux sujets** :
  `GET /api/public/diagnostics/current` (public, rate-limité par IP à 120 / 10
  min, `PublicDiagnosticResponse` **sans** `attemptId`/`submissionId`/
  `submissionStatus`). La **version active et ses deux sujets se résolvent en un
  seul endroit** (`DiagnosticContentResolver`, partagé par la lecture publique,
  la création de session et la restitution) : deux résolutions séparées feraient
  soumettre une production pour un sujet que le candidat n'a jamais lu. Funnel :
  `DIAGNOSTIC_ACCOUNT_REQUIRED` sur `/diagnostic` est LA mesure de conversion —
  tout ce qui précède se joue hors base. Après inscription, l'enchaînement
  `POST /api/diagnostics` → écrit → oral **coup sur coup** est accepté sans
  assouplir aucune garde (`DiagnosticPostSignupSequenceIT`) ; un compte au
  diagnostic **déjà terminé** récupère sa session `COMPLETED` (200, avec son
  `result`, jamais de seconde session) et toute nouvelle production est refusée
  en **422** — c'est au front d'afficher le message.
- **Agrégat** : `diagnostic_sessions` enveloppe les deux attempts EE/EO, avec
  unicité `(user, code, version)` **et** unicité séparée de chaque attempt. Les
  états persistés sont `IN_PROGRESS`, `ANALYZING`, `COMPLETED`, `FAILED` ; le DTO
  ajoute `NOT_STARTED` quand aucune session n'existe. `POST /api/diagnostics`
  est idempotent et sûr en concurrence ; `GET /api/diagnostics/current` permet
  la reprise cross-device, `GET /api/diagnostics/{id}` protège l'IDOR par 404,
  et `POST .../{id}/retry-analysis` est borné/configuré et rate-limité.
- **Soumission stricte** : les routes de production existantes sont réutilisées,
  mais le bypass de quota n'est accordé que si la tâche, l'attempt, l'utilisateur,
  la session courante et l'étape concordent. Une tâche diagnostique seule ne
  suffit jamais. Une seule submission diagnostique est admise par attempt ; la
  route générique `/production-submissions/{id}/retry` la refuse au profit du
  retry agrégé. Audio, taille, durée, rate-limit et Whisper restent appliqués.
- **Contrat IA séparé** : `diagnostic-analysis-rubrics-v1.json` et
  `diagnostic-analysis-tool-schema-v1.json`, configurés sous
  `sejourfr.diagnostic.analysis`, ne produisent **aucune note /20**. Le schéma
  impose l'allowlist exacte des compétences de la tâche, codes uniques, preuve
  par segment réel, confiance et cohérence statut/observation. Une réponse
  vide/illisible est transitoire et une seule réparation de format est tentée.
  **On versionne ces deux fichiers, on ne réécrit jamais une version livrée.**
- **`priority` est DÉRIVÉ de `status`, il n'est plus un motif de refus**
  (`DiagnosticAnalysisReconciler`, qui passe **avant** le validateur) : une
  divergence est réconciliée puis comptée, et le plafond de **2 priorités par
  production** est une **troncature déterministe** (les 2 meilleures par
  confiance puis rang d'allowlist — règle partagée `DiagnosticPriorityRanking`,
  **jamais l'alphabet** ; le surplus est abaissé d'un cran en `TO_REINFORCE`),
  jamais un refus. Motif : ce couple d'invariants n'était **écrit nulle part
  dans le prompt** et portait sur un champ **redondant** (`status` fait foi, il
  est seul persisté et contraint en base) — il a détruit un diagnostic réel,
  donc les **deux productions** du candidat. Contrat v1 inchangé ; compteurs
  `DiagnosticReconciliationMetrics`, famille distincte.
- **Bifurcation persistée** : `production_submissions.is_diagnostic` décide du
  pipeline async. Une submission diagnostique réutilise Whisper si nécessaire,
  puis `DiagnosticProductionAnalysisService` ; elle ne passe jamais dans
  `AiEvaluationService`, `ai_evaluations`, la version ciblée, le profil TCF ni la
  calibration. L'assemblage des deux analyses est déterministe, sans troisième
  appel LLM, limite les priorités globales à trois et renvoie toujours un
  `nextAction` réellement disponible, même si aucune priorité n'est assez
  fiable. La relance agrégée réserve `FAILED → ANALYZING` sous verrou pessimiste
  puis déclenche l'async après commit ; une session `COMPLETED` n'est jamais
  rétrogradée par un recorder tardif.
- ⚠️ **Corollaire de cette bifurcation : le diagnostic ne traverse AUCUN filet de
  `AiEvaluationService`.** Il rendait donc des reproches bâtis sur un artefact de
  transcription — cas réel : `EO2-C3` reprochait « « horreurs » pour « horaires »
  est une erreur lexicale », alors que le candidat avait dit « horaires ».
  **`DiagnosticOralArtifactFilter`** (livré **ACTIF** le 2026-08-14, EO **seulement**)
  applique la règle du volet FORME au diagnostic oral : une remarque qui
  **reproche**, **cite un passage réel** de la transcription et dont la citation
  ne nomme **qu'1 ou 2 mots pleins** est purgée ; **0 mot porteur** (structure
  pure) et **≥ 3** sont conservés ; transcription **dégradée**
  (`TranscriptionQualityAudit`) ⇒ tout reproche ancré tombe. **Rien n'est extrait
  du néant** : la règle entière vit dans **`EvaluationOralForme`**
  (`reprocheAncreSurUneForme`, 3ᵉ occurrence ⇒ les patterns `CITATION`/`REPROCHE`
  y ont été **déplacés** depuis `EvaluationOralArtifactFilter`, qui délègue
  désormais), le découpage en phrases dans `EvaluationTexte` (rendue publique).
  ⚠️ **Le diagnostic n'a PAS d'axe de critères** (ses observations sont des
  compétences, pas `morphosyntaxe`/`lexique`) : la restriction « jamais `lexique` »
  des productions **ne s'y transpose pas**, et le propriétaire a arbitré qu'on
  purge quand même un reproche dit « lexical » — les deux lectures (machine qui a
  mal entendu / candidat qui a mal prononcé) mènent au même endroit, et la grille
  interdit déjà de noter la prononciation. **Champs purgés** :
  `skills[].explanation` (l'observation **survit sans son explication**),
  `weaknesses[]` (entrée vidée ⇒ retirée), `summary` (remplacé par un texte qui dit
  pourquoi). **Jamais touchés** : l'ÉCRIT, `strengths`, `evidence`, `status`,
  `priority`, `confidence`, `level_estimate`, `task_completion`,
  `communication_status`, l'ordre des priorités. 🛑 **Une purge ne peut pas rendre
  une session `FAILED`** : le filtre tourne **après** `DiagnosticAnalysisValidator`
  sur la sortie déjà normalisée (rien ne revalide derrière), et `purge` **avale
  toute exception**. Compté `EvaluationPurgeMetrics.ARTEFACT_ORAL_FORME_DIAGNOSTIC`
  — même **nature** (une purge retire une phrase) donc même famille que les 4
  surfaces `MARQUEUR_PALIER*`, dont une est déjà diagnostique ; constante à part
  pour distinguer les deux voies. **Contrats IA inchangés** (`diagnostic-analysis-*-v1`) :
  c'est un contrôle serveur, pas une consigne. Legacy non migré.
- **Départage des priorités : allowlist puis alternance, jamais l'alphabet**
  (`DiagnosticSessionCoordinator`). À confiance égale (`HIGH>MEDIUM>LOW`), c'est
  le rang de la compétence dans l'allowlist de son sujet
  (`diagnostic_task_skills.display_order`, l'ordre éditorial d'importance) qui
  tranche ; à égalité résiduelle, écrit et oral **alternent** au lieu d'être
  groupés (la première égalité parfaite revient à l'écrit, produit en premier).
  L'ancien départage se faisait sur l'ordre **alphabétique du code**, ce qui
  faisait mécaniquement passer toutes les priorités `EE…` devant les `EO…` et les
  compétences C1/C2 devant les autres. Déterministe, aucun appel LLM.
- **Une priorité se DÉRIVE des faiblesses quand le correcteur n'en désigne
  aucune** (`DiagnosticPriorityRanking.faiblesseObservee`, appliqué par
  `DiagnosticSessionCoordinator`). Mesuré sur deux diagnostics réels joués de
  bout en bout — dont un sur une production A1/A2 volontairement fautive : le
  modèle range tout en `TO_REINFORCE` et ne pose jamais `status=PRIORITY`, donc
  `priority_skill_codes` sortait **vide** et le Plan restait `ACTIVE` sans rien à
  faire. Rien dans les rubriques ne l'y oblige (« **au plus** deux » est satisfait
  par zéro) et une consigne ne serait qu'un vœu : la dérivation est déterministe
  et serveur. Une priorité **désignée l'emporte toujours** (on complète, on ne
  remplace pas) ; `SOLID` et `NOT_OBSERVED` n'en deviennent **jamais** une — zéro
  faiblesse observée ⇒ zéro priorité, état légitime. Bornes inchangées (2 par
  production, 3 après fusion, alternance écrit/oral), comptage
  `DiagnosticReconciliationMetrics.PRIORITE_DERIVEE_DE_FAIBLESSE`.
  **Le Plan applique la même règle** : `LearningPlanPriorityResolver.actionable`
  traite une observation `TO_REINFORCE` comme une priorité dérivée et départage
  par **confiance** avant la récence, miroir de `DiagnosticPriorityRanking` — les
  deux productions du diagnostic sont observées au même instant, la récence n'y
  trie rien. `/api/me/plan` et `GET /api/diagnostics/{id}` ne peuvent donc plus
  désigner deux étapes n°1 différentes, et le freemium suit
  (`SkillAccessService` ouvre la compétence de la priorité, dérivée comprise).
- **Une étape du Plan = les 5 premiers sujets actifs de sa compétence**, par
  `display_order` croissant (`LearningPlanStep.PROMPTS_PAR_ETAPE`, arbitré le
  2026-08-11). **Dérivé, jamais persisté** : aucune table, aucune migration, le
  périmètre se relit du rang d'affichage — mêmes 5 sujets pour tout le monde,
  ils ne bougent jamais. Avant, une étape exigeait les **15** sujets (« 2/15 »),
  que personne n'allait finir. Une compétence publiant moins de 5 sujets a une
  étape plus courte : le périmètre vaut ce qui existe, **aucun dénominateur
  n'est inventé**. « Tous distincts » est **acquis par construction**
  (`latestObservedBySkill` ne garde qu'une observation par compétence) : **ne
  jamais construire de mécanisme d'unicité inter-étapes**, il serait mort-né.
- **Compteurs d'étape À CÔTÉ des compteurs de compétence, jamais à leur place.**
  `LearningPlanPriorityDto` porte les deux : `promptCount`/`attemptedCount`/
  `validatedCount` = la **compétence** (15 sujets, sémantique de `SkillDto`,
  inchangée) ; `stepPromptCount`/`stepAttemptedCount`/`stepValidatedCount`/
  `stepCompleted` = l'**étape** (5 sujets). C'est le second jeu que les fronts
  affichent sur l'anneau d'une étape. Détourner le premier à 5 ferait dire
  « /5 » au Plan et « /15 » à la fiche de compétence pour une même compétence.
  `LearningPlanSkillDto` (compétences observées) **n'est pas une étape** et ne
  porte que les compteurs de compétence. Un seul calcul dans
  `SkillProgressCounter` (+ `SkillProgressTally`, `SkillStatusResolver`), **2
  requêtes** quel que soit le nombre de compétences.
- **Le PÉRIMÈTRE de l'étape est publié, pas redécoupé par les fronts** :
  `LearningPlanPriorityDto.stepPromptIds` (liste ordonnée d'UUID, **jamais
  `null`**, éventuellement vide, `display_order` croissant sur les sujets
  actifs), dérivée de `LearningPlanStep.scope`. Invariant garanti :
  `stepPromptIds.size() == stepPromptCount` — le compteur en est **dérivé**, ils
  ne peuvent plus diverger. **Zéro requête ajoutée** : les sujets étaient déjà
  chargés pour les compteurs. Motif : ouvrir une compétence **depuis le Plan**
  affichait « 1/15 » (la fiche générique), l'étape se perdait à la navigation.
  Les fronts servent désormais un écran **scopé aux 5 sujets** quand on vient du
  Plan, et la fiche complète (« x/15 ») par le chemin Réviser → Compétences —
  deux vues assumées pour une même compétence. Ils **ne réimplémentent pas**
  « les 5 premiers par ordre d'affichage » : deux copies désigneraient deux
  étapes différentes.
- **UNE SEULE définition de « transfert prouvé », et elle vit chez le moteur**
  (2026-08-16, `SkillMastery.transferProven()`) : l'état agrégé vaut `SOLID`,
  **ou** une réussite en situation (`SOLID` issu de `PRODUCTION_EE/EO` ou
  `MOCK_EXAM_EE/EO` — jamais un micro-entraînement, jamais le diagnostic qui est
  la baseline) est encore dans `transfer-proof-days` **et** les fragilités
  contextualisées récentes restent sous `fragility-tolerance`. Une compétence
  dont le transfert est prouvé cesse d'être *actionable* : elle sort des
  priorités et la suivante devient l'étape n°1.
  `LearningPlanPriorityResolver.transfertProuve` ne fait que **lire** ce
  booléen — il ne relit plus l'historique.
  ⚠️ **Cette règle RÉVOQUE celle du 2026-08-15** (« la **dernière** observation
  contextualisée fait foi »), qui avait une tolérance **nulle** et enfermait le
  candidat : une seule production moins bonne révoquait trois `SOLID`
  antérieurs, la compétence restait priorité **à vie**, et le moteur — qui la
  jugeait déjà `SOLID` — refusait en même temps d'ouvrir la vérification
  (`readyForReassessment` court-circuite sur `state == SOLID`). Impasse mesurée
  en base sur `user@sejourfr.fr`/`EE1-C8`, plus 4 autres compétences du même
  compte. Ne pas la réintroduire.
  ⚠️ **Aligner sur le seul `state == SOLID` NE MARCHE PAS non plus** — piège
  arithmétique, vérifié : dans le parcours normal (5 micro-sujets validés + 1
  vérification réussie) le score plafonne à **0,679** pour un `solid-score` de
  **0,75**, les 5 `TO_REINFORCE` ciblés à 0,5 diluant la moyenne. Les 5
  conditions structurelles de `SOLID` sont pourtant réunies : c'est le **seuil de
  score** qui manque. Exiger `SOLID` déplacerait donc l'impasse d'un cran et
  imposerait une **seconde** preuve en situation, contre la décision « une
  réussite suffit ». D'où la seconde branche. Verrou :
  `SkillMasteryEngineTest.cinqSujetsPuisUneVerificationProuventLeTransfert`
  (assert `transferProven()` **et** `state != SOLID`).
  **Corollaire** : une étape franchie n'est **pas** forcément `SOLID` — sur le
  compte réel, 1 l'est et 4 sont `CONSOLIDATING`. `PlanMilestoneSelector`
  (≥ 2 compétences `SOLID`) est donc **inchangé**, et les fronts ne doivent
  **jamais** conditionner la coche verte à `masteryState == SOLID` :
  l'appartenance à `completedSteps` **est** la coche.
  🛑 **`recentContextualProof` ne se pose que sur une contextualisée `SOLID`**
  (corrigé le 2026-08-16) : il l'était sur tout `valeur >= 0.5`, donc une
  production jugée **fragile** comptait comme preuve de transfert et **éteignait**
  le signal de vérification. Ne change rien au cas ci-dessus (de vrais `SOLID`
  existaient) ; débloque les candidats dont la seule trace en situation était une
  fragilité.
  ⚠️ **Le déclencheur de la vérification est INCHANGÉ** : toujours
  `readyForReassessment` **et** `step.completed()`.
  Conséquence sur le freemium : `SkillAccessService` ouvrant la compétence de la
  priorité n°1, celle-ci **se déplace** avec l'enchaînement. Sans effet réel pour
  un compte gratuit, qui plafonne à 2 sujets sur 5, ne termine jamais une étape
  et n'obtient donc jamais cette preuve par cette voie.
- **Une étape franchie RESTE dans le parcours, cochée** —
  `LearningPlanDto.completedSteps` (`LearningPlanCompletedStepDto`, **jamais
  `null`**, vide = cas normal, **bornée à 5** les plus récentes, ordre du plus
  ancien au plus récent). Elle se lit **avant** `currentPriority` puis
  `nextPriorities`, dans le **même parcours numéroté**. Sans elle, une compétence
  prouvée **disparaissait** et le candidat perdait la trace de ce qu'il avait
  franchi. Elle ne porte **ni `recommendedExercise` ni `locked`** : il n'y a rien
  à y faire, et ce n'est pas une porte commerciale. L'historique complet reste
  l'affaire de l'écran Progression.
- **Achèvement d'une étape, dérivé serveur** (`LearningPlanStep.Progress
  .completed()`, jamais persisté, jamais recalculé par un front — philosophie
  `SkillStatusResolver` / `SituationDansNiveau`) : terminée quand ses 5 sujets
  ont été **traités** (`status.isAttempted()`, tout sauf `TODO`). **Terminée ≠
  tout validé** — `stepValidatedCount` reste l'information distincte. Une étape
  sans sujet actif n'est jamais terminée. ⚠️ **Une étape terminée ne disparaît
  pas du Plan** : les priorités ne changent qu'à l'arrivée d'une nouvelle
  observation (`LearningPlanObservationService`), donc à la prochaine
  production. C'est le comportement correct — aux fronts de le dire clairement.
- **L'exercice recommandé doit faire avancer** — règle unique partagée par le
  Plan et l'écran de résultat du diagnostic (`RecommendedExerciseSelector`, seul
  endroit) : (1) premier sujet **jamais tenté** par `display_order` croissant,
  (2) sinon le sujet `TO_REINFORCE` dont la dernière tentative est la plus
  ancienne, (3) sinon le sujet tenté le plus anciennement, (4) sinon rien. Statut
  dérivé par `SkillStatusResolver`, chargement en lot (2 requêtes quel que soit
  le nombre de compétences). Avant, les deux appelants prenaient le sujet de rang
  1 et le resservaient indéfiniment. **Le périmètre est celui de l'ÉTAPE** : le
  choix se fait parmi les 5 premiers sujets actifs (`LearningPlanStep.scope`),
  jamais sur les 15 — sinon « Continuer cette étape » enverrait hors étape et
  l'anneau « x/5 » ne bougerait pas. Les **4 branches sont intactes**, seul
  l'ensemble sur lequel elles s'appliquent est réduit, et la borne vaut pour les
  **deux** appelants : le diagnostic désigne la compétence de la priorité n°1,
  il doit pointer dans les mêmes 5. `estimatedMinutes` est **dérivé du sujet**
  (EO : temps de parole conseillé × 3 pour lecture/préparation ; EE : milieu de
  la fourchette de mots à 12 mots/minute ; repli 5/4 min si la donnée manque).
- **Plan source de vérité serveur** : `GET /api/me/plan` renvoie les états
  `NEEDS_DIAGNOSTIC`, `DIAGNOSTIC_IN_PROGRESS` ou `ACTIVE`, les priorités déjà
  ordonnées, l'exercice recommandé et, sur chaque priorité comme sur chaque
  compétence observée, `promptCount`/`attemptedCount`/`validatedCount` — mêmes
  compteurs, même calcul (`SkillProgressCounter` + `SkillProgressTally`) que
  `SkillDto` du module Compétences, jamais un second calcul parallèle (les
  compteurs d'**étape** s'ajoutent à côté, cf. ci-dessus). `learning_plan_observations` conserve
  `skill_id`, source typée + `source_id`, preuve, explication, confiance, date et
  indicateur de baseline. Les fronts affichent cet ordre sans le recalculer ;
  `NOT_OBSERVED` est conservé dans l'historique mais n'annule jamais la dernière
  observation probante d'une compétence ;
  l'écran historique/Progression reste secondaire et séparé.
  **L'ordre des priorités vit dans `LearningPlanPriorityResolver`**, extrait de
  `LearningPlanService` le 2026-08-10 parce qu'un second lecteur en dépend :
  `SkillAccessService` ouvre la compétence de la priorité n°1 à un compte
  gratuit. Deux copies auraient fini par désigner deux « étapes n°1 »
  différentes.
- **Le Plan reste intégralement visible sans abonnement** : aucune priorité,
  aucune compétence observée, aucun compteur, aucun exercice recommandé n'est
  masqué à un compte gratuit — masquer priverait le candidat du résultat de sa
  propre production. Seuls les **accès** sont verrouillés, signalés par
  `locked` sur `LearningPlanPriorityDto`, `LearningPlanSkillDto` et
  `PlanRecommendedExerciseDto`. L'exercice recommandé reste **désigné** même
  verrouillé : savoir quoi travailler est ce que le Plan apporte, on ne le
  détourne pas vers un sujet ouvert qui ne serait plus la priorité mesurée.
  **Visible ≠ finissable** : les compteurs d'étape sont servis en entier, mais
  un compte gratuit plafonne à 2/5 (cf. § Freemium).
- **Boucle de réévaluation — l'étape CHANGE DE NATURE, elle ne se dédouble pas.**
  Quand la maîtrise pose `readyForReassessment` (moteur inchangé), la carte « À
  faire maintenant » cesse de proposer un micro-sujet et propose une
  **vérification en situation** : même carte, même emplacement, action
  différente. Le sujet est une **tâche de production déjà publiée** de la
  `SkillTaskCode` de la compétence (jamais de génération, jamais de nouvelle
  banque, jamais d'appel LLM) ; le **diagnostic initial n'est jamais rejoué**
  (filtre `diagnostic_code IS NULL` des deux côtés — mémorisation, biais,
  lassitude). Autorité unique : **`ReassessmentExerciseSelector`**, jumelle de
  `RecommendedExerciseSelector`. Règle : (1) premier sujet **jamais rendu**, (2)
  tous rendus ⇒ le premier du même ordre en écartant la copie la plus récente,
  (3) aucun sujet publié ⇒ rien, et l'étape retombe sur son micro-exercice —
  cas **normal**, jamais une erreur. L'ordre est une **permutation semée** par
  (candidat, compétence, sujet) via splitmix64 : reproductible d'un appel, d'un
  process et d'un serveur à l'autre — jamais `Random` non semé, jamais
  `hashCode` d'objet. Elle porte sur le pool **entier**, donc jouer un autre
  sujet de la même tâche ne redistribue rien. Le DTO dit **quoi et où** :
  `PlanRecommendedExerciseDto.kind` (`MICRO_TRAINING|REASSESSMENT`),
  `skillPromptId` **xor** `productionTaskId` + `tacheNumero`, construits par
  `microTraining(...)` / `reassessment(...)`. `estimatedMinutes` reste **dérivé
  du sujet** (`util/ExerciseDuration`, formule partagée par les deux
  sélecteurs). **Le verrou freemium continue de s'appliquer et ne détourne
  rien** : un sujet verrouillé est **désigné quand même** avec son `locked`, lu
  par `ProductionAccessService.isTrainingLocked` — même règle que
  `enforceQuota`, en lecture (une copie aurait fini par ouvrir ce que le serveur
  refuse). Une réévaluation est une **production standard** : elle produit ses
  observations `PRODUCTION_EE/EO` par le pipeline existant, aucun type de source
  dédié.
- **La bascule vers la vérification exige DEUX conditions, pas une** (2026-08-14) :
  le signal du moteur (`SkillMastery.readyForReassessment`) **et**
  `LearningPlanStep.Progress.completed()` — l'**étape terminée**, ses **5** sujets
  traités. `LearningPlanService` combine les deux **une seule fois** et sert ce
  booléen à la fois à `LearningPlanPriorityDto.readyForReassessment` et au choix
  de l'exercice : le DTO ne peut pas dire « prêt » pendant que la carte propose
  un micro-sujet. Motif mesuré en base : un candidat ayant validé 2 des 5 sujets
  se voyait proposer « Vérifier ma progression » sous un anneau à **2/5** — le
  moteur avait raison sur le fond, l'étape n'était pas finie.
  🛑 **Le périmètre est l'étape ENTIÈRE, pas ce que l'accès du candidat lui
  ouvre — c'est un ARBITRAGE PRODUIT du propriétaire, pas une propriété du
  moteur de maîtrise : la vérification de progression est PREMIUM.** Un compte
  gratuit plafonne à 2 sujets sur 5 (`FREE_PROMPTS_PER_SKILL`), donc il ne
  bascule **jamais** ; aucune de ses compétences n'atteint `SOLID` (qui réclame
  la preuve contextualisée que seule cette vérification apporte) ; et il ne voit
  donc pas non plus les **jalons** de `PlanMilestoneSelector`, dont le
  déclencheur d'épreuve exige ≥ 2 compétences `SOLID`. **Ces trois conséquences
  sont voulues** : ne pas les « réparer » en comptant les sujets ouverts. Une
  première version (livrée puis révoquée le jour même) le faisait, via un
  `exhausted()` / `openCount` dérivé de `SkillAccess` — supprimés, ne pas les
  réintroduire. Le seuil `readiness-targeted-subjects: 2` n'y change rien : il
  n'a jamais gardé cette porte.
  ⚠️ **Le seuil `readiness-targeted-score` ne se monte pas.** Une observation
  ciblée vaut **au mieux 0,5** — `recordSkillAttempt` écrit `TO_REINFORCE` quand
  le critère est **VALIDATED**, et **jamais `SOLID`**. Donc : `0.30` est le seul
  réglage qui sépare « un échec ancien puis deux réussites » (0,351, à laisser
  passer) de « deux réussites noyées dans trois échecs récents » (0,20, à
  refuser) ; `0.50` interdit d'échouer une première fois ; au-delà le signal
  s'**éteint** — et avec lui `SOLID`, qui réclame la preuve contextualisée que
  seule cette vérification apporte. Même piège pour les **réussites ciblées**
  (`SkillMasteryEngine.estReussiteCiblee`, désormais découplé du `valeur >= 0.5`
  du score) : **ne pas la restreindre à `SOLID`**, aucune ligne ne le produit.
  Verrou : `SkillMasteryEngineTest.leSeuilCibleResteAtteignable`.
- **JALONS — on ESCALADE, on ne reporte pas** (`PlanMilestoneSelector`, 3ᵉ et
  dernier sélecteur d'exercice, jumeau de `RecommendedExerciseSelector` /
  `ReassessmentExerciseSelector` — **autorité unique**, deux copies auraient fini
  par désigner deux jalons). Échelle : étape (5 sujets) → **vérification ciblée**
  (débloque `SOLID`) → **examen blanc d'épreuve** (EE ou EO, 3 tâches) → **examen
  blanc TCF complet**. Attendre « les 3 étapes finies » était inatteignable (un
  gratuit plafonne à 2/5) et aurait figé tout le monde en `CONSOLIDATING`.
  L'échelle est déjà **tarifée** par les poids du moteur (0,45 / 0,80 / 1,00 /
  1,20) ; il ne manquait que le déclencheur.
  - **Déclencheurs, dérivés serveur et jamais persistés** : jalon d'épreuve quand
    les compétences **observées** de l'épreuve sont majoritairement **`SOLID`**
    (`epreuve-min-solid-skills: 2` **et** `epreuve-solid-ratio: 0.5`, les deux
    ensemble) et qu'aucun examen blanc de cette épreuve n'a été observé depuis
    `proof-days: 45` ; jalon complet quand **les deux** épreuves ont franchi le
    leur **et l'ont prouvé**, sauf si un `TCF_COMPLET` a démarré dans la fenêtre.
    `SOLID` et pas le score : c'est le seul état qui exige une preuve **en
    situation**. Tous les nombres vivent sous
    `sejourfr.learning-plan.milestone` (+ POJO `LearningPlanProperties.Milestone`
    aux mêmes défauts). À égalité, l'**écrit** passe devant l'oral.
  - **Aucun contenu créé, aucune route nouvelle** : un jalon désigne un examen
    blanc **déjà existant** par `epreuve` + `slotNumber` (le premier slot non
    joué, plafonné à la grille). `PlanExerciseKind` gagne `EPREUVE_MOCK_EXAM` et
    `FULL_TCF_MOCK_EXAM` ; `PlanRecommendedExerciseDto` gagne `epreuve` +
    `slotNumber`, **mutuellement exclusifs** avec `skillPromptId` et avec
    `productionTaskId`+`tacheNumero`. Un jalon ne porte **ni titre ni
    compétence** : le serveur expose des faits, la phrase appartient aux fronts.
    Servi sur `LearningPlanDto.milestone`, **à côté** des priorités (chaque étape
    garde son propre exercice) ; `null` est le **cas normal**.
  - **Verrou reporté, jamais appliqué à la désignation** : un jalon verrouillé
    est **désigné quand même** avec son `locked`, lu chez l'autorité que le
    serveur oppose au démarrage — `ProductionAccessService.isProductionExamLocked`
    (jumelle en lecture de `assertCanStartProductionExam`, que
    `AttemptService.startProductionAttempt` appelle désormais) et
    `.isFullExamProductionLocked` (jumelle du calcul que `FullTcfExamService
    .start` faisait en propre). **Jamais une copie de la règle.**
  - **Coût** : **zéro requête** tant qu'aucun jalon n'est atteint — tout se
    décide sur l'historique déjà chargé et les états de maîtrise déjà calculés
    (`fromObservations` porte désormais sur **toutes** les compétences observées,
    pas seulement celles des cartes : une compétence `SOLID` n'est jamais une
    priorité). Quand un jalon est atteint : 2 à 3 requêtes bornées, jamais une
    par compétence.
- **« Le Plan a changé » après une production** : `ProductionSubmissionDto
  .planChange` (`PlanChangeDto` = `confirmedSkill` + `newPriority`, deux
  `PlanSkillRefDto` **indépendamment nullables**, bloc entier `null` si rien n'a
  bougé). Une **ligne**, jamais la liste des compétences observées. « Confirmée »
  = observation `SOLID` **contextuelle** issue de cette soumission (le diagnostic
  est la baseline, il ne confirme jamais) ; « nouvelle priorité » = la priorité
  n°1 courante **si c'est cette production qui l'a désignée**. Calculé
  **serveur, à la lecture** (`LearningPlanService.changeAfterProduction`,
  branché sur `getOwnDetail` seulement — ni liste d'historique, ni sujet de
  diagnostic, ni avant `EVALUATED`). ⚠️ **Course assumée** : les observations
  s'écrivent **après** la correction, best-effort et hors transaction
  (`ProductionPipelineAsyncRunner`) — rien n'est figé à l'écriture, donc
  l'absence du bloc est un **état normal** et la lecture suivante le rend, sans
  erreur ni rejeu (même sursis côté fronts que le plan d'action).
  **Aucun libellé serveur** : le bloc expose des faits, la phrase appartient aux
  fronts — et un transfert manqué ne se dit **jamais** « vous avez perdu votre
  progression », mais « réussi en exercice ciblé, pas encore automatique en
  production complète ».
- **Plan vivant** : après une correction v14/v8 réussie d'une future production
  complète standard, une observation structurée séparée utilise les skill IDs de
  sa tâche ; son échec best-effort ne dégrade jamais la correction. Les
  micro-exercices alimentent aussi le Plan une fois évalués, mais une réussite
  isolée devient au mieux `TO_REINFORCE`, jamais `SOLID`. **Les productions
  d'examen blanc EE/EO alimentent le même moteur** (V031) : elles passaient déjà
  par le même pipeline mais étaient enregistrées comme de l'entraînement, donc
  sous-pondérées. Une session d'examen productive porte un `slotNumber`, une
  épreuve d'examen **complet** est un sous-attempt d'un parent `TCF_COMPLET` —
  les deux sont sur la ligne `attempts` déjà chargée, aucune requête de plus
  (`LearningPlanObservationService.isMockExam`, sources `MOCK_EXAM_EE/EO`).
- **Aucun diagnostic n'est exigé pour OBSERVER** (2026-08-12). `hasActivePlan` a
  été **supprimé** des deux producteurs (`recordSkillAttempt`,
  `observeStandardProduction`) : un candidat qui travaillait sans passer le
  diagnostic n'accumulait rien, et tout son travail était perdu le jour où il le
  passait. C'est le **Plan** qui continue de réclamer un diagnostic `COMPLETED`
  pour passer `ACTIVE` — `NEEDS_DIAGNOSTIC` / `DIAGNOSTIC_IN_PROGRESS` sont
  inchangés. ⚠️ Conséquence de coût assumée : la voie d'observation d'une
  production standard **appelle le LLM**, elle tourne désormais pour tout le
  monde, plus seulement pour les comptes diagnostiqués.
- **Moteur de maîtrise — `SkillMasteryEngine` + `SkillMasteryResolver`**, dérivé
  à la lecture et **jamais persisté** (même philosophie que `SkillStatusResolver`
  et `SituationDansNiveau`) : recalibrer une pondération relit tout l'historique
  au prochain appel, sans migration ni job.
  - **4 états agrégés, enum `SkillMasteryState`** : `PRIORITY` / `TO_REINFORCE` /
    `CONSOLIDATING` / `SOLID` (« Priorité » / « À renforcer » / « En
    consolidation » / « Solide », gelés par `SkillLabelsTest`, à mirrorer sur les
    3 fronts). ⚠️ **Distinct de `LearningPlanSkillStatus`**, qui est le verdict
    d'**une production** et reste persisté sur chaque observation : la contrainte
    `chk_learning_plan_observation_status` n'admet toujours que
    `NOT_OBSERVED|PRIORITY|TO_REINFORCE|SOLID`. `null` quand rien n'a été observé
    — on n'invente pas un état. `CONSOLIDATING` existe parce que « réussi en
    exercice ciblé » n'est ni « à renforcer » ni « maîtrisé » : c'est lui qui rend
    la vérification en situation compréhensible.
  - **Score interne** `poidsSource × confiance × récence`, moyenne pondérée dans
    `[0,1]` sur une fenêtre glissante et un nombre plafonné d'observations. Il
    **n'est exposé à aucun front** : pas de « 73 % maîtrisé ». `NOT_OBSERVED`
    ignoré (« je n'ai pas pu observer » ≠ « le candidat est mauvais »).
  - **L'état ne se déduit jamais du seul score.** `SOLID` exige **cinq**
    conditions : score ≥ seuil, ≥ 2 observations positives, **≥ 1 venue d'une
    production contextualisée** (production complète ou examen blanc — jamais un
    micro-entraînement, ni le diagnostic qui est la baseline), sujets
    **différents** (`learning_plan_observations.subject_id`, V031 — le sujet, pas
    la tentative), et pas de série de fragilités récentes.
  - **Stabilité** : une seule production moins bonne ne casse pas une compétence
    solide — le moteur rejoue le calcul sans les fragilités récentes tant que
    celles issues d'une production contextualisée restent sous
    `fragility-tolerance` (2). Une fragilité en micro-exercice ne révoque jamais
    un transfert déjà prouvé.
  - **`readyForReassessment`** : signal **interne** (exposé sur
    `LearningPlanPriorityDto` pour la suite du chantier) — assez de réussites
    ciblées, sur des **sujets différents**, performance **ciblée** suffisante, et
    pas de preuve de transfert récente. ⚠️ Le seuil porte sur la performance
    **des seuls micro-entraînements**, pas sur le score global : la baseline du
    diagnostic est une fragilité et un micro-exercice réussi ne vaut qu'une
    demi-preuve, donc un seuil global serait mécaniquement hors d'atteinte et le
    Plan proposerait des micro-exercices à l'infini.
  - **Tous les nombres vivent dans `application.yaml`** sous
    `sejourfr.learning-plan.mastery`, POJO `LearningPlanProperties` **aux mêmes
    valeurs par défaut** : sources `0.45 / 0.80 / 1.00 / 1.20`
    (micro-entraînement / diagnostic / production / examen blanc), confiances
    `1.00 / 0.80 / 0.55`, récence `1.00` (≤ 14 j) / `0.85` (≤ 30 j) / `0.70`,
    fenêtre 180 j, 12 observations max, seuils `0.75 / 0.50 / 0.30`. Aucune
    constante de pondération dans le Java.
  - **Chargement en lot obligatoire** : `SkillMasteryResolver.bySkillIds` fait
    **une** requête pour 24 compétences (index `idx_learning_plan_user_skill_recent`,
    posé en V029 et jusqu'ici jamais emprunté, verrouillé par
    `SkillMasteryResolverIT` qui compte les statements) ; le Plan, lui, se branche
    sur l'historique **déjà chargé** par `LearningPlanPriorityResolver`
    (`fromObservations`, zéro requête de plus).
  - **Exposition** : `masteryState` sur `SkillDto` (**c'est ce que la carte de
    compétence affiche à la place de « 2/15 traités »** — les compteurs restent,
    ils servent l'anneau d'étape), `LearningPlanSkillDto` et
    `LearningPlanPriorityDto`. ⚠️ **La `trajectory` de `SkillDetailDto` a été
    SUPPRIMÉE** le 2026-08-16 (DTO, `SkillObservationPointDto`,
    `SkillMasteryResolver.trajectory` et les deux miroirs front) : la section
    « Ton parcours sur cette compétence » n'apportait rien au candidat, et la
    servir coûtait **une requête à chaque ouverture** d'une compétence. Ne pas
    la réintroduire sans un écran qui la lise vraiment.
  - **`LearningPlanPriorityResolver` reste l'unique autorité sur l'ordre des
    priorités** : le moteur ne le réordonne pas, `SkillAccessService` continue
    d'en dépendre pour ouvrir la compétence de la priorité n°1.
  - **Aucun rattrapage** : le suivi démarre à la mise en service, le diagnostic
    reste la baseline. V031 ne renseigne `subject_id` que par jointure SQL
    déterministe sur des lignes existantes — aucun rejeu, aucun appel LLM.
- **Contenu et audio seed-only** : V755 crée la version `INITIAL_TCF/1`, ses deux
  sujets et leurs allowlists de huit compétences. La console de sujets standard
  refuse de les modifier. V755 ne génère aucun média : elle référence l'objet R2
  fixe, produit une fois explicitement et vérifié en HTTP 200. `GET
  /api/admin/diagnostics/{code}/versions/{version}/instruction-audio` inspecte
  son état ; `POST` le génère ou répare idempotemment son URL sous la clé stable
  dérivée de l'UUID de tâche. Rien n'est généré au boot ni au démarrage candidat.
  **`POST …?force=true` refait la synthèse même si l'objet existe** — seul moyen
  de corriger un audio devenu faux quand la consigne change (cas V756 : trois
  étapes à l'écran, quatre dans la voix), le retour anticipé idempotent ne sachant
  que réparer l'URL. **Opt-in strict** : sans le paramètre, le comportement est
  inchangé et aucun appel payant ne part, même sur une route rejouée. L'écrasement
  se fait **sous la même clé** (`putObject`, last-write-wins — jamais de delete,
  qui ouvrirait un 404 transitoire), donc l'URL en base et côté fronts ne bouge
  pas, et `generatedNow` dit la vérité : `true` seulement si une synthèse a eu
  lieu.
  **V756 raccourcit les deux consignes EN PLACE dans la version 1** (EE 100-120
  mots, EO 90-150 s) : les sujets de V755 se lisaient comme un examen complet dès
  le premier contact, alors que le diagnostic doit se lire « 5 minutes et je
  découvre mon niveau ». Aucun UUID ne bouge (clé de `diagnostic_sessions` **et**
  de l'audio R2), aucune allowlist n'est touchée — les incises « et ce que vous en
  avez pensé », « dites ce que vous cherchez » et « (activités, horaires, tarif,
  inscription) » sont conservées exprès, sans elles `EE2-C7`, `EO1-C3` et `EO2-C4`
  reviendraient `NOT_OBSERVED`. ⚠️ **L'audio de consigne de l'oral est donc faux
  tant qu'il n'est pas régénéré** par le `POST` ci-dessus. V756 retire au passage
  les bornes du diagnostic écrites en dur dans `chk_prod_task_tcf_irn_ee_word_bounds`
  (piège de V723/V724) : un sujet diagnostique est exempté de la table officielle,
  ses bornes vivent dans `production_tasks.mots_min/mots_max`.
- **« Avant / après » de l'écran de résultat — SECOND APPEL LLM SÉPARÉ, ÉCRIT
  SEULEMENT** (`service/diagnostic/exemplecible/`, livré **ACTIF**). Rend la
  phrase du candidat **et la même phrase réécrite au palier qu'il vise** : on ne
  lui dit pas qu'il a un problème, on lui montre à quoi ressemblerait sa propre
  phrase un cran plus haut. Jumeau de `service/versionciblee/`, mêmes invariants :
  **best-effort**, lancé par `ProductionPipelineAsyncRunner` **après** que
  l'analyse est persistée et la session assemblée, **hors transaction**, toute
  exception avalée, **aucun rejeu** — un échec laisse le diagnostic complet et la
  session `COMPLETED`. **Le contrat d'analyse (`diagnostic-analysis-*-v1`) ne
  bouge pas d'un octet** : le correcteur du diagnostic n'apprend jamais qu'on va
  réécrire quoi que ce soit (v10/v11 ont mesuré qu'un bloc ajouté à une grille qui
  juge fait tomber l'accord exact de 81,8 % à 75,6 %) ; verrou
  `DiagnosticExempleCibleContractTest`. **La production ORALE n'est jamais
  réécrite** — aucun appel n'est émis, aucun bloc produit. Le modèle **désigne la
  phrase par son NUMÉRO** (`EvaluationProductionSegments`, technique v12), le
  serveur la **résout en texte avant persistance** : aucun miroir DTO ne
  transporte d'entier. DTO `DiagnosticResultDto.exempleCible` **nullable**
  (`original` = sous-chaîne exacte de la production, `texte`, `segments[{extrait,
  apport}]`, `niveauVise`) — **son absence est un cas NORMAL**. Persisté dans
  `diagnostic_production_analyses.analysis_json.exemple_cible` (**aucune
  migration**, legacy intact) et **pas** dans `summary_json`, que le coordinateur
  remet à null puis reconstruit à chaque assemblage. Segments = **confort**
  (`util/SegmentsSurlignage`) ; bornes du texte = `util/ProductionTextBounds`,
  **plafond seul** (la borne basse décrit une production de 100 mots, on réécrit
  une phrase) ; filet marqueurs A2 sur les `apport`, **4ᵉ surface**
  (`EvaluationMarqueursA2`, compté `MARQUEUR_PALIER_APPORT_DIAGNOSTIC`). **Une
  seule réparation par bloc**, et seulement sur du mécanique (numéro hors bornes,
  texte trop long) ; compteurs dédiés `DiagnosticExempleCibleMetrics`. Retour
  arrière : `DIAGNOSTIC_EXEMPLE_CIBLE_ENABLED=false`.

Les migrations structurantes sont V029 (agrégats/observations et séparation des
tâches), V030 (événements du funnel), V031 (sources d'examen blanc +
`subject_id`, additive) et V755 (contenu initial). La suppression de
compte purge observations et sessions **avant** les attempts. Le détail grand
public du jugement et de ses limites est dans `docs/notation-ia-eo-ee.md`.

## Notation IA des productions EE/EO — repères

Le « quoi » et le « pourquoi » vivent dans `docs/notation-ia-eo-ee.md` (référence
grand public, **à tenir exhaustive et à jour dans la même passe** — cf. la règle
dédiée plus bas). Ici, uniquement de quoi se repérer.

- **Versions actives** : rubriques `production-rubrics-v15.json`, tool-schema de
  sortie `production-evaluation-tool-schema-v9.json`, persona vocale
  `realtime-personas-v3.json`. **v14/v8, v13/v7, v12/v6, v9/v5, v8/v5, v7/v4, v6/v3, v5/v3,
  v4.2/v2, v4.1/v2, v4/v2 et v3/v2 restent chargeables et validées** : un retour arrière
  change la paire `EVAL_RUBRICS_VERSION` + `EVAL_PROMPT_VERSION`, aucune migration.
  **On versionne, on ne réécrit jamais** une rubrique livrée. **v10 et v11 sont
  chargeables mais MESURÉES MOINS BONNES que v9 — ne pas les réactiver** (détail
  dans le filet de langue étrangère, plus bas).
- **v15 / v9 = `exemples_corriges` ET `suggestions` NE SONT PLUS PRODUITS.** v15 est **v14
  au bit près pour tout ce qui note** (échelle, 4 critères, seuils `commun.niveau`,
  `couplage`, `plafonds`, `bandes_criteres`, tests décisifs A1/A2 et B1/B2, les 16 ancres,
  descripteurs et barème des 6 tâches, et **les 23 sections restent 23** — aucune n'est
  ajoutée, retirée ni renommée) ; elle **retire uniquement les fragments qui décrivaient les
  deux champs** : le bloc EXEMPLES CORRIGES et le renvoi vers `suggestions` de la section
  « preuves et priorités », leurs deux lignes de « une erreur, un seul endroit », le
  paragraphe oral qui bornait les exemples à la clarté, les étapes 10-11 de la méthode, le
  plafond « 3 exemples corrigés », leurs mentions dans la règle d'accentuation et dans les 6
  consignes de tâche. Verrou : `ProductionEvaluationContractTest` **reconstruit v15 depuis
  v14** en appliquant la liste **énumérée** des retraits et exige l'égalité. Le tool-schema v9
  est **v8 sans ces deux propriétés ni leurs entrées `required`**, verrou : **égalité stricte**
  de tout le reste (`additionalProperties:false` récursif, titres, descriptions ; seule la
  `description` racine s'étoffe et doit commencer par celle de v8).
  Motif : le bloc replié **« Voir l'analyse complète »** de l'écran de résultat EE/EO — le seul
  endroit où ces deux champs étaient affichés — disparaît. On cesse de payer des tokens de
  sortie pour des pavés que personne ne lit, et la place gagnée finance un second appel plus
  utile (`version_ciblee`).
  ⚠️ **Ce qui NE sort PAS, et pourquoi** : `accomplissement` reste au contrat (son `objectif`
  et son `objectif_resume` alimentent le bandeau du haut, `points_traites` le compteur « Ce qui
  marche », et `points_oublies[].obligatoire` pilote `applyObjectifCoherence`) ;
  `avertissements` n'a **jamais** été dans le tool-schema — c'est le serveur qui l'écrit
  (`buildAvertissements`/`addAvertissement`), il est produit tel quel.
  Répercussions serveur : `EvaluationToolSchema.exemplesEtSuggestions()` (**deuxième capacité
  qu'un rang POSTÉRIEUR retire**, après `versionAmelioree()` — vaut depuis toujours, se referme
  en v9) ; **`EvaluationOutputValidator.CHAMPS_V4` devient dépendante du rang** — c'était une
  redéclaration EN DUR des champs obligatoires, en doublon du `required` du JSON : la laisser
  telle quelle aurait fait **rejeter 100 % des évaluations**. Elle est scindée en
  `CHAMPS_STRICTS_SOCLE` + `CHAMPS_RESTITUTION_LONGUE`, la seconde n'étant exigée que si
  `schema.exemplesEtSuggestions()`. Les deux champs restent **tolérés** à la racine sous v9
  puis retirés par `AiEvaluationService` (même arbitrage que `version_amelioree` : une
  évaluation perdue coûte plus cher qu'un champ ignoré) ; `persistProductionInvalide` ne les
  pose plus ; `EvaluationRepairPrompt` reçoit le contrat et cesse de nommer
  `exemples_corriges` (nommer un champ absent du schéma, c'est le faire produire). Les filtres
  (`EvaluationOralArtifactFilter`, `EvaluationPalierMarqueurFilter`, `capListe`,
  `stripOrthographicCorrections`) sont déjà no-op sur un champ absent — **inchangés**, ils
  restent exercés en retour arrière. **Legacy intact** : les 100+ `feedback_json` déjà
  persistés gardent les deux champs, rien ne les migre, la console de calibration admin les
  affiche toujours.
  ⚠️ **Bascule NON mesurée au banc** (aucune règle de notation ne bouge, et le prompt **perd**
  du texte au lieu d'en gagner — même raisonnement que v12/v13/v14, à l'inverse de v10/v11).
  Retour arrière : `EVAL_RUBRICS_VERSION=v14` + `EVAL_PROMPT_VERSION=v8`.
- **v14 / v8 = `version_amelioree` N'EST PLUS PRODUITE.** v14 est **v13 au bit près
  pour tout ce qui note** (échelle, 4 critères, seuils `commun.niveau`, `couplage`,
  `plafonds`, `bandes_criteres`, tests décisifs A1/A2 et B1/B2, les 16 ancres,
  descripteurs et barème des 6 tâches — verrouillé par
  `ProductionEvaluationContractTest`, qui reconstruit v13 depuis v14 en y **remettant**
  les fragments retirés) ; elle **retire** la section dédiée (23 sections au lieu de
  24), sa ligne dans « une erreur, un seul endroit », sa mention dans les champs
  obligatoires et dans la règle d'accentuation, et la dernière phrase des 6 consignes
  de tâche. Le tool-schema v8 est **v7 sans la propriété `version_amelioree`**, verrou :
  **égalité stricte** de tout le reste (`required` inchangé, `additionalProperties:false`,
  seule la `description` s'étoffe et doit commencer par celle de v7). Motif : les fronts
  ne l'affichent plus (texte modèle = `version_ciblee`, 2ᵉ appel) et elle réécrivait la
  production **au même niveau** que le candidat — recopiée et resoumise, même note au
  dixième près. Mesure sur les 12 évaluations EE qui la portent : **297 caractères,
  54 mots, ~5,7 % du JSON de sortie ⇒ ~90 tokens de sortie par correction écrite**
  (≈ 0,003 ¢ chez `deepseek-v4-flash` — le vrai gain n'est pas l'argent, c'est un champ
  obligatoire de moins qui peut faire échouer une soumission EE).
  Répercussions serveur : `EvaluationToolSchema.versionAmelioree()` (**première capacité
  qu'un rang POSTÉRIEUR retire** — s'ouvre en v5, se referme en v8), validateur qui ne
  l'exige plus sous v8 mais **la tolère** (une évaluation perdue coûte plus cher qu'un
  champ ignoré) et `AiEvaluationService` qui la retire sous v8 **comme il le faisait déjà
  en EO**. Legacy intact : les `feedback_json` déjà persistés la gardent.
  ⚠️ **Bascule NON mesurée au banc** (aucune règle de notation ne bouge, et le prompt
  **perd** du texte au lieu d'en gagner — à l'inverse de v10/v11). Retour arrière :
  `EVAL_RUBRICS_VERSION=v13` + `EVAL_PROMPT_VERSION=v7`.
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
- **VERSION AU NIVEAU VISÉ — SECOND APPEL LLM SÉPARÉ, EE *et* EO** (`service/versionciblee/`,
  livré **ACTIF**). Rend au candidat un **plan d'action** vers le palier qu'il VISE
  (`User.targetLevel` avec plancher `TargetProcedure.niveauVise`, repli
  `production_tasks.niveau_cible`). Distinct de `version_amelioree`, qui visait le palier
  **juste au-dessus**.
  **Contrat v2 (`VersionCibleeContrat`, registre par rang comme `EvaluationToolSchema` —
  une version inconnue échoue au BOOT, jamais de repli muet)** :
  - **commun** : `leviers[2..3]` = objets `{action ≤ 6 mots impératif, exemple ≤ 5 mots}`
    (fini la chaîne libre de 25 mots) + `a_retenir {formule ≤ 8 mots, explication ≤ 14 mots}` ;
  - **EE** : `exemple_cible {texte, segments[0..3] {extrait, apport ≤ 3 mots}}` — `texte` garde
    les bornes `production_tasks.mots_min/max` (recomptées serveur). ⚠️ **Les segments sont
    FACULTATIFS** (règle du 2026-08-11, elle **révoque** « 2 segments minimum, sinon ce n'est
    pas un chemin », qui ne vaut que pour les `reformulations` orales) : un extrait
    introuvable, un apport trop long ou un objet mal formé fait retirer **ce segment**
    (`VersionCibleeSegmentFilter`), l'`exemple_cible` survit dès que son `texte` est valide, et
    la section ne tombe que si le **texte** est fautif. Motif : le texte réécrit est ce que le
    candidat vient chercher — **afficher le texte sans surlignage vaut mieux que ne rien
    afficher**. Un extrait introuvable ne vaut **plus de réparation payée** (il ne coûte qu'un
    surlignage). Les 3 fronts étaient **déjà** prêts (web `asActionExempleCible` n'exige que
    `texte`, mobile idem) ;
  - **la comparaison extrait ⇄ texte neutralise la TYPOGRAPHIE** (`util/TexteNormalise`, NFKC,
    apostrophes courbes/droites, espaces insécables, tirets longs, ligatures, suites de blancs)
    **et rien d'autre** — ni casse, ni accents, ni appariement flou ; puis l'extrait servi est
    **remplacé par la sous-chaîne ORIGINALE exacte**, comme `resolvePreuveSegments`, pour que le
    front surligne par simple recherche de chaîne. Motif : nos textes portent des apostrophes
    courbes, le modèle rend des droites (ou l'inverse), et un extrait **juste** était déclaré
    introuvable. `EvaluationProofMatcher.normalizeToken` a été **déplacé** dans ce même fichier
    (`TexteNormalise.mot`, au bit près) : une seule normalisation, deux couches ;
  - **EO** : ⚠️ **la production orale n'est JAMAIS réécrite** (rendre un beau texte à la place
    d'une transcription est trompeur). `exemple_cible` est remplacé par
    `reformulations[2..3] {segment_numero, reformule, apport}` — **désignation par NUMÉRO**
    (technique v12 qui a fait tomber `PREUVE_NON_RATTACHEE`, 42,9 % des appels oraux), via
    `EvaluationProductionSegments` (**appelée, jamais recopiée**) ; tours `Examinateur :`
    montrés **sans numéro** ⇒ non désignables par construction. Le serveur **résout le numéro
    en texte** (`original`) avant persistance, comme `resolvePreuveSegments` : **aucun miroir
    DTO ne transporte d'entier** ;
  - **deux tool-schemas** (`…-tool-schema-v2.json` / `…-tool-schema-oral-v2.json`), chargés au
    boot par variante (`VersionCibleeTools`) ; les fondre en un seul aurait supposé des champs
    facultatifs, c'est-à-dire plus de contrat.
  **Trois garde-fous oraux, exigence du propriétaire** (« c'est la formulation des phrases
  qu'on reformule, pas les erreurs de transcription ») : (1) `TranscriptionQualityAudit
  .degradee` ⇒ **aucun appel émis**, gratuit et honnête ; (2) `VersionCibleeReformulationFilter`
  retire toute reformulation dont l'apport tient à **1 ou 2 mots pleins REMPLACÉS SUR PLACE** —
  règle du volet FORME extraite dans **`EvaluationOralForme`** (2ᵉ occurrence ⇒ extraction,
  partagée avec `EvaluationOralArtifactFilter`) ; l'alignement **positionnel** est le cœur :
  subordonner/réordonner déplace les mots, donc n'est jamais purgé ; (3) durée **jamais
  envoyée**, ni prononciation/accent/débit/fluidité/hésitations/orthographe. Moins de 2
  reformulations restantes ⇒ **1** réparation nommée puis abandon de la **section
  `reformulations` seule**. Purges comptées
  `EvaluationPurgeMetrics.REFORMULATION_ORALE_FORME` (à part de `ARTEFACT_ORAL_FORME`).
  ⚠️ **UNE SECTION QUI TOMBE N'EMPORTE PAS LE BLOC** (règle posée le 2026-08-11, elle
  **révoque** l'ancienne « moins de 2 ⇒ le bloc entier est abandonné »). `exemple_cible` /
  `reformulations` et `a_retenir` sont **facultatives** : inexploitables après l'unique
  réparation, elles tombent **seules** et le reste est servi. Seuls les **leviers** portent le
  bloc — purgés sous leur minimum et non réparés, tout est abandonné (comportement conservé).
  Motif, mesuré sur une tâche 1 d'EO en temps réel : sur une transcription hachée les
  reformulations sont **légitimement** purgées (elles ne corrigeraient qu'un artefact de notre
  machine) et le candidat perdait **aussi** ses leviers et son « à retenir », qui ne dépendent
  d'aucune citation — la fragilité des citations à l'oral ne doit pas emporter des contenus qui
  n'en dépendent pas. Le validateur range donc ses violations **par section**
  (`VersionCibleeValidator.Section`), et les trois fronts conditionnent déjà chaque section
  indépendamment.
  ⚠️ **C'est LE seul texte modèle d'un résultat EE** : les fronts ont retiré
  `version_amelioree` de l'écran, puis **v14/v8 l'a retirée du contrat de sortie** —
  elle n'est plus ni demandée ni produite (legacy persisté intact). Motif mesuré en base : elle était **au même niveau que la copie**,
  sans étiquette de palier — recopiée telle quelle et resoumise, elle rendait la
  **même note au dixième près**. `version_ciblee`, elle, **nomme son niveau**.
  ⚠️ **L'appel est séparé de la correction, c'est la raison même du montage** : le prompt de
  notation ne change pas d'un octet et le correcteur n'apprend **jamais** le niveau visé, sinon
  il aligne sa note dessus (v10/v11 ont mesuré qu'un simple bloc ajouté à la grille fait tomber
  l'accord exact de 81,8 % à 75,6 %). **Ne pas fusionner les deux appels.** Verrou :
  `VersionCibleeContractTest`.
  Prompts versionnés `production-version-ciblee-{rubrics,tool-schema[-oral]}-v2.json`, paire
  validée au boot ; **aucune consigne en dur dans le Java** ; français **accentué** (leçon
  v13/v7). `additionalProperties:false`, chaque plafond **déclaré en mots par la grille** ET
  doublé d'un `maxLength` + plafond serveur (tolérance ×1,2 sur les plafonds pédagogiques, **pas**
  sur les bornes du texte modèle) — **aucun champ où loger une note ou un niveau**. Le serveur
  ajoute `niveau_vise` / `niveau_constate` (⚠️ données de logique : ne pas en faire une étiquette
  de palier sur l'exemple, autre chantier).
  **UNE seule réparation par bloc, tous motifs confondus** (`VersionCibleeRepairPrompt`) — pas
  une par section — et seulement sur du **mécanique nommable** : longueur du texte, numéro hors
  bornes, leviers purgés, reformulations purgées. Sortie structurellement fausse ⇒ **zéro**
  second appel payé, et **leviers** structurellement faux ⇒ aucune réparation non plus (le bloc
  est condamné, payer ne rachèterait rien).
  **Tolérance des plafonds pédagogiques : `PlafondMots.tolere` = `max(plafond+1,
  floor(plafond×1,2))`** (2026-08-11). L'ancienne formule seule était **fictive sur les petits
  plafonds** : sur `apport` (3 mots) elle tolérait 3, soit **zéro marge**, exactement là où la
  tolérance avait été écrite pour servir. Effet mesuré, plafond par plafond : `apport` 3→**4**
  (avant : 3) ; `exemple` 6, `action` 7, `formule` 9, `explication` 16, `reformule` 72,
  `ce_qui_manque` 30 — **inchangés**. Même correction, même passe, sur le module Compétences
  (`CompetenceAnalysisValidator` : `strength_tag`/`focus_tag` 3→**4** ;
  `CompetenceNiveauViseValidator` : `apport` 3→**4**). Ne s'applique **pas** aux bornes du
  texte modèle (`ProductionTextBounds`), qui restent au mot près.
  **Compteurs `VersionCibleeMetrics`** (troisième famille, à ne pas mélanger avec
  `EvaluationRefusalMetrics` « un refus coûte la tâche » ni `EvaluationPurgeMetrics` « une purge
  retire une phrase ») : **section abandonnée** par section × motif, **réparation payée** par
  motif, **segment retiré** par motif. Sans eux, la disparition intermittente de la section
  n'avait que deux `log.info` pour l'expliquer et aucune de ces décisions n'était jugeable sur
  des chiffres.
  **Best-effort, jamais bloquant** : lancé par `ProductionPipelineAsyncRunner` **après** que
  l'éval est persistée et `EVALUATED`, **hors transaction** (invariant du runner), le service
  avale toute exception, **aucun rejeu** (c'est un confort, pas une correction). Rien n'est
  produit si le niveau visé est **≤** au niveau constaté (bloc `niveau_vise_atteint` à la place)
  ou si le drapeau est éteint.
  Persistance dans `feedback_json.version_ciblee` — **aucune migration**. Un front distingue
  l'écrit de l'oral à la présence de `exemple_cible` ou de `reformulations`. Tokens/coût du 2ᵉ
  appel **additionnés** à ceux de l'éval. Provider = `production-evaluation.provider` (règle
  « un seul correcteur configurable »), réglages propres sous
  `production-evaluation.version-ciblee` (`enabled`, `max-tokens: 1600`, `max-leviers: 3`).
  Retour arrière : `EVAL_VERSION_CIBLEE_ENABLED=false`, ou **v1** par
  `EVAL_VERSION_CIBLEE_RUBRICS_VERSION=v1` + `EVAL_VERSION_CIBLEE_TOOL_SCHEMA_VERSION=v1`
  (sortie `texte` + `ce_qui_manque[string]`, oral muet) — **aucune migration**, on versionne, on
  ne réécrit jamais. **Aucune campagne requise** : rien de ce qui note ne bouge, par
  construction. Le banc (`CalibrationRunner`) n'emprunte pas ce chemin.
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
    (string racine) **obligatoire en EE, absente en EO** (retirée serveur) —
    ⚠️ champ **supprimé du contrat en v14/v8**, cf. plus haut. Le
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
  le **modèle et ses tarifs** sont des `${EVAL_*_MODEL/COST_INPUT/COST_OUTPUT/COST_CACHED_INPUT}` ;
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
  le coût, 2026-08-08).
  ✅ **CHOIX CLOS le 2026-08-16 : `flash` est retenu, motif LATENCE.** 16,3 s de
  médiane et 36 s au pire appel contre 28,8 s / 66,7 s pour `pro` — c'est le seul
  écart que le candidat ressent, il attend sa correction devant l'écran. Renforcé
  par un fait mesuré le même jour : **la justesse se gagne dans les contrats et les
  contrôles serveur, pas dans le moteur** (+14,5 points d'accord exact sans changer
  de modèle). Payer 4,5× pour `gpt-5.4`, qui note **aussi juste** (81,3 % des deux
  côtés), n'achèterait pas de la précision ; et les 42,9 % d'appels refusés à l'oral
  se traitent chez **nos validateurs**, pas chez le fournisseur. Ne pas rouvrir ce
  dossier sans une mesure neuve, à réessais égaux.
  **Le rejet est un problème purement ORAL** : 0 % d'appels refusés en EE chez les
  trois moteurs. Et ce ne sont pas des JSON cassés — ce sont **nos validateurs** qui
  refusent des sorties bien formées.
  ⚠️ **Les tarifs du tableau ci-dessus datent de l'ANCIENNE grille** (relevés le
  2026-08-07 : flash 0,14 / 0,28 ; pro 0,435 / 0,87) — conservés parce que les
  campagnes ont été payées à ce prix-là. La grille **en vigueur** est celle du
  2026-08-16 16:00 UTC, à trois tarifs et deux plages horaires (cf. § *Ce que coûte
  un appel LLM* ci-dessous).
  `timeout-sec` deepseek 60 → **90** (read timeout **par appel** : pire appel `flash`
  36 s, `pro` 67 s ; les « 5 min » d'un rapport sont un **cas entier**, pas un appel).
  Bascule = un bloc de `.env`. Détail : `docs/notation-ia-eo-ee.md` §12.6.
- **Ce que coûte un appel LLM — TROIS tarifs, deux plages horaires, et un cout au
  MICRO-DOLLAR** (2026-08-16). Autorité unique : **`util/CoutAppelLlm`**, extraite à
  la **11ᵉ** occurrence — chacun des 11 clients portait sa propre copie de
  `estimateCostCents`, et passer de 2 tarifs à 3 les aurait fait diverger. Contrat
  partagé : **`config/TarifsLlm`** (implémenté par `BlocTarifs`, dont héritent les 3
  blocs provider).
  - **Grille DeepSeek en vigueur depuis le 2026-08-16 16:00 UTC** (USD / 1M tokens),
    en heures creuses : `flash` **0,007 / 0,22 / 0,66** (entrée cache hit / cache
    miss / sortie), `pro` **0,022 / 0,66 / 1,98**. **Heures pleines = ×2 sur les
    trois**, sur **01:00-04:00 et 06:00-10:00 UTC**. L'ancienne paire `0,14 / 0,28`
    était fausse **dans les deux sens** : sortie sous-estimée ×2,4 à ×4,7, entrée
    cache miss ×1,6 à ×3,1, et entrée cache **hit SUR**estimée ×20.
  - **Un multiplicateur, pas six chiffres** : la grille est exactement
    proportionnelle (×2 sur les 3 tarifs et les 2 gammes), donc
    `peak-multiplier` + `peak-utc-ranges` disent la même chose sans tripler la
    surface d'env. Si un fournisseur cessait d'être proportionnel, **alors** on
    scinde. Les bornes horaires vivent **en configuration**, jamais en dur.
    L'heure est résolue **à l'instant de l'appel**, en UTC, depuis un `Clock`
    paramètre du calcul (`CoutAppelLlm(tarifs, horloge)`) — testable, jamais un
    `Instant.now()` enfoui dans 11 clients.
  - **Le découpage cache hit / miss est LU, jamais deviné** : DeepSeek renvoie
    `usage.prompt_cache_hit_tokens`, OpenAI `usage.prompt_tokens_details.cached_tokens`,
    les deux dialectes sont acceptés (`CoutAppelLlm.lireCacheHitTokens`). **Absent ⇒
    tout en cache miss**, l'hypothèse **prudente** : on surestime, jamais l'inverse.
    Même repli quand un provider ne déclare pas de tarif de cache (`0` ⇒ plein tarif).
    🛑 **L'invariant « changer de LLM ne touche aucun `.java` ni `.yaml` » survit** :
    tarif de cache et heures pleines sont **facultatifs**, avec des neutres (`0`, `1`,
    `""`), verrouillé par `EvaluationProviderSwapTest`.
  - **Fin de l'arrondi au centime supérieur.** `Math.ceil(usd * 100)` multipliait par
    ~8 la facture d'une micro-analyse (~0,0013 $) : la campagne de 90 cas du
    2026-08-16 a persisté **90 centimes pour 9,9 centimes réels**, et
    `CompetenceCalibrationReport` avait dû republier un `cout_reel_usd` recalculé pour
    le contourner (supprimé, il n'a plus lieu d'être). Le coût est désormais un
    **entier de micro-dollars** — additionnable sans erreur flottante quand un second
    appel s'ajoute au premier, et arrondi au **micro-dollar supérieur** (même prudence,
    granularité 10 000× plus fine).
  - **V034, additive** : `cout_micro_usd` (+ `cost_micro_usd` côté diagnostic) et
    `tokens_input_cache_hit` sur `ai_evaluations`, `user_skill_attempts`,
    `diagnostic_production_analyses`. Le cache **miss** n'a pas de colonne, il se
    déduit. 🛑 `cout_estime_centimes` / `cost_estimate_cents` deviennent **LEGACY,
    plus jamais écrites, plus mappées** — les valeurs restent, **aucun recalcul
    rétroactif** : le prix du jour n'a jamais été stocké à côté des tokens, le
    recalculer serait une invention.
  - **V035, additive : la TRANSCRIPTION suit** (2026-08-16). V034 avait laissé
    `transcriptions.cout_estime_centimes` active au motif que Whisper facture **à la
    minute d'audio, pas au token** — exact sur la **formule**, faux sur l'**unité** :
    `Math.ceil` au centime facturait **1 centime** un audio de 95 s (la médiane du
    dépôt) qui en vaut 0,95, soit **~5 % de trop**, et c'était le dernier endroit du
    dépôt à arrondir une facture au centime. Nouvelle colonne
    `transcriptions.cout_micro_usd` ; l'ancienne devient **LEGACY, plus jamais
    écrite, plus mappée, valeurs intactes** — même doctrine, **aucun recalcul
    rétroactif**.
    🛑 **Les deux formules restent distinctes, seule l'unité est partagée** :
    `util/MicroDollars` (conversion + arrondi au supérieur) est appelé par
    `CoutAppelLlm` (au token) **comme** par `CoutTranscription` (à la minute). Ne pas
    tordre `CoutAppelLlm` pour y faire entrer Whisper, ni recopier la règle d'arrondi
    — c'est le motif qui a fait supprimer les 11 `estimateCostCents`.
    Le tarif à la minute vit désormais **en configuration**
    (`sejourfr.openai.whisper.cost-per-minute-usd`, `OPENAI_WHISPER_COST_PER_MINUTE`,
    défaut YAML **et** POJO `0.006`), jamais en constante Java : il **voyage avec le
    modèle**, dans la même source, comme les tarifs des correcteurs. `0` ⇒ rien n'est
    facturé (colonne `NULL`) plutôt qu'un montant inventé.
  - **Le cache PEUT mordre chez nous, et l'ordre des prompts est déjà bon** (vérifié
    le 2026-08-16, aucun réordonnancement nécessaire — en faire un aurait changé ce
    que le correcteur lit, donc la version du contrat). La grille invariante est le
    **message système**, envoyé en tête : **~80 ko sur 120** pour les productions
    (`commun.sections` 58 ko + few-shot 22 ko), **~94 %** pour Compétences,
    `versionciblee` et `niveauvise`. Rien de variable ne la précède, et la production
    du candidat est **le dernier élément** du message utilisateur. Verrou :
    `EvaluationPromptBuilderTest.le_prefixe_envoye_au_correcteur_est_invariant_donc_le_cache_peut_mordre`
    — ne jamais glisser d'horodatage, d'identifiant ni de compteur en tête d'un
    prompt, c'est invisible fonctionnellement et ça éteint la remise de 31×.
    ⚠️ Le **taux de cache réel** n'est pas mesuré : c'est précisément ce que la
    nouvelle colonne servira à répondre, en une requête SQL.
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
- **Titre éditorial d'un sujet** : `production_tasks.titre` (colonne V028,
  **nullable** ; contenu V754 — les **103** sujets publiés). Les cartes de sujet
  affichaient « Sujet 01 » + le début de la consigne, or les consignes d'une même
  tâche commencent toutes pareil. Contenu **généré**, jamais écrit à la main dans
  le SQL (`backend_sejourfr/tools/production-titres/`, même convention que
  `tools/competences/`), et **éditable en console** une fois les migrations
  appliquées (`/api/admin/production-tasks`, feature admin `productionTasks/`) :
  c'est la base qui fait foi. **Repli obligatoire quand le titre manque** :
  « Sujet N » + consigne, déclaré une seule fois par front
  (`productionSubjectTitle`, `lib/types.ts` ⇄ `widgets/production_common.dart`,
  libellé gelé par test des deux côtés). Aucun écran ne suppose le titre présent.
- **Fluidité de la session vocale temps réel** (chantier du 2026-08-12, les 3
  surfaces). Le ressenti « l'examinateur met trop longtemps à répondre » avait une
  cause unique et symétrique : **le gate qui coupe le micro pendant que
  l'examinateur parle se levait sur une estimation arithmétique** (durée théorique
  de l'audio reçu + 900 ms), aveugle au retard réel de la file. Trop tôt, le micro
  rouvrait pendant la parole et l'écho repartait à Gemini en **faux tour
  candidat** ; trop tard, les **premiers mots du candidat étaient jetés** et tout
  le tour glissait. Le gate suit désormais la **position de lecture réelle** —
  `playHead` côté web, `remainingFrames` du moteur natif + file côté mobile, sur
  **horloge monotone** (`Stopwatch`, jamais `DateTime.now()`). Marge 900 → 100 ms,
  tenue micro 300 → 120 ms : ces deux valeurs ne compensaient que l'imprécision
  supprimée. **Ne pas les regonfler** sans remettre une estimation à la place.
  - **Le micro reste coupé pendant que l'examinateur parle** (half-duplex,
    anti-écho) — arbitrage du propriétaire, 2026-08-12. L'AEC mobile n'a pas le
    signal joué par `flutter_pcm_sound` comme référence, donc un full-duplex
    ferait s'auto-interrompre l'examinateur. Le code de flush `interrupted` reste
    en place, **inatteignable mais intact** : ne pas le supprimer.
  - **Chunk micro 20–40 ms des deux côtés** (recommandation Google). Le worklet
    web postait un render quantum brut = **un message WS toutes les 8 ms**
    (~125/s, 256 o utiles pour ~344 car. de base64) ; il accumule maintenant
    40 ms. Mobile : `streamBufferSize` explicite — ⚠️ **l'unité diffère**,
    Android compte des **octets**, iOS/macOS des **frames**.
  - **Pré-roll de lecture** (120 ms web / 150 ms mobile) : sans lui, un hoquet
    réseau donne un trou puis un clic. Amorçage forcé en fin de tour pour ne pas
    coincer une réponse courte.
  - 🛑 **VAD de fin de tour : `END_SENSITIVITY_MEDIUM` N'EXISTE PAS.** L'enum du
    fournisseur n'a que `..._UNSPECIFIED`, `..._LOW` et `..._HIGH` — sur chacune
    des deux sensibilités. Posée le 2026-08-12 (« répondre plus vite en fin de
    tour »), cette valeur a fait répondre `auth_tokens` en **400
    INVALID_ARGUMENT à CHAQUE émission de token** : `GeminiTokenBroker.mint`
    levait, `RealtimeSessionService.start` retombait en `ASYNC_FALLBACK`, et
    **plus une seule session temps réel n'a eu lieu du 2026-08-12 au 2026-08-16**
    (dernière ligne `realtime_sessions` : 2026-08-11 21:33) — sur les **deux**
    fronts, **en silence** : le candidat choisissait « Avec un examinateur » et
    atterrissait sur l'enregistreur solo, sans un mot. **La valeur retenue est
    donc `LOW`** : c'est le réglage le plus lent, mais `HIGH` couperait un
    apprenant A2 en pleine hésitation et il n'y a pas de troisième choix — le
    vrai levier de réactivité est `silence-duration-ms`, pas cette enum.
    Deux verrous posés le 2026-08-16 : allowlists
    `RealtimeProperties.Vad.{START,END}_SENSITIVITES` **opposées au BOOT**
    (`GeminiTokenBroker.assertVadSupportee` → une valeur inconnue fait échouer le
    démarrage, jamais de repli muet — philosophie des contrats de prompts), et un
    **message au candidat** quand son choix de temps réel n'aboutit pas
    (`kRealtimeUnavailableMessage` ⇄ `REALTIME_UNAVAILABLE_MESSAGE`, miroirs mot
    pour mot) : on continue de ne **jamais** le bloquer, mais on ne le dépose
    plus sur l'enregistreur solo comme s'il l'avait choisi.
    `silence-duration-ms` reste à **500** (plancher Google, en dessous les pauses
    naturelles fragmentent l'énoncé) et `prefix-padding-ms` à **300** (sinon la
    première syllabe est rognée). Les 5 valeurs sont surchargeables par env.
  - **Reprise de session** (`sessionResumption` + `contextWindowCompression`,
    V032 additive, `POST /api/realtime/eo/sessions/{id}/resume`). Le token vise
    l'endpoint **contraint** : le client ne peut poser **aucun** champ de setup,
    donc il **relaie son handle au serveur**, qui le verrouille dans le setup d'un
    nouveau token. Seul montage possible — ne pas tenter de reconnecter en
    réutilisant l'ancien token. `uses` 1 → 3 et `newSessionExpireTime` 120 → 600 s
    (120 s ne couvrent pas un tunnel de métro : le token mourait avant le retour
    du réseau, la reprise aurait été illusoire). ⚠️ **Non vérifié contre l'API
    réelle** que Gemini accepte `sessionResumption` dans un setup verrouillé —
    repli `REALTIME_SESSION_RESUMPTION_ENABLED=false`.
  - **Quota jamais débité deux fois** : `appendTranscript` lisait la session
    **sans verrou**, deux transactions concurrentes pouvaient toutes deux voir
    `PENDING` et décrémenter (`decrementRealtimeSessions` est atomique mais
    conditionné à `> 0` : il ne protège pas contre deux débits **légitimes**).
    Verrou pessimiste de ligne, `finish` restant volontairement non transactionnel.
    `turnIndex` rend `appendTranscript` **idempotent** : un réessai doit repartir
    avec le **même** index, attribué à la construction du lot et non à l'envoi.
    C'est l'invariant qui protège le quota — **aucun front ne rappelle
    `POST /sessions` après une coupure**, ce serait un second slot.
- **Écran allumé — primitives partagées, un seul point de câblage par front.**
  Mobile `core/utils/screen_wake_lock.dart` (`ScreenWakeLock`, **refcount par
  raison**, exceptions plateforme avalées, ré-application au retour au premier
  plan car Android relâche en arrière-plan) + widget déclaratif
  `core/widgets/keep_screen_awake.dart` ; web `lib/use-screen-wake-lock.ts`
  (`useScreenWakeLock(active)`, détection de capacité — absente sur Safari iOS
  < 16.4 et Firefox — et **ré-acquisition sur `visibilitychange`**, le navigateur
  relâchant le verrou dès que l'onglet passe en arrière-plan). Câblé dans
  `RecordingController` (mobile) et `EoRecordingForm` (web), qui servent **à eux
  seuls** production EO + compétences EO + diagnostic ; plus `SejourAudioPlayer`
  pour la réécoute et l'écran temps réel. ⚠️ Le câblage mobile passe par le **flux
  d'état** du service, pas par `start()/stop()` : l'auto-stop de `maxDuration`
  appelle `stop()` sur le **service**, pas sur le controller — un acquire posé
  dans `start()` fuirait à chaque enregistrement arrivé au bout. **Aucune
  permission `WAKE_LOCK`** : `wakelock_plus` pose `FLAG_KEEP_SCREEN_ON` sur la
  fenêtre, qui n'en exige pas ; la déclarer ne ferait que salir la fiche Play Store.
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
- **Volet FORME du même filet — une faute de grammaire ORALE est une STRUCTURE, jamais
  la forme d'un mot** (`EvaluationOralArtifactFilter`, livré **ACTIF** le 2026-08-09).
  Cas réel : « « abit à Lille » (j'habite) » reproché en `morphosyntaxe` alors que le
  candidat avait dit « j'habite » — la transcription avait mangé le « j'h ». Mesure sur
  les 142 évaluations en base (passages cités, présents verbatim, absents d'un
  dictionnaire de 475 k formes) : **9 EO sur 75 (12,0 %), 0 EE sur 67**. **Zéro à
  l'écrit** ⇒ la cause est la machine, pas le niveau. Règle : un reproche ancré dont une
  citation ne nomme qu'**1 ou 2 mots porteurs** est purgé ; **0 mot porteur**
  (« pour ne pas que ») = structure pure, **conservée** ; **≥ 3** = structure, conservée.
  **EO seulement, critère `morphosyntaxe` + priorités qui le relisent seulement** —
  jamais `lexique` (deux faux positifs réels mesurés : `chronoposte`, `ESN`, ce dernier
  cité en **point fort**), jamais l'écrit. Ni note, ni niveau, ni seuil ne bougent ;
  avertissement candidat + compteur `ARTEFACT_ORAL_FORME`. **Coût assumé et mesuré** :
  11 phrases sur 75 commentaires EO tomberaient, dont ~7 portaient AUSSI une vraie faute
  — la phrase entière part (retirer une citation au milieu d'une énumération rendrait un
  texte mutilé). Corollaire honnête : **ça ne change aucune note**, donc le palier du cas
  réel (A2 → B1 si on retirait les 3 fautes) n'est **pas** corrigé.
  Au passage, `reprocheDeNiveauMot` (volet MOT) exige désormais ≥ 1 mot porteur :
  il purgeait par inadvertance les citations 100 % mots-outils, qui sont de vrais
  reproches de grammaire. Resserrement pur.
- **UN SEUL avertissement sur une production ORALE** (2026-08-17). Le bloc « À savoir sur
  cette évaluation » empilait **trois** paragraphes ; il n'en porte plus qu'un,
  `AiEvaluationService.AVERTISSEMENT_TRANSCRIPTION`, réécrit en trois phrases : « Nous
  analysons la transcription écrite de votre enregistrement, pas votre voix — et la
  transcription peut se tromper. Dans ce cas, l'erreur ne vous est jamais comptée. La
  prononciation et l'aisance ne sont donc pas évaluées ici. » Les constantes
  `AVERTISSEMENT_ARTEFACT`, `AVERTISSEMENT_FORME` et `AVERTISSEMENT_LANGUE` d'
  `EvaluationOralArtifactFilter` sont **supprimées**, ainsi que les trois `addAvertissement`
  qui les posaient. Motifs : elles racontaient au candidat la **mécanique interne** de nos
  purges, et leur seul contenu utile (« la transcription peut se tromper, on ne vous le
  compte pas ») est **exactement** ce que dit la 2ᵉ phrase du texte unique — d'où l'absorption
  de `AVERTISSEMENT_LANGUE` avec les deux autres. La mention « prononciation et aisance »
  est **conservée** (la retirer laisserait croire que l'oral a été jugé dessus et que c'est
  bon) ; le renvoi à l'examen officiel part dans `docs/notation-ia-eo-ee.md` §9.
  🛑 **Aucun filtre n'est désactivé, aucun compteur n'est retiré** : les purges des trois
  volets tournent à l'identique et restent comptées par `EvaluationPurgeMetrics` — c'est le
  **texte affiché** qui disparaît, pas le nettoyage ni sa trace. Ne pas recréer ces
  constantes. Miroirs front (le **repli** quand la liste arrive vide sur une tâche orale,
  évaluations antérieures) : `web/ProductionFeedbackView.TRANSCRIPTION_LIMIT` ⇄
  `mobile/kOralEvaluationLimitNotice`, mot pour mot. **Legacy intact** : les `feedback_json`
  déjà persistés gardent leurs anciens textes, aucune migration, et les fronts affichent la
  liste reçue quel qu'en soit le nombre. Les **commentaires de critère de remplacement**
  (`COMMENTAIRE_CRITERE_PURGE*`, `OBJECTIF_RESUME_PURGE_LANGUE`) sont **inchangés** : ce sont
  des champs obligatoires qui ne peuvent pas rester vides, pas des avertissements. Le
  **diagnostic** n'est pas concerné (`DiagnosticOralArtifactFilter` remplace le `summary`, il
  ne pose aucun avertissement).
- **Indicateur de qualité de transcription** (`TranscriptionQualityAudit`, migration
  `V027`). Whisper renvoie `segments[].avg_logprob/no_speech_prob/compression_ratio` dans
  `verbose_json` — **payés depuis toujours, jamais lus** ; le temps réel n'expose rien.
  Deux taux **déterministes et gratuits** sur les seuls tours `Candidat :` : **formes
  suspectes** (mots de 1-3 lettres absents d'un inventaire fermé d'~290 entrées, incluant
  `MOTS_OUTILS_FR`) > **10 %**, ou **collages** (deux formes suspectes qui se suivent) >
  **2 %** ⇒ transcription **dégradée**. Plancher 40 mots. **Pas de dictionnaire français
  embarqué** (2-4 Mo de jar, licence tierce) : mesuré sur les 123 productions mesurables
  de la base, l'inventaire fermé **sépare mieux** qu'un OOV brut (les mots longs
  hors-vocabulaire sont des noms propres, sigles et néologismes d'apprenant). La coupure
  colle **exactement** à la fenêtre du bug « mot coupé » : 8 sessions du 28/06 au 04/07 à
  **18,29-26,94 %**, les 24 suivantes **< 4,84 %**, aucune observation entre les deux.
  Déclenche **deux choses et rien d'autre** : le volet FORME passe en mode large, et la
  **confiance** est plafonnée `FAIBLE` avec sa raison (obstacle à l'**observation**, pas
  défaut du candidat). **Note, niveau et seuils ne bougent jamais.** Les deux taux + les
  3 indicateurs Whisper sont **persistés** sur `transcriptions` (index partiel
  `idx_transcription_degradee`) : le bug de juillet aurait été visible **en une requête**.
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
  Une épreuve **ouverte puis abandonnée** (`timer_started_at` posé, chrono
  écoulé, rien rendu) reste, elle, comptée `A1_NON_ATTEINT` — elle a été passée
  et ratée. ⚠️ **Une épreuve JAMAIS OUVERTE en sort** (2026-08-15) :
  `timer_started_at` NULL **et** rien de rendu (aucune réponse en CO/CE, aucune
  soumission en EE/EO) ⇒ `cecrlLevel` **null**, hors plancher, donc
  `finalLevelPartial` vrai. Les **deux** critères, jamais l'un seul : tous les
  sous-attempts antérieurs au chrono par épreuve portent `timer_started_at`
  null, et s'en contenter effacerait le niveau d'épreuves réellement passées.
  Motif mesuré : un candidat ayant joué CO (A2) + CE (A1) puis quitté voyait ses
  EE/EO closes par le front, notées `A1_NON_ATTEINT`, son A2 écrasé, et un bilan
  annoncé **complet sur 4 épreuves**. Même raisonnement que la branche `locked`
  vingt lignes plus haut — une porte jamais franchie n'a pas été passée, et
  `null = inconnu, jamais mauvais`. ⚠️ **Le serveur ne refuse PAS
  `markSubAttemptDone` sur une épreuve jamais lancée** (pas de 422) : le flux
  d'abandon volontaire des fronts l'appelle avant `finish`, qui exige tous les
  sous-attempts terminés — un refus casserait le bouton « Abandonner ».
  Abandonner sans ouvrir l'EE est un geste **valide** ; c'est le **verdict**
  qu'on en tirait qui était faux. Conséquence côté fronts : une sous-épreuve
  terminée, non verrouillée, sans échec et **sans niveau** est désormais un cas
  normal, à lire « non passée » et **jamais** « évaluation en cours » (web :
  état `not_taken` de `subAttemptView` ; mobile : `SubAttempt.jamaisOuverte` —
  sans quoi un spinner tourne sans issue). Partialité
  exposée aux fronts par `epreuvesCountedInFinalLevel` / `epreuvesExpected` /
  `finalLevelPartial` (+ `finalLevelPartial` sur le résumé) : aucun front ne doit
  plus écrire « le plus bas de tes 4 épreuves » en dur, ni agréger un examen
  partiel dans un « meilleur niveau » sans l'annoter. V024 a remis à NULL les
  `final_cecrl_level` déjà persistés à tort sur les examens verrouillés.
- **Niveau TCF estimé d'un CANDIDAT** (≠ résultat d'un examen) —
  `TcfProfileService`, arbitré le 2026-08-08 : **plancher des 4 épreuves,
  chaque épreuve retenant son MEILLEUR résultat, une épreuve abandonnée sans
  rien rendre étant EXCLUE**. « Aucune preuve » n'est pas « mauvaise preuve » :
  `null = inconnu, jamais mauvais`, même principe que `finalCecrlLevel`.
  - **« Abandonnée sans rien rendre »**, écrit dans le code : CO/CE = examen
    fini avec **zéro réponse** (filtre `EXISTS` de
    `AttemptRepository.findQcmEpreuvesPassees`, verrouillé par
    `AttemptManagerIT`) ; EE/EO = **zéro soumission évaluée**.
  - **Les productions entrent enfin dans le calcul** : EE/EO sont lues dans
    `ai_evaluations` (meilleur niveau d'une **tâche** évaluée, la plus récente
    évaluation faisant foi par soumission). Avant, le niveau ne regardait que
    `attempts.cecrl_level` — un candidat qui ne travaillait qu'en EE/EO restait
    à « — » indéfiniment, et un examen complet abandonné le figeait à
    « < A1 ».
  - **Une seule surface publie ce niveau** : `DashboardSummaryResponse
    .estimatedTcfLevel` (`GET /api/me/dashboard`), lu tel quel par le web
    (dashboard, profil, statistiques, `TcfHub`, examens-blancs) et le mobile
    (accueil, profil). **Aucun front ne le recalcule.** Libellé aligné des deux
    côtés : il contient toujours le mot **« estimé »**.
  - L'endpoint `GET /api/tcf/profile/level` et son client mobile
    `tcfLevelProfile()` (zéro appelant) ont été **supprimés** : deux surfaces
    HTTP répondant différemment à la même question, c'est exactement ce qui a
    produit l'incohérence.
- **Ce qui reste ouvert** : `ProductionBilanService` (bilan d'**une épreuve**
  de production) garde sa **moyenne** pondérée des 3 tâches, et
  `FullTcfExamResponseBuilder` (niveau d'**un examen complet**) garde son
  plancher où une épreuve abandonnée compte `A1_NON_ATTEINT`. L'arbitrage
  ci-dessus ne vaut que pour le **niveau d'un candidat dans le temps** — ne pas
  le propager à ces deux calculs sans une décision explicite.

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

## L'audio d'une production de candidat n'est pas conservé (2026-08-16)

Décision du propriétaire, **motif consentement** : « on ne stocke pas les
enregistrements audio des gens ; l'audio sert **uniquement** à produire la
transcription, et après la transcription on ne le stocke pas ». Ce qui reste
d'une production orale, c'est **son texte**.

- **Aucune production de candidat n'est écrite sur R2.** `ProductionAudioStorageService`
  (préfixe `submissions/`) et `SkillTranscriptionService` sont **supprimés** — pas
  désactivés : il n'existe plus de code capable d'écrire ou de relire un audio de
  candidat. Les trois voies concernées étaient les **productions EE/EO**
  (`production_submissions.media_url`), les **micro-exercices de compétence EO**
  (`user_skill_attempts.audio_object_key`) et l'**oral du diagnostic** (qui passe
  par la même route de production). La session vocale **temps réel** n'a jamais
  rien persisté (flux client ⇄ Gemini, production = transcript).
- 🛑 **Ne touche PAS aux audios ÉDITORIAUX** : consignes du diagnostic, exemples
  EO, audios de compréhension orale, médias de questions. Ils passent par
  `CloudflareR2Client` / `MediaStorageService` et sont du **contenu**, pas de la
  donnée personnelle.
- 🛑 **Rien n'est supprimé rétroactivement** : les objets déjà sur R2 restent, les
  clés déjà en base restent. `media_url` et `audio_object_key` deviennent des
  colonnes **LEGACY, plus jamais écrites**. **Ne jamais écrire de migration de
  purge, de job de suppression ni de `delete` rétroactif.**
- **La transcription est SYNCHRONE**, dans la requête de soumission — seul moment
  où les octets existent. Ordre volontaire : **transcrire PUIS insérer**. Un échec
  Whisper ne laisse alors **aucune ligne**, **aucun quota consommé**, et le
  candidat renvoie depuis son appareil (les 4 fronts gardent le fichier local
  après un envoi raté). L'ordre inverse fabriquerait des productions `FAILED`
  définitivement irrécupérables. Coût mesuré sur la base : audio médian 90 s,
  p90 175 s ⇒ quelques secondes d'attente ajoutées à l'envoi, contre ~0 avant.
- **`AudioEphemere.avecOctets` est le seul endroit qui tient la promesse** : le
  tampon est remis à zéro dans un `finally`, donc **aussi quand la transcription
  échoue**. À utiliser dès qu'on manipule les octets d'une production.
- **`spring.servlet.multipart.file-size-threshold: 26MB`** : au défaut (`0B`)
  Spring écrivait **tout** upload multipart dans un fichier temporaire — l'audio
  touchait le disque à chaque soumission. Ne pas rabaisser.
- **Les runners ne transcrivent plus.** `ProductionPipelineAsyncRunner` et
  `SkillAnalysisAsyncRunner` partent toujours d'une production **écrite** ; une
  production orale sans transcription est un état impossible (sauf ligne
  antérieure) et échoue clairement au lieu de noter du vide.
- **Retries** : le retry d'une **évaluation** repart de la transcription (il ne
  relisait déjà que le texte). Le retry d'une **transcription** n'existe plus —
  un échec est une **réponse HTTP 503** (`GlobalExceptionHandler.handleTranscription`)
  qui dit au candidat de **renvoyer**, pas d'attendre. Le retry **agrégé du
  diagnostic** et `POST /api/skill-attempts/{id}/analyse` sont inchangés, mais
  `analyse` refuse **avant** de consommer le quota une tentative orale LEGACY
  sans transcription.
- **Aucun DTO ne porte plus d'URL audio** : `ProductionSubmissionDto.mediaUrl` et
  `SkillAttemptDto.audioUrl` sont **retirés** du backend et des **trois miroirs**
  (`admin/src/types/api.ts`, `web/lib/types.ts`, `mobile/core/models/*.dart`).
  `mediaDurationSec` / `audioDurationSec` restent : la durée n'est pas l'audio.
- **Écrans** : aucun ne propose plus de réécouter une production **soumise** (web
  `CompetenceResult`, mobile `competence_result_screen`, admin
  `calibration/ProductionView` — les seuls qui le faisaient). ✅ **La réécoute
  LOCALE, avant validation, reste** : le fichier est encore sur l'appareil, rien
  n'est stocké, et elle protège le candidat d'envoyer une prise ratée.
- Contraintes desserrées par **V033** : `chk_prod_sub_audio_or_text` (une
  soumission orale n'a plus ni média ni texte, sa production vit dans
  `transcriptions`, comme le temps réel depuis V017) et
  `chk_user_skill_attempts_has_production` (qui accepte désormais `transcript`).

## Module « Compétences TCF » (micro-entraînement EE/EO)

Voie **parallèle** aux productions complètes, pas une réutilisation : le candidat
travaille **une micro-compétence à la fois** sur un « petit sujet » de quelques
phrases. Schéma en `V025`, contenu seedé en `V300..V305` (lot 1) puis
`V312..V317` (lot 2).

⚠️ **RÈGLE RÉVOQUÉE À MOITIÉ le 2026-08-11 : niveau OUI, note /20 NON.**
L'ancienne formule « cette voie ne rend ni note /20 ni niveau CECRL » **ne vaut
plus pour le niveau**. Elle laissait le candidat sans réponse à « où j'en suis »,
alors que c'est exactement ce qu'il vient chercher : sa démarche exige un palier
(CSP→A2, CR→B1, NAT→B2) et l'écran ne le situait nulle part. Depuis le contrat
**v3**, le correcteur attribue un `level_reached` (`A1_NON_ATTEINT|A1|A2|B1|B2`,
profil TCF IRN, **jamais C1/C2**). **La note /20 reste interdite et le restera** :
aucun champ du tool-schema ne peut la loger, et c'est le schéma qui tient la
règle, pas une consigne. Ne pas réintroduire l'ancienne formule au motif qu'elle
est encore écrite quelque part — ce qui suit fait foi.

**Où ça vit** — tables `skills`, `skill_prompts`, `skill_references`,
`user_skill_attempts` (DDL `00_schema/V025__schema_competences_tcf.sql`, seed
`300_tcf/competences/V300..V317`). Backend : `service/competence/` (analyse IA) +
`SkillService` / `SkillAttemptService` / `SkillStatusResolver` /
`SkillAnalysisAccessService` / `AdminSkillService`. **12 endpoints utilisateur**
(`/api/skills*`, `/api/skill-attempts*`, `/api/skill-prompts*`) et **11 endpoints
admin** (`/api/admin/skills*`, `/api/admin/skill-prompts*`) — détail dans
`docs/api-endpoints.md`. Fronts : web `app/_components/competences/` + routes
`…/entrainement/tcf/{ee,eo}/tache/[n]/competences/…`, mobile
`lib/screens/tcf_production/competences/` + `core/models/skill_models.dart` ;
point d'entrée = 3ᵉ onglet « Compétences » à côté de « Sujets » et « Exemples »,
qui **pousse** vers le nouvel écran au lieu d'ouvrir un onglet local.

- **DEUX APPELS LLM SÉPARÉS, invariant à ne pas casser.** L'**appel 1** juge et
  **ne connaît jamais le palier visé par le candidat** ; l'**appel 2** (« pour
  viser X ») reçoit niveau constaté + niveau visé et produit le plan d'action.
  Motif **mesuré** côté productions : donner l'objectif au correcteur fait tomber
  l'accord exact de **81,8 % à 75,6 %** (campagnes v10/v11). Montage calqué sur
  `service/versionciblee/`. **Ne pas fusionner.** ⚠️ **Depuis v5, l'appel 1 ne
  reçoit PLUS AUCUN niveau cible** — même pas celui de la **compétence** (donnée
  éditoriale du sujet, comme `production_tasks.niveau_cible`), qui y était jusqu'à
  v4 sans que la grille le nomme nulle part : une étiquette de palier posée dans
  le même objet JSON que le texte à niveler. Autorité unique :
  `CompetenceRubricsProvider.envoieLeNiveauCibleDeLaCompetence()`, allowlist des
  versions v1..v4 (un retour arrière doit reproduire le prompt d'avant, une
  version future ne doit pas hériter du défaut). Verrous :
  `CompetenceAnalysisServiceTest`, `CompetenceRubricsProviderTest`.
- **v6 = LE COÛT DE NOMMER UN PALIER DEVIENT LE MÊME PARTOUT** (2026-08-16,
  rubriques v6 / tool-schema **v5**). v6 est **v5 au bit près pour tout ce qui
  JUGE** (rôle, périmètre, les 3 verdicts et leur règle de décision,
  `commun.statuts`, `commun.niveaux`, `commun.contraintes_longueur`, la brièveté
  qui n'est pas un défaut, le garde-fou oral, et **les 10 ancres dans leur
  substance**) — verrou `CompetenceAnalysisContractTest`, qui **reconstruit v5
  depuis v6** par une liste **énumérée** de 6 éditions et exige l'égalité. Le
  tool-schema v5 est **v4 avec `level_evidence` dans son `required`**, verrou :
  **égalité stricte** de tout le reste (types, bornes,
  `additionalProperties:false`, les 5 autres propriétés au caractère près) ; les
  2 descriptions éditées se **reconstruisent** elles aussi en celles de v4.
  - **Le défaut corrigé est dans le MÉCANISME, pas dans une consigne.** Sous v4,
    annoncer un B1/B2 obligeait à fournir un numéro de segment, et un numéro
    absent/faux faisait **abaisser le verdict d'un palier** ; annoncer un A2 ne
    coûtait **rien** et ne risquait **rien**. Le mécanisme lui-même rendait le
    palier bas confortable et le haut risqué — et **aucune ancre ne pouvait le
    corriger**, d'où les 3 ancres de v5 restées sans effet sur la cause. Mesure
    en base : **0 B2 sur 18 tentatives**.
  - **L'EFFORT devient symétrique, la SANCTION reste où elle protège.** Le
    correcteur désigne **toujours** le segment sur lequel il fonde son verdict,
    `A1_NON_ATTEINT` compris. Mais `CompetenceLevelEvidenceGuard` **n'abaisse que
    sur un B1/B2 mal étayé** : abaisser un A2 punirait la prudence, exactement
    l'inverse du but. Un défaut sous le B1 est **compté**
    (`CompetenceLevelDowngradeMetrics.enregistrerSansSanction`, clés
    `MOTIF/SANS_SANCTION/<palier>`, **même famille** — c'est la seule façon de
    comparer les deux moitiés de l'échelle) et **ne vaut aucune réparation
    payée** : le correcteur ne l'anticipe pas au moment de produire, donc l'appel
    n'achèterait rien. Coût d'exploitation **inchangé**.
  - 🛑 **Une preuve manquante ne fait toujours JAMAIS échouer l'analyse.**
    `level_evidence` reste **hors de `CompetenceAnalysisValidator`**, seul
    habilité à rendre `FAILED`, **y compris sous v5 où le schéma la rend
    requise** : c'est le fournisseur qui l'exige, jamais nous. La méthode
    s'appelle désormais **`estExclueDuValidateur`** (et non plus
    `estOptionnelle`) parce que le nom invitait à recopier le `required` du JSON
    dans le jeu de clés vérifié — ce qui aurait fait **rejeter 100 % des
    sorties** qui l'omettent : le piège exact de
    `EvaluationOutputValidator.CHAMPS_V4`.
  - **Le numéro reste résolu en TEXTE avant persistance**, aux paliers bas comme
    aux hauts : `analysis_json.level_evidence` porte le passage, jamais l'entier
    — **aucun miroir DTO à propager sur les 3 fronts**, aucun écran modifié.
  - **Les 6 ancres qui n'avaient pas de preuve en portent une**, dont celle
    d'`A1_NON_ATTEINT` : elle désigne le passage qui **MONTRE** que le palier
    n'est pas atteint (la phrase en langue étrangère). Une ancre qui omettrait la
    preuve apprendrait au correcteur à s'en passer, précisément là où v6 veut
    qu'il ne s'en passe plus.
  - **Rang lu par ALLOWLIST explicite** (`CompetenceAnalysisFields
    .exigeLaPreuveSurTousLesPaliers`), jamais un `!= v6` — patron
    `CompetenceRubricsProvider.envoieLeNiveauCibleDeLaCompetence` : une version
    future ne doit pas hériter du comportement par accident. Retour arrière :
    `COMPETENCE_RUBRICS_VERSION=v5` + `COMPETENCE_TOOL_SCHEMA_VERSION=v4`
    reproduit le comportement d'avant **au bit près** (champ facultatif, aucune
    anomalie comptée sous le B1, rappel du prompt reformulé à l'identique).
    Aucune migration, `analysis_json` legacy intact.
  - ✅ **MESURÉ le 2026-08-16** — trois campagnes de 90 cas sur
    `golden-set-competences-v1.json`, le **même jour**, `retries=1`, même
    provider/modèle (`deepseek-v4-flash`), rapports dans `target/calibration/` :

    | | **v4/v4** | **v5/v4** | **v6/v5** |
    |---|---|---|---|
    | accord exact niveau | 71,1 % | 82,2 % | **85,6 %** |
    | accord statut critère | 88,9 % | 87,8 % | **90,0 %** |
    | B2 · A2 · B1 justes (/18) | 8 · 13 · 13 | 13 · 16 · 15 | **14 · 17 · 16** |
    | écart de palier moyen | 0,0 | +0,02 | −0,01 |
    | échec de production | 0 % | 0 % | 0 % |
    | paires confondues (tâche, /540) | 74 | 43 | **39** |

    **+14,5 points** d'accord exact, 0 échec sur 270 appels, **0,33 $** au total
    (tarifs alors configurés). 🛑 **Les deux moitiés de l'échelle montent
    ENSEMBLE** — c'était la condition de réfutation : les A2 justes passent de 13
    à 17 *pendant que* les B2 passent de 8 à 14, et l'écart moyen reste à zéro.
    Le correcteur ne note pas plus haut, il note plus juste.
  - ⚠️ **Le diagnostic initial était PLUS GROSSIER que la réalité, et la campagne
    l'a corrigé.** On croyait à un **plafonnement au A2** (« 0 B2 sur 18 » en
    base). Faux : v4 rend déjà 10 B2 sur 90 cas. Le vrai défaut est une
    **compression vers le MILIEU** — v4 rendait 27 B1 là où le corpus en attend
    18, en absorbant par le bas les B2 (9 des 18 attendus B2 sortaient B1) et par
    le haut les A2 (5 des 18 attendus A2 sortaient B1). v5+v6 décompressent les
    deux extrêmes. Corollaire : le « 0 B2 » de la base ne prouvait pas que le
    correcteur en soit incapable — il disait peut-être seulement que ces 18
    productions réelles n'étaient pas B2. **Ne pas rejouer ce raisonnement sur un
    échantillon de production sans référence.**
  - ⚠️ **Un point de la prédiction reste INVÉRIFIÉ** :
    `PREUVE_ABSENTE/SANS_SANCTION/*` vit en mémoire (`LongAdder`) et n'est pas
    exporté dans le rapport de banc, donc rien ne prouve encore que l'effort est
    devenu symétrique **dans les faits** (le modèle pourrait omettre le champ en
    bas d'échelle malgré le `required`). À exporter avant d'en tirer une
    conclusion sur le mécanisme lui-même.
- **v5 = LE NIVEAU CESSE D'ÊTRE PLAFONNÉ AU A2** (2026-08-16). Mesuré par SQL sur
  la base locale : **0 B2 sur 18 tentatives**, jamais ; une production fautive et
  une production propre avec subordonnée et conditionnel recevaient **le même
  A2** ; **aucun sujet rejoué n'a jamais rendu deux niveaux différents**. Trois
  causes, toutes **lisibles dans le prompt lui-même**, trois éditions et rien
  d'autre : **(a)** les 7 ancres v4 étaient A2×4, B1×2, A1×1 — **zéro B2, zéro
  `A1_NON_ATTEINT`** ⇒ 3 ancres ajoutées (2 B2, 1 `A1_NON_ATTEINT`), le A2 restant
  majoritaire (on ouvre le haut de l'échelle, on ne bascule pas le prior) ;
  **(b)** retrait de « *c'est même le cas le plus fréquent, et c'est normal* », une
  **consigne de répartition** — l'idée légitime (verdict et niveau indépendants,
  un critère peut être validé à un palier modeste) est conservée ; **(c)** le
  `targetLevel` de la compétence quitte le prompt (ci-dessus). v5 est **v4 au bit
  près pour tout ce qui JUGE** (rôle, les 3 verdicts et leur règle de décision,
  `commun.statuts/niveaux/contraintes_longueur`, la brièveté, le garde-fou oral,
  la preuve du niveau par numéro) — verrou `CompetenceAnalysisContractTest`, qui
  **reconstruit v4 depuis v5** par l'unique édition énumérée et exige l'égalité des
  11 sections et des 7 premières ancres. **Le CONTRAT DE SORTIE NE BOUGE PAS** :
  v5 déclare `tool_schema_version: v4`, aucun champ ajouté ni retiré, aucun miroir
  front — première version de ce module à réutiliser le schéma de la précédente
  (`TOOL_SCHEMA_BY_RUBRICS_VERSION` : `v5 -> v4` ; demander un « v5 » échoue au
  boot). ⚠️ **Bascule NON mesurée, et il n'existe AUCUN corpus de
  micro-productions avec niveau attendu** (le golden-set des 48 cas est celui des
  productions complètes) : ce qui la justifie, c'est qu'on retire des **biais
  visibles dans le prompt**, pas qu'on règle un curseur. Retour arrière :
  `COMPETENCE_RUBRICS_VERSION=v4` + `COMPETENCE_TOOL_SCHEMA_VERSION=v4`.
- **Contrat de l'analyse (appel 1)** : rubriques
  `prompts/competence-analysis-rubrics-v5.json` + tool-schema
  `prompts/competence-analysis-tool-schema-v4.json` (`profile: TCF_IRN`, paire
  `rubrics-version` ⇄ `tool_schema_version` validée au boot — **aucune consigne de
  notation en dur dans le Java**). **v3 = v2 au bit près pour tout ce qui JUGE**
  (rôle et périmètre, les 3 verdicts et leur règle de décision, la brièveté qui
  n'est pas un défaut, le garde-fou oral, `commun.statuts`) — verrouillé par
  `CompetenceAnalysisContractTest`, qui compare les blocs et **reconstruit** la
  section d'accentuation de v2 depuis celle de v3 (2 éditions inversées, technique
  de `ProductionEvaluationContractTest`). Sortie stricte à **5 champs** (6 sous
  v4), `additionalProperties: false` : `status` (`VALIDATED|PARTIAL|NOT_VALIDATED`),
  **`level_reached`** (`A1_NON_ATTEINT|A1|A2|B1|B2`), `verdict` (20 mots),
  **`strength_tag`** et **`focus_tag`** (**3 mots** chacun — des étiquettes, pas
  des phrases). **Retirés du contrat** : `success_point`,
  `improvement_priority`, `improved_version` — même mouvement que v14/v8 côté
  productions (retirer un champ du schéma est la façon la plus fiable de le faire
  disparaître) ; les leviers de l'appel 2 les remplacent.
  ⚠️ **Legacy non migré** : les `analysis_json` déjà persistés portent les 5
  anciennes clés. `SkillAnalysisDto` les expose encore, **tous nullables**, et le
  jeu de clés attendu d'une NOUVELLE sortie suit la version du contrat
  (`CompetenceAnalysisFields.cles(toolSchemaVersion)`) — c'est ce qui garde
  `COMPETENCE_RUBRICS_VERSION=v2` + `COMPETENCE_TOOL_SCHEMA_VERSION=v2` (ou v1)
  réellement jouable. `LearningPlanObservationService` replie
  `improvement_priority` → `focus_tag` → `verdict`.
  Contraintes de longueur **en mots** déclarées par la grille (20 / 3 / 3),
  doublées de `maxLength` en caractères dans le schéma ; le validateur tolère
  ×1,2 avant de rejeter. Sortie invalide → **un seul rejeu** avec les violations,
  puis **échec net** (`FAILED`) — jamais d'analyse partielle.
- **v4 = LE NIVEAU DEVIENT OPPOSABLE, il ne se nomme plus à vue** (2026-08-11).
  Sous v3 le correcteur écrivait `level_reached` d'après cinq lignes de
  descripteurs, **sans note, sans seuil, sans ancre chiffrée et sans aucun
  contrôle serveur en aval**, alors qu'une production complète **dérive** le sien
  d'une note contrainte par `applyCouplage`/`applyPlafonds` : deux grandeurs
  portaient le nom de la même échelle CECRL sans être commensurables. v4 est
  **v3 au bit près pour tout ce qui juge** (`commun.statuts`, `commun.niveaux`,
  `commun.contraintes_longueur`, et toutes les sections sauf deux) — verrou
  `CompetenceAnalysisContractTest`, qui **reconstruit v3 depuis v4** en inversant
  les 2 seules éditions (« Les cinq champs à produire » → « six » + un paragraphe
  ajouté **en fin** de section ; « des cinq prévus » → « des six prévus » dans les
  interdictions) et vérifie que les 6 ancres de v3 sont reprises **au numéro de
  preuve près**.
  - **Preuve par NUMÉRO, jamais par citation** — même technique que le contrat
    **v12** des productions, pour la même raison mesurée (`PREUVE_NON_RATTACHEE`
    = 42,9 % des appels sur les productions orales). La production part au
    correcteur **découpée en segments numérotés** par
    **`EvaluationProductionSegments`** — la classe des productions complètes,
    **appelée, jamais recopiée** (EE = une phrase, EO = un tour `Candidat :`, les
    tours examinateur montrés **sans numéro**). Nouveau champ **`level_evidence`**
    = **entier ≥ 1**, **optionnel dans le schéma** : seuls B1 et B2 se démontrent,
    et l'exiger partout pousserait à désigner un segment « par défaut ».
  - **`CompetenceLevelEvidenceGuard` est la seule autorité.** Numéro absent sur un
    B1/B2, hors bornes, ou non entier ⇒ **une** réparation actionnable
    (`CompetenceEvidenceRepairPrompt` : nomme le numéro refusé, rappelle les
    bornes **réelles**, redonne les deux sorties sûres — technique
    `EvaluationRepairPrompt`, motif mesuré : un libellé brut répare **0 preuve
    sur 8**). Cette réparation est **partagée** avec celle du validateur : une
    sortie malformée et une preuve manquante partent dans le **même** message, on
    ne double pas les appels. Après elle, le serveur **abaisse d'un palier, une
    seule fois, et ne relève JAMAIS** (philosophie `applyCouplage` /
    `applyPlafonds` / `applyConfiance`).
  - 🛑 **Une preuve manquante ne fait JAMAIS échouer l'analyse** — c'est pourquoi
    `level_evidence` est **volontairement hors du `CompetenceAnalysisValidator`**,
    qui a le pouvoir de rendre `FAILED`. Une analyse perdue coûte au candidat sa
    production et son quota ; un niveau prudent ne lui coûte qu'un affichage.
  - **Le numéro est résolu en TEXTE avant persistance** (comme
    `resolvePreuveSegments`) : `analysis_json.level_evidence` porte le passage,
    jamais l'entier, donc **aucun miroir DTO à propager sur les 3 fronts**. Le
    passage **n'est exposé à aucun front** (rien ne l'affiche — pas d'API morte),
    mais il est **persisté** : c'est ce qui permettra de répondre en une requête
    SQL à « sur quoi ce B2 était-il fondé ? ».
  - Abaissements comptés par **`CompetenceLevelDowngradeMetrics`** (motif +
    `avant->après`), **distinct** de `EvaluationRefusalMetrics` (un refus coûte la
    tâche) et de `EvaluationPurgeMetrics` (une purge retire une phrase) : les
    mélanger rendrait la mesure illisible.
  - ⚠️ **AUCUNE campagne ne l'appuie**, et ce qui tient la règle reste la
    contrainte dure (schéma `integer`/`minimum:1` + contrôle serveur), pas une
    mesure a posteriori. ⚠️ En revanche, la phrase « il n'existe aucun corpus
    pour la voie Compétences » est **révoquée** : il en existe un depuis le
    2026-08-16 (cf. le banc ci-dessous). L'instrument existe, la mesure reste à
    payer.
  - Retour arrière : `COMPETENCE_RUBRICS_VERSION=v3` +
    `COMPETENCE_TOOL_SCHEMA_VERSION=v3` — sous v3 le découpage n'est même pas
    calculé et le prompt repart **inchangé d'un octet**
    (`CompetenceAnalysisFields.porteLaPreuveDuNiveau`).
- **Contrat du plan d'action (appel 2)** : `service/competence/niveauvise/` +
  `prompts/competence-niveau-vise-{rubrics,tool-schema}-v3.json`. Sortie stricte à
  **3 champs**, `additionalProperties: false` : `leviers[2..3]`
  `{action ≤6 mots impératif, exemple ≤5 mots, procede}`, `exemple_cible`
  `{texte, segments[2..3] {extrait, apport ≤3 mots}, marqueurs_du_palier[2..3]
  {extrait, type}}`, `a_retenir` `{formule ≤8 mots, explication ≤14 mots}`.
  **Aucun champ de note, de verdict ni de niveau** : le serveur pose lui-même
  `niveau_vise` / `niveau_constate`.
- **v3 = UN LEVIER NOMME UNE OPÉRATION DE LANGUE** (2026-08-16). Chaque levier
  gagne un **`procede` requis**, `enum` reprenant **exactement** `MarqueurPalier`
  — la même énumération, la même table de compatibilité procédé ⇄ palier
  (`MarqueurPalier.demontre`), jamais une copie. Motif, cas réel : les trois
  leviers servis vers le B2 étaient « Rends ton invitation plus chaleureuse »,
  « Propose une alternative concrète », « Termine par une formule engageante » —
  des conseils de **ton**, qu'on peut suivre à la lettre en restant A2. Le filet
  `EvaluationMarqueursA2` ne pouvait rien y voir (liste fermée de 6 mots-outils,
  égalité exacte) et **il ne faut pas l'élargir** : deux variantes plus larges ont
  déjà été mesurées et rejetées côté productions pour faux positifs.
  - 🛑 **RÈGLE ABSOLUE : un levier n'est JAMAIS purgé à cause de son procédé.**
    Ce qui tient la règle, c'est le **schéma** — le modèle ne peut plus produire
    un conseil de ton sans le rattacher à un moyen de langue réel —, pas une
    sanction à l'affichage. Les leviers portent le **bloc entier** (purgés sous
    leur minimum et non réparés, tout est abandonné) : purger sur ce motif
    viderait l'écran du candidat. Donc procédé **manquant**, **inconnu** ou qui
    **sur-vend** le palier cible ⇒ le levier est **servi tel quel**, l'anomalie est
    **comptée**, et **aucune réparation payée** n'est déclenchée.
    `CompetenceNiveauViseProcedeAudit` est la seule autorité ; il ne retire
    jamais un levier, seulement le procédé fautif de l'objet persisté.
  - **Le procédé fautif n'est PAS persisté** (arbitrage). Le champ n'est exposé à
    **aucun front** (doctrine `level_evidence` — pas d'API morte) : il existe pour
    répondre en **une requête SQL** à « ce levier nommait-il un vrai moyen de
    langue ? ». Une colonne pouvant contenir n'importe quelle chaîne du modèle ne
    répond à rien ; un procédé **absent** dit exactement « ce levier n'était pas
    vérifiable », et le compteur porte le motif.
  - **Le validateur ADMET le procédé, il ne le juge pas** : une violation de la
    section `LEVIERS` est **fatale**, l'y ranger reviendrait à purger. Il n'ajoute
    donc que la clé à l'allowlist du levier.
  - Compteurs : `CompetenceNiveauViseMetrics.procedeAnormal` →
    `PROCEDE_ANORMAL/{ABSENT,INCONNU,SUR_VENDU}`. Famille inchangée, jamais
    mélangée à `EvaluationRefusalMetrics` ni `EvaluationPurgeMetrics`.
  - Le filet **`CompetenceNiveauViseLevierFilter`** (marqueur A2 vendu pour un
    palier supérieur) est **conservé inchangé** : lui purge, c'est un motif
    différent, et il garde sa réparation. Ne pas le fusionner avec le nouveau
    contrôle, ne pas le désactiver.
  - **v3 = v2 au bit près** pour tout ce qui juge, pour `exemple_cible` et pour
    `a_retenir` : seule la section « Les leviers » est éditée, plus un `procede`
    ajouté à chaque levier des 2 ancres. Verrou :
    `CompetenceNiveauViseContractTest` **reconstruit v2 depuis v3** (rubriques et
    tool-schema) par une liste **énumérée** d'éditions.
  - **Retour arrière réel** : `COMPETENCE_NIVEAU_VISE_{RUBRICS,TOOL_SCHEMA}_VERSION=v2`
    (ou `v1`) — sous v2 le champ n'est ni demandé dans le prompt, ni admis par le
    validateur (il redevient une clé hors contrat), ni compté. Conditionné par une
    **allowlist explicite** (`CompetenceNiveauViseFields.porteLeProcedeDesLeviers`,
    patron `CompetenceRubricsProvider.envoieLeNiveauCibleDeLaCompetence`), jamais
    par un test `!= v3`. Aucune migration.
  - ⚠️ **Non mesuré, et il faut le dire** : il n'existe **aucun corpus** de
    micro-productions avec un niveau attendu (le banc porte sur les productions
    complètes). Défendable sans mesure parce qu'on **ajoute une contrainte de
    schéma** — la façon la plus fiable de rendre un comportement impossible — et
    qu'on ne déplace **aucun seuil, aucune note, aucun niveau**.
- **v2 = LE PALIER DEVIENT EXIGIBLE** (2026-08-16). Trois changements, un seul
  motif — mesuré en base : un candidat a copié-collé le `exemple_cible.texte`
  servi comme « version pour viser B2 », l'a resoumis, et l'appel 1 l'a réévalué
  **A2** (`written_production = analysis_json->'pour_viser'->'exemple_cible'->>'texte'`
  vaut `true`). Rien n'obligeait ce texte à être au niveau annoncé, et la consigne
  tirait dans l'autre sens (« longueur PROCHE de la sienne »).
  - **Le texte modèle vise la MARCHE SUIVANTE** : `palierCible = min(constaté + 1,
    visé)`, ramené dans `[A2, B2]`. **Autorité unique**
    `CompetenceNiveauViseService.palierCible`, à côté de la garde « constaté ≥ visé
    ⇒ aucun appel » (inchangée). Effet voulu : les 2 ancres few-shot (A2→B1,
    B1→B2) couvrent désormais 100 % des cas — le cas réel était un saut A2→B2
    **sans aucune ancre**. Le palier VISÉ du candidat reste calculé comme avant
    (`TargetProcedure.niveauVise`, plancher de la démarche) mais devient le
    **plafond** de l'ambition. `SkillLevelProgressResolver` / `SituationNiveauVise`
    **inchangés** : c'est là que le candidat se situe par rapport à son objectif
    réel. ⚠️ `analysis_json.pour_viser.niveau_vise` et donc
    `SkillNiveauViseDto.niveauVise` portent le **palier cible**, pas l'objectif —
    aucun changement de type, seuls les libellés fronts bougent.
  - **`marqueurs_du_palier` requis** : 2 à 3 passages **recopiés du texte modèle**
    + un `type` d'une énumération fermée (`MarqueurPalier` : `REGISTRE_AJUSTE` /
    `ARTICULATION_LOGIQUE` A2, `SUBORDINATION` / `LEXIQUE_PRECIS` B1, `NUANCE` /
    `OBJECTION_TRAITEE` B2). Doctrine du dépôt : un champ **requis et vérifiable**
    force le contenu, une consigne ne serait qu'un vœu. Extraits résolus par
    `util/SegmentsSurlignage` (mécanique partagée, jamais recopiée) ; un type qui
    **sur-vend** le palier cible est retiré (`objection_traitee` pour viser A2). La
    table `MarqueurPalier` est **opposée à `commun.marqueurs_palier` au BOOT**
    (divergence ⇒ échec du démarrage). **Persistés, exposés à aucun front** (même
    arbitrage que `level_evidence`) : ils répondront en SQL à « sur quoi ce B1
    était-il fondé ? ».
  - **Longueur du texte modèle bornée** par `skill_prompts.recommended_min/max_words`
    (**plafond seul, au mot près, sans tolérance** — patron `ProductionTextBounds`
    + `ProductionPayloadSupport.countWords`), bornes **injectées dans le prompt**
    (`mots_min`/`mots_max`). `null` sur un sujet **oral** (il porte une durée, pas
    une fourchette) : on n'invente pas de borne.
  - 🛑 **Rien ne disparaît de l'écran.** Les violations sont désormais rangées
    **par section** (`CompetenceNiveauViseValidator.Section`, patron
    `VersionCibleeValidator`) : `exemple_cible` et `a_retenir` tombent **seules**,
    seuls la racine et les **leviers** emportent le bloc. Un marqueur retiré, comme
    un segment, ne coûte que sa propre mise en évidence et **n'ouvre aucun appel
    payé**. **Une seule réparation par bloc, tous motifs confondus**
    (`CompetenceNiveauViseRepairPrompt.pour`) : leviers purgés **et/ou** texte hors
    bornes partent dans le **même** message actionnable.
  - Compteurs : `CompetenceNiveauViseMetrics` gagne `Motif.TEXTE_HORS_BORNES`,
    `sectionAbandonnee(section, motif)` et `marqueurRetire(motif)` — même famille,
    jamais mélangée à `EvaluationRefusalMetrics` ni `EvaluationPurgeMetrics`.
  - Retour arrière sans migration : `COMPETENCE_NIVEAU_VISE_RUBRICS_VERSION=v1` +
    `COMPETENCE_NIVEAU_VISE_TOOL_SCHEMA_VERSION=v1` — sous v1 **tout** ce chantier
    est inerte (ni marqueurs, ni bornes de longueur). Verrou :
    `CompetenceNiveauViseContractTest` reconstruit le tool-schema v1 depuis v2 par
    une liste **énumérée** d'éditions.
  - **Fronts** : l'intertitre nomme le palier cible — « Pour passer au niveau B1 »
    (`pourPasserAuTitle`, web `skill-ui/ActionPlan.tsx` ⇄ mobile
    `widgets/action_plan.dart`), déclaré une fois par front. `pourViserTitle`
    **reste** pour les productions complètes, dont le `niveauVise` est toujours
    l'objectif. ⚠️ **Aucune campagne** : le corpus de calibration est celui des
    productions complètes, il n'existe aucun corpus pour cette voie.
  Persisté dans `user_skill_attempts.analysis_json.pour_viser` — **aucune
  migration**.
  - **Best-effort, jamais bloquant** : lancé par `SkillAnalysisAsyncRunner`
    **après** que l'analyse est persistée et `EVALUATED`, **hors transaction**
    (même invariant que `ProductionPipelineAsyncRunner`), toute exception avalée,
    **aucun rejeu**. Si le bloc manque, l'écran reste utile. ⚠️ Conséquence
    assumée : la tentative passe `EVALUATED` **avant** l'arrivée du bloc — les
    fronts doivent traiter `niveauVise == null` comme un cas NORMAL, pas une
    erreur (même course que `version_ciblee` côté productions).
  - **Aucun appel émis** si le visé n'est pas **strictement au-dessus** du
    constaté, si l'analyse ne porte aucun niveau (contrat v1/v2), si le palier
    visé est introuvable, ou si `niveau-vise.enabled=false`. Économie réelle, pas
    seulement un bloc absent.
  - **Deux contrôles serveur.** (1) **les `segments` sont un confort de lecture,
    le texte est la pièce centrale** (aligné sur `version_ciblee` le
    **2026-08-12**) : un segment introuvable dans `exemple_cible.texte`, mal
    formé ou au-delà du 3ᵉ est **retiré**, `exemple_cible` survit dès que son
    `texte` est valide (présent, non vide), et la section ne tombe que si le
    **texte** est fautif. Un extrait introuvable **n'ouvre plus droit à
    réparation payée** — il ne coûte que son surlignage. La comparaison neutralise
    la **typographie** (`util/TexteNormalise`) et l'extrait servi est la
    **sous-chaîne originale exacte** du texte, le front surlignant par simple
    recherche de chaîne : rien d'inventé n'est jamais affiché. **Mécanique
    partagée** avec les productions — `util/SegmentsSurlignage`, câblé sur les
    noms de champs de chaque contrat — précisément parce que deux copies avaient
    divergé (l'ancienne règle « un extrait introuvable emporte tout le bloc »
    était restée dure ici après avoir été assouplie là-bas). Le tool-schema v1
    continue d'exiger 2 à 3 segments : **aucune version de contrat n'a bougé**,
    seul le serveur a cessé de punir.
    (2) filet marqueurs A2 sur les leviers, **3ᵉ occurrence** du même défaut :
    `EvaluationMarqueursA2.designe` est réutilisé tel quel (le levier est inspecté
    comme `action + « exemple »`, ce qu'il est sémantiquement), et
    `EvaluationMarqueursA2.sousLeNiveauVise` a été **extrait** à cette occasion,
    `VersionCibleeLevierFilter` l'utilisant désormais aussi. Reste < 2 leviers ⇒
    une réparation, puis abandon. **Une seule réparation par bloc, tous motifs
    confondus** — et c'est désormais le **seul** motif qui en vaut une. Compté
    `EvaluationPurgeMetrics.MARQUEUR_PALIER_LEVIER_COMPETENCE`.
  - **Compteurs `CompetenceNiveauViseMetrics`** (bloc abandonné par motif,
    réparation payée, segment retiré) : famille **distincte** de
    `VersionCibleeMetrics` (même mesure, mais sur l'écran des productions), de
    `EvaluationRefusalMetrics` (un refus coûte la tâche) et de
    `EvaluationPurgeMetrics` (une purge retire une phrase). Pas de compteur « par
    section » ici : les 3 champs du contrat sont requis ensemble, le bloc tombe
    d'un bloc — seul un **segment** peut disparaître seul.
  - **Niveau visé = `TargetProcedure.niveauVise(procedure, targetLevel)`**, la
    démarche fait **plancher** ; repli sur `skills.target_level`. Ne jamais
    réécrire cette table.
- **Dérivé serveur `SkillLevelProgressResolver`** (jamais un front, jamais le
  LLM) : compare `level_reached` au palier visé et rend `SituationNiveauVise` +
  son libellé, l'**échelle de 3 crans** se terminant sur l'objectif (B2 →
  A2·B1·B2) et l'**index du curseur** (ramené dans l'échelle s'il est en dessous
  du premier cran). Exposé par `SkillLevelProgressDto`. Le palier visé est
  **recalculé à la lecture**, jamais figé dans l'analyse : un candidat qui passe
  de CR à NAT vise soudain le B2, et ses tentatives passées doivent l'afficher.
  Libellés gelés par `SkillLabelsTest`, **à mirrorer sur web et mobile**.
- **Config** : `sejourfr.competences.analysis` (`max-tokens: 600`,
  `temperature: 0`, `free-analyses: 3`, `max-text-words: 400`,
  `max-audio-duration-seconds: 180`) et `sejourfr.competences.niveau-vise`
  (`enabled: true`, `max-tokens: 900`, `temperature: 0`, `max-leviers: 3`), POJO
  `CompetenceProperties` **aux mêmes valeurs par défaut que le YAML**. Le
  **fournisseur LLM n'a de réglage propre ni pour l'un ni pour l'autre** :
  `CompetenceLlmConfig` et `CompetenceNiveauViseLlmConfig` lisent
  `sejourfr.production-evaluation.provider`, comme tout le reste (règle « un seul
  correcteur configurable »). Ne pas leur en donner un second.
  Retours arrière, sans migration : `COMPETENCE_RUBRICS_VERSION=v4` +
  `COMPETENCE_TOOL_SCHEMA_VERSION=v4` pour l'analyse (⚠️ **le rang des deux
  n'est plus le même** : v5 tourne sur le tool-schema **v4**, demander « v5 »
  échoue au boot),
  `COMPETENCE_NIVEAU_VISE_ENABLED=false` pour le plan d'action (ou ses contrats
  antérieurs par `COMPETENCE_NIVEAU_VISE_{RUBRICS,TOOL_SCHEMA}_VERSION=v2`, ou
  `=v1`).
  ⚠️ **Bascules v3, v4 et v5 de l'analyse, et v2/v3 du plan d'action, NON
  mesurées au banc** (cf. `docs/notation-ia-eo-ee.md` §11 bis, qui le dit
  franchement au lecteur). Le motif — « il n'existe aucun corpus » — a **cessé
  d'être vrai le 2026-08-16**, cf. le banc ci-dessous : elles restent non
  mesurées, mais plus faute d'instrument.
- **Banc de mesure du module — `CompetenceCalibrationBenchTest`** (2026-08-16),
  **jumeau** de `CalibrationBenchTest` et **jamais son remplaçant** : corpus
  séparé `src/test/resources/calibration/golden-set-competences-v1.json`
  (**90 micro-productions annotées**, 6 tâches × 5 paliers × 3, plus 33
  productions **réelles hors score**), grandeurs séparées (**palier** +
  **verdict de critère**, jamais une note /20 — le contrat n'a aucun champ où la
  loger). Mêmes garde-fous que l'autre banc : **opt-in strict** (jamais dans
  `./mvnw verify`), provider et modèle **non surchargeables**,
  `calibration.retries` figé dans le rapport, `sorties_refusees_pct` et
  `echec_production_pct` **distincts**. Détail d'usage :
  `docs/plan-tests-backend.md`.
  - **La vérité terrain se déduit de traits STRUCTURELS**, listés par cas dans
    `traits_structurels` et lus dans `commun.niveaux` de la grille active — pas
    d'un jugement esthétique. C'est la parade à la circularité : une IA écrit les
    productions, une IA les note. Un cas se conteste en montrant que le trait
    annoncé n'est pas dans la production.
  - **Le verdict de critère est INDÉPENDANT du palier**, et le corpus le teste :
    les cas `HORS_SUJET_RICHE` sont en langue B2 avec un critère `NOT_VALIDATED`.
    Un correcteur qui aligne l'un sur l'autre y échoue.
  - **Métrique de SENSIBILITÉ**, propre à ce banc : 6 **échelles** de 5
    productions du **même sujet** à des paliers différents, et le rapport compte
    les paires *ordonnées / inversées / confondues*. C'est la question du
    dossier — mesuré en base : **0 B2 sur 18 tentatives**, deux productions
    manifestement inégales notées toutes deux A2. Le rapport publie aussi la
    **répartition des paliers rendus** et `paliers_jamais_rendus` : un bon taux
    d'accord peut coexister avec un palier entier jamais produit.
  - **Pilote du 2026-08-16, 10 cas, consignes v6 / contrat v5, `retries=1`** :
    0 sortie refusée, 0 cas perdu, accord exact **60 %** — **100 % sur
    A1_NON_ATTEINT, A1 et A2, 0 % sur B1 et B2**, tous les cas hauts retombant en
    A2 (un seul B1 rendu, **aucun B2**). Coût réel **0,0129 $** (88 980 tokens
    d'entrée, 1 562 de sortie). Le défaut mesuré en base est donc **reproduit par
    l'instrument**, sur un échantillon trop petit pour conclure.
  - ⚠️ **Le coût persisté ment sur ce module** : chaque appel est arrondi au cent
    **supérieur** (`Math.ceil`), donc une campagne de micro-analyses s'affiche
    ~10× trop cher. Le rapport publie `cout_reel_usd`, recalculé depuis les tokens
    et les tarifs du provider actif — c'est ce chiffre qu'on cite.
  - **Les 33 productions réelles sont HORS SCORE** : tableau `temoins_reels`
    séparé, `hors_score: true`, exclues de tous les agrégats par
    `CompetenceCaseRun.exploitable()`. Elles n'ont aucune vérité terrain et ne
    servent qu'à vérifier le réalisme des cas synthétiques. **Ne jamais les faire
    entrer dans un taux d'accord.**
  - `CompetenceGoldenSetTest` fige le corpus (couverture, pièges, échelles,
    séparation des témoins) **sans aucun appel LLM** : lui tourne dans `verify`.
- **Volume figé** : 6 tâches (`EE1..EE3`, `EO1..EO3`) × **8 compétences** × **15
  sujets** × **3 références** (`INSUFFICIENT`/`EXPECTED`/`EXCELLENT`) = 48 / 720 /
  2160. Les 6 tâches sont un référentiel officiel (**enum `SkillTaskCode`, pas de
  table**). Ce compte est verrouillé par **`SkillSeedIT`**, pas par le DDL : la
  contrainte `display_order BETWEEN 1 AND 8` gelait le catalogue (les 8 rangs
  légaux étant tous seedés, l'admin ne pouvait plus rien créer) — elle est passée
  à **50**, et la règle produit vit désormais dans le test. Ne pas la remettre.
- **Les seeds sont GÉNÉRÉS**, jamais écrits à la main. Le générateur est
  **versionné** dans `backend_sejourfr/tools/competences/` (`generer_seed.py` +
  `contenu/*.json`, une fiche par tâche) et se rejoue par
  `cd backend_sejourfr && python3 tools/competences/generer_seed.py` (Python 3
  seul, aucune dépendance). **On édite le JSON puis on régénère, jamais le SQL** :
  modifier un `V300..V317` à la main désynchronise les deux et la régénération
  suivante écrase le correctif. Le script valide le contenu (8×15×3, cohérence
  EE mots / EO durée, unicité des codes **et unicité éditoriale** — pas deux fois
  le même titre ni la même situation dans une tâche, quasi-doublons de contexte
  détectés par trigrammes) et **refuse de générer** sur du contenu non conforme ;
  les UUID sont déterministes (uuid5 sur le code métier), donc stables d'un
  environnement à l'autre.
  - **Deux lots, parce que le lot 1 est déjà appliqué.** Les sujets de
    `display_order` 1-5 sortent en `V300..V305` (+ guidage `V306..V311`), ceux de
    6-15 en `V312..V317`. Régénérer doit rendre `V300..V311` **au bit près** —
    toute autre sortie invaliderait leur somme de contrôle Flyway sur les bases
    qui les ont jouées. Un nouveau lot de contenu = de nouvelles migrations,
    jamais une réécriture des précédentes.
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
- **Freemium — règle en vigueur depuis le 2026-08-10.** ⚠️ **L'ancienne règle
  (« aucun sujet n'est verrouillé, seule l'analyse IA est premium ») est
  RÉVOQUÉE** : elle ouvrait les 720 sujets à un compte gratuit, si bien que le
  module entier — le cœur de l'entraînement quotidien — ne donnait aucune raison
  de payer, et les 3 analyses offertes étaient la seule friction. Ne pas la
  réintroduire au motif qu'elle est encore écrite quelque part : ce qui suit
  fait foi. Pour un compte **sans accès TCF** (`hasTcf == false`) :
  - **une seule compétence ouverte par tâche**, celle de `display_order` le plus
    bas encore actif (= rang 1 sur le contenu publié) → **6 compétences** pour
    les 6 tâches ;
  - **plus la compétence de la priorité n°1 de son Plan**, si elle n'y est pas
    déjà. Sans cette exception, un diagnostic désignant une compétence de rang 5
    cadenasserait l'**étape 1** du Plan et rendrait le Plan entier inutilisable —
    or c'est la colonne vertébrale du produit ;
  - dans une compétence ouverte, **les 2 premiers sujets actifs** seulement
    (`SkillAccessService.FREE_PROMPTS_PER_SKILL`). ⚠️ **Ne pas l'aligner sur les
    5 sujets d'une étape du Plan** (`LearningPlanStep.PROMPTS_PAR_ETAPE`) : les
    deux constantes disent des choses différentes, et le plafond à **2/5** sur
    l'étape n°1 est la conséquence voulue — aucune étape n'est finissable sans
    abonnement (arbitré le 2026-08-11) ;
  - **les 3 analyses IA offertes à vie ne bougent pas** : un sujet ouvert reste
    analysable dans la limite du quota existant (`free-analyses`, décompte
    inchangé). Sur un sujet ouvert, produire, s'auto-évaluer, se relire et lire
    les 3 références restent gratuits et illimités ; la garde des références
    (« au moins une tentative ») est inchangée.
  - Un **abonné TCF** n'a aucun verrou.
  **Une seule autorité : `SkillAccessService`** (`SkillAccess.isSkillLocked` /
  `isPromptLocked`), qui s'appuie sur `LearningPlanPriorityResolver` — extrait
  exprès pour que l'ordre des priorités du Plan et le verrou ne puissent pas
  diverger. Aucun mapper, aucun controller, aucun front ne réimplémente la
  règle : les DTO portent un `locked` (`SkillDto`, `SkillPromptDto`,
  `SkillPromptSummaryDto`, `LearningPlanPriorityDto`, `LearningPlanSkillDto`,
  `PlanRecommendedExerciseDto`), et le verrou est **opposable serveur** —
  `SkillAccessService.assertCanProduce` rend **403** à la création d'une
  tentative comme sur `analyse` et `retry`, même philosophie que
  `AttemptService.enforceMockExamSlotAccess`. Résolution **groupée** (4 requêtes
  au plus, 1 seule pour un abonné) : un écran, c'est 24 compétences × 5 sujets.
  Le quota d'analyses, lui, se consomme toujours à l'**acceptation**
  (`analysis_requested = true`), pas au succès : sinon un retry après échec
  fournisseur en offrirait davantage.
- **Statut d'un sujet dérivé serveur**, jamais recalculé par un front
  (`SkillStatusResolver`) : `TODO` / **`TREATED`** / `VALIDATED` / `TO_REINFORCE`.
  `TREATED` (« Fait ») est le 4ᵉ statut qu'impose le freemium — une production
  sans analyse n'a pas de verdict, l'afficher « Validé » ou « À renforcer » serait
  faux.
- **Libellés FR = contrat gelé sur les 4 couches.** Ces chaînes ne transitent pas
  par le réseau : le backend, le web, le mobile et l'admin en tiennent chacun une
  copie écrite à la main, donc rien n'empêche une couche de dériver — et c'est
  arrivé (`NOT_VALIDATED` affiché en trois formulations différentes). Elles sont
  figées par un test **par couche**, sur exactement les mêmes chaînes :
  `SkillLabelsTest` (backend), `lib/skill-labels.test.ts` (web),
  `test/skill_models_test.dart` (mobile). Un libellé qui bouge, ce sont **quatre**
  fichiers à changer dans la même passe.
  ⚠️ **Les tests front cités ici sont un héritage** : depuis le 2026-08-09 on
  n'écrit plus de test sur les fronts (cf. § Tests). Le gel de libellé n'y est donc
  plus reproduit pour un nouveau contrat — seul `SkillLabelsTest` continue de
  l'assurer côté backend, et la concordance des copies front se vérifie **à la
  lecture**. Ne pas créer de nouveau `*.test.ts` / `*_test.dart` pour ça.
  Côté fronts, on lit toujours la constante
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
- **Transcription SYSTÉMATIQUE, audio JAMAIS conservé** (cf. la section
  transverse « L'audio d'une production de candidat n'est pas conservé »).
  ⚠️ **Révoque** l'ancienne règle « Whisper seulement si une analyse est
  demandée » et « l'audio est conservé dans tous les cas, les deux fronts
  permettent de se réécouter » : sans audio gardé, ne pas transcrire ne
  laisserait **rien** de la production. Elle est donc écrite dès la soumission,
  analyse demandée ou non, et l'écran de résultat n'a plus de lecteur. Pipeline
  async **sans transaction englobante**, même invariant que
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
  section : EE « Reprendre ma réponse » (préremplit), EO « **Relire** ma dernière
  réponse » (ouvre le résultat). ⚠️ L'EO disait « Écouter » jusqu'au 2026-08-16 :
  il n'y a plus rien à réécouter, l'enregistrement n'étant pas conservé — c'est
  la transcription qu'on relit.
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
CLAUDE.md local de son sous-projet — parité web ⇄ mobile ⇄ admin, **tests backend dans la
même passe et aucun test front** (cf. § Tests), hygiène d'architecture, pas de `.md` non
demandé. C'est à Claude principal de le rappeler dans le prompt de l'agent et de **vérifier
à la restitution** que ça a été respecté — y compris qu'aucun agent front n'a créé de test.

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

### Tests — BACKEND UNIQUEMENT (règle posée le 2026-08-09)

🛑 **On n'écrit plus AUCUN test sur les fronts.** Ni `web_sejoufr`, ni `admin_sejourfr`, ni
`mobile_sejourfr` : pas de `*.test.ts`, pas de `flutter_test`, pas de test de widget, pas de
test de libellé gelé, pas de test de layout. **Les seuls tests du dépôt sont ceux du
backend**, unitaires (`*Test`) et d'intégration (`*IT`). Cette règle **prime** sur toute
consigne de test écrite ailleurs dans ce fichier ou dans un `CLAUDE.md` local, et sur
l'habitude « tests dans la même passe » — qui ne vaut désormais **que** pour le backend.

Ce que ça implique concrètement :

- Un changement purement front (écran, style, libellé, composant, provider, routing) se
  ferme **sans test**. On vérifie par `npx tsc --noEmit` / `npm run build` côté web et admin,
  `flutter analyze` côté mobile — la compilation et l'analyse statique, rien de plus.
- **Ne pas créer** de nouveau fichier de test front, même « juste pour geler un libellé ».
  Les libellés miroirs (`SKILL_*_LABEL`, statuts du plan, verdicts de production…) restent à
  tenir à la main dans la même passe, mais leur **respect ne se vérifie plus par un test** :
  c'est une relecture, pas une assertion.
- **Les tests front existants ne sont pas supprimés d'office** (ils tournent, ils sont verts,
  les jeter est une passe à part). En revanche on ne les étend plus, et un test front qui
  devient rouge à cause d'un changement voulu se **met à jour ou se supprime** — il ne
  justifie jamais de renoncer au changement.
- La parité web ⇄ mobile ⇄ admin reste **non négociable** : elle se vérifie désormais par
  lecture croisée des deux implémentations, pas par un test de chaque côté.

**Le backend, lui, ne bouge pas d'un pouce** : tout code ajouté ou modifié y est couvert par
des tests **dans la même passe**. Une feature, un bugfix, une règle métier, un endpoint, une
migration à impact logique ne se ferment pas sans test(s) qui verrouillent le comportement.
Avant un refactor d'un bloc existant non couvert : écrire d'abord le filet de tests, puis
refactorer. Pas d'exception « je testerai plus tard ».

C'est là que le raisonnement tient : le backend est la **source de vérité** des DTO, des
règles métier et du freemium ; un test qui y fige une règle protège les trois fronts d'un
seul endroit, alors qu'un test front ne protège qu'une surface d'affichage — la moins
coûteuse à corriger, et celle que le propriétaire vérifie lui-même à l'écran.

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
`plans.realtime_eo_sessions`, V018/V113/V114) : le nombre de simulations orales
en temps réel ouvertes par le pass — **5 (7 j) / 15 (1 mois) / 25 (2 mois)** sur
Intégral, **0** sur Civique et Free. Les fronts l'affichent tel quel au lieu de
coder le quota en dur — il reste éditable côté admin. **C'est la seule ressource
qui distingue deux passes Intégral** (même catalogue, mêmes examens blancs,
mêmes corrections IA : seules la durée et ce quota progressent), donc il est
annoncé **sur chaque ligne de pass** — `/paiement`, `/tarifs`, `/reussir` et le
paywall mobile — par un libellé unique par front, `realtimeSessionsLabel`
(`web_sejoufr/lib/types.ts` ⇄ `PlanPublicResponse.realtimeSessionsLabel` dans
`mobile_sejourfr/lib/core/models/billing_models.dart`), miroirs mot pour mot.
⚠️ Il ne dit **jamais** « sans simulation orale » sur un pass **Intégral** : un
backend antérieur au champ le renvoie à 0, et ce serait faux sur l'argument
principal du produit — il rend alors « incluses », sans chiffre. Seul le module
(source sûre) autorise le « sans », et seule `/reussir` l'écrit, parce que sa
puce de liste doit exister même vide.

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
  d'abonnements. Catalogue **en vigueur (V114, 2026-08-14)** : Civique 3 mois
  (9,99) / 1 an (29,99) — **inchangé** ; Intégral **7 jours (9,99) / 1 mois
  (19,99) / 2 mois (29,99)**, codes `INTEGRAL_PASS_{7J,1M,2M}`, product IDs
  `integral_pass_{7j,1m,2m}`. Les 3 anciens passes Intégral (sprint 6 sem 19,99 /
  3 mois 34,99 / 1 an 79,99) sont **désactivés, jamais supprimés** : les
  souscriptions vendues les référencent par FK et les stores doivent encore
  résoudre leurs product IDs. **Une durée de plan ne se réécrit pas** — `ends_at`
  est figé à l'achat, mais changer `duration_days` d'un plan encore vendu
  falsifierait les achats suivants et le product ID du store, d'où des **codes
  neufs** plutôt qu'une mise à jour en place. Le pass **mis en avant** (« le plus
  populaire ») est `INTEGRAL_PASS_2M`, déclaré une fois par front
  (`POPULAR_PASS_CODE` ⇄ `_popularPassCode`). Ce qu'il reste à faire côté stores
  vit dans `docs/bascule-prix-integral.md`. Modèle : paiement →
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
    product IDs **lus en base** (`plans.apple_product_id` / `google_product_id`,
    identiques et en minuscules), **plus dérivés de `Plan.code`** — un ID Apple
    supprimé n'étant jamais réutilisable, une recréation impose un ID neuf.
    Guide pas-à-pas → `docs/setup-paiement-one-time.md`.

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
- `docs/bascule-prix-integral.md` — nouvelle grille Intégral (7 j / 1 mois / 2 mois) : ce qui est fait
  en base et dans les fronts, et ce qui reste à créer côté stores
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
