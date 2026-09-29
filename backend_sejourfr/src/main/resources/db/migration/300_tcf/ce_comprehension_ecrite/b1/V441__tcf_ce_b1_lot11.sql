-- ============================================================================
-- V441 — TCF CE B1 — lot 11 (support : avis / critique court)
-- ----------------------------------------------------------------------------
-- 10 items de compréhension écrite B1. Support unique : avis / critique court
-- (restaurant, application mobile, salon de coiffure, auto-école, roman,
-- camping, entreprise de déménagement, atelier de réparation de vélos, pièce
-- de théâtre, boutique en ligne). Passages TEXTE (~60-120 mots), questions +
-- choices (4 rows/question). theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty='B1', question_type='CE'. Données déterministes, rejouables
-- dev+recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-b00b-4000-0000-000000000001', 'TEXTE',
   '★★★★☆ — Restaurant Le Safran, Lyon — avis publié le 18 mai

Nous avons dîné au Safran samedi soir. Les plats sont délicieux, surtout le tajine d''agneau, et la salle est très chaleureuse. Seul point noir : nous avons attendu quarante-cinq minutes entre l''entrée et le plat. Le serveur s''est excusé et nous a offert les desserts, ce que j''ai trouvé très correct. Malgré cette attente, je recommande l''adresse : nous reviendrons, mais plutôt en semaine, quand il y a moins de monde.

Yuki',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00b-4000-0000-000000000002', 'TEXTE',
   '★★★☆☆ — Application ParloFacile — avis utilisateur

J''utilise ParloFacile depuis trois mois pour améliorer mon français. Les exercices de vocabulaire sont bien construits et la version gratuite suffit pour commencer. En revanche, tous les exercices de prononciation et les dialogues de niveau avancé sont réservés à l''abonnement payant, ce qui n''est pas indiqué clairement avant le téléchargement. En résumé : très utile si vous débutez, mais si vous avez déjà un bon niveau, vous serez vite limité sans payer.

Tarek',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00b-4000-0000-000000000003', 'TEXTE',
   '★★★☆☆ — Salon Boucle d''Or — avis publié il y a 2 jours

Je suis entrée sans rendez-vous un mardi après-midi et j''ai été installée en moins de dix minutes : très appréciable. La coupe est exactement ce que je voulais et la coiffeuse a pris le temps de me conseiller. Ma seule déception concerne le prix : un supplément « cheveux longs » de douze euros, jamais mentionné sur la vitrine ni avant le shampoing, est apparu sur le ticket. Je reviendrai, mais je demanderai le tarif complet avant de m''asseoir.

Carmen',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00b-4000-0000-000000000004', 'TEXTE',
   '★★★★★ — Auto-école du Canal — avis vérifié

Permis obtenu du premier coup la semaine dernière ! Mon moniteur, toujours patient, m''a fait refaire les créneaux jusqu''à ce qu''ils deviennent automatiques. Un seul défaut : le secrétariat est injoignable par téléphone, la ligne sonne souvent dans le vide. Un conseil pour les futurs élèves : réservez vos leçons directement sur l''application de l''auto-école, c''est confirmé en quelques minutes. Malgré ce détail, je recommande cette école sans hésiter.

Mamadou',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00b-4000-0000-000000000005', 'TEXTE',
   '★★★★☆ — « La Maison des marées », roman — critique de lectrice

J''avoue avoir failli abandonner ce roman : les cinquante premières pages, très lentes, multiplient les descriptions. Quelle erreur cela aurait été ! Dès que l''histoire de la famille Lemoine démarre vraiment, impossible de lâcher le livre : j''ai lu toute la seconde moitié en deux soirées. Les personnages, surtout la grand-mère, restent en tête longtemps après la dernière page. À conseiller aux lecteurs patients qui aiment les histoires de famille.

Ingrid',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00b-4000-0000-000000000006', 'TEXTE',
   '★★★☆☆ — Camping Les Embruns — séjour en famille

Séjour d''une semaine en août avec ma femme et nos deux enfants. Sanitaires impeccables, propriétaires charmants, et la piscine a fait le bonheur des petits. Attention cependant : l''annonce promet la plage « à cinq minutes », mais comptez vingt-cinq minutes de marche réelle, avec une route à traverser. Avec de jeunes enfants et le matériel de plage, c''est long : prévoyez la voiture pour vous y rendre. À part ce point, qui mériterait d''être corrigé sur le site, bon rapport qualité-prix.

Bohdan',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00b-4000-0000-000000000007', 'TEXTE',
   '★★★★★ — Déménagements Brizard — avis client

Équipe ponctuelle et soigneuse : tous nos cartons sont arrivés intacts au quatrième étage sans ascenseur. Une étagère a malheureusement été rayée pendant le transport. C''est justement là que cette entreprise se distingue : j''ai envoyé une photo le soir même, et le remboursement de la réparation est arrivé en moins d''une semaine, sans aucune discussion. Une société qui reconnaît ses erreurs et les corrige aussi vite, c''est rare. Je mets cinq étoiles sans hésiter.

Anjali',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00b-4000-0000-000000000008', 'TEXTE',
   '★★★★☆ — Atelier Vélocité — réparation de vélos

J''ai déposé mon vélo pour un problème de freins. Le réparateur a remarqué que le pneu arrière était très usé : avant de le changer, il m''a montré l''usure et m''a demandé mon accord, en m''annonçant le prix exact. Cette honnêteté change des ateliers qui facturent des réparations jamais demandées. Freins et pneu impeccables depuis trois semaines. Petit détail à connaître : l''atelier est fermé le lundi, vérifiez avant de vous déplacer.

Pavel',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00b-4000-0000-000000000009', 'TEXTE',
   '★★★☆☆ — « Un dimanche chez les Brun », comédie au théâtre du Phare

Vue samedi soir. La première partie est irrésistible : la salle entière riait, et la comédienne principale est remarquable de bout en bout. Après l''entracte, malheureusement, le rythme retombe et certaines scènes s''étirent inutilement : deux heures trente, c''est trop pour cette histoire. Je ne regrette pas ma soirée, mais une demi-heure de moins n''aurait rien enlevé au plaisir. Bon plan : le jeudi, les places sont à quinze euros au lieu de vingt-huit.

Aminata',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00b-4000-0000-00000000000a', 'TEXTE',
   '★★★★★ — Boutique en ligne Lumea.fr — avis après achat

Commandé une lampe de bureau le 2 mars, reçue le 5… avec le pied cassé, sans doute à cause du transport. J''ai écrit au service client en joignant une photo : réponse en moins d''une heure, nouvelle lampe expédiée gratuitement et reçue deux jours plus tard. On ne m''a même pas demandé de renvoyer l''article abîmé. Un problème peut arriver à n''importe quel vendeur ; ce qui compte, c''est la réaction. Ici, elle a été parfaite. Je commanderai à nouveau sans hésiter.

Leïla',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-b00b-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00b-4000-0000-000000000001',
   NULL, 'B1', 'CE',
   'Que faut-il retenir de l''avis de Yuki sur ce restaurant ?',
   'Yuki conclut : « Malgré cette attente, je recommande l''adresse : nous reviendrons ». La bonne réponse reformule cette **concession** (« malgré » + recommandation) : l''avis reste positif en dépit du service lent. La réponse A ne retient que le point noir et contredit « nous reviendrons ». La réponse C inverse les jugements : ce sont les plats qui sont « délicieux » et le service qui est lent, pas le contraire. La réponse D contredit le texte : les desserts ont été **offerts** en compensation, ils n''ont pas été facturés.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b00b-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00b-4000-0000-000000000002',
   NULL, 'B1', 'CE',
   'À qui Tarek conseille-t-il la version gratuite de l''application ?',
   'Tarek résume : « très utile si vous débutez, mais si vous avez déjà un bon niveau, vous serez vite limité sans payer ». C''est un **repérage explicite de la recommandation**, introduite par la condition « si vous débutez ». La réponse A sur-généralise : les utilisateurs avancés sont justement « vite limités » sans abonnement. La réponse B inverse le public visé par la version gratuite. La réponse C contredit le texte : les exercices de prononciation sont « réservés à l''abonnement payant », donc absents de l''offre gratuite.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00b-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00b-4000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Quel reproche Carmen fait-elle au salon de coiffure ?',
   'Carmen écrit : « un supplément « cheveux longs » de douze euros, jamais mentionné sur la vitrine ni avant le shampoing, est apparu sur le ticket ». Le **marqueur d''opinion « Ma seule déception »** isole ce reproche unique : un prix découvert au moment de payer. La réponse B contredit le début : elle a été installée « en moins de dix minutes ». La réponse C contredit « La coupe est exactement ce que je voulais ». La réponse D contredit « la coiffeuse a pris le temps de me conseiller » — le distracteur retourne chaque compliment du texte en critique.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00b-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00b-4000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Que conseille Mamadou aux futurs élèves de l''auto-école ?',
   'Mamadou écrit : « réservez vos leçons directement sur l''application de l''auto-école », phrase annoncée par « Un conseil pour les futurs élèves ». C''est un **repérage explicite du conseil**, signalé par l''impératif. La réponse A contredit le texte : le secrétariat est « injoignable par téléphone », la ligne « sonne dans le vide ». La réponse B invente un problème : Mamadou a eu son permis « du premier coup » et loue la patience de son moniteur. La réponse D inverse la conclusion : « je recommande cette école sans hésiter », il ne conseille pas d''aller ailleurs.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00b-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00b-4000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Quelle est l''opinion d''Ingrid sur ce roman ?',
   'Ingrid raconte avoir « failli abandonner » à cause d''un début « très lent », puis avoir « lu toute la seconde moitié en deux soirées ». La bonne réponse **reformule ce contraste avant/après**, marqué par « Dès que… impossible de lâcher le livre ». La réponse A confond « failli abandonner » (action non réalisée — le verbe **faillir** exprime ce qui a presque eu lieu) avec un abandon réel. La réponse C ne retient que les cinquante premières pages et ignore le renversement. La réponse D inverse la recommandation finale : le roman est conseillé aux lecteurs « qui aiment les histoires de famille ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b00b-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00b-4000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Sur quel point l''annonce du camping est-elle inexacte, selon Bohdan ?',
   'Bohdan prévient : « l''annonce promet la plage « à cinq minutes », mais comptez vingt-cinq minutes de marche réelle ». Le **connecteur d''opposition « mais »** confronte la promesse de l''annonce à la réalité : seule la distance jusqu''à la plage est inexacte. La réponse A contredit « Sanitaires impeccables ». La réponse B contredit le texte : la piscine existe bien et « a fait le bonheur des petits ». La réponse C contredit la conclusion « bon rapport qualité-prix » : le prix n''est jamais mis en cause dans cet avis.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00b-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00b-4000-0000-000000000007',
   NULL, 'B1', 'CE',
   'Pourquoi Anjali attribue-t-elle la note maximale à l''entreprise ?',
   'Anjali écrit : « C''est justement là que cette entreprise se distingue » à propos du remboursement « en moins d''une semaine, sans aucune discussion ». Par **inférence d''intention**, la note maximale s''explique par la gestion exemplaire de l''incident, pas par un déménagement sans faute. La réponse B contredit le texte : une étagère « a malheureusement été rayée ». La réponse C invente une gratuité jamais évoquée : seul le coût de la **réparation** a été remboursé, pas le déménagement. La réponse D déforme la solution : l''entreprise a remboursé la réparation, elle n''a rien réparé sur place.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b00b-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00b-4000-0000-000000000008',
   NULL, 'B1', 'CE',
   'Qu''est-ce que Pavel a particulièrement apprécié à l''atelier ?',
   'Pavel raconte : « avant de le changer, il m''a montré l''usure et m''a demandé mon accord, en m''annonçant le prix exact », puis salue « cette honnêteté ». La bonne réponse **reformule cette transparence** : l''accord du client est demandé avant la réparation supplémentaire. La réponse A contredit l''avertissement final : « l''atelier est fermé le lundi ». La réponse B invente une gratuité : le prix du pneu a été annoncé puis facturé, rien n''est offert. La réponse D inverse exactement le comportement décrit — piège de **négation du fait** : le réparateur a justement prévenu avant d''agir.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b00b-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00b-4000-0000-000000000009',
   NULL, 'B1', 'CE',
   'Que pense Aminata de cette pièce de théâtre ?',
   'Aminata oppose une première partie « irrésistible » à une seconde où « le rythme retombe », puis écrit : « Je ne regrette pas ma soirée, mais une demi-heure de moins n''aurait rien enlevé au plaisir ». Par **inférence simple**, on relie ces deux éléments : bilan positif avec une réserve sur la durée (« deux heures trente, c''est trop »). La réponse A ne garde que la critique et ignore les rires de la première partie. La réponse C contredit « la comédienne principale est remarquable de bout en bout ». La réponse D inverse la comparaison : c''est la première partie qui est réussie, la seconde qui s''étire.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b00b-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00b-4000-0000-00000000000a',
   NULL, 'B1', 'CE',
   'Pourquoi Leïla garde-t-elle confiance dans cette boutique en ligne ?',
   'Leïla insiste : « ce qui compte, c''est la réaction. Ici, elle a été parfaite », après une « nouvelle lampe expédiée gratuitement et reçue deux jours plus tard ». Par **inférence d''intention**, sa confiance repose sur la qualité du service client, pas sur la livraison initiale. La réponse A contredit le texte : la lampe est arrivée « avec le pied cassé ». La réponse B confond **remplacement et remboursement** : une nouvelle lampe a été envoyée, aucun remboursement n''est mentionné. La réponse D invente un acteur : le transporteur ne s''exprime jamais, c''est la boutique qui a réagi.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- Q01 — restaurant Le Safran (bonne réponse : position 2)
  ('11111111-b00b-2100-0000-000000000001', '11111111-b00b-1000-0000-000000000001',
   'Elle ne reviendra pas au restaurant à cause de l''attente',
   'false', '1'),
  ('11111111-b00b-2200-0000-000000000001', '11111111-b00b-1000-0000-000000000001',
   'Elle recommande le restaurant malgré un service trop lent',
   'true', '2'),
  ('11111111-b00b-2300-0000-000000000001', '11111111-b00b-1000-0000-000000000001',
   'Elle a trouvé le service rapide mais les plats décevants',
   'false', '3'),
  ('11111111-b00b-2400-0000-000000000001', '11111111-b00b-1000-0000-000000000001',
   'Elle a dû payer un supplément pour les desserts',
   'false', '4'),

  -- Q02 — application ParloFacile (bonne réponse : position 4)
  ('11111111-b00b-2100-0000-000000000002', '11111111-b00b-1000-0000-000000000002',
   'À tous les utilisateurs, quel que soit leur niveau',
   'false', '1'),
  ('11111111-b00b-2200-0000-000000000002', '11111111-b00b-1000-0000-000000000002',
   'Aux apprenants qui ont déjà un niveau avancé',
   'false', '2'),
  ('11111111-b00b-2300-0000-000000000002', '11111111-b00b-1000-0000-000000000002',
   'À ceux qui veulent surtout travailler la prononciation',
   'false', '3'),
  ('11111111-b00b-2400-0000-000000000002', '11111111-b00b-1000-0000-000000000002',
   'Aux personnes qui débutent en français',
   'true', '4'),

  -- Q03 — salon Boucle d''Or (bonne réponse : position 1)
  ('11111111-b00b-2100-0000-000000000003', '11111111-b00b-1000-0000-000000000003',
   'Un supplément de prix découvert seulement au moment de payer',
   'true', '1'),
  ('11111111-b00b-2200-0000-000000000003', '11111111-b00b-1000-0000-000000000003',
   'Une attente trop longue avant d''être coiffée',
   'false', '2'),
  ('11111111-b00b-2300-0000-000000000003', '11111111-b00b-1000-0000-000000000003',
   'Une coupe différente de celle qu''elle avait demandée',
   'false', '3'),
  ('11111111-b00b-2400-0000-000000000003', '11111111-b00b-1000-0000-000000000003',
   'Une coiffeuse pressée qui ne donne aucun conseil',
   'false', '4'),

  -- Q04 — auto-école du Canal (bonne réponse : position 3)
  ('11111111-b00b-2100-0000-000000000004', '11111111-b00b-1000-0000-000000000004',
   'De téléphoner au secrétariat pour réserver leurs leçons',
   'false', '1'),
  ('11111111-b00b-2200-0000-000000000004', '11111111-b00b-1000-0000-000000000004',
   'De changer de moniteur avant de passer l''examen',
   'false', '2'),
  ('11111111-b00b-2300-0000-000000000004', '11111111-b00b-1000-0000-000000000004',
   'De réserver leurs leçons sur l''application de l''auto-école',
   'true', '3'),
  ('11111111-b00b-2400-0000-000000000004', '11111111-b00b-1000-0000-000000000004',
   'De s''inscrire dans une école plus facile à joindre',
   'false', '4'),

  -- Q05 — roman « La Maison des marées » (bonne réponse : position 2)
  ('11111111-b00b-2100-0000-000000000005', '11111111-b00b-1000-0000-000000000005',
   'Elle a abandonné sa lecture au bout de cinquante pages',
   'false', '1'),
  ('11111111-b00b-2200-0000-000000000005', '11111111-b00b-1000-0000-000000000005',
   'Le début l''a déçue, mais la suite l''a passionnée',
   'true', '2'),
  ('11111111-b00b-2300-0000-000000000005', '11111111-b00b-1000-0000-000000000005',
   'Elle a trouvé le livre ennuyeux du début à la fin',
   'false', '3'),
  ('11111111-b00b-2400-0000-000000000005', '11111111-b00b-1000-0000-000000000005',
   'Elle le déconseille aux amateurs d''histoires de famille',
   'false', '4'),

  -- Q06 — camping Les Embruns (bonne réponse : position 4)
  ('11111111-b00b-2100-0000-000000000006', '11111111-b00b-1000-0000-000000000006',
   'La propreté des sanitaires',
   'false', '1'),
  ('11111111-b00b-2200-0000-000000000006', '11111111-b00b-1000-0000-000000000006',
   'La présence d''une piscine pour les enfants',
   'false', '2'),
  ('11111111-b00b-2300-0000-000000000006', '11111111-b00b-1000-0000-000000000006',
   'Le prix du séjour en août',
   'false', '3'),
  ('11111111-b00b-2400-0000-000000000006', '11111111-b00b-1000-0000-000000000006',
   'Le temps nécessaire pour rejoindre la plage à pied',
   'true', '4'),

  -- Q07 — déménagements Brizard (bonne réponse : position 1)
  ('11111111-b00b-2100-0000-000000000007', '11111111-b00b-1000-0000-000000000007',
   'Parce que l''entreprise a réglé l''incident vite et sans discuter',
   'true', '1'),
  ('11111111-b00b-2200-0000-000000000007', '11111111-b00b-1000-0000-000000000007',
   'Parce qu''aucun meuble n''a été abîmé pendant le transport',
   'false', '2'),
  ('11111111-b00b-2300-0000-000000000007', '11111111-b00b-1000-0000-000000000007',
   'Parce que le déménagement ne lui a finalement rien coûté',
   'false', '3'),
  ('11111111-b00b-2400-0000-000000000007', '11111111-b00b-1000-0000-000000000007',
   'Parce que les déménageurs ont réparé l''étagère sur place',
   'false', '4'),

  -- Q08 — atelier Vélocité (bonne réponse : position 3)
  ('11111111-b00b-2100-0000-000000000008', '11111111-b00b-1000-0000-000000000008',
   'L''ouverture de l''atelier tous les jours de la semaine',
   'false', '1'),
  ('11111111-b00b-2200-0000-000000000008', '11111111-b00b-1000-0000-000000000008',
   'Le changement de pneu offert par le réparateur',
   'false', '2'),
  ('11111111-b00b-2300-0000-000000000008', '11111111-b00b-1000-0000-000000000008',
   'L''accord demandé au client avant toute réparation supplémentaire',
   'true', '3'),
  ('11111111-b00b-2400-0000-000000000008', '11111111-b00b-1000-0000-000000000008',
   'Le remplacement du pneu effectué sans le prévenir',
   'false', '4'),

  -- Q09 — comédie au théâtre du Phare (bonne réponse : position 2)
  ('11111111-b00b-2100-0000-000000000009', '11111111-b00b-1000-0000-000000000009',
   'Elle s''est ennuyée du début à la fin du spectacle',
   'false', '1'),
  ('11111111-b00b-2200-0000-000000000009', '11111111-b00b-1000-0000-000000000009',
   'Elle a passé un bon moment, mais juge la pièce trop longue',
   'true', '2'),
  ('11111111-b00b-2300-0000-000000000009', '11111111-b00b-1000-0000-000000000009',
   'Elle trouve la comédienne principale décevante',
   'false', '3'),
  ('11111111-b00b-2400-0000-000000000009', '11111111-b00b-1000-0000-000000000009',
   'Elle préfère la seconde partie, plus rythmée que la première',
   'false', '4'),

  -- Q10 — boutique en ligne Lumea.fr (bonne réponse : position 3)
  ('11111111-b00b-2100-0000-00000000000a', '11111111-b00b-1000-0000-00000000000a',
   'Parce que sa commande est arrivée en parfait état',
   'false', '1'),
  ('11111111-b00b-2200-0000-00000000000a', '11111111-b00b-1000-0000-00000000000a',
   'Parce qu''elle a été intégralement remboursée de son achat',
   'false', '2'),
  ('11111111-b00b-2300-0000-00000000000a', '11111111-b00b-1000-0000-00000000000a',
   'Parce que le service client a remplacé la lampe très rapidement',
   'true', '3'),
  ('11111111-b00b-2400-0000-00000000000a', '11111111-b00b-1000-0000-00000000000a',
   'Parce que le transporteur s''est excusé pour la casse',
   'false', '4');

-- ============================================================================
-- CHECKLIST — contrôles passés
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (11111111-b00b-1000/4000/21..2400-…-NN, NN=01..0a).
-- [x] Support unique : avis / critique court (10 auteurs et objets tous
--     différents : restaurant, application de langue, salon de coiffure,
--     auto-école, roman, camping, entreprise de déménagement, atelier de
--     réparation de vélos, pièce de théâtre, boutique en ligne). Aucun support
--     réservé à un autre lot (pas d''e-mail, forum, article, annonce, etc.).
-- [x] Passages TEXTE ~60-120 mots, mise en forme avis réaliste (note en
--     étoiles, objet de l''avis, corps, signature), media_id NULL.
-- [x] 4 propositions / 1 correcte par item. Distribution des bonnes réponses :
--     pos1:2, pos2:3, pos3:3, pos4:2 (max 3 par position, 4 positions utilisées).
-- [x] competence_code : ce_reperage_explicite x4 (Q2, Q3, Q4, Q6),
--     ce_reformulation x3 (Q1, Q5, Q8), ce_inference_intention x3 (Q7, Q9, Q10).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3 distracteurs
--     expliqués, point clé en **gras**, mécanisme linguistique nommé (concession,
--     connecteur d''opposition, verbe faillir, inférence d''intention,
--     remplacement vs remboursement, négation du fait…).
-- [x] Pièges = confusion entre deux infos proches du texte (cause vs objet,
--     promesse vs réalité, détail vs bilan, compliment retourné en critique).
-- [x] Pas de SVG ni SSML dans ce lot (supports textuels uniquement) — rien à
--     équilibrer.
-- [x] Apostrophes SQL doublées partout, contenu 100% original, items autonomes.
-- ============================================================================
