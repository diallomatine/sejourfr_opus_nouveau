-- Correctif de données : `attempts.epreuve` valait TCF_CO sur des sessions de
-- compréhension ÉCRITE et de structure de la langue.
--
-- Cause : ni `AttemptService.startModuleExam` ni `startTcfLot` ne posaient
-- `epreuve` ; le @PrePersist de l'entité Attempt retombait alors sur
-- `deriveEpreuveFromModule(TCF)` = TCF_CO. Les fronts labellisent sur ce champ
-- (GET /api/me/attempts, historiques) → « Compréhension orale » affiché sur un
-- examen de CE. Le code pose désormais l'épreuve à la création ; cette
-- migration réaligne l'historique déjà écrit.
--
-- Déterministe et borné : on ne dérive que depuis un type de question déjà
-- stocké sur la ligne, et on ne touche qu'aux lignes réellement incohérentes.
-- Les sous-attempts d'un examen blanc complet (parent TCF_COMPLET) portaient
-- déjà la bonne épreuve : les clauses ci-dessous sont sans effet sur eux.

-- Examens blancs module (MOCK_EXAM CO / CE / STRUCTURE).
UPDATE attempts
SET epreuve = CASE module_exam_question_type
                  WHEN 'CE' THEN 'TCF_CE'
                  WHEN 'STRUCTURE' THEN 'TCF_STRUCTURE'
                  ELSE 'TCF_CO'
              END
WHERE module = 'TCF'
  AND module_exam_question_type IS NOT NULL
  AND epreuve <> CASE module_exam_question_type
                     WHEN 'CE' THEN 'TCF_CE'
                     WHEN 'STRUCTURE' THEN 'TCF_STRUCTURE'
                     ELSE 'TCF_CO'
                 END;

-- Séries d'entraînement TCF (lots), même cause, même dérivation.
UPDATE attempts
SET epreuve = CASE lot_question_type
                  WHEN 'CE' THEN 'TCF_CE'
                  WHEN 'STRUCTURE' THEN 'TCF_STRUCTURE'
                  ELSE 'TCF_CO'
              END
WHERE module = 'TCF'
  AND module_exam_question_type IS NULL
  AND lot_question_type IS NOT NULL
  AND epreuve <> CASE lot_question_type
                     WHEN 'CE' THEN 'TCF_CE'
                     WHEN 'STRUCTURE' THEN 'TCF_STRUCTURE'
                     ELSE 'TCF_CO'
                 END;
