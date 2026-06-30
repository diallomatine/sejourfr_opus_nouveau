# CHANGELOG sécurité — SejourFR

Correctifs issus de l'audit (`SECURITY_AUDIT_REPORT.md`). Un bloc par batch.

---

## Phase 1 · Batch A — Rate-limiting (BE-01, BE-02, BE-03)

**Objectif** : couper l'abus automatisé sur les surfaces coûteuses ou floodables
(facture LLM, brute force auth, inflation DB). Garde-fous **généreux** (pas de gêne
pour un usage réel), entièrement configurables, désactivables via `RATE_LIMIT_ENABLED=false`.

**Mécanisme** : rate-limiter en mémoire à fenêtre fixe (Caffeine, déjà au classpath),
exception `429 Too Many Requests` + header `Retry-After`. Mono-instance (un seul process
backend aujourd'hui) — à migrer vers Redis / reverse-proxy si passage multi-instance.

### Nouveaux fichiers
- `config/RateLimitProperties.java` — seuils par surface (`sejourfr.rate-limit.*`) + `enabled`.
- `ratelimit/InMemoryRateLimiter.java` — compteur fenêtre fixe, Caffeine, thread-safe.
- `ratelimit/RateLimitGuard.java` — façade métier (une méthode par surface).
- `exception/RateLimitException.java` — 429 + `Retry-After` (distincte de celle du sous-module `audioquestion`).

### Fichiers modifiés
- `exception/GlobalExceptionHandler.java` — handler `RateLimitException` → 429 + `Retry-After`.
- `controller/AuthController.java` — `login` (IP + compte), `register`, `forgot-password`, `reset-password` (IP). **BE-02**
- `controller/ContactController.java` — `submit` rate-limité par IP. **BE-03**
- `controller/PublicAttemptController.java` — `startDemo` rate-limité par IP. **BE-03**
- `service/ProductionSubmissionService.java` — `submitAudio`/`submitText` : plafond burst + journalier par user (tous tiers). **BE-01**
- `resources/application.yaml` — bloc `sejourfr.rate-limit` (toggle `RATE_LIMIT_ENABLED`).

### Seuils par défaut (surchargeables)
| Surface | Limite | Clé |
|---|---|---|
| login | 30 / 5 min | IP |
| login | 10 / 15 min | compte (email) |
| register | 10 / h | IP |
| forgot-password | 5 / h | IP |
| reset-password | 10 / h | IP |
| contact | 5 / h | IP |
| demo guest | 60 / 10 min | IP |
| production EE/EO (burst) | 20 / 10 min | user |
| production EE/EO (jour) | 200 / jour | user |

### Changement de comportement (signalé)
- Un utilisateur dépassant un seuil reçoit **429** (au lieu de réussir). Seuils calibrés
  pour ne jamais toucher un usage légitime ; ajustables sans redéploiement de code.
- **NAT partagé** (carrier/entreprise) : plusieurs utilisateurs derrière une même IP
  partagent les compteurs « par IP ». Limites volontairement hautes pour absorber ce cas.
- **Redémarrage** = compteurs remis à zéro (garde-fou anti-abus, pas un compteur facturé).

### Hors-scope confirmé (déjà protégé)
- **EO realtime (Gemini Live)** : déjà borné — quota par pass (`RealtimeQuotaService`) +
  token éphémère minté serveur, scope verrouillé. Pas de modification.

### Build
- `./mvnw -o compile` → **BUILD SUCCESS**.

---

## Phase 1 · Batch B — XSS SVG inline (ADM-01, WEB-04)

**Objectif** : neutraliser l'injection de script via le SVG inline rendu en
`dangerouslySetInnerHTML` (source non strictement fiable : drafts générés IA +
images admin remplaçables). Un SVG piégé exécutait du JS dans la session admin
(→ vol des tokens `localStorage`, prise de contrôle) ou utilisateur.

**Mécanisme** : sanitisation **DOMPurify** (profil SVG : retire `<script>`,
attributs `on*`, balises dangereuses ; préserve le rendu du dessin). Choix de
DOMPurify plutôt que `<img data:>` pour garder le rendu **pixel-identique**
(les SVG Flyway n'ont pas toujours de dimensions intrinsèques → un `<img>`
risquait de les écraser).

### Nouveaux fichiers
- `admin_sejourfr/src/lib/sanitizeSvg.ts` — helper `sanitizeSvg()` (DOMPurify, profil SVG).

### Fichiers modifiés
- `admin_sejourfr/src/components/ui/MediaPreview.tsx` — SVG assaini. **ADM-01**
- `admin_sejourfr/src/features/audioQuestions/AudioDraftReviewPage.tsx` — SVG assaini. **ADM-01**
- `web_sejoufr/app/_components/MediaView.tsx` — SVG assaini côté **client** (import dynamique de DOMPurify dans un `useEffect` → pas d'exécution SSR, pas de hydration mismatch, pas de jsdom). **WEB-04**

### Dépendances ajoutées
- `dompurify@^3` dans `admin_sejourfr` et `web_sejoufr` (lib auditée standard ; types inclus).

### Vérifs
- `admin` : `tsc --noEmit` OK. `web` : `tsc --noEmit` OK.

### Note (hors scope, à traiter en Phase 2)
- `npm install` signale des vulnérabilités préexistantes dans l'arbre de deps
  (`npm audit` : admin 3 low + 1 high ; web idem) — **non liées à DOMPurify**,
  à traiter dans le batch « dépendances vulnérables » (SCA) de la Phase 2.
- **Défense en profondeur recommandée (Phase 2)** : sanitiser aussi le SVG
  **à la publication côté backend** (`audioquestion/`), pour ne pas stocker de
  contenu dangereux (cf. point « À confirmer » n°10 du rapport).

---

## Phase 2 · Batch C — Durcissement config backend & headers (T-01, T-02, BE-04, BE-07)

**Objectif** : défense en profondeur côté backend, sans changement de
comportement métier. Tout est non-bloquant pour le dev local.

### Fichiers modifiés
- `resources/application-dev.yaml` — secret JWT dev rendu **env-overridable**
  (`${JWT_SECRET:<placeholder dev>}`) : un dev/staging partagé pose `JWT_SECRET`
  au lieu de signer avec une clé publique (déjà brûlée dans l'historique). **T-01**
- `resources/application.yaml` — profil actif explicite `${SPRING_PROFILES_ACTIVE:dev}`
  (auto-documenté ; l'env override fonctionnait déjà). **T-02**
- `security/SecurityConfig.java` — bloc `.headers()` : **HSTS** (1 an,
  includeSubDomains, preload, émis sur HTTPS via le proxy), **Referrer-Policy**
  (strict-origin-when-cross-origin), **CSP d'API** (`default-src 'none'` →
  aucune exécution de script dans une réponse ; `style-src 'unsafe-inline'` +
  `img-src 'self' data:` pour ne pas casser la page HTML de confirmation
  d'email). nosniff + frame-DENY restent par défaut. **BE-04**

### Nouveaux fichiers
- `config/StartupProfileLogger.java` — log du profil actif au boot + **WARN
  visible si `dev` actif** (garde-fou contre un déploiement prod démarré par
  erreur en dev). Informatif, ne bloque pas. **T-02**

### Fichiers supprimés
- `security/SecurityConfigPatch.java` — scaffolding mort (référençait un
  `permitAll()` Swagger inexistant), aucune référence. **BE-07**

### Build
- `./mvnw -o compile` → **BUILD SUCCESS**.

---

## Phase 2 · Batch D — Hygiène de logs (T-03, T-04, MOB-03)

**Objectif** : ne plus écrire de PII (emails) ni de token de paiement réutilisable
en clair dans les logs. RGPD + bonne pratique.

### Nouveaux fichiers
- `util/LogMask.java` — `email()` (`k***@domaine`) + `token()` (6 car. + longueur).

### Fichiers modifiés (backend)
- `service/SocialAuthService.java` — 2 logs email masqués. **T-03**
- `service/ContactService.java` — 1 log email masqué. **T-03**
- `service/MailService.java` — 2 logs sender email masqués (relais contact). **T-03**
- `service/billing/GoogleSubscriptionService.java` — 8 logs `purchaseToken` tronqués. **T-04**

### Fichiers modifiés (mobile)
- `core/billing/billing_controller.dart` — `print` IAP → `if (kDebugMode) debugPrint(...)` (plus de log en release). **MOB-03**

### Vérifs
- Backend `./mvnw -o compile` → **BUILD SUCCESS**.
- Mobile `flutter analyze` (fichier) → **No issues found**.

---

## Phase 2 · Batch E — Validation input backend (BE-05, BE-06)

### Fichiers modifiés
- `service/ProductionEvaluationService.java` — **BE-05** : `validateAudioContentType()`
  rejette un upload audio EO manifestement non-audio (text/html, image/svg+xml…),
  tout en tolérant `audio/*` et `application/octet-stream` (clients mobiles qui
  n'étiquettent pas leur binaire) et l'absence de type. Clé R2 = UUID serveur
  (pas de path-traversal). Ne casse aucun client légitime (WAV/m4a/webm/ogg…).

### Décision (pas de changement de code)
- **BE-06** (messages d'erreur 400/409 bruts) : **accepté en l'état**. Les
  messages des `IllegalArgumentException`/`IllegalStateException` sont des copies
  **françaises intentionnelles** consommées par les 3 fronts (`message`) ; les
  génériser dégraderait l'UX. Le catch-all `Exception` → 500 générique **sans
  stacktrace** est déjà en place (vérifié Batch 0). Risque résiduel faible.

### Build
- `./mvnw -o compile` → **BUILD SUCCESS**.

---

## Phase 2 · Batch F/G — Logout révocable, garde rôle, stockage mot de passe mobile (ADM-03, ADM-04, MOB-02 + web)

**Objectif** : durcissements sûrs et contenus côté fronts (le refactor lourd
`localStorage → cookie httpOnly` est traité à part, voir « Non auto-appliqué »).

### Fichiers modifiés (admin)
- `src/api/authApi.ts` — ajout `logout(refreshToken)` → `POST /api/auth/logout`. **ADM-04**
- `src/auth/AuthContext.tsx` — `logout()` révoque le refresh token côté serveur
  (best-effort, idempotent) avant la purge locale. **ADM-04**
- `src/routes/ProtectedRoute.tsx` — garde aligné sur `user?.role === "ADMIN"`
  (cosmétique ; la vraie barrière reste backend). **ADM-03**

### Fichiers modifiés (web)
- `lib/api.ts` — `authApi.logout()` révoque le refresh token côté serveur
  (best-effort) avant la purge locale (comblait le `POST /api/auth/logout`
  jamais consommé). *(parité avec admin)*

### Fichiers modifiés (mobile) — MOB-02
- `lib/core/auth/token_storage.dart` — **ne persiste plus le mot de passe** :
  `saveCredentials/readCredentials` → `saveEmail/readSavedEmail` (email seul).
  L'ancienne clé `savedPassword` est **purgée** sur les installs existants.
- `lib/screens/auth/login_screen.dart` — préremplit l'email seul ; libellé de la
  case → « Se souvenir de mon email ».
- ⚠ **Changement de comportement signalé** : « Enregistrer mes identifiants » ne
  préremplit plus le mot de passe (l'utilisateur le ressaisit). Gain : aucun mot
  de passe réutilisable stocké sur l'appareil (plus risqué qu'un refresh token
  révocable, même chiffré au repos).

### Vérifs
- Backend `compile` OK · admin `tsc` OK · web `tsc` OK · mobile `flutter analyze` (3 fichiers) → **No issues found**.

---

## Phase 2 · Batch I — Dépendances vulnérables (SCA)

### Appliqué (non-breaking)
- **admin** : `npm audit fix` → react-router (CSRF doc-requests, low) + vite
  (`fs.deny` bypass / NTLM, high — **dev-server Windows uniquement**) corrigés.
  **0 vulnérabilité restante**. `tsc` + `npm run build` → OK.
- **web** : `npm audit fix` → js-yaml (DoS, build-time via gray-matter) corrigé.
  `npm run build` → OK (arbre de routes complet rendu).

### Non appliqué (breaking / à planifier)
- **web** : 2 modérées restantes (`postcss` XSS-in-stringify via `next`) — le fix
  exige `npm audit fix --force` qui **rétrograde Next.js** (breaking). **Laissé**
  (risque pratique faible, build-time) → à traiter via une montée de version Next
  maîtrisée, pas un downgrade.
- **backend** : pas d'OWASP Dependency-Check configuré → **recommandé en CI**
  (`mvn org.owasp:dependency-check-maven:check`) plutôt qu'ajouté à chaud
  (télécharge la base NVD, lent).
- **mobile** : `flutter pub outdated` = 67 paquets en retard, **aucun CVE signalé**
  par l'outil → montées de version à planifier hors périmètre sécurité.

---

## Phase 2 · Batch J — Outillage de durcissement (étapes sûres des chantiers)

Étapes **non-bloquantes** posées pour amorcer les chantiers structurants sans
toucher à la prod.

### Fichiers modifiés
- `web_sejoufr/next.config.ts` — **WEB-03 (étape 1)** : CSP stricte en
  `Content-Security-Policy-Report-Only`. N'applique rien (zéro régression) mais
  fait remonter ce qu'une CSP enforcing bloquerait → instrumente la migration
  vers une CSP à nonce. Build web OK.
- `backend_sejourfr/pom.xml` — **SCA** : profil Maven opt-in `security-scan`
  (`mvn -Psecurity-scan verify`, OWASP Dependency-Check, `failBuildOnCVSS=7`,
  formats HTML+SARIF, clé `NVD_API_KEY`). Ne ralentit pas les builds normaux
  (vérifié `mvn -o compile`). À brancher en CI.

---

## Non auto-appliqué — décisions structurantes (validation requise)

Ces findings touchent l'**auth en prod** ou peuvent **bricker une app installée** :
je ne les applique pas en aveugle (cf. brief « ne casse pas la prod » + « décisions
structurantes = proposer »).

### Chantier 1 — WEB-01 / WEB-02 / ADM-02 : JWT (+ refresh 30 j) hors `localStorage`
Le fix propre = refresh token en cookie **`httpOnly; Secure; SameSite=Strict`** posé
par le **backend** + access token en mémoire (jamais persisté). C'est une réécriture
du flux d'auth des 3 surfaces → risque de couper le login de **tous** les
utilisateurs si mal déployé. **Atténuation déjà en place** : sinks XSS assainis
(Batch B) + CSP backend (Batch C) + CSP web report-only (Batch J).

Plan d'exécution (backend d'abord, additif, rollout testé en staging) :
1. **Backend additif** : sur login/register/refresh, poser EN PLUS un cookie
   `Set-Cookie: sejourfr.rt=<refresh>; HttpOnly; Secure; SameSite=Strict; Path=/api/auth`
   (tout en continuant à renvoyer les tokens en JSON → clients actuels intacts).
2. **Backend lecture** : `/api/auth/refresh` accepte le refresh depuis le cookie
   si le body est absent. **CSRF** : comme l'auth API reste **Bearer-header**
   (cookie non accepté comme credential d'accès), pas de surface CSRF nouvelle ;
   seul `/refresh` lit le cookie → y exiger un en-tête custom (`X-Refresh: 1`) ou
   `SameSite=Strict` suffit.
3. **Fronts** : web/admin cessent d'écrire le refresh en `localStorage` (le cookie
   httpOnly s'en charge) ; l'access token reste en mémoire JS (state), re-dérivé
   via `/refresh` au boot. Supprimer le cookie JS dupliqué (WEB-02).
4. **Rollout** : déployer 1 (additif, sans risque), tester, puis 3 derrière un flag,
   avec fallback `localStorage` tant que le flag est off.
- Effort : **L**. Mobile non concerné (secure storage OK).

### Chantier 2 — MOB-01 : Certificate pinning
⚠ Le whole-cert pinning (seul exposé par `dart:io`) **brique l'app à chaque
renouvellement de certificat** (Let's Encrypt = nouvelle clé tous les 90 j). Donc :
1. **SPKI pinning** (survit au renouvellement si la clé est conservée) via un
   package vetté (`http_certificate_pinning`) ou un `SecurityContext` custom.
2. **Pins multiples** : clé courante **+** clé de secours (backup CSR) → la
   rotation ne brique pas.
3. **Default OFF** + flag : n'activer qu'après test sandbox sur le vrai host prod.
4. **Runbook de rotation** documenté + kill-switch serveur (`/api/app-config`).
- Effort : **M**. Ne pas activer sans pins de secours + procédure.

### Chantier 3 — WEB-03 (étape 2) : CSP `script-src` enforcing
La Report-Only (Batch J) collecte les violations. Ensuite :
1. Cartographier les inline scripts (styled-jsx, Google Identity, Next).
2. CSP **à nonce** : middleware Next génère un nonce par requête, propagé aux
   `<script>` et à styled-jsx ; `script-src 'self' 'nonce-…' https://accounts.google.com`.
3. Basculer `Content-Security-Policy-Report-Only` → `Content-Security-Policy`.
- Effort : **L**.

### Findings Basse acceptés (risque résiduel faible, documentés)
- **MOB-04** brouillons EE en `SharedPreferences` (texte de l'user, purgé au succès).
- **MOB-05 / MOB-06 / WEB-05** token éphémère / IP de dev — inhérents/dev-only.
- **WEB-06** `GOOGLE_OAUTH_AUDIENCES` dans le `.env.production` web (non bundlé, non
  secret) — à retirer côté ops (fichier non versionné).
