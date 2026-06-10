-- ============================================================================
-- V474 — TCF CE B2 — lot 14 (thème : sport & loisirs)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~200-215 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : spécialisation sportive précoce des enfants / pénurie d'arbitres
-- amateurs / e-sport et statut de sport / boom des loisirs manuels /
-- massification de l'ultra-trail / renouveau des jeux de société /
-- pétanque entre licences et pratique libre.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c00e-4000-0000-000000000001', 'TEXTE',
   'À huit ans, Sofiane s''entraîne déjà quatre fois par semaine dans un centre de formation de tennis, vacances comprises. Son cas n''a plus rien d''exceptionnel : persuadés que les champions se fabriquent tôt, de nombreux clubs proposent désormais des filières intensives dès l''école primaire, et les parents s''y précipitent.

Les travaux des chercheurs en sciences du sport racontent pourtant une autre histoire. En suivant pendant dix ans plusieurs milliers de jeunes licenciés, une équipe de l''université de Poitiers a montré que les enfants spécialisés avant douze ans se blessent deux fois plus que les autres et abandonnent massivement leur discipline à l''adolescence, dégoûtés par la répétition et la pression. Plus troublant encore : la majorité des sportifs professionnels interrogés dans l''étude ont pratiqué plusieurs sports jusqu''au collège, et ne se sont spécialisés que tardivement.

La conclusion s''impose d''elle-même : la spécialisation précoce ne fabrique pas des champions, elle fabrique surtout des blessés et des déçus. Avant douze ans, l''enjeu n''est pas de produire de la performance, mais de construire un répertoire moteur varié et, surtout, une chose que les programmes intensifs détruisent méthodiquement : le plaisir de jouer. Les clubs qui l''oublient préparent moins des podiums que des salles d''attente de kinésithérapeutes.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00e-4000-0000-000000000002', 'TEXTE',
   'Dimanche matin, stade municipal de Lormont : le match de la catégorie des moins de quinze ans est annulé, faute d''arbitre. La scène, marginale il y a vingt ans, devient routinière. Les districts de football estiment qu''il manque plusieurs milliers d''arbitres en France, et la pyramide vieillit : un officiel sur trois a plus de cinquante ans, tandis que les jeunes recrutés raccrochent en moyenne au bout de deux saisons.

Pourquoi cette hémorragie ? Les indemnités, modestes, n''ont jamais été la motivation première. Ce qui pousse les arbitres vers la sortie, ce sont les bords de terrain : insultes des spectateurs, contestations systématiques, parfois agressions physiques. Une enquête fédérale révèle que la moitié des arbitres amateurs déclarent avoir été menacés au moins une fois dans la saison — et que ce motif arrive très loin devant tous les autres dans les lettres de démission.

Les fédérations multiplient les campagnes de recrutement, distribuent des écussons « respect » et promettent des formations accélérées. Autant verser de l''eau dans un seau percé : tant que siffler un match de quartier exposera à la vindicte du public, aucune campagne ne retiendra les vocations. Le problème de l''arbitrage amateur n''est pas un problème de recrutement ; c''est un problème de climat.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00e-4000-0000-000000000003', 'TEXTE',
   'Faut-il considérer les compétitions de jeux vidéo comme un sport à part entière ? La question, qui faisait sourire il y a dix ans, se pose désormais sérieusement : tournois remplissant des salles entières, joueurs sous contrat soumis à des entraînements quotidiens, préparateurs physiques et mentaux, et même des discussions pour une éventuelle apparition aux Jeux olympiques.

Les défenseurs de l''e-sport avancent des arguments solides. La dextérité d''un joueur professionnel, capable de plusieurs centaines d''actions par minute, n''a rien à envier aux réflexes d''un gardien de but ; la rigueur des entraînements, la tactique collective, la gestion du stress en compétition rappellent point par point le sport traditionnel. À l''inverse, leurs adversaires objectent l''absence d''effort physique global et la dépendance à des éditeurs privés, propriétaires des jeux et donc des règles — situation inimaginable en athlétisme ou en judo.

Disons-le franchement : ce débat de définition est largement stérile. Que l''e-sport entre ou non dans la catégorie « sport » ne changera rien à ce qu''il est déjà : une pratique compétitive exigeante, structurée, suivie par des millions de spectateurs. La vraie question n''est pas sémantique mais pratique : statut des joueurs, encadrement des mineurs, reconversion après des carrières qui s''achèvent à vingt-cinq ans. Pendant qu''on dispute des mots, ces chantiers-là n''avancent pas.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00e-4000-0000-000000000004', 'TEXTE',
   'Les ateliers de céramique de Clermont-Ferrand affichent complet six mois à l''avance ; les merceries, que l''on disait condamnées, rouvrent ; les cours de menuiserie du soir refusent du monde. Le phénomène dépasse l''anecdote : en quelques années, les loisirs manuels, longtemps associés aux générations précédentes, sont devenus la passion des vingt-cinq – quarante ans.

Comment expliquer cet engouement ? L''interprétation la plus répandue y voit une mode passagère, portée par quelques émissions à succès. Elle passe à côté de l''essentiel. Ce que cherchent les nouveaux adeptes du tournage ou du tricot, à les écouter, c''est d''abord une expérience que leur quotidien ne leur offre plus : faire une chose entière, du début à la fin, avec leurs mains, et constater un résultat tangible. Beaucoup décrivent aussi ces heures d''atelier comme les seules de la semaine où leur attention se pose enfin sur un seul objet.

Il serait naïf d''y voir une révolution — la plupart des inscrits restent des amateurs du dimanche, et c''est très bien ainsi. Mais le succès de ces pratiques dit quelque chose de notre époque : le besoin, de plus en plus pressant, d''éprouver une forme de prise directe sur le monde. Les mains, semble-t-il, savent encore ce que nous avons oublié.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00e-4000-0000-000000000005', 'TEXTE',
   'Trois cents kilomètres de sentiers, douze mille mètres de dénivelé, des concurrents qui s''élancent pour soixante heures de course : les épreuves d''ultra-trail repoussent chaque année leurs limites, et le public suit. La discipline, confidentielle il y a quinze ans, compte aujourd''hui des centaines d''épreuves en France et des listes d''attente pour s''y inscrire.

Cette croissance spectaculaire a son revers, que les secouristes de montagne sont les premiers à mesurer. Les pelotons grossissent plus vite que l''expérience des coureurs : on voit désormais s''aligner sur des formats extrêmes des amateurs qui ne courent en montagne que depuis deux saisons, équipés de matériel dernier cri mais incapables de lire une dégradation météo. Les interventions liées aux courses et aux entraînements en altitude ont doublé en cinq ans dans plusieurs massifs — épuisements sévères, hypothermies, chutes sur des terrains que les intéressés n''auraient jamais dû aborder.

Faut-il interdire, limiter, contingenter ? Les organisateurs sérieux ont déjà choisi une autre voie : exiger des qualifications préalables, durcir le matériel obligatoire, ne plus hésiter à arrêter une course quand la montagne le commande. Reste le plus difficile, qui ne se décrète pas : convaincre les coureurs que l''ultra-distance est une pratique qui s''apprend pendant des années, et non un exploit que l''on s''offre.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00e-4000-0000-000000000006', 'TEXTE',
   'On annonçait leur disparition, écrasés par les écrans ; ils ne se sont jamais aussi bien portés. Les jeux de société connaissent depuis une dizaine d''années un âge d''or éditorial : plus d''un millier de nouveautés paraissent chaque année en France, les bars à jeux essaiment de Brest à Mulhouse, et les festivals spécialisés attirent des foules familiales qui patientent une heure pour essayer un prototype.

Le plus intéressant n''est pas le volume, mais le profil des joueurs. Contrairement au cliché du passionné solitaire, les enquêtes des éditeurs dessinent un public d''abord motivé par la rencontre : on vient pour jouer, certes, mais surtout pour passer trois heures autour d''une table avec des gens dont on croise le regard. Plusieurs gérants de bars à jeux le confirment : une partie de leur clientèle repart sans avoir terminé la partie, mais après une longue conversation.

Les éditeurs l''ont d''ailleurs compris, qui conçoivent de plus en plus de jeux coopératifs, où l''on gagne ou perd ensemble, et des formats courts pensés pour faire jouer des inconnus. Le jeu de société moderne vend moins de la compétition que de la présence. Sa boîte colorée contient, au fond, ce qui est devenu le plus rare : une excuse en carton pour se retrouver vraiment.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00e-4000-0000-000000000007', 'TEXTE',
   'La pétanque se meurt, entend-on dans les congrès fédéraux : les licenciés ont fondu d''un tiers en vingt ans, les boulodromes vieillissent avec leurs habitués, et la moyenne d''âge des compétiteurs frôle la soixantaine. Le tableau, exact, appelle pourtant un sérieux correctif.

Car pendant que les licences s''érodent, la pratique libre explose. Les terrains improvisés se multiplient sur les berges et dans les parcs, des bars à boules ouvrent dans les métropoles avec des allées éclairées jusqu''à minuit, et les triplettes de trentenaires y disputent des parties acharnées entre deux conversations. Selon les estimations du secteur, la France compterait dix fois plus de joueurs occasionnels que de licenciés. La pétanque ne disparaît pas : elle déserte les fédérations.

On peut déplorer cette évolution, regretter les concours d''antan et le rituel des qualifications départementales. On peut aussi y lire une leçon : ce que cherchent les nouveaux joueurs — la convivialité, la simplicité, l''absence d''enjeu —, c''est exactement ce que la pétanque a toujours su offrir, débarrassée du carcan compétitif. Plutôt que de pleurer ses licenciés perdus, la fédération serait bien inspirée d''aller à la rencontre de cette génération qui joue autrement. Le jeu, lui, n''a jamais été aussi pratiqué ; c''est l''institution qui doit se réinventer.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c00e-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00e-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'Le texte conclut : « la spécialisation précoce ne fabrique pas des champions, elle fabrique surtout des blessés et des déçus ». **L''idée principale est la nocivité de la spécialisation sportive avant douze ans**, que la bonne réponse synthétise. La réponse A inverse la thèse : c''est la croyance des clubs et des parents que le texte démonte. La réponse C contredit un détail explicite : la majorité des professionnels interrogés ont pratiqué plusieurs sports et ne se sont spécialisés que tardivement. La réponse D est une sur-généralisation : les enfants spécialisés abandonnent « massivement », pas dans leur totalité. Mécanisme : distinguer la **thèse de l''auteur** de la croyance qu''il réfute.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c00e-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00e-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur la crise de l''arbitrage amateur ?',
   'Le texte affirme : « Ce qui pousse les arbitres vers la sortie, ce sont les bords de terrain », motif qui « arrive très loin devant tous les autres dans les lettres de démission ». **La cause première des départs est l''hostilité subie pendant les matchs**, que la bonne réponse reformule. La réponse A contredit un détail : les indemnités « n''ont jamais été la motivation première ». La réponse B inverse les faits : les campagnes se multiplient, mais l''auteur les compare à « de l''eau dans un seau percé ». La réponse C déforme le chiffre-piège : la moitié des arbitres déclarent avoir été menacés, non agressés physiquement. Mécanisme : **inférence de la cause principale** face à des distracteurs en déformation de détail.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c00e-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00e-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur dans le débat sur l''e-sport ?',
   'L''auteur tranche : « ce débat de définition est largement stérile », et déplace la question vers « statut des joueurs, encadrement des mineurs, reconversion ». **Sa position : dépasser la querelle sémantique pour traiter les chantiers concrets du secteur.** La réponse B reprend les arguments des défenseurs de l''e-sport, rapportés sans être endossés par l''auteur. La réponse C reprend l''objection des adversaires, elle aussi rapportée au discours indirect. La réponse D promeut un détail secondaire déformé : les Jeux olympiques ne sont évoqués que comme « discussions » pour une « éventuelle apparition », jamais comme une revendication de l''auteur. Mécanisme : distinguer la **voix de l''auteur** des positions qu''il rapporte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c00e-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00e-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Quelle est l''intention principale de l''auteur de ce texte ?',
   'Le texte oppose la lecture « mode passagère » — qui « passe à côté de l''essentiel » — au besoin réel des pratiquants : « faire une chose entière […] et constater un résultat tangible ». **L''intention est de montrer que cet engouement répond à un besoin profond de prise directe sur le monde.** La réponse A reprend l''interprétation explicitement rejetée par l''auteur. La réponse B sur-généralise : « il serait naïf d''y voir une révolution », les inscrits restent des amateurs. La réponse D inverse le jugement : l''auteur précise que rester un amateur du dimanche, « c''est très bien ainsi ». Mécanisme : **inférence d''intention** à partir d''une réfutation suivie d''une thèse.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c00e-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00e-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'Le texte relie la croissance de la discipline à son « revers » : des amateurs inexpérimentés sur des formats extrêmes et des interventions de secours qui « ont doublé en cinq ans ». **L''idée principale associe massification, inexpérience des coureurs et hausse des accidents.** La réponse A sur-généralise : l''auteur écarte l''interdiction au profit des qualifications préalables et du matériel obligatoire. La réponse C contredit le détail-piège : le « matériel dernier cri » n''empêche pas d''être « incapables de lire une dégradation météo ». La réponse D inverse les faits : les organisateurs sérieux durcissent déjà leurs exigences. Mécanisme : identifier l''**idée directrice** qui relie la cause (afflux de novices) à la conséquence (secours en hausse).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c00e-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00e-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Que cherche à montrer l''auteur à propos du succès des jeux de société ?',
   'Le texte affirme que le public est « d''abord motivé par la rencontre » et conclut que le jeu moderne « vend moins de la compétition que de la présence ». **La bonne réponse reformule cette explication par le besoin de présence partagée.** La réponse A promeut un détail vrai mais secondaire : le millier de nouveautés annuelles illustre le succès, il ne l''explique pas — l''auteur précise que « le plus intéressant n''est pas le volume ». La réponse B inverse le propos : la compétition passe après la rencontre, certains clients ne terminent même pas leur partie. La réponse C contredit l''ouverture du texte : les jeux « ne se sont jamais aussi bien portés » malgré les écrans. Mécanisme : résister au **détail secondaire** promu en explication principale.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c00e-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00e-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Comment l''auteur réagit-il au déclin annoncé de la pétanque ?',
   'L''auteur valide le constat chiffré (« Le tableau, exact ») mais lui oppose « un sérieux correctif » : « La pétanque ne disparaît pas : elle déserte les fédérations ». **Sa position : un déclin institutionnel, non un déclin du jeu, d''où l''appel à réinventer la fédération.** La réponse B sur-généralise : seules les licences chutent, la pratique libre « explose ». La réponse C inverse le jugement : l''auteur voit dans les bars à boules la preuve de la vitalité du jeu, le « carcan compétitif » étant présenté comme le repoussoir. La réponse D contredit la conclusion : la fédération est précisément invitée à « aller à la rencontre » de cette génération, ce qu''elle n''a pas encore fait. Mécanisme : la **concession corrigée** (exact… pourtant) signale une thèse nuancée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — spécialisation sportive précoce (bonne réponse : position 2)
  ('11111111-c00e-2100-0000-000000000001', '11111111-c00e-1000-0000-000000000001',
   'Les enfants doivent commencer l''entraînement intensif le plus tôt possible pour devenir champions',
   'false', '1'),

  ('11111111-c00e-2200-0000-000000000001', '11111111-c00e-1000-0000-000000000001',
   'La spécialisation sportive avant douze ans nuit aux enfants plus qu''elle ne fabrique des champions',
   'true', '2'),

  ('11111111-c00e-2300-0000-000000000001', '11111111-c00e-1000-0000-000000000001',
   'Les sportifs professionnels se sont presque tous spécialisés dès l''école primaire',
   'false', '3'),

  ('11111111-c00e-2400-0000-000000000001', '11111111-c00e-1000-0000-000000000001',
   'Tous les enfants inscrits en filière intensive abandonnent le sport à l''adolescence',
   'false', '4'),

  -- item 02 — arbitrage amateur (bonne réponse : position 4)
  ('11111111-c00e-2100-0000-000000000002', '11111111-c00e-1000-0000-000000000002',
   'Les arbitres quittent la fonction principalement à cause d''indemnités trop faibles',
   'false', '1'),

  ('11111111-c00e-2200-0000-000000000002', '11111111-c00e-1000-0000-000000000002',
   'Les campagnes de recrutement des fédérations ont permis de combler la pénurie d''arbitres',
   'false', '2'),

  ('11111111-c00e-2300-0000-000000000002', '11111111-c00e-1000-0000-000000000002',
   'La moitié des arbitres amateurs ont déjà été agressés physiquement pendant un match',
   'false', '3'),

  ('11111111-c00e-2400-0000-000000000002', '11111111-c00e-1000-0000-000000000002',
   'L''hostilité subie aux bords des terrains est la cause première des départs d''arbitres',
   'true', '4'),

  -- item 03 — e-sport (bonne réponse : position 1)
  ('11111111-c00e-2100-0000-000000000003', '11111111-c00e-1000-0000-000000000003',
   'Il juge la querelle de classification stérile et appelle à traiter les questions concrètes du secteur',
   'true', '1'),

  ('11111111-c00e-2200-0000-000000000003', '11111111-c00e-1000-0000-000000000003',
   'Il démontre que l''e-sport mérite pleinement le statut de sport traditionnel',
   'false', '2'),

  ('11111111-c00e-2300-0000-000000000003', '11111111-c00e-1000-0000-000000000003',
   'Il estime que l''absence d''effort physique disqualifie définitivement l''e-sport',
   'false', '3'),

  ('11111111-c00e-2400-0000-000000000003', '11111111-c00e-1000-0000-000000000003',
   'Il milite pour l''entrée rapide de l''e-sport au programme des Jeux olympiques',
   'false', '4'),

  -- item 04 — loisirs manuels (bonne réponse : position 3)
  ('11111111-c00e-2100-0000-000000000004', '11111111-c00e-1000-0000-000000000004',
   'Démontrer que l''engouement pour les loisirs manuels n''est qu''une mode télévisée passagère',
   'false', '1'),

  ('11111111-c00e-2200-0000-000000000004', '11111111-c00e-1000-0000-000000000004',
   'Annoncer une révolution des loisirs portée par une nouvelle génération d''artisans professionnels',
   'false', '2'),

  ('11111111-c00e-2300-0000-000000000004', '11111111-c00e-1000-0000-000000000004',
   'Montrer que ce succès répond à un besoin profond de faire de ses mains et d''éprouver un résultat concret',
   'true', '3'),

  ('11111111-c00e-2400-0000-000000000004', '11111111-c00e-1000-0000-000000000004',
   'Regretter que la plupart des inscrits restent de simples amateurs du dimanche',
   'false', '4'),

  -- item 05 — ultra-trail (bonne réponse : position 2)
  ('11111111-c00e-2100-0000-000000000005', '11111111-c00e-1000-0000-000000000005',
   'Les épreuves d''ultra-trail devraient être interdites pour mettre fin aux accidents en montagne',
   'false', '1'),

  ('11111111-c00e-2200-0000-000000000005', '11111111-c00e-1000-0000-000000000005',
   'La massification de l''ultra-trail attire des coureurs trop inexpérimentés, ce qui multiplie les secours en montagne',
   'true', '2'),

  ('11111111-c00e-2300-0000-000000000005', '11111111-c00e-1000-0000-000000000005',
   'Le matériel moderne protège désormais efficacement les coureurs des dangers de la montagne',
   'false', '3'),

  ('11111111-c00e-2400-0000-000000000005', '11111111-c00e-1000-0000-000000000005',
   'Les organisateurs refusent toute mesure de sécurité pour préserver l''esprit de la discipline',
   'false', '4'),

  -- item 06 — jeux de société (bonne réponse : position 4)
  ('11111111-c00e-2100-0000-000000000006', '11111111-c00e-1000-0000-000000000006',
   'Le nombre record de nouveautés publiées chaque année explique à lui seul ce succès',
   'false', '1'),

  ('11111111-c00e-2200-0000-000000000006', '11111111-c00e-1000-0000-000000000006',
   'Les joueurs fréquentent les bars à jeux avant tout pour le plaisir de la compétition',
   'false', '2'),

  ('11111111-c00e-2300-0000-000000000006', '11111111-c00e-1000-0000-000000000006',
   'Les écrans ont fini par marginaliser les jeux de plateau auprès des familles',
   'false', '3'),

  ('11111111-c00e-2400-0000-000000000006', '11111111-c00e-1000-0000-000000000006',
   'Ce succès s''explique d''abord par le besoin de partager un moment de présence réelle',
   'true', '4'),

  -- item 07 — pétanque (bonne réponse : position 1)
  ('11111111-c00e-2100-0000-000000000007', '11111111-c00e-1000-0000-000000000007',
   'Il reconnaît la chute des licences mais conteste l''idée d''un déclin du jeu lui-même',
   'true', '1'),

  ('11111111-c00e-2200-0000-000000000007', '11111111-c00e-1000-0000-000000000007',
   'Il confirme que la pétanque est condamnée à disparaître avec ses derniers licenciés',
   'false', '2'),

  ('11111111-c00e-2300-0000-000000000007', '11111111-c00e-1000-0000-000000000007',
   'Il déplore que les bars à boules dénaturent l''esprit compétitif de la discipline',
   'false', '3'),

  ('11111111-c00e-2400-0000-000000000007', '11111111-c00e-1000-0000-000000000007',
   'Il félicite la fédération d''avoir su attirer la génération des joueurs occasionnels',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c00e-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « sport & loisirs », 7 angles tous différents :
--     spécialisation sportive précoce des enfants / pénurie d'arbitres
--     amateurs (football) / e-sport et statut de sport / boom des loisirs
--     manuels (céramique, tricot, menuiserie) / massification de l'ultra-trail /
--     renouveau des jeux de société / pétanque (licences vs pratique libre).
--     Aucun thème interdit (pas de santé publique, économie, médias, etc.).
-- [x] Textes B2 longs : 202 / 206 / 213 / 205 / 208 / 210 / 206 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (ex. « menacés » ≠ agressés, « matériel dernier cri » inutile face à la
--     météo, JO seulement « éventuels », « c'est très bien ainsi »).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2 (items 1, 5),
--     ce_inference_intention ×3 (items 2, 4, 6), ce_ton_auteur ×2 (items 3, 7).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme linguistique
--     nommé (voix de l'auteur vs discours rapporté, concession corrigée,
--     sur-généralisation, inversion, détail vrai mais secondaire).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (Sofiane, Lormont, Poitiers,
--     Clermont-Ferrand, Brest, Mulhouse — situations et chiffres inventés).
-- ============================================================================
