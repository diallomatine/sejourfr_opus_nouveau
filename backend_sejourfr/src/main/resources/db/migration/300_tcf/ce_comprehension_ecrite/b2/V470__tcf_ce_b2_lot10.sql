-- ============================================================================
-- V470 — TCF CE B2 — lot 10 (thème : emploi & chômage)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~194-214 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : emploi des seniors, métiers en tension non pourvus, contrôle des
-- demandeurs d'emploi, territoires zéro chômeur, insertion des jeunes
-- diplômés, discours sur l'« assistanat », stigmate du chômage de longue durée.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c00a-4000-0000-000000000001', 'TEXTE',
   'À en croire les discours officiels, l''expérience des salariés âgés serait un trésor national. Les entreprises vantent la transmission des savoirs, les ministres célèbrent les « secondes carrières », et chaque réforme des retraites s''accompagne d''un plan pour l''emploi des seniors. La réalité des chiffres raconte une tout autre histoire : passé cinquante-cinq ans, à peine un Français sur deux occupe encore un emploi, et un chômeur de cet âge met en moyenne deux fois plus de temps qu''un trentenaire à retrouver un poste.

Le paradoxe devient brutal lorsqu''on le rapproche du report de l''âge de départ à la retraite. On demande aux salariés de travailler plus longtemps dans un marché du travail qui cesse de les recruter dès la cinquantaine. Quelques grandes entreprises, il est vrai, ont mis en place des programmes de recrutement dédiés, salués par la presse économique. Mais ces initiatives, aussi médiatisées soient-elles, concernent quelques centaines de postes par an : une goutte d''eau.

Tant que les employeurs continueront d''associer l''âge à un coût plutôt qu''à une compétence, repousser l''âge légal reviendra à fabriquer non pas des travailleurs supplémentaires, mais des chômeurs âgés. C''est par la lutte contre cette discrimination silencieuse qu''il fallait commencer.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00a-4000-0000-000000000002', 'TEXTE',
   'Comment un pays qui compte plusieurs millions de demandeurs d''emploi peut-il laisser, dans le même temps, des centaines de milliers de postes sans candidat ? Le paradoxe alimente depuis des années un procès commode : si les emplois ne trouvent pas preneurs, ce serait que les chômeurs ne veulent pas travailler. Une enquête publiée la semaine dernière par l''observatoire régional de l''emploi de Besançon vient rappeler combien cette explication est courte.

Sur les douze métiers les plus en tension étudiés — aide à domicile, conduite routière, hôtellerie, bâtiment —, les chercheurs identifient trois obstacles récurrents. Les salaires, d''abord, inférieurs de quinze pour cent à la moyenne pour des horaires souvent décalés. La géographie, ensuite : les postes vacants se concentrent dans des zones où le logement abordable manque, à des heures où les transports en commun ne circulent plus. La formation, enfin : un tiers des recrutements échouent faute de qualification adaptée, alors que les dispositifs existants restent sous-utilisés.

L''enquête note, certes, qu''une minorité de candidats renonce après une première expérience décourageante. Mais conclure de là à une paresse générale, c''est confondre le symptôme et la cause : ce ne sont pas les chômeurs qui fuient ces métiers, ce sont ces métiers qui, tels qu''ils sont organisés, restent infranchissables pour eux.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00a-4000-0000-000000000003', 'TEXTE',
   'Le gouvernement a annoncé, mardi, le triplement des contrôles de recherche d''emploi d''ici à deux ans. À l''appui de cette décision, un chiffre martelé sur tous les plateaux : dix-sept pour cent des dossiers contrôlés l''an dernier ont débouché sur une radiation. Présenté ainsi, le chiffre impressionne. Il mérite pourtant d''être regardé de près.

D''abord, les contrôles actuels ciblent en priorité les profils jugés « à risque » : le taux mesuré sur cette population triée ne dit rien de l''ensemble des inscrits. Ensuite, une radiation ne signifie pas une fraude : la majorité sanctionne un rendez-vous manqué ou un justificatif égaré, pas un refus de travailler. Enfin, et surtout, les études disponibles convergent : la fraude aux allocations chômage représente une part infime des sommes versées, sans commune mesure avec les cotisations éludées par certains employeurs, dix fois supérieures selon la Cour des comptes.

Que les contrôles existent, rien de plus normal : tout système de solidarité suppose des règles et leur vérification. Mais en faire l''alpha et l''oméga de la politique de l''emploi, au moment où les conseillers croulent sous les dossiers et manquent de temps pour accompagner, relève moins de la bonne gestion que de la mise en scène. On ne réduit pas le chômage en surveillant les chômeurs ; on le réduit en les aidant à en sortir.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00a-4000-0000-000000000004', 'TEXTE',
   'Lancée en 2017 dans une dizaine de communes, l''expérimentation « territoires zéro chômeur de longue durée » repose sur un pari simple : plutôt que de financer les conséquences du chômage, autant financer des emplois. Des entreprises dites « à but d''emploi » embauchent en contrat stable, au niveau du salaire minimum, des personnes privées de travail depuis plus d''un an, pour des activités utiles localement — maraîchage, recyclerie, aide aux personnes âgées — qu''aucune entreprise classique ne juge rentables.

Sept ans plus tard, le bilan humain force le respect. À Trélissac comme à Vervins, d''anciens chômeurs de longue durée racontent des vies remises en mouvement : santé retrouvée, dettes apurées, enfants qui revoient leurs parents se lever le matin. Les évaluations officielles confirment ces effets, tout en pointant une réserve sérieuse : le coût par emploi dépasse les prévisions initiales d''environ un tiers, car les personnes embauchées, plus éloignées de l''emploi qu''anticipé, nécessitent un accompagnement renforcé.

Les détracteurs s''emparent de ce surcoût pour réclamer l''arrêt du dispositif. C''est faire un étrange calcul : compare-t-on jamais ce surcoût à ce que coûte, en allocations, en soins, en désespoir, une vie entière sans travail ? L''expérimentation n''est pas une recette miracle ; elle est, à ce jour, l''une des rares réponses sérieuses au chômage d''exclusion. Elle mérite d''être étendue, et non rabotée.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00a-4000-0000-000000000005', 'TEXTE',
   '« Débutant accepté, deux ans d''expérience exigés » : la formule, repérée telle quelle dans une offre d''emploi par une association d''aide à l''insertion de Valenciennes, ferait sourire si elle ne résumait pas le mur auquel se heurtent les jeunes diplômés. Selon le baromètre annuel de l''association, sept offres sur dix destinées aux profils « juniors » réclament désormais une expérience préalable d''au moins dix-huit mois.

Comment acquérir de l''expérience quand chaque porte exige d''en avoir déjà ? La réponse, les jeunes la connaissent : par les stages et les contrats courts, enchaînés parfois pendant trois ou quatre ans après le diplôme. Cette période d''essai géante arrange tout le monde, sauf eux : les employeurs disposent d''une main-d''œuvre qualifiée, motivée et bon marché, tandis que l''entrée dans l''emploi stable — et avec elle l''accès au logement, au crédit, à l''autonomie — recule d''autant.

Les recruteurs interrogés se défendent : dans un contexte incertain, embaucher un profil sans références constitue un risque qu''ils ne peuvent plus se permettre. L''argument s''entend, mais il décrit moins une fatalité qu''un choix collectif : celui de faire porter le coût de la prudence des entreprises sur la génération qui peut le moins l''assumer. Un diplôme devait être un passeport ; il n''est plus qu''un visa d''attente.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00a-4000-0000-000000000006', 'TEXTE',
   '« Des assistés qui vivent du chômage » : la petite phrase, lâchée par un éditorialiste, a tourné en boucle et installé une image — celle d''un demandeur d''emploi confortablement indemnisé, peu pressé de retrouver un poste. Une donnée, pourtant publique, suffit à la fissurer : moins d''un inscrit sur deux perçoit une allocation chômage. Les autres — droits épuisés, périodes travaillées trop courtes, démissions non couvertes — ne touchent rien, ou basculent vers les minima sociaux.

Quant au « confort » des indemnisés, il relève largement de la légende : l''allocation moyenne avoisine mille euros par mois, et la moitié des bénéficiaires perçoit moins. On objectera que des situations d''abus existent ; c''est vrai, comme dans tout système, et personne ne propose de les ignorer. Mais bâtir un discours public sur l''exception plutôt que sur la règle n''est pas une approximation innocente : c''est un choix rhétorique qui prépare l''opinion à des droits réduits.

À force de répéter qu''il est doux d''être chômeur, on finit par rendre inaudible la réalité statistique : celle d''une population majoritairement non indemnisée, précarisée, et qui, sondage après sondage, déclare d''abord vouloir travailler. Le débat sur l''assurance chômage mérite mieux que des caricatures ; il mérite des chiffres, et le courage de les regarder.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00a-4000-0000-000000000007', 'TEXTE',
   'L''économiste Awa Tounkara a mené, avec son équipe de l''université de Limoges, une expérience d''une simplicité redoutable : envoyer à six cents employeurs des candidatures rigoureusement identiques — même diplôme, mêmes compétences, même parcours — à un détail près, la durée de la période de chômage en cours. Verdict : le candidat sans emploi depuis vingt mois reçoit deux fois moins de réponses positives que celui qui ne l''est que depuis trois mois. À qualification égale, c''est donc bien la durée d''inactivité elle-même qui disqualifie.

Le mécanisme, connu des chercheurs sous le nom de « stigmate du chômage », fonctionne comme une prophétie autoréalisatrice : les recruteurs interprètent un long passage sans emploi comme le signe d''un problème caché — compétences rouillées, motivation douteuse —, ce qui prolonge le chômage, ce qui renforce le soupçon. Plus la personne cherche longtemps, moins elle a de chances de trouver, indépendamment de sa valeur réelle.

L''étude relève une exception encourageante : mentionner une activité pendant la période — bénévolat, formation, projet personnel — réduit nettement l''écart. Mais cette parade individuelle ne corrige pas la défaillance d''ensemble : un marché du travail qui élimine les candidats sur la longueur de leur recherche plutôt que sur leurs aptitudes se prive de talents et fabrique, méthodiquement, le chômage de longue durée qu''il prétend déplorer.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c00a-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00a-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale défendue par l''auteur ?',
   'La conclusion du texte est explicite : « C''est par la lutte contre cette discrimination silencieuse qu''il fallait commencer ». **L''idée principale : combattre la discrimination par l''âge aurait dû précéder le report de l''âge de la retraite.** La réponse A est une sur-généralisation du détail-piège : les programmes dédiés de quelques grandes entreprises ne concernent que « quelques centaines de postes par an : une goutte d''eau ». La réponse C inverse les faits : le report de la retraite n''a pas amélioré l''emploi des seniors, il risque de « fabriquer des chômeurs âgés ». La réponse D inverse un détail chiffré : un chômeur âgé met deux fois **plus** de temps qu''un trentenaire à retrouver un poste. Mécanisme : distinguer la **thèse conclusive** d''un détail vrai mais secondaire promu en solution.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c00a-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00a-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur les emplois qui ne trouvent pas de candidats ?',
   'La conclusion renverse le procès en paresse : « ce ne sont pas les chômeurs qui fuient ces métiers, ce sont ces métiers qui restent infranchissables pour eux ». **La cause des postes vacants tient aux conditions des métiers eux-mêmes (salaires, localisation, qualification), pas à un refus de travailler.** La réponse A sur-généralise le détail-piège : seule « une minorité de candidats » renonce après une première expérience. La réponse B contredit un détail explicite : les dispositifs de formation existent mais « restent sous-utilisés », ils ne manquent pas. La réponse C invente une cause absente et inverse la logique du texte, qui ne lie jamais les difficultés de recrutement à une baisse du nombre de demandeurs d''emploi. Mécanisme : **inférence de la cause principale** contre une explication commode démentie par le texte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c00a-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00a-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur à l''égard du renforcement des contrôles des demandeurs d''emploi ?',
   'L''auteur concède que les contrôles sont « normaux » dans tout système de solidarité, puis retourne la concession : en faire « l''alpha et l''oméga de la politique de l''emploi relève moins de la bonne gestion que de la mise en scène ». **Sa position : il admet le principe du contrôle mais dénonce une mesure d''affichage qui néglige l''accompagnement.** La réponse B sur-étend la critique : il ne réclame jamais la suppression des contrôles, qu''il juge légitimes. La réponse C inverse le propos : la fraude est « une part infime des sommes versées », pas un phénomène massif. La réponse D déforme un détail : la majorité des radiations sanctionne un rendez-vous manqué ou un justificatif égaré, « pas un refus de travailler ». Mécanisme : repérer la **concession rhétorique** (rien de plus normal… mais) qui introduit une critique, non une adhésion.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c00a-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00a-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'Le texte reconnaît la réserve des évaluations (un coût supérieur d''un tiers aux prévisions) mais conclut : « Elle mérite d''être étendue, et non rabotée ». **L''idée principale : malgré un surcoût réel, l''expérimentation fait ses preuves et doit être élargie.** La réponse A reprend la position des détracteurs, que l''auteur réfute explicitement (« C''est faire un étrange calcul »). La réponse B contredit un détail : les activités confiées sont précisément celles « qu''aucune entreprise classique ne juge rentables » — la rentabilité n''est pas l''objectif. La réponse D nie le détail-piège : le dispositif n''a justement PAS tenu ses promesses financières, le coût dépasse les prévisions d''environ un tiers. Mécanisme : identifier la **thèse défendue** face à un distracteur qui reprend l''opinion adverse rapportée dans le texte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c00a-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00a-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Que cherche à montrer l''auteur de ce texte ?',
   'L''auteur conclut que l''exigence d''expérience pour les débutants relève d''« un choix collectif : celui de faire porter le coût de la prudence des entreprises sur la génération qui peut le moins l''assumer ». **Son intention : dénoncer un système qui fait payer aux jeunes la frilosité des employeurs.** La réponse A inverse le constat : les stages et contrats courts retardent l''entrée dans l''emploi stable au lieu de l''accélérer (« recule d''autant »). La réponse C prend pour thèse un **argument rapporté** : la justification des recruteurs est citée puis relativisée (« L''argument s''entend, mais… »). La réponse D sur-généralise la métaphore finale : le diplôme devient un « visa d''attente », ce qui signifie qu''il ne suffit plus, pas qu''il ne sert à rien. Mécanisme : **inférence d''intention** — distinguer la voix de l''auteur des positions qu''il rapporte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c00a-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00a-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Quel est le ton adopté par l''auteur face au discours sur l''« assistanat » ?',
   'L''auteur oppose méthodiquement des données chiffrées (moins d''un inscrit sur deux indemnisé, allocation moyenne de mille euros) à la « petite phrase » de l''éditorialiste, tout en concédant que « des situations d''abus existent ». **Son ton : une réfutation argumentée par les chiffres, qui ne nie pas l''existence d''abus mais refuse d''en faire la règle.** La réponse B inverse la démonstration : le « confort » des indemnisés « relève largement de la légende ». La réponse C est démentie par l''engagement du texte : l''auteur tranche nettement, il ne se contente pas d''exposer deux positions. La réponse D sur-généralise le détail-piège : les abus sont reconnus comme une **exception**, jamais comme un phénomène massif. Mécanisme : analyse du **ton de l''auteur** — concession limitée (c''est vrai… mais) au service d''une réfutation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c00a-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00a-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur le chômage de longue durée ?',
   'L''expérience montre qu''« à qualification égale, c''est la durée d''inactivité elle-même qui disqualifie », et le texte décrit une « prophétie autoréalisatrice » : le soupçon des recruteurs prolonge le chômage, qui renforce le soupçon. **L''information centrale : la durée du chômage devient une cause de non-embauche et entretient un cercle vicieux.** La réponse A contredit le protocole : les candidatures étaient « rigoureusement identiques », l''écart joue « indépendamment de la valeur réelle » des candidats. La réponse B sur-généralise le détail-piège : mentionner une activité « réduit nettement l''écart » mais « ne corrige pas la défaillance d''ensemble ». La réponse D inverse l''intention de l''auteur, qui présente la méfiance des recruteurs comme un préjugé infondé, pas comme une prudence légitime. Mécanisme : **inférence du mécanisme causal** (cercle vicieux) contre l''inversion cause/effet.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — emploi des seniors (bonne réponse : position 2)
  ('11111111-c00a-2100-0000-000000000001', '11111111-c00a-1000-0000-000000000001',
   'Les programmes de recrutement des grandes entreprises ont réglé le problème de l''emploi des seniors',
   'false', '1'),

  ('11111111-c00a-2200-0000-000000000001', '11111111-c00a-1000-0000-000000000001',
   'La lutte contre la discrimination par l''âge aurait dû précéder le report de l''âge de la retraite',
   'true', '2'),

  ('11111111-c00a-2300-0000-000000000001', '11111111-c00a-1000-0000-000000000001',
   'Le report de l''âge de départ a nettement amélioré le taux d''emploi des plus de cinquante-cinq ans',
   'false', '3'),

  ('11111111-c00a-2400-0000-000000000001', '11111111-c00a-1000-0000-000000000001',
   'Les chômeurs âgés retrouvent un poste plus rapidement que les jeunes grâce à leur expérience',
   'false', '4'),

  -- item 02 — métiers en tension (bonne réponse : position 4)
  ('11111111-c00a-2100-0000-000000000002', '11111111-c00a-1000-0000-000000000002',
   'Les chômeurs abandonnent massivement ces métiers après une première expérience décevante',
   'false', '1'),

  ('11111111-c00a-2200-0000-000000000002', '11111111-c00a-1000-0000-000000000002',
   'Les dispositifs de formation font défaut pour les métiers les plus en tension',
   'false', '2'),

  ('11111111-c00a-2300-0000-000000000002', '11111111-c00a-1000-0000-000000000002',
   'La baisse du nombre de demandeurs d''emploi explique les difficultés de recrutement',
   'false', '3'),

  ('11111111-c00a-2400-0000-000000000002', '11111111-c00a-1000-0000-000000000002',
   'Les postes restent vacants surtout à cause de leurs conditions, non d''un refus de travailler',
   'true', '4'),

  -- item 03 — contrôles des demandeurs d'emploi (bonne réponse : position 1)
  ('11111111-c00a-2100-0000-000000000003', '11111111-c00a-1000-0000-000000000003',
   'Il en admet le principe mais y voit une mise en scène qui néglige l''accompagnement',
   'true', '1'),

  ('11111111-c00a-2200-0000-000000000003', '11111111-c00a-1000-0000-000000000003',
   'Il réclame la suppression de tout contrôle des demandeurs d''emploi',
   'false', '2'),

  ('11111111-c00a-2300-0000-000000000003', '11111111-c00a-1000-0000-000000000003',
   'Il salue une réponse efficace à une fraude massive aux allocations chômage',
   'false', '3'),

  ('11111111-c00a-2400-0000-000000000003', '11111111-c00a-1000-0000-000000000003',
   'Il estime que les radiations prouvent que la plupart des inscrits refusent de travailler',
   'false', '4'),

  -- item 04 — territoires zéro chômeur (bonne réponse : position 3)
  ('11111111-c00a-2100-0000-000000000004', '11111111-c00a-1000-0000-000000000004',
   'Le surcoût constaté justifie de mettre fin progressivement à l''expérimentation',
   'false', '1'),

  ('11111111-c00a-2200-0000-000000000004', '11111111-c00a-1000-0000-000000000004',
   'Les entreprises à but d''emploi sont devenues rentables au bout de sept ans',
   'false', '2'),

  ('11111111-c00a-2300-0000-000000000004', '11111111-c00a-1000-0000-000000000004',
   'Malgré un coût supérieur aux prévisions, le dispositif fait ses preuves et mérite d''être élargi',
   'true', '3'),

  ('11111111-c00a-2400-0000-000000000004', '11111111-c00a-1000-0000-000000000004',
   'Le dispositif a tenu toutes ses promesses financières depuis son lancement',
   'false', '4'),

  -- item 05 — jeunes diplômés (bonne réponse : position 2)
  ('11111111-c00a-2100-0000-000000000005', '11111111-c00a-1000-0000-000000000005',
   'Les stages et contrats courts permettent aux jeunes diplômés d''accéder rapidement à un emploi stable',
   'false', '1'),

  ('11111111-c00a-2200-0000-000000000005', '11111111-c00a-1000-0000-000000000005',
   'Les exigences d''expérience font payer aux jeunes diplômés la prudence des entreprises',
   'true', '2'),

  ('11111111-c00a-2300-0000-000000000005', '11111111-c00a-1000-0000-000000000005',
   'Le risque encouru par les recruteurs justifie de différer l''embauche des débutants',
   'false', '3'),

  ('11111111-c00a-2400-0000-000000000005', '11111111-c00a-1000-0000-000000000005',
   'Le diplôme ne joue plus aucun rôle dans l''accès au marché du travail',
   'false', '4'),

  -- item 06 — discours sur l'assistanat (bonne réponse : position 1)
  ('11111111-c00a-2100-0000-000000000006', '11111111-c00a-1000-0000-000000000006',
   'Une réfutation par les chiffres, qui reconnaît des abus sans en faire la règle',
   'true', '1'),

  ('11111111-c00a-2200-0000-000000000006', '11111111-c00a-1000-0000-000000000006',
   'Une adhésion prudente : il confirme que la plupart des chômeurs vivent confortablement de leurs allocations',
   'false', '2'),

  ('11111111-c00a-2300-0000-000000000006', '11111111-c00a-1000-0000-000000000006',
   'Une neutralité descriptive : il expose les deux positions sans prendre parti',
   'false', '3'),

  ('11111111-c00a-2400-0000-000000000006', '11111111-c00a-1000-0000-000000000006',
   'Une dénonciation des abus massifs commis par les demandeurs d''emploi',
   'false', '4'),

  -- item 07 — stigmate du chômage (bonne réponse : position 3)
  ('11111111-c00a-2100-0000-000000000007', '11111111-c00a-1000-0000-000000000007',
   'Les chômeurs de longue durée ont des compétences objectivement inférieures aux autres candidats',
   'false', '1'),

  ('11111111-c00a-2200-0000-000000000007', '11111111-c00a-1000-0000-000000000007',
   'Mentionner une activité pendant la période de chômage suffit à supprimer la discrimination',
   'false', '2'),

  ('11111111-c00a-2300-0000-000000000007', '11111111-c00a-1000-0000-000000000007',
   'La durée du chômage devient elle-même une cause de non-embauche et entretient un cercle vicieux',
   'true', '3'),

  ('11111111-c00a-2400-0000-000000000007', '11111111-c00a-1000-0000-000000000007',
   'Les recruteurs ont raison de se méfier des candidats restés longtemps sans emploi',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c00a-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « emploi & chômage », 7 angles tous différents :
--     discrimination des seniors / métiers en tension non pourvus /
--     contrôles des demandeurs d'emploi / territoires zéro chômeur /
--     insertion des jeunes diplômés / discours sur l'« assistanat » /
--     stigmate du chômage de longue durée. Aucun thème interdit
--     (pas de monde du travail générique, pas de télétravail).
-- [x] Textes B2 longs : 194 / 204 / 214 / 209 / 198 / 196 / 205 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (programmes seniors « goutte d'eau », minorité qui renonce,
--     radiations ≠ fraude, surcoût d'un tiers, argument des recruteurs,
--     abus reconnus comme exception, parade individuelle insuffisante).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2 (items 1, 4),
--     ce_inference_intention ×3 (items 2, 5, 7), ce_ton_auteur ×2 (items 3, 6).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme linguistique
--     nommé (concession rhétorique, inversion cause/effet, argument
--     rapporté, sur-généralisation, détail vrai mais secondaire).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (prénoms, villes, chiffres inventés).
-- ============================================================================
