-- ============================================================================
-- V309 — Competences TCF : guidage de saisie, tache EO1
--
-- Renseigne le guidage des 40 petits sujets de « Entretien dirige : parler de soi » :
--   checklist        ce qu'il faut faire, en 2 a 4 gestes a l'imperatif
--   constraint_tags  1 a 3 etiquettes {label, icon} — le COMMENT, jamais
--                    la longueur ni la duree (le front les rend depuis les
--                    bornes deja en base ; les dupliquer les ferait diverger)
--   answer_starter   l'amorce grisee du champ de reponse
--   tip              l'astuce affichee sous la zone de production
--
-- Colonnes ajoutees par V026. UPDATE et non INSERT : les lignes existent
-- deja (V303), et cette migration-la est deja appliquee — la
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
  -- EO1-C1-S1
  ('EO1-C1-S1',
   '["Dites votre prénom", "Dites ce que vous faites", "Nommez votre ville"]',
   '[{"label": "Trois informations", "icon": "NUMBER"}, {"label": "Réponse directe", "icon": "STRUCTURE"}]',
   'Bonjour, je m''appelle Sofia et je…',
   'les trois informations comptent autant : ne vous arrêtez pas au prénom.'),
  -- EO1-C1-S2
  ('EO1-C1-S2',
   '["Donnez votre prénom", "Dites votre occupation", "Expliquez pourquoi vous venez"]',
   '[{"label": "Trois informations", "icon": "NUMBER"}, {"label": "Une raison", "icon": "EXAMPLE"}]',
   'Bonjour à tous, je m''appelle…',
   'terminez par la raison de votre venue : c''est elle qu''on oublie souvent.'),
  -- EO1-C1-S3
  ('EO1-C1-S3',
   '["Dites votre prénom", "Nommez votre poste", "Citez une expérience passée"]',
   '[{"label": "Trois informations", "icon": "NUMBER"}, {"label": "Expérience passée", "icon": "TENSE"}]',
   'Bonjour, moi c''est Elena, je commence…',
   'une expérience courte suffit : deux ans dans un bureau, par exemple.'),
  -- EO1-C1-S4
  ('EO1-C1-S4',
   '["Dites votre prénom", "Précisez votre situation actuelle", "Dites depuis quand vous habitez ici"]',
   '[{"label": "Trois informations", "icon": "NUMBER"}, {"label": "Durée précise", "icon": "TIME"}]',
   'Bonjour, je m''appelle Diego, je suis…',
   'donnez une durée chiffrée : un an, six mois, plutôt que longtemps.'),
  -- EO1-C1-S5
  ('EO1-C1-S5',
   '["Dites votre prénom", "Nommez votre formation", "Résumez votre expérience", "Dites ce que vous cherchez"]',
   '[{"label": "Quatre informations", "icon": "NUMBER"}, {"label": "Objectif clair", "icon": "STRUCTURE"}]',
   'Bonjour, je m''appelle Fatou et je suis…',
   'finissez par votre objectif : c''est ce que la responsable retiendra.'),
  -- EO1-C2-S1
  ('EO1-C2-S1',
   '["Répondez par oui ou non", "Expliquez brièvement pourquoi"]',
   '[{"label": "Réponse directe", "icon": "STRUCTURE"}, {"label": "Une raison", "icon": "EXAMPLE"}]',
   'Oui, j''aime bien mon quartier parce que…',
   'commencez par oui ou non, la raison vient juste après.'),
  -- EO1-C2-S2
  ('EO1-C2-S2',
   '["Répondez par oui ou non", "Nommez le sport ou la raison"]',
   '[{"label": "Réponse personnelle", "icon": "PERSON"}, {"label": "Une précision", "icon": "EXAMPLE"}]',
   'Oui, je fais du sport, surtout…',
   'parlez de vous, pas du sport en général : la question est personnelle.'),
  -- EO1-C2-S3
  ('EO1-C2-S3',
   '["Annoncez votre choix", "Justifiez-le en une phrase"]',
   '[{"label": "Choix net", "icon": "STRUCTURE"}, {"label": "Une justification", "icon": "EXAMPLE"}]',
   'Je préfère cuisiner chez moi, parce que…',
   'choisissez une option, même si les deux vous plaisent : un choix net rassure.'),
  -- EO1-C2-S4
  ('EO1-C2-S4',
   '["Répondez par oui ou non", "Dites comment vous vous déplacez"]',
   '[{"label": "Réponse personnelle", "icon": "PERSON"}, {"label": "Un exemple concret", "icon": "EXAMPLE"}]',
   'Oui, je prends les transports pour…',
   'décrivez vos trajets à vous, pas ceux de toute la ville.'),
  -- EO1-C2-S5
  ('EO1-C2-S5',
   '["Dites clairement si cela vous plaît", "Donnez deux éléments d''explication"]',
   '[{"label": "Position claire", "icon": "STRUCTURE"}, {"label": "Deux éléments", "icon": "NUMBER"}]',
   'Oui, mon travail me plaît, surtout…',
   'décrire votre poste ne suffit pas : donnez d''abord votre avis.'),
  -- EO1-C3-S1
  ('EO1-C3-S1',
   '["Nommez une activité", "Ajoutez quand, où ou avec qui"]',
   '[{"label": "Une précision", "icon": "EXAMPLE"}, {"label": "Moment ou lieu", "icon": "TIME"}]',
   'Le week-end, j''aime surtout…',
   'une activité seule reste vague : ajoutez le moment ou le lieu.'),
  -- EO1-C3-S2
  ('EO1-C3-S2',
   '["Nommez un plat", "Ajoutez une précision utile"]',
   '[{"label": "Une précision", "icon": "EXAMPLE"}, {"label": "Quand ou pourquoi", "icon": "TIME"}]',
   'J''aime beaucoup le poisson, surtout…',
   'dites quand vous le mangez ou avec qui : la réponse devient vivante.'),
  -- EO1-C3-S3
  ('EO1-C3-S3',
   '["Nommez votre moyen de transport", "Ajoutez la durée ou l''horaire"]',
   '[{"label": "Durée ou horaire", "icon": "TIME"}, {"label": "Une précision", "icon": "EXAMPLE"}]',
   'Pour aller au travail, je prends…',
   'un chiffre aide beaucoup : vingt minutes, sept heures et demie.'),
  -- EO1-C3-S4
  ('EO1-C3-S4',
   '["Nommez l''endroit", "Ajoutez quand ou à quelle fréquence"]',
   '[{"label": "Lieu nommé", "icon": "PLACE"}, {"label": "Une précision", "icon": "EXAMPLE"}]',
   'Je fais mes courses au…',
   'le nom du lieu ne suffit pas : dites aussi quand vous y allez.'),
  -- EO1-C3-S5
  ('EO1-C3-S5',
   '["Dites ce que vous apprenez", "Donnez une première précision", "Ajoutez-en une deuxième"]',
   '[{"label": "Deux précisions", "icon": "NUMBER"}, {"label": "Depuis quand", "icon": "TIME"}]',
   'Oui, en ce moment j''apprends…',
   'deux précisions valent mieux qu''une : depuis quand, et où par exemple.'),
  -- EO1-C4-S1
  ('EO1-C4-S1',
   '["Commencez par votre réveil", "Enchaînez trois actions", "Utilisez d''abord, ensuite, après"]',
   '[{"label": "Trois actions", "icon": "NUMBER"}, {"label": "Ordre chronologique", "icon": "STRUCTURE"}]',
   'Le matin, je me lève vers…',
   'les mots d''ordre guident votre auditeur : d''abord, ensuite, puis, après.'),
  -- EO1-C4-S2
  ('EO1-C4-S2',
   '["Dites à quelle heure vous rentrez", "Citez trois habitudes du soir", "Reliez-les avec puis ou ensuite"]',
   '[{"label": "Trois habitudes", "icon": "NUMBER"}, {"label": "Enchaînement", "icon": "STRUCTURE"}]',
   'Le soir, quand je rentre, je…',
   'racontez des actions, pas seulement votre fatigue de fin de journée.'),
  -- EO1-C4-S3
  ('EO1-C4-S3',
   '["Commencez par le matin", "Continuez avec l''après-midi", "Terminez par la soirée"]',
   '[{"label": "Matin, après-midi, soir", "icon": "TIME"}, {"label": "Trois moments", "icon": "NUMBER"}]',
   'Le dimanche, je me lève…',
   'découpez la journée en trois moments : c''est plus facile à suivre.'),
  -- EO1-C4-S4
  ('EO1-C4-S4',
   '["Nommez vos jours de travail", "Donnez vos horaires", "Suivez l''ordre de la semaine"]',
   '[{"label": "Jours et horaires", "icon": "TIME"}, {"label": "Semaine ordonnée", "icon": "STRUCTURE"}]',
   'Je travaille du lundi au…',
   'des jours et des heures précis valent mieux que beaucoup ou fatigant.'),
  -- EO1-C4-S5
  ('EO1-C4-S5',
   '["Situez la journée", "Enchaînez cinq activités", "Marquez chaque moment", "Dites comment vous vous organisez"]',
   '[{"label": "Cinq activités", "icon": "NUMBER"}, {"label": "Moments marqués", "icon": "TIME"}]',
   'Le mercredi, ma journée commence…',
   'cinq activités, c''est court si chacune tient en une phrase simple.'),
  -- EO1-C5-S1
  ('EO1-C5-S1',
   '["Nommez un commerce ou un lieu", "Ajoutez une deuxième information concrète"]',
   '[{"label": "Deux informations", "icon": "NUMBER"}, {"label": "Détails concrets", "icon": "EXAMPLE"}]',
   'Mon quartier est plutôt calme, et…',
   'remplacez c''est très bien par un lieu, un commerce, un transport.'),
  -- EO1-C5-S2
  ('EO1-C5-S2',
   '["Dites le type de logement", "Ajoutez une deuxième information précise"]',
   '[{"label": "Deux informations", "icon": "NUMBER"}, {"label": "Pièces ou étage", "icon": "PLACE"}]',
   'J''habite dans un appartement de…',
   'confortable ne dit rien : nombre de pièces, étage, balcon, lumière.'),
  -- EO1-C5-S3
  ('EO1-C5-S3',
   '["Dites qui est cette personne", "Donnez deux informations sur elle"]',
   '[{"label": "Personne identifiée", "icon": "PERSON"}, {"label": "Deux informations", "icon": "NUMBER"}]',
   'Je vais vous parler de ma…',
   'gentille reste vague : son métier, sa ville, ce que vous partagez.'),
  -- EO1-C5-S4
  ('EO1-C5-S4',
   '["Dites où vous travaillez", "Donnez trois informations concrètes", "Parlez de l''équipe ou des horaires"]',
   '[{"label": "Trois informations", "icon": "NUMBER"}, {"label": "Faits, pas impressions", "icon": "EXAMPLE"}]',
   'Je travaille dans un magasin de…',
   'les gens sont sympas ne compte pas : donnez des faits observables.'),
  -- EO1-C5-S5
  ('EO1-C5-S5',
   '["Donnez trois informations sur votre ville", "Nommez un lieu à découvrir", "Dites pourquoi ce lieu"]',
   '[{"label": "Trois informations", "icon": "NUMBER"}, {"label": "Un lieu proposé", "icon": "PLACE"}]',
   'Ma ville n''est pas très grande…',
   'terminez par votre proposition : où emmèneriez-vous cette personne ?'),
  -- EO1-C6-S1
  ('EO1-C6-S1',
   '["Dites quand c''était", "Racontez deux actions", "Respectez l''ordre des faits"]',
   '[{"label": "Passé composé", "icon": "TENSE"}, {"label": "Moment situé", "icon": "TIME"}]',
   'Samedi dernier, je suis allé…',
   'commencez par la date : samedi dernier, la semaine dernière, hier soir.'),
  -- EO1-C6-S2
  ('EO1-C6-S2',
   '["Dites quand c''était", "Dites avec qui", "Racontez deux moments du repas"]',
   '[{"label": "Passé composé", "icon": "TENSE"}, {"label": "Deux moments", "icon": "NUMBER"}]',
   'Le mois dernier, nous avons fêté…',
   'd''abord, ensuite, après : ces mots suffisent pour raconter dans l''ordre.'),
  -- EO1-C6-S3
  ('EO1-C6-S3',
   '["Dites quand c''était", "Racontez trois étapes", "Suivez l''ordre du rendez-vous"]',
   '[{"label": "Trois étapes", "icon": "NUMBER"}, {"label": "Passé composé", "icon": "TENSE"}]',
   'Il y a deux semaines, j''ai…',
   'pensez à l''avant, au pendant et à l''après : trois étapes naturelles.'),
  -- EO1-C6-S4
  ('EO1-C6-S4',
   '["Dites quand c''était", "Racontez le problème", "Dites comment cela s''est terminé"]',
   '[{"label": "Problème et fin", "icon": "STRUCTURE"}, {"label": "Passé composé", "icon": "TENSE"}]',
   'L''hiver dernier, je suis parti…',
   'un récit a une fin : dites comment la situation s''est résolue.'),
  -- EO1-C6-S5
  ('EO1-C6-S5',
   '["Dites quand c''était", "Racontez trois étapes", "Terminez par votre ressenti"]',
   '[{"label": "Trois étapes", "icon": "NUMBER"}, {"label": "Un ressenti", "icon": "TONE"}, {"label": "Passé composé", "icon": "TENSE"}]',
   'L''année dernière, j''ai commencé dans…',
   'le ressenti se place à la fin : fatiguée mais contente, par exemple.'),
  -- EO1-C7-S1
  ('EO1-C7-S1',
   '["Nommez un projet précis", "Ajoutez une précision", "Utilisez je vais ou je voudrais"]',
   '[{"label": "Futur", "icon": "TENSE"}, {"label": "Une précision", "icon": "EXAMPLE"}]',
   'L''année prochaine, je voudrais…',
   'un projet nommé vaut mieux que changer des choses dans ma vie.'),
  -- EO1-C7-S2
  ('EO1-C7-S2',
   '["Dites ce que vous allez faire", "Ajoutez quand, où ou avec qui"]',
   '[{"label": "Futur proche", "icon": "TENSE"}, {"label": "Une précision", "icon": "EXAMPLE"}]',
   'Cet été, je vais partir…',
   'se reposer n''est pas un projet : dites où, quand, avec qui.'),
  -- EO1-C7-S3
  ('EO1-C7-S3',
   '["Nommez la formation visée", "Donnez une première précision", "Ajoutez-en une deuxième"]',
   '[{"label": "Deux précisions", "icon": "NUMBER"}, {"label": "Quand et où", "icon": "TIME"}]',
   'Oui, je voudrais faire une formation…',
   'nommez le domaine : informatique, comptabilité, aide à la personne.'),
  -- EO1-C7-S4
  ('EO1-C7-S4',
   '["Dites clairement votre intention", "Donnez deux précisions"]',
   '[{"label": "Intention claire", "icon": "STRUCTURE"}, {"label": "Deux précisions", "icon": "NUMBER"}]',
   'Oui, je pense déménager d''ici…',
   'peut-être un jour ne suffit pas : décidez, puis expliquez votre choix.'),
  -- EO1-C7-S5
  ('EO1-C7-S5',
   '["Annoncez votre objectif", "Nommez la première étape", "Nommez la deuxième étape"]',
   '[{"label": "Objectif nommé", "icon": "STRUCTURE"}, {"label": "Deux étapes", "icon": "NUMBER"}]',
   'Dans deux ans, je voudrais travailler…',
   'd''abord et ensuite suffisent pour présenter vos deux étapes clairement.'),
  -- EO1-C8-S1
  ('EO1-C8-S1',
   '["Répondez à la question pourquoi", "Donnez une raison nouvelle", "Évitez de répéter votre phrase"]',
   '[{"label": "Information nouvelle", "icon": "EXAMPLE"}, {"label": "Une raison", "icon": "STRUCTURE"}]',
   'Parce qu''il est calme et que…',
   'une relance attend du nouveau, pas la même phrase reformulée.'),
  -- EO1-C8-S2
  ('EO1-C8-S2',
   '["Dites avec qui vous y allez", "Ajoutez une information nouvelle"]',
   '[{"label": "Les personnes", "icon": "PERSON"}, {"label": "Information nouvelle", "icon": "EXAMPLE"}]',
   'Avec deux amis, on part…',
   'la relance porte sur les personnes : nommez-les avant tout le reste.'),
  -- EO1-C8-S3
  ('EO1-C8-S3',
   '["Donnez une durée précise", "Ajoutez une information nouvelle"]',
   '[{"label": "Durée précise", "icon": "TIME"}, {"label": "Information nouvelle", "icon": "EXAMPLE"}]',
   'Depuis deux ans environ, et…',
   'un chiffre répond mieux que depuis un moment ou un certain temps.'),
  -- EO1-C8-S4
  ('EO1-C8-S4',
   '["Répondez clairement à la relance", "Donnez deux éléments nouveaux"]',
   '[{"label": "Réponse directe", "icon": "STRUCTURE"}, {"label": "Deux éléments", "icon": "NUMBER"}]',
   'C''est un peu difficile, surtout…',
   'dites oui ou non, puis expliquez avec deux détails concrets.'),
  -- EO1-C8-S5
  ('EO1-C8-S5',
   '["Prenez position clairement", "Justifiez votre conseil", "Dites à qui vous le conseillez"]',
   '[{"label": "Position claire", "icon": "STRUCTURE"}, {"label": "Un destinataire", "icon": "PERSON"}, {"label": "Une justification", "icon": "EXAMPLE"}]',
   'Oui, je le conseillerais surtout à…',
   'précisez à qui s''adresse votre conseil : c''est la partie souvent oubliée.')
) AS v(code, checklist, constraint_tags, answer_starter, tip)
WHERE p.code = v.code;
