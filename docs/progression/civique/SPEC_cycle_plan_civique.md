# SPEC — Moteur de cycle (Plan) — Module CIVIQUE

Statut : **spécification fonctionnelle, mise en conformité le 2026-09-19** (phase P8.0).
Complète `SPEC_cycle_plan.md` (TCF). **Le moteur est le même** : mêmes règles, mêmes écrans, même
grammaire visuelle. Ce document ne décrit que ce qui change.

> 🛑 **Source de vérité du module : l'arrêté du 10 octobre 2025** relatif au programme, aux épreuves
> et aux modalités d'organisation de l'examen civique — JORF n° 0240 du 12 octobre 2025, NOR
> **INTV2527907A**, articles 1 à 3 et **annexe I**.
> **Là où le produit diverge du texte, c'est le produit qui a tort**, y compris quand la divergence
> est ancienne, documentée et testée (**D-25**).

> Les arbitrages qui ont mis ce document en conformité sont consignés verbatim dans
> `docs/decisions/plan-parcours-tcf.md` — **D-25 → D-37**, 2026-09-19 — à partir de
> `docs/audits/AUDIT_cycle_plan_civique_v2.md` et de `docs/audits/REPONSES_AUDIT_civique_v2.md`.
> Chaque règle ci-dessous porte la référence de la décision qui la tient.

> Prérequis : le chantier TCF est livré jusqu'à P7. Le civique est **P8**, et **D-23 est levée**
> sur ce seul point (**D-36**).

---

## 0. Le référentiel officiel — ce que le texte fixe

🛑 **Ni configurable, ni négociable.** Ce n'est pas un réglage produit : c'est la loi, au même titre
que `CivicExamFormat`, `DureeEpreuve` et `TargetProcedure` (**D-25**, **D-29**).

**Où chaque valeur vit — une seule autorité par valeur** (**D-38**) :

| Valeur | Autorité |
|---|---|
| **Le quota par unité** (3, 2, 6, 3, 2, 1, 2, 3, 6, 3, 3, 2, 1, 1, 1, 1) | **La table des 16 unités officielles** (`quota_examen`) |
| 40 questions · seuil 32 · 45 min · partage **28 / 12** | `CivicExamFormat` |
| Les totaux par thématique — **11 / 6 / 11 / 8 / 4** | 🛑 **Nulle part.** Ils se **dérivent** par somme des quotas d'unité. Les déclarer en ferait une 2ᵉ copie, et un jour l'une des deux aurait tort. |

🛑 **Trois garde-fous, parce qu'on met de la loi dans une table** (**D-38**) : elle est **seedée par
migration et n'est pas éditable en admin** ; un `CHECK` ou un test normatif vérifie que la somme des
16 quotas vaut **40** et que les mises en situation totalisent **12** ; un test **verrouille les
16 lignes et leurs quotas**, l'arrêté cité en commentaire. Si ces trois garde-fous ne tiennent pas,
**remonter avant d'écrire la migration** — le quota repassera en code.

⚠️ **Conséquence sur l'ordre des phases** : P8.A **dépend de la table**, donc de P8.2 (cf. §6).

| Thématique | Total | Unités officielles et quotas par examen |
|---|---|---|
| **T1** Principes et valeurs de la République | **11** | Devise et symboles **3** · Laïcité **2** · *Mises en situation* **6** |
| **T2** Système institutionnel et politique | **6** | Démocratie et droit de vote **3** · Organisation de la République **2** · Institutions européennes **1** |
| **T3** Droits et devoirs | **11** | Droits fondamentaux **2** · Obligations et devoirs **3** · *Mises en situation* **6** |
| **T4** Histoire, géographie et culture | **8** | Périodes et personnages **3** · Territoires et géographie **3** · Patrimoine **2** |
| **T5** Vivre dans la société française | **4** | S'installer **1** · Accès aux soins **1** · Travailler **1** · Autorité parentale et système éducatif **1** |
| **Total** | **40** | **28 connaissances + 12 mises en situation** |

Et les quatre faits qui commandent le reste :

1. **40 questions pour TOUTES les mentions**, sur **une seule** annexe I. Il n'existe **ni trois
   programmes, ni trois niveaux de difficulté** (**D-25**, **D-27**).
2. Art. 3 : « Chaque candidat devra répondre à un **nombre équivalent de questions par thématique et
   notion**. »
3. **Durée 45 min · seuil 80 %** (32 / 40).
4. Art. 3, dernier alinéa : « Les questions de connaissances sont **rendues publiques** sur le site
   internet du ministère chargé des naturalisations. » ⚠️ Les **mises en situation ne sont pas
   publiées** — leur production reste entièrement à la charge de SejourFR.

---

## 1. Correspondance des objets

| TCF | Civique | Détail |
|---|---|---|
| Épreuve (CO, CE, EE, EO) | **Thématique** (T1→T5) | Les 5 thématiques officielles. C'est l'unité de **bloc** (**D-32**, FK `theme_id`). |
| `Skill` (compétence) | **Unité officielle** de l'annexe I | 🛑 **16 unités** : les **14 notions** de connaissance **+ 2 unités « Mises en situation »** (T1 et T3 seulement). C'est l'unité **travaillable** du cycle (**D-26**). |
| — | **Notion civique** (`civic_notions`, 46 actives) | ⚠️ **Ce n'est PAS l'unité du cycle.** C'est la granularité du **plan dérivé** — choisir *quoi* faire travailler. Elle se rattache à son unité officielle par **FK** (**D-26**). |
| Question → `Skill` | `questions.civic_notion_id` → notion interne → unité officielle | Liaison **1..1 déjà en place**, tagée à **97,9 %** des connaissances. |
| `EXAM_BLOC` (examen d'épreuve) | **Examen blanc du thème** | Format **SejourFR** : 20 questions, seuil 16, 20 min. **Pas un format officiel** (**D-31**). |
| `ExamComplet` (TCF complet) | **Examen blanc global** | 40 questions, seuil 32, 45 min. Format **officiel**, figé dans le code (**D-29**). |
| Niveau CECRL par épreuve | **Score par thème** (%) | Pas de niveau, pas de palier. L'objectif est le seuil de l'examen. |
| `journey.target_level` (CECRL) | `journey.target_procedure` (**mention**) | La mention est l'**objectif** d'un cycle — la démarche visée et le seuil. 🛑 **Jamais un pool** (**D-27**, **D-32**). |
| `entry_level` / `exit_level` | **`entry_score` / `exit_score`** | Colonnes neuves. 🛑 Un score n'est pas un niveau : aucune réinterprétation des colonnes CECRL (**D-32**). |
| Diagnostic rapide (écrit IA) | **Diagnostic civique** | Existe déjà (`CivicDiagnosticSession`, tunnel invité). **Aucun coût LLM.** 🛑 **Préservé tel quel**, configuration comprise (**D-29**). |

### 🛑 Les mises en situation sont une unité, pas un type à part

L'arrêté place « Mises en situation » **au même niveau qu'une notion**, avec son propre quota, dans
**deux** thématiques : T1 Principes (6) et T3 Droits et devoirs (6). Elles sont donc une **unité
travaillable à part entière** dans ces deux blocs, et **clôturent leur propre étape** — uniquement
celle-là. Elles ne portent **aucune** notion de connaissance (**D-26**, **D-35**).

---

## 2. Ce qui ne change pas

Reprendre **à l'identique**, sans réinterprétation. 🛑 Et depuis **D-26**, c'est vrai **sans écart** :
le contenu porte R2 au grain officiel, il n'y a plus rien à réinventer.

- **Amorces de cycle** (§2 de la spec TCF) : diagnostic fait → bloc(s) peuplé(s) + les autres thèmes
  en « Évaluer mon niveau » ; examen de thème passé sans diagnostic → ce thème peuplé + les autres à
  évaluer ; rien de fait → les 5 blocs en « Évaluer mon niveau ».
- **R1** : un examen de thème passé hors du plan valide l'étape **si et seulement si** l'étape était
  débloquée (aucune unité restante dans le bloc). L'examen global valide de la même façon chaque
  thème dont le bloc était débloqué. ✅ **Faisable** : le thème d'un examen est **déjà persisté**
  (`attempts.lot_theme_id`).
- **R2** : une unité du cycle passe `REUSSI` après **2 séries réussies** (≥ 0,80) ou **4 séries
  terminées**. ✅ **Applicable au grain officiel** : **13 des 14 notions** portent ≥ 20 questions.
  Une seule échoue — **Laïcité, 9** —, et **11 questions** la referment (**D-35**).
- **R3** : l'entraînement libre n'alimente **jamais** le cycle en attente. Seuls les examens le font.
- **Déblocage** : toute unité est cliquable dans n'importe quel ordre ; seul l'examen du thème est
  verrouillé tant qu'une unité du bloc reste ouverte. 🛑 **D-15 s'applique mot pour mot.**
- **Fin de cycle** : « Passer l'examen blanc global » crée un cycle de mesure (5 blocs, un examen
  chacun, tous débloqués, passables thème par thème) ; « Actualiser mon plan » promeut le cycle en
  attente.
- **Cycle en attente** invisible, **historisation**, **score de sortie persisté**.
- `module` sur le cycle, un seul `EN_COURS` et un seul `EN_ATTENTE` par `(user, module)` — les index
  **partiels** de V067 sont déjà sur `(user_id, module)`, **rien à migrer**.
- **Le cycle se SUPERPOSE au plan dérivé**, il ne le remplace pas (**D-12** transposé, **D-36**). Le
  Leitner reste : il produit l'état de maîtrise servi, l'échéance de revue, les 5 crans de parcours,
  l'ordre servi du plan, le **tagging rétroactif** et l'**absence de job quotidien**.

---

## 3. Ce qui change vraiment

### 3.1 Les mises en situation — deux unités de deux blocs

🛑 **L'arrêté les place 6 en T1 Principes et 6 en T3 Droits et devoirs. Zéro dans les trois autres
thématiques.**

*⚠️ Cette section a été réécrite le 2026-09-19. Le premier jet affirmait « 12 des 40 questions sont
des mises en situation, **réparties sur les thèmes** » et proposait deux options — un type présent
dans **chaque** bloc, ou un **6ᵉ bloc** transversal. **Les deux étaient fausses** : il n'y en a pas
dans 3 blocs sur 5, et elles appartiennent à **deux** blocs nommés. Phrase révoquée par **D-35**.*

**La règle** :

- Les mises en situation sont une **unité travaillable** dans T1 et T3, avec leur quota officiel de 6
  chacune (**D-26**).
- Elles restent **sans notion de connaissance**, et n'en recevront pas :
  `CivicPlanProperties.seuilTagging` les exclut déjà de son dénominateur, et c'est voulu.
- Elles clôturent **leur propre étape**, dans leur bloc, et **aucune autre** (**D-35**).
- 🛑 **Un examen blanc ne peut en tirer que dans T1 et T3** (**D-29**, axe 3). Un examen de **thème**
  suit la même règle : aucune mise en situation dans T2, T4, T5 (**D-31**, Q-F21).

**L'état du stock** : 176 actives, dont **68 dans le périmètre officiel** (T1 21, T3 47) et
**108 hors périmètre** (T2 31, T4 30, T5 47). Les 108 **restent du contenu d'entraînement**,
simplement **exclues des examens blancs** — ni retypage, ni reclassement (**D-35**, Q-F26).

### 3.2 Pas d'analyse IA

Aucune production écrite ou orale, donc aucun correcteur, aucun quota d'analyse. **Un QCM ne coûte
aucun appel LLM** — et c'est ce qui commande le freemium du §3.3.

### 3.3 Freemium civique — **pas de ledger**

*⚠️ Réécrit le 2026-09-19 par **D-33**. Le premier jet prévoyait « 1 examen blanc de thème, une fois
à vie, au choix du candidat », consommé « à l'examen terminé et corrigé », sur le « même ledger
`free_entitlement_usage` ». **Révoqué** : il transposait au QCM une règle écrite pour les
productions IA. Le TCF, lui, laisse ses examens QCM CO/CE sous `enforceMockExamSlotAccess`.*

| Élément | Régime |
|---|---|
| Diagnostic civique | ✅ **Gratuit** |
| `civique-decouverte` (40 Q, seuil 32) | ✅ **Gratuit**, comme aujourd'hui — promesse déjà publiée et affichée, elle est tenue. ⚠️ **À rendre conforme en P8.A** comme les autres examens. |
| Examens de thème | ❌ **Premium** |
| Autres examens blancs globaux | ❌ **Premium** |
| Travailler une unité depuis le Plan | ❌ **Premium** |

- 🛑 **Aucun code de gratuité civique n'est créé.** `chk_free_entitlement_code` n'est pas touché et
  `FreeExamEntitlementService` reste le service des deux gratuités **de production**.
- 🛑 **`enforceMockExamSlotAccess` est retiré du chemin civique** : il est remplacé par la règle
  ci-dessus. **Deux verrous sur le même bouton** sont exactement le patron qui a produit les 4
  implémentations ad hoc de « première fois gratuite » (**D-33**).
- ✅ Le Plan civique est **déjà** conforme à **D-18** : `CivicPlanService.demarrerSerie` oppose un
  **403** sans `hasCivique`. Rien à révoquer.
- L'abonnement est déjà à granularité module (`NONE < CIVIQUE < INTEGRAL`) : **rien à créer côté
  billing**.
- ⚠️ **À surveiller sans agir** : un examen complet gratuit et rejouable sans limite peut
  cannibaliser l'abonnement. On ne le restreint pas — la promesse est publique — mais l'usage réel
  doit être **mesuré** avant d'ouvrir le sujet.

### 3.4 La mention ne filtre plus le contenu

🛑 **Le filtre `q.difficulty = :mention` est retiré de la lecture** (**D-27**). La colonne reste en
base comme **métadonnée éditoriale** : elle dit de quelle campagne vient une question, et l'admin
continue de la voir. Aucune migration de données, aucun `DROP` — le retour arrière est **un
changement de variable de code**.

**Pourquoi** : l'arrêté prescrit un programme et une épreuve **pour toutes les mentions**. Et la
mesure le confirme — sur **976** questions actives, **15** (1,5 %) citent une démarche dans leur
énoncé et **aucune n'est exclusive d'une démarche**. Le clivage était dans l'**étiquetage**, pas
dans le contenu.

⚠️ **Le filtre n'était déjà pas une règle du module** : `LotService` passe `null` en `difficulty` —
les lots d'entraînement civiques **ignorent la mention depuis toujours**.

**Supprimés avec le filtre**, et pas laissés vides (« refonte = suppression immédiate de l'ancien ») :
`CivicDotation` (enum entier + son test) et `questions-min-par-notion: 5`. Sans filtre, **0 couple**
tombe sous le seuil et `NON_APPLICABLE` devient **impossible** : une règle morte qui donne l'illusion
d'un garde-fou est pire que pas de garde-fou (**D-27**).

**Conservés** : `questions-par-serie: 10` (tenable sur les 16 unités, minimum 9) et
`seuil-tagging: 0.80` (franchi partout, 97–98,6 % ; garde-fou du plan **dérivé**, dont le cycle ne
dépend pas).

### 3.5 🛑 L'examen blanc doit simuler l'examen réel — chantier séparé et **prioritaire**

**P8.A passe AVANT le cycle** (**D-29**). Aujourd'hui, **0 examen sur 33** déjà passés est conforme :
le produit tire **8/8/8/8/8** au lieu de 11/6/11/8/4, sort **7,7 mises en situation au lieu de 12**,
et **58 %** de celles tirées l'étaient dans une thématique où l'examen réel n'en pose aucune.

Le tirage devient une **contrainte dure** sur **trois axes** : la répartition par thématique, le
quota par unité officielle, et les 12 mises en situation placées **uniquement** en T1 (6) et T3 (6).

Détail des cinq exigences de la phase : **D-29**. **Aucune question n'est à produire** — un examen
parfaitement conforme est tirable du stock actuel, à condition que le filtre de mention soit retiré
(§3.4).

Les **11 templates « Focus » mono-thème à 40 questions** sont **dépubliés** : structurellement non
conformes, ils ne peuvent pas s'appeler « examen blanc », et ce qu'ils offraient — travailler un
thème — est exactement ce que le cycle fournit (**D-30**).

### 3.6 Changer de mention ne détruit pas le cycle

**A27 s'applique tel quel** : on met à jour l'**objectif**, on ne détruit pas le cycle. La mention ne
filtrant plus le contenu, **le travail fourni reste valide** (**D-34**).

*⚠️ Révoque la recommandation d'historisation du premier jet (§5.6), qui reposait sur « changer de
mention, c'est changer de programme » — la conclusion de V058, révoquée par **D-25**.*

⚠️ **Mais le changement reste sans trace** : `users.target_procedure` est **écrasé**, sans table
d'audit. **Consigner la bascule d'objectif sur le cycle** — c'est désormais la seule occasion de
l'écrire.

---

## 4. Écrans — strictement identiques au TCF

### Accueil, deux sections
1. **À faire maintenant** : une carte, un bouton rouge.
2. **Où vous en êtes** : les 5 thématiques, chacune avec son score et son état (*acquis · à
   consolider · à travailler · pas encore évalué*), plus le rappel du dernier examen global
   (« 29 / 40, il manque 3 points »). L'échelle A1→B2 du TCF est remplacée par la progression vers le
   seuil.

### Plan, deux sections + un lien
1. **À faire maintenant**, identique à l'Accueil.
2. **Cycle en cours** : 5 blocs de thématique, le bloc courant déplié, les autres repliés avec leur
   compteur. L'examen du thème est la **dernière étape** de chaque bloc.
3. **Voir ma progression** → page historique (⛔ **en attente du template** fourni par le
   propriétaire).

Le toggle TCF IRN / Examen civique pilote les deux écrans ; chaque module a son cycle, indépendant.
Il vit dans l'URL (`?module=`) et nulle part ailleurs — **une seule autorité de sélection**.

**Vocabulaire** : « **thème** » et le **nom complet de la thématique** s'affichent partout où le TCF
affiche l'épreuve — carte d'action, en-tête de bloc, ligne d'étape, écran de résultat (**D-21**
transposé). Le vocabulaire interne (`lot`, `step`, `journey`, `notion`) n'apparaît **jamais** à
l'écran ; à l'écran on dit le **libellé officiel de l'unité**, ou rien.

**Les kits** : les deux fronts assemblent les mêmes primitives, miroirs brique pour brique
(`web_sejoufr/app/_components/sejour/SejourKit.tsx` ⇄
`mobile_sejourfr/lib/core/widgets/sejour/sejour_kit.dart`). ✅ **Les 4 primitives de cycle existent
déjà des deux côtés** (`CycleProgress`/`SfCycleProgress`, `BlocAccordion`/`SfBlocAccordion`,
`ExamStepBox`/`SfExamStepBox`, `NextStepCard`/`SfNextStepCard`). ⚠️ **Une seule brique manque** :
`BlocAccordion` attend une **initiale d'épreuve** (CO/CE/EE/EO) ; une thématique n'en a pas. À
étendre **dans les deux kits dans la même passe**.

⚠️ **Aucun nouveau test sur les fronts** (invariant du `CLAUDE.md` racine). Vérification :
`npx tsc --noEmit` · `npm run build` · `flutter analyze`.

---

## 5. Ce qui reste ouvert

Les six points de vérification du premier jet sont **tous tranchés** (**D-25 → D-40**). Ce qui reste
n'est pas une question de conception, mais une mesure et un template :

1. **Le contrôle de couverture (Q-F30, D-28, D-40)** — à faire **avant P8.A**. Le ministère publie
   **trois listes de questions distinctes par mention** (CSP ≈ 212, CR ≈ 205, NAT en PDF). Le
   **programme** est unique ; la **banque publiée** ne l'est pas. Une seule question à trancher,
   chiffres à l'appui : les trois listes se **recouvrent-elles largement** ?
   - **Recouvrement large** ⇒ le retrait du filtre (§3.4) est confirmé **définitivement**, y compris
     pour la composition des examens blancs.
   - **Divergence réelle** ⇒ le filtre revient **pour la seule composition de l'examen blanc**,
     jamais pour l'entraînement ni pour le cycle, et le rapport dit quelles questions écrire par
     mention.

   🛑 **Dans les deux cas, l'entraînement et le cycle restent sans filtre.** R2 en dépend, et rien
   dans l'arrêté ne justifie de restreindre ce qu'un candidat peut **travailler**.

   🛑 **Le recouvrement se mesure d'abord, par comparaison directe des énoncés, sans rattacher quoi
   que ce soit aux 16 unités** (**D-40**). La couverture du stock par unité vient **après, et
   seulement si elle sert encore** : le rattachement fin est le poste coûteux, il ne se paie pas pour
   répondre à une question qui n'en a pas besoin.
   ⛔ **Aucun import** — les énoncés publics n'ont pas leurs réponses. ⛔ **Aucun appel LLM** : si la
   comparaison directe échoue, on **remonte le problème avec un chiffre**.

2. **Le template de l'écran « historique des cycles »** — ⛔ **bloqué**, à fournir par le
   propriétaire. Ne rien concevoir. Travail autorisé en amont, et seulement après les écrans :
   étendre `GET /api/me/plan/journey/history` au module civique. Le contrat est arrêté et les deux
   fronts codent déjà dessus.

3. **Les 11 questions de « Laïcité »** (9 → 20) — **P8.8**. Seul contenu identifié comme nécessaire,
   et il referme la dernière unité où R2 échoue (**D-35**).

---

## 6. Ordre des phases

**P8.0** (arbitrages, fait) → **Q-F30** (contrôle de couverture) → **P8.1** (rangement : le format de
thème rejoint `CivicExamFormat`, les documents périmés) → **P8.2** (référentiel officiel : table des
16 unités, retrait du filtre) → **P8.A** (conformité de l'examen blanc) → **P8.3** (schéma du cycle)
→ **P8.4** (moteur) → **P8.5** (freemium) → **P8.6** (kits) → **P8.7** (écrans) → **P8.8** (les
11 questions de Laïcité). **P8.9** (historique des cycles) : ⛔ **bloquée**.

⚠️ **P8.A a glissé derrière P8.2**, et ce n'est pas un recul de priorité. **D-38** met le quota par
unité **dans la table** : P8.A ne peut plus s'écrire avant que la table existe. La conformité de
l'examen blanc reste le **premier chantier de code** ; elle a désormais une dépendance, et P8.1 comme
P8.2 sont les deux passes qui la préparent. **Point remonté au propriétaire**, pas arbitré seul.

Périmètre de fichiers de **P8.A** et de **P8.2** : annexe P8.0 de
`docs/audits/AUDIT_cycle_plan_civique_v2.md`.
