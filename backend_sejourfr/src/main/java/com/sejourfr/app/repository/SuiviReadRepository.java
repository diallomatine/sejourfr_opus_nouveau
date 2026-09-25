package com.sejourfr.app.repository;

import com.sejourfr.app.entity.DiagnosticRun;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Lecture agregee du dashboard « Suivi » ({@code GET /api/admin/analytics/suivi}).
 * <b>Rien ne s'ecrit ici.</b> Definitions : {@code docs/regles/mesure-audience.md}
 * § « Lecture du dashboard Suivi ».
 *
 * <p><b>Tout est agrege en SQL, a la volee</b> (brief §9 : vue materialisee
 * seulement si une lecture depasse 1 s sur un jeu realiste — verrouille par
 * {@code SuiviPerformanceIT}). <b>Six requetes, constantes</b>, quel que soit
 * le volume et les filtres (egalite verrouillee par le meme test).
 *
 * <p>Conventions communes :
 * <ul>
 *   <li><b>Personne</b> ({@code pk}) = {@code COALESCE(user_id, anonymous_id)} de
 *       la run ; une run sans l'un ni l'autre est sa propre personne.</li>
 *   <li><b>Source</b> = groupe (config {@code utmSourceGroups}, passee en
 *       {@code :srcMap} jsonb source → groupe, repli {@code :fallback}) de la
 *       source first-touch declaree : visiteur de la run, sinon visiteur
 *       d'inscription du compte, sinon son plus ancien visiteur lie, sinon
 *       {@code users.signup_source}. Aucune → {@code NULL} (inconnue, comptee
 *       seulement sous « Toutes »).</li>
 *   <li><b>Interne</b> : compte {@code is_internal}, ou identifiant de mesure lie
 *       a un compte interne ; exclu sauf {@code :includeInternal}.</li>
 *   <li>Un filtre {@code NULL} = « tous ». Bornes {@code [from, to)}, instants
 *       deja resolus en Europe/Paris par l'appelant.</li>
 * </ul>
 */
public interface SuiviReadRepository extends Repository<DiagnosticRun, UUID> {

    /** Groupe de la colonne {@code src_key}, selon la config (lecture, reversible). */
    String GROUPE = " (CASE WHEN src_key IS NULL THEN NULL"
            + " ELSE COALESCE(CAST(:srcMap AS jsonb) ->> lower(src_key), CAST(:fallback AS text)) END) ";

    /** Visiteur d'inscription ({@code vu}) et plus ancien visiteur lie ({@code vi}) du compte {@code u}. */
    String SOURCE_DU_COMPTE = """
            LEFT JOIN analytics_visitor vu ON vu.anonymous_id = u.signup_anonymous_id
            LEFT JOIN LATERAL (
                  SELECT COALESCE(v.ft_source_raw, v.ft_source) AS k
                    FROM analytics_identity i
                    JOIN analytics_visitor v ON v.anonymous_id = i.anonymous_id
                   WHERE i.user_id = u.id
                   ORDER BY i.linked_at, i.anonymous_id
                   LIMIT 1) vi ON true
            """;

    /** Cle de source du compte {@code u}, apres {@link #SOURCE_DU_COMPTE}. */
    String CLE_SOURCE_DU_COMPTE = " COALESCE(vu.ft_source_raw, vu.ft_source, vi.k, u.signup_source) ";

    /**
     * <b>« Soumis » retenu</b> d'une run {@code r} (controle C, V076). TCF : le
     * fait pose. Civique : le fait pose ET au moins {@code :civicMinRatio} des
     * questions repondues, mesure figee a la soumission — une run civique sans
     * mesure (anterieure a V076) est INCONNUE : jamais comptee soumise, jamais
     * lue comme 0 reponse. Applique une fois, dans {@link #RUNS} : tunnel,
     * ratios, activite et « jamais rattachees » lisent tous cette colonne.
     */
    String SOUMIS_RETENU = """
            (r.diagnostic_type <> 'CIVIQUE'
                  OR (r.submitted_question_count > 0
                      AND r.submitted_answered_count
                          >= CAST(:civicMinRatio AS float8) * r.submitted_question_count))""";

    /**
     * Les runs du tunnel (rapide TCF et civique, Q2), personne et groupe de
     * source resolus, comptes internes exclus sauf demande.
     */
    String RUNS = """
            runs AS (
                SELECT x.*, """ + GROUPE + """
             AS grp
                  FROM (SELECT r.id, r.diagnostic_type, r.platform, r.user_id, r.subject_viewed_at,
                               CASE WHEN """ + SOUMIS_RETENU + """
             THEN r.submitted_at END AS submitted_at,
                               CASE WHEN """ + SOUMIS_RETENU + """
             THEN r.submitted_authenticated END AS submitted_authenticated,
                               r.claimed_at, r.claim_kind,
                               COALESCE(CAST(r.user_id AS text), CAST(r.anonymous_id AS text),
                                        CAST(r.id AS text)) AS pk,
                               COALESCE(vr.ft_source_raw, vr.ft_source, """ + CLE_SOURCE_DU_COMPTE + """
            ) AS src_key
                          FROM diagnostic_run r
                          LEFT JOIN analytics_visitor vr ON vr.anonymous_id = r.anonymous_id
                          LEFT JOIN users u ON u.id = r.user_id
            """ + SOURCE_DU_COMPTE + """
                         WHERE r.diagnostic_type IN ('QUICK_TCF', 'CIVIQUE')
                           AND (:includeInternal
                                OR (NOT COALESCE(u.is_internal, false)
                                    AND NOT EXISTS (SELECT 1 FROM analytics_identity ii
                                                      JOIN users iu ON iu.id = ii.user_id
                                                     WHERE ii.anonymous_id = r.anonymous_id
                                                       AND iu.is_internal)))) x
            )
            """;

    // ------------------------------------------------------------------------
    // 1. Visiteurs (periode et periode precedente) et sources (periode)
    // ------------------------------------------------------------------------

    interface VisitorCell {
        /** {@code CUR} ou {@code PREV}. */
        String getPer();

        /** Groupe de source ; jamais nul (un visiteur a toujours une source). */
        String getGrp();

        long getN();
    }

    /**
     * Identifiants de mesure distincts ayant au moins un evenement dans la
     * periode, par groupe de source first-touch. Un visiteur appartient a un
     * seul groupe : la somme des groupes est le total.
     */
    @Query(value = """
            WITH ev AS (
                SELECT DISTINCT
                       CASE WHEN e.occurred_at >= :from THEN 'CUR' ELSE 'PREV' END AS per,
                       e.anonymous_id
                  FROM analytics_event e
                 WHERE e.occurred_at >= :prevFrom AND e.occurred_at < :to
                   AND (CAST(:platform AS text) IS NULL OR e.platform = CAST(:platform AS text))
                   AND (:includeInternal OR NOT COALESCE(e.is_internal, false))
            ),
            vis AS (
                SELECT x.per, """ + GROUPE + """
             AS grp
                  FROM (SELECT ev.per, COALESCE(v.ft_source_raw, v.ft_source) AS src_key
                          FROM ev
                          JOIN analytics_visitor v ON v.anonymous_id = ev.anonymous_id
                         WHERE :includeInternal
                            OR NOT EXISTS (SELECT 1 FROM analytics_identity ii
                                             JOIN users iu ON iu.id = ii.user_id
                                            WHERE ii.anonymous_id = ev.anonymous_id AND iu.is_internal)) x
            )
            SELECT per AS per, grp AS grp, count(*) AS n
              FROM vis
             WHERE CAST(:source AS text) IS NULL OR grp = CAST(:source AS text)
             GROUP BY per, grp
            """, nativeQuery = true)
    List<VisitorCell> visitors(@Param("prevFrom") Instant prevFrom, @Param("from") Instant from,
                               @Param("to") Instant to, @Param("platform") String platform,
                               @Param("source") String source, @Param("includeInternal") boolean includeInternal,
                               @Param("srcMap") String srcMap, @Param("fallback") String fallback);

    // ------------------------------------------------------------------------
    // 2. Tunnel — cohorte (brief §7.2), trois vues d'un coup : ALL, QUICK_TCF, CIVIQUE
    // ------------------------------------------------------------------------

    interface FunnelRow {
        /** {@code ALL}, {@code QUICK_TCF} ou {@code CIVIQUE}. */
        String getScope();

        long getS1();

        long getS2();

        long getS3();

        long getS4();

        long getS5();

        long getS6();

        long getS7();

        long getAttachedAlready();

        long getAttachedSignup();

        long getAttachedLogin();

        long getAnonSubmitted();

        Long getCohortNet();

        long getCohortUnknown();
    }

    /**
     * Cohorte : pour chaque personne et chaque type, sa <b>1ʳᵉ run</b> de ce type
     * (toutes dates) ; elle entre si son sujet a ete vu dans la periode, et si la
     * plateforme et la source de CETTE run passent les filtres. Chaque etape doit
     * etre atteinte avant {@code subject_viewed_at + :windowDays} et exige la
     * precedente.
     *
     * <p>Etapes 5 et 6 : l'evenement se rattache a la run par son parcours
     * ({@code v_journey_founding_run}, Q8), sinon par la run qu'il cite. Etape 7 :
     * achat attribue a la run ({@code origin = DIAGNOSTIC_PLAN}), non
     * {@code PENDING}. CA net cohorte : net HT de ces achats, tous leurs
     * remboursements deduits ; un achat sans decomposition (ou un remboursement
     * sans delta) est compte a part, jamais a zero.
     *
     * <p>Vue {@code ALL} : personnes distinctes ; une personne rattachee n'entre
     * que dans une sous-ligne (deja connecte, puis inscrit, puis connecte apres).
     *
     * @param horizon {@code to + windowDays} : aucun fait d'une entree de la
     *                periode ne peut etre posterieur
     */
    @Query(value = "WITH " + RUNS + """
            , firsts AS (
                SELECT DISTINCT ON (pk, diagnostic_type) *
                  FROM runs
                 ORDER BY pk, diagnostic_type, subject_viewed_at, id
            ),
            ref AS (
                SELECT f.*, f.subject_viewed_at + make_interval(days => CAST(:windowDays AS int)) AS wend
                  FROM firsts f
                 WHERE f.subject_viewed_at >= :from AND f.subject_viewed_at < :to
                   AND (CAST(:platform AS text) IS NULL OR f.platform = CAST(:platform AS text))
                   AND (CAST(:source AS text) IS NULL OR f.grp = CAST(:source AS text))
            ),
            rep AS (
                SELECT e.diagnostic_run_id AS run_id, min(e.occurred_at) AS at
                  FROM analytics_event e
                 WHERE e.event = 'DIAGNOSTIC_REPORT_VIEWED' AND e.diagnostic_run_id IS NOT NULL
                   AND e.occurred_at >= :from AND e.occurred_at < :horizon
                 GROUP BY 1
            ),
            plan_ev AS (
                SELECT e.event AS event, COALESCE(fr.diagnostic_run_id, e.diagnostic_run_id) AS run_id,
                       min(e.occurred_at) AS at
                  FROM analytics_event e
                  LEFT JOIN v_journey_founding_run fr ON fr.journey_id = e.journey_id
                 WHERE e.event IN ('PLAN_OPENED', 'PLAN_UNLOCK_CLICKED')
                   AND (e.journey_id IS NOT NULL OR e.diagnostic_run_id IS NOT NULL)
                   AND e.occurred_at >= :from AND e.occurred_at < :horizon
                 GROUP BY 1, 2
            ),
            pur AS (
                SELECT s.diagnostic_run_id AS run_id, s.purchased_at, s.net_ex_vat_cents AS net,
                       rf.delta, COALESCE(rf.unknown, false) AS refund_unknown
                  FROM user_subscriptions s
                  LEFT JOIN LATERAL (SELECT sum(pr.net_ex_vat_delta_cents) AS delta,
                                            bool_or(pr.net_ex_vat_delta_cents IS NULL) AS unknown
                                       FROM payment_refunds pr
                                      WHERE pr.subscription_id = s.id) rf ON true
                 WHERE s.diagnostic_run_id IS NOT NULL AND s.status <> 'PENDING'
                   AND s.purchased_at >= :from AND s.purchased_at < :horizon
            ),
            reached AS (
                SELECT ref.pk, ref.diagnostic_type AS dtype,
                       (ref.submitted_at IS NOT NULL AND ref.submitted_at < ref.wend) AS s2,
                       (ref.submitted_authenticated IS TRUE
                        OR (ref.claimed_at IS NOT NULL AND ref.claimed_at < ref.wend)) AS att,
                       COALESCE(ref.submitted_authenticated, false) AS already,
                       ref.claim_kind,
                       (rep.at < ref.wend) IS TRUE AS rep_ok,
                       (po.at < ref.wend) IS TRUE AS plan_ok,
                       (pu.at < ref.wend) IS TRUE AS unlock_ok,
                       pa.n AS pur_n, pa.net AS pur_net, pa.unknown AS pur_unknown
                  FROM ref
                  LEFT JOIN rep ON rep.run_id = ref.id
                  LEFT JOIN plan_ev po ON po.run_id = ref.id AND po.event = 'PLAN_OPENED'
                  LEFT JOIN plan_ev pu ON pu.run_id = ref.id AND pu.event = 'PLAN_UNLOCK_CLICKED'
                  LEFT JOIN LATERAL (
                        SELECT count(*) AS n,
                               sum(p.net + COALESCE(p.delta, 0))
                                   FILTER (WHERE p.net IS NOT NULL AND NOT p.refund_unknown) AS net,
                               count(*) FILTER (WHERE p.net IS NULL OR p.refund_unknown) AS unknown
                          FROM pur p
                         WHERE p.run_id = ref.id AND p.purchased_at < ref.wend) pa ON true
            ),
            flags AS (
                SELECT pk, dtype, s2,
                       (s2 AND att) AS s3,
                       (s2 AND att AND already) AS a_already,
                       (s2 AND att AND NOT already AND claim_kind = 'SIGNUP') AS a_signup,
                       (s2 AND att AND NOT already AND claim_kind = 'LOGIN') AS a_login,
                       (s2 AND NOT already) AS anon,
                       (s2 AND att AND rep_ok) AS s4,
                       (s2 AND att AND rep_ok AND plan_ok) AS s5,
                       (s2 AND att AND rep_ok AND plan_ok AND unlock_ok) AS s6,
                       (s2 AND att AND rep_ok AND plan_ok AND unlock_ok AND pur_n > 0) AS s7,
                       pur_net, pur_unknown
                  FROM reached
            ),
            per_person AS (
                SELECT scope, pk,
                       bool_or(s2) AS s2, bool_or(s3) AS s3, bool_or(s4) AS s4, bool_or(s5) AS s5,
                       bool_or(s6) AS s6, bool_or(s7) AS s7,
                       bool_or(a_already) AS a_already, bool_or(a_signup) AS a_signup,
                       bool_or(a_login) AS a_login, bool_or(anon) AS anon,
                       sum(CASE WHEN s7 THEN pur_net END) AS net,
                       sum(CASE WHEN s7 THEN pur_unknown ELSE 0 END) AS unk
                  FROM (SELECT 'ALL' AS scope, f.* FROM flags f
                        UNION ALL
                        SELECT f.dtype, f.* FROM flags f) x
                 GROUP BY scope, pk
            )
            SELECT scope AS scope,
                   count(*) AS s1,
                   count(*) FILTER (WHERE s2) AS s2,
                   count(*) FILTER (WHERE s3) AS s3,
                   count(*) FILTER (WHERE s4) AS s4,
                   count(*) FILTER (WHERE s5) AS s5,
                   count(*) FILTER (WHERE s6) AS s6,
                   count(*) FILTER (WHERE s7) AS s7,
                   count(*) FILTER (WHERE a_already) AS attached_already,
                   count(*) FILTER (WHERE a_signup AND NOT a_already) AS attached_signup,
                   count(*) FILTER (WHERE a_login AND NOT a_already AND NOT a_signup) AS attached_login,
                   count(*) FILTER (WHERE anon) AS anon_submitted,
                   CAST(sum(net) AS bigint) AS cohort_net,
                   CAST(COALESCE(sum(unk), 0) AS bigint) AS cohort_unknown
              FROM per_person
             GROUP BY scope
            """, nativeQuery = true)
    List<FunnelRow> funnel(@Param("from") Instant from, @Param("to") Instant to,
                           @Param("horizon") Instant horizon, @Param("windowDays") int windowDays,
                           @Param("platform") String platform, @Param("source") String source,
                           @Param("includeInternal") boolean includeInternal,
                           @Param("srcMap") String srcMap, @Param("fallback") String fallback,
                           @Param("civicMinRatio") double civicMinRatio);

    // ------------------------------------------------------------------------
    // 3. Activite des runs (periode) : soumis, jamais rattaches, connexions
    // ------------------------------------------------------------------------

    interface ActivityRow {
        long getCurFirst();

        long getCurRaw();

        long getPrevFirst();

        long getPrevRaw();

        long getAnonNeverAttached();

        long getLoggedInAfter();
    }

    /**
     * Soumissions de la periode (et de la precedente) : 1ʳᵉ tentative = personnes
     * distinctes du type filtre ; brut = toutes les runs soumises. « Jamais
     * rattachees » : soumises anonymement dans la periode, sans claim dans les
     * {@code :windowDays} jours qui suivent la soumission. Connexions apres
     * diagnostic : comptes ayant claime une run par connexion dans la periode
     * (le filtre type ne s'y applique pas, c'est une ligne du bloc Inscriptions).
     *
     * @param runType {@code QUICK_TCF}, {@code CIVIQUE} ou {@code NULL} (les deux)
     */
    @Query(value = "WITH " + RUNS + """
            , flt AS (
                SELECT * FROM runs
                 WHERE (CAST(:platform AS text) IS NULL OR platform = CAST(:platform AS text))
                   AND (CAST(:source AS text) IS NULL OR grp = CAST(:source AS text))
            ),
            typed AS (
                SELECT * FROM flt
                 WHERE CAST(:runType AS text) IS NULL OR diagnostic_type = CAST(:runType AS text)
            )
            SELECT (SELECT count(DISTINCT pk) FROM typed
                     WHERE submitted_at >= :from AND submitted_at < :to) AS cur_first,
                   (SELECT count(*) FROM typed
                     WHERE submitted_at >= :from AND submitted_at < :to) AS cur_raw,
                   (SELECT count(DISTINCT pk) FROM typed
                     WHERE submitted_at >= :prevFrom AND submitted_at < :from) AS prev_first,
                   (SELECT count(*) FROM typed
                     WHERE submitted_at >= :prevFrom AND submitted_at < :from) AS prev_raw,
                   (SELECT count(*) FROM typed
                     WHERE submitted_at >= :from AND submitted_at < :to
                       AND submitted_authenticated = false
                       AND NOT (claimed_at IS NOT NULL
                                AND claimed_at < submitted_at
                                                 + make_interval(days => CAST(:windowDays AS int))))
                       AS anon_never_attached,
                   (SELECT count(DISTINCT user_id) FROM flt
                     WHERE claim_kind = 'LOGIN' AND claimed_at >= :from AND claimed_at < :to)
                       AS logged_in_after
            """, nativeQuery = true)
    ActivityRow activity(@Param("prevFrom") Instant prevFrom, @Param("from") Instant from,
                         @Param("to") Instant to, @Param("windowDays") int windowDays,
                         @Param("runType") String runType, @Param("platform") String platform,
                         @Param("source") String source, @Param("includeInternal") boolean includeInternal,
                         @Param("srcMap") String srcMap, @Param("fallback") String fallback,
                         @Param("civicMinRatio") double civicMinRatio);

    // ------------------------------------------------------------------------
    // 4. Achats et remboursements (periode et periode precedente)
    // ------------------------------------------------------------------------

    /**
     * Achats filtres. Type d'un achat : celui de sa run attribuee, sinon le
     * module de son parcours, sinon {@code CIVIQUE} pour un pass Civique seul ;
     * un pass Integral non attribue n'a pas de type (compte sous « Tous »
     * seulement). Plateforme = canal (Stripe = web, Apple = iOS, Google = Android).
     */
    String ACHATS = """
            achats AS (
                SELECT x.* FROM (
                    SELECT s.id, s.source, s.purchased_at, s.amount_eur_cents, s.vat_cents,
                           s.provider_fee_cents, s.net_after_fee_cents, s.net_ex_vat_cents, s.fee_source,
                           s.origin,
                           CASE WHEN rt.diagnostic_type IN ('QUICK_TCF', 'FULL_TCF') THEN 'TCF'
                                WHEN rt.diagnostic_type = 'CIVIQUE' THEN 'CIVIQUE'
                                WHEN j.module IN ('TCF', 'CIVIQUE') THEN j.module
                                WHEN p.module_access = 'CIVIQUE' THEN 'CIVIQUE'
                           END AS ptype,
                           CASE s.source WHEN 'STRIPE' THEN 'WEB' WHEN 'APPLE' THEN 'IOS'
                                         WHEN 'GOOGLE' THEN 'ANDROID' END AS pplatform,
                           """ + CLE_SOURCE_DU_COMPTE + """
             AS src_key
                      FROM user_subscriptions s
                      JOIN users u ON u.id = s.user_id
                      JOIN plans p ON p.id = s.plan_id
                      LEFT JOIN diagnostic_run rt ON rt.id = s.diagnostic_run_id
                      LEFT JOIN journey j ON j.id = s.journey_id
            """ + SOURCE_DU_COMPTE + """
                     WHERE s.status <> 'PENDING'
                       AND (:includeInternal OR NOT u.is_internal)) x
                 WHERE (CAST(:type AS text) IS NULL OR x.ptype = CAST(:type AS text))
                   AND (CAST(:platform AS text) IS NULL OR x.pplatform = CAST(:platform AS text))
                   AND (CAST(:source AS text) IS NULL OR (""" + GROUPE + """
            ) = CAST(:source AS text))
            )
            """;

    interface PurchaseCell {
        String getPer();

        String getProvider();

        long getN();

        Long getGross();

        long getGrossUnknown();

        Long getVat();

        Long getFee();

        Long getNetAfterFee();

        Long getNetExVat();

        long getWithoutBreakdown();

        long getEstimatedFee();

        long getOriginDiagnosticPlan();

        long getOriginOtherCta();

        long getOriginUnknown();
    }

    /** Achats dates par {@code purchased_at}, par periode et par canal. Rembourses inclus. */
    @Query(value = "WITH " + ACHATS + """
            SELECT CASE WHEN a.purchased_at >= :from THEN 'CUR' ELSE 'PREV' END AS per,
                   a.source AS provider,
                   count(*) AS n,
                   CAST(sum(a.amount_eur_cents) AS bigint) AS gross,
                   count(*) FILTER (WHERE a.amount_eur_cents IS NULL) AS gross_unknown,
                   CAST(sum(a.vat_cents) AS bigint) AS vat,
                   CAST(sum(a.provider_fee_cents) AS bigint) AS fee,
                   CAST(sum(a.net_after_fee_cents) AS bigint) AS net_after_fee,
                   CAST(sum(a.net_ex_vat_cents) AS bigint) AS net_ex_vat,
                   count(*) FILTER (WHERE a.net_ex_vat_cents IS NULL) AS without_breakdown,
                   count(*) FILTER (WHERE a.fee_source = 'ESTIMATED') AS estimated_fee,
                   count(*) FILTER (WHERE a.origin = 'DIAGNOSTIC_PLAN') AS origin_diagnostic_plan,
                   count(*) FILTER (WHERE a.origin = 'OTHER_CTA') AS origin_other_cta,
                   count(*) FILTER (WHERE a.origin = 'UNKNOWN') AS origin_unknown
              FROM achats a
             WHERE a.purchased_at >= :prevFrom AND a.purchased_at < :to
             GROUP BY 1, 2
            """, nativeQuery = true)
    List<PurchaseCell> purchases(@Param("prevFrom") Instant prevFrom, @Param("from") Instant from,
                                 @Param("to") Instant to, @Param("type") String type,
                                 @Param("platform") String platform, @Param("source") String source,
                                 @Param("includeInternal") boolean includeInternal,
                                 @Param("srcMap") String srcMap, @Param("fallback") String fallback);

    interface RefundCell {
        String getPer();

        long getN();

        Long getAmount();

        Long getDelta();
    }

    /**
     * Remboursements dates par {@code refunded_at} (logique periode), filtres par
     * l'achat qu'ils touchent — quelle que soit la date de cet achat.
     */
    @Query(value = "WITH " + ACHATS + """
            SELECT CASE WHEN pr.refunded_at >= :from THEN 'CUR' ELSE 'PREV' END AS per,
                   count(*) AS n,
                   CAST(sum(pr.refunded_eur_cents) AS bigint) AS amount,
                   CAST(sum(pr.net_ex_vat_delta_cents) AS bigint) AS delta
              FROM payment_refunds pr
              JOIN achats a ON a.id = pr.subscription_id
             WHERE pr.refunded_at >= :prevFrom AND pr.refunded_at < :to
             GROUP BY 1
            """, nativeQuery = true)
    List<RefundCell> refunds(@Param("prevFrom") Instant prevFrom, @Param("from") Instant from,
                             @Param("to") Instant to, @Param("type") String type,
                             @Param("platform") String platform, @Param("source") String source,
                             @Param("includeInternal") boolean includeInternal,
                             @Param("srcMap") String srcMap, @Param("fallback") String fallback);

    // ------------------------------------------------------------------------
    // 5. Inscriptions (periode)
    // ------------------------------------------------------------------------

    interface SignupRow {
        long getTotal();

        long getAfterTotal();

        long getAfterTcf();

        long getAfterCivique();

        long getOutside();

        long getContextUnknown();

        long getWeb();

        long getIos();

        long getAndroid();

        long getMobile();

        long getPlatformUnknown();
    }

    /**
     * Comptes crees dans la periode ({@code users.created_at}, non supprimes),
     * par contexte d'inscription, type du diagnostic rattache et plateforme.
     */
    @Query(value = """
            WITH comptes AS (
                SELECT x.* FROM (
                    SELECT u.signup_context, u.signup_diagnostic_type, u.signup_platform,
                           """ + CLE_SOURCE_DU_COMPTE + """
             AS src_key
                      FROM users u
            """ + SOURCE_DU_COMPTE + """
                     WHERE u.created_at >= :from AND u.created_at < :to AND u.deleted_at IS NULL
                       AND (:includeInternal OR NOT u.is_internal)
                       AND (CAST(:platform AS text) IS NULL OR u.signup_platform = CAST(:platform AS text))) x
                 WHERE CAST(:source AS text) IS NULL OR (""" + GROUPE + """
            ) = CAST(:source AS text)
            )
            SELECT count(*) AS total,
                   count(*) FILTER (WHERE signup_context = 'AFTER_DIAGNOSTIC') AS after_total,
                   count(*) FILTER (WHERE signup_context = 'AFTER_DIAGNOSTIC'
                                      AND signup_diagnostic_type IN ('QUICK_TCF', 'FULL_TCF')) AS after_tcf,
                   count(*) FILTER (WHERE signup_context = 'AFTER_DIAGNOSTIC'
                                      AND signup_diagnostic_type = 'CIVIQUE') AS after_civique,
                   count(*) FILTER (WHERE signup_context = 'OUTSIDE_DIAGNOSTIC') AS outside,
                   count(*) FILTER (WHERE signup_context IS NULL) AS context_unknown,
                   count(*) FILTER (WHERE signup_platform = 'WEB') AS web,
                   count(*) FILTER (WHERE signup_platform = 'IOS') AS ios,
                   count(*) FILTER (WHERE signup_platform = 'ANDROID') AS android,
                   count(*) FILTER (WHERE signup_platform = 'MOBILE') AS mobile,
                   count(*) FILTER (WHERE signup_platform IS NULL
                                       OR signup_platform NOT IN ('WEB', 'IOS', 'ANDROID', 'MOBILE'))
                       AS platform_unknown
              FROM comptes
            """, nativeQuery = true)
    SignupRow signups(@Param("from") Instant from, @Param("to") Instant to,
                      @Param("platform") String platform, @Param("source") String source,
                      @Param("includeInternal") boolean includeInternal,
                      @Param("srcMap") String srcMap, @Param("fallback") String fallback);
}
