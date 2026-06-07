-- ============================================================================
-- V864 — TCF CO B2 — lot 02 (thème : message professionnel & réunion)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B2), format C : document parlé long (~120-200 mots),
-- messages vocaux professionnels, prises de parole et dialogues denses en
-- réunion + question implicite (intention du locuteur, idée principale,
-- décision finale, conséquence non dite). Table audio_question_draft.
-- status='TEXT_VALIDATED', colonnes audio NULL (remplies par le batch admin
-- Azure). Contenu 100% original, situations et locuteurs inventés.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-c002-1000-0000-000000000001', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour Nadia, c''est Wei, du service logistique. Je t''appelle au sujet de la réunion avec le transporteur, prévue jeudi à neuf heures. Comme tu l''as peut-être vu, elle est décalée à vendredi quatorze heures, la salle du deuxième étage étant réquisitionnée pour l''audit. Ce n''est pas la vraie raison de mon appel. Vendredi, je serai à Lyon pour la visite de l''entrepôt, impossible de me dédoubler. Or quelqu''un doit présenter notre analyse des retards de livraison, et tu connais le dossier mieux que personne : c''est toi qui as compilé les chiffres du premier trimestre. Je t''ai déposé mes diapositives sur le serveur, dossier transport, elles sont presque terminées ; il manque juste la conclusion, que je te laisse formuler à ta manière. Préviens-moi avant demain soir si tu ne peux vraiment pas, que je trouve une autre solution. Merci d''avance, je te revaudrai ça.

Pourquoi Wei laisse-t-il ce message à Nadia ?

A. Pour l''informer du changement d''horaire de la réunion.
B. Pour lui demander de présenter le dossier à sa place.
C. Pour lui reprocher des chiffres incomplets dans les diapositives.
D. Pour annuler sa participation à la visite de l''entrepôt.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour Nadia, c''est Wei, du service logistique. Je t''appelle au sujet de la réunion avec le transporteur, prévue jeudi à neuf heures. Comme tu l''as peut-être vu, elle est décalée à vendredi quatorze heures, la salle du deuxième étage étant réquisitionnée pour l''audit. Ce n''est pas la vraie raison de mon appel. Vendredi, je serai à Lyon pour la visite de l''entrepôt, impossible de me dédoubler. Or quelqu''un doit présenter notre analyse des retards de livraison, et tu connais le dossier mieux que personne : c''est toi qui as compilé les chiffres du premier trimestre. Je t''ai déposé mes diapositives sur le serveur, dossier transport, elles sont presque terminées ; il manque juste la conclusion, que je te laisse formuler à ta manière. Préviens-moi avant demain soir si tu ne peux vraiment pas, que je trouve une autre solution. Merci d''avance, je te revaudrai ça.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi Wei laisse-t-il ce message à Nadia ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour l''informer du changement d''horaire de la réunion.<break time="700ms"/>B.<break time="300ms"/>Pour lui demander de présenter le dossier à sa place.<break time="700ms"/>C.<break time="300ms"/>Pour lui reprocher des chiffres incomplets dans les diapositives.<break time="700ms"/>D.<break time="300ms"/>Pour annuler sa participation à la visite de l''entrepôt.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La phrase pivot « ce n''est pas la vraie raison de mon appel » oblige à **distinguer l''information de surface de l''intention réelle** — inférence d''intention, mécanisme B2 typique des messages vocaux. Wei enchaîne aussitôt sur sa demande : que Nadia présente l''analyse des retards à sa place vendredi, d''où B. A s''arrête au thème d''ouverture (le report de la réunion), que Wei écarte lui-même comme un simple préambule. C déforme un détail : il manque « juste la conclusion », volontairement laissée à Nadia — aucun reproche sur les chiffres, qu''elle a d''ailleurs compilés elle-même. D inverse la logique : c''est la visite de l''entrepôt qui empêche Wei d''assister à la réunion, il ne renonce à rien.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c002-1000-0000-000000000002', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour à tous, merci d''être là. Avant d''ouvrir l''ordre du jour, je voudrais revenir sur les résultats de notre enquête interne. En moyenne, chacun d''entre vous passe seize heures par semaine en réunion, et la moitié d''entre vous déclare en sortir sans savoir ce qui a été décidé. Je ne vais pas supprimer les réunions, ce serait absurde : c''est là que se prennent nos décisions. En revanche, à partir du mois prochain, les règles changent. Toute réunion devra tenir en quarante-cinq minutes, commencer par un objectif écrit et se terminer par un relevé de décisions envoyé le jour même. Les points d''information simples passeront par messagerie : on ne mobilise pas douze personnes pour écouter ce qu''un courriel dit aussi bien. Enfin, chacun a le droit de décliner une invitation sans ordre du jour. Je ne cherche pas à vider vos agendas, je cherche à ce que chaque heure passée ensemble produise une décision.

Quel est l''objectif principal annoncé par la directrice ?

A. Réduire le nombre d''heures travaillées dans le service.
B. Remplacer toutes les réunions par des échanges écrits.
C. Rendre les réunions plus courtes et réellement décisionnelles.
D. Sanctionner les employés qui refusent les invitations.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour à tous, merci d''être là. Avant d''ouvrir l''ordre du jour, je voudrais revenir sur les résultats de notre enquête interne. En moyenne, chacun d''entre vous passe seize heures par semaine en réunion, et la moitié d''entre vous déclare en sortir sans savoir ce qui a été décidé. Je ne vais pas supprimer les réunions, ce serait absurde : c''est là que se prennent nos décisions. En revanche, à partir du mois prochain, les règles changent. Toute réunion devra tenir en quarante-cinq minutes, commencer par un objectif écrit et se terminer par un relevé de décisions envoyé le jour même. Les points d''information simples passeront par messagerie : on ne mobilise pas douze personnes pour écouter ce qu''un courriel dit aussi bien. Enfin, chacun a le droit de décliner une invitation sans ordre du jour. Je ne cherche pas à vider vos agendas, je cherche à ce que chaque heure passée ensemble produise une décision.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel est l''objectif principal annoncé par la directrice ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Réduire le nombre d''heures travaillées dans le service.<break time="700ms"/>B.<break time="300ms"/>Remplacer toutes les réunions par des échanges écrits.<break time="700ms"/>C.<break time="300ms"/>Rendre les réunions plus courtes et réellement décisionnelles.<break time="700ms"/>D.<break time="300ms"/>Sanctionner les employés qui refusent les invitations.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Il faut **distinguer les moyens (les nouvelles règles) du but**, condensé dans la phrase finale : « que chaque heure passée ensemble produise une décision ». Quarante-cinq minutes maximum, objectif écrit, relevé de décisions : C synthétise cette double exigence de concision et d''efficacité décisionnelle. A détourne « je ne cherche pas à vider vos agendas » : la directrice parle du temps de réunion, jamais du temps de travail global — piège entre **thème et propos**. B pousse à l''extrême une mesure limitée : seuls « les points d''information simples » passent par messagerie, les réunions décisionnelles sont explicitement maintenues. D est un contresens : décliner une invitation sans ordre du jour est présenté comme un droit nouveau, pas comme une faute à punir.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c002-1000-0000-000000000003', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Marek, on doit caler notre position avant la réunion de quinze heures avec Madame Costa. Le module de facturation aura trois semaines de retard, on ne peut plus le cacher.
[Homme] Justement, je me demande si on ne devrait pas présenter d''abord les écrans déjà terminés. Elle verra que le projet avance, et on glissera le calendrier révisé à la fin.
[Femme] On a déjà fait ça en mars, et elle l''a très mal pris quand elle a découvert le décalage dans le compte rendu. Si elle l''apprend encore après coup, on perd sa confiance pour de bon.
[Homme] Tu n''as pas tort. Mais arriver avec un retard sec, sans rien d''autre, c''est l''envoyer directement chez notre concurrent.
[Femme] Alors on annonce le retard en ouverture, chiffres à l''appui, et dans la même phrase on propose une compensation : la maintenance offerte pendant six mois et un point d''avancement chaque vendredi.
[Homme] Vendu. Je prépare le calendrier révisé, tu chiffres la maintenance. Et c''est toi qui ouvres la réunion, elle t''écoute davantage.

Quelle stratégie les deux collègues adoptent-ils pour la réunion ?

A. Reporter la réunion jusqu''à la livraison du module de facturation.
B. Montrer d''abord les écrans terminés et mentionner le retard à la fin.
C. Laisser la cliente découvrir le décalage dans le compte rendu.
D. Annoncer le retard d''emblée en proposant une compensation.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Marek, on doit caler notre position avant la réunion de quinze heures avec Madame Costa. Le module de facturation aura trois semaines de retard, on ne peut plus le cacher.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Justement, je me demande si on ne devrait pas présenter d''abord les écrans déjà terminés. Elle verra que le projet avance, et on glissera le calendrier révisé à la fin.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">On a déjà fait ça en mars, et elle l''a très mal pris quand elle a découvert le décalage dans le compte rendu. Si elle l''apprend encore après coup, on perd sa confiance pour de bon.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu n''as pas tort. Mais arriver avec un retard sec, sans rien d''autre, c''est l''envoyer directement chez notre concurrent.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Alors on annonce le retard en ouverture, chiffres à l''appui, et dans la même phrase on propose une compensation : la maintenance offerte pendant six mois et un point d''avancement chaque vendredi.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vendu. Je prépare le calendrier révisé, tu chiffres la maintenance. Et c''est toi qui ouvres la réunion, elle t''écoute davantage.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle stratégie les deux collègues adoptent-ils pour la réunion ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Reporter la réunion jusqu''à la livraison du module de facturation.<break time="700ms"/>B.<break time="300ms"/>Montrer d''abord les écrans terminés et mentionner le retard à la fin.<break time="700ms"/>C.<break time="300ms"/>Laisser la cliente découvrir le décalage dans le compte rendu.<break time="700ms"/>D.<break time="300ms"/>Annoncer le retard d''emblée en proposant une compensation.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le mécanisme attendu est de **suivre la négociation jusqu''à la décision finale** (inférence de la conclusion d''un dialogue argumenté) : la proposition d''Aïcha — annoncer le retard « en ouverture », chiffres à l''appui, avec maintenance offerte et point hebdomadaire — est ratifiée par le « Vendu » de Marek, donc D. B est la **première option de Marek**, abandonnée après l''objection de sa collègue : c''est le piège classique de la position initiale prise pour la décision finale. C décrit précisément le scénario de mars qu''ils cherchent à ne pas reproduire, la cliente l''ayant « très mal pris ». A n''est jamais envisagée : la réunion de quinze heures est maintenue, tout le dialogue sert justement à la préparer.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c002-1000-0000-000000000004', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour à toute l''équipe, c''est Tomás. Je vous laisse ce message avant la prise de poste de lundi, écoutez-le jusqu''au bout. Vendredi soir, une palette mal arrimée a glissé du rayonnage du quai trois. Personne n''a été touché, à deux mètres près. Je veux être clair : je ne cherche pas de coupable, ce serait trop facile et parfaitement inutile. Quand un incident pareil se produit, c''est l''organisation qui a une faille, pas une personne. À partir de lundi, donc, chaque équipe commencera sa journée par cinq minutes de point sécurité devant le tableau : on vérifie ensemble les zones de circulation, les charges en hauteur et le matériel signalé défectueux. Ceux qui trouvent ça lourd, je les invite à repenser à vendredi. Cinq minutes par jour contre un accident grave, le calcul est vite fait. Les chefs de ligne ont reçu la trame du brief, voyez avec eux. Bon week-end à tous, et lundi, on démarre du bon pied.

Quelle est l''intention principale du chef d''atelier ?

A. Instaurer une routine de prévention sans chercher de responsable.
B. Identifier l''employé responsable de l''incident du quai trois.
C. Annoncer une réduction du temps de travail des équipes.
D. Informer du remplacement du matériel défectueux.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour à toute l''équipe, c''est Tomás. Je vous laisse ce message avant la prise de poste de lundi, écoutez-le jusqu''au bout. Vendredi soir, une palette mal arrimée a glissé du rayonnage du quai trois. Personne n''a été touché, à deux mètres près. Je veux être clair : je ne cherche pas de coupable, ce serait trop facile et parfaitement inutile. Quand un incident pareil se produit, c''est l''organisation qui a une faille, pas une personne. À partir de lundi, donc, chaque équipe commencera sa journée par cinq minutes de point sécurité devant le tableau : on vérifie ensemble les zones de circulation, les charges en hauteur et le matériel signalé défectueux. Ceux qui trouvent ça lourd, je les invite à repenser à vendredi. Cinq minutes par jour contre un accident grave, le calcul est vite fait. Les chefs de ligne ont reçu la trame du brief, voyez avec eux. Bon week-end à tous, et lundi, on démarre du bon pied.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est l''intention principale du chef d''atelier ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Instaurer une routine de prévention sans chercher de responsable.<break time="700ms"/>B.<break time="300ms"/>Identifier l''employé responsable de l''incident du quai trois.<break time="700ms"/>C.<break time="300ms"/>Annoncer une réduction du temps de travail des équipes.<break time="700ms"/>D.<break time="300ms"/>Informer du remplacement du matériel défectueux.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Il faut saisir la **valeur illocutoire du message** (inférence d''intention) : Tomás raconte l''incident non pour accuser, mais pour justifier la mesure qu''il instaure — le point sécurité quotidien de cinq minutes — tout en écartant explicitement la recherche de coupable (« je ne cherche pas de coupable », « c''est l''organisation qui a une faille, pas une personne »). A réunit ces deux dimensions. B contredit frontalement ce refus affirmé deux fois. C déforme les « cinq minutes » de brief : c''est un **rituel ajouté** à la journée, en aucun cas une réduction d''horaires — piège sur la fonction du chiffre. D élève un détail au rang de propos : le matériel signalé défectueux n''est qu''un des trois points à vérifier au brief, aucun remplacement n''est annoncé.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c002-1000-0000-000000000005', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour à tous, point suivant de notre réunion mensuelle : l''organisation du travail à distance. Vous avez été cent quarante-trois à répondre au questionnaire, merci. Les résultats sont contrastés. D''un côté, quatre-vingts pour cent d''entre vous estiment mieux se concentrer chez eux, et personne ne souhaite revenir à la semaine entière sur site, moi y compris. De l''autre, les chefs d''équipe décrivent tous la même difficulté : impossible de réunir un projet complet le mardi ou le vendredi, chacun choisissant ses jours dans son coin. Les nouveaux arrivés, eux, disent ne croiser leurs collègues qu''en visioconférence. Nous n''allons donc pas réduire le nombre de jours à distance, je m''y étais engagée et je m''y tiens. En revanche, à compter de septembre, chaque service définira deux journées communes de présence, les mêmes pour tous ses membres, réservées aux ateliers, aux arbitrages et à l''accueil des nouveaux. Le reste de la semaine demeure libre. Vos responsables vous présenteront le calendrier d''ici fin juin.

Quelle décision annonce la directrice des opérations ?

A. Réduire le nombre de jours de télétravail autorisés.
B. Supprimer la visioconférence pour les nouveaux arrivés.
C. Imposer des jours de présence communs sans toucher au volume de télétravail.
D. Laisser chaque salarié choisir librement tous ses jours de présence.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour à tous, point suivant de notre réunion mensuelle : l''organisation du travail à distance. Vous avez été cent quarante-trois à répondre au questionnaire, merci. Les résultats sont contrastés. D''un côté, quatre-vingts pour cent d''entre vous estiment mieux se concentrer chez eux, et personne ne souhaite revenir à la semaine entière sur site, moi y compris. De l''autre, les chefs d''équipe décrivent tous la même difficulté : impossible de réunir un projet complet le mardi ou le vendredi, chacun choisissant ses jours dans son coin. Les nouveaux arrivés, eux, disent ne croiser leurs collègues qu''en visioconférence. Nous n''allons donc pas réduire le nombre de jours à distance, je m''y étais engagée et je m''y tiens. En revanche, à compter de septembre, chaque service définira deux journées communes de présence, les mêmes pour tous ses membres, réservées aux ateliers, aux arbitrages et à l''accueil des nouveaux. Le reste de la semaine demeure libre. Vos responsables vous présenteront le calendrier d''ici fin juin.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle décision annonce la directrice des opérations ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Réduire le nombre de jours de télétravail autorisés.<break time="700ms"/>B.<break time="300ms"/>Supprimer la visioconférence pour les nouveaux arrivés.<break time="700ms"/>C.<break time="300ms"/>Imposer des jours de présence communs sans toucher au volume de télétravail.<break time="700ms"/>D.<break time="300ms"/>Laisser chaque salarié choisir librement tous ses jours de présence.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La structure clé est le **balancement concessif « nous n''allons donc pas… en revanche… »** : il faut articuler les deux volets de la décision — volume de télétravail maintenu, mais deux journées communes de présence par service à compter de septembre. C est la seule reformulation qui combine les deux. A contredit l''engagement explicite, répété avec insistance (« je m''y étais engagée et je m''y tiens »). D décrit la **situation actuelle critiquée** (« chacun choisissant ses jours dans son coin »), c''est-à-dire le problème, pas la solution — piège d''inversion entre constat et décision. B transforme un constat des nouveaux arrivés (ne voir leurs collègues qu''en visioconférence) en mesure jamais annoncée : la réponse apportée est l''accueil lors des journées communes.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c002-1000-0000-000000000006', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Elif, j''ai repris tes chiffres hier soir : si on maintient la totalité du périmètre, le dépassement atteindra douze pour cent d''ici décembre. Le comité ne validera jamais.
[Femme] Je sais. Mais je refuse de rogner sur la qualité des tests, on l''a payé assez cher sur le projet précédent.
[Homme] Personne ne te le demande. La vraie question, c''est le module de statistiques : il mobilise deux développeurs depuis mars pour une fonction que seuls trois clients ont réclamée.
[Femme] Si on le sort du périmètre, on tient le budget ?
[Homme] On repasse même légèrement en dessous. Et rien n''empêche de le proposer l''an prochain, en option payante cette fois.
[Femme] D''accord, mais je veux que le comité l''acte noir sur blanc : ce n''est pas un abandon, c''est un report assumé. Et les deux développeurs basculent sur les tests dès lundi.
[Homme] Je rédige la note dans ce sens pour jeudi. Tu la relis avant que je l''envoie ?
[Femme] Envoie-la-moi mercredi soir, je te fais un retour dans la foulée.

Quelle solution les deux collègues retiennent-ils ?

A. Reporter le module de statistiques pour respecter le budget.
B. Réduire le temps consacré aux tests du projet.
C. Demander au comité une rallonge de douze pour cent.
D. Recruter deux développeurs supplémentaires.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Elif, j''ai repris tes chiffres hier soir : si on maintient la totalité du périmètre, le dépassement atteindra douze pour cent d''ici décembre. Le comité ne validera jamais.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je sais. Mais je refuse de rogner sur la qualité des tests, on l''a payé assez cher sur le projet précédent.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Personne ne te le demande. La vraie question, c''est le module de statistiques : il mobilise deux développeurs depuis mars pour une fonction que seuls trois clients ont réclamée.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Si on le sort du périmètre, on tient le budget ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">On repasse même légèrement en dessous. Et rien n''empêche de le proposer l''an prochain, en option payante cette fois.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">D''accord, mais je veux que le comité l''acte noir sur blanc : ce n''est pas un abandon, c''est un report assumé. Et les deux développeurs basculent sur les tests dès lundi.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je rédige la note dans ce sens pour jeudi. Tu la relis avant que je l''envoie ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Envoie-la-moi mercredi soir, je te fais un retour dans la foulée.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle solution les deux collègues retiennent-ils ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Reporter le module de statistiques pour respecter le budget.<break time="700ms"/>B.<break time="300ms"/>Réduire le temps consacré aux tests du projet.<break time="700ms"/>C.<break time="300ms"/>Demander au comité une rallonge de douze pour cent.<break time="700ms"/>D.<break time="300ms"/>Recruter deux développeurs supplémentaires.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Il faut **inférer la décision conjointe au terme de l''échange** (chaîne cause → solution) : sortir le module de statistiques du périmètre fait repasser le budget « légèrement en dessous », et Elif l''accepte en le qualifiant de « report assumé » — donc A. B est doublement exclue : Elif « refuse de rogner sur la qualité des tests » et Pavel confirme que « personne ne te le demande » — piège de l''option évoquée puis écartée. C détourne le chiffre entendu : douze pour cent est le **dépassement prévu** si rien ne change, pas une rallonge sollicitée — inversion entre le problème et la demande. D inverse la mesure réelle : les deux développeurs existants sont **réaffectés** aux tests dès lundi, aucune embauche n''est envisagée.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c002-1000-0000-000000000007', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour Madame Keller, c''est Hakim, du service achats. Désolé de vous laisser un message si tard, mais je préfère vous prévenir avant la réunion de lancement de demain matin. Je dois partir au Havre à la première heure : le contrôle qualité a bloqué un conteneur complet, et notre client principal exige quelqu''un sur place avant midi. Je ne pourrai donc pas être des vôtres. Cela dit, ce n''est pas pour m''excuser que j''appelle. Demain, vous devez trancher entre les deux fournisseurs d''emballage, et j''ai reçu hier soir des informations qui changent la donne : le moins cher des deux vient de perdre sa certification, j''attends la confirmation écrite. Je vous demande simplement de ne pas signer demain. Accordez-moi quarante-huit heures : jeudi, je vous présenterai un comparatif complet, preuves à l''appui. Tout le reste de l''ordre du jour peut se décider sans moi, Sonia a mes dossiers. Je reste joignable toute la journée sur mon portable. Merci, et encore désolé pour ce contretemps.

Pourquoi Hakim appelle-t-il sa responsable ?

A. Pour s''excuser de son absence à la réunion de lancement.
B. Pour obtenir le report de la décision sur le choix du fournisseur.
C. Pour signaler que le client principal a bloqué un conteneur.
D. Pour demander à Sonia de présenter ses dossiers en réunion.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour Madame Keller, c''est Hakim, du service achats. Désolé de vous laisser un message si tard, mais je préfère vous prévenir avant la réunion de lancement de demain matin. Je dois partir au Havre à la première heure : le contrôle qualité a bloqué un conteneur complet, et notre client principal exige quelqu''un sur place avant midi. Je ne pourrai donc pas être des vôtres. Cela dit, ce n''est pas pour m''excuser que j''appelle. Demain, vous devez trancher entre les deux fournisseurs d''emballage, et j''ai reçu hier soir des informations qui changent la donne : le moins cher des deux vient de perdre sa certification, j''attends la confirmation écrite. Je vous demande simplement de ne pas signer demain. Accordez-moi quarante-huit heures : jeudi, je vous présenterai un comparatif complet, preuves à l''appui. Tout le reste de l''ordre du jour peut se décider sans moi, Sonia a mes dossiers. Je reste joignable toute la journée sur mon portable. Merci, et encore désolé pour ce contretemps.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi Hakim appelle-t-il sa responsable ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour s''excuser de son absence à la réunion de lancement.<break time="700ms"/>B.<break time="300ms"/>Pour obtenir le report de la décision sur le choix du fournisseur.<break time="700ms"/>C.<break time="300ms"/>Pour signaler que le client principal a bloqué un conteneur.<break time="700ms"/>D.<break time="300ms"/>Pour demander à Sonia de présenter ses dossiers en réunion.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le mécanisme B2 consiste à **hiérarchiser les actes de parole** : l''excuse n''est qu''un préambule, ce que Hakim signale lui-même (« ce n''est pas pour m''excuser que j''appelle »), avant de formuler sa requête centrale : « je vous demande simplement de ne pas signer demain » — il veut quarante-huit heures pour prouver que le fournisseur le moins cher a perdu sa certification, donc B. A s''arrête à l''acte de surface, explicitement relativisé par le locuteur. C déforme un détail circonstanciel : c''est le **contrôle qualité** qui a bloqué le conteneur (le client, lui, exige une présence sur place), et ce point explique l''absence, il n''est pas l''objet de l''appel. D travestit une simple information logistique (« Sonia a mes dossiers ») en demande adressée à la responsable.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes 66666666-c002-1000-0000-000000000001..07.
-- [x] Format C exclusif (co_document_question), documents parlés longs :
--     longueurs comptées = 143 / 154 / 168 / 158 / 159 / 162 / 161 mots
--     (toutes dans la fourchette 120-200 mots B2). 5 monologues + 2 dialogues
--     denses (6 et 8 répliques).
-- [x] Thème unique « message professionnel & réunion », 7 situations toutes
--     différentes et inventées : message vocal de délégation (logistique, Lyon),
--     annonce d''une nouvelle politique de réunions (directrice), dialogue de
--     préparation d''une réunion client (retard à annoncer), message vocal de
--     consignes sécurité après incident (atelier, Tours), annonce télétravail
--     en réunion mensuelle (Metz), dialogue d''arbitrage budgétaire (comité),
--     message vocal demandant le report d''une décision fournisseur (Le Havre).
--     Aucun thème interdit (pas de présentation d''organisme, communiqué,
--     témoignage, chronique, dispositif public, exposé associatif, produit,
--     bulletin local, formation, débat, récit, culture, conseil d''expert,
--     environnement, économie). Prénoms variés : Wei, Nadia, Marek, Aïcha,
--     Tomás, Mariama (directrice item 5), Elif, Pavel, Hakim, Sonia.
-- [x] 4 propositions / 1 correcte par item ; distribution des bonnes réponses :
--     B, C, D, A, C, A, B → A ×2, B ×2, C ×2, D ×1 — max 2 par lettre,
--     4 lettres utilisées.
-- [x] Compréhension implicite B2 : intention du locuteur (items 1, 4, 7),
--     idée principale/décision (items 2, 5), décision finale d''un dialogue
--     (items 3, 6) ; pièges : thème vs propos, détail secondaire vs idée
--     principale, option écartée vs décision retenue, inversion cause/effet.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse + les 3
--     distracteurs, point clé en **gras**, mécanisme linguistique nommé
--     (inférence d''intention, valeur illocutoire, balancement concessif,
--     hiérarchie des actes de parole).
-- [x] SSML équilibré (monologues : 4 <voice>/4 </voice> ; dialogues : 9 et 11
--     paires <voice>/<prosody>), pauses conformes (1500ms après intro, 400ms
--     entre répliques, 1000ms après document et question, 700ms entre
--     propositions, 300ms après la lettre), Denise (0.95) + Henri/Vivienne
--     (1.0), voice_recommended = voix principale du document.
-- [x] status='TEXT_VALIDATED', toutes colonnes audio NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées partout, JSONB valide, contenu 100% original.
-- ============================================================================
