-- ============================================================================
-- V476 — TCF CE B2 — lot 16 (thème : vie associative)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~190-215 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : pénurie de dirigeants bénévoles / financement par appels à projets /
-- engagement des jeunes bénévoles / professionnalisation et place des
-- bénévoles / mécénat de compétences / assemblées générales désertées /
-- reconnaissance des compétences bénévoles.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c010-4000-0000-000000000001', 'TEXTE',
   'À Niort comme à Mulhouse, le scénario se répète : la chorale, le club de randonnée ou le comité des fêtes annonce sa dissolution, non par manque d''adhérents, mais faute de candidat à la présidence. Le paradoxe mérite d''être souligné : les associations françaises n''ont jamais rassemblé autant de membres, et jamais eu autant de mal à trouver ceux qui acceptent de les diriger.

Les raisons de cette désaffection sont connues. Présider, c''est engager sa responsabilité personnelle devant la loi, passer ses soirées à remplir des dossiers de subvention, répondre seul des comptes devant l''assemblée. Beaucoup de bénévoles, prêts à donner un samedi pour organiser un tournoi, reculent devant un engagement qui ressemble à un second métier — sans le salaire.

Certains y voient la preuve d''un individualisme croissant. Le diagnostic est paresseux : on ne refuse pas de s''engager, on refuse une fonction devenue écrasante. Plutôt que de déplorer l''air du temps, mieux vaudrait alléger la charge : direction collégiale, présidences tournantes, mutualisation de la gestion entre plusieurs structures. Des solutions existent, déjà expérimentées avec succès dans plusieurs départements. Le bénévolat ne manque pas de bras ; il manque d''épaules sur lesquelles on n''empile pas tout.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c010-4000-0000-000000000002', 'TEXTE',
   'Quand on interroge les responsables associatifs sur leurs difficultés, la réponse fuse : l''argent. La réalité est plus subtile. Selon une étude du cabinet Solivia portant sur quatre mille structures, les financements publics versés au secteur n''ont globalement pas diminué depuis dix ans. Ce qui a changé, c''est leur forme : la subvention de fonctionnement, versée chaque année pour soutenir l''activité d''ensemble, cède partout la place à l''appel à projets, qui finance une action précise, limitée dans le temps, choisie par le financeur.

Le glissement paraît technique ; il bouleverse tout. Les associations passent désormais des semaines à rédiger des dossiers, en concurrence les unes avec les autres, sans certitude de reconduction d''une année sur l''autre. Impossible, dans ces conditions, de salarier durablement, de louer un local, de construire un projet de long terme. Surtout, la logique s''inverse : ce n''est plus l''association qui définit sa mission et cherche des soutiens, c''est le financeur qui fixe ses priorités et sélectionne des exécutants.

Des collectivités commencent à revenir à des conventions pluriannuelles, conscientes d''avoir fragilisé ce qu''elles voulaient piloter. Le mouvement reste timide. Tant qu''il ne s''amplifiera pas, le monde associatif continuera de s''épuiser à courir après des financements qui le détournent de sa raison d''être.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c010-4000-0000-000000000003', 'TEXTE',
   '« Les jeunes ne s''engagent plus. » La phrase revient dans chaque assemblée générale, prononcée avec un soupir par des dirigeants vieillissants qui peinent à renouveler leurs rangs. Les enquêtes disent pourtant autre chose. Selon le baromètre annuel de l''institut Verdier, les jeunes de moins de trente ans déclarent davantage d''activités bénévoles qu''il y a quinze ans. Simplement, ils s''engagent autrement.

Prendre une carte, siéger au conseil d''administration, tenir la buvette tous les dimanches pendant vingt ans : ce modèle de fidélité ne fait plus recette, c''est exact. Les jeunes bénévoles préfèrent les missions courtes, concrètes, dont ils voient le résultat — une maraude, un chantier de rénovation, une collecte. Ils s''attachent à une cause plus qu''à une structure, et n''hésitent pas à passer de l''une à l''autre.

On peut déplorer cette volatilité ; on peut aussi y lire une exigence. Ces bénévoles intermittents demandent aux associations ce que les adhérents d''hier ne demandaient pas : du sens, de l''efficacité, de la souplesse. Les structures qui l''ont compris — missions à la carte, engagement sans adhésion, responsabilités partagées — ne connaissent aucune pénurie. Les autres confondent la crise de leur modèle avec une crise de la jeunesse. Ce n''est pas la même chose, et le reconnaître serait déjà un progrès.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c010-4000-0000-000000000004', 'TEXTE',
   'L''association Trait d''Union, qui accompagne des personnes isolées à Besançon, vient de recruter son sixième salarié. Personne ne s''en plaint : les financeurs exigent des comptes rendus professionnels, les publics accompagnés ont besoin de compétences que la bonne volonté ne remplace pas. Le secteur associatif emploie aujourd''hui près de deux millions de personnes, et cette professionnalisation a incontestablement élevé la qualité des actions menées.

Elle a aussi un coût, rarement mesuré : la place des bénévoles. Dans bien des structures, ceux qui faisaient vivre le projet se retrouvent cantonnés aux tâches que les salariés n''ont pas le temps d''assurer — distribuer des tracts, tenir un stand, ranger la salle. Les décisions, elles, se prennent désormais entre permanents, au fil de réunions tenues en journée, quand les bénévoles travaillent. Beaucoup s''éloignent sur la pointe des pieds, avec le sentiment confus d''être devenus les supplétifs d''un projet qui fut le leur.

Le problème n''est pas la salarisation, qui restera nécessaire. Le problème est qu''aucune réflexion n''accompagne, dans la plupart des structures, la redistribution des rôles qu''elle provoque. Une association n''est pas une entreprise dotée de bénévoles d''appoint : si elle cesse d''être gouvernée par ses membres, elle perd ce qui la distingue — et ce qui la justifie.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c010-4000-0000-000000000005', 'TEXTE',
   'Le « mécénat de compétences » a le vent en poupe : des entreprises mettent leurs salariés à disposition d''associations, quelques heures ou plusieurs mois, sur leur temps de travail. Un informaticien refond le site d''une banque alimentaire, une juriste sécurise les contrats d''un club sportif, des équipes entières repeignent un centre d''hébergement le temps d''une « journée solidaire ». Pour des structures qui manquent de tout, l''apport est réel, et il serait absurde de le bouder.

Il serait tout aussi naïf de n''y voir que de la générosité. Ces dispositifs ouvrent droit à des réductions fiscales substantielles, nourrissent la communication des entreprises et figurent en bonne place dans leurs rapports annuels. Rien d''illégitime à cela — mais l''équilibre est fragile. Certaines associations racontent des « journées solidaires » conçues d''abord pour la photo, où l''accueil des volontaires d''un jour mobilise plus d''énergie qu''il n''en apporte. D''autres s''inquiètent de voir leur programmation dépendre des thèmes que les mécènes acceptent de soutenir.

La règle devrait être simple : c''est à l''association de définir ses besoins, à l''entreprise de s''y ajuster, et non l''inverse. Tant que cette hiérarchie est respectée, le mécénat de compétences enrichit tout le monde. Quand elle s''inverse, le monde associatif devient un décor — et il a mieux à faire.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c010-4000-0000-000000000006', 'TEXTE',
   'Quinze présents pour quatre cents adhérents : l''assemblée générale du club nautique de Lorient, en mars dernier, n''a rien d''une exception. Partout, ces réunions statutaires se tiennent devant des chaises vides, expédiées en une heure entre le rapport moral et le verre de l''amitié. On en sourit, on s''en accommode. On a tort.

Car l''assemblée générale n''est pas une formalité : c''est l''organe qui fonde la légitimité de tout ce que fait une association. Quand plus personne n''y vient, les décisions se concentrent entre les mains d''un noyau de fidèles, toujours les mêmes, qui finissent par confondre la structure avec leur propre histoire. Les orientations ne sont plus débattues mais entérinées ; les comptes, approuvés sans être lus. Le jour où surgit un désaccord — un projet contesté, une cotisation augmentée —, il explose d''autant plus violemment qu''aucun espace n''existait pour l''exprimer.

Certaines associations ont pris le problème au sérieux : consultations en amont, ateliers thématiques ouverts à tous, votes organisés sur plusieurs jours pour ceux qui ne peuvent se déplacer. Leurs assemblées ne font pas le plein pour autant, mais leurs membres savent que leur avis compte. C''est exactement l''enjeu : non pas remplir une salle un soir de mars, mais faire vivre, le reste de l''année, la démocratie dont l''assemblée n''est que le rendez-vous final.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c010-4000-0000-000000000007', 'TEXTE',
   'Gérer un budget de quarante mille euros, encadrer une équipe de vingt personnes, négocier avec une mairie, organiser un événement pour six cents participants : ces lignes pourraient figurer dans le profil d''un cadre expérimenté. Elles décrivent le quotidien d''Awa, trente-deux ans, trésorière bénévole d''une association d''aide aux devoirs à Saint-Étienne — et n''apparaissent nulle part sur son CV.

Le cas est si répandu qu''il en devient invisible. Des centaines de milliers de bénévoles acquièrent, dans leurs associations, des compétences que les entreprises s''arrachent : conduite de projet, prise de parole, gestion de crise, comptabilité. Mais faute de mots pour les nommer et de cadres pour les certifier, ces savoir-faire restent lettre morte au moment de chercher un emploi. Les dispositifs existent pourtant — portefeuilles de compétences, validation des acquis de l''expérience, comptes d''engagement —, si méconnus que leurs bénéficiaires se comptent en milliers quand les bénévoles se comptent en millions.

Il ne s''agit pas de transformer le bénévolat en tremplin de carrière : on s''engage d''abord pour une cause, et c''est très bien ainsi. Il s''agit de cesser de regarder comme un simple loisir ce qui constitue, pour beaucoup, la première école de responsabilité. Le jour où un recruteur lira une présidence d''association comme il lit une expérience professionnelle, personne n''y perdra — et beaucoup y gagneront.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c010-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c010-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale défendue par l''auteur ?',
   'L''auteur conclut : « Le bénévolat ne manque pas de bras ; il manque d''épaules sur lesquelles on n''empile pas tout », après avoir proposé direction collégiale et présidences tournantes. **L''idée principale est qu''il faut alléger et partager la charge dirigeante.** La réponse A inverse un détail explicite : les associations n''ont « jamais rassemblé autant de membres ». La réponse C reprend une explication que l''auteur qualifie de « diagnostic paresseux » — c''est l''opinion réfutée, pas la thèse. La réponse D sur-étend la formule « un second métier — sans le salaire », qui décrit la lourdeur de la fonction sans réclamer de rémunération. Mécanisme : distinguer la **thèse défendue** de l''opinion adverse rapportée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c010-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c010-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur le financement des associations ?',
   'Le texte affirme que les financements « n''ont globalement pas diminué » et que « ce qui a changé, c''est leur forme » : **la cause centrale est le remplacement de la subvention de fonctionnement par l''appel à projets**, que la bonne réponse reformule. La réponse A contredit ce constat explicite sur les montants. La réponse B inverse les faits : les associations « passent des semaines à rédiger des dossiers », elles répondent donc massivement. La réponse C sur-généralise un détail final : « des collectivités commencent » à revenir aux conventions, et « le mouvement reste timide ». Mécanisme : **inférence de la cause principale** contre une explication évidente mais fausse (la baisse des moyens).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c010-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c010-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur à l''égard de l''engagement bénévole des jeunes ?',
   'L''auteur oppose au soupir des dirigeants les données du baromètre (« davantage d''activités bénévoles qu''il y a quinze ans ») et conclut que certains « confondent la crise de leur modèle avec une crise de la jeunesse ». **Sa position : pas de désengagement, mais une mutation des formes d''engagement.** La réponse B contredit les chiffres cités. La réponse C inverse le sens du texte : c''est aux structures de s''adapter (« missions à la carte »), pas aux jeunes de revenir en arrière. La réponse D sur-généralise : les associations qui se sont adaptées « ne connaissent aucune pénurie ». Mécanisme : repérer le **renversement argumentatif** (opinion commune citée puis réfutée par les faits).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c010-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c010-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'L''auteur pose que « le problème n''est pas la salarisation, qui restera nécessaire », mais l''absence de réflexion sur « la redistribution des rôles qu''elle provoque » : **l''idée principale articule l''utilité de la professionnalisation et la marginalisation des bénévoles qu''elle entraîne**. La réponse A contredit cette concession explicite en faveur des salariés. La réponse B inverse les faits : les bénévoles sont précisément cantonnés aux tâches matérielles, ils ne les refusent pas. La réponse D inverse un détail : la professionnalisation a « incontestablement élevé la qualité des actions ». Mécanisme : saisir une **thèse en deux temps** (concession + critique) et résister aux distracteurs en inversion.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c010-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c010-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Quel regard l''auteur porte-t-il sur le mécénat de compétences ?',
   'L''auteur juge « l''apport réel » et estime qu''« il serait absurde de le bouder », avant d''avertir qu''« il serait tout aussi naïf de n''y voir que de la générosité » : **un regard nuancé, entre reconnaissance de l''utilité et vigilance sur les dérives** (journées conçues « pour la photo », programmation dépendante des mécènes). La réponse A sur-généralise la critique et nie l''apport pourtant reconnu. La réponse C déforme le texte : « rien d''illégitime à cela », les avantages fiscaux sont parfaitement légaux. La réponse D inverse la règle finale : c''est « à l''entreprise de s''y ajuster, et non l''inverse ». Mécanisme : le **double mouvement concessif** signale un ton mesuré, ni enthousiasme béat ni rejet.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c010-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c010-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Que cherche à montrer l''auteur de ce texte ?',
   'Le texte affirme que l''assemblée « n''est pas une formalité » mais « l''organe qui fonde la légitimité » de l''association, et conclut qu''il faut « faire vivre, le reste de l''année, la démocratie » : **la bonne réponse relie le constat des salles vides à l''enjeu démocratique de fond**. La réponse A contredit frontalement la thèse de l''auteur. La réponse B déforme un détail : les assemblées des associations réformées « ne font pas le plein pour autant ». La réponse C promeut un **détail vrai mais secondaire** (la cotisation n''est qu''un exemple de désaccord) au rang de cause principale. Mécanisme : **inférence globale** — relier le constat initial à la conclusion, contre des distracteurs littéraux.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c010-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c010-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Quelle est l''intention principale de l''auteur ?',
   'Tout le texte converge vers la chute : « Le jour où un recruteur lira une présidence d''association comme il lit une expérience professionnelle, personne n''y perdra ». **L''intention est de plaider pour la reconnaissance des compétences acquises dans le bénévolat**, illustrée par le cas d''Awa. La réponse B contredit la précaution explicite : « on s''engage d''abord pour une cause, et c''est très bien ainsi ». La réponse C inverse le chiffre piège : les bénéficiaires des dispositifs « se comptent en milliers quand les bénévoles se comptent en millions ». La réponse D inverse le propos : ces compétences sont celles « que les entreprises s''arrachent ». Mécanisme : **inférence d''intention** à partir de l''exemple d''ouverture et de la conclusion.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — pénurie de dirigeants bénévoles (bonne réponse : position 2)
  ('11111111-c010-2100-0000-000000000001', '11111111-c010-1000-0000-000000000001',
   'Les Français adhèrent de moins en moins aux associations',
   'false', '1'),

  ('11111111-c010-2200-0000-000000000001', '11111111-c010-1000-0000-000000000001',
   'C''est le poids de la fonction dirigeante qu''il faut alléger pour sauver les associations',
   'true', '2'),

  ('11111111-c010-2300-0000-000000000001', '11111111-c010-1000-0000-000000000001',
   'La montée de l''individualisme explique la disparition des clubs et des comités',
   'false', '3'),

  ('11111111-c010-2400-0000-000000000001', '11111111-c010-1000-0000-000000000001',
   'Les présidents d''association devraient recevoir un salaire pour leur engagement',
   'false', '4'),

  -- item 02 — financement par appels à projets (bonne réponse : position 4)
  ('11111111-c010-2100-0000-000000000002', '11111111-c010-1000-0000-000000000002',
   'Les financements publics versés aux associations ont fortement chuté depuis dix ans',
   'false', '1'),

  ('11111111-c010-2200-0000-000000000002', '11111111-c010-1000-0000-000000000002',
   'Les associations refusent désormais de répondre aux appels à projets des financeurs',
   'false', '2'),

  ('11111111-c010-2300-0000-000000000002', '11111111-c010-1000-0000-000000000002',
   'La plupart des collectivités sont déjà revenues aux conventions pluriannuelles',
   'false', '3'),

  ('11111111-c010-2400-0000-000000000002', '11111111-c010-1000-0000-000000000002',
   'C''est le passage de la subvention à l''appel à projets qui fragilise les associations',
   'true', '4'),

  -- item 03 — engagement des jeunes (bonne réponse : position 1)
  ('11111111-c010-2100-0000-000000000003', '11111111-c010-1000-0000-000000000003',
   'Il conteste l''idée d''un désengagement : les jeunes s''engagent autant, mais sous d''autres formes',
   'true', '1'),

  ('11111111-c010-2200-0000-000000000003', '11111111-c010-1000-0000-000000000003',
   'Il regrette que les jeunes refusent aujourd''hui toute forme de bénévolat',
   'false', '2'),

  ('11111111-c010-2300-0000-000000000003', '11111111-c010-1000-0000-000000000003',
   'Il invite les jeunes à revenir au modèle de l''adhésion fidèle et durable',
   'false', '3'),

  ('11111111-c010-2400-0000-000000000003', '11111111-c010-1000-0000-000000000003',
   'Il estime que la volatilité des jeunes bénévoles condamne les associations à disparaître',
   'false', '4'),

  -- item 04 — professionnalisation et place des bénévoles (bonne réponse : position 3)
  ('11111111-c010-2100-0000-000000000004', '11111111-c010-1000-0000-000000000004',
   'L''auteur appelle les associations à renoncer à l''embauche de salariés',
   'false', '1'),

  ('11111111-c010-2200-0000-000000000004', '11111111-c010-1000-0000-000000000004',
   'Les bénévoles refusent désormais d''assumer les tâches matérielles des associations',
   'false', '2'),

  ('11111111-c010-2300-0000-000000000004', '11111111-c010-1000-0000-000000000004',
   'La professionnalisation, utile, marginalise les bénévoles faute d''une réflexion sur leur place',
   'true', '3'),

  ('11111111-c010-2400-0000-000000000004', '11111111-c010-1000-0000-000000000004',
   'La qualité des actions associatives a baissé depuis l''arrivée des salariés',
   'false', '4'),

  -- item 05 — mécénat de compétences (bonne réponse : position 2)
  ('11111111-c010-2100-0000-000000000005', '11111111-c010-1000-0000-000000000005',
   'Il y voit une opération de communication sans aucun bénéfice pour les associations',
   'false', '1'),

  ('11111111-c010-2200-0000-000000000005', '11111111-c010-1000-0000-000000000005',
   'Il en reconnaît l''utilité réelle tout en mettant en garde contre ses dérives',
   'true', '2'),

  ('11111111-c010-2300-0000-000000000005', '11111111-c010-1000-0000-000000000005',
   'Il dénonce l''illégalité des avantages fiscaux accordés aux entreprises mécènes',
   'false', '3'),

  ('11111111-c010-2400-0000-000000000005', '11111111-c010-1000-0000-000000000005',
   'Il invite les associations à adapter leurs projets aux priorités des entreprises',
   'false', '4'),

  -- item 06 — assemblées générales désertées (bonne réponse : position 4)
  ('11111111-c010-2100-0000-000000000006', '11111111-c010-1000-0000-000000000006',
   'Les assemblées générales sont des formalités dont les associations pourraient se passer',
   'false', '1'),

  ('11111111-c010-2200-0000-000000000006', '11111111-c010-1000-0000-000000000006',
   'Les associations qui ont réformé leurs pratiques remplissent désormais leurs salles',
   'false', '2'),

  ('11111111-c010-2300-0000-000000000006', '11111111-c010-1000-0000-000000000006',
   'Les conflits internes naissent principalement des hausses de cotisation',
   'false', '3'),

  ('11111111-c010-2400-0000-000000000006', '11111111-c010-1000-0000-000000000006',
   'La désertion des assemblées mine la démocratie associative, qu''il faut faire vivre toute l''année',
   'true', '4'),

  -- item 07 — reconnaissance des compétences bénévoles (bonne réponse : position 1)
  ('11111111-c010-2100-0000-000000000007', '11111111-c010-1000-0000-000000000007',
   'Plaider pour une vraie reconnaissance des compétences acquises dans le bénévolat',
   'true', '1'),

  ('11111111-c010-2200-0000-000000000007', '11111111-c010-1000-0000-000000000007',
   'Encourager les jeunes à s''engager d''abord pour enrichir leur CV',
   'false', '2'),

  ('11111111-c010-2300-0000-000000000007', '11111111-c010-1000-0000-000000000007',
   'Montrer que les dispositifs de validation profitent déjà à des millions de bénévoles',
   'false', '3'),

  ('11111111-c010-2400-0000-000000000007', '11111111-c010-1000-0000-000000000007',
   'Démontrer que les compétences associatives valent moins que celles acquises en entreprise',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c010-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « vie associative », 7 angles tous différents :
--     pénurie de dirigeants bénévoles / financement par appels à projets /
--     engagement des jeunes bénévoles / professionnalisation et place des
--     bénévoles / mécénat de compétences / assemblées générales désertées /
--     reconnaissance des compétences bénévoles. Aucun thème interdit.
-- [x] Textes B2 longs : 191 / 201 / 202 / 201 / 202 / 210 / 211 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (ex. « jamais autant de membres », « le mouvement reste timide »,
--     « ne font pas le plein pour autant », « milliers vs millions »).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2, ce_inference_intention ×3,
--     ce_ton_auteur ×2.
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme linguistique
--     nommé (concession, renversement argumentatif, inversion cause/effet,
--     détail secondaire, sur-généralisation, inférence d'intention).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (prénoms, villes, chiffres,
--     instituts inventés : Solivia, Verdier, Trait d'Union, Awa…).
-- ============================================================================
