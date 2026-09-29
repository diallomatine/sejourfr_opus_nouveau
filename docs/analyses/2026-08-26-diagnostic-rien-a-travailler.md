# Pourquoi l'EO n'a « rien à travailler », et pourquoi l'EE n'affiche qu'une ligne

> Rapport d'analyse — 2026-08-26. **Aucune correction appliquée.**
> Compte observé : `billodiallo2@gmail.com` (`1a55f230-…`), créé le 2026-08-26 00:16,
> objectif **NAT → B2**, diagnostic `fe35354d-…` terminé `COMPLETED` à 00:22.
> Tout ce qui suit est lu **en base locale**, aucun appel LLM.

---

## 1. Le verdict en une phrase

Le candidat n'a **rien** à travailler en EO parce que trois règles indépendantes se
sont additionnées : le correcteur n'a trouvé **aucune fragilité** sur les 8 compétences
qu'il avait le droit d'observer, le Plan a classé l'EO **« pas encore prioritaire »**
(elle est *au-dessus* du palier en construction), et le budget d'apprentissage — **5
places pour les 4 épreuves réunies** — était déjà consommé par l'EE. Aucun des trois
n'est un bug isolé : c'est leur **composition** qui produit un écran vide.

Et l'EE n'affiche **pas** une seule chose à travailler : elle en a **5**. Le rideau
freemium n'en montre qu'une en clair — c'est exactement ce que dit le libellé
« **1 sur 5** ».

---

## 2. Ce que la base contient réellement

### 2.1 Ce que le correcteur a rendu

| Épreuve | Niveau estimé | Compétences observées | SOLID | TO_REINFORCE | PRIORITY |
|---|---|---|---|---|---|
| EE (`3a2e427d-…`) | **A2** | 8 | 5 | 3 | **0** |
| EO (`a79376ce-…`) | **B1** | 8 | **8** | 0 | **0** |

EE fragiles : `EE1-C8` (HIGH), `EE2-C3` (MEDIUM), `EE3-C3` (MEDIUM).
EO : `EO1-C1`, `EO1-C3`, `EO2-C2`, `EO2-C3`, `EO2-C4`, `EO2-C7`, `EO3-C1`, `EO3-C3` —
**toutes SOLID, toutes en confiance HIGH**, y compris les deux compétences **B2**
(`EO3-C1`, `EO3-C3`) alors que le candidat est estimé B1.

Résumé de session (`diagnostic_sessions.summary_json`) : `priority_skill_codes =
["EE1-C8", "EE2-C3"]`. **Aucune priorité EO** — il n'y en avait aucune à dériver.

### 2.2 L'allowlist du diagnostic : 8 sur 24, par construction

```
TCF_EE : EE1-C1 A2, EE1-C8 A2, EE2-C2 B1, EE2-C3 B1, EE2-C5 B1, EE2-C7 B1, EE3-C1 B1, EE3-C3 B2
TCF_EO : EO1-C1 A2, EO1-C3 A2, EO2-C2 B1, EO2-C3 B1, EO2-C4 B1, EO2-C7 B1, EO3-C1 B2, EO3-C3 B2
```

Une production de diagnostic ne peut donc **jamais** rien dire de **16 compétences sur
24** par épreuve. Ce n'est pas un défaut — c'est la contrepartie assumée d'un diagnostic
à deux productions. Mais ça veut dire que « rien à retravailler » ne signifie jamais
« rien à apprendre » : ça signifie « rien de fragile **parmi les 8 regardées** ».

### 2.3 L'état réel du référentiel pour ce candidat

| Section | Palier | Jamais travaillée | Solide | À renforcer |
|---|---|---|---|---|
| EE | A2 | 6 | 1 | 1 |
| EE | B1 | 6 | 4 | 1 |
| EE | B2 | 4 | 0 | 1 |
| EO | A2 | 6 | 2 | 0 |
| EO | B1 | **4** | 4 | 0 |
| EO | B2 | **6** | 2 | 0 |

**16 compétences EO sur 24 n'ont jamais été touchées**, dont 6 au palier B2 — celui qui
sépare le candidat de son objectif. L'écran lui dit pourtant qu'il n'a rien à faire.

---

## 3. La chaîne de causes, maillon par maillon

### Maillon 1 — Le correcteur ne pose (presque) jamais `PRIORITY`, et ici il n'a rien trouvé de fragile

Sur l'EO, les 8 compétences ressortent `SOLID` / `HIGH`. Le dépôt sait déjà que le
correcteur range ses faiblesses en `TO_REINFORCE` et ne pose quasiment jamais
`PRIORITY` (`LearningPlanPriorityResolver`, javadoc de `actionable`) — ici il n'a même
pas posé de `TO_REINFORCE`. **Aucune fragilité EO ⇒ aucune priorité EO.** C'est
légitime et voulu : `SOLID` et `NOT_OBSERVED` ne deviennent jamais une fragilité pour
remplir un écran.

⚠️ À noter quand même : deux compétences **B2** notées `SOLID` en confiance `HIGH` sur
un monologue de ~100 s, chez un candidat estimé B1 par le même appel. C'est une
générosité de notation qui mérite sa propre mesure (§7.5), indépendamment du reste.

### Maillon 2 — Le palier en construction est **global**, pas par domaine

`PlanCycleResolver.palierVise` (`PlanCycleResolver.java:210`) : le palier du cycle est
le premier cran **strictement au-dessus du niveau global**, plafonné par l'objectif. Le
niveau global est le **plancher des domaines évalués** — ici `min(EE=A2, EO=B1) = A2`,
donc le cycle construit **B1** pour les quatre domaines à la fois.

Conséquence directe : les **6 compétences B2 de l'EO** ne sont candidates à rien. Elles
ne le deviendront que quand le niveau **global** passera B1, c'est-à-dire quand l'**EE**
aura progressé. Le domaine le plus avancé attend le plus faible.

### Maillon 3 — Le Plan classe l'EO « pas encore prioritaire »

`PlanCycleResolver.priorite` (`:361`), cascade lue de haut en bas. Pour l'EO :
niveau `B1`, aucune priorité portée, `vise = B1` → `niveau < vise` est **faux** ;
objectif `B2`, `B1 >= B2` est **faux** → **`PAS_ENCORE_PRIORITAIRE`**.

C'est explicitement la règle du brief §93 : *le Plan cible le domaine qui bloque le
palier courant, pas celui qui est déjà devant*. Décision de design, pas accident — mais
c'est elle qui autorise une épreuve à n'avoir aucune action.

### Maillon 4 — Le budget d'apprentissage est **global** et déjà consommé

`LearningPlanService.java:214-216` :

```java
List<Skill> acquisitions = acquisitionSelector.select(
        profil.cycle(), profil.domaines(), lastActivity.keySet(),
        LearningPlanPriorityResolver.MAX_PRIORITIES - actionable.size());
```

`MAX_PRIORITIES = 5` (`LearningPlanPriorityResolver.java:54`) est un plafond **pour tout
le Plan**, pas par épreuve. Ici : 3 fragilités EE ⇒ **limite = 2**.

`PlanAcquisitionSelector` trie ensuite par **urgence de domaine** (`PlanDomainPriority`,
ordinal) : `FORTE` (EE) avant `PAS_ENCORE_PRIORITAIRE` (EO). Les **deux** places
restantes partent donc en EE.

**Le compte exact des acquisitions réellement disponibles** (palier B1, jamais
travaillées) :

| Domaine | Candidates | Servies |
|---|---|---|
| EE | `EE2-C1`, `EE2-C4`, `EE2-C6`, `EE2-C8`, `EE3-C2`, `EE3-C4` (6) | **2** (`EE2-C1`, `EE2-C4`) |
| EO | `EO2-C1`, `EO2-C5`, `EO2-C6`, `EO2-C8` (4) | **0** |

**10 actions pédagogiques réelles existaient, 2 ont été servies.** Ce n'est pas un
manque de contenu : c'est un plafond d'affichage utilisé comme budget de production.

### Maillon 5 — La carte d'épreuve n'a **aucune source propre**

`PlanDomainSkillResolver.java:118` : la colonne `nature` d'une compétence est
`natures.get(skill.getId())` — c'est-à-dire **exactement les cartes que le Plan vient
d'empiler**. Rien d'autre.

Côté mobile, `diagnostic_result.dart:460` :

```dart
final work = [ ...priority, ...reinforce, ...acquire ];   // acquire ⇔ nature == A_ACQUERIR
```

Donc : **le budget global de 5 décide de ce que chacune des 4 cartes d'épreuve a le
droit d'afficher.** L'EO se retrouve avec `work = []`, 8 lignes solides et 16 lignes
« pas encore assez de données ». Le front est fidèle ; il n'a rien à corriger.

---

## 4. Réponse aux deux questions posées

**« Pourquoi en EO on n'a pas de quoi retravailler alors qu'on est à B1 ? »**
Parce que les 8 compétences observées sont solides (maillon 1), que le Plan considère
l'EO comme non prioritaire tant que l'EE n'a pas rattrapé B1 (maillons 2-3), et que les
2 places d'apprentissage restantes sont parties en EE (maillon 4). Ses 4 compétences B1
jamais travaillées et ses 6 compétences B2 existent — elles ne sont simplement jamais
proposées.

**« Et l'EE à A2, une seule chose proposée ? »**
Non : l'EE en a **5** (3 fragilités + 2 acquisitions). Le compte affiché « 1 sur 5 » est
littéral — `diagnosticFreeWorkCount(visible, total)` : le compte **sans abonnement**
n'en voit qu'une en clair, les 4 autres sont derrière le rideau. Le bloc flouté « + 2
compétences détectées · 4 déjà solides » dit le reste. **Rien à corriger de ce côté**,
sinon éventuellement la lisibilité du libellé.

---

## 5. Ce qui est un choix assumé, et ce qui est un trou

| | Nature | Verdict |
|---|---|---|
| Allowlist de 8 compétences par production | Choix (coût d'un diagnostic à 2 productions) | À garder |
| `SOLID` / `NOT_OBSERVED` ne deviennent jamais des fragilités | Invariant du dépôt (*null = inconnu, jamais mauvais*) | 🛑 À garder absolument |
| Palier de cycle **global** au lieu de par domaine | Choix (brief §37/§93) | **À rediscuter** |
| `PAS_ENCORE_PRIORITAIRE` ⇒ zéro action | Conséquence non voulue du choix précédent | **Trou** |
| Plafond de 5 utilisé comme **budget partagé** entre 4 domaines | Confusion plafond d'affichage / budget | **Trou principal** |
| Carte d'épreuve alimentée par les cartes du Plan | Économie de calcul | **Trou** : elle a besoin de sa propre vue |

---

## 6. Pistes de correction

Classées par rapport valeur / risque. Aucune n'est appliquée.

### Piste A — Découpler la carte d'épreuve du budget du Plan *(recommandée)*

La carte « Mes 4 épreuves » répond à « **qu'est-ce qui me reste à faire sur cette
épreuve ?** ». Elle ne devrait pas hériter d'un plafond conçu pour « Mes priorités ».

- Faire calculer par `PlanAcquisitionSelector` (ou un frère) **la liste complète par
  domaine**, sans limite, et la joindre à `PlanDomainDto` — soit via `nature` posée sur
  toutes les compétences acquérables du domaine, soit via un champ dédié
  (`acquisitionSkillCount` + `nature` complète), pour ne pas casser le sens actuel de
  `nature` = « le Plan demande ça **maintenant** ».
- « Mes priorités » garde son plafond de 5 : rien ne change côté séance.
- Effet immédiat sur ce compte : l'EO afficherait **4 compétences B1 à acquérir**, l'EE
  en afficherait **6** au lieu de 2.
- Coût : aucune requête de plus (le référentiel est déjà chargé, cf. §Coût de
  `PlanAcquisitionSelector`).
- Risque : la carte d'épreuve devient plus longue — mais elle est déjà pliable
  (« Voir le détail de l'épreuve ») et le rideau freemium borne l'affichage.

### Piste B — Palier de cycle **par domaine** au lieu d'un palier global

`palierVise(depart, objectif)` reçoit le niveau **global** ; lui passer le niveau **du
domaine** pour les acquisitions d'expression rendrait à l'EO ses 6 compétences B2.

- Effet sur ce compte : l'EO travaillerait du **B2** (son vrai cran suivant), l'EE du
  **B1**.
- ⚠️ Contredit frontalement le brief §37/§93 (« un palier à la fois, celui qui bloque »).
  À arbitrer : c'est un changement de doctrine produit, pas un correctif.
- Compromis possible : garder le palier global pour l'**ordre** et le **chemin**
  affiché, mais autoriser l'acquisition au palier propre du domaine quand celui-ci est
  **déjà au-dessus** du palier global — c'est exactement le cas `PAS_ENCORE_PRIORITAIRE`.

### Piste C — Une garantie de plancher : « jamais une épreuve mesurée sans action »

Règle explicite : *toute épreuve évaluée dont le niveau est sous l'objectif porte au
moins une action*. Implémentée comme un **quota minimal par domaine** dans le sélecteur
(ex. 1 place réservée par domaine sous objectif, avant la répartition du reste).

- Effet : l'EO aurait toujours au moins 1 ligne.
- 🛑 Danger à surveiller : cette règle ne doit **jamais** fabriquer une action à partir
  d'une compétence solide ou non observée. Elle ne peut piocher que dans les
  acquisitions **réelles**. Quand un domaine n'a plus rien à acquérir ni à réparer, il
  n'a légitimement rien — et la bonne réponse est alors un examen blanc / une
  vérification, pas une ligne inventée.
- C'est la piste qui répond le plus directement à la demande (« toujours quelque chose
  qui fera progresser »), mais elle est cosmétique si A n'est pas fait : elle donnerait
  1 ligne à l'EO là où A en donne 4.

### Piste D — Élargir le budget de « Mes priorités »

Passer `MAX_PRIORITIES` de 5 à N. Simple, mais c'est un pansement : le budget resterait
partagé, l'ordre par urgence continuerait de servir l'EE d'abord, et l'EO n'aurait des
lignes que par débordement. **Non recommandée seule.**

### Piste E — Le maillon notation (indépendant)

Deux compétences **B2** notées `SOLID`/`HIGH` chez un candidat estimé B1 dans le même
appel. Vérifier si la rubrique du diagnostic autorise un garde-fou de cohérence
« une compétence d'un palier au-dessus du niveau estimé ne peut pas sortir `SOLID` en
confiance `HIGH` » — un contrôle **déterministe** côté serveur, dans l'esprit du
`CompetenceLevelEvidenceGuard` existant, jamais une consigne de prompt de plus.
À mesurer avant de trancher : combien de diagnostics réels sont concernés.

---

## 7. Ce qu'il faut arbitrer avant de coder

1. **La carte d'épreuve doit-elle montrer tout ce qui reste à acquérir sur cette
   épreuve, ou seulement ce que le Plan traite maintenant ?** (Piste A ⇔ statu quo.)
   C'est la question centrale : elle décide du sens de `nature` dans `PlanDomainSkillDto`.
2. **Un domaine déjà au-dessus du palier global peut-il travailler son propre palier
   suivant ?** (Piste B / compromis.) C'est une modification du brief §93.
3. **Veut-on une garantie « au moins une action par épreuve sous objectif » ?**
   (Piste C.) Et acceptez-vous qu'elle rende zéro quand il n'y a rien de vrai à servir ?
4. **Lance-t-on une mesure sur la générosité de notation du diagnostic ?** (Piste E —
   coût LLM si on rejoue des productions, nul si on se contente d'une requête SQL sur
   les analyses déjà en base.)

---

## 8. Comment reproduire ce constat

```sql
-- le compte et sa session
select id, email, created_at from users order by created_at desc limit 1;
select id, status, jsonb_pretty(summary_json) from diagnostic_sessions where user_id = '<user>';

-- ce que le correcteur a rendu, compétence par compétence
select a.submission_id, a.level_estimate, s->>'skill_code', s->>'status', s->>'confidence'
from diagnostic_production_analyses a, jsonb_array_elements(a.analysis_json->'skills') s
where a.submission_id in ('<written>', '<oral>') order by 1, 3;

-- l'état réel du référentiel pour ce candidat
select s.section, s.target_level,
       count(*) filter (where o.id is null) as jamais_travaillee,
       count(*) filter (where o.status = 'SOLID') as solide,
       count(*) filter (where o.status = 'TO_REINFORCE') as a_renforcer
from skills s
left join learning_plan_observations o on o.skill_id = s.id and o.user_id = '<user>'
where s.is_active and s.section in ('EE','EO') group by 1, 2 order by 1, 2;
```

## 9. Fichiers concernés

| Fichier | Rôle dans le constat |
|---|---|
| `service/LearningPlanService.java:214` | le budget `5 - fragilités` passé au sélecteur |
| `service/LearningPlanPriorityResolver.java:54` | `MAX_PRIORITIES = 5` |
| `service/PlanAcquisitionSelector.java:126` | palier du cycle, tri par urgence, troncature |
| `service/PlanCycleResolver.java:210` | `palierVise` — un cran au-dessus du niveau **global** |
| `service/PlanCycleResolver.java:361` | `priorite` — l'EO tombe en `PAS_ENCORE_PRIORITAIRE` |
| `service/PlanDomainSkillResolver.java:118` | `nature` = les cartes du Plan, rien d'autre |
| `screens/diagnostic/widgets/diagnostic_result.dart:332,460` | le groupage de la carte (fidèle au serveur) |
| `app/_components/diagnostic/*` (web) | même lecture, à vérifier dans la même passe |
