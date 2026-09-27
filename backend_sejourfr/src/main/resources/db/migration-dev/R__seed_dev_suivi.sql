-- ============================================================================
-- R__seed_dev_suivi (DEV UNIQUEMENT) — jeu de donnees de relecture de l'ecran
-- admin « Suivi » (/dashboard, GET /api/admin/analytics/suivi).
-- ----------------------------------------------------------------------------
-- Couvre les 20 scenarios de docs/admin/decisions-suivi.md §3.2 (brief §12 +
-- 18-20), lus par SuiviReadRepository. Les ecritures reelles (claim, soumis,
-- webhooks, montants) sont verrouillees par les tests ; ici on seme l'ETAT
-- qu'elles produisent, comme SuiviScenariosIT.
--
-- POURQUOI UNE MIGRATION REPETABLE (R__) et pas un V9xx : les dates sont
-- RELATIVES A now() (aujourd'hui, hier, 7 derniers jours, mois en cours) pour
-- que les presets de l'ecran montrent des chiffres. Un V9xx ne s'applique
-- qu'une fois : trois jours plus tard, « Aujourd'hui » serait vide. Le
-- placeholder Flyway ci-dessous change a chaque demarrage, donc la checksum
-- aussi : Flyway REJOUE ce fichier a chaque boot dev, apres les V*.
--   rejoue le : ${flyway:timestamp}
-- Le fichier est idempotent : il efface d'abord tout ce qu'il a seme.
--
-- 🛑 Jamais en production ni dans les tests : db/migration-dev n'est lu que par
-- le profil dev (application-dev.yaml). Zonky n'applique que db/migration.
--
-- Perimetre : comptes `suivi.*@sejourfr.test` (sans mot de passe : on ne s'y
-- connecte pas) et identifiants `5e1f5e1f-*`. Aucun compte seed existant
-- (admin@, user@, karim.test@) n'est touche.
--
-- Les dates de debut de mesure du profil dev sont posees par
-- application-dev.yaml (sejourfr.analytics.measurement-start-overrides) ; la
-- config versionnee analytics-config-v1.json ne change pas (D43).
--
-- Montants : figes comme a l'ecriture par RevenueCalculator (revenue-rules-v1,
-- franchise 293B pour Stripe, stores MULTIPLY 0,15, TVA store 20 %) :
--   Stripe  9,99 -> tva 0,   frais 40,  net 959   | Store  9,99 -> 166 / 125 / 708
--   Stripe 19,99 -> tva 0,   frais 55,  net 1944  | Store 29,99 -> 500 / 375 / 2124
--   Stripe 29,99 -> tva 0,   frais 70,  net 2929
-- Invariant (CHECK V074) : brut = tva + frais + net HT.
-- ============================================================================


-- ---------------------------------------------------------------------------
-- 0. Nettoyage de la passe precedente (ordre impose par les FK)
-- ---------------------------------------------------------------------------
-- Visiteurs -> cascade sur analytics_event et analytics_identity.
DELETE FROM analytics_visitor WHERE CAST(anonymous_id AS text) LIKE '5e1f5e1f-%';
-- Comptes -> cascade sur user_subscriptions (-> payment_refunds), purchase_intent.
DELETE FROM users WHERE email LIKE 'suivi.%@sejourfr.test';
DELETE FROM diagnostic_run WHERE CAST(id AS text) LIKE '5e1f5e1f-%';


-- ---------------------------------------------------------------------------
-- 1. Outils de la passe (schema temporaire de la connexion, disparaissent avec elle)
-- ---------------------------------------------------------------------------

-- Identifiant deterministe : famille (1 compte, 2 visiteur, 3 run, 4 achat,
-- 5 intention, 6 remboursement, 7 evenement rejoue) + numero.
CREATE OR REPLACE FUNCTION pg_temp.suivi_uuid(famille int, n int) RETURNS uuid
    LANGUAGE sql IMMUTABLE AS $$
SELECT CAST('5e1f5e1f-' || lpad(CAST(famille AS text), 4, '0') || '-4000-8000-'
            || lpad(CAST(n AS text), 12, '0') AS uuid)
$$;

-- Instant a `jours` jours d'aujourd'hui, a heure:minute HEURE DE PARIS. Jamais
-- dans le futur (une heure d'aujourd'hui pas encore arrivee est ramenee a
-- now() - 1 min ; monotone, donc l'ordre des etapes est conserve).
CREATE OR REPLACE FUNCTION pg_temp.suivi_j(jours int, heure int, minute int DEFAULT 0) RETURNS timestamptz
    LANGUAGE sql AS $$
SELECT least((date_trunc('day', now() AT TIME ZONE 'Europe/Paris')
              - make_interval(days => jours)
              + make_interval(hours => heure, mins => minute)) AT TIME ZONE 'Europe/Paris',
             now() - interval '1 minute')
$$;

-- Evenement analytics (event_id et session tires au hasard : un evenement neuf).
CREATE OR REPLACE FUNCTION pg_temp.suivi_evt(visiteur uuid, evt text, le timestamptz, plateforme text,
                                             compte uuid DEFAULT NULL, run uuid DEFAULT NULL,
                                             type_diag text DEFAULT NULL, interne boolean DEFAULT false)
    RETURNS void LANGUAGE sql AS $$
INSERT INTO analytics_event (id, event, occurred_at, anonymous_id, session_id, user_id, properties,
                             event_id, received_at, platform, diagnostic_type, diagnostic_run_id, is_internal)
VALUES (gen_random_uuid(), evt, le, visiteur, gen_random_uuid(), compte, '{}'::jsonb,
        gen_random_uuid(), le, plateforme, type_diag, run, interne)
$$;

-- Visiteur + son premier evenement (LANDING_VIEWED). `source` = colonne
-- normalisee (TrafficSource : « ig » y devient « autre », NULL pour le natif
-- depuis V076), `brute` = source declaree (regroupee a la lecture).
CREATE OR REPLACE FUNCTION pg_temp.suivi_visiteur(n int, brute text, source text, plateforme text,
                                                  appareil text, le timestamptz,
                                                  interne boolean DEFAULT false)
    RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
    v uuid := pg_temp.suivi_uuid(2, n);
BEGIN
    INSERT INTO analytics_visitor (anonymous_id, first_seen_at, last_seen_at, ft_source, ft_source_raw,
                                   lt_source, lt_seen_at, device_type, platform)
    VALUES (v, le, le, source, brute, source, le, appareil, plateforme);
    PERFORM pg_temp.suivi_evt(v, 'LANDING_VIEWED', le, plateforme, NULL, NULL, NULL, interne);
    RETURN v;
END
$$;

-- Compte `suivi.<prenom>@sejourfr.test`, sans mot de passe. Contexte
-- d'inscription tel que le pose l'auth (NULL = client ancien, D98).
CREATE OR REPLACE FUNCTION pg_temp.suivi_compte(n int, prenom text, le timestamptz, source text,
                                                plateforme text, contexte text, type_diag text,
                                                visiteur uuid, interne boolean DEFAULT false)
    RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
    u uuid := pg_temp.suivi_uuid(1, n);
BEGIN
    INSERT INTO users (id, email, password_hash, first_name, last_name, role, is_active, created_at,
                       signup_source, signup_platform, signup_context, signup_diagnostic_type,
                       signup_anonymous_id, is_internal)
    VALUES (u, 'suivi.' || prenom || '@sejourfr.test', NULL, initcap(prenom), 'Suivi', 'USER', TRUE, le,
            source, plateforme, contexte, type_diag, visiteur, interne);
    IF visiteur IS NOT NULL THEN
        INSERT INTO analytics_identity (anonymous_id, user_id, linked_at) VALUES (visiteur, u, le);
    END IF;
    RETURN u;
END
$$;

-- Lien visiteur -> compte (connexion d'un compte existant sur un appareil).
CREATE OR REPLACE FUNCTION pg_temp.suivi_lien(visiteur uuid, compte uuid, le timestamptz)
    RETURNS void LANGUAGE sql AS $$
INSERT INTO analytics_identity (anonymous_id, user_id, linked_at) VALUES (visiteur, compte, le)
ON CONFLICT DO NOTHING
$$;

-- Run = « sujet vu ». Une run d'invite porte un jeton de claim (2 j, D91).
CREATE OR REPLACE FUNCTION pg_temp.suivi_run(n int, type_diag text, plateforme text, visiteur uuid,
                                             compte uuid, le timestamptz)
    RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
    r uuid := pg_temp.suivi_uuid(3, n);
    invite boolean := compte IS NULL AND visiteur IS NOT NULL;
BEGIN
    INSERT INTO diagnostic_run (id, diagnostic_type, platform, app_version, anonymous_id, user_id,
                                client_key, subject_viewed_at, claim_token_hash, claim_token_expires_at,
                                updated_at)
    VALUES (r, type_diag, plateforme,
            CASE WHEN plateforme IN ('IOS', 'ANDROID') THEN '2.3.0' WHEN plateforme = 'WEB' THEN '0.9.0' END,
            visiteur, compte,
            CASE WHEN visiteur IS NOT NULL THEN gen_random_uuid() END,
            le,
            CASE WHEN invite THEN encode(sha256(convert_to('seed-suivi-' || r, 'UTF8')), 'hex') END,
            CASE WHEN invite THEN le + interval '2 days' END,
            le);
    RETURN r;
END
$$;

-- « Soumis ». Civique : compteurs figes a la soumission (V076), la lecture
-- exige >= 80 % (civicSubmittedMinAnsweredRatio).
CREATE OR REPLACE FUNCTION pg_temp.suivi_soumis(run uuid, le timestamptz, connecte boolean,
                                                repondues int DEFAULT 40, posees int DEFAULT 40)
    RETURNS void LANGUAGE sql AS $$
UPDATE diagnostic_run
   SET submitted_at = le, submitted_authenticated = connecte,
       submitted_answered_count = CASE WHEN diagnostic_type = 'CIVIQUE' THEN repondues END,
       submitted_question_count = CASE WHEN diagnostic_type = 'CIVIQUE' THEN posees END,
       updated_at = le
 WHERE id = run
$$;

CREATE OR REPLACE FUNCTION pg_temp.suivi_claim(run uuid, compte uuid, genre text, canal text, le timestamptz)
    RETURNS void LANGUAGE sql AS $$
UPDATE diagnostic_run
   SET user_id = compte, claimed_at = le, claim_kind = genre, claimed_via = canal, updated_at = le
 WHERE id = run
$$;

-- Intention d'achat (Q12), TTL 24 h.
CREATE OR REPLACE FUNCTION pg_temp.suivi_intention(n int, compte uuid, cta text, plan_code text,
                                                   plateforme text, run uuid, le timestamptz,
                                                   consommee boolean)
    RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
    i uuid := pg_temp.suivi_uuid(5, n);
BEGIN
    INSERT INTO purchase_intent (id, user_id, cta_location, product_id, platform, diagnostic_run_id,
                                 created_at, expires_at, consumed_at)
    VALUES (i, compte, cta, plan_code, plateforme, run, le, le + interval '24 hours',
            CASE WHEN consommee THEN le + interval '5 minutes' END);
    RETURN i;
END
$$;

-- Achat encaisse, decomposition figee (NULL partout = inconnue, tout ou rien).
-- updated_at = date de l'achat (puis du remboursement, cf. suivi_remboursement) :
-- sans elle, le DEFAULT now() datait les 14 lignes de l'heure du boot, et la
-- colonne « Maj » de /subscriptions bougeait a chaque redemarrage du dev.
-- ON CONFLICT DO NOTHING : un webhook rejoue n'ecrit rien (scenario 11).
CREATE OR REPLACE FUNCTION pg_temp.suivi_achat(n int, compte uuid, plan_code text, fournisseur text,
                                               le timestamptz, devise text, brut_devise int, brut_eur int,
                                               tva int, frais int, net_ht int, source_frais text,
                                               origine text, run uuid, intention uuid,
                                               statut text DEFAULT 'ACTIVE', paiement text DEFAULT 'PAID',
                                               transaction text DEFAULT NULL)
    RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
    a uuid := pg_temp.suivi_uuid(4, n);
BEGIN
    INSERT INTO user_subscriptions (id, user_id, plan_id, status, starts_at, ends_at, source,
                                    original_transaction_id, product_id, auto_renew, amount_cents, currency,
                                    amount_eur_cents, fx_rate_to_eur, purchased_at, vat_cents,
                                    provider_fee_cents, net_after_fee_cents, net_ex_vat_cents, fee_source,
                                    revenue_rules_version, origin, diagnostic_run_id, purchase_intent_id,
                                    payment_status, updated_at)
    SELECT a, compte, p.id, statut, le, le + make_interval(days => p.duration_days), fournisseur,
           COALESCE(transaction, 'seed_suivi_' || n), p.code, FALSE, brut_devise, devise,
           brut_eur, CASE WHEN brut_eur IS NOT NULL THEN 1 END, le, tva,
           frais, CASE WHEN tva IS NOT NULL THEN brut_eur - frais END, net_ht, source_frais,
           CASE WHEN tva IS NOT NULL THEN 1 END, origine, run, intention, paiement, le
      FROM plans p
     WHERE p.code = plan_code
    ON CONFLICT DO NOTHING;
    RETURN a;
END
$$;

-- Remboursement (ou litige perdu, `dispute:`), delta net HT fige.
CREATE OR REPLACE FUNCTION pg_temp.suivi_remboursement(n int, achat uuid, fournisseur text, ref text,
                                                       montant int, delta int, le timestamptz)
    RETURNS void LANGUAGE sql AS $$
INSERT INTO payment_refunds (id, subscription_id, provider, provider_refund_id, refunded_amount_cents,
                             currency, refunded_eur_cents, net_ex_vat_delta_cents, revenue_rules_version,
                             refunded_at)
VALUES (pg_temp.suivi_uuid(6, n), achat, fournisseur, ref, montant, 'EUR', montant, delta, 1, le);
UPDATE user_subscriptions SET updated_at = GREATEST(updated_at, le) WHERE id = achat;
$$;


-- ---------------------------------------------------------------------------
-- 2. Les personnes. Jn = n jours avant aujourd'hui (heure de Paris).
--    Preset « 7 derniers jours » = J6..J0 ; periode precedente = J13..J7.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    v uuid; v2 uuid; u uuid; r uuid; r2 uuid; i uuid; a uuid;
BEGIN
    -- Sc. 1, 3, 12, 17 — JEAN : arrive par /reussir?utm_source=IG (web), TCF
    -- rapide anonyme, s'inscrit sur le meme navigateur, ouvre son rapport 7 fois
    -- (compte 1), Plan, debloquer, achat Stripe 9,99 via le Plan.
    v := pg_temp.suivi_visiteur(1, 'ig', 'autre', 'WEB', 'DESKTOP_WEB', pg_temp.suivi_j(2, 9, 50));
    r := pg_temp.suivi_run(1, 'QUICK_TCF', 'WEB', v, NULL, pg_temp.suivi_j(2, 10, 5));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(2, 10, 20), FALSE);
    u := pg_temp.suivi_compte(1, 'jean', pg_temp.suivi_j(2, 10, 30), 'autre', 'WEB',
                              'AFTER_DIAGNOSTIC', 'QUICK_TCF', v);
    PERFORM pg_temp.suivi_claim(r, u, 'SIGNUP', 'SAME_DEVICE', pg_temp.suivi_j(2, 10, 30));
    UPDATE users SET signup_diagnostic_run_id = r WHERE id = u;
    FOR k IN 1..7 LOOP
        PERFORM pg_temp.suivi_evt(v, 'DIAGNOSTIC_REPORT_VIEWED', pg_temp.suivi_j(2, 10, 30 + k), 'WEB', u, r,
                                  'QUICK_TCF');
    END LOOP;
    PERFORM pg_temp.suivi_evt(v, 'PLAN_OPENED', pg_temp.suivi_j(2, 10, 40), 'WEB', u, r);
    PERFORM pg_temp.suivi_evt(v, 'PLAN_UNLOCK_CLICKED', pg_temp.suivi_j(2, 10, 45), 'WEB', u, r);
    i := pg_temp.suivi_intention(1, u, 'LOCKED_PLAN', 'INTEGRAL_PASS_7J', 'WEB', r, pg_temp.suivi_j(2, 10, 46), TRUE);
    a := pg_temp.suivi_achat(1, u, 'INTEGRAL_PASS_7J', 'STRIPE', pg_temp.suivi_j(2, 10, 50), 'EUR', 999, 999,
                             0, 40, 959, 'ACTUAL', 'DIAGNOSTIC_PLAN', r, i);
    -- Sc. 11 — le webhook d'achat de Jean arrive une 2e fois : rien n'est ecrit.
    PERFORM pg_temp.suivi_achat(901, u, 'INTEGRAL_PASS_7J', 'STRIPE', pg_temp.suivi_j(2, 10, 51), 'EUR', 999, 999,
                                0, 40, 959, 'ACTUAL', 'DIAGNOSTIC_PLAN', r, i, 'ACTIVE', 'PAID', 'seed_suivi_1');

    -- Sc. 2, 6 — AHMED : compte cree le J5 (hors diagnostic, arrive par TikTok
    -- « tt »), fait le TCF rapide PUIS le civique en etant deja connecte, va au
    -- bout des deux : Tous = 1, TCF = 1, Civique = 1 a chaque etape.
    v := pg_temp.suivi_visiteur(2, 'tt', 'autre', 'WEB', 'DESKTOP_WEB', pg_temp.suivi_j(5, 7, 55));
    u := pg_temp.suivi_compte(2, 'ahmed', pg_temp.suivi_j(5, 8, 0), 'autre', 'WEB', 'OUTSIDE_DIAGNOSTIC', NULL, v);
    r := pg_temp.suivi_run(2, 'QUICK_TCF', 'WEB', v, u, pg_temp.suivi_j(3, 9, 0));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(3, 9, 30), TRUE);
    PERFORM pg_temp.suivi_evt(v, 'DIAGNOSTIC_REPORT_VIEWED', pg_temp.suivi_j(3, 9, 35), 'WEB', u, r, 'QUICK_TCF');
    PERFORM pg_temp.suivi_evt(v, 'PLAN_OPENED', pg_temp.suivi_j(3, 9, 40), 'WEB', u, r);
    PERFORM pg_temp.suivi_evt(v, 'PLAN_UNLOCK_CLICKED', pg_temp.suivi_j(3, 9, 45), 'WEB', u, r);
    i := pg_temp.suivi_intention(2, u, 'LOCKED_PLAN', 'INTEGRAL_PASS_2M', 'WEB', r, pg_temp.suivi_j(3, 9, 46), TRUE);
    PERFORM pg_temp.suivi_achat(2, u, 'INTEGRAL_PASS_2M', 'STRIPE', pg_temp.suivi_j(3, 9, 50), 'EUR', 2999, 2999,
                                0, 70, 2929, 'ACTUAL', 'DIAGNOSTIC_PLAN', r, i);
    r := pg_temp.suivi_run(3, 'CIVIQUE', 'WEB', v, u, pg_temp.suivi_j(3, 14, 0));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(3, 14, 40), TRUE, 38, 40);
    PERFORM pg_temp.suivi_evt(v, 'DIAGNOSTIC_REPORT_VIEWED', pg_temp.suivi_j(3, 14, 45), 'WEB', u, r, 'CIVIQUE');
    PERFORM pg_temp.suivi_evt(v, 'PLAN_OPENED', pg_temp.suivi_j(3, 14, 50), 'WEB', u, r);
    PERFORM pg_temp.suivi_evt(v, 'PLAN_UNLOCK_CLICKED', pg_temp.suivi_j(3, 14, 55), 'WEB', u, r);
    i := pg_temp.suivi_intention(3, u, 'LOCKED_PLAN', 'CIVIQUE_PASS_3M', 'WEB', r, pg_temp.suivi_j(3, 14, 56), TRUE);
    PERFORM pg_temp.suivi_achat(3, u, 'CIVIQUE_PASS_3M', 'STRIPE', pg_temp.suivi_j(3, 15, 0), 'EUR', 999, 999,
                                0, 40, 959, 'ESTIMATED', 'DIAGNOSTIC_PLAN', r, i);

    -- Sc. 4 — FATOU : TCF rapide anonyme sur le web (Facebook « fb »), puis
    -- l'app iOS par le lien avec jeton : claim APP_LINK a l'inscription, rapport,
    -- Plan, debloquer et achat Apple 9,99 (net 7,08) dans l'app.
    v := pg_temp.suivi_visiteur(3, 'fb', 'autre', 'WEB', 'MOBILE_WEB', pg_temp.suivi_j(1, 10, 30));
    v2 := pg_temp.suivi_visiteur(4, NULL, NULL, 'IOS', 'IOS', pg_temp.suivi_j(1, 11, 50));
    r := pg_temp.suivi_run(4, 'QUICK_TCF', 'WEB', v, NULL, pg_temp.suivi_j(1, 10, 35));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(1, 10, 55), FALSE);
    u := pg_temp.suivi_compte(3, 'fatou', pg_temp.suivi_j(1, 12, 0), NULL, 'IOS', 'AFTER_DIAGNOSTIC', 'QUICK_TCF', v2);
    PERFORM pg_temp.suivi_claim(r, u, 'SIGNUP', 'APP_LINK', pg_temp.suivi_j(1, 12, 0));
    UPDATE users SET signup_diagnostic_run_id = r WHERE id = u;
    PERFORM pg_temp.suivi_evt(v2, 'DIAGNOSTIC_REPORT_VIEWED', pg_temp.suivi_j(1, 12, 5), 'IOS', u, r, 'QUICK_TCF');
    PERFORM pg_temp.suivi_evt(v2, 'PLAN_OPENED', pg_temp.suivi_j(1, 12, 10), 'IOS', u, r);
    PERFORM pg_temp.suivi_evt(v2, 'PLAN_UNLOCK_CLICKED', pg_temp.suivi_j(1, 12, 15), 'IOS', u, r);
    i := pg_temp.suivi_intention(4, u, 'LOCKED_PLAN', 'INTEGRAL_PASS_7J', 'IOS', r, pg_temp.suivi_j(1, 12, 16), TRUE);
    PERFORM pg_temp.suivi_achat(4, u, 'INTEGRAL_PASS_7J', 'APPLE', pg_temp.suivi_j(1, 12, 20), 'EUR', 999, 999,
                                166, 125, 708, 'ESTIMATED', 'DIAGNOSTIC_PLAN', r, i);

    -- Sc. 5 — civique anonyme sur le web SANS jeton transmis : la personne
    -- s'inscrit ensuite dans l'app Android (autre appareil) -> non rattache,
    -- OUTSIDE_DIAGNOSTIC, compte dans « soumis anonymes jamais rattaches ».
    v := pg_temp.suivi_visiteur(5, NULL, 'direct', 'WEB', 'MOBILE_WEB', pg_temp.suivi_j(4, 9, 55));
    r := pg_temp.suivi_run(5, 'CIVIQUE', 'WEB', v, NULL, pg_temp.suivi_j(4, 10, 0));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(4, 10, 30), FALSE);
    v2 := pg_temp.suivi_visiteur(6, NULL, NULL, 'ANDROID', 'ANDROID', pg_temp.suivi_j(4, 14, 55));
    PERFORM pg_temp.suivi_compte(4, 'moussa', pg_temp.suivi_j(4, 15, 0), NULL, 'ANDROID', 'OUTSIDE_DIAGNOSTIC',
                                 NULL, v2);

    -- Sc. 6 — CLAIRE : compte ancien (J40), deja connectee, TCF rapide
    -- aujourd'hui ; s'arrete au Plan (etape 5).
    u := pg_temp.suivi_compte(5, 'claire', pg_temp.suivi_j(40, 18, 0), 'direct', 'WEB', 'OUTSIDE_DIAGNOSTIC',
                              NULL, NULL);
    v := pg_temp.suivi_visiteur(27, NULL, 'direct', 'WEB', 'DESKTOP_WEB', pg_temp.suivi_j(0, 7, 0));
    PERFORM pg_temp.suivi_lien(v, u, pg_temp.suivi_j(0, 7, 0));
    r := pg_temp.suivi_run(6, 'QUICK_TCF', 'WEB', v, u, pg_temp.suivi_j(0, 7, 5));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(0, 7, 25), TRUE);
    PERFORM pg_temp.suivi_evt(v, 'DIAGNOSTIC_REPORT_VIEWED', pg_temp.suivi_j(0, 7, 30), 'WEB', u, r, 'QUICK_TCF');
    PERFORM pg_temp.suivi_evt(v, 'PLAN_OPENED', pg_temp.suivi_j(0, 7, 35), 'WEB', u, r);

    -- Sc. 7 — LUCAS : compte ancien (J60), civique fait deconnecte (36/40 = 90 %,
    -- retenu), puis connexion : « connecte apres diagnostic », pas d'inscription.
    -- Sc. 10 : un lot de ses evenements est rejoue (event_id identiques) : rien
    -- n'est ecrit en double.
    u := pg_temp.suivi_compte(6, 'lucas', pg_temp.suivi_j(60, 12, 0), 'instagram', 'WEB', 'OUTSIDE_DIAGNOSTIC',
                              NULL, NULL);
    v := pg_temp.suivi_visiteur(7, 'instagram', 'instagram', 'WEB', 'DESKTOP_WEB', pg_temp.suivi_j(1, 17, 55));
    r := pg_temp.suivi_run(7, 'CIVIQUE', 'WEB', v, NULL, pg_temp.suivi_j(1, 18, 0));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(1, 18, 25), FALSE, 36, 40);
    PERFORM pg_temp.suivi_claim(r, u, 'LOGIN', 'SAME_DEVICE', pg_temp.suivi_j(1, 18, 30));
    PERFORM pg_temp.suivi_lien(v, u, pg_temp.suivi_j(1, 18, 30));
    FOR passe IN 1..2 LOOP
        INSERT INTO analytics_event (id, event, occurred_at, anonymous_id, session_id, user_id, properties, event_id,
                                     received_at, platform, diagnostic_type, diagnostic_run_id, is_internal)
        VALUES (gen_random_uuid(), 'DIAGNOSTIC_REPORT_VIEWED', pg_temp.suivi_j(1, 18, 35), v,
                pg_temp.suivi_uuid(7, 100), u, '{}'::jsonb, pg_temp.suivi_uuid(7, 1),
                pg_temp.suivi_j(1, 18, 35) + make_interval(mins => passe), 'WEB', 'CIVIQUE', r, FALSE),
               (gen_random_uuid(), 'PRICING_VIEWED', pg_temp.suivi_j(1, 18, 40), v,
                pg_temp.suivi_uuid(7, 100), u, '{}'::jsonb, pg_temp.suivi_uuid(7, 2),
                pg_temp.suivi_j(1, 18, 40) + make_interval(mins => passe), 'WEB', NULL, NULL, FALSE)
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Sc. 8 — NADIA : TCF rapide anonyme dans l'app Android (native, sans
    -- source) le J6, inscription, Plan, debloquer le J5, achat Google 29,99 le
    -- J2 (J+4) : dans la cohorte du J6 ET dans l'activite du J2.
    v := pg_temp.suivi_visiteur(8, NULL, NULL, 'ANDROID', 'ANDROID', pg_temp.suivi_j(6, 19, 55));
    r := pg_temp.suivi_run(8, 'QUICK_TCF', 'ANDROID', v, NULL, pg_temp.suivi_j(6, 20, 0));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(6, 20, 20), FALSE);
    u := pg_temp.suivi_compte(7, 'nadia', pg_temp.suivi_j(6, 20, 25), NULL, 'ANDROID', 'AFTER_DIAGNOSTIC',
                              'QUICK_TCF', v);
    PERFORM pg_temp.suivi_claim(r, u, 'SIGNUP', 'SAME_DEVICE', pg_temp.suivi_j(6, 20, 25));
    UPDATE users SET signup_diagnostic_run_id = r WHERE id = u;
    PERFORM pg_temp.suivi_evt(v, 'DIAGNOSTIC_REPORT_VIEWED', pg_temp.suivi_j(6, 20, 30), 'ANDROID', u, r, 'QUICK_TCF');
    PERFORM pg_temp.suivi_evt(v, 'PLAN_OPENED', pg_temp.suivi_j(6, 20, 35), 'ANDROID', u, r);
    PERFORM pg_temp.suivi_evt(v, 'PLAN_UNLOCK_CLICKED', pg_temp.suivi_j(5, 9, 0), 'ANDROID', u, r);
    i := pg_temp.suivi_intention(8, u, 'LOCKED_PLAN', 'INTEGRAL_PASS_2M', 'ANDROID', r, pg_temp.suivi_j(2, 18, 55), TRUE);
    PERFORM pg_temp.suivi_achat(5, u, 'INTEGRAL_PASS_2M', 'GOOGLE', pg_temp.suivi_j(2, 19, 0), 'EUR', 2999, 2999,
                                500, 375, 2124, 'ESTIMATED', 'DIAGNOSTIC_PLAN', r, i);

    -- Sc. 9 — OMAR : civique le J20 (mois en cours), tout le tunnel, mais achat
    -- aujourd'hui (J+20) : hors tunnel de sa cohorte, present dans l'activite et
    -- le CA du jour.
    v := pg_temp.suivi_visiteur(9, NULL, 'direct', 'WEB', 'DESKTOP_WEB', pg_temp.suivi_j(20, 9, 55));
    r := pg_temp.suivi_run(9, 'CIVIQUE', 'WEB', v, NULL, pg_temp.suivi_j(20, 10, 0));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(20, 10, 30), FALSE);
    u := pg_temp.suivi_compte(8, 'omar', pg_temp.suivi_j(20, 10, 35), 'direct', 'WEB', 'AFTER_DIAGNOSTIC',
                              'CIVIQUE', v);
    PERFORM pg_temp.suivi_claim(r, u, 'SIGNUP', 'SAME_DEVICE', pg_temp.suivi_j(20, 10, 35));
    UPDATE users SET signup_diagnostic_run_id = r WHERE id = u;
    PERFORM pg_temp.suivi_evt(v, 'DIAGNOSTIC_REPORT_VIEWED', pg_temp.suivi_j(20, 10, 40), 'WEB', u, r, 'CIVIQUE');
    PERFORM pg_temp.suivi_evt(v, 'PLAN_OPENED', pg_temp.suivi_j(20, 10, 45), 'WEB', u, r);
    PERFORM pg_temp.suivi_evt(v, 'PLAN_UNLOCK_CLICKED', pg_temp.suivi_j(20, 10, 50), 'WEB', u, r);
    PERFORM pg_temp.suivi_evt(v, 'PLAN_OPENED', pg_temp.suivi_j(0, 8, 55), 'WEB', u, r);
    i := pg_temp.suivi_intention(9, u, 'LOCKED_PLAN', 'CIVIQUE_PASS_1Y', 'WEB', r, pg_temp.suivi_j(0, 8, 58), TRUE);
    PERFORM pg_temp.suivi_achat(6, u, 'CIVIQUE_PASS_1Y', 'STRIPE', pg_temp.suivi_j(0, 9, 0), 'EUR', 2999, 2999,
                                0, 70, 2929, 'ACTUAL', 'DIAGNOSTIC_PLAN', r, i);

    -- Sc. 14 — sujet vu a 23h30 UTC hier (heure d'ete : 01h30 a Paris) : compte
    -- AUJOURD'HUI, pas hier. S'arrete a l'etape 1.
    v := pg_temp.suivi_visiteur(10, NULL, 'direct', 'WEB', 'DESKTOP_WEB',
                                least(((CAST(now() AT TIME ZONE 'Europe/Paris' AS date) - 1) + time '23:25')
                                          AT TIME ZONE 'UTC', now() - interval '1 minute'));
    PERFORM pg_temp.suivi_run(10, 'QUICK_TCF', 'WEB', v, NULL,
                              least(((CAST(now() AT TIME ZONE 'Europe/Paris' AS date) - 1) + time '23:30')
                                        AT TIME ZONE 'UTC', now() - interval '1 minute'));

    -- Sc. 15 — compte INTERNE : tout le tunnel + achat, exclu par defaut,
    -- visible avec « Inclure les comptes internes ».
    v := pg_temp.suivi_visiteur(11, NULL, 'direct', 'WEB', 'DESKTOP_WEB', pg_temp.suivi_j(1, 8, 55), TRUE);
    u := pg_temp.suivi_compte(9, 'interne', pg_temp.suivi_j(1, 8, 58), 'direct', 'WEB', 'OUTSIDE_DIAGNOSTIC',
                              NULL, v, TRUE);
    r := pg_temp.suivi_run(11, 'QUICK_TCF', 'WEB', v, u, pg_temp.suivi_j(1, 9, 0));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(1, 9, 20), TRUE);
    PERFORM pg_temp.suivi_evt(v, 'DIAGNOSTIC_REPORT_VIEWED', pg_temp.suivi_j(1, 9, 25), 'WEB', u, r, 'QUICK_TCF', TRUE);
    PERFORM pg_temp.suivi_evt(v, 'PLAN_OPENED', pg_temp.suivi_j(1, 9, 30), 'WEB', u, r, NULL, TRUE);
    PERFORM pg_temp.suivi_evt(v, 'PLAN_UNLOCK_CLICKED', pg_temp.suivi_j(1, 9, 35), 'WEB', u, r, NULL, TRUE);
    i := pg_temp.suivi_intention(11, u, 'LOCKED_PLAN', 'INTEGRAL_PASS_7J', 'WEB', r, pg_temp.suivi_j(1, 9, 36), TRUE);
    PERFORM pg_temp.suivi_achat(7, u, 'INTEGRAL_PASS_7J', 'STRIPE', pg_temp.suivi_j(1, 9, 40), 'EUR', 999, 999,
                                0, 40, 959, 'ACTUAL', 'DIAGNOSTIC_PLAN', r, i);

    -- Seuil civique (controle C) — abandon a 8/40 (< 80 %) : sujet vu, JAMAIS
    -- soumis a la lecture. Source declaree « newsletter » -> groupe « autre ».
    v := pg_temp.suivi_visiteur(12, 'newsletter', 'autre', 'WEB', 'DESKTOP_WEB', pg_temp.suivi_j(2, 15, 55));
    r := pg_temp.suivi_run(12, 'CIVIQUE', 'WEB', v, NULL, pg_temp.suivi_j(2, 16, 0));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(2, 16, 10), FALSE, 8, 40);

    -- Sc. 16 — AWA : civique refait 3 fois (J5, J4, J3), connectee : 1 personne
    -- dans le tunnel (sa 1re run), 3 soumissions en brut.
    v := pg_temp.suivi_visiteur(28, NULL, 'direct', 'WEB', 'DESKTOP_WEB', pg_temp.suivi_j(6, 11, 0));
    u := pg_temp.suivi_compte(10, 'awa', pg_temp.suivi_j(6, 11, 5), 'direct', 'WEB', 'OUTSIDE_DIAGNOSTIC', NULL, v);
    FOR k IN 0..2 LOOP
        r := pg_temp.suivi_run(13 + k, 'CIVIQUE', 'WEB', v, u, pg_temp.suivi_j(5 - k, 10, 0));
        PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(5 - k, 10, 30), TRUE);
        PERFORM pg_temp.suivi_evt(v, 'DIAGNOSTIC_REPORT_VIEWED', pg_temp.suivi_j(5 - k, 10, 35), 'WEB', u, r,
                                  'CIVIQUE');
        IF k = 0 THEN
            PERFORM pg_temp.suivi_evt(v, 'PLAN_OPENED', pg_temp.suivi_j(5, 10, 40), 'WEB', u, r);
        END IF;
    END LOOP;

    -- Sc. 19 — invites civiques soumis, dont la session a ete purgee
    -- (civic_diagnostic_session_id NULL) : la run et le compteur « jamais
    -- rattaches » restent intacts.
    v := pg_temp.suivi_visiteur(13, NULL, 'direct', 'WEB', 'MOBILE_WEB', pg_temp.suivi_j(3, 10, 55));
    r := pg_temp.suivi_run(16, 'CIVIQUE', 'WEB', v, NULL, pg_temp.suivi_j(3, 11, 0));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(3, 11, 30), FALSE);
    v := pg_temp.suivi_visiteur(14, 'tiktok', 'tiktok', 'WEB', 'MOBILE_WEB', pg_temp.suivi_j(2, 10, 55));
    r := pg_temp.suivi_run(17, 'CIVIQUE', 'WEB', v, NULL, pg_temp.suivi_j(2, 11, 0));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(2, 11, 25), FALSE, 33, 40);

    -- Sc. 20 — HUGO : TCF rapide anonyme, puis inscription sur iOS avec un runId
    -- valide mais un jeton faux : pas de claim, OUTSIDE_DIAGNOSTIC, run jamais
    -- rattachee.
    v := pg_temp.suivi_visiteur(15, NULL, 'direct', 'WEB', 'MOBILE_WEB', pg_temp.suivi_j(1, 14, 55));
    r := pg_temp.suivi_run(18, 'QUICK_TCF', 'WEB', v, NULL, pg_temp.suivi_j(1, 15, 0));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(1, 15, 20), FALSE);
    v2 := pg_temp.suivi_visiteur(16, NULL, NULL, 'IOS', 'IOS', pg_temp.suivi_j(1, 15, 55));
    PERFORM pg_temp.suivi_compte(11, 'hugo', pg_temp.suivi_j(1, 16, 0), NULL, 'IOS', 'OUTSIDE_DIAGNOSTIC', NULL, v2);

    -- Controle D — runs SANS identifiant (ni compte ni identifiant de mesure :
    -- compte supprime, D106) : chacune est sa propre personne.
    r := pg_temp.suivi_run(19, 'QUICK_TCF', 'WEB', NULL, NULL, pg_temp.suivi_j(0, 6, 0));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(0, 6, 15), FALSE);
    PERFORM pg_temp.suivi_run(20, 'CIVIQUE', 'WEB', NULL, NULL, pg_temp.suivi_j(1, 7, 0));

    -- MARIAMA : civique anonyme (Facebook), inscription apres diagnostic
    -- CIVIQUE, rapport et Plan, pas de deblocage.
    v := pg_temp.suivi_visiteur(35, 'facebook', 'facebook', 'WEB', 'MOBILE_WEB', pg_temp.suivi_j(2, 18, 55));
    r := pg_temp.suivi_run(21, 'CIVIQUE', 'WEB', v, NULL, pg_temp.suivi_j(2, 19, 0));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(2, 19, 30), FALSE);
    u := pg_temp.suivi_compte(22, 'mariama', pg_temp.suivi_j(2, 19, 35), 'facebook', 'WEB', 'AFTER_DIAGNOSTIC',
                              'CIVIQUE', v);
    PERFORM pg_temp.suivi_claim(r, u, 'SIGNUP', 'SAME_DEVICE', pg_temp.suivi_j(2, 19, 35));
    UPDATE users SET signup_diagnostic_run_id = r WHERE id = u;
    PERFORM pg_temp.suivi_evt(v, 'DIAGNOSTIC_REPORT_VIEWED', pg_temp.suivi_j(2, 19, 40), 'WEB', u, r, 'CIVIQUE');
    PERFORM pg_temp.suivi_evt(v, 'PLAN_OPENED', pg_temp.suivi_j(2, 19, 45), 'WEB', u, r);

    -- Contexte d'inscription INCONNU (D98) : client ancien.
    --   ancien app « mobile » (plateforme MOBILE, source repli « direct » ->
    --   source inconnue a la lecture, N2) ;
    v := pg_temp.suivi_visiteur(17, NULL, 'direct', 'MOBILE', 'ANDROID', pg_temp.suivi_j(3, 12, 0));
    u := pg_temp.suivi_compte(12, 'ancienmobile', pg_temp.suivi_j(3, 12, 5), 'direct', 'MOBILE', NULL, NULL, v);
    PERFORM pg_temp.suivi_evt(v, 'PRICING_VIEWED', pg_temp.suivi_j(3, 12, 10), 'MOBILE', u);
    --   web sans version d'application.
    v := pg_temp.suivi_visiteur(18, NULL, 'direct', 'WEB', 'DESKTOP_WEB', pg_temp.suivi_j(0, 8, 0));
    PERFORM pg_temp.suivi_compte(13, 'ancienweb', pg_temp.suivi_j(0, 8, 5), 'direct', 'WEB', NULL, NULL, v);

    -- Sc. 13, 18 — achats HORS tunnel.
    --   INES : Stripe 9,99 depuis la page tarifs (OTHER_CTA), rembourse
    --   integralement le J1 : net de l'achat = 959 - 999 = -0,40 EUR.
    u := pg_temp.suivi_compte(14, 'ines', pg_temp.suivi_j(3, 13, 0), 'direct', 'WEB', 'OUTSIDE_DIAGNOSTIC', NULL, NULL);
    i := pg_temp.suivi_intention(14, u, 'PRICING', 'CIVIQUE_PASS_3M', 'WEB', NULL, pg_temp.suivi_j(3, 13, 55), TRUE);
    a := pg_temp.suivi_achat(8, u, 'CIVIQUE_PASS_3M', 'STRIPE', pg_temp.suivi_j(3, 14, 0), 'EUR', 999, 999,
                             0, 40, 959, 'ACTUAL', 'OTHER_CTA', NULL, i, 'REFUNDED', 'REFUNDED');
    PERFORM pg_temp.suivi_remboursement(1, a, 'STRIPE', 'ch_seed_suivi_ines:999', 999, -999, pg_temp.suivi_j(1, 10, 0));
    --   THEO : Apple 9,99 sans intention (UNKNOWN), rembourse par le store le
    --   J2 : net de l'achat = 708 - 708 = 0.
    u := pg_temp.suivi_compte(15, 'theo', pg_temp.suivi_j(4, 19, 0), NULL, 'IOS', 'OUTSIDE_DIAGNOSTIC', NULL, NULL);
    a := pg_temp.suivi_achat(9, u, 'CIVIQUE_PASS_3M', 'APPLE', pg_temp.suivi_j(4, 20, 0), 'EUR', 999, 999,
                             166, 125, 708, 'ESTIMATED', 'UNKNOWN', NULL, NULL, 'REFUNDED', 'REFUNDED');
    PERFORM pg_temp.suivi_remboursement(2, a, 'APPLE', '2000000seedsuivitheo', 999, -708, pg_temp.suivi_j(2, 9, 0));
    --   PAUL : Stripe 19,99 depuis un examen blanc (OTHER_CTA), LITIGE PERDU le
    --   J1 : delta = -1999 (HT conteste) - 1500 (frais du litige) (D111).
    u := pg_temp.suivi_compte(16, 'paul', pg_temp.suivi_j(5, 10, 0), 'facebook', 'WEB', 'OUTSIDE_DIAGNOSTIC', NULL, NULL);
    i := pg_temp.suivi_intention(16, u, 'MOCK_EXAM', 'INTEGRAL_PASS_1M', 'WEB', NULL, pg_temp.suivi_j(5, 10, 55), TRUE);
    a := pg_temp.suivi_achat(10, u, 'INTEGRAL_PASS_1M', 'STRIPE', pg_temp.suivi_j(5, 11, 0), 'EUR', 1999, 1999,
                             0, 55, 1944, 'ACTUAL', 'OTHER_CTA', NULL, i, 'REFUNDED', 'REFUNDED');
    PERFORM pg_temp.suivi_remboursement(3, a, 'STRIPE', 'dispute:du_seed_suivi_paul', 1999, -3499,
                                        pg_temp.suivi_j(1, 17, 0));
    --   LEA : Google 9,99 avec une intention EXPIREE (creee le J5, jamais
    --   consommee) : rejetee -> UNKNOWN, aucune reconstruction.
    u := pg_temp.suivi_compte(17, 'lea', pg_temp.suivi_j(5, 17, 0), NULL, 'ANDROID', 'OUTSIDE_DIAGNOSTIC', NULL, NULL);
    PERFORM pg_temp.suivi_intention(17, u, 'LOCKED_PLAN', 'INTEGRAL_PASS_7J', 'ANDROID', NULL,
                                    pg_temp.suivi_j(5, 17, 30), FALSE);
    PERFORM pg_temp.suivi_achat(11, u, 'INTEGRAL_PASS_7J', 'GOOGLE', pg_temp.suivi_j(3, 18, 0), 'EUR', 999, 999,
                                166, 125, 708, 'ESTIMATED', 'UNKNOWN', NULL, NULL);
    --   KENJI : Stripe en JPY, devise sans taux : brut en euros INCONNU, aucune
    --   decomposition (compte a part, jamais a zero). Source « youtube » ->
    --   groupe « autre ».
    u := pg_temp.suivi_compte(18, 'kenji', pg_temp.suivi_j(2, 12, 0), 'youtube', 'WEB', 'OUTSIDE_DIAGNOSTIC', NULL, NULL);
    i := pg_temp.suivi_intention(18, u, 'PRICING', 'INTEGRAL_PASS_1M', 'WEB', NULL, pg_temp.suivi_j(2, 12, 55), TRUE);
    PERFORM pg_temp.suivi_achat(12, u, 'INTEGRAL_PASS_1M', 'STRIPE', pg_temp.suivi_j(2, 13, 0), 'JPY', 3300, NULL,
                                NULL, NULL, NULL, NULL, 'OTHER_CTA', NULL, i);

    -- Periode PRECEDENTE (J13..J7) — YANIS : TCF rapide anonyme le J9,
    -- inscription, rapport, Plan ; achat le J8 depuis la page tarifs
    -- (OTHER_CTA) : dans le CA, pas dans l'etape « Achat » de sa cohorte.
    v := pg_temp.suivi_visiteur(25, NULL, 'direct', 'WEB', 'DESKTOP_WEB', pg_temp.suivi_j(9, 9, 55));
    r := pg_temp.suivi_run(22, 'QUICK_TCF', 'WEB', v, NULL, pg_temp.suivi_j(9, 10, 0));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(9, 10, 20), FALSE);
    u := pg_temp.suivi_compte(20, 'yanis', pg_temp.suivi_j(9, 10, 25), 'direct', 'WEB', 'AFTER_DIAGNOSTIC',
                              'QUICK_TCF', v);
    PERFORM pg_temp.suivi_claim(r, u, 'SIGNUP', 'SAME_DEVICE', pg_temp.suivi_j(9, 10, 25));
    UPDATE users SET signup_diagnostic_run_id = r WHERE id = u;
    PERFORM pg_temp.suivi_evt(v, 'DIAGNOSTIC_REPORT_VIEWED', pg_temp.suivi_j(9, 10, 30), 'WEB', u, r, 'QUICK_TCF');
    PERFORM pg_temp.suivi_evt(v, 'PLAN_OPENED', pg_temp.suivi_j(9, 10, 35), 'WEB', u, r);
    i := pg_temp.suivi_intention(20, u, 'PRICING', 'INTEGRAL_PASS_7J', 'WEB', NULL, pg_temp.suivi_j(8, 11, 55), TRUE);
    PERFORM pg_temp.suivi_achat(13, u, 'INTEGRAL_PASS_7J', 'STRIPE', pg_temp.suivi_j(8, 12, 0), 'EUR', 999, 999,
                                0, 40, 959, 'ESTIMATED', 'OTHER_CTA', NULL, i);

    -- Cohorte CLOSE (J30, fenetre de 14 j echue) — SOFIA : Instagram « ig »,
    -- tout le tunnel, achat Stripe 19,99 le J27 ; et un invite qui s'arrete au
    -- « soumis ». A lire avec une periode personnalisee sur le J30.
    v := pg_temp.suivi_visiteur(26, 'ig', 'autre', 'WEB', 'MOBILE_WEB', pg_temp.suivi_j(30, 9, 55));
    r := pg_temp.suivi_run(23, 'QUICK_TCF', 'WEB', v, NULL, pg_temp.suivi_j(30, 10, 0));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(30, 10, 20), FALSE);
    u := pg_temp.suivi_compte(19, 'sofia', pg_temp.suivi_j(30, 10, 25), 'autre', 'WEB', 'AFTER_DIAGNOSTIC',
                              'QUICK_TCF', v);
    PERFORM pg_temp.suivi_claim(r, u, 'SIGNUP', 'SAME_DEVICE', pg_temp.suivi_j(30, 10, 25));
    UPDATE users SET signup_diagnostic_run_id = r WHERE id = u;
    PERFORM pg_temp.suivi_evt(v, 'DIAGNOSTIC_REPORT_VIEWED', pg_temp.suivi_j(30, 10, 30), 'WEB', u, r, 'QUICK_TCF');
    PERFORM pg_temp.suivi_evt(v, 'PLAN_OPENED', pg_temp.suivi_j(30, 10, 35), 'WEB', u, r);
    PERFORM pg_temp.suivi_evt(v, 'PLAN_UNLOCK_CLICKED', pg_temp.suivi_j(28, 20, 0), 'WEB', u, r);
    i := pg_temp.suivi_intention(19, u, 'LOCKED_PLAN', 'INTEGRAL_PASS_1M', 'WEB', r, pg_temp.suivi_j(27, 8, 55), TRUE);
    PERFORM pg_temp.suivi_achat(14, u, 'INTEGRAL_PASS_1M', 'STRIPE', pg_temp.suivi_j(27, 9, 0), 'EUR', 1999, 1999,
                                0, 55, 1944, 'ACTUAL', 'DIAGNOSTIC_PLAN', r, i);
    v := pg_temp.suivi_visiteur(34, NULL, 'direct', 'WEB', 'DESKTOP_WEB', pg_temp.suivi_j(30, 14, 55));
    r := pg_temp.suivi_run(24, 'QUICK_TCF', 'WEB', v, NULL, pg_temp.suivi_j(30, 15, 0));
    PERFORM pg_temp.suivi_soumis(r, pg_temp.suivi_j(30, 15, 20), FALSE);

    -- Visiteurs sans diagnostic, pour les blocs Visiteurs et Sources (periode
    -- et periode precedente) : instagram « insta », tiktok, facebook « meta »,
    -- direct, et l'app native sans provenance.
    PERFORM pg_temp.suivi_visiteur(19, 'insta', 'autre', 'WEB', 'MOBILE_WEB', pg_temp.suivi_j(0, 7, 40));
    PERFORM pg_temp.suivi_visiteur(20, 'tiktok', 'tiktok', 'WEB', 'MOBILE_WEB', pg_temp.suivi_j(5, 21, 0));
    PERFORM pg_temp.suivi_visiteur(21, 'meta', 'autre', 'WEB', 'MOBILE_WEB', pg_temp.suivi_j(4, 12, 30));
    PERFORM pg_temp.suivi_visiteur(22, NULL, 'direct', 'WEB', 'DESKTOP_WEB', pg_temp.suivi_j(0, 6, 30));
    PERFORM pg_temp.suivi_visiteur(23, NULL, NULL, 'IOS', 'IOS', pg_temp.suivi_j(1, 20, 0));
    PERFORM pg_temp.suivi_visiteur(24, NULL, NULL, 'ANDROID', 'ANDROID', pg_temp.suivi_j(0, 7, 50));
    PERFORM pg_temp.suivi_visiteur(29, NULL, 'direct', 'WEB', 'DESKTOP_WEB', pg_temp.suivi_j(10, 9, 0));
    PERFORM pg_temp.suivi_visiteur(30, 'ig', 'autre', 'WEB', 'MOBILE_WEB', pg_temp.suivi_j(9, 20, 0));
    PERFORM pg_temp.suivi_visiteur(31, 'tt', 'autre', 'WEB', 'MOBILE_WEB', pg_temp.suivi_j(12, 18, 0));
    PERFORM pg_temp.suivi_visiteur(32, NULL, 'direct', 'WEB', 'DESKTOP_WEB', pg_temp.suivi_j(1, 22, 0));
    PERFORM pg_temp.suivi_visiteur(33, 'fb', 'autre', 'WEB', 'MOBILE_WEB', pg_temp.suivi_j(20, 12, 0));
END
$$;

-- Derniere visite de chaque visiteur seme = son dernier evenement.
UPDATE analytics_visitor v
   SET last_seen_at = e.last_at
  FROM (SELECT anonymous_id, max(occurred_at) AS last_at FROM analytics_event GROUP BY anonymous_id) e
 WHERE e.anonymous_id = v.anonymous_id
   AND CAST(v.anonymous_id AS text) LIKE '5e1f5e1f-%';
