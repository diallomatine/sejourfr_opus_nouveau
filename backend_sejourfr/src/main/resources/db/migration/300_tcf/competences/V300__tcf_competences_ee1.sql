-- ============================================================================
-- V300 — Competences TCF : EE1 « Ecrire un message court »
--
-- Seed du module « Competences » pour la tache EE1 (EE).
-- 8 competences, 40 petits sujets, 120 references.
--
-- Tables : skills, skill_prompts, skill_references (DDL en V025).
--
-- FICHIER GENERE — NE PAS EDITER A LA MAIN.
--
--   cd backend_sejourfr && python3 tools/competences/generer_seed.py
--
-- On edite la fiche de contenu tools/competences/contenu/EE1.json,
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
  -- EE1-C1 — Adapter le message au destinataire
  ('80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1', 'EE1-C1', 'Adapter le message au destinataire',
   'On n''écrit pas de la même façon à un ami, à un voisin, à un employeur ou à une administration. Cette compétence entraîne le choix du ton, du tutoiement ou du vouvoiement et des formules de politesse, que le TCF observe dès la première ligne.',
   'Savoir choisir une formule, un ton et un niveau de politesse adaptés : ami, voisin, collègue, administration, responsable.',
   'A2', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2 — Annoncer clairement l'objet du message
  ('b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1', 'EE1-C2', 'Annoncer clairement l''objet du message',
   'Le lecteur doit comprendre dès la première phrase pourquoi vous écrivez. Cette compétence entraîne l''annonce nette de l''objet : informer, prévenir, annuler, remercier, demander ou répondre.',
   'Faire comprendre immédiatement pourquoi on écrit : informer, prévenir, annuler, remercier, demander ou répondre.',
   'A2', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3 — Donner des informations pratiques précises
  ('d711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1', 'EE1-C3', 'Donner des informations pratiques précises',
   'Un message utile contient des informations exactes : quand, où, avec qui, combien, comment. Cette compétence entraîne la précision des détails pratiques, très souvent attendue dans les sujets du TCF.',
   'Indiquer correctement une date, une heure, un lieu, une personne, une quantité ou une modalité.',
   'A2', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4 — Formuler une demande polie
  ('f1794c8d-332a-565e-b4f4-af7b162de403', 'EE', 'EE1', 'EE1-C4', 'Formuler une demande polie',
   'Demander sans donner l''impression d''exiger : c''est ce que le TCF attend d''un message adressé à un voisin, un employeur ou un service. Cette compétence entraîne la demande à la fois claire et polie.',
   'Demander une information, une aide, un document, une autorisation ou un service de manière claire.',
   'A2', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5 — Inviter, proposer, accepter ou refuser
  ('058c595e-cd1c-5798-be9a-416ef3eae23e', 'EE', 'EE1', 'EE1-C5', 'Inviter, proposer, accepter ou refuser',
   'Inviter, proposer, dire oui ou dire non : ce sont les messages les plus fréquents au TCF. Cette compétence entraîne des réponses nettes, qui ne laissent jamais le lecteur dans le doute.',
   'Formuler une invitation ou une proposition et répondre clairement à celle d''une autre personne.',
   'A2', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6 — S'excuser et expliquer une raison
  ('e9e1e162-8cd7-5cd2-a372-65aed419f8e4', 'EE', 'EE1', 'EE1-C6', 'S''excuser et expliquer une raison',
   'S''excuser sans se perdre en explications : le TCF attend une excuse claire suivie d''une raison compréhensible, en quelques mots seulement. Cette compétence entraîne ce couple excuse + cause.',
   'Présenter une excuse compréhensible et donner une cause suffisante sans écrire un récit trop long.',
   'A2', 6, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7 — Décrire simplement une personne, un lieu ou une situation
  ('b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1', 'EE1-C7', 'Décrire simplement une personne, un lieu ou une situation',
   'Décrire, c''est donner les quelques détails qui permettent à l''autre de se représenter une personne, un lieu ou une situation. Cette compétence entraîne la description courte, concrète et utile au lecteur.',
   'Donner quelques caractéristiques utiles et compréhensibles adaptées au contexte du message.',
   'A2', 7, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8 — Relier les informations dans un message complet
  ('f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1', 'EE1-C8', 'Relier les informations dans un message complet',
   'Un message complet ne tient pas en une phrase : il annonce, informe, puis se termine. Cette compétence entraîne l''enchaînement de plusieurs phrases simples et la clôture naturelle du message.',
   'Enchaîner plusieurs phrases simples et terminer le message naturellement.',
   'A2', 8, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');

INSERT INTO skill_prompts (id, skill_id, section, code, title, context, instruction,
                           unique_criterion, recommended_min_words, recommended_max_words,
                           recommended_duration_seconds, difficulty_level, display_order,
                           is_active, created_at, updated_at)
VALUES
  -- EE1-C1-S1 — EASY — Un mot pour votre voisine
  ('f77e873d-d588-5da3-9d13-f434a391edfd', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S1', 'Un mot pour votre voisine',
   'Vous partez trois jours et vos plantes ont besoin d''eau. Vous connaissez peu votre voisine du deuxième étage.',
   'Écrivez les deux premières phrases de votre message : saluez-la et dites qui vous êtes.',
   'Employer une salutation et un vouvoiement adaptés à une voisine que l''on connaît peu.',
   15, 35, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S2 — EASY — Proposer une sortie à une amie
  ('f47c9eef-b3a3-5e57-93da-93acd6c1527f', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S2', 'Proposer une sortie à une amie',
   'Votre amie Sofia vient de terminer ses examens. Vous voulez lui proposer d''aller au cinéma ce week-end.',
   'Écrivez-lui un court message pour lui proposer cette sortie.',
   'Employer un ton amical et le tutoiement du début à la fin du message.',
   15, 35, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S3 — MEDIUM — Signaler une fuite au propriétaire
  ('bf1f6d9f-1d3d-5f1f-98df-45849ce28243', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S3', 'Signaler une fuite au propriétaire',
   'Un tuyau fuit sous l''évier de votre cuisine. Vous écrivez à votre propriétaire, que vous n''avez rencontré qu''une seule fois.',
   'Écrivez le début de votre message : formule d''appel, présentation, puis annonce du problème.',
   'S''adresser au propriétaire avec une formule d''appel formelle et le vouvoiement.',
   25, 45, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S4 — MEDIUM — Écrire au service client
  ('49572fd8-a8be-5fa1-87ad-4a89472fd46c', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S4', 'Écrire au service client',
   'Votre connexion internet ne fonctionne plus depuis deux jours. Vous écrivez au service client de votre opérateur.',
   'Rédigez un court courriel qui commence et se termine par les formules adaptées à un service client.',
   'Encadrer le message par une formule d''appel et une formule de clôture formelles.',
   30, 55, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S5 — HARD — Un message à votre responsable
  ('8f2062e7-e3cd-5011-93cf-42bc57049ba7', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S5', 'Un message à votre responsable',
   'Vous travaillez dans un supermarché. Vous écrivez à votre responsable, Madame Fontaine, au sujet de votre planning de la semaine prochaine.',
   'Écrivez-lui un message complet sur ce sujet, du bonjour jusqu''à la signature.',
   'Garder un ton professionnel et le vouvoiement dans tout le message, salutation et clôture comprises.',
   40, 70, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S1 — EASY — Annuler un rendez-vous chez le dentiste
  ('b331ef2a-aa92-561b-9005-a073e8fc2e0e', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S1', 'Annuler un rendez-vous chez le dentiste',
   'Vous avez un rendez-vous chez le dentiste jeudi à 15 h. Vous ne pourrez pas y aller.',
   'Écrivez la première phrase du message que vous envoyez au cabinet dentaire.',
   'Annoncer l''annulation du rendez-vous dès la première phrase.',
   12, 30, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S2 — EASY — Remercier une voisine
  ('9d8bfc2f-4cc9-590a-9a20-13ad22514121', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S2', 'Remercier une voisine',
   'Votre voisine a gardé votre chat pendant vos deux semaines d''absence. Vous voulez lui écrire.',
   'Écrivez un court message dont la première phrase dit clairement pourquoi vous écrivez.',
   'Indiquer dès la première phrase qu''il s''agit d''un remerciement.',
   15, 35, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S3 — MEDIUM — Prévenir d'un changement de réunion
  ('8f82648f-4d21-5460-9f34-af882186ed2e', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S3', 'Prévenir d''un changement de réunion',
   'Vous travaillez dans une entreprise de nettoyage. La réunion d''équipe de mardi est déplacée à jeudi.',
   'Écrivez un message à vos collègues. La première phrase doit dire de quoi il s''agit.',
   'Annoncer dès la première phrase qu''il s''agit d''un changement de date de la réunion.',
   20, 40, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S4 — MEDIUM — Demande d'information au secrétariat
  ('e08248b9-c463-5612-940e-c8ced942c9a5', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S4', 'Demande d''information au secrétariat',
   'Vous voulez vous inscrire à une formation de français dans un centre de votre ville. Vous avez besoin de renseignements.',
   'Écrivez un courriel au secrétariat. Annoncez le but de votre message avant de donner les détails.',
   'Annoncer en une phrase qu''il s''agit d''une demande d''information, avant tout autre détail.',
   25, 45, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S5 — HARD — Réclamation après un trajet annulé
  ('0176ca90-0099-576d-b0c0-ee2083481f85', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S5', 'Réclamation après un trajet annulé',
   'Votre bus longue distance a été annulé sans que personne ne vous prévienne. Vous avez payé 42 euros et vous voulez être remboursé.',
   'Écrivez un message à la compagnie. Le but de votre message doit apparaître avant les explications.',
   'Annoncer la demande de remboursement avant de raconter ce qui s''est passé.',
   40, 70, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S1 — EASY — Inviter un ami à un anniversaire
  ('5de5d54b-bc7c-5c58-bc8c-1a9d517efbfd', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S1', 'Inviter un ami à un anniversaire',
   'Vous fêtez votre anniversaire samedi chez vous. Vous écrivez à votre ami Mehdi.',
   'Écrivez-lui un court message avec les informations dont il a besoin pour venir.',
   'Indiquer un lieu précis et une heure précise.',
   15, 35, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S2 — EASY — Se retrouver à la gare
  ('8de20dd2-564c-54fd-9181-7ff061656385', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S2', 'Se retrouver à la gare',
   'Vous arrivez en train à Bordeaux demain. Votre cousine vient vous chercher à la gare.',
   'Écrivez-lui un message avec les informations utiles pour vous retrouver.',
   'Indiquer l''heure d''arrivée et le point de rendez-vous exact.',
   15, 35, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S3 — MEDIUM — Expliquer comment venir chez vous
  ('0adb1223-c831-5a76-b42f-ca259ba7e053', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S3', 'Expliquer comment venir chez vous',
   'Une amie vient dîner chez vous pour la première fois. Votre immeuble a un code et vous habitez au quatrième étage.',
   'Écrivez-lui un message pour qu''elle trouve votre appartement sans avoir à vous appeler.',
   'Donner trois informations pratiques : l''adresse, le code d''entrée et l''étage.',
   25, 45, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S4 — MEDIUM — Confirmer un rendez-vous en préfecture
  ('1af08222-3aac-5fbf-9f04-3cbb26e8169b', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S4', 'Confirmer un rendez-vous en préfecture',
   'Vous accompagnez votre frère à la préfecture pour le renouvellement de son titre de séjour. Vous lui envoyez les informations.',
   'Écrivez-lui un message avec tout ce qu''il doit savoir pour ce rendez-vous.',
   'Indiquer la date, l''heure et les documents à apporter.',
   30, 55, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S5 — HARD — Organiser une livraison au magasin
  ('daa879e1-a4d5-595a-b173-749abd044abd', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S5', 'Organiser une livraison au magasin',
   'Vous travaillez dans un magasin. Une livraison importante arrive la semaine prochaine et vous devez prévenir toute l''équipe.',
   'Écrivez un message à vos collègues avec les informations nécessaires pour s''organiser.',
   'Donner quatre informations pratiques : le jour, l''heure, le lieu et la personne à contacter.',
   40, 70, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S1 — EASY — Demander un service à un voisin
  ('6c468df6-1298-5b27-998d-69a0233f83ba', 'f1794c8d-332a-565e-b4f4-af7b162de403', 'EE', 'EE1-C4-S1', 'Demander un service à un voisin',
   'Vous attendez un colis important mais vous travaillez toute la journée. Votre voisin est souvent chez lui.',
   'Écrivez-lui un court message pour lui demander de réceptionner ce colis.',
   'Formuler la demande avec une forme polie, par exemple « pourriez-vous » ou « s''il vous plaît ».',
   15, 35, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S2 — EASY — Demander le cours à sa formatrice
  ('0bb7f81f-dfe0-511d-92c4-513eb29b498c', 'f1794c8d-332a-565e-b4f4-af7b162de403', 'EE', 'EE1-C4-S2', 'Demander le cours à sa formatrice',
   'Vous suivez une formation de français. Vous avez manqué le cours de lundi et un document a été distribué.',
   'Écrivez un message à votre formatrice pour obtenir ce document.',
   'Exprimer la demande poliment, avec une formule de politesse ou un verbe au conditionnel.',
   15, 35, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S3 — MEDIUM — Modifier son horaire de travail
  ('ddb4f776-594a-5112-929d-9c5a1858399c', 'f1794c8d-332a-565e-b4f4-af7b162de403', 'EE', 'EE1-C4-S3', 'Modifier son horaire de travail',
   'Vous commencez à 8 h dans un restaurant. Pendant deux semaines, vous devez amener votre fils à l''école à 8 h 20.',
   'Écrivez à votre responsable pour demander un changement d''horaire.',
   'Formuler la demande poliment et laisser à la personne la possibilité de répondre non.',
   30, 55, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S4 — MEDIUM — Demander une attestation au cabinet médical
  ('09597d62-c18d-5456-a561-86e5f000855c', 'f1794c8d-332a-565e-b4f4-af7b162de403', 'EE', 'EE1-C4-S4', 'Demander une attestation au cabinet médical',
   'Votre employeur vous demande une attestation de votre médecin après votre consultation de la semaine dernière.',
   'Écrivez un message au secrétariat du cabinet pour obtenir ce document.',
   'Demander le document avec une formule de politesse et remercier à la fin du message.',
   25, 45, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S5 — HARD — Demander un rendez-vous à la mairie
  ('e78ab711-9d8c-5b7e-b85e-dbf29d0065f3', 'f1794c8d-332a-565e-b4f4-af7b162de403', 'EE', 'EE1-C4-S5', 'Demander un rendez-vous à la mairie',
   'Vous devez déposer un dossier de demande de logement social. Le site internet ne propose aucun créneau disponible.',
   'Écrivez un courriel à la mairie pour demander un rendez-vous.',
   'Exprimer la demande de façon polie et directe, sans exiger et sans s''excuser à l''excès.',
   40, 70, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S1 — EASY — Inviter un voisin à la fête
  ('27ff05d1-69e5-59c6-b591-7d1db292f135', '058c595e-cd1c-5798-be9a-416ef3eae23e', 'EE', 'EE1-C5-S1', 'Inviter un voisin à la fête',
   'Les habitants de votre immeuble organisent un repas dans la cour samedi soir. Vous voulez inviter votre nouveau voisin.',
   'Écrivez-lui un court message pour l''inviter.',
   'Formuler une invitation claire, en précisant le jour et l''activité.',
   15, 35, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S2 — EASY — Refuser une sortie
  ('a91b0de2-90df-5db4-8179-bc8fa6a32b83', '058c595e-cd1c-5798-be9a-416ef3eae23e', 'EE', 'EE1-C5-S2', 'Refuser une sortie',
   'Votre ami Thomas vous propose d''aller voir un match de football dimanche. Vous ne pouvez pas y aller.',
   'Répondez-lui par un court message.',
   'Refuser clairement, sans laisser croire que vous viendrez peut-être.',
   15, 35, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S3 — MEDIUM — Accepter la proposition d'un collègue
  ('28ce0e24-c333-5a08-8ce0-8477ba94e455', '058c595e-cd1c-5798-be9a-416ef3eae23e', 'EE', 'EE1-C5-S3', 'Accepter la proposition d''un collègue',
   'Votre collègue Awa vous propose d''échanger votre samedi de travail contre son mercredi.',
   'Répondez-lui par un message.',
   'Accepter explicitement et confirmer le jour de chacun.',
   20, 40, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S4 — MEDIUM — Proposer une révision à deux
  ('a848dfca-8cc2-5bc2-9c07-b1b0b479ec28', '058c595e-cd1c-5798-be9a-416ef3eae23e', 'EE', 'EE1-C5-S4', 'Proposer une révision à deux',
   'Vous préparez le TCF avec Ana, une camarade de votre cours. Vous voulez réviser avec elle avant l''examen.',
   'Écrivez-lui un message pour lui proposer une séance de révision.',
   'Faire une proposition claire en offrant deux moments possibles.',
   25, 45, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S5 — HARD — Refuser et proposer autre chose
  ('9cb2b1ea-c1d0-5931-8279-21731fbe2f1d', '058c595e-cd1c-5798-be9a-416ef3eae23e', 'EE', 'EE1-C5-S5', 'Refuser et proposer autre chose',
   'Votre voisine vous demande de garder ses deux enfants vendredi soir. Vous n''êtes pas disponible ce soir-là.',
   'Répondez-lui par un message.',
   'Refuser clairement et proposer une autre solution.',
   40, 70, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S1 — EASY — Prévenir d'un retard
  ('cf9626ad-6d23-5259-b05b-a07ef17ded91', 'e9e1e162-8cd7-5cd2-a372-65aed419f8e4', 'EE', 'EE1-C6-S1', 'Prévenir d''un retard',
   'Vous devez rejoindre votre amie Camille à 18 h au restaurant. Vous aurez une vingtaine de minutes de retard.',
   'Écrivez-lui un court message.',
   'Présenter une excuse et donner la raison du retard.',
   12, 30, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S2 — EASY — Un livre rendu en retard
  ('27c430ec-dfdb-53a0-8c9f-f8b1cf9a5e85', 'e9e1e162-8cd7-5cd2-a372-65aed419f8e4', 'EE', 'EE1-C6-S2', 'Un livre rendu en retard',
   'Vous deviez rapporter un livre à la médiathèque il y a une semaine. Vous l''avez oublié.',
   'Écrivez un message à la médiathèque.',
   'S''excuser du retard et en donner la raison.',
   15, 35, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S3 — MEDIUM — Expliquer une absence au travail
  ('711154a2-700a-580f-90fe-5b46c84780f3', 'e9e1e162-8cd7-5cd2-a372-65aed419f8e4', 'EE', 'EE1-C6-S3', 'Expliquer une absence au travail',
   'Vous n''êtes pas venu travailler hier et vous n''avez pas pu prévenir votre responsable à temps.',
   'Écrivez-lui un message aujourd''hui.',
   'Présenter une excuse et donner une raison précise de l''absence.',
   25, 45, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S4 — MEDIUM — S'excuser du bruit
  ('bc388229-26e1-5326-b28b-d8fb64df41d1', 'e9e1e162-8cd7-5cd2-a372-65aed419f8e4', 'EE', 'EE1-C6-S4', 'S''excuser du bruit',
   'Vous avez fait des travaux dans votre appartement samedi matin. Votre voisine du dessous a été dérangée.',
   'Écrivez-lui un mot que vous glisserez dans sa boîte aux lettres.',
   'S''excuser pour le bruit et en expliquer la cause, sans longue justification.',
   25, 45, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S5 — HARD — Justifier l'absence de son enfant
  ('78dfed5f-28da-5966-b472-58646aaad2df', 'e9e1e162-8cd7-5cd2-a372-65aed419f8e4', 'EE', 'EE1-C6-S5', 'Justifier l''absence de son enfant',
   'Votre fils n''est pas allé à l''école mardi ni mercredi. L''enseignante demande un mot des parents.',
   'Écrivez ce mot à l''enseignante.',
   'Présenter une excuse et expliquer clairement la raison de l''absence.',
   40, 70, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S1 — EASY — Décrire un studio à louer
  ('efdde157-a9fa-527c-b1d7-84a53de1628f', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S1', 'Décrire un studio à louer',
   'Vous quittez votre studio le mois prochain et un ami cherche un logement. Vous voulez lui en parler.',
   'Écrivez-lui un court message pour décrire ce studio.',
   'Donner au moins deux caractéristiques concrètes du logement.',
   15, 35, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S2 — EASY — Qui viendra chercher les clés
  ('8f59523c-6c4c-5f87-82cb-c3d2fdff892e', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S2', 'Qui viendra chercher les clés',
   'Vous ne pouvez pas être présent pour rendre les clés à l''agence immobilière. Votre belle-sœur viendra à votre place.',
   'Écrivez un message à l''agence pour qu''on la reconnaisse à son arrivée.',
   'Donner deux ou trois caractéristiques qui permettent de reconnaître la personne.',
   20, 40, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S3 — MEDIUM — Un sac oublié dans le bus
  ('c5d8740c-60c5-556a-b8df-74fabb731a82', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S3', 'Un sac oublié dans le bus',
   'Vous avez laissé votre sac dans le bus hier soir. Vous écrivez au service des objets trouvés.',
   'Écrivez un message décrivant le sac que vous avez perdu.',
   'Décrire le sac avec des caractéristiques précises : couleur, taille et contenu.',
   30, 55, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S4 — MEDIUM — Parler de votre quartier
  ('aa457d87-8856-53f0-966c-11b1c18e1452', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S4', 'Parler de votre quartier',
   'Un ami installé à l''étranger cherche un logement dans votre ville. Il vous demande si votre quartier lui conviendrait.',
   'Écrivez-lui un message pour lui décrire votre quartier.',
   'Donner trois caractéristiques utiles du quartier.',
   30, 55, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S5 — HARD — Décrire un vol à l'assurance
  ('d262dae9-8c8b-5dda-bc64-9519c551ba10', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S5', 'Décrire un vol à l''assurance',
   'Votre vélo a été volé devant la gare pendant que vous étiez au travail. Vous déclarez ce vol à votre assurance.',
   'Écrivez un message qui décrit ce qui s''est passé et le vélo volé.',
   'Décrire la situation et le vélo assez précisément pour être compris sans photo.',
   45, 70, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S1 — EASY — Changer le lieu d'un rendez-vous
  ('79506cab-4962-5f03-98ff-3d51d327d1cd', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S1', 'Changer le lieu d''un rendez-vous',
   'Vous deviez retrouver votre amie Lucie devant le musée samedi. Le musée est fermé ce jour-là.',
   'Écrivez-lui un message en trois phrases : annoncez le changement, donnez le nouveau lieu, puis terminez le message.',
   'Enchaîner trois phrases : l''annonce, la nouvelle information, puis une formule finale.',
   30, 60, NULL, 'EASY', 1, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S2 — EASY — Reporter une réunion d'équipe
  ('cced9b3d-a961-5bc7-80cc-f197bdd960e4', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S2', 'Reporter une réunion d''équipe',
   'La réunion d''équipe prévue jeudi ne peut pas avoir lieu. Elle est reportée au lundi suivant.',
   'Écrivez un message à votre collègue Sarah en trois phrases : le changement, la nouvelle date, une formule finale.',
   'Enchaîner l''annonce, la nouvelle date et une phrase de clôture polie.',
   30, 60, NULL, 'EASY', 2, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S3 — MEDIUM — Message complet au propriétaire
  ('0d0be427-d189-5dea-80ff-b80773cd895a', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S3', 'Message complet au propriétaire',
   'Le chauffage de votre appartement ne fonctionne plus depuis deux jours. Vous écrivez à votre propriétaire.',
   'Écrivez un message qui annonce le problème, donne une précision et se termine poliment.',
   'Relier les phrases avec au moins un mot de liaison et terminer par une formule de clôture.',
   35, 65, NULL, 'MEDIUM', 3, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S4 — MEDIUM — Reporter un rendez-vous administratif
  ('8b75e658-6277-5c8e-b395-1a12e87770e0', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S4', 'Reporter un rendez-vous administratif',
   'Vous avez un rendez-vous à la caisse d''allocations familiales lundi. Vous ne pourrez pas vous y rendre.',
   'Écrivez un courriel qui explique la situation et demande un autre rendez-vous.',
   'Enchaîner les informations dans un ordre logique et terminer par une formule de clôture.',
   40, 70, NULL, 'MEDIUM', 4, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S5 — HARD — Suspendre son inscription au club
  ('18952468-9342-5bef-9312-55315ef5b828', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S5', 'Suspendre son inscription au club',
   'Vous êtes inscrit dans un club de natation. Vous devez arrêter pendant trois mois pour raisons de santé.',
   'Écrivez au responsable du club : annoncez votre situation, expliquez, posez votre question et terminez le message.',
   'Enchaîner quatre informations dans un message suivi et le terminer par une formule adaptée.',
   45, 70, NULL, 'HARD', 5, true, '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');

INSERT INTO skill_references (id, skill_prompt_id, level, text, pedagogical_note,
                              created_at, updated_at)
VALUES
  -- EE1-C1-S1 / INSUFFICIENT
  ('a86c34ab-03ef-5855-aef1-66e8c9e333f4', 'f77e873d-d588-5da3-9d13-f434a391edfd', 'INSUFFICIENT',
   'Salut, c''est moi ton voisin du dessus. Tu peux arroser mes plantes cette semaine ?',
   'Le tutoiement et « salut » sont trop familiers pour une voisine peu connue.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S1 / EXPECTED
  ('969d7712-b3b1-5bb4-b683-b10dabca44d1', 'f77e873d-d588-5da3-9d13-f434a391edfd', 'EXPECTED',
   'Bonjour Madame, je suis votre voisin du troisième étage. Je pars trois jours et je voudrais vous demander un service.',
   'La salutation et le vouvoiement conviennent à une voisine que l''on connaît peu.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S1 / EXCELLENT
  ('cb57ebb1-efe2-5719-896f-98a4a55e6593', 'f77e873d-d588-5da3-9d13-f434a391edfd', 'EXCELLENT',
   'Bonjour Madame Léger, je suis Amadou, votre voisin du troisième étage. Je me permets de vous écrire car je pars trois jours.',
   'Le nom et « je me permets » rendent le ton juste et naturel.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S2 / INSUFFICIENT
  ('b95c6fa2-149e-5a5f-9629-a3591e6fc48f', 'f47c9eef-b3a3-5e57-93da-93acd6c1527f', 'INSUFFICIENT',
   'Madame, je vous informe que je souhaite vous proposer une sortie au cinéma samedi. Cordialement.',
   'Ce ton administratif ne convient pas à une amie proche.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S2 / EXPECTED
  ('ad6c9425-b4c2-5e91-a64a-675f627d8520', 'f47c9eef-b3a3-5e57-93da-93acd6c1527f', 'EXPECTED',
   'Salut Sofia ! Tes examens sont enfin finis, bravo. Ça te dit d''aller au cinéma samedi après-midi ?',
   'Le tutoiement et le ton détendu conviennent bien à une amie.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S2 / EXCELLENT
  ('2b84e9e5-a684-5520-ac75-90ca1dcd38df', 'f47c9eef-b3a3-5e57-93da-93acd6c1527f', 'EXCELLENT',
   'Coucou Sofia ! Bravo, tes examens sont derrière toi. On se fait un cinéma samedi après-midi pour fêter ça ? Dis-moi vite !',
   'Le ton reste amical et vivant, sans jamais quitter le tutoiement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S3 / INSUFFICIENT
  ('59fe7d62-648c-5346-b03f-727b0937655a', 'bf1f6d9f-1d3d-5f1f-98df-45849ce28243', 'INSUFFICIENT',
   'Salut, il y a de l''eau sous l''évier depuis hier. Tu peux venir voir quand ?',
   'Le tutoiement n''est pas adapté à un propriétaire : il faut vouvoyer.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S3 / EXPECTED
  ('36acfcb8-26fe-51af-8215-31a80e066dda', 'bf1f6d9f-1d3d-5f1f-98df-45849ce28243', 'EXPECTED',
   'Bonjour Monsieur, je suis votre locataire de l''appartement 12. Je vous écris car un tuyau fuit sous l''évier de la cuisine.',
   'La formule d''appel et le vouvoiement sont corrects et suffisent ici.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S3 / EXCELLENT
  ('bf116fb8-dbaf-5bcf-9322-62bbb94e51ca', 'bf1f6d9f-1d3d-5f1f-98df-45849ce28243', 'EXCELLENT',
   'Bonjour Monsieur Renaud, je suis Leïla Benali, votre locataire du 12 rue des Lilas. Je me permets de vous signaler une fuite sous l''évier de la cuisine.',
   'L''identification complète et « je me permets » donnent un ton formel juste.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S4 / INSUFFICIENT
  ('bfbb2dd6-1a1f-531b-9d34-29bac3796985', '49572fd8-a8be-5fa1-87ad-4a89472fd46c', 'INSUFFICIENT',
   'Bonjour, ma connexion ne marche plus depuis deux jours. Merci de régler ça rapidement.',
   'Il manque une formule d''appel formelle et une formule de clôture.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S4 / EXPECTED
  ('df0a68c1-2177-57fe-951e-666d24415da4', '49572fd8-a8be-5fa1-87ad-4a89472fd46c', 'EXPECTED',
   'Madame, Monsieur, ma connexion internet ne fonctionne plus depuis deux jours. Pouvez-vous m''indiquer la marche à suivre ? Cordialement, Rachid Mansour.',
   'Le message est bien encadré par deux formules adaptées à un service client.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S4 / EXCELLENT
  ('011be9a8-1d56-5ef5-9a5a-85fa56388ea7', '49572fd8-a8be-5fa1-87ad-4a89472fd46c', 'EXCELLENT',
   'Madame, Monsieur, je suis client chez vous depuis 2023 et ma connexion internet est interrompue depuis deux jours. Je vous remercie de bien vouloir intervenir. Cordialement, Rachid Mansour.',
   'Ouverture, remerciement et signature forment un ensemble cohérent et formel.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S5 / INSUFFICIENT
  ('41ffe56b-7e81-57d3-b33a-5a1501f00b67', '8f2062e7-e3cd-5011-93cf-42bc57049ba7', 'INSUFFICIENT',
   'Bonjour Madame Fontaine, je voulais savoir pour le planning de la semaine prochaine. J''aimerais changer mon mardi soir. Bisous, à demain !',
   'Le début convient, mais la clôture familière casse le ton professionnel.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S5 / EXPECTED
  ('3abfcb05-e1be-58bf-abc5-58587e187651', '8f2062e7-e3cd-5011-93cf-42bc57049ba7', 'EXPECTED',
   'Bonjour Madame Fontaine, je vous écris au sujet du planning de la semaine prochaine. Je suis inscrit mardi soir, mais je dois accompagner ma fille à un rendez-vous médical. Est-ce que je peux travailler mardi matin à la place ? Merci de votre réponse. Cordialement, Ivan Petrov.',
   'Le vouvoiement et le ton restent professionnels du début à la fin.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C1-S5 / EXCELLENT
  ('07c80538-4da6-551f-a719-5ed1331913ab', '8f2062e7-e3cd-5011-93cf-42bc57049ba7', 'EXCELLENT',
   'Bonjour Madame Fontaine, j''espère que vous allez bien. Je me permets de vous écrire au sujet du planning de la semaine prochaine : je suis inscrit mardi soir, mais je dois accompagner ma fille chez le médecin. Serait-il possible de travailler mardi matin à la place ? Je reste disponible pour en discuter. Cordialement, Ivan Petrov.',
   'Le registre professionnel est tenu partout, avec une ouverture et une clôture soignées.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S1 / INSUFFICIENT
  ('71214a66-fef5-5f86-b76f-c24b9fb2c299', 'b331ef2a-aa92-561b-9005-a073e8fc2e0e', 'INSUFFICIENT',
   'Bonjour, j''ai un petit problème avec la journée de jeudi, je vous explique.',
   'Le lecteur ne sait pas encore que le rendez-vous est annulé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S1 / EXPECTED
  ('2599b19c-2894-5ea8-b4bd-9b3fa0dd8856', 'b331ef2a-aa92-561b-9005-a073e8fc2e0e', 'EXPECTED',
   'Bonjour, je vous écris pour annuler mon rendez-vous de jeudi à 15 h.',
   'L''objet du message est annoncé immédiatement : c''est ce qui est demandé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S1 / EXCELLENT
  ('2925804c-8906-5793-91f2-b3c4e83c9ef6', 'b331ef2a-aa92-561b-9005-a073e8fc2e0e', 'EXCELLENT',
   'Bonjour, je dois malheureusement annuler mon rendez-vous du jeudi 12 mars à 15 h avec le docteur Aubry.',
   'L''annulation est annoncée d''emblée et le rendez-vous est identifié sans ambiguïté.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S2 / INSUFFICIENT
  ('d2be6a3b-b94f-57bb-9679-73606f086886', '9d8bfc2f-4cc9-590a-9a20-13ad22514121', 'INSUFFICIENT',
   'Bonjour Madame Diaz, je suis bien rentrée hier soir, le voyage a été très long.',
   'Rien n''annonce le remerciement : le lecteur attend encore l''objet du message.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S2 / EXPECTED
  ('3a467b20-e4cc-5569-938b-1cef0e484acc', '9d8bfc2f-4cc9-590a-9a20-13ad22514121', 'EXPECTED',
   'Bonjour Madame Diaz, je voulais vous remercier d''avoir gardé mon chat pendant mon absence. Tout s''est très bien passé.',
   'Le remerciement arrive en premier : l''objet du message est clair.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S2 / EXCELLENT
  ('6a1eb867-d328-5b68-b980-d2dd9075e44c', '9d8bfc2f-4cc9-590a-9a20-13ad22514121', 'EXCELLENT',
   'Bonjour Madame Diaz, un grand merci d''avoir gardé Minou pendant mes deux semaines d''absence. Il était en pleine forme à mon retour.',
   'Le merci ouvre le message et la suite ne fait que le préciser.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S3 / INSUFFICIENT
  ('23ce3c53-5cdc-5172-b0ef-3cb9d858eb9e', '8f82648f-4d21-5460-9f34-af882186ed2e', 'INSUFFICIENT',
   'Bonjour à tous, j''espère que vous allez bien. La semaine va être chargée, il y a beaucoup de chantiers en cours.',
   'Le message ne dit pas encore que la réunion change de date.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S3 / EXPECTED
  ('c6e5c8aa-ce06-5e2b-9edf-5b6c41d15095', '8f82648f-4d21-5460-9f34-af882186ed2e', 'EXPECTED',
   'Bonjour à tous, la réunion d''équipe de mardi est reportée à jeudi. Elle aura lieu à 9 h dans la salle habituelle.',
   'Le changement est annoncé tout de suite, la précision vient après.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S3 / EXCELLENT
  ('43d058d2-71b7-5bb8-8c4a-0461ca166be6', '8f82648f-4d21-5460-9f34-af882186ed2e', 'EXCELLENT',
   'Bonjour à tous, petit changement : la réunion d''équipe de mardi est déplacée à jeudi 9 h, dans la même salle. Merci de noter la nouvelle date.',
   '« Petit changement » annonce l''objet et prépare le lecteur à l''information.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S4 / INSUFFICIENT
  ('8526a82e-ab73-5b76-ba96-e6280169d0ea', 'e08248b9-c463-5612-940e-c8ced942c9a5', 'INSUFFICIENT',
   'Bonjour, je suis arrivée en France il y a deux ans et je travaille tous les matins. J''ai vu votre centre sur internet.',
   'Le lecteur lit des informations personnelles sans savoir ce qui est demandé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S4 / EXPECTED
  ('8009d466-73c8-507e-b622-097b981332df', 'e08248b9-c463-5612-940e-c8ced942c9a5', 'EXPECTED',
   'Bonjour, je vous écris pour obtenir des informations sur votre formation de français. Je voudrais connaître les horaires et le tarif.',
   'L''objet est annoncé d''abord, les questions viennent ensuite : c''est clair.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S4 / EXCELLENT
  ('232a19c9-6423-5ec0-a435-64da36c2269e', 'e08248b9-c463-5612-940e-c8ced942c9a5', 'EXCELLENT',
   'Madame, Monsieur, je souhaite m''inscrire à votre formation de français et je vous écris pour obtenir quelques renseignements : horaires, tarif et documents à fournir.',
   'Une seule phrase installe le but du message et annonce les questions.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S5 / INSUFFICIENT
  ('fce6a8d9-b505-5096-b91f-b7d587137855', '0176ca90-0099-576d-b0c0-ee2083481f85', 'INSUFFICIENT',
   'Madame, Monsieur, samedi dernier, j''attendais le bus de 7 h à Lyon. Il n''est jamais arrivé. J''ai attendu une heure, puis j''ai pris un taxi et je suis arrivé très en retard à Grenoble. C''était vraiment compliqué pour moi.',
   'Le récit occupe tout le message ; la demande n''apparaît jamais clairement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S5 / EXPECTED
  ('887137d3-d34a-5a0f-b034-0c6a9fac8b89', '0176ca90-0099-576d-b0c0-ee2083481f85', 'EXPECTED',
   'Madame, Monsieur, je vous écris pour demander le remboursement de mon billet de 42 euros. Mon bus Lyon-Grenoble du samedi 8 mars a été annulé sans information et j''ai dû prendre un taxi.',
   'La demande ouvre le message ; les explications la justifient ensuite.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C2-S5 / EXCELLENT
  ('8dc5517d-d65b-56d2-9b54-2b14966929ac', '0176ca90-0099-576d-b0c0-ee2083481f85', 'EXCELLENT',
   'Madame, Monsieur, je vous demande le remboursement de mon billet de 42 euros (réservation 5482). Mon bus Lyon-Grenoble du samedi 8 mars n''est jamais parti et aucune information ne nous a été donnée sur place. Je vous remercie de votre réponse.',
   'L''objet est net dès la première ligne, le reste vient l''appuyer.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S1 / INSUFFICIENT
  ('2d456218-446e-5df2-8284-6e10ee8e24ef', '5de5d54b-bc7c-5c58-bc8c-1a9d517efbfd', 'INSUFFICIENT',
   'Salut Mehdi ! Je fête mon anniversaire samedi, viens, ce sera vraiment sympa !',
   'L''heure et le lieu manquent : Mehdi ne peut pas venir.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S1 / EXPECTED
  ('c198069f-996b-5b60-b7d3-07f39a6a3e7f', '5de5d54b-bc7c-5c58-bc8c-1a9d517efbfd', 'EXPECTED',
   'Salut Mehdi ! Je fête mon anniversaire samedi chez moi, au 8 rue Pasteur, à partir de 19 h.',
   'Le lieu et l''heure sont donnés : le message est utilisable.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S1 / EXCELLENT
  ('ea32b0c8-608a-5291-8af3-c5ff48901ffd', '5de5d54b-bc7c-5c58-bc8c-1a9d517efbfd', 'EXCELLENT',
   'Salut Mehdi ! Je fête mon anniversaire samedi chez moi, 8 rue Pasteur, bâtiment B, à partir de 19 h 30. Tu peux venir ?',
   'Chaque détail, du bâtiment à l''horaire, évite une question de plus.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S2 / INSUFFICIENT
  ('2a55f73a-36e9-5cd7-8f6d-7190267d6028', '8de20dd2-564c-54fd-9181-7ff061656385', 'INSUFFICIENT',
   'Coucou, j''arrive à Bordeaux demain dans l''après-midi. On se retrouve à la gare ?',
   '« Dans l''après-midi » et « à la gare » restent beaucoup trop vagues.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S2 / EXPECTED
  ('b4718379-7d6d-5716-8c73-5d42f938afaf', '8de20dd2-564c-54fd-9181-7ff061656385', 'EXPECTED',
   'Coucou, j''arrive demain à 14 h 20 à la gare Saint-Jean. On se retrouve devant l''entrée principale ?',
   'L''heure exacte et le point de rendez-vous permettent de se trouver.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S2 / EXCELLENT
  ('9d07a729-8622-5955-bd37-d959c19708ce', '8de20dd2-564c-54fd-9181-7ff061656385', 'EXCELLENT',
   'Coucou, j''arrive demain à 14 h 20, gare Saint-Jean, voie 6. Je t''attends devant la sortie principale, à côté de la boulangerie.',
   'Voie, sortie et repère visuel : impossible de se manquer.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S3 / INSUFFICIENT
  ('2b114795-d867-537a-9314-c796b07a3722', '0adb1223-c831-5a76-b42f-ca259ba7e053', 'INSUFFICIENT',
   'J''habite près du parc, dans le grand immeuble gris. Sonne quand tu arrives et je descends t''ouvrir.',
   'Sans adresse, code ni étage, votre amie devra vous appeler.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S3 / EXPECTED
  ('8ea0a85a-03c3-5cb4-9b35-9b6c9b827dee', '0adb1223-c831-5a76-b42f-ca259ba7e053', 'EXPECTED',
   'J''habite au 14 avenue Jean Jaurès. Le code de la porte est 2580A et je suis au quatrième étage, porte de gauche.',
   'Adresse, code et étage : les trois informations utiles sont là.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S3 / EXCELLENT
  ('d0bddb23-e806-5539-8c3c-e0640b689750', '0adb1223-c831-5a76-b42f-ca259ba7e053', 'EXCELLENT',
   'J''habite au 14 avenue Jean Jaurès, juste en face du parc. Le code de la porte est 2580A. Prends l''escalier B jusqu''au quatrième étage : c''est la porte de gauche.',
   'Les trois informations sont précises et l''ordre suit le trajet.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S4 / INSUFFICIENT
  ('8f4193fb-6d7b-5089-b72c-4bced773b43d', '1af08222-3aac-5fbf-9f04-3cbb26e8169b', 'INSUFFICIENT',
   'Le rendez-vous à la préfecture est confirmé. N''oublie pas tes papiers, on se retrouve directement là-bas.',
   'Ni date, ni heure, ni liste : « tes papiers » ne suffit pas.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S4 / EXPECTED
  ('814b6da0-4d3f-5a08-b540-9df61d2f9b25', '1af08222-3aac-5fbf-9f04-3cbb26e8169b', 'EXPECTED',
   'Le rendez-vous est le mardi 4 avril à 9 h 30 à la préfecture. Apporte ton passeport, ton ancien titre de séjour et un justificatif de domicile.',
   'Date, heure et documents sont donnés : ton frère peut s''organiser.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S4 / EXCELLENT
  ('ca9bff98-052d-5961-ba4c-2a6211c115ab', '1af08222-3aac-5fbf-9f04-3cbb26e8169b', 'EXCELLENT',
   'Rendez-vous mardi 4 avril à 9 h 30 à la préfecture, guichet 7. Apporte ton passeport, ton ancien titre de séjour, un justificatif de domicile de moins de trois mois et deux photos.',
   'Le guichet et la validité du justificatif évitent un déplacement pour rien.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S5 / INSUFFICIENT
  ('5f41a9d6-c202-544e-b379-d102e7d0336b', 'daa879e1-a4d5-595a-b173-749abd044abd', 'INSUFFICIENT',
   'Bonjour à tous, une grosse livraison arrive la semaine prochaine. Il faudra être présents et bien s''organiser, ce sera une longue journée. Merci d''avance à chacun.',
   'Le message annonce l''événement mais ne donne aucune information exploitable.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S5 / EXPECTED
  ('c15057e8-95db-53df-a545-4d1760693067', 'daa879e1-a4d5-595a-b173-749abd044abd', 'EXPECTED',
   'Bonjour à tous, la livraison arrive mercredi 12 à 7 h, à l''entrée de la réserve. Sonia s''occupe de la réception : voyez avec elle si vous avez une question.',
   'Jour, heure, lieu et contact : chacun sait où se présenter.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C3-S5 / EXCELLENT
  ('ca1885fd-f34b-5372-8400-b1e1149e5037', 'daa879e1-a4d5-595a-b173-749abd044abd', 'EXCELLENT',
   'Bonjour à tous, la livraison arrive mercredi 12 à 7 h précises, au quai de la réserve, porte arrière. Sonia Karimi supervise la réception et reste joignable au 06 12 34 56 78. Merci d''être sur place à 6 h 45.',
   'Chaque information est complète, jusqu''à l''heure où il faut être présent.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S1 / INSUFFICIENT
  ('3b3c6c91-bfcd-520c-b5bc-babce6532f82', '6c468df6-1298-5b27-998d-69a0233f83ba', 'INSUFFICIENT',
   'Bonjour, je reçois un colis demain. Prenez-le pour moi, je travaille toute la journée.',
   'L''impératif sans politesse transforme la demande en ordre.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S1 / EXPECTED
  ('d8750158-51f1-54b8-9755-4fd70f65682d', '6c468df6-1298-5b27-998d-69a0233f83ba', 'EXPECTED',
   'Bonjour, je reçois un colis demain et je travaille toute la journée. Pourriez-vous le prendre pour moi, s''il vous plaît ?',
   '« Pourriez-vous » et « s''il vous plaît » rendent la demande polie.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S1 / EXCELLENT
  ('7d24d5d5-2f30-51f0-a01f-57a22edc9600', '6c468df6-1298-5b27-998d-69a0233f83ba', 'EXCELLENT',
   'Bonjour Monsieur Wei, je reçois un colis demain et je serai au travail. Seriez-vous d''accord pour le réceptionner ? Je le récupérerai en rentrant, vers 19 h.',
   'La demande est polie et laisse au voisin la possibilité de refuser.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S2 / INSUFFICIENT
  ('462f806e-0f93-5ac5-8d7a-a2b98daa8512', '0bb7f81f-dfe0-511d-92c4-513eb29b498c', 'INSUFFICIENT',
   'Bonjour, j''étais absent lundi. Envoyez-moi le document du cours aujourd''hui.',
   'La demande est claire mais l''impératif sec manque de politesse.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S2 / EXPECTED
  ('1b62d402-9d47-5e5d-b63a-2238e8b495fd', '0bb7f81f-dfe0-511d-92c4-513eb29b498c', 'EXPECTED',
   'Bonjour Madame, j''étais absent au cours de lundi. Pourriez-vous m''envoyer le document distribué ce jour-là ? Merci beaucoup.',
   'Le conditionnel et le remerciement suffisent à rendre la demande polie.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S2 / EXCELLENT
  ('8fd1d973-0269-5fb4-8f5f-4d64b8cc6f8a', '0bb7f81f-dfe0-511d-92c4-513eb29b498c', 'EXCELLENT',
   'Bonjour Madame Lambert, je n''ai pas pu assister au cours de lundi. Serait-il possible de recevoir le document distribué ce jour-là ? Je vous remercie par avance.',
   '« Serait-il possible » et le remerciement anticipé sonnent naturels et polis.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S3 / INSUFFICIENT
  ('2ceaaef8-8b35-5f5b-85fe-b014ef6402cf', 'ddb4f776-594a-5112-929d-9c5a1858399c', 'INSUFFICIENT',
   'Bonjour, à partir de lundi je viendrai à 9 h parce que je dois emmener mon fils à l''école.',
   'Ce n''est pas une demande mais une décision annoncée au responsable.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S3 / EXPECTED
  ('59328433-7856-5818-b7b6-fc32781e2e44', 'ddb4f776-594a-5112-929d-9c5a1858399c', 'EXPECTED',
   'Bonjour Madame, pendant deux semaines je dois emmener mon fils à l''école le matin. Serait-il possible de commencer à 9 h au lieu de 8 h ? Merci de me dire ce que vous en pensez.',
   'La demande est polie et la réponse reste entre les mains du responsable.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S3 / EXCELLENT
  ('846cd598-bbe0-5d85-b8c6-015e2d1a3fd5', 'ddb4f776-594a-5112-929d-9c5a1858399c', 'EXCELLENT',
   'Bonjour Madame Okonkwo, je dois emmener mon fils à l''école pendant deux semaines. Serait-il envisageable de commencer à 9 h et de terminer plus tard le soir ? Si ce n''est pas possible, je m''organiserai autrement. Merci beaucoup.',
   'La solution proposée et l''ouverture au refus rendent la demande vraiment polie.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S4 / INSUFFICIENT
  ('b50a783d-1f74-522a-bba0-cb8fc936d634', '09597d62-c18d-5456-a561-86e5f000855c', 'INSUFFICIENT',
   'Bonjour, il me faut une attestation pour ma consultation de la semaine dernière. C''est urgent.',
   '« Il me faut » et « urgent » pèsent : la politesse manque ici.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S4 / EXPECTED
  ('668578d5-dc00-54fc-8ba3-e457c9667a1c', '09597d62-c18d-5456-a561-86e5f000855c', 'EXPECTED',
   'Bonjour, j''ai consulté le docteur Silva mardi dernier. Pourriez-vous m''établir une attestation de consultation pour mon employeur ? Je vous remercie.',
   'Demande polie et remerciement final : les deux éléments attendus sont là.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S4 / EXCELLENT
  ('41d0d594-4685-5b66-bb96-9776b2525c18', '09597d62-c18d-5456-a561-86e5f000855c', 'EXCELLENT',
   'Bonjour, j''ai consulté le docteur Silva le mardi 3 juin. Mon employeur me demande une attestation de consultation : pourriez-vous me l''établir quand vous aurez un moment ? Je vous remercie sincèrement.',
   '« Quand vous aurez un moment » adoucit la demande sans la rendre floue.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S5 / INSUFFICIENT
  ('218ce81c-0eaf-5520-9a68-259297f0f360', 'e78ab711-9d8c-5b7e-b85e-dbf29d0065f3', 'INSUFFICIENT',
   'Madame, Monsieur, je suis vraiment désolé de vous déranger, je sais que vous êtes très occupés et j''espère que je ne prends pas trop de votre temps. Excusez-moi encore de vous écrire aujourd''hui.',
   'Les excuses répétées occupent la place de la demande, qui n''arrive jamais.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S5 / EXPECTED
  ('86071e87-e21c-5f6a-a9de-f84e25a77776', 'e78ab711-9d8c-5b7e-b85e-dbf29d0065f3', 'EXPECTED',
   'Madame, Monsieur, je souhaite déposer un dossier de demande de logement social, mais aucun créneau n''est disponible en ligne. Pourriez-vous me proposer un rendez-vous ? Je suis disponible les lundis et jeudis matin. Cordialement, Nadia Haddad.',
   'La demande est directe, polie, et l''excès d''excuses est évité.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C4-S5 / EXCELLENT
  ('68fbfc4e-c8dc-522e-93b9-7b28ce3f4f24', 'e78ab711-9d8c-5b7e-b85e-dbf29d0065f3', 'EXCELLENT',
   'Madame, Monsieur, je souhaite déposer un dossier de demande de logement social. Le site ne propose aucun créneau ce mois-ci : pourriez-vous m''indiquer une date de rendez-vous ? Je suis disponible les lundis et jeudis matin, et je peux me déplacer rapidement si une place se libère. Cordialement, Nadia Haddad.',
   'Demande nette, ton respectueux et disponibilité claire : rien à ajouter.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S1 / INSUFFICIENT
  ('5ef094dc-09f5-5126-9800-c4f61124b7fb', '27ff05d1-69e5-59c6-b591-7d1db292f135', 'INSUFFICIENT',
   'Bonjour, il y a des choses sympas prévues dans l''immeuble en ce moment, si jamais cela vous intéresse.',
   'Ce n''est pas une invitation : ni jour, ni activité, ni proposition nette.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S1 / EXPECTED
  ('23e928c2-4464-5008-95c7-ba7f1e2234d3', '27ff05d1-69e5-59c6-b591-7d1db292f135', 'EXPECTED',
   'Bonjour, les habitants de l''immeuble organisent un repas dans la cour samedi soir. Vous êtes invité à venir avec nous.',
   'L''invitation, le jour et l''activité sont clairs : le voisin peut répondre.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S1 / EXCELLENT
  ('92af354b-52e2-5d99-93f8-9a73d959f697', '27ff05d1-69e5-59c6-b591-7d1db292f135', 'EXCELLENT',
   'Bonjour, nous organisons un repas entre voisins samedi soir à 19 h dans la cour. Je serais content que vous veniez : chacun apporte un plat.',
   'L''invitation est chaleureuse, précise, et dit comment y participer.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S2 / INSUFFICIENT
  ('a4777c7e-e0d3-51df-a8b7-688a4ccadebf', 'a91b0de2-90df-5db4-8179-bc8fa6a32b83', 'INSUFFICIENT',
   'Salut Thomas ! Dimanche, c''est un peu compliqué pour moi. On verra bien, je te redis.',
   'Thomas ne sait pas si vous venez : le refus n''est pas dit.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S2 / EXPECTED
  ('279e9f98-36b2-53aa-aea0-29108644eade', 'a91b0de2-90df-5db4-8179-bc8fa6a32b83', 'EXPECTED',
   'Salut Thomas ! Merci pour la proposition, mais je ne peux pas venir dimanche : je travaille toute la journée.',
   'Le refus est net et la raison évite tout malentendu.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S2 / EXCELLENT
  ('acff61c6-fbb3-520c-8fc9-78f776b7a9fd', 'a91b0de2-90df-5db4-8179-bc8fa6a32b83', 'EXCELLENT',
   'Salut Thomas ! Merci d''avoir pensé à moi, mais je ne pourrai pas venir dimanche, je travaille jusqu''à 20 h. Une prochaine fois avec plaisir !',
   'Le non est clair, le ton reste amical et la porte reste ouverte.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S3 / INSUFFICIENT
  ('158a17c1-35ba-5509-be46-ec1af00e422b', '28ce0e24-c333-5a08-8ce0-8477ba94e455', 'INSUFFICIENT',
   'Bonjour Awa, c''est gentil de me proposer ça, ça m''arrangerait bien en ce moment.',
   'Le message ne dit pas si vous acceptez l''échange proposé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S3 / EXPECTED
  ('42e7d32a-86b0-5a17-a2a8-ca8b4d58d762', '28ce0e24-c333-5a08-8ce0-8477ba94e455', 'EXPECTED',
   'Bonjour Awa, oui, j''accepte l''échange avec plaisir. Je travaillerai ton mercredi et tu prends mon samedi.',
   'L''accord est explicite et le jour de chacun est confirmé.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S3 / EXCELLENT
  ('f2e83570-f8b3-58a4-b2a1-fc2e2cf55c11', '28ce0e24-c333-5a08-8ce0-8477ba94e455', 'EXCELLENT',
   'Bonjour Awa, c''est d''accord pour l''échange : je prends ton mercredi 14 et tu fais mon samedi 17. Je préviens la responsable aujourd''hui.',
   'L''accord, les dates et l''étape suivante ne laissent aucun doute.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S4 / INSUFFICIENT
  ('d282951f-4858-5158-b760-a1f8b97e7684', 'a848dfca-8cc2-5bc2-9c07-b1b0b479ec28', 'INSUFFICIENT',
   'Salut Ana, il faudrait qu''on révise ensemble avant l''examen, ce serait bien pour nous deux.',
   'L''intention est là, mais aucune proposition concrète n''est faite.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S4 / EXPECTED
  ('197b9925-bfdf-530b-8d2c-671f96759712', 'a848dfca-8cc2-5bc2-9c07-b1b0b479ec28', 'EXPECTED',
   'Salut Ana, ça te dit de réviser ensemble avant l''examen ? Je suis libre mardi après-midi ou samedi matin, comme tu préfères.',
   'La proposition est nette et les deux créneaux permettent de choisir.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S4 / EXCELLENT
  ('92ffd2a4-cb76-5527-9450-d7e7cd12f160', 'a848dfca-8cc2-5bc2-9c07-b1b0b479ec28', 'EXCELLENT',
   'Salut Ana, je te propose qu''on révise l''expression écrite ensemble. Mardi après-midi à la bibliothèque ou samedi matin chez moi : dis-moi ce qui t''arrange le mieux.',
   'Le sujet, les deux options et le lieu rendent la proposition facile à accepter.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S5 / INSUFFICIENT
  ('27154308-15ff-5873-a613-e236e2692f50', '9cb2b1ea-c1d0-5931-8279-21731fbe2f1d', 'INSUFFICIENT',
   'Bonjour Madame Traoré, vendredi soir ce n''est pas facile pour moi, j''ai déjà quelque chose de prévu et je rentre tard. Je suis désolée, c''est vraiment dommage.',
   'Le refus est compris, mais aucune autre solution n''est proposée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S5 / EXPECTED
  ('32396f4d-eaed-5536-8323-bbe46373e389', '9cb2b1ea-c1d0-5931-8279-21731fbe2f1d', 'EXPECTED',
   'Bonjour Madame Traoré, je ne peux malheureusement pas garder vos enfants vendredi soir, je travaille jusqu''à 21 h. En revanche, je suis libre samedi après-midi si cela peut vous aider.',
   'Le refus est clair et l''alternative rend le message utile.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C5-S5 / EXCELLENT
  ('d457e9a7-2440-5ed7-a8ff-f34b1bf41e0f', '9cb2b1ea-c1d0-5931-8279-21731fbe2f1d', 'EXCELLENT',
   'Bonjour Madame Traoré, je suis désolée, je ne peux pas garder vos enfants vendredi soir : je termine à 21 h. Je peux les garder samedi après-midi, ou vous donner le numéro de Julie, du deuxième étage, qui fait souvent du baby-sitting.',
   'Un non net et deux solutions concrètes : le message reste vraiment aidant.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S1 / INSUFFICIENT
  ('18552113-4f3b-52e9-a8e7-8cf6523b688a', 'cf9626ad-6d23-5259-b05b-a07ef17ded91', 'INSUFFICIENT',
   'Salut Camille, je vais avoir un peu de retard, à tout de suite !',
   'L''excuse et la raison manquent toutes les deux.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S1 / EXPECTED
  ('162a5e00-9217-5c88-aeb5-67af82f0f8a0', 'cf9626ad-6d23-5259-b05b-a07ef17ded91', 'EXPECTED',
   'Salut Camille, désolée, j''aurai vingt minutes de retard : mon bus est bloqué dans les embouteillages.',
   'Excuse et raison en une phrase : c''est exactement ce qui est attendu.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S1 / EXCELLENT
  ('483eda4b-ecc0-53c0-95ee-12937849f1a1', 'cf9626ad-6d23-5259-b05b-a07ef17ded91', 'EXCELLENT',
   'Salut Camille, je suis vraiment désolée : mon bus est bloqué depuis dix minutes. J''arriverai vers 18 h 20, commence sans moi !',
   'L''excuse, la cause et l''heure d''arrivée règlent la situation d''un coup.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S2 / INSUFFICIENT
  ('bfcb539b-eb79-5a0b-ae2d-7503847e9fe5', '27c430ec-dfdb-53a0-8c9f-f8b1cf9a5e85', 'INSUFFICIENT',
   'Bonjour, je passerai rendre le livre cette semaine, je n''ai pas eu le temps avant.',
   'Aucune excuse n''est présentée, seulement une explication rapide.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S2 / EXPECTED
  ('fda6be59-8d9b-5cb0-99d9-0e21963dfb39', '27c430ec-dfdb-53a0-8c9f-f8b1cf9a5e85', 'EXPECTED',
   'Bonjour, je suis désolé pour ce retard : j''ai oublié de rapporter le livre avant mon déplacement. Je le rapporte demain.',
   'L''excuse est présentée et la raison est simple mais suffisante.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S2 / EXCELLENT
  ('8565c499-f244-5cf2-8104-edcd7de4fb8c', '27c430ec-dfdb-53a0-8c9f-f8b1cf9a5e85', 'EXCELLENT',
   'Bonjour, je vous prie de m''excuser pour ce retard : j''ai été absent une semaine pour raisons familiales et le livre est resté chez moi. Je le rapporte demain matin.',
   'Excuse formelle et raison crédible, sans récit inutile.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S3 / INSUFFICIENT
  ('f96be820-b8c9-5c59-8c29-4f6de4a3b5a2', '711154a2-700a-580f-90fe-5b46c84780f3', 'INSUFFICIENT',
   'Bonjour Monsieur, désolé pour hier, je n''ai pas pu venir. Je serai là aujourd''hui normalement.',
   'L''excuse est là, mais la raison de l''absence reste inconnue.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S3 / EXPECTED
  ('14cec0a1-689e-5ac7-bbad-8b1c5e6fe718', '711154a2-700a-580f-90fe-5b46c84780f3', 'EXPECTED',
   'Bonjour Monsieur, je vous prie de m''excuser pour mon absence d''hier. Ma fille était malade et j''ai dû l''emmener aux urgences.',
   'Excuse claire et raison précise : le responsable comprend la situation.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S3 / EXCELLENT
  ('9119a8de-0c24-5b1f-b988-e0100029166a', '711154a2-700a-580f-90fe-5b46c84780f3', 'EXCELLENT',
   'Bonjour Monsieur Delaunay, je vous prie de m''excuser pour mon absence d''hier. Ma fille a été hospitalisée dans la nuit et je n''ai pas pu prévenir plus tôt. Je vous apporte le certificat aujourd''hui.',
   'L''excuse, la raison et le justificatif ferment le sujet proprement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S4 / INSUFFICIENT
  ('e672b847-bd02-5dbf-a480-dc0b08b8f849', 'bc388229-26e1-5326-b28b-d8fb64df41d1', 'INSUFFICIENT',
   'Bonjour, j''espère que le bruit de samedi ne vous a pas trop dérangée. Bon week-end à vous.',
   'Le bruit est évoqué, mais l''excuse et la cause manquent.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S4 / EXPECTED
  ('ef2a9fcb-2fcd-5051-af95-2ed4b9ff798a', 'bc388229-26e1-5326-b28b-d8fb64df41d1', 'EXPECTED',
   'Bonjour Madame, je m''excuse pour le bruit de samedi matin : je devais changer le carrelage de la salle de bain.',
   'Excuse et cause en une phrase, sans se justifier longuement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S4 / EXCELLENT
  ('bdc40056-82cc-5d66-b4ab-e54a3f126e66', 'bc388229-26e1-5326-b28b-d8fb64df41d1', 'EXCELLENT',
   'Bonjour Madame Nguyen, je vous prie d''excuser le bruit de samedi matin : je remplaçais le carrelage de la salle de bain. Les travaux sont terminés, vous ne serez plus dérangée.',
   'L''excuse, la cause et la fin du dérangement rassurent la voisine.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S5 / INSUFFICIENT
  ('25ff8690-69dc-5315-822e-fdd36273301a', '78dfed5f-28da-5966-b472-58646aaad2df', 'INSUFFICIENT',
   'Bonjour Madame, mon fils Yanis n''était pas à l''école mardi et mercredi. Il reviendra jeudi normalement. Merci de votre compréhension.',
   'L''absence est signalée, mais ni excuse ni raison n''apparaissent.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S5 / EXPECTED
  ('23e17fcd-1a0b-52ef-858c-9cad9ba31023', '78dfed5f-28da-5966-b472-58646aaad2df', 'EXPECTED',
   'Bonjour Madame, je vous prie d''excuser l''absence de mon fils Yanis mardi et mercredi. Il avait beaucoup de fièvre et le médecin lui a demandé de rester à la maison deux jours. Il revient jeudi.',
   'Excuse et raison précise : le mot remplit exactement son rôle.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C6-S5 / EXCELLENT
  ('f89eeb5c-cfa8-5211-9554-86e06031febb', '78dfed5f-28da-5966-b472-58646aaad2df', 'EXCELLENT',
   'Bonjour Madame Perrin, je vous prie d''excuser l''absence de Yanis mardi 12 et mercredi 13. Il a eu une forte fièvre et le médecin a conseillé deux jours de repos. Il reprendra jeudi et rattrapera les exercices ce week-end. Cordialement, Fatou Sow.',
   'L''excuse, la cause et la suite donnée font un mot complet et sûr.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S1 / INSUFFICIENT
  ('1b7caf0b-7e02-5940-b832-a3580c3175ea', 'efdde157-a9fa-527c-b1d7-84a53de1628f', 'INSUFFICIENT',
   'Salut, mon studio se libère le mois prochain, il est vraiment très bien, tu devrais le prendre.',
   '« Très bien » ne décrit rien : votre ami ignore à quoi s''attendre.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S1 / EXPECTED
  ('1117891e-ead5-5da7-8031-daa9c9dd6817', 'efdde157-a9fa-527c-b1d7-84a53de1628f', 'EXPECTED',
   'Salut, mon studio se libère le mois prochain. Il fait 25 m², il est au calme et le loyer est de 480 euros.',
   'Surface, environnement et loyer suffisent à se faire une idée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S1 / EXCELLENT
  ('464f1f88-7b8c-51b9-9942-e7238535d594', 'efdde157-a9fa-527c-b1d7-84a53de1628f', 'EXCELLENT',
   'Salut, mon studio se libère le mois prochain : 25 m², cuisine équipée, grande fenêtre côté cour, très calme. Le loyer est de 480 euros charges comprises.',
   'Chaque détail est concret et répond à une vraie question du locataire.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S2 / INSUFFICIENT
  ('70ffde42-93ab-5ee0-938b-3f2fcb2bc068', '8f59523c-6c4c-5f87-82cb-c3d2fdff892e', 'INSUFFICIENT',
   'Bonjour, ma belle-sœur viendra chercher les clés à ma place vendredi matin, merci de les lui donner.',
   'Rien ne permet à l''agence de reconnaître la personne annoncée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S2 / EXPECTED
  ('d26718e5-0e60-58f9-b681-5681888b7656', '8f59523c-6c4c-5f87-82cb-c3d2fdff892e', 'EXPECTED',
   'Bonjour, ma belle-sœur Rita Costa viendra chercher les clés vendredi matin. Elle a une cinquantaine d''années, les cheveux courts et gris, et elle porte des lunettes.',
   'Le nom et deux détails physiques suffisent à l''identifier.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S2 / EXCELLENT
  ('40d552c3-ee03-5be8-b09e-bb997dc249b3', '8f59523c-6c4c-5f87-82cb-c3d2fdff892e', 'EXCELLENT',
   'Bonjour, ma belle-sœur Rita Costa passera vendredi vers 10 h. Elle a une cinquantaine d''années, les cheveux courts et gris, des lunettes rondes, et elle aura sa pièce d''identité.',
   'Les détails sont précis et la pièce d''identité lève tout doute.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S3 / INSUFFICIENT
  ('94fd7d8e-3c6a-5828-8033-96c52400c9e3', 'c5d8740c-60c5-556a-b8df-74fabb731a82', 'INSUFFICIENT',
   'Bonjour, j''ai oublié mon sac dans le bus 27 hier soir. Est-ce que quelqu''un l''a rapporté ? C''est très important pour moi.',
   'Sans description, le service ne peut pas retrouver le sac.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S3 / EXPECTED
  ('2c443ed3-4a0c-54b5-9553-e8bee1649946', 'c5d8740c-60c5-556a-b8df-74fabb731a82', 'EXPECTED',
   'Bonjour, j''ai oublié mon sac dans le bus 27 hier soir. C''est un sac à dos noir de taille moyenne, avec un cahier bleu et une trousse rouge à l''intérieur.',
   'Couleur, taille et contenu permettent une recherche efficace.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S3 / EXCELLENT
  ('4af09cca-ce79-5f99-843d-ab4752d75d4b', 'c5d8740c-60c5-556a-b8df-74fabb731a82', 'EXCELLENT',
   'Bonjour, j''ai oublié mon sac dans le bus 27 hier vers 19 h. C''est un sac à dos noir de taille moyenne, avec une bande grise sur le devant et une fermeture cassée à droite. Il contient un cahier bleu et une trousse rouge.',
   'Le détail de la fermeture cassée rend le sac identifiable entre tous.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S4 / INSUFFICIENT
  ('c77ab239-e964-586c-8452-f7324138ef4b', 'aa457d87-8856-53f0-966c-11b1c18e1452', 'INSUFFICIENT',
   'Salut, mon quartier est très agréable, les gens sont sympas et j''aime bien y habiter depuis trois ans.',
   'L''avis est donné, mais rien n''est décrit concrètement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S4 / EXPECTED
  ('d13d0abd-0aa8-5812-9ffa-01b34d792eea', 'aa457d87-8856-53f0-966c-11b1c18e1452', 'EXPECTED',
   'Salut, mon quartier est calme et bien desservi : il y a le tramway à cinq minutes, un marché le samedi et plusieurs écoles.',
   'Transports, commerces et écoles : trois informations vraiment utiles.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S4 / EXCELLENT
  ('80a3a1fe-c49a-5b32-92f1-0a54fdf800fd', 'aa457d87-8856-53f0-966c-11b1c18e1452', 'EXCELLENT',
   'Salut, mon quartier est calme et pratique : tramway à cinq minutes, marché le samedi matin, deux écoles et un centre de santé. Les loyers sont un peu plus bas qu''au centre-ville.',
   'La description est concrète et anticipe la question du budget.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S5 / INSUFFICIENT
  ('a43491de-5af1-5296-bfca-b16c19776c37', 'd262dae9-8c8b-5dda-bc64-9519c551ba10', 'INSUFFICIENT',
   'Madame, Monsieur, mon vélo a été volé devant la gare. Je suis très ennuyé car j''en ai besoin tous les jours pour aller travailler. Je compte sur vous pour m''aider rapidement.',
   'Le message dit la conséquence mais ne décrit ni la scène ni le vélo.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S5 / EXPECTED
  ('ad3a0ea5-3a06-5d00-9807-9063ba5f97fa', 'd262dae9-8c8b-5dda-bc64-9519c551ba10', 'EXPECTED',
   'Madame, Monsieur, mon vélo a été volé jeudi 5 juin devant la gare de Rennes. Je l''avais attaché au parking à vélos vers 8 h et il avait disparu à 18 h. C''est un vélo de ville vert, de marque Btwin, avec un panier à l''avant.',
   'Lieu, moment et description du vélo : le dossier est compréhensible.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C7-S5 / EXCELLENT
  ('a7ff4be8-18d0-5a57-ac39-892b98dafd73', 'd262dae9-8c8b-5dda-bc64-9519c551ba10', 'EXCELLENT',
   'Madame, Monsieur, je déclare le vol de mon vélo, jeudi 5 juin, au parking à vélos de la gare de Rennes. Je l''avais attaché avec un antivol en U à 8 h ; à 18 h, seul l''antivol coupé restait au sol. C''est un vélo de ville vert de marque Btwin, avec un panier avant et une selle marron.',
   'L''antivol coupé et les détails du vélo racontent la scène avec précision.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S1 / INSUFFICIENT
  ('326da81d-bd09-5d1a-bc0e-d3e5f22012f7', '79506cab-4962-5f03-98ff-3d51d327d1cd', 'INSUFFICIENT',
   'Salut Lucie, le musée est fermé samedi.',
   'L''annonce est là, mais ni le nouveau lieu ni la clôture n''apparaissent.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S1 / EXPECTED
  ('76eae671-599b-5138-b8ba-d83d1060e39f', '79506cab-4962-5f03-98ff-3d51d327d1cd', 'EXPECTED',
   'Salut Lucie, le musée est fermé samedi, donc on ne peut pas s''y retrouver. On peut se voir au café de la place à 14 h. Dis-moi si ça te va !',
   'Les trois étapes sont là et le message se termine naturellement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S1 / EXCELLENT
  ('97dcc831-9c63-5a47-811c-dc6825835081', '79506cab-4962-5f03-98ff-3d51d327d1cd', 'EXCELLENT',
   'Salut Lucie, petite mauvaise nouvelle : le musée est fermé samedi. Je te propose qu''on se retrouve plutôt au café de la place, à 14 h. Confirme-moi et je réserve une table. À samedi !',
   'Les phrases s''enchaînent sans effort et la fin appelle une réponse.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S2 / INSUFFICIENT
  ('8d535c08-13af-5f4c-a435-3e9995a452ec', 'cced9b3d-a961-5bc7-80cc-f197bdd960e4', 'INSUFFICIENT',
   'Bonjour Sarah, la réunion de jeudi est annulée. Merci.',
   'La nouvelle date manque et la clôture est trop brève pour informer.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S2 / EXPECTED
  ('1a745781-7324-5db1-8a4a-d1b5db7fa999', 'cced9b3d-a961-5bc7-80cc-f197bdd960e4', 'EXPECTED',
   'Bonjour Sarah, la réunion de jeudi est reportée. Elle aura lieu lundi 15 à 10 h dans la salle 2. Bonne journée à toi.',
   'Les trois éléments s''enchaînent et le message se termine correctement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S2 / EXCELLENT
  ('86e90aaa-b888-50b7-ac15-b39d53acd4fb', 'cced9b3d-a961-5bc7-80cc-f197bdd960e4', 'EXCELLENT',
   'Bonjour Sarah, la réunion de jeudi ne peut pas se tenir, faute de salle disponible. Elle est donc reportée au lundi 15 à 10 h, en salle 2. Merci de prévenir Karim, et bonne journée !',
   '« Donc » relie les phrases et la fin distribue une consigne utile.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S3 / INSUFFICIENT
  ('e4f66696-4e24-531c-9728-840dc8a8af26', '0d0be427-d189-5dea-80ff-b80773cd895a', 'INSUFFICIENT',
   'Bonjour Monsieur, le chauffage ne marche plus. Il fait froid. Deux jours. Merci.',
   'Les informations sont posées sans lien et la clôture reste très sèche.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S3 / EXPECTED
  ('9cca7cfb-fca1-5b6a-ba25-4f6750e0d004', '0d0be427-d189-5dea-80ff-b80773cd895a', 'EXPECTED',
   'Bonjour Monsieur, le chauffage ne fonctionne plus depuis mardi, donc l''appartement est très froid le matin. J''ai essayé de le rallumer, mais rien ne change. Pouvez-vous appeler un technicien ? Cordialement, Yasmine.',
   '« Donc » et « mais » relient les phrases, et la clôture est correcte.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S3 / EXCELLENT
  ('226b1e34-1e5f-52b0-8f0a-26a13f71176f', '0d0be427-d189-5dea-80ff-b80773cd895a', 'EXCELLENT',
   'Bonjour Monsieur Aubert, le chauffage ne fonctionne plus depuis mardi soir, et la température ne dépasse pas 15 degrés le matin. J''ai vérifié le thermostat, mais l''appareil ne redémarre pas. Pourriez-vous faire intervenir un technicien cette semaine ? Je vous remercie. Cordialement, Yasmine Belkacem.',
   'Les liens logiques guident la lecture jusqu''à la demande et à la signature.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S4 / INSUFFICIENT
  ('1795859d-b83a-5aa3-be69-fda8ecbb5dee', '8b75e658-6277-5c8e-b395-1a12e87770e0', 'INSUFFICIENT',
   'Madame, Monsieur, je voudrais un autre rendez-vous. Lundi je travaille. Mon dossier est le 774512. Voilà.',
   'Les informations arrivent dans le désordre et la fin manque de clôture.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S4 / EXPECTED
  ('8d16b7f6-91bf-5084-bf28-b63f7584e24c', '8b75e658-6277-5c8e-b395-1a12e87770e0', 'EXPECTED',
   'Madame, Monsieur, j''ai un rendez-vous lundi 9 juin à 14 h pour mon dossier 774512. Je ne pourrai pas m''y rendre car je travaille ce jour-là. Pourriez-vous me proposer une autre date ? Cordialement, Boubacar Diarra.',
   'L''ordre est logique : rappel, empêchement, demande, puis clôture.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S4 / EXCELLENT
  ('ae22a77e-dd7a-5bc9-93fb-fc2e9dff26f9', '8b75e658-6277-5c8e-b395-1a12e87770e0', 'EXCELLENT',
   'Madame, Monsieur, j''ai rendez-vous le lundi 9 juin à 14 h pour mon dossier n° 774512. Je ne pourrai malheureusement pas m''y présenter, car je travaille ce jour-là jusqu''à 18 h. Pourriez-vous me proposer une autre date, de préférence un mercredi ? Je vous remercie par avance. Cordialement, Boubacar Diarra.',
   'Chaque phrase prépare la suivante et la clôture referme le message.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S5 / INSUFFICIENT
  ('e84279f1-7869-56c1-922a-6876e1807890', '18952468-9342-5bef-9312-55315ef5b828', 'INSUFFICIENT',
   'Bonjour, je dois arrêter la natation trois mois. Est-ce que je peux revenir après ? Merci.',
   'Le message va trop vite : pas d''explication, pas de vraie clôture.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S5 / EXPECTED
  ('5b72404e-4632-580d-913d-1d6cc42bac75', '18952468-9342-5bef-9312-55315ef5b828', 'EXPECTED',
   'Bonjour Monsieur, je vous informe que je dois interrompre la natation pendant trois mois. Mon médecin m''a interdit le sport après une opération de l''épaule. Est-il possible de suspendre mon inscription et de la reprendre en septembre ? Merci et bonne journée.',
   'Les quatre informations se suivent et le message se ferme correctement.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02'),
  -- EE1-C8-S5 / EXCELLENT
  ('67531497-f238-5fd0-a7cc-9e2c9f912867', '18952468-9342-5bef-9312-55315ef5b828', 'EXCELLENT',
   'Bonjour Monsieur Roussel, je dois malheureusement interrompre la natation pendant trois mois. Mon médecin m''a interdit le sport à la suite d''une opération de l''épaule, et la reprise est prévue en septembre. Pourriez-vous me dire s''il est possible de suspendre mon inscription plutôt que de l''annuler ? Je vous remercie. Cordialement, Elena Marku.',
   'Le message avance étape par étape et se termine par une clôture soignée.', '2026-08-06 09:00:00+02', '2026-08-06 09:00:00+02');
