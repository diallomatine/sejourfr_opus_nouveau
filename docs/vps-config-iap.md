# Configurer le VPS pour que l'In-App Purchase marche

Synthèse opérationnelle croisant `backend_sejourfr/DEPLOIEMENT_BACKEND.md` (le **où**
sur le serveur) et `docs/paiements-iap-setup.md` (le **quoi** configurer). Ce doc se
limite à ce qui se fait **sur le VPS** (`82.223.165.43` / `api.sejourfr.fr`). La création
des SKUs côté App Store Connect / Play Console et la config Pub/Sub se font dans les
dashboards — voir la checklist §6 de `paiements-iap-setup.md`.

> L'IAP (Apple + Google) repose **entièrement sur le backend**. Le mobile ne fait que
> lire/soumettre ; toute la config sensible vit sur le serveur. Trois choses à poser :
> **(1)** les secrets dans le `.env`, **(2)** les certs racine Apple dans le jar (au build),
> **(3)** les Product IDs en base Postgres. Plus s'assurer que les webhooks sont joignables
> via Nginx.

---

## 1. Les secrets — `/etc/sejourfr/backend.env`

Fichier `chmod 600` (cf. §3.3 du mémo déploiement). On y ajoute les blocs Apple + Google.

```bash
sudo nano /etc/sejourfr/backend.env
|
```

```ini
# --- Apple (iOS IAP) ---
APPLE_ISSUER_ID=99b16628-...
APPLE_KEY_ID=ABCDEFGHIJ
APPLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
APPLE_BUNDLE_ID=com.sejourfr.app
APPLE_APP_ID=1234567890
APPLE_ENVIRONMENT=PRODUCTION          # SANDBOX tant que tu testes en TestFlight

# --- Google (Android IAP) ---
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
GOOGLE_PLAY_PACKAGE_NAME=com.sejourfr.app
GOOGLE_PUBSUB_AUDIENCE=https://api.sejourfr.fr/api/billing/webhooks/google
GOOGLE_PUBSUB_SA_EMAIL=pubsub-pusher@<project>.iam.gserviceaccount.com
```

Points de vigilance VPS :

- **`APPLE_PRIVATE_KEY`** : contenu du `.p8` sur **une seule ligne** avec des `\n` littéraux
  (pas de vrais retours à la ligne, sinon systemd casse le parsing).
- **`GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`** : le JSON brut entre quotes simples, sur une ligne.
- Tant qu'un bloc est vide ou faux, l'endpoint correspondant renvoie **503 volontairement**
  (ce n'est pas un bug — c'est ton premier signal de diagnostic).

Le `.env` est chargé via `EnvironmentFile=/etc/sejourfr/backend.env` dans le service systemd
(§3.4). Aucune modif du `.service` ni du `application-prod.yaml` n'est nécessaire : les clés
mappent déjà vers `sejourfr.apple.*` / `sejourfr.google.*`.

---

## 2. Les certs racine Apple — dans le jar, pas sur le VPS

Piège : **les certs Apple ne se déposent PAS sur le serveur**, ils sont embarqués dans
`src/main/resources/apple/` **au build**. Donc ça se fait sur la machine de dev avant
`mvnw package` :

```
backend_sejourfr/src/main/resources/apple/AppleRootCA-G3.cer   # OBLIGATOIRE
backend_sejourfr/src/main/resources/apple/AppleRootCA-G2.cer   # par sécurité
backend_sejourfr/src/main/resources/apple/AppleIncRootCertificate.cer
```

Téléchargeables depuis <https://www.apple.com/certificateauthority/>. **Sans le G3, le bean
Apple reste en 503** même avec les bonnes variables d'env. Après ajout, rebuild + redéploiement
du jar via la procédure §6 du mémo (`scp` → `systemctl stop` → `mv app.jar` → `start`).

---

## 3. Les Product IDs en base — Postgres sur le VPS

Les SKUs ne sont **pas** en config : ils vivent dans `plans`, colonnes `apple_product_id` /
`google_product_id`, NULL au départ. Tant qu'elles sont NULL, **la card ne s'affiche pas dans
le paywall mobile** (le SKU revient dans `notFoundIDs`).

```bash
psql -h localhost -U sejourfr -d sejourfr
```

```sql
UPDATE plans
SET apple_product_id = code
WHERE code LIKE 'CIVIQUE_%'
   OR code LIKE 'INTEGRAL_%';
UPDATE plans
SET google_product_id = code
WHERE code LIKE 'CIVIQUE_%'
   OR code LIKE 'INTEGRAL_%';
```

Marche parce que la convention recommandée est `apple_product_id == plans.code`
(ex. `CIVIQUE_MONTHLY`). Ces IDs doivent matcher **exactement** ce que tu crées dans App Store
Connect / Play Console. Alternative plus propre : via l'admin `/plans`. Les 6 plans
(Civique + Intégral × mensuel/trimestriel/annuel) doivent être couverts.

---

## 4. Nginx — les webhooks doivent passer

Renouvellements et annulations arrivent via des webhooks appelés **depuis l'extérieur** par
Apple et Google :

- `POST https://api.sejourfr.fr/api/billing/webhooks/apple`
- `POST https://api.sejourfr.fr/api/billing/webhooks/google`

Le bloc Nginx `api.sejourfr.fr` fait déjà `proxy_pass :8080` pour tout — ces routes passent
sans config dédiée. Ces URLs sont aussi à renseigner côté Apple (ASSN V2, prod **et** sandbox)
et côté Google (Pub/Sub push subscription, avec `GOOGLE_PUBSUB_AUDIENCE` = l'URL exacte).

---

## 5. Appliquer et vérifier

```bash
sudo systemctl restart sejourfr-backend
sudo journalctl -u sejourfr-backend -f
curl http://localhost:8080/actuator/health
```

Check le plus parlant : `GET /api/billing/plans` (public) et vérifier que les
`apple_product_id` / `google_product_id` remontent bien remplis.

| Symptôme                             | Cause sur le VPS                                                                                    |
|--------------------------------------|-----------------------------------------------------------------------------------------------------|
| `/api/billing/*` → **503**           | une variable `APPLE_*` / `GOOGLE_*` vide ou mal formée dans `backend.env`                           |
| Card absente du paywall mobile       | colonne `apple/google_product_id` NULL en base, ou ID ≠ store                                       |
| Webhook Apple/Google ignoré          | signature JWS / Bearer JWT invalide → vérifier `GOOGLE_PUBSUB_AUDIENCE` et `GOOGLE_PUBSUB_SA_EMAIL` |
| Bean Apple reste 503 malgré les vars | cert `AppleRootCA-G3.cer` absent du jar (rebuild requis)                                            |

---

## Ordre des opérations sur le VPS

1. `nano /etc/sejourfr/backend.env` → poser les 6 vars Apple + 4 vars Google
2. (sur dev) ajouter les 3 certs Apple dans `resources/apple/`, rebuild, redéployer le jar
3. `psql` → remplir `apple_product_id` + `google_product_id` sur les 6 plans
4. vérifier que Nginx route les `/webhooks/apple|google` (déjà le cas)
5. `systemctl restart sejourfr-backend` + health check + `/api/billing/plans`

Le reste (créer les SKUs dans les dashboards, Pub/Sub, SHA-1 Android) se fait hors VPS —
checklist §6 de `paiements-iap-setup.md`.

---

## 6. Re-tester un achat de zéro (sandbox Apple)

**Symptôme** : après un premier achat réussi, la feuille Apple Pay ne s'ouvre plus —
Apple affiche « vous êtes déjà abonné » et renvoie la transaction existante sans
prélèvement. C'est normal : un abonnement auto-renouvelable reste actif côté Apple, et
StoreKit refuse de le racheter tant qu'il court. Pour repartir d'un état vierge il faut
réinitialiser **les deux côtés** : la base backend **et** l'état sandbox Apple.

### 6.1 Réinitialiser le backend (base dev)

Libère le(s) reçu(s) pour que le prochain achat reparte sur une ligne neuve :

```sql
-- Tout effacer (DEV uniquement) :
DELETE FROM user_subscriptions WHERE source = 'APPLE';

-- Ou cibler un reçu précis :
DELETE FROM user_subscriptions
WHERE source = 'APPLE' AND original_transaction_id = '<originalTransactionId>';

-- Si tu testes aussi les WEBHOOKS (ASSN V2) : vider l'idempotence pour rejouer
-- les mêmes notifications. Sinon un replay du même event est skippé en silence.
DELETE FROM processed_external_events WHERE provider = 'apple';
```

> `verify-receipt` n'est PAS bloqué par `processed_external_events` (cette table ne
> dédoublonne que les webhooks). Pour le simple ré-achat, le `DELETE` sur
> `user_subscriptions` suffit. La ligne `apple_product_id` des plans, elle, reste en
> place — ne pas y toucher.

### 6.2 Réinitialiser l'abonnement sandbox Apple

C'est ce qui débloque la réouverture de la feuille d'achat. Trois options, de la plus
propre à la plus rapide :

1. **Clear Purchase History** (recommandé) — App Store Connect → **Users and Access →
   Sandbox → Testers** → le testeur concerné → **Clear Purchase History**. Remet à zéro
   ses abonnements sandbox : le prochain achat repart comme un premier achat.
   ⚠ En pratique le clear **ne force pas toujours l'expiration immédiate** : si l'abo
   sandbox est encore dans sa période active, Apple répond « déjà abonné, expire le… » et
   **rejoue le reçu existant** (chemin restauration) au lieu d'ouvrir une feuille de
   paiement neuve. Ce n'est pas un échec : le reçu remonte quand même à `verify-receipt`,
   et comme la ligne backend a été supprimée (§6.1) elle est **recréée et rattachée au
   compte courant** (snackbar « Bienvenue dans Intégral »). Tu verras alors le **même**
   `originalTransactionId` qu'avant. Pour un vrai « premier achat » (feuille Apple Pay +
   **nouvel** `originalTransactionId`), passe par l'option 2.
2. **Nouveau testeur sandbox** — créer un 2ᵉ compte sandbox et l'utiliser sur l'appareil
   (Réglages → App Store → section *SANDBOX ACCOUNT*). Chaque testeur a son propre
   `originalTransactionId`, donc aucune collision avec l'historique précédent. C'est ce qui
   reflète le mieux la réalité prod (un nouvel utilisateur = un nouvel achat).
3. **Laisser expirer** — en sandbox les durées sont accélérées (1 mois ≈ 5 min, 1 an ≈ 1 h,
   max ~6 renouvellements puis expiration auto). Tu peux attendre l'expiration, mais
   « Clear Purchase History » est immédiat.

> ⚠ Le compte **Apple sandbox** (celui des Réglages iOS) est indépendant des comptes
> **SejourFR** (email/mot de passe applicatif). Changer de compte SejourFR sans changer de
> compte Apple sandbox = même reçu = **409** anti-account-stealing (comportement voulu, cf.
> §5 de `paiements-iap-setup.md`). Pour tester deux achats distincts, il faut un **2ᵉ
> compte Apple sandbox**, pas seulement un 2ᵉ compte SejourFR.

### 6.3 Recette de re-test « tout propre »

1. `DELETE FROM user_subscriptions WHERE source = 'APPLE';` (base dev)
2. App Store Connect → Sandbox → Testers → **Clear Purchase History** sur le testeur
3. Sur l'appareil : se reconnecter au compte SejourFR de test
4. Relancer l'achat → la feuille Apple Pay s'ouvre → flow complet `verify-receipt`
5. Vérifier : `SELECT email, source, status, product_id FROM user_subscriptions us
   JOIN users u ON u.id = us.user_id;` → la ligne est bien rattachée au bon compte

Sur le **VPS** c'est identique, en remplaçant la connexion locale par
`psql -h localhost -U sejourfr -d sejourfr` (cf. §5 du mémo déploiement).
