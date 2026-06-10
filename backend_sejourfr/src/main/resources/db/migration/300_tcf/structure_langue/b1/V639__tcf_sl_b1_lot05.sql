-- ============================================================================
-- V639 — TCF SL B1 — lot 05 (point : connecteurs logiques courants + gérondif)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B1'.
-- 10 items, tous sur les connecteurs logiques courants et le gérondif (haut B1) :
-- pourtant (opposition attente/réalité), donc (conséquence), car (cause-explication),
-- comme (cause en tête de phrase), puisque (cause partagée), grâce à (cause positive),
-- à cause de (cause négative), gérondif de manière, gérondif de simultanéité,
-- gérondif de moyen en mise en relief (« c''est en … que »).
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-b005-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « La météo annonçait un week-end radieux sur Biarritz ; ___, les plages sont restées presque désertes. »',
   'Le lien entre les deux faits est une **opposition entre l''attente et la réalité** : un beau temps annoncé laisse attendre des plages pleines, or elles sont vides → connecteur de concession « pourtant ». « Donc » et « ainsi » introduiraient une conséquence logique, exactement inverse de ce que dit la phrase (beau temps → plages désertes n''est pas une suite logique). « Car » présenterait les plages désertes comme la cause du beau temps annoncé, ce qui n''a aucun sens.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_connecteurs_logiques'),

  ('33333333-b005-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « L''ascenseur de la résidence est en panne depuis lundi ; ___, les livreurs déposent tous les colis à l''accueil. »',
   'La seconde proposition est la **conséquence logique** de la panne (plus d''ascenseur → les colis restent en bas) : connecteur de conséquence « donc ». « Pourtant » marquerait une opposition, or les deux faits vont dans le même sens. « Car » inverserait la relation en faisant du dépôt des colis la cause de la panne. « Comme » exprime bien la cause, mais il doit ouvrir la phrase en tête de subordonnée (« Comme l''ascenseur est en panne,… ») et ne peut pas s''insérer après le point-virgule.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_connecteurs_logiques'),

  ('33333333-b005-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Amadou a quitté la réunion avant la fin, ___ sa fille l''attendait devant l''école de Créteil. »',
   'La seconde proposition apporte la **cause donnée comme une explication nouvelle** du départ d''Amadou : c''est l''emploi de « car », qui se place après la proposition qu''il justifie. « Donc » ferait de l''attente de sa fille la conséquence du départ — relation inversée. « Pourtant » signalerait une opposition inexistante entre les deux faits, qui s''expliquent l''un l''autre. « Or » introduit une donnée nouvelle dans un raisonnement pour préparer une conclusion, pas une simple explication de comportement.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_connecteurs_logiques'),

  ('33333333-b005-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « ___ la médiathèque de Niort fermait exceptionnellement à midi, Mirela a réservé ses livres en ligne. »',
   'La cause est placée **en tête de phrase, avant la conséquence** : c''est la position type du « comme » causal (« Comme + cause, conséquence »). « Car » ne peut jamais ouvrir une phrase : il relie deux propositions et se place après celle qu''il explique. « Donc » introduirait une conséquence, or la fermeture exceptionnelle est la cause de la réservation, pas son résultat. « Pourtant » créerait une opposition absurde : réserver en ligne est la suite logique de la fermeture, pas son contraire.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_connecteurs_logiques'),

  ('33333333-b005-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « ___ vous avez déjà validé le module de sécurité, vous pouvez passer directement à l''atelier pratique. »',
   'La cause invoquée est un **fait déjà connu de l''interlocuteur** (c''est lui qui a validé le module) : c''est l''emploi propre de « puisque », qui présente une cause évidente ou partagée pour en tirer une autorisation. « Pourtant » opposerait les deux faits alors qu''ils s''enchaînent logiquement. « Donc » marque la conséquence : placé devant la cause, il rendrait le raisonnement incohérent. « Tandis que » exprime la simultanéité ou le contraste entre deux situations, jamais la cause.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_connecteurs_logiques'),

  ('33333333-b005-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « ___ la nouvelle rampe d''accès, monsieur Keita entre seul dans la bibliothèque de Besançon avec son fauteuil roulant. »',
   'La rampe produit un **effet positif** (l''autonomie retrouvée) : la cause à résultat favorable s''introduit avec « grâce à ». « À cause de » est réservé aux causes d''effet négatif ou gênant — contresens ici. « Malgré » exprime la concession : la phrase signifierait qu''il entre seul bien que la rampe existe, comme si elle était un obstacle. « Faute de » signale l''absence ou le manque de quelque chose (« faute de rampe, il ne pouvait pas entrer »), soit l''inverse exact de la situation décrite.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_cause_grace_a'),

  ('33333333-b005-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « La cérémonie en plein air a été déplacée dans le gymnase ___ la tempête annoncée sur le littoral vendéen. »',
   'La tempête est une **cause à effet négatif ou contraignant** (on renonce au plein air) : c''est l''emploi de « à cause de ». « Grâce à » présenterait la tempête comme une chance dont on profite — contresens. « Malgré » (concession) signifierait que la cérémonie a été déplacée bien qu''une tempête arrive, comme si la tempête aurait dû empêcher ce déplacement : illogique, puisqu''elle en est la raison. « Faute de » indique un manque (« faute de salle disponible ») et ne convient pas à un phénomène bien présent.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_cause_grace_a'),

  ('33333333-b005-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Nadia a fini par calmer son fils ___ très bas une chanson que sa propre mère lui chantait autrefois. »',
   'Le **gérondif de manière** (« en + participe présent ») indique comment Nadia a calmé son fils, les deux verbes ayant le même sujet → « en fredonnant ». « Fredonnant » seul est un participe présent : placé juste après « son fils », il se rattacherait à l''enfant (ce serait lui qui fredonne) — contresens. « Ayant fredonné » marque l''antériorité, or le chant et l''apaisement sont simultanés, l''un est le moyen de l''autre. « Pour fredonner » exprimerait le but : elle ne calme pas son fils dans l''intention de chanter.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_gerondif'),

  ('33333333-b005-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Chaque matin dans le RER B, Bohdan révise son vocabulaire ___ d''une oreille les annonces sonores de la ligne. »',
   'Les deux actions se déroulent **en même temps et avec le même sujet** : c''est le gérondif de simultanéité « en écoutant » (il révise tout en écoutant). « Écoutant » sans « en », participe présent détaché, exigerait une virgule et un registre écrit soutenu ; collé après « vocabulaire », il ne marque pas deux actions menées de front. « Ayant écouté » exprime l''antériorité : l''écoute serait terminée avant la révision, ce que dément la scène quotidienne. « Pour écouter » introduirait un but absurde — il ne révise pas afin d''entendre les annonces.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_gerondif'),

  ('33333333-b005-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « C''est ___ chaque semaine avec les commerçants du marché de Wazemmes que Yuki a appris à négocier en français. »',
   'La tournure de mise en relief « **c''est en + gérondif… que** » exprime le moyen : c''est par des discussions répétées qu''elle a progressé → « en discutant » (gérondif de moyen). « À discuter » existe après certains verbes (« passer son temps à discuter ») mais ne s''insère pas dans cette structure de moyen. « Ayant discuté » marque une antériorité accomplie, incompatible avec un procédé répété qui constitue précisément le moyen de l''apprentissage. « Discutant » (participe présent nu) ne peut pas porter la mise en relief « c''est … que ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_gerondif');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-b005-2100-0000-000000000001', '33333333-b005-1000-0000-000000000001', 'car', 'false', '1'),
  ('33333333-b005-2200-0000-000000000001', '33333333-b005-1000-0000-000000000001', 'donc', 'false', '2'),
  ('33333333-b005-2300-0000-000000000001', '33333333-b005-1000-0000-000000000001', 'pourtant', 'true', '3'),
  ('33333333-b005-2400-0000-000000000001', '33333333-b005-1000-0000-000000000001', 'ainsi', 'false', '4'),

  ('33333333-b005-2100-0000-000000000002', '33333333-b005-1000-0000-000000000002', 'donc', 'true', '1'),
  ('33333333-b005-2200-0000-000000000002', '33333333-b005-1000-0000-000000000002', 'pourtant', 'false', '2'),
  ('33333333-b005-2300-0000-000000000002', '33333333-b005-1000-0000-000000000002', 'car', 'false', '3'),
  ('33333333-b005-2400-0000-000000000002', '33333333-b005-1000-0000-000000000002', 'comme', 'false', '4'),

  ('33333333-b005-2100-0000-000000000003', '33333333-b005-1000-0000-000000000003', 'donc', 'false', '1'),
  ('33333333-b005-2200-0000-000000000003', '33333333-b005-1000-0000-000000000003', 'pourtant', 'false', '2'),
  ('33333333-b005-2300-0000-000000000003', '33333333-b005-1000-0000-000000000003', 'or', 'false', '3'),
  ('33333333-b005-2400-0000-000000000003', '33333333-b005-1000-0000-000000000003', 'car', 'true', '4'),

  ('33333333-b005-2100-0000-000000000004', '33333333-b005-1000-0000-000000000004', 'Car', 'false', '1'),
  ('33333333-b005-2200-0000-000000000004', '33333333-b005-1000-0000-000000000004', 'Comme', 'true', '2'),
  ('33333333-b005-2300-0000-000000000004', '33333333-b005-1000-0000-000000000004', 'Donc', 'false', '3'),
  ('33333333-b005-2400-0000-000000000004', '33333333-b005-1000-0000-000000000004', 'Pourtant', 'false', '4'),

  ('33333333-b005-2100-0000-000000000005', '33333333-b005-1000-0000-000000000005', 'Puisque', 'true', '1'),
  ('33333333-b005-2200-0000-000000000005', '33333333-b005-1000-0000-000000000005', 'Pourtant', 'false', '2'),
  ('33333333-b005-2300-0000-000000000005', '33333333-b005-1000-0000-000000000005', 'Donc', 'false', '3'),
  ('33333333-b005-2400-0000-000000000005', '33333333-b005-1000-0000-000000000005', 'Tandis que', 'false', '4'),

  ('33333333-b005-2100-0000-000000000006', '33333333-b005-1000-0000-000000000006', 'À cause de', 'false', '1'),
  ('33333333-b005-2200-0000-000000000006', '33333333-b005-1000-0000-000000000006', 'Malgré', 'false', '2'),
  ('33333333-b005-2300-0000-000000000006', '33333333-b005-1000-0000-000000000006', 'Grâce à', 'true', '3'),
  ('33333333-b005-2400-0000-000000000006', '33333333-b005-1000-0000-000000000006', 'Faute de', 'false', '4'),

  ('33333333-b005-2100-0000-000000000007', '33333333-b005-1000-0000-000000000007', 'grâce à', 'false', '1'),
  ('33333333-b005-2200-0000-000000000007', '33333333-b005-1000-0000-000000000007', 'à cause de', 'true', '2'),
  ('33333333-b005-2300-0000-000000000007', '33333333-b005-1000-0000-000000000007', 'malgré', 'false', '3'),
  ('33333333-b005-2400-0000-000000000007', '33333333-b005-1000-0000-000000000007', 'faute de', 'false', '4'),

  ('33333333-b005-2100-0000-000000000008', '33333333-b005-1000-0000-000000000008', 'pour fredonner', 'false', '1'),
  ('33333333-b005-2200-0000-000000000008', '33333333-b005-1000-0000-000000000008', 'ayant fredonné', 'false', '2'),
  ('33333333-b005-2300-0000-000000000008', '33333333-b005-1000-0000-000000000008', 'fredonnant', 'false', '3'),
  ('33333333-b005-2400-0000-000000000008', '33333333-b005-1000-0000-000000000008', 'en fredonnant', 'true', '4'),

  ('33333333-b005-2100-0000-000000000009', '33333333-b005-1000-0000-000000000009', 'ayant écouté', 'false', '1'),
  ('33333333-b005-2200-0000-000000000009', '33333333-b005-1000-0000-000000000009', 'en écoutant', 'true', '2'),
  ('33333333-b005-2300-0000-000000000009', '33333333-b005-1000-0000-000000000009', 'pour écouter', 'false', '3'),
  ('33333333-b005-2400-0000-000000000009', '33333333-b005-1000-0000-000000000009', 'écoutant', 'false', '4'),

  ('33333333-b005-2100-0000-00000000000a', '33333333-b005-1000-0000-00000000000a', 'en discutant', 'true', '1'),
  ('33333333-b005-2200-0000-00000000000a', '33333333-b005-1000-0000-00000000000a', 'à discuter', 'false', '2'),
  ('33333333-b005-2300-0000-00000000000a', '33333333-b005-1000-0000-00000000000a', 'ayant discuté', 'false', '3'),
  ('33333333-b005-2400-0000-00000000000a', '33333333-b005-1000-0000-00000000000a', 'discutant', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (33333333-b005-1000-…-01..0a, choices 2100/2200/2300/2400).
-- [x] 4 propositions / 1 correcte par item ; options toujours de même catégorie
--     (4 connecteurs, 4 locutions prépositionnelles, 4 formes du même verbe).
-- [x] Distribution des bonnes réponses : pos1=3, pos2=3, pos3=2, pos4=2 (équilibrée, 4 positions).
-- [x] Tous les items sur connecteurs logiques courants + gérondif, mécanismes tous différents :
--     pourtant (attente/réalité), donc (conséquence), car (explication), comme (cause en tête),
--     puisque (cause partagée), grâce à (cause positive), à cause de (cause négative),
--     gérondif de manière, gérondif de simultanéité, gérondif de moyen (« c''est en … que »).
-- [x] Aucun point interdit (pas d''imparfait/PC, relatifs, y/en/COD-COI, subjonctif,
--     comparatifs/superlatifs ni accord du participe passé).
-- [x] explanation ≥ 80 caractères, point clé en **gras**, règle nommée, 3 distracteurs démontés.
-- [x] Contextes tous différents (plage, résidence, réunion, médiathèque, formation sécurité,
--     bibliothèque accessible, cérémonie, berceuse, RER, marché) ; prénoms/villes variés
--     (Amadou, Mirela, Keita, Nadia, Bohdan, Yuki — Biarritz, Créteil, Niort, Besançon,
--     littoral vendéen, Wazemmes).
-- [x] Apostrophes SQL doublées partout ; pas de medias/passages (SVG/SSML : N/A pour SL).
-- [x] Calibrage haut B1 : distracteurs grammaticalement existants, contexte qui tranche seul.
-- ============================================================================
