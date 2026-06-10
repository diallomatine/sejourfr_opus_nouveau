-- ============================================================================
-- V684 — TCF SL B2 — lot 24 (point : « dont » complexe (dont + nom, ce dont))
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur les emplois complexes de « dont » : complément du nom
-- (sujet et COD), complément d''adjectif, « dont » partitif, « la manière
-- dont », « ce dont ». Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c018-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « L''immeuble ___ la façade vient d''être rénovée se trouve rue des Carmes, à Nantes. »',
   '« Dont » est ici **complément du nom** : la façade **de** l''immeuble → « l''immeuble dont la façade… ». Règle : quand le nom qui suit appartient à l''antécédent (relation en « de »), on emploie « dont » directement devant ce nom. « Duquel » ne s''emploie comme complément du nom qu''après une locution prépositionnelle (au sommet duquel, à l''angle duquel) — jamais seul en tête de relative. « De qui » est réservé aux personnes, or un immeuble est une chose. « Auquel » reprendrait un complément introduit par « à » (l''immeuble auquel il s''intéresse), ce qui ne correspond pas à la relation de possession exigée ici.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_dont_complexe'),

  ('33333333-c018-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Une vraie semaine de repos, c''est exactement ___ tu as besoin après ce déménagement. »',
   'La **rection du verbe** tranche : « avoir besoin **de** quelque chose ». Le pronom relatif neutre qui reprend un complément en « de » est « ce dont » → « ce dont tu as besoin ». « Ce que » reprendrait un COD (ce que tu veux) — or « avoir besoin » se construit avec « de », pas avec un COD. « Ce qui » serait sujet du verbe suivant (ce qui te ferait du bien). « Ce à quoi » reprendrait une rection en « à » (ce à quoi tu aspires), inadaptée ici.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_dont_complexe'),

  ('33333333-c018-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Le diplôme d''infirmière ___ Aïcha est si fière lui a demandé quatre ans d''efforts. »',
   '« Dont » est ici **complément de l''adjectif** : « être fier **de** quelque chose » → « le diplôme dont elle est fière ». Tout complément introduit par « de » (verbe, nom ou adjectif) se reprend par « dont ». « Que » reprendrait un COD — impossible, « être fière » n''admet pas de COD. « Duquel » ne peut pas remplacer « dont » seul : il n''apparaît qu''après une locution prépositionnelle (à la suite duquel). « Pour lequel » reprendrait un complément en « pour » (le concours pour lequel elle a révisé), sens absent de la phrase.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_dont_complexe'),

  ('33333333-c018-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Lucia parle couramment quatre langues, ___ le portugais et le wolof. »',
   'Emploi **partitif de « dont »** : il introduit un sous-ensemble d''un tout déjà cité (« quatre langues, dont deux africaines » = parmi lesquelles, y compris). C''est le seul relatif qui fonctionne ici sans verbe conjugué dans la relative. « Desquelles » ne s''emploie qu''après une locution prépositionnelle (au sujet desquelles) et exigerait une proposition complète. « Auxquelles » reprendrait un complément en « à » (les langues auxquelles elle s''intéresse) et demanderait aussi un verbe. « Que » introduirait un COD avec verbe obligatoire (les langues qu''elle étudie) — il ne peut pas précéder une simple énumération.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_dont_complexe'),

  ('33333333-c018-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « La romancière ___ Karim a traduit le premier récit sera l''invitée d''honneur du salon de Bordeaux. »',
   '« Dont » est ici **complément du nom COD** : Karim a traduit le premier récit **de** la romancière → « la romancière dont Karim a traduit le premier récit ». « Que » reprendrait directement un COD (la romancière que Karim admire) — impossible ici, car « traduire » a déjà son COD, « le premier récit ». « De laquelle » ne remplace pas « dont » en tête de relative : il est réservé aux locutions prépositionnelles (à propos de laquelle). « À qui » reprendrait un complément en « à » (la romancière à qui il a écrit), relation absente de la phrase.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_dont_complexe'),

  ('33333333-c018-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « La manière ___ Diego a désamorcé le conflit entre les deux services a impressionné la direction. »',
   'Tournure figée « **la manière dont** » : le complément est en « de » (il a désamorcé le conflit **de** cette manière) → « dont ». Après « la manière / la façon », le français standard impose « dont ». « De laquelle » est exclu en tête de relative : il ne survit qu''après une locution prépositionnelle (à partir de laquelle). « Que » supposerait un COD — or « désamorcer » a déjà le sien, « le conflit », et « la manière que » est agrammatical dans ce sens. « Où » reprendrait un complément de lieu ou de temps (l''année où, la ville où), pas une manière.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_dont_complexe'),

  ('33333333-c018-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Personne ne comprend ___ Fatou se plaint : son nouvel appartement de Lille est lumineux et très calme. »',
   'La **rection du verbe pronominal** tranche : « se plaindre **de** quelque chose » → le relatif neutre « ce dont » (ce dont Fatou se plaint). « Ce que » reprendrait un COD (ce que Fatou raconte) — or « se plaindre » se construit avec « de », jamais avec un COD direct. « Ce qui » serait sujet de la relative (ce qui dérange Fatou), rôle déjà occupé par « Fatou ». « Ce à quoi » reprendrait une rection en « à » (ce à quoi Fatou pense), qui ne correspond pas à « se plaindre de ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_dont_complexe');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c018-2100-0000-000000000001', '33333333-c018-1000-0000-000000000001', 'duquel', 'false', '1'),
  ('33333333-c018-2200-0000-000000000001', '33333333-c018-1000-0000-000000000001', 'dont', 'true', '2'),
  ('33333333-c018-2300-0000-000000000001', '33333333-c018-1000-0000-000000000001', 'auquel', 'false', '3'),
  ('33333333-c018-2400-0000-000000000001', '33333333-c018-1000-0000-000000000001', 'de qui', 'false', '4'),

  ('33333333-c018-2100-0000-000000000002', '33333333-c018-1000-0000-000000000002', 'ce dont', 'true', '1'),
  ('33333333-c018-2200-0000-000000000002', '33333333-c018-1000-0000-000000000002', 'ce que', 'false', '2'),
  ('33333333-c018-2300-0000-000000000002', '33333333-c018-1000-0000-000000000002', 'ce qui', 'false', '3'),
  ('33333333-c018-2400-0000-000000000002', '33333333-c018-1000-0000-000000000002', 'ce à quoi', 'false', '4'),

  ('33333333-c018-2100-0000-000000000003', '33333333-c018-1000-0000-000000000003', 'que', 'false', '1'),
  ('33333333-c018-2200-0000-000000000003', '33333333-c018-1000-0000-000000000003', 'duquel', 'false', '2'),
  ('33333333-c018-2300-0000-000000000003', '33333333-c018-1000-0000-000000000003', 'pour lequel', 'false', '3'),
  ('33333333-c018-2400-0000-000000000003', '33333333-c018-1000-0000-000000000003', 'dont', 'true', '4'),

  ('33333333-c018-2100-0000-000000000004', '33333333-c018-1000-0000-000000000004', 'dont', 'true', '1'),
  ('33333333-c018-2200-0000-000000000004', '33333333-c018-1000-0000-000000000004', 'desquelles', 'false', '2'),
  ('33333333-c018-2300-0000-000000000004', '33333333-c018-1000-0000-000000000004', 'auxquelles', 'false', '3'),
  ('33333333-c018-2400-0000-000000000004', '33333333-c018-1000-0000-000000000004', 'que', 'false', '4'),

  ('33333333-c018-2100-0000-000000000005', '33333333-c018-1000-0000-000000000005', 'que', 'false', '1'),
  ('33333333-c018-2200-0000-000000000005', '33333333-c018-1000-0000-000000000005', 'de laquelle', 'false', '2'),
  ('33333333-c018-2300-0000-000000000005', '33333333-c018-1000-0000-000000000005', 'dont', 'true', '3'),
  ('33333333-c018-2400-0000-000000000005', '33333333-c018-1000-0000-000000000005', 'à qui', 'false', '4'),

  ('33333333-c018-2100-0000-000000000006', '33333333-c018-1000-0000-000000000006', 'de laquelle', 'false', '1'),
  ('33333333-c018-2200-0000-000000000006', '33333333-c018-1000-0000-000000000006', 'dont', 'true', '2'),
  ('33333333-c018-2300-0000-000000000006', '33333333-c018-1000-0000-000000000006', 'que', 'false', '3'),
  ('33333333-c018-2400-0000-000000000006', '33333333-c018-1000-0000-000000000006', 'où', 'false', '4'),

  ('33333333-c018-2100-0000-000000000007', '33333333-c018-1000-0000-000000000007', 'ce que', 'false', '1'),
  ('33333333-c018-2200-0000-000000000007', '33333333-c018-1000-0000-000000000007', 'ce qui', 'false', '2'),
  ('33333333-c018-2300-0000-000000000007', '33333333-c018-1000-0000-000000000007', 'ce dont', 'true', '3'),
  ('33333333-c018-2400-0000-000000000007', '33333333-c018-1000-0000-000000000007', 'ce à quoi', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c018-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (pronoms relatifs simples/composés ou relatifs neutres « ce + relatif »,
--     tous grammaticalement existants).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : « dont » complexe — complément du nom sujet (façade),
--     « ce dont » (avoir besoin de, se plaindre de), complément d''adjectif
--     (fière de), « dont » partitif (quatre langues, dont…), complément du
--     nom COD (le récit de la romancière), « la manière dont ».
--     Aucun point de la liste interdite (les relatifs composés n''apparaissent
--     que comme distracteurs, jamais comme réponse testée).
-- [x] explanation ≥ 80 caractères, règle nommée en **gras** (complément du nom,
--     rection du verbe, dont partitif, tournure figée…) et démonte chacun des
--     3 distracteurs.
-- [x] Contextes tous différents (rénovation d''immeuble à Nantes, repos après
--     déménagement, diplôme d''infirmière, plurilinguisme, traduction littéraire
--     à Bordeaux, conflit en entreprise, appartement à Lille) ; prénoms variés
--     (Aïcha, Lucia, Karim, Diego, Fatou).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
