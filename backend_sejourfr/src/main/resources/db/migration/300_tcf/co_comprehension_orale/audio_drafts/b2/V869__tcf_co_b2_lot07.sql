-- ============================================================================
-- V869 — TCF CO B2 — lot 07 (thème : exposé associatif)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B2), format C : prises de parole longues (~120-200 mots)
-- dans la vie associative (assemblée générale, forum des associations, accueil
-- de bénévoles, restitution d''enquête, bilan de projet) + question implicite
-- (rôle du locuteur, intention, idée principale, conséquence non dite).
-- Table audio_question_draft. status='TEXT_VALIDATED', colonnes audio NULL
-- (remplies par le batch admin Azure). Contenu 100% original, situations inventées.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-c007-1000-0000-000000000001', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonsoir à toutes et à tous. Comme chaque année à la même époque, c''est à moi que revient la partie la moins poétique de notre assemblée générale. Rassurez-vous, je serai bref. Cette saison, notre club de randonnée de Pau a encaissé onze mille quatre cents euros de cotisations, soit trois cents de plus que l''an dernier. En face, les dépenses ont grimpé : la location du minibus a augmenté de douze pour cent, et l''assurance de huit. Résultat, l''exercice se termine avec un excédent de cent soixante euros seulement, contre près de mille auparavant. Je tiens les justificatifs et le registre des comptes à la disposition de chacun, comme la loi m''y oblige. Avant de céder la parole à notre présidente, qui vous parlera des projets, je vous invite à voter dans un instant l''approbation de ces comptes. Sans ce vote, aucune dépense nouvelle ne pourra être engagée.

Quelle est la fonction du locuteur au sein de l''association ?

A. Il préside l''association et décide des projets de la saison.
B. Il est l''expert-comptable extérieur engagé par le club.
C. Il est le trésorier chargé de présenter les comptes annuels.
D. Il est le secrétaire chargé de rédiger le compte rendu de séance.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonsoir à toutes et à tous. Comme chaque année à la même époque, c''est à moi que revient la partie la moins poétique de notre assemblée générale. Rassurez-vous, je serai bref. Cette saison, notre club de randonnée de Pau a encaissé onze mille quatre cents euros de cotisations, soit trois cents de plus que l''an dernier. En face, les dépenses ont grimpé : la location du minibus a augmenté de douze pour cent, et l''assurance de huit. Résultat, l''exercice se termine avec un excédent de cent soixante euros seulement, contre près de mille auparavant. Je tiens les justificatifs et le registre des comptes à la disposition de chacun, comme la loi m''y oblige. Avant de céder la parole à notre présidente, qui vous parlera des projets, je vous invite à voter dans un instant l''approbation de ces comptes. Sans ce vote, aucune dépense nouvelle ne pourra être engagée.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est la fonction du locuteur au sein de l''association ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il préside l''association et décide des projets de la saison.<break time="700ms"/>B.<break time="300ms"/>Il est l''expert-comptable extérieur engagé par le club.<break time="700ms"/>C.<break time="300ms"/>Il est le trésorier chargé de présenter les comptes annuels.<break time="700ms"/>D.<break time="300ms"/>Il est le secrétaire chargé de rédiger le compte rendu de séance.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le rôle n''est jamais nommé : il faut **inférer la fonction à partir d''un faisceau d''indices lexicaux** (mécanisme B2 d''inférence de rôle) — « encaissé les cotisations », « le registre des comptes », « l''approbation de ces comptes », tâches typiques d''un trésorier : C est correcte. A inverse les rôles : le locuteur annonce lui-même que « notre présidente » parlera ensuite des projets — c''est elle qui occupe cette fonction. B contredit les marques d''appartenance (« notre club », « notre assemblée générale ») : un expert-comptable extérieur ne dirait pas « nous » et ne ferait pas voter l''assemblée. D confond deux fonctions du bureau : rien dans l''exposé n''évoque la rédaction d''un compte rendu, le locuteur manipule des chiffres et des justificatifs, pas des procès-verbaux.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c007-1000-0000-000000000002', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Mes chers amis, après neuf années à la présidence de notre chorale, le moment est venu pour moi de passer la main. Je pourrais occuper cette tribune à remercier chacun d''entre vous, et croyez bien que le cœur y est. Mais je préfère employer ces quelques minutes autrement. Lorsque j''ai lancé un appel à candidatures pour le prochain bureau, au mois de mars, je n''ai reçu aucune réponse. Aucune. Or une chorale de quatre-vingt-dix voix ne tient pas seulement par ses répétitions du mardi : il faut négocier les salles, monter les dossiers de subvention, organiser les concerts d''été. Si personne ne reprend ces tâches, elles ne se feront plus, c''est aussi simple que cela. Je vois dans cette salle des trentenaires pleins d''idées qui n''osent pas se proposer, par modestie sans doute. Qu''ils se rassurent : je resterai disponible toute la première année pour transmettre les dossiers. L''élection a lieu dans une heure.

Quelle est l''intention principale de la locutrice ?

A. Inciter les adhérents à se porter candidats au bureau de l''association.
B. Remercier les choristes pour les neuf années écoulées.
C. Annoncer l''annulation des concerts d''été de la chorale.
D. Justifier les raisons personnelles de son départ de la présidence.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Mes chers amis, après neuf années à la présidence de notre chorale, le moment est venu pour moi de passer la main. Je pourrais occuper cette tribune à remercier chacun d''entre vous, et croyez bien que le cœur y est. Mais je préfère employer ces quelques minutes autrement. Lorsque j''ai lancé un appel à candidatures pour le prochain bureau, au mois de mars, je n''ai reçu aucune réponse. Aucune. Or une chorale de quatre-vingt-dix voix ne tient pas seulement par ses répétitions du mardi : il faut négocier les salles, monter les dossiers de subvention, organiser les concerts d''été. Si personne ne reprend ces tâches, elles ne se feront plus, c''est aussi simple que cela. Je vois dans cette salle des trentenaires pleins d''idées qui n''osent pas se proposer, par modestie sans doute. Qu''ils se rassurent : je resterai disponible toute la première année pour transmettre les dossiers. L''élection a lieu dans une heure.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est l''intention principale de la locutrice ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Inciter les adhérents à se porter candidats au bureau de l''association.<break time="700ms"/>B.<break time="300ms"/>Remercier les choristes pour les neuf années écoulées.<break time="700ms"/>C.<break time="300ms"/>Annoncer l''annulation des concerts d''été de la chorale.<break time="700ms"/>D.<break time="300ms"/>Justifier les raisons personnelles de son départ de la présidence.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Tout le discours converge vers l''appel à candidatures : zéro réponse en mars, liste des tâches qui resteraient orphelines, encouragement direct aux « trentenaires pleins d''idées » et promesse d''accompagnement — A reformule cette **intention d''inciter à l''engagement** (mécanisme B2 d''inférence d''intention du locuteur). B reprend ce que la locutrice **écarte explicitement** (« je préfère employer ces quelques minutes autrement ») : c''est le contenu attendu d''un discours d''adieu, pas celui-ci. C transforme une **hypothèse conditionnelle** (« si personne ne reprend ces tâches, elles ne se feront plus ») en annonce ferme — piège sur la valeur du conditionnel d''avertissement. D invente un contenu absent : elle annonce son départ en une phrase mais n''en justifie jamais les raisons personnelles.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c007-1000-0000-000000000003', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour à tous, et merci aux organisateurs de ce forum de m''accorder dix minutes. Je représente Coup de Pouce Cartable, qui accompagne chaque soir une soixantaine d''écoliers de Tarbes dans leurs devoirs. Quand je tiens ce stand, on me dit souvent : vous devez manquer de monde. Eh bien, détrompez-vous. Chaque mois de septembre, une quarantaine de personnes s''inscrivent, enthousiastes. À la Toussaint, la moitié a disparu ; en janvier, il en reste une douzaine. Et c''est là tout notre problème. Un enfant de huit ans qui change d''accompagnateur tous les quinze jours cesse de progresser, parce que la confiance repart de zéro à chaque fois. Alors ce soir, je ne cherche pas quarante volontaires. J''en cherche dix, peut-être quinze, capables de promettre une heure par semaine, la même, jusqu''au mois de juin. Réfléchissez avant de signer ; mais si vous signez, tenez. C''est tout ce que nos élèves demandent.

Quel est le message essentiel de ce locuteur ?

A. L''association manque cruellement de volontaires à chaque rentrée.
B. Les écoliers de la ville rencontrent des difficultés croissantes.
C. L''association va réduire le nombre d''enfants accompagnés.
D. Quelques bénévoles assidus valent mieux qu''un grand nombre d''inscrits irréguliers.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour à tous, et merci aux organisateurs de ce forum de m''accorder dix minutes. Je représente Coup de Pouce Cartable, qui accompagne chaque soir une soixantaine d''écoliers de Tarbes dans leurs devoirs. Quand je tiens ce stand, on me dit souvent : vous devez manquer de monde. Eh bien, détrompez-vous. Chaque mois de septembre, une quarantaine de personnes s''inscrivent, enthousiastes. À la Toussaint, la moitié a disparu ; en janvier, il en reste une douzaine. Et c''est là tout notre problème. Un enfant de huit ans qui change d''accompagnateur tous les quinze jours cesse de progresser, parce que la confiance repart de zéro à chaque fois. Alors ce soir, je ne cherche pas quarante volontaires. J''en cherche dix, peut-être quinze, capables de promettre une heure par semaine, la même, jusqu''au mois de juin. Réfléchissez avant de signer ; mais si vous signez, tenez. C''est tout ce que nos élèves demandent.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel est le message essentiel de ce locuteur ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>L''association manque cruellement de volontaires à chaque rentrée.<break time="700ms"/>B.<break time="300ms"/>Les écoliers de la ville rencontrent des difficultés croissantes.<break time="700ms"/>C.<break time="300ms"/>L''association va réduire le nombre d''enfants accompagnés.<break time="700ms"/>D.<break time="300ms"/>Quelques bénévoles assidus valent mieux qu''un grand nombre d''inscrits irréguliers.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le locuteur construit une **concession argumentative** (« détrompez-vous… je ne cherche pas quarante volontaires, j''en cherche dix… capables de promettre une heure par semaine, la même ») : le problème n''est pas la quantité mais la constance — D synthétise cette idée principale. A reprend exactement **l''idée reçue que le locuteur réfute** (« on me dit souvent : vous devez manquer de monde. Eh bien, détrompez-vous ») : une quarantaine de personnes s''inscrivent chaque septembre. B confond le **thème** (l''aide aux devoirs) et le **propos** : rien n''indique que les difficultés des écoliers augmentent, c''est la rotation des bénévoles qui freine leurs progrès. C invente une conséquence jamais annoncée : il appelle à un engagement régulier, il ne réduit pas l''activité.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c007-1000-0000-000000000004', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonsoir à toutes et à tous. Je vous présente ce soir le projet que le conseil d''administration soumettra au vote tout à l''heure. Depuis deux ans, les enseignantes des deux écoles voisines nous demandent d''accueillir leurs classes dans nos jardins partagés. Le projet est désormais prêt : de mars à octobre, les élèves viendraient deux matinées par semaine, le mardi et le vendredi, découvrir les semis, le compost et la récolte. Une animatrice diplômée, financée par la mairie de Colmar, encadrerait les séances ; notre association ne débourserait donc pas un centime. Je sais que plusieurs d''entre vous jardinent justement en semaine, le matin, quand les parcelles sont calmes. Le conseil en a longuement discuté : les allées centrales et la serre seraient réservées aux enfants pendant ces créneaux, et l''arrosage collectif serait décalé en fin de journée. Chacun mesurera ce que cela implique pour ses habitudes. Le vote est ouvert dans vingt minutes ; j''espère sincèrement que ce projet vous enthousiasmera autant que nous.

Si le projet est adopté, qu''est-ce qui changera pour les adhérents ?

A. Ils devront payer une cotisation plus élevée pour financer l''animatrice.
B. Ils devront adapter leurs habitudes de jardinage certains matins de la semaine.
C. Ils devront encadrer eux-mêmes les classes des écoles voisines.
D. Ils perdront définitivement l''accès à la serre et aux allées centrales.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonsoir à toutes et à tous. Je vous présente ce soir le projet que le conseil d''administration soumettra au vote tout à l''heure. Depuis deux ans, les enseignantes des deux écoles voisines nous demandent d''accueillir leurs classes dans nos jardins partagés. Le projet est désormais prêt : de mars à octobre, les élèves viendraient deux matinées par semaine, le mardi et le vendredi, découvrir les semis, le compost et la récolte. Une animatrice diplômée, financée par la mairie de Colmar, encadrerait les séances ; notre association ne débourserait donc pas un centime. Je sais que plusieurs d''entre vous jardinent justement en semaine, le matin, quand les parcelles sont calmes. Le conseil en a longuement discuté : les allées centrales et la serre seraient réservées aux enfants pendant ces créneaux, et l''arrosage collectif serait décalé en fin de journée. Chacun mesurera ce que cela implique pour ses habitudes. Le vote est ouvert dans vingt minutes ; j''espère sincèrement que ce projet vous enthousiasmera autant que nous.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Si le projet est adopté, qu''est-ce qui changera pour les adhérents ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ils devront payer une cotisation plus élevée pour financer l''animatrice.<break time="700ms"/>B.<break time="300ms"/>Ils devront adapter leurs habitudes de jardinage certains matins de la semaine.<break time="700ms"/>C.<break time="300ms"/>Ils devront encadrer eux-mêmes les classes des écoles voisines.<break time="700ms"/>D.<break time="300ms"/>Ils perdront définitivement l''accès à la serre et aux allées centrales.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La conséquence n''est jamais formulée directement : il faut **relier deux informations pour déduire une conséquence non dite** (mécanisme B2 d''implication) — les adhérents « jardinent justement en semaine, le matin » et ces mêmes créneaux seraient réservés aux enfants, d''où la clé « chacun mesurera ce que cela implique pour ses habitudes » : B est correcte. A contredit un point explicite : l''animatrice est « financée par la mairie », l''association « ne débourserait pas un centime » — piège sur la source du financement. C confond les acteurs : c''est l''animatrice diplômée qui « encadrerait les séances », pas les adhérents. D transforme une **restriction ponctuelle** (« pendant ces créneaux », deux matinées de mars à octobre) en perte définitive — piège classique d''exagération de la portée.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c007-1000-0000-000000000005', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour à tous. Au printemps, le bureau m''a confié l''analyse du questionnaire envoyé aux adhérents qui n''ont pas renouvelé leur inscription à notre club de gymnastique de Lorient. Cent quarante-deux personnes ont répondu, ce qui est considérable. Voici ce que disent les chiffres. Beaucoup d''entre nous pensaient que la hausse du tarif, l''an dernier, expliquait les départs. Or, seuls neuf pour cent des répondants la mentionnent, et la plupart ajoutent même que nos prix restent inférieurs à ceux des salles privées. En revanche, près de deux tiers citent la même difficulté : tous nos cours adultes ont lieu entre dix-sept heures trente et dix-neuf heures, un créneau impossible pour ceux qui terminent leur travail à dix-huit heures ou récupèrent leurs enfants. Quatorze pour cent évoquent un déménagement, et le reste des motifs est dispersé. Je livre ces résultats sans recommandation, ce n''est pas mon rôle ; mais je crois que chacun voit où se situe le vrai chantier.

Que révèle principalement cette enquête ?

A. Les tarifs du club ont fait fuir la majorité des adhérents.
B. Les adhérents préfèrent désormais les salles de sport privées.
C. Les horaires des cours sont la cause principale des départs.
D. Les déménagements expliquent l''essentiel des non-renouvellements.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour à tous. Au printemps, le bureau m''a confié l''analyse du questionnaire envoyé aux adhérents qui n''ont pas renouvelé leur inscription à notre club de gymnastique de Lorient. Cent quarante-deux personnes ont répondu, ce qui est considérable. Voici ce que disent les chiffres. Beaucoup d''entre nous pensaient que la hausse du tarif, l''an dernier, expliquait les départs. Or, seuls neuf pour cent des répondants la mentionnent, et la plupart ajoutent même que nos prix restent inférieurs à ceux des salles privées. En revanche, près de deux tiers citent la même difficulté : tous nos cours adultes ont lieu entre dix-sept heures trente et dix-neuf heures, un créneau impossible pour ceux qui terminent leur travail à dix-huit heures ou récupèrent leurs enfants. Quatorze pour cent évoquent un déménagement, et le reste des motifs est dispersé. Je livre ces résultats sans recommandation, ce n''est pas mon rôle ; mais je crois que chacun voit où se situe le vrai chantier.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que révèle principalement cette enquête ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Les tarifs du club ont fait fuir la majorité des adhérents.<break time="700ms"/>B.<break time="300ms"/>Les adhérents préfèrent désormais les salles de sport privées.<break time="700ms"/>C.<break time="300ms"/>Les horaires des cours sont la cause principale des départs.<break time="700ms"/>D.<break time="300ms"/>Les déménagements expliquent l''essentiel des non-renouvellements.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'L''exposé oppose une cause supposée et une cause réelle par l''articulation **« Or… En revanche »** : seuls neuf pour cent citent le tarif, tandis que « près de deux tiers citent la même difficulté », le créneau horaire — C dégage cette conclusion principale, confirmée par l''allusion finale au « vrai chantier » (mécanisme B2 de **hiérarchisation des causes**). A reprend l''hypothèse initiale du bureau, précisément **réfutée par les chiffres** (9 % seulement). B est un contresens : les répondants soulignent au contraire que les prix du club « restent inférieurs à ceux des salles privées » — la comparaison sert à disculper le tarif, pas à signaler une fuite vers la concurrence. D promeut un **détail secondaire** (14 % de déménagements) au rang de cause principale, piège entre donnée marginale et donnée majoritaire.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c007-1000-0000-000000000006', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bienvenue à toutes et à tous pour votre première permanence au Vestiaire du Pont, à Metz. Avant de vous montrer les rayonnages, je veux vous parler de l''essentiel, parce que les gestes techniques, vous les apprendrez en une soirée. Ici, les personnes qui poussent la porte choisissent leurs vêtements comme dans n''importe quelle boutique : elles essaient, elles hésitent, elles reposent. Certaines mettront quarante minutes pour repartir avec un seul manteau, et c''est très bien ainsi. Vous verrez des files d''attente, des soirs de grande affluence, et vous serez tentés de presser le mouvement, de choisir à la place des gens pour aller plus vite. Je vous le demande solennellement : ne le faites jamais. Une personne qui a perdu son logement a déjà cessé de décider beaucoup de choses dans sa vie. Le quart d''heure où elle choisit une chemise lui rend exactement ce que la rue lui a pris. Nous ne distribuons pas des vêtements ; nous rendons des choix. Si vous repartez ce soir avec cette seule phrase, la formation aura réussi.

Que veut transmettre la locutrice aux nouveaux bénévoles ?

A. Le respect du libre choix des bénéficiaires passe avant la rapidité du service.
B. Les gestes techniques du tri s''apprennent en une seule soirée.
C. Il faut aider les personnes hésitantes à choisir leurs vêtements plus vite.
D. Le vestiaire doit distribuer davantage de manteaux les soirs d''affluence.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bienvenue à toutes et à tous pour votre première permanence au Vestiaire du Pont, à Metz. Avant de vous montrer les rayonnages, je veux vous parler de l''essentiel, parce que les gestes techniques, vous les apprendrez en une soirée. Ici, les personnes qui poussent la porte choisissent leurs vêtements comme dans n''importe quelle boutique : elles essaient, elles hésitent, elles reposent. Certaines mettront quarante minutes pour repartir avec un seul manteau, et c''est très bien ainsi. Vous verrez des files d''attente, des soirs de grande affluence, et vous serez tentés de presser le mouvement, de choisir à la place des gens pour aller plus vite. Je vous le demande solennellement : ne le faites jamais. Une personne qui a perdu son logement a déjà cessé de décider beaucoup de choses dans sa vie. Le quart d''heure où elle choisit une chemise lui rend exactement ce que la rue lui a pris. Nous ne distribuons pas des vêtements ; nous rendons des choix. Si vous repartez ce soir avec cette seule phrase, la formation aura réussi.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que veut transmettre la locutrice aux nouveaux bénévoles ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le respect du libre choix des bénéficiaires passe avant la rapidité du service.<break time="700ms"/>B.<break time="300ms"/>Les gestes techniques du tri s''apprennent en une seule soirée.<break time="700ms"/>C.<break time="300ms"/>Il faut aider les personnes hésitantes à choisir leurs vêtements plus vite.<break time="700ms"/>D.<break time="300ms"/>Le vestiaire doit distribuer davantage de manteaux les soirs d''affluence.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'L''intention culmine dans la formule conclusive « nous ne distribuons pas des vêtements ; nous rendons des choix », précédée de l''interdiction solennelle de « choisir à la place des gens pour aller plus vite » : A reformule ce **message de valeurs** — le libre choix prime sur la rapidité (mécanisme B2 d''inférence d''intention, repérage de la **phrase-clé conclusive**). B élève en message central ce que la locutrice **minore explicitement** (« les gestes techniques, vous les apprendrez en une soirée ») pour mieux passer à l''essentiel. C est le contresens exact : presser le mouvement et choisir pour autrui est précisément ce qu''elle interdit (« ne le faites jamais »). D confond avec une logique de quantité que la conclusion rejette : la mission n''est pas de distribuer plus, mais de rendre des choix.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c007-1000-0000-000000000007', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonsoir, je vous présente le bilan de notre atelier itinérant de réparation de vélos, lancé en avril dans les villages autour de Niort. Les chiffres donnent le vertige : vingt-trois communes visitées, six cent dix vélos remis en état, des files d''attente dès l''ouverture, et trois mairies voisines qui réclament déjà notre passage l''an prochain. Vu de l''extérieur, c''est un triomphe. Vu de l''intérieur, le tableau est moins éclatant. Nous étions huit au départ ; nous ne sommes plus que cinq à assurer les tournées, et deux d''entre nous enchaînent tous les samedis depuis six mois. Trois bénévoles ont arrêté, épuisés, et je les comprends. Alors oui, la demande existe, oui, les communes nous attendent. Mais accepter de nouvelles tournées avec une équipe qui s''amenuise, ce serait courir à l''accident. Avant toute extension, il nous faut une chose : des bras, formés cet hiver à la mécanique. La feuille d''inscription des parrainages circule au fond de la salle.

Quelle est la conclusion principale de ce bilan ?

A. L''atelier est un échec qui sera abandonné l''an prochain.
B. Les communes voisines refusent désormais d''accueillir l''atelier.
C. Le projet doit s''étendre immédiatement à de nouvelles communes.
D. Le développement du projet exige d''abord de renforcer l''équipe de bénévoles.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonsoir, je vous présente le bilan de notre atelier itinérant de réparation de vélos, lancé en avril dans les villages autour de Niort. Les chiffres donnent le vertige : vingt-trois communes visitées, six cent dix vélos remis en état, des files d''attente dès l''ouverture, et trois mairies voisines qui réclament déjà notre passage l''an prochain. Vu de l''extérieur, c''est un triomphe. Vu de l''intérieur, le tableau est moins éclatant. Nous étions huit au départ ; nous ne sommes plus que cinq à assurer les tournées, et deux d''entre nous enchaînent tous les samedis depuis six mois. Trois bénévoles ont arrêté, épuisés, et je les comprends. Alors oui, la demande existe, oui, les communes nous attendent. Mais accepter de nouvelles tournées avec une équipe qui s''amenuise, ce serait courir à l''accident. Avant toute extension, il nous faut une chose : des bras, formés cet hiver à la mécanique. La feuille d''inscription des parrainages circule au fond de la salle.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est la conclusion principale de ce bilan ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>L''atelier est un échec qui sera abandonné l''an prochain.<break time="700ms"/>B.<break time="300ms"/>Les communes voisines refusent désormais d''accueillir l''atelier.<break time="700ms"/>C.<break time="300ms"/>Le projet doit s''étendre immédiatement à de nouvelles communes.<break time="700ms"/>D.<break time="300ms"/>Le développement du projet exige d''abord de renforcer l''équipe de bénévoles.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le bilan suit un mouvement concessif : succès public (« vu de l''extérieur, c''est un triomphe ») **mais** équipe épuisée, d''où la condition finale « avant toute extension, il nous faut… des bras » — D restitue cette conclusion (mécanisme B2 de la **concession « oui… mais »** qui inverse la portée des éloges initiaux). A est un contresens global : six cent dix vélos réparés et des mairies qui « réclament » le retour de l''atelier, rien n''annonce un abandon. B inverse les faits : trois mairies voisines demandent au contraire le passage de l''atelier l''an prochain. C reprend la demande extérieure mais ignore la restriction centrale : étendre « avec une équipe qui s''amenuise, ce serait courir à l''accident » — piège entre **ce que veulent les autres et ce que conclut le locuteur**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes 66666666-c007-1000-0000-000000000001..07.
-- [x] Format C exclusif (co_document_question), document parlé long :
--     longueurs comptées = 147 / 152 / 147 / 161 / 156 / 172 / 155 mots
--     (toutes dans la fourchette 120-200 mots B2).
-- [x] Thème unique « exposé associatif », 7 situations inventées et toutes
--     différentes : rapport du trésorier en AG d''un club de randonnée (Pau),
--     discours de passation de présidence d''une chorale (Angoulême), appel à
--     bénévoles réguliers au forum des associations (Tarbes), présentation
--     d''un projet d''ouverture des jardins partagés aux écoles (Colmar),
--     restitution d''enquête sur les départs d''un club de gym (Lorient),
--     accueil des nouveaux bénévoles d''un vestiaire solidaire (Metz), bilan
--     d''un atelier vélo itinérant (Niort). Aucun thème interdit (pas de
--     présentation d''organisme, communiqué, témoignage, chronique, etc.).
-- [x] Villes et prénoms distincts du lot 01 ; locuteurs en alternance
--     Henri / Vivienne (items 1,3,5,7 = Henri ; 2,4,6 = Vivienne),
--     voice_recommended = voix du document.
-- [x] 4 propositions / 1 correcte par item ; distribution des bonnes
--     réponses : C, A, D, B, C, A, D → A ×2, B ×1, C ×2, D ×2 — max 2 par
--     lettre, 4 lettres utilisées.
-- [x] Compréhension implicite B2 variée : rôle/fonction du locuteur (item 1),
--     intention du locuteur (items 2, 6), idée principale (items 3, 5, 7),
--     conséquence non dite (item 4) ; distracteurs tous plausibles (thème vs
--     propos, détail secondaire vs idée principale, inversion cause/effet,
--     hypothèse vs annonce, exagération de portée).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse + les 3
--     distracteurs, point clé en **gras**, mécanisme linguistique nommé
--     (inférence de rôle, conditionnel d''avertissement, concession,
--     hiérarchisation des causes, implication, phrase-clé conclusive).
-- [x] SSML équilibré (4 <voice>/4 </voice>, 4 <prosody>/4 </prosody> par
--     item), pauses conformes (1500ms / 1000ms / 700ms / 300ms), Denise 0.95
--     pour intro/question/propositions, Henri/Vivienne 1.0 pour le document.
-- [x] status='TEXT_VALIDATED', toutes colonnes audio NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées partout, JSONB valide, contenu 100% original.
-- ============================================================================
