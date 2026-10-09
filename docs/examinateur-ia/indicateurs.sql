-- ============================================================================
-- Indicateurs de conduite de l'examinateur IA temps réel (EO T1/T2)
-- ----------------------------------------------------------------------------
-- Lecture seule. Données : V090 (realtime_session_turns, realtime_session_events,
-- realtime_fallbacks, colonnes de mesure de realtime_sessions).
-- Unité de « réplique » : un SEGMENT relayé (tours consécutifs d'un même
-- locuteur fusionnés par le client). Temps en ms depuis setupComplete côté
-- client. Temps candidat = transcription (approximation, DECISIONS D-07).
-- Toutes les requêtes ventilent par tâche, version de persona et plateforme.
-- Sessions mesurées : COMPLETED, ouvertes après le lot M (persona_version renseignée).
-- Chaque requête est autonome (pas de vue, pas de table temporaire).
-- Exécuter : psql -d sejourfr_db -f docs/examinateur-ia/indicateurs.sql
-- ============================================================================

-- 1. Part de l'examinateur : temps de parole (secondes) et mots
SELECT s.tache_numero,
       s.persona_version,
       COALESCE(s.client_platform, 'UNKNOWN')                                        AS plateforme,
       count(DISTINCT s.id)                                                          AS sessions,
       round(100.0 * sum(t.ended_at_ms - t.started_at_ms) FILTER (WHERE t.speaker = 'EXAMINER')
             / NULLIF(sum(t.ended_at_ms - t.started_at_ms), 0), 1)                    AS pct_temps_examinateur,
       round(sum(t.ended_at_ms - t.started_at_ms) FILTER (WHERE t.speaker = 'EXAMINER') / 1000.0, 1)  AS sec_examinateur,
       round(sum(t.ended_at_ms - t.started_at_ms) FILTER (WHERE t.speaker = 'CANDIDATE') / 1000.0, 1) AS sec_candidat,
       round(100.0 * sum(t.word_count) FILTER (WHERE t.speaker = 'EXAMINER')
             / NULLIF(sum(t.word_count), 0), 1)                                      AS pct_mots_examinateur
FROM realtime_sessions s
JOIN realtime_session_turns t ON t.session_id = s.id
WHERE s.status = 'COMPLETED'
  AND s.persona_version IS NOT NULL
  AND (t.started_at_ms IS NULL OR t.ended_at_ms IS NULL OR t.ended_at_ms >= t.started_at_ms)
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- 2. Longueur des répliques de l'examinateur (mots et secondes)
SELECT s.tache_numero,
       s.persona_version,
       COALESCE(s.client_platform, 'UNKNOWN')                                        AS plateforme,
       count(*)                                                                      AS repliques,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY t.word_count)                     AS mots_mediane,
       max(t.word_count)                                                             AS mots_max,
       round(100.0 * count(*) FILTER (WHERE t.word_count > 25) / count(*), 1)        AS pct_plus_de_25_mots,
       round((percentile_cont(0.5) WITHIN GROUP (ORDER BY t.ended_at_ms - t.started_at_ms)
              / 1000.0)::numeric, 1)                                                 AS sec_mediane,
       round(max(t.ended_at_ms - t.started_at_ms) / 1000.0, 1)                       AS sec_max
FROM realtime_sessions s
JOIN realtime_session_turns t ON t.session_id = s.id AND t.speaker = 'EXAMINER'
WHERE s.status = 'COMPLETED'
  AND s.persona_version IS NOT NULL
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- 3. Délai entre la fin de parole du candidat et la reprise de parole de l'examinateur
--    (sous-estimé du retard de transcription, identique avant et après : D-07)
SELECT s.tache_numero,
       s.persona_version,
       COALESCE(s.client_platform, 'UNKNOWN')                                        AS plateforme,
       count(*)                                                                      AS reprises_de_parole,
       round((percentile_cont(0.5) WITHIN GROUP (ORDER BY e.started_at_ms - c.ended_at_ms)
              / 1000.0)::numeric, 2)                                                 AS delai_median_sec,
       round((percentile_cont(0.9) WITHIN GROUP (ORDER BY e.started_at_ms - c.ended_at_ms)
              / 1000.0)::numeric, 2)                                                 AS delai_p90_sec,
       round(100.0 * count(*) FILTER (WHERE e.started_at_ms - c.ended_at_ms < 1500) / count(*), 1)
                                                                                     AS pct_moins_de_1_5_sec
FROM realtime_sessions s
JOIN realtime_session_turns e ON e.session_id = s.id AND e.speaker = 'EXAMINER'
JOIN realtime_session_turns c ON c.session_id = s.id AND c.seq = e.seq - 1 AND c.speaker = 'CANDIDATE'
WHERE s.status = 'COMPLETED'
  AND s.persona_version IS NOT NULL
  AND e.started_at_ms IS NOT NULL
  AND c.ended_at_ms IS NOT NULL
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- 4. Relances sur silence par session
SELECT s.tache_numero,
       s.persona_version,
       COALESCE(s.client_platform, 'UNKNOWN')                                        AS plateforme,
       count(*)                                                                      AS sessions,
       round(avg(r.relances), 2)                                                     AS relances_moyenne,
       max(r.relances)                                                               AS relances_max,
       count(*) FILTER (WHERE r.relances > 0)                                        AS sessions_avec_relance
FROM realtime_sessions s
CROSS JOIN LATERAL (
    SELECT count(*) AS relances
    FROM realtime_session_events ev
    WHERE ev.session_id = s.id AND ev.type = 'SILENCE_RELANCE'
) r
WHERE s.status = 'COMPLETED'
  AND s.persona_version IS NOT NULL
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- 5a. Répartition des causes de fin (toutes sessions closes)
SELECT s.tache_numero,
       s.persona_version,
       COALESCE(s.client_platform, 'UNKNOWN')                                        AS plateforme,
       COALESCE(s.end_cause, 'NON_DECLAREE')                                         AS cause,
       count(*)                                                                      AS sessions
FROM realtime_sessions s
WHERE s.status IN ('COMPLETED', 'FAILED')
  AND s.persona_version IS NOT NULL
GROUP BY 1, 2, 3, 4
ORDER BY 1, 2, 3, 4;

-- 5b. Durée effective comparée à la durée officielle
--     effective = fin du dernier segment (horloge client) ; serveur = ended − connected
SELECT s.tache_numero,
       s.persona_version,
       COALESCE(s.client_platform, 'UNKNOWN')                                        AS plateforme,
       count(*)                                                                      AS sessions,
       max(pt.duree_max_sec)                                                         AS duree_officielle_sec,
       round((percentile_cont(0.5) WITHIN GROUP (ORDER BY d.fin_ms) / 1000.0)::numeric, 0)
                                                                                     AS duree_client_mediane_sec,
       round((percentile_cont(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM s.ended_at - s.connected_at)))::numeric, 0)
                                                                                     AS duree_serveur_mediane_sec,
       count(*) FILTER (WHERE abs(d.fin_ms / 1000.0 - pt.duree_max_sec) <= 10)       AS sessions_a_10_sec_pres,
       round(avg(g.grace_ms) / 1000.0, 1)                                            AS grace_fin_moyenne_sec
FROM realtime_sessions s
JOIN production_tasks pt ON pt.id = s.production_task_id
CROSS JOIN LATERAL (
    SELECT max(t.ended_at_ms) AS fin_ms
    FROM realtime_session_turns t
    WHERE t.session_id = s.id
) d
LEFT JOIN LATERAL (
    SELECT sum(ev.value_ms) AS grace_ms
    FROM realtime_session_events ev
    WHERE ev.session_id = s.id AND ev.type = 'TIMEUP_GRACE'
) g ON true
WHERE s.status = 'COMPLETED'
  AND s.persona_version IS NOT NULL
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- 6. Répliques de l'examinateur contenant un terme interdit (persona v4, §3.1)
SELECT s.tache_numero,
       s.persona_version,
       COALESCE(s.client_platform, 'UNKNOWN')                                        AS plateforme,
       count(*)                                                                      AS repliques,
       count(*) FILTER (WHERE t.text ~* '(tr[eè]s bien|\mbravo\M|\mparfait|\mexcellent|\msuper\M|int[ée]ressant|beau projet)')
                                                                                     AS avec_terme_interdit,
       round(100.0 * count(*) FILTER (WHERE t.text ~* '(tr[eè]s bien|\mbravo\M|\mparfait|\mexcellent|\msuper\M|int[ée]ressant|beau projet)')
             / count(*), 1)                                                          AS pct_terme_interdit
FROM realtime_sessions s
JOIN realtime_session_turns t ON t.session_id = s.id AND t.speaker = 'EXAMINER'
WHERE s.status = 'COMPLETED'
  AND s.persona_version IS NOT NULL
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- 7. Replis asynchrones (le candidat demandait l'examinateur et s'enregistre seul)
SELECT date_trunc('week', f.created_at)::date                                       AS semaine,
       f.tache_numero,
       f.reason,
       count(*)                                                                      AS replis
FROM realtime_fallbacks f
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- 8. Reprises après coupure, avec ou sans contexte restauré
SELECT s.tache_numero,
       s.persona_version,
       COALESCE(s.client_platform, 'UNKNOWN')                                        AS plateforme,
       count(*) FILTER (WHERE ev.type = 'RESUME_WITH_HANDLE')                        AS reprises_avec_handle,
       count(*) FILTER (WHERE ev.type = 'RESUME_WITHOUT_HANDLE')                     AS reprises_sans_handle
FROM realtime_sessions s
JOIN realtime_session_events ev ON ev.session_id = s.id
WHERE s.persona_version IS NOT NULL
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- 9. Délai entre la fin de parole du candidat MESURÉE AU MICRO et la reprise de parole
--    de l'examinateur (temps de détection locale, V091, à partir du lot 2 — DECISIONS D-07).
--    Complète la requête 3 sans la remplacer : la 3 reste la référence (transcription),
--    comparable avant / après. Couverture = part des reprises de parole qui ont une mesure micro.
SELECT s.tache_numero,
       s.persona_version,
       COALESCE(s.client_platform, 'UNKNOWN')                                        AS plateforme,
       count(*)                                                                      AS reprises_de_parole,
       count(*) FILTER (WHERE c.ended_at_ms_vad IS NOT NULL)                         AS avec_mesure_micro,
       round((percentile_cont(0.5) WITHIN GROUP (ORDER BY e.started_at_ms - c.ended_at_ms_vad)
              / 1000.0)::numeric, 2)                                                 AS delai_median_micro_sec,
       round((percentile_cont(0.9) WITHIN GROUP (ORDER BY e.started_at_ms - c.ended_at_ms_vad)
              / 1000.0)::numeric, 2)                                                 AS delai_p90_micro_sec,
       round(100.0 * count(*) FILTER (WHERE e.started_at_ms - c.ended_at_ms_vad < 1500)
             / NULLIF(count(*) FILTER (WHERE c.ended_at_ms_vad IS NOT NULL), 0), 1)  AS pct_moins_de_1_5_sec_micro,
       round((percentile_cont(0.5) WITHIN GROUP (ORDER BY c.ended_at_ms_vad - c.started_at_ms_vad)
              / 1000.0)::numeric, 1)                                                 AS parole_candidat_mediane_micro_sec
FROM realtime_sessions s
JOIN realtime_session_turns e ON e.session_id = s.id AND e.speaker = 'EXAMINER'
JOIN realtime_session_turns c ON c.session_id = s.id AND c.seq = e.seq - 1 AND c.speaker = 'CANDIDATE'
WHERE s.status = 'COMPLETED'
  AND s.persona_version IS NOT NULL
  AND e.started_at_ms IS NOT NULL
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;
