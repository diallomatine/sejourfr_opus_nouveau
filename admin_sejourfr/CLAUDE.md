# SejourFR Admin — Guide pour Claude Code

Ce projet est l'espace d'administration web de **SejourFR**, une plateforme d'entraînement aux examens civique et TCF pour étrangers en France. Cette console est destinée aux administrateurs qui gèrent le contenu pédagogique (questions, thématiques) et les échanges avec les utilisateurs.

## Stack technique

- **React 19** (dernière version)
- **TypeScript** (mode strict)
- **Vite** (dev server + build)
- **React Router 7** pour le routing
- **TanStack Query 5** pour le state serveur (fetch, cache, invalidation)
- **React Hook Form** pour les formulaires
- **CSS Modules** vanilla — **pas de Tailwind, pas de CSS-in-JS, pas d'UI kit**

La palette de couleurs et la typographie reprennent l'identité SejourFR : bleu France (`#1E3A8F`), rouge France (`#E1252C`), polices Fraunces (titres) / Inter (corps) / JetBrains Mono (labels techniques).

## Architecture

Le projet suit une **organisation par feature**, comme le backend Spring Boot :

```
src/
├── App.tsx                  Routing principal
├── main.tsx                 Entry point
├── api/                     Couche HTTP (un fichier par domaine)
│   ├── http.ts              Client HTTP central + refresh JWT automatique
│   ├── authApi.ts
│   ├── dashboardApi.ts
│   ├── questionsApi.ts
│   ├── themesApi.ts
│   └── conversationsApi.ts
├── auth/                    Authentification
│   ├── AuthContext.tsx      Provider + hook useAuth()
│   └── tokenStorage.ts      Persistance localStorage des tokens
├── components/
│   ├── layout/AppLayout.*   Sidebar + main outlet (visible quand connecté)
│   └── ui/                  Primitives réutilisables (Button, Modal, Tag, etc.)
├── features/                Une feature = un dossier (entité + UI + helpers)
│   ├── audience/            Audience des landings (/reussir) : vues, clics CTA,
│   │                        taux de clic par réseau, série journalière. Lecture
│   │                        seule, compteur agrégé sans traceur (cf. racine)
│   ├── dashboard/
│   ├── questions/           Le plus complexe : liste + filtres + modal CRUD
│   ├── themes/
│   ├── conversations/       Vue split list/detail style "boîte mail".
│   │                        Alimentée par le formulaire de contact public
│   │                        (backend ContactService → ConversationService.
│   │                        createFromContact) : chaque message devient une
│   │                        conversation. Supporte les invités sans compte
│   │                        (userId/authorId null → coordonnées dans
│   │                        userEmail/userFullName). « Répondre » envoie un
│   │                        email au contact (MailService, Reply-To support).
│   ├── calibration/         Calibration de la notation IA EO/EE : bandeau de
│   │                        santé (biais vs dispersion), liste des productions
│   │                        évaluées, fiche de détail + annotation humaine
│   ├── skills/              Compétences TCF EE/EO : contenu éditorial (48
│   │                        compétences, 240 petits sujets, 720 références).
│   │                        Liste filtrée + détail + modals sujet/références
│   │                        + statistiques d'usage
│   ├── audioQuestions/      Génération assistée TCF CO : form + preview + audit
│   │                        (modes WRITTEN_QUESTION / FULL_AUDIO — cf CLAUDE.md racine)
│   └── exampleAudio/        Génération batch + validation des audios des exemples
│                            EO (Expression Orale) — Azure Speech + R2 réutilisés
├── lib/
│   └── queryClient.ts       Config TanStack Query
├── pages/
│   └── LoginPage.tsx        Page hors layout, accessible publiquement
├── routes/
│   └── ProtectedRoute.tsx   Garde d'auth pour les routes admin
├── styles/global.css        Variables CSS + polices Google Fonts
└── types/api.ts             Tous les DTO miroirs du backend
```

**Règle simple** : si une feature a son entité backend (`questions/`, `themes/`, `conversations/`...), elle a son dossier dans `features/`. Les composants partagés sont dans `components/ui/`. La couche réseau est isolée dans `api/`.

## Backend

L'API Java/Spring Boot 4 tourne en parallèle (par défaut `http://localhost:8080`). Le contrat est documenté dans le projet backend correspondant. Les types TypeScript dans `src/types/api.ts` sont **alignés à la main** sur les DTO Java — quand le backend change, mettre à jour ce fichier.

Endpoints utilisés actuellement :
- `POST /api/auth/login`, `POST /api/auth/refresh`, `GET /api/auth/me`
- `GET /api/admin/dashboard`
- `GET|POST|PUT|PATCH|DELETE /api/admin/questions[/{id}[/status]]`
- `GET|POST|PUT|DELETE /api/admin/themes[/{id}]`
- `GET|POST|PATCH|DELETE /api/admin/conversations[/{id}[/reply|mark-read|status]]`
- `GET /api/admin/conversations/unread-count`
- `POST|GET|PATCH|DELETE /api/admin/audio-questions[/{id}[/preview|validate]]` + `GET /api/admin/audio-questions/generation-logs`
- `POST /api/admin/production/examples/audio/batch-generate?size=10`, `GET …/pending/count`, `GET …/to-review`, `POST …/{id}/publish`, `POST …/{id}/regenerate` (audios exemples EO — feature `exampleAudio/`)
- `GET /api/admin/page-views?path=…&days=…` + `GET /api/admin/page-views/paths`
  — audience des landings (feature `audience/`)
- `GET /api/admin/plans`, `PATCH /api/admin/plans/{id}` (commerce — lot 4c)
- `GET /api/admin/subscriptions?source=…&status=…&moduleAccess=…&search=…&page=…&size=…` (lot 4c)
- `POST /api/admin/subscriptions/{id}/cancel` — annulation manuelle (support).
  Stripe → DONE ; Apple/Google → REDIRECT (l'admin copie l'URL pour la transmettre).
- `PATCH /api/admin/subscriptions/{id}/realtime-sessions` `{ remaining }` — pose le
  solde de sessions EO temps réel du pass (support : offrir/corriger des sessions).
- `GET|POST|PUT|PATCH|DELETE /api/admin/questions[…]` — la liste accepte
  `?media=AUDIO|IMAGE|VIDEO|NONE` (majuscules), **filtre serveur** : ne jamais
  refiltrer la page courante côté navigateur, le compteur et la pagination
  deviendraient faux.
- `GET /api/admin/calibration/submissions?status=evaluated&hasHumanNote=…&limit=…`,
  `GET|POST /api/admin/calibration/submissions/{id}/human-note`,
  `GET /api/admin/calibration/stats`, `GET /api/admin/calibration/stats/niveau`
  (feature `calibration/`)
- `GET|POST|PATCH|DELETE /api/admin/skills[/{id}]`, `GET /api/admin/skills/stats?section=`,
  `GET|POST|PATCH|DELETE /api/admin/skill-prompts[/{id}]`,
  `PUT /api/admin/skill-prompts/{id}/references` (feature `skills/` — module
  Compétences TCF, §6 du contrat gelé)
- `GET /api/production-tasks?epreuve=TCF_EE|TCF_EO` — catalogue des sujets, utilisé
  pour retrouver l'épreuve et la consigne d'une soumission (le DTO submission ne
  porte que `productionTaskId`). Route authentifiée, pas `/api/admin/**`.

### Compétences TCF EE/EO (`features/skills/`)

Console d'édition du **contenu** du module Compétences (48 compétences × 5 petits
sujets × 3 références). Ce contenu est éditorial et vit en base : sans cet écran,
corriger une faute de frappe dans un sujet imposerait une migration Flyway.

- **Routes** : `/skills` (liste paginée, filtres `section` / `taskCode` / `active`
  + recherche `q` debouncée 300 ms), `/skills/stats` (usage), `/skills/:id`
  (détail + petits sujets). Le sujet et ses références s'éditent en **modal**
  depuis le détail, pas sur une route à part.
- **Deux textes distincts sur une compétence**, tous deux obligatoires et
  `NOT NULL` en base : `description` (courte explication adressée au candidat —
  ce qu'il travaille et pourquoi ça compte au TCF) et `generalCriterion` (le
  critère général, ce qui sera observé dans les 5 petits sujets). Ne pas
  confondre ce dernier avec `AdminSkillPromptDto.uniqueCriterion`, qui ne vaut
  que pour **un** sujet. Le `POST` échoue en 400 sans `generalCriterion` ; le
  `PATCH` tolère l'absence (« ne touche pas »), mais le front envoie toujours
  les deux. Le détail les affiche sous deux intitulés séparés.
- **`code` immuable** (compétence et sujet) : affiché en encart figé
  « non modifiable » dès qu'on est en modification. Les seeds s'appuient dessus.
- **Bornes de longueur pilotées par la section** : `EE` exige `recommendedMinWords`
  **et** `recommendedMaxWords` (min < max) et interdit
  `recommendedDurationSeconds` ; `EO` l'inverse. Le formulaire n'affiche **que**
  le jeu autorisé et construit la charge utile depuis la section de la compétence
  parente, jamais depuis l'état du formulaire — la base porte un CHECK, l'erreur
  doit être impossible côté UI plutôt que renvoyée en 500.
- **Les 3 références partent ensemble** (`PUT`, remplacement atomique, 3 niveaux
  exigés sans doublon) : la modal ne permet ni d'ajouter ni de retirer un niveau,
  et refuse de soumettre tant qu'un texte ou une note manque.
- **Désactiver, pas supprimer** : le `DELETE` répond `409` dès qu'une tentative
  candidat référence l'élément. La suppression est reléguée en bas de page, et le
  409 est traduit en clair (« des candidats ont déjà travaillé ce sujet… »).
- **`queryKey`** : `["adminSkills", filters]`, `["adminSkills", "detail", id]`,
  `["adminSkills", "stats", section]`, `["adminSkillPrompts", "detail", id]`.
  Toute mutation invalide `["adminSkills"]` (préfixe → liste, détail et stats) ;
  les mutations de sujet invalident en plus `["adminSkillPrompts"]`, ce qui
  rafraîchit bien la compétence parente (`promptCount`).
- Les modals de sujet et de références **rechargent le sujet** par
  `GET /api/admin/skill-prompts/{id}` au lieu de se fier au payload du détail :
  un seul endroit garantit d'avoir le contexte, la consigne et les 3 références
  complets.

### Calibration de la notation IA (`features/calibration/`)

Écran qui répond à « est-ce que l'IA note juste ? ». Un correcteur annote de
vraies productions, le bandeau mesure l'écart avec l'IA.

- **Convention de signe du backend** : `écart = note humaine − note IA`. Donc
  `ecartMoyen` **négatif** = l'IA note au-dessus du correcteur = **trop
  indulgente**. Contre-intuitif : l'écran l'écrit toujours en toutes lettres,
  jamais en brut. `ecartMoyen` = biais (dans quel sens), `ecartMoyenAbsolu` =
  dispersion (de combien) — deux cartes distinctes, avec la formule affichée.
- `hasHumanNote=true|false` filtre réellement côté backend (annotées /
  non-annotées) ; l'écran appelle chaque onglet avec le bon paramètre, sans
  reconstitution côté front. `GET .../submissions/{id}/human-note` relit la
  **dernière** note humaine d'une soumission (404 = jamais annotée, traité
  comme `null`, pas comme une erreur) : à l'ouverture d'une production le
  formulaire d'annotation se pré-remplit avec cette note et l'écart IA/humain
  s'affiche immédiatement. Réenregistrer **ajoute** une observation (pas de
  contrainte d'unicité en base) au lieu de remplacer — le tableau de bord ne
  compte que la plus récente par soumission, donc réannoter ne fausse pas la
  statistique.
- **Version de grille** : la liste renvoie des `CalibrationSubmissionDto`
  (`{ submission, rubricsVersion, promptVersion }`), pas des
  `ProductionSubmissionDto` bruts. Une note produite avec la grille v3 et une
  note v4.2 ne se comparent pas, donc la fiche affiche « Grille v4.2 » à côté
  du badge de format ; `rubricsVersion` null (colonne ajoutée en V022) donne
  « Grille inconnue », pas une erreur. Ces deux versions vivent dans un DTO
  **admin** : ne pas les remonter dans `ProductionSubmissionDto` /
  `EvaluationResultDto`, partagés avec le web et le mobile.
- **Rétrocompatibilité v3** : `niveauObserve` / `confiance` / `avertissementNiveau`
  à null, pas de `bande`, `preuve` ni `accomplissement`, code de critère
  `pertinence` disparu en v4. Chaque bloc se masque si absent — l'absence est un
  cas normal. `isLegacyEvaluation()` pose un badge « format v3 ».

**Authentification** : JWT Bearer dans l'en-tête `Authorization`. Le refresh est automatique côté `http.ts` quand une requête prend un 401 — pas besoin de le gérer dans les composants.

## Conventions de code

**Style général**
- TypeScript strict, pas de `any`. Utiliser les types de `types/api.ts`.
- Noms de composants en `PascalCase`, hooks en `useXxx`, fichiers en `PascalCase.tsx` pour les composants.
- Imports relatifs (pas d'alias `@/`).
- Pas de commentaires inutiles. Code expressif d'abord.

**Style des composants**
- Composants fonctionnels uniquement.
- Pas de `React.FC`, on type les props directement avec une interface.
- Un fichier `.tsx` + un fichier `.module.css` à côté quand il y a du style.
- Pour les classes conditionnelles, faire `` `${styles.a} ${cond ? styles.b : ""}` ``, pas de lib `clsx`.

**Données serveur**
- **Toujours** passer par TanStack Query (`useQuery` pour la lecture, `useMutation` pour l'écriture).
- Les `queryKey` suivent une convention : `["resource", paramsObj]` ou `["resource", "subresource", id]`.
- Après une mutation, invalider les `queryKey` impactées via `queryClient.invalidateQueries`.
- Les erreurs sont remontées par `HttpError` (status + message).

**Formulaires**
- React Hook Form pour tout formulaire non trivial (`useForm`, `useFieldArray`).
- Validation simple via les options de `register` (required, etc.). Si on a besoin de plus complexe, on ajoutera Zod plus tard.

**UI**
- Les couleurs sont dans `:root` de `styles/global.css`. **Ne jamais hardcoder une couleur** dans un module — toujours utiliser `var(--blue)`, `var(--red)`, `var(--ink)`, etc.
- Polices fixées : `Fraunces` pour les titres (`.page-title`, `.panel-title`), `Inter` partout ailleurs, `JetBrains Mono` pour les labels techniques (eyebrows, badges, tags).
- Le style général s'inspire du template `admin__1_.html` fourni en début de projet — typographique, fait main, sans framework UI.
- **Tableaux** : envelopper la `<table>` dans `<div className={tableStyles.tableWrap}>` et
  ajouter `tableStyles.cardTable` à la table, tous deux dans
  `components/ui/DataTable.module.css`. `tableWrap` donne le défilement horizontal (les
  `Panel` sont en `overflow: hidden`, sans lui les colonnes de droite sont rognées) ;
  `cardTable` bascule chaque ligne en fiche empilée sous 720 px, chaque cellule étant
  préfixée par l'intitulé de sa colonne — donc **chaque `<td>` porte un `data-label`**
  (sauf la 1ʳᵉ colonne, titre de la fiche, et la dernière, actions de ligne). Ne pas
  redupliquer ce bloc dans un module de feature : il y était recopié 5 fois avant d'être
  remonté.

**Hygiène (rappel transverse, cf. CLAUDE.md racine)**
- Toute nouvelle feature prend son dossier dans `features/` (jamais à côté d'une feature voisine). Si un sous-composant n'a de sens que dans une feature, il vit dans `features/<feature>/components/`, pas dans `components/ui/`.
- Composant ou hook dupliqué dans 2 features ? Le **remonter** dans `components/ui/` ou `lib/`. À la 2ᵉ duplication, pas à la 3ᵉ.
- Quand un écran est remplacé : supprimer le `.tsx` + le `.module.css` + la route dans `routes/` + tous les `Link to=` et `navigate(...)` qui le ciblaient. Pas de cohabitation. Faire un grep sur le nom du composant et du path avant de fermer le lot.
- `queryKey` cohérents avec la convention `["resource", ...]` documentée — toute nouvelle ressource passe par le même schéma. Pas d'invention locale qui complique les `invalidateQueries`.
- Mettre à jour ce CLAUDE.md en même temps que les modifs structurantes (nouvelle feature, nouveau provider, nouvelle convention). Pas de PR qui change l'archi sans synchroniser la doc.

## Démarrage en local

```bash
npm install
npm run dev-admin   # ⚠️ le script s'appelle "dev-admin", pas "dev"
```

Par défaut, le client tape sur `http://localhost:8080`. Pour pointer ailleurs :

```bash
echo 'VITE_API_BASE_URL=http://localhost:9090' > .env.local
```

Comptes admin (en dev, ils sont dans le seed Flyway du backend) :
- `admin@sejourfr.fr` / `Admin123!`

## Roadmap (ce qui n'est pas encore branché)

Pas encore d'API côté backend, donc pas implémenté ici :
- **Clients / utilisateurs** : liste, détail, désactivation
- **Upload de médias** dans le formulaire de question : l'endpoint `/api/admin/media/upload` existe côté backend mais pas encore intégré dans le formulaire. À ajouter quand on aura des questions avec audio/image (TCF compréhension orale notamment).
- **Statistiques par utilisateur** : taux de réussite, progression, etc.

**Commerce (lot 4c ✅ fait)** :
- `features/plans/` — tableau des Plans (FREE + 6 SKUs récurrents) avec
  modal d'édition. Champs éditables : prix, prix barré (originalPrice),
  active, stripePriceId, appleProductId, googleProductId. Garde anti-incohérence
  côté backend : un plan payant actif doit avoir au moins un SKU renseigné.
  Les Plans sont créés en migration Flyway (V100/V106) — pas de POST/DELETE
  côté admin.
- `features/subscriptions/` — liste paginée des UserSubscription, filtres
  source/status/moduleAccess + recherche email+nom (debounced 300ms),
  pagination prev/next. Tri par updatedAt desc. Modal détail montrant tous
  les transactionIds, dates, plan, montant. Trois sources possibles : Stripe
  (web), Apple (iOS), Google (Android) — cf. CLAUDE.md racine pour le schéma.
  Modal détail : bouton **Résilier l'abonnement** (variant danger) actif uniquement
  pour les statuts ACTIVE/TRIAL/IN_GRACE. Appelle `subscriptionsApi.cancel(id)` →
  invalide `["adminSubscriptions"]`. Bandeau de feedback en bas de modal :
  vert pour DONE (Stripe), ambre pour REDIRECT (Apple/Google) avec l'URL à
  copier-coller au client, rouge si erreur.
  Modal détail : champ **Sessions temps réel (EO)** éditable (input + Enregistrer)
  → `subscriptionsApi.setRealtimeSessions(id, remaining)` (PATCH) → invalide
  `["adminSubscriptions"]`. C'est le solde `user_subscriptions.realtime_eo_sessions_remaining`
  (posé à la souscription = `plans.realtime_eo_sessions`, cumulé à la prolongation,
  débité à chaque session temps réel).

## Pistes d'évolution

- Quand l'écran **clients** sera ajouté, créer `features/users/` sur le même modèle (`features/subscriptions/` existe depuis le lot 4c).
- Pour l'upload de médias dans le formulaire question : ajouter un composant `MediaPicker` qui appelle `POST /api/admin/media/upload` (multipart) ou `POST /api/admin/media/from-url`, puis remplit `mediaId` dans le `QuestionWriteRequest`.
- Si la pagination des questions devient lourde, envisager un `useInfiniteQuery` plutôt que des boutons précédent/suivant.
- Tests : aucun pour l'instant. Quand on en ajoutera, partir sur Vitest + React Testing Library.
