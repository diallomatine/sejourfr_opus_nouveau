-- ============================================================================
-- V461 — TCF CE B2 — lot 01 (thème : famille & société)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~175-205 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : familles recomposées, garde d'enfants, aidants familiaux,
-- parentalité, fratries, grands-parents, monoparentalité.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c001-4000-0000-000000000001', 'TEXTE',
   'Une famille sur dix, en France, est aujourd''hui une famille recomposée. Le chiffre, longtemps perçu comme le signe d''une crise du modèle conjugal, s''est banalisé au point de ne plus susciter de commentaire. Les beaux-parents, demi-frères et quasi-sœurs peuplent désormais les cours d''école sans que personne ne s''en étonne.

Cette normalisation statistique masque pourtant une réalité plus rugueuse. Sur le plan juridique, le beau-parent reste un fantôme : il conduit l''enfant chez le médecin, signe les cahiers de liaison, finance une partie du quotidien, mais ne dispose d''aucun statut reconnu. En cas de séparation ou de décès du parent biologique, le lien construit pendant des années peut être rompu du jour au lendemain, sans recours.

Plusieurs propositions de loi ont tenté d''instaurer un « mandat d''éducation quotidienne », toutes enterrées au motif qu''il fragiliserait l''autorité des parents biologiques. L''argument se respecte, mais il revient à nier ce que vivent des millions de foyers. Reconnaître juridiquement le rôle du beau-parent, ce n''est pas affaiblir la filiation : c''est cesser de faire comme si la famille d''aujourd''hui ressemblait encore à celle d''hier.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c001-4000-0000-000000000002', 'TEXTE',
   'On aurait pu croire que la baisse de la natalité, observée depuis dix ans, allait mécaniquement détendre la situation de la garde d''enfants. Il n''en est rien. À Roubaix comme à Aurillac, les parents de jeunes enfants décrivent le même parcours d''obstacles : listes d''attente interminables, refus en série, solutions de fortune.

L''explication tient moins au nombre d''enfants qu''à l''effondrement silencieux d''un métier : celui d''assistante maternelle. Près de la moitié des professionnelles en exercice partiront à la retraite d''ici à 2030, et les candidates ne se bousculent pas pour les remplacer. Rémunération horaire faible, amplitude de travail extensible, isolement professionnel, responsabilité écrasante : le métier cumule les handicaps, sans bénéficier de la reconnaissance accordée aux crèches collectives, pourtant minoritaires dans l''offre de garde.

Les pouvoirs publics annoncent régulièrement des créations de places en structures collectives. C''est utile, mais c''est regarder le problème par le petit bout de la lorgnette : tant que le cœur du système, l''accueil individuel, continuera de se vider, les annonces ne combleront jamais le déficit. Revaloriser ce métier de l''ombre n''est plus une option.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c001-4000-0000-000000000003', 'TEXTE',
   'Ils seraient plus de neuf millions en France à soutenir au quotidien un proche malade, âgé ou handicapé. Neuf millions de conjoints, de filles, de fils — souvent des filles, d''ailleurs — qui jonglent entre leur emploi, leur propre famille et les rendez-vous médicaux d''un parent qui décline. On les appelle les « aidants familiaux », terme administratif bien commode pour désigner ce que la solidarité publique a renoncé à prendre en charge.

Que l''on ne s''y trompe pas : aider un proche peut être un choix, parfois même une fierté. Mais il faut être aveugle pour ne pas voir l''épuisement derrière le dévouement. Un aidant sur trois déclare avoir renoncé à des soins pour lui-même ; un sur quatre a réduit ou cessé son activité professionnelle, avec les conséquences que l''on imagine sur sa future retraite.

Le congé de proche aidant existe, certes, ainsi qu''un droit au répit théorique. Mais indemnisé quelques semaines à peine, méconnu des employeurs, il relève davantage du symbole que de la politique publique. Tant que la société considérera ces millions d''heures de soin comme une affaire privée, elle continuera de vivre à crédit sur la santé de ceux qui tiennent les autres debout.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c001-4000-0000-000000000004', 'TEXTE',
   'Jamais les parents n''ont eu autant de livres, de podcasts et de comptes spécialisés pour les guider ; jamais ils ne se sont sentis aussi coupables. Tel est le paradoxe que souligne la sociologue Nadia Belkacem dans une enquête menée auprès de huit cents familles : plus les parents consultent de contenus sur la « parentalité positive », plus leur sentiment d''incompétence augmente.

Le constat n''est pas anecdotique. Derrière les conseils bienveillants — ne jamais crier, accueillir chaque émotion, bannir toute punition — se cache une norme d''autant plus tyrannique qu''elle se présente comme de la bienveillance. L''écart entre l''idéal prescrit et la réalité d''un mardi soir, entre un enfant épuisé et un parent qui rentre tard, devient une faute personnelle. Et comme cette norme circule surtout chez les mères, c''est sur elles que retombe l''essentiel de la culpabilité.

Faut-il jeter ces savoirs aux orties ? Évidemment non : on élève mieux un enfant en comprenant ses besoins. Mais un principe utile devient toxique quand il se transforme en tribunal permanent. Les enfants n''ont pas besoin de parents parfaits ; ils ont besoin de parents suffisamment présents, et suffisamment sereins pour le rester.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c001-4000-0000-000000000005', 'TEXTE',
   'L''aîné serait sérieux et autoritaire, le benjamin charmeur et rebelle, l''enfant du milieu éternel oublié : les croyances sur le rang de naissance ont la vie dure, jusque dans les entretiens d''embauche où certains recruteurs avouent y prêter attention. Une vaste étude menée par une équipe de l''université de Gand sur plus de vingt mille adultes vient pourtant de leur porter un coup sérieux : une fois neutralisés l''âge et la taille de la famille, le rang de naissance n''explique presque rien des différences de personnalité entre frères et sœurs.

Presque rien, mais pas tout à fait rien : les chercheurs observent un très léger avantage des aînés dans les tests de raisonnement, attribué au temps d''attention parentale dont ils ont bénéficié seuls. Un écart réel, mais si faible qu''il ne permet aucune prédiction individuelle.

D''où vient alors la ténacité de ces portraits de famille ? De notre goût pour les explications simples, répondent les auteurs. Ce qui façonne réellement une personnalité — le tempérament, les rencontres, le climat familial, les hasards de la vie — est trop complexe pour tenir dans une case. Le rang de naissance, lui, offre une histoire toute prête. Trop belle pour être vraie.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c001-4000-0000-000000000006', 'TEXTE',
   'Chaque mercredi, Mireille, soixante-six ans, traverse la moitié de Lyon pour garder ses deux petits-enfants. Comme elle, près d''un grand-parent sur deux assure une garde régulière, ce qui représente, selon les estimations, l''équivalent de plusieurs centaines de milliers de places d''accueil que la collectivité n''a pas à financer. Pilier silencieux du système, cette solidarité familiale commence pourtant à se fissurer.

Première raison : le recul de l''âge de départ à la retraite. Les jeunes grands-parents, encore en activité, ne sont tout simplement plus disponibles le mardi à seize heures trente. Deuxième raison : la mobilité géographique, qui éloigne les générations de plusieurs centaines de kilomètres. Troisième raison, plus discrète : une partie des retraités revendique désormais le droit de profiter de cette période de la vie sans la consacrer entièrement aux autres, quitte à décevoir leurs propres enfants.

Aucune de ces évolutions n''est scandaleuse en soi. Mais leur addition dessine un problème que personne n''anticipe : le jour où les grands-parents ne pourront plus, ou ne voudront plus, jouer les variables d''ajustement, c''est tout l''équilibre de la garde d''enfants qui vacillera. Les politiques familiales feraient bien d''intégrer cette donnée avant d''y être contraintes.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c001-4000-0000-000000000007', 'TEXTE',
   'Une famille sur quatre, en France, ne compte qu''un seul parent au foyer — une mère dans plus de huit cas sur dix. Derrière cette réalité massive, les politiques publiques continuent pourtant de raisonner comme si la famille type comptait deux salaires, deux emplois du temps, deux paires de bras.

Les chiffres devraient suffire à provoquer un sursaut : un tiers des familles monoparentales vit sous le seuil de pauvreté, soit trois fois plus que les autres ménages avec enfants. Et la pauvreté n''est que la partie visible du problème. Comment se rendre à un entretien d''embauche quand aucune solution de garde n''accepte un enfant après dix-huit heures ? Comment envisager une formation, une promotion, une mutation, quand chaque imprévu repose sur une seule personne ?

On objectera que des aides existent : allocation de soutien familial, majorations diverses, service public des pensions alimentaires. C''est exact, et il serait injuste de prétendre que rien n''a été fait. Mais ces dispositifs compensent à la marge, quand c''est l''organisation même de la société — horaires, services, logement, marché du travail — qui reste pensée pour des couples. Tant que cette évidence ne sera pas regardée en face, les mères solos continueront de porter seules ce que la collectivité refuse de voir.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c001-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c001-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale défendue par l''auteur ?',
   'L''auteur conclut : « Reconnaître juridiquement le rôle du beau-parent, ce n''est pas affaiblir la filiation ». **L''idée principale est un plaidoyer pour un statut juridique du beau-parent.** La réponse A est une sur-généralisation : une famille sur dix est recomposée, ce qui n''en fait pas une majorité. La réponse B sur-étend le propos : l''auteur demande une reconnaissance du rôle, jamais un remplacement des parents biologiques. La réponse D inverse les faits : les propositions de loi ont été enterrées, et c''est l''argument de leurs opposants qui invoquait cette fragilisation. Mécanisme testé : distinguer la **thèse défendue** des arguments rapportés au discours indirect.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c001-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c001-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur les difficultés de garde d''enfants ?',
   'Le texte affirme que « l''explication tient moins au nombre d''enfants qu''à l''effondrement silencieux d''un métier ». **La cause centrale est la crise du métier d''assistante maternelle**, que la bonne réponse reformule. La réponse B inverse le rapport de cause à effet : la baisse de la natalité n''a justement pas détendu la situation (« Il n''en est rien »). La réponse C contredit un détail explicite : les crèches collectives sont « minoritaires dans l''offre de garde ». La réponse D déforme un chiffre : la moitié des professionnelles partiront à la retraite d''ici à 2030, elles n''ont pas déjà quitté le métier. Mécanisme : inférence de la **cause principale** face à une inversion cause/effet tentante.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c001-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c001-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur à l''égard des dispositifs publics destinés aux aidants ?',
   'L''auteur écrit que le congé de proche aidant « relève davantage du symbole que de la politique publique » : **il reconnaît l''existence des dispositifs mais les juge dérisoires** face aux neuf millions d''aidants. La réponse A invente une idée absente : rien n''indique que les aides découragent les familles. La réponse B inverse le ton : « certes » introduit une concession aussitôt retournée par « Mais », pas un éloge. La réponse C contredit la conclusion : l''auteur dénonce précisément le fait de traiter ce soin « comme une affaire privée ». Mécanisme : repérer la **concession rhétorique** (certes… mais) qui signale une critique, non une approbation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c001-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c001-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Quelle est l''intention principale de l''auteur de ce texte ?',
   'Tout le texte oppose l''utilité des savoirs éducatifs (« on élève mieux un enfant en comprenant ses besoins ») à leur dérive en « tribunal permanent » : **l''intention est de dénoncer la culpabilisation des parents sans rejeter les apports de ces contenus**. La réponse A sur-étend la critique : l''auteur ne conteste jamais le fondement scientifique de ces savoirs. La réponse C inverse le propos : consulter davantage de contenus augmente justement le sentiment d''incompétence selon l''enquête citée. La réponse D contredit un détail : la norme « circule surtout chez les mères », la pression n''est pas équitablement partagée. Mécanisme : **inférence d''intention** à partir d''une structure concessive (critique nuancée, ni rejet ni adhésion).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c001-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c001-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'L''étude citée conclut que « le rang de naissance n''explique presque rien des différences de personnalité » : **l''idée principale est l''invalidation scientifique des croyances sur le rang de naissance**. La réponse B est une sur-généralisation du détail-piège : le « très léger avantage » des aînés dans les tests de raisonnement « ne permet aucune prédiction individuelle ». La réponse C inverse l''intention : le texte présente l''attention des recruteurs comme une croyance tenace, pas comme une pratique fondée. La réponse D déforme la méthode : l''âge et la taille de la famille sont des variables neutralisées par les chercheurs, pas des facteurs présentés comme déterminants. Mécanisme : résister au **détail vrai mais secondaire** promu en idée principale.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c001-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c001-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Que cherche à montrer l''auteur de ce texte ?',
   'Le texte annonce que cette solidarité « commence pourtant à se fissurer » et conclut que sans les grands-parents, « c''est tout l''équilibre de la garde d''enfants qui vacillera » : **la bonne réponse relie l''érosion de cette garde familiale à la fragilité du système entier**. La réponse A sur-généralise : seule « une partie des retraités » revendique du temps pour elle, il n''y a pas de refus massif. La réponse C inverse un détail : ces gardes représentent des places que la collectivité « n''a pas à financer ». La réponse D inverse la cause et l''effet : le recul de la retraite rend les grands-parents moins disponibles, pas davantage. Mécanisme : **inférence globale** — relier le constat initial à la conséquence finale, contre des distracteurs en inversion.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c001-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c001-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Comment l''auteur se positionne-t-il face aux aides existantes pour les familles monoparentales ?',
   'L''auteur concède : « C''est exact, et il serait injuste de prétendre que rien n''a été fait », avant d''objecter que « ces dispositifs compensent à la marge, quand c''est l''organisation même de la société qui reste pensée pour des couples ». **Sa position : des aides réelles mais marginales face à un problème structurel.** La réponse A invente la suffisance des aides, jamais affirmée dans le texte. La réponse B contredit la concession explicite de l''auteur. La réponse D invente une proposition absente : aucune allocation unique n''est évoquée. Mécanisme : le **mouvement concessif** (on objectera… c''est exact… mais) exprime un jugement nuancé, ni rejet total ni satisfaction.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — familles recomposées (bonne réponse : position 3)
  ('11111111-c001-2100-0000-000000000001', '11111111-c001-1000-0000-000000000001',
   'Les familles recomposées sont devenues majoritaires parmi les foyers français',
   'false', '1'),

  ('11111111-c001-2200-0000-000000000001', '11111111-c001-1000-0000-000000000001',
   'Les beaux-parents devraient remplacer les parents biologiques après une séparation',
   'false', '2'),

  ('11111111-c001-2300-0000-000000000001', '11111111-c001-1000-0000-000000000001',
   'Le droit devrait enfin reconnaître la place réelle des beaux-parents auprès des enfants',
   'true', '3'),

  ('11111111-c001-2400-0000-000000000001', '11111111-c001-1000-0000-000000000001',
   'Les propositions de loi adoptées ont fragilisé l''autorité des parents biologiques',
   'false', '4'),

  -- item 02 — garde d'enfants (bonne réponse : position 1)
  ('11111111-c001-2100-0000-000000000002', '11111111-c001-1000-0000-000000000002',
   'La pénurie de garde tient surtout à la désaffection pour le métier d''assistante maternelle',
   'true', '1'),

  ('11111111-c001-2200-0000-000000000002', '11111111-c001-1000-0000-000000000002',
   'La baisse de la natalité a nettement réduit les difficultés de garde des parents',
   'false', '2'),

  ('11111111-c001-2300-0000-000000000002', '11111111-c001-1000-0000-000000000002',
   'Les crèches collectives assurent l''essentiel de l''accueil des jeunes enfants',
   'false', '3'),

  ('11111111-c001-2400-0000-000000000002', '11111111-c001-1000-0000-000000000002',
   'La moitié des assistantes maternelles ont déjà quitté la profession',
   'false', '4'),

  -- item 03 — aidants familiaux (bonne réponse : position 4)
  ('11111111-c001-2100-0000-000000000003', '11111111-c001-1000-0000-000000000003',
   'Il estime que ces dispositifs découragent les familles d''aider leurs proches',
   'false', '1'),

  ('11111111-c001-2200-0000-000000000003', '11111111-c001-1000-0000-000000000003',
   'Il salue le congé de proche aidant comme une avancée décisive',
   'false', '2'),

  ('11111111-c001-2300-0000-000000000003', '11111111-c001-1000-0000-000000000003',
   'Il considère que l''aide aux proches doit rester une affaire strictement privée',
   'false', '3'),

  ('11111111-c001-2400-0000-000000000003', '11111111-c001-1000-0000-000000000003',
   'Il en reconnaît l''existence mais les juge dérisoires au regard des besoins',
   'true', '4'),

  -- item 04 — parentalité (bonne réponse : position 2)
  ('11111111-c001-2100-0000-000000000004', '11111111-c001-1000-0000-000000000004',
   'Démontrer que la parentalité positive ne repose sur aucun fondement scientifique',
   'false', '1'),

  ('11111111-c001-2200-0000-000000000004', '11111111-c001-1000-0000-000000000004',
   'Dénoncer la culpabilisation des parents sans rejeter les apports des savoirs éducatifs',
   'true', '2'),

  ('11111111-c001-2300-0000-000000000004', '11111111-c001-1000-0000-000000000004',
   'Encourager les parents à consulter davantage de contenus spécialisés',
   'false', '3'),

  ('11111111-c001-2400-0000-000000000004', '11111111-c001-1000-0000-000000000004',
   'Montrer que pères et mères subissent à égalité la pression éducative',
   'false', '4'),

  -- item 05 — fratries (bonne réponse : position 1)
  ('11111111-c001-2100-0000-000000000005', '11111111-c001-1000-0000-000000000005',
   'Le rang de naissance n''a presque aucun effet démontré sur la personnalité',
   'true', '1'),

  ('11111111-c001-2200-0000-000000000005', '11111111-c001-1000-0000-000000000005',
   'Les aînés réussissent nettement mieux que leurs frères et sœurs dans la vie',
   'false', '2'),

  ('11111111-c001-2300-0000-000000000005', '11111111-c001-1000-0000-000000000005',
   'Les recruteurs ont raison de tenir compte du rang de naissance des candidats',
   'false', '3'),

  ('11111111-c001-2400-0000-000000000005', '11111111-c001-1000-0000-000000000005',
   'La taille de la famille détermine fortement la personnalité des enfants',
   'false', '4'),

  -- item 06 — grands-parents (bonne réponse : position 2)
  ('11111111-c001-2100-0000-000000000006', '11111111-c001-1000-0000-000000000006',
   'Les grands-parents refusent désormais massivement de garder leurs petits-enfants',
   'false', '1'),

  ('11111111-c001-2200-0000-000000000006', '11111111-c001-1000-0000-000000000006',
   'L''érosion de la garde assurée par les grands-parents menace l''équilibre de tout le système d''accueil',
   'true', '2'),

  ('11111111-c001-2300-0000-000000000006', '11111111-c001-1000-0000-000000000006',
   'La collectivité finance l''équivalent des gardes assurées par les grands-parents',
   'false', '3'),

  ('11111111-c001-2400-0000-000000000006', '11111111-c001-1000-0000-000000000006',
   'Le recul de l''âge de la retraite rend les grands-parents plus disponibles pour leurs petits-enfants',
   'false', '4'),

  -- item 07 — monoparentalité (bonne réponse : position 3)
  ('11111111-c001-2100-0000-000000000007', '11111111-c001-1000-0000-000000000007',
   'Il les juge suffisantes mais trop mal connues des familles concernées',
   'false', '1'),

  ('11111111-c001-2200-0000-000000000007', '11111111-c001-1000-0000-000000000007',
   'Il affirme que rien n''a jamais été entrepris pour ces familles',
   'false', '2'),

  ('11111111-c001-2300-0000-000000000007', '11111111-c001-1000-0000-000000000007',
   'Il en reconnaît la réalité mais les estime marginales face à un problème structurel',
   'true', '3'),

  ('11111111-c001-2400-0000-000000000007', '11111111-c001-1000-0000-000000000007',
   'Il propose de les remplacer par une allocation unique versée aux mères solos',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c001-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « famille & société », 7 angles tous différents :
--     familles recomposées / garde d'enfants (assistantes maternelles) /
--     aidants familiaux / parentalité positive / fratries (rang de naissance) /
--     rôle des grands-parents / monoparentalité. Aucun thème interdit.
-- [x] Textes B2 longs : 176 / 175 / 193 / 184 / 193 / 189 / 202 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (ex. « léger avantage des aînés », « certes… mais », chiffre 2030).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2, ce_inference_intention ×3,
--     ce_ton_auteur ×2.
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme linguistique
--     nommé (concession, inversion cause/effet, inférence d'intention,
--     détail secondaire, sur-généralisation).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (prénoms, villes, chiffres inventés).
-- ============================================================================
