# RÉPONSES À L'AUDIT — Moteur de cycle (Plan) — entrée en P1

Répond à `docs/audits/AUDIT_cycle_plan.md` (2026-09-18). Autorité : propriétaire, 2026-09-18.
Référence fonctionnelle : `SPEC_cycle_plan.md`.

> ⛔ **HARD STOP.** Cette passe est **P1 uniquement** : consigner les arbitrages dans
> `docs/decisions/plan-parcours-tcf.md` (suite de D-11) et mettre la spec en conformité.
> **Aucun code, aucune migration, aucun test.** Arrête-toi après et attends validation.

---

## 0. Cadre

L'audit est validé. Deux corrections actées :

- `Competence` **existe** sous le nom `Skill` ; la spec §10.1 était fausse et doit être corrigée.
- Le vocabulaire `journey` / `lot` / `étape` est conservé (D-8 maintenu). Seul le **cadre fonctionnel**
  de la spec fait autorité.

**Le comportement décrit dans la spec est la cible et ne se négocie pas.** Là où l'existant diverge,
c'est l'existant qui est révoqué, avec une décision datée. Les arbitrages ci-dessous ne sont pas des
compromis techniques : ce sont les règles du produit.

---

## 1. Réponses aux 18 questions

| # | Réponse | Précision |
|---|---|---|
| 1 | **Non** | La compétence de compréhension reste le **palier** (`CO-B1`). Pas de `question_skills`. R2 se lit « 2 séries sur le palier ». |
| 2 | **Oui, superposition** | Le cycle **borné** se superpose aux lots existants. `journey_lot` n'est pas remplacé. |
| 3 | **Oui, révocation** | La phrase de R2 « les priorités au-delà ne sont ni stockées ni mises en attente » est **révoquée**. Le cycle en attente est persisté et invisible du candidat. |
| 4 | **Oui, D-7 maintenu** | Le statut d'**étape** reste dérivé à la lecture. Seul le statut du **cycle** (`EN_COURS` / `EN_ATTENTE` / `HISTORISE`) est persisté, argumenté comme mémoire d'ordonnancement. |
| 5 | **Oui** | `EXAM_BLOC` verrouillé tant qu'une compétence du bloc n'est pas clôturée. Un examen passé hors plan avec des compétences restantes **ne valide rien** : abandon de `SUPERSEDED` dans ce cas précis. |
| 6 | **Oui, avec échappatoire** | Le quota d'étape devient « **2 séries réussies** » (seuil lu chez `learning-plan.comprehension.solid-ratio: 0.80`, pas de 8ᵉ déclaration de 0.80) **ou 4 séries terminées**, pour ne pas bloquer un candidat faible. |
| 7 | **Non** | `maxPrioritiesPerLot` reste à **3**. Aucune clé `nb_max_competences_par_bloc` n'est créée. |
| 8 | **Oui** | Ordre `CO, CE, EO, EE` conservé (D-9). Le diagnostic rapide place EE/EO en tête par construction. |
| 9 | **Oui** | Travailler une compétence depuis le Plan est **premium, sans exception**. L'exemption du 2026-08-21 est **révoquée dans la même passe**. `JourneyState.LOCKED` permanent pour un compte gratuit est l'effet **voulu**. |
| 10 | **Remplacé, pas reconduit** | Voir §2. Ni « 3 à vie », ni quota journalier. |
| 11 | **Voir §2** | Reformulé : 1 examen blanc gratuit **par épreuve de production**, à vie. |
| 12 | **Non** | Le diagnostic rapide **n'est pas** l'`EXAM_BLOC` EE. Ce sont deux gestes distincts, tous deux gratuits ; le double coût LLM au démarrage est **assumé**. |
| 13 | **Non** | Le civique **sort** de ce chantier. Le moteur est livré TCF d'abord. |
| 14 | — | Sans objet. |
| 15 | **Non** | Le mode module persisté est un chantier à part (P9). |
| 16 | **Oui** | `GoalBanner` et les 4 CTA par épreuve sont supprimés de l'Accueil, **après** avoir rebasculé le lancement d'examen sur « À faire maintenant » et sur le bloc d'épreuve du Plan. |
| 17 | **Oui** | Le niveau de sortie est **persisté** à l'historisation du cycle. Pas de recalcul rétroactif. |
| 18 | **Non, sauf un bug** | L'offline N1 sort du chantier. Mais `auth_controller.dart:81-124` (un `GET /me` en échec réseau efface les tokens et déconnecte) est un **bug à corriger immédiatement**, en ticket séparé. |

---

## 2. Freemium — nouvelle règle (révoque l'existant)

La règle est simplifiée volontairement. On assume d'être plus fermé au démarrage, quitte à rouvrir plus tard.

### Gratuit

| Élément | Détail |
|---|---|
| Diagnostic rapide | Gratuit, avec ses priorités et son analyse. |
| 1 examen blanc **EE** | Gratuit, **une fois à vie**, analyse IA complète incluse. |
| 1 examen blanc **EO** | Gratuit, **une fois à vie**, analyse IA complète incluse. |
| Examens QCM CO / CE | Inchangé : slot 1 offert selon `enforceMockExamSlotAccess`. |

### Premium sans exception

Tout travail de compétence depuis le Plan, tous les sujets d'expression au-delà du freebie, **toute
analyse IA** EE et EO au-delà du freebie.

### Révocations à consigner

- `sejourfr.competences.analysis.free-analyses: 3` (« 3 analyses à vie ») → **supprimé**, remplacé par le
  freebie ci-dessus. Aucun quota journalier n'est introduit ; `dailyQuota` reste inexistant.
- `ProductionAccessService` : seuil « 2 sessions EE+EO confondues » → **1 par épreuve, nominatif**.
- `ProductionAccessService.FREE_TRAINING_PER_EPREUVE = 1` → **supprimé** (contredit « travailler EE/EO = premium »).
- `SkillAccessService` : l'ouverture de la compétence du focus Plan et du 1ᵉʳ rang des sections **EE/EO**
  → **supprimée**. L'ouverture des rangs CO/CE est traitée dans la même passe, cohérente avec Q9.
- Exemption du 2026-08-21 → **révoquée** (cf. Q9).

### Consommation du freebie — règle stricte

Le freebie est consommé **uniquement** quand l'examen est **réellement terminé et l'analyse rendue**.

- Abandon, expiration, échec technique, échec du correcteur → **non consommé**, le candidat le retrouve.
- La consommation est **persistée**, pas calculée à la lecture. L'audit note qu'il n'existe aucune table
  de quota et 4 implémentations ad hoc de « première fois gratuite » : créer un **ledger unique**, du
  type `free_entitlement_usage (user_id, code, consumed_at, source_attempt_id)` avec
  `UNIQUE (user_id, code)`, et y ramener les 4 implémentations.
- Le point d'écriture est la **remise de l'analyse**, pas le démarrage de l'examen ni `doFinish` seul.

> ❓ **Un seul point à confirmer avant P2** : la lecture retenue est **1 gratuit en EE et 1 gratuit en EO**
> (deux freebies nominatifs). Si l'intention était « un seul, au choix, EE **ou** EO », le dire maintenant.

---

## 3. B2 — le cycle porte le module et l'épreuve

`journey` reçoit une colonne `module`. Sa clé d'unicité devient `(user_id, module, status)` via **index
uniques partiels** sur le patron existant `uq_journey_lot_open_par_epreuve` — un seul `EN_COURS` et un
seul `EN_ATTENTE` par `(user, module)`. `uq_journey_user_target` est adaptée en conséquence.

**Chaque étape du plan est rattachée à une épreuve, et cette épreuve est visible partout.** C'est une
exigence produit, pas un détail d'affichage : le candidat doit savoir en permanence sur quelle épreuve il
travaille. L'épreuve apparaît dans « À faire maintenant », dans l'en-tête du bloc, sur la ligne d'étape,
et sur l'écran de résultat. Le vocabulaire des épreuves (compréhension orale, expression écrite…) prime
sur le vocabulaire interne (lot, step, journey), qui ne doit **jamais** apparaître à l'écran.

---

## 4. Contraintes de découpage

Le découpage proposé (P1→P9) est validé, avec ces amendements :

- **P7 (page Progression) est bloquée.** Le propriétaire fournira le **template de l'écran historique des
  cycles**. Ne rien concevoir ni implémenter sur cet écran avant réception. Le travail préparatoire
  autorisé est l'**endpoint d'agrégation** seul, et seulement après P6.
- **P8 (civique) est retirée** du chantier (Q13).
- **P2** intègre `module` + `status` + historisation + le ledger de freebie. Pas de `question_skills` (Q1).
- **P3** doit brancher les **4 points post-évaluation** identifiés (B9), et exclure explicitement
  `lockProductionSubAttempts`. Un branchement sur `doFinish` seul est un échec de la phase.
- **P3** lit `SkillMasteryEngine` comme autorité de maîtrise. Le moteur `progression/` V4.2 reste en
  shadow et n'est pas consulté (B10). Aucune troisième autorité n'est créée.
- Les 5 documents périmés (C10) sont corrigés en P2, pas maintenant.

---

## 5. Livrable de P1

1. `docs/decisions/plan-parcours-tcf.md` complété à partir de D-12, une décision par arbitrage ci-dessus,
   datée 2026-09-18, avec pour chaque révocation la phrase révoquée citée et le document où elle vivait.
2. `SPEC_cycle_plan.md` mise en conformité : §10.1 corrigé (`Skill` existe), vocabulaire aligné,
   §7 freemium réécrit selon le §2 ci-dessus, §9 réduit aux seules clés neuves
   (`seuil_reussite_competence`, `exam_bloc_gratuit`, et rien d'autre — `nb_series_reussies`,
   `nb_max_competences_par_bloc`, `ordre_blocs_cycle_initial` et le bloc `civique` sont supprimés).
3. La liste des fichiers que P2 devra toucher, sans les toucher.

> ⛔ **RAPPEL STOP.** Termine après ces trois livrables. N'ouvre pas P2, même si le schéma paraît évident.
