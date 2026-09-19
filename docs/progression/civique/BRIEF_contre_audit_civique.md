# BRIEF — CONTRE-AUDIT CIVIQUE — le référentiel officiel invalide trois hypothèses

Fait suite à `AUDIT_cycle_plan_civique.md` (2026-09-19), qui reste **valide dans ses mesures** et
**caduc dans deux de ses conclusions**. Source de vérité : **arrêté du 10 octobre 2025** relatif au
programme, aux épreuves et aux modalités d'organisation de l'examen civique (JORF n° 0240 du
12 octobre 2025, NOR INTV2527907A), articles 1 à 3 et annexe I.

> ⛔ **HARD STOP.** Lecture et requêtes de lecture seulement. Aucun code, aucune migration, aucun test.
> Livrable unique : `docs/audits/AUDIT_cycle_plan_civique_v2.md`. Attendre le go explicite ensuite.

---

## 1. Ce que dit le texte officiel — à tenir pour acquis, à ne pas redébattre

1. **Article 1** — l'examen comporte alternativement trois mentions : « carte de séjour pluriannuelle »,
   « carte de résident », « naturalisation ». Ce sont des **mentions d'attestation**.
2. **Article 3** — le programme est défini par **un** référentiel de connaissances (annexe I, singulier).
   **Pour toutes les mentions**, l'épreuve est un QCM de 40 questions incluant connaissances et mises en
   situation. « Chaque candidat devra répondre à un **nombre équivalent de questions par thématique et
   notion**. »
3. **Il n'existe donc ni trois programmes, ni trois pools de questions, ni trois niveaux de difficulté.**
   Rien dans l'arrêté ne fonde une différenciation du contenu par mention.
4. **La répartition est fixée, notion par notion** :

| Thématique | Total | Répartition officielle |
|---|---|---|
| Principes et valeurs de la République | 11 | Devise et symboles 3 · Laïcité 2 · **Mises en situation 6** |
| Système institutionnel et politique | 6 | Démocratie et droit de vote 3 · Organisation de la République 2 · Institutions européennes 1 |
| Droits et devoirs | 11 | Droits fondamentaux 2 · Obligations et devoirs 3 · **Mises en situation 6** |
| Histoire, géographie et culture | 8 | Périodes et personnages 3 · Territoires et géographie 3 · Patrimoine 2 |
| Vivre dans la société française | 4 | S'installer 1 · Accès aux soins 1 · Travailler 1 · Autorité parentale et système éducatif 1 |

5. **L'annexe I définit 14 notions**, pas 40 ni 46 : 2 + 3 + 2 + 3 + 4.
6. **Les 12 mises en situation ne sont pas réparties sur les 5 thèmes** : 6 en Principes, 6 en Droits et
   devoirs, **zéro ailleurs**.
7. Une seule bonne réponse par question ; bonne réponse 1 point, mauvaise ou absence 0 ; durée 45 min
   maximum ; seuil 80 %.
8. **Les questions de connaissances sont rendues publiques** sur le site du ministère chargé des
   naturalisations (art. 3, dernier alinéa).

---

## 2. Ce que ça invalide dans l'audit v1

| Conclusion v1 | Statut |
|---|---|
| **E-1** « R2 inapplicable : 1 couple (notion × mention) sur 138 » | **Caduque dans sa cause.** Le découpage par mention n'a pas de fondement réglementaire, et le grain « 46 notions » est une taxonomie interne. Le déficit était un artefact de double découpage. |
| **Q-F16** « Principes × NAT = 20 questions, pool épuisé » | **Sans objet.** Il n'y a pas de pool par mention. |
| **Q-F15** « produire ~5 mises en situation Principes × CSP » | **Sans objet**, même raison. |
| **§2.6 option α** (grain thème, faute de contenu) | **À réexaminer.** Si le grain devient les 14 notions officielles sans filtre de mention, **β/γ n'ont plus lieu d'être et α n'est plus une contrainte subie**. |
| Les mesures du §1 (tagging 98 %, cohérence thème↔notion 0 écart, 176 mises en situation non taguées, formats 20/16 et 40/32) | **Toutes valides.** Rien à refaire. |

---

## 3. Vérifications demandées — par ordre de gravité

### 3.1 🛑 L'examen blanc global respecte-t-il la répartition officielle ?

C'est la promesse centrale du produit, avant le cycle. Pour **chacun des trois chemins de composition**
(`exam_templates` + `exam_template_rules`, `composeCiviqueFullExam`, et tout autre) :

- Le tirage impose-t-il **11 / 6 / 11 / 8 / 4** par thématique ? Donner la règle réelle, pas l'intention.
- Impose-t-il la répartition **par notion** à l'intérieur de chaque thématique (3/2/6, 3/2/1, 2/3/6,
  3/3/2, 1/1/1/1) ?
- Impose-t-il **12 mises en situation**, et **uniquement** en Principes et Droits et devoirs ?
- Mesurer sur les **33 examens à 40 questions déjà passés** en base : répartition réelle par thématique,
  par type, et écart à la répartition officielle. Un tableau, pas une appréciation.

**Conclusion attendue** : l'examen blanc global simule-t-il l'examen réel, oui ou non, et sur quels axes
il s'en écarte.

### 3.2 Correspondance 46 notions internes → 14 notions officielles

- Produire la table de correspondance complète : pour chacune des 46 `civic_notions` actives, la notion
  officielle de rattachement, ou **« sans rattachement »**.
- Compter les questions actives **par notion officielle**, toutes mentions confondues. Chaque notion
  officielle atteint-elle 20 questions (le seuil de R2 : 2 séries de 10) ? Lister les exceptions.
- Signaler les notions internes qui ne se rattachent à **aucune** notion officielle, et celles qui
  chevauchent deux notions officielles.
- Dire si `civic_notions` doit gagner une colonne de rattachement, ou si une table de référence des
  14 notions officielles doit être créée à côté.

### 3.3 Le champ `difficulty` une fois le filtre de mention retiré

- Recenser **tous** les points de code qui filtrent sur `q.difficulty = :mention` (l'audit v1 en cite
  `CivicPlanRepository` ; en donner la liste exhaustive, civique **et** TCF — la colonne est partagée).
- Que devient la colonne : supprimée, conservée comme métadonnée éditoriale sans effet de filtre, ou
  réinterprétée en difficulté réelle (facile / moyen / difficile) sur le modèle de
  `difficulty_band` côté TCF ? Options, coût, recommandation.
- Mesurer l'effet du retrait du filtre : dotation par notion officielle **avant** et **après**, et
  impact sur `CivicDotation` (les états `NON_APPLICABLE` disparaissent-ils tous ?).
- ⚠️ Vérifier qu'aucune question active n'est **réellement** spécifique à une démarche (une question qui
  n'aurait de sens que pour un candidat à la naturalisation). Si de telles questions existent, dire
  combien et sur quelles notions — elles restent légitimes dans le référentiel (« les démarches d'accès
  à la nationalité française » figure au programme **pour tous**), mais il faut le constater, pas le
  supposer.

### 3.4 Les mises en situation hors Principes et Droits et devoirs

L'audit v1 mesure 30 mises en situation en Histoire, 31 en Institutions, 47 en Société. Officiellement,
il n'y en a aucune dans ces trois thématiques.

- Confirmer les comptes, et dire ce que deviennent ces ~108 questions : contenu d'entraînement valable
  mais **exclu des examens blancs**, ou à re-typer, ou à reclasser.
- Vérifier que le tirage des examens ne peut plus en placer hors des deux thématiques autorisées.

### 3.5 Les questions officielles publiques

- Vérifier si le site du ministère publie effectivement la banque de questions de connaissances, et sous
  quelle forme (page, PDF, nombre de questions, date).
- **Ne rien importer.** Livrable : l'URL, le format, le volume, et une évaluation de ce que ça
  représenterait comme chantier de contenu. C'est une piste, pas une tâche.

### 3.6 Impact sur le cycle

Une fois 3.2 et 3.3 mesurés, reprendre **Q-F1** :

- Le grain **14 notions officielles sans filtre de mention** rend-il R2 applicable tel quel
  (2 séries réussies de 10 questions) ? Chiffres à l'appui.
- Si oui, l'option **α** du v1 (bloc clos sur son seul examen) reste-t-elle préférable, ou le bloc
  retrouve-t-il ses étapes de notion comme le TCF ? Recommandation argumentée, **non appliquée**.
- Ce que devient le seuil `questionsMinParNotion: 5` et `questionsParSerie: 10` dans ce cadre.

---

## 4. Livrable

`docs/audits/AUDIT_cycle_plan_civique_v2.md` :

1. **Synthèse** — 10 lignes : l'examen blanc est-il conforme, le grain notion est-il désormais tenable.
2. **Conformité du tirage** (3.1), avec les tableaux de mesure.
3. **Table de correspondance 46 → 14** (3.2), complète, en annexe si volumineuse.
4. **Sort de `difficulty`** (3.3) : options, coût, recommandation.
5. **Mises en situation hors périmètre** (3.4).
6. **Questions publiques du ministère** (3.5) : constat seul.
7. **Q-F1 révisée** (3.6).
8. **Ce que l'audit v1 conserve** : la liste explicite de ses écarts et questions qui restent valides
   (E-2 à E-20, Q-F2 à Q-F20), et de ceux qui tombent.

Rappels : la page **historique des cycles** reste bloquée, template non fourni. Le **civique-découverte**
reste gratuit. Aucune question n'est à produire tant que 3.2 n'a pas conclu.

> ⛔ **RAPPEL STOP.** Termine après le rapport. Si 3.1 révèle une non-conformité de l'examen blanc,
> **ne la corrige pas** : signale-la, chiffre-la, et arrête-toi. C'est un chantier à part, prioritaire,
> qui sera arbitré séparément.
