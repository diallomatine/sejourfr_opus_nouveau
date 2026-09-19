# RÉPONSES À L'AUDIT CIVIQUE v2 — entrée en P8.0

Répond à `docs/audits/AUDIT_cycle_plan_civique_v2.md` (2026-09-19). Autorité : propriétaire, 2026-09-19.
Références : `SPEC_cycle_plan_civique.md`, `SPEC_cycle_plan.md`, `docs/decisions/plan-parcours-tcf.md`.

> ⛔ **HARD STOP.** Cette passe est **P8.0 uniquement** : consigner les arbitrages, lever D-23, révoquer
> la phrase de V058, conformer la spec. **Aucun code, aucune migration, aucun test.** Arrête-toi ensuite.

---

## 0. Le principe qui tranche tout le reste

**L'arrêté du 10 octobre 2025 est la source de vérité du module civique.** Là où le produit diverge du
texte, c'est le produit qui a tort, y compris quand la divergence est ancienne, documentée et testée.

Corollaire immédiat : **l'examen blanc doit simuler l'examen réel**. Un examen blanc qui tire 8/8/8/8/8
au lieu de 11/6/11/8/4 ne prépare pas au bon examen, quelle que soit la qualité de ses questions. C'est
la promesse centrale du produit, et elle n'est aujourd'hui pas tenue sur un seul des 33 examens passés.

L'audit v2 est validé dans ses mesures, ses conclusions et son découpage.

---

## 1. Le grain, le référentiel, la mention

| # | Réponse |
|---|---|
| **Q-F1 bis** | **Oui.** Le cycle civique adopte les **14 notions officielles de l'annexe I** comme unité travaillable. Les 46 notions internes restent la granularité du **plan dérivé** (choisir quoi faire travailler) ; le **cycle** compte au grain officiel. |
| **Q-F24** | **Oui.** Table de référence des unités officielles : libellé, thématique, ordre, **quota officiel par examen**. Le tirage conforme, le cycle et l'écran lisent le même objet. Le rattachement des 46 notions internes s'y fait par FK. |
| **Q-F22** | **Oui, pour la lecture d'entraînement et le cycle.** Le filtre `q.difficulty = :mention` est retiré ; la colonne reste en base comme métadonnée éditoriale (option **B** du §4.4). Le civique s'aligne ainsi sur le régime TCF, où le test est unique pour tous. |
| **Q-F30** | **Oui, et en priorité.** Le contrôle de couverture contre les trois listes publiques du ministère est lancé **avant** P8.A. Zéro appel LLM : extraction et rattachement aux 16 unités. |

⚠️ **La table de référence compte 16 lignes, pas 14.** Dans la répartition officielle, « Mises en
situation » figure **au même niveau qu'une notion**, avec son propre quota, dans deux thématiques :
Principes (6) et Droits et devoirs (6). Le cycle en fait donc une unité travaillable à part entière,
dans ces deux blocs seulement. Les 14 notions de connaissance + ces 2 unités = **16 lignes**.

### Ce que Q-F30 doit établir, et pourquoi il précède P8.A

L'audit relève à juste titre que le ministère publie **trois listes distinctes** (CSP ≈ 212, CR ≈ 205,
NAT en PDF). Le programme est unique ; la banque publiée ne l'est pas. Le contrôle de couverture doit
donc répondre à **une** question, chiffres à l'appui :

> Les trois listes publiques se recouvrent-elles largement, ou portent-elles des contenus réellement
> distincts ?

- **Recouvrement large** → le retrait du filtre est confirmé définitivement, y compris pour la
  composition des examens blancs.
- **Divergence réelle** → le filtre revient **pour la seule composition de l'examen blanc**, jamais pour
  l'entraînement ni pour le cycle, et le rapport dit exactement quelles questions écrire par mention.

Dans les deux cas, l'entraînement et le cycle restent sans filtre : R2 en dépend, et rien dans l'arrêté
ne justifie de restreindre ce qu'un candidat peut **travailler**.

Livrable attendu : couverture du stock SejourFR par unité officielle **et** par liste publique, taux de
recouvrement entre les trois listes, et la liste des unités où le stock ne couvre pas le programme.

---

## 2. La conformité de l'examen blanc

| # | Réponse |
|---|---|
| **Q-F23** | **Oui.** La conformité de l'examen blanc est un **chantier séparé et prioritaire (P8.A)**, avant le cycle. |
| **Q-F13 bis** | **Oui.** Le tirage devient une **contrainte dure** portant sur les trois axes : 11/6/11/8/4 par thématique, le quota par unité officielle à l'intérieur de chaque thématique, et **12 mises en situation placées uniquement en Principes (6) et Droits et devoirs (6)**. |
| **Q-F29** | **Oui.** Les 11 templates « Focus » mono-thème à 40 questions sont **dépubliés**. Structurellement non conformes, ils ne peuvent pas s'appeler « examen blanc ». Ce qu'ils offraient — travailler un thème — est exactement ce que le cycle fournit. |
| **Q-F21** | **Non.** Un examen de thème ne contient de mises en situation que dans les thématiques où l'examen réel en pose : Principes et Droits et devoirs. |

### Exigences de P8.A

1. **Une autorité unique de la répartition officielle, en code**, au même titre que `CivicExamFormat` :
   les 5 thématiques, leurs unités, leurs quotas, et le placement des 12 mises en situation. Aucune de
   ces valeurs n'est un réglage.
2. **Le quota par unité devient une contrainte du tirage**, pas une consigne. `civic_notion_id` (ou le
   rattachement à l'unité officielle) entre dans la requête de composition.
3. 🛑 **Le fallback de `pickQuestionsForTemplate` est encadré.** Un examen officiel ne doit jamais
   pouvoir compléter hors règles en silence : si les règles ne peuvent pas être satisfaites, l'examen
   **échoue bruyamment**, il ne se dégrade pas. C'est le défaut le plus grave relevé par l'audit, parce
   qu'il rend toute règle future inopérante sans le dire.
4. **Le format de l'examen de thème** (20 Q / seuil 16 / 20 min) applique les **proportions officielles
   internes** à la thématique. Il ne peut pas être conforme à l'examen réel — ce n'est pas son objet —
   mais il doit en respecter la structure.
5. **Le diagnostic civique est préservé tel quel.** Sa configuration `connaissances: 28` +
   `mises-en-situation: 12` est le seul endroit du dépôt qui tient le partage officiel. Ne pas y toucher.

---

## 3. Le schéma

| # | Réponse |
|---|---|
| **Q-F4** | **Oui.** `journey` reçoit `target_procedure`. La mention ne filtre plus le contenu, mais elle reste l'**objectif** d'un cycle civique : la démarche visée et le seuil. |
| **Q-F5** | **`entry_score` / `exit_score`.** Aucune réinterprétation des colonnes CECRL : un score n'est pas un niveau. |
| **Q-F6** | **Oui.** Le bloc désigne sa thématique par une **FK `theme_id`**. Un thème est une donnée de `themes`, pas une valeur d'enum. |
| **Q-F7** | **Reformulée et résolue.** L'unité travaillable est une **unité officielle**, dans sa table de référence de 16 lignes. Ni `skills` généralisée, ni `civic_notions` polymorphe : `journey_step` et `learning_plan_observations` pointent l'unité officielle. |
| **Q-F25** | **Oui.** `CivicDotation` et `questions-min-par-notion: 5` sont **supprimés**, pas laissés vides. Sans filtre de mention, ils ne discriminent plus rien, et une règle morte qui donne l'illusion d'un garde-fou est pire que pas de garde-fou. |

---

## 4. Le freemium civique — règle simplifiée

Le ledger « 1 examen de thème offert à vie » de la spec civique §3.3 est **abandonné**. Il transposait au
QCM une règle écrite pour les productions IA, qui n'a pas lieu d'être ici : un QCM ne coûte pas d'appel
LLM.

| Élément | Régime |
|---|---|
| Diagnostic civique | **Gratuit** |
| `civique-decouverte` (40 Q, seuil 32) | **Gratuit**, comme aujourd'hui. C'est une promesse déjà publiée et affichée ; elle est tenue. ⚠️ Elle doit être **rendue conforme** en P8.A comme les autres. |
| Examens de thème | **Premium** |
| Autres examens blancs globaux | **Premium** |
| Travailler une unité depuis le Plan | **Premium** |

| # | Réponse |
|---|---|
| **Q-F10** | **Oui**, `civique-decouverte` reste gratuit. |
| **Q-F8 / Q-F11** | **Sans objet** — pas de ledger civique. |
| **Q-F9** | **Oui.** `enforceMockExamSlotAccess` est retiré du chemin civique : il est remplacé par la règle ci-dessus, et deux verrous sur le même bouton sont exactement le patron qu'on cherche à éviter. |

⚠️ **À surveiller, sans agir maintenant** : un examen complet gratuit et rejouable sans limite peut
cannibaliser l'abonnement. On ne le restreint pas aujourd'hui — la promesse est publique — mais l'usage
réel doit être mesuré avant d'ouvrir le sujet.

---

## 5. Le contenu

| # | Réponse |
|---|---|
| **Q-F27** | **Oui.** Les **11 questions de Laïcité** manquantes (9 → 20) sont produites. C'est le seul contenu que l'audit identifie comme nécessaire, et il débloque la dernière unité où R2 échoue. |
| **Q-F28** | **S2 Accès aux soins.** Le rattachement n'est pas un arbitrage : l'annexe I range explicitement « les numéros d'urgence » sous « L'accès aux soins ». `vs_urgences_secours` y va. |
| **Q-F26** | **Oui.** Les 108 mises en situation hors Principes et Droits restent du **contenu d'entraînement**, simplement exclues des examens blancs. Ni retypage, ni reclassement. |
| **Q-F12** | **Révisée.** Les mises en situation restent sans notion de connaissance, **mais elles deviennent une unité travaillable à part entière** dans les blocs Principes et Droits et devoirs, puisque l'arrêté leur donne un quota au même niveau qu'une notion. Elles peuvent donc clôturer leur propre étape — et uniquement celle-là. |
| **Q-F14** | **Oui.** Les 17 questions de connaissance non taguées sont taguées à la main. Aucun appel LLM. |

---

## 6. Le rangement et les décisions à consigner

| # | Réponse |
|---|---|
| **Q-F17** | **Oui.** Le format de l'examen de thème (20 / 16 / 20 min) rejoint `CivicExamFormat`, et `AttemptService` perd ses 6 constantes privées, **dans la passe P8.1**. |
| **Q-F18 bis** | **A27 s'applique.** Un changement de mention **ne détruit pas** le cycle : on met à jour l'objectif. La mention ne filtrant plus le contenu, le travail fourni reste valide. La recommandation d'historisation de la spec est **révoquée**. ⚠️ Mais le changement reste **sans trace** : consigner la bascule d'objectif sur le cycle, puisque c'est désormais la seule occasion de l'écrire. |
| **Q-F19** | **Oui.** P8 s'ouvre par une décision datée qui **lève D-23** sur le seul point du périmètre et **maintient** « le plan civique reste dérivé ». |
| **Q-F20** | **Sans objet** — Q-F29 tranche : les Focus sont dépubliés, pas laissés en dette. |
| **C-7** | **Révoquer la phrase de V058.** « CSP, CR et NAT sont trois programmes différents » est faux au regard de l'arrêté, et le raisonnement était circulaire : le corpus a été écrit par mention, puis on en a déduit que le programme l'était. **Nommer l'arrêté du 10 octobre 2025 comme source du référentiel**, dans la décision et dans `docs/regles/domaine.md`. |

---

## 7. Livrable de P8.0

1. `docs/decisions/plan-parcours-tcf.md` complété à partir de **D-25** : une décision par arbitrage
   ci-dessus, datée 2026-09-19, avec pour chaque révocation la phrase révoquée citée et son origine
   (D-23, V058, spec civique §3.3, spec civique §5.6).
2. `SPEC_cycle_plan_civique.md` mise en conformité : les 14 notions officielles + 2 unités de mises en
   situation remplacent les « 40 notions » ; §3.1 réécrit (les mises en situation ne sont pas réparties
   sur les 5 thèmes) ; §3.3 freemium réécrit selon le §4 ci-dessus ; §5 vidé de ses questions résolues ;
   l'arrêté cité en source.
3. La **liste des fichiers** que P8.A et P8.2 devront toucher, sans les toucher.
4. Le **plan du contrôle de couverture** (Q-F30) : ce qui sera extrait, comment c'est rattaché, quel
   tableau sort à la fin. Plan seulement, aucune extraction.

---

## 8. Ordre des phases — rappel

**P8.0** (cette passe) → **Q-F30** (contrôle de couverture) → **P8.A** (conformité de l'examen blanc) →
P8.1 → P8.2 → P8.3 → P8.4 → P8.5 → P8.6 → P8.7 → P8.8.

**P8.9** (historique des cycles) reste ⛔ **bloquée** : template non fourni.

> ⛔ **RAPPEL STOP.** Termine après les quatre livrables du §7. N'ouvre ni Q-F30 ni P8.A, même si
> l'arbitrage paraît évident et le travail court.
