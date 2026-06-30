# SECURITY_AUDIT_REPORT — SejourFR

> **Phase 0 — Audit en lecture seule.** Aucun code modifié. Aucune valeur de secret
> imprimée (seul l'emplacement est noté). En attente de validation avant Phase 1.
>
> Périmètre : `backend_sejourfr/` (Spring Boot 4), `web_sejoufr/` (Next.js 16),
> `admin_sejourfr/` (React/Vite), `mobile_sejourfr/` (Flutter), + transverse
> (secrets, git, RGPD, TLS, dépendances).
> Date : 2026-06-30.

---

## Synthèse

| Sévérité | Nombre |
|----------|--------|
| 🔴 Critique | **0** |
| 🟠 Haute | **3** |
| 🟡 Moyenne | **10** |
| 🔵 Basse | **15** |
| ⚪ Info / Conforme | (voir §4) |

**Posture globale : solide.** Les fondations sensibles sont saines : pas de secret réel
versionné ni dans l'historique git, IDOR correctement bloqué côté backend (vérif
d'ownership systématique), webhooks Stripe/Apple/Google signés + idempotents, JWT sans
faille (HS, secret fort imposé au boot, autorités relues en DB, refresh révocable),
conformité Apple 3.1.1 respectée sur mobile, endpoint de suppression de compte présent.

Les findings se concentrent sur **deux axes** : (1) **absence de rate-limiting** sur les
surfaces coûteuses ou abusables (auth, évaluation LLM, démo guest) — le risque économique
et d'abus n°1 ; (2) **gestion des tokens côté fronts web/admin** (JWT + refresh 30 j en
`localStorage`/cookie JS) couplée à des **sinks XSS** (SVG inline non assaini) et une CSP
faible — chaîne classique de vol de session.

### Top 5 des risques (par impact réel)

| # | Risque | Module | Sév. | Impact |
|---|--------|--------|------|--------|
| 1 | **Évaluations EE/EO illimitées pour comptes premium** — `enforceQuota` bypass total si `hasTcf`, aucun cap journalier ni rate-limit serveur sur `POST /api/production-submissions` | Backend | Haute | **Facture LLM non bornée** (Whisper + Claude/OpenAI) déclenchable par 1 seul compte payant. C'est le risque économique n°1 du brief. |
| 2 | **Aucun rate-limit / lockout sur `/api/auth/*`** (login, register, forgot/reset-password) | Backend | Haute | Brute force & credential stuffing sur login ; énumération de comptes + flood d'emails via forgot-password. Endpoints publics. |
| 3 | **XSS stocké via SVG inline non assaini** (`dangerouslySetInnerHTML`) dans la console admin | Admin | Haute | Exécution de script dans la session admin → vol des tokens en `localStorage` → **prise de contrôle du compte admin**. Se déclenche pour tout admin ouvrant la question/draft piégé. |
| 4 | **JWT access + refresh (30 j) en `localStorage` / cookie non-`httpOnly`** sur web et admin | Web / Admin | Moyenne | Tout XSS exfiltre une session complète et **persistante** (refresh 30 j = compromission longue, pas juste une session). Amplificateur des sinks XSS ci-dessus. |
| 5 | **Surfaces publiques sans rate-limit** : `/api/public/attempts/demo`, `/api/contact` | Backend | Moyenne | Inflation non bornée de la table `attempts` par bot (dette déjà documentée dans le CLAUDE.md) + abus du formulaire contact. À traiter avant ouverture publique. |

---

## Findings détaillés

> Convention de sévérité (rubrique harmonisée entre modules) :
> **Haute** = directement exploitable ou impact élevé avec chemin réaliste ·
> **Moyenne** = exploitation conditionnée (souvent à un XSS) ou misconfig à fort potentiel ·
> **Basse** = défense en profondeur / fuite mineure / dev-only.
> Les sinks d'injection (XSS) sont notés selon leur exploitabilité propre ; le stockage de
> token en `localStorage` est l'**amplificateur** (Moyenne), distinct de l'injection.

### Backend — `backend_sejourfr/`

| ID | Sév. | Catégorie OWASP | Fichier:ligne | Description | Exploitabilité | Reco | Effort |
|----|------|-----------------|---------------|-------------|----------------|------|--------|
| BE-01 | 🟠 Haute | A04 / coût LLM | `service/ProductionSubmissionService.java:220-221` | `enforceQuota` retourne immédiatement si `subscriptionService.hasTcf(userId)` → un compte **premium** soumet un nombre **illimité** d'évaluations EE/EO (Whisper + Claude/OpenAI). Free correctement plafonné (1/épreuve à vie). | Un seul compte payant fait monter la facture LLM sans borne. Pas de rate-limit serveur ni cap journalier premium. | Cap journalier/horaire premium + rate-limit serveur par user sur `POST /api/production-submissions`. | M |
| BE-02 | 🟠 Haute | A07 Auth Failures | `controller/AuthController.java:44-86` ; `security/SecurityConfig.java:61` | Aucun rate-limit ni lockout sur `/api/auth/login`, `/forgot-password`, `/reset-password`, `/register`. | Brute force / credential stuffing sur login ; énumération de comptes + flood d'emails via forgot-password. | Bucket4j par IP + lockout progressif par compte sur login ; throttle forgot/reset. | M |
| BE-03 | 🟡 Moyenne | A09 / abus ressources | `controller/PublicAttemptController.java:35` ; `service/PublicAttemptService` | `POST /api/public/attempts/demo` sans rate-limit (quota supprimé). `client_ip` posée mais inexploitée. Idem `POST /api/contact`. | Bot gonfle `attempts` (user NULL) indéfiniment. Connu/documenté (CLAUDE.md), à traiter avant ouverture publique. | Rate-limit IP (Bucket4j) + job `@Scheduled` de purge des attempts anonymes anciens. | M |
| BE-04 | 🔵 Basse | A05 Misconfig | `security/SecurityConfig.java:40-87` | Aucun bloc `.headers(...)` : pas de HSTS/CSP/Referrer-Policy explicites (seuls défauts Spring : `X-Content-Type-Options`, `X-Frame-Options=DENY`). | Faible pour une API JSON derrière reverse-proxy ; durcissement manquant. | Ajouter `.headers()` (HSTS includeSubDomains, CSP minimale, Referrer-Policy). | S |
| BE-05 | 🔵 Basse | A03 Input Validation | `service/ProductionEvaluationService.java:296-302` (`validatePayload:273`) | Upload audio EO : seule la **taille** est validée (25 Mo). Pas de validation MIME/content-type (contraste avec `ImageUploadSupport.java:17-37` qui valide MIME+ext pour images). | Un non-audio passe le contrôle ; échoue plus loin à la transcription. Pas de path-traversal (clé R2 = UUID serveur). | Valider le content-type audio (mpeg/m4a/wav) avant stockage R2. | S |
| BE-06 | 🔵 Basse | A09 Info Exposure | `exception/GlobalExceptionHandler.java:68-76` | `IllegalArgumentException`→400 et `IllegalStateException`→409 renvoient `e.getMessage()` brut. (Catch-all `Exception`→500 générique sans stacktrace : bon, lignes 118-127.) | Pas de stacktrace fuitée ; messages internes potentiellement révélés. Faible. | Messages contrôlés côté métier ; surveiller. | S |
| BE-07 | ⚪ Info | A05 | `security/SecurityConfigPatch.java` | Scaffolding mort (instructions de patch jamais exécutées) référençant un `permitAll()` Swagger inexistant dans la vraie config. Confusion future. | Aucune (classe sans bean). | Supprimer le fichier. | S |

### Web — `web_sejoufr/`

> Architecture = **client pur** : aucune route handler `app/api/**`, aucun `"use server"`.
> L'autorisation est entièrement déléguée au backend (Bearer JWT). Stripe : le web ne
> détient **aucune** clé secrète (il appelle `GET /api/billing/payment-link` et redirige).

| ID | Sév. | Catégorie OWASP | Fichier:ligne | Description | Exploitabilité | Reco | Effort |
|----|------|-----------------|---------------|-------------|----------------|------|--------|
| WEB-01 | 🟡 Moyenne | A07 Auth Failures | `lib/api.ts:51-76` | Access **et** refresh token (30 j) en `localStorage` (`sejourfr.accessToken/refreshToken`). Lisibles par tout JS. | Conditionné à un XSS ; le refresh long-lived volé = prise de compte persistante. | Migrer (au moins le refresh) vers cookie `httpOnly; Secure; SameSite` posé par le backend. | L |
| WEB-02 | 🟡 Moyenne | A05 Misconfig | `lib/api.ts:64-68` | Access token **dupliqué dans un cookie via `document.cookie`** → **non-`httpOnly`** (lisible JS), `Secure` seulement si https, `SameSite=Lax`. Sert au SSR mais reste exposé. | Même surface qu'au-dessus : tout XSS le lit. | Le poser côté serveur en `httpOnly` ; ne pas mettre le token brut dans un cookie JS. | M |
| WEB-03 | 🟡 Moyenne | A05 Misconfig | `next.config.ts:24-27` | CSP minimale : `frame-ancestors 'self'; object-src 'none'; base-uri 'self'`, **pas de `script-src`/`style-src`** (assumé : styled-jsx + Google Identity sans nonce). | Pas une vuln seule, mais supprime le filet qui limiterait un XSS (cf. tokens). | Chantier CSP nonce-based (`script-src 'self' 'nonce-…' accounts.google.com`). | L |
| WEB-04 | 🟡 Moyenne | A03 XSS | `app/_components/MediaView.tsx:30-34` | `dangerouslySetInnerHTML={{__html: media.inlineSvg}}` — SVG brut. Source = seed Flyway / contenu admin (pas d'upload utilisateur final). | Faible : nécessite de compromettre le contenu backend/admin. Même cause racine que ADM-01. | Sanitiser le SVG (DOMPurify profil SVG) ou le servir en `<img src>`. | M |
| WEB-05 | 🔵 Basse | A09 Data Exposure | `lib/realtime/geminiLive.ts:140` | Token éphémère Gemini en **query string** de l'URL WSS (`?access_token=…`). Inhérent au WS navigateur (pas de headers custom). | Faible : éphémère + scope verrouillé serveur (schéma A). Risque = fuite via logs de proxy. | Durée de vie minimale ; vérifier que le backend lie ce token à la session ciblée. | S |
| WEB-06 | 🔵 Basse | A05 Misconfig | `.env.production` (`GOOGLE_OAUTH_AUDIENCES`) | Variable **backend** posée dans l'env du web. Non-`NEXT_PUBLIC_` → **pas bundlée** (pas une fuite), non secrète (audiences = client IDs publics), mais inutilisée et trompeuse. | Aucune. | Retirer du `.env.production` web. | S |
| WEB-07 | ⚪ Info / OK | A03 XSS | `app/blog/page.tsx:52`, `tarifs/page.tsx:83`, `faq/page.tsx:53`, `blog/[slug]/page.tsx:100` | `dangerouslySetInnerHTML` JSON-LD **correctement échappé** via `safeJsonLd()` (`lib/security.ts:31-33`, anti `</script>` breakout). Données statiques. | Non exploitable. | Aucune — pattern de référence. | — |
| WEB-08 | ⚪ Info / OK | A05 Headers | `next.config.ts:9-28` | Présents : HSTS (2 ans + preload), `X-Frame-Options: SAMEORIGIN`, `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `Permissions-Policy`. **3 seules vars `NEXT_PUBLIC_`** = client ID Google + URLs (non secrets). | N/A — bon socle. | Compléter par CSP `script-src` (WEB-03). | — |

### Admin — `admin_sejourfr/`

| ID | Sév. | Catégorie OWASP | Fichier:ligne | Description | Exploitabilité | Reco | Effort |
|----|------|-----------------|---------------|-------------|----------------|------|--------|
| ADM-01 | 🟠 Haute | A03 XSS stocké | `src/components/ui/MediaPreview.tsx:25` ; `src/features/audioQuestions/AudioDraftReviewPage.tsx:366` | `dangerouslySetInnerHTML={{__html: inlineSvg}}` rend du SVG/HTML de la DB (`inlineSvg`/`mediaInlineSvg`) **sans sanitisation**. Source = drafts générés IA + images remplaçables admin (R2). | Payload `<img src=x onerror=…>`/`<foreignObject>` s'exécute dans la session admin → vol des tokens `localStorage` (ADM-02) → **prise de contrôle admin**. Stocké = se déclenche pour tout admin. | Sanitiser le SVG (DOMPurify `USE_PROFILES:{svg:true}`) **ou** rendre via `<img src="data:image/svg+xml;base64,…">`. Sanitiser aussi à la publication backend. | M |
| ADM-02 | 🟡 Moyenne | A07 Auth Failures | `src/auth/tokenStorage.ts:3-33` ; `src/api/http.ts:35,49` | Access **et** refresh token (~30 j) en `localStorage`. Exfiltrables par tout XSS (cf. ADM-01). | Indirecte (requiert XSS), mais en couple avec ADM-01 = chaîne complète d'ATO admin persistant. | Refresh en cookie `httpOnly; Secure; SameSite=Strict` ; access en mémoire. À défaut, réduire la durée du refresh. | L |
| ADM-03 | 🔵 Basse | A01 Broken Access Control (info) | `src/routes/ProtectedRoute.tsx:5-13` ; `src/auth/AuthContext.tsx:33-39` | `ProtectedRoute` ne teste que `isAuthenticated` (présence user en `localStorage`), sans re-vérifier le rôle. | Nulle : toute donnée passe par `/api/admin/**` (ROLE_ADMIN backend). Forger `role=ADMIN` montre l'UI mais reçoit 401/403. Le client **assume** correctement le backend comme barrière. | Faire porter le garde sur `user?.role === "ADMIN"` (cohérence). Sécurité réelle = backend. | S |
| ADM-04 | 🔵 Basse | A07 Logout incomplet | `src/auth/AuthContext.tsx:43-46` ; `src/api/authApi.ts` | `logout()` purge `localStorage` mais n'appelle aucun endpoint de révocation backend. | Faible : impact seulement si le token a déjà fuité. | Endpoint de révocation backend appelé au logout. | S |
| ADM-05 | ⚪ Info / OK | A05 | `src/api/http.ts:4` ; `.env*` | Seule var `VITE_*` = `VITE_API_BASE_URL` (URL publique). Aucun secret sous `VITE_`. `.env*` gitignorés. Pas de log de credentials. Refresh JWT dédoublonné correctement. | N/A — conforme. | Aucune. | — |

### Mobile — `mobile_sejourfr/` (MASVS)

| ID | Sév. | Catégorie MASVS | Fichier:ligne | Description | Exploitabilité | Reco | Effort |
|----|------|-----------------|---------------|-------------|----------------|------|--------|
| MOB-01 | 🟡 Moyenne | MASVS-NETWORK | `lib/core/api/api_client.dart:15-30` | **Aucun certificate pinning** sur Dio (pas de `badCertificateCallback`/interceptor/`SecurityContext`). Trafic JWT = PKI système seule. | MITM possible sur réseau hostile si une CA est compromise/injectée (device rooté, proxy d'entreprise). TLS standard couvre le cas courant. | Pinning SPKI sur le host prod, avec rotation de clés prévue. | M |
| MOB-02 | 🟡 Moyenne | MASVS-STORAGE / AUTH | `lib/core/auth/token_storage.dart:17,81-91` | « Enregistrer mes identifiants » persiste **email + mot de passe en clair** (chiffrés au repos via Keychain/EncryptedSharedPreferences). Mot de passe réutilisable = plus risqué qu'un refresh révocable. | Device compromis/jailbreaké ou backup non chiffré → mot de passe (cross-service) exposé. | Ne stocker que le refresh token (déjà présent) pour le re-login ; garder au plus l'email, jamais le mot de passe. | M |
| MOB-03 | 🔵 Basse | MASVS-CODE | `lib/core/billing/billing_controller.dart:260` | `print('IAP: SKUs introuvables…')` non gardé par `kReleaseMode` → actif en release (`idevicesyslog`/`logcat`). Contenu non sensible (IDs SKU). | Faible : pas de PII/token. | `if (kDebugMode)` ou supprimer. | S |
| MOB-04 | 🔵 Basse | MASVS-STORAGE | `lib/screens/tcf_production/draft_service.dart:18-39` | Brouillons EE (texte produit par l'user) en clair dans SharedPreferences (`ee_draft_<taskId>`). | Faible : donnée auto-générée, faible valeur ; lisible sur device compromis. Purgé au succès. | Acceptable ; durcir via secure storage si souhaité. | S |
| MOB-05 | 🔵 Basse | MASVS-NETWORK | `lib/core/api/api_config.dart:12-13` | Fallback `API_BASE_URL` codé en dur sur **IP LAN privée HTTP cleartext** (`http://192.168.1.x:8080`). | Très faible : atteint seulement sans `.env`. ATS iOS / Android 28+ bloquent le cleartext en prod. | Fallback = URL HTTPS de prod, pas une IP de dev. | S |
| MOB-06 | 🔵 Basse | MASVS-NETWORK | `lib/core/realtime/gemini_live_client.dart:77-85` | Token éphémère realtime en **query string** de l'URL WSS. | Faible : éphémère, design assumé (schéma A). | Passer le token en header de handshake si possible. | S |
| MOB-07 | ⚪ Info / OK | MASVS-AUTH / PLATFORM / RESILIENCE | `token_storage.dart:8-72` ; manifests ; `lib/core/billing/*` | **Tokens JWT dans `FlutterSecureStorage`** (Keychain/EncryptedSharedPreferences). **Aucune surface deep-link** exposée (1 seul intent MAIN/LAUNCHER, pas de scheme custom). **Apple 3.1.1 OK** : IAP natif, `openSubscriptionWeb` confirmé absent, aucun steering hors-store. | N/A — conforme. | Maintenir. | — |

### Transverse — secrets / git / RGPD / TLS

| ID | Sév. | Catégorie | Fichier:ligne | Description | Exploitabilité | Reco | Effort |
|----|------|-----------|---------------|-------------|----------------|------|--------|
| T-01 | 🟡 Moyenne | A05 / A02 Crypto | `backend_sejourfr/src/main/resources/application-dev.yaml:91` | Secret JWT HS256 **hardcodé en clair** (libellé « dev seulement »). Présent dès le commit initial → vit dans tout l'historique. Prod lit bien `${JWT_SECRET}`. | Faible en prod (override env). Mais quiconque a le repo peut forger des JWT valides sur tout environnement tournant en profil `dev`. Secret « brûlé » (historique). | `${JWT_SECRET:}` même en dev (ou secret aléatoire au boot dev). Ne jamais réutiliser cette valeur ailleurs. | S |
| T-02 | 🟡 Moyenne | A05 Misconfig | `backend_sejourfr/src/main/resources/application.yaml:5` | Profil actif par défaut = `dev`. Un déploiement oubliant `SPRING_PROFILES_ACTIVE=prod` démarre avec JWT hardcodé, DB password vide, CORS LAN, logs DEBUG + `security: DEBUG`. Scripts de déploiement passent bien `prod` → latent. | Conditionnée à une erreur d'opération. | Défaut neutre/safe, ou échec du boot si `JWT_SECRET` absent en non-dev. | S |
| T-03 | 🔵 Basse | RGPD / PII logs | `SocialAuthService.java:107,124` ; `MailService.java:319,321` | Emails loggés en clair en **INFO** (auth sociale, relais contact). Pas de mot de passe ni token. | Faible (accès logs requis) ; PII exposée hors besoin. | Masquer/hasher (`u***@domain`) ou passer en DEBUG. | S |
| T-04 | 🔵 Basse | RGPD / Privacy | `GoogleSubscriptionService.java:142,168,293,356,408` | `purchaseToken` Google Play loggé en INFO/WARN (donnée de paiement réutilisable pour requêter l'état d'abonnement). | Faible (accès logs requis). | Tronquer le token dans les logs. | S |
| T-05 | 🔵 Basse | A02 TLS | `application.yaml:130` (+ dev `:95`) | Base-URL média en **HTTP non-TLS** dans le profil par défaut (LAN dev). Prod override via `${STORAGE_PUBLIC_BASE_URL}`. | Nulle en prod si l'env est bien posé. | Confirmer la valeur prod en https. | S |
| T-06 | 🔵 Basse | A05 Misconfig | `application.yaml:52` ; `application-dev.yaml:46` | CORS dev autorise une IP LAN fixe. Prod = `${CORS_ORIGINS}`. | Nulle hors LAN dev. | Acceptable ; vérifier que `CORS_ORIGINS` prod n'a pas de wildcard. | S |

---

## §4 — Points vérifiés conformes (pas de finding)

**Secrets / git :**
- ✅ **Aucun secret réel** dans les fichiers trackés ni dans l'historique git. Tous les
  patterns (`sk_live`/`whsec_`/`-----BEGIN`/`price_`/`AIza`) sont des placeholders `xxx`
  dans la doc/commentaires. Stripe, Anthropic, OpenAI, Gemini, Azure, R2, Google SA JSON,
  Apple P8, DB, mail : **tous en `${ENV_VAR:}`**.
- ✅ `application-prod.yaml` : tous les secrets en `${ENV}` (Apple key-id/private-key en
  défaut vide `:}`, les défauts non-vides sont des paths/URLs/IDs publics). *(Recoupé à la
  main par le lead auditor.)*
- ✅ **Aucun `.env` jamais committé** ; `.gitignore` correct (`.env*` bloqués, `.example`
  ré-autorisé). Aucun `.p8`/`.pem`/`.jks`/clé tracké.

**Backend :**
- ✅ **IDOR** correctement bloqué partout (Attempt, production EE/EO, full-TCF-exam,
  realtime) — vérif d'ownership avant retour/mutation, 404 pour ne pas révéler l'existence.
- ✅ **Admin** : tous les controllers sous `/api/admin/**` → `hasRole("ADMIN")` +
  `@EnableMethodSecurity`. Aucun controller admin hors préfixe.
- ✅ **Webhooks** Stripe (HMAC + idempotence `processed_external_events`), Google RTDN
  (JWT signature + audience + email SA), Apple ASSN (JWS + `notificationUUID`) — pas de
  re-crédit par replay.
- ✅ **JWT** sain : HMAC-SHA, secret ≥ 32 octets imposé au boot, pas d'`alg:none`,
  autorités relues en DB (pas le claim `role`), refresh révocable via `refresh_tokens`.
- ✅ **Token éphémère Gemini** minté serveur-side, scope/voix/persona verrouillés, clé API
  longue durée ne quitte jamais le serveur ; quota realtime par pass (anti mint-spam).
- ✅ Bean Validation (`@Valid`) partout ; **aucun binding sur `@Entity`** (pas de
  mass-assignment). Requêtes natives **paramétrées**. Actuator restreint à `health,info`.
  CORS origines explicites. Pas de stacktrace renvoyée (catch-all générique).
- ✅ **Suppression de compte** (`AccountController.java:28-30` → `AccountDeletionService`) :
  anonymise, purge attempts/statuses/conversations, révoque refresh tokens, coupe le
  renouvellement Stripe. Idempotent. *(Exigence App Store satisfaite.)*
- ✅ **Pas de mail marketing/Brevo/newsletter** : envoi 100 % transactionnel (pas de
  problème d'opt-in à ce stade).

**Mobile :** tokens en secure storage, pas de deep-link à effet de bord, conformité Apple
3.1.1, pas de secret en dur.
**Web :** client pur sans secret, headers de sécurité présents, JSON-LD échappé, Stripe
server-side (backend).
**Admin :** aucun secret sous `VITE_`, pas de log de credentials.

---

## §5 — À confirmer (hors repo / infra — à valider, ne pas conclure à une faille)

1. **Valeur réelle de `STORAGE_PUBLIC_BASE_URL` et `CORS_ORIGINS` en prod** (env VPS) —
   doivent être `https://` et sans wildcard.
2. **TLS / HSTS / redirection HTTP→HTTPS** — `forward-headers-strategy: framework`
   (prod) suppose un reverse-proxy (Nginx) qui termine le TLS et émet HSTS ; config hors
   repo.
3. **`forward-headers-strategy`** — confirmer que le proxy **écrase** `X-Forwarded-For`
   entrant (sinon spoofing d'IP sur les invariants guest/demo et le rate-limit à venir).
4. **Cap LLM premium** (BE-01) — confirmer s'il existe un plafond métier mensuel ailleurs,
   ou si c'est réellement illimité.
5. **`management.endpoint.health.show-details`** (`application.yaml:46-47`) — ne doit pas
   exposer l'état détaillé (DB/mail) sans auth.
6. **Durée de vie réelle du token éphémère Gemini** (`tokenUses`, `sessionExpireSeconds`).
7. **Le backend n'authentifie jamais sur le cookie `sejourfr.accessToken`** (Bearer-only) —
   sinon le risque CSRF web passe de conforme à Haute.
8. **Build mobile** : obfuscation (`--obfuscate --split-debug-info`) non vérifiable depuis
   le repo (aucun CI présent) ; `FlutterSecureStorage` sans `AndroidOptions`/`IOSOptions`
   explicites → confirmer la config par défaut effective sur l'APK/IPA ; URL prod injectée
   bien en HTTPS.
9. **SCA / CVE dépendances** : non réalisé ici (pas de lockfiles résolus). Lancer en CI :
   `mvn dependency-check` (OWASP), `npm audit` (web + admin), `flutter pub outdated`.
10. **Sanitisation backend du SVG à la publication** (`audioquestion/`) — si elle existe et
    est stricte, ADM-01/WEB-04 baissent d'un cran ; sinon ADM-01 reste Haute.

---

## §6 — Hors périmètre (signalé, non corrigé sans feu vert)

- **Rate-limit / WAF côté gateway** (Nginx) : plusieurs findings (BE-02/03, contact)
  pourraient être atténués au reverse-proxy plutôt qu'en applicatif — décision à prendre.
- Hardening Nginx/Ubuntu, rotation des secrets côté providers, pentest externe : non
  exécutés (conformément au brief §5).
- Aucun port DB exposé ni config Nginx permissive visible **dans le repo**.

---

## Proposition de batchs pour la Phase 1 (Critique + Haute)

À ta validation, je propose de regrouper la remédiation Haute ainsi :

- **Batch A — Rate-limiting (BE-01, BE-02, +BE-03 anticipé)** : Bucket4j par IP/user sur
  `/api/auth/*`, cap premium + rate-limit sur `/api/production-submissions`, throttle
  `/api/public/attempts/demo` + `/api/contact`. *(Le risque économique n°1.)*
- **Batch B — XSS admin (ADM-01)** : sanitisation SVG (DOMPurify ou `<img data:>`), +
  alignement web (WEB-04) dans la même passe (parité, même cause racine).

Les items Moyenne/Basse (tokens `localStorage`, CSP, headers, secrets dev, logs PII…)
iront en Phase 2 par batchs thématiques.

**J'attends ta validation du rapport avant toute modification de code.**
