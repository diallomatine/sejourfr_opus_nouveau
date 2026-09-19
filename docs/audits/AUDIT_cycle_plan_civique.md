# AUDIT — Moteur de cycle (Plan) — module CIVIQUE — Phase 0

Date : **2026-09-19**. Périmètre : `BRIEF_cycle_plan_civique_audit.md` (§1 diagnostic de contenu,
§2 les 5 questions ouvertes, §3 inventaire technique).
Références : `docs/progression/civique/SPEC_cycle_plan_civique.md`,
`docs/progression/SPEC_cycle_plan.md`, `docs/decisions/plan-parcours-tcf.md` (D-12 → D-24),
`docs/audits/REPONSES_AUDIT_cycle_plan.md`.

> ⛔ **Lecture seule.** Aucun fichier de code, aucune migration, aucun test n'a été créé ni modifié.
> Toutes les mesures du §1 viennent de requêtes `SELECT` sur la base locale `sejourfr_db`.
> **Aucun appel LLM n'a été passé.**

---

## 🔻 AVERTISSEMENT AJOUTÉ LE 2026-09-19 — les mesures de tagging de ce rapport ne sont **pas reproductibles**

🛑 **Toutes les mesures de tagging ci-dessous sont vraies de la base locale de l'auteur, et fausses
d'une base neuve.** Elles portent sur `questions.civic_notion_id`, et la campagne du 2026-09-11 a
posé ces tags **par script** — **aucune migration ne les reproduit**.

| | Base locale | **Base neuve** (Zonky, toutes migrations Flyway) |
|---|---|---|
| Questions civiques | 1 016 | **1 005** |
| **Taguées** | **783** actives | 🛑 **1** |
| `question_notion_suggestions` | 981 | 🛑 **0** |

**Ce qui est donc à relire avec cette réserve** : §1.2 (couverture globale), §1.3 (couverture par
thématique, les 97-98,6 % et la bascule au grain NOTION), §1.4 (par mention), §1.6 (la dotation par
notion × mention, le « 1 couple sur 138 »), §1.10 (les 981 suggestions), §1.11 (la cohérence), §1.12
(la conclusion sur R2).

**Ce qui reste valide** : tout ce qui ne compte pas de tags — les 176 mises en situation (jamais
taguées), les formats 20/16 et 40/32, les 11 examens de thème, les constatations de code, les
contraintes de schéma, et les 46 notions elles-mêmes (seedées par V051/V058, donc reproductibles).

🛑 **Corrigé par `DETTE-T1`** (`docs/decisions/plan-parcours-tcf.md`) : deux migrations rendent le
tagging reproductible. Cet avertissement se retire quand elles sont livrées, **et pas avant**.
La légende complète des natures de chiffre vit dans `AUDIT_cycle_plan_civique_v2.md`.


---

## 0. Ce qu'il faut retenir en dix lignes

1. **Le tagging est fait, et il est bon** : 98 % des questions de **connaissance** portent leur
   notion, sur les 5 thèmes. La bascule `seuil-tagging: 0.80` est **franchie partout** — le plan
   civique travaille **déjà** au grain NOTION aujourd'hui, en production.
2. **Les mises en situation ne sont pas taguées du tout** (0 / 176), et c'est **volontaire** :
   `CivicPlanProperties.seuilTagging` exclut explicitement ce type du dénominateur.
3. 🛑 **R2 au grain (notion × mention) n'est PAS applicable en l'état.** Une série fait
   **10 questions** ; « 2 séries réussies » demande donc ~20 questions distinctes. Sur
   **138 couples (notion × mention), 1 seul** atteint 20. **23 sont à zéro.**
4. 🛑 **Le format « 20 questions / seuil 16 » de la spec est EXACT mais mal rangé** : il vit en
   constantes privées de `AttemptService`, pas dans `CivicExamFormat`, et il **duplique** 40/32 qui
   y vit déjà. Aucun `ExamTemplate` ne le porte ; la composition est **dynamique**.
5. Le thème d'un examen de thème **est déjà persisté** (`attempts.lot_theme_id`) : R1 est faisable.
6. **Le ledger de gratuité est entièrement façonné pour les productions EE/EO** (enum, CHECK, point
   d'écriture « remise de l'analyse »). Le civique n'a pas d'analyse : il faut un second point
   d'écriture, et le CHECK doit s'ouvrir.
7. **Le freemium civique actuel contredit la spec** : slot 1 offert **et rejouable à volonté**, pas
   « une fois à vie ».
8. **Le schéma du cycle est TCF-only par contrainte dure** : 6 `CHECK` et 2 `FK` s'opposent à un
   cycle civique. La colonne `journey.module` livrée en P2 ne suffit pas.
9. **L'autorité de R2 est `learning_plan_observations.status = SOLID`**, écrite par
   `ComprehensionObservationService`. **Rien n'écrit d'observation pour le civique** : c'est la
   décision la plus structurante du chantier, avant même le choix `skills` / `civic_notions`.
10. Les deux fronts sont **déjà sur le kit** et les **4 primitives de cycle existent des deux
    côtés**. Le coût d'écran est faible ; le coût est au backend.

---

# 1. Diagnostic du contenu

## 1.1 Périmètre et effet de `is_active` / `status`

| Filtre | Questions CIVIQUE |
|---|---|
| Toutes | **1 016** |
| `is_active = true` | **976** |
| `is_active = false` | **40** |
| `status <> 'ACTIVE'` | **0** |

🛑 **`status` ne joue aucun rôle côté civique** : les 1 016 lignes sont `ACTIVE`, y compris les 40
désactivées par `is_active`. La désactivation passe **uniquement** par `is_active`. Tous les
compteurs ci-dessous sont donc sur `is_active = true AND status = 'ACTIVE'` (= 976), et l'écart avec
le filtre `is_active` seul est **nul**.

⚠️ **Dette latente repérée** : `CivicPlanRepository.questionsParNotion()` et
`questionsParTheme()` filtrent `is_active = true` **sans filtrer `status`**. Inoffensif aujourd'hui
(0 `DRAFT`, 0 `ARCHIVED`), faux le jour où un brouillon civique apparaît. À aligner dans la passe,
pas un blocage.

Curiosité à signaler : les **40** questions `is_active = false` sont **taguées à 100 %**. Ce sont
les doublons retirés par V294 ; leur tag a survécu à la désactivation.

## 1.2 Couverture du tagging — global

| Périmètre | Total | Taguées | % |
|---|---|---|---|
| Actives, tous types | 976 | 783 | **80,2 %** |
| Actives, `CONNAISSANCE` | 800 | 783 | **97,9 %** |
| Actives, `MISE_SITUATION` | 176 | **0** | **0 %** |

🛑 **Les 193 non taguées se décomposent en 176 mises en situation + 17 connaissances.** Le « 80 % »
global est un artefact : il mélange un type tagué à 98 % et un type que la règle n'exige pas de
taguer.

## 1.3 Couverture par thématique

Deux lectures, et **c'est la seconde qui fait règle** — `CivicPlanProperties.seuilTagging` dit noir
sur blanc que le dénominateur **exclut** les mises en situation (« les compter plafonnait trois
thèmes sur cinq sous 80 %, seuil qu'ils n'auraient donc JAMAIS franchi »).

**Lecture brute (tous types) — informative seulement**

| Thème | Total | Taguées | % |
|---|---|---|---|
| `CIV_DROITS_DEVOIRS` | 213 | 163 | 76,5 % |
| `CIV_HISTOIRE_GEO` | 223 | 189 | 84,8 % |
| `CIV_INSTITUTIONS` | 235 | 200 | 85,1 % |
| `CIV_PRINCIPES` | 90 | 68 | 75,6 % |
| `CIV_SOCIETE` | 215 | 163 | 75,8 % |

**Lecture de la règle (dénominateur `CONNAISSANCE`) — celle qui décide du grain**

| Thème | Connaissances actives | Taguées | % | `≥ 0,80` ⇒ grain NOTION |
|---|---|---|---|---|
| `CIV_DROITS_DEVOIRS` | 166 | 163 | **98,2 %** | ✅ |
| `CIV_HISTOIRE_GEO` | 193 | 189 | **97,9 %** | ✅ |
| `CIV_INSTITUTIONS` | 204 | 200 | **98,0 %** | ✅ |
| `CIV_PRINCIPES` | 69 | 68 | **98,6 %** | ✅ |
| `CIV_SOCIETE` | 168 | 163 | **97,0 %** | ✅ |

✅ **Les cinq thèmes sont au grain NOTION.** Le commentaire de `CivicPlanProperties` (« au lancement
de L10, 0 question sur 1 016 est taguée — les cinq thèmes sont donc au grain THEME ») est
**périmé** : c'est l'inverse qui est vrai depuis la campagne du 2026-09-11. À corriger (§4, écart
non bloquant E-7).

## 1.4 Couverture par mention

La `difficulty` **est** la mention. Le filtre du moteur est **strict** (`q.difficulty = :mention`,
`CivicPlanRepository`), **jamais cumulatif** : un candidat NAT ne voit **pas** les questions CSP.
C'est documenté et voulu — `CivicDotation` : « CSP, CR et NAT ne sont pas trois niveaux du même
programme, ce sont **trois programmes différents** ».

| Mention | Total actives | Taguées | % |
|---|---|---|---|
| `CSP` | 297 | 237 | 79,8 % |
| `CR` | 410 | 330 | 80,5 % |
| `NAT` | 269 | 216 | 80,3 % |

Le tagging est **homogène** entre mentions. Aucune mention n'est lésée par la campagne. Le problème
n'est pas la couverture du tagging, c'est la **dotation** (§1.6).

## 1.5 Notions — effectif et orphelines

| | Nombre |
|---|---|
| `civic_notions` totales | 60 |
| **actives** | **46** |
| inactives | 14, dont **13 fusionnées** (`merged_into_id`) |

🛑 **46 notions actives, pas 40.** La spec civique (§1) et le brief (§2.1) parlent de « 40 notions » ;
le référentiel en base en porte **46**. Écart de documentation à trancher (§6, Q-F1).

| Thème | Notions actives | Total |
|---|---|---|
| `CIV_DROITS_DEVOIRS` | 9 | 14 |
| `CIV_HISTOIRE_GEO` | 12 | 14 |
| `CIV_INSTITUTIONS` | 8 | 9 |
| `CIV_PRINCIPES` | 5 | 7 |
| `CIV_SOCIETE` | 12 | 16 |

**Orphelines : aucune.** Zéro notion active à 0 question, toutes mentions confondues. Le minimum est
**5** (`pv_libertes_ddhc`, `vs_emploi_formation`).

**Notions à moins de 20 questions** (toutes mentions confondues) : **30 sur 46**.
Les 16 qui atteignent 20 : `pv_symboles_devise` (37), `inst_parlement` (34), `inst_ue` (32),
`hg_geographie` (27), `hg_guerres_resistance` (26), `inst_elections` / `inst_president` (25),
`dd_infractions_peines` / `dd_libertes_limites` / `inst_constitution` / `vs_ecole_scolarite` (24),
`vs_famille_etat_civil` (22), `inst_collectivites` (21), `hg_republiques` / `inst_justice` /
`vs_travail_contrat_salaire` (20).

## 1.6 🛑 Dotation par (notion × mention) — le chiffre qui décide de tout

C'est **la** mesure qui répond à la question du brief, parce que le moteur ne lit **jamais** une
notion hors de la mention du candidat.

**46 notions × 3 mentions = 138 couples.**

| Mention | 0 q. | 1–4 q. | 5–9 q. | 10–19 q. | **≥ 20 q.** | Servables (`≥ 5`) |
|---|---|---|---|---|---|---|
| `CSP` | **12** | 10 | 16 | 7 | **1** | **24 / 46** |
| `CR` | 3 | 9 | 22 | 12 | **0** | **34 / 46** |
| `NAT` | 8 | 16 | 16 | 6 | **0** | **22 / 46** |
| **Total** | **23** | **35** | **54** | **25** | **1** | — |

Le seul couple à ≥ 20 est `pv_symboles_devise` en CSP (21).

**Ce que ça veut dire, concrètement**

- Une **série ciblée** fait `questionsParSerie = 10` (`application.yaml`, `sejourfr.civic-plan`).
- **R2 demande 2 séries réussies** ⇒ ~**20 questions distinctes** pour deux séries sans recouvrement.
- **1 couple sur 138** le permet. Les 2 séries d'une notion à 7 questions **rejoueront les mêmes
  items** — et « réussir deux fois les mêmes 7 questions » ne prouve pas ce que R2 croit prouver.
- Pire, le seuil de servabilité est `questionsMinParNotion = 5`, **la moitié d'une série**. Une notion
  SERVABLE à 5 questions ouvre une série de **5 items**, pas 10 (`tirageSerieCiblee` a un `LIMIT`,
  il ne complète pas). Le candidat reçoit une « série » deux fois trop courte, en silence.
- **Un candidat CSP a 24 notions travaillables sur 46** ; **12 notions n'existent pas pour lui**
  (`NON_APPLICABLE`). Un candidat NAT en a 22.

**Les 38 notions qui ont au moins une mention sous le seuil de 5** (c.-à-d. tout sauf 8) sont
listées en annexe A. Les plus parlantes :

| Notion | CSP | CR | NAT |
|---|---|---|---|
| `dd_protection_europeenne` | **0** | **0** | 11 |
| `vs_papiers_identite` | 8 | **0** | **0** |
| `vs_nationalite_francaise` | **0** | 1 | 11 |
| `inst_constitution` | **0** | 12 | 12 |
| `inst_justice` | **0** | 14 | 6 |
| `hg_litterature` | **0** | 8 | 5 |
| `vs_ecole_scolarite` | 12 | 12 | **0** |
| `vs_urgences_secours` | 13 | 2 | **0** |

🛑 Ce **n'est pas** un défaut de tagging : c'est un défaut de **stock éditorial par mention**, et
`CivicDotation` l'avait déjà nommé (« « Devenir français » porte 10 questions en NAT et **zéro** en
CSP »). Le tagging l'a rendu **visible**, il ne l'a pas créé.

## 1.7 Répartition par thème et par mention — le pool des examens

| Thème | Mention | Total | dont `CONNAISSANCE` | dont `MISE_SITUATION` |
|---|---|---|---|---|
| `CIV_DROITS_DEVOIRS` | CSP | 62 | 44 | 18 |
| | CR | 96 | 77 | 19 |
| | NAT | 55 | 45 | 10 |
| `CIV_HISTOIRE_GEO` | CSP | 69 | 59 | 10 |
| | CR | 79 | 69 | 10 |
| | NAT | 75 | 65 | 10 |
| `CIV_INSTITUTIONS` | CSP | 69 | 57 | 12 |
| | CR | 95 | 86 | 9 |
| | NAT | 71 | 61 | 10 |
| `CIV_PRINCIPES` | CSP | **25** | 24 | 1 |
| | CR | 45 | 30 | 15 |
| | NAT | **20** | 15 | 5 |
| `CIV_SOCIETE` | CSP | 72 | 57 | 15 |
| | CR | 95 | 73 | 22 |
| | NAT | **48** | 38 | 10 |

**Écart type des totaux par thème** (toutes mentions) : moyenne 195,2, écart type **≈ 52,3** —
`CIV_PRINCIPES` (90) est à **deux écarts types sous** la moyenne, les quatre autres sont dans un
mouchoir (213–235).

🛑 **Un examen de thème de 20 questions passe partout, mais `CIV_PRINCIPES` est à la limite** :

- `CIV_PRINCIPES` × **NAT** = **20 questions exactement**. Un examen de 20 questions **épuise le
  pool** : aucune variation possible entre deux passages, et aucun rejeu qui ne redonne pas
  strictement les mêmes items.
- `CIV_PRINCIPES` × **CSP** = 25 questions ⇒ un examen en consomme **80 %**.
- Un examen **global** de 40 questions stratifié 8 × 5 thèmes (`composeCiviqueFullExam`) passe
  partout, y compris Principes/NAT (8 sur 20).
- Un examen **« Focus Principes » de 40 questions dans une mention est impossible** — c'est
  exactement pourquoi le template `civique-principes` est le seul « Focus » sans
  `target_procedure` (§1.9).

## 1.8 Mises en situation

**Comment le type est porté** : par la colonne `questions.question_type` (`varchar(24)`), valeur
`MISE_SITUATION`, en regard de `CONNAISSANCE`. Pas d'enum dédié en base, pas de table à part ;
côté Java c'est `QuestionType`. **Aucun `CHECK`** ne borne cette colonne (contrairement à `status`
et `audio_mode`) — c'est l'application qui la tient.

**Combien** : **176** actives (18,0 % du stock actif de 976).
**Taguées à une notion** : **0**, et aucune n'a même reçu de **suggestion** (§1.10).

**Répartition sur les 5 thèmes** — elles sont bien **réparties**, pas concentrées :

| Thème | Total | CSP | CR | NAT |
|---|---|---|---|---|
| `CIV_DROITS_DEVOIRS` | 47 | 18 | 19 | 10 |
| `CIV_HISTOIRE_GEO` | 30 | 10 | 10 | 10 |
| `CIV_INSTITUTIONS` | 31 | 12 | 9 | 10 |
| `CIV_PRINCIPES` | **21** | **1** | 15 | 5 |
| `CIV_SOCIETE` | 47 | 15 | 22 | 10 |

⚠️ **Une seule case est creuse : `CIV_PRINCIPES` × `CSP` = 1 mise en situation.** Toutes les autres
cellules sont à ≥ 5.

**Le ratio de l'examen réel n'est pas tenu.** L'examen porte **12 mises en situation sur 40** (30 %).
Le stock actif en porte **18 %**. Et surtout : **aucun tirage d'examen ne garantit ce ratio.**

- Les 20 `exam_templates` civiques ont tous leurs `exam_template_rules` avec
  `question_type = NULL` ⇒ le tirage ne distingue pas les deux types.
- `composeCiviqueFullExam(difficulty, size)` passe `null` en `questionType` ⇒ idem.
- L'examen de thème (`questionManager.findRandom(module, themeId, difficulty, null, 20)`) ⇒ idem.
- **Seul le diagnostic** tient le ratio, et il le tient **en configuration** :
  `sejourfr.civic-diagnostic.connaissances: 28` + `mises-en-situation: 12`.

🛑 **Conséquence pour l'option A du §3.1 de la spec** (« la mise en situation est un type de question
présent dans chaque bloc, chaque examen de thème en contient sa part ») : la phrase « en contient sa
part » **décrit une fonctionnalité qui n'existe pas**. Le schéma la permet
(`exam_template_rules.question_type` existe et est mappée dans `ExamTemplateRule`), le code ne s'en
sert jamais pour le civique. C'est du travail à chiffrer, pas un acquis.

## 1.9 Examen de thème et examen global — ce qui existe vraiment

**L'examen de thème existe, au format annoncé par la spec, mais il n'est pas là où on le cherche.**

| Fait | Valeur | Où |
|---|---|---|
| Questions | **20** | `AttemptService.CIVIQUE_THEME_EXAM_SIZE` (l. 69) |
| Seuil | **16** | `AttemptService.CIVIQUE_THEME_EXAM_THRESHOLD` (l. 71) |
| Durée | **20 min** | `AttemptService.CIVIQUE_THEME_EXAM_TIME` (l. 70) |
| Composition | **dynamique**, `questionManager.findRandom(CIVIQUE, themeId, mention, null, 20)` | `AttemptService` l. 213-234 |
| Déclencheur | `type = MOCK_EXAM` + `module = CIVIQUE` + **`themeId` non nul** | `AttemptService` l. 161-163 |
| Thème persisté | **oui**, `attempts.lot_theme_id` | index `idx_attempts_user_lot_civique` |
| Template | **aucun** | 0 `ExamTemplate` à 20 questions |

**Vérification en base** — les trois formes d'examen blanc civique passées :

| `total_questions` | template | `lot_theme_id` | Nombre |
|---|---|---|---|
| **20** | non | **oui** | **11** |
| 40 | non | non | 18 |
| 40 | oui | non | 15 |

✅ **La spec a raison sur 20/16** (le brief et la spec disaient « confirmer 20/16 plutôt que 10 » —
c'est confirmé), **et l'audit TCF avait raison de noter « aucun template thème »** : les deux
constats sont compatibles, la composition est dynamique.

🛑 **Deux défauts de rangement, à corriger dans la passe :**

1. **`CivicExamFormat` n'est pas l'autorité qu'il prétend être.** Son javadoc dit « 40 questions et
   un seuil de 32 ne sont pas des paramètres produit : ce sont les règles de l'épreuve […] même
   traitement que `DureeEpreuve` et `TargetProcedure` ». Or `AttemptService` redéclare
   `CIVIQUE_EXAM_SIZE = 40` (l. 63) et `CIVIQUE_EXAM_THRESHOLD = 32` (l. 65) : **la règle vit en
   2 copies**, et `exam_templates` en porte une 3ᵉ (`total_questions`/`passing_score`, 20 lignes).
   C'est le défaut nommé « une règle, une autorité » du `CLAUDE.md` racine.
2. **Le format de l'examen de thème n'est déclaré nulle part d'autorisé.** 20/16/20 min sont trois
   constantes privées d'un service de 900 lignes. Le cycle civique en fera son étape de clôture de
   bloc : il doit les lire chez une autorité, pas les redéclarer une 2ᵉ fois.

**Les templates**, pour mémoire : **20** templates civiques, **tous** à 40 Q / seuil 32 / 2 700 s.
Onze sont des « Focus » mono-thème (une seule `exam_template_rule` à 40 questions), et la matrice
est **incomplète** :

| Mention | Focus existants | Manquants |
|---|---|---|
| `CSP` | Institutions, Histoire, Société | **Droits et devoirs, Principes** |
| `CR` | Institutions, Histoire, Société, Droits | **Principes** |
| `NAT` | Institutions, Histoire, Droits | **Société, Principes** |
| *(sans mention)* | Principes | — |

⚠️ Ces « Focus » à 40 questions **ne sont pas** les examens de thème du cycle (qui font 20). Ils ne
sont pas une base de travail ; au mieux une source de confusion à l'écran.

## 1.10 `question_notion_suggestions` — la campagne, telle qu'elle s'est passée

**La table n'est pas vide** : **981 lignes**, **840 questions distinctes**, **4 lots**.

| `review_verdict` | `review_source` | Lignes |
|---|---|---|
| *(aucun)* | `AUTO_THRESHOLD` | 366 |
| `VALIDATED` | `OWNER_REVIEW` | 355 |
| `VALIDATED` | `AGENT_REVIEW` | 172 |
| *(aucun)* | *(aucune)* | 67 |
| `CORRECTED` | `OWNER_REVIEW` | 17 |
| `REJECTED` | `OWNER_REVIEW` | 4 |

**Comment le tagging a été fait** : par **LLM, puis revue humaine et agent**.

- Modèle : **`claude-sonnet-5`**, unique. Prompt : **`PROMPT_TAG_NOTION_v4`**, unique.
- Toutes les lignes sont datées du **2026-09-11**, en 4 lots.
- Chemin des scripts : **`scripts/pre-tagging/`** — `prompt-v4.sh`, `batch-v4.sh`, `tagger-lot.sh`,
  `persister.sh`, `mesurer.sh`, `selectionner-pilote.sh`, avec les requêtes et réponses conservées
  dans `scripts/pre-tagging/campagne-v4/` (un couple `*.questions.json` / `*.reponse.json` par lot
  de thème) et `scripts/pre-tagging/tsv/`.
- La **persistance** des tags est en migrations : `V286` → `V295` dans `db/migration/200_civique/`
  (rangements par thème, propagation de verdicts, seuil automatique à 0,95, déduplication,
  corrections factuelles). Le garde-fou est en base : deux triggers
  (`trg_suggestion_theme_source`, `trg_suggestion_verdict_applicable`) et cinq `CHECK`.

🛑 **Ce que la campagne n'a jamais couvert : les mises en situation.** Les 840 questions suggérées
sont **toutes** de type `CONNAISSANCE`. Les 176 `MISE_SITUATION` n'ont **aucune** ligne de
suggestion — elles n'ont pas été rejetées, elles n'ont **pas été soumises**.

**Les 17 connaissances actives non taguées** ont toutes une suggestion, mais aucune n'a abouti :
3 `REJECTED` par le propriétaire, 1 `VALIDATED` sur un `notion_id` **nul**, et les autres laissées
sans verdict. Elles se répartissent : Droits 3, Histoire 4, Institutions 4, Principes 1, Société 5.
C'est un **reliquat de revue**, pas une défaillance de pipeline.

## 1.11 Cohérence thème ↔ notion

| Contrôle | Résultat |
|---|---|
| Questions dont `civic_notion_id` pointe une notion d'un **autre** `theme_code` que le `theme_id` de la question | **0** |
| Questions taguées sur une notion **inactive** | **0** |

✅ **Cohérence parfaite.** Rien à corriger. Le `trg_suggestion_theme_source` et les rangements
V286/V288/V291 ont fait leur travail.

## 1.12 🛑 Conclusion du diagnostic — R2 est-il applicable, oui ou non ?

**NON, pas en l'état — et le manquant n'est pas du tagging, c'est du contenu.**

| Question du brief | Réponse |
|---|---|
| Le tagging permet-il d'identifier la notion d'une réponse ? | ✅ **Oui**, à 98 % des connaissances, sur les 5 thèmes et les 3 mentions, sans une seule incohérence. |
| Le tagging permet-il d'appliquer **R2** (2 séries réussies de 10 questions) au grain notion ? | ❌ **Non.** 1 couple (notion × mention) sur 138 porte les ~20 questions distinctes nécessaires. |
| Sur les 5 thèmes ? | ❌ Non : le déficit est **transversal**, il ne se règle pas thème par thème. |
| Sur les 3 mentions ? | ❌ Non, et **inégalement** : CSP 24 notions servables / 46, CR 34, NAT 22. 23 couples à zéro. |

**Ce qui manque, en nombre de questions.** Deux cibles possibles, à trancher par le propriétaire :

| Cible | Définition | Questions à produire |
|---|---|---|
| **Cible haute** — R2 littérale | 20 questions par couple (notion × mention) servable | ≈ **1 480** (de quoi amener les 115 couples non nuls à 20) |
| **Cible médiane** — R2 avec recouvrement assumé | 10 questions par couple, soit **une série pleine** | ≈ **560** |
| **Cible basse** — statu quo servable | aucune production ; R2 change de grain (§2.6) | **0** |

🛑 **La cible haute ≈ 1 480 questions est un multiple et demi du stock civique entier (976).** Ce
n'est pas un ajustement de contenu, c'est un second chantier éditorial. **La recommandation de cet
audit est donc de ne pas appliquer R2 au grain (notion × mention)** — voir §2.6 pour les options.

---

# 2. Réponses aux 5 questions ouvertes de la spec §5

Format imposé : **existant / options / recommandation / coût**. 🛑 **Rien n'est tranché ici.**

## 2.1 Q1 — Où vit la notion dans le moteur ?

### L'existant, mesuré

| Fait | Détail |
|---|---|
| `skills` est **TCF-only par contrainte dure** | `chk_skills_section CHECK (section IN ('EE','EO','CO','CE'))` ; `chk_skills_task_code` borne à `EE1..EO3` ; `chk_skills_section_matches_task` ; `chk_skills_target_level CHECK (target_level IN ('A1','A2','B1','B2'))` ; `chk_skills_display_order BETWEEN 1 AND 50` |
| `skills` a **4 colonnes `NOT NULL` sans équivalent civique** | `description`, `general_criterion`, `target_level`, `section` |
| `skills` est référencée par **5 FK** | `diagnostic_task_skills` (RESTRICT), `skill_prompts` (composite `(id, section)` !), `journey_step.skill_id` (CASCADE), `learning_plan_observations.skill_id` (RESTRICT), `plan_pinned_priorities.skill_id` (CASCADE) |
| `civic_notions` est **propre et complète** | 46 actives, `code` unique, `theme_code`, `display_order`, `merged_into_id` avec 2 `CHECK`, `description` |
| `learning_plan_observations.skill_id` | `uuid NOT NULL`, **FK réelle** vers `skills` en `ON DELETE RESTRICT` |
| Un `CHECK` supplémentaire bloque | `chk_learning_plan_observation_source CHECK (source_type IN (…9 valeurs…))` — **aucune civique** |
| `journey_step` porte 3 `CHECK` de forme | `chk_journey_step_train_skill` exige `skill_id NOT NULL AND lot_id NOT NULL AND exam_type NOT NULL` |

### Option A — généraliser `skills`, importer les 46 notions

**Travail** : ajouter `module` (défaut `'TCF'`), relâcher `chk_skills_section` pour une valeur
civique, rendre `target_level` / `description` / `general_criterion` nullables **ou** leur inventer
une valeur civique, relâcher `chk_skills_display_order` (46 notions tiennent sous 50, mais le
`uq_skills_section_order_comprehension` gêne), importer 46 lignes, et **garder `civic_notions` en
miroir** ou la faire disparaître.

**Ce que ça casse**

- `skill_prompts` a une FK **composite** `(skill_id, section)` : une notion civique sans `section`
  valide n'a pas de place dans ce couple.
- `AdminSkillService`, `SkillAccessService`, `SkillMasteryEngine`, `SkillMasteryResolver`,
  `SkillProgressCounter`, `EpreuvesProductionQualifiantesResolver` lisent tous `Skill.getSection()`
  et branchent sur `isComprehension()`. Une 5ᵉ valeur de `section` traverse **tout** ce code.
- `diagnostic_task_skills` et `plan_pinned_priorities` gagnent des lignes civiques possibles sans
  que rien ne les attende.
- **Deux référentiels du même objet** : `civic_notions` (que l'admin édite, que les migrations
  V286→V295 alimentent) et `skills` (que le moteur lit). C'est **exactement** le défaut « une règle,
  une autorité » qu'on cherche à éviter, transposé aux données.

**Coût mesuré** : 1 migration lourde + **≈ 6 services** à rendre tolérants à une `section` non
CECRL + la synchronisation permanente des deux tables. Le risque n'est pas le volume, c'est que
`Skill.section` cesse de vouloir dire quelque chose.

### Option B — observation polymorphe (`skill_id` **ou** `civic_notion_id`)

**Travail** : `learning_plan_observations.skill_id` devient nullable, ajout de `civic_notion_id`
nullable + FK + `CHECK` d'exclusivité, `uq_learning_plan_observation_source` étendue, extension de
`chk_learning_plan_observation_source` aux sources civiques. Idem sur `journey_step` (skill_id
nullable + `civic_notion_id` + `CHECK` de forme adapté).

**Chiffrage de l'impact (demandé par le brief)**

| Surface | Compte |
|---|---|
| Lecteurs de `learning_plan_observations` | **8 fichiers** — `ComprehensionObservationService`, `JourneyReadService`, `SkillMasteryEngine`, `SkillMasteryResolver`, `LearningPlanService`, `ProgressionPlanBridge`, `ReceptiveEvidenceAdapter`, `ProductiveEvidenceAdapter` |
| Lecteurs de `journey_step.skill_id` | **5** — `JourneyService`, `JourneyReadService`, `JourneyLotBuilder`, `JourneyBlocResolver`, `JourneyHistoryService` |
| Requêtes qui **doublent** | ⚠️ **Aucune, si le polymorphisme est résolu au niveau du manager.** Les requêtes prennent un `UUID` ; c'est le `CHECK` d'exclusivité qui dit dans quelle colonne il va. Le brief craignait « toutes les requêtes du moteur doublent » — **c'est faux** tant qu'on n'écrit pas deux chemins de lecture. |
| Ce qui double vraiment | les **écritures** (2 constructeurs d'observation) et les **mappers** (2 façons de rendre un titre d'étape) |

**Coût mesuré** : 2 migrations de colonnes nullables + `CHECK`, **≈ 4 écritures** à dédoubler,
0 requête de lecture dédoublée si le manager porte la résolution. `civic_notions` reste l'unique
référentiel des notions.

### Option C — *non prévue par la spec, relevée par l'audit*

**Le cycle civique n'a pas besoin de la notion au niveau de `journey_step`.** Voir §2.6 : si R2
change de grain (le **thème**, pas la notion), alors `journey_step` civique porte un `theme_id` et
**aucune** des deux options ci-dessus n'est nécessaire. `civic_notions` reste où elle est, dans le
plan dérivé, qui marche déjà.

### Recommandation

**Option B**, et **pas** l'option A. La spec recommande A « parce que le moteur ne doit connaître
qu'une seule notion d'unité travaillable » — l'intention est juste, mais A l'obtient en **cassant
le sens de `Skill.section`** et en créant deux référentiels de la même notion. B garde une seule
autorité par donnée, et son surcoût réel (4 écritures) est inférieur à celui de A (6 services + une
synchronisation permanente).

⚠️ **Mais Q1 est subordonnée à §2.6.** Si le propriétaire tranche que R2 civique se joue au grain
**thème**, B devient inutile et le coût tombe à zéro. **Trancher §2.6 avant Q1.**

## 2.2 Q2 — Le plan civique existant : superposition ou retrait du Leitner ?

### Ce que le Leitner pilote aujourd'hui, exactement

`service/plancivique/` — **11 fichiers, 1 454 lignes** (le brief disait 13 ; c'est 11).

| Fichier | Lignes | Rôle |
|---|---|---|
| `CivicPlanService` | 717 | le moteur complet |
| `CivicChangementsResolver` | 164 | le bloc « progression détectée » |
| `CivicLeitner` | 109 | les 5 boîtes, **pur et sans état** |
| `CivicPrioriteScorer` | 107 | l'ordre du plan |
| `CivicLeitnerResolver` | 94 | replie la boîte sur l'historique des réponses |
| `CivicDotation` | 68 | SERVABLE / CONTENU_INSUFFISANT / NON_APPLICABLE |
| `CivicMaitrise` | 68 | NON_EVALUEE / A_TRAVAILLER / EN_PROGRESSION / MAITRISEE |
| `CivicEtatCible` | 49 | l'état servi d'une cible |
| `CivicReponse` | 32 | la projection d'une réponse |
| `CivicEtapeEtat` | 24 | FRANCHIE / EN_COURS / A_VENIR |
| `CivicPlanGrain` | 22 | NOTION / THEME |

**Ce que le Leitner produit, et que rien d'autre ne produit :**

1. **L'état de maîtrise d'une notion** (`CivicMaitrise.of(réponses, boîte, dernièreCorrecte)`), avec
   son garde-fou « un thème n'est **jamais** maîtrisé » qui ne peut qu'**abaisser**.
2. **L'échéance de revue** (`CivicLeitner.echeance` : 0/1/3/7/21 jours), qui alimente la section
   « à revoir bientôt ».
3. **Le parcours visible en 5 crans** (`CivicLeitner.parcours`) — « c'est ce qui rend l'effet
   Leitner visible, sans jamais publier le numéro de boîte ».
4. **L'ordre du plan** (`CivicPrioriteScorer` + `ORDRE_DU_PLAN`), servi, jamais retrié par un front.
5. **Le tagging rétroactif** : rien n'est persisté, donc le jour où une question reçoit sa notion,
   **toutes** les réponses déjà données comptent pour elle. C'est ce qui a permis à la campagne du
   2026-09-11 de valoriser l'historique entier sans une seule migration de données.
6. **L'absence de job quotidien** : une échéance calculée à la lecture est franchie toute seule.

### Ce qui casserait s'il disparaissait

| Perte | Conséquence |
|---|---|
| `CivicMaitrise` | Plus aucun état pédagogique servi côté civique. **Les deux fronts en tiennent un miroir de libellés gelés** (`CIVIC_MAITRISE_LABEL` web, `civic_plan_labels.dart` mobile) : ils afficheraient du vide. |
| `prochaineRevue` + `aRevoir` | La section « à revoir bientôt » du Plan et de Réviser disparaît. |
| `CivicEtapeEtat` / `parcours` | Les 5 crans de progression d'une notion disparaissent. |
| Le tagging rétroactif | Un cycle persisté **naît vide** : les 44 examens blancs et 26 entraînements civiques déjà en base ne comptent plus. |
| `CivicDotation` | ⚠️ **Rien ne remplace ça**, et c'est le plus grave : c'est la **seule** autorité qui dit qu'une notion n'est pas au programme d'une mention. Sans elle, le cycle proposerait à un CSP 12 notions à 0 question. |

### Options

- **A — superposer** (le patron TCF, D-12) : le cycle est une **file persistée** de blocs de thème ;
  le plan dérivé continue de rendre la maîtrise, la dotation et l'échéance, que le cycle **lit**.
- **B — retirer le Leitner** : le cycle devient l'unique plan. Coût : réécrire les 6 productions
  ci-dessus dans le moteur de cycle, et accepter qu'un cycle persisté ne profite plus du tagging
  rétroactif.

### Recommandation

**A — superposer**, sans hésitation, et c'est **aussi** ce que recommande la spec (§5.3) et ce que
D-12 a tranché pour le TCF (« le cycle borné **se superpose** aux lots, il ne les remplace pas »).

Précision que l'audit ajoute : **`CivicDotation` doit devenir une dépendance explicite du cycle**,
pas un reste du plan dérivé. Une étape de cycle sur une notion `NON_APPLICABLE` est une étape que le
candidat ne pourra **jamais** clôturer — un cycle bloqué à vie.

**Coût** : faible. Le cycle appelle `CivicPlanService.calculer()` (déjà extrait, déjà partagé entre
deux lecteurs) au lieu de recalculer.

## 2.3 Q3 — Mises en situation : option A ou option B ?

### À la lumière des chiffres du §1.8

| Critère | Option A (type dans chaque bloc) | Option B (6ᵉ bloc transversal) |
|---|---|---|
| Fidélité à l'examen réel | ✅ 12/40 réparties | ❌ crée une unité qui n'existe pas |
| Répartition du stock | ✅ les 176 sont sur les 5 thèmes | ✅ indifférent |
| Case creuse | ⚠️ `CIV_PRINCIPES` × `CSP` = **1** | ✅ 176 suffisent largement |
| Tagging à une notion | ❌ **0 / 176**, et la règle de `seuilTagging` les **exclut** | ✅ pas besoin de notion |
| R2 applicable | ❌ une mise en situation n'a pas de notion ⇒ elle ne peut **clôturer** aucune étape de notion | ⚠️ il faudrait une unité travaillable, qui n'existe pas |
| Travail à faire | tenir le ratio 12/40 dans **3 chemins de tirage** (template, `composeCiviqueFullExam`, examen de thème) | créer un 6ᵉ bloc hors thème dans le moteur, à rebours de « le bloc **est** une thématique » |

### Le fait décisif, que la spec ne connaissait pas

🛑 **Les mises en situation ne portent pas de notion, et la règle du dépôt dit qu'elles n'en
porteront pas** (`CivicPlanProperties.seuilTagging` : « les mises en situation relèvent des domaines
`sit_*` et ne reçoivent pas de notion »). Donc :

- en **option A**, une mise en situation tombée dans une série ou un examen **ne fait avancer aucune
  étape** du cycle. Elle est du contenu que le cycle **ne sait pas compter** ;
- en **option B**, le 6ᵉ bloc n'a **aucune unité travaillable** : pas de notion, donc aucune
  `TRAIN_SKILL` possible. Le bloc serait un examen seul.

### Recommandation

**Option A, avec une restriction explicite** : la mise en situation est un **type de question
présent dans les examens** (de thème et global), où le ratio 12/40 doit être **tenu par le tirage**.
Elle n'entre **pas** dans les séries ciblées et ne clôt **aucune** étape de notion.

Motif : c'est le seul choix qui reste vrai à l'examen réel sans inventer une unité pédagogique que
le référentiel refuse. Et cela répond à l'invariant du dépôt : ce n'est pas une consigne, c'est le
`question_type` du tirage — une contrainte dure.

⚠️ **L'option A a une dette à nommer** : `CIV_PRINCIPES` × `CSP` = 1 mise en situation. Un examen de
thème CSP sur les Principes ne peut pas en contenir 6 (le prorata de 12/40 sur 20 questions). Deux
issues : produire ~5 mises en situation Principes/CSP, ou admettre que le ratio est un **objectif de
tirage, pas une garantie** (et le dire dans le code, pas dans un commentaire).

**Coût de l'option A** : 3 chemins de tirage à doter d'une contrainte de type, 1 autorité à créer
pour le ratio (qui est du **code**, comme `CivicExamFormat` — pas un réglage), ~5 questions à
produire pour la case creuse.

## 2.4 Q4 — Le format de l'examen de thème

**Réponse : 20 questions / seuil 16 / 20 minutes. Confirmé en base et en code.** Composition
**dynamique**, aucun `ExamTemplate`. Détail complet et preuves : **§1.9**.

Trois précisions que le brief demandait :

1. **L'audit TCF avait raison** en notant « aucun template thème » — il n'y en a aucun, et il n'en
   faut pas : la composition dynamique est le bon patron ici (elle suit la mention du candidat, ce
   qu'un template figé ne fait pas).
2. **Les 11 templates « Focus » à 40 questions ne sont pas des examens de thème.** Ne pas les
   confondre, ne pas les réutiliser, et se demander s'ils ont encore un emploi une fois le cycle
   livré (matrice incomplète, 5 cases manquantes sur 15).
3. 🛑 **Le format doit déménager.** 20/16/20 min sont des constantes privées d'`AttemptService`, et
   40/32 y vivent **en double** de `CivicExamFormat`. Le cycle civique fera de l'examen de thème sa
   **clôture de bloc** : il doit lire ce format chez une autorité unique.

**Recommandation** : étendre `CivicExamFormat` au format de thème
(`QUESTIONS_THEME = 20`, `SEUIL_REUSSITE_THEME = 16`, `DUREE_THEME`) et faire
`AttemptService` lire ces constantes au lieu des siennes, **dans la même passe** — pas plus tard.
Même traitement que `DureeEpreuve` : c'est du code, pas un réglage.

**Coût** : ~30 lignes, 1 fichier de test à étendre (`CivicExamFormatTest` existe), 6 constantes
supprimées d'`AttemptService`.

## 2.5 Q5 — Changement de mention en cours de cycle

### Ce que le code fait aujourd'hui

| Fait | Détail |
|---|---|
| Où vit la mention | `users.target_procedure` (`varchar(16)`, nullable) |
| **Historique** | 🛑 **Aucun.** Pas de table, pas de colonne d'audit, pas de trigger. Un changement **écrase** la valeur, sans trace. |
| Comment le plan la lit | `TargetProcedure.mentionCivique(user.getTargetProcedure())`, à **chaque lecture**. `null ⇒ CSP` (« le périmètre le plus étroit »). |
| Effet immédiat d'un changement | **Tout le plan civique change de pool à la lecture suivante.** Les dotations sont relues (`questionsParNotion(mention)`), donc une notion `SERVABLE` peut devenir `NON_APPLICABLE` du jour au lendemain. |
| Le code le sait-il ? | ✅ **Oui, et il s'en protège déjà** : `CivicPlanService.mettreEnForme` filtre `solides` par dotation, avec ce commentaire — « une cible maîtrisée puis devenue non servable — le candidat change de `targetProcedure`, et la notion n'a plus de question dans sa nouvelle mention — s'affichait comme un acquis ». |
| Côté TCF | `A27` (décisions autonomes) : « changer d'objectif ne détruit pas le cycle : son **niveau cible est mis à jour** ». `JourneyService.getOrCreate` fait exactement ça (l. 167-170). |

### Le blocage de schéma

🛑 **Le cycle ne peut pas porter une mention aujourd'hui.**

```
chk_journey_target_level  CHECK (target_level IN ('A2','B1','B2'))
chk_journey_entry_level   CHECK (entry_level IS NULL OR entry_level IN ('A2','B1','B2'))
chk_journey_exit_level    CHECK (exit_level  IS NULL OR exit_level  IN ('A2','B1','B2'))
```

`target_level` est `NOT NULL`. Un cycle civique n'a pas de niveau CECRL : son objectif **est** la
mention (CSP/CR/NAT), et le seuil de l'examen. Il faut soit une colonne `target_procedure` sur
`journey`, soit relâcher ces trois `CHECK` — et dans les deux cas décider ce que `entry_level` /
`exit_level` veulent dire côté civique (un **score**, pas un niveau).

### Options

- **A — historiser** (recommandation de la spec) : changement de mention ⇒ le cycle en cours est
  `HISTORISE`, un cycle neuf `EN_COURS` est amorcé sur le nouveau pool, le `EN_ATTENTE` est vidé.
- **B — conserver le cycle, changer le pool** (le patron TCF `A27`) : le cycle garde ses étapes, sa
  `target_procedure` est mise à jour, et les étapes devenues `NON_APPLICABLE` sont closes en
  `SUPERSEDED`.

### Faisabilité de A « sans perte » — la question exacte du brief

✅ **Oui, faisable sans perte, à deux conditions :**

1. Le cycle doit **porter sa mention** (colonne sur `journey`), sinon un cycle historisé ne dit pas
   sous quelle démarche il a été suivi — et l'historique devient illisible.
2. `journey.status` et ses deux index partiels (`uq_journey_en_cours`, `uq_journey_en_attente`) sont
   sur `(user_id, module)`, **pas** sur la mention : historiser puis recréer respecte déjà l'unicité,
   sans migration. ✅ Rien à changer là.

**Aucune donnée n'est perdue** : le contenu du cycle est dans `journey_step` / `journey_lot`, que
l'historisation ne touche pas. Et les **réponses** du candidat, elles, ne sont dans aucune des deux
options — elles sont dans `answers`, que le plan dérivé relit sans condition de mention.

### Recommandation

**A — historiser**, comme la spec le propose, **et** la nuancer : historiser sur un changement de
mention est cohérent (changer de démarche, c'est changer de programme — `CivicDotation` : « trois
programmes différents »), là où le TCF ne changeait que de **niveau** dans un même programme. Les
deux décisions ne se contredisent donc pas, mais **il faut le dire dans la décision**, sinon A27 et
la règle civique paraîtront incompatibles.

⚠️ **Et un garde-fou à poser** : le changement de mention étant **sans trace**, l'historisation est
la **seule** occasion d'écrire ce qui s'est passé. Si elle n'a pas lieu, la bascule CSP → NAT est
définitivement invisible.

**Coût** : 1 colonne + 1 point de branchement sur l'écriture de `target_procedure` (un seul,
`UserService` / profil) + la décision sur `entry_level` / `exit_level` civiques.

## 2.6 🛑 Q6 — *Question que la spec ne pose pas, et qui commande tout*

**À quel grain R2 se joue-t-il côté civique ?**

La spec (§2) reprend R2 « à l'identique, sans réinterprétation » : « une notion du cycle passe
`REUSSI` après 2 séries réussies (≥ 0,80) ou 4 séries terminées. **Ici la mesure est exacte, puisque
chaque question porte sa notion.** »

**La phrase est vraie, et la conclusion est fausse.** La mesure est exacte ; c'est le **contenu** qui
ne suffit pas (§1.6 : 1 couple sur 138). Et l'autorité de R2 n'existe pas côté civique :

| Fait | Preuve |
|---|---|
| R2 se lit chez **une seule** autorité | `JourneyReadService.etapesAuQuota()` (l. 559), partagée par la lecture et par l'écriture (`JourneyService.onTrainingProgress` l. 695) |
| Cette autorité lit `learning_plan_observations.status = SOLID` | `seriesDepuisLaCreation()` (l. 504) — « le verdict est **déjà écrit** […] on relit donc ce statut, **aucune 8ᵉ déclaration du seuil** » |
| Qui écrit ce `SOLID` ? | `ComprehensionObservationService`, à partir de `learning-plan.comprehension.solid-ratio: 0.80` |
| Écrit-il pour le civique ? | 🛑 **Non.** `chk_learning_plan_observation_source` n'admet que 9 sources, **toutes TCF** (`DIAGNOSTIC_EE/EO`, `PRODUCTION_EE/EO`, `MOCK_EXAM_EE/EO`, `SKILL_TRAINING`, `TCF_CO`, `TCF_CE`). |
| Le civique a-t-il un équivalent ? | **Non** — il n'écrit **rien** : `CivicLeitnerResolver` **replie** la boîte sur `answers` à chaque lecture. |

### Les options, par ordre de coût croissant

| Option | R2 devient | Contenu à produire | Ce qu'il faut coder |
|---|---|---|---|
| **α — grain THÈME** | « le bloc d'un thème se clôt sur son **examen de thème** (20 Q / 16) » ; les notions restent l'affaire du plan dérivé | **0** | le cycle porte `theme_id`, pas de notion ; **aucune** modification de `skills` ni de `learning_plan_observations` |
| **β — grain NOTION, quota abaissé** | « 1 série réussie, ou 2 terminées », sur une série dimensionnée au pool réel | **0** (mais séries de 5 à 10 items, variables) | Q1 option B + un écrivain d'observations civiques + un quota civique distinct |
| **γ — grain NOTION, R2 littérale** | inchangée | ≈ **1 480** | idem β, plus la campagne éditoriale |

### Recommandation

**α, et le dire comme une décision de produit, pas comme un repli technique.**

Trois raisons, dans l'ordre :

1. 🛑 **Le contenu ne porte pas γ**, et β ment sur ce qu'il mesure (« 2 séries réussies » sur 7
   questions, ce sont les mêmes 7 questions deux fois). Le dépôt a une règle pour ça :
   « **ce qui tient la qualité, ce sont les contraintes dures** » — et ici la contrainte dure, c'est
   le stock.
2. **Le grain thème est déjà l'unité du cycle** dans la spec elle-même : « Épreuve (CO, CE, EE, EO)
   → **Thématique** (T1→T5). C'est l'unité de bloc. » α fait simplement du **bloc** l'unité de
   clôture aussi, ce qui est cohérent avec « l'objectif est le seuil de l'examen » (§1 de la spec).
3. **Le travail de notion ne disparaît pas** : il reste dans le plan dérivé, qui le fait déjà bien,
   avec sa maîtrise, sa dotation et ses échéances. Le cycle **encadre** le travail, il ne le
   remplace pas — exactement la superposition de Q2.

⚠️ **Ce que α coûte** : le cycle civique perd les étapes `TRAIN_SKILL`, donc les blocs n'ont plus
qu'un examen. Il faut alors décider ce qui **débloque** l'examen d'un thème (D-15 côté TCF : « aucune
compétence restante dans le bloc »). Proposition à trancher : un **nombre de séries ciblées faites
sur le thème**, lu chez `CivicPlanService`, sans nouvelle table.

🛑 **C'est un écart au « le moteur civique ne réinvente aucune règle » du brief.** Il est donc
consigné comme **conflit**, au §5 (C-1), et **non appliqué**.

---

# 3. Inventaire technique

## 3.1 Schéma

**Prochain numéro de migration**

| Tranche | Dossier | Dernier | Prochain |
|---|---|---|---|
| Schéma | `db/migration/00_schema/` | `V067__schema_cycle_journey_et_freebie.sql` | **`V068`** |
| Référence | `db/migration/100_reference/` | `V114` | `V115` |
| **Contenu civique** | `db/migration/200_civique/` | `V295__corrections_factuelles.sql` | **`V296`** |
| Contenu TCF | `db/migration/300_tcf/` | (arbo par épreuve, max global `V878`) | — |

**Ce que `module` livré en P2 permet déjà** — et c'est plus que ce que le brief supposait :

| Acquis de V067 | Détail |
|---|---|
| `journey.module` | `varchar(16) NOT NULL DEFAULT 'TCF'`, `chk_journey_module CHECK (module IN ('TCF','CIVIQUE'))` ✅ **CIVIQUE est déjà admis** |
| `journey.status` | `EN_COURS` / `EN_ATTENTE` / `HISTORISE` ✅ |
| Unicité par module | `uq_journey_en_cours` et `uq_journey_en_attente`, index **partiels** sur `(user_id, module)` ✅ **rien à changer** |
| `journey.entry_level` / `exit_level` / `historise_at` | présents, avec `chk_journey_historisation` ✅ (mais bornés CECRL, cf. ci-dessous) |
| `idx_journey_user_module_status` | présent ✅ |
| `free_entitlement_usage` | table + `UNIQUE (user_id, code)` ✅ |

**Ce qui reste — les contraintes qui s'opposent à un cycle civique**

| # | Contrainte | Table | Ce qu'elle bloque |
|---|---|---|---|
| S-1 | `chk_journey_target_level CHECK (IN 'A2','B1','B2')` + `NOT NULL` | `journey` | un cycle civique n'a pas de niveau CECRL |
| S-2 | `chk_journey_entry_level` / `chk_journey_exit_level` | `journey` | un niveau d'entrée/sortie civique est un **score**, pas un palier |
| S-3 | `chk_journey_lot_exam_type CHECK (IN 'TCF_CO','TCF_CE','TCF_EO','TCF_EE')` | `journey_lot` | un lot de **thème** |
| S-4 | `chk_journey_step_exam_type` — mêmes 4 valeurs | `journey_step` | une étape de **thème** |
| S-5 | `journey_step.skill_id` FK → `skills` + `chk_journey_step_train_skill` (exige `skill_id NOT NULL`) | `journey_step` | une étape sur une **notion** ou un **thème** |
| S-6 | `chk_skills_section CHECK (IN 'EE','EO','CO','CE')` (+ 4 `NOT NULL`, + 3 autres `CHECK`) | `skills` | l'option A de Q1 |
| S-7 | `learning_plan_observations.skill_id` FK → `skills` `RESTRICT`, `NOT NULL` | `learning_plan_observations` | une observation sur une **notion** |
| S-8 | `chk_learning_plan_observation_source` — 9 valeurs, **aucune civique** | `learning_plan_observations` | R2 civique (§2.6) |
| S-9 | `chk_free_entitlement_code CHECK (IN 'EXAM_BLANC_EE','EXAM_BLANC_EO')` | `free_entitlement_usage` | « 1 examen de thème offert à vie » |
| S-10 | `uq_journey_step_lot_skill` (partiel `WHERE skill_id IS NOT NULL`) | `journey_step` | à étendre si l'étape porte autre chose qu'un `skill_id` |
| S-11 | `uq_journey_user_target` | ⚠️ **absente** de la base actuelle — V067 l'a déjà remplacée par les deux index partiels. Le brief la mentionne ; elle n'existe plus. |

Selon l'option retenue au §2.6 : **α** touche S-1 à S-4, S-9 et S-10 (**6 contraintes**) ;
**β/γ** y ajoutent S-5, S-7, S-8 (option B de Q1) ou S-6 (option A).

## 3.2 Métier

| Élément attendu | Existe | Chemin | Remarque |
|---|---|---|---|
| Diagnostic civique | ✅ | `service/diagnosticcivique/` — 4 fichiers | `CivicDiagnosticService`, `CivicDiagnosticComposer`, `CivicDiagnosticThemeResolver`, `CivicDiagnosticViewService`. Tunnel invité compris. Aucun coût LLM. |
| Format 28 + 12 du diagnostic | ✅ | `application.yaml` `sejourfr.civic-diagnostic` | `config-version: 1`, `min-par-theme: 4`, seuils 0,80 / 0,55, réévaluation 14 j |
| Plan civique | ✅ | `service/plancivique/` — **11** fichiers, 1 454 l. | 100 % dérivé. Détail : §2.2. Le brief disait 13. |
| `CivicExamFormat` | ✅ | `enums/CivicExamFormat.java` | 40 / 32 + `projection()`. ⚠️ **ne porte pas** le format de thème, et 40/32 est **dupliqué** dans `AttemptService` |
| Examen global 40 Q | ✅ | `AttemptService` l. 181-183 + `AttemptCompositionService.composeCiviqueFullExam` | stratifié 8 × 5 thèmes, `Collections.shuffle` |
| Examen de thème 20 Q | ✅ | `AttemptService` l. 69-71, 161-163, 176-179 | **dynamique**, `lot_theme_id` persisté. Détail : §1.9 |
| Verrou d'examen blanc | ✅ | `AttemptService.enforceMockExamSlotAccess` l. 484 | slot 1 offert **et rejouable**, slots 2+ premium |
| `GET /api/me/civic-plan` | ✅ | `CivicPlanController` l. 31, 49 | + `POST /cibles/{cibleId}/serie` l. 64 |
| Série ciblée | ✅ | `CivicPlanService.demarrerSerie` | `TRAINING` ordinaire, **premium opposable** (403), grain client **ignoré** (le serveur recalcule) |
| `CivicNotionService` + admin | ✅ | `service/CivicNotionService.java`, `controller/AdminCivicNotionController.java` | référentiel éditable |
| Moteur de cycle | ✅ | `service/journey/` — 13 fichiers, 3 210 l. | **TCF-only** : cf. ci-dessous |
| Un `journey` civique | ❌ | `JourneyService.getOrCreate` l. 156-182 | 🛑 **`Module.TCF` en dur** (l. 164, 177) **et** sortie sèche si `TargetProcedure.niveauVise(...)` rend `null` — un candidat civique sans `target_level` CECRL n'aura **jamais** de cycle |
| L'axe des blocs | ⚠️ | `JourneyBlocResolver` l. 72-84 | 🛑 l'autorité est **`TcfDomainProfileDto.ORDRE`** — 4 `EpreuveType` en dur, « autorité unique et **non configurable** » (D-9, D-20). Un axe « 5 thèmes » est une **donnée**, pas un enum : c'est le changement le plus profond du chantier. |
| L'autorité de R2 | ⚠️ | `JourneyReadService.etapesAuQuota` l. 559 | lit `learning_plan_observations.status = SOLID`. **Aucun équivalent civique.** Détail : §2.6 |
| `TcfJourneyConfig` | ✅ | `service/journey/TcfJourneyConfig*.java` + `plan/tcf-journey-config-v2.json` | `trainSeriesQuota`, `trainSeriesFallbackQuota: 4`, `maxPrioritiesPerLot: 3`, loader validant. **Aucun pendant civique.** |
| Branchement post-évaluation | ✅ | D-24 : 4 points | `doFinish` après `recordProgression`, la **sortie anticipée EE/EO**, `buildAndPersistCecrlIfReady`, et `lockProductionSubAttempts` **exclu**. ⚠️ Les 3 premiers sont TCF ; **le civique passe par `doFinish`** — 1 point suffit, mais il faut le vérifier pour l'examen de thème **et** le global. |
| `attempts.lot_theme_id` | ✅ | index `idx_attempts_user_lot_civique` | ✅ **R1 est faisable** : le thème d'un examen est connu |
| Historique par thème | ✅ | `AttemptRepository.findByUserFiltered` l. 76 | `GET /api/me/attempts?type=MOCK_EXAM&module=CIVIQUE&themeId=…` |
| Historique de mention | ❌ | — | `users.target_procedure` écrasé sans trace. Détail : §2.5 |
| Un ratio 12/40 tenu au tirage | ❌ | — | Détail : §1.8 |

## 3.3 Freemium

**Ce qui est ouvert au gratuit côté civique, aujourd'hui**

| Élément | État réel | Où |
|---|---|---|
| Diagnostic civique | ✅ gratuit, tunnel invité compris | `PublicCivicDiagnosticController` |
| Examen blanc civique (global **ou** de thème) | ✅ **slot 1 offert ET REJOUABLE À VOLONTÉ** ; slots 2+ → `hasCivique` | `AttemptService.enforceMockExamSlotAccess` l. 484-496 |
| Template `civique-decouverte` | ✅ `is_free = true`, 40 Q, tirage **déterministe** pour un non-abonné | `exam_templates` + `composeFromTemplate(deterministic)` |
| Travailler une notion depuis le Plan | ❌ **premium sans exception**, opposable **403** | `CivicPlanService.demarrerSerie` l. 77-81 |
| Entraînement libre | ⚠️ `TRAINING` en mode démo : série **déterministe**, taille plafonnée `FREE_TRAINING_MAX_SIZE` | `AttemptService` l. 153, 194-211 |
| Lecture du Plan | ✅ entière | `CivicPlanPanel` / `civic_plan_view` |

✅ **Bonne nouvelle : le Plan civique est déjà conforme à D-18** (« lisible mais inexécutable »,
premium sans exception). Rien à révoquer de ce côté, contrairement au TCF où il a fallu fermer
`SkillAccessService`.

**Ce que le ledger `free_entitlement_usage` couvre déjà — et ce qu'il ne couvre pas**

| Acquis | Manquant pour « 1 examen de thème offert à vie » |
|---|---|
| ✅ La table, `UNIQUE (user_id, code)`, `source_attempt_id` FK `ON DELETE SET NULL` | 🛑 `chk_free_entitlement_code` n'admet que `EXAM_BLANC_EE` / `EXAM_BLANC_EO` (**S-9**). Il faut un code civique. |
| ✅ L'écriture idempotente : `FreeEntitlementUsageManager.consommer` **avale** la violation d'unicité et rend un booléen (A30) | 🛑 `FreeEntitlementCode.pourExamenBlanc(EpreuveType)` prend une **épreuve TCF**. `EpreuveType.CIVIQUE` n'a pas de code. |
| ✅ La règle « un abonné ne consomme rien » | ⚠️ `consommerApresAnalyse` teste `subscriptionService.hasTcf(userId)` — il faudra `hasCivique` pour le civique. |
| ✅ La règle « abandon / expiration / échec ⇒ non consommé » | 🛑 **Le point d'écriture est `consommerApresAnalyse(submissionId)`, appelé par `ProductionPipelineAsyncRunner` après une `AiEvaluation`.** Le civique **n'a aucune analyse** : il faut un **second point d'écriture**, sur l'examen **terminé et corrigé** (QCM ⇒ la correction est immédiate et déterministe). |
| ✅ `analyseOffertePossible(user, epreuve, attemptId)` — « les 2 tâches restantes du même attempt sont dues » | ⚠️ Sans objet côté civique : un examen de thème est **un** attempt, pas 3 tâches. La logique se simplifie. |
| — | 🛑 **« au choix du candidat » n'est pas modélisé.** `UNIQUE (user_id, code)` impose **un** code. Modélisation qui marche : **un seul** code (p. ex. `EXAM_BLANC_CIVIQUE_THEME`) et le thème choisi lu sur `source_attempt_id → attempts.lot_theme_id`. **Ne pas** créer 5 codes par thème, ce serait 5 gratuités. |

🛑 **Et le conflit central du freemium civique** : la spec dit « 1 examen blanc de thème, **une fois à
vie** ». Le code dit « slot 1 offert **et rejouable** ». Ce sont deux règles différentes, sur le même
geste. Consigné en C-2 (§5).

⚠️ **Point d'attention qu'on ne peut pas ignorer** : le template `civique-decouverte` est
`is_free = true` à **40 questions** (l'examen **global**), alors que la spec met l'examen global en
**premium**. Troisième règle sur le même écran. Consigné en C-3.

**Billing** : ✅ rien à créer. `ModuleAccess` est déjà `NONE < CIVIQUE < INTEGRAL`,
`SubscriptionService.hasCivique()` existe, `assertModuleAtLeast` gère la prolongation.

## 3.4 Fronts

| Élément attendu | Existe | Chemin | Remarque |
|---|---|---|---|
| Écran Plan civique (web) | ✅ | `web_sejoufr/app/_components/plan/CivicPlanPanel.tsx` — **497 l.** | monté par `PlanModules.tsx` l. 182 |
| Écran Plan civique (mobile) | ✅ | `mobile_sejourfr/lib/screens/plan/civic_plan_view.dart` — **536 l.** | miroir |
| Types / modèles | ✅ | `web_sejoufr/lib/civic-plan.ts` (233 l.) ⇄ `mobile_sejourfr/lib/core/models/civic_plan_models.dart` (474 l.) | + libellés gelés `civic_plan_labels.dart` |
| Lanceur de série | ✅ | `plan/useCivicSerie.ts` ⇄ `plan/civic_serie_launcher.dart` | un **seul** point de départ (commenté dans `dashboard/page.tsx` l. 626) |
| Toggle de module | ✅ | `ModuleToggle` + `?module=` dans l'URL | `PlanModules.tsx` — **une seule autorité de sélection**, déjà réglé le 2026-09-12 |
| Les deux écrans passent par le kit | ✅ | `SejourKit.tsx` ⇄ `sejour_kit.dart` | ✅ conforme à l'invariant du `CLAUDE.md` racine |

**Les primitives du cycle existent des deux côtés** (livrées en P5) :

| Web (`SejourKit.tsx`) | Mobile (`sejour_kit.dart`) | Réutilisable tel quel pour un bloc de thème ? |
|---|---|---|
| `CycleProgress` (l. 1999) | `SfCycleProgress` (l. 4585) | ✅ **oui** — barre + « X sur Y » + repère de cycle, rien de TCF |
| `BlocAccordion` (l. 2071) | `SfBlocAccordion` (l. 4714) | ⚠️ **presque** — attend une **initiale d'épreuve** (CO/CE/EE/EO). Un thème n'a pas d'initiale à 2 lettres ; la spec civique dit « thème + nom complet de la thématique ». À étendre **dans les deux kits dans la même passe**. |
| `ExamStepBox` (l. 2148) | `SfExamStepBox` (l. 4905) | ✅ **oui** — `VERROUILLÉ` / `DISPONIBLE` + phrase de condition |
| `NextStepCard` (l. 2203) | `SfNextStepCard` (l. 5013) | ✅ **oui** — carte finale à 2 actions |
| `Pill` (l. 1968) | *(miroir existant)* | ✅ |

**Ce que les écrans civiques utilisent aujourd'hui** : `Card`, `Cta`, `DoneRow`, `LockItem`,
`LockList`, `NowCard`, `Pad`, `PillMeta`, `Pills`, `Prio`, `Section`, `Stack`, `ThemeLine`, `Top` —
c'est-à-dire l'**ancienne** grammaire (la file plate + les 3 priorités), pas celle du cycle.

**Écart avec les blocs de thème attendus** : la section « Cycle en cours » n'existe pas côté civique.
Elle remplacera `CIVIC_PLAN_PRIORITIES_TITLE` + `CIVIC_PLAN_REVIEW_TITLE` (les 3 priorités et
« à revoir »), en réutilisant 4 primitives sur 5 sans y toucher.

🛑 **Refonte = suppression immédiate de l'ancien** : les libellés `CIVIC_PLAN_PRIORITIES_TITLE`,
`civicPlanAutresLabel`, `CIVIC_PLAN_REVIEW_TITLE`, `civicRevueLabel` et leurs miroirs Dart partent
dans la même passe, **s'ils n'ont plus de lecteur**. À vérifier : `CivicPath` / `civicPath` /
`civicPathCounter` servent aussi l'écran Réviser.

⚠️ **Pas de nouveau test sur les fronts** (invariant du `CLAUDE.md` racine, arbitré le 2026-09-10).
Vérification : `npx tsc --noEmit` + `npm run build` + `flutter analyze`. Les tests existants
(16 TS + 23 Dart) doivent rester verts ; un test rendu rouge par un changement voulu se **met à
jour**, il ne bloque pas.

## 3.5 Tests

**Volume backend** : **259** `*Test` + **142** `*IT`.

**Couverture civique existante — 13 fichiers**

| Fichier | Nature |
|---|---|
| `service/CivicNotionServiceIT.java` | IT |
| `service/CivicTaggingVerdictIT.java` | IT — les triggers de verdict |
| `service/diagnosticcivique/CivicDiagnosticServiceIT.java` | IT |
| `service/diagnosticcivique/CivicDiagnosticGuestIT.java` | IT — tunnel invité |
| `service/diagnosticcivique/CivicDiagnosticThemeResolverTest.java` | unitaire |
| `service/diagnosticcivique/CivicExamFormatTest.java` | unitaire ✅ **à étendre pour le format de thème** |
| `service/plancivique/CivicPlanServiceIT.java` | IT |
| `service/plancivique/CivicPlanNotionParcoursIT.java` | IT — **le grain NOTION est déjà couvert** |
| `service/plancivique/CivicChangementsResolverTest.java` | unitaire |
| `service/plancivique/CivicDotationTest.java` | unitaire |
| `service/plancivique/CivicLeitnerParcoursTest.java` | unitaire |
| `service/plancivique/CivicLeitnerResolverTest.java` | unitaire |
| `service/plancivique/CivicPrioriteScorerTest.java` | unitaire |

**Fixtures réutilisables** (`src/test/java/com/sejourfr/app/support/TestData.java`)

| Fabrique | Ligne | Civique ? |
|---|---|---|
| `theme(Module.CIVIQUE, …)` | 244 | ✅ |
| `question(...)` avec `setModule(CIVIQUE)` | 281 | ✅ |
| `attempt(...)` avec `setModule(CIVIQUE)` + `setEpreuve(EpreuveType.CIVIQUE)` | 325-326 | ✅ |
| `journey(user, Module, JourneyStatus, TargetLevel)` | 1236-1240 | ⚠️ prend déjà un `Module`, **mais exige un `TargetLevel` CECRL** (S-1) |

**Fabriques manquantes**

1. 🛑 `civicNotion(theme, code, label, …)` — **absente**. Les IT de `plancivique` créent leurs
   notions à la main. À extraire (2ᵉ occurrence = signal, règle du dépôt).
2. `journeyCivique(user, TargetProcedure, JourneyStatus)` — dépend de la levée de S-1.
3. `freeEntitlement(user, code, attempt)` — le ledger n'a pas de fabrique.
4. Une fabrique de **lot de questions par notion et par mention** : les tests de dotation ont besoin
   de « N questions sur cette notion dans cette mention », c'est le cœur de §1.6.

**Infra** : Postgres embarqué **Zonky** (pas Docker), vraies migrations Flyway,
`AbstractIntegrationTest` + `TestData`. Conventions et gabarits : `docs/plan-tests-backend.md`.
✅ Rien à installer.

**Obligation** : « Backend : tests dans la même passe » (invariant racine). Migration à impact
logique, règle métier, endpoint ⇒ test(s) qui verrouillent le comportement.

---

# 4. Écarts bloquants, classés par gravité

## Bloquants — le chantier ne peut pas démarrer sans arbitrage

| # | Écart | Pourquoi c'est bloquant |
|---|---|---|
| **E-1** | 🛑 **R2 n'est pas applicable au grain (notion × mention)** : 1 couple sur 138 porte 20 questions, 23 sont à zéro (§1.6) | C'est la règle centrale du cycle. Aucune ligne de code ne peut s'écrire avant que §2.6 soit tranché : **α** ne touche ni `skills` ni `learning_plan_observations`, **β/γ** les touchent tous les deux. Le périmètre du chantier **double** selon la réponse. |
| **E-2** | 🛑 **Aucune autorité de R2 côté civique** : `etapesAuQuota` lit `learning_plan_observations.status = SOLID`, que rien n'écrit pour le civique, et dont le `CHECK` de source n'admet aucune valeur civique (S-8) | Sous β/γ, il faut créer un **écrivain d'observations civiques**. Ce serait une **seconde autorité de maîtrise** à côté de `CivicLeitnerResolver` — le défaut le plus cher du dépôt. Sous α, la question disparaît. |
| **E-3** | 🛑 **L'axe des blocs est un enum en dur** : `TcfDomainProfileDto.ORDRE`, « autorité unique et **non configurable** » (D-9, D-20), 4 `EpreuveType` | Un bloc civique est un **thème** : une ligne de `themes`, un `UUID`, pas une valeur d'enum. `journey_lot.exam_type` et `journey_step.exam_type` sont des `varchar` `CHECK`és sur 4 valeurs TCF (S-3, S-4). Il faut décider **comment un bloc désigne son thème** avant d'écrire la migration. |
| **E-4** | 🛑 **`journey.target_level` est `NOT NULL` et `CHECK`é CECRL** (S-1), et `getOrCreate` sort à sec si `niveauVise(...)` est `null` | Un candidat **purement civique** (CSP déclaré, aucun `target_level`) n'obtiendra **jamais** de cycle. C'est le cas d'usage majoritaire du module. |
| **E-5** | 🛑 **Le ledger de gratuité est façonné pour une analyse IA** : `chk_free_entitlement_code` (S-9), `FreeEntitlementCode.pourExamenBlanc(EpreuveType)`, point d'écriture `consommerApresAnalyse(submissionId)` | « 1 examen de thème offert à vie » n'a **aucun** chemin d'écriture. Il faut un code, un `CHECK` ouvert, et un second point de consommation sur « examen terminé et corrigé ». |

## Graves — à trancher avant l'écran, pas avant la migration

| # | Écart | Détail |
|---|---|---|
| **E-6** | **Le format de l'examen de thème n'a pas d'autorité** : 20/16/20 min en constantes privées d'`AttemptService` (l. 69-71), et 40/32 **dupliqués** de `CivicExamFormat` (l. 63-65) | Le cycle en fera sa clôture de bloc. Une 3ᵉ copie apparaîtra si on ne range pas maintenant. §2.4 |
| **E-7** | **Aucun tirage ne tient le ratio 12/40 de mises en situation** : 3 chemins, tous avec `questionType = null` ; les 20 `exam_template_rules` civiques ont `question_type` à `NULL` | L'option A du §3.1 de la spec **décrit une fonctionnalité qui n'existe pas**. §1.8 |
| **E-8** | **176 mises en situation (18 % du stock) sont invisibles du moteur** : 0 notion, 0 suggestion, exclues du dénominateur de `seuilTagging` | Elles ne peuvent faire avancer aucune étape. Il faut **dire** ce qu'elles font dans le cycle. §2.3 |
| **E-9** | **`CIV_PRINCIPES` × `NAT` = 20 questions exactement** ; `× CSP` = 25, avec **1** mise en situation | Un examen de thème de 20 Q **épuise le pool** NAT : aucun rejeu qui ne redonne pas les mêmes items. §1.7 |
| **E-10** | **Aucun historique de mention** : `users.target_procedure` est écrasé sans trace | L'historisation du cycle est la **seule** occasion de consigner une bascule CSP → NAT. §2.5 |

## Moyens — à corriger dans la passe, sans arbitrage

| # | Écart | Correctif |
|---|---|---|
| **E-11** | **46 notions actives, la doc dit 40** (spec §1, brief §2.1) | Corriger la spec et le brief. §1.5 |
| **E-12** | **`CivicPlanProperties.seuilTagging` documente un état périmé** (« 0 question sur 1 016 est taguée — les cinq thèmes sont donc au grain THEME »). C'est l'inverse depuis le 2026-09-11 ; le commentaire est **répété 3 fois** : POJO, `application.yaml`, `CivicPlanService` javadoc | Mettre à jour les 3. §1.3 |
| **E-13** | **`CivicPlanRepository.questionsParNotion()` / `questionsParTheme()` filtrent `is_active` sans filtrer `status`** | Inoffensif (0 `DRAFT`/`ARCHIVED` civique), faux au premier brouillon. §1.1 |
| **E-14** | **17 connaissances actives non taguées** : 3 `REJECTED`, 1 `VALIDATED` sur `notion_id` nul, le reste sans verdict | Reliquat de revue, **sans appel LLM** : les 17 se taguent à la main. §1.10 |
| **E-15** | **Les 11 templates « Focus » à 40 Q sont une matrice incomplète** (5 cases sur 15 manquantes) et ne sont **pas** les examens de thème du cycle | Décider de leur sort : les compléter, les retirer, ou les laisser hors du cycle. §1.9 |
| **E-16** | **`plancivique/` compte 11 fichiers, le brief en annonce 13** | Corriger le brief. §2.2 |
| **E-17** | **Le brief cite `uq_journey_user_target` comme contrainte gênante** — elle n'existe plus, V067 l'a remplacée par les 2 index partiels | Aucun travail. §3.1 S-11 |
| **E-18** | **`CivicDotation` n'est pas une dépendance déclarée du cycle** | Une étape sur une notion `NON_APPLICABLE` est une étape inclôturable à vie. §2.2 |
| **E-19** | **Pas de fabrique de test `civicNotion(...)`** ; les IT les créent à la main (≥ 2 occurrences) | Extraire dans `TestData`. §3.5 |

---

# 5. Conflits avec les décisions TCF déjà datées

🛑 **Options de résolution recommandées, non appliquées.**

## C-1 — R2 au grain notion (spec civique §2) ⇄ le contenu réel

| | |
|---|---|
| **Ce que dit la décision en vigueur** | D-16, 2026-09-18 : « une étape `TRAIN_SKILL` de compréhension se clôt après **2 séries réussies**, ou après **4 séries terminées** ». Spec civique §2 : « Reprendre **à l'identique**, sans réinterprétation. […] Ici la mesure est exacte, puisque chaque question porte sa notion. » |
| **Ce que dit la base** | 1 couple (notion × mention) sur 138 porte 20 questions. 23 sont à zéro. Le seuil de servabilité est **5**, la moitié d'une série. |
| **Nature du conflit** | La règle est reprise correctement ; c'est sa **précondition de contenu** qui est fausse. Le brief interdit tout écart (« le moteur civique **ne réinvente aucune règle** ») — donc l'écart se **signale**, il ne s'applique pas. |
| **Options** | **α** grain THÈME (0 question à produire) · **β** grain notion à quota abaissé (0 question, mais mesure faible) · **γ** R2 littérale (≈ **1 480** questions) |
| **Recommandation** | **α**, et **consignée comme un arbitrage de produit daté**, pas comme un repli. Elle est cohérente avec la spec civique elle-même (« la thématique est l'unité de bloc », « l'objectif est le seuil de l'examen »). |

## C-2 — « 1 examen de thème une fois à vie » ⇄ « slot 1 offert et rejouable »

| | |
|---|---|
| **Décision en vigueur** | Spec TCF §7 : « Examens QCM CO / CE : **inchangé** — slot 1 offert **et rejouable** (`enforceMockExamSlotAccess`) ». D-17. |
| **Spec civique §3.3** | « 1 examen blanc de thème, **une fois à vie**, au choix du candidat ». « Même règle de consommation que le TCF : le droit n'est consommé qu'à l'examen **terminé et corrigé**. » |
| **Nature du conflit** | Le civique **est** du QCM. La spec civique croit reprendre la règle TCF ; elle en applique en réalité celle des **productions** (freebie à vie, ledger), qui n'a jamais gouverné un QCM. Le code, lui, applique la règle QCM : `enforceMockExamSlotAccess` vaut déjà pour les examens de thème. |
| **Options** | **A** le civique suit la règle QCM (slot 1 rejouable, pas de ledger) — 0 ligne de code, 0 migration, mais la spec §3.3 est révoquée · **B** le civique suit la règle des productions (ledger, une fois à vie) — S-9 + un code + un point de consommation, et `enforceMockExamSlotAccess` devient une **seconde** règle sur le même geste |
| **Recommandation** | **B**, mais **en retirant `enforceMockExamSlotAccess` du chemin civique dans la même passe** — sinon deux verrous coexistent sur le même bouton, et c'est le patron qui a produit les 4 implémentations ad hoc de « première fois gratuite » que D-17 a dû rassembler. |

## C-3 — L'examen global est premium ⇄ `civique-decouverte` est `is_free`

| | |
|---|---|
| **Spec civique §3.3** | « Examen blanc global : ❌ **premium** » |
| **La base** | `exam_templates` : `civique-decouverte`, 40 Q, seuil 32, **`is_free = true`, `is_published = true`**, sous-titre « **40 questions · 45 min · Tous parcours · Gratuit** » |
| **Nature du conflit** | Ce n'est pas un écart de code, c'est une **promesse affichée** au candidat. La retirer est une régression visible de l'offre. |
| **Options** | **A** retirer `is_free` / dépublier le template · **B** garder l'examen global découverte gratuit et corriger la spec · **C** faire de l'examen **global** le freebie à vie, au lieu de l'examen de thème |
| **Recommandation** | **B** — corriger la spec. Un examen blanc global gratuit est l'argument de conversion du module civique, symétrique du diagnostic rapide TCF, et il ne coûte **rien** (QCM déterministe, 0 LLM). Le fermer pour se conformer à une phrase de spec serait payer une régression commerciale pour une cohérence de document. ⚠️ **Décision du propriétaire, pas de l'audit.** |

## C-4 — Historiser sur changement de mention ⇄ A27 « changer d'objectif ne détruit pas le cycle »

| | |
|---|---|
| **Décision en vigueur** | `A27` (décisions autonomes, 2026-09-18) : « Changer d'objectif **ne détruit pas** le cycle : son niveau cible est mis à jour ». Implémenté : `JourneyService.getOrCreate` l. 167-170. |
| **Spec civique §5.6** | « un changement de mention (CSP → NAT) : recommandation **historiser** » |
| **Nature du conflit** | **Apparent seulement.** Côté TCF, changer d'objectif change de **niveau dans un même programme** (mêmes compétences, même contenu). Côté civique, changer de mention change de **programme** : `CivicDotation` l'a mesuré (« CSP, CR et NAT ne sont pas trois niveaux du même programme, ce sont **trois programmes différents** » ; 12 notions n'existent pas pour un CSP). |
| **Recommandation** | Historiser, **et écrire la distinction dans la décision** : « A27 vaut pour un changement de **niveau** ; un changement de **programme** historise ». Sans cette phrase, les deux règles paraîtront incompatibles à la prochaine lecture. |

## C-5 — « Le civique sort du chantier » (D-23) ⇄ ce chantier

| | |
|---|---|
| **Décision en vigueur** | D-23, 2026-09-18 : « **Civique : sort du chantier.** Le moteur est livré **TCF d'abord**. Le plan civique reste dérivé (Leitner). » Et REPONSES §1 Q13 : « **Non.** Le civique **sort** de ce chantier. » |
| **La situation** | Le TCF est **livré** (`REPRISE-CHANTIER-CYCLE-PLAN.md` : « ✅ CHANTIER LIVRÉ le 2026-09-19 », 7 commits, `./mvnw verify` 3 048 + 1 345, 0 échec). Le civique est **P8**, et ce brief l'ouvre. |
| **Nature du conflit** | **Aucun, formellement** : D-23 disait « TCF **d'abord** », la condition est remplie. Mais D-23 dit aussi « le plan civique **reste dérivé** (Leitner) », ce que la superposition (§2.2) respecte et qu'un retrait du Leitner violerait. |
| **Recommandation** | Ouvrir P8 par une décision datée qui **lève explicitement** D-23 sur le seul point du périmètre, et **maintient** « le plan civique reste dérivé ». Ne pas laisser D-23 en l'état : une décision qui dit « sort du chantier » et un chantier qui tourne, c'est la 4ᵉ contradiction ouverte du dépôt. |

## C-6 — Pas de config civique (spec TCF §9) ⇄ le civique en a déjà une

| | |
|---|---|
| **Décision en vigueur** | Spec TCF §9 : le bloc `civique.{seuil_examen, nb_questions_examen}` est **supprimé** de la configuration — « `CivicExamFormat` : c'est du code, pas un réglage ». `cycle-config-v1.json` **n'a pas été créé**. |
| La base | ✅ Respecté : 40/32 sont du code. ⚠️ Mais `sejourfr.civic-plan` **existe** en configuration, avec 6 clés dont **`questionsParSerie: 10`** et **`questionsMinParNotion: 5`** — les deux nombres qui décident si R2 est applicable (§1.6). |
| **Nature du conflit** | Pas une contradiction : deux natures différentes. Le **format de l'épreuve** est une règle (code) ; les **plafonds du plan** sont des réglages (YAML), et leur javadoc l'argumente (« le plan est un dérivé relu à chaque lecture, rien ne se réinterprète rétroactivement »). |
| **Recommandation** | Ne **rien** déplacer, et **noter** que si α est retenu, `questionsParSerie` et `questionsMinParNotion` restent des réglages du **plan dérivé** — et que le **cycle** n'en lit aucun. Une clé lue par les deux deviendrait une règle partagée entre un dérivé et un persisté : c'est là que les divergences naissent. |

---

# 6. Questions fermées restantes — formulées en oui / non

🛑 **Ordre imposé : Q-F1 commande le périmètre. Les autres en dépendent.**

## Le grain — à répondre en premier

| # | Question | Effet d'un **oui** | Effet d'un **non** |
|---|---|---|---|
| **Q-F1** | Le bloc de thème civique se clôt-il sur **son seul examen de thème** (20 Q / 16), sans étape de notion dans le cycle — option **α** ? | Périmètre **réduit** : 6 contraintes de schéma, aucune modif de `skills` ni de `learning_plan_observations`, 0 question à produire | On passe à Q-F2 |
| **Q-F2** | *(si Q-F1 = non)* Acceptez-vous que « 2 séries réussies » porte sur des séries **qui rejouent les mêmes questions** (7 items en moyenne, 5 au minimum) — option **β** ? | Périmètre **étendu** : Q1 option B + un écrivain d'observations civiques (**E-2**) + un quota civique distinct | On passe à Q-F3 |
| **Q-F3** | *(si Q-F2 = non)* Autorisez-vous une **campagne éditoriale de ≈ 1 480 questions** avant le cycle civique — option **γ** ? | Le chantier attend la campagne | **Aucune option ne reste** : il faut réécrire R2 pour le civique |

## Le schéma

| # | Question | Oui / Non |
|---|---|---|
| **Q-F4** | `journey` reçoit-il une colonne **`target_procedure`** (CSP/CR/NAT) plutôt que de relâcher `chk_journey_target_level` ? | Oui ⇒ `target_level` reste CECRL et devient nullable pour le civique ; Non ⇒ un seul champ porte deux échelles |
| **Q-F5** | `journey.entry_level` / `exit_level` accueillent-ils un **score civique** (« 29 / 40 ») en réinterprétant les colonnes ? | Non recommandé (deux sens dans une colonne). Alternative : `entry_score` / `exit_score` |
| **Q-F6** | Un bloc civique désigne-t-il son thème par une **FK `theme_id`** plutôt que par un `varchar` `CHECK`é comme `exam_type` ? | Oui recommandé : un thème est une donnée de `themes`, pas une valeur d'enum |
| **Q-F7** | Adoptez-vous l'**option B de Q1** (observation polymorphe) plutôt que l'option A (généraliser `skills`) ? | Sans objet si Q-F1 = oui |

## Le freemium

| # | Question | Oui / Non |
|---|---|---|
| **Q-F8** | Le freebie civique est-il un **seul code** (`EXAM_BLANC_CIVIQUE_THEME`), le thème choisi étant lu sur `source_attempt_id → attempts.lot_theme_id` ? | Oui recommandé. Non ⇒ 5 codes = 5 gratuités |
| **Q-F9** | `enforceMockExamSlotAccess` est-il **retiré du chemin civique** quand le ledger le remplace (C-2) ? | Oui recommandé : sinon deux verrous sur le même bouton |
| **Q-F10** | Le template `civique-decouverte` (40 Q, `is_free`) **reste-t-il gratuit**, la spec §3.3 étant corrigée (C-3) ? | Décision commerciale du propriétaire |
| **Q-F11** | Le freebie se consomme-t-il sur « examen **terminé et corrigé** » — pour un QCM, la fin de l'attempt avec son score ? | Oui recommandé : c'est l'équivalent exact de « analyse rendue » pour un contenu déterministe |

## Le contenu

| # | Question | Oui / Non |
|---|---|---|
| **Q-F12** | Les **176 mises en situation** restent-elles **sans notion**, réservées aux examens, ne clôturant aucune étape (option A restreinte, §2.3) ? | Oui recommandé |
| **Q-F13** | Le ratio **12/40** devient-il une contrainte **dure du tirage** (contrainte de type sur les 3 chemins), et non une consigne ? | Oui recommandé (ordre de préférence du `CLAUDE.md` racine : le schéma avant la consigne) |
| **Q-F14** | Les **17 connaissances non taguées** sont-elles taguées **à la main** dans cette passe ? | Oui recommandé — **aucun appel LLM**, donc aucun coût |
| **Q-F15** | Produisez-vous ~**5 mises en situation `CIV_PRINCIPES` × `CSP`** (la seule case creuse) ? | Sinon le ratio 12/40 est inatteignable sur ce couple |
| **Q-F16** | L'**examen de thème** accepte-t-il d'épuiser le pool `CIV_PRINCIPES` × `NAT` (20 sur 20, aucune variation entre deux passages) ? | Non ⇒ produire ~20 questions Principes/NAT |

## Le rangement

| # | Question | Oui / Non |
|---|---|---|
| **Q-F17** | `CivicExamFormat` accueille-t-il le format de thème (20 / 16 / 20 min), `AttemptService` perdant ses 6 constantes privées, **dans cette passe** (E-6) ? | Oui recommandé : le cycle en fera une 3ᵉ copie sinon |
| **Q-F18** | Un changement de **mention** historise-t-il le cycle (§2.5 option A), avec la distinction A27 écrite dans la décision (C-4) ? | Oui recommandé |
| **Q-F19** | Ouvre-t-on P8 par une décision datée qui **lève D-23** sur le périmètre et **maintient** « le plan civique reste dérivé » (C-5) ? | Oui recommandé |
| **Q-F20** | Les 11 templates « Focus » à 40 Q (matrice incomplète) sortent-ils du périmètre du cycle, sans être ni complétés ni retirés ? | Oui = dette assumée et nommée |

---

# 7. Découpage proposé

⚠️ Périmètre indicatif. **Aucune phase n'est ouverte.** Les points **STOP** sont des arrêts durs :
on livre, on vérifie, on attend le go.

## P8.0 — Arbitrages (aucun code)

Répondre à **Q-F1 → Q-F20**. Consigner dans `docs/decisions/plan-parcours-tcf.md` à la suite de
**D-24** (une décision par arbitrage, datée), et lever **D-23** sur le périmètre (C-5). Mettre
`SPEC_cycle_plan_civique.md` en conformité : §1 (46 notions, pas 40), §2 (R2 selon Q-F1), §3.1
(l'option A ne décrit pas l'existant), §3.3 (freemium selon C-2 et C-3), §5 (les 6 points tranchés).

🛑 **STOP** — le périmètre de P8.1 **double** selon Q-F1. Ne pas écrire de migration avant.

## P8.1 — Corrections sans arbitrage *(peut partir en parallèle de P8.0)*

Les écarts **moyens** E-11 à E-19, qui ne dépendent d'aucune réponse :

1. **E-12** — les 3 commentaires périmés sur le grain (POJO, YAML, javadoc).
2. **E-13** — `status` dans les 2 requêtes de `CivicPlanRepository`.
3. **E-14** — les 17 questions taguées à la main (`V296`), **sans appel LLM**.
4. **E-11 / E-16 / E-17** — corriger la doc (46 notions, 11 fichiers, `uq_journey_user_target`).
5. **E-19** — fabrique `civicNotion(...)` dans `TestData`.
6. **E-6 / Q-F17** — le format de thème rejoint `CivicExamFormat` ; `AttemptService` perd ses
   6 constantes ; `CivicExamFormatTest` est étendu.

**Vérification** : `./mvnw verify`. **STOP** — livrer et faire valider ce socle avant le schéma.

## P8.2 — Schéma (`V068`)

Selon Q-F1. **Version α** (la recommandation) :

- `journey` : `target_procedure` (Q-F4), `target_level` nullable pour le civique, `entry_score` /
  `exit_score` (Q-F5) — **S-1, S-2**.
- Bloc de thème : `journey_lot.theme_id` + `journey_step.theme_id` (FK → `themes`, Q-F6), `CHECK`
  d'exclusivité avec `exam_type`, `chk_journey_step_train_skill` adapté — **S-3, S-4, S-10**.
- `chk_free_entitlement_code` ouvert au code civique (Q-F8) — **S-9**.
- Miroirs JPA. **Garde de réconciliation déterministe avant tout index unique** (patron **A28**).

**Version β/γ** : ajouter S-5, S-7, S-8 (option B de Q1) ou S-6 (option A).

**Vérification** : `./mvnw verify`, avec tests qui verrouillent chaque `CHECK` relâché.
🛑 **STOP** — une migration livrée ne se réécrit pas.

## P8.3 — Moteur

- `JourneyService.getOrCreate` : sortir `Module.TCF` du dur, accepter un objectif **mention**
  (**E-4**).
- `JourneyBlocResolver` : l'axe des blocs devient **les 5 thèmes** pour le module civique, lu sur
  `themes.display_order` et non sur un enum (**E-3**). `TcfDomainProfileDto.ORDRE` reste
  l'autorité **TCF**, intouchée.
- Amorces A / B / C au grain thème (spec civique §2).
- **R1** : un examen de thème passé hors du plan clôt l'étape **si le bloc était débloqué** — le
  thème est lu sur `attempts.lot_theme_id` ✅ ; l'examen global clôt chaque thème dont le bloc
  l'était.
- Déblocage de l'examen de thème (D-15 transposé) — selon Q-F1.
- Cycle `EN_ATTENTE`, fin de cycle (2 actions), historisation, **R3**.
- **`CivicDotation` en dépendance déclarée** : jamais d'étape sur une notion/thème non servable
  (**E-18**).
- Branchement post-évaluation : vérifier les **2** chemins civiques (examen de thème, examen global)
  au patron **D-24** ; `doFinish` seul ne suffit pas si l'un passe ailleurs.
- Historisation sur changement de mention (**E-10**, Q-F18).

**Vérification** : `./mvnw verify`. 🛑 **STOP**.

## P8.4 — Freemium et contenu d'examen

- Le freebie civique : code, point de consommation sur « terminé et corrigé » (Q-F11), retrait
  d'`enforceMockExamSlotAccess` du chemin civique (Q-F9), `hasCivique` au lieu de `hasTcf` —
  **E-5**, **C-2**.
- `civique-decouverte` selon Q-F10 (**C-3**).
- Le ratio 12/40 en contrainte de tirage sur les 3 chemins (**E-7**, Q-F13).
- Les 5 mises en situation Principes/CSP (Q-F15) et, si Q-F16 = non, les ~20 Principes/NAT.

**Vérification** : `./mvnw verify`, avec un test par règle de freemium. 🛑 **STOP**.

## P8.5 — Kits

Une seule brique manque : **`BlocAccordion` doit accepter un en-tête de thème** (nom complet, pas
d'initiale à 2 lettres) — **web et mobile dans la même passe**, brique pour brique. Les 4 autres
primitives de cycle se réutilisent telles quelles.

**Vérification** : `npx tsc --noEmit`, `npm run build`, `flutter analyze`. **Aucun nouveau test
front.** 🛑 **STOP**.

## P8.6 — Écrans

- **Plan civique** : « Cycle en cours » (5 blocs de thème, le courant déplié) remplace « Vos
  priorités » + « À revoir bientôt ». Vocabulaire : **thème** et nom complet de la thématique
  partout où le TCF dit l'épreuve ; `lot` / `step` / `journey` / `notion` interne jamais à l'écran
  (spec civique §4, **D-21**).
- **Accueil** : les 5 thèmes avec score et état, + rappel du dernier examen global (« 29 / 40, il
  manque 3 points »).
- 🛑 **Suppression immédiate de l'ancien** : libellés, imports, CTA morts, des deux côtés.
- ⚠️ **Parité web ⇄ mobile vérifiée dans la même passe**, avant de fermer.

**Vérification** : les 4 commandes front + `node scripts/verifier-contrat-front-progression.mjs`.
🛑 **STOP**.

## P8.7 — Historique des cycles civiques

⛔ **Bloqué.** Le template de l'écran historique n'a pas été fourni (D-23 / spec TCF §8). Ne rien
concevoir. Travail autorisé en amont, et **seulement après P8.6** : étendre
`GET /api/me/plan/journey/history` au module civique (le contrat est arrêté et les deux fronts
codent dessus).

## P8.8 — Documentation

- `docs/regles/plan.md` : la section civique du cycle.
- `docs/regles/freemium.md` : la règle civique arbitrée.
- `docs/regles/domaine.md` : 46 notions, le grain, la dotation.
- `backend_sejourfr/CLAUDE.md` + les 2 `CLAUDE.md` de front : la brique de kit neuve.
- `CLAUDE.md` **racine** : seulement si un invariant transverse naît.
- Consigner les décisions prises en autonomie à la suite de **A46**.

---

## Annexe A — Les 38 notions ayant au moins une mention sous le seuil de 5

Seules **8** notions sur 46 sont servables dans les **trois** mentions.
Lecture : `0` = `NON_APPLICABLE` (pas au programme) · `1–4` = `CONTENU_INSUFFISANT`.

| Thème | Notion | CSP | CR | NAT |
|---|---|---|---|---|
| `CIV_DROITS_DEVOIRS` | `dd_devoirs_citoyen` | 10 | 5 | **4** |
| | `dd_droits_sociaux` | 8 | 7 | **4** |
| | `dd_infractions_peines` | **3** | 14 | 7 |
| | `dd_interdits_quotidien` | 10 | 5 | **0** |
| | `dd_libertes_limites` | **1** | 15 | 8 |
| | `dd_police_justice` | 7 | 6 | **1** |
| | `dd_protection_europeenne` | **0** | **0** | 11 |
| | `dd_textes_fondateurs` | **0** | 12 | 7 |
| | `dd_vie_privee_famille` | 5 | 11 | **2** |
| `CIV_HISTOIRE_GEO` | `hg_art_de_vivre` | 9 | **2** | **2** |
| | `hg_arts_sciences` | **3** | 7 | **3** |
| | `hg_conquetes_droits` | **1** | **4** | 14 |
| | `hg_europe` | **0** | **4** | 6 |
| | `hg_fetes_jours_feries` | 7 | **2** | **0** |
| | `hg_geographie` | 15 | 8 | **4** |
| | `hg_litterature` | **0** | 8 | 5 |
| | `hg_napoleon_xixe` | **0** | 5 | 5 |
| | `hg_patrimoine` | 7 | 5 | **1** |
| | `hg_republiques` | **2** | 9 | 9 |
| | `hg_revolution` | 6 | 6 | **4** |
| `CIV_INSTITUTIONS` | `inst_collectivites` | 7 | 10 | **4** |
| | `inst_constitution` | **0** | 12 | 12 |
| | `inst_justice` | **0** | 14 | 6 |
| `CIV_PRINCIPES` | `pv_egalite_non_discrimination` | **0** | 6 | **3** |
| | `pv_laicite` | **1** | **3** | 5 |
| | `pv_libertes_ddhc` | **0** | 5 | **0** |
| | `pv_republique_democratie` | **2** | **4** | **2** |
| | `pv_symboles_devise` | 21 | 12 | **4** |
| `CIV_SOCIETE` | `vs_deplacements_route` | 6 | **0** | **1** |
| | `vs_ecole_scolarite` | 12 | 12 | **0** |
| | `vs_emploi_formation` | **0** | 5 | **0** |
| | `vs_nationalite_francaise` | **0** | **1** | 11 |
| | `vs_papiers_identite` | 8 | **0** | **0** |
| | `vs_sante_soins` | **2** | 9 | **0** |
| | `vs_sejour_asile` | **1** | 8 | **3** |
| | `vs_travail_contrat_salaire` | **2** | 17 | **1** |
| | `vs_travail_entreprise` | **0** | **4** | 5 |
| | `vs_urgences_secours` | 13 | **2** | **0** |

**Les 8 notions servables dans les 3 mentions** : `inst_elections`, `inst_gouvernement`,
`inst_parlement`, `inst_president`, `inst_ue`, `hg_guerres_resistance`, `vs_famille_etat_civil`,
`vs_protection_sociale_aides`.

---

## Annexe B — Requêtes de mesure

Toutes les mesures du §1 sont reproductibles sur `sejourfr_db` en lecture seule. Filtre de
référence : `module = 'CIVIQUE' AND is_active = true AND status = 'ACTIVE'`.

La mesure décisive (§1.6), pour rejouer le chiffre « 1 couple sur 138 » :

```sql
WITH d AS (
  SELECT n.theme_code, n.code, m.mention,
         (SELECT count(*) FROM questions q
           WHERE q.civic_notion_id = n.id AND q.module = 'CIVIQUE'
             AND q.is_active AND q.status = 'ACTIVE'
             AND q.difficulty = m.mention) AS nb
  FROM civic_notions n
  CROSS JOIN (VALUES ('CSP'),('CR'),('NAT')) m(mention)
  WHERE n.is_active)
SELECT mention,
       count(*) FILTER (WHERE nb = 0)              AS zero,
       count(*) FILTER (WHERE nb BETWEEN 1 AND 4)  AS insuffisant,
       count(*) FILTER (WHERE nb BETWEEN 5 AND 9)  AS demi_serie,
       count(*) FILTER (WHERE nb BETWEEN 10 AND 19) AS une_serie,
       count(*) FILTER (WHERE nb >= 20)            AS deux_series
FROM d GROUP BY 1 ORDER BY 1;
```

---

> ⛔ **FIN DE LA PHASE 0.** Aucune phase d'implémentation n'est ouverte. Le rapport s'arrête ici et
> attend le **go explicite** du propriétaire, ainsi que ses réponses aux questions **Q-F1 → Q-F20**
> — en commençant par **Q-F1**, qui détermine à elle seule si le chantier touche `skills` et
> `learning_plan_observations`, ou non.
