-- ============================================================================
-- V306 — Competences TCF : guidage de saisie, tache EE1
--
-- Renseigne le guidage des 40 petits sujets de « Ecrire un message court » :
--   checklist        ce qu'il faut faire, en 2 a 4 gestes a l'imperatif
--   constraint_tags  1 a 3 etiquettes {label, icon} — le COMMENT, jamais
--                    la longueur ni la duree (le front les rend depuis les
--                    bornes deja en base ; les dupliquer les ferait diverger)
--   answer_starter   l'amorce grisee du champ de reponse
--   tip              l'astuce affichee sous la zone de production
--
-- Colonnes ajoutees par V026. UPDATE et non INSERT : les lignes existent
-- deja (V300), et cette migration-la est deja appliquee — la
-- rejouer invaliderait sa somme de controle Flyway.
--
-- FICHIER GENERE — NE PAS EDITER A LA MAIN.
--   cd backend_sejourfr && python3 tools/competences/generer_seed.py
-- ============================================================================

UPDATE skill_prompts p SET
    checklist       = v.checklist::jsonb,
    constraint_tags = v.constraint_tags::jsonb,
    answer_starter  = v.answer_starter,
    tip             = v.tip,
    updated_at      = '2026-08-06 09:00:00+02'
FROM (VALUES
  -- EE1-C1-S1
  ('EE1-C1-S1',
   '["Saluez votre voisine", "Dites qui vous êtes", "Écrivez deux phrases"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Ton poli", "icon": "TONE"}]',
   'Bonjour Madame, je suis votre voisin du…',
   'commencez par bonjour, puis présentez-vous en quelques mots'),
  -- EE1-C1-S2
  ('EE1-C1-S2',
   '["Ouvrez avec un bonjour amical", "Proposez le cinéma ce week-end", "Tutoyez-la jusqu''à la fin"]',
   '[{"label": "Tutoiement", "icon": "PERSON"}, {"label": "Ton amical", "icon": "TONE"}]',
   'Salut Sofia, bravo pour ces examens…',
   'gardez le même tutoiement de la première à la dernière ligne'),
  -- EE1-C1-S3
  ('EE1-C1-S3',
   '["Ouvrez par Bonjour Monsieur", "Présentez-vous comme locataire", "Annoncez la fuite", "Vouvoyez tout le message"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Formule d''appel", "icon": "TONE"}]',
   'Bonjour Monsieur, je suis votre locataire…',
   'une formule d''appel formelle vaut mieux qu''un simple salut'),
  -- EE1-C1-S4
  ('EE1-C1-S4',
   '["Commencez par Madame, Monsieur", "Exposez le problème de connexion", "Terminez par une formule de clôture"]',
   '[{"label": "Ton formel", "icon": "TONE"}, {"label": "Ouverture et clôture", "icon": "STRUCTURE"}]',
   'Madame, Monsieur, ma connexion internet ne…',
   'la signature ferme le message aussi sûrement que la formule d''appel l''ouvre'),
  -- EE1-C1-S5
  ('EE1-C1-S5',
   '["Saluez Madame Fontaine", "Exposez votre demande de planning", "Vouvoyez du début à la fin", "Signez votre message"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Ton professionnel", "icon": "TONE"}]',
   'Bonjour Madame Fontaine, je vous écris…',
   'une fin familière efface un début professionnel, restez constant jusqu''à la signature'),
  -- EE1-C2-S1
  ('EE1-C2-S1',
   '["Saluez le cabinet dentaire", "Annoncez l''annulation dès le début", "Écrivez une seule phrase"]',
   '[{"label": "Objet en premier", "icon": "STRUCTURE"}, {"label": "Ton poli", "icon": "TONE"}]',
   'Bonjour, je vous écris au sujet…',
   'dites l''essentiel avant d''expliquer, votre lecteur comprend immédiatement'),
  -- EE1-C2-S2
  ('EE1-C2-S2',
   '["Ouvrez par un bonjour", "Remerciez-la dès la première phrase", "Précisez pourquoi vous la remerciez"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Merci en ouverture", "icon": "STRUCTURE"}]',
   'Bonjour Madame Diaz, je vous écris…',
   'placez le merci avant vos nouvelles du voyage'),
  -- EE1-C2-S3
  ('EE1-C2-S3',
   '["Adressez-vous à toute l''équipe", "Annoncez d''emblée le report", "Précisez le nouveau jour"]',
   '[{"label": "Information en tête", "icon": "STRUCTURE"}, {"label": "Ton professionnel", "icon": "TONE"}]',
   'Bonjour à tous, la réunion d''équipe…',
   'commencez par ce qui change, les détails viennent juste après'),
  -- EE1-C2-S4
  ('EE1-C2-S4',
   '["Ouvrez par une salutation", "Dites que vous demandez des informations", "Posez ensuite vos questions"]',
   '[{"label": "But d''abord", "icon": "STRUCTURE"}, {"label": "Ton formel", "icon": "TONE"}]',
   'Bonjour, je souhaite m''inscrire à votre…',
   'annoncez votre but avant de raconter votre parcours personnel'),
  -- EE1-C2-S5
  ('EE1-C2-S5',
   '["Ouvrez par Madame, Monsieur", "Demandez le remboursement dès le début", "Racontez ensuite l''annulation"]',
   '[{"label": "Demande en tête", "icon": "STRUCTURE"}, {"label": "Ton posé", "icon": "TONE"}]',
   'Madame, Monsieur, je vous écris au…',
   'votre demande d''abord, votre histoire ensuite, le lecteur suivra bien mieux'),
  -- EE1-C3-S1
  ('EE1-C3-S1',
   '["Annoncez la fête de samedi", "Donnez l''adresse exacte", "Indiquez l''heure de début"]',
   '[{"label": "Tutoiement", "icon": "PERSON"}, {"label": "Lieu précis", "icon": "PLACE"}, {"label": "Heure précise", "icon": "TIME"}]',
   'Salut Mehdi, je fête mon anniversaire…',
   'sans adresse ni heure, votre invité ne peut pas venir'),
  -- EE1-C3-S2
  ('EE1-C3-S2',
   '["Donnez votre heure d''arrivée exacte", "Fixez un point de rendez-vous précis"]',
   '[{"label": "Tutoiement", "icon": "PERSON"}, {"label": "Heure exacte", "icon": "TIME"}, {"label": "Repère précis", "icon": "PLACE"}]',
   'Coucou, j''arrive demain à Bordeaux en…',
   'écrivez 14 h 20 plutôt que dans l''après-midi'),
  -- EE1-C3-S3
  ('EE1-C3-S3',
   '["Écrivez votre adresse complète", "Indiquez le code d''entrée", "Précisez l''étage"]',
   '[{"label": "Trois informations", "icon": "NUMBER"}, {"label": "Tutoiement", "icon": "PERSON"}]',
   'Coucou, voici comment arriver chez moi…',
   'un seul détail oublié et votre amie devra vous appeler'),
  -- EE1-C3-S4
  ('EE1-C3-S4',
   '["Rappelez la date du rendez-vous", "Indiquez l''heure exacte", "Listez les documents à apporter"]',
   '[{"label": "Tutoiement", "icon": "PERSON"}, {"label": "Date et heure", "icon": "TIME"}, {"label": "Liste de documents", "icon": "STRUCTURE"}]',
   'Le rendez-vous à la préfecture est…',
   'nommez chaque document plutôt que d''écrire simplement tes papiers'),
  -- EE1-C3-S5
  ('EE1-C3-S5',
   '["Annoncez le jour et l''heure", "Précisez le lieu de livraison", "Nommez la personne à contacter"]',
   '[{"label": "Quatre informations", "icon": "NUMBER"}, {"label": "Ton professionnel", "icon": "TONE"}]',
   'Bonjour à tous, une livraison importante…',
   'vérifiez que chacun sait où, quand et avec qui se présenter'),
  -- EE1-C4-S1
  ('EE1-C4-S1',
   '["Saluez votre voisin", "Expliquez que vous attendez un colis", "Formulez la demande poliment"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Forme polie", "icon": "TONE"}]',
   'Bonjour, je reçois un colis demain…',
   'remplacez l''impératif par pourriez-vous, votre voisin se sentira libre d''accepter'),
  -- EE1-C4-S2
  ('EE1-C4-S2',
   '["Rappelez votre absence de lundi", "Demandez le document au conditionnel"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Conditionnel", "icon": "TENSE"}]',
   'Bonjour Madame, j''étais absent au cours…',
   'pourriez-vous et serait-il possible adoucissent n''importe quelle demande'),
  -- EE1-C4-S3
  ('EE1-C4-S3',
   '["Expliquez votre contrainte du matin", "Demandez le changement poliment", "Laissez la porte ouverte au refus"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Demande, pas décision", "icon": "TONE"}]',
   'Bonjour Madame, pendant deux semaines je…',
   'une question laisse le choix, une annonce le retire'),
  -- EE1-C4-S4
  ('EE1-C4-S4',
   '["Rappelez votre consultation", "Demandez l''attestation poliment", "Remerciez à la fin"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Remerciement final", "icon": "TONE"}]',
   'Bonjour, j''ai consulté le docteur Silva…',
   'un remerciement final coûte trois secondes et change le ton'),
  -- EE1-C4-S5
  ('EE1-C4-S5',
   '["Exposez votre besoin de rendez-vous", "Demandez une date poliment", "Évitez les excuses répétées"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Poli et direct", "icon": "TONE"}]',
   'Madame, Monsieur, je souhaite déposer un…',
   'trop d''excuses repoussent la demande, allez-y simplement et poliment'),
  -- EE1-C5-S1
  ('EE1-C5-S1',
   '["Nommez l''activité prévue", "Précisez le jour", "Formulez clairement l''invitation"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Jour précis", "icon": "TIME"}]',
   'Bonjour, les habitants de l''immeuble organisent…',
   'dites clairement quoi et quand, sinon ce n''est pas une invitation'),
  -- EE1-C5-S2
  ('EE1-C5-S2',
   '["Dites clairement que vous refusez", "Évitez le peut-être"]',
   '[{"label": "Tutoiement", "icon": "PERSON"}, {"label": "Réponse nette", "icon": "TONE"}]',
   'Salut Thomas, merci pour ta proposition…',
   'un on verra bien laisse votre ami dans le doute'),
  -- EE1-C5-S3
  ('EE1-C5-S3',
   '["Dites clairement que vous acceptez", "Confirmez votre jour et le sien"]',
   '[{"label": "Accord explicite", "icon": "TONE"}, {"label": "Deux jours confirmés", "icon": "NUMBER"}]',
   'Bonjour Awa, merci pour ta proposition…',
   'ça m''arrangerait n''est pas encore un oui, écrivez-le franchement'),
  -- EE1-C5-S4
  ('EE1-C5-S4',
   '["Proposez une séance de révision", "Offrez deux moments possibles"]',
   '[{"label": "Tutoiement", "icon": "PERSON"}, {"label": "Deux créneaux", "icon": "NUMBER"}]',
   'Salut Ana, l''examen approche et je…',
   'deux options valent mieux qu''une, votre camarade choisit plus vite'),
  -- EE1-C5-S5
  ('EE1-C5-S5',
   '["Refusez clairement pour vendredi soir", "Proposez une autre solution"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Refus puis solution", "icon": "STRUCTURE"}]',
   'Bonjour Madame, merci de penser à…',
   'un non clair suivi d''une solution reste un message aidant'),
  -- EE1-C6-S1
  ('EE1-C6-S1',
   '["Prévenez Camille de votre retard", "Présentez vos excuses", "Donnez la raison"]',
   '[{"label": "Tutoiement", "icon": "PERSON"}, {"label": "Excuse et raison", "icon": "STRUCTURE"}]',
   'Salut Camille, petit contretemps ce soir…',
   'une excuse sans raison laisse toujours une question en suspens'),
  -- EE1-C6-S2
  ('EE1-C6-S2',
   '["Excusez-vous pour le retard", "Expliquez la raison de l''oubli"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Excuse puis cause", "icon": "STRUCTURE"}]',
   'Bonjour, je devais rapporter un livre…',
   'annoncer votre passage ne remplace pas les excuses attendues'),
  -- EE1-C6-S3
  ('EE1-C6-S3',
   '["Présentez vos excuses au responsable", "Donnez une raison précise"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Raison précise", "icon": "EXAMPLE"}]',
   'Bonjour Monsieur, au sujet de mon…',
   'je n''ai pas pu venir n''explique toujours pas pourquoi'),
  -- EE1-C6-S4
  ('EE1-C6-S4',
   '["Excusez-vous pour le bruit", "Expliquez la cause en une phrase"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Explication courte", "icon": "STRUCTURE"}]',
   'Bonjour Madame, au sujet de samedi…',
   'une cause en une phrase vaut mieux qu''une longue justification'),
  -- EE1-C6-S5
  ('EE1-C6-S5',
   '["Présentez vos excuses pour son absence", "Expliquez clairement la raison"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Excuse et raison", "icon": "STRUCTURE"}]',
   'Bonjour Madame, je vous écris au…',
   'signaler l''absence ne suffit pas, excusez-la et expliquez-la'),
  -- EE1-C7-S1
  ('EE1-C7-S1',
   '["Annoncez que le studio se libère", "Donnez deux caractéristiques concrètes"]',
   '[{"label": "Tutoiement", "icon": "PERSON"}, {"label": "Détails concrets", "icon": "EXAMPLE"}]',
   'Salut, mon studio se libère le…',
   'très bien ne décrit rien, préférez une surface ou un loyer'),
  -- EE1-C7-S2
  ('EE1-C7-S2',
   '["Annoncez la venue de votre belle-sœur", "Donnez son nom", "Décrivez deux détails reconnaissables"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Détails reconnaissables", "icon": "EXAMPLE"}]',
   'Bonjour, ma belle-sœur viendra chercher les…',
   'imaginez la personne qui l''attend, que doit-elle repérer d''un coup d''œil'),
  -- EE1-C7-S3
  ('EE1-C7-S3',
   '["Signalez l''oubli dans le bus", "Donnez la couleur et la taille", "Décrivez le contenu du sac"]',
   '[{"label": "Trois précisions", "icon": "NUMBER"}, {"label": "Vouvoiement", "icon": "PERSON"}]',
   'Bonjour, j''ai oublié mon sac dans…',
   'un détail unique, comme une fermeture cassée, fait toute la différence'),
  -- EE1-C7-S4
  ('EE1-C7-S4',
   '["Choisissez trois caractéristiques du quartier", "Restez concret et utile"]',
   '[{"label": "Tutoiement", "icon": "PERSON"}, {"label": "Trois caractéristiques", "icon": "NUMBER"}]',
   'Salut, mon quartier pourrait bien te…',
   'agréable reste un avis, le tramway à cinq minutes est une information'),
  -- EE1-C7-S5
  ('EE1-C7-S5',
   '["Racontez précisément le vol", "Décrivez le vélo en détail"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Description précise", "icon": "EXAMPLE"}, {"label": "Ton formel", "icon": "TONE"}]',
   'Madame, Monsieur, je déclare le vol…',
   'écrivez comme si votre assureur ne verra jamais aucune photo'),
  -- EE1-C8-S1
  ('EE1-C8-S1',
   '["Annoncez le changement", "Donnez le nouveau lieu", "Terminez par une formule finale"]',
   '[{"label": "Tutoiement", "icon": "PERSON"}, {"label": "Trois phrases", "icon": "STRUCTURE"}]',
   'Salut Lucie, petite nouvelle pour samedi…',
   'une annonce sans nouveau lieu laisse votre amie sans solution'),
  -- EE1-C8-S2
  ('EE1-C8-S2',
   '["Annoncez le report", "Donnez la nouvelle date", "Terminez par une phrase polie"]',
   '[{"label": "Trois phrases", "icon": "STRUCTURE"}, {"label": "Clôture polie", "icon": "TONE"}]',
   'Bonjour Sarah, la réunion de jeudi…',
   'une réunion reportée sans nouvelle date laisse toute l''équipe bloquée'),
  -- EE1-C8-S3
  ('EE1-C8-S3',
   '["Annoncez la panne de chauffage", "Ajoutez une précision utile", "Reliez vos phrases par un connecteur", "Terminez par une formule de clôture"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Connecteurs", "icon": "STRUCTURE"}]',
   'Bonjour Monsieur, le chauffage ne fonctionne…',
   'donc, mais et car suffisent à relier vos phrases entre elles'),
  -- EE1-C8-S4
  ('EE1-C8-S4',
   '["Rappelez le rendez-vous prévu", "Expliquez votre empêchement", "Demandez une autre date", "Terminez par une formule de clôture"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Ordre logique", "icon": "STRUCTURE"}]',
   'Madame, Monsieur, j''ai un rendez-vous lundi…',
   'rappelez le rendez-vous avant d''expliquer, votre lecteur suivra sans effort'),
  -- EE1-C8-S5
  ('EE1-C8-S5',
   '["Annoncez votre interruption", "Expliquez la raison de santé", "Posez votre question au responsable", "Terminez par une formule adaptée"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Quatre étapes", "icon": "STRUCTURE"}]',
   'Bonjour Monsieur, je dois malheureusement interrompre…',
   'avancez étape par étape, chaque phrase prépare la suivante')
) AS v(code, checklist, constraint_tags, answer_starter, tip)
WHERE p.code = v.code;
