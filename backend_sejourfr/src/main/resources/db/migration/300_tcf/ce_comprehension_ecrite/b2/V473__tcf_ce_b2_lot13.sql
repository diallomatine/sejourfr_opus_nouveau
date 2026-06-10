-- ============================================================================
-- V473 — TCF CE B2 — lot 13 (thème : tourisme)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~177-211 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : quotas de visiteurs sur site naturel / tourisme de mémoire /
-- escales de croisière / label de village / guides-conférenciers /
-- promotion du hors-saison / séjours de déconnexion.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c00d-4000-0000-000000000001', 'TEXTE',
   'Depuis avril, on n''entre plus librement dans les gorges du Vergon : chaque visiteur doit réserver, au plus tard la veille, un créneau gratuit en ligne. La mesure, une première dans la région, répond à un constat devenu intenable : jusqu''à huit mille personnes se pressaient certains dimanches sur un sentier prévu pour le dixième. Les commerçants du village voisin avaient prédit la catastrophe : sans la foule, disaient-ils, les terrasses se videraient.

Six mois plus tard, le bilan les contredit : la fréquentation annuelle n''a presque pas baissé, elle s''est simplement étalée sur la semaine, et le chiffre d''affaires des restaurateurs est resté stable. Les visiteurs, eux, redécouvrent un site qu''on n''entendait plus : le silence, notent les gardes, est revenu avec les oiseaux.

Faut-il pour autant généraliser le modèle ? Rien n''est moins sûr. La réservation suppose une connexion, une anticipation, une organisation qui excluent de fait les visites spontanées et une partie des habitants des environs, attachés à « leurs » gorges. Elle ne règle pas davantage la question de fond : tant que les mêmes dix sites concentreront l''essentiel des envies, on déplacera la pression au lieu de la réduire. Le quota n''est pas une solution miracle ; c''est un aveu, utile et provisoire, que la nature ne peut plus tout absorber.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00d-4000-0000-000000000002', 'TEXTE',
   'Chaque année, des millions de visiteurs franchissent les portes d''anciens camps, de champs de bataille ou de prisons transformés en lieux de mémoire. Ce « tourisme de mémoire » a longtemps été regardé avec méfiance : que viennent chercher ces foules en short sur les traces des tragédies ? Les polémiques récurrentes sur les autoportraits souriants pris devant les baraquements semblent donner raison aux sceptiques.

Ce procès est pourtant trop facile. Les enquêtes menées auprès des visiteurs racontent une autre histoire : l''immense majorité ressort bouleversée, et beaucoup déclarent avoir compris sur place ce que dix manuels scolaires n''avaient pas réussi à leur transmettre. Les comportements déplacés, bien réels, restent statistiquement marginaux ; ils sont surtout devenus très visibles à l''ère des réseaux.

Plutôt que de trier les « bons » et les « mauvais » visiteurs, les gestionnaires de ces sites ont mieux à faire : préparer la visite en amont, former des guides capables de répondre aux questions dérangeantes, aménager des espaces où déposer l''émotion. Car le vrai danger n''est pas le selfie maladroit d''un adolescent ; c''est le jour où plus personne ne fera le déplacement.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00d-4000-0000-000000000003', 'TEXTE',
   'Le paquebot s''amarre à huit heures ; à neuf heures, six mille passagers déferlent dans les ruelles de la vieille ville de Port-Salvère. Les municipalités se sont longtemps battues pour attirer ces géants des mers, persuadées que chaque escale ruissellerait sur l''économie locale. Une étude commandée par la chambre de commerce vient de doucher cet enthousiasme : un croisiériste dépense en moyenne dix-neuf euros à terre, soit six fois moins qu''un touriste qui dort à l''hôtel.

Tout est pensé pour que l''argent reste à bord : repas compris, boutiques sur le pont, excursions vendues par la compagnie elle-même. Pendant ce temps, la ville assume seule les coûts : nettoyage des rues, saturation des navettes, usure des sites, sans parler des fumées qui stationnent au-dessus du port.

Certains commerçants y trouvent malgré tout leur compte : les vendeurs de glaces et de souvenirs réalisent jusqu''à un tiers de leur chiffre annuel les jours d''escale. Mais ce ruissellement-là est trop étroit pour justifier la facture collective. Plusieurs ports voisins l''ont compris, qui instaurent une taxe par passager ou plafonnent le nombre d''escales : non pour chasser les navires, mais pour que la croisière paie enfin ce qu''elle coûte.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00d-4000-0000-000000000004', 'TEXTE',
   'Quand Saint-Andrin-sur-Ource a décroché le label « Perles de France », en 2019, la mairie a sablé le champagne. Cinq ans plus tard, le maire, Bertrand Loiseau, confie ne plus savoir s''il faut s''en réjouir. La fréquentation a quadruplé, certes, et avec elle les recettes de la boutique communale. Mais la boulangerie a été remplacée par un marchand de savons parfumés, le café des habitués par un salon de thé qui ferme en novembre, et la moitié des maisons du bourg par des résidences occupées trois semaines par an. L''école, faute d''enfants, a perdu une classe à la dernière rentrée.

Le phénomène n''a rien d''isolé : les chercheurs qui étudient ces villages labellisés parlent de « muséification » — un décor admirablement entretenu, mais qui se vide de la vie ordinaire qui en faisait le charme. Le label n''est pas coupable en soi ; il agit comme un accélérateur, qui récompense la beauté d''un lieu et précipite ce qui la menace.

Quelques communes tentent de reprendre la main : achat des murs commerciaux par la mairie, loyers plafonnés pour les artisans, quota de résidences secondaires. Autant de garde-fous qui rappellent une évidence : un village n''est beau que s''il reste un village.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00d-4000-0000-000000000005', 'TEXTE',
   'On croit le connaître : parapluie levé, micro à la main, le guide-conférencier promène son groupe de monument en monument. Derrière la carte professionnelle, obtenue après des années d''études en histoire de l''art, se cache pourtant l''un des métiers les plus précaires du secteur touristique. Payés à la vacation, sans revenu l''hiver, les guides voient en outre leur terrain envahi : applications audio à deux euros, visites « gratuites » au pourboire, accompagnateurs improvisés recrutés sur les réseaux, sans carte ni formation. Résultat : en dix ans, un tiers des titulaires de la carte a quitté la profession.

Doit-on s''en émouvoir, quand une application raconte la cathédrale pour le prix d''un café ? Oui, et pas seulement par corporatisme. Un enregistrement ne voit pas son public ; il ne sent pas qu''un groupe décroche, ne répond pas à la question imprévue, ne raconte pas la ville en train de changer. Le guide est précisément ce qui distingue une visite d''une consommation.

Si sa disparition se poursuit, les villes d''art y perdront bien plus qu''une profession : une certaine manière de se raconter, qui ne tient ni dans une oreillette ni dans un algorithme.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00d-4000-0000-000000000006', 'TEXTE',
   '« Venez en novembre » : depuis quelques années, les offices de tourisme du littoral rivalisent de campagnes pour vanter la douceur de l''arrière-saison. L''idée semble frappée au coin du bon sens : puisque juillet et août débordent, déplaçons une partie des vacanciers vers les mois creux, et chacun y gagnera — les sites moins saturés, les professionnels mieux occupés à l''année.

Les premiers bilans chiffrés invitent pourtant à la prudence. Sur la côte de Trébélan, la fréquentation d''octobre a bien bondi de quarante pour cent en quatre ans ; celle du mois d''août, elle, n''a pas reculé d''un seul point. Autrement dit, la promotion du hors-saison n''a pas étalé les flux : elle en a créé de nouveaux, venus s''ajouter aux anciens. Les courts séjours d''automne, rendus possibles par le télétravail et les billets à bas prix, sont des vacances supplémentaires, pas des vacances déplacées. Pour les habitants, le répit d''antan disparaît : les ruelles ne désemplissent plus jamais vraiment.

Personne ne suggère de renoncer à faire vivre les stations à l''année, et les hôteliers, qui recrutent désormais dix mois sur douze, auraient beaucoup à y perdre. Mais il faudra cesser de présenter l''étalement de la saison comme un remède au surtourisme : tant que rien ne limite les pics de l''été, il ne fait qu''allonger la haute saison.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00d-4000-0000-000000000007', 'TEXTE',
   'Pour cent quatre-vingts euros la nuit, l''auberge du Roc-Blanc, dans les Cévennes, propose à ses clients de déposer leur téléphone dans un coffre à l''arrivée. Au programme : randonnées sans itinéraire enregistré, repas sans photo, soirées sans écran. Le créneau de la « déconnexion » est devenu l''un des plus dynamiques de l''hôtellerie : l''offre a triplé en cinq ans, et les établissements affichent complet des mois à l''avance.

Il y a quelque chose de piquant à payer aussi cher pour se voir confisquer ce que l''on possède déjà : le silence, la marche, une conversation. Les mauvaises langues parlent d''une arnaque chic, qui revend aux urbains fatigués ce qui ne coûte rien. Le succès de ces séjours dit pourtant quelque chose de sérieux : beaucoup de vacanciers reconnaissent qu''ils n''arrivent plus à s''interrompre seuls, et qu''il leur faut un cadre, presque une autorité extérieure, pour lâcher l''appareil.

À l''auberge du Roc-Blanc, un client sur cinq abandonne et réclame son téléphone avant la fin du séjour ; les autres repartent en jurant qu''ils recommenceront. On peut sourire du procédé ; on peut aussi y lire le symptôme d''une époque où le repos est devenu une compétence perdue, que le tourisme, fidèle à lui-même, a transformée en produit.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c00d-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00d-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale défendue par l''auteur ?',
   'L''auteur conclut que le quota est « un aveu, utile et provisoire, que la nature ne peut plus tout absorber » : **la réservation a fait ses preuves localement mais ne résout pas la concentration des flux sur quelques sites**. La réponse A inverse les faits : les commerçants avaient prédit la catastrophe, mais « le bilan les contredit », le chiffre d''affaires est resté stable. La réponse C sur-généralise : à la question « Faut-il généraliser le modèle ? », l''auteur répond « Rien n''est moins sûr ». La réponse D déforme un détail : la fréquentation annuelle « n''a presque pas baissé », elle s''est étalée. Mécanisme : distinguer la **thèse nuancée de l''auteur** (succès local, limite structurelle) des prédictions rapportées et des détails déformés.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c00d-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00d-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur à l''égard du tourisme de mémoire ?',
   'L''auteur qualifie les critiques de « procès trop facile » et conclut que « le vrai danger... c''est le jour où plus personne ne fera le déplacement » : **il défend ce tourisme, jugeant les reproches disproportionnés par rapport aux comportements réels**, statistiquement marginaux. La réponse A invente une mesure absente : aucune interdiction des photographies n''est demandée. La réponse B inverse le constat des enquêtes : « l''immense majorité ressort bouleversée », pas voyeuriste. La réponse C contredit le texte, qui rejette explicitement l''idée de « trier les "bons" et les "mauvais" visiteurs ». Mécanisme : repérer le **renversement argumentatif** (« Ce procès est pourtant trop facile ») qui signale la prise de position de l''auteur contre les sceptiques.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c00d-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00d-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur les escales de croisière ?',
   'Le texte oppose les dix-neuf euros dépensés à terre par croisiériste aux coûts que « la ville assume seule » : **les retombées locales des escales sont trop faibles au regard de la facture collective qu''elles imposent**. La réponse B inverse la comparaison : le croisiériste dépense « six fois moins » qu''un touriste hébergé à l''hôtel, pas davantage. La réponse C contredit la fin du texte : les taxes sont instaurées « non pour chasser les navires », mais pour faire payer le coût réel. La réponse D sur-généralise un détail vrai mais secondaire : seuls certains vendeurs réalisent jusqu''à un tiers de leur chiffre les jours d''escale, ce « ruissellement-là est trop étroit ». Mécanisme : **inférence du bilan global** contre une inversion de comparaison et un détail secondaire promu en idée centrale.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c00d-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00d-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Que cherche à montrer l''auteur de ce texte ?',
   'Le texte décrit la « muséification » : « un décor admirablement entretenu, mais qui se vide de la vie ordinaire » : **le label touristique, en attirant les foules, peut vider un village de sa vie quotidienne** — c''est la démonstration centrale. La réponse A inverse les faits économiques : la fréquentation a quadruplé « et avec elle les recettes », il n''y a pas de ruine. La réponse B sur-étend le propos : l''auteur précise que « le label n''est pas coupable en soi » et évoque des garde-fous, jamais un abandon du label. La réponse D inverse un détail-piège : l''école « a perdu une classe », elle n''a pas été sauvée. Mécanisme : **inférence d''intention** — identifier l''effet d''accélérateur dénoncé, contre des distracteurs en inversion de détail et en sur-extension.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c00d-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00d-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Comment l''auteur se positionne-t-il face au déclin du métier de guide-conférencier ?',
   'À la question « Doit-on s''en émouvoir ? », l''auteur répond « Oui » et énumère ce qu''un enregistrement ne fera jamais : **il s''alarme de ce déclin, le guide apportant une valeur humaine qu''aucun outil ne remplace** (« ce qui distingue une visite d''une consommation »). La réponse A inverse le ton : l''auteur refuse de voir là une évolution acceptable, il y voit une perte pour les villes d''art. La réponse C contredit la précision « et pas seulement par corporatisme » : sa défense dépasse la solidarité professionnelle. La réponse D invente une recommandation absente : les visites au pourboire sont citées parmi les causes de la précarité, pas comme un conseil. Mécanisme : la **question rhétorique suivie de sa réponse** (« Doit-on s''en émouvoir ? Oui ») révèle le ton engagé de l''auteur.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c00d-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00d-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'Le texte conclut : « la promotion du hors-saison n''a pas étalé les flux : elle en a créé de nouveaux » : **les campagnes d''arrière-saison ajoutent des visiteurs au lieu de répartir ceux de l''été**, dont les pics ne baissent pas. La réponse A inverse le détail-piège chiffré : la fréquentation d''août « n''a pas reculé d''un seul point », seule celle d''octobre a bondi. La réponse B contredit la concession explicite : « Personne ne suggère de renoncer à faire vivre les stations à l''année ». La réponse C inverse la position des hôteliers : ils recrutent « dix mois sur douze » et « auraient beaucoup à y perdre » si la saison raccourcissait. Mécanisme : résister à l''**inversion cause/effet** (ajout de flux ≠ étalement) et aux détails retournés.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c00d-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00d-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Quelle est l''intention principale de l''auteur de ce texte ?',
   'L''auteur balance : « On peut sourire du procédé ; on peut aussi y lire le symptôme d''une époque où le repos est devenu une compétence perdue » : **son intention est d''analyser ce que le succès de ces séjours révèle de notre rapport au repos, sans condamner le procédé**. La réponse B attribue à l''auteur l''avis des « mauvaises langues », rapporté au discours indirect mais aussitôt nuancé par « pourtant ». La réponse C inverse un détail : seul « un client sur cinq abandonne », les autres « repartent en jurant qu''ils recommenceront ». La réponse D contredit le constat central : beaucoup de vacanciers « n''arrivent plus à s''interrompre seuls » et ont besoin d''un cadre. Mécanisme : **inférence d''intention** — distinguer l''opinion rapportée de la lecture symptomatique proposée par l''auteur.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — quotas de visiteurs (bonne réponse : position 2)
  ('11111111-c00d-2100-0000-000000000001', '11111111-c00d-1000-0000-000000000001',
   'Le quota a fait fuir les visiteurs et ruiné les commerçants du village voisin',
   'false', '1'),

  ('11111111-c00d-2200-0000-000000000001', '11111111-c00d-1000-0000-000000000001',
   'La réservation a fait ses preuves sur ce site mais ne résout pas la concentration touristique',
   'true', '2'),

  ('11111111-c00d-2300-0000-000000000001', '11111111-c00d-1000-0000-000000000001',
   'La réservation obligatoire devrait être généralisée à tous les sites naturels',
   'false', '3'),

  ('11111111-c00d-2400-0000-000000000001', '11111111-c00d-1000-0000-000000000001',
   'La fréquentation annuelle des gorges a fortement chuté depuis le mois d''avril',
   'false', '4'),

  -- item 02 — tourisme de mémoire (bonne réponse : position 4)
  ('11111111-c00d-2100-0000-000000000002', '11111111-c00d-1000-0000-000000000002',
   'Il demande d''interdire les photographies dans les lieux de mémoire',
   'false', '1'),

  ('11111111-c00d-2200-0000-000000000002', '11111111-c00d-1000-0000-000000000002',
   'Il estime que la plupart des visiteurs viennent dans ces lieux par voyeurisme',
   'false', '2'),

  ('11111111-c00d-2300-0000-000000000002', '11111111-c00d-1000-0000-000000000002',
   'Il propose de sélectionner les visiteurs avant l''entrée des sites',
   'false', '3'),

  ('11111111-c00d-2400-0000-000000000002', '11111111-c00d-1000-0000-000000000002',
   'Il le défend, jugeant les critiques disproportionnées par rapport aux dérives réelles',
   'true', '4'),

  -- item 03 — escales de croisière (bonne réponse : position 1)
  ('11111111-c00d-2100-0000-000000000003', '11111111-c00d-1000-0000-000000000003',
   'Leurs retombées locales sont trop faibles au regard des coûts imposés à la ville',
   'true', '1'),

  ('11111111-c00d-2200-0000-000000000003', '11111111-c00d-1000-0000-000000000003',
   'Les croisiéristes dépensent davantage à terre que les touristes logés à l''hôtel',
   'false', '2'),

  ('11111111-c00d-2300-0000-000000000003', '11111111-c00d-1000-0000-000000000003',
   'Les ports voisins instaurent des taxes pour chasser définitivement les navires',
   'false', '3'),

  ('11111111-c00d-2400-0000-000000000003', '11111111-c00d-1000-0000-000000000003',
   'Les vendeurs de souvenirs font des escales le pilier de l''économie de la ville',
   'false', '4'),

  -- item 04 — label de village (bonne réponse : position 3)
  ('11111111-c00d-2100-0000-000000000004', '11111111-c00d-1000-0000-000000000004',
   'Le label « Perles de France » a ruiné l''économie de Saint-Andrin-sur-Ource',
   'false', '1'),

  ('11111111-c00d-2200-0000-000000000004', '11111111-c00d-1000-0000-000000000004',
   'Les villages labellisés doivent renoncer à leur label pour survivre',
   'false', '2'),

  ('11111111-c00d-2300-0000-000000000004', '11111111-c00d-1000-0000-000000000004',
   'Le label touristique, en attirant les foules, peut vider un village de sa vie quotidienne',
   'true', '3'),

  ('11111111-c00d-2400-0000-000000000004', '11111111-c00d-1000-0000-000000000004',
   'La hausse de la fréquentation a permis de sauver l''école du village',
   'false', '4'),

  -- item 05 — guides-conférenciers (bonne réponse : position 2)
  ('11111111-c00d-2100-0000-000000000005', '11111111-c00d-1000-0000-000000000005',
   'Il y voit une évolution naturelle rendue inévitable par les applications audio',
   'false', '1'),

  ('11111111-c00d-2200-0000-000000000005', '11111111-c00d-1000-0000-000000000005',
   'Il s''en alarme, le guide apportant une valeur qu''aucun outil ne peut remplacer',
   'true', '2'),

  ('11111111-c00d-2300-0000-000000000005', '11111111-c00d-1000-0000-000000000005',
   'Il défend les guides uniquement par solidarité avec leur profession',
   'false', '3'),

  ('11111111-c00d-2400-0000-000000000005', '11111111-c00d-1000-0000-000000000005',
   'Il recommande aux visiteurs de choisir les visites gratuites au pourboire',
   'false', '4'),

  -- item 06 — promotion du hors-saison (bonne réponse : position 4)
  ('11111111-c00d-2100-0000-000000000006', '11111111-c00d-1000-0000-000000000006',
   'La fréquentation du mois d''août a nettement reculé grâce aux campagnes d''arrière-saison',
   'false', '1'),

  ('11111111-c00d-2200-0000-000000000006', '11111111-c00d-1000-0000-000000000006',
   'Les stations devraient cesser toute activité touristique en dehors de l''été',
   'false', '2'),

  ('11111111-c00d-2300-0000-000000000006', '11111111-c00d-1000-0000-000000000006',
   'Les hôteliers s''opposent à l''allongement de la saison touristique',
   'false', '3'),

  ('11111111-c00d-2400-0000-000000000006', '11111111-c00d-1000-0000-000000000006',
   'La promotion du hors-saison ajoute des visiteurs au lieu de répartir ceux de l''été',
   'true', '4'),

  -- item 07 — séjours de déconnexion (bonne réponse : position 1)
  ('11111111-c00d-2100-0000-000000000007', '11111111-c00d-1000-0000-000000000007',
   'Analyser ce que le succès de ces séjours révèle de notre rapport au repos, sans condamner le procédé',
   'true', '1'),

  ('11111111-c00d-2200-0000-000000000007', '11111111-c00d-1000-0000-000000000007',
   'Dénoncer une escroquerie organisée par les hôteliers des Cévennes',
   'false', '2'),

  ('11111111-c00d-2300-0000-000000000007', '11111111-c00d-1000-0000-000000000007',
   'Démontrer que les clients regrettent massivement ces séjours',
   'false', '3'),

  ('11111111-c00d-2400-0000-000000000007', '11111111-c00d-1000-0000-000000000007',
   'Encourager les vacanciers à se déconnecter sans aucune aide extérieure',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c00d-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « tourisme », 7 angles tous différents :
--     quotas de visiteurs (gorges du Vergon) / tourisme de mémoire /
--     escales de croisière (Port-Salvère) / label de village
--     (Saint-Andrin-sur-Ource) / métier de guide-conférencier /
--     promotion du hors-saison (côte de Trébélan) / séjours de déconnexion
--     (auberge du Roc-Blanc). Aucun thème interdit.
-- [x] Textes B2 longs : 206 / 177 / 190 / 193 / 185 / 211 / 199 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (ex. « presque pas baissé », « six fois moins », « un tiers de leur
--     chiffre », « pas seulement par corporatisme », « pas reculé d'un seul
--     point », « un client sur cinq abandonne »).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2 (items 1, 6),
--     ce_inference_intention ×3 (items 3, 4, 7), ce_ton_auteur ×2 (items 2, 5).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme nommé
--     (renversement argumentatif, inversion cause/effet, détail secondaire,
--     sur-généralisation, question rhétorique, opinion rapportée).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (lieux, prénoms, chiffres inventés).
-- ============================================================================
