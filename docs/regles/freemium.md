# Freemium — ce qui est ouvert, ce qui est verrouillé

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Contenu verbatim, aucune réécriture.**
> Origine : lignes 113-253 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier porte la loi de ce sous-système : on l'ouvre **quand on travaille dedans**.
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

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
  6 pour les 6 tâches) **+ la compétence de la première place du Plan** — celle
  que désigne `PlanFocusResolver`, **quelle que soit sa nature**, fragilité
  observée comme compétence « à acquérir » (2026-08-21, cf. la section *Plan
  adaptatif*) —, et **2 sujets** par compétence ouverte. Le reste est verrouillé — cadenas côté
  fronts, **403 côté serveur** (`SkillAccessService.assertCanProduce`). Les **3
  analyses IA offertes à vie** sont un verrou distinct, inchangé, qui se cumule.
  Règle posée le **2026-08-10**, elle **révoque** l'ancienne (« aucun sujet n'est
  verrouillé ») ; détail et motif dans la section *Module « Compétences TCF »*.
- **Compte gratuit, Plan personnalisé** : ⚠️ **la phrase qui ouvrait cette puce a été
  RETIRÉE le 2026-08-23** — elle avait été explicitement révoquée le 2026-08-21 par la règle
  « On floute l'ACTION pas encore accessible, jamais le RÉSULTAT mesuré »
  (`docs/regles/plan.md`), mais elle était restée écrite ici, 766 lignes plus haut dans le
  même fichier. Texte retiré et motif : `docs/decisions/contradictions-ouvertes.md`
  (contradiction #1). **Ce qui fait foi aujourd'hui** : le Plan reste **lisible** en entier,
  mais les **items de séance** et les **lignes de priorité verrouillés** sont floutés — voir
  `docs/regles/plan.md`. La compétence de sa
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

### Idempotence — un renvoi ne consomme pas un second essai (V046, lot L1)

Ajouté le **2026-09-09**. Le quota était protégé contre l'abus, pas contre le
**réseau** : une production partie dont la réponse se perdait était renvoyée par
le client, et le serveur — qui n'avait aucun moyen de reconnaître la même
production — insérait une seconde ligne, payait une seconde correction et
décomptait un second essai. Le candidat voyait deux rapports pour une seule
production.

- Les deux surfaces payantes portent une colonne `client_submission_id`
  (nullable) : `production_submissions` et `user_skill_attempts`.
- **Une clé par PRODUCTION, pas par requête** — c'est le renvoi qui doit porter
  la clé de l'envoi initial. Les fronts la tirent une fois par production
  (`web_sejoufr/lib/idempotency.ts`, `mobile_sejourfr/lib/core/utils/submission_key.dart`).
- Le rejeu est intercepté **avant** le rate-limit, **avant** le quota et
  **avant** Whisper : la seconde requête est la même requête, la refuser en 429
  rendrait la clé inutile précisément quand le client en a besoin.
- **Clé absente = comportement d'avant, à l'identique.** Les applications déjà
  installées continuent de fonctionner ; NULL ne signifie jamais « soumission
  invalide ».
- 🛑 **L'unicité est bornée à `(user_id, clé)`, pas globale.** La clé est tirée
  par le client : avec une unicité globale, deux appareils tirant la même UUID
  se feraient échouer l'un l'autre — ou pire, résoudraient vers la production
  d'un inconnu. La spec proposait l'unicité globale ; on ne la suit pas.
- La **course** (deux requêtes parties ensemble) est tranchée par l'index
  unique : la perdante relit la ligne gagnante et la rend. Un seul rapport, un
  seul quota consommé. Coût assumé à l'oral : la perdante a déjà payé une
  transcription, jetée — même arbitrage que le double-clic du diagnostic.

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

> ⚠ **SUSPECTÉ PÉRIMÉ — non vérifié au 2026-08-23, ne pas appliquer sans confirmation.**
> Suspicion #5 — motif et liste complète : `docs/decisions/suspects-perimes.md`.

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
