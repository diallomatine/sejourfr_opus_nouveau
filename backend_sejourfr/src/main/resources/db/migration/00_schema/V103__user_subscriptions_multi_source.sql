-- ============================================================================
-- V103 — UserSubscription multi-source (Stripe + Apple + Google).
--
-- Pourquoi : l'app mobile va vendre du Premium via App Store IAP et Google
-- Play Billing. Le backend doit centraliser le statut Premium sans permettre
-- au client de mentir : UserSubscription devient la source de vérité unique,
-- alimentée par 3 canaux (Stripe web, Apple iOS, Google Android) qui ne
-- doivent jamais se contredire.
--
-- Schéma :
--   - source                  enum 'STRIPE'|'APPLE'|'GOOGLE' (NOT NULL)
--   - external_transaction_id  id de transaction propre à la source
--   - original_transaction_id  id de réconciliation des renouvellements :
--                               * Apple : originalTransactionId (stable sur
--                                 toute la chaîne de renouvellements d'un
--                                 user)
--                               * Google : purchaseToken (idem)
--                               * Stripe : subscription_id (ou session_id en
--                                 mode one-shot historique)
--                              c'est CETTE valeur qu'on utilise pour upsert
--                              un abonnement existant lors d'un
--                              renouvellement, pas l'external_transaction_id
--                              qui lui change à chaque tick.
--   - product_id              SKU côté store (ex: "integral_monthly")
--   - auto_renew              flag de renouvellement automatique
--   - updated_at              timestamp de dernière mise à jour (webhooks)
--
-- Idempotence : index UNIQUE sur (source, original_transaction_id). Quand un
-- webhook arrive pour un renouvellement, on retrouve la ligne existante au
-- lieu d'en créer une nouvelle.
--
-- Backfill : les lignes existantes (toutes Stripe) reçoivent source='STRIPE'
-- et original_transaction_id = stripe_subscription_id (qui est en fait un
-- checkout session id en mode one-shot — on garde le mapping cohérent).
--
-- L'index unique partiel sur stripe_subscription_id (V101) est remplacé par
-- l'index unique multi-source. Les anciennes colonnes Stripe restent en place
-- pour le code existant — on les conservera tant que la refonte des plans
-- (lot 4) n'est pas faite.
-- ============================================================================

ALTER TABLE user_subscriptions
    ADD COLUMN source VARCHAR(16),
    ADD COLUMN external_transaction_id VARCHAR(255),
    ADD COLUMN original_transaction_id VARCHAR(255),
    ADD COLUMN product_id VARCHAR(128),
    ADD COLUMN auto_renew BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Backfill avant le NOT NULL : toutes les souscriptions actuelles viennent
-- de Stripe. Pour les lignes seed/admin sans stripe_subscription_id, on
-- forge une clé synthétique basée sur l'UUID interne (rare en pratique,
-- mais évite un crash sur les comptes de dev).
UPDATE user_subscriptions
SET source = 'STRIPE',
    external_transaction_id = stripe_subscription_id,
    original_transaction_id = COALESCE(stripe_subscription_id, 'seed_' || id::text)
WHERE source IS NULL;

ALTER TABLE user_subscriptions
    ALTER COLUMN source SET NOT NULL,
    ALTER COLUMN original_transaction_id SET NOT NULL;

-- Idempotence des renouvellements : un même (source, original_transaction_id)
-- = un seul user_subscription. Les webhooks de renouvellement updatent la
-- ligne au lieu d'en créer une nouvelle.
CREATE UNIQUE INDEX ux_user_subscriptions_source_original
    ON user_subscriptions(source, original_transaction_id);

-- L'ancien index partiel sur stripe_subscription_id (V101) devient redondant
-- avec le nouvel index multi-source. On le drop pour éviter la double
-- contrainte sur les rows Stripe.
DROP INDEX IF EXISTS ux_user_subscriptions_stripe_id;

-- Lookup webhook : on retrouve souvent un abonnement par sa source uniquement
-- (toutes les souscriptions Apple d'un user, etc.).
CREATE INDEX IF NOT EXISTS idx_user_subs_source ON user_subscriptions(source);

-- Trigger soft : updated_at posé en code applicatif, pas par trigger SQL —
-- cohérent avec les autres tables et plus facile à débogger.
