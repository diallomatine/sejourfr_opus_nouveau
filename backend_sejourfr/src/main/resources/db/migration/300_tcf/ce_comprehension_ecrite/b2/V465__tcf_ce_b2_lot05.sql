-- ============================================================================
-- V465 — TCF CE B2 — lot 05 (thème : santé publique)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~200-220 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : déserts médicaux, antibiorésistance, santé mentale des jeunes,
-- pénuries de médicaments, défiance vaccinale, prévention vs curatif,
-- crise de l'hôpital public.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c005-4000-0000-000000000001', 'TEXTE',
   'Six millions de Français vivent aujourd''hui dans une zone où trouver un médecin traitant relève du parcours du combattant. À Guéret comme à Provins, des patients renoncent à consulter, repoussent un examen, laissent s''installer une douleur qui aurait pu être traitée à temps. Le phénomène, longtemps cantonné aux campagnes isolées, gagne désormais les périphéries des grandes villes.

Face à cette pénurie, la tentation est grande de contraindre : obliger les jeunes diplômés à s''installer quelques années dans les territoires délaissés, comme on l''impose déjà aux pharmaciens. La mesure séduit l''opinion, et l''on comprend pourquoi. Elle se heurte pourtant à une réalité têtue : on ne soigne pas bien là où l''on ne veut pas vivre. Les expériences menées à l''étranger le confirment : les praticiens contraints repartent dès la fin de leur obligation, laissant le territoire à son point de départ.

La véritable réponse est moins spectaculaire : créer les conditions qui donnent envie de rester. Maisons de santé pluridisciplinaires, postes salariés pour ceux que la gestion d''un cabinet rebute, accueil du conjoint, délégation de certains actes aux infirmiers. Plusieurs départements pionniers, qui ont mené ce travail patient pendant dix ans, regagnent aujourd''hui des praticiens. La coercition flatte l''impatience collective ; seule l''attractivité soigne durablement les déserts.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c005-4000-0000-000000000002', 'TEXTE',
   'Les infections dues à des bactéries résistantes aux antibiotiques causent environ 5 500 décès par an en France, davantage que les accidents de la route. Le mécanisme est connu de longue date : plus on consomme d''antibiotiques, plus les bactéries apprennent à leur résister. Or la France demeure l''un des plus gros consommateurs d''Europe, environ 30 % au-dessus de la moyenne continentale, malgré vingt ans de campagnes rappelant qu''ils ne sont « pas automatiques ».

Pourquoi un tel échec ? On accuse volontiers le patient, qui exigerait son ordonnance. La réalité observée en consultation est plus nuancée : plusieurs études montrent que les médecins surestiment largement cette attente et prescrivent « par précaution » des traitements que la plupart des patients n''avaient pas réclamés. S''ajoute la contrainte du temps : expliquer pourquoi un antibiotique est inutile contre un virus prend dix minutes ; le prescrire en prend une.

Des leviers existent pourtant : tests rapides qui distinguent en quelques minutes une angine virale d''une angine bactérienne, ordonnances dites « de non-prescription », formation continue des prescripteurs. Les pays scandinaves, qui les ont généralisés, prescrivent deux fois moins sans observer davantage de complications. La surconsommation française n''est donc pas une fatalité culturelle : c''est un problème d''organisation des soins. Et l''organisation, contrairement aux mentalités, se réforme.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c005-4000-0000-000000000003', 'TEXTE',
   'Les chiffres s''accumulent, et avec eux une forme d''accoutumance qui devrait inquiéter autant que les chiffres eux-mêmes. Passages aux urgences pour gestes auto-infligés en forte hausse chez les adolescentes depuis cinq ans, consommation d''antidépresseurs en progression constante chez les mineurs, huit à douze mois d''attente pour un premier rendez-vous en centre médico-psychologique : chaque rapport confirme le précédent, chaque alerte succède à une alerte restée sans réponse.

On a d''abord incriminé la pandémie, puis les écrans, puis l''angoisse de l''avenir. Ces explications contiennent sans doute chacune une part de vérité, mais elles partagent un défaut commode : elles permettent de discourir sur les causes plutôt que d''agir sur les réponses. Car pendant que l''on débat, la pédopsychiatrie s''effondre en silence : un tiers des postes hospitaliers vacants, des départements entiers privés du moindre praticien, des familles contraintes de payer des consultations privées hors de portée des plus modestes.

Le dispositif public qui rembourse quelques séances chez un psychologue de ville a le mérite d''exister, et il serait injuste de le balayer. Mais offrir douze séances à des adolescents dont certains nécessitent des années de suivi revient à écoper l''océan avec une cuillère. La santé mentale des jeunes a été proclamée grande cause nationale ; il serait temps que les moyens cessent de démentir l''affiche.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c005-4000-0000-000000000004', 'TEXTE',
   'Monsieur le Ministre,

Au nom des huit cents pharmaciens d''officine que notre fédération représente, je souhaite appeler votre attention sur une situation qui ne relève plus de l''incident, mais de la crise installée. L''an dernier, nos adhérents ont signalé en moyenne quarante références manquantes par semaine et par officine : antibiotiques pédiatriques, traitements du diabète, anticancéreux, corticoïdes. Il y a dix ans, ces ruptures se comptaient sur les doigts d''une main.

Nos équipes passent désormais plusieurs heures par jour à téléphoner aux grossistes, à fractionner des boîtes, à joindre les prescripteurs pour adapter des ordonnances. Ce travail invisible n''est ni reconnu ni indemnisé ; surtout, il ne résout rien, car la cause est ailleurs : la production des principes actifs, délocalisée pour l''essentiel hors d''Europe, échappe à toute maîtrise, et les prix administrés français, parmi les plus bas du continent, conduisent les laboratoires à servir nos voisins en priorité.

Nous ne demandons pas un traitement de faveur, mais un plan crédible : des stocks obligatoires réellement contrôlés, une relocalisation ciblée des molécules essentielles, une révision du prix des médicaments anciens. À défaut, nous continuerons de gérer la pénurie au comptoir — et d''en porter seuls la responsabilité devant des patients inquiets.

Veuillez agréer, Monsieur le Ministre, l''expression de ma haute considération.

Sabine Okonkwo, présidente de la Fédération régionale des pharmaciens d''officine',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c005-4000-0000-000000000005', 'TEXTE',
   'La France cultive un paradoxe bien documenté : patrie de Pasteur, elle figure régulièrement parmi les pays les plus méfiants au monde à l''égard des vaccins. Une enquête conduite au printemps auprès de quatre mille adultes le confirme : un tiers des personnes interrogées doutent de la sécurité des vaccins en général, alors même que la grande majorité d''entre elles déclarent suivre la recommandation de leur propre médecin lorsqu''il leur en propose un.

Ce grand écart dit quelque chose d''essentiel, que les autorités sanitaires tardent à entendre : la défiance ne vise pas tant le geste vaccinal que les institutions qui le promeuvent. Scandales sanitaires anciens, communication descendante, soupçons de liens d''intérêts entre experts et industrie : le passif est lourd, et aucune campagne d''affichage, si bien conçue soit-elle, ne le soldera.

Les pays qui ont regagné du terrain l''ont compris. Le Portugal, dont la couverture vaccinale compte parmi les meilleures d''Europe, mise depuis vingt ans sur la relation individuelle : chaque hésitation y est accueillie en consultation comme une question légitime, jamais comme une faute morale. À l''inverse, traiter les hésitants en ignorants les pousse vers ceux qui, eux, prennent le temps de leur parler — au premier rang desquels les marchands de fausses certitudes. La confiance ne se décrète pas : elle se reconstruit, un entretien après l''autre.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c005-4000-0000-000000000006', 'TEXTE',
   'Notre système de santé excelle à réparer et néglige de prévenir. Le constat n''est pas neuf, mais les chiffres gardent leur pouvoir d''étonnement : la France consacre à peine 2 % de ses dépenses de santé à la prévention, près de deux fois moins que plusieurs de ses voisins. Résultat : une espérance de vie globale parmi les meilleures du monde, mais une espérance de vie en bonne santé inférieure de deux ans à la moyenne européenne. Nous vivons vieux, mais malades.

Pourquoi cette anomalie persiste-t-elle ? D''abord parce que la prévention rapporte à long terme quand la décision politique raisonne à court terme : un dépistage organisé aujourd''hui évite des cancers dans quinze ans, autant dire après plusieurs alternances. Ensuite parce que notre organisation rémunère l''acte de soin, jamais le temps passé à le rendre inutile : un médecin payé à la consultation n''a objectivement aucun intérêt financier à vider sa salle d''attente, ce qui ne signifie pas, bien sûr, qu''il s''en réjouisse.

Il ne s''agit pas d''opposer soin et prévention : un système qui dépisterait tout mais soignerait mal n''aurait rien d''enviable. Il s''agit de rééquilibrer. Tant que la santé publique restera le parent pauvre des arbitrages budgétaires, nous continuerons de payer au prix fort, en maladies évitables, les économies réalisées sur la prévention.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c005-4000-0000-000000000007', 'TEXTE',
   'On nous promet, à chaque rentrée, le « réarmement » de l''hôpital public. Les milliards annoncés succèdent aux milliards annoncés, les missions d''évaluation aux comités de pilotage, et pendant ce temps, dans les couloirs de l''hôpital de Mont-de-Marsan comme partout ailleurs, les infirmières continuent de partir. Près de mille trois cents lits ont fermé l''an dernier dans le pays — non par décision budgétaire, précisons-le, mais faute de personnel pour s''occuper de ceux qui les auraient occupés.

Qu''on ne s''y méprenne pas : les revalorisations salariales consenties ces dernières années étaient nécessaires, et il serait malhonnête de les passer sous silence. Mais l''argent ne répond qu''à une partie du problème. Ce que disent les soignants qui démissionnent — et les enquêtes le confirment, étude après étude —, c''est d''abord la perte de sens : des plannings bouleversés la veille pour le lendemain, des ratios de patients par infirmière parmi les plus élevés d''Europe, le sentiment de mal faire un métier choisi pour bien faire.

Tant que les plans hospitaliers compteront les milliards plutôt que les conditions concrètes d''exercice, ils manqueront leur cible. On ne retient pas des professionnels par des enveloppes ; on les retient en leur rendant possible le travail bien fait. Le jour où cette évidence guidera enfin une réforme, l''hôpital cessera peut-être de se vider.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c005-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c005-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est la position défendue par l''auteur de ce texte ?',
   'L''auteur conclut : « La coercition flatte l''impatience collective ; seule l''attractivité soigne durablement les déserts ». **La thèse défendue est qu''il faut donner envie aux médecins de s''installer, non les y contraindre.** La réponse A inverse cette position : l''obligation d''installation est précisément la mesure que l''auteur écarte (« on ne soigne pas bien là où l''on ne veut pas vivre »). La réponse C contredit un fait du texte : le phénomène « gagne désormais les périphéries des grandes villes », il n''est plus limité aux campagnes. La réponse D détourne un détail : l''obligation des pharmaciens est citée comme simple comparaison, jamais remise en cause. Mécanisme testé : distinguer la **thèse défendue** de la mesure populaire rapportée puis réfutée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c005-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c005-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur la surconsommation d''antibiotiques en France ?',
   'Le texte établit que « les médecins surestiment largement cette attente » des patients et conclut : « c''est un problème d''organisation des soins ». **La cause centrale relève des pratiques de prescription et de l''organisation, pas d''une exigence des malades.** La réponse A contredit le constat d''échec : malgré vingt ans de campagnes, la consommation reste 30 % au-dessus de la moyenne européenne. La réponse B reprend l''idée reçue que le texte réfute explicitement (les traitements sont prescrits « par précaution », non réclamés). La réponse C déplace un détail : les tests rapides sont généralisés dans les pays scandinaves, pas en France. Mécanisme : **inférence de la cause principale** contre une idée reçue tentante (le patient demandeur).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c005-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c005-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Comment l''auteur juge-t-il la réponse publique à la crise de la santé mentale des jeunes ?',
   'Les images finales — « écoper l''océan avec une cuillère », des moyens qui « démentent l''affiche » — révèlent un **jugement très critique : la réponse publique est dérisoire face à l''effondrement de la pédopsychiatrie** (un tiers des postes vacants, départements sans praticien). La réponse B prend la concession (« a le mérite d''exister ») pour la conclusion, alors que le « Mais » qui suit la retourne. La réponse C inverse le propos : l''auteur reproche justement de « discourir sur les causes plutôt que d''agir sur les réponses ». La réponse D promeut en thèse l''une des explications que le texte relativise (pandémie, écrans, angoisse de l''avenir). Mécanisme : **ton de l''auteur** repéré par la concession retournée et l''ironie des images.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c005-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c005-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Quel est l''objectif principal de ce courrier ?',
   'La demande est formulée au dernier paragraphe : « Nous ne demandons pas un traitement de faveur, mais un plan crédible : des stocks obligatoires…, une relocalisation ciblée…, une révision du prix ». **L''objectif est d''obtenir des mesures structurelles contre les pénuries.** La réponse A transforme un **détail vrai mais secondaire** (le travail « ni reconnu ni indemnisé ») en demande centrale, alors que la lettre précise que ce travail « ne résout rien ». La réponse B se trompe de cible : les grossistes sont seulement appelés au téléphone, la cause désignée est la délocalisation de la production et les prix administrés. La réponse D contredit la dénégation explicite (« Nous ne demandons pas un traitement de faveur »). Mécanisme : **inférence d''intention** dans un courrier formel, détail vs demande principale.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c005-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c005-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'Le texte affirme que « la défiance ne vise pas tant le geste vaccinal que les institutions qui le promeuvent » et conclut que la confiance « se reconstruit, un entretien après l''autre ». **L''idée principale articule ces deux temps : défiance institutionnelle, réponse par la relation individuelle.** La réponse B inverse le détail-chiffre : la grande majorité des sondés suit justement la recommandation de son propre médecin. La réponse C contredit une affirmation explicite : « aucune campagne d''affichage, si bien conçue soit-elle, ne le soldera ». La réponse D inverse l''exemple portugais, où l''hésitation est accueillie « comme une question légitime, jamais comme une faute morale ». Mécanisme : **thème vs propos** — résister aux distracteurs qui inversent le sondage ou l''exemple.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c005-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c005-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Que cherche à montrer l''auteur de ce texte ?',
   'La conclusion porte le propos : « nous continuerons de payer au prix fort, en maladies évitables, les économies réalisées sur la prévention ». **L''auteur démontre que le sous-investissement chronique dans la prévention coûte finalement très cher.** La réponse A déforme le **détail-piège** : c''est l''espérance de vie en bonne santé qui est inférieure de deux ans à la moyenne, l''espérance de vie globale restant « parmi les meilleures du monde ». La réponse B sur-étend la thèse : l''auteur refuse explicitement « d''opposer soin et prévention » et parle de rééquilibrer. La réponse D sur-généralise un mécanisme financier en intention coupable, que le texte écarte (« ce qui ne signifie pas, bien sûr, qu''il s''en réjouisse »). Mécanisme : **détail vs idée principale** et résistance à la sur-généralisation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c005-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c005-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Comment l''auteur se positionne-t-il face aux mesures prises pour l''hôpital public ?',
   'Le mouvement concessif structure le texte : « les revalorisations salariales… étaient nécessaires… Mais l''argent ne répond qu''à une partie du problème ». **L''auteur reconnaît les efforts financiers tout en jugeant qu''ils manquent le cœur du problème : la perte de sens et les conditions d''exercice.** La réponse A contredit la concession explicite (« il serait malhonnête de les passer sous silence »). La réponse C inverse un détail précis : les lits ont fermé « non par décision budgétaire… mais faute de personnel ». La réponse D contredit la thèse : « On ne retient pas des professionnels par des enveloppes ». Mécanisme : la **concession rhétorique** (certes… mais) exprime un jugement nuancé, ni déni des efforts ni satisfaction.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — déserts médicaux (bonne réponse : position 2)
  ('11111111-c005-2100-0000-000000000001', '11111111-c005-1000-0000-000000000001',
   'L''obligation d''installation des jeunes médecins est la solution la plus efficace contre les déserts médicaux',
   'false', '1'),

  ('11111111-c005-2200-0000-000000000001', '11111111-c005-1000-0000-000000000001',
   'Seule l''amélioration des conditions d''exercice convaincra durablement les médecins de s''installer dans les zones délaissées',
   'true', '2'),

  ('11111111-c005-2300-0000-000000000001', '11111111-c005-1000-0000-000000000001',
   'Les déserts médicaux restent un problème limité aux campagnes les plus isolées',
   'false', '3'),

  ('11111111-c005-2400-0000-000000000001', '11111111-c005-1000-0000-000000000001',
   'Les pharmaciens devraient être dispensés de leurs obligations d''installation',
   'false', '4'),

  -- item 02 — antibiorésistance (bonne réponse : position 4)
  ('11111111-c005-2100-0000-000000000002', '11111111-c005-1000-0000-000000000002',
   'Les campagnes de sensibilisation ont ramené la consommation française dans la moyenne européenne',
   'false', '1'),

  ('11111111-c005-2200-0000-000000000002', '11111111-c005-1000-0000-000000000002',
   'Les patients français exigent presque systématiquement une prescription d''antibiotiques',
   'false', '2'),

  ('11111111-c005-2300-0000-000000000002', '11111111-c005-1000-0000-000000000002',
   'Les tests rapides de diagnostic sont déjà généralisés dans les cabinets français',
   'false', '3'),

  ('11111111-c005-2400-0000-000000000002', '11111111-c005-1000-0000-000000000002',
   'Elle tient davantage à l''organisation des soins qu''à une exigence réelle des patients',
   'true', '4'),

  -- item 03 — santé mentale des jeunes (bonne réponse : position 1)
  ('11111111-c005-2100-0000-000000000003', '11111111-c005-1000-0000-000000000003',
   'Il la juge dérisoire au regard de l''effondrement silencieux de la pédopsychiatrie',
   'true', '1'),

  ('11111111-c005-2200-0000-000000000003', '11111111-c005-1000-0000-000000000003',
   'Il estime que le remboursement de séances de psychologue règle l''essentiel du problème',
   'false', '2'),

  ('11111111-c005-2300-0000-000000000003', '11111111-c005-1000-0000-000000000003',
   'Il considère qu''il faut d''abord identifier les causes de la crise avant d''agir',
   'false', '3'),

  ('11111111-c005-2400-0000-000000000003', '11111111-c005-1000-0000-000000000003',
   'Il attribue principalement la crise à l''usage des écrans par les adolescents',
   'false', '4'),

  -- item 04 — pénuries de médicaments (bonne réponse : position 3)
  ('11111111-c005-2100-0000-000000000004', '11111111-c005-1000-0000-000000000004',
   'Obtenir une indemnisation du temps passé par les équipes à gérer les ruptures de stock',
   'false', '1'),

  ('11111111-c005-2200-0000-000000000004', '11111111-c005-1000-0000-000000000004',
   'Dénoncer les grossistes, présentés comme les responsables des pénuries de médicaments',
   'false', '2'),

  ('11111111-c005-2300-0000-000000000004', '11111111-c005-1000-0000-000000000004',
   'Réclamer des mesures structurelles sur les stocks, la production et le prix des médicaments',
   'true', '3'),

  ('11111111-c005-2400-0000-000000000004', '11111111-c005-1000-0000-000000000004',
   'Demander un traitement de faveur pour les pharmacies de la région',
   'false', '4'),

  -- item 05 — défiance vaccinale (bonne réponse : position 1)
  ('11111111-c005-2100-0000-000000000005', '11111111-c005-1000-0000-000000000005',
   'La défiance vise les institutions plus que les vaccins et ne se résorbe que par la relation individuelle',
   'true', '1'),

  ('11111111-c005-2200-0000-000000000005', '11111111-c005-1000-0000-000000000005',
   'Les Français refusent désormais de suivre les recommandations vaccinales de leur propre médecin',
   'false', '2'),

  ('11111111-c005-2300-0000-000000000005', '11111111-c005-1000-0000-000000000005',
   'Des campagnes d''affichage mieux conçues suffiraient à restaurer la confiance dans les vaccins',
   'false', '3'),

  ('11111111-c005-2400-0000-000000000005', '11111111-c005-1000-0000-000000000005',
   'Le Portugal a amélioré sa couverture vaccinale en traitant l''hésitation comme une faute',
   'false', '4'),

  -- item 06 — prévention vs curatif (bonne réponse : position 3)
  ('11111111-c005-2100-0000-000000000006', '11111111-c005-1000-0000-000000000006',
   'L''espérance de vie des Français figure désormais parmi les plus faibles d''Europe',
   'false', '1'),

  ('11111111-c005-2200-0000-000000000006', '11111111-c005-1000-0000-000000000006',
   'Il faudrait consacrer l''essentiel des dépenses de santé à la prévention plutôt qu''au soin',
   'false', '2'),

  ('11111111-c005-2300-0000-000000000006', '11111111-c005-1000-0000-000000000006',
   'Le sous-investissement chronique dans la prévention finit par coûter très cher en maladies évitables',
   'true', '3'),

  ('11111111-c005-2400-0000-000000000006', '11111111-c005-1000-0000-000000000006',
   'Les médecins refusent de faire de la prévention afin de préserver leurs revenus',
   'false', '4'),

  -- item 07 — hôpital public (bonne réponse : position 2)
  ('11111111-c005-2100-0000-000000000007', '11111111-c005-1000-0000-000000000007',
   'Il nie que le moindre effort financier ait été consenti en faveur des soignants',
   'false', '1'),

  ('11111111-c005-2200-0000-000000000007', '11111111-c005-1000-0000-000000000007',
   'Il reconnaît les efforts salariaux mais juge qu''ils manquent le problème central, la perte de sens',
   'true', '2'),

  ('11111111-c005-2300-0000-000000000007', '11111111-c005-1000-0000-000000000007',
   'Il impute les fermetures de lits à des décisions d''économies budgétaires',
   'false', '3'),

  ('11111111-c005-2400-0000-000000000007', '11111111-c005-1000-0000-000000000007',
   'Il estime qu''une nouvelle hausse des salaires suffirait à retenir les soignants à l''hôpital',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c005-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « santé publique », 7 angles tous différents :
--     déserts médicaux / antibiorésistance / santé mentale des jeunes /
--     pénuries de médicaments (courrier formel) / défiance vaccinale /
--     prévention vs curatif / crise de l'hôpital public. Aucun thème interdit
--     (mentions ponctuelles d'écrans ou de retraite = simple arrière-plan,
--     l'angle reste sanitaire).
-- [x] Textes B2 longs : ~202 / 205 / 211 / 220 / 214 / 212 / 215 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (obligation des pharmaciens, tests rapides scandinaves, « a le mérite
--     d'exister », travail non indemnisé, espérance de vie globale vs en
--     bonne santé, « non par décision budgétaire »).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2 (items 1, 5),
--     ce_inference_intention ×3 (items 2, 4, 6), ce_ton_auteur ×2 (items 3, 7).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme nommé
--     (concession rhétorique, inversion cause/effet, inférence d'intention,
--     détail vrai mais secondaire, sur-généralisation, thème vs propos).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (prénoms, villes, chiffres inventés :
--     Guéret, Provins, Mont-de-Marsan, Sabine Okonkwo…).
-- ============================================================================
