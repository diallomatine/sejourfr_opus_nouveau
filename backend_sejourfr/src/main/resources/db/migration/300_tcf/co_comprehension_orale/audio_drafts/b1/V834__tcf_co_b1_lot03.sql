-- ============================================================================
-- V834 — TCF CO B1 — lot 03 (thème : rendez-vous médical)
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
  ('66666666-b003-1000-0000-000000000001', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Cabinet du docteur Lemoine, bonjour. Pour votre rappel de vaccin, il me reste mardi à huit heures ou vendredi à dix-huit heures trente.
[Homme] Le matin, c''est impossible : je commence à l''usine à sept heures. Je prends le créneau de vendredi.
[Femme] Parfait, monsieur Diabaté, c''est noté.

Quand le patient viendra-t-il au cabinet ?

A. Mardi à huit heures.
B. Vendredi à dix-huit heures trente.
C. Samedi matin, avant son travail.
D. Il rappellera la semaine prochaine.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Cabinet du docteur Lemoine, bonjour. Pour votre rappel de vaccin, il me reste mardi à huit heures ou vendredi à dix-huit heures trente.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Le matin, c''est impossible : je commence à l''usine à sept heures. Je prends le créneau de vendredi.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Parfait, monsieur Diabaté, c''est noté.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quand le patient viendra-t-il au cabinet ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Mardi à huit heures.<break time="700ms"/>B.<break time="300ms"/>Vendredi à dix-huit heures trente.<break time="700ms"/>C.<break time="300ms"/>Samedi matin, avant son travail.<break time="700ms"/>D.<break time="300ms"/>Il rappellera la semaine prochaine.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple contrainte → choix** : il faut relier « je commence à l''usine à sept heures » (le matin est impossible) et « je prends le créneau de vendredi » pour conclure que B est correct. A est le créneau **proposé puis écarté** — piège de la première information entendue ; il répondrait à « quel créneau était aussi disponible ? ». C n''est jamais évoqué : aucun rendez-vous le samedi n''est proposé. D contredit la fin du dialogue, où la secrétaire confirme « c''est noté » : le rendez-vous est bien pris.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b003-1000-0000-000000000002', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] La consultation fait vingt-six euros, madame Alvarez. Par contre, notre terminal de carte est en panne ce matin.
[Femme] Ah… Je n''ai pas de chéquier. Vous acceptez les espèces ?
[Homme] Bien sûr.
[Femme] Alors je retire de l''argent au distributeur d''en face et je reviens tout de suite.

Comment la patiente va-t-elle régler la consultation ?

A. Par carte bancaire.
B. Par chèque.
C. Par virement.
D. En espèces.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">La consultation fait vingt-six euros, madame Alvarez. Par contre, notre terminal de carte est en panne ce matin.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Ah… Je n''ai pas de chéquier. Vous acceptez les espèces ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bien sûr.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Alors je retire de l''argent au distributeur d''en face et je reviens tout de suite.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment la patiente va-t-elle régler la consultation ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Par carte bancaire.<break time="700ms"/>B.<break time="300ms"/>Par chèque.<break time="700ms"/>C.<break time="300ms"/>Par virement.<break time="700ms"/>D.<break time="300ms"/>En espèces.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Moyen de paiement final déduit par inférence simple** : la carte est éliminée (« terminal en panne »), le chèque aussi (« je n''ai pas de chéquier ») ; restent les espèces, confirmées par « je retire de l''argent au distributeur ». D est correct. A est le moyen rendu **impossible par la panne** — piège de la première mention. B est écarté par la patiente elle-même, qui n''a pas de chéquier. C n''est jamais évoqué dans le dialogue : distracteur thématique plausible mais hors document. Mécanisme B1 : relier les deux éliminations pour déduire le choix final.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b003-1000-0000-000000000003', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Monsieur Haddad, cette carie doit être soignée. Je peux le faire maintenant, mais il faut compter une heure. Sinon, revenez demain à neuf heures.
[Homme] Une heure ? J''ai une réunion dans trente minutes… Je reviendrai demain, alors.
[Femme] Très bien, je vous note à neuf heures.

Que décide le patient ?

A. Revenir demain matin pour le soin.
B. Se faire soigner immédiatement.
C. Annuler sa réunion de travail.
D. Prendre seulement un médicament contre la douleur.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Monsieur Haddad, cette carie doit être soignée. Je peux le faire maintenant, mais il faut compter une heure. Sinon, revenez demain à neuf heures.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Une heure ? J''ai une réunion dans trente minutes… Je reviendrai demain, alors.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Très bien, je vous note à neuf heures.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que décide le patient ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Revenir demain matin pour le soin.<break time="700ms"/>B.<break time="300ms"/>Se faire soigner immédiatement.<break time="700ms"/>C.<break time="300ms"/>Annuler sa réunion de travail.<break time="700ms"/>D.<break time="300ms"/>Prendre seulement un médicament contre la douleur.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence de décision finale** : il faut relier la contrainte du patient (« j''ai une réunion dans trente minutes », incompatible avec un soin d''une heure) et sa conclusion « je reviendrai demain », confirmée par la dentiste (« je vous note à neuf heures »). A est correct. B est l''option **proposée puis écartée**, justement à cause de la durée du soin. C inverse le raisonnement : le patient protège sa réunion au lieu de l''annuler. D n''est jamais évoqué : aucun médicament n''apparaît dans le dialogue, distracteur thématique hors document.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b003-1000-0000-000000000004', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, c''est madame Bondarenko. J''ai trente-neuf de fièvre, il me faudrait un rendez-vous aujourd''hui.
[Homme] Le docteur n''a plus de place avant lundi. Mais il propose des téléconsultations : il peut vous voir en vidéo à dix-sept heures.
[Femme] D''accord pour la vidéo, je ne peux pas attendre lundi.

Que va faire la patiente ?

A. Attendre le rendez-vous de lundi.
B. Aller aux urgences de l''hôpital.
C. Consulter le médecin en vidéo aujourd''hui.
D. Rappeler un autre cabinet médical.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, c''est madame Bondarenko. J''ai trente-neuf de fièvre, il me faudrait un rendez-vous aujourd''hui.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Le docteur n''a plus de place avant lundi. Mais il propose des téléconsultations : il peut vous voir en vidéo à dix-sept heures.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">D''accord pour la vidéo, je ne peux pas attendre lundi.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que va faire la patiente ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Attendre le rendez-vous de lundi.<break time="700ms"/>B.<break time="300ms"/>Aller aux urgences de l''hôpital.<break time="700ms"/>C.<break time="300ms"/>Consulter le médecin en vidéo aujourd''hui.<break time="700ms"/>D.<break time="300ms"/>Rappeler un autre cabinet médical.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple problème → solution acceptée** : il faut relier l''urgence de la patiente (« je ne peux pas attendre lundi ») et la proposition du secrétaire (téléconsultation « en vidéo à dix-sept heures »), qu''elle accepte explicitement (« d''accord pour la vidéo »). C est correct. A est précisément l''option **refusée** : attendre lundi est impossible avec sa fièvre. B n''est jamais évoqué dans le dialogue : distracteur thématique plausible en cas d''urgence, mais hors document. D contredit l''accord conclu : la patiente accepte la solution de ce cabinet, elle n''a aucune raison d''en appeler un autre.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b003-1000-0000-000000000005', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Monsieur Costa ? C''est le secrétariat du docteur Morel. La docteure a été appelée en urgence à l''hôpital : votre rendez-vous de seize heures est reporté à jeudi.
[Homme] Ah, d''accord. Jeudi à la même heure ?
[Femme] Oui, seize heures, c''est noté.

Pourquoi le rendez-vous est-il reporté ?

A. Parce que le patient a un empêchement.
B. Parce que la docteure a une urgence à l''hôpital.
C. Parce que le cabinet est fermé pour travaux.
D. Parce que la secrétaire a fait une erreur de planning.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Monsieur Costa ? C''est le secrétariat du docteur Morel. La docteure a été appelée en urgence à l''hôpital : votre rendez-vous de seize heures est reporté à jeudi.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Ah, d''accord. Jeudi à la même heure ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Oui, seize heures, c''est noté.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi le rendez-vous est-il reporté ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce que le patient a un empêchement.<break time="700ms"/>B.<break time="300ms"/>Parce que la docteure a une urgence à l''hôpital.<break time="700ms"/>C.<break time="300ms"/>Parce que le cabinet est fermé pour travaux.<break time="700ms"/>D.<break time="300ms"/>Parce que la secrétaire a fait une erreur de planning.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « pourquoi ? » appelle **une cause**, et la secrétaire l''énonce explicitement : « la docteure a été appelée en urgence à l''hôpital » — B est correct. A inverse les rôles : c''est la médecin qui est indisponible, pas le patient, qui accepte simplement le report. C et D sont deux causes **plausibles d''annulation** dans un cabinet médical (travaux, erreur de planning), mais aucune n''est citée dans le dialogue : distracteurs purement thématiques. Piège B1 : retenir la cause réellement donnée, pas une cause vraisemblable, et identifier **qui** est à l''origine du report.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b003-1000-0000-000000000006', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, je voudrais un rendez-vous avec l''ophtalmologue pour renouveler mes lunettes. Je m''appelle Wei Zhang.
[Femme] Ici, à Besançon, le premier créneau est dans cinq mois. Mais notre cabinet de Dole reçoit sous trois semaines.
[Homme] Dole, c''est à trente minutes en train… Je préfère ça plutôt qu''attendre cinq mois.

Que décide finalement le patient ?

A. Attendre cinq mois à Besançon.
B. Renoncer à changer de lunettes.
C. Prendre rendez-vous au cabinet de Dole.
D. Acheter des lunettes sans ordonnance.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, je voudrais un rendez-vous avec l''ophtalmologue pour renouveler mes lunettes. Je m''appelle Wei Zhang.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Ici, à Besançon, le premier créneau est dans cinq mois. Mais notre cabinet de Dole reçoit sous trois semaines.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Dole, c''est à trente minutes en train… Je préfère ça plutôt qu''attendre cinq mois.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que décide finalement le patient ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Attendre cinq mois à Besançon.<break time="700ms"/>B.<break time="300ms"/>Renoncer à changer de lunettes.<break time="700ms"/>C.<break time="300ms"/>Prendre rendez-vous au cabinet de Dole.<break time="700ms"/>D.<break time="300ms"/>Acheter des lunettes sans ordonnance.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence de décision finale** : « je préfère ça » renvoie à la proposition qui précède — le cabinet de Dole, qui reçoit « sous trois semaines » —, opposée à « attendre cinq mois ». Il faut relier le pronom « ça » à son antécédent pour conclure que C est correct. A est l''option explicitement **rejetée** par la comparaison « plutôt qu''attendre cinq mois ». B contredit la démarche du patient, qui accepte une solution au lieu d''abandonner. D n''est jamais évoqué : on renouvelle l''ordonnance chez l''ophtalmologue, distracteur thématique hors document. Mécanisme B1 : résolution de la **référence pronominale**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b003-1000-0000-000000000007', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, je dois faire une prise de sang pour mon bilan annuel. Il faut un rendez-vous ?
[Homme] Non, madame Camara, venez directement. Mais attention : pour ce bilan, il faut être à jeun. Ne mangez rien à partir de minuit.
[Femme] D''accord, alors je viendrai demain à sept heures et demie, avant mon petit-déjeuner.

Que doit faire la patiente avant sa prise de sang ?

A. Ne rien manger à partir de minuit.
B. Prendre un rendez-vous par téléphone.
C. Prendre un petit-déjeuner léger.
D. Apporter son carnet de vaccination.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, je dois faire une prise de sang pour mon bilan annuel. Il faut un rendez-vous ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Non, madame Camara, venez directement. Mais attention : pour ce bilan, il faut être à jeun. Ne mangez rien à partir de minuit.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">D''accord, alors je viendrai demain à sept heures et demie, avant mon petit-déjeuner.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que doit faire la patiente avant sa prise de sang ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ne rien manger à partir de minuit.<break time="700ms"/>B.<break time="300ms"/>Prendre un rendez-vous par téléphone.<break time="700ms"/>C.<break time="300ms"/>Prendre un petit-déjeuner léger.<break time="700ms"/>D.<break time="300ms"/>Apporter son carnet de vaccination.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La consigne est explicite : « il faut être à jeun. Ne mangez rien à partir de minuit » — A est correct. Comprendre **« être à jeun »** demande une inférence lexicale simple, confirmée par la patiente qui vient « avant son petit-déjeuner ». B est précisément ce qui est **inutile** : le laborantin répond « non, venez directement » à la question du rendez-vous. C contredit frontalement la consigne : un petit-déjeuner, même léger, rompt le jeûne — piège d''inversion. D n''est jamais mentionné : le carnet de vaccination appartient au contexte médical mais reste hors document.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b003-1000-0000-000000000008', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Pourquoi souhaitez-vous voir le docteur aujourd''hui ?

A. Demain après-midi, si possible.
B. Au deuxième étage du cabinet.
C. Avec mon fils aîné.
D. Parce que je tousse depuis une semaine.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pourquoi souhaitez-vous voir le docteur aujourd''hui ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Demain après-midi, si possible.<break time="700ms"/>B.<break time="300ms"/>Au deuxième étage du cabinet.<break time="700ms"/>C.<break time="300ms"/>Avec mon fils aîné.<break time="700ms"/>D.<break time="300ms"/>Parce que je tousse depuis une semaine.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Pourquoi ? » appelle **une cause**, marquée par « parce que » : seule D « parce que je tousse depuis une semaine » donne le motif de la consultation. A indique **un moment** et répondrait à « quand voulez-vous venir ? ». B indique **un lieu** et répondrait à « où se trouve le cabinet ? ». C indique **un accompagnant** et répondrait à « avec qui venez-vous ? ». Mécanisme B1 : identifier le mot interrogatif et la nature de l''information attendue — les quatre réponses restent crédibles dans le contexte du rendez-vous médical, seule la cause convient.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b003-1000-0000-000000000009', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Le cabinet de la docteure N''Diaye se trouve où, exactement ?

A. Le mardi et le jeudi seulement.
B. Trente-cinq euros la consultation.
C. Au dix, rue des Acacias, près du marché couvert.
D. Sur rendez-vous uniquement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Le cabinet de la docteure N''Diaye se trouve où, exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le mardi et le jeudi seulement.<break time="700ms"/>B.<break time="300ms"/>Trente-cinq euros la consultation.<break time="700ms"/>C.<break time="300ms"/>Au dix, rue des Acacias, près du marché couvert.<break time="700ms"/>D.<break time="300ms"/>Sur rendez-vous uniquement.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Se trouve où ? » demande **un lieu** : seule C donne une adresse (« au dix, rue des Acacias, près du marché couvert »). A indique **des jours d''ouverture** et répondrait à « quand la docteure consulte-t-elle ? ». B donne **un prix** et répondrait à « combien coûte la consultation ? ». D indique **une modalité d''accès** et répondrait à « comment peut-on consulter ? ». Piège B1 classique : toutes les réponses parlent du même cabinet médical, seule la nature de la question — une localisation — permet de trancher.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b003-1000-0000-00000000000a', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Vous préférez votre rendez-vous de contrôle le matin ou l''après-midi ?

A. Chez le cardiologue, de préférence.
B. Plutôt le matin, avant mon travail.
C. Une fois par an, environ.
D. Depuis le mois de janvier.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous préférez votre rendez-vous de contrôle le matin ou l''après-midi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Chez le cardiologue, de préférence.<break time="700ms"/>B.<break time="300ms"/>Plutôt le matin, avant mon travail.<break time="700ms"/>C.<break time="300ms"/>Une fois par an, environ.<break time="700ms"/>D.<break time="300ms"/>Depuis le mois de janvier.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question est une **interrogation alternative** (« le matin ou l''après-midi ? ») : la réponse doit choisir l''une des deux options. Seule B « plutôt le matin, avant mon travail » reprend un des deux termes proposés. A indique **un praticien ou un lieu** et répondrait à « chez qui prenez-vous rendez-vous ? ». C exprime **une fréquence** et répondrait à « tous les combien faites-vous un contrôle ? ». D, avec « depuis », marque **un point de départ dans le temps** et répondrait à « depuis quand êtes-vous suivi ? ». Mécanisme B1 : une question alternative impose de retenir l''un des deux termes énoncés, pas une autre information temporelle.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes 66666666-b003-1000-0000-000000000001 → 0a.
-- [x] Thème unique « rendez-vous médical », 10 situations toutes différentes :
--     choix d'un créneau de vaccination, paiement de la consultation, décision
--     chez le dentiste, acceptation d'une téléconsultation, report de
--     rendez-vous pour urgence, choix d'un cabinet d'ophtalmologie plus
--     rapide, consigne de jeûne avant prise de sang, motif de consultation,
--     adresse du cabinet, préférence matin/après-midi.
-- [x] Aucun thème interdit (logement, SAV, banque, mairie, voyage, restaurant,
--     téléphonie, école, travail, voiture, déménagement, assurance, colis,
--     hôtel, pharmacie) — tout se passe en cabinet médical / laboratoire.
-- [x] Répartition : 7 × format C (co_document_question, dialogues 3-4 répliques,
--     ~35-65 mots prononcés chacun, multi-voix Henri/Vivienne) + 3 × format B
--     (co_question_reponse, question Henri/Vivienne + propositions Denise).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : A=2 (items 3,7), B=3 (items 1,5,10),
--     C=3 (items 4,6,9), D=2 (items 2,8) — 4 positions utilisées, max 3.
-- [x] Inférence simple B1 : contrainte → choix (1), moyen de paiement par
--     double élimination (2), décision finale (3,4), référence pronominale (6),
--     inférence lexicale « à jeun » (7) ; explicite + distracteurs proches
--     (5,8,9,10).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**, mécanisme linguistique nommé
--     (inférence simple, cause vs but, référence pronominale, interrogation
--     alternative, rection interrogative).
-- [x] SSML : balises <voice>/<prosody> équilibrées, voix Denise 0.95 (narration)
--     / Henri & Vivienne 1.0 (dialogue), pauses 1500/1000/700/300 ms conformes.
-- [x] status='TEXT_VALIDATED', colonnes audio NULL, batch_id NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées (''), JSONB valide, aucun SVG requis (pas de
--     CO_IMAGE dans ce lot). Contenu 100 % original, prénoms et villes variés
--     (Diabaté, Alvarez, Haddad, Bondarenko, Costa, Wei Zhang, Camara,
--     N'Diaye — Besançon, Dole).
-- ============================================================================
