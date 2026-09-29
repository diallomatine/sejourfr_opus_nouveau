-- ============================================================================
-- V467 — TCF CE B2 — lot 07 (thème : économie & consommation)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty = 'B2'. 7 items, textes longs (~194-211 mots), compréhension
-- implicite (idée principale, inférence d'intention, ton de l'auteur).
-- Angles : réduflation / paiement fractionné / économie de l'abonnement /
-- tarification dynamique / fausses promotions / paradoxe de l'épargne /
-- modèle low-cost.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-c007-4000-0000-000000000001', 'TEXTE',
   'Le pot de pâte à tartiner trône toujours au même rayon, dans le même emballage et au même prix. Seule la balance trahit le subterfuge : il pèse désormais 350 grammes au lieu de 400. Cette pratique, baptisée « réduflation », consiste à réduire discrètement la quantité d''un produit tout en maintenant son prix, ce qui équivaut à une hausse masquée pouvant dépasser dix pour cent.

Les industriels se défendent en invoquant la flambée de leurs coûts, qu''il faudrait bien répercuter quelque part. L''argument serait recevable si la démarche était transparente ; or tout, dans la réduflation, est conçu pour que le client ne s''aperçoive de rien. L''emballage conserve son format, l''étiquette son graphisme ; seule la mention du poids, en petits caractères, est modifiée.

Depuis l''an dernier, les grandes surfaces ont l''obligation de signaler ces réductions de contenance par une affichette, pendant deux mois. Le dispositif a le mérite d''exister, mais sa portée reste limitée : il ne s''applique ni aux petits commerces ni à la vente en ligne, et rien n''interdit de réduire encore le format une fois le délai écoulé. Tant que la transparence dépendra du bon vouloir des fabricants, le consommateur continuera de payer plus cher sans le savoir.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c007-4000-0000-000000000002', 'TEXTE',
   '« Payez en quatre fois, sans frais. » La promesse s''affiche désormais sur la moindre boutique en ligne, pour un canapé comme pour une paire de baskets à soixante euros. En cinq ans, le paiement fractionné a conquis plus de dix millions d''utilisateurs en France, séduits par une simplicité déconcertante : quelques clics suffisent, sans justificatif de revenus ni vérification approfondie.

C''est précisément cette facilité qui inquiète les associations de consommateurs. Juridiquement, un paiement étalé sur moins de quatre-vingt-dix jours n''est pas considéré comme un crédit : il échappe donc aux protections prévues pour les emprunteurs, comme l''étude de solvabilité. Aucun fichier ne recense ces mini-dettes, si bien qu''un même client peut en accumuler chez dix enseignes différentes sans que personne ne s''en aperçoive. Et si le service est bien gratuit tant que les échéances sont honorées, le premier incident déclenche des pénalités qui, elles, n''ont rien de symbolique.

Une directive européenne, applicable l''an prochain, imposera enfin une vérification de solvabilité. Les acteurs du secteur jurent qu''ils n''ont jamais souhaité endetter qui que ce soit. Peut-être. Mais un outil conçu pour lever toutes les hésitations à l''achat ne saurait être tenu pour un simple service neutre : c''est un accélérateur de dépenses, et il serait temps de le réguler comme tel.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c007-4000-0000-000000000003', 'TEXTE',
   'Musique, séries, presse, repas livrés, logiciels, voitures et jusqu''aux lames de rasoir : tout, désormais, se loue au mois. Selon une étude du cabinet Mersenne, un foyer français paie en moyenne quatorze abonnements, pour un total qu''il estime à soixante-dix euros mensuels — alors que la dépense réelle dépasse cent trente euros. Cet écart de presque moitié n''est pas un détail : il est le cœur du modèle.

Car l''abonnement ne vend pas seulement un service : il vend de l''oubli. De petits montants prélevés sans douleur, des reconductions automatiques, des offres d''essai qui basculent en silence vers le plein tarif. Les entreprises connaissent parfaitement la proportion d''abonnés « dormants », qui paient sans consommer ; certaines plateformes de sport en ligne bâtissent même leur rentabilité sur eux. À l''inverse, résilier relève souvent du parcours d''obstacles : numéro surtaxé, horaires restreints, conseiller chargé de vous retenir.

La loi impose désormais un bouton de résiliation « en trois clics », mais uniquement pour les contrats souscrits en ligne, et les enseignes rivalisent d''imagination pour le rendre introuvable. On aurait tort de n''y voir qu''une question de confort : un modèle économique qui prospère sur l''inattention de ses clients ne mérite pas qu''on le qualifie de service.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c007-4000-0000-000000000004', 'TEXTE',
   'Réserver un billet de train le mardi soir plutôt que le mercredi matin peut désormais coûter trente euros de plus. Longtemps réservée aux compagnies aériennes, qui la pratiquent depuis trois décennies, la tarification dynamique — des prix recalculés en permanence selon la demande — s''étend aux trains, aux concerts, aux parcs d''attractions et même à certains cinémas.

Sur le papier, la logique se défend. Moduler les prix permet de remplir les heures creuses, d''éviter le gaspillage de sièges vides et d''offrir de vraies bonnes affaires à ceux qui peuvent voyager à contretemps. Les économistes y voient un outil d''efficacité, et ils n''ont pas tort.

Le problème n''est donc pas le principe, mais son exécution. Les algorithmes qui fixent ces tarifs sont des boîtes noires : nul ne sait si le prix affiché reflète la demande, l''historique de navigation ou la simple audace du vendeur. Le consommateur, lui, perd tout repère ; acheter un billet devient un pari, et l''angoisse de payer plus cher que son voisin s''installe à chaque réservation.

Exiger l''affichage d''un prix plancher et d''un prix plafond, comme le proposent plusieurs associations, ne tuerait pas le modèle : cela le rendrait simplement honnête. L''efficacité économique n''a jamais dispensé de la transparence.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c007-4000-0000-000000000005', 'TEXTE',
   'Moins quarante pour cent, ventes flash, prix barrés, « offre exceptionnelle » prolongée de semaine en semaine : dans certaines enseignes, plus de la moitié des articles sont affichés en promotion permanente. Le rabais, conçu à l''origine comme un événement, est devenu le décor ordinaire du commerce. Et c''est précisément là que le bât blesse : quand tout est en solde, plus rien ne l''est.

Le droit européen a pourtant tenté d''assainir le terrain : depuis 2022, un prix barré doit correspondre au tarif le plus bas pratiqué au cours des trente jours précédents. La règle a fait reculer les remises fictives les plus grossières, mais les contournements ont fleuri aussitôt : comparaison avec un « prix conseillé » fixé par le fabricant, remises dites de lancement, promotions calculées sur des produits jamais vendus au prix fort. Les services de la répression des fraudes l''admettent eux-mêmes : les contrôles ne suivent pas le rythme des inventions du marketing.

La conséquence la plus grave n''est pourtant pas juridique. À force d''être bombardé de rabais, le consommateur a perdu toute idée de ce que valent réellement les choses. Combien coûte « vraiment » un téléviseur, une veste, un matelas ? Personne ne le sait plus, et c''est bien le but : un client privé de repères n''achète plus un prix, il achète l''illusion d''une bonne affaire.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c007-4000-0000-000000000006', 'TEXTE',
   'Le paradoxe intrigue les économistes : alors que les prix ont augmenté plus vite que les salaires pendant trois ans, les Français n''ont jamais autant épargné. Le taux d''épargne des ménages frôle dix-huit pour cent du revenu disponible, un niveau inédit depuis quarante ans, loin devant la moyenne européenne.

Faut-il y voir le signe d''une aisance retrouvée ? Ce serait une lecture trompeuse. Cette montagne d''épargne est d''abord une épargne de peur : peur du chômage, des réformes à venir, d''une retraite incertaine. Les ménages mettent de côté non parce qu''ils le peuvent, mais parce qu''ils s''inquiètent. Surtout, la moyenne dissimule un gouffre : l''essentiel des sommes est accumulé par les vingt pour cent les plus aisés, pendant qu''un tiers des foyers déclare puiser dans ses réserves, quand il en a, pour boucler ses fins de mois. Parler du « bas de laine des Français » au singulier relève donc de la fiction statistique.

Ce diagnostic n''est pas qu''une querelle de chiffres. Tant que les pouvoirs publics liront ce taux record comme une réserve de croissance qu''il suffirait de « libérer » par des incitations à consommer, ils se tromperont de cible : on ne convainc pas de dépenser des ménages qui n''ont rien de côté, ni de rassurer par décret ceux qui épargnent par inquiétude.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-c007-4000-0000-000000000007', 'TEXTE',
   'Vols à dix-neuf euros, abonnements de salle de sport à moins de vingt euros, coupes de cheveux à dix euros : en vingt ans, le low-cost a conquis des pans entiers de la consommation. Qu''on le déplore ou qu''on s''en réjouisse, un constat s''impose : des millions de personnes accèdent désormais à des services dont les tarifs classiques les excluaient. Réduire ce modèle à une simple dégradation de la qualité serait donc injuste.

Encore faut-il regarder le prix de près. Car le tarif d''appel n''est que la porte d''entrée d''un édifice savamment construit : bagage facturé en supplément, choix du siège payant, frais de dossier, assurance ajoutée par défaut, résiliation moyennant indemnité. Une enquête de l''association Clairvue, menée sur trois cents réservations, montre qu''un billet d''avion affiché à vingt-cinq euros revient en moyenne à soixante-huit euros une fois l''achat finalisé. Le client moyen ne compare que les prix d''appel ; c''est exactement ce sur quoi parient les enseignes.

Le low-cost a donc gagné sa place, et personne ne propose sérieusement de l''interdire. Mais son pacte implicite — un prix réduit contre un service réduit — ne tient que si le prix annoncé est sincère. Imposer l''affichage du coût total dès la première page ne serait pas brider la concurrence : ce serait lui rendre son sens.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-c007-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c007-4000-0000-000000000001',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale défendue par l''auteur ?',
   'L''auteur conclut : « le consommateur continuera de payer plus cher sans le savoir » tant que la transparence dépendra des fabricants. **L''idée principale : la réduflation est une hausse déguisée que l''encadrement actuel ne parvient pas à enrayer.** La réponse A déforme le dispositif légal : les grandes surfaces doivent seulement signaler la pratique pendant deux mois, elle n''est pas interdite. La réponse B inverse le ton : l''argument des coûts « serait recevable si la démarche était transparente », c''est une concession aussitôt retournée. La réponse D promeut un détail déformé : la vente en ligne échappe à l''obligation d''affichage, le texte n''en fait pas le principal canal. Mécanisme : distinguer la **thèse défendue** d''une concession rhétorique et d''un détail secondaire.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c007-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c007-4000-0000-000000000002',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur le paiement fractionné ?',
   'Le texte montre qu''« aucun fichier ne recense ces mini-dettes » et que ce paiement « échappe aux protections prévues pour les emprunteurs » : **sa facilité d''accès masque un endettement qu''aucun dispositif ne mesure aujourd''hui**. La réponse B inverse l''information clé : étalé sur moins de quatre-vingt-dix jours, il n''est justement PAS considéré comme un crédit. La réponse C contredit un détail-piège : le service « est bien gratuit tant que les échéances sont honorées », les pénalités ne tombent qu''au premier incident. La réponse D confond présent et futur : la directive européenne sera applicable « l''an prochain », rien n''est encore imposé. Mécanisme : **inférence de l''idée centrale** face à des distracteurs en inversion et en anticipation de temporalité.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c007-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c007-4000-0000-000000000003',
   NULL, 'B2', 'CE',
   'Quelle est l''intention principale de l''auteur de ce texte ?',
   'L''auteur affirme que l''abonnement « vend de l''oubli » et conclut qu''un « modèle économique qui prospère sur l''inattention de ses clients ne mérite pas qu''on le qualifie de service » : **son intention est de dénoncer un modèle fondé sur l''oubli et l''inertie des abonnés**. La réponse A invente un conseil absent : l''auteur ne recommande jamais de tout résilier. La réponse B inverse son jugement : le bouton « trois clics » est présenté comme limité aux contrats en ligne et contourné par les enseignes, pas comme une protection suffisante. La réponse C contredit le chiffre-piège : les foyers estiment soixante-dix euros une dépense réelle de plus de cent trente, ils la sous-estiment de moitié. Mécanisme : **inférence d''intention** à partir de la conclusion, contre des distracteurs en inversion.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c007-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c007-4000-0000-000000000004',
   NULL, 'B2', 'CE',
   'Que pense l''auteur de la tarification dynamique ?',
   'L''auteur concède que « la logique se défend » et que les économistes « n''ont pas tort », avant de cibler « son exécution » : des algorithmes en « boîtes noires ». **Sa position : il admet la logique économique mais dénonce l''opacité des prix pour le consommateur.** La réponse A sur-étend la critique : il propose d''encadrer (prix plancher et plafond), jamais d''interdire — « cela le rendrait simplement honnête ». La réponse C contredit un détail-piège : les compagnies aériennes pratiquent cette tarification « depuis trois décennies », elle n''est pas née avec les concerts. La réponse D inverse le texte : nul ne sait si le prix reflète la demande ou « la simple audace du vendeur ». Mécanisme : repérer le **mouvement concessif** (le principe se défend… mais) qui signale un jugement nuancé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('11111111-c007-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c007-4000-0000-000000000005',
   NULL, 'B2', 'CE',
   'Quelle est l''idée principale de ce texte ?',
   'Le dernier paragraphe porte la thèse : « le consommateur a perdu toute idée de ce que valent réellement les choses » et achète « l''illusion d''une bonne affaire ». **L''idée principale : la banalisation des promotions a détruit tout repère sur la valeur réelle des produits.** La réponse B promeut un détail déformé : la règle de 2022 a fait reculer les remises « les plus grossières », mais les contournements ont aussitôt fleuri — elle n''a pas mis fin aux remises fictives. La réponse C est une invention par sur-généralisation : des articles « affichés en promotion » ne sont pas vendus à perte. La réponse D inverse l''aveu des autorités : les contrôles « ne suivent pas le rythme » du marketing. Mécanisme : résister au **détail vrai mais secondaire** promu en idée principale.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('11111111-c007-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c007-4000-0000-000000000006',
   NULL, 'B2', 'CE',
   'Qu''apprend-on dans ce texte sur l''épargne des ménages français ?',
   'Le texte affirme que « la moyenne dissimule un gouffre » et que cette épargne est « d''abord une épargne de peur » : **le taux record masque de fortes inégalités et traduit surtout une inquiétude**, ce que la bonne réponse synthétise. La réponse A reprend l''hypothèse explicitement écartée : y voir une « aisance retrouvée » serait « une lecture trompeuse ». La réponse C inverse un détail-piège : un tiers des foyers « puise dans ses réserves » pour boucler ses fins de mois, il n''épargne pas davantage. La réponse D contredit la conclusion : les incitations à consommer sont précisément la mauvaise cible selon l''auteur. Mécanisme : **inférence globale** — relier le paradoxe initial à son explication, contre des distracteurs en inversion et en sur-généralisation de la moyenne.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-c007-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-c007-4000-0000-000000000007',
   NULL, 'B2', 'CE',
   'Comment l''auteur se positionne-t-il face au modèle low-cost ?',
   'L''auteur concède que le low-cost a ouvert des services « dont les tarifs classiques excluaient » des millions de personnes, puis objecte que son « pacte implicite ne tient que si le prix annoncé est sincère » : **il en reconnaît l''apport mais exige la sincérité du prix affiché**. La réponse A sur-étend le propos : « personne ne propose sérieusement de l''interdire », et l''auteur réclame un affichage du coût total, pas une interdiction. La réponse B reprend la thèse explicitement rejetée : réduire ce modèle à une dégradation de la qualité « serait injuste ». La réponse D transforme une moyenne (vingt-cinq euros affichés, soixante-huit payés) en règle absolue avec « toujours », et le texte ne compare pas ce total aux enseignes classiques. Mécanisme : **mouvement concessif** (apport reconnu… mais) exprimant un jugement nuancé, contre des distracteurs en sur-généralisation.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- item 01 — réduflation (bonne réponse : position 3)
  ('11111111-c007-2100-0000-000000000001', '11111111-c007-1000-0000-000000000001',
   'La réduflation est désormais interdite dans les grandes surfaces françaises',
   'false', '1'),

  ('11111111-c007-2200-0000-000000000001', '11111111-c007-1000-0000-000000000001',
   'La hausse des coûts des industriels justifie pleinement la réduction des formats',
   'false', '2'),

  ('11111111-c007-2300-0000-000000000001', '11111111-c007-1000-0000-000000000001',
   'La réduflation est une hausse de prix déguisée que l''encadrement actuel ne parvient pas à enrayer',
   'true', '3'),

  ('11111111-c007-2400-0000-000000000001', '11111111-c007-1000-0000-000000000001',
   'La vente en ligne est devenue le principal canal de diffusion de la réduflation',
   'false', '4'),

  -- item 02 — paiement fractionné (bonne réponse : position 1)
  ('11111111-c007-2100-0000-000000000002', '11111111-c007-1000-0000-000000000002',
   'Sa facilité d''accès masque un risque d''endettement qu''aucun dispositif ne mesure aujourd''hui',
   'true', '1'),

  ('11111111-c007-2200-0000-000000000002', '11111111-c007-1000-0000-000000000002',
   'Il est juridiquement traité comme un crédit, avec les protections prévues pour les emprunteurs',
   'false', '2'),

  ('11111111-c007-2300-0000-000000000002', '11111111-c007-1000-0000-000000000002',
   'Des pénalités s''appliquent dès la souscription, même sans incident de paiement',
   'false', '3'),

  ('11111111-c007-2400-0000-000000000002', '11111111-c007-1000-0000-000000000002',
   'Une directive européenne a déjà imposé une vérification de solvabilité aux enseignes',
   'false', '4'),

  -- item 03 — économie de l'abonnement (bonne réponse : position 4)
  ('11111111-c007-2100-0000-000000000003', '11111111-c007-1000-0000-000000000003',
   'Conseiller aux foyers de résilier la totalité de leurs abonnements mensuels',
   'false', '1'),

  ('11111111-c007-2200-0000-000000000003', '11111111-c007-1000-0000-000000000003',
   'Saluer la résiliation en trois clics comme une protection désormais suffisante',
   'false', '2'),

  ('11111111-c007-2300-0000-000000000003', '11111111-c007-1000-0000-000000000003',
   'Montrer que les foyers connaissent précisément le montant total de leurs abonnements',
   'false', '3'),

  ('11111111-c007-2400-0000-000000000003', '11111111-c007-1000-0000-000000000003',
   'Dénoncer un modèle économique qui prospère sur l''oubli et l''inertie des abonnés',
   'true', '4'),

  -- item 04 — tarification dynamique (bonne réponse : position 2)
  ('11111111-c007-2100-0000-000000000004', '11111111-c007-1000-0000-000000000004',
   'Il réclame son interdiction pure et simple au nom de l''égalité entre consommateurs',
   'false', '1'),

  ('11111111-c007-2200-0000-000000000004', '11111111-c007-1000-0000-000000000004',
   'Il en admet la logique économique mais dénonce l''opacité des prix pour le consommateur',
   'true', '2'),

  ('11111111-c007-2300-0000-000000000004', '11111111-c007-1000-0000-000000000004',
   'Il présente cette pratique comme une invention récente des vendeurs de billets de concert',
   'false', '3'),

  ('11111111-c007-2400-0000-000000000004', '11111111-c007-1000-0000-000000000004',
   'Il estime que les algorithmes garantissent un prix fidèle au niveau réel de la demande',
   'false', '4'),

  -- item 05 — fausses promotions (bonne réponse : position 1)
  ('11111111-c007-2100-0000-000000000005', '11111111-c007-1000-0000-000000000005',
   'La banalisation des promotions a fait perdre aux consommateurs tout repère sur la valeur réelle des produits',
   'true', '1'),

  ('11111111-c007-2200-0000-000000000005', '11111111-c007-1000-0000-000000000005',
   'La réglementation européenne de 2022 a mis fin aux remises fictives dans le commerce',
   'false', '2'),

  ('11111111-c007-2300-0000-000000000005', '11111111-c007-1000-0000-000000000005',
   'Les enseignes vendent désormais la majorité de leurs articles à perte',
   'false', '3'),

  ('11111111-c007-2400-0000-000000000005', '11111111-c007-1000-0000-000000000005',
   'Les services de répression des fraudes ont adapté leurs contrôles aux inventions du marketing',
   'false', '4'),

  -- item 06 — paradoxe de l'épargne (bonne réponse : position 2)
  ('11111111-c007-2100-0000-000000000006', '11111111-c007-1000-0000-000000000006',
   'L''aisance financière retrouvée des ménages explique le niveau record de l''épargne',
   'false', '1'),

  ('11111111-c007-2200-0000-000000000006', '11111111-c007-1000-0000-000000000006',
   'Le taux d''épargne record masque de fortes inégalités et traduit surtout une inquiétude',
   'true', '2'),

  ('11111111-c007-2300-0000-000000000006', '11111111-c007-1000-0000-000000000006',
   'Un tiers des foyers parvient à mettre davantage d''argent de côté chaque mois',
   'false', '3'),

  ('11111111-c007-2400-0000-000000000006', '11111111-c007-1000-0000-000000000006',
   'Des incitations à consommer suffiraient à transformer cette épargne en croissance',
   'false', '4'),

  -- item 07 — modèle low-cost (bonne réponse : position 3)
  ('11111111-c007-2100-0000-000000000007', '11111111-c007-1000-0000-000000000007',
   'Il demande son interdiction, le prix d''appel relevant selon lui de la publicité mensongère',
   'false', '1'),

  ('11111111-c007-2200-0000-000000000007', '11111111-c007-1000-0000-000000000007',
   'Il considère que le low-cost a dégradé la qualité de tous les services concernés',
   'false', '2'),

  ('11111111-c007-2300-0000-000000000007', '11111111-c007-1000-0000-000000000007',
   'Il en reconnaît l''apport pour l''accès aux services mais exige la sincérité du prix affiché',
   'true', '3'),

  ('11111111-c007-2400-0000-000000000007', '11111111-c007-1000-0000-000000000007',
   'Il affirme que le prix final rejoint toujours celui des enseignes classiques',
   'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (11111111-c007-1000/4000/21xx-…-NN, NN=01..07).
-- [x] Thème unique « économie & consommation », 7 angles tous différents :
--     réduflation (shrinkflation) / paiement fractionné (BNPL) / économie de
--     l'abonnement / tarification dynamique / fausses promotions (prix barrés) /
--     paradoxe de l'épargne des ménages / modèle low-cost et coûts cachés.
--     Aucun thème interdit (pas d'angle consommation responsable, emploi,
--     logement, alimentation, tourisme, énergie, numérique & vie privée…).
-- [x] Textes B2 longs : 197 / 206 / 194 / 198 / 211 / 207 / 209 mots
--     (tous dans la fourchette 150-280), denses, avec détail-piège
--     (ex. « gratuit tant que les échéances sont honorées », « depuis trois
--     décennies » pour l'aérien, remises « les plus grossières », un tiers
--     qui désépargne, moyenne 68 € vs « toujours »).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, max 2 par position).
-- [x] competence_code : ce_idee_principale ×2 (items 1, 5),
--     ce_inference_intention ×3 (items 2, 3, 6), ce_ton_auteur ×2 (items 4, 7).
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3
--     distracteurs réfutés, point clé en **gras**, mécanisme nommé
--     (mouvement concessif, inversion, sur-généralisation, détail vrai mais
--     secondaire, inférence d'intention, thèse vs concession).
-- [x] Apostrophes SQL doublées ('') partout ; pas de SVG/SSML (passages TEXTE,
--     media_id NULL) ; contenu 100 % original (cabinet Mersenne, association
--     Clairvue, chiffres inventés).
-- ============================================================================
