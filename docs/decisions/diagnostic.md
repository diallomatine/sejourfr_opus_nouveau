# Journal — diagnostic (V040 / V041 / V042)

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Journal daté, verbatim et intégral.**
> Origine : lignes 1196-1341 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier consigne les arbitrages et révocations : on l'ouvre **avant de changer une règle**, pas pour l'appliquer.
> Fichier jumeau : `docs/regles/diagnostic.md`
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

- **UNE MISE EN FORME NE COÛTE PLUS LE DIAGNOSTIC** (2026-08-25). En prod, sur la submission
  `3136658f-d3f7-46cc-8344-336ee928bd85` (EO, transcription de 1 045 caractères) :
  `Sortie diagnostic invalide submission=… — réparation unique : [summary dépasse 280
  caractères, EO2-C7 : une compétence non observée doit avoir une confiance LOW]`, puis
  `Pipeline async FAILED … : Sortie diagnostic invalide après réparation : summary dépasse
  280 caractères`. Coût réel de l'incident : **deux appels LLM payés** (l'analyse + la
  réparation), **zéro analyse persistée**, session `FAILED`, et chaque relance
  (`max-session-retries: 3`) repayant les deux appels pour buter sur la même phrase de ~300
  caractères. La même minute, `44f43bdd-262c-45ad-bb40-3e50f5906572` partait en réparation sur
  le seul motif `EE2-C2 : une compétence non observée doit avoir une confiance LOW`.
  - **Cause** : `summary.maxLength: 280` est bien déclaré dans
    `diagnostic-analysis-tool-schema-v1.json`, mais **aucun fournisseur n'applique une longueur**
    (correcteur par défaut : DeepSeek, `EVAL_LLM_PROVIDER`). Contrairement à `enum`, `required`
    et `additionalProperties`, `maxLength`/`maxItems` ne sont pour le modèle qu'une indication.
    L'ordre de préférence du dépôt — *tool-schema > longueur plafonnée > contrôle serveur
    déterministe > consigne de prompt* — supposait ici une garantie qui n'existe pas.
  - **Décision** : ces motifs rejoignent `priority` dans `DiagnosticAnalysisReconciler`, **avant**
    le validateur, donc **avant toute réparation payée**. Longueurs (`summary` 280, item de
    `strengths`/`weaknesses` 180, `explanation` 220) et taille de liste (3) sont **tronquées**
    — coupe sur limite de mot, ellipse `…`, jamais un point final inventé, qui ferait passer une
    phrase coupée pour une phrase finie. La confiance d'une compétence `observed=false` est
    **ramenée à `LOW`**, exactement comme sa `priority` est ramenée à `false` : une compétence
    non observée ne dit rien du candidat, il n'y a aucune confiance à graduer.
  - 🛑 **Ce qui reste un refus** : ce que le serveur ne peut pas inventer sans mentir —
    `skill_code` hors allowlist, compétence manquante, `evidence_segment` absent ou hors bornes,
    enum invalide, champ hors contrat, `level_estimate` au-dessus de B2. Et une **preuve posée
    sur une compétence déclarée non observée** n'est PAS effacée : c'est une contradiction du
    correcteur, pas une mise en forme.
  - **Contrat v1 inchangé** (ni rubriques, ni tool-schema) : on ne réécrit pas une version
    livrée. Le `maxLength` reste au schéma comme indication au modèle ; c'est le serveur qui le
    rend dur.
  - **Compteurs** (`DiagnosticReconciliationMetrics`, même famille que les priorités dérivées) :
    `SYNTHESE_TRONQUEE`, `TEXTE_TRONQUE`, `LISTE_TRONQUEE`, `CONFIANCE_NON_OBSERVEE_DERIVEE`.
    Ils disent à quelle fréquence le fournisseur ignore le contrat — c'est eux qui justifieront,
    ou non, de resserrer la consigne des rubriques en v2 plutôt que de tronquer.
  - **Verrouillé** par `DiagnosticAnalysisReconcilerTest` (le cas de prod, le summary pile au
    plafond qui n'est pas touché, les deux plafonds de liste, l'explication, la confiance
    non observée, la non-mutation de la sortie d'origine).

- **UNE PRODUCTION INEXPLOITABLE NE PRODUIT AUCUN NIVEAU** (2026-08-21, V040). Mesuré en
  base : **4 s d'audio, 7 caractères transcrits, verdict `A1_NON_ATTEINT`** — une *absence de
  preuve* enregistrée comme la *preuve du niveau le plus faible*. Et depuis que le diagnostic
  sert de **repli** EE/EO à `TcfProfileService`, ce faux verdict devenait le niveau du domaine
  puis, par le **plancher des 4 domaines**, le niveau global du candidat. C'est la confusion
  que tout le dépôt combat sous *null = inconnu, jamais mauvais* — le diagnostic était le seul
  endroit qui ne la tenait pas, faute de pouvoir dire « pas de niveau ».
  - 🛑 **Rien n'est demandé au correcteur quand il n'y a rien à observer** — patron
    `AiEvaluationService.evaluate` (verdict `INVALIDE` ⇒ aucun appel) et
    `TranscriptionQualityAudit.degradee` (version ciblée). À qui on demande un palier, on
    obtient un palier : un modèle sollicité sur un mot en nommera un. **Les contrats IA du
    diagnostic ne bougent pas d'un octet** (`diagnostic-analysis-*-v1`) : c'est un contrôle
    serveur, pas une consigne.
  - **Juge unique** : `ProductionValidityService`, **appelé** et non recopié.
    `evaluerDiagnostic` est le même contrôle avec un **plancher paramétré**
    (`sejourfr.production-evaluation.validite.min-mots-diagnostic: 20`, POJO à la même
    valeur). Plus haut que le plancher générique (5) parce que la **conséquence** l'est : une
    production de diagnostic fixe le niveau d'un **domaine**, pas seulement son propre retour.
    20 mots ≈ 2-3 phrases complètes, soit **un cinquième** de ce que le sujet demande.
    🛑 **La frontière n'est pas « c'est mauvais », c'est « il n'y a rien à observer »** : un A1
    authentique produit peu. Mesure : les 2 lignes fautives font **1 et 3 mots**, les 16
    autres **≥ 104** — aucun cas réel n'approche la ligne.
  - **Schéma (V040)** : les **trois** verdicts (`level_estimate`, `task_completion`,
    `communication_status`) deviennent **nullables** — écrire `NOT_COMPLETED`/`INEFFECTIVE`
    sur 4 secondes remplacerait un faux verdict par deux autres —, plus une colonne
    `evaluabilite` (`DiagnosticEvaluabilite{EVALUABLE|NON_EVALUABLE}`, NOT NULL, défaut
    `EVALUABLE`) et **deux CHECK** dont un qui interdit de mélanger les deux états. Le champ
    existe parce que **absence de ligne = « pas encore analysée »** ≠ **ligne `NON_EVALUABLE`
    = « rendue, rien à observer »** : deux phrases différentes côté front, et un front ne doit
    pas déduire un fait de la nullité de trois colonnes. **Aucun libellé serveur.**
  - ✅ **Les 2 lignes fausses ont été REJUGÉES** (V042, cf. le point dédié plus bas) :
    l'arbitrage du propriétaire est rendu. V040 elle-même ne migre toujours rien.
  - **Le reste a marché sans une ligne de code neuf**, et c'est vérifié de bout en bout :
    `findCompletedLevelsByUser` filtrait **déjà** `levelEstimate IS NOT NULL` ;
    `PlanCycleResolver` pose `evaluated = (niveau != null)`, donc le domaine retombe seul dans
    `domainesAEvaluer` (kind `PRODUCTION`, le diagnostic étant terminé) ;
    `DiagnosticExempleCibleService` sortait déjà sur `constate == null`.
  - **La session ne devient JAMAIS `FAILED`** : une production inexploitable sur deux laisse
    un diagnostic utile, le candidat garde son résultat écrit. L'`analysis_json` porte une
    observation **`NOT_OBSERVED` par compétence de l'allowlist** (une production rendue est
    une activité, cf. `lastActivityAt`) — c'est aussi ce qui garde
    `DiagnosticService.recommendedAction` capable de désigner un exercice quand les **deux**
    productions sont inexploitables.
  - ✅ **Le trou JUMEAU de la voie standard est bouché** (2026-08-21, V041) — cf. le point
    suivant.
  - ⚠️ **Pourquoi une soumission de 4 s passe** : `validateAudio` ne contrôle que la **taille
    en octets**, jamais la durée, et `production_tasks.duree_min_sec` (90 s sur le sujet
    diagnostic) n'est opposable **nulle part** — seul l'écrit l'est
    (`validateTextWordCount`). **Ne pas la rendre opposable au rendu** : refuser la soumission
    ferait perdre la production, alors qu'on préfère l'accepter et ne pas en conclure.
- **LE MÊME, SUR LA VOIE STANDARD** (2026-08-21, **V041**). `AiEvaluationService
  .persistProductionInvalide` écrivait `note 0` + `A1_NON_ATTEINT` dans `ai_evaluations` —
  **aucun appel LLM n'ayant eu lieu**. Blast radius plus large que le diagnostic :
  `ai_evaluations` est la table que `TcfProfileService` lit **en priorité** (le diagnostic n'en
  est que le **repli**), donc une seule production ratée fixait le domaine EE ou EO, puis le
  niveau global par le plancher des 4 domaines. La ligne ne porte plus **ni note, ni niveau, ni
  `niveau_cecrl_ia`** ; `feedback_json` ne porte plus **ni `note_globale` ni `niveau_cecrl`**.
  - 🛑 **DEUX SITUATIONS QUI SE RESSEMBLENT ET QU'IL NE FAUT JAMAIS CONFONDRE.** (a) *production
    rendue mais inexploitable* ⇒ **aucun niveau** ; (b) *épreuve d'examen ouverte, chrono
    écoulé, rien rendu* ⇒ **`A1_NON_ATTEINT`, décision produit inchangée** — « elle a été passée
    et ratée ». **Elles sont séparables parce qu'elles ne partagent aucun code** : (a) est une
    **ligne qui existe et ne dit rien**, (b) est **l'absence de ligne**, traitée par
    `ProductionBilanService.bilanEpreuveTerminee` (« le reste noté 0 »), qui **ne bouge pas**.
    Ne pas « unifier » les deux.
  - **Le bilan d'épreuve est INCHANGÉ, par construction** : `latestEvalsByTache` écarte la ligne
    sans verdict, donc sa tâche retombe à « non rendue », donc elle compte **0** sur une épreuve
    terminée — exactement ce qu'elle valait quand elle y entrait avec une note 0. Le niveau d'un
    **examen complet** en hérite sans une ligne de code (`FullTcfExamResponseBuilder`), et ses
    trois exclusions (`locked`, `cecrlLevel` null, **jamais ouverte**) restent intactes.
  - **Colonne `evaluabilite`** (`ProductionEvaluabilite{EVALUABLE|NON_EVALUABLE}`, NOT NULL,
    défaut `EVALUABLE`) + CHECK `NON_EVALUABLE ⇒ note_sur_20 / niveau_cecrl / niveau_cecrl_ia
    NULL`. **L'enum est PARTAGÉE avec le diagnostic** (`DiagnosticEvaluabilite` renommée à la 2ᵉ
    occurrence : même fait, même juge `ProductionValidityService`, valeurs sérialisées
    inchangées). ⚠️ **La contrainte ne va que dans UN sens** : la réciproque (`EVALUABLE ⇒
    verdicts non nuls`) inventerait un invariant que le code n'a jamais tenu — ces deux colonnes
    sont nullables depuis V011.
  - **Exposé aux fronts** sur `EvaluationResultDto.evaluabilite` (miroirs web/mobile/admin :
    passe dédiée). **Trois états**, pas deux : bloc `evaluation` absent = « pas encore
    évaluée » ; présent + `NON_EVALUABLE` = « rendue, rien à observer ». Aucun libellé serveur.
  - **`version_ciblee` n'est plus demandée** sur une production inexploitable : sans ce garde,
    `aQuelqueChoseAViser(null, visé)` rend `true` et on **payait** un appel pour réécrire du
    vide. Et **aucun `niveau_vise_atteint`** n'est posé : ce serait annoncer une victoire à qui
    n'a rien rendu. La voie **Plan** (`observeStandardProduction`) était **déjà** protégée par
    le même juge depuis V040.
  - `UserDashboardService` prend le **dernier niveau réellement évalué**, plus la dernière ligne
    quelle qu'elle soit : une production ratée n'efface plus le niveau déjà obtenu. Idem
    `TcfProfileService`, où « la plus récente fait foi » se joue désormais sur **toutes** les
    lignes d'une soumission avant le filtre des nulls.
  - ✅ **Les 4 lignes ont été REJUGÉES** (V042, ci-dessous). V041 elle-même ne migre rien.
  - ✅ **`scores_criteres` est RETIRÉ de ce chemin** (2026-08-21). ⚠️ **Révoque** le
    « laissé exprès » du jour même. Il portait les 4 critères à `note_sur_20: 0` avec
    `bande: NON_EVALUABLE` : le sens vivait dans la **bande**, la note disait le contraire, et
    rien n'empêchait un lecteur (front, export, futur calcul) de sommer des zéros — la même
    confusion que le niveau qu'on venait de retirer, un cran plus bas. **Doctrine du dépôt** :
    un champ **absent du contrat ne peut pas être produit par erreur**, ce qui vaut mieux que
    quatre zéros qu'on compte sur trois fronts pour ne pas afficher. Ce qui reste sont des
    **faits** : `accomplissement.objectif = NON_ATTEINT`, `confiance = FAIBLE` et ses raisons.
    **Aucun lecteur serveur ne le supposait présent sur ce chemin** (vérifié) :
    `latestEvalsByTache` écarte déjà une ligne sans note ni niveau, donc `ProductionBilanService
    .competenceOf` ne la lit jamais ; validateur, filtres et `capListe` ne tournent que sur une
    sortie de correcteur, et il n'y en a pas ici ; `BandeCritere.NON_EVALUABLE` reste produite
    par `BandeCritere.of(0)` sur la voie LLM, l'enum ne bouge pas. 🛑 **Legacy intact, aucune
    migration** : les `feedback_json` déjà persistés gardent leurs quatre zéros — les fronts
    doivent traiter l'**absence** du champ (aucun ne plante : web `lib/types.ts`, mobile
    `production_models.dart` et admin `EvaluationReport` replient déjà sur une liste vide ; il
    reste à ne pas afficher un bloc « critères » vide, en lisant `evaluabilite`).
- **ON REJUGE LES 6 LIGNES QUI PORTAIENT UN FAUX NIVEAU** (2026-08-21, **V042**).
  V040 et V041 avaient écrit noir sur blanc qu'elles ne migraient rien et que le rattrapage
  était un **arbitrage du propriétaire**. Il est rendu : *on corrige*.
  - **Ce n'est pas réécrire l'historique.** L'historique, c'est **ce que le candidat a
    produit** — 4 s d'audio, 1 à 3 mots, un texte en anglais : rien n'y touche. Ce qu'on
    retire, c'est notre **conclusion** (`A1_NON_ATTEINT`), qui est la sortie d'un bug corrigé
    en `7a6739b`/`919fdd8`. Et on la retire **sans rien inventer** : le texte est toujours là,
    le juge est **déterministe**, **aucun appel LLM**.
  - **DEUX MARQUEURS, jamais un `UPDATE` en masse.** (1) `diagnostic_production_analyses` : la
    voie du diagnostic **sautait** le juge, rien dans la ligne ne dit qu'elle aurait été
    refusée ⇒ on **rejoue le critère**, et **seulement le compte de mots réel** (< `min-mots-
    diagnostic` = 20, valeur **figée** dans la migration : un geste décrit une date, pas un
    réglage courant), miroir SQL de `motsNormalises`, sur le **même texte** que le juge lit
    (transcription la plus récente en EO, `texte_soumis` à l'écrit). 🛑 Les deux autres
    familles de refus (langue, recopiage) ne sont **volontairement pas** reproduites en SQL :
    ce serait une **seconde copie** de la règle — en cas de doute, on ne touche pas ; idem pour
    une ligne portant un marqueur de tour. (2) `ai_evaluations` : **aucun critère à rejouer**,
    `modele_utilise = 'validation-serveur'` **est** le marqueur que `persistProductionInvalide`
    pose et lui seul, le juge avait déjà refusé — et ses règles n'ont pas bougé (`7a6739b` n'a
    fait qu'**ajouter** `evaluerDiagnostic`). ⚠️ Y appliquer le compte de mots toucherait
    **zéro** ligne (45 à 73 mots) : ces 4-là sont refusées pour langue étrangère et recopiage.
  - **Volume exact : 2 + 4 = 6 lignes, 3 comptes.** Effet mesuré : les 2 comptes du diagnostic
    voient leur domaine **oral** redevenir *non mesuré* (`null = inconnu, jamais mauvais`), donc
    leur niveau global remonte **`A1_NON_ATTEINT` → A2** et leur profil passe de 2/4 à **1/4**
    domaines mesurés. Le 3ᵉ (`admin@`) **ne bouge pas** : `bestProduction` retient le
    **meilleur** niveau par épreuve et ses autres productions écrites valent déjà B2 — ce qui
    change, c'est que ces 4 lignes cessent d'**affirmer** un niveau.
  - **Ce qui n'est PAS touché** : `analysis_json` / `feedback_json` (l'**archive**, et elle dit
    vrai : « la production ne contient qu'un simple Bonjour »), `model_used` / les tokens / le
    coût (sur les 2 lignes de diagnostic le correcteur a **réellement** été appelé et payé —
    l'écrire « validation-serveur » effacerait une dépense réelle ; les commentaires de colonne
    le disent), et la règle « épreuve **abandonnée** compte `A1_NON_ATTEINT` » (aucune ligne :
    c'est l'**absence** de ligne).
  - **Idempotente et bornée** : les deux ordres exigent `evaluabilite = 'EVALUABLE'`.
  - ⚠️ **Une migration de données ne se teste pas en place** :
    `RejugementProductionsInexploitablesIT` **relit le fichier**, le coupe sur sa sentinelle
    `@@REJUGEMENT_DES_PRODUCTIONS@@` et rejoue le SQL réel (patron
    `LegacyPassCompensationIT`). Ne pas supprimer cette ligne, ne jamais recopier la requête
    dans le test. Un test dédié vérifie qu'une production **que le juge accepterait** ne bouge
    pas, même avec le verdict le plus bas.
