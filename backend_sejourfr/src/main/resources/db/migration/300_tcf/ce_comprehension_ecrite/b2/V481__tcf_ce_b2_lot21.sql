-- ============================================================================
-- V481 — TCF CE B2 — lot 21 (thème : télétravail)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~195-225 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : flex office & immobilier de bureau, droit à la déconnexion,
-- surveillance logicielle, biais de proximité & carrières, installation hors
-- métropoles, bilan carbone, intégration des jeunes recrues.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c015-4000-0000-000000000001', 'TEXTE',
   'Depuis que le télétravail s''est installé dans les habitudes, les tours de bureaux se vident deux jours par semaine. À Villeurbanne comme à Nanterre, les directions immobilières ont fait leurs comptes : des plateaux occupés à soixante pour cent coûtent une fortune pour rien. Beaucoup d''entreprises ont donc réduit leurs surfaces et basculé vers le « flex office », où plus personne ne possède de bureau attitré.

L''économie est réelle — jusqu''à trente pour cent de loyers en moins pour certaines sociétés —, et il serait absurde de la nier. Mais elle a un coût que les bilans comptables ignorent. Privés de repères, contraints chaque matin de chercher une place libre, nombre de salariés décrivent un sentiment de dépossession : le bureau n''est plus un lieu auquel on appartient, mais un service que l''on consomme. Résultat paradoxal : certains, ne trouvant plus d''intérêt à venir, désertent davantage encore les locaux, ce qui pousse les directions à réduire de nouveau les surfaces.

Le cercle est connu des spécialistes, qui l''appellent la « spirale du plateau vide ». Tant que les entreprises traiteront leurs locaux comme une simple ligne de coûts, elles découvriront, un peu tard, qu''un lieu de travail est aussi ce qui fabrique un collectif.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c015-4000-0000-000000000002', 'TEXTE',
   'À dix-neuf heures, l''ordinateur de Bénédicte est éteint ; à vingt-deux heures, elle répond pourtant à un message « urgent » de sa responsable, depuis le canapé, sur son téléphone personnel. Comme elle, une majorité de télétravailleurs reconnaissent travailler régulièrement en dehors de leurs horaires. Le phénomène n''est pas nouveau, mais le travail à domicile l''a démultiplié : quand le bureau est dans le salon, rien ne signale plus la fin de la journée.

Le droit à la déconnexion existe pourtant dans la loi depuis plusieurs années. Les entreprises sont tenues de négocier des accords sur le sujet, et beaucoup l''ont fait : messageries coupées la nuit, chartes de bonnes pratiques, rappels automatiques. Ces dispositifs ne sont pas inutiles. Ils échouent cependant sur l''essentiel, car la pression ne passe pas par des outils, mais par des attentes implicites : un message lu sans réponse, un collègue qui répond toujours, un manager qui félicite les plus « réactifs ».

Autrement dit, on ne déconnecte pas par décret. Tant que la disponibilité permanente restera, dans les faits, un signe d''engagement valorisé, les salariés continueront de répondre le soir — et les chartes resteront des documents que tout le monde signe et que personne n''applique.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c015-4000-0000-000000000003', 'TEXTE',
   'Captures d''écran aléatoires, mesure des frappes au clavier, voyants de présence scrutés à distance : depuis la généralisation du télétravail, le marché des logiciels de surveillance des salariés a explosé. Les éditeurs parlent pudiquement d''outils de « productivité » ; les syndicats, eux, dénoncent un flicage numérique que le droit encadre pourtant strictement — en France, un contrôle permanent et disproportionné est illégal.

Le plus frappant n''est pas la technologie, mais ce qu''elle révèle. Si tant de directions éprouvent le besoin d''espionner leurs équipes à distance, c''est qu''elles n''ont jamais réellement mesuré le travail autrement que par la présence. Le salarié visible à son poste passait pour productif ; privé de ce repère, le manager se raccroche aux données, fussent-elles absurdes — une souris qui bouge n''a jamais prouvé qu''un cerveau réfléchit.

Des études convergentes montrent d''ailleurs que cette surveillance produit l''inverse du but recherché : les salariés épiés développent des stratégies de contournement, simulent l''activité et s''épuisent à paraître occupés au lieu de l''être. La confiance, elle, ne se décrète pas, mais elle se mesure : les équipes évaluées sur leurs résultats plutôt que sur leurs horaires affichent partout de meilleures performances. Le télétravail n''a pas créé le management par la défiance ; il l''a simplement rendu visible.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c015-4000-0000-000000000004', 'TEXTE',
   'Deux collègues aux résultats identiques, l''un présent au bureau quatre jours par semaine, l''autre presque toujours à distance : lequel sera promu ? Une enquête menée par le cabinet lyonnais Artemia auprès de mille deux cents cadres apporte une réponse dérangeante : à performance égale, les salariés majoritairement présents ont près de deux fois plus de chances d''obtenir une promotion dans les deux ans. Les chercheurs nomment ce phénomène le « biais de proximité » : on confie les dossiers stratégiques à ceux que l''on croise, on pense aux absents après les autres.

Rien, dans ces décisions, ne relève d''une volonté délibérée d''écarter les télétravailleurs. C''est précisément ce qui rend le mécanisme difficile à combattre : il opère à l''insu de ceux qui le pratiquent, persuadés de ne juger que les résultats.

Les conséquences dépassent la carrière de chacun. Comme les femmes, et en particulier les mères, recourent davantage au travail à distance, le biais de proximité risque de recréer en silence des écarts que des années de politiques d''égalité avaient commencé à réduire. Certaines entreprises l''ont compris, qui forment leurs managers ou imposent des critères de promotion objectivés. Les autres découvriront un jour que leur politique de flexibilité, si généreuse sur le papier, a fabriqué une salle des promus où ne siègent que les présents.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c015-4000-0000-000000000005', 'TEXTE',
   '« Tous à la campagne ! » : au plus fort de la vague du télétravail, les magazines promettaient un exode massif des cadres parisiens vers les villes moyennes. Cinq ans plus tard, les données de l''observatoire Territoires et Mobilités permettent de solder ce récit. Oui, des départs ont eu lieu : Angoulême, Vannes ou Mulhouse ont vu arriver des télétravailleurs en nombre mesurable. Mais l''ampleur du mouvement a été considérablement exagérée : il concerne à peine quelques pour cent des actifs concernés, et la majorité des partants se sont installés à moins d''une heure de leur métropole d''origine, pour pouvoir s''y rendre deux jours par semaine.

L''exode rural inversé tient donc davantage du déplacement de banlieue élargie que de la révolution géographique. Ce constat n''enlève rien aux effets bien réels sur les villes d''accueil : prix de l''immobilier en hausse rapide, tension sur les écoles, mais aussi cafés rouverts et associations rajeunies. Des effets puissants localement, précisément parce qu''ils se concentrent sur peu de territoires.

La leçon vaut d''être retenue : le télétravail ne redessine pas la carte de la France, il en accentue certains traits. Les politiques d''aménagement qui tablent sur une dispersion spontanée des actifs risquent d''attendre longtemps.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c015-4000-0000-000000000006', 'TEXTE',
   'Moins de trajets domicile-travail, donc moins d''émissions : à première vue, le télétravail semble un allié évident du climat. Le raisonnement, répété à l''envi, mérite pourtant d''être passé au crible. C''est ce qu''a fait une équipe de l''École des Ponts en reconstituant le bilan carbone complet de quatre mille télétravailleurs. Conclusion : le gain existe, mais il est deux à trois fois plus faible que ne le suggère le simple calcul des kilomètres évités.

En cause, une série d''effets rebond que l''intuition néglige. Le logement, d''abord : chauffer toute la journée un appartement occupé, parfois une pièce supplémentaire aménagée en bureau, annule une partie des économies de transport. Les déplacements, ensuite : libérés de la contrainte du bureau, beaucoup de télétravailleurs s''installent plus loin de leur entreprise, si bien que leurs trajets, moins fréquents, sont nettement plus longs — et plus souvent en voiture, faute de transports en commun adaptés. S''ajoutent enfin les déplacements privés qui remplacent les trajets professionnels supprimés.

Faut-il en conclure que le télétravail est écologiquement neutre, voire nuisible ? Non : le bilan reste positif dans la plupart des configurations. Mais il dépend étroitement des choix de logement et de mobilité de chacun. Présenter le travail à distance comme une politique climatique en soi relève donc du raccourci : c''est un levier modeste, qui n''exonère ni des transports collectifs ni de la rénovation des logements.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c015-4000-0000-000000000007', 'TEXTE',
   'Recrutée en janvier par une société de conseil bordelaise, Inès, vingt-quatre ans, n''a rencontré son équipe au complet qu''au bout de trois mois. Entre-temps, elle a appris son métier par visioconférence, posé ses questions par messagerie en s''excusant de déranger, et déjeuné seule devant son écran. Son cas n''a rien d''exceptionnel : toutes les enquêtes le confirment, les jeunes recrues sont les grandes perdantes du travail à distance.

L''explication est simple : on n''apprend pas un métier uniquement dans les documents. On l''apprend en écoutant un collègue négocier au téléphone, en surprenant une conversation de couloir, en osant une question idiote à la machine à café. Ces mille apprentissages informels, invisibles dans les organigrammes, disparaissent à distance. Les salariés expérimentés s''en passent sans dommage — leur réseau et leurs réflexes sont déjà construits ; les débutants, eux, en sont privés au moment précis où ils en auraient le plus besoin.

Faut-il pour autant imposer le présentiel aux nouveaux venus, comme le font certaines entreprises ? La piste a sa logique, mais elle oublie un détail : un débutant présent dans des locaux vides n''apprend rien de plus. C''est la présence simultanée des anciens et des nouveaux qui transmet le métier. Le vrai sujet n''est donc pas le retour au bureau, mais son organisation.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c015-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c015-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale défendue par l''auteur ?',
   'La conclusion du texte porte la thèse : « un lieu de travail est aussi ce qui fabrique un collectif », que les entreprises oublient en traitant leurs locaux « comme une simple ligne de coûts ». **L''idée principale est que la réduction comptable des bureaux finit par fragiliser le collectif de travail.** La réponse A contredit un détail explicite : « L''économie est réelle », l''auteur refuse justement de la nier. La réponse C promeut un **détail vrai mais secondaire** (les trente pour cent d''économies) au rang d''idée principale. La réponse D inverse l''intention : le bureau devenu « un service que l''on consomme » est précisément ce que l''auteur déplore, pas ce qu''il recommande. Mécanisme testé : distinguer la **thèse conclusive** des données concédées en cours d''argumentation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c015-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c015-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur à l''égard des dispositifs de déconnexion mis en place par les entreprises ?',
   'L''auteur concède que « ces dispositifs ne sont pas inutiles » avant de retourner le propos : « Ils échouent cependant sur l''essentiel, car la pression ne passe pas par des outils, mais par des attentes implicites ». **Sa position : des dispositifs réels mais impuissants face à une norme implicite de disponibilité.** La réponse A contredit un fait explicite : « beaucoup l''ont fait », les accords existent bel et bien. La réponse B inverse le jugement : couper les messageries fait partie des outils qui « échouent sur l''essentiel ». La réponse D invente une proposition absente : l''auteur ne demande jamais la suppression du droit à la déconnexion. Mécanisme : repérer la **concession rhétorique** (pas inutiles… cependant) qui annonce une critique, non une approbation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c015-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c015-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Quelle est l''intention principale de l''auteur de ce texte ?',
   'Le texte affirme que « le plus frappant n''est pas la technologie, mais ce qu''elle révèle » et que la surveillance « produit l''inverse du but recherché » : **l''intention est de montrer que ces logiciels trahissent un management par la défiance et se retournent contre leur objectif**. La réponse B inverse les faits : les équipes les plus performantes sont celles évaluées sur leurs résultats, pas les équipes épiées. La réponse C est une **sur-généralisation** du détail juridique : seul un contrôle « permanent et disproportionné » est illégal, pas toute surveillance. La réponse D inverse la chute du texte : le télétravail « n''a pas créé le management par la défiance ; il l''a simplement rendu visible ». Mécanisme : **inférence d''intention** — dégager la visée critique derrière un constat factuel.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c015-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c015-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'L''enquête citée établit qu''« à performance égale, les salariés majoritairement présents ont près de deux fois plus de chances d''obtenir une promotion » : **l''idée principale est que la présence physique favorise les carrières au détriment des télétravailleurs, sans intention délibérée**. La réponse A contredit un passage explicite : « Rien, dans ces décisions, ne relève d''une volonté délibérée » — le biais opère à l''insu de ceux qui le pratiquent. La réponse B inverse un détail : les femmes « recourent davantage au travail à distance », elles ne télétravaillent pas moins. La réponse D est une **sur-généralisation** : seules « certaines entreprises » ont objectivé leurs critères, pas la plupart. Mécanisme : résister à l''**inversion de détail** et à la sur-généralisation pour retrouver la synthèse exacte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c015-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c015-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Que cherche à montrer l''auteur de ce texte ?',
   'Le texte « solde » le récit médiatique : « l''ampleur du mouvement a été considérablement exagérée », tout en reconnaissant des « effets bien réels » concentrés sur peu de territoires. **La bonne réponse articule les deux volets : un mouvement limité, mais des effets locaux réels.** La réponse A reprend la **sur-généralisation** que le texte démonte précisément : l''« exode massif » est le mythe des magazines. La réponse C contredit le deuxième paragraphe : immobilier en hausse, écoles sous tension, cafés rouverts — les effets existent. La réponse D inverse un détail-piège : les partants se sont installés « à moins d''une heure de leur métropole » pour continuer à s''y rendre deux jours par semaine. Mécanisme : **inférence globale** — relier la thèse nuancée contre un distracteur reprenant le cliché réfuté.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c015-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c015-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Comment l''auteur se positionne-t-il sur le bilan écologique du télétravail ?',
   'L''auteur répond explicitement à sa propre question : « Non : le bilan reste positif dans la plupart des configurations », tout en montrant qu''il est « deux à trois fois plus faible » qu''annoncé à cause des effets rebond. **Sa position : un gain réel mais nettement plus modeste que le discours courant.** La réponse A sur-étend la critique jusqu''à l''**inversion** : le texte exclut précisément la conclusion d''un télétravail nuisible. La réponse B reprend le raisonnement initial que l''auteur « passe au crible » et relativise. La réponse C transforme un **détail vrai mais secondaire** (le chauffage du logement, cité comme effet rebond) en reproche moral inventé. Mécanisme : le **mouvement concessif** (question rhétorique… Non… Mais) exprime un jugement nuancé, ni enthousiasme ni rejet.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c015-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c015-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Quelle conclusion l''auteur tire-t-il des difficultés des jeunes recrues en télétravail ?',
   'La chute du texte est explicite : « Le vrai sujet n''est donc pas le retour au bureau, mais son organisation », car seule « la présence simultanée des anciens et des nouveaux » transmet le métier. **La conclusion porte sur l''organisation de la présence commune, pas sur le présentiel en soi.** La réponse B promeut un **détail vrai mais secondaire** : imposer le présentiel aux nouveaux est une piste évoquée puis jugée insuffisante (« un débutant présent dans des locaux vides n''apprend rien de plus »). La réponse C contredit le texte : les expérimentés « s''en passent sans dommage ». La réponse D inverse l''argument central : on n''apprend justement pas un métier « uniquement dans les documents ». Mécanisme : **inférence de conséquence** — identifier la conclusion nuancée au-delà de la solution intermédiaire écartée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — flex office & immobilier de bureau (bonne réponse : position 2)
  ('11111111-c015-2100-0000-000000000001', '11111111-c015-1000-0000-000000000001',
   'Les économies promises par le flex office se révèlent en réalité inexistantes',
   'false', '1'),

  ('11111111-c015-2200-0000-000000000001', '11111111-c015-1000-0000-000000000001',
   'Réduire les bureaux à une simple ligne de coûts finit par fragiliser le collectif de travail',
   'true', '2'),

  ('11111111-c015-2300-0000-000000000001', '11111111-c015-1000-0000-000000000001',
   'Le flex office permet aux entreprises d''économiser jusqu''à trente pour cent de loyers',
   'false', '3'),

  ('11111111-c015-2400-0000-000000000001', '11111111-c015-1000-0000-000000000001',
   'Les salariés doivent apprendre à considérer le bureau comme un service que l''on consomme',
   'false', '4'),

  -- item 02 — droit à la déconnexion (bonne réponse : position 4)
  ('11111111-c015-2100-0000-000000000002', '11111111-c015-1000-0000-000000000002',
   'Il estime que les entreprises refusent de négocier des accords sur la déconnexion',
   'false', '1'),

  ('11111111-c015-2200-0000-000000000002', '11111111-c015-1000-0000-000000000002',
   'Il considère que couper les messageries la nuit suffit à protéger les salariés',
   'false', '2'),

  ('11111111-c015-2300-0000-000000000002', '11111111-c015-1000-0000-000000000002',
   'Il propose de supprimer un droit à la déconnexion selon lui inapplicable',
   'false', '3'),

  ('11111111-c015-2400-0000-000000000002', '11111111-c015-1000-0000-000000000002',
   'Il les juge réels mais impuissants face aux attentes implicites de disponibilité',
   'true', '4'),

  -- item 03 — surveillance logicielle (bonne réponse : position 1)
  ('11111111-c015-2100-0000-000000000003', '11111111-c015-1000-0000-000000000003',
   'Montrer que la surveillance à distance révèle un management par la défiance et se retourne contre son but',
   'true', '1'),

  ('11111111-c015-2200-0000-000000000003', '11111111-c015-1000-0000-000000000003',
   'Démontrer que les logiciels de surveillance améliorent la productivité des équipes',
   'false', '2'),

  ('11111111-c015-2300-0000-000000000003', '11111111-c015-1000-0000-000000000003',
   'Rappeler que toute surveillance des salariés est interdite par le droit français',
   'false', '3'),

  ('11111111-c015-2400-0000-000000000003', '11111111-c015-1000-0000-000000000003',
   'Prouver que le télétravail a fait naître le management fondé sur le contrôle',
   'false', '4'),

  -- item 04 — biais de proximité & carrières (bonne réponse : position 3)
  ('11111111-c015-2100-0000-000000000004', '11111111-c015-1000-0000-000000000004',
   'Les managers écartent volontairement les télétravailleurs des promotions',
   'false', '1'),

  ('11111111-c015-2200-0000-000000000004', '11111111-c015-1000-0000-000000000004',
   'Les femmes télétravaillent moins que les hommes, ce qui freine leur carrière',
   'false', '2'),

  ('11111111-c015-2300-0000-000000000004', '11111111-c015-1000-0000-000000000004',
   'À résultats égaux, la présence au bureau favorise les promotions, à l''insu même des décideurs',
   'true', '3'),

  ('11111111-c015-2400-0000-000000000004', '11111111-c015-1000-0000-000000000004',
   'La plupart des entreprises ont déjà objectivé leurs critères de promotion',
   'false', '4'),

  -- item 05 — installation hors métropoles (bonne réponse : position 2)
  ('11111111-c015-2100-0000-000000000005', '11111111-c015-1000-0000-000000000005',
   'Que les villes moyennes ont accueilli un exode massif de cadres venus des métropoles',
   'false', '1'),

  ('11111111-c015-2200-0000-000000000005', '11111111-c015-1000-0000-000000000005',
   'Que les installations de télétravailleurs hors des métropoles restent limitées, malgré des effets locaux bien réels',
   'true', '2'),

  ('11111111-c015-2300-0000-000000000005', '11111111-c015-1000-0000-000000000005',
   'Que l''arrivée des télétravailleurs n''a eu aucun effet sur les villes d''accueil',
   'false', '3'),

  ('11111111-c015-2400-0000-000000000005', '11111111-c015-1000-0000-000000000005',
   'Que les partants se sont installés loin de leur métropole pour ne plus jamais y retourner',
   'false', '4'),

  -- item 06 — bilan carbone (bonne réponse : position 4)
  ('11111111-c015-2100-0000-000000000006', '11111111-c015-1000-0000-000000000006',
   'Il démontre que le télétravail est finalement nuisible pour le climat',
   'false', '1'),

  ('11111111-c015-2200-0000-000000000006', '11111111-c015-1000-0000-000000000006',
   'Il confirme que la suppression des trajets garantit un gain climatique majeur',
   'false', '2'),

  ('11111111-c015-2300-0000-000000000006', '11111111-c015-1000-0000-000000000006',
   'Il reproche aux télétravailleurs de chauffer inutilement leur logement la journée',
   'false', '3'),

  ('11111111-c015-2400-0000-000000000006', '11111111-c015-1000-0000-000000000006',
   'Il le juge positif mais bien plus modeste qu''annoncé, en raison d''effets rebond',
   'true', '4'),

  -- item 07 — intégration des jeunes recrues (bonne réponse : position 1)
  ('11111111-c015-2100-0000-000000000007', '11111111-c015-1000-0000-000000000007',
   'L''enjeu n''est pas le retour au bureau en soi, mais l''organisation de la présence commune des anciens et des débutants',
   'true', '1'),

  ('11111111-c015-2200-0000-000000000007', '11111111-c015-1000-0000-000000000007',
   'Il faut imposer le présentiel à tous les nouveaux salariés dès l''embauche',
   'false', '2'),

  ('11111111-c015-2300-0000-000000000007', '11111111-c015-1000-0000-000000000007',
   'Les salariés expérimentés souffrent autant que les débutants du travail à distance',
   'false', '3'),

  ('11111111-c015-2400-0000-000000000007', '11111111-c015-1000-0000-000000000007',
   'Les jeunes recrues apprennent leur métier essentiellement dans les documents internes',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c015-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « télétravail », 7 angles tous différents :
--     flex office & immobilier de bureau / droit à la déconnexion /
--     surveillance logicielle / biais de proximité & carrières /
--     installation hors métropoles / bilan carbone & effets rebond /
--     intégration des jeunes recrues. Aucun thème interdit traité pour
--     lui-même (le télétravail est le sujet imposé du lot).
-- [x] Textes B2 longs : 199 / 196 / 203 / 209 / 196 / 222 / 208 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (ex. « l''économie est réelle », « beaucoup l''ont fait », contrôle
--     « permanent et disproportionné », « à moins d''une heure », « Non : le
--     bilan reste positif », piste du présentiel écartée).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2 (items 1, 4),
--     ce_inference_intention ×3 (items 3, 5, 7), ce_ton_auteur ×2 (items 2, 6).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme linguistique
--     nommé (concession rhétorique, inversion cause/effet, sur-généralisation,
--     détail vrai mais secondaire, inférence d''intention/conséquence).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (prénoms — Bénédicte, Inès —,
--     villes, cabinets et chiffres inventés).
-- ============================================================================
