-- ============================================================================
-- V840 — TCF CO B1 — lot 09 (thème : inscription dans une école)
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
  ('66666666-b009-1000-0000-000000000001', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Monsieur Sarr, pour le cours d''informatique, il reste des places le mardi soir et le samedi matin.
[Homme] Je suis veilleur de nuit, je commence à dix-huit heures. Le samedi matin, c''est parfait pour moi.
[Femme] Très bien, je vous inscris dans le groupe du samedi.

Quel cours le client choisit-il ?

A. Le cours du mardi soir.
B. Un cours en ligne, à distance.
C. Le cours du samedi matin.
D. Aucun cours pour cette année.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Monsieur Sarr, pour le cours d''informatique, il reste des places le mardi soir et le samedi matin.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je suis veilleur de nuit, je commence à dix-huit heures. Le samedi matin, c''est parfait pour moi.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Très bien, je vous inscris dans le groupe du samedi.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel cours le client choisit-il ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le cours du mardi soir.<break time="700ms"/>B.<break time="300ms"/>Un cours en ligne, à distance.<break time="700ms"/>C.<break time="300ms"/>Le cours du samedi matin.<break time="700ms"/>D.<break time="300ms"/>Aucun cours pour cette année.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple contrainte → choix** : il faut relier « je suis veilleur de nuit, je commence à dix-huit heures » (le soir est impossible) et la confirmation de la secrétaire « je vous inscris dans le groupe du samedi » pour conclure que C est correct. A est le créneau **incompatible avec son travail** — piège de la première option entendue, il répondrait à « quels créneaux restent disponibles ? ». B n''est jamais évoqué : aucun cours à distance n''est proposé dans le dialogue. D contredit la phrase finale, qui valide bien une inscription.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b009-1000-0000-000000000002', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Madame Fernandez, les frais d''inscription à l''école de langues s''élèvent à cent vingt euros.
[Femme] Je peux vous faire un chèque ?
[Homme] Non, désolé, nous acceptons seulement la carte ou les espèces.
[Femme] Je n''ai que vingt euros sur moi... je vais payer par carte, alors.

Comment la cliente va-t-elle payer les frais d''inscription ?

A. Par chèque.
B. En espèces.
C. Par virement bancaire.
D. Par carte bancaire.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Madame Fernandez, les frais d''inscription à l''école de langues s''élèvent à cent vingt euros.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je peux vous faire un chèque ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Non, désolé, nous acceptons seulement la carte ou les espèces.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je n''ai que vingt euros sur moi... je vais payer par carte, alors.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment la cliente va-t-elle payer les frais d''inscription ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Par chèque.<break time="700ms"/>B.<break time="300ms"/>En espèces.<break time="700ms"/>C.<break time="300ms"/>Par virement bancaire.<break time="700ms"/>D.<break time="300ms"/>Par carte bancaire.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Moyen de paiement final déduit par inférence simple** : le chèque est refusé, il reste carte ou espèces ; comme la cliente « n''a que vingt euros » sur elle (insuffisant pour cent vingt euros), elle conclut « je vais payer par carte ». D est correct. A est le moyen **proposé puis refusé** par le secrétaire — piège de la première mention. B est accepté par l''école mais éliminé par le manque d''argent liquide : il faut relier le montant et la somme disponible. C n''est jamais évoqué dans le dialogue : distracteur thématique plausible mais hors document.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b009-1000-0000-000000000003', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Monsieur Chen, le dossier de votre fille est presque complet : il manque seulement l''attestation d''assurance scolaire.
[Homme] Ah, je l''ai laissée à la maison. Je peux vous l''apporter demain matin ?
[Femme] Oui, avant dix heures, et l''inscription sera validée.

Que va faire le père ?

A. Apporter l''attestation d''assurance demain matin.
B. Souscrire une nouvelle assurance scolaire.
C. Revenir au secrétariat avec sa fille.
D. Envoyer le document par courrier.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Monsieur Chen, le dossier de votre fille est presque complet : il manque seulement l''attestation d''assurance scolaire.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Ah, je l''ai laissée à la maison. Je peux vous l''apporter demain matin ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Oui, avant dix heures, et l''inscription sera validée.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que va faire le père ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Apporter l''attestation d''assurance demain matin.<break time="700ms"/>B.<break time="300ms"/>Souscrire une nouvelle assurance scolaire.<break time="700ms"/>C.<break time="300ms"/>Revenir au secrétariat avec sa fille.<break time="700ms"/>D.<break time="300ms"/>Envoyer le document par courrier.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question porte sur **la décision du père** : il propose « je peux vous l''apporter demain matin ? » et la secrétaire accepte (« oui, avant dix heures ») — A est correct, **inférence simple** proposition + accord. B déforme le problème : l''attestation existe déjà, elle est simplement « restée à la maison », il n''a pas besoin d''une nouvelle assurance. C invente un détail : la présence de la fille n''est jamais demandée, seul le document manque. D contredit le dialogue : le père apportera le papier **en personne**, aucun envoi postal n''est évoqué.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b009-1000-0000-000000000004', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Madame Bondarenko, j''ai corrigé votre test de niveau : quarante-deux points sur cinquante.
[Femme] C''est bien ? Je voulais m''inscrire dans le groupe débutant.
[Homme] Ce serait trop facile pour vous. Avec ce résultat, je vous place dans le groupe intermédiaire.
[Femme] D''accord, je vous fais confiance.

Dans quel groupe la candidate va-t-elle être inscrite ?

A. Dans le groupe débutant.
B. Dans le groupe intermédiaire.
C. Dans le groupe avancé.
D. Dans aucun groupe : elle doit repasser le test.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Madame Bondarenko, j''ai corrigé votre test de niveau : quarante-deux points sur cinquante.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">C''est bien ? Je voulais m''inscrire dans le groupe débutant.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Ce serait trop facile pour vous. Avec ce résultat, je vous place dans le groupe intermédiaire.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">D''accord, je vous fais confiance.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Dans quel groupe la candidate va-t-elle être inscrite ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dans le groupe débutant.<break time="700ms"/>B.<break time="300ms"/>Dans le groupe intermédiaire.<break time="700ms"/>C.<break time="300ms"/>Dans le groupe avancé.<break time="700ms"/>D.<break time="300ms"/>Dans aucun groupe : elle doit repasser le test.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple résultat → placement** : il faut relier le bon score (« quarante-deux points sur cinquante »), la décision du formateur (« je vous place dans le groupe intermédiaire ») et l''acceptation de la candidate (« d''accord ») pour choisir B. A est le groupe **souhaité au départ puis écarté** — piège de l''intention initiale, contredite par « ce serait trop facile pour vous ». C surinterprète le bon score : le formateur parle d''intermédiaire, jamais d''avancé. D contredit le dialogue : le test est déjà corrigé et le placement décidé, rien n''est à repasser.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b009-1000-0000-000000000005', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Monsieur Morales, pour la cantine, vous inscrivez votre fille tous les jours ?
[Homme] Non, le vendredi, elle déjeune chez sa grand-mère. Inscrivez-la lundi, mardi et jeudi.
[Femme] C''est noté. Et le mercredi, il n''y a pas classe, donc pas de cantine.

Quels jours la fille du client mangera-t-elle à la cantine ?

A. Tous les jours de la semaine.
B. Seulement le vendredi.
C. Le mercredi et le vendredi.
D. Le lundi, le mardi et le jeudi.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Monsieur Morales, pour la cantine, vous inscrivez votre fille tous les jours ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Non, le vendredi, elle déjeune chez sa grand-mère. Inscrivez-la lundi, mardi et jeudi.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">C''est noté. Et le mercredi, il n''y a pas classe, donc pas de cantine.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quels jours la fille du client mangera-t-elle à la cantine ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Tous les jours de la semaine.<break time="700ms"/>B.<break time="300ms"/>Seulement le vendredi.<break time="700ms"/>C.<break time="300ms"/>Le mercredi et le vendredi.<break time="700ms"/>D.<break time="300ms"/>Le lundi, le mardi et le jeudi.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le père énonce explicitement la liste : « inscrivez-la **lundi, mardi et jeudi** » — D est correct. Le piège B1 consiste à relier deux exclusions : le vendredi (déjeuner chez la grand-mère) et le mercredi (pas de classe). A est contredit par le « non » initial du père à « tous les jours ? ». B inverse l''information : le vendredi est précisément le jour **sans** cantine, pas le seul jour de cantine. C regroupe les deux jours exclus — piège de l''inversion, il répondrait à « quels jours la fille ne mange-t-elle pas à la cantine ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b009-1000-0000-000000000006', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Madame Patel, pour la deuxième langue de votre fils au collège, vous avez le choix entre l''espagnol et l''allemand.
[Femme] Nous passons tous les étés à Berlin, chez son oncle. L''allemand lui sera plus utile.
[Homme] Très bien, je note l''allemand sur sa fiche d''inscription.

Quelle langue le fils va-t-il étudier ?

A. L''espagnol.
B. L''allemand.
C. Les deux langues en même temps.
D. Aucune langue cette année.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Madame Patel, pour la deuxième langue de votre fils au collège, vous avez le choix entre l''espagnol et l''allemand.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Nous passons tous les étés à Berlin, chez son oncle. L''allemand lui sera plus utile.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Très bien, je note l''allemand sur sa fiche d''inscription.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle langue le fils va-t-il étudier ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>L''espagnol.<break time="700ms"/>B.<break time="300ms"/>L''allemand.<break time="700ms"/>C.<break time="300ms"/>Les deux langues en même temps.<break time="700ms"/>D.<break time="300ms"/>Aucune langue cette année.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple argument → choix** : il faut relier la raison donnée par la mère (« nous passons tous les étés à Berlin, chez son oncle ») et la confirmation du secrétaire (« je note l''allemand sur sa fiche ») pour choisir B. A est l''option **mentionnée puis non retenue** — piège de la première langue citée, elle répondrait à « quelles langues sont proposées ? ». C contredit l''énoncé : le choix porte sur **une seule** deuxième langue (« vous avez le choix entre »). D contredit la fin du dialogue, où l''inscription en allemand est bien enregistrée.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b009-1000-0000-000000000007', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] L''inscription au cours de dessin coûte deux cents euros l''année, monsieur Haddad. Mais c''est moitié prix pour les demandeurs d''emploi.
[Homme] Justement, je suis inscrit à France Travail. J''ai mon attestation ici.
[Femme] Parfait, avec ce document, vous payez le tarif réduit.

Combien le client va-t-il payer pour son inscription ?

A. Cent euros.
B. Deux cents euros.
C. Cinquante euros.
D. Rien : l''inscription est gratuite pour lui.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">L''inscription au cours de dessin coûte deux cents euros l''année, monsieur Haddad. Mais c''est moitié prix pour les demandeurs d''emploi.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Justement, je suis inscrit à France Travail. J''ai mon attestation ici.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Parfait, avec ce document, vous payez le tarif réduit.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Combien le client va-t-il payer pour son inscription ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Cent euros.<break time="700ms"/>B.<break time="300ms"/>Deux cents euros.<break time="700ms"/>C.<break time="300ms"/>Cinquante euros.<break time="700ms"/>D.<break time="300ms"/>Rien : l''inscription est gratuite pour lui.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple par calcul** : le montant final n''est jamais prononcé — il faut relier « deux cents euros » + « moitié prix pour les demandeurs d''emploi » + le fait que le client présente son attestation pour déduire qu''il paiera **la moitié de deux cents euros, soit cent euros** (A). B est le tarif plein, le **chiffre entendu littéralement** — piège pour qui ne fait pas le calcul. C divise une fois de trop : cinquante serait le quart, pas la moitié. D confond réduction et gratuité : « moitié prix » signifie payer moins, pas ne rien payer.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b009-1000-0000-000000000008', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] La réunion de rentrée pour les nouveaux inscrits, c''est quand ?

A. Dans la salle polyvalente de l''école.
B. Avec tous les professeurs de l''équipe.
C. Jeudi prochain, à dix-huit heures.
D. Pour présenter le programme de l''année.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">La réunion de rentrée pour les nouveaux inscrits, c''est quand ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dans la salle polyvalente de l''école.<break time="700ms"/>B.<break time="300ms"/>Avec tous les professeurs de l''équipe.<break time="700ms"/>C.<break time="300ms"/>Jeudi prochain, à dix-huit heures.<break time="700ms"/>D.<break time="300ms"/>Pour présenter le programme de l''année.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « c''est quand ? » porte sur **le moment** : seule C « jeudi prochain, à dix-huit heures » situe la réunion dans le temps. A, introduit par « dans », donne **un lieu** et répondrait à « où a-t-elle lieu ? ». B donne **les participants** et répondrait à « avec qui se déroule-t-elle ? ». D, introduit par « pour », exprime **un but** et répondrait à « à quoi sert cette réunion ? ». Mécanisme B1 : identifier le mot interrogatif et la nature de l''information attendue — les quatre réponses restent crédibles dans le contexte de la rentrée scolaire.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b009-1000-0000-000000000009', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Où dois-je déposer le dossier d''inscription de ma fille ?

A. Avant la fin du mois, c''est plus sûr.
B. Au secrétariat, au premier étage.
C. Avec deux photos d''identité récentes.
D. Parce que les places sont limitées.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Où dois-je déposer le dossier d''inscription de ma fille ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avant la fin du mois, c''est plus sûr.<break time="700ms"/>B.<break time="300ms"/>Au secrétariat, au premier étage.<break time="700ms"/>C.<break time="300ms"/>Avec deux photos d''identité récentes.<break time="700ms"/>D.<break time="300ms"/>Parce que les places sont limitées.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Où dois-je déposer... ? » appelle **un lieu** : seule B « au secrétariat, au premier étage » localise le dépôt du dossier. A, introduit par « avant », donne **une échéance** et répondrait à « quand faut-il le déposer ? ». C donne **le contenu du dossier** et répondrait à « que faut-il joindre au dossier ? ». D, introduit par « parce que », exprime **une cause** et répondrait à « pourquoi faut-il se dépêcher ? ». Piège B1 classique : toutes les réponses parlent du dossier d''inscription, seule la nature de la question — un endroit — permet de trancher.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b009-1000-0000-00000000000a', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Comment je peux inscrire mon fils aux activités du soir ?

A. Depuis la rentrée de septembre.
B. À côté du gymnase de l''école.
C. Parce qu''il adore le sport.
D. En remplissant le formulaire en ligne.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Comment je peux inscrire mon fils aux activités du soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis la rentrée de septembre.<break time="700ms"/>B.<break time="300ms"/>À côté du gymnase de l''école.<break time="700ms"/>C.<break time="300ms"/>Parce qu''il adore le sport.<break time="700ms"/>D.<break time="300ms"/>En remplissant le formulaire en ligne.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Comment je peux inscrire... ? » appelle **un moyen, une manière de procéder** : seule D « en remplissant le formulaire en ligne » répond, grâce au **gérondif de moyen** (« en + participe présent »). A, introduit par « depuis », donne **un point de départ dans le temps** et répondrait à « depuis quand les activités existent-elles ? ». B donne **un lieu** et répondrait à « où se déroulent les activités ? ». C, introduit par « parce que », exprime **une cause** et répondrait à « pourquoi voulez-vous l''inscrire ? ». Mécanisme B1 : « comment » exige une procédure, pas un moment, un lieu ni une raison.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes 66666666-b009-1000-0000-000000000001 → 0a.
-- [x] Thème unique « inscription dans une école », 10 situations toutes
--     différentes : choix d'un créneau de cours d'informatique, paiement des
--     frais d'inscription en école de langues, pièce manquante au dossier,
--     test de niveau et placement en groupe, inscription à la cantine,
--     choix de la deuxième langue au collège, tarif réduit au cours de dessin,
--     date de la réunion de rentrée, lieu de dépôt du dossier, procédure
--     d'inscription aux activités du soir.
-- [x] Répartition : 7 × format C (co_document_question, dialogues 2-4 répliques,
--     ~35-65 mots prononcés chacun, multi-voix Henri/Vivienne) + 3 × format B
--     (co_question_reponse, question Henri/Vivienne + propositions Denise).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : A=2 (items 3,7), B=3 (items 4,6,9),
--     C=2 (items 1,8), D=3 (items 2,5,10) — 4 positions utilisées, max 3.
-- [x] Inférence simple B1 : décision finale (1,3,4,6), moyen de paiement (2),
--     montant déduit par calcul (7) ; explicite + distracteurs proches
--     (5,8,9,10).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**, mécanisme linguistique nommé
--     (inférence simple, cause vs but, gérondif de moyen, mot interrogatif).
-- [x] SSML : balises <voice>/<prosody> équilibrées, voix Denise 0.95 (narration)
--     / Henri & Vivienne 1.0 (dialogue), pauses 1500/1000/700/300 ms conformes.
-- [x] status='TEXT_VALIDATED', colonnes audio NULL, batch_id NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées (''), JSONB valide, aucun SVG requis (pas de
--     CO_IMAGE dans ce lot). Contenu 100 % original.
-- ============================================================================
