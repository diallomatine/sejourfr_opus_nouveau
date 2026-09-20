# Reprise — lancée 3, les écrans du cycle civique (P8.6 → P8.9)

> **C'est un ÉTAT, pas un plan.** Chaque point dit ce qui est **déjà en place** et ce qui **manque**,
> avec le fichier et la ligne. La passe suivante doit démarrer sur les écrans, pas sur une relecture.
>
> Écrit le **2026-09-20**, contexte frais, à la fin de la lancée 2 (P8.4 + P8.2b + P8.5).
> ⚠️ Les numéros de ligne datent de ce jour — vérifier par `grep`, pas par `sed -n`.

## Où en est le chantier

| Phase | État |
|---|---|
| P8.0 → P8.3, P8.A, **P8.2b** | ✅ livrées |
| **P8.4** (moteur) · **P8.5** (freemium) | ✅ **livrées**, preuve : `ParcoursCiviqueDeBoutEnBoutIT` |
| **P8.6** (kits) · **P8.7** (écrans) | ✅ **livrées** (2026-09-20), décisions **A84 → A90** |
| P8.8 (les 28 questions) | 🟡 **relecture rendue** — dossier complet, ⛔ **arrêt avant migration** : la forme est montrée, pas écrite |
| **P8.9** (historique des cycles) | ✅ **livrée** (2026-09-20) — le blocage est **levé** : l'écran TCF fait référence, transposé brique pour brique. Décisions **A91 → A94** |

**Autorité des règles** : `docs/decisions/plan-parcours-tcf.md` — **D-25 → D-53**, les règles
générales **D-48** (`PROGRAMME ≠ CORPUS`) et **D-50** (les écrans), et les dettes **DETTE-M1**,
**DETTE-P1**, **DETTE-A1**, **DETTE-C1** (fermée).
**Mesure des écarts d'écran** : `docs/audits/AUDIT_plan_civique_ecran_et_moteur.md` (clos).
**Décisions prises seul** : `docs/decisions-autonomes-parcours-tcf.md`, **A47 → A83**.

---

## 🛑 Les quatre arbitrages de D-50, à appliquer sans les rouvrir

1. **La bande objectif** dit « **Objectif : naturalisation · seuil 32/40** ». ⛔ **Jamais un score
   d'entrée** : `entry_score` existe en base et ne s'affiche pas là — il se lirait comme un niveau
   acquis alors que c'est un résultat d'examen blanc.
2. **« À faire maintenant » bascule sur le cycle** (`journey.current`), et quitte le plan dérivé.
   ⚠️ **Effet visible assumé** : la carte peut nommer autre chose qu'aujourd'hui pour le même
   candidat. C'est le prix d'une autorité unique, payé une fois.
3. **« À revoir bientôt » RESTE** — seul affichage du Leitner, que le cycle ne porte pas (D-49).
   **Partent** : « Vos priorités », « Déjà travaillé et validé », « Progression détectée ».
4. **Le grain affiché est l'unité officielle** (D-48) : 16 au lieu de 46. 🛑 **La formulation est
   SERVIE** — « 5 unités à travailler » arrive du serveur, comme le bloc et le label.

---

## Ce qui est DÉJÀ en place, et sur quoi s'appuyer

| Acquis | Où |
|---|---|
| Le **cycle civique complet** : amorce, lots, unités, examens, R1, R2, fin de cycle, historisation | `JourneyService`, `JourneyCycleService` |
| Le **bloc servi** `{kind, code, label}` et l'**objectif servi** `{kind, code, label}` | `JourneyBlocRefDto`, `JourneyObjectifRefDto` ⇄ les 2 miroirs front |
| `JourneyBlocResolver` **sans enum** : il reçoit son axe | `JourneyReadService.axe(module)` |
| Le verrou **D-15** par code de bloc | `JourneyReadService.blocsAvecTravailOuvert` |
| Les **4 primitives de cycle**, des deux côtés | `CycleProgress` · `BlocAccordion` · `ExamStepBox` · `NextStepCard` |
| Le freemium civique **opposable** | `AttemptService.enforceAccesExamenCivique` (D-33) |
| `prioritesVisibles` / `aRevoirVisibles` — le plafond est **dans le nom** | `CivicPlanDto` ⇄ les 2 miroirs |

---

## Le reste, dans l'ordre

### 1. P8.6 — la brique de kit qui manque

**En place** : `BlocAccordion` / `SfBlocAccordion`, des deux côtés.
**Manque** : un en-tête de bloc **sans initiale**. ⟦CODE⟧ `journeyBlocMark(bloc)` rend `""` pour une
thématique (**A49**) — « Principes et valeurs de la République » ne se réduit pas à deux lettres, et
en inventer une serait un libellé **fabriqué par le front**.

🛑 **Dans les DEUX kits, même passe.** C'est ce qui garantit que les deux fronts montrent le même
écran.

### 2. P8.7 — les contrats servis (⚠️ avant les vues)

| # | Ce qui manque | Pourquoi maintenant |
|---|---|---|
| a | `GET /api/me/plan/journey?module=` | ⟦CODE⟧ le module est **en dur** à **un seul endroit** : `JourneyController.get()`, avec le commentaire qui le dit. Idem `refresh` et `measurement-cycle`. Une ligne chacun. |
| b | La **phrase des unités**, servie | D-50 §4 : « 5 unités à travailler » vient du serveur. Aucun front ne compte des unités. |
| c | `JourneyStepDto` : l'**unité travaillable** servie | ⟦CODE⟧ il porte 6 champs TCF (`section`, `taskCode`, `skillCode`, `skillTitle`, `assessment`, `exercise`) ; une étape civique n'a aucun `Skill`. Même geste que le bloc servi. |
| d | `JourneyBlocDto.etapesRestantes` | ✅ **déjà renommé** — il disait « compétences ». |

⚠️ **`mesureDe` rend `null` pour un examen de thème** (`DETTE-A1`, annoté sur place) : l'action de
l'examen de thème se sert **ici**, avec les écrans. `CivicExamFormat` en porte déjà le format
(20 questions, 20 min, seuil 16).

### 3. P8.7 — les deux vues

**En place** : `PlanCycleSection` (web **et** mobile) ne lit **que des faits servis** depuis D-47.
**Manque** : qu'elle devienne **commune** aux deux modules (D-50, décision technique validée).
⚠️ Deux dépendances TCF à isoler avant : `fullExamsHistoryProvider` et `plan_now_card`.

**Et la suppression** : les trois sections que le TCF n'a plus (§ arbitrage 3 ci-dessus) partent des
deux vues civiques **dans la même passe** — « refonte = suppression immédiate de l'ancien ».

### 3 bis. 🛑 CHANTIER — `DETTE-P1` : le seuil des trois occurrences est **atteint**

**Inscrit ici par le propriétaire (2026-09-20)** : « une troisième occurrence transforme la dette en
chantier. Elle est atteinte. Ne l'ouvre pas maintenant — **les écrans sont justement la passe où
elle se traitera le mieux**. »

**Les trois occurrences, toutes trouvées en mesurant, aucune par relecture :**

| # | Le fait tenu des deux côtés | Symptôme | État |
|---|---|---|---|
| 1 | La **durée** de l'examen civique, écrite en dur dans chaque front | web : `?? 2400` = **40 min** là où l'arrêté en fixe **45** | ✅ corrigé (`c2304fef`) — miroirs gelés, chiffres lus chez `CivicExamFormat` |
| 2 | La **carte de contexte** du Plan civique | mobile « 4 thèmes / 17 notions », web « 17 à consolider / 3 à revoir » — **même carte, faits différents** | ✅ **fermé** (P8.7) — la carte est **supprimée** des deux côtés, la bande objectif la remplace, et ses trois helpers (`civicPlanEngineLine`, `civicPlanThemesPill`, `civicPlanCiblesPill`) partent avec elle |
| 3 | La **promesse de gratuité** des examens de thème | « examen 1 gratuit » des deux côtés, **403 au clic** | ✅ corrigé (`9652315a`) |

🛑 **Ce que le 3ᵉ cas ajoute** : le verrou **existait** côté serveur — il n'était simplement pas
**servi**. Un front ne peut pas lire ce qu'on ne lui dit pas. Le chantier n'est donc pas « mieux
surveiller les miroirs », c'est **servir le fait** plutôt que le laisser se réécrire à la main.

**Ce que la passe des écrans en a fait — les trois occurrences sont closes :**
- la **phrase des unités est servie** (`JourneyBlocMeta` → `bloc.meta`, D-50 §4) : aucun front ne
  compte d'unité ;
- la **carte de contexte est supprimée**, donc les deux faits divergents n'existent plus ;
- un libellé écrit en dur dans un écran a été **remonté aux mots du parcours** dès sa 2ᵉ occurrence
  (`JOURNEY_LOCKED_BADGE` ⇄ `kJourneyLockedBadge`, **A85**) — c'est le geste que le chantier
  demandait : **servir le fait**, ou à défaut le **déclarer une fois**.

🛑 **Ce qui RESTE ouvert, et se suit désormais comme une divergence nommée** : l'écran **gratuit**
civique n'est pas le même des deux côtés (trois helpers vivent côté Dart seulement, **A84**). Ce n'est
plus une dette silencieuse — c'est écrit en tête des deux fichiers de libellés. Le précédent d'un filet
reste `scripts/verifier-contrat-front-progression.mjs`, écrit pour **un** contrat et jamais étendu.

⛔ **Aucun nouveau test front** : la réponse est un fait **servi** ou un script hors test, jamais un
`*.test.ts`.

### 4. P8.8 — les 28 questions

⛔ ~~ARRÊT ÉDITORIAL avant écriture.~~ **Relecture rendue le 2026-09-20.** Tout vit dans un dossier
unique : `docs/progression/civique/P8.8-extraction.md` — partie A la matière brute, partie B la
relecture du propriétaire, partie C les vérifications et **la forme des deux migrations**.

**Ce qui est tranché** : les **12** questions de Laïcité (le doublon désactivé, 8 + 12 = **20**, le
seuil de R2 atteint exactement), **6** rattachements sur 14 (option 3 — on ne rattache que ce qui
redescend proprement jusqu'à une notion), **4** désactivations (3 hors programme + le doublon), et
`difficulty = 'CR'` sur les douze avec une ligne d'en-tête disant que **la valeur est inerte depuis
D-42**.

**Ce qui reste ouvert, et consigné comme signal** : les **8** questions sans notion interne — cinq
manques de la taxonomie des 46, qui a été reconstruite **depuis le corpus** (`SIGNAL-T1`).

⛔ **ARRÊT AVANT LA MIGRATION**, comme pour V069, V070 et V071 : la forme est en partie C.4, rien
n'est écrit.

⚠️ **`V299` sera le dernier slot de la plage `200_civique`** (`DETTE-F1`, signalée avant d'écrire).

### 5. P8.9 — l'historique des cycles ✅

⛔ ~~BLOQUÉE : template non fourni.~~ **Blocage LEVÉ le 2026-09-20** par le propriétaire : *« Le
gabarit n'est plus à fournir : l'écran existe côté TCF et il fait référence. »*

**Ce qui a été livré** — le **même** écran, scopé au parcours, jamais un second :

| Brique | TCF | CIVIQUE |
|---|---|---|
| Point d'entrée | Plan → « Aller plus loin » → **Ma progression** | **identique**, ajouté au Plan civique |
| Route | `/plan/progression` | **la même**, `?module=CIVIQUE` (web) · `parcoursCiviqueProvider` (mobile) |
| Le bloc | une **épreuve** | une **thématique** |
| L'unité travaillée | une **compétence** | une **unité officielle** |
| La clôture de bloc | examen d'épreuve | **examen de thème** (20 q, seuil 16) |
| La mesure du cycle | palier **CECRL** (`entry/exitLevel`) | **score sur 40** (`entry/exitScore`), rapporté au seuil de **32** |

🛑 **C'est ICI, et seulement ici, que `entry_score` et `exit_score` s'affichent.** D-50 §1 les
interdit sur la **bande objectif** du Plan, où un résultat d'examen blanc se lirait comme un niveau
acquis ; dans une **archive datée**, un résultat d'examen est exactement à sa place.

---

## Les pièges déjà payés, à ne pas repayer

0. 🛑 **`getExamType()` hors d'un chemin TCF** = panne en attente (`DETTE-A1`). Toute lecture d'axe
   passe par **`blocCode()`**, ou dit en une ligne qu'elle est TCF. **Un 3ᵉ site non annoté ouvre le
   chantier.**
1. 🛑 **Un test ne dépend jamais d'un choix du moteur qu'il ne fixe pas lui-même** — un classement,
   un premier élément, une liste plafonnée. **Trois occurrences en deux jours.** Règle écrite :
   `docs/plan-tests-backend.md`.
2. **Une migration ne s'applique jamais à la main** sur la base de dev : `verify` reste vert, seul un
   **boot** le voit.
3. **Postgres traite les NULL comme distincts** : tout index unique sur une colonne devenue nullable
   veut son **jumeau partiel**.
4. **Une violation de contrainte par méthode de test** (`25P02` aborte la transaction).
5. **`porterAuParcours` avale ses exceptions** (`DETTE-M1`) : vérifier **en base**, pas au vert.
6. **Les tests du plan civique supposent un corpus non tagué** : `remettreLeCorpusANonTague()`.
7. **Aucune fixture ne construit un cycle civique** — ⚠️ **obsolète** : `AmorceCiviqueIT` et
   `ParcoursCiviqueDeBoutEnBoutIT` en construisent maintenant. S'en inspirer plutôt que d'en écrire
   une troisième.
8. 🛑 **Une dépendance d'action dans `CivicPlanService` referme une boucle Spring** (A64). Le
   **seuil** est écrit dans D-52 : une seconde dépendance d'action ⇒ on extrait `CivicSerieService`.

---

## Ce qui NE doit PAS bouger

- 🛑 `service/plancivique/` reste **dérivé** (D-36) — le cycle **se superpose**.
- 🛑 `TcfDomainProfileDto.ORDRE` reste l'autorité **TCF** (D-9, D-20).
- 🛑 `CivicDiagnosticComposer` et `sejourfr.civic-diagnostic` — **D-29 exigence 5**.
- 🛑 `SkillMasteryEngine` **lève** sur une source civique (A50), et c'est voulu.
- 🛑 **Le TCF n'est pas touché.** Toute généralisation est **additive** de son côté.
- 🛑 **Aucun nouveau test sur les fronts.** `npx tsc --noEmit` · `npm run build` · `flutter analyze`.

---

## Le livrable de preuve attendu à la fin de la lancée 3

Les **deux écrans montrés au propriétaire** — ils se jugent à l'œil, c'est pourquoi cette lancée est
séparée. Plus la liste des décisions prises seul, à la suite de **A83**.

✅ **Livré le 2026-09-20.** Les décisions sont **A84 → A90**
(`docs/decisions-autonomes-parcours-tcf.md`). Ce que porte le plan civique **abonné**, des deux côtés,
dans cet ordre : en-tête → **bande objectif** (« Objectif : naturalisation · Seuil 32/40 ») →
**« À faire maintenant »** lu sur `journey.current` → **le cycle en blocs**
(`PlanCycleSection`, module en paramètre) → **« À revoir bientôt »**. L'écran **gratuit** n'a pas
bougé (**A89**).

**Vérifié** : `./mvnw verify` ✅ · `npx tsc --noEmit` + `npm run build` + `npm test` (270) ✅ ·
`flutter analyze` (0) + `flutter test` (296) ✅.
