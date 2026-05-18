-- ============================================================================
-- LOT PILOTE B1 — 10 questions audio (réponses dictées A/B/C/D)
-- ============================================================================
-- 📋 Insertion dans la table audio_question_draft
--
-- 🎯 Caractéristiques :
--    - Niveau : B1 (10/10)
--    - Module : TCF, type CO (Compréhension Orale)
--    - Format : audio inclut les 4 propositions A/B/C/D lues
--    - Énoncé standard : "Écoutez le document sonore..."
--    - Distracteurs B1 : ≥2 piégeux sur 3 (durcis conformément au référentiel)
--    - Stratégies : vrai mais hors champ, reformulation faussée,
--                   inversion de locuteur, presque-synonyme trompeur
--
-- 📊 10 thèmes différents (aucune répétition avec lot A2) :
--    1. Démarches admin  2. Banque   3. Voisinage  4. Études  5. Médias
--    6. Téléphone        7. Famille  8. Bricolage  9. Sport   10. Culture
--
-- 📌 Format des choices : seules les lettres A, B, C, D apparaissent.
--    Les contenus des réponses sont dans l'audio (transcript + SSML).
-- ============================================================================


-- ============================================================================
-- Q1 : DÉMARCHES ADMIN — Renouvellement titre de séjour (préfecture)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0011-0000-0000-000000000011', 'B1', 'co_comprendre_message_admin',
    '22222222-0000-0000-0000-000000000001',
    E'Bonjour, vous êtes bien sur la messagerie de la préfecture de Lyon, service des étrangers. Pour le renouvellement de votre titre de séjour, nous vous rappelons que la demande doit être déposée entre 4 mois et 2 mois avant la date d''expiration. Au-delà, des frais supplémentaires de 180 euros pourront s''appliquer. La prise de rendez-vous se fait uniquement en ligne, sur le site de la préfecture, rubrique « démarches étrangers ».\n\nQuand faut-il déposer la demande de renouvellement du titre de séjour ?\nA. Entre 4 mois et 2 mois avant la date d''expiration.\nB. Au moins 6 mois avant la date d''expiration.\nC. À tout moment, mais avec des frais supplémentaires de 180 euros.\nD. Le jour de l''expiration au plus tard.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Bonjour, vous êtes bien sur la messagerie de la préfecture de Lyon, service des étrangers.<break time="400ms"/> Pour le renouvellement de votre titre de séjour, nous vous rappelons que la demande doit être déposée entre 4 mois et 2 mois avant la date d''expiration.<break time="400ms"/> Au-delà, des frais supplémentaires de 180 euros pourront s''appliquer.<break time="400ms"/> La prise de rendez-vous se fait uniquement en ligne, sur le site de la préfecture, rubrique démarches étrangers.</prosody><break time="800ms"/><prosody rate="0.95">Quand faut-il déposer la demande de renouvellement du titre de séjour ?<break time="500ms"/>A.<break time="300ms"/>Entre 4 mois et 2 mois avant la date d''expiration.<break time="500ms"/>B.<break time="300ms"/>Au moins 6 mois avant la date d''expiration.<break time="500ms"/>C.<break time="300ms"/>À tout moment, mais avec des frais supplémentaires de 180 euros.<break time="500ms"/>D.<break time="300ms"/>Le jour de l''expiration au plus tard.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le message précise clairement : « la demande doit être déposée entre 4 mois et 2 mois avant la date d''expiration ». La réponse A est correcte. La réponse B propose un délai plus large (6 mois), proche mais incorrect — distracteur piégeux pour qui mémorise mal. La réponse C est une reformulation faussée : les 180 euros sont des frais en cas de dépôt tardif, pas une option valide pour déposer « à tout moment ». La réponse D inverse la logique de l''anticipation requise.',
    '[
      {
            "label": "A",
            "is_correct": true,
            "display_order": 1
      },
      {
            "label": "B",
            "is_correct": false,
            "display_order": 2
      },
      {
            "label": "C",
            "is_correct": false,
            "display_order": 3
      },
      {
            "label": "D",
            "is_correct": false,
            "display_order": 4
      }
]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q2 : BANQUE — Conversation conseiller (ouverture de compte)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0012-0000-0000-000000000012', 'B1', 'co_comprendre_dialogue',
    '22222222-0000-0000-0000-000000000001',
    E'— Bonjour, je voudrais ouvrir un compte courant chez vous.\n— Bien sûr ! Vous avez besoin de plusieurs documents : une pièce d''identité, un justificatif de domicile de moins de 3 mois, et un justificatif de revenus.\n— J''ai ma carte d''identité et ma fiche de paie, mais mon justificatif de domicile est une facture d''électricité de janvier dernier.\n— Si nous sommes en mai, cela fait plus de 3 mois. Je vais avoir besoin d''un document plus récent. Une quittance de loyer du mois dernier pourrait convenir.\n— D''accord, je vais l''apporter la semaine prochaine.\n\nPourquoi le conseiller refuse-t-il le justificatif de domicile du client ?\nA. Parce que les factures d''électricité ne sont pas acceptées.\nB. Parce que le document est trop ancien.\nC. Parce que le client n''a pas de quittance de loyer.\nD. Parce qu''il manque un autre document.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, je voudrais ouvrir un compte courant chez vous.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Bien sûr !<break time="200ms"/> Vous avez besoin de plusieurs documents :<break time="300ms"/> une pièce d''identité, un justificatif de domicile de moins de 3 mois, et un justificatif de revenus.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''ai ma carte d''identité et ma fiche de paie, mais mon justificatif de domicile est une facture d''électricité de janvier dernier.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Si nous sommes en mai, cela fait plus de 3 mois.<break time="300ms"/> Je vais avoir besoin d''un document plus récent.<break time="300ms"/> Une quittance de loyer du mois dernier pourrait convenir.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">D''accord, je vais l''apporter la semaine prochaine.</prosody></voice><break time="800ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi le conseiller refuse-t-il le justificatif de domicile du client ?<break time="500ms"/>A.<break time="300ms"/>Parce que les factures d''électricité ne sont pas acceptées.<break time="500ms"/>B.<break time="300ms"/>Parce que le document est trop ancien.<break time="500ms"/>C.<break time="300ms"/>Parce que le client n''a pas de quittance de loyer.<break time="500ms"/>D.<break time="300ms"/>Parce qu''il manque un autre document.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'La conseillère explique : « cela fait plus de 3 mois (...) Je vais avoir besoin d''un document plus récent ». La réponse B reformule cette raison. La réponse A est une généralisation abusive : la conseillère n''a pas rejeté les factures d''électricité en principe, mais ce document précis trop ancien. La réponse C inverse la logique : la quittance est suggérée comme solution, pas comme problème. La réponse D est piégeuse car le client a bien apporté les 3 types de documents demandés — c''est l''ancienneté du justificatif qui pose problème.',
    '[
      {"label": "A", "is_correct": false, "display_order": 1},
      {"label": "B", "is_correct": true, "display_order": 2},
      {"label": "C", "is_correct": false, "display_order": 3},
      {"label": "D", "is_correct": false, "display_order": 4}
    ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q3 : VOISINAGE — Message gardien (panne ascenseur)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0013-0000-0000-000000000013', 'B1', 'co_comprendre_message',
    '22222222-0000-0000-0000-000000000001',
    E'Bonjour à tous les résidents de la résidence Les Pommiers. Je vous informe que l''ascenseur du bâtiment C est en panne depuis ce matin. Le technicien est passé et il manque une pièce qui sera livrée mercredi. L''ascenseur sera donc réparé jeudi dans la journée. En attendant, je suis disponible pour aider les personnes âgées ou les familles avec poussette à monter leurs courses. N''hésitez pas à venir me voir à la loge.\n\nQuand l''ascenseur sera-t-il à nouveau fonctionnel ?\nA. Dès mercredi, après la livraison de la pièce.\nB. Dans la journée, après la réparation par le gardien\nC. Ce matin, quand le technicien repassera.\nD. Pendant la journée de jeudi..',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-HenriNeural"><prosody rate="0.95">Bonjour à tous les résidents de la résidence Les Pommiers.<break time="400ms"/> Je vous informe que l''ascenseur du bâtiment C est en panne depuis ce matin.<break time="400ms"/> Le technicien est passé et il manque une pièce qui sera livrée mercredi.<break time="400ms"/> L''ascenseur sera donc réparé jeudi dans la journée.<break time="400ms"/> En attendant, je suis disponible pour aider les personnes âgées ou les familles avec poussette à monter leurs courses.<break time="300ms"/> N''hésitez pas à venir me voir à la loge.</prosody><break time="800ms"/><prosody rate="0.95">Quand l''ascenseur sera-t-il à nouveau fonctionnel ?<break time="500ms"/>A.<break time="300ms"/>Dès mercredi, après la livraison de la pièce.<break time="500ms"/>B.<break time="300ms"/>Dans la journée, après la réparation par le gardien<break time="500ms"/>C.<break time="300ms"/>Ce matin, quand le technicien repassera.<break time="500ms"/>D.<break time="300ms"/>Pendant la journée de jeudi..</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le gardien précise : « L''ascenseur sera donc réparé jeudi dans la journée ». La réponse D reformule cette information. La réponse A est piégeuse : mercredi est la date de livraison de la pièce, mais pas celle de la réparation — confusion temporelle classique B1. La réponse C est une reformulation faussée : le technicien est passé, mais ne revient pas « ce matin ». La réponse B inverse le métier : c''est le technicien qui répare, pas le gardien (qui aide seulement à monter les courses).',
    '[
      {
            "label": "A",
            "is_correct": false,
            "display_order": 1
      },
      {
            "label": "B",
            "is_correct": false,
            "display_order": 2
      },
      {
            "label": "C",
            "is_correct": false,
            "display_order": 3
      },
      {
            "label": "D",
            "is_correct": true,
            "display_order": 4
      }
]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q4 : ÉTUDES — Annonce université (inscription examens)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0014-0000-0000-000000000014', 'B1', 'co_comprendre_annonce',
    '22222222-0000-0000-0000-000000000001',
    E'Chers étudiants, je vous rappelle que les inscriptions aux examens de la session de juin sont ouvertes jusqu''au 15 avril minuit. Les inscriptions se font exclusivement en ligne, depuis votre espace personnel. Attention, après cette date, plus aucune inscription ne sera acceptée, même avec un justificatif médical. Les étudiants en double cursus doivent prendre rendez-vous avec leur secrétariat pédagogique avant le 10 avril pour valider leur situation.\n\nQue se passe-t-il si un étudiant s''inscrit après le 15 avril ?\nA. Il peut s''inscrire avec un justificatif médical.\nB. Il devra prendre rendez-vous avec son secrétariat.\nC. Son inscription sera refusée sans exception.\nD. Il pourra passer ses examens en septembre.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Chers étudiants, je vous rappelle que les inscriptions aux examens de la session de juin sont ouvertes jusqu''au 15 avril minuit.<break time="400ms"/> Les inscriptions se font exclusivement en ligne, depuis votre espace personnel.<break time="400ms"/> Attention, après cette date, plus aucune inscription ne sera acceptée, même avec un justificatif médical.<break time="400ms"/> Les étudiants en double cursus doivent prendre rendez-vous avec leur secrétariat pédagogique avant le 10 avril pour valider leur situation.</prosody><break time="800ms"/><prosody rate="0.95">Que se passe-t-il si un étudiant s''inscrit après le 15 avril ?<break time="500ms"/>A.<break time="300ms"/>Il peut s''inscrire avec un justificatif médical.<break time="500ms"/>B.<break time="300ms"/>Il devra prendre rendez-vous avec son secrétariat.<break time="500ms"/>C.<break time="300ms"/>Son inscription sera refusée sans exception.<break time="500ms"/>D.<break time="300ms"/>Il pourra passer ses examens en septembre.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'L''annonce est très claire : « plus aucune inscription ne sera acceptée, même avec un justificatif médical ». La réponse C reformule cette règle stricte. La réponse A inverse exactement le propos (« même avec un justificatif médical » est explicitement exclu). La réponse B mélange deux infos : le rendez-vous secrétariat concerne les étudiants en double cursus, pas les retardataires. La réponse D invente une session de rattrapage non mentionnée.',
    '[
      {"label": "A", "is_correct": false, "display_order": 1},
      {"label": "B", "is_correct": false, "display_order": 2},
      {"label": "C", "is_correct": true, "display_order": 3},
      {"label": "D", "is_correct": false, "display_order": 4}
    ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q5 : MÉDIAS — Bulletin radio (météo + transports)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0015-0000-0000-000000000015', 'B1', 'co_comprendre_annonce',
    '22222222-0000-0000-0000-000000000001',
    E'Il est 8 heures, voici le point info. Sur les routes, attention : la circulation est très difficile autour de Paris en raison de la pluie. On compte déjà plus de 200 kilomètres de bouchons sur les autoroutes A6 et A10. Du côté des transports en commun, le métro fonctionne normalement, mais le RER C est interrompu entre Versailles et Paris à cause d''un incident technique. Reprise prévue vers 10 heures. Côté météo, les averses devraient cesser en fin de matinée.\n\nQu''est-ce qui perturbe les voyageurs ce matin ?\nA. La pluie sur les routes et un incident sur le RER C.\nB. Une grève des transports en commun.\nC. Un incident technique sur l''autoroute A6.\nD. Des averses sur les voies du métro parisien.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Il est 8 heures, voici le point info.<break time="400ms"/> Sur les routes, attention :<break time="300ms"/> la circulation est très difficile autour de Paris en raison de la pluie.<break time="300ms"/> On compte déjà plus de 200 kilomètres de bouchons sur les autoroutes A6 et A10.<break time="400ms"/> Du côté des transports en commun, le métro fonctionne normalement, mais le RER C est interrompu entre Versailles et Paris à cause d''un incident technique.<break time="300ms"/> Reprise prévue vers 10 heures.<break time="400ms"/> Côté météo, les averses devraient cesser en fin de matinée.</prosody><break time="800ms"/><prosody rate="0.95">Qu''est-ce qui perturbe les voyageurs ce matin ?<break time="500ms"/>A.<break time="300ms"/>La pluie sur les routes et un incident sur le RER C.<break time="500ms"/>B.<break time="300ms"/>Une grève des transports en commun.<break time="500ms"/>C.<break time="300ms"/>Un incident technique sur l''autoroute A6.<break time="500ms"/>D.<break time="300ms"/>Des averses sur les voies du métro parisien.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le bulletin mentionne deux problèmes : « la pluie » qui crée des bouchons sur la route, et « le RER C est interrompu (...) à cause d''un incident technique ». La réponse A combine ces deux éléments. La réponse B invente une grève non mentionnée. La réponse C mélange deux infos : l''incident technique est sur le RER, pas sur l''A6 (où il y a des bouchons à cause de la pluie). La réponse D est piégeuse : le métro fonctionne normalement, ce sont les averses qui touchent les routes.',
    '[
      {
            "label": "A",
            "is_correct": true,
            "display_order": 1
      },
      {
            "label": "B",
            "is_correct": false,
            "display_order": 2
      },
      {
            "label": "C",
            "is_correct": false,
            "display_order": 3
      },
      {
            "label": "D",
            "is_correct": false,
            "display_order": 4
      }
]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q6 : TÉLÉPHONE — Service client (réclamation forfait)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0016-0000-0000-000000000016', 'B1', 'co_comprendre_dialogue',
    '22222222-0000-0000-0000-000000000001',
    E'— Bonjour, je vous appelle parce que ma facture du mois est plus élevée que d''habitude. Je paye 35 euros normalement, et là c''est 58 euros.\n— Bonjour, je vais regarder votre dossier. Pouvez-vous me donner votre numéro de client ?\n— Oui, c''est le 7842156.\n— Je vois... Vous avez utilisé 4 gigas de plus que votre forfait, et il y a aussi un appel international vers le Maroc de 12 euros.\n— Ah, oui, j''ai appelé ma mère. Je pensais que c''était inclus.\n— Non, malheureusement, les appels vers l''étranger ne font pas partie du forfait standard. Vous pouvez ajouter une option à 5 euros par mois si vous appelez régulièrement.\n\nPourquoi la facture du client est-elle plus élevée que d''habitude ?\nA. Parce que le prix du forfait a augmenté.\nB. Parce qu''il a dépassé son forfait et appelé à l''étranger.\nC. Parce qu''il a oublié de payer le mois précédent.\nD. Parce qu''il a souscrit une nouvelle option à 5 euros.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, je vous appelle parce que ma facture du mois est plus élevée que d''habitude.<break time="200ms"/> Je paye 35 euros normalement, et là c''est 58 euros.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Bonjour, je vais regarder votre dossier.<break time="200ms"/> Pouvez-vous me donner votre numéro de client ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, c''est le 7842156.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Je vois...<break time="300ms"/> Vous avez utilisé 4 gigas de plus que votre forfait, et il y a aussi un appel international vers le Maroc de 12 euros.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Ah, oui, j''ai appelé ma mère.<break time="200ms"/> Je pensais que c''était inclus.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Non, malheureusement, les appels vers l''étranger ne font pas partie du forfait standard.<break time="200ms"/> Vous pouvez ajouter une option à 5 euros par mois si vous appelez régulièrement.</prosody></voice><break time="800ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi la facture du client est-elle plus élevée que d''habitude ?<break time="500ms"/>A.<break time="300ms"/>Parce que le prix du forfait a augmenté.<break time="500ms"/>B.<break time="300ms"/>Parce qu''il a dépassé son forfait et appelé à l''étranger.<break time="500ms"/>C.<break time="300ms"/>Parce qu''il a oublié de payer le mois précédent.<break time="500ms"/>D.<break time="300ms"/>Parce qu''il a souscrit une nouvelle option à 5 euros.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'La conseillère identifie deux causes : « Vous avez utilisé 4 gigas de plus que votre forfait, et il y a aussi un appel international vers le Maroc de 12 euros ». La réponse B combine fidèlement ces deux raisons. La réponse A invente une augmentation tarifaire non mentionnée. La réponse C invente un retard de paiement. La réponse D inverse la logique : l''option à 5 euros est proposée pour le futur, ce n''est pas la cause de la facture actuelle.',
    '[
      {"label": "A", "is_correct": false, "display_order": 1},
      {"label": "B", "is_correct": true, "display_order": 2},
      {"label": "C", "is_correct": false, "display_order": 3},
      {"label": "D", "is_correct": false, "display_order": 4}
    ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q7 : FAMILLE — Dialogue parents (activités enfants)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0017-0000-0000-000000000017', 'B1', 'co_comprendre_dialogue',
    '22222222-0000-0000-0000-000000000001',
    E'— Tu as réfléchi pour les activités de Lucas l''année prochaine ?\n— Oui, je pense qu''il faut choisir entre le football et la natation. Il aime les deux, mais je préfère la natation parce que c''est plus complet pour le corps.\n— Le problème, c''est que la piscine est loin et je travaille tard le mardi soir.\n— On peut peut-être trouver une solution avec ma sœur, qui pourrait l''emmener.\n— Bonne idée. Et pour Léa, je voudrais qu''elle continue le dessin, elle adore ça.\n— Oui, c''est décidé. Je m''occupe des inscriptions cette semaine.\n\nQuelle activité Lucas va-t-il probablement choisir ?\nA. Le football, car la piscine est trop loin.\nB. Aucune, car le papa travaille tard le mardi\nC. Le dessin, comme sa sœur Léa.\nD. La natation, grâce à l''aide d''un membre de la famille..',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as réfléchi pour les activités de Lucas l''année prochaine ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je pense qu''il faut choisir entre le football et la natation.<break time="200ms"/> Il aime les deux, mais je préfère la natation parce que c''est plus complet pour le corps.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Le problème, c''est que la piscine est loin et je travaille tard le mardi soir.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">On peut peut-être trouver une solution avec ma sœur, qui pourrait l''emmener.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Bonne idée.<break time="200ms"/> Et pour Léa, je voudrais qu''elle continue le dessin, elle adore ça.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, c''est décidé.<break time="200ms"/> Je m''occupe des inscriptions cette semaine.</prosody></voice><break time="800ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle activité Lucas va-t-il probablement choisir ?<break time="500ms"/>A.<break time="300ms"/>Le football, car la piscine est trop loin.<break time="500ms"/>B.<break time="300ms"/>Aucune, car le papa travaille tard le mardi<break time="500ms"/>C.<break time="300ms"/>Le dessin, comme sa sœur Léa.<break time="500ms"/>D.<break time="300ms"/>La natation, grâce à l''aide d''un membre de la famille..</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le père préfère la natation, la mère évoque le problème de la piscine, mais la solution est trouvée : « On peut peut-être trouver une solution avec ma sœur, qui pourrait l''emmener », acceptée par « Bonne idée ». La réponse D reformule cette conclusion. La réponse A est piégeuse car la piscine éloignée est évoquée comme problème, mais résolu. La réponse C confond Lucas avec sa sœur Léa. La réponse B inverse la logique : un problème mentionné mais résolu n''empêche pas l''inscription.',
    '[
      {
            "label": "A",
            "is_correct": false,
            "display_order": 1
      },
      {
            "label": "B",
            "is_correct": false,
            "display_order": 2
      },
      {
            "label": "C",
            "is_correct": false,
            "display_order": 3
      },
      {
            "label": "D",
            "is_correct": true,
            "display_order": 4
      }
]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q8 : BRICOLAGE — Conseil magasin (peinture)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0018-0000-0000-000000000018', 'B1', 'co_comprendre_dialogue',
    '22222222-0000-0000-0000-000000000001',
    E'— Bonjour, je voudrais repeindre la chambre de mon fils. Pouvez-vous me conseiller ?\n— Avec plaisir ! C''est une chambre d''enfant, donc je vous recommande une peinture sans solvant, pour éviter les odeurs et les produits chimiques. C''est un peu plus cher, mais c''est plus sain.\n— Et pour la couleur ? Mon fils veut absolument du bleu très foncé.\n— Je comprends, mais attention : les couleurs très foncées rendent la pièce plus petite et plus sombre. Si la chambre n''est pas très grande, je vous conseille plutôt un bleu clair ou pastel, qui agrandit visuellement la pièce.\n— D''accord, je vais essayer de le convaincre.\n\nQuel conseil principal la vendeuse donne-t-elle ?\nA. De choisir une peinture peu chère pour faire des économies.\nB. De prendre du bleu foncé pour faire plaisir à l''enfant.\nC. De privilégier la santé et adapter la couleur à la taille de la pièce.\nD. D''attendre que l''enfant soit plus grand pour repeindre.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Bonjour, je voudrais repeindre la chambre de mon fils.<break time="200ms"/> Pouvez-vous me conseiller ?</prosody></voice><voice name="fr-FR-VivienneMultilingualNeural"><prosody rate="1.0">Avec plaisir !<break time="200ms"/> C''est une chambre d''enfant, donc je vous recommande une peinture sans solvant, pour éviter les odeurs et les produits chimiques.<break time="200ms"/> C''est un peu plus cher, mais c''est plus sain.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et pour la couleur ?<break time="200ms"/> Mon fils veut absolument du bleu très foncé.</prosody></voice><voice name="fr-FR-VivienneMultilingualNeural"><prosody rate="1.0">Je comprends, mais attention :<break time="200ms"/> les couleurs très foncées rendent la pièce plus petite et plus sombre.<break time="200ms"/> Si la chambre n''est pas très grande, je vous conseille plutôt un bleu clair ou pastel, qui agrandit visuellement la pièce.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">D''accord, je vais essayer de le convaincre.</prosody></voice><break time="800ms"/><voice name="fr-FR-VivienneMultilingualNeural"><prosody rate="0.95">Quel conseil principal la vendeuse donne-t-elle ?<break time="500ms"/>A.<break time="300ms"/>De choisir une peinture peu chère pour faire des économies.<break time="500ms"/>B.<break time="300ms"/>De prendre du bleu foncé pour faire plaisir à l''enfant.<break time="500ms"/>C.<break time="300ms"/>De privilégier la santé et adapter la couleur à la taille de la pièce.<break time="500ms"/>D.<break time="300ms"/>D''attendre que l''enfant soit plus grand pour repeindre.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'La vendeuse donne deux conseils combinés : peinture « sans solvant (...) plus sain » (santé) et « les couleurs très foncées rendent la pièce plus petite (...) je vous conseille plutôt un bleu clair » (adaptation à la pièce). La réponse C résume fidèlement. La réponse A inverse le propos : la vendeuse dit que la peinture saine est « un peu plus cher ». La réponse B inverse la recommandation sur la couleur. La réponse D invente un conseil non donné.',
    '[
      {"label": "A", "is_correct": false, "display_order": 1},
      {"label": "B", "is_correct": false, "display_order": 2},
      {"label": "C", "is_correct": true, "display_order": 3},
      {"label": "D", "is_correct": false, "display_order": 4}
    ]'::jsonb,
    'fr-FR-VivienneMultilingualNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q9 : SPORT — Annonce club (inscription saison)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0019-0000-0000-000000000019', 'B1', 'co_comprendre_annonce',
    '22222222-0000-0000-0000-000000000001',
    E'Bienvenue au Club Sportif des Cèdres ! Pour la nouvelle saison, nos inscriptions ouvrent le 1er septembre. Nous proposons trois disciplines : tennis, judo et danse. Bonne nouvelle pour les familles : à partir du deuxième enfant inscrit, vous bénéficiez de 20 % de réduction sur la cotisation annuelle. Attention, un certificat médical de moins de 6 mois est obligatoire pour tous les nouveaux inscrits. Pour les anciens membres, il est demandé tous les 3 ans.\n\nÀ qui le certificat médical est-il demandé chaque année ?\nA. Uniquement aux nouveaux inscrits.\nB. À tous les inscrits, sans exception.\nC. Uniquement aux anciens membres après 3 ans.\nD. Uniquement aux enfants à partir du deuxième inscrit.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Bienvenue au Club Sportif des Cèdres !<break time="400ms"/> Pour la nouvelle saison, nos inscriptions ouvrent le 1er septembre.<break time="300ms"/> Nous proposons trois disciplines :<break time="200ms"/> tennis, judo et danse.<break time="400ms"/> Bonne nouvelle pour les familles :<break time="300ms"/> à partir du deuxième enfant inscrit, vous bénéficiez de 20 % de réduction sur la cotisation annuelle.<break time="400ms"/> Attention, un certificat médical de moins de 6 mois est obligatoire pour tous les nouveaux inscrits.<break time="300ms"/> Pour les anciens membres, il est demandé tous les 3 ans.</prosody><break time="800ms"/><prosody rate="0.95">À qui le certificat médical est-il demandé chaque année ?<break time="500ms"/>A.<break time="300ms"/>Uniquement aux nouveaux inscrits.<break time="500ms"/>B.<break time="300ms"/>À tous les inscrits, sans exception.<break time="500ms"/>C.<break time="300ms"/>Uniquement aux anciens membres après 3 ans.<break time="500ms"/>D.<break time="300ms"/>Uniquement aux enfants à partir du deuxième inscrit.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'L''annonce distingue deux cas : « obligatoire pour tous les nouveaux inscrits » (chaque année puisqu''ils s''inscrivent une fois) et « pour les anciens membres, il est demandé tous les 3 ans ». La question demande qui doit le fournir CHAQUE année : seuls les nouveaux. La réponse A est correcte. La réponse B est une généralisation abusive : les anciens membres ne le fournissent que tous les 3 ans. La réponse C inverse le propos. La réponse D confond avec la réduction (20%) qui concerne le deuxième enfant.',
    '[
      {
            "label": "A",
            "is_correct": true,
            "display_order": 1
      },
      {
            "label": "B",
            "is_correct": false,
            "display_order": 2
      },
      {
            "label": "C",
            "is_correct": false,
            "display_order": 3
      },
      {
            "label": "D",
            "is_correct": false,
            "display_order": 4
      }
]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q10 : CULTURE — Guide musée (présentation visite)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0020-0000-0000-000000000020', 'B1', 'co_comprendre_annonce',
    '22222222-0000-0000-0000-000000000001',
    E'Mesdames et messieurs, bienvenue au musée d''Histoire Naturelle. La visite guidée que vous allez suivre dure environ une heure trente. Nous commencerons par la galerie des dinosaures, puis nous passerons à la salle des minéraux, et nous terminerons par l''exposition temporaire sur les océans. Je vous demande de bien vouloir éteindre vos téléphones, et de ne pas utiliser le flash pour photographier les œuvres. Si vous avez des questions, vous pouvez les poser à la fin de chaque salle.\n\nPar quelle salle la visite va-t-elle commencer ?\nA. Par l''exposition temporaire sur les océans.\nB. Par la salle des minéraux.\nC. Par la salle où l''on peut prendre des photos\nD. Par la galerie des dinosaures..',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-VivienneMultilingualNeural"><prosody rate="0.95">Mesdames et messieurs, bienvenue au musée d''Histoire Naturelle.<break time="400ms"/> La visite guidée que vous allez suivre dure environ une heure trente.<break time="400ms"/> Nous commencerons par la galerie des dinosaures, puis nous passerons à la salle des minéraux, et nous terminerons par l''exposition temporaire sur les océans.<break time="400ms"/> Je vous demande de bien vouloir éteindre vos téléphones, et de ne pas utiliser le flash pour photographier les œuvres.<break time="400ms"/> Si vous avez des questions, vous pouvez les poser à la fin de chaque salle.</prosody><break time="800ms"/><prosody rate="0.95">Par quelle salle la visite va-t-elle commencer ?<break time="500ms"/>A.<break time="300ms"/>Par l''exposition temporaire sur les océans.<break time="500ms"/>B.<break time="300ms"/>Par la salle des minéraux.<break time="500ms"/>C.<break time="300ms"/>Par la salle où l''on peut prendre des photos<break time="500ms"/>D.<break time="300ms"/>Par la galerie des dinosaures..</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le guide précise l''ordre : « Nous commencerons par la galerie des dinosaures, puis nous passerons à la salle des minéraux, et nous terminerons par l''exposition temporaire sur les océans ». La réponse D est correcte. La réponse A inverse l''ordre (les océans sont la fin). La réponse B place les minéraux au début, alors qu''ils sont au milieu. La réponse C est piégeuse : aucune salle dédiée aux photos n''existe, le flash étant interdit dans tout le musée.',
    '[
      {
            "label": "A",
            "is_correct": false,
            "display_order": 1
      },
      {
            "label": "B",
            "is_correct": false,
            "display_order": 2
      },
      {
            "label": "C",
            "is_correct": false,
            "display_order": 3
      },
      {
            "label": "D",
            "is_correct": true,
            "display_order": 4
      }
]'::jsonb,
    'fr-FR-VivienneMultilingualNeural', 'TEXT_VALIDATED'
);
