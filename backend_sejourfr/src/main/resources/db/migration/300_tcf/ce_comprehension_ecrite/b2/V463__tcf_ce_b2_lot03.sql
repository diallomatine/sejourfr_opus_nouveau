-- ============================================================================
-- V463 — TCF CE B2 — lot 03 (thème : éducation)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~180-200 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : évaluation et notes / recrutement des enseignants / devoirs à la
-- maison / redoublement / voie professionnelle et apprentissage / rythmes
-- scolaires (courrier formel) / sélection à l'université.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c003-4000-0000-000000000001', 'TEXTE',
   'Faut-il en finir avec les notes à l''école ? Le débat, récurrent, vient d''être relancé par l''expérience du collège des Tilleuls, à Niort, qui a remplacé depuis trois ans les notes chiffrées par des évaluations de compétences en quatre couleurs. Résultat mis en avant par l''équipe : moins de stress déclaré, davantage de participation orale, des familles globalement satisfaites.

L''argument des partisans de la note mérite pourtant d''être entendu : la note, disent-ils, prépare aux exigences du monde réel et permet aux élèves de se situer. Mais il repose sur une confusion. Ce qui fait progresser un élève, toutes les études le montrent, n''est ni le chiffre ni la couleur : c''est la qualité du commentaire qui l''accompagne. Une copie rendue avec un 8 sans explication n''apprend rien ; un 8 assorti d''indications précises sur ce qu''il faut reprendre devient un outil.

Supprimer les notes ne garantit donc rien, et les conserver ne condamne personne. Le vrai chantier, le seul, consiste à donner aux enseignants le temps et la formation nécessaires pour faire de chaque évaluation un retour utile. Tant que ce chantier restera ouvert, la querelle des couleurs et des chiffres ne sera qu''un écran de fumée.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c003-4000-0000-000000000002', 'TEXTE',
   'Pour la cinquième année consécutive, les concours de l''enseignement n''ont pas fait le plein : près de mille deux cents postes sont restés vacants au printemps dernier, principalement en mathématiques, en allemand et en lettres classiques. Dans plusieurs académies, on recrute désormais des contractuels en quelques jours, parfois après un simple entretien de trente minutes.

Le réflexe consiste à incriminer les salaires, et il n''est pas infondé : un professeur débutant gagne aujourd''hui à peine plus que le salaire minimum, à niveau bac+5. Les revalorisations engagées depuis deux ans ont d''ailleurs amélioré les débuts de carrière. Mais elles n''ont eu aucun effet mesurable sur le nombre de candidats, et c''est bien là que le bât blesse.

Car la désaffection se nourrit d''autre chose : classes surchargées, sentiment de déclassement, image dégradée du métier dans l''opinion, perspectives de carrière plates pendant quarante ans. Les enquêtes menées auprès des étudiants qui renoncent au professorat le confirment : le salaire arrive en troisième position de leurs motifs, loin derrière les conditions d''exercice. Tant que la question sera réduite à une ligne sur la fiche de paie, les amphithéâtres de préparation aux concours continueront de se vider.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c003-4000-0000-000000000003', 'TEXTE',
   'Chaque soir, dans des millions de foyers, la même scène se rejoue : un enfant fatigué, un cahier ouvert, un parent qui s''improvise professeur entre deux casseroles. Les devoirs écrits sont pourtant interdits à l''école primaire depuis 1956, interdiction si peu appliquée qu''elle en est devenue une curiosité juridique.

Le problème n''est pas que les devoirs soient inutiles : s''exercer seul, mémoriser, reprendre une notion sont des gestes indispensables à tout apprentissage. Le problème est l''endroit où ils se font. Entre l''élève dont la mère, ingénieure, reprend patiemment la division posée, et celui qui se débrouille seul dans une cuisine bruyante parce que ses parents travaillent le soir ou maîtrisent mal le français, le travail à la maison agit comme une machine à creuser les écarts. Les évaluations le confirment d''année en année.

Faut-il pour autant abolir tout travail personnel, comme le réclament certains ? Ce serait jeter le geste avec son cadre. La solution existe et porte un nom sans poésie : faire les devoirs dans l''établissement, encadrés par des adultes formés, avant de rentrer chez soi. Des collèges l''expérimentent avec des résultats encourageants. Reste à en faire une règle, et non une option dépendant de la bonne volonté locale.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c003-4000-0000-000000000004', 'TEXTE',
   'Longtemps, la France a détenu un record peu enviable : celui du redoublement. Au début des années deux mille, près d''un élève sur deux avait déjà recommencé une classe avant ses quinze ans. La proportion a été divisée par quatre depuis, sous l''effet conjugué des consignes ministérielles et de son coût, estimé à plusieurs milliers d''euros par élève et par an.

Une synthèse publiée le mois dernier par une équipe de l''université de Mons, qui a compilé une soixantaine d''études internationales, permet de juger cette évolution sur pièces. Son constat est sans appel : si l''élève qui redouble progresse souvent durant l''année recommencée — il revoit, après tout, un programme déjà connu —, cet avantage s''évapore en deux ou trois ans. À moyen terme, à profil équivalent, les redoublants décrochent plus souvent, perdent confiance et s''orientent vers des filières moins choisies que les élèves passés dans la classe supérieure avec des difficultés comparables.

Le redoublement rassure les adultes : il donne le sentiment d''agir. Mais l''honnêteté oblige à le dire : ce que montrent les données, c''est qu''une année de plus ne remplace jamais un accompagnement différent.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c003-4000-0000-000000000005', 'TEXTE',
   '« L''apprentissage, c''est une voie d''excellence. » La formule revient dans chaque discours officiel, accompagnée de chiffres flatteurs : huit cent mille contrats signés l''an dernier, des taux d''insertion professionnelle supérieurs, dans certains métiers, à ceux de bien des licences universitaires. Devant les caméras, ministres et chefs d''entreprise rivalisent d''éloges sur les mains qui savent faire.

La réalité des conseils de classe raconte une autre histoire. Dans la plupart des collèges, la voie professionnelle n''est jamais présentée en premier choix : on y « oriente » les élèves dont les bulletins fléchissent, souvent contre leur avis et celui de leurs familles. Le message implicite est limpide, et tous les adolescents le décodent parfaitement : la filière que l''on vante à la tribune est celle qu''on réserve, dans les faits, à ceux dont on n''attend plus rien.

Cette hypocrisie a un coût : démotivation, abandons en première année, sentiment de relégation durable. Les pays qui ont fait de la formation professionnelle une réussite, eux, l''ont rendue accessible aux bons élèves, réversible, connectée à l''enseignement supérieur. Tant que choisir un métier manuel sera vécu comme une sanction scolaire, les discours sur l''excellence resteront ce qu''ils sont : des discours.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c003-4000-0000-000000000006', 'TEXTE',
   'Madame, Monsieur,

À compter de la rentrée prochaine, le collège Simone-Berthier expérimentera, pendant une année scolaire, un aménagement des horaires : les cours débuteront à neuf heures au lieu de huit heures, et s''achèveront à dix-sept heures trente.

Cette décision, validée par le conseil d''administration du 12 mai, s''appuie sur des travaux convergents concernant le sommeil des adolescents : entre douze et seize ans, l''endormissement se décale naturellement, et les premières heures de cours se déroulent, pour beaucoup d''élèves, dans un état de vigilance réduite. Les établissements ayant adopté un dispositif comparable constatent une amélioration de l''attention et une baisse des retards.

Nous savons que ce changement bouleverse l''organisation de nombreuses familles. C''est pourquoi je tiens à préciser que les circuits de ramassage scolaire demeurent inchangés et que les élèves arrivant dès huit heures seront accueillis en étude surveillée, sans frais supplémentaires. Par ailleurs, l''expérimentation fera l''objet d''un bilan complet en juin, présenté aux représentants des parents d''élèves : rien ne sera pérennisé sans ce retour d''expérience.

Une réunion d''information se tiendra le jeudi 18 juin à dix-huit heures, au réfectoire de l''établissement. Votre présence nous sera précieuse.

La principale,
Houria Benamar',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c003-4000-0000-000000000007', 'TEXTE',
   'Chaque printemps, le rituel recommence : des centaines de milliers de lycéens confient leurs vœux d''études à la plateforme nationale d''affectation, puis guettent pendant des semaines des réponses qui tombent au compte-goutte. Et chaque printemps, le même débat ressurgit : faut-il, oui ou non, sélectionner à l''entrée de l''université ?

Posée ainsi, la question est un trompe-l''œil. La sélection existe déjà, massivement : dès qu''une licence reçoit plus de candidatures que de places — c''est le cas de toutes les filières recherchées —, des commissions classent les dossiers, examinent les bulletins, pondèrent les lycées d''origine. Reconnaissons à la plateforme un mérite : elle a mis fin au tirage au sort, procédé absurde qui décidait naguère de l''avenir d''un bachelier à pile ou face.

Mais ce progrès s''est payé d''une opacité devenue indéfendable. Sur quels critères un dossier est-il classé ? Quel poids pour les notes, lequel pour l''établissement fréquenté ? Les familles l''ignorent, et cette ignorance nourrit tous les soupçons, fondés ou non. On peut être favorable à une sélection assumée et juger inacceptable qu''elle s''exerce dans une boîte noire. Classer des candidats est une chose ; le faire sans rendre de comptes en est une autre.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c003-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c003-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale défendue par l''auteur ?',
   'L''auteur tranche : « Ce qui fait progresser un élève […] c''est la qualité du commentaire qui l''accompagne », puis désigne « le vrai chantier, le seul ». **L''idée principale : la forme de l''évaluation compte moins que la qualité du retour fait à l''élève.** La réponse A sur-généralise un détail : l''expérience de Niort montre moins de stress et plus de participation, pas une amélioration des résultats. La réponse C reprend l''argument **rapporté** des partisans de la note, que l''auteur qualifie de « confusion ». La réponse D contredit la conclusion : l''auteur réclame justement de donner ce temps aux enseignants. Mécanisme : distinguer la **thèse défendue** des arguments rapportés et du détail secondaire.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c003-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c003-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur la crise du recrutement des enseignants ?',
   'Le texte concède que les revalorisations « ont amélioré les débuts de carrière » mais « n''ont eu aucun effet mesurable sur le nombre de candidats » : **la cause profonde de la désaffection est ailleurs, dans les conditions d''exercice**, classées « loin devant » le salaire par les étudiants eux-mêmes. La réponse A contredit un fait explicite : les salaires de début de carrière ont été améliorés, pas réduits. La réponse B restreint abusivement un détail : la pénurie touche « principalement » les mathématiques, mais aussi l''allemand et les lettres classiques. La réponse C inverse cause et effet : les hausses n''ont justement produit aucun effet sur les candidatures. Mécanisme : **inférence de la cause principale** derrière une concession (il n''est pas infondé… mais).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c003-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c003-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur sur les devoirs à la maison ?',
   'L''auteur affirme que les devoirs sont « des gestes indispensables » mais que « le problème est l''endroit où ils se font », puis propose de les faire « dans l''établissement, encadrés par des adultes formés ». **Sa position : conserver le travail personnel, mais le déplacer à l''école pour neutraliser les inégalités.** La réponse B sur-étend le propos : l''abolition est la position « de certains », que l''auteur réfute (« jeter le geste avec son cadre »). La réponse C contredit le cœur du texte : les devoirs à la maison sont « une machine à creuser les écarts ». La réponse D invente un reproche : l''auteur décrit des parents empêchés (travail du soir, langue), jamais démissionnaires. Mécanisme : repérer le **ton nuancé** — ni rejet ni statu quo, mais déplacement du cadre.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c003-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c003-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'La synthèse citée conclut que l''avantage du redoublant « s''évapore en deux ou trois ans » et qu''à moyen terme les redoublants « décrochent plus souvent » : **l''idée principale est que le redoublement n''offre qu''un bénéfice passager et se révèle contre-productif à moyen terme**. La réponse A promeut un détail secondaire en idée principale : le coût n''est qu''un des facteurs de la baisse, pas le cœur de la démonstration. La réponse B sur-généralise le détail-piège : le progrès observé pendant l''année recommencée est précisément celui qui disparaît ensuite. La réponse D contredit un fait explicite : la proportion de redoublants « a été divisée par quatre ». Mécanisme : résister au **détail vrai mais secondaire** et à la sur-généralisation du piège.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c003-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c003-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Quelle est l''intention principale de l''auteur de ce texte ?',
   'Le texte oppose « la formule [qui] revient dans chaque discours officiel » à « la réalité des conseils de classe », et nomme cet écart « hypocrisie » : **l''intention est de dénoncer la contradiction entre l''éloge public de l''apprentissage et une orientation qui en fait une voie de relégation**. La réponse A inverse l''intention : l''auteur ne déconseille pas cette voie, il veut qu''elle devienne un vrai choix, comme dans les pays qui l''ont réussie. La réponse C sur-généralise un détail : les taux d''insertion sont supérieurs « dans certains métiers » seulement, jamais garantis pour tous. La réponse D invente une proposition absente : aucune réduction de la voie générale n''est réclamée. Mécanisme : **inférence d''intention** à partir d''une opposition discours/pratique.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c003-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c003-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Que cherche à faire la principale à travers ce courrier ?',
   'La lettre annonce la mesure, puis enchaîne : « Nous savons que ce changement bouleverse l''organisation de nombreuses familles. C''est pourquoi je tiens à préciser… » (ramassage inchangé, étude gratuite, bilan en juin). **L''intention : annoncer l''expérimentation tout en désamorçant par avance les objections pratiques des parents.** La réponse A déforme la nature de la mesure : il s''agit d''une expérimentation d''un an, « rien ne sera pérennisé » sans bilan, pas d''une réforme définitive. La réponse B invente une consultation : la décision est déjà « validée par le conseil d''administration », la réunion est d''information. La réponse C invente un échec antérieur dont le texte ne dit rien. Mécanisme : **inférence d''intention** d''un courrier formel — informer ET rassurer, au-delà de la simple annonce.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c003-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c003-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Comment l''auteur se positionne-t-il dans le débat sur la sélection à l''université ?',
   'L''auteur écrit : « On peut être favorable à une sélection assumée et juger inacceptable qu''elle s''exerce dans une boîte noire. » **Sa position : il accepte le principe de la sélection, mais exige la transparence de ses critères.** La réponse A contredit le texte : le tirage au sort est qualifié de « procédé absurde » auquel la plateforme a heureusement mis fin. La réponse B inverse son constat : « la sélection existe déjà, massivement » — c''est le faux débat « pour ou contre » qu''il qualifie de trompe-l''œil. La réponse D contredit la critique centrale : le progrès « s''est payé d''une opacité devenue indéfendable ». Mécanisme : repérer le **ton de l''auteur** dans un mouvement concessif (reconnaissons un mérite… mais), ni rejet ni satisfecit.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — évaluation et notes (bonne réponse : position 2)
  ('11111111-c003-2100-0000-000000000001', '11111111-c003-1000-0000-000000000001',
   'L''expérience du collège des Tilleuls prouve que supprimer les notes améliore les résultats scolaires',
   'false', '1'),

  ('11111111-c003-2200-0000-000000000001', '11111111-c003-1000-0000-000000000001',
   'La forme de l''évaluation importe moins que la qualité du retour donné à l''élève',
   'true', '2'),

  ('11111111-c003-2300-0000-000000000001', '11111111-c003-1000-0000-000000000001',
   'Les notes chiffrées doivent être conservées car elles préparent aux exigences du monde réel',
   'false', '3'),

  ('11111111-c003-2400-0000-000000000001', '11111111-c003-1000-0000-000000000001',
   'Les enseignants disposent déjà du temps nécessaire pour commenter utilement chaque copie',
   'false', '4'),

  -- item 02 — recrutement des enseignants (bonne réponse : position 4)
  ('11111111-c003-2100-0000-000000000002', '11111111-c003-1000-0000-000000000002',
   'Le salaire des professeurs débutants a continué de baisser malgré les annonces ministérielles',
   'false', '1'),

  ('11111111-c003-2200-0000-000000000002', '11111111-c003-1000-0000-000000000002',
   'La pénurie de candidats aux concours ne concerne que les mathématiques',
   'false', '2'),

  ('11111111-c003-2300-0000-000000000002', '11111111-c003-1000-0000-000000000002',
   'Les revalorisations salariales ont relancé le nombre de candidats aux concours',
   'false', '3'),

  ('11111111-c003-2400-0000-000000000002', '11111111-c003-1000-0000-000000000002',
   'Les hausses de salaire n''ont pas suffi car les conditions d''exercice pèsent davantage dans la désaffection',
   'true', '4'),

  -- item 03 — devoirs à la maison (bonne réponse : position 1)
  ('11111111-c003-2100-0000-000000000003', '11111111-c003-1000-0000-000000000003',
   'Il ne conteste pas le travail personnel mais demande qu''il soit fait dans l''établissement, encadré',
   'true', '1'),

  ('11111111-c003-2200-0000-000000000003', '11111111-c003-1000-0000-000000000003',
   'Il réclame l''abolition de tout travail personnel après la classe',
   'false', '2'),

  ('11111111-c003-2300-0000-000000000003', '11111111-c003-1000-0000-000000000003',
   'Il estime que les devoirs à la maison profitent de la même manière à tous les élèves',
   'false', '3'),

  ('11111111-c003-2400-0000-000000000003', '11111111-c003-1000-0000-000000000003',
   'Il reproche aux parents de ne pas s''investir suffisamment dans le suivi des devoirs',
   'false', '4'),

  -- item 04 — redoublement (bonne réponse : position 3)
  ('11111111-c003-2100-0000-000000000004', '11111111-c003-1000-0000-000000000004',
   'Le coût financier est la seule raison valable de renoncer au redoublement',
   'false', '1'),

  ('11111111-c003-2200-0000-000000000004', '11111111-c003-1000-0000-000000000004',
   'L''élève qui redouble prend une avance durable sur les élèves en difficulté passés en classe supérieure',
   'false', '2'),

  ('11111111-c003-2300-0000-000000000004', '11111111-c003-1000-0000-000000000004',
   'Le redoublement n''apporte qu''un bénéfice passager et se révèle néfaste à moyen terme',
   'true', '3'),

  ('11111111-c003-2400-0000-000000000004', '11111111-c003-1000-0000-000000000004',
   'La France fait aujourd''hui redoubler ses élèves plus que jamais',
   'false', '4'),

  -- item 05 — voie professionnelle (bonne réponse : position 2)
  ('11111111-c003-2100-0000-000000000005', '11111111-c003-1000-0000-000000000005',
   'Déconseiller aux familles de choisir la voie professionnelle, trop peu valorisée',
   'false', '1'),

  ('11111111-c003-2200-0000-000000000005', '11111111-c003-1000-0000-000000000005',
   'Dénoncer l''écart entre l''éloge officiel de l''apprentissage et une orientation qui en fait une relégation',
   'true', '2'),

  ('11111111-c003-2300-0000-000000000005', '11111111-c003-1000-0000-000000000005',
   'Montrer que l''apprentissage garantit un emploi à tous ceux qui le choisissent',
   'false', '3'),

  ('11111111-c003-2400-0000-000000000005', '11111111-c003-1000-0000-000000000005',
   'Réclamer la réduction du nombre de places dans la voie générale au profit des lycées professionnels',
   'false', '4'),

  -- item 06 — rythmes scolaires, courrier formel (bonne réponse : position 4)
  ('11111111-c003-2100-0000-000000000006', '11111111-c003-1000-0000-000000000006',
   'Informer les familles d''une réforme définitive des horaires du collège',
   'false', '1'),

  ('11111111-c003-2200-0000-000000000006', '11111111-c003-1000-0000-000000000006',
   'Demander aux parents de voter pour ou contre le décalage des cours',
   'false', '2'),

  ('11111111-c003-2300-0000-000000000006', '11111111-c003-1000-0000-000000000006',
   'Reconnaître l''échec du dispositif mis en place l''année précédente',
   'false', '3'),

  ('11111111-c003-2400-0000-000000000006', '11111111-c003-1000-0000-000000000006',
   'Annoncer une expérimentation tout en répondant par avance aux inquiétudes pratiques des familles',
   'true', '4'),

  -- item 07 — sélection à l'université (bonne réponse : position 3)
  ('11111111-c003-2100-0000-000000000007', '11111111-c003-1000-0000-000000000007',
   'Il réclame le rétablissement du tirage au sort, plus équitable que le classement des dossiers',
   'false', '1'),

  ('11111111-c003-2200-0000-000000000007', '11111111-c003-1000-0000-000000000007',
   'Il nie l''existence de toute sélection à l''entrée des licences universitaires',
   'false', '2'),

  ('11111111-c003-2300-0000-000000000007', '11111111-c003-1000-0000-000000000007',
   'Il accepte le principe d''une sélection mais exige que ses critères soient rendus publics',
   'true', '3'),

  ('11111111-c003-2400-0000-000000000007', '11111111-c003-1000-0000-000000000007',
   'Il juge la plateforme parfaitement transparente depuis la fin du tirage au sort',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c003-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « éducation », 7 angles tous différents :
--     évaluation et notes / recrutement des enseignants / devoirs à la maison /
--     redoublement / voie professionnelle et apprentissage / rythmes scolaires
--     (courrier formel élaboré) / sélection à l'université. Aucun thème interdit
--     (pas de numérique, pas d'emploi/chômage, pas d'égalité & société, etc.).
-- [x] Textes B2 longs : 193 / 190 / 197 / 182 / 188 / 189 / 187 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (ex. « moins de stress » ≠ résultats, revalorisations sans effet,
--     progrès du redoublant qui s'évapore, taux d'insertion « dans certains
--     métiers », expérimentation d'un an, fin du tirage au sort).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:1, pos2:2, pos3:2, pos4:2
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2 (items 1, 4),
--     ce_inference_intention ×3 (items 2, 5, 6), ce_ton_auteur ×2 (items 3, 7).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme linguistique
--     nommé (concession, inversion cause/effet, inférence d'intention,
--     détail secondaire, sur-généralisation, thèse vs argument rapporté).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (prénoms, villes, chiffres inventés).
-- ============================================================================
