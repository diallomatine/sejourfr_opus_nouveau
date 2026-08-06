-- ============================================================================
-- V304 — Competences TCF : EO2 « Jeu de role : demander et obtenir des informations »
--
-- Seed du module « Competences » pour la tache EO2 (EO).
-- 8 competences, 40 petits sujets, 120 references.
--
-- Tables : skills, skill_prompts, skill_references (DDL en V025).
--
-- FICHIER GENERE — NE PAS EDITER A LA MAIN.
--
--   cd backend_sejourfr && python3 tools/competences/generer_seed.py
--
-- On edite la fiche de contenu tools/competences/contenu/EO2.json,
-- puis on regenere. Une correction faite ici serait ecrasee a la prochaine
-- generation, et les deux sources auraient diverge entre-temps.
--
-- (Le contenu vivant, lui, s'edite depuis la console d'administration une fois
-- la migration appliquee. Ce generateur ne sert qu'a republier depuis zero.)
--
-- Les UUID sont DETERMINISTES (uuid5 sur le code metier) : un identifiant de
-- contenu reste stable d'un environnement a l'autre, et rejouer la generation
-- redonne exactement le meme fichier.
--
-- Rappel du contrat : un petit sujet porte UN SEUL critere, et ses 3 references
-- (INSUFFICIENT / EXPECTED / EXCELLENT) ne se distinguent que par le respect de
-- ce critere — jamais par la quantite de fautes de langue.
-- ============================================================================

INSERT INTO skills (id, section, task_code, code, title, description,
                    general_criterion, target_level, display_order, is_active,
                    created_at, updated_at)
VALUES
  -- EO2-C1 — Commencer poliment et expliquer son besoin
  ('65e03c2e-fd8d-5b33-9171-fce7ed15108f', 'EO', 'EO2', 'EO2-C1', 'Commencer poliment et expliquer son besoin',
   'Vous ouvrez l''échange : vous saluez, vous situez rapidement votre situation et vous annoncez ce que vous cherchez. Au TCF, un interlocuteur qui comprend votre besoin dès les premières phrases peut vous répondre utilement, et le jeu de rôle démarre bien.',
   'Saluer, présenter rapidement la situation et annoncer ce que l''on recherche.',
   'B1', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2 — Formuler une question claire
  ('d3d4c89e-875e-5d02-a05a-7fcd8a992624', 'EO', 'EO2', 'EO2-C2', 'Formuler une question claire',
   'Vous transformez une intention en question complète et directement compréhensible. Une question construite en entier obtient une vraie réponse ; une question devinée oblige votre interlocuteur à vous en reposer une.',
   'Construire une question compréhensible et directement liée à la situation.',
   'B1', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3 — Demander des informations pratiques
  ('1ffc80f0-9b18-5bb4-8b5b-10a3f68170a6', 'EO', 'EO2', 'EO2-C3', 'Demander des informations pratiques',
   'Vous obtenez les informations concrètes dont vous avez besoin : prix, horaire, date, lieu, durée ou disponibilité. Au TCF, le candidat qui pose plusieurs questions utiles fait vivre le jeu de rôle bien mieux que celui qui n''en pose qu''une.',
   'Obtenir un prix, un horaire, une date, une adresse, une durée ou une disponibilité.',
   'B1', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4 — Demander les conditions et les modalités
  ('72365c64-d215-5259-9cd8-54d6ae3f2dae', 'EO', 'EO2', 'EO2-C4', 'Demander les conditions et les modalités',
   'Vous vous renseignez sur ce qu''il faut faire ou fournir : documents, inscription, paiement, règles, services compris. C''est ce qui distingue une simple curiosité d''une véritable démarche, et le TCF valorise cette précision.',
   'Se renseigner sur les documents, l''inscription, le paiement, les règles ou les services inclus.',
   'B1', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5 — Poser une question de suivi
  ('c41a70b4-2c20-5455-a009-fad634af923c', 'EO', 'EO2', 'EO2-C5', 'Poser une question de suivi',
   'Vous écoutez la réponse de votre interlocuteur et vous vous en servez pour demander une information supplémentaire pertinente. C''est ce qui montre à l''examinateur que vous menez l''échange au lieu de le subir.',
   'Utiliser la réponse de l''interlocuteur pour demander une information supplémentaire pertinente.',
   'B1', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6 — Demander une précision ou reformuler
  ('bbaf2b5d-840d-5cfe-8572-da30d97eeba0', 'EO', 'EO2', 'EO2-C6', 'Demander une précision ou reformuler',
   'Vous réagissez quand une information est incomplète, vague ou mal entendue : vous demandez qu''on répète, qu''on précise, ou vous reformulez pour vérifier. Demander une précision n''est jamais une faiblesse au TCF, c''est une compétence attendue.',
   'Réagir lorsque l''information est incomplète, ambiguë ou mal comprise.',
   'B1', 6, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7 — Comparer les possibilités et faire un choix
  ('d272143d-8eac-5638-99e8-7ed7db9dddcc', 'EO', 'EO2', 'EO2-C7', 'Comparer les possibilités et faire un choix',
   'Vous interrogez plusieurs options, vous les mettez en regard et vous annoncez votre choix en l''expliquant. Comparer puis décider montre à l''examinateur que vous maîtrisez la situation, et pas seulement le vocabulaire.',
   'Questionner sur plusieurs options, leurs différences et celle qui correspond au besoin.',
   'B1', 7, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8 — Confirmer les informations et terminer l'échange
  ('f26ed897-1c2e-54dd-ba46-17bd7874cf0a', 'EO', 'EO2', 'EO2-C8', 'Confirmer les informations et terminer l''échange',
   'Vous récapitulez les informations importantes, vous vérifiez un dernier point puis vous prenez congé. Une fin d''échange claire évite les malentendus et laisse à l''examinateur l''image d''une conversation menée jusqu''au bout.',
   'Récapituler l''essentiel, vérifier une dernière information et prendre congé naturellement.',
   'B1', 8, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');

INSERT INTO skill_prompts (id, skill_id, section, code, title, context, instruction,
                           unique_criterion, recommended_min_words, recommended_max_words,
                           recommended_duration_seconds, difficulty_level, display_order,
                           is_active, created_at, updated_at)
VALUES
  -- EO2-C1-S1 — EASY — Appeler une agence immobilière
  ('32b6d9a5-181a-5a3a-aec7-ef07423d905f', '65e03c2e-fd8d-5b33-9171-fce7ed15108f', 'EO', 'EO2-C1-S1', 'Appeler une agence immobilière',
   'Vous téléphonez à une agence immobilière de votre ville. Une conseillère décroche : « Agence Latour, bonjour. »',
   'Commencez la conversation : saluez la conseillère, dites pourquoi vous appelez et précisez ce que vous cherchez à louer.',
   'La prise de parole contient une salutation et annonce clairement le besoin de location.',
   NULL, NULL, 25, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S2 — EASY — Se présenter à l'accueil d'une salle de sport
  ('9a0cba7f-b88b-5fc9-9fb4-9c5c26861c35', '65e03c2e-fd8d-5b33-9171-fce7ed15108f', 'EO', 'EO2-C1-S2', 'Se présenter à l''accueil d''une salle de sport',
   'Vous entrez dans une salle de sport située près de chez vous. Un employé se tient à l''accueil et se tourne vers vous.',
   'Adressez-vous à lui : saluez, expliquez pourquoi vous venez et dites ce que vous souhaitez faire.',
   'La prise de parole salue l''employé et annonce l''objet de la visite en une phrase compréhensible.',
   NULL, NULL, 25, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S3 — MEDIUM — Au service scolaire de la mairie
  ('d5907348-73dc-536c-900e-4aec18b28899', '65e03c2e-fd8d-5b33-9171-fce7ed15108f', 'EO', 'EO2-C1-S3', 'Au service scolaire de la mairie',
   'Vous vous présentez au service scolaire de la mairie de votre commune. Une agente vous accueille au guichet.',
   'Saluez-la, présentez votre situation en une phrase et annoncez la démarche que vous voulez faire.',
   'La prise de parole salue, situe brièvement votre situation et nomme la démarche voulue.',
   NULL, NULL, 30, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S4 — MEDIUM — Expliquer un problème au garage
  ('9850c220-d17e-571f-b92e-20727783b93f', '65e03c2e-fd8d-5b33-9171-fce7ed15108f', 'EO', 'EO2-C1-S4', 'Expliquer un problème au garage',
   'Votre voiture fait un bruit anormal depuis quelques jours. Vous poussez la porte d''un garage du quartier ; un mécanicien vient vers vous.',
   'Saluez-le, expliquez brièvement le problème et dites clairement ce que vous attendez de lui.',
   'La prise de parole salue, décrit le problème et annonce la demande adressée au garage.',
   NULL, NULL, 35, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S5 — HARD — Chercher une formation du soir
  ('76633541-058a-55d0-954c-80d75b75266a', '65e03c2e-fd8d-5b33-9171-fce7ed15108f', 'EO', 'EO2-C1-S5', 'Chercher une formation du soir',
   'Vous travaillez en journée et vous souhaitez reprendre une formation. Vous téléphonez à un centre de formation de votre région ; une conseillère décroche.',
   'Ouvrez la conversation : saluez, présentez votre situation professionnelle et annoncez précisément la formation que vous recherchez.',
   'La prise de parole salue, expose votre situation et annonce le type de formation recherché.',
   NULL, NULL, 45, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S1 — EASY — Horaires de la piscine
  ('316887d7-4ec0-5bcd-8fa2-6e982f6929c7', 'd3d4c89e-875e-5d02-a05a-7fcd8a992624', 'EO', 'EO2-C2-S1', 'Horaires de la piscine',
   'Vous téléphonez à la piscine municipale de votre ville. Un agent d''accueil vous répond.',
   'Posez-lui une question claire pour savoir si la piscine est ouverte au public le samedi matin.',
   'Une question complète et compréhensible porte sur l''ouverture au public le samedi matin.',
   NULL, NULL, 20, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S2 — EASY — Emprunter à la médiathèque
  ('59782b3c-60dc-523c-b9b3-9b62c5c514e3', 'd3d4c89e-875e-5d02-a05a-7fcd8a992624', 'EO', 'EO2-C2-S2', 'Emprunter à la médiathèque',
   'Vous êtes à l''accueil de la médiathèque de votre commune. Une bibliothécaire est disponible derrière le comptoir.',
   'Posez-lui une question claire pour savoir combien de livres vous pouvez emprunter en même temps.',
   'La question est complète et porte exactement sur le nombre de livres empruntables en même temps.',
   NULL, NULL, 20, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S3 — MEDIUM — Vérifier la fibre à son adresse
  ('0cf8a154-3312-50fc-9cee-b17128bb7cc8', 'd3d4c89e-875e-5d02-a05a-7fcd8a992624', 'EO', 'EO2-C2-S3', 'Vérifier la fibre à son adresse',
   'Vous appelez le service client de votre opérateur internet. Après quelques minutes d''attente, un conseiller prend votre appel.',
   'Posez-lui une question claire pour savoir si la fibre est disponible à votre adresse.',
   'La question est formulée en entier et permet au conseiller de vérifier la disponibilité à votre adresse.',
   NULL, NULL, 25, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S4 — MEDIUM — Une place en crèche pour septembre
  ('43926060-1554-5b8a-b161-aad67e8cbcff', 'd3d4c89e-875e-5d02-a05a-7fcd8a992624', 'EO', 'EO2-C2-S4', 'Une place en crèche pour septembre',
   'Vous téléphonez à une crèche municipale. La directrice prend votre appel.',
   'Posez une question claire pour savoir s''il reste une place pour votre enfant à la rentrée de septembre.',
   'La question est complète et précise l''enfant concerné ainsi que la période demandée.',
   NULL, NULL, 25, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S5 — HARD — Rendez-vous obligatoire en préfecture
  ('9141e1bf-8010-5081-a4e8-55aeb425916f', 'd3d4c89e-875e-5d02-a05a-7fcd8a992624', 'EO', 'EO2-C2-S5', 'Rendez-vous obligatoire en préfecture',
   'Vous devez renouveler votre titre de séjour. Vous appelez le standard de la préfecture ; une agente décroche.',
   'Posez une question claire pour savoir si un rendez-vous est obligatoire avant de déposer votre dossier.',
   'La question est construite en entier et porte précisément sur l''obligation de prendre rendez-vous.',
   NULL, NULL, 30, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S1 — EASY — Cours de français d'une association
  ('8d27a19d-7a77-58e0-b3c6-862969a042f3', '1ffc80f0-9b18-5bb4-8b5b-10a3f68170a6', 'EO', 'EO2-C3-S1', 'Cours de français d''une association',
   'Une association de votre quartier propose des cours de français aux adultes. Vous passez à sa permanence et une bénévole vous reçoit.',
   'Demandez-lui deux informations pratiques : quels jours ont lieu les cours et à quelle heure.',
   'Les deux informations demandées, les jours et les horaires, sont réclamées explicitement.',
   NULL, NULL, 30, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S2 — EASY — Prix et durée du permis
  ('73acf70c-a97d-5134-81b8-cffe7845e52d', '1ffc80f0-9b18-5bb4-8b5b-10a3f68170a6', 'EO', 'EO2-C3-S2', 'Prix et durée du permis',
   'Vous voulez passer le permis de conduire. Vous entrez dans une auto-école de votre ville et un formateur vous reçoit.',
   'Demandez-lui deux informations pratiques : le prix du forfait et la durée moyenne de la formation.',
   'Le prix et la durée de la formation sont tous les deux demandés explicitement.',
   NULL, NULL, 30, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S3 — MEDIUM — Trois questions sur un cours de guitare
  ('09101337-d168-5262-a84b-f81fcb233b18', '1ffc80f0-9b18-5bb4-8b5b-10a3f68170a6', 'EO', 'EO2-C3-S3', 'Trois questions sur un cours de guitare',
   'Un centre culturel propose des cours de guitare pour adultes. Vous téléphonez et un animateur vous répond.',
   'Posez trois questions pour connaître le prix du cours, son horaire et le lieu exact où il se déroule.',
   'Les trois informations, prix, horaire et lieu, sont demandées chacune explicitement.',
   NULL, NULL, 40, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S4 — MEDIUM — Un séjour à Marseille
  ('5de1234a-9d3c-56ab-81e9-7837ed274852', '1ffc80f0-9b18-5bb4-8b5b-10a3f68170a6', 'EO', 'EO2-C3-S4', 'Un séjour à Marseille',
   'Vous préparez un séjour d''une semaine à Marseille pour les vacances de printemps. Vous entrez dans une agence de voyage et une conseillère vous invite à vous asseoir.',
   'Demandez-lui trois informations pratiques : les dates de départ possibles, la durée du séjour proposé et le prix par personne.',
   'Les trois informations, dates, durée et prix, sont demandées chacune explicitement.',
   NULL, NULL, 40, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S5 — HARD — Le centre de loisirs cet été
  ('b3a8cd58-bce6-5b54-a3b9-40d05d9ca116', '1ffc80f0-9b18-5bb4-8b5b-10a3f68170a6', 'EO', 'EO2-C3-S5', 'Le centre de loisirs cet été',
   'Votre fille de huit ans souhaite aller au centre de loisirs pendant les vacances d''été. Vous appelez le directeur du centre.',
   'Demandez-lui quatre informations pratiques : les dates d''ouverture, les horaires d''accueil, le tarif à la journée et l''adresse du centre.',
   'Les quatre informations demandées sont réclamées chacune de façon explicite.',
   NULL, NULL, 45, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S1 — EASY — Inscrire son enfant à la cantine
  ('edfacf14-5cd7-5459-963b-737c938855d3', '72365c64-d215-5259-9cd8-54d6ae3f2dae', 'EO', 'EO2-C4-S1', 'Inscrire son enfant à la cantine',
   'Vous voulez inscrire votre enfant à la cantine scolaire. Vous vous présentez au guichet du service scolaire de la mairie.',
   'Demandez à l''agente quelles conditions il faut remplir et quels documents vous devez fournir pour cette inscription.',
   'La demande porte explicitement sur les documents ou les conditions exigés pour l''inscription.',
   NULL, NULL, 30, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S2 — EASY — Livraison et garantie d'un lave-linge
  ('35cd48ce-7d0b-5ffd-ac27-8967c1c99f94', '72365c64-d215-5259-9cd8-54d6ae3f2dae', 'EO', 'EO2-C4-S2', 'Livraison et garantie d''un lave-linge',
   'Vous venez de choisir un lave-linge dans un magasin d''électroménager. Le vendeur prépare la commande sur son ordinateur.',
   'Demandez-lui les conditions du service : ce que comprend la livraison et ce que couvre la garantie.',
   'La demande porte explicitement sur les modalités de livraison et sur la garantie.',
   NULL, NULL, 30, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S3 — MEDIUM — Ouvrir un compte bancaire
  ('ff11b141-eb2f-54a0-b725-f2489f1b9f23', '72365c64-d215-5259-9cd8-54d6ae3f2dae', 'EO', 'EO2-C4-S3', 'Ouvrir un compte bancaire',
   'Vous venez d''arriver dans une nouvelle ville et vous voulez ouvrir un compte bancaire. Un conseiller vous reçoit à son bureau.',
   'Demandez-lui les conditions d''ouverture : les documents nécessaires et les frais éventuels.',
   'La demande porte à la fois sur les pièces exigées et sur les frais du compte.',
   NULL, NULL, 35, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S4 — MEDIUM — Le dossier de location
  ('89dad550-8af1-5e26-95bc-79e43410bc9c', '72365c64-d215-5259-9cd8-54d6ae3f2dae', 'EO', 'EO2-C4-S4', 'Le dossier de location',
   'Une agence immobilière vous propose un appartement qui vous plaît. Avant d''organiser la visite, le conseiller vous demande si vous avez des questions.',
   'Demandez-lui quelles pièces composent le dossier de location et quelles conditions sont exigées pour être retenu.',
   'La demande porte sur les pièces du dossier et sur les conditions exigées, revenus, garant ou dépôt.',
   NULL, NULL, 40, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S5 — HARD — Conditions d'accès à une formation
  ('2b318794-27ea-5628-b8aa-28b5f756244b', '72365c64-d215-5259-9cd8-54d6ae3f2dae', 'EO', 'EO2-C4-S5', 'Conditions d''accès à une formation',
   'Vous êtes inscrit à France Travail et une formation de magasinier vous intéresse. Votre conseillère vous reçoit pour en parler.',
   'Demandez-lui les conditions d''accès à cette formation, la façon dont elle est financée et ce qui est attendu de vous pendant les cours.',
   'La demande couvre les conditions d''accès, le financement et les obligations du stagiaire.',
   NULL, NULL, 45, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S1 — EASY — Le loyer et les charges
  ('de8ae451-dfed-5823-98b6-f13d48fe4d8f', 'c41a70b4-2c20-5455-a009-fad634af923c', 'EO', 'EO2-C5-S1', 'Le loyer et les charges',
   'Vous cherchez un appartement à louer. Au téléphone, l''employé de l''agence vous répond : « Le logement est libre le 15 mars, il est à 620 euros par mois. »',
   'Rebondissez sur cette réponse : posez une question de suivi sur ce que ce prix comprend réellement.',
   'La question posée s''appuie sur l''information reçue et porte sur ce qu''inclut le loyer annoncé.',
   NULL, NULL, 25, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S2 — EASY — Après l'horaire du cours de yoga
  ('10a608d2-4d4d-5174-a9d8-6d0df4a8c613', 'c41a70b4-2c20-5455-a009-fad634af923c', 'EO', 'EO2-C5-S2', 'Après l''horaire du cours de yoga',
   'Vous vous renseignez sur un cours de yoga dans une association de quartier. La responsable vous dit : « Le cours a lieu tous les mardis à dix-neuf heures. »',
   'Rebondissez sur cette réponse : posez une question de suivi utile à partir de l''horaire annoncé.',
   'La question s''appuie sur l''horaire annoncé et demande une information supplémentaire liée à ce cours.',
   NULL, NULL, 25, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S3 — MEDIUM — Un créneau chez le médecin
  ('99719e32-a7fa-552e-bcd5-fc00ba56d52f', 'c41a70b4-2c20-5455-a009-fad634af923c', 'EO', 'EO2-C5-S3', 'Un créneau chez le médecin',
   'Vous appelez un cabinet médical pour prendre rendez-vous. La secrétaire vous répond : « Le docteur Lemaire peut vous recevoir jeudi à seize heures trente. »',
   'Rebondissez sur cette proposition : dites si elle vous convient, puis posez une question de suivi sur ce rendez-vous.',
   'La réponse reprend le créneau proposé et demande une information supplémentaire liée à ce rendez-vous.',
   NULL, NULL, 30, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S4 — MEDIUM — Après la durée de la formation
  ('ab4a0dfb-108a-54aa-9712-11b464656368', 'c41a70b4-2c20-5455-a009-fad634af923c', 'EO', 'EO2-C5-S4', 'Après la durée de la formation',
   'Vous vous renseignez sur une formation d''aide à la personne. La conseillère vous annonce : « La formation dure six mois, à raison de trois jours par semaine. »',
   'Rebondissez sur cette réponse : posez une ou deux questions de suivi sur l''organisation concrète de cette formation.',
   'Les questions s''appuient sur la durée annoncée et portent sur l''organisation concrète de la formation.',
   NULL, NULL, 35, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S5 — HARD — Le vrai prix du forfait
  ('734532e5-ca28-5a19-bbd5-abd42fec5055', 'c41a70b4-2c20-5455-a009-fad634af923c', 'EO', 'EO2-C5-S5', 'Le vrai prix du forfait',
   'Un conseiller d''un opérateur téléphonique vous présente une offre : « Notre forfait fibre est à 24,99 euros par mois pendant douze mois. »',
   'Rebondissez : posez deux questions de suivi qui vous permettront de savoir ce que vous paierez réellement.',
   'Deux questions de suivi s''appuient sur le prix annoncé et portent sur le coût réel de l''offre.',
   NULL, NULL, 40, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S1 — EASY — Une heure mal entendue
  ('f78e0290-a805-50ac-ab01-1207b285f22a', 'bbaf2b5d-840d-5cfe-8572-da30d97eeba0', 'EO', 'EO2-C6-S1', 'Une heure mal entendue',
   'Vous appelez la mairie. L''agente vous indique l''heure de fermeture du guichet, mais la ligne est mauvaise et vous n''avez pas entendu ce qu''elle a dit.',
   'Signalez poliment que vous n''avez pas compris et demandez-lui de répéter cette information.',
   'La demande signale l''incompréhension et réclame explicitement la répétition de l''heure.',
   NULL, NULL, 25, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S2 — EASY — Une livraison « en fin de semaine »
  ('61c3be19-0b1a-5bf4-a771-f00441723801', 'bbaf2b5d-840d-5cfe-8572-da30d97eeba0', 'EO', 'EO2-C6-S2', 'Une livraison « en fin de semaine »',
   'Au bureau de poste, l''employé consulte votre suivi et vous dit : « Votre colis sera livré en fin de semaine. »',
   'Demandez-lui une précision pour savoir exactement quand le colis arrivera chez vous.',
   'La demande signale que l''information est trop vague et réclame une précision de date.',
   NULL, NULL, 25, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S3 — MEDIUM — Un devis approximatif
  ('f4c947d0-0763-56c4-8b4d-061de8a23d0c', 'bbaf2b5d-840d-5cfe-8572-da30d97eeba0', 'EO', 'EO2-C6-S3', 'Un devis approximatif',
   'Le garagiste examine votre voiture, referme le capot et vous annonce : « Ça devrait coûter dans les trois cents euros. »',
   'Demandez-lui des précisions sur ce montant, qui reste approximatif.',
   'La demande porte sur ce que couvre le montant annoncé ou sur son caractère approximatif.',
   NULL, NULL, 30, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S4 — MEDIUM — Un justificatif « récent »
  ('b25cf5d2-f696-5757-833f-9bc163b58b66', 'bbaf2b5d-840d-5cfe-8572-da30d97eeba0', 'EO', 'EO2-C6-S4', 'Un justificatif « récent »',
   'À la préfecture, l''agent parcourt la liste des pièces à fournir et vous dit : « Il faudra joindre un justificatif de domicile récent. »',
   'Demandez-lui de préciser quels documents sont acceptés et ce que le mot « récent » signifie ici.',
   'La demande porte sur la nature des documents acceptés et sur l''ancienneté maximale admise.',
   NULL, NULL, 35, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S5 — HARD — Vérifier ce qu'est une franchise
  ('2fe51b50-d3a9-5b55-bc60-4a1cdc1b0ca7', 'bbaf2b5d-840d-5cfe-8572-da30d97eeba0', 'EO', 'EO2-C6-S5', 'Vérifier ce qu''est une franchise',
   'Une conseillère en assurance vous explique rapidement : « Avec cette formule, vous êtes couvert en cas de dégât des eaux, mais il reste une franchise de cent cinquante euros à votre charge. »',
   'Reformulez avec vos propres mots ce que vous avez compris, puis demandez-lui de confirmer.',
   'La production reformule l''information avec d''autres mots et demande explicitement une confirmation.',
   NULL, NULL, 40, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S1 — EASY — Deux formules à la salle de sport
  ('0c63a91f-1f3d-590e-abce-f2673fd6ee05', 'd272143d-8eac-5638-99e8-7ed7db9dddcc', 'EO', 'EO2-C7-S1', 'Deux formules à la salle de sport',
   'À la salle de sport, l''employé vous présente deux formules : « L''abonnement mensuel est à 39 euros, sans engagement. L''abonnement à l''année revient à 29 euros par mois, mais vous vous engagez douze mois. »',
   'Interrogez-le sur la différence entre les deux formules, puis dites laquelle vous choisissez et pourquoi.',
   'La production compare les deux formules et annonce un choix accompagné d''une raison.',
   NULL, NULL, 35, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S2 — EASY — Deux forfaits mobiles
  ('fd1f41fe-da53-56bb-90ac-8ee28f4487c5', 'd272143d-8eac-5638-99e8-7ed7db9dddcc', 'EO', 'EO2-C7-S2', 'Deux forfaits mobiles',
   'Un conseiller vous présente deux forfaits mobiles : « Le premier est à 9,99 euros avec 20 gigaoctets. Le second est à 19,99 euros avec 100 gigaoctets et les appels illimités vers l''étranger. »',
   'Posez une question sur la différence entre les deux forfaits, puis annoncez votre choix en expliquant pourquoi.',
   'La production met les deux forfaits en regard et justifie le choix final.',
   NULL, NULL, 35, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S3 — MEDIUM — Train ou bus pour Lyon
  ('74370a01-1767-59bb-9c99-d437b4722ec5', 'd272143d-8eac-5638-99e8-7ed7db9dddcc', 'EO', 'EO2-C7-S3', 'Train ou bus pour Lyon',
   'En agence de voyage, la conseillère vous propose deux trajets pour aller à Lyon : « Le train met deux heures trente et coûte 55 euros. Le bus met cinq heures et coûte 25 euros. »',
   'Interrogez-la sur ce qui distingue les deux trajets, puis choisissez-en un en justifiant votre décision.',
   'La production compare les deux trajets sur au moins deux aspects et justifie le choix retenu.',
   NULL, NULL, 40, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S4 — MEDIUM — Cours du soir ou du samedi
  ('2346c516-c085-523d-85b4-d485c28352f0', 'd272143d-8eac-5638-99e8-7ed7db9dddcc', 'EO', 'EO2-C7-S4', 'Cours du soir ou du samedi',
   'Un centre de formation vous propose deux organisations pour le même diplôme : « Soit trois soirées par semaine pendant quatre mois, soit tous les samedis pendant huit mois. »',
   'Posez des questions sur ces deux formules, comparez-les, puis dites laquelle vous convient et pourquoi.',
   'Les deux formules sont comparées sur des points concrets et le choix est justifié par votre situation.',
   NULL, NULL, 45, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S5 — HARD — Deux contrats d'assurance habitation
  ('814d0d84-a34d-50e2-bff6-46987f36e6d7', 'd272143d-8eac-5638-99e8-7ed7db9dddcc', 'EO', 'EO2-C7-S5', 'Deux contrats d''assurance habitation',
   'Une conseillère en assurance vous présente deux contrats pour votre appartement : « La formule de base est à 12 euros par mois, avec 300 euros de franchise. La formule confort est à 19 euros, avec 100 euros de franchise et le remplacement à neuf des appareils. »',
   'Posez des questions pour bien saisir ce qui distingue ces deux contrats, comparez-les, puis annoncez votre choix en l''expliquant.',
   'La production interroge et compare les deux contrats sur plusieurs points, puis justifie le choix retenu.',
   NULL, NULL, 55, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S1 — EASY — Confirmer un rendez-vous médical
  ('945c7e12-76e3-5f5c-8a20-bce909e09a37', 'f26ed897-1c2e-54dd-ba46-17bd7874cf0a', 'EO', 'EO2-C8-S1', 'Confirmer un rendez-vous médical',
   'La secrétaire médicale vous confirme : « C''est noté : rendez-vous le mardi 10 mars à quatorze heures avec le docteur Aubry, au deuxième étage. »',
   'Récapitulez les informations importantes pour vérifier qu''elles sont exactes, puis prenez congé.',
   'La production reprend les informations essentielles du rendez-vous et se termine par une formule de congé.',
   NULL, NULL, 30, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S2 — EASY — Confirmer une réparation
  ('567b60b9-03d1-59cd-8cc0-3bfd072246f7', 'f26ed897-1c2e-54dd-ba46-17bd7874cf0a', 'EO', 'EO2-C8-S2', 'Confirmer une réparation',
   'Le garagiste conclut votre échange : « Votre voiture sera prête vendredi à dix-sept heures, et la réparation coûtera 240 euros. »',
   'Reprenez ces informations pour les confirmer, puis terminez poliment la conversation.',
   'La production répète l''heure et le montant annoncés et se clôt par une formule de congé.',
   NULL, NULL, 30, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S3 — MEDIUM — Fin d'entretien à la crèche
  ('c882e2e7-5134-5c94-9135-a923abe6c405', 'f26ed897-1c2e-54dd-ba46-17bd7874cf0a', 'EO', 'EO2-C8-S3', 'Fin d''entretien à la crèche',
   'La directrice de la crèche conclut : « Déposez le dossier complet avant le 30 avril. La commission se réunit en juin et vous recevrez la réponse par courrier. »',
   'Récapitulez ces informations, vérifiez un point qui reste à confirmer, puis prenez congé.',
   'La production reprend les informations reçues, ajoute une question de vérification et se termine par un congé.',
   NULL, NULL, 40, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S4 — MEDIUM — Confirmer une location de voiture
  ('7d8f4b6c-e2cf-5068-9044-3306fdca54ba', 'f26ed897-1c2e-54dd-ba46-17bd7874cf0a', 'EO', 'EO2-C8-S4', 'Confirmer une location de voiture',
   'L''agent de location vous récapitule : « Vous prenez le véhicule le samedi 12 à neuf heures à l''agence de la gare, vous le rendez le lundi 14 avant midi, pour un total de 96 euros. »',
   'Reprenez ces informations pour les confirmer, posez une dernière question utile, puis terminez l''échange.',
   'La production confirme les dates, le lieu et le prix, ajoute une dernière question et clôt l''échange.',
   NULL, NULL, 45, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S5 — HARD — Clore une inscription au centre social
  ('78a8129e-7e6b-5f1c-8001-4c071aac6aa9', 'f26ed897-1c2e-54dd-ba46-17bd7874cf0a', 'EO', 'EO2-C8-S5', 'Clore une inscription au centre social',
   'Au centre social, l''animatrice conclut votre inscription : « Les ateliers d''informatique ont lieu le jeudi de dix-huit à vingt heures, à partir du 15 septembre, en salle 3. L''adhésion annuelle est de 20 euros et il faut apporter une photo d''identité. »',
   'Récapitulez l''essentiel de ces informations, vérifiez le point qui vous semble le moins clair, puis prenez congé.',
   'La production reprend l''essentiel des informations, vérifie un point précis et se termine par un congé.',
   NULL, NULL, 55, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');

INSERT INTO skill_references (id, skill_prompt_id, level, text, pedagogical_note,
                              created_at, updated_at)
VALUES
  -- EO2-C1-S1 / INSUFFICIENT
  ('89efca32-82d4-56bb-ab75-3530f66e9ef9', '32b6d9a5-181a-5a3a-aec7-ef07423d905f', 'INSUFFICIENT',
   'Bonjour madame. Voilà, c''est pour un renseignement s''il vous plaît.',
   'La salutation est là, mais la conseillère ignore encore ce que vous cherchez.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S1 / EXPECTED
  ('5030faa6-8930-54e0-9547-d25167310a71', '32b6d9a5-181a-5a3a-aec7-ef07423d905f', 'EXPECTED',
   'Bonjour madame. Je vous appelle parce que je cherche un appartement à louer dans le centre-ville.',
   'Salutation et besoin annoncés : la conseillère peut déjà vous orienter.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S1 / EXCELLENT
  ('e9073ce2-8cf4-54fd-b4ab-ac8a2f79ac60', '32b6d9a5-181a-5a3a-aec7-ef07423d905f', 'EXCELLENT',
   'Bonjour madame. Je m''appelle Awa Camara. Je vous appelle au sujet de votre annonce pour le studio de la rue des Lilas : je cherche à louer à partir du mois de mars.',
   'Le besoin est daté et situé : l''échange démarre tout de suite sur du concret.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S2 / INSUFFICIENT
  ('9f28ad4f-eba9-527e-a0ba-efe2c00562bc', '9a0cba7f-b88b-5fc9-9fb4-9c5c26861c35', 'INSUFFICIENT',
   'Bonjour. Est-ce que je peux avoir des informations, s''il vous plaît ?',
   'Le mot « informations » ne dit pas sur quoi : l''employé doit tout deviner.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S2 / EXPECTED
  ('4e98c8af-a82d-5fb1-a03a-bd117b804005', '9a0cba7f-b88b-5fc9-9fb4-9c5c26861c35', 'EXPECTED',
   'Bonjour monsieur. Je voudrais m''inscrire à la salle et je viens me renseigner sur vos formules.',
   'Salutation et objet de la visite : l''employé sait quoi vous présenter.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S2 / EXCELLENT
  ('51b61c03-1e3f-596a-b5d4-f6a8963b2d4f', '9a0cba7f-b88b-5fc9-9fb4-9c5c26861c35', 'EXCELLENT',
   'Bonjour monsieur. J''habite dans le quartier depuis un mois et j''aimerais m''inscrire pour venir nager et courir le soir après le travail. Pouvez-vous me présenter vos formules ?',
   'Le besoin est situé et précisé : la réponse sera adaptée à vos horaires.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S3 / INSUFFICIENT
  ('198fca46-cf88-5e6c-93bf-3cd176d3bdb2', 'd5907348-73dc-536c-900e-4aec18b28899', 'INSUFFICIENT',
   'Bonjour madame. C''est pour l''école de mon fils.',
   'La démarche reste à deviner : inscription, changement d''école ou simple question ?', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S3 / EXPECTED
  ('efde73dd-cf3a-558b-9710-cd81c1f4dfac', 'd5907348-73dc-536c-900e-4aec18b28899', 'EXPECTED',
   'Bonjour madame. Nous venons d''emménager dans le quartier et je voudrais inscrire mon fils à l''école primaire.',
   'Situation et démarche sont dites : l''agente peut ouvrir le bon dossier.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S3 / EXCELLENT
  ('22a4f8a2-8077-5bbb-b83b-0dd23df20716', 'd5907348-73dc-536c-900e-4aec18b28899', 'EXCELLENT',
   'Bonjour madame. Nous avons emménagé rue Victor-Hugo au mois d''août et je souhaite inscrire mon fils Ibrahim, qui a sept ans, à l''école primaire pour la rentrée.',
   'L''âge, l''adresse et la période évitent plusieurs questions à l''agente.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S4 / INSUFFICIENT
  ('79cd19d0-d6b2-5486-8e4f-de57f6336e25', '9850c220-d17e-571f-b92e-20727783b93f', 'INSUFFICIENT',
   'Bonjour monsieur. Ma voiture fait un bruit bizarre depuis lundi, surtout quand je freine.',
   'Le problème est clair, mais vous ne dites pas ce que vous demandez au garage.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S4 / EXPECTED
  ('0b1fa50a-a064-58c0-a854-ca00f02592ab', '9850c220-d17e-571f-b92e-20727783b93f', 'EXPECTED',
   'Bonjour monsieur. Ma voiture fait un bruit quand je freine et je voudrais que vous regardiez d''où cela vient.',
   'Problème et demande sont réunis : le mécanicien sait quoi faire.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S4 / EXCELLENT
  ('27a56639-4f39-5961-9dfc-38ebd0f68888', '9850c220-d17e-571f-b92e-20727783b93f', 'EXCELLENT',
   'Bonjour monsieur. Depuis lundi, ma voiture fait un bruit de frottement dès que je freine. J''aimerais que vous l''examiniez cette semaine et que vous me fassiez un devis avant la réparation.',
   'Le délai et le devis transforment la plainte en véritable demande de service.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S5 / INSUFFICIENT
  ('f0c557d6-ea93-5027-a406-1b25493328b2', '76633541-058a-55d0-954c-80d75b75266a', 'INSUFFICIENT',
   'Bonjour madame. Je voudrais des renseignements sur vos formations, s''il vous plaît.',
   'Sans votre situation ni le domaine visé, la conseillère ne peut rien proposer.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S5 / EXPECTED
  ('a997801a-745e-5e24-a3ff-bdc6e762a9d9', '76633541-058a-55d0-954c-80d75b75266a', 'EXPECTED',
   'Bonjour madame. Je travaille toute la journée et je cherche une formation en comptabilité que je pourrais suivre le soir.',
   'Contrainte horaire et domaine annoncés : la recherche est déjà ciblée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C1-S5 / EXCELLENT
  ('a6296f84-ea00-55cb-be4b-5ca9945a570a', '76633541-058a-55d0-954c-80d75b75266a', 'EXCELLENT',
   'Bonjour madame. Je m''appelle Rachid Benali, je suis employé dans un supermarché du lundi au vendredi. Je voudrais me former à la comptabilité pour changer de poste, donc je cherche des cours du soir ou du samedi.',
   'L''objectif professionnel explique la demande et oriente vers la bonne formule.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S1 / INSUFFICIENT
  ('5e28d562-9d08-5611-b8a6-dd3b6002b525', '316887d7-4ec0-5bcd-8fa2-6e982f6929c7', 'INSUFFICIENT',
   'Bonjour. La piscine, le samedi ?',
   'L''idée est là, mais la question n''est pas construite et reste à deviner.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S1 / EXPECTED
  ('3abd2b7b-ff28-54be-876b-0b652ba7d853', '316887d7-4ec0-5bcd-8fa2-6e982f6929c7', 'EXPECTED',
   'Bonjour monsieur. Est-ce que la piscine est ouverte au public le samedi matin ?',
   'Question entière et directe : l''agent peut répondre par oui ou non.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S1 / EXCELLENT
  ('d7104d96-df84-5a66-add8-81d2a8df1bf5', '316887d7-4ec0-5bcd-8fa2-6e982f6929c7', 'EXCELLENT',
   'Bonjour monsieur. Je voudrais savoir si la piscine est ouverte au public le samedi matin, ou si le bassin est réservé aux clubs à ce moment-là.',
   'La question anticipe le cas fréquent des créneaux réservés aux clubs.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S2 / INSUFFICIENT
  ('54f118bb-f9a3-5415-8679-0fa13f9b5b88', '59782b3c-60dc-523c-b9b3-9b62c5c514e3', 'INSUFFICIENT',
   'Bonjour. Les livres, on prend combien ?',
   'Le sens passe à peine ; la question mérite d''être formulée en entier.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S2 / EXPECTED
  ('4445a77b-111a-522a-bed5-4db44c7cb32b', '59782b3c-60dc-523c-b9b3-9b62c5c514e3', 'EXPECTED',
   'Bonjour madame. Est-ce que vous pouvez me dire combien de livres on peut emprunter en même temps ?',
   'Question construite et polie : elle appelle une réponse chiffrée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S2 / EXCELLENT
  ('fdaee985-15ef-5cab-a27b-b91d6d6a49a2', '59782b3c-60dc-523c-b9b3-9b62c5c514e3', 'EXCELLENT',
   'Bonjour madame. Je viens de m''inscrire ici et j''aimerais savoir combien de livres je peux emprunter en même temps avec ma carte.',
   'Le rappel de votre situation évite une réponse générale qui ne vous concerne pas.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S3 / INSUFFICIENT
  ('1e631425-3500-5564-bcd9-6fefb41179a9', '0cf8a154-3312-50fc-9cee-b17128bb7cc8', 'INSUFFICIENT',
   'Bonjour. La fibre chez moi, c''est possible ou pas ?',
   'Le conseiller ne peut rien vérifier : ni adresse, ni question construite.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S3 / EXPECTED
  ('cc0311e0-f3d5-53df-9790-db77e79428ba', '0cf8a154-3312-50fc-9cee-b17128bb7cc8', 'EXPECTED',
   'Bonjour monsieur. Je voudrais savoir si la fibre est disponible à mon adresse, au 12 rue des Écoles à Nantes.',
   'L''adresse dans la question permet une vérification immédiate.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S3 / EXCELLENT
  ('5ad1408a-6982-50da-9ff7-625ae88baa0c', '0cf8a154-3312-50fc-9cee-b17128bb7cc8', 'EXCELLENT',
   'Bonjour monsieur. J''habite au 12 rue des Écoles à Nantes, dans un immeuble de six logements. Est-ce que vous pouvez vérifier si la fibre est déjà installée à cette adresse ?',
   'Le détail de l''immeuble aide le conseiller à trouver la bonne fiche technique.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S4 / INSUFFICIENT
  ('bc89450b-6dbe-5441-9d4c-9c57448b3e7e', '43926060-1554-5b8a-b161-aad67e8cbcff', 'INSUFFICIENT',
   'Bonjour madame. Est-ce que vous avez de la place ?',
   'Ni l''enfant ni la date ne sont dits : la réponse risque d''être inutile.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S4 / EXPECTED
  ('fb818d8e-034b-5c62-a668-0d7fd6f1da68', '43926060-1554-5b8a-b161-aad67e8cbcff', 'EXPECTED',
   'Bonjour madame. Est-ce qu''il vous reste une place pour ma fille à partir du mois de septembre ?',
   'L''enfant et la période sont précisés : la directrice peut consulter ses listes.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S4 / EXCELLENT
  ('ba517f81-3a5c-5f56-bb62-919ce7c7be87', '43926060-1554-5b8a-b161-aad67e8cbcff', 'EXCELLENT',
   'Bonjour madame. Ma fille aura dix-huit mois en septembre. Est-ce qu''il vous reste une place pour elle à la rentrée, à temps plein ?',
   'L''âge et le temps d''accueil évitent une réponse qui ne correspondrait pas.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S5 / INSUFFICIENT
  ('52c1ea76-06d2-5e39-a3ac-dc76c9bd3206', '9141e1bf-8010-5081-a4e8-55aeb425916f', 'INSUFFICIENT',
   'Bonjour madame. Je viens quand pour mon titre de séjour ?',
   'La demande est floue : rendez-vous, horaires d''ouverture ou date limite ?', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S5 / EXPECTED
  ('12076148-8953-58f0-8971-376e8b8aec5a', '9141e1bf-8010-5081-a4e8-55aeb425916f', 'EXPECTED',
   'Bonjour madame. Je dois renouveler mon titre de séjour. Est-ce qu''il faut obligatoirement un rendez-vous pour déposer le dossier ?',
   'La démarche puis la question : l''agente répond sans avoir à vous relancer.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C2-S5 / EXCELLENT
  ('20124e89-dafc-59f5-87cf-e0f099fd0e2f', '9141e1bf-8010-5081-a4e8-55aeb425916f', 'EXCELLENT',
   'Bonjour madame. Mon titre de séjour expire en octobre et je prépare mon renouvellement. Est-ce que le dépôt du dossier se fait uniquement sur rendez-vous, ou puis-je me présenter directement au guichet ?',
   'Les deux possibilités sont nommées : la réponse ne pourra pas rester ambiguë.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S1 / INSUFFICIENT
  ('cf783e3a-dde1-5d18-9f72-2df4e2130e27', '8d27a19d-7a77-58e0-b3c6-862969a042f3', 'INSUFFICIENT',
   'Bonjour madame. Je voudrais connaître les horaires des cours de français, s''il vous plaît.',
   'Les horaires seuls ne suffisent pas : vous ignorez encore quels jours venir.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S1 / EXPECTED
  ('896b8733-81c5-5dd8-a196-dc96d37825c0', '8d27a19d-7a77-58e0-b3c6-862969a042f3', 'EXPECTED',
   'Bonjour madame. Je voudrais m''inscrire aux cours de français. Quels jours ont-ils lieu, et à quelle heure commencent-ils ?',
   'Les deux informations sont demandées clairement, dans une seule prise de parole.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S1 / EXCELLENT
  ('469f2f90-9449-5431-9c3e-5289364d1591', '8d27a19d-7a77-58e0-b3c6-862969a042f3', 'EXCELLENT',
   'Bonjour madame. Je souhaite suivre vos cours de français. Pouvez-vous me dire quels jours de la semaine ils ont lieu, à quelle heure ils commencent et combien de temps dure une séance ?',
   'Une troisième information s''ajoute naturellement, sans alourdir la demande.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S2 / INSUFFICIENT
  ('8be1edda-4540-5947-997a-2931e424b098', '73acf70c-a97d-5134-81b8-cffe7845e52d', 'INSUFFICIENT',
   'Bonjour monsieur. Ça coûte combien, le permis chez vous ?',
   'Le prix est demandé, mais la durée de la formation reste inconnue.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S2 / EXPECTED
  ('aacf2406-302a-5274-b56c-cc6170595d8b', '73acf70c-a97d-5134-81b8-cffe7845e52d', 'EXPECTED',
   'Bonjour monsieur. Je voudrais passer le permis. Combien coûte le forfait, et combien de temps dure la formation en général ?',
   'Prix et durée sont réclamés : vous pourrez organiser votre budget et votre agenda.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S2 / EXCELLENT
  ('a6ea757a-8d34-5550-99ba-bbf5e0127a89', '73acf70c-a97d-5134-81b8-cffe7845e52d', 'EXCELLENT',
   'Bonjour monsieur. Je voudrais passer le permis B. Quel est le prix du forfait complet, et en combien de mois vos élèves l''obtiennent-ils en moyenne ?',
   '« Forfait complet » et « en moyenne » ferment la porte aux réponses approximatives.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S3 / INSUFFICIENT
  ('d647d812-7f15-54ec-9885-a2d0b875129b', '09101337-d168-5262-a84b-f81fcb233b18', 'INSUFFICIENT',
   'Bonjour monsieur. Je voudrais savoir combien coûtent les cours de guitare et à quelle heure ils ont lieu.',
   'Deux informations sur trois : le lieu du cours manque encore.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S3 / EXPECTED
  ('f0914004-5ea0-5670-a97e-228009ea11d0', '09101337-d168-5262-a84b-f81fcb233b18', 'EXPECTED',
   'Bonjour monsieur. Je m''intéresse aux cours de guitare pour adultes. Combien coûtent-ils, à quelle heure ont-ils lieu, et où se déroulent-ils exactement ?',
   'Les trois questions sont posées et faciles à suivre pour l''animateur.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S3 / EXCELLENT
  ('a5cd0fed-c861-5ee8-87e1-ca15116ea4ac', '09101337-d168-5262-a84b-f81fcb233b18', 'EXCELLENT',
   'Bonjour monsieur. Je voudrais m''inscrire au cours de guitare pour adultes débutants. Quel est le tarif à l''année, quel jour et à quelle heure a lieu la séance, et à quelle adresse dois-je me rendre ?',
   'Chaque question est resserrée : les réponses seront directement utilisables.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S4 / INSUFFICIENT
  ('15af3e14-5681-5beb-8306-0ebbcc054b68', '5de1234a-9d3c-56ab-81e9-7837ed274852', 'INSUFFICIENT',
   'Bonjour madame. Je cherche un séjour à Marseille au printemps, est-ce que vous avez quelque chose ?',
   'Aucune des trois informations n''est réclamée : la conseillère devra tout deviner.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S4 / EXPECTED
  ('c6674bb9-e661-566f-8558-2ac94aa31fb2', '5de1234a-9d3c-56ab-81e9-7837ed274852', 'EXPECTED',
   'Bonjour madame. Je cherche un séjour à Marseille. Quelles sont les dates de départ possibles, combien de jours dure le séjour, et quel est le prix par personne ?',
   'Les trois questions sont nettes et posées dans un ordre logique.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S4 / EXCELLENT
  ('3e4ca3e7-7903-5876-b00e-8b451f2a8008', '5de1234a-9d3c-56ab-81e9-7837ed274852', 'EXCELLENT',
   'Bonjour madame. Je voudrais partir à Marseille pendant les vacances de printemps, avec mon mari. Quelles dates de départ vous reste-t-il en avril, combien de nuits comprend la formule, et quel est le prix par personne ?',
   'Le mois et le nombre de voyageurs rendent chaque réponse immédiatement exploitable.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S5 / INSUFFICIENT
  ('5de40467-ec47-5a8f-9b5e-914b1af7b119', 'b3a8cd58-bce6-5b54-a3b9-40d05d9ca116', 'INSUFFICIENT',
   'Bonjour monsieur. Je voudrais savoir quand le centre est ouvert cet été et combien cela coûte.',
   'Deux informations sur quatre : les horaires et l''adresse manquent encore.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S5 / EXPECTED
  ('5febec14-3cc6-5adf-9a74-7212ae60fbb8', 'b3a8cd58-bce6-5b54-a3b9-40d05d9ca116', 'EXPECTED',
   'Bonjour monsieur. Ma fille voudrait venir cet été. À quelles dates le centre est-il ouvert, à quelle heure accueillez-vous les enfants, combien coûte la journée, et quelle est votre adresse ?',
   'Les quatre questions sont posées clairement, sans que l''échange devienne confus.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C3-S5 / EXCELLENT
  ('d9628a38-09d2-5b2d-93ce-be4d99629461', 'b3a8cd58-bce6-5b54-a3b9-40d05d9ca116', 'EXCELLENT',
   'Bonjour monsieur. Ma fille a huit ans et je voudrais l''inscrire pour le mois de juillet. Entre quelles dates le centre fonctionne-t-il, à partir de quelle heure accueillez-vous les enfants le matin et jusqu''à quelle heure le soir, quel est le tarif d''une journée avec le repas, et à quelle adresse dois-je la déposer ?',
   'Le repas et l''heure du soir sont précisés : plus rien ne restera à rappeler.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S1 / INSUFFICIENT
  ('b96a1852-b132-55ae-8163-ed82e5db82f1', 'edfacf14-5cd7-5459-963b-737c938855d3', 'INSUFFICIENT',
   'Bonjour madame. Je voudrais inscrire mon fils à la cantine, s''il vous plaît.',
   'L''intention est claire, mais rien n''est demandé sur les documents exigés.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S1 / EXPECTED
  ('2da5f1a5-3e9b-5c11-a4db-5b73faf143fe', 'edfacf14-5cd7-5459-963b-737c938855d3', 'EXPECTED',
   'Bonjour madame. Je voudrais inscrire mon fils à la cantine. Quels documents dois-je apporter pour l''inscription ?',
   'La question sur les pièces à fournir évite un second déplacement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S1 / EXCELLENT
  ('31d64e43-8690-542e-a966-909da869681e', 'edfacf14-5cd7-5459-963b-737c938855d3', 'EXCELLENT',
   'Bonjour madame. Je voudrais inscrire mon fils à la cantine pour la rentrée. Quels documents devez-vous recevoir, et faut-il fournir un justificatif de revenus pour calculer le tarif ?',
   'Le tarif selon les revenus est anticipé : la démarche sera complète du premier coup.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S2 / INSUFFICIENT
  ('2a8437db-03f8-5aed-bcb9-2e2a4c11d6fc', '35cd48ce-7d0b-5ffd-ac27-8967c1c99f94', 'INSUFFICIENT',
   'Bonjour monsieur. Vous le livrez quand, ce lave-linge ?',
   'Vous obtiendrez une date, mais rien sur ce qui est inclus ni sur la garantie.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S2 / EXPECTED
  ('54a3566c-bd65-56f2-a35c-1a11c2da48bc', '35cd48ce-7d0b-5ffd-ac27-8967c1c99f94', 'EXPECTED',
   'Est-ce que la livraison est comprise dans le prix, et combien de temps dure la garantie ?',
   'Les deux conditions essentielles sont posées avant l''achat, au bon moment.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S2 / EXCELLENT
  ('f4eecfc7-488a-52b7-b493-2e6a5d6b783c', '35cd48ce-7d0b-5ffd-ac27-8967c1c99f94', 'EXCELLENT',
   'Est-ce que la livraison et l''installation sont comprises dans le prix, ou payantes en plus ? Et la garantie couvre-t-elle aussi le déplacement d''un technicien à mon domicile ?',
   'L''installation et le déplacement sont les vrais coûts cachés : bien vu.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S3 / INSUFFICIENT
  ('10bf8527-be21-50b9-bdf9-174cd99f4451', 'ff11b141-eb2f-54a0-b725-f2489f1b9f23', 'INSUFFICIENT',
   'Bonjour monsieur. Je voudrais ouvrir un compte chez vous. Quels papiers faut-il apporter ?',
   'Les documents sont demandés ; les frais du compte restent une inconnue.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S3 / EXPECTED
  ('cf24e963-2319-59f7-bf2b-64876c20c6ae', 'ff11b141-eb2f-54a0-b725-f2489f1b9f23', 'EXPECTED',
   'Bonjour monsieur. Je souhaite ouvrir un compte. Quels documents dois-je fournir, et est-ce qu''il y a des frais chaque mois ?',
   'Pièces et frais sont demandés ensemble : vous saurez à quoi vous engager.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S3 / EXCELLENT
  ('c1e7d9f4-cc59-569c-9b3b-278d86553c0c', 'ff11b141-eb2f-54a0-b725-f2489f1b9f23', 'EXCELLENT',
   'Bonjour monsieur. Je souhaite ouvrir un compte courant avec une carte bancaire. Quels justificatifs devez-vous recevoir, faut-il déposer un montant minimum au départ, et quels sont les frais mensuels ?',
   'Le dépôt minimum est souvent oublié et peut bloquer l''ouverture.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S4 / INSUFFICIENT
  ('1b8521c1-5c74-5c51-958f-c32edba6a9e8', '89dad550-8af1-5e26-95bc-79e43410bc9c', 'INSUFFICIENT',
   'Merci monsieur. Est-ce que je peux visiter l''appartement cette semaine ?',
   'La visite est demandée, mais aucune condition du dossier n''est abordée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S4 / EXPECTED
  ('3db57d81-d0b2-520e-9942-f76764dc8bbf', '89dad550-8af1-5e26-95bc-79e43410bc9c', 'EXPECTED',
   'Avant de visiter, je voudrais savoir quels documents composent le dossier, et s''il faut obligatoirement un garant.',
   'Documents et garant sont les deux conditions décisives : elles sont posées.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S4 / EXCELLENT
  ('b7852abe-dbeb-5248-81bb-24342ad3c2b7', '89dad550-8af1-5e26-95bc-79e43410bc9c', 'EXCELLENT',
   'Avant la visite, j''aimerais connaître les conditions : quelles pièces composent le dossier, quel niveau de revenus demandez-vous, et un garant est-il obligatoire si je suis en contrat à durée indéterminée ?',
   'Le contrat de travail est mentionné : la réponse portera sur votre cas réel.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S5 / INSUFFICIENT
  ('e5110531-1de0-53f9-ade0-a9cb222e0430', '2b318794-27ea-5628-b8aa-28b5f756244b', 'INSUFFICIENT',
   'Bonjour madame. Cette formation m''intéresse beaucoup. Est-ce que je peux la faire ?',
   'La question ouvre le sujet sans interroger le financement ni les obligations.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S5 / EXPECTED
  ('6d8ba5fd-96bb-57c0-92f6-bfb43448d40b', '2b318794-27ea-5628-b8aa-28b5f756244b', 'EXPECTED',
   'Bonjour madame. Cette formation m''intéresse. Quelles sont les conditions pour y entrer, qui la finance, et qu''est-ce qu''on attend de moi pendant les cours ?',
   'Les trois volets sont demandés : accès, financement et engagement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C4-S5 / EXCELLENT
  ('9a129b31-87a3-57f6-9e51-09f674718d28', '2b318794-27ea-5628-b8aa-28b5f756244b', 'EXCELLENT',
   'Bonjour madame. La formation de magasinier m''intéresse. Faut-il un niveau ou une expérience particulière pour y accéder ? Est-elle entièrement financée, ou une part reste-t-elle à ma charge ? Et dois-je être présent tous les jours pour conserver mon allocation ?',
   'Le lien entre présence et allocation montre une vraie lecture de la situation.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S1 / INSUFFICIENT
  ('da81ab48-cadd-5a51-addd-45505f41625f', 'de8ae451-dfed-5823-98b6-f13d48fe4d8f', 'INSUFFICIENT',
   'D''accord, très bien. Merci beaucoup monsieur, je vais réfléchir.',
   'L''information est acceptée telle quelle : le vrai coût du loyer reste inconnu.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S1 / EXPECTED
  ('eee98fd9-5ec8-51fa-83cc-930cdaf0b19d', 'de8ae451-dfed-5823-98b6-f13d48fe4d8f', 'EXPECTED',
   'D''accord. Est-ce que les charges sont comprises dans les 620 euros ?',
   'La question part du chiffre annoncé : c''est exactement ce qu''on attend.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S1 / EXCELLENT
  ('97ce3f96-b189-5299-aac4-5e334935a87f', 'de8ae451-dfed-5823-98b6-f13d48fe4d8f', 'EXCELLENT',
   'D''accord, le 15 mars me conviendrait très bien. Est-ce que les 620 euros comprennent les charges, ou faut-il ajouter l''eau et le chauffage ?',
   'La date est reprise et la question nomme les charges concernées : très efficace.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S2 / INSUFFICIENT
  ('33510d0e-b7f6-54a8-9b3e-6765717b72c5', '10a608d2-4d4d-5174-a9d8-6d0df4a8c613', 'INSUFFICIENT',
   'Le mardi à dix-neuf heures, d''accord. Et est-ce que vous proposez d''autres activités dans l''association ?',
   'La question change de sujet au lieu d''approfondir le cours annoncé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S2 / EXPECTED
  ('e7c8cbd1-99d8-5c53-847a-ae3360cd74b6', '10a608d2-4d4d-5174-a9d8-6d0df4a8c613', 'EXPECTED',
   'Le mardi à dix-neuf heures, d''accord. Et combien de temps dure la séance ?',
   'La question prolonge l''information reçue : l''échange avance vraiment.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S2 / EXCELLENT
  ('197123bb-57a3-5afe-acf3-d6574bfe2da2', '10a608d2-4d4d-5174-a9d8-6d0df4a8c613', 'EXCELLENT',
   'Le mardi à dix-neuf heures, cela m''arrange. Est-ce que la séance dure une heure, et faut-il réserver sa place à l''avance ?',
   'Deux suites logiques de l''horaire : la durée et la réservation.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S3 / INSUFFICIENT
  ('df879e7c-dfe4-524c-9945-8fd55a86fa2c', '99719e32-a7fa-552e-bcd5-fc00ba56d52f', 'INSUFFICIENT',
   'Oui, c''est parfait, je prends ce créneau. Merci madame, au revoir.',
   'Le rendez-vous est pris, mais aucune information pratique n''est vérifiée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S3 / EXPECTED
  ('edd6f143-41a2-5bf6-a728-6f1460704842', '99719e32-a7fa-552e-bcd5-fc00ba56d52f', 'EXPECTED',
   'Jeudi à seize heures trente, cela me convient. Est-ce que je dois apporter quelque chose de particulier ?',
   'Le créneau est confirmé et la question prépare concrètement la visite.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S3 / EXCELLENT
  ('22e12ebf-24f8-523a-844c-3d88612959d3', '99719e32-a7fa-552e-bcd5-fc00ba56d52f', 'EXCELLENT',
   'Jeudi à seize heures trente, c''est parfait pour moi. Faut-il que j''apporte ma carte Vitale et mes anciennes ordonnances, et à quelle adresse se trouve le cabinet ?',
   'Documents et adresse : deux suites naturelles d''une prise de rendez-vous.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S4 / INSUFFICIENT
  ('dc3c8d40-6873-547b-8e8f-c11d34080ff7', 'ab4a0dfb-108a-54aa-9712-11b464656368', 'INSUFFICIENT',
   'Six mois, trois jours par semaine. C''est bien, je vais y réfléchir et je vous rappelle.',
   'L''information est répétée sans être exploitée : l''échange s''arrête là.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S4 / EXPECTED
  ('a17c04fc-23a5-564d-9529-e4ab35f9aa9f', 'ab4a0dfb-108a-54aa-9712-11b464656368', 'EXPECTED',
   'Six mois, d''accord. Quels sont les trois jours de la semaine concernés ?',
   'La question découle directement de la réponse et vous est vraiment utile.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S4 / EXCELLENT
  ('1b5f6607-61a5-5d5a-b609-23c4b98dd747', 'ab4a0dfb-108a-54aa-9712-11b464656368', 'EXCELLENT',
   'Six mois à trois jours par semaine, cela me paraît possible. Quels jours exactement, et est-ce qu''un stage en entreprise est prévu pendant ces six mois ?',
   'Le stage est une suite logique : la question anticipe l''organisation réelle.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S5 / INSUFFICIENT
  ('b4066199-5908-57b5-b3f0-7933bd73e96f', '734532e5-ca28-5a19-bbd5-abd42fec5055', 'INSUFFICIENT',
   'Vingt-quatre euros quatre-vingt-dix-neuf, d''accord. Et est-ce que la télévision est incluse ?',
   'Une seule question, et le prix après les douze mois reste inconnu.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S5 / EXPECTED
  ('4ad2844a-6c14-512f-977e-49f3696ccdfa', '734532e5-ca28-5a19-bbd5-abd42fec5055', 'EXPECTED',
   'Vingt-cinq euros par mois, d''accord. Est-ce que le prix augmente après les douze mois ? Et faut-il payer des frais d''installation ?',
   'Les deux questions visent bien le coût réel, promotion et frais compris.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C5-S5 / EXCELLENT
  ('4798dbd8-ff97-52e7-86bd-11be6739983b', '734532e5-ca28-5a19-bbd5-abd42fec5055', 'EXCELLENT',
   'Vingt-quatre euros quatre-vingt-dix-neuf pendant un an, très bien. À quel tarif passe le forfait à partir du treizième mois, et dois-je payer des frais d''installation ou la location de la box en plus ?',
   'Le treizième mois et la location de la box : les deux pièges sont couverts.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S1 / INSUFFICIENT
  ('9ab46e18-451b-5ea2-864c-bbb263c63efb', 'f78e0290-a805-50ac-ab01-1207b285f22a', 'INSUFFICIENT',
   'Oui, d''accord, très bien madame. Merci beaucoup.',
   'L''information est perdue : rien ne dit à l''agente que vous n''avez pas entendu.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S1 / EXPECTED
  ('4e6a2f9f-74c6-5583-a3d7-48a185f3b0c6', 'f78e0290-a805-50ac-ab01-1207b285f22a', 'EXPECTED',
   'Excusez-moi madame, je n''ai pas bien entendu. Est-ce que vous pouvez répéter l''heure, s''il vous plaît ?',
   'L''incompréhension est signalée poliment et la demande est précise.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S1 / EXCELLENT
  ('650ce065-be99-5c02-b720-d5628b1a0afe', 'f78e0290-a805-50ac-ab01-1207b285f22a', 'EXCELLENT',
   'Excusez-moi madame, la ligne coupe un peu et je n''ai pas saisi l''heure. Pouvez-vous me répéter jusqu''à quelle heure le guichet reste ouvert ?',
   'La cause est expliquée et la question redit exactement ce qui manque.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S2 / INSUFFICIENT
  ('16c37e61-fd82-542d-b8fb-9c5e8c0c85f7', '61c3be19-0b1a-5bf4-a771-f00441723801', 'INSUFFICIENT',
   'En fin de semaine, d''accord. Merci beaucoup monsieur, bonne journée.',
   '« Fin de semaine » reste vague : vous ne savez pas quel jour attendre.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S2 / EXPECTED
  ('ca5a8ea2-c0e2-502c-9519-bd73bc4a1907', '61c3be19-0b1a-5bf4-a771-f00441723801', 'EXPECTED',
   'En fin de semaine, c''est-à-dire quel jour exactement, monsieur ?',
   'La formule vague est reprise et la précision demandée directement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S2 / EXCELLENT
  ('bc25c906-da74-5cb0-9737-996a6c1ef8fc', '61c3be19-0b1a-5bf4-a771-f00441723801', 'EXCELLENT',
   'En fin de semaine, d''accord. Est-ce que cela veut dire vendredi ou plutôt samedi ? Je dois être chez moi pour le recevoir.',
   'Deux possibilités proposées et une raison donnée : la réponse sera précise.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S3 / INSUFFICIENT
  ('3cf1f762-56f0-5853-9834-9fb38716e948', 'f4c947d0-0763-56c4-8b4d-061de8a23d0c', 'INSUFFICIENT',
   'Trois cents euros ? C''est cher quand même, je ne m''attendais pas à ça.',
   'La réaction exprime un avis mais ne demande aucune précision utile.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S3 / EXPECTED
  ('60d2f394-e08c-53c2-a43d-4ff983a76297', 'f4c947d0-0763-56c4-8b4d-061de8a23d0c', 'EXPECTED',
   'Trois cents euros, d''accord. Est-ce que ce prix comprend les pièces et la main-d''œuvre ?',
   'La question porte sur le contenu du montant : c''est le point décisif.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S3 / EXCELLENT
  ('eac5d043-6c80-518e-b3ef-bdfd0398a142', 'f4c947d0-0763-56c4-8b4d-061de8a23d0c', 'EXCELLENT',
   'Vous dites « dans les trois cents euros » : est-ce que ce montant comprend les pièces et la main-d''œuvre, et pouvez-vous me faire un devis écrit avant de commencer ?',
   'L''expression floue est citée et le devis écrit lève toute ambiguïté.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S4 / INSUFFICIENT
  ('a466738a-3b90-51ec-9b2d-2728f094ab90', 'b25cf5d2-f696-5757-833f-9bc163b58b66', 'INSUFFICIENT',
   'Un justificatif de domicile, d''accord. Je vais l''apporter la prochaine fois.',
   'Deux zones d''ombre subsistent : quel document, et daté de quand ?', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S4 / EXPECTED
  ('7665719d-5245-5bf3-822b-c6ff94ddf744', 'b25cf5d2-f696-5757-833f-9bc163b58b66', 'EXPECTED',
   'Un justificatif de domicile, d''accord. Quels documents acceptez-vous, et « récent », cela veut dire de moins de combien de temps ?',
   'Les deux points flous sont repris : vous éviterez un dossier refusé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S4 / EXCELLENT
  ('1a89ad61-d7bc-5516-8f12-bdc8f93b2ff3', 'b25cf5d2-f696-5757-833f-9bc163b58b66', 'EXCELLENT',
   'Un justificatif récent, d''accord. Est-ce qu''une facture d''électricité convient, ou faut-il une quittance de loyer ? Et « récent », c''est moins de trois mois ou moins de six mois ?',
   'Des exemples concrets sont proposés : l''agent n''a plus qu''à confirmer.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S5 / INSUFFICIENT
  ('45cea972-ff82-524e-854a-3af29f4f5a7e', '2fe51b50-d3a9-5b55-bc60-4a1cdc1b0ca7', 'INSUFFICIENT',
   'D''accord, donc je suis bien assuré en cas de dégât des eaux. Merci pour l''explication, madame.',
   'L''assurance est reprise, mais la franchise n''est ni reformulée ni vérifiée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S5 / EXPECTED
  ('37914ab9-4ddb-5974-8d8b-8121414a482b', '2fe51b50-d3a9-5b55-bc60-4a1cdc1b0ca7', 'EXPECTED',
   'Si je comprends bien, en cas de dégât des eaux je paie cent cinquante euros et vous payez le reste. C''est bien cela ?',
   'La reformulation est simple et la confirmation demandée clairement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C6-S5 / EXCELLENT
  ('066e854a-3729-5b74-bfb9-265b05f50b23', '2fe51b50-d3a9-5b55-bc60-4a1cdc1b0ca7', 'EXCELLENT',
   'Je vous répète pour être sûr : s''il y a une fuite chez moi, je paie les cent cinquante premiers euros et l''assurance prend en charge la suite, quel que soit le montant des dégâts. Est-ce que c''est exact ?',
   'L''exemple concret et la limite testée montrent une compréhension vraiment vérifiée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S1 / INSUFFICIENT
  ('10a89a14-4ba7-5244-a2f8-f65a7827d60b', '0c63a91f-1f3d-590e-abce-f2673fd6ee05', 'INSUFFICIENT',
   'Je vais prendre l''abonnement à l''année, s''il vous plaît.',
   'Le choix est posé sans aucune comparaison ni raison exprimée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S1 / EXPECTED
  ('eb89edb2-524e-5f25-ba41-a337707085d8', '0c63a91f-1f3d-590e-abce-f2673fd6ee05', 'EXPECTED',
   'Le mensuel est plus cher mais je reste libre, et l''annuel est moins cher avec un engagement. Je préfère le mensuel, parce que je ne sais pas si je resterai dans cette ville toute l''année.',
   'Les deux formules sont mises en regard et le choix est expliqué.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S1 / EXCELLENT
  ('de884499-21ec-55c2-b163-786e7d17af5d', '0c63a91f-1f3d-590e-abce-f2673fd6ee05', 'EXCELLENT',
   'Si je calcule bien, l''année revient à trois cent quarante-huit euros et le mensuel à quatre cent soixante-huit. Est-ce qu''on peut arrêter l''abonnement annuel en cas de déménagement ? Si c''est possible, je prends l''annuel, car je viens ici trois fois par semaine.',
   'Le calcul et la question rendent le choix solide et vraiment argumenté.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S2 / INSUFFICIENT
  ('ddf92723-a8ff-5e87-a553-ea2b6dd800eb', 'fd1f41fe-da53-56bb-90ac-8ee28f4487c5', 'INSUFFICIENT',
   'D''accord, je vais prendre le deuxième forfait, celui à dix-neuf euros.',
   'Le forfait est choisi sans que les deux offres soient comparées.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S2 / EXPECTED
  ('95531bd2-6ccc-57ca-a082-f2675e7fba02', 'fd1f41fe-da53-56bb-90ac-8ee28f4487c5', 'EXPECTED',
   'Le premier est moins cher, mais le second offre plus de données et les appels vers l''étranger. Comme j''appelle souvent ma famille, je choisis le second.',
   'La différence est nommée et le besoin personnel justifie le choix.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S2 / EXCELLENT
  ('1b77f706-97d4-53d3-a8b8-67078c4f4a60', 'fd1f41fe-da53-56bb-90ac-8ee28f4487c5', 'EXCELLENT',
   'Est-ce que les appels illimités du second forfait comprennent bien le Maroc ? Si oui, je le prends : vingt gigaoctets me suffiraient largement, mais vingt euros par mois me coûteront moins cher que mes cartes d''appel actuelles.',
   'La question conditionne le choix, et le calcul le rend convaincant.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S3 / INSUFFICIENT
  ('7c15fd32-c47f-5853-8694-3c2436357790', '74370a01-1767-59bb-9c99-d437b4722ec5', 'INSUFFICIENT',
   'Le train est plus rapide, donc je prends le train.',
   'Un seul aspect est comparé : le prix, pourtant très différent, n''est pas pesé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S3 / EXPECTED
  ('b2dc5748-1d14-5483-a0c3-12962188f7cc', '74370a01-1767-59bb-9c99-d437b4722ec5', 'EXPECTED',
   'Le train est deux fois plus rapide, mais il coûte trente euros de plus. Comme je pars le vendredi soir après le travail, je préfère le train pour arriver moins tard.',
   'Temps et prix sont comparés, et la contrainte personnelle explique le choix.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S3 / EXCELLENT
  ('369426d4-88e5-5548-9769-d515bf396f34', '74370a01-1767-59bb-9c99-d437b4722ec5', 'EXCELLENT',
   'Le train me fait gagner deux heures et demie pour trente euros de plus. Est-ce que le bus arrive au centre-ville ou en périphérie ? S''il arrive loin, je prends le train : le trajet supplémentaire annulerait l''économie.',
   'La question sur l''arrivée transforme la comparaison en véritable raisonnement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S4 / INSUFFICIENT
  ('e31ea051-2248-57ad-880c-1720885c266c', '2346c516-c085-523d-85b4-d485c28352f0', 'INSUFFICIENT',
   'Je préfère la formule du samedi, c''est mieux pour moi.',
   'Le choix est annoncé, mais rien ne le compare ni ne l''explique.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S4 / EXPECTED
  ('a31b7f4e-1783-5352-a139-215f8c48e051', '2346c516-c085-523d-85b4-d485c28352f0', 'EXPECTED',
   'La formule du soir est plus courte, quatre mois au lieu de huit, mais elle occupe trois soirées. Je termine tard le soir, donc je choisis le samedi.',
   'La durée et le rythme sont comparés, et votre emploi du temps justifie la décision.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S4 / EXCELLENT
  ('c0dd017d-0936-551e-aadc-d06d6416744f', '2346c516-c085-523d-85b4-d485c28352f0', 'EXCELLENT',
   'Est-ce que le contenu et le diplôme sont identiques dans les deux cas ? La formule du soir termine deux fois plus vite, mais je finis mon travail à dix-neuf heures et je n''arriverais jamais à l''heure. Je choisis donc le samedi, même si cela dure huit mois.',
   'La question sur le diplôme sécurise un choix par ailleurs bien expliqué.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S5 / INSUFFICIENT
  ('eca22ee0-899f-51ea-ab0c-f44f66a4f40e', '814d0d84-a34d-50e2-bff6-46987f36e6d7', 'INSUFFICIENT',
   'La formule de base est moins chère, alors je vais prendre celle-là.',
   'Seul le prix mensuel est retenu ; la franchise change pourtant beaucoup de choses.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S5 / EXPECTED
  ('fad5df11-d1cf-5d5e-a19d-790695ee0340', '814d0d84-a34d-50e2-bff6-46987f36e6d7', 'EXPECTED',
   'La formule de base coûte sept euros de moins par mois, mais la franchise est trois fois plus élevée. Est-ce que les deux couvrent le vol ? Comme j''ai peu d''objets de valeur, je pense choisir la formule de base.',
   'Prix et franchise sont comparés, et une question complète la décision.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C7-S5 / EXCELLENT
  ('06555cb6-8a97-534b-9895-137ab4162ec1', '814d0d84-a34d-50e2-bff6-46987f36e6d7', 'EXCELLENT',
   'Sur une année, la formule confort coûte quatre-vingt-quatre euros de plus, mais elle réduit la franchise de deux cents euros et remplace les appareils à neuf. Est-ce que le vol et le dégât des eaux sont couverts dans les deux cas ? Si oui, je prends la formule confort : mon lave-linge et mon ordinateur sont récents, et un seul sinistre rembourserait la différence.',
   'Le calcul annuel et la situation personnelle rendent le choix vraiment démontré.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S1 / INSUFFICIENT
  ('9d50d14b-1b8f-54a0-be33-fd8c7db11040', '945c7e12-76e3-5f5c-8a20-bce909e09a37', 'INSUFFICIENT',
   'Très bien, merci beaucoup madame. Au revoir et bonne journée.',
   'La politesse est là, mais rien n''est vérifié : une erreur passerait inaperçue.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S1 / EXPECTED
  ('81d32717-cff8-5f5e-9023-5b672236aaab', '945c7e12-76e3-5f5c-8a20-bce909e09a37', 'EXPECTED',
   'Donc mardi 10 mars à quatorze heures, avec le docteur Aubry. C''est noté. Merci madame, bonne journée.',
   'Date, heure et médecin sont confirmés, et l''échange se clôt proprement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S1 / EXCELLENT
  ('25d5e610-4f6e-5673-bc02-255c99939a86', '945c7e12-76e3-5f5c-8a20-bce909e09a37', 'EXCELLENT',
   'Je récapitule : mardi 10 mars, quatorze heures, docteur Aubry, deuxième étage. Je viendrai un peu en avance. Merci beaucoup pour votre aide, bonne journée madame.',
   'Tous les éléments sont repris et l''échange se termine de façon naturelle.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S2 / INSUFFICIENT
  ('0171cbb5-c6ff-5492-b0e3-3bc719534a92', '567b60b9-03d1-59cd-8cc0-3bfd072246f7', 'INSUFFICIENT',
   'D''accord, parfait. À vendredi alors, au revoir monsieur.',
   'Le rendez-vous est accepté, mais le prix n''est pas confirmé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S2 / EXPECTED
  ('05f64686-3d49-5a38-866a-7d6a9d788afa', '567b60b9-03d1-59cd-8cc0-3bfd072246f7', 'EXPECTED',
   'Donc vendredi à dix-sept heures, pour deux cent quarante euros. C''est d''accord. Merci monsieur, à vendredi.',
   'Heure et montant sont repris : les deux points importants sont sécurisés.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S2 / EXCELLENT
  ('f4b43d80-8089-59e3-906f-b318b6290617', '567b60b9-03d1-59cd-8cc0-3bfd072246f7', 'EXCELLENT',
   'Je résume : je récupère la voiture vendredi à dix-sept heures et je règle deux cent quarante euros, pièces comprises. Vous m''appelez si le montant change ? Merci beaucoup, bonne journée.',
   'Le récapitulatif se double d''une sécurité utile sur le prix final.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S3 / INSUFFICIENT
  ('e9c88f0c-749c-5b29-82a3-d6ca14e95508', 'c882e2e7-5134-5c94-9135-a923abe6c405', 'INSUFFICIENT',
   'Donc le dossier avant le 30 avril et la réponse en juin. Merci madame, au revoir.',
   'Le récapitulatif est juste ; il manque la dernière vérification demandée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S3 / EXPECTED
  ('da773331-93b9-51cd-9e85-cbb169dd5d67', 'c882e2e7-5134-5c94-9135-a923abe6c405', 'EXPECTED',
   'Donc je dépose le dossier avant le 30 avril et la réponse arrive par courrier en juin. Est-ce que je peux l''envoyer par la poste ? Merci beaucoup, bonne journée.',
   'Récapitulatif, vérification et congé : les trois moments sont bien présents.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S3 / EXCELLENT
  ('b37bbf3a-da4d-58a3-bd31-cc46cf81c4e9', 'c882e2e7-5134-5c94-9135-a923abe6c405', 'EXCELLENT',
   'Je récapitule : dossier complet avant le 30 avril, commission en juin, réponse par courrier. Une dernière chose : si une pièce manque, est-ce que vous me prévenez avant la commission ? Merci pour votre accueil, madame, bonne journée.',
   'La vérification porte sur le vrai risque du dossier : une pièce oubliée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S4 / INSUFFICIENT
  ('e4f18ce0-34e5-58e0-acfe-e917cfa23bdd', '7d8f4b6c-e2cf-5068-9044-3306fdca54ba', 'INSUFFICIENT',
   'C''est parfait, je prends. Est-ce que je peux payer par carte ? Merci, au revoir monsieur.',
   'La question est utile, mais les dates et le prix n''ont pas été confirmés.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S4 / EXPECTED
  ('b254bf06-9753-5141-bed1-9824e36abf4d', '7d8f4b6c-e2cf-5068-9044-3306fdca54ba', 'EXPECTED',
   'Donc je prends la voiture samedi 12 à neuf heures à l''agence de la gare, je la rends lundi avant midi, et cela fait quatre-vingt-seize euros. Est-ce que le carburant est compris ? Merci beaucoup, au revoir.',
   'Tout est confirmé, une question reste posée et l''échange se termine bien.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S4 / EXCELLENT
  ('3d3ae149-9de0-5135-b65c-956680038515', '7d8f4b6c-e2cf-5068-9044-3306fdca54ba', 'EXCELLENT',
   'Je récapitule : départ samedi 12 à neuf heures à l''agence de la gare, retour lundi 14 avant midi, quatre-vingt-seize euros au total. Dernière question : dois-je rendre le réservoir plein, et que se passe-t-il si j''ai une heure de retard ? Merci pour vos explications, bonne journée.',
   'La question anticipe le retard, la difficulté la plus fréquente en location.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S5 / INSUFFICIENT
  ('e019c684-73cd-55b0-b17e-283b7689e84d', '78a8129e-7e6b-5f1c-8001-4c071aac6aa9', 'INSUFFICIENT',
   'D''accord madame, c''est noté, je viendrai le 15 septembre. Merci beaucoup et bonne journée.',
   'Une seule information est reprise : l''adhésion et la photo sont oubliées.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S5 / EXPECTED
  ('df43bcef-b776-5ccb-b29d-16f9e6543556', '78a8129e-7e6b-5f1c-8001-4c071aac6aa9', 'EXPECTED',
   'Donc les ateliers ont lieu le jeudi de dix-huit à vingt heures, à partir du 15 septembre, en salle 3. Je paie vingt euros d''adhésion et j''apporte une photo. Est-ce que je peux payer le jour même ? Merci madame, bonne journée.',
   'L''essentiel est repris, un point est vérifié et le congé est naturel.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EO2-C8-S5 / EXCELLENT
  ('dc1871bb-058a-5115-ab5c-4f6b73b6c37d', '78a8129e-7e6b-5f1c-8001-4c071aac6aa9', 'EXCELLENT',
   'Je récapitule pour être sûr : atelier informatique le jeudi, de dix-huit à vingt heures, salle 3, à partir du 15 septembre ; vingt euros d''adhésion et une photo d''identité à fournir. Un point n''est pas clair pour moi : dois-je payer et apporter la photo dès la première séance, ou avant ? Merci beaucoup pour votre aide, à jeudi 15 septembre.',
   'Le récapitulatif est complet et la dernière question porte sur ce qui manquait vraiment.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');
