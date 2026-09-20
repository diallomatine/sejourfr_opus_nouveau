# QCM — niveau, score et ordre des propositions

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Contenu verbatim, aucune réécriture.**
> Origine : lignes 3039-3176 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier porte la loi de ce sous-système : on l'ouvre **quand on travaille dedans**.
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

## Niveau QCM — le plus haut palier MAÎTRISÉ, sans saut (2026-09-20)

🛑 **Cette section REMPLACE intégralement « Niveau QCM — plancher A1 dès UNE bonne
réponse (2026-08-17) »**, révoquée ci-dessous avec son motif.

### La règle

Sur les trois épreuves QCM (**CO**, **CE**, **STRUCTURE**), le niveau rendu est **le plus
haut palier tel que TOUS les paliers inférieurs sont également maîtrisés**.

- Une **strate** est l'ensemble des items d'un même palier CECRL posés dans l'épreuve.
- Une strate est **maîtrisée** à **60 % de ses items, arrondis à l'entier SUPÉRIEUR**.
- 🛑 **Pas de saut de palier** : si l'A2 n'est pas tenu, le résultat est `A1`, **même si le
  B1 ou le B2 passe**. La monotonie est la règle, pas une précaution.
- **Zéro bonne réponse sur l'épreuve entière** ⇒ `A1_NON_ATTEINT`.
- **Au moins une bonne réponse, aucune strate maîtrisée** ⇒ `A1`. **`A1` est donc le
  plancher réel** du dispositif ; `A1_NON_ATTEINT` est devenu un cas quasi théorique.
- **Aucun item de palier CECRL posé** ⇒ `null`. *Inconnu, jamais mauvais.*

Sur la composition d'un examen (**10 A2 / 8 B1 / 7 B2**, cf. plus bas), les seuils sont :

| strate | items | seuil | P(strate maîtrisée en cliquant au hasard, QCM à 4 choix) |
|---|---|---|---|
| A2 | 10 | **6/10** | 1,97 % |
| B1 | 8  | **5/8**  | 2,73 % |
| B2 | 7  | **5/7**  | 1,29 % |

**Pourquoi 60 %, et pas 50 ni 70.** Décision du propriétaire, prise sur la probabilité de
décrocher un palier **au hasard** — parce qu'un niveau affiché pousse quelqu'un à
s'inscrire au vrai TCF, **qui est payant**. À 5/10 (50 %) un débutant qui clique au hasard
décroche A2 **une fois sur treize** (7,5 %). À 6/10, une fois sur cinquante. À 70 %, il
fallait la quasi-perfection (0,35 %), ce qui refermait le problème inverse.

⚠️ **L'arrondi supérieur crée une inégalité ASSUMÉE entre strates.** 5/8 = 62,5 % exigés en
B1, mais 5/7 = **71,4 %** exigés en B2, contre 60,0 % pile en A2. C'est le prix de
l'arithmétique entière sur des strates de tailles différentes, et le sens de l'écart est le
bon : c'est le palier **le plus haut** qui est le plus exigeant. Ne pas « corriger » en
arrondissant à l'inférieur — 4/7 = 57 % passerait sous la barre voulue.

🛑 **Distinguer « 0 bonne réponse » de « 0 réponse donnée ».** Ce sont deux situations
différentes :

- **0 bonne réponse** : le candidat a répondu, tout est faux. `A1_NON_ATTEINT` y est un
  verdict de langue.
- **0 réponse donnée** : la session a été ouverte puis **abandonnée**. Ce n'est pas un
  verdict, c'est une absence de mesure.

**Les deux rendent aujourd'hui `A1_NON_ATTEINT`** — c'est le comportement d'avant, conservé
tel quel, **et ce n'est pas arbitré**. La donnée, elle, ne les confond plus : `StrateQcm`
porte `repondus` à côté de `poses` et de `reussis`, et la branche est écrite séparément
dans `TcfLevelEstimatorService.niveauParStrates`. Le jour où le premier cas doit devenir
`null`, il y a **un seul endroit** à changer. ⚠️ **Mesuré sur la base locale le
2026-09-20 : sur 81 épreuves CO/CE terminées, 38 valent `A1_NON_ATTEINT`, dont 36 par
abandon total (aucune réponse) et 2 seulement par « tout faux ».** La population
`A1_NON_ATTEINT` est donc, en pratique, celle des abandons.

### Ce que cette règle répare, et pourquoi l'ancienne est révoquée

L'ancien niveau venait d'un **score pondéré** (A2=1, B1=2, B2=3) corrigé du hasard à 25 %,
puis d'une **bande** (≥400 B2 · ≥300 B1 · ≥200 A2 · ≥101 A1).

🛑 **La bande A2 était inatteignable par un candidat A2.** Sur l'examen stratifié
8 A2 / 9 B1 / 8 B2 d'alors, la strate A2 ne pesait que 8/50 = **16 %** du pondéré, donc
**sous la ligne de hasard de 25 %** : maîtriser tout l'A2 et rien d'autre donnait
**100/499**, c'est-à-dire « A1 non atteint ». Pour être classé A2 il fallait toute la
strate A2 **plus 7 B1 sur 9** — c'est-à-dire être B1. Mesuré : B1 et B2 sortaient juste,
**seule la bande A2 était morte**.

Le **plancher A1 du 2026-08-17** (`plancherA1SiUneBonneReponse`) traitait le symptôme : il
relevait `A1_NON_ATTEINT` à `A1` dès une bonne réponse. **Il est supprimé** — la méthode et
ses trois appels — parce que le modèle par strate rend déjà `A1` à qui a au moins une bonne
réponse sans strate maîtrisée. Le garde-fou n'a plus d'objet, et c'était le seul du dépôt
qui **relevait**.

### Dérivation À LA LECTURE — la colonne a été supprimée

🛑 **`attempts.cecrl_level` n'est plus écrit, plus lu, et n'existe plus** (migration
`00_schema/V879__drop_attempts_cecrl_level.sql`). Le niveau est une **fonction pure des
réponses**.

- C'est la doctrine du dépôt : *un dérivé se relit, il ne se persiste pas*. Une colonne qui
  porte un verdict fige l'historique sous la règle du jour où elle a été écrite — c'est
  exactement ce qui aurait obligé à une migration de recalcul pour réparer la bande A2.
- Conséquence voulue : **un changement de règle relit tout l'historique, sans migration**.
- ⚠️ Le repli legacy `FullTcfExamResponseBuilder.weightedScoreToCecrl` (seconde table
  80/60/40/20 % du pondéré brut, pour les sous-attempts antérieurs à V416) **est supprimé
  lui aussi** : leurs réponses sont en base comme les autres.
- ⚠️ **Numéro de migration hors de sa plage, et c'est voulu** : `V112__reset_tcf_cecrl_levels`
  ÉCRIT dans cette colonne. Flyway ordonne par **numéro**, pas par dossier : un drop
  numéroté en V0xx s'exécuterait avant elle et ferait échouer toute base neuve. D'où
  **V879** — après tout le contenu (max V878), avant le seed dev (V900).

🛑 **Attention au N+1 sur les écrans de LISTE.** Historique, profil TCF, « Voir mes
résultats », liste des examens blancs, bilan d'examen complet : **une seule requête agrégée
pour toutes les tentatives de la page**, jamais une boucle.

- La requête unique : `AttemptQuestionRepository.aggregateStratesByAttempts`, servie par
  `AttemptQuestionManager.stratesParAttempt`.
- La forme à appeler : `TcfLevelEstimatorService.niveauxQcm(Collection<UUID>)`. La forme
  unitaire `niveauEpreuveQcm(Attempt)` existe, mais **une boucle dessus est un N+1**.
- Verrouillé par `NiveauQcmDeriveSansNPlusUnIT`, qui compte les requêtes **à l'ÉGALITÉ** et
  vérifie que le compte **ne bouge pas** entre 1 et 6 tentatives. Un `<=` laisserait passer
  précisément ce qu'on interdit. Le budget global du Plan (`LearningPlanCycleIT`) passe de
  21 à **23** : deux requêtes agrégées, une par épreuve de compréhension, constantes.

### Autorité unique

🛑 **`TcfLevelEstimatorService` est le seul endroit du dépôt qui calcule un niveau QCM.**
`AttemptScoringService`, `AttemptMapper`, `TcfProfileService`, `NiveauActuelEpreuveResolver`,
`EpreuveHistoriqueService` et `FullTcfExamResponseBuilder` en héritent **sans une ligne de
règle**.

- `AttemptScoringService.computeLevelAchieved` portait un **second seuil** (60 % par strate,
  sans monotonie) pour l'entraînement TCF libre : il **délègue** désormais.
- `AttemptMapper` ne fait **aucune lookup** (c'est un mapper) : son appelant lui passe le
  niveau, calculé pour toute la page.

### Le score 100-499 est un SCORE DE PROGRESSION

🛑 **Il n'est plus présenté comme un score TCF, et plus aucun niveau n'en dérive.** Le vrai
relevé du TCF IRN a une échelle officielle que nous n'avons pas.

- La **formule** ne bouge pas : `100 + max(0, (ratio − 0,25) / 0,75) × 399`, arrondie.
  Hasard pur → 100 ; sans-faute → 499. Les valeurs **100 / 233 / 499** restent gelées par
  test.
- Ce qui **disparaît** : toute conversion « score → palier ». Les frontières **43/44,
  62/63, 81/82** et la méthode `niveauDepuisScoreCalibre` n'existent plus — elles
  délimitaient des bandes, et il n'y a plus de bande. `TcfLevelEstimatorServiceTest` en fait
  une **assertion de structure** : aucune méthode publique ne prend un entier et ne rend un
  `NiveauCecrl`.
- **Aucune seconde échelle n'est créée.** Les fronts renomment seulement le libellé :
  `scoreProgressionLabel` (`web_sejoufr/lib/exam-levels.ts`) ⇄ `scoreProgressionLabel`
  (`mobile_sejourfr/lib/core/models/full_tcf_exam.dart`), et « Score TCF » devient « Score
  de progression ».
- ⚠️ **Le score et le palier ne disent pas la même chose, et c'est voulu** : un candidat qui
  maîtrise tout l'A2 et rien d'autre est **A2** avec un score de **100/499** — 10 points
  pondérés sur 47, donc sous la ligne du hasard. Le palier dit *où il en est*, le score dit
  *combien il lui reste*.

### Composition d'un examen d'épreuve : 10 A2 / 8 B1 / 7 B2

**25 questions**, inchangé. `AttemptCompositionService.MODULE_EXAM_A2/B1/B2`.

- La granularité recherchée **ne concerne que l'A2** : 10 items donnent un seuil à
  **6/10 = 60 % pile**, contre 5/8 = 62,5 % sur l'ancienne strate de 8. Un item A2 vaut un
  dixième au lieu d'un huitième, donc le palier est moins sensible à une seule erreur.
- 🛑 **`DureeEpreuve` n'est PAS touché.** Les 20 min de la CO sont perçues comme fidèles au
  vrai examen ; le total reste 25 questions, donc la durée n'a aucune raison de bouger.
- Profondeur de pool vérifiée avant bascule (base locale, items actifs) :
  **CO** A2 134 / B1 214 / B2 212 · **CE** A2 206 / B1 205 / B2 205. Aucune strate n'est
  contrainte.
- Le score pondéré maximal passe de 50 à **47** (10×1 + 8×2 + 7×3). Sans effet sur le score
  de progression, qui est un **ratio** normalisé.
- ⚠️ La composition du **diagnostic** reste à répartition ÉGALE (`composeDiagnosticComprehension`,
  8/8/8) là où elle est encore utilisée : son calcul de niveau lit un taux par palier, et un
  palier sous-doté rendrait ce taux trop sensible.

### Le niveau ACTUEL affiché moyenne des ITEMS, pas des labels

`NiveauActuelEpreuveResolver.mesureQcm` (Accueil, Profil) retient les **3 derniers examens
qualifiants** et **cumule leurs strates**, puis relit le palier chez l'autorité unique.

- On ne moyenne ni des labels (« la moyenne de A2 et B2 » n'a pas de sens), ni des scores
  (il n'existe plus de table score → palier).
- ⚠️ **Conséquence assumée** : le palier affiché est plus **inerte** qu'une moyenne de
  scores. Sur trois examens cumulés, **un seul mauvais n'efface pas deux sans-faute** ; il
  faut une tendance, pas un accident. La révocation du maximum monotone (2026-09-16) tient
  toujours : un historique récent dégradé **fait** redescendre le palier.

### Impact mesuré de la bascule

Base locale, 2026-09-20, **81 épreuves CO/CE terminées et stratifiées** (examens de module,
sous-épreuves d'examen blanc complet et sections de diagnostic complet) :

| répartition APRÈS | A1_NON_ATTEINT | A1 | A2 | B1 | B2 |
|---|---|---|---|---|---|
| tentatives | 38 | 35 | 3 | 3 | 2 |

**54 tentatives ne changent pas de niveau, 27 changent** : 18 montent de `A1_NON_ATTEINT` à
`A1`, 2 de `A1` à `A2`, 1 de `A2` à `B1`, **3 descendent de `A2` à `A1`**, et 3 passent
d'« inconnu » à `A1` (elles n'avaient ni niveau persisté ni score pondéré, et sont
désormais lisibles sur leurs réponses).

🛑 **Les 3 descentes sont le défaut qu'on répare, pas un dommage** : ce sont des candidats
à **1/8 ou 4/16** items A2 réussis que l'ancienne formule classait A2, parce que leurs
bonnes réponses en B2 pesaient 3 points chacune. Le nouveau modèle refuse de leur
attribuer un palier qu'ils n'ont pas démontré.

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

---

## Une série d'étape est un QCM qui NE CORRIGE PAS pendant la passation (2026-09-20)

> Règle complète : `docs/regles/plan.md` § « **L'ÉCRAN D'ÉTAPE** ».

Le niveau QCM, le score 100-499 et l'ordre des propositions **ne bougent pas**. Ce qui change
est le **régime de passation** d'un type de session, et il est désormais **servi**.

🛑 **`AttemptResponse.mode` (`AttemptMode`) dit si le candidat voit les corrections pendant
qu'il joue** — jamais `type`, jamais une route, jamais un paramètre d'URL.

| `mode` | Pendant la session | Audio (CO) |
|---|---|---|
| `ENTRAINEMENT` | correction immédiate après chaque réponse | réécoutable |
| `EXAMEN` | **aucune** correction : ni bonne réponse, ni explication | **joué une seule fois** |
| `REVISION` | aucune correction | réécoutable |

Une **série lancée depuis une carte d'étape du Plan** reste un `AttemptType.TRAINING` — pour ne
rien changer au freemium ni à l'historique — posée en `EXAMEN`. Le comportement de toutes les
autres sessions est **inchangé** (`TRAINING→ENTRAINEMENT`, `MOCK_EXAM→EXAMEN`,
`REVIEW→REVISION`, dérivés par `Attempt.prePersist`).

🛑 **Le serveur oppose la même valeur** : `AttemptInteractionService.doSubmitAnswer` ne renvoie
la correction (bonne réponse + explication) qu'en `ENTRAINEMENT`. L'écran et le refus ne peuvent
pas diverger.

⚠️ **Le résultat corrigé reste consultable APRÈS coup** : `GET /api/attempts/{id}` révèle les
corrections dès que la session est terminée, exactement comme pour une série de « Réviser ».

### Le « 16/20 » d'une série n'est pas un verdict de niveau

Le seuil de réussite d'une série d'étape est **16 bonnes réponses sur 20**, lues sur l'attempt
(`JourneySerieVerdict`). 🛑 Il se **dérive** de `learning-plan.comprehension.solid-ratio` × la
taille de la série — **aucune huitième déclaration de 0,80**, et **aucun palier CECRL** n'en
sort : c'est un seuil de **progression du Plan**, pas une mesure de niveau. Le niveau, lui,
continue de se lire strate par strate (§ ci-dessus).
