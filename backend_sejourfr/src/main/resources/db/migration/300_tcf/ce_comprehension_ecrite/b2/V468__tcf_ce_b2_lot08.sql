-- ============================================================================
-- V468 — TCF CE B2 — lot 08 (thème : culture & médias)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~195-215 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : librairies indépendantes, salles de cinéma face au streaming,
-- défiance envers les journalistes, gratuité des musées, algorithmes de
-- recommandation musicale, reconnaissance de la bande dessinée,
-- économie des festivals d'été.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c008-4000-0000-000000000001', 'TEXTE',
   'On annonçait leur disparition pour la décennie passée ; elles sont toujours là. Les librairies indépendantes françaises, que la vente en ligne devait balayer, affichent un réseau parmi les plus denses du monde : plus de trois mille points de vente, et des ouvertures qui dépassent les fermetures depuis cinq ans.

Le miracle n''en est pas un. Il repose d''abord sur une digue législative posée il y a plus de quarante ans : le prix unique du livre, qui interdit aux géants de la distribution de casser les prix. Privé de l''argument du rabais, le client choisit sa librairie pour autre chose — un conseil, une table de nouveautés qui ne doit rien à un algorithme, une rencontre avec un auteur le jeudi soir.

Faut-il pour autant céder au triomphalisme ? Ce serait oublier la fragilité du modèle : des marges parmi les plus faibles du commerce, des loyers de centre-ville qui flambent, des libraires payés à peine au-dessus du minimum légal malgré un niveau d''études élevé. La librairie ne survit pas parce qu''elle est rentable, mais parce que des passionnés acceptent de l''être à sa place. Une politique culturelle digne de ce nom ne peut pas s''en remettre éternellement au dévouement.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c008-4000-0000-000000000002', 'TEXTE',
   'À en croire les prophètes du tout-écran, les salles de cinéma auraient dû fermer les unes après les autres, achevées par les plateformes de vidéo à la demande. Or les chiffres racontent une autre histoire : la fréquentation des salles françaises est revenue à son niveau d''avant la crise sanitaire, autour de cent quatre-vingts millions d''entrées par an, là où plusieurs voisins européens stagnent très en dessous.

Cette exception ne doit rien au hasard. Elle tient à un maillage unique de plus de deux mille cinémas, dont une moitié de salles classées art et essai, soutenues par des aides publiques et des collectivités locales. Elle tient aussi à la chronologie des médias, ce dispositif réglementaire qui impose aux plateformes d''attendre de longs mois avant de diffuser un film sorti en salle : critiqué à l''étranger, ce verrou garantit aux exploitants une exclusivité précieuse.

Reste une ombre au tableau, que les moyennes nationales dissimulent : le public des salles vieillit, et les moins de vingt-cinq ans, biberonnés aux séries, n''y reviennent qu''en cas d''événement planétaire. La salle de cinéma n''est pas morte ; mais si elle ne reconquiert pas la jeunesse, elle vivra de plus en plus comme les théâtres — respectée, subventionnée, et désertée par ceux qui feront la culture de demain.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c008-4000-0000-000000000003', 'TEXTE',
   'Année après année, les baromètres le confirment : à peine un Français sur trois déclare faire confiance aux journalistes. Le constat nourrit deux discours symétriques, aussi paresseux l''un que l''autre. Le premier accuse le public, jugé crédule, incapable de distinguer une enquête sourcée d''une rumeur virale. Le second accable la profession tout entière, vendue aux puissants, coupable de tous les renoncements.

La réalité mérite mieux que ces caricatures. Oui, la concentration des médias entre les mains de quelques grands groupes industriels alimente un soupçon légitime ; oui, la course au clic a poussé des rédactions à sacrifier la vérification à la rapidité. Mais réduire le journalisme à ces dérives, c''est effacer le travail patient de milliers de reporters, de fact-checkeurs et de correspondants locaux qui font exister une information vérifiée — souvent pour des salaires modestes et dans des conditions de plus en plus hostiles.

La défiance n''est d''ailleurs pas une fatalité : les études montrent que les citoyens formés à l''éducation aux médias, dès le collège, identifient mieux les sources fiables et accordent à celles-ci une confiance accrue. Plutôt que de gémir sur la crédulité supposée du public ou la trahison supposée des journalistes, il serait temps d''investir massivement dans cette formation. C''est moins spectaculaire qu''un procès ; c''est infiniment plus utile.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c008-4000-0000-000000000004', 'TEXTE',
   'Depuis quinze ans, les musées nationaux ouvrent gratuitement leurs portes le premier dimanche du mois. La mesure, présentée à l''origine comme un levier de démocratisation culturelle, fait figure d''acquis : qui oserait rétablir un billet d''entrée ce jour-là ? Les bilans dressés par les chercheurs invitent pourtant à regarder le dispositif avec moins de complaisance.

Premier enseignement : la gratuité remplit les salles, sans grand mystère. La fréquentation de ces dimanches dépasse de moitié celle d''un dimanche ordinaire. Second enseignement, plus dérangeant : les visiteurs supplémentaires ressemblent trait pour trait aux visiteurs habituels — diplômés, urbains, déjà familiers des lieux. Les publics que la mesure prétendait conquérir, eux, ne franchissent pas davantage les portes. Le prix du billet n''a jamais été le principal obstacle ; le sentiment que « ce n''est pas un endroit pour soi » pèse bien plus lourd que dix euros.

Faut-il en conclure que la gratuité est inutile ? Ce serait excessif : offrir une visite de plus à ceux qui aiment déjà les musées n''a rien d''un scandale. Mais s''en contenter revient à confondre l''affluence avec la démocratisation. Tant que l''école, les associations et les musées eux-mêmes n''iront pas chercher les publics éloignés — par l''accompagnement, la médiation, les horaires adaptés —, le premier dimanche du mois restera une fête pour initiés.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c008-4000-0000-000000000005', 'TEXTE',
   'Jamais l''humanité n''a eu accès à autant de musique : cent millions de titres tiennent désormais dans une poche, pour le prix d''une place de concert par mois. À ce festin sans précédent, les plateformes d''écoute ont ajouté un maître d''hôtel : l''algorithme de recommandation, censé guider chacun vers des découvertes taillées sur mesure.

Le résultat tient du paradoxe. Plusieurs travaux récents, dont une étude menée à Montréal sur les habitudes de quarante mille auditeurs, montrent que plus une personne s''en remet aux playlists automatiques, plus son univers musical se rétrécit. La machine, payée pour retenir l''attention, mise sur le confort : elle ressert ce qui a déjà plu, elle arrondit les angles, elle évite les surprises qui font fuir. À l''échelle d''une vie d''auditeur, cette douceur produit un appauvrissement ; à l''échelle du marché, elle concentre les écoutes sur une poignée de titres calibrés, pendant que la production indépendante devient invisible.

Rien n''oblige pourtant à subir. Les mêmes plateformes permettent de chercher un disque par soi-même, de suivre un label, d''écouter une radio animée par des humains. La curiosité musicale n''est pas morte ; elle demande simplement, comme avant, un petit effort. La vraie question n''est pas de savoir ce que l''algorithme nous propose, mais ce que nous renonçons à chercher quand nous le laissons choisir.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c008-4000-0000-000000000006', 'TEXTE',
   'Longtemps reléguée au rayon des lectures d''enfance, la bande dessinée a conquis ses lettres de noblesse : un fauteuil à l''Académie des beaux-arts, des expositions dans les plus grands musées, des romans graphiques recensés dans les pages littéraires des journaux. Le « neuvième art » serait donc enfin reconnu. Permettez-nous de nuancer l''enthousiasme général.

Car cette consécration ressemble fort à une politesse de façade. Pendant que les institutions célèbrent quelques auteurs devenus des classiques, la profession, elle, s''enfonce : selon les états généraux du secteur, plus de la moitié des autrices et auteurs de bande dessinée vivent sous le seuil de pauvreté, alors même que le marché ne s''est jamais aussi bien porté — un album vendu sur quatre en librairie est une bande dessinée. L''essentiel de la valeur part ailleurs : vers l''édition, la distribution, et désormais les adaptations en série ou en film.

On nous objectera que la misère de l''artiste ne date pas d''hier, et qu''aucun secteur culturel n''y échappe tout à fait. Sans doute. Mais il y a quelque chose d''indécent à inaugurer des expositions pendant que ceux qui produisent l''œuvre renoncent à en vivre. Une reconnaissance qui ne ruisselle jamais jusqu''aux ateliers n''est pas un hommage : c''est une vitrine. Le neuvième art n''a plus besoin de compliments ; il a besoin de contrats équitables.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c008-4000-0000-000000000007', 'TEXTE',
   'On en recense désormais plus de sept mille chaque été : la France est devenue le pays des festivals. Musique, théâtre de rue, photographie, cinéma en plein air — pas une sous-préfecture sans son rendez-vous estival, pas un village sans sa scène montée sur la place. Cette vitalité, réelle, fait la fierté des élus locaux, qui y voient à la fois une animation pour les habitants et une carte de visite pour le territoire.

Derrière la photographie souriante, les organisateurs décrivent pourtant une équation de plus en plus intenable. Les cachets des têtes d''affiche ont doublé en dix ans, tirés vers le haut par la concurrence internationale ; les normes de sécurité, indispensables mais coûteuses, alourdissent chaque édition ; les subventions publiques, elles, se replient. Résultat : plusieurs manifestations historiques ont jeté l''éponge l''an dernier, non par manque de public, mais par impossibilité de boucler un budget.

Le plus préoccupant n''est pas la disparition de tel ou tel événement — il en naîtra d''autres. C''est la logique qui s''installe : seuls les mastodontes adossés à de grands groupes privés résistent, pendant que les festivals indépendants, ceux qui prennent des risques artistiques et font émerger les artistes de demain, ferment les uns après les autres. À ce rythme, l''été culturel français restera animé, mais il aura partout le même visage.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c008-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c008-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'L''auteur refuse de « céder au triomphalisme » et conclut qu''une politique culturelle « ne peut pas s''en remettre éternellement au dévouement » : **l''idée principale est la fragilité d''une survie qui repose sur le prix unique du livre et le sacrifice des libraires**. La réponse A reprend précisément le triomphalisme que l''auteur écarte (sur-généralisation : les librairies résistent, elles n''ont pas « gagné »). La réponse C inverse les faits : les marges sont « parmi les plus faibles du commerce » et la librairie « ne survit pas parce qu''elle est rentable ». La réponse D promeut un **détail vrai mais secondaire** (les rencontres du jeudi soir) au rang d''idée centrale. Mécanisme : distinguer la thèse globale des exemples qui l''illustrent.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c008-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c008-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur les salles de cinéma françaises ?',
   'Le texte oppose des chiffres rassurants (fréquentation revenue à cent quatre-vingts millions d''entrées) à une « ombre au tableau » : **la bonne santé apparente des salles masque un vieillissement du public qui menace leur avenir**. La réponse A contredit le constat d''ouverture : les salles n''ont justement pas fermé, « les chiffres racontent une autre histoire ». La réponse B inverse l''effet du dispositif : la chronologie des médias « garantit aux exploitants une exclusivité précieuse », elle les protège. La réponse C est une sur-généralisation du détail-piège : les jeunes reviennent « en cas d''événement planétaire », ils n''ont pas totalement cessé d''y aller. Mécanisme : **inférence globale** — relier le constat chiffré à la réserve finale introduite par « Reste une ombre au tableau ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c008-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c008-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Comment l''auteur se positionne-t-il face à la défiance envers les journalistes ?',
   'L''auteur qualifie de « paresseux » les deux discours symétriques et conclut qu''il faut « investir massivement » dans l''éducation aux médias : **il renvoie dos à dos les procès faits au public et à la profession, et défend une troisième voie, la formation**. La réponse B reprend le second discours qu''il rejette comme une « caricature » (la profession « tout entière » trahie). La réponse C reprend le premier discours, tout aussi caricatural à ses yeux. La réponse D contredit la double concession explicite (« Oui, la concentration… ; oui, la course au clic… ») : il reconnaît les dérives, il refuse seulement d''y « réduire le journalisme ». Mécanisme : repérer la **concession rhétorique** (oui… oui… mais) qui distingue nuance et rejet.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c008-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c008-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur la gratuité des musées le premier dimanche du mois ?',
   'Le texte distingue deux enseignements : la gratuité « remplit les salles », mais les visiteurs supplémentaires « ressemblent trait pour trait aux visiteurs habituels ». **La bonne réponse synthétise ce double constat : plus d''affluence, mais pas les publics visés.** La réponse A inverse la conclusion : s''en contenter « revient à confondre l''affluence avec la démocratisation ». La réponse B contredit le détail-piège explicite : « le prix du billet n''a jamais été le principal obstacle », c''est le sentiment d''illégitimité qui pèse. La réponse D sur-étend le propos : à la question « Faut-il en conclure que la gratuité est inutile ? », le texte répond « Ce serait excessif » — personne ne recommande sa suppression. Mécanisme : résister à la **sur-généralisation** d''un bilan nuancé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c008-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c008-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale défendue par l''auteur ?',
   'Le texte montre que « plus une personne s''en remet aux playlists automatiques, plus son univers musical se rétrécit », puis rappelle que « rien n''oblige pourtant à subir » : **l''idée principale articule l''appauvrissement algorithmique et la découverte toujours possible pour qui fait l''effort de chercher**. La réponse A inverse le paradoxe central : l''abondance n''a pas élargi les goûts, la délégation à la machine les rétrécit. La réponse C est une sur-généralisation : l''auteur souligne que « les mêmes plateformes permettent » de chercher autrement, il n''appelle à aucun rejet. La réponse D déforme un détail : la production indépendante « devient invisible » dans les recommandations, elle n''a pas disparu des catalogues. Mécanisme : reconstruire une **thèse en deux temps** (constat critique + voie de sortie), contre des distracteurs en inversion.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c008-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c008-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Quel est le ton adopté par l''auteur à propos de la reconnaissance de la bande dessinée ?',
   'Dès « Permettez-nous de nuancer l''enthousiasme général », puis avec « il y a quelque chose d''indécent », l''auteur dénonce une « politesse de façade » : **le ton est indigné, contre une consécration qui ne bénéficie pas à ceux qui créent**. La réponse A inverse le ton : les honneurs énumérés en ouverture servent de repoussoir, pas de motif de célébration. La réponse B reprend l''objection que l''auteur concède (« Sans doute ») avant de la retourner par « Mais » — il refuse précisément la résignation. La réponse C contredit la dimension polémique du texte : les chiffres (moitié des auteurs sous le seuil de pauvreté, un album sur quatre) sont mobilisés au service d''une accusation, pas d''un constat neutre. Mécanisme : identifier le **ton de l''auteur** derrière une concession rhétorique (sans doute… mais).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c008-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c008-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Que cherche à montrer l''auteur de ce texte ?',
   'Le texte conclut que si « seuls les mastodontes » résistent pendant que les festivals indépendants ferment, « l''été culturel français restera animé, mais il aura partout le même visage » : **l''auteur montre que la fragilité économique des festivals indépendants menace la diversité culturelle, pas l''animation elle-même**. La réponse B inverse la cause explicite : les manifestations ont fermé « non par manque de public, mais par impossibilité de boucler un budget ». La réponse C déforme un détail : les normes de sécurité sont qualifiées d''« indispensables », aucun allègement n''est suggéré. La réponse D contredit les faits : plus de sept mille festivals sont recensés et « il en naîtra d''autres » — c''est leur uniformisation qui inquiète, pas leur nombre. Mécanisme : **inférence d''intention** — dégager la conséquence implicite (uniformisation) derrière les constats économiques.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — librairies indépendantes (bonne réponse : position 2)
  ('11111111-c008-2100-0000-000000000001', '11111111-c008-1000-0000-000000000001',
   'Les librairies indépendantes ont définitivement gagné leur bataille contre la vente en ligne',
   'false', '1'),

  ('11111111-c008-2200-0000-000000000001', '11111111-c008-1000-0000-000000000001',
   'La survie des librairies repose sur un équilibre fragile que la politique culturelle ne peut pas tenir pour acquis',
   'true', '2'),

  ('11111111-c008-2300-0000-000000000001', '11111111-c008-1000-0000-000000000001',
   'Le prix unique du livre a rendu les librairies particulièrement rentables',
   'false', '3'),

  ('11111111-c008-2400-0000-000000000001', '11111111-c008-1000-0000-000000000001',
   'Les rencontres avec des auteurs sont le principal attrait des librairies de quartier',
   'false', '4'),

  -- item 02 — salles de cinéma (bonne réponse : position 4)
  ('11111111-c008-2100-0000-000000000002', '11111111-c008-1000-0000-000000000002',
   'Les plateformes de vidéo à la demande ont fait fermer la plupart des salles françaises',
   'false', '1'),

  ('11111111-c008-2200-0000-000000000002', '11111111-c008-1000-0000-000000000002',
   'La chronologie des médias pénalise les exploitants de salles face aux plateformes',
   'false', '2'),

  ('11111111-c008-2300-0000-000000000002', '11111111-c008-1000-0000-000000000002',
   'Les moins de vingt-cinq ans ont totalement cessé d''aller au cinéma',
   'false', '3'),

  ('11111111-c008-2400-0000-000000000002', '11111111-c008-1000-0000-000000000002',
   'La bonne santé des salles masque un vieillissement du public qui hypothèque leur avenir',
   'true', '4'),

  -- item 03 — défiance envers les journalistes (bonne réponse : position 1)
  ('11111111-c008-2100-0000-000000000003', '11111111-c008-1000-0000-000000000003',
   'Il renvoie dos à dos les procès faits au public et à la profession, et plaide pour l''éducation aux médias',
   'true', '1'),

  ('11111111-c008-2200-0000-000000000003', '11111111-c008-1000-0000-000000000003',
   'Il estime que la profession tout entière a trahi la confiance du public',
   'false', '2'),

  ('11111111-c008-2300-0000-000000000003', '11111111-c008-1000-0000-000000000003',
   'Il juge le public trop crédule pour distinguer une enquête sérieuse d''une rumeur',
   'false', '3'),

  ('11111111-c008-2400-0000-000000000003', '11111111-c008-1000-0000-000000000003',
   'Il nie l''existence de dérives dans les rédactions françaises',
   'false', '4'),

  -- item 04 — gratuité des musées (bonne réponse : position 3)
  ('11111111-c008-2100-0000-000000000004', '11111111-c008-1000-0000-000000000004',
   'La gratuité du premier dimanche a permis de démocratiser l''accès aux musées',
   'false', '1'),

  ('11111111-c008-2200-0000-000000000004', '11111111-c008-1000-0000-000000000004',
   'Le prix du billet reste le principal obstacle à la visite des musées',
   'false', '2'),

  ('11111111-c008-2300-0000-000000000004', '11111111-c008-1000-0000-000000000004',
   'La gratuité augmente l''affluence sans atteindre les publics qu''elle prétendait conquérir',
   'true', '3'),

  ('11111111-c008-2400-0000-000000000004', '11111111-c008-1000-0000-000000000004',
   'Les chercheurs recommandent de supprimer la gratuité, jugée inutile',
   'false', '4'),

  -- item 05 — algorithmes de recommandation musicale (bonne réponse : position 2)
  ('11111111-c008-2100-0000-000000000005', '11111111-c008-1000-0000-000000000005',
   'L''accès à des millions de titres a rendu les auditeurs plus curieux que jamais',
   'false', '1'),

  ('11111111-c008-2200-0000-000000000005', '11111111-c008-1000-0000-000000000005',
   'Confiée aux algorithmes, l''écoute musicale se rétrécit, alors que la découverte reste possible pour qui cherche par lui-même',
   'true', '2'),

  ('11111111-c008-2300-0000-000000000005', '11111111-c008-1000-0000-000000000005',
   'L''auteur appelle à se détourner complètement des plateformes d''écoute en ligne',
   'false', '3'),

  ('11111111-c008-2400-0000-000000000005', '11111111-c008-1000-0000-000000000005',
   'La production indépendante a entièrement disparu des plateformes musicales',
   'false', '4'),

  -- item 06 — bande dessinée (bonne réponse : position 4)
  ('11111111-c008-2100-0000-000000000006', '11111111-c008-1000-0000-000000000006',
   'Un ton enthousiaste : il célèbre la consécration enfin obtenue du neuvième art',
   'false', '1'),

  ('11111111-c008-2200-0000-000000000006', '11111111-c008-1000-0000-000000000006',
   'Un ton résigné : il juge la pauvreté des artistes inévitable dans tout secteur culturel',
   'false', '2'),

  ('11111111-c008-2300-0000-000000000006', '11111111-c008-1000-0000-000000000006',
   'Un ton neutre : il se borne à rapporter les chiffres du marché de l''album',
   'false', '3'),

  ('11111111-c008-2400-0000-000000000006', '11111111-c008-1000-0000-000000000006',
   'Un ton indigné : il dénonce une reconnaissance de façade qui ne profite pas à ceux qui créent',
   'true', '4'),

  -- item 07 — festivals d'été (bonne réponse : position 1)
  ('11111111-c008-2100-0000-000000000007', '11111111-c008-1000-0000-000000000007',
   'La fragilité économique des festivals indépendants menace la diversité culturelle de l''été français',
   'true', '1'),

  ('11111111-c008-2200-0000-000000000007', '11111111-c008-1000-0000-000000000007',
   'Les festivals disparaissent avant tout parce que le public s''en détourne',
   'false', '2'),

  ('11111111-c008-2300-0000-000000000007', '11111111-c008-1000-0000-000000000007',
   'Les normes de sécurité devraient être allégées pour sauver les festivals',
   'false', '3'),

  ('11111111-c008-2400-0000-000000000007', '11111111-c008-1000-0000-000000000007',
   'Le nombre de festivals organisés chaque été diminue rapidement en France',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c008-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « culture & médias », 7 angles tous différents :
--     librairies indépendantes / salles de cinéma face au streaming /
--     défiance envers les journalistes / gratuité des musées / algorithmes
--     de recommandation musicale / reconnaissance de la bande dessinée /
--     économie des festivals d'été. Aucun thème interdit.
-- [x] Textes B2 longs : 196 / 207 / 208 / 205 / 212 / 212 / 212 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (ex. « ne survit pas parce qu'elle est rentable », « non par manque
--     de public », « le prix du billet n'a jamais été le principal
--     obstacle », « il en naîtra d'autres »).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2 (items 01, 05),
--     ce_inference_intention ×3 (items 02, 04, 07), ce_ton_auteur ×2
--     (items 03, 06).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme linguistique
--     nommé (concession rhétorique, inversion cause/effet, inférence
--     d'intention, détail vrai mais secondaire, sur-généralisation).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (chiffres, études, situations
--     inventés, aucune personnalité ni marque réelle).
-- ============================================================================
