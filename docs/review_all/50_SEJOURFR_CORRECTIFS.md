# SejourFR — Correctifs de spécification après audit

> **Ce document fait autorité sur `00_`, `10_`, `20_` et `30_`.**
> Ordre de lecture pour Claude Code : `00_` → `10_` → `20_` → `30_` → `40_AUDIT` → **`50_` (celui-ci)**.
> En cas de contradiction, c'est ce document qui l'emporte, puis l'audit, puis les specs initiales.
>
> Motif : les quatre premiers documents ont été rédigés à partir d'une description du produit qui
> ne correspondait pas au dépôt. L'audit `40_` l'a établi par la mesure. Plutôt que de réécrire les
> specs — ce qui effacerait la trace de ce qui a changé et laisserait passer des hypothèses mortes —
> on rectifie section par section.

---

# 1. Les trois erreurs de départ

| Hypothèse des specs | Réalité mesurée | Conséquence |
|---|---|---|
| Web en Angular | **Next.js 16 / React 19** | Matrice de parité et routes à réécrire (§7) |
| CO, EE, EO non modélisés ; micro-exercices à créer | **Tout existe** : 560 questions CO avec 100 % d'audios, modèle EE/EO complet, correcteur LLM v15, 48 compétences, 720 sujets courts | Les lots L2 et L6 sont faits à ~90 % (§8) |
| Abonnement 14,99 €/mois | **Aucun abonnement récurrent actif** : pass à achat unique de 9,99 € à 29,99 € | Tout le wording de paywall est faux et juridiquement risqué (§4.4) |

Ce qui reste réellement neuf, et qui justifie ces specs : le **diagnostic écrit rapide**, le
**diagnostic TCF 4 épreuves**, le **référentiel de notions civiques** et la **répétition espacée**.
Le reste est du réalignement.

Conséquence de cadrage, que l'audit rend visible : **le gros du chantier n'est plus le TCF, c'est le
civique.** Côté TCF il reste à créer les deux diagnostics, à y reconnecter un Plan qui existe déjà et
plus riche que la spec, et à mettre les rapports dans la forme voulue. Côté civique, les notions et
la répétition espacée sont un produit entier à construire, contenu compris.

---

# 2. Principe directeur des correctifs

**L'existant a raison par défaut.** Quand une spec et le dépôt divergent sans qu'un besoin produit
précis l'exige, c'est la spec qui se plie. Plusieurs mécanismes du dépôt sont meilleurs que ce que
j'avais écrit et ne doivent pas être touchés (§10).

---

# 3. Décisions sur les 8 questions ouvertes de l'audit

## 3.1. Q1 — Persistance du diagnostic rapide avant le compte : **résolution par le client**

L'audit pose une alternative qui n'en est pas une. La règle du dépôt
(`docs/regles/diagnostic.md` : aucune ligne en base sans compte) est **conservée**.

```
Rédaction → persistance CÔTÉ CLIENT uniquement
            web    : localStorage
            mobile : secure storage
         → création de compte OU connexion        (flux d'authentification standard, inchangé)
         → token obtenu
         → POST /api/diagnostics                  (authentifié) — crée la session
         → POST .../productions                   — envoie le texte lu depuis le stockage local
         → POST .../analyze                       — déclenche le LLM
         → résultat
```

**Le texte ne voyage jamais dans la requête d'inscription.** Mélanger authentification et métier
créerait un endpoint d'inscription à double responsabilité, plus difficile à sécuriser et à tester.
L'UX est identique — l'utilisateur ne voit qu'un enchaînement — mais l'architecture reste propre.

- `diagnostic_sessions.user_id` reste `NOT NULL`. **Ne rien rendre nullable.**
- Aucun `anon_id` n'est introduit. Le terme disparaît des specs.
- Le stockage local est purgé une fois la session créée côté serveur, jamais avant.
- Si l'envoi échoue après authentification, le texte est toujours en local : l'écran propose
  « Reprendre l'analyse », il ne renvoie pas l'utilisateur à la rédaction.
- **Correctif à `10_` §3.4 et `30_` §4.2/4.3** : remplacer « persistée sur l'`anon_id` » par
  « persistée sur l'appareil ». Le texte de T03 devient :
  « Votre texte est enregistré sur cet appareil. Créez votre compte pour lancer l'analyse. »
- Cas dégradé assumé : changement d'appareil avant inscription → texte perdu. Acceptable.

### Accessibilité sans compte : web **et** mobile

Le diagnostic rapide n'a de sens que s'il est atteignable avant inscription sur les deux
plateformes. **T01, T02 et T03 sont accessibles sans authentification en web et en mobile.**

Cela **ne crée pas** un mode invité mobile : le redirect global vers `/login` reste la règle, on
étend seulement l'allowlist existante — qui contient déjà `/diagnostic` — aux routes de rédaction et
de porte de compte. Tout le reste de l'application mobile reste protégé, et les séries et examens
en invité restent une exclusivité web assumée.

## 3.2. Q2 — Le diagnostic rapide **remplace** l'actuel

L'existant (EE 100-130 mots + EO 2-3 min) est remplacé par la production transversale unique de
150-220 mots. Conséquence acceptée : **plus aucun signal oral au diagnostic rapide**.

C'est cohérent avec la spec telle qu'écrite : T05 verrouille déjà « 🔒 Vos priorités en expression
orale », et le diagnostic complet évalue désormais EO1 + EO2 + EO3. Deux diagnostics rapides
concurrents seraient pire que la perte du signal EO à l'entrée.

## 3.3. Q3 — Aucun lecteur audio dans le rapport EO : **confirmé**

La décision « aucun audio de candidat conservé » est maintenue et prime.

- **Supprimer** le bloc `[0. Votre enregistrement]` de `30_` §6.3 (T25). Le rapport EO commence
  directement par « Ce que nous avons entendu » (transcription + avertissement), sans lecteur.
- **Supprimer** dans `10_` §7.4 : « lecture de son propre enregistrement disponible dans le rapport ».
- **Supprimer** dans `00_` §13 : « Audio EO : stockage S3 chiffré, URL signées, suppression
  automatique après 12 mois ». Remplacer par :
  > Aucun enregistrement de candidat n'est conservé. L'audio est transcrit en flux puis détruit ;
  > seule la transcription est stockée. Le seuil multipart de 26 Mo est délibéré et ne doit jamais
  > être abaissé : à la valeur par défaut, Spring écrirait les enregistrements sur disque.

## 3.4. Q4 — **Pass à achat unique conservés**

Décision : on ne revient pas à l'abonnement récurrent. Le public vise une date d'examen ; un pass
borné correspond mieux au besoin qu'un abonnement, et c'est le modèle vivant du dépôt.

**A14 est annulé.** Il n'y a pas de « pack 3 mois » à créer : `CIVIQUE_PASS_3M` existe déjà.

Correctifs de wording, obligatoires avant L5 — sur un achat unique, les formulations actuelles sont
**trompeuses**, pas seulement inexactes :

| À supprimer | À utiliser |
|---|---|
| « 14,99 €/mois » | le prix et la durée du pass concerné |
| « Annulable à tout moment » | « Accès pendant 30 jours. Aucun renouvellement automatique. » |
| « renouvellement le 9 octobre » | « Votre accès se termine le 9 octobre. » |
| « Passez Premium » | « Débloquer mon plan {cible} » (inchangé) |
| « Restaurer mes achats » | conservé sur mobile uniquement (IAP), retiré sur web |

Nouveau levier de vente, propre aux pass et à utiliser dans le paywall quand la date d'examen est
connue : **aligner la durée du pass sur l'échéance**.

> « Votre examen est le 18 octobre. Le pass 2 mois couvre toute votre préparation. »

Sections à réécrire : `10_` §5, `20_` §6 (bloc Premium), `30_` §10.1 (G02) et `30_` §10.2 (G03).

## 3.5. Q5 — Tests front : **supprimer la dérivation, pas les tests**

Mon exigence de « tests de rendu web et mobile » (`10_` §13, `00_` §15) est **retirée** : elle
créait un conflit frontal avec `CLAUDE.md`.

Mais **supprimer des tests n'est pas un chantier de cette refonte.** Un test qui protège la
navigation, l'affichage, le paiement, le mapping d'API, la persistance locale du diagnostic ou un
composant critique apporte de la valeur, quel que soit le côté où il vit.

Ce qui est réellement en cause, ce n'est pas leur emplacement, c'est **ce que certains protègent** :

1. identifier les tests qui verrouillent une **dérivation métier côté client**
   (`estimated-tcf-level`, `target_procedure_levels`, `niveau_cecrl_display`, `skill-progress`) ;
2. **déplacer la dérivation vers le serveur**, qui la sert déjà pour la progression ;
3. le test perd son objet et disparaît **avec le code qu'il testait**, pas avant ;
4. **tous les autres tests front existants sont conservés.** Aucune suppression de masse.

Le miroir `TargetProcedure` gelé par test de chaque côté est **conservé tel quel** : il existe
précisément parce que la table des paliers a vécu en six copies.

Règle de travail pendant la refonte : **ne pas ajouter de nouveau test front**, ne pas en retirer
hors du cas 3.

⚠ **Point de conflit à traiter par le propriétaire, pas par l'implémentation.** `CLAUDE.md` pose
« aucun test sur les fronts, jamais — cette règle prime sur toute consigne écrite ailleurs ». Tant
que cette phrase reste telle quelle, Claude Code recevra deux instructions contradictoires et
tranchera seul. Si les tests front sont conservés, **c'est `CLAUDE.md` qu'il faut amender**, par
exemple : « Pas de nouveaux tests sur les fronts. Les tests existants qui ne verrouillent aucune
règle pédagogique sont conservés. » Ce document ne peut pas amender `CLAUDE.md` à ta place.

Remplacement de la garantie de parité : étendre
`scripts/verifier-contrat-front-progression.mjs` aux nouveaux contrats (diagnostic, plan, paywall)
plutôt que d'écrire des tests de rendu.

## 3.6. Q6 — Référentiel de notions : **ne rien figer avant le tagging**

Ma réduction à 28 notions était une erreur de méthode. Elle découlait d'une règle que j'avais moi-même
posée sans la justifier — « 6 questions par notion **et par mention** » — puis appliquée comme une
contrainte physique. Une division arithmétique ne décide pas d'un découpage pédagogique.

**Cette règle est annulée** et remplacée par une dégradation par notion et par mention (§6.1).

Décision : on part d'un **référentiel de travail de 40 notions**, on tague, on **mesure la couverture
réelle**, puis on fusionne uniquement ce que le contenu montre comme trop fin. Cible finale attendue :
**30 à 40 notions**, arrêtée après le tagging et pas avant.

Corollaire important : **`CIV_PRINCIPES` conserve ses notions.** C'est même le thème où elles sont
les plus parlantes pour un candidat. « À travailler : la laïcité » vaut infiniment mieux que
« À travailler : Principes et valeurs de la République » — et c'est exactement ce qui distingue le
plan Premium d'un simple filtrage par thème. Mon exclusion définitive de ce thème est retirée.

## 3.7. Q7 — **Pas de `/api/v1`**

Toutes les routes des specs sont à lire sous `/api/`. Les blocs `10_` §12 et `20_` §11 sont
corrigés en conséquence : supprimer `/v1` partout. Ne pas créer une seconde convention sur
48 contrôleurs.

## 3.8. Q8 — La mention reste portée par `difficulty`

Option (c) de l'audit. `questions.difficulty` continue de valoir `CSP` | `CR` | `NAT` pour le
civique. **Aucune colonne `mentions text[]` n'est créée**, aucune migration du catalogue.

- **Correctif à `20_` §1.2** : supprimer « tableau, pas une clé étrangère unique ». Une question
  civique sert **une seule** mention.
- Conséquence sur les notions : `civic_notion.mentions` reste un tableau (une notion, elle, est
  bien transverse aux mentions), mais le scoping des questions se fait par `difficulty`.
- Si un jour une question doit servir deux mentions, le sujet sera rouvert avec une preuve d'usage.

---

# 4. Correctifs au document maître `00_`

| Section | Correctif |
|---|---|
| §1.1 | Remplacer l'état des lieux par celui de l'audit §1 à §6. Web = Next.js ; CO/EE/EO modélisés ; module Compétences livré |
| §1.2 | Retirer de la colonne « Nouveau » : modèle EE/EO, micro-exercices, quotas séparés. Ne restent neufs que les 4 éléments du §1 ci-dessus |
| §3 A2 | Inchangé et confirmé |
| §3 A14 | **Annulé** (§3.4) |
| §3 A15 | Confirmé par l'audit : aucun cache offline, l'app est 100 % en ligne |
| §6.1 | Colonne « Angular » → **Next.js 16 App Router**. Les divergences autorisées restent valables |
| §6.2 | Confirmé, et déjà appliqué par le dépôt (`locked` servi, contrat vérifié par script) |
| **§6.3** | **Supprimé.** L'i18n commun n'existe dans aucun front, l'audit l'estime à un lot entier, et l'application est monolingue française. Exigence retirée : les textes restent où ils sont |
| §6.4 | Conservé. Le dépôt applique déjà le principe |
| §6.5 | `client_submission_id` UUID obligatoire : **maintenu, et prioritaire** (§8, L1). La phrase sur les identifiants d'entités reste supprimée |
| §7.1 | **Remplacé** par la matrice réelle de l'audit §4.5 : 1 essai d'entraînement par épreuve à vie, 1 examen blanc production offert, 1 examen TCF complet offert avec EE+EO évaluées une fois, 1 compétence ouverte par tâche + celle de la priorité n°1, 2 sujets par compétence, 3 analyses IA à vie, slot 1 d'examen blanc offert. Ne pas remplacer ce système par « 1 EE + 1 EO » |
| §7.2 | Le champ `source` n'existe pas. Voir §8.4 ci-dessous |
| §7.4 | Conservé comme filet, mais l'audit montre qu'aucun cas n'est réel : audios CO 100 %, explications civiques 100 % |
| **§8.4** | `ai_usage` **n'est pas créée**. À la place : une **vue SQL** unifiant `ai_evaluations`, `transcriptions` et `user_skill_attempts`, avec un `source` dérivé du contexte. Une donnée déjà écrite trois fois ne se duplique pas une quatrième |
| §9 | Les tokens réels portent d'autres noms (`--color-blue`…) pour des valeurs **identiques**. **Ne rien renommer.** Les composants demandés existent sous d'autres noms : vérifier au cas par cas, ne pas recréer |
| §12 | Les tables `analytics_event`, `user_funnel_events`, `page_views` existent. Les événements du tunnel s'ajoutent à ce système, on n'en crée pas un second |
| §13 | Voir §3.3 pour l'audio. Ajouter : suppression de compte déjà livrée (`AccountDeletionService`) ; **vérifier l'export des données**, non confirmé par l'audit |
| §14 | Plan de lots **remplacé** par le §8 ci-dessous |
| §15 | Retirer « tests des deux côtés » et « matrice de parité cochée » comme critère bloquant tant que §3.5 n'est pas exécuté |

---

# 5. Correctifs au document TCF `10_`

## 5.1. Modèle : correspondances à utiliser

Ne créer aucune des tables de `10_` §11 qui a déjà un équivalent.

| Spec | À utiliser | Écart à combler |
|---|---|---|
| `tcf_task` | `production_tasks` | ajouter `prep_seconds` ; `duree_max_sec` tient lieu de `max_duration_seconds` |
| `tcf_subject` | `production_tasks` | une tâche = un sujet dans le dépôt. **Ne pas séparer** sans besoin avéré |
| `tcf_competence` / `_task_competence` | `skills` + `diagnostic_task_skills` | les codes de `10_` §2.3 (`ee_argumenter`…) sont **abandonnés** au profit des 48 codes existants |
| `tcf_micro_exercise` | `skill_prompts` (720) + `skill_references` (2 160) | rien |
| `tcf_production` | `production_submissions` + `user_skill_attempts` | **ajouter `client_submission_id`** + unicité |
| `tcf_ai_report` | `ai_evaluations`, `diagnostic_production_analyses` | rien |
| `user_tcf_competence_state` | `progression_state` (moteur V4.2) | rien — le moteur existant est plus riche que mes seuils |
| `tcf_plan*` | calcul à la lecture, `LearningPlanService` | voir §5.4 |
| `quick_diag_subject` | **à créer** | seule table réellement nouvelle du module TCF |

## 5.2. Seuils de maîtrise (`10_` §8.4)

**Annulés.** Le moteur de progression V4.2 possède déjà ses états et son système de preuves
(`learning_evidence`, `progression_state`). Mes seuils (« 2 verdicts consécutifs + simulation »,
« décroissance à 30 jours ») ne doivent pas être plaqués par-dessus : ils créeraient une seconde
autorité sur la même question. Utiliser les états existants et, s'ils manquent quelque chose,
étendre V4.2 plutôt que le doubler.

## 5.3. Prompts (`10_` §10)

Les six prompts que j'ai rédigés sont **annulés en tant que nouveaux prompts**. Le dépôt possède un
système de grilles versionnées avec matrice rubriques ↔ schéma vérifiée au démarrage, preuve par
segment numéroté et réparation unique. Il ne faut surtout pas ouvrir une septième famille.

| Besoin | Ce qu'on fait |
|---|---|
| Diagnostic rapide | **Nouvelle version** de `diagnostic-analysis-rubrics` (v1 → v2). La v1 prévoit déjà `analysis_type=INITIAL_DIAGNOSTIC` et « l'exercice hybride n'est pas une tâche officielle du TCF » : c'est exactement la production transversale. Adapter à une production unique écrite |
| Tâche complète EE/EO | `production-rubrics-v15` **inchangée** |
| Micro-exercice | `competence-analysis-rubrics-v6` **inchangée** |
| Génération de contenu | `AdminSkillPromptController` existe |

Mon exigence de versionnement (`00_` §8.1) est déjà dépassée par le dépôt, qui conserve v1→v15
simultanément chargeables. Rien à faire.

## 5.4. Plan matérialisé (`10_` §6.4)

**Correctif** : l'invariant « dérivé serveur ⇒ jamais persisté » est conservé. On applique
l'option (c) de l'audit :

- le Plan reste **calculé à la lecture** ;
- on persiste uniquement un `plan_version` et un **hash du plan calculé**, pour détecter un
  changement entre deux lectures ;
- le bloc « Progression détectée » s'appuie sur ce hash et sur `PlanRecentChangesResolver` et
  `learning_plan_observations`, qui existent déjà.

Supprimer de `10_` §11 les tables `tcf_plan`, `tcf_plan_item`, `tcf_plan_step`.

## 5.5. Autres

- **§7.4** : supprimer la mention du lecteur audio (§3.3).
- **§12** : supprimer `/v1` de toutes les routes.
- **§13** : supprimer les tests de rendu front ; conserver tous les tests de moteur et de quota,
  qui restent backend.
- **§9 mode dégradé** : conservé comme filet, sans cas d'usage réel aujourd'hui.
- **Correctif à l'audit B12** : « EO1 n'a qu'un sujet par niveau » n'est pas un manque. À l'EO1 du
  TCF IRN, le candidat ne lit aucun sujet : l'examinateur mène un **entretien guidé** sur lui-même
  et son quotidien. Un seul « sujet » par niveau est donc conforme au format, et il ne faut surtout
  pas en inventer quinze.
  Ce qui doit varier, c'est le **jeu de questions posées**. Modéliser une banque de relances
  rattachée à la tâche EO1 (`eo1_question_set` : ~15 jeux de 4 à 6 questions, tirage aléatoire,
  scopé par niveau), afin qu'un candidat qui refait EO1 ne rejoue pas le même échange.
  Aucun nouveau `production_task` n'est créé pour cela.

---

# 6. Correctifs au document civique `20_`

## 6.1. Référentiel de notions — méthode, pas liste figée

Les 54 notions de `20_` §2 ne sont **ni validées ni remplacées par une liste définitive**. Elles
deviennent un **référentiel de travail**, resserré à 40 notions par fusion des doublons évidents, et
destiné à être ajusté **après** le tagging.

### La règle de volume est remplacée

`20_` §2.5 posait « minimum 6 questions actives par notion **et par mention** ». Annulé. Nouvelle
règle, qui dégrade par notion et par mention au lieu d'exclure un thème entier :

| Situation mesurée après tagging | Comportement |
|---|---|
| ≥ 5 questions actives dans la mention de l'utilisateur | notion pleinement utilisable, éligible comme priorité du plan |
| 1 à 4 questions dans cette mention | notion visible en révision libre, **non éligible comme priorité** pour cette mention ; repli au thème **pour cette mention seulement** |
| 0 question dans cette mention | notion invisible pour cette mention |
| < 12 questions **toutes mentions confondues** | candidate à la fusion (§6.1.3) |

Le repli est donc désormais **par notion et par mention**, jamais « ce thème n'a pas de notions ».

### 6.1.1. Référentiel de travail — 40 notions

**Principes et valeurs de la République** (79 questions) — conservé avec notions

| Code | Libellé |
|---|---|
| `pv_laicite` | La laïcité |
| `pv_symboles` | Les symboles de la République |
| `pv_devise_valeurs` | La devise et les valeurs républicaines |
| `pv_egalite_non_discrimination` | Égalité et refus des discriminations |
| `pv_libertes_fondamentales` | Les libertés fondamentales |
| `pv_ddhc` | La Déclaration des droits de l'homme et du citoyen |

**Système institutionnel et politique** (214 questions)

| Code | Libellé |
|---|---|
| `inst_constitution` | La Constitution et la Ve République |
| `inst_president` | Le Président de la République |
| `inst_gouvernement` | Le Gouvernement et le Premier ministre |
| `inst_parlement` | Le Parlement : Assemblée nationale et Sénat |
| `inst_elections` | Les élections et le droit de vote |
| `inst_commune` | La commune et le maire |
| `inst_departement_region` | Le département et la région |
| `inst_justice` | La justice et les tribunaux |
| `inst_ue` | L'Union européenne |

**Droits et devoirs** (166 questions)

| Code | Libellé |
|---|---|
| `dd_droits_fondamentaux` | Les droits fondamentaux |
| `dd_devoirs_citoyen` | Les devoirs : lois, impôts, jury |
| `dd_egalite_loi` | L'égalité devant la loi |
| `dd_travail` | Droits et devoirs au travail |
| `dd_protection_sociale` | Protection sociale et assurance maladie |
| `dd_ecole_enfance` | École obligatoire et droits de l'enfant |
| `dd_logement` | Droits et obligations liés au logement |
| `dd_liberte_culte` | La liberté de culte et ses limites |

**Histoire, géographie et culture** (215 questions)

| Code | Libellé |
|---|---|
| `hg_revolution` | La Révolution française et 1789 |
| `hg_dates_republique` | Les grandes dates de la République |
| `hg_loi_1905` | La séparation des Églises et de l'État |
| `hg_guerres_resistance` | Les guerres mondiales et la Résistance |
| `hg_conquetes_droits` | Les grandes conquêtes de droits |
| `hg_europe` | La construction européenne |
| `hg_geographie` | Géographie de la France et outre-mer |
| `hg_patrimoine` | Patrimoine et monuments |
| `hg_langue_culture` | Langue française, culture et francophonie |

**Vivre dans la société française** (166 questions)

| Code | Libellé |
|---|---|
| `vs_demarches` | Les démarches administratives courantes |
| `vs_sante` | Se soigner au quotidien |
| `vs_logement_pratique` | Se loger : bail, aides, voisinage |
| `vs_emploi` | Travailler et chercher un emploi |
| `vs_transports_securite` | Transports, sécurité routière et urgences |
| `vs_budget_impots` | Budget, banque et impôts |
| `vs_vie_collective` | Vivre ensemble et respect des règles |
| `vs_laicite_quotidien` | La laïcité dans la vie quotidienne |

**Couples à surveiller au tagging**, susceptibles de fusionner : `dd_logement` / `vs_logement_pratique`,
`pv_laicite` / `vs_laicite_quotidien` (principe vs application concrète — à trancher sur pièces),
`inst_commune` / `inst_departement_region`, `hg_patrimoine` / `hg_langue_culture`.

### 6.1.2. Ordre de tagging

Commencer par les thèmes les mieux dotés — `CIV_HISTOIRE_GEO` (215) puis `CIV_INSTITUTIONS` (214) —
pour calibrer la méthode et le taux d'hésitation du modèle avant d'attaquer `CIV_PRINCIPES`, plus
petit et plus sujet aux recouvrements.

### 6.1.3. Porte de revue après tagging — livrable obligatoire

Le tagging terminé, produire `docs/decisions/notions-civiques.md` avec la couverture mesurée par
notion × mention, puis appliquer :

| Règle | Action |
|---|---|
| notion < 12 questions toutes mentions confondues | fusionner avec la notion voisine du même thème |
| deux notions dont plus de 30 % des suggestions sont hésitantes entre elles (`confidence < 0.7`) | candidates à fusion, tranchées à la main |
| notion > 60 questions | candidate à scission |
| notion ≥ 12 mais faible sur une mention | **conservée**, repli par mention (tableau ci-dessus) |

Aucune fusion ni scission n'est appliquée automatiquement : le job propose, un humain valide, comme
pour le tagging lui-même.

## 6.2. Domaines de situation — réduits à 5

176 mises en situation seulement. Les 7 domaines de `20_` §2.6 deviennent :

| Code | Libellé |
|---|---|
| `sit_demarches` | Services publics et démarches |
| `sit_travail_ecole` | Travail, école et parentalité |
| `sit_vie_collective` | Vie quotidienne et voisinage |
| `sit_laicite` | Laïcité et vivre-ensemble |
| `sit_droits_sante` | Faire valoir ses droits, santé |

## 6.3. Mises en situation dans le diagnostic — **7 sur 24 conservées**

Ma réduction à 5 sur 24 est **annulée**. Le diagnostic doit refléter ce que le candidat doit savoir
faire à l'examen, pas la composition actuelle de notre base. Les mises en situation sont un axe
pédagogique distinct des connaissances : les sous-représenter au diagnostic reviendrait à
sous-détecter précisément la difficulté qui fait échouer.

`20_` §4.2 reste donc : **17 connaissances + 7 mises en situation**, réparties sur au moins
3 domaines. Le stock de 176 questions le permet sans difficulté, y compris sur NAT (45 disponibles).

Deux contraintes de tirage à coder, elles, restent nécessaires :

- **sur CSP, ne jamais tirer de mise en situation dans `CIV_PRINCIPES`** : il n'y en a qu'une seule.
  À traiter comme une contrainte dure du tirage, pas comme une probabilité faible ;
- ne jamais évaluer un thème sur une seule question, toutes catégories confondues.

Là où le déficit de contenu mord réellement, c'est sur les **examens blancs répétés** : 12 questions
sur 45 disponibles en NAT signifie que le deuxième examen blanc rejoue largement le premier. C'est
un problème de contenu, pas de diagnostic — traité au §9.

## 6.4. Autres

- **§1.2** : mention portée par `difficulty`, une seule par question (§3.8).
- **§3.4** : le mode dégradé « question sans explication » n'a aucun cas réel (100 % des questions
  civiques ont une explication). Conserver comme filet.
- **§5** : la répétition espacée est à construire **intégralement**, support de données compris.
  `user_question_statuses` est un compteur d'erreurs, pas un moteur de mémorisation. C'est le vrai
  coût de L10.
- **§11** : supprimer `/v1` des routes.

---

# 7. Correctifs au document écrans `30_`

| Écran | Correctif |
|---|---|
| **T01** | La date d'examen n'existe pas en base. Ajouter `users.exam_date` (nullable) en L1. Sans elle, T01 Q3, le paywall et G01 perdent leur personnalisation |
| **T02 / T03** | Persistance **côté client**, pas `anon_id` (§3.1). Texte de T03 corrigé |
| **T25** | **Supprimer le bloc `[0. Votre enregistrement]`.** Le rapport EO commence par la transcription |
| **T02/T03** | Accessibles sans authentification **en web et en mobile** (§3.1). Étendre l'allowlist mobile existante, ne pas créer de mode invité |
| **T27** | Le rapport de micro-sujet existe déjà, avec `criterion_status` (`VALIDATED` / `PARTIAL` / `NOT_VALIDATED`) et 3 références (`INSUFFICIENT` / `EXPECTED` / `EXCELLENT`). **Mapper** mes 6 blocs sur cette structure au lieu de créer un format concurrent : verdict ← `criterion_status`, avant/après ← références `EXPECTED` et `EXCELLENT` |
| **G02 / G03** | Réécrire pour des pass (§3.4). G03 n'est pas une « gestion d'abonnement » mais un **suivi d'accès** : date de fin, pas de résiliation |
| **A04** | S'appuie sur la vue SQL unifiée, pas sur une table `ai_usage` |
| **§12** | Les routes citées sont Angular. Les remplacer par les routes Next.js réelles relevées à l'audit §1.3, notamment `/entrainement/tcf/{ee\|eo}/tache/[n]/competences/[skillId]/[promptId]` |
| **§13** | Matrice remplacée par le §7.1 ci-dessous |
| **§14** | Retirer les critères de test front |

## 7.1. Matrice de parité — colonnes corrigées

Colonne « Angular » → **Next.js**. Deux colonnes ajoutées : *Existe déjà* et *À adapter*, pour ne
pas recompter comme neuf ce qui est livré.

| ID | Écran | Next.js | Flutter | Existe déjà | Nature du travail |
|---|---|:--:|:--:|:--:|---|
| T01 | Objectif / date | ☐ | ☐ | partiel | ajouter la date d'examen |
| T02–T04 | Rédaction, porte de compte, analyse | ☐ | ☐ | non | à créer |
| T05 | Résultat rapide | ☐ | ☐ | partiel | refonte (EE+EO → transversal) |
| T06–T11 | Diagnostic 4 épreuves | ☐ | ☐ | non | à créer — le plus gros lot |
| T12 | Résultat complet | ☐ | ☐ | non | à créer |
| T13 | Paywall | ☐ | ☐ | oui | contextualiser + réécrire pour les pass |
| T14–T16 | Plan | ☐ | ☐ | **oui, plus riche** | aligner, ne pas reconstruire |
| T20–T22 | Réviser EE/EO | ☐ | ☐ | **oui** | rien, ou ajustements |
| T23 | Tâche complète | ☐ | ☐ | **oui** | rien |
| T24–T25 | Rapports de tâche | ☐ | ☐ | **oui** | aligner l'affichage, retirer l'audio |
| T26–T27 | Micro-exercice et rapport | ☐ | ☐ | **oui** | mapper les 6 blocs |
| T28 | Progrès TCF | ☐ | ☐ | **oui** | rien |
| C01 | Mention | ☐ | ☐ | partiel | `TargetProcedure` existe |
| C02–C03 | Diagnostic civique | ☐ | ☐ | non | à créer |
| C04 | Plan civique | ☐ | ☐ | non | à créer |
| C05–C08 | Réviser civique | ☐ | ☐ | partiel | notions à ajouter |
| C09–C11 | Séries, correction, examen | ☐ | ☐ | **oui** | brancher sur Leitner |
| G01 | Accueil agrégé | ☐ | ☐ | **oui** | aligner |
| G02–G04 | Abonnement, profil | ☐ | ☐ | **oui** | réécrire pour les pass |

**T01 à T03 sont accessibles sans compte sur les deux plateformes** : le diagnostic rapide n'a de
sens que s'il est atteignable avant inscription, sur mobile comme sur web. T04 et T05, qui viennent
après l'authentification, ne posent pas la question.

En revanche, le **mode invité général** (séries libres, examens démo) reste **web uniquement**, par
décision assumée. Ce n'est pas un trou de parité.

---

# 8. Plan de lots révisé

Remplace `00_` §14. Ordre issu de l'audit §9, que je reprends : il est meilleur que le mien.

| Lot | Contenu | Effort | Note |
|---|---|:--:|---|
| **L1** | `client_submission_id` + unicité · `users.exam_date` · vue SQL de coût · événements du tunnel | **M** | i18n retiré du périmètre |
| **L4** | Diagnostic TCF 4 épreuves | **XL** | Le vrai gros morceau restant |
| **L5** | Paywall contextualisé + réécriture pass · alignement du Plan | **M** | Le Plan existe |
| **L7** | Boucle de réévaluation | **M** | V4.2 fournit déjà états et preuves |
| **L3** | Diagnostic écrit rapide | **L** | Débloqué par la décision Q1 ; ne retarde pas L4 |
| **L8** | Référentiel de travail (40 notions) + tagging admin + porte de revue | **XL** | Chemin critique **éditorial**. Se termine par `docs/decisions/notions-civiques.md` et l'arrêt du référentiel définitif |
| **L9** | Diagnostic civique + mises en situation | **L** | Contrainte de tirage CSP à coder |
| **L10** | Plan civique + Leitner | **XL** | Tout à construire, support de données compris |
| **L11** | Examens blancs branchés + Progrès unifié | **M** | 21 templates existent |
| **L6** | Alignement du rapport micro + contenu EO1 | **S** | Largement livré |
| **L12** | Supervision des coûts IA | **M** | Dépend de la vue de L1 |

**L2 est supprimé** : déjà livré.

**Première action recommandée, avant tout le reste** : `client_submission_id`. Sans lui, une perte
de réseau en fin de soumission EO peut déclencher deux corrections payantes. Une migration, deux
gardes, et cela protège directement l'argent dépensé en IA.

---

# 9. Chantiers de contenu

Le code n'est pas le chemin critique. Ces trois chantiers le sont.

| Chantier | Volume | Bloque |
|---|---|---|
| Tagging des 1 016 questions civiques sur 28 notions | ~1 016 validations humaines assistées | L8 → L10 |
| Mises en situation civiques | ~120 questions à produire | répétition entre examens blancs (le diagnostic, lui, tient avec le stock actuel) |
| Banques de questions EO1 | ~15 jeux de relances | L6 |

---

# 10. Ce qui ne doit pas être touché

Mécanismes du dépôt supérieurs à ce que les specs proposaient. Toute modification doit être un
arbitrage explicite, jamais un effet de bord d'implémentation.

- **Preuve par segment numéroté** (v12+) : le modèle ne peut pas inventer une citation, par
  construction. Ne pas revenir à une preuve en texte libre.
- **`chk_ai_eval_aucun_verdict_si_non_evaluable`** : `null` = inconnu, jamais mauvais, rendu
  opposable par la base.
- **Matrice rubriques ↔ schéma vérifiée au démarrage** : une paire incohérente bloque le boot.
- **Ordre de préférence** : tool-schema > longueur plafonnée > contrôle serveur déterministe >
  consigne de prompt. Les versions v10 et v11 sont la preuve mesurée que l'inverse dégrade.
- **`ProductionAccessService.assertCanSubmit`** : garde unique pour les deux voies de notation,
  freemium opposable en 403, `locked` servi aux fronts.
- **Seuil multipart à 26 Mo** : délibéré, protège les enregistrements du disque.
- **Miroir `TargetProcedure` gelé par test** : né d'un incident réel, six copies de la table des
  paliers tirant un candidat NAT vers B1.
- **`out-of-order: true`** et la structure des migrations en 4 dossiers.
- **Tokens de couleur** : valeurs identiques sous d'autres noms. Ne rien renommer.

---

# 11. Décisions restant au propriétaire

| # | Décision | Recommandation | Bloque |
|---|---|---|---|
| D1 | Le diagnostic rapide perd le signal oral (Q2) | Accepter | L3 |
| D2 | Arrêter le référentiel définitif **après** le tagging, à la porte de revue §6.1.3 | Accepter | fin L8 |
| D3 | Produire ~120 mises en situation, ou assumer la répétition en examen blanc | Produire, après L9 | qualité |
| D4 | **Amender `CLAUDE.md`** sur les tests front, ou confirmer l'interdiction absolue (§3.5) | Amender : « pas de nouveaux tests front, les existants sans règle pédagogique sont conservés » | L1 — sinon instruction contradictoire dès le premier lot |
| D5 | Export des données personnelles : livré ou à faire ? | À vérifier avant toute communication RGPD | conformité |

---

# 12. Critère d'entrée en implémentation

Avant d'ouvrir L1, Claude Code doit avoir confirmé par écrit :

- [ ] qu'il a lu les 5 documents dans l'ordre et que `50_` prime ;
- [ ] qu'il ne créera aucune table listée en §5.1 comme ayant un équivalent ;
- [ ] qu'il n'ouvrira aucune nouvelle famille de prompts (§5.3) ;
- [ ] qu'il ne touchera à aucun élément du §10 sans arbitrage explicite ;
- [ ] qu'il n'introduira pas `/api/v1` ;
- [ ] qu'aucun **nouveau** test ne sera écrit sur les fronts, et qu'aucun test existant ne sera
      supprimé hors du cas §3.5 point 3 ;
- [ ] qu'il ne figera aucun référentiel de notions avant la porte de revue §6.1.3.
