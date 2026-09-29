-- ============================================================================
-- V442 — TCF CE B1 — lot 12 (support : échange de messages)
-- ----------------------------------------------------------------------------
-- 10 items de compréhension écrite B1. Support unique : échange de messages
-- (conversation type SMS/messagerie entre deux personnes : match déplacé,
-- enfant à récupérer, écharpe oubliée, place de concert, pique-nique,
-- perceuse à emprunter, retard de train, colis à réceptionner, permis
-- obtenu, vélo prêté). Passages TEXTE (~60-120 mots), questions + choices
-- (4 rows/question). theme_id = 22222222-0000-0000-0000-000000000002,
-- difficulty='B1', question_type='CE'. Données déterministes, rejouables
-- dev+recette.
-- ============================================================================


-- passages — supports de lecture référencés par les questions ci-dessous
INSERT INTO passages
  (id, type, content, media_id, theme_id)
VALUES
  ('11111111-b00c-4000-0000-000000000001', 'TEXTE',
   'Sofia : Salut Amadou ! Mauvaise nouvelle : le terrain du parc est fermé samedi à cause des travaux.
Amadou : Ah non… On annule le match ?
Sofia : Non, j''ai réservé le gymnase Jaurès de 15 h à 17 h. Par contre, il faut des chaussures de salle, les crampons sont interdits.
Amadou : Pas de souci, j''en ai une paire. Je préviens les autres ?
Sofia : Oui, surtout Mehdi, il oublie tout ! Et dis-leur d''arriver à 14 h 45 pour s''échauffer.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00c-4000-0000-000000000002', 'TEXTE',
   'Lucia : Karim, ma voiture vient de tomber en panne sur le parking du supermarché. Le dépanneur n''arrive que dans une heure.
Karim : Oh non ! Tu as besoin de quelque chose ?
Lucia : Oui… Tu pourrais aller chercher Maya à l''école à 16 h 30 ? Je ne serai jamais à l''heure.
Karim : Bien sûr. Je la ramène chez vous ?
Lucia : Non, garde-la chez toi, je passerai la prendre vers 18 h. Je préviens la maîtresse que c''est toi qui viens.
Karim : Ça marche, ne t''inquiète pas.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00c-4000-0000-000000000003', 'TEXTE',
   'Wei : Coucou Nadia, je crois que j''ai oublié mon écharpe grise chez toi samedi soir.
Nadia : Oui, elle est sur le canapé ! Tu veux passer la chercher ?
Wei : Je ne peux pas cette semaine, je suis en formation à Lyon jusqu''à vendredi.
Nadia : Je peux la déposer dans ta boîte aux lettres demain, je passe devant chez toi pour aller au travail.
Wei : Elle est trop épaisse pour la boîte… Laisse-la plutôt à mon voisin du dessus, monsieur Costa, il est toujours là le matin.
Nadia : Parfait, je ferai ça demain vers 8 h.',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00c-4000-0000-000000000004', 'TEXTE',
   'Rachid : Bilal, tu fais quoi vendredi soir ? Mon frère est malade, il me reste une place pour le concert de jazz au théâtre municipal.
Bilal : Sérieux ? J''adorerais ! C''est à quelle heure ?
Rachid : 20 h 30, mais on se retrouve à 19 h 45 devant l''entrée, il y a toujours la queue.
Bilal : Je te dois combien pour la place ?
Rachid : Rien du tout, elle était déjà payée. Tu m''offriras un café à l''entracte !
Bilal : Avec plaisir. À vendredi alors !',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00c-4000-0000-000000000005', 'TEXTE',
   'Olena : Marta, pour le pique-nique de dimanche, tu avais prévu d''apporter une salade, c''est bien ça ?
Marta : Oui, une salade de riz. Pourquoi ?
Olena : Ana en apporte déjà deux… Est-ce que tu pourrais plutôt préparer un dessert ? Personne ne s''est proposé.
Marta : Pas de problème, je ferai un gâteau au chocolat. Il faut que j''apporte autre chose ?
Olena : Des gobelets si tu en as, j''ai oublié d''en acheter. On se retrouve toujours à midi à l''entrée du parc.
Marta : Noté !',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00c-4000-0000-000000000006', 'TEXTE',
   'Diego : Salut Hugo ! Dis-moi, tu aurais une perceuse à me prêter ? Je dois fixer des étagères avant l''arrivée de mes parents samedi.
Hugo : La mienne est cassée depuis cet été… Mais mon père en a une très bonne.
Diego : Tu crois qu''il accepterait ?
Hugo : Aucun souci, je déjeune chez lui dimanche, je peux te l''apporter dans la soirée.
Diego : Dimanche soir, c''est trop tard pour moi… Tant pis, je vais en louer une au magasin de bricolage.
Hugo : Bonne idée, c''est ce que fait mon voisin. Désolé !',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00c-4000-0000-000000000007', 'TEXTE',
   'Priya : Camille, catastrophe : mon train est bloqué en gare, on annonce quarante minutes de retard.
Camille : Oh non ! La séance commence à 18 h, tu n''y arriveras jamais…
Priya : Vas-y sans moi, ne rate pas le début. Je te rembourserai ta place si je n''arrive pas.
Camille : Hors de question d''y aller seule ! Il y a une autre séance à 20 h 15, je nous prends deux billets pour celle-là.
Priya : Tu es sûre ? Bon, d''accord. Je t''invite à manger un morceau avant, pour me faire pardonner.
Camille : Marché conclu !',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00c-4000-0000-000000000008', 'TEXTE',
   'Fatou : Léa, j''ai un service à te demander. Je reçois un colis demain entre 9 h et 13 h, mais je serai à l''hôpital toute la matinée pour des examens.
Léa : Rien de grave, j''espère ?
Fatou : Non, un simple contrôle, ne t''inquiète pas. Tu pourrais réceptionner le colis ? Le livreur peut sonner chez toi, je mets ton nom en contact.
Léa : Bien sûr ! Mais je pars au travail à 11 h 30… S''il passe après, il faudra voir avec le gardien.
Fatou : Je vais le prévenir aussi, comme ça on est sûres. Merci mille fois !',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00c-4000-0000-000000000009', 'TEXTE',
   'Marek : Anh, ça y est : j''ai eu mon permis de conduire ce matin, du premier coup !
Anh : Bravo !! Après tous ces mois de leçons, tu l''as bien mérité. Il faut fêter ça !
Marek : Carrément. Je vous invite, Sara et toi, à la crêperie du port. Vendredi soir, ça vous va ?
Anh : Vendredi je termine à 22 h, je suis de fermeture au restaurant… Samedi plutôt ?
Marek : Va pour samedi, 19 h 30. Je réserve une table pour trois.
Anh : Parfait. Et c''est toi qui conduis, maintenant !',
   NULL, '22222222-0000-0000-0000-000000000002'),

  ('11111111-b00c-4000-0000-00000000000a', 'TEXTE',
   'Aïcha : Tomas, mon vélo est encore chez le réparateur, et il ne sera prêt que jeudi prochain. Or je commence mon nouveau travail lundi…
Tomas : Et le bus ne passe pas près de chez toi ?
Aïcha : Si, mais il faut changer deux fois, presque une heure de trajet contre vingt minutes à vélo.
Tomas : Prends le mien ! Depuis que je vais au bureau à pied, il dort à la cave.
Aïcha : C''est vrai ? Tu me sauves ! Je te le rends jeudi soir, dès que je récupère le mien.
Tomas : Garde-le autant que tu veux, il ne me manque pas.',
   NULL, '22222222-0000-0000-0000-000000000002');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-b00c-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00c-4000-0000-000000000001',
   NULL, 'B1', 'CE',
   'Qu''est-ce qui change pour le match de samedi ?',
   'Sofia annonce : « le terrain du parc est fermé samedi » puis « j''ai réservé le gymnase Jaurès de 15 h à 17 h ». C''est un **repérage explicite du changement de lieu** : le match est maintenu mais déplacé en salle. La réponse A contredit l''échange : à la question « On annule le match ? », Sofia répond clairement « Non ». La réponse C confond le début et la fin du créneau : le gymnase est réservé « de 15 h à 17 h », le match ne commence donc pas à 17 h. La réponse D inverse la consigne : « les crampons sont interdits », il faut des chaussures de salle — piège classique d''**inversion d''une interdiction**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00c-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00c-4000-0000-000000000002',
   NULL, 'B1', 'CE',
   'Que demande Lucia à Karim ?',
   'Lucia demande : « Tu pourrais aller chercher Maya à l''école à 16 h 30 ? » puis précise « garde-la chez toi, je passerai la prendre vers 18 h ». **Repérage explicite de la demande** : récupérer l''enfant et la garder chez lui. La réponse A confond le problème et le service demandé : le dépanneur est déjà prévenu pour la panne, Karim n''a pas à intervenir sur le parking. La réponse B inverse les rôles : c''est Lucia qui dit « Je préviens la maîtresse ». La réponse C contredit la consigne : à « Je la ramène chez vous ? », Lucia répond « Non, garde-la chez toi » — le piège reprend la **proposition écartée dans le dialogue**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00c-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00c-4000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Comment Wei récupérera-t-il son écharpe ?',
   'La solution finale est posée par Wei : « Laisse-la plutôt à mon voisin du dessus, monsieur Costa », ce que Nadia confirme (« je ferai ça demain vers 8 h »). **Repérage explicite de la solution retenue**, introduite par « plutôt », adverbe qui écarte la proposition précédente. La réponse B reprend justement l''option abandonnée : l''écharpe est « trop épaisse pour la boîte » aux lettres. La réponse C est impossible : Wei est « en formation à Lyon jusqu''à vendredi », il ne peut pas passer cette semaine. La réponse D invente un déplacement : Nadia passe devant chez Wei pour aller au travail, elle ne va pas à Lyon — piège de **confusion entre deux lieux du texte**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00c-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00c-4000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Que propose Rachid à Bilal ?',
   'Rachid annonce une place libre (« Mon frère est malade, il me reste une place ») et précise « Rien du tout, elle était déjà payée ». La bonne réponse **reformule cette invitation gratuite** au concert de vendredi. La réponse A contredit le texte : Bilal propose de payer, Rachid refuse — il n''y a aucune vente. La réponse B confond la cause de la place libre (le frère malade) avec l''objet du message : personne ne parle de lui rendre visite. La réponse D déforme un détail : le café est prévu « à l''entracte » du concert, en guise de remerciement, pas comme une sortie séparée — piège de **détail déplacé hors de son contexte**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b00c-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00c-4000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Que demande Olena à Marta ?',
   'Olena demande : « Est-ce que tu pourrais plutôt préparer un dessert ? Personne ne s''est proposé ». **Repérage explicite du changement demandé** : un dessert à la place de la salade, car « Ana en apporte déjà deux ». La réponse A va à l''inverse de la demande : il y a déjà trop de salades, Marta ne doit plus en apporter. La réponse C déforme le second service : Olena demande des **gobelets** qu''elle a oublié d''acheter, pas des boissons — confusion entre deux objets proches du texte. La réponse D contredit la fin du message : « On se retrouve toujours à midi », l''adverbe « toujours » signale que l''horaire ne change pas.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-b00c-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00c-4000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Pourquoi Diego va-t-il finalement louer une perceuse ?',
   'Il faut relier deux informations : « La mienne est cassée depuis cet été » et la perceuse du père disponible seulement dimanche soir, alors que Diego doit fixer ses étagères « avant l''arrivée de mes parents samedi » (« Dimanche soir, c''est trop tard pour moi »). Par **inférence simple**, la location devient la seule solution à temps. La réponse A est fausse : Hugo ne refuse rien, il cherche au contraire une solution. La réponse B invente un refus : Hugo affirme « Aucun souci » au sujet de son père. La réponse C invente un argument de prix : c''est le **délai**, jamais le coût, qui motive la décision — piège de cause substituée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b00c-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00c-4000-0000-000000000007',
   NULL, 'B1', 'CE',
   'Que décident finalement les deux amies ?',
   'La décision finale vient de Camille : « Il y a une autre séance à 20 h 15, je nous prends deux billets », et Priya ajoute « Je t''invite à manger un morceau avant ». Par **inférence sur la conclusion du dialogue**, elles iront ensemble à la séance de 20 h 15 après avoir mangé. La réponse B reprend la proposition initiale de Priya (« Vas-y sans moi »), que Camille rejette : « Hors de question d''y aller seule ! ». La réponse C cite une hypothèse abandonnée : le remboursement n''était prévu que « si je n''arrive pas », et la nouvelle séance le rend inutile. La réponse D contredit l''échange : la sortie est décalée, pas supprimée — piège entre **report et annulation**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b00c-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00c-4000-0000-000000000008',
   NULL, 'B1', 'CE',
   'Que faut-il comprendre de cet échange ?',
   'Léa accepte mais prévient : « je pars au travail à 11 h 30… S''il passe après, il faudra voir avec le gardien », et Fatou confirme : « Je vais le prévenir aussi ». Par **inférence simple reliant l''horaire de Léa et le rôle du gardien**, un passage tardif du livreur aboutira chez le gardien. La réponse A ignore cette limite : Léa ne peut pas attendre jusqu''à 13 h puisqu''elle part à 11 h 30. La réponse B invente une information : Fatou dit être absente « toute la matinée » sans annoncer d''heure de retour. La réponse D exagère un détail rassurant : « un simple contrôle, ne t''inquiète pas » exclut la maladie grave — piège de **dramatisation d''un détail**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('11111111-b00c-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00c-4000-0000-000000000009',
   NULL, 'B1', 'CE',
   'Pourquoi Marek écrit-il à Anh ?',
   'Marek annonce « j''ai eu mon permis de conduire ce matin » puis enchaîne « Je vous invite, Sara et toi, à la crêperie du port ». La bonne réponse **reformule cette double intention** : annoncer sa réussite et inviter ses amis à la fêter. La réponse A inverse la chronologie : le permis est déjà obtenu « du premier coup », aucun conseil n''est demandé. La réponse C garde le mauvais jour : vendredi est écarté car Anh « termine à 22 h », la table sera réservée pour samedi — piège de **confusion entre la date proposée et la date retenue**. La réponse D détourne la plaisanterie finale d''Anh (« c''est toi qui conduis ») en un service que Marek n''a jamais proposé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('11111111-b00c-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', '11111111-b00c-4000-0000-00000000000a',
   NULL, 'B1', 'CE',
   'Comment Aïcha ira-t-elle travailler la semaine prochaine ?',
   'Tomas propose : « Prends le mien ! », et Aïcha accepte : « Tu me sauves ! Je te le rends jeudi soir, dès que je récupère le mien ». La bonne réponse **reformule cette solution** : elle ira travailler avec le vélo prêté par Tomas. La réponse A reprend l''option écartée : le bus impose « presque une heure de trajet » avec deux changements, c''est justement ce qu''Aïcha veut éviter. La réponse B confond les personnes : c''est Tomas qui va au bureau à pied, pas Aïcha. La réponse C se trompe de date : son propre vélo « ne sera prêt que jeudi prochain », donc après le début du travail lundi — piège de **confusion entre deux repères temporels**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reformulation');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  -- Q01 — match déplacé au gymnase (bonne réponse : position 2)
  ('11111111-b00c-2100-0000-000000000001', '11111111-b00c-1000-0000-000000000001',
   'Le match est annulé à cause des travaux',
   'false', '1'),
  ('11111111-b00c-2200-0000-000000000001', '11111111-b00c-1000-0000-000000000001',
   'Le match aura lieu dans un gymnase au lieu du parc',
   'true', '2'),
  ('11111111-b00c-2300-0000-000000000001', '11111111-b00c-1000-0000-000000000001',
   'Le match commencera à 17 h au lieu de 15 h',
   'false', '3'),
  ('11111111-b00c-2400-0000-000000000001', '11111111-b00c-1000-0000-000000000001',
   'Les joueurs devront porter des crampons',
   'false', '4'),

  -- Q02 — panne de Lucia (bonne réponse : position 4)
  ('11111111-b00c-2100-0000-000000000002', '11111111-b00c-1000-0000-000000000002',
   'De venir la dépanner sur le parking du supermarché',
   'false', '1'),
  ('11111111-b00c-2200-0000-000000000002', '11111111-b00c-1000-0000-000000000002',
   'De prévenir la maîtresse de Maya',
   'false', '2'),
  ('11111111-b00c-2300-0000-000000000002', '11111111-b00c-1000-0000-000000000002',
   'De ramener Maya directement chez elle',
   'false', '3'),
  ('11111111-b00c-2400-0000-000000000002', '11111111-b00c-1000-0000-000000000002',
   'D''aller chercher Maya à l''école et de la garder chez lui',
   'true', '4'),

  -- Q03 — écharpe de Wei (bonne réponse : position 1)
  ('11111111-b00c-2100-0000-000000000003', '11111111-b00c-1000-0000-000000000003',
   'Nadia la confiera à son voisin, monsieur Costa',
   'true', '1'),
  ('11111111-b00c-2200-0000-000000000003', '11111111-b00c-1000-0000-000000000003',
   'Nadia la déposera dans sa boîte aux lettres',
   'false', '2'),
  ('11111111-b00c-2300-0000-000000000003', '11111111-b00c-1000-0000-000000000003',
   'Il passera la chercher chez Nadia cette semaine',
   'false', '3'),
  ('11111111-b00c-2400-0000-000000000003', '11111111-b00c-1000-0000-000000000003',
   'Nadia la lui apportera à Lyon vendredi',
   'false', '4'),

  -- Q04 — place de concert de Rachid (bonne réponse : position 3)
  ('11111111-b00c-2100-0000-000000000004', '11111111-b00c-1000-0000-000000000004',
   'De lui vendre la place de concert de son frère',
   'false', '1'),
  ('11111111-b00c-2200-0000-000000000004', '11111111-b00c-1000-0000-000000000004',
   'De rendre visite à son frère malade vendredi',
   'false', '2'),
  ('11111111-b00c-2300-0000-000000000004', '11111111-b00c-1000-0000-000000000004',
   'De l''accompagner gratuitement à un concert de jazz',
   'true', '3'),
  ('11111111-b00c-2400-0000-000000000004', '11111111-b00c-1000-0000-000000000004',
   'De prendre un café ensemble vendredi après-midi',
   'false', '4'),

  -- Q05 — pique-nique d''Olena (bonne réponse : position 2)
  ('11111111-b00c-2100-0000-000000000005', '11111111-b00c-1000-0000-000000000005',
   'De préparer une deuxième salade de riz',
   'false', '1'),
  ('11111111-b00c-2200-0000-000000000005', '11111111-b00c-1000-0000-000000000005',
   'D''apporter un dessert à la place de la salade',
   'true', '2'),
  ('11111111-b00c-2300-0000-000000000005', '11111111-b00c-1000-0000-000000000005',
   'D''acheter les boissons pour le pique-nique',
   'false', '3'),
  ('11111111-b00c-2400-0000-000000000005', '11111111-b00c-1000-0000-000000000005',
   'De retrouver le groupe plus tôt à l''entrée du parc',
   'false', '4'),

  -- Q06 — perceuse de Diego (bonne réponse : position 4)
  ('11111111-b00c-2100-0000-000000000006', '11111111-b00c-1000-0000-000000000006',
   'Parce que Hugo refuse de prêter ses outils',
   'false', '1'),
  ('11111111-b00c-2200-0000-000000000006', '11111111-b00c-1000-0000-000000000006',
   'Parce que le père de Hugo ne veut pas prêter la sienne',
   'false', '2'),
  ('11111111-b00c-2300-0000-000000000006', '11111111-b00c-1000-0000-000000000006',
   'Parce que la location coûte moins cher qu''un achat',
   'false', '3'),
  ('11111111-b00c-2400-0000-000000000006', '11111111-b00c-1000-0000-000000000006',
   'Parce qu''aucune perceuse prêtée ne serait disponible à temps',
   'true', '4'),

  -- Q07 — cinéma de Priya et Camille (bonne réponse : position 1)
  ('11111111-b00c-2100-0000-000000000007', '11111111-b00c-1000-0000-000000000007',
   'D''aller ensemble à la séance de 20 h 15 après avoir mangé',
   'true', '1'),
  ('11111111-b00c-2200-0000-000000000007', '11111111-b00c-1000-0000-000000000007',
   'Que Camille ira seule à la séance de 18 h',
   'false', '2'),
  ('11111111-b00c-2300-0000-000000000007', '11111111-b00c-1000-0000-000000000007',
   'Que Priya remboursera la place de Camille',
   'false', '3'),
  ('11111111-b00c-2400-0000-000000000007', '11111111-b00c-1000-0000-000000000007',
   'D''annuler leur sortie au cinéma',
   'false', '4'),

  -- Q08 — colis de Fatou (bonne réponse : position 3)
  ('11111111-b00c-2100-0000-000000000008', '11111111-b00c-1000-0000-000000000008',
   'Léa attendra le livreur chez elle jusqu''à 13 h',
   'false', '1'),
  ('11111111-b00c-2200-0000-000000000008', '11111111-b00c-1000-0000-000000000008',
   'Fatou rentrera de l''hôpital avant le passage du livreur',
   'false', '2'),
  ('11111111-b00c-2300-0000-000000000008', '11111111-b00c-1000-0000-000000000008',
   'Si le livreur passe après 11 h 30, le gardien prendra le colis',
   'true', '3'),
  ('11111111-b00c-2400-0000-000000000008', '11111111-b00c-1000-0000-000000000008',
   'Fatou est gravement malade et hospitalisée plusieurs jours',
   'false', '4'),

  -- Q09 — permis de Marek (bonne réponse : position 2)
  ('11111111-b00c-2100-0000-000000000009', '11111111-b00c-1000-0000-000000000009',
   'Pour lui demander des conseils avant l''examen du permis',
   'false', '1'),
  ('11111111-b00c-2200-0000-000000000009', '11111111-b00c-1000-0000-000000000009',
   'Pour annoncer sa réussite et inviter ses amis à la fêter',
   'true', '2'),
  ('11111111-b00c-2300-0000-000000000009', '11111111-b00c-1000-0000-000000000009',
   'Pour réserver une table à la crêperie vendredi soir',
   'false', '3'),
  ('11111111-b00c-2400-0000-000000000009', '11111111-b00c-1000-0000-000000000009',
   'Pour proposer de conduire Anh à son travail',
   'false', '4'),

  -- Q10 — vélo d''Aïcha (bonne réponse : position 4)
  ('11111111-b00c-2100-0000-00000000000a', '11111111-b00c-1000-0000-00000000000a',
   'En bus, avec deux changements',
   'false', '1'),
  ('11111111-b00c-2200-0000-00000000000a', '11111111-b00c-1000-0000-00000000000a',
   'À pied, comme Tomas',
   'false', '2'),
  ('11111111-b00c-2300-0000-00000000000a', '11111111-b00c-1000-0000-00000000000a',
   'Avec son propre vélo, réparé dès lundi',
   'false', '3'),
  ('11111111-b00c-2400-0000-00000000000a', '11111111-b00c-1000-0000-00000000000a',
   'Avec le vélo que Tomas lui prête',
   'true', '4');

-- ============================================================================
-- CHECKLIST — contrôles passés
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (11111111-b00c-1000/4000/21..2400-…-NN, NN=01..0a).
-- [x] Support unique : échange de messages (10 conversations toutes
--     différentes : match de foot déplacé, enfant à récupérer après une panne,
--     écharpe oubliée, place de concert offerte, organisation de pique-nique,
--     perceuse introuvable à temps, retard de train avant le cinéma, colis à
--     réceptionner, permis obtenu à fêter, vélo prêté pour le travail).
-- [x] Aucun support interdit utilisé (pas d''e-mail, lettre, article, forum,
--     annonce, note, FAQ, brochure…) — uniquement des dialogues type
--     SMS/messagerie « Prénom : message ».
-- [x] Passages TEXTE ~60-120 mots, mise en forme réaliste d''une conversation
--     (tours de parole alternés, ton oral familier), media_id NULL.
-- [x] 4 propositions / 1 correcte par item. Distribution des bonnes réponses :
--     pos1:2, pos2:3, pos3:2, pos4:3 (max 3 par position, 4 positions utilisées).
-- [x] competence_code : ce_reperage_explicite x4, ce_inference_intention x3,
--     ce_reformulation x3.
-- [x] explanation ≥ 80 caractères : bonne réponse justifiée + les 3 distracteurs
--     expliqués, point clé en **gras**, mécanisme linguistique nommé (inversion
--     d''interdiction, proposition écartée, cause substituée, report vs
--     annulation, repères temporels…).
-- [x] Pas de SVG ni SSML dans ce lot (supports textuels uniquement) — rien à
--     équilibrer.
-- [x] Apostrophes SQL doublées partout, contenu 100% original, prénoms variés
--     (Sofia, Amadou, Lucia, Karim, Wei, Nadia, Rachid, Bilal, Olena, Marta,
--     Diego, Hugo, Priya, Camille, Fatou, Léa, Marek, Anh, Aïcha, Tomas),
--     items autonomes.
-- ============================================================================
