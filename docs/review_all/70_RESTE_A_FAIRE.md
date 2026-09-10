# Ce qui n'est pas fait — état au 2026-09-10

> **À quoi sert ce document.** Une liste unique de ce qui reste, pour décider
> quoi lancer ensuite. Il ne remplace ni `50_` (qui fait autorité sur le
> périmètre) ni `60_` (le journal des décisions prises sans arbitrage) : il les
> **agrège**, et il ajoute ce que les specs ne pouvaient pas savoir — l'état
> réel du code et des contenus.
>
> **Les chiffres viennent de la base locale**, pas d'une estimation : ils sont
> datés du 2026-09-10 et la requête qui les produit est donnée à chaque fois.
> 🛑 Aucun n'a été obtenu en appelant un modèle payant.
>
> **Trois catégories, et elles ne se traitent pas pareil** :
> **É** éditorial (du travail humain, parfois de l'argent) · **C** code ·
> **D** décision qui n'appartient qu'au propriétaire.

---

# 0. Le résumé en une page

| # | Ce qui reste | Cat. | Bloque | Volume |
|---|---|---|---|---|
| 1 | **Tagging des 1 016 questions civiques** | É | le plan civique **par notion**, la révision par notion | ~1 016 validations |
| 2 | **Sujets EO tâche 1** | É | la tâche 1 de l'expression orale, aujourd'hui à 3 sujets contre ~20 ailleurs | ~15 sujets |
| 3 | **Mises en situation civiques** | É | la répétition d'un examen blanc à l'autre | ~120 questions |
| 4 | **L'effet Leitner n'est pas VISIBLE** (C09) | C | la valeur perçue du Premium civique | 1 écran + 1 champ servi |
| 5 | **Export des données personnelles** (G04, D5) | C+D | une réponse RGPD | 1 endpoint + 1 écran |
| 6 | **Bloc « Votre semaine »** du plan civique | C+D | rien ; c'est un manque de la maquette | à définir |
| 7 | **Domaines de mise en situation** comme cibles du plan | C | la finesse du plan civique sur les situations | référentiel + moteur |
| 8 | **Écran de mention civique dédié** (C01) | C | rien ; `TargetProcedure` fait le travail | 1 écran |
| 9 | **Accueil agrégé** aligné sur `30_` §9 (G01) | C | rien ; `/dashboard` existe et diverge | à comparer |
| 10 | **Aucun écran n'a été ouvert** de tout le chantier | D | la confiance dans ce qui est livré | une passe de relecture |
| 11 | **Courbe de progression** (T28 bloc 1) | C | rien ; attend des candidats à 3 réévaluations | différé |
| 12 | **Dette : libellés d'épreuve en dur** (mobile) | C | rien | 4 écrans à migrer |

**Ce qui bloque vraiment n'est pas du code.** Les trois premières lignes sont
éditoriales, et elles portent tout le reste : `50_` §9 le disait déjà, et rien
depuis ne l'a démenti.

---

# 1. Chantiers éditoriaux — le chemin critique

## 1.1. Le tagging des questions civiques (É, ~1 016 décisions)

**Mesuré le 2026-09-10** :

```sql
SELECT count(*) FILTER (WHERE q.is_active)                             AS actives,
       count(*) FILTER (WHERE q.is_active AND q.civic_notion_id IS NOT NULL) AS taguees
FROM questions q JOIN themes t ON t.id = q.theme_id
WHERE t.module = 'CIVIQUE';
-- actives = 1016 · taguees = 0
SELECT count(*) FROM question_notion_suggestions;   -- 0
SELECT count(*) FROM civic_notions WHERE is_active; -- 40
```

**Ce qui est prêt** : les 40 notions (V051), la colonne `questions.civic_notion_id`,
la table de suggestions, l'écran d'administration et sa file de tagging, et —
depuis L10 — un moteur qui bascule **thème par thème** dès que 80 % des questions
d'un thème sont taguées.

**Ce qui manque** : les décisions humaines. Personne ne peut les écrire à la
place d'un relecteur.

🛑 **Le pré-tagging assisté coûte de l'argent.** `50_` §6.1.2 prévoit
`PROMPT_TAG_NOTION_v1` par lots de 50 questions — c'est un appel à un modèle
payant, donc **une décision du propriétaire**, pas un effet de bord
d'implémentation. Le job **n'existe pas** dans le dépôt et la table de
suggestions est volontairement vide.

**Ce que ça bloque, exactement** : rien ne casse. Le plan civique fonctionne
**au grain thème** (`20_` §3.3 phase 1), et il l'écrit à l'écran. Ce qui manque,
c'est la précision — « Le Parlement » au lieu de « Système institutionnel ».

**La porte de revue reste ouverte** (`50_` §6.1.3, décision **D2**) : le
référentiel des 40 notions est un référentiel **de travail**, à arrêter *après*
le tagging, pas avant. `civic_notions.merged_into_id` existe pour ça.

## 1.2. Les sujets d'expression orale, tâche 1 (É, ~15 sujets)

**Mesuré** :

```sql
SELECT epreuve, tache_numero, count(*) FROM production_tasks
WHERE is_active GROUP BY 1, 2 ORDER BY 1, 2;
-- TCF_EO tâche 1 =  3   ← le trou
-- TCF_EO tâche 2 = 20 · tâche 3 = 21
-- TCF_EE tâches  = 20 · 20 · 22
```

**Conséquence concrète** : un candidat qui refait la tâche 1 de l'oral retombe
sur le même sujet au troisième essai. Les cinq autres tâches n'ont pas ce
problème.

## 1.3. Les mises en situation civiques (É, ~120 questions)

**Mesuré** :

```sql
SELECT difficulty, count(*) FROM questions
WHERE module='CIVIQUE' AND is_active AND question_type='MISE_SITUATION'
GROUP BY 1;
-- CSP = 56 · CR = 75 · NAT = 45   (total 176)
```

**Ce que ça permet déjà** : le diagnostic civique en tire 12 par passage, sur la
mention du candidat — même le stock CSP (le plus mince) le supporte largement.

**Ce que ça ne permet pas** : l'examen blanc civique en tire 12 aussi, et il se
rejoue jusqu'à 10 fois. Sur la mention **NAT** (45 questions), la répétition
devient visible dès le quatrième examen. C'est la décision **D3** de `50_` §11 :
produire, ou assumer la répétition.

---

# 2. Décisions qui n'appartiennent qu'au propriétaire

| # | Décision | Où c'est écrit | État |
|---|---|---|---|
| **D2** | Arrêter le référentiel de notions **après** le tagging | `50_` §6.1.3, §11 | **en attente** — rien n'est figé, `merged_into_id` est là |
| **D3** | Produire ~120 mises en situation, ou assumer la répétition | `50_` §11 | **en attente** |
| **D5** | Export des données personnelles : livré ou à faire ? | `50_` §11 | **tranché par le code : à faire** (cf. §3.2) |
| **—** | Autoriser (ou non) le pré-tagging assisté par LLM | `50_` §6.1.2 | **jamais posée** — le job n'existe pas |
| **—** | Le bloc « Votre semaine » du plan civique | `20_` §6 bloc 3 | **jamais posée** (cf. §3.3) |

**D1** (le diagnostic rapide perd le signal oral) et **D4** (les tests front)
ont été tranchées en cours de route et sont appliquées.

---

# 3. Code non fait

## 3.1. 🛑 L'effet Leitner n'est pas visible (C09) — le plus gros manque

`20_` §8.2 est explicite : « **L'effet Leitner doit être visible : c'est ce qui
rend la valeur Premium tangible.** Ne jamais afficher le numéro de boîte,
seulement l'état et la prochaine échéance. »

La maquette de fin de série ciblée demande :

```
« Série terminée — 8 / 10 »
« Le Parlement passe de À travailler à En progression. »
« Prochaine révision proposée dans 3 jours. »
```

**Ce qui existe** : le moteur (L10) calcule l'état et l'échéance, et le Plan les
affiche. La série ciblée démarre bien.

**Ce qui manque, vérifié** : le runner ne reçoit **aucun** marqueur de cible —
ni bandeau « Notion travaillée : … · Question 4 / 10 » pendant la série, ni
transition d'état à la fin.

```
grep -n "notion" web_sejoufr/app/sessions/[attemptId]/page.tsx   # aucun résultat
```

**Pourquoi c'est le plus gros manque de la liste** : c'est le seul endroit où le
candidat **voit** ce qu'il paie. Un plan qui se réordonne en silence ne se
distingue pas d'une liste de thèmes.

**Ce que ça demande** : un paramètre de retour sur le runner (le patron existe
déjà — `civicDiagnosticId`, `tcfDiagnosticId`), et un DTO de fin de série
portant l'état **avant** et **après**. 🛑 La transition doit être **servie**, pas
recalculée par un front, et la boîte ne s'affiche jamais.

## 3.2. Export des données personnelles (G04)

`40_` §6.1 le notait « non vérifié ». **Vérifié maintenant** :
`AccountController` ne porte qu'un `@DeleteMapping`. Il n'existe **aucun**
endpoint d'export, et aucun écran.

La suppression de compte, elle, est livrée (`AccountDeletionService`,
anonymisation, message d'action manuelle pour un abonnement de store).

⚠️ **À traiter avant toute communication RGPD** — c'est une obligation, pas une
fonctionnalité.

## 3.3. Le bloc « Votre semaine » du plan civique

`20_` §6 bloc 3 : « 2 séries sur 4 terminées », avec des séries cochées.

**Pas fait, et pas par oubli** : rien ne définit ce qu'est une « semaine »
civique — combien de séries, réinitialisées quand, et ce qui arrive si le
candidat en fait six. Le plan sert « À faire maintenant » et les priorités, qui
suffisent à agir. **Une décision produit manque**, pas du code.

## 3.4. Les domaines de mise en situation comme cibles du plan

`20_` §2.6 et §5.1 prévoient des `civic_situation_domain` avec leurs **propres**
boîtes Leitner : « sur une mise en situation, la boîte concernée est celle du
`situation_domain`, pas d'une notion ».

**Pas fait** : le référentiel n'existe pas en base. Aujourd'hui une mise en
situation alimente la boîte de sa **notion** (ou de son thème). Le diagnostic,
lui, les compte déjà séparément — c'est le plan qui ne les distingue pas.

## 3.5. Écran de mention civique dédié (C01)

`30_` §8.1 décrit un écran « Quelle démarche préparez-vous ? » avec trois
cartes et une ligne d'explication chacune, plus un écran de confirmation au
changement (« les notions déjà maîtrisées sont conservées »).

**Ce qui existe** : `TargetProcedure` au niveau du compte, l'onboarding
`/target-path` (mobile) et `/parcours` (web), et — depuis V053 — un choix de
démarche à l'entrée du diagnostic civique invité.

**Ce qui manque** : la ligne d'explication par carte et l'écran de confirmation
au changement. Aucun blocage : le parcours fonctionne.

## 3.6. Accueil agrégé (G01)

`30_` §9 décrit un écran très cadré : au maximum **2 cartes** d'action (une par
module), « Vos objectifs » sur une ligne par module, un encart contextuel **et un
seul**.

**Ce qui existe** : `/dashboard` (web) et `screens/home/` (mobile), plus riches
et structurés autrement, plus la `PreparationCard` livrée en L9 qui agrège les
deux parcours.

**Ce qui manque** : la comparaison ligne à ligne avec la maquette. C'est un
travail à part entière, et rien n'est cassé en attendant.

## 3.7. Plan premium / plan gratuit contre les maquettes 04 et 05

Noté dans `60_` et jamais fait : les deux écrans de Plan existent et sont **plus
riches** que les maquettes (séance du jour, jalons, cycle de palier, changements
récents). Ils n'ont pas été comparés ligne à ligne.

## 3.8. La courbe de progression (T28 bloc 1)

Le DTO sert l'historique des estimations, et l'écran le **liste** dès qu'il y a
deux points. Une vraie courbe (tracé, interpolation) attend des candidats à trois
réévaluations : la dessiner sur deux points serait de la décoration.

---

# 4. Écarts assumés avec les specs — à confirmer ou à corriger

Tous sont livrés, documentés dans `60_`, et **réversibles**. Ils sont ici parce
qu'ils n'ont pas été arbitrés.

| Écart | Spec | Ce qui est fait | Où c'est justifié |
|---|---|---|---|
| Diagnostic civique à **40** questions | `20_` §4.2 en prévoyait 24 | 28 + 12 = 40, le score **est** le résultat | arbitré par le propriétaire |
| **Aucune table** de plan civique ni de progression Leitner | `20_` §10 en prévoyait 3 + un job quotidien | tout est relu à chaque appel — c'est ce qui rend le tagging **rétroactif** | `60_` D-L10-1 |
| Un **thème** n'est jamais « maîtrisé » | `20_` §5.2 ne distingue pas les grains | garde-fou qui **abaisse** au grain thème | `60_` D-L10-2 |
| Le bloc « objectif » du plan sert le **diagnostic** | `20_` §6 bloc 1 : « résultat estimé aujourd'hui » | pas d'estimation fabriquée à partir de séries | `60_` D-L10-3 |
| Aucun `reason_text` servi | `20_` §10 | les phrases vivent dans les deux fronts | `60_` D-L10-4 |
| **Pas de troisième page** « progression » | `30_` §7 décrit un écran | greffé sur l'écran existant | `60_` D-T28-1 |
| **Pas de toggle** TCF \| Civique sur Progrès | `30_` §7 en met un | l'écran empile déjà les deux parcours | `60_` D-T28-2 |
| Fenêtre d'activité à **28** jours | `30_` §7 écrit 30 | 30 ne fait pas un nombre entier de semaines | `60_` D-T28-3 |
| Le tunnel invité civique **persiste** une session | le TCF garde tout sur l'appareil | corriger du QCM côté client exposerait les bonnes réponses | `60_` D-G-1 |
| `/api/…` sans `/v1` | `20_` §11 écrit `/api/v1/…` | interdit par `50_` §12 | `50_` §12 |

**Une réserve technique** reste ouverte depuis L4 : la sévérité EE/EO est dérivée
des bandes du correcteur, `50_` §5.3 interdisant une septième famille de prompts.

---

# 5. Dette repérée en passant

- **Libellés d'épreuve en dur (mobile)** : quatre écrans d'examen complet
  écrivent « Compréhension orale », etc. `EpreuveType.displayLabel` est
  maintenant l'autorité (T28) ; les quatre copies restent à migrer.
- **Sessions civiques invitées jamais adoptées** : rien ne les purge. Elles sont
  inertes — invisibles de tout écran connecté, exclues des grilles par
  `attempts.civic_diagnostic_id` — mais elles s'accumulent. À traiter le jour où
  le volume le justifie.
- **10 tests Dart rouges**, antérieurs à tout ce chantier (`competences_prototype`,
  `evaluation_report`, `plan_screen`, …). Ils n'ont été ni réparés ni supprimés.
- **i18n** : `30_` §14 l'exige dans la *definition of done* (« aucun texte en
  dur : tout passe par `i18n/fr.json` »). Il n'existe **aucun** fichier i18n dans
  les deux fronts. `50_` §8 l'avait explicitement **retiré du périmètre** de L1 —
  c'est donc un écart connu, pas un oubli, mais la DoD n'a pas été mise à jour.

---

# 6. 🛑 Ce qui n'a jamais été vérifié

**Aucun écran de tout ce chantier n'a été ouvert.** `tsc`, `npm run build`,
`flutter analyze` et les suites de tests passent — mais aucun de ces outils ne
vérifie qu'une règle CSS **s'applique**, ni qu'un écran est lisible.

Ce n'est pas une précaution de principe : ce chantier en a déjà payé le prix
**deux fois**.

1. Sept écrans rendus **invisiblement nus** — `<style jsx>` dans un composant qui
   ne rend que la balise ne scope sur rien, donc aucune règle ne s'appliquait.
   `tsc`, `build` et les tests étaient verts. C'est le propriétaire qui l'a vu :
   « je ne vois toujours pas de toggle dans /plan ».
2. Trois défauts trouvés par **un seul** passage réel du diagnostic civique :
   pas de marqueur de retour, session jamais close, mauvaise formulation du Plan.

**Les écrans à ouvrir en priorité**, dans cet ordre : `/plan` (onglet civique,
compte gratuit **et** abonné), `/diagnostic-civique` en visiteur puis
l'inscription, `/statistiques` (le bloc « Ce qui a bougé »), `/reussir` et
`/diagnostic`.

---

# 7. Ce qui est fait — pour ne pas le refaire

Livré et vérifié par `./mvnw verify` vert, `tsc` + `build` + 270 tests web, et
`flutter analyze` propre.

| Lot | État |
|---|---|
| L1 socle · L5 paywall · L12 coûts IA | ✅ |
| L4 diagnostic TCF 4 épreuves | ✅ (1 réserve, §4) |
| L7 boucle de réévaluation | ✅ |
| L3 diagnostic écrit rapide | ✅ |
| L6 rapport micro | ✅ code — reste le contenu EO1 (§1.2) |
| L8 référentiel de 40 notions + admin de tagging | ✅ **code** — reste le tagging (§1.1) |
| L9 diagnostic civique (40 questions) | ✅ |
| **V053** les deux diagnostics avant le compte | ✅ |
| **L10** plan civique + Leitner + série ciblée | ✅ — au grain thème tant que le tagging n'a pas avancé |
| **T28** Progrès (« ce qui a bougé ») | ✅ |
| L11 examens blancs branchés | ✅ **de fait** : depuis L10, les réponses d'examen blanc civique alimentent les mêmes boîtes que les séries (`20_` §8.2) |

⚠️ **« Livré » veut dire « écrit, testé et cohérent »**, pas « vu à l'écran ».
Cf. §6.
