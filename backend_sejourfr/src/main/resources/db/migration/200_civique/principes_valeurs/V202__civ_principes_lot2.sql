-- ============================================================================
-- V202 — Civique : Principes et valeurs (lot 2)
-- ----------------------------------------------------------------------------
-- Questions + choix. Filtre: 11111111-0000-0000-0000-000000000001 .
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('f0000001-0000-0000-0000-00000000010e', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Depuis quand "Liberté, Égalité, Fraternité" est-elle la devise officielle de la République ?',
   'La devise est officiellement adoptée sous la IIIe République, en 1880. Elle est ensuite inscrite dans les Constitutions de 1946 et 1958.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000010f', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'De quel événement historique vient la devise "Liberté, Égalité, Fraternité" ?',
   'La devise a été popularisée par la Révolution française de 1789. Les trois mots résument les idéaux des révolutionnaires.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000110', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que l''égalité des chances en France ?',
   'L''égalité des chances signifie que chacun, quelle que soit son origine sociale ou son milieu, doit pouvoir accéder aux mêmes opportunités (école, emploi, logement).',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000111', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'À quelle valeur de la République le bénévolat et le service civique sont-ils liés ?',
   'Le bénévolat et le service civique sont des engagements pour aider les autres : ils sont une expression concrète de la fraternité.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000112', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce qu''une République ?',
   'Une République est un régime politique dans lequel le pouvoir n''appartient ni à une famille royale ni à une personne unique, mais au peuple, qui l''exerce par ses représentants élus.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000113', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que la démocratie ?',
   'La démocratie est un système politique où le peuple choisit ses représentants par des élections libres. Elle garantit aussi les libertés fondamentales et le respect des minorités.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000114', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que le suffrage universel ?',
   'Le suffrage universel signifie que tous les citoyens majeurs ont le droit de vote, sans condition de fortune, de sexe ou de race. C''est un fondement de la démocratie.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000115', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Depuis quelle année les femmes ont-elles le droit de vote en France ?',
   'Les femmes ont obtenu le droit de vote en 1944, par une ordonnance du général de Gaulle. Elles ont voté pour la première fois en 1945.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000116', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Depuis quand le suffrage universel masculin existe-t-il en France ?',
   'Le suffrage universel masculin a été instauré en 1848, sous la IIe République. Le suffrage universel complet (hommes et femmes) date de 1944.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000117', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qu''est-ce que la souveraineté nationale ?',
   'La souveraineté nationale signifie que le pouvoir politique appartient à la nation, c''est-à-dire au peuple. Il s''exerce par les représentants élus et par le référendum.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000118', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'En quelle année la première République française a-t-elle été proclamée ?',
   'La première République a été proclamée le 22 septembre 1792, après la chute de la monarchie. La France a ensuite connu plusieurs régimes avant la stabilité républicaine.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000119', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Combien y a-t-il eu de Républiques en France depuis 1792 ?',
   'La France a connu cinq Républiques : Ire (1792), IIe (1848), IIIe (1870), IVe (1946) et Ve (1958, régime actuel).',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000011a', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel homme politique a fondé la Ve République ?',
   'La Ve République a été fondée en 1958 par le général Charles de Gaulle, qui en est aussi le premier Président (1959-1969).',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000011b', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que la Déclaration des droits de l''homme et du citoyen ?',
   'Adoptée le 26 août 1789, c''est un texte fondateur de la Révolution qui proclame les droits naturels et l''égalité des hommes. Elle a aujourd''hui valeur constitutionnelle.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000011c', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que la parité en politique ?',
   'La parité est le principe d''égale représentation des hommes et des femmes, notamment sur les listes électorales. La loi impose la parité dans plusieurs scrutins depuis 2000.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000011d', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Pour un même travail, une femme et un homme doivent-ils être payés pareil ?',
   'Oui. Le principe "à travail égal, salaire égal" est inscrit dans la loi depuis 1972. Toute discrimination salariale fondée sur le sexe est interdite et punie.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000011e', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le mariage entre deux personnes de même sexe est-il autorisé en France ?',
   'Oui. Depuis la loi du 17 mai 2013, deux personnes de même sexe peuvent se marier en France et adopter des enfants ensemble.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000011f', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Quel numéro gratuit appeler en cas de violences conjugales ?',
   'Le 3919 est le numéro national d''écoute pour les femmes victimes de violences (anonyme, gratuit). En urgence, on appelle aussi le 17 (police) ou le 112.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000120', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Le harcèlement sexuel est-il un délit en France ?',
   'Oui. Le harcèlement sexuel est un délit puni de prison et d''amende. La loi protège toutes les personnes, dans le travail comme dans la vie courante.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000121', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce qu''une discrimination ?',
   'Une discrimination consiste à traiter une personne moins bien qu''une autre dans une situation comparable, sur la base d''un critère interdit par la loi (origine, sexe, religion, handicap, âge...).',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000122', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Parmi ces critères, lequel ne peut PAS justifier un traitement défavorable selon la loi française ?',
   'La loi interdit toute discrimination fondée sur l''origine, le sexe, la religion, l''orientation sexuelle, l''âge, le handicap, l''état de santé, l''apparence... (plus de 20 critères).',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000123', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le racisme est-il puni par la loi en France ?',
   'Oui. Les propos et actes racistes sont des délits punis de prison et d''amende. La loi Pleven (1972) et la loi Gayssot (1990) renforcent ce dispositif.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000124', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle autorité peut être saisie gratuitement en cas de discrimination ?',
   'Le Défenseur des droits est une autorité indépendante qui défend les droits des citoyens. Sa saisine est gratuite et il peut agir en cas de discrimination, violence policière ou atteinte aux droits.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000125', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'L''homophobie (propos ou actes haineux envers les personnes homosexuelles) est-elle un délit ?',
   'Oui. Depuis 2003, les propos et actes homophobes sont des délits punis comme les autres formes de discrimination, par la prison et l''amende.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000126', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'En quelle année a été votée la loi interdisant les signes religieux ostensibles à l''école publique ?',
   'La loi du 15 mars 2004 interdit le port de signes religieux ostensibles (voile, kippa, grande croix...) dans les écoles, collèges et lycées publics.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000127', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que dit la loi du 15 mars 2004 ?',
   'Elle interdit dans les écoles, collèges et lycées publics les signes religieux ostensibles. L''objectif est de protéger l''école comme espace neutre, conforme à la laïcité.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000128', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Un fonctionnaire (agent public) peut-il porter un signe religieux visible pendant son service ?',
   'Non. Le principe de neutralité impose à tous les agents publics (enseignants, policiers, employés de mairie...) de ne pas manifester leurs opinions religieuses dans le cadre de leurs fonctions.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000129', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que prévoit la Charte de la laïcité à l''école, adoptée en 2013 ?',
   'La Charte de la laïcité à l''école rappelle les principes de neutralité et de laïcité à l''école publique : respect des différences, liberté de conscience, refus du prosélytisme.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000012a', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Existe-t-il une exception au régime de laïcité français dans certaines régions ?',
   'Oui. En Alsace et en Moselle, le Concordat de 1801 est toujours en vigueur : l''État rémunère certains ministres du culte (catholique, protestant, israélite). Ces départements n''étaient pas français en 1905.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000012b', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Une mère portant un voile religieux peut-elle accompagner une sortie scolaire ?',
   'Oui. Les parents accompagnateurs ne sont pas des agents publics : ils ne sont pas tenus à la neutralité religieuse, sauf s''ils troublent l''ordre ou se livrent au prosélytisme.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000012c', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que la liberté de réunion ?',
   'C''est le droit de se rassembler pacifiquement (manifestations, réunions publiques ou privées), sous réserve du respect de l''ordre public.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000012d', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que la liberté de la presse ?',
   'C''est le droit pour les journalistes et les médias d''informer librement, sans censure préalable. La loi de 1881 protège cette liberté fondamentale, avec des limites (diffamation, vie privée).',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000012e', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que la liberté d''aller et venir ?',
   'C''est le droit de circuler librement sur le territoire français, de choisir son lieu de résidence et, pour les citoyens, de quitter et de revenir dans le pays.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000012f', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'La liberté syndicale est-elle reconnue en France ?',
   'Oui. Tout salarié peut adhérer librement à un syndicat, en créer un ou ne pas s''affilier. La loi protège les représentants syndicaux dans l''entreprise.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000130', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le droit de grève est-il reconnu en France ?',
   'Oui. Le droit de grève a valeur constitutionnelle (Préambule de 1946). Il est encadré par la loi, notamment dans les services publics (préavis, service minimum).',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000131', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Un employeur peut-il refuser d''embaucher une femme parce qu''elle est enceinte ?',
   'Non. C''est une discrimination interdite par le Code du travail, punie de prison et d''amende. La grossesse ne peut être un motif de refus d''embauche ni de licenciement.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000132', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Un propriétaire peut-il refuser de louer un appartement à cause de l''origine du candidat locataire ?',
   'Non. C''est une discrimination raciale interdite par la loi, qui peut être signalée au Défenseur des droits. Le propriétaire peut refuser pour des motifs objectifs (revenus, garanties) mais pas pour l''origine.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000133', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Un maire peut-il refuser de marier deux personnes parce qu''elles sont de religions différentes ?',
   'Non. Le mariage civil est un acte républicain laïque. Le maire, en sa qualité d''officier d''état civil, ne peut refuser un mariage pour des motifs religieux ou personnels.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000134', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Un médecin peut-il refuser un patient à cause de son origine ou de sa nationalité ?',
   'Non. Le Code de la santé publique et le code de déontologie médicale interdisent toute discrimination. Le serment d''Hippocrate engage le médecin à soigner sans distinction.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000135', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'MISE_SITUATION',
   'À l''hôpital public, un patient peut-il refuser d''être soigné par une femme médecin ?',
   'Non. L''égalité hommes-femmes et la neutralité du service public s''imposent : le patient ne choisit pas son soignant en fonction de son sexe. Refuser un soin pour ce motif n''est pas un droit.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000136', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Une commune peut-elle financer la construction d''un nouveau lieu de culte ?',
   'Non. La loi de 1905 interdit à l''État et aux collectivités de subventionner les cultes. Elles peuvent en revanche entretenir les édifices religieux construits avant 1905 (propriétés publiques).',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000137', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Un syndicat peut-il refuser l''adhésion d''un salarié à cause de sa religion ?',
   'Non. La discrimination religieuse est interdite, y compris dans les associations et syndicats. La liberté syndicale s''accompagne du respect de la non-discrimination.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000138', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'A-t-on le droit de critiquer publiquement une religion en France ?',
   'Oui. La critique d''idées, de dogmes ou de pratiques religieuses est autorisée au nom de la liberté d''expression. En revanche, attaquer les personnes (insultes, incitation à la haine) reste interdit.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000139', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'MISE_SITUATION',
   'Une entreprise privée peut-elle imposer à ses salariés une tenue de travail neutre, sans signes religieux ?',
   'Oui, sous conditions. Le règlement intérieur peut limiter le port de signes religieux s''il s''agit d''une exigence professionnelle objective et proportionnée (sécurité, neutralité face aux clients).',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000013a', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'À partir de quel âge l''instruction est-elle obligatoire en France ?',
   'L''instruction est obligatoire de 3 à 16 ans (depuis 2019, auparavant à partir de 6 ans). Elle peut être suivie à l''école publique, privée, ou à domicile sous conditions.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000013b', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'L''école publique en France est-elle gratuite ?',
   'Oui. L''école publique est gratuite, laïque et obligatoire depuis les lois Jules Ferry (1881-1882). C''est un fondement de la République.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000013c', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Que peut-on faire si on est témoin d''un acte ou de propos racistes ?',
   'On peut alerter la police (17 ou 112), porter plainte, ou saisir gratuitement le Défenseur des droits. Des associations comme SOS Racisme ou la LICRA accompagnent les victimes.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL);

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('aa742f08-4e40-4df8-a5e2-7a953dd81382', 'f0000001-0000-0000-0000-00000000010e',
   '1880, sous la IIIe République',
   'true', '0'),

  ('cfe58ed6-fc4f-4bc4-92b2-731c8dbe36c3', 'f0000001-0000-0000-0000-00000000010e',
   '1789, dès la Révolution',
   'false', '1'),

  ('3d9e3ee2-3961-49ed-8b1c-d436f8f6cec6', 'f0000001-0000-0000-0000-00000000010e',
   '1958, avec la Ve République',
   'false', '2'),

  ('0103fc20-53fc-477b-9ceb-bab81856a30d', 'f0000001-0000-0000-0000-00000000010e',
   '2000, récemment',
   'false', '3'),

  ('9bbd6beb-4974-41e8-819e-afc73f56dfc2', 'f0000001-0000-0000-0000-00000000010f',
   'La Révolution française de 1789',
   'true', '0'),

  ('88a4dcd8-a1b5-4e2c-86bf-39d4ad7335e3', 'f0000001-0000-0000-0000-00000000010f',
   'La conquête de l''Algérie',
   'false', '1'),

  ('518cd060-11e8-4283-944f-b47ae92e9dbe', 'f0000001-0000-0000-0000-00000000010f',
   'La fin de la Première Guerre mondiale',
   'false', '2'),

  ('7288c043-489f-4f5b-87e3-3202007e39bb', 'f0000001-0000-0000-0000-00000000010f',
   'Mai 1968',
   'false', '3'),

  ('af0c6e15-1509-474a-ae2c-78e3a584d9ac', 'f0000001-0000-0000-0000-000000000110',
   'Chacun doit pouvoir réussir, quelle que soit son origine sociale',
   'true', '0'),

  ('165abb6b-3d21-4606-ab3a-492c5714b3e9', 'f0000001-0000-0000-0000-000000000110',
   'Tout le monde gagne le même salaire',
   'false', '1'),

  ('4680e9c0-21b2-467d-b1b3-342bae3c4422', 'f0000001-0000-0000-0000-000000000110',
   'Tout le monde a le même métier',
   'false', '2'),

  ('5616d0c0-c29a-4d2d-bb28-498121b07166', 'f0000001-0000-0000-0000-000000000110',
   'Tout le monde possède les mêmes biens',
   'false', '3'),

  ('3c52266f-b298-4c9e-ac03-73fb0cce7417', 'f0000001-0000-0000-0000-000000000111',
   'La fraternité',
   'true', '0'),

  ('7f692697-6cf0-4dbb-8c7e-28b2950ea181', 'f0000001-0000-0000-0000-000000000111',
   'La laïcité',
   'false', '1'),

  ('eef1ab0f-cfd6-44c6-a426-13351d6f6962', 'f0000001-0000-0000-0000-000000000111',
   'La propriété privée',
   'false', '2'),

  ('bda1978a-2019-485a-862a-4323198a5711', 'f0000001-0000-0000-0000-000000000111',
   'La liberté de la presse',
   'false', '3'),

  ('93e7737c-47ef-472f-bb4d-365cb3c02f36', 'f0000001-0000-0000-0000-000000000112',
   'Un régime où le pouvoir appartient au peuple, pas à un roi',
   'true', '0'),

  ('4cecf006-1e5c-49f8-bec3-d81228ba6028', 'f0000001-0000-0000-0000-000000000112',
   'Une monarchie héréditaire',
   'false', '1'),

  ('b8649c78-15d2-4fbe-93bc-069ee1b4e82c', 'f0000001-0000-0000-0000-000000000112',
   'Un régime militaire',
   'false', '2'),

  ('000c0b6b-3d46-46a6-bd33-992313089579', 'f0000001-0000-0000-0000-000000000112',
   'Un État religieux',
   'false', '3'),

  ('f6e1b04e-034e-4ff9-b7ba-8eb3ffa5978d', 'f0000001-0000-0000-0000-000000000113',
   'Un système où le peuple choisit ses représentants par des élections',
   'true', '0'),

  ('f1a7108b-1302-4c70-a855-66d059bd365c', 'f0000001-0000-0000-0000-000000000113',
   'Le gouvernement d''une seule personne',
   'false', '1'),

  ('8250eba0-aacc-4243-87ff-49a038d77583', 'f0000001-0000-0000-0000-000000000113',
   'Un régime sans loi écrite',
   'false', '2'),

  ('c602b2d9-19da-49f5-acca-86fb61718d44', 'f0000001-0000-0000-0000-000000000113',
   'Un pays sans frontières',
   'false', '3'),

  ('c3268427-586a-494b-9eca-3937efa97908', 'f0000001-0000-0000-0000-000000000114',
   'Tous les citoyens majeurs ont le droit de vote',
   'true', '0'),

  ('b6970b7c-7602-4f52-87ca-fd2834609186', 'f0000001-0000-0000-0000-000000000114',
   'Seuls les hommes ont le droit de vote',
   'false', '1'),

  ('0f9ccd3d-364d-448d-9c93-2a3ad2c457ae', 'f0000001-0000-0000-0000-000000000114',
   'Seules les personnes payant des impôts votent',
   'false', '2'),

  ('e5c40fab-d768-4756-bca9-7aedd5c1603d', 'f0000001-0000-0000-0000-000000000114',
   'Le vote est réservé aux élus',
   'false', '3'),

  ('9b0c5121-23fd-4f4c-a906-905c63ade44f', 'f0000001-0000-0000-0000-000000000115',
   '1944',
   'true', '0'),

  ('23549812-1f0b-4184-8941-22f441984614', 'f0000001-0000-0000-0000-000000000115',
   '1848',
   'false', '1'),

  ('9099af19-7b07-494a-ac31-8e32ce130dea', 'f0000001-0000-0000-0000-000000000115',
   '1968',
   'false', '2'),

  ('1591fe2e-6898-42c7-9100-738b8859c50c', 'f0000001-0000-0000-0000-000000000115',
   '1981',
   'false', '3'),

  ('7b552a9c-85f7-4b64-859e-6322cc070a4f', 'f0000001-0000-0000-0000-000000000116',
   '1848',
   'true', '0'),

  ('3be53ff2-be2b-4507-a5a1-0145adf82e58', 'f0000001-0000-0000-0000-000000000116',
   '1789',
   'false', '1'),

  ('a25aa190-1fd9-47a1-a6c1-a87366c5780a', 'f0000001-0000-0000-0000-000000000116',
   '1875',
   'false', '2'),

  ('8e2a184e-bc28-4416-b3ee-b09e8d08b6e8', 'f0000001-0000-0000-0000-000000000116',
   '1944',
   'false', '3'),

  ('e9208875-d087-4405-9857-02f55e3c2574', 'f0000001-0000-0000-0000-000000000117',
   'Le pouvoir politique appartient au peuple',
   'true', '0'),

  ('5a7e6c6b-2bb0-4b49-a898-28d78284c762', 'f0000001-0000-0000-0000-000000000117',
   'Le pouvoir appartient au Président seul',
   'false', '1'),

  ('83e5c4fa-1b5c-4e63-b86d-d54acbabffab', 'f0000001-0000-0000-0000-000000000117',
   'Le pouvoir appartient à l''armée',
   'false', '2'),

  ('3b341531-2c78-4239-9f6c-e422d758105c', 'f0000001-0000-0000-0000-000000000117',
   'Le pouvoir appartient à une famille royale',
   'false', '3'),

  ('bc954967-0dfa-4ecc-bbd4-c05aaf38e098', 'f0000001-0000-0000-0000-000000000118',
   '1792',
   'true', '0'),

  ('0d3486f8-03c9-45e2-8154-114602b05399', 'f0000001-0000-0000-0000-000000000118',
   '1789',
   'false', '1'),

  ('1b8051e3-f7c5-451e-80b6-b808e2fced7c', 'f0000001-0000-0000-0000-000000000118',
   '1848',
   'false', '2'),

  ('148e7d0a-a705-4fbd-a078-603a4fa1bb7d', 'f0000001-0000-0000-0000-000000000118',
   '1870',
   'false', '3'),

  ('632cef17-532c-4529-a22a-9ca4b1bbab6e', 'f0000001-0000-0000-0000-000000000119',
   'Cinq',
   'true', '0'),

  ('5f9676f0-e336-4ef1-9de1-3d6bbcd041c9', 'f0000001-0000-0000-0000-000000000119',
   'Trois',
   'false', '1'),

  ('7e5cc0b3-6ca7-47c2-9604-b86f856e6500', 'f0000001-0000-0000-0000-000000000119',
   'Quatre',
   'false', '2'),

  ('be701a52-b6a0-4e8a-8e0a-2a09b3b657e1', 'f0000001-0000-0000-0000-000000000119',
   'Sept',
   'false', '3'),

  ('21245b94-f406-4d5f-a062-3b9afba77968', 'f0000001-0000-0000-0000-00000000011a',
   'Charles de Gaulle',
   'true', '0'),

  ('97249701-7d11-4c57-a881-65c23b268679', 'f0000001-0000-0000-0000-00000000011a',
   'François Mitterrand',
   'false', '1'),

  ('ec5b8f45-549c-4612-8c87-6ede0ff92581', 'f0000001-0000-0000-0000-00000000011a',
   'Georges Pompidou',
   'false', '2'),

  ('17930100-ab60-4223-8718-e1b50e343fe6', 'f0000001-0000-0000-0000-00000000011a',
   'Léon Blum',
   'false', '3'),

  ('371c630f-b59e-48e9-8c1c-86f159298222', 'f0000001-0000-0000-0000-00000000011b',
   'Un texte de 1789 qui proclame les droits fondamentaux',
   'true', '0'),

  ('3dd62c14-b1f9-4749-a00a-2aa67cbefe68', 'f0000001-0000-0000-0000-00000000011b',
   'Une loi récente sur l''immigration',
   'false', '1'),

  ('3ad7ef48-98f5-4ab0-9c94-eeb7c0b832fd', 'f0000001-0000-0000-0000-00000000011b',
   'Un traité militaire',
   'false', '2'),

  ('9dac56eb-b0db-4875-841f-7b5f8db42be8', 'f0000001-0000-0000-0000-00000000011b',
   'Un texte religieux',
   'false', '3'),

  ('39ff8211-0219-45c9-8647-894f0929a6b9', 'f0000001-0000-0000-0000-00000000011c',
   'L''égale représentation des hommes et des femmes',
   'true', '0'),

  ('6fb63f46-2c2f-4b18-b6af-199205a49fe9', 'f0000001-0000-0000-0000-00000000011c',
   'Le même salaire pour tous',
   'false', '1'),

  ('268ebdbb-9d48-4539-8166-9b131f757852', 'f0000001-0000-0000-0000-00000000011c',
   'L''égalité entre les régions',
   'false', '2'),

  ('6f4f441b-7bba-4bac-ba32-376e1fd53e73', 'f0000001-0000-0000-0000-00000000011c',
   'L''égalité entre les religions',
   'false', '3'),

  ('3fba927f-d933-40f5-b86a-3cf65bf2cb53', 'f0000001-0000-0000-0000-00000000011d',
   'Oui, c''est obligatoire (à travail égal, salaire égal)',
   'true', '0'),

  ('97d5fcee-567c-4596-affc-c49ce66ade80', 'f0000001-0000-0000-0000-00000000011d',
   'Non, l''employeur décide librement',
   'false', '1'),

  ('9271fbd6-19f0-413e-9d24-df3c0fbfb498', 'f0000001-0000-0000-0000-00000000011d',
   'Non, les hommes gagnent plus par tradition',
   'false', '2'),

  ('b86631a1-ce3b-4d58-a602-d546e92cebbe', 'f0000001-0000-0000-0000-00000000011d',
   'Uniquement dans la fonction publique',
   'false', '3'),

  ('4cf81daa-7794-4c9d-b6ad-ae774a8d0ee6', 'f0000001-0000-0000-0000-00000000011e',
   'Oui, depuis 2013',
   'true', '0'),

  ('5302f709-d0ed-4fc1-9aaf-2ed6952df4e3', 'f0000001-0000-0000-0000-00000000011e',
   'Non, c''est interdit',
   'false', '1'),

  ('78e83bb7-0d23-44e9-89da-4084c5495c97', 'f0000001-0000-0000-0000-00000000011e',
   'Oui, mais uniquement dans certaines communes',
   'false', '2'),

  ('ef8719d7-191b-42aa-a76f-0f132a65e05e', 'f0000001-0000-0000-0000-00000000011e',
   'Non, sauf autorisation religieuse',
   'false', '3'),

  ('d9031351-eca3-4463-bb39-f1ca00c12a31', 'f0000001-0000-0000-0000-00000000011f',
   'Le 3919',
   'true', '0'),

  ('0f35519f-fe16-4206-8e56-3837920933cb', 'f0000001-0000-0000-0000-00000000011f',
   'Le 15',
   'false', '1'),

  ('74393be3-cc61-4d45-94b2-f48c6f57fa56', 'f0000001-0000-0000-0000-00000000011f',
   'Le 18',
   'false', '2'),

  ('2bbab77e-05e8-4cbb-95e0-632e9fdae7fc', 'f0000001-0000-0000-0000-00000000011f',
   'Le 3615',
   'false', '3'),

  ('6c04121d-0335-467e-90ef-a3b6f0500ddf', 'f0000001-0000-0000-0000-000000000120',
   'Oui, c''est un délit puni par la loi',
   'true', '0'),

  ('9c7f701b-d599-4da2-8b21-3198bd26ead7', 'f0000001-0000-0000-0000-000000000120',
   'Non, ce n''est qu''une faute morale',
   'false', '1'),

  ('313c08a1-4f5e-4c86-a160-8841926f59f4', 'f0000001-0000-0000-0000-000000000120',
   'Uniquement entre adultes consentants',
   'false', '2'),

  ('97ca61b8-13b2-429f-9bf2-3ef6cd3a288f', 'f0000001-0000-0000-0000-000000000120',
   'Uniquement sur le lieu de travail',
   'false', '3'),

  ('d951a4f4-82ac-4ef3-a908-34a2d025d271', 'f0000001-0000-0000-0000-000000000121',
   'Traiter quelqu''un moins bien à cause d''un critère interdit',
   'true', '0'),

  ('e901ff38-475b-4dfd-8fbc-5145f3510478', 'f0000001-0000-0000-0000-000000000121',
   'Respecter les préférences de chacun',
   'false', '1'),

  ('451ffb1b-e318-46fe-a029-5ad3b0b2965a', 'f0000001-0000-0000-0000-000000000121',
   'Faire payer un impôt',
   'false', '2'),

  ('84af159a-73e7-4ed4-84ea-be1a0c411167', 'f0000001-0000-0000-0000-000000000121',
   'Inviter ses amis à une fête privée',
   'false', '3'),

  ('77946ffb-671d-4882-a806-fd0af06071de', 'f0000001-0000-0000-0000-000000000122',
   'L''origine de la personne',
   'true', '0'),

  ('ed9e793f-67b2-4523-9440-228b80e72d62', 'f0000001-0000-0000-0000-000000000122',
   'L''expérience professionnelle',
   'false', '1'),

  ('8454a5fb-5582-4383-bf07-f650e04c7fc4', 'f0000001-0000-0000-0000-000000000122',
   'Les diplômes obtenus',
   'false', '2'),

  ('230d827f-0900-4abe-97ab-8cf3d7d0bc6b', 'f0000001-0000-0000-0000-000000000122',
   'Les compétences techniques',
   'false', '3'),

  ('34ea89ec-cddc-4d8f-90dc-9f6c61888753', 'f0000001-0000-0000-0000-000000000123',
   'Oui, c''est un délit',
   'true', '0'),

  ('fc01cdc3-0019-4012-a694-d3071b4aa67b', 'f0000001-0000-0000-0000-000000000123',
   'Non, c''est protégé par la liberté d''expression',
   'false', '1'),

  ('0c5547f9-7f8c-4777-919c-5505aafc3518', 'f0000001-0000-0000-0000-000000000123',
   'Uniquement dans la rue',
   'false', '2'),

  ('ce84f125-2518-4419-965b-de0095d427e6', 'f0000001-0000-0000-0000-000000000123',
   'Uniquement contre les Français',
   'false', '3'),

  ('4badd0c3-e6b9-4933-9997-dfde74cf1740', 'f0000001-0000-0000-0000-000000000124',
   'Le Défenseur des droits',
   'true', '0'),

  ('6a4718ab-45a6-44c2-8caa-8701470469f4', 'f0000001-0000-0000-0000-000000000124',
   'Le Président de la République en personne',
   'false', '1'),

  ('c5ca649e-3750-437d-829e-54eac4e61f43', 'f0000001-0000-0000-0000-000000000124',
   'La gendarmerie nationale uniquement',
   'false', '2'),

  ('a8abd8be-5acd-4652-9494-d4a1ef90fc34', 'f0000001-0000-0000-0000-000000000124',
   'Une association sportive',
   'false', '3'),

  ('32f8be5e-0b36-48f8-b6b7-1476f87f07ac', 'f0000001-0000-0000-0000-000000000125',
   'Oui, c''est un délit puni par la loi',
   'true', '0'),

  ('95eb0c6d-2750-4a74-92ae-fce9c2768cfa', 'f0000001-0000-0000-0000-000000000125',
   'Non, c''est une opinion personnelle',
   'false', '1'),

  ('5a1f6b26-475a-4f70-a80d-e0ebbae10959', 'f0000001-0000-0000-0000-000000000125',
   'Uniquement contre des personnes mariées',
   'false', '2'),

  ('878ac01b-abbf-45e8-a473-f45f239fcfd6', 'f0000001-0000-0000-0000-000000000125',
   'Uniquement dans le sport',
   'false', '3'),

  ('5ff3d6e0-179f-42f9-b718-6273d69796b5', 'f0000001-0000-0000-0000-000000000126',
   '2004',
   'true', '0'),

  ('a8cd43e0-77e1-485b-b8f1-67cd3c3c912b', 'f0000001-0000-0000-0000-000000000126',
   '1905',
   'false', '1'),

  ('58b1903a-fd3a-487e-96a3-1f112adb68c0', 'f0000001-0000-0000-0000-000000000126',
   '1989',
   'false', '2'),

  ('5b8f754e-991b-458a-97ba-c0c3bc386be9', 'f0000001-0000-0000-0000-000000000126',
   '2010',
   'false', '3'),

  ('fc14e1af-6945-4e6c-86c1-af7a3cd573ac', 'f0000001-0000-0000-0000-000000000127',
   'Elle interdit les signes religieux ostensibles à l''école publique',
   'true', '0'),

  ('ab875cb6-e316-4e89-ac85-2ca6f27826ea', 'f0000001-0000-0000-0000-000000000127',
   'Elle interdit toutes les religions en France',
   'false', '1'),

  ('9e456d0c-d72d-4ef3-a072-2dc0a9dd0ee5', 'f0000001-0000-0000-0000-000000000127',
   'Elle oblige les élèves à aller à la messe',
   'false', '2'),

  ('28355ef5-6252-4848-b37e-a4780756cc10', 'f0000001-0000-0000-0000-000000000127',
   'Elle réserve l''école aux Français',
   'false', '3'),

  ('90a3aa5a-f4e2-433e-8755-8d6cdf926ae4', 'f0000001-0000-0000-0000-000000000128',
   'Non, il a un devoir de neutralité',
   'true', '0'),

  ('6fdb41ac-8a4a-419a-87c8-ad490a340d4d', 'f0000001-0000-0000-0000-000000000128',
   'Oui, c''est sa liberté religieuse',
   'false', '1'),

  ('1de795be-0f0d-49f3-8350-29f1af3ec2e8', 'f0000001-0000-0000-0000-000000000128',
   'Oui, mais uniquement le vendredi',
   'false', '2'),

  ('eaf391ae-a631-4e7f-94a0-3ac234272ab8', 'f0000001-0000-0000-0000-000000000128',
   'Uniquement avec autorisation écrite',
   'false', '3'),

  ('a31e212f-ed4c-418e-88c0-41e1b3e0ccc8', 'f0000001-0000-0000-0000-000000000129',
   'Les règles de laïcité à l''école pour élèves et personnels',
   'true', '0'),

  ('8368468a-e8bc-441a-9cee-717b4478b5bb', 'f0000001-0000-0000-0000-000000000129',
   'L''interdiction des religions dans la société',
   'false', '1'),

  ('4c5260b6-e3ea-4d21-9042-229b0cc04230', 'f0000001-0000-0000-0000-000000000129',
   'L''obligation de pratiquer une religion',
   'false', '2'),

  ('3ba5e8f3-acea-4310-a452-abdbb9106c82', 'f0000001-0000-0000-0000-000000000129',
   'Les horaires des cours d''éducation religieuse',
   'false', '3'),

  ('9f1260b1-68c4-4172-8af4-024507b64955', 'f0000001-0000-0000-0000-00000000012a',
   'Oui, en Alsace et Moselle (Concordat de 1801 toujours en vigueur)',
   'true', '0'),

  ('6289d0bf-1cce-4abe-a81b-5f9997376353', 'f0000001-0000-0000-0000-00000000012a',
   'Non, la laïcité s''applique partout de la même manière',
   'false', '1'),

  ('0243a4c2-1f11-47d6-b73d-e37da32ecb35', 'f0000001-0000-0000-0000-00000000012a',
   'Oui, en Corse uniquement',
   'false', '2'),

  ('01d57688-4140-48a8-a6ba-a89a15c5e2fc', 'f0000001-0000-0000-0000-00000000012a',
   'Oui, dans les départements d''outre-mer',
   'false', '3'),

  ('74cd8c15-31d9-464c-b7bc-62491d1947dc', 'f0000001-0000-0000-0000-00000000012b',
   'Oui, sauf trouble à l''ordre ou prosélytisme',
   'true', '0'),

  ('995b336e-d786-4b94-9959-9cdd91d84520', 'f0000001-0000-0000-0000-00000000012b',
   'Non, c''est interdit en toutes circonstances',
   'false', '1'),

  ('bafc6aff-cf62-4ec4-9dce-8c398c26791f', 'f0000001-0000-0000-0000-00000000012b',
   'Oui, mais uniquement les mères françaises',
   'false', '2'),

  ('c7040e66-1e4f-4c5f-9b87-bf08308d5676', 'f0000001-0000-0000-0000-00000000012b',
   'Non, sauf accord du préfet',
   'false', '3'),

  ('a90e7f31-7455-4e02-9c3c-6ae6fb8d559d', 'f0000001-0000-0000-0000-00000000012c',
   'Le droit de se rassembler pacifiquement',
   'true', '0'),

  ('b613dc5b-51ba-4367-820d-1c1ed66e67e6', 'f0000001-0000-0000-0000-00000000012c',
   'L''obligation de participer aux fêtes officielles',
   'false', '1'),

  ('18007211-a663-4336-b4b5-34d183463eb0', 'f0000001-0000-0000-0000-00000000012c',
   'Le droit de bloquer une rue sans déclaration',
   'false', '2'),

  ('35419675-2efa-4f00-984c-2c00e383d6bc', 'f0000001-0000-0000-0000-00000000012c',
   'Le droit de créer une milice privée',
   'false', '3'),

  ('181311bc-4984-4f5b-ac42-965ee2b0bfb0', 'f0000001-0000-0000-0000-00000000012d',
   'Le droit pour les médias d''informer librement',
   'true', '0'),

  ('7f0fb655-b5d4-48cb-acc9-4b32e78f2728', 'f0000001-0000-0000-0000-00000000012d',
   'Le droit de mentir publiquement',
   'false', '1'),

  ('11bec5a3-3c03-45ad-b9e1-16d75817f6ac', 'f0000001-0000-0000-0000-00000000012d',
   'Le monopole de l''État sur les journaux',
   'false', '2'),

  ('182c9a9e-4b34-43c8-95e1-c9b5bea48b67', 'f0000001-0000-0000-0000-00000000012d',
   'L''obligation de lire la presse chaque jour',
   'false', '3'),

  ('129c6288-03f2-4c1f-bf64-a52e06354f93', 'f0000001-0000-0000-0000-00000000012e',
   'Le droit de circuler librement et de choisir son domicile',
   'true', '0'),

  ('e175cc08-94d0-470d-aa4c-c142eb0ba041', 'f0000001-0000-0000-0000-00000000012e',
   'L''obligation de demander un visa pour changer de ville',
   'false', '1'),

  ('3a3d07a2-4d5c-46ef-9a18-0c321979acf6', 'f0000001-0000-0000-0000-00000000012e',
   'Le droit réservé aux fonctionnaires',
   'false', '2'),

  ('997257b6-72bc-46cf-9fae-4d0c54537aaa', 'f0000001-0000-0000-0000-00000000012e',
   'Le droit de conduire sans permis',
   'false', '3'),

  ('22c6ace1-fdd7-4e51-afc2-54bc3be8a662', 'f0000001-0000-0000-0000-00000000012f',
   'Oui, chacun peut adhérer ou non à un syndicat',
   'true', '0'),

  ('ac234f73-09fa-41a7-aab7-3ad3b8caae15', 'f0000001-0000-0000-0000-00000000012f',
   'Non, les syndicats sont interdits',
   'false', '1'),

  ('104e2db0-ea15-4cf4-8020-f4239d28a179', 'f0000001-0000-0000-0000-00000000012f',
   'Oui, mais uniquement dans le public',
   'false', '2'),

  ('21026884-7261-465d-917a-43032596ce75', 'f0000001-0000-0000-0000-00000000012f',
   'Non, sauf pour les cadres',
   'false', '3'),

  ('894860c6-86b8-41f2-9682-c1fca1965a44', 'f0000001-0000-0000-0000-000000000130',
   'Oui, c''est un droit constitutionnel encadré par la loi',
   'true', '0'),

  ('ed474db8-b863-41c0-9236-87f5fb71cb5a', 'f0000001-0000-0000-0000-000000000130',
   'Non, c''est interdit en France',
   'false', '1'),

  ('4be16a61-9cbb-4ef9-aec1-a6e7208774fb', 'f0000001-0000-0000-0000-000000000130',
   'Oui, mais uniquement les samedis',
   'false', '2'),

  ('d915de44-8e9f-42cb-8937-c60d9cc23b5c', 'f0000001-0000-0000-0000-000000000130',
   'Non, sauf pour les agriculteurs',
   'false', '3'),

  ('78b268ab-e84e-47d8-b52b-e53af602adce', 'f0000001-0000-0000-0000-000000000131',
   'Non, c''est une discrimination interdite',
   'true', '0'),

  ('e2ee1b6f-fe8d-4197-acda-e3aceaf147f3', 'f0000001-0000-0000-0000-000000000131',
   'Oui, c''est son droit',
   'false', '1'),

  ('57717602-0391-4dfe-bba3-8c0fdd8af7c0', 'f0000001-0000-0000-0000-000000000131',
   'Oui, pour protéger la santé de la femme',
   'false', '2'),

  ('58643d56-64e6-46af-9416-051b60b782a1', 'f0000001-0000-0000-0000-000000000131',
   'Oui, dans les petites entreprises',
   'false', '3'),

  ('d0503d58-2fa3-40c1-99f8-e110f327b730', 'f0000001-0000-0000-0000-000000000132',
   'Non, c''est une discrimination interdite',
   'true', '0'),

  ('bb4a4080-0e4b-4c38-a76e-04cd1e0e8b35', 'f0000001-0000-0000-0000-000000000132',
   'Oui, le propriétaire choisit son locataire librement',
   'false', '1'),

  ('050b21b9-1424-4417-8e32-80e75d7ab2fe', 'f0000001-0000-0000-0000-000000000132',
   'Oui, sauf en HLM',
   'false', '2'),

  ('c7c83c72-e13e-41b3-9168-9eb2b20a7645', 'f0000001-0000-0000-0000-000000000132',
   'Uniquement dans les grandes villes',
   'false', '3'),

  ('5be9602a-8048-4afe-b348-d0ae5c7e4539', 'f0000001-0000-0000-0000-000000000133',
   'Non, le mariage civil est laïque et obligatoire pour le maire',
   'true', '0'),

  ('9670fa58-2604-4cc6-a333-cee0413865f1', 'f0000001-0000-0000-0000-000000000133',
   'Oui, si la religion du maire l''interdit',
   'false', '1'),

  ('67711128-3061-4295-bb87-f337ae1920f5', 'f0000001-0000-0000-0000-000000000133',
   'Oui, si l''un des conjoints n''est pas baptisé',
   'false', '2'),

  ('4e7903bb-6ee1-4137-8ed2-9afe3843ee2a', 'f0000001-0000-0000-0000-000000000133',
   'Oui, avec accord du conseil municipal',
   'false', '3'),

  ('41ca11d0-1eda-46a3-b24d-bdc954ee529f', 'f0000001-0000-0000-0000-000000000134',
   'Non, c''est une discrimination interdite',
   'true', '0'),

  ('f9b31cb4-f7d1-453d-a611-538767f7ab0e', 'f0000001-0000-0000-0000-000000000134',
   'Oui, c''est sa clientèle privée',
   'false', '1'),

  ('0f317d08-fc3e-40f6-998c-e13af3a55e77', 'f0000001-0000-0000-0000-000000000134',
   'Oui, sauf urgence vitale',
   'false', '2'),

  ('20fccbdb-2da2-465d-a70d-75ea72bec686', 'f0000001-0000-0000-0000-000000000134',
   'Uniquement dans le secteur privé',
   'false', '3'),

  ('7e639365-afa9-4a80-8075-70129706eb1b', 'f0000001-0000-0000-0000-000000000135',
   'Non, l''égalité et le service public s''imposent',
   'true', '0'),

  ('a0571676-5540-45d6-8f83-371e3d86ad4f', 'f0000001-0000-0000-0000-000000000135',
   'Oui, c''est son droit personnel',
   'false', '1'),

  ('9e0e7305-c5a2-4cb8-97cf-62f141edc068', 'f0000001-0000-0000-0000-000000000135',
   'Oui, si sa religion l''impose',
   'false', '2'),

  ('2c74ff41-a762-4dcd-b953-0862d1aaca50', 'f0000001-0000-0000-0000-000000000135',
   'Uniquement avec l''accord du chef de service',
   'false', '3'),

  ('f148b479-26ed-458a-8b64-b1b6be9d8d7c', 'f0000001-0000-0000-0000-000000000136',
   'Non, la loi de 1905 l''interdit',
   'true', '0'),

  ('f130f296-f58e-4eab-a48f-fffdb69743bd', 'f0000001-0000-0000-0000-000000000136',
   'Oui, librement',
   'false', '1'),

  ('234f198b-ec60-46ee-b675-b6cf648e8770', 'f0000001-0000-0000-0000-000000000136',
   'Oui, pour la religion majoritaire seulement',
   'false', '2'),

  ('8f7c4b96-f375-469d-a989-83a7fe176a22', 'f0000001-0000-0000-0000-000000000136',
   'Oui, avec accord du préfet',
   'false', '3'),

  ('ddf951a4-3a0f-46ab-8ee4-1936e88182b6', 'f0000001-0000-0000-0000-000000000137',
   'Non, c''est une discrimination interdite',
   'true', '0'),

  ('6a714ed9-3707-4a05-af7a-2e7e2bf13050', 'f0000001-0000-0000-0000-000000000137',
   'Oui, le syndicat choisit ses adhérents',
   'false', '1'),

  ('9a397443-f5d1-4eed-9fab-faf7a0e8b0db', 'f0000001-0000-0000-0000-000000000137',
   'Oui, si le syndicat est confessionnel',
   'false', '2'),

  ('ad0060bc-f1f4-45b6-a090-0b6406fe186e', 'f0000001-0000-0000-0000-000000000137',
   'Uniquement avec accord de l''entreprise',
   'false', '3'),

  ('845decc4-d25b-49b2-b057-d4658551ee42', 'f0000001-0000-0000-0000-000000000138',
   'Oui, on peut critiquer une religion ; pas attaquer les personnes',
   'true', '0'),

  ('9169ea1b-bc3f-4f1b-9636-3ee4e3af207d', 'f0000001-0000-0000-0000-000000000138',
   'Non, le blasphème est puni par la loi',
   'false', '1'),

  ('6ec49daa-20ce-458b-b457-9b173569f210', 'f0000001-0000-0000-0000-000000000138',
   'Oui, sans aucune limite',
   'false', '2'),

  ('22a05818-3e38-4ab5-aa02-389c008b0270', 'f0000001-0000-0000-0000-000000000138',
   'Non, c''est interdit par la Constitution',
   'false', '3'),

  ('7d1bd2ee-11e2-48a2-ab35-434113970833', 'f0000001-0000-0000-0000-000000000139',
   'Oui, si c''est justifié et proportionné',
   'true', '0'),

  ('91dd2906-b562-4bd9-b1c4-519ae1ffc731', 'f0000001-0000-0000-0000-000000000139',
   'Non, jamais dans le privé',
   'false', '1'),

  ('b279e775-c41d-4695-a980-67a75b3ad8f4', 'f0000001-0000-0000-0000-000000000139',
   'Oui, sans aucune justification',
   'false', '2'),

  ('caad99e5-5c02-40b1-98ab-bfa337b3420a', 'f0000001-0000-0000-0000-000000000139',
   'Uniquement pour les femmes',
   'false', '3'),

  ('5597daca-6a5f-45c3-acc6-e70f31ace798', 'f0000001-0000-0000-0000-00000000013a',
   'De 3 à 16 ans',
   'true', '0'),

  ('9839e2d9-2638-4733-9b93-dd099e016caf', 'f0000001-0000-0000-0000-00000000013a',
   'De 6 à 18 ans',
   'false', '1'),

  ('3ba59fd6-4210-4dd8-b809-15f49b87d720', 'f0000001-0000-0000-0000-00000000013a',
   'De 7 à 14 ans',
   'false', '2'),

  ('dc634510-6dc5-4e2b-8ddf-00d939ee7dc4', 'f0000001-0000-0000-0000-00000000013a',
   'L''instruction n''est pas obligatoire',
   'false', '3'),

  ('6c7c7aea-9e7a-4f8a-bbae-350a1c7ed36c', 'f0000001-0000-0000-0000-00000000013b',
   'Oui, gratuite et laïque',
   'true', '0'),

  ('15a4dcc2-d8f5-45f2-8aa7-9d341d04162b', 'f0000001-0000-0000-0000-00000000013b',
   'Non, il faut payer chaque année',
   'false', '1'),

  ('939e8aa7-9fac-4b30-b2db-b7a42e2414b1', 'f0000001-0000-0000-0000-00000000013b',
   'Oui, mais uniquement pour les Français',
   'false', '2'),

  ('8a72ca55-ad22-4bf4-bb5d-282abbe42248', 'f0000001-0000-0000-0000-00000000013b',
   'Uniquement de la maternelle au CM2',
   'false', '3'),

  ('72ab0562-89e6-4b3b-b194-532fced72b5a', 'f0000001-0000-0000-0000-00000000013c',
   'Alerter la police, porter plainte ou saisir le Défenseur des droits',
   'true', '0'),

  ('56a82fd7-4b40-4e9b-a7a6-1f18b14a74cf', 'f0000001-0000-0000-0000-00000000013c',
   'Ne rien faire, ce n''est pas son problème',
   'false', '1'),

  ('87744d64-7141-4445-9088-8c08f2c043a8', 'f0000001-0000-0000-0000-00000000013c',
   'Insulter la personne raciste en retour',
   'false', '2'),

  ('a9e82d53-2134-4fcc-936f-da3b38fe16ac', 'f0000001-0000-0000-0000-00000000013c',
   'Attendre que la situation se reproduise',
   'false', '3');
