-- ============================================================================
-- V201 — Civique : Principes et valeurs (lot 1)
-- ----------------------------------------------------------------------------
-- Questions + choix. Filtre: 11111111-0000-0000-0000-000000000001 .
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('f0000001-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'À quoi correspond la date du 14 juillet ?',
   'Le 14 juillet est la fête nationale française. Elle commémore la prise de la Bastille en 1789, événement majeur de la Révolution française, et la Fête de la Fédération de 1790.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel est l''un des symboles de la République française ?',
   'Marianne est l''un des symboles officiels de la République française, avec le drapeau tricolore, La Marseillaise, la devise et le coq.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Lequel de ces symboles représente officiellement la République française ?',
   'Le drapeau tricolore bleu-blanc-rouge est l''emblème national de la France, inscrit dans l''article 2 de la Constitution.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quels sont des symboles officiels de la République française ?',
   'Les principaux symboles officiels sont : le drapeau tricolore, La Marseillaise, Marianne, la devise "Liberté, Égalité, Fraternité" et le coq gaulois.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000005', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel symbole de la République française est tricolore ?',
   'Le drapeau français est tricolore : bleu, blanc et rouge. Ces couleurs ont été adoptées pendant la Révolution française.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000006', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelles sont les couleurs du drapeau français ?',
   'Le drapeau français est composé de trois bandes verticales : bleu, blanc et rouge, de gauche à droite quand on le regarde.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel animal est un symbole de la France ?',
   'Le coq gaulois est un emblème traditionnel de la France, hérité de l''époque gallo-romaine. On le retrouve notamment sur les maillots des équipes sportives nationales.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui est Marianne ?',
   'Marianne est l''allégorie (la représentation symbolique) de la République française. Son buste est présent dans toutes les mairies de France.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel est le nom de l''hymne national ?',
   'La Marseillaise est l''hymne national de la France. Écrite par Rouget de Lisle en 1792 à Strasbourg, elle est devenue hymne national en 1795.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Qu''est-ce que la Marseillaise ?',
   'La Marseillaise est l''hymne national de la France. Elle est chantée lors des cérémonies officielles et des événements sportifs internationaux.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle est la devise de la République française ?',
   'La devise "Liberté, Égalité, Fraternité" est inscrite à l''article 2 de la Constitution. Elle résume les valeurs fondamentales de la République.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Où peut-on voir la devise de la République ?',
   'La devise "Liberté, Égalité, Fraternité" est inscrite sur le fronton de tous les bâtiments publics : mairies, écoles, préfectures, tribunaux.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   '"Liberté, égalité, fraternité", c''est :',
   '"Liberté, Égalité, Fraternité" est la devise officielle de la République française depuis 1880, reprise dans les Constitutions de 1946 et 1958.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que signifie la liberté ?',
   'La liberté est le droit de faire ce que les lois permettent, dans le respect des libertés des autres. Article 4 de la Déclaration des droits de l''homme et du citoyen de 1789.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que l''égalité ?',
   'L''égalité signifie que tous les citoyens sont égaux devant la loi, sans distinction d''origine, de race, de religion, de sexe ou d''opinion.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le principe d''égalité signifie que :',
   'Le principe d''égalité garantit que la loi s''applique de la même manière à tous, sans discrimination liée à l''origine, au sexe, à la religion ou aux opinions.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que signifie le mot "fraternité" dans la devise française ?',
   'La fraternité représente la solidarité et l''entraide entre les citoyens. Elle implique le respect, la tolérance et le devoir d''aider les autres.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel est l''un des rôles des associations ?',
   'Les associations contribuent à la solidarité et à la vie sociale (aide aux personnes en difficulté, sport, culture, éducation...). Elles sont une expression de la fraternité.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'De quand date la Constitution de la Ve République ?',
   'La Constitution de la Ve République a été adoptée le 4 octobre 1958, sous l''impulsion du général de Gaulle. Elle est toujours en vigueur aujourd''hui.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le régime de la France est :',
   'La France est une république démocratique. L''article 1er de la Constitution précise : "La France est une République indivisible, laïque, démocratique et sociale."',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'CONNAISSANCE',
   '"La France est une République indivisible, ..., démocratique et sociale". Completez cette phrase extraite de l''article 1er de la Constitution :',
   'L''article 1er de la Constitution définit la France comme une République "indivisible, laïque, démocratique et sociale". La laïcité est l''un des quatre principes fondamentaux.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle est la date de la fête nationale française ?',
   'La fête nationale française est le 14 juillet. Elle commémore la prise de la Bastille en 1789 et la Fête de la Fédération de 1790.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Qu''est-ce qui est traditionnellement organisé sur les Champs-Élysées le 14 juillet pour célébrer la fête nationale ?',
   'Un défilé militaire est organisé chaque année sur les Champs-Élysées à Paris, en présence du président de la République. C''est la plus ancienne et la plus grande parade militaire d''Europe.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle est la langue officielle de la République française ?',
   'Le français est la langue officielle de la République, inscrit dans l''article 2 de la Constitution depuis 1992.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle est la place de la langue française dans la République ?',
   'Le français est la langue officielle et de l''administration. Sa connaissance est un élément essentiel d''intégration et est exigée pour la naturalisation.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle liberté permet à chacun d''exprimer ses idées ?',
   'La liberté d''expression permet à chacun d''exprimer ses opinions, par la parole, l''écrit, l''image. Elle est garantie par la Déclaration des droits de l''homme et du citoyen de 1789.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle proposition est correcte ? La liberté d''expression :',
   'La liberté d''expression n''est pas absolue : elle est encadrée par la loi. L''injure, la diffamation, l''incitation à la haine ou à la violence sont interdites.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'MISE_SITUATION',
   'A-t-on le droit d''insulter publiquement quelqu''un parce qu''il est différent (handicap, apparence physique, sexe...) ?',
   'Non. Les injures et discriminations sont interdites par la loi et punies pénalement. Le respect de la dignité de chacun est un principe fondamental.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Certains métiers peuvent-ils être réservés aux hommes ?',
   'Non. L''égalité entre les hommes et les femmes est un principe constitutionnel. Tous les métiers sont accessibles aux deux sexes sans distinction.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que la laïcité ?',
   'La laïcité est la séparation entre l''État et les religions. L''État est neutre, ne reconnaît aucun culte et garantit la liberté de conscience de chacun.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000001f', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'En quelle année la loi de séparation des Églises et de l''État a-t-elle été votée ?',
   'La loi de séparation des Églises et de l''État a été votée le 9 décembre 1905. Elle a posé les bases de la laïcité française.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000020', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que permet le principe de laïcité ?',
   'La laïcité garantit la liberté de conscience : chacun peut croire, ne pas croire ou changer de religion, dans le respect des autres et de la loi.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000021', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel droit est garanti par la laïcité ?',
   'La laïcité garantit la liberté de conscience et de religion : chacun peut pratiquer la religion de son choix ou n''en pratiquer aucune.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000022', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Pourquoi le principe de laïcité doit-il être respecté à l''école ?',
   'L''école publique est laïque pour garantir l''égalité de tous les élèves, leur permettre de se former librement et éviter toute pression religieuse.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000023', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Un enfant peut-il refuser d''aller à l''école pour une raison religieuse ?',
   'Non. L''instruction est obligatoire pour tous les enfants de 3 à 16 ans. Aucun motif religieux ne peut justifier l''absence ou refuser certains enseignements.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000024', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Une personne a-t-elle le droit de ne pas croire en une religion ?',
   'Oui. La liberté de conscience, garantie par la laïcité, comprend le droit de ne pas croire (athée, agnostique). Personne ne peut être forcé à adhérer à une religion.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000025', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Une personne peut-elle changer librement de religion ?',
   'Oui. La liberté de conscience inclut le droit de choisir, changer ou abandonner une religion sans aucune contrainte. Nul ne peut être forcé de rester dans une religion.',
   'true', '2026-05-27 17:40:29.695032+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000101', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui a composé La Marseillaise ?',
   'La Marseillaise a été composée par Rouget de Lisle en 1792 à Strasbourg. C''était à l''origine un chant de guerre pour l''armée du Rhin.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000102', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'En quelle année La Marseillaise a-t-elle été composée ?',
   'La Marseillaise a été composée en 1792, pendant la Révolution française. Elle est devenue hymne national en 1795, puis définitivement en 1879.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000103', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Dans quelle ville Rouget de Lisle a-t-il écrit La Marseillaise ?',
   'La Marseillaise a été écrite à Strasbourg en avril 1792. Le titre vient des volontaires marseillais qui l''ont entonnée à leur entrée dans Paris.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000104', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Comment doit-on se comporter lorsque retentit La Marseillaise dans une cérémonie officielle ?',
   'Par respect pour l''hymne national, on se tient debout et en silence. Cette règle vaut aussi lors des événements sportifs internationaux.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000105', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Dans quelles occasions La Marseillaise est-elle chantée ?',
   'La Marseillaise est jouée lors des cérémonies officielles (commémorations, prises de fonction), des événements sportifs internationaux et de la fête nationale.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000106', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que porte traditionnellement Marianne sur la tête ?',
   'Marianne porte un bonnet phrygien, coiffure rouge symbole de liberté héritée de l''Antiquité (les esclaves affranchis le portaient).',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000107', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que symbolise le bonnet phrygien porté par Marianne ?',
   'Le bonnet phrygien symbolise la liberté. Dans l''Antiquité, les esclaves affranchis le portaient. La Révolution française l''a repris comme emblème.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000108', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Où peut-on voir le buste de Marianne ?',
   'Le buste de Marianne est présent dans toutes les mairies de France. Il est aussi reproduit sur les timbres et certaines pièces de monnaie.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-000000000109', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Sur quels objets du quotidien apparaît Marianne ?',
   'Marianne apparaît sur les timbres-poste français et sur certaines pièces de monnaie en euros frappées en France. C''est l''image officielle de la République.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000010a', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Sur quoi peut-on souvent voir le coq gaulois ?',
   'Le coq gaulois est l''emblème traditionnel de la France. On le voit notamment sur les maillots des équipes sportives nationales et sur certaines pièces de monnaie.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000010b', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'À quelle époque le drapeau tricolore a-t-il été créé ?',
   'Le drapeau tricolore est né pendant la Révolution française. Le bleu et le rouge sont les couleurs de Paris, le blanc celle de la royauté : réunir les trois symbolisait l''union.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000010c', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Sur quels bâtiments le drapeau français est-il obligatoirement déployé ?',
   'Le drapeau est arboré sur les bâtiments publics : mairies, préfectures, écoles, tribunaux, ministères, casernes. Il marque la présence de la République.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f0000001-0000-0000-0000-00000000010d', 'CIVIQUE', '11111111-0000-0000-0000-000000000001', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le drapeau européen est-il aussi affiché sur les bâtiments officiels français ?',
   'Oui. La France étant membre de l''Union européenne, le drapeau européen (douze étoiles dorées sur fond bleu) est affiché aux côtés du drapeau français sur les bâtiments officiels.',
   'true', '2026-05-27 17:40:29.820007+02', NULL, 'ACTIVE', NULL, NULL, NULL);

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('4890706d-b090-4c90-bac5-2538da32c1a5', 'f0000001-0000-0000-0000-000000000001',
   'La fête nationale française',
   'true', '0'),

  ('ac628bc6-f922-4f01-b534-f7e79c4707ae', 'f0000001-0000-0000-0000-000000000001',
   'La fête du Travail',
   'false', '1'),

  ('62e582df-9c26-4711-9cfc-0690a1e3151e', 'f0000001-0000-0000-0000-000000000001',
   'L''Armistice de 1918',
   'false', '2'),

  ('21a9a0c7-b441-4aa3-bca8-b20f925f9ed5', 'f0000001-0000-0000-0000-000000000001',
   'La fête de la Victoire',
   'false', '3'),

  ('3bcb7954-22cb-48cd-9ff6-ad2d02439dd3', 'f0000001-0000-0000-0000-000000000002',
   'Marianne',
   'true', '0'),

  ('2c6483c8-648b-4086-b105-7831e16d3996', 'f0000001-0000-0000-0000-000000000002',
   'La tour Eiffel',
   'false', '1'),

  ('2fc64f80-b86b-4b7d-a60e-aef3de658229', 'f0000001-0000-0000-0000-000000000002',
   'Le Mont-Saint-Michel',
   'false', '2'),

  ('92104dbd-7e24-491e-a40e-341f180a59f3', 'f0000001-0000-0000-0000-000000000002',
   'L''Arc de Triomphe',
   'false', '3'),

  ('08eef639-6dd1-4b06-9745-9c1245c2f30c', 'f0000001-0000-0000-0000-000000000003',
   'Le drapeau tricolore',
   'true', '0'),

  ('2045133a-1a11-4d59-a287-b8d677b47a37', 'f0000001-0000-0000-0000-000000000003',
   'La Tour Eiffel',
   'false', '1'),

  ('9c4809ef-0276-4eb4-a3cd-a2e61a9aee2a', 'f0000001-0000-0000-0000-000000000003',
   'Notre-Dame de Paris',
   'false', '2'),

  ('282f5685-85f2-4f42-aecb-c44d81a695bb', 'f0000001-0000-0000-0000-000000000003',
   'Le Louvre',
   'false', '3'),

  ('11b4d2db-84fb-4fd6-8452-dacacd542689', 'f0000001-0000-0000-0000-000000000004',
   'Le drapeau, La Marseillaise et Marianne',
   'true', '0'),

  ('2105da82-358d-4f9f-ba6f-cc20cbdec015', 'f0000001-0000-0000-0000-000000000004',
   'La baguette, le béret et le vin',
   'false', '1'),

  ('6f9a2f09-e597-4ff0-8e49-3129a4261ccb', 'f0000001-0000-0000-0000-000000000004',
   'Le président, le Premier ministre et les ministres',
   'false', '2'),

  ('f7d3996c-a2e0-4e67-abe1-b8b73a6aeacc', 'f0000001-0000-0000-0000-000000000004',
   'Paris, Lyon et Marseille',
   'false', '3'),

  ('ac4a2604-1b90-45e2-a693-bf847fa9a68f', 'f0000001-0000-0000-0000-000000000005',
   'Le drapeau',
   'true', '0'),

  ('d16d3479-0de8-4330-ab19-4ce59ac0b7ee', 'f0000001-0000-0000-0000-000000000005',
   'La Marseillaise',
   'false', '1'),

  ('6aa8b326-e902-4211-b873-5dddf2233ad6', 'f0000001-0000-0000-0000-000000000005',
   'Le coq',
   'false', '2'),

  ('a0374119-aaa5-4483-852f-a51edb5cc0a9', 'f0000001-0000-0000-0000-000000000005',
   'Marianne',
   'false', '3'),

  ('52a6afe9-106e-4223-9c55-13030c4fd323', 'f0000001-0000-0000-0000-000000000006',
   'Bleu, blanc, rouge',
   'true', '0'),

  ('d70525cc-443a-4265-9e27-4d4941c09d13', 'f0000001-0000-0000-0000-000000000006',
   'Rouge, blanc, vert',
   'false', '1'),

  ('6ec92ebf-0c84-4fd8-822f-1390d757c155', 'f0000001-0000-0000-0000-000000000006',
   'Bleu, jaune, rouge',
   'false', '2'),

  ('4d1b794c-5cba-4cd1-9ac5-748adb8fd8c1', 'f0000001-0000-0000-0000-000000000006',
   'Blanc, bleu, jaune',
   'false', '3'),

  ('dc7a8010-77ad-4458-b24d-a08604b93c8b', 'f0000001-0000-0000-0000-000000000007',
   'Le coq',
   'true', '0'),

  ('cbdb08bd-5768-4ac6-9435-3128ea8c7bd6', 'f0000001-0000-0000-0000-000000000007',
   'L''aigle',
   'false', '1'),

  ('21e6cca9-471d-4ad2-b918-99d4e72545d8', 'f0000001-0000-0000-0000-000000000007',
   'Le lion',
   'false', '2'),

  ('0ff96f09-3b95-41b7-9078-93c0f9735edc', 'f0000001-0000-0000-0000-000000000007',
   'Le loup',
   'false', '3'),

  ('881091fa-20bc-42b1-946c-99f73f7ac38c', 'f0000001-0000-0000-0000-000000000008',
   'L''allégorie de la République française',
   'true', '0'),

  ('c7f70ca5-c4ca-4908-8096-927a2b9f26b0', 'f0000001-0000-0000-0000-000000000008',
   'La première reine de France',
   'false', '1'),

  ('94e98e72-60ca-467f-9917-ba3e4edab3d6', 'f0000001-0000-0000-0000-000000000008',
   'L''épouse du président actuel',
   'false', '2'),

  ('0b86b3dc-c00d-4b4d-8ab7-942e6c172b4d', 'f0000001-0000-0000-0000-000000000008',
   'Une sainte catholique',
   'false', '3'),

  ('c1f0c817-24a8-48ba-846e-ac88f2bff987', 'f0000001-0000-0000-0000-000000000009',
   'La Marseillaise',
   'true', '0'),

  ('89e62a68-e0ba-4da9-ad03-6a279bf2dee9', 'f0000001-0000-0000-0000-000000000009',
   'L''Internationale',
   'false', '1'),

  ('8e928b12-f641-4f57-8957-7797516f3fef', 'f0000001-0000-0000-0000-000000000009',
   'Le chant des partisans',
   'false', '2'),

  ('d0192ec1-d3ca-4dad-a45c-53ea2372415a', 'f0000001-0000-0000-0000-000000000009',
   'La Parisienne',
   'false', '3'),

  ('31f8cdcf-44f3-47a8-ad38-b80c0e9eca52', 'f0000001-0000-0000-0000-00000000000a',
   'L''hymne national français',
   'true', '0'),

  ('0d86e7d8-4a00-4ec2-ad09-e9c128c53561', 'f0000001-0000-0000-0000-00000000000a',
   'Un quartier de Marseille',
   'false', '1'),

  ('afae3e36-057d-4a26-9683-7b26d7b064ab', 'f0000001-0000-0000-0000-00000000000a',
   'Une recette de cuisine provençale',
   'false', '2'),

  ('1014d5b4-89e9-4ebb-90b0-fc9a6f71009e', 'f0000001-0000-0000-0000-00000000000a',
   'Une danse traditionnelle',
   'false', '3'),

  ('bfb9f0c7-9e77-4696-9950-e30de83a813f', 'f0000001-0000-0000-0000-00000000000b',
   'Liberté, Égalité, Fraternité',
   'true', '0'),

  ('808c7d91-fbd8-4007-82a4-1b4edd06045b', 'f0000001-0000-0000-0000-00000000000b',
   'Liberté, Fraternité, Solidarité',
   'false', '1'),

  ('73f07fde-36b9-4c52-b0cb-625f64c33795', 'f0000001-0000-0000-0000-00000000000b',
   'Liberté, Justice, Paix',
   'false', '2'),

  ('70c34212-bf03-4574-854e-4329856ad9ad', 'f0000001-0000-0000-0000-00000000000b',
   'Unité, Travail, Patrie',
   'false', '3'),

  ('017f12be-1e0a-4f81-bb16-9633b2eaeeba', 'f0000001-0000-0000-0000-00000000000c',
   'Sur le fronton des bâtiments publics',
   'true', '0'),

  ('f28aaf6c-a749-4176-ab6e-50145b710b54', 'f0000001-0000-0000-0000-00000000000c',
   'Sur les pièces de 1 centime uniquement',
   'false', '1'),

  ('291b3fd0-aa36-426c-9d5d-d2dedf9e3959', 'f0000001-0000-0000-0000-00000000000c',
   'Dans les églises catholiques',
   'false', '2'),

  ('d0351eb9-d432-4e1c-863e-bca9f09c2f85', 'f0000001-0000-0000-0000-00000000000c',
   'Sur les plaques d''immatriculation',
   'false', '3'),

  ('ae219cc0-33bc-4327-b872-bca6f94630b6', 'f0000001-0000-0000-0000-00000000000d',
   'La devise de la République française',
   'true', '0'),

  ('90fc03e9-6cea-4d34-876e-67212ab505f8', 'f0000001-0000-0000-0000-00000000000d',
   'Le titre de l''hymne national',
   'false', '1'),

  ('fbaa7463-2682-485d-bdc8-665024727108', 'f0000001-0000-0000-0000-00000000000d',
   'Une chanson populaire',
   'false', '2'),

  ('74c861af-69c7-484a-a7ec-881a44b65d49', 'f0000001-0000-0000-0000-00000000000d',
   'Une loi récente',
   'false', '3'),

  ('17a2ad29-6da6-4b20-a6c3-c62212c60be4', 'f0000001-0000-0000-0000-00000000000e',
   'Le droit de faire ce que la loi permet, dans le respect des autres',
   'true', '0'),

  ('21d8a947-7076-4638-b224-f40e5070f2e5', 'f0000001-0000-0000-0000-00000000000e',
   'Le droit de faire absolument tout ce que l''on veut',
   'false', '1'),

  ('b8e73317-a1f7-481b-986f-c170fa538096', 'f0000001-0000-0000-0000-00000000000e',
   'L''obligation d''obéir au gouvernement',
   'false', '2'),

  ('e62d07d1-1a91-44d8-a866-1256fdcdce32', 'f0000001-0000-0000-0000-00000000000e',
   'Le droit réservé aux citoyens français',
   'false', '3'),

  ('09de9456-a50f-46b6-adea-14c63b70b3c6', 'f0000001-0000-0000-0000-00000000000f',
   'Tous les citoyens sont égaux devant la loi',
   'true', '0'),

  ('3108e87a-08fa-4004-b212-f62ff2300c0a', 'f0000001-0000-0000-0000-00000000000f',
   'Tout le monde gagne le même salaire',
   'false', '1'),

  ('94376b03-847b-4cee-9162-2b4c31c82d04', 'f0000001-0000-0000-0000-00000000000f',
   'Tout le monde a la même apparence',
   'false', '2'),

  ('afcfc856-aa9f-4070-a61c-354d6030d535', 'f0000001-0000-0000-0000-00000000000f',
   'Tout le monde doit avoir les mêmes opinions',
   'false', '3'),

  ('f2da2b8f-8254-4daf-a759-cdeed223adf8', 'f0000001-0000-0000-0000-000000000010',
   'La loi est la même pour tous, sans discrimination',
   'true', '0'),

  ('67381d6d-30d7-44dd-bffb-adfe96e8240b', 'f0000001-0000-0000-0000-000000000010',
   'Tout le monde doit posséder les mêmes biens',
   'false', '1'),

  ('a87700c2-287d-40f2-bfa7-8b12a8e7cbe5', 'f0000001-0000-0000-0000-000000000010',
   'Les hommes et les femmes ont des rôles différents',
   'false', '2'),

  ('e30ce4d0-ba2b-49cc-b755-cb31b95c012e', 'f0000001-0000-0000-0000-000000000010',
   'Les Français ont plus de droits que les étrangers',
   'false', '3'),

  ('38c08657-2321-4e83-87a6-f084087f59aa', 'f0000001-0000-0000-0000-000000000011',
   'La solidarité et l''entraide entre les citoyens',
   'true', '0'),

  ('5c4eb10c-5b12-4620-9391-de28c6f890d5', 'f0000001-0000-0000-0000-000000000011',
   'Le lien familial entre frères et sœurs uniquement',
   'false', '1'),

  ('cef227a2-a993-41e8-bc2a-96d255ade84f', 'f0000001-0000-0000-0000-000000000011',
   'L''appartenance à la même religion',
   'false', '2'),

  ('8eb75c4a-32e6-4133-bdb9-40702bc2af53', 'f0000001-0000-0000-0000-000000000011',
   'Le service militaire obligatoire',
   'false', '3'),

  ('b95d8811-d1e2-4a58-b89e-89629489c14d', 'f0000001-0000-0000-0000-000000000012',
   'Aider les personnes et contribuer à la vie sociale',
   'true', '0'),

  ('ffeb902d-08ad-47ac-bbde-7963242136f0', 'f0000001-0000-0000-0000-000000000012',
   'Remplacer le gouvernement',
   'false', '1'),

  ('318ca444-bbaf-413d-ae2a-e5a5551a3a02', 'f0000001-0000-0000-0000-000000000012',
   'Imposer des taxes aux citoyens',
   'false', '2'),

  ('be545062-fb42-4bd4-8554-13508eb32fe5', 'f0000001-0000-0000-0000-000000000012',
   'Réserver leurs services aux Français uniquement',
   'false', '3'),

  ('19508b6d-9912-4227-aeca-83d2da56ddbf', 'f0000001-0000-0000-0000-000000000013',
   '1958',
   'true', '0'),

  ('993c1312-83d2-4fe6-ad45-f1029b76723e', 'f0000001-0000-0000-0000-000000000013',
   '1789',
   'false', '1'),

  ('e242e3d4-9443-4804-b7bb-43583a08adc6', 'f0000001-0000-0000-0000-000000000013',
   '1945',
   'false', '2'),

  ('d49db940-6400-410d-83cf-2b26c94b01e0', 'f0000001-0000-0000-0000-000000000013',
   '1981',
   'false', '3'),

  ('a3597337-b725-4dc5-bb5f-8fc0da0f52f8', 'f0000001-0000-0000-0000-000000000014',
   'Une république démocratique',
   'true', '0'),

  ('0595afbe-b00d-4d20-aac6-b2b44c55903f', 'f0000001-0000-0000-0000-000000000014',
   'Une monarchie constitutionnelle',
   'false', '1'),

  ('fa4ec067-273d-46bd-85c2-5c79c7e56ff6', 'f0000001-0000-0000-0000-000000000014',
   'Une dictature militaire',
   'false', '2'),

  ('622ee352-218d-45c4-a905-071069b8b11e', 'f0000001-0000-0000-0000-000000000014',
   'Une théocratie',
   'false', '3'),

  ('d4d17b1a-2af5-40fd-bb39-163c390961fd', 'f0000001-0000-0000-0000-000000000015',
   'laïque',
   'true', '0'),

  ('c1078c31-645b-4c8a-b4c0-90f31d9ac0e4', 'f0000001-0000-0000-0000-000000000015',
   'religieuse',
   'false', '1'),

  ('db1a70f9-dcce-42bf-bf26-a8392860eace', 'f0000001-0000-0000-0000-000000000015',
   'monarchique',
   'false', '2'),

  ('b5e652a6-62be-4ad6-a770-cb78055ca762', 'f0000001-0000-0000-0000-000000000015',
   'fédérale',
   'false', '3'),

  ('723b2277-e939-4735-b90e-702f53ed9f30', 'f0000001-0000-0000-0000-000000000016',
   'Le 14 juillet',
   'true', '0'),

  ('93fb5d01-4a2b-4382-bd32-2b8ea72cc35f', 'f0000001-0000-0000-0000-000000000016',
   'Le 1er mai',
   'false', '1'),

  ('83f2646b-a519-425b-9250-c8ab75010cd0', 'f0000001-0000-0000-0000-000000000016',
   'Le 11 novembre',
   'false', '2'),

  ('4f3df74c-e3e9-4366-bc44-328983c4d16c', 'f0000001-0000-0000-0000-000000000016',
   'Le 8 mai',
   'false', '3'),

  ('20024a28-8ea4-4271-865c-749cf3e3259f', 'f0000001-0000-0000-0000-000000000017',
   'Un défilé militaire',
   'true', '0'),

  ('11aaad09-752b-4831-9153-6e1c456b8098', 'f0000001-0000-0000-0000-000000000017',
   'Un marché de Noël',
   'false', '1'),

  ('586fc5a6-4d9b-4fa6-a880-3f992c5b5c11', 'f0000001-0000-0000-0000-000000000017',
   'Une course cycliste',
   'false', '2'),

  ('607a2907-0333-4ddc-8444-ebabe3e4541d', 'f0000001-0000-0000-0000-000000000017',
   'Un concert de musique classique',
   'false', '3'),

  ('6a992ab1-7e95-48ce-937c-1136a7c7c1a8', 'f0000001-0000-0000-0000-000000000018',
   'Le français',
   'true', '0'),

  ('8089996a-367a-4183-bd11-da24552d79c2', 'f0000001-0000-0000-0000-000000000018',
   'L''anglais',
   'false', '1'),

  ('fa9c9314-bb1f-43f5-a235-5ca9d3a7ea2c', 'f0000001-0000-0000-0000-000000000018',
   'Le français et l''anglais',
   'false', '2'),

  ('ec873172-7a3a-4ae4-9c8a-398683ef9f98', 'f0000001-0000-0000-0000-000000000018',
   'Aucune langue officielle n''est définie',
   'false', '3'),

  ('0d174be3-7b41-4525-aa3b-adba877eb69b', 'f0000001-0000-0000-0000-000000000019',
   'C''est la langue officielle et le lien commun entre les citoyens',
   'true', '0'),

  ('03edbe93-571b-4bbd-be5d-fa4ae3d440b5', 'f0000001-0000-0000-0000-000000000019',
   'C''est une langue parmi d''autres, sans statut particulier',
   'false', '1'),

  ('4c0f1bb2-e2d6-4895-824e-1febc3b53406', 'f0000001-0000-0000-0000-000000000019',
   'C''est une langue réservée à l''écrit',
   'false', '2'),

  ('8393720c-5ddc-4ab7-b677-f440e64be899', 'f0000001-0000-0000-0000-000000000019',
   'Elle n''est pas obligatoire pour les services publics',
   'false', '3'),

  ('711c44bc-f890-4768-a475-5ae57813e656', 'f0000001-0000-0000-0000-00000000001a',
   'La liberté d''expression',
   'true', '0'),

  ('33683231-88ca-4847-a8c0-40db87473c64', 'f0000001-0000-0000-0000-00000000001a',
   'La liberté de circulation',
   'false', '1'),

  ('0c3ae399-c191-4407-97fc-1e14f74f2242', 'f0000001-0000-0000-0000-00000000001a',
   'La liberté du commerce',
   'false', '2'),

  ('cfc605da-c09c-40b8-8e9d-2b2ee8ed79f2', 'f0000001-0000-0000-0000-00000000001a',
   'La liberté de propriété',
   'false', '3'),

  ('62804c0c-ca4c-4867-848b-52f0e0688b61', 'f0000001-0000-0000-0000-00000000001b',
   'À des limites fixées par la loi (injure, diffamation, incitation à la haine)',
   'true', '0'),

  ('a368db03-c800-468c-bee2-b8ed8890814a', 'f0000001-0000-0000-0000-00000000001b',
   'Est totale et sans aucune limite',
   'false', '1'),

  ('66ed815a-6fd9-4a70-b0fe-9af6f0de100d', 'f0000001-0000-0000-0000-00000000001b',
   'N''existe pas en France',
   'false', '2'),

  ('7c89a6b2-6102-405f-8150-4e6dfcfec58d', 'f0000001-0000-0000-0000-00000000001b',
   'Est réservée aux journalistes',
   'false', '3'),

  ('29e9e984-93df-400f-a5ab-1b025ade85f4', 'f0000001-0000-0000-0000-00000000001c',
   'Non, c''est interdit et puni par la loi',
   'true', '0'),

  ('6fdf8fe5-2eb5-403a-8b49-ec14e75c0e4d', 'f0000001-0000-0000-0000-00000000001c',
   'Oui, c''est la liberté d''expression',
   'false', '1'),

  ('334c92e6-784f-45d5-a4a1-b60fc1f1e36d', 'f0000001-0000-0000-0000-00000000001c',
   'Oui, mais seulement sur Internet',
   'false', '2'),

  ('f15a9adf-f1f8-43ce-9c2b-226e26ac7912', 'f0000001-0000-0000-0000-00000000001c',
   'Oui, si c''est dit avec humour',
   'false', '3'),

  ('48044ba6-6ec6-46c5-8541-d6861cafbb2f', 'f0000001-0000-0000-0000-00000000001d',
   'Non, l''égalité hommes-femmes interdit toute discrimination',
   'true', '0'),

  ('37b009ed-9cee-42b3-9e16-93a37555a13e', 'f0000001-0000-0000-0000-00000000001d',
   'Oui, certains métiers physiques',
   'false', '1'),

  ('ed884377-19f6-48d1-b494-5b65d64a0a1b', 'f0000001-0000-0000-0000-00000000001d',
   'Oui, les métiers militaires',
   'false', '2'),

  ('5f2bb83e-f387-4bf5-bfb2-90c9a85feca7', 'f0000001-0000-0000-0000-00000000001d',
   'Oui, si l''employeur le décide',
   'false', '3'),

  ('41a3b3d2-2df3-4304-ae32-ea3b14ba85b6', 'f0000001-0000-0000-0000-00000000001e',
   'La séparation entre l''État et les religions',
   'true', '0'),

  ('87260c13-9c93-4796-9bcb-a6b728e9b77e', 'f0000001-0000-0000-0000-00000000001e',
   'L''interdiction de toutes les religions',
   'false', '1'),

  ('7ef8974b-aa3a-4948-b3f3-1e0a0f90a357', 'f0000001-0000-0000-0000-00000000001e',
   'L''obligation de pratiquer une religion',
   'false', '2'),

  ('96ccdc15-7a94-4c82-83ee-365fdd98c028', 'f0000001-0000-0000-0000-00000000001e',
   'Le respect d''une religion d''État',
   'false', '3'),

  ('d4b83b03-5abe-4d1a-ade0-1ebcdbfa7453', 'f0000001-0000-0000-0000-00000000001f',
   '1905',
   'true', '0'),

  ('834be41e-3cb5-438d-b0c3-01fe42255796', 'f0000001-0000-0000-0000-00000000001f',
   '1789',
   'false', '1'),

  ('3e056280-7627-4b50-b8ce-668dee92f545', 'f0000001-0000-0000-0000-00000000001f',
   '1958',
   'false', '2'),

  ('68638962-1c42-4bc7-ac90-7f9f33766ac0', 'f0000001-0000-0000-0000-00000000001f',
   '1881',
   'false', '3'),

  ('790afd46-7d64-474e-bbfa-3bede3935956', 'f0000001-0000-0000-0000-000000000020',
   'La liberté de croire ou de ne pas croire',
   'true', '0'),

  ('2dca0438-1713-4146-83b7-06c31358391f', 'f0000001-0000-0000-0000-000000000020',
   'D''interdire toutes les religions',
   'false', '1'),

  ('6f47e62f-8353-4e08-93ab-b19a8e1029c2', 'f0000001-0000-0000-0000-000000000020',
   'De favoriser une religion en particulier',
   'false', '2'),

  ('52d83d09-a5ae-4b7c-83f8-98a4a8185884', 'f0000001-0000-0000-0000-000000000020',
   'D''obliger les citoyens à suivre une religion',
   'false', '3'),

  ('4054fa71-88d7-4e9b-9d33-d507315d860d', 'f0000001-0000-0000-0000-000000000021',
   'La liberté de conscience et de religion',
   'true', '0'),

  ('14440ef0-3cff-4647-851e-e723812f89d2', 'f0000001-0000-0000-0000-000000000021',
   'Le droit à la propriété privée',
   'false', '1'),

  ('9b727600-df06-412b-853b-8309a66cf86c', 'f0000001-0000-0000-0000-000000000021',
   'Le droit de vote des étrangers',
   'false', '2'),

  ('d5f007e0-4f45-4e34-b4bf-dc9acb469fde', 'f0000001-0000-0000-0000-000000000021',
   'Le droit à la sécurité sociale',
   'false', '3'),

  ('30f4df8e-b808-44dd-9b39-1bdde44b6ec5', 'f0000001-0000-0000-0000-000000000022',
   'Pour garantir l''égalité entre les élèves et la liberté de conscience',
   'true', '0'),

  ('a65c121a-2e16-46de-86d6-ccdbaeafa5f3', 'f0000001-0000-0000-0000-000000000022',
   'Parce que les religions sont interdites',
   'false', '1'),

  ('453ef79b-ee7a-4d48-b030-5c5052965b75', 'f0000001-0000-0000-0000-000000000022',
   'Pour favoriser la religion catholique',
   'false', '2'),

  ('b813b627-514b-474c-a312-14000950f1dc', 'f0000001-0000-0000-0000-000000000022',
   'Parce que les enseignants choisissent la religion des élèves',
   'false', '3'),

  ('c84d34a8-0649-436a-9876-b0a08e7e12a5', 'f0000001-0000-0000-0000-000000000023',
   'Non, l''instruction est obligatoire de 3 à 16 ans',
   'true', '0'),

  ('3df413db-badc-48c7-80ba-e49e3dd5912e', 'f0000001-0000-0000-0000-000000000023',
   'Oui, la religion passe avant la loi',
   'false', '1'),

  ('b61e468c-b1bb-4165-b85b-ac052b87a175', 'f0000001-0000-0000-0000-000000000023',
   'Oui, si les parents le décident',
   'false', '2'),

  ('63d87f10-ae7c-4958-83dd-a3539ef9a116', 'f0000001-0000-0000-0000-000000000023',
   'Oui, certains jours de l''année',
   'false', '3'),

  ('06d415c3-4fe5-45c3-abee-8987e059d6f0', 'f0000001-0000-0000-0000-000000000024',
   'Oui, la liberté de conscience est garantie',
   'true', '0'),

  ('4a076f93-1222-47a3-9fb9-8e9221e795f4', 'f0000001-0000-0000-0000-000000000024',
   'Non, il faut obligatoirement avoir une religion',
   'false', '1'),

  ('cd029fa2-1312-42a9-a489-e4a56778d5d1', 'f0000001-0000-0000-0000-000000000024',
   'Oui, mais seulement les Français',
   'false', '2'),

  ('5569aab5-d842-4419-ab60-b25a307fb635', 'f0000001-0000-0000-0000-000000000024',
   'Non, c''est interdit par la Constitution',
   'false', '3'),

  ('9fbb814c-3700-41c5-a936-add28ededfb8', 'f0000001-0000-0000-0000-000000000025',
   'Oui, c''est une liberté fondamentale',
   'true', '0'),

  ('030aa776-09e5-4159-8369-f247dc8c082b', 'f0000001-0000-0000-0000-000000000025',
   'Non, c''est strictement interdit',
   'false', '1'),

  ('aed1a194-3dc1-48d9-9c6a-6ec4078e43fa', 'f0000001-0000-0000-0000-000000000025',
   'Oui, mais avec autorisation de l''État',
   'false', '2'),

  ('d11acb2b-7b00-4d37-9f07-885c41f48f86', 'f0000001-0000-0000-0000-000000000025',
   'Oui, mais seulement une fois dans sa vie',
   'false', '3'),

  ('1012eb96-e354-4ddd-bde3-484930ebd88a', 'f0000001-0000-0000-0000-000000000101',
   'Rouget de Lisle',
   'true', '0'),

  ('9e9b9b99-be6b-4b48-b291-ccb8447c09ab', 'f0000001-0000-0000-0000-000000000101',
   'Victor Hugo',
   'false', '1'),

  ('3628729c-828a-4be3-8632-215d72d725cf', 'f0000001-0000-0000-0000-000000000101',
   'Napoléon Bonaparte',
   'false', '2'),

  ('059fd872-5004-4fab-acd8-9c0d4c8b5107', 'f0000001-0000-0000-0000-000000000101',
   'Charles de Gaulle',
   'false', '3'),

  ('196018e5-7712-45fa-8d6b-bc175c25f876', 'f0000001-0000-0000-0000-000000000102',
   '1792',
   'true', '0'),

  ('aae4f6cc-b360-40ee-980e-18948cd28597', 'f0000001-0000-0000-0000-000000000102',
   '1789',
   'false', '1'),

  ('1c846575-e7e9-47f0-a3e6-fe179c153ea0', 'f0000001-0000-0000-0000-000000000102',
   '1804',
   'false', '2'),

  ('58f7214a-4086-4d26-b79a-35d4345b8a96', 'f0000001-0000-0000-0000-000000000102',
   '1848',
   'false', '3'),

  ('4f10cfc2-cdd6-4b39-8284-66857c4952c0', 'f0000001-0000-0000-0000-000000000103',
   'Strasbourg',
   'true', '0'),

  ('2d2b527d-ace2-41cb-ae1d-5b6cc7ac7aa7', 'f0000001-0000-0000-0000-000000000103',
   'Marseille',
   'false', '1'),

  ('2f24087e-f56c-41cc-a828-c7f0540e1040', 'f0000001-0000-0000-0000-000000000103',
   'Paris',
   'false', '2'),

  ('77fb91e1-fcf3-47de-9e9e-c466f719d1f9', 'f0000001-0000-0000-0000-000000000103',
   'Lyon',
   'false', '3'),

  ('9f6261c3-bc55-4bef-9fe5-2a8ff049904e', 'f0000001-0000-0000-0000-000000000104',
   'Se tenir debout et en silence',
   'true', '0'),

  ('c98bc1e1-3bb9-401e-9966-38453a9e9762', 'f0000001-0000-0000-0000-000000000104',
   'Continuer à parler normalement',
   'false', '1'),

  ('66310b25-0c9a-499e-8049-c76402742950', 'f0000001-0000-0000-0000-000000000104',
   'S''asseoir et applaudir',
   'false', '2'),

  ('c974f12f-c8b4-4489-869d-b7f9e55b5878', 'f0000001-0000-0000-0000-000000000104',
   'Quitter la salle par respect',
   'false', '3'),

  ('eaa2e614-790a-4b2a-b1b8-8ebd0dd50999', 'f0000001-0000-0000-0000-000000000105',
   'Cérémonies officielles et événements sportifs internationaux',
   'true', '0'),

  ('bd73e70c-721d-432e-b38f-fd3ca6e90338', 'f0000001-0000-0000-0000-000000000105',
   'Uniquement le 14 juillet',
   'false', '1'),

  ('45027ad3-967a-4c0c-abf2-484aa557926c', 'f0000001-0000-0000-0000-000000000105',
   'Uniquement dans les écoles',
   'false', '2'),

  ('0ff1619d-1dff-450d-878f-40bcdcfe520d', 'f0000001-0000-0000-0000-000000000105',
   'À la fin de chaque journal télévisé',
   'false', '3'),

  ('e585a319-b09e-48f2-b2bf-126ada9754e8', 'f0000001-0000-0000-0000-000000000106',
   'Un bonnet phrygien',
   'true', '0'),

  ('3f96f765-cabb-435b-b4b7-964215413d3f', 'f0000001-0000-0000-0000-000000000106',
   'Une couronne royale',
   'false', '1'),

  ('51807edf-40af-4b18-ac27-b5ce7f4bd731', 'f0000001-0000-0000-0000-000000000106',
   'Un casque militaire',
   'false', '2'),

  ('4b28c989-e2e6-47bb-88e7-d27069ed4d74', 'f0000001-0000-0000-0000-000000000106',
   'Un voile blanc',
   'false', '3'),

  ('35ce21b9-2cd7-4bc8-9cf8-f3cce31f5b68', 'f0000001-0000-0000-0000-000000000107',
   'La liberté',
   'true', '0'),

  ('c17457b5-c062-48b7-a5d4-fea5f2c7b4c2', 'f0000001-0000-0000-0000-000000000107',
   'Le pouvoir militaire',
   'false', '1'),

  ('978e7520-c3f7-43df-84fb-dda29193ef03', 'f0000001-0000-0000-0000-000000000107',
   'La royauté',
   'false', '2'),

  ('afb124cd-bc42-4263-a5a1-5077f3fed147', 'f0000001-0000-0000-0000-000000000107',
   'La religion catholique',
   'false', '3'),

  ('efc0458c-adab-4d29-b006-1af7587da041', 'f0000001-0000-0000-0000-000000000108',
   'Dans toutes les mairies de France',
   'true', '0'),

  ('3cb43c19-51da-4fc6-a8fe-1e69c6e70f7b', 'f0000001-0000-0000-0000-000000000108',
   'Uniquement à Paris',
   'false', '1'),

  ('b1d6bddf-60a0-4c61-9904-bda91154fadf', 'f0000001-0000-0000-0000-000000000108',
   'Dans les églises',
   'false', '2'),

  ('3f92010e-a942-4a37-a243-a9f5aba4eeff', 'f0000001-0000-0000-0000-000000000108',
   'Dans les écoles privées',
   'false', '3'),

  ('9c69b8bf-6ae4-4e87-9e9b-b9229d60778a', 'f0000001-0000-0000-0000-000000000109',
   'Les timbres et les pièces de monnaie',
   'true', '0'),

  ('24db0b97-42c4-4c0a-9030-e2b776cfa4bd', 'f0000001-0000-0000-0000-000000000109',
   'Les billets de banque uniquement',
   'false', '1'),

  ('6a3ebc12-76ec-4497-b940-138cfabab5a1', 'f0000001-0000-0000-0000-000000000109',
   'Les permis de conduire',
   'false', '2'),

  ('3942ad45-da29-46c8-95fb-4bd6a382e629', 'f0000001-0000-0000-0000-000000000109',
   'Les cartes de transport',
   'false', '3'),

  ('ffb86f1f-a4e6-4f1f-a567-e4ea8b82ea01', 'f0000001-0000-0000-0000-00000000010a',
   'Les maillots des équipes sportives nationales',
   'true', '0'),

  ('56d6c6d7-cd0f-4871-b041-878ea61b80be', 'f0000001-0000-0000-0000-00000000010a',
   'Le drapeau européen',
   'false', '1'),

  ('f7dbc706-e2b9-4dc2-aa68-c52ce84c3223', 'f0000001-0000-0000-0000-00000000010a',
   'Les passeports étrangers',
   'false', '2'),

  ('f5429dab-f709-4243-9680-325d1887e9e4', 'f0000001-0000-0000-0000-00000000010a',
   'Les uniformes scolaires',
   'false', '3'),

  ('378c54a0-965e-4d42-9c75-b581059fc2f4', 'f0000001-0000-0000-0000-00000000010b',
   'Pendant la Révolution française',
   'true', '0'),

  ('8f1e5465-bc85-4f1d-8947-422e5e40311c', 'f0000001-0000-0000-0000-00000000010b',
   'Au Moyen Âge',
   'false', '1'),

  ('92113274-bd86-4f62-b776-309e6338fb8b', 'f0000001-0000-0000-0000-00000000010b',
   'Après la Seconde Guerre mondiale',
   'false', '2'),

  ('14cece98-a5bb-4de6-b1ad-5292c3f3cb64', 'f0000001-0000-0000-0000-00000000010b',
   'Sous Napoléon III',
   'false', '3'),

  ('537db034-ec59-43d3-be98-7c87910d8d0a', 'f0000001-0000-0000-0000-00000000010c',
   'Les bâtiments publics',
   'true', '0'),

  ('d72229a2-2123-4415-b965-283034be5073', 'f0000001-0000-0000-0000-00000000010c',
   'Les commerces de centre-ville',
   'false', '1'),

  ('11f75a61-1738-4d08-a094-d4bb665b286f', 'f0000001-0000-0000-0000-00000000010c',
   'Les immeubles d''habitation',
   'false', '2'),

  ('0c10436a-6e23-4e7a-a36e-4d29221883ca', 'f0000001-0000-0000-0000-00000000010c',
   'Les gares et aéroports uniquement',
   'false', '3'),

  ('b0b4a076-d7a5-4917-9bc4-8d9557466434', 'f0000001-0000-0000-0000-00000000010d',
   'Oui, aux côtés du drapeau français sur les bâtiments officiels',
   'true', '0'),

  ('dd1e9108-b712-49a9-a401-5e5e4bf67ffc', 'f0000001-0000-0000-0000-00000000010d',
   'Non, jamais en France',
   'false', '1'),

  ('4d2ed850-bcc8-480f-b391-8288109b1bf5', 'f0000001-0000-0000-0000-00000000010d',
   'Oui, mais à la place du drapeau français',
   'false', '2'),

  ('5e4516eb-9fd2-417a-987e-f7670eaaf74d', 'f0000001-0000-0000-0000-00000000010d',
   'Uniquement dans les ambassades',
   'false', '3');
