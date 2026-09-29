-- ============================================================================
-- V311 — Competences TCF : guidage de saisie, tache EO3
--
-- Renseigne le guidage des 40 petits sujets de « Exprimer et developper un point de vue » :
--   checklist        ce qu'il faut faire, en 2 a 4 gestes a l'imperatif
--   constraint_tags  1 a 3 etiquettes {label, icon} — le COMMENT, jamais
--                    la longueur ni la duree (le front les rend depuis les
--                    bornes deja en base ; les dupliquer les ferait diverger)
--   answer_starter   l'amorce grisee du champ de reponse
--   tip              l'astuce affichee sous la zone de production
--
-- Colonnes ajoutees par V026. UPDATE et non INSERT : les lignes existent
-- deja (V305), et cette migration-la est deja appliquee — la
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
  -- EO3-C1-S1
  ('EO3-C1-S1',
   '["Choisissez : ville ou campagne", "Annoncez ce choix dès l''ouverture", "Tenez ce choix jusqu''au bout"]',
   '[{"label": "Position immédiate", "icon": "STRUCTURE"}, {"label": "Un seul camp", "icon": "NUMBER"}]',
   'Si je devais choisir, je dirais…',
   'commencez par votre choix ; les explications peuvent attendre la deuxième phrase'),
  -- EO3-C1-S2
  ('EO3-C1-S2',
   '["Dites d''abord ce que vous préférez", "Nommez clairement l''option choisie", "Ne décrivez pas les deux options"]',
   '[{"label": "Préférence explicite", "icon": "STRUCTURE"}, {"label": "Ton personnel", "icon": "TONE"}]',
   'Entre les deux, ma préférence va…',
   'une préférence se dit, elle ne se devine pas : nommez-la tout de suite'),
  -- EO3-C1-S3
  ('EO3-C1-S3',
   '["Annoncez voiture ou vélo", "Placez ce choix en ouverture", "Concédez au plus un point"]',
   '[{"label": "Choix en ouverture", "icon": "STRUCTURE"}, {"label": "Concession brève", "icon": "TONE"}]',
   'Pour mes trajets quotidiens, je choisis…',
   'une concession se place après votre choix, jamais avant lui'),
  -- EO3-C1-S4
  ('EO3-C1-S4',
   '["Positionnez-vous : pour ou contre", "Annoncez-le dès la première phrase", "Restez sur cette position"]',
   '[{"label": "Pour ou contre", "icon": "STRUCTURE"}, {"label": "Avis assumé", "icon": "TONE"}]',
   'Sur cette question, ma position est…',
   'ne décrivez pas la situation : donnez d''abord votre avis'),
  -- EO3-C1-S5
  ('EO3-C1-S5',
   '["Annoncez favorable ou défavorable", "Mettez cet avis en premier", "Ne changez pas d''avis ensuite"]',
   '[{"label": "Avis constant", "icon": "STRUCTURE"}, {"label": "Une seule position", "icon": "NUMBER"}]',
   'À titre personnel, je serais plutôt…',
   'une réserve ne doit jamais faire basculer l''avis annoncé au départ'),
  -- EO3-C2-S1
  ('EO3-C2-S1',
   '["Annoncez l''avantage retenu", "Donnez une seule raison", "Reliez-la clairement au télétravail"]',
   '[{"label": "Une raison", "icon": "NUMBER"}, {"label": "Lien explicite", "icon": "STRUCTURE"}]',
   'Ce qui me convainc surtout, c''est…',
   'dites parce que, puis la raison ; évitez de répéter votre opinion'),
  -- EO3-C2-S2
  ('EO3-C2-S2',
   '["Choisissez une seule raison", "Formulez-la clairement", "Montrez son lien avec l''activité"]',
   '[{"label": "Une raison", "icon": "NUMBER"}, {"label": "Effet concret", "icon": "EXAMPLE"}]',
   'La raison qui me paraît décisive…',
   'évitez c''est important : dites ce que le sport change réellement'),
  -- EO3-C2-S3
  ('EO3-C2-S3',
   '["Donnez une raison sur la période", "Écartez les mérites du voyage", "Reliez la raison au conseil"]',
   '[{"label": "Raison ciblée", "icon": "STRUCTURE"}, {"label": "Hors saison", "icon": "TIME"}]',
   'Si je lui conseille septembre, c''est…',
   'votre raison doit porter sur la période, pas sur les vacances'),
  -- EO3-C2-S4
  ('EO3-C2-S4',
   '["Défendez la proposition en une phrase", "Donnez une raison liée à l''âge", "Montrez ce que le tôt change"]',
   '[{"label": "Argument sur l''âge", "icon": "TIME"}, {"label": "Une raison", "icon": "NUMBER"}]',
   'Ce qui joue vraiment, à cet âge…',
   'l''utilité des langues ne suffit pas : expliquez l''intérêt de commencer jeune'),
  -- EO3-C2-S5
  ('EO3-C2-S5',
   '["Choisissez votre meilleure raison", "N''en donnez qu''une", "Développez-la assez pour convaincre"]',
   '[{"label": "Une seule raison", "icon": "NUMBER"}, {"label": "Argument tenu", "icon": "STRUCTURE"}]',
   'S''il ne fallait en retenir qu''une…',
   'empiler quatre raisons affaiblit le propos ; une seule, bien tenue, convainc'),
  -- EO3-C3-S1
  ('EO3-C3-S1',
   '["Reprenez l''idée en une phrase", "Expliquez la cause ou la conséquence", "Terminez par un effet concret"]',
   '[{"label": "Cause ou conséquence", "icon": "STRUCTURE"}, {"label": "Effet concret", "icon": "EXAMPLE"}]',
   'Cela tient surtout au fait que…',
   'reformuler n''est pas expliquer : montrez ce qui découle de quoi'),
  -- EO3-C3-S2
  ('EO3-C3-S2',
   '["Partez de l''idée déjà donnée", "Déroulez une conséquence puis une autre", "Arrivez à un effet visible"]',
   '[{"label": "Cause et conséquence", "icon": "STRUCTURE"}, {"label": "Effet observable", "icon": "EXAMPLE"}]',
   'Le lien passe surtout par…',
   'des mots comme du coup ou donc rendent votre explication facile à suivre'),
  -- EO3-C3-S3
  ('EO3-C3-S3',
   '["Ciblez le bénéfice du bénévole", "Expliquez d''où il vient", "Poussez jusqu''à sa conséquence"]',
   '[{"label": "Bénéfice du bénévole", "icon": "PERSON"}, {"label": "Explication déroulée", "icon": "STRUCTURE"}]',
   'Ce que le bénévole y gagne…',
   'dire que c''est une belle chose ne remplace pas l''explication attendue'),
  -- EO3-C3-S4
  ('EO3-C3-S4',
   '["Suivez le trajet du déchet", "Expliquez le mécanisme étape par étape", "Concluez sur l''effet obtenu"]',
   '[{"label": "Mécanisme expliqué", "icon": "STRUCTURE"}, {"label": "Cas concret", "icon": "EXAMPLE"}]',
   'Tout se joue au moment où…',
   'montrez comment ça marche plutôt que de répéter qu''il faut trier'),
  -- EO3-C3-S5
  ('EO3-C3-S5',
   '["Reprenez l''idée du stagiaire", "Dites ce que cela rend possible", "Allez au-delà du mot pratique"]',
   '[{"label": "Explication précise", "icon": "STRUCTURE"}, {"label": "Situation concrète", "icon": "EXAMPLE"}]',
   'L''élément décisif, à mon sens…',
   'pratique et flexible sont des étiquettes ; expliquez ce qu''elles recouvrent'),
  -- EO3-C4-S1
  ('EO3-C4-S1',
   '["Annoncez que vous donnez un exemple", "Situez une personne et un moment", "Dites l''effet observé"]',
   '[{"label": "Une seule situation", "icon": "NUMBER"}, {"label": "Détail concret", "icon": "EXAMPLE"}]',
   'Je pense à une personne que…',
   'une généralité n''est pas un exemple : racontez une scène précise'),
  -- EO3-C4-S2
  ('EO3-C4-S2',
   '["Choisissez une scène précise", "Donnez le lieu et le moment", "Montrez ce que cela change"]',
   '[{"label": "Lieu et moment", "icon": "PLACE"}, {"label": "Un seul exemple", "icon": "NUMBER"}]',
   'Je repense à un samedi où…',
   'un exemple vit par ses détails : qui, où, quand'),
  -- EO3-C4-S3
  ('EO3-C4-S3',
   '["Écartez la question du loyer", "Racontez une situation datée", "Reliez-la à l''idée défendue"]',
   '[{"label": "Aspect non financier", "icon": "STRUCTURE"}, {"label": "Situation située", "icon": "PLACE"}]',
   'Je pense à une colocataire qui…',
   'parler du loyer partagé ferait retomber l''exemple sur l''argent'),
  -- EO3-C4-S4
  ('EO3-C4-S4',
   '["Choisissez une personne et un métier", "Précisez la durée et le résultat", "Reliez l''exemple à votre idée"]',
   '[{"label": "Métier précis", "icon": "PERSON"}, {"label": "Avant et après", "icon": "TIME"}]',
   'Je connais quelqu''un qui, après…',
   'des gens et ça va mieux ne suffisent pas : nommez, datez, chiffrez'),
  -- EO3-C4-S5
  ('EO3-C4-S5',
   '["Choisissez un usage autre que l''emprunt", "Situez le lieu et le jour", "Développez cet unique exemple"]',
   '[{"label": "Autre usage", "icon": "STRUCTURE"}, {"label": "Un exemple développé", "icon": "EXAMPLE"}]',
   'Dans la bibliothèque près de chez moi…',
   'si votre exemple parle de livres, il retombe sur l''emprunt'),
  -- EO3-C5-S1
  ('EO3-C5-S1',
   '["Annoncez un deuxième argument", "Changez de terrain", "Écartez la question du temps"]',
   '[{"label": "Deuxième argument", "icon": "NUMBER"}, {"label": "Terrain différent", "icon": "STRUCTURE"}]',
   'Il y a un deuxième point…',
   'redire le même argument autrement ne compte pas pour un second'),
  -- EO3-C5-S2
  ('EO3-C5-S2',
   '["Signalez que vous ajoutez un argument", "Évitez toute question de coût", "Développez ce nouvel argument"]',
   '[{"label": "Hors budget", "icon": "STRUCTURE"}, {"label": "Argument distinct", "icon": "NUMBER"}]',
   'Sur un tout autre plan…',
   'le budget est déjà traité : cherchez un avantage d''une autre nature'),
  -- EO3-C5-S3
  ('EO3-C5-S3',
   '["Ouvrez un aspect nouveau", "Laissez de côté la motivation", "Expliquez brièvement ce deuxième apport"]',
   '[{"label": "Aspect nouveau", "icon": "STRUCTURE"}, {"label": "Deuxième argument", "icon": "NUMBER"}]',
   'Il y a aussi autre chose…',
   'insister sur la motivation reviendrait à répéter l''argument déjà donné'),
  -- EO3-C5-S4
  ('EO3-C5-S4',
   '["Trouvez un intérêt hors dépistage", "Annoncez-le comme second argument", "Montrez qu''il tient seul"]',
   '[{"label": "Hors dépistage", "icon": "STRUCTURE"}, {"label": "Argument autonome", "icon": "NUMBER"}]',
   'Un second intérêt, très différent…',
   'revenir au dépistage précoce annulerait l''effet de ce deuxième argument'),
  -- EO3-C5-S5
  ('EO3-C5-S5',
   '["Sortez du lien familial", "Nommez un autre domaine", "Illustrez-le en une phrase"]',
   '[{"label": "Autre domaine", "icon": "STRUCTURE"}, {"label": "Deuxième argument", "icon": "NUMBER"}]',
   'Sur un terrain complètement différent…',
   'changez franchement de domaine : le lien familial est déjà votre premier argument'),
  -- EO3-C6-S1
  ('EO3-C6-S1',
   '["Choisissez un ou deux critères", "Traitez chaque critère des deux côtés", "Employez alors que ou en revanche"]',
   '[{"label": "Mots de comparaison", "icon": "STRUCTURE"}, {"label": "Deux critères", "icon": "NUMBER"}]',
   'Sur le premier point, la différence…',
   'deux descriptions côte à côte ne font pas une comparaison'),
  -- EO3-C6-S2
  ('EO3-C6-S2',
   '["Fixez des critères communs", "Comparez les deux options ensemble", "Reliez-les par un connecteur"]',
   '[{"label": "Critères communs", "icon": "STRUCTURE"}, {"label": "Deux options", "icon": "NUMBER"}]',
   'Si je compare sur le prix…',
   'un critère à la fois, mais toujours traité des deux côtés'),
  -- EO3-C6-S3
  ('EO3-C6-S3',
   '["Choisissez deux critères de comparaison", "Mettez les logements face à face", "Marquez l''écart avec un connecteur"]',
   '[{"label": "Face à face", "icon": "STRUCTURE"}, {"label": "Deux critères", "icon": "NUMBER"}]',
   'À loyer comparable, la différence tient…',
   'alors que, en revanche, c''est l''inverse : ces mots font la comparaison'),
  -- EO3-C6-S4
  ('EO3-C6-S4',
   '["Retenez des critères identiques", "Examinez chaque formule dessus", "Soulignez le renversement s''il existe"]',
   '[{"label": "Critères identiques", "icon": "STRUCTURE"}, {"label": "Deux formules", "icon": "NUMBER"}]',
   'Sur la préparation, les deux formules…',
   'quand un critère s''inverse, dites-le : la comparaison devient limpide'),
  -- EO3-C6-S5
  ('EO3-C6-S5',
   '["Prenez deux critères communs", "Donnez avantage et inconvénient", "Concluez par un critère de choix"]',
   '[{"label": "Avantages et inconvénients", "icon": "STRUCTURE"}, {"label": "Deux formules", "icon": "NUMBER"}]',
   'Les deux formules s''opposent surtout…',
   'chaque avantage annoncé appelle son revers, des deux côtés'),
  -- EO3-C7-S1
  ('EO3-C7-S1',
   '["Donnez d''abord un avantage", "Introduisez ensuite une limite", "Reprenez votre position pour finir"]',
   '[{"label": "Une limite", "icon": "NUMBER"}, {"label": "Position maintenue", "icon": "STRUCTURE"}]',
   'Leur vrai apport, selon moi…',
   'terminez sur votre position, sinon la limite prend toute la place'),
  -- EO3-C7-S2
  ('EO3-C7-S2',
   '["Présentez l''avantage principal", "Reconnaissez une difficulté", "Réaffirmez votre avis favorable"]',
   '[{"label": "Avis favorable", "icon": "TONE"}, {"label": "Limite reconnue", "icon": "STRUCTURE"}]',
   'Ce que ça change vraiment…',
   'cela dit, je reconnais : ces formules annoncent proprement une limite'),
  -- EO3-C7-S3
  ('EO3-C7-S3',
   '["Défendez l''avantage retenu", "Ajoutez une réserve mesurée", "Gardez votre position finale"]',
   '[{"label": "Réserve mesurée", "icon": "TONE"}, {"label": "Position tenue", "icon": "STRUCTURE"}]',
   'Ce service dépanne surtout quand…',
   'une réserve peut dire comment utiliser, sans condamner ce que vous défendez'),
  -- EO3-C7-S4
  ('EO3-C7-S4',
   '["Nommez un avantage réel", "Reconnaissez une limite sérieuse", "Concluez sans abandonner votre position"]',
   '[{"label": "Limite sérieuse", "icon": "STRUCTURE"}, {"label": "Position conservée", "icon": "TONE"}]',
   'L''intérêt principal, pour moi, reste…',
   'prendre la critique au sérieux renforce votre position au lieu de l''affaiblir'),
  -- EO3-C7-S5
  ('EO3-C7-S5',
   '["Défendez un avantage précis", "Concédez le point sensible", "Revenez à votre avis initial"]',
   '[{"label": "Concession explicite", "icon": "STRUCTURE"}, {"label": "Avis tenu", "icon": "TONE"}]',
   'Ce qu''elle change vraiment, c''est…',
   'je concède, j''admets : ces formules montrent que vous maîtrisez le sujet'),
  -- EO3-C8-S1
  ('EO3-C8-S1',
   '["Annoncez votre avis", "Donnez une raison", "Ajoutez un exemple", "Terminez par une conclusion"]',
   '[{"label": "Quatre étapes", "icon": "NUMBER"}, {"label": "Ordre respecté", "icon": "STRUCTURE"}]',
   'Pour moi, la réponse est…',
   'd''abord, par exemple, au final : ces mots guident votre auditeur'),
  -- EO3-C8-S2
  ('EO3-C8-S2',
   '["Donnez votre avis d''entrée", "Enchaînez une raison", "Illustrez par un exemple", "Refermez par une conclusion"]',
   '[{"label": "Quatre temps", "icon": "NUMBER"}, {"label": "Conclusion nette", "icon": "STRUCTURE"}]',
   'Sur ce point, je penche…',
   'une réponse qui s''arrête n''est pas une réponse qui conclut'),
  -- EO3-C8-S3
  ('EO3-C8-S3',
   '["Répondez à la question posée", "Justifiez par une raison", "Donnez un exemple vécu", "Concluez sans revenir en arrière"]',
   '[{"label": "Quatre étapes", "icon": "NUMBER"}, {"label": "Ordre des étapes", "icon": "STRUCTURE"}]',
   'Ma réponse à cette question…',
   'gardez l''avis en premier : le placer à la fin brouille tout'),
  -- EO3-C8-S4
  ('EO3-C8-S4',
   '["Donnez votre conseil", "Appuyez-le sur une raison", "Ajoutez un exemple chiffré", "Terminez par une phrase de clôture"]',
   '[{"label": "Conseil assumé", "icon": "TONE"}, {"label": "Quatre étapes", "icon": "NUMBER"}]',
   'Ce que je conseillerais, personnellement…',
   'un exemple chiffré rend le conseil crédible en quelques mots'),
  -- EO3-C8-S5
  ('EO3-C8-S5',
   '["Prenez position sur le tourisme", "Développez une raison", "Appuyez par un exemple", "Refermez par une phrase forte"]',
   '[{"label": "Quatre étapes", "icon": "NUMBER"}, {"label": "Conclusion ferme", "icon": "STRUCTURE"}]',
   'Sur cette question, je dirais…',
   'la conclusion doit ajouter quelque chose, pas répéter votre première phrase')
) AS v(code, checklist, constraint_tags, answer_starter, tip)
WHERE p.code = v.code;
