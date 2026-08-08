-- ============================================================================
-- V310 — Competences TCF : guidage de saisie, tache EO2
--
-- Renseigne le guidage des 40 petits sujets de « Jeu de role : demander et obtenir des informations » :
--   checklist        ce qu'il faut faire, en 2 a 4 gestes a l'imperatif
--   constraint_tags  1 a 3 etiquettes {label, icon} — le COMMENT, jamais
--                    la longueur ni la duree (le front les rend depuis les
--                    bornes deja en base ; les dupliquer les ferait diverger)
--   answer_starter   l'amorce grisee du champ de reponse
--   tip              l'astuce affichee sous la zone de production
--
-- Colonnes ajoutees par V026. UPDATE et non INSERT : les lignes existent
-- deja (V304), et cette migration-la est deja appliquee — la
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
  -- EO2-C1-S1
  ('EO2-C1-S1',
   '["Saluez la conseillère", "Dites pourquoi vous appelez", "Précisez le logement cherché"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Besoin annoncé", "icon": "STRUCTURE"}]',
   'Bonjour madame, je vous appelle pour…',
   'Nommez le type de logement : la conseillère pourra vous orienter tout de suite.'),
  -- EO2-C1-S2
  ('EO2-C1-S2',
   '["Saluez l''employé", "Dites pourquoi vous venez", "Annoncez ce que vous voulez"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Objet annoncé", "icon": "STRUCTURE"}]',
   'Bonjour monsieur, je viens me renseigner…',
   'Dites en une phrase ce que vous voulez faire dans cette salle.'),
  -- EO2-C1-S3
  ('EO2-C1-S3',
   '["Saluez l''agente", "Résumez votre situation", "Nommez la démarche voulue"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Registre poli", "icon": "TONE"}]',
   'Bonjour madame, nous venons d''emménager et…',
   'Une phrase suffit pour situer votre situation avant d''annoncer la démarche.'),
  -- EO2-C1-S4
  ('EO2-C1-S4',
   '["Saluez le mécanicien", "Décrivez le bruit constaté", "Dites ce que vous demandez"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Demande explicite", "icon": "STRUCTURE"}]',
   'Bonjour monsieur, ma voiture fait un bruit…',
   'Après le problème, dites clairement ce que le garage doit faire pour vous.'),
  -- EO2-C1-S5
  ('EO2-C1-S5',
   '["Saluez la conseillère", "Présentez votre situation professionnelle", "Annoncez la formation recherchée"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Domaine précis", "icon": "EXAMPLE"}]',
   'Bonjour madame, je travaille en journée et…',
   'Nommez le domaine visé : la conseillère ciblera immédiatement les bonnes formations.'),
  -- EO2-C2-S1
  ('EO2-C2-S1',
   '["Saluez l''agent d''accueil", "Demandez l''ouverture du samedi matin"]',
   '[{"label": "Question entière", "icon": "STRUCTURE"}, {"label": "Samedi matin", "icon": "TIME"}]',
   'Bonjour monsieur, je voudrais savoir si…',
   'Nommez le jour et le moment dans votre question : samedi matin.'),
  -- EO2-C2-S2
  ('EO2-C2-S2',
   '["Saluez la bibliothécaire", "Demandez le nombre de livres"]',
   '[{"label": "Question entière", "icon": "STRUCTURE"}, {"label": "Nombre exact", "icon": "NUMBER"}]',
   'Bonjour madame, pouvez-vous me dire combien…',
   'Une question complète appelle une réponse chiffrée, utilisable tout de suite.'),
  -- EO2-C2-S3
  ('EO2-C2-S3',
   '["Saluez le conseiller", "Demandez la disponibilité de la fibre", "Donnez votre adresse"]',
   '[{"label": "Question entière", "icon": "STRUCTURE"}, {"label": "Adresse précise", "icon": "PLACE"}]',
   'Bonjour monsieur, je voudrais vérifier si…',
   'Donnez votre adresse dans la question : le conseiller vérifie immédiatement.'),
  -- EO2-C2-S4
  ('EO2-C2-S4',
   '["Saluez la directrice", "Demandez s''il reste une place", "Précisez l''enfant et septembre"]',
   '[{"label": "Rentrée de septembre", "icon": "TIME"}, {"label": "Question entière", "icon": "STRUCTURE"}]',
   'Bonjour madame, est-ce qu''il vous reste…',
   'Nommez l''enfant concerné et la période : la réponse vous concernera vraiment.'),
  -- EO2-C2-S5
  ('EO2-C2-S5',
   '["Saluez l''agente", "Dites quelle démarche vous faites", "Demandez si le rendez-vous est obligatoire"]',
   '[{"label": "Vouvoiement", "icon": "PERSON"}, {"label": "Question entière", "icon": "STRUCTURE"}]',
   'Bonjour madame, je dois renouveler mon…',
   'Annoncez la démarche avant la question : l''agente saura de quoi vous parlez.'),
  -- EO2-C3-S1
  ('EO2-C3-S1',
   '["Saluez la bénévole", "Demandez les jours des cours", "Demandez l''heure de début"]',
   '[{"label": "Deux questions", "icon": "NUMBER"}, {"label": "Jours et horaires", "icon": "TIME"}]',
   'Bonjour madame, je souhaite suivre vos cours…',
   'Posez vos deux questions à la suite, sans en oublier une.'),
  -- EO2-C3-S2
  ('EO2-C3-S2',
   '["Saluez le formateur", "Demandez le prix du forfait", "Demandez la durée de la formation"]',
   '[{"label": "Prix demandé", "icon": "NUMBER"}, {"label": "Durée demandée", "icon": "TIME"}]',
   'Bonjour monsieur, je voudrais passer le permis…',
   'Le prix ne suffit pas : demandez aussi combien de temps dure la formation.'),
  -- EO2-C3-S3
  ('EO2-C3-S3',
   '["Saluez l''animateur", "Demandez le prix du cours", "Demandez l''horaire", "Demandez le lieu exact"]',
   '[{"label": "Trois questions", "icon": "NUMBER"}, {"label": "Lieu précis", "icon": "PLACE"}]',
   'Bonjour monsieur, je m''intéresse à vos cours…',
   'Comptez vos questions : trois informations sont demandées, le lieu s''oublie souvent.'),
  -- EO2-C3-S4
  ('EO2-C3-S4',
   '["Saluez la conseillère", "Demandez les dates de départ", "Demandez la durée du séjour", "Demandez le prix par personne"]',
   '[{"label": "Trois questions", "icon": "NUMBER"}, {"label": "Dates possibles", "icon": "TIME"}]',
   'Bonjour madame, je prépare un séjour…',
   'Enchaînez vos trois questions dans un ordre logique : dates, durée, prix.'),
  -- EO2-C3-S5
  ('EO2-C3-S5',
   '["Saluez le directeur", "Demandez les dates d''ouverture", "Demandez horaires et tarif", "Demandez l''adresse du centre"]',
   '[{"label": "Quatre questions", "icon": "NUMBER"}, {"label": "Adresse demandée", "icon": "PLACE"}]',
   'Bonjour monsieur, ma fille voudrait venir…',
   'Quatre informations à obtenir : gardez-les en tête et n''en laissez aucune.'),
  -- EO2-C4-S1
  ('EO2-C4-S1',
   '["Saluez l''agente", "Annoncez l''inscription à la cantine", "Demandez les documents à fournir"]',
   '[{"label": "Documents exigés", "icon": "EXAMPLE"}, {"label": "Vouvoiement", "icon": "PERSON"}]',
   'Bonjour madame, je voudrais inscrire mon…',
   'Demander la liste des pièces maintenant vous évite un second déplacement.'),
  -- EO2-C4-S2
  ('EO2-C4-S2',
   '["Demandez ce que comprend la livraison", "Demandez ce que couvre la garantie"]',
   '[{"label": "Deux conditions", "icon": "NUMBER"}, {"label": "Vouvoiement", "icon": "PERSON"}]',
   'Avant de commander, je voudrais savoir…',
   'Posez ces deux questions avant de valider la commande : c''est le moment.'),
  -- EO2-C4-S3
  ('EO2-C4-S3',
   '["Saluez le conseiller", "Demandez les documents nécessaires", "Demandez les frais du compte"]',
   '[{"label": "Documents et frais", "icon": "STRUCTURE"}, {"label": "Vouvoiement", "icon": "PERSON"}]',
   'Bonjour monsieur, je souhaite ouvrir un compte…',
   'Les frais mensuels comptent autant que les papiers : demandez les deux.'),
  -- EO2-C4-S4
  ('EO2-C4-S4',
   '["Demandez les pièces du dossier", "Demandez les conditions exigées", "Citez le garant ou les revenus"]',
   '[{"label": "Conditions exigées", "icon": "STRUCTURE"}, {"label": "Garant", "icon": "PERSON"}]',
   'Avant la visite, j''aimerais connaître les…',
   'Connaître les conditions avant la visite vous fait gagner un temps précieux.'),
  -- EO2-C4-S5
  ('EO2-C4-S5',
   '["Demandez les conditions d''accès", "Demandez qui finance la formation", "Demandez ce qu''on attend de vous"]',
   '[{"label": "Trois volets", "icon": "STRUCTURE"}, {"label": "Vouvoiement", "icon": "PERSON"}]',
   'Bonjour madame, cette formation m''intéresse et…',
   'Le financement et vos obligations pèsent autant que les conditions d''entrée.'),
  -- EO2-C5-S1
  ('EO2-C5-S1',
   '["Reprenez les 620 euros annoncés", "Demandez si les charges sont comprises"]',
   '[{"label": "Montant repris", "icon": "NUMBER"}, {"label": "Question de suivi", "icon": "STRUCTURE"}]',
   'D''accord, et concernant ces 620 euros…',
   'Repartez du chiffre annoncé : votre question s''accroche à sa réponse.'),
  -- EO2-C5-S2
  ('EO2-C5-S2',
   '["Reprenez le mardi dix-neuf heures", "Demandez une information liée au cours"]',
   '[{"label": "Horaire repris", "icon": "TIME"}, {"label": "Même sujet", "icon": "STRUCTURE"}]',
   'Le mardi à dix-neuf heures, et…',
   'Restez sur ce cours : la durée ou la réservation prolongent naturellement l''horaire.'),
  -- EO2-C5-S3
  ('EO2-C5-S3',
   '["Reprenez le créneau proposé", "Dites s''il vous convient", "Posez une question sur le rendez-vous"]',
   '[{"label": "Créneau repris", "icon": "TIME"}, {"label": "Accord exprimé", "icon": "STRUCTURE"}]',
   'Jeudi à seize heures trente, cela…',
   'Confirmez d''abord le créneau, puis demandez ce qu''il faut apporter.'),
  -- EO2-C5-S4
  ('EO2-C5-S4',
   '["Reprenez les six mois annoncés", "Demandez quels jours sont concernés", "Interrogez l''organisation concrète"]',
   '[{"label": "Durée reprise", "icon": "TIME"}, {"label": "Organisation concrète", "icon": "STRUCTURE"}]',
   'Six mois à trois jours, d''accord…',
   'Partez de la durée annoncée pour interroger le rythme réel des semaines.'),
  -- EO2-C5-S5
  ('EO2-C5-S5',
   '["Reprenez le prix annoncé", "Demandez le tarif après douze mois", "Demandez les frais éventuels"]',
   '[{"label": "Deux questions", "icon": "NUMBER"}, {"label": "Après douze mois", "icon": "TIME"}]',
   'Vingt-quatre euros quatre-vingt-dix-neuf, d''accord, et…',
   'Deux questions valent mieux qu''une pour connaître le coût réel du forfait.'),
  -- EO2-C6-S1
  ('EO2-C6-S1',
   '["Signalez poliment votre incompréhension", "Demandez de répéter l''heure"]',
   '[{"label": "Ton poli", "icon": "TONE"}, {"label": "Heure demandée", "icon": "TIME"}]',
   'Excusez-moi madame, je n''ai pas bien…',
   'Dire qu''on n''a pas compris est normal et attendu dans l''échange.'),
  -- EO2-C6-S2
  ('EO2-C6-S2',
   '["Reprenez la formule vague", "Demandez le jour exact"]',
   '[{"label": "Date précise", "icon": "TIME"}, {"label": "Ton poli", "icon": "TONE"}]',
   'En fin de semaine, d''accord, mais…',
   'Reprendre le mot vague montre exactement ce que vous voulez préciser.'),
  -- EO2-C6-S3
  ('EO2-C6-S3',
   '["Reprenez les trois cents euros", "Demandez ce que couvre ce montant"]',
   '[{"label": "Montant repris", "icon": "NUMBER"}, {"label": "Pièces et main-d''œuvre", "icon": "EXAMPLE"}]',
   'Trois cents euros, est-ce que ce…',
   'Un montant approximatif se précise : demandez ce qu''il comprend vraiment.'),
  -- EO2-C6-S4
  ('EO2-C6-S4',
   '["Reprenez le mot récent", "Demandez quels documents sont acceptés", "Demandez l''ancienneté maximale admise"]',
   '[{"label": "Deux précisions", "icon": "NUMBER"}, {"label": "Documents acceptés", "icon": "EXAMPLE"}]',
   'Un justificatif récent, c''est-à-dire quels…',
   'Préciser la date limite vous évite un dossier refusé au guichet.'),
  -- EO2-C6-S5
  ('EO2-C6-S5',
   '["Reformulez avec vos propres mots", "Reprenez les cent cinquante euros", "Demandez confirmation à la conseillère"]',
   '[{"label": "Reformulation", "icon": "STRUCTURE"}, {"label": "Montant repris", "icon": "NUMBER"}]',
   'Si je comprends bien, en cas…',
   'Dites-le autrement, avec vos mots, puis demandez si c''est exact.'),
  -- EO2-C7-S1
  ('EO2-C7-S1',
   '["Interrogez la différence entre les formules", "Comparez prix et engagement", "Annoncez votre choix et sa raison"]',
   '[{"label": "Deux formules", "icon": "NUMBER"}, {"label": "Choix justifié", "icon": "STRUCTURE"}]',
   'Si je compare les deux formules…',
   'Un choix convainc quand il repose sur une comparaison, pas une préférence.'),
  -- EO2-C7-S2
  ('EO2-C7-S2',
   '["Posez une question sur la différence", "Comparez prix et services", "Annoncez votre choix motivé"]',
   '[{"label": "Deux forfaits", "icon": "NUMBER"}, {"label": "Raison donnée", "icon": "STRUCTURE"}]',
   'Entre les deux forfaits, est-ce que…',
   'Reliez votre choix à votre usage réel : appels, données, budget.'),
  -- EO2-C7-S3
  ('EO2-C7-S3',
   '["Interrogez la conseillère sur les trajets", "Comparez le temps et le prix", "Choisissez et justifiez"]',
   '[{"label": "Deux critères", "icon": "NUMBER"}, {"label": "Choix justifié", "icon": "STRUCTURE"}]',
   'Entre le train et le bus…',
   'Deux aspects comparés valent mieux qu''un : le temps et le prix.'),
  -- EO2-C7-S4
  ('EO2-C7-S4',
   '["Posez vos questions sur les formules", "Comparez durée et rythme", "Dites laquelle vous convient", "Expliquez pourquoi"]',
   '[{"label": "Deux formules", "icon": "NUMBER"}, {"label": "Votre situation", "icon": "PERSON"}]',
   'Avant de choisir, j''aimerais savoir si…',
   'Votre emploi du temps réel est le meilleur argument pour trancher.'),
  -- EO2-C7-S5
  ('EO2-C7-S5',
   '["Interrogez les deux contrats", "Comparez prix et franchise", "Annoncez votre choix", "Expliquez votre décision"]',
   '[{"label": "Deux contrats", "icon": "NUMBER"}, {"label": "Choix argumenté", "icon": "STRUCTURE"}]',
   'Entre ces deux contrats, est-ce que…',
   'Comparez sur plusieurs points : le prix seul ne décide pas tout.'),
  -- EO2-C8-S1
  ('EO2-C8-S1',
   '["Répétez la date et l''heure", "Nommez le médecin", "Terminez par une formule de congé"]',
   '[{"label": "Récapitulatif", "icon": "STRUCTURE"}, {"label": "Date et heure", "icon": "TIME"}]',
   'Donc mardi 10 mars à quatorze…',
   'Répéter la date permet de corriger une erreur avant de partir.'),
  -- EO2-C8-S2
  ('EO2-C8-S2',
   '["Répétez l''heure annoncée", "Répétez le montant annoncé", "Prenez congé poliment"]',
   '[{"label": "Heure et montant", "icon": "NUMBER"}, {"label": "Congé poli", "icon": "TONE"}]',
   'Donc vendredi à dix-sept heures, pour…',
   'Le prix se confirme aussi : c''est lui qui compte à la fin.'),
  -- EO2-C8-S3
  ('EO2-C8-S3',
   '["Répétez la date limite", "Rappelez la réponse par courrier", "Vérifiez un point précis", "Prenez congé"]',
   '[{"label": "Récapitulatif", "icon": "STRUCTURE"}, {"label": "Date limite", "icon": "TIME"}]',
   'Donc je dépose le dossier avant…',
   'Gardez une dernière question pour la fin : elle sécurise votre dossier.'),
  -- EO2-C8-S4
  ('EO2-C8-S4',
   '["Répétez les dates et le lieu", "Répétez le prix total", "Posez une dernière question", "Terminez l''échange poliment"]',
   '[{"label": "Dates et lieu", "icon": "TIME"}, {"label": "Prix total", "icon": "NUMBER"}]',
   'Donc je prends la voiture samedi…',
   'Récapitulatif complet, puis une question, puis le congé : dans cet ordre.'),
  -- EO2-C8-S5
  ('EO2-C8-S5',
   '["Répétez le jour et l''horaire", "Rappelez l''adhésion et la photo", "Vérifiez le point le moins clair", "Prenez congé"]',
   '[{"label": "Récapitulatif complet", "icon": "STRUCTURE"}, {"label": "Adhésion et photo", "icon": "EXAMPLE"}]',
   'Donc les ateliers ont lieu le…',
   'Reprenez l''essentiel, pas tout : jour, horaire, salle, adhésion, photo.')
) AS v(code, checklist, constraint_tags, answer_starter, tip)
WHERE p.code = v.code;
