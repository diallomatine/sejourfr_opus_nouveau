-- ============================================================================
-- V444 — TCF CE B1 — lot 14 (support : communiqué associatif)
-- ----------------------------------------------------------------------------
-- 10 items de compréhension écrite B1. Support unique : communiqué associatif
-- (club de gym en travaux, AMAP changement de distribution, aide aux devoirs
-- appel à bénévoles, fête de quartier reportée, assemblée générale de chorale,
-- cotisation de club de foot, collecte de la ressourcerie, ateliers de
-- conversation, jardin partagé en sécheresse, ciné-club changement de salle).
-- Passages TEXTE (~60-120 mots), questions + choices (4 rows/question).
-- theme_id = 22222222-0000-0000-0000-000000000002, difficulty='B1',
-- question_type='CE'. Données déterministes, rejouables dev+recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-b00e-4000-0000-000000000001', 'TEXTE',
   'Association Tonus pour Tous — Communiqué aux adhérents

Chers adhérents,

En raison de travaux de rénovation du plancher, la salle municipale Jean-Moulin sera fermée du 2 au 27 mars. Pendant cette période, tous les cours de gymnastique sont maintenus, mais ils auront lieu au gymnase du collège Pasteur, rue des Tilleuls, aux horaires habituels. Seul le cours du samedi matin est suspendu, le gymnase étant occupé par le club de basket ; ces séances seront rattrapées en avril. Merci de votre compréhension.

Le bureau de l''association
Fatou Ndiaye, présidente',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00e-4000-0000-000000000002', 'TEXTE',
   'AMAP Les Paniers du Canal — Communiqué

Chers adhérents,

À partir du mardi 5 mai, la distribution des paniers de légumes n''aura plus lieu le jeudi soir mais le mardi, de 18 h à 20 h, toujours sous le préau de l''école Voltaire. Ce changement répond à une demande de notre maraîcher, Diego, dont la tournée a été réorganisée. Attention : les paniers non retirés avant 20 h seront offerts à l''épicerie solidaire du quartier, comme le prévoit notre règlement. Nous cherchons par ailleurs deux bénévoles pour aider à la pesée chaque semaine.

L''équipe de coordination',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00e-4000-0000-000000000003', 'TEXTE',
   'Association Coup de Pouce — Communiqué

L''association Coup de Pouce accompagne chaque année une centaine d''écoliers du quartier des Érables dans leurs devoirs. À la rentrée, douze nouveaux enfants sont inscrits sur liste d''attente, faute d''accompagnateurs disponibles. Nous lançons donc un appel : si vous pouvez consacrer une heure par semaine, le soir entre 17 h et 19 h, rejoignez notre équipe. Aucun diplôme n''est exigé, seule la régularité compte. Une réunion d''information se tiendra le jeudi 12 octobre à 18 h 30 dans notre local, 4 rue des Érables.

Pour le bureau,
Rachid Benali',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00e-4000-0000-000000000004', 'TEXTE',
   'Comité des fêtes du quartier Saint-Rémi — Communiqué

Chers habitants,

En raison des fortes pluies annoncées, la fête de quartier prévue ce samedi 6 juin sur la place du Marché est reportée au samedi 20 juin, au même endroit et aux mêmes horaires. Le repas partagé, le concert et les jeux pour enfants sont maintenus à cette nouvelle date. Les personnes qui avaient réservé une table pour le vide-greniers conservent leur emplacement sans aucune démarche supplémentaire. En cas de nouvelle annulation, les frais de réservation seraient intégralement remboursés.

Le comité des fêtes
Olena Kovalenko, secrétaire',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00e-4000-0000-000000000005', 'TEXTE',
   'Chorale La Clé des Chants — Communiqué aux choristes

Chers membres,

Notre assemblée générale annuelle aura lieu le vendredi 14 novembre à 20 h, salle des associations de Beaulieu. À l''ordre du jour : le bilan financier, le programme des concerts de printemps et surtout l''élection du nouveau bureau, notre président Wei Zhang ne souhaitant pas renouveler son mandat. Pour que les votes soient valables, la moitié des adhérents doit être présente ou représentée. Si vous ne pouvez pas venir, remettez votre pouvoir signé à un autre choriste avant la séance.

Le bureau',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00e-4000-0000-000000000006', 'TEXTE',
   'FC Les Hirondelles — Communiqué aux familles

Chers parents,

La cotisation annuelle de votre enfant (95 euros, équipement compris) doit être réglée avant le 30 septembre. Nouveauté cette saison : le paiement s''effectue uniquement en ligne, sur notre site, en une ou trois fois. Les chèques ne sont plus acceptés au secrétariat. Les familles qui rencontrent des difficultés peuvent demander une aide auprès de notre trésorière, Priya Sharma, en toute confidentialité : personne ne doit renoncer au football pour des raisons d''argent. Sans règlement au 30 septembre, l''enfant ne pourra plus participer aux matchs.

Le bureau du club',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00e-4000-0000-000000000007', 'TEXTE',
   'Ressourcerie du Vieux-Port — Communiqué

L''association organise sa grande collecte d''hiver le samedi 7 décembre, de 9 h à 17 h, sur le parking du centre social. Nous acceptons les vêtements chauds en bon état, les couvertures et les chaussures par paires. En revanche, merci de ne pas déposer de vêtements abîmés ni de jouets : nous n''avons pas la place de les stocker cette année. Les dons seront redistribués gratuitement aux personnes hébergées par le foyer Sainte-Claire. Les bénévoles qui souhaitent aider au tri peuvent s''inscrire auprès de Lucia, au local, jusqu''au 4 décembre.

Le conseil d''administration',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00e-4000-0000-000000000008', 'TEXTE',
   'Association Parlons Ensemble — Communiqué

Les inscriptions aux ateliers de conversation française de la session d''automne ouvriront le lundi 1er septembre, à la maison de quartier des Lilas. Les ateliers, gratuits, ont lieu deux fois par semaine et s''adressent aux adultes de tous niveaux. Attention : le nombre de places est limité à soixante, et les personnes déjà inscrites au printemps sont prioritaires jusqu''au 8 septembre. Passé cette date, les places restantes seront attribuées dans l''ordre d''arrivée des nouvelles demandes. Aucune inscription n''est prise par téléphone : il faut se présenter sur place avec une pièce d''identité.

Amadou Sow, coordinateur',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00e-4000-0000-000000000009', 'TEXTE',
   'Les Jardins de la Roselière — Communiqué aux jardiniers

En raison de la sécheresse et de l''arrêté préfectoral du 15 juillet, de nouvelles règles s''appliquent dès cette semaine dans notre jardin partagé. L''arrosage n''est autorisé qu''après 20 h, uniquement à l''arrosoir : l''usage du tuyau est interdit jusqu''à nouvel ordre. Les récupérateurs d''eau de pluie restent en libre accès, mais merci de n''en prélever que le strict nécessaire. Les parcelles laissées sans entretien plus de trois semaines seront proposées aux personnes sur liste d''attente, conformément au règlement.

Le collectif d''animation',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00e-4000-0000-00000000000a', 'TEXTE',
   'Ciné-club Lumières du Sud — Communiqué aux adhérents

La salle paroissiale où se tenaient nos projections n''étant plus disponible le mercredi, les séances du ciné-club sont transférées, à partir du 5 février, à l''auditorium de la médiathèque Georges-Brassens, à deux rues de l''ancienne salle. Le jour et l''horaire ne changent pas : toujours le mercredi à 20 h 30. Le tarif reste fixé à 4 euros la séance, gratuit pour les moins de douze ans. La séance du 29 janvier, dernière dans l''ancienne salle, sera suivie d''un pot amical offert par l''association.

Pour le ciné-club,
Khadija Lemrini',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-b00e-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00e-4000-0000-000000000001',
   NULL, 'B1', 'CE',
   'Qu''annonce ce communiqué aux adhérents ?',
   'Le communiqué indique que « tous les cours de gymnastique sont maintenus, mais ils auront lieu au gymnase du collège Pasteur ». La bonne réponse **reformule ce déplacement temporaire des cours** pendant les travaux. La réponse A sur-généralise : seul le cours du samedi matin est suspendu, les autres sont maintenus — piège de **sur-généralisation** à partir d''une exception. La réponse C contredit le texte : les cours gardent leurs « horaires habituels », seul le lieu change. La réponse D confond fermeture temporaire et définitive : la salle est fermée « du 2 au 27 mars » pour rénovation, une durée précise.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b00e-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00e-4000-0000-000000000002',
   NULL, 'B1', 'CE',
   'Que deviennent les paniers non retirés avant 20 h ?',
   'Le communiqué précise : « les paniers non retirés avant 20 h seront offerts à l''épicerie solidaire du quartier ». C''est un **repérage explicite de la conséquence** prévue par le règlement. La réponse A invente une conservation : rien dans le texte ne prévoit de garder les paniers, et le jeudi n''est plus jour de distribution — piège de **confusion entre l''ancien et le nouveau jour**. La réponse B confond les rôles : Diego est à l''origine du changement de jour, il ne reprend pas les paniers. La réponse C est fausse : aucun remboursement n''est mentionné, le règlement prévoit le don, pas la compensation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00e-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00e-4000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Pourquoi l''association publie-t-elle ce communiqué ?',
   'Le connecteur « donc » révèle l''intention : « faute d''accompagnateurs disponibles. Nous lançons donc un appel ». Par **inférence d''intention**, l''objet du communiqué est de recruter des bénévoles pour les enfants en attente. La réponse B inverse les rôles : ce sont les enfants qui attendent déjà sur liste, l''association cherche des adultes, pas de nouveaux élèves — piège de **confusion entre deux publics proches**. La réponse C dramatise : le manque de bénévoles crée une liste d''attente, pas une fermeture. La réponse D contredit la phrase « Aucun diplôme n''est exigé » : on ne cherche pas des enseignants diplômés.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b00e-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00e-4000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Que doivent faire les personnes qui avaient réservé une table pour le vide-greniers ?',
   'Le communiqué est explicite : elles « conservent leur emplacement sans aucune démarche supplémentaire ». C''est un **repérage explicite** — la bonne réponse reformule l''absence de démarche à accomplir. La réponse A contredit directement « sans aucune démarche supplémentaire » : aucune nouvelle réservation n''est demandée. La réponse B confond deux scénarios : le remboursement n''est prévu qu''« en cas de nouvelle annulation » — le **conditionnel « seraient remboursés »** marque une hypothèse, pas la situation actuelle. La réponse D invente un changement de place : la fête est reportée « au même endroit », chacun garde son emplacement.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00e-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00e-4000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Que se passera-t-il si moins de la moitié des adhérents participent à l''assemblée ?',
   'Le texte pose la condition : « Pour que les votes soient valables, la moitié des adhérents doit être présente ou représentée ». Par **inférence simple sur la condition** (but introduit par « pour que »), si ce seuil n''est pas atteint, les votes ne seront pas valables. La réponse A contredit le texte : Wei Zhang « ne souhaitant pas renouveler son mandat », il ne peut pas être réélu automatiquement — piège sur le **gérondif de cause**. La réponse C invente un changement de salle qui n''est mentionné nulle part. La réponse D confond les points de l''ordre du jour : le programme des concerts sera discuté, son annulation n''est pas en jeu.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b00e-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00e-4000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Qu''est-ce qui change cette saison pour les familles du club ?',
   'Le communiqué annonce : « Nouveauté cette saison : le paiement s''effectue uniquement en ligne » et « Les chèques ne sont plus acceptés ». La bonne réponse **reformule ce passage au paiement exclusivement sur Internet**. La réponse B confond le montant et une augmentation : 95 euros est le prix de la cotisation, rien n''indique une hausse — piège de **confusion entre valeur et variation**. La réponse C contredit la parenthèse « équipement compris », toujours valable. La réponse D sur-généralise une menace conditionnelle : seuls les enfants **sans règlement au 30 septembre** ne joueront plus, pas tous les enfants.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b00e-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00e-4000-0000-000000000007',
   NULL, 'B1', 'CE',
   'Quels dons la ressourcerie accepte-t-elle pour sa collecte ?',
   'Le communiqué liste les dons acceptés : « les vêtements chauds en bon état, les couvertures et les chaussures par paires ». C''est un **repérage explicite dans une énumération**. La réponse A contredit la consigne « merci de ne pas déposer […] de jouets » : même en bon état, ils sont refusés faute de place — piège du **contraste introduit par « En revanche »**. La réponse B ignore la restriction « en bon état » : les vêtements abîmés sont explicitement exclus. La réponse D déforme la condition « par paires » : une chaussure dépareillée ne respecte pas le critère demandé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00e-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00e-4000-0000-000000000008',
   NULL, 'B1', 'CE',
   'Qui est prioritaire pour obtenir une place jusqu''au 8 septembre ?',
   'Le texte précise : « les personnes déjà inscrites au printemps sont prioritaires jusqu''au 8 septembre ». Par **inférence simple reliant la priorité et la date**, seuls les anciens participants sont assurés de passer avant les autres pendant cette période. La réponse A est doublement fausse : « Aucune inscription n''est prise par téléphone » et l''ordre d''arrivée ne joue qu''**après** le 8 septembre — piège de **confusion entre deux modalités proches**. La réponse B déforme le public visé : les ateliers s''adressent « aux adultes de tous niveaux », les débutants n''ont aucune priorité. La réponse C invente un critère géographique : les Lilas désignent le lieu des ateliers, pas une condition d''accès.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b00e-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00e-4000-0000-000000000009',
   NULL, 'B1', 'CE',
   'Qu''est-ce qui est désormais interdit dans le jardin partagé ?',
   'Le communiqué est formel : « l''usage du tuyau est interdit jusqu''à nouvel ordre », seul l''arrosoir étant autorisé. C''est un **repérage explicite de l''interdiction**. La réponse A inverse la règle : arroser **après 20 h** est précisément le seul créneau autorisé — piège classique d''**inversion entre l''autorisé et l''interdit** autour de la même heure. La réponse C contredit le texte : les récupérateurs d''eau « restent en libre accès », on demande seulement la modération. La réponse D confond une procédure normale avec une interdiction : la liste d''attente sert à réattribuer les parcelles abandonnées, s''y inscrire n''est pas défendu.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00e-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00e-4000-0000-00000000000a',
   NULL, 'B1', 'CE',
   'Qu''annonce ce communiqué du ciné-club ?',
   'Le texte annonce que « les séances du ciné-club sont transférées […] à l''auditorium de la médiathèque » tandis que « Le jour et l''horaire ne changent pas » et « Le tarif reste fixé à 4 euros ». La bonne réponse **reformule ce changement de salle sans autre modification**. La réponse A confond la dernière séance **dans l''ancienne salle** (le 29 janvier) avec un arrêt définitif du ciné-club — piège sur le complément de lieu. La réponse B contredit « toujours le mercredi à 20 h 30 ». La réponse D confond maintien et hausse : le verbe « **reste fixé** » indique que 4 euros est le tarif inchangé, pas un nouveau prix.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- Q01 — travaux Tonus pour Tous (bonne réponse : position 2)
  ('11111111-b00e-2100-0000-000000000001', '11111111-b00e-1000-0000-000000000001',
   'L''annulation de tous les cours pendant le mois de mars',
   'false', '1'),
  ('11111111-b00e-2200-0000-000000000001', '11111111-b00e-1000-0000-000000000001',
   'Le déplacement des cours au gymnase du collège Pasteur',
   'true', '2'),
  ('11111111-b00e-2300-0000-000000000001', '11111111-b00e-1000-0000-000000000001',
   'Un changement d''horaires pour toutes les séances',
   'false', '3'),
  ('11111111-b00e-2400-0000-000000000001', '11111111-b00e-1000-0000-000000000001',
   'La fermeture définitive de la salle Jean-Moulin',
   'false', '4'),

  -- Q02 — paniers de l''AMAP (bonne réponse : position 4)
  ('11111111-b00e-2100-0000-000000000002', '11111111-b00e-1000-0000-000000000002',
   'Ils sont conservés jusqu''à la distribution du jeudi suivant',
   'false', '1'),
  ('11111111-b00e-2200-0000-000000000002', '11111111-b00e-1000-0000-000000000002',
   'Ils sont repris par le maraîcher Diego',
   'false', '2'),
  ('11111111-b00e-2300-0000-000000000002', '11111111-b00e-1000-0000-000000000002',
   'Ils sont remboursés aux adhérents absents',
   'false', '3'),
  ('11111111-b00e-2400-0000-000000000002', '11111111-b00e-1000-0000-000000000002',
   'Ils sont donnés à l''épicerie solidaire du quartier',
   'true', '4'),

  -- Q03 — appel de Coup de Pouce (bonne réponse : position 1)
  ('11111111-b00e-2100-0000-000000000003', '11111111-b00e-1000-0000-000000000003',
   'Pour recruter des accompagnateurs bénévoles',
   'true', '1'),
  ('11111111-b00e-2200-0000-000000000003', '11111111-b00e-1000-0000-000000000003',
   'Pour inscrire de nouveaux écoliers à l''aide aux devoirs',
   'false', '2'),
  ('11111111-b00e-2300-0000-000000000003', '11111111-b00e-1000-0000-000000000003',
   'Pour annoncer la fermeture prochaine de l''association',
   'false', '3'),
  ('11111111-b00e-2400-0000-000000000003', '11111111-b00e-1000-0000-000000000003',
   'Pour recruter des enseignants diplômés',
   'false', '4'),

  -- Q04 — vide-greniers reporté (bonne réponse : position 3)
  ('11111111-b00e-2100-0000-000000000004', '11111111-b00e-1000-0000-000000000004',
   'Réserver de nouveau un emplacement avant le 20 juin',
   'false', '1'),
  ('11111111-b00e-2200-0000-000000000004', '11111111-b00e-1000-0000-000000000004',
   'Demander le remboursement de leurs frais de réservation',
   'false', '2'),
  ('11111111-b00e-2300-0000-000000000004', '11111111-b00e-1000-0000-000000000004',
   'Rien : leur emplacement est conservé pour la nouvelle date',
   'true', '3'),
  ('11111111-b00e-2400-0000-000000000004', '11111111-b00e-1000-0000-000000000004',
   'Choisir un autre emplacement sur la place du Marché',
   'false', '4'),

  -- Q05 — quorum de la chorale (bonne réponse : position 2)
  ('11111111-b00e-2100-0000-000000000005', '11111111-b00e-1000-0000-000000000005',
   'Wei Zhang sera automatiquement réélu président',
   'false', '1'),
  ('11111111-b00e-2200-0000-000000000005', '11111111-b00e-1000-0000-000000000005',
   'Les votes de l''assemblée ne seront pas valables',
   'true', '2'),
  ('11111111-b00e-2300-0000-000000000005', '11111111-b00e-1000-0000-000000000005',
   'L''assemblée sera déplacée dans une autre salle',
   'false', '3'),
  ('11111111-b00e-2400-0000-000000000005', '11111111-b00e-1000-0000-000000000005',
   'Les concerts de printemps seront annulés',
   'false', '4'),

  -- Q06 — cotisation FC Les Hirondelles (bonne réponse : position 1)
  ('11111111-b00e-2100-0000-000000000006', '11111111-b00e-1000-0000-000000000006',
   'La cotisation se règle désormais uniquement sur Internet',
   'true', '1'),
  ('11111111-b00e-2200-0000-000000000006', '11111111-b00e-1000-0000-000000000006',
   'Le montant de la cotisation augmente de 95 euros',
   'false', '2'),
  ('11111111-b00e-2300-0000-000000000006', '11111111-b00e-1000-0000-000000000006',
   'L''équipement n''est plus compris dans la cotisation',
   'false', '3'),
  ('11111111-b00e-2400-0000-000000000006', '11111111-b00e-1000-0000-000000000006',
   'Les enfants ne participeront plus aux matchs cette saison',
   'false', '4'),

  -- Q07 — collecte de la ressourcerie (bonne réponse : position 3)
  ('11111111-b00e-2100-0000-000000000007', '11111111-b00e-1000-0000-000000000007',
   'Des jouets en bon état pour les enfants du foyer',
   'false', '1'),
  ('11111111-b00e-2200-0000-000000000007', '11111111-b00e-1000-0000-000000000007',
   'Tous les vêtements, même abîmés',
   'false', '2'),
  ('11111111-b00e-2300-0000-000000000007', '11111111-b00e-1000-0000-000000000007',
   'Des vêtements chauds en bon état',
   'true', '3'),
  ('11111111-b00e-2400-0000-000000000007', '11111111-b00e-1000-0000-000000000007',
   'Des chaussures, même dépareillées',
   'false', '4'),

  -- Q08 — ateliers Parlons Ensemble (bonne réponse : position 4)
  ('11111111-b00e-2100-0000-000000000008', '11111111-b00e-1000-0000-000000000008',
   'Les soixante premières personnes qui téléphonent',
   'false', '1'),
  ('11111111-b00e-2200-0000-000000000008', '11111111-b00e-1000-0000-000000000008',
   'Les adultes débutants en français',
   'false', '2'),
  ('11111111-b00e-2300-0000-000000000008', '11111111-b00e-1000-0000-000000000008',
   'Les habitants du quartier des Lilas',
   'false', '3'),
  ('11111111-b00e-2400-0000-000000000008', '11111111-b00e-1000-0000-000000000008',
   'Les personnes qui suivaient déjà les ateliers au printemps',
   'true', '4'),

  -- Q09 — règles du jardin partagé (bonne réponse : position 2)
  ('11111111-b00e-2100-0000-000000000009', '11111111-b00e-1000-0000-000000000009',
   'Arroser sa parcelle après 20 h',
   'false', '1'),
  ('11111111-b00e-2200-0000-000000000009', '11111111-b00e-1000-0000-000000000009',
   'Arroser avec un tuyau',
   'true', '2'),
  ('11111111-b00e-2300-0000-000000000009', '11111111-b00e-1000-0000-000000000009',
   'Prendre de l''eau dans les récupérateurs de pluie',
   'false', '3'),
  ('11111111-b00e-2400-0000-000000000009', '11111111-b00e-1000-0000-000000000009',
   'S''inscrire sur la liste d''attente des parcelles',
   'false', '4'),

  -- Q10 — déménagement du ciné-club (bonne réponse : position 3)
  ('11111111-b00e-2100-0000-00000000000a', '11111111-b00e-1000-0000-00000000000a',
   'L''arrêt définitif des séances après le 29 janvier',
   'false', '1'),
  ('11111111-b00e-2200-0000-00000000000a', '11111111-b00e-1000-0000-00000000000a',
   'Le passage des séances du mercredi au jeudi',
   'false', '2'),
  ('11111111-b00e-2300-0000-00000000000a', '11111111-b00e-1000-0000-00000000000a',
   'Le changement de salle, sans modification du jour ni du tarif',
   'true', '3'),
  ('11111111-b00e-2400-0000-00000000000a', '11111111-b00e-1000-0000-00000000000a',
   'Une augmentation du tarif à 4 euros la séance',
   'false', '4');

-- ============================================================================
-- CHECKLIST — contrôles passés
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (11111111-b00e-1000/4000/21..2400-…-NN, NN=01..0a).
-- [x] Support unique : communiqué associatif (10 associations et situations
--     toutes différentes : club de gym en travaux, AMAP changement de jour,
--     aide aux devoirs appel à bénévoles, fête de quartier reportée, assemblée
--     générale de chorale, cotisation de club de foot, collecte de la
--     ressourcerie, ateliers de conversation, jardin partagé en sécheresse,
--     ciné-club changement de salle). Aucun support réservé à un autre lot.
-- [x] Passages TEXTE ~60-120 mots, mise en forme communiqué (en-tête de
--     l''association, corps, signature du bureau/responsable), media_id NULL.
-- [x] 4 propositions / 1 correcte par item. Distribution des bonnes réponses :
--     pos1:2, pos2:3, pos3:3, pos4:2 (max 3 par position, 4 positions utilisées).
-- [x] competence_code : ce_reperage_explicite x4, ce_inference_intention x3,
--     ce_reformulation x3.
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3 distracteurs
--     expliqués, point clé en **gras**, mécanisme linguistique nommé
--     (sur-généralisation, conditionnel d''hypothèse, gérondif de cause,
--     contraste « en revanche », inversion autorisé/interdit, valeur vs
--     variation…).
-- [x] Prénoms variés (Fatou, Diego, Rachid, Olena, Wei, Priya, Lucia, Amadou,
--     Khadija). Pas de SVG ni SSML dans ce lot (supports textuels uniquement).
-- [x] Apostrophes SQL doublées partout, contenu 100% original, items autonomes.
-- ============================================================================
