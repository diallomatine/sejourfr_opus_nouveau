# Audit — les caractéristiques officielles du TCF IRN dans le code et les contenus

**Rapport d'audit. Rien n'est modifié.** Chaque écart est donné avec son fichier
et sa ligne, pour que tu décides quoi corriger.

Référence retenue (fournie par le propriétaire) : **EE1 30–60 mots · EE2 40–90 ·
EE3 40–90**.

---

## 0. Ce qui est CONFORME — à ne pas toucher

| Surface | État |
|---|---|
| `production_tasks` (base) | ✅ CHECK dur posé par `V724__tcf_irn_ee_t2_t3_mots_min_40.sql` : `tache 1 → 30/60`, `taches 2 et 3 → 40/90`. Aucune ligne hors bornes n'est insérable. |
| Grille de notation active | ✅ `EVAL_RUBRICS_VERSION` vaut `v15` par défaut (`application.yaml:543`). `production-rubrics-v15.json` ne contient **aucune** borne de mots EE — elle lit celles de la tâche. |
| `docs/notation-ia-eo-ee.md` | ✅ Documente explicitement le piège IRN / Canada (§ « TCF IRN ≠ TCF Canada », l. 417-422) et interdit de « corriger » nos bornes d'après une recherche web. |

---

## 1. 🔴 Le blog publie le format du TCF **Canada**, pas celui de l'IRN

Six articles publics annoncent **60–120 mots** pour la tâche 2 et **120–180 mots
avec comparaison de deux documents** pour la tâche 3. Ce sont les
caractéristiques du **TCF Canada**. C'est exactement le piège que
`docs/notation-ia-eo-ee.md` nomme — et il est déjà en ligne.

| Fichier (`web_sejoufr/content/articles/`) | Ligne | Contenu |
|---|---|---|
| `tcf-irn-expression-ecrite-tache-2.mdx` | 5, 20, 63, 85 | « entre 60 et 120 mots », consigne type « (60-120 mots) » |
| `tcf-irn-expression-ecrite-tache-3.mdx` | 5, 17, 20, 69, 71 | « comparer deux documents courts » + « 120 à 180 mots » — **l'article entier repose sur un format qui n'est pas le nôtre** |
| `tcf-irn-expression-ecrite-tache-1.mdx` | 81-82 | tableau récapitulatif : T2 60–120, T3 120–180 (la ligne T1 30–60 est juste) |
| `tcf-irn-10-erreurs-frequentes.mdx` | 62 | « 30-60 pour la tâche 1, 60-120 pour la tâche 2, 120-180 pour la tâche 3 » |
| `tcf-irn-gerer-son-temps-epreuves.mdx` | 71-72 | tableau de gestion du temps, mêmes bornes |
| `tcf-irn-atteindre-b2-naturalisation-plan-12-semaines.mdx` | 45 | « deux points de vue à comparer, une position à défendre en 120 à 180 mots » |

**Conséquence concrète** : un candidat qui suit le blog s'entraîne à 150 mots,
puis l'app lui sert une tâche de 40–90 et l'IA le corrige sur 40–90.

⚠️ `tcf-irn-expression-ecrite-tache-3.mdx` n'est pas un chiffre à remplacer :
la **définition de la tâche** y est fausse (comparer deux documents fournis).
Il est à réécrire, pas à corriger.

---

## 2. 🔴 Un retour arrière sur la grille réintroduit les bornes 60-90

`production-rubrics-v9.json` contient en dur `30-60 mots` **et `60-90 mots`**.
La règle du dépôt (« on versionne, on ne réécrit jamais une grille livrée ») est
juste : cette grille est la trace de ce avec quoi les copies ont été corrigées.

Mais le retour arrière est un simple `EVAL_RUBRICS_VERSION=v9`, et il
**réintroduit silencieusement une borne minimale fausse** (60 au lieu de 40).
C'est documenté dans `docs/notation-ia-eo-ee.md` — mais rien ne l'empêche.

**À arbitrer** : soit on l'assume (rollback = urgence, on sait ce qu'on fait),
soit on pose un garde-fou au démarrage qui refuse une version dont les bornes
contredisent le CHECK de `production_tasks`.

---

## 3. 🟠 « Référentiel OFFICIEL » affirmé sur la table EE1=A2 / EE2=B1 / EE3=B2

`backend_sejourfr/src/main/java/com/sejourfr/app/enums/SkillTaskCode.java:6-14` :

> « Les 6 tâches sont un referentiel **OFFICIEL** fige par le TCF »

La phrase est vraie pour **les 6 tâches**. Elle est fausse pour le `targetLevel`
qui est déclaré sur la même ligne d'enum :

```java
EE1(SkillSection.EE, 1, "Écrire un message court", "A2"),
EE2(SkillSection.EE, 2, "Raconter une expérience", "B1"),
EE3(SkillSection.EE, 3, "Donner son opinion",      "B2"),
```

Le javadoc l'admet lui-même deux paragraphes plus bas (« quand la spec donne une
fourchette EE1 « A1-A2 », EE2 « A2-B1 », EE3 « B1-B2 », on retient la borne
HAUTE ») : c'est **notre choix pédagogique**, pas une règle de France Éducation
international. Même affirmation répétée dans `SkillTaskProgressDto.java:11-13`.

**Aucun changement de valeur n'est nécessaire** — c'est le **commentaire** et
surtout **ce que l'UI en dit** qui posent problème. Conforme à ta consigne du
message 7.

---

## 4. 🟡 « Niveau A2 » en pastille sur la tâche jouée — à requalifier, pas à retirer

- `web_sejoufr/app/_components/production/EeWritingForm.tsx:214`
- `web_sejoufr/app/_components/production/EoRecordingForm.tsx:685`
- `mobile_sejourfr/lib/screens/tcf_production/ee_briefing_writing_screen.dart:590`
- `mobile_sejourfr/lib/screens/tcf_production/eo_briefing_screen.dart:669`

⚠️ **Ici la donnée est légitime** : `production_tasks.niveau_cible` existe en
A2 / B1 / B2 **pour chacune des 3 tâches** (vérifié : 8 sujets A2, 6 B1, 6 B2
par tâche à l'écrit). La pastille dit donc « la variante que vous jouez est
calibrée A2 », pas « la tâche 1 est officiellement A2 ».

Le problème est **le libellé** : « Niveau A2 » collé à « Tâche 1 » se lit comme
une caractéristique de la tâche. `docs/notation-ia-eo-ee.md:424` dit déjà la
bonne formule : **« Niveau visé »**, et précise que ce n'est pas un plafond.

**Proposition** : « Niveau visé A2 ». Un mot, les deux fronts.

---

## 5. 🟡 « Le niveau final est le plancher de vos 3 tâches (règle TCF IRN) »

- `web_sejoufr/app/_components/production/ProductionExams.tsx:339`
- `web_sejoufr/app/_components/production/config.ts:103` et `:121` (« le plancher des 3 tâches »)

La règle du plancher **est** officielle — mais sur les **4 épreuves** du TCF, pas
sur les 3 tâches d'une même épreuve. La variante correcte existe d'ailleurs à
côté : `TcfFullExamBriefingSheet.tsx:31` dit bien « le plancher de vos **4
épreuves** (règle TCF IRN) ».

Prendre le plancher des 3 tâches pour noter une épreuve d'expression est une
**convention maison défendable**, mais elle est présentée comme officielle.

**Proposition** : retirer « (règle TCF IRN) » des trois occurrences « 3 tâches »,
et garder la mention sur la ligne « 4 épreuves ».

---

## 6. Récapitulatif des écarts

| # | Écart | Gravité | Portée |
|---|---|---|---|
| 1 | Blog : format TCF Canada publié comme IRN | 🔴 public | 6 articles, dont 1 à réécrire entièrement |
| 2 | Rollback `v9` réintroduit 60-90 | 🔴 silencieux | 1 variable d'env, aucun garde-fou |
| 3 | « référentiel OFFICIEL » sur les paliers de tâche | 🟠 | 2 javadoc |
| 4 | Pastille « Niveau A2 » ambiguë | 🟡 | 4 fichiers, 2 fronts |
| 5 | « règle TCF IRN » sur le plancher des 3 tâches | 🟡 | 3 lignes |

🛑 **Rien n'est corrigé.** Les écarts 3, 4 et 5 sont des changements de libellé
et de commentaire ; l'écart 1 est un chantier éditorial ; l'écart 2 est un
arbitrage.
