# Journal — versions des grilles de notation (v4 → v15)

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Journal daté, verbatim et intégral.**
> Origine : lignes 1916-2033, 2164-2321 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier consigne les arbitrages et révocations : on l'ouvre **avant de changer une règle**, pas pour l'appliquer.
> Fichier jumeau : `docs/regles/notation-ia.md`
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

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
