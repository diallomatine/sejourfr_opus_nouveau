-- ============================================================================
-- V038 — Geste commercial envers les acheteurs de l'ANCIEN catalogue Intégral
-- ----------------------------------------------------------------------------
-- Le produit a profondément changé depuis leur achat (diagnostic initial, Plan
-- personnalisé, module Compétences et ses petits sujets, entretien oral en temps
-- réel avec un examinateur IA). Ces clients ont payé avant la grille actuelle et
-- avant que ces briques existent. On leur rouvre un accès Intégral et on garantit
-- un socle de simulations orales.
--
--   INTEGRAL_PASS_SPRINT (6 semaines, 19,99 €) -> +14 jours ·  5 simulations
--   INTEGRAL_PASS_3M     (3 mois,     34,99 €) -> +21 jours · 15 simulations
--
-- ⚠ Les autres profils sont VOLONTAIREMENT hors périmètre pour l'instant et
--   n'ont RIEN reçu : INTEGRAL_PASS_1Y, les abonnements récurrents Intégral
--   (dormants) et tous les passes Civique (aucun accès TCF, donc aucune
--   simulation utilisable). Élargir = ajouter une ligne au barème ci-dessous
--   dans une NOUVELLE migration, jamais réécrire celle-ci.
--
-- ---------------------------------------------------------------------------
-- Quatre règles, chacune motivée par une mécanique existante du dépôt :
--
-- 1. LE SOLDE VIT SUR LA SOUSCRIPTION, PAS SUR LE PLAN. Depuis V019 le compteur
--    est `user_subscriptions.realtime_eo_sessions_remaining` ;
--    `plans.realtime_eo_sessions` n'est plus qu'un cap d'affichage. Toucher le
--    plan ne changerait donc rien au solde d'un client existant.
--
-- 2. ON NE RETIRE JAMAIS RIEN : `GREATEST(solde, plancher)`. Le backfill V019 a
--    posé jusqu'à 25 (sprint) et 60 (3 mois) sur ces lignes. Fixer sèchement à 5
--    et 15 en reprendrait 20 et 45 — dans un e-mail qui annonce un cadeau.
--    Le barème est donc un PLANCHER, pas une valeur imposée.
--
-- 3. UN SEUL GESTE PAR UTILISATEUR, POSÉ SUR LA LIGNE QUI FERA FOI.
--    `RealtimeQuotaService` lit le solde via `SubscriptionService
--    .currentSubscription()`, qui ne retient qu'UNE souscription (Intégral >
--    Civique, puis `ends_at` le plus tardif). Créditer une ligne perdante serait
--    invisible dans l'app. On vise donc la souscription Intégral du compte dont
--    le `ends_at` est le plus tardif — après prolongation elle reste la plus
--    tardive, donc elle est bien celle que l'app lira. Le barème retenu est
--    celui du MEILLEUR pass acheté (3 mois > sprint).
--
-- 4. « PROLONGER » UN PASS EXPIRÉ, C'EST LE ROUVRIR. L'expiration est lazy
--    (`SubscriptionService.isCovering` : statut couvrant ET `ends_at > now`), donc
--    `ends_at + 14 j` sur un pass mort depuis deux mois resterait dans le passé.
--    D'où `GREATEST(ends_at, now()) + N jours` : le compte à rebours part de la
--    mise en production. Et comme un statut `EXPIRED` bloque `isCovering` quelle
--    que soit la date, on le repasse `ACTIVE` — sinon la prolongation n'ouvrirait
--    aucun accès. `REFUNDED` (remboursés) et `PENDING` (jamais payés) sont exclus,
--    ainsi que les comptes supprimés.
--
-- La table de trace n'est pas décorative : elle sert d'anti-doublon au mailing
-- (`mailed_at`), d'audit de ce qui a été donné, et de plan de retour arrière.
-- ============================================================================

CREATE TABLE legacy_pass_compensations (
    id               uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id          uuid        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id  uuid        NOT NULL REFERENCES user_subscriptions(id) ON DELETE CASCADE,
    plan_code        varchar(64) NOT NULL,
    days_granted     int         NOT NULL,
    ends_at_before   timestamptz,
    ends_at_after    timestamptz,
    sessions_before  int         NOT NULL,
    sessions_after   int         NOT NULL,
    granted_at       timestamptz NOT NULL DEFAULT now(),
    mailed_at        timestamptz,
    CONSTRAINT ux_legacy_pass_comp_user UNIQUE (user_id)
);

COMMENT ON TABLE legacy_pass_compensations IS
    'Geste commercial V038 envers les acheteurs de l''ancien catalogue Intégral. Une ligne par utilisateur compensé : ce qui a été donné (audit), et si l''e-mail d''annonce est parti (mailed_at, anti-doublon du mailing admin).';
COMMENT ON COLUMN legacy_pass_compensations.plan_code IS
    'Pass qui a ouvert le droit (barème retenu = meilleur pass acheté), pas forcément le plan de subscription_id.';
COMMENT ON COLUMN legacy_pass_compensations.subscription_id IS
    'Souscription effectivement créditée : celle que SubscriptionService.currentSubscription() lira.';
COMMENT ON COLUMN legacy_pass_compensations.mailed_at IS
    'NULL = e-mail d''annonce pas encore envoyé. Posé par POST /api/admin/mailing/anciens-acheteurs.';

-- Les destinataires restant à traiter par le mailing admin.
CREATE INDEX idx_legacy_pass_comp_a_envoyer
    ON legacy_pass_compensations (granted_at)
    WHERE mailed_at IS NULL;

-- ---------------------------------------------------------------------------
-- Application du geste
-- ---------------------------------------------------------------------------
-- ⚠ La ligne sentinelle ci-dessous est LUE PAR UN TEST. `LegacyPassCompensationIT`
--   charge ce fichier, coupe dessus et rejoue les deux ordres qui suivent sur des
--   jeux d'essai — c'est ainsi que la logique de ciblage et le barème sont
--   vérifiés sans recopier le SQL ailleurs (une copie aurait fini par diverger de
--   ce qui tourne réellement en production). Ne pas la supprimer ni la reformuler.
-- @@APPLICATION_DU_GESTE@@
WITH bareme (plan_code, jours, plancher_sessions) AS (
    VALUES ('INTEGRAL_PASS_SPRINT', 14,  5),
           ('INTEGRAL_PASS_3M',     21, 15)
),
-- Droit ouvert par compte : le meilleur pass éligible qu'il a acheté.
droit AS (
    SELECT DISTINCT ON (us.user_id)
           us.user_id, b.plan_code, b.jours, b.plancher_sessions
    FROM user_subscriptions us
    JOIN plans  p ON p.id = us.plan_id
    JOIN users  u ON u.id = us.user_id
    JOIN bareme b ON b.plan_code = p.code
    WHERE u.deleted_at IS NULL
      AND us.status NOT IN ('REFUNDED', 'PENDING')
    ORDER BY us.user_id, b.jours DESC
),
-- Ligne créditée : la souscription Intégral du compte qui portera l'accès.
cible AS (
    SELECT DISTINCT ON (us.user_id)
           us.user_id,
           us.id      AS subscription_id,
           us.ends_at AS ends_at_before,
           us.realtime_eo_sessions_remaining AS sessions_before
    FROM user_subscriptions us
    JOIN plans p ON p.id = us.plan_id
    JOIN droit d ON d.user_id = us.user_id
    WHERE p.module_access = 'INTEGRAL'
      AND us.status NOT IN ('REFUNDED', 'PENDING')
    ORDER BY us.user_id, us.ends_at DESC NULLS FIRST, us.updated_at DESC, us.id
)
INSERT INTO legacy_pass_compensations
    (user_id, subscription_id, plan_code, days_granted,
     ends_at_before, ends_at_after, sessions_before, sessions_after)
SELECT c.user_id,
       c.subscription_id,
       d.plan_code,
       d.jours,
       c.ends_at_before,
       -- ends_at NULL = accès sans terme (lignes seed) : on n'invente pas de fin.
       CASE WHEN c.ends_at_before IS NULL THEN NULL
            ELSE GREATEST(c.ends_at_before, now()) + make_interval(days => d.jours)
       END,
       c.sessions_before,
       GREATEST(c.sessions_before, d.plancher_sessions)
FROM cible c
JOIN droit d ON d.user_id = c.user_id;

UPDATE user_subscriptions us
SET ends_at = COALESCE(c.ends_at_after, us.ends_at),
    realtime_eo_sessions_remaining = c.sessions_after,
    -- Un statut EXPIRED/CANCELED bloque isCovering quelle que soit la date :
    -- sans cette remise à ACTIVE, la prolongation n'ouvrirait aucun accès.
    status = CASE WHEN us.status IN ('EXPIRED', 'CANCELED') THEN 'ACTIVE' ELSE us.status END,
    updated_at = now()
FROM legacy_pass_compensations c
WHERE c.subscription_id = us.id;
