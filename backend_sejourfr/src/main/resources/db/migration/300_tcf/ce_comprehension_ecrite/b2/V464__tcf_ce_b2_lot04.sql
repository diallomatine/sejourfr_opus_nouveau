-- ============================================================================
-- V464 — TCF CE B2 — lot 04 (thème : environnement)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~195-212 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : pollinisateurs sauvages, artificialisation des sols, santé des
-- forêts, pollution lumineuse, retour du loup, érosion du littoral,
-- pollution des nappes phréatiques.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c004-4000-0000-000000000001', 'TEXTE',
   'En vingt-cinq ans, la masse des insectes volants a chuté de plus de 70 % dans certaines réserves naturelles d''Europe, selon des relevés menés par des entomologistes bénévoles. Le chiffre a fait le tour du monde ; il n''a pourtant déclenché aucun plan d''ampleur. Sans doute parce que les insectes n''attendrissent personne : on s''émeut du sort de l''ours polaire, rarement de celui du syrphe ou du carabe.

L''attention médiatique s''est concentrée sur l''abeille domestique, devenue le symbole commode de cette hécatombe. Le paradoxe est qu''elle est, de toutes, la moins menacée : élevée, soignée, déplacée par les apiculteurs, elle bénéficie d''une protection que les milliers d''espèces sauvages n''auront jamais. Pendant qu''on installe des ruches sur les toits des sièges sociaux, les pollinisateurs sauvages, qui assurent l''essentiel du travail dans les cultures et les milieux naturels, s''éteignent en silence.

Or ce sont eux qui font tenir l''édifice : sans insectes, pas de pollinisation pour la majorité des plantes à fleurs, plus de nourriture pour les oiseaux des champs, dont les effectifs s''effondrent déjà. S''alarmer pour les abeilles ne suffit plus ; c''est tout le peuple minuscule des haies et des prairies qu''il faut apprendre à regarder — et à protéger.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c004-4000-0000-000000000002', 'TEXTE',
   'Vingt mille hectares : c''est la surface de terres agricoles et d''espaces naturels qui disparaît chaque année en France sous les lotissements, les entrepôts et les ronds-points. Pour enrayer cette consommation, la loi impose désormais aux collectivités de tendre vers le « zéro artificialisation nette » d''ici au milieu du siècle. Depuis, une partie des élus locaux crie à l''asphyxie : comment accueillir de nouveaux habitants, attirer des entreprises, construire une école, si l''on ne peut plus ouvrir de terrains à bâtir ?

L''inquiétude mérite d''être entendue, et l''État aurait tort de la balayer : les communes rurales, qui ont peu construit, vivent mal d''être soumises au même régime que les métropoles qui ont bétonné sans compter. Mais elle ne saurait servir de prétexte à l''abandon de l''objectif. Car les chiffres sont têtus : l''essentiel des surfaces consommées ne répond pas à des besoins vitaux, mais à l''étalement pavillonnaire et aux zones commerciales de périphérie, pendant que des millions de mètres carrés de friches, de bureaux vides et de bâtiments vacants attendent une seconde vie.

Densifier, réhabiliter, reconstruire la ville sur la ville : la voie est connue, plus exigeante, souvent plus coûteuse à court terme. C''est précisément là que l''État doit porter son effort, plutôt que de rouvrir un débat que l''urgence écologique a déjà tranché.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c004-4000-0000-000000000003', 'TEXTE',
   'Vue du ciel, la forêt française se porte bien : sa surface a presque doublé depuis un siècle et continue de gagner du terrain sur les campagnes désertées. Cette expansion nourrit un discours rassurant, que les chiffres de terrain démentent pourtant un peu plus chaque année.

Dans les massifs de l''Est, des dizaines de milliers d''hectares d''épicéas, affaiblis par les sécheresses successives, ont succombé aux attaques du scolyte, un coléoptère qui prolifère à la faveur des hivers doux. Plus au sud, les chênes eux-mêmes, réputés résistants, montrent des signes de dépérissement inquiétants. Résultat : la mortalité des arbres a augmenté de près de 80 % en dix ans, et le puits de carbone forestier — la capacité des forêts à absorber le CO2 — a été divisé par deux, alors que les scénarios climatiques nationaux comptent précisément sur lui.

Les forestiers ne restent pas les bras croisés : essais d''essences méridionales, migration assistée, peuplements mélangés censés mieux résister. Mais une forêt pousse à l''échelle du siècle, quand le climat change à celle de la décennie. C''est ce décalage de tempo, plus que la surface des forêts, qui devrait inquiéter : un massif peut s''étendre sur la carte et, dans le même temps, mourir sur pied.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c004-4000-0000-000000000004', 'TEXTE',
   'La nuit a quasiment disparu de France métropolitaine : les points lumineux ont plus que doublé en trente ans, au point qu''on ne distingue plus la Voie lactée que dans quelques zones préservées. Longtemps traitée comme une simple nuisance pour astronomes, la pollution lumineuse est désormais documentée comme une cause majeure d''effondrement du vivant : insectes piégés par les lampadaires, oiseaux migrateurs désorientés, chauves-souris privées de territoires de chasse, rythmes biologiques déréglés jusque chez les arbres.

Face à ce constat, plusieurs milliers de communes ont franchi le pas : extinction de l''éclairage public au cœur de la nuit, le plus souvent entre vingt-trois heures et cinq heures. Les oppositions, vives au début, reposaient presque toutes sur la crainte de l''insécurité. Or les gendarmeries des départements concernés sont formelles : aucune hausse de la délinquance n''a été constatée, les cambrioleurs ayant, du reste, rarement l''habitude d''opérer dans le noir complet. Quant aux économies réalisées, elles atteignent parfois la moitié de la facture d''électricité municipale.

Peu de politiques publiques offrent un tel rapport entre le coût — quasi nul — et le bénéfice, écologique et financier. L''obscurité est l''une des rares ressources naturelles qu''il suffit de cesser de détruire pour la restaurer. Il serait temps que les grandes villes, encore frileuses, s''en avisent.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c004-4000-0000-000000000005', 'TEXTE',
   'Trente ans après son retour par les Alpes, le loup occupe désormais une bonne moitié du territoire français, et le millier d''individus recensés a rendu sa disparition improbable. On pourrait s''en réjouir sobrement : le retour d''un grand prédateur signe la vitalité retrouvée des écosystèmes. Mais le débat public, lui, reste enfermé dans une guerre de tranchées aussi stérile que bruyante.

D''un côté, certains défenseurs de la nature idéalisent un animal qui n''a que faire de nos symboles, et balaient d''un revers de main les milliers de brebis tuées chaque année — pertes indemnisées, certes, mais l''indemnisation ne dit rien des nuits blanches, des troupeaux affolés, des bergers qui renoncent. De l''autre, une partie du monde agricole réclame une éradication pure et simple, juridiquement impossible et écologiquement absurde, le loup régulant précisément les ongulés sauvages qui ravagent les jeunes forêts.

Entre ces deux postures, une politique de coexistence existe pourtant : chiens de protection, aides au gardiennage, tirs de défense strictement encadrés, expérimentés avec des résultats probants dans plusieurs massifs. Elle exige des moyens durables et un peu de silence médiatique. Le loup n''est ni un trésor sacré ni une vermine à abattre : c''est un voisin difficile, avec lequel il va falloir apprendre à partager la montagne.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c004-4000-0000-000000000006', 'TEXTE',
   'À Kervadec, petite commune de la côte atlantique, la résidence des Embruns a été évacuée puis démolie l''an dernier : la falaise qui la portait avait reculé de douze mètres en quinze ans. Le cas n''a plus rien d''exceptionnel. Près d''un cinquième du littoral français recule, et des dizaines de milliers de bâtiments pourraient être concernés d''ici à la fin du siècle, sous l''effet conjugué de la montée des eaux et des tempêtes plus fréquentes.

Le réflexe historique a toujours été le même : défendre. Digues, enrochements, épis de béton — des ouvrages coûteux, à entretenir sans fin, et dont les ingénieurs savent désormais qu''ils déplacent souvent l''érosion vers les plages voisines plus qu''ils ne la suppriment. Protéger un port ou un quartier dense peut se justifier ; sanctuariser chaque mètre de côte ne le peut pas.

Reste l''autre voie, que quelques communes pionnières expérimentent : la recomposition. Reculer les routes, déplacer les campings, interdire les constructions neuves dans les zones condamnées, racheter les biens les plus exposés avant qu''ils ne perdent toute valeur. Politiquement ingrate, la démarche se heurte à une question non résolue : qui paiera ? Tant que l''État n''aura pas tranché ce point, les maires resteront seuls face à des habitants qui découvrent que leur maison a les pieds dans un sablier.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c004-4000-0000-000000000007', 'TEXTE',
   'On croit souvent qu''interdire une substance suffit à s''en débarrasser. L''eau souterraine raconte une tout autre histoire. Dans la plaine de Valgrange, les hydrogéologues retrouvent aujourd''hui, dans les nappes, des résidus d''un herbicide retiré du marché il y a plus de vingt ans. Rien d''étonnant pour les spécialistes : l''eau de pluie met parfois des décennies à traverser les sols avant d''atteindre les réserves souterraines. Ce que nous pompons aujourd''hui, ce sont les pratiques agricoles des années quatre-vingt-dix ; ce que nous épandons aujourd''hui, nos enfants le boiront.

Les conséquences sont déjà tangibles : plusieurs centaines de captages d''eau potable ont dû être fermés ces dernières années, et les collectivités investissent des sommes croissantes dans des usines de traitement toujours plus sophistiquées — payées, in fine, par la facture des abonnés. Traiter coûte cher ; prévenir coûterait moins, mais les bénéfices n''apparaîtraient que dans vingt ou trente ans, un horizon que le calendrier politique ignore superbement.

C''est là toute la cruauté du dossier : les nappes phréatiques sont une mémoire. Elles n''oublient rien de ce qu''on leur a fait subir, et elles le restituent avec un implacable décalage. Les protéger exige d''agir pour des électeurs qui ne sont pas encore nés — exercice dont peu de responsables se montrent capables.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c004-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c004-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'Le texte affirme que l''abeille domestique « est, de toutes, la moins menacée », pendant que « les pollinisateurs sauvages […] s''éteignent en silence » : **l''idée principale est que la focalisation sur l''abeille domestique masque un déclin bien plus grave, celui des insectes sauvages**. La réponse A inverse le détail-piège : l''abeille domestique est précisément la moins menacée. La réponse C contredit l''ironie du texte sur les ruches installées « sur les toits des sièges sociaux », présentées comme une fausse solution. La réponse D invente une causalité : les oiseaux des champs déclinent faute d''insectes, pas à cause des apiculteurs. Mécanisme : résister au **détail-piège inversé** et distinguer le symbole médiatique du propos réel.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c004-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c004-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Comment l''auteur se positionne-t-il face à la contestation des élus locaux ?',
   'L''auteur concède que « l''inquiétude mérite d''être entendue », notamment pour les communes rurales, avant d''objecter : « Mais elle ne saurait servir de prétexte à l''abandon de l''objectif ». **Sa position : une critique en partie légitime, qui ne doit pas pour autant enterrer le zéro artificialisation.** La réponse A nie la concession explicite du début du deuxième paragraphe. La réponse B sur-étend cette concession : l''auteur demande un traitement différencié, jamais une exemption définitive. La réponse C inverse sa conclusion : le débat est « déjà tranché » par l''urgence écologique. Mécanisme : repérer le **mouvement concessif** (certes… mais) qui exprime un jugement nuancé, ni rejet ni ralliement.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c004-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c004-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur la forêt française ?',
   'Le texte oppose une surface qui « a presque doublé depuis un siècle » à une mortalité des arbres en hausse de 80 % : **on apprend que la forêt s''étend en superficie tout en se dégradant gravement sur le plan sanitaire** (« s''étendre sur la carte et, dans le même temps, mourir sur pied »). La réponse B inverse le constat : la forêt ne recule pas, elle gagne du terrain. La réponse C inverse le chiffre-piège : le puits de carbone a été « divisé par deux », pas doublé. La réponse D sur-généralise un détail : les essences méridionales sont des « essais », pas une solution ayant déjà mis fin au dépérissement. Mécanisme : **inférence globale** réunissant deux informations apparemment contradictoires, contre des distracteurs en inversion.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c004-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c004-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Quelle est l''intention principale de l''auteur de ce texte ?',
   'Tout le texte démonte les objections à l''extinction nocturne (« aucune hausse de la délinquance n''a été constatée ») et vante un « rapport entre le coût — quasi nul — et le bénéfice » exceptionnel : **l''intention est de convaincre que l''extinction de l''éclairage est une mesure efficace dont les objections ne résistent pas aux faits**. La réponse A inverse le détail-piège : les gendarmeries n''observent justement aucune hausse de la délinquance. La réponse B contredit le texte, qui dépasse la « simple nuisance pour astronomes » pour en faire une cause d''effondrement du vivant. La réponse D inverse la fin du texte : les grandes villes sont « encore frileuses », pas pionnières. Mécanisme : **inférence d''intention** à partir d''une argumentation qui réfute méthodiquement les contre-arguments.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c004-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c004-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur dans le débat sur le loup ?',
   'L''auteur critique « d''un côté » l''idéalisation du loup, « de l''autre » la demande d''éradication, et conclut : « ni un trésor sacré ni une vermine à abattre ». **Sa position : renvoyer dos à dos les deux camps et défendre une coexistence concrète, outillée et financée** (chiens de protection, gardiennage, tirs encadrés). La réponse A ne retient qu''un camp, alors que l''éradication est qualifiée d''« écologiquement absurde ». La réponse C s''appuie sur le détail-piège : les pertes sont indemnisées, mais « l''indemnisation ne dit rien des nuits blanches » — elle ne règle donc pas l''essentiel. La réponse D inverse un fait : le loup régule les ongulés qui ravagent les jeunes forêts, il ne les menace pas. Mécanisme : identifier le **ton de l''auteur** dans une structure en balancement (d''un côté… de l''autre… entre ces deux postures).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c004-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c004-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale défendue dans ce texte ?',
   'Le texte juge que « sanctuariser chaque mètre de côte » est impossible et présente la recomposition (reculer les routes, racheter les biens exposés) comme « l''autre voie » : **l''idée principale est qu''organiser le repli des zones menacées est plus réaliste que de défendre la côte mètre par mètre**. La réponse A contredit le détail-piège : les digues « déplacent souvent l''érosion vers les plages voisines plus qu''ils ne la suppriment ». La réponse B minimise un constat explicite : le cas « n''a plus rien d''exceptionnel », un cinquième du littoral recule. La réponse D inverse la fin du texte : la question du financement n''est justement « pas tranchée » par l''État. Mécanisme : distinguer la **thèse défendue** (le repli organisé) du constat initial et des objections évoquées.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c004-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c004-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur la pollution des nappes phréatiques ?',
   'Le texte explique que l''eau de pluie « met parfois des décennies à traverser les sols », si bien qu''on retrouve aujourd''hui un herbicide « retiré du marché il y a plus de vingt ans » : **on apprend que les nappes restituent avec des décennies de retard les pollutions passées, interdiction ou pas**. La réponse B inverse ce mécanisme central : interdire ne nettoie pas les nappes à court terme. La réponse C invente un fait : des captages ont été fermés, rien n''indique qu''ils aient rouvert grâce aux usines de traitement. La réponse D déforme l''origine de la pollution : le texte incrimine « les pratiques agricoles des années quatre-vingt-dix », pas les rejets industriels. Mécanisme : **inférence de la cause** (l''inertie hydrogéologique) face à des distracteurs en inversion temporelle.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — pollinisateurs sauvages (bonne réponse : position 2)
  ('11111111-c004-2100-0000-000000000001', '11111111-c004-1000-0000-000000000001',
   'Les abeilles domestiques sont aujourd''hui les insectes les plus menacés d''Europe',
   'false', '1'),

  ('11111111-c004-2200-0000-000000000001', '11111111-c004-1000-0000-000000000001',
   'La focalisation sur l''abeille domestique masque le déclin, bien plus grave, des insectes sauvages',
   'true', '2'),

  ('11111111-c004-2300-0000-000000000001', '11111111-c004-1000-0000-000000000001',
   'Installer des ruches sur les toits des villes suffit à enrayer la disparition des pollinisateurs',
   'false', '3'),

  ('11111111-c004-2400-0000-000000000001', '11111111-c004-1000-0000-000000000001',
   'Les oiseaux des champs disparaissent parce que les apiculteurs déplacent leurs ruches',
   'false', '4'),

  -- item 02 — artificialisation des sols (bonne réponse : position 4)
  ('11111111-c004-2100-0000-000000000002', '11111111-c004-1000-0000-000000000002',
   'Il la juge purement électoraliste et refuse de l''examiner sérieusement',
   'false', '1'),

  ('11111111-c004-2200-0000-000000000002', '11111111-c004-1000-0000-000000000002',
   'Il propose d''exempter définitivement les communes rurales de l''objectif',
   'false', '2'),

  ('11111111-c004-2300-0000-000000000002', '11111111-c004-1000-0000-000000000002',
   'Il estime que l''objectif de zéro artificialisation doit être abandonné',
   'false', '3'),

  ('11111111-c004-2400-0000-000000000002', '11111111-c004-1000-0000-000000000002',
   'Il en reconnaît la part légitime mais refuse qu''elle serve à enterrer l''objectif',
   'true', '4'),

  -- item 03 — santé des forêts (bonne réponse : position 1)
  ('11111111-c004-2100-0000-000000000003', '11111111-c004-1000-0000-000000000003',
   'Sa surface s''accroît alors même que son état sanitaire se dégrade rapidement',
   'true', '1'),

  ('11111111-c004-2200-0000-000000000003', '11111111-c004-1000-0000-000000000003',
   'Elle recule chaque année sous l''effet des sécheresses et des insectes ravageurs',
   'false', '2'),

  ('11111111-c004-2300-0000-000000000003', '11111111-c004-1000-0000-000000000003',
   'Elle absorbe deux fois plus de carbone qu''il y a dix ans',
   'false', '3'),

  ('11111111-c004-2400-0000-000000000003', '11111111-c004-1000-0000-000000000003',
   'Les nouvelles essences plantées ont déjà mis fin au dépérissement des arbres',
   'false', '4'),

  -- item 04 — pollution lumineuse (bonne réponse : position 3)
  ('11111111-c004-2100-0000-000000000004', '11111111-c004-1000-0000-000000000004',
   'Alerter sur la hausse de la délinquance dans les communes qui éteignent la nuit',
   'false', '1'),

  ('11111111-c004-2200-0000-000000000004', '11111111-c004-1000-0000-000000000004',
   'Démontrer que la pollution lumineuse ne gêne en réalité que les astronomes',
   'false', '2'),

  ('11111111-c004-2300-0000-000000000004', '11111111-c004-1000-0000-000000000004',
   'Convaincre que l''extinction nocturne est une mesure très rentable dont les objections ne tiennent pas',
   'true', '3'),

  ('11111111-c004-2400-0000-000000000004', '11111111-c004-1000-0000-000000000004',
   'Saluer le rôle moteur des grandes villes dans l''extinction de l''éclairage public',
   'false', '4'),

  -- item 05 — retour du loup (bonne réponse : position 2)
  ('11111111-c004-2100-0000-000000000005', '11111111-c004-1000-0000-000000000005',
   'Il soutient les éleveurs qui réclament l''éradication pure et simple du prédateur',
   'false', '1'),

  ('11111111-c004-2200-0000-000000000005', '11111111-c004-1000-0000-000000000005',
   'Il renvoie dos à dos les deux camps et défend une coexistence concrète, dotée de moyens durables',
   'true', '2'),

  ('11111111-c004-2300-0000-000000000005', '11111111-c004-1000-0000-000000000005',
   'Il estime que l''indemnisation des brebis tuées règle l''essentiel du problème des bergers',
   'false', '3'),

  ('11111111-c004-2400-0000-000000000005', '11111111-c004-1000-0000-000000000005',
   'Il considère le retour du loup comme une menace pour la survie des jeunes forêts',
   'false', '4'),

  -- item 06 — érosion du littoral (bonne réponse : position 3)
  ('11111111-c004-2100-0000-000000000006', '11111111-c004-1000-0000-000000000006',
   'Les digues et les enrochements protègent durablement l''ensemble du littoral français',
   'false', '1'),

  ('11111111-c004-2200-0000-000000000006', '11111111-c004-1000-0000-000000000006',
   'L''érosion côtière ne concerne encore que quelques communes aux situations exceptionnelles',
   'false', '2'),

  ('11111111-c004-2300-0000-000000000006', '11111111-c004-1000-0000-000000000006',
   'Plutôt que de défendre chaque mètre de côte, il faut organiser le repli des zones menacées',
   'true', '3'),

  ('11111111-c004-2400-0000-000000000006', '11111111-c004-1000-0000-000000000006',
   'L''État a déjà tranché la question du financement de la recomposition du littoral',
   'false', '4'),

  -- item 07 — nappes phréatiques (bonne réponse : position 1)
  ('11111111-c004-2100-0000-000000000007', '11111111-c004-1000-0000-000000000007',
   'Des substances interdites depuis des décennies y sont encore détectées, l''eau mettant très longtemps à s''infiltrer',
   'true', '1'),

  ('11111111-c004-2200-0000-000000000007', '11111111-c004-1000-0000-000000000007',
   'L''interdiction d''un pesticide permet d''assainir les nappes en quelques années',
   'false', '2'),

  ('11111111-c004-2300-0000-000000000007', '11111111-c004-1000-0000-000000000007',
   'Les usines de traitement ont permis de rouvrir tous les captages d''eau potable fermés',
   'false', '3'),

  ('11111111-c004-2400-0000-000000000007', '11111111-c004-1000-0000-000000000007',
   'La pollution des nappes provient essentiellement des rejets industriels',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c004-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « environnement », 7 angles tous différents :
--     déclin des pollinisateurs sauvages / artificialisation des sols /
--     santé des forêts (scolytes, puits de carbone) / pollution lumineuse /
--     retour du loup et pastoralisme / érosion du littoral (recomposition) /
--     pollution différée des nappes phréatiques. Aucun thème interdit
--     (pas d'énergie & transition, pas de consommation responsable,
--     pas de ville & mobilité, pas d'alimentation).
-- [x] Textes B2 longs : 195 / 210 / 202 / 207 / 204 / 212 / 206 mots
--     (tous dans la fourchette 150-280), denses, chacun avec un détail-piège
--     (abeille domestique « la moins menacée », concession aux élus ruraux,
--     surface forestière en hausse, délinquance non constatée, indemnisation
--     des brebis, digues qui déplacent l'érosion, herbicide interdit depuis
--     vingt ans).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2 (items 3, 7), pos2:2
--     (items 1, 5), pos3:2 (items 4, 6), pos4:1 (item 2) — 4 positions
--     utilisées, max 2 par position.
-- [x] competence_code : ce_idee_principale ×2 (items 1, 6),
--     ce_inference_intention ×3 (items 3, 4, 7), ce_ton_auteur ×2 (items 2, 5).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme nommé
--     (mouvement concessif, inversion cause/effet, inférence d'intention,
--     détail-piège, sur-généralisation, thèse vs constat).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (lieux inventés : Kervadec,
--     Valgrange ; chiffres inventés et plausibles).
-- ============================================================================
