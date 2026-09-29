-- ============================================================================
-- V436 — TCF CE B1 — lot 06 (support : annonce détaillée)
-- ----------------------------------------------------------------------------
-- 10 items de compréhension écrite B1. Support unique : annonce détaillée
-- (location de studio, vente de vélo électrique, recherche de baby-sitter,
-- cours de guitare, don de chatons, recherche de colocataire, recrutement
-- saisonnier, vente d''électroménager, tandem linguistique, avis de chat
-- perdu). Passages TEXTE (~60-120 mots), questions + choices (4 rows/question).
-- theme_id = 22222222-0000-0000-0000-000000000002, difficulty='B1',
-- question_type='CE'. Données déterministes, rejouables dev+recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-b006-4000-0000-000000000001', 'TEXTE',
   'À LOUER — STUDIO MEUBLÉ, QUARTIER GARE

Studio de 24 m² au troisième étage sans ascenseur, entièrement meublé : lit, bureau, kitchenette équipée. Loyer : 540 euros charges comprises (eau, chauffage, internet). Libre à partir du 1er septembre. Idéal pour étudiant ou jeune travailleur. Les animaux ne sont pas acceptés. Visites uniquement le samedi matin, sur rendez-vous. Dossier demandé pour la location : pièce d''identité, justificatif de revenus ou garant. Contact : Lucia, de préférence par SMS après 18 h.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b006-4000-0000-000000000002', 'TEXTE',
   'VENDS VÉLO ÉLECTRIQUE — TRÈS BON ÉTAT

Vends vélo électrique de ville acheté il y a deux ans, 1 200 km au compteur. Batterie changée le mois dernier (facture fournie) : autonomie de 70 km. Quelques rayures sur le cadre, sans conséquence sur le fonctionnement. Prix : 650 euros, légèrement négociable. Casque et antivol offerts. Je vends car je déménage dans une ville où tout se fait à pied. Essai possible en bas de chez moi, en semaine entre 17 h et 19 h. Paiement en espèces uniquement.

Rachid — réponse par téléphone ou message.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b006-4000-0000-000000000003', 'TEXTE',
   'RECHERCHE BABY-SITTER — RENTRÉE DE SEPTEMBRE

Famille du quartier Saint-Michel cherche une personne sérieuse pour aller chercher nos deux enfants (5 et 8 ans) à l''école à 16 h 30, les lundis, mardis et jeudis, puis les garder à la maison jusqu''à 19 h : goûter, devoirs pour l''aîné, jeux. Pas de ménage ni de cuisine à prévoir, en dehors du goûter. Rémunération : 12 euros de l''heure, déclarés. Une première expérience avec les enfants est indispensable. Le mercredi n''est pas concerné : les enfants sont chez leur grand-mère.

Écrire à Olena en précisant vos disponibilités.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b006-4000-0000-000000000004', 'TEXTE',
   'COURS DE GUITARE TOUS NIVEAUX

Guitariste depuis quinze ans et diplômé d''une école de musique, je propose des cours pour adultes et adolescents, débutants ou confirmés. Première séance d''essai gratuite et sans engagement. Cours de 45 minutes à mon domicile, quartier des Halles : 25 euros. Je peux aussi me déplacer chez vous pour 5 euros de plus. Pas besoin d''acheter un instrument tout de suite : je prête une guitare pendant les trois premiers mois. Possibilité de cours en espagnol.

Diego — réponses le soir uniquement.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b006-4000-0000-000000000005', 'TEXTE',
   'DONNE TROIS CHATONS CONTRE BONS SOINS

Notre chatte a eu une portée de trois chatons (deux mâles roux, une femelle tigrée), nés le 2 avril. Ils pourront quitter la maison à la mi-juin, après leur première visite chez le vétérinaire, qui est à notre charge. Nous les donnons gratuitement, mais nous voulons être sûrs qu''ils seront bien traités : nous demandons donc à rencontrer les futurs adoptants à la maison avant de nous décider. Priorité aux personnes disposant d''un jardin ou d''un grand appartement. Pas de réservation par simple message.

Priya, quartier Bellevue.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b006-4000-0000-000000000006', 'TEXTE',
   'CHERCHE COLOCATAIRE — APPARTEMENT CENTRE-VILLE

Je cherche une personne pour partager mon appartement de 70 m² près de la place du Marché, à partir du 1er octobre. Chambre libre de 14 m², lumineuse, avec placard. Loyer : 380 euros par mois, charges et internet compris. Cuisine et salon partagés ; chacun fait ses courses, mais nous cuisinons souvent ensemble le week-end. Je travaille à l''hôpital avec des horaires décalés : je cherche donc quelqu''un de calme, non-fumeur. Les étudiants sont les bienvenus s''ils peuvent présenter un garant. Visites possibles en soirée cette semaine.

Wei',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b006-4000-0000-000000000007', 'TEXTE',
   'RECRUTE ÉQUIPIERS POUR LA CUEILLETTE DES POMMES

La ferme des Quatre Vents, à 15 km de Tours, recrute dix personnes pour la cueillette, du 8 septembre au 17 octobre. Travail en extérieur du lundi au vendredi, de 8 h à 16 h, avec une heure de pause. Aucune expérience exigée : une formation est assurée le premier jour. Salaire : SMIC horaire, plus un panier repas. Bonne condition physique nécessaire (port de caisses). Logement non fourni, mais covoiturage organisé depuis le centre de Tours.

Envoyer nom et numéro de téléphone à Amadou avant le 25 août.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b006-4000-0000-000000000008', 'TEXTE',
   'VENDS ÉLECTROMÉNAGER — CAUSE DÉPART À L''ÉTRANGER

Je quitte la France fin juillet et je vends : un lave-linge de 2023 encore sous garantie (180 euros), un réfrigérateur deux portes en parfait état (120 euros) et un four à micro-ondes (25 euros). Le lave-linge et le réfrigérateur sont à retirer sur place, au deuxième étage : prévoyez d''être deux, je ne peux pas aider au transport. Pour le micro-ondes, je peux le déposer en centre-ville. Prix fermes. Première personne arrivée, première servie. Photos supplémentaires sur demande.

Fatou — disponible le week-end pour les retraits.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b006-4000-0000-000000000009', 'TEXTE',
   'ÉCHANGE CONVERSATION : ESPAGNOL CONTRE FRANÇAIS

Bonjour ! Je m''appelle Mariana, je suis arrivée d''Argentine il y a six mois et je prépare un examen de français. Je propose un échange simple et gratuit : une heure de conversation en espagnol contre une heure de conversation en français, une ou deux fois par semaine, dans un café du centre ou au parc s''il fait beau. Je cherche une personne patiente, qui parle français couramment ; pas besoin de connaître l''espagnol parfaitement, mon objectif est justement d''aider un vrai débutant. Pas de cours payants : ce n''est pas une annonce professionnelle. Me contacter le soir.

Mariana',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b006-4000-0000-00000000000a', 'TEXTE',
   'PERDU CHAT GRIS — RÉCOMPENSE

Notre chat Plume, gris aux yeux verts, a disparu depuis dimanche soir dans le quartier de la Fontaine. Il porte un collier bleu avec une médaille à nos coordonnées. Plume est craintif : ne courez pas après lui, il se cacherait. Si vous le voyez, notez l''endroit et appelez-nous immédiatement, à toute heure. Merci de vérifier vos garages et vos caves : il a pu s''y enfermer. Une récompense de 50 euros est offerte à la personne qui nous permettra de le retrouver.

Marek et sa famille — joignables par téléphone.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-b006-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b006-4000-0000-000000000001',
   NULL, 'B1', 'CE',
   'Comment peut-on visiter le studio de Lucia ?',
   'L''annonce précise : « Visites uniquement le samedi matin, sur rendez-vous ». C''est un **repérage explicite** qui combine le jour ET la prise de rendez-vous. La réponse A est fausse car « sur rendez-vous » exclut de se présenter directement, même le bon jour. La réponse C inverse la consigne de contact : Lucia demande un SMS « après 18 h », pas un appel avant 18 h. La réponse D confond deux informations proches : le dossier (pièce d''identité, revenus, garant) est demandé pour la **location**, pas pour obtenir une visite — piège classique de confusion entre deux procédures voisines du texte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b006-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b006-4000-0000-000000000002',
   NULL, 'B1', 'CE',
   'Pourquoi Rachid vend-il son vélo électrique ?',
   'Rachid écrit : « Je vends **car** je déménage dans une ville où tout se fait à pied ». La conjonction « car » introduit explicitement la **cause de la vente** : il n''aura plus besoin du vélo. La réponse A contredit le texte : la batterie a été « changée le mois dernier » et offre 70 km d''autonomie. La réponse B exagère un détail : les rayures sont « sans conséquence sur le fonctionnement », le vélo roule parfaitement. La réponse C invente une intention absente de l''annonce : rien n''indique l''achat d''un nouveau modèle — piège de la cause plausible mais non écrite.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b006-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b006-4000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Quelles tâches la baby-sitter devra-t-elle assurer ?',
   'L''annonce énumère les tâches après l''école : « goûter, devoirs pour l''aîné, jeux ». C''est un **repérage explicite de l''énumération**. La réponse B est fausse : « Pas de ménage ni de cuisine à prévoir, en dehors du goûter » — la préparation du dîner est donc exclue. La réponse C contredit la même phrase : aucun ménage n''est demandé. La réponse D confond les jours travaillés (« les lundis, mardis et jeudis ») avec le jour explicitement exclu : « Le mercredi n''est pas concerné : les enfants sont chez leur grand-mère » — piège de **confusion entre deux informations temporelles proches**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b006-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b006-4000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Quel est le prix d''un cours de 45 minutes au domicile de l''élève ?',
   'Il faut relier deux informations du texte : le cours coûte « 25 euros » chez Diego et « je peux aussi me déplacer chez vous pour 5 euros **de plus** ». Par **inférence simple (addition de deux données)** : 25 + 5 = 30 euros. La réponse A confond le supplément de déplacement avec le prix total du cours. La réponse B est le tarif au domicile de Diego, quartier des Halles, pas chez l''élève. La réponse D inverse l''opération : la locution « de plus » indique que les 5 euros s''**ajoutent** au tarif de base, ils ne s''en déduisent pas — piège sur le sens de l''expression de quantité.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b006-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b006-4000-0000-000000000005',
   NULL, 'B1', 'CE',
   'À quelle condition Priya accepte-t-elle de donner un chaton ?',
   'Priya écrit : « nous demandons donc à rencontrer les futurs adoptants à la maison avant de nous décider ». La bonne réponse **reformule cette condition** : faire d''abord connaissance chez elle. La réponse A contredit le texte : la visite chez le vétérinaire « est à notre charge », l''adoptant ne paie rien. La réponse C contredit la dernière consigne : « Pas de réservation par simple message ». La réponse D déforme une information : Bellevue est simplement le quartier de Priya ; la priorité annoncée porte sur le **jardin ou le grand appartement**, pas sur le lieu d''habitation — piège du détail détourné de son rôle.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b006-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b006-4000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Pourquoi Wei précise-t-il ses horaires de travail dans l''annonce ?',
   'Wei écrit : « Je travaille à l''hôpital avec des horaires décalés : je cherche **donc** quelqu''un de calme ». Le connecteur « donc » relie explicitement la cause (horaires décalés, sommeil en journée) à l''exigence — c''est une **inférence d''intention** guidée par le lien logique. La réponse A contredit le texte : « Visites possibles en soirée cette semaine », pas seulement le week-end. La réponse B invente un lien : le loyer de 380 euros est justifié par les charges et internet compris, jamais par les horaires. La réponse C est une déduction non écrite : des horaires décalés ne signifient pas qu''il est rarement présent — piège de la sur-interprétation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b006-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b006-4000-0000-000000000007',
   NULL, 'B1', 'CE',
   'Que prévoit la ferme pour les personnes qui n''ont jamais fait de cueillette ?',
   'L''annonce indique : « Aucune expérience exigée : une formation est assurée le premier jour ». C''est un **repérage explicite** — les deux-points relient directement l''absence d''expérience à la solution proposée. La réponse A déforme la rémunération : le salaire est le « SMIC horaire, plus un panier repas », le panier ne fait pas un salaire supérieur au SMIC. La réponse B contredit « Logement non fourni » : seul un **covoiturage** est organisé depuis Tours, pas un hébergement. La réponse D invente un aménagement : les horaires (8 h - 16 h, une heure de pause) sont les mêmes pour tous — piège de l''avantage plausible mais absent du texte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b006-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b006-4000-0000-000000000008',
   NULL, 'B1', 'CE',
   'Que doit prévoir la personne qui achète le réfrigérateur ?',
   'Fatou précise : « à retirer sur place, au deuxième étage : prévoyez d''être deux, je ne peux pas aider au transport ». La bonne réponse **reformule cette consigne** : venir accompagné pour descendre l''appareil soi-même. La réponse A contredit la disponibilité annoncée : Fatou est « disponible le week-end pour les retraits », pas en semaine. La réponse C contredit la mention « Prix fermes » : aucune négociation n''est possible. La réponse D confond deux informations voisines : le dépôt en centre-ville ne concerne **que le micro-ondes**, pas le réfrigérateur — piège classique de confusion entre deux objets proches du texte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b006-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b006-4000-0000-000000000009',
   NULL, 'B1', 'CE',
   'Quel type de partenaire Mariana recherche-t-elle ?',
   'Il faut relier deux critères du texte : « une personne patiente, qui parle français couramment » et « pas besoin de connaître l''espagnol parfaitement, mon objectif est justement d''aider un vrai débutant ». La bonne réponse combine ces deux conditions — **inférence simple par mise en relation de deux informations**. La réponse A contredit la fin de l''annonce : « Pas de cours payants : ce n''est pas une annonce professionnelle ». La réponse B inverse les rôles : c''est **Mariana** qui prépare un examen de français, pas le partenaire recherché. La réponse C contredit directement le texte : un débutant en espagnol est le bienvenu, la maîtrise n''est pas exigée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b006-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b006-4000-0000-00000000000a',
   NULL, 'B1', 'CE',
   'Que doit faire une personne qui aperçoit le chat Plume ?',
   'L''annonce demande : « Si vous le voyez, notez l''endroit et appelez-nous immédiatement, à toute heure ». La bonne réponse **reformule cette double consigne** : noter le lieu puis téléphoner sans attendre. La réponse B contredit l''avertissement : « ne courez pas après lui, il se cacherait » — le **conditionnel** exprime la conséquence à éviter si on le poursuit. La réponse C invente une procédure : aucune adresse n''est donnée, la famille est « joignable par téléphone » uniquement. La réponse D contredit « immédiatement, à toute heure » : l''adverbe exclut tout délai — piège sur la **valeur temporelle** de la consigne.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- Q01 — studio de Lucia (bonne réponse : position 2)
  ('11111111-b006-2100-0000-000000000001', '11111111-b006-1000-0000-000000000001',
   'En se présentant directement le samedi matin',
   'false', '1'),
  ('11111111-b006-2200-0000-000000000001', '11111111-b006-1000-0000-000000000001',
   'En prenant rendez-vous pour un samedi matin',
   'true', '2'),
  ('11111111-b006-2300-0000-000000000001', '11111111-b006-1000-0000-000000000001',
   'En téléphonant à Lucia avant 18 h',
   'false', '3'),
  ('11111111-b006-2400-0000-000000000001', '11111111-b006-1000-0000-000000000001',
   'En envoyant d''abord un dossier complet par SMS',
   'false', '4'),

  -- Q02 — vélo de Rachid (bonne réponse : position 4)
  ('11111111-b006-2100-0000-000000000002', '11111111-b006-1000-0000-000000000002',
   'Parce que la batterie ne fonctionne plus',
   'false', '1'),
  ('11111111-b006-2200-0000-000000000002', '11111111-b006-1000-0000-000000000002',
   'Parce que le cadre est trop abîmé pour rouler',
   'false', '2'),
  ('11111111-b006-2300-0000-000000000002', '11111111-b006-1000-0000-000000000002',
   'Parce qu''il veut acheter un modèle plus récent',
   'false', '3'),
  ('11111111-b006-2400-0000-000000000002', '11111111-b006-1000-0000-000000000002',
   'Parce qu''il part vivre dans une ville où il se déplacera à pied',
   'true', '4'),

  -- Q03 — baby-sitter d''Olena (bonne réponse : position 1)
  ('11111111-b006-2100-0000-000000000003', '11111111-b006-1000-0000-000000000003',
   'Le goûter, les devoirs de l''aîné et les jeux après l''école',
   'true', '1'),
  ('11111111-b006-2200-0000-000000000003', '11111111-b006-1000-0000-000000000003',
   'La préparation du dîner des enfants',
   'false', '2'),
  ('11111111-b006-2300-0000-000000000003', '11111111-b006-1000-0000-000000000003',
   'Le ménage de la maison en fin de journée',
   'false', '3'),
  ('11111111-b006-2400-0000-000000000003', '11111111-b006-1000-0000-000000000003',
   'La garde des enfants le mercredi après-midi',
   'false', '4'),

  -- Q04 — cours de guitare de Diego (bonne réponse : position 3)
  ('11111111-b006-2100-0000-000000000004', '11111111-b006-1000-0000-000000000004',
   '5 euros',
   'false', '1'),
  ('11111111-b006-2200-0000-000000000004', '11111111-b006-1000-0000-000000000004',
   '25 euros',
   'false', '2'),
  ('11111111-b006-2300-0000-000000000004', '11111111-b006-1000-0000-000000000004',
   '30 euros',
   'true', '3'),
  ('11111111-b006-2400-0000-000000000004', '11111111-b006-1000-0000-000000000004',
   '20 euros',
   'false', '4'),

  -- Q05 — chatons de Priya (bonne réponse : position 2)
  ('11111111-b006-2100-0000-000000000005', '11111111-b006-1000-0000-000000000005',
   'Payer la première visite chez le vétérinaire',
   'false', '1'),
  ('11111111-b006-2200-0000-000000000005', '11111111-b006-1000-0000-000000000005',
   'Rencontrer d''abord Priya à son domicile',
   'true', '2'),
  ('11111111-b006-2300-0000-000000000005', '11111111-b006-1000-0000-000000000005',
   'Réserver rapidement un chaton par message',
   'false', '3'),
  ('11111111-b006-2400-0000-000000000005', '11111111-b006-1000-0000-000000000005',
   'Habiter dans le quartier Bellevue',
   'false', '4'),

  -- Q06 — colocataire de Wei (bonne réponse : position 4)
  ('11111111-b006-2100-0000-000000000006', '11111111-b006-1000-0000-000000000006',
   'Pour prévenir qu''il ne fera visiter que le week-end',
   'false', '1'),
  ('11111111-b006-2200-0000-000000000006', '11111111-b006-1000-0000-000000000006',
   'Pour justifier le montant du loyer demandé',
   'false', '2'),
  ('11111111-b006-2300-0000-000000000006', '11111111-b006-1000-0000-000000000006',
   'Pour annoncer qu''il est rarement présent dans l''appartement',
   'false', '3'),
  ('11111111-b006-2400-0000-000000000006', '11111111-b006-1000-0000-000000000006',
   'Pour expliquer pourquoi il cherche quelqu''un de calme',
   'true', '4'),

  -- Q07 — cueillette de la ferme des Quatre Vents (bonne réponse : position 3)
  ('11111111-b006-2100-0000-000000000007', '11111111-b006-1000-0000-000000000007',
   'Un salaire supérieur au SMIC',
   'false', '1'),
  ('11111111-b006-2200-0000-000000000007', '11111111-b006-1000-0000-000000000007',
   'Un hébergement gratuit à la ferme',
   'false', '2'),
  ('11111111-b006-2300-0000-000000000007', '11111111-b006-1000-0000-000000000007',
   'Une formation assurée le premier jour',
   'true', '3'),
  ('11111111-b006-2400-0000-000000000007', '11111111-b006-1000-0000-000000000007',
   'Des journées de travail plus courtes',
   'false', '4'),

  -- Q08 — électroménager de Fatou (bonne réponse : position 2)
  ('11111111-b006-2100-0000-000000000008', '11111111-b006-1000-0000-000000000008',
   'Venir en semaine, avant la fin du mois de juillet',
   'false', '1'),
  ('11111111-b006-2200-0000-000000000008', '11111111-b006-1000-0000-000000000008',
   'Venir accompagnée pour descendre l''appareil du deuxième étage',
   'true', '2'),
  ('11111111-b006-2300-0000-000000000008', '11111111-b006-1000-0000-000000000008',
   'Négocier le prix directement sur place',
   'false', '3'),
  ('11111111-b006-2400-0000-000000000008', '11111111-b006-1000-0000-000000000008',
   'Demander à Fatou une livraison en centre-ville',
   'false', '4'),

  -- Q09 — tandem linguistique de Mariana (bonne réponse : position 4)
  ('11111111-b006-2100-0000-000000000009', '11111111-b006-1000-0000-000000000009',
   'Un professeur de français pour des cours payants',
   'false', '1'),
  ('11111111-b006-2200-0000-000000000009', '11111111-b006-1000-0000-000000000009',
   'Une personne qui prépare le même examen qu''elle',
   'false', '2'),
  ('11111111-b006-2300-0000-000000000009', '11111111-b006-1000-0000-000000000009',
   'Quelqu''un qui parle déjà très bien l''espagnol',
   'false', '3'),
  ('11111111-b006-2400-0000-000000000009', '11111111-b006-1000-0000-000000000009',
   'Un francophone patient, même débutant en espagnol',
   'true', '4'),

  -- Q10 — chat perdu de Marek (bonne réponse : position 1)
  ('11111111-b006-2100-0000-00000000000a', '11111111-b006-1000-0000-00000000000a',
   'Noter où il se trouve et téléphoner aussitôt à la famille',
   'true', '1'),
  ('11111111-b006-2200-0000-00000000000a', '11111111-b006-1000-0000-00000000000a',
   'Courir vers lui pour l''attraper rapidement',
   'false', '2'),
  ('11111111-b006-2300-0000-00000000000a', '11111111-b006-1000-0000-00000000000a',
   'Le rapporter directement au domicile de Marek',
   'false', '3'),
  ('11111111-b006-2400-0000-00000000000a', '11111111-b006-1000-0000-00000000000a',
   'Attendre le lendemain matin pour signaler l''endroit',
   'false', '4');

-- ============================================================================
-- CHECKLIST — contrôles passés
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (11111111-b006-1000/4000/21..2400-…-NN, NN=01..0a).
-- [x] Support unique : annonce détaillée (10 annonceurs et situations toutes
--     différentes : location de studio, vente de vélo électrique, recherche
--     de baby-sitter, cours de guitare, don de chatons, recherche de
--     colocataire, recrutement saisonnier cueillette, vente d''électroménager,
--     tandem linguistique, avis de chat perdu). Aucun support interdit
--     (pas d''e-mail, lettre, article, forum, note, programme, FAQ, etc.).
-- [x] Passages TEXTE ~60-120 mots, mise en forme annonce (titre en capitales,
--     corps détaillé, contact/signature), media_id NULL.
-- [x] 4 propositions / 1 correcte par item. Distribution des bonnes réponses :
--     pos1:2, pos2:3, pos3:2, pos4:3 (max 3 par position, 4 positions utilisées).
-- [x] competence_code : ce_reperage_explicite x4, ce_inference_intention x3,
--     ce_reformulation x3.
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3 distracteurs
--     expliqués, point clé en **gras**, mécanisme linguistique nommé (cause
--     introduite par « car », connecteur « donc », addition de deux données,
--     conditionnel de conséquence, confusion d''informations proches…).
-- [x] Pas de SVG ni SSML dans ce lot (supports textuels uniquement) — rien à
--     équilibrer.
-- [x] Apostrophes SQL doublées partout, contenu 100% original, items autonomes.
-- ============================================================================
