package com.sejourfr.app.repository;

import com.sejourfr.app.entity.AnalyticsVisitor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

/**
 * Lecture agregee de l'ecran Analytics. <b>Rien ne s'ecrit ici.</b>
 *
 * <p><b>Tout est agrege en SQL, jamais en Java</b> (brief §66, §99, §109) : le
 * cout d'un appel est independant du nombre de visiteurs, de sources, de pays et
 * de campagnes. Charger les evenements pour les grouper en memoire tiendrait le
 * temps d'une demonstration et s'effondrerait au premier millier de visiteurs —
 * c'est exactement ce que le brief interdit.
 *
 * <p><b>Le nombre de requetes est CONSTANT</b>, et c'est verrouille par un test
 * qui compte les statements prepares ({@code AdminAnalyticsCoutIT}, patron
 * {@code SkillMasteryResolverIT}) : sans egalite stricte, un N+1 se glisse sans
 * qu'aucun test ne rougisse.
 *
 * <p><b>Une seule requete par population et par periode</b>, qui rend d'un coup
 * <i>toutes</i> les ventilations sous forme de lignes {@code (dim, cle, cle2)} —
 * patron {@code AudienceFunnelRepository.dailyCounts}. Une requete par dimension
 * aurait multiplie par cinq le nombre d'allers-retours pour relire exactement le
 * meme sous-ensemble de lignes.
 *
 * <p><b>Deux populations, jamais melangees.</b> Les visiteurs et leurs gestes
 * vivent dans {@code analytics_visitor} / {@code analytics_event} ; les
 * inscriptions, les paiements et le revenu se lisent sur les <i>vraies</i> tables
 * ({@code users}, {@code user_subscriptions}, {@code user_funnel_events}). C'est
 * la doctrine V036 : on ne cree jamais une seconde verite.
 *
 * <p><b>Les comptes de test sont exclus EN SQL</b> (brief §85), jamais soustraits
 * apres coup : une soustraction a la lecture laisse tous les pourcentages faux.
 */
public interface AnalyticsReadRepository extends Repository<AnalyticsVisitor, UUID> {

    // ------------------------------------------------------------------------
    // Projections
    // ------------------------------------------------------------------------

    /** Une cellule de ventilation cote visiteur : un compteur d'acteurs distincts. */
    interface VisitorCell {
        String getDim();
        String getDimKey();
        String getDimKey2();
        String getMetric();
        long getN();
    }

    /** Une cellule de ventilation cote compte : cohorte d'inscription. */
    interface UserCell {
        String getDim();
        String getDimKey();
        String getDimKey2();
        long getSig();
        long getPay();
        long getCk();
        long getRev();
    }

    /** Une etape d'un format de diagnostic. */
    interface DiagStepCell {
        String getDiagType();
        String getStep();
        long getN();
    }

    /** Une ligne de la table des CTA Premium. */
    interface CtaCell {
        String getLoc();
        long getPrem();
        long getCk();
        long getPay();
        long getRev();
    }

    /** Un parcours reduit a ses jalons. */
    interface PathCell {
        String getSource();
        String getChain();
        long getN();
    }

    /** Un contexte d'inscription et le nombre de visiteurs qui l'ont declenche. */
    interface TriggerCell {
        String getContexte();
        long getN();
    }

    // ------------------------------------------------------------------------
    // 1. Visiteurs et gestes, toutes ventilations d'un coup
    // ------------------------------------------------------------------------

    /**
     * Acteurs <b>distincts</b> par (dimension, metrique).
     *
     * <p>🛑 {@code count(DISTINCT anonymous_id)} partout, jamais {@code count(*)} :
     * la metrique demandee est « combien de personnes », pas « combien de vues »
     * (brief §27, §32, §109). Un visiteur qui recharge dix fois la landing reste
     * un visiteur, et un candidat qui clique trois fois « Débloquer mon plan »
     * reste un cliqueur — le volume brut de clics ne sort que dans la table CTA,
     * ou il decrit autre chose.
     *
     * <p>La pseudo-metrique {@code VISITEUR} compte les visiteurs ayant eu au
     * moins un geste dans la fenetre. On ne se sert pas de
     * {@code first_seen_at} : ce serait « nouveaux visiteurs », pas « visiteurs
     * de la periode », et les deux ne se ressemblent qu'au premier jour.
     *
     * <p><b>Additivite.</b> Un visiteur appartient a exactement une source, un
     * pays, un appareil et au plus une campagne : la somme des lignes d'un
     * tableau egale donc son pied. La ventilation {@code BUCKET} fait exception
     * et c'est normal : un visiteur actif deux jours compte dans deux barres —
     * aucune courbe d'uniques n'est additive, et l'aplatir donnerait « nouveaux
     * visiteurs par jour », ce que la courbe ne dit pas.
     */
    @Query(value = """
            WITH vis AS (
                SELECT av.anonymous_id, av.ft_source, av.country_code, av.device_type,
                       av.platform, av.ft_campaign, av.ft_medium, av.ft_content
                FROM analytics_visitor av
                WHERE (CAST(:source AS text) IS NULL OR av.ft_source = CAST(:source AS text))
                  AND (CAST(:country AS text) IS NULL
                       OR COALESCE(av.country_code, 'UNKNOWN') = CAST(:country AS text))
                  AND (CAST(:device AS text) IS NULL OR av.device_type = CAST(:device AS text))
                  AND (CAST(:platform AS text) IS NULL OR av.platform = CAST(:platform AS text))
            ),
            ev AS (
                SELECT e.event AS event, e.occurred_at AS occurred_at,
                       v.anonymous_id AS anonymous_id, v.ft_source AS ft_source,
                       v.country_code AS country_code, v.device_type AS device_type,
                       v.platform AS platform, v.ft_campaign AS ft_campaign,
                       v.ft_medium AS ft_medium, v.ft_content AS ft_content
                FROM analytics_event e
                JOIN vis v ON v.anonymous_id = e.anonymous_id
                WHERE e.occurred_at >= :from AND e.occurred_at < :to
            ),
            pts AS (
                SELECT event AS metric, anonymous_id, occurred_at, ft_source, country_code,
                       device_type, platform, ft_campaign, ft_medium, ft_content
                FROM ev
                WHERE event IN ('DIAGNOSTIC_CTA_CLICKED', 'CIVIQUE_CTA_CLICKED',
                                'DIAGNOSTIC_STARTED', 'DIAGNOSTIC_EE_STARTED',
                                'DIAGNOSTIC_EE_COMPLETED', 'DIAGNOSTIC_EO_STARTED',
                                'DIAGNOSTIC_EO_COMPLETED', 'DIAGNOSTIC_CO_COMPLETED',
                                'DIAGNOSTIC_CE_COMPLETED', 'DIAGNOSTIC_ACCOUNT_REQUIRED',
                                'DIAGNOSTIC_REPORT_VIEWED', 'PREMIUM_CTA_CLICKED')
                UNION ALL
                SELECT 'VISITEUR', anonymous_id, occurred_at, ft_source, country_code,
                       device_type, platform, ft_campaign, ft_medium, ft_content
                FROM ev
            )
            SELECT 'TOTAL' AS dim, 'ALL' AS dim_key, '' AS dim_key2,
                   metric AS metric, count(DISTINCT anonymous_id) AS n
            FROM pts GROUP BY 4
            UNION ALL
            SELECT 'SOURCE', ft_source, '', metric, count(DISTINCT anonymous_id)
            FROM pts GROUP BY 2, 4
            UNION ALL
            SELECT 'COUNTRY', COALESCE(country_code, 'UNKNOWN'), '', metric,
                   count(DISTINCT anonymous_id)
            FROM pts GROUP BY 2, 4
            UNION ALL
            SELECT 'DEVICE', device_type, platform, metric, count(DISTINCT anonymous_id)
            FROM pts GROUP BY 2, 3, 4
            UNION ALL
            SELECT 'CAMPAIGN',
                   concat_ws(chr(31), ft_source, ft_campaign,
                             COALESCE(ft_medium, ''), COALESCE(ft_content, '')),
                   '', metric, count(DISTINCT anonymous_id)
            FROM pts WHERE ft_campaign IS NOT NULL GROUP BY 2, 4
            UNION ALL
            SELECT 'BUCKET',
                   to_char(date_trunc(CAST(:grain AS text),
                                      occurred_at AT TIME ZONE 'Europe/Paris'),
                           'YYYY-MM-DD HH24:MI:SS'),
                   '', metric, count(DISTINCT anonymous_id)
            FROM pts GROUP BY 2, 4
            """, nativeQuery = true)
    List<VisitorCell> visitorCells(@Param("from") Instant from,
                                   @Param("to") Instant to,
                                   @Param("grain") String grain,
                                   @Param("source") String source,
                                   @Param("country") String country,
                                   @Param("device") String device,
                                   @Param("platform") String platform);

    // ------------------------------------------------------------------------
    // 2. Comptes : cohorte d'inscription, paiements, revenu
    // ------------------------------------------------------------------------

    /**
     * Inscriptions, checkouts, payants et revenu <b>sur la cohorte
     * d'inscription</b> — les comptes crees dans la fenetre, chaque etape
     * mesuree sur ces memes comptes quelle que soit sa date (patron
     * {@code AudienceFunnelRepository}). C'est ce qui rend « 4 payants sur
     * 50 inscrits TikTok » vrai : compter les paiements du mois au numerateur et
     * les inscrits du mois au denominateur melange deux populations et donne un
     * taux qui ne decrit personne.
     *
     * <p><b>Un payant est un COMPTE, jamais une souscription</b> :
     * {@code count(*) FILTER (WHERE paye)} sur des comptes distincts, donc un
     * renouvellement n'ajoute jamais un nouvel abonne (brief §33). Un
     * remboursement, lui, reste compte : il a bien ete un paiement — seul
     * {@code PENDING} est exclu, parce qu'il n'a jamais encaisse.
     *
     * <p><b>Le revenu est la somme des montants REELLEMENT encaisses</b>
     * ({@code amount_eur_cents}, fige a l'ecriture). Une ligne sans montant
     * n'apporte rien a la somme et n'est pas comptee zero : un montant inconnu
     * est une ignorance, pas une vente a zero euro. On ne derive jamais depuis
     * {@code plans.price}, modifiable en console : le lire aujourd'hui pour
     * dater un achat d'hier reecrirait le chiffre d'affaires passe.
     *
     * <p><b>Pays, appareil et campagne d'un compte passent par
     * {@code analytics_identity}</b> — les seules dimensions que {@code users} ne
     * porte pas. Le {@code LEFT JOIN LATERAL ... LIMIT 1} retient <b>un seul</b>
     * visiteur par compte (le premier relie) : sans lui, un candidat ayant
     * ouvert le site sur deux appareils compterait dans deux pays et la somme
     * des lignes depasserait le pied de table.
     */
    @Query(value = """
            WITH cohorte AS (
                SELECT u.id AS id,
                       u.created_at AS created_at,
                       COALESCE(u.signup_source, 'inconnu') AS src,
                       COALESCE(u.signup_platform, 'UNKNOWN') AS plat,
                       av.country_code AS country_code,
                       av.device_type AS device_type,
                       av.vplatform AS vplatform,
                       av.ft_source AS vsource,
                       av.ft_campaign AS ft_campaign,
                       av.ft_medium AS ft_medium,
                       av.ft_content AS ft_content
                FROM users u
                LEFT JOIN LATERAL (
                    SELECT v.country_code AS country_code, v.device_type AS device_type,
                           v.platform AS vplatform, v.ft_source AS ft_source,
                           v.ft_campaign AS ft_campaign, v.ft_medium AS ft_medium,
                           v.ft_content AS ft_content
                    FROM analytics_identity i
                    JOIN analytics_visitor v ON v.anonymous_id = i.anonymous_id
                    WHERE i.user_id = u.id
                    ORDER BY i.linked_at, v.first_seen_at
                    LIMIT 1
                ) av ON true
                WHERE u.deleted_at IS NULL
                  AND u.created_at >= :from AND u.created_at < :to
                  AND lower(u.email) NOT IN (:excluded)
                  AND (CAST(:source AS text) IS NULL
                       OR COALESCE(u.signup_source, 'inconnu') = CAST(:source AS text))
                  AND (CAST(:platform AS text) IS NULL
                       OR COALESCE(u.signup_platform, 'UNKNOWN') = CAST(:platform AS text))
                  AND (CAST(:country AS text) IS NULL
                       OR COALESCE(av.country_code, 'UNKNOWN') = CAST(:country AS text))
                  AND (CAST(:device AS text) IS NULL
                       OR COALESCE(av.device_type, 'UNKNOWN') = CAST(:device AS text))
            ),
            argent AS (
                SELECT s.user_id AS uid, COALESCE(sum(s.amount_eur_cents), 0)::bigint AS rev
                FROM user_subscriptions s
                JOIN cohorte c ON c.id = s.user_id
                WHERE s.status <> 'PENDING'
                GROUP BY s.user_id
            ),
            checkouts AS (
                SELECT DISTINCT f.user_id AS uid
                FROM user_funnel_events f
                JOIN cohorte c ON c.id = f.user_id
                WHERE f.event = 'CHECKOUT_STARTED'
            ),
            base AS (
                SELECT c.*, (a.uid IS NOT NULL) AS paye,
                       COALESCE(a.rev, 0) AS rev, (k.uid IS NOT NULL) AS checkout
                FROM cohorte c
                LEFT JOIN argent a ON a.uid = c.id
                LEFT JOIN checkouts k ON k.uid = c.id
            )
            SELECT 'TOTAL' AS dim, 'ALL' AS dim_key, '' AS dim_key2,
                   count(*) AS sig,
                   count(*) FILTER (WHERE paye) AS pay,
                   count(*) FILTER (WHERE checkout) AS ck,
                   COALESCE(sum(rev), 0)::bigint AS rev
            FROM base
            UNION ALL
            SELECT 'SOURCE', src, '', count(*), count(*) FILTER (WHERE paye),
                   count(*) FILTER (WHERE checkout), COALESCE(sum(rev), 0)::bigint
            FROM base GROUP BY 2
            UNION ALL
            SELECT 'COUNTRY', COALESCE(country_code, 'UNKNOWN'), '', count(*),
                   count(*) FILTER (WHERE paye), count(*) FILTER (WHERE checkout),
                   COALESCE(sum(rev), 0)::bigint
            FROM base GROUP BY 2
            UNION ALL
            SELECT 'DEVICE', COALESCE(device_type, 'UNKNOWN'), COALESCE(vplatform, plat),
                   count(*), count(*) FILTER (WHERE paye), count(*) FILTER (WHERE checkout),
                   COALESCE(sum(rev), 0)::bigint
            FROM base GROUP BY 2, 3
            UNION ALL
            SELECT 'CAMPAIGN',
                   concat_ws(chr(31), COALESCE(vsource, src), ft_campaign,
                             COALESCE(ft_medium, ''), COALESCE(ft_content, '')),
                   '', count(*), count(*) FILTER (WHERE paye),
                   count(*) FILTER (WHERE checkout), COALESCE(sum(rev), 0)::bigint
            FROM base WHERE ft_campaign IS NOT NULL GROUP BY 2
            UNION ALL
            SELECT 'BUCKET',
                   to_char(date_trunc(CAST(:grain AS text),
                                      created_at AT TIME ZONE 'Europe/Paris'),
                           'YYYY-MM-DD HH24:MI:SS'),
                   '', count(*), count(*) FILTER (WHERE paye),
                   count(*) FILTER (WHERE checkout), COALESCE(sum(rev), 0)::bigint
            FROM base GROUP BY 2
            """, nativeQuery = true)
    List<UserCell> userCells(@Param("from") Instant from,
                             @Param("to") Instant to,
                             @Param("grain") String grain,
                             @Param("excluded") Collection<String> excludedEmails,
                             @Param("source") String source,
                             @Param("country") String country,
                             @Param("device") String device,
                             @Param("platform") String platform);

    // ------------------------------------------------------------------------
    // 3. Progression par format de diagnostic
    // ------------------------------------------------------------------------

    /**
     * Chaque maillon de la chaine d'un format, en visiteurs distincts.
     *
     * <p>Le format n'est <b>pas persiste</b> sur {@code diagnostic_sessions} — et
     * c'est voulu : au moment du choix, le candidat est encore invite, aucune
     * ligne ne pourrait le porter. Il vit donc sur l'evenement de depart, et la
     * population d'un format est l'ensemble des visiteurs qui l'ont <i>commence</i>.
     *
     * <p>{@code PAY} passe par {@code analytics_identity} : c'est la seule facon
     * de relier un format choisi en anonyme a un compte qui a paye. Un visiteur
     * jamais relie a un compte n'y figure pas — sous-compte assume, jamais
     * comble par une estimation.
     */
    @Query(value = """
            WITH vis AS (
                SELECT av.anonymous_id
                FROM analytics_visitor av
                WHERE (CAST(:source AS text) IS NULL OR av.ft_source = CAST(:source AS text))
                  AND (CAST(:country AS text) IS NULL
                       OR COALESCE(av.country_code, 'UNKNOWN') = CAST(:country AS text))
                  AND (CAST(:device AS text) IS NULL OR av.device_type = CAST(:device AS text))
                  AND (CAST(:platform AS text) IS NULL OR av.platform = CAST(:platform AS text))
            ),
            typed AS (
                SELECT DISTINCT e.anonymous_id AS anonymous_id,
                       COALESCE(e.properties ->> 'diagnosticType', 'UNKNOWN') AS dtype
                FROM analytics_event e
                JOIN vis v ON v.anonymous_id = e.anonymous_id
                WHERE e.event = 'DIAGNOSTIC_STARTED'
                  AND e.occurred_at >= :from AND e.occurred_at < :to
            ),
            steps AS (
                SELECT t.dtype AS dtype, e.event AS step,
                       count(DISTINCT e.anonymous_id) AS n
                FROM typed t
                JOIN analytics_event e ON e.anonymous_id = t.anonymous_id
                WHERE e.occurred_at >= :from AND e.occurred_at < :to
                  AND e.event IN ('DIAGNOSTIC_EE_COMPLETED', 'DIAGNOSTIC_EO_COMPLETED',
                                  'DIAGNOSTIC_CO_COMPLETED', 'DIAGNOSTIC_CE_COMPLETED',
                                  'DIAGNOSTIC_REPORT_VIEWED', 'PREMIUM_CTA_CLICKED')
                GROUP BY 1, 2
            ),
            payeurs AS (
                SELECT t.dtype AS dtype, count(DISTINCT u.id) AS n
                FROM typed t
                JOIN analytics_identity i ON i.anonymous_id = t.anonymous_id
                JOIN users u ON u.id = i.user_id
                    AND u.deleted_at IS NULL
                    AND lower(u.email) NOT IN (:excluded)
                JOIN user_subscriptions s ON s.user_id = u.id AND s.status <> 'PENDING'
                GROUP BY 1
            )
            SELECT dtype AS diag_type, 'START' AS step, count(*) AS n FROM typed GROUP BY 1
            UNION ALL SELECT dtype, step, n FROM steps
            UNION ALL SELECT dtype, 'PAY', n FROM payeurs
            """, nativeQuery = true)
    List<DiagStepCell> diagnosticSteps(@Param("from") Instant from,
                                       @Param("to") Instant to,
                                       @Param("excluded") Collection<String> excludedEmails,
                                       @Param("source") String source,
                                       @Param("country") String country,
                                       @Param("device") String device,
                                       @Param("platform") String platform);

    // ------------------------------------------------------------------------
    // 4. CTA Premium et attribution du paiement
    // ------------------------------------------------------------------------

    /**
     * Par emplacement de CTA : cliqueurs uniques, puis checkouts, payants et
     * revenu <b>attribues au dernier clic qui les precede</b> (brief §49).
     *
     * <p>⚠️ <b>Cette attribution ne remplace jamais celle de l'acquisition</b>,
     * qui reste au <i>premier</i> contact. Les deux repondent a deux questions
     * differentes : « d'ou vient cette personne » (une fois pour toutes) et
     * « quel bouton a declenche l'achat » (le dernier avant l'acte). Les
     * confondre ferait disparaitre le reseau qui a amene le candidat.
     *
     * <p>La fenetre de {@code 7 jours} borne le rattachement : au-dela, un clic
     * n'a plus rien declenche, il precede seulement.
     */
    @Query(value = """
            WITH clics AS (
                SELECT e.occurred_at AS occurred_at,
                       COALESCE(e.properties ->> 'ctaLocation', 'OTHER') AS loc,
                       e.anonymous_id AS anonymous_id,
                       COALESCE(e.user_id, i.user_id) AS uid
                FROM analytics_event e
                JOIN analytics_visitor av ON av.anonymous_id = e.anonymous_id
                LEFT JOIN analytics_identity i ON i.anonymous_id = e.anonymous_id
                WHERE e.event = 'PREMIUM_CTA_CLICKED'
                  AND e.occurred_at >= :from AND e.occurred_at < :to
                  AND (CAST(:source AS text) IS NULL OR av.ft_source = CAST(:source AS text))
                  AND (CAST(:country AS text) IS NULL
                       OR COALESCE(av.country_code, 'UNKNOWN') = CAST(:country AS text))
                  AND (CAST(:device AS text) IS NULL OR av.device_type = CAST(:device AS text))
                  AND (CAST(:platform AS text) IS NULL OR av.platform = CAST(:platform AS text))
            ),
            cibles AS (
                SELECT f.user_id AS uid, f.occurred_at AS at, 'CK' AS kind, 0::bigint AS rev
                FROM user_funnel_events f
                JOIN users u ON u.id = f.user_id
                WHERE f.event = 'CHECKOUT_STARTED'
                  AND f.occurred_at >= :from AND f.occurred_at < :to
                  AND u.deleted_at IS NULL AND lower(u.email) NOT IN (:excluded)
                UNION ALL
                SELECT s.user_id, s.starts_at, 'PAY', COALESCE(s.amount_eur_cents, 0)::bigint
                FROM user_subscriptions s
                JOIN users u ON u.id = s.user_id
                WHERE s.status <> 'PENDING'
                  AND s.starts_at >= :from AND s.starts_at < :to
                  AND u.deleted_at IS NULL AND lower(u.email) NOT IN (:excluded)
            ),
            attribue AS (
                SELECT c.kind AS kind, c.rev AS rev, c.uid AS uid, l.loc AS loc
                FROM cibles c
                JOIN LATERAL (
                    SELECT cl.loc
                    FROM clics cl
                    WHERE cl.uid = c.uid
                      AND cl.occurred_at <= c.at
                      AND cl.occurred_at >= c.at - INTERVAL '7 days'
                    ORDER BY cl.occurred_at DESC
                    LIMIT 1
                ) l ON true
            )
            SELECT loc AS loc, count(DISTINCT anonymous_id) AS prem,
                   0::bigint AS ck, 0::bigint AS pay, 0::bigint AS rev
            FROM clics GROUP BY 1
            UNION ALL
            SELECT loc, 0::bigint,
                   count(DISTINCT uid) FILTER (WHERE kind = 'CK'),
                   count(DISTINCT uid) FILTER (WHERE kind = 'PAY'),
                   COALESCE(sum(rev) FILTER (WHERE kind = 'PAY'), 0)::bigint
            FROM attribue GROUP BY 1
            """, nativeQuery = true)
    List<CtaCell> ctaCells(@Param("from") Instant from,
                           @Param("to") Instant to,
                           @Param("excluded") Collection<String> excludedEmails,
                           @Param("source") String source,
                           @Param("country") String country,
                           @Param("device") String device,
                           @Param("platform") String platform);

    // ------------------------------------------------------------------------
    // 5. Parcours reduits aux jalons
    // ------------------------------------------------------------------------

    /**
     * Les cinq parcours les plus frequents, reduits aux <b>jalons</b> du brief
     * §45 — jamais chaque page vue, qui noierait le signal sous le bruit.
     *
     * <p>Les repetitions immediates sont ecrasees ({@code lag}) : rouvrir deux
     * fois la landing n'est pas un parcours different. Le premier maillon est la
     * <b>provenance</b> du visiteur, pour lire « TikTok → landing → diagnostic
     * rapide » d'un seul trait.
     *
     * <p>⚠️ La chaine s'arrete aux jalons <i>observables cote visiteur</i>. Le
     * checkout et le paiement vivent sur les tables de comptes et n'ont pas
     * d'horodate rattachable a un parcours anonyme : les y coller demanderait de
     * deviner un ordre, ce qu'on ne fait pas.
     */
    @Query(value = """
            WITH m AS (
                SELECT e.anonymous_id AS anonymous_id, e.occurred_at AS occurred_at,
                       av.ft_source AS ft_source,
                       CASE e.event
                           WHEN 'LANDING_VIEWED' THEN 'LANDING'
                           WHEN 'SIGNUP_STARTED' THEN 'SIGNUP'
                           WHEN 'DIAGNOSTIC_REPORT_VIEWED' THEN 'REPORT'
                           WHEN 'PREMIUM_CTA_CLICKED' THEN 'PREMIUM_CLICK'
                           WHEN 'DIAGNOSTIC_STARTED' THEN
                               CASE WHEN COALESCE(e.properties ->> 'diagnosticType', 'UNKNOWN')
                                         = 'COMPLETE'
                                    THEN 'DIAGNOSTIC_COMPLETE' ELSE 'DIAGNOSTIC_RAPID' END
                       END AS ms
                FROM analytics_event e
                JOIN analytics_visitor av ON av.anonymous_id = e.anonymous_id
                WHERE e.occurred_at >= :from AND e.occurred_at < :to
                  AND (CAST(:source AS text) IS NULL OR av.ft_source = CAST(:source AS text))
                  AND (CAST(:country AS text) IS NULL
                       OR COALESCE(av.country_code, 'UNKNOWN') = CAST(:country AS text))
                  AND (CAST(:device AS text) IS NULL OR av.device_type = CAST(:device AS text))
                  AND (CAST(:platform AS text) IS NULL OR av.platform = CAST(:platform AS text))
            ),
            f AS (SELECT * FROM m WHERE ms IS NOT NULL),
            d AS (
                SELECT anonymous_id, ft_source, ms, occurred_at,
                       lag(ms) OVER (PARTITION BY anonymous_id ORDER BY occurred_at, ms) AS prev
                FROM f
            ),
            c AS (
                SELECT anonymous_id, min(ft_source) AS src,
                       string_agg(ms, '>' ORDER BY occurred_at, ms) AS chain
                FROM d WHERE prev IS DISTINCT FROM ms GROUP BY anonymous_id
            )
            SELECT src AS source, chain AS chain, count(*) AS n
            FROM c GROUP BY 1, 2 ORDER BY 3 DESC, 2 LIMIT 5
            """, nativeQuery = true)
    List<PathCell> topPaths(@Param("from") Instant from,
                            @Param("to") Instant to,
                            @Param("source") String source,
                            @Param("country") String country,
                            @Param("device") String device,
                            @Param("platform") String platform);

    // ------------------------------------------------------------------------
    // 6. Contexte d'inscription
    // ------------------------------------------------------------------------

    /**
     * Ou, dans le parcours, la creation de compte est declenchee (brief §47).
     *
     * <p>C'est un compte de <b>visiteurs</b>, pas de comptes crees : l'inscription
     * reussie se lit sur {@code users}, et le contexte n'existe que dans le
     * navigateur au moment ou le formulaire s'ouvre.
     */
    @Query(value = """
            SELECT COALESCE(e.properties ->> 'registrationContext', 'OTHER') AS contexte,
                   count(DISTINCT e.anonymous_id) AS n
            FROM analytics_event e
            JOIN analytics_visitor av ON av.anonymous_id = e.anonymous_id
            WHERE e.event = 'SIGNUP_STARTED'
              AND e.occurred_at >= :from AND e.occurred_at < :to
              AND (CAST(:source AS text) IS NULL OR av.ft_source = CAST(:source AS text))
              AND (CAST(:country AS text) IS NULL
                   OR COALESCE(av.country_code, 'UNKNOWN') = CAST(:country AS text))
              AND (CAST(:device AS text) IS NULL OR av.device_type = CAST(:device AS text))
              AND (CAST(:platform AS text) IS NULL OR av.platform = CAST(:platform AS text))
            GROUP BY 1
            """, nativeQuery = true)
    List<TriggerCell> registrationTriggers(@Param("from") Instant from,
                                           @Param("to") Instant to,
                                           @Param("source") String source,
                                           @Param("country") String country,
                                           @Param("device") String device,
                                           @Param("platform") String platform);

    // ------------------------------------------------------------------------
    // 7. Cumul hors periode
    // ------------------------------------------------------------------------

    /**
     * Comptes actifs, <b>a date</b> : ce chiffre n'est jamais filtre par la
     * periode (brief §29). Un total historique qui bougerait avec le selecteur de
     * dates ne serait plus un total.
     */
    @Query(value = """
            SELECT count(*) FROM users u
            WHERE u.deleted_at IS NULL AND lower(u.email) NOT IN (:excluded)
            """, nativeQuery = true)
    long totalUsers(@Param("excluded") Collection<String> excludedEmails);
}
