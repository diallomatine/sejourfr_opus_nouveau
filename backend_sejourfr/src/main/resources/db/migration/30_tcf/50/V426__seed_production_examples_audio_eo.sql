-- ============================================================================
-- V426 : Nouveaux exemples-modèles EO réalistes
-- Même format que V425, avec attribution correcte des voix selon le genre.
-- Règle SSML : voix féminine pour personnage féminin, voix masculine pour personnage masculin.
-- ============================================================================

DO $$
DECLARE
eo_t1 UUID;
eo_t2 UUID;
eo_t3 UUID;
BEGIN
SELECT id INTO eo_t1 FROM production_tasks
WHERE epreuve = 'TCF_EO' AND tache_numero = 1 AND niveau_cible = 'B1' LIMIT 1;
SELECT id INTO eo_t2 FROM production_tasks
WHERE epreuve = 'TCF_EO' AND tache_numero = 2 AND niveau_cible = 'B1' LIMIT 1;
SELECT id INTO eo_t3 FROM production_tasks
WHERE epreuve = 'TCF_EO' AND tache_numero = 3 AND niveau_cible = 'B1' LIMIT 1;

-- ========================================================================
-- EO TÂCHE 1
-- ========================================================================
INSERT INTO production_examples (
    task_id, titre, resume, contenu, explications, ssml_text, plan_points, niveau_indicatif, display_order
) VALUES (
    eo_t1,
    E'Entretien dirigé : un chauffeur-livreur se présente',
    E'Un échange réaliste avec une présentation longue : identité, famille, arrivée en France, travail, quotidien, loisirs et projets.',
    E'[Examinateur] Bonjour. Pour commencer, pouvez-vous vous présenter de manière assez complète, s''il vous plaît ?
[Candidat] Bonjour Madame. Oui, bien sûr. Je m''appelle Mamadou Diarra, j''ai 42 ans et je suis malien. Je suis né à Bamako, où j''ai grandi avec mes parents, mes deux frères et ma petite sœur. Aujourd''hui, j''habite à Toulouse avec ma femme et nos trois enfants. Mon plus grand fils est au collège, ma fille est à l''école primaire et le dernier est encore petit. Je vis en France depuis huit ans. Au début, je suis venu pour travailler, mais maintenant ma vie est vraiment ici : ma famille, mon travail, mes amis et les projets de mes enfants sont en France.
[Examinateur] Merci. Pouvez-vous parler un peu de votre parcours professionnel ?
[Candidat] Dans mon pays, j''ai travaillé comme chauffeur-livreur pendant plusieurs années. J''aimais ce métier parce que je rencontrais beaucoup de personnes et je connaissais bien la ville. En arrivant en France, j''ai d''abord fait des petits emplois : manutention, nettoyage et aide dans un entrepôt. Ce n''était pas toujours simple, surtout à cause de la langue et des horaires. Ensuite, j''ai passé une formation courte en logistique, et aujourd''hui je travaille dans une entreprise de transport. Je prépare les commandes et parfois je conduis un petit véhicule pour livrer des colis.
[Examinateur] Comment se passe une journée normale pour vous ?
[Candidat] Ma journée commence tôt. Je me lève vers cinq heures trente, je prends un café, puis je pars au travail. Je commence souvent à sept heures. Le matin, il faut vérifier les commandes, charger les cartons et respecter les horaires de livraison. À midi, je mange avec mes collègues. L''après-midi, je termine les livraisons ou je range l''entrepôt. Le soir, je rentre à la maison, je passe du temps avec les enfants et je parle avec ma femme de notre journée. Quand je suis trop fatigué, je me repose un peu, mais j''essaie toujours d''aider à la maison.
[Examinateur] Qu''est-ce que vous aimez faire pendant votre temps libre ?
[Candidat] Le week-end, j''aime beaucoup jouer au football avec des amis. Même si je ne suis plus très jeune, ça me fait du bien de courir et de rire avec les autres. J''aime aussi regarder des matchs à la télévision avec mon fils. En famille, nous aimons nous promener au bord de la Garonne ou aller au marché. J''aime cuisiner des plats de chez moi, par exemple le riz au poulet, et inviter des amis à la maison.
[Examinateur] Et quels sont vos projets pour les prochaines années ?
[Candidat] Mon projet principal, c''est de stabiliser encore plus ma situation. J''aimerais obtenir un CDI plus solide ou évoluer vers un poste de responsable d''équipe, parce que j''ai de l''expérience et je connais bien le travail. Je veux aussi continuer à améliorer mon français, surtout pour mieux écrire les mails professionnels. Enfin, je prépare le TCF parce que je souhaite demander la nationalité française. Pour moi, c''est important : je respecte ce pays, mes enfants grandissent ici, et je veux participer pleinement à la vie française.
[Examinateur] Merci beaucoup, votre présentation est claire.
[Candidat] Merci Madame.',
    E'Ce modèle propose une première réponse plus longue et plus naturelle. Le candidat ne donne pas seulement son nom : il parle de son origine, de sa famille, de sa ville actuelle, de son arrivée en France et de son installation. Ensuite, il développe son parcours professionnel, son quotidien, ses loisirs et ses projets. La voix SSML du candidat est masculine car Mamadou est un homme.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Bonjour. Pour commencer, pouvez-vous vous présenter de manière assez complète, s''il vous plaît ?</prosody><break time="700ms"/></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour Madame. Oui, bien sûr. Je m''appelle Mamadou Diarra, j''ai 42 ans et je suis malien. Je suis né à Bamako, où j''ai grandi avec mes parents, mes deux frères et ma petite sœur. Aujourd''hui, j''habite à Toulouse avec ma femme et nos trois enfants. Mon plus grand fils est au collège, ma fille est à l''école primaire et le dernier est encore petit. Je vis en France depuis huit ans. Au début, je suis venu pour travailler, mais maintenant ma vie est vraiment ici : ma famille, mon travail, mes amis et les projets de mes enfants sont en France.</prosody><break time="700ms"/></voice><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Merci. Pouvez-vous parler un peu de votre parcours professionnel ?</prosody><break time="600ms"/></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Dans mon pays, j''ai travaillé comme chauffeur-livreur pendant plusieurs années. J''aimais ce métier parce que je rencontrais beaucoup de personnes et je connaissais bien la ville. En arrivant en France, j''ai d''abord fait des petits emplois : manutention, nettoyage et aide dans un entrepôt. Ce n''était pas toujours simple, surtout à cause de la langue et des horaires. Ensuite, j''ai passé une formation courte en logistique, et aujourd''hui je travaille dans une entreprise de transport. Je prépare les commandes et parfois je conduis un petit véhicule pour livrer des colis.</prosody><break time="700ms"/></voice><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment se passe une journée normale pour vous ?</prosody><break time="600ms"/></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Ma journée commence tôt. Je me lève vers cinq heures trente, je prends un café, puis je pars au travail. Je commence souvent à sept heures. Le matin, il faut vérifier les commandes, charger les cartons et respecter les horaires de livraison. À midi, je mange avec mes collègues. L''après-midi, je termine les livraisons ou je range l''entrepôt. Le soir, je rentre à la maison, je passe du temps avec les enfants et je parle avec ma femme de notre journée. Quand je suis trop fatigué, je me repose un peu, mais j''essaie toujours d''aider à la maison.</prosody><break time="700ms"/></voice><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Qu''est-ce que vous aimez faire pendant votre temps libre ?</prosody><break time="600ms"/></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Le week-end, j''aime beaucoup jouer au football avec des amis. Même si je ne suis plus très jeune, ça me fait du bien de courir et de rire avec les autres. J''aime aussi regarder des matchs à la télévision avec mon fils. En famille, nous aimons nous promener au bord de la Garonne ou aller au marché. J''aime cuisiner des plats de chez moi, par exemple le riz au poulet, et inviter des amis à la maison.</prosody><break time="700ms"/></voice><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Et quels sont vos projets pour les prochaines années ?</prosody><break time="600ms"/></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mon projet principal, c''est de stabiliser encore plus ma situation. J''aimerais obtenir un CDI plus solide ou évoluer vers un poste de responsable d''équipe, parce que j''ai de l''expérience et je connais bien le travail. Je veux aussi continuer à améliorer mon français, surtout pour mieux écrire les mails professionnels. Enfin, je prépare le TCF parce que je souhaite demander la nationalité française. Pour moi, c''est important : je respecte ce pays, mes enfants grandissent ici, et je veux participer pleinement à la vie française.</prosody><break time="700ms"/></voice><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Merci beaucoup, votre présentation est claire.</prosody><break time="500ms"/></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Merci Madame.</prosody></voice></speak>',
    '["Présentation longue : identité, origine, famille, ville", "Arrivée en France et installation", "Parcours professionnel", "Journée quotidienne", "Loisirs et vie de famille", "Projets professionnels", "Projet de nationalité française"]'::jsonb,
    'B1', 2
);


-- ========================================================================
-- EO TÂCHE 2
-- ========================================================================
INSERT INTO production_examples (
    task_id, titre, resume, contenu, explications, ssml_text, plan_points, niveau_indicatif, display_order
) VALUES (
    eo_t2,
    E'Jeu de rôle : inscrire son enfant à la natation',
    E'La candidate appelle le service des sports pour obtenir des informations et réserver une place.',
    E'[Agent] Service des sports de la mairie, bonjour.
[Candidat] Bonjour Monsieur. Je vous appelle parce que je voudrais inscrire ma fille à une activité sportive pendant l''année. Elle a dix ans et elle aimerait faire de la natation. Est-ce que vous pouvez me donner des informations, s''il vous plaît ?
[Agent] Oui, bien sûr. Nous avons des cours de natation pour les enfants le mercredi et le samedi. Votre fille sait déjà nager un peu ?
[Candidat] Oui, elle sait nager un peu, mais elle manque de confiance. Elle peut traverser une petite piscine, mais elle a encore peur dans le grand bassin.
[Agent] Dans ce cas, le groupe débutant avancé peut être adapté. Les enfants apprennent à mieux respirer, à flotter et à nager plus longtemps.
[Candidat] D''accord. Quels sont les horaires disponibles pour ce groupe ?
[Agent] Il y a un cours le mercredi à quinze heures et un autre le samedi à dix heures trente.
[Candidat] Le samedi m''intéresse, parce que je travaille le mercredi. Le cours dure combien de temps ?
[Agent] Le cours dure quarante-cinq minutes.
[Candidat] Très bien. Et combien coûte l''inscription pour l''année ?
[Agent] Pour les habitants de la commune, c''est cent vingt euros pour l''année. Pour les personnes qui habitent dans une autre ville, c''est cent cinquante euros.
[Candidat] Nous habitons dans la commune. Est-ce qu''il faut apporter un justificatif de domicile ?
[Agent] Oui, il faut une pièce d''identité du parent, un justificatif de domicile et un certificat médical pour l''enfant.
[Candidat] D''accord. Est-ce que je peux faire l''inscription en ligne ou je dois venir à la mairie ?
[Agent] Vous pouvez commencer le dossier en ligne, mais il faut ensuite venir déposer le certificat médical à l''accueil.
[Candidat] Très bien. Est-ce qu''il reste encore des places pour le samedi matin ?
[Agent] Oui, il reste trois places pour le moment.
[Candidat] Alors je préfère réserver une place si c''est possible. Ma fille s''appelle Inès Benyamina.
[Agent] Je peux noter son nom, mais la place sera confirmée seulement quand le dossier sera complet.
[Candidat] Je comprends. Je vais remplir le dossier aujourd''hui et passer demain à la mairie avec les documents.
[Agent] Très bien Madame. L''accueil est ouvert de neuf heures à dix-sept heures.
[Candidat] Merci beaucoup pour vos informations. Bonne journée Monsieur.
[Agent] Bonne journée Madame.',
    E'Ce modèle correspond bien à la tâche 2 : la candidate explique son besoin, pose des questions concrètes et confirme les informations utiles. Elle demande les horaires, le prix, les documents, la possibilité de réserver et la procédure d''inscription. La voix SSML de la candidate est féminine car la personne qui parle est une femme.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-HenriNeural"><prosody rate="0.95">Service des sports de la mairie, bonjour.</prosody><break time="600ms"/></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Bonjour Monsieur. Je vous appelle parce que je voudrais inscrire ma fille à une activité sportive pendant l''année. Elle a dix ans et elle aimerait faire de la natation. Est-ce que vous pouvez me donner des informations, s''il vous plaît ?</prosody><break time="600ms"/></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, bien sûr. Nous avons des cours de natation pour les enfants le mercredi et le samedi. Votre fille sait déjà nager un peu ?</prosody><break time="600ms"/></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, elle sait nager un peu, mais elle manque de confiance. Elle peut traverser une petite piscine, mais elle a encore peur dans le grand bassin.</prosody><break time="600ms"/></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Dans ce cas, le groupe débutant avancé peut être adapté. Les enfants apprennent à mieux respirer, à flotter et à nager plus longtemps.</prosody><break time="600ms"/></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">D''accord. Quels sont les horaires disponibles pour ce groupe ?</prosody><break time="600ms"/></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Il y a un cours le mercredi à quinze heures et un autre le samedi à dix heures trente.</prosody><break time="600ms"/></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Le samedi m''intéresse, parce que je travaille le mercredi. Le cours dure combien de temps ?</prosody><break time="600ms"/></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Le cours dure quarante-cinq minutes.</prosody><break time="600ms"/></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Très bien. Et combien coûte l''inscription pour l''année ?</prosody><break time="600ms"/></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pour les habitants de la commune, c''est cent vingt euros pour l''année. Pour les personnes qui habitent dans une autre ville, c''est cent cinquante euros.</prosody><break time="600ms"/></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Nous habitons dans la commune. Est-ce qu''il faut apporter un justificatif de domicile ?</prosody><break time="600ms"/></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, il faut une pièce d''identité du parent, un justificatif de domicile et un certificat médical pour l''enfant.</prosody><break time="600ms"/></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">D''accord. Est-ce que je peux faire l''inscription en ligne ou je dois venir à la mairie ?</prosody><break time="600ms"/></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous pouvez commencer le dossier en ligne, mais il faut ensuite venir déposer le certificat médical à l''accueil.</prosody><break time="600ms"/></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Très bien. Est-ce qu''il reste encore des places pour le samedi matin ?</prosody><break time="600ms"/></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, il reste trois places pour le moment.</prosody><break time="600ms"/></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Alors je préfère réserver une place si c''est possible. Ma fille s''appelle Inès Benyamina.</prosody><break time="600ms"/></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je peux noter son nom, mais la place sera confirmée seulement quand le dossier sera complet.</prosody><break time="600ms"/></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Je comprends. Je vais remplir le dossier aujourd''hui et passer demain à la mairie avec les documents.</prosody><break time="500ms"/></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Très bien Madame. L''accueil est ouvert de neuf heures à dix-sept heures.</prosody><break time="500ms"/></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Merci beaucoup pour vos informations. Bonne journée Monsieur.</prosody><break time="500ms"/></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonne journée Madame.</prosody></voice></speak>',
    '["Ouverture polie", "Objet de l’appel", "Âge et niveau de l’enfant", "Horaires", "Durée du cours", "Tarif", "Documents nécessaires", "Inscription en ligne", "Réservation et confirmation"]'::jsonb,
    'B1', 2
);


-- ========================================================================
-- EO TÂCHE 3
-- ========================================================================
INSERT INTO production_examples (
    task_id, titre, resume, contenu, explications, ssml_text, plan_points, niveau_indicatif, display_order
) VALUES (
    eo_t3,
    E'Donner son opinion : le téléphone chez les enfants',
    E'Un monologue argumenté sur les avantages, les risques et les règles à mettre en place.',
    E'[Candidat] Aujourd''hui, je vais parler d''un sujet important : est-ce qu''il faut limiter l''utilisation du téléphone chez les enfants ? À mon avis, oui, il faut mettre des limites, mais il ne faut pas interdire complètement le téléphone.

D''abord, le téléphone peut être utile. Par exemple, un enfant peut appeler ses parents s''il a un problème, s''il sort de l''école ou s''il prend le bus. Il peut aussi utiliser certaines applications pour apprendre une langue, faire des exercices ou chercher une information simple. Donc, le téléphone n''est pas seulement un objet pour jouer.

Mais il y a aussi beaucoup de risques. Le premier risque, c''est le temps passé devant l''écran. Certains enfants regardent des vidéos pendant des heures, jouent trop longtemps ou dorment plus tard à cause du téléphone. Cela peut fatiguer les yeux, diminuer la concentration et créer des disputes à la maison.

Le deuxième risque concerne les réseaux sociaux et les contenus dangereux. Un enfant ne sait pas toujours reconnaître une fausse information, une publicité ou une personne mal intentionnée. Les parents doivent donc accompagner leurs enfants et expliquer les règles de sécurité.

Pour moi, la meilleure solution est de fixer un cadre clair. Par exemple, pas de téléphone pendant les repas, pas de téléphone dans la chambre la nuit, et un temps limité après les devoirs. Les parents doivent aussi montrer l''exemple, parce qu''un enfant comprend mieux les règles si les adultes les respectent aussi.

Pour conclure, je pense que le téléphone peut être utile pour les enfants, mais il doit rester contrôlé. Il faut apprendre aux enfants à l''utiliser correctement, avec des horaires, des règles et un vrai dialogue avec les parents.',
    E'Ce modèle convient à la tâche 3 : il donne une opinion claire, nuance le sujet, présente des avantages, des risques et une solution équilibrée. Le style reste pratique et accessible pour le TCF IRN, avec des connecteurs simples. La voix SSML est féminine pour proposer aussi un modèle oral porté par une femme.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Aujourd''hui, je vais parler d''un sujet important : est-ce qu''il faut limiter l''utilisation du téléphone chez les enfants ? À mon avis, oui, il faut mettre des limites, mais il ne faut pas interdire complètement le téléphone.<break time="600ms"/>D''abord, le téléphone peut être utile. Par exemple, un enfant peut appeler ses parents s''il a un problème, s''il sort de l''école ou s''il prend le bus. Il peut aussi utiliser certaines applications pour apprendre une langue, faire des exercices ou chercher une information simple. Donc, le téléphone n''est pas seulement un objet pour jouer.<break time="600ms"/>Mais il y a aussi beaucoup de risques. Le premier risque, c''est le temps passé devant l''écran. Certains enfants regardent des vidéos pendant des heures, jouent trop longtemps ou dorment plus tard à cause du téléphone. Cela peut fatiguer les yeux, diminuer la concentration et créer des disputes à la maison.<break time="600ms"/>Le deuxième risque concerne les réseaux sociaux et les contenus dangereux. Un enfant ne sait pas toujours reconnaître une fausse information, une publicité ou une personne mal intentionnée. Les parents doivent donc accompagner leurs enfants et expliquer les règles de sécurité.<break time="600ms"/>Pour moi, la meilleure solution est de fixer un cadre clair. Par exemple, pas de téléphone pendant les repas, pas de téléphone dans la chambre la nuit, et un temps limité après les devoirs. Les parents doivent aussi montrer l''exemple, parce qu''un enfant comprend mieux les règles si les adultes les respectent aussi.<break time="600ms"/>Pour conclure, je pense que le téléphone peut être utile pour les enfants, mais il doit rester contrôlé. Il faut apprendre aux enfants à l''utiliser correctement, avec des horaires, des règles et un vrai dialogue avec les parents.</prosody></voice></speak>',
    '["Introduction + avis", "Avantage : sécurité et apprentissage", "Risque : temps d’écran", "Risque : réseaux sociaux", "Solution : règles claires", "Rôle des parents", "Conclusion équilibrée"]'::jsonb,
    'B1', 2
);

END $$;
