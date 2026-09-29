-- ============================================================================
-- V028 — production_tasks.titre : intitulé éditorial d'un sujet
-- ----------------------------------------------------------------------------
-- Un sujet n'avait qu'une consigne. Les cartes de sujet des hubs EE/EO
-- affichaient donc « Sujet 01 » suivi du début de la consigne — or toutes les
-- consignes d'une même tâche commencent par des formules proches
-- (« Écrivez un message à… », « Racontez… », « Donnez votre opinion… ») : dans
-- une liste de vingt sujets, rien ne les distinguait au premier coup d'œil.
--
-- La colonne est NULLABLE, volontairement : le contenu déjà en base n'en a pas
-- au moment où cette migration s'applique, et la console d'administration doit
-- pouvoir créer ou vider un titre sans casser un écran. Les deux fronts
-- retombent alors sur l'affichage historique (« Sujet N » + consigne) — repli
-- déclaré une seule fois par front (`productionSubjectTitle`).
--
-- Le CHECK interdit la seule valeur qui produirait un trou à l'écran : une
-- chaîne vide ou blanche. « Pas de titre » se dit NULL, jamais ''.
--
-- Le contenu (les 103 titres) est publié par V754, généré depuis
-- tools/production-titres/. Une fois les migrations appliquées, c'est la BASE
-- qui fait foi : le titre s'édite depuis la console admin
-- (PATCH /api/admin/production-tasks/{id}/titre).
-- ============================================================================

ALTER TABLE production_tasks
    ADD COLUMN titre varchar(80);

ALTER TABLE production_tasks
    ADD CONSTRAINT chk_prod_task_titre CHECK (
        titre IS NULL OR btrim(titre) <> ''
    );

COMMENT ON COLUMN production_tasks.titre IS
    'Intitulé éditorial court du sujet (2 à 5 mots, nominal, fidèle à la consigne), affiché en tête de sa carte sur les hubs EE/EO. NULLABLE : absent, les fronts retombent sur « Sujet N » + consigne. Jamais une chaîne vide.';
