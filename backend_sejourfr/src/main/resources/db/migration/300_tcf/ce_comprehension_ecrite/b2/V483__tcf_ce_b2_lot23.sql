-- ============================================================================
-- V483 — TCF CE B2 — lot 23 (thème : ruralité vs urbanité)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 6 items, textes longs (~190-230 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : conflits néo-ruraux (patrimoine sensoriel) / fusions de communes /
-- imaginaire idéalisé de la campagne / renaissance des villes moyennes /
-- fermetures de services publics ruraux / le périurbain mal-aimé.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c017-4000-0000-000000000001', 'TEXTE',
   'Depuis quelques années, les tribunaux ruraux voient défiler des plaignants d''un genre nouveau : des citadins fraîchement installés qui attaquent en justice le chant d''un coq, le carillon d''une église ou l''odeur d''une étable. À Saint-Genest, village de huit cents habitants du Cantal, l''éleveur Bernard Vialatte a ainsi passé deux ans à se défendre contre ses nouveaux voisins, arrivés de région parisienne, qui exigeaient le déplacement de son troupeau.

Le législateur a fini par trancher : une loi reconnaît désormais les sons et les odeurs des campagnes comme un « patrimoine sensoriel » protégé. Victoire symbolique, saluée par les maires ruraux, mais qui ne règle pas le fond du problème. Car ces conflits révèlent moins une question de bruit qu''un malentendu profond : beaucoup de nouveaux arrivants achètent un décor — clochers, prés, silence supposé — sans imaginer que ce décor est aussi un lieu de travail.

La campagne n''est pas un parc paysager entretenu pour le repos des urbains ; c''est un espace productif, avec ses horaires, ses machines et ses bêtes. Tant que cette évidence ne sera pas comprise avant la signature chez le notaire, les greffes des tribunaux continueront de recevoir des plaintes contre des coqs.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c017-4000-0000-000000000002', 'TEXTE',
   'La France compte près de trente-cinq mille communes, record européen dont elle tire une fierté ambiguë. Dans la Meuse, le village de Brouennes-la-Côte n''existe plus sur le papier depuis janvier : ses cent quarante habitants ont voté la fusion avec deux bourgs voisins pour former une « commune nouvelle ». Le maire sortant, Étienne Roussel, résume l''alternative qui s''offrait à lui : « disparaître en gardant notre nom, ou survivre en le perdant ».

Depuis dix ans, près de huit cents fusions de ce type ont redessiné la carte des campagnes. Les incitations financières de l''État y sont pour beaucoup, mais elles n''expliquent pas tout. Une mairie ouverte deux heures par semaine, un conseil municipal introuvable faute de candidats, un budget qui ne couvre plus l''entretien de la voirie : pour bien des micro-communes, la fusion n''est pas un choix d''avenir, c''est un constat de fin.

Les opposants dénoncent une perte d''identité et une démocratie éloignée des habitants. L''argument mérite d''être entendu. Mais une identité sans école, sans budget et sans élus tient davantage du souvenir que de la vie locale. La vraie question n''est pas de savoir si ces villages doivent fusionner, mais pourquoi on les a laissés s''affaiblir au point de n''avoir plus que cette option.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c017-4000-0000-000000000003', 'TEXTE',
   'Ouvrez un magazine de décoration, une publicité pour une voiture ou un catalogue immobilier : la campagne y est partout, et toujours la même. Brume dorée sur les prés, table en bois sous un tilleul, enfants courant pieds nus dans l''herbe. Selon une enquête de l''institut Ipsoval, huit Français sur dix jugent la vie rurale « plus authentique » que la vie urbaine — y compris parmi ceux qui n''y ont jamais vécu.

Cette campagne rêvée a un mérite : elle dit beaucoup de nos fatigues urbaines. Elle a aussi un défaut considérable : elle n''existe pas. La campagne réelle connaît les fins de mois difficiles, les vingt minutes de voiture pour acheter du pain et les hivers où le hameau se vide. Quant au silence tant vanté, il s''interrompt à l''aube, quand démarrent les tracteurs.

Faut-il pour autant ricaner de ce besoin de verdure ? Ce serait trop facile. Le rêve rural, si naïf soit-il, exprime une demande sérieuse : ralentir, habiter autrement, retrouver de l''espace. Le problème n''est pas de rêver la campagne, c''est de déménager dans un rêve. Les retours en ville, deux ou trois ans après une installation enthousiaste, sont assez nombreux pour rappeler qu''un paysage de magazine fait rarement un projet de vie.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c017-4000-0000-000000000004', 'TEXTE',
   'Longtemps moquées pour leurs centres déserts et leurs rocades commerciales, les villes moyennes connaissent un retournement que peu d''observateurs avaient anticipé. À Nevers, à Albi, à Saint-Brieuc, les agences immobilières décrivent une clientèle nouvelle : des trentenaires venus des métropoles, mais aussi des habitants des villages alentour qui se rapprochent des services.

Ce double mouvement est la clé du phénomène, et il bouscule la lecture habituelle du débat. On oppose volontiers la France des métropoles à celle des campagnes, comme s''il n''existait rien entre les deux. Or les villes de vingt à cent mille habitants offrent précisément ce que chacun des deux pôles refuse à l''autre : un hôpital, un lycée, un cinéma, des prix au mètre carré qui laissent respirer, sans l''anonymat ni la saturation des grandes agglomérations.

Rien n''est gagné pour autant. Des cœurs de ville restent à rénover, des emplois qualifiés manquent encore, et certaines communes lauréates de programmes nationaux peinent à transformer l''essai. Mais le simple fait que ces villes soient redevenues désirables change l''équation territoriale : le rééquilibrage du pays ne se jouera peut-être ni dans les métropoles saturées ni dans les villages isolés, mais dans cet entre-deux que l''on a si longtemps regardé de haut.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c017-4000-0000-000000000005', 'TEXTE',
   'À Mailly-le-Bas, sept cents habitants dans la Nièvre, la trésorerie a fermé en 2019, le guichet de la gare en 2021, et le bureau de poste vient de réduire ses horaires à deux matinées par semaine. Rien d''exceptionnel : chaque fermeture, prise isolément, obéit à une logique comptable défendable — fréquentation en baisse, dématérialisation des démarches, rationalisation des réseaux.

C''est précisément là que réside le piège. Les habitants ne protestent pas contre une fermeture : ils protestent contre leur accumulation. Quand l''État explique qu''une maison de services installée à quinze kilomètres remplace avantageusement quatre guichets disparus, il fait un calcul exact et une erreur politique. Car un service public, en milieu rural, n''est pas seulement un guichet : c''est la preuve visible qu''un territoire compte encore aux yeux de la nation.

Les enquêtes d''opinion le confirment avec constance : le sentiment d''abandon exprimé dans les campagnes progresse plus vite que les fermetures elles-mêmes. Certains y voient une émotion irrationnelle qu''il suffirait de corriger par de la pédagogie. C''est prendre le problème à l''envers : quand des habitants se sentent invisibles, leur démontrer qu''ils ont tort ne fait que confirmer leur impression. La rationalité budgétaire a ses raisons ; encore faudrait-il qu''elle accepte de compter ce qui ne se chiffre pas.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c017-4000-0000-000000000006', 'TEXTE',
   'Le lotissement périurbain est sans doute l''espace le plus habité et le plus méprisé de France. Un quart de la population y vit, mais les discours savants n''ont longtemps eu pour lui que des mots durs : uniformité des pavillons, dépendance à la voiture, entrées de ville défigurées par les enseignes commerciales. Ni vraie ville ni vraie campagne, le périurbain serait la faute de goût du territoire national.

Le géographe Paul Andrieu propose de renverser le regard. Dans une étude menée pendant trois ans autour de Châteauroux et de Vannes, il décrit des habitants qui n''ont pas atterri là par défaut, mais qui ont arbitré : un jardin plutôt qu''un balcon, des voisins à bonne distance, la ville accessible sans devoir y dormir. Loin du désert social décrit par certains essayistes, il observe des sociabilités bien réelles — fêtes des voisins, clubs sportifs, entraide ordinaire —, simplement moins visibles que celles des centres anciens.

On peut discuter telle ou telle de ses conclusions, et l''auteur ne prétend d''ailleurs pas clore le débat. Mais son travail a une vertu : il rappelle que le mépris du pavillon est souvent un mépris de classe qui ne dit pas son nom, exprimé par ceux qui ont les moyens d''habiter les centres historiques. Juger un mode de vie sans écouter ceux qui l''ont choisi, voilà une faute de goût plus sûre que toutes les zones commerciales.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c017-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c017-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'L''auteur affirme que « ces conflits révèlent moins une question de bruit qu''un malentendu profond » : **l''idée principale est que beaucoup de néo-ruraux achètent un décor sans comprendre que la campagne est un espace de travail**. La réponse A contredit le texte : la loi est une « victoire symbolique » qui « ne règle pas le fond du problème ». La réponse C inverse la thèse : pour l''auteur, c''est aux arrivants de comprendre l''espace productif avant d''acheter, pas aux éleveurs de s''adapter. La réponse D est une sur-généralisation : les procès cités restent des cas portés devant les tribunaux, rien n''indique que « la plupart » des citadins installés attaquent leurs voisins. Mécanisme : distinguer l''**idée principale** d''un détail (la loi) et résister à la sur-généralisation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c017-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c017-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Que cherche à montrer l''auteur à propos des fusions de communes ?',
   'Le texte conclut que « la fusion n''est pas un choix d''avenir, c''est un constat de fin » et que la vraie question est « pourquoi on les a laissés s''affaiblir » : **la fusion est présentée comme le symptôme d''un long affaiblissement subi, non comme un véritable choix**. La réponse A déforme un détail : les incitations financières « y sont pour beaucoup, mais elles n''expliquent pas tout ». La réponse B inverse un argument : les opposants dénoncent justement une démocratie « éloignée des habitants ». La réponse C attribue à l''auteur la position des opposants, qu''il rapporte puis relativise (« une identité sans école… tient davantage du souvenir »). Mécanisme : **inférence d''intention** — distinguer la thèse de l''auteur des arguments rapportés au discours indirect.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c017-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c017-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Quel regard l''auteur porte-t-il sur l''image idéalisée de la campagne ?',
   'L''auteur refuse de « ricaner » (« Ce serait trop facile ») et reconnaît que le rêve rural « exprime une demande sérieuse », tout en avertissant que « le problème… c''est de déménager dans un rêve » : **son regard est nuancé — compréhension du besoin, mise en garde contre la confusion entre rêve et projet de vie**. La réponse B inverse le ton : la moquerie est précisément ce qu''il écarte. La réponse C sur-généralise le sondage cité : huit Français sur dix le « jugent », mais l''auteur répond que cette campagne rêvée « n''existe pas ». La réponse D invente un encouragement absent : les retours en ville après deux ou trois ans servent au contraire d''avertissement. Mécanisme : repérer le **ton concessif** (question rhétorique + « Ce serait trop facile ») qui signale une position médiane.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c017-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c017-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'Le texte décrit un « retournement » et conclut que le rééquilibrage du pays se jouera « dans cet entre-deux longtemps regardé de haut » : **l''idée principale est que les villes moyennes redeviennent attractives et s''imposent comme une voie médiane entre métropoles et villages**. La réponse A sur-généralise : le texte décrit un double mouvement vers les villes moyennes, pas un exode massif des métropoles vers les campagnes. La réponse B contredit le détail-piège : « Rien n''est gagné pour autant », des cœurs de ville restent à rénover. La réponse D inverse le flux décrit : les habitants des villages « se rapprochent » des villes moyennes, ils ne les fuient pas. Mécanisme : **idée principale** — synthétiser le mouvement global contre une inversion de sens et une sur-généralisation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c017-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c017-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Que veut faire comprendre l''auteur à propos des fermetures de services publics en milieu rural ?',
   'Le texte oppose des fermetures « défendables » une à une à leur « accumulation », et qualifie la réponse comptable de « calcul exact et erreur politique » : **la bonne réponse relie l''accumulation des fermetures au sentiment d''abandon, que les justifications chiffrées ne font qu''aggraver**. La réponse A attribue à l''auteur une opinion qu''il rapporte (« Certains y voient… ») puis réfute (« C''est prendre le problème à l''envers »). La réponse B reprend l''argument de l''État, justement présenté comme une « erreur politique », pas comme la position de l''auteur. La réponse C inverse un détail : c''est le sentiment d''abandon qui « progresse plus vite que les fermetures elles-mêmes », pas l''inverse. Mécanisme : **inférence de la thèse** face à des opinions rapportées et à une inversion de comparaison.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c017-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c017-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Comment l''auteur se positionne-t-il face aux critiques adressées au périurbain ?',
   'L''auteur relaie l''étude qui « renverse le regard » et conclut que « le mépris du pavillon est souvent un mépris de classe qui ne dit pas son nom », tout en concédant qu''« on peut discuter telle ou telle de ses conclusions » : **il prend ses distances avec les critiques, y voyant un jugement social déguisé, sans pour autant adhérer aveuglément à l''étude citée**. La réponse A inverse sa position : le « désert social » est la description des essayistes que l''étude contredit. La réponse C contredit un détail explicite : l''auteur de l''étude « ne prétend d''ailleurs pas clore le débat ». La réponse D sur-généralise : l''étude décrit des habitants qui « ont arbitré », sans affirmer que tous ont choisi en toute liberté. Mécanisme : **ton de l''auteur** — concession (« On peut discuter… Mais ») signalant une adhésion critique, ni rejet ni approbation totale.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — conflits néo-ruraux (bonne réponse : position 2)
  ('11111111-c017-2100-0000-000000000001', '11111111-c017-1000-0000-000000000001',
   'La loi sur le patrimoine sensoriel a définitivement réglé les conflits de voisinage à la campagne',
   'false', '1'),

  ('11111111-c017-2200-0000-000000000001', '11111111-c017-1000-0000-000000000001',
   'Ces procès révèlent que beaucoup de nouveaux arrivants confondent un espace de travail avec un décor',
   'true', '2'),

  ('11111111-c017-2300-0000-000000000001', '11111111-c017-1000-0000-000000000001',
   'Les éleveurs devraient adapter leurs activités aux attentes des nouveaux habitants',
   'false', '3'),

  ('11111111-c017-2400-0000-000000000001', '11111111-c017-1000-0000-000000000001',
   'La plupart des citadins installés à la campagne finissent par attaquer leurs voisins en justice',
   'false', '4'),

  -- item 02 — fusions de communes (bonne réponse : position 4)
  ('11111111-c017-2100-0000-000000000002', '11111111-c017-1000-0000-000000000002',
   'Les incitations financières de l''État expliquent à elles seules la vague de fusions',
   'false', '1'),

  ('11111111-c017-2200-0000-000000000002', '11111111-c017-1000-0000-000000000002',
   'Les communes nouvelles ont rapproché la démocratie locale des habitants',
   'false', '2'),

  ('11111111-c017-2300-0000-000000000002', '11111111-c017-1000-0000-000000000002',
   'Il condamne les fusions parce qu''elles font disparaître l''identité des villages',
   'false', '3'),

  ('11111111-c017-2400-0000-000000000002', '11111111-c017-1000-0000-000000000002',
   'Les fusions sont moins un choix d''avenir que l''aboutissement d''un long affaiblissement des villages',
   'true', '4'),

  -- item 03 — campagne idéalisée (bonne réponse : position 1)
  ('11111111-c017-2100-0000-000000000003', '11111111-c017-1000-0000-000000000003',
   'Il comprend le besoin qu''elle exprime mais met en garde contre la confusion entre rêve et projet de vie',
   'true', '1'),

  ('11111111-c017-2200-0000-000000000003', '11111111-c017-1000-0000-000000000003',
   'Il se moque ouvertement de la naïveté des citadins épris de verdure',
   'false', '2'),

  ('11111111-c017-2300-0000-000000000003', '11111111-c017-1000-0000-000000000003',
   'Il confirme que la vie rurale est plus authentique que la vie urbaine',
   'false', '3'),

  ('11111111-c017-2400-0000-000000000003', '11111111-c017-1000-0000-000000000003',
   'Il encourage les urbains fatigués à s''installer à la campagne sans attendre',
   'false', '4'),

  -- item 04 — villes moyennes (bonne réponse : position 3)
  ('11111111-c017-2100-0000-000000000004', '11111111-c017-1000-0000-000000000004',
   'Les métropoles se vident massivement au profit des campagnes françaises',
   'false', '1'),

  ('11111111-c017-2200-0000-000000000004', '11111111-c017-1000-0000-000000000004',
   'Les villes moyennes ont surmonté toutes les difficultés qui les pénalisaient',
   'false', '2'),

  ('11111111-c017-2300-0000-000000000004', '11111111-c017-1000-0000-000000000004',
   'Les villes moyennes redeviennent attractives et s''imposent comme une voie médiane entre métropoles et villages',
   'true', '3'),

  ('11111111-c017-2400-0000-000000000004', '11111111-c017-1000-0000-000000000004',
   'Les habitants des villages quittent les villes moyennes pour rejoindre les grandes agglomérations',
   'false', '4'),

  -- item 05 — services publics ruraux (bonne réponse : position 4)
  ('11111111-c017-2100-0000-000000000005', '11111111-c017-1000-0000-000000000005',
   'Le sentiment d''abandon des campagnes est une émotion irrationnelle qu''un effort de pédagogie suffirait à corriger',
   'false', '1'),

  ('11111111-c017-2200-0000-000000000005', '11111111-c017-1000-0000-000000000005',
   'Les maisons de services remplacent avantageusement les guichets fermés en milieu rural',
   'false', '2'),

  ('11111111-c017-2300-0000-000000000005', '11111111-c017-1000-0000-000000000005',
   'Les fermetures réelles sont plus nombreuses que ne le perçoivent les habitants des campagnes',
   'false', '3'),

  ('11111111-c017-2400-0000-000000000005', '11111111-c017-1000-0000-000000000005',
   'Des fermetures défendables une à une produisent, par leur accumulation, un sentiment d''abandon que les arguments comptables aggravent',
   'true', '4'),

  -- item 06 — périurbain (bonne réponse : position 2)
  ('11111111-c017-2100-0000-000000000006', '11111111-c017-1000-0000-000000000006',
   'Il partage le constat d''un désert social propre aux lotissements pavillonnaires',
   'false', '1'),

  ('11111111-c017-2200-0000-000000000006', '11111111-c017-1000-0000-000000000006',
   'Il s''en distancie, y voyant souvent un mépris de classe, tout en restant prudent sur l''étude qu''il cite',
   'true', '2'),

  ('11111111-c017-2300-0000-000000000006', '11111111-c017-1000-0000-000000000006',
   'Il considère que l''étude de Paul Andrieu clôt définitivement le débat sur le périurbain',
   'false', '3'),

  ('11111111-c017-2400-0000-000000000006', '11111111-c017-1000-0000-000000000006',
   'Il affirme que tous les habitants du périurbain ont choisi ce mode de vie en toute liberté',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 6 items, UUID déterministes (11111111-c017-1000/4000/21xx-…-NN, NN=01..06).
-- [x] Thème unique « ruralité vs urbanité », 6 angles tous différents :
--     conflits néo-ruraux & patrimoine sensoriel / fusions de communes
--     rurales / imaginaire idéalisé de la campagne / renaissance des villes
--     moyennes / fermetures de services publics ruraux & sentiment d'abandon /
--     réhabilitation du périurbain. Aucun thème interdit (pas de ville &
--     mobilité, logement, environnement, tourisme, télétravail…).
-- [x] Textes B2 longs : 191 / 201 / 200 / 198 / 203 / 227 mots (tous dans la
--     fourchette 150-280), denses, avec détail-piège (loi « symbolique » qui
--     ne règle pas le fond, incitations qui « n'expliquent pas tout »,
--     « Rien n'est gagné pour autant », sentiment qui progresse plus vite que
--     les fermetures, « ne prétend pas clore le débat »).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:1, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2 (items 01, 04),
--     ce_inference_intention ×2 (items 02, 05), ce_ton_auteur ×2 (items 03, 06).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme nommé
--     (sur-généralisation, inversion de position/comparaison, opinion
--     rapportée vs thèse, concession « certes/mais », détail-piège).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (Saint-Genest, Brouennes-la-Côte,
--     Mailly-le-Bas, Bernard Vialatte, Étienne Roussel, Paul Andrieu, institut
--     Ipsoval — lieux, prénoms et chiffres inventés).
-- ============================================================================
