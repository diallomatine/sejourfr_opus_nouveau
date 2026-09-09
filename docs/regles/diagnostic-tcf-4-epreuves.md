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
| Compréhension | **réduite** — 15 items (5 A2 / 5 B1 / 5 B2) | format réel, 25 items |
| Production | **les 3 tâches**, jamais réduites | les 3 tâches |
| Accès | 1 offert, puis réévaluation Premium tous les 14 j | slot 1 offert, 2-20 Premium |
| Grille des 20 slots | **jamais** | oui |

**On ne réduit que la compréhension, jamais la production** (arbitrage A2). Le
Plan raisonne par tâche : afficher « EO tâche 2 est votre priorité » sans avoir
évalué EO2 rendrait la personnalisation fictive.

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
blancs et compterait dans « examens blancs passés ». Six requêtes le portent, et
`TcfDiagnosticServiceIT` le verrouille.

Deux décisions d'exclusion, écrites parce qu'elles ne se devinent pas :

- **le niveau TCF estimé EXCLUT les diagnostics** — il se lit sur un score
  calibré 100-499 établi sur 25 items, quand une section de diagnostic en compte
  15 ; les mélanger comparerait deux mesures qui ne mesurent pas la même chose ;
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

## Configuration

`sejourfr.tcf-diagnostic` dans `application.yaml`, miroir exact de
`config/TcfDiagnosticProperties`.

🛑 **`config-version` s'incrémente dès qu'un réglage change le SENS d'un
résultat** (items par palier, seuils). Il est recopié sur chaque session : un
diagnostic se relit avec la configuration **qui l'a produit**, sans quoi un
recalibrage réinterpréterait rétroactivement des diagnostics déjà passés.

Ce qui n'y vit **pas** : les durées d'épreuve (`DureeEpreuve`) et la table
démarche → palier (`TargetProcedure`). Données officielles = du code, pas des
réglages.
