# BRIEF — Navigation v2 SejourFR (web + mobile)

> Refonte de la **structure de navigation** et de l'**Accueil**, alignée sur deux maquettes HTML.
> Backend **inchangé**. Contenu des écrans existants **inchangé** (sauf Accueil).
> Travail en phases avec **audit obligatoire avant tout code** et points **STOP** bloquants.

---

## 0. Fichiers de référence

| Fichier | Rôle |
|---|---|
| `docs/redesign/sejourfr-navigation-web.html` | Maquette **web** (sidebar + topbar + écrans) |
| `docs/redesign/sejourfr-navigation-mobile.html` | Maquette **mobile** (bottom nav + onglets segmentés) |
| Ce brief | Règles, mapping des données, phases |

**Ouvre et lis intégralement les deux maquettes (HTML + CSS + JS) avant l'audit.** Elles font foi pour : structure, hiérarchie, ordre des blocs, composants, espacements, rayons, ombres, tailles de texte, états actifs, comportements responsive, libellés statiques.

---

## 1. Règles d'or (non négociables)

| # | Règle |
|---|---|
| R1 | **Fidélité à la maquette** : structure, ordre des sections, composants et proportions identiques. Pas de "réinterprétation". Tout écart doit être signalé et justifié. |
| R2 | **Couleurs de la maquette interdites.** Utiliser exclusivement les tokens SejourFR (§8). Aucun hex de la maquette ne doit apparaître dans le code. |
| R3 | **Toutes les données de la maquette sont fictives** (nom, niveaux, %, scores, compteurs, noms de pass, n° de série…). Chaque valeur dynamique provient du backend. **Zéro valeur métier en dur.** |
| R4 | **Backend inchangé** : pas de nouvel endpoint, pas de migration, pas de modification d'API. Si une donnée manque → **ne pas l'inventer**, la signaler à l'audit. |
| R5 | **Contenu des écrans existants inchangé** (TCF plan/entraînement/examens/progression, civique, profil) : on les **re-loge** dans la nouvelle structure et on applique le **style** de la maquette. Seul l'**Accueil** prend le contenu des maquettes. |
| R6 | **Vocabulaire** : côté utilisateur on dit « pass » / « accès », **jamais « abonnement »** (la maquette dit « Mon abonnement » → afficher « Mon pass »). Le score /499 reste « score de progression ». |
| R7 | Constantes métier (seuil 32/40, nb questions, nb épreuves, nb thèmes) : depuis le backend ou le fichier JSON de config versionné existant, jamais en dur. |
| R8 | Les textes **éditoriaux statiques** de la maquette (titres, sous-titres, libellés de section, CTA) sont repris **tels quels**, sauf quand ils contiennent une valeur (ex. « Atteindre **B2** partout » → niveau cible dynamique). |

### Exemples de valeurs fictives à remplacer (liste non exhaustive)

| Maquette | Source réelle attendue |
|---|---|
| « Abdoul Matine », « AM » | Nom / initiales de l'utilisateur connecté |
| « Objectif · Naturalisation » | Mention de l'utilisateur (CSP / CR / NAT → libellé) |
| « B1 → B2 », « Atteindre B2 partout » | Niveau actuel estimé → niveau cible de la mention (A2 / B1 / B2) |
| « 34 % », « 17 séries », « 17/43 » | Calcul §6 |
| « 3/5 séries », ring 60 % | Séries terminées / total **par thème** |
| « 91 % », « 76 % → 84 % → 91 % » | Historique réel des examens blancs civiques |
| « 2/4 », « Examen 3 », « Verrouillé » | Examens TCF réels + droits d'accès réels |
| « Pass Intégral · actif » | Plan / pass réel de l'utilisateur (ou accès gratuit) |
| « Cycle 2 · 0/4 » | Données du plan TCF existant |
| « 32/40 », « 40 questions » | ExamTemplate civique |

---

## 2. Périmètre

**Inclus** : shell de navigation web (sidebar, topbar, tiroir responsive), shell mobile (bottom nav 4 onglets, onglets segmentés, sous-écrans Progression), écran Accueil web + mobile, re-logement et restylage des écrans TCF / Civique / Profil, redirections des anciennes routes.

**Exclus** : backend, console admin, écrans de passation (QCM, examen en cours, correction), paiement, authentification/onboarding, emails. Ces écrans gardent leur design actuel ; seuls les **liens** qui y mènent doivent fonctionner depuis la nouvelle navigation.

**Ignorer** dans la maquette web : classes CSS orphelines non utilisées dans le markup (`.search`, `.chip.streak`, `.stat-strip`, `.stat-tile`). Ne pas les implémenter.

---

## 3. Architecture de navigation cible

### 3.1 Web

```
Sidebar
├─ Vue d'ensemble
│   └─ Accueil
├─ [Module TCF IRN]        (bloc fond bleu clair, rail bleu)
│   ├─ Mon plan            tail : {niveauActuel} → {niveauCible}
│   ├─ Entraînement        tail : {nbEpreuves} épreuves
│   ├─ Examens blancs      tail : {faits}/{total}
│   └─ Progression         tail : {niveauActuel}
├─ [Module Examen civique] (bloc fond rouge clair, rail rouge)
│   ├─ Plan                tail : {pct} %
│   ├─ Entraînement        tail : {nbThemes} thèmes
│   ├─ Examens             tail : {meilleurScore} %   (masqué si aucun examen)
│   └─ Progression         tail : {seriesTerminees} séries
├─ Compte
│   └─ Profil
└─ Carte utilisateur (bas) : initiales · nom · « {nom du pass} · actif » ou accès gratuit → Profil
```

- En-tête de module : titre + sous-titre dynamique (`Objectif {niveauCible} · {nbEpreuves} épreuves` / `Objectif {seuil}/{total} · {nbThemes} thèmes`).
- Sous-menus « en escalier » : indentation + rail vertical + petit trait horizontal par item, item actif = fond blanc + ombre + couleur du module (cf. CSS `.module-items`, `.module .nav-item`).
- Marque : **notre logo cocarde** + wordmark « Sejour**FR** » avec **FR en rouge** (la maquette utilise une icône bouclier et un FR bleu → à remplacer).
- **Topbar** sticky : burger (≤1024 px) · fil d'Ariane `SejourFR / {Section} / {Page}` (page colorée bleu pour TCF, rouge pour civique) · avatar → Profil.
- Chaque entrée = **une vraie route** (URL partageable, bouton retour navigateur OK).

**Breakpoints (reprendre exactement ceux de la maquette)** :

| Largeur | Comportement |
|---|---|
| > 1180 px | Layout complet, `split` en 2 colonnes, `grid-4` en 4 |
| ≤ 1180 px | `split` → 1 colonne, `grid-4` → 2 |
| ≤ 1024 px | Sidebar → **tiroir** (burger, overlay flouté, bouton fermer, fermeture à la navigation) |
| ≤ 760 px | `grid-2` → 1 colonne, paddings réduits, H1 26 px |
| ≤ 520 px | Fil d'Ariane masqué |

### 3.2 Mobile (Flutter)

```
Bottom nav (4) : Accueil · TCF · Civique · Profil
                 (actif bleu ; onglet Civique actif = rouge)
├─ Accueil
├─ TCF       : en-tête + carte « Ma progression » + segment [Plan | Entraînement | Examens]
│   └─ (push) Progression TCF   ← lien retour « TCF IRN », onglet TCF reste actif
├─ Civique   : en-tête + carte « Ma progression » + segment [voir D1]
│   └─ (push) Progression civique ← lien retour « Examen civique », onglet Civique reste actif
└─ Profil
```

- Segment TCF : actif = fond blanc. Segment civique : actif = **fond rouge, texte blanc** (cf. `.segment.red`).
- Chaque onglet de la bottom nav conserve sa pile et son état (onglet segmenté sélectionné, scroll).
- Changement d'onglet segmenté → retour en haut de page.
- Retour Android : depuis Progression → écran module ; depuis un onglet racine ≠ Accueil → Accueil.

### 3.3 Correspondance web ↔ mobile

| Web (route) | Mobile |
|---|---|
| Accueil | Onglet Accueil |
| TCF · Mon plan | TCF › segment Plan |
| TCF · Entraînement | TCF › segment Entraînement |
| TCF · Examens blancs | TCF › segment Examens |
| TCF · Progression | TCF › carte « Ma progression » → écran poussé |
| Civique · Plan | Civique › segment 1 |
| Civique · Entraînement | Civique › segment 2 |
| Civique · Examens | Civique › segment 3 |
| Civique · Progression | Civique › carte « Ma progression » → écran poussé |
| Profil | Onglet Profil |

---

## 4. Écran Accueil (nouveau contenu)

Ordre des blocs **différent** entre web et mobile dans les maquettes : le respecter (sauf décision D2).

### 4.1 Mobile (ordre)

1. Kicker `Objectif · {mention}`
2. H1 `Bonjour {nom}` + sous-titre statique
3. **Mes objectifs** — une carte groupée, 2 lignes séparées par un divider :
   - TCF IRN · « Atteindre {niveauCible} partout » · « Progression vers l'objectif » · valeur `{actuel} → {cible}` (bleu) → **Progression TCF**
   - Examen civique · « Être prêt pour l'examen » · `Objectif : avoir {seuil}/{total}` · valeur `{pct} %` (rouge) → **Progression civique**
4. **À faire maintenant** — 2 cartes action :
   - TCF : icône pleine bleue, label « TCF IRN », titre = **prochaine activité recommandée par le plan**, méta = type · durée, CTA bleu « Continuer le TCF »
   - Civique : icône pleine rouge, label « Examen civique », titre = **thème de la prochaine série recommandée**, méta statique, CTA rouge « Continuer le civique »

### 4.2 Web (ordre)

1. Page-head : kicker, H1, sous-titre statique (version web, plus longue)
2. **À faire maintenant** — `grid-2`, mêmes 2 cartes action + badge à droite (`{codeEpreuve}` / `Série {n}`)
3. **Mes objectifs** — `grid-2`, 2 grandes cartes dégradées (`.obj-card`) :

| Carte | Barre | Métrique 1 | Métrique 2 | Métrique 3 |
|---|---|---|---|---|
| TCF (bleu) | voir D4 | `{actuel} → {cible}` · Progression | `{n}/{nbEpreuves}` · Épreuves au {cible} | `Cycle {n}` · En cours |
| Civique (rouge) | `{pct} %` | `{pct} %` · Du parcours | `{terminées}/{total}` · Séries terminées | `{seuil}/{total}` · Objectif examen |

Les descriptions des cartes sont statiques, sauf le niveau cible et le nombre d'épreuves.

### 4.3 Destinations des CTA

Les CTA « Continuer » ouvrent **directement l'activité recommandée** (même destination que le « continuer » actuel s'il existe). À défaut, ils ouvrent l'onglet/la page du module comme dans la maquette. À préciser à l'audit.

---

## 5. Écrans TCF, Civique, Profil (re-logement)

Pour chaque écran existant :

1. Le placer à son nouvel emplacement (§3.3).
2. Lui appliquer le **gabarit** de la maquette : page-head (kicker + H1 + sous-titre + badges à droite sur web), cartes, `hero`, `info-card`, `metric`, `exam-row`, `level-row`, `timeline`, `theme-card`, `split` web.
3. Garder **toutes** ses données et fonctionnalités actuelles.
4. Bloc de la maquette **sans équivalent** dans l'existant → **ne pas l'ajouter**, le lister à l'audit (voir D3).
5. Bloc existant **absent** de la maquette → le garder, stylé avec le composant de maquette le plus proche, et le signaler.

Éléments **nouveaux de structure** (à câbler, données backend) :
- Mobile TCF : carte `Ma progression` → `{actuel} → {cible}`, `Objectif : {cible} dans les {nbEpreuves} compétences`, « Voir le détail ».
- Mobile Civique : carte `Ma progression` → `{pct} %`, `{terminées} séries terminées`.
- Web : tails de la sidebar (§3.1), fil d'Ariane.

Profil : « Mon abonnement » → **« Mon pass »** ; méta = nom du pass réel (+ « paiement unique, aucun renouvellement » sur web si pass actif). Badges « Membre depuis » / « Votre semaine » : voir D3.

---

## 6. Règle du pourcentage civique

```
pct = floor( séries terminées / séries totales × 100 )
```

| Élément | Définition |
|---|---|
| Séries totales | Toutes les séries de la **mention de l'utilisateur**, tous thèmes (voir D5 pour les séries verrouillées) |
| Série terminée | Voir D5 |
| Arrondi | `floor` (on n'affiche jamais 100 % tant qu'il reste une série) |
| Par thème | Même formule restreinte au thème (rings, `level-row`, « 3/5 séries ») |
| 0 série | Afficher `0 %`, jamais vide |

Exemple : 17 terminées / 43 → **39 %** (le 34 % de la maquette est fictif).

Le même pourcentage alimente : ligne objectif Accueil, carte objectif web, tail sidebar « Plan », carte « Ma progression » mobile, hero Plan civique, écran Progression civique.

- Si le backend expose déjà ces compteurs → les utiliser.
- Sinon → calcul client depuis les endpoints existants, dans **une fonction unique** par plateforme (web / Flutter), testée unitairement, même résultat sur les deux.

---

## 7. États à gérer (absents des maquettes)

| Cas | Comportement attendu |
|---|---|
| Chargement | Skeletons aux dimensions des composants (pas de spinner plein écran) |
| Erreur API | Message + « Réessayer » dans le bloc concerné, le reste de l'écran reste utilisable |
| Nouvel utilisateur (aucune donnée) | Niveau actuel « — » / « Non évalué », 0 %, pas d'historique → texte d'invitation au 1er examen/1re série |
| Aucun examen civique | Tail « Examens » masqué, timeline remplacée par un état vide |
| Accès gratuit vs pass | Verrouillages et libellés selon les droits réels (pas ceux de la maquette) |
| Mention sans TCF ou civique pertinent | À vérifier à l'audit (ne rien supposer) |

---

## 8. Design tokens

### 8.1 Couleurs — remplacement obligatoire

| Rôle (variable maquette) | Hex maquette (interdit) | **Token SejourFR** |
|---|---|---|
| `--blue` | `#27449B` | **Bleu France `#1E3A8C`** |
| `--blue-dark` | `#1B337F` | **`#15296B`** |
| `--blue-soft` / `#EAF0FF` | `#EEF2FF` | **`#E8ECF8`** |
| `--red` | `#D94B40` | **Rouge France `#E1372F`** |
| rouge foncé (`#B53C33`, `#A83730`, `#B93E35`) | — | **`#B5251E`** |
| `--red-soft` | `#FFF1EF` | **`#FDECEB`** |
| `--ink` | `#0E1738` | **Encre `#0F1839`** |
| `--green` | `#2F9A69` | **Vert succès `#168F5B`** |
| `--amber` | `#A87A22` | **Ambre `#E8A317`** (voir note) |
| Dégradé hero/obj bleu | `#182758 → #2B4AA2` | **`#15296B → #1E3A8C`** |
| Dégradé hero/obj rouge | `#B93E35 → #E05A4F` | **`#B5251E → #E1372F`** |
| Ombres teintées (`rgba(39,68,155,…)`, `rgba(217,75,64,…)`) | — | Recalculées depuis nos bleu/rouge |

- **Neutres** (`--bg`, `--muted`, `--line`, `--surface-2`, gris des segments) : utiliser les tokens neutres **existants** de l'app ; s'il n'y en a pas, reprendre les valeurs de la maquette **en les déclarant comme tokens** (jamais en dur dans les composants).
- **Note ambre** : `#E8A317` en texte sur fond clair a un contraste insuffisant. L'utiliser pour pastilles, fonds, icônes ; pour du texte ambre, utiliser un token ambre foncé existant ou le signaler à l'audit.
- Les vert/ambre « soft » et le fond `tip-card` : dériver de nos teintes.
- Aucun hex en dur hors fichier de tokens (web : variables CSS / thème ; Flutter : `ThemeData` / classe de couleurs).

### 8.2 Typographie

La maquette utilise une pile système → **remplacer** par :

| Usage | Police |
|---|---|
| Corps, titres, CTA, chiffres de cartes | Plus Jakarta Sans (graisses équivalentes à la maquette) |
| Labels uppercase (`.label`, `.kicker`, `.nav-label`), codes épreuves/thèmes (CO, CE, PV…), tails sidebar | JetBrains Mono |
| Moments éditoriaux | Fraunces — voir D6 |

Tailles, interlignages et letter-spacing : ceux de la maquette.

### 8.3 Icônes

Reprendre les pictogrammes SVG de la maquette (style trait 2–2,2 px, arrondis). Mobile : équivalents Flutter fidèles (SVG embarqués ou jeu d'icônes au même style), pas de substitution par des icônes Material pleines.

---

## 9. Anciennes routes & liens profonds

- Recenser toutes les routes actuelles (web + `go_router`) et les rediriger vers leur nouvel emplacement.
- Vérifier les liens utilisés dans les **emails transactionnels** et notifications push : aucun lien cassé.
- Pas de 404 pour un utilisateur qui avait un favori.

---

## 10. Phases et points STOP

### Phase 1 — Audit (aucun code)

Livrer un rapport `docs/redesign/AUDIT.md` contenant :

1. **Inventaire** des écrans et routes actuels (web + mobile), composants partagés, système de tokens existant.
2. **Tableau de correspondance** écran actuel → emplacement cible (§3.3).
3. **Tableau de mapping des données** : pour **chaque valeur dynamique** de chaque maquette (Accueil, sidebar, cartes « Ma progression », tails, profil) → endpoint + champ, ou **« ABSENT »**.
4. Liste des **blocs maquette sans équivalent** et des **blocs existants absents** de la maquette, par écran.
5. Méthode de calcul du % civique retenue (compteurs backend existants ou calcul client) + endpoints utilisés.
6. Liste des anciennes routes → redirections.
7. Écarts maquette / contraintes techniques identifiés.
8. Réponses proposées aux décisions §11 (avec recommandation).

> ⛔ **STOP 1** — Attendre validation explicite de l'audit et des décisions D1–D6.

### Phase 2 — Fondations

Tokens couleurs/typo (§8), shell web (sidebar, modules, topbar, tiroir, breakpoints), shell mobile (bottom nav, piles par onglet, segments, sous-écrans Progression), routes + redirections. Écrans existants simplement branchés dans le nouveau shell.

> ⛔ **STOP 2** — Démo du shell web (3 largeurs : 1280 / 900 / 390) et mobile. Validation avant la suite.

### Phase 3 — Accueil

Web + mobile, données réelles, états §7.

> ⛔ **STOP 3** — Validation de l'Accueil.

### Phase 4 — Re-logement TCF / Civique / Profil

Application du gabarit maquette, cartes « Ma progression », tails, % civique, fonction de calcul testée.

> ⛔ **STOP 4** — Validation finale + checklist §12.

---

## 11. Décisions à faire valider (STOP 1)

| # | Sujet | Options | Reco |
|---|---|---|---|
| D1 | Libellés des onglets civique : mobile « Parcours / Réviser / Examens » vs web « Plan / Entraînement / Examens » | **A** harmoniser partout en Plan / Entraînement / Examens · **B** garder chaque maquette | A |
| D2 | Ordre Accueil (web : À faire → Objectifs ; mobile : Objectifs → À faire) | **A** respecter chaque maquette · **B** harmoniser | A |
| D3 | Blocs maquette sans donnée probable : « Conseil du plan », « Analyse IA », « Statistiques par thème », « Votre semaine » (série de jours), « Membre depuis », « Examen blanc par thème », « Entretien en temps réel » | **A** masquer tant que la donnée n'existe pas · **B** afficher ceux dont l'audit trouve la donnée | B (A par défaut pour le reste) |
| D4 | Barre de progression TCF (carte objectif web + hero Plan) | **A** épreuves au niveau cible / nb épreuves · **B** avancement du cycle en cours · **C** pas de barre | A |
| D5 | « Série terminée » et total pour le % civique | **A** terminée au moins une fois, quel que soit le score ; total = toutes les séries de la mention, verrouillées comprises · **B** idem mais total = séries accessibles · **C** terminée avec score ≥ seuil | A |
| D6 | Usage de Fraunces | **A** reprendre l'usage actuel de l'app · **B** H1 Accueil + titres `hero` uniquement · **C** jamais (fidélité stricte à la maquette) | A |

---

## 12. Checklist de recette

- [ ] Aucun hex de la maquette dans le code (`grep` sur `27449B`, `D94B40`, `0E1738`, `2F9A69`, `A87A22`, `182758`, `2B4AA2`, `B93E35`, `E05A4F`, `EEF2FF`, `FFF1EF`)
- [ ] Aucune donnée fictive de la maquette dans le code (`grep` « Abdoul », « 34% », « 17/43 », « 91 », « Pass Intégral » codé en dur…)
- [ ] Le mot « abonnement » n'apparaît nulle part côté utilisateur
- [ ] Logo cocarde + « FR » rouge dans la sidebar
- [ ] Structure, ordre des blocs et composants identiques aux maquettes (comparaison côte à côte, 3 largeurs web + mobile)
- [ ] Toutes les entrées de navigation ont une URL / route propre ; retour navigateur et retour Android cohérents
- [ ] Tiroir web : ouverture, overlay, fermeture à la navigation, scroll du body bloqué
- [ ] Onglet Civique actif en rouge (bottom nav, segment, sidebar, fil d'Ariane)
- [ ] % civique identique sur les 6 emplacements et identique web / mobile ; tests unitaires de la fonction
- [ ] États chargement / vide / erreur / gratuit / pass vérifiés
- [ ] Anciennes routes et liens d'emails redirigés, aucun 404
- [ ] Écrans existants : aucune donnée ni fonctionnalité perdue
