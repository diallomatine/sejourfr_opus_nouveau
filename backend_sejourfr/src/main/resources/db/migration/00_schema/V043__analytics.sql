-- ============================================================================
-- V043 — ANALYTICS : le socle d'ECRITURE du parcours acquisition -> diagnostic
--        -> inscription -> Premium -> paiement.
-- ----------------------------------------------------------------------------
-- CE QU'ON AJOUTE, ET SEULEMENT CA : ce qui n'existe QUE dans le navigateur.
--
-- La doctrine du depot (V036, en toutes lettres) est qu'on ne cree JAMAIS une
-- seconde verite. Tout ce qui se lit sur les vraies tables continue de s'y
-- lire :
--   * l'inscription        -> users.created_at
--   * le diagnostic        -> diagnostic_sessions.started_at / .completed_at
--   * le paiement          -> user_subscriptions
--   * l'ecran Premium vu   -> user_funnel_events (V036, conservee, continuee)
-- Il n'existe donc AUCUN evenement `USER_REGISTERED`, `PAYMENT_SUCCEEDED`,
-- `SUBSCRIPTION_CREATED` ni `DIAGNOSTIC_COMPLETED` ici. Le brief les liste ; la
-- doctrine prime : deux compteurs pour un meme fait sont condamnes a diverger,
-- et c'est celui qu'on regarde le moins qui ment.
--
-- Ce qui manquait vraiment : la VISITE avant le compte. Un visiteur TikTok
-- ouvre /reussir, commence le diagnostic, fait son EE, son EO, voit son
-- rapport... et seulement ENSUITE cree un compte. Toute cette moitie de
-- parcours n'a aucun `user_id` a qui s'accrocher. D'ou `analytics_visitor`,
-- `analytics_event` et `analytics_identity`.
--
-- POURQUOI L'ATTRIBUTION VIT SUR LE VISITEUR ET PAS SUR L'EVENEMENT.
-- Le brief propose (§6) de porter source / medium / campaign / content / term
-- sur CHAQUE ligne d'evenement. On ne le fait pas, pour trois raisons :
--   1. l'attribution est une propriete de la PERSONNE, pas du geste : « d'ou
--      vient ce visiteur » a une reponse et une seule, elle ne change pas
--      entre son clic de CTA et l'affichage de son rapport ;
--   2. la repeter sur chaque evenement, c'est dupliquer sept colonnes des
--      dizaines de fois par visiteur — et surtout, c'est ouvrir la porte a ce
--      qu'un meme visiteur porte deux first touch differents selon la ligne
--      qu'on regarde. Le first touch cesserait d'etre premier ;
--   3. « combien de visiteurs uniques venus de TikTok » devient un COUNT sur
--      une table d'une ligne par visiteur, au lieu d'un COUNT(DISTINCT ...)
--      sur le journal complet.
-- Le journal, lui, garde ce qui est propre au geste : quand, ou, quoi, avec
-- quelles proprietes.
--
-- AUCUNE DONNEE N'EST MIGREE, ET C'EST VOLONTAIRE (brief §72). Le passe n'a
-- jamais porte d'`anonymous_id`, d'UTM ni de referrer : les fabriquer
-- reviendrait a inventer d'ou viennent des gens qu'on n'a pas mesures. Les
-- colonnes ajoutees a `user_subscriptions` restent NULL sur l'existant — NULL
-- veut dire « montant inconnu », jamais « zero euro ». Aucun recalcul
-- retroactif, jamais : `plans.price` est modifiable en console, le lire
-- aujourd'hui pour dater un achat d'hier falsifierait l'historique.
--
-- VIE PRIVEE. Aucune IP n'est persistee nulle part ici : elle est lue en
-- memoire, convertie en code pays, puis jetee (cf. util/GeoIpCountryResolver).
-- Aucun user-agent non plus : seule sa conclusion (`device_type`) est gardee.
-- `analytics_visitor.anonymous_id` est un identifiant first-party, jamais
-- partage, jamais recoupe avec un tiers, retention 13 mois — c'est ce qui le
-- fait tenir sous l'exemption CNIL de mesure d'audience.
-- ============================================================================


-- ---------------------------------------------------------------------------
-- 1. analytics_visitor — UN visiteur, pas un evenement.
--
-- C'est LA source des « visiteurs uniques » et le porteur de l'attribution.
--
-- FIRST TOUCH : ecrit une seule fois, a la premiere requete du visiteur, et
-- plus JAMAIS reecrit (l'ecriture se fait en ON CONFLICT DO NOTHING sur ces
-- colonnes-la). Sans cette garantie, un visiteur revenu par Google se
-- retrouverait attribue a Google alors que TikTok l'avait amene : on perdrait
-- exactement la reponse qu'on cherche.
--
-- LAST TOUCH : lui est reecrit, mais SEULEMENT quand une source EXPLICITE
-- arrive (UTM ou en-tete de provenance). Le reecrire a chaque page vue le
-- ferait retomber sur « direct » des la deuxieme page, et « quelle source a
-- precede l'achat » repondrait « direct » pour tout le monde.
-- ---------------------------------------------------------------------------
CREATE TABLE analytics_visitor
(
    anonymous_id     uuid        NOT NULL PRIMARY KEY,
    first_seen_at    timestamptz NOT NULL,
    last_seen_at     timestamptz NOT NULL,

    -- First touch (fige)
    ft_source        varchar(40)  NOT NULL,
    ft_medium        varchar(40),
    ft_campaign      varchar(120),
    ft_content       varchar(120),
    ft_term          varchar(120),
    ft_landing_path  varchar(160),
    -- HOTE seul (« tiktok.com »), jamais l'URL complete : une URL de referrer
    -- peut porter un identifiant, un terme de recherche, un jeton. L'hote
    -- suffit a repondre « d'ou vient ce visiteur ».
    ft_referrer_host varchar(120),

    -- Last touch (reecrit sur source explicite)
    lt_source        varchar(40)  NOT NULL,
    lt_medium        varchar(40),
    lt_campaign      varchar(120),
    lt_content       varchar(120),
    lt_term          varchar(120),
    lt_seen_at       timestamptz  NOT NULL,

    -- Deduit serveur, jamais recu du client (il serait falsifiable).
    -- NULL = inconnu (base geo absente, IP privee, IP non determinable) —
    -- jamais « autre », jamais un pays invente.
    -- varchar(2) et non char(2) : `bpchar` complete a la longueur fixe avec des
    -- espaces, et surtout Hibernate le refuse a la validation du mapping
    -- (`ddl-auto: validate`). La contrainte de longueur est identique.
    country_code     varchar(2),
    device_type      varchar(16)  NOT NULL,
    platform         varchar(16)  NOT NULL
);

COMMENT ON TABLE analytics_visitor IS
    'Un visiteur anonyme (first-party, retention 13 mois). Porte l''attribution first touch (figee) et last touch (reecrite sur source explicite). Aucune IP, aucun user-agent : seules leurs conclusions (pays, type d''appareil).';
COMMENT ON COLUMN analytics_visitor.ft_source IS
    'Provenance normalisee par util/TrafficSource, la MEME allowlist que users.signup_source et page_views.source. Une seule dimension pour un seul fait.';
COMMENT ON COLUMN analytics_visitor.ft_referrer_host IS
    'Hote du referrer uniquement (« tiktok.com »), jamais l''URL complete : elle peut porter un identifiant ou un terme de recherche.';
COMMENT ON COLUMN analytics_visitor.country_code IS
    'ISO 3166-1 alpha-2, resolu serveur par geo-IP. L''IP n''est JAMAIS persistee. NULL = inconnu, jamais « autre ».';
COMMENT ON COLUMN analytics_visitor.device_type IS
    'AnalyticsDeviceType : MOBILE_WEB / DESKTOP_WEB / TABLET_WEB / IOS / ANDROID / UNKNOWN. Deduit du user-agent, qui n''est pas conserve.';

-- « Combien de visiteurs sur la periode » et la serie temporelle.
CREATE INDEX idx_analytics_visitor_first_seen ON analytics_visitor (first_seen_at DESC);
-- « Combien de visiteurs venus de TikTok sur la periode » : c'est LA lecture
-- principale du tableau d'acquisition, et la seule qui justifie un index
-- compose plutot qu'un filtre sur l'index de date.
CREATE INDEX idx_analytics_visitor_ft_source ON analytics_visitor (ft_source, first_seen_at DESC);
-- Purge de retention (13 mois) : elle balaie par derniere activite, pas par
-- premiere vue — un visiteur actif ne doit pas etre purge parce qu'il est
-- ancien.
CREATE INDEX idx_analytics_visitor_last_seen ON analytics_visitor (last_seen_at DESC);


-- ---------------------------------------------------------------------------
-- 2. analytics_event — le journal comportemental.
--
-- `properties` est un jsonb, mais ses CLES sont bornees cote serveur, par
-- evenement (enums/AnalyticsEvent). L'endpoint d'ecriture est PUBLIC : sans
-- cette allowlist fermee, n'importe qui creerait des dimensions a volonte, et
-- rien n'empecherait un front d'y deposer un e-mail, un jeton ou un bout de
-- production. Le brief §6 propose un jsonb libre ; on l'ecarte pour cette
-- raison, et le §95 (« ne jamais stocker de donnee sensible ») devient alors
-- vrai PAR CONSTRUCTION plutot que par vigilance.
--
-- `user_id` est renseigne A L'ECRITURE quand le visiteur est deja connu. Il
-- n'est jamais backfille en masse a l'inscription (brief §9) : rattacher le
-- passe est le travail d'`analytics_identity`, une jointure, pas un UPDATE de
-- millions de lignes.
-- ---------------------------------------------------------------------------
CREATE TABLE analytics_event
(
    id           uuid         NOT NULL PRIMARY KEY,
    event        varchar(48)  NOT NULL,
    occurred_at  timestamptz  NOT NULL,
    anonymous_id uuid         NOT NULL REFERENCES analytics_visitor (anonymous_id) ON DELETE CASCADE,
    session_id   uuid         NOT NULL,
    -- ON DELETE SET NULL : la suppression de compte est une ANONYMISATION, la
    -- ligne `users` survit, donc cette cascade ne se declenche pas d'elle-meme
    -- — AccountDeletionService detache explicitement, comme il purge deja
    -- user_funnel_events. La clause reste la pour une vraie suppression.
    user_id      uuid         REFERENCES users (id) ON DELETE SET NULL,
    path         varchar(160),
    properties   jsonb        NOT NULL DEFAULT '{}'::jsonb,
    -- Idempotence (brief §71) : un rejeu porte la meme cle et n'ecrit rien.
    -- NULLable parce que la plupart des evenements de navigation n'en ont pas
    -- besoin, et que Postgres tient deux NULL pour distincts — l'unicite ne
    -- gene donc jamais ceux qui n'en posent pas.
    dedup_key    varchar(120) UNIQUE
);

COMMENT ON TABLE analytics_event IS
    'Journal des gestes qui n''existent QUE dans le navigateur. Aucun evenement d''inscription, de paiement ni de diagnostic termine : ceux-la se lisent sur les vraies tables (doctrine V036).';
COMMENT ON COLUMN analytics_event.properties IS
    'Proprietes ALLOWLISTEES par evenement (enums/AnalyticsEvent). Jamais de texte de production, de transcription, d''e-mail, de jeton ni de coordonnees : le validateur refuse toute cle hors allowlist.';
COMMENT ON COLUMN analytics_event.user_id IS
    'Pose a l''ecriture si le visiteur est deja identifie. Jamais backfille : le rattachement du passe passe par analytics_identity.';
COMMENT ON COLUMN analytics_event.dedup_key IS
    'Cle d''idempotence facultative. Un rejeu (double-clic, retry reseau) n''ecrit rien.';

-- « Les DIAGNOSTIC_CTA_CLICKED des 30 derniers jours » : la lecture de base.
CREATE INDEX idx_analytics_event_event_date ON analytics_event (event, occurred_at DESC);
-- Bornage de periode quand on balaie tous les evenements (funnel, series).
CREATE INDEX idx_analytics_event_date ON analytics_event (occurred_at DESC);
-- Reconstitution d'un parcours visiteur (top journeys, abandons).
CREATE INDEX idx_analytics_event_visitor ON analytics_event (anonymous_id, occurred_at DESC);
-- Partiel : la grande majorite des lignes sont anonymes, indexer leurs NULL
-- ne servirait aucune requete et grossirait l'index pour rien.
CREATE INDEX idx_analytics_event_user ON analytics_event (user_id, occurred_at DESC)
    WHERE user_id IS NOT NULL;


-- ---------------------------------------------------------------------------
-- 3. analytics_identity — fusion anonyme -> compte (brief §9).
--
-- Pourquoi une TABLE et pas une colonne `user_id` sur analytics_visitor : un
-- appareil partage (un poste de mediatheque, un telephone familial) porte
-- legitimement DEUX comptes derriere un seul anonymous_id. Une colonne
-- obligerait a en ecraser un ; la table les garde tous les deux, et c'est la
-- lecture qui decide quoi en faire.
--
-- Ecrite a l'inscription ET a la connexion (locale et sociale), en
-- ON CONFLICT DO NOTHING : rejouable a l'infini, ne leve jamais. Une fusion
-- ratee ne doit JAMAIS empecher quelqu'un de se connecter.
-- ---------------------------------------------------------------------------
CREATE TABLE analytics_identity
(
    anonymous_id uuid        NOT NULL REFERENCES analytics_visitor (anonymous_id) ON DELETE CASCADE,
    user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    linked_at    timestamptz NOT NULL,
    PRIMARY KEY (anonymous_id, user_id)
);

COMMENT ON TABLE analytics_identity IS
    'Lien anonyme -> compte, pose a l''inscription et a la connexion. Plusieurs comptes peuvent partager un anonymous_id (appareil partage) : c''est pour ca que ce n''est pas une colonne.';

-- Sens de lecture inverse : « quels parcours anonymes menent a ce compte ».
CREATE INDEX idx_analytics_identity_user ON analytics_identity (user_id);


-- ---------------------------------------------------------------------------
-- 4. analytics_annotation — les reperes poses sur la courbe (brief §52).
--
-- « Le 12, on a publie trois videos » explique un pic mieux que n'importe
-- quelle statistique. C'est de la donnee EDITORIALE, saisie a la main : elle
-- n'a ni source, ni visiteur, ni idempotence a tenir.
-- ---------------------------------------------------------------------------
CREATE TABLE analytics_annotation
(
    id          uuid         NOT NULL PRIMARY KEY,
    occurred_on date         NOT NULL,
    title       varchar(120) NOT NULL,
    description text,
    category    varchar(24)  NOT NULL,
    -- SET NULL : l'annotation survit au depart de son auteur, c'est un repere
    -- produit, pas une donnee personnelle.
    created_by  uuid         REFERENCES users (id) ON DELETE SET NULL,
    created_at  timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT chk_analytics_annotation_category CHECK (category IN ('PRODUIT', 'MARKETING'))
);

COMMENT ON TABLE analytics_annotation IS
    'Reperes produit / marketing affiches sur la courbe temporelle. Saisis a la main en console admin.';

CREATE INDEX idx_analytics_annotation_date ON analytics_annotation (occurred_on);


-- ---------------------------------------------------------------------------
-- 5. user_subscriptions — LE MONTANT REELLEMENT ENCAISSE, enfin.
--
-- Jusqu'ici aucun montant n'etait persiste : le revenu ne pouvait se calculer
-- qu'en relisant `plans.price` AUJOURD'HUI pour des achats d'HIER. Or ce prix
-- est modifiable depuis la console admin (AdminPlanService) : une baisse de
-- tarif reecrivait retroactivement tout le chiffre d'affaires du passe. On
-- FIGE donc le montant a l'ecriture, avec sa devise.
--
-- `amount_eur_cents` + `fx_rate_to_eur` : le total du tableau de bord est en
-- euros, mais un achat en dollars sur l'App Store n'est pas un achat en euros.
-- Le taux est fige AU MOMENT DE L'ENCAISSEMENT, jamais relu : convertir
-- aujourd'hui un dollar de l'an dernier donnerait un chiffre d'affaires qui
-- bouge tout seul.
--
-- Devise inconnue (hors table de taux) => `amount_eur_cents` NULL. Un revenu
-- inconnu vaut NULL, jamais 0 : zero euro est une affirmation, l'absence de
-- taux est une ignorance.
--
-- LA CONTRAINTE NE VA QUE DANS UN SENS : montant et devise vont ensemble ou
-- pas du tout. On n'exige PAS la reciproque (« un montant implique un montant
-- en euros ») — ce serait faux des qu'une devise n'a pas de taux, ce qui est
-- precisement le cas qu'on vient de decrire.
-- ---------------------------------------------------------------------------
ALTER TABLE user_subscriptions
    ADD COLUMN amount_cents     integer,
    -- varchar(3) et non char(3) : meme raison que country_code ci-dessus.
    ADD COLUMN currency         varchar(3),
    ADD COLUMN amount_eur_cents integer,
    ADD COLUMN fx_rate_to_eur   numeric(12, 6);

ALTER TABLE user_subscriptions
    ADD CONSTRAINT chk_user_subscriptions_amount_currency CHECK (
        (amount_cents IS NULL) = (currency IS NULL)
        );

COMMENT ON COLUMN user_subscriptions.amount_cents IS
    'Montant reellement encaisse, en plus petite unite de la devise, FIGE a l''ecriture. NULL = inconnu (ligne anterieure a la mesure), jamais zero. Ne jamais recalculer depuis plans.price : ce prix est modifiable en console.';
COMMENT ON COLUMN user_subscriptions.currency IS
    'Devise ISO 4217 de amount_cents. Presente si et seulement si amount_cents l''est.';
COMMENT ON COLUMN user_subscriptions.amount_eur_cents IS
    'Le meme montant en centimes d''euro, converti au taux du jour de l''encaissement. NULL si la devise n''a pas de taux configure : on n''invente pas une conversion.';
COMMENT ON COLUMN user_subscriptions.fx_rate_to_eur IS
    'Taux applique a l''encaissement, fige. 1 pour un achat en euros. Jamais relu ni rafraichi.';
