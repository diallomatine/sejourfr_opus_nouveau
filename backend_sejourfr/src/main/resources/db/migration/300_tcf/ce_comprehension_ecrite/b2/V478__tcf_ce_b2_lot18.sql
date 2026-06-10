-- ============================================================================
-- V478 — TCF CE B2 — lot 18 (thème : rapports entre générations)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~175-205 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : mythe du conflit des générations / déclinisme (« c'était mieux
-- avant ») / crèches en résidence pour aînés / langage des jeunes /
-- ateliers d'échange de savoirs réciproques / passeurs de mémoire /
-- stéréotypes d'âge réciproques.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c012-4000-0000-000000000001', 'TEXTE',
   'À en croire certains débats publics, jeunes et aînés se livreraient une guerre ouverte : les premiers accuseraient les seconds d''avoir confisqué la prospérité, les seconds reprocheraient aux premiers leur prétendue paresse. Une vaste enquête menée à Nantes auprès de onze mille personnes âgées de dix-huit à quatre-vingt-cinq ans vient bousculer ce récit commode.

Sur l''essentiel — l''attachement à la solidarité, l''inquiétude pour l''avenir, la défiance envers les discours tout faits —, les réponses des moins de trente ans et des plus de soixante-cinq ans sont presque superposables. Les chercheurs relèvent bien un désaccord marqué sur un point précis, le rythme des changements de société, que les aînés souhaitent plus prudent. Mais cet écart, réel, reste très loin de la fracture annoncée.

D''où vient alors l''impression d''un fossé infranchissable ? Des porte-voix, répondent les auteurs : les positions les plus tranchées de chaque classe d''âge occupent l''espace public, tandis que la masse des opinions modérées demeure inaudible. Le « conflit des générations » serait ainsi moins une réalité sociologique qu''un spectacle entretenu, dont les deux publics, ironiquement, se disent également lassés.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c012-4000-0000-000000000002', 'TEXTE',
   '« De mon temps, les jeunes étaient polis, travailleurs et débrouillards. » La phrase traverse les siècles : on en trouve des variantes chez les scribes de l''Antiquité comme dans les courriers des lecteurs d''aujourd''hui. Chaque génération, arrivée à maturité, semble convaincue que celle qui la suit marque un recul.

Des psychologues de l''université de Rennes ont voulu comprendre la mécanique de cette certitude. Leur expérience, menée auprès de trois mille adultes, met au jour un double biais. D''abord, un effet de mémoire : nous comparons les jeunes d''aujourd''hui non pas aux jeunes que nous étions réellement, mais au souvenir embelli que nous en gardons. Ensuite, un effet de projection : plus une personne se juge compétente dans un domaine — la politesse, l''orthographe, l''effort —, plus elle perçoit un déclin des nouvelles générations dans ce domaine précis.

Les chercheurs notent au passage que les jeunes adultes interrogés n''échappent pas entièrement au phénomène : certains portent déjà un regard sévère sur les adolescents. Le déclinisme n''est donc pas l''apanage d''un âge ; c''est une illusion d''optique que chaque génération reproduit à son tour, et qui en dit bien plus sur celui qui juge que sur ceux qui sont jugés.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c012-4000-0000-000000000003', 'TEXTE',
   'À Périgueux, la résidence des Tilleuls accueille depuis deux ans, au rez-de-chaussée, une micro-crèche de douze berceaux. Chaque matin, des résidents descendent lire des albums aux tout-petits ; chaque vendredi, les enfants montent chanter dans la salle commune. Les premiers résultats émerveillent les visiteurs : appétit retrouvé chez certains pensionnaires, recul des signes de tristesse, enfants plus à l''aise avec la lenteur et la différence.

Faut-il pour autant voir dans ces lieux la réponse au cloisonnement des âges ? Un peu de prudence s''impose. Les évaluations disponibles portent sur de petits effectifs et sur des volontaires, c''est-à-dire sur les résidents déjà les plus sociables. Surtout, l''essentiel du bénéfice repose sur une présence humaine dédiée : sans la coordinatrice qui prépare chaque rencontre, ajuste les groupes et rassure les familles, les deux publics cohabitent sans se croiser, comme l''ont montré plusieurs expériences arrêtées faute de personnel.

Ces réserves ne condamnent pas le modèle ; elles rappellent qu''il ne suffit pas de juxtaposer une crèche et une maison de retraite pour créer du lien. Le contact entre générations ne se décrète pas : il s''organise, il se finance, il s''apprend. C''est précisément pour cela qu''il mérite mieux qu''un effet de mode.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c012-4000-0000-000000000004', 'TEXTE',
   'Tous les dix ans environ, la même alarme retentit : les jeunes « massacreraient » la langue française. Hier le verlan, aujourd''hui les abréviations et les mots venus d''ailleurs, chaque nouveauté lexicale déclenche son lot de tribunes inquiètes annonçant la mort prochaine de la syntaxe.

La linguiste Aurélie Mercadier, qui a constitué un corpus de conversations adolescentes enregistrées à Saint-Étienne pendant trois ans, invite à regarder les faits. Premier constat : les adolescents qu''elle a suivis maîtrisent plusieurs registres et passent de l''un à l''autre selon l''interlocuteur — un parler entre pairs, un français standard avec les adultes, un écrit scolaire correct. Loin d''appauvrir leur langue, cette gymnastique en accroît la souplesse. Second constat : la plupart des mots qui scandalisent disparaissent d''eux-mêmes en quelques années ; seuls quelques survivants finissent au dictionnaire, comme tant de termes d''argot d''autrefois devenus parfaitement respectables.

Reste une question que la chercheuse retourne avec malice : pourquoi chaque génération oublie-t-elle qu''elle a, elle aussi, exaspéré ses aînés avec ses propres mots ? Peut-être parce que déplorer la langue des jeunes est, depuis toujours, la manière la plus commode d''affirmer qu''on ne l''est plus.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c012-4000-0000-000000000005', 'TEXTE',
   'Au centre social du quartier Bellevue, à Brest, le jeudi après-midi appartient aux « ateliers réciproques ». Le principe en est simple : chacun vient à la fois enseigner et apprendre. Suzanne, quatre-vingt-un ans, initie trois lycéens à la couture qu''elle pratiquait autrefois ; en échange, Ilyès, dix-sept ans, lui apprend à envoyer des photos à sa sœur installée au Québec. D''autres binômes s''échangent le jardinage contre les démarches en ligne, la mécanique de vélo contre les jeux de stratégie.

Lancés un peu partout en France, ces dispositifs sont souvent évalués à l''aune des compétences transmises. C''est passer à côté de l''essentiel, estime l''équipe qui a suivi quarante ateliers pendant deux ans. Les progrès techniques restent modestes, et la moitié des participants oublient rapidement ce qu''ils ont appris. Ce qui demeure, en revanche, c''est autre chose : des liens qui se prolongent hors des ateliers, des invitations à déjeuner, une jeune fille qui accompagne désormais sa partenaire chez l''ophtalmologue. Et, des deux côtés, un changement de regard mesurable sur l''autre classe d''âge.

La leçon vaut d''être entendue : la réciprocité affichée n''est peut-être qu''un prétexte. Mais c''est un prétexte précieux, car il place chacun en position de donner — condition première pour qu''une rencontre entre générations soit autre chose qu''une bonne action.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c012-4000-0000-000000000006', 'TEXTE',
   'Depuis quelques années, des collectifs de « passeurs de mémoire » se multiplient : des bénévoles, souvent étudiants, recueillent et mettent en forme les récits de vie de personnes très âgées, avant que ces témoignages ne disparaissent avec elles. À Mulhouse, le collectif Mémoire vive a déjà rassemblé deux cents heures d''enregistrement auprès d''anciens ouvriers du textile, de réfugiées arrivées dans les années cinquante, de paysannes devenues citadines.

L''entreprise est précieuse, et il faut espérer qu''elle s''étende. On se permettra pourtant une mise en garde. À écouter certains promoteurs de ces projets, la parole des anciens serait par nature une leçon de sagesse, un trésor d''authenticité face à une époque déboussolée. Cette posture, pour généreuse qu''elle paraisse, enferme les vieilles personnes dans un nouveau rôle convenu : après la grand-mère gâteau, voici l''ancêtre oracle. Or les témoins ne demandent pas qu''on les vénère ; ils demandent qu''on les écoute, avec leurs contradictions, leurs silences, leurs souvenirs incertains, parfois leur mauvaise foi.

Transmettre la mémoire entre générations ne consiste pas à fabriquer des saints. C''est accepter de recevoir une parole humaine, donc imparfaite — et c''est précisément ce qui la rend irremplaçable.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c012-4000-0000-000000000007', 'TEXTE',
   'On parle volontiers des préjugés qui visent les seniors ; on évoque moins souvent ceux qui frappent la jeunesse. Une enquête conduite dans six villes moyennes par l''équipe du sociologue Bertrand Okafor montre pourtant que les stéréotypes d''âge circulent dans les deux sens, avec une efficacité comparable.

Côté aînés, les clichés sont connus : lenteur supposée, fermeture au changement, incompétence présumée dès qu''un écran apparaît. Côté jeunes, le portrait n''est guère plus flatteur : impatience, fragilité, allergie à l''effort. L''étude révèle surtout que ces images produisent des effets bien réels : des personnes de soixante-dix ans renoncent à prendre la parole en réunion publique de peur de paraître dépassées, tandis que des moins de vingt-cinq ans s''entendent refuser des responsabilités « en attendant de faire leurs preuves ».

Le plus frappant reste l''effet miroir : chaque groupe se sent caricaturé, mais reproduit sans hésiter les caricatures sur l''autre. Et les deux partagent la même conviction erronée d''être le seul à en souffrir. Les chercheurs y voient la racine du problème : tant que chacun se vivra uniquement comme victime des stéréotypes, personne ne se reconnaîtra comme leur véhicule. Briser ce cercle suppose de commencer non par accuser l''autre génération, mais par interroger ses propres évidences.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c012-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c012-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'Le texte conclut que le « conflit des générations » est « moins une réalité sociologique qu''un spectacle entretenu » par les voix les plus tranchées : **l''idée principale est que l''opposition entre jeunes et aînés est largement amplifiée**, les valeurs des deux groupes étant « presque superposables ». La réponse A contredit ce constat central en affirmant une opposition radicale. La réponse C est une sur-généralisation du détail-piège : les aînés souhaitent un rythme de changement « plus prudent », ils ne refusent pas « tout changement ». La réponse D promeut en conclusion un propos rapporté au conditionnel (« accuseraient ») et démenti par l''enquête. Mécanisme : distinguer la **thèse de l''auteur** des discours rapportés et du détail secondaire.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c012-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c012-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Que cherche à montrer l''auteur de ce texte ?',
   'Le texte qualifie le déclinisme d''« illusion d''optique que chaque génération reproduit à son tour » : **l''intention est de démonter le sentiment de déclin des jeunes générations comme un double biais psychologique** (mémoire embellie + projection). La réponse A prend la croyance d''ouverture pour un fait, alors que tout le texte la déconstruit. La réponse B contredit le détail-piège : les jeunes adultes « n''échappent pas entièrement au phénomène » et jugent déjà les adolescents. La réponse C inverse l''effet de projection : plus on se juge compétent dans un domaine, plus on perçoit le déclin — donc plus de sévérité, pas d''indulgence. Mécanisme : **inférence d''intention** face à une inversion et à une sur-généralisation tentantes.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c012-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c012-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Comment l''auteur se positionne-t-il à l''égard de ces lieux réunissant enfants et personnes âgées ?',
   'L''auteur écrit que « ces réserves ne condamnent pas le modèle » et qu''il « mérite mieux qu''un effet de mode » : **sa position est un soutien conditionnel — le modèle est prometteur s''il est réellement encadré et financé** (rôle décisif de la coordinatrice). La réponse B sur-généralise les « premiers résultats » : les évaluations portent sur de petits effectifs de volontaires, rien n''est « prouvé ». La réponse C contredit la phrase explicite « il ne suffit pas de juxtaposer une crèche et une maison de retraite ». La réponse D déforme les réserves en rejet : l''auteur n''appelle jamais à abandonner ces expériences. Mécanisme : repérer le **mouvement concessif** (enthousiasme rapporté, puis « un peu de prudence s''impose », puis réhabilitation finale).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c012-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c012-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Quelle est l''intention principale de l''auteur de ce texte ?',
   'Le texte oppose « la même alarme » récurrente aux « faits » établis par la linguiste, puis retourne la question avec ironie : **l''intention est de relativiser la panique sur le langage des jeunes en montrant qu''elle est cyclique et démentie par l''observation** (maîtrise de plusieurs registres). La réponse A inverse la conclusion : la gymnastique entre registres « accroît la souplesse » de la langue, elle ne l''appauvrit pas. La réponse B contredit le premier constat : les adolescents suivis utilisent « un français standard avec les adultes ». La réponse D déforme le détail-piège : « la plupart » des mots disparaissent, « seuls quelques survivants » entrent au dictionnaire — et ce n''est qu''un argument secondaire, pas l''objet du texte. Mécanisme : **inférence d''intention** contre une inversion et un détail vrai mais déformé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c012-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c012-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'L''équipe de suivi estime qu''évaluer ces ateliers « à l''aune des compétences transmises », c''est « passer à côté de l''essentiel » : **l''idée principale est que le vrai apport de ces ateliers est le lien créé entre générations, bien plus que les savoirs échangés** (liens qui se prolongent, changement de regard mesurable). La réponse A contredit un détail explicite : les progrès techniques « restent modestes » et la moitié des participants oublient vite. La réponse C déforme la conclusion : la réciprocité est « peut-être un prétexte », mais un prétexte « précieux » qui sert le dispositif au lieu de le desservir. La réponse D invente une asymétrie absente : le changement de regard est observé « des deux côtés ». Mécanisme : résister au **détail vrai mais secondaire** et à la déformation d''une nuance concessive.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c012-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c012-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur à l''égard des collectifs de « passeurs de mémoire » ?',
   'L''auteur juge « l''entreprise précieuse » et espère « qu''elle s''étende », avant la bascule « On se permettra pourtant une mise en garde » : **il soutient ces collectifs tout en refusant l''idéalisation de la parole des anciens** (le rôle convenu d''« ancêtre oracle »). La réponse B attribue à l''auteur la posture qu''il critique : la « leçon de sagesse » est le discours de « certains promoteurs », rapporté au conditionnel. La réponse C inverse la conclusion : les contradictions et souvenirs incertains rendent cette parole « irremplaçable », ils ne disqualifient pas les projets. La réponse D invente un reproche absent : rien n''accuse les bénévoles de déformer les récits. Mécanisme : la **concession rhétorique** (précieux… pourtant) signale une adhésion nuancée, pas un rejet ni une adhésion au discours rapporté.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c012-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c012-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte ?',
   'Le texte établit que les stéréotypes d''âge « circulent dans les deux sens » et décrit un « effet miroir » où chaque groupe « reproduit sans hésiter les caricatures sur l''autre » : **la bonne réponse synthétise cette réciprocité aveugle**, racine du problème selon les chercheurs. La réponse A contredit le texte, qui documente des effets concrets pour les deux groupes (prise de parole évitée chez les aînés, responsabilités refusées aux jeunes). La réponse B prend un cliché énuméré (« fragilité, allergie à l''effort ») pour un fait validé, alors qu''il est présenté comme caricature. La réponse D inverse un détail explicite : ces images « produisent des effets bien réels ». Mécanisme : **idée principale** contre l''inversion d''un détail et la confusion entre stéréotype rapporté et fait établi.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — mythe du conflit des générations (bonne réponse : position 2)
  ('11111111-c012-2100-0000-000000000001', '11111111-c012-1000-0000-000000000001',
   'Jeunes et aînés s''opposent radicalement sur la plupart des grandes questions de société',
   'false', '1'),

  ('11111111-c012-2200-0000-000000000001', '11111111-c012-1000-0000-000000000001',
   'L''opposition entre les générations est largement amplifiée par les voix les plus extrêmes',
   'true', '2'),

  ('11111111-c012-2300-0000-000000000001', '11111111-c012-1000-0000-000000000001',
   'Les aînés refusent tout changement de société, contrairement aux plus jeunes',
   'false', '3'),

  ('11111111-c012-2400-0000-000000000001', '11111111-c012-1000-0000-000000000001',
   'L''enquête confirme que les jeunes ont vu leur prospérité confisquée par leurs aînés',
   'false', '4'),

  -- item 02 — déclinisme « c'était mieux avant » (bonne réponse : position 4)
  ('11111111-c012-2100-0000-000000000002', '11111111-c012-1000-0000-000000000002',
   'Que les jeunes d''aujourd''hui sont réellement moins polis et moins travailleurs qu''autrefois',
   'false', '1'),

  ('11111111-c012-2200-0000-000000000002', '11111111-c012-1000-0000-000000000002',
   'Que seules les personnes âgées portent un regard sévère sur la jeunesse',
   'false', '2'),

  ('11111111-c012-2300-0000-000000000002', '11111111-c012-1000-0000-000000000002',
   'Que les personnes très compétentes dans un domaine jugent les jeunes avec plus d''indulgence',
   'false', '3'),

  ('11111111-c012-2400-0000-000000000002', '11111111-c012-1000-0000-000000000002',
   'Que le sentiment de déclin des nouvelles générations est une illusion que chaque âge reproduit',
   'true', '4'),

  -- item 03 — crèche en résidence pour aînés (bonne réponse : position 1)
  ('11111111-c012-2100-0000-000000000003', '11111111-c012-1000-0000-000000000003',
   'Il juge le modèle prometteur à condition d''être réellement encadré et financé dans la durée',
   'true', '1'),

  ('11111111-c012-2200-0000-000000000003', '11111111-c012-1000-0000-000000000003',
   'Il y voit la solution désormais prouvée au cloisonnement entre les âges',
   'false', '2'),

  ('11111111-c012-2300-0000-000000000003', '11111111-c012-1000-0000-000000000003',
   'Il estime qu''installer une crèche près d''une maison de retraite suffit à créer du lien',
   'false', '3'),

  ('11111111-c012-2400-0000-000000000003', '11111111-c012-1000-0000-000000000003',
   'Il recommande d''abandonner ces expériences, trop dépendantes du personnel',
   'false', '4'),

  -- item 04 — langage des jeunes (bonne réponse : position 3)
  ('11111111-c012-2100-0000-000000000004', '11111111-c012-1000-0000-000000000004',
   'Alerter sur l''appauvrissement réel de la langue chez les adolescents',
   'false', '1'),

  ('11111111-c012-2200-0000-000000000004', '11111111-c012-1000-0000-000000000004',
   'Montrer que les adolescents sont incapables d''employer un français standard avec les adultes',
   'false', '2'),

  ('11111111-c012-2300-0000-000000000004', '11111111-c012-1000-0000-000000000004',
   'Relativiser les inquiétudes sur le parler des jeunes en montrant qu''elles sont récurrentes et infondées',
   'true', '3'),

  ('11111111-c012-2400-0000-000000000004', '11111111-c012-1000-0000-000000000004',
   'Démontrer que la plupart des mots inventés par les jeunes finissent par entrer au dictionnaire',
   'false', '4'),

  -- item 05 — ateliers d'échange de savoirs (bonne réponse : position 2)
  ('11111111-c012-2100-0000-000000000005', '11111111-c012-1000-0000-000000000005',
   'Ces ateliers permettent aux participants d''acquérir des compétences techniques durables',
   'false', '1'),

  ('11111111-c012-2200-0000-000000000005', '11111111-c012-1000-0000-000000000005',
   'Le principal apport de ces ateliers est le lien créé entre générations, plus que les savoirs transmis',
   'true', '2'),

  ('11111111-c012-2300-0000-000000000005', '11111111-c012-1000-0000-000000000005',
   'La réciprocité affichée de l''échange est une illusion qui dessert ces dispositifs',
   'false', '3'),

  ('11111111-c012-2400-0000-000000000005', '11111111-c012-1000-0000-000000000005',
   'Les jeunes tirent davantage de bénéfices de ces ateliers que les personnes âgées',
   'false', '4'),

  -- item 06 — passeurs de mémoire (bonne réponse : position 1)
  ('11111111-c012-2100-0000-000000000006', '11111111-c012-1000-0000-000000000006',
   'Il soutient leur démarche tout en mettant en garde contre l''idéalisation de la parole des anciens',
   'true', '1'),

  ('11111111-c012-2200-0000-000000000006', '11111111-c012-1000-0000-000000000006',
   'Il considère la parole des anciens comme une leçon de sagesse face à une époque déboussolée',
   'false', '2'),

  ('11111111-c012-2300-0000-000000000006', '11111111-c012-1000-0000-000000000006',
   'Il juge ces projets inutiles tant que les témoignages recueillis restent contradictoires',
   'false', '3'),

  ('11111111-c012-2400-0000-000000000006', '11111111-c012-1000-0000-000000000006',
   'Il reproche aux bénévoles de déformer les récits qu''ils mettent en forme',
   'false', '4'),

  -- item 07 — stéréotypes d'âge réciproques (bonne réponse : position 3)
  ('11111111-c012-2100-0000-000000000007', '11111111-c012-1000-0000-000000000007',
   'Seules les personnes âgées subissent des conséquences concrètes des préjugés liés à l''âge',
   'false', '1'),

  ('11111111-c012-2200-0000-000000000007', '11111111-c012-1000-0000-000000000007',
   'Les jeunes manquent réellement d''endurance, ce qui explique la prudence à leur égard',
   'false', '2'),

  ('11111111-c012-2300-0000-000000000007', '11111111-c012-1000-0000-000000000007',
   'Les stéréotypes d''âge circulent dans les deux sens et chaque génération les reproduit sans le voir',
   'true', '3'),

  ('11111111-c012-2400-0000-000000000007', '11111111-c012-1000-0000-000000000007',
   'Les caricatures entre générations sont blessantes mais restent sans effet sur les comportements',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c012-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « rapports entre générations », 7 angles tous différents :
--     mythe du conflit des générations / déclinisme (« c'était mieux avant ») /
--     crèches en résidence pour aînés / langage des jeunes / ateliers d'échange
--     de savoirs réciproques / passeurs de mémoire / stéréotypes d'âge
--     réciproques. Aucun thème interdit (ni famille & société, ni travail,
--     ni numérique & vie privée, ni vie associative, etc.).
-- [x] Textes B2 longs : 175 / 190 / 192 / 181 / 206 / 185 / 197 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (rythme des changements vs refus de tout changement, « n'échappent pas
--     entièrement », rôle de la coordinatrice, « seuls quelques survivants »,
--     « la moitié oublient », posture des promoteurs rapportée, effet miroir).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, max 2 par position — ≤ 3 exigé).
-- [x] competence_code : ce_idee_principale ×3 (items 1, 5, 7),
--     ce_inference_intention ×2 (items 2, 4), ce_ton_auteur ×2 (items 3, 6).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme nommé
--     (concession rhétorique, inversion, sur-généralisation, détail vrai
--     mais secondaire, discours rapporté vs thèse, inférence d'intention).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (prénoms variés : Suzanne, Ilyès,
--     Aurélie Mercadier, Bertrand Okafor ; villes : Nantes, Rennes, Périgueux,
--     Saint-Étienne, Brest, Mulhouse ; chiffres inventés).
-- ============================================================================
