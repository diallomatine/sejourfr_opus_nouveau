-- ============================================================================
-- V243 — Civique : Droits et devoirs (lot 3)
-- ----------------------------------------------------------------------------
-- Questions + choix. Filtre: 11111111-0000-0000-0000-000000000003 .
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('f3000002-0000-0000-0000-000000000029', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Je vois quelqu''un en train de voler dans un magasin. Que faire ?',
   'Vous pouvez prévenir le personnel du magasin ou la police (17). Ne tentez pas d''intervenir physiquement vous-même : c''est dangereux et l''intervention revient aux professionnels.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000002a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Je suis témoin d''un accident de la route. Que dois-je faire ?',
   'Sécuriser la zone, appeler les secours (112, 15, 18), porter assistance dans la limite de ses capacités et attendre les autorités. Ne pas déplacer les victimes sauf danger imminent.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000002b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Mon voisin fait du bruit toute la nuit. Quel recours ?',
   'On peut d''abord essayer le dialogue. Sinon : prévenir la mairie ou la police, demander un constat par huissier en cas de nuisances répétées, ou saisir le tribunal.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000002c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Un inconnu prend des photos de mes enfants dans un parc. Que faire ?',
   'Demandez-lui de cesser et de supprimer les photos. Si refus, prévenez la police : la prise de vue et la diffusion d''images de mineurs sans accord parental sont pénalement sanctionnées.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000002d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Je suis contrôlé par un policier. Quels droits dois-je connaître ?',
   'Vous devez présenter une pièce d''identité si demandée. Vous avez le droit de demander la raison du contrôle, d''être traité avec respect, et de ne pas être fouillé sans cadre légal.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000002e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Je découvre qu''un colis livré n''est pas le mien et contient de l''argent. Que faire ?',
   'Il faut le remettre au transporteur, à la police ou à la mairie. Garder un objet qui ne vous appartient pas est un délit (recel ou abus de confiance).',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000002f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Mon employeur me demande de travailler le dimanche sans paie supplémentaire. Est-ce légal ?',
   'Le travail dominical est encadré. Selon la convention collective, il peut donner droit à une majoration salariale ou un repos compensateur. Refuser le paiement majoré peut être contesté aux prud''hommes.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000030', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Je veux divorcer mais mon conjoint refuse. Est-ce possible ?',
   'Oui. Même sans le consentement de l''autre conjoint, le divorce reste possible : divorce pour faute, divorce pour altération définitive du lien conjugal (après 1 an de séparation), divorce pour acceptation.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000031', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Un voisin me menace verbalement et physiquement. Que faire ?',
   'Notez les faits par écrit avec dates et heures. Allez déposer plainte au commissariat ou en gendarmerie. Si besoin urgent, appelez le 17.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000032', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Je suis témoin d''un acte raciste dans la rue. Quel comportement adopter ?',
   'On peut soutenir la victime, appeler la police (17), recueillir des témoignages. Les actes racistes sont des délits que la loi punit sévèrement.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000033', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que prévoit l''article 1er de la DDHC de 1789 ?',
   'L''article 1er de la Déclaration de 1789 énonce : ''Les hommes naissent et demeurent libres et égaux en droits.'' Il pose le principe d''égalité et de liberté.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000034', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quels sont les droits naturels imprescriptibles selon la DDHC de 1789 ?',
   'L''article 2 de la DDHC de 1789 cite quatre droits naturels et imprescriptibles : la liberté, la propriété, la sûreté (sécurité) et la résistance à l''oppression.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000035', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que stipule l''article 4 de la DDHC sur la liberté ?',
   'L''article 4 énonce : ''La liberté consiste à pouvoir faire tout ce qui ne nuit pas à autrui''. Elle s''arrête là où commence celle des autres.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000036', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le droit à la présomption d''innocence figure-t-il dans la DDHC ?',
   'Oui. L''article 9 dispose : ''Tout homme étant présumé innocent jusqu''à ce qu''il ait été déclaré coupable...'' C''est un principe fondamental du droit pénal français.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000037', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que dit la DDHC concernant l''égalité devant la loi ?',
   'L''article 6 dispose que ''la loi est l''expression de la volonté générale'' et que ''tous les citoyens sont égaux à ses yeux''. C''est le principe d''égalité devant la loi.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000038', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel article de la DDHC établit la liberté d''expression ?',
   'L''article 11 de la DDHC dispose que ''la libre communication des pensées et des opinions est un des droits les plus précieux de l''homme''. C''est le fondement de la liberté d''expression.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000039', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'La liberté d''expression est-elle absolue selon le droit français ?',
   'Non. La liberté d''expression est limitée par la loi (injure, diffamation, incitation à la haine, apologie du terrorisme, atteinte à la vie privée). Ces limites visent à protéger autrui.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000003a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel principe protège le secret des correspondances ?',
   'L''inviolabilité des correspondances est un droit fondamental. Ouvrir le courrier d''autrui, intercepter ses communications ou pirater ses comptes est un délit puni pénalement.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000003b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le droit à la vie privée est-il protégé en France ?',
   'Oui. L''article 9 du Code civil dispose que ''chacun a droit au respect de sa vie privée''. Sa violation peut donner lieu à des dommages et intérêts et à des sanctions pénales.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000003c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que prévoit le droit à l''image ?',
   'Le droit à l''image protège chacun contre l''utilisation non autorisée de son image. La diffusion sans consentement peut donner lieu à des dommages et intérêts et à une condamnation pénale.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000003d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le droit à un procès équitable est-il garanti en France ?',
   'Oui. Il est garanti par la Constitution, la DDHC et la Convention européenne des droits de l''homme (article 6). Il comprend l''accès au juge, l''égalité des armes, la présomption d''innocence, le droit à la défense.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000003e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que prévoit le principe de légalité des délits et des peines ?',
   'Article 8 de la DDHC : ''Nul ne peut être puni qu''en vertu d''une loi établie et promulguée antérieurement au délit''. Une infraction et sa peine doivent être prévues par la loi.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000003f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que désigne la présomption d''innocence ?',
   'La présomption d''innocence signifie qu''une personne est considérée innocente tant qu''elle n''a pas été jugée coupable définitivement. C''est la charge de la preuve qui incombe à l''accusation.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000040', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel est le délai général de prescription pour les délits en France ?',
   'Le délai de prescription pour les délits est de 6 ans depuis 2017 (porté de 3 à 6 ans par la loi du 27 février 2017). Au-delà, l''action publique ne peut plus être exercée.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000041', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'La torture est-elle interdite par la loi française ?',
   'Oui. La torture, les traitements inhumains ou dégradants sont prohibés par la Constitution, la Convention européenne des droits de l''homme (article 3) et le Code pénal français. C''est une interdiction absolue.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000042', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que désigne la ''liberté d''aller et venir'' ?',
   'C''est la liberté de circuler librement sur le territoire français et de le quitter. C''est un droit fondamental, qui peut être restreint par la loi (contrôles, mesures judiciaires).',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000043', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le droit d''asile est-il reconnu en France ?',
   'Oui. La France accorde l''asile aux personnes persécutées dans leur pays en raison de leur action en faveur de la liberté (préambule de la Constitution de 1946). L''OFPRA traite les demandes.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000044', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que le droit à la dignité humaine ?',
   'Le principe de dignité humaine, principe constitutionnel depuis 1994, protège chaque personne de toute atteinte dégradant sa condition d''être humain. Il fonde de nombreux droits fondamentaux.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000045', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quels sont les droits sociaux fondamentaux en France ?',
   'Le préambule de 1946 reconnaît notamment : le droit à la santé, à l''éducation, au travail, à la sécurité matérielle, au logement, à la participation à la gestion des entreprises.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000046', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que prévoit le droit au logement opposable (DALO) ?',
   'La loi DALO de 2007 reconnaît un droit au logement décent. Les personnes en difficulté peuvent saisir une commission de médiation, voire le tribunal pour faire valoir ce droit.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000047', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'L''aide juridictionnelle existe-t-elle pour les justiciables modestes ?',
   'Oui. L''aide juridictionnelle, totale ou partielle, est accordée aux personnes dont les revenus ne dépassent pas un certain plafond. Elle permet de payer les frais d''avocat et de procès.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000048', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'L''esclavage est-il considéré comme un crime contre l''humanité en droit français ?',
   'Oui. La loi Taubira de 2001 reconnaît la traite négrière et l''esclavage comme crimes contre l''humanité. Le 10 mai est journée nationale de commémoration.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000049', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que dit la loi sur la haine en ligne ?',
   'Les propos haineux (racistes, sexistes, homophobes, etc.) sur internet relèvent du droit pénal français (loi de 1881 sur la presse). Les plateformes ont aussi des obligations de modération (loi Avia/DSA).',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000004a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que la double peine pour un étranger ?',
   'La double peine désigne la situation où un étranger condamné à une peine de prison est ensuite expulsé du territoire français. La loi de 2003 a limité cette pratique mais pas supprimée.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000004b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Une victime peut-elle bénéficier d''aides spécifiques en France ?',
   'Oui. Les victimes peuvent être indemnisées par la Commission d''indemnisation des victimes d''infractions (CIVI), bénéficier d''un accompagnement par des associations (France Victimes au 116 006).',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000004c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quels sont les principaux devoirs du citoyen français ?',
   'Respecter la loi, payer ses impôts, accomplir les obligations militaires (Journée défense et citoyenneté), défendre la patrie, être solidaire, respecter les autres et l''environnement.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000004d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'La Journée défense et citoyenneté est-elle obligatoire pour les jeunes Français ?',
   'Oui. Tous les jeunes français (filles et garçons) doivent participer à la Journée défense et citoyenneté (JDC) entre 16 et 25 ans. C''est une condition pour passer le permis ou les concours.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000004e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que représente la Charte de l''environnement de 2004 ?',
   'La Charte de l''environnement, adossée à la Constitution depuis 2005, reconnaît le droit à un environnement sain et l''obligation pour chacun de protéger l''environnement.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000004f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel principe environnemental impose de prévenir les dommages graves à l''environnement ?',
   'Le principe de précaution (article 5 de la Charte de l''environnement) impose des mesures provisoires pour prévenir un risque grave de dommage à l''environnement, même en cas d''incertitude scientifique.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000050', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le harcèlement moral au travail est-il sanctionné ?',
   'Oui. Le harcèlement moral est un délit puni par le Code du travail et le Code pénal (article 222-33-2). La victime peut saisir les prud''hommes et porter plainte.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000051', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le harcèlement sexuel est-il interdit en France ?',
   'Oui. Le harcèlement sexuel est un délit (article 222-33 du Code pénal) puni de 2 ans de prison et 30 000 EUR d''amende, plus selon les circonstances (mineur, autorité, etc.).',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000052', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le droit à la mort digne (fin de vie) existe-t-il en France ?',
   'La loi Claeys-Leonetti (2016) reconnaît le droit à une sédation profonde et continue pour les malades en fin de vie. L''euthanasie active reste interdite ; un débat parlementaire est en cours sur l''aide à mourir.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000053', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Mon employeur cumule plusieurs comportements de harcèlement moral. Que faire ?',
   'Conservez les preuves (mails, témoignages). Alertez le service RH, les représentants du personnel, l''inspection du travail. Saisissez les prud''hommes. Vous pouvez aussi porter plainte pénalement.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000054', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Je suis victime de discrimination au logement en raison de mon origine. Quel recours ?',
   'Saisissez le Défenseur des droits, déposez plainte pénale (la discrimination au logement est punie de 3 ans de prison et 45 000 EUR d''amende). Une association comme SOS Racisme peut aider.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000055', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Un commerçant refuse de me servir car je porte un signe religieux discret. Est-ce légal ?',
   'Non. Le refus de service fondé sur la religion est une discrimination punie par la loi. Vous pouvez déposer plainte et saisir le Défenseur des droits.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000056', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Un site internet diffuse des photos privées de moi sans consentement. Que faire ?',
   'Vous pouvez demander le retrait au site (procédure prévue par la loi), saisir la CNIL pour les données personnelles, porter plainte (atteinte à la vie privée, droit à l''image) et engager une action civile.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000057', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Mon enfant subit du harcèlement scolaire. Quels recours ?',
   'Alertez immédiatement le directeur d''école, écrivez à l''inspection académique. Le 3018 est dédié au harcèlement scolaire. Une plainte pénale est possible (délit de harcèlement).',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000058', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'MISE_SITUATION',
   'On me réclame une somme d''argent sans justificatif. Comment me défendre ?',
   'Demandez par écrit le détail et le fondement de la créance. En cas de litige, saisissez le tribunal judiciaire (où des litiges < 10 000 EUR sans avocat obligatoire).',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000059', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Mon propriétaire veut m''expulser sans suivre la procédure légale. Est-ce autorisé ?',
   'Non. L''expulsion d''un locataire ne peut se faire que par décision de justice et avec l''intervention d''un huissier. Toute expulsion forcée sans cette procédure est illégale et punie pénalement.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000005a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Je veux signaler un acte de maltraitance sur un animal. Quelles démarches ?',
   'Vous pouvez contacter la SPA ou une autre association de protection animale, prévenir la police ou la gendarmerie. La maltraitance animale est un délit puni (article 521-1 du Code pénal).',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL);

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('1fb6cd26-69d4-4a0b-9759-7bc816f40dfb', 'f3000002-0000-0000-0000-000000000029',
   'Prévenir le personnel ou appeler la police',
   'true', '0'),

  ('e9384b9f-985f-4b1b-ac03-968203ccb265', 'f3000002-0000-0000-0000-000000000029',
   'Voler aussi',
   'false', '1'),

  ('5168f6d3-732d-4ee7-88cb-f4d9a3dfde64', 'f3000002-0000-0000-0000-000000000029',
   'Filmer pour les réseaux sociaux',
   'false', '2'),

  ('09775ed0-8947-4caf-8a11-18ea7bcb9b88', 'f3000002-0000-0000-0000-000000000029',
   'Rester sans rien faire',
   'false', '3'),

  ('15dc1a30-c5dc-4b1a-a6da-65d900774531', 'f3000002-0000-0000-0000-00000000002a',
   'Sécuriser, appeler les secours, porter assistance',
   'true', '0'),

  ('c49962b2-68d2-4641-a1cc-0a4518a41676', 'f3000002-0000-0000-0000-00000000002a',
   'Continuer ma route',
   'false', '1'),

  ('9edc7ae1-ce70-403e-8d5c-d27c9b3b4d49', 'f3000002-0000-0000-0000-00000000002a',
   'Voler les biens des victimes',
   'false', '2'),

  ('b39ab97c-7192-4692-85d1-29c4c7014869', 'f3000002-0000-0000-0000-00000000002a',
   'Filmer la scène pour le partager',
   'false', '3'),

  ('be4c8733-f674-4812-a54a-145426320bba', 'f3000002-0000-0000-0000-00000000002b',
   'Dialogue, mairie/police, voire huissier ou tribunal',
   'true', '0'),

  ('dfbc6e9e-b39f-48a4-9528-6ef4e7a249e3', 'f3000002-0000-0000-0000-00000000002b',
   'Aller le frapper',
   'false', '1'),

  ('9fb3787e-f986-4e83-8891-eaeefa858e38', 'f3000002-0000-0000-0000-00000000002b',
   'Rien faire',
   'false', '2'),

  ('a443f950-6a5b-4819-9ddd-1c5ae64232a1', 'f3000002-0000-0000-0000-00000000002b',
   'Quitter le pays',
   'false', '3'),

  ('f378a53a-38bb-4d0c-bd2b-1c0e5be74f81', 'f3000002-0000-0000-0000-00000000002c',
   'Demander l''arrêt et prévenir la police',
   'true', '0'),

  ('6caf72df-c18b-4dc9-9e5e-8a5f6356afe8', 'f3000002-0000-0000-0000-00000000002c',
   'Sourire et l''encourager',
   'false', '1'),

  ('cf8951d5-3231-4b61-ba7f-26b9aecb29e1', 'f3000002-0000-0000-0000-00000000002c',
   'Le frapper',
   'false', '2'),

  ('58a49f4c-14a8-4d62-a034-b1a6009c7726', 'f3000002-0000-0000-0000-00000000002c',
   'Lui demander un tirage gratuit',
   'false', '3'),

  ('87d002e6-8281-43e4-ada4-4a1582e69c31', 'f3000002-0000-0000-0000-00000000002d',
   'Présenter une pièce d''identité, demander le motif, être traité avec respect',
   'true', '0'),

  ('8e48f90b-b3bb-4b03-b92d-e2e9074b31a9', 'f3000002-0000-0000-0000-00000000002d',
   'Refuser tout dialogue',
   'false', '1'),

  ('cc2d9b0b-f592-4905-8799-d79c861dd5d7', 'f3000002-0000-0000-0000-00000000002d',
   'Frapper le policier',
   'false', '2'),

  ('3e0e2089-d344-4bf0-a6cd-72cf4af310e1', 'f3000002-0000-0000-0000-00000000002d',
   'Mentir sur mon identité',
   'false', '3'),

  ('47b24f64-c4fb-48e6-851b-9b61d72b45d0', 'f3000002-0000-0000-0000-00000000002e',
   'Le remettre à la police, au transporteur ou à la mairie',
   'true', '0'),

  ('98d8c143-b38a-417f-9b68-d3ed00b95358', 'f3000002-0000-0000-0000-00000000002e',
   'Le garder discrètement',
   'false', '1'),

  ('948c35c1-035e-419f-aa8b-47e954486270', 'f3000002-0000-0000-0000-00000000002e',
   'Le vendre rapidement',
   'false', '2'),

  ('2f8638f4-048f-42c2-af27-08d3bb8b8f7a', 'f3000002-0000-0000-0000-00000000002e',
   'Le brûler',
   'false', '3'),

  ('ff7026cd-4a34-4899-9dba-2dcc22c849c2', 'f3000002-0000-0000-0000-00000000002f',
   'C''est encadré par la loi et la convention collective ; saisir les prud''hommes au besoin',
   'true', '0'),

  ('2dd5d52e-6abd-4d5f-b44a-31699f44b5c8', 'f3000002-0000-0000-0000-00000000002f',
   'Accepter sans discussion',
   'false', '1'),

  ('d7af86cc-d79b-4076-9410-34662cace2e2', 'f3000002-0000-0000-0000-00000000002f',
   'Démissionner immédiatement',
   'false', '2'),

  ('61c4fa61-a4e4-4412-a823-75088b888f03', 'f3000002-0000-0000-0000-00000000002f',
   'Faire grève seul',
   'false', '3'),

  ('67ecd3a8-0344-40d6-8b2a-02503e2e028e', 'f3000002-0000-0000-0000-000000000030',
   'Oui, plusieurs formes de divorce existent même sans accord',
   'true', '0'),

  ('1acd0c7d-7e44-4166-9682-03de6674a35c', 'f3000002-0000-0000-0000-000000000030',
   'Non, l''accord est obligatoire',
   'false', '1'),

  ('be5bf8cd-38d3-476d-b769-2a6424c2b7ba', 'f3000002-0000-0000-0000-000000000030',
   'Uniquement les hommes peuvent demander',
   'false', '2'),

  ('4e55c023-0a7c-40fb-8689-e88d27918391', 'f3000002-0000-0000-0000-000000000030',
   'Uniquement après 20 ans',
   'false', '3'),

  ('63923da6-cefa-4150-ab1a-c89b454b1a66', 'f3000002-0000-0000-0000-000000000031',
   'Noter les faits et déposer plainte',
   'true', '0'),

  ('cad4d1cf-df1b-4668-8e68-e2e5d81ce8ac', 'f3000002-0000-0000-0000-000000000031',
   'Rendre les coups en retour',
   'false', '1'),

  ('912beca8-4b66-4289-b3c0-3d8fdfef986c', 'f3000002-0000-0000-0000-000000000031',
   'Faire comme si de rien n''était',
   'false', '2'),

  ('7e93394e-ff7b-4fd5-acf8-83db71255845', 'f3000002-0000-0000-0000-000000000031',
   'Déménager immédiatement',
   'false', '3'),

  ('4c1d618b-85e3-4b83-b0be-ab1ece03baf5', 'f3000002-0000-0000-0000-000000000032',
   'Soutenir la victime, prévenir la police',
   'true', '0'),

  ('44e06758-7ff6-413e-9cb9-572118ffc3d4', 'f3000002-0000-0000-0000-000000000032',
   'Encourager le raciste',
   'false', '1'),

  ('6574e6e6-9626-4550-a697-acedf8083870', 'f3000002-0000-0000-0000-000000000032',
   'Faire de même',
   'false', '2'),

  ('6283a0d4-92b7-431c-9061-b81fc528b3ce', 'f3000002-0000-0000-0000-000000000032',
   'Filmer pour rire',
   'false', '3'),

  ('8e962e9d-059c-434f-ac75-90a76f3e209b', 'f3000002-0000-0000-0000-000000000033',
   'Que les hommes naissent libres et égaux en droits',
   'true', '0'),

  ('ab9961a4-43b6-4358-a016-e52213f8c247', 'f3000002-0000-0000-0000-000000000033',
   'Que tout est gratuit pour les nobles',
   'false', '1'),

  ('dbcdf2b2-5136-42d6-9def-192fa564ba8d', 'f3000002-0000-0000-0000-000000000033',
   'Que la religion est obligatoire',
   'false', '2'),

  ('c23dc78d-1492-4964-877d-799904945569', 'f3000002-0000-0000-0000-000000000033',
   'Que la France est un royaume',
   'false', '3'),

  ('55a28862-c9c3-44a9-b027-caf0609f9051', 'f3000002-0000-0000-0000-000000000034',
   'Liberté, propriété, sûreté et résistance à l''oppression',
   'true', '0'),

  ('ca47ce7d-ff3c-4c55-9df6-e899373feee9', 'f3000002-0000-0000-0000-000000000034',
   'Travail, famille, patrie',
   'false', '1'),

  ('eb37ba4b-1622-48d8-9615-7e3713224f28', 'f3000002-0000-0000-0000-000000000034',
   'Santé, éducation, retraite',
   'false', '2'),

  ('4e3a4746-9acf-4bba-8808-234e4392379c', 'f3000002-0000-0000-0000-000000000034',
   'Vote, éligibilité, éducation',
   'false', '3'),

  ('6505262f-d5ad-497b-b76f-81be77c51dc0', 'f3000002-0000-0000-0000-000000000035',
   'La liberté est de faire ce qui ne nuit pas à autrui',
   'true', '0'),

  ('f77be00c-e799-4059-a567-74013cd3c3c5', 'f3000002-0000-0000-0000-000000000035',
   'La liberté est totale sans limite',
   'false', '1'),

  ('9dd3501c-f60a-4d59-a0b9-9cd1ea034747', 'f3000002-0000-0000-0000-000000000035',
   'La liberté est réservée aux nobles',
   'false', '2'),

  ('5cb311d4-7be6-4125-92c9-c2baccfe4925', 'f3000002-0000-0000-0000-000000000035',
   'La liberté est définie par le pape',
   'false', '3'),

  ('12c5af56-6a9b-4d36-8524-2602d514590e', 'f3000002-0000-0000-0000-000000000036',
   'Oui, article 9 de la DDHC',
   'true', '0'),

  ('5e6ae9a9-59ad-44c4-b23b-360e51491c14', 'f3000002-0000-0000-0000-000000000036',
   'Non, c''est une invention récente',
   'false', '1'),

  ('eb0e3fe0-aac8-44f6-9595-02e3c9efdfa0', 'f3000002-0000-0000-0000-000000000036',
   'Non, c''est un principe religieux',
   'false', '2'),

  ('462b3b9e-825a-4289-b4c9-363d555ae5b2', 'f3000002-0000-0000-0000-000000000036',
   'Oui, mais réservé aux Français',
   'false', '3'),

  ('a24c2a00-b55a-424e-b066-7dc4d293f7f9', 'f3000002-0000-0000-0000-000000000037',
   'Tous les citoyens sont égaux devant la loi',
   'true', '0'),

  ('7008d6db-47b3-4e2a-ade3-5eb2aabfb2d5', 'f3000002-0000-0000-0000-000000000037',
   'La loi varie selon la classe sociale',
   'false', '1'),

  ('f190efaf-7195-40b0-9737-22d92f1ae67d', 'f3000002-0000-0000-0000-000000000037',
   'La loi est différente pour les hommes et les femmes',
   'false', '2'),

  ('9e6b0c64-3a9c-40fd-9fa0-3db200cd30e4', 'f3000002-0000-0000-0000-000000000037',
   'La loi favorise les militaires',
   'false', '3'),

  ('fa2f05d1-0139-4f7c-a804-b80ea22c5f0e', 'f3000002-0000-0000-0000-000000000038',
   'L''article 11',
   'true', '0'),

  ('969cfa3a-417d-4a55-b5a1-ea0bb5e1b5ee', 'f3000002-0000-0000-0000-000000000038',
   'L''article 1er',
   'false', '1'),

  ('c5d76f65-a3f5-411d-87bd-1b720a22a6d7', 'f3000002-0000-0000-0000-000000000038',
   'L''article 17',
   'false', '2'),

  ('7d3fe247-f3c5-431b-bb75-64c9db2a8c10', 'f3000002-0000-0000-0000-000000000038',
   'Aucun article ne le prévoit',
   'false', '3'),

  ('5c52645a-7178-4677-beb4-37eb5d270405', 'f3000002-0000-0000-0000-000000000039',
   'Non, elle est encadrée par la loi',
   'true', '0'),

  ('9f9d9139-18a5-4011-b98f-fd4752733e4a', 'f3000002-0000-0000-0000-000000000039',
   'Oui, totalement absolue',
   'false', '1'),

  ('028cd5d8-81e9-470b-be8e-f7501da72654', 'f3000002-0000-0000-0000-000000000039',
   'Uniquement pour la presse',
   'false', '2'),

  ('bed61c9d-4fcd-4d43-bb77-7b12df2cba42', 'f3000002-0000-0000-0000-000000000039',
   'Uniquement dans les universités',
   'false', '3'),

  ('fe6be73d-c024-4dcd-935c-1648c2d32406', 'f3000002-0000-0000-0000-00000000003a',
   'L''inviolabilité des correspondances',
   'true', '0'),

  ('ee761b1e-2553-42e2-8296-702217c203b4', 'f3000002-0000-0000-0000-00000000003a',
   'Le droit à la propriété',
   'false', '1'),

  ('40287f60-db30-49ac-a4c0-79f94f8f8acb', 'f3000002-0000-0000-0000-00000000003a',
   'Le droit à la santé',
   'false', '2'),

  ('09c7b098-895f-4367-adae-ddc18d10f7d9', 'f3000002-0000-0000-0000-00000000003a',
   'Le droit à la retraite',
   'false', '3'),

  ('5875d6d8-c00e-49ac-a1f6-d14b54df7619', 'f3000002-0000-0000-0000-00000000003b',
   'Oui, article 9 du Code civil',
   'true', '0'),

  ('e389e6a1-bb8b-4e3b-b4eb-ae464b5ce324', 'f3000002-0000-0000-0000-00000000003b',
   'Non, c''est aboli',
   'false', '1'),

  ('5609e716-9aba-4461-820f-05dd40f29f4d', 'f3000002-0000-0000-0000-00000000003b',
   'Uniquement pour les célébrités',
   'false', '2'),

  ('c352977c-5a2e-4aa7-b2af-247dad1e0e37', 'f3000002-0000-0000-0000-00000000003b',
   'Uniquement dans les hôpitaux',
   'false', '3'),

  ('986b8911-5fe5-4afb-8719-8d1d337654c4', 'f3000002-0000-0000-0000-00000000003c',
   'Le consentement est requis pour utiliser l''image d''une personne',
   'true', '0'),

  ('1831d989-77bf-4274-9b4e-d289b02c927b', 'f3000002-0000-0000-0000-00000000003c',
   'Toute image peut être librement diffusée',
   'false', '1'),

  ('4a173b40-eba8-4ab8-b07c-4b4f9981b9f0', 'f3000002-0000-0000-0000-00000000003c',
   'Uniquement pour les enfants',
   'false', '2'),

  ('027256e3-609f-4498-950c-15c282073d82', 'f3000002-0000-0000-0000-00000000003c',
   'Uniquement les images publiques',
   'false', '3'),

  ('77359a53-f943-4104-99f4-11649d3b9607', 'f3000002-0000-0000-0000-00000000003d',
   'Oui, garanti par la Constitution et la CEDH',
   'true', '0'),

  ('cf36f03c-9a2f-485c-b214-e964e7b49b8c', 'f3000002-0000-0000-0000-00000000003d',
   'Non, c''est une formalité',
   'false', '1'),

  ('644669f7-6ebc-4e10-b316-4cc60fcb7723', 'f3000002-0000-0000-0000-00000000003d',
   'Uniquement pour les Français',
   'false', '2'),

  ('b38f66dd-aaad-4f05-b118-76bc014e3a5b', 'f3000002-0000-0000-0000-00000000003d',
   'Uniquement en matière civile',
   'false', '3'),

  ('7aceeed8-3286-4543-b4af-d2c5eb26fb4e', 'f3000002-0000-0000-0000-00000000003e',
   'Nul ne peut être puni sans loi préalable (article 8 DDHC)',
   'true', '0'),

  ('338869e6-eb87-4e95-b8f6-91f114039aa3', 'f3000002-0000-0000-0000-00000000003e',
   'Le juge crée les peines',
   'false', '1'),

  ('fe4acf74-96ac-46f5-9794-d77f1e6d9a4c', 'f3000002-0000-0000-0000-00000000003e',
   'Le pape détermine les délits',
   'false', '2'),

  ('134ea2f9-42f8-4e33-9313-5b4c324b5537', 'f3000002-0000-0000-0000-00000000003e',
   'Aucune règle n''existe',
   'false', '3'),

  ('80fc58df-c6d2-42a7-a3a1-7506f99379d4', 'f3000002-0000-0000-0000-00000000003f',
   'L''accusé est présumé innocent jusqu''à condamnation définitive',
   'true', '0'),

  ('9c2e1e98-8fc9-4b1c-8192-c5192245dd8c', 'f3000002-0000-0000-0000-00000000003f',
   'L''accusé doit prouver son innocence',
   'false', '1'),

  ('5c8452bf-1275-44dc-93ad-514e523cd9fe', 'f3000002-0000-0000-0000-00000000003f',
   'L''accusé est coupable par défaut',
   'false', '2'),

  ('8e3d4d85-c3bc-426a-8247-776740b0b369', 'f3000002-0000-0000-0000-00000000003f',
   'L''accusé est ignoré par la justice',
   'false', '3'),

  ('23576f63-ef8a-443d-9e96-fd4c48a5c258', 'f3000002-0000-0000-0000-000000000040',
   '6 ans depuis 2017',
   'true', '0'),

  ('dcb40243-85a8-439b-8996-77e198df1423', 'f3000002-0000-0000-0000-000000000040',
   '10 ans toujours',
   'false', '1'),

  ('5cfd84a6-a3b2-449f-8061-b3388546c4be', 'f3000002-0000-0000-0000-000000000040',
   '30 jours',
   'false', '2'),

  ('9dcca33a-0f70-4d52-bc86-916cbea71914', 'f3000002-0000-0000-0000-000000000040',
   'Aucune prescription',
   'false', '3'),

  ('6b26a4d1-c57e-4395-9b76-96056ba30bc9', 'f3000002-0000-0000-0000-000000000041',
   'Oui, c''est interdit de façon absolue',
   'true', '0'),

  ('02cfdd26-408e-4373-b88f-866bb9106669', 'f3000002-0000-0000-0000-000000000041',
   'Non, sous certaines conditions',
   'false', '1'),

  ('2a66a0eb-8f04-4e0e-ab08-0374e7c17f7a', 'f3000002-0000-0000-0000-000000000041',
   'Uniquement en temps de paix',
   'false', '2'),

  ('df59f3f5-288f-4eee-aed3-bb1269e89eca', 'f3000002-0000-0000-0000-000000000041',
   'Uniquement pour les Français',
   'false', '3'),

  ('5ea039eb-bfdd-4dad-ab2b-6fb985cd009c', 'f3000002-0000-0000-0000-000000000042',
   'La liberté de circuler et de quitter le territoire',
   'true', '0'),

  ('95bb6ddc-57d5-4a5d-8adf-896fb7ffa27d', 'f3000002-0000-0000-0000-000000000042',
   'La liberté religieuse',
   'false', '1'),

  ('6564651f-fb58-4d51-a5ef-83f0d7f95801', 'f3000002-0000-0000-0000-000000000042',
   'La liberté d''opinion',
   'false', '2'),

  ('0efc59e0-2e50-469d-8fab-8d3d435dae46', 'f3000002-0000-0000-0000-000000000042',
   'La liberté de commerce',
   'false', '3'),

  ('eb95ff29-aa3a-4c1f-8666-cd1c649abfb8', 'f3000002-0000-0000-0000-000000000043',
   'Oui, garanti par le préambule de la Constitution',
   'true', '0'),

  ('17a7f078-dd24-42f6-b8ee-3f2a23036f41', 'f3000002-0000-0000-0000-000000000043',
   'Non, c''est interdit',
   'false', '1'),

  ('7f79631e-20d6-49fa-9349-c008b0ee2d59', 'f3000002-0000-0000-0000-000000000043',
   'Uniquement aux Européens',
   'false', '2'),

  ('1707c0d6-65a1-4f08-afaf-878241827f70', 'f3000002-0000-0000-0000-000000000043',
   'Uniquement temporairement',
   'false', '3'),

  ('c0628dc4-7fe9-4091-bb34-8fdc0b291179', 'f3000002-0000-0000-0000-000000000044',
   'Un principe constitutionnel protégeant la condition humaine',
   'true', '0'),

  ('1d523812-5506-46d5-9116-b3d7869c28f3', 'f3000002-0000-0000-0000-000000000044',
   'Un avantage fiscal',
   'false', '1'),

  ('8d449497-5f5a-44ad-a203-4918ebbba9f9', 'f3000002-0000-0000-0000-000000000044',
   'Une obligation religieuse',
   'false', '2'),

  ('f6c7b15b-b539-43d4-8711-e065cb5cec19', 'f3000002-0000-0000-0000-000000000044',
   'Un droit réservé aux femmes',
   'false', '3'),

  ('34e0a298-0648-4fb7-9ea5-6742ad8916f3', 'f3000002-0000-0000-0000-000000000045',
   'Droit à la santé, éducation, travail, sécurité matérielle',
   'true', '0'),

  ('b7602d3d-4a9e-4ee5-a46e-4fc1fc830cf1', 'f3000002-0000-0000-0000-000000000045',
   'Aucun droit social',
   'false', '1'),

  ('26e56163-aaa7-4687-8077-fb8483aebf8c', 'f3000002-0000-0000-0000-000000000045',
   'Uniquement le droit à l''argent',
   'false', '2'),

  ('2b1338fc-20f6-48af-9122-660f8d7f81e5', 'f3000002-0000-0000-0000-000000000045',
   'Droits réservés aux militaires',
   'false', '3'),

  ('bde97720-2ff8-4d20-9dfc-830e0e438a77', 'f3000002-0000-0000-0000-000000000046',
   'Un recours légal pour obtenir un logement décent',
   'true', '0'),

  ('58f6fb3b-06d1-47ec-83da-1de60e3aef5c', 'f3000002-0000-0000-0000-000000000046',
   'L''attribution automatique d''un logement',
   'false', '1'),

  ('dd00ba2f-5277-4ee8-b765-e72b5078364a', 'f3000002-0000-0000-0000-000000000046',
   'Un droit réservé aux fonctionnaires',
   'false', '2'),

  ('6bdc12f4-cbab-4052-b34c-1c151e2c2a42', 'f3000002-0000-0000-0000-000000000046',
   'Un droit européen non transposé',
   'false', '3'),

  ('d1ad80d9-f1aa-434d-86bf-ff0297f50b9c', 'f3000002-0000-0000-0000-000000000047',
   'Oui, sous conditions de ressources',
   'true', '0'),

  ('31a465a5-c363-4940-87eb-9374ecdc4ff7', 'f3000002-0000-0000-0000-000000000047',
   'Non, c''est payé par tous',
   'false', '1'),

  ('68a0210a-8bfd-4c05-8ba5-a5befb0d18c5', 'f3000002-0000-0000-0000-000000000047',
   'Uniquement pour les retraités',
   'false', '2'),

  ('25967768-b100-4365-9cde-19c8a19aa041', 'f3000002-0000-0000-0000-000000000047',
   'Uniquement pour les Français',
   'false', '3'),

  ('0352bb7a-635c-46e9-8084-c451c7242d49', 'f3000002-0000-0000-0000-000000000048',
   'Oui, depuis la loi Taubira de 2001',
   'true', '0'),

  ('043c5ac6-c56a-40a7-bc06-694ade24c566', 'f3000002-0000-0000-0000-000000000048',
   'Non, c''est un simple délit',
   'false', '1'),

  ('f582612b-c556-4094-adbd-5cbb6e658d9b', 'f3000002-0000-0000-0000-000000000048',
   'Uniquement en outre-mer',
   'false', '2'),

  ('383a35c0-7ef8-4290-8e68-ce330ee20fe6', 'f3000002-0000-0000-0000-000000000048',
   'Uniquement pour le 19e siècle',
   'false', '3'),

  ('eee9b26a-48ae-4c18-a175-d6e614d95551', 'f3000002-0000-0000-0000-000000000049',
   'Punis par la loi de 1881 et la régulation des plateformes',
   'true', '0'),

  ('922a1fc9-18e8-4885-af1c-e073b4985b25', 'f3000002-0000-0000-0000-000000000049',
   'Liberté totale sur internet',
   'false', '1'),

  ('9dab0905-127c-4eb6-bceb-18a7490ae7c7', 'f3000002-0000-0000-0000-000000000049',
   'Uniquement les commentaires anonymes',
   'false', '2'),

  ('9fe329d8-6268-45a8-8a51-fc3c9e2a3abe', 'f3000002-0000-0000-0000-000000000049',
   'Uniquement entre adultes',
   'false', '3'),

  ('e1888243-1d90-46ed-8e4d-54e5be25fcca', 'f3000002-0000-0000-0000-00000000004a',
   'Une peine de prison suivie d''une expulsion du territoire',
   'true', '0'),

  ('e13f2377-3420-4be6-8695-03c4df107d97', 'f3000002-0000-0000-0000-00000000004a',
   'Deux peines successives à domicile',
   'false', '1'),

  ('4483dd8e-5eaa-4ee6-8105-c6e71cc8fd10', 'f3000002-0000-0000-0000-00000000004a',
   'Une amende doublée',
   'false', '2'),

  ('1a065515-261e-432a-9b18-1372907d2c08', 'f3000002-0000-0000-0000-00000000004a',
   'Une peine annulée',
   'false', '3'),

  ('4309f0a0-ca83-4a8f-855e-5247fc974ae6', 'f3000002-0000-0000-0000-00000000004b',
   'Oui, via la CIVI et les associations (116 006)',
   'true', '0'),

  ('e64b7db5-f5cc-4572-bde7-d5a58d3b9856', 'f3000002-0000-0000-0000-00000000004b',
   'Non, aucune aide n''existe',
   'false', '1'),

  ('6e4f49ca-0a2f-41dd-9b90-84c5b4bd3396', 'f3000002-0000-0000-0000-00000000004b',
   'Uniquement les Français',
   'false', '2'),

  ('41eb1a75-d5c3-4e66-ade3-d1f894df099e', 'f3000002-0000-0000-0000-00000000004b',
   'Uniquement les adultes',
   'false', '3'),

  ('8f15b393-d584-41c6-b609-c7064eb2ebce', 'f3000002-0000-0000-0000-00000000004c',
   'Respecter la loi, payer ses impôts, être solidaire',
   'true', '0'),

  ('7bf1aef9-834f-4ae3-ace0-0fd118f942f1', 'f3000002-0000-0000-0000-00000000004c',
   'Aucun devoir',
   'false', '1'),

  ('946dbd89-ec5d-4c94-b052-422849d879f4', 'f3000002-0000-0000-0000-00000000004c',
   'Uniquement servir l''armée',
   'false', '2'),

  ('0a43083b-45e2-42e9-9a22-e21d2ad698ec', 'f3000002-0000-0000-0000-00000000004c',
   'Uniquement assister aux cérémonies',
   'false', '3'),

  ('766af248-e4e3-4a98-891f-78cdf8f10365', 'f3000002-0000-0000-0000-00000000004d',
   'Oui, entre 16 et 25 ans',
   'true', '0'),

  ('dbda82bd-c49b-4885-b21d-81b980275396', 'f3000002-0000-0000-0000-00000000004d',
   'Non, c''est facultatif',
   'false', '1'),

  ('579abf38-8e1b-4570-b377-a7af5d28708e', 'f3000002-0000-0000-0000-00000000004d',
   'Uniquement les garçons',
   'false', '2'),

  ('761fa7e2-6289-4b0b-a99f-3f025aa75b16', 'f3000002-0000-0000-0000-00000000004d',
   'Uniquement les filles',
   'false', '3'),

  ('67699a43-1f8f-4927-ad69-a7b1f1831eed', 'f3000002-0000-0000-0000-00000000004e',
   'Le droit à un environnement sain et le devoir de le protéger',
   'true', '0'),

  ('9f18f0ab-6f10-4cdf-a808-673dc31f8743', 'f3000002-0000-0000-0000-00000000004e',
   'Une charte facultative',
   'false', '1'),

  ('29369336-c4bd-4089-950d-e908f93a9574', 'f3000002-0000-0000-0000-00000000004e',
   'Un texte sans valeur juridique',
   'false', '2'),

  ('f4fafec8-4e92-4c4d-a293-e8581f83e647', 'f3000002-0000-0000-0000-00000000004e',
   'Une loi européenne uniquement',
   'false', '3'),

  ('eccc0868-6d7e-450c-a23d-d8a14dfbf7ee', 'f3000002-0000-0000-0000-00000000004f',
   'Le principe de précaution (Charte de l''environnement)',
   'true', '0'),

  ('1484d1ed-85ab-4c01-9978-15f7bb92d4ab', 'f3000002-0000-0000-0000-00000000004f',
   'Le principe de proportionnalité',
   'false', '1'),

  ('f1141300-ee26-4103-8bd8-0b2939d62761', 'f3000002-0000-0000-0000-00000000004f',
   'Le principe de neutralité',
   'false', '2'),

  ('025826a6-3bc8-45b3-8e03-b61e8b6de5c1', 'f3000002-0000-0000-0000-00000000004f',
   'Le principe de subsidiarité',
   'false', '3'),

  ('46f394b8-c729-4dd1-a71e-2397d4cc47e2', 'f3000002-0000-0000-0000-000000000050',
   'Oui, c''est un délit puni pénalement',
   'true', '0'),

  ('678b983b-740e-4599-906c-8512f5cd48ef', 'f3000002-0000-0000-0000-000000000050',
   'Non, c''est libre',
   'false', '1'),

  ('81ebcb82-b618-4688-8128-3218d1b1c098', 'f3000002-0000-0000-0000-000000000050',
   'Uniquement entre supérieurs',
   'false', '2'),

  ('5bee7082-9133-4cf1-8f8d-54fef6e35661', 'f3000002-0000-0000-0000-000000000050',
   'Uniquement les femmes y ont droit',
   'false', '3'),

  ('0f2fb002-fa61-4714-a017-29a59e84bb45', 'f3000002-0000-0000-0000-000000000051',
   'Oui, c''est un délit grave puni pénalement',
   'true', '0'),

  ('8a2c6b0b-98f6-4bf7-b72b-b59817da47b7', 'f3000002-0000-0000-0000-000000000051',
   'Non, c''est toléré',
   'false', '1'),

  ('99feac69-6d51-402a-ac91-507565b183de', 'f3000002-0000-0000-0000-000000000051',
   'Uniquement physique',
   'false', '2'),

  ('52d9ffa6-c3c6-4d19-8df1-d068e67abb88', 'f3000002-0000-0000-0000-000000000051',
   'Uniquement avec menaces explicites',
   'false', '3'),

  ('3523a792-8187-4c69-9866-e1d826597809', 'f3000002-0000-0000-0000-000000000052',
   'Oui, par sédation profonde (loi Claeys-Leonetti 2016)',
   'true', '0'),

  ('adcdedb4-6989-4c96-8d96-fc86ab6a3f1f', 'f3000002-0000-0000-0000-000000000052',
   'Non, aucun cadre légal',
   'false', '1'),

  ('7d2429a6-8617-4472-a852-fc0e094619e8', 'f3000002-0000-0000-0000-000000000052',
   'Oui, l''euthanasie est légalisée',
   'false', '2'),

  ('934b12fa-7aa7-4005-801e-75df4f4c303b', 'f3000002-0000-0000-0000-000000000052',
   'Uniquement pour les hommes',
   'false', '3'),

  ('e480107b-ce4a-49b6-a0e8-b455608a4f02', 'f3000002-0000-0000-0000-000000000053',
   'Réunir des preuves et saisir les prud''hommes / porter plainte',
   'true', '0'),

  ('15896965-2846-4907-97d0-8077b9f6c044', 'f3000002-0000-0000-0000-000000000053',
   'Démissionner immédiatement sans rien',
   'false', '1'),

  ('ea252c85-d80a-4445-99c0-00a7b7898098', 'f3000002-0000-0000-0000-000000000053',
   'Insulter l''employeur',
   'false', '2'),

  ('badc917e-33ff-43d7-a263-e10241bda614', 'f3000002-0000-0000-0000-000000000053',
   'Quitter la France',
   'false', '3'),

  ('c09eaf16-bf8d-48ff-800d-04478d182965', 'f3000002-0000-0000-0000-000000000054',
   'Saisir le Défenseur des droits et porter plainte',
   'true', '0'),

  ('6f0dfd79-0831-4300-bc80-26a034d41918', 'f3000002-0000-0000-0000-000000000054',
   'Aucun recours possible',
   'false', '1'),

  ('86689a09-ccf8-4cd1-83d8-9e4a753a39d7', 'f3000002-0000-0000-0000-000000000054',
   'Changer de nom',
   'false', '2'),

  ('eb553c36-7d71-46ee-99a0-b6d5cbc2794c', 'f3000002-0000-0000-0000-000000000054',
   'Renoncer à chercher un logement',
   'false', '3'),

  ('e862edb3-958b-4e94-9e86-fa20dd32447a', 'f3000002-0000-0000-0000-000000000055',
   'Non, c''est une discrimination interdite',
   'true', '0'),

  ('a0e35762-c7dc-41cc-b239-e55cc610810e', 'f3000002-0000-0000-0000-000000000055',
   'Oui, c''est son droit',
   'false', '1'),

  ('6b1fbfdb-690f-4fd1-b55e-d39fbfa91833', 'f3000002-0000-0000-0000-000000000055',
   'Uniquement avec accord du maire',
   'false', '2'),

  ('5fc07481-aea8-481c-a8a9-f1e8cf312ae2', 'f3000002-0000-0000-0000-000000000055',
   'Uniquement la nuit',
   'false', '3'),

  ('039a338e-5d4c-4f39-9b46-16380d97f63e', 'f3000002-0000-0000-0000-000000000056',
   'Demander le retrait, saisir la CNIL, porter plainte',
   'true', '0'),

  ('2ef9e616-9918-45de-a140-12f2a18e41c6', 'f3000002-0000-0000-0000-000000000056',
   'Rien faire',
   'false', '1'),

  ('86e88f4d-c346-4213-9541-64b468922bab', 'f3000002-0000-0000-0000-000000000056',
   'Diffuser aussi des images de la personne',
   'false', '2'),

  ('f24312c3-03f9-4b25-a2ac-b623fc593fee', 'f3000002-0000-0000-0000-000000000056',
   'Quitter internet',
   'false', '3'),

  ('75f1e602-fd1e-4499-b8ef-0146102e464d', 'f3000002-0000-0000-0000-000000000057',
   'Alerter l''école, l''inspection, appeler le 3018, porter plainte',
   'true', '0'),

  ('97d23fe1-2394-4b0a-9753-5fafb23e4cff', 'f3000002-0000-0000-0000-000000000057',
   'Rien faire',
   'false', '1'),

  ('0c27268b-b3a9-4022-a675-6cd25f7c545c', 'f3000002-0000-0000-0000-000000000057',
   'Punir l''enfant victime',
   'false', '2'),

  ('a1888999-75ac-4048-aee4-6070099d676e', 'f3000002-0000-0000-0000-000000000057',
   'Changer de pays',
   'false', '3'),

  ('eb80f355-3f81-415b-9285-db4f02f50937', 'f3000002-0000-0000-0000-000000000058',
   'Demander le justificatif et saisir le tribunal au besoin',
   'true', '0'),

  ('6ab34f15-de3b-465c-bf1d-e2139c4f285a', 'f3000002-0000-0000-0000-000000000058',
   'Payer immédiatement sans questions',
   'false', '1'),

  ('fb0223cd-d729-4467-b4d8-f9172f649596', 'f3000002-0000-0000-0000-000000000058',
   'Insulter le créancier',
   'false', '2'),

  ('0490603f-cb67-445d-bce5-72a9ce30e957', 'f3000002-0000-0000-0000-000000000058',
   'Fuir le pays',
   'false', '3'),

  ('e9511dda-1eec-4542-ac3c-3f271a72724b', 'f3000002-0000-0000-0000-000000000059',
   'Non, une décision de justice est obligatoire',
   'true', '0'),

  ('5652eee4-0230-4f3d-9c95-4da6a72d06e9', 'f3000002-0000-0000-0000-000000000059',
   'Oui, le propriétaire décide',
   'false', '1'),

  ('3dba14dd-9b11-4abb-be8a-c20148ad71d7', 'f3000002-0000-0000-0000-000000000059',
   'Oui, en l''absence de famille',
   'false', '2'),

  ('21f9f41c-2c7c-4bd1-b0a2-9d743d7b0914', 'f3000002-0000-0000-0000-000000000059',
   'Oui, en période estivale',
   'false', '3'),

  ('32706778-9402-4709-b698-dc54e7042bdd', 'f3000002-0000-0000-0000-00000000005a',
   'Prévenir la SPA, la police ou la gendarmerie',
   'true', '0'),

  ('d372b270-a661-46cb-b6c3-d3585976c1c4', 'f3000002-0000-0000-0000-00000000005a',
   'Rien faire',
   'false', '1'),

  ('612baf90-0e40-4102-aa04-cb9982a79111', 'f3000002-0000-0000-0000-00000000005a',
   'Le faire moi-même aussi',
   'false', '2'),

  ('2bbda294-c987-443e-a828-45c2f4a48d75', 'f3000002-0000-0000-0000-00000000005a',
   'Quitter la France',
   'false', '3');
