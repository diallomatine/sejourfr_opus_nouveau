-- ============================================================================
-- V307 — Competences TCF : guidage de saisie, tache EE2
--
-- Renseigne le guidage des 40 petits sujets de « Raconter une experience » :
--   checklist        ce qu'il faut faire, en 2 a 4 gestes a l'imperatif
--   constraint_tags  1 a 3 etiquettes {label, icon} — le COMMENT, jamais
--                    la longueur ni la duree (le front les rend depuis les
--                    bornes deja en base ; les dupliquer les ferait diverger)
--   answer_starter   l'amorce grisee du champ de reponse
--   tip              l'astuce affichee sous la zone de production
--
-- Colonnes ajoutees par V026. UPDATE et non INSERT : les lignes existent
-- deja (V301), et cette migration-la est deja appliquee — la
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
  -- EE2-C1-S1
  ('EE2-C1-S1',
   '["Nommez le jour de la sortie", "Précisez où vous étiez", "Écrivez une seule phrase"]',
   '[{"label": "Repère de temps", "icon": "TIME"}, {"label": "Lieu précis", "icon": "PLACE"}]',
   'Samedi dernier, je suis allé…',
   'Un jour nommé vaut mieux qu''un vague « récemment » : soyez précis.'),
  -- EE2-C1-S2
  ('EE2-C1-S2',
   '["Indiquez la période exactement", "Nommez votre lieu de travail", "Écrivez une phrase d''ouverture"]',
   '[{"label": "Période datée", "icon": "TIME"}, {"label": "Lieu de travail", "icon": "PLACE"}]',
   'Le mois dernier, j''ai commencé…',
   'Le nom de la ville ou du commerce ancre tout de suite votre récit.'),
  -- EE2-C1-S3
  ('EE2-C1-S3',
   '["Donnez le jour", "Ajoutez l''heure d''arrivée", "Nommez la préfecture concernée", "Écrivez deux phrases"]',
   '[{"label": "Jour et heure", "icon": "TIME"}, {"label": "Lieu identifiable", "icon": "PLACE"}]',
   'Mardi dernier, j''avais rendez-vous…',
   'Une heure précise vaut mieux que « le matin » pour situer la scène.'),
  -- EE2-C1-S4
  ('EE2-C1-S4',
   '["Situez le jour et l''heure", "Nommez la gare", "Écrivez deux phrases"]',
   '[{"label": "Jour précisé", "icon": "TIME"}, {"label": "Gare nommée", "icon": "PLACE"}]',
   'Jeudi dernier, à sept heures…',
   'Nommez la gare et le quai : le lecteur voit immédiatement où vous êtes.'),
  -- EE2-C1-S5
  ('EE2-C1-S5',
   '["Datez le jour de l''emménagement", "Situez la ville ou l''adresse", "Reliez-les à votre action"]',
   '[{"label": "Date et heure", "icon": "TIME"}, {"label": "Adresse ou ville", "icon": "PLACE"}, {"label": "Action en cours", "icon": "STRUCTURE"}]',
   'Début juin, j''ai emménagé à…',
   'Enchaînez tout de suite sur ce que vous faisiez : le décor sert l''action.'),
  -- EE2-C2-S1
  ('EE2-C2-S1',
   '["Dites où vous étiez", "Nommez les personnes présentes", "Décrivez votre activité", "Écrivez deux phrases"]',
   '[{"label": "Lieu de départ", "icon": "PLACE"}, {"label": "Qui est là", "icon": "PERSON"}, {"label": "Imparfait", "icon": "TENSE"}]',
   'J''étais dans la cour avec…',
   'Trois informations suffisent : l''endroit, les personnes, ce que vous faisiez.'),
  -- EE2-C2-S2
  ('EE2-C2-S2',
   '["Placez-vous dans la salle", "Dites avec qui vous êtes", "Racontez ce que vous faisiez"]',
   '[{"label": "Salle et place", "icon": "PLACE"}, {"label": "Autres élèves", "icon": "PERSON"}, {"label": "Avant le cours", "icon": "TIME"}]',
   'J''étais assis dans la salle…',
   'Restez sur ce seul soir : évitez de décrire les cours en général.'),
  -- EE2-C2-S3
  ('EE2-C2-S3',
   '["Situez la salle d''attente", "Dites qui vous accompagne", "Précisez votre occupation", "Arrêtez-vous avant la consultation"]',
   '[{"label": "Lieu d''attente", "icon": "PLACE"}, {"label": "Votre fille", "icon": "PERSON"}, {"label": "Activité en cours", "icon": "STRUCTURE"}]',
   'Dans la salle d''attente, je…',
   'Ne racontez pas encore la consultation : restez sur les minutes d''attente.'),
  -- EE2-C2-S4
  ('EE2-C2-S4',
   '["Décrivez le point de rendez-vous", "Présentez les autres passagers", "Dites ce que vous faisiez", "Écrivez trois phrases"]',
   '[{"label": "Lieu du départ", "icon": "PLACE"}, {"label": "Passagers présents", "icon": "PERSON"}, {"label": "Avant le trajet", "icon": "TIME"}]',
   'Samedi matin, j''attendais devant la gare…',
   'Le décor d''abord : le voyage lui-même n''est pas demandé ici.'),
  -- EE2-C2-S5
  ('EE2-C2-S5',
   '["Posez le lieu de travail", "Nommez votre collègue", "Dites ce que vous faisiez", "Ne racontez pas l''incident"]',
   '[{"label": "Lieu et horaire", "icon": "PLACE"}, {"label": "Collègues présents", "icon": "PERSON"}, {"label": "Imparfait", "icon": "TENSE"}]',
   'Ce vendredi-là, j''étais à la caisse…',
   'Gardez la surprise : l''incident se raconte plus tard, pas dans ces phrases.'),
  -- EE2-C3-S1
  ('EE2-C3-S1',
   '["Choisissez une action terminée", "Écrivez-la au passé composé", "Tenez-vous à une phrase"]',
   '[{"label": "Passé composé", "icon": "TENSE"}, {"label": "Une seule action", "icon": "NUMBER"}]',
   'Samedi matin, au supermarché, je…',
   '« J''ai acheté » plutôt que « j''achète » : l''action est terminée.'),
  -- EE2-C3-S2
  ('EE2-C3-S2',
   '["Choisissez deux faits d''hier", "Mettez chaque verbe au passé", "Écrivez deux phrases"]',
   '[{"label": "Passé composé", "icon": "TENSE"}, {"label": "Deux actions", "icon": "NUMBER"}, {"label": "Hier", "icon": "TIME"}]',
   'Hier, à l''école, mon fils…',
   'Le présent raconterait une habitude : ici, tout s''est passé hier.'),
  -- EE2-C3-S3
  ('EE2-C3-S3',
   '["Décrivez l''attente à l''imparfait", "Introduisez l''action avec « quand »", "Mettez cette action au passé composé"]',
   '[{"label": "Imparfait", "icon": "TENSE"}, {"label": "Passé composé", "icon": "TENSE"}, {"label": "« Quand »", "icon": "STRUCTURE"}]',
   'J''attendais le bus depuis dix minutes…',
   'L''imparfait plante le décor, le passé composé apporte l''événement.'),
  -- EE2-C3-S4
  ('EE2-C3-S4',
   '["Décrivez la scène à l''imparfait", "Racontez la coupure au passé", "Ajoutez vos actions terminées"]',
   '[{"label": "Imparfait", "icon": "TENSE"}, {"label": "Passé composé", "icon": "TENSE"}, {"label": "Le soir", "icon": "TIME"}]',
   'Je préparais le dîner quand…',
   'Ce qui durait va à l''imparfait, ce qui arrive au passé composé.'),
  -- EE2-C3-S5
  ('EE2-C3-S5',
   '["Plantez le décor à l''imparfait", "Racontez vos actions au passé", "Terminez par la fin du rendez-vous"]',
   '[{"label": "Imparfait", "icon": "TENSE"}, {"label": "Passé composé", "icon": "TENSE"}, {"label": "Trois étapes", "icon": "STRUCTURE"}]',
   'La salle était grande et…',
   'Un récit entièrement à l''imparfait n''avance plus : ajoutez des actions terminées.'),
  -- EE2-C4-S1
  ('EE2-C4-S1',
   '["Choisissez le problème exact", "Marquez l''instant avec « soudain »", "Écrivez une seule phrase"]',
   '[{"label": "Rupture nette", "icon": "STRUCTURE"}, {"label": "Passé composé", "icon": "TENSE"}]',
   'Au moment de taper mon code…',
   'Un mot de rupture — soudain, tout à coup — fait basculer le récit.'),
  -- EE2-C4-S2
  ('EE2-C4-S2',
   '["Ouvrez par une expression de rupture", "Nommez l''événement inattendu", "Dites ce qu''il a provoqué"]',
   '[{"label": "Effet de surprise", "icon": "STRUCTURE"}, {"label": "Passé composé", "icon": "TENSE"}]',
   'Nous regardions le match quand…',
   'Placez l''expression de rupture en tête : la surprise se voit aussitôt.'),
  -- EE2-C4-S3
  ('EE2-C4-S3',
   '["Rappelez le calme d''avant", "Marquez l''instant du changement", "Écrivez deux phrases"]',
   '[{"label": "Avant puis après", "icon": "STRUCTURE"}, {"label": "Instant précis", "icon": "TIME"}]',
   'Le bus roulait tranquillement quand…',
   'Le calme décrit juste avant rend la bascule beaucoup plus visible.'),
  -- EE2-C4-S4
  ('EE2-C4-S4',
   '["Faites entendre l''annonce", "Marquez la surprise", "Montrez la réaction des voyageurs"]',
   '[{"label": "Annonce soudaine", "icon": "STRUCTURE"}, {"label": "Réaction visible", "icon": "EXAMPLE"}]',
   'J''étais assis sur un banc quand…',
   'Une réaction visible juste après prouve que l''annonce a tout changé.'),
  -- EE2-C4-S5
  ('EE2-C4-S5',
   '["Posez la scène du guichet", "Marquez l''annonce de l''employée", "Enchaînez la conséquence pour vous"]',
   '[{"label": "Rupture marquée", "icon": "STRUCTURE"}, {"label": "Conséquence immédiate", "icon": "STRUCTURE"}, {"label": "Passé composé", "icon": "TENSE"}]',
   'L''employée a ouvert mon dossier…',
   'Sans conséquence, l''annonce reste une information : dites ce qu''elle a changé.'),
  -- EE2-C5-S1
  ('EE2-C5-S1',
   '["Listez trois étapes dans l''ordre", "Reliez-les par des connecteurs", "Écrivez trois phrases"]',
   '[{"label": "D''abord, ensuite, finalement", "icon": "STRUCTURE"}, {"label": "Trois étapes", "icon": "NUMBER"}]',
   'D''abord, je suis allé au guichet…',
   'Chaque phrase commence par une étape : le lecteur ne se perd jamais.'),
  -- EE2-C5-S2
  ('EE2-C5-S2',
   '["Partez de la découverte", "Racontez ensuite votre démarche", "Terminez par la réparation"]',
   '[{"label": "Ordre chronologique", "icon": "STRUCTURE"}, {"label": "Trois étapes", "icon": "NUMBER"}]',
   'Un matin, les radiateurs étaient froids…',
   'Racontez dans l''ordre vécu : remonter le temps perd votre lecteur.'),
  -- EE2-C5-S3
  ('EE2-C5-S3',
   '["Commencez par votre arrivée", "Suivez l''ordre de la journée", "Finissez par la dernière épreuve"]',
   '[{"label": "Chronologie", "icon": "TIME"}, {"label": "Connecteurs de temps", "icon": "STRUCTURE"}]',
   'D''abord, je suis arrivé au centre…',
   'Trois moments simples suffisent : l''accueil, les épreuves écrites, puis l''oral.'),
  -- EE2-C5-S4
  ('EE2-C5-S4',
   '["Démarrez au moment de la perte", "Enchaînez vos démarches", "Variez les connecteurs employés"]',
   '[{"label": "Connecteurs variés", "icon": "STRUCTURE"}, {"label": "Ordre chronologique", "icon": "TIME"}]',
   'En sortant du magasin, j''ai remarqué…',
   'Alternez les connecteurs : puis, ensuite, enfin, plus tard.'),
  -- EE2-C5-S5
  ('EE2-C5-S5',
   '["Prévoyez au moins quatre étapes", "Ordonnez-les du début à la fin", "Changez de connecteur chaque fois"]',
   '[{"label": "Quatre étapes", "icon": "NUMBER"}, {"label": "Connecteurs différents", "icon": "STRUCTURE"}]',
   'D''abord, j''ai rempli mes cartons…',
   'Quatre étapes tiennent dans trois phrases : deux peuvent se suivre.'),
  -- EE2-C6-S1
  ('EE2-C6-S1',
   '["Racontez votre arrivée en retard", "Ajoutez un détail concret", "Écrivez deux phrases"]',
   '[{"label": "Un détail concret", "icon": "EXAMPLE"}, {"label": "Heure ou numéro", "icon": "NUMBER"}]',
   'Je suis arrivé à la gare…',
   'Une heure ou un numéro de quai suffit à rendre la scène réelle.'),
  -- EE2-C6-S2
  ('EE2-C6-S2',
   '["Choisissez un instant du repas", "Nommez un plat précis", "Décrivez la table ou les invités"]',
   '[{"label": "Détail concret", "icon": "EXAMPLE"}, {"label": "Nombre d''invités", "icon": "NUMBER"}]',
   'Ma voisine avait préparé un…',
   '« Très bon » ne se voit pas ; le nom du plat, si.'),
  -- EE2-C6-S3
  ('EE2-C6-S3',
   '["Situez votre attente", "Ajoutez deux détails visibles", "Écrivez trois phrases"]',
   '[{"label": "Deux détails", "icon": "NUMBER"}, {"label": "Précision concrète", "icon": "EXAMPLE"}]',
   'Je suis arrivé vingt minutes avant…',
   'Un objet, une couleur, un geste : trois façons de rendre l''attente visible.'),
  -- EE2-C6-S4
  ('EE2-C6-S4',
   '["Racontez l''échange au comptoir", "Ajoutez un détail utile", "Écrivez deux phrases"]',
   '[{"label": "Détail sur l''échange", "icon": "EXAMPLE"}, {"label": "Le pharmacien", "icon": "PERSON"}]',
   'À la pharmacie, j''ai donné…',
   'Ce que dit le pharmacien vaut mieux qu''un simple « c''était rapide ».'),
  -- EE2-C6-S5
  ('EE2-C6-S5',
   '["Décrivez le logement visité", "Donnez deux détails concrets", "Reliez-les à votre décision"]',
   '[{"label": "Deux détails", "icon": "NUMBER"}, {"label": "Précisions concrètes", "icon": "EXAMPLE"}, {"label": "Votre décision", "icon": "STRUCTURE"}]',
   'L''agence m''a fait visiter un…',
   'Un loyer, un étage, une vue : des faits éclairent mieux qu''un avis.'),
  -- EE2-C7-S1
  ('EE2-C7-S1',
   '["Nommez ce que vous avez ressenti", "Expliquez la cause de ce sentiment", "Écrivez deux phrases"]',
   '[{"label": "Un sentiment nommé", "icon": "TONE"}, {"label": "Sa cause", "icon": "STRUCTURE"}]',
   'Devant ma porte fermée, j''ai…',
   'Nommez l''émotion : peur, colère, soulagement — puis dites pourquoi.'),
  -- EE2-C7-S2
  ('EE2-C7-S2',
   '["Situez le moment de la nouvelle", "Décrivez votre réaction", "Reliez-la au résultat reçu"]',
   '[{"label": "Réaction exprimée", "icon": "TONE"}, {"label": "Instant de l''annonce", "icon": "TIME"}]',
   'Quand j''ai vu le résultat…',
   'Un geste ou un cri montrent la joie mieux qu''un simple « content ».'),
  -- EE2-C7-S3
  ('EE2-C7-S3',
   '["Dites votre ressenti avant", "Décrivez-le pendant l''entretien", "Terminez par l''après", "Reliez chaque état à sa cause"]',
   '[{"label": "Avant, pendant, après", "icon": "TIME"}, {"label": "Trois ressentis", "icon": "TONE"}]',
   'Avant le rendez-vous, j''avais…',
   'Le ressenti doit changer : la même émotion trois fois n''avance pas.'),
  -- EE2-C7-S4
  ('EE2-C7-S4',
   '["Rappelez le geste du voisin", "Dites ce qu''il a provoqué", "Expliquez pourquoi cela vous a touché"]',
   '[{"label": "Sentiment personnel", "icon": "TONE"}, {"label": "Lien au geste", "icon": "STRUCTURE"}]',
   'Mon voisin est descendu m''aider…',
   '« Gentil » décrit le voisin ; dites ce que vous avez ressenti.'),
  -- EE2-C7-S5
  ('EE2-C7-S5',
   '["Nommez votre état du début", "Montrez le basculement", "Nommez le second sentiment", "Expliquez chaque changement"]',
   '[{"label": "Deux sentiments", "icon": "NUMBER"}, {"label": "Chacun expliqué", "icon": "STRUCTURE"}, {"label": "Pendant puis après", "icon": "TIME"}]',
   'Je suis entré assez confiant…',
   'Deux émotions différentes racontent mieux qu''une déception répétée trois fois.'),
  -- EE2-C8-S1
  ('EE2-C8-S1',
   '["Dites comment le problème s''est réglé", "Précisez la date de réception", "Écrivez deux phrases"]',
   '[{"label": "Résultat clair", "icon": "STRUCTURE"}, {"label": "Passé composé", "icon": "TENSE"}]',
   'Après plusieurs appels, le transporteur…',
   'Terminez vraiment l''histoire : le lecteur doit savoir comment cela s''est fini.'),
  -- EE2-C8-S2
  ('EE2-C8-S2',
   '["Donnez le résultat obtenu", "Ajoutez ce que cela change", "Écrivez deux phrases"]',
   '[{"label": "Résultat concret", "icon": "STRUCTURE"}, {"label": "Conséquence quotidienne", "icon": "EXAMPLE"}]',
   'À la fin de l''année…',
   '« Maintenant, je peux… » montre bien ce que cette année a changé.'),
  -- EE2-C8-S3
  ('EE2-C8-S3',
   '["Racontez la réparation", "Donnez l''état final", "Terminez par la conséquence pour vous"]',
   '[{"label": "Résultat net", "icon": "STRUCTURE"}, {"label": "Conséquence pour vous", "icon": "PERSON"}]',
   'Le plombier est venu réparer…',
   '« Depuis, … » est une façon simple d''annoncer la conséquence.'),
  -- EE2-C8-S4
  ('EE2-C8-S4',
   '["Racontez la réaction du responsable", "Dites comment cela s''est terminé", "Indiquez ce que vous avez changé"]',
   '[{"label": "Issue de l''incident", "icon": "STRUCTURE"}, {"label": "Nouvelle habitude", "icon": "EXAMPLE"}]',
   'Mon responsable m''a écouté, puis…',
   'Une habitude nouvelle prouve mieux qu''un « je ferai attention » un peu vague.'),
  -- EE2-C8-S5
  ('EE2-C8-S5',
   '["Annoncez le résultat obtenu", "Montrez ce qui devient possible", "Terminez par votre bilan personnel"]',
   '[{"label": "Résultat daté", "icon": "TIME"}, {"label": "Conséquence concrète", "icon": "EXAMPLE"}, {"label": "Bilan personnel", "icon": "STRUCTURE"}]',
   'Au mois d''avril, j''ai enfin…',
   'Un bilan précis vaut mieux qu''une phrase toute faite sur la patience.')
) AS v(code, checklist, constraint_tags, answer_starter, tip)
WHERE p.code = v.code;
