-- ============================================================================
-- V101 — Idempotence des évènements externes (webhooks Stripe, à terme Google
-- Apple etc.).
--
-- Pourquoi : Stripe re-livre un même évènement si le 200 n'est pas retourné
-- dans les 30 s (timeout HTTP), et l'admin peut cliquer "Resend" depuis le
-- dashboard. Sans déduplication, chaque replay re-active un abonnement →
-- l'utilisateur cumule de la durée. Cf audit sécurité Vuln 4.
--
-- Pattern : avant tout side-effect, INSERT ON CONFLICT DO NOTHING dans cette
-- table. Si 0 row affectée → on a déjà traité l'évènement, on skip.
--
-- + UNIQUE INDEX partiel sur user_subscriptions.stripe_subscription_id pour
-- une défense en profondeur (impossible de créer 2 lignes avec la même
-- session checkout, même si le code rate la vérif d'idempotence).
-- ============================================================================

CREATE TABLE processed_external_events (
    provider     VARCHAR(32) NOT NULL,
    event_id     VARCHAR(255) NOT NULL,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (provider, event_id)
);

-- Permet plusieurs subs sans stripe_subscription_id (cas seed / admin manuel)
-- mais bloque tout doublon dès qu'un ID est posé.
CREATE UNIQUE INDEX ux_user_subscriptions_stripe_id
    ON user_subscriptions(stripe_subscription_id)
    WHERE stripe_subscription_id IS NOT NULL;
