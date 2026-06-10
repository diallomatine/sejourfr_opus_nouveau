-- ============================================================================
-- V471 — TCF CE B2 — lot 11 (thème : logement)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~185-197 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : encadrement des loyers / logements vacants / coliving des
-- trentenaires / bail réel solidaire / habitat participatif / permis de
-- louer & habitat indigne / logement étudiant.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c00b-4000-0000-000000000001', 'TEXTE',
   'Sept ans après son retour dans plusieurs grandes villes, l''encadrement des loyers continue de diviser. Ses partisans rappellent qu''à Lille ou à Bordeaux, la hausse des loyers a nettement ralenti depuis son entrée en vigueur. Ses adversaires rétorquent qu''un bailleur sur trois ne respecte tout simplement pas les plafonds, et que les contrôles restent rares.

Les deux camps ont raison, et c''est bien le problème. Oui, le dispositif protège les locataires en place contre les hausses les plus brutales : les études convergent sur ce point. Mais non, il ne fait pas apparaître un seul logement supplémentaire. Or la flambée des loyers n''est pas une maladie : c''est le symptôme d''une pénurie. Quand cent candidats se disputent un deux-pièces, plafonner le prix ne supprime pas la file d''attente, il en change seulement l''ordre.

Faut-il pour autant abandonner l''encadrement ? Ce serait absurde : on ne jette pas un pare-feu sous prétexte qu''il n''éteint pas l''incendie. Mais le présenter comme la solution à la crise du logement relève de l''illusion. Tant que l''on ne construira pas davantage là où les gens veulent vivre, l''encadrement restera ce qu''il est : un médicament contre la douleur, pas contre la maladie.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00b-4000-0000-000000000002', 'TEXTE',
   'Trois millions de logements vides, deux millions de ménages en attente d''un toit : l''équation semble si simple qu''elle revient à chaque débat sur la crise du logement. Il suffirait, entend-on, de remplir les uns avec les autres. À Vesoul, pourtant, l''adjointe au logement Sabine Okonkwo sourit tristement de cette arithmétique : sa ville compte des centaines d''appartements vacants… et presque personne pour les vouloir.

C''est là le malentendu central : la vacance ne se trouve pas là où s''exerce la demande. Elle se concentre dans des villes moyennes et des bourgs en perte d''habitants, où les biens vides sont souvent vétustes, mal situés, hérités de successions interminables ou nécessitant des travaux que leurs propriétaires, parfois âgés, ne peuvent financer. Dans les métropoles où l''on s''arrache le moindre studio, la vacance réelle est au contraire très faible.

La taxe sur les logements vacants, régulièrement durcie, n''y change pas grand-chose : on ne taxe pas un propriétaire vers une demande qui n''existe pas. Cela ne signifie pas qu''il faille renoncer à mobiliser ce parc — il peut accompagner la revitalisation des centres anciens. Mais en faire la clé de la crise du logement, c''est confondre un gisement avec une solution.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00b-4000-0000-000000000003', 'TEXTE',
   'Cuisines partagées « conviviales », salles de sport intégrées, communauté « comme une famille » : les résidences de coliving qui fleurissent à Montpellier ou à Rennes vendent la colocation comme un art de vivre. Leurs brochures montrent des trentenaires épanouis autour d''un brunch, et leurs fondateurs parlent de « révolution de l''habitat ».

Reconnaissons-leur un mérite : certains résidents y trouvent réellement leur compte, notamment les nouveaux arrivants dans une ville où ils ne connaissent personne. Il serait malhonnête de nier ces parcours heureux.

Mais que l''on ne nous fasse pas prendre une contrainte pour un choix. Si la part des actifs de trente à trente-neuf ans vivant en colocation a doublé en dix ans, ce n''est pas parce qu''une génération entière a soudain découvert les joies du frigo commun. C''est parce qu''un salaire moyen ne permet plus de louer seul un deux-pièces dans la plupart des grandes villes. Le coliving ne révolutionne rien : il monétise une pénurie, en facturant au prix fort — souvent plus cher au mètre carré qu''une location classique — l''impossibilité de se loger autrement. Habiller cette réalité en « expérience communautaire », c''est faire du marketing avec la crise du logement.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00b-4000-0000-000000000004', 'TEXTE',
   'Devenir propriétaire de son appartement sans jamais acheter le terrain sur lequel il est construit : c''est le principe du bail réel solidaire, un dispositif encore confidentiel qui commence à changer la donne dans quelques villes. Le mécanisme est simple : un organisme foncier solidaire conserve la propriété du sol, et le ménage n''achète que les murs, moyennant une modeste redevance mensuelle. Résultat : des prix inférieurs de trente à quarante pour cent à ceux du marché, dans des quartiers ordinairement inaccessibles aux revenus moyens.

À Angers, Naïma et Théo, infirmière et chauffeur-livreur, ont ainsi acquis un trois-pièces qu''ils n''auraient jamais pu s''offrir autrement. La contrepartie existe : plafonds de ressources à l''entrée, prix de revente encadré pour que le logement reste abordable pour le ménage suivant. On ne s''enrichit pas avec un bail réel solidaire ; on s''y loge.

Reste que le dispositif demeure une goutte d''eau : quelques milliers de logements par an, quand il en faudrait dix fois plus. Les organismes fonciers manquent de terrains, les notaires connaissent mal la formule, et bien des candidats à l''achat ignorent jusqu''à son existence. Une bonne idée ne suffit pas : encore faut-il lui donner les moyens de changer d''échelle.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00b-4000-0000-000000000005', 'TEXTE',
   'L''image colle à la peau de l''habitat participatif : des militants en sandales décidant en assemblée de la couleur des volets. La réalité de la résidence des Tisserands, livrée l''an dernier à Strasbourg, est plus prosaïque : dix-huit ménages — enseignants, artisans, retraités — qui ont conçu ensemble leur immeuble, mutualisé une buanderie, deux chambres d''amis et un atelier, et économisé environ quinze pour cent par rapport à un achat classique, en se passant de promoteur.

Le modèle séduit au-delà des cercles convaincus : les demandes de renseignement ont triplé en cinq ans auprès des associations spécialisées, et plusieurs bailleurs sociaux intègrent désormais des logements participatifs dans leurs programmes.

Il faut pourtant le dire à ceux qui rêvent : l''aventure se mérite. Quatre à six ans de réunions entre la première rencontre et la remise des clés, des décisions collectives parfois éprouvantes, des départs en cours de route. Les groupes qui aboutissent sont ceux qui ont accepté de se doter de règles précises et, souvent, de se faire accompagner par des professionnels. L''habitat participatif n''est ni une utopie ni un long fleuve tranquille : c''est une troisième voie sérieuse, à condition d''en mesurer le coût humain.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00b-4000-0000-000000000006', 'TEXTE',
   'Dans certains immeubles du centre de Perpignan ou de Maubeuge, on loue encore, en 2026, des chambres sans fenêtre à des familles entières. Huit cents euros par mois pour vingt mètres carrés moisis : le commerce de la misère a ses tarifs, et ils ne baissent pas.

Depuis quelques années, des communes peuvent exiger un « permis de louer » : avant toute mise en location dans les quartiers concernés, le propriétaire doit faire contrôler son bien. Sur le papier, l''idée est imparable — on inspecte bien les restaurants avant de les laisser servir. Et là où le dispositif est appliqué avec sérieux, les premiers résultats sont réels : des centaines de logements refusés à la location, des travaux imposés.

Mais regardons les chiffres en face. Les services municipaux chargés des contrôles tiennent souvent en deux agents ; les amendes plafonnent à des montants qu''un marchand de sommeil amortit en quelques mois de loyers ; et rien n''empêche un bailleur retoqué de relouer discrètement, le contrôle suivant n''arrivant jamais. Un outil pertinent appliqué avec des moyens dérisoires ne fait pas une politique : il fait un alibi. Les locataires des taudis méritent mieux qu''une bonne intention sous-financée.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00b-4000-0000-000000000007', 'TEXTE',
   'Chaque été, le même rituel : des files de jeunes gens devant les agences de Lorient ou de Poitiers, dossiers sous le bras, parents garants en renfort. Trouver un studio est devenu, pour beaucoup d''étudiants, une épreuve plus sélective que n''importe quel concours.

Les chiffres expliquent la cohue : le pays compte environ trois millions d''étudiants, pour à peine deux cent quarante mille places en résidences publiques à loyer modéré. Tous les autres se débrouillent : studios privés dont les loyers ont augmenté deux fois plus vite que l''ensemble du marché en dix ans, chambres chez l''habitant, trajets quotidiens de deux heures depuis le domicile familial. Les plans gouvernementaux successifs promettent des dizaines de milliers de places nouvelles ; les livraisons effectives, elles, se comptent chaque année en milliers.

Conséquence silencieuse, que documentent désormais plusieurs enquêtes : un bachelier sur cinq dit avoir renoncé à la formation de son choix parce qu''il était impossible de se loger dans la ville où elle se trouvait. La pénurie ne se contente donc pas de grever les budgets : elle décide, à la place des jeunes, de ce qu''ils feront de leur vie. Il est rare qu''une crise du logement choisisse si directement l''avenir des gens.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c00b-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00b-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale défendue par l''auteur ?',
   'L''auteur conclut que l''encadrement est « un médicament contre la douleur, pas contre la maladie » : **il protège les locataires mais ne peut pas résoudre une crise née de la pénurie de logements**. La réponse A inverse le propos : le texte ne dit jamais que l''encadrement aggrave la pénurie, seulement qu''il ne la résout pas. La réponse C promeut en idée principale un **détail vrai mais secondaire** : le non-respect des plafonds est l''argument des adversaires, rapporté au discours indirect, pas la thèse de l''auteur. La réponse D contredit la concession explicite : abandonner l''encadrement « serait absurde ». Mécanisme testé : dégager une **thèse nuancée** (utile mais insuffisant) face à des distracteurs en inversion et en sur-promotion de détail.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c00b-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00b-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur les logements vacants ?',
   'Le texte pose le « malentendu central : la vacance ne se trouve pas là où s''exerce la demande ». **Les logements vides sont concentrés dans des territoires en perte d''habitants, où presque personne ne veut s''installer**, ce que la bonne réponse reformule. La réponse A invente une intention spéculative : le texte décrit au contraire une vacance souvent subie (successions, travaux trop lourds, propriétaires âgés). La réponse B contredit un passage explicite : la taxe « n''y change pas grand-chose ». La réponse C reprend l''argument que l''auteur réfute — « Il suffirait, entend-on » est un **discours rapporté**, immédiatement démonté par l''exemple de Vesoul. Mécanisme : distinguer la thèse de l''auteur de l''**opinion rapportée** qu''il critique.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c00b-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00b-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Comment l''auteur juge-t-il le discours des résidences de coliving ?',
   'L''auteur concède d''abord un mérite (« certains résidents y trouvent réellement leur compte »), puis retourne la concession : « que l''on ne nous fasse pas prendre une contrainte pour un choix », jusqu''à la chute « faire du marketing avec la crise du logement ». **Sa position : le coliving habille commercialement une contrainte économique, même si quelques parcours heureux existent.** La réponse B inverse le ton : il ne salue aucune « révolution », il la démonte. La réponse C est une **sur-généralisation** qui efface la concession sur les résidents satisfaits. La réponse D inverse un détail explicite : le coliving est facturé « souvent plus cher au mètre carré qu''une location classique ». Mécanisme : repérer la **concession rhétorique** (reconnaissons… mais) qui prépare la critique.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c00b-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00b-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'Le texte présente le mécanisme (« le ménage n''achète que les murs ») puis sa limite (« le dispositif demeure une goutte d''eau ») : **l''idée principale associe l''intérêt du bail réel solidaire — une accession abordable par dissociation du terrain et du logement — et son caractère encore marginal**. La réponse A contredit le mécanisme : le ménage n''achète jamais le terrain, l''organisme foncier en « conserve la propriété ». La réponse B détourne un détail : la revente encadrée est présentée comme une contrepartie assumée, pas comme un repoussoir, et rien n''indique qu''elle décourage les candidats. La réponse D contredit une phrase explicite : « On ne s''enrichit pas avec un bail réel solidaire ; on s''y loge ». Mécanisme : synthétiser **mécanisme + limite** sans céder au contresens ni au détail détourné.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c00b-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00b-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Quelle est l''intention principale de l''auteur ?',
   'La conclusion résume l''intention : l''habitat participatif « n''est ni une utopie ni un long fleuve tranquille : c''est une troisième voie sérieuse, à condition d''en mesurer le coût humain ». **L''auteur veut le présenter comme une option crédible, débarrassée des clichés, mais exigeante.** La réponse A inverse l''intention : décrire les difficultés (« l''aventure se mérite ») sert à préparer les candidats, pas à les dissuader. La réponse C promeut un **détail secondaire** : l''économie d''environ quinze pour cent n''est qu''un élément de la description, pas le cœur du propos. La réponse D est une sur-généralisation : le texte note que des bailleurs sociaux intègrent ce modèle, jamais qu''il remplacerait la promotion classique. Mécanisme : **inférence d''intention** à partir d''un mouvement en deux temps (séduction du modèle / exigences réelles).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c00b-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00b-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur sur le permis de louer ?',
   'L''auteur valide le principe (« Sur le papier, l''idée est imparable ») et reconnaît des « premiers résultats réels », avant de basculer : « Mais regardons les chiffres en face » — deux agents, amendes amorties en quelques mois, absence de second contrôle — jusqu''au verdict : « il fait un alibi ». **Sa position : un outil pertinent, vidé de sa portée par des moyens dérisoires.** La réponse A sur-généralise les « premiers résultats » : rien n''indique la disparition des marchands de sommeil, le texte décrit l''inverse. La réponse B inverse le jugement : il ne conteste jamais le principe ni ne demande l''abandon du dispositif. La réponse C contredit un passage explicite : les amendes sont amorties « en quelques mois de loyers ». Mécanisme : articulation **concession / réfutation** (l''idée est bonne, MAIS les moyens manquent).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c00b-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00b-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Quelle conclusion l''auteur tire-t-il de la pénurie de logements étudiants ?',
   'La conclusion du texte dépasse la question financière : la pénurie « décide, à la place des jeunes, de ce qu''ils feront de leur vie », un bachelier sur cinq ayant renoncé à la formation de son choix faute de logement. **La bonne réponse reformule cette conséquence implicite : la crise du logement en vient à dicter l''orientation d''une partie des jeunes.** La réponse B contredit les chiffres : deux cent quarante mille places publiques pour trois millions d''étudiants, la majorité se loge ailleurs. La réponse C contredit un détail explicite : les loyers étudiants ont augmenté « deux fois plus vite que l''ensemble du marché ». La réponse D inverse promesses et réalité : les plans promettent des dizaines de milliers de places, les livraisons « se comptent chaque année en milliers ». Mécanisme : **inférence de conséquence** — relier le chiffre-clé à la portée que l''auteur lui donne.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — encadrement des loyers (bonne réponse : position 2)
  ('11111111-c00b-2100-0000-000000000001', '11111111-c00b-1000-0000-000000000001',
   'L''encadrement des loyers a aggravé la pénurie de logements dans les grandes villes',
   'false', '1'),

  ('11111111-c00b-2200-0000-000000000001', '11111111-c00b-1000-0000-000000000001',
   'L''encadrement protège les locataires mais ne peut pas résoudre une crise née de la pénurie',
   'true', '2'),

  ('11111111-c00b-2300-0000-000000000001', '11111111-c00b-1000-0000-000000000001',
   'Le non-respect des plafonds par un bailleur sur trois rend le dispositif inapplicable',
   'false', '3'),

  ('11111111-c00b-2400-0000-000000000001', '11111111-c00b-1000-0000-000000000001',
   'Il faut abandonner l''encadrement des loyers et miser uniquement sur la construction',
   'false', '4'),

  -- item 02 — logements vacants (bonne réponse : position 4)
  ('11111111-c00b-2100-0000-000000000002', '11111111-c00b-1000-0000-000000000002',
   'Les propriétaires laissent leurs biens vides pour spéculer sur la hausse des prix',
   'false', '1'),

  ('11111111-c00b-2200-0000-000000000002', '11111111-c00b-1000-0000-000000000002',
   'La taxe sur la vacance a permis de remettre la plupart des biens vides sur le marché',
   'false', '2'),

  ('11111111-c00b-2300-0000-000000000002', '11111111-c00b-1000-0000-000000000002',
   'Remplir les logements vides suffirait à loger les ménages en attente d''un toit',
   'false', '3'),

  ('11111111-c00b-2400-0000-000000000002', '11111111-c00b-1000-0000-000000000002',
   'Les logements vides se concentrent surtout là où la demande de logements est faible',
   'true', '4'),

  -- item 03 — coliving (bonne réponse : position 1)
  ('11111111-c00b-2100-0000-000000000003', '11111111-c00b-1000-0000-000000000003',
   'Il y voit l''habillage commercial d''une contrainte économique, malgré quelques parcours heureux',
   'true', '1'),

  ('11111111-c00b-2200-0000-000000000003', '11111111-c00b-1000-0000-000000000003',
   'Il salue une innovation qui réinvente en profondeur l''habitat des jeunes actifs',
   'false', '2'),

  ('11111111-c00b-2300-0000-000000000003', '11111111-c00b-1000-0000-000000000003',
   'Il estime que la colocation est vécue comme une contrainte par tous les résidents',
   'false', '3'),

  ('11111111-c00b-2400-0000-000000000003', '11111111-c00b-1000-0000-000000000003',
   'Il souligne que le coliving revient moins cher qu''une location classique',
   'false', '4'),

  -- item 04 — bail réel solidaire (bonne réponse : position 3)
  ('11111111-c00b-2100-0000-000000000004', '11111111-c00b-1000-0000-000000000004',
   'Le bail réel solidaire permet aux ménages d''acheter le terrain à prix réduit',
   'false', '1'),

  ('11111111-c00b-2200-0000-000000000004', '11111111-c00b-1000-0000-000000000004',
   'L''encadrement du prix de revente décourage la plupart des candidats à l''accession',
   'false', '2'),

  ('11111111-c00b-2300-0000-000000000004', '11111111-c00b-1000-0000-000000000004',
   'Un dispositif rend l''accession abordable en dissociant terrain et logement, mais reste marginal',
   'true', '3'),

  ('11111111-c00b-2400-0000-000000000004', '11111111-c00b-1000-0000-000000000004',
   'Le bail réel solidaire offre aux ménages modestes un placement immobilier rentable',
   'false', '4'),

  -- item 05 — habitat participatif (bonne réponse : position 2)
  ('11111111-c00b-2100-0000-000000000005', '11111111-c00b-1000-0000-000000000005',
   'Dissuader les ménages de se lancer dans un projet d''habitat participatif',
   'false', '1'),

  ('11111111-c00b-2200-0000-000000000005', '11111111-c00b-1000-0000-000000000005',
   'Présenter l''habitat participatif comme une voie crédible, à condition d''en accepter les exigences',
   'true', '2'),

  ('11111111-c00b-2300-0000-000000000005', '11111111-c00b-1000-0000-000000000005',
   'Montrer que l''habitat participatif sert avant tout à réduire le coût d''achat',
   'false', '3'),

  ('11111111-c00b-2400-0000-000000000005', '11111111-c00b-1000-0000-000000000005',
   'Prouver que ce modèle peut remplacer la promotion immobilière classique',
   'false', '4'),

  -- item 06 — permis de louer (bonne réponse : position 4)
  ('11111111-c00b-2100-0000-000000000006', '11111111-c00b-1000-0000-000000000006',
   'Il considère que les contrôles ont fait disparaître les marchands de sommeil',
   'false', '1'),

  ('11111111-c00b-2200-0000-000000000006', '11111111-c00b-1000-0000-000000000006',
   'Il juge le dispositif mauvais par principe et demande son abandon',
   'false', '2'),

  ('11111111-c00b-2300-0000-000000000006', '11111111-c00b-1000-0000-000000000006',
   'Il estime que les amendes actuelles suffisent à dissuader les bailleurs indélicats',
   'false', '3'),

  ('11111111-c00b-2400-0000-000000000006', '11111111-c00b-1000-0000-000000000006',
   'Il approuve le principe mais dénonce des moyens si faibles qu''ils le réduisent à un alibi',
   'true', '4'),

  -- item 07 — logement étudiant (bonne réponse : position 1)
  ('11111111-c00b-2100-0000-000000000007', '11111111-c00b-1000-0000-000000000007',
   'La pénurie de logements en vient à dicter l''orientation d''une partie des jeunes',
   'true', '1'),

  ('11111111-c00b-2200-0000-000000000007', '11111111-c00b-1000-0000-000000000007',
   'Les résidences publiques à loyer modéré accueillent désormais la majorité des étudiants',
   'false', '2'),

  ('11111111-c00b-2300-0000-000000000007', '11111111-c00b-1000-0000-000000000007',
   'Les loyers des studios étudiants évoluent au même rythme que le reste du marché',
   'false', '3'),

  ('11111111-c00b-2400-0000-000000000007', '11111111-c00b-1000-0000-000000000007',
   'Les plans gouvernementaux ont comblé l''essentiel du déficit de places',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c00b-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « logement », 7 angles tous différents :
--     encadrement des loyers / logements vacants / coliving des trentenaires /
--     bail réel solidaire / habitat participatif / permis de louer & habitat
--     indigne / logement étudiant. Aucun thème interdit (pas d'angle
--     énergie, ville & mobilité, tourisme ou générations).
-- [x] Textes B2 longs : 192 / 194 / 185 / 193 / 189 / 188 / 197 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (ex. « plus cher au mètre carré », « premiers résultats réels »,
--     promesses vs livraisons, taxe « régulièrement durcie »).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2 (items 1, 4),
--     ce_inference_intention ×3 (items 2, 5, 7), ce_ton_auteur ×2 (items 3, 6).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme linguistique
--     nommé (concession rhétorique, discours rapporté, inversion,
--     sur-généralisation, détail vrai mais secondaire, inférence de
--     conséquence).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (prénoms, villes, chiffres
--     inventés : Sabine Okonkwo, Naïma, Théo, Vesoul, Angers, Lorient…).
-- ============================================================================
