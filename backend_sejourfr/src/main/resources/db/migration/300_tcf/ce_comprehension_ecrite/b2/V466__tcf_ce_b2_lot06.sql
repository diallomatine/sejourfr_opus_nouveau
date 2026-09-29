-- ============================================================================
-- V466 — TCF CE B2 — lot 06 (thème : numérique & vie privée)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~205-220 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : vidéosurveillance algorithmique / exposition des enfants en ligne /
-- montres connectées et données de santé / fatigue du consentement (bandeaux) /
-- enceintes connectées / droit à l'oubli / courtiers en données de localisation.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c006-4000-0000-000000000001', 'TEXTE',
   'Expérimentée d''abord dans quelques gares, la vidéosurveillance dite « intelligente » s''installe désormais dans les rues de plusieurs villes moyennes. À Montluçon comme à Vannes, des caméras couplées à des logiciels d''analyse repèrent en temps réel les « comportements suspects » : un attroupement, un bagage abandonné, une silhouette qui court. Les maires qui s''en équipent jurent qu''il ne s''agit pas de reconnaissance faciale, interdite hors expérimentation. C''est exact, mais l''argument rassure à bon compte.

Car le glissement est déjà engagé. Les mêmes industriels qui vendent aujourd''hui la détection de mouvements proposent, dans leurs catalogues destinés à l''export, l''identification biométrique en option. Et chaque dispositif installé crée une infrastructure — caméras haute définition, serveurs, habitudes administratives — qu''il suffira d''activer le jour où la loi s''assouplira. Or l''histoire récente des technologies de surveillance enseigne qu''une exception finit rarement par se refermer : prévue pour un grand événement sportif, prolongée pour le suivant, banalisée ensuite.

Le débat ne porte donc pas sur les caméras d''aujourd''hui, mais sur la société qu''elles préparent. Accepter d''être analysé en marchant dans la rue, même anonymement, modifie déjà les comportements : on ne flâne pas de la même manière sous un algorithme. C''est cette liberté-là, discrète et fondamentale, que personne ne pense à défendre.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c006-4000-0000-000000000002', 'TEXTE',
   'Avant même de savoir marcher, un enfant français apparaît en moyenne sur près de deux cents photos publiées en ligne par ses parents. Anniversaires, sorties d''école, colères filmées « pour rire » : ce que les chercheurs nomment le « sharenting » s''est imposé comme une pratique ordinaire, encouragée par des plateformes qui récompensent l''intime en visibilité.

Les parents qui publient ne sont ni négligents ni malveillants : ils partagent une fierté, entretiennent un lien avec une famille éloignée, parfois documentent simplement leur quotidien. Là n''est pas la question. Le problème est que l''enfant, lui, n''a rien choisi. Les images aimables d''aujourd''hui — un bain, une grimace, un bulletin scolaire brandi — composeront demain une archive consultable par ses camarades, ses recruteurs et des inconnus moins bienveillants : selon les services de protection de l''enfance, une part notable des contenus circulant sur les forums pédocriminels provient de comptes familiaux parfaitement anodins.

La loi reconnaît désormais que le droit à l''image de l''enfant s''impose aussi à ses parents, et permet en dernier recours d''en confier la défense à un tiers. Avancée symbolique, diront certains. Sans doute, mais le symbole dit l''essentiel : l''enfant n''est pas un contenu. Avant de publier, une question suffit : accepterait-il, à vingt ans, que cette image existe ?',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c006-4000-0000-000000000003', 'TEXTE',
   'Rythme cardiaque, qualité du sommeil, cycles menstruels, taux d''oxygène : les montres connectées enregistrent désormais des informations qu''un médecin n''oserait pas demander sans raison. Plus de dix millions de Français portent ou possèdent un de ces objets, et la plupart n''ont jamais lu la politique de confidentialité qui les accompagne.

Ils auraient pourtant des surprises. Une étude de l''association lyonnaise Datalogis, portant sur trente-sept applications de suivi de santé, montre que vingt-neuf d''entre elles transmettent des données à des sociétés tierces — régies publicitaires, courtiers, parfois assureurs. Le procédé est légal dès lors qu''une case a été cochée à l''installation ; il n''en est pas moins vertigineux. Car ces données ne sont pas des données comme les autres : croisées avec d''autres fichiers, elles permettent de deviner une grossesse, une dépression, le début d''une maladie chronique, bien avant que l''intéressé n''en parle à quiconque.

Faut-il pour autant jeter sa montre ? Ce serait se tromper de cible. Ces objets aident réellement des millions de personnes à bouger davantage ou à surveiller une pathologie. Le scandale n''est pas la mesure de soi, c''est son commerce. Tant que le modèle économique de la santé connectée reposera sur la revente de l''intime, le consentement coché à la va-vite restera ce qu''il est : une fiction juridique.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c006-4000-0000-000000000004', 'TEXTE',
   '« Tout accepter ». Le bouton s''affiche, le doigt clique, la page se libère. Chaque internaute français rencontre en moyenne plusieurs dizaines de bandeaux de consentement par semaine, et les enquêtes convergent : plus de huit clics sur dix se font sans lecture, en moins de deux secondes. Ce que le droit européen avait conçu comme un instrument d''autonomie est devenu un réflexe d''évitement.

Le paradoxe mérite qu''on s''y arrête. Le règlement européen sur les données reposait sur une idée généreuse : informé, l''individu choisirait librement. Mais un choix répété des milliers de fois cesse d''être un choix ; il devient une corvée, que l''on expédie. Les professionnels du secteur l''ont parfaitement compris, qui rendent le refus laborieux — trois écrans, des intitulés ambigus — quand l''acceptation tient en un bouton coloré. La défaillance n''est donc pas celle des internautes, trop pressés ou trop paresseux : elle est celle d''une architecture qui organise méthodiquement leur lassitude.

Des solutions existent, et elles ne passent pas par davantage de bandeaux. Un réglage unique dans le navigateur, opposable à tous les sites, transformerait un harcèlement quotidien en décision prise une fois. Si cette piste, techniquement prête, reste bloquée, ce n''est pas par difficulté : c''est qu''une partie de l''économie du web vit précisément de notre fatigue.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c006-4000-0000-000000000005', 'TEXTE',
   'Elles trônent sur les buffets, répondent aux questions des enfants, lancent la radio du matin : les enceintes connectées équipent désormais un foyer français sur quatre. Leur micro, par construction, écoute en permanence — il le faut bien, pour réagir au mot d''activation. Les fabricants assurent que rien n''est transmis avant ce signal, et c''est globalement vrai. Le problème se loge ailleurs.

Il se loge d''abord dans les erreurs : une conversation ordinaire contient régulièrement des sonorités proches du mot magique, et l''appareil, croyant être appelé, capture alors quelques secondes de vie domestique qui filent vers des serveurs lointains. Des employés sous-traitants, chargés d''améliorer la reconnaissance vocale, ont raconté avoir écouté des disputes, des confidences médicales, des scènes intimes — des fragments anonymisés, certes, mais dont le contenu permettait parfois d''identifier les personnes.

Il se loge ensuite dans l''asymétrie. L''utilisateur peut consulter et effacer ses enregistrements ; presque personne ne le fait, faute de le savoir. Les invités, eux, n''ont jamais consenti à rien : on n''affiche pas à l''entrée de son salon que la pièce est équipée d''un micro. La convivialité de l''objet fait oublier sa nature. Une enceinte connectée n''est ni un espion ni un simple haut-parleur : c''est un micro domestique, et c''est ainsi qu''il faudrait apprendre à la traiter.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c006-4000-0000-000000000006', 'TEXTE',
   'En 2014, la justice européenne consacrait le « droit à l''oubli » : chacun peut demander aux moteurs de recherche de déréférencer des pages anciennes, inexactes ou devenues sans intérêt public. Douze ans et des millions de demandes plus tard, l''heure du bilan est venue, et il est plus nuancé que les espoirs d''alors.

D''un côté, le mécanisme fonctionne : environ une demande sur deux aboutit, et des vies ont changé. Hakim, condamné il y a dix-neuf ans pour une fraude mineure depuis effacée de son casier, raconte avoir retrouvé un emploi le jour où l''article relatant son procès a cessé d''apparaître sous son nom. De l''autre, les limites sont têtues. Le déréférencement ne supprime rien : la page demeure, accessible à qui sait chercher. Il s''arrête aussi aux frontières : invisible en Europe, le contenu reste affiché ailleurs. Surtout, la procédure suppose de savoir qu''elle existe, de rédiger, d''argumenter, de contester un refus : autant d''obstacles qui la réservent de fait aux plus armés.

Le droit à l''oubli n''est donc ni la victoire totale célébrée par les uns, ni le gadget dénoncé par les autres. C''est un correctif réel mais partiel, qui rappelle une vérité d''époque : sur Internet, la mémoire est devenue la règle, et l''oubli, une conquête.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c006-4000-0000-000000000007', 'TEXTE',
   'Une application de lampe de poche qui réclame l''accès à la position. Un jeu de cartes qui s''intéresse au carnet d''adresses. L''utilisateur hausse les épaules, accepte, et passe à autre chose. Il vient pourtant d''alimenter l''une des industries les plus discrètes du numérique : celle des courtiers en données, qui collectent, agrègent et revendent les traces laissées par nos téléphones.

Le journaliste Bertrand Faivre en a fait l''expérience pour la revue Octet : en se faisant passer pour une jeune entreprise de marketing, il a pu acheter, pour moins de trois mille euros, les historiques de localisation de plusieurs centaines de milliers d''appareils circulant dans la région de Besançon. Les fichiers étaient anonymisés, au sens où aucun nom n''y figurait. Mais un téléphone qui dort chaque nuit à la même adresse et passe ses journées au même bureau n''a pas besoin d''un nom pour être identifié. En quelques recoupements, le journaliste a pu suivre les trajets d''un magistrat, d''une infirmière, d''un militaire affecté à une base sensible.

Aucune de ces personnes n''avait conscience d''être suivie ; toutes avaient pourtant « consenti », quelque part, un jour de pluie, en installant une application météo. Ce marché prospère dans un angle mort : trop technique pour indigner, trop diffus pour être combattu. C''est précisément ce qui devrait inquiéter.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c006-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c006-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Que cherche à montrer l''auteur de ce texte ?',
   'L''auteur affirme que « le débat ne porte donc pas sur les caméras d''aujourd''hui, mais sur la société qu''elles préparent » : **les dispositifs actuels créent une infrastructure activable le jour où la loi s''assouplira**, ce que la bonne réponse reformule. La réponse A contredit le texte : « C''est exact » valide la parole des maires, la reconnaissance faciale n''est pas utilisée aujourd''hui. La réponse C invente un bilan absent : aucun effet sur la délinquance n''est mentionné. La réponse D déforme un détail : la reconnaissance faciale est interdite « hors expérimentation », et l''auteur envisage justement un assouplissement futur, pas une interdiction définitive. Mécanisme : **inférence d''intention** — repérer la thèse prospective derrière un constat présent.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c006-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c006-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'Le texte pose que « le problème est que l''enfant, lui, n''a rien choisi » et conclut « l''enfant n''est pas un contenu » : **l''idée principale est l''absence de consentement de l''enfant face à une archive qui engagera son avenir**. La réponse A contredit un passage explicite : les parents ne sont « ni négligents ni malveillants ». La réponse B déforme la portée de la loi : elle reconnaît un droit à l''image opposable aux parents, elle n''interdit pas de publier. La réponse C est une sur-généralisation inversée du détail-piège : une part notable des contenus des forums pédocriminels vient de comptes familiaux, ce qui ne signifie pas que la majorité des photos familiales y finissent. Mécanisme : distinguer le **détail vrai mais secondaire** de l''idée centrale.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c006-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c006-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur à l''égard des montres connectées ?',
   'L''auteur écrit : « Le scandale n''est pas la mesure de soi, c''est son commerce », après avoir reconnu que ces objets « aident réellement des millions de personnes ». **Sa position : utiles en elles-mêmes, condamnables par leur modèle économique fondé sur la revente des données intimes.** La réponse B contredit « Ce serait se tromper de cible », réponse explicite à la question de jeter sa montre. La réponse C inverse la conclusion : le consentement coché à la va-vite est qualifié de « fiction juridique », pas de garantie suffisante. La réponse D promeut un constat neutre (la plupart n''ont jamais lu la politique de confidentialité) en reproche, alors que l''auteur impute la défaillance au système, pas aux utilisateurs. Mécanisme : **ton de l''auteur** — distinguer la critique ciblée (le commerce) de l''objet lui-même.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c006-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c006-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Selon l''auteur, à quoi tient l''échec du consentement en ligne ?',
   'Le texte tranche explicitement : « La défaillance n''est donc pas celle des internautes [...] : elle est celle d''une architecture qui organise méthodiquement leur lassitude ». **La cause est structurelle : un système conçu pour épuiser le choix**, refus laborieux contre acceptation en un clic. La réponse A reprend précisément l''explication que l''auteur écarte (« trop pressés ou trop paresseux »). La réponse B sur-étend la critique : le règlement reposait sur « une idée généreuse », c''est sa mise en œuvre qui échoue, pas son principe. La réponse D inverse un détail : la piste du réglage unique est « techniquement prête », elle est bloquée par intérêt économique. Mécanisme : **inversion cause/effet** — identifier la cause défendue contre la cause explicitement réfutée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c006-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c006-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur les enceintes connectées ?',
   'Le texte situe le problème « ailleurs » que dans la transmission permanente : **dans les captations accidentelles (sonorités proches du mot d''activation) et dans l''asymétrie du consentement, jamais demandé aux invités**. La bonne réponse synthétise ces deux volets. La réponse A contredit un passage explicite : « rien n''est transmis avant ce signal, et c''est globalement vrai ». La réponse C inverse un détail-piège : les fragments anonymisés permettaient « parfois d''identifier les personnes ». La réponse D contredit le texte : « presque personne ne le fait, faute de le savoir ». Mécanisme : **idée principale contre détails inversés** — la difficulté tient à ce que le texte commence par disculper l''objet avant de déplacer le problème.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c006-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c006-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Quel bilan l''auteur dresse-t-il du droit à l''oubli ?',
   'La conclusion est explicite : « ni la victoire totale célébrée par les uns, ni le gadget dénoncé par les autres [...] un correctif réel mais partiel ». **Le bilan est nuancé : un mécanisme qui fonctionne, mais incomplet et inégalitaire** (procédure réservée « de fait aux plus armés »). La réponse A reprend la position du « gadget » que l''auteur rejette : une demande sur deux aboutit et l''exemple de Hakim montre des effets concrets. La réponse B reprend l''autre extrême écarté, et inverse la formule finale : sur Internet, c''est la mémoire qui est la règle, pas l''oubli. La réponse C contredit une limite centrale : « le déréférencement ne supprime rien ». Mécanisme : **ton de l''auteur** — repérer le jugement d''équilibre entre deux positions extrêmes toutes deux récusées.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c006-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c006-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Que démontre l''enquête rapportée dans ce texte ?',
   'Le texte explique qu''« un téléphone qui dort chaque nuit à la même adresse [...] n''a pas besoin d''un nom pour être identifié » : **l''anonymisation des données de localisation est illusoire, de simples recoupements suffisent à retrouver les personnes**. La réponse B déforme les faits : le journaliste a acheté les fichiers sur un marché présenté comme légal (« le procédé prospère dans un angle mort »), il n''a rien piraté. La réponse C promeut les exemples (magistrat, infirmière, militaire) en règle générale, alors que des centaines de milliers d''appareils ordinaires figuraient dans les fichiers. La réponse D sur-généralise un détail final : l''application météo est un exemple de consentement distrait, pas la seule source du marché. Mécanisme : **inférence de la démonstration** — relier l''expérience rapportée à la thèse qu''elle illustre.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — vidéosurveillance algorithmique (bonne réponse : position 2)
  ('11111111-c006-2100-0000-000000000001', '11111111-c006-1000-0000-000000000001',
   'Les maires dissimulent l''usage actuel de la reconnaissance faciale dans leurs villes',
   'false', '1'),

  ('11111111-c006-2200-0000-000000000001', '11111111-c006-1000-0000-000000000001',
   'Les dispositifs actuels installent une infrastructure qui prépare une surveillance bien plus large',
   'true', '2'),

  ('11111111-c006-2300-0000-000000000001', '11111111-c006-1000-0000-000000000001',
   'La vidéosurveillance intelligente a déjà fait reculer la délinquance dans les villes équipées',
   'false', '3'),

  ('11111111-c006-2400-0000-000000000001', '11111111-c006-1000-0000-000000000001',
   'La loi française interdit définitivement toute identification biométrique dans l''espace public',
   'false', '4'),

  -- item 02 — exposition des enfants en ligne (bonne réponse : position 4)
  ('11111111-c006-2100-0000-000000000002', '11111111-c006-1000-0000-000000000002',
   'Les parents qui exposent leurs enfants en ligne font preuve d''une négligence coupable',
   'false', '1'),

  ('11111111-c006-2200-0000-000000000002', '11111111-c006-1000-0000-000000000002',
   'La loi interdit désormais aux parents de publier des photos de leurs enfants',
   'false', '2'),

  ('11111111-c006-2300-0000-000000000002', '11111111-c006-1000-0000-000000000002',
   'La majorité des photos familiales publiées finissent sur des forums pédocriminels',
   'false', '3'),

  ('11111111-c006-2400-0000-000000000002', '11111111-c006-1000-0000-000000000002',
   'Publier l''image d''un enfant engage son avenir sans qu''il ait jamais pu y consentir',
   'true', '4'),

  -- item 03 — montres connectées et données de santé (bonne réponse : position 1)
  ('11111111-c006-2100-0000-000000000003', '11111111-c006-1000-0000-000000000003',
   'Il défend leur utilité mais condamne le commerce des données intimes qu''elles génèrent',
   'true', '1'),

  ('11111111-c006-2200-0000-000000000003', '11111111-c006-1000-0000-000000000003',
   'Il recommande aux utilisateurs de s''en débarrasser pour protéger leur vie privée',
   'false', '2'),

  ('11111111-c006-2300-0000-000000000003', '11111111-c006-1000-0000-000000000003',
   'Il estime que le consentement donné à l''installation règle la question juridique',
   'false', '3'),

  ('11111111-c006-2400-0000-000000000003', '11111111-c006-1000-0000-000000000003',
   'Il reproche aux utilisateurs de ne pas lire les politiques de confidentialité',
   'false', '4'),

  -- item 04 — fatigue du consentement (bonne réponse : position 3)
  ('11111111-c006-2100-0000-000000000004', '11111111-c006-1000-0000-000000000004',
   'À la paresse des internautes, qui refusent de lire ce qu''ils acceptent',
   'false', '1'),

  ('11111111-c006-2200-0000-000000000004', '11111111-c006-1000-0000-000000000004',
   'Au règlement européen sur les données, dont le principe même était une erreur',
   'false', '2'),

  ('11111111-c006-2300-0000-000000000004', '11111111-c006-1000-0000-000000000004',
   'À une architecture qui organise délibérément la lassitude des utilisateurs',
   'true', '3'),

  ('11111111-c006-2400-0000-000000000004', '11111111-c006-1000-0000-000000000004',
   'À l''impossibilité technique de remplacer les bandeaux par un réglage unique',
   'false', '4'),

  -- item 05 — enceintes connectées (bonne réponse : position 2)
  ('11111111-c006-2100-0000-000000000005', '11111111-c006-1000-0000-000000000005',
   'Elles transmettent en continu toutes les conversations du foyer vers des serveurs',
   'false', '1'),

  ('11111111-c006-2200-0000-000000000005', '11111111-c006-1000-0000-000000000005',
   'Leurs risques tiennent aux captations accidentelles et au consentement jamais demandé aux invités',
   'true', '2'),

  ('11111111-c006-2300-0000-000000000005', '11111111-c006-1000-0000-000000000005',
   'L''anonymisation des extraits écoutés empêche toute identification des personnes',
   'false', '3'),

  ('11111111-c006-2400-0000-000000000005', '11111111-c006-1000-0000-000000000005',
   'Les utilisateurs consultent et effacent régulièrement leurs enregistrements vocaux',
   'false', '4'),

  -- item 06 — droit à l'oubli (bonne réponse : position 4)
  ('11111111-c006-2100-0000-000000000006', '11111111-c006-1000-0000-000000000006',
   'Un échec, le dispositif n''ayant rien changé pour les personnes concernées',
   'false', '1'),

  ('11111111-c006-2200-0000-000000000006', '11111111-c006-1000-0000-000000000006',
   'Une victoire totale qui a fait de l''oubli la règle sur Internet',
   'false', '2'),

  ('11111111-c006-2300-0000-000000000006', '11111111-c006-1000-0000-000000000006',
   'Un droit pleinement efficace, puisque les contenus déréférencés disparaissent du web',
   'false', '3'),

  ('11111111-c006-2400-0000-000000000006', '11111111-c006-1000-0000-000000000006',
   'Un correctif utile mais limité, dont l''accès reste inégal selon les personnes',
   'true', '4'),

  -- item 07 — courtiers en données de localisation (bonne réponse : position 1)
  ('11111111-c006-2100-0000-000000000007', '11111111-c006-1000-0000-000000000007',
   'L''anonymat des données de localisation vendues est illusoire, de simples recoupements suffisant à identifier chacun',
   'true', '1'),

  ('11111111-c006-2200-0000-000000000007', '11111111-c006-1000-0000-000000000007',
   'Le journaliste a dû enfreindre la loi pour se procurer ces historiques de localisation',
   'false', '2'),

  ('11111111-c006-2300-0000-000000000007', '11111111-c006-1000-0000-000000000007',
   'Seules les personnes exerçant des métiers sensibles sont visées par les courtiers en données',
   'false', '3'),

  ('11111111-c006-2400-0000-000000000007', '11111111-c006-1000-0000-000000000007',
   'Les applications météo sont les seules à revendre la position de leurs utilisateurs',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c006-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « numérique & vie privée », 7 angles tous différents :
--     vidéosurveillance algorithmique / exposition des enfants en ligne
--     (sharenting) / montres connectées & données de santé / fatigue du
--     consentement (bandeaux cookies) / enceintes connectées / droit à
--     l'oubli / courtiers en données de localisation. Aucun thème interdit
--     (pas de travail, éducation, santé publique comme sujets : l'angle reste
--     la vie privée numérique).
-- [x] Textes B2 longs : 209 / 212 / 215 / 215 / 218 / 213 / 217 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (« C'est exact, mais », « ni négligents ni malveillants », 29/37
--     applications, « techniquement prête », « globalement vrai »,
--     « ne supprime rien », fichiers « anonymisés »).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2, ce_inference_intention ×3,
--     ce_ton_auteur ×2.
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme nommé
--     (inférence d'intention, inversion cause/effet, détail vrai mais
--     secondaire, sur-généralisation, ton de l'auteur).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (prénoms, villes, chiffres,
--     associations et revues inventés).
-- ============================================================================
