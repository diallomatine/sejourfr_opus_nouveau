-- ============================================================================
-- V055 — LA DÉFINITION D'UNE NOTION DEVIENT UNE DONNÉE, ET HISTOIRE-GÉO GAGNE
--        SA NOTION « FÊTES ET JOURS FÉRIÉS ».
-- ----------------------------------------------------------------------------
-- Les deux changements viennent du PILOTE de pré-tagging du 2026-09-11 (2 lots
-- × 25 sur CIV_HISTOIRE_GEO, `PROMPT_TAG_NOTION_v1`). Ils corrigent le
-- RÉFÉRENTIEL, pas le modèle : c'est la porte de revue de 50_ §6.1.3, ouverte
-- pour 5 centimes au lieu de 1 016 questions.
--
-- 🛑 CE QUE LE PILOTE A MESURÉ, ET POURQUOI ÇA JUSTIFIE UNE NOTION DE PLUS.
-- 4 des 7 questions les moins sûres (confiance 0,55 à 0,65) étaient des fêtes
-- du calendrier — 1er janvier, Toussaint, 1er mai, Noël. Aucune notion ne les
-- couvrait, donc le modèle les entassait dans `hg_langue_culture`, qui devenait
-- une POUBELLE : une notion fourre-tout ne se travaille pas, et une série
-- ciblée dessus n'apprend rien de précis au candidat.
-- Mesuré dans le corpus : ~10 questions de fêtes/jours fériés en Histoire-Géo
-- (8 CSP, 2 CR, 0 NAT). ⚠️ Au seuil de 5 par mention (`questions-min-par-notion`)
-- cette notion sera donc SERVABLE EN CSP, et `contenuInsuffisant` en CR et NAT.
-- C'est voulu et le garde-fou le gère seul : on ne crée pas la notion pour
-- remplir une couverture, on la crée pour que le tagging cesse de mentir.
-- Le 14 juillet du thème PRINCIPES (fête nationale) reste chez lui : c'est un
-- symbole de la République, pas une entrée de calendrier.
--
-- 🛑 POURQUOI `description` EST UNE COLONNE, ET PAS UNE CONSTANTE DE PROMPT.
-- La deuxième leçon du pilote est une AMBIGUÏTÉ, pas un trou : la paire la plus
-- confondue est `hg_conquetes_droits` ⇄ `hg_dates_republique` (2 hésitations sur
-- 50, confiance moyenne 0,73) — « Mai 68 », le 1er mai et la décolonisation
-- tombent entre les deux. Un libellé de 40 caractères ne tranche pas ; une
-- définition métier, si.
-- Elle vit en BASE parce qu'elle a trois lecteurs qui doivent dire la même
-- chose : le prompt de tagging, l'écran d'administration, et le relecteur
-- humain. En constante de prompt, elle aurait divergé de l'écran à la première
-- retouche — c'est le défaut le plus cher du dépôt (« une règle = une
-- autorité »).
-- 🛑 Le propriétaire a explicitement demandé de NE PAS FUSIONNER ces deux
-- notions : on mesure d'abord si une définition plus précise suffit à faire
-- tomber les hésitations. `merged_into_id` reste là si elle ne suffit pas.
-- ============================================================================

ALTER TABLE civic_notions
    ADD COLUMN description text;

COMMENT ON COLUMN civic_notions.description IS
    'La frontière de la notion, en langage métier. Lue par le prompt de '
    'pré-tagging, par l''écran d''administration et par le relecteur : une '
    'seule autorité pour les trois. Nullable — une notion sans frontière '
    'ambiguë n''en a pas besoin.';

-- ----------------------------------------------------------------------------
-- Les frontières d'Histoire-Géo. Seules les notions qui se disputent des
-- questions en reçoivent une : décrire ce qui ne pose aucun problème ajoute du
-- bruit au prompt et coûte des tokens à chaque lot.
-- ----------------------------------------------------------------------------

UPDATE civic_notions SET description =
    'Grandes dates, changements de régime, événements institutionnels et '
    'jalons historiques de la République. Réponds ici quand la question porte '
    'sur QUAND un événement a eu lieu ou sur le régime en place.'
WHERE code = 'hg_dates_republique';

UPDATE civic_notions SET description =
    'Acquisition ou extension de droits civils, politiques ou sociaux : qui '
    'obtient quel droit, et quand. Réponds ici quand la question porte sur un '
    'DROIT GAGNÉ (suffrage, droits des femmes, droits sociaux, abolitions), '
    'même si elle cite une date.'
WHERE code = 'hg_conquetes_droits';

UPDATE civic_notions SET description =
    'Langue française, francophonie, littérature, arts, gastronomie et '
    'personnalités culturelles. 🛑 N''y range PAS ce qui ne trouve pas sa '
    'place ailleurs : une fête du calendrier relève de '
    '« hg_fetes_jours_feries », un monument de « hg_patrimoine ».'
WHERE code = 'hg_langue_culture';

-- ----------------------------------------------------------------------------
-- La notion elle-même. `display_order` 10 : elle vient après les neuf
-- existantes, l'ordre du référentiel n'a pas à être renuméroté.
-- ----------------------------------------------------------------------------

INSERT INTO civic_notions (code, label, theme_code, display_order, is_active, description)
VALUES (
    'hg_fetes_jours_feries',
    'Fêtes et jours fériés en France',
    'CIV_HISTOIRE_GEO',
    10,
    true,
    'Fêtes du calendrier et jours fériés français : ce qu''ils commémorent et '
    'quand ils tombent (1er janvier, 1er mai, 8 mai, 14 juillet, 15 août, '
    '1er novembre, 11 novembre, Noël, fêtes religieuses fériées). 🛑 Le 14 '
    'juillet en tant que FÊTE NATIONALE et symbole de la République relève du '
    'thème « Principes et valeurs », pas d''ici.'
)
ON CONFLICT (code) DO NOTHING;
