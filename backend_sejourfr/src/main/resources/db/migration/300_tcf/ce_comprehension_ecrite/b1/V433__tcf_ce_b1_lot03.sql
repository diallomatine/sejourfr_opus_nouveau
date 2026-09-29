-- ============================================================================
-- V433 — TCF CE B1 — lot 03 (support : article informatif court)
-- ----------------------------------------------------------------------------
-- 10 items de compréhension écrite B1. Support unique : article informatif
-- court de presse locale (atelier de réparation, prêt d''instruments en
-- médiathèque, navette gratuite vers le marché, paniers d''invendus en
-- boulangerie, cours de natation pour adultes, épicerie de village financée
-- par les habitants, jardin partagé sur un ancien parking, étude sur le vélo,
-- nocturne au musée, collecte des déchets alimentaires). Passages TEXTE
-- (~60-120 mots), questions + choices (4 rows/question). theme_id =
-- 22222222-0000-0000-0000-000000000002, difficulty='B1', question_type='CE'.
-- Données déterministes, rejouables dev+recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-b003-4000-0000-000000000001', 'TEXTE',
   'LYON — Réparer plutôt que jeter

Depuis samedi, la maison de quartier des Tilleuls accueille un atelier de réparation gratuit, chaque premier samedi du mois. Grille-pain, lampes, vélos : des bénévoles aident les habitants à remettre en état leurs objets en panne au lieu de les jeter. « Huit objets sur dix repartent réparés », se réjouit Amadou Sow, l''un des fondateurs. Attention, les bénévoles ne réparent pas à la place des visiteurs : chacun apprend à le faire lui-même, outils fournis sur place. Seule condition pour participer : s''inscrire la veille sur le site de la mairie, car le nombre de places est limité à vingt personnes par séance.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b003-4000-0000-000000000002', 'TEXTE',
   'NANTES — À la médiathèque, on emprunte aussi des guitares

La médiathèque Jacques-Brel ne prête plus seulement des livres. Depuis le 1er mars, ses abonnés peuvent emprunter gratuitement une guitare, un ukulélé ou un clavier pour un mois, renouvelable une fois. L''initiative vise ceux qui hésitent à acheter un instrument sans savoir si la musique leur plaira vraiment. « On veut permettre d''essayer sans dépenser », explique la directrice, Lucia Fernandes. Vingt instruments sont disponibles et la réservation se fait uniquement à l''accueil, sur place. Les cours, en revanche, ne sont pas assurés : la médiathèque fournit simplement une liste de professeurs du quartier.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b003-4000-0000-000000000003', 'TEXTE',
   'PERPIGNAN — Une navette gratuite vers le marché

À partir de lundi, une navette gratuite reliera deux matinées par semaine, le mardi et le samedi, les quartiers nord au marché couvert du centre-ville. Elle est réservée aux habitants de plus de 65 ans ; aucune inscription n''est demandée, il suffit de monter à bord. La mairie a créé ce service après avoir constaté que de nombreuses personnes âgées, qui ne conduisent plus, renonçaient à faire leurs courses elles-mêmes. « Avant, je dépendais de ma fille pour chaque sortie », raconte Wei Zhang, 72 ans, déjà conquise. Quatre arrêts sont prévus le long du parcours.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b003-4000-0000-000000000004', 'TEXTE',
   'TOULOUSE — Des paniers surprise contre le gaspillage

La boulangerie du Capitole vend désormais chaque soir, à partir de 19 h, des paniers composés de ses invendus de la journée : pains, viennoiseries, parfois quelques sandwichs. Prix unique : 3 euros, pour une valeur réelle d''une dizaine d''euros. Particularité : impossible de choisir le contenu, qui dépend de ce qui reste en rayon. Les paniers se réservent dans la journée sur une application et se retirent avant la fermeture, à 19 h 30. « Je ne jette presque plus rien », se félicite le gérant, Rachid Benali, qui préparait jusqu''à dix paniers par soir cet hiver.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b003-4000-0000-000000000005', 'TEXTE',
   'BESANÇON — Apprendre à nager à l''âge adulte

En France, environ un adulte sur sept ne sait pas nager. Pour y remédier, la piscine municipale Mallarmé organise cet été des cours gratuits réservés aux adultes débutants : huit séances en juillet, en petits groupes de six, encadrées par des maîtres-nageurs. Les stages pour enfants, eux, continuent comme chaque année et restent payants. Les inscriptions ouvrent le 15 juin à l''accueil de la piscine ; un certificat médical est demandé. « J''ai quarante ans et je n''avais jamais osé me lancer », confie Olena Kovalenko, déjà inscrite. Si la demande est forte, une session sera ajoutée en août.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b003-4000-0000-000000000006', 'TEXTE',
   'SAINT-JULIEN (Cantal) — Le village retrouve son épicerie

Fermée depuis deux ans, la dernière boutique du village a rouvert samedi matin sous les applaudissements. Pour financer le projet, 180 habitants ont acheté des parts du commerce, entre 50 et 500 euros chacun, réunissant ainsi la somme nécessaire aux travaux et au premier stock. La gérante, Fatou Diallo, servait déjà ses premiers clients à 8 h. Le magasin proposera des produits locaux, un dépôt de pain et un point poste, des services disparus du village depuis longtemps. La mairie, elle, s''est contentée de prêter le local pour un loyer symbolique d''un euro par mois.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b003-4000-0000-000000000007', 'TEXTE',
   'ROUBAIX — Des légumes à la place des voitures

L''ancien parking de la rue des Fauvettes a été transformé ce printemps en jardin partagé de quarante parcelles. Chaque famille du quartier peut en louer une pour 20 euros par an, eau et outils compris. Le succès dépasse toutes les prévisions : plus de cent demandes sont déjà arrivées en mairie. Les dix parcelles encore libres seront donc attribuées par tirage au sort, le 12 mai, parmi les candidatures déposées avant la fin du mois d''avril. « J''ai enfin un coin de terre pour mes tomates », sourit Diego Morales, l''un des premiers servis.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b003-4000-0000-000000000008', 'TEXTE',
   'GRENOBLE — Le vélo gagne du terrain

Selon une étude publiée mardi par l''observatoire des mobilités, le nombre de trajets quotidiens à vélo a augmenté de 30 % en deux ans dans l''agglomération. La nouvelle piste qui longe l''Isère, ouverte en 2024, explique en grande partie cette progression : séparée de la circulation automobile, elle rassure les cyclistes débutants. L''étude pointe cependant un problème persistant : le manque de stationnements sécurisés près des gares, où les vols de vélos restent nombreux. La métropole promet 500 arceaux supplémentaires d''ici l''an prochain. « Je n''osais pas rouler au milieu des voitures ; maintenant, je viens travailler à vélo tous les jours », témoigne Priya Sharma.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b003-4000-0000-000000000009', 'TEXTE',
   'AMIENS — Le musée ouvre ses portes en soirée

Le musée des Beaux-Arts reste désormais ouvert jusqu''à 22 h chaque jeudi, avec entrée gratuite à partir de 18 h. Cette nocturne, testée pendant six mois, vise un public précis : les personnes qui travaillent en journée et renoncent souvent à venir. Selon le directeur, Marek Nowak, la moitié des visiteurs interrogés citaient les horaires comme premier obstacle, loin devant le prix du billet. Les premiers résultats sont encourageants : six cents visiteurs jeudi dernier, soit deux fois plus qu''un jeudi ordinaire. Si l''essai est concluant, une seconde soirée pourrait être ajoutée le mardi à la rentrée.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b003-4000-0000-00000000000a', 'TEXTE',
   'TOURS — Les déchets alimentaires auront leur poubelle

À partir du 1er septembre, des bornes marron réservées aux déchets alimentaires seront installées dans toutes les rues de la ville, à côté des conteneurs habituels. Épluchures, restes de repas, coquilles d''œufs : ces déchets, qui représentent un tiers de nos poubelles, ne seront plus incinérés mais transformés en compost pour les agriculteurs de la région. Chaque foyer pourra retirer gratuitement un petit seau de cuisine en mairie, sur présentation d''un justificatif de domicile. « Brûler des épluchures, composées surtout d''eau, n''a aucun sens », résume Aïcha Traoré, responsable du service propreté. Des réunions d''information sont prévues dans chaque quartier en août.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-b003-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b003-4000-0000-000000000001',
   NULL, 'B1', 'CE',
   'Que doit faire un habitant pour participer à l''atelier ?',
   'L''article précise : « Seule condition pour participer : s''inscrire la veille sur le site de la mairie ». C''est un **repérage explicite de la condition d''accès**, annoncée par la formule restrictive « seule condition ». La réponse A contredit le texte : les outils sont « fournis sur place », inutile d''apporter les siens. La réponse C est fausse car l''atelier est « gratuit » dès la première phrase. La réponse D déforme le principe même du lieu : « les bénévoles ne réparent pas à la place des visiteurs : chacun apprend à le faire lui-même » — le piège consiste à confondre un **service de réparation** avec un atelier d''apprentissage.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b003-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b003-4000-0000-000000000002',
   NULL, 'B1', 'CE',
   'Que propose désormais la médiathèque à ses abonnés ?',
   'Le texte annonce que les abonnés « peuvent emprunter gratuitement une guitare, un ukulélé ou un clavier pour un mois ». La bonne réponse est une **reformulation de ce prêt gratuit d''instruments**. La réponse A confond deux informations proches : la médiathèque « fournit simplement une liste de professeurs », mais « les cours ne sont pas assurés » par elle. La réponse B confond emprunter et acheter : rien n''est vendu, le but est justement d''« essayer sans dépenser ». La réponse C contredit la gratuité explicite du dispositif (« emprunter **gratuitement** ») — le piège joue sur la confusion entre prêt gratuit et location payante.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b003-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b003-4000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Pourquoi la mairie a-t-elle créé cette navette ?',
   'Par **inférence d''intention**, on relie deux informations : la navette est « réservée aux habitants de plus de 65 ans » et la mairie a constaté que « de nombreuses personnes âgées, qui ne conduisent plus, renonçaient à faire leurs courses elles-mêmes ». Le but est donc d''aider ces personnes à rejoindre le marché sans voiture. La réponse B est plausible thématiquement (un bus réduit le trafic) mais cette motivation n''apparaît nulle part dans l''article. La réponse C invente une suppression de ligne jamais mentionnée. La réponse D contredit le public visé : le service est « réservé aux habitants », pas destiné aux touristes.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b003-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b003-4000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Quelle est la particularité des paniers vendus par cette boulangerie ?',
   'L''article l''annonce avec le mot « Particularité : impossible de choisir le contenu, qui dépend de ce qui reste en rayon ». La bonne réponse **reformule cette absence de choix**, qui justifie le nom de « paniers surprise ». La réponse A réduit le contenu aux pains alors que le texte cite aussi « viennoiseries, parfois quelques sandwichs ». La réponse B confond prix réduit et gratuité : les paniers sont « vendus » 3 euros, ils ne sont offerts à personne. La réponse D inverse le moment du retrait : les paniers se retirent **le soir** « avant la fermeture, à 19 h 30 » — piège classique de confusion entre deux informations temporelles proches.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b003-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b003-4000-0000-000000000005',
   NULL, 'B1', 'CE',
   'À qui s''adressent les cours de natation gratuits ?',
   'Le texte indique que les cours gratuits sont « réservés aux adultes débutants », en écho au constat initial : « un adulte sur sept ne sait pas nager ». C''est un **repérage explicite du public visé**, marqué par le participe restrictif « réservés ». La réponse A confond deux dispositifs voisins : les stages pour enfants existent, mais ils « restent payants ». La réponse C contredit la restriction du texte : les cours ne s''adressent ni à tous les habitants ni à tous les niveaux. La réponse D inverse les rôles : les maîtres-nageurs « encadrent » les séances, ils ne sont pas le public des cours.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b003-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b003-4000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Comment la réouverture de l''épicerie a-t-elle été possible ?',
   'Par **inférence simple**, on relie « Pour financer le projet, 180 habitants ont acheté des parts du commerce » et « réunissant ainsi la somme nécessaire » : c''est l''argent investi par les villageois qui a permis la réouverture. La réponse A surinterprète le rôle de la mairie : elle « s''est contentée de prêter le local » pour un euro par mois, ce n''est pas une subvention qui finance travaux et stock — piège de confusion entre **deux aides de nature différente**. La réponse B invente un prêt bancaire absent du texte. La réponse C contredit l''esprit du projet : c''est un commerce de village tenu par une gérante, aucune chaîne n''intervient.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b003-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b003-4000-0000-000000000007',
   NULL, 'B1', 'CE',
   'Comment les dernières parcelles du jardin seront-elles attribuées ?',
   'L''article précise : « Les dix parcelles encore libres seront donc attribuées par tirage au sort, le 12 mai, parmi les candidatures déposées avant la fin du mois d''avril ». C''est un **repérage explicite du mode d''attribution**, introduit par le connecteur de conséquence « donc » (la demande dépasse l''offre, d''où le tirage). La réponse B décrit la règle inverse : si l''ordre d''arrivée comptait, le tirage au sort serait inutile. La réponse C contredit le tarif unique : la location coûte « 20 euros par an » pour tous, aucune enchère n''existe. La réponse D invente un vote des jardiniers que le texte ne mentionne jamais.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b003-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b003-4000-0000-000000000008',
   NULL, 'B1', 'CE',
   'Qu''apprend-on dans cet article ?',
   'La bonne réponse **reformule l''idée centrale** : les trajets à vélo « ont augmenté de 30 % en deux ans » et la nouvelle piste « explique en grande partie cette progression » car, « séparée de la circulation automobile, elle rassure les cyclistes débutants ». La réponse A inverse une information : les vols « restent nombreux » près des gares, ils n''ont pas diminué. La réponse B se trompe de temps : la piste est déjà « ouverte en 2024 » — le piège joue sur la confusion entre un fait accompli et la promesse des « 500 arceaux d''ici l''an prochain ». La réponse D inverse le sens de cette promesse : la métropole **ajoute** des stationnements, elle n''en supprime pas.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b003-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b003-4000-0000-000000000009',
   NULL, 'B1', 'CE',
   'Pourquoi le musée a-t-il créé cette nocturne du jeudi ?',
   'Le texte énonce le but : la nocturne « vise un public précis : les personnes qui travaillent en journée et renoncent souvent à venir ». C''est une **inférence d''intention** confirmée par l''enquête citée : « la moitié des visiteurs interrogés citaient les horaires comme premier obstacle ». La réponse A prend le **détail secondaire** pour la cause principale : le prix arrive « loin devant » derrière les horaires — c''est précisément l''obstacle écarté par le texte. La réponse C invente une suppression : la soirée du mardi serait « ajoutée », rien n''est remplacé. La réponse D contredit les chiffres : la nocturne attire deux fois plus de monde, le problème n''était pas une fréquentation excessive.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b003-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b003-4000-0000-00000000000a',
   NULL, 'B1', 'CE',
   'Pourquoi la ville installe-t-elle ces bornes marron ?',
   'Par **inférence de but**, on comprend l''objectif de la mesure : les déchets alimentaires « ne seront plus incinérés mais transformés en compost pour les agriculteurs de la région » — l''opposition « ne… plus… mais » marque le remplacement d''une pratique par une autre. La citation d''Aïcha Traoré (« Brûler des épluchures… n''a aucun sens ») confirme cette intention. La réponse A inverse la logique : les bornes s''**ajoutent** « à côté des conteneurs habituels », rien n''est retiré. La réponse B contredit la gratuité du dispositif : le seau est remis « gratuitement » en mairie. La réponse C déforme le destinataire du compost : il est destiné aux agriculteurs, pas vendu aux habitants.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- Q01 — atelier de réparation à Lyon (bonne réponse : position 2)
  ('11111111-b003-2100-0000-000000000001', '11111111-b003-1000-0000-000000000001',
   'Apporter ses propres outils de réparation',
   'false', '1'),
  ('11111111-b003-2200-0000-000000000001', '11111111-b003-1000-0000-000000000001',
   'S''inscrire la veille sur le site de la mairie',
   'true', '2'),
  ('11111111-b003-2300-0000-000000000001', '11111111-b003-1000-0000-000000000001',
   'Payer une petite participation à l''entrée',
   'false', '3'),
  ('11111111-b003-2400-0000-000000000001', '11111111-b003-1000-0000-000000000001',
   'Déposer son objet et revenir le chercher réparé',
   'false', '4'),

  -- Q02 — instruments à la médiathèque de Nantes (bonne réponse : position 4)
  ('11111111-b003-2100-0000-000000000002', '11111111-b003-1000-0000-000000000002',
   'Des cours de musique donnés par des professeurs du quartier',
   'false', '1'),
  ('11111111-b003-2200-0000-000000000002', '11111111-b003-1000-0000-000000000002',
   'La vente de guitares et de claviers d''occasion',
   'false', '2'),
  ('11111111-b003-2300-0000-000000000002', '11111111-b003-1000-0000-000000000002',
   'La location d''instruments pour une petite somme',
   'false', '3'),
  ('11111111-b003-2400-0000-000000000002', '11111111-b003-1000-0000-000000000002',
   'Le prêt gratuit d''instruments de musique pendant un mois',
   'true', '4'),

  -- Q03 — navette vers le marché à Perpignan (bonne réponse : position 1)
  ('11111111-b003-2100-0000-000000000003', '11111111-b003-1000-0000-000000000003',
   'Pour aider les personnes âgées à faire leurs courses sans voiture',
   'true', '1'),
  ('11111111-b003-2200-0000-000000000003', '11111111-b003-1000-0000-000000000003',
   'Pour réduire la circulation dans le centre-ville le samedi',
   'false', '2'),
  ('11111111-b003-2300-0000-000000000003', '11111111-b003-1000-0000-000000000003',
   'Pour remplacer une ligne de bus récemment supprimée',
   'false', '3'),
  ('11111111-b003-2400-0000-000000000003', '11111111-b003-1000-0000-000000000003',
   'Pour faire découvrir le marché couvert aux touristes',
   'false', '4'),

  -- Q04 — paniers surprise de la boulangerie de Toulouse (bonne réponse : position 3)
  ('11111111-b003-2100-0000-000000000004', '11111111-b003-1000-0000-000000000004',
   'Ils sont composés uniquement de pains de la journée',
   'false', '1'),
  ('11111111-b003-2200-0000-000000000004', '11111111-b003-1000-0000-000000000004',
   'Ils sont offerts aux clients les plus fidèles',
   'false', '2'),
  ('11111111-b003-2300-0000-000000000004', '11111111-b003-1000-0000-000000000004',
   'Leur contenu n''est pas choisi par le client',
   'true', '3'),
  ('11111111-b003-2400-0000-000000000004', '11111111-b003-1000-0000-000000000004',
   'Ils se retirent le matin, avant l''ouverture de la boutique',
   'false', '4'),

  -- Q05 — cours de natation à Besançon (bonne réponse : position 2)
  ('11111111-b003-2100-0000-000000000005', '11111111-b003-1000-0000-000000000005',
   'Aux enfants qui débutent la natation',
   'false', '1'),
  ('11111111-b003-2200-0000-000000000005', '11111111-b003-1000-0000-000000000005',
   'Aux adultes qui ne savent pas nager',
   'true', '2'),
  ('11111111-b003-2300-0000-000000000005', '11111111-b003-1000-0000-000000000005',
   'À tous les habitants, quel que soit leur niveau',
   'false', '3'),
  ('11111111-b003-2400-0000-000000000005', '11111111-b003-1000-0000-000000000005',
   'Aux maîtres-nageurs en cours de formation',
   'false', '4'),

  -- Q06 — épicerie de Saint-Julien (bonne réponse : position 4)
  ('11111111-b003-2100-0000-000000000006', '11111111-b003-1000-0000-000000000006',
   'Grâce à une importante subvention versée par la mairie',
   'false', '1'),
  ('11111111-b003-2200-0000-000000000006', '11111111-b003-1000-0000-000000000006',
   'Grâce à un prêt bancaire obtenu par la gérante',
   'false', '2'),
  ('11111111-b003-2300-0000-000000000006', '11111111-b003-1000-0000-000000000006',
   'Grâce à l''installation d''une grande chaîne de magasins',
   'false', '3'),
  ('11111111-b003-2400-0000-000000000006', '11111111-b003-1000-0000-000000000006',
   'Grâce à l''argent investi par les habitants du village',
   'true', '4'),

  -- Q07 — jardin partagé de Roubaix (bonne réponse : position 1)
  ('11111111-b003-2100-0000-000000000007', '11111111-b003-1000-0000-000000000007',
   'Par un tirage au sort parmi les candidatures déposées',
   'true', '1'),
  ('11111111-b003-2200-0000-000000000007', '11111111-b003-1000-0000-000000000007',
   'Selon l''ordre d''arrivée des demandes en mairie',
   'false', '2'),
  ('11111111-b003-2300-0000-000000000007', '11111111-b003-1000-0000-000000000007',
   'Aux familles prêtes à payer le loyer le plus élevé',
   'false', '3'),
  ('11111111-b003-2400-0000-000000000007', '11111111-b003-1000-0000-000000000007',
   'Par un vote des jardiniers déjà installés',
   'false', '4'),

  -- Q08 — étude sur le vélo à Grenoble (bonne réponse : position 3)
  ('11111111-b003-2100-0000-000000000008', '11111111-b003-1000-0000-000000000008',
   'Les vols de vélos ont fortement diminué près des gares',
   'false', '1'),
  ('11111111-b003-2200-0000-000000000008', '11111111-b003-1000-0000-000000000008',
   'La piste le long de l''Isère ouvrira l''an prochain',
   'false', '2'),
  ('11111111-b003-2300-0000-000000000008', '11111111-b003-1000-0000-000000000008',
   'L''usage du vélo a progressé, notamment grâce à une piste protégée',
   'true', '3'),
  ('11111111-b003-2400-0000-000000000008', '11111111-b003-1000-0000-000000000008',
   'La métropole va supprimer des stationnements pour vélos',
   'false', '4'),

  -- Q09 — nocturne du musée d''Amiens (bonne réponse : position 2)
  ('11111111-b003-2100-0000-000000000009', '11111111-b003-1000-0000-000000000009',
   'Parce que le prix du billet décourageait la plupart des visiteurs',
   'false', '1'),
  ('11111111-b003-2200-0000-000000000009', '11111111-b003-1000-0000-000000000009',
   'Pour permettre aux personnes qui travaillent en journée de venir',
   'true', '2'),
  ('11111111-b003-2300-0000-000000000009', '11111111-b003-1000-0000-000000000009',
   'Pour remplacer l''ouverture du mardi, supprimée à la rentrée',
   'false', '3'),
  ('11111111-b003-2400-0000-000000000009', '11111111-b003-1000-0000-000000000009',
   'Parce que le musée était trop fréquenté l''après-midi',
   'false', '4'),

  -- Q10 — bornes à déchets alimentaires de Tours (bonne réponse : position 4)
  ('11111111-b003-2100-0000-00000000000a', '11111111-b003-1000-0000-00000000000a',
   'Pour réduire le nombre de conteneurs dans les rues',
   'false', '1'),
  ('11111111-b003-2200-0000-00000000000a', '11111111-b003-1000-0000-00000000000a',
   'Pour faire payer la collecte des déchets alimentaires',
   'false', '2'),
  ('11111111-b003-2300-0000-00000000000a', '11111111-b003-1000-0000-00000000000a',
   'Pour vendre du compost aux habitants de la ville',
   'false', '3'),
  ('11111111-b003-2400-0000-00000000000a', '11111111-b003-1000-0000-00000000000a',
   'Pour transformer ces déchets en compost au lieu de les brûler',
   'true', '4');

-- ============================================================================
-- CHECKLIST — contrôles passés
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (11111111-b003-1000/4000/21..2400-…-NN, NN=01..0a).
-- [x] Support unique : article informatif court de presse locale (10 sujets et
--     villes tous différents : atelier de réparation à Lyon, prêt d''instruments
--     à Nantes, navette seniors à Perpignan, paniers d''invendus à Toulouse,
--     natation adultes à Besançon, épicerie de village dans le Cantal, jardin
--     partagé à Roubaix, étude vélo à Grenoble, nocturne au musée d''Amiens,
--     collecte des biodéchets à Tours). Aucun support interdit utilisé
--     (pas d''e-mail, lettre, forum, annonce, note, FAQ, brochure…).
-- [x] Passages TEXTE ~60-120 mots, mise en forme article (titre avec ville en
--     dateline, corps journalistique, citation d''un témoin), media_id NULL.
-- [x] Prénoms variés et originaux dans les citations : Amadou Sow, Lucia
--     Fernandes, Wei Zhang, Rachid Benali, Olena Kovalenko, Fatou Diallo,
--     Diego Morales, Priya Sharma, Marek Nowak, Aïcha Traoré.
-- [x] 4 propositions / 1 correcte par item. Distribution des bonnes réponses :
--     pos1:2, pos2:3, pos3:2, pos4:3 (max 3 par position, 4 positions utilisées).
-- [x] competence_code : ce_reperage_explicite x3 (Q1, Q5, Q7),
--     ce_inference_intention x4 (Q3, Q6, Q9, Q10), ce_reformulation x3
--     (Q2, Q4, Q8).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3 distracteurs
--     expliqués, point clé en **gras**, mécanisme linguistique nommé (formule
--     restrictive, connecteur de conséquence, opposition « ne… plus… mais »,
--     détail secondaire vs cause principale, inférence de but…).
-- [x] Pas de SVG ni SSML dans ce lot (supports textuels uniquement) — rien à
--     équilibrer.
-- [x] Apostrophes SQL doublées partout, contenu 100% original, items autonomes.
-- ============================================================================
