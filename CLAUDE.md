# SejourFR — index racine

Monorepo (4 dossiers indépendants, pas de workspace npm/Maven parent) de **SejourFR**,
plateforme d'entraînement aux examens **civique** (CSP, CR, naturalisation) et **TCF IRN**
(A2/B1/B2), obligatoires depuis le **1ᵉʳ janvier 2026**.

## Comment lire ce fichier

🛑 **Ce fichier est un INDEX, pas une référence.** Il est rechargé intégralement à chaque
requête, donc il ne contient que deux choses : **ce qui casse en silence ailleurs**, et **de
quoi savoir quel fichier ouvrir**. Tout le reste vit dans `docs/`, en **lecture à la demande**.

Trois règles d'usage :

1. **Ne jamais répondre « de mémoire » sur une règle métier.** Freemium, Plan, diagnostic,
   notation IA, compétences, paiements, chronos : la règle exacte vit dans un fichier
   `docs/regles/*.md`. On l'ouvre, on ne la reconstitue pas.
2. **Avant de CHANGER une règle** (un seuil, un contrat, une consigne de notation, une règle
   produit), ouvrir aussi le `docs/decisions/*.md` du même sujet : il dit ce qui a déjà été
   essayé, mesuré et révoqué. Beaucoup de ces règles ont un coût mesuré derrière elles.
3. **Chemins en texte brut, jamais d'`@import`.** Un import rechargerait le contenu à chaque
   requête et annulerait tout le bénéfice.

> Avant de coder sur un sous-projet, **toujours lire son `CLAUDE.md` local** : les conventions
> précises (state management, styling, runner) y vivent.

## Le monorepo

| Dossier              | Stack                                                                       | Rôle                                                       | Port dev    |
|----------------------|-----------------------------------------------------------------------------|------------------------------------------------------------|-------------|
| `backend_sejourfr/`  | Spring Boot 4 / Java 21 / PostgreSQL / Flyway / JWT                         | API REST unique pour les 3 fronts                          | 8080        |
| `admin_sejourfr/`    | React 19 + Vite + TS strict + TanStack Query + React Router 7 + CSS Modules | Console admin                                              | 5173 (Vite) |
| `web_sejoufr/` ⚠️    | Next.js 16 App Router + React 19 + Tailwind v4 (tokens seuls)               | Vitrine + parcours user + paiement Stripe + démo gratuite  | 3000        |
| `mobile_sejourfr/`   | Flutter 3.6+ / Dart 3.6+ / Riverpod 2 + Dio + go_router                     | App d'entraînement quotidien (cœur produit)                | —           |

⚠️ Le dossier web est `web_sejoufr` (typo : *sejoufr*, pas *sejourfr*).

**Stratégie business** : le web pousse à l'abonnement (paiement Stripe **hors stores** pour
éviter la commission Apple/Google), puis l'utilisateur s'entraîne principalement sur le mobile.
Web : 1 examen blanc + 10 QCM d'entraînement par module pour convertir.

**Le backend est la source de vérité des DTO.** Les 3 fronts maintiennent leurs miroirs **à la
main** — `admin_sejourfr/src/types/api.ts`, `web_sejoufr/lib/types.ts`,
`mobile_sejourfr/lib/core/models/*.dart`. Quand un DTO Java change, mettre à jour les 3.

## Vocabulaire minimal

Juste de quoi comprendre une demande. Le détail (sémantique fine, valeurs, pièges) :
`docs/regles/domaine.md`.

- **Module** : `CIVIQUE` ou `TCF`.
- **TargetProcedure** (civique) : `CSP` / `CR` / `NAT`. 🛑 **Le palier de français exigé est
  porté par l'enum** — `CSP→A2`, `CR→B1`, `NAT→B2` (seuils du 1ᵉʳ janvier 2026).
  `TargetProcedure.getRequiredTcfLevel()` est LA source de vérité et
  `TargetProcedure.niveauVise(procedure, declare)` applique le **plancher**. **Ne jamais
  réécrire cette table ailleurs** : elle a vécu en 6 copies, d'où un candidat NAT tiré vers le
  B1. Miroirs gelés par test de chaque côté.
- **TargetLevel** (TCF) : `A2` / `B1` / `B2`.
- **Epreuve** : `CIVIQUE` / `TCF_CO` / `TCF_CE` / `TCF_STRUCTURE` / `TCF_EO` / `TCF_EE` /
  `TCF_COMPLET` (conteneur d'examen blanc, sous-attempts via `attempts.parent_attempt_id`).
- **AttemptType** : `TRAINING` (correction immédiate) / `MOCK_EXAM` (examen blanc, chrono, pas
  de correction live) / `REVIEW`.
- **SkillSection** (compétences) : `EE` / `EO` / `CO` / `CE`. **SkillTaskCode** : les 6 tâches
  officielles d'expression `EE1..EE3` / `EO1..EO3` — 🛑 ne jamais y ajouter de valeur CO/CE.
- **Difficulty** : `CSP` / `CR` / `NAT` / `A2` / `B1` / `B2` — c'est l'axe « procédure visée
  **ou** palier CECRL », **pas** une échelle facile/moyen/difficile. Distinct de
  `SkillDifficulty` (`EASY`/`MEDIUM`/`HARD`), qui existe pour cette raison.
- **Role** : `USER` / `ADMIN`. **AuthProvider** : `LOCAL` / `GOOGLE` / `APPLE`.

## Les invariants qui cassent en silence

Ce qui suit est résident parce que ça se viole depuis une tâche qui n'en avait pas l'air.

### Pour toute tâche

- **Parité web ⇄ mobile ⇄ admin, non négociable.** Les 3 fronts consomment le même backend et
  implémentent les mêmes parcours. Toute modif d'une **surface partagée** — endpoint (chemin,
  query params, méthode, param devenu requis), DTO, règle métier, enum — se propage et se
  **vérifie des trois côtés dans la même passe**. Idem pour un **bugfix** : dès qu'on corrige
  un bug sur un parcours commun, on vérifie le même comportement de l'autre côté et on aligne.
  Avant de fermer : *« web et mobile font-ils exactement pareil, sans régression ? »*
- 🛑 **Aucun test sur les fronts. Jamais.** Ni `*.test.ts`, ni `flutter_test`, ni test de
  widget, de libellé gelé ou de layout. Les seuls tests du dépôt sont ceux du **backend**.
  Cette règle **prime** sur toute consigne de test écrite ailleurs. Vérification d'un
  changement front : `npx tsc --noEmit` / `npm run build` / `flutter analyze`, rien de plus.
- **Backend : tests dans la même passe.** Feature, bugfix, règle métier, endpoint, migration à
  impact logique ne se ferment pas sans test(s) qui verrouillent le comportement. Avant un
  refactor d'un bloc non couvert : écrire le filet d'abord.
- 🛑 **Aucun test ni aucune mesure qui appelle un LLM payant sans demande explicite.** Vaut
  pour le banc de calibration et tout script qui interroge un fournisseur. C'est l'argent du
  propriétaire : on **propose** la mesure et son coût, il décide. Avant toute analyse, se
  demander d'abord si une **requête SQL sur la base locale** répond à la question.
- **Pas de README ni de `.md` généré automatiquement.** N'en créer un que sur demande.
- **Refonte = suppression immédiate de l'ancien** : fichier + imports + routes + CTA, dans la
  foulée. Pas de cohabitation « au cas où ».
- **Duplication = signal.** 2ᵉ occurrence ⇒ extraire un widget/util/service partagé. À la 3ᵉ,
  c'est de la dette.
- **Mode agent : orchestrateur par défaut, surchargeable.** Par défaut, une demande de travail
  part dans un agent et Claude principal délègue, suit et synthétise ; les arbitrages, la
  synthèse et la mise à jour des `CLAUDE.md` restent chez lui. ⚠️ **Une consigne de session
  contraire l'emporte** (ex. « ne pas utiliser l'outil Agent ») : dans ce cas, exécuter
  directement. Détail du dispatch et des collisions : `docs/regles/collaboration.md`.

### Pour toute donnée

- 🛑 **`null` = inconnu, jamais mauvais.** Une absence de mesure ne devient jamais le verdict
  le plus bas. C'est la confusion qui a produit des faux `A1_NON_ATTEINT` (V040/V041/V042).
- **Dérivé serveur ⇒ jamais persisté, jamais recalculé par un front.** Statuts, situations,
  niveaux, natures d'action, achèvements d'étape : le serveur calcule à la lecture, les fronts
  affichent. Un front qui recalcule finit par désigner autre chose que le serveur.
- **Une règle = une autorité.** Deux copies d'une même règle finissent toujours par diverger —
  c'est le défaut le plus cher du dépôt (table des paliers en 6 copies, `estimateCostCents` en
  11 copies). À la 2ᵉ occurrence, on extrait.
- **Un garde-fou serveur ne peut qu'abaisser.** Seule exception connue et voulue : le plancher
  A1 des QCM, qui ne relève que d'un cran depuis `A1_NON_ATTEINT` (`docs/regles/qcm.md`).
- **Ce qui tient la qualité, ce sont les contraintes dures, pas les consignes.** Ordre de
  préférence : (1) le tool-schema — un champ absent ne peut pas être produit ; (2) une longueur
  plafonnée ; (3) un contrôle serveur déterministe ; (4) **en dernier** une consigne de prompt.
- 🛑 **Aucun audio de candidat n'est conservé** (décision du propriétaire, motif consentement).
  L'audio sert uniquement à produire la transcription, puis il disparaît. Ne jamais réintroduire
  d'écriture d'audio candidat, ni de migration de purge rétroactive.
  → `docs/regles/audio-productions.md`
- **Le freemium est opposable serveur** (403), et les fronts **lisent un `locked`** servi. Ne
  jamais coder « à partir du 2ᵉ, cadenas » ni déduire un verrou d'un rang.
  → `docs/regles/freemium.md`
- 🛑 **Un plafond d'AFFICHAGE n'est jamais un budget PÉDAGOGIQUE.** Le moteur calcule
  **toutes** les actions vraies, l'écran en montre un sous-ensemble — jamais l'inverse. Un
  plafond utilisé comme budget de production a privé trois domaines sur quatre de toute
  action (2026-08-25 : 10 actions existaient, 2 étaient servies). Corollaire : une carte
  d'épreuve ne dérive jamais d'une liste déjà tronquée.
- 🛑 **`NON FRAGILE` ≠ `PLUS RIEN À APPRENDRE`**, et **le palier se lit sur le DOMAINE**, pas
  sur le plancher global. Une épreuve sans fragilité mais sous l'objectif a un palier entier à
  acquérir. Un domaine plus avancé que les autres ne **redescend** pas (règle conservée) et ne
  reste pas **vide** pour autant. → `docs/regles/plan.md`
- 🛑 **Aucun front ne classe un nombre en état pédagogique ni en niveau CECRL.** Pas de
  `cefr(v)`, pas de `masteryLabel(v)`, pas de ton dérivé d'un pourcentage : l'état, son
  libellé et son ton arrivent **servis** (six états, `WATCH` et `READY_FOR_REASSESSMENT`
  compris). Vérifiable : `node scripts/verifier-contrat-front-progression.mjs`.
  → `docs/regles/progression.md`
- **On versionne, on ne réécrit jamais** une rubrique, un tool-schema ou un contrat livré. Un
  retour arrière est un changement de variable d'environnement, pas une migration.

### Pour tout écran

- 🛑 **Jamais de couleur ni de font en dur.** Toujours les tokens locaux (`var(--color-*)`,
  `AppColors.*`, `AppFonts.*`). Bleu France `#1E3A8C` + Rouge France `#E1372F` (CTAs critiques
  seulement) ; **Plus Jakarta Sans** (web/mobile) ou **Inter** (admin), **Fraunces** (titres,
  `<em>` toujours rouge), **JetBrains Mono** (labels techniques).
  → `docs/identite-visuelle.md`
- **Responsive obligatoire (web + admin)** : du mobile (~360 px) au desktop. Tester mentalement
  360 / 768 / 1280. Pas de largeur fixe sans `max-width: 100%`, pas de grille à colonnes fixes
  sans `@media` de repli, pas de tableau sans alternative carte.
- **Pas de Tailwind utility-first dans le markup web** — Tailwind v4 sert uniquement aux tokens
  via `@theme`. Styles dans `globals.css` ou `<style>` JSX scoped.
- **Admin & runner** : pas d'UI kit, pas de CSS-in-JS, pas de `clsx`. CSS Modules vanilla.
- **Mobile** : Riverpod uniquement (pas de Bloc/Provider/GetX), `context.go/push` (jamais
  `Navigator.push`), `withValues(alpha:)` (pas `withOpacity`).
- **Tous** : TypeScript/Dart strict, pas de `any`/`dynamic`, imports relatifs, pas de
  commentaire qui paraphrase le code.

## Conventions par sous-projet

Tous les fronts suivent l'organisation **par feature**, miroir du backend Java.

- **Backend Java** — `Controller → Service → Manager → Repository`, **strict**. Controllers
  ultra-fins ; services orchestrent un cas d'usage et **n'accèdent jamais à un `*Repository`**
  directement ; **les managers sont la seule couche autorisée** à le faire ; mappers purs
  (`@Component`, aucune lookup). Lombok `@RequiredArgsConstructor` / `@Slf4j` ; sur les entités
  JPA `@Getter/@Setter` mais **jamais `@Data`**. Seule exception : `audioquestion/`, sous-module
  isolé non migré. → `backend_sejourfr/CLAUDE.md`
- **Admin React** — `features/{questions,themes,conversations,analytics,plans,…}/` + `api/`,
  `auth/`, `components/ui/`, `routes/`, `types/`.
- **Web Next** — `app/{inscription,connexion,examen-blanc,paiement,…}/` + `app/_components/` +
  `lib/{api,types}.ts`.
- **Mobile Flutter** — `screens/{auth,home,plan,diagnostic,question_runner,tcf_production,…}/`
  + `core/{api,auth,models,router,theme,utils,widgets}/`.

Le **runner de questions** (mobile `screens/question_runner/`, web `examen-blanc/page.tsx`) est
le composant le plus complexe — relire son `CLAUDE.md` local avant d'y toucher.

**Hygiène** : tout nouveau fichier prend sa place dans l'arbo `feature/` existante ; si une
feature grossit, créer un dossier dédié. Pas d'exception « juste pour cette fois ».

## API backend partagée

Base : `http://localhost:8080`. CORS dev autorise `localhost:3000` (web) et `localhost:5173`
(admin). Auth JWT Bearer (access ~60 min + refresh 30 j), **refresh automatique** dans le client
HTTP de chaque front. → liste complète : `docs/api-endpoints.md`

## Démarrage local

```bash
# Backend (depuis backend_sejourfr/)
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
# DB : Postgres local, db = sejourfr_db, user = diallomatine (cf. application-dev.yaml)
# Mail : MailHog sur localhost:1025 (UI http://localhost:8025)
# Tests : ./mvnw verify  (unitaires *Test via surefire + intégration *IT via failsafe).
#   Les *IT tournent sur un Postgres EMBARQUÉ (Zonky, pas de Docker) qui applique les
#   vraies migrations Flyway. Détails + gabarits : docs/plan-tests-backend.md.

# Admin (depuis admin_sejourfr/)
npm install && npm run dev-admin   # ⚠️ script "dev-admin", pas "dev"

# Web (depuis web_sejoufr/)
npm install && npm run dev-web     # ⚠️ script "dev-web", pas "dev"

# Mobile (depuis mobile_sejourfr/)
flutter pub get && flutter run     # config via mobile_sejourfr/.env (cf. son CLAUDE.md)
```

**Comptes seed (profil dev uniquement)**

| Email                    | Mot de passe | Rôle  |
|--------------------------|--------------|-------|
| `admin@sejourfr.fr`      | `Admin123!`  | ADMIN |
| `user@sejourfr.fr`       | `User123!`   | USER  |
| `karim.test@sejourfr.fr` | `User123!`   | USER  |

## Git

- Remote : `git@github.com:diallomatine/sejourfr_opus_nouveau.git`
- Branche par défaut : `develop` (PRs vers `main`)
- Le repo racine est **un seul git** qui couvre les 4 dossiers — un commit peut toucher
  plusieurs surfaces (utile quand on aligne un DTO backend avec ses miroirs front).

## Maintenir les `CLAUDE.md` à jour

Après une modif structurante (nouvelle feature, nouveau pipeline, changement de convention,
migration importante, nouveau dossier `features/*`), mettre à jour **le fichier concerné** :
le `docs/regles/*.md` du sujet, le `CLAUDE.md` local du sous-projet, et **ce fichier-ci
seulement si la modif crée un invariant transverse ou un nouveau fichier à indexer**. Pas de
changelog exhaustif ; inutile de consigner les bugfixes et les micro-ajustements.

⚠️ **Exception — `docs/notation-ia-eo-ee.md` doit TOUJOURS être exhaustive et à jour.** C'est
la référence **grand public** (compréhensible par un non-informaticien) de la façon dont l'IA
note les productions EE/EO. Dès qu'on touche une règle de notation, un barème, un poids de
critère, une consigne donnée à l'IA, une tâche EE/EO ou le comportement de l'examinateur vocal,
on la met à jour **dans la même passe**. Ce n'est pas un aide-mémoire, c'est une exigence.

---

# Où lire quoi

## Index par situation — les règles (`docs/regles/`)

Ouvrir le fichier **avant** de coder, pas après.

| Si tu touches à… | Ouvre |
|---|---|
| un cadenas, un quota, un slot d'examen, un `locked` de DTO, « c'est gratuit ou pas ? » | `docs/regles/freemium.md` |
| le Plan, une priorité, la séance, un jalon, une étape, le moteur de maîtrise, un domaine | `docs/regles/plan.md` |
| le moteur de progression V4.2, une preuve, un palier CO/CE, un état pédagogique servi, `visibleProgress` | `docs/regles/progression.md` |
| le diagnostic initial, le parcours invité→compte→analyse, l'écran de résultat du diagnostic | `docs/regles/diagnostic.md` |
| une rubrique, un tool-schema, un filet/purge serveur, un coût LLM, le banc, l'examinateur vocal | `docs/regles/notation-ia.md` |
| le module Compétences (micro-entraînement EE/EO), un petit sujet, une référence | `docs/regles/competences.md` |
| un score QCM, un niveau CECRL dérivé, l'ordre des propositions, une explication qui cite des lettres | `docs/regles/qcm.md` |
| un chrono, une échéance, `DureeEpreuve`, `deadlineAt`, quitter/suspendre un examen | `docs/regles/examens-temps.md` |
| une soumission orale, Whisper, R2, `AudioEphemere`, la réécoute d'une production | `docs/regles/audio-productions.md` |
| l'analytics, le funnel, un rate-limit par IP, `/confidentialite`, une provenance | `docs/regles/mesure-audience.md` |
| `user_subscriptions`, un webhook store, un plan, un pass, une résiliation | `docs/regles/paiements.md` |
| la sémantique fine d'un enum métier | `docs/regles/domaine.md` |
| le détail du mode agent, de l'hygiène d'archi ou des gabarits de test backend | `docs/regles/collaboration.md` |

## Avant de CHANGER une règle — le journal (`docs/decisions/`)

Journal daté, **verbatim et intégral** : ce qui a été essayé, mesuré, révoqué. À ouvrir quand
on est tenté de modifier un seuil, un contrat, une consigne ou une règle produit.

| Fichier | Ce qu'il contient |
|---|---|
| `docs/decisions/contradictions-ouvertes.md` | Les **3 endroits où le dépôt se contredit**. #1 tranchée, #2 et #3 en attente d'arbitrage. |
| `docs/decisions/suspects-perimes.md` | Les **6 contenus suspectés périmés**, non vérifiés, à ne pas appliquer sans confirmation. |
| `docs/decisions/notation-ia.md` | Journal des grilles v4 → v15 et de leurs tool-schemas, avec les chiffres de banc. |
| `docs/decisions/competences.md` | Journal des contrats du module Compétences v2 → v6 et de leurs campagnes. |
| `docs/decisions/diagnostic.md` | V040 / V041 / V042 — les productions inexploitables et le rejugement des 6 lignes. |
| `docs/decisions/paiements.md` | Lots 1 → 5, geste V038 envers les anciens acheteurs, réversibilité. |
| `docs/decisions/mesure-audience.md` | L'ancien système `page_views`, legacy, conservé comme archive. |

## Documentation de référence (inchangée)

- `docs/api-endpoints.md` — liste complète des endpoints REST
- `docs/identite-visuelle.md` — palette complète, fonts, logo
- `docs/migrations-flyway.md` — convention de numérotation et arbo `db/migration/`
- `docs/plan-tests-backend.md` — stratégie de tests backend (Zonky, conventions `*Test`/`*IT`, gabarits)
- `docs/exams-tcf.md` — examens module (CO/CE) et examen blanc TCF complet
- `docs/lots-entrainement.md` — lots TCF/Civique (calcul dynamique sans schéma)
- `docs/auth-social.md` — Google/Apple sign-in (backend + front, config env)
- `docs/notation-ia-eo-ee.md` — **explication grand public** de la notation IA EE/EO (à tenir exhaustive)
- `docs/pipeline-evaluation-eo-ee.md` — éval EO/EE (transcription → correcteur → R2 privé)
- `docs/pipeline-audio-co.md` + `docs/audio-pipeline/` — génération audio TCF CO (10 fichiers)
- `docs/setup-paiement-one-time.md` — passes achat unique : setup Stripe/Apple/Google pas-à-pas
- `docs/bascule-prix-integral.md` — grille Intégral (7 j / 1 mois / 2 mois), reste à faire côté stores
- `docs/paiements-iap-setup.md` · `docs/vps-config-iap.md` — setup IAP détaillé
- `docs/ia/ANALYSE_SPEC_EVALUATION_IA.md` — décisions produit de la refonte de notation
- `docs/skills/SEJOURFR_SPEC_COMPETENCES_EE_EO.md` — spec fonctionnelle du module Compétences
- `docs/plan/` — briefs et maquettes (Plan adaptatif, Analytics, Mobile/Web Autonome)
- `docs/diagnostiques/` · `docs/relatime/` — briefs diagnostic et EO temps réel
- `docs/refonte-entrainement.md` · `docs/roadmap.md` — statuts et roadmap commune

## Traçabilité de la restructuration

`docs/inventaire-claude-md.md` — pourquoi ce fichier a été découpé le **2026-08-23**, le
critère de tri, et le **tableau de contrôle** ancienne section → nouvelle localisation.
