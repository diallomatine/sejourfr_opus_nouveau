-- ============================================================================
-- V876 — TCF CO B2 — lot 14 (thème : conseil d'expert)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B2), format C : monologue expositif long (~120-200 mots)
-- + question implicite (conseil essentiel, intention du locuteur, idée
-- principale, conséquence non dite). Table audio_question_draft.
-- status='TEXT_VALIDATED', colonnes audio NULL (remplies par le batch admin
-- Azure). Contenu 100% original, experts et situations inventés.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-c00e-1000-0000-000000000001', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, je suis Wei Zhang, ergonome à Grenoble depuis quinze ans, et j''interviens auprès de salariés en télétravail. On me pose toujours la même question : quel fauteuil acheter ? Je réponds souvent que ce n''est pas la bonne question. J''ai vu des personnes souffrir du dos sur des sièges à huit cents euros, et d''autres travailler sans douleur sur une simple chaise de cuisine. Pourquoi ? Parce que le corps n''est pas fait pour rester immobile, même dans la meilleure position du monde. La posture parfaite maintenue huit heures devient une mauvaise posture. Alors voici ce que je conseille : levez-vous toutes les quarante-cinq minutes, ne serait-ce que deux minutes, téléphonez debout, alternez écran haut et écran bas si vous le pouvez. Réglez correctement votre siège, bien sûr, mais ne croyez pas qu''un équipement coûteux vous protégera à lui seul. C''est la variation qui protège vos articulations, pas le matériel.

Quel est le conseil essentiel de cette ergonome ?

A. Investir dans un fauteuil de bureau de qualité professionnelle.
B. Travailler debout pour soulager le dos.
C. Varier les postures tout au long de la journée de travail.
D. Limiter le nombre d''heures passées devant l''écran.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, je suis Wei Zhang, ergonome à Grenoble depuis quinze ans, et j''interviens auprès de salariés en télétravail. On me pose toujours la même question : quel fauteuil acheter ? Je réponds souvent que ce n''est pas la bonne question. J''ai vu des personnes souffrir du dos sur des sièges à huit cents euros, et d''autres travailler sans douleur sur une simple chaise de cuisine. Pourquoi ? Parce que le corps n''est pas fait pour rester immobile, même dans la meilleure position du monde. La posture parfaite maintenue huit heures devient une mauvaise posture. Alors voici ce que je conseille : levez-vous toutes les quarante-cinq minutes, ne serait-ce que deux minutes, téléphonez debout, alternez écran haut et écran bas si vous le pouvez. Réglez correctement votre siège, bien sûr, mais ne croyez pas qu''un équipement coûteux vous protégera à lui seul. C''est la variation qui protège vos articulations, pas le matériel.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel est le conseil essentiel de cette ergonome ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Investir dans un fauteuil de bureau de qualité professionnelle.<break time="700ms"/>B.<break time="300ms"/>Travailler debout pour soulager le dos.<break time="700ms"/>C.<break time="300ms"/>Varier les postures tout au long de la journée de travail.<break time="700ms"/>D.<break time="300ms"/>Limiter le nombre d''heures passées devant l''écran.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Toute l''argumentation converge vers la formule finale : « c''est la variation qui protège vos articulations, pas le matériel ». Il faut **dégager le conseil central derrière les exemples** (se lever, téléphoner debout, alterner les écrans) : C synthétise cette logique du mouvement. A reprend précisément la fausse piste que Wei écarte d''emblée — le fauteuil à huit cents euros ne protège pas — piège sur la **croyance réfutée par l''experte**. B élève un **exemple ponctuel** (« téléphonez debout ») au rang de conseil principal : l''ergonome ne prône pas le travail debout permanent, qui serait une posture figée comme une autre. D n''est jamais formulée : Wei explique comment travailler huit heures sans douleur, elle ne demande pas de réduire le temps d''écran.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00e-1000-0000-000000000002', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Je suis Rachid Benyoucef, pharmacien à Tours depuis vingt-deux ans. Chaque semaine, je vois des clients repartir avec un médicament contre le rhume alors qu''ils prennent déjà un traitement pour la tension, sans imaginer une seconde que les deux puissent se gêner. C''est là le vrai danger de l''automédication. Pris isolément, un sirop ou un comprimé contre la douleur vendus sans ordonnance sont sûrs ; c''est leur rencontre avec un autre traitement qui peut poser problème. Certains anti-inflammatoires diminuent l''effet des médicaments pour le cœur, certaines plantes perturbent les anticoagulants. Mon conseil tient en une phrase : avant d''ajouter quoi que ce soit à un traitement en cours, même un produit en apparence anodin, posez la question à votre pharmacien. La consultation ne coûte rien, elle prend deux minutes, et nous avons votre historique sous les yeux. Ne décidez jamais seul d''un mélange, c''est l''association qui crée le risque, presque jamais le produit lui-même.

Quel est le conseil essentiel de ce pharmacien ?

A. Demander l''avis du pharmacien avant d''associer un produit à un traitement en cours.
B. Renoncer aux médicaments vendus sans ordonnance.
C. Éviter les plantes médicinales pendant l''hiver.
D. Consulter un médecin dès les premiers symptômes d''un rhume.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je suis Rachid Benyoucef, pharmacien à Tours depuis vingt-deux ans. Chaque semaine, je vois des clients repartir avec un médicament contre le rhume alors qu''ils prennent déjà un traitement pour la tension, sans imaginer une seconde que les deux puissent se gêner. C''est là le vrai danger de l''automédication. Pris isolément, un sirop ou un comprimé contre la douleur vendus sans ordonnance sont sûrs ; c''est leur rencontre avec un autre traitement qui peut poser problème. Certains anti-inflammatoires diminuent l''effet des médicaments pour le cœur, certaines plantes perturbent les anticoagulants. Mon conseil tient en une phrase : avant d''ajouter quoi que ce soit à un traitement en cours, même un produit en apparence anodin, posez la question à votre pharmacien. La consultation ne coûte rien, elle prend deux minutes, et nous avons votre historique sous les yeux. Ne décidez jamais seul d''un mélange, c''est l''association qui crée le risque, presque jamais le produit lui-même.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel est le conseil essentiel de ce pharmacien ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Demander l''avis du pharmacien avant d''associer un produit à un traitement en cours.<break time="700ms"/>B.<break time="300ms"/>Renoncer aux médicaments vendus sans ordonnance.<break time="700ms"/>C.<break time="300ms"/>Éviter les plantes médicinales pendant l''hiver.<break time="700ms"/>D.<break time="300ms"/>Consulter un médecin dès les premiers symptômes d''un rhume.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Rachid annonce lui-même que son conseil « tient en une phrase » : poser la question au pharmacien avant tout ajout à un traitement en cours, car « c''est l''association qui crée le risque » — A reformule exactement ce message. B est un **contresens sur la concession** : il affirme que ces produits, « pris isolément », « sont sûrs » ; il ne demande pas d''y renoncer mais de vérifier les mélanges. C déforme un **exemple ponctuel** (les plantes qui perturbent les anticoagulants) en interdiction générale, et la mention de l''hiver est inventée. D déplace le destinataire du conseil : tout le monologue valorise le passage par le **pharmacien**, gratuit et immédiat, jamais une consultation médicale — piège classique de substitution d''acteur.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00e-1000-0000-000000000003', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, Priya Nair, médecin au centre du sommeil de Strasbourg. Mes patients arrivent presque tous avec la même croyance : pour bien dormir, il faudrait dormir huit heures, coûte que coûte. Alors ils se couchent tôt le dimanche pour rattraper le week-end, font la grasse matinée le samedi, et s''étonnent d''être épuisés le lundi. Ce que la recherche montre, c''est autre chose : votre cerveau possède une horloge interne, et cette horloge déteste les surprises. Se lever à sept heures en semaine et à onze heures le samedi, c''est lui imposer un décalage horaire chaque fin de semaine, comme un vol Paris-Moscou sans quitter votre lit. Mon conseil paraîtra modeste, il est pourtant le plus efficace que je connaisse : levez-vous à la même heure tous les jours, dimanche compris, à trente minutes près. La durée idéale varie d''une personne à l''autre, six heures et demie suffisent à certains. Mais la régularité, elle, profite à tout le monde.

Que recommande avant tout cette spécialiste ?

A. Dormir au moins huit heures chaque nuit.
B. Se coucher plus tôt le dimanche soir.
C. Éviter les voyages qui perturbent l''horloge interne.
D. Se lever chaque jour à la même heure, y compris le week-end.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, Priya Nair, médecin au centre du sommeil de Strasbourg. Mes patients arrivent presque tous avec la même croyance : pour bien dormir, il faudrait dormir huit heures, coûte que coûte. Alors ils se couchent tôt le dimanche pour rattraper le week-end, font la grasse matinée le samedi, et s''étonnent d''être épuisés le lundi. Ce que la recherche montre, c''est autre chose : votre cerveau possède une horloge interne, et cette horloge déteste les surprises. Se lever à sept heures en semaine et à onze heures le samedi, c''est lui imposer un décalage horaire chaque fin de semaine, comme un vol Paris-Moscou sans quitter votre lit. Mon conseil paraîtra modeste, il est pourtant le plus efficace que je connaisse : levez-vous à la même heure tous les jours, dimanche compris, à trente minutes près. La durée idéale varie d''une personne à l''autre, six heures et demie suffisent à certains. Mais la régularité, elle, profite à tout le monde.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que recommande avant tout cette spécialiste ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dormir au moins huit heures chaque nuit.<break time="700ms"/>B.<break time="300ms"/>Se coucher plus tôt le dimanche soir.<break time="700ms"/>C.<break time="300ms"/>Éviter les voyages qui perturbent l''horloge interne.<break time="700ms"/>D.<break time="300ms"/>Se lever chaque jour à la même heure, y compris le week-end.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le mécanisme B2 attendu est l''**opposition entre la croyance des patients et le conseil de la spécialiste** : Priya réfute le dogme des huit heures, puis énonce sa recommandation (« levez-vous à la même heure tous les jours, dimanche compris ») et conclut « la régularité, elle, profite à tout le monde » — D la reformule fidèlement. A reprend la **croyance réfutée** en ouverture : la durée idéale « varie d''une personne à l''autre », « six heures et demie suffisent à certains ». B décrit un **comportement présenté comme inefficace** (se coucher tôt le dimanche pour rattraper), pas un conseil. C prend la **comparaison au pied de la lettre** : le « vol Paris-Moscou » est une image du décalage créé par les grasses matinées, pas une mise en garde contre les voyages réels.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00e-1000-0000-000000000004', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Diego Salazar, je travaille depuis dix-huit ans dans la prévention routière, à Bordeaux. Quand j''interviens auprès de conducteurs, je leur demande ce qu''ils font lorsqu''ils sentent la fatigue arriver sur l''autoroute. Les réponses sont toujours les mêmes : ouvrir la fenêtre, monter le son de la radio, boire un café au prochain péage. Or, toutes les études le confirment : ces astuces repoussent la somnolence d''un quart d''heure, au mieux. Le cerveau qui réclame du sommeil finit toujours par l''obtenir, parfois trois secondes, les yeux ouverts, à cent trente kilomètres heure. Trois secondes, c''est cent mètres parcourus à l''aveugle. Mon conseil est sans nuance : dès le premier bâillement répété, dès que vos paupières deviennent lourdes, sortez à la prochaine aire et dormez vingt minutes. Pas une heure, vingt minutes, suivies d''une vraie pause. C''est la seule réponse qui fonctionne, parce que c''est la seule qui donne au cerveau ce qu''il demande, au lieu d''essayer de le tromper.

Selon cet expert, que doit faire un conducteur qui sent la fatigue ?

A. Boire un café à la prochaine station-service.
B. S''arrêter et dormir une vingtaine de minutes dès les premiers signes.
C. Réduire sa vitesse pour diminuer le risque d''accident.
D. Faire une pause d''au moins une heure sur une aire de repos.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Diego Salazar, je travaille depuis dix-huit ans dans la prévention routière, à Bordeaux. Quand j''interviens auprès de conducteurs, je leur demande ce qu''ils font lorsqu''ils sentent la fatigue arriver sur l''autoroute. Les réponses sont toujours les mêmes : ouvrir la fenêtre, monter le son de la radio, boire un café au prochain péage. Or, toutes les études le confirment : ces astuces repoussent la somnolence d''un quart d''heure, au mieux. Le cerveau qui réclame du sommeil finit toujours par l''obtenir, parfois trois secondes, les yeux ouverts, à cent trente kilomètres heure. Trois secondes, c''est cent mètres parcourus à l''aveugle. Mon conseil est sans nuance : dès le premier bâillement répété, dès que vos paupières deviennent lourdes, sortez à la prochaine aire et dormez vingt minutes. Pas une heure, vingt minutes, suivies d''une vraie pause. C''est la seule réponse qui fonctionne, parce que c''est la seule qui donne au cerveau ce qu''il demande, au lieu d''essayer de le tromper.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Selon cet expert, que doit faire un conducteur qui sent la fatigue ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Boire un café à la prochaine station-service.<break time="700ms"/>B.<break time="300ms"/>S''arrêter et dormir une vingtaine de minutes dès les premiers signes.<break time="700ms"/>C.<break time="300ms"/>Réduire sa vitesse pour diminuer le risque d''accident.<break time="700ms"/>D.<break time="300ms"/>Faire une pause d''au moins une heure sur une aire de repos.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le conseil « sans nuance » de Diego est explicite dans sa conclusion : sortir à la prochaine aire et « dormir vingt minutes » dès le premier bâillement, car c''est « la seule réponse qui fonctionne » — B le reformule. A reprend l''une des **astuces démontées par l''expert** : le café, comme la fenêtre ouverte ou la radio, ne repousse la somnolence que « d''un quart d''heure, au mieux ». C est plausible mais jamais évoquée : la vitesse (cent trente kilomètres heure) sert uniquement à **illustrer la distance parcourue à l''aveugle**, pas à fonder un conseil de ralentissement — piège entre exemple chiffré et recommandation. D contredit la précision « pas une heure, vingt minutes » : le piège joue sur l''**inversion de la durée** explicitement écartée.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00e-1000-0000-000000000005', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Je m''appelle Lucia Andrade, je suis consultante en cybersécurité à Rennes, et j''accompagne des particuliers victimes de piratage. Presque tous me disent la même chose : pourtant, mon mot de passe était compliqué ! Majuscule, chiffre, point d''exclamation, ils avaient tout fait comme on leur avait appris. Le problème n''était pas là. Leur mot de passe, si savant soit-il, était le même partout : messagerie, banque, sites d''achat, forums. Or, il suffit qu''un seul petit site se fasse voler son fichier clients pour que ce précieux mot de passe circule, et avec lui l''accès à toute votre vie numérique. Les pirates n''ont rien deviné : ils ont essayé la même clé sur toutes les portes. Voilà pourquoi mon conseil ne porte pas sur la complexité : utilisez un mot de passe différent pour chaque compte, quitte à les confier à un gestionnaire qui les retiendra pour vous. Une serrure ordinaire sur chaque porte protège mieux qu''une serrure blindée dont la copie traîne partout.

Quel est le message principal de cette experte ?

A. Le vrai danger est de réutiliser le même mot de passe sur plusieurs comptes.
B. Un mot de passe doit contenir des majuscules et des caractères spéciaux.
C. Il faut éviter d''acheter sur les petits sites mal protégés.
D. Les gestionnaires de mots de passe présentent un risque de piratage.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je m''appelle Lucia Andrade, je suis consultante en cybersécurité à Rennes, et j''accompagne des particuliers victimes de piratage. Presque tous me disent la même chose : pourtant, mon mot de passe était compliqué ! Majuscule, chiffre, point d''exclamation, ils avaient tout fait comme on leur avait appris. Le problème n''était pas là. Leur mot de passe, si savant soit-il, était le même partout : messagerie, banque, sites d''achat, forums. Or, il suffit qu''un seul petit site se fasse voler son fichier clients pour que ce précieux mot de passe circule, et avec lui l''accès à toute votre vie numérique. Les pirates n''ont rien deviné : ils ont essayé la même clé sur toutes les portes. Voilà pourquoi mon conseil ne porte pas sur la complexité : utilisez un mot de passe différent pour chaque compte, quitte à les confier à un gestionnaire qui les retiendra pour vous. Une serrure ordinaire sur chaque porte protège mieux qu''une serrure blindée dont la copie traîne partout.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel est le message principal de cette experte ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le vrai danger est de réutiliser le même mot de passe sur plusieurs comptes.<break time="700ms"/>B.<break time="300ms"/>Un mot de passe doit contenir des majuscules et des caractères spéciaux.<break time="700ms"/>C.<break time="300ms"/>Il faut éviter d''acheter sur les petits sites mal protégés.<break time="700ms"/>D.<break time="300ms"/>Les gestionnaires de mots de passe présentent un risque de piratage.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Lucia déplace explicitement le problème : « le problème n''était pas là », « mon conseil ne porte pas sur la complexité » — le danger, illustré par « la même clé sur toutes les portes », est la **réutilisation du même mot de passe**, donc A. B reprend la **croyance des victimes** (majuscule, chiffre, point d''exclamation), citée précisément pour être réfutée — piège entre l''opinion rapportée et la thèse de la locutrice. C transforme un **maillon du scénario** (le petit site dont le fichier clients fuit) en consigne : Lucia n''interdit pas ces sites, elle montre qu''aucun compte ne doit partager sa clé avec eux. D est un **contresens** : le gestionnaire est recommandé comme solution (« quitte à les confier à un gestionnaire »), jamais présenté comme une menace.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00e-1000-0000-000000000006', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Amadou Traoré, agronome, je conseille depuis vingt ans les jardiniers amateurs de la région de Perpignan. L''erreur que je rencontre le plus souvent ne concerne ni les semences ni le sol : c''est l''arrosage. Par affection pour leurs légumes, beaucoup de jardiniers sortent l''arrosoir tous les soirs et déposent un peu d''eau au pied de chaque plante. Le geste paraît bienveillant ; il est contre-productif. Une eau qui reste en surface attire les racines vers le haut, là où la terre sèche en premier. La plante devient alors dépendante : trois jours sans vous, et elle flétrit. Faites l''inverse. Arrosez deux fois par semaine seulement, mais copieusement, dix litres par mètre carré, pour que l''eau descende en profondeur. Les racines iront la chercher, et vos légumes traverseront une semaine de canicule sans souffrir. J''ajoute un détail : arrosez le matin tôt ou le soir, jamais en plein soleil. Mais retenez surtout ceci : en arrosage, la générosité espacée vaut mieux que l''attention quotidienne.

Quel est le conseil principal de cet agronome ?

A. Arroser chaque soir au pied de chaque plante.
B. Arroser uniquement le matin, avant les fortes chaleurs.
C. Arroser moins souvent, mais en grande quantité.
D. Choisir des semences résistantes à la sécheresse.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Amadou Traoré, agronome, je conseille depuis vingt ans les jardiniers amateurs de la région de Perpignan. L''erreur que je rencontre le plus souvent ne concerne ni les semences ni le sol : c''est l''arrosage. Par affection pour leurs légumes, beaucoup de jardiniers sortent l''arrosoir tous les soirs et déposent un peu d''eau au pied de chaque plante. Le geste paraît bienveillant ; il est contre-productif. Une eau qui reste en surface attire les racines vers le haut, là où la terre sèche en premier. La plante devient alors dépendante : trois jours sans vous, et elle flétrit. Faites l''inverse. Arrosez deux fois par semaine seulement, mais copieusement, dix litres par mètre carré, pour que l''eau descende en profondeur. Les racines iront la chercher, et vos légumes traverseront une semaine de canicule sans souffrir. J''ajoute un détail : arrosez le matin tôt ou le soir, jamais en plein soleil. Mais retenez surtout ceci : en arrosage, la générosité espacée vaut mieux que l''attention quotidienne.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel est le conseil principal de cet agronome ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Arroser chaque soir au pied de chaque plante.<break time="700ms"/>B.<break time="300ms"/>Arroser uniquement le matin, avant les fortes chaleurs.<break time="700ms"/>C.<break time="300ms"/>Arroser moins souvent, mais en grande quantité.<break time="700ms"/>D.<break time="300ms"/>Choisir des semences résistantes à la sécheresse.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Amadou oppose l''erreur courante (un peu d''eau tous les soirs) et sa recommandation (« arrosez deux fois par semaine seulement, mais copieusement »), résumée par la formule finale « la générosité espacée vaut mieux que l''attention quotidienne » — C reformule cette **hiérarchie entre fréquence et quantité**. A décrit précisément le **comportement dénoncé comme contre-productif**, celui qui rend la plante dépendante — piège entre la pratique critiquée et le conseil donné. B élève un **« détail » explicitement secondaire** (le moment de la journée, « j''ajoute un détail ») au rang de conseil principal, et ajoute « uniquement » alors que le soir est aussi admis. D détourne une simple mention introductive : l''erreur fréquente « ne concerne ni les semences ni le sol » — les semences ne font l''objet d''aucune recommandation.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 6 items, UUID déterministes 66666666-c00e-1000-0000-000000000001..06.
-- [x] Format C exclusif (co_document_question), monologue de conseil d''expert
--     long : longueurs comptées = 147 / 152 / 155 / 155 / 158 / 158 mots
--     (toutes dans la fourchette 120-200 mots B2).
-- [x] Thème unique « conseil d''expert », 6 situations/locuteurs inventés tous
--     différents : ergonome télétravail (Grenoble), pharmacien automédication
--     (Tours), médecin du sommeil (Strasbourg), préventeur routier fatigue au
--     volant (Bordeaux), consultante cybersécurité mots de passe (Rennes),
--     agronome arrosage du potager (Perpignan). Prénoms variés : Wei, Rachid,
--     Priya, Diego, Lucia, Amadou. Aucun thème interdit (pas de présentation
--     d''organisme, ni communiqué, ni chronique, ni formation, etc.).
-- [x] 4 propositions / 1 correcte par item ; distribution des bonnes réponses :
--     C, A, D, B, A, C → pos1 (A) ×2, pos2 (B) ×1, pos3 (C) ×2, pos4 (D) ×1 —
--     max 2 par position, 4 positions utilisées.
-- [x] Compréhension implicite B2 : conseil essentiel vs croyance réfutée,
--     idée principale vs détail secondaire (« j''ajoute un détail »),
--     comparaison prise au pied de la lettre, inversion de durée/acteur ;
--     4 propositions en reformulation, toutes plausibles.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse + les 3
--     distracteurs, point clé en **gras**, mécanisme linguistique nommé.
-- [x] SSML équilibré (4 <voice>/4 </voice>, 4 <prosody>/4 </prosody> par item),
--     pauses conformes (1500ms / 1000ms / 700ms / 300ms), Denise (0.95) +
--     Henri/Vivienne (1.0) en alternance, voice_recommended = voix du document.
-- [x] status='TEXT_VALIDATED', toutes colonnes audio NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées partout, JSONB valide, contenu 100% original.
-- ============================================================================
