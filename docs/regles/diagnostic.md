# Diagnostic initial TCF

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Contenu verbatim, aucune réécriture.**
> Origine : lignes 644-813, 1342-1405 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier porte la loi de ce sous-système : on l'ouvre **quand on travaille dedans**.
> Fichier jumeau : `docs/decisions/diagnostic.md`
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

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
- **Les LONGUEURS et les TAILLES DE LISTE sont des troncatures, jamais des
  refus** (2026-08-25, même réconciliateur, avant le validateur) : `summary`
  (280), un item de `strengths`/`weaknesses` (180), une `explanation` (220) et
  le plafond de **3 items** par liste sont coupés côté serveur — coupe sur
  limite de mot, ellipse `…`, jamais un point final inventé. Et **la confiance
  d'une compétence non observée est ramenée à `LOW`**, comme `priority` est
  ramené à `false` : `observed=false` ne dit rien du candidat, il n'y a aucune
  confiance à graduer. Motif : ces `maxLength`/`maxItems` sont déclarés au
  tool-schema mais **aucun fournisseur ne les applique** (contrairement à
  `enum`, `required`, `additionalProperties`) ; en prod le 2026-08-25, un
  `summary` de ~300 caractères a coûté une réparation payée **puis** tout le
  diagnostic (submission `3136658f`, `AiEvaluationException` → `FAILED`, chaque
  retry repayant deux appels). Compteurs `SYNTHESE_TRONQUEE`, `TEXTE_TRONQUE`,
  `LISTE_TRONQUEE`, `CONFIANCE_NON_OBSERVEE_DERIVEE`.
- **Ce qui reste un refus dur**, et doit le rester : ce que le serveur ne peut
  pas inventer sans mentir — `skill_code` hors allowlist, compétence manquante,
  `evidence_segment` absent ou hors bornes, enum invalide, champ hors contrat,
  `level_estimate` au-dessus de B2. Une **preuve posée sur une compétence
  déclarée non observée** n'est pas non plus effacée : c'est une contradiction
  du correcteur, pas une mise en forme.
- **Le déséquilibre EE/EO de la notation est MESURÉ, pas corrigé** (2026-08-26).
  Sur les 22 analyses en base : `EE` 2 `PRIORITY` / 34 `TO_REINFORCE` / 51 `SOLID` ;
  `EO` **0** `PRIORITY` / 10 / 57. Et 12 observations sur 12 en `SOLID`/`HIGH` sur une
  compétence **B2** chez un candidat estimé **B1** à l'oral.
  🛑 **Vérifié : ce n'est pas structurel.** Le tool-schema est un **fichier unique** pour les
  deux modalités et autorise les quatre statuts ; les rubriques demandent explicitement « au
  plus deux compétences prioritaires ». La seule consigne propre à l'oral porte sur ce que le
  correcteur ne peut pas **entendre** (prononciation, débit, intonation), jamais sur les
  verdicts. Le déséquilibre est donc **comportemental**.
  Compteur posé (`DiagnosticStatusDistributionMetrics`, clés `TCF_EO:SOLID`…) : il **ne décide
  de rien** et n'entre dans aucun calcul. À relire vers **N ≈ 100**. Aucun garde-fou, aucune
  consigne de prompt de plus, aucun backfill — 22 lignes ne portent rien.
  ⚠️ Ce déséquilibre compte : c'est toujours l'oral qui se retrouve sans fragilité, donc sans
  priorité, sur les écrans. → `docs/regles/plan.md`
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
- **Écran de RÉSULTAT — le « + N autres » est un VRAI nombre** (2026-08-21).
  L'ordre des blocs est figé et identique sur les deux fronts : **Mes priorités**
  (1 en clair, 2 lignes réelles floutées, « + N autres ») → **Points forts**
  (même traitement) → **Compléter mon profil** (si `domainesAEvaluer` n'est pas
  vide) → **carte d'abonnement**. Seuils d'**affichage** déclarés une fois par
  front : `FREE_PRIORITIES`/`FREE_STRENGTHS` = 1 et `TEASE_SAMPLE` = 2 (web) ⇄
  `_kFreeFocusVisible`/`_kFreeSolidVisible` = 1 et `_kBlurredSample` = 2 (mobile).
  🛑 **`DiagnosticResultDto.fragileSkillCount` / `.solidSkillCount` sont
  l'autorité du compteur, et ils sont SERVEUR** (`DiagnosticService`,
  compétences **distinctes** de `written.skills` + `oral.skills`, `observed`,
  statut `PRIORITY|TO_REINFORCE` / `SOLID`, dédoublonnées par code) : le calculer
  dans chaque front aurait produit deux nombres pour la même chose. Il **ne se
  lit pas sur `priorities`**, plafonné à 3 par règle produit — le plafond n'est
  pas touché, et un « + 2 » de plafond n'est pas une réalité. Il ne se lit pas
  non plus sur `strengths`, plafonné à 3 **à l'écriture** du résumé par
  `DiagnosticSessionCoordinator`. `0` ⇒ **aucun bloc flouté**, et une liste plus
  courte que le seuil s'affiche en clair. Contenu flouté = le **vrai**, hors
  arbre d'accessibilité et hors parcours clavier (`aria-hidden` + `inert` ⇄
  `BlurredContent`), l'information nette (compteur, CTA) vivant hors du rideau ;
  un seul chemin vers l'offre, **aucun événement d'audience ajouté**.
  ⚠️ **Trois surfaces démentaient le flou et ont été fermées** : la section web
  « Le détail reste disponible » listait en clair **toutes** les observations —
  elle est **remplacée** par « Vos points forts » (les seules compétences
  `SOLID`) ; les phrases `strengths` deviennent un **repli** affiché seulement
  quand aucune compétence solide n'existe (deux listes disaient la même chose) ;
  et la liste « À travailler » de chaque production (web `ProductionSummary`,
  mobile `_ProductionCard`) n'est servie qu'à un compte **avec** accès. En
  contrepartie, la liste des priorités est **complétée** par les autres
  fragilités observées au-delà des 3 servies : un abonné doit voir exactement ce
  que le compteur d'un compte gratuit lui a promis.
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
  `weaknesses[]` (entrée vidée ⇒ retirée), `summary` (**champ obligatoire**, donc
  remplacé, jamais vidé — par un texte qui **rassure** : « Votre production a bien
  été analysée. Certaines remarques portaient sur la transcription, pas sur vous :
  elles n'ont pas été retenues. » Il n'explique **plus** notre mécanique de
  filtrage — c'est le premier écran de quelqu'un qui découvre son niveau, et la
  trace de la purge vit dans le compteur, pas à l'écran. Même mouvement que les
  trois avertissements oraux ramenés à un seul le 2026-08-16 ; texte gelé par
  `DiagnosticOralArtifactFilterTest`, posé **uniquement** par le serveur, aucun
  front ne le recopie, legacy non migré). **Jamais touchés** : l'ÉCRIT, `strengths`, `evidence`, `status`,
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


## Le diagnostic se passe AVANT le compte — des DEUX côtés (V053, 2026-09-10)

🛑 **Arbitrage du propriétaire** : « que ce soit le diagnostic examen civique ou
TCF, l'utilisateur doit pouvoir passer le diagnostic avant de créer son compte,
il saisit le texte ou répond au QCM et seulement après on lui demande de créer
son compte pour voir le résultat. »

La règle produit est **la même des deux côtés**. La mécanique, non — et la
différence est délibérée, pas un oubli de parité :

| | TCF invité | Civique invité |
|---|---|---|
| Ce qui est produit | un texte (et un audio) | 40 réponses à un QCM |
| Où ça vit avant le compte | **l'appareil** (IndexedDB / `SharedPreferences`) | **le serveur** (attempt invité, `user_id IS NULL` + `client_ip`) |
| Ce que l'appareil garde | la production entière | **deux UUID** : la session et son attempt |
| Le compte est demandé | à « Analyser mes réponses » | à « Voir mon résultat » |

🛑 **Pourquoi le civique ne peut pas garder ses réponses sur l'appareil** : le
corriger côté client obligerait à **servir les bonnes réponses à un visiteur**,
et jouer 40 questions hors `attempts` obligerait à écrire un **second runner** —
les deux sont interdits. On réutilise donc la mécanique d'attempt invité qui
existe déjà pour la démo.

Les invariants qui tiennent ce tunnel :

- 🛑 **La session civique existe dès le premier tirage**, avant le compte : c'est
  elle qui porte `attempts.civic_diagnostic_id`. Sans elle, les 40 questions d'un
  visiteur seraient un **examen blanc** pour toutes les grilles.
- 🛑 **Aucune route de résultat publique.** Le résultat est ce qu'on échange
  contre le compte : le serveur n'en sert aucun sans authentification, donc aucun
  front ne peut mentir sur ce point.
- 🛑 **La démarche est demandée AVANT le tirage** (CSP / CR / NAT) : c'est elle
  qui choisit les questions. Absente ⇒ **CSP**, le périmètre le plus étroit.
  Mesurer un candidat naturalisation sur le programme d'une carte de séjour
  produirait un diagnostic flatteur et un plan incomplet.
- 🛑 **L'adoption ne rejoue rien** : mêmes questions, mêmes réponses déjà
  corrigées ; le serveur pose seulement le porteur. Un second tirage rendrait au
  candidat un résultat qui n'est pas celui qu'il vient de passer.
- 🛑 **Le quota du compte s'applique à l'adoption** (`20_` §4.3) : sinon il
  suffirait de se déconnecter pour se refaire un diagnostic gratuit indéfiniment.
  Conséquence assumée : un compte qui a déjà son diagnostic **perd** les réponses
  du tunnel invité — les fronts retombent alors sur son diagnostic existant, sans
  message d'erreur.
- 🛑 **Une session adoptée n'est plus lisible publiquement**, même depuis la même
  IP : deux personnes derrière le même NAT ne se lisent pas.

Routes et détail : `docs/api-endpoints.md`, section « Diagnostic civique (L9) ».
Journal de la décision : `docs/review_all/60_DECISIONS_IMPLEMENTATION.md`,
section « Le diagnostic se passe AVANT le compte ».

---

## `estimationSessionId` — le rapide reste relisible après le démarrage du complet (2026-09-12)

`PreparationService.tcf()` ne servait, dans la branche « complet présent », que le `sessionId`
de la session **TCF 4 épreuves** : le `findLatestCompleted` qui retrouve la session du rapide
n'était atteint que si aucun complet n'existait. Dès le démarrage du complet, l'identifiant du
rapide **disparaissait de la réponse** et son rapport devenait introuvable pour les trois
fronts. Aucun correctif front ne pouvait compenser ça.

`PreparationDto.ModulePreparation` porte donc **`estimationSessionId`** (`UUID`, nullable),
résolu **avant** le branchement d'étape et servi à **toutes** les étapes — y compris
`PLAN_PRET`. `sessionId` garde son sens inchangé : « le diagnostic à reprendre ».

🛑 **Champ distinct, jamais un `sessionId` surchargé.** Deux sens sur un même champ finissent
toujours par se contredire, et les fronts auraient dû deviner lequel ils lisent selon l'étape.
Même doctrine que `nextTargetLevel` vs `cycle.targetLevel`.

**Coût assumé** : une lecture indexée de plus sur `/api/me/preparation`, à toutes les étapes.
Le champ aurait pu n'être calculé que quand le plan n'est pas prêt, mais un champ qui ne dit
vrai qu'à certaines étapes finit par être lu aux autres. Commenté dans le service.

Civique : toujours `null` (il n'a qu'un diagnostic), verrouillé par test. Gelé par
`PreparationServiceIT` — `estimationSurvitAuDemarrageDuComplet` est le test du bug ; un rapide
`IN_PROGRESS` rend `null`, on n'invente pas un rapport.

Lecteur : la porte d'entrée du Plan TCF → `docs/regles/plan.md`.

---

## 🛑 Le diagnostic complet n'est plus un prérequis d'accès au Plan (2026-09-12)

**Arbitrage du propriétaire.** *« Dès que le diagnostic rapide est terminé, le serveur doit
constituer un premier Plan à partir des données disponibles dans ce diagnostic rapide. Ce Plan
est provisoire mais réel et utilisable. […] Le diagnostic complet ne doit plus être un
prérequis d'accès au Plan, seulement un moyen de le rendre plus précis. »*

### Où était réellement la porte

**Pas dans le moteur.** `LearningPlanService.get()` a toujours basculé en `ACTIVE` sur
`DiagnosticSessionManager.findLatestCompleted(userId)` — c'est-à-dire sur le diagnostic
**RAPIDE**. Vérifié en base : les comptes sans aucun `tcf_diagnostic_sessions` portent 8 à 27
`learning_plan_observations`, toutes issues du rapide, et `LearningPlanProfilProgressifIT`
assertait déjà `ACTIVE` après le seul rapide.

La porte vivait **uniquement dans l'état servi** (`PreparationService` + les deux fronts, qui
lisaient `etape == PLAN_PRET`). C'est elle, et elle seule, qui affichait « Votre plan TCF n'est
pas encore prêt » devant un plan que le serveur savait construire.

### Le fait servi : `planDisponible`

`PreparationDto.ModulePreparation.planDisponible` (`boolean`) rend **mot pour mot** la
condition du moteur — « une session de diagnostic rapide close existe-t-elle ? ».
🛑 **Il ne se déduit pas de `etape`** : un écran qui promettrait un plan que le moteur refuse
de construire est exactement la contradiction que l'état unique existe pour empêcher.
`ESTIMATION_FAITE` garde son sens (« où en est le diagnostic »), et son commentaire
« le Plan ne peut pas encore être construit » est **révoqué**.

### Ce que le Plan provisoire n'invente pas

🛑 **Aucune priorité sur une compétence que le rapide n'a pas observée.** Les trois garde-fous
existaient déjà et sont conservés tels quels :

- `LearningPlanPriorityResolver` ne trie que des **observations réelles** ;
- `PlanAcquisitionSelector` exige que le **domaine ait déjà été mesuré** — un domaine jamais
  évalué « se mesure avant de s'apprendre » ;
- les domaines non mesurés ressortent dans `domainesAEvaluer` avec
  `PlanDomainPriority.A_EVALUER`, `niveau: null`, `evaluated: false` — *`null` = inconnu, jamais
  mauvais*, la confusion même de V040/V041/V042.

Un Plan avec **peu** de priorités, toutes vraies, est le bon résultat. Gelé par
`LearningPlanProfilProgressifIT.leRapideSeulDonneUnPlanSansInventerDePriorite` : rapide écrit
seul ⇒ `ACTIVE`, priorités **toutes en EE**, et EO/CO/CE à `acquireCount == 0`.

### Le recalcul, et la marque « provisoire »

**Rien à invalider** : le Plan est dérivé à la lecture de bout en bout (moteur de maîtrise,
cycle, domaines). Chaque épreuve du complet qui se termine écrit ses observations, et la
lecture suivante en tient compte — sans job ni cache.

Le caractère provisoire est **déjà servi**, aucun champ nouveau : `LearningPlanDto.cycle
.profileComplete` / `domainsEvaluated` / `domainsExpected`, et `domainesAEvaluer` non vide.
Un front ne compte jamais des domaines vides pour le deviner.

### Reprendre, pas recommencer : `prochaineEpreuve`

`ModulePreparation.prochaineEpreuve` (`EpreuveType`, nullable) = la première section non
`TERMINEE`, dans l'ordre serveur (`TcfDiagnosticReadService.EPREUVES`). 🛑 `null` quand il n'y a
rien à reprendre — complet **jamais démarré** (aucune sous-épreuve n'est tirée, en nommer une
serait l'inventer) ou **terminé**. Et `fait` / `total` valent `0 / 4` dès que le Plan existe :
le dénominateur est une donnée serveur, pas une constante front.

Le CTA vise le **hub** `/diagnostic-tcf`, jamais un lancement direct : c'est le hub qui reprend
où l'on s'est arrêté (une épreuve terminée n'y porte plus de bouton) et qui pose
l'avertissement « une fois commencée, elle se termine d'une traite ». Un lien profond
déclencherait un chrono par surprise.

### Le freemium ne bouge pas

`locked` reste servi et opposable en 403. Un Plan provisoire pour un non-abonné est verrouillé
exactement comme un Plan complet — aucun accès n'a été ouvert dans cette passe.

Gelé par `PreparationServiceIT` : `leRapideClosRendLePlanDisponible`,
`leCompletEnCoursNeFermePasLePlan`, `sansRapideLePlanNestPasDisponible`,
`leCompletClosNaPlusDeProchaineEpreuve`.

### Côté fronts — une autorité, trois lecteurs

`affinerPlan()` (web `lib/preparation.ts` ⇄ mobile `core/models/preparation_labels.dart`,
miroirs mot pour mot) rend l'invitation au complet sous ses **trois** formes, lue par le Plan
gratuit, le Plan abonné et l'Accueil :

| État servi | Carte |
|---|---|
| `0 / 4`, jamais commencé | « Affiner votre Plan » (abonné : « Rendez votre Plan encore plus précis »). 🛑 **« 0 / 4 » n'est pas affiché** |
| `1 / 4` à `3 / 4` | « Diagnostic complet en cours » + « N / 4 épreuves terminées » + barre + prochaine épreuve **si servie** |
| `4 / 4` | `null` — plus aucune invitation, nulle part |

Le rendu vit dans un composant unique par front (`AffinerPlanCard`), posé **après** le contenu
du Plan, bouton `line` (contour) : 🛑 sur un compte gratuit, le seul bouton plein de la page
reste « Débloquer mon plan ». Sur l'Accueil la carte n'apparaît **que** si le complet est
commencé, en action secondaire persistante.
