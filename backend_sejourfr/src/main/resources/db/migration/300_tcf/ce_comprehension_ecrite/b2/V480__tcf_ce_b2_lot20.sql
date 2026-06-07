-- ============================================================================
-- V480 — TCF CE B2 — lot 20 (thème : consommation responsable)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~186-194 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : seconde main & effet rebond, labels « durables », bonus réparation,
-- vente en vrac, boycotts citoyens, bibliothèques d'objets, injonction
-- « consommer mieux ».
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c014-4000-0000-000000000001', 'TEXTE',
   'Avec quarante millions d''annonces publiées chaque année, les plateformes de revente de vêtements entre particuliers se présentent volontiers comme les championnes d''une mode enfin durable. Acheter d''occasion plutôt que neuf : le geste paraît irréprochable, et il l''est parfois.

Parfois seulement. Car les économistes qui se penchent sur ces plateformes décrivent un mécanisme moins reluisant, l''effet rebond. L''argent tiré de la revente d''une robe portée deux fois ne dort pas sur un compte : dans la majorité des cas, il finance aussitôt de nouveaux achats, souvent neufs. Pire, la perspective de pouvoir revendre demain déculpabilise l''achat d''aujourd''hui : pourquoi résister à un pantalon superflu puisqu''il retrouvera preneur ? Une enquête menée à Bordeaux auprès de mille utilisateurs réguliers révèle ainsi que leur garde-robe a grossi depuis qu''ils revendent.

La seconde main n''a d''intérêt écologique que si elle remplace un achat neuf. Quand elle s''y ajoute, elle accélère la rotation des vêtements au lieu de la freiner. Ce n''est pas une raison pour renoncer à l''occasion, mais une invitation à la lucidité : le marché de la revente est d''abord un marché, et il prospère sur ce qu''il prétend combattre — l''envie permanente de renouveler sa penderie.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c014-4000-0000-000000000002', 'TEXTE',
   'Dans les rayons d''un supermarché de Besançon, Olena, trente-quatre ans, retourne un paquet de café : trois logos verts, deux mentions « responsable », un pictogramme de feuille. Lequel croire ? Elle n''est pas la seule à se poser la question. On recense désormais plus de quatre cent cinquante labels et allégations « durables » sur le marché français, contre une centaine il y a quinze ans.

Cette inflation aurait pu être une bonne nouvelle : elle signalerait des exigences toujours plus nombreuses. C''est l''inverse qui se produit. Une partie de ces signes sont de simples auto-déclarations des marques, sans contrôle indépendant ; d''autres certifient des critères si modestes qu''ils n''engagent presque à rien. Noyés dans cette profusion, les labels sérieux — cahier des charges public, audits externes, exigences mesurables — deviennent indiscernables des étiquettes de complaisance. Résultat documenté par les associations de consommateurs : un acheteur sur deux déclare ne plus faire confiance à aucun logo, y compris aux plus rigoureux.

Le législateur a commencé à interdire les mentions vagues comme « neutre en carbone » sans preuve. Il faudra aller plus loin : tant qu''afficher une feuille verte restera moins coûteux que mériter un vrai label, la profusion continuera de fabriquer du doute, c''est-à-dire de l''inaction.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c014-4000-0000-000000000003', 'TEXTE',
   'Depuis deux ans, faire réparer son grille-pain ou sa machine à laver ouvre droit à un « bonus réparation », déduit directement de la facture chez les professionnels labellisés. L''intention est louable : remettre en circulation des objets condamnés à la benne pour une panne de trente euros. Et les chiffres frémissent : le nombre de réparations financées a doublé en un an, reconnaissons-le.

Doublé, certes — mais à partir de presque rien. Rapporté aux dizaines de millions d''appareils jetés chaque année, le dispositif relève de l''homéopathie. Surtout, il ne s''attaque à aucune des causes qui rendent la réparation dissuasive : pièces détachées vendues à des prix prohibitifs quand elles existent, appareils collés ou soudés conçus pour décourager le démontage, réseau de réparateurs si clairsemé qu''il faut parfois soixante kilomètres pour trouver un atelier agréé. À Guéret comme à Mende, le bonus ne sert à rien faute de professionnel pour l''appliquer.

On nous pardonnera donc un enthousiasme mesuré. Subventionner la réparation sans contraindre les fabricants à concevoir des produits réparables, c''est éponger le sol en laissant le robinet ouvert. Le jour où un lave-linge increvable coûtera moins cher, à l''usage, qu''un lave-linge jetable, on n''aura plus besoin de bonus.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c014-4000-0000-000000000004', 'TEXTE',
   'Il y a cinq ans encore, les épiceries de vrac ouvraient au rythme d''une par jour, et les supermarchés s''empressaient d''installer leurs silos de céréales et de lessive à la louche. Le secteur, qui avait triplé de taille en trois ans, se voyait déjà conquérir un rayon sur cinq. La réalité a tourné autrement : un magasin spécialisé sur trois a fermé depuis, et les enseignes généralistes réduisent discrètement leurs linéaires sans emballage.

Faut-il y voir un désaveu de la consommation sans déchet ? Les études d''opinion disent le contraire : l''adhésion au principe n''a jamais été aussi haute. Ce qui a flanché, c''est l''épreuve du quotidien. Apporter ses bocaux, peser, étiqueter, transporter : le vrac exige du temps et de l''organisation, deux ressources que l''inflation et les journées surchargées ont raréfiées. Quand le paquet emballé coûte parfois moins cher au kilo que le même produit en silo — aberration due aux volumes d''achat des industriels —, l''arbitrage est vite fait.

Le vrac ne meurt pas d''un rejet, mais d''un défaut de conception : il a fait reposer tout l''effort sur le consommateur. Il renaîtra le jour où la simplicité changera de camp.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c014-4000-0000-000000000005', 'TEXTE',
   'À chaque scandale, le scénario se répète : appel au boycott sur les réseaux sociaux, déferlante d''indignation, promesse de ne plus jamais acheter la marque fautive. Puis, quelques semaines plus tard, les courbes de vente reprennent leur pente habituelle, comme si rien ne s''était passé. Faut-il en conclure que le boycott est une arme factice ? Ce serait aller vite en besogne.

L''économiste Diego Ferrant, qui a passé au crible une trentaine de campagnes menées en Europe depuis vingt ans, dresse un constat plus subtil. Les pertes de chiffre d''affaires restent, de fait, presque toujours marginales : la plupart des indignés ne changent pas durablement leurs habitudes. Mais l''effet décisif se joue ailleurs : la peur de la prochaine campagne. Pour éviter de devenir une cible, les entreprises revoient leurs chaînes d''approvisionnement, auditent leurs fournisseurs, publient des engagements — souvent avant toute menace concrète. Le boycott agit moins par les ventes qu''il retire que par les comportements qu''il prévient.

Conclusion contre-intuitive : inutile de culpabiliser les consommateurs qui « craquent ». Quelques milliers d''acheteurs visiblement déterminés suffisent à entretenir cette vigilance préventive. La force du boycott n''est pas dans le porte-monnaie, elle est dans la menace.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c014-4000-0000-000000000006', 'TEXTE',
   'Une perceuse sert en moyenne douze minutes dans toute sa vie. Partant de ce constat, des « bibliothèques d''objets » ont essaimé dans une quarantaine de villes : à Quimper, à Mulhouse ou à Valence, on y emprunte pour quelques euros par mois une ponceuse, une tente, un appareil à raclette ou une machine à coudre, comme on emprunterait un roman.

Le modèle séduit sur le papier — un objet partagé par cent foyers remplace des dizaines d''achats — mais son équilibre économique reste fragile. Les cotisations couvrent rarement le loyer du local et le salaire d''un permanent ; la plupart des structures survivent grâce aux subventions municipales et à des bénévoles qui s''épuisent. Surtout, leur fréquentation révèle un paradoxe embarrassant : les usagers sont en grande majorité des ménages diplômés et déjà convaincus, alors que l''argument économique — éviter d''immobiliser cent cinquante euros dans une perceuse — parlerait d''abord aux budgets serrés.

Pour les fondateurs du réseau, la priorité n''est donc plus d''ouvrir de nouveaux lieux, mais d''aller chercher ceux qui n''y entrent jamais : permanences dans les quartiers populaires, partenariats avec les bailleurs sociaux, tarifs solidaires. L''objet partagé ne changera la consommation que s''il sort du cercle des convertis.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c014-4000-0000-000000000007', 'TEXTE',
   '« Consommez mieux ! » L''injonction s''affiche partout, jusque sur les sacs en papier des enseignes qui nous vendaient hier l''inverse. Acheter moins mais durable, comparer les étiquettes, traquer les compositions douteuses : le consommateur moderne est sommé de devenir un expert à temps plein, enquêteur au rayon lessive, juriste devant les conditions de garantie.

Cette figure du « consom''acteur » a tout pour plaire aux industriels : elle déplace élégamment la responsabilité. Si la planète déborde d''objets inutiles, ce serait la faute de nos caddies mal remplis — non celle de catalogues renouvelés toutes les six semaines, des prix cassés conçus pour déclencher l''achat impulsif, ou des produits dont la fragilité est une stratégie commerciale. Le tour de passe-passe est connu ; il fonctionne toujours.

Soyons clair : les choix individuels comptent, et il serait absurde de s''en exonérer. Mais demander à chacun de résister, seul, à un système entièrement organisé pour le faire céder revient à organiser l''échec — puis à le lui reprocher. Une consommation réellement responsable commence en amont : par ce qu''on autorise à produire, à afficher, à promettre. Le reste, malgré les sourires des publicités recyclables, n''est trop souvent qu''un transfert de culpabilité savamment emballé.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c014-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c014-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'L''auteur conclut : « La seconde main n''a d''intérêt écologique que si elle remplace un achat neuf ». **L''idée principale est la condition de substitution : l''occasion n''est vertueuse que si elle évite un achat neuf, pas si elle s''y ajoute.** La réponse A affirme le contraire du texte : l''effet rebond montre que ces plateformes entretiennent la surconsommation, elles n''y ont pas mis fin. La réponse C est le **détail vrai mais secondaire** : les quarante millions d''annonces situent le phénomène, ils ne constituent pas la thèse. La réponse D sur-étend la conclusion : l''auteur précise que « ce n''est pas une raison pour renoncer à l''occasion ». Mécanisme : dégager l''**idée principale** d''un texte concessif, contre un détail chiffré promu en thèse.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c014-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c014-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur la multiplication des labels « durables » ?',
   'Le texte montre que les labels sérieux deviennent « indiscernables des étiquettes de complaisance » et qu''un acheteur sur deux ne fait « plus confiance à aucun logo, y compris aux plus rigoureux » : **la profusion de labels détruit la confiance, même envers les plus exigeants.** La réponse A reprend l''hypothèse explicitement réfutée par le texte (« C''est l''inverse qui se produit »). La réponse B est une sur-généralisation : seule « une partie de ces signes » sont des auto-déclarations sans contrôle. La réponse C déforme un détail : le législateur « a commencé à interdire les mentions vagues », il n''a pas banni l''ensemble des allégations. Mécanisme : **inférence de conséquence** (profusion → doute → inaction) face à une inversion tentante.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c014-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c014-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Quelle est la position de l''auteur à l''égard du bonus réparation ?',
   'L''auteur concède le doublement des réparations (« reconnaissons-le ») avant de retourner la concession : « Doublé, certes — mais à partir de presque rien », le dispositif relevant de « l''homéopathie ». **Sa position : un premier pas réel mais dérisoire tant que les fabricants ne seront pas contraints de concevoir des produits réparables.** La réponse B inverse le mouvement concessif : le doublement est minimisé, pas salué comme décisif. La réponse C sur-étend la chute du texte : la disparition du bonus est un horizon conditionnel souhaité, pas une demande de suppression immédiate. La réponse D invente une cause absente : le texte incrimine les fabricants et le réseau clairsemé, jamais le désintérêt des consommateurs. Mécanisme : la **concession rhétorique** (certes… mais) signale un enthousiasme mesuré, non une adhésion.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c014-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c014-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur le recul de la vente en vrac ?',
   'Le texte conclut : « Le vrac ne meurt pas d''un rejet, mais d''un défaut de conception : il a fait reposer tout l''effort sur le consommateur ». **La cause du recul est la charge pratique imposée à l''acheteur, pas un désaveu du principe.** La réponse A contredit les études citées : « l''adhésion au principe n''a jamais été aussi haute ». La réponse B inverse un détail-piège : c''est le paquet emballé qui coûte « parfois moins cher au kilo » que le même produit en silo. La réponse D est une sur-généralisation : un magasin spécialisé « sur trois » a fermé, pas tous. Mécanisme : distinguer la **cause réelle** (contraintes du quotidien) d''une inversion cause/effet (rejet supposé du principe).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c014-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c014-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale défendue dans ce texte ?',
   'L''étude citée conclut que le boycott « agit moins par les ventes qu''il retire que par les comportements qu''il prévient » : **l''idée principale est l''effet dissuasif du boycott sur les entreprises, supérieur à son impact commercial direct.** La réponse A est le **détail vrai mais secondaire** : les pertes marginales servent d''appui au raisonnement, elles ne sont pas la thèse. La réponse C reprend l''hypothèse écartée dès l''ouverture (« Ce serait aller vite en besogne »). La réponse D contredit le texte : « la plupart des indignés ne changent pas durablement leurs habitudes ». Mécanisme : repérer la **thèse contre-intuitive** d''un texte qui réfute d''abord la lecture évidente.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c014-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c014-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Que cherche à montrer l''auteur de ce texte ?',
   'Le texte se ferme sur la condition décisive : « L''objet partagé ne changera la consommation que s''il sort du cercle des convertis ». **L''auteur veut montrer que l''enjeu des bibliothèques d''objets est désormais d''élargir leur public au-delà des ménages déjà acquis.** La réponse A contredit le texte : l''équilibre économique « reste fragile », les structures survivent grâce aux subventions. La réponse B est le **détail vrai mais secondaire** : les douze minutes d''usage d''une perceuse sont l''accroche, pas le propos. La réponse C inverse le paradoxe décrit : les usagers sont en grande majorité des ménages diplômés et convaincus, pas les budgets serrés. Mécanisme : **inférence globale** — relier le paradoxe central (public des convertis) à la conclusion programmatique.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c014-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c014-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Comment l''auteur se positionne-t-il face à l''injonction de « consommer mieux » ?',
   'L''auteur concède que « les choix individuels comptent » mais dénonce « un transfert de culpabilité savamment emballé » orchestré par les industriels : **sa position est une critique du report de responsabilité sur le consommateur, sans nier la part des choix individuels.** La réponse B sur-étend la critique : l''auteur juge « absurde de s''en exonérer », il ne nie pas l''importance des choix. La réponse C inverse le ton : la mention des enseignes « qui nous vendaient hier l''inverse » est ironique, pas élogieuse. La réponse D prend pour opinion de l''auteur la thèse qu''il rapporte au conditionnel (« ce serait la faute de nos caddies ») précisément pour la dénoncer. Mécanisme : distinguer le **discours rapporté ironique** de l''opinion réelle de l''auteur (ton).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — seconde main & effet rebond (bonne réponse : position 2)
  ('11111111-c014-2100-0000-000000000001', '11111111-c014-1000-0000-000000000001',
   'Les plateformes de revente entre particuliers ont mis fin à la surconsommation de vêtements',
   'false', '1'),

  ('11111111-c014-2200-0000-000000000001', '11111111-c014-1000-0000-000000000001',
   'L''achat d''occasion n''est écologiquement utile que s''il remplace un achat neuf au lieu de s''y ajouter',
   'true', '2'),

  ('11111111-c014-2300-0000-000000000001', '11111111-c014-1000-0000-000000000001',
   'Quarante millions d''annonces sont publiées chaque année sur les plateformes de revente',
   'false', '3'),

  ('11111111-c014-2400-0000-000000000001', '11111111-c014-1000-0000-000000000001',
   'Il faut renoncer définitivement à acheter ses vêtements en seconde main',
   'false', '4'),

  -- item 02 — labels « durables » (bonne réponse : position 4)
  ('11111111-c014-2100-0000-000000000002', '11111111-c014-1000-0000-000000000002',
   'La multiplication des labels prouve que les exigences des marques se renforcent',
   'false', '1'),

  ('11111111-c014-2200-0000-000000000002', '11111111-c014-1000-0000-000000000002',
   'Tous les logos verts présents en rayon sont de simples étiquettes de complaisance',
   'false', '2'),

  ('11111111-c014-2300-0000-000000000002', '11111111-c014-1000-0000-000000000002',
   'Le législateur a interdit l''ensemble des allégations environnementales sur les produits',
   'false', '3'),

  ('11111111-c014-2400-0000-000000000002', '11111111-c014-1000-0000-000000000002',
   'La profusion de logos finit par discréditer même les labels les plus rigoureux',
   'true', '4'),

  -- item 03 — bonus réparation (bonne réponse : position 1)
  ('11111111-c014-2100-0000-000000000003', '11111111-c014-1000-0000-000000000003',
   'Il y voit un premier pas réel mais dérisoire tant que la conception des produits ne change pas',
   'true', '1'),

  ('11111111-c014-2200-0000-000000000003', '11111111-c014-1000-0000-000000000003',
   'Il salue une mesure décisive qui a déjà transformé le marché de la réparation',
   'false', '2'),

  ('11111111-c014-2300-0000-000000000003', '11111111-c014-1000-0000-000000000003',
   'Il réclame la suppression immédiate d''un bonus qu''il juge totalement inutile',
   'false', '3'),

  ('11111111-c014-2400-0000-000000000003', '11111111-c014-1000-0000-000000000003',
   'Il attribue l''échec du dispositif au désintérêt des consommateurs pour la réparation',
   'false', '4'),

  -- item 04 — vente en vrac (bonne réponse : position 3)
  ('11111111-c014-2100-0000-000000000004', '11111111-c014-1000-0000-000000000004',
   'Les Français n''adhèrent plus au principe d''une consommation sans déchet',
   'false', '1'),

  ('11111111-c014-2200-0000-000000000004', '11111111-c014-1000-0000-000000000004',
   'Les produits en vrac restent toujours moins chers au kilo que les produits emballés',
   'false', '2'),

  ('11111111-c014-2300-0000-000000000004', '11111111-c014-1000-0000-000000000004',
   'Le vrac recule parce qu''il fait peser l''essentiel de l''effort sur le consommateur, non par rejet du principe',
   'true', '3'),

  ('11111111-c014-2400-0000-000000000004', '11111111-c014-1000-0000-000000000004',
   'Toutes les épiceries spécialisées dans le vrac ont fermé en cinq ans',
   'false', '4'),

  -- item 05 — boycotts citoyens (bonne réponse : position 2)
  ('11111111-c014-2100-0000-000000000005', '11111111-c014-1000-0000-000000000005',
   'Les pertes de ventes provoquées par les boycotts restent presque toujours marginales',
   'false', '1'),

  ('11111111-c014-2200-0000-000000000005', '11111111-c014-1000-0000-000000000005',
   'Le boycott agit surtout par la crainte qu''il inspire aux entreprises, davantage que par les ventes perdues',
   'true', '2'),

  ('11111111-c014-2300-0000-000000000005', '11111111-c014-1000-0000-000000000005',
   'Le boycott est une arme factice qui ne produit aucun effet sur les entreprises',
   'false', '3'),

  ('11111111-c014-2400-0000-000000000005', '11111111-c014-1000-0000-000000000005',
   'La plupart des consommateurs indignés modifient durablement leurs habitudes d''achat',
   'false', '4'),

  -- item 06 — bibliothèques d'objets (bonne réponse : position 4)
  ('11111111-c014-2100-0000-000000000006', '11111111-c014-1000-0000-000000000006',
   'Le prêt d''objets entre habitants s''est imposé comme un modèle économiquement rentable',
   'false', '1'),

  ('11111111-c014-2200-0000-000000000006', '11111111-c014-1000-0000-000000000006',
   'Une perceuse ne sert en moyenne que douze minutes dans toute sa vie',
   'false', '2'),

  ('11111111-c014-2300-0000-000000000006', '11111111-c014-1000-0000-000000000006',
   'Les ménages aux budgets serrés sont les principaux usagers des bibliothèques d''objets',
   'false', '3'),

  ('11111111-c014-2400-0000-000000000006', '11111111-c014-1000-0000-000000000006',
   'Les bibliothèques d''objets ne pèseront sur la consommation que si elles touchent un public au-delà des convertis',
   'true', '4'),

  -- item 07 — injonction « consommer mieux » (bonne réponse : position 1)
  ('11111111-c014-2100-0000-000000000007', '11111111-c014-1000-0000-000000000007',
   'Il reconnaît le poids des choix individuels mais dénonce un transfert de responsabilité vers les consommateurs',
   'true', '1'),

  ('11111111-c014-2200-0000-000000000007', '11111111-c014-1000-0000-000000000007',
   'Il considère que les comportements individuels n''ont aucune importance dans la consommation',
   'false', '2'),

  ('11111111-c014-2300-0000-000000000007', '11111111-c014-1000-0000-000000000007',
   'Il félicite les enseignes d''encourager enfin leurs clients à consommer mieux',
   'false', '3'),

  ('11111111-c014-2400-0000-000000000007', '11111111-c014-1000-0000-000000000007',
   'Il impute la surconsommation aux seuls choix des ménages dans leurs caddies',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c014-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « consommation responsable », 7 angles tous différents :
--     seconde main & effet rebond / prolifération des labels « durables » /
--     bonus réparation & réparabilité / recul de la vente en vrac /
--     efficacité des boycotts citoyens / bibliothèques d'objets (partage) /
--     injonction « consommer mieux » & responsabilité individuelle.
--     Aucun thème interdit (pas de famille, travail, environnement générique,
--     alimentation, énergie, etc. — chaque texte reste centré sur l'acte de
--     consommer de façon responsable).
-- [x] Textes B2 longs : 190 / 194 / 193 / 186 / 188 / 191 / 190 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (ex. « 40 millions d'annonces », « doublé… à partir de presque rien »,
--     « paquet emballé parfois moins cher », « pertes marginales »,
--     « douze minutes », discours rapporté au conditionnel).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2 (items 1, 5),
--     ce_inference_intention ×3 (items 2, 4, 6), ce_ton_auteur ×2 (items 3, 7).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme linguistique
--     nommé (concession rhétorique, inversion cause/effet, détail vrai mais
--     secondaire, sur-généralisation, discours rapporté ironique).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (prénoms, villes, chiffres
--     inventés : Olena à Besançon, Diego Ferrant, Quimper, Mulhouse, Valence,
--     Guéret, Mende, Bordeaux).
-- ============================================================================
