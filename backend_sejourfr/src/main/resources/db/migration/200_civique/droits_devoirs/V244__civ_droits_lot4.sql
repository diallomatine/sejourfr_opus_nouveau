-- ============================================================================
-- V244 — Civique : Droits et devoirs (lot 4)
-- ----------------------------------------------------------------------------
-- Questions + choix. Filtre: 11111111-0000-0000-0000-000000000003 .
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('f3000002-0000-0000-0000-00000000005b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Je suis perçu comme suspect par un policier qui me parle agressivement. Quels droits ?',
   'Restez calme et coopérez. Vous pouvez demander la raison du contrôle, l''identité du policier. Si vous estimez avoir été maltraité, vous pouvez déposer plainte auprès du procureur ou saisir l''IGPN.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000005c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'MISE_SITUATION',
   'On me propose un travail très bien payé mais sans contrat ni déclaration. Que penser ?',
   'C''est du travail dissimulé, illégal en France. Vous n''aurez aucun droit social (assurance maladie, retraite, chômage), et vous risquez des sanctions. Refuser et signaler aux autorités.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000005d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel article de la DDHC consacre le principe de la souveraineté nationale ?',
   'L''article 3 de la DDHC énonce : ''Le principe de toute souveraineté réside essentiellement dans la Nation''. Réaffirmé par l''article 3 de la Constitution actuelle.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000005e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Le préambule de la Constitution de 1946 fait-il partie du bloc de constitutionnalité ?',
   'Oui. Depuis la décision du Conseil constitutionnel de 1971, le préambule de 1946 (qui reconnaît notamment les droits sociaux) fait partie du bloc de constitutionnalité et a valeur constitutionnelle.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000005f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel principe constitutionnel garantit l''égalité entre hommes et femmes pour les mandats électoraux ?',
   'La parité, inscrite dans la Constitution depuis 1999 (article 1er), impose aux partis politiques de favoriser l''égal accès des femmes et des hommes aux mandats électifs et aux fonctions électives.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000060', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que prévoit la Convention européenne des droits de l''homme (CEDH) ?',
   'La CEDH, adoptée en 1950 par le Conseil de l''Europe, garantit les droits fondamentaux (vie, liberté, procès équitable, etc.). La France l''a ratifiée en 1974. La Cour européenne des droits de l''homme (Strasbourg) la fait respecter.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000061', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Où siège la Cour européenne des droits de l''homme (CEDH) ?',
   'La Cour européenne des droits de l''homme siège à Strasbourg. C''est l''organe juridictionnel du Conseil de l''Europe (à distinguer de la Cour de justice de l''UE située à Luxembourg).',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000062', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Un citoyen français peut-il saisir directement la Cour européenne des droits de l''homme ?',
   'Oui, après épuisement des voies de recours internes (jugement définitif en France), un citoyen peut saisir la CEDH s''il estime que ses droits garantis par la Convention ont été violés.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000063', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'La Cour pénale internationale (CPI) juge-t-elle des actes commis en France ?',
   'La CPI, basée à La Haye, juge les génocides, crimes contre l''humanité, crimes de guerre et crimes d''agression, subsidiairement aux juridictions nationales. La France l''a reconnue en 2002.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000064', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'L''imprescriptibilité des crimes contre l''humanité est-elle reconnue en droit français ?',
   'Oui. Les crimes contre l''humanité (loi de 1964) sont imprescriptibles : il n''existe aucun délai au-delà duquel leurs auteurs ne pourraient plus être poursuivis.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000065', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel principe interdit toute forme de torture, même en temps de guerre ?',
   'L''interdiction absolue de la torture (article 3 CEDH, Convention contre la torture de 1984). Aucune circonstance, même l''état de guerre ou de nécessité, ne peut justifier la torture.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000066', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qu''est-ce que le ''droit international humanitaire'' ?',
   'Le droit international humanitaire (Conventions de Genève de 1949) régit la conduite des conflits armés : protection des civils, des prisonniers, des blessés, et restriction des méthodes de guerre.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000067', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel est l''apport de la Charte des droits fondamentaux de l''Union européenne ?',
   'La Charte des droits fondamentaux de l''UE (2000, valeur juridique depuis le traité de Lisbonne en 2009) consacre l''ensemble des droits applicables dans l''UE : dignité, libertés, égalité, solidarité, citoyenneté, justice.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000068', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Le mariage entre personnes du même sexe a-t-il une valeur dans toute l''Union européenne ?',
   'Pas obligatoirement. Chaque État membre choisit s''il légalise le mariage homosexuel. Toutefois, la libre circulation des couples mariés (et leur reconnaissance) progresse.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000069', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qu''est-ce que le ''noyau dur'' des droits intangibles selon la CEDH ?',
   'Certains droits sont absolus, indispensables : droit à la vie, interdiction de la torture, interdiction de l''esclavage, principe de légalité pénale. Aucune dérogation n''est possible, même en cas de guerre.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000006a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que prévoit le ''principe de proportionnalité'' en droit pénal ?',
   'Le principe de proportionnalité impose que la peine prononcée soit en rapport avec la gravité de l''infraction commise. Une amende excessive ou une prison disproportionnée peut être censurée.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000006b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle juridiction européenne assure l''application uniforme du droit de l''UE ?',
   'La Cour de justice de l''Union européenne (CJUE), basée à Luxembourg, assure l''application uniforme du droit de l''UE et tranche les questions soumises par les juges nationaux.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000006c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'La hiérarchie des normes françaises place la Constitution en tête. Quels sont les rangs suivants ?',
   'Hiérarchie : 1. Constitution (et bloc de constitutionnalité), 2. Traités internationaux et droit européen, 3. Lois, 4. Règlements (décrets, arrêtés), 5. Conventions collectives, jurisprudence.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000006d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que représente le principe ''non bis in idem'' en droit pénal ?',
   'Le principe ''non bis in idem'' (article 4 du Protocole 7 CEDH) interdit de juger ou de punir une personne deux fois pour les mêmes faits. Une exception : la découverte de faits nouveaux après jugement.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000006e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Le droit à un recours effectif est-il garanti ?',
   'Oui. Article 13 de la CEDH : toute personne dont les droits ont été violés a droit à un recours effectif devant une instance nationale. Garantie aussi par la Constitution et le droit européen.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000006f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que désigne la notion d''''état d''urgence'' en droit français ?',
   'L''état d''urgence (loi de 1955, révisée depuis) permet au gouvernement de prendre des mesures restrictives des libertés en cas de péril imminent (terrorisme, catastrophe). Il a notamment été déclaré après 2015.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000070', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel principe limite la durée maximum d''une garde à vue ?',
   'La garde à vue est limitée à 24 heures, prolongeable à 48 heures par le procureur (et jusqu''à 96 heures pour terrorisme/criminalité organisée). La personne doit être informée de ses droits.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000071', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel droit fondamental protège le secret médical ?',
   'Le secret médical (article 4 du Code de déontologie médicale, article 226-13 du Code pénal) protège la confidentialité des informations transmises au médecin. Sa violation est un délit.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000072', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'L''avortement (IVG) est-il aujourd''hui un droit constitutionnel ?',
   'Oui. La révision constitutionnelle du 8 mars 2024 a inscrit dans la Constitution la ''liberté garantie à la femme d''avoir recours à une interruption volontaire de grossesse''.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000073', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que protège la loi sur la presse de 1881 ?',
   'La loi du 29 juillet 1881 garantit la liberté de la presse et encadre les abus (diffamation, injure, provocation à la haine, fausse nouvelle). C''est le texte fondateur de la liberté d''expression médiatique.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000074', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que désigne l''expression ''État de droit'' en philosophie politique ?',
   'Un État de droit est un État soumis à la loi, où les pouvoirs publics doivent respecter les règles juridiques et où les droits des citoyens sont garantis et contrôlés par des juges indépendants.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000075', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel article de la CEDH protège le droit à un procès équitable ?',
   'L''article 6 de la CEDH garantit le droit à un procès équitable : tribunal indépendant et impartial, jugement public dans un délai raisonnable, présomption d''innocence, droits de la défense.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000076', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Comment la France peut-elle être condamnée par la Cour européenne des droits de l''homme ?',
   'Sur recours individuel d''une personne ayant épuisé ses voies de recours internes, la CEDH peut déclarer que la France a violé la Convention. La France doit alors modifier sa pratique et indemniser le requérant.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000077', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quels sont les principaux ''devoirs constitutionnels'' du citoyen ?',
   'La Constitution implique des devoirs : respect de la loi, paiement des contributions communes, défense de la patrie (article 35), préservation de l''environnement (Charte de 2004), respect de la dignité humaine.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000078', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'L''objection de conscience militaire est-elle reconnue en France ?',
   'Le statut d''objecteur de conscience a existé en France jusqu''à la suspension du service militaire en 1997. Avec la professionnalisation, la question ne se pose plus de la même manière. Aujourd''hui, le service est volontaire.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000079', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que signifie le principe d''''égalité réelle'' ?',
   'L''égalité réelle (par opposition à l''égalité formelle) vise à corriger les inégalités de fait, par des politiques publiques (éducation prioritaire, parité, accessibilité handicap, discrimination positive).',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000007a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'L''arrêt ''Marbury vs Madison'' équivalent français reconnaissant la portée constitutionnelle des principes ?',
   'La décision du Conseil constitutionnel du 16 juillet 1971 (''liberté d''association'') a reconnu la valeur constitutionnelle du préambule de 1946, donc des droits sociaux et de la DDHC. Équivalent français d''un contrôle de constitutionnalité renforcé.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000007b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que prévoit le principe de subsidiarité dans l''Union européenne ?',
   'Le principe de subsidiarité (article 5 TUE) impose que l''UE n''agisse, dans les domaines non exclusifs, que si l''action est plus efficace au niveau européen qu''au niveau national.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000007c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'L''apatridie est-elle protégée par le droit français ?',
   'Oui. La Convention de 1954 et le droit français protègent les apatrides (personnes sans nationalité). L''OFPRA peut leur accorder un statut leur permettant de séjourner et de circuler.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000007d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Après avoir épuisé tous les recours en France, je veux saisir la Cour européenne des droits de l''homme. Quelle est la démarche ?',
   'Vous adressez une requête (formulaire officiel) à la CEDH à Strasbourg, dans les 4 mois suivant la décision interne définitive. Pas d''avocat obligatoire pour la requête initiale. La cour examine la recevabilité.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000007e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Une mesure de l''état d''urgence me prive d''une liberté (assignation à résidence) et je la conteste. Quel recours ?',
   'Les mesures de l''état d''urgence peuvent être contestées devant le juge administratif (référé-liberté si l''urgence est grande, ou recours classique). Le juge contrôle leur proportionnalité.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000007f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Je découvre qu''une loi en vigueur depuis 5 ans porte atteinte à un de mes droits constitutionnels. Quels recours ?',
   'Vous pouvez soulever une Question prioritaire de constitutionnalité (QPC) lors d''une procédure judiciaire ou administrative. Le Conseil constitutionnel peut alors abroger la loi pour l''avenir.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000080', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Mon employeur privé me discrimine en raison de mes convictions religieuses. Que faire ?',
   'Vous pouvez saisir le Défenseur des droits, les prud''hommes (juridiction du travail), ou déposer plainte pénale. La discrimination religieuse au travail est un délit. La charge de la preuve est partagée.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000081', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Je suis témoin d''un crime contre l''humanité commis à l''étranger par une personne résidant maintenant en France. Que prévoit le droit ?',
   'La France peut juger les auteurs de crimes contre l''humanité, même commis à l''étranger, en vertu de la compétence universelle. Vous pouvez signaler les faits au procureur, qui pourra ouvrir une enquête.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000082', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Le gouvernement adopte une mesure restrictive par ordonnance. Quels contrôles existent ?',
   'Les ordonnances peuvent être contestées devant le Conseil d''État. Elles doivent ensuite être ratifiées par le Parlement, sinon elles perdent leur valeur. Le Conseil constitutionnel peut aussi être saisi de la loi de ratification.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000083', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Une chaîne de télévision refuse de diffuser un débat contradictoire pendant une campagne. Quel recours ?',
   'L''ARCOM (ex-CSA) veille au respect du pluralisme dans l''audiovisuel. Vous pouvez la saisir d''un signalement. Elle peut sanctionner les chaînes manquant à leurs obligations.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000084', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Une donnée personnelle me concernant est conservée illégalement par une entreprise. Que faire ?',
   'Saisir la CNIL (Commission nationale de l''informatique et des libertés). Elle peut sanctionner l''entreprise. Vous pouvez aussi faire valoir vos droits RGPD : effacement, portabilité, opposition.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000085', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Un journal publie un article diffamatoire sur moi. Quels recours pénaux et civils ?',
   'Diffamation = imputation d''un fait portant atteinte à l''honneur. Vous pouvez déposer plainte pénale (délai de prescription très court : 3 mois) et engager une action civile pour obtenir réparation et un droit de réponse.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000086', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'L''administration prend une décision qui me touche sans m''avoir entendu. Quel recours ?',
   'Le ''principe du contradictoire'' impose souvent un échange préalable. Si une décision individuelle défavorable est prise sans procédure contradictoire requise, vous pouvez demander son annulation au tribunal administratif.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-0000000000a1', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel principe interdit toute peine cruelle ou dégradante ?',
   'Le principe de dignité humaine et l''article 3 de la Convention européenne des droits de l''homme prohibent absolument les traitements cruels, inhumains ou dégradants, même en temps de guerre.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-0000000000a2', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que le ''droit à l''oubli'' numérique ?',
   'Le droit à l''oubli permet à une personne de demander le déréférencement (suppression des résultats de recherche) ou l''effacement de données personnelles obsolètes ou inappropriées, garanti par le RGPD.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-0000000000a3', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que protège le RGPD (Règlement général sur la protection des données) ?',
   'Le RGPD, en vigueur depuis 2018, protège les données personnelles des citoyens européens. Il impose aux entreprises consentement, transparence, sécurité, et accorde plusieurs droits (accès, rectification, effacement).',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-0000000000a4', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le viol est-il un crime en droit français ?',
   'Oui. Le viol est un crime (article 222-23 du Code pénal), puni de 15 ans de réclusion criminelle, plus selon les circonstances aggravantes (mineur, autorité, etc.).',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-0000000000a5', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'L''incitation à la haine raciale est-elle réprimée en France ?',
   'Oui. La provocation à la haine, la discrimination ou la violence en raison de l''origine, de la religion ou du sexe est un délit puni par la loi de 1881 sur la presse (1 an de prison, 45 000 EUR d''amende).',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-0000000000a6', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel principe protège chacun de la ''rétroactivité'' d''une loi pénale plus sévère ?',
   'Le principe de non-rétroactivité de la loi pénale plus sévère (article 8 DDHC, article 112-1 du Code pénal) interdit d''appliquer une loi nouvelle plus dure aux faits commis avant son entrée en vigueur.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL);

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('2294d30d-a8c3-4949-bfc0-48f01089a087', 'f3000002-0000-0000-0000-00000000005b',
   'Coopérer, demander le motif, déposer plainte si abus',
   'true', '0'),

  ('46c84281-d674-4c1d-a949-fcd95eedf1c0', 'f3000002-0000-0000-0000-00000000005b',
   'Frapper le policier',
   'false', '1'),

  ('91e619b9-c7cf-417e-a041-587bc7dfeb7f', 'f3000002-0000-0000-0000-00000000005b',
   'Crier dans la rue',
   'false', '2'),

  ('7350a91e-9b6e-4f4d-896f-59c12c9d7d73', 'f3000002-0000-0000-0000-00000000005b',
   'Mentir sur mon identité',
   'false', '3'),

  ('b5635a05-7297-4dfa-9705-91c4c4360383', 'f3000002-0000-0000-0000-00000000005c',
   'Refuser et signaler : c''est du travail dissimulé illégal',
   'true', '0'),

  ('9f4897f2-794b-4e5b-b992-4cc8074e33d7', 'f3000002-0000-0000-0000-00000000005c',
   'Accepter, c''est plus avantageux',
   'false', '1'),

  ('bf85ed20-a693-4109-b902-2d53590f9a17', 'f3000002-0000-0000-0000-00000000005c',
   'Négocier un meilleur taux',
   'false', '2'),

  ('9192e4b5-9fc4-44d5-9536-d9235a5a4689', 'f3000002-0000-0000-0000-00000000005c',
   'Accepter mais en informer le pape',
   'false', '3'),

  ('4cdf05d3-292b-44fc-a72d-a3c13da6a0fd', 'f3000002-0000-0000-0000-00000000005d',
   'L''article 3 de la DDHC',
   'true', '0'),

  ('8f2b1db6-d791-4488-8791-dd79accaa26e', 'f3000002-0000-0000-0000-00000000005d',
   'L''article 1er',
   'false', '1'),

  ('d0e46e7f-e04f-407d-bb22-fe82aa49a689', 'f3000002-0000-0000-0000-00000000005d',
   'L''article 17',
   'false', '2'),

  ('de1b5e8e-8734-4b19-a825-ae04708f0d4f', 'f3000002-0000-0000-0000-00000000005d',
   'L''article 89',
   'false', '3'),

  ('6049e22f-b672-401c-bc06-0b0525d59013', 'f3000002-0000-0000-0000-00000000005e',
   'Oui, depuis 1971',
   'true', '0'),

  ('763ac3ae-716f-4b94-b5ca-f5fe72e984f9', 'f3000002-0000-0000-0000-00000000005e',
   'Non, c''est un texte historique sans portée',
   'false', '1'),

  ('24ae8894-8811-44fc-ae3c-ea4cb2fd46c0', 'f3000002-0000-0000-0000-00000000005e',
   'Uniquement les économistes',
   'false', '2'),

  ('24df9b34-adc7-4b50-a9b7-a7428ebe7864', 'f3000002-0000-0000-0000-00000000005e',
   'Uniquement les ouvriers',
   'false', '3'),

  ('0b9866c3-f1cb-4eea-85e8-3f1db0bef8e3', 'f3000002-0000-0000-0000-00000000005f',
   'La parité (Constitution depuis 1999)',
   'true', '0'),

  ('e4063f2e-3db6-49a9-ac11-572a1368679d', 'f3000002-0000-0000-0000-00000000005f',
   'L''unicité du suffrage',
   'false', '1'),

  ('3494ec44-b63e-443a-a2e6-610cf568d018', 'f3000002-0000-0000-0000-00000000005f',
   'La proportionnelle intégrale',
   'false', '2'),

  ('5e48f380-6e6e-454f-ad72-4d1f052ddd45', 'f3000002-0000-0000-0000-00000000005f',
   'Aucun principe particulier',
   'false', '3'),

  ('35248871-7866-428c-8d4d-a3fa5d3fa715', 'f3000002-0000-0000-0000-000000000060',
   'Les droits fondamentaux des Européens, contrôlés par la CourEDH',
   'true', '0'),

  ('111a47dc-f855-45e5-99ed-41301fa93c84', 'f3000002-0000-0000-0000-000000000060',
   'Une convention sur le commerce',
   'false', '1'),

  ('d269f769-953b-490d-88fd-88dbe1c59471', 'f3000002-0000-0000-0000-000000000060',
   'Un accord sur la pêche',
   'false', '2'),

  ('b21f6f0d-412b-46e2-abc4-40e117a7e979', 'f3000002-0000-0000-0000-000000000060',
   'Un traité militaire',
   'false', '3'),

  ('1fd673ef-f548-409f-bf36-874390f9f754', 'f3000002-0000-0000-0000-000000000061',
   'À Strasbourg',
   'true', '0'),

  ('c3c5475a-6eb0-4d61-942c-7b2755a23401', 'f3000002-0000-0000-0000-000000000061',
   'À Bruxelles',
   'false', '1'),

  ('6d5371c4-5264-4fd0-8d39-cf62d2ca500f', 'f3000002-0000-0000-0000-000000000061',
   'À Paris',
   'false', '2'),

  ('98956df1-a941-4454-9d08-7458182b852f', 'f3000002-0000-0000-0000-000000000061',
   'À Luxembourg',
   'false', '3'),

  ('abfae311-c29d-48d4-8446-52aa21244751', 'f3000002-0000-0000-0000-000000000062',
   'Oui, après épuisement des recours internes',
   'true', '0'),

  ('d46f0e53-9b37-4d50-a1c3-61aff33fda55', 'f3000002-0000-0000-0000-000000000062',
   'Non, jamais directement',
   'false', '1'),

  ('d984c444-a505-4740-8556-457d4a5c680e', 'f3000002-0000-0000-0000-000000000062',
   'Uniquement les associations peuvent',
   'false', '2'),

  ('1e56d11a-ad2e-463b-b12b-794db3270e05', 'f3000002-0000-0000-0000-000000000062',
   'Uniquement avec accord du président',
   'false', '3'),

  ('c078206c-f940-4ed5-a521-14c9dd62f0d8', 'f3000002-0000-0000-0000-000000000063',
   'Subsidiairement, pour les crimes les plus graves',
   'true', '0'),

  ('90247829-b7bc-4fb3-9afd-79b08458e15c', 'f3000002-0000-0000-0000-000000000063',
   'Pour tous les délits français',
   'false', '1'),

  ('eba63d54-494a-4daa-a4bc-2aa3ba107551', 'f3000002-0000-0000-0000-000000000063',
   'Jamais',
   'false', '2'),

  ('1bbd3d2e-dba2-4d45-8f63-9c1038ce6c0e', 'f3000002-0000-0000-0000-000000000063',
   'Uniquement les crimes économiques',
   'false', '3'),

  ('c2119def-717a-44fe-9b2f-bffe3b3f2abe', 'f3000002-0000-0000-0000-000000000064',
   'Oui, ces crimes sont imprescriptibles',
   'true', '0'),

  ('8d0a1234-5400-4e26-b064-a203050d977c', 'f3000002-0000-0000-0000-000000000064',
   'Non, ils suivent la prescription normale',
   'false', '1'),

  ('c0e7b1a3-5000-4da6-9d18-27b2766a93ea', 'f3000002-0000-0000-0000-000000000064',
   'Uniquement pour les Français',
   'false', '2'),

  ('f755c27b-3f16-4786-93c6-8857de4da7f6', 'f3000002-0000-0000-0000-000000000064',
   'Uniquement pour la Seconde Guerre mondiale',
   'false', '3'),

  ('1e0c6bd6-413e-45af-9f81-97ad4ed27329', 'f3000002-0000-0000-0000-000000000065',
   'L''interdiction absolue (article 3 CEDH)',
   'true', '0'),

  ('bb92dfb0-396f-4597-aa52-619f425272d5', 'f3000002-0000-0000-0000-000000000065',
   'L''interdiction conditionnelle',
   'false', '1'),

  ('32121f0d-af94-4c97-98d7-ae9cf6967187', 'f3000002-0000-0000-0000-000000000065',
   'L''interdiction uniquement civile',
   'false', '2'),

  ('b3c77659-3e32-49be-a156-3a5cf0c79b20', 'f3000002-0000-0000-0000-000000000065',
   'L''interdiction uniquement pour les Français',
   'false', '3'),

  ('fe68085b-17ad-472e-8c38-68f5e765cc2e', 'f3000002-0000-0000-0000-000000000066',
   'Les règles applicables en cas de conflit armé',
   'true', '0'),

  ('2b4598aa-3e94-41dd-b28c-f52ebe3c1b7a', 'f3000002-0000-0000-0000-000000000066',
   'Le droit du commerce mondial',
   'false', '1'),

  ('fe33625c-f436-4ee6-a63b-02793183a59a', 'f3000002-0000-0000-0000-000000000066',
   'Le droit de l''environnement',
   'false', '2'),

  ('a0bed97c-f4b7-4660-b18b-47f5f3a7538c', 'f3000002-0000-0000-0000-000000000066',
   'Le droit familial international',
   'false', '3'),

  ('cd7828ab-3b5e-47c4-8019-d6437d4b7128', 'f3000002-0000-0000-0000-000000000067',
   'Elle consacre les droits fondamentaux applicables dans l''UE',
   'true', '0'),

  ('dd8872e1-f3a1-4f9e-bfa4-ce74640cc1d7', 'f3000002-0000-0000-0000-000000000067',
   'Elle réglemente le commerce européen',
   'false', '1'),

  ('a0cfe319-3b10-4ba7-ad21-5abf0911e130', 'f3000002-0000-0000-0000-000000000067',
   'Elle définit la PAC',
   'false', '2'),

  ('0eb25bec-2dea-4f2f-9395-98234fd46ce5', 'f3000002-0000-0000-0000-000000000067',
   'Elle organise les élections européennes',
   'false', '3'),

  ('671d2532-bb9e-4db9-bae4-c7b7c594036e', 'f3000002-0000-0000-0000-000000000068',
   'Cela dépend de chaque État membre',
   'true', '0'),

  ('65e00904-1a41-4ba1-a0b8-c8a723d9d7f8', 'f3000002-0000-0000-0000-000000000068',
   'Oui, c''est uniforme dans toute l''UE',
   'false', '1'),

  ('0c1fccda-3848-41ef-b77d-1507e87640d8', 'f3000002-0000-0000-0000-000000000068',
   'Non, c''est interdit partout en Europe',
   'false', '2'),

  ('3bb51c76-2f1f-4f69-b627-ce9031349d5a', 'f3000002-0000-0000-0000-000000000068',
   'Uniquement dans les pays scandinaves',
   'false', '3'),

  ('ceab40bb-dd8d-40a6-b354-ceb920602152', 'f3000002-0000-0000-0000-000000000069',
   'Vie, interdiction de torture, d''esclavage, légalité pénale',
   'true', '0'),

  ('6efc5502-7be0-47ea-abe1-3a66f283ae4b', 'f3000002-0000-0000-0000-000000000069',
   'Tous les droits sont intangibles',
   'false', '1'),

  ('b9c9540a-29ea-4f06-b74a-7800c3c9ecb4', 'f3000002-0000-0000-0000-000000000069',
   'Aucun droit n''est intangible',
   'false', '2'),

  ('016c575e-c791-4c04-a795-61dc491053f2', 'f3000002-0000-0000-0000-000000000069',
   'Uniquement le droit à la propriété',
   'false', '3'),

  ('b98db838-6eaa-48d1-a0d6-4e54fa494105', 'f3000002-0000-0000-0000-00000000006a',
   'La peine doit être proportionnée à la gravité de l''infraction',
   'true', '0'),

  ('7f2d7c98-b794-485a-bf1d-71bdfbd7b8e6', 'f3000002-0000-0000-0000-00000000006a',
   'Toutes les peines sont égales',
   'false', '1'),

  ('e833467d-6a14-4d34-80bb-be16056bc03b', 'f3000002-0000-0000-0000-00000000006a',
   'Les peines sont fixées au hasard',
   'false', '2'),

  ('8d4f6736-e8a4-41a7-9a42-fb891cac1cb7', 'f3000002-0000-0000-0000-00000000006a',
   'Les peines sont décidées par le maire',
   'false', '3'),

  ('08298a31-4b58-4d1a-bfaf-54968438b1de', 'f3000002-0000-0000-0000-00000000006b',
   'La Cour de justice de l''UE (Luxembourg)',
   'true', '0'),

  ('ff4ee38f-3e41-46a3-911b-e313d4aaa071', 'f3000002-0000-0000-0000-00000000006b',
   'La Cour européenne des droits de l''homme',
   'false', '1'),

  ('e430903e-5d9d-420b-bf7b-adcacd3663b5', 'f3000002-0000-0000-0000-00000000006b',
   'La Cour pénale internationale',
   'false', '2'),

  ('61efaf1b-5509-4a97-8156-2ef593550105', 'f3000002-0000-0000-0000-00000000006b',
   'Le Conseil constitutionnel français',
   'false', '3'),

  ('ff42746f-3fda-442c-abc1-790e90ec0e0f', 'f3000002-0000-0000-0000-00000000006c',
   'Constitution > traités > lois > règlements',
   'true', '0'),

  ('9b5bffcc-b460-4792-a16b-71be4df7c860', 'f3000002-0000-0000-0000-00000000006c',
   'Lois > Constitution > traités',
   'false', '1'),

  ('64b31f6e-b233-4e10-bad4-28f0d137a454', 'f3000002-0000-0000-0000-00000000006c',
   'Règlements > tous',
   'false', '2'),

  ('94747361-3fe4-4c08-b508-18ab788df697', 'f3000002-0000-0000-0000-00000000006c',
   'Tout est égal',
   'false', '3'),

  ('c9626da8-5bb0-45ae-925c-28e1c046e369', 'f3000002-0000-0000-0000-00000000006d',
   'Interdiction d''être jugé deux fois pour les mêmes faits',
   'true', '0'),

  ('60faf4f4-192b-4fbb-babf-5facfb1f7f1f', 'f3000002-0000-0000-0000-00000000006d',
   'Interdiction de mentir',
   'false', '1'),

  ('932d3d0b-da88-4743-937d-2b1f4b065de3', 'f3000002-0000-0000-0000-00000000006d',
   'Obligation de comparaître',
   'false', '2'),

  ('cd3a1708-91df-4c84-935a-c02445800e4c', 'f3000002-0000-0000-0000-00000000006d',
   'Interdiction de l''avocat',
   'false', '3'),

  ('62bd1fad-0a53-44e2-90e7-239609090601', 'f3000002-0000-0000-0000-00000000006e',
   'Oui, article 13 de la CEDH',
   'true', '0'),

  ('f61718af-237f-444e-b477-0cc5b71544bc', 'f3000002-0000-0000-0000-00000000006e',
   'Non, c''est facultatif',
   'false', '1'),

  ('ac32871a-f2f1-4648-b739-335d71102332', 'f3000002-0000-0000-0000-00000000006e',
   'Uniquement pour les Français',
   'false', '2'),

  ('14f9f6db-ab37-486a-9245-8d72bea2cd67', 'f3000002-0000-0000-0000-00000000006e',
   'Uniquement pour les Européens',
   'false', '3'),

  ('6fd29f38-b81e-4667-930b-5d75ed31c024', 'f3000002-0000-0000-0000-00000000006f',
   'Un régime d''exception restreignant temporairement certaines libertés',
   'true', '0'),

  ('bfc28a33-cd83-4b4a-93c9-9175cdad1ea2', 'f3000002-0000-0000-0000-00000000006f',
   'Un service hospitalier',
   'false', '1'),

  ('ef183347-97b2-4b08-92e9-d79a65934b20', 'f3000002-0000-0000-0000-00000000006f',
   'Une procédure administrative ordinaire',
   'false', '2'),

  ('ef997014-6938-4e5f-807e-15d064b46ccc', 'f3000002-0000-0000-0000-00000000006f',
   'Une mesure économique',
   'false', '3'),

  ('60d1d491-a472-44c6-ae85-7d3580ae7ea7', 'f3000002-0000-0000-0000-000000000070',
   '24 heures, prolongeable jusqu''à 96h dans certains cas',
   'true', '0'),

  ('e56a8ad3-be66-414f-9d16-ffb228648535', 'f3000002-0000-0000-0000-000000000070',
   '1 semaine sans limite',
   'false', '1'),

  ('4ac2cd3f-49a9-46c9-9161-e3f5003b6c54', 'f3000002-0000-0000-0000-000000000070',
   'Indéfinie selon le juge',
   'false', '2'),

  ('6650d1e0-4e6b-45ec-ac88-3694241b0763', 'f3000002-0000-0000-0000-000000000070',
   'Aucune limite',
   'false', '3'),

  ('e383824d-e8e6-45bb-ae1c-674274e09a6b', 'f3000002-0000-0000-0000-000000000071',
   'Le secret médical (protégé par la déontologie et le Code pénal)',
   'true', '0'),

  ('da4bfd3d-dd04-40b9-a6e4-8100865b186f', 'f3000002-0000-0000-0000-000000000071',
   'Le droit à la santé',
   'false', '1'),

  ('e3fe4c81-0c1e-4336-abc6-61ce686a7a18', 'f3000002-0000-0000-0000-000000000071',
   'Le droit à la formation',
   'false', '2'),

  ('e4bc83a3-ccbe-4a98-af44-c15ef1155b43', 'f3000002-0000-0000-0000-000000000071',
   'Aucun droit spécifique',
   'false', '3'),

  ('a49bbb9b-ce5f-45fe-bed8-30169991c442', 'f3000002-0000-0000-0000-000000000072',
   'Oui, depuis la révision constitutionnelle de mars 2024',
   'true', '0'),

  ('fac888b5-a7a5-4867-823d-0ad2ae6e2c5f', 'f3000002-0000-0000-0000-000000000072',
   'Non, c''est une simple loi',
   'false', '1'),

  ('1e80a21b-7768-45b4-a864-92e19ed7f743', 'f3000002-0000-0000-0000-000000000072',
   'Uniquement en cas de viol',
   'false', '2'),

  ('e20e96f0-847c-4377-a626-02f9ddc45653', 'f3000002-0000-0000-0000-000000000072',
   'Uniquement les jours pairs',
   'false', '3'),

  ('35606c23-9371-44ec-b760-ccd3767a3beb', 'f3000002-0000-0000-0000-000000000073',
   'La liberté de la presse, avec ses limites légales',
   'true', '0'),

  ('deb45c2b-fb3a-43da-b394-2f65d814f269', 'f3000002-0000-0000-0000-000000000073',
   'Le droit des imprimeurs',
   'false', '1'),

  ('b0767a41-8094-4c6c-bd12-27206f8c3346', 'f3000002-0000-0000-0000-000000000073',
   'Le commerce des livres',
   'false', '2'),

  ('b478f859-2a0d-4ecd-8878-910e8b5084f5', 'f3000002-0000-0000-0000-000000000073',
   'Aucune liberté particulière',
   'false', '3'),

  ('7a8e9249-8eea-41d3-9bfa-8e37651de875', 'f3000002-0000-0000-0000-000000000074',
   'Un État soumis à la loi avec contrôle juridictionnel',
   'true', '0'),

  ('bae3b9c3-8533-4416-b904-fcddb0be3204', 'f3000002-0000-0000-0000-000000000074',
   'Un État avec beaucoup de lois',
   'false', '1'),

  ('d2fab405-b260-4e44-9b93-eceb0cbb5991', 'f3000002-0000-0000-0000-000000000074',
   'Un État sans lois',
   'false', '2'),

  ('2555dc37-56c9-4759-bd5e-105fe3f841c7', 'f3000002-0000-0000-0000-000000000074',
   'Un État monarchique',
   'false', '3'),

  ('bce4fb78-c63d-42b3-b0a8-09453ce7c3b9', 'f3000002-0000-0000-0000-000000000075',
   'L''article 6',
   'true', '0'),

  ('e1ddc921-f908-49b7-a0fc-00b53272f82a', 'f3000002-0000-0000-0000-000000000075',
   'L''article 1er',
   'false', '1'),

  ('a57676ac-384e-4c8a-b5a2-8c0aa133c8c2', 'f3000002-0000-0000-0000-000000000075',
   'L''article 12',
   'false', '2'),

  ('adb5250c-7cca-4d02-9d04-c8977409c945', 'f3000002-0000-0000-0000-000000000075',
   'L''article 30',
   'false', '3'),

  ('801e2a74-1d3f-475b-9878-e5638162bcf9', 'f3000002-0000-0000-0000-000000000076',
   'Sur recours individuel après épuisement des recours internes',
   'true', '0'),

  ('5f42dc2f-df90-426a-bdd0-05784ece2581', 'f3000002-0000-0000-0000-000000000076',
   'Automatiquement chaque année',
   'false', '1'),

  ('ef13fd37-d9a3-4253-8ac2-28ee4f4a2f40', 'f3000002-0000-0000-0000-000000000076',
   'Par décision du Parlement européen',
   'false', '2'),

  ('5cb44b0b-e6f3-4547-997d-cdf2e8efec09', 'f3000002-0000-0000-0000-000000000076',
   'Jamais',
   'false', '3'),

  ('9d369feb-154e-480f-b08a-99898264949b', 'f3000002-0000-0000-0000-000000000077',
   'Respect de la loi, contributions, défense, environnement',
   'true', '0'),

  ('eb05aad5-f187-454a-85f0-541752bae2ee', 'f3000002-0000-0000-0000-000000000077',
   'Aucun devoir n''est constitutionnel',
   'false', '1'),

  ('f36cd7af-eca4-4da3-b619-375d1acc60ea', 'f3000002-0000-0000-0000-000000000077',
   'Uniquement payer la TVA',
   'false', '2'),

  ('628fae20-8d46-4c3f-99b8-9d0fbd3c3717', 'f3000002-0000-0000-0000-000000000077',
   'Uniquement le service militaire',
   'false', '3'),

  ('a52a23d8-b0f9-45fe-8bd2-58175f19956f', 'f3000002-0000-0000-0000-000000000078',
   'Anciennement, mais le service militaire est suspendu depuis 1997',
   'true', '0'),

  ('c996b139-751c-42af-ae7b-8191260036ae', 'f3000002-0000-0000-0000-000000000078',
   'Non, jamais reconnu',
   'false', '1'),

  ('ec54403b-d719-401e-bd16-eea72ce95092', 'f3000002-0000-0000-0000-000000000078',
   'Uniquement pour les religieux',
   'false', '2'),

  ('d17f98d6-f28a-4e43-8bba-a7e972808337', 'f3000002-0000-0000-0000-000000000078',
   'Uniquement les hommes',
   'false', '3'),

  ('942b746e-50b3-4401-a7b4-4c8f7549584c', 'f3000002-0000-0000-0000-000000000079',
   'Corriger les inégalités de fait par des politiques publiques',
   'true', '0'),

  ('25f49d97-f81d-4cdb-a781-08d23d5cf607', 'f3000002-0000-0000-0000-000000000079',
   'Faire tous identiques',
   'false', '1'),

  ('fde3e8e1-5932-49ca-a1c7-83f5db9808a0', 'f3000002-0000-0000-0000-000000000079',
   'Supprimer la propriété',
   'false', '2'),

  ('26319995-478a-4267-bc58-a4833b465f7a', 'f3000002-0000-0000-0000-000000000079',
   'Donner plus aux puissants',
   'false', '3'),

  ('d6bf5daa-33a8-47da-b8a6-3e7ceed45227', 'f3000002-0000-0000-0000-00000000007a',
   'La décision du 16 juillet 1971 sur la liberté d''association',
   'true', '0'),

  ('b03ec083-22d8-4cf2-b3b0-eb9aea314d9a', 'f3000002-0000-0000-0000-00000000007a',
   'L''arrêt Sarran de 1998',
   'false', '1'),

  ('41654403-c46e-41de-ba0a-0d703399bd40', 'f3000002-0000-0000-0000-00000000007a',
   'L''arrêt Nicolo de 1989',
   'false', '2'),

  ('12e29ec0-196d-42da-9f0d-f176768db2ce', 'f3000002-0000-0000-0000-00000000007a',
   'Aucune décision française comparable',
   'false', '3'),

  ('613788f1-6de7-4cef-a31d-86b4af21b1d6', 'f3000002-0000-0000-0000-00000000007b',
   'L''UE agit si l''action est plus efficace au niveau européen',
   'true', '0'),

  ('6508d195-98bc-4b8d-bcb5-0ce5ff3bbe69', 'f3000002-0000-0000-0000-00000000007b',
   'L''UE remplace toujours les États',
   'false', '1'),

  ('8331f52a-0d08-4f15-b33a-cfb89b641804', 'f3000002-0000-0000-0000-00000000007b',
   'Les États peuvent ignorer l''UE',
   'false', '2'),

  ('38107d8c-d9dd-4ed3-ac53-f61ede60808f', 'f3000002-0000-0000-0000-00000000007b',
   'Tout est décidé à Bruxelles',
   'false', '3'),

  ('e09fb6cc-e076-4ef9-8048-5ff81d6aff7c', 'f3000002-0000-0000-0000-00000000007c',
   'Oui, statut d''apatride accordé par l''OFPRA',
   'true', '0'),

  ('7ee874c7-4bbb-43ce-a159-27386e3f1577', 'f3000002-0000-0000-0000-00000000007c',
   'Non, ils sont expulsés',
   'false', '1'),

  ('787419ea-3fba-4c96-abbb-ec229f070688', 'f3000002-0000-0000-0000-00000000007c',
   'Ils ne peuvent pas exister',
   'false', '2'),

  ('ff71059c-45b0-41f0-b836-4bc274765623', 'f3000002-0000-0000-0000-00000000007c',
   'Uniquement les enfants',
   'false', '3'),

  ('d47f7e9b-5998-4cae-8bf3-3ca1c6de6f65', 'f3000002-0000-0000-0000-00000000007d',
   'Requête à Strasbourg dans les 4 mois après recours interne définitif',
   'true', '0'),

  ('41a63086-e9a6-4a7f-91e7-cf9c99827b1e', 'f3000002-0000-0000-0000-00000000007d',
   'Aucune démarche possible',
   'false', '1'),

  ('29f66b8b-1284-4aa8-96b8-9bacbb18f2d2', 'f3000002-0000-0000-0000-00000000007d',
   'Demander à l''ambassadeur',
   'false', '2'),

  ('45f5b325-58b2-4799-a2c9-63a9601e9e4e', 'f3000002-0000-0000-0000-00000000007d',
   'Saisir le pape',
   'false', '3'),

  ('189351e6-b127-4d3d-a983-9fa5bb158fe5', 'f3000002-0000-0000-0000-00000000007e',
   'Saisir le juge administratif (référé-liberté ou recours)',
   'true', '0'),

  ('fa23e267-e3ad-4c2e-aae2-932f5c1fdc7f', 'f3000002-0000-0000-0000-00000000007e',
   'Aucun recours possible',
   'false', '1'),

  ('1ab29f15-382d-4508-9669-beb33fb1f92f', 'f3000002-0000-0000-0000-00000000007e',
   'Saisir le pape',
   'false', '2'),

  ('e71be47a-15b5-43c7-9e94-07fa1e18366d', 'f3000002-0000-0000-0000-00000000007e',
   'Faire la grève de la faim',
   'false', '3'),

  ('4fe490c1-8f95-4d0f-b58e-79fd772d057c', 'f3000002-0000-0000-0000-00000000007f',
   'Soulever une QPC lors d''une procédure judiciaire',
   'true', '0'),

  ('4fc03e80-9b5d-44a8-887b-2916c1f08811', 'f3000002-0000-0000-0000-00000000007f',
   'Réécrire la loi soi-même',
   'false', '1'),

  ('568bd569-089c-4b55-839c-cea25d8ec0e2', 'f3000002-0000-0000-0000-00000000007f',
   'Forcer le Parlement à voter',
   'false', '2'),

  ('99f78969-7859-44ea-8e01-8e349aed8fe6', 'f3000002-0000-0000-0000-00000000007f',
   'Aucun recours possible',
   'false', '3'),

  ('ae83ead7-bb39-4554-b658-13b4bc49c795', 'f3000002-0000-0000-0000-000000000080',
   'Saisir le Défenseur des droits, les prud''hommes, porter plainte',
   'true', '0'),

  ('73e9422b-5b1b-418a-9f6c-ebab5786054b', 'f3000002-0000-0000-0000-000000000080',
   'Aucune action possible',
   'false', '1'),

  ('1bda3053-f362-4a9e-bd18-c868db82b3c1', 'f3000002-0000-0000-0000-000000000080',
   'Changer de religion',
   'false', '2'),

  ('8e7a2ba5-f550-4193-8a33-4de63e885337', 'f3000002-0000-0000-0000-000000000080',
   'Faire de même avec d''autres salariés',
   'false', '3'),

  ('a8d26d8f-e750-4b94-9ec7-0a97ea0f5768', 'f3000002-0000-0000-0000-000000000081',
   'Signaler au procureur ; la compétence universelle peut s''appliquer',
   'true', '0'),

  ('994e19c4-49ac-4df1-ae01-39ae652ee68e', 'f3000002-0000-0000-0000-000000000081',
   'Aucune action possible en France',
   'false', '1'),

  ('d8ff47d3-8585-4749-899b-bbea277f2507', 'f3000002-0000-0000-0000-000000000081',
   'Saisir directement la CPI',
   'false', '2'),

  ('1b2e9ed5-3d19-4011-a6b0-0deaff12f651', 'f3000002-0000-0000-0000-000000000081',
   'Renvoyer la personne dans son pays',
   'false', '3'),

  ('962c9635-e399-47e0-b507-bf2a42f63360', 'f3000002-0000-0000-0000-000000000082',
   'Recours devant le Conseil d''État, ratification parlementaire ensuite',
   'true', '0'),

  ('a66958a6-f0e0-40c8-9370-6a4ffd41489d', 'f3000002-0000-0000-0000-000000000082',
   'Aucun contrôle',
   'false', '1'),

  ('924ada51-a0e8-4eaa-b25f-93a818ee79ec', 'f3000002-0000-0000-0000-000000000082',
   'Uniquement contrôle de l''ONU',
   'false', '2'),

  ('a16ae7cd-6c2b-4199-8dbe-e0f47b467985', 'f3000002-0000-0000-0000-000000000082',
   'Uniquement le pape peut intervenir',
   'false', '3'),

  ('20f917a6-9607-4a3d-b63d-8936c116d72e', 'f3000002-0000-0000-0000-000000000083',
   'Saisir l''ARCOM, qui peut sanctionner la chaîne',
   'true', '0'),

  ('3df52dc5-d327-4b0a-8d14-acc4fe6ca213', 'f3000002-0000-0000-0000-000000000083',
   'Aucune action possible',
   'false', '1'),

  ('2a3c7b41-9a3e-4e45-8d18-9bb6cc243ffb', 'f3000002-0000-0000-0000-000000000083',
   'Forcer le studio à diffuser',
   'false', '2'),

  ('dd21d8e5-ee45-469d-8077-90cc0c3ef5ce', 'f3000002-0000-0000-0000-000000000083',
   'Demander au pape de diffuser',
   'false', '3'),

  ('bf9acafa-da2e-4415-802c-ce4e33bff16d', 'f3000002-0000-0000-0000-000000000084',
   'Saisir la CNIL et faire valoir vos droits RGPD',
   'true', '0'),

  ('b6e96ae9-1e1f-465e-ac60-d1e611dee5bc', 'f3000002-0000-0000-0000-000000000084',
   'Aucun recours possible',
   'false', '1'),

  ('2546f253-eb77-4b48-9aec-cb37a10681d9', 'f3000002-0000-0000-0000-000000000084',
   'Pirater l''entreprise',
   'false', '2'),

  ('9e805446-ff77-459b-94d1-5bcda077e2a6', 'f3000002-0000-0000-0000-000000000084',
   'Demander au pape',
   'false', '3'),

  ('14de75d2-2609-4bc9-aadb-a60b80f92995', 'f3000002-0000-0000-0000-000000000085',
   'Plainte pénale (dans 3 mois) + action civile + droit de réponse',
   'true', '0'),

  ('e9fc97ed-9906-4451-ab81-be4461cb5b86', 'f3000002-0000-0000-0000-000000000085',
   'Aucun recours',
   'false', '1'),

  ('23cfba9e-912e-4a79-bc18-e950b0dc11ac', 'f3000002-0000-0000-0000-000000000085',
   'Diffamer aussi le journaliste',
   'false', '2'),

  ('a5dea5b5-d2a9-4804-875a-d3164fa5d116', 'f3000002-0000-0000-0000-000000000085',
   'Fermer le journal',
   'false', '3'),

  ('e570d3e9-f036-4c8b-9818-005c0373acc7', 'f3000002-0000-0000-0000-000000000086',
   'Saisir le tribunal administratif pour vice de procédure',
   'true', '0'),

  ('2b39b26e-be2e-4f96-b6e0-1a64c1299b42', 'f3000002-0000-0000-0000-000000000086',
   'Aucun recours possible',
   'false', '1'),

  ('508793b9-8b5c-493a-9603-40f29e9f951e', 'f3000002-0000-0000-0000-000000000086',
   'Refuser d''obéir sans formalité',
   'false', '2'),

  ('ec9835d2-1717-43ee-95d6-057aa443f74c', 'f3000002-0000-0000-0000-000000000086',
   'Saisir l''OTAN',
   'false', '3'),

  ('0f7cac86-b080-42a0-9a5b-081737021411', 'f3000002-0000-0000-0000-0000000000a1',
   'L''interdiction des traitements dégradants (article 3 CEDH)',
   'true', '0'),

  ('f7cd682c-8f3d-42bd-80c4-e7a0146900d3', 'f3000002-0000-0000-0000-0000000000a1',
   'Le principe de proportionnalité',
   'false', '1'),

  ('299a401f-f7de-4b35-83c5-000cdbf53d83', 'f3000002-0000-0000-0000-0000000000a1',
   'Le droit à la propriété',
   'false', '2'),

  ('be98891a-5f50-410c-bae6-4d6fab22626e', 'f3000002-0000-0000-0000-0000000000a1',
   'La liberté d''expression',
   'false', '3'),

  ('516d35d3-0607-4b66-b929-4de92b6b5b3b', 'f3000002-0000-0000-0000-0000000000a2',
   'Le droit de demander l''effacement de données personnelles',
   'true', '0'),

  ('33db0bbe-a6df-4d99-ae40-9882e46c4a7f', 'f3000002-0000-0000-0000-0000000000a2',
   'Le droit d''effacer toute sa vie',
   'false', '1'),

  ('3a6f91bc-6966-4368-a9da-e125400e3826', 'f3000002-0000-0000-0000-0000000000a2',
   'Un droit réservé aux mineurs',
   'false', '2'),

  ('4cd2fbd8-2e5b-4878-932c-01aec2f52dba', 'f3000002-0000-0000-0000-0000000000a2',
   'Aucun droit spécifique',
   'false', '3'),

  ('567d7fbd-7d51-461d-a7f1-e8df4ff1a771', 'f3000002-0000-0000-0000-0000000000a3',
   'Les données personnelles des citoyens européens',
   'true', '0'),

  ('151c27ed-fe93-4743-be8e-35d564aba4aa', 'f3000002-0000-0000-0000-0000000000a3',
   'Les données bancaires uniquement',
   'false', '1'),

  ('67738741-0158-4117-b3e3-3693ace4ae94', 'f3000002-0000-0000-0000-0000000000a3',
   'Les données médicales uniquement',
   'false', '2'),

  ('d4b94dd2-26a2-4d2c-ae1f-aefac1464091', 'f3000002-0000-0000-0000-0000000000a3',
   'Aucune donnée',
   'false', '3'),

  ('41ee1d68-46da-4b32-92f8-a13e5dde9fc3', 'f3000002-0000-0000-0000-0000000000a4',
   'Oui, c''est un crime jugé en cour d''assises',
   'true', '0'),

  ('f2677195-2e26-4731-92e2-5cb7718f4342', 'f3000002-0000-0000-0000-0000000000a4',
   'Non, c''est un simple délit',
   'false', '1'),

  ('ad7d8ab5-1720-416f-8d89-08be5ff5aa6f', 'f3000002-0000-0000-0000-0000000000a4',
   'Uniquement entre étrangers',
   'false', '2'),

  ('1c81d79d-f195-45aa-9df1-1a9971963863', 'f3000002-0000-0000-0000-0000000000a4',
   'Uniquement avec violence visible',
   'false', '3'),

  ('7c25e490-e4d5-4e40-9cd7-391a135b8380', 'f3000002-0000-0000-0000-0000000000a5',
   'Oui, c''est un délit puni par la loi',
   'true', '0'),

  ('3556a874-5115-4f27-ae0b-c26fc08f9cd1', 'f3000002-0000-0000-0000-0000000000a5',
   'Non, c''est de l''opinion',
   'false', '1'),

  ('09f65b77-0cb9-41ee-b0cd-28c64502ed29', 'f3000002-0000-0000-0000-0000000000a5',
   'Uniquement les insultes directes',
   'false', '2'),

  ('e12e72d7-8bcb-4659-8a15-cfe07b63c8c2', 'f3000002-0000-0000-0000-0000000000a5',
   'Uniquement en public',
   'false', '3'),

  ('ef96523b-d12a-491a-a2c5-28b3f9672ba3', 'f3000002-0000-0000-0000-0000000000a6',
   'La non-rétroactivité de la loi pénale plus sévère',
   'true', '0'),

  ('c4e29518-3362-49e7-b179-e1245893b929', 'f3000002-0000-0000-0000-0000000000a6',
   'La présomption d''innocence',
   'false', '1'),

  ('7ef985e5-a464-4663-8ea7-b214a0021bb7', 'f3000002-0000-0000-0000-0000000000a6',
   'La double incrimination',
   'false', '2'),

  ('93e62604-f366-4a93-b95d-93dfe188e330', 'f3000002-0000-0000-0000-0000000000a6',
   'L''amnistie générale',
   'false', '3');
