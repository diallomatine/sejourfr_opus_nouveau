-- ==========================================================================
-- V758 — Diagnostic rapide QUICK_TCF v1 : une seule fourchette, 80 à 300 mots
--
-- Décision du propriétaire (2026-09-26). L'écran de l'écrit affichait TROIS
-- longueurs contradictoires : la consigne réclamait « entre 150 et 220 mots »,
-- une pastille disait « 100–300 mots » et l'éditeur « 100–300 mots ». La règle
-- devient : des bornes FIXES de 80 à 300 mots, affichées à un seul endroit,
-- lues sur `mots_min` / `mots_max` — la même donnée que celle qui accepte ou
-- refuse la copie (`ProductionTextBounds`, via `validateTextWordCount`).
--
--   · `mots_min` 100 → 80 : la recevabilité descend. Aucun appel LLM ne part
--     sous 80 mots, la garde de soumission restant AVANT le pipeline ;
--   · `mots_max` 300 inchangé (et déjà égal au plafond absolu
--     `max-text-words: 300`) ;
--   · la phrase « Écrivez entre 150 et 220 mots. » quitte la consigne : c'était
--     la seconde autorité sur la longueur, celle qui contredisait l'écran. Le
--     reste de l'énoncé ne bouge pas d'un caractère — l'allowlist de huit
--     compétences (V757, V878) s'appuie sur ses trois mouvements.
--
-- 🛑 CORRECTION EN PLACE DE LA VERSION 1, PAS UNE VERSION 2 (même voie que V756
-- pour INITIAL_TCF). Motifs :
--   · une version 2 rouvrirait le diagnostic à tous les comptes qui l'ont déjà
--     terminé : l'unicité est `(user, code, version)` et la version active est
--     la plus haute publiée ;
--   · elle invaliderait les brouillons invités, rangés sous `code/vN` sur
--     l'appareil, et ferait échouer leur envoi (« sujets d'une autre version ») ;
--   · l'UUID du sujet est la clé de `diagnostic_sessions` et des attempts : il
--     ne bouge pas.
-- « On versionne, on ne réécrit jamais » vaut pour les CONTRATS livrés
-- (rubrique, tool-schema, contrat de prompt, qui gardent leur v1). Un énoncé de
-- sujet est du contenu éditorial, que la console d'administration corrigerait
-- en place pour n'importe quel autre sujet.
--
-- ⚠️ Effet sur l'analyse IA, signalé et assumé : `DiagnosticAnalysisPromptBuilder`
-- transmet la consigne au correcteur (`instruction`) ; il n'y lit donc plus
-- aucune longueur demandée. Ni la rubrique ni le tool-schema du diagnostic ne
-- parlent de longueur : rien d'autre ne change dans ce qu'il reçoit.
--
-- Déterministe et idempotente : bornée par l'UUID ET le couple (code, version),
-- `replace` ne fait plus rien au second passage.
-- ==========================================================================

UPDATE production_tasks
SET mots_min = 80,
    mots_max = 300,
    consigne = replace(consigne, E'\n\nÉcrivez entre 150 et 220 mots.', '')
WHERE id = 'd1a60000-0000-5000-8000-000000000101'
  AND diagnostic_code = 'QUICK_TCF'
  AND diagnostic_version = 1;
