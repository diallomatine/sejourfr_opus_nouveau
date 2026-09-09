# Collaboration, hygiène d'architecture et tests

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Contenu verbatim, aucune réécriture.**
> Origine : lignes 3943-4130 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier porte la loi de ce sous-système : on l'ouvre **quand on travaille dedans**.
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

## Préférences de collaboration (durables — à respecter à chaque tâche)

- **Pas de README ni de docs générés automatiquement.** Ne créer un `.md` que si
  l'utilisateur le demande.
- 🛑 **Aucun test ni aucune mesure qui appelle un LLM payant sans demande explicite
  de l'utilisateur.** Vaut pour le banc de calibration (`CalibrationBenchTest`) et
  pour tout script qui interroge un fournisseur. C'est son argent. On propose la
  mesure et son coût estimé, il décide. Un smoke test d'un ou deux appels pour
  vérifier qu'une chaîne technique répond est toléré ; une campagne ne l'est pas.
  Avant de lancer une analyse, se demander d'abord si une **requête SQL sur la base
  locale** répond à la question — c'est gratuit, immédiat, et c'est le plus souvent
  le cas quand il s'agit de regarder ce que l'IA a réellement produit.
- **Code direct + brèves explications.** Pas de récap de fin de message ni de narration
  d'étapes triviales.
- **Décisions structurantes** : proposer des options avec leurs tradeoffs, pas imposer.
- **Pas de Tailwind utility-first dans le markup web** — Tailwind v4 sert uniquement aux
  tokens via `@theme`. Styles dans `globals.css` ou `<style>` JSX scoped.
- **Responsive obligatoire (web + admin)** : tout écran fonctionne du mobile (~360 px) au
  desktop. Tester mentalement 360 / 768 / 1280 minimum. Pas de largeur fixe en px sans
  `max-width: 100%`, pas de grilles à colonnes fixes sans `@media` de repli, pas de
  tableaux sans alternative carte sur petit écran.
- **Admin & runner** : pas d'UI kit, pas de CSS-in-JS, pas de `clsx`. CSS Modules vanilla.
- **Mobile** : Riverpod uniquement (pas de Bloc/Provider/GetX), `context.go/push`
  (jamais `Navigator.push`), `withValues(alpha:)` (pas `withOpacity`).
- **Tous** : TypeScript/Dart strict, pas de `any`/`dynamic`, imports relatifs, pas de
  commentaire qui paraphrase le code.

### Mode agent par défaut — Claude est l'ORCHESTRATEUR (non négociable)

**Toute demande de travail part dans un agent, jamais exécutée inline.** Claude principal ne
code pas, ne fouille pas, ne lit pas les fichiers en masse : il **délègue, suit et
synthétise**. Le but est que l'utilisateur puisse **enchaîner les demandes sans attendre**.

**Règle de dispatch — à appliquer à chaque nouveau message :**

1. **Nouvelle demande ⇒ nouvel agent.** On lance immédiatement, sans demander confirmation.
2. **Avant de lancer, vérifier les collisions** avec les agents **en cours** : même
   sous-projet ? mêmes fichiers ? même surface partagée (DTO, endpoint, règle métier, enum,
   rubrique de notation, migration) ?
   - **Aucune collision** → lancer **en parallèle** tout de suite. Plusieurs agents
     indépendants se lancent dans **un seul message** (appels d'outils groupés).
   - **Collision possible** → **file d'attente**. Ne pas lancer, annoncer explicitement à
     l'utilisateur : *« mis en attente, dépend de l'agent X en cours »*. Démarrer dès que
     l'agent bloquant a rendu.
   - **Dans le doute, on met en attente.** Deux agents qui éditent le même fichier =
     conflit silencieux, c'est le pire cas.
3. **Toujours annoncer l'état** en fin de réponse : ce qui tourne, ce qui attend et pourquoi.
4. **Isolation `worktree`** dès que deux agents écrivent en parallèle sur le même
   sous-projet et qu'on ne peut pas les séquencer.
5. **Modèle** : `opus` par défaut pour tout agent qui touche à une refonte, une règle métier
   ou plusieurs fichiers. `sonnet` acceptable pour les petits agents UI ciblés ou une
   recherche simple.
6. **Restitution** : le rapport d'un agent n'est pas montré à l'utilisateur. Claude en
   extrait **la conclusion utile**, pas les dumps de fichiers.

**Ce qui reste chez Claude principal** (ne pas déléguer) : les réponses conversationnelles et
les demandes de clarification, les **arbitrages et décisions** (on ne délègue pas un choix
produit), la synthèse des retours d'agents, et la mise à jour de ce fichier.

**Ce qui ne change pas** : un agent hérite de **toutes** les règles de ce CLAUDE.md et du
CLAUDE.md local de son sous-projet — parité web ⇄ mobile ⇄ admin, **tests backend dans la
même passe et aucun test front** (cf. § Tests), hygiène d'architecture, pas de `.md` non
demandé. C'est à Claude principal de le rappeler dans le prompt de l'agent et de **vérifier
à la restitution** que ça a été respecté — y compris qu'aucun agent front n'a créé de test.

### Hygiène d'architecture (non négociable)

La plateforme est faite pour durer, chaque ajout doit préserver une archi propre et
lisible — pas de patch rapide qui s'accumule.

- Tout nouveau fichier prend sa place dans l'arbo `feature/` existante (cf. CLAUDE.md
  local). Si une feature grossit, créer un dossier dédié.
- **Duplication = signal** : à la 2ᵉ occurrence, **extraire** un widget/util/service
  partagé (ex: `hub_widgets.dart`, `paywall_sheet.dart`). À 3 occurrences, c'est de la
  dette.
- **Refonte = suppression immédiate de l'ancien**. Quand un écran/route/composant est
  remplacé, supprimer le fichier + tous les imports + toutes les références CTA dans la
  foulée. Pas de cohabitation "au cas où".
- Respecter la convention de couches du backend Java et les conventions par sous-projet
  documentées dans chaque `CLAUDE.md` local. Pas d'exception "juste pour cette fois".
- **Parité mobile ⇄ web (non négociable)** : les 3 fronts consomment le **même backend** et
  le mobile et le web implémentent **les mêmes parcours** (examen blanc TCF complet, runner,
  productions EE/EO, paywall, freemium…). Toute modif d'une surface partagée — **endpoint**
  (chemin, **query params**, méthode, params devenus requis), **DTO**, **règle métier**,
  **enum** — doit être propagée et **vérifiée des deux (trois) côtés** dans la même passe.
  Avant de fermer une tâche, se demander explicitement : *« est-ce que ce changement casse
  l'autre front ? »* et le corriger s'il le faut. Exemple vécu : rendre `?epreuve=` requis
  sur `POST /api/full-tcf-exams/{id}/begin` côté backend aurait silencieusement figé le
  chrono web (appel best-effort avalé en 400) si le web n'avait pas été mis à jour en même
  temps. Quand un comportement est corrigé d'un côté (ex. ancrage de chrono), vérifier que le
  bug n'existe pas, ou n'a pas été réintroduit, de l'autre. Les miroirs DTO à tenir à jour :
  `admin_sejourfr/src/types/api.ts`, `web_sejoufr/lib/types.ts`, `mobile_sejourfr/lib/core/models/*.dart`.
- **Tout bugfix sur une surface partagée se synchronise sur l'autre front (impératif)** :
  dès qu'on corrige un bug côté **mobile** OU **web** sur un parcours commun (freemium,
  paywall, runner, examens, productions EE/EO, chrono…), il faut **systématiquement**
  vérifier le même comportement de l'autre côté et l'aligner dans la **même passe** —
  soit le bug y existe aussi (le corriger), soit il y était déjà correct (s'en servir de
  référence et ne rien casser). Les deux fronts doivent rester **synchronisés en
  permanence** : aucun fix ne se ferme sans s'être posé la question « web et mobile font-ils
  exactement pareil maintenant, sans régression ? ». Exemple vécu : le slot 1 des examens
  blancs module TCF (CO/CE/STRUCTURE) était bloqué par le paywall sur mobile alors que le
  web l'autorisait déjà (rejouable à volonté) — le fix a aligné mobile + backend sur le
  comportement web, pas l'inverse.

### Tests — BACKEND UNIQUEMENT (règle posée le 2026-08-09)

🛑 **On n'écrit plus AUCUN test sur les fronts.** Ni `web_sejoufr`, ni `admin_sejourfr`, ni
`mobile_sejourfr` : pas de `*.test.ts`, pas de `flutter_test`, pas de test de widget, pas de
test de libellé gelé, pas de test de layout. **Les seuls tests du dépôt sont ceux du
backend**, unitaires (`*Test`) et d'intégration (`*IT`). Cette règle **prime** sur toute
consigne de test écrite ailleurs dans ce fichier ou dans un `CLAUDE.md` local, et sur
l'habitude « tests dans la même passe » — qui ne vaut désormais **que** pour le backend.

> ✅ **Amendé le 2026-09-10 par le propriétaire.** La règle reste « **aucun NOUVEAU**
> test front », mais **les 41 tests déjà versionnés sont conservés** et doivent rester
> verts — la formulation « les seuls tests du dépôt sont ceux du backend » était
> contredite par le dépôt lui-même. Aucune suppression en masse ; un test part **avec le
> code qu'il testait**, jamais seul. Détail et motif :
> `docs/decisions/contradictions-ouvertes.md` #2.

Ce que ça implique concrètement :

- Un changement purement front (écran, style, libellé, composant, provider, routing) se
  ferme **sans test**. On vérifie par `npx tsc --noEmit` / `npm run build` côté web et admin,
  `flutter analyze` côté mobile — la compilation et l'analyse statique, rien de plus.
- **Ne pas créer** de nouveau fichier de test front, même « juste pour geler un libellé ».
  Les libellés miroirs (`SKILL_*_LABEL`, statuts du plan, verdicts de production…) restent à
  tenir à la main dans la même passe, mais leur **respect ne se vérifie plus par un test** :
  c'est une relecture, pas une assertion.
- **Les tests front existants ne sont pas supprimés d'office** (ils tournent, ils sont verts,
  les jeter est une passe à part). En revanche on ne les étend plus, et un test front qui
  devient rouge à cause d'un changement voulu se **met à jour ou se supprime** — il ne
  justifie jamais de renoncer au changement.
- La parité web ⇄ mobile ⇄ admin reste **non négociable** : elle se vérifie désormais par
  lecture croisée des deux implémentations, pas par un test de chaque côté.

**Le backend, lui, ne bouge pas d'un pouce** : tout code ajouté ou modifié y est couvert par
des tests **dans la même passe**. Une feature, un bugfix, une règle métier, un endpoint, une
migration à impact logique ne se ferment pas sans test(s) qui verrouillent le comportement.
Avant un refactor d'un bloc existant non couvert : écrire d'abord le filet de tests, puis
refactorer. Pas d'exception « je testerai plus tard ».

C'est là que le raisonnement tient : le backend est la **source de vérité** des DTO, des
règles métier et du freemium ; un test qui y fige une règle protège les trois fronts d'un
seul endroit, alors qu'un test front ne protège qu'une surface d'affichage — la moins
coûteuse à corriger, et celle que le propriétaire vérifie lui-même à l'écran.

Bonnes pratiques pour ce projet (cf. `docs/plan-tests-backend.md`, infra déjà en place) :

- **Lancer la suite** : `./mvnw verify` (unitaires `*Test` via surefire + intégration `*IT`
  via failsafe). Le build doit rester **vert** — un commit ne part pas sur du rouge.
- **Choisir la bonne granularité** :
  - *Unitaire* (`*Test`, Mockito) par défaut pour la logique métier, les branches, les
    validations, le mapping, les appels à des clients externes (toujours **mockés**, jamais
    de vrai réseau). Gabarit : `FullTcfExamServiceFreemiumTest`, `AiEvaluationServiceTest`.
  - *Intégration* (`*IT extends AbstractIntegrationTest`) quand le cas traverse réellement
    la base (requêtes JPA, specifications, contraintes, transactions). Tourne sur un
    **Postgres embarqué** (Zonky, pas de Docker) qui applique les **vraies migrations
    Flyway** → toute contrainte (NOT NULL, FK, CHECK, index unique) est vérifiée pour de
    vrai, et `ddl-auto: validate` valide le mapping JPA.
- **Tester chaque couche** : manager → `*ManagerIT` (vrai PG) ; service → unitaire ou IT ;
  controller → **droits** via la matrice (`AdminRoutes/AuthenticatedRoutes/PublicRoutesSecurityIT`,
  401 anonyme / 403 mauvais rôle / 200 rôle attendu, avec un vrai JWT) **et** comportement ;
  mapper → unitaire pur ; specification → `*IT`. Un nouvel endpoint admin s'ajoute à la
  matrice de droits.
- **Seeder via `TestData`** (fabriques de toutes les entités, déjà validées) plutôt que de
  bâtir les entités à la main — les fabriques respectent toutes les contraintes du schéma.
- **Assertions tolérantes au seed Flyway** : les tables seedées (questions, production_tasks,
  exam_templates, audio_question_drafts) contiennent déjà des lignes → filtrer aux ids créés
  dans le test ou raisonner en delta, **jamais** de total exact sur une table seedée.
- **Pièges connus** : `repository.save()` ne flushe pas (une violation de contrainte passe
  inaperçue → utiliser `saveAndFlush` quand on veut l'attraper) ; ordre `id ASC` Postgres
  (uuid non signé) ≠ `Comparator<UUID>` Java (signé) ; `when(x).thenReturn(helperQuiMock(...))`
  → `UnfinishedStubbing` (extraire le mock en variable avant le `thenReturn`).
- **Parité fronts** : un test backend qui fige une règle partagée (freemium, quotas, droits)
  est le garde-fou de la cohérence mobile ⇄ web — le maintenir à jour quand la règle évolue.

### Maintenir les `CLAUDE.md` à jour

Après une modif structurante (nouvelle feature, nouveau pipeline, changement de convention,
nouvelle migration importante, nouveau dossier `features/*`), mettre à jour le CLAUDE.md
local concerné et celui de la racine si la modif est transverse. Pas de changelog
exhaustif — juste de quoi qu'un futur Claude se repère vite. Inutile d'y consigner les
bugfixes ou les micro-ajustements.

**Exception — la doc de notation IA doit TOUJOURS être exhaustive et à jour.**
`docs/notation-ia-eo-ee.md` est la référence grand public (compréhensible par un
non-informaticien) de la façon dont l'IA note les productions EE/EO. Contrairement aux
CLAUDE.md, elle **n'est pas** un simple aide-mémoire : elle doit rester **complète et
exacte**. Dès qu'on touche une **règle de notation, un barème, un poids de critère, une
consigne donnée à l'IA** (`production-rubrics-*.json`, `production-evaluation-tool-schema-*.json`),
**une tâche EE/EO**, ou le **comportement de l'examinateur vocal** (`realtime-personas-*.json`,
config VAD), on met à jour ce fichier **dans la même passe**, en gardant un langage clair et
sans jargon non expliqué. Ce n'est pas un « bugfix à ne pas consigner » : c'est une exigence.


---

## Annexe — « Architecture mentale par projet » (verbatim)

> Origine : lignes 3904-3942 de l'ancien `CLAUDE.md` racine. Conservé **verbatim** ici pour
> qu'aucun char ne se perde à la restructuration du 2026-08-23. La forme courte vit dans le
> `CLAUDE.md` racine (§ *Conventions par sous-projet*) et la convention de couches, développée,
> dans `backend_sejourfr/CLAUDE.md`. ⚠️ Les listes de dossiers ci-dessous datent de mai 2026 et
> n'ont pas suivi les chantiers Plan/Diagnostic/Analytics : le `CLAUDE.md` local de chaque
> sous-projet fait foi.

## Architecture mentale par projet

Tous les fronts suivent l'organisation par feature (miroir du backend Java) :

- **Backend Java** : `entity/`, `repository/`, `manager/`, `service/`, `controller/`,
  `dto/`, `mapper/`, `specification/`, `security/`, `config/`, `exception/`, `enums/`
  (+ sous-module historique `audioquestion/` à part)
- **Admin React** : `features/{questions,themes,conversations,dashboard}/` + `api/`,
  `auth/`, `components/ui/`, `routes/`, `types/`
- **Web Next** : `app/{inscription,connexion,examen-blanc,paiement}/` + `app/_components/`
  + `lib/{api,types}.ts`
- **Mobile Flutter** : `screens/{auth,home,training,exam,question_runner,review,profile,…}/`
  + `core/{api,auth,models,router,theme,utils,widgets}/`

Le **runner de questions** (mobile `screens/question_runner/` et web
`examen-blanc/page.tsx`) est le composant le plus complexe — relire son CLAUDE.md local
avant de toucher.

### Convention backend Java : Controller → Service → Manager → Repository (strict)

- **Controllers** : ultra-fins, délèguent tout au service. Pas de logique, pas de mapping
  inline, pas d'accès repo. `@RequiredArgsConstructor` Lombok.
- **Services** : orchestrent un cas d'usage (validations, règles métier, transactions,
  mapping DTO). N'accèdent JAMAIS un `*Repository` directement — passent par les managers.
  Un service peut appeler plusieurs managers et d'autres services.
- **Managers** (`manager/`) : seule couche autorisée à appeler les `*Repository`. Wrappent
  JPA et exposent une API métier. Un manager par agrégat, même pour du CRUD trivial. `int
  limit` au lieu de `Pageable` quand suffisant ; `Specification + Pageable` quand la
  recherche est dynamique.
- **Mappers** : `@Component`, purs. Reçoivent l'entité + compléments en paramètres,
  retournent un DTO. Ne touchent ni repo ni manager. Si un mapping a besoin d'une lookup,
  le service la fait avant.
- **Lombok** : `@RequiredArgsConstructor` sur tous les controllers/services/managers/mappers.
  `@Slf4j` au lieu du `LoggerFactory.getLogger(...)`. Sur les entités JPA : `@Getter/@Setter`
  OK, **jamais `@Data`** ni `@EqualsAndHashCode` automatique (toString/equals + lazy loading
  = bugs).
- **Exception** : `audioquestion/` est un sous-module isolé non migré (refacto reportée).
  Ses services peuvent encore appeler `MediaRepository` direct.

