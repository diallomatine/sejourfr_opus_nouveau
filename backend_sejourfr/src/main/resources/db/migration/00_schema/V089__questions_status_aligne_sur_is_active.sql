-- ============================================================================
-- V089 — Correctif de données : `questions.status` réaligné sur `is_active`
-- ----------------------------------------------------------------------------
-- Les tirages candidats exigent désormais `is_active = true` ET
-- `status = 'ACTIVE'` (QuestionRepository.SERVABLE_JPQL / SERVABLE_SQL).
--
-- Avant ce lot, PATCH /api/admin/questions/{id}/status ne basculait que
-- `is_active` : une question générée à l'unité (née `is_active = false,
-- status = 'DRAFT'`) activée par ce chemin était TIRÉE avec un statut resté
-- `DRAFT`. Le nouveau filtre l'aurait silencieusement retirée des tirages. On
-- aligne donc, une fois, toute question ACTIVE au sens de `is_active` sur
-- `status = 'ACTIVE'` : rien de ce qui est servi aujourd'hui ne cesse de l'être.
--
-- Mesuré sur la base locale le 2026-10-04 : 0 ligne concernée. Cible : la
-- production, où des questions générées à l'unité ont pu être activées ainsi.
--
-- Déterministe, borné par sa clause WHERE, idempotent (rejoué, il ne touche
-- plus rien). Les questions inactives ne sont pas touchées. Le SQL sous la
-- sentinelle est rejoué tel quel par QuestionStatusAlignementIT.
-- ============================================================================

-- @@ALIGNEMENT_STATUS@@
UPDATE questions
   SET status = 'ACTIVE'
 WHERE is_active = true
   AND status <> 'ACTIVE';
