-- ============================================================================
-- V295 — VINGT-CINQ CORRECTIONS FACTUELLES DU CORPUS CIVIQUE.
-- ----------------------------------------------------------------------------
-- Passe de QA éditorial et factuel du 2026-09-11 : les 800 questions de
-- connaissance ont été relues, et les ~120 qui portent un nombre, une date, un
-- seuil ou un nom d'organisme ont été confrontées à des sources officielles
-- (Légifrance, service-public.gouv.fr, BCE, europa.eu, ameli.fr, OIF).
--
-- 🛑 TROIS ERREURS SUR QUATRE TOUCHENT LA BONNE RÉPONSE, PAS L'EXPLICATION.
-- L'âge de départ à la retraite, la validité de la carte d'identité et l'âge du
-- permis B donnaient tous une réponse fausse. Un contrôle qui ne relirait que
-- les explications les aurait manquées toutes les trois — et un candidat qui
-- révise sur une réponse fausse la répétera à l'examen.
--
-- 🛑 LE CORPUS SE CONTREDISAIT AVEC LUI-MÊME en quatre endroits, ce qui est
-- pire qu'une erreur isolée : le Défenseur des droits « administrative » ici et
-- « constitutionnelle » là ; l'Élysée résidence « depuis 1873 » et « depuis
-- 1848 » ; la loi qui devrait être « votée dans les mêmes termes » alors
-- qu'une autre question donne correctement le dernier mot à l'Assemblée.
--
-- Ce que chaque correction répare, avec sa source, est consigné dans
-- `QA-CONTENU-A-VERIFIER.md`. Les six doutes non tranchés y figurent aussi, et
-- ne sont PAS corrigés ici : on ne remplace pas un fait douteux par un autre.
--
-- ⚠️ Aucune notion n'est touchée, aucun thème ne bouge. La taxonomie est gelée.
-- ============================================================================

-- ---- Explications réécrites (25) -------------------------------------------
UPDATE questions SET explanation = $tx$L'âge légal de départ dépend de l'année de naissance. La réforme de 2023 le relevait progressivement de 62 à 64 ans ; ce calendrier est suspendu depuis le 1er septembre 2026 et jusqu'au 1er janvier 2028 (loi du 30 décembre 2025). Né en 1964 : 62 ans et 9 mois ; en 1966 : 63 ans et 3 mois ; en 1969 ou après : 64 ans.$tx$ WHERE id = 'f5000002-0000-0000-0000-00000000003f';
UPDATE questions SET explanation = $tx$La loi Claeys-Leonetti du 2 février 2016, toujours en vigueur, reconnaît la sédation profonde et continue jusqu'au décès et rend les directives anticipées contraignantes. La loi du 18 août 2026 a en outre créé un droit à l'aide à mourir, sous conditions strictes : être majeur, français ou résidant de façon stable, atteint d'une affection grave et incurable en phase avancée ou terminale, avec une souffrance réfractaire, et exprimer une volonté libre et éclairée.$tx$ WHERE id = 'f3000002-0000-0000-0000-000000000052';
UPDATE questions SET explanation = $tx$Depuis le format carte bancaire du 2 août 2021, la carte nationale d'identité est valable 10 ans pour un majeur comme pour un mineur. Les cartes de l'ancien format délivrées entre 2014 et le 1er août 2021 restent valables 15 ans.$tx$ WHERE id = 'f5000002-0000-0000-0000-000000000025';
UPDATE questions SET explanation = $tx$L'inscription à l'auto-école est possible dès 16 ans, et dès 15 ans en conduite accompagnée. L'épreuve pratique se passe à 17 ans et, depuis le 1er janvier 2024, on peut conduire seul dès l'obtention du permis à 17 ans.$tx$ WHERE id = 'f5000002-0000-0000-0000-000000000006';
UPDATE questions SET explanation = $tx$Depuis le 1er janvier 2024, on peut conduire seul dès 17 ans. La conduite accompagnée commence à 15 ans et l'épreuve pratique se passe à 17 ans.$tx$ WHERE id = 'f3000002-0000-0000-0000-000000000006';
UPDATE questions SET explanation = $tx$Le gilet de haute visibilité, à portée de main dans l'habitacle et non dans le coffre, et le triangle de présignalisation sont obligatoires. L'éthylotest n'est plus obligatoire à bord depuis 2020 ; seuls les débits de boissons ouverts la nuit doivent en mettre à disposition.$tx$ WHERE id = 'f5000002-0000-0000-0000-000000000022';
UPDATE questions SET explanation = $tx$Non. L'euro est utilisé par 21 des 27 pays de l'Union européenne, qui forment la zone euro, la Bulgarie l'ayant adopté le 1er janvier 2026. Des pays comme la Pologne ou la Suède ont conservé leur monnaie nationale.$tx$ WHERE id = 'f2000002-0000-0000-0000-000000000027';
UPDATE questions SET explanation = $tx$L'euro est la monnaie de la France depuis le 1er janvier 2002. Il est partagé avec 20 autres pays de l'Union européenne, soit 21 au total depuis l'entrée de la Bulgarie le 1er janvier 2026.$tx$ WHERE id = 'f2000000-0000-0000-0000-00000000002c';
UPDATE questions SET explanation = $tx$Le congé de paternité et d'accueil de l'enfant est de 25 jours calendaires, ou 32 pour des naissances multiples, auxquels s'ajoutent 3 jours de congé de naissance : 28 ou 35 jours au total. Un congé supplémentaire de naissance, d'un à deux mois indemnisés par parent, existe depuis le 1er juillet 2026.$tx$ WHERE id = 'f5000002-0000-0000-0000-000000000045';
UPDATE questions SET explanation = $tx$Le contrat d'intégration républicaine comprend une formation civique de quatre journées, soit 24 heures, et si nécessaire une formation linguistique pouvant aller jusqu'à 600 heures, qui vise le niveau A2 depuis 2026.$tx$ WHERE id = 'f5000002-0000-0000-0000-00000000004b';
UPDATE questions SET explanation = $tx$11 vaccinations sont obligatoires pour les enfants nés entre 2018 et 2024, et 12 pour ceux nés depuis le 1er janvier 2025 : le méningocoque C a été remplacé par le méningocoque ACWY et le méningocoque B a été ajouté. Elles protègent l'enfant et, par l'immunité collective, ceux qui ne peuvent pas être vaccinés.$tx$ WHERE id = 'f5000000-0000-0000-0000-000000000015';
UPDATE questions SET explanation = $tx$11 vaccinations sont obligatoires pour les enfants nés entre 2018 et 2024, et 12 pour ceux nés depuis le 1er janvier 2025. L'obligation protège l'enfant lui-même et, par l'immunité collective, les personnes qui ne peuvent pas être vaccinées.$tx$ WHERE id = 'f5000001-0000-0000-0000-000000000015';
UPDATE questions SET explanation = $tx$Édith Piaf, Dalida, Mireille Mathieu, Barbara, Vanessa Paradis, Mylène Farmer ou Patricia Kaas comptent parmi les chanteuses françaises les plus connues.$tx$ WHERE id = 'f4000001-0000-0000-0000-00000000002a';
UPDATE questions SET explanation = $tx$La France élit 81 députés européens pour la législature 2024-2029. Après le Brexit, elle en comptait 79 : 74 élus en 2019, puis 5 sièges supplémentaires au 1er février 2020 issus de la redistribution des sièges britanniques.$tx$ WHERE id = 'f2000002-0000-0000-0000-000000000047';
UPDATE questions SET explanation = $tx$Depuis le 1er janvier 2026, le niveau A2 doit être justifié par un diplôme ou une certification. Auparavant, aucun niveau n'était opposable : il suffisait d'avoir suivi avec assiduité et sérieux les formations du contrat d'intégration républicaine.$tx$ WHERE id = 'f5000002-0000-0000-0000-00000000004c';
UPDATE questions SET explanation = $tx$Interdit depuis le 1er février 2007 dans les lieux publics et de travail fermés, et depuis le 1er janvier 2008 dans les bars, restaurants, hôtels, casinos et discothèques. Depuis le 1er juillet 2025, l'interdiction s'étend aux plages en saison, aux parcs et jardins publics, aux abribus, aux abords des écoles, aux bibliothèques et aux équipements sportifs.$tx$ WHERE id = 'f3000002-0000-0000-0000-00000000000d';
UPDATE questions SET explanation = $tx$Le 39 39, Allô Service Public, renseigne sur les démarches administratives. Le service est gratuit ; seul l'appel est facturé au tarif normal de votre opérateur. Depuis l'étranger : +33 1 73 60 39 39.$tx$ WHERE id = 'f5000002-0000-0000-0000-000000000023';
UPDATE questions SET explanation = $tx$Le SMIC est le salaire minimum légal en dessous duquel aucun salarié ne peut être payé. Il est revalorisé au moins une fois par an au 1er janvier, et automatiquement en cours d'année dès que l'inflation constatée atteint 2 %.$tx$ WHERE id = 'f5000001-0000-0000-0000-000000000009';
UPDATE questions SET explanation = $tx$Le pharmacien délivre les médicaments, conseille les patients et peut prescrire et administrer tous les vaccins du calendrier vaccinal aux personnes de 11 ans et plus.$tx$ WHERE id = 'f5000002-0000-0000-0000-000000000010';
UPDATE questions SET explanation = $tx$L'Organisation internationale de la Francophonie regroupe les États et gouvernements ayant le français en partage. Le rapport 2026 recense 396 millions de locuteurs de français dans le monde, quatrième langue la plus parlée.$tx$ WHERE id = 'f4000002-0000-0000-0000-000000000027';
UPDATE questions SET explanation = $tx$Oui. Le Sénat dispose de l'initiative des lois au même titre que l'Assemblée nationale. En cas de désaccord persistant après la navette et la commission mixte paritaire, le Gouvernement peut donner le dernier mot à l'Assemblée nationale, en application de l'article 45 de la Constitution.$tx$ WHERE id = 'f2000002-0000-0000-0000-000000000017';
UPDATE questions SET explanation = $tx$La saisine doit intervenir après l'adoption définitive et avant la promulgation. Elle suspend le délai de 15 jours dont dispose le président pour promulguer la loi ; le Conseil constitutionnel statue dans le mois, ou dans les huit jours en cas d'urgence.$tx$ WHERE id = 'f2000002-0000-0000-0000-000000000086';
UPDATE questions SET explanation = $tx$Le palais de l'Élysée, à Paris, est la résidence du président de la République depuis 1848 ; ce statut a été officiellement fixé par la loi du 22 janvier 1879.$tx$ WHERE id = 'f2000000-0000-0000-0000-00000000001f';
UPDATE questions SET explanation = $tx$Il peut saisir le Défenseur des droits, autorité constitutionnelle indépendante créée en 2011 et inscrite à l'article 71-1 de la Constitution, ou exercer un recours devant la juridiction administrative.$tx$ WHERE id = 'f2000002-0000-0000-0000-000000000051';

-- ---- Énoncé réécrit : une invention de 1895 n'est pas du XXe siecle --------
UPDATE questions SET statement = $tx$Quelle invention des frères Lumière a donné naissance au cinéma ?$tx$ WHERE id = 'f4000002-0000-0000-0000-0000000000c2';

-- ---- Bonnes réponses corrigées (4) ----------------------------------------
UPDATE choices SET label = $tx$Entre 62 ans et 9 mois et 64 ans selon l'année de naissance$tx$ WHERE question_id = 'f5000002-0000-0000-0000-00000000003f' AND is_correct AND label = $tx$64 ans (après la réforme de 2023)$tx$;
UPDATE choices SET label = $tx$10 ans (majeurs comme mineurs)$tx$ WHERE question_id = 'f5000002-0000-0000-0000-000000000025' AND is_correct AND label = $tx$15 ans pour les majeurs (10 ans pour mineurs)$tx$;
UPDATE choices SET label = $tx$17 ans pour conduire seul (15 ans en conduite accompagnée)$tx$ WHERE question_id = 'f5000002-0000-0000-0000-000000000006' AND is_correct AND label = $tx$18 ans pour conduire seul (17 en conduite accompagnée)$tx$;
UPDATE choices SET label = $tx$17 ans, depuis 2024$tx$ WHERE question_id = 'f3000002-0000-0000-0000-000000000006' AND is_correct AND label = $tx$18 ans (avec quelques exceptions)$tx$;

-- ---- Un distracteur devenu ambigu depuis la loi du 18 aout 2026 ------------
UPDATE choices SET label = $tx$Oui, l'euthanasie active est autorisée sans aucune condition$tx$ WHERE question_id = 'f3000002-0000-0000-0000-000000000052' AND NOT is_correct AND label = $tx$Oui, l'euthanasie est légalisée$tx$;

-- ----------------------------------------------------------------------------
-- Les corrections ont-elles porté ? Sur une base neuve toutes ces questions
-- existent ; ailleurs, aucune. Entre les deux, un énoncé a bougé depuis la QA.
-- ----------------------------------------------------------------------------
DO $ctrl$
DECLARE trouvees integer;
BEGIN
    SELECT count(*) INTO trouvees FROM questions
     WHERE id IN ('f5000002-0000-0000-0000-00000000003f',
                  'f3000002-0000-0000-0000-000000000052',
                  'f5000002-0000-0000-0000-000000000025',
                  'f5000002-0000-0000-0000-000000000006',
                  'f3000002-0000-0000-0000-000000000006',
                  'f5000002-0000-0000-0000-000000000022',
                  'f2000002-0000-0000-0000-000000000027',
                  'f2000000-0000-0000-0000-00000000002c',
                  'f5000002-0000-0000-0000-000000000045',
                  'f5000002-0000-0000-0000-00000000004b',
                  'f5000000-0000-0000-0000-000000000015',
                  'f5000001-0000-0000-0000-000000000015',
                  'f4000001-0000-0000-0000-00000000002a',
                  'f2000002-0000-0000-0000-000000000047',
                  'f5000002-0000-0000-0000-00000000004c',
                  'f3000002-0000-0000-0000-00000000000d',
                  'f5000002-0000-0000-0000-000000000023',
                  'f5000001-0000-0000-0000-000000000009',
                  'f5000002-0000-0000-0000-000000000010',
                  'f4000002-0000-0000-0000-000000000027',
                  'f2000002-0000-0000-0000-000000000017',
                  'f2000002-0000-0000-0000-000000000086',
                  'f2000000-0000-0000-0000-00000000001f',
                  'f2000002-0000-0000-0000-000000000051');
    IF trouvees <> 0 AND trouvees <> 24 THEN
        RAISE EXCEPTION 'V295 : % questions retrouvees sur 24 a corriger.', trouvees;
    END IF;
END $ctrl$;
