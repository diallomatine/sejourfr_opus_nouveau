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
- 🛑 **Compte gratuit, EE/EO — REFONDU le 2026-09-18 (D-17, D-17 bis).**
  **Deux examens blancs de production offerts à vie, un par épreuve** : un EE,
  un EO. **Deux freebies nominatifs**, pas « un au choix » — celui qui a usé son
  EE garde son EO. Chacun est **complet** : les 3 tâches sont réellement
  corrigées, le LLM **est** appelé, l'analyse entière est rendue. C'est la
  vitrine du produit, pas un aperçu.
  - **Le rejeu est ouvert, c'est l'ANALYSE qui est premium.** Repasser
    l'épreuve n'est pas interdit ; faire corriger le second passage l'est. 🛑 Et
    **aucun appel payé ne part** : ni correcteur, ni **Whisper**. Le refus est
    posé par `ProductionAccessService.enforceQuota`, appelé **avant** le
    pipeline — même place que l'interception d'idempotence de V046.
  - **Côté ORAL, le paywall se présente AU DÉMARRAGE** de l'épreuve
    (`ProductionAccessService.assertCanStartProductionExam`), pas après la
    soumission : sans Whisper il ne resterait **rien** à lire, et l'audio d'un
    candidat n'est jamais conservé. À l'écrit, le texte reste sous les yeux du
    candidat, donc le démarrage reste ouvert.
  - **La consommation est PERSISTÉE et s'écrit à la REMISE DE L'ANALYSE**, ni au
    démarrage de l'examen, ni à la clôture de la session : un abandon, une
    expiration, un échec technique ou un échec du correcteur laissent le freebie
    **intact**. Ledger `free_entitlement_usage` (V067), `UNIQUE (user_id, code)`,
    codes `EXAM_BLANC_EE` / `EXAM_BLANC_EO` ; écriture par
    `FreeExamEntitlementService.consommerApresAnalyse`, appelée par
    `ProductionPipelineAsyncRunner` après qu'une `AiEvaluation` est produite.
    ⚠️ La ligne est écrite dès la **première** analyse rendue et porte
    `source_attempt_id` : les **2 tâches restantes du même examen** restent
    corrigées au titre de la même gratuité. *(Décision d'implémentation prise en
    P4 : n'écrire qu'après la 3ᵈ tâche aurait laissé un candidat abandonner
    chaque examen sur la 2ᵈ tâche et obtenir des corrections LLM sans borne.)*
  - **Un abonné ne consomme rien** : le ledger dit « ceci lui a été *offert* ».
  - 🛑 **Les règles révoquées, verbatim** : « 1 essai d'entraînement par épreuve
    à vie » (`FREE_TRAINING_PER_EPREUVE = 1`, **supprimé** — travailler EE/EO
    est premium) ; « 2 sessions d'examen, EE+EO confondues »
    (`countProductionExamSessions(userId) >= 2`, **supprimé** — il comptait des
    examens *démarrés*, donc abandonnés, et ne savait pas dire sur quelle
    épreuve) ; « Refaire l'examen 1 = toléré une fois mais consomme les essais
    d'entraînement restants » (**supprimé**).
  - **Inchangé** : une **session d'examen production reste bornée** — chrono
    d'épreuve **EE 30 min** (l'**EO n'en a plus**, elle se chronomètre par
    tâche — cf. § *Temps des examens blancs*) et **une seule soumission par
    (attempt, tacheNumero)**, un examen c'est 3 tâches une fois chacune.
- **QCM entraînement** : série 1 gratuite, 2+ premium. **Tous les examens blancs QCM** (`MOCK_EXAM`) :
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
- 🛑 **Compte gratuit, module Compétences TCF — TOUT EST PREMIUM depuis le
  2026-09-18 (D-18).** Travailler une compétence est premium, **sans
  exception** : `SkillAccessService` n'ouvre **aucune** compétence et **aucun**
  sujet à un compte sans accès TCF. Cadenas côté fronts, **403 côté serveur**
  (`assertCanProduce` au grain du sujet, `assertCanTrain` au grain de la
  compétence — la compréhension n'a pas de petit sujet à nommer).
  - 🛑 **Les quatre ouvertures révoquées** : « une seule compétence ouverte par
    tâche » ; « **plus la compétence de la première place du Plan** » (exemption
    du 2026-08-21) ; « **2 sujets** par compétence ouverte »
    (`FREE_PROMPTS_PER_SKILL = 2`, **supprimé**) ; « la première compétence de
    chaque domaine de **compréhension** » (`CO-A2` / `CE-A2` — D-18 ne connaît
    pas de domaine d'exception).
  - 🛑 **`sejourfr.competences.analysis.free-analyses: 3` est SUPPRIMÉ**, sans
    remplaçant : l'analyse IA du module Compétences est premium, point. **Aucun
    quota journalier** n'a été introduit (le premier jet de la spec proposait
    « 1 analyse IA / jour » : refusé). `SkillAnalysisAccessService` refuse
    désormais dès la première.
  - 🛑 **La contradiction #1 n'est PAS rouverte** : le référentiel, le Plan, les
    priorités, les niveaux mesurés et les compteurs **restent lisibles et
    servis**. Ce qui se ferme est l'**exécution**, jamais l'affichage — un
    `locked` servi, jamais une donnée masquée.
- 🛑 **Compte gratuit, Plan personnalisé — LISIBLE mais INEXÉCUTABLE (D-18,
  2026-09-18).** Le Plan, le parcours, les priorités, les niveaux mesurés et les
  compteurs restent **servis en entier** ; **aucune** étape n'est exécutable.
  Conséquence **voulue** : `JourneyState.LOCKED` permanent, `current = null`, et
  la carte « À faire maintenant » nomme la **première étape verrouillée** avec
  son paywall (arbitrage D-1, inchangé : `CURRENT` = première étape non clôturée
  **et exécutable**).
  - ⚠️ **La phrase qui ouvrait cette puce avait déjà été RETIRÉE le 2026-08-23**
    (révoquée le 2026-08-21 par « On floute l'ACTION pas encore accessible,
    jamais le RÉSULTAT mesuré » — `docs/regles/plan.md`) ; motif dans
    `docs/decisions/contradictions-ouvertes.md` (contradiction #1).
  - 🛑 **Et l'exemption qui l'avait remplacée est révoquée à son tour** : « un
    candidat non abonné pourra travailler sa priorité 1, vu qu'elle est
    visible ». Il ne reste **rien** d'ouvert, donc **rien** à préparer pour
    `SkillAccessService` : la circularité `CURRENT` ⇄ `locked` que D-1 avait
    résolue **disparaît avec l'exemption**, et sa surcharge
    `resolve(userId, focusSkillId)` est supprimée.
  - **Conséquences en cascade, déjà arbitrées et toujours vraies** : aucune
    étape n'est finissable sans abonnement, la bascule en **vérification de
    progression** exige l'étape terminée donc un compte gratuit ne la voit
    jamais, aucune de ses compétences n'atteint `SOLID`, et il ne reçoit aucun
    **jalon** d'examen blanc. La vérification est **premium** — choix produit du
    2026-08-14, détaillé dans la section Plan. Ne pas « réparer ».
- **Compte gratuit, examen blanc TCF complet** (`/api/full-tcf-exams`,
  orchestré CO→CE→EE→EO) : **accessible sans abonnement**, et chaque épreuve de
  production y est incluse **tant que sa gratuité n'est pas consommée**.
  - 🛑 **Le verrou est PAR ÉPREUVE depuis D-17 bis** : deux gratuités
    nominatives ne se ferment pas ensemble. `FullTcfExamService.start`
    pré-termine **la** sous-épreuve dont la gratuité est consommée (finishedAt +
    TERMINE) et pose `attempts.production_locked = true` **sur ce
    sous-attempt** ; le drapeau du **parent** ne vaut plus que pour les **deux**
    épreuves fermées, et reste lu tel quel pour les examens antérieurs (donnée
    réelle). `FullTcfExamResponseBuilder` lit le OU des deux, exposé en
    `FullTcfExamResponse.SubAttempt.locked`.
  - **Une épreuve verrouillée n'a PAS de niveau** et sort du plancher global :
    le verrou est commercial, pas linguistique.
  - 🛑 **Le freebie se lit sur le LEDGER**, plus sur l'existence d'une
    soumission : `ProductionSubmissionManager.hasFullExamProductionSubmission`
    est **supprimé** (D-17). Il consommait la gratuité dès le dépôt d'une tâche,
    avant toute correction, et sans savoir sur quelle épreuve — une soumission
    dont le correcteur échoue ne doit rien fermer.
  - Les examens complets restent rejouables ; soumettre vers une épreuve déjà
    terminée est refusé (`enforceQuota`).

### 🛑 L'EE et l'EO du DIAGNOSTIC TCF sont totalement offertes (2026-09-13)

Arbitrage du propriétaire : « la EE et EO sont totalement gratuits » dans le
diagnostic complet. **Aucun cadenas, aucun décompte.**

C'était déjà vrai pour l'essentiel, et pas par accident : un sous-attempt de
diagnostic a un **parent**, donc `ProductionAccessService.isExamSession` le
reconnaît comme une session d'examen et `enforceQuota` **sort avant tout
décompte**. `countTrainingByUserAndEpreuve` l'exclut de la même façon
(`parentAttempt IS NULL`), et `countProductionExamSessions` aussi
(`slotNumber IS NOT NULL`, or un diagnostic n'a jamais de slot).

**Une fuite restait, elle est fermée** :
`ProductionSubmissionRepository.countByUserAndParentEpreuve` — le compteur du
freebie « EE/EO offerts une fois dans l'examen complet » — ne portait **pas**
`tcfDiagnostic IS NULL`. Une production EE ou EO faite dans un diagnostic
brûlait donc le freebie de l'examen blanc d'un compte gratuit, qui arrivait
ensuite avec EE/EO pré-terminées. C'est la 7ᵉ requête à porter le discriminant,
verrouillée par `TcfDiagnosticServiceIT.productionsDuDiagnosticNeConsommentRien`.

🛑 **Aucun garde-fou nouveau n'a été ajouté, et il n'en faut pas.** Le coût LLM
est déjà borné par ce qui existe : le premier diagnostic est **unique** (porte 1
+ porte 2 — un compte gratuit n'en ouvre jamais un second), la porte 3 impose
14 jours entre deux passations, une tâche ne se rend **qu'une fois** par session
(`assertTacheNotAlreadySubmitted`) et la 3ᵉ soumission clôt la section, après
quoi `assertNotFinished` refuse. Plafond réel : **6 évaluations** par
diagnostic. → `docs/regles/diagnostic-tcf-4-epreuves.md`

⚠️ **L'examinateur vocal temps réel n'est pas proposé sur EO1/EO2 du
diagnostic** : il a son propre quota payant, et l'y offrir contredirait
« totalement gratuit ». Ces deux tâches se passent en enregistrement +
transcription, comme le propriétaire l'a décrit.

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
