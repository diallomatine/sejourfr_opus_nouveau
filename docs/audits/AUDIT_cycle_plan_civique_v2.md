# AUDIT v2 — Moteur de cycle (Plan) — module CIVIQUE — après contre-audit

Date : **2026-09-19**. Périmètre : `BRIEF_contre_audit_civique.md` (§3.1 → §3.6).
Remplace les **conclusions** de `AUDIT_cycle_plan_civique.md` (v1) ; en conserve **toutes les
mesures**.
Source de droit : **arrêté du 10 octobre 2025** (JORF n° 0240 du 12 octobre 2025, NOR
INTV2527907A), articles 1 à 3 et annexe I — **vérifié sur Légifrance**, voir §5.

> ⛔ **Lecture seule.** Aucun fichier de code, aucune migration, aucun test créé ni modifié.
> Aucun appel LLM. Les mesures viennent de requêtes `SELECT` sur `sejourfr_db` ; les faits
> réglementaires de Légifrance et des sites du ministère.
> 🛑 **§2 révèle une non-conformité de l'examen blanc. Elle n'est pas corrigée** : signalée,
> chiffrée, arrêtée là, comme le brief l'exige.

---

## 1. Synthèse

1. **Le contre-audit a raison sur le fond, et sur sept de ses huit prémisses** : l'arrêté est
   confirmé mot pour mot sur Légifrance — 14 notions, répartition **11 / 6 / 11 / 8 / 4**,
   12 mises en situation **en Principes et en Droits et devoirs uniquement**, 40 questions
   **pour toutes les mentions**, **une** annexe I commune.
2. 🛑 **L'examen blanc global n'est conforme sur AUCUN axe.** Aucun des trois chemins de
   composition ne connaît la répartition officielle. **0 examen sur 33** déjà passés est
   conforme. Les mises en situation sortent à **6,6–8,7 par examen au lieu de 12**, et se
   répartissent sur les **5** thématiques au lieu de 2.
3. 🛑 **C'est le chantier prioritaire, avant le cycle** — et ce n'est pas un réglage : ni
   `exam_template_rules` ni aucun tirage ne sait exprimer un quota **par notion**.
4. ✅ **La v1 se trompait de cause, et le contre-audit a identifié la bonne** : le déficit
   « 1 couple sur 138 » venait d'un **double découpage** (46 notions internes × 3 mentions),
   dont aucun des deux étages n'est officiel.
5. ✅ **Au grain des 14 notions officielles, sans filtre de mention, R2 devient applicable** :
   **13 des 14 notions portent ≥ 20 questions**. Une seule échoue — **Laïcité, 9**.
6. ✅ **Et un examen parfaitement conforme est tirable du stock actuel** : les 14 quotas et les
   12 mises en situation sont couverts, **sans produire une seule question**.
7. 🛑 **Mais avec le filtre de mention, un examen conforme est IMPOSSIBLE** pour **CSP**
   (Laïcité : 1 question pour 2 exigées ; mises en situation Principes : 1 pour 6) et pour
   **NAT** (mises en situation Principes : 5 pour 6). **Seul CR** y arrive.
8. ⚠️ **Une nuance que §3.5 impose au contre-audit** : le ministère publie des **listes
   officielles de questions DISTINCTES par mention** (une CSP, une CR, un PDF naturalisation).
   Le **programme** est unique ; la **banque de questions**, telle que publiée, ne l'est pas.
   Prémisse n° 3 (« ni trois pools de questions ») est donc à **nuancer, pas à écarter** — et
   c'est au propriétaire de trancher, pas à l'audit.
9. **La taxonomie des 46 notions n'est pas fautive, elle est d'une autre nature** : V058 dit
   qu'elle a été « reconstruite **à partir du corpus réel** plutôt que déduite ». Elle n'a
   jamais prétendu refléter l'annexe I — que le dépôt ne cite nulle part.
10. **Q-F1 révisée** : le bloc civique **retrouve ses étapes de notion**, au grain des
    **14 notions officielles**. L'option α de la v1 (bloc clos sur son seul examen) n'est plus
    nécessaire. Détail et chiffres : §7.

---

## 2. §3.1 — Conformité du tirage de l'examen blanc global

### 2.1 Ce que l'arrêté exige

| Thématique | Total | Notions officielles et quotas |
|---|---|---|
| Principes et valeurs de la République | **11** | Devise et symboles **3** · Laïcité **2** · *Mises en situation* **6** |
| Système institutionnel et politique | **6** | Démocratie et droit de vote **3** · Organisation de la République **2** · Institutions européennes **1** |
| Droits et devoirs | **11** | Droits fondamentaux **2** · Obligations et devoirs **3** · *Mises en situation* **6** |
| Histoire, géographie et culture | **8** | Périodes et personnages **3** · Territoires et géographie **3** · Patrimoine **2** |
| Vivre dans la société française | **4** | S'installer **1** · Accès aux soins **1** · Travailler **1** · Autorité parentale et système éducatif **1** |
| **Total** | **40** | dont **28 connaissances** et **12 mises en situation** |

Et la phrase qui fait règle (art. 3) : « Chaque candidat devra répondre à un **nombre équivalent
de questions par thématique et notion**. »

### 2.2 Les trois chemins de composition — la règle réelle, pas l'intention

| Chemin | Où | Règle réellement appliquée |
|---|---|---|
| **A. Template MIX** | `exam_template_rules` + `AttemptCompositionService.pickQuestionsForTemplate` | **8 questions × 5 thèmes**, `question_type = NULL`, `difficulty` = la mention du template. 5 règles par template. |
| **B. Template FOCUS** | idem, 1 seule règle | **40 questions d'UN seul thème** |
| **C. Dynamique** | `AttemptCompositionService.composeCiviqueFullExam(difficulty, size)` | `perTheme = max(1, 40/5) = 8` par thème, `questionType` **`null`**, puis complément libre, puis `Collections.shuffle` |

**Réponses aux trois questions du brief, pour les trois chemins :**

| Question | A (MIX) | B (FOCUS) | C (dynamique) |
|---|---|---|---|
| Impose **11 / 6 / 11 / 8 / 4** par thématique ? | ❌ **Non** — impose 8/8/8/8/8 | ❌ **Non** — 40 sur 1 thème | ❌ **Non** — impose 8/8/8/8/8 |
| Impose la répartition **par notion** ? | ❌ **Non** — `exam_template_rules` **n'a aucune colonne de notion** | ❌ Non | ❌ **Non** — le tirage ne lit jamais `civic_notion_id` |
| Impose **12 mises en situation**, et seulement en Principes + Droits ? | ❌ **Non** — `question_type = NULL` sur les **20** règles civiques | ❌ Non | ❌ **Non** — `questionType` passé à `null` |

🛑 **Un quatrième défaut, non demandé mais structurant** : `pickQuestionsForTemplate` a un
**fallback sans contrainte** — si les règles ne remplissent pas `totalQuestions`, il complète
avec `findRandomExcluding(module, null, null, null, …)`. Un stock faible **désactive
silencieusement** toutes les règles du template.

### 2.3 Mesure sur les 33 examens à 40 questions déjà passés

**Classement par chemin réel**

| Chemin | Examens |
|---|---|
| C. dynamique (`composeCiviqueFullExam`) | **18** |
| A. template MIX (8 × 5) | **14** |
| B. template FOCUS (40 × 1) | **1** |

**Répartition réelle par thématique** — attendu **11 / 6 / 11 / 8 / 4**

| Chemin | Thématique | Attendu | min | **moy** | max |
|---|---|---|---|---|---|
| **A. MIX** | `CIV_PRINCIPES` | 11 | 6 | **7,7** | 9 |
| | `CIV_INSTITUTIONS` | **6** | 7 | **7,4** | 8 |
| | `CIV_DROITS_DEVOIRS` | 11 | 6 | **7,9** | 11 |
| | `CIV_HISTOIRE_GEO` | 8 | 7 | **8,3** | 12 |
| | `CIV_SOCIETE` | **4** | 7 | **8,6** | 11 |
| **C. dynamique** | `CIV_PRINCIPES` | 11 | 3 | **7,8** | 31 |
| | `CIV_INSTITUTIONS` | **6** | 3 | **8,1** | 11 |
| | `CIV_DROITS_DEVOIRS` | 11 | 3 | **7,8** | 11 |
| | `CIV_HISTOIRE_GEO` | 8 | 2 | **8,8** | 13 |
| | `CIV_SOCIETE` | **4** | 1 | **7,4** | 9 |
| **B. FOCUS** | `CIV_SOCIETE` | 4 | 38 | **38,0** | 38 |

**Mises en situation par examen** — attendu **12**

| Chemin | min | **moy** | max | Examens |
|---|---|---|---|---|
| A. MIX | 3 | **6,6** | 12 | 14 |
| C. dynamique | 5 | **8,7** | 12 | 18 |
| B. FOCUS | 5 | **5,0** | 5 | 1 |
| **Ensemble** | 3 | **7,7** | 12 | 33 |

**Placement des mises en situation** — attendu **6 Principes + 6 Droits, 0 ailleurs**

| Thématique | Autorisée ? | MES sur les 33 examens | Par examen |
|---|---|---|---|
| `CIV_PRINCIPES` | ✅ oui (6) | 58 | 1,76 |
| `CIV_DROITS_DEVOIRS` | ✅ oui (6) | 49 | 1,48 |
| `CIV_HISTOIRE_GEO` | 🛑 **non (0)** | **46** | 1,39 |
| `CIV_INSTITUTIONS` | 🛑 **non (0)** | **43** | 1,30 |
| `CIV_SOCIETE` | 🛑 **non (0)** | **58** | 1,76 |

**Examens conformes à la répartition officielle par thématique : 0 sur 33.**
Un examen n'a même couvert que **3** thématiques sur 5.

### 2.4 🛑 Conclusion : l'examen blanc global ne simule pas l'examen réel

**Non, sur les quatre axes :**

| Axe | Écart |
|---|---|
| **Répartition par thématique** | Le produit tire **8/8/8/8/8**, l'examen exige **11/6/11/8/4**. Institutions est **sur-représentée de +23 %**, Société de **+115 %**, Principes **sous-représentée de −30 %**, Droits de **−28 %**. |
| **Répartition par notion** | **Aucune** contrainte, aucun chemin. Le schéma ne sait même pas l'exprimer (`exam_template_rules` sans colonne de notion). |
| **Nombre de mises en situation** | **7,7 en moyenne au lieu de 12** — il en manque **4,3 par examen**, soit **36 %** du quota. |
| **Placement des mises en situation** | **147 des 254** mises en situation tirées (**58 %**) étaient dans une thématique où l'examen réel n'en pose **aucune**. |

**Ce qui EST conforme, et qu'il faut préserver** : le **diagnostic civique**. Sa configuration
`sejourfr.civic-diagnostic` porte `connaissances: 28` + `mises-en-situation: 12` — exactement le
partage officiel. C'est le **seul** endroit du dépôt qui tient le ratio, et il le tient parce
qu'il est **déclaré**, pas déduit d'un tirage.

### 2.5 ✅ Un examen conforme est-il tirable du stock actuel ?

**Oui, sans produire une seule question — à condition de retirer le filtre de mention.**

| Notion officielle | Exigé | Stock (sans filtre) | Conforme sans filtre | Conforme dans les **3** mentions |
|---|---|---|---|---|
| P1 Devise et symboles | 3 | 37 | ✅ | ✅ |
| **P2 Laïcité** | **2** | **9** | ✅ | 🛑 **non — CSP n'en a que 1** |
| I1 Démocratie et droit de vote | 3 | 33 | ✅ | ✅ |
| I2 Organisation de la République | 2 | 143 | ✅ | ✅ |
| I3 Institutions européennes | 1 | 32 | ✅ | ✅ |
| D1 Droits fondamentaux | 2 | 119 | ✅ | ✅ |
| D2 Obligations et devoirs | 3 | 58 | ✅ | ✅ |
| H1 Périodes et personnages | 3 | 101 | ✅ | ✅ |
| H2 Territoires et géographie | 3 | 27 | ✅ | ✅ |
| H3 Patrimoine | 2 | 61 | ✅ | ✅ |
| S1 S'installer | 1 | 39 | ✅ | ✅ |
| S2 Accès aux soins | 1 | 29 | ✅ | ✅ |
| S3 Travailler | 1 | 34 | ✅ | ✅ |
| S4 Autorité parentale et éducation | 1 | 46 | ✅ | ✅ |
| **MES Principes** | **6** | **21** | ✅ | 🛑 **non — CSP 1, NAT 5** |
| MES Droits et devoirs | 6 | 47 | ✅ | ✅ |

🛑 **Le verdict le plus net de cet audit** : un examen blanc **conforme à l'arrêté** est tirable
**sans filtre de mention** et **impossible avec** — pour CSP comme pour NAT. Seul **CR** y arrive.
C'est un argument **indépendant** de R2 et du cycle : il porte sur la promesse centrale du
produit.

### 2.6 Chiffrage du chantier de conformité *(signalé, non corrigé)*

| Travail | Coût |
|---|---|
| Une autorité de la répartition officielle — du **code**, comme `CivicExamFormat` : 5 thématiques × leurs notions × leurs quotas + le placement des 12 MES | ~120 lignes + tests |
| Faire du **quota par notion** une contrainte du tirage : `civic_notion_id` dans la requête de composition | 1 requête, 1 service |
| Exprimer un quota par notion en **template** : colonne `notion_id` sur `exam_template_rules` (ou retirer les templates du chemin de l'examen officiel) | 1 migration **ou** 0, selon l'arbitrage |
| Reprendre les **20 templates civiques** (5 règles à 8 → règles conformes, ou dépublication) | données |
| Encadrer le **fallback** de `pickQuestionsForTemplate` : un examen officiel ne doit pas pouvoir compléter hors règles **en silence** | ~20 lignes |
| Questions à produire | **0** |

⛔ **Arrêt ici sur ce point**, conformément au brief : chantier à part, prioritaire, arbitré
séparément.

---

## 3. §3.2 — Correspondance 46 notions internes → 14 notions officielles

### 3.1 Méthode et statut

La correspondance a été construite à partir du `label` **et** de la `description` de chaque
notion — les descriptions de `V058__referentiel_civique_valide.sql` sont explicites sur ce qui
entre et ce qui n'entre pas, frontières nommées comprises. **Les 46 notions se rattachent, sauf
une.** ⚠️ C'est une **proposition d'audit**, à valider par le propriétaire : neuf rattachements
sont des arbitrages, signalés par la colonne « Chevauchement ».

🛑 **Fait à consigner** : l'arrêté du 10 octobre 2025 **n'est cité nulle part dans le dépôt** —
ni en migration, ni en doc, ni en commentaire. `V058` dit que le référentiel a été « reconstruit
**à partir du corpus réel** plutôt que déduit », et validé le 2026-09-11. La taxonomie des
46 notions n'a donc jamais prétendu être l'annexe I : c'est une **taxonomie de travail
éditoriale**, et les deux peuvent coexister — l'une pour écrire les questions, l'autre pour
tirer l'examen et mesurer le candidat.

### 3.2 Dotation par notion officielle — la mesure qui remplace le « 1 sur 138 » de la v1

| Notion officielle | Notions internes | Questions | CSP | CR | NAT | **R2 (≥ 20)** |
|---|---|---|---|---|---|---|
| I2 Organisation de la République | 6 | **143** | 41 | 63 | 39 | ✅ |
| D1 Droits fondamentaux | 8 | **119** | 21 | 62 | 36 | ✅ |
| H1 Périodes et personnages | 6 | **101** | 17 | 37 | 47 | ✅ |
| H3 Patrimoine | 5 | **61** | 26 | 24 | 11 | ✅ |
| D2 Obligations et devoirs | 3 | **58** | 23 | 24 | 11 | ✅ |
| S4 Autorité parentale et éducation | 2 | **46** | 18 | 18 | 10 | ✅ |
| S1 S'installer | 4 | **39** | 15 | 9 | 15 | ✅ |
| P1 Devise et symboles | 1 | **37** | 21 | 12 | 4 | ✅ |
| S3 Travailler | 3 | **34** | 2 | 26 | 6 | ✅ |
| I1 Démocratie et droit de vote | 2 | **33** | 10 | 13 | 10 | ✅ |
| I3 Institutions européennes | 1 | **32** | 7 | 14 | 11 | ✅ |
| S2 Accès aux soins | 2 | **29** | 7 | 15 | 7 | ✅ |
| H2 Territoires et géographie | 1 | **27** | 15 | 8 | 4 | ✅ |
| **P2 Laïcité** | 1 | **9** | 1 | 3 | 5 | 🛑 **non** |
| *(ZZ sans rattachement)* | 1 | *15* | *13* | *2* | *0* | — |
| **Total** | **46** | **783** | 237 | 330 | 216 | **13 / 14** |

**Les exceptions, exhaustivement :**

1. 🛑 **P2 Laïcité — 9 questions.** La seule notion officielle sous le seuil de R2. Il en manque
   **11** pour atteindre 20. C'est **la seule production de contenu que cet audit identifie comme
   nécessaire**, et elle est modeste.
2. ⚠️ **`vs_urgences_secours` — 15 questions, sans rattachement.** Sa description est explicite :
   « qui intervient en cas d'urgence, quel numéro composer, **et ce que font la police et la
   gendarmerie au quotidien** ». L'annexe I n'a pas de notion « urgences / secours / forces de
   l'ordre ». Options : rattacher à **S2 Accès aux soins** (le 15, le 112 y ont leur place et cela
   porterait S2 à 44), ou la conserver comme **contenu d'entraînement hors examen**.

### 3.3 Avant / après, en un tableau

| Grain | Unités | Atteignent 20 | À zéro |
|---|---|---|---|
| **v1** — 46 notions internes × 3 mentions | 138 | **1** | 23 |
| 14 notions officielles × 3 mentions | 45 | **14** | 1 |
| **14 notions officielles, sans filtre de mention** | **15** | **13** | **0** |

✅ **Le contre-audit a identifié la bonne cause.** Le déficit de la v1 était l'effet cumulé de
deux découpages dont aucun n'est officiel : une taxonomie de travail à 46 entrées, et un filtre
de mention. Retirer les deux rend R2 applicable sans produire de contenu — **à 11 questions de
Laïcité près**.

### 3.4 Chevauchements et arbitrages — les neuf rattachements discutables

| Notion interne | Rattachement proposé | Chevauchement, et pourquoi |
|---|---|---|
| `pv_republique_democratie` (8) | I1 Démocratie et droit de vote | Sa description dit « **le principe, pas l'organe** » ; l'annexe I n'a pas de notion « principe républicain » hors Devise/Laïcité. |
| `pv_libertes_ddhc` (5) | D1 Droits fondamentaux | Sa propre description l'annonce : « ⚠️ **Recouvrement assumé** avec CIV_DROITS_DEVOIRS […] la frontière la plus fragile du référentiel ». |
| `pv_egalite_non_discrimination` (9) | D1 Droits fondamentaux | Égalité comme droit fondamental ; exclut explicitement « l'égalité comme mot de la devise ». |
| `dd_protection_europeenne` (11) | D1 Droits fondamentaux | Chevauche **I3 Institutions européennes** ; sa description tranche : « le fonctionnement **politique** de l'UE → CIV_INSTITUTIONS ». |
| `dd_police_justice` (14) | D1 Droits fondamentaux | Chevauche I2 (les tribunaux) ; sa règle : « ce que **font** les forces de l'ordre est un service ; ce que je peux **leur opposer** est un droit ». |
| `dd_droits_sociaux` (19) | D1 Droits fondamentaux | Chevauche S2 et S3 ; sa règle : « un droit devant un **juge** reste ici ; un formulaire à un **guichet** part là-bas ». |
| `hg_europe` (10) | H1 Périodes et personnages | Chevauche I3 ; sa description exclut « les institutions **d'aujourd'hui** → `inst_ue` ». |
| `hg_fetes_jours_feries` (9) | H3 Patrimoine | Chevauche P1 ; sa description renvoie « le 14 juillet comme **fête nationale et symbole** → CIV_PRINCIPES ». |
| `vs_deplacements_route` (7) | S1 S'installer | Le permis et la sécurité routière ne figurent dans **aucune** des 4 notions officielles de « Vivre dans la société française ». Rattachement **faible**. |
| `vs_protection_sociale_aides` (18) | S2 Accès aux soins | Chevauche S3 (cotisations, retraite) ; la Sécu penche vers les soins. |

### 3.5 Où faire vivre les 14 notions officielles ?

| Option | Travail | Ce qu'on gagne / perd |
|---|---|---|
| **A — colonne de rattachement sur `civic_notions`** (`official_notion` varchar ou FK) | 1 migration + 46 `UPDATE` | ✅ Le plus léger. ⚠️ Les 14 notions officielles n'ont alors ni libellé, ni ordre, ni description propres : elles sont une **valeur**, pas un objet. Un écran qui doit afficher « Laïcité — 2 questions à l'examen » n'a rien à lire. |
| **B — table de référence des 14 notions officielles** + FK depuis `civic_notions` | 1 migration + 14 `INSERT` + 46 `UPDATE` | ✅ Les 14 deviennent un **objet** : libellé, ordre, **quota officiel**, thématique. C'est ce dont le tirage conforme (§2.6) **et** le cycle (§7) ont besoin, l'un comme l'autre. ⚠️ Deux tables de notions coexistent — mais avec **deux rôles distincts et nommés** : l'officielle **mesure**, l'interne **écrit**. |

**Recommandation : B**, et pour une raison qui n'est pas d'élégance. §2.6 a besoin d'une autorité
du quota par notion, §7 a besoin d'une unité travaillable, et l'écran a besoin d'un libellé. Les
trois ont besoin du **même** objet. L'option A obligerait à redéclarer le quota ailleurs — et
« une règle, une autorité » est précisément ce que le dépôt fait payer le plus cher.

⚠️ **Réserve** : `chk_civic_notion_merge_desactive` et `merged_into_id` restent la mécanique de
révision de la taxonomie **interne**. La table officielle, elle, n'a pas de fusions : elle suit
un arrêté. Ne pas leur donner la même forme.

---

## 4. §3.3 — Le sort de `questions.difficulty`

### 4.1 Recensement exhaustif des points qui filtrent sur la mention

**A. Filtre CIVIQUE dur (`:mention` non nul, jamais désactivable) — 4 points**

| # | Fichier : ligne | Requête / rôle |
|---|---|---|
| 1 | `CivicPlanRepository:112` | `questionsParNotion(mention)` — la **dotation par notion** |
| 2 | `CivicPlanRepository:129` | `questionsParTheme(mention)` — la dotation par thème |
| 3 | `CivicPlanRepository:166` | `tirageSerieCiblee(...)` — le tirage d'une **série ciblée** |
| 4 | `CivicDiagnosticComposer:72,80,86` | les 3 tirages du **diagnostic civique** |

**B. La porte unique qui alimente A — 1 point**

| # | Fichier : ligne | Rôle |
|---|---|---|
| 5 | `AttemptService.resolveDifficulty:1100-1112` | 🛑 **LA porte.** `requested != null ⇒ requested` · `module == TCF ⇒ null` · `targetProcedure == null ⇒ null` · sinon CSP/CR/NAT. Alimente les examens blancs (global et de thème) et l'entraînement. |
| | `TargetProcedure.mentionCivique(…)` | La table CSP→CSP / CR→CR / NAT→NAT. Appelée en **3 endroits** : `CivicDiagnosticService:216`, `CivicPlanService:143`, `CivicPlanService:461`. Repli `null ⇒ CSP`. |

**C. Filtre optionnel, partagé avec le TCF (`:difficulty IS NULL OR …`) — 11 requêtes**

`QuestionRepository` lignes **50, 80, 142, 164, 232, 268, 298, 309, 366** ·
`MediaRepository:28` · `QuestionEmpiricalDifficultyRepository:26`.
⚠️ **Le TCF passe toujours `null`** ici : « le TCF n'est jamais filtré par niveau : le test est
unique pour tous » (`resolveDifficulty`). Ces requêtes sont donc génériques ; **seul le civique
leur passe une valeur**.

**D. Données**

| # | Où | Détail |
|---|---|---|
| 6 | `exam_template_rules.difficulty` | **15 règles** portent `CSP`/`CR`/`NAT` sur les 20 templates civiques |
| 7 | `exam_templates.target_procedure` | l'étiquette de mention du template |
| 8 | `attempts.lot_difficulty` | filtre d'historique (`AttemptRepository:154`) |

**E. 🛑 Une incohérence interne déjà présente**

`LotService` lignes **139** et **173** : les **lots d'entraînement civiques** appellent
`countActiveMatching(Module.CIVIQUE, themeId, null, null)` — **`difficulty` à `null`**.
L'entraînement libre par thème **ignore déjà la mention**, là où le plan, le diagnostic et les
examens l'appliquent. Le filtre n'est donc **pas** une règle du module : c'est une règle de
**trois chemins sur quatre**.

### 4.2 Aucune question n'est réellement spécifique à une démarche

| Mesure | Résultat |
|---|---|
| Questions actives dont l'énoncé cite une démarche (« naturalisation », « carte de résident », « carte de séjour », « nationalité française ») | **15 sur 976** (1,5 %) |
| Réparties | NAT 9 · CR 5 · CSP 1 |
| Leurs notions | `vs_nationalite_francaise` (6), `vs_sejour_asile` (3), `vs_papiers_identite` (1), non taguées (5) |

✅ **Aucune n'est exclusive d'une démarche.** « Les démarches d'accès à la nationalité française »
et « S'installer et résider en France » figurent au programme **pour toutes les mentions**
(annexe I, notion S1). Une question sur la naturalisation est **légitime pour un candidat CSP** :
c'est du programme, pas une spécificité.

🛑 **Le corollaire est important** : le clivage par mention n'est pas dans le **contenu** des
questions, il est dans leur **étiquetage**. `V058` en tirait la conclusion inverse — « CSP, CR et
NAT ne sont pas trois niveaux du même programme : ce sont **trois programmes différents** » — mais
il la tirait **du corpus**, qui avait été **écrit** ainsi. Le raisonnement est circulaire, et la
mesure ci-dessus le montre.

### 4.3 Effet du retrait du filtre

| Mesure | Avec filtre | Sans filtre |
|---|---|---|
| Notions officielles atteignant 20 questions | 14 couples / 45 | **13 unités / 14** |
| Unités à **zéro** question | 1 | **0** |
| `CivicDotation.NON_APPLICABLE` (notion interne × mention) | **23 couples** | **0** — l'état devient **impossible** |
| `CivicDotation.CONTENU_INSUFFISANT` (< 5), notions internes | 35 couples | **0** — le minimum interne est 5 (`pv_libertes_ddhc`, `vs_emploi_formation`) |
| Notions internes servables, par candidat | CSP 24/46 · CR 34/46 · NAT 22/46 | **46/46 pour tous** |
| Un examen blanc **conforme** est tirable | 🛑 **CR seulement** | ✅ **oui** |

🛑 **`CivicDotation` perd deux de ses trois états.** C'est un enum de 68 lignes dont le javadoc
argumente longuement la distinction `NON_APPLICABLE` / `CONTENU_INSUFFISANT` — et cet argument
repose entièrement sur le découpage par mention. Sans filtre, `depuis(questions, minimum)` rend
toujours `SERVABLE` au grain notion officielle. **À supprimer, pas à laisser mourir vide**
(« refonte = suppression immédiate de l'ancien »).

### 4.4 Les trois options pour la colonne

| | **A — supprimer** | **B — métadonnée éditoriale, sans effet de filtre** | **C — réinterpréter en difficulté réelle** |
|---|---|---|---|
| Ce qu'on fait | `DROP COLUMN` côté civique — impossible : la colonne est partagée avec le TCF, où elle porte le palier CECRL | On garde `difficulty`, on cesse de la **lire** : les 4 points de §4.1-A passent `null`, `resolveDifficulty` rend `null` pour le civique | On ajoute `difficulty_band` (`EASY`/`MEDIUM`/`HARD`) aux questions civiques, sur le patron TCF **déjà en place** (`idx_questions_band`, `questions_difficulty_band_valide`) |
| Migration | ❌ impossible sans casser le TCF | **0** (données intactes) | 1 migration de données + un travail de calibration éditoriale |
| Réversibilité | — | ✅ **totale** — c'est une variable de code, pas une migration | partielle |
| Perte | — | l'étiquette reste lisible en admin, pour savoir de quelle campagne vient une question | rien |
| Ce que ça permet | — | tout ce que §4.3 mesure | une vraie progressivité de difficulté, que le civique n'a pas du tout aujourd'hui |

**Recommandation : B maintenant, C plus tard et séparément.**

Trois raisons :

1. **B ne coûte rien et ne perd rien.** `difficulty` reste en base, l'admin continue de la voir,
   et si l'arbitrage se révèle mauvais on remet la lecture. Le dépôt a une règle pour ça : « un
   retour arrière est un changement de variable d'environnement, pas une migration ».
2. **B est déjà le régime du TCF**, et c'est exactement le régime que l'arrêté prescrit : un
   programme, un test pour tous. `resolveDifficulty` dit déjà « le TCF n'est jamais filtré par
   niveau : le test est unique pour tous ». Le civique devient **cohérent** avec lui.
3. **C est un autre sujet.** Une difficulté facile/moyen/difficile est un besoin réel — le civique
   n'a **aucune** progressivité — mais c'est du travail éditorial sur 976 questions, et ça ne
   débloque ni la conformité de l'examen (§2) ni R2 (§7).

⚠️ **Ce que B ne règle pas, et qu'il faut nommer** : la **mention disparaît de l'expérience
produit**. Trois écrans en parlent aujourd'hui (le sous-titre des templates, l'en-tête du plan,
le libellé du diagnostic). Si le contenu est commun, le mot « CSP / CR / NAT » ne désigne plus
qu'une **attestation visée**, jamais un programme. Il reste utile (le seuil, la démarche
administrative) mais ne doit plus rien filtrer. ⛔ **Et voir §5** : le ministère publie des listes
par mention — c'est l'argument le plus sérieux **contre** B, et il n'appartient pas à l'audit de
le trancher.

---

## 5. §3.5 — Les questions officielles publiques *(constat seul, rien à importer)*

### 5.1 Ce qui est vérifié

**L'arrêté, sur Légifrance** — confirmé mot pour mot :

| Prémisse du contre-audit | Vérification |
|---|---|
| 40 questions **pour toutes les mentions** | ✅ art. 3 : « **Pour toutes les mentions**, l'épreuve […] comprenant quarante questions » |
| **Une** annexe I, commune | ✅ Annexes I (référentiel), II (déroulement), III (règlement) — **communes aux trois mentions**, aucune annexe par mention |
| Répartition 11 / 6 / 11 / 8 / 4 et les 14 notions | ✅ conforme au tableau du brief, au détail près |
| 12 mises en situation, **6 Principes + 6 Droits, 0 ailleurs** | ✅ |
| « nombre équivalent de questions par thématique et notion » | ✅ art. 3, verbatim |
| Durée 45 min · seuil 80 % | ✅ 45 min confirmé ; **80 % explicitement énoncé pour la mention « naturalisation »**. ⚠️ Le texte consulté ne fait pas apparaître de seuil distinct pour CSP et CR — **non vérifié**, à confirmer si l'écart compte |
| « Les questions de connaissances sont rendues publiques sur le site internet du ministère chargé des naturalisations » | ✅ art. 3, dernier alinéa |

### 5.2 🛑 Ce que la publication révèle — et qui nuance la prémisse n° 3

Le ministère publie effectivement la banque, **mais par mention** :

| Ressource | URL | Forme | Volume |
|---|---|---|---|
| Liste officielle — **mention CSP** | `formation-civique.interieur.gouv.fr/examen-civique/liste-officielle-des-questions-de-connaissance-csp/` | page HTML, questions en liste, **par thématique** | **≈ 212** : Principes 47 · Institutions 49 · Droits 40 · Histoire 43 · Société 33 |
| Liste officielle — **mention CR** | `…/liste-officielle-des-questions-de-connaissance-cr/` | idem | **≈ 205** : ≈ 40 · 50 · 35 · 40 · 40 |
| Questions — **nationalité française** | `immigration.interieur.gouv.fr/documentation/examen-civique/questions-de-connaissance-pour-lexamen-civique-nationalite-francaise.html` → PDF `…-20251212.pdf` | **PDF**, daté du **2025-12-12** | non mesuré (page en **403** depuis cet environnement) |
| Informations générales | `formation-civique.interieur.gouv.fr/examen-civique/informations-générales-sur-lexamen-civique/` | page | confirme **28 connaissances + 12 mises en situation** |

**Trois faits à retenir :**

1. 🛑 **Il existe des listes de questions DISTINCTES par mention.** La page CSP dit : « Voici les
   questions de connaissances qui pourront être posées lors de l'examen civique de niveau
   **carte de séjour pluriannuelle (CSP)** ». La prémisse n° 3 du contre-audit (« il n'existe
   ni trois programmes, ni trois pools de questions ») est **vraie du programme** — une seule
   annexe I — et **fausse de la banque publiée**. ⚠️ **Constat, pas arbitrage.** Il pèse
   directement sur §4.4 et sur §7.
2. ✅ **Les mises en situation ne sont pas publiées** : « L'examen civique comporte également des
   questions de mises en situation **qui ne sont pas rendues publiques** ». Les 176 du dépôt
   n'ont donc aucun équivalent officiel à comparer — leur production reste entièrement à la
   charge de SejourFR.
3. **La répartition 11/6/11/8/4 n'est publiée que dans l'arrêté**, pas sur les pages du
   ministère. Les listes publiques, elles, sont réparties à peu près **également** entre les
   5 thématiques (≈ 40-50 chacune) : la **banque** est équilibrée, le **tirage** ne l'est pas.
   C'est exactement la confusion que le produit fait aujourd'hui (§2.2).

### 5.3 Ce que ça représenterait comme chantier — évaluation, pas tâche

| | Volume | Nature |
|---|---|---|
| Banque publique par mention | ≈ 212 (CSP) + ≈ 205 (CR) + le PDF NAT | énoncés **sans réponses fournies** sur les pages consultées — la réponse reste à produire et à vérifier |
| Stock SejourFR actuel, connaissances | **800** | déjà écrit, tagué à 98 % |
| Recouvrement | **non mesuré** | mesurable seulement après extraction, hors périmètre |

**Trois lectures possibles**, dans l'ordre de coût :

1. **Contrôle de couverture** — extraire les listes, les rattacher aux 14 notions, et mesurer ce
   que le stock SejourFR **ne couvre pas**. C'est le meilleur rapport valeur/coût : ça dit où
   écrire, sans rien importer.
2. **Alignement d'énoncés** — comparer 800 questions à ≈ 420 officielles. Coûteux, et d'intérêt
   discutable : les énoncés officiels étant publics, les reproduire n'apporte pas d'avantage.
3. **Import** — ⛔ **exclu par le brief**, et à raison : sans les réponses, un import est du
   travail éditorial déguisé en migration.

⛔ **Aucune action.** Le livrable de §3.5 est ce tableau.

---

## 6. §3.4 — Les mises en situation hors périmètre officiel

### 6.1 Les comptes, confirmés

| Thématique | MES actives | Autorisée par l'arrêté ? | Quota officiel |
|---|---|---|---|
| `CIV_DROITS_DEVOIRS` | **47** | ✅ oui | 6 |
| `CIV_PRINCIPES` | **21** | ✅ oui | 6 |
| `CIV_HISTOIRE_GEO` | **30** | 🛑 **non** | 0 |
| `CIV_INSTITUTIONS` | **31** | 🛑 **non** | 0 |
| `CIV_SOCIETE` | **47** | 🛑 **non** | 0 |
| **Dans le périmètre** | **68** | | 12 |
| 🛑 **Hors périmètre** | **108** | | — |

✅ Les chiffres de la v1 sont confirmés : **108 mises en situation** (61 % des 176, **11 % du
stock actif total**) sont dans une thématique où l'examen réel n'en pose aucune.

⚠️ **Et la case creuse de la v1 change de sens** : `CIV_PRINCIPES` × `CSP` = **1** mise en
situation. Sans filtre de mention, Principes en a **21** pour 6 exigées — le problème disparaît.
**Avec** le filtre, il est **rédhibitoire** : on ne tire pas 6 questions dans un stock de 1.
C'est la mesure de §2.5 vue d'un autre angle.

### 6.2 Ce que deviennent les 108

| Option | Effet | Coût |
|---|---|---|
| **A — contenu d'entraînement, exclu des examens blancs** | Les 108 restent jouables en série ciblée et en lot libre ; le tirage d'examen ne les atteint plus. **Rien n'est perdu, rien n'est retypé.** | la contrainte de tirage de §2.6, et **rien de plus** |
| **B — re-typer en `CONNAISSANCE`** | +108 connaissances (800 → 908). ⚠️ Une mise en situation **n'est pas** une question de connaissance : elle décrit une situation et demande la bonne conduite. Les re-typer **fausse le diagnostic** (`connaissances: 28` / `mises-en-situation: 12`) et **dégrade le stock**. | relecture des 108, et une perte de sens |
| **C — reclasser vers Principes ou Droits** | Une mise en situation « vous arrivez aux urgences sans carte Vitale » ne devient pas un cas de laïcité parce qu'on change son `theme_id`. **Ce serait une trace fausse.** | à écarter |

**Recommandation : A.** Les 108 sont du contenu valable, écrit et relu ; ce qui est faux, c'est
qu'un **examen blanc** puisse les tirer. La correction est **dans le tirage**, pas dans les
données — et c'est le même travail que §2.6, pas un travail de plus.

### 6.3 Le tirage peut-il encore en placer hors périmètre ?

🛑 **Oui, aujourd'hui, sur les trois chemins**, puisqu'aucun ne contraint `question_type` (§2.2).
La mesure le prouve : **147 des 254** mises en situation tirées sur les 33 examens (58 %) étaient
hors périmètre. La garantie ne peut pas venir d'une consigne : elle doit venir de la contrainte
de tirage de §2.6 — « ce qui tient la qualité, ce sont les contraintes dures ».

⚠️ **Et l'examen de thème (20 Q / seuil 16) est un cas à part** : c'est un **format SejourFR**,
pas un format officiel. Un examen de thème sur `CIV_SOCIETE` devrait-il contenir des mises en
situation, alors que l'examen réel n'en pose aucune dans cette thématique ? **Question ouverte,
Q-F21 (§8).**

---

## 7. §3.6 — Q-F1 révisée

### 7.1 R2 est-elle applicable, au grain des 14 notions officielles sans filtre de mention ?

**Oui, sur 13 des 14 notions, sans produire une seule question.**

| Critère de R2 | Verdict |
|---|---|
| Une série de **10 questions** est-elle composable ? | ✅ sur les 14 notions — le minimum est **9** (Laïcité), les 13 autres sont à **27 ou plus** |
| **Deux séries sans recouvrement** (≈ 20 questions) ? | ✅ sur **13 / 14**. 🛑 **Laïcité (9) échoue** : il en manque 11 |
| L'échappatoire « 4 séries terminées » ? | ✅ sans objet — elle protège un candidat faible, pas un stock faible |
| Le quota est-il mesurable ? | ✅ **chaque question porte sa notion interne**, donc sa notion officielle par rattachement |

**À comparer à la v1 :** 1 couple sur 138 → **13 unités sur 14**. Le contre-audit a bien
identifié la cause : c'était le **double découpage**, pas le stock.

### 7.2 α ou les étapes de notion ?

**Le bloc civique retrouve ses étapes de notion, comme le TCF. L'option α n'est plus nécessaire.**

| | **α — bloc clos sur son seul examen** (reco v1) | **Étapes de notion** (reco v2) |
|---|---|---|
| Fondement | un **repli** faute de contenu | le contenu **porte** la règle |
| Unité travaillable | aucune | les **14 notions officielles** |
| Étapes par bloc | 1 (l'examen) | 2 à 3 notions + son examen — et **2 ou 3, c'est exactement le format officiel** (Principes : Devise + Laïcité ; Institutions : 3 notions ; Société : 4) |
| Conformité à D-15 | à réinventer (« quoi débloque l'examen ? ») | ✅ **D-15 s'applique mot pour mot** : « aucune notion restante dans le bloc » |
| Écart au brief v1 (« ne réinvente aucune règle ») | 🛑 **oui**, signalé comme conflit C-1 | ✅ **aucun** — R1, R2, R3, déblocage, cycle en attente, historisation s'appliquent tels quels |
| Schéma | `journey_step.theme_id` | `journey_step` pointe la **notion officielle** |

🛑 **Ce qui a changé, et qui fait toute la différence** : la v1 recommandait α en disant
« c'est un écart, il se signale, il ne s'applique pas ». La v2 n'a plus d'écart à signaler. Le
cycle civique devient le **même moteur** que le TCF, à l'axe des blocs près (thématique au lieu
d'épreuve) — ce que la spec civique annonçait depuis le début.

**Corollaire, et il simplifie encore** : l'unité travaillable est la **notion officielle**, pas
la notion interne. Elle vit dans une table de référence de **14 lignes** (§3.5 option B) — pas
dans `skills`, pas dans `civic_notions`. Les deux options de **Q1 de la v1** (généraliser
`skills` / observation polymorphe) sont donc **toutes deux caduques dans leur motif** ; reste à
décider comment `journey_step` et `learning_plan_observations` la désignent, ce qui est la même
question qu'avant mais **posée sur 14 lignes stables au lieu de 46 mouvantes**.

### 7.3 Le sort de `questionsMinParNotion: 5` et `questionsParSerie: 10`

| Clé | Aujourd'hui | Dans le cadre v2 | Recommandation |
|---|---|---|---|
| `questions-min-par-notion: 5` | seuil de `CivicDotation`, **compté par mention** | ⚠️ **sans objet** : sans filtre, le minimum au grain officiel est **9**, et **0 unité** est sous 5. La clé ne peut plus rien refuser. | 🛑 **Supprimer, avec `CivicDotation`** — une clé qui ne discrimine plus rien est une règle morte qui donne l'illusion d'un garde-fou. Ce que la clé protégeait (« ne jamais proposer une notion qu'on ne sait pas enseigner ») est désormais garanti par la **structure** : 14 notions officielles, toutes dotées. |
| `questions-par-serie: 10` | taille d'une série ciblée | ✅ **tenable sur les 14 notions** (min 9). | **Conserver à 10.** ⚠️ Et corriger le défaut que la v1 a relevé : `tirageSerieCiblee` a un `LIMIT` et **ne complète pas** — une notion à 9 questions rend une série de 9, en silence. Sur Laïcité, une **seconde** série rejoue les mêmes 9. C'est le **seul** point où R2 reste faible, et 11 questions de Laïcité le referment. |
| `seuil-tagging: 0.80` | bascule THEME → NOTION par thème | ✅ **franchie partout** (97-98,6 %). ⚠️ Mais elle porte sur la taxonomie **interne** ; au grain officiel le rattachement est **total** (46/46). | **Conserver** comme garde-fou du plan dérivé ; le **cycle n'en dépend pas**. |
| `priorites-visibles: 3` / `revisions-visibles: 3` | plafonds d'**affichage** | inchangés | conserver — et ne jamais les lire comme un budget |

### 7.4 Le seul contenu à produire, et c'est tout

| Besoin | Volume | Pourquoi |
|---|---|---|
| **P2 Laïcité** | **+11 questions** (9 → 20) | La seule notion officielle sous le seuil de R2 |
| *(si le filtre de mention est conservé)* | **≈ 340** | Pour amener les 45 couples (14 notions × 3 mentions) à 20 — **et même alors, la conformité CSP resterait impossible** faute de mises en situation en Principes |
| Rattachement de `vs_urgences_secours` | **0** | Un arbitrage, pas du contenu |

**À comparer à la v1 : ≈ 1 480 questions → 11.** C'est la mesure de la valeur du contre-audit.

---

## 8. Ce que la v1 conserve, et ce qui tombe

### 8.1 Mesures — toutes valides, rien à refaire

Tagging 98 % des connaissances · les 5 thèmes au grain NOTION · 0 incohérence thème ↔ notion ·
0 notion orpheline · 46 notions actives (pas 40) · 176 mises en situation non taguées, 0 suggestion ·
981 suggestions / 840 questions / `claude-sonnet-5` / `PROMPT_TAG_NOTION_v4` / 2026-09-11 /
`scripts/pre-tagging/` · 17 connaissances non taguées · formats 20/16/20 min et 40/32 · 11 examens
de thème avec `lot_theme_id` · `status` sans rôle côté civique.

### 8.2 Écarts — ce qui tombe, ce qui reste

| # | v1 | Statut v2 |
|---|---|---|
| **E-1** | R2 inapplicable (1 couple / 138) | 🛑 **TOMBE.** Cause invalidée. Au grain officiel sans filtre : **13/14**. |
| **E-2** | Aucune autorité de R2 côté civique (`learning_plan_observations`, `CHECK` de source TCF-only) | ✅ **RESTE, entier.** Indépendant du grain : c'est l'écriture de l'observation qui manque. |
| **E-3** | L'axe des blocs est un enum en dur (`TcfDomainProfileDto.ORDRE`) | ✅ **RESTE.** Le bloc reste une thématique. |
| **E-4** | `journey.target_level` `NOT NULL` CECRL ; `getOrCreate` câblé `Module.TCF` | ✅ **RESTE.** ⚠️ **S'aggrave** : si la mention ne filtre plus rien (§4.4-B), l'objectif d'un cycle civique n'est plus qu'un **seuil**, ce qui rend `target_level` encore plus inadapté. |
| **E-5** | Le ledger de gratuité est façonné pour une analyse IA | ✅ **RESTE, entier.** |
| **E-6** | Le format de thème n'a pas d'autorité ; 40/32 dupliqué | ✅ **RESTE, et devient urgent** : §2.6 crée une **autorité de la répartition officielle**, qui doit être au même endroit. |
| **E-7** | Aucun tirage ne tient le ratio 12/40 | 🔺 **RESTE et MONTE en gravité** : ce n'était pas seulement 12/40, c'est **11/6/11/8/4 + par notion + le placement des MES**. Devient le **chantier prioritaire** (§2). |
| **E-8** | 176 MES invisibles du moteur | ✅ **RESTE**, et se précise : **108 hors périmètre officiel** (§6). |
| **E-9** | `CIV_PRINCIPES` × `NAT` = 20 questions, pool épuisé | 🛑 **TOMBE** — pas de pool par mention. **Remplacé** par un écart plus grave : sans filtre, aucun pool de thème n'est tendu ; **avec** filtre, CSP et NAT ne peuvent pas produire un examen conforme (§2.5). |
| **E-10** | Aucun historique de mention | ✅ **RESTE**, et se **réduit** : si la mention ne filtre plus le contenu, en changer n'invalide plus le travail fourni. Voir Q-F18 révisée. |
| **E-11** | 46 notions, la doc dit 40 | ✅ **RESTE**, et se complète : ni 40 ni 46 ne sont l'annexe I, qui en compte **14**. |
| **E-12** | `seuilTagging` documente un état périmé, en 3 copies | ✅ **RESTE** |
| **E-13** | `questionsParNotion`/`questionsParTheme` sans filtre `status` | ✅ **RESTE** |
| **E-14** | 17 connaissances non taguées | ✅ **RESTE** (tagging manuel, 0 LLM) |
| **E-15** | 11 templates « Focus » à 40 Q, matrice incomplète | 🔺 **RESTE et MONTE** : un Focus mono-thème à 40 Q est **structurellement non conforme** ; il n'a aucune place dans un examen blanc officiel. |
| **E-16** | `plancivique/` : 11 fichiers, pas 13 | ✅ RESTE |
| **E-17** | `uq_journey_user_target` n'existe plus | ✅ RESTE |
| **E-18** | `CivicDotation` n'est pas une dépendance déclarée du cycle | 🛑 **TOMBE, et s'inverse** : sans filtre de mention, `CivicDotation` perd 2 de ses 3 états et devient une **règle morte à supprimer** (§4.3). |
| **E-19** | Pas de fabrique `civicNotion(...)` | ✅ RESTE, + une fabrique pour les 14 notions officielles |
| **E-20** | *(la v1 s'arrête à E-19)* | — |

**Nouveaux écarts de la v2**

| # | Écart | Gravité |
|---|---|---|
| **E-21** | 🛑 **L'examen blanc global n'est conforme à l'arrêté sur aucun axe** (thématique, notion, nombre et placement des MES). 0/33. | **Bloquant, prioritaire, avant le cycle** |
| **E-22** | 🛑 **`exam_template_rules` ne sait pas exprimer un quota par notion** — aucune colonne de notion | Bloquant pour E-21 |
| **E-23** | 🛑 **Le fallback de `pickQuestionsForTemplate` désactive les règles en silence** quand le stock manque | Grave |
| **E-24** | 🛑 **Avec le filtre de mention, un examen conforme est impossible** pour CSP (Laïcité 1/2, MES Principes 1/6) et NAT (MES Principes 5/6) | Bloquant |
| **E-25** | ⚠️ **L'arrêté n'est cité nulle part dans le dépôt** — le référentiel des 46 notions a été « reconstruit à partir du corpus réel » (V058), sans source réglementaire | Grave (de gouvernance) |
| **E-26** | ⚠️ **`LotService` ignore déjà la mention** (l. 139, 173) alors que le plan, le diagnostic et les examens l'appliquent : le filtre n'est pas une règle du module | Moyen |
| **E-27** | **P2 Laïcité : 9 questions** — la seule notion officielle sous le seuil de R2 | Moyen (+11 questions) |
| **E-28** | **`vs_urgences_secours` (15 q.) ne se rattache à aucune notion officielle** | Moyen (un arbitrage) |
| **E-29** | ⚠️ **Le ministère publie des listes de questions par mention** — la banque publiée n'est pas unique, même si le programme l'est | À arbitrer (§5.2) |

### 8.3 Questions fermées — ce qui tombe, ce qui reste, ce qui s'ajoute

**Tombent**

| # | v1 | Pourquoi |
|---|---|---|
| **Q-F1** | grain thème sans étape de notion ? | **Reformulée** en Q-F1 bis ci-dessous |
| **Q-F2 / Q-F3** | β (séries recouvrantes) / γ (1 480 questions) | Sans objet : le grain officiel rend R2 applicable |
| **Q-F7** | option B de Q1 (observation polymorphe) ? | **Reformulée** : l'unité est une notion officielle sur 14 lignes stables, pas une notion interne sur 46 |
| **Q-F15** | produire ~5 MES Principes × CSP ? | Sans objet — pas de pool par mention |
| **Q-F16** | accepter d'épuiser Principes × NAT ? | Sans objet, même raison |

**Restent valides sans changement** : **Q-F4, Q-F5, Q-F6, Q-F8, Q-F9, Q-F10, Q-F11, Q-F12,
Q-F14, Q-F17, Q-F19, Q-F20.**

**Restent, reformulées**

| # | Question révisée |
|---|---|
| **Q-F13 bis** | Le tirage d'un examen blanc devient-il une **contrainte dure** portant sur **11/6/11/8/4 + le quota par notion + 12 MES placées en Principes et Droits** — et non plus seulement sur le ratio 12/40 ? *(oui recommandé)* |
| **Q-F18 bis** | Un changement de mention historise-t-il encore le cycle, **si la mention ne filtre plus le contenu** ? *(à reconsidérer : sans filtre, le travail fourni reste valide — le patron TCF **A27** « on met à jour l'objectif, on ne détruit pas le cycle » redevient le bon)* |

**Nouvelles**

| # | Question | Oui / Non |
|---|---|---|
| **Q-F1 bis** | Le cycle civique adopte-t-il les **14 notions officielles de l'annexe I** comme unité travaillable, en lieu et place des 46 notions internes ? | **Oui recommandé** — R2 s'applique alors sur 13/14, et le moteur TCF se transpose sans réinventer une règle |
| **Q-F22** | Le filtre de mention (`q.difficulty = :mention`) est-il **retiré de la lecture** côté civique, la colonne restant en base comme métadonnée éditoriale (§4.4-B) ? | **Oui recommandé** — c'est la seule façon de rendre un examen conforme tirable pour CSP et NAT. ⚠️ **À arbitrer au vu de §5.2** : le ministère publie des listes par mention |
| **Q-F23** | La conformité de l'**examen blanc global** (§2) passe-t-elle **avant** le cycle civique, en chantier séparé ? | **Oui recommandé** — c'est la promesse centrale du produit, et 0/33 examens sont conformes |
| **Q-F24** | Les **14 notions officielles** vivent-elles dans une **table de référence** (libellé, ordre, quota officiel, thématique) plutôt qu'en simple colonne de rattachement sur `civic_notions` (§3.5) ? | **Oui recommandé** — le tirage conforme, le cycle et l'écran ont besoin du même objet |
| **Q-F25** | `CivicDotation` et `questions-min-par-notion: 5` sont-ils **supprimés** une fois le filtre retiré, puisqu'ils ne discriminent plus rien (§4.3, §7.3) ? | **Oui recommandé** — « refonte = suppression immédiate de l'ancien » |
| **Q-F26** | Les **108 mises en situation hors périmètre** restent-elles du **contenu d'entraînement**, simplement exclues des examens blancs (§6.2-A) ? | **Oui recommandé** — ni retypage, ni reclassement |
| **Q-F27** | Produit-on les **11 questions de Laïcité** qui manquent (9 → 20) ? | **Oui recommandé** — le seul contenu que cet audit identifie comme nécessaire |
| **Q-F28** | `vs_urgences_secours` (15 q.) est-elle rattachée à **S2 Accès aux soins**, ou conservée hors examen ? | Arbitrage |
| **Q-F29** | Les **11 templates « Focus » mono-thème à 40 Q** sont-ils **dépubliés**, étant structurellement non conformes (E-15) ? | Arbitrage — ils ne peuvent plus s'appeler « examen blanc » |
| **Q-F30** | Lance-t-on le **contrôle de couverture** contre les listes publiques du ministère (§5.3, lecture 1) — sans import ? | Arbitrage. **0 € d'appel LLM**, c'est de l'extraction et du rattachement |
| **Q-F21** | Un **examen de thème** (format SejourFR, 20 Q / 16) contient-il des mises en situation dans les thématiques où l'examen réel n'en pose aucune (§6.3) ? | Arbitrage |

### 8.4 Conflits — mise à jour

| # | v1 | Statut v2 |
|---|---|---|
| **C-1** | R2 au grain notion ⇄ le contenu réel | 🛑 **RÉSOLU, et en faveur de la spec.** Le contenu **porte** R2 au grain officiel. L'écart que la v1 signalait n'existe plus, et α n'a plus à être proposée. |
| **C-2** | « 1 examen de thème à vie » ⇄ « slot 1 offert et rejouable » | ✅ **RESTE, entier** |
| **C-3** | Examen global premium ⇄ `civique-decouverte` gratuit | ✅ **RESTE** — et le brief tranche : **`civique-decouverte` reste gratuit** |
| **C-4** | Historiser sur changement de mention ⇄ A27 | 🔻 **S'ATTÉNUE** : si la mention ne filtre plus le contenu, **A27 s'applique tel quel** et il n'y a plus de conflit. Voir Q-F18 bis. |
| **C-5** | « Le civique sort du chantier » (D-23) | ✅ **RESTE** — à lever explicitement en ouvrant P8 |
| **C-6** | Pas de config civique ⇄ `sejourfr.civic-plan` | 🔻 **S'ATTÉNUE** : `questions-min-par-notion` disparaît (Q-F25), `questions-par-serie` reste un réglage du plan dérivé. |
| **C-7** | *(nouveau)* | 🛑 **L'arrêté ⇄ le produit.** Le référentiel interne a été « reconstruit à partir du corpus réel » (V058) et le corpus a été **écrit** par mention ; le produit en a déduit que « CSP, CR et NAT sont trois programmes différents ». L'arrêté dit **un** programme pour toutes les mentions. Le raisonnement de V058 est **circulaire**, et §4.2 le mesure : **aucune** des 976 questions n'est exclusive d'une démarche. **Résolution recommandée** : consigner une décision datée qui révoque la phrase de V058, et **nommer l'arrêté comme source** du référentiel. |

---

## 9. Découpage révisé

⚠️ Indicatif. **Aucune phase ouverte.** L'ordre a changé : **la conformité de l'examen passe
devant le cycle.**

| Phase | Contenu | STOP |
|---|---|---|
| **P8.0** | **Arbitrages.** Q-F1 bis, Q-F22, Q-F23, Q-F24 d'abord (elles commandent tout), puis le reste. Consigner à la suite de **D-24**, lever **D-23**, révoquer la phrase de V058 (C-7), **nommer l'arrêté**. Conformer `SPEC_cycle_plan_civique.md`. | 🛑 |
| **P8.A** 🔺 | **CONFORMITÉ DE L'EXAMEN BLANC** — chantier prioritaire et séparé (§2.6, E-21 → E-24). Une autorité de la répartition officielle **en code**, la contrainte par notion dans le tirage, le fallback encadré, les templates reprises ou dépubliées. **0 question à produire.** | 🛑 |
| **P8.1** | Corrections sans arbitrage : E-6, E-11 → E-14, E-16, E-17, E-19. | 🛑 |
| **P8.2** | **Référentiel officiel** : table des 14 notions + rattachement des 46 (Q-F24), retrait du filtre de mention (Q-F22), suppression de `CivicDotation` et `questions-min-par-notion` (Q-F25). Migration `V068` / `V296`. | 🛑 |
| **P8.3** | **Schéma du cycle** : E-4, E-3, S-1 → S-4, S-9, S-10 — avec l'unité **notion officielle**. | 🛑 |
| **P8.4** | **Moteur** : amorces, R1 (via `lot_theme_id`), R2 (E-2 — l'écriture d'observation civique), R3, déblocage D-15, cycle en attente, fin de cycle, historisation. | 🛑 |
| **P8.5** | **Freemium** : E-5, C-2, C-3. | 🛑 |
| **P8.6** | **Kits** : `BlocAccordion` accepte un en-tête de thématique, web **et** mobile dans la même passe. Les 4 autres primitives de cycle se réutilisent telles quelles. | 🛑 |
| **P8.7** | **Écrans** : Plan civique (5 blocs de thématique), Accueil. Suppression immédiate de l'ancien. Parité web ⇄ mobile dans la passe. **Aucun nouveau test front.** | 🛑 |
| **P8.8** | **Contenu** : les 11 questions de Laïcité (Q-F27). | 🛑 |
| **P8.9** | ⛔ **Historique des cycles — bloqué**, template non fourni. Autorisé en amont, après P8.7 : étendre `GET /api/me/plan/journey/history` au civique. | — |
| **P8.10** | **Documentation** : `docs/regles/plan.md`, `freemium.md`, `domaine.md`, les `CLAUDE.md`. Consigner les décisions autonomes à la suite de **A46**. | — |

---

## Annexe A — Table de correspondance complète : 46 notions internes → 14 notions officielles

`Q` = questions actives. `⚠️` = rattachement arbitré, voir §3.4.

### Principes et valeurs de la République — officiel 11 (3 + 2 + 6 MES)

| Notion interne | Q | Notion officielle | |
|---|---|---|---|
| `pv_symboles_devise` | 37 | **P1 Devise et symboles** | |
| `pv_laicite` | 9 | **P2 Laïcité** | |
| `pv_republique_democratie` | 8 | I1 Démocratie et droit de vote | ⚠️ principe, pas organe |
| `pv_egalite_non_discrimination` | 9 | D1 Droits fondamentaux | ⚠️ |
| `pv_libertes_ddhc` | 5 | D1 Droits fondamentaux | ⚠️ recouvrement **assumé en base** |

### Système institutionnel et politique — officiel 6 (3 + 2 + 1)

| Notion interne | Q | Notion officielle | |
|---|---|---|---|
| `inst_elections` | 25 | **I1 Démocratie et droit de vote** | |
| `inst_constitution` | 24 | **I2 Organisation de la République** | |
| `inst_president` | 25 | I2 | |
| `inst_gouvernement` | 19 | I2 | |
| `inst_parlement` | 34 | I2 | |
| `inst_collectivites` | 21 | I2 | |
| `inst_justice` | 20 | I2 | |
| `inst_ue` | 32 | **I3 Institutions européennes** | |

### Droits et devoirs — officiel 11 (2 + 3 + 6 MES)

| Notion interne | Q | Notion officielle | |
|---|---|---|---|
| `dd_textes_fondateurs` | 19 | **D1 Droits fondamentaux** | |
| `dd_libertes_limites` | 24 | D1 | |
| `dd_droits_sociaux` | 19 | D1 | ⚠️ chevauche S2, S3 |
| `dd_vie_privee_famille` | 18 | D1 | ⚠️ chevauche S4 |
| `dd_police_justice` | 14 | D1 | ⚠️ chevauche I2 |
| `dd_protection_europeenne` | 11 | D1 | ⚠️ chevauche I3 |
| `dd_devoirs_citoyen` | 19 | **D2 Obligations et devoirs** | |
| `dd_interdits_quotidien` | 15 | D2 | |
| `dd_infractions_peines` | 24 | D2 | |

### Histoire, géographie et culture — officiel 8 (3 + 3 + 2)

| Notion interne | Q | Notion officielle | |
|---|---|---|---|
| `hg_revolution` | 16 | **H1 Périodes et personnages** | |
| `hg_napoleon_xixe` | 10 | H1 | |
| `hg_republiques` | 20 | H1 | |
| `hg_guerres_resistance` | 26 | H1 | |
| `hg_conquetes_droits` | 19 | H1 | |
| `hg_europe` | 10 | H1 | ⚠️ chevauche I3 |
| `hg_geographie` | 27 | **H2 Territoires et géographie** | |
| `hg_patrimoine` | 13 | **H3 Patrimoine** | |
| `hg_litterature` | 13 | H3 | |
| `hg_arts_sciences` | 13 | H3 | |
| `hg_art_de_vivre` | 13 | H3 | |
| `hg_fetes_jours_feries` | 9 | H3 | ⚠️ chevauche P1 |

### Vivre dans la société française — officiel 4 (1 + 1 + 1 + 1)

| Notion interne | Q | Notion officielle | |
|---|---|---|---|
| `vs_papiers_identite` | 8 | **S1 S'installer** | |
| `vs_sejour_asile` | 12 | S1 | |
| `vs_nationalite_francaise` | 12 | S1 | |
| `vs_deplacements_route` | 7 | S1 | ⚠️ rattachement **faible** |
| `vs_sante_soins` | 11 | **S2 Accès aux soins** | |
| `vs_protection_sociale_aides` | 18 | S2 | ⚠️ chevauche S3 |
| `vs_travail_contrat_salaire` | 20 | **S3 Travailler** | |
| `vs_travail_entreprise` | 9 | S3 | |
| `vs_emploi_formation` | 5 | S3 | |
| `vs_ecole_scolarite` | 24 | **S4 Autorité parentale et éducation** | |
| `vs_famille_etat_civil` | 22 | S4 | |
| 🛑 `vs_urgences_secours` | **15** | **SANS RATTACHEMENT** | L'annexe I n'a pas de notion « urgences / forces de l'ordre » |

**Contrôle** : 46 notions rattachées, 0 non mappée, **783 questions**, ce qui recoupe exactement
le compte de questions taguées.

---

## Annexe B — Requêtes de mesure

Filtre de référence : `module = 'CIVIQUE' AND is_active = true AND status = 'ACTIVE'`.
La vue de correspondance qui sous-tend §3 et §7 :

```sql
CREATE TEMP VIEW map14 AS
SELECT n.id, n.code, n.theme_code,
  CASE n.code
    WHEN 'pv_symboles_devise'  THEN 'P1 Devise et symboles'
    WHEN 'pv_laicite'          THEN 'P2 Laicite'
    WHEN 'inst_elections'      THEN 'I1 Democratie et droit de vote'
    WHEN 'pv_republique_democratie' THEN 'I1 Democratie et droit de vote'
    -- … les 46 branches, cf. annexe A …
    WHEN 'vs_urgences_secours' THEN 'ZZ SANS RATTACHEMENT'
  END AS off14
FROM civic_notions n WHERE n.is_active;
```

La mesure décisive de §2.5 — « un examen conforme est-il tirable ? » :

```sql
WITH quota(off14, exige) AS (VALUES
  ('P1 Devise et symboles',3),('P2 Laicite',2),
  ('I1 Democratie et droit de vote',3),('I2 Organisation de la Republique',2),
  ('I3 Institutions europeennes',1),('D1 Droits fondamentaux',2),
  ('D2 Obligations et devoirs',3),('H1 Periodes et personnages',3),
  ('H2 Territoires et geographie',3),('H3 Patrimoine',2),
  ('S1 S installer',1),('S2 Acces aux soins',1),('S3 Travailler',1),
  ('S4 Autorite parentale et education',1)),
stock AS (
  SELECT m.off14,
    count(*) FILTER (WHERE q.question_type='CONNAISSANCE') AS tous,
    count(*) FILTER (WHERE q.question_type='CONNAISSANCE' AND q.difficulty='CSP') AS csp,
    count(*) FILTER (WHERE q.question_type='CONNAISSANCE' AND q.difficulty='CR')  AS cr,
    count(*) FILTER (WHERE q.question_type='CONNAISSANCE' AND q.difficulty='NAT') AS nat
  FROM map14 m JOIN questions q ON q.civic_notion_id = m.id
  WHERE q.module='CIVIQUE' AND q.is_active AND q.status='ACTIVE'
  GROUP BY 1)
SELECT q.off14, q.exige, s.tous,
       (s.tous >= q.exige) AS ok_sans_filtre,
       (s.csp >= q.exige AND s.cr >= q.exige AND s.nat >= q.exige) AS ok_les_3_mentions
FROM quota q JOIN stock s USING (off14) ORDER BY 1;
```

## Annexe C — Sources réglementaires

- [Arrêté du 10 octobre 2025 relatif au programme, aux épreuves et aux modalités d'organisation de l'examen civique — Légifrance](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000052381620)
- [Informations générales sur l'examen civique — Formation civique, ministère de l'Intérieur](https://formation-civique.interieur.gouv.fr/examen-civique/informations-g%C3%A9n%C3%A9rales-sur-lexamen-civique/)
- [Liste officielle des questions de connaissance — mention CSP](https://formation-civique.interieur.gouv.fr/examen-civique/liste-officielle-des-questions-de-connaissance-csp/)
- [Liste officielle des questions de connaissance — mention CR](https://formation-civique.interieur.gouv.fr/examen-civique/liste-officielle-des-questions-de-connaissance-cr/)
- [Questions de connaissance pour l'examen civique — Nationalité française (DGEF)](https://www.immigration.interieur.gouv.fr/documentation/guides-textes-et-brochures/questions-de-connaissance-pour-lexamen-civique-nationalite-francaise.html) — page en 403 depuis cet environnement ; PDF référencé `examen-civique-naturalisation-questions-de-connaissance-20251212.pdf`
- [Examen civique — section du site Formation civique](https://formation-civique.interieur.gouv.fr/examen-civique/)

---

> ⛔ **FIN DE LA PHASE 0 — v2.** Aucune implémentation ouverte. Deux arrêts distincts :
> **(1)** la non-conformité de l'examen blanc (§2) est **signalée et chiffrée, non corrigée** —
> chantier à part, prioritaire, à arbitrer séparément ;
> **(2)** le cycle civique attend les réponses à **Q-F1 bis, Q-F22, Q-F23 et Q-F24**, qui
> commandent son périmètre. Aucune question de contenu n'est à produire avant ces réponses,
> hors les **11 questions de Laïcité** que §7.4 identifie.

---
---

# Annexe P8.0 (2026-09-19) — périmètre de fichiers et plan du contrôle de couverture

Livrables 3 et 4 de **P8.0**, produits après `REPONSES_AUDIT_civique_v2.md`.
Arbitrages qui les commandent : `docs/decisions/plan-parcours-tcf.md` **D-25 → D-37**.

> ⛔ **Rien n'est touché ici.** Cette annexe **liste** ce que les phases devront modifier. Elle ne
> modifie aucun fichier, n'ouvre ni Q-F30 ni P8.A, et ne produit aucune extraction.

---

## A. Numéros de migration disponibles

| Tranche | Dossier | Dernier | À prendre |
|---|---|---|---|
| Schéma | `db/migration/00_schema/` | `V067__schema_cycle_journey_et_freebie.sql` | **`V068`** (P8.2), **`V069`** (P8.3) |
| Contenu civique | `db/migration/200_civique/` | `V295__corrections_factuelles.sql` | **`V296`** (P8.A), **`V297`** (P8.2), **`V298`** (P8.8) |
| Référence | `db/migration/100_reference/` | `V114` | `V115` si les templates sont reprises plutôt que dépubliées |

---

## B. Périmètre de **P8.A** — conformité de l'examen blanc *(D-29, D-30, D-31)*

### B.1 L'autorité de la répartition officielle — **tranchée : c'est la table** (D-38)

🛑 **P8.A LIT la table des 16, elle ne redéclare aucun quota.** Le point laissé ouvert dans la
première version de cette annexe est arbitré : **le quota par unité vit dans la table**, créée en
P8.2.

| Fichier | Travail |
|---|---|
| *(la table des 16 unités, créée en **P8.2** — cf. §C.1)* | **Porte `quota_examen`**, unité par unité. Seule autorité du nombre. |
| `backend_sejourfr/src/main/java/com/sejourfr/app/enums/CivicExamFormat.java` | **Étendre seulement de ce qui n'est PAS par unité** : 40 questions, seuil 32, 45 min, partage **28 / 12**. 🛑 **Aucun quota d'unité ici**, et **aucun total par thématique**. |
| *(le service de composition)* | **Dérive** 11 / 6 / 11 / 8 / 4 par **somme des quotas d'unité**. 🛑 Ces cinq nombres ne sont déclarés nulle part : les écrire en ferait une 2ᵉ copie. |

🛑 **Les trois garde-fous de D-38 sont des exigences de P8.2, et P8.A en dépend** :

1. la table est **seedée par migration et n'est pas éditable en admin** — aucun endpoint, aucun
   écran, aucun `AdminCivicUniteController` ;
2. un **`CHECK` ou un test normatif** vérifie que la somme des 16 quotas vaut **40** et que les
   mises en situation totalisent **12** ;
3. un **test verrouille les 16 lignes et leurs quotas**, l'arrêté cité en commentaire.

> **Clause de repli (D-38, verbatim)** : « Si ces trois garde-fous ne tiennent pas, reviens vers moi
> **avant d'écrire la migration** — on remettra le quota en code. »

🔺 **Conséquence sur l'ordre des phases, remontée au propriétaire** : P8.A **ne peut plus précéder
P8.2**, puisqu'elle lit la table. L'ordre devient **P8.1 → P8.2 → P8.A**. La conformité de l'examen
blanc reste le **premier chantier de code** ; elle a désormais une dépendance.

### B.2 Les trois chemins de composition

| Fichier | Travail |
|---|---|
| `service/attempt/AttemptCompositionService.java` | 🛑 **`composeCiviqueFullExam(difficulty, size)`** — remplacer `perTheme = max(1, size/themes.size())` par la répartition officielle, et poser la contrainte de `question_type` par thématique. 🛑 **`pickQuestionsForTemplate`** — **encadrer le fallback** (exigence 3 de D-29) : un examen officiel qui ne peut pas satisfaire ses règles **échoue bruyamment**. |
| `service/AttemptService.java` | La branche `MOCK_EXAM` civique (l. 159-234) : `civicThemeExam`, `civiqueFullExam`, et le passage de `qType` à `null` (l. 222). |
| `repository/QuestionRepository.java` | Les requêtes de tirage doivent accepter une **unité officielle** en plus du thème et du type. Lignes concernées : **50, 80, 142, 164, 232, 268, 298, 309, 366**. |
| `manager/QuestionManager.java` | `findRandom`, `findRandomExcluding`, `findOrderedExcluding`, `countActiveMatching` — signatures à étendre. |

### B.3 Le format de l'examen de thème *(D-31 ; le déménagement lui-même est en P8.1)*

| Fichier | Travail |
|---|---|
| `service/AttemptService.java` | Appliquer les **proportions officielles internes** à la thématique : aucune mise en situation en T2, T4, T5 (Q-F21). |

### B.4 Les templates

| Fichier | Travail |
|---|---|
| `db/migration/200_civique/V296__*.sql` | **Dépublier les 11 templates « Focus »** (D-30) : `is_published = false`. 🛑 **Ne pas supprimer les lignes** — des `attempts` les référencent par `exam_template_id` (15 en base). ⚠️ **D-39 en fait la règle générale du dépôt**, pas une précaution locale : *ne jamais supprimer une ligne référencée par un `attempt`*. La bonne mécanique est toujours la **désactivation** (`is_published`, `is_active`, ou une colonne de retrait dédiée), jamais le `DELETE`. Vaut pour `exam_templates`, `questions`, `themes`, `civic_notions` et la table des 16. |
| `entity/ExamTemplateRule.java` | ⚠️ **Décision à prendre en ouvrant la phase** : soit `exam_template_rules` reçoit une colonne d'unité officielle (`V296`), soit **les templates sortent du chemin de l'examen officiel** et ne servent plus qu'aux variantes d'entraînement. **La seconde est plus simple** — la composition officielle est du code, pas une donnée. |
| `service/AdminExamTemplateService.java` | `suggestForCivique(target, poolSize, tp)` (l. 128) : la suggestion doit refléter la répartition officielle. |
| `exam_templates` (données) | Les **9** templates MIX restants (5 règles à 8 questions) : reprises ou dépubliées selon la décision ci-dessus. |

### B.5 Tests *(obligatoires — « backend : tests dans la même passe »)*

| Fichier | Travail |
|---|---|
| `src/test/java/com/sejourfr/app/service/diagnosticcivique/CivicExamFormatTest.java` | **Étendre** : verrouiller les quotas officiels et leur somme à 40 (28 + 12). |
| *(nouveau)* IT de composition | Un examen global tiré **est** conforme : 11/6/11/8/4, quota par unité, 12 MES **uniquement** en T1 et T3. |
| *(nouveau)* IT du fallback | Stock artificiellement insuffisant ⇒ l'examen **échoue**, il ne se dégrade pas. |
| *(nouveau)* IT de l'examen de thème | Aucune MES en T2/T4/T5. |

### B.6 Ce que P8.A ne touche **pas**

🛑 **`service/diagnosticcivique/CivicDiagnosticComposer.java` et la configuration
`sejourfr.civic-diagnostic`** (`connaissances: 28`, `mises-en-situation: 12`, `min-par-theme: 4`,
`config-version: 1`). C'est le **seul** endroit du dépôt qui tient le partage officiel (exigence 5
de D-29). ⚠️ Le **retrait du filtre de mention** dans ce composer relève de **P8.2**, pas de P8.A.

---

## C. Périmètre de **P8.2** — référentiel officiel et retrait du filtre *(D-26, D-27)*

### C.1 Migrations

| Fichier | Travail |
|---|---|
| `db/migration/00_schema/V068__*.sql` | **Créer la table des 16 unités officielles** : `code`, `label`, `theme_code`, `display_order`, `quota_examen`, `porte_mises_en_situation` (ou un type d'unité). 🛑 **Citer l'arrêté du 10 octobre 2025 (NOR INTV2527907A) en en-tête** — l'audit a relevé qu'il n'est cité nulle part dans le dépôt (D-25). Ajouter la **FK de rattachement** sur `civic_notions`. ⚠️ **Pas de `merged_into_id`** : cette table suit un arrêté, elle n'a pas de fusions (ne pas copier la forme de `civic_notions`). |
| `db/migration/200_civique/V297__*.sql` | **Les 46 rattachements** (annexe A de ce rapport), dont `vs_urgences_secours` → **S2 Accès aux soins** (D-35, Q-F28). **Taguer les 17 questions de connaissance** restantes à la main (Q-F14) — 🛑 **aucun appel LLM**. |

### C.2 Le retrait du filtre de mention — les 4 points de lecture

| Fichier : ligne | Travail |
|---|---|
| `repository/CivicPlanRepository.java:112` | `questionsParNotion(mention)` — retirer `AND q.difficulty = CAST(:mention AS varchar)`. ⚠️ **Et ajouter le filtre `status` manquant** (E-13). |
| `repository/CivicPlanRepository.java:129` | `questionsParTheme(mention)` — idem, `status` compris. |
| `repository/CivicPlanRepository.java:166` | `tirageSerieCiblee(...)` — idem. ⚠️ **Et corriger le `LIMIT` qui ne complète pas** : une unité à 9 questions rend une série de 9, en silence (D-27). |
| `service/diagnosticcivique/CivicDiagnosticComposer.java:72,80,86` | Les 3 tirages du diagnostic. 🛑 **Le format 28 + 12 ne bouge pas**, seul le filtre de mention part. |
| `service/AttemptService.java:1100-1112` | `resolveDifficulty` — **LA porte**. Le civique rend désormais `null`, comme le TCF. C'est le point qui alimente les examens et l'entraînement. |
| `enums/TargetProcedure.java:58-74` | `mentionCivique()` / `mentionCivique(procedure)` : 3 appelants restent — `CivicDiagnosticService:216`, `CivicPlanService:143`, `CivicPlanService:461`. Les retirer, ou ne garder la méthode que pour l'**objectif** du cycle (D-32). |
| `service/LotService.java:139,173` | ✅ **Rien à faire** — ils passent déjà `null`. À mentionner dans la décision : le filtre n'était une règle que sur 3 chemins sur 4 (E-26). |

### C.3 Les suppressions *(« refonte = suppression immédiate de l'ancien »)*

| Fichier | Travail |
|---|---|
| `service/plancivique/CivicDotation.java` | 🛑 **SUPPRIMER** l'enum entier (68 l.). |
| `src/test/java/com/sejourfr/app/service/plancivique/CivicDotationTest.java` | 🛑 **SUPPRIMER**. |
| `config/CivicPlanProperties.java` | Retirer `questionsMinParNotion` (+ son javadoc, dont la phrase révoquée par D-27). |
| `src/main/resources/application.yaml` | Retirer `sejourfr.civic-plan.questions-min-par-notion: 5` et son bloc de commentaire. |
| `service/plancivique/CivicPlanService.java` | Retirer les **5** filtres `dotation().estServable()` (`proposables`, `aRevoir`, `solides`, `servables`, `themeLignes`) et le garde de `demarrerSerie`. Retirer `dotationNotions` / `dotationThemes` de `calculer()`. |
| `manager/CivicPlanManager.java` | `questionsParNotion` / `questionsParTheme` : signature sans mention, ou suppression si plus aucun lecteur. |
| `dto/CivicPlanDto.java` | Retirer le champ `dotation` (l. 299) et son import (l. 6). 🛑 **Changement de DTO ⇒ les 2 miroirs front dans la même passe.** |

### C.4 Les fronts — parité obligatoire

| Fichier : ligne | Travail |
|---|---|
| `web_sejoufr/lib/types.ts:4282-4290, 4353-4354` | Retirer `CivicDotation` et le champ `dotation` de la cible. |
| `web_sejoufr/lib/civic-plan.ts` | Vérifier qu'aucun libellé ne dérive de la dotation. |
| `web_sejoufr/app/_components/plan/CivicPlanPanel.tsx` | Retirer toute lecture de `dotation`. |
| `mobile_sejourfr/lib/core/models/civic_plan_models.dart:59-79, 177, 215-216, 245, 364` | Retirer l'enum `CivicDotation`, le champ, son `fromWire` et le commentaire « Cibles servables du thème ». |
| `mobile_sejourfr/lib/screens/plan/civic_plan_view.dart` | idem. |
| `mobile_sejourfr/lib/screens/plan/civic_plan_labels.dart` | Vérifier les libellés gelés. |

⚠️ **Aucun nouveau test front.** Vérification : `npx tsc --noEmit` · `npm run build` ·
`flutter analyze`. Les tests existants (16 TS + 23 Dart) doivent rester verts ; un test rendu rouge
par ce changement se **met à jour**.

### C.5 Tests backend

| Fichier | Travail |
|---|---|
| `service/plancivique/CivicPlanServiceIT.java` | Mettre à jour : plus de dotation, plus de mention. |
| `service/plancivique/CivicPlanNotionParcoursIT.java` | Idem, et **ajouter** le grain **unité officielle**. |
| `src/test/java/com/sejourfr/app/support/TestData.java` | **Ajouter** une fabrique `civicNotion(...)` (E-19, ≥ 2 occurrences manuelles dans les IT existants) **et** une fabrique de l'unité officielle. |
| *(nouveau)* IT du référentiel | Les **16** unités existent, les **46** notions sont rattachées, **aucune** orpheline, la somme des quotas fait **40**. |

### C.6 Documents à corriger dans la passe

| Fichier | Correctif |
|---|---|
| `config/CivicPlanProperties.java` (javadoc de `seuilTagging`) | « au lancement de L10, 0 question sur 1 016 est taguée — les cinq thèmes sont donc au grain THEME » ⇒ **faux depuis le 2026-09-11** : 97–98,6 %, les 5 thèmes sont au grain NOTION (E-12). |
| `src/main/resources/application.yaml` (bloc `civic-plan`) | Même phrase, 2ᵉ copie. |
| `service/plancivique/CivicPlanService.java` (javadoc de classe) | Même phrase, 3ᵉ copie. |
| `docs/regles/domaine.md` | **Nommer l'arrêté comme source** du référentiel civique ; les 16 unités officielles ; la révocation de la phrase de V058 (D-25). |

---

## D. Périmètre indicatif des phases suivantes

*Listé pour que P8.2 et P8.3 ne se marchent pas dessus. Détail à produire en ouvrant chaque phase.*
*Ordre révisé : §F.*

| Phase | Fichiers clés |
|---|---|
| **P8.1** rangement | `enums/CivicExamFormat.java` (+ le format de thème), `service/AttemptService.java` (les **6** constantes privées l. 63-71), `CivicExamFormatTest` |
| **P8.3** schéma du cycle | `V069` : `journey.target_procedure`, `entry_score`/`exit_score`, `journey_lot.theme_id`, `journey_step.theme_id` + unité officielle, `chk_learning_plan_observation_source`. Miroirs JPA : `entity/Journey.java`, `JourneyLot.java`, `JourneyStep.java`, `LearningPlanObservation.java` |
| **P8.4** moteur | `service/journey/JourneyService.java` (🛑 `Module.TCF` en dur l. 164, 177 + la sortie sèche sur `niveauVise` = `null`), `JourneyBlocResolver.java` (l'axe des blocs), `JourneyReadService.java` (`etapesAuQuota`), `JourneyLotBuilder.java`, `JourneyHistoryService.java`, **l'écrivain d'observations civiques** (E-2, il n'existe pas) |
| **P8.5** freemium | `service/AttemptService.java` (`enforceMockExamSlotAccess` retiré du chemin civique, D-33) |
| **P8.6** kits | `web_sejoufr/app/_components/sejour/SejourKit.tsx` (`BlocAccordion`) ⇄ `mobile_sejourfr/lib/core/widgets/sejour/sejour_kit.dart` (`SfBlocAccordion`) — **en-tête de thématique**, dans la même passe |
| **P8.7** écrans | `CivicPlanPanel.tsx` ⇄ `civic_plan_view.dart`, `civic-plan.ts` ⇄ `civic_plan_labels.dart`, l'Accueil |
| **P8.8** contenu | `V298` : les **11** questions de Laïcité (D-35) |
| **P8.9** | ⛔ **bloquée** — template non fourni. Autorisé après P8.7 : `service/journey/JourneyHistoryService.java` étendu au civique |

---

## E. Plan du **contrôle de couverture** (Q-F30 / D-28)

⛔ **Plan seulement. Aucune extraction n'est lancée.**

### E.1 La question, et pourquoi elle précède P8.A

> Les trois listes publiques du ministère se **recouvrent-elles largement**, ou portent-elles des
> contenus **réellement distincts** ?

| Résultat | Conséquence |
|---|---|
| **Recouvrement large** | Le retrait du filtre de mention est confirmé **définitivement**, y compris pour la composition des examens blancs. |
| **Divergence réelle** | Le filtre revient **pour la seule composition de l'examen blanc**, jamais pour l'entraînement ni pour le cycle, et le rapport dit **quelles questions écrire par mention**. |

🛑 **Dans les deux cas, l'entraînement et le cycle restent sans filtre** (D-28). C'est pourquoi P8.2
peut être planifiée sans attendre : seul le périmètre de **P8.A** dépend du résultat.

### E.2 Les trois sources

| # | Source | Forme | Volume annoncé |
|---|---|---|---|
| 1 | `formation-civique.interieur.gouv.fr/examen-civique/liste-officielle-des-questions-de-connaissance-csp/` | page HTML, énoncés en liste, groupés par thématique | **≈ 212** (P 47 · I 49 · D 40 · H 43 · S 33) |
| 2 | `…/liste-officielle-des-questions-de-connaissance-cr/` | idem | **≈ 205** (≈ 40 · 50 · 35 · 40 · 40) |
| 3 | `immigration.interieur.gouv.fr/documentation/examen-civique/…-nationalite-francaise.html` → PDF `examen-civique-naturalisation-questions-de-connaissance-20251212.pdf` | **PDF**, 2025-12-12 | **non mesuré** |

⚠️ **Obstacles connus** : la source 3 répond **403** depuis cet environnement — le PDF devra être
récupéré par le propriétaire, ou par un autre chemin. Et **aucune** des trois ne fournit les
**réponses** : seuls les énoncés sont publics.
⚠️ **Les mises en situation ne sont pas publiées** : le contrôle ne porte que sur les **28
connaissances** du format, jamais sur les 12 mises en situation.

### E.3 Les étapes — **le recouvrement d'abord** (D-40)

🛑 **L'ordre a été inversé.** La question décisive de E.1 se répond **sans rattacher quoi que ce soit
aux 16 unités**. Le rattachement fin est le poste coûteux : il ne se paie pas pour répondre à une
question qui n'en a pas besoin.

**Partie 1 — inconditionnelle : le recouvrement**

1. **Extraire** — un énoncé par ligne, avec sa thématique de publication et sa liste d'origine
   (CSP / CR / NAT). Sortie : un TSV par liste, dans `scripts/` sur le patron de
   `scripts/pre-tagging/tsv/`. 🛑 **Aucun appel LLM** : c'est du parsing HTML et PDF.
2. **Mesurer le recouvrement** — apparier les énoncés entre les trois listes : à l'identique d'abord,
   puis quasi-identiques après normalisation (casse, accents, ponctuation, espaces, apostrophes).
   Sortie : un identifiant d'énoncé unique et, pour chacun, **les listes où il figure**.
   🛑 **C'est le livrable décisif, et il s'arrête là.**

**⛔ STOP** — le résultat décide si l'examen blanc se compose par mention (**D-28**). On remonte le
chiffre avant d'aller plus loin.

**Partie 2 — ⚠️ conditionnelle, seulement si elle sert encore**

3. **Rattacher aux 16 unités**, puis **croiser avec les 800** questions de connaissance actives du
   stock. ⚠️ **Le rattachement fin est le poste de travail réel** : la thématique est donnée par la
   source, l'unité **ne l'est pas**.

🛑 **Aucun appel LLM, à aucune étape.** Si la comparaison directe de l'étape 2 se mesure mal, on
**remonte le problème avec un chiffre** — combien d'énoncés ne s'apparient pas, et pourquoi — avant de
proposer quoi que ce soit de payant (**D-40**).

### E.4 Les tableaux du livrable

**Partie 1 — le seul tableau qui doit sortir**

| # | Tableau | Ce qu'il doit dire |
|---|---|---|
| 1 | **Recouvrement entre les 3 listes** | Énoncés communs aux 3 · communs à 2 · exclusifs à une seule. **C'est ce tableau qui répond à E.1**, et c'est le seul dont P8.A a besoin. |

**Partie 2 — seulement si la partie 1 la justifie**

| # | Tableau | Ce qu'il doit dire |
|---|---|---|
| 2 | **Couverture par unité officielle** | Pour chacune des 16 : énoncés officiels · questions SejourFR · appariés · **manquants** |
| 3 | **Couverture par liste** | Pour chaque mention : part de sa liste couverte par le stock SejourFR |
| 4 | **Où écrire** | Les unités où le stock **ne couvre pas** le programme, par volume décroissant |

⚠️ **Si la partie 2 est jouée, un résultat est déjà connu et doit être recoupé** : l'audit v2 a établi
que **P2 Laïcité** est la seule unité sous 20 questions (9). Le tableau 4 doit le retrouver — s'il en
trouve d'autres, c'est que le rattachement fin diverge de celui de l'annexe A, et **c'est un
signal**, pas une erreur à corriger en silence.

⚠️ **Et si la partie 2 n'est pas jouée, rien n'est perdu** : les 11 questions de Laïcité sont déjà
arbitrées (**D-35**, P8.8), et elles ne dépendent pas de ce contrôle.

### E.5 Ce que le contrôle ne fait **pas**

- ⛔ **Aucun import d'énoncé.** Les listes sont publiques, donc sans avantage à les reproduire, et
  elles n'ont **pas leurs réponses** — un import serait du travail éditorial déguisé en migration.
- ⛔ **Aucune production de question.** Le livrable **dit où écrire**, il n'écrit pas.
- ⛔ **Aucune modification du stock existant** : ni retypage, ni reclassement, ni retagging au-delà
  des 17 questions déjà arbitrées (Q-F14).
- ⛔ **Aucun appel LLM**, à aucune étape (**D-40**) — pas même « proposé avec son coût » avant d'avoir
  remonté le chiffre d'échec de la comparaison directe.
- ⛔ **Aucun rattachement aux 16 unités tant que la partie 1 n'a pas conclu**, et aucun si elle rend
  la partie 2 inutile.

---

## F. Ordre des phases — révisé par D-38

**P8.0** (fait) → **Q-F30** partie 1 (le recouvrement seul, D-40) → **P8.1** (rangement) →
**P8.2** (référentiel officiel : la table des 16 et ses 3 garde-fous, retrait du filtre) →
**P8.A** (conformité de l'examen blanc) → **P8.3** (schéma du cycle) → **P8.4** (moteur) →
**P8.5** (freemium) → **P8.6** (kits) → **P8.7** (écrans) → **P8.8** (les 11 questions de Laïcité).
**P8.9** : ⛔ bloquée.

🔺 **P8.A a glissé derrière P8.2, et c'est une conséquence de D-38, pas un changement de priorité.**
Le quota par unité vivant dans la table, la composition conforme ne peut pas s'écrire avant que la
table existe. La conformité de l'examen blanc reste le **premier chantier de code** ; P8.1 et P8.2
sont les deux passes qui la préparent. **Point remonté, pas arbitré seul.**

---

> ⛔ **FIN DE P8.0.** Les quatre livrables sont produits, puis **amendés par les 3 arbitrages du
> 2026-09-19** (D-38, D-39, D-40) :
> **(1)** `docs/decisions/plan-parcours-tcf.md` — **D-25 → D-40**, datées 2026-09-19, chaque
> révocation citée verbatim avec son origine ;
> **(2)** `SPEC_cycle_plan_civique.md` conformée ;
> **(3)** le périmètre de fichiers de P8.A et P8.2 (§B, §C), **sans les toucher** ;
> **(4)** le plan du contrôle de couverture (§E), **sans extraction** — désormais en **deux parties**,
> la seconde conditionnelle.
> **Ni Q-F30 ni P8.A ne sont ouvertes.** J'attends le go.
