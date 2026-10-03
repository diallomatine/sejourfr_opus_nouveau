package com.sejourfr.app.repository;

import com.sejourfr.app.entity.ProductionSubmission;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Lectures de la console admin « Productions IA » : <b>lecture seule, sans
 * effet de bord</b>. Périmètre (F-2 A) : productions TCF EE/EO complètes, EO
 * temps réel comprise ; ni diagnostic, ni petits sujets Compétences.
 *
 * <p>🛑 Le <b>statut IA</b> (F-6 A) et l'<b>état de signalement</b> d'une
 * production se calculent ICI et nulle part ailleurs : la liste, ses filtres
 * et l'en-tête de la fiche lisent la même expression.
 *
 * <p>Une page = {@link #findPage} + {@link #count} : deux requêtes, quel que
 * soit le nombre de lignes (verrouillé par égalité dans l'IT).
 */
public interface AdminProductionReadRepository extends Repository<ProductionSubmission, UUID> {

    /** Une ligne de la liste (et l'en-tête de la fiche). */
    interface Ligne {
        UUID getId();
        Instant getSubmittedAt();
        UUID getUserId();
        String getUserEmail();
        Boolean getUserInternal();
        String getEpreuve();
        Number getTache();
        String getSource();
        Boolean getExamenComplet();
        Boolean getExamenBlanc();
        /** Niveau observé (tâche) de la dernière évaluation, {@code null} = aucun. */
        String getNiveau();
        String getStatutIa();
        String getEtatSignalement();
        Boolean getAnnotee();
    }

    String BASE = """
            WITH base AS (
                SELECT ps.id AS id,
                       ps.submitted_at AS submitted_at,
                       ps.user_id AS user_id,
                       u.email AS user_email,
                       COALESCE(u.is_internal, FALSE) AS user_internal,
                       pt.epreuve AS epreuve,
                       pt.tache_numero AS tache,
                       ps.source AS source,
                       (a.parent_attempt_id IS NOT NULL) AS examen_complet,
                       (a.slot_number IS NOT NULL) AS examen_blanc,
                       e.niveau_cecrl AS niveau,
                       CASE
                           WHEN ps.statut = 'FAILED' THEN 'ECHEC'
                           WHEN ps.statut = 'EVALUATED' AND e.evaluabilite = 'NON_EVALUABLE' THEN 'NON_EVALUABLE'
                           WHEN ps.statut = 'EVALUATED' THEN 'EVALUEE'
                           ELSE 'EN_COURS'
                       END AS statut_ia,
                       CASE
                           WHEN f.id IS NULL THEN 'AUCUN'
                           WHEN f.verified_at IS NULL THEN 'SIGNALE'
                           ELSE 'VERIFIE'
                       END AS etat_signalement,
                       EXISTS (SELECT 1 FROM human_calibration_notes h
                                WHERE h.submission_id = ps.id) AS annotee
                  FROM production_submissions ps
                  JOIN production_tasks pt ON pt.id = ps.production_task_id
                  JOIN users u ON u.id = ps.user_id
                  JOIN attempts a ON a.id = ps.attempt_id
                  LEFT JOIN LATERAL (
                        SELECT ae.niveau_cecrl, ae.evaluabilite
                          FROM ai_evaluations ae
                         WHERE ae.submission_id = ps.id
                         ORDER BY ae.evaluated_at DESC, ae.id DESC
                         LIMIT 1) e ON TRUE
                  LEFT JOIN LATERAL (
                        SELECT fl.id, fl.verified_at
                          FROM ai_evaluation_flags fl
                         WHERE fl.submission_id = ps.id AND fl.removed_at IS NULL
                         ORDER BY fl.created_at DESC, fl.id DESC
                         LIMIT 1) f ON TRUE
                 WHERE ps.is_diagnostic = FALSE
                   AND pt.diagnostic_code IS NULL
                   AND pt.epreuve IN ('TCF_EE', 'TCF_EO')
                   AND (:includeInternal OR NOT COALESCE(u.is_internal, FALSE))
                   AND (CAST(:submissionId AS uuid) IS NULL OR ps.id = CAST(:submissionId AS uuid))
                   AND (CAST(:qUuid AS uuid) IS NULL
                        OR ps.id = CAST(:qUuid AS uuid) OR ps.user_id = CAST(:qUuid AS uuid))
                   AND (CAST(:qPattern AS varchar) IS NULL
                        OR lower(u.email) LIKE CAST(:qPattern AS varchar) ESCAPE '\\')
                   AND (CAST(:epreuve AS varchar) IS NULL OR pt.epreuve = CAST(:epreuve AS varchar))
                   AND (CAST(:tache AS integer) IS NULL OR pt.tache_numero = CAST(:tache AS integer))
                   AND (CAST(:fromTs AS timestamptz) IS NULL OR ps.submitted_at >= CAST(:fromTs AS timestamptz))
                   AND (CAST(:toTs AS timestamptz) IS NULL OR ps.submitted_at < CAST(:toTs AS timestamptz))
            )
            """;

    String FILTRES = """
             WHERE (CAST(:niveau AS varchar) IS NULL
                    OR (CAST(:niveau AS varchar) = 'SANS_NIVEAU' AND niveau IS NULL)
                    OR niveau = CAST(:niveau AS varchar))
               AND (CAST(:statut AS varchar) IS NULL OR statut_ia = CAST(:statut AS varchar))
               AND (CAST(:etatSignalement AS varchar) IS NULL
                    OR etat_signalement = CAST(:etatSignalement AS varchar))
               AND (CAST(:annotee AS boolean) IS NULL OR annotee = CAST(:annotee AS boolean))
            """;

    @Query(value = BASE + """
            SELECT id AS id, submitted_at AS submittedAt, user_id AS userId, user_email AS userEmail,
                   user_internal AS userInternal, epreuve AS epreuve, tache AS tache, source AS source,
                   examen_complet AS examenComplet, examen_blanc AS examenBlanc, niveau AS niveau,
                   statut_ia AS statutIa, etat_signalement AS etatSignalement, annotee AS annotee
              FROM base
            """ + FILTRES + """
             ORDER BY
                   CASE WHEN CAST(:sort AS varchar) = 'DATE_ASC' THEN submitted_at END ASC,
                   CASE WHEN CAST(:sort AS varchar) = 'NIVEAU_DESC' THEN
                        CASE niveau WHEN 'A1_NON_ATTEINT' THEN 0 WHEN 'A1' THEN 1 WHEN 'A2' THEN 2
                                    WHEN 'B1' THEN 3 WHEN 'B2' THEN 4 WHEN 'C1' THEN 5 WHEN 'C2' THEN 6 END
                   END DESC NULLS LAST,
                   CASE WHEN CAST(:sort AS varchar) = 'NIVEAU_ASC' THEN
                        CASE niveau WHEN 'A1_NON_ATTEINT' THEN 0 WHEN 'A1' THEN 1 WHEN 'A2' THEN 2
                                    WHEN 'B1' THEN 3 WHEN 'B2' THEN 4 WHEN 'C1' THEN 5 WHEN 'C2' THEN 6 END
                   END ASC NULLS LAST,
                   CASE WHEN CAST(:sort AS varchar) = 'EPREUVE' THEN epreuve END ASC,
                   CASE WHEN CAST(:sort AS varchar) = 'EPREUVE' THEN tache END ASC,
                   submitted_at DESC, id DESC
             LIMIT :limit OFFSET :offset
            """, nativeQuery = true)
    List<Ligne> findPage(@Param("includeInternal") boolean includeInternal,
                         @Param("submissionId") UUID submissionId,
                         @Param("qUuid") UUID qUuid,
                         @Param("qPattern") String qPattern,
                         @Param("epreuve") String epreuve,
                         @Param("tache") Integer tache,
                         @Param("fromTs") Instant fromTs,
                         @Param("toTs") Instant toTs,
                         @Param("niveau") String niveau,
                         @Param("statut") String statut,
                         @Param("etatSignalement") String etatSignalement,
                         @Param("annotee") Boolean annotee,
                         @Param("sort") String sort,
                         @Param("limit") int limit,
                         @Param("offset") long offset);

    @Query(value = BASE + "SELECT count(*) FROM base" + FILTRES, nativeQuery = true)
    long count(@Param("includeInternal") boolean includeInternal,
               @Param("submissionId") UUID submissionId,
               @Param("qUuid") UUID qUuid,
               @Param("qPattern") String qPattern,
               @Param("epreuve") String epreuve,
               @Param("tache") Integer tache,
               @Param("fromTs") Instant fromTs,
               @Param("toTs") Instant toTs,
               @Param("niveau") String niveau,
               @Param("statut") String statut,
               @Param("etatSignalement") String etatSignalement,
               @Param("annotee") Boolean annotee);
}
