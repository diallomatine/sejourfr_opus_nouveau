-- Horodatage de l'envoi du rappel « ton accès se termine bientôt » (passes
-- one-time, lot 5). NULL = pas encore rappelé. Évite les doublons d'e-mail :
-- le job d'expiration ne traite que les lignes à expiry_reminded_at NULL.
ALTER TABLE user_subscriptions
    ADD COLUMN expiry_reminded_at TIMESTAMPTZ;

COMMENT ON COLUMN user_subscriptions.expiry_reminded_at IS
    'Pass one-time : date d''envoi du rappel d''expiration (anti-doublon). NULL si non rappelé / sans objet.';
