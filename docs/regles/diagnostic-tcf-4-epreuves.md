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

⚠️ **La compréhension n'est plus vraiment « réduite » (2026-09-13).** Demande du
propriétaire : « le diagnostic complet, c'est pratiquement un examen blanc
complet ». `items-per-level` passe de **5 à 8** — 24 items au lieu de 15, quand
l'épreuve réelle en compte 25 —, et `config-version` passe de **1 à 2** parce
que le sens d'un niveau change. Le chrono suit tout seul : il est **au prorata
des items posés** (`TcfDiagnosticSectionStarter.dureeReduite`), donc il passe de
12/21 min à ≈ 19/34 min sans qu'aucun nombre n'ait été écrit.

🛑 **La répartition reste ÉGALE entre paliers** (8/8/8), là où l'examen suit
8/9/8. Ce n'est pas un oubli : le niveau se lit sur un **taux par palier**, et
un palier sous-doté rendrait son taux plus sensible à une seule erreur. Un item
de plus ne valait pas un réglage par palier.

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
