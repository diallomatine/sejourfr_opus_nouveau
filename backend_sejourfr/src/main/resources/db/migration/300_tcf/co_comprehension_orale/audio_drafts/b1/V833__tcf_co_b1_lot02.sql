-- ============================================================================
-- V833 — TCF CO B1 — lot 02 (thème : achat & service après-vente)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B1). Table audio_question_draft.
-- 7 items format C (dialogue de service + question, co_document_question)
-- + 3 items format B (question + 4 réponses, co_question_reponse).
-- Compréhension explicite + inférence simple (décision finale, moyen de
-- paiement, choix retenu). Contenu 100 % original, déterministe, rejouable.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-b002-1000-0000-000000000001', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, monsieur Keita. Votre grille-pain ne fonctionne plus ? Je peux vous rembourser, ou vous l''échanger.
[Homme] Le même modèle est encore en rayon ?
[Femme] Non, il ne reste que le modèle supérieur, à douze euros de plus.
[Homme] Tant pis, je prends celui-là et je paie la différence.

Que décide finalement le client ?

A. Se faire rembourser son grille-pain.
B. Faire réparer son ancien appareil.
C. Échanger contre le modèle supérieur en payant la différence.
D. Attendre le retour du même modèle en rayon.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, monsieur Keita. Votre grille-pain ne fonctionne plus ? Je peux vous rembourser, ou vous l''échanger.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Le même modèle est encore en rayon ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Non, il ne reste que le modèle supérieur, à douze euros de plus.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tant pis, je prends celui-là et je paie la différence.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que décide finalement le client ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Se faire rembourser son grille-pain.<break time="700ms"/>B.<break time="300ms"/>Faire réparer son ancien appareil.<break time="700ms"/>C.<break time="300ms"/>Échanger contre le modèle supérieur en payant la différence.<break time="700ms"/>D.<break time="300ms"/>Attendre le retour du même modèle en rayon.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence de décision finale** : il faut relier l''indisponibilité du même modèle (« il ne reste que le modèle supérieur, à douze euros de plus ») et la conclusion du client « je prends celui-là et je paie la différence » — C est correct. A est l''option **proposée au début puis non retenue** : elle répondrait à « que propose d''abord la vendeuse ? ». B n''est jamais évoqué : personne ne parle de réparer l''appareil en panne. D contredit le « tant pis » du client, qui accepte l''échange immédiat au lieu d''attendre un réassort. Mécanisme B1 : relier deux informations (rupture de stock + acceptation) pour déduire le choix.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b002-1000-0000-000000000002', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Pour le canapé, cela fait sept cent quarante euros, madame Rossi.
[Femme] Ma carte est limitée à cinq cents euros par semaine. Vous acceptez les chèques ?
[Homme] Non, mais nous proposons le paiement en trois fois sans frais, par carte.
[Femme] Parfait, faisons comme ça.

Comment la cliente va-t-elle payer son canapé ?

A. En espèces.
B. En trois fois par carte.
C. Par chèque.
D. En une seule fois par carte.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pour le canapé, cela fait sept cent quarante euros, madame Rossi.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Ma carte est limitée à cinq cents euros par semaine. Vous acceptez les chèques ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Non, mais nous proposons le paiement en trois fois sans frais, par carte.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Parfait, faisons comme ça.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment la cliente va-t-elle payer son canapé ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En espèces.<break time="700ms"/>B.<break time="300ms"/>En trois fois par carte.<break time="700ms"/>C.<break time="300ms"/>Par chèque.<break time="700ms"/>D.<break time="300ms"/>En une seule fois par carte.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Moyen de paiement final déduit par inférence simple** : la carte est plafonnée à cinq cents euros par semaine, le chèque est refusé, et la cliente accepte la proposition du vendeur (« le paiement en trois fois sans frais, par carte » — « parfait, faisons comme ça ») : B est correct. A n''est jamais mentionné dans le dialogue, distracteur purement thématique. C est le moyen **demandé puis refusé** par le vendeur — piège de la solution évoquée mais écartée. D est impossible : le plafond de la carte empêche justement de régler sept cent quarante euros en une fois. Mécanisme B1 : relier la contrainte (plafond) et la solution acceptée.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b002-1000-0000-000000000003', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, je voudrais rendre ces baskets, elles sont trop petites. Mais j''ai perdu le ticket de caisse.
[Homme] Sans ticket, je ne peux pas vous rembourser, madame Haddad. Je peux seulement vous faire un avoir, valable un an dans le magasin.
[Femme] Bon, d''accord pour l''avoir, je reviendrai choisir autre chose.

Que va recevoir la cliente ?

A. Un remboursement en espèces.
B. Une nouvelle paire à sa taille.
C. Un remboursement sur sa carte bancaire.
D. Un avoir valable dans le magasin.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, je voudrais rendre ces baskets, elles sont trop petites. Mais j''ai perdu le ticket de caisse.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Sans ticket, je ne peux pas vous rembourser, madame Haddad. Je peux seulement vous faire un avoir, valable un an dans le magasin.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bon, d''accord pour l''avoir, je reviendrai choisir autre chose.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que va recevoir la cliente ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un remboursement en espèces.<break time="700ms"/>B.<break time="300ms"/>Une nouvelle paire à sa taille.<break time="700ms"/>C.<break time="300ms"/>Un remboursement sur sa carte bancaire.<break time="700ms"/>D.<break time="300ms"/>Un avoir valable dans le magasin.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple contrainte → solution retenue** : sans ticket de caisse, le remboursement est impossible ; le vendeur propose « seulement un avoir, valable un an » et la cliente accepte (« d''accord pour l''avoir ») — D est correct. A et C reprennent le remboursement, précisément **exclu** par le vendeur (« sans ticket, je ne peux pas vous rembourser ») : ils répondraient à la situation où la cliente aurait gardé son ticket. B confond avec un échange immédiat : la cliente repart sans chaussures et « reviendra choisir autre chose » plus tard. Piège B1 : distinguer la demande initiale de la solution finalement acceptée.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b002-1000-0000-000000000004', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Mon aspirateur est encore sous garantie, mais il ne s''allume plus du tout.
[Femme] La réparation est gratuite, monsieur Nguyen, mais il faut compter trois semaines. Si vous voulez, nous vous prêtons un appareil pendant ce temps.
[Homme] Trois semaines sans aspirateur, impossible avec deux enfants ! Je prends l''appareil de prêt.

Que choisit le client pendant la réparation ?

A. Utiliser un appareil prêté par le magasin.
B. Acheter un nouvel aspirateur.
C. Payer pour une réparation plus rapide.
D. Attendre trois semaines sans appareil.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mon aspirateur est encore sous garantie, mais il ne s''allume plus du tout.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">La réparation est gratuite, monsieur Nguyen, mais il faut compter trois semaines. Si vous voulez, nous vous prêtons un appareil pendant ce temps.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Trois semaines sans aspirateur, impossible avec deux enfants ! Je prends l''appareil de prêt.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que choisit le client pendant la réparation ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Utiliser un appareil prêté par le magasin.<break time="700ms"/>B.<break time="300ms"/>Acheter un nouvel aspirateur.<break time="700ms"/>C.<break time="300ms"/>Payer pour une réparation plus rapide.<break time="700ms"/>D.<break time="300ms"/>Attendre trois semaines sans appareil.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple proposition + acceptation** : l''employée propose « nous vous prêtons un appareil pendant ce temps » et le client conclut « je prends l''appareil de prêt » — A est correct. B n''est jamais envisagé : l''aspirateur est sous garantie, acheter un neuf n''aurait pas de sens dans ce dialogue. C invente une option payante qui n''existe pas — la réparation est **gratuite** et aucun service express n''est proposé. D est exactement la situation que le client refuse (« trois semaines sans aspirateur, impossible avec deux enfants ! »). Mécanisme B1 : relier le refus d''attendre et la solution de prêt acceptée.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b002-1000-0000-000000000005', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, j''hésite entre ces deux machines à laver.
[Homme] La première est moins chère, mais assez bruyante. La seconde coûte quatre-vingts euros de plus, et elle est très silencieuse, madame Mendy.
[Femme] J''habite un petit studio et je lave souvent le soir... Je vais mettre le prix pour la silencieuse.

Pourquoi la cliente choisit-elle la machine la plus chère ?

A. Parce qu''elle lave plus de linge à la fois.
B. Parce qu''elle est silencieuse.
C. Parce qu''elle est en promotion.
D. Parce qu''elle consomme moins d''eau.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, j''hésite entre ces deux machines à laver.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">La première est moins chère, mais assez bruyante. La seconde coûte quatre-vingts euros de plus, et elle est très silencieuse, madame Mendy.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">J''habite un petit studio et je lave souvent le soir... Je vais mettre le prix pour la silencieuse.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi la cliente choisit-elle la machine la plus chère ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce qu''elle lave plus de linge à la fois.<break time="700ms"/>B.<break time="300ms"/>Parce qu''elle est silencieuse.<break time="700ms"/>C.<break time="300ms"/>Parce qu''elle est en promotion.<break time="700ms"/>D.<break time="300ms"/>Parce qu''elle consomme moins d''eau.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple cause → choix** : il faut relier la situation de la cliente (« j''habite un petit studio et je lave souvent le soir ») et la qualité de la seconde machine (« très silencieuse ») pour comprendre que le **silence** motive l''achat malgré le surcoût — B est correct. A n''est pas évoqué : aucune capacité de lavage n''est comparée dans le dialogue. C contredit le document : la machine choisie coûte quatre-vingts euros **de plus**, elle n''est pas en promotion. D invente un argument écologique jamais mentionné — distracteur thématique plausible mais hors document. Piège B1 : retenir la cause réellement donnée, pas une cause vraisemblable.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b002-1000-0000-000000000006', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] J''ai acheté ce vélo ici il y a dix jours, et le frein arrière frotte déjà.
[Femme] Je suis désolée, monsieur Traoré. Le réglage est gratuit : notre technicien peut le faire tout de suite, en vingt minutes, ou alors vous revenez demain.
[Homme] Vingt minutes seulement ? Alors je patiente ici, ce sera réglé aujourd''hui.

Que décide le client ?

A. Revenir demain pour le réglage.
B. Demander le remboursement du vélo.
C. Attendre en boutique pendant la réparation.
D. Régler le frein lui-même à la maison.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''ai acheté ce vélo ici il y a dix jours, et le frein arrière frotte déjà.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je suis désolée, monsieur Traoré. Le réglage est gratuit : notre technicien peut le faire tout de suite, en vingt minutes, ou alors vous revenez demain.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vingt minutes seulement ? Alors je patiente ici, ce sera réglé aujourd''hui.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que décide le client ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Revenir demain pour le réglage.<break time="700ms"/>B.<break time="300ms"/>Demander le remboursement du vélo.<break time="700ms"/>C.<break time="300ms"/>Attendre en boutique pendant la réparation.<break time="700ms"/>D.<break time="300ms"/>Régler le frein lui-même à la maison.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence de décision finale entre deux options** : la vendeuse propose « tout de suite, en vingt minutes » ou « vous revenez demain » ; le client tranche avec « alors je patiente ici » — C est correct. A est la **seconde option proposée puis écartée** : piège classique de l''alternative entendue mais non choisie. B n''est jamais demandé : le client signale un défaut de frein, pas une volonté de rendre le vélo. D contredit le dialogue : c''est le technicien du magasin qui effectue le réglage, pas le client. Mécanisme B1 : relier la courte durée annoncée (« vingt minutes seulement ? ») et la décision de rester.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b002-1000-0000-000000000007', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] La garantie de cet ordinateur portable dure un an, c''est ça ? L''écran est fragile, ça m''inquiète un peu.
[Homme] Oui, un an. Mais pour soixante-dix-neuf euros, l''extension de deux ans couvre tout, madame Petrenko, même l''écran cassé.
[Femme] Même l''écran ? Alors j''ajoute l''extension, je serai tranquille.

Que décide finalement la cliente ?

A. Choisir un autre ordinateur moins fragile.
B. Garder seulement la garantie d''un an.
C. Acheter une housse de protection.
D. Prendre l''extension de garantie de deux ans.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">La garantie de cet ordinateur portable dure un an, c''est ça ? L''écran est fragile, ça m''inquiète un peu.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, un an. Mais pour soixante-dix-neuf euros, l''extension de deux ans couvre tout, madame Petrenko, même l''écran cassé.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Même l''écran ? Alors j''ajoute l''extension, je serai tranquille.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que décide finalement la cliente ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Choisir un autre ordinateur moins fragile.<break time="700ms"/>B.<break time="300ms"/>Garder seulement la garantie d''un an.<break time="700ms"/>C.<break time="300ms"/>Acheter une housse de protection.<break time="700ms"/>D.<break time="300ms"/>Prendre l''extension de garantie de deux ans.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple inquiétude → solution choisie** : la cliente s''inquiète pour l''écran fragile ; quand le vendeur précise que l''extension couvre « même l''écran cassé », elle conclut « alors j''ajoute l''extension » — D est correct. A n''est jamais envisagé : elle ne remet pas en cause le modèle, seulement sa protection. B décrit la situation de départ, **abandonnée** au moment où elle ajoute l''extension payante. C confond protection physique et garantie : aucune housse n''est mentionnée dans le dialogue, distracteur thématique plausible. Mécanisme B1 : relier l''argument décisif (« même l''écran ») et l''accord final.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b002-1000-0000-000000000008', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Vous avez acheté cet appareil photo quand, exactement ?

A. Il y a deux semaines, pendant les soldes.
B. Dans votre magasin du centre-ville.
C. Pour photographier mes voyages.
D. Avec une carte mémoire offerte.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez acheté cet appareil photo quand, exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il y a deux semaines, pendant les soldes.<break time="700ms"/>B.<break time="300ms"/>Dans votre magasin du centre-ville.<break time="700ms"/>C.<break time="300ms"/>Pour photographier mes voyages.<break time="700ms"/>D.<break time="300ms"/>Avec une carte mémoire offerte.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « quand, exactement ? » porte sur **le moment de l''achat** : seule A « il y a deux semaines, pendant les soldes » situe l''achat dans le temps. B donne **un lieu** et répondrait à « où l''avez-vous acheté ? ». C, introduit par « pour », exprime **un but** et répondrait à « pourquoi l''avez-vous acheté ? ». D décrit **un accessoire inclus** et répondrait à « qu''est-ce qui était offert avec ? ». Mécanisme B1 : identifier le mot interrogatif et la nature de l''information attendue — les quatre réponses restent crédibles dans le contexte d''un retour en magasin.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b002-1000-0000-000000000009', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Et le remboursement de mon achat, je le recevrai comment ?

A. Sous cinq jours ouvrés, madame.
B. Quarante-neuf euros au total.
C. Directement sur votre carte bancaire.
D. À l''accueil du magasin, au rez-de-chaussée.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Et le remboursement de mon achat, je le recevrai comment ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Sous cinq jours ouvrés, madame.<break time="700ms"/>B.<break time="300ms"/>Quarante-neuf euros au total.<break time="700ms"/>C.<break time="300ms"/>Directement sur votre carte bancaire.<break time="700ms"/>D.<break time="300ms"/>À l''accueil du magasin, au rez-de-chaussée.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Comment ? » interroge ici **le mode de remboursement** : seule C « directement sur votre carte bancaire » indique la manière dont l''argent sera rendu. A donne **un délai** et répondrait à « quand serai-je remboursée ? ». B donne **un montant** et répondrait à « de combien serai-je remboursée ? ». D donne **un lieu** et répondrait à « où dois-je m''adresser ? ». Piège B1 classique : toutes les réponses parlent du remboursement, seule la nature de la question — la **manière** — permet de trancher entre mode, délai, montant et lieu.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b002-1000-0000-00000000000a', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Pourquoi voulez-vous rendre cette cafetière ?

A. Depuis mardi dernier, environ.
B. Parce qu''elle fuit dès qu''on la remplit.
C. Au rayon électroménager, au fond.
D. Avant la fin du mois, si possible.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pourquoi voulez-vous rendre cette cafetière ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis mardi dernier, environ.<break time="700ms"/>B.<break time="300ms"/>Parce qu''elle fuit dès qu''on la remplit.<break time="700ms"/>C.<break time="300ms"/>Au rayon électroménager, au fond.<break time="700ms"/>D.<break time="300ms"/>Avant la fin du mois, si possible.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Pourquoi ? » appelle **une cause**, introduite typiquement par « parce que » : seule B « parce qu''elle fuit dès qu''on la remplit » donne le motif du retour. A, avec « depuis », indique **une durée écoulée** et répondrait à « depuis quand fuit-elle ? ». C donne **un lieu** et répondrait à « où se trouve le rayon ? ». D, avec « avant », indique **une échéance** et répondrait à « quand souhaitez-vous être remboursé ? ». Mécanisme B1 : reconnaître le connecteur attendu après « pourquoi » (cause en « parce que ») et écarter les réponses de durée, de lieu et de délai, toutes crédibles dans un service après-vente.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes 66666666-b002-1000-0000-000000000001 → 0a.
-- [x] Thème unique « achat & service après-vente », 10 situations toutes
--     différentes : échange d'un grille-pain contre le modèle supérieur,
--     paiement d'un canapé en trois fois, avoir pour des baskets sans ticket,
--     appareil de prêt pendant la réparation d'un aspirateur, choix d'une
--     machine à laver silencieuse, réglage immédiat d'un frein de vélo,
--     extension de garantie d'un ordinateur, date d'achat d'un appareil photo,
--     mode de remboursement, motif de retour d'une cafetière.
-- [x] Aucun thème interdit (pas de logement, médical, banque, administration,
--     voyage, restaurant, téléphonie, école, travail, voiture, déménagement,
--     assurance, livraison/colis, hôtel, pharmacie).
-- [x] Répartition : 7 × format C (co_document_question, dialogues 3-4 répliques,
--     ~40-60 mots prononcés chacun, multi-voix Henri/Vivienne) + 3 × format B
--     (co_question_reponse, question Henri/Vivienne + propositions Denise).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : A=2 (items 4,8), B=3 (items 2,5,10),
--     C=3 (items 1,6,9), D=2 (items 3,7) — 4 lettres utilisées, max 3.
-- [x] Inférence simple B1 : décision finale (1,4,6,7), moyen de paiement (2),
--     solution retenue (3), cause du choix (5) ; explicite + distracteurs
--     proches sur les formats B (8,9,10).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**, mécanisme linguistique nommé
--     (inférence simple, cause vs but, nature de l'information interrogée).
-- [x] SSML : balises <voice>/<prosody> équilibrées, voix Denise 0.95 (narration)
--     / Henri & Vivienne 1.0 (dialogue), pauses 1500/1000/700/300 ms conformes.
-- [x] status='TEXT_VALIDATED', colonnes audio NULL, batch_id NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées (''), JSONB valide, aucun SVG requis (pas de
--     CO_IMAGE dans ce lot). Contenu 100 % original, prénoms et situations
--     variés (Keita, Rossi, Haddad, Nguyen, Mendy, Traoré, Petrenko).
-- ============================================================================
