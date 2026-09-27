-- ============================================================================
-- V079 — Date d'achat : les achats anterieurs a la mesure recoivent leur
--        date de mise a jour (2026-09-27)
-- ----------------------------------------------------------------------------
-- Decision du proprietaire : une souscription sans `purchased_at` (achat
-- anterieur au chantier Suivi, V074) prend `updated_at` comme date d'achat
-- par defaut, pour entrer dans le filtre « Achats du mois » de l'admin.
-- A partir de maintenant la date d'achat ne bouge jamais : elle est posee a
-- la creation (OneTimeAccessService) et la colonne n'est plus modifiable par
-- JPA (`updatable = false`).
--
-- Deterministe et idempotente : ne touche que les lignes encore NULL.
-- Les champs de revenu de ces lignes restent NULL (« on ne sait pas ») : seule
-- la date est posee, aucun montant n'est invente.
-- ============================================================================
UPDATE user_subscriptions
SET purchased_at = updated_at
WHERE purchased_at IS NULL
  AND updated_at IS NOT NULL;
