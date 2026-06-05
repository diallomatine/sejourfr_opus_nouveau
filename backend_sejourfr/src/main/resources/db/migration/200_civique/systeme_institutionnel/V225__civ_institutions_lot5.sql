-- ============================================================================
-- V225 — Civique : Système institutionnel (lot 5)
-- ----------------------------------------------------------------------------
-- Questions + choix. Filtre: 11111111-0000-0000-0000-000000000002 .
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('f2000002-0000-0000-0000-000000000071', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle révision constitutionnelle de 2008 a renforcé le rôle du Parlement ?',
   'La révision constitutionnelle du 23 juillet 2008 a renforcé le Parlement (contrôle de l''ordre du jour partiellement partagé, encadrement du 49.3, création de la QPC) et limite le président (2 mandats consécutifs maximum).',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000072', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel principe limite à deux le nombre de mandats consécutifs du président ?',
   'Depuis la révision de 2008 (article 6 de la Constitution), nul ne peut exercer plus de deux mandats consécutifs comme président de la République.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000073', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qui peut saisir le Conseil constitutionnel sur une loi avant sa promulgation ?',
   'Le Conseil constitutionnel peut être saisi par : le président de la République, le Premier ministre, les présidents de l''Assemblée et du Sénat, ou 60 députés / 60 sénateurs.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000074', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Combien de membres compte le Conseil constitutionnel ?',
   'Le Conseil constitutionnel compte 9 membres nommés (3 par le président, 3 par le président de l''Assemblée, 3 par le président du Sénat), plus les anciens présidents de la République de droit.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000075', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Pour quelle durée sont nommés les membres du Conseil constitutionnel ?',
   'Les membres nommés du Conseil constitutionnel sont désignés pour 9 ans, non renouvelables. Le Conseil est renouvelé par tiers tous les 3 ans.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000076', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Comment s''appelle l''organe qui juge le président en cas de manquement grave à ses devoirs ?',
   'La Haute Cour, composée des membres du Parlement (Assemblée + Sénat), peut destituer le président en cas de manquement incompatible avec l''exercice du mandat (article 68).',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000077', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'La révision constitutionnelle peut-elle modifier le caractère républicain de la France ?',
   'Non. L''article 89 de la Constitution interdit toute révision portant atteinte à la forme républicaine du gouvernement. C''est l''une des ''clauses d''éternité'' de la Constitution.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000078', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel organe gère la carrière et la discipline des magistrats ?',
   'Le Conseil supérieur de la magistrature (CSM) gère la nomination, l''avancement et la discipline des magistrats. Il garantit leur indépendance.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000079', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle est la différence principale entre un magistrat du siège et un magistrat du parquet ?',
   'Les magistrats du siège jugent (juges, présidents de tribunaux), les magistrats du parquet poursuivent les infractions au nom de la société (procureurs, substituts). Tous deux relèvent de l''autorité judiciaire.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000007a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qu''est-ce que l''ordre administratif distingue de l''ordre judiciaire ?',
   'L''ordre administratif (Conseil d''État, tribunaux administratifs) juge les litiges impliquant l''administration. L''ordre judiciaire juge les litiges entre particuliers et les affaires pénales.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000007b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel est le rôle du procureur de la République ?',
   'Le procureur de la République dirige les enquêtes pénales, décide des poursuites contre les auteurs présumés d''infractions et requiert l''application de la loi devant les tribunaux.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000007c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qu''est-ce qu''une ''loi organique'' en droit français ?',
   'Une loi organique précise l''organisation et le fonctionnement des pouvoirs publics. Elle est adoptée selon une procédure renforcée et est soumise obligatoirement au contrôle du Conseil constitutionnel.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000007d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle est la différence entre un décret et une loi ?',
   'La loi est votée par le Parlement, le décret est pris par le pouvoir exécutif (président ou Premier ministre). Les décrets précisent l''application des lois ou interviennent dans le domaine réglementaire.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000007e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'La Constitution prévoit-elle un partage entre domaine de la loi et domaine du règlement ?',
   'Oui. L''article 34 énumère les domaines réservés au Parlement (lois). L''article 37 confie au gouvernement les autres domaines (règlements).',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000007f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle institution européenne représente les gouvernements des États membres ?',
   'Le Conseil de l''Union européenne (à distinguer du Conseil européen, qui réunit les chefs d''État) réunit les ministres spécialisés de chaque pays membre. Il vote les lois avec le Parlement européen.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000080', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qui siège au Conseil européen ?',
   'Le Conseil européen réunit les chefs d''État et de gouvernement des 27 pays membres, plus le président de la Commission et son président permanent. Il fixe les grandes orientations de l''UE.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000081', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle est la différence entre un règlement et une directive européens ?',
   'Le règlement européen s''applique directement dans tous les États membres sans transposition. La directive fixe des objectifs et laisse les États libres des moyens, avec un délai de transposition en droit national.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000082', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Comment une révision de la Constitution peut-elle aboutir ?',
   'Une révision constitutionnelle est adoptée par les deux chambres du Parlement, puis ratifiée soit par référendum, soit par le Congrès (Parlement réuni à Versailles) à la majorité des 3/5e.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000083', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel article de la Constitution organise la révision constitutionnelle ?',
   'L''article 89 organise la procédure de révision de la Constitution. Il prévoit le vote des deux chambres puis le référendum ou le Congrès.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000084', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Une loi votée par le Parlement entre-t-elle en vigueur immédiatement ?',
   'Non. Une fois la loi votée, le président dispose de 15 jours pour la promulguer. Elle entre en vigueur après sa publication au Journal officiel, parfois après parution des décrets d''application.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000085', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Le président peut-il refuser de promulguer une loi ?',
   'Non, il doit la promulguer dans les 15 jours. Il peut cependant demander une nouvelle délibération au Parlement, ou saisir le Conseil constitutionnel pour contrôle.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000086', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel est le délai standard pour saisir le Conseil constitutionnel après le vote d''une loi ?',
   'La saisine doit intervenir dans le délai de 15 jours qui suivent la promulgation possible, c''est-à-dire avant que le président ne signe la loi.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000087', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qu''est-ce qu''un référendum d''initiative partagée ?',
   'Le référendum d''initiative partagée (RIP), créé en 2008, permet l''organisation d''un référendum à la demande d''1/5e des parlementaires soutenus par 10% des électeurs inscrits.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000088', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Combien y a-t-il eu de référendums sous la Ve République ?',
   'Sous la Ve République, environ 10 référendums ont été organisés au niveau national, sur des sujets tels que l''Algérie, l''élection du président, l''Europe, le quinquennat ou les traités européens.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000089', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'En quoi consiste le ''contrôle a posteriori'' des lois ?',
   'Le contrôle a posteriori, par voie de Question prioritaire de constitutionnalité (QPC), permet de contester une loi déjà en vigueur si elle porte atteinte aux droits constitutionnels. Créé en 2008.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000008a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel est le principe d''autonomie financière des collectivités territoriales ?',
   'Les collectivités territoriales (communes, départements, régions) disposent d''une part de ressources propres et peuvent fixer le taux de certains impôts locaux dans les limites de la loi (article 72-2 de la Constitution).',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000008b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle institution gère les finances et le budget de l''État ?',
   'Le budget de l''État est préparé par le gouvernement (ministère de l''Économie et des Finances), voté par le Parlement chaque automne, et son exécution est contrôlée par la Cour des comptes.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000008c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle institution évalue l''exécution des politiques publiques et les comptes de l''État ?',
   'La Cour des comptes est une juridiction financière indépendante qui contrôle l''usage des fonds publics et publie des rapports souvent commentés dans le débat public.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000008d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Le médiateur entre l''administration et les citoyens existe-t-il sous une forme officielle en France ?',
   'Oui, c''est le Défenseur des droits, autorité constitutionnelle indépendante (depuis 2011) qui défend les droits et libertés des citoyens face aux administrations et lutte contre les discriminations.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000008e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel principe constitutionnel garantit l''égal accès des femmes et des hommes aux mandats électifs ?',
   'Le principe de parité, inscrit dans la Constitution depuis 1999 (article 1er, alinéa 2), impose aux partis politiques de favoriser l''égal accès des femmes et des hommes aux mandats et fonctions électives.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000008f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quel principe encadre le financement des campagnes électorales en France ?',
   'Les campagnes électorales sont strictement encadrées : plafond de dépenses, interdiction des dons d''entreprises depuis 1995, remboursement partiel par l''État, contrôle par la Commission nationale des comptes de campagne.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000090', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que prévoit la loi pour assurer la transparence de la vie publique ?',
   'Depuis 2013, les élus et hauts responsables doivent déclarer leur patrimoine et leurs intérêts à la Haute Autorité pour la transparence de la vie publique (HATVP), qui contrôle d''éventuels conflits d''intérêts.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000091', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Un président sortant a déjà effectué deux mandats consécutifs. Peut-il se représenter immédiatement après ?',
   'Non. Depuis la révision de 2008 (article 6), un président ne peut pas exercer plus de deux mandats consécutifs. Il devra attendre au moins un mandat avant de se représenter.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000092', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Une loi votée me semble priver d''un droit fondamental. Avant promulgation, qui peut saisir le Conseil constitutionnel ?',
   'Un citoyen seul ne peut pas saisir directement. Mais 60 députés ou 60 sénateurs peuvent saisir le Conseil dans les 15 jours suivant l''adoption de la loi. Après promulgation, il reste la QPC.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000093', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Le président veut organiser un référendum sur une question économique. En a-t-il le pouvoir ?',
   'L''article 11 permet au président de soumettre au référendum un projet de loi portant sur l''organisation des pouvoirs publics, des réformes économiques, sociales ou environnementales, ou la ratification d''un traité.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000094', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Un député français peut-il siéger simultanément au Sénat ?',
   'Non. Les mandats parlementaires sont incompatibles entre eux : on ne peut pas être député et sénateur en même temps. La loi limite aussi le cumul des mandats locaux.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000095', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Un parti politique reçoit des financements étrangers importants. Que dit le droit ?',
   'Les partis politiques français ne peuvent recevoir aucune contribution ou aide matérielle directe ou indirecte d''un État étranger ou d''une personne morale de droit étranger. C''est interdit par la loi.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000096', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Une commune ne respecte pas un jugement du tribunal administratif. Que peut-on faire ?',
   'Le requérant peut demander au tribunal administratif d''ordonner l''exécution sous astreinte (somme due par jour de retard). Le préfet peut aussi se substituer à la commune dans certains cas.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000097', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Le président signe un traité international sans autorisation parlementaire pour un traité important. Est-ce légal ?',
   'Non. Les traités importants (qui modifient des dispositions législatives, engagent les finances, affectent l''état des personnes, cèdent ou échangent du territoire) doivent être autorisés par une loi (article 53).',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000098', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Un ministre prend une décision contraire à une directive européenne. Quels recours sont possibles ?',
   'Le droit européen prime sur le droit national. Un acte contraire peut être contesté devant le juge administratif français (Conseil d''État). La Commission européenne peut aussi engager une procédure d''infraction contre la France.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-000000000099', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Le président souhaite dissoudre l''Assemblée nationale. Y a-t-il des limites ?',
   'Oui. L''article 12 permet la dissolution après consultation du Premier ministre et des présidents des chambres. Mais il ne peut y avoir de nouvelle dissolution dans l''année qui suit ces élections.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000002-0000-0000-0000-00000000009a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Une personne souhaite obtenir une information détenue par une administration mais celle-ci refuse. Quel recours ?',
   'La Commission d''accès aux documents administratifs (CADA) peut être saisie en cas de refus. Elle donne un avis non contraignant ; le tribunal administratif peut ensuite être saisi.',
   'true', '2026-05-27 17:40:29.905576+02', NULL, 'ACTIVE', NULL, NULL, NULL);

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('9bec048a-c8ee-4534-bed3-548e68046a6a', 'f2000002-0000-0000-0000-000000000071',
   'La révision constitutionnelle du 23 juillet 2008',
   'true', '0'),

  ('f7fe75d7-178e-4f10-9f81-333a8b695de3', 'f2000002-0000-0000-0000-000000000071',
   'La révision de 1962',
   'false', '1'),

  ('452498f0-70c3-44b7-b5ac-ff431d0c6225', 'f2000002-0000-0000-0000-000000000071',
   'La révision de 1992',
   'false', '2'),

  ('a6e16b0b-c7f9-4b2f-81a5-7f436dd5964d', 'f2000002-0000-0000-0000-000000000071',
   'Aucune révision n''a renforcé le Parlement',
   'false', '3'),

  ('fd7e0179-a621-4edb-a86a-eb2a2ede5257', 'f2000002-0000-0000-0000-000000000072',
   'Deux mandats consécutifs maximum (article 6)',
   'true', '0'),

  ('a36402d8-be87-4f81-9271-8c6571e77861', 'f2000002-0000-0000-0000-000000000072',
   'Aucune limite',
   'false', '1'),

  ('75762a20-75de-45f9-860a-dfdfc3c9f98b', 'f2000002-0000-0000-0000-000000000072',
   'Trois mandats consécutifs',
   'false', '2'),

  ('6f53df0c-4be0-4b92-91b4-1a929a7cd5a5', 'f2000002-0000-0000-0000-000000000072',
   'Cinq mandats consécutifs',
   'false', '3'),

  ('ed72a754-16f8-4f1d-a843-fb878c475b3e', 'f2000002-0000-0000-0000-000000000073',
   'Le président, le PM, les présidents des chambres, 60 parlementaires',
   'true', '0'),

  ('a1e275b6-f8c2-4c4d-8534-086ee754f574', 'f2000002-0000-0000-0000-000000000073',
   'N''importe quel citoyen seul',
   'false', '1'),

  ('f3190792-c7b4-4502-a945-4fc8434a7de1', 'f2000002-0000-0000-0000-000000000073',
   'Uniquement le pape',
   'false', '2'),

  ('b2890756-f7e2-492a-b06b-0ca97ba62cd6', 'f2000002-0000-0000-0000-000000000073',
   'Uniquement les magistrats',
   'false', '3'),

  ('8ea571ab-3826-4422-bdcd-9b63671717e3', 'f2000002-0000-0000-0000-000000000074',
   '9 membres nommés (plus les anciens présidents de droit)',
   'true', '0'),

  ('3fb0d02d-80bb-433f-8fc8-1d76c4f02bcb', 'f2000002-0000-0000-0000-000000000074',
   '27 membres élus',
   'false', '1'),

  ('d8a2b887-5e7d-4deb-8701-94dc55a60991', 'f2000002-0000-0000-0000-000000000074',
   '100 membres',
   'false', '2'),

  ('a26e13df-dae4-45e7-8e3a-7ed87ff59577', 'f2000002-0000-0000-0000-000000000074',
   '1 seul juge',
   'false', '3'),

  ('74bb36fa-a720-47ed-99b6-13ac7baa2a3a', 'f2000002-0000-0000-0000-000000000075',
   '9 ans non renouvelables',
   'true', '0'),

  ('d6ff3592-a26d-490f-b6cc-402df51d7c1f', 'f2000002-0000-0000-0000-000000000075',
   'À vie',
   'false', '1'),

  ('84a090b7-2127-4ae8-9e70-55710ee888f6', 'f2000002-0000-0000-0000-000000000075',
   '5 ans renouvelables',
   'false', '2'),

  ('34074a96-0a8e-483f-a83f-0fb30119aff2', 'f2000002-0000-0000-0000-000000000075',
   '1 an',
   'false', '3'),

  ('73bc41a1-b513-46b8-a868-8e064383b8e3', 'f2000002-0000-0000-0000-000000000076',
   'La Haute Cour',
   'true', '0'),

  ('1a062be7-6b61-436a-9c6e-0d0d322f625d', 'f2000002-0000-0000-0000-000000000076',
   'La Cour de cassation',
   'false', '1'),

  ('722203d0-3b11-4153-92ea-c0841d1adaf5', 'f2000002-0000-0000-0000-000000000076',
   'Le tribunal de Paris',
   'false', '2'),

  ('f20e577b-7042-4abb-9834-88d498b17095', 'f2000002-0000-0000-0000-000000000076',
   'Le conseil municipal',
   'false', '3'),

  ('2d0064de-a1bb-4f36-ba25-52151492b464', 'f2000002-0000-0000-0000-000000000077',
   'Non, la forme républicaine est intouchable',
   'true', '0'),

  ('897d1ad3-edd1-40f0-96e2-6c849b05852f', 'f2000002-0000-0000-0000-000000000077',
   'Oui, par référendum',
   'false', '1'),

  ('7b10a51a-e003-4290-88c4-2eaf42f1bf65', 'f2000002-0000-0000-0000-000000000077',
   'Oui, avec accord du pape',
   'false', '2'),

  ('e1b85b21-ae9d-46d1-a810-91f51387739a', 'f2000002-0000-0000-0000-000000000077',
   'Oui, en cas de guerre',
   'false', '3'),

  ('0ca3b29f-fd9d-47b4-9a47-18295853d037', 'f2000002-0000-0000-0000-000000000078',
   'Le Conseil supérieur de la magistrature (CSM)',
   'true', '0'),

  ('e45615c2-7320-4e05-aec8-05a9fa5e45d8', 'f2000002-0000-0000-0000-000000000078',
   'Le ministre de la Justice seul',
   'false', '1'),

  ('da9893e6-c00e-4162-bf7a-3de338a7e257', 'f2000002-0000-0000-0000-000000000078',
   'Le maire de Paris',
   'false', '2'),

  ('908fa430-4485-453d-8373-00d5e99d74ec', 'f2000002-0000-0000-0000-000000000078',
   'Le président seul',
   'false', '3'),

  ('9c48e594-70c0-49fb-97d9-159126b9cbab', 'f2000002-0000-0000-0000-000000000079',
   'Le siège juge, le parquet poursuit au nom de la société',
   'true', '0'),

  ('3b85b622-5e7c-4eff-90fa-d2cff7e6cd78', 'f2000002-0000-0000-0000-000000000079',
   'Aucune différence',
   'false', '1'),

  ('100cf4f1-1cd6-46bd-bf00-ce02aee2fd85', 'f2000002-0000-0000-0000-000000000079',
   'Le siège paie, le parquet reçoit',
   'false', '2'),

  ('5900cb4d-e872-45ff-927b-3c548ae91260', 'f2000002-0000-0000-0000-000000000079',
   'Le siège est élu, le parquet est nommé',
   'false', '3'),

  ('a01a02d4-fc69-4664-a040-b9329316b145', 'f2000002-0000-0000-0000-00000000007a',
   'L''ordre administratif juge les litiges avec l''administration',
   'true', '0'),

  ('a427a273-a3b7-4e45-aeb4-5a6e4d29d3fa', 'f2000002-0000-0000-0000-00000000007a',
   'Aucune distinction',
   'false', '1'),

  ('116449ec-784d-44f4-bf81-dbd3c8bf25db', 'f2000002-0000-0000-0000-00000000007a',
   'L''ordre administratif juge les crimes',
   'false', '2'),

  ('76e6d61d-2fc3-4ecb-9ff7-605bbd68eca9', 'f2000002-0000-0000-0000-00000000007a',
   'L''ordre administratif est européen',
   'false', '3'),

  ('ac2b0829-a29e-4f3c-bec5-9a30caefae3d', 'f2000002-0000-0000-0000-00000000007b',
   'Diriger les enquêtes et engager les poursuites pénales',
   'true', '0'),

  ('3f99775a-c992-4695-b669-3c4af2184777', 'f2000002-0000-0000-0000-00000000007b',
   'Voter les lois',
   'false', '1'),

  ('c10aae78-b877-4a96-984a-b260bf337149', 'f2000002-0000-0000-0000-00000000007b',
   'Diriger la commune',
   'false', '2'),

  ('76fc94ab-20a9-4d4a-8c67-a71635ab8e47', 'f2000002-0000-0000-0000-00000000007b',
   'Nommer le président',
   'false', '3'),

  ('6d8873b8-c0d0-4048-b6a9-caf54efb3106', 'f2000002-0000-0000-0000-00000000007c',
   'Une loi précisant l''organisation des pouvoirs publics',
   'true', '0'),

  ('1604568a-810c-4970-bfb6-64e2284feff2', 'f2000002-0000-0000-0000-00000000007c',
   'Une loi religieuse',
   'false', '1'),

  ('1ac486ea-fadf-413e-8103-31a0a41dd965', 'f2000002-0000-0000-0000-00000000007c',
   'Une loi sur les organes humains',
   'false', '2'),

  ('a0874f07-859c-4ca5-b01e-0d36d0841060', 'f2000002-0000-0000-0000-00000000007c',
   'Un décret du maire',
   'false', '3'),

  ('89d76fa8-882a-4e67-943a-fbcd1e22dd53', 'f2000002-0000-0000-0000-00000000007d',
   'La loi est votée par le Parlement, le décret est pris par l''exécutif',
   'true', '0'),

  ('f4d185ca-970b-49b6-a2ff-f9c6b41bccf9', 'f2000002-0000-0000-0000-00000000007d',
   'Aucune différence',
   'false', '1'),

  ('c1c01c84-dedf-4459-9308-dfaf9a96c882', 'f2000002-0000-0000-0000-00000000007d',
   'Le décret est supérieur à la loi',
   'false', '2'),

  ('19e8f7af-3291-4076-b408-1443dd8638bd', 'f2000002-0000-0000-0000-00000000007d',
   'La loi est religieuse, le décret est civil',
   'false', '3'),

  ('c72eff5d-2514-42de-b4a1-44d35881fa9c', 'f2000002-0000-0000-0000-00000000007e',
   'Oui, articles 34 (loi) et 37 (règlement)',
   'true', '0'),

  ('453bf321-5597-4fc8-a0be-aa8e5211c0bf', 'f2000002-0000-0000-0000-00000000007e',
   'Non, tout est législatif',
   'false', '1'),

  ('dbd5c8bd-0a83-49f6-838a-5683f39deecc', 'f2000002-0000-0000-0000-00000000007e',
   'Non, tout est réglementaire',
   'false', '2'),

  ('e5f8a961-54da-45fd-85d2-87448487d58b', 'f2000002-0000-0000-0000-00000000007e',
   'Uniquement en Belgique',
   'false', '3'),

  ('86db0554-b362-4877-b493-68643daa1ce4', 'f2000002-0000-0000-0000-00000000007f',
   'Le Conseil de l''Union européenne',
   'true', '0'),

  ('beb84004-a52b-4861-85bd-06bbe151e58c', 'f2000002-0000-0000-0000-00000000007f',
   'Le Parlement européen',
   'false', '1'),

  ('ba79984e-ef0a-4922-8598-e22449b3de46', 'f2000002-0000-0000-0000-00000000007f',
   'La Commission européenne',
   'false', '2'),

  ('bba320e6-37f3-4a0d-9ed6-d74866e56d25', 'f2000002-0000-0000-0000-00000000007f',
   'La Cour de justice',
   'false', '3'),

  ('2556d2f7-8bbf-4f31-adcb-1b33ce1a38d9', 'f2000002-0000-0000-0000-000000000080',
   'Les chefs d''État et de gouvernement des 27 pays',
   'true', '0'),

  ('bdbcb3f4-e6fd-438b-868b-cfe05e1e6b5a', 'f2000002-0000-0000-0000-000000000080',
   'Les maires des grandes villes européennes',
   'false', '1'),

  ('3d11b997-4500-4fab-ab8c-dcd46101cbc2', 'f2000002-0000-0000-0000-000000000080',
   'Des députés tirés au sort',
   'false', '2'),

  ('7f40786f-9dcb-4243-986a-d9eeacb69d20', 'f2000002-0000-0000-0000-000000000080',
   'Uniquement des Français',
   'false', '3'),

  ('a6511574-4a13-4e6a-9741-fa352d255de7', 'f2000002-0000-0000-0000-000000000081',
   'Le règlement s''applique directement, la directive doit être transposée',
   'true', '0'),

  ('30a6b50d-4a88-4b11-9314-8c48cbea4a02', 'f2000002-0000-0000-0000-000000000081',
   'Aucune différence',
   'false', '1'),

  ('f2e2bd6b-911a-46e0-9b21-4bfaa9120816', 'f2000002-0000-0000-0000-000000000081',
   'Le règlement est français, la directive européenne',
   'false', '2'),

  ('8dd5c288-97b6-453e-abd6-8cee884df343', 'f2000002-0000-0000-0000-000000000081',
   'Le règlement est militaire, la directive civile',
   'false', '3'),

  ('33c4825d-ec4d-492b-a3f9-b34dc7476aae', 'f2000002-0000-0000-0000-000000000082',
   'Vote des deux chambres + référendum ou Congrès aux 3/5e',
   'true', '0'),

  ('aaf975b6-cd7d-4736-9fa1-bae3ddf90aa4', 'f2000002-0000-0000-0000-000000000082',
   'Décision du seul président',
   'false', '1'),

  ('ec3c015c-7898-449c-be67-05829ce913c6', 'f2000002-0000-0000-0000-000000000082',
   'Décret du gouvernement',
   'false', '2'),

  ('a2c9fb85-4a5a-42f7-a0ec-d20f9d5891ba', 'f2000002-0000-0000-0000-000000000082',
   'Vote des maires',
   'false', '3'),

  ('4112f894-0a27-4024-ac31-a9bdea957f6e', 'f2000002-0000-0000-0000-000000000083',
   'L''article 89',
   'true', '0'),

  ('18e066f0-faaf-4cde-b866-895126f70193', 'f2000002-0000-0000-0000-000000000083',
   'L''article 11',
   'false', '1'),

  ('1ec3a9e1-a442-4ff1-af63-8a6cb16207d7', 'f2000002-0000-0000-0000-000000000083',
   'L''article 16',
   'false', '2'),

  ('06aa1333-acb6-4e56-8af3-91fd0194b515', 'f2000002-0000-0000-0000-000000000083',
   'L''article 1er',
   'false', '3'),

  ('d8dbfa17-c727-4bb0-b42e-1fb012e3bb11', 'f2000002-0000-0000-0000-000000000084',
   'Non, elle doit être promulguée et publiée au Journal officiel',
   'true', '0'),

  ('5c1d31e3-359a-4f79-9eb0-64c25462b0c2', 'f2000002-0000-0000-0000-000000000084',
   'Oui, immédiatement au vote',
   'false', '1'),

  ('82f5d349-d0dd-4a8a-975b-4a9b07d210e1', 'f2000002-0000-0000-0000-000000000084',
   'Après 1 an obligatoirement',
   'false', '2'),

  ('9364931f-f8fe-484b-856a-e6ba248d7cf9', 'f2000002-0000-0000-0000-000000000084',
   'Après accord du pape',
   'false', '3'),

  ('2be31288-7db0-4ae9-a894-ae8f93516216', 'f2000002-0000-0000-0000-000000000085',
   'Non, mais il peut demander une nouvelle délibération ou saisir le Conseil constitutionnel',
   'true', '0'),

  ('fb0d34e6-4416-47aa-bbee-492ec1ec94d2', 'f2000002-0000-0000-0000-000000000085',
   'Oui, sans condition',
   'false', '1'),

  ('8b01862b-4653-4906-86d8-0ba71645701c', 'f2000002-0000-0000-0000-000000000085',
   'Oui, par référendum',
   'false', '2'),

  ('326080b2-8e34-4e7d-ae8b-ce85a0f46ad3', 'f2000002-0000-0000-0000-000000000085',
   'Oui, en cas de guerre',
   'false', '3'),

  ('4c5909ef-a457-4fcb-8e8b-f7efbad6167f', 'f2000002-0000-0000-0000-000000000086',
   'Dans les 15 jours avant promulgation',
   'true', '0'),

  ('878c3fff-d248-4b66-bbdf-b09a4dee199f', 'f2000002-0000-0000-0000-000000000086',
   '1 an après',
   'false', '1'),

  ('65eba6f5-b3ba-49e6-81b2-33b2a4b0b55c', 'f2000002-0000-0000-0000-000000000086',
   'Jamais',
   'false', '2'),

  ('c717a1f7-9660-4790-9f95-e0358e3904b3', 'f2000002-0000-0000-0000-000000000086',
   '10 ans après',
   'false', '3'),

  ('c300b8c7-2cf1-4c05-85a3-ee64d30847f1', 'f2000002-0000-0000-0000-000000000087',
   'Référendum lancé par parlementaires + 10% des électeurs',
   'true', '0'),

  ('df023d48-7a8e-44e6-99d8-89520092c669', 'f2000002-0000-0000-0000-000000000087',
   'Référendum local de quartier',
   'false', '1'),

  ('10396622-e41a-409d-8014-44e98510e663', 'f2000002-0000-0000-0000-000000000087',
   'Vote informatique uniquement',
   'false', '2'),

  ('8422d63b-6402-42e7-b49d-27fa397c206d', 'f2000002-0000-0000-0000-000000000087',
   'Sondage télévisé',
   'false', '3'),

  ('1254b474-39a6-4f29-9c65-1efc4124bf77', 'f2000002-0000-0000-0000-000000000088',
   'Environ 10 référendums depuis 1958',
   'true', '0'),

  ('af752aae-898a-4785-a9ba-bf85e2156ffb', 'f2000002-0000-0000-0000-000000000088',
   'Aucun référendum',
   'false', '1'),

  ('d33f2ab2-9f0f-4ab1-a7b2-c8609d409518', 'f2000002-0000-0000-0000-000000000088',
   'Plus de 100',
   'false', '2'),

  ('603a3044-e3ba-4222-9d60-e47eebed4474', 'f2000002-0000-0000-0000-000000000088',
   'Un seul référendum',
   'false', '3'),

  ('5aa1e2a2-6029-44a8-ae4a-ae0352539a80', 'f2000002-0000-0000-0000-000000000089',
   'Contestation d''une loi en vigueur via QPC (2008)',
   'true', '0'),

  ('1aa76e9a-e936-415c-826a-2f32a3815d0c', 'f2000002-0000-0000-0000-000000000089',
   'Réécriture spontanée d''une loi',
   'false', '1'),

  ('88874e96-d990-446a-b658-ea3d2e0aaf71', 'f2000002-0000-0000-0000-000000000089',
   'Vérification annuelle par l''ONU',
   'false', '2'),

  ('daedda03-506f-403b-a808-34001a1c9aeb', 'f2000002-0000-0000-0000-000000000089',
   'Sondage des citoyens',
   'false', '3'),

  ('4c304fa8-0bf0-46b1-b072-57c2a5bc5bf6', 'f2000002-0000-0000-0000-00000000008a',
   'Les collectivités disposent de ressources propres et peuvent fixer certains impôts',
   'true', '0'),

  ('499b91bc-1481-467d-b42c-2664a55ce77a', 'f2000002-0000-0000-0000-00000000008a',
   'Tout est décidé par l''État',
   'false', '1'),

  ('d9584390-f523-4fb1-b804-1f366f288ae9', 'f2000002-0000-0000-0000-00000000008a',
   'Aucune autonomie financière',
   'false', '2'),

  ('3f5681d1-d137-49c7-9cc9-df2a65598fb6', 'f2000002-0000-0000-0000-00000000008a',
   'Elles dépossèdent l''État',
   'false', '3'),

  ('52d64a24-f5c3-4057-a82b-9ce6488eb6ce', 'f2000002-0000-0000-0000-00000000008b',
   'Préparé par le gouvernement, voté par le Parlement, contrôlé par la Cour des comptes',
   'true', '0'),

  ('d9388a64-dfad-45a6-8989-b9d975186245', 'f2000002-0000-0000-0000-00000000008b',
   'Décidé par le pape',
   'false', '1'),

  ('08c5b5a6-0609-4ea8-a335-4faafbe05639', 'f2000002-0000-0000-0000-00000000008b',
   'Voté par les maires',
   'false', '2'),

  ('3032f427-754b-4c9e-90b4-936b610eb781', 'f2000002-0000-0000-0000-00000000008b',
   'Aucun budget officiel',
   'false', '3'),

  ('b6331503-b184-431a-8971-dde0e940c796', 'f2000002-0000-0000-0000-00000000008c',
   'La Cour des comptes',
   'true', '0'),

  ('3dd44c8b-507f-4a3d-975a-3480bdce0700', 'f2000002-0000-0000-0000-00000000008c',
   'Le Conseil constitutionnel',
   'false', '1'),

  ('35a8d0fe-9c2c-40bd-9b75-55217c515be6', 'f2000002-0000-0000-0000-00000000008c',
   'L''Assemblée nationale seule',
   'false', '2'),

  ('a4266388-615b-4ec3-a91d-183eaaaf9221', 'f2000002-0000-0000-0000-00000000008c',
   'L''ONU',
   'false', '3'),

  ('a7cbc923-ef4e-41f9-8e17-873902292593', 'f2000002-0000-0000-0000-00000000008d',
   'Oui, le Défenseur des droits',
   'true', '0'),

  ('9f166d82-6b7e-4523-afa9-df3eef66ff84', 'f2000002-0000-0000-0000-00000000008d',
   'Non, il n''existe pas',
   'false', '1'),

  ('fc375fcd-2742-471b-987e-9dfb97e8c590', 'f2000002-0000-0000-0000-00000000008d',
   'Uniquement les avocats',
   'false', '2'),

  ('dcf67327-6755-44cb-aa6e-ad97593bac78', 'f2000002-0000-0000-0000-00000000008d',
   'Uniquement le pape',
   'false', '3'),

  ('7469765b-2521-4e4b-97e0-e3fb9ea54d69', 'f2000002-0000-0000-0000-00000000008e',
   'La parité (inscrite dans la Constitution en 1999)',
   'true', '0'),

  ('1d4ae79b-f5b2-48c8-a2b2-7d1c0234fb3e', 'f2000002-0000-0000-0000-00000000008e',
   'Le quota religieux',
   'false', '1'),

  ('04a23dfd-a286-458f-9701-9712541901a9', 'f2000002-0000-0000-0000-00000000008e',
   'La hiérarchie par âge',
   'false', '2'),

  ('b5534546-12d5-49df-ac54-9180a1506ba8', 'f2000002-0000-0000-0000-00000000008e',
   'Aucun principe particulier',
   'false', '3'),

  ('ed074865-d6e5-4180-bde2-b106423bcab7', 'f2000002-0000-0000-0000-00000000008f',
   'Plafonnement des dépenses et contrôle public',
   'true', '0'),

  ('6a737a8d-837e-484a-985f-699da434b035', 'f2000002-0000-0000-0000-00000000008f',
   'Aucune règle, c''est libre',
   'false', '1'),

  ('07732aaf-d8d7-4b5c-b776-f10302f7e9e8', 'f2000002-0000-0000-0000-00000000008f',
   'Financement uniquement religieux',
   'false', '2'),

  ('814d85a4-e06f-4b05-8658-e47fc8b99a8a', 'f2000002-0000-0000-0000-00000000008f',
   'Financement uniquement étranger',
   'false', '3'),

  ('d7b0c177-ea63-4aeb-aa97-01eb796d965e', 'f2000002-0000-0000-0000-000000000090',
   'Déclarations de patrimoine et d''intérêts à la HATVP',
   'true', '0'),

  ('b96e9010-7858-4ec3-9f5f-c1b58daa64cc', 'f2000002-0000-0000-0000-000000000090',
   'Rien n''est prévu',
   'false', '1'),

  ('c1e9861b-e1ac-4f95-8969-c0b3fd4a3593', 'f2000002-0000-0000-0000-000000000090',
   'Uniquement pour le président',
   'false', '2'),

  ('4571429e-50cb-4fba-82fc-c0c4ee03d640', 'f2000002-0000-0000-0000-000000000090',
   'Déclarations religieuses',
   'false', '3'),

  ('4f385a9f-8762-4ab3-ae85-13a5c47c393d', 'f2000002-0000-0000-0000-000000000091',
   'Non, il faut attendre au moins un mandat avant de se représenter',
   'true', '0'),

  ('522ce21e-9f23-4b71-bfd9-8144544d71f0', 'f2000002-0000-0000-0000-000000000091',
   'Oui, immédiatement',
   'false', '1'),

  ('cd64bf64-36d4-4603-b42b-2e8e2922befb', 'f2000002-0000-0000-0000-000000000091',
   'Oui, mais pour 3 ans',
   'false', '2'),

  ('162a75fd-be74-4414-beae-bc7dc1a82e86', 'f2000002-0000-0000-0000-000000000091',
   'Non, jamais à vie',
   'false', '3'),

  ('656eb7bb-bffe-474d-8622-533827f23d25', 'f2000002-0000-0000-0000-000000000092',
   '60 députés ou 60 sénateurs (avant promulgation), QPC après',
   'true', '0'),

  ('07432f7a-aa88-48f7-922a-6393f58ee63e', 'f2000002-0000-0000-0000-000000000092',
   'N''importe quel citoyen seul',
   'false', '1'),

  ('76b34d0b-99b5-4fcb-be62-9781da043d31', 'f2000002-0000-0000-0000-000000000092',
   'Uniquement le président',
   'false', '2'),

  ('2ff18131-f348-4b9c-9e12-e77b089f2003', 'f2000002-0000-0000-0000-000000000092',
   'Uniquement le pape',
   'false', '3'),

  ('33a5a5eb-8947-46e8-8c39-1689b63c62a1', 'f2000002-0000-0000-0000-000000000093',
   'Oui, l''article 11 le permet pour les réformes économiques et sociales',
   'true', '0'),

  ('22c34462-b1c4-429d-9a44-b57bb66c76f9', 'f2000002-0000-0000-0000-000000000093',
   'Non, jamais',
   'false', '1'),

  ('3690666e-606e-4f77-9bd4-592fadfde25d', 'f2000002-0000-0000-0000-000000000093',
   'Oui, sur toute question sans limite',
   'false', '2'),

  ('4e9f46a4-8dff-442b-b1ea-3d98f51d91f8', 'f2000002-0000-0000-0000-000000000093',
   'Uniquement avec accord du pape',
   'false', '3'),

  ('6d8f7285-abf5-4ced-85d8-828bd57215af', 'f2000002-0000-0000-0000-000000000094',
   'Non, les mandats parlementaires sont incompatibles',
   'true', '0'),

  ('c9be920d-da23-4043-a7e2-51c9a95ad311', 'f2000002-0000-0000-0000-000000000094',
   'Oui, sans aucune limite',
   'false', '1'),

  ('200b08a7-2bc1-4a28-b967-ec8677ac29c1', 'f2000002-0000-0000-0000-000000000094',
   'Uniquement les week-ends',
   'false', '2'),

  ('ee7a8395-2b96-457e-8897-58a75600fd43', 'f2000002-0000-0000-0000-000000000094',
   'Uniquement les femmes',
   'false', '3'),

  ('634365ad-1320-41f2-85d0-78f80a1b85df', 'f2000002-0000-0000-0000-000000000095',
   'C''est interdit par la loi sur le financement des partis',
   'true', '0'),

  ('8b6d8d00-d0d1-46dd-a268-b4b70f8439e2', 'f2000002-0000-0000-0000-000000000095',
   'C''est autorisé sans limite',
   'false', '1'),

  ('44301d01-3c5a-4a2c-8b4a-7e2e3de53557', 'f2000002-0000-0000-0000-000000000095',
   'Uniquement avec accord du pape',
   'false', '2'),

  ('c7f84622-e943-4dd7-83c0-d1e3df37f000', 'f2000002-0000-0000-0000-000000000095',
   'Uniquement avant les élections',
   'false', '3'),

  ('e4792206-ad32-4e1f-9a2a-30ec543469a8', 'f2000002-0000-0000-0000-000000000096',
   'Demander l''exécution sous astreinte au tribunal',
   'true', '0'),

  ('7bbc5497-168d-45b4-b4f8-14ba6c99d6ee', 'f2000002-0000-0000-0000-000000000096',
   'Rien faire',
   'false', '1'),

  ('a39b6883-4228-47b9-9ca4-19cbffd3d6f9', 'f2000002-0000-0000-0000-000000000096',
   'Forcer l''exécution manu militari',
   'false', '2'),

  ('96d70ed5-bf34-448d-8d3d-14e61ea6f2d2', 'f2000002-0000-0000-0000-000000000096',
   'Quitter la commune',
   'false', '3'),

  ('b5df0f2b-6050-4bed-9445-8a65c827fe77', 'f2000002-0000-0000-0000-000000000097',
   'Non, certains traités doivent être autorisés par une loi (article 53)',
   'true', '0'),

  ('e5a9d119-6ca8-4939-b53f-587678255d26', 'f2000002-0000-0000-0000-000000000097',
   'Oui, sans condition',
   'false', '1'),

  ('6625e365-02d3-44ea-a669-ad6b8ac5c658', 'f2000002-0000-0000-0000-000000000097',
   'Uniquement pour les traités militaires',
   'false', '2'),

  ('12d3a0f8-5e62-4986-acf5-90dae211eaa3', 'f2000002-0000-0000-0000-000000000097',
   'Uniquement avec accord du pape',
   'false', '3'),

  ('1457a950-d763-4146-9f25-265ab247459c', 'f2000002-0000-0000-0000-000000000098',
   'Recours administratif français + procédure d''infraction européenne',
   'true', '0'),

  ('fb43424d-9bae-4deb-8f77-7ce278d5e0f9', 'f2000002-0000-0000-0000-000000000098',
   'Aucun recours possible',
   'false', '1'),

  ('86428636-7621-4152-a527-7f8cd8f1d30f', 'f2000002-0000-0000-0000-000000000098',
   'Demander un référendum européen',
   'false', '2'),

  ('08123f68-7067-4453-bc46-7a113b0cd419', 'f2000002-0000-0000-0000-000000000098',
   'Saisir le pape',
   'false', '3'),

  ('461cf933-2764-4175-ad35-3b7372410c40', 'f2000002-0000-0000-0000-000000000099',
   'Oui, pas de seconde dissolution dans l''année suivant les élections',
   'true', '0'),

  ('2323da7d-00a8-42be-bf1d-5fb1338a348d', 'f2000002-0000-0000-0000-000000000099',
   'Aucune limite',
   'false', '1'),

  ('fb0e32f1-4869-47ff-9b38-8322dd386096', 'f2000002-0000-0000-0000-000000000099',
   'Uniquement le 14 juillet',
   'false', '2'),

  ('0b379f89-b904-47ff-93b7-56607e104494', 'f2000002-0000-0000-0000-000000000099',
   'Uniquement en cas de guerre',
   'false', '3'),

  ('35f0ab70-4831-4ec8-aa2f-59c610420913', 'f2000002-0000-0000-0000-00000000009a',
   'Saisir la CADA puis le tribunal administratif',
   'true', '0'),

  ('aae9fd64-0fd4-4ca8-8a5f-f21a048996ad', 'f2000002-0000-0000-0000-00000000009a',
   'Forcer la porte',
   'false', '1'),

  ('52fa1ed2-30eb-4ffa-8102-86db42e9a026', 'f2000002-0000-0000-0000-00000000009a',
   'Rien faire',
   'false', '2'),

  ('75332603-929f-482d-a37a-e38315a10f56', 'f2000002-0000-0000-0000-00000000009a',
   'Saisir l''OTAN',
   'false', '3');
