-- ==========================================================================
-- V755 — Sujets fixes du diagnostic initial SejourFR, version 1
--
-- Deux production_tasks actives mais exclues du tirage d'entraînement par leur
-- diagnostic_code. Les UUID et la relation aux skills sont déterministes.
-- L'audio EO a été généré une fois par l'opération admin explicite et vérifié
-- publiquement. Flyway ne contacte jamais Azure/R2 : il référence seulement
-- l'objet immuable dont la clé dérive de l'UUID du sujet.
-- ==========================================================================

-- V724 est chronologiquement exécutée après V029 sur une base reconstruite et
-- remet la contrainte officielle sans connaître le diagnostic. On publie ici
-- sa forme finale, compatible avec les deux histoires Flyway (base neuve ou
-- base existante migrée out-of-order), sans modifier le checksum de V724.
ALTER TABLE production_tasks
    DROP CONSTRAINT IF EXISTS chk_prod_task_tcf_irn_ee_word_bounds;

ALTER TABLE production_tasks
    ADD CONSTRAINT chk_prod_task_tcf_irn_ee_word_bounds CHECK (
        epreuve <> 'TCF_EE'
        OR (
            diagnostic_code IS NULL
            AND (
                (tache_numero = 1 AND mots_min = 30 AND mots_max = 60)
                OR (tache_numero IN (2, 3) AND mots_min = 40 AND mots_max = 90)
            )
        )
        OR (diagnostic_code IS NOT NULL AND mots_min = 100 AND mots_max = 130)
    );

INSERT INTO production_tasks
    (id, epreuve, tache_numero, niveau_cible, titre, consigne, contexte,
     duree_max_sec, duree_min_sec, mots_min, mots_max, is_active, created_at,
     diagnostic_code, diagnostic_version, instruction_audio_url)
VALUES
    ('d1a60000-0000-5000-8000-000000000001', 'TCF_EE', 3, 'B1',
     'Une nouvelle activité',
     E'Vous avez récemment commencé une nouvelle activité près de chez vous : sport, cours de français, bénévolat, formation, association…\n\nÉcrivez à un ami pour :\n- lui expliquer de quelle activité il s''agit et où elle se déroule ;\n- raconter comment s''est passée votre première expérience ;\n- dire ce que vous avez aimé ou moins aimé ;\n- expliquer si vous lui conseillez cette activité et pourquoi.\n\nÉcrivez environ 100 à 130 mots.',
     'Diagnostic écrit SejourFR : message à un ami mêlant description, récit et opinion. Cet exercice n’est pas une tâche officielle du TCF.',
     NULL, NULL, 100, 130, true, '2026-08-09 09:00:00+02',
     'INITIAL_TCF', 1, NULL),
    ('d1a60000-0000-5000-8000-000000000002', 'TCF_EO', 3, 'B1',
     'Trouver une activité dans une nouvelle ville',
     E'Vous venez d''arriver dans une nouvelle ville et vous souhaitez participer à une activité pour rencontrer des personnes et améliorer votre français.\n\nDans votre réponse :\n1. présentez-vous brièvement et expliquez ce que vous recherchez ;\n2. imaginez que vous parlez à une personne qui travaille dans une maison de quartier : posez plusieurs questions utiles pour obtenir des informations sur les activités proposées ;\n3. expliquez quelle activité vous choisiriez et pourquoi ;\n4. terminez en donnant votre opinion : selon vous, est-il préférable d''apprendre le français dans une activité en groupe ou seul sur Internet ? Expliquez pourquoi.\n\nParlez naturellement pendant environ 2 à 3 minutes.',
     'Diagnostic oral SejourFR enregistré : monologue guidé, sans conversation IA en temps réel.',
     180, 120, NULL, NULL, true, '2026-08-09 09:00:00+02',
     'INITIAL_TCF', 1,
     'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/d1a60000-0000-5000-8000-000000000002.mp3')
ON CONFLICT (id) DO NOTHING;

-- Écrit : destinataire, cohérence du message, récit et opinion. Huit signaux
-- réellement observables, tous issus du catalogue existant.
INSERT INTO diagnostic_task_skills (production_task_id, skill_id, display_order)
SELECT 'd1a60000-0000-5000-8000-000000000001'::uuid, s.id, v.ord
FROM (VALUES
    ('EE1-C1', 1), ('EE1-C8', 2), ('EE2-C2', 3), ('EE2-C3', 4),
    ('EE2-C5', 5), ('EE2-C7', 6), ('EE3-C1', 7), ('EE3-C3', 8)
) AS v(code, ord)
JOIN skills s ON s.code = v.code
ON CONFLICT (production_task_id, skill_id) DO NOTHING;

-- Oral enregistré : présentation, développement, questions utiles, choix et
-- opinion. Les compétences qui exigent une vraie relance/reformulation ne sont
-- pas dans l'allowlist et ne pourront donc pas être inventées par le LLM.
INSERT INTO diagnostic_task_skills (production_task_id, skill_id, display_order)
SELECT 'd1a60000-0000-5000-8000-000000000002'::uuid, s.id, v.ord
FROM (VALUES
    ('EO1-C1', 1), ('EO1-C3', 2), ('EO2-C2', 3), ('EO2-C3', 4),
    ('EO2-C4', 5), ('EO2-C7', 6), ('EO3-C1', 7), ('EO3-C3', 8)
) AS v(code, ord)
JOIN skills s ON s.code = v.code
ON CONFLICT (production_task_id, skill_id) DO NOTHING;
