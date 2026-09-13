# Diagnostic TCF — 4 épreuves (lot L4)

> Règle du sous-système, lue **à la demande**. Spec d'origine :
> `docs/review_all/10_SEJOURFR_TCF.md` §4 et `30_SEJOURFR_ECRANS.md` §5,
> corrigées par `50_SEJOURFR_CORRECTIFS.md`.
> Fichier voisin, à ne pas confondre : `docs/regles/diagnostic.md` — le
> diagnostic **initial** (une production écrite + une orale).

---

## Ce que c'est, et ce que ce n'est pas

🛑 **Ce n'est pas un examen blanc, et le nom compte.** `10_` §4.1 l'interdit
explicitement : « Nommage imposé : *Diagnostic TCF — 4 épreuves*. Interdit
d'appeler cela un examen blanc. » Les deux objets coexistent :

| | Diagnostic TCF | Examen blanc complet |
|---|---|---|
| But | identifier quoi travailler, construire le Plan | se mettre en situation réelle |
| Compréhension | 24 items (8 A2 / 8 B1 / 8 B2), CO ≈ 19 min · CE ≈ 34 min | format réel, 25 items (8/9/8), CO 20 min · CE 35 min |
| Production | **les 3 tâches**, jamais réduites | les 3 tâches |
| EE / EO | **totalement offertes**, aucun quota consommé | 1 examen offert, puis Premium |
| EO tâches 1 et 2 | **pas en conditions réelles** | conditions réelles |
| Accès | 1 offert, puis réévaluation Premium tous les 14 j | slot 1 offert, 2-20 Premium |
| Grille des 20 slots | **jamais** | oui |

**On ne réduit que la compréhension, jamais la production** (arbitrage A2). Le
Plan raisonne par tâche : afficher « EO tâche 2 est votre priorité » sans avoir
évalué EO2 rendrait la personnalisation fictive.

🛑 **UNE SECTION EST UN EXAMEN BLANC DE SON ÉPREUVE (2026-09-13).** Arbitrage du
propriétaire, verbatim : « le diagnostic complet, chaque épreuve se lance comme
un examen blanc complet de l'épreuve ; tu peux d'ailleurs y prendre l'examen
blanc 1, même si on n'affiche pas "examen 1" ». Conséquences, toutes dans la
même passe :

- **Compréhension : `composeModuleExam`**, plus `composeDiagnosticComprehension`
  — les mêmes **25 items (8/9/8)** et le **même tirage** qu'un examen de module.
- **Durée PLEINE** (`DureeEpreuve.secondesPourQcm`), plus de prorata :
  `TcfDiagnosticSectionStarter.dureeReduite` est **supprimée**.
- **`items-per-level` a disparu** de `application.yaml` et du POJO, et avec elle
  `TcfDiagnosticLevelResolver.repartitionAttendue` (qui n'avait aucun appelant).
- **`config-version` passe à 3** : le sens d'un niveau change encore.

⚠️ **Ce que cela révoque**, et qui ne doit pas être réintroduit « par
cohérence » : la répartition **égale** 8/8/8 et l'**absence de repli hors
palier**, les deux spécificités de `composeDiagnosticComprehension`. Le calcul de
niveau n'en souffre pas — il lit un **taux par palier** et ajuste ses
dénominateurs sur ce qui a réellement été posé (mode dégradé `10_` §9), donc un
palier à 9 items se lit aussi bien qu'un palier à 8, et une question ajoutée par
le repli compte dans le palier qu'elle porte.

⚠️ **Historique** : `items-per-level` était passé de 5 à 8 le matin même
(24 items, chrono au prorata) — étape intermédiaire, remplacée le jour même.

⚠️ **Ce qui n'a PAS été touché, et reste à arbitrer** : le niveau TCF estimé
**exclut toujours les diagnostics**. Son motif écrit (« un score calibré établi
sur 25 items, quand une section de diagnostic en compte 15 ») ne tient plus tout
à fait à 24 items — mais l'exclusion tient aussi par le filtre
`tcf_diagnostic_id`, qui garde le diagnostic hors des grilles et des
statistiques. On ne l'ouvre pas en passant.

## La mécanique est celle de l'examen complet, pas une seconde

Parent `TCF_COMPLET` + 4 sous-attempts, un chrono par épreuve, clôture
paresseuse à la lecture, productions branchées sur
`/api/production-submissions`. **Rien n'a été dupliqué** : la reconstruire en
parallèle aurait donné deux implémentations du même parcours, qui divergeraient
(`50_` §2 — l'existant a raison par défaut).

🛑 **D'où `attempts.tcf_diagnostic_id`, et il se filtre PARTOUT.** Même
discipline que `production_tasks.diagnostic_code` : tous les catalogues,
grilles, historiques, statistiques et quotas gardent `tcf_diagnostic_id IS NULL`.
Sans ce filtre, un diagnostic occuperait un slot de la grille des 20 examens
blancs et compterait dans « examens blancs passés ». **Sept** requêtes le portent
depuis le 2026-09-13 (la 7ᵉ est le freebie EE/EO de l'examen complet, cf. la
boucle de réévaluation plus bas), et `TcfDiagnosticServiceIT` les verrouille.

Deux décisions d'exclusion, écrites parce qu'elles ne se devinent pas :

- **le niveau TCF estimé EXCLUT les diagnostics** — il se lit sur un score
  calibré 100-499 établi sur 25 items, quand une section de diagnostic en compte
  24 ; l'exclusion tient d'abord au filtre `tcf_diagnostic_id`, qui garde le
  diagnostic hors des grilles et des statistiques. ⚠️ Son motif d'origine (« 25
  items contre 15 ») s'est affaibli le 2026-09-13 — cf. l'encart en tête de
  fichier, c'est un point à arbitrer, pas à ouvrir en passant ;
- **la série de jours consécutifs les COMPTE** — passer une section de
  diagnostic est un jour de travail.

## Une section rend SON résultat, et son rapport

🛑 **Arbitrage du propriétaire (2026-09-13)**, verbatim : « si on finit par
exemple CO ou CE, on peut tout de suite voir le résultat affiché dessus, et il
peut consulter le rapport comme un examen ».

⚠️ **Cela RÉVOQUE `10_` §4.2** (« aucun résultat détaillé n'est affiché avant la
fin — le résultat est le moment de conversion, il ne doit pas être dilué »).
Ne pas le réintroduire au motif qu'il est encore écrit dans la spec : ce qui
suit fait foi.

- **`TcfDiagnosticSectionDto` porte `niveau`, `scoreCalibre` et
  `analyseEnCours`.** Le niveau était **déjà calculé** par
  `TcfDiagnosticReadService` — il était simplement retenu à la frontière du DTO.
- **`scoreCalibre` est le /499 des examens de module**, lu chez son autorité
  (`AttemptMapper.calibratedScoreOf`, rendue publique pour l'occasion) : le
  recalculer aurait fait exister un second « /499 » dans le dépôt. Compréhension
  **close** seulement ; `null` en production, qui n'a pas de score.
- 🛑 **`analyseEnCours` distingue « on attend l'IA » de « rien
  d'exploitable »** — deux états qui donnent tous deux `niveau == null` et que
  l'écran ne doit pas confondre. *null = inconnu, jamais mauvais.*
- **Le rapport est CELUI D'UN EXAMEN**, aucun écran n'est créé : compréhension ⇒
  le rapport question par question (`/exam-report/:attemptId` ⇄ `/sessions/:id`),
  production ⇒ le bilan de session. Côté web, `sectionRapportHref` est
  exactement `sectionHref` **sans le marqueur de section** — le marqueur ne sert
  qu'au retour pendant la passation.

🛑 **CE QUI RESTE LE MOMENT DE CONVERSION, et n'apparaît pas sur une carte de
section** : le **niveau global** (plancher des quatre), les **priorités** et le
plan. Ils vivent sur `TcfDiagnosticResultDto` et nulle part ailleurs. Une
épreuve rend le sien, rien de plus.

## Quitter une épreuve, c'est la terminer

Même règle qu'un examen blanc (arbitrage du propriétaire, 2026-09-13) : « pour
les épreuves, c'est toute l'épreuve qui est chronométrée ; l'abandonner, c'est
fini, si elle est déjà commencée ». Une section **jamais ouverte** n'est jamais
fermée par un geste de sortie — elle attend le candidat aussi longtemps qu'il
faut.

- **L'autorité est `TcfDiagnosticSectionStarter.cloreSection`**
  (`POST /api/tcf-diagnostics/{id}/sections/{epreuve}/close`), idempotente, et
  elle ne ferme que ce qui porte un `timerStartedAt`.
- 🛑 **L'EXPRESSION ORALE EST LA SEULE EXCEPTION**, et elle tient à son chrono :
  l'EO se chronomètre **par tâche**, donc quitter n'y termine que la **tâche en
  cours** — le candidat rouvre l'épreuve et **reprend à la suivante**. La clore
  lui ferait perdre les tâches qu'il n'a pas encore rendues.
  - Côté mobile, `EoSessionNotifier.startInFullExam` relit les **tâches déjà
    rendues** (best-effort, une requête à l'entrée de l'épreuve) et
    `_reprendreALaTacheSuivante` saute celles qui sont soumises. Sans ce relevé,
    on revenait toujours sur la tâche 1 et le serveur la refusait — une tâche ne
    se soumet qu'une fois par session. Côté web, `enterTask(nextTodo)` le faisait
    déjà.
  - Le message de sortie le **dit** (`TCF_DIAGNOSTIC_EO_QUIT_MESSAGE` ⇄
    `kTcfDiagnosticEoQuitMessage`), sinon le candidat croit tout perdre et ne
    revient pas.

## ⚠️ L'exception EO1/EO2 « hors conditions d'examen » est RÉVOQUÉE

Le 2026-09-13 au matin, `ProductionExamConditions` relâchait les conditions
d'examen sur **EO1 et EO2 d'un diagnostic** (réécoute, refaire, envoi quand on
veut). Le propriétaire l'a révoquée le jour même : « comme à l'examen, sauf que
l'EO, chaque tâche a son propre chrono ; une fois commencée on ne l'arrête pas,
et si on l'arrête, cette tâche est considérée comme finie ».

**Supprimés** : `ProductionExamConditions`, son test,
`ProductionTaskDto.conditionsReelles` et ses trois miroirs front, la note
`PRODUCTION_HORS_CONDITIONS_NOTE` ⇄ `kProductionHorsConditionsNote` et la classe
CSS `.horsConditions`. Un champ qui ne peut plus valoir qu'une seule chose ne
voyage pas.

🛑 **Un effet de bord à connaître** : ce champ servait aussi de discriminant
pour **ne pas proposer l'examinateur vocal** sur les tâches du diagnostic. Le
discriminant est désormais le **marqueur de section** (`tcfDiagnosticId`), et
c'est plus juste : le quota du temps réel ne doit pas dépendre d'une règle de
chrono. Règle confirmée par le propriétaire — « en freemium, le diagnostic est
offert et l'IA analyse, par contre c'est juste en enregistrement normal, pas
avec l'examinateur en temps réel ».

## Aucune table de section, aucune table de résultat

`10_` §11 propose `tcf_diagnostic_section` et `tcf_diagnostic_result`. **Elles
n'existent pas.** L'état d'une section EST celui de son sous-attempt, et le
niveau se recalcule à la lecture depuis les réponses (compréhension) ou les
évaluations (production). Les persister violerait « dérivé serveur ⇒ jamais
persisté » et figerait un résultat qu'un recalibrage devrait pouvoir revoir.

Seule exception, déjà en place pour l'examen complet : le niveau global est
recopié sur `attempts.final_cecrl_level` à la clôture — **cache de lecture**,
jamais la source.

## Le calcul du niveau

**Compréhension**, déterministe, taux **par palier** (jamais sur le total) :

```
B2  si taux(A2) ≥ 0,80  et  taux(B1) ≥ 0,70  et  taux(B2) ≥ 0,60
B1  si taux(A2) ≥ 0,80  et  taux(B1) ≥ 0,60
A2  si taux(A2) ≥ 0,60
A1  sinon
```

Un palier supérieur exige de tenir **aussi** les paliers inférieurs : réussir le
B2 en échouant l'A2 ne fait pas un B2. Le seuil B1 est **plus sévère** quand on
vise le B2 (0,70) que pour le B1 lui-même (0,60).

**Un palier non posé ajuste son dénominateur** au lieu d'inventer un échec
(mode dégradé `10_` §9) : sans ça, un catalogue sans item B2 plafonnerait à B1
un candidat qui n'a jamais eu d'item B2 à traiter.

**Production** : minimum des 3 tâches — au TCF, une tâche ratée plafonne
l'épreuve. Une tâche non rendue ou **inexploitable** est **absente** du calcul,
elle ne tire pas l'épreuve vers le bas.

**Global** : plancher des épreuves **évaluées** (A7). Les autres sont exclues.

🛑 **`null` = non évaluée, jamais le palier le plus bas.** C'est l'invariant que
V040/V041/V042 ont payé. L'écran doit **nommer** l'épreuve non évaluée
(« Compréhension orale : non évaluée »), pas afficher un A1.

## Les priorités

Score **par tâche**, jamais par compétence (A5) — « Expression orale, tâche 3 »
se comprend, `eo_nuancer` non :

```
score = (3 × gap_tâche + 2 × gap_épreuve + sévérité) × poids_épreuve
sévérité      = 2 × (critères FRAGILE) + 1 × (critères EN_COURS_ACQUISITION)
poids_épreuve = 1,0 si l'épreuve est sous la cible, 0,3 sinon
```

La sévérité est **dérivée des bandes que le correcteur sert déjà**
(`scores_criteres[].bande`), jamais d'une seconde notation. `NON_EVALUABLE` ne
compte pas : une absence de mesure n'est pas une faiblesse.

Trois règles dures :

- 🛑 **une tâche non évaluée ne peut pas devenir une priorité** (test de garde) ;
- 🛑 **une épreuve déjà au niveau cible ne génère aucune priorité** — elle va
  dans « Déjà au niveau attendu » ;
- égalités tranchées **EO > EE > CE > CO**, puis par code de tâche pour que le
  même diagnostic rende toujours le même classement.

Le score **n'est jamais exposé** : c'est un rang de tri interne, et le montrer
inviterait à le comparer d'un diagnostic à l'autre alors qu'il dépend de la
cible du candidat.

## Ce que les écrans ne doivent pas faire

- 🛑 **aucun résultat partiel entre les sections** (`10_` §4.2) — « le résultat
  est le moment de conversion, il ne doit pas être dilué ». `TcfDiagnosticDto`
  ne porte donc aucun niveau ;
- 🛑 **aucun contenu verrouillé sur le résultat** — le paywall porte sur le
  plan, pas sur le constat (`10_` §4.5) ;
- une section commencée se termine **d'une traite** : il n'existe pas de reprise
  à mi-section, et l'écran doit le dire avant de lancer.

## Le délai de reprise n'est pas une péremption

7 jours (configurable). Passé ce délai, les sections réalisées **comptent
toujours** et les autres restent « non évaluée » : le candidat peut demander son
résultat sur ce qui existe. Rien n'est détruit — d'où l'absence d'un état
`EXPIRE`, qui laisserait croire à une perte.

## La boucle de réévaluation (L7)

Trois portes, et **leur nature compte** :

| # | Porte | `locked` ? | Ce qui l'ouvre |
|---|---|:--:|---|
| 1 | Le premier diagnostic | non | rien — il est offert, sans condition |
| 2 | Accès TCF | **oui** | l'achat. C'est la porte commerciale |
| 3 | Délai minimal entre deux passations (14 j) | non | le temps, **ou** une priorité du Plan terminée |

🛑 **EE et EO sont TOTALEMENT offertes dans le diagnostic** (arbitrage du
propriétaire, 2026-09-13) : aucun cadenas, aucun décompte de quota. C'était déjà
le cas pour l'essentiel — un sous-attempt de diagnostic a un parent, donc
`ProductionAccessService.enforceQuota` sort avant tout décompte
(`isExamSession`). **Une fuite restait** et a été fermée :
`ProductionSubmissionRepository.countByUserAndParentEpreuve` ne portait pas
`tcfDiagnostic IS NULL`, si bien qu'une production EE/EO de diagnostic brûlait
le freebie « EE/EO offerts une fois » de l'**examen blanc complet** d'un compte
gratuit. C'est la 7ᵉ requête à porter le filtre, verrouillée par
`TcfDiagnosticServiceIT.productionsDuDiagnosticNeConsommentRien`.

🛑 **Ce qui borne le coût LLM, et qui suffit** : le premier diagnostic est
**unique** (porte 1 + porte 2 : un compte gratuit n'en ouvre jamais un second),
la porte 3 impose 14 jours entre deux, une tâche ne se rend **qu'une fois** par
session (`assertTacheNotAlreadySubmitted`) et la 3ᵉ soumission clôt la section
(`finishSubAttemptIfFullExam`), après quoi `assertNotFinished` refuse. Plafond
réel : **6 évaluations** par diagnostic. Aucun garde-fou nouveau n'a été ajouté.

🛑 **La porte 3 n'est pas un cadenas.** Payer ne l'ouvre pas, et l'écran ne doit
jamais y afficher un CTA d'achat. Sans ce délai, une réévaluation à volonté ne
mesurerait plus une progression — juste le bruit de deux passations rapprochées.

🛑 **La porte 2 ne verrouille jamais le résultat déjà obtenu.** Le paywall porte
sur la nouvelle mesure, jamais sur le constat rendu (`10_` §4.5).

**Le déclencheur produit**, et c'est tout ce que L7 ajoute au moteur : une
**étape franchie** depuis le dernier diagnostic ouvre la porte 3 **avant** son
terme (`10_` §4.6 : « ou déclenchée par le plan quand une priorité est
terminée »). Le candidat qui a réellement fait progresser une compétence
n'attend pas quatorze jours pour le vérifier ; celui qui n'a rien fait attend.
La notion d'étape franchie n'est **pas** redéfinie : elle est lue chez
`LearningPlanPriorityResolver.franchies`, la même que celle qui coche les étapes
du Plan.

**Une seule autorité** : `TcfReassessmentService` sert `GET
/api/tcf-diagnostics/eligibility` **et** garde `POST /api/tcf-diagnostics`. Le
message du refus et celui de l'écran sont le même objet — verrouillé par
`TcfDiagnosticServiceIT.eligibiliteEtRefusSontDaccord`.

**La comparaison** (`TcfDiagnosticProgressionResolver`, pur) accompagne le
résultat d'une réévaluation. Elle rend un sens de variation par épreuve et pour
le palier global.

🛑 **`INCONNUE` n'est pas `STABLE`.** Une épreuve non évaluée d'un côté ou de
l'autre n'est pas comparable : afficher « = » dessus se lirait « vous avez tenu
votre niveau » alors que personne n'a rien mesuré. C'est l'incident
V040/V041/V042 sous un autre déguisement.

🛑 **`BAISSE` existe et se sert.** Masquer une baisse rendrait invendable
exactement ce qu'une réévaluation payante promet de mesurer. La façon de le dire
appartient aux fronts ; le fait appartient au serveur.

## EO tâches 1 et 2 : pas en conditions réelles

🛑 **Arbitrage du propriétaire, 2026-09-13**, verbatim : « la EE et EO sont
totalement gratuits, mais pas en condition réelle pour EO t1 et t2, la personne
s'enregistre et transcription comme d'habitude ».

**Le fait est un DÉRIVÉ SERVEUR**, servi sur
`ProductionTaskDto.conditionsReelles` et calculé par `ProductionExamConditions`
— une autorité, deux lecteurs. Il vivait implicitement dans les fronts (le web
forçait `examMode`, le mobile lisait `isExam`) : deux implémentations de la même
règle, vouées à diverger.

- `null` = **hors session** : le catalogue ne le sert pas, la question n'y a pas
  de sens. Seul `GET /api/attempts/{id}/production-exam-tasks` le renseigne.
- La lecture des fronts est **« conditions d'examen sauf si le serveur dit
  explicitement `false` »** — un client ancien garde exactement son
  comportement, et une erreur ne peut qu'être conservatrice.
- Périmètre : **EO1 et EO2, dans un diagnostic**. EO3 garde les conditions
  d'examen (c'est la tâche la plus proche de l'épreuve réelle, et rien ne
  demandait de l'ouvrir), toute l'EE aussi, et 🛑 **l'examen blanc ne change
  pas** — verrouillé par `ProductionExamConditionsTest`.

**Ce qui est relâché, c'est le GESTE, pas le budget** : plus de décompte de
tâche, plus d'envoi au premier arrêt, réécoute et reprise autorisées, puis envoi
explicite. La prise reste bornée par `dureeMaxSec` (plafond de capture, qui
protège le coût de transcription), une tâche reste **soumise une seule fois**, et
le pipeline Whisper → correcteur est **inchangé** — aucun audio candidat n'est
conservé.

⚠️ **L'examinateur vocal temps réel n'est pas proposé sur ces deux tâches**
(hypothèse tenue : le propriétaire décrit « la personne s'enregistre et
transcription comme d'habitude », et le temps réel a son propre quota payant —
l'y proposer contredirait « totalement gratuit »).

## Configuration

`sejourfr.tcf-diagnostic` dans `application.yaml`, miroir exact de
`config/TcfDiagnosticProperties`.

🛑 **`config-version` s'incrémente dès qu'un réglage change le SENS d'un
résultat** (items par palier, seuils). Il vaut **2** depuis le 2026-09-13. Il est recopié sur chaque session : un
diagnostic se relit avec la configuration **qui l'a produit**, sans quoi un
recalibrage réinterpréterait rétroactivement des diagnostics déjà passés.

Ce qui n'y vit **pas** : les durées d'épreuve (`DureeEpreuve`) et la table
démarche → palier (`TargetProcedure`). Données officielles = du code, pas des
réglages.
