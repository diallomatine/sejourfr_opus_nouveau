-- ============================================================================
-- V026 — Competences TCF : guidage de l'ecran de saisie
-- ----------------------------------------------------------------------------
-- Ajoute a `skill_prompts` les quatre elements que l'ecran de production montre
-- au candidat AVANT qu'il produise.
--
-- POURQUOI — l'ecran livre en V025 *decrivait* l'exercice (critere abstrait,
-- paragraphe d'objectif, encarts d'explication) et repoussait la zone de saisie
-- tres loin sous la ligne de flottaison. Il le fait desormais *faire* : le
-- critere devient une check-list de gestes, les contraintes deviennent des
-- etiquettes lisibles d'un coup d'oeil, et le champ s'ouvre sur une amorce.
-- Ces quatre informations ne se deduisent pas du critere : elles sont redigees
-- sujet par sujet.
--
-- POURQUOI UNE MIGRATION SEPAREE, ET NULLABLE — V025 et les seeds V300-V305
-- sont deja APPLIQUES (base de developpement comprise). Les modifier
-- invaliderait leur somme de controle Flyway. Et la table porte deja 240
-- lignes : un NOT NULL sans valeur par defaut echouerait a l'ajout. Le contenu
-- publie est rempli juste apres par les migrations V306-V311, et sa completude
-- est verrouillee par un test, pas par le DDL.
--
-- CONSEQUENCE ASSUMEE — un sujet cree depuis la console d'administration peut
-- naitre sans guidage. Les deux fronts doivent donc se degrader proprement :
-- pas de check-list ⇒ on retombe sur la consigne, pas d'etiquette ⇒ seule la
-- puce de longueur, pas d'amorce ⇒ un texte grise neutre. Jamais de carte vide.
-- ============================================================================

ALTER TABLE skill_prompts
    -- Ce qu'il faut faire : 2 a 4 gestes a l'imperatif, dans l'ordre
    -- d'execution. Tableau JSON de chaines. Un tableau plutot que quatre
    -- colonnes : le nombre d'items varie d'un sujet a l'autre, et l'admin doit
    -- pouvoir en ajouter un sans migration.
    ADD COLUMN checklist jsonb,

    -- Les contraintes visibles d'un coup d'oeil : 1 a 3 objets
    -- {label, icon}, ou `icon` appartient a une liste fermee cote application
    -- (TONE, PERSON, TIME, PLACE, NUMBER, TENSE, STRUCTURE, EXAMPLE).
    -- ⚠ N'y mettre NI la longueur NI la duree : les fronts les rendent depuis
    -- recommended_min_words / recommended_max_words / recommended_duration_seconds.
    -- Les stocker deux fois, c'est se garantir de les voir diverger.
    ADD COLUMN constraint_tags jsonb,

    -- L'amorce affichee en texte grise dans le champ de reponse. Elle donne
    -- l'elan sans donner la reponse : elle ne doit jamais satisfaire a elle
    -- seule le critere du sujet.
    ADD COLUMN answer_starter text,

    -- L'astuce affichee sous la zone de production. Elle rappelle le geste le
    -- plus souvent oublie sur CE sujet. Le prefixe « Astuce : » est ajoute par
    -- les fronts, il n'est pas stocke.
    ADD COLUMN tip text;

COMMENT ON COLUMN skill_prompts.checklist IS
    'Ce qu''il faut faire : 2 a 4 gestes a l''imperatif. Tableau JSON de chaines.';
COMMENT ON COLUMN skill_prompts.constraint_tags IS
    'Etiquettes de contrainte : 1 a 3 objets {label, icon}. Jamais la longueur ni la duree.';
COMMENT ON COLUMN skill_prompts.answer_starter IS
    'Amorce grisee du champ de reponse. Ne satisfait jamais le critere a elle seule.';
COMMENT ON COLUMN skill_prompts.tip IS
    'Astuce affichee sous la zone de production. Le prefixe « Astuce : » est ajoute par les fronts.';
