# Journal — diagnostic (V040 / V041 / V042)

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Journal daté, verbatim et intégral.**
> Origine : lignes 1196-1341 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier consigne les arbitrages et révocations : on l'ouvre **avant de changer une règle**, pas pour l'appliquer.
> Fichier jumeau : `docs/regles/diagnostic.md`
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

- 🛑 **UNE ÉPREUVE MESURÉE EST UNE SECTION FAITE — il n'existe qu'UNE notion de
  « mesurée »** (2026-09-16, **quatrième** décision du propriétaire de la
  journée). Elle ne révoque rien de ce qui suit : elle branche l'écran
  Diagnostic sur l'autorité que les trois décisions précédentes ont construite.
  - **L'énoncé, verbatim.**
    > Normalement, la règle : un diagnostic complet, chaque épreuve **est** un
    > examen blanc de l'épreuve. Donc si un examen blanc est fait ailleurs,
    > directement on considère que **le diagnostic de cette épreuve est fait**,
    > et les priorités à travailler identifiées. Donc ce n'est pas normal qu'on
    > dise qu'une épreuve est « mesurée ailleurs » : si c'est mesuré, c'est
    > okay, sur le diagnostic. **Vérifie vraiment bien que toutes ces règles
    > sont bien appliquées partout et que c'est rigoureux.**
  - **Le défaut, constaté sur un compte réel.** Le candidat passe un examen
    blanc de compréhension orale depuis l'Accueil (25 questions, 25 réponses,
    B1) ; l'écran Diagnostic continuait d'annoncer sa propre section CO
    « Terminée · **Non évaluée** » (15 questions, 0 réponse). Les deux
    affirmations étaient vraies séparément, et c'est précisément ce que le
    propriétaire refuse. Cause : `TcfDiagnosticReadService.sections` ne lisait
    que les **sous-attempts de la session** (`findSubAttempts`), et un examen
    blanc isolé a `parent_attempt_id IS NULL` — il ne pouvait donc jamais y
    apparaître.
  - **Aucune autorité nouvelle n'a été créée**, et c'était la contrainte
    principale. « Cette épreuve est-elle mesurée ? » **est déjà** la question à
    laquelle répond le niveau actuel : `NiveauActuelEpreuveResolver`
    (`findQcmEpreuvesPassees` pour CO/CE, `EpreuvesProductionQualifiantesResolver`
    pour EE/EO). `null` ⇒ non mesurée, non-`null` ⇒ mesurée. Le resolver a
    seulement gagné un **`Mesure(niveau, attemptId)`** : le niveau est inchangé,
    `attemptId` nomme le **plus récent** des examens retenus — celui dont le
    rapport existe.
  - 🛑 **DEUX lectures, et il fallait les séparer** — c'est l'arbitrage
    technique de la passe, et le révoquer casserait `evolution` :
    - **`sections(session)` — ce que CETTE session a mesuré.** Inchangée.
      C'est elle que lisent la comparaison de deux diagnostics
      (`TcfDiagnosticProgressionResolver`), le palier **initial** et la courbe
      de l'écran Progrès (`ProgressService.tcf`), le « votre niveau estimé
      était B1 » de la réévaluation (`TcfReassessmentService`) et le cache
      `final_cecrl_level` posé à la clôture.
    - **`sectionsMesurees(session)` — ce que le PRODUIT sait.** Nouvelle, lue
      par l'écran Diagnostic (`vue`), son résultat (`resultat`) et la
      préparation (`PreparationService`, donc « N sur 4 » et « prochaine
      épreuve »).
    - **Pourquoi** : enrichir les deux côtés d'une comparaison reviendrait à
      comparer le niveau d'aujourd'hui à lui-même. Toute épreuve non jouée dans
      l'un ou l'autre diagnostic sortirait `STABLE` — « vous avez tenu votre
      niveau » alors que ces deux diagnostics-là n'ont rien mesuré. C'est
      V040/V041/V042 sous un autre déguisement. `resultat` passe donc des
      sections **enrichies** au résultat et des sections **propres** à la
      progression.
  - **L'enrichissement COMBLE, il ne remplace jamais.** Une section que la
    session a réellement mesurée garde **exactement** son résultat — niveau,
    score calibré, rapport. Seule une section qui n'a **rien** mesuré interroge
    le produit. Corollaire : la règle « une section rend SON résultat »
    (2026-09-13) est intacte, et un diagnostic ne se met pas à afficher une
    moyenne à la place de ce qu'il a lui-même mesuré.
  - **Ce que devient une section comblée** : `etat = TERMINEE`, `niveau` = celui
    du produit (donc **la même valeur que l'Accueil et le Profil**),
    `scoreCalibre = null` (une moyenne de trois examens n'a pas de « /499 »),
    `analyseEnCours = false`, et un **`rapportAttemptId`** neuf sur
    `TcfDiagnosticSectionDto` qui pointe l'examen qualifiant. Le CTA
    « Commencer » disparaît avec l'état, « Voir le rapport » mène à un rapport
    qui existe. ⚠️ Effet de bord **voulu** : une section close **sans aucune
    réponse** et mesurée nulle part n'a plus de bouton « Voir le rapport » du
    tout — son rapport était vide.
  - 🛑 **Aucun vocabulaire « mesurée ailleurs » n'est sorti**, refus explicite du
    propriétaire : le DTO ne porte **aucun drapeau de provenance**, une section
    mesurée se lit comme **faite**, point.
  - **« Et les priorités à travailler identifiées »**, la moitié qu'on aurait pu
    oublier : `tachesMesurees` lit désormais les productions de l'attempt **qui
    a mesuré** (`rapportAttemptId`), plus du sous-attempt de la session. Sans
    cela, une EE mesurée par un examen blanc rendait son niveau mais **aucune
    tâche** à travailler. En compréhension, les deux chemins alimentaient déjà
    le Plan à égalité (`ComprehensionObservationService` est appelé sur **toute**
    session QCM TCF terminée) ; en expression aussi
    (`LearningPlanObservationService.recordProduction`, qui distingue seulement
    le **poids** `MOCK_EXAM_EE/EO` de `PRODUCTION_EE/EO`).
  - **La clôture n'a eu besoin d'aucune levée de garde** : `cloturer` n'a jamais
    exigé les 4 sections (10_ §4.2 impose déjà de calculer sur ce qui existe).
    Les 4 épreuves mesurées ⇒ 4 sections `TERMINEE` ⇒ `resultatDisponible` passe
    de lui-même, des deux côtés.
  - **Tests** : `TcfDiagnosticEpreuveMesureeIT` (examen blanc isolé, examen TCF
    complet + ses priorités, mesurée nulle part, lecture historique non
    enrichie, les 4 mesurées ⇒ clôture et résultat).
  - ⚠️ **Contradiction restante, signalée et NON corrigée** : l'écran **Réviser**
    et la **fiche de domaine du Plan** affichent « Niveau estimé : X » à partir
    de `PlanDomainDto.niveau`, qui vient de `TcfProfileService.levelProfile` —
    le **maximum** de toutes les observations, **entraînement compris**. Un
    candidat dont la seule trace EO est un entraînement y lit donc « Niveau
    estimé : A2 » pendant que l'Accueil, le Profil, Progrès et maintenant le
    Diagnostic disent « À évaluer ». La lecture du Plan est un arbitrage explicite
    du propriétaire du même jour et n'est pas en cause ; ce qui l'est, c'est la
    **phrase** « Niveau estimé » posée dessus par un écran de catalogue. Décision
    produit à prendre, pas à prendre en passant.
    - ✅ **TRANCHÉE ET FERMÉE le 2026-09-16, cinquième décision du propriétaire :
      « aligne Réviser ».** L'écran lit désormais l'**autorité d'affichage**,
      la même que l'Accueil et le Profil — `tcfDomainProfile`, publication de
      `TcfProfileService.levelProfileAccueil` — par `niveauActuelEpreuve(profil,
      code)` (`web_sejoufr/lib/reviser.ts` ⇄
      `mobile_sejourfr/lib/screens/reviser/reviser_labels.dart`, miroirs).
      Un candidat ne peut plus lire deux paliers pour la même épreuve sur deux
      écrans qu'il ouvre dans la même minute.
    - 🛑 **Aucun appel de plus, et c'est ce qui a décidé de la source.** Les deux
      Réviser chargeaient **déjà** `GET /api/me/dashboard` — ils y lisent
      `CategoryStat` pour « 2 / 10 séries ». `tcfDomainProfile` voyageait dans la
      même réponse, inutilisé. `GET /api/me/progress` porte la même valeur
      (`ProgressDto.Tcf.epreuves[].niveau`) mais **n'est chargé par aucun des deux
      Réviser** : le brancher aurait coûté une requête par ouverture d'onglet,
      pour la valeur qui était déjà là.
    - 🛑 **Le repli `DashboardCategoryStat.level` est SUPPRIMÉ de cette phrase** —
      c'était une **troisième** autorité (le dernier niveau CECRL de n'importe
      quelle soumission EE/EO), encore plus large que celle du Plan, et elle
      n'avait aucune raison d'être lue ici. **Le champ reste au DTO** : quatre
      lecteurs subsistent (`/statistiques` et `ReinforceRow` côté web,
      `progres_screen` et `reco_screen` côté mobile). ⚠️ **Ces quatre-là écrivent
      eux aussi « Niveau estimé X » sur `stat.level`** : c'est un reste de la même
      famille, hors du périmètre arbitré ce jour — à rouvrir, pas à corriger en
      passant.
    - **Épreuve non mesurée ⇒ aucun palier inventé** : la ligne retombe sur ce
      que Réviser sait **compter** (séries terminées, compétences observées), et
      à défaut sur son propre « **Pas encore travaillé** » — son vocabulaire de
      catalogue, pas le « À évaluer » d'un constat. `null` = inconnu, jamais un
      plancher.
    - **Le reste de la ligne n'a pas bougé** : tâche courante, compétences
      acquises, séries faites, anneau de couverture. `PlanDomainDto` reste lu
      pour ce qui se **compte** — la mesure, elle, ne vient plus de lui.
    - ⚠️ **La fiche de domaine du Plan reste sur la lecture du Plan**, et c'est
      voulu : elle *est* le Plan. La contradiction ne portait que sur la phrase
      d'un écran de **catalogue**.
    - **Aucun test front ajouté** (règle du dépôt) : `npx tsc --noEmit`,
      `npm run build`, `npm test` (270 verts), `flutter analyze` (0 issue),
      `flutter test` (296 verts) et
      `node scripts/verifier-contrat-front-progression.mjs`. **Backend non
      touché** — le DTO servait déjà tout ce qu'il fallait.

- 🛑 **LE MAXIMUM MONOTONE DE LA LECTURE D'AFFICHAGE EST RÉVOQUÉ — le niveau
  affiché est la MOYENNE DES 3 DERNIERS EXAMENS QUALIFIANTS** (2026-09-16,
  **troisième** décision du propriétaire de la journée, celle **qui fait foi**).
  Les deux entrées ci-dessous sont **conservées pour la trace** : ce qu'elles
  disent de l'**exclusion de l'entraînement** reste vrai et intact ; ce qu'elles
  disent du **maximum** ne l'est plus.
  - **Ce qui est révoqué, mot pour mot.** L'entrée du matin écrivait : « *Ce qui
    NE change pas, et c'est délibéré : (1) le **maximum monotone** — le niveau
    d'une épreuve reste le meilleur de tout l'historique qualifiant, jamais le
    dernier, donc l'anti-yoyo tient toujours par construction* ». Et le javadoc
    de `TcfProfileService.bestEpreuveComplete` : « *Toujours un maximum monotone :
    une mauvaise journée ne fait pas redescendre, et l'ordre des sessions
    n'influence rien. C'est ce qui tient l'anti-yoyo sans règle de séquence.* »
    **Les deux sont fausses depuis cette décision**, pour la lecture d'affichage.
  - **Pourquoi elles sont révoquées.** Le maximum répond à « qu'avez-vous déjà
    démontré ? ». L'écran, lui, pose « où en êtes-vous **aujourd'hui** ? ». Un
    candidat qui a régressé lisait son meilleur jour comme son niveau courant, et
    aucun examen raté ne pouvait le lui dire — ce qui est exactement l'inverse de
    ce qu'un outil de préparation doit faire à trois semaines de l'examen.
  - **L'énoncé du propriétaire, verbatim.**
    > Je confirme : **moyenne des 3 derniers examens qualifiants**. Le niveau
    > affiché doit représenter le **niveau actuel estimé**, donc il peut monter
    > comme descendre.
    > - 1 examen qualifiant → niveau de cet examen ;
    > - 2 examens → moyenne des 2 ;
    > - 3 examens ou plus → moyenne des **3 derniers uniquement**.
    >
    > Les examens qualifiants sont : l'épreuve passée dans le diagnostic ;
    > l'examen blanc isolé de cette épreuve ; cette épreuve passée dans un examen
    > blanc TCF complet. **Les entraînements ne comptent pas.**
    >
    > Si on dispose d'un **score numérique interne**, moyenne d'abord les
    > **scores** puis transforme le résultat en niveau CECRL. Évite de faire une
    > moyenne directe des labels A2/B1/B2.
    >
    > On retire donc la règle du **maximum monotone** et la protection « le
    > niveau ne redescend jamais ». Le meilleur niveau atteint peut rester
    > visible plus tard dans l'historique, mais il ne doit pas être confondu avec
    > le niveau actuel affiché.

    Et sur le périmètre :
    > Accueil et Profil, c'est juste l'affichage du **niveau actuel**. Le niveau
    > global, c'est le **min des niveaux des 4 épreuves** (même chose dans
    > Profil, le « niveau estimé »). Donc il faut qu'on ait **le niveau global
    > estimé et les niveaux estimés de chaque épreuve**. Même pour le niveau
    > global, on applique d'abord la moyenne par épreuve, puis on prend le min
    > des épreuves.
  - **Ce qui la remplace** : `NiveauActuelEpreuveResolver`, **une seule fois pour
    les 4 épreuves**, appelé par `TcfProfileService.levelProfileAccueil` et par
    personne d'autre. Les ≤3 sessions les plus récentes, leurs **scores**
    moyennés, puis une conversion par la table de bandes **existante**.
  - 🛑 **On moyenne des SCORES, jamais des labels**, et aucune table n'est
    recopiée — c'est le défaut le plus cher du dépôt (les paliers ont vécu en
    6 copies). CO/CE : le **score calibré 100-499** déjà produit par
    `TcfLevelEstimatorService.calibratedScore`, converti par
    `niveauDepuisScoreCalibre` (nouvelle méthode **publique**, qui n'est que
    `levelByScore` + `capB2`). EE/EO : la **compétence /20 de l'épreuve**,
    l'agrégat pondéré des 3 tâches — elle existait, mais restait **privée** dans
    `ProductionBilanService.compute` ; elle est désormais publiée sur
    `NiveauEpreuve.competence` et convertie par `niveauDepuisCompetence`, qui
    n'est que `niveauFromCompetence` + les seuils de la grille active.
    - ⚠️ **Le garde-fou de cohérence T3 abaissait le NIVEAU, pas le score** : la
      compétence publiée est ramenée sous la bande plafonnée par `sousPlafond`
      (l'autorité qui existait déjà pour le plafond de tâche), sinon le plafond
      se serait perdu dans la moyenne.
  - **Règle de bande, écrite noir sur blanc** : une moyenne qui tombe **entre
    deux bandes reste dans la bande BASSE** — la convention déjà en vigueur pour
    les notes de critère. Elle est gratuite : les deux tables sont des **bornes
    basses** (`>=`). Côté QCM la moyenne est ramenée à l'entier **inférieur**
    (`RoundingMode.FLOOR`) avant conversion, ce qui est strictement la même
    décision : 399,5 reste B1, 400,0 devient B2.
  - **Aucune définition d'« examen qualifiant » n'a été réécrite.** Les deux qui
    existent sont **appelées** : `AttemptRepository.findQcmEpreuvesPassees` pour
    CO/CE (avec les sous-épreuves de diagnostic, depuis le correctif du même
    jour) et `EpreuvesProductionQualifiantesResolver` pour EE/EO. L'ordre
    chronologique n'a pas été réinventé non plus : les deux rendent déjà leurs
    sessions du plus récent au plus ancien, comme pour `EpreuveHistoriqueService`.
  - **Aucun examen qualifiant ⇒ `null`** (« À évaluer »), jamais un plancher
    fabriqué. Une session qui porte un palier mais **aucun score moyennable**
    (repli sur les niveaux persistés, attempt legacy sans score pondéré) ne casse
    rien : si aucune des sessions retenues n'a de score, le palier de la **plus
    récente** fait foi — « 1 examen → le niveau de cet examen ».
  - **Le global reste le MIN des 4**, `TcfLevelEstimatorService.floor` — la règle
    du plancher n'est pas dupliquée, elle reçoit simplement les nouvelles valeurs.
  - 🛑 **TOUTES les surfaces d'affichage basculent, et c'était la moitié du
    sujet.** `UserDashboardService` passait encore par `levelProfile` (« hors
    périmètre de l'arbitrage », écrivait l'entrée du matin) : le **Profil**
    annonçait donc le maximum du Plan pendant que l'**Accueil** annonçait autre
    chose. Il lit maintenant `levelProfileAccueil`. Comme
    `DashboardSummaryResponse.estimatedTcfLevel` est le **seul** endroit d'où ce
    niveau sort pour les fronts, les **cinq** surfaces web (`/dashboard`,
    `/profil`, `/statistiques`, `TcfHub`, `/examens-blancs`) et les **deux**
    surfaces mobiles (Accueil, Profil) annoncent maintenant le même palier, au
    même instant. Verrouillé par `UserDashboardServiceTest.summary_neLitJamaisLaLectureDuPlan`.
  - ⚠️ **Le PLAN n'est PAS touché, ni dans sa source ni dans son maximum.**
    `TcfProfileService.levelProfile` — la lecture de `PlanCycleResolver`, des
    priorités et des compétences — continue de voir les entraînements EE/EO **et**
    de retenir le **meilleur** résultat. Un Plan n'a pas à désapprendre ce qu'un
    candidat a démontré, et l'arbitrage du matin sur le périmètre reste entier.
  - **Aucun DTO n'a changé de forme, aucun front n'est touché.** `niveau` était
    déjà nullable et `TcfDomainProfileDto` publiait déjà les **4 paliers
    d'épreuve** à côté du global, sur `GET /api/me/dashboard` — la demande
    « le niveau global estimé **et** les niveaux estimés de chaque épreuve »
    était déjà servie, elle ne l'était simplement pas par la bonne lecture.
  - 🛑 **Niveau ACTUEL affiché ≠ MEILLEUR niveau atteint.** Le meilleur reste
    lisible, et à un seul endroit : la page « Voir mes résultats »
    (`EpreuveHistoriqueService`), qui liste les 3 dernières mesures avec leur date
    et leur provenance. Ne jamais présenter l'un comme l'autre.
  - **Verrouillé par** : `NiveauActuelEpreuveResolverTest` (1 / 2 / 4 examens, la
    baisse sur un mauvais examen récent — **le cas exact que l'ancienne règle
    interdisait** —, la bande basse sur 399,5, le plancher A1, le repli sans
    score, le plafond B2) ; `TcfProfileServiceIT` (les **3 provenances à
    égalité** en base, la moyenne réelle, la fenêtre de 3, l'entraînement dehors,
    le min des 4 sur les 4 vraies épreuves) ; `TcfProfileServiceTest` section
    « lecture d'AFFICHAGE » (le câblage, et l'affichage **plus bas** que le Plan) ;
    `EpreuvesProductionQualifiantesResolverTest` (la compétence servie avec le
    palier). La section « anti-yoyo » de `TcfProfileServiceTest` est **conservée
    et re-cadrée** : ses cas B / C / I ne valent plus que pour la lecture du Plan,
    et son en-tête le dit.

- 🛑 **PÉRIMÈTRE CORRIGÉ LE MÊME JOUR — la règle vaut pour l'ACCUEIL, PAS pour le PLAN**
  (2026-09-16, seconde décision du propriétaire, celle **qui fait foi**). La première passe
  décrite juste en dessous avait restreint `TcfProfileService.levelProfile` **globalement**,
  donc aussi `PlanCycleResolver`, les priorités et les compétences. Le propriétaire a tranché
  que c'était trop large :
  - **Son énoncé, verbatim.** « Limite l'effet à l'Accueil uniquement. Accueil / niveau global
    par épreuve → uniquement basé sur un examen complet de l'épreuve. Plan / priorités /
    compétences → peut continuer à utiliser les observations issues des entraînements EO/EE.
    Ne change PAS `TcfProfileService.levelProfile` globalement si ça impacte le Plan. Fais
    plutôt une logique dédiée à l'affichage du niveau sur l'Accueil, ou un resolver spécifique
    pour le "niveau global affichable". En résumé : entraînement EO/EE = utile pour le Plan ;
    examen complet EO/EE = nécessaire pour afficher un niveau global sur l'Accueil. »
  - **Ce qui a été reverté**, exactement : `TcfProfileService.bestProduction` retrouve son
    comportement d'avant — toute évaluation IA valide, entraînement compris, la plus récente
    par soumission faisant foi, avec le repli sur `diagnostic_production_analyses`. Avec lui,
    le **budget de requêtes du Plan revient à 23** (`LearningPlanCycleIT
    .leCoutDuPlanNeGrandiPasAvecLHistorique`) : le N+1 corrigé en lots dans la première passe
    n'a plus lieu d'être là, puisque le Plan ne lit plus les épreuves complètes.
  - **Ce qui a été GARDÉ** : `EpreuvesProductionQualifiantesResolver`, l'autorité qui
    distingue l'examen complet de l'entraînement, et ses deux requêtes en lot. C'est la bonne
    logique ; elle sert désormais deux lecteurs — la page « Voir mes résultats » et l'Accueil.
  - **Où vit la règle d'Accueil maintenant** : `TcfProfileService.levelProfileAccueil`, une
    **seconde lecture** du même profil, appelée **uniquement** par `ProgressService.tcf()`.
    Elle partage tout avec `levelProfile` — CO/CE, repli baseline, plancher — et ne diffère
    que sur la source d'EE/EO (`bestEpreuveComplete` au lieu de `bestProduction`). Une seule
    autorité, deux lectures nommées, aucune duplication de la baseline ni du plancher.
  - **Le niveau GLOBAL de l'Accueil suit** : c'est le plancher des **quatre paliers
    affichés**, sinon l'écran annoncerait un niveau global tiré d'une EO qu'il présente deux
    lignes plus bas comme non évaluée. ~~`UserDashboardService` (l'ancien `/dashboard`) n'est
    pas concerné : il garde `levelProfile`, hors périmètre de l'arbitrage.~~ 🛑 **RÉVOQUÉ le
    jour même** : il lit `levelProfileAccueil`, sans quoi le **Profil** annonçait le maximum
    du Plan pendant que l'Accueil annonçait autre chose — cf. l'entrée en tête de fichier.
  - **`niveauInitial` / `evolution` / `status` : inchangés, et c'est cohérent.**
    `niveauInitial` vient des sections du **premier diagnostic 4 épreuves clos** — or une
    section EE/EO de diagnostic complet est justement l'une des trois provenances
    qualifiantes. Les deux paliers se lisent donc déjà sur la même famille de mesures, et
    `actuel` étant un **maximum** sur ces sessions, il ne peut pas passer sous `initial`.
    `status` dérive d'`actuel`, il suit sans rien à changer.
  - **Verrouillé par** : `ProgressServiceIT.lEntrainementRenseigneLePlanPasLAccueil` — le même
    candidat, le même entraînement EO noté B1 : le Plan lit **B1**, l'Accueil affiche **« à
    évaluer »**, et une épreuve complète à A2 ajoutée ensuite s'affiche, elle, à **A2** sans
    faire bouger le B1 du Plan. Plus `ProgressServiceTest.lAccueilNeLitQueSaPropreLecture`
    (l'Accueil n'appelle jamais `levelProfile`) et la section « lecture d'ACCUEIL » de
    `TcfProfileServiceTest`.

- **EE/EO : UN ENTRAÎNEMENT NE DÉFINIT PLUS LE NIVEAU GLOBAL D'UNE ÉPREUVE** (2026-09-16,
  règle du propriétaire). ⚠️ **Entrée conservée pour la trace ; son périmètre est corrigé par
  l'entrée ci-dessus — Accueil seulement, jamais le Plan.** `TcfProfileService.bestProduction`
  se restreint aux **examens complets de l'épreuve**. C'est la **sortie 1** de l'arbitrage
  laissé ouvert le matin même
  par `EpreuveHistoriqueService` (« restreindre le profil EE/EO aux sessions d'examen » vs
  « accueillir l'entraînement libre sous une 5ᵉ provenance ») ; `docs/regles/progression.md`
  le notait comme *ouvert*, il est **clos**.
  - **L'énoncé du propriétaire, verbatim.** « Pour EO et EE, un entraînement ne doit JAMAIS
    définir le niveau global affiché à l'accueil, même s'il est corrigé par l'IA et produit un
    niveau CECRL. Les entraînements servent uniquement à : pratiquer autant que l'utilisateur
    veut ; alimenter les compétences/priorités/feedbacks ; conserver éventuellement un niveau
    observé sur la tâche. Le niveau global EO/EE ne doit être mis à jour que lorsqu'un examen
    complet de l'épreuve a été réalisé. Trois cas valides, et seulement trois : (1) l'épreuve
    EO/EE complète réalisée dans le diagnostic complet (4-épreuves) ; (2) un examen blanc
    isolé EO ou EE réalisé indépendamment ; (3) l'épreuve EO/EE réalisée dans le cadre d'un
    examen blanc TCF complet. Dans ces trois cas, on utilise le niveau calculé pour l'épreuve
    complète (l'agrégat des 3 tâches, pas une tâche isolée) et on peut l'afficher comme niveau
    global. Si aucun examen complet EO n'a encore été fait : `Expression orale — À évaluer`.
    Même chose pour EE. »
  - **LE CAS CONSTATÉ, en base.** Compte `wewiwe4789@bowlfuel.com` : **une seule** soumission
    EO, un entraînement libre de trois minutes (`attempts.type = TRAINING`,
    `mode = ENTRAINEMENT`, ni slot ni parent), évaluée **A2** par l'IA le 2026-09-13. Ce A2
    remontait comme « niveau global d'expression orale » à l'Accueil, alors qu'aucune épreuve
    d'EO n'avait jamais été passée par ce compte. Sa sous-épreuve EO de diagnostic complet
    existait bien, mais **vide** (0 soumission, jamais terminée). Après le correctif : EO =
    `null` ⇒ « À évaluer ». Son EE, elle, reste **B1** — par le **repli** sur la baseline du
    diagnostic rapide, inchangé.
  - **Ce qui distingue les 3 cas d'un entraînement, en SQL.** 🛑 **Pas `attempts.type`** :
    `AttemptService.startProduction` pose `TRAINING` sur **toutes** les sessions de
    production, examen blanc isolé compris — le drapeau d'examen y est le `slot_number`. Un
    filtre `type = MOCK_EXAM` aurait laissé le cas 2 dehors. Le prédicat réel est celui de
    `ProductionAccessService.isExamSession`, déjà porté en JPQL par
    `AttemptRepository.findProductionEpreuvesPassees` : `slot_number IS NOT NULL` (cas 2)
    **OU** `parent_attempt_id IS NOT NULL` (cas 3, **et** cas 1 — `TcfDiagnosticSectionStarter
    .creerProduction` accroche ses sections au même conteneur `TCF_COMPLET`), plus
    `finished_at IS NOT NULL` et `EXISTS` une soumission.
  - **Aucune règle dupliquée, une autorité EXTRAITE.** La liste des sessions qualifiantes et
    le niveau de chacune existaient déjà, dans `EpreuveHistoriqueService`. À la 2ᵉ occurrence,
    ils sont sortis dans `EpreuvesProductionQualifiantesResolver`, appelé par **les deux** —
    le profil en prend le **maximum**, la page « Voir mes résultats » la **chronologie**. Le
    niveau d'une session reste demandé à `ProductionBilanService.niveauEpreuve` : l'agrégat
    pondéré des 3 tâches, avec son garde-fou de cohérence T3 et son « reste noté 0 ».
  - **Ce qui NE change pas**, et c'est délibéré : (1) ~~le **maximum monotone** — le niveau
    d'une épreuve reste le meilleur de tout l'historique qualifiant, jamais le dernier, donc
    l'anti-yoyo tient toujours par construction~~ — 🛑 **RÉVOQUÉ le jour même** par l'entrée
    en tête de fichier : la lecture d'**affichage** sert désormais la **moyenne des 3
    derniers examens qualifiants** et peut redescendre. Le **Plan**, lui, garde bien son
    maximum ; (2) le **repli** sur
    `diagnostic_production_analyses` quand aucune des 3 sources n'existe — « une baseline n'est
    jamais concurrente d'une preuve réelle » ; (3) le **niveau observé sur la tâche**, que
    l'écran de résultat d'un entraînement continue d'afficher (`EvaluationResult.niveauObserve`)
    — seul le niveau **global** de l'épreuve cesse d'en tenir compte ; (4) la **forme du
    contrat** : `niveau` était déjà nullable, **aucun front n'est touché**.
  - 🛑 ~~**Le Plan en hérite, et c'est cohérent.**~~ **RÉVOQUÉ le jour même** par l'entrée
    ci-dessus. C'est précisément ce que le propriétaire a refusé : le Plan, les priorités et
    les compétences **continuent** de voir les observations d'entraînement EE/EO. Seul
    l'affichage d'un niveau global sur l'Accueil exige une épreuve complète.
  - ⚠️ **Le coût a dû être retenu.** Le profil évaluait, dans cette première passe, toutes les
    épreuves complètes d'un candidat à chaque lecture d'Accueil **et de Plan**. La version
    naïve (une requête par session, une par soumission, un lazy-load de tâche par soumission)
    coûtait **+14 requêtes** sur le budget du Plan et **grandissait avec l'historique** — le
    test d'égalité `LearningPlanCycleIT.leCoutDuPlanNeGrandiPasAvecLHistorique` l'a attrapé
    immédiatement, ce pour quoi il existe. Corrigé en lots : `findByAttemptIdsWithTask`
    (`JOIN FETCH` sur la tâche) et `findLatestBySubmissionIds`. Coût final **3 requêtes par
    épreuve, constant**. 🛑 **Le budget du Plan était passé à 27 ; il est revenu à 23** avec
    le revert de périmètre — le Plan ne lit plus ces épreuves du tout. Les deux requêtes en
    lot, elles, **restent** : elles servent l'Accueil et « Voir mes résultats ».
  - **Verrouillé par** : `TcfProfileServiceIT` (le compte constaté, les 3 cas positifs,
    l'agrégat, le maximum entre examens, le repli baseline),
    `EpreuvesProductionQualifiantesResolverTest` (le lot unique, le `null` non servi),
    `TcfProfileServiceTest` (anti-yoyo intact). `TestData.epreuveProductionPassee` est la
    fixture partagée : les tests du Plan la réutilisent au lieu de recopier une production
    d'entraînement.

- **LE DIAGNOSTIC COMPTE DÉSORMAIS DANS LE PROFIL TCF — inversion de la décision V049**
  (2026-09-16). `AttemptRepository.findQcmEpreuvesPassees` portait `AND a.tcfDiagnostic IS
  NULL` depuis le commit `c675ad5c` (2026-09-10). Le filtre est **retiré**.
  - **Pourquoi la règle avait raison le 2026-09-10.** Son motif écrit, verbatim : « le niveau
    estimé se lit sur un score calibré 100-499 **établi sur 25 items**, quand une section de
    diagnostic en compte **15** ». C'était exact et c'était la bonne décision : les deux
    mesures ne mesuraient pas la même chose, et `TcfProfileService` prend le **meilleur**
    résultat par épreuve — une section courte, plus facile à réussir, aurait tiré le profil
    vers le haut sans preuve comparable derrière. Le filtre était au surplus cohérent avec la
    discipline générale de `tcf_diagnostic_id` (7 requêtes le portaient).
  - **Pourquoi elle a cessé d'avoir raison le 2026-09-13.** Le commit `dd06334e` a appliqué
    l'arbitrage du propriétaire — « chaque épreuve du diagnostic complet se lance comme un
    examen blanc complet de l'épreuve ». `TcfDiagnosticSectionStarter.creerComprehension`
    appelle depuis lors le **même `composeModuleExam`** qu'un examen de module :
    **25 items (8 A2 / 9 B1 / 8 B2), même tirage, même durée pleine**.
    `composeDiagnosticComprehension` et `dureeReduite` ont été supprimées dans la même passe.
    La prémisse de V049 — « 15 items contre 25 » — **n'existe plus**. Ce qui restait n'était
    pas une règle mais son ombre : une CE de diagnostic était, ligne pour ligne, la même
    mesure qu'une CE passée seule, et elle était la seule que beaucoup de comptes de test
    avaient.
  - **Ce qui change.** Une sous-épreuve CE/CO de diagnostic complet compte dans
    `TcfProfileService.levelProfile` exactement comme une épreuve passée seule ou dans un
    examen blanc. **Aucun traitement différent selon la provenance de l'attempt** — c'est la
    règle métier, pas un effet de bord. `bestQcm` retenant un **maximum**, aucun double
    comptage n'en découle : une même épreuve mesurée deux fois n'est comptée qu'une, à sa
    meilleure valeur. Verrouillé par `AttemptManagerIT
    .findQcmEpreuvesPassees_includesTcfDiagnosticSubAttempts`.
  - 🛑 **La levée est bornée à CETTE requête.** Les six autres porteuses de
    `tcf_diagnostic_id` — grille des 20 slots, catalogues, historiques, statistiques, quotas,
    freebie EE/EO — la gardent : leur motif à elles n'a jamais été la comparabilité des
    scores. `TcfDiagnosticServiceIT` continue de les verrouiller.
  - **Non touché** : `AND a.civicDiagnostic IS NULL` (un diagnostic civique n'est pas une
    épreuve TCF) et l'`EXISTS` sur `answers` — une section de diagnostic ouverte puis
    abandonnée sans une seule réponse reste hors du profil, et c'est verrouillé aussi.
  - **Autorisation** : le propriétaire a explicitement permis de casser la compatibilité avec
    les anciens diagnostics de test, cette partie du produit n'ayant jamais été en production.
    Les 12 sous-attempts de diagnostic locaux datent d'avant le 2026-09-13 (15 items) ; tous
    portent **zéro réponse**, donc aucun n'entre dans le profil — le changement n'a aucun
    effet rétroactif sur les données existantes.

- **UNE QUESTION NON RÉPONDUE N'EST PAS UNE RÉPONSE FAUSSE** (2026-09-16). Mesuré en base
  locale : sur **31** observations `learning_plan_observations` de source `TCF_CO`/`TCF_CE`,
  **25 provenaient de sessions à zéro réponse** — dont la session CO `713cbf9f` du compte
  `070f4564` (`wewiwe4789@bowlfuel.com`), 25 questions posées, aucune répondue, qui avait
  produit trois `PRIORITY` à « 0 / 8 », « 0 / 9 » et « 0 / 8 bonnes réponses ». Des fragilités
  qui n'ont jamais été observées.
  - **Cause** : `AttemptInteractionService.recordComprehension` construisait
    `ReponseComprehension(…, correct = aq.getAnswer() != null && …)`. Une question sans réponse
    y arrivait **indiscernable** d'une réponse fausse, et `ComprehensionObservationService` la
    comptait au dénominateur comme au numérateur. Le moteur V4.2 (`ReceptiveEvidenceAdapter
    .ReponseQcm`) portait déjà un champ `answered` pour ce cas exact ; le producteur du Plan
    ne l'avait pas.
  - **Décision** : `ReponseComprehension` porte `answered`, et la ventilation écarte toute
    question non répondue — **ni numérateur, ni dénominateur, ni `min-questions`**. Une
    épreuve terminée sans aucune réponse n'écrit donc **aucune** observation : ni `PRIORITY`
    (fausse fragilité), ni `NOT_OBSERVED` (faux « données insuffisantes »). Pour la mesure de
    compétence, elle n'a pas eu lieu. **L'attempt, lui, est conservé** : on cesse d'en tirer
    une mesure, on n'efface pas l'historique du candidat.
  - ⚠️ **Sans effet sur le résultat d'UN examen**, où une épreuve abandonnée reste comptée
    `A1_NON_ATTEINT` (`FullTcfExamResponseBuilder`) : c'est le résultat de cet examen-là, pas
    le profil du candidat dans le temps. Même partage que l'`EXISTS` de
    `findQcmEpreuvesPassees`, posé pour la même raison.
  - ⚠️ **Non touché, et volontairement** : `ReceptiveEvidenceAdapter` (moteur V4.2, shadow
    mode) compte toujours les non répondues comme fausses sur une session close par le chrono
    — c'est sa doctrine §23.4 écrite (« une session close par le chrono reste qualifiante :
    c'est un examen, pas un entraînement, et le candidat le savait en le lançant »). Point
    signalé, pas arbitré ici.
  - **Nettoyage local** (`sejourfr_db` dev, autorisé par le propriétaire) : les **25** lignes
    `learning_plan_observations` dont l'attempt source ne porte aucune réponse ont été
    supprimées — comptes `wewiwe4789@bowlfuel.com` (9), `user@sejourfr.fr` (8),
    `billodiallo@gmail.com` (5), `billo12@gmail.com` (3). Les **6** lignes restantes
    (`billodiallo@gmail.com` et `billodiallo2@gmail.com`, deux sessions à 25/25) ont été
    vérifiées ligne à ligne contre les réponses réelles : elles sont exactes. Aucun attempt
    supprimé.

- **UNE COMPRÉHENSION « PAS ASSEZ MESURÉE » N'EST PAS UNE MESURE RATÉE** (2026-09-16).
  `PlanDomainAssessmentResolver.indispensable` — qui sert la carte « à compléter » en tête de
  séance — traitait tout domaine « tenté mais sans aucune observation probante » comme une
  **production inutilisable à réévaluer**. Ce sens-là est légitime pour EO/EE (une production
  rendue dont le correcteur n'a rien pu observer, cf. l'entrée V040 plus bas), mais
  `ComprehensionObservationService` écrit `NOT_OBSERVED` pour une **troisième** raison :
  moins de `comprehension.min-questions` (6) réponses sur ce palier.
  - **Décision** : `indispensable` ne retient que les sections de **production**
    (`section.isProduction()`). Une épreuve CE/CO terminée dont un palier manque de preuve
    n'est **jamais** proposée à repasser — `NOT_OBSERVED` dit « pas assez de preuve », pas
    « échec ».
  - **Les trois états, qui ne se confondent plus** : (1) épreuve **jamais réalisée** ⇒ la
    mesurer (`resolve` / `PlanAcquisitionSelector`) ; (2) réalisée mais **données
    insuffisantes** sur ce palier ⇒ **rien**, ni carte ni invitation ; (3) **fragilité
    réellement observée** ⇒ une priorité ordinaire. L'enum `LearningPlanSkillStatus` suffit à
    les porter une fois ces bugs corrigés — `NOT_OBSERVED` + `observed = false` pour (2), et
    (1) n'a **aucune** ligne d'observation du tout. **Aucun statut nouveau n'a été créé** :
    en ajouter un aurait dupliqué un sens existant.
  - **Verrouillé** par `PlanDomainAssessmentResolverTest` (production `NOT_OBSERVED` toujours
    retenue — non-régression du cas fondateur ; compréhension `NOT_OBSERVED` jamais retenue ;
    une CO non observée n'éclipse pas l'EO ratée qui, elle, compte).

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
