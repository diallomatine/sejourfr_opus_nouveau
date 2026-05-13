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
│   ├── dashboard/
│   ├── questions/           Le plus complexe : liste + filtres + modal CRUD
│   ├── themes/
│   └── conversations/       Vue split list/detail style "boîte mail"
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

## Démarrage en local

```bash
npm install
npm run dev
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
- **Abonnements** : suivi des plans, paiements
- **Upload de médias** dans le formulaire de question : l'endpoint `/api/admin/media/upload` existe côté backend mais pas encore intégré dans le formulaire. À ajouter quand on aura des questions avec audio/image (TCF compréhension orale notamment).
- **Statistiques par utilisateur** : taux de réussite, progression, etc.

## Pistes d'évolution

- Quand les écrans **clients** et **abonnements** seront ajoutés, créer `features/users/` et `features/subscriptions/` sur le même modèle.
- Pour l'upload de médias dans le formulaire question : ajouter un composant `MediaPicker` qui appelle `POST /api/admin/media/upload` (multipart) ou `POST /api/admin/media/from-url`, puis remplit `mediaId` dans le `QuestionWriteRequest`.
- Si la pagination des questions devient lourde, envisager un `useInfiniteQuery` plutôt que des boutons précédent/suivant.
- Tests : aucun pour l'instant. Quand on en ajoutera, partir sur Vitest + React Testing Library.
