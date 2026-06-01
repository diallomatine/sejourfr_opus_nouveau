-- ============================================================================
-- V224 — Civique : Système institutionnel (lot 4)
-- ----------------------------------------------------------------------------
-- Questions + choix. Filtre: 11111111-0000-0000-0000-000000000002 .
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('f2000002-0000-0000-0000-00000000003b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle juridiction juge les crimes les plus graves (meurtre, viol) ?',
   'Les crimes sont jugés par la cour d''assises, composée de magistrats professionnels et de jurés tirés au sort parmi les citoyens.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000003c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel échelon territorial constitue la base de l''organisation administrative française ?',
   'La commune est la collectivité territoriale de base. Au-dessus : département, région, État.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000003d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Combien de régions compte la France métropolitaine depuis 2016 ?',
   'Depuis 2016, la France métropolitaine compte 13 régions (contre 22 auparavant), suite à la réforme territoriale.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000003e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui dirige une région en France ?',
   'Une région est dirigée par le président du conseil régional, élu par les conseillers régionaux après les élections régionales.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000003f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle est une compétence importante des régions en France ?',
   'Les régions gèrent notamment le développement économique, la formation professionnelle, les lycées et les transports ferroviaires régionaux (TER).',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000040', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'À quel échelon administratif sont rattachés les collèges ?',
   'Les collèges relèvent des départements. Les lycées relèvent des régions. Les écoles primaires relèvent des communes.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000041', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui dirige un conseil départemental ?',
   'Le conseil départemental est présidé par son président, élu par les conseillers départementaux. Le préfet représente lui l''État dans le département.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000042', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le vote est-il obligatoire en France ?',
   'Non. Voter est un droit et un devoir civique mais pas une obligation légale en France (contrairement à la Belgique). S''abstenir n''est pas sanctionné.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000043', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Combien de types d''élections principales un citoyen peut-il voter en France ?',
   'Un citoyen peut voter aux présidentielles, législatives, régionales, départementales, municipales et européennes : six types directs (plus le référendum).',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000044', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle est la durée du mandat des conseillers municipaux ?',
   'Les conseillers municipaux sont élus pour 6 ans. Le maire qu''ils élisent a la même durée de mandat.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000045', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle est la durée du mandat des conseillers régionaux ?',
   'Comme les conseillers départementaux et municipaux, les conseillers régionaux sont élus pour 6 ans.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000046', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Les citoyens européens résidant en France peuvent-ils être candidats aux municipales ?',
   'Oui, sauf au poste de maire ou d''adjoint. Ils peuvent aussi voter aux municipales et européennes en France.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000047', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Combien d''eurodéputés la France envoie-t-elle au Parlement européen ?',
   'La France élit 81 députés européens (depuis le Brexit). Le nombre dépend de la population de chaque pays membre.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000048', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle institution européenne vote les lois européennes ?',
   'Le Parlement européen, élu par les citoyens, vote les lois européennes conjointement avec le Conseil de l''UE.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000049', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Où se situent les sièges du Parlement européen ?',
   'Le Parlement européen siège à Strasbourg (sessions plénières officielles) et à Bruxelles (sessions supplémentaires et commissions).',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000004a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel traité a fondé la Communauté économique européenne en 1957 ?',
   'Le traité de Rome (25 mars 1957), signé par 6 pays fondateurs, a créé la CEE, ancêtre de l''Union européenne.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000004b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel traité a créé l''Union européenne sous sa forme actuelle ?',
   'Le traité de Maastricht (7 février 1992) a fondé l''UE. Il a aussi préparé la monnaie unique (euro) et la citoyenneté européenne.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000004c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que prévoit l''espace Schengen ?',
   'L''espace Schengen permet la libre circulation des personnes en supprimant les contrôles aux frontières entre pays signataires.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000004d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que confère la citoyenneté européenne ?',
   'Elle donne le droit de circuler, de travailler dans tout pays de l''UE, de voter aux municipales et européennes dans son pays de résidence.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000004e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Combien y a-t-il de sénateurs en France ?',
   'Le Sénat français compte 348 sénateurs, élus pour 6 ans au suffrage universel indirect.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000004f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'En cas de désaccord persistant entre Assemblée nationale et Sénat, qui tranche ?',
   'L''Assemblée nationale a le dernier mot en cas de désaccord persistant. Cette procédure est prévue par la Constitution.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000050', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce qu''une ordonnance en droit français ?',
   'Une ordonnance est un texte pris par le gouvernement dans un domaine relevant normalement de la loi, après autorisation du Parlement.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000051', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que peut faire un citoyen face à un mauvais fonctionnement d''un service public ?',
   'Il peut saisir le Défenseur des droits, autorité administrative indépendante qui défend les droits des usagers face aux administrations.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000052', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que la Question prioritaire de constitutionnalité (QPC) ?',
   'Instaurée en 2008, la QPC permet à tout citoyen de contester devant le Conseil constitutionnel la conformité d''une loi aux droits constitutionnels.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000053', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Comment appelle-t-on les regroupements de communes pour gérer ensemble certains services ?',
   'Les intercommunalités (communautés de communes, d''agglomération, urbaines, métropoles) mutualisent des services (transports, déchets, urbanisme).',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000054', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle assemblée élit le maire d''une commune ?',
   'Le maire est élu par le conseil municipal (les conseillers municipaux) lors de la première réunion qui suit les élections municipales.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000055', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel est le rôle d''un député européen ?',
   'Un député européen vote les lois européennes au Parlement de Strasbourg, contrôle la Commission européenne et adopte le budget de l''UE.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000056', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle institution propose les lois européennes ?',
   'La Commission européenne, basée à Bruxelles, est la seule à pouvoir proposer des lois européennes. Le Parlement et le Conseil les votent.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000005a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle indépendance est essentielle pour les juges ?',
   'L''indépendance de la justice signifie que les juges décident en toute liberté, sans pression du pouvoir politique. C''est garanti par la Constitution.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000005b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel pouvoir public contrôle le pouvoir exécutif au quotidien ?',
   'Le Parlement (Assemblée + Sénat) contrôle le gouvernement par des questions, des commissions d''enquête, des débats et le vote du budget.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000005c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que sont les commissions parlementaires ?',
   'Les commissions parlementaires sont des groupes de députés ou sénateurs spécialisés dans un domaine (lois, finances, défense...) qui préparent les travaux des assemblées.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000005d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Un parlementaire peut-il être arrêté sans condition ?',
   'Non. Les parlementaires bénéficient d''une immunité parlementaire pour protéger leur fonction. Elle n''empêche pas la justice de les poursuivre, mais protège la liberté d''expression dans leur fonction.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000005e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le président de la République peut-il être poursuivi pénalement pendant son mandat ?',
   'Le président bénéficie d''une immunité pendant son mandat pour les actes accomplis en cette qualité. Il peut être poursuivi après la fin de son mandat ou destitué par le Parlement réuni en Haute Cour.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000005f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Mon employeur veut me licencier sans motif valable. Quel recours s''offre à moi ?',
   'Vous pouvez saisir le conseil des prud''hommes, juridiction spécialisée dans les conflits du travail entre salariés et employeurs.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000061', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Une loi votée me paraît contraire à un de mes droits fondamentaux. Que faire ?',
   'Au cours d''un procès, vous pouvez demander à votre juge de transmettre une Question prioritaire de constitutionnalité (QPC) au Conseil constitutionnel pour faire annuler la loi.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000062', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Je veux participer à la vie démocratique sans être élu. Quelles possibilités existent ?',
   'On peut s''engager dans un parti politique, dans une association, participer à des consultations publiques, lancer une pétition, ou intervenir lors d''enquêtes publiques.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000063', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Un agent de mairie refuse de me délivrer un document auquel j''ai droit. Que faire ?',
   'Demandez d''abord par écrit pour conserver une trace. En cas de refus persistant, saisissez le Défenseur des droits ou le tribunal administratif.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000064', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Je veux participer à une commission d''enquête parlementaire pour témoigner. Est-ce possible ?',
   'Les commissions d''enquête parlementaires peuvent auditionner des témoins. Le témoignage peut être obligatoire et le faux témoignage est puni pénalement.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000065', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Je conteste un PV de stationnement. À quelle juridiction m''adresser ?',
   'Pour contester un PV de stationnement (forfait post-stationnement), il faut saisir la Commission du contentieux du stationnement payant, juridiction administrative spécialisée.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000066', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Mon député défend un projet contraire à mes idées. Que puis-je faire ?',
   'On peut lui écrire pour exprimer son désaccord, participer à une manifestation légale, soutenir un autre candidat aux prochaines élections, ou militer dans un parti.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000067', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Je suis convoqué comme juré de cour d''assises. Puis-je refuser ?',
   'Être juré est une obligation civique. Seuls certains motifs (âge, incapacité, profession incompatible) permettent d''être dispensé. Refuser sans raison expose à une amende.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000068', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Mon voisin n''a pas respecté une règle d''urbanisme. À quelle autorité signaler ?',
   'Les règles d''urbanisme sont contrôlées par la mairie. Vous pouvez signaler l''infraction au maire, qui peut diligenter un contrôle et éventuellement prendre un arrêté.',
   'true', '2026-05-27 17:40:29.884451+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000069', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qui a rédigé le projet de Constitution de la Ve République adopté en 1958 ?',
   'La Constitution de 1958 a été rédigée sous l''autorité de Charles de Gaulle et de Michel Debré (alors garde des sceaux), avec l''aide de juristes comme René Cassin.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000006a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Pourquoi la IVe République a-t-elle pris fin en 1958 ?',
   'La IVe République souffrait d''instabilité gouvernementale chronique et a été renversée par la crise algérienne de mai 1958, ouvrant la voie à la Ve République avec de Gaulle.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000006b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'En quelle année le quinquennat présidentiel a-t-il remplacé le septennat ?',
   'Le quinquennat a remplacé le septennat suite au référendum du 24 septembre 2000. Le premier président élu pour 5 ans a été Jacques Chirac en 2002.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000006c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qui a été le premier président de la Ve République élu au suffrage universel direct ?',
   'Charles de Gaulle a été le premier président élu au suffrage universel direct en 1965, après la révision constitutionnelle de 1962.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000006d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel référendum de 1962 a transformé l''élection du président ?',
   'Le référendum du 28 octobre 1962 a instauré l''élection du président au suffrage universel direct, sur l''initiative de Charles de Gaulle.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000006e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que signifie l''expression ''cohabitation'' en politique française ?',
   'La cohabitation désigne la situation où le président de la République et le Premier ministre appartiennent à des bords politiques opposés. Trois cohabitations ont eu lieu : 1986-88, 1993-95, 1997-2002.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000006f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel article permet au président d''exercer des pouvoirs exceptionnels en cas de crise grave ?',
   'L''article 16 de la Constitution autorise le président, en cas de menace grave et immédiate sur les institutions, à prendre des mesures exceptionnelles. Il n''a été utilisé qu''une fois, en 1961 par de Gaulle.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000070', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Combien de fois l''article 16 de la Constitution a-t-il été utilisé depuis 1958 ?',
   'L''article 16 (pouvoirs exceptionnels) n''a été appliqué qu''une seule fois, par Charles de Gaulle du 23 avril au 29 septembre 1961, lors du putsch des généraux à Alger.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL);

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('b461d756-ac33-4552-9a14-4a3966e1dc81', 'f2000002-0000-0000-0000-00000000003b',
   'La cour d''assises',
   'true', '0'),

  ('2ec4165d-640d-44b2-9a60-f83bdfb407b8', 'f2000002-0000-0000-0000-00000000003b',
   'Le tribunal de police',
   'false', '1'),

  ('a79fbcfa-3930-4c4c-b3af-28eb5d5f281f', 'f2000002-0000-0000-0000-00000000003b',
   'Le Sénat',
   'false', '2'),

  ('b84a2631-10d6-4ea9-8c92-c57d99c79d61', 'f2000002-0000-0000-0000-00000000003b',
   'Le Parlement',
   'false', '3'),

  ('4f36948a-d379-44e8-941e-f3a2954068f5', 'f2000002-0000-0000-0000-00000000003c',
   'La commune (échelon de base)',
   'true', '0'),

  ('100b9660-0bd8-4265-90e6-dfef61231edf', 'f2000002-0000-0000-0000-00000000003c',
   'L''échelon le plus élevé',
   'false', '1'),

  ('2962d677-8dbe-44c0-acd7-706a9103daa0', 'f2000002-0000-0000-0000-00000000003c',
   'Au-dessus de la région',
   'false', '2'),

  ('2d0ebdf5-3f5c-4716-af12-77123878bfdb', 'f2000002-0000-0000-0000-00000000003c',
   'Un découpage uniquement religieux',
   'false', '3'),

  ('ab6eeba2-9c47-47c6-98e5-7b9f779465e0', 'f2000002-0000-0000-0000-00000000003d',
   '13 régions',
   'true', '0'),

  ('7835900f-aa1a-40af-a58b-e87fbfbc1526', 'f2000002-0000-0000-0000-00000000003d',
   '22 régions',
   'false', '1'),

  ('bbaa1c20-3ba7-47c5-a7b0-383dfdd82df3', 'f2000002-0000-0000-0000-00000000003d',
   '5 régions',
   'false', '2'),

  ('186ce58f-bc81-4e73-8c2c-0594031ef41c', 'f2000002-0000-0000-0000-00000000003d',
   '95 régions',
   'false', '3'),

  ('3d5af058-7809-4bfd-a6f1-18d3f58446f3', 'f2000002-0000-0000-0000-00000000003e',
   'Le président du conseil régional',
   'true', '0'),

  ('8d579240-4547-4f5f-8a93-11452dcdeb23', 'f2000002-0000-0000-0000-00000000003e',
   'Le préfet de région',
   'false', '1'),

  ('75e04e17-f481-4f19-84b7-4a6b6efc56a5', 'f2000002-0000-0000-0000-00000000003e',
   'Le maire de la plus grande ville',
   'false', '2'),

  ('f9c7cbcd-608b-4684-8ada-b66618b042b9', 'f2000002-0000-0000-0000-00000000003e',
   'Le président de la République',
   'false', '3'),

  ('8aaac8b6-f4e3-46f3-98ab-c2ec359a34a4', 'f2000002-0000-0000-0000-00000000003f',
   'La gestion des lycées et des TER',
   'true', '0'),

  ('b0cf8cb0-e3c9-4d3e-8456-db7bd90b7832', 'f2000002-0000-0000-0000-00000000003f',
   'La défense nationale',
   'false', '1'),

  ('0ade0ce0-a487-4ce2-8b78-21a379c8d6f0', 'f2000002-0000-0000-0000-00000000003f',
   'La politique étrangère',
   'false', '2'),

  ('5f3fa86e-593d-4a2a-9347-1602b25ed77f', 'f2000002-0000-0000-0000-00000000003f',
   'La monnaie',
   'false', '3'),

  ('cc867755-9ab2-4c41-8d6e-5a63981dc955', 'f2000002-0000-0000-0000-000000000040',
   'Le département',
   'true', '0'),

  ('e9a45301-2a54-4ed6-8cff-5c6771ddc423', 'f2000002-0000-0000-0000-000000000040',
   'La commune',
   'false', '1'),

  ('aba267d1-90ab-433d-8c5f-2c2f065cb938', 'f2000002-0000-0000-0000-000000000040',
   'La région',
   'false', '2'),

  ('ac44e488-4d77-49c9-9049-094be9406b7f', 'f2000002-0000-0000-0000-000000000040',
   'L''État directement',
   'false', '3'),

  ('03f6e8e8-d026-42b3-80ab-f53f6b1f65c1', 'f2000002-0000-0000-0000-000000000041',
   'Le président du conseil départemental',
   'true', '0'),

  ('2807097b-798c-4a51-8f81-b344a0c89662', 'f2000002-0000-0000-0000-000000000041',
   'Le préfet',
   'false', '1'),

  ('965526c2-1532-408c-ad0c-a7fc2071aaed', 'f2000002-0000-0000-0000-000000000041',
   'Le ministre de l''Intérieur',
   'false', '2'),

  ('e835c302-41ce-4d7f-9d05-4f1ae967067a', 'f2000002-0000-0000-0000-000000000041',
   'Le maire du chef-lieu',
   'false', '3'),

  ('64048e3a-e043-4184-9ab4-9e8d81ee10ba', 'f2000002-0000-0000-0000-000000000042',
   'Non, c''est un droit mais pas une obligation',
   'true', '0'),

  ('cb95701a-3a12-4ad1-88fb-a30164f49793', 'f2000002-0000-0000-0000-000000000042',
   'Oui, sous peine d''amende',
   'false', '1'),

  ('7a53c1a8-9573-4d3a-8cae-fc3f6c3a2591', 'f2000002-0000-0000-0000-000000000042',
   'Oui, sous peine de prison',
   'false', '2'),

  ('d00d6881-582b-441c-ad54-08524a58a5c0', 'f2000002-0000-0000-0000-000000000042',
   'Uniquement pour les fonctionnaires',
   'false', '3'),

  ('372b13b8-a4d2-4460-a835-efae9a0b6cbf', 'f2000002-0000-0000-0000-000000000043',
   'Au moins six types différents',
   'true', '0'),

  ('5cdb91e2-0270-4ce8-b1be-459953b717b6', 'f2000002-0000-0000-0000-000000000043',
   'Une seule élection',
   'false', '1'),

  ('ed007baa-1ef2-4983-b57d-ab98d537edf2', 'f2000002-0000-0000-0000-000000000043',
   'Aucune',
   'false', '2'),

  ('db7b8437-ad15-4205-800d-19a6e7cb6fee', 'f2000002-0000-0000-0000-000000000043',
   'Uniquement la présidentielle',
   'false', '3'),

  ('82e574a2-473d-4e7f-bf62-6c51b367994d', 'f2000002-0000-0000-0000-000000000044',
   '6 ans',
   'true', '0'),

  ('1e860144-4200-49c3-b1e6-0dd9111227b3', 'f2000002-0000-0000-0000-000000000044',
   '5 ans',
   'false', '1'),

  ('7710981e-aeb3-4890-b924-dbafb40c67a5', 'f2000002-0000-0000-0000-000000000044',
   '4 ans',
   'false', '2'),

  ('060a9c47-1a17-48a5-9180-e8188a46c592', 'f2000002-0000-0000-0000-000000000044',
   '3 ans',
   'false', '3'),

  ('c4a01045-9018-4393-a5f7-2ec95b715081', 'f2000002-0000-0000-0000-000000000045',
   '6 ans',
   'true', '0'),

  ('fbcbc52c-a204-4a43-a793-6245c1e51650', 'f2000002-0000-0000-0000-000000000045',
   '5 ans',
   'false', '1'),

  ('95b9cb6b-b1be-484a-815b-aec70d0f3bc2', 'f2000002-0000-0000-0000-000000000045',
   '7 ans',
   'false', '2'),

  ('a2f5cd6a-e9c3-4d43-a90b-41dbce850022', 'f2000002-0000-0000-0000-000000000045',
   '9 ans',
   'false', '3'),

  ('e30168eb-ba5e-4772-8b40-66c8dd2b3c52', 'f2000002-0000-0000-0000-000000000046',
   'Oui, mais pas comme maire ou adjoint',
   'true', '0'),

  ('7ba78daf-1501-4aee-9132-d79c4673e44e', 'f2000002-0000-0000-0000-000000000046',
   'Non, c''est interdit',
   'false', '1'),

  ('4ef47a1f-bd7c-4e5b-952b-3beace4691ef', 'f2000002-0000-0000-0000-000000000046',
   'Oui, à toutes les fonctions',
   'false', '2'),

  ('6fd5dedf-8d12-44b3-809b-bb741842161b', 'f2000002-0000-0000-0000-000000000046',
   'Uniquement après 30 ans',
   'false', '3'),

  ('2e4f1162-1913-41d7-aaa6-6d2367ff331a', 'f2000002-0000-0000-0000-000000000047',
   '81 députés européens',
   'true', '0'),

  ('559d7826-b845-4801-8843-93749d3ac80b', 'f2000002-0000-0000-0000-000000000047',
   '577 députés européens',
   'false', '1'),

  ('00311a5f-2e12-4815-9c9b-c3b56e412a31', 'f2000002-0000-0000-0000-000000000047',
   '12 députés européens',
   'false', '2'),

  ('fb2ace53-81f9-48fc-9651-addf287894b6', 'f2000002-0000-0000-0000-000000000047',
   'Aucun',
   'false', '3'),

  ('6de80af9-6733-4508-8989-a6e6b14450ea', 'f2000002-0000-0000-0000-000000000048',
   'Le Parlement européen',
   'true', '0'),

  ('b9b14626-aa51-4f13-ac8f-9a7d3f7f6cf9', 'f2000002-0000-0000-0000-000000000048',
   'L''Assemblée nationale française',
   'false', '1'),

  ('46f6fe6e-05aa-42f7-91cc-09a477af3b73', 'f2000002-0000-0000-0000-000000000048',
   'L''ONU',
   'false', '2'),

  ('b9dca2d8-7ab4-4409-ac7e-59d3f355c6dd', 'f2000002-0000-0000-0000-000000000048',
   'L''OTAN',
   'false', '3'),

  ('3eaef319-6d41-4acc-ba8b-78d07e1f9837', 'f2000002-0000-0000-0000-000000000049',
   'À Strasbourg et à Bruxelles',
   'true', '0'),

  ('a9ddb0ad-a281-422b-91ff-766b7c784532', 'f2000002-0000-0000-0000-000000000049',
   'Uniquement à Paris',
   'false', '1'),

  ('a9b9a360-9b98-4c74-a548-7eaf35f85a08', 'f2000002-0000-0000-0000-000000000049',
   'À Londres',
   'false', '2'),

  ('98673aaf-ad9d-4450-acfc-ba36acd27e0c', 'f2000002-0000-0000-0000-000000000049',
   'À New York',
   'false', '3'),

  ('c53b7ffb-be99-47d3-a429-4a9ce701bc41', 'f2000002-0000-0000-0000-00000000004a',
   'Le traité de Rome',
   'true', '0'),

  ('63baeafc-0ea2-411f-a09c-c26e7bc9bb4d', 'f2000002-0000-0000-0000-00000000004a',
   'Le traité de Versailles',
   'false', '1'),

  ('bc58831c-65c9-476e-80b6-f1c3bb60bc66', 'f2000002-0000-0000-0000-00000000004a',
   'Le traité de Lisbonne',
   'false', '2'),

  ('3f83c245-9729-465e-8faa-87c7f11973f9', 'f2000002-0000-0000-0000-00000000004a',
   'Le traité de Maastricht',
   'false', '3'),

  ('8e773bea-2ddd-4479-8402-a35990ace7ff', 'f2000002-0000-0000-0000-00000000004b',
   'Le traité de Maastricht',
   'true', '0'),

  ('8b1af188-b02b-42fd-932b-dbbb7c04c212', 'f2000002-0000-0000-0000-00000000004b',
   'Le traité de Rome',
   'false', '1'),

  ('46538058-9735-4cc8-a77e-5b10692b7f94', 'f2000002-0000-0000-0000-00000000004b',
   'Le traité de Schengen',
   'false', '2'),

  ('1c339234-3997-424a-bc8f-0f1e46ab1043', 'f2000002-0000-0000-0000-00000000004b',
   'Le traité de Berlin',
   'false', '3'),

  ('9417aa95-bca4-4da5-a6d8-3a4ceba7cb93', 'f2000002-0000-0000-0000-00000000004c',
   'La libre circulation sans contrôle aux frontières internes',
   'true', '0'),

  ('8ccdb4cf-ad18-45e5-95d3-e4ed9e4c6e73', 'f2000002-0000-0000-0000-00000000004c',
   'Une monnaie unique',
   'false', '1'),

  ('dcac5a26-e044-47ce-bdea-4087382da4c8', 'f2000002-0000-0000-0000-00000000004c',
   'L''interdiction de voyager',
   'false', '2'),

  ('6df19c2c-6fb7-4135-a042-cf06a8de91a7', 'f2000002-0000-0000-0000-00000000004c',
   'L''abolition des passeports mondiaux',
   'false', '3'),

  ('9e630f84-00b0-4ac1-993c-eacaeadeff72', 'f2000002-0000-0000-0000-00000000004d',
   'Droit de circuler, travailler et voter dans toute l''Union',
   'true', '0'),

  ('0a6850b8-4823-466f-bbd8-3d94c808a08b', 'f2000002-0000-0000-0000-00000000004d',
   'L''abandon de sa nationalité',
   'false', '1'),

  ('4dc3fd8d-a3f1-41c4-80ad-b58e9cedc029', 'f2000002-0000-0000-0000-00000000004d',
   'Le droit de voter à la présidentielle française',
   'false', '2'),

  ('b70aeff0-39bd-49ce-9c27-caf181012ecf', 'f2000002-0000-0000-0000-00000000004d',
   'Aucun droit particulier',
   'false', '3'),

  ('057bbd53-cfa6-472b-9678-7249d5e3daf5', 'f2000002-0000-0000-0000-00000000004e',
   '348 sénateurs',
   'true', '0'),

  ('b82d61cb-6a25-4e7d-9476-65ad0c01a6be', 'f2000002-0000-0000-0000-00000000004e',
   '577 sénateurs',
   'false', '1'),

  ('ad4e8d5a-f0a1-4ec1-8d2c-a41ba1df192c', 'f2000002-0000-0000-0000-00000000004e',
   '100 sénateurs',
   'false', '2'),

  ('19305dde-7455-410a-a7e7-ab85ba5619b3', 'f2000002-0000-0000-0000-00000000004e',
   '50 sénateurs',
   'false', '3'),

  ('47dd3558-b7b2-4169-917d-c1c909777245', 'f2000002-0000-0000-0000-00000000004f',
   'L''Assemblée nationale',
   'true', '0'),

  ('d9b1879b-bdc6-470f-83ae-7f15d4a690b6', 'f2000002-0000-0000-0000-00000000004f',
   'Le Sénat',
   'false', '1'),

  ('2b3b728f-144f-4563-ac7e-72ad7f5c67ff', 'f2000002-0000-0000-0000-00000000004f',
   'Le président seul',
   'false', '2'),

  ('556d08f4-806f-4f0a-bf44-086933efb5ed', 'f2000002-0000-0000-0000-00000000004f',
   'Le Conseil constitutionnel',
   'false', '3'),

  ('38c1aac0-74d6-41dc-b736-abe5959b0dbe', 'f2000002-0000-0000-0000-000000000050',
   'Un texte du gouvernement dans un domaine normalement législatif',
   'true', '0'),

  ('e4e0414c-01b5-483f-88fb-1c1a244fa203', 'f2000002-0000-0000-0000-000000000050',
   'Une décision médicale obligatoire',
   'false', '1'),

  ('e5aa2144-c49f-4680-ab26-7a7b13338473', 'f2000002-0000-0000-0000-000000000050',
   'Un décret religieux',
   'false', '2'),

  ('09e0a1d1-1adb-4565-88c4-514edac5b870', 'f2000002-0000-0000-0000-000000000050',
   'Une convocation au tribunal',
   'false', '3'),

  ('b6bbe0bc-6162-4363-b0d4-ffa18840a74a', 'f2000002-0000-0000-0000-000000000051',
   'Saisir le Défenseur des droits',
   'true', '0'),

  ('41ebe30d-3f2f-4875-ae23-4473fcd75137', 'f2000002-0000-0000-0000-000000000051',
   'Devenir lui-même ministre',
   'false', '1'),

  ('70072ba5-40c6-4cbc-a8a5-02fd0a389c30', 'f2000002-0000-0000-0000-000000000051',
   'Demander à la presse de menacer le service',
   'false', '2'),

  ('6750a891-e6aa-485c-95ed-1c54a6db5854', 'f2000002-0000-0000-0000-000000000051',
   'Rien, il n''y a aucun recours',
   'false', '3'),

  ('97834df3-0b8c-49c4-b020-bfb2674839e1', 'f2000002-0000-0000-0000-000000000052',
   'Recours du citoyen pour contester une loi devant le Conseil constitutionnel',
   'true', '0'),

  ('c7985151-2688-412d-b034-93531b157263', 'f2000002-0000-0000-0000-000000000052',
   'Une question posée au président',
   'false', '1'),

  ('0bb9901c-e820-4f8c-badf-bad6d8ed70f8', 'f2000002-0000-0000-0000-000000000052',
   'Un sondage parlementaire',
   'false', '2'),

  ('43e59ccc-5cec-47b9-9af4-d973c1562be0', 'f2000002-0000-0000-0000-000000000052',
   'Une émission télévisée',
   'false', '3'),

  ('31b97448-b4d1-40e0-bb00-0918ade42900', 'f2000002-0000-0000-0000-000000000053',
   'Les intercommunalités',
   'true', '0'),

  ('a4aaa662-7380-4605-aaa3-afd538015bfa', 'f2000002-0000-0000-0000-000000000053',
   'Les paroisses',
   'false', '1'),

  ('e9ec91de-18ec-42f6-89c0-34c1f44cae46', 'f2000002-0000-0000-0000-000000000053',
   'Les cantons',
   'false', '2'),

  ('3cb17911-c40a-4dd9-9d95-892c7d814f57', 'f2000002-0000-0000-0000-000000000053',
   'Les districts religieux',
   'false', '3'),

  ('2fe5989b-38d3-420e-9bdb-035ce3ba1ee4', 'f2000002-0000-0000-0000-000000000054',
   'Le conseil municipal',
   'true', '0'),

  ('e71edb55-44ed-43ad-a80f-d4d78a113fa9', 'f2000002-0000-0000-0000-000000000054',
   'Le président de la République',
   'false', '1'),

  ('f5a154b1-18fa-41f7-862e-acb8f1ae3148', 'f2000002-0000-0000-0000-000000000054',
   'Le préfet',
   'false', '2'),

  ('60d62368-627b-4d51-a869-8c6cea1b8ce7', 'f2000002-0000-0000-0000-000000000054',
   'Les habitants au suffrage direct',
   'false', '3'),

  ('d9fa11b0-c8a8-498e-8bdc-1e5dca0e977e', 'f2000002-0000-0000-0000-000000000055',
   'Voter les lois européennes et contrôler la Commission',
   'true', '0'),

  ('f866978d-0153-4cf0-8d7e-e9bde0413ca4', 'f2000002-0000-0000-0000-000000000055',
   'Diriger un ministère national',
   'false', '1'),

  ('34d63045-206b-4e75-a6b5-2f52e34fd51f', 'f2000002-0000-0000-0000-000000000055',
   'Commander l''armée européenne',
   'false', '2'),

  ('b0434fa6-2db3-4569-8327-2b53837f1e49', 'f2000002-0000-0000-0000-000000000055',
   'Nommer le pape',
   'false', '3'),

  ('2a6af6f6-1079-4cb4-8468-b2607223f945', 'f2000002-0000-0000-0000-000000000056',
   'La Commission européenne',
   'true', '0'),

  ('c5ffa723-899d-4828-89a9-08131274a56e', 'f2000002-0000-0000-0000-000000000056',
   'Le Parlement européen seul',
   'false', '1'),

  ('0b2d25a6-b131-4e68-897c-d7dac6c8c765', 'f2000002-0000-0000-0000-000000000056',
   'L''ONU',
   'false', '2'),

  ('17cfd4eb-acf2-4027-95a5-58930697c37e', 'f2000002-0000-0000-0000-000000000056',
   'Le Vatican',
   'false', '3'),

  ('caea9cad-e400-4b16-8dbf-bf3bebb02835', 'f2000002-0000-0000-0000-00000000005a',
   'L''indépendance vis-à-vis du pouvoir politique',
   'true', '0'),

  ('1f7d61dc-824d-457f-a9a3-88b8f1a59494', 'f2000002-0000-0000-0000-00000000005a',
   'La dépendance au président',
   'false', '1'),

  ('c5ca2459-7af3-46d9-90ea-b5506d32ef86', 'f2000002-0000-0000-0000-00000000005a',
   'L''allégeance à un parti',
   'false', '2'),

  ('5e825270-df73-4d63-ad5b-b7d86bdb20a3', 'f2000002-0000-0000-0000-00000000005a',
   'La soumission au préfet',
   'false', '3'),

  ('4663fa29-359c-49d8-bd1e-330086dd4a5c', 'f2000002-0000-0000-0000-00000000005b',
   'Le Parlement',
   'true', '0'),

  ('92fe3cad-4489-45c0-9edf-306364e41c57', 'f2000002-0000-0000-0000-00000000005b',
   'L''armée',
   'false', '1'),

  ('56103d00-f324-4582-a25f-91ee1036fb11', 'f2000002-0000-0000-0000-00000000005b',
   'Le pape',
   'false', '2'),

  ('8c668e8b-a48b-48b2-99d1-1102970e6ba2', 'f2000002-0000-0000-0000-00000000005b',
   'Le maire de Paris',
   'false', '3'),

  ('f6ae6a19-2c5b-4f48-a37c-748379201faa', 'f2000002-0000-0000-0000-00000000005c',
   'Des groupes de parlementaires spécialisés par domaine',
   'true', '0'),

  ('3a572689-7cac-4696-90d4-846fffaa2b05', 'f2000002-0000-0000-0000-00000000005c',
   'Des tribunaux spéciaux',
   'false', '1'),

  ('2d6ab57a-caaf-4f46-90a6-ebd14b1bd875', 'f2000002-0000-0000-0000-00000000005c',
   'Des associations de citoyens',
   'false', '2'),

  ('bb2fdf57-0010-48bc-8e31-44373c6d18fa', 'f2000002-0000-0000-0000-00000000005c',
   'Des émissions de télévision',
   'false', '3'),

  ('5b59e74c-5145-4f91-98c8-281e188a5c2e', 'f2000002-0000-0000-0000-00000000005d',
   'Non, ils ont une immunité parlementaire',
   'true', '0'),

  ('3d07d137-ae6f-4733-b9c9-dc5c82ce9478', 'f2000002-0000-0000-0000-00000000005d',
   'Oui, sans aucune restriction',
   'false', '1'),

  ('8547b2b5-d085-4b9a-a54d-0ceced2123af', 'f2000002-0000-0000-0000-00000000005d',
   'Non, jamais sous aucune condition',
   'false', '2'),

  ('bae3f81c-678a-4053-9451-6392a72d857c', 'f2000002-0000-0000-0000-00000000005d',
   'Uniquement les ministres',
   'false', '3'),

  ('3e71d2e1-c198-4fc2-b27d-4ba1706268a2', 'f2000002-0000-0000-0000-00000000005e',
   'Il est protégé pendant le mandat, sauf destitution par la Haute Cour',
   'true', '0'),

  ('e823d5b5-80c4-49fe-8b7d-c3ca3666d9d0', 'f2000002-0000-0000-0000-00000000005e',
   'Oui, comme tout citoyen',
   'false', '1'),

  ('065dd6b8-2213-4f4d-bc8e-e0ddae39ecbf', 'f2000002-0000-0000-0000-00000000005e',
   'Non, jamais à vie',
   'false', '2'),

  ('63e1a1e2-305a-413f-89c5-6f310c345f9b', 'f2000002-0000-0000-0000-00000000005e',
   'Oui, par le pape',
   'false', '3'),

  ('09e5485d-2e54-4457-a8cc-34009d323e9a', 'f2000002-0000-0000-0000-00000000005f',
   'Saisir le conseil des prud''hommes',
   'true', '0'),

  ('9141fddd-5a54-4f0b-9060-1b3e9c8d3dbf', 'f2000002-0000-0000-0000-00000000005f',
   'Saisir le Conseil constitutionnel',
   'false', '1'),

  ('ce44852b-53ac-4b66-8871-bb3e0af95bf3', 'f2000002-0000-0000-0000-00000000005f',
   'Demander au pape',
   'false', '2'),

  ('64bb62d8-3bdd-45a6-a90c-4de5d7de16c9', 'f2000002-0000-0000-0000-00000000005f',
   'Aucun recours possible',
   'false', '3'),

  ('22531ed1-117c-4430-95d4-f3b0964ab3d8', 'f2000002-0000-0000-0000-000000000061',
   'Soulever une Question prioritaire de constitutionnalité (QPC)',
   'true', '0'),

  ('3c17ea83-e105-4171-a2ca-d63480ca195c', 'f2000002-0000-0000-0000-000000000061',
   'Réécrire moi-même la Constitution',
   'false', '1'),

  ('dc58e839-889f-4fc7-9d15-61266aae252d', 'f2000002-0000-0000-0000-000000000061',
   'Saisir une église',
   'false', '2'),

  ('7a670f81-10e8-49bd-8787-812feb710312', 'f2000002-0000-0000-0000-000000000061',
   'Aucune action possible',
   'false', '3'),

  ('d468ecee-feb5-410b-b8cd-6da430a80acf', 'f2000002-0000-0000-0000-000000000062',
   'Adhérer à un parti, une association, participer à des consultations',
   'true', '0'),

  ('77c4de55-600a-4e4d-96c2-5625f91fe803', 'f2000002-0000-0000-0000-000000000062',
   'Forcer la porte de l''Élysée',
   'false', '1'),

  ('35e8d1d9-5821-426f-bb16-9d54602453cc', 'f2000002-0000-0000-0000-000000000062',
   'Acheter un mandat de député',
   'false', '2'),

  ('63902939-e74c-43b1-9765-da4305c4721b', 'f2000002-0000-0000-0000-000000000062',
   'Rien hors du vote n''est possible',
   'false', '3'),

  ('afd55a3a-85c8-4e45-aebe-57e8dffc86f8', 'f2000002-0000-0000-0000-000000000063',
   'Saisir le Défenseur des droits ou le tribunal administratif',
   'true', '0'),

  ('20334e70-1eee-4429-83b0-37d75e9441e8', 'f2000002-0000-0000-0000-000000000063',
   'Forcer l''accès avec un huissier',
   'false', '1'),

  ('f9469d77-b1b9-4378-b659-84f3bd747ff7', 'f2000002-0000-0000-0000-000000000063',
   'Renoncer immédiatement',
   'false', '2'),

  ('b94933fb-9ccf-4c65-934d-2bb85319b817', 'f2000002-0000-0000-0000-000000000063',
   'Écrire au pape',
   'false', '3'),

  ('acdd40fa-d053-4729-987d-564bf9bb374e', 'f2000002-0000-0000-0000-000000000064',
   'Oui, on peut être cité comme témoin par une commission d''enquête',
   'true', '0'),

  ('34f2c6a4-ea7e-4c5f-807f-4d8630bc4f58', 'f2000002-0000-0000-0000-000000000064',
   'Non, c''est strictement réservé aux députés',
   'false', '1'),

  ('e19697d6-4c54-413a-8683-8dbc40a37282', 'f2000002-0000-0000-0000-000000000064',
   'Uniquement les retraités',
   'false', '2'),

  ('173b3735-b0ec-4eb3-961b-c73d70fc9172', 'f2000002-0000-0000-0000-000000000064',
   'Uniquement avec accord de l''Église',
   'false', '3'),

  ('b9e16b9b-f0a3-457d-84ed-434662e56c8c', 'f2000002-0000-0000-0000-000000000065',
   'La Commission du contentieux du stationnement payant',
   'true', '0'),

  ('dfa1f5a9-2994-4f0a-9426-ea4a9afadeb0', 'f2000002-0000-0000-0000-000000000065',
   'La cour d''assises',
   'false', '1'),

  ('e325cc7c-39a6-42eb-9b15-eba1a186eac5', 'f2000002-0000-0000-0000-000000000065',
   'Le Conseil constitutionnel',
   'false', '2'),

  ('66727e53-96aa-4653-92c5-6b7aeeefd7d0', 'f2000002-0000-0000-0000-000000000065',
   'Le tribunal de commerce',
   'false', '3'),

  ('7cf80f67-3fcd-416d-9dbb-9cd77a4d2f8b', 'f2000002-0000-0000-0000-000000000066',
   'Écrire, manifester légalement, voter différemment au scrutin suivant',
   'true', '0'),

  ('b30c7cb8-8e7a-4e90-bc6f-09472ce085df', 'f2000002-0000-0000-0000-000000000066',
   'Le faire arrêter',
   'false', '1'),

  ('6a8dad02-347c-47ba-946c-b4d4369e9ee9', 'f2000002-0000-0000-0000-000000000066',
   'Refuser de payer mes impôts',
   'false', '2'),

  ('dcd8df28-d5e0-400f-a86b-ddc0150359a8', 'f2000002-0000-0000-0000-000000000066',
   'Quitter la France',
   'false', '3'),

  ('8142fe9f-7863-4aee-a984-7a42095ce730', 'f2000002-0000-0000-0000-000000000067',
   'C''est une obligation civique, refuser sans motif est sanctionné',
   'true', '0'),

  ('a3aaffde-94d7-40e8-b7e4-dde480f63920', 'f2000002-0000-0000-0000-000000000067',
   'Oui, c''est facultatif',
   'false', '1'),

  ('7d032750-9595-43d5-934d-0bb5b4d32ff5', 'f2000002-0000-0000-0000-000000000067',
   'Uniquement les femmes y sont obligées',
   'false', '2'),

  ('f8684998-e46a-49a9-b42a-c16493ad3eb8', 'f2000002-0000-0000-0000-000000000067',
   'Uniquement les fonctionnaires',
   'false', '3'),

  ('d6281587-a3e1-460a-b297-6351f0f10f04', 'f2000002-0000-0000-0000-000000000068',
   'Au maire de la commune',
   'true', '0'),

  ('c0506859-c95b-4d99-8294-80a013bdefa5', 'f2000002-0000-0000-0000-000000000068',
   'Au président de la République',
   'false', '1'),

  ('513cd244-a32e-47b8-8c78-539476d7872a', 'f2000002-0000-0000-0000-000000000068',
   'Au pape',
   'false', '2'),

  ('0d82c348-06cc-4e4a-8ab2-d92577f34952', 'f2000002-0000-0000-0000-000000000068',
   'À l''OTAN',
   'false', '3'),

  ('2e065eda-2b73-45ef-9696-dad47e43fb42', 'f2000002-0000-0000-0000-000000000069',
   'Charles de Gaulle et Michel Debré',
   'true', '0'),

  ('f008e283-f47b-460e-8b0c-22dba218c589', 'f2000002-0000-0000-0000-000000000069',
   'Napoléon III',
   'false', '1'),

  ('3083522e-c4ba-4446-a7c6-94e9edbb9587', 'f2000002-0000-0000-0000-000000000069',
   'Robespierre',
   'false', '2'),

  ('11a09be5-ea88-43ba-ab6b-3871fdb4cc2f', 'f2000002-0000-0000-0000-000000000069',
   'François Mitterrand',
   'false', '3'),

  ('5ac2ce91-5095-40b1-8e02-990833254676', 'f2000002-0000-0000-0000-00000000006a',
   'Crise algérienne et instabilité chronique',
   'true', '0'),

  ('1d36f457-c9ed-4b2a-816b-43b6c4c719ff', 'f2000002-0000-0000-0000-00000000006a',
   'Une invasion étrangère',
   'false', '1'),

  ('51b8e320-2f21-449f-a704-64fa35b36bbe', 'f2000002-0000-0000-0000-00000000006a',
   'Un référendum européen',
   'false', '2'),

  ('54806757-aeaf-4d66-8451-0fdc0874c4cc', 'f2000002-0000-0000-0000-00000000006a',
   'Un attentat contre le président',
   'false', '3'),

  ('d80ecdaa-2363-4cb9-97e5-afb743b3ae40', 'f2000002-0000-0000-0000-00000000006b',
   'En 2000',
   'true', '0'),

  ('3793f792-9385-48ad-935d-ee58beccfb1c', 'f2000002-0000-0000-0000-00000000006b',
   'En 1958',
   'false', '1'),

  ('7b193dbb-847c-4269-9ea0-cbe7861711d9', 'f2000002-0000-0000-0000-00000000006b',
   'En 1981',
   'false', '2'),

  ('190c9417-604b-42da-a567-41c7591fc872', 'f2000002-0000-0000-0000-00000000006b',
   'En 2017',
   'false', '3'),

  ('e6a1a973-dfeb-4d5c-ba8f-fa5c6b978ab7', 'f2000002-0000-0000-0000-00000000006c',
   'Charles de Gaulle (1965)',
   'true', '0'),

  ('3dfb7095-8875-4461-8819-bd1a8831959c', 'f2000002-0000-0000-0000-00000000006c',
   'Vincent Auriol',
   'false', '1'),

  ('b4e8a0be-efd9-4aa8-b706-6209f7db0215', 'f2000002-0000-0000-0000-00000000006c',
   'François Mitterrand',
   'false', '2'),

  ('2821258a-98bc-4837-88dd-31cebf935c8e', 'f2000002-0000-0000-0000-00000000006c',
   'Georges Pompidou',
   'false', '3'),

  ('0b07f4a3-7f10-4148-8bfe-8d44d212e75b', 'f2000002-0000-0000-0000-00000000006d',
   'Le référendum de 1962 sur le suffrage direct',
   'true', '0'),

  ('3921eecf-571d-4ac7-beab-55b2ce057a16', 'f2000002-0000-0000-0000-00000000006d',
   'Le référendum sur l''Algérie',
   'false', '1'),

  ('076e2fb1-1cf1-48c4-ba5b-80ce0fa6840f', 'f2000002-0000-0000-0000-00000000006d',
   'Le référendum sur Maastricht',
   'false', '2'),

  ('956a6571-f1c9-4bc3-ab27-6f6095707a55', 'f2000002-0000-0000-0000-00000000006d',
   'Le référendum sur l''euro',
   'false', '3'),

  ('28d61744-adde-4334-9a80-5c0d7de077d9', 'f2000002-0000-0000-0000-00000000006e',
   'Président et Premier ministre de bords opposés',
   'true', '0'),

  ('eecb95fd-8298-4313-8c27-b012d497b6bc', 'f2000002-0000-0000-0000-00000000006e',
   'Deux présidents simultanés',
   'false', '1'),

  ('d797a65e-d642-41e8-9174-1b385a426819', 'f2000002-0000-0000-0000-00000000006e',
   'Un partage de l''Élysée',
   'false', '2'),

  ('5493dd6d-2b14-424c-b3bb-d25d5a79a29f', 'f2000002-0000-0000-0000-00000000006e',
   'Un meeting commun',
   'false', '3'),

  ('d70de892-8f8f-47b5-893a-76eec521a4c6', 'f2000002-0000-0000-0000-00000000006f',
   'L''article 16',
   'true', '0'),

  ('3f19c908-f3fd-4e4e-a4a2-1e8cf5c4c46d', 'f2000002-0000-0000-0000-00000000006f',
   'L''article 49',
   'false', '1'),

  ('5d0e308a-7f3d-4171-93cb-aa05a2ee553e', 'f2000002-0000-0000-0000-00000000006f',
   'L''article 89',
   'false', '2'),

  ('d7d3e415-5b0f-48d6-a18b-bd27ff51e93b', 'f2000002-0000-0000-0000-00000000006f',
   'L''article 1er',
   'false', '3'),

  ('5b2ccb5e-9164-41ac-ab6a-379edbacf6b2', 'f2000002-0000-0000-0000-000000000070',
   'Une seule fois (en 1961)',
   'true', '0'),

  ('d8e2fed7-2da3-4112-94f3-f4616600a1c8', 'f2000002-0000-0000-0000-000000000070',
   'Jamais',
   'false', '1'),

  ('d558a238-eb38-43a8-b54b-ec05a5344e99', 'f2000002-0000-0000-0000-000000000070',
   'Dix fois',
   'false', '2'),

  ('449343f9-2158-49c3-84ef-8098798fc30e', 'f2000002-0000-0000-0000-000000000070',
   'À chaque crise',
   'false', '3');
