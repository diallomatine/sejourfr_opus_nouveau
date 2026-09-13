-- ==========================================================================
-- V878 — L'allowlist du diagnostic suit la taxonomie V3
--
-- V319 a retire 7 competences, V320 a desactive leurs sujets. Une seule de
-- ces 7 etait encore designee ailleurs que dans le catalogue : `EO2-C4`,
-- que `diagnostic_task_skills` propose comme action immediate apres le
-- diagnostic oral. Un candidat aurait ete route vers une fiche absente.
--
-- ⚠️ POURQUOI ICI ET PAS DANS V320. `diagnostic_task_skills` n'est seedee
-- qu'en V755 et V757 — apres V320. Le meme UPDATE, place dans V320, ne
-- trouvait aucune ligne et passait en silence. Le numero de version est ce
-- qui rend cette migration correcte.
--
-- 🛑 Le remplacant n'est PAS `EO2-C3`, qui absorbe pourtant `EO2-C4` dans la
-- V3 : elle figure deja dans la meme allowlist, et la cle primaire
-- (production_task_id, skill_id) refuserait le doublon. C'est `EO2-C9`, qui
-- occupe desormais le rang 4 de la tache — « Reagir a une reponse ou une
-- contrainte imprevue ».
-- ==========================================================================

UPDATE diagnostic_task_skills
   SET skill_id = (SELECT id FROM skills WHERE code = 'EO2-C9')
 WHERE skill_id = (SELECT id FROM skills WHERE code = 'EO2-C4');

-- Le filet : aucune ligne de l'allowlist ne doit plus designer une competence
-- hors catalogue, ni une competence sans sujet actif — les deux priveraient le
-- resultat du diagnostic de l'action qu'il promet.
DO $$
DECLARE
    hors_catalogue int;
    sans_sujet     int;
BEGIN
    SELECT count(*) INTO hors_catalogue
      FROM diagnostic_task_skills d
      JOIN skills s ON s.id = d.skill_id
     WHERE NOT s.is_active;
    IF hors_catalogue > 0 THEN
        RAISE EXCEPTION 'V878 : le diagnostic route vers % competence(s) retiree(s)',
            hors_catalogue;
    END IF;

    SELECT count(*) INTO sans_sujet
      FROM diagnostic_task_skills d
     WHERE NOT EXISTS (SELECT 1 FROM skill_prompts p
                        WHERE p.skill_id = d.skill_id AND p.is_active);
    IF sans_sujet > 0 THEN
        RAISE EXCEPTION 'V878 : % competence(s) du diagnostic n''ont aucun sujet actif',
            sans_sujet;
    END IF;
END $$;
