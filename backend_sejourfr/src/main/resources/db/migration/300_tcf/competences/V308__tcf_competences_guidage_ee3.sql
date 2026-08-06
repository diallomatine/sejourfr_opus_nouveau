-- ============================================================================
-- V308 — Competences TCF : guidage de saisie, tache EE3
--
-- Renseigne le guidage des 40 petits sujets de « Donner son opinion » :
--   checklist        ce qu'il faut faire, en 2 a 4 gestes a l'imperatif
--   constraint_tags  1 a 3 etiquettes {label, icon} — le COMMENT, jamais
--                    la longueur ni la duree (le front les rend depuis les
--                    bornes deja en base ; les dupliquer les ferait diverger)
--   answer_starter   l'amorce grisee du champ de reponse
--   tip              l'astuce affichee sous la zone de production
--
-- Colonnes ajoutees par V026. UPDATE et non INSERT : les lignes existent
-- deja (V302), et cette migration-la est deja appliquee — la
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
  -- EE3-C1-S1
  ('EE3-C1-S1',
   '["Choisissez votre camp", "Employez un verbe d''opinion", "Tenez-vous à une phrase"]',
   '[{"label": "Position tranchée", "icon": "STRUCTURE"}, {"label": "Verbe d''opinion", "icon": "TONE"}]',
   'Selon moi, le télétravail devrait…',
   'votre avis doit apparaître avant tout le reste'),
  -- EE3-C1-S2
  ('EE3-C1-S2',
   '["Annoncez votre avis", "Nommez la mesure concernée", "Arrêtez-vous après une phrase"]',
   '[{"label": "Avis explicite", "icon": "STRUCTURE"}, {"label": "Ton personnel", "icon": "TONE"}]',
   'Je trouve que cette gratuité…',
   'dites franchement oui ou non, le doute affaiblit votre réponse'),
  -- EE3-C1-S3
  ('EE3-C1-S3',
   '["Prenez clairement position", "Désignez le menu unique", "Évitez toute formule hésitante"]',
   '[{"label": "Aucune hésitation", "icon": "TONE"}, {"label": "Avis personnel", "icon": "PERSON"}]',
   'Ce menu unique me paraît…',
   '« cela dépend » ne fait pas une opinion, tranchez'),
  -- EE3-C1-S4
  ('EE3-C1-S4',
   '["Répondez directement à la question", "Dites si vous êtes favorable", "Gardez vos raisons de côté"]',
   '[{"label": "Réponse directe", "icon": "STRUCTURE"}, {"label": "Ton neutre", "icon": "TONE"}]',
   'À mon sens, un âge…',
   'une position affirmée vaut mieux qu''un constat général'),
  -- EE3-C1-S5
  ('EE3-C1-S5',
   '["Nommez l''option choisie", "Écartez clairement l''autre", "Ne justifiez pas encore"]',
   '[{"label": "Choix unique", "icon": "NUMBER"}, {"label": "Conseil assumé", "icon": "TONE"}]',
   'À ta place, je choisirais…',
   'votre ami doit savoir quoi faire après une seule lecture'),
  -- EE3-C2-S1
  ('EE3-C2-S1',
   '["Donnez une raison nouvelle", "Reliez-la à votre avis", "Restez sur une phrase"]',
   '[{"label": "Raison nouvelle", "icon": "STRUCTURE"}, {"label": "Sans exemple", "icon": "EXAMPLE"}]',
   'Ils permettent surtout de…',
   'répéter l''opinion autrement ne compte pas comme une raison'),
  -- EE3-C2-S2
  ('EE3-C2-S2',
   '["Nommez un effet concret", "Rattachez-le à votre avis", "Limitez-vous à une raison"]',
   '[{"label": "Une seule raison", "icon": "NUMBER"}, {"label": "Effet concret", "icon": "EXAMPLE"}]',
   'Bouger chaque jour aide à…',
   'un bénéfice précis convainc plus qu''un « c''est important »'),
  -- EE3-C2-S3
  ('EE3-C2-S3',
   '["Ciblez l''âge de six ans", "Dites ce que cela permet", "Tenez en une phrase"]',
   '[{"label": "Argument ciblé", "icon": "STRUCTURE"}, {"label": "Âge précis", "icon": "TIME"}]',
   'À six ans, un enfant…',
   'l''argument doit parler de l''âge, pas des langues en général'),
  -- EE3-C2-S4
  ('EE3-C2-S4',
   '["Dites ce que l''atelier évite", "Ou ce qu''il permet d''obtenir", "Restez sur une seule raison"]',
   '[{"label": "Effet mesurable", "icon": "EXAMPLE"}, {"label": "Raison unique", "icon": "NUMBER"}]',
   'Ces ateliers permettent d''éviter…',
   '« bon pour l''environnement » gagne à devenir concret'),
  -- EE3-C2-S5
  ('EE3-C2-S5',
   '["Comparez occasion et neuf", "Dites ce que l''on gagne", "Laissez votre expérience de côté"]',
   '[{"label": "Sans anecdote", "icon": "EXAMPLE"}, {"label": "Raison convaincante", "icon": "STRUCTURE"}]',
   'L''occasion permet surtout de…',
   '« beaucoup de gens le font » n''explique rien, cherchez l''avantage'),
  -- EE3-C3-S1
  ('EE3-C3-S1',
   '["Dites d''où vient l''avantage", "Montrez ce que cela change", "Évitez tout exemple précis"]',
   '[{"label": "Cause puis conséquence", "icon": "STRUCTURE"}, {"label": "Sans exemple", "icon": "EXAMPLE"}]',
   'En ville, la plupart des…',
   'expliquer une idée, c''est dire d''où elle vient'),
  -- EE3-C3-S2
  ('EE3-C3-S2',
   '["Posez votre raison d''abord", "Expliquez l''effet qu''elle produit", "N''ajoutez aucun autre argument"]',
   '[{"label": "Un seul argument", "icon": "NUMBER"}, {"label": "Lien logique", "icon": "STRUCTURE"}]',
   'Les pistes séparées permettent…',
   'la deuxième phrase prolonge la première, elle n''en ouvre pas d''autre'),
  -- EE3-C3-S3
  ('EE3-C3-S3',
   '["Partez de la durée courte", "Expliquez comment l''habitude agit", "Reliez vos deux phrases"]',
   '[{"label": "Mécanisme expliqué", "icon": "STRUCTURE"}, {"label": "Durée quotidienne", "icon": "TIME"}]',
   'Quinze minutes tiennent facilement dans…',
   'montrez comment ces minutes agissent, pas seulement qu''elles sont utiles'),
  -- EE3-C3-S4
  ('EE3-C3-S4',
   '["Donnez la raison en premier", "Décrivez sa conséquence directe", "Restez sur ce seul argument"]',
   '[{"label": "Conséquence directe", "icon": "STRUCTURE"}, {"label": "Rythme annuel", "icon": "TIME"}]',
   'Une visite annuelle permet de…',
   'élargir le sujet fait perdre le fil, restez sur votre raison'),
  -- EE3-C3-S5
  ('EE3-C3-S5',
   '["Décrivez ce que fait le bénévole", "Montrez ce que cela lui apporte", "Écartez votre expérience personnelle"]',
   '[{"label": "Étapes enchaînées", "icon": "STRUCTURE"}, {"label": "Sans récit personnel", "icon": "PERSON"}]',
   'En donnant quelques heures, un…',
   'reformuler trois fois la même idée ne remplace pas une explication'),
  -- EE3-C4-S1
  ('EE3-C4-S1',
   '["Choisissez une seule situation", "Situez le lieu et le moment", "Dites ce que cela a permis"]',
   '[{"label": "Situation unique", "icon": "NUMBER"}, {"label": "Lieu précis", "icon": "PLACE"}]',
   'Par exemple, la semaine dernière…',
   'un exemple vaut par ses détails, pas par sa longueur'),
  -- EE3-C4-S2
  ('EE3-C4-S2',
   '["Nommez un plat précis", "Donnez un prix ou une quantité", "Précisez quand c''était"]',
   '[{"label": "Chiffres concrets", "icon": "NUMBER"}, {"label": "Moment daté", "icon": "TIME"}]',
   'Par exemple, dimanche dernier, j''ai…',
   'un prix et une quantité rendent votre exemple imparable'),
  -- EE3-C4-S3
  ('EE3-C4-S3',
   '["Nommez la démarche exacte", "Dites le temps gagné", "Comparez avec le guichet"]',
   '[{"label": "Démarche nommée", "icon": "EXAMPLE"}, {"label": "Temps gagné", "icon": "TIME"}]',
   'Par exemple, j''ai renouvelé ma…',
   'chiffrer le temps gagné transforme l''idée en preuve'),
  -- EE3-C4-S4
  ('EE3-C4-S4',
   '["Racontez un problème précis", "Dites comment l''équipe s''est organisée", "Terminez par le résultat"]',
   '[{"label": "Situation identifiable", "icon": "EXAMPLE"}, {"label": "Rôle de chacun", "icon": "PERSON"}]',
   'Par exemple, dans mon service…',
   'une histoire avec un début et une fin convainc immédiatement'),
  -- EE3-C4-S5
  ('EE3-C4-S5',
   '["Situez l''exemple dans votre immeuble", "Indiquez depuis quand", "Décrivez un effet visible"]',
   '[{"label": "Échelle du quartier", "icon": "PLACE"}, {"label": "Effet observable", "icon": "EXAMPLE"}]',
   'Par exemple, dans mon immeuble…',
   'restez près de chez vous, la planète entière ne se vérifie pas'),
  -- EE3-C5-S1
  ('EE3-C5-S1',
   '["Écartez l''angle de la santé", "Trouvez un autre bénéfice", "Introduisez-le par un connecteur"]',
   '[{"label": "Angle nouveau", "icon": "STRUCTURE"}, {"label": "Connecteur d''ajout", "icon": "STRUCTURE"}]',
   'Par ailleurs, le sport apprend…',
   'changez de terrain : le second argument doit surprendre un peu'),
  -- EE3-C5-S2
  ('EE3-C5-S2',
   '["Laissez la pollution de côté", "Trouvez un avantage différent", "Ouvrez par un connecteur"]',
   '[{"label": "Autre angle", "icon": "STRUCTURE"}, {"label": "Ton du conseil", "icon": "TONE"}]',
   'En plus, dans le train…',
   'reformuler le premier argument ne fait pas avancer votre texte'),
  -- EE3-C5-S3
  ('EE3-C5-S3',
   '["Évitez la question des horaires", "Pensez à un autre usage", "Reliez par « ensuite »"]',
   '[{"label": "Angle inédit", "icon": "STRUCTURE"}, {"label": "Public concerné", "icon": "PERSON"}]',
   'Ensuite, la bibliothèque offrirait aux…',
   'demandez-vous à qui d''autre cette ouverture profiterait'),
  -- EE3-C5-S4
  ('EE3-C5-S4',
   '["Oubliez la question du prix", "Cherchez un autre bénéfice", "Annoncez-le par un connecteur"]',
   '[{"label": "Hors budget", "icon": "NUMBER"}, {"label": "Second argument", "icon": "STRUCTURE"}]',
   'D''autre part, faire réparer son…',
   'le prix est déjà dit, montrez ce qu''il ne couvre pas'),
  -- EE3-C5-S5
  ('EE3-C5-S5',
   '["Écartez le sujet des trajets", "Développez un bénéfice personnel", "Enchaînez vos deux phrases"]',
   '[{"label": "Autre aspect", "icon": "STRUCTURE"}, {"label": "Effet personnel", "icon": "PERSON"}]',
   'Ensuite, vingt minutes de marche…',
   'cherchez ce que la marche apporte une fois arrivé au bureau'),
  -- EE3-C6-S1
  ('EE3-C6-S1',
   '["Donnez un point fort chacun", "Utilisez les mêmes critères", "Nommez la différence décisive"]',
   '[{"label": "Deux options", "icon": "NUMBER"}, {"label": "Critères comparables", "icon": "STRUCTURE"}]',
   'À la maison, on gagne…',
   'comparer, c''est confronter, pas décrire les options l''une après l''autre'),
  -- EE3-C6-S2
  ('EE3-C6-S2',
   '["Choisissez un critère commun", "Opposez les deux solutions", "Terminez par la différence essentielle"]',
   '[{"label": "Points comparables", "icon": "STRUCTURE"}, {"label": "Deux solutions", "icon": "NUMBER"}]',
   'En ligne, le choix est…',
   'un même critère des deux côtés, et la comparaison devient claire'),
  -- EE3-C6-S3
  ('EE3-C6-S3',
   '["Partez du loyer identique", "Confrontez espace et trajet", "Dégagez la différence centrale"]',
   '[{"label": "Base commune", "icon": "NUMBER"}, {"label": "Différence centrale", "icon": "STRUCTURE"}]',
   'Le studio offre peu d''espace…',
   'à loyer égal, demandez-vous ce que chaque logement fait perdre'),
  -- EE3-C6-S4
  ('EE3-C6-S4',
   '["Décrivez chaque formule brièvement", "Comparez-les sur le même point", "Concluez par la différence principale"]',
   '[{"label": "Deux formules", "icon": "NUMBER"}, {"label": "Mise en relation", "icon": "STRUCTURE"}]',
   'En ligne, on suit le…',
   'n''oubliez pas de décrire la seconde formule aussi précisément'),
  -- EE3-C6-S5
  ('EE3-C6-S5',
   '["Donnez un avantage par option", "Ajoutez un inconvénient par option", "Finissez par la différence essentielle"]',
   '[{"label": "Avantage et inconvénient", "icon": "STRUCTURE"}, {"label": "Équilibre des deux", "icon": "NUMBER"}]',
   'Au marché, les légumes sont…',
   'n''oubliez pas les inconvénients : ils rendent la comparaison honnête'),
  -- EE3-C7-S1
  ('EE3-C7-S1',
   '["Rappelez votre opinion positive", "Reconnaissez une limite réelle", "Gardez votre position finale"]',
   '[{"label": "Concession assumée", "icon": "TONE"}, {"label": "Position maintenue", "icon": "STRUCTURE"}]',
   'Les réseaux sociaux me permettent…',
   'reconnaître une limite renforce votre avis au lieu de l''affaiblir'),
  -- EE3-C7-S2
  ('EE3-C7-S2',
   '["Défendez d''abord votre position", "Admettez un cas contraire", "Revenez à votre avis"]',
   '[{"label": "Cas contraire", "icon": "STRUCTURE"}, {"label": "Avis conservé", "icon": "TONE"}]',
   'Dans une ville moyenne, les…',
   'un « certes… mais » suffit à montrer votre nuance'),
  -- EE3-C7-S3
  ('EE3-C7-S3',
   '["Soutenez la régularité", "Signalez une limite concrète", "Terminez par votre conseil"]',
   '[{"label": "Réserve concrète", "icon": "STRUCTURE"}, {"label": "Ton bienveillant", "icon": "TONE"}]',
   'La régularité fait progresser bien…',
   'une limite précise vaut mieux qu''une réserve vague'),
  -- EE3-C7-S4
  ('EE3-C7-S4',
   '["Annoncez votre avis favorable", "Nommez un risque réel", "Montrez comment le limiter"]',
   '[{"label": "Risque nommé", "icon": "STRUCTURE"}, {"label": "Avis favorable", "icon": "TONE"}]',
   'Les horaires libres permettraient de…',
   'traiter l''objection après l''avoir posée est un vrai réflexe B2'),
  -- EE3-C7-S5
  ('EE3-C7-S5',
   '["Soutenez l''initiative d''abord", "Reconnaissez la contrainte pour les clients", "Redites votre position à la fin"]',
   '[{"label": "Contrainte reconnue", "icon": "STRUCTURE"}, {"label": "Ton mesuré", "icon": "TONE"}]',
   'Les bocaux consignés évitent des…',
   'finir sur votre position évite que la concession prenne le dessus'),
  -- EE3-C8-S1
  ('EE3-C8-S1',
   '["Posez votre argument", "Introduisez la conséquence par un connecteur", "Concluez en reprenant votre position"]',
   '[{"label": "Connecteurs logiques", "icon": "STRUCTURE"}, {"label": "Trois étapes", "icon": "NUMBER"}]',
   'Apprendre une langue dès le…',
   'un connecteur bien placé montre que vos idées s''enchaînent'),
  -- EE3-C8-S2
  ('EE3-C8-S2',
   '["Commencez par un argument", "Ajoutez sa conséquence", "Terminez par une phrase de conclusion"]',
   '[{"label": "Enchaînement marqué", "icon": "STRUCTURE"}, {"label": "Trois étapes", "icon": "NUMBER"}]',
   'Ce marché permet d''acheter des…',
   'une phrase de conclusion s''annonce toujours par un connecteur'),
  -- EE3-C8-S3
  ('EE3-C8-S3',
   '["Annoncez votre position", "Reliez vos deux idées", "Fermez par une conclusion"]',
   '[{"label": "Position puis idées", "icon": "STRUCTURE"}, {"label": "Deux arguments", "icon": "NUMBER"}]',
   'Je suis favorable à ce…',
   '« d''abord », « ensuite » guident le lecteur sans effort'),
  -- EE3-C8-S4
  ('EE3-C8-S4',
   '["Ouvrez par votre avis", "Numérotez vos idées par des connecteurs", "Réunissez-les dans la conclusion"]',
   '[{"label": "Ordre visible", "icon": "STRUCTURE"}, {"label": "Conclusion cohérente", "icon": "STRUCTURE"}]',
   'Je trouve cette formule particulièrement…',
   'la conclusion réunit vos idées, elle n''en répète aucune'),
  -- EE3-C8-S5
  ('EE3-C8-S5',
   '["Annoncez votre position", "Variez vos connecteurs", "Concluez avec des mots nouveaux"]',
   '[{"label": "Connecteurs variés", "icon": "STRUCTURE"}, {"label": "Quatre étapes", "icon": "NUMBER"}]',
   'Cette proposition mérite d''être…',
   'terminer par la même phrase qu''au début donne une impression d''inachevé')
) AS v(code, checklist, constraint_tags, answer_starter, tip)
WHERE p.code = v.code;
