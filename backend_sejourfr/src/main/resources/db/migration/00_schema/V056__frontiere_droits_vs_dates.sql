-- ============================================================================
-- V056 — LA FRONTIÈRE `hg_conquetes_droits` ⇄ `hg_dates_republique` SE JUGE SUR
--        LA SUBSTANCE, PAS SUR LA FORMULATION DE LA QUESTION.
-- ----------------------------------------------------------------------------
-- Troisième itération du référentiel, mesurée. V055 avait donné une frontière à
-- ces deux notions ; le pilote v2 (mêmes 50 questions, 2026-09-11) a montré
-- qu'elle ne tranchait pas : les hésitations sont passées de 2 à **3**.
--
-- 🛑 POURQUOI V055 A ÉCHOUÉ, ET C'EST LE POINT À NE PAS REFAIRE.
-- Elle décrivait `hg_dates_republique` par la FORME de la question — « réponds
-- ici quand la question porte sur QUAND un événement a eu lieu ». Le modèle l'a
-- suivie littéralement, et « Depuis quelle année l'école publique est-elle
-- gratuite ? » est partie dans les dates (0,85) : une conquête de droit rédigée
-- comme une date. Une frontière qui se lit sur la tournure de l'énoncé classe
-- la même notion différemment selon la façon dont on la demande.
-- La frontière porte donc désormais sur la SUBSTANCE HISTORIQUE : un droit
-- est-il acquis, étendu ou reconnu ? Si oui, c'est une conquête — que la
-- question demande une année, une loi ou une personnalité.
--
-- 🛑 LES EXEMPLES FONT PARTIE DE LA RÈGLE, pas de la décoration. Ils sont lus
-- par le prompt de pré-tagging ET par le relecteur humain dans l'écran
-- d'administration : ce sont eux qui rendent la frontière opposable sur les cas
-- réels du corpus, là où une définition abstraite laisse le doute.
--
-- ⚠️ « Mai 68 » n'est volontairement PAS tranché. Le propriétaire a demandé de
-- ne pas forcer une règle sur un contenu qui relève réellement des deux : le
-- modèle garde son alternative avec une confiance plus basse, et la revue
-- humaine décide. Une frontière qui prétendrait trancher ce cas mentirait sur
-- le reste.
-- ============================================================================

UPDATE civic_notions SET description =
    'Événements, lois, réformes ou évolutions ayant conduit à l''ACQUISITION, '
    'l''EXTENSION ou la RECONNAISSANCE d''un droit social, civil ou politique — '
    'même lorsque la question demande une date, une année ou une personnalité. '
    'Exemples qui relèvent d''ici : « depuis quelle année l''école est-elle '
    'gratuite ? », la création et le développement de la Sécurité sociale, le '
    'droit de vote des femmes, l''abolition de la peine de mort.'
WHERE code = 'hg_conquetes_droits';

UPDATE civic_notions SET description =
    'Jalons chronologiques de l''histoire politique et institutionnelle de la '
    'République qui NE relèvent PAS principalement de l''acquisition d''un '
    'droit. Exemples qui relèvent d''ici : la proclamation d''une République, '
    'un changement de régime, une grande date institutionnelle. 🛑 Si '
    'l''événement fait GAGNER un droit, il relève de « hg_conquetes_droits », '
    'même si la question est posée sous forme de date.'
WHERE code = 'hg_dates_republique';
