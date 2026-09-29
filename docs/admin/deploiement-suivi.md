# Chantier « Suivi » — checklist de déploiement

Ordre imposé : **backend → web → app** (contrôle N10). Une app publiée avant son backend
abandonnerait ses lots d'événements (4xx) et ne créerait aucune trace de diagnostic.

Références : `docs/admin/decisions-suivi.md` (§3 récapitulatif, D1 → D112),
`docs/admin/controle-suivi.md` (passe de contrôle).

---

## 0. Avant tout déploiement (propriétaire)

- [ ] **Taux de commission Apple / Google** : 0,15 provisoire dans
  `backend_sejourfr/src/main/resources/billing/revenue-rules-v1.json`. Le taux est **figé achat
  par achat** (`revenue_rules_version`) : le confirmer **avant** de poser
  `measurementStart.REVENUE_BREAKDOWN`, sinon passer en v2 (non rétroactif).
- [ ] **Comptes internes** : si `ANALYTICS_EXCLUDED_EMAILS` était surchargée en production,
  préparer `UPDATE users SET is_internal = true WHERE email IN (…);` (la variable n'est plus lue).
- [ ] **RGPD** : relire `/confidentialite` (§ 8.2 et § 8.4 — « aucun recoupement » vs
  rattachement du parcours anonyme au compte) ; ta vérification du rattachement
  visiteur → compte (Q5).

## 1. Stripe (Dashboard)

- [ ] Webhook `https://api.sejourfr.fr/api/billing/webhook` abonné à **5 événements** :
  `checkout.session.completed`, `checkout.session.async_payment_succeeded`,
  `checkout.session.async_payment_failed`, `charge.refunded`, `charge.dispute.closed`.
- [ ] Le Checkout est restreint **dans le code** à la carte (Apple Pay / Google Pay compris,
  D109) : rien à régler, mais Bancontact, iDEAL et Klarna ne sont plus proposés.
- [ ] **Apple Pay** : dans le Dashboard, *Settings → Payment methods*, vérifier que **Apple Pay**
  et **Google Pay** sont activés (ils passent par la carte, `payment_method_types = [card]`), et
  **enregistrer le domaine** `sejourfr.fr` sous *Payment method domains*. ⚠️ Le Checkout actuel
  est la page **hébergée par Stripe** (`session.getUrl()`, `BillingService.java:376`), servie
  depuis `checkout.stripe.com` : Stripe y gère lui-même le domaine Apple Pay. L'enregistrement
  de `sejourfr.fr` ne devient **obligatoire** que si l'on passe un jour au Checkout intégré
  (`ui_mode=embedded`) ou à Elements ; le faire dès maintenant est sans risque. Contrôle : ouvrir
  un Checkout depuis Safari sur iPhone et vérifier que le bouton Apple Pay apparaît.

## 2. Backend

Migrations appliquées au démarrage : **V074** (schéma Suivi), **V075** (vue
`v_journey_founding_run`), **V076** (compteurs de réponses civiques, `ft_source` nullable).

Variables d'environnement :
- [ ] `APP_MIN_VERSION_IOS` / `APP_MIN_VERSION_ANDROID` : **vides** au départ (personne
  n'est bloqué). Format `MAJOR.MINOR.PATCH` ; une valeur mal formée fait échouer le démarrage.
- [ ] `TRUSTED_PROXY_RANGES` : **vide** en production (jamais `*`).
- [ ] `TOMCAT_TRUSTED_PROXIES` : seulement si le reverse proxy atteint le backend depuis une
  adresse **publique** (voir § 5, N8).

Après démarrage :
- [ ] `GET /api/public/app-config` → `{"minSupportedVersion":{"ios":null,"android":null}}`.
- [ ] `GET /api/admin/analytics/suivi` (compte admin) → 200 ; visiteurs et sources chiffrés,
  le reste `null` (normal tant que le § 6 n'est pas fait).
- [ ] Le port 8080 n'est **pas** joignable depuis l'extérieur.

## 3. Web

- [ ] Déployer avec `public/.well-known/` (`apple-app-site-association`, `assetlinks.json`).
- [ ] `https://sejourfr.fr/.well-known/apple-app-site-association` servi en
  `application/json`, sans redirection.
- [ ] `assetlinks.json` : remplacer `A_REMPLACER_SHA256_CLE_DE_SIGNATURE_PLAY_APP_SIGNING` par
  l'empreinte SHA-256 de la clé **App Signing** (Play Console), pas la clé d'upload.
- [ ] AASA : garder **le seul** bundle ID réel (le projet Xcode dit
  `com.example.sejourfrMobile`, la doc de paiement `com.sejourfr.app`) et corriger le projet
  Xcode en conséquence.
- [ ] **Hôte `app.sejourfr.fr`** (lien web → app sur iPhone) : DNS + vhost servis par le web
  Next, `/.well-known/*` en accès direct ; puis `NEXT_PUBLIC_APP_LINK_BASE_URL=https://app.sejourfr.fr`.
  Tant qu'il n'existe pas, le lien retombe sur la page web (et, avant Android 12, la
  vérification App Links échoue pour tous les hôtes).
- [ ] La version web part bien en en-tête (`X-Sejourfr-App-Version`, lue dans `package.json`) :
  sans elle, le serveur classerait le web en « client ancien » (`signup_context` inconnu).

## 4. App mobile (iOS + Android)

- [ ] Apple Developer : activer **Associated Domains** sur l'App ID, régénérer les profils.
- [ ] `.env` de build : `IOS_APP_STORE_URL` (identifiant App Store **numérique**, inconnu à ce
  jour — sinon repli sur la recherche App Store) et `ANDROID_PLAY_STORE_URL`.
- [ ] Publier la nouvelle version sur les deux stores (manifest, entitlements, instrumentation).
- [ ] Rien n'est mesuré sur mobile avant cette publication.

## 5. Vérifications serveur (contrôle N8 — IP réelle)

Depuis le correctif, Tomcat (`forward-headers-strategy: native`) ne lit `X-Forwarded-For`
que pour une connexion venant du loopback ou d'une plage privée.
- [ ] Relever l'adresse sous laquelle le backend voit le reverse proxy (en général
  `127.0.0.1`). Si elle est **publique**, la déclarer dans `TOMCAT_TRUSTED_PROXIES` —
  sinon tous les utilisateurs partagent l'IP du proxy et les rate-limits frappent tout le monde.
- [ ] Test : se connecter avec un en-tête forgé `X-Forwarded-For: 1.2.3.4` et vérifier que le
  rate-limit compte la **vraie** IP.

## 6. Dates de début de mesure (le jour J + 1)

✅ **Fait le 2026-09-28 (D116)** : les 14 indicateurs datés du 2026-09-28 (déploiement à 00:09,
heure de Paris, aucune inscription entre minuit et le déploiement). La règle ci-dessous reste
celle d'un futur indicateur.

Dans `backend_sejourfr/src/main/resources/analytics/analytics-config-v1.json`,
`measurementStart` : poser la date **du lendemain du dernier déploiement** (backend + web ;
la date est au jour, les inscriptions du matin même seraient sinon comptées) pour :
`DIAGNOSTIC_SUBJECT_VIEWED`, `DIAGNOSTIC_SUBMITTED`, `ACCOUNT_ATTACHED`, `REPORT_VIEWED`,
`PLAN_VIEWED`, `PLAN_UNLOCK_CLICKED`, `PURCHASES`, `PURCHASE_ORIGIN`, `REVENUE_BREAKDOWN`
(**après** confirmation du taux, § 0), `REFUNDS`, `SIGNUP_CONTEXT`, `SIGNUP_PLATFORM_DETAIL`.
- [ ] Vérifier aussi `VISITORS` / `ACQUISITION_SOURCES` = `2026-08-21` contre la vraie date
  de mise en production de l'analytics V043.
- [ ] Redéployer le backend (la config est lue au démarrage).

Tant qu'une date est `null`, l'écran Suivi affiche « non mesuré », jamais 0 (D43).

## 7. Après déploiement — requêtes de contrôle

**Retrait de l'ingestion unitaire (N1, D-Q17)** — à lancer chaque semaine ; retirer l'unitaire
(contrôleur, service, DTO, rate-limit, tests — comme au commit `2988a6dd`) quand
`pct_mobile < 5` et `recus_par_l_unitaire` est marginal :

```sql
SELECT count(*) FILTER (WHERE platform = 'MOBILE')                   AS evenements_mobile,
       count(*) FILTER (WHERE platform IN ('MOBILE', 'IOS', 'ANDROID')) AS evenements_app,
       round(100.0 * count(*) FILTER (WHERE platform = 'MOBILE')
             / NULLIF(count(*) FILTER (WHERE platform IN ('MOBILE', 'IOS', 'ANDROID')), 0), 2)
                                                                    AS pct_mobile,
       count(*) FILTER (WHERE event_id IS NULL)                        AS recus_par_l_unitaire
  FROM analytics_event
 WHERE received_at >= now() - interval '7 days';
```

**Seuil civique de 80 % (C, D89)** — après quelques semaines, vérifier la distribution
réelle ; changer le seuil = changer `civicSubmittedMinAnsweredRatio`, sans migration :

```sql
SELECT count(*)                                                         AS runs_civiques_closes,
       count(*) FILTER (WHERE submitted_answered_count IS NULL)         AS inconnues,
       count(*) FILTER (WHERE submitted_answered_count = 0)             AS zero_reponse,
       count(*) FILTER (WHERE submitted_answered_count < 0.5 * submitted_question_count) AS moins_50,
       count(*) FILTER (WHERE submitted_answered_count >= 0.5 * submitted_question_count
                          AND submitted_answered_count <  0.8 * submitted_question_count) AS de_50_a_80,
       count(*) FILTER (WHERE submitted_answered_count >= 0.8 * submitted_question_count
                          AND submitted_answered_count <  submitted_question_count)       AS de_80_a_99,
       count(*) FILTER (WHERE submitted_answered_count >= submitted_question_count)       AS complets
  FROM diagnostic_run
 WHERE diagnostic_type = 'CIVIQUE' AND submitted_at IS NOT NULL;
```

**Montée de la version minimale (G-a)** — quand la nouvelle app est largement adoptée :
poser `APP_MIN_VERSION_IOS` / `APP_MIN_VERSION_ANDROID`, redéployer le backend.

## 8. Tests sur appareil

- [ ] Lien « Continuer sur l'application » : app installée / non installée, iOS / Android ;
  inscription dans l'app → run rattachée en `APP_LINK`.
- [ ] Achat store avec intention (`purchaseIntentId`), achat rejoué au relancement.
- [ ] File d'événements hors ligne (mode avion, puis retour réseau).
- [ ] Écran de mise à jour : poser temporairement une version minimale supérieure sur un
  environnement de test.
