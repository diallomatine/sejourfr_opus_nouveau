-- ============================================================================
-- V415 — TCF CE B1
-- ----------------------------------------------------------------------------
-- Questions + choix. 22222222-0000-0000-0000-000000000002 AND difficulty='B1'.
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('55555555-0009-0000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0009-0000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Quelle est l''opinion globale de l''auteure sur ce restaurant ?',
   'L''auteure conclut : « Je recommande pour le décor, mais peut-être pas pour une occasion spéciale ». Elle reconnaît du positif (décor, personnel attentif) et pointe des défauts (attente longue, plats sans surprise). Son avis est donc mitigé, ni totalement enthousiaste, ni totalement négatif, ni indifférent.',
   'true', '2026-05-27 17:40:30.147221+02', '2026-05-27 17:40:30.147221+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('55555555-0009-0000-0000-000000000010', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0009-0000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Que doit faire le destinataire après avoir lu ce message ?',
   'L''agence dit que « sans ces documents, nous ne pourrons pas étudier votre candidature » et précise qu''il manque « votre dernier avis d''imposition ainsi qu''un justificatif de domicile ». Le destinataire doit donc envoyer les pièces manquantes. Le dossier n''est pas complet, n''est pas refusé, et il n''est pas question de payer une caution.',
   'true', '2026-05-27 17:40:30.147221+02', '2026-05-27 17:40:30.147221+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('55555555-0009-0000-0000-000000000011', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0009-0000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Qu''est-ce qui change dans le tri à partir du 1er juin ?',
   'Le texte précise : « Le bac jaune accueillera désormais tous les emballages plastiques, y compris les pots de yaourt et les barquettes, alors qu''ils étaient auparavant interdits ». C''est donc une extension de ce qu''on peut mettre dans le bac jaune. Le bac vert n''est pas modifié, le tri n''est pas supprimé, et le texte n''indique pas que seuls les pots seraient triés.',
   'true', '2026-05-27 17:40:30.147221+02', '2026-05-27 17:40:30.147221+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('55555555-0009-0000-0000-000000000012', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0009-0000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Que risque un habitant qui ne respecte pas les nouvelles règles ?',
   'Le texte indique : « Les contrevenants s''exposent à une amende de 35 euros. » Le risque est donc financier (une amende). Le texte n''évoque ni peine de prison, ni suspension du ramassage, ni convocation au tribunal.',
   'true', '2026-05-27 17:40:30.147221+02', '2026-05-27 17:40:30.147221+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('55555555-0010-0000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0010-0000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Quel est le but principal de cet article ?',
   'L''article décrit une arnaque par SMS puis conclut par des conseils de protection : « il est conseillé de ne jamais cliquer sur un lien reçu par SMS, et de contacter directement son conseiller en cas de doute ». Son objectif est donc d''informer et de mettre en garde. Il ne fait ni la promotion d''un service, ni la critique des banques, ni un témoignage personnel.',
   'true', '2026-05-27 17:40:30.164849+02', '2026-05-27 17:40:30.164849+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('55555555-0010-0000-0000-000000000010', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0010-0000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Que doit faire un client qui reçoit un SMS suspect de sa banque ?',
   'L''article conseille de « contacter directement son conseiller en cas de doute ». Le bon réflexe est donc de joindre sa banque par un canal direct (et non par le SMS suspect). Cliquer sur le lien est précisément ce que le texte déconseille. Communiquer ses identifiants ou supprimer son compte ne sont pas recommandés.',
   'true', '2026-05-27 17:40:30.164849+02', '2026-05-27 17:40:30.164849+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('55555555-0010-0000-0000-000000000011', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0010-0000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Quelle est la position globale de l''auteur sur ce vendeur ?',
   'L''auteur conclut : « Je recommanderais le produit, mais pas forcément ce vendeur. » Il sépare clairement le produit (positif) du service client (négatif). Sa position est donc partagée. Il n''est ni entièrement satisfait, ni totalement insatisfait, et ne reste pas neutre.',
   'true', '2026-05-27 17:40:30.164849+02', '2026-05-27 17:40:30.164849+02', 'ACTIVE', NULL, NULL, 'ce_ton_auteur'),

  ('55555555-0010-0000-0000-000000000012', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0010-0000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Quel principal reproche l''auteur fait-il au vendeur ?',
   'Le texte dit : « le service client était injoignable pendant toute la durée de l''attente ». Le reproche porte donc sur le service client. Le canapé est arrivé en bon état et correspond à la description (donc pas de défaut produit), et le texte ne mentionne ni prix excessif, ni absence de garantie.',
   'true', '2026-05-27 17:40:30.164849+02', '2026-05-27 17:40:30.164849+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('55555555-0011-0000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0011-0000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Quel est l''objectif principal de cette campagne ?',
   'Le texte dit que la campagne vise à « encourager les adultes de plus de 50 ans à se faire dépister ». Son but est donc d''inciter au dépistage. Le texte ne propose pas de nouveau médicament, ne dénonce pas les médecins, et ne s''adresse pas spécifiquement aux jeunes.',
   'true', '2026-05-27 17:40:30.178875+02', '2026-05-27 17:40:30.178875+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('55555555-0011-0000-0000-000000000010', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0011-0000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Selon le texte, quel est l''avantage principal du dépistage ?',
   'Le texte dit que les cancers sont « trop souvent diagnostiqués à un stade avancé » et « pourraient être pris en charge bien plus tôt ». L''avantage est donc une détection précoce. Le texte précise que le dépistage ne remplace pas le suivi médical, ne dit pas qu''il guérit, et n''évoque pas de réduction des coûts.',
   'true', '2026-05-27 17:40:30.178875+02', '2026-05-27 17:40:30.178875+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('55555555-0011-0000-0000-000000000011', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0011-0000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Combien la mairie de Saint-Léonard économise-t-elle grâce aux panneaux solaires ?',
   'Le texte indique : « ce qui permet à la mairie d''économiser environ 4 000 euros par an ». L''économie annuelle est donc de 4 000 euros. Les autres montants ne sont pas mentionnés.',
   'true', '2026-05-27 17:40:30.178875+02', '2026-05-27 17:40:30.178875+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('55555555-0011-0000-0000-000000000012', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0011-0000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Que prévoit ensuite la municipalité ?',
   'Le texte précise : « La municipalité envisage maintenant d''étendre l''installation à la salle des fêtes et au gymnase ». Elle prévoit donc d''équiper d''autres bâtiments. Le texte n''évoque ni la vente d''électricité, ni le retour à l''électricité classique, ni un nouveau référendum.',
   'true', '2026-05-27 17:40:30.178875+02', '2026-05-27 17:40:30.178875+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('55555555-0012-0000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0012-0000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Quelle est la durée de la formation ?',
   'Le texte indique : « D''une durée de six mois ». La formation dure donc six mois. Les autres durées (trois mois, un an, deux ans) ne sont pas mentionnées.',
   'true', '2026-05-27 17:40:30.194289+02', '2026-05-27 17:40:30.194289+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('55555555-0012-0000-0000-000000000010', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0012-0000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Qui peut s''inscrire à cette formation ?',
   'Le texte précise que la formation est « destinée aux personnes en reconversion professionnelle » et que « aucun diplôme préalable n''est exigé ». Elle est donc ouverte aux personnes en reconversion, sans condition de diplôme. Elle n''est pas réservée aux jeunes, ni aux ingénieurs, et ne demande pas un master.',
   'true', '2026-05-27 17:40:30.194289+02', '2026-05-27 17:40:30.194289+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('55555555-0012-0000-0000-000000000011', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0012-0000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Comment le destinataire recevra-t-il ses billets ?',
   'Le message indique : « Vos billets électroniques vous seront envoyés par courriel 48 heures avant l''événement. » Les billets sont donc envoyés par e-mail (courriel), et 48h avant. Ils ne sont ni envoyés par la poste, ni à retirer sur place, ni dans une enveloppe physique.',
   'true', '2026-05-27 17:40:30.194289+02', '2026-05-27 17:40:30.194289+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('55555555-0012-0000-0000-000000000012', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0012-0000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Jusqu''à quand le remboursement est-il possible ?',
   'Le message précise : « En cas d''empêchement, le remboursement est possible jusqu''à dix jours avant la date. » La limite est donc dix jours avant le concert. Le texte n''évoque ni un remboursement le jour même, ni 48 heures avant, ni une interdiction totale.',
   'true', '2026-05-27 17:40:30.194289+02', '2026-05-27 17:40:30.194289+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('55555555-0013-0000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '33333333-0013-0000-0000-000000000020', 'B1', 'CE',
   'Quand auront lieu les cours de français ?',
   'L''e-mail précise en bleu : « Les cours auront lieu tous les mardis de 18h à 20h ». Les cours ont donc lieu le mardi soir. Les autres options (lundi, mercredi, samedi matin) ne sont pas mentionnées.',
   'true', '2026-05-27 17:40:30.209527+02', '2026-05-27 17:40:30.209527+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('55555555-0013-0000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '33333333-0013-0000-0000-000000000021', 'B1', 'CE',
   'À qui cet appartement est-il déconseillé ?',
   'L''annonce précise en bas : « Animaux non acceptés ». L''appartement est donc déconseillé aux personnes qui ont un animal. Le texte mentionne aussi « idéal jeune couple ou personne seule » : il convient donc aux couples et aux personnes seules. La présence d''un ascenseur le rend accessible aux personnes âgées.',
   'true', '2026-05-27 17:40:30.209527+02', '2026-05-27 17:40:30.209527+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('55555555-0013-0000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '33333333-0013-0000-0000-000000000022', 'B1', 'CE',
   'Combien de temps dure le trajet en TGV ?',
   'Le billet affiche entre le départ (14h08) et l''arrivée (17h32) la mention « 3h24 » au milieu de la flèche. La durée du trajet est donc de 3h24, qui correspond aussi au calcul direct (17h32 - 14h08 = 3h24).',
   'true', '2026-05-27 17:40:30.209527+02', '2026-05-27 17:40:30.209527+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('55555555-0013-0000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '33333333-0013-0000-0000-000000000023', 'B1', 'CE',
   'Quand un adulte peut-il entrer gratuitement au musée ?',
   'Le bloc vert indique deux cas de gratuité : « pour les moins de 18 ans » et « pour tous, le 1er dimanche de chaque mois ». Pour un adulte (donc plus de 18 ans), la seule option de gratuité est le premier dimanche du mois. Les autres jours, l''entrée est payante (plein tarif ou tarif réduit selon les conditions).',
   'true', '2026-05-27 17:40:30.209527+02', '2026-05-27 17:40:30.209527+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('55555555-0020-0000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '33333333-0020-0000-0000-000000000001', 'B1', 'CE',
   'Quel candidat peut postuler à cette colocation ?',
   'L''annonce impose quatre conditions cumulatives visibles dans les badges et les conditions d''entrée : « Étudiants uniquement », « Non-fumeurs », disponibilité « à partir du 1er octobre » et un bail de « 9 mois minimum (année universitaire) ». Seule la réponse C respecte ces quatre critères. La réponse A est une demi-vérité : étudiant oui, mais fumeur exclu et la caution est de 2 mois de loyer (soit 960 €, pas 480 €). La réponse B est une reformulation faussée : tout est correct sauf la date (le texte précise octobre, pas septembre). La réponse D est vraie sur le non-fumeur mais hors champ pour le reste : un jeune actif en CDI n''est pas « étudiant », ce qui est une condition exclusive.',
   'true', '2026-05-27 17:40:30.286561+02', '2026-05-27 17:40:30.286561+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('55555555-0021-0000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '33333333-0021-0000-0000-000000000001', 'B1', 'CE',
   'Quand et où aura lieu la réunion finalement ?',
   'L''e-mail précise que la réunion « est reportée à jeudi 14h en salle B (et non plus en salle A) ». Il faut combiner le jour, l''heure et le bon lieu. La réponse C reformule correctement ces trois éléments. La réponse A reprend les informations initiales (avant le report) : c''est une inversion temporelle. La réponse B mélange la nouvelle date (jeudi) avec l''ancienne salle (A) : c''est une combinaison erronée. La réponse D inverse le lieu : la salle A n''est plus utilisée.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('55555555-0021-0000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '33333333-0021-0000-0000-000000000001', 'B1', 'CE',
   'Quand sera abordé le sujet du budget annuel ?',
   'L''e-mail indique que « le point sur le budget annuel, que nous devions traiter mardi, est décalé à la prochaine réunion de la semaine suivante ». Il sera donc abordé à la réunion suivante, soit une semaine plus tard. La réponse C reformule cette information. La réponse A est une reformulation faussée : le budget est précisément ce qui est retiré de l''ordre du jour de jeudi. La réponse B mélange deux dates citées dans le mail : la réunion de jeudi et la confirmation de mercredi midi. La réponse D propose une option non mentionnée et contraire (par mail) : Thomas convoque une réunion physique pour ce point.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('55555555-0021-0000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '33333333-0021-0000-0000-000000000002', 'B1', 'CE',
   'Quelles sont les conditions de participation à l''atelier ?',
   'L''affiche précise quatre éléments : « tous niveaux acceptés, débutants bienvenus », « matériel et tablier fournis », « 8 places maximum » et « inscription préalable obligatoire ». La réponse B reformule fidèlement ces conditions. La réponse A inverse le nombre de places (12 au lieu de 8) et est partiellement vraie sur les débutants. La réponse C est une demi-vérité : il faut bien réserver, mais pas en venant sur place — uniquement par téléphone ou mail. La réponse D inverse les éléments : le matériel est fourni, on ne doit pas l''apporter.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('55555555-0021-0000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '33333333-0021-0000-0000-000000000002', 'B1', 'CE',
   'Comment réserver une place à cet atelier ?',
   'L''affiche indique « par téléphone au 05 56 12 34 56 ou par mail : contact@latelier-du-gout.fr ». Deux moyens sont donc proposés. La réponse C reformule cette information. La réponse A est une reformulation faussée : on ne se présente pas sur place (8 places maximum + inscription préalable obligatoire). La réponse B est partiellement vraie (le téléphone) mais omet l''option mail. La réponse D propose un canal non mentionné (site internet).',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('55555555-0021-0000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '33333333-0021-0000-0000-000000000003', 'B1', 'CE',
   'Combien le client va-t-il payer au total ?',
   'L''écran affiche clairement « Total à payer : 21,50 € » sous le détail du paiement (24 − 5 + 2,50 = 21,50). La réponse D est correcte. La réponse A reprend le sous-total avant déduction et frais. La réponse B prend le sous-total moins la promo, sans les frais de livraison (calcul incomplet). La réponse C ajoute les frais de livraison au sous-total sans déduire la promo.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('55555555-0021-0000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '33333333-0021-0000-0000-000000000003', 'B1', 'CE',
   'Pourquoi le client a-t-il bénéficié de 5 euros de réduction ?',
   'L''écran affiche « Code BIENVENUE (nouveau client) − 5,00 € ». La réduction est donc liée au statut de nouveau client de l''application. La réponse C reformule cette information. La réponse A est une reformulation faussée : il ne s''agit pas d''une promotion limitée dans le temps, mais d''une remise réservée aux nouveaux clients. La réponse B est une généralisation abusive : ce n''est pas le montant qui déclenche la promo. La réponse D adopte une position adjacente erronée : aucune mention de fidélité (au contraire, c''est pour les nouveaux clients).',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('55555555-0021-0000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '33333333-0021-0000-0000-000000000004', 'B1', 'CE',
   'Que l''acheteur recevra-t-il en plus du vélo ?',
   'L''annonce détaille quatre éléments inclus : deux batteries, le chargeur, la facture d''origine et un antivol U récent. La réponse B reformule l''essentiel : deux batteries + un antivol U. La réponse A est une demi-vérité : la batterie est citée, mais l''annonce en mentionne deux. La réponse C inverse l''information : la facture est incluse, pas le casque (jamais mentionné). La réponse D est une généralisation erronée : aucune révision en magasin n''est offerte.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('55555555-0021-0000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '33333333-0021-0000-0000-000000000004', 'B1', 'CE',
   'Comment l''acheteur peut-il récupérer le vélo ?',
   'L''annonce indique en encart rouge « Retrait uniquement sur place à Nantes. Pas d''envoi possible. Essai bienvenu. ». La réponse C reformule cette contrainte. La réponse A est une reformulation faussée : aucun envoi par transporteur n''est proposé (« pas d''envoi possible »). La réponse B inverse la logique : c''est l''acheteur qui doit se déplacer, pas le vendeur. La réponse D mélange deux notions : l''essai est possible, mais sur place (pas en dehors de Nantes).',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('55555555-0021-0000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '33333333-0021-0000-0000-000000000005', 'B1', 'CE',
   'Quand Camille peut-elle bénéficier de la réduction de 10% sur les viennoiseries ?',
   'L''encart vert indique « −10% sur les viennoiseries du lundi au vendredi », et l''encart rouge précise « la réduction ne s''applique pas le week-end ni sur les commandes spéciales ». La réponse C reformule ces deux informations cumulées. La réponse A est une reformulation faussée : la carte est valable jusqu''au 30 juin prochain, ce n''est pas une condition d''avantage. La réponse B inclut à tort le samedi (la réduction ne s''applique pas le week-end). La réponse D adopte une condition non mentionnée et trop restrictive.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('55555555-0021-0000-0000-000000000010', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '33333333-0021-0000-0000-000000000005', 'B1', 'CE',
   'Si Camille passe commande sur le site internet de la boulangerie, que se passe-t-il ?',
   'L''encart rouge indique : « Avantages valables uniquement en boutique, jamais sur les commandes en ligne. ». La réponse C reformule cette restriction. La réponse A est une reformulation faussée : les avantages ne se cumulent pas en ligne, ils ne s''appliquent pas du tout. La réponse B introduit une condition (week-end) qui n''est pas la cause réelle (c''est le canal en ligne). La réponse D est une généralisation abusive : la commande en ligne reste possible, simplement sans les avantages fidélité.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('55555555-0021-0000-0000-000000000011', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '33333333-0021-0000-0000-000000000006', 'B1', 'CE',
   'Quelles pièces sont nécessaires pour commencer la démarche ?',
   'L''encart jaune liste trois pièces : pièce d''identité, justificatif de domicile de moins de 6 mois, et ancien certificat d''immatriculation si le véhicule est d''occasion. La réponse B reformule fidèlement ces trois pièces. La réponse A est une reformulation faussée : la condition d''ancienneté est de 6 mois, pas de 3 mois. La réponse C oublie le justificatif de domicile et introduit un permis de conduire jamais mentionné. La réponse D est une demi-vérité : la pièce d''identité est requise, mais les autres documents ne correspondent pas (avis d''imposition non mentionné).',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('55555555-0021-0000-0000-000000000012', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '33333333-0021-0000-0000-000000000006', 'B1', 'CE',
   'Que peut faire le demandeur pendant qu''il attend sa carte grise définitive ?',
   'L''encart vert « bon à savoir » indique : « Vous pouvez circuler avec un certificat provisoire pendant 1 mois, en attendant la carte définitive. ». La réponse C reformule cette possibilité. La réponse A est une reformulation faussée : la durée du traitement est de 7 à 14 jours, mais le certificat provisoire permet de circuler entre-temps. La réponse B est une inversion : l''ancien certificat ne peut pas servir de titre après la vente. La réponse D adopte une formulation trop tranchée et fausse : il faut pouvoir prouver son droit de circuler, ce que permet justement le certificat provisoire.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('55555555-0021-0000-0000-000000000013', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0021-0000-0000-000000000001',
   NULL, 'B1', 'CE',
   'Que doivent apporter les collègues qui viennent au pot ?',
   'Le mail indique que « Camille apporte les boissons » et que « chacun amène quelque chose à grignoter (sucré ou salé) ». Les collègues sont donc seulement chargés du grignotage. La réponse C reformule cette information. La réponse A est une inversion de locuteur : c''est Camille (et non l''ensemble du groupe) qui s''occupe des boissons. La réponse B inclut à tort le cadeau, alors que le cadeau est financé par la cagnotte gérée par Marc (15 € par personne, séparé). La réponse D oublie le grignotage et invente la vaisselle, qui est précisément ce que Thomas dispense d''apporter (« inutile de prévoir des assiettes »).',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('55555555-0021-0000-0000-000000000014', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0021-0000-0000-000000000001',
   NULL, 'B1', 'CE',
   'Un collègue absent peut-il participer au cadeau ?',
   'Le mail précise : « Si vous souhaitez participer à la collecte sans pouvoir venir au pot, prévenez-le [Marc] directement. ». Une absence n''interdit donc pas la participation au cadeau, à condition de prévenir Marc. La réponse B reformule cette possibilité. La réponse A inverse la règle : la présence n''est pas requise pour participer à la cagnotte. La réponse C invente une condition (passer en main propre) non mentionnée. La réponse D est une demi-vérité : Marc gère bien la cagnotte, mais le mail indique qu''il faut justement le prévenir, pas qu''il faut s''adresser ailleurs.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention'),

  ('55555555-0021-0000-0000-000000000015', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0021-0000-0000-000000000002',
   NULL, 'B1', 'CE',
   'Un copropriétaire peut-il utiliser une perceuse le samedi matin ?',
   'L''article 12 précise : « Les travaux bruyants (perceuse, marteau) ne sont autorisés que du lundi au samedi, entre 9h et 12h puis entre 14h et 19h. ». Le samedi de 10h à 12h est donc autorisé. La réponse B reformule cette autorisation. La réponse A est une reformulation faussée : la perceuse est explicitement autorisée le samedi. La réponse C est une demi-vérité : les jours ouvrables sont autorisés, mais le samedi aussi. La réponse D introduit une condition (autorisation préalable) non mentionnée.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('55555555-0021-0000-0000-000000000016', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0021-0000-0000-000000000002',
   NULL, 'B1', 'CE',
   'Que dit le règlement à propos des animaux de compagnie ?',
   'L''article 13 indique que « la présence d''animaux est tolérée, à l''exclusion des chiens classés comme dangereux » et impose la laisse dans les parties communes. La réponse C reformule cette double règle. La réponse A est une généralisation abusive : seuls les chiens « classés comme dangereux » sont interdits, pas tous les chiens. La réponse B est une demi-vérité : la laisse est requise, mais l''interdiction des chiens dangereux est aussi importante. La réponse D inverse la règle : le texte ne demande pas d''accord écrit du syndic.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('55555555-0021-0000-0000-000000000017', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0021-0000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Quelle impression générale les clients ressortent-ils de leur séjour ?',
   'Les clients écrivent : « Globalement, c''était un bon séjour, même si tout n''a pas été parfait » et concluent « malgré ces désagréments, nous reviendrions ». Le bilan est donc positif mais nuancé. La réponse C reformule cette nuance. La réponse A est trop tranchée et déforme l''opinion : les clients ne sont pas pleinement satisfaits. La réponse B inverse le ton : ils ne sont pas globalement déçus, ils sont prêts à revenir. La réponse D est une reformulation faussée : ils ne déconseillent absolument pas l''hôtel.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_idee_principale'),

  ('55555555-0021-0000-0000-000000000018', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0021-0000-0000-000000000003',
   NULL, 'B1', 'CE',
   'Quels problèmes les clients ont-ils rencontrés pendant leur séjour ?',
   'Le texte cite deux problèmes précis : la climatisation « en panne le premier soir, et seulement réparée le lendemain matin », et le bruit de la rue « audible dès 6h du matin, fenêtres fermées comprises ». La réponse C reformule ces deux points. La réponse A introduit un problème non mentionné (la propreté). La réponse B est une demi-vérité : la climatisation est citée, mais isolée du problème de bruit. La réponse D est une reformulation faussée : ils ont apprécié le personnel (« attentif »), ce n''est pas un problème.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('55555555-0021-0000-0000-000000000019', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0021-0000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Que propose le club aux personnes qui hésitent encore à s''inscrire ?',
   'Le texte précise que la formule « forfait découverte 3 mois (60 €) » est destinée aux « nouveaux adhérents qui hésitent encore », et qu''« en septembre, des séances d''essai gratuites » sont proposées aux non-adhérents. La réponse B combine correctement ces deux offres. La réponse A est une généralisation abusive : la première semaine de gratuité concerne uniquement les non-adhérents en septembre. La réponse C confond les formules : 60 € est le forfait découverte, pas la licence loisir (qui est à 160 €). La réponse D mélange deux tarifs : 60 € est bien le forfait découverte, mais sa durée est de 3 mois, pas illimitée.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('55555555-0021-0000-0000-000000000020', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0021-0000-0000-000000000004',
   NULL, 'B1', 'CE',
   'Comment réserver un court de tennis ?',
   'Le texte précise : « La réservation se fait obligatoirement en ligne via notre site, au minimum deux jours à l''avance pour les courts couverts, et la veille pour les courts extérieurs. ». La réponse C reformule cette double règle. La réponse A est une généralisation abusive : le délai de 2 jours ne s''applique qu''aux courts couverts. La réponse B est une demi-vérité : la réservation est bien en ligne, mais pas le jour même. La réponse D inverse le canal : la réservation par téléphone n''est pas mentionnée.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('55555555-0021-0000-0000-000000000021', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0021-0000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Que recommande la newsletter à propos de la douche avant de dormir ?',
   'Le texte écrit : « Évitez les douches glacées juste avant de dormir : contre-intuitif, mais elles relancent l''activité du corps. Préférez une douche tiède, vingt minutes avant le coucher. ». La réponse C reformule ces deux indications. La réponse A est une reformulation faussée : il faut éviter les douches glacées (et non les recommander). La réponse B est une généralisation abusive : la douche n''est pas à proscrire en soi, c''est sa température qui compte. La réponse D inverse la causalité : la douche tiède est conseillée, pas la douche froide.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_reformulation'),

  ('55555555-0021-0000-0000-000000000022', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0021-0000-0000-000000000005',
   NULL, 'B1', 'CE',
   'Que dit la newsletter à propos de l''alcool et du sommeil ?',
   'Le texte indique : « L''alcool, souvent perçu comme un facilitateur d''endormissement, dégrade en réalité la qualité du sommeil profond. ». La réponse C reformule cette nuance. La réponse A reprend la perception courante (facilitateur) que la newsletter dément justement. La réponse B est une généralisation excessive : l''alcool est déconseillé sur la qualité, pas sur l''endormissement initial. La réponse D introduit une distinction (rouge/blanc) non mentionnée.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('55555555-0021-0000-0000-000000000023', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0021-0000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Que se passe-t-il avec le train de 7h12 pendant la période de travaux ?',
   'Le texte indique : « le train de 7h12 au départ de Toulouse partira exceptionnellement à 7h35, sans modification des arrêts ». Le train est donc décalé de 23 minutes, mais sans changement de parcours. La réponse C reformule cette double information. La réponse A est une reformulation faussée : le train n''est pas supprimé, il est décalé. La réponse B est une demi-vérité : le décalage est correct, mais les arrêts ne changent pas. La réponse D introduit un service routier qui ne concerne que le train de 19h40, pas celui de 7h12.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('55555555-0021-0000-0000-000000000024', 'TCF', '22222222-0000-0000-0000-000000000002', '44444444-0021-0000-0000-000000000006',
   NULL, 'B1', 'CE',
   'Que doivent faire les voyageurs qui ont déjà acheté un billet pour le week-end ?',
   'Le texte dit : « Les billets déjà achetés restent valables, sans démarche supplémentaire de votre part. ». La réponse C reformule cette information. La réponse A est une reformulation faussée : aucune nouvelle réservation n''est requise. La réponse B introduit une démarche (demande de remboursement) que la SNCF ne demande pas. La réponse D est une généralisation erronée : aucun billet n''est invalidé, le service est simplement assuré par autocar.',
   'true', '2026-05-27 17:40:30.246972+02', '2026-05-27 17:40:30.246972+02', 'ACTIVE', NULL, NULL, 'ce_inference_intention');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('92228f45-f7a7-4f98-9ff0-88db91f89b99', '55555555-0009-0000-0000-000000000009',
   'Elle est très enthousiaste',
   'false', '1'),

  ('7a847bab-08b4-4f7e-99e4-3b1aeb4f9b91', '55555555-0009-0000-0000-000000000009',
   'Son avis est mitigé',
   'true', '2'),

  ('1a2f7336-cf07-4da4-b43e-3b31fbfd278c', '55555555-0009-0000-0000-000000000009',
   'Elle déconseille totalement le lieu',
   'false', '3'),

  ('9d872c22-34b8-4ac5-8d8b-b05f8d6bd6da', '55555555-0009-0000-0000-000000000009',
   'Elle est indifférente',
   'false', '4'),

  ('918fdae9-301b-4a9c-a9ee-7b34e83ec12a', '55555555-0009-0000-0000-000000000010',
   'Attendre, son dossier est complet',
   'false', '1'),

  ('3fd6e616-13d9-43b0-8991-0ceda44770fd', '55555555-0009-0000-0000-000000000010',
   'Envoyer les documents manquants',
   'true', '2'),

  ('490a15d1-87e1-48a6-acdf-86668887aa7c', '55555555-0009-0000-0000-000000000010',
   'Recommencer son dossier depuis le début',
   'false', '3'),

  ('93bf323a-c481-4801-a8c9-f023ada50511', '55555555-0009-0000-0000-000000000010',
   'Payer une caution supplémentaire',
   'false', '4'),

  ('5433ac5f-5cb1-4d71-85b7-18a4b2ac5df8', '55555555-0009-0000-0000-000000000011',
   'Le tri sélectif est supprimé',
   'false', '1'),

  ('54f8ef7b-5fff-4c5d-9815-4d4f3e311489', '55555555-0009-0000-0000-000000000011',
   'On peut désormais mettre plus d''emballages plastiques dans le bac jaune',
   'true', '2'),

  ('1cca15e3-0b97-40b7-8670-bfb3923bf2a8', '55555555-0009-0000-0000-000000000011',
   'Le bac vert accueille maintenant le plastique',
   'false', '3'),

  ('b0909968-329c-40c6-8a6e-7f84f4d48dd7', '55555555-0009-0000-0000-000000000011',
   'Seuls les pots de yaourt peuvent être triés',
   'false', '4'),

  ('8e594dcc-ec8b-45fb-9a2d-6082dc45732a', '55555555-0009-0000-0000-000000000012',
   'Une peine de prison',
   'false', '1'),

  ('1b5cae7f-1792-4644-923a-c24d6050cc79', '55555555-0009-0000-0000-000000000012',
   'Une amende de 35 euros',
   'true', '2'),

  ('22db481f-8c20-4726-9454-fcdf1058f2f7', '55555555-0009-0000-0000-000000000012',
   'La suspension du ramassage',
   'false', '3'),

  ('3c60f34d-97ae-4801-8c89-7b9660d20cee', '55555555-0009-0000-0000-000000000012',
   'Une convocation au tribunal',
   'false', '4'),

  ('437e0359-c978-4243-8191-3c248fea3aaf', '55555555-0010-0000-0000-000000000009',
   'Faire la promotion d''un nouveau service bancaire',
   'false', '1'),

  ('a7b911fb-4c1f-44db-bd0c-e54308505040', '55555555-0010-0000-0000-000000000009',
   'Mettre en garde contre les escroqueries par SMS',
   'true', '2'),

  ('4d436d04-8bea-4e92-b472-67e677b292a0', '55555555-0010-0000-0000-000000000009',
   'Critiquer les banques pour leur manque de sécurité',
   'false', '3'),

  ('13aabef5-3039-4a04-9d02-302b6e2e0b36', '55555555-0010-0000-0000-000000000009',
   'Raconter une histoire personnelle de fraude',
   'false', '4'),

  ('e64d0bd5-42b8-48f1-a8b6-3ce76b1dc347', '55555555-0010-0000-0000-000000000010',
   'Cliquer sur le lien pour vérifier',
   'false', '1'),

  ('f9626fa9-f2a2-41df-8b48-4855c975bc4e', '55555555-0010-0000-0000-000000000010',
   'Contacter directement son conseiller',
   'true', '2'),

  ('8c126f91-4f0f-487c-b1ec-4718141569a3', '55555555-0010-0000-0000-000000000010',
   'Communiquer ses identifiants par retour de SMS',
   'false', '3'),

  ('984e3d08-a04a-4565-8cbf-8777f41cdf95', '55555555-0010-0000-0000-000000000010',
   'Supprimer son compte bancaire',
   'false', '4'),

  ('4d743fc2-4e19-4f5d-a420-68c8f42c4d3d', '55555555-0010-0000-0000-000000000011',
   'Il est entièrement satisfait',
   'false', '1'),

  ('bbe6cba1-0347-48c3-b335-ba54c851a257', '55555555-0010-0000-0000-000000000011',
   'Son avis est partagé : produit correct, vendeur décevant',
   'true', '2'),

  ('5facbda7-903e-4c03-a011-3b7ea1a8c89b', '55555555-0010-0000-0000-000000000011',
   'Il est complètement déçu par sa commande',
   'false', '3'),

  ('253d7a08-d9f9-418b-9a33-09dbfb373896', '55555555-0010-0000-0000-000000000011',
   'Il ne donne pas vraiment son opinion',
   'false', '4'),

  ('35a9c588-5de9-41a9-b187-91802672d367', '55555555-0010-0000-0000-000000000012',
   'Le canapé est arrivé endommagé',
   'false', '1'),

  ('012b0a56-54b0-4cc9-a870-003dc5668462', '55555555-0010-0000-0000-000000000012',
   'Le service client était injoignable',
   'true', '2'),

  ('17a07cb5-07d8-4e16-ac65-a0aab51a3bb3', '55555555-0010-0000-0000-000000000012',
   'Le prix était beaucoup trop élevé',
   'false', '3'),

  ('9ef67557-be41-425f-a486-fb0e9fc4674a', '55555555-0010-0000-0000-000000000012',
   'Le produit ne correspondait pas à la description',
   'false', '4'),

  ('3dccd717-25ff-4528-b639-92ccdc3c3a0f', '55555555-0011-0000-0000-000000000009',
   'Promouvoir un nouveau médicament',
   'false', '1'),

  ('e23b5e2d-e500-4a36-87db-f47f0b24bac0', '55555555-0011-0000-0000-000000000009',
   'Inciter les plus de 50 ans à se faire dépister',
   'true', '2'),

  ('6193bdb8-8485-41b4-91c8-0026a1e141c7', '55555555-0011-0000-0000-000000000009',
   'Dénoncer le manque de suivi médical des Français',
   'false', '3'),

  ('c53d0a68-923e-4af4-831b-42cbf18b19b7', '55555555-0011-0000-0000-000000000009',
   'Informer les jeunes adultes sur les risques de santé',
   'false', '4'),

  ('526192f1-3ead-4979-b1ae-a48bc2cfd5d1', '55555555-0011-0000-0000-000000000010',
   'Il permet de détecter la maladie plus tôt',
   'true', '1'),

  ('ca6679eb-5dc0-4e3f-a448-37f7ac5c8ec3', '55555555-0011-0000-0000-000000000010',
   'Il remplace définitivement le suivi médical',
   'false', '2'),

  ('defadcb0-ed9b-4648-90ef-b6e4c5f70d47', '55555555-0011-0000-0000-000000000010',
   'Il garantit la guérison des malades',
   'false', '3'),

  ('3e204aa1-a83f-42d7-b589-1434fc26869f', '55555555-0011-0000-0000-000000000010',
   'Il réduit les coûts pour la Sécurité sociale',
   'false', '4'),

  ('7a5017c5-c76c-4861-ac8f-5538e5769f57', '55555555-0011-0000-0000-000000000011',
   '400 euros par an',
   'false', '1'),

  ('775723d0-9b2a-4c58-87a5-eeb89a1009e3', '55555555-0011-0000-0000-000000000011',
   '4 000 euros par an',
   'true', '2'),

  ('207b3108-9932-4eb1-b56a-485e9f787860', '55555555-0011-0000-0000-000000000011',
   '40 000 euros par an',
   'false', '3'),

  ('03dcc6aa-cede-4889-b9cf-d11f7e23bbb2', '55555555-0011-0000-0000-000000000011',
   'Le texte ne précise pas le montant',
   'false', '4'),

  ('820c8cae-d4a6-42b3-913f-1f7db6a02688', '55555555-0011-0000-0000-000000000012',
   'Vendre l''électricité produite aux habitants',
   'false', '1'),

  ('5c42826f-017e-48aa-8332-5031e253ecb2', '55555555-0011-0000-0000-000000000012',
   'Installer des panneaux sur d''autres bâtiments publics',
   'true', '2'),

  ('f23f3fbc-3606-4910-9480-4b60872f1f43', '55555555-0011-0000-0000-000000000012',
   'Revenir à l''électricité classique',
   'false', '3'),

  ('33cfeb77-dc18-4c74-a42c-00b73bfe464e', '55555555-0011-0000-0000-000000000012',
   'Organiser un référendum sur le projet',
   'false', '4'),

  ('e6de29e4-2601-4032-b2c5-b54110a0558b', '55555555-0012-0000-0000-000000000009',
   'Trois mois',
   'false', '1'),

  ('640da5c5-9cd9-44bb-b5bc-e14d72d61892', '55555555-0012-0000-0000-000000000009',
   'Six mois',
   'true', '2'),

  ('4171b0ba-b776-4c47-b441-24d530335797', '55555555-0012-0000-0000-000000000009',
   'Un an',
   'false', '3'),

  ('2464cf34-cb64-45c0-9c60-69c85b7fe76e', '55555555-0012-0000-0000-000000000009',
   'Deux ans',
   'false', '4'),

  ('37fe4db0-23e8-4822-8f90-8dc120cb4f59', '55555555-0012-0000-0000-000000000010',
   'Uniquement les jeunes de moins de 25 ans',
   'false', '1'),

  ('b2dbaa4d-4be9-4810-9baa-38f5dea04427', '55555555-0012-0000-0000-000000000010',
   'Les personnes en reconversion, sans condition de diplôme',
   'true', '2'),

  ('2ad8bbf2-67ac-4078-a04c-38b9ff8db4b8', '55555555-0012-0000-0000-000000000010',
   'Seulement les ingénieurs déjà diplômés',
   'false', '3'),

  ('b439d34e-6af2-4623-b1c7-9a7f8b633b12', '55555555-0012-0000-0000-000000000010',
   'Les candidats ayant au moins un master',
   'false', '4'),

  ('170ddda8-9feb-4426-82bf-3a2deea6ee32', '55555555-0012-0000-0000-000000000011',
   'Par voie postale, une semaine avant',
   'false', '1'),

  ('38a4d61f-5481-4874-9e8b-26573ef581c2', '55555555-0012-0000-0000-000000000011',
   'Par e-mail, 48 heures avant le concert',
   'true', '2'),

  ('952d331a-97a7-438b-8e32-47f2d57a80ef', '55555555-0012-0000-0000-000000000011',
   'À retirer sur place le jour du concert',
   'false', '3'),

  ('9d37769f-ef45-4084-be46-3a3e3a37ab27', '55555555-0012-0000-0000-000000000011',
   'Dans une enveloppe à l''entrée de la salle',
   'false', '4'),

  ('02bdd70c-feaa-4730-abad-fb2be742feb5', '55555555-0012-0000-0000-000000000012',
   'Le jour du concert',
   'false', '1'),

  ('cae6c398-2b6a-4f41-b4e3-d3702692e286', '55555555-0012-0000-0000-000000000012',
   '48 heures avant l''événement',
   'false', '2'),

  ('240bad05-52da-48cb-988d-3456674e3dff', '55555555-0012-0000-0000-000000000012',
   'Au plus tard dix jours avant',
   'true', '3'),

  ('3731136b-9a50-4001-a99d-05a06ba927e7', '55555555-0012-0000-0000-000000000012',
   'Aucun remboursement n''est possible',
   'false', '4'),

  ('771736b7-af12-461e-af95-8c0e77430d8c', '55555555-0013-0000-0000-000000000005',
   'Tous les lundis de 18h à 20h',
   'false', '1'),

  ('261e934a-5a05-4315-b675-330d6bbc5181', '55555555-0013-0000-0000-000000000005',
   'Tous les mardis de 18h à 20h',
   'true', '2'),

  ('acf6c5d7-d4c7-4208-b1dd-ca0ca3774d2a', '55555555-0013-0000-0000-000000000005',
   'Tous les mercredis de 14h à 16h',
   'false', '3'),

  ('d6c0cad2-bf56-48ba-927e-e2bbe36b16e0', '55555555-0013-0000-0000-000000000005',
   'Tous les samedis matin',
   'false', '4'),

  ('3263ca98-a66c-45b8-8858-9ba2da9158d4', '55555555-0013-0000-0000-000000000006',
   'À un jeune couple sans enfant',
   'false', '1'),

  ('1205d4ec-95ca-4173-ad51-0cd77c33a020', '55555555-0013-0000-0000-000000000006',
   'À une personne ayant un chien ou un chat',
   'true', '2'),

  ('0d09aae3-869f-404d-ad5d-2a866e143f79', '55555555-0013-0000-0000-000000000006',
   'À une personne âgée',
   'false', '3'),

  ('d60fa871-5c9d-455e-9cc4-f1318505f68d', '55555555-0013-0000-0000-000000000006',
   'À une personne seule',
   'false', '4'),

  ('1fc0899a-f2de-4419-809d-29f25a0dcbc8', '55555555-0013-0000-0000-000000000007',
   '2h24',
   'false', '1'),

  ('fcc5320a-e1dc-48ef-9c6c-ba2e4cf09c5b', '55555555-0013-0000-0000-000000000007',
   '3h08',
   'false', '2'),

  ('6052489f-02f5-4176-a2b7-69a38751d530', '55555555-0013-0000-0000-000000000007',
   '3h24',
   'true', '3'),

  ('5db1e672-43bb-4ba4-9414-64e301206fc5', '55555555-0013-0000-0000-000000000007',
   '4h32',
   'false', '4'),

  ('4789e28a-82d3-450e-a8e0-f69a8fe17b10', '55555555-0013-0000-0000-000000000008',
   'Tous les dimanches',
   'false', '1'),

  ('a08d5614-dfc9-4fbf-a61d-2f9f081e79b2', '55555555-0013-0000-0000-000000000008',
   'Le mercredi en nocturne',
   'false', '2'),

  ('ed63899c-4630-4cae-b8bd-f9332caef21c', '55555555-0013-0000-0000-000000000008',
   'Le 1er dimanche de chaque mois',
   'true', '3'),

  ('fbea9875-3559-4f90-9d7c-ee0dd19b39ed', '55555555-0013-0000-0000-000000000008',
   'Jamais : c''est toujours payant',
   'false', '4'),

  ('bf888a16-3c06-4217-a821-9e91716e7772', '55555555-0020-0000-0000-000000000002',
   'Un étudiant fumeur qui peut payer une caution de 480 €',
   'false', '1'),

  ('1763dde8-5b08-4938-b1fe-abb2a0a61244', '55555555-0020-0000-0000-000000000002',
   'Un étudiant non-fumeur disponible dès septembre',
   'false', '2'),

  ('9a828477-2b83-49b4-a558-b73e1877a0fa', '55555555-0020-0000-0000-000000000002',
   'Un étudiant non-fumeur pour l''année universitaire dès octobre',
   'true', '3'),

  ('2d9737a7-c759-4a87-9bb0-90c52ef29960', '55555555-0020-0000-0000-000000000002',
   'Un jeune actif non-fumeur en CDI',
   'false', '4'),

  ('1e6a121e-216f-4da8-afd9-d85db2d13fc7', '55555555-0021-0000-0000-000000000001',
   'Mardi à 10h en salle A',
   'false', '1'),

  ('5406402c-cb04-4985-a541-df52609e7269', '55555555-0021-0000-0000-000000000001',
   'Jeudi à 14h en salle A',
   'false', '2'),

  ('0b6f79c3-999c-49e9-9a14-62d0983a3698', '55555555-0021-0000-0000-000000000001',
   'Jeudi à 14h en salle B',
   'true', '3'),

  ('81c46c69-8ba7-4b75-9a6b-5aa58514fc02', '55555555-0021-0000-0000-000000000001',
   'Mardi à 14h en salle B',
   'false', '4'),

  ('4a43a180-e300-4b5a-858c-f076c3133c8b', '55555555-0021-0000-0000-000000000002',
   'Lors de la réunion de jeudi',
   'false', '1'),

  ('e3766640-9f36-4874-9801-7b79bffb0462', '55555555-0021-0000-0000-000000000002',
   'Mercredi midi au plus tard',
   'false', '2'),

  ('5e879560-0e96-4c24-8791-ce046a987a1c', '55555555-0021-0000-0000-000000000002',
   'À la prochaine réunion la semaine suivante',
   'true', '3'),

  ('82b1472f-dce0-4f78-89dc-5da57a928686', '55555555-0021-0000-0000-000000000002',
   'Par e-mail dans la journée',
   'false', '4'),

  ('eac27239-37c1-48c3-b0c2-3ee808c71d9a', '55555555-0021-0000-0000-000000000003',
   '12 places maximum, débutants acceptés, matériel fourni',
   'false', '1'),

  ('ed60cc3e-2a74-4aea-8074-d94b7c2dba43', '55555555-0021-0000-0000-000000000003',
   '8 places maximum, débutants bienvenus, inscription obligatoire',
   'true', '2'),

  ('41c6a1cd-3507-4706-a2f9-395e6571c399', '55555555-0021-0000-0000-000000000003',
   'Inscription le jour même sur place, tous niveaux acceptés',
   'false', '3'),

  ('37c5039c-6cd7-4e88-aa83-bc479e747bde', '55555555-0021-0000-0000-000000000003',
   'Inscription obligatoire, matériel à apporter, débutants acceptés',
   'false', '4'),

  ('ded17616-19eb-4f1c-9e67-7102f8db1d0c', '55555555-0021-0000-0000-000000000004',
   'En se présentant directement sur place le jour de l''atelier',
   'false', '1'),

  ('06d6bf4a-cfbe-41d6-a665-4fd21014958c', '55555555-0021-0000-0000-000000000004',
   'Par téléphone uniquement',
   'false', '2'),

  ('99abbcd1-2a50-4ad0-ad2e-450ce5ccde6e', '55555555-0021-0000-0000-000000000004',
   'Par téléphone ou par mail',
   'true', '3'),

  ('af8aedab-f69d-415e-8776-ced9ea2e8375', '55555555-0021-0000-0000-000000000004',
   'En remplissant un formulaire sur le site internet',
   'false', '4'),

  ('32176d91-7e81-4fc2-9c42-afc400bbab9c', '55555555-0021-0000-0000-000000000005',
   '24,00 €',
   'false', '1'),

  ('87344dc9-bc6b-423a-8b02-eacb8beb160f', '55555555-0021-0000-0000-000000000005',
   '19,00 €',
   'false', '2'),

  ('951545ba-244d-4538-b516-d33492a90cb2', '55555555-0021-0000-0000-000000000005',
   '26,50 €',
   'false', '3'),

  ('cd6b45f9-4288-4e70-a87f-2532aa0799ff', '55555555-0021-0000-0000-000000000005',
   '21,50 €',
   'true', '4'),

  ('690c39f4-8aeb-4e78-9540-60402ceb4a89', '55555555-0021-0000-0000-000000000006',
   'C''est une promotion valable jusqu''à la fin de la semaine',
   'false', '1'),

  ('68a786c6-ad1e-44d0-aa05-6bfdd1a9033d', '55555555-0021-0000-0000-000000000006',
   'Toutes les commandes au-dessus de 20 € bénéficient de cette réduction',
   'false', '2'),

  ('41476bff-f59e-4b1d-8d7c-e1802b194702', '55555555-0021-0000-0000-000000000006',
   'Il s''agit d''une remise réservée aux nouveaux clients de l''application',
   'true', '3'),

  ('ec2a180a-f508-43f7-8fa1-3d4f201e6664', '55555555-0021-0000-0000-000000000006',
   'C''est un avantage lié à son ancienneté sur l''application',
   'false', '4'),

  ('9926bade-d3cd-4c51-bae1-0d17606cd2b9', '55555555-0021-0000-0000-000000000007',
   'Une batterie et un antivol',
   'false', '1'),

  ('e0661680-a4b5-4d80-b64b-dd25455cd241', '55555555-0021-0000-0000-000000000007',
   'Deux batteries, le chargeur, la facture et un antivol',
   'true', '2'),

  ('ca99966a-7ef2-4ae0-abb1-5f97522b6b0c', '55555555-0021-0000-0000-000000000007',
   'Deux batteries, un casque et le chargeur',
   'false', '3'),

  ('60534a2c-ec0a-4a2b-a9dd-2568efde38ad', '55555555-0021-0000-0000-000000000007',
   'Le vélo et une révision gratuite en magasin',
   'false', '4'),

  ('1204394d-044b-440d-a5fe-20d57dcfc90e', '55555555-0021-0000-0000-000000000008',
   'Par envoi via un transporteur, frais à sa charge',
   'false', '1'),

  ('39669317-ba3d-4bd7-8df0-1531636afa40', '55555555-0021-0000-0000-000000000008',
   'Le vendeur peut le livrer à domicile dans Nantes',
   'false', '2'),

  ('2f385f8e-7302-4d38-a6c5-072357f3412b', '55555555-0021-0000-0000-000000000008',
   'En se déplaçant chez le vendeur à Nantes pour le récupérer',
   'true', '3'),

  ('fa04ea7f-370b-472c-90ff-6efa4a33a6a7', '55555555-0021-0000-0000-000000000008',
   'En essayant d''abord le vélo dans une autre ville',
   'false', '4'),

  ('b2923f03-c557-41a9-9156-7c54e24d7bf4', '55555555-0021-0000-0000-000000000009',
   'Pendant toute la durée de validité de sa carte',
   'false', '1'),

  ('7016bab8-9bde-46c2-977c-2ca1908ce9c3', '55555555-0021-0000-0000-000000000009',
   'Du lundi au samedi en boutique',
   'false', '2'),

  ('aef7ff5c-21ff-4a8c-b947-795e8c45236b', '55555555-0021-0000-0000-000000000009',
   'Du lundi au vendredi en boutique uniquement',
   'true', '3'),

  ('80f9d29d-d76c-4367-89ca-a407d6ef8c7e', '55555555-0021-0000-0000-000000000009',
   'Uniquement à partir de 10 visites enregistrées',
   'false', '4'),

  ('e8ed2a6c-abe8-4896-abfc-a0de763e3872', '55555555-0021-0000-0000-000000000010',
   'Elle bénéficie de la même réduction qu''en boutique',
   'false', '1'),

  ('e3d319e8-56f1-475d-ae6e-2f8e4f975cb9', '55555555-0021-0000-0000-000000000010',
   'Elle bénéficie de la réduction uniquement si la commande est passée en semaine',
   'false', '2'),

  ('4a2114ba-8be7-46f7-ad34-5a09cd2d891b', '55555555-0021-0000-0000-000000000010',
   'Aucun avantage de la carte de fidélité ne s''applique sur cette commande',
   'true', '3'),

  ('dcff1e9d-bf34-4210-a2a9-f8344af1f713', '55555555-0021-0000-0000-000000000010',
   'Sa commande sera refusée tant qu''elle utilise sa carte de fidélité',
   'false', '4'),

  ('a0013b10-3af0-4955-a097-682df32d22cc', '55555555-0021-0000-0000-000000000011',
   'Pièce d''identité et justificatif de domicile de moins de 3 mois',
   'false', '1'),

  ('b4c7e0b9-69c6-43bc-929e-c2562ed42040', '55555555-0021-0000-0000-000000000011',
   'Pièce d''identité, justificatif de domicile récent et ancien certificat d''immatriculation',
   'true', '2'),

  ('2c56fcd5-c00c-41f4-8a38-1063fdcfb822', '55555555-0021-0000-0000-000000000011',
   'Permis de conduire et ancien certificat d''immatriculation',
   'false', '3'),

  ('b2de0287-32a1-4d5a-840e-4179bd3190df', '55555555-0021-0000-0000-000000000011',
   'Pièce d''identité et avis d''imposition de l''année',
   'false', '4'),

  ('5d52d523-95d6-4b97-9bb6-509e832e6bba', '55555555-0021-0000-0000-000000000012',
   'Il doit attendre la carte définitive avant de pouvoir circuler avec son véhicule',
   'false', '1'),

  ('0015574e-68f3-4d9a-868d-456053d137d5', '55555555-0021-0000-0000-000000000012',
   'Il peut continuer à utiliser l''ancien certificat d''immatriculation du véhicule',
   'false', '2'),

  ('c4911413-b51b-4feb-87f1-9a4c419e99a0', '55555555-0021-0000-0000-000000000012',
   'Il peut circuler pendant un mois avec un certificat provisoire',
   'true', '3'),

  ('ab3a0ad6-bd71-4297-ae64-8195b6bf11c2', '55555555-0021-0000-0000-000000000012',
   'Il peut circuler librement sans aucun document particulier',
   'false', '4'),

  ('cf3ac6ed-23c2-493d-a50c-8d578a2a2a74', '55555555-0021-0000-0000-000000000013',
   'Des boissons et un cadeau personnel',
   'false', '1'),

  ('0b863474-a8e2-4f5d-b32f-68ac774a046c', '55555555-0021-0000-0000-000000000013',
   'Quelque chose à grignoter et un cadeau personnel',
   'false', '2'),

  ('857497a8-9667-4054-8e71-27cf142f7771', '55555555-0021-0000-0000-000000000013',
   'Quelque chose à grignoter, sucré ou salé',
   'true', '3'),

  ('cd0eacc8-2bfe-4528-930b-6b7a12c02958', '55555555-0021-0000-0000-000000000013',
   'De la vaisselle et des boissons',
   'false', '4'),

  ('536c4be6-9f66-4c32-9224-40ce4877a965', '55555555-0021-0000-0000-000000000014',
   'Non, il faut être présent au pot pour participer au cadeau',
   'false', '1'),

  ('b6a1b040-aba3-46c6-8621-f2c26152f4ef', '55555555-0021-0000-0000-000000000014',
   'Oui, à condition de prévenir directement Marc',
   'true', '2'),

  ('d03746fb-b9a3-4391-a96a-f187251dee3c', '55555555-0021-0000-0000-000000000014',
   'Oui, en lui donnant son argent en main propre le jour du pot',
   'false', '3'),

  ('ff3e2a36-710f-4c23-b7ec-b91bd3e89c55', '55555555-0021-0000-0000-000000000014',
   'Oui, mais il doit s''adresser à Thomas directement',
   'false', '4'),

  ('658a8a23-3921-4294-869c-238c58f12a1f', '55555555-0021-0000-0000-000000000015',
   'Non, les travaux bruyants sont interdits le samedi',
   'false', '1'),

  ('c516dc5c-b905-485f-9203-2962704c5e15', '55555555-0021-0000-0000-000000000015',
   'Oui, entre 9h et 12h',
   'true', '2'),

  ('d572ae77-8411-4492-aa20-75af84471fdc', '55555555-0021-0000-0000-000000000015',
   'Oui, mais seulement les jours de semaine',
   'false', '3'),

  ('ee9f5e68-45c3-4615-a403-15062d31e153', '55555555-0021-0000-0000-000000000015',
   'Oui, à condition de prévenir le syndic au préalable',
   'false', '4'),

  ('239bfba2-341a-49aa-ba30-07b6f32d0cb4', '55555555-0021-0000-0000-000000000016',
   'Tous les chiens sont interdits dans la copropriété',
   'false', '1'),

  ('bf0d102d-51fb-4d8f-9b51-ee49e80684f6', '55555555-0021-0000-0000-000000000016',
   'Les animaux sont autorisés à condition d''être tenus en laisse',
   'false', '2'),

  ('7f7e4ce9-c349-40f1-8e10-350004183c66', '55555555-0021-0000-0000-000000000016',
   'Les animaux sont acceptés sauf les chiens dangereux, et doivent être en laisse',
   'true', '3'),

  ('ecb823c8-ec4e-4749-b0b8-02bdd61529de', '55555555-0021-0000-0000-000000000016',
   'Les animaux sont acceptés sur accord écrit du syndic uniquement',
   'false', '4'),

  ('734b6b64-239f-4ea7-8941-d6de6aae1201', '55555555-0021-0000-0000-000000000017',
   'Pleinement satisfaits, sans réserve',
   'false', '1'),

  ('386cec91-bade-47b1-9e35-5b5c28e4e010', '55555555-0021-0000-0000-000000000017',
   'Globalement déçus du séjour',
   'false', '2'),

  ('d5477e22-8ec8-44a7-bc28-157cca5f94c3', '55555555-0021-0000-0000-000000000017',
   'Globalement satisfaits, malgré quelques désagréments',
   'true', '3'),

  ('eb37c7a2-077b-400a-a658-fa9deed294c4', '55555555-0021-0000-0000-000000000017',
   'Insatisfaits au point de déconseiller l''hôtel',
   'false', '4'),

  ('ea95f40b-79fd-4461-bf38-47ae2e602f02', '55555555-0021-0000-0000-000000000018',
   'Une chambre mal nettoyée et un personnel désagréable',
   'false', '1'),

  ('bacfec55-5cd4-4e4d-9c55-0e78d2b190de', '55555555-0021-0000-0000-000000000018',
   'Une climatisation en panne, uniquement',
   'false', '2'),

  ('2575a641-4852-4a08-b847-ec4c78245f0b', '55555555-0021-0000-0000-000000000018',
   'Une climatisation tombée en panne et un bruit de rue très matinal',
   'true', '3'),

  ('ceef7bc6-8588-485b-9a4c-2b2c40067190', '55555555-0021-0000-0000-000000000018',
   'Un personnel peu attentif et un petit-déjeuner médiocre',
   'false', '4'),

  ('f7effa60-7bd3-4f53-bd34-388d50afafc7', '55555555-0021-0000-0000-000000000019',
   'Une première semaine d''accès gratuit, toute l''année',
   'false', '1'),

  ('3331a0b3-891a-490d-b316-3c54066f752a', '55555555-0021-0000-0000-000000000019',
   'Un forfait découverte 3 mois à 60 € et des séances d''essai gratuites en septembre',
   'true', '2'),

  ('444ac627-e521-44bd-b3e5-0f0fdeabd23a', '55555555-0021-0000-0000-000000000019',
   'Une licence loisir à 60 € au lieu de 160 €',
   'false', '3'),

  ('df9b31d2-8998-4d60-95f3-04829a790d76', '55555555-0021-0000-0000-000000000019',
   'Un accès illimité à 60 € pour les hésitants',
   'false', '4'),

  ('3a287620-14b5-4c99-8299-05048b263ae5', '55555555-0021-0000-0000-000000000020',
   'En ligne, au minimum deux jours à l''avance pour tous les courts',
   'false', '1'),

  ('553f275b-18de-48ae-8c88-2381ce4a9706', '55555555-0021-0000-0000-000000000020',
   'En ligne, jusqu''au jour même de la réservation',
   'false', '2'),

  ('9f103f06-4899-49e6-b3a7-44482af230e4', '55555555-0021-0000-0000-000000000020',
   'En ligne, 2 jours à l''avance pour les courts couverts, la veille pour les extérieurs',
   'true', '3'),

  ('32af8d8d-fc4f-423b-a9ef-2d5de0cb3635', '55555555-0021-0000-0000-000000000020',
   'Par téléphone au moins une semaine à l''avance',
   'false', '4'),

  ('12d9a45d-84e1-4980-9984-d01f59ec052d', '55555555-0021-0000-0000-000000000021',
   'Prendre une douche froide juste avant de se coucher',
   'false', '1'),

  ('d33adbe8-8564-4a60-9c1b-c3a05849612c', '55555555-0021-0000-0000-000000000021',
   'Éviter toute douche dans l''heure qui précède le coucher',
   'false', '2'),

  ('656e0591-573a-45b4-b343-ea3ac493016b', '55555555-0021-0000-0000-000000000021',
   'Prendre une douche tiède environ 20 minutes avant le coucher',
   'true', '3'),

  ('565c32b2-be9e-4ed6-b9bf-fdd336bcf69d', '55555555-0021-0000-0000-000000000021',
   'Prendre une douche froide pour activer le corps avant le coucher',
   'false', '4'),

  ('fd90620e-10f7-4c05-84f3-3756de923342', '55555555-0021-0000-0000-000000000022',
   'C''est un bon facilitateur d''endormissement',
   'false', '1'),

  ('d070525e-c68f-4d9b-aba7-a181cd873ab4', '55555555-0021-0000-0000-000000000022',
   'Il empêche complètement de s''endormir',
   'false', '2'),

  ('23e73ff6-5a3b-456e-b071-2ce6c9b7c78d', '55555555-0021-0000-0000-000000000022',
   'Il facilite l''endormissement en apparence mais dégrade le sommeil profond',
   'true', '3'),

  ('76efc383-55f7-4415-ad2b-d0372572c5c5', '55555555-0021-0000-0000-000000000022',
   'Seul le vin rouge perturbe le sommeil, pas le vin blanc',
   'false', '4'),

  ('ebc1564f-d291-4a46-912f-f897879b40b9', '55555555-0021-0000-0000-000000000023',
   'Il est supprimé et remplacé par un autocar',
   'false', '1'),

  ('206ba40f-a50f-4782-b346-4e5caec88ad5', '55555555-0021-0000-0000-000000000023',
   'Il part à 7h35 avec des arrêts modifiés',
   'false', '2'),

  ('ac0371c8-0f30-44b8-a9c9-708022be3089', '55555555-0021-0000-0000-000000000023',
   'Il part à 7h35 sans changement d''arrêts',
   'true', '3'),

  ('ad770544-2e8b-491f-b2c3-54f920d8c7f7', '55555555-0021-0000-0000-000000000023',
   'Il est remplacé par un service routier au départ d''Auch',
   'false', '4'),

  ('06d65d32-3c7b-4804-acda-2e705c12ebae', '55555555-0021-0000-0000-000000000024',
   'Réserver à nouveau leur billet sur les autocars de remplacement',
   'false', '1'),

  ('9b66c844-55ac-4949-a8c0-19404eafd276', '55555555-0021-0000-0000-000000000024',
   'Demander un remboursement avant de réutiliser leur billet',
   'false', '2'),

  ('747ce0a7-4811-4765-8b95-2fa84956753d', '55555555-0021-0000-0000-000000000024',
   'Conserver leur billet, qui reste valable sans démarche supplémentaire',
   'true', '3'),

  ('08b4dc34-8db0-468c-95b5-d4ca87685277', '55555555-0021-0000-0000-000000000024',
   'Considérer leur billet comme invalide et acheter un nouveau billet',
   'false', '4');
