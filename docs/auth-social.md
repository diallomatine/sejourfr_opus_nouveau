# Social sign-in (Google web/Android, Apple iOS)

Le backend expose deux endpoints qui valident un ID token externe et ouvrent une session
SejourFR (création automatique du compte s'il n'existe pas) :

- `POST /api/auth/google` — body `{ idToken }`. Web : token issu de Google Identity Services
  (`window.google.accounts.id`). Mobile : token issu de `google_sign_in` (le `serverClientId`
  doit être le **Web client ID** pour que l'audience matche).
- `POST /api/auth/apple` — body `{ identityToken, firstName?, lastName? }`. iOS uniquement,
  via `sign_in_with_apple`. Le nom n'est renvoyé par Apple qu'au tout premier consent, on le
  passe donc au backend pour peupler le profil à la création.

## Validation côté Java (`service/social/`)

- `GoogleTokenVerifier` / `AppleTokenVerifier` (interface `SocialTokenVerifier`) — Nimbus
  JOSE + JWKS cachées (`RemoteJWKSet` 9.40). Vérifie signature RS256, issuer
  (`accounts.google.com` ou `https://accounts.google.com` pour Google ;
  `https://appleid.apple.com` pour Apple), audience (whitelist via
  `sejourfr.oauth.{google|apple}.audiences`), expiration, et `email_verified` pour Google.
- `SocialAuthService` : find-or-create. Lookup par `(provider, providerUserId)` d'abord,
  fallback par email (lie le compte existant à la session sans muter `auth_provider`).
- `SocialAuthController` (`/api/auth/{google,apple}`). 503 quand les audiences ne sont pas
  configurées — le bouton mobile/web est aussi masqué quand la config locale est absente,
  donc ce 503 ne devrait apparaître que si un client est mal aligné avec le backend.

## Schema

Migration `V093__users_auth_provider.sql` ajoute `auth_provider VARCHAR(16) NOT NULL
DEFAULT 'LOCAL'` + `provider_user_id VARCHAR(255)` + rend `password_hash` nullable (comptes
sociaux n'ont pas de mdp) + index unique partiel `(auth_provider, provider_user_id)` WHERE
provider_user_id IS NOT NULL.

## Conflit email (choix produit)

Si on tente de se connecter via Google et qu'un compte existe déjà avec ce même email
(créé via mot de passe ou Apple), on **lie automatiquement** la session au compte existant
sans muter `auth_provider` (= moyen de création, immutable). L'utilisateur peut donc avoir
un compte qu'il a créé en LOCAL et se reconnecter via Google sans frottement.

## Config env (clés à fournir, vide par défaut → providers désactivés)

- Backend : `GOOGLE_OAUTH_AUDIENCES=comma,separated` ·
  `APPLE_OAUTH_AUDIENCES=com.sejourfr.app` · `APPLE_TEAM_ID=ABCDE12345`
- Web : `NEXT_PUBLIC_GOOGLE_CLIENT_ID=xxx-xxx.apps.googleusercontent.com` (le Web client)
- Mobile : `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` (Web client, passé en
  `serverClientId`) · `--dart-define=GOOGLE_IOS_CLIENT_ID=...` (iOS client, pour le URL
  scheme).
- iOS natif : `Info.plist` contient un `CFBundleURLTypes` avec
  `com.googleusercontent.apps.<REVERSED_IOS_CLIENT_ID>` (à remplir une fois le Client iOS
  créé). `Runner.entitlements` contient `com.apple.developer.applesignin` — à activer aussi
  via Xcode (Capability "Sign in with Apple") et sur l'App ID dans Apple Developer Portal.

## Côté front

- **Web** : composant `web_sejoufr/app/_components/GoogleSignInButton.tsx` (charge
  `gsi/client`, rend le bouton officiel, POST `authApi.google` puis `refreshUser`). Branché
  sur `/connexion` et `/inscription`. Pas d'Apple sur web pour l'instant (parité demandée :
  Apple uniquement iOS).
- **Mobile** : `core/auth/social_sign_in_service.dart` encapsule `google_sign_in` +
  `sign_in_with_apple`. `core/auth/auth_controller.dart` expose `loginWithGoogle()` et
  `loginWithApple()`. Widget réutilisable `screens/auth/widgets/social_auth_buttons.dart`
  (Google partout, Apple iOS seul via `Platform.isIOS`), branché dans login + register.
  Logout fait aussi un `signOutAll()` Google pour vider la session native (sinon le
  prochain signIn() réutilise silencieusement le dernier compte).
