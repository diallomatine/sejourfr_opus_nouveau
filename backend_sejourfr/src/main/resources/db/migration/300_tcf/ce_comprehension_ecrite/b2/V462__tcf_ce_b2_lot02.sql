-- ============================================================================
-- V462 — TCF CE B2 — lot 02 (thème : monde du travail)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~185-230 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : transparence des salaires, semaine de quatre jours, présentéisme,
-- reconversion vers les métiers manuels, flex office, réunionite,
-- injonction à la passion au travail.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c002-4000-0000-000000000001', 'TEXTE',
   '« Combien gagnez-vous ? » La question reste, en France, l''un des derniers grands tabous. À partir de 2027, une directive européenne obligera pourtant les entreprises de plus de cent salariés à publier les écarts de rémunération et à indiquer une fourchette de salaire dès l''offre d''embauche. Officiellement, tout le monde applaudit. En coulisses, les directions s''inquiètent.

Leur crainte n''est pas illégitime : la transparence révélera des écarts que rien ne justifie, sinon l''histoire des négociations individuelles. Tel commercial recruté en période de pénurie gagne un cinquième de plus que sa collègue arrivée deux ans plus tôt, à poste et résultats égaux. Tant que ces différences restaient invisibles, elles ne coûtaient rien ; exposées au grand jour, elles deviendront indéfendables.

C''est précisément pour cela qu''il faut se réjouir de cette directive. Non parce qu''elle ferait baisser les salaires des uns ou monter ceux des autres par enchantement, mais parce qu''elle obligera enfin les employeurs à fonder leur politique de rémunération sur des critères explicables. La transparence n''est pas une fin en soi : c''est un instrument qui rend l''arbitraire coûteux. Les entreprises qui paient juste n''ont, elles, rien à redouter.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c002-4000-0000-000000000002', 'TEXTE',
   'Trente-deux heures réparties sur quatre jours, sans baisse de salaire : depuis dix-huit mois, quarante entreprises volontaires, de la PME de chaudronnerie au cabinet de conseil, testent en France la semaine comprimée. Les premiers résultats, compilés par l''observatoire indépendant qui suit l''expérimentation, dessinent un tableau plus contrasté que les slogans.

Côté pile, les indicateurs s''améliorent presque partout : absentéisme en recul d''un quart, démissions divisées par deux, candidatures multipliées dans des secteurs qui peinaient à recruter. Côté face, la productivité ne suit que dans les entreprises qui ont profondément revu leur organisation — réunions raccourcies, tâches superflues supprimées, polyvalence accrue. Là où la direction s''est contentée de compacter cinq jours de travail en quatre, l''épuisement a remplacé l''enthousiasme en quelques mois, et deux sociétés ont d''ailleurs fait machine arrière.

La conclusion des chercheurs tient en une phrase : la semaine de quatre jours n''est pas une mesure, c''est un révélateur. Elle réussit aux organisations capables de questionner leurs habitudes et échoue chez celles qui espéraient un simple tour de passe-passe horaire. Autrement dit, le bénéfice ne vient pas du jour de repos supplémentaire, mais du travail de réorganisation qu''il impose.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c002-4000-0000-000000000003', 'TEXTE',
   'Dans la plupart des entreprises françaises, l''absentéisme fait l''objet de tableaux de bord scrutés chaque trimestre. Son jumeau inverse, lui, n''apparaît dans aucun indicateur : le présentéisme, ou l''art de venir travailler malade, épuisé, ou l''esprit ailleurs. Selon une étude du cabinet Vigie Travail menée auprès de six mille salariés, ce phénomène invisible coûterait aux employeurs près du double de l''absentéisme, en erreurs, en contaminations et en convalescences prolongées.

Le grippé qui s''installe en open space contamine ses collègues ; le salarié épuisé qui s''obstine commet des fautes qu''il faudra rattraper ; celui qui aurait dû s''arrêter une semaine finit, six mois plus tard, par s''arrêter six mois. Tout cela se paie, mais ailleurs et plus tard — donc nulle part dans les comptes.

Le plus troublant est que ce comportement n''est pas seulement subi : il est valorisé. Arriver enrhumé reste perçu, dans bien des équipes, comme une preuve de conscience professionnelle, et certains managers donnent l''exemple en s''en vantant. Tant que la culture d''entreprise récompensera le corps présent plutôt que le travail bien fait, les campagnes sur la santé au travail resteront des affiches dans les couloirs. C''est la définition même de l''engagement qu''il faut réviser.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c002-4000-0000-000000000004', 'TEXTE',
   'À trente-neuf ans, Bastien a quitté son poste de chef de projet dans une compagnie d''assurances de Niort pour reprendre une boulangerie à Figeac. Son cas n''a plus rien d''exceptionnel : les organismes de formation aux métiers manuels voient affluer des cadres en milieu de carrière, prêts à diviser leur revenu par deux pour, disent-ils, « voir enfin le résultat de leur travail ».

Il serait tentant de moquer ces vocations tardives, qu''un certain discours réduit à une mode de citadins fatigués des réunions. Ce serait passer à côté de ce qu''elles révèlent : non pas un rejet du travail, mais une demande de travail concret, dont on perçoit l''utilité et la fin. Les enquêtes le confirment, le geste précis, le client que l''on voit, l''objet terminé procurent une satisfaction que des années de tableurs et de comités de pilotage n''ont jamais offerte.

Encore faut-il regarder la réalité en face : un tiers de ces reconvertis abandonne avant la troisième année, rattrapé par la précarité du démarrage, les charges, les week-ends travaillés. La reconversion n''est ni une lubie ni un paradis : c''est un projet exigeant, qui réussit à ceux qui l''ont préparé comme on prépare une expédition, et qui brise ceux qui n''y cherchaient qu''une fuite.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c002-4000-0000-000000000005', 'TEXTE',
   'Plus de bureau attitré : chacun pose le matin son ordinateur là où une place est libre, et range le soir ses affaires dans un casier. Le « flex office » gagne du terrain dans les sièges sociaux, au rythme des renégociations de baux. Ses promoteurs y voient une évidence comptable : pourquoi payer des mètres carrés vides ?

L''argument économique est imparable, reconnaissons-le : avec des locaux occupés aux deux tiers en moyenne, réduire les surfaces relève de la simple gestion. Et certains salariés apprécient sincèrement de choisir leur environnement selon les tâches du jour : salle silencieuse pour rédiger, espace ouvert pour coopérer.

Mais ce que les tableurs ne mesurent pas, c''est ce qui disparaît avec le bureau fixe. Les équipes se dispersent au gré des places disponibles, et l''on déjeune de moins en moins avec les mêmes collègues ; les conversations imprévues, celles où naissent les idées et où s''apprend le métier, se raréfient. Le sentiment d''être chez soi quelque part, qui attache discrètement à une entreprise, s''évapore. À force de considérer l''espace de travail comme un coût à comprimer plutôt que comme un outil de cohésion, certaines directions découvriront que les économies de loyer se paient en désengagement. Le mètre carré le plus cher est celui qui fait fuir les salariés.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c002-4000-0000-000000000006', 'TEXTE',
   'Seize heures par semaine : c''est le temps qu''un cadre français passe en moyenne en réunion, selon le baromètre annuel de l''institut Ergonomie & Organisations. La moitié de ces réunions, estiment les intéressés eux-mêmes, ne débouche sur aucune décision. Le diagnostic est connu, moqué, documenté — et rien ne change. Pourquoi ?

Parce que la réunion ne sert pas qu''à décider, répondent les sociologues du travail. Elle rassure le chef qui convoque, donne aux participants le sentiment d''exister dans l''organigramme, et fournit à chacun la preuve visible qu''il est occupé. Supprimer les réunions inutiles supposerait donc de toucher à ce qu''elles protègent : des positions, des territoires, des statuts. Voilà pourquoi les chartes de « réunions efficaces », affichées dans tant de salles, restent lettre morte : elles s''attaquent au symptôme en ménageant la cause.

Quelques entreprises ont pourtant rompu le cercle, non par une charte de plus, mais par une règle de rareté : à Clermont-Ferrand, un équipementier a réduit de moitié les salles disponibles et imposé un ordre du jour écrit pour toute convocation. Résultat, dix-huit mois plus tard : un tiers de réunions en moins, sans que personne ne réclame leur retour. La preuve que le problème n''a jamais été le manque de bonnes pratiques, mais l''absence de contrainte.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c002-4000-0000-000000000007', 'TEXTE',
   '« Choisissez un travail que vous aimez et vous ne travaillerez plus un seul jour de votre vie. » La formule orne les murs des espaces de coworking et les discours de remise de diplômes. Elle a tout d''un cadeau ; c''est en réalité l''un des pièges les mieux décorés du monde professionnel contemporain.

Car l''injonction à la passion arrange d''abord ceux qui emploient. Une enquête menée par deux chercheuses de l''université de Lausanne auprès de mille deux cents recruteurs le montre : face à un candidat présenté comme « passionné », ils jugent plus acceptable de proposer des horaires étendus, des tâches hors fiche de poste ou un salaire inférieur. La passion, censée récompenser, sert en pratique de monnaie : on paie les gens en plaisir supposé, et ce plaisir justifie tout.

Elle fait aussi des dégâts chez ceux qui ne la ressentent pas. Le soignant consciencieux, la comptable fiable, le conducteur ponctuel qui font simplement bien leur métier se voient implicitement reprocher de n''être « que » compétents. Comme si la conscience professionnelle, vertu autrement plus répandue et plus solide que la flamme, était devenue insuffisante.

Aimer son travail est une chance, personne ne le nie. Mais en faire une obligation, c''est transformer un bonheur possible en dette permanente. On peut exiger d''un emploi qu''il soit utile, correctement payé et respectueux ; exiger en plus qu''il nous comble relève d''une autre affaire — la nôtre, pas celle de l''employeur.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c002-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c002-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est la position défendue par l''auteur sur la transparence des salaires ?',
   'L''auteur conclut que la directive « obligera enfin les employeurs à fonder leur politique de rémunération sur des critères explicables » : **la thèse défendue est le soutien à la directive comme instrument contre l''arbitraire salarial**. La réponse A invente un effet automatique que l''auteur écarte explicitement (« non parce qu''elle ferait baisser les salaires des uns ou monter ceux des autres par enchantement »). La réponse C inverse deux affirmations du texte : la crainte des directions « n''est pas illégitime » et les écarts sont précisément ceux « que rien ne justifie ». La réponse D prend le contre-pied de toute la thèse défendue. Mécanisme : distinguer la **thèse de l''auteur** des effets fantasmés ou des positions qu''il réfute.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c002-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c002-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur l''expérimentation de la semaine de quatre jours ?',
   'La chute du texte est explicite : « le bénéfice ne vient pas du jour de repos supplémentaire, mais du travail de réorganisation qu''il impose ». **La condition du succès est la refonte de l''organisation, pas le jour chômé lui-même.** La réponse A est une sur-généralisation : la productivité ne suit « que dans les entreprises qui ont profondément revu leur organisation ». La réponse B inverse les résultats : compacter cinq jours en quatre a produit épuisement et marche arrière. La réponse C déforme un détail chiffré : seules deux sociétés sur quarante ont renoncé, pas « la plupart ». Mécanisme : **inférence de la cause réelle** d''un résultat, contre une inversion cause/effet tentante.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c002-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c002-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'Le texte affirme que le présentéisme « coûterait aux employeurs près du double de l''absentéisme » et que ce comportement est culturellement « valorisé » : **l''idée principale est le coût caché, supérieur et invisible, du travail effectué malade ou épuisé**. La réponse B inverse le rapport chiffré : c''est le présentéisme qui coûte le double, pas l''absentéisme. La réponse C est un **détail vrai mais secondaire** promu en idée principale : la contamination en open space n''est qu''un exemple parmi d''autres (erreurs, convalescences). La réponse D contredit la conclusion : les campagnes restent « des affiches dans les couloirs », elles n''ont rien transformé. Mécanisme : hiérarchiser **idée principale vs détail illustratif**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c002-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c002-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Quelle est l''intention principale de l''auteur de ce texte ?',
   'Le texte refuse à la fois la moquerie (« Il serait tentant de moquer ces vocations tardives… Ce serait passer à côté ») et l''idéalisation (« ni une lubie ni un paradis ») : **l''intention est de prendre ces reconversions au sérieux tout en soulignant l''exigence de préparation**, illustrée par le tiers d''abandons avant trois ans. La réponse A inverse le ton : l''auteur ne dissuade pas, il met en garde contre l''impréparation. La réponse B reprend le « certain discours » que l''auteur cite précisément pour le réfuter. La réponse D inverse un détail explicite : les reconvertis acceptent de « diviser leur revenu par deux ». Mécanisme : **inférence d''intention** à partir d''une double réfutation (ni mépris ni enchantement), avec discours rapporté piège.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c002-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c002-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur à l''égard du flex office ?',
   'L''auteur concède que « l''argument économique est imparable », avant de retourner le propos avec « Mais ce que les tableurs ne mesurent pas… » : **sa position est une critique nuancée — logique financière admise, coût caché sur la cohésion dénoncé**. La réponse A ignore la concession : il ne juge pas la réduction des surfaces absurde, il en reconnaît la rationalité. La réponse C sur-généralise un détail : seuls « certains salariés » apprécient de choisir leur place. La réponse D transforme la mise en garde finale (les directions « découvriront » le désengagement) en fait déjà démontré. Mécanisme : repérer la **concession rhétorique** (reconnaissons-le… mais) qui signale un jugement critique, non une adhésion.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c002-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c002-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Selon ce texte, pourquoi les réunions inutiles persistent-elles dans les entreprises ?',
   'Les sociologues cités expliquent que la réunion « rassure le chef », « donne le sentiment d''exister » et « protège des positions, des territoires, des statuts » : **les réunions persistent parce qu''elles remplissent des fonctions sociales cachées que nul n''a intérêt à abolir**. La réponse A contredit la chute : le problème « n''a jamais été le manque de bonnes pratiques ». La réponse B déforme un chiffre : les seize heures hebdomadaires sont un constat subi, pas un plaisir revendiqué. La réponse C inverse le diagnostic : les chartes échouent par **absence** de contrainte, l''exemple de Clermont-Ferrand montrant que seule une règle contraignante a fonctionné. Mécanisme : **inférence de la cause profonde** derrière un paradoxe apparent (tout le monde critique, rien ne change).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c002-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c002-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Que pense l''auteur du discours sur la passion au travail ?',
   'L''auteur qualifie la formule de « piège le mieux décoré » et montre, enquête à l''appui, que la passion « sert en pratique de monnaie » au bénéfice des employeurs : **il dénonce une injonction trompeuse qui profite d''abord à ceux qui emploient**. La réponse B sur-généralise : il écrit au contraire qu''« aimer son travail est une chance, personne ne le nie » — c''est l''obligation d''aimer qu''il conteste. La réponse C inverse sa position : il défend le soignant consciencieux et la comptable fiable contre le reproche implicite qui leur est fait. La réponse D inverse le sens de l''enquête citée : elle révèle que les candidats « passionnés » se voient proposer de moins bonnes conditions. Mécanisme : **inférence du ton** (ironie de « cadeau » vs « piège ») et distinction entre ce que l''auteur affirme et ce qu''il dénonce.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — transparence des salaires (bonne réponse : position 2)
  ('11111111-c002-2100-0000-000000000001', '11111111-c002-1000-0000-000000000001',
   'La directive européenne fera automatiquement augmenter les salaires les plus bas',
   'false', '1'),

  ('11111111-c002-2200-0000-000000000001', '11111111-c002-1000-0000-000000000001',
   'Il soutient la directive parce qu''elle contraindra les employeurs à justifier leurs rémunérations',
   'true', '2'),

  ('11111111-c002-2300-0000-000000000001', '11111111-c002-1000-0000-000000000001',
   'Les inquiétudes des directions sont infondées car les écarts de salaire sont toujours justifiés',
   'false', '3'),

  ('11111111-c002-2400-0000-000000000001', '11111111-c002-1000-0000-000000000001',
   'Les entreprises devraient garder les rémunérations confidentielles pour préserver la paix sociale',
   'false', '4'),

  -- item 02 — semaine de quatre jours (bonne réponse : position 4)
  ('11111111-c002-2100-0000-000000000002', '11111111-c002-1000-0000-000000000002',
   'Elle a amélioré la productivité dans toutes les entreprises participantes',
   'false', '1'),

  ('11111111-c002-2200-0000-000000000002', '11111111-c002-1000-0000-000000000002',
   'Les entreprises qui ont compacté cinq jours de travail en quatre ont obtenu les meilleurs résultats',
   'false', '2'),

  ('11111111-c002-2300-0000-000000000002', '11111111-c002-1000-0000-000000000002',
   'La plupart des sociétés engagées ont abandonné l''expérimentation en cours de route',
   'false', '3'),

  ('11111111-c002-2400-0000-000000000002', '11111111-c002-1000-0000-000000000002',
   'Son succès dépend de la réorganisation du travail davantage que du jour de repos accordé',
   'true', '4'),

  -- item 03 — présentéisme (bonne réponse : position 1)
  ('11111111-c002-2100-0000-000000000003', '11111111-c002-1000-0000-000000000003',
   'Venir travailler malade coûte plus cher aux entreprises que les absences qu''elles surveillent de près',
   'true', '1'),

  ('11111111-c002-2200-0000-000000000003', '11111111-c002-1000-0000-000000000003',
   'L''absentéisme représente un coût deux fois plus élevé que le présentéisme pour les employeurs',
   'false', '2'),

  ('11111111-c002-2300-0000-000000000003', '11111111-c002-1000-0000-000000000003',
   'La contamination des collègues en open space est le principal risque du travail en équipe',
   'false', '3'),

  ('11111111-c002-2400-0000-000000000003', '11111111-c002-1000-0000-000000000003',
   'Les campagnes de santé au travail ont profondément transformé les comportements des salariés',
   'false', '4'),

  -- item 04 — reconversion vers les métiers manuels (bonne réponse : position 3)
  ('11111111-c002-2100-0000-000000000004', '11111111-c002-1000-0000-000000000004',
   'Dissuader les cadres de quitter leur poste pour un métier manuel',
   'false', '1'),

  ('11111111-c002-2200-0000-000000000004', '11111111-c002-1000-0000-000000000004',
   'Montrer que ces reconversions ne sont qu''une mode passagère de citadins lassés des réunions',
   'false', '2'),

  ('11111111-c002-2300-0000-000000000004', '11111111-c002-1000-0000-000000000004',
   'Prendre ces reconversions au sérieux tout en rappelant qu''elles exigent une solide préparation',
   'true', '3'),

  ('11111111-c002-2400-0000-000000000004', '11111111-c002-1000-0000-000000000004',
   'Prouver que les métiers manuels rapportent davantage que les postes de cadre',
   'false', '4'),

  -- item 05 — flex office (bonne réponse : position 2)
  ('11111111-c002-2100-0000-000000000005', '11111111-c002-1000-0000-000000000005',
   'Il rejette toute réduction des surfaces de bureaux, qu''il juge économiquement absurde',
   'false', '1'),

  ('11111111-c002-2200-0000-000000000005', '11111111-c002-1000-0000-000000000005',
   'Il en admet la logique économique mais redoute son coût caché sur la cohésion des équipes',
   'true', '2'),

  ('11111111-c002-2300-0000-000000000005', '11111111-c002-1000-0000-000000000005',
   'Il constate que les salariés sont unanimement satisfaits de choisir leur place chaque matin',
   'false', '3'),

  ('11111111-c002-2400-0000-000000000005', '11111111-c002-1000-0000-000000000005',
   'Il démontre que le flex office a déjà fait fuir la majorité des salariés des sièges sociaux',
   'false', '4'),

  -- item 06 — réunionite (bonne réponse : position 4)
  ('11111111-c002-2100-0000-000000000006', '11111111-c002-1000-0000-000000000006',
   'Parce que les salariés ignorent encore les bonnes pratiques d''animation de réunion',
   'false', '1'),

  ('11111111-c002-2200-0000-000000000006', '11111111-c002-1000-0000-000000000006',
   'Parce que les cadres apprécient de consacrer seize heures par semaine à se réunir',
   'false', '2'),

  ('11111111-c002-2300-0000-000000000006', '11111111-c002-1000-0000-000000000006',
   'Parce que les chartes de réunions efficaces imposent des contraintes trop lourdes aux équipes',
   'false', '3'),

  ('11111111-c002-2400-0000-000000000006', '11111111-c002-1000-0000-000000000006',
   'Parce qu''elles remplissent des fonctions sociales que personne n''a intérêt à remettre en cause',
   'true', '4'),

  -- item 07 — injonction à la passion (bonne réponse : position 1)
  ('11111111-c002-2100-0000-000000000007', '11111111-c002-1000-0000-000000000007',
   'Il y voit une injonction trompeuse qui profite d''abord aux employeurs',
   'true', '1'),

  ('11111111-c002-2200-0000-000000000007', '11111111-c002-1000-0000-000000000007',
   'Il considère qu''aimer son travail est devenu impossible dans le monde professionnel actuel',
   'false', '2'),

  ('11111111-c002-2300-0000-000000000007', '11111111-c002-1000-0000-000000000007',
   'Il reproche aux salariés simplement compétents leur manque d''enthousiasme',
   'false', '3'),

  ('11111111-c002-2400-0000-000000000007', '11111111-c002-1000-0000-000000000007',
   'Il recommande aux recruteurs de privilégier les candidats qui se déclarent passionnés',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c002-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « monde du travail », 7 angles tous différents :
--     transparence des salaires / semaine de quatre jours / présentéisme /
--     reconversion vers les métiers manuels / flex office / réunionite /
--     injonction à la passion au travail. Aucun thème interdit (ni emploi &
--     chômage, ni télétravail, ni économie & consommation…).
-- [x] Textes B2 longs : 184 / 186 / 193 / 201 / 207 / 203 / 230 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (concession « imparable… mais », « deux sociétés » vs « la plupart »,
--     inversion du double absentéisme/présentéisme, discours rapporté réfuté).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2 (items 1, 3),
--     ce_inference_intention ×3 (items 2, 4, 6), ce_ton_auteur ×2 (items 5, 7).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme nommé
--     (concession rhétorique, inversion cause/effet, inférence d'intention,
--     détail vrai mais secondaire, sur-généralisation, discours rapporté).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (prénoms, villes, chiffres,
--     instituts et études inventés).
-- ============================================================================
