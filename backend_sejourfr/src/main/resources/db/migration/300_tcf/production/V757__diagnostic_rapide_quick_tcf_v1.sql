-- ==========================================================================
-- V757 — Le diagnostic écrit rapide : QUICK_TCF v1 (lot L3)
--
-- `10_` §3.3 : un sujet transversal en trois mouvements -- décrire, raconter,
-- projeter/justifier -- sans jamais nommer de tâche TCF. 150 à 220 mots,
-- 8 à 10 minutes.
--
-- 🛑 UN SEUL SUJET, PAS UN POOL, et c'est un écart assumé à `10_` §3.3.
-- `uq_prod_task_diagnostic UNIQUE (diagnostic_code, diagnostic_version,
-- epreuve)` (V029) impose UNE tâche par modalité et par version. Cette unicité
-- n'est pas décorative : c'est elle qui garantit que la lecture publique (le
-- visiteur sans compte) et la création de session servent le MÊME énoncé --
-- l'invariant que `DiagnosticContentResolver` documente en tête. La relâcher
-- pour un tirage apporterait peu ici : le diagnostic rapide se fait UNE fois
-- par compte, il n'y a donc pas de « je retombe sur le même sujet », et des
-- énoncés différents rendraient les niveaux estimés moins comparables entre
-- candidats. Trois énoncés supplémentaires sont rédigés et disponibles dans
-- `docs/review_all/60_DECISIONS_IMPLEMENTATION.md` si le propriétaire veut le
-- pool : il suffira alors de remplacer cette unicité par un index sur
-- (code, version, epreuve, id). Le code serveur, lui, sait déjà tirer.
--
-- 🛑 AUCUNE TABLE `quick_diag_subject` N'EST CRÉÉE, contrairement à la lettre de
-- `50_` §5.1. Motif : le même document, deux lignes plus haut, tranche que
-- `tcf_subject` doit rester `production_tasks` -- « une tâche = un sujet dans
-- le dépôt. Ne pas séparer sans besoin avéré ». Un sujet de diagnostic rapide
-- est exactement cela : un énoncé, des bornes de mots, et une allowlist de
-- compétences observables (`diagnostic_task_skills`), c'est-à-dire les
-- `observation_targets` de la spec sous leur nom du dépôt. Une seconde table de
-- sujets aurait dupliqué le tirage, les bornes et le lien aux compétences.
-- Consigné dans `docs/review_all/60_DECISIONS_IMPLEMENTATION.md`.
--
-- 🛑 CE POOL EST EN `TCF_EE` ET N'EST PAS UNE TÂCHE DU TCF. `tache_numero`
-- est une colonne obligatoire de la table, pas une désignation : elle n'est
-- exposée à aucun front, et la consigne ne nomme jamais EE1/EE2/EE3.
-- `chk_prod_task_tcf_irn_ee_word_bounds` (V756) exempte déjà explicitement les
-- sujets diagnostiques de la table officielle des bornes.
--
-- 🛑 AUCUN SUJET ORAL. Le diagnostic rapide n'en a pas (V050, `50_` §3.2), et
-- il ne faut surtout pas en seeder un « au cas où » : c'est la présence ou
-- l'absence d'une tâche `TCF_EO` sur ce couple (code, version) qui dit au
-- serveur si le parcours a une étape orale.
--
-- 🛑 `mots_min = 100` ET NON 150, `mots_max = 300` ET NON 220 : ces colonnes
-- portent la RECEVABILITÉ (ce que le serveur accepte), pas la DEMANDE (ce que
-- la consigne réclame). `10_` §3.3 distingue explicitement les deux :
-- « Longueur demandée : 150 à 220 mots » et « Seuil de recevabilité : 100 mots.
-- En dessous, pas d'analyse. Aucun appel LLM déclenché. »
--   · seeder 150 refuserait un candidat de 130 mots, que la spec veut analyser ;
--   · le plafond est desserré à 300 : un diagnostic ne doit pas renvoyer chez
--     lui quelqu'un qui a écrit PLUS. Le but est de mesurer, et refuser un
--     texte généreux perd exactement la personne qu'on cherche à convertir.
-- La demande de 150-220 vit dans la consigne, qui est ce que le correcteur lit
-- pour juger si les éléments demandés sont accomplis.
--
-- Rejouable : `ON CONFLICT DO NOTHING`, UUID déterministes.
-- ==========================================================================

INSERT INTO production_tasks
    (id, epreuve, tache_numero, niveau_cible, titre, consigne, contexte,
     duree_max_sec, duree_min_sec, mots_min, mots_max, is_active, created_at,
     diagnostic_code, diagnostic_version, instruction_audio_url)
VALUES
    -- Sujet de référence de `10_` §3.3, mis au format du dépôt.
    ('d1a60000-0000-5000-8000-000000000101', 'TCF_EE', 3, 'B1',
     'Vous et votre quotidien',
     E'Parlez-nous un peu de vous et de votre quotidien.\n\nDans un seul texte :\n- décrivez votre lieu de vie ;\n- racontez une expérience récente qui vous a marqué ;\n- expliquez quelque chose que vous aimeriez changer dans votre quotidien, et pourquoi.\n\nÉcrivez entre 150 et 220 mots.',
     'Diagnostic écrit rapide SejourFR : une production transversale unique. Cet exercice n’est pas une tâche officielle du TCF et ne reproduit aucune de ses tâches.',
     NULL, NULL, 100, 300, true, '2026-09-10 09:00:00+02',
     'QUICK_TCF', 1, NULL)
ON CONFLICT (id) DO NOTHING;

-- Les `observation_targets` de `10_` §3.3, sous leur nom du dépôt.
--
-- Les huit capacités listées en `10_` §3.1 -- décrire · raconter · expliquer ·
-- donner son avis · justifier · développer · relier ses idées -- ont chacune
-- une compétence EXISTANTE du catalogue des 48. Aucun code n'est inventé :
-- `50_` §5.1 abandonne les codes `ee_argumenter…` de `10_` §2.3 au profit de
-- ceux-ci, et le moteur de maîtrise ne sait lire que ceux-là.
--
-- « Vocabulaire et correction de la langue » n'y figure PAS, volontairement :
-- ce n'est pas une compétence du référentiel, c'est ce que le correcteur pèse
-- pour estimer le palier de l'ensemble de la production. En faire une entrée
-- d'allowlist aurait produit une observation de compétence qui n'existe pas.
--
-- Si un pool est ouvert un jour, tous ses énoncés devront partager CETTE
-- allowlist : deux candidats tirant deux sujets différents doivent être mesurés
-- sur exactement les mêmes signaux, sans quoi le niveau estimé dépendrait du
-- tirage.
INSERT INTO diagnostic_task_skills (production_task_id, skill_id, display_order)
SELECT 'd1a60000-0000-5000-8000-000000000101'::uuid, s.id, v.ord
FROM (VALUES
    ('EE1-C7', 1),  -- décrire un lieu, une personne, une situation
    ('EE2-C5', 2),  -- raconter les actions dans l'ordre
    ('EE2-C3', 3),  -- les temps du passé, sans quoi le récit ne tient pas
    ('EE2-C7', 4),  -- exprimer une réaction, un ressenti
    ('EE3-C1', 5),  -- prendre position
    ('EE3-C2', 6),  -- justifier
    ('EE3-C3', 7),  -- développer
    ('EE1-C8', 8)   -- relier les informations en un texte cohérent
) AS v(code, ord)
JOIN skills s ON s.code = v.code
ON CONFLICT (production_task_id, skill_id) DO NOTHING;
