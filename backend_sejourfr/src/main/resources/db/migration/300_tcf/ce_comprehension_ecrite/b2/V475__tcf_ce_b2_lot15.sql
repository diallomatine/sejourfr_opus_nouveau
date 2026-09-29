-- ============================================================================
-- V475 — TCF CE B2 — lot 15 (thème : sciences (vulgarisation))
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~180-207 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : crise de la réplication / cognition du poulpe / couleur des
-- dinosaures / ordinateur quantique / sommeil et mémoire / prévision des
-- éruptions volcaniques / vulgarisation scientifique indépendante.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c00f-4000-0000-000000000001', 'TEXTE',
   'En 2015, une équipe internationale a tenté de reproduire cent expériences publiées dans les meilleures revues de psychologie. Résultat : moins de quatre sur dix ont confirmé leurs conclusions initiales. Le séisme, depuis, n''a cessé d''agiter la discipline, et il serait commode d''y voir la preuve que la psychologie n''est pas une science. Commode, mais faux.

Car ce que révèle cette « crise de la réplication », c''est moins la faillite d''un domaine que la mécanique perverse de la publication scientifique. Les revues préfèrent les résultats spectaculaires aux vérifications laborieuses ; les carrières se construisent sur la nouveauté, jamais sur la confirmation. Un chercheur qui passe deux ans à reproduire l''étude d''un collègue n''en tirera ni poste ni prestige. Dans ces conditions, s''étonner que les résultats fragiles prolifèrent relève de l''hypocrisie.

La réponse est venue de la discipline elle-même : pré-enregistrement des hypothèses, partage des données, revues acceptant de publier des réplications. La psychologie, souvent moquée, est paradoxalement devenue le laboratoire des bonnes pratiques que la biologie ou la médecine commencent à peine à adopter. Une crise bien gérée, décidément, vaut mieux qu''une fausse assurance.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00f-4000-0000-000000000002', 'TEXTE',
   'Le poulpe n''a ni squelette, ni vie sociale, ni longévité : il meurt avant ses trois ans, souvent juste après la reproduction. Tout, chez lui, semblait condamner l''émergence d''une intelligence élaborée. C''est pourtant l''un des animaux les plus déconcertants que la science ait étudiés : il dévisse des bocaux, transporte des noix de coco pour s''en faire un abri, reconnaît les visages humains et semble même rêver, à en juger par les vagues de couleurs qui parcourent sa peau pendant son sommeil.

Le plus troublant n''est pas la performance, mais l''architecture qui la produit. Les deux tiers de ses neurones ne logent pas dans son cerveau mais dans ses bras, capables de goûter, d''explorer et de décider en partie seuls. Là où le chimpanzé ou le corbeau partagent avec nous un lointain ancêtre déjà doté d''un système nerveux centralisé, le poulpe a développé sa cognition sur une lignée séparée de la nôtre depuis plus de cinq cents millions d''années.

C''est précisément ce qui fait sa valeur scientifique : il prouve que l''évolution a inventé l''intelligence au moins deux fois, par des chemins radicalement différents. Étudier le poulpe, ce n''est pas s''attendrir sur un animal étrange ; c''est entrevoir ce que pourrait être un esprit construit sur d''autres plans que le nôtre.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00f-4000-0000-000000000003', 'TEXTE',
   'Pendant un siècle et demi, les dinosaures ont été peints de mémoire : gris, verdâtres, écailleux, mi-lézards mi-cauchemars. Faute d''indices, les illustrateurs faisaient au mieux, et personne ne pouvait leur en vouloir. Cette excuse a disparu en 2010, lorsque des chercheurs ont identifié, dans des plumes fossilisées vieilles de cent vingt-cinq millions d''années, des mélanosomes — ces organites microscopiques dont la forme détermine la couleur. En comparant leur géométrie à celle des oiseaux actuels, ils ont pu restituer le pelage rayé, roux et blanc, d''un petit dinosaure chinois.

Quinze ans plus tard, la liste des espèces dont la couleur est partiellement connue s''allonge chaque année. La science a fait sa part. Les musées, les manuels et le cinéma, beaucoup moins : on continue d''y croiser des reptiles ternes et nus que la recherche a pourtant remisés depuis longtemps. On invoque l''attente du public, qui « ne reconnaîtrait pas » un tyrannosaure partiellement emplumé. Curieux argument : le public n''a jamais demandé qu''on lui mente, il a appris à aimer les dinosaures qu''on lui montrait.

Rien n''oblige un film à être exact. Mais qu''on cesse de présenter comme scientifiques des images qui ont un demi-siècle de retard : la vérité paléontologique est devenue plus étonnante que la fiction.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00f-4000-0000-000000000004', 'TEXTE',
   'À en croire certains discours, l''ordinateur quantique serait sur le point de tout bouleverser : la chimie, la finance, la cryptographie, la découverte de médicaments. Les annonces se succèdent, chacune saluant un processeur « historique », chaque communiqué promettant la révolution pour la décennie en cours. Les laboratoires qui en sont à l''origine ont d''excellentes raisons d''entretenir cette fièvre : les financements suivent les promesses.

La réalité du terrain est plus austère. Les machines actuelles alignent quelques centaines de qubits, ces unités de calcul quantiques d''une fragilité extrême : la moindre vibration, le moindre écart de température détruit l''information qu''ils portent. Corriger ces erreurs exige de mobiliser des centaines de qubits physiques pour obtenir un seul qubit fiable — si bien que les applications réellement utiles demanderaient des machines des milliers de fois plus grandes que tout ce qui existe.

Faut-il en conclure que le quantique est une impasse ? Ce serait l''excès inverse. Les progrès des dix dernières années sont authentiques et réguliers, et quelques résultats récents sur la correction d''erreurs ont impressionné jusqu''aux sceptiques. Le plus probable est aussi le moins vendeur : ni révolution imminente, ni mirage, mais une lente conquête dont les fruits viendront sans prévenir, dans dix, vingt ou trente ans. La patience, hélas, n''a jamais fait lever de capitaux.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00f-4000-0000-000000000005', 'TEXTE',
   'Réviser toute la nuit avant un examen : la stratégie paraît héroïque, elle est surtout contre-productive. Depuis une vingtaine d''années, les neurosciences ont établi que le sommeil n''est pas une pause dans l''apprentissage, mais l''une de ses étapes décisives. Pendant le sommeil profond, l''hippocampe — cette structure qui enregistre les souvenirs récents — « rejoue » à grande vitesse les expériences de la journée et les transfère vers le cortex, où elles s''inscrivent durablement. Supprimer la nuit, c''est interrompre ce transfert : les informations restent en mémoire de travail, fragiles, et s''évaporent en quelques jours.

Une équipe de l''université de Liège l''a vérifié sur deux groupes d''étudiants : à quantité de révision égale, ceux qui avaient dormi sept heures retenaient, une semaine plus tard, près de quarante pour cent d''éléments de plus que les noctambules. Plus surprenant : une simple sieste de quatre-vingt-dix minutes après l''étude produisait déjà une partie de l''effet.

Ces résultats ne disent pas que dormir dispense d''apprendre — un cerveau reposé ne consolide que ce qu''on lui a confié. Ils disent qu''à travail égal, le sommeil constitue un multiplicateur gratuit, à la portée de chacun. Que des générations d''étudiants persistent à le sacrifier en dit long sur la distance entre la science et les habitudes.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00f-4000-0000-000000000006', 'TEXTE',
   'Prévoir une éruption volcanique relève d''un paradoxe : les volcans sont les catastrophes naturelles les mieux surveillées au monde, et pourtant les plus rétives au calendrier. Sismomètres, capteurs de gaz, mesures satellitaires de la déformation du sol : un volcan instrumenté annonce presque toujours son réveil, parfois des semaines à l''avance. Le magma qui monte fracture la roche, gonfle l''édifice, libère du dioxyde de soufre — autant de signaux que les observatoires savent lire.

Le problème commence après. Un volcan qui s''agite peut entrer en éruption dans trois jours, dans trois mois, ou se rendormir sans prévenir — un scénario qui se produit dans près d''un cas sur deux. Pour les autorités, l''équation est redoutable : évacuer trop tôt, c''est vider une région pendant des semaines pour rien, ruiner l''économie locale et user la confiance ; trop tard, c''est l''irréparable. Dans les années soixante-dix, l''évacuation de plusieurs mois d''une ville antillaise, au pied d''un volcan finalement resté calme, a durablement marqué la discipline : lors des alertes suivantes, ailleurs dans le monde, on hésita.

Les volcanologues le répètent : leur science fournit des probabilités, jamais des certitudes, et la décision d''évacuer ne leur appartient pas. Le véritable progrès viendra moins de nouveaux capteurs que d''une chose plus rare : des populations préparées à vivre avec l''incertitude.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00f-4000-0000-000000000007', 'TEXTE',
   'Ils s''appellent chaînes, podcasts ou infolettres, comptent parfois plus d''abonnés qu''un grand quotidien, et expliquent la relativité, l''évolution ou la chimie de l''atmosphère à des publics que l''école avait perdus en route. La vulgarisation scientifique indépendante est devenue, en une décennie, le premier contact de millions de personnes avec la science. Une partie du monde académique persiste pourtant à la regarder de haut : trop de simplifications, pas de comité de lecture, du spectacle plutôt que du savoir.

Le reproche n''est pas toujours infondé — il arrive qu''une métaphore brillante écrase une nuance essentielle, et les meilleurs vulgarisateurs sont les premiers à publier des correctifs. Mais il est savoureux de l''entendre de la part d''institutions qui ont si longtemps déserté le terrain. Qui parlait de science au grand public quand les amphithéâtres restaient fermés ? Les charlatans, eux, n''ont jamais attendu de comité de lecture.

Le mépris est d''autant moins justifié que la frontière s''estompe : des chercheurs en activité animent désormais leurs propres chaînes, des vulgarisateurs co-signent des articles, des universités recrutent des médiateurs formés sur le terrain numérique. Plutôt que d''opposer la rigueur à l''audience, il serait temps d''admettre que l''une sans l''autre ne sert à rien : un savoir exact que personne n''écoute ne protège personne.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c00f-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00f-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale défendue par l''auteur ?',
   'L''auteur écarte d''emblée la conclusion facile (« Commode, mais faux ») puis montre que la crise « révèle moins la faillite d''un domaine que la mécanique perverse de la publication » et que « la réponse est venue de la discipline elle-même ». **L''idée principale : la crise dévoile les défauts du système de publication et a déclenché une réforme exemplaire.** La réponse A reprend exactement la conclusion que l''auteur qualifie de fausse. La réponse C est une sur-généralisation absente du texte : il parle de résultats fragiles favorisés par le système, jamais de fraude délibérée. La réponse D inverse les rôles : c''est la psychologie qui est devenue « le laboratoire des bonnes pratiques », que biologie et médecine « commencent à peine à adopter ». Mécanisme : distinguer la **thèse défendue** de l''opinion explicitement réfutée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c00f-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00f-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Pourquoi, selon l''auteur, le poulpe présente-t-il un intérêt scientifique majeur ?',
   'Le texte conclut : « C''est précisément ce qui fait sa valeur scientifique : il prouve que l''évolution a inventé l''intelligence au moins deux fois ». **L''intérêt du poulpe tient à l''apparition indépendante de sa cognition, sur une lignée séparée de la nôtre depuis cinq cents millions d''années.** La réponse A est une sur-généralisation : « l''un des animaux les plus déconcertants » ne signifie pas le plus intelligent jamais étudié. La réponse B inverse le propos : ce sont le chimpanzé et le corbeau qui partagent cet ancêtre avec nous, pas le poulpe. La réponse C promeut un détail vrai mais secondaire (il meurt avant trois ans) en raison principale, alors que le texte n''en tire aucun avantage expérimental. Mécanisme : **inférence de la raison centrale** contre un détail vrai mais secondaire.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c00f-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00f-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur à l''égard des représentations habituelles des dinosaures ?',
   'L''auteur oppose « La science a fait sa part » à « Les musées, les manuels et le cinéma, beaucoup moins » et exige qu''on cesse de présenter comme scientifiques « des images qui ont un demi-siècle de retard ». **Sa position : un reproche adressé aux représentations populaires, en retard sur des découvertes bien établies.** La réponse B contredit le texte : depuis 2010, les mélanosomes permettent de restituer partiellement les couleurs. La réponse C inverse la responsabilité : la recherche a fait sa part, ce sont les relais grand public qui n''ont pas suivi. La réponse D est une sur-généralisation : l''auteur concède « Rien n''oblige un film à être exact », il ne réclame aucune contrainte légale. Mécanisme : identifier le **ton critique de l''auteur** et la cible exacte de son reproche.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c00f-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00f-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Quelle est l''intention principale de l''auteur de ce texte ?',
   'Le texte rejette les deux excès : la « fièvre » des annonces (entretenue parce que « les financements suivent les promesses ») et l''idée d''une impasse (« Ce serait l''excès inverse »). **L''intention : ramener le débat à une position mesurée — des progrès authentiques mais lents, loin de la révolution annoncée.** La réponse A reprend la conclusion que l''auteur écarte explicitement. La réponse B inverse le propos : la révolution pour la décennie en cours est le discours promotionnel critiqué, pas la thèse du texte. La réponse D sur-étend un détail vrai : la fragilité des qubits est un obstacle réel, mais les progrès « authentiques et réguliers » sur la correction d''erreurs interdisent d''y voir un blocage définitif. Mécanisme : **inférence d''intention** dans une structure à double réfutation (ni hype, ni mirage).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c00f-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00f-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'Le texte établit que « le sommeil n''est pas une pause dans l''apprentissage, mais l''une de ses étapes décisives », via le transfert hippocampe → cortex, et le qualifie de « multiplicateur gratuit ». **L''idée principale : le sommeil participe activement à la consolidation des apprentissages.** La réponse A est une sur-généralisation explicitement réfutée : « un cerveau reposé ne consolide que ce qu''on lui a confié », dormir ne dispense pas d''apprendre. La réponse C déforme le détail-piège : la sieste de quatre-vingt-dix minutes produit « une partie de l''effet », pas l''équivalent d''une nuit. La réponse D inverse les résultats de l''étude : ce sont les dormeurs qui retiennent quarante pour cent d''éléments de plus que les noctambules. Mécanisme : dégager l''**idée centrale** en résistant aux distracteurs en inversion et en déformation de détail.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c00f-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00f-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur la prévision des éruptions volcaniques ?',
   'Le texte oppose deux moments : « un volcan instrumenté annonce presque toujours son réveil » mais « le problème commence après », car le calendrier reste imprévisible et la décision d''évacuer est un dilemme pour les autorités. **L''idée à inférer : la détection du réveil est maîtrisée, c''est la décision d''évacuation qui constitue le vrai défi.** La réponse A contredit le texte : les signaux précurseurs sont lisibles « parfois des semaines à l''avance ». La réponse B contredit un passage explicite : « la décision d''évacuer ne leur appartient pas ». La réponse C inverse la conclusion : le progrès viendra « moins de nouveaux capteurs » que de populations préparées, et la science fournit « des probabilités, jamais des certitudes ». Mécanisme : **inférence globale** reliant le paradoxe initial à la conclusion, contre des distracteurs en inversion.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c00f-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00f-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Comment l''auteur se positionne-t-il à l''égard de la vulgarisation scientifique indépendante ?',
   'L''auteur concède que « le reproche n''est pas toujours infondé » avant de retourner la critique contre les institutions (« Mais il est savoureux de l''entendre… ») et de plaider pour réconcilier rigueur et audience. **Sa position : une défense de la vulgarisation indépendante, assortie de la reconnaissance de ses limites réelles.** La réponse B inverse l''attribution : « du spectacle plutôt que du savoir » est le reproche du monde académique, que l''auteur conteste. La réponse C contredit le texte, qui relativise le comité de lecture (« Les charlatans, eux, n''ont jamais attendu de comité de lecture »). La réponse D inverse un fait : les institutions ont « si longtemps déserté le terrain », elles ne sont pas félicitées. Mécanisme : la **concession rhétorique** (pas toujours infondé… mais) signale un soutien nuancé, non un rejet.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — crise de la réplication (bonne réponse : position 2)
  ('11111111-c00f-2100-0000-000000000001', '11111111-c00f-1000-0000-000000000001',
   'La psychologie n''est pas une vraie science puisque ses résultats ne se reproduisent pas',
   'false', '1'),

  ('11111111-c00f-2200-0000-000000000001', '11111111-c00f-1000-0000-000000000001',
   'La crise de la réplication a révélé les travers du système de publication et poussé la discipline à se réformer',
   'true', '2'),

  ('11111111-c00f-2300-0000-000000000001', '11111111-c00f-1000-0000-000000000001',
   'Les chercheurs en psychologie falsifient délibérément leurs données pour être publiés',
   'false', '3'),

  ('11111111-c00f-2400-0000-000000000001', '11111111-c00f-1000-0000-000000000001',
   'La biologie et la médecine ont montré à la psychologie l''exemple des bonnes pratiques',
   'false', '4'),

  -- item 02 — cognition du poulpe (bonne réponse : position 4)
  ('11111111-c00f-2100-0000-000000000002', '11111111-c00f-1000-0000-000000000002',
   'Parce qu''il est l''animal le plus intelligent que la science ait jamais étudié',
   'false', '1'),

  ('11111111-c00f-2200-0000-000000000002', '11111111-c00f-1000-0000-000000000002',
   'Parce qu''il partage avec les primates un ancêtre commun au système nerveux centralisé',
   'false', '2'),

  ('11111111-c00f-2300-0000-000000000002', '11111111-c00f-1000-0000-000000000002',
   'Parce que sa courte durée de vie facilite les expériences menées en laboratoire',
   'false', '3'),

  ('11111111-c00f-2400-0000-000000000002', '11111111-c00f-1000-0000-000000000002',
   'Parce que son intelligence est apparue indépendamment de la nôtre, par une autre voie évolutive',
   'true', '4'),

  -- item 03 — couleur des dinosaures (bonne réponse : position 1)
  ('11111111-c00f-2100-0000-000000000003', '11111111-c00f-1000-0000-000000000003',
   'Il déplore qu''elles ignorent des découvertes scientifiques pourtant bien établies',
   'true', '1'),

  ('11111111-c00f-2200-0000-000000000003', '11111111-c00f-1000-0000-000000000003',
   'Il rappelle que l''apparence réelle des dinosaures reste totalement inconnue',
   'false', '2'),

  ('11111111-c00f-2300-0000-000000000003', '11111111-c00f-1000-0000-000000000003',
   'Il reproche aux chercheurs de ne pas diffuser leurs résultats auprès du grand public',
   'false', '3'),

  ('11111111-c00f-2400-0000-000000000003', '11111111-c00f-1000-0000-000000000003',
   'Il demande que les films soient légalement contraints à l''exactitude scientifique',
   'false', '4'),

  -- item 04 — ordinateur quantique (bonne réponse : position 3)
  ('11111111-c00f-2100-0000-000000000004', '11111111-c00f-1000-0000-000000000004',
   'Démontrer que l''ordinateur quantique est une impasse technologique sans avenir',
   'false', '1'),

  ('11111111-c00f-2200-0000-000000000004', '11111111-c00f-1000-0000-000000000004',
   'Annoncer que la révolution quantique transformera l''économie avant la fin de la décennie',
   'false', '2'),

  ('11111111-c00f-2300-0000-000000000004', '11111111-c00f-1000-0000-000000000004',
   'Inviter à distinguer les progrès réels du quantique des promesses exagérées qui l''entourent',
   'true', '3'),

  ('11111111-c00f-2400-0000-000000000004', '11111111-c00f-1000-0000-000000000004',
   'Prouver que la fragilité des qubits constitue un obstacle définitivement insurmontable',
   'false', '4'),

  -- item 05 — sommeil et mémoire (bonne réponse : position 2)
  ('11111111-c00f-2100-0000-000000000005', '11111111-c00f-1000-0000-000000000005',
   'Dormir suffit à mémoriser un cours sans qu''il soit nécessaire de le réviser',
   'false', '1'),

  ('11111111-c00f-2200-0000-000000000005', '11111111-c00f-1000-0000-000000000005',
   'Le sommeil joue un rôle actif et déterminant dans la consolidation des apprentissages',
   'true', '2'),

  ('11111111-c00f-2300-0000-000000000005', '11111111-c00f-1000-0000-000000000005',
   'Une sieste de quatre-vingt-dix minutes remplace entièrement une nuit de sommeil',
   'false', '3'),

  ('11111111-c00f-2400-0000-000000000005', '11111111-c00f-1000-0000-000000000005',
   'Les étudiants qui révisent toute la nuit retiennent davantage que ceux qui dorment',
   'false', '4'),

  -- item 06 — prévision volcanique (bonne réponse : position 4)
  ('11111111-c00f-2100-0000-000000000006', '11111111-c00f-1000-0000-000000000006',
   'Les volcans entrent généralement en éruption sans donner le moindre signe avant-coureur',
   'false', '1'),

  ('11111111-c00f-2200-0000-000000000006', '11111111-c00f-1000-0000-000000000006',
   'Les volcanologues décident eux-mêmes du moment où il faut évacuer les populations',
   'false', '2'),

  ('11111111-c00f-2300-0000-000000000006', '11111111-c00f-1000-0000-000000000006',
   'De nouveaux capteurs permettront bientôt de prédire la date exacte des éruptions',
   'false', '3'),

  ('11111111-c00f-2400-0000-000000000006', '11111111-c00f-1000-0000-000000000006',
   'Détecter le réveil d''un volcan est maîtrisé ; c''est la décision d''évacuer qui reste le vrai dilemme',
   'true', '4'),

  -- item 07 — vulgarisation indépendante (bonne réponse : position 1)
  ('11111111-c00f-2100-0000-000000000007', '11111111-c00f-1000-0000-000000000007',
   'Il la défend tout en admettant que les critiques sur ses simplifications sont parfois fondées',
   'true', '1'),

  ('11111111-c00f-2200-0000-000000000007', '11111111-c00f-1000-0000-000000000007',
   'Il estime qu''elle relève du spectacle et non du savoir scientifique',
   'false', '2'),

  ('11111111-c00f-2300-0000-000000000007', '11111111-c00f-1000-0000-000000000007',
   'Il considère que seuls les comités de lecture garantissent une information fiable au public',
   'false', '3'),

  ('11111111-c00f-2400-0000-000000000007', '11111111-c00f-1000-0000-000000000007',
   'Il félicite les institutions académiques pour leur présence ancienne auprès du grand public',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c00f-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « sciences (vulgarisation) », 7 angles tous différents :
--     crise de la réplication (psychologie) / cognition du poulpe (éthologie) /
--     couleur des dinosaures (paléontologie) / ordinateur quantique (physique) /
--     sommeil et mémoire (neurosciences) / prévision des éruptions
--     (volcanologie) / vulgarisation scientifique indépendante (médiation).
--     Aucun thème interdit (pas de santé publique, environnement, numérique &
--     vie privée, culture & médias, etc. — angles strictement scientifiques).
-- [x] Textes B2 longs : 180 / 207 / 200 / 207 / 200 / 207 / 204 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (ex. « Commode, mais faux », « une partie de l''effet », « Ce serait
--     l''excès inverse », « la décision d''évacuer ne leur appartient pas »).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2 (items 1, 5),
--     ce_inference_intention ×3 (items 2, 4, 6), ce_ton_auteur ×2 (items 3, 7).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme linguistique
--     nommé (concession rhétorique, inversion cause/effet ou d''attribution,
--     inférence d''intention, détail vrai mais secondaire, sur-généralisation).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (situations, chiffres et
--     références inventés ou anonymisés, aucune personnalité réelle).
-- ============================================================================
