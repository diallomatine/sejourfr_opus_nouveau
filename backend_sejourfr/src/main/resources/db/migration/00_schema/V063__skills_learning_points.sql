-- ============================================================================
-- V063 — Competences TCF : « Vous allez apprendre a : »
-- ----------------------------------------------------------------------------
-- Ajoute a `skills` les trois points d'apprentissage qu'affiche la fiche d'une
-- competence, au-dessus de son bouton d'action.
--
-- POURQUOI — la fiche annoncait la competence par sa prose : `description` (un
-- paragraphe) et `general_criterion` (une phrase). Le candidat y lisait
-- *pourquoi* la competence existe, jamais *ce qu'il va savoir faire* en
-- sortant. La maquette du proprietaire demande trois gestes courts —
-- « Choisir tu ou vous », « Saluer de facon adaptee », « Rester dans le bon
-- registre ».
--
-- 🛑 CES POINTS NE SE DERIVENT PAS DE L'EXISTANT, et c'est le motif meme de la
-- colonne (arbitrage du 2026-09-12) :
--   * decouper `general_criterion` sur ses virgules rend des DESTINATAIRES
--     (« ami, voisin, collegue, administration ») et non des gestes ;
--   * les `unique_criterion` des sujets sont longs et COLLES A LEUR CONTEXTE
--     (« ... adaptes a une voisine que l'on connait peu ») ;
--   * les `checklist` des sujets ont le bon format mais le mauvais niveau :
--     elles nomment la voisine du sujet n° 1. Agreger les 15 checklists d'une
--     competence rendrait ~45 items redondants et situes.
-- C'est donc une donnee EDITORIALE nouvelle, redigee competence par competence.
--
-- POURQUOI UNE MIGRATION SEPAREE, ET NULLABLE — meme raison qu'en V026 :
-- V025 et les seeds V300-V318 sont deja APPLIQUES (base de developpement
-- comprise), les modifier invaliderait leur somme de controle Flyway, et la
-- table porte deja 54 lignes — un NOT NULL sans defaut echouerait a l'ajout.
-- Le contenu publie arrivera par une migration de seed dediee, et sa completude
-- est verrouillee par un TEST (`SkillSeedIT`), jamais par le DDL.
--
-- CONSEQUENCE ASSUMEE — une competence creee depuis la console d'administration
-- peut naitre sans points d'apprentissage, et le contenu deja seede n'en a pas
-- encore. Les deux fronts doivent donc se degrader proprement : pas de points
-- ⇒ le bloc « Vous allez apprendre a » disparait, la carte garde son titre, son
-- compteur et son action. Jamais de carte vide, jamais de puce inventee.
-- ============================================================================

ALTER TABLE skills
    -- Ce que le candidat va savoir faire : EXACTEMENT 3 gestes courts, a
    -- l'infinitif, dans l'ordre d'apprentissage. Tableau JSON de chaines, meme
    -- forme que `skill_prompts.checklist` — c'est le registre d'ecriture deja
    -- eprouve sur 720 sujets, remonte d'un cran dans la hierarchie.
    --
    -- ⚠ Un tableau plutot que trois colonnes : l'admin edite une liste
    -- ordonnable (le patron existe deja pour `checklist`), et un 4e point
    -- eventuel ne demanderait pas de migration. Le nombre exact est une regle
    -- PRODUIT, verrouillee par test.
    ADD COLUMN learning_points jsonb;

COMMENT ON COLUMN skills.learning_points IS
    'Vous allez apprendre a : 3 gestes courts a l''infinitif. Tableau JSON de chaines. Jamais derive de description ni de general_criterion.';
