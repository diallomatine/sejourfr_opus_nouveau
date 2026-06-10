-- ============================================================================
-- V679 — TCF SL B2 — lot 19 (point : articulateurs argumentatifs)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur les articulateurs argumentatifs (corrélation d''une part /
-- d''autre part, d''ailleurs vs par ailleurs, en effet vs en fait, « or » pivot
-- du raisonnement, notamment, en revanche, enfin d''énumération). Contenu
-- original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c013-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Le télétravail présente deux atouts majeurs : ___, il réduit les trajets quotidiens ; d''autre part, il facilite l''organisation familiale. »',
   'La présence de « d''autre part » dans la suite impose la **corrélation obligatoire « d''une part… d''autre part »** : ces deux articulateurs fonctionnent en paire pour distribuer deux arguments. « D''un côté » existe mais appelle son propre corrélat « de l''autre (côté) », pas « d''autre part ». « Par ailleurs » ajoute une information indépendante et ne forme jamais de paire avec « d''autre part ». « En premier lieu » s''enchaîne avec « en second lieu », pas avec « d''autre part » : les séries d''articulateurs ne se mélangent pas.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_articulateurs'),

  ('33333333-c013-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « La médiathèque de Besançon prolonge ses horaires le samedi ; ___, un atelier numérique gratuit ouvrira en septembre. »',
   'La phrase introduit une **information nouvelle, sans lien argumentatif avec la précédente** : c''est la fonction de « par ailleurs » (changement de point, ajout indépendant). « D''ailleurs » ferait l''inverse : il renforcerait l''argument précédent par une preuve supplémentaire allant dans le même sens. « En effet » introduirait une justification de la première affirmation, or l''atelier numérique ne justifie pas la prolongation des horaires. « Du reste », proche de « d''ailleurs », sert aussi à appuyer ce qui vient d''être dit, pas à ouvrir un sujet distinct.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_articulateurs'),

  ('33333333-c013-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « — Le nouveau tramway de Dijon est très silencieux. — ___, on l''entend à peine arriver. »',
   'Le second locuteur **confirme** ce que dit le premier : l''articulateur de confirmation est « en effet » (acquiescement + appui). « En fait » marquerait au contraire une **rectification** (« en réalité, c''est différent »), ce qui contredirait l''accord exprimé. « Au fait » sert à changer de sujet ou à introduire une idée qui revient à l''esprit, pas à approuver. « De fait » constate un résultat factuel et s''emploie surtout à l''écrit pour enchaîner sur sa propre affirmation, pas pour répondre à un interlocuteur dans un dialogue.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_articulateurs'),

  ('33333333-c013-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Le règlement exigeait un dépôt des candidatures avant le 15 mars ; ___, le dossier de Mariama n''est arrivé que le 22. »',
   '« Or » est l''articulateur qui introduit une **prémisse nouvelle réorientant le raisonnement** : on pose une règle, puis « or » apporte le fait qui crée le problème (le dossier est en retard) et prépare la conclusion implicite. « Ainsi » introduirait un exemple ou un aboutissement conforme à ce qui précède, alors qu''ici le fait contrarie la règle. « De même » ajouterait un élément parallèle allant dans le même sens, ce qui est contraire à la logique de la phrase. « D''ailleurs » renforcerait l''affirmation précédente par un argument supplémentaire, il ne signale pas un fait qui fait basculer le raisonnement.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_articulateurs'),

  ('33333333-c013-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « La mairie de Perpignan rénovera plusieurs bâtiments publics, ___ les trois écoles du quartier sud. »',
   '« Notamment » est l''articulateur d''**illustration partielle** : il extrait quelques exemples saillants d''un ensemble plus large (« plusieurs bâtiments », dont les trois écoles). « En l''occurrence » renvoie à un cas précis déjà identifié par le contexte (« dans le cas dont on parle »), il ne sert pas à donner des exemples d''un ensemble. « En outre » et « de surcroît » sont des articulateurs d''**addition** : ils ajouteraient un argument ou un fait nouveau, alors qu''ici les écoles ne s''ajoutent pas aux bâtiments — elles en font partie.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_articulateurs'),

  ('33333333-c013-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Ce studio proche de la gare de Rennes est minuscule ; ___, son loyer reste très abordable. »',
   '« En revanche » oppose **deux aspects différents d''une même réalité en les compensant** (petite surface, mais loyer avantageux) : c''est l''articulateur de la contrepartie. « Au contraire » exige de contredire frontalement l''énoncé précédent, le plus souvent après une négation (« il n''est pas cher, au contraire ») — or ici on ne contredit pas la petitesse du studio. « Inversement » et « à l''inverse » posent une symétrie inversée entre deux situations parallèles (deux logements, deux personnes…), pas entre deux qualités du même studio.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_articulateurs'),

  ('33333333-c013-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Pour choisir son master, Khadija a comparé trois critères : d''abord le contenu des cours, ensuite le coût de la vie, ___ les débouchés professionnels. »',
   'La série « **d''abord… ensuite… enfin** » est la chaîne canonique d''énumération : « enfin » clôt la liste ouverte par les deux premiers articulateurs. « Finalement » marque une issue après hésitation ou un résultat inattendu (« elle a finalement renoncé »), pas le dernier élément d''une énumération. « À la fin » est un repère **temporel** (à la fin d''un processus, d''un film), inadapté pour ordonner des arguments. « En définitive » introduit un bilan global après pesée des arguments, il ne peut pas s''insérer comme troisième maillon d''une liste de critères.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_articulateurs');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c013-2100-0000-000000000001', '33333333-c013-1000-0000-000000000001', 'd''un côté', 'false', '1'),
  ('33333333-c013-2200-0000-000000000001', '33333333-c013-1000-0000-000000000001', 'd''une part', 'true', '2'),
  ('33333333-c013-2300-0000-000000000001', '33333333-c013-1000-0000-000000000001', 'par ailleurs', 'false', '3'),
  ('33333333-c013-2400-0000-000000000001', '33333333-c013-1000-0000-000000000001', 'en premier lieu', 'false', '4'),

  ('33333333-c013-2100-0000-000000000002', '33333333-c013-1000-0000-000000000002', 'd''ailleurs', 'false', '1'),
  ('33333333-c013-2200-0000-000000000002', '33333333-c013-1000-0000-000000000002', 'en effet', 'false', '2'),
  ('33333333-c013-2300-0000-000000000002', '33333333-c013-1000-0000-000000000002', 'du reste', 'false', '3'),
  ('33333333-c013-2400-0000-000000000002', '33333333-c013-1000-0000-000000000002', 'par ailleurs', 'true', '4'),

  ('33333333-c013-2100-0000-000000000003', '33333333-c013-1000-0000-000000000003', 'En effet', 'true', '1'),
  ('33333333-c013-2200-0000-000000000003', '33333333-c013-1000-0000-000000000003', 'En fait', 'false', '2'),
  ('33333333-c013-2300-0000-000000000003', '33333333-c013-1000-0000-000000000003', 'Au fait', 'false', '3'),
  ('33333333-c013-2400-0000-000000000003', '33333333-c013-1000-0000-000000000003', 'De fait', 'false', '4'),

  ('33333333-c013-2100-0000-000000000004', '33333333-c013-1000-0000-000000000004', 'ainsi', 'false', '1'),
  ('33333333-c013-2200-0000-000000000004', '33333333-c013-1000-0000-000000000004', 'de même', 'false', '2'),
  ('33333333-c013-2300-0000-000000000004', '33333333-c013-1000-0000-000000000004', 'or', 'true', '3'),
  ('33333333-c013-2400-0000-000000000004', '33333333-c013-1000-0000-000000000004', 'd''ailleurs', 'false', '4'),

  ('33333333-c013-2100-0000-000000000005', '33333333-c013-1000-0000-000000000005', 'en l''occurrence', 'false', '1'),
  ('33333333-c013-2200-0000-000000000005', '33333333-c013-1000-0000-000000000005', 'notamment', 'true', '2'),
  ('33333333-c013-2300-0000-000000000005', '33333333-c013-1000-0000-000000000005', 'en outre', 'false', '3'),
  ('33333333-c013-2400-0000-000000000005', '33333333-c013-1000-0000-000000000005', 'de surcroît', 'false', '4'),

  ('33333333-c013-2100-0000-000000000006', '33333333-c013-1000-0000-000000000006', 'en revanche', 'true', '1'),
  ('33333333-c013-2200-0000-000000000006', '33333333-c013-1000-0000-000000000006', 'au contraire', 'false', '2'),
  ('33333333-c013-2300-0000-000000000006', '33333333-c013-1000-0000-000000000006', 'inversement', 'false', '3'),
  ('33333333-c013-2400-0000-000000000006', '33333333-c013-1000-0000-000000000006', 'à l''inverse', 'false', '4'),

  ('33333333-c013-2100-0000-000000000007', '33333333-c013-1000-0000-000000000007', 'finalement', 'false', '1'),
  ('33333333-c013-2200-0000-000000000007', '33333333-c013-1000-0000-000000000007', 'à la fin', 'false', '2'),
  ('33333333-c013-2300-0000-000000000007', '33333333-c013-1000-0000-000000000007', 'en définitive', 'false', '3'),
  ('33333333-c013-2400-0000-000000000007', '33333333-c013-1000-0000-000000000007', 'enfin', 'true', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c013-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 articulateurs argumentatifs existants à chaque fois).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, aucune ne dépasse 2 — max autorisé 3).
-- [x] Point unique : articulateurs argumentatifs (d''une part/d''autre part,
--     par ailleurs vs d''ailleurs, en effet vs en fait, « or » pivot, notamment,
--     en revanche, enfin d''énumération) — aucun point de la liste interdite
--     (pas de concessifs, pas de cause/conséquence, pas de comparaison complexe).
-- [x] explanation ≥ 80 caractères, nomme le mécanisme (**gras**) et démonte
--     chacun des 3 distracteurs.
-- [x] Contextes tous différents (télétravail en entreprise, médiathèque de
--     Besançon, tramway de Dijon, candidature administrative, rénovation
--     d''écoles à Perpignan, studio à Rennes, choix de master) ; prénoms variés
--     (Mariama, Khadija).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
