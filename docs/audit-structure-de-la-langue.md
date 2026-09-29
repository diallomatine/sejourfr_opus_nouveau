# Audit — « Structure de la langue » n'est pas une cinquième épreuve du TCF IRN

**Rapport d'audit. Rien n'est modifié.** Liste exhaustive des surfaces, pour
arbitrage avant la refonte de l'écran Réviser.

**Le fait** : le TCF IRN comporte **4 épreuves officielles — CO, CE, EE, EO**.
« Structure de la langue » est un module d'**entraînement complémentaire**
SejourFR, utile (la grammaire se paie sur CE, EE et EO) mais **hors examen**.

---

## 0. Ce qui est DÉJÀ correct — à ne pas casser

| Surface | État |
|---|---|
| `EpreuveType.java:9` | ✅ « TCF_STRUCTURE : structure de la langue (entrainement **bonus, hors examen blanc IRN**) ». |
| Examen blanc complet | ✅ `AttemptCompositionService.java:196` : « **Pas de STRUCTURE** » dans `TCF_COMPLET`. |
| Plan / progression | ✅ `PlanDomainAssessmentResolver.java:198-201` : `TCF_STRUCTURE` rend `null` — « epreuve **hors des quatre du profil TCF IRN** […] on n'invente pas une mesure pour elles ». |
| Diagnostic | ✅ partout « **Diagnostic TCF — 4 épreuves** », nommage imposé et respecté. |
| Écran de détail **mobile** | ✅ `tcf_qcm_detail_screen.dart:59-74` : eyebrow « **Entraînement complémentaire** », description « Module **hors TCF IRN officiel** », + `QcmNoticeBanner` « Module non évalué dans le TCF IRN officiel ». C'est **le bon modèle**. |

🛑 **Le backend ne présente nulle part SL comme une épreuve officielle.** Tout ce
qui suit est une affaire d'**affichage**.

---

## 1. 🔴 L'offre payante annonce « Les 5 épreuves du TCF IRN »

| Fichier | Ligne |
|---|---|
| `web_sejoufr/app/(app)/profil/abonnement/page.tsx` | **136** |
| `mobile_sejourfr/lib/screens/profile/manage_subscription_screen.dart` | **144** |

C'est la ligne de tête du Pass Intégral. Elle **contredit la page de vente du
même produit** : `web_sejoufr/app/_components/reussir/ReussirView.tsx:1736` dit
« Les **4** épreuves du TCF IRN », comme les 5 autres mentions de ReussirView
(`:1026`, `:1093`, `:1414`, `:1417`) et `TargetPathBanner.tsx:10,14,18`.

Une ligne de fonctionnalité d'un produit payant qui annonce une épreuve
d'examen qui n'existe pas est le point le plus exposé de l'audit.

⚠️ La ligne suivante — « Compréhension orale & écrite, **structure** » — dit
déjà la vérité. C'est bien « 5 épreuves » qui est faux, pas le contenu vendu.

---

## 2. 🟠 L'écran **Réviser** range SL parmi les épreuves, et le titre compte 5

L'écran que nous allons refondre est celui qui l'affirme le plus visiblement.

| Fichier | Ligne | Contenu |
|---|---|---|
| `web_sejoufr/app/_components/reviser/ReviserScreen.tsx` | **123-125** | « Ordre canonique des **cinq épreuves TCF** » + `TCF_ORDER = [CO, CE, **STRUCTURE**, EE, EO]` — SL **intercalée au milieu des officielles** |
| `mobile_sejourfr/lib/core/utils/dashboard_targets.dart` | **40-48** | miroir Dart : « Ordre canonique des **5 épreuves TCF** », `tcfCategoryOrder` identique |
| `web_sejoufr/lib/reviser.ts` | **45-48** | `reviserSectionTitle()` → **« Les 5 épreuves »** (le compte vient de la liste) |
| `mobile_sejourfr/lib/screens/reviser/reviser_labels.dart` | **37-39** | miroir Dart, même comportement |
| `web_sejoufr/app/_components/reviser/ReviserScreen.tsx` | **109, 134, 317** | icône, route et libellé de repli de SL, au même rang que les 4 autres |

**Le titre « Les 5 épreuves » n'est pas écrit en dur** — il compte la liste. Il
suffit donc de **sortir SL de la liste** pour qu'il redevienne « Les 4 épreuves »
sans toucher aux libellés.

---

## 3. 🟡 Les autres listes qui mettent SL au même rang que CO / CE

Aucune ne dit « épreuve officielle », mais toutes l'affichent comme un pair.

| Fichier | Ligne | Nature |
|---|---|---|
| `web_sejoufr/app/entrainement/tcf/[code]/page.tsx` | 21-38 | `TCF_QCM` : co / ce / **structure**, même carte, **aucune mention « hors IRN »** — asymétrie nette avec le mobile (§0) |
| `web_sejoufr/app/entrainement/tcf/[code]/[level]/page.tsx` | 32-33 | idem |
| `web_sejoufr/app/entrainement/tcf/[code]/examens/page.tsx` | 50-51 | idem, **écran d'examen blanc de module** |
| `web_sejoufr/app/(app)/statistiques/page.tsx` | 41, 55 | SL dans les stats, à côté des 4 épreuves |
| `web_sejoufr/app/(app)/historique/page.tsx` | 43, 49, 56 | idem dans l'historique |
| `web_sejoufr/app/sessions/[attemptId]/page.tsx` | 75, 81 | idem sur une session |
| `web_sejoufr/app/_components/ExamReport.tsx` | 30 | `EPREUVE_META` — et le libellé y est **« Structure*s* de la langue »**, seule occurrence au pluriel du dépôt |
| `mobile_sejourfr/lib/core/models/enums.dart` | 58, 79, 201, 222 | libellés Dart |
| `mobile_sejourfr/lib/core/utils/dashboard_targets.dart` | 12, 33 | icône et route |

**Le web n'a aucun équivalent du bandeau mobile.** Un utilisateur web peut
faire toute une série de Structure de la langue sans jamais lire qu'elle n'est
pas au programme de l'examen.

---

## 4. 🟡 Un article de blog range SL dans les épreuves obligatoires

`web_sejoufr/content/articles/quel-tcf-passer-irn-tout-public-canada-quebec.mdx:46` :

> « Version historique et la plus large du TCF. Elle repose sur des **épreuves
> obligatoires de compréhension et de structure de la langue** […] »

⚠️ **Cette phrase est JUSTE** : elle décrit le TCF **tout public**, pas l'IRN,
et c'est précisément le propos de l'article. **Rien à corriger** — je la
signale parce qu'elle explique probablement d'où vient la confusion interne :
Structure de la langue *est* une épreuve obligatoire… d'un autre examen.

---

## 5. Récapitulatif et options

| # | Surface | Gravité | Volume |
|---|---|---|---|
| 1 | « Les 5 épreuves du TCF IRN » sur l'offre payante | 🔴 | 2 lignes, 2 fronts |
| 2 | Réviser : SL intercalée + « Les 5 épreuves » | 🟠 | 5 fichiers, 2 fronts |
| 3 | Listes d'égal à égal, et **aucun avertissement côté web** | 🟡 | 11 fichiers, 3 fronts |
| 4 | Blog TCF tout public | ✅ | rien à faire |

**Deux options pour le §2, à trancher :**

- **(A) SL sort de la liste des épreuves** et devient une section à part sur
  Réviser (« Renforcer son français », après les 4 épreuves). Le titre passe
  seul à « Les 4 épreuves ». C'est la lecture la plus fidèle.
- **(B) SL reste dans la liste**, en dernier, avec une mention
  « complémentaire » sur sa ligne, et le titre de section devient neutre.
  Moins de travail, mais la ligne reste au milieu d'un décompte d'épreuves.

🛑 **Aucune donnée n'est en cause** : `DashboardCategoryStat` continue de servir
SL, et le backend continue de l'exclure du Plan, du diagnostic et de l'examen
blanc. C'est un regroupement d'affichage.
