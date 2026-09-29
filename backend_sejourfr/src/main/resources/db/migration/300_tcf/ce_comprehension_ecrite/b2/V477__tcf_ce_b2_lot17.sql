-- ============================================================================
-- V477 — TCF CE B2 — lot 17 (thème : immigration & intégration)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~190-205 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : formation linguistique des primo-arrivants / déclassement des
-- diplômés étrangers / parrainage citoyen / cérémonies de naturalisation /
-- apprentis étrangers devenus majeurs / anciens travailleurs immigrés /
-- interprétariat dans les services publics.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c011-4000-0000-000000000001', 'TEXTE',
   'Apprendre le français est, dit-on, la première marche de l''intégration. L''État en a fait une obligation : tout étranger signataire du contrat d''intégration républicaine se voit prescrire des cours de langue, jusqu''à six cents heures pour les moins avancés. Sur le papier, le dispositif impressionne. Dans les salles de classe, le tableau est moins flatteur.

Les formateurs décrivent des groupes hétérogènes où se côtoient une ingénieure ukrainienne diplômée et un berger soudanais jamais scolarisé, des plannings incompatibles avec les horaires des emplois de nuit, et surtout un objectif final modeste : le niveau visé en fin de parcours permet tout juste de comprendre une conversation simple, pas de suivre une formation qualifiante ni de défendre un dossier devant une administration.

Les comparaisons internationales font mal : l''Allemagne finance des parcours allant jusqu''à neuf cents heures, adossés à des modules professionnels. La France, elle, considère trop souvent la langue comme une formalité d''entrée plutôt que comme un investissement de long terme. Tant que les heures prescrites resteront déconnectées des besoins réels — travailler, étudier, accompagner la scolarité de ses enfants —, on continuera de proclamer que la langue est la clé de l''intégration tout en la laissant sous le paillasson.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c011-4000-0000-000000000002', 'TEXTE',
   'Karim a exercé onze ans comme chirurgien-dentiste à Alep ; il pose aujourd''hui des prothèses comme assistant dentaire à Clermont-Ferrand, pour un salaire divisé par trois. Son parcours n''a rien d''exceptionnel : selon une étude récente, près de quatre immigrés diplômés du supérieur sur dix occupent en France un emploi inférieur à leur qualification, soit deux fois plus que les diplômés nés dans le pays.

Le réflexe consiste à incriminer la barrière de la langue. L''étude montre pourtant que le déclassement persiste chez des personnes parfaitement francophones, installées depuis plus de dix ans. Le verrou se situe ailleurs : dans le maquis des procédures de reconnaissance des diplômes, longues, coûteuses et imprévisibles, et dans la fermeture de dizaines de professions réglementées, accessibles aux seuls titulaires de titres européens.

Ce gâchis a un coût que personne ne chiffre volontiers : des hôpitaux qui manquent de médecins pendant que des praticiens étrangers conduisent des taxis, des laboratoires qui peinent à recruter pendant que des ingénieurs trient des colis. À rebours du discours sur l''« immigration choisie », la France choisit surtout de ne pas utiliser les compétences qu''elle a déjà accueillies.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c011-4000-0000-000000000003', 'TEXTE',
   'À Niort, l''association Tandem réunit chaque mois des binômes improbables : un retraité de l''Éducation nationale et un jeune Afghan, une pharmacienne et une mère érythréenne. Le principe du parrainage citoyen est simple — quelques heures par mois pour aider un nouvel arrivant à déchiffrer un courrier, préparer un entretien, rencontrer des voisins — et ses effets, eux, sont tout sauf anecdotiques : les personnes accompagnées trouvent un emploi presque deux fois plus vite, selon le suivi mené sur trois ans.

On comprend l''engouement des pouvoirs publics, qui multiplient les appels à projets pour étendre la formule. Elle ne coûte presque rien, repose sur la bonne volonté et produit ce que nul dispositif administratif ne sait fabriquer : du lien, des carnets d''adresses, de la confiance.

C''est précisément là que le bât blesse. À force de célébrer les parrains, on en viendrait presque à oublier que l''accès aux droits, au logement ou à la formation relève de la responsabilité de l''État, non de la générosité des particuliers. Le bénévolat fait des merveilles comme complément ; il devient un alibi dès qu''on lui demande de boucher les trous d''une politique d''accueil sous-dimensionnée. Saluer ces initiatives, oui. S''en servir de paravent, non.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c011-4000-0000-000000000004', 'TEXTE',
   'Dans la salle des fêtes de la préfecture du Doubs, ils étaient quarante-trois, ce jeudi, à recevoir leur décret de naturalisation au son de la Marseillaise. Discours du préfet, remise du livret citoyen, photographie devant le drapeau : le rituel, codifié depuis 2007, se veut le point d''orgue d''un parcours qui aura duré, pour la plupart, entre sept et douze ans.

Les recherches menées sur les nouveaux Français racontent pourtant une histoire moins solennelle. Pour beaucoup, le sentiment d''appartenance précédait largement le décret : ils se disaient français bien avant que l''administration ne le confirme. Pour d''autres, c''est l''inverse qui se produit — le passeport ne suffit pas à faire taire la question, posée au détour d''un regard ou d''un entretien d''embauche : « Mais vous venez d''où, vraiment ? »

La cérémonie n''est donc ni inutile ni suffisante. Elle dit quelque chose d''important : la communauté nationale accueille officiellement de nouveaux membres. Mais elle ne clôt rien. L''appartenance ne se délivre pas comme un titre de séjour ; elle se construit dans les mille interactions ordinaires où chacun se voit reconnu — ou renvoyé à ses origines. Le décret fait des citoyens ; c''est la société, ensuite, qui fait les compatriotes.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c011-4000-0000-000000000005', 'TEXTE',
   'Mamadou avait tout pour réussir son CAP de boulangerie à Besançon : un patron qui le décrit comme « le meilleur apprenti en quinze ans », des résultats scolaires solides, un logement stable. À ses dix-huit ans, tout s''est arrêté : faute de titre de séjour, son contrat d''apprentissage a été suspendu, et son employeur s''est retrouvé menacé d''amende pour avoir voulu le garder.

Ce scénario se répète chaque année pour des centaines de jeunes arrivés mineurs, scolarisés et formés aux frais de la collectivité, puis poussés vers la sortie au moment précis où ils allaient devenir autonomes. L''absurdité est double. Humaine, d''abord : on brise des trajectoires exemplaires au seul motif d''une date d''anniversaire. Économique, ensuite : la boulangerie, la restauration ou le bâtiment, qui peinent à recruter, perdent des bras déjà formés, et les sommes investies dans leur éducation partent en pure perte.

Des préfets régularisent, d''autres refusent : la décision dépend moins du dossier que du département. Plusieurs fédérations patronales, peu suspectes d''angélisme, demandent désormais un droit au séjour automatique pour les apprentis arrivés mineurs. Quand les artisans eux-mêmes réclament de la stabilité pour leurs apprentis étrangers, il serait temps que la règle cesse de défaire ce que la formation a construit.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c011-4000-0000-000000000006', 'TEXTE',
   'Ils ont bâti des autoroutes, monté des chaînes d''assemblage, nettoyé des bureaux pendant quarante ans. Aujourd''hui âgés de soixante-quinze ou quatre-vingts ans, plusieurs dizaines de milliers d''anciens ouvriers venus du Maghreb ou d''Afrique de l''Ouest vieillissent seuls dans les chambres de neuf mètres carrés des anciens foyers de travailleurs, là même où ils s''étaient installés « provisoirement » dans les années soixante-dix.

Leur situation tient du paradoxe administratif. Beaucoup n''osent pas rentrer au pays plus de quelques mois par an, sous peine de perdre l''allocation qui complète leur maigre retraite : la loi conditionne ce minimum vieillesse à une résidence continue en France. Les voilà donc assignés à demeure dans un pays qui ne les a jamais vraiment regardés, séparés de familles qu''ils ont financées toute leur vie à distance.

Un rapport parlementaire avait bien proposé, voici quelques années, une aide spécifique permettant ces allers-retours sans pénalité. Le décret d''application a mis sept ans à paraître, et le dispositif reste si restrictif que quelques centaines de personnes seulement en bénéficient. Pour des hommes qui ont passé leur vie à construire le pays, on conviendra que la reconnaissance arrive tard, et chichement. L''oubli, parfois, est une politique.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c011-4000-0000-000000000007', 'TEXTE',
   'À l''hôpital de Mulhouse, c''est souvent un enfant de dix ans qui traduit à sa mère le diagnostic du médecin. Dans les caisses d''allocations, un agent se débrouille avec un traducteur automatique ; au commissariat, on attend qu''un collègue « parle un peu l''arabe ». L''interprétariat professionnel, pourtant reconnu comme un métier à part entière, reste l''angle mort des services publics français : aucune obligation légale générale, des budgets dérisoires, un recours laissé au bon vouloir de chaque structure.

Les conséquences dépassent le simple inconfort. Une étude conduite dans trois hôpitaux révèle que les patients non francophones subissent davantage d''examens inutiles — prescrits faute de pouvoir mener un interrogatoire clinique fiable — et reviennent plus souvent aux urgences pour la même pathologie. Autrement dit, l''économie réalisée en se passant d''interprètes se paie au double, en actes redondants et en erreurs de compréhension.

D''autres pays ont tranché : en Suède, le droit à un interprète dans les démarches essentielles est inscrit dans la loi depuis les années quatre-vingt. La France, elle, continue de considérer la traduction comme un luxe, alors qu''elle conditionne l''accès réel aux droits — et, accessoirement, l''efficacité de ses propres services. Mal se comprendre coûte toujours plus cher que se faire comprendre.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c011-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c011-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale défendue par l''auteur ?',
   'L''auteur conclut que la France proclame que « la langue est la clé de l''intégration tout en la laissant sous le paillasson » : **l''idée principale est l''insuffisance de la formation linguistique au regard des besoins réels** (travailler, étudier, suivre la scolarité des enfants). La réponse A inverse la comparaison : c''est l''Allemagne qui finance des parcours plus ambitieux, la France n''est pas présentée en modèle. La réponse C est un **détail vrai mais secondaire** : les neuf cents heures allemandes servent d''argument, pas de thèse. La réponse D inverse la prémisse du texte, qui pose au contraire la langue comme « première marche de l''intégration ». Mécanisme : distinguer la **thèse** des arguments d''appui.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c011-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c011-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur le déclassement professionnel des immigrés diplômés ?',
   'Le texte écarte explicitement « le réflexe » de la barrière de la langue et situe « le verrou ailleurs » : **la cause centrale est l''obstacle administratif** — procédures de reconnaissance des diplômes « longues, coûteuses et imprévisibles » et professions réglementées fermées. La réponse A inverse un point explicite : le déclassement « persiste chez des personnes parfaitement francophones ». La réponse B est une **sur-généralisation** d''un chiffre : quatre diplômés sur dix sont déclassés, pas la totalité. La réponse C contredit un détail : ces professions restent « accessibles aux seuls titulaires de titres européens », aucune ouverture récente n''est mentionnée. Mécanisme : inférence de la **cause principale** contre une explication tentante mais réfutée par le texte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c011-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c011-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur sur le parrainage citoyen ?',
   'Le texte salue des effets « tout sauf anecdotiques » puis bascule avec « C''est précisément là que le bât blesse » : **l''auteur approuve le parrainage comme complément mais refuse qu''il serve d''« alibi » à l''État** (« Saluer ces initiatives, oui. S''en servir de paravent, non. »). La réponse B inverse les faits : l''efficacité est chiffrée (emploi trouvé presque deux fois plus vite). La réponse C inverse la thèse : l''accès aux droits « relève de la responsabilité de l''État, non de la générosité des particuliers ». La réponse D contredit un détail : les pouvoirs publics « multiplient les appels à projets », ils ne freinent rien. Mécanisme : repérer le **mouvement concessif** (éloge… mais) qui exprime une adhésion sous condition.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c011-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c011-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Que cherche à montrer l''auteur à propos des cérémonies de naturalisation ?',
   'La conclusion condense la thèse : la cérémonie « n''est donc ni inutile ni suffisante » et « le décret fait des citoyens ; c''est la société, ensuite, qui fait les compatriotes ». **La bonne réponse reformule ce double mouvement : valeur symbolique réelle, mais reconnaissance sociale non garantie.** La réponse A est une sur-généralisation du versant critique : « ni inutile » exclut la suppression. La réponse B inverse les observations : le sentiment d''appartenance précède souvent le décret, et le passeport « ne suffit pas à faire taire la question ». La réponse D promeut un **détail vrai mais secondaire** (la durée de sept à douze ans) en intention principale, et lui ajoute un découragement jamais affirmé. Mécanisme : **inférence d''intention** à partir d''une structure en balancement (ni… ni).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c011-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c011-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'Le texte qualifie la situation d''« absurdité double », « humaine » et « économique », et conclut que « la règle cesse de défaire ce que la formation a construit » : **l''idée principale est le non-sens consistant à interrompre à la majorité des parcours d''apprentissage réussis**. La réponse A inverse l''attitude des employeurs : le patron de Mamadou voulait le garder et les fédérations patronales réclament un droit au séjour, la crainte des sanctions est une conséquence subie, pas un refus d''embaucher. La réponse C inverse les faits : c''est justement l''absence de titre automatique qui brise ces parcours. La réponse D contredit un détail explicite : « Des préfets régularisent, d''autres refusent », la décision varie selon le département. Mécanisme : résister aux **inversions de cause et de position** des acteurs.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c011-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c011-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Comment l''auteur juge-t-il le traitement réservé aux anciens travailleurs immigrés ?',
   'La chute — « la reconnaissance arrive tard, et chichement. L''oubli, parfois, est une politique » — donne le ton : **l''auteur dénonce l''ingratitude de la collectivité envers des hommes « qui ont passé leur vie à construire le pays »**. La réponse A inverse la portée du dispositif : le décret a mis sept ans à paraître et « quelques centaines de personnes seulement en bénéficient », rien d''une liberté retrouvée. La réponse B inverse la responsabilité : ce n''est pas un choix de ces retraités, la loi sur le minimum vieillesse les « assigne à demeure ». La réponse C inverse l''effet de cette même loi, présentée comme un « paradoxe administratif » qui les piège, non comme une protection. Mécanisme : identifier le **ton de l''auteur** (ironie amère de la chute) derrière un exposé factuel.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c011-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c011-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur l''absence d''interprètes professionnels dans les services publics ?',
   'Le pivot du texte est « l''économie réalisée en se passant d''interprètes se paie au double », résumé par la chute : « Mal se comprendre coûte toujours plus cher que se faire comprendre ». **La bonne réponse reformule cette inférence de conséquence : renoncer aux interprètes coûte finalement plus cher.** La réponse B inverse le cadre juridique : il n''existe « aucune obligation légale générale » en France, contrairement à la Suède. La réponse C sur-généralise un détail : le traducteur automatique illustre le bricolage des agents, pas une solution. La réponse D inverse un résultat de l''étude : les patients non francophones « reviennent plus souvent aux urgences », pas moins. Mécanisme : **inférence de conséquence implicite** (fausse économie) contre des distracteurs en inversion.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — formation linguistique des primo-arrivants (bonne réponse : position 2)
  ('11111111-c011-2100-0000-000000000001', '11111111-c011-1000-0000-000000000001',
   'L''obligation de cours de français a fait de la France un modèle européen d''intégration',
   'false', '1'),

  ('11111111-c011-2200-0000-000000000001', '11111111-c011-1000-0000-000000000001',
   'La formation linguistique offerte aux nouveaux arrivants reste très en deçà des besoins réels d''intégration',
   'true', '2'),

  ('11111111-c011-2300-0000-000000000001', '11111111-c011-1000-0000-000000000001',
   'L''Allemagne propose des parcours de langue plus longs que ceux de la France',
   'false', '3'),

  ('11111111-c011-2400-0000-000000000001', '11111111-c011-1000-0000-000000000001',
   'La maîtrise de la langue n''est pas un facteur déterminant de l''intégration',
   'false', '4'),

  -- item 02 — déclassement des diplômés étrangers (bonne réponse : position 4)
  ('11111111-c011-2100-0000-000000000002', '11111111-c011-1000-0000-000000000002',
   'Il disparaît dès que les personnes maîtrisent parfaitement le français',
   'false', '1'),

  ('11111111-c011-2200-0000-000000000002', '11111111-c011-1000-0000-000000000002',
   'Il touche la totalité des immigrés diplômés de l''enseignement supérieur',
   'false', '2'),

  ('11111111-c011-2300-0000-000000000002', '11111111-c011-1000-0000-000000000002',
   'Les professions réglementées se sont récemment ouvertes aux diplômés non européens',
   'false', '3'),

  ('11111111-c011-2400-0000-000000000002', '11111111-c011-1000-0000-000000000002',
   'Il s''explique surtout par les obstacles administratifs à la reconnaissance des qualifications',
   'true', '4'),

  -- item 03 — parrainage citoyen (bonne réponse : position 1)
  ('11111111-c011-2100-0000-000000000003', '11111111-c011-1000-0000-000000000003',
   'Il en reconnaît l''efficacité mais refuse qu''il se substitue à la responsabilité de l''État',
   'true', '1'),

  ('11111111-c011-2200-0000-000000000003', '11111111-c011-1000-0000-000000000003',
   'Il doute des effets réels de ces accompagnements sur l''accès à l''emploi',
   'false', '2'),

  ('11111111-c011-2300-0000-000000000003', '11111111-c011-1000-0000-000000000003',
   'Il appelle l''État à confier l''accueil des nouveaux arrivants aux seuls bénévoles',
   'false', '3'),

  ('11111111-c011-2400-0000-000000000003', '11111111-c011-1000-0000-000000000003',
   'Il reproche aux pouvoirs publics de freiner le développement de ces initiatives',
   'false', '4'),

  -- item 04 — cérémonies de naturalisation (bonne réponse : position 3)
  ('11111111-c011-2100-0000-000000000004', '11111111-c011-1000-0000-000000000004',
   'Qu''elles devraient être supprimées car elles n''ont aucun effet sur les nouveaux citoyens',
   'false', '1'),

  ('11111111-c011-2200-0000-000000000004', '11111111-c011-1000-0000-000000000004',
   'Que le décret de naturalisation fait naître le sentiment d''appartenance chez tous les nouveaux Français',
   'false', '2'),

  ('11111111-c011-2300-0000-000000000004', '11111111-c011-1000-0000-000000000004',
   'Qu''elles ont une valeur symbolique réelle mais ne garantissent pas une pleine reconnaissance sociale',
   'true', '3'),

  ('11111111-c011-2400-0000-000000000004', '11111111-c011-1000-0000-000000000004',
   'Que la durée de la procédure, de sept à douze ans, décourage la plupart des candidats',
   'false', '4'),

  -- item 05 — apprentis étrangers devenus majeurs (bonne réponse : position 2)
  ('11111111-c011-2100-0000-000000000005', '11111111-c011-1000-0000-000000000005',
   'Les employeurs refusent d''embaucher des apprentis étrangers par crainte des sanctions',
   'false', '1'),

  ('11111111-c011-2200-0000-000000000005', '11111111-c011-1000-0000-000000000005',
   'Interrompre à leur majorité le parcours d''apprentis étrangers est un non-sens humain et économique',
   'true', '2'),

  ('11111111-c011-2300-0000-000000000005', '11111111-c011-1000-0000-000000000005',
   'Les jeunes étrangers obtiennent automatiquement un titre de séjour grâce à l''apprentissage',
   'false', '3'),

  ('11111111-c011-2400-0000-000000000005', '11111111-c011-1000-0000-000000000005',
   'Les préfectures appliquent partout les mêmes critères de régularisation des apprentis',
   'false', '4'),

  -- item 06 — anciens travailleurs immigrés (bonne réponse : position 4)
  ('11111111-c011-2100-0000-000000000006', '11111111-c011-1000-0000-000000000006',
   'Il salue l''aide spécifique qui a enfin permis à ces retraités de circuler librement',
   'false', '1'),

  ('11111111-c011-2200-0000-000000000006', '11111111-c011-1000-0000-000000000006',
   'Il reproche à ces retraités de ne pas être rentrés dans leur pays d''origine',
   'false', '2'),

  ('11111111-c011-2300-0000-000000000006', '11111111-c011-1000-0000-000000000006',
   'Il estime que la loi sur le minimum vieillesse protège efficacement ces anciens ouvriers',
   'false', '3'),

  ('11111111-c011-2400-0000-000000000006', '11111111-c011-1000-0000-000000000006',
   'Il dénonce l''ingratitude de la collectivité envers des hommes qui ont contribué à construire le pays',
   'true', '4'),

  -- item 07 — interprétariat dans les services publics (bonne réponse : position 1)
  ('11111111-c011-2100-0000-000000000007', '11111111-c011-1000-0000-000000000007',
   'Renoncer aux interprètes professionnels finit par coûter plus cher que d''y recourir',
   'true', '1'),

  ('11111111-c011-2200-0000-000000000007', '11111111-c011-1000-0000-000000000007',
   'Les hôpitaux français ont l''obligation légale de fournir un interprète aux patients',
   'false', '2'),

  ('11111111-c011-2300-0000-000000000007', '11111111-c011-1000-0000-000000000007',
   'Les traducteurs automatiques ont résolu l''essentiel des problèmes de communication',
   'false', '3'),

  ('11111111-c011-2400-0000-000000000007', '11111111-c011-1000-0000-000000000007',
   'Les patients non francophones reviennent moins souvent que les autres aux urgences',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c011-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « immigration & intégration », 7 angles tous différents :
--     formation linguistique des primo-arrivants / déclassement professionnel
--     des diplômés étrangers / parrainage citoyen / cérémonies de
--     naturalisation / apprentis étrangers devenus majeurs / anciens
--     travailleurs immigrés (minimum vieillesse) / interprétariat dans les
--     services publics. Aucun thème interdit utilisé.
-- [x] Textes B2 longs : 199 / 189 / 200 / 202 / 205 / 196 / 204 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (ex. « quatre sur dix », « ni inutile ni suffisante », « des préfets
--     régularisent, d''autres refusent », heures allemandes vs françaises).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2 (items 1, 5),
--     ce_inference_intention ×3 (items 2, 4, 7), ce_ton_auteur ×2 (items 3, 6).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme nommé
--     (concession, inversion cause/effet, sur-généralisation, détail vrai
--     mais secondaire, inférence d''intention/conséquence).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (prénoms — Karim, Mamadou —,
--     association Tandem, villes — Niort, Besançon, Mulhouse,
--     Clermont-Ferrand —, chiffres inventés).
-- ============================================================================
