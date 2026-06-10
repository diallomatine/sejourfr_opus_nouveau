-- ============================================================================
-- V482 — TCF CE B2 — lot 22 (thème : énergie & transition)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~177-202 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : éolien en mer / agrivoltaïsme / relance du nucléaire /
-- hydrogène vert / flexibilité électrique / géothermie / rénovation
-- énergétique des bâtiments.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c016-4000-0000-000000000001', 'TEXTE',
   'Dix ans : c''est le temps qui sépare, en France, la décision de construire un parc éolien en mer de la production de son premier kilowattheure. Nos voisins néerlandais font la même chose en quatre ans. L''écart ne tient ni au vent, ni à la technologie, identiques d''un rivage à l''autre : il tient à l''empilement des procédures, des recours et des autorisations qui jalonnent chaque projet français.

On invoque souvent l''hostilité des pêcheurs pour expliquer ces lenteurs. C''est de moins en moins vrai : sur plusieurs façades maritimes, les comités des pêches négocient désormais le tracé des câbles et les zones de navigation, et obtiennent des compensations qui ont apaisé bien des conflits. Le blocage est ailleurs : sept services de l''État différents interviennent sur un même dossier, sans calendrier commun ni autorité de coordination.

Le gouvernement promet régulièrement de « simplifier ». Mais tant qu''une autorisation unique, délivrée par un guichet unique, ne remplacera pas ce labyrinthe administratif, les objectifs affichés pour 2050 resteront un exercice de communication. L''énergie du large n''attend qu''une chose : que l''État se mette en ordre de marche.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c016-4000-0000-000000000002', 'TEXTE',
   'Des rangées de panneaux solaires surplombant des brebis ou des vignes : l''image, encore exotique il y a cinq ans, se multiplie dans les campagnes. L''agrivoltaïsme — produire de l''électricité au-dessus d''une parcelle qui reste cultivée — séduit les énergéticiens, qui y voient un gisement de foncier considérable, et certains exploitants, auxquels les loyers versés assurent un revenu stable bienvenu.

Le procédé a des vertus réelles : les panneaux protègent les cultures de la grêle et des canicules, et des essais menés dans l''Hérault montrent des rendements maintenus, parfois améliorés, sous les ombrières. Mais l''engouement attire aussi des montages où l''agriculture n''est plus qu''un alibi : quelques moutons loués à l''année pour justifier une centrale au sol, des loyers si élevés qu''ils renchérissent les terres et découragent l''installation de jeunes agriculteurs.

Un décret impose désormais que la production agricole demeure l''activité principale de la parcelle. Encore faudra-t-il des contrôles réels pour le faire respecter. L''agrivoltaïsme mérite mieux qu''un choix binaire entre enthousiasme aveugle et rejet de principe : c''est un outil utile, à condition que l''énergie reste au service du champ, et non l''inverse.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c016-4000-0000-000000000003', 'TEXTE',
   'En annonçant la construction de six nouveaux réacteurs, l''exécutif a relancé un débat que l''on croyait clos. Partisans et adversaires de l''atome ont aussitôt repris leurs arguments rituels : indépendance énergétique et électricité pilotable d''un côté, coût des chantiers et question des déchets de l''autre. Ce débat-là est légitime. Mais il en masque un autre, moins idéologique et plus urgent.

Pendant vingt-cinq ans, la France n''a ouvert aucun chantier nucléaire. Une génération entière de soudeurs spécialisés, de chaudronniers, d''ingénieurs en sûreté est partie à la retraite sans transmettre son savoir-faire. La filière estime qu''il faudra recruter cent mille personnes en dix ans, dans des métiers que plus aucune école ne remplissait. Les retards accumulés sur le chantier finistérien de référence — douze ans au lieu de cinq — tiennent moins aux normes, souvent incriminées, qu''à des gestes industriels qu''il a fallu réapprendre.

Que l''on soit favorable ou non à l''atome importe finalement assez peu : si les compétences manquent, la question sera tranchée par défaut. Avant de débattre du nombre de réacteurs, il faudrait s''assurer que le pays sait encore les construire.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c016-4000-0000-000000000004', 'TEXTE',
   'Il y a quatre ans, l''hydrogène « vert » était présenté comme le pétrole du XXIe siècle : des dizaines de projets d''usines, neuf milliards d''euros d''argent public promis, des discours annonçant des camions, des trains et des avions propulsés à l''eau. Quatre ans plus tard, l''heure est au dégrisement : les trois quarts des projets annoncés en Europe n''ont toujours pas trouvé leur financement, et plusieurs usines pilotes ont fermé faute de clients.

La raison n''a rien de mystérieux. Produire de l''hydrogène par électrolyse exige d''énormes quantités d''électricité décarbonée, déjà disputée par d''autres usages ; le produit final coûte trois à quatre fois plus cher que son équivalent fossile, et presque personne n''accepte de payer la différence. Le transporter et le stocker reste, de surcroît, un casse-tête technique.

Faut-il enterrer la filière ? Non, mais la remettre à sa juste place. Là où l''électrification directe fonctionne — voitures, chauffage, la majorité de l''industrie —, l''hydrogène n''a aucune chance économique. Il demeure en revanche irremplaçable pour quelques usages précis : engrais, sidérurgie, carburants maritimes. C''est en concentrant les moyens publics sur ces niches stratégiques, plutôt qu''en les saupoudrant sur tout et n''importe quoi, que l''hydrogène tiendra enfin une promesse à sa mesure.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c016-4000-0000-000000000005', 'TEXTE',
   'Chaque soir d''hiver, entre dix-neuf et vingt heures, la consommation électrique française bondit : les fours s''allument, les radiateurs montent, les écrans s''ajoutent les uns aux autres. Pour franchir cette pointe, le gestionnaire du réseau mobilise des centrales d''appoint au gaz et des importations coûteuses. Pendant ce temps, à treize heures, les panneaux solaires produisent parfois plus que ce que le pays peut absorber, au point qu''il faut brader ces kilowattheures, voire payer pour s''en débarrasser.

Ce grand écart résume le défi des prochaines années : le problème n''est plus tant de produire de l''électricité décarbonée que de la consommer au bon moment. Or les solutions existent et n''ont rien de futuriste. Le simple décalage automatique des chauffe-eau vers les heures solaires, expérimenté auprès de trois cent mille foyers volontaires, a effacé l''équivalent d''une demi-tranche nucléaire à la pointe du soir, sans le moindre inconfort pour les intéressés.

Recharger sa voiture la nuit, lancer son lave-linge à midi, accepter qu''un signal pilote le ballon d''eau chaude : ces gestes minuscules, multipliés par des millions de foyers, pèsent davantage que bien des chantiers pharaoniques. La transition ne se jouera pas seulement dans les centrales ; elle se jouera aussi, plus discrètement, dans nos compteurs.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c016-4000-0000-000000000006', 'TEXTE',
   'Sous les pieds des habitants de la région parisienne dort une nappe d''eau à soixante-dix degrés, exploitée depuis les années mille neuf cent quatre-vingt par une cinquantaine de réseaux de chaleur. Des dizaines de milliers de logements, des hôpitaux, des piscines sont ainsi chauffés sans flamme ni fumée, à un prix remarquablement stable. La géothermie est sans doute la seule énergie renouvelable dont personne ne conteste ni l''empreinte ni le paysage : elle est invisible.

Pourquoi, alors, reste-t-elle si marginale ? D''abord parce qu''un forage coûte cher au départ — plusieurs millions d''euros engagés avant de savoir précisément ce que la roche donnera —, un risque que peu de collectivités acceptent seules. Ensuite parce qu''elle ne bénéficie d''aucun lobby : pas de turbines à vendre, pas de panneaux à exporter, peu d''industriels pour la défendre dans les ministères. La chaleur, enfin, est le parent pauvre des politiques énergétiques, obsédées par l''électricité alors que se chauffer représente près de la moitié de l''énergie consommée dans le pays.

Un fonds de garantie couvrant le risque géologique existe pourtant, et chaque forage réussi rembourse la collectivité en quelques années. Le gisement est là, les techniques sont mûres. Il ne manque que ce qui fait avancer les autres filières : des porte-voix.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c016-4000-0000-000000000007', 'TEXTE',
   'Le gisement le plus rentable de la transition énergétique ne se trouve ni en mer ni sous terre : c''est l''énergie que nous gaspillons. Les bâtiments mal isolés engloutissent chaque hiver des térawattheures entiers, et l''État consacre désormais plusieurs milliards d''euros par an à aider les ménages à isoler murs et combles ou à remplacer leurs vieilles chaudières.

Sur le terrain, pourtant, le compte n''y est pas. À Mulhouse, Awa et Bertrand ont renoncé après huit mois de démarches : trois plateformes différentes, des devis à refaire, un dossier rejeté pour une pièce manquante jamais réclamée auparavant. Leur cas n''a rien d''isolé : un tiers des dossiers engagés sont abandonnés en cours de route, et les fraudes d''entreprises peu scrupuleuses, largement médiatisées, achèvent de semer la méfiance. Résultat paradoxal : une partie des crédits votés n''est même pas dépensée, pendant que les passoires énergétiques continuent de chauffer les rues.

Le problème n''est donc plus budgétaire, il est bureaucratique. Un interlocuteur unique, des règles stables d''une année sur l''autre, des artisans certifiés contrôlés sérieusement : voilà qui ferait plus pour les économies d''énergie que la prochaine rallonge financière annoncée en grande pompe.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c016-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c016-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale défendue par l''auteur ?',
   'L''auteur conclut que sans « autorisation unique, délivrée par un guichet unique », les objectifs resteront « un exercice de communication » : **sa thèse est que le retard de l''éolien en mer vient du labyrinthe administratif, qu''il faut simplifier**. La réponse A reprend le détail-piège : l''hostilité des pêcheurs est précisément relativisée (« C''est de moins en moins vrai », des compensations ont apaisé les conflits). La réponse C contredit le texte : vent et technologie sont « identiques d''un rivage à l''autre ». La réponse D déforme les faits : les cinquante parcs sont un objectif pour 2050, pas un acquis. Mécanisme : distinguer la **thèse défendue** du faux coupable écarté par l''auteur.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c016-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c016-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Quelle est l''intention principale de l''auteur de ce texte ?',
   'L''auteur refuse le « choix binaire entre enthousiasme aveugle et rejet de principe » et pose sa condition : « que l''énergie reste au service du champ, et non l''inverse ». **Son intention est de défendre un agrivoltaïsme strictement encadré, subordonné à l''activité agricole.** La réponse A contredit un détail explicite : les essais de l''Hérault montrent des rendements « maintenus, parfois améliorés ». La réponse B sur-étend un détail secondaire : les loyers stables sont mentionnés, mais l''auteur dénonce justement leurs dérives spéculatives. La réponse C est la sur-généralisation inverse : il ne réclame aucune interdiction, il valide « un outil utile ». Mécanisme : **inférence d''intention** à partir d''une structure concessive (vertus réelles… mais… à condition que).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c016-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c016-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Comment l''auteur se positionne-t-il dans le débat sur la relance du nucléaire ?',
   'L''auteur écrit : « Que l''on soit favorable ou non à l''atome importe finalement assez peu » — **il ne prend pas parti et déplace le débat vers la pénurie de compétences industrielles** (cent mille recrutements, savoir-faire parti à la retraite). La réponse B lui attribue un argument qu''il rapporte au discours indirect : l''indépendance énergétique est l''argument « rituel » des partisans, pas le sien. La réponse C inverse une précision du texte : les retards tiennent « moins aux normes, souvent incriminées, qu''à des gestes industriels qu''il a fallu réapprendre ». La réponse D déforme l''ouverture : le débat « que l''on croyait clos » vient justement d''être relancé. Mécanisme : repérer le **déplacement de problématique** opéré par l''auteur, contre des arguments rapportés.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c016-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c016-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'L''auteur répond lui-même à sa question rhétorique : « Faut-il enterrer la filière ? Non, mais la remettre à sa juste place », en concentrant les moyens sur « ces niches stratégiques » (engrais, sidérurgie, carburants maritimes). **L''idée principale est de réserver l''hydrogène aux usages où il est irremplaçable.** La réponse A sur-généralise le constat d''échec en condamnation totale, que le « Non » du texte écarte explicitement. La réponse B inverse le propos : là où l''électrification directe fonctionne (voitures, chauffage), l''hydrogène « n''a aucune chance économique ». La réponse D contredit un chiffre clé : les trois quarts des projets « n''ont toujours pas trouvé leur financement ». Mécanisme : identifier la **position nuancée** entre deux distracteurs en sur-généralisation et en inversion.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c016-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c016-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur la transition électrique ?',
   'Le texte pose que « le problème n''est plus tant de produire de l''électricité décarbonée que de la consommer au bon moment », et conclut que ces gestes « pèsent davantage que bien des chantiers pharaoniques » : **déplacer les consommations est devenu un levier aussi décisif que la production**. La réponse A inverse cette idée centrale : le texte ne déplore pas un manque de production, mais un décalage temporel. La réponse C contredit un détail explicite : l''expérimentation s''est faite « sans le moindre inconfort pour les intéressés ». La réponse D inverse le détail-piège de la mi-journée : à treize heures, le solaire produit parfois **trop**, au point de devoir brader les kilowattheures. Mécanisme : **inférence de l''idée-force** face à des distracteurs en inversion cause/effet.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c016-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c016-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur sur la géothermie ?',
   'Tout le texte valorise la filière (« Le gisement est là, les techniques sont mûres ») et conclut qu''il ne manque « que des porte-voix » : **l''auteur plaide pour une énergie fiable et mûre, marginalisée faute de relais et de visibilité** (aucun lobby, parent pauvre des politiques). La réponse A retourne le détail-piège : le coût initial des forages est cité, mais un fonds de garantie existe et « chaque forage réussi rembourse la collectivité en quelques années ». La réponse B contredit frontalement le texte : la géothermie est « invisible », personne ne conteste son paysage. La réponse C inverse la critique de l''auteur, qui reproche aux politiques d''être « obsédées par l''électricité » alors que la chaleur pèse près de la moitié de l''énergie consommée. Mécanisme : **ton de l''auteur** — plaidoyer repérable aux jugements mélioratifs et à la chute.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c016-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c016-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Que cherche à montrer l''auteur de ce texte ?',
   'La conclusion est explicite : « Le problème n''est donc plus budgétaire, il est bureaucratique » — **la rénovation énergétique bute désormais sur la complexité des démarches plus que sur le manque d''argent** (un tiers des dossiers abandonnés, crédits non dépensés). La réponse B inverse la thèse : réclamer une rallonge financière est précisément ce que l''auteur juge inutile, puisque les crédits existants ne sont « même pas dépensés ». La réponse C sur-généralise un détail secondaire : les fraudes sont le fait d''« entreprises peu scrupuleuses », pas de la majorité. La réponse D contredit l''exemple : Awa et Bertrand « ont renoncé » après huit mois, ils n''ont rien obtenu. Mécanisme : **inférence de la conséquence implicite** (paradoxe budgétaire), contre un distracteur en inversion et un détail promu à tort.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — éolien en mer (bonne réponse : position 2)
  ('11111111-c016-2100-0000-000000000001', '11111111-c016-1000-0000-000000000001',
   'L''opposition des pêcheurs reste le principal obstacle aux parcs éoliens en mer',
   'false', '1'),

  ('11111111-c016-2200-0000-000000000001', '11111111-c016-1000-0000-000000000001',
   'La lenteur de l''éolien en mer français tient d''abord au maquis administratif, qu''il faut simplifier',
   'true', '2'),

  ('11111111-c016-2300-0000-000000000001', '11111111-c016-1000-0000-000000000001',
   'Les Pays-Bas bénéficient de vents et de technologies plus favorables que la France',
   'false', '3'),

  ('11111111-c016-2400-0000-000000000001', '11111111-c016-1000-0000-000000000001',
   'La France a déjà atteint l''objectif de cinquante parcs éoliens fixé pour 2050',
   'false', '4'),

  -- item 02 — agrivoltaïsme (bonne réponse : position 4)
  ('11111111-c016-2100-0000-000000000002', '11111111-c016-1000-0000-000000000002',
   'Démontrer que les panneaux solaires dégradent systématiquement les rendements agricoles',
   'false', '1'),

  ('11111111-c016-2200-0000-000000000002', '11111111-c016-1000-0000-000000000002',
   'Encourager les agriculteurs à louer leurs terres aux énergéticiens pour sécuriser leurs revenus',
   'false', '2'),

  ('11111111-c016-2300-0000-000000000002', '11111111-c016-1000-0000-000000000002',
   'Réclamer l''interdiction des centrales solaires sur les terres cultivées',
   'false', '3'),

  ('11111111-c016-2400-0000-000000000002', '11111111-c016-1000-0000-000000000002',
   'Défendre un agrivoltaïsme strictement encadré, où l''électricité reste au service de l''agriculture',
   'true', '4'),

  -- item 03 — relance du nucléaire (bonne réponse : position 1)
  ('11111111-c016-2100-0000-000000000003', '11111111-c016-1000-0000-000000000003',
   'Il ne tranche pas entre partisans et adversaires, mais alerte sur la pénurie de compétences industrielles',
   'true', '1'),

  ('11111111-c016-2200-0000-000000000003', '11111111-c016-1000-0000-000000000003',
   'Il défend la construction des six réacteurs au nom de l''indépendance énergétique',
   'false', '2'),

  ('11111111-c016-2300-0000-000000000003', '11111111-c016-1000-0000-000000000003',
   'Il attribue les retards des chantiers à l''excès de normes de sûreté',
   'false', '3'),

  ('11111111-c016-2400-0000-000000000003', '11111111-c016-1000-0000-000000000003',
   'Il estime que le débat sur le nucléaire est désormais définitivement clos',
   'false', '4'),

  -- item 04 — hydrogène vert (bonne réponse : position 3)
  ('11111111-c016-2100-0000-000000000004', '11111111-c016-1000-0000-000000000004',
   'La filière hydrogène doit être abandonnée, faute de toute perspective économique',
   'false', '1'),

  ('11111111-c016-2200-0000-000000000004', '11111111-c016-1000-0000-000000000004',
   'L''hydrogène remplacera bientôt l''électricité dans les voitures et le chauffage',
   'false', '2'),

  ('11111111-c016-2300-0000-000000000004', '11111111-c016-1000-0000-000000000004',
   'L''hydrogène vert doit être réservé aux quelques usages où il est réellement irremplaçable',
   'true', '3'),

  ('11111111-c016-2400-0000-000000000004', '11111111-c016-1000-0000-000000000004',
   'Les financements publics promis ont permis à la plupart des projets européens d''aboutir',
   'false', '4'),

  -- item 05 — flexibilité électrique (bonne réponse : position 2)
  ('11111111-c016-2100-0000-000000000005', '11111111-c016-1000-0000-000000000005',
   'La France manque structurellement de moyens de production d''électricité décarbonée',
   'false', '1'),

  ('11111111-c016-2200-0000-000000000005', '11111111-c016-1000-0000-000000000005',
   'Déplacer les consommations vers les bons moments est devenu un levier aussi décisif que la production',
   'true', '2'),

  ('11111111-c016-2300-0000-000000000005', '11111111-c016-1000-0000-000000000005',
   'Le pilotage automatique des chauffe-eau a imposé un inconfort notable aux foyers participants',
   'false', '3'),

  ('11111111-c016-2400-0000-000000000005', '11111111-c016-1000-0000-000000000005',
   'Les panneaux solaires produisent trop peu pour couvrir la consommation de la mi-journée',
   'false', '4'),

  -- item 06 — géothermie (bonne réponse : position 4)
  ('11111111-c016-2100-0000-000000000006', '11111111-c016-1000-0000-000000000006',
   'Il juge le risque géologique trop élevé pour que les collectivités s''y engagent',
   'false', '1'),

  ('11111111-c016-2200-0000-000000000006', '11111111-c016-1000-0000-000000000006',
   'Il reproche à la géothermie de défigurer les paysages comme les autres énergies renouvelables',
   'false', '2'),

  ('11111111-c016-2300-0000-000000000006', '11111111-c016-1000-0000-000000000006',
   'Il estime que l''électricité doit rester la priorité absolue des politiques énergétiques',
   'false', '3'),

  ('11111111-c016-2400-0000-000000000006', '11111111-c016-1000-0000-000000000006',
   'Il plaide pour une filière mûre et fiable, marginalisée surtout faute de relais et de visibilité',
   'true', '4'),

  -- item 07 — rénovation énergétique (bonne réponse : position 1)
  ('11111111-c016-2100-0000-000000000007', '11111111-c016-1000-0000-000000000007',
   'Que la rénovation énergétique bute désormais sur la complexité des démarches plus que sur le manque d''argent',
   'true', '1'),

  ('11111111-c016-2200-0000-000000000007', '11111111-c016-1000-0000-000000000007',
   'Que l''État doit augmenter d''urgence les budgets consacrés à la rénovation des bâtiments',
   'false', '2'),

  ('11111111-c016-2300-0000-000000000007', '11111111-c016-1000-0000-000000000007',
   'Que la majorité des entreprises de rénovation pratiquent la fraude aux aides publiques',
   'false', '3'),

  ('11111111-c016-2400-0000-000000000007', '11111111-c016-1000-0000-000000000007',
   'Qu''Awa et Bertrand ont fini par obtenir leur aide au terme de huit mois de démarches',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c016-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « énergie & transition », 7 angles tous différents :
--     éolien en mer (procédures) / agrivoltaïsme (terres agricoles) /
--     relance du nucléaire (compétences industrielles) / hydrogène vert
--     (promesses vs réalité) / flexibilité électrique (pilotage de la
--     demande) / géothermie (réseaux de chaleur) / rénovation énergétique
--     (complexité des aides). Aucun thème interdit traité comme sujet.
-- [x] Textes B2 longs : 182 / 179 / 177 / 197 / 199 / 202 / 186 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (pêcheurs apaisés, rendements améliorés, « moins aux normes »,
--     « Non, mais », solaire excédentaire à midi, fonds de garantie,
--     crédits non dépensés).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2 (items 1, 4),
--     ce_inference_intention ×3 (items 2, 5, 7), ce_ton_auteur ×2 (items 3, 6).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme linguistique
--     nommé (concession, inversion cause/effet, inférence d'intention,
--     détail secondaire, sur-généralisation, déplacement de problématique).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (prénoms, villes, chiffres inventés).
-- ============================================================================
