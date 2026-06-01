-- ============================================================================
-- V221 — Civique : Système institutionnel (lot 1)
-- ----------------------------------------------------------------------------
-- Questions + choix. Filtre: 11111111-0000-0000-0000-000000000002 .
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('f2000000-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Qui nomme le Premier ministre ?',
   'Le Premier ministre est nommé par le président de la République (article 8 de la Constitution). Il dirige l''action du gouvernement.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Le Parlement est composé :',
   'Le Parlement français est bicaméral : il comprend l''Assemblée nationale (députés) et le Sénat (sénateurs).',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que le pouvoir exécutif ? Le pouvoir :',
   'Le pouvoir exécutif est chargé d''appliquer les lois et de diriger la politique de la nation. En France, il est exercé par le président et le gouvernement.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Les dirigeants sont élus par les citoyens dans :',
   'Dans une démocratie, les dirigeants sont élus par les citoyens lors d''élections libres. La France est une démocratie représentative.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000005', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'A-t-on le droit de ne pas respecter une loi ?',
   'Non. Tout citoyen doit respecter la loi. Ne pas la respecter expose à des sanctions pénales ou civiles, prononcées par les tribunaux.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000006', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Qui doit respecter la loi ?',
   'Toute personne présente sur le territoire français doit respecter la loi : citoyens français, étrangers, résidents, touristes, dirigeants politiques.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel est le rôle de l''autorité judiciaire ?',
   'L''autorité judiciaire fait respecter la loi, tranche les conflits entre personnes et sanctionne les infractions. Elle est indépendante du pouvoir politique.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel pouvoir détient un juge ? Le pouvoir :',
   'Le juge exerce le pouvoir judiciaire : il dit le droit, tranche les litiges et sanctionne les infractions, en toute indépendance.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'L''autorité judiciaire est exercée par :',
   'L''autorité judiciaire est exercée par les juges et magistrats, dans les tribunaux. Ils sont indépendants des pouvoirs exécutif et législatif.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que se passe-t-il si un ministre ne respecte pas la loi ?',
   'Un ministre, comme tout citoyen, est soumis à la loi. Il peut être jugé par la Cour de justice de la République pour les actes commis dans ses fonctions.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Qui est élu lors des élections législatives ?',
   'Les élections législatives élisent les députés de l''Assemblée nationale, au suffrage universel direct.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Combien de députés composent l''Assemblée nationale ?',
   'L''Assemblée nationale compte 577 députés, élus pour 5 ans au suffrage universel direct, chacun dans une circonscription.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quand sont élus les sénateurs ?',
   'Les sénateurs sont élus pour 6 ans au suffrage indirect, par environ 162 000 "grands électeurs" (députés, conseillers régionaux, départementaux, municipaux). Le Sénat est renouvelé par moitié tous les 3 ans.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Qui est élu lors des élections municipales ?',
   'Les élections municipales elisent les conseillers municipaux. Ces conseillers élisent ensuite le maire de la commune.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Qui est élu lors des élections présidentielles ?',
   'L''élection présidentielle élit le président de la République, au suffrage universel direct, pour un mandat de 5 ans, depuis 1962.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'À partir de quel âge a-t-on le droit de voter ?',
   'En France, le droit de vote est accordé à partir de 18 ans, âge de la majorité civile fixée depuis 1974.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Pour combien de temps est élu le président de la République française ?',
   'Le président de la République est élu pour 5 ans (quinquennat) depuis la réforme constitutionnelle de 2000.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Pour combien de temps sont élus les députés ?',
   'Les députés sont élus pour 5 ans au suffrage universel direct, par circonscription.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Pour combien de temps sont élus les sénateurs ?',
   'Les sénateurs sont élus pour 6 ans au suffrage universel indirect. Le Sénat est renouvelé par moitié tous les 3 ans.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui possède le pouvoir exécutif ?',
   'Le pouvoir exécutif est détenu par le président de la République et le gouvernement (Premier ministre et ministres).',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle condition est nécessaire pour voter aux élections ?',
   'Pour voter en France, il faut être majeur (18 ans), de nationalité française (sauf élections locales et européennes pour les ressortissants UE), jouir de ses droits civils, et être inscrit sur les listes électorales.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui peut voter aux élections en France ?',
   'Aux élections nationales, seuls les citoyens français majeurs et inscrits sur les listes peuvent voter. Les ressortissants UE peuvent voter aux municipales et européennes.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que signifie "suffrage universel" ?',
   'Le suffrage universel signifie que tous les citoyens majeurs ont le droit de voter, sans condition de fortune, de sexe ou d''éducation. En France : universel masculin en 1848, étendu aux femmes en 1944.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Concernant les partis politiques, quelle proposition est correcte ?',
   'Les partis politiques se forment librement et concourent à l''expression du suffrage (article 4 de la Constitution). Le multipartisme est garanti.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel est le rôle des députés ?',
   'Les députés votent les lois, contrôlent l''action du gouvernement et représentent les citoyens de leur circonscription à l''Assemblée nationale.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'La séparation des pouvoirs est un principe fondamental. Quels sont les trois pouvoirs concernés ?',
   'Selon Montesquieu, les trois pouvoirs sont : législatif (faire les lois), exécutif (les appliquer), judiciaire (sanctionner leur non-respect). Ils doivent être séparés pour éviter la concentration du pouvoir.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui possède le pouvoir législatif ?',
   'Le pouvoir législatif est détenu par le Parlement, composé de l''Assemblée nationale et du Sénat. Il vote les lois et le budget de l''État.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui sanctionne l''auteur d''un vol ?',
   'Le vol est une infraction pénale. C''est un tribunal, dans le cadre du pouvoir judiciaire, qui juge et sanctionne l''auteur du vol.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Qui élit les députés ?',
   'Les députés sont élus par les citoyens français majeurs au suffrage universel direct, par circonscription.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Qui vote les lois ?',
   'Les lois sont votées par le Parlement (Assemblée nationale + Sénat). C''est le pouvoir législatif.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-00000000001f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Qui réside au palais de l''Élysée ?',
   'Le palais de l''Élysée, à Paris, est la résidence officielle du président de la République depuis 1873.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000020', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Combien y a-t-il de départements en France ?',
   'La France compte 101 départements : 96 en métropole et 5 outre-mer (Guadeloupe, Martinique, Guyane, La Réunion, Mayotte).',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000021', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui représente l''État dans un département ?',
   'Le préfet est le représentant de l''État dans un département. Il est nommé par le président sur proposition du Premier ministre.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000022', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Qui dirige la commune ?',
   'Le maire dirige la commune. Il est élu par le conseil municipal pour 6 ans. Il est officier d''état civil et de police judiciaire.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000023', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Est-ce que le président de la République a tous les pouvoirs ?',
   'Non. Les pouvoirs sont séparés : le président partage le pouvoir exécutif avec le gouvernement, le Parlement vote les lois, et la justice est indépendante.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000024', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui est le préfet ?',
   'Le préfet est le représentant de l''État dans le département (ou la région). Il met en œuvre la politique du gouvernement au niveau local.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000025', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel est le rôle du Parlement ?',
   'Le Parlement vote les lois, autorise le budget de l''État et contrôle l''action du gouvernement.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000026', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel est le régime politique de la France aujourd''hui ?',
   'La France est sous le régime de la Ve République depuis 1958. C''est une république semi-présidentielle.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000027', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Combien d''États font partie de l''Union européenne au 1er janvier 2025 ?',
   'L''Union européenne compte 27 États membres depuis le retrait du Royaume-Uni (Brexit) en 2020.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000028', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel État n''est pas membre de l''Union européenne ?',
   'La Suisse n''est pas membre de l''Union européenne. Elle a refusé plusieurs fois par référendum. Le Royaume-Uni est sorti de l''UE en 2020 (Brexit).',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-000000000029', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle condition est nécessaire pour voter aux élections européennes ?',
   'Pour voter aux élections européennes, il faut être majeur, ressortissant d''un État membre de l''UE et inscrit sur les listes électorales en France.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-00000000002a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'À quelle fréquence les élections européennes sont-elles organisées ?',
   'Les élections européennes ont lieu tous les 5 ans, simultanément dans tous les États membres de l''UE.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-00000000002b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel pays est un pays fondateur de l''Union européenne ?',
   'Les 6 pays fondateurs (CEE 1957) sont : France, Allemagne, Italie, Belgique, Pays-Bas et Luxembourg.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-00000000002c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle est la monnaie utilisée en France ?',
   'L''euro est la monnaie de la France depuis le 1er janvier 2002, partagée avec 19 autres pays de la zone euro.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-00000000002d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qui élit les députés européens ?',
   'Les députés du Parlement européen sont élus au suffrage universel direct par les citoyens des États membres, tous les 5 ans.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000000-0000-0000-0000-00000000002e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quand célèbre-t-on la journée de l''Europe ?',
   'La journée de l''Europe est célébrée le 9 mai, en commémoration de la déclaration de Robert Schuman du 9 mai 1950, acte fondateur de la construction européenne.',
   'true', '2026-05-27 17:40:29.759953+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000001-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelle autorité désigne le Premier ministre en France ?',
   'Le Premier ministre est nommé par le président de la République, conformément à l''article 8 de la Constitution. Il dirige l''action du gouvernement.',
   'true', '2026-05-27 17:40:29.835446+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000001-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quelles sont les deux assemblées qui forment le Parlement français ?',
   'Le Parlement français est bicaméral : il est composé de l''Assemblée nationale (députés) et du Sénat (sénateurs).',
   'true', '2026-05-27 17:40:29.835446+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000001-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle est la mission principale du pouvoir exécutif ?',
   'Le pouvoir exécutif est chargé de faire appliquer les lois et de conduire la politique de la nation. Il est exercé par le président de la République et le gouvernement.',
   'true', '2026-05-27 17:40:29.835446+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f2000001-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Dans quel type de régime les dirigeants sont-ils choisis par les citoyens ?',
   'Dans une démocratie, les dirigeants sont élus par les citoyens. C''est ce qui distingue ce régime des monarchies absolues, des dictatures ou des théocraties.',
   'true', '2026-05-27 17:40:29.835446+02', NULL, 'ACTIVE', NULL, NULL, NULL);

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('484e78de-34a4-473d-9e34-ead6c4b85b66', 'f2000000-0000-0000-0000-000000000001',
   'Le président de la République',
   'true', '0'),

  ('c0566237-279e-40ce-8ffc-76432a108092', 'f2000000-0000-0000-0000-000000000001',
   'L''Assemblée nationale',
   'false', '1'),

  ('958b9032-9bb4-4c03-9463-c472f99c8211', 'f2000000-0000-0000-0000-000000000001',
   'Le Conseil constitutionnel',
   'false', '2'),

  ('177a892c-37a0-47a4-8ddd-59a897435acf', 'f2000000-0000-0000-0000-000000000001',
   'Les citoyens au suffrage direct',
   'false', '3'),

  ('2ef79e20-a0db-4a4e-a532-2cc2927a87f0', 'f2000000-0000-0000-0000-000000000002',
   'De l''Assemblée nationale et du Sénat',
   'true', '0'),

  ('4ffae6f3-0e63-4d86-a822-19fdd529e9e1', 'f2000000-0000-0000-0000-000000000002',
   'Du président et des ministres',
   'false', '1'),

  ('e535aebf-9b56-4534-8742-e49a5154a000', 'f2000000-0000-0000-0000-000000000002',
   'Du Conseil constitutionnel uniquement',
   'false', '2'),

  ('b5ac207a-9d53-4c2d-96bc-70a5df9e82df', 'f2000000-0000-0000-0000-000000000002',
   'Des maires et des préfets',
   'false', '3'),

  ('dfcadb2c-aa22-4fb4-bb4f-3806168a85c8', 'f2000000-0000-0000-0000-000000000003',
   'D''appliquer les lois et de diriger l''État',
   'true', '0'),

  ('3867b100-3e7c-4e91-8a90-67612f5f4c75', 'f2000000-0000-0000-0000-000000000003',
   'De voter les lois',
   'false', '1'),

  ('581c171d-4041-4410-97ef-06217f51fe10', 'f2000000-0000-0000-0000-000000000003',
   'De juger les citoyens',
   'false', '2'),

  ('d055c145-3733-47fe-892c-e3c4f1fe2dd4', 'f2000000-0000-0000-0000-000000000003',
   'De modifier la Constitution',
   'false', '3'),

  ('b9548869-aa1f-4ce7-ab97-1cb5ab26a9e1', 'f2000000-0000-0000-0000-000000000004',
   'Une démocratie',
   'true', '0'),

  ('b32598f3-39f5-41b6-9daa-b3af499a6031', 'f2000000-0000-0000-0000-000000000004',
   'Une dictature',
   'false', '1'),

  ('cd9de878-8dff-4934-a1c7-699ce2dc77e0', 'f2000000-0000-0000-0000-000000000004',
   'Une monarchie absolue',
   'false', '2'),

  ('09b96405-72c9-4584-9626-5f0dd4fc3229', 'f2000000-0000-0000-0000-000000000004',
   'Une théocratie',
   'false', '3'),

  ('70f62f76-f596-4bb9-8d0b-a5adc6b95014', 'f2000000-0000-0000-0000-000000000005',
   'Non, tout le monde doit respecter la loi',
   'true', '0'),

  ('a37b5517-b992-41d1-bbb7-2abfa0f5d990', 'f2000000-0000-0000-0000-000000000005',
   'Oui, si on n''est pas d''accord avec elle',
   'false', '1'),

  ('f664054d-e75b-49e0-bdca-cb27d7996f01', 'f2000000-0000-0000-0000-000000000005',
   'Oui, dans son foyer privé',
   'false', '2'),

  ('90b7eb73-618c-497b-9163-f78a216a94f2', 'f2000000-0000-0000-0000-000000000005',
   'Oui, si on est mineur',
   'false', '3'),

  ('708a9d1d-ed92-424e-929c-50825e8f6842', 'f2000000-0000-0000-0000-000000000006',
   'Toute personne présente sur le territoire français',
   'true', '0'),

  ('d8c42cae-bef4-4f67-b93f-73320dc05693', 'f2000000-0000-0000-0000-000000000006',
   'Uniquement les citoyens français',
   'false', '1'),

  ('50a01d78-70d5-40f3-a84a-a6f07de77812', 'f2000000-0000-0000-0000-000000000006',
   'Uniquement les majeurs',
   'false', '2'),

  ('58c7ae91-b3dc-4bc3-8b20-56a5558c4433', 'f2000000-0000-0000-0000-000000000006',
   'Uniquement les personnes salariées',
   'false', '3'),

  ('c204100d-71a7-4333-a56e-3407dc710b10', 'f2000000-0000-0000-0000-000000000007',
   'Faire respecter la loi et juger les litiges',
   'true', '0'),

  ('b2962d13-187e-40a3-8d69-805a6a0a09c1', 'f2000000-0000-0000-0000-000000000007',
   'Voter les lois',
   'false', '1'),

  ('e5e8d80f-e43d-4c08-ad64-78ba506d4e17', 'f2000000-0000-0000-0000-000000000007',
   'Nommer le président',
   'false', '2'),

  ('d255db76-13fd-4480-ac8d-f789369143e8', 'f2000000-0000-0000-0000-000000000007',
   'Diriger l''armée',
   'false', '3'),

  ('ea847f37-eec5-49a8-a2c2-9d25f13d1db2', 'f2000000-0000-0000-0000-000000000008',
   'Judiciaire',
   'true', '0'),

  ('b345d2dc-0cbe-4386-b16b-3d4ea59112f0', 'f2000000-0000-0000-0000-000000000008',
   'Législatif',
   'false', '1'),

  ('91cf98b0-52d8-462f-99b5-e56394dc6d82', 'f2000000-0000-0000-0000-000000000008',
   'Exécutif',
   'false', '2'),

  ('dd06ccaf-fb1a-4c18-8862-2a5124d71af8', 'f2000000-0000-0000-0000-000000000008',
   'Constituant',
   'false', '3'),

  ('90fec36b-2a15-4b60-ac4d-1ff2ddd170ce', 'f2000000-0000-0000-0000-000000000009',
   'Les juges et les magistrats',
   'true', '0'),

  ('0b91578f-111e-4cc1-a138-208a9d4ee1aa', 'f2000000-0000-0000-0000-000000000009',
   'Les députés et sénateurs',
   'false', '1'),

  ('0e036032-c999-4097-979f-7ba6101028da', 'f2000000-0000-0000-0000-000000000009',
   'Les ministres',
   'false', '2'),

  ('f795e782-afe4-4f76-bced-390edd376f62', 'f2000000-0000-0000-0000-000000000009',
   'Le président seul',
   'false', '3'),

  ('db34e636-3330-48b5-9ec5-d423134657cc', 'f2000000-0000-0000-0000-00000000000a',
   'Il peut être jugé comme tout citoyen',
   'true', '0'),

  ('22a47944-401a-46c7-80df-af484f1c08c9', 'f2000000-0000-0000-0000-00000000000a',
   'Rien, il a l''immunité totale',
   'false', '1'),

  ('a0b67653-816e-4a38-a36e-af9c86685169', 'f2000000-0000-0000-0000-00000000000a',
   'Il perd seulement son poste',
   'false', '2'),

  ('319b618e-14e2-4781-ade6-50b288b52b81', 'f2000000-0000-0000-0000-00000000000a',
   'Il décide lui-même de sa sanction',
   'false', '3'),

  ('0ca2b7fd-0d6c-428f-a9b7-810f70171b89', 'f2000000-0000-0000-0000-00000000000b',
   'Les députés',
   'true', '0'),

  ('87ef2a4b-a4ba-47f4-a210-1b7c8ca5dd1d', 'f2000000-0000-0000-0000-00000000000b',
   'Le président',
   'false', '1'),

  ('1ca0e080-2e42-4b44-9361-47451bdb7b9c', 'f2000000-0000-0000-0000-00000000000b',
   'Les maires',
   'false', '2'),

  ('468b357c-7e51-46b5-952d-a0f15054dcb7', 'f2000000-0000-0000-0000-00000000000b',
   'Les sénateurs',
   'false', '3'),

  ('4d56402c-a88c-4b74-889c-b31e72a2504f', 'f2000000-0000-0000-0000-00000000000c',
   '577 députés',
   'true', '0'),

  ('108a5d8d-34c6-41f7-adc6-0c854f5189d6', 'f2000000-0000-0000-0000-00000000000c',
   '348 députés',
   'false', '1'),

  ('2e8de922-43e6-4291-af97-e040661c8cf7', 'f2000000-0000-0000-0000-00000000000c',
   '500 députés',
   'false', '2'),

  ('3761ec38-b2ee-4d63-92e8-4e9f721b6332', 'f2000000-0000-0000-0000-00000000000c',
   '1000 députés',
   'false', '3'),

  ('33b6bda9-3871-4719-8410-5b40f17c9aaa', 'f2000000-0000-0000-0000-00000000000d',
   'Tous les 3 ans, par moitié',
   'true', '0'),

  ('7a9c5224-8524-4382-99fb-19942d70350d', 'f2000000-0000-0000-0000-00000000000d',
   'Tous les ans',
   'false', '1'),

  ('d56071f1-ea31-493b-a266-e2d0923a6d47', 'f2000000-0000-0000-0000-00000000000d',
   'Tous les 5 ans en même temps',
   'false', '2'),

  ('9b478c85-6aa0-42f7-8569-86d6f7b52de3', 'f2000000-0000-0000-0000-00000000000d',
   'Tous les 10 ans',
   'false', '3'),

  ('68378efb-2a92-477e-b538-f219f7afee36', 'f2000000-0000-0000-0000-00000000000e',
   'Les conseillers municipaux (qui élisent le maire)',
   'true', '0'),

  ('adf3f49b-fd22-4b3e-b2ca-945ffc88f047', 'f2000000-0000-0000-0000-00000000000e',
   'Le président de la République',
   'false', '1'),

  ('62067e34-baba-4a4d-be08-20f29f218a28', 'f2000000-0000-0000-0000-00000000000e',
   'Les députés',
   'false', '2'),

  ('68eeb2b2-5113-4fb8-98c2-1689ca010901', 'f2000000-0000-0000-0000-00000000000e',
   'Les préfets',
   'false', '3'),

  ('61e1a65d-5cda-4cac-a383-1600f1b30912', 'f2000000-0000-0000-0000-00000000000f',
   'Le président de la République',
   'true', '0'),

  ('2a2e59fd-3999-49ed-b006-26d10f99e356', 'f2000000-0000-0000-0000-00000000000f',
   'Le Premier ministre',
   'false', '1'),

  ('a9791c7c-5d65-48c2-9a77-ac8ef8b70222', 'f2000000-0000-0000-0000-00000000000f',
   'Les ministres',
   'false', '2'),

  ('f28eeda5-aec0-49e8-982e-13802b5077b1', 'f2000000-0000-0000-0000-00000000000f',
   'Les sénateurs',
   'false', '3'),

  ('f1ea691f-6769-4f92-8576-c37173beb3fb', 'f2000000-0000-0000-0000-000000000010',
   '18 ans',
   'true', '0'),

  ('fafddb6b-5e38-4697-bb46-6b0092c77de5', 'f2000000-0000-0000-0000-000000000010',
   '16 ans',
   'false', '1'),

  ('a89af85d-f708-474d-89f9-0d303894444e', 'f2000000-0000-0000-0000-000000000010',
   '21 ans',
   'false', '2'),

  ('95c881a1-e803-401a-96f7-1778921e3225', 'f2000000-0000-0000-0000-000000000010',
   '25 ans',
   'false', '3'),

  ('0beaa22a-acd5-4442-b5ee-f14cc335c20d', 'f2000000-0000-0000-0000-000000000011',
   '5 ans',
   'true', '0'),

  ('3b2ab939-16ac-40d9-a143-423a739e7d3f', 'f2000000-0000-0000-0000-000000000011',
   '4 ans',
   'false', '1'),

  ('7febaeb5-3ee1-403c-86e5-fcd32ea907c5', 'f2000000-0000-0000-0000-000000000011',
   '6 ans',
   'false', '2'),

  ('0a75a83d-2069-4fa5-b7e4-3334a665fccd', 'f2000000-0000-0000-0000-000000000011',
   '7 ans',
   'false', '3'),

  ('d7616d3e-91f0-47cf-b6b0-a8d0608e2a54', 'f2000000-0000-0000-0000-000000000012',
   '5 ans',
   'true', '0'),

  ('ff500b94-4155-4d07-a504-bd697589852c', 'f2000000-0000-0000-0000-000000000012',
   '4 ans',
   'false', '1'),

  ('07a8f6f2-8acd-48d0-bb1f-918d63a1ce1a', 'f2000000-0000-0000-0000-000000000012',
   '6 ans',
   'false', '2'),

  ('67f67680-68ba-437f-8438-1e7b4f21eadb', 'f2000000-0000-0000-0000-000000000012',
   '7 ans',
   'false', '3'),

  ('476bc4cb-8990-46cd-8fd7-de645bdb4954', 'f2000000-0000-0000-0000-000000000013',
   '6 ans',
   'true', '0'),

  ('a00e78c0-7397-48b3-8929-cca9a6af1602', 'f2000000-0000-0000-0000-000000000013',
   '5 ans',
   'false', '1'),

  ('6deeab34-526a-4c16-89db-9fa1cfa75243', 'f2000000-0000-0000-0000-000000000013',
   '3 ans',
   'false', '2'),

  ('ef0957f6-825e-40d1-be87-2ae3e2032760', 'f2000000-0000-0000-0000-000000000013',
   '9 ans',
   'false', '3'),

  ('bed2a5e8-6dd5-4c5f-abd3-d40d4da2b7da', 'f2000000-0000-0000-0000-000000000014',
   'Le président et le gouvernement',
   'true', '0'),

  ('f15fbc08-cee1-4f0c-8ad3-65b0686d4696', 'f2000000-0000-0000-0000-000000000014',
   'L''Assemblée nationale et le Sénat',
   'false', '1'),

  ('453e9c5f-f6f9-4f94-b5c6-be6ff92889ae', 'f2000000-0000-0000-0000-000000000014',
   'Les tribunaux',
   'false', '2'),

  ('e711c112-e270-41f0-b7a9-76b411e1bbc3', 'f2000000-0000-0000-0000-000000000014',
   'Le Conseil constitutionnel',
   'false', '3'),

  ('2b1391db-ac70-49a3-af26-b8ff2bb9a224', 'f2000000-0000-0000-0000-000000000015',
   'Être majeur, citoyen et inscrit sur les listes électorales',
   'true', '0'),

  ('1304ed64-431d-4e73-a087-1b0740f7dd68', 'f2000000-0000-0000-0000-000000000015',
   'Avoir suivi des études supérieures',
   'false', '1'),

  ('f208affa-12ec-4764-a7d5-ff490078664d', 'f2000000-0000-0000-0000-000000000015',
   'Être propriétaire',
   'false', '2'),

  ('4b17ff95-8691-4af9-a0bf-9fb4f6a1f811', 'f2000000-0000-0000-0000-000000000015',
   'Payer un impôt spécifique',
   'false', '3'),

  ('6e572417-a081-4e01-9bd0-10733cb1e1f0', 'f2000000-0000-0000-0000-000000000016',
   'Les citoyens français majeurs inscrits sur les listes électorales',
   'true', '0'),

  ('f03f267e-2e11-48d6-a083-3e832a55c4da', 'f2000000-0000-0000-0000-000000000016',
   'Tous les résidents en France, français ou non',
   'false', '1'),

  ('95fe001c-bdbb-40a0-936a-41644a999282', 'f2000000-0000-0000-0000-000000000016',
   'Uniquement les fonctionnaires',
   'false', '2'),

  ('fa4b2196-34e4-4bac-a097-3e93757144b0', 'f2000000-0000-0000-0000-000000000016',
   'Toute personne de plus de 16 ans',
   'false', '3'),

  ('44752111-5f1f-4f2c-95db-942bc4a2ea54', 'f2000000-0000-0000-0000-000000000017',
   'Tous les citoyens majeurs ont le droit de vote',
   'true', '0'),

  ('ec52ec21-9957-47d0-bb5b-ecb214e47c22', 'f2000000-0000-0000-0000-000000000017',
   'Le vote est obligatoire pour tous',
   'false', '1'),

  ('a471e7fa-18bd-4c71-9b28-a74632b1ddfa', 'f2000000-0000-0000-0000-000000000017',
   'Seuls les hommes peuvent voter',
   'false', '2'),

  ('00d19250-e3d8-4925-a625-772edbb84324', 'f2000000-0000-0000-0000-000000000017',
   'Le vote des étrangers est autorisé',
   'false', '3'),

  ('84073ba1-aff3-42c5-a134-2b350f49d84b', 'f2000000-0000-0000-0000-000000000018',
   'Plusieurs partis politiques peuvent exister librement',
   'true', '0'),

  ('ba85fe1a-a08f-4c8a-b3fc-4a8d2cf9a70d', 'f2000000-0000-0000-0000-000000000018',
   'Il n''y a qu''un seul parti autorisé',
   'false', '1'),

  ('5daf541d-9b5d-418f-bb2c-831671a7996c', 'f2000000-0000-0000-0000-000000000018',
   'Les partis politiques sont interdits',
   'false', '2'),

  ('15ff5835-df78-4d41-8125-1ec085ed205b', 'f2000000-0000-0000-0000-000000000018',
   'Seuls les ministres peuvent créer un parti',
   'false', '3'),

  ('1e07f02a-1cb9-421d-bc82-82f91a412e09', 'f2000000-0000-0000-0000-000000000019',
   'Voter les lois et contrôler le gouvernement',
   'true', '0'),

  ('c35e8daa-c711-4165-ac49-79d144ddf2bb', 'f2000000-0000-0000-0000-000000000019',
   'Diriger les ministères',
   'false', '1'),

  ('ab3930ec-f7b4-4827-bb47-40afbbd90c01', 'f2000000-0000-0000-0000-000000000019',
   'Juger les criminels',
   'false', '2'),

  ('f89bf975-4d46-4b57-9c35-f7a642e9d2fb', 'f2000000-0000-0000-0000-000000000019',
   'Nommer le président',
   'false', '3'),

  ('1bddbc84-5a78-4bf3-afa0-7f9348ba1d21', 'f2000000-0000-0000-0000-00000000001a',
   'Législatif, exécutif, judiciaire',
   'true', '0'),

  ('bc3a4274-1dab-47e0-a6da-306c9f83d65d', 'f2000000-0000-0000-0000-00000000001a',
   'Politique, économique, militaire',
   'false', '1'),

  ('e343d8d6-a347-4bba-bd74-792793ac4f33', 'f2000000-0000-0000-0000-00000000001a',
   'National, régional, local',
   'false', '2'),

  ('e943ccdb-20d7-4434-b29e-e2f498499c0b', 'f2000000-0000-0000-0000-00000000001a',
   'Civil, pénal, administratif',
   'false', '3'),

  ('448084ba-671b-476b-8e3e-32cb2e6447f6', 'f2000000-0000-0000-0000-00000000001b',
   'Le Parlement (Assemblée nationale + Sénat)',
   'true', '0'),

  ('7a1a5219-d5bb-487b-8fcd-ec22b63e2764', 'f2000000-0000-0000-0000-00000000001b',
   'Le président seul',
   'false', '1'),

  ('d2a9196f-14da-4525-896b-636d16cbe5e8', 'f2000000-0000-0000-0000-00000000001b',
   'Les juges',
   'false', '2'),

  ('7471bd52-a756-48f2-a89b-44ff6c4a88b0', 'f2000000-0000-0000-0000-00000000001b',
   'Les maires',
   'false', '3'),

  ('46c49aa6-d669-4993-95e1-3105ba44f1b8', 'f2000000-0000-0000-0000-00000000001c',
   'Un tribunal (juge)',
   'true', '0'),

  ('602c81ea-b8be-4e3e-bb1b-ea6b719c5275', 'f2000000-0000-0000-0000-00000000001c',
   'Le maire',
   'false', '1'),

  ('49a0e184-8e0d-436f-bc24-e48437459962', 'f2000000-0000-0000-0000-00000000001c',
   'La victime elle-même',
   'false', '2'),

  ('e13c93c6-ff6a-4c08-967b-6737eb69dc44', 'f2000000-0000-0000-0000-00000000001c',
   'Le Premier ministre',
   'false', '3'),

  ('4f68e89b-44ce-43a8-aa39-54f2c856820d', 'f2000000-0000-0000-0000-00000000001d',
   'Les citoyens majeurs au suffrage universel direct',
   'true', '0'),

  ('da39a5fb-604c-463b-80e6-dc3c63909336', 'f2000000-0000-0000-0000-00000000001d',
   'Les sénateurs',
   'false', '1'),

  ('1aca3b38-b452-418a-9079-dae8badc2419', 'f2000000-0000-0000-0000-00000000001d',
   'Le président de la République',
   'false', '2'),

  ('aa0975dd-5ca0-4cbe-abac-a82352426007', 'f2000000-0000-0000-0000-00000000001d',
   'Les maires',
   'false', '3'),

  ('ebaa9921-9baa-4ad8-93e6-afcd379495f2', 'f2000000-0000-0000-0000-00000000001e',
   'Le Parlement',
   'true', '0'),

  ('978618ba-3de2-4f6b-8dbe-e9a2d60d5ce1', 'f2000000-0000-0000-0000-00000000001e',
   'Le président seul',
   'false', '1'),

  ('848a6dbc-952e-485e-a66c-0423eb7823bd', 'f2000000-0000-0000-0000-00000000001e',
   'Le Conseil constitutionnel',
   'false', '2'),

  ('33d184d7-7a9f-41d4-bcce-96a57d8fe10f', 'f2000000-0000-0000-0000-00000000001e',
   'Les juges',
   'false', '3'),

  ('15f2483a-75c0-4215-84f1-f5b15e7fde4c', 'f2000000-0000-0000-0000-00000000001f',
   'Le président de la République',
   'true', '0'),

  ('40f74ce6-5a88-4a5f-b53e-ccafa5efe712', 'f2000000-0000-0000-0000-00000000001f',
   'Le Premier ministre',
   'false', '1'),

  ('a9aa5ddf-b96a-45f4-a28c-2fbc09a08103', 'f2000000-0000-0000-0000-00000000001f',
   'Le président du Sénat',
   'false', '2'),

  ('50c6a8bf-3054-4227-9bc8-d32e088833db', 'f2000000-0000-0000-0000-00000000001f',
   'Le maire de Paris',
   'false', '3'),

  ('95352c20-059e-49bc-a844-42df28b5f121', 'f2000000-0000-0000-0000-000000000020',
   '101 départements (96 en métropole, 5 outre-mer)',
   'true', '0'),

  ('5bc99f0e-3b94-4af6-8f69-05473adf3dba', 'f2000000-0000-0000-0000-000000000020',
   '50',
   'false', '1'),

  ('85598ad8-860b-4cde-8547-3020e4f47f69', 'f2000000-0000-0000-0000-000000000020',
   '83',
   'false', '2'),

  ('cfdfdcae-54ce-464b-affa-20ba95a53d1c', 'f2000000-0000-0000-0000-000000000020',
   '120',
   'false', '3'),

  ('9c66ce4a-46c2-452c-a627-8d980bd3a1e0', 'f2000000-0000-0000-0000-000000000021',
   'Le préfet',
   'true', '0'),

  ('4c26a7df-3be9-41d7-b769-7969a67fd97c', 'f2000000-0000-0000-0000-000000000021',
   'Le maire',
   'false', '1'),

  ('566866bb-5ba3-4b12-97ad-30107c843cc5', 'f2000000-0000-0000-0000-000000000021',
   'Le député',
   'false', '2'),

  ('bcfddabb-2263-4855-ae8d-fdd24c9f826a', 'f2000000-0000-0000-0000-000000000021',
   'Le procureur',
   'false', '3'),

  ('3a3395e0-cb52-40c8-862e-02a226a395fd', 'f2000000-0000-0000-0000-000000000022',
   'Le maire',
   'true', '0'),

  ('16c7d10c-412d-4adf-8e62-689d9d665e47', 'f2000000-0000-0000-0000-000000000022',
   'Le préfet',
   'false', '1'),

  ('77000ab4-0172-4c0f-8eb5-f610fc1f2567', 'f2000000-0000-0000-0000-000000000022',
   'Le député',
   'false', '2'),

  ('2a181326-c96f-4180-9bc3-876f225547ea', 'f2000000-0000-0000-0000-000000000022',
   'Le ministre de l''Intérieur',
   'false', '3'),

  ('a350f691-9b48-4e5c-8ac5-e17cd3ab445e', 'f2000000-0000-0000-0000-000000000023',
   'Non, les pouvoirs sont séparés',
   'true', '0'),

  ('0da9a514-2f5c-4a4e-baaf-2d2ed7195e20', 'f2000000-0000-0000-0000-000000000023',
   'Oui, il décide de tout',
   'false', '1'),

  ('44ca0a53-f9b2-4f62-8067-3628397b5a4c', 'f2000000-0000-0000-0000-000000000023',
   'Oui, il peut modifier seul la Constitution',
   'false', '2'),

  ('9c71b5f0-f1ec-4dec-9bc4-e5d1129e3f3d', 'f2000000-0000-0000-0000-000000000023',
   'Oui, sauf en cas de guerre',
   'false', '3'),

  ('b9c0c1e0-8f42-4280-bab2-c9f2d726974d', 'f2000000-0000-0000-0000-000000000024',
   'Le représentant de l''État dans le département',
   'true', '0'),

  ('e9f3bb6d-c69a-48c6-81e8-7c76ff60d278', 'f2000000-0000-0000-0000-000000000024',
   'Un élu municipal',
   'false', '1'),

  ('1812e5f0-8245-4c79-a86e-2e36ca8537ab', 'f2000000-0000-0000-0000-000000000024',
   'Le chef de la police nationale',
   'false', '2'),

  ('cfff6c7a-269f-403f-84e8-a4234525aa4e', 'f2000000-0000-0000-0000-000000000024',
   'Un juge spécialisé',
   'false', '3'),

  ('e6591e04-b875-438f-96da-35fda6d77395', 'f2000000-0000-0000-0000-000000000025',
   'Voter les lois et contrôler le gouvernement',
   'true', '0'),

  ('0529bf11-6f0a-43cc-9a31-f0fd290ec7c6', 'f2000000-0000-0000-0000-000000000025',
   'Diriger les ministères',
   'false', '1'),

  ('62f0daa3-0a83-47e9-bf79-a2f5a97234c9', 'f2000000-0000-0000-0000-000000000025',
   'Rendre la justice',
   'false', '2'),

  ('7106278b-5c5d-4e7e-b90b-1166a9439619', 'f2000000-0000-0000-0000-000000000025',
   'Nommer les préfets',
   'false', '3'),

  ('86ff39f3-9a25-4166-a19b-e77fee3c5549', 'f2000000-0000-0000-0000-000000000026',
   'La Ve République',
   'true', '0'),

  ('ef4cc02d-0d52-4f26-be48-abb4a7685bfd', 'f2000000-0000-0000-0000-000000000026',
   'La IVe République',
   'false', '1'),

  ('0497a9f8-fd32-40b5-ba80-7d94e3e63bb3', 'f2000000-0000-0000-0000-000000000026',
   'L''Empire',
   'false', '2'),

  ('d3e69cdc-fbf6-4eea-b62e-51297af3c0e6', 'f2000000-0000-0000-0000-000000000026',
   'La monarchie constitutionnelle',
   'false', '3'),

  ('357759c3-59e0-439e-a433-568246f7ee01', 'f2000000-0000-0000-0000-000000000027',
   '27 États',
   'true', '0'),

  ('f978c027-efff-4d36-b11d-e14a3b544f8c', 'f2000000-0000-0000-0000-000000000027',
   '15 États',
   'false', '1'),

  ('82204584-89c6-43f5-91ac-3600bed63792', 'f2000000-0000-0000-0000-000000000027',
   '28 États',
   'false', '2'),

  ('49ae5d20-eb5b-493e-b82f-44f850e8c3ae', 'f2000000-0000-0000-0000-000000000027',
   '50 États',
   'false', '3'),

  ('c53aec9a-31d3-4840-a580-2e92a79cf4f8', 'f2000000-0000-0000-0000-000000000028',
   'La Suisse',
   'true', '0'),

  ('bcc3b7f1-3df0-4943-a46a-6866d158ee25', 'f2000000-0000-0000-0000-000000000028',
   'L''Italie',
   'false', '1'),

  ('504776f7-c221-47cb-9d83-2f1201cca585', 'f2000000-0000-0000-0000-000000000028',
   'L''Allemagne',
   'false', '2'),

  ('6d95f00a-ba24-437e-9105-f55095bf5a78', 'f2000000-0000-0000-0000-000000000028',
   'L''Espagne',
   'false', '3'),

  ('91acc4e7-5557-48f0-b791-ba45e1e5d70f', 'f2000000-0000-0000-0000-000000000029',
   'Être majeur et citoyen d''un État membre de l''UE',
   'true', '0'),

  ('5397f960-bfdc-40f6-b728-df95bee9286b', 'f2000000-0000-0000-0000-000000000029',
   'Être obligatoirement de nationalité française',
   'false', '1'),

  ('27b16b61-28e3-43af-a298-626338f97827', 'f2000000-0000-0000-0000-000000000029',
   'Résider en Belgique',
   'false', '2'),

  ('9fd1bbcb-837c-45c9-860a-8239ac2e5eeb', 'f2000000-0000-0000-0000-000000000029',
   'Parler trois langues européennes',
   'false', '3'),

  ('62937721-8d18-4c8b-9d63-41ef5be29dff', 'f2000000-0000-0000-0000-00000000002a',
   'Tous les 5 ans',
   'true', '0'),

  ('96877b63-e35b-4b53-8b04-e1af53f90fe2', 'f2000000-0000-0000-0000-00000000002a',
   'Tous les ans',
   'false', '1'),

  ('38fd4b5e-9b6c-41b4-8da8-5f58c8c3dff7', 'f2000000-0000-0000-0000-00000000002a',
   'Tous les 3 ans',
   'false', '2'),

  ('128dc4da-dbfb-469f-85ac-584aff2eae58', 'f2000000-0000-0000-0000-00000000002a',
   'Tous les 10 ans',
   'false', '3'),

  ('33430034-2f48-498e-a656-ce070860e04a', 'f2000000-0000-0000-0000-00000000002b',
   'La France',
   'true', '0'),

  ('25ce00c9-699b-445d-8730-a9c02e8365ad', 'f2000000-0000-0000-0000-00000000002b',
   'L''Espagne',
   'false', '1'),

  ('38c8f6a3-d688-4bee-89c9-81ab37a0f0c7', 'f2000000-0000-0000-0000-00000000002b',
   'La Pologne',
   'false', '2'),

  ('b267095b-05d8-42ab-b0ed-858f044aacd0', 'f2000000-0000-0000-0000-00000000002b',
   'La Grèce',
   'false', '3'),

  ('3738b5ca-8282-4027-814a-98ecaaf18b8d', 'f2000000-0000-0000-0000-00000000002c',
   'L''euro',
   'true', '0'),

  ('51568b7f-8626-4b57-b0bf-a801720771b0', 'f2000000-0000-0000-0000-00000000002c',
   'Le franc',
   'false', '1'),

  ('015d91ef-c3d5-4506-9cc3-35fc9085d613', 'f2000000-0000-0000-0000-00000000002c',
   'La livre sterling',
   'false', '2'),

  ('e916a157-35cd-4a93-bfd1-2b8f154c8249', 'f2000000-0000-0000-0000-00000000002c',
   'Le dollar',
   'false', '3'),

  ('93716daf-4524-4d4e-9dd0-bb53b10e579d', 'f2000000-0000-0000-0000-00000000002d',
   'Les citoyens des États membres de l''UE',
   'true', '0'),

  ('f19bc8aa-564f-4f42-95ca-caa0f50aa490', 'f2000000-0000-0000-0000-00000000002d',
   'Les chefs d''État',
   'false', '1'),

  ('6892f73d-e2e1-4c3c-b76b-c1a2259f0c01', 'f2000000-0000-0000-0000-00000000002d',
   'Les ministres',
   'false', '2'),

  ('454d0e09-9c73-457b-9452-4734735c35b6', 'f2000000-0000-0000-0000-00000000002d',
   'La Cour de justice européenne',
   'false', '3'),

  ('54786c1a-0c31-47ee-98b3-d1a0b963f271', 'f2000000-0000-0000-0000-00000000002e',
   'Le 9 mai',
   'true', '0'),

  ('c3721565-bab5-4b28-9b52-5e8864b5208c', 'f2000000-0000-0000-0000-00000000002e',
   'Le 14 juillet',
   'false', '1'),

  ('2b679cac-491e-4545-9c6b-f9de12a3a781', 'f2000000-0000-0000-0000-00000000002e',
   'Le 1er janvier',
   'false', '2'),

  ('7a0314a6-d821-4390-b01a-467b0cd5f8f7', 'f2000000-0000-0000-0000-00000000002e',
   'Le 11 novembre',
   'false', '3'),

  ('67052b39-d194-403d-8579-dd024b217bb9', 'f2000001-0000-0000-0000-000000000001',
   'Le président de la République',
   'true', '0'),

  ('9b335bf9-cb2a-4f9f-a035-daa34cefd368', 'f2000001-0000-0000-0000-000000000001',
   'Le président du Sénat',
   'false', '1'),

  ('7a802dfd-9970-49f4-8013-a8e41d604654', 'f2000001-0000-0000-0000-000000000001',
   'Le maire de Paris',
   'false', '2'),

  ('8e54d41c-3318-4d0d-b076-b57cb300f40b', 'f2000001-0000-0000-0000-000000000001',
   'Le peuple par référendum',
   'false', '3'),

  ('3d2b5502-6d39-4e62-89ca-556fae19ef5d', 'f2000001-0000-0000-0000-000000000002',
   'L''Assemblée nationale et le Sénat',
   'true', '0'),

  ('8412eb78-3eb3-4f59-8f98-120930292e60', 'f2000001-0000-0000-0000-000000000002',
   'Le gouvernement et le Conseil d''État',
   'false', '1'),

  ('f4e266ea-aef3-45ec-ad22-561803dac798', 'f2000001-0000-0000-0000-000000000002',
   'Le Conseil constitutionnel et le Sénat',
   'false', '2'),

  ('bcc13344-7dc4-4686-945c-4de92b764d21', 'f2000001-0000-0000-0000-000000000002',
   'L''Élysée et Matignon',
   'false', '3'),

  ('7a41dca0-4c3c-4b3a-8d8e-e7909db3c2ea', 'f2000001-0000-0000-0000-000000000003',
   'Faire appliquer les lois et diriger la politique de l''État',
   'true', '0'),

  ('7aa351de-ac01-4134-910c-405b6d058d84', 'f2000001-0000-0000-0000-000000000003',
   'Voter les lois',
   'false', '1'),

  ('b12e0838-30e5-463b-ba4e-b816a9d6c603', 'f2000001-0000-0000-0000-000000000003',
   'Juger les délinquants',
   'false', '2'),

  ('0252c3fe-c5fd-4cec-8ebe-953f180bf1fd', 'f2000001-0000-0000-0000-000000000003',
   'Réviser la Constitution',
   'false', '3'),

  ('d9ef94f5-6c38-41e4-b912-b3b72ba23611', 'f2000001-0000-0000-0000-000000000004',
   'Dans une démocratie',
   'true', '0'),

  ('ea3975ab-79ce-4e03-80c0-8cbd6cd80d13', 'f2000001-0000-0000-0000-000000000004',
   'Dans une dictature',
   'false', '1'),

  ('a8149d30-2355-423d-8929-6a26472f9c0d', 'f2000001-0000-0000-0000-000000000004',
   'Dans une théocratie',
   'false', '2'),

  ('4e128e4b-66ee-4b4a-9640-162e2a3fb8e0', 'f2000001-0000-0000-0000-000000000004',
   'Dans une monarchie absolue',
   'false', '3');
