-- Compteur de sessions EO temps réel STOCKÉ sur la souscription, au lieu d'être
-- dérivé par comptage des lignes `realtime_sessions`.
--
-- Pourquoi : le modèle par comptage ne permettait pas d'ajuster le solde d'un
-- utilisateur (ni de cumuler proprement à la prolongation). Désormais :
--   * à la souscription : solde = plans.realtime_eo_sessions ;
--   * à la prolongation / au ré-achat : on cumule (report du reste + allocation du pass) ;
--   * à la connexion réelle d'une session (status -> ACTIVE) : on décrémente de 1 ;
--   * l'admin peut ajuster le solde directement.
ALTER TABLE user_subscriptions
    ADD COLUMN realtime_eo_sessions_remaining INT NOT NULL DEFAULT 0;

-- Backfill : reproduit EXACTEMENT le solde de l'ancien modèle au moment de la
-- bascule (cap du plan − sessions déjà consommées = ACTIVE|COMPLETED, scopé sur
-- la souscription), pour ne rien offrir ni retirer. Les plans sans TCF
-- (Civique / Free) portent 0 → solde 0.
UPDATE user_subscriptions us
SET realtime_eo_sessions_remaining = GREATEST(0,
        COALESCE((SELECT p.realtime_eo_sessions FROM plans p WHERE p.id = us.plan_id), 0)
        - COALESCE((
            SELECT COUNT(*) FROM realtime_sessions rs
            WHERE rs.subscription_id = us.id
              AND rs.status IN ('ACTIVE', 'COMPLETED')
          ), 0)
    );
