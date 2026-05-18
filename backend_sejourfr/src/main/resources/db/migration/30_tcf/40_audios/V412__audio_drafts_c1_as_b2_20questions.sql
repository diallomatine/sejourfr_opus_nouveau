-- ============================================================
-- 20 exercices C1 - CO TCF - format "réponse à question implicite"
-- IMPORTANT : niveau pédagogique réel = C1, stocké en difficulty='B2'
-- car l'enum Java backend ne connaît actuellement que A2/B1/B2.
-- Traçabilité du niveau réel C1 :
--   - préfixe UUID : 66666666-00c1-1000-...
--   - competence_code : 'co_dialogue_c1_implicite'
-- Dialogues plus denses (3 à 5 tours, majorité 4-5), implicites multiples,
-- sous-entendus, lexique soutenu. Labels JSON = "A"/"B"/"C"/"D".
-- Position de la bonne réponse équilibrée : 5×A, 5×B, 5×C, 5×D.
-- Voix : 10 Henri / 10 Denise sur voice_recommended.
-- ============================================================

-- ----- Exercice 1 : Nuance fine entre deux concepts / professionnel / 4 tours / bonne réponse A -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-000000000001', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu dis que ce que tu fais relève de la médiation, pas de la négociation. La distinction me semble subtile.\n[Femme] Et pourtant, dans ma pratique quotidienne, elle est fondamentale.\n[Homme] Vraiment ? Tout le monde tend pourtant à confondre les deux.\n[Femme] À tort. En quoi est-ce subtilement différent, selon toi ?\n[Homme] ...\n\nA. Le médiateur ne défend aucune partie, il restaure un dialogue ; le négociateur, lui, arrache un accord.\nB. Sous couvert de neutralité, le médiateur impose en réalité ses propres vues.\nC. À l''aune des conventions internationales, la médiation a vu son cadre se durcir.\nD. Moyennant une formation longue, on peut basculer d''un métier à l''autre sans grande difficulté.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu dis que ce que tu fais relève de la médiation, pas de la négociation. La distinction me semble subtile.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et pourtant, dans ma pratique quotidienne, elle est fondamentale.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vraiment ? Tout le monde tend pourtant à confondre les deux.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">À tort. En quoi est-ce subtilement différent, selon toi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le médiateur ne défend aucune partie, il restaure un dialogue ; le négociateur, lui, arrache un accord.<break time="700ms"/>B.<break time="300ms"/>Sous couvert de neutralité, le médiateur impose en réalité ses propres vues.<break time="700ms"/>C.<break time="300ms"/>À l''aune des conventions internationales, la médiation a vu son cadre se durcir.<break time="700ms"/>D.<break time="300ms"/>Moyennant une formation longue, on peut basculer d''un métier à l''autre sans grande difficulté.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours posent le contraste médiation/négociation que l''interlocuteur juge subtil ; le troisième en renforce la confusion ordinaire ; la question finale (« en quoi est-ce subtilement différent ? ») demande **la nuance opératoire fine entre les deux notions**. Seule A formule cette nuance pragmatique exacte : finalité (restaurer un dialogue vs arracher un accord) et posture (neutre vs partisane). B fait un **procès d''intention** au médiateur (« sous couvert de neutralité... ») et répond à « qu''est-ce qu''on peut reprocher à la médiation ? ». C donne **un cadre juridique évolutif** (« comment le droit a-t-il fait évoluer la médiation ? »). D évoque la **passerelle professionnelle** entre les deux métiers (« peut-on passer de l''un à l''autre ? ») — piège fin C1 car elle accepte implicitement la distinction sans la définir.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 2 : Paradoxe apparent / sociétal / 4 tours / bonne réponse B -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-000000000002', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Les chiffres du bénévolat n''ont jamais été aussi élevés dans la région.\n[Homme] Étonnant, dans une période où chacun se replie sur soi.\n[Femme] Justement, c''est ce qui m''intrigue : on n''a jamais autant dénoncé l''individualisme, et pourtant les associations ne désemplissent pas.\n[Homme] Où est le paradoxe, exactement ?\n[Femme] ...\n\nA. Le bénévolat finit par essouffler ceux qui s''y dévouent trop longtemps.\nB. On déplore un repli généralisé là même où, en pratique, les gens s''engagent comme jamais pour autrui.\nC. Les jeunes générations se montrent plus engagées que leurs aînés ne le furent à leur âge.\nD. Les associations souffrent malgré tout d''un manque chronique de financements publics.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Les chiffres du bénévolat n''ont jamais été aussi élevés dans la région.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Étonnant, dans une période où chacun se replie sur soi.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Justement, c''est ce qui m''intrigue : on n''a jamais autant dénoncé l''individualisme, et pourtant les associations ne désemplissent pas.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Où est le paradoxe, exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le bénévolat finit par essouffler ceux qui s''y dévouent trop longtemps.<break time="700ms"/>B.<break time="300ms"/>On déplore un repli généralisé là même où, en pratique, les gens s''engagent comme jamais pour autrui.<break time="700ms"/>C.<break time="300ms"/>Les jeunes générations se montrent plus engagées que leurs aînés ne le furent à leur âge.<break time="700ms"/>D.<break time="300ms"/>Les associations souffrent malgré tout d''un manque chronique de financements publics.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le dialogue construit en quatre tours une tension entre **discours dominant** (individualisme déploré) et **réalité observée** (bénévolat record). La question « où est le paradoxe ? » demande **l''identification précise de la contradiction logique entre les deux faits intégrés**. Seule B reformule cette tension exacte (déplorer le repli ≠ observer l''engagement effectif). A énonce **une limite du bénévolat** (« quel risque court le bénévole ? »). C apporte **une nuance générationnelle** (« qui s''engage le plus ? ») — piège C1 fin car elle aussi semble paradoxale, mais elle ne porte pas sur la même opposition. D dénonce **un déficit structurel** (« de quoi souffrent les associations ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 3 : Implicite culturel / familial / 4 tours / bonne réponse C -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-000000000003', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] J''ai dîné chez les parents de Camille hier soir.\n[Femme] Et tu as réussi à leur parler de votre projet de mariage ?\n[Homme] Pas vraiment. Sa mère a longuement insisté pour que je reprenne du dessert, son père m''a resservi du vin trois fois.\n[Femme] Et tu en as conclu quelque chose ? Qu''est-ce qu''on comprend sans le dire, dans ce genre de soirée ?\n[Homme] ...\n\nA. Qu''ils trouvent l''occasion encore trop précoce pour aborder un sujet aussi sérieux.\nB. Qu''ils manquent cruellement de sujets de conversation avec un futur gendre.\nC. Qu''ils m''acceptent dans la famille sans avoir besoin de le formuler explicitement.\nD. Qu''ils cherchent à me mettre à l''épreuve par un excès de prévenance feinte.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''ai dîné chez les parents de Camille hier soir.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et tu as réussi à leur parler de votre projet de mariage ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pas vraiment. Sa mère a longuement insisté pour que je reprenne du dessert, son père m''a resservi du vin trois fois.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et tu en as conclu quelque chose ? Qu''est-ce qu''on comprend sans le dire, dans ce genre de soirée ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Qu''ils trouvent l''occasion encore trop précoce pour aborder un sujet aussi sérieux.<break time="700ms"/>B.<break time="300ms"/>Qu''ils manquent cruellement de sujets de conversation avec un futur gendre.<break time="700ms"/>C.<break time="300ms"/>Qu''ils m''acceptent dans la famille sans avoir besoin de le formuler explicitement.<break time="700ms"/>D.<break time="300ms"/>Qu''ils cherchent à me mettre à l''épreuve par un excès de prévenance feinte.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le dialogue cumule deux informations clés : le sujet du mariage n''a **pas** été abordé verbalement, **mais** l''hôte a multiplié les gestes d''hospitalité. La question « qu''est-ce qu''on comprend sans le dire ? » demande **le contenu de l''implicite culturel français porté par ces gestes d''accueil**. Seule C lit correctement ces gestes comme un signe tacite d''adoption. A propose **une explication évitante** (« pourquoi le sujet n''a-t-il pas été abordé ? ») — distracteur très proche car cohérent avec « pas vraiment ». B donne **une explication psychologisante triviale**. D bascule dans **une lecture défiante** (« et si c''était une mise à l''épreuve ? »), interprétation possible mais qui contredit la dimension chaleureuse des gestes.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 4 : Sens caché derrière une formule / professionnel / 4 tours / bonne réponse D -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-000000000004', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Le directeur a conclu ton entretien annuel par une formule étrange.\n[Homme] Oui, il m''a dit : « Vos qualités finiront par être reconnues, à leur juste mesure. »\n[Femme] Sur le moment, tu as souri poliment, mais tu as l''air contrarié maintenant.\n[Homme] Plus j''y repense, plus je m''interroge. Qu''est-ce qu''il faut entendre derrière ces mots, à ton avis ?\n[Femme] ...\n\nA. Qu''il faut prendre cette phrase pour ce qu''elle est : un compliment maladroitement formulé.\nB. Qu''il prépare en réalité une promotion imminente pour toi.\nC. Qu''il souligne discrètement ton manque d''autorité face à l''équipe.\nD. Qu''à ses yeux, ta reconnaissance attendra encore, sans qu''il s''en sente responsable.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Le directeur a conclu ton entretien annuel par une formule étrange.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, il m''a dit : « Vos qualités finiront par être reconnues, à leur juste mesure. »</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Sur le moment, tu as souri poliment, mais tu as l''air contrarié maintenant.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Plus j''y repense, plus je m''interroge. Qu''est-ce qu''il faut entendre derrière ces mots, à ton avis ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Qu''il faut prendre cette phrase pour ce qu''elle est : un compliment maladroitement formulé.<break time="700ms"/>B.<break time="300ms"/>Qu''il prépare en réalité une promotion imminente pour toi.<break time="700ms"/>C.<break time="300ms"/>Qu''il souligne discrètement ton manque d''autorité face à l''équipe.<break time="700ms"/>D.<break time="300ms"/>Qu''à ses yeux, ta reconnaissance attendra encore, sans qu''il s''en sente responsable.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le dialogue isole la formule « finiront par être reconnues » (futur indéterminé) et « à leur juste mesure » (jugement implicite sur la valeur réelle des qualités) ; le tour 3 souligne que l''homme, après réflexion, s''en inquiète. La question « qu''est-ce qu''il faut entendre derrière ces mots ? » exige **le décodage de ce non-dit hiérarchique**. Seule D restitue la lecture pragmatique : promesse différée + déresponsabilisation du locuteur. A propose une **lecture naïve** qui ignore la contrariété du tour 3. B sur-interprète **dans le sens positif inverse** (« promotion imminente »), pas étayé. C glisse vers **un autre type de reproche** (manque d''autorité) qui n''est pas dans la formule.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 5 : Ce qui se joue vraiment / politique d'entreprise / 5 tours / bonne réponse A -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-000000000005', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] La direction propose de revoir l''organigramme pour « simplifier les circuits de décision ».\n[Femme] On nous l''a déjà servie, celle-là, il y a trois ans.\n[Homme] Cette fois, ils invoquent l''agilité et l''efficacité.\n[Femme] Bien sûr. Mais derrière le vocabulaire choisi, qu''est-ce qui se joue vraiment, au-delà du visible ?\n[Homme] ...\n\nA. Une recentralisation discrète du pouvoir au sommet, sous couvert de fluidification.\nB. Une simplification authentique des processus, attendue de longue date.\nC. Une volonté affichée d''ouvrir davantage de postes à responsabilité.\nD. Une réponse mesurée à la pression des actionnaires sur les coûts fixes.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">La direction propose de revoir l''organigramme pour « simplifier les circuits de décision ».</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">On nous l''a déjà servie, celle-là, il y a trois ans.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Cette fois, ils invoquent l''agilité et l''efficacité.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Bien sûr. Mais derrière le vocabulaire choisi, qu''est-ce qui se joue vraiment, au-delà du visible ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une recentralisation discrète du pouvoir au sommet, sous couvert de fluidification.<break time="700ms"/>B.<break time="300ms"/>Une simplification authentique des processus, attendue de longue date.<break time="700ms"/>C.<break time="300ms"/>Une volonté affichée d''ouvrir davantage de postes à responsabilité.<break time="700ms"/>D.<break time="300ms"/>Une réponse mesurée à la pression des actionnaires sur les coûts fixes.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Cinq tours installent une **lecture critique du discours managérial** : déjà-vu, vocabulaire suspect (« agilité », « efficacité »). La question « qu''est-ce qui se joue vraiment, au-delà du visible ? » demande **le véritable enjeu, dissimulé derrière l''argumentaire officiel**. Seule A nomme un mécanisme de pouvoir caché (recentralisation sous couvert de fluidification), cohérent avec l''ironie de la femme. B prend **le discours officiel pour argent comptant** — distracteur très proche en surface, mais incompatible avec « au-delà du visible ». C propose **un autre projet (ouverture de postes)** qui n''est pas suggéré. D donne **une cause externe vraisemblable** (pression actionnariale) mais ne décrit pas ce que la réforme produit en interne.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 6 : Tension entre deux positions / institutionnel / 4 tours / bonne réponse B -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-000000000006', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu dois choisir entre les deux candidats pour diriger le laboratoire.\n[Homme] L''un est un chercheur brillant mais peu enclin au management ; l''autre, un gestionnaire chevronné, plus éloigné de la recherche pure.\n[Femme] Les deux profils sont défendus avec ardeur en interne.\n[Homme] Effectivement. Mais où est la véritable tension, in fine ?\n[Femme] ...\n\nA. Dans la difficulté à les départager équitablement sans froisser les soutiens de chacun.\nB. Entre préserver l''excellence scientifique et garantir la viabilité opérationnelle du laboratoire.\nC. Dans le fait qu''aucun des deux ne souhaite réellement endosser cette responsabilité.\nD. Entre la pression du conseil et la résistance attendue des équipes en place.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu dois choisir entre les deux candidats pour diriger le laboratoire.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">L''un est un chercheur brillant mais peu enclin au management ; l''autre, un gestionnaire chevronné, plus éloigné de la recherche pure.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Les deux profils sont défendus avec ardeur en interne.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Effectivement. Mais où est la véritable tension, in fine ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dans la difficulté à les départager équitablement sans froisser les soutiens de chacun.<break time="700ms"/>B.<break time="300ms"/>Entre préserver l''excellence scientifique et garantir la viabilité opérationnelle du laboratoire.<break time="700ms"/>C.<break time="300ms"/>Dans le fait qu''aucun des deux ne souhaite réellement endosser cette responsabilité.<break time="700ms"/>D.<break time="300ms"/>Entre la pression du conseil et la résistance attendue des équipes en place.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le tour 2 caractérise deux profils incarnant deux **valeurs incompatibles** (excellence scientifique vs efficacité gestionnaire) ; la question finale demande **la tension de fond**, pas la tension de surface. Seule B nomme l''arbitrage stratégique réel (excellence vs viabilité). A désigne **une tension politique interne** (« comment trancher sans heurter ? ») — distracteur très proche car aussi présente, mais c''est une conséquence, pas la tension de fond. C propose **un retournement non étayé** (« et s''ils refusaient ? »). D évoque **une tension verticale conseil/équipes** qui ne figure pas dans l''échange.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 7 : Reproche voilé / familial / 4 tours / bonne réponse C -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-000000000007', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Ma sœur a passé tout le dîner à évoquer les souvenirs de la maison de campagne.\n[Femme] Tu n''y vas plus que rarement, je crois.\n[Homme] Depuis trois ans, à peine deux week-ends. Elle l''a rappelé à plusieurs reprises devant tout le monde.\n[Femme] Sans jamais te le dire en face. Qu''est-ce qu''on te reproche en filigrane, dans ce genre d''insistance ?\n[Homme] ...\n\nA. De ne plus aimer cette maison autant qu''elle aimerait que je l''aime.\nB. D''avoir voulu vendre cette maison contre l''avis de la fratrie.\nC. De m''être éloigné d''un patrimoine familial qu''on attendait que je continue à faire vivre.\nD. De manquer de gratitude envers les parents qui l''ont entretenue durant des années.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Ma sœur a passé tout le dîner à évoquer les souvenirs de la maison de campagne.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu n''y vas plus que rarement, je crois.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Depuis trois ans, à peine deux week-ends. Elle l''a rappelé à plusieurs reprises devant tout le monde.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Sans jamais te le dire en face. Qu''est-ce qu''on te reproche en filigrane, dans ce genre d''insistance ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>De ne plus aimer cette maison autant qu''elle aimerait que je l''aime.<break time="700ms"/>B.<break time="300ms"/>D''avoir voulu vendre cette maison contre l''avis de la fratrie.<break time="700ms"/>C.<break time="300ms"/>De m''être éloigné d''un patrimoine familial qu''on attendait que je continue à faire vivre.<break time="700ms"/>D.<break time="300ms"/>De manquer de gratitude envers les parents qui l''ont entretenue durant des années.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le dialogue combine deux indices : peu de visites depuis trois ans **et** insistance répétée devant témoins. La question « qu''est-ce qu''on te reproche en filigrane ? » demande **l''accusation tacite portée par cette stratégie indirecte**. Seule C formule le reproche pragmatique exact : l''éloignement d''un patrimoine familial qu''on attendait qu''il continue à faire vivre. A propose **un reproche affectif diffus** (« tu n''aimes plus assez la maison ») — très proche de C, mais ne porte pas la dimension d''engagement attendu. B invente **un projet de vente** non mentionné. D bascule **vers les parents** (« tu manques de gratitude ») alors que le sujet implicite reste la maison.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 8 : Concession inavouée / négociation / 4 tours / bonne réponse D -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-000000000008', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as fini par signer le compromis avec les acheteurs.\n[Homme] Oui, hier soir, au bout de huit heures de discussion.\n[Femme] Tu avais pourtant juré que tu ne céderais sur aucun point essentiel.\n[Homme] C''est ce que j''ai prétendu publiquement. Qu''as-tu dû concéder discrètement, à ton avis ?\n[Femme] ...\n\nA. Un report de la date d''entrée dans les lieux, ce qui n''engage à rien.\nB. Une exigence de garanties bancaires renforcées, dont tu te félicites.\nC. La présence d''un notaire imposé par l''autre partie, ce qui reste anecdotique.\nD. Une révision à la baisse du prix sur la pièce que tu refusais absolument de toucher.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as fini par signer le compromis avec les acheteurs.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, hier soir, au bout de huit heures de discussion.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu avais pourtant juré que tu ne céderais sur aucun point essentiel.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est ce que j''ai prétendu publiquement. Qu''as-tu dû concéder discrètement, à ton avis ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un report de la date d''entrée dans les lieux, ce qui n''engage à rien.<break time="700ms"/>B.<break time="300ms"/>Une exigence de garanties bancaires renforcées, dont tu te félicites.<break time="700ms"/>C.<break time="300ms"/>La présence d''un notaire imposé par l''autre partie, ce qui reste anecdotique.<break time="700ms"/>D.<break time="300ms"/>Une révision à la baisse du prix sur la pièce que tu refusais absolument de toucher.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'L''homme a soutenu publiquement n''avoir rien cédé d''essentiel, mais reconnaît implicitement une concession « discrète ». La question demande **la concession non avouée portant précisément sur un point essentiel**. Seule D désigne une vraie concession sur la ligne rouge déclarée (« la pièce que tu refusais absolument de toucher »). A propose **une concession volontairement minimisée** (« n''engage à rien ») — proche par la forme, mais l''autoderision de la phrase indique qu''elle ne portait pas sur un point essentiel. B est **un gain, pas une concession**. C est **un détail relationnel** présenté comme anecdotique.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 9 : Ambiguïté volontaire / institutionnel / 5 tours / bonne réponse A -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-000000000009', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Le communiqué de la préfecture évoque « une réorganisation des dispositifs d''accueil sans suppression de services ».\n[Femme] La formule est habile : on parle de réorganisation, mais on promet de ne rien supprimer.\n[Homme] Les associations, elles, hurlent à la fermeture déguisée.\n[Femme] Et le préfet maintient sa formule au mot près à chaque interview.\n[Homme] Où réside l''ambiguïté volontaire de cette communication ?\n[Femme] ...\n\nA. « Sans suppression de services » laisse entendre la continuité, alors qu''une réorganisation peut très bien fermer des sites tout en transférant la fonction.\nB. La préfecture nie ouvertement les fermetures alors qu''elles sont publiquement actées.\nC. Le communiqué oppose explicitement les inquiétudes des associations à celles des usagers.\nD. Le mot « accueil » est utilisé dans son sens administratif strict, contraire au sens commun.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Le communiqué de la préfecture évoque « une réorganisation des dispositifs d''accueil sans suppression de services ».</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">La formule est habile : on parle de réorganisation, mais on promet de ne rien supprimer.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Les associations, elles, hurlent à la fermeture déguisée.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et le préfet maintient sa formule au mot près à chaque interview.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Où réside l''ambiguïté volontaire de cette communication ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>« Sans suppression de services » laisse entendre la continuité, alors qu''une réorganisation peut très bien fermer des sites tout en transférant la fonction.<break time="700ms"/>B.<break time="300ms"/>La préfecture nie ouvertement les fermetures alors qu''elles sont publiquement actées.<break time="700ms"/>C.<break time="300ms"/>Le communiqué oppose explicitement les inquiétudes des associations à celles des usagers.<break time="700ms"/>D.<break time="300ms"/>Le mot « accueil » est utilisé dans son sens administratif strict, contraire au sens commun.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Cinq tours décortiquent une formule officielle qui résiste à la critique. La question demande **où se loge précisément l''ambiguïté linguistique** exploitée. Seule A repère la **distinction fonction/site** : promettre « pas de suppression de services » n''empêche pas de fermer des points d''accueil et de transférer la fonction ailleurs. B accuse la préfecture **de mensonge frontal** — ce que la femme dément (« la formule est habile », pas mensongère). C invente **une opposition d''acteurs** absente du communiqué. D propose **une ambiguïté lexicale** sur « accueil » qui n''est pas étayée par le dialogue.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 10 : Ce que cette attitude révèle / société / 4 tours / bonne réponse B -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-00000000000a', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] On voit aujourd''hui des jeunes diplômés refuser des postes qu''on aurait acceptés sans réfléchir il y a vingt ans.\n[Homme] Tu trouves cela problématique ?\n[Femme] Ni problématique ni anodin. Cela me dit quelque chose de notre époque.\n[Homme] Justement, qu''est-ce que cette attitude révèle, à l''aune de ce qu''on vivait nous-mêmes au même âge ?\n[Femme] ...\n\nA. Un manque flagrant de courage chez les nouvelles générations face à l''effort.\nB. Un basculement : le travail n''est plus le centre légitime autour duquel on organise sa vie.\nC. Une difficulté économique accrue qui pousse à attendre la meilleure offre possible.\nD. Une méfiance compréhensible envers des employeurs jugés peu fiables.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">On voit aujourd''hui des jeunes diplômés refuser des postes qu''on aurait acceptés sans réfléchir il y a vingt ans.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu trouves cela problématique ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Ni problématique ni anodin. Cela me dit quelque chose de notre époque.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Justement, qu''est-ce que cette attitude révèle, à l''aune de ce qu''on vivait nous-mêmes au même âge ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un manque flagrant de courage chez les nouvelles générations face à l''effort.<break time="700ms"/>B.<break time="300ms"/>Un basculement : le travail n''est plus le centre légitime autour duquel on organise sa vie.<break time="700ms"/>C.<break time="300ms"/>Une difficulté économique accrue qui pousse à attendre la meilleure offre possible.<break time="700ms"/>D.<break time="300ms"/>Une méfiance compréhensible envers des employeurs jugés peu fiables.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'La femme refuse d''emblée la lecture morale (« ni problématique ni anodin ») et propose une lecture **générationnelle / sociologique**. La question demande **ce que ce comportement révèle de l''époque**, par contraste avec la génération précédente. Seule B nomme ce basculement de valeurs (place centrale du travail). A est précisément **la lecture morale** que la femme a déjà écartée — distracteur très fort. C donne **une explication conjoncturelle économique** (« pourquoi attendent-ils ? ») qui n''engage pas l''époque. D propose **une explication relationnelle** (méfiance), sans portée révélatrice.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 11 : Glissement progressif / conversation tendue / 4 tours / bonne réponse C -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-00000000000b', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] La discussion avec Élise a commencé très cordialement, autour d''un café.\n[Femme] Et pourtant, vous vous êtes quittés en froid, d''après ce que tu m''en dis.\n[Homme] J''ai senti que le ton a basculé à un moment, sans que je puisse exactement le situer.\n[Femme] Essaie de te rappeler : à quel moment le ton a-t-il basculé, précisément ?\n[Homme] ...\n\nA. Au moment précis où elle s''est levée pour partir, après notre dernière phrase.\nB. Dès l''instant où nous nous sommes assis face à face, sans bavardage préalable.\nC. Quand j''ai osé mentionner, en passant, le projet de promotion qu''elle convoitait aussi.\nD. À la toute fin, lorsqu''elle a sèchement refusé que je règle son café.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">La discussion avec Élise a commencé très cordialement, autour d''un café.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et pourtant, vous vous êtes quittés en froid, d''après ce que tu m''en dis.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''ai senti que le ton a basculé à un moment, sans que je puisse exactement le situer.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Essaie de te rappeler : à quel moment le ton a-t-il basculé, précisément ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au moment précis où elle s''est levée pour partir, après notre dernière phrase.<break time="700ms"/>B.<break time="300ms"/>Dès l''instant où nous nous sommes assis face à face, sans bavardage préalable.<break time="700ms"/>C.<break time="300ms"/>Quand j''ai osé mentionner, en passant, le projet de promotion qu''elle convoitait aussi.<break time="700ms"/>D.<break time="300ms"/>À la toute fin, lorsqu''elle a sèchement refusé que je règle son café.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le dialogue précise que la discussion **a commencé cordialement** et que la rupture s''est faite **insensiblement, en cours d''échange**. La question demande **le point de bascule pragmatique**, ni le début (réfuté), ni un signal terminal (qui en serait l''effet). Seule C désigne un déclencheur intermédiaire (mention d''un sujet sensible « en passant ») cohérent avec un glissement insensible. A et D désignent **des manifestations finales** du refroidissement — proches mais relèvent du symptôme, pas du basculement. B contredit **explicitement** le premier tour (« commencé cordialement »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 12 : Contrepartie inavouée d'un accord / négociation politique / 4 tours / bonne réponse D -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-00000000000c', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] La majorité municipale a fini par voter le projet d''écoquartier.\n[Homme] L''opposition s''y était farouchement opposée pendant six mois.\n[Femme] Et pourtant, le vote est passé presque sans débat.\n[Homme] Eu égard à cette volte-face, quelle contrepartie inavouée a dû être glissée dans l''accord, à ton avis ?\n[Femme] ...\n\nA. Une garantie écrite que le projet sera réévalué à mi-parcours par un comité indépendant.\nB. Une concession purement symbolique sur la dénomination du futur quartier.\nC. Une compensation financière immédiate versée à chaque conseiller d''opposition.\nD. Un arbitrage discret sur un dossier d''urbanisme cher à l''opposition, voté en échange.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">La majorité municipale a fini par voter le projet d''écoquartier.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">L''opposition s''y était farouchement opposée pendant six mois.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et pourtant, le vote est passé presque sans débat.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Eu égard à cette volte-face, quelle contrepartie inavouée a dû être glissée dans l''accord, à ton avis ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une garantie écrite que le projet sera réévalué à mi-parcours par un comité indépendant.<break time="700ms"/>B.<break time="300ms"/>Une concession purement symbolique sur la dénomination du futur quartier.<break time="700ms"/>C.<break time="300ms"/>Une compensation financière immédiate versée à chaque conseiller d''opposition.<break time="700ms"/>D.<break time="300ms"/>Un arbitrage discret sur un dossier d''urbanisme cher à l''opposition, voté en échange.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le dialogue installe une volte-face inexplicable (opposition farouche → vote sans débat) et la question vise **la contrepartie cachée**, ni avouable publiquement, ni triviale. Seule D propose un **échange politique discret entre dossiers**, mécanisme classique d''accord tacite. A est **une garantie publique** (qui aurait pu être dite ouvertement, donc pas inavouée). B est **une concession trop superficielle** pour justifier la volte-face. C est **une accusation de corruption** — trop frontale et invraisemblable pour une « contrepartie inavouée » (qui se dissimule, mais reste légale).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 13 : Pari implicite / projet entrepreneurial / 4 tours / bonne réponse A -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-00000000000d', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu lances ta marque de cosmétiques solides sans levée de fonds ?\n[Femme] Exactement. Croissance lente, autofinancée, distribution sélective.\n[Homme] Tu refuses donc explicitement la course au volume.\n[Femme] Et derrière ce choix, il y a un pari de fond. Sur quoi paries-tu en réalité, selon toi ?\n[Homme] ...\n\nA. Sur le fait que la sobriété deviendra un argument commercial supérieur à la nouveauté permanente.\nB. Sur la capacité de tes premiers clients à supporter des prix très élevés à long terme.\nC. Sur un rachat éventuel par un grand groupe au bout de cinq ou six années.\nD. Sur l''indifférence durable des concurrents installés vis-à-vis de ton segment.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu lances ta marque de cosmétiques solides sans levée de fonds ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Exactement. Croissance lente, autofinancée, distribution sélective.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu refuses donc explicitement la course au volume.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et derrière ce choix, il y a un pari de fond. Sur quoi paries-tu en réalité, selon toi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Sur le fait que la sobriété deviendra un argument commercial supérieur à la nouveauté permanente.<break time="700ms"/>B.<break time="300ms"/>Sur la capacité de tes premiers clients à supporter des prix très élevés à long terme.<break time="700ms"/>C.<break time="300ms"/>Sur un rachat éventuel par un grand groupe au bout de cinq ou six années.<break time="700ms"/>D.<break time="300ms"/>Sur l''indifférence durable des concurrents installés vis-à-vis de ton segment.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le dialogue accumule trois traits stratégiques cohérents : pas de levée, croissance lente, refus du volume. La question demande **le pari profond qui sous-tend ce dispositif**, c''est-à-dire l''anticipation d''évolution du marché. Seule A formule ce pari structurant (la sobriété comme valeur commerciale dominante à venir). B identifie un **pari secondaire sur la clientèle** (« comptes-tu sur eux ? ») — plausible mais ne fonde pas la stratégie. C nomme **une porte de sortie financière** opposée au modèle décrit. D est **un pari négatif fragile** (« tu comptes que personne ne s''y intéressera ») qui contredit l''idée d''un marché émergent.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 14 : Présupposé non discuté / débat public / 4 tours / bonne réponse B -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-00000000000e', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Le ministre défend sa réforme en répétant qu''« il faut moderniser nos institutions ».\n[Homme] Et personne ne discute le fond de cette affirmation.\n[Femme] C''est précisément ce qui me frappe : le débat porte sur les modalités, jamais sur le principe.\n[Homme] Tu pointes là un présupposé non discuté qui sous-tend toute sa position. Lequel, exactement ?\n[Femme] ...\n\nA. Que la modernisation entraîne nécessairement une amélioration tangible du service rendu.\nB. Que nos institutions, telles qu''elles fonctionnent, seraient par nature dépassées et à reconfigurer.\nC. Que la réforme ne peut être conduite sans l''adhésion préalable des partenaires sociaux.\nD. Que les modalités techniques choisies seront politiquement neutres et consensuelles.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Le ministre défend sa réforme en répétant qu''« il faut moderniser nos institutions ».</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et personne ne discute le fond de cette affirmation.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">C''est précisément ce qui me frappe : le débat porte sur les modalités, jamais sur le principe.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu pointes là un présupposé non discuté qui sous-tend toute sa position. Lequel, exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Que la modernisation entraîne nécessairement une amélioration tangible du service rendu.<break time="700ms"/>B.<break time="300ms"/>Que nos institutions, telles qu''elles fonctionnent, seraient par nature dépassées et à reconfigurer.<break time="700ms"/>C.<break time="300ms"/>Que la réforme ne peut être conduite sans l''adhésion préalable des partenaires sociaux.<break time="700ms"/>D.<break time="300ms"/>Que les modalités techniques choisies seront politiquement neutres et consensuelles.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'La femme distingue explicitement **principe** et **modalités** : le principe (« il faut moderniser ») n''est jamais interrogé. La question demande **le présupposé contenu dans cette affirmation-principe**. Seule B reformule ce présupposé latent : qu''il y aurait quelque chose à moderniser, donc que les institutions sont dépassées. A énonce **un autre présupposé**, lui aussi tacite mais portant sur la conséquence (« moderniser = mieux ») — distracteur très proche car effectivement présupposé, mais le tour 3 précise que c''est **le principe** qui n''est pas discuté, pas l''effet. C porte **sur la méthode** (modalités), donc ce qui est, lui, discuté. D porte **sur la neutralité des outils**, hors du sujet.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 15 : Véritable pierre d'achoppement / conflit pro / 4 tours / bonne réponse C -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-00000000000f', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] La discussion bloque toujours, paraît-il, sur les indicateurs de performance.\n[Femme] C''est en tout cas ce que les deux parties répètent en réunion.\n[Homme] Mais tu m''as glissé hier que la vraie pierre d''achoppement se trouvait ailleurs.\n[Femme] Exactement. Le sujet des indicateurs n''est qu''un prétexte. La véritable pierre d''achoppement, c''est quoi en réalité ?\n[Homme] ...\n\nA. La méfiance personnelle entre les deux chefs de service, jamais nommée publiquement.\nB. Une divergence ancienne sur la méthode statistique de calcul des indicateurs eux-mêmes.\nC. Le refus tacite, côté direction, de céder un pouvoir d''arbitrage symbolique à l''autre service.\nD. Un défaut chronique d''outils de mesure partagés entre les deux services.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">La discussion bloque toujours, paraît-il, sur les indicateurs de performance.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">C''est en tout cas ce que les deux parties répètent en réunion.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mais tu m''as glissé hier que la vraie pierre d''achoppement se trouvait ailleurs.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Exactement. Le sujet des indicateurs n''est qu''un prétexte. La véritable pierre d''achoppement, c''est quoi en réalité ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La méfiance personnelle entre les deux chefs de service, jamais nommée publiquement.<break time="700ms"/>B.<break time="300ms"/>Une divergence ancienne sur la méthode statistique de calcul des indicateurs eux-mêmes.<break time="700ms"/>C.<break time="300ms"/>Le refus tacite, côté direction, de céder un pouvoir d''arbitrage symbolique à l''autre service.<break time="700ms"/>D.<break time="300ms"/>Un défaut chronique d''outils de mesure partagés entre les deux services.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le dialogue construit une opposition prétexte/véritable enjeu : les indicateurs ne sont qu''un masque. La question demande **le véritable point de blocage, distinct du prétexte affiché**. Seule C nomme un enjeu de pouvoir tacite (refus de céder un arbitrage), cohérent avec la logique du « prétexte ». A désigne une **lecture interpersonnelle** (« méfiance entre chefs ») — distracteur très proche, plausible, mais d''ordre relationnel, alors que le contexte (réunions, négociations) suggère un enjeu institutionnel. B reconduit **le sujet des indicateurs**, ce que la femme exclut expressément. D désigne **une difficulté technique**, encore une fois dans le registre du prétexte.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 16 : Désaccord de fond vs apparent / couple amical / 4 tours / bonne réponse D -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-000000000010', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu te disputes encore avec Antoine sur le choix de l''école pour Léa ?\n[Homme] En apparence, oui : il défend le public, je préfère le privé sous contrat.\n[Femme] Pourtant, vous étiez d''accord il y a six mois sur le principe d''une école proche.\n[Homme] C''est bien là que le bât blesse. Le désaccord de fond entre nous est ailleurs, par contraste avec celui qui s''affiche.\n[Femme] Selon toi, ce désaccord de fond porte sur quoi en réalité ?\n[Homme] ...\n\nA. Sur le quartier où nous voulons que Léa fasse sa scolarité.\nB. Sur le budget que nous sommes prêts à consacrer à son éducation.\nC. Sur la place du religieux dans le choix de l''établissement.\nD. Sur le type d''enfant que chacun de nous voudrait qu''elle devienne, à travers cette école.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu te disputes encore avec Antoine sur le choix de l''école pour Léa ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">En apparence, oui : il défend le public, je préfère le privé sous contrat.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Pourtant, vous étiez d''accord il y a six mois sur le principe d''une école proche.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est bien là que le bât blesse. Le désaccord de fond entre nous est ailleurs, par contraste avec celui qui s''affiche.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Selon toi, ce désaccord de fond porte sur quoi en réalité ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Sur le quartier où nous voulons que Léa fasse sa scolarité.<break time="700ms"/>B.<break time="300ms"/>Sur le budget que nous sommes prêts à consacrer à son éducation.<break time="700ms"/>C.<break time="300ms"/>Sur la place du religieux dans le choix de l''établissement.<break time="700ms"/>D.<break time="300ms"/>Sur le type d''enfant que chacun de nous voudrait qu''elle devienne, à travers cette école.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le dialogue oppose un désaccord de surface (public/privé) à un désaccord de fond distinct, plus profond que le simple choix d''école. La question demande **la nature véritable de cette divergence sous-jacente**. Seule D désigne un enjeu éducatif fondamental (projet d''enfant), qui peut expliquer pourquoi public ou privé devient un proxy. A reconduit **le critère géographique** déjà tranché (« d''accord sur l''école proche »). B introduit **une dimension matérielle** non évoquée. C propose **une lecture confessionnelle** (« privé sous contrat = religieux ») plausible, mais qui resterait du même ordre que le désaccord affiché.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 17 : Lecture entre les lignes / message professionnel / 4 tours / bonne réponse A -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-000000000011', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] J''ai reçu un courriel surprenant de ma nouvelle directrice ce matin.\n[Femme] Qu''est-ce qu''elle te dit, au juste ?\n[Homme] Elle me félicite pour mon « investissement remarquable » et me suggère de penser, je cite, à « équilibrer davantage mes responsabilités avec d''autres dimensions de la vie ».\n[Femme] La formule est belle, mais qu''est-ce qu''il fallait comprendre vraiment, entre les lignes ?\n[Homme] ...\n\nA. Qu''elle me trouve trop investi et redoute pour moi un essoufflement à court ou moyen terme.\nB. Qu''elle me prépare officieusement à un changement de poste plus exposé.\nC. Qu''elle attend de moi un investissement encore supérieur dans les mois à venir.\nD. Qu''elle me reproche en creux mon manque d''engagement extra-professionnel.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''ai reçu un courriel surprenant de ma nouvelle directrice ce matin.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qu''est-ce qu''elle te dit, au juste ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Elle me félicite pour mon « investissement remarquable » et me suggère de penser, je cite, à « équilibrer davantage mes responsabilités avec d''autres dimensions de la vie ».</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">La formule est belle, mais qu''est-ce qu''il fallait comprendre vraiment, entre les lignes ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Qu''elle me trouve trop investi et redoute pour moi un essoufflement à court ou moyen terme.<break time="700ms"/>B.<break time="300ms"/>Qu''elle me prépare officieusement à un changement de poste plus exposé.<break time="700ms"/>C.<break time="300ms"/>Qu''elle attend de moi un investissement encore supérieur dans les mois à venir.<break time="700ms"/>D.<break time="300ms"/>Qu''elle me reproche en creux mon manque d''engagement extra-professionnel.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le message combine **éloge de l''investissement** et **suggestion d''équilibrer avec d''autres dimensions** : la lecture pragmatique attendue intègre les deux éléments. Seule A relie l''éloge (« tu en fais beaucoup ») à l''avertissement (« attention à toi »). B sur-interprète **vers une promotion** non suggérée. C contredit **frontalement** la suggestion d''équilibrer (« encore plus » contre « davantage d''équilibre »). D inverse **le reproche** (vie privée vs vie pro), à rebours du sens du message — distracteur fin C1 car formellement « équilibrer » peut concerner les deux côtés, mais le contexte (féliciter l''investissement professionnel) impose la direction.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 18 : Ressort dramatique principal / récit / 4 tours / bonne réponse B -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-000000000012', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] J''ai enfin vu la pièce de Mouawad que tu m''avais recommandée.\n[Homme] Et qu''en as-tu pensé, finalement ?\n[Femme] Bouleversante. On reste suspendu à la fratrie pendant deux heures, sans pouvoir détacher le regard.\n[Homme] Mais quel est, à ton sens, le ressort dramatique principal qui fait tenir l''édifice ?\n[Femme] ...\n\nA. La beauté très formelle des dialogues, ciselés au mot près.\nB. Le silence partagé sur un secret de famille que chacun pressent sans oser le formuler.\nC. La mise en scène austère, qui laisse toute la place au texte.\nD. La performance impressionnante de la comédienne principale, qui porte la pièce à elle seule.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">J''ai enfin vu la pièce de Mouawad que tu m''avais recommandée.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et qu''en as-tu pensé, finalement ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Bouleversante. On reste suspendu à la fratrie pendant deux heures, sans pouvoir détacher le regard.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mais quel est, à ton sens, le ressort dramatique principal qui fait tenir l''édifice ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La beauté très formelle des dialogues, ciselés au mot près.<break time="700ms"/>B.<break time="300ms"/>Le silence partagé sur un secret de famille que chacun pressent sans oser le formuler.<break time="700ms"/>C.<break time="300ms"/>La mise en scène austère, qui laisse toute la place au texte.<break time="700ms"/>D.<break time="300ms"/>La performance impressionnante de la comédienne principale, qui porte la pièce à elle seule.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le tour 3 souligne deux indices : l''attention captive et **la fratrie comme objet du regard**. La question demande **le ressort dramatique** — donc une tension narrative, pas un mérite formel. Seule B identifie un mécanisme dramaturgique (secret familial tu mais pressenti) qui justifie la suspension du regard sur la fratrie. A vante **une qualité d''écriture**, pas un ressort dramatique. C porte sur **la scénographie**, registre formel à nouveau — distracteur très proche car valorisable, mais ne tend pas l''action. D désigne **un mérite d''interprétation**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 19 : Posture adoptée / confrontation / 4 tours / bonne réponse C -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-000000000013', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu as présenté ton rapport critique devant le conseil d''administration ?\n[Femme] Oui, hier après-midi. Six administrateurs, trois heures de séance.\n[Homme] J''imagine qu''ils ne t''ont pas ménagée.\n[Femme] Ils m''ont attaquée sur tous les angles. Mais j''avais réfléchi à l''avance à la posture que je voulais tenir. Quelle posture as-tu choisie face à eux, à ton avis ?\n[Homme] ...\n\nA. Celle de la conciliation, en cherchant à reformuler chacune de leurs critiques pour les apaiser.\nB. Celle du retrait poli, en différant systématiquement les réponses à une note écrite ultérieure.\nC. Celle de la fermeté argumentée, en assumant chaque conclusion sans la durcir ni la nuancer.\nD. Celle de la contre-attaque, en pointant à mon tour les angles morts de leur propre gouvernance.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as présenté ton rapport critique devant le conseil d''administration ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, hier après-midi. Six administrateurs, trois heures de séance.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''imagine qu''ils ne t''ont pas ménagée.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Ils m''ont attaquée sur tous les angles. Mais j''avais réfléchi à l''avance à la posture que je voulais tenir. Quelle posture as-tu choisie face à eux, à ton avis ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Celle de la conciliation, en cherchant à reformuler chacune de leurs critiques pour les apaiser.<break time="700ms"/>B.<break time="300ms"/>Celle du retrait poli, en différant systématiquement les réponses à une note écrite ultérieure.<break time="700ms"/>C.<break time="300ms"/>Celle de la fermeté argumentée, en assumant chaque conclusion sans la durcir ni la nuancer.<break time="700ms"/>D.<break time="300ms"/>Celle de la contre-attaque, en pointant à mon tour les angles morts de leur propre gouvernance.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le contexte associe deux informations : rapport **critique** + posture **réfléchie à l''avance** (donc volontaire). La question demande **la posture délibérée tenue**, cohérente avec un rapport critique présenté à des opposants. Seule C combine assomption (fidélité au rapport) et tenue (ni durcissement ni nuance opportune) — posture caractéristique de l''auteur d''un rapport critique solide. A est **la conciliation**, contraire à l''idée d''un rapport critique tenu. B est **le retrait**, qui annulerait la fonction même de la séance. D est **la contre-attaque**, possible mais qui ferait dévier l''objet (de son rapport vers leur gouvernance) — distracteur très proche car aussi assumée.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 20 : Vérité dérangeante à dire ou à taire / éthique professionnelle / 5 tours / bonne réponse D -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c1-1000-0000-000000000014', 'B2', 'co_dialogue_c1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Lors du pot de départ, le directeur a fait un discours élogieux pour Vincent.\n[Homme] Vincent qui, comme chacun le sait, part contraint, après deux années très difficiles.\n[Femme] Personne, dans l''assemblée, n''a osé rappeler ce point.\n[Homme] Tu m''as dit pourtant que tu avais hésité à prendre la parole.\n[Femme] Oui. Et je m''interroge encore : qu''est-ce qu''il aurait fallu dire, à ce moment précis ?\n[Homme] ...\n\nA. Rien : ce genre de rituel social n''appelle aucune vérité dérangeante de la part des collègues.\nB. Il aurait fallu prendre la parole pour critiquer publiquement la gestion du dossier par la direction.\nC. Il aurait suffi d''applaudir un peu moins fort, pour marquer discrètement une distance.\nD. Reconnaître brièvement et avec tact ce que ce départ avait de difficile, sans en faire un règlement de comptes.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Lors du pot de départ, le directeur a fait un discours élogieux pour Vincent.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vincent qui, comme chacun le sait, part contraint, après deux années très difficiles.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Personne, dans l''assemblée, n''a osé rappeler ce point.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu m''as dit pourtant que tu avais hésité à prendre la parole.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui. Et je m''interroge encore : qu''est-ce qu''il aurait fallu dire, à ce moment précis ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Rien : ce genre de rituel social n''appelle aucune vérité dérangeante de la part des collègues.<break time="700ms"/>B.<break time="300ms"/>Il aurait fallu prendre la parole pour critiquer publiquement la gestion du dossier par la direction.<break time="700ms"/>C.<break time="300ms"/>Il aurait suffi d''applaudir un peu moins fort, pour marquer discrètement une distance.<break time="700ms"/>D.<break time="300ms"/>Reconnaître brièvement et avec tact ce que ce départ avait de difficile, sans en faire un règlement de comptes.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Cinq tours installent une situation où une vérité partagée par tous n''est pas dite, et où la femme s''interroge sur **la parole juste**, ni la lâcheté du silence collectif ni la violence du règlement de comptes. La question, posée par elle-même après hésitation, attend **la formule médiane assumant la vérité avec tact**. Seule D propose cette voie d''équilibre. A justifie **le silence intégral**, position que la femme a précisément remise en cause. B propose **la dénonciation frontale** (« critiquer publiquement la direction »), qui transforme le rituel social en confrontation — distracteur très proche car aussi « dire la vérité ». C esquive **par un signal corporel** discret, qui ne « dit » rien et ne répond donc pas à la question (« qu''est-ce qu''il aurait fallu dire ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);
