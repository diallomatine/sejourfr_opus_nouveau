-- ============================================================================
-- V472 — TCF CE B2 — lot 12 (thème : alimentation)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~177-198 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : carnets de recettes familiaux, fermentation du pain, néophobie
-- alimentaire enfantine, fromages au lait cru, légumes oubliés,
-- authenticité culinaire, raccourcissement du déjeuner.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c00c-4000-0000-000000000001', 'TEXTE',
   'Dans une boîte en fer, chez Josiane, à Périgueux, dorment trois carnets couverts d''une écriture serrée : la daube de sa grand-mère, le clafoutis d''une voisine, des proportions notées « au jugé ». Des millions de foyers français possèdent de tels carnets de recettes, et la plupart finiront à la benne lors d''un déménagement ou d''une succession.

On aurait tort d''y voir un détail sentimental. Ces carnets constituent la seule trace écrite d''une cuisine domestique que les livres de chefs ignorent : plats d''accommodation des restes, tours de main régionaux, variantes familiales d''un même bourguignon. Les historiens de l''alimentation, qui travaillent d''ordinaire sur les menus imprimés et les traités de gastronomie, commencent à peine à les collecter, et plusieurs bibliothèques municipales, comme celle de Tourcoing, lancent des appels aux dons.

Certains objecteront que la cuisine vivante n''a pas besoin d''archives : une recette existe parce qu''on la prépare, pas parce qu''on la conserve. L''argument aurait du poids si la transmission orale fonctionnait encore. Or, on cuisine de moins en moins avec ses aînés. Quand le geste ne se montre plus, il ne reste que le papier. Le jeter, c''est effacer deux siècles de cuisine ordinaire que personne n''a jamais jugée digne d''être imprimée.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00c-4000-0000-000000000002', 'TEXTE',
   'À quoi reconnaît-on un bon pain ? À sa croûte dorée, répondent la plupart des clients interrogés à la sortie des boulangeries de Besançon. Mauvaise pioche : l''apparence est précisément ce que l''industrie sait le mieux imiter. Améliorants, cuissons calibrées, four à sole reconstitué en vitrine, tout concourt à donner au pain le plus standardisé l''allure d''un produit de terroir.

La vraie ligne de partage est invisible : c''est le temps. Une pâte qui fermente quinze à vingt-quatre heures développe des arômes complexes et une mie qui se conserve ; une pâte expédiée en deux heures, dopée à la levure, produit un pain spectaculaire au sortir du four et rassis dès le soir. Or rien n''oblige un artisan à prendre son temps : l''enseigne « boulangerie » garantit seulement que le pain est pétri et cuit sur place, pas qu''il a fermenté lentement.

Le consommateur n''est pourtant pas démuni. Un pain dont la mie reste souple le lendemain, dont la croûte chante quand on la presse, dont l''acidité se devine, a presque toujours pris son temps. Le goût, lui, ne s''imite pas : il s''attend.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00c-4000-0000-000000000003', 'TEXTE',
   '« Il ne mange rien. » Ainsi commencent la plupart des consultations que reçoit Hortense Mariani, qui anime des ateliers du goût dans les écoles maternelles de Clermont-Ferrand. Brocolis recrachés, assiettes triées, repas transformés en bras de fer : entre deux et six ans, près de trois enfants sur quatre traversent une période de néophobie alimentaire, ce refus quasi systématique des aliments nouveaux.

Première nouvelle pour les parents inquiets : cette phase est normale. Les spécialistes du développement y voient même un héritage utile, le réflexe de prudence d''un petit omnivore qui apprend à marcher et pourrait porter n''importe quoi à sa bouche. Elle s''estompe d''elle-même dans l''immense majorité des cas.

Seconde nouvelle, moins confortable : la plupart des stratégies parentales l''aggravent. Forcer à finir l''assiette associe l''aliment à la contrainte ; déguiser les légumes dans une purée prive l''enfant de l''occasion d''apprivoiser leur goût ; le chantage au dessert transforme le légume en punition et le sucre en récompense. Ce qui fonctionne est plus lent et moins spectaculaire : représenter l''aliment refusé, parfois dix ou douze fois, sans commentaire et sans obligation, et manger soi-même, avec un plaisir visible, ce que l''on souhaite voir adopté.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00c-4000-0000-000000000004', 'TEXTE',
   'Le saint-félicien de la ferme des Brunier, près de Valence, a manqué disparaître l''an dernier : deux analyses défavorables, une suspension de commercialisation, des mois de trésorerie à sec. L''affaire s''est conclue sans qu''aucun consommateur ne tombe malade, mais elle illustre la pression croissante qui pèse sur les fromages au lait cru, lesquels ne représentent plus qu''un dixième de la production française.

Que l''on s''entende : personne de sensé ne réclame la suppression des contrôles sanitaires. Les fromagers eux-mêmes les acceptent, et les drames passés ont laissé des traces légitimes. Le problème est ailleurs : les seuils s''abaissent d''année en année, les protocoles s''alourdissent, et chaque alerte médiatisée pousse distributeurs et cantines à écarter le lait cru par simple précaution juridique, au-delà de toute exigence réglementaire.

Or un fromage au lait cru n''est pas un fromage pasteurisé avec un supplément de risque : c''est un écosystème vivant, dont la flore microbienne fait précisément le goût. Le pasteuriser, c''est le rendre sûr et interchangeable. À force d''exiger du vivant qu''il se comporte comme du stérile, on finira par obtenir des fromages irréprochables — et qui n''auront plus rien à dire.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00c-4000-0000-000000000005', 'TEXTE',
   'Panais, rutabaga, cerfeuil tubéreux : il y a vingt ans, ces noms évoquaient au mieux les récits des anciens, au pire rien du tout. Aujourd''hui, on les retrouve sur les cartes des tables les plus en vue, où un simple topinambour rôti peut se facturer au prix d''une viande. La gastronomie adore ces revenants : ils racontent une histoire, surprennent le palais et photographient bien.

Faut-il pour autant parler de retour ? Rien n''est moins sûr. Dans les cuisines familiales, ces légumes restent introuvables ou intimidants : on ne sait ni les choisir, ni les éplucher, ni les cuire, et leur prix au kilo, souvent supérieur à celui des légumes courants, n''aide pas à se lancer. Le maraîcher qui en cultive trois rangs pour deux restaurants ne nourrit pas un rayon de supermarché.

L''histoire de la cuisine l''a montré plus d''une fois : un produit ne revient vraiment que lorsqu''il passe des menus de fête aux repas du mardi. Le jour où le cerfeuil tubéreux figurera dans une soupe ordinaire, sans storytelling ni supplément, les « légumes oubliés » auront cessé de l''être. D''ici là, ils restent surtout les accessoires d''une mode gastronomique.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00c-4000-0000-000000000006', 'TEXTE',
   'Lorsque le chef Damien Roche a présenté, dans son bistrot de Nantes, un pot-au-feu au lait de coco et à la citronnelle, les commentaires furieux ont plu : on ne « trahit » pas un monument national. L''épisode ferait sourire s''il ne révélait une croyance tenace : celle d''une cuisine authentique, fixée de toute éternité, qu''il faudrait protéger des mélanges.

Cette cuisine-là n''a jamais existé. La tomate, emblème de la Provence, a mis deux siècles à être acceptée après son arrivée d''Amérique ; la pomme de terre fut longtemps réservée aux bêtes ; le « traditionnel » bœuf bourguignon doit autant aux manuels du dix-neuvième siècle qu''aux fermes de Bourgogne. Ce que chaque génération appelle tradition n''est que l''innovation de la précédente, digérée puis sacralisée.

Défendre des savoir-faire, des appellations, des terroirs : rien de plus légitime. Mais brandir l''authenticité pour interdire l''expérimentation, c''est confondre patrimoine et embaumement. Les cuisines que l''on admire aujourd''hui sont précisément celles qui ont le plus emprunté, accueilli, détourné. Le pot-au-feu à la citronnelle de Damien Roche ne menace pas la tradition : il fait exactement ce qu''elle a toujours fait — il continue.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c00c-4000-0000-000000000007', 'TEXTE',
   'Vingt-deux minutes : c''est le temps moyen que les actifs français consacrent désormais à leur déjeuner, selon une enquête menée auprès de quatre mille salariés par l''institut lillois Opaline. Au début des années quatre-vingt, la même pause durait près d''une heure et demie. En une génération, le repas de midi s''est réduit à un ravitaillement : sandwich avalé devant un écran, salade en boîte mangée debout, parfois rien du tout.

On rétorquera que cette évolution relève de la liberté de chacun, et qu''une heure gagnée à midi est une heure rendue au soir. L''argument se défend, et il serait absurde d''idéaliser les déjeuners d''autrefois, qui devaient moins à l''art de vivre qu''à l''absence d''alternative.

Reste que quelque chose se perd, qui ne relève pas de la nostalgie. Un repas pris ensemble, lentement, est l''un des derniers moments où l''on mange ce que l''on goûte, où la conversation n''a pas d''ordre du jour, où les hiérarchies se suspendent. Le déjeuner expédié nourrit, sans aucun doute. Mais une alimentation qui ne serait plus que du carburant aurait renoncé, sans le dire, à la moitié de ce qui fait sa raison d''être.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c00c-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00c-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale défendue par l''auteur ?',
   'L''auteur conclut : « Le jeter, c''est effacer deux siècles de cuisine ordinaire ». **L''idée principale est que les carnets de recettes familiaux forment un patrimoine culinaire à sauver de la disparition.** La réponse A est une sur-généralisation : on cuisine « de moins en moins » avec ses aînés, ce qui ne signifie pas que les Français ont cessé de cuisiner les plats familiaux. La réponse C promeut un **détail vrai mais secondaire** : les appels aux dons des bibliothèques illustrent la thèse, ils ne la constituent pas. La réponse D attribue aux historiens l''argument des objecteurs (« la cuisine vivante n''a pas besoin d''archives »), que l''auteur réfute justement. Mécanisme : distinguer la **thèse défendue** des arguments rapportés.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c00c-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00c-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur la qualité du pain ?',
   'Le texte affirme : « La vraie ligne de partage est invisible : c''est le temps ». **La qualité d''un pain tient d''abord à la durée de sa fermentation**, ce que la bonne réponse reformule. La réponse A reprend le piège d''ouverture : la croûte dorée est « précisément ce que l''industrie sait le mieux imiter », donc un critère trompeur. La réponse B inverse un détail explicite : l''enseigne garantit un pain pétri et cuit sur place, « pas qu''il a fermenté lentement ». La réponse C contredit le premier paragraphe : l''industrie imite très bien l''apparence des produits de terroir. Mécanisme : **inférence de la cause principale** face à un critère apparent mis en avant puis démenti.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c00c-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00c-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Quelle est l''intention principale de l''auteur de ce texte ?',
   'Le texte articule deux « nouvelles » : la néophobie « est normale » et s''estompe d''elle-même, mais « la plupart des stratégies parentales l''aggravent ». **L''intention est de rassurer les parents tout en corrigeant des réactions contre-productives.** La réponse B dramatise à contre-sens : il s''agit d''une phase normale du développement, pas d''une maladie exigeant un spécialiste. La réponse C inverse un conseil : déguiser les légumes « prive l''enfant de l''occasion d''apprivoiser leur goût », c''est une stratégie dénoncée. La réponse D est une sur-généralisation : les ateliers d''Hortense Mariani servent de cadre au texte, jamais de solution unique — ce qui fonctionne, c''est l''exposition répétée sans pression. Mécanisme : **inférence d''intention** à partir d''un plan en deux temps (rassurer puis corriger).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c00c-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00c-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur sur les contrôles sanitaires appliqués aux fromages au lait cru ?',
   'L''auteur concède : « personne de sensé ne réclame la suppression des contrôles sanitaires », avant d''objecter : « Le problème est ailleurs » — seuils abaissés, précaution juridique excessive. **Sa position : des contrôles nécessaires, mais une surenchère de précaution qui menace ces fromages.** La réponse A contredit la concession explicite : il ne demande jamais la suppression des contrôles. La réponse B invente une affirmation absente : l''auteur ne nie pas le risque, il rappelle même que « les drames passés ont laissé des traces légitimes ». La réponse D inverse la conclusion : pasteuriser, c''est rendre le fromage « sûr et interchangeable », c''est-à-dire lui ôter son goût. Mécanisme : la **concession rhétorique** (que l''on s''entende… le problème est ailleurs) signale une critique nuancée, non un rejet ni une approbation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c00c-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00c-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'Le texte répond à sa propre question (« Faut-il pour autant parler de retour ? Rien n''est moins sûr ») et conclut que ces légumes « restent surtout les accessoires d''une mode gastronomique ». **L''idée principale : le retour des légumes anciens reste une mode de restaurant tant qu''ils n''entrent pas dans la cuisine quotidienne.** La réponse A est la sur-généralisation que le texte réfute précisément : dans les cuisines familiales, ils restent « introuvables ou intimidants ». La réponse B promeut un **détail vrai mais secondaire** (le prix du topinambour) en idée centrale. La réponse C déforme un constat : le maraîcher aux trois rangs « ne nourrit pas un rayon de supermarché », il n''est pas dit qu''il refuse de le faire. Mécanisme : résister au détail saillant et repérer la **réponse de l''auteur à sa question rhétorique**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c00c-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00c-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Que cherche à montrer l''auteur de ce texte ?',
   'Le pivot du texte est : « Cette cuisine-là n''a jamais existé » et « Ce que chaque génération appelle tradition n''est que l''innovation de la précédente ». **L''auteur veut montrer que les cuisines dites traditionnelles se sont toujours construites par emprunts et mélanges.** La réponse A inverse l''intention : le pot-au-feu revisité est défendu en conclusion (« il fait exactement ce qu''elle a toujours fait »). La réponse C sur-étend le propos : défendre appellations et terroirs est jugé « rien de plus légitime », l''auteur ne leur retire aucune protection. La réponse D promeut un **détail vrai mais secondaire** : la tomate et la pomme de terre sont des exemples au service de la démonstration, pas sa conclusion. Mécanisme : **inférence d''intention** — distinguer les exemples historiques de la thèse qu''ils illustrent.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c00c-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c00c-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Comment l''auteur se positionne-t-il face au raccourcissement du déjeuner ?',
   'L''auteur concède (« L''argument se défend », « il serait absurde d''idéaliser les déjeuners d''autrefois ») puis retourne la concession : « Reste que quelque chose se perd ». **Sa position : regretter la perte de la dimension partagée du repas, sans idéaliser le passé.** La réponse A confond la thèse de l''auteur avec l''objection qu''il rapporte (« On rétorquera que… ») et qu''il dépasse aussitôt. La réponse B invente une prescription : aucun retour à la pause d''une heure et demie n''est réclamé, le chiffre des années quatre-vingt n''est qu''un repère. La réponse D contredit un détail explicite : ces déjeuners « devaient moins à l''art de vivre qu''à l''absence d''alternative ». Mécanisme : le **mouvement concessif** (on rétorquera… reste que) exprime un jugement nuancé, ni nostalgie ni approbation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — carnets de recettes familiaux (bonne réponse : position 2)
  ('11111111-c00c-2100-0000-000000000001', '11111111-c00c-1000-0000-000000000001',
   'Les Français ont cessé de cuisiner les plats transmis par leurs aînés',
   'false', '1'),

  ('11111111-c00c-2200-0000-000000000001', '11111111-c00c-1000-0000-000000000001',
   'Les carnets de recettes familiaux sont un patrimoine culinaire qu''il faut sauver de la disparition',
   'true', '2'),

  ('11111111-c00c-2300-0000-000000000001', '11111111-c00c-1000-0000-000000000001',
   'Des bibliothèques municipales organisent des collectes de carnets de recettes anciens',
   'false', '3'),

  ('11111111-c00c-2400-0000-000000000001', '11111111-c00c-1000-0000-000000000001',
   'Les historiens estiment qu''une cuisine vivante n''a pas besoin d''être archivée',
   'false', '4'),

  -- item 02 — fermentation du pain (bonne réponse : position 4)
  ('11111111-c00c-2100-0000-000000000002', '11111111-c00c-1000-0000-000000000002',
   'La croûte dorée reste le critère le plus fiable pour reconnaître un bon pain',
   'false', '1'),

  ('11111111-c00c-2200-0000-000000000002', '11111111-c00c-1000-0000-000000000002',
   'L''enseigne « boulangerie » garantit au client un pain à fermentation lente',
   'false', '2'),

  ('11111111-c00c-2300-0000-000000000002', '11111111-c00c-1000-0000-000000000002',
   'L''industrie ne parvient pas à imiter l''apparence des pains de terroir',
   'false', '3'),

  ('11111111-c00c-2400-0000-000000000002', '11111111-c00c-1000-0000-000000000002',
   'La qualité d''un pain dépend avant tout de la durée de sa fermentation',
   'true', '4'),

  -- item 03 — néophobie alimentaire enfantine (bonne réponse : position 1)
  ('11111111-c00c-2100-0000-000000000003', '11111111-c00c-1000-0000-000000000003',
   'Rassurer les parents sur une phase normale tout en corrigeant des réactions qui l''entretiennent',
   'true', '1'),

  ('11111111-c00c-2200-0000-000000000003', '11111111-c00c-1000-0000-000000000003',
   'Alerter sur une maladie de l''enfance qui exige une consultation spécialisée',
   'false', '2'),

  ('11111111-c00c-2300-0000-000000000003', '11111111-c00c-1000-0000-000000000003',
   'Recommander de dissimuler les légumes dans les plats pour habituer les enfants à leur goût',
   'false', '3'),

  ('11111111-c00c-2400-0000-000000000003', '11111111-c00c-1000-0000-000000000003',
   'Démontrer que seule la participation à des ateliers du goût fait disparaître la néophobie',
   'false', '4'),

  -- item 04 — fromages au lait cru (bonne réponse : position 3)
  ('11111111-c00c-2100-0000-000000000004', '11111111-c00c-1000-0000-000000000004',
   'Il réclame la suppression des contrôles, responsables selon lui de la disparition des fermes',
   'false', '1'),

  ('11111111-c00c-2200-0000-000000000004', '11111111-c00c-1000-0000-000000000004',
   'Il considère que les fromages au lait cru ne présentent aucun risque sanitaire',
   'false', '2'),

  ('11111111-c00c-2300-0000-000000000004', '11111111-c00c-1000-0000-000000000004',
   'Il en admet la nécessité mais dénonce une surenchère de précaution qui menace ces fromages',
   'true', '3'),

  ('11111111-c00c-2400-0000-000000000004', '11111111-c00c-1000-0000-000000000004',
   'Il recommande la pasteurisation pour concilier sécurité et qualité gustative',
   'false', '4'),

  -- item 05 — légumes oubliés (bonne réponse : position 4)
  ('11111111-c00c-2100-0000-000000000005', '11111111-c00c-1000-0000-000000000005',
   'Les légumes oubliés ont retrouvé leur place dans l''alimentation quotidienne des Français',
   'false', '1'),

  ('11111111-c00c-2200-0000-000000000005', '11111111-c00c-1000-0000-000000000005',
   'Les grandes tables facturent désormais le topinambour au prix d''une viande',
   'false', '2'),

  ('11111111-c00c-2300-0000-000000000005', '11111111-c00c-1000-0000-000000000005',
   'Les maraîchers refusent de cultiver ces variétés anciennes pour les supermarchés',
   'false', '3'),

  ('11111111-c00c-2400-0000-000000000005', '11111111-c00c-1000-0000-000000000005',
   'Le retour des légumes anciens restera une mode de restaurant tant qu''ils n''entreront pas dans la cuisine ordinaire',
   'true', '4'),

  -- item 06 — authenticité culinaire (bonne réponse : position 2)
  ('11111111-c00c-2100-0000-000000000006', '11111111-c00c-1000-0000-000000000006',
   'Que les chefs devraient renoncer à revisiter les grands plats du patrimoine national',
   'false', '1'),

  ('11111111-c00c-2200-0000-000000000006', '11111111-c00c-1000-0000-000000000006',
   'Que les cuisines dites traditionnelles se sont toujours construites par emprunts et mélanges',
   'true', '2'),

  ('11111111-c00c-2300-0000-000000000006', '11111111-c00c-1000-0000-000000000006',
   'Que les appellations et les terroirs ne méritent aucune protection particulière',
   'false', '3'),

  ('11111111-c00c-2400-0000-000000000006', '11111111-c00c-1000-0000-000000000006',
   'Que la tomate et la pomme de terre furent d''abord mal accueillies en France',
   'false', '4'),

  -- item 07 — raccourcissement du déjeuner (bonne réponse : position 3)
  ('11111111-c00c-2100-0000-000000000007', '11111111-c00c-1000-0000-000000000007',
   'Il considère que cette évolution relève d''une liberté individuelle qu''il faut saluer',
   'false', '1'),

  ('11111111-c00c-2200-0000-000000000007', '11111111-c00c-1000-0000-000000000007',
   'Il appelle à rétablir la pause d''une heure et demie des années quatre-vingt',
   'false', '2'),

  ('11111111-c00c-2300-0000-000000000007', '11111111-c00c-1000-0000-000000000007',
   'Il regrette la perte de la dimension partagée du repas, sans pour autant idéaliser le passé',
   'true', '3'),

  ('11111111-c00c-2400-0000-000000000007', '11111111-c00c-1000-0000-000000000007',
   'Il juge que les déjeuners d''autrefois témoignaient d''un véritable art de vivre',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c00c-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « alimentation », 7 angles tous différents :
--     carnets de recettes familiaux / fermentation du pain artisanal /
--     néophobie alimentaire enfantine / fromages au lait cru et normes /
--     légumes oubliés en gastronomie / authenticité culinaire et métissage /
--     raccourcissement du déjeuner. Aucun thème interdit (pas de santé
--     publique, environnement, consommation responsable ni économie).
-- [x] Textes B2 longs : 198 / 177 / 188 / 184 / 186 / 178 / 187 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (ex. croûte dorée trompeuse, « que l''on s''entende… le problème est
--     ailleurs », prix du topinambour, « on rétorquera… reste que »).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:1, pos2:2, pos3:2, pos4:2
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2 (items 1, 5),
--     ce_inference_intention ×3 (items 2, 3, 6), ce_ton_auteur ×2 (items 4, 7).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme nommé
--     (concession rhétorique, inversion, sur-généralisation, détail vrai
--     mais secondaire, inférence d'intention, question rhétorique).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (prénoms, villes, chiffres inventés).
-- ============================================================================
