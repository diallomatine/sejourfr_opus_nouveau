-- ============================================================================
-- V841 — TCF CO B1 — lot 10 (thème : entretien / travail)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B1). Table audio_question_draft.
-- 7 items format C (dialogue de service + question, co_document_question)
-- + 3 items format B (question + 4 réponses, co_question_reponse).
-- Compréhension explicite + inférence simple (décision finale, moyen retenu,
-- choix et sa cause). Contenu 100 % original, déterministe, rejouable.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-b00a-1000-0000-000000000001', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Monsieur Traoré, nous avons deux postes : préparateur de commandes la nuit, mieux payé, ou vendeur en magasin la journée.
[Homme] Je garde mes enfants le soir, donc je préfère le magasin, même avec un salaire plus bas.
[Femme] Très bien, je note votre choix.

Quel poste le candidat choisit-il ?

A. Préparateur de commandes la nuit.
B. Aucun des deux postes.
C. Vendeur en magasin la journée.
D. Gardien d''enfants à domicile.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Monsieur Traoré, nous avons deux postes : préparateur de commandes la nuit, mieux payé, ou vendeur en magasin la journée.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je garde mes enfants le soir, donc je préfère le magasin, même avec un salaire plus bas.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Très bien, je note votre choix.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel poste le candidat choisit-il ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Préparateur de commandes la nuit.<break time="700ms"/>B.<break time="300ms"/>Aucun des deux postes.<break time="700ms"/>C.<break time="300ms"/>Vendeur en magasin la journée.<break time="700ms"/>D.<break time="300ms"/>Gardien d''enfants à domicile.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence de décision finale** : il faut relier la contrainte du candidat (« je garde mes enfants le soir ») à sa préférence (« je préfère le magasin ») et à la confirmation de la recruteuse (« je note votre choix ») pour conclure que C est correct. A est le poste **mieux payé mais écarté** — piège de la première information entendue ; il répondrait à « quel poste offre le meilleur salaire ? ». B contredit la confirmation finale : un choix est bien enregistré. D détourne « je garde mes enfants » : c''est sa situation familiale, pas un emploi proposé.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00a-1000-0000-000000000002', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Pour ce poste de comptable à Lyon, nous proposons deux mille euros, madame Fernandez.
[Femme] J''espérais deux mille deux cents, vu mon expérience.
[Homme] Le salaire est fixe, mais nous ajoutons des tickets restaurant et une prime annuelle.
[Femme] Dans ce cas, j''accepte votre proposition.

Pourquoi la candidate accepte-t-elle finalement le poste ?

A. Parce que le salaire passe à deux mille deux cents euros.
B. Parce que l''employeur ajoute des avantages au salaire.
C. Parce qu''elle n''a pas d''expérience professionnelle.
D. Parce que le poste se trouve près de chez elle.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pour ce poste de comptable à Lyon, nous proposons deux mille euros, madame Fernandez.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">J''espérais deux mille deux cents, vu mon expérience.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Le salaire est fixe, mais nous ajoutons des tickets restaurant et une prime annuelle.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Dans ce cas, j''accepte votre proposition.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi la candidate accepte-t-elle finalement le poste ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce que le salaire passe à deux mille deux cents euros.<break time="700ms"/>B.<break time="300ms"/>Parce que l''employeur ajoute des avantages au salaire.<break time="700ms"/>C.<break time="300ms"/>Parce qu''elle n''a pas d''expérience professionnelle.<break time="700ms"/>D.<break time="300ms"/>Parce que le poste se trouve près de chez elle.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « pourquoi accepte-t-elle ? » appelle **la cause de la décision**. Inférence simple : le salaire reste fixe, mais l''employeur ajoute « des tickets restaurant et une prime annuelle », et la candidate enchaîne « dans ce cas, j''accepte » — B est correct. A est faux : la hausse à deux mille deux cents euros est précisément **refusée** (« le salaire est fixe »). C contredit ses propres mots « vu mon expérience », qui prouvent qu''elle en a. D n''est jamais évoqué dans le dialogue : distracteur thématique plausible mais hors document.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00a-1000-0000-000000000003', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] L''entrepôt se trouve à la sortie de Strasbourg, monsieur Haddad. Vous avez une voiture ?
[Homme] Non, mais j''ai vérifié : le tramway s''arrête juste devant, et il circule tôt le matin.
[Femme] Parfait, car les équipes commencent à six heures.

Comment le candidat ira-t-il au travail ?

A. En voiture.
B. À vélo.
C. Avec un collègue.
D. En tramway.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">L''entrepôt se trouve à la sortie de Strasbourg, monsieur Haddad. Vous avez une voiture ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Non, mais j''ai vérifié : le tramway s''arrête juste devant, et il circule tôt le matin.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Parfait, car les équipes commencent à six heures.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment le candidat ira-t-il au travail ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En voiture.<break time="700ms"/>B.<break time="300ms"/>À vélo.<break time="700ms"/>C.<break time="300ms"/>Avec un collègue.<break time="700ms"/>D.<break time="300ms"/>En tramway.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « comment ? » appelle **un moyen de transport**. Inférence simple : le candidat n''a pas de voiture (« non ») mais il a vérifié que « le tramway s''arrête juste devant » et circule tôt — D est correct. A est contredit par sa réponse négative à la question de la recruteuse : piège de la **première mention**. B et C sont des moyens plausibles d''aller travailler, mais ils ne sont **jamais évoqués** dans le dialogue : distracteurs thématiques. Mécanisme B1 : relier l''absence de voiture et la solution annoncée pour déduire le moyen retenu.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00a-1000-0000-000000000004', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Madame Rossi, j''aimerais télétravailler trois jours par semaine.
[Femme] C''est trop : toute l''équipe doit être présente du lundi au mercredi. Je vous propose le jeudi et le vendredi à la maison.
[Homme] Deux jours, c''est déjà bien. J''accepte.

Combien de jours par semaine le salarié va-t-il télétravailler ?

A. Deux jours.
B. Trois jours.
C. Cinq jours.
D. Aucun jour.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Madame Rossi, j''aimerais télétravailler trois jours par semaine.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">C''est trop : toute l''équipe doit être présente du lundi au mercredi. Je vous propose le jeudi et le vendredi à la maison.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Deux jours, c''est déjà bien. J''accepte.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Combien de jours par semaine le salarié va-t-il télétravailler ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Deux jours.<break time="700ms"/>B.<break time="300ms"/>Trois jours.<break time="700ms"/>C.<break time="300ms"/>Cinq jours.<break time="700ms"/>D.<break time="300ms"/>Aucun jour.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence numérique simple** : la présence est obligatoire du lundi au mercredi et la responsable propose « le jeudi et le vendredi à la maison », soit deux jours, que le salarié confirme (« deux jours, c''est déjà bien. J''accepte »). A est correct. B est la **demande initiale refusée** (« c''est trop ») — piège de la première information entendue ; elle répondrait à « combien de jours demandait-il ? ». C est impossible puisque trois jours de présence au bureau sont exigés. D contredit l''accord final : le salarié obtient bien une part de télétravail.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00a-1000-0000-000000000005', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Pour finaliser votre contrat, monsieur Morales, il me faut une copie de votre diplôme. Vous pouvez la déposer à l''accueil ?
[Homme] Je suis en déplacement à Lille toute la semaine. Je peux vous l''envoyer par courrier ?
[Femme] Un scan par e-mail suffit, c''est plus rapide.
[Homme] D''accord, je vous l''envoie ce soir.

Comment le candidat va-t-il transmettre son diplôme ?

A. En le déposant à l''accueil.
B. Par courrier postal.
C. Par e-mail.
D. En main propre, après son déplacement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Pour finaliser votre contrat, monsieur Morales, il me faut une copie de votre diplôme. Vous pouvez la déposer à l''accueil ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je suis en déplacement à Lille toute la semaine. Je peux vous l''envoyer par courrier ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Un scan par e-mail suffit, c''est plus rapide.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">D''accord, je vous l''envoie ce soir.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment le candidat va-t-il transmettre son diplôme ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En le déposant à l''accueil.<break time="700ms"/>B.<break time="300ms"/>Par courrier postal.<break time="700ms"/>C.<break time="300ms"/>Par e-mail.<break time="700ms"/>D.<break time="300ms"/>En main propre, après son déplacement.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question porte sur **le moyen de transmission finalement retenu** : inférence simple en trois étapes — le dépôt à l''accueil est impossible (déplacement à Lille), le courrier est écarté par la responsable (« un scan par e-mail suffit »), et le candidat conclut « d''accord, je vous l''envoie ce soir ». C est correct. A est la **première solution proposée puis rendue impossible** par le déplacement — piège de la première mention. B est l''idée du candidat, écartée au profit d''une solution plus rapide. D n''est jamais envisagé : le document part le soir même, sans attendre son retour.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00a-1000-0000-000000000006', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Madame Chen, pour la formation à la caisse, il y a une session mardi à Toulouse, ou un module en ligne à suivre quand vous voulez.
[Femme] Mardi, je remplace une collègue au magasin. Je vais donc suivre le module en ligne.
[Homme] Très bien, je vous envoie le lien d''inscription.

Pourquoi la salariée choisit-elle le module en ligne ?

A. Parce qu''elle habite loin de Toulouse.
B. Parce que la formation en ligne est plus courte.
C. Parce qu''elle n''aime pas les formations en groupe.
D. Parce qu''elle travaille le jour de la session.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Madame Chen, pour la formation à la caisse, il y a une session mardi à Toulouse, ou un module en ligne à suivre quand vous voulez.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Mardi, je remplace une collègue au magasin. Je vais donc suivre le module en ligne.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Très bien, je vous envoie le lien d''inscription.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi la salariée choisit-elle le module en ligne ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce qu''elle habite loin de Toulouse.<break time="700ms"/>B.<break time="300ms"/>Parce que la formation en ligne est plus courte.<break time="700ms"/>C.<break time="300ms"/>Parce qu''elle n''aime pas les formations en groupe.<break time="700ms"/>D.<break time="300ms"/>Parce qu''elle travaille le jour de la session.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « pourquoi ? » appelle **la cause du choix**. Inférence simple : il faut relier la date de la session (« mardi à Toulouse ») et l''empêchement de la salariée (« mardi, je remplace une collègue au magasin ») pour comprendre qu''elle est prise ce jour-là — D est correct. A, B et C sont des raisons **plausibles** de préférer une formation en ligne (distance, durée, préférence personnelle), mais aucune n''est mentionnée dans le dialogue : distracteurs purement thématiques. Piège B1 : retenir la cause réellement énoncée, pas une cause vraisemblable.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00a-1000-0000-000000000007', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonne nouvelle, madame Sharma : votre entretien nous a convaincus. Nous vous proposons un contrat de six mois pour commencer.
[Femme] J''espérais un poste permanent...
[Homme] Si tout se passe bien, le contrat deviendra définitif en janvier.
[Femme] Entendu, je signe pour les six mois.

Quel contrat la candidate accepte-t-elle ?

A. Un contrat de six mois.
B. Un contrat permanent immédiat.
C. Un stage de janvier à juin.
D. Aucun contrat pour le moment.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonne nouvelle, madame Sharma : votre entretien nous a convaincus. Nous vous proposons un contrat de six mois pour commencer.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">J''espérais un poste permanent...</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Si tout se passe bien, le contrat deviendra définitif en janvier.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Entendu, je signe pour les six mois.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel contrat la candidate accepte-t-elle ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un contrat de six mois.<break time="700ms"/>B.<break time="300ms"/>Un contrat permanent immédiat.<break time="700ms"/>C.<break time="300ms"/>Un stage de janvier à juin.<break time="700ms"/>D.<break time="300ms"/>Aucun contrat pour le moment.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence de décision finale** : la candidate espérait un poste permanent, mais après la promesse d''un contrat « définitif en janvier si tout se passe bien », elle conclut « je signe pour les six mois » — A est correct. B est son **souhait exprimé mais non satisfait** immédiatement : le poste permanent n''est qu''une possibilité future, pas le contrat signé. C recombine les repères entendus (« six mois », « janvier ») en un stage jamais évoqué — piège de recomposition. D contredit le verbe « je signe », qui marque explicitement l''acceptation.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00a-1000-0000-000000000008', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Vous pourriez commencer à quelle date ?

A. Dès le premier mars, si vous voulez.
B. Dans l''usine de Rennes.
C. Avec l''équipe du matin.
D. Parce que je suis disponible.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Vous pourriez commencer à quelle date ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dès le premier mars, si vous voulez.<break time="700ms"/>B.<break time="300ms"/>Dans l''usine de Rennes.<break time="700ms"/>C.<break time="300ms"/>Avec l''équipe du matin.<break time="700ms"/>D.<break time="300ms"/>Parce que je suis disponible.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « à quelle date ? » porte sur **le moment précis** : seule A « dès le premier mars » situe le début du travail dans le temps. B donne **un lieu** et répondrait à « où allez-vous travailler ? ». C donne **un accompagnement** et répondrait à « avec qui travaillerez-vous ? ». D, introduit par « parce que », donne **une cause** et répondrait à « pourquoi pouvez-vous commencer rapidement ? ». Mécanisme B1 : identifier la nature de l''information attendue par le mot interrogatif — les quatre réponses restent crédibles dans un entretien d''embauche.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00a-1000-0000-000000000009', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Vous avez travaillé combien d''années comme cuisinier ?

A. Dans une brasserie de Marseille.
B. Pendant sept ans, environ.
C. Tous les week-ends.
D. Pour gagner ma vie.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez travaillé combien d''années comme cuisinier ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dans une brasserie de Marseille.<break time="700ms"/>B.<break time="300ms"/>Pendant sept ans, environ.<break time="700ms"/>C.<break time="300ms"/>Tous les week-ends.<break time="700ms"/>D.<break time="300ms"/>Pour gagner ma vie.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Combien d''années ? » appelle **une durée** : seule B « pendant sept ans, environ » exprime une durée d''expérience, marquée par « pendant ». A donne **un lieu de travail** et répondrait à « où avez-vous travaillé ? ». C exprime **une fréquence** et répondrait à « à quel rythme travailliez-vous ? » — piège classique de la confusion durée/fréquence. D, introduit par « pour », donne **un but** et répondrait à « pourquoi travailliez-vous ? ». Mécanisme B1 : une question en « combien d''années » impose une réponse en durée, pas en lieu, en fréquence ni en but.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00a-1000-0000-00000000000a', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Pourquoi avez-vous quitté votre dernier emploi ?

A. Depuis le mois d''octobre.
B. À l''agence de Bordeaux.
C. Parce que l''entreprise a fermé.
D. Trois fois par semaine.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Pourquoi avez-vous quitté votre dernier emploi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis le mois d''octobre.<break time="700ms"/>B.<break time="300ms"/>À l''agence de Bordeaux.<break time="700ms"/>C.<break time="300ms"/>Parce que l''entreprise a fermé.<break time="700ms"/>D.<break time="300ms"/>Trois fois par semaine.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « pourquoi ? » appelle **une cause** : seule C, introduite par « parce que », explique le départ (« l''entreprise a fermé »). A, marqué par « depuis », donne **un point de départ dans le temps** et répondrait à « depuis quand êtes-vous sans emploi ? ». B donne **un lieu** et répondrait à « où travailliez-vous ? ». D exprime **une fréquence** et répondrait à « à quel rythme travailliez-vous ? ». Mécanisme B1 : repérer le connecteur de cause « parce que » — toutes les réponses évoquent la vie professionnelle, seul ce connecteur correspond au mot interrogatif.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes 66666666-b00a-1000-0000-000000000001 → 0a.
-- [x] Thème unique « entretien / travail », 10 situations toutes différentes :
--     choix entre 2 postes (nuit/journée), négociation salariale et avantages,
--     trajet domicile-travail, négociation du télétravail, transmission du
--     diplôme pour le contrat, choix d'une formation interne, type de contrat
--     accepté, date de début, durée d'expérience, motif de départ.
-- [x] Aucun thème interdit (logement, SAV, médical, banque, mairie, voyage,
--     restaurant-réservation, téléphonie, école, voiture, déménagement,
--     assurance, colis, hôtel, pharmacie).
-- [x] Répartition : 7 × format C (co_document_question, dialogues 3-4 répliques,
--     ~35-60 mots prononcés chacun, multi-voix Henri/Vivienne) + 3 × format B
--     (co_question_reponse, question Henri/Vivienne + propositions Denise).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : A=3 (items 4,7,8), B=2 (items 2,9),
--     C=3 (items 1,5,10), D=2 (items 3,6) — 4 positions utilisées, max 3.
-- [x] Inférence simple B1 : décision finale (1,4,7), cause de l'acceptation (2),
--     moyen retenu (3,5), cause du choix (6) ; explicite + distracteurs
--     proches sur la nature de la question (8,9,10).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**, mécanisme linguistique nommé
--     (inférence de décision, cause vs but, durée vs fréquence, connecteur).
-- [x] SSML : balises <voice>/<prosody> équilibrées, voix Denise 0.95 (narration)
--     / Henri & Vivienne 1.0 (dialogue), pauses 1500/1000/700/300 ms conformes.
-- [x] status='TEXT_VALIDATED', colonnes audio NULL, batch_id NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées (''), JSONB valide, aucun SVG requis (pas de
--     CO_IMAGE dans ce lot). Contenu 100 % original, prénoms et villes variés
--     (Traoré, Fernandez, Haddad, Rossi, Morales, Chen, Sharma · Lyon,
--     Strasbourg, Lille, Toulouse, Rennes, Marseille, Bordeaux).
-- ============================================================================
