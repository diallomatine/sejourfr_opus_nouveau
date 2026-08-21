-- ============================================================================
-- V318 — Contenu : les 6 compétences de COMPRÉHENSION (CO / CE)
-- ----------------------------------------------------------------------------
-- Une compétence par NIVEAU et par DOMAINE, pas un référentiel fin
-- (brief « Plan adaptatif TCF » §8) : le catalogue de questions est déjà
-- organisé par niveau, une question CO de niveau B1 alimente CO-B1 et rien
-- d'autre. Les tags plus fins (implicite, intention, lexique...) viendront plus
-- tard SANS casser ce modèle — ils se poseront sur les questions, jamais en
-- multipliant les compétences.
--
-- ⚠️ CES 6 LIGNES NE PASSENT PAS PAR `tools/competences/generer_seed.py`, et
-- c'est volontaire. Ce générateur est structuré pour les 6 tâches EE/EO : il
-- valide 8 compétences par tâche x 15 sujets x 3 références, exige une
-- fourchette de mots (EE) ou une durée (EO) sur chaque sujet, et rattache tout
-- à un `task_code`. Une compétence de compréhension n'a NI tâche, NI sujet, NI
-- référence — le générateur la refuserait, et l'y faire entrer supposerait de
-- relâcher les validations qui protègent les 720 sujets existants. Ces 6 lignes
-- sont donc écrites ici, à la main, et se modifient ensuite depuis la console
-- d'administration comme le reste du catalogue.
--
-- Les UUID restent DÉTERMINISTES et suivent la même convention que le
-- générateur : uuid5(namespace 6f2b1a54-9c3d-4e78-8a10-5e10c0de0001,
-- "skill:<code>"). Un identifiant stable d'un environnement à l'autre est ce
-- qui permet aux observations du Plan de survivre à une republication.
--
-- `task_code` est NULL (V039), `display_order` porte l'ordre pédagogique du
-- domaine : 1 = A2, 2 = B1, 3 = B2. La progression est séquentielle (brief §12) ;
-- ce rang est aussi ce sur quoi s'appuie le verrou freemium, qui ouvre le rang
-- le plus bas encore actif de chaque domaine.
--
-- Idempotent : ON CONFLICT (code) DO NOTHING — rejouable sans effet.
-- ============================================================================

INSERT INTO skills (id, section, task_code, code, title, description, general_criterion,
                    target_level, display_order, is_active)
VALUES
    -- ---------------------------------------------------------------------
    -- Compréhension orale
    -- ---------------------------------------------------------------------
    ('cf10ca00-0522-5cf5-8fde-458d44f8a298', 'CO', NULL, 'CO-A2',
     'Repérer une information explicite à l''oral',
     'Retrouver une information directement donnée dans un message, une annonce ou un échange simple.',
     'Repérer dans un document sonore une information clairement prononcée : un lieu, une heure, un prix, une action, une personne ou un détail concret.',
     'A2', 1, true),

    ('7d06aba5-c549-5c14-85ea-68cd43daf8f2', 'CO', NULL, 'CO-B1',
     'Comprendre le sens global et l''intention à l''oral',
     'Comprendre l''idée principale d''un message et ce que le locuteur cherche à dire, demander ou faire comprendre.',
     'Dégager l''idée principale, la situation et le but d''un message sonore, et relier entre elles plusieurs informations entendues.',
     'B1', 2, true),

    ('2f5acc30-c427-5acb-861a-af3301f9b145', 'CO', NULL, 'CO-B2',
     'Comprendre l''implicite et les nuances à l''oral',
     'Comprendre une information qui n''est pas formulée mot pour mot, une nuance, une conclusion ou une intention plus indirecte.',
     'Déduire ce qui n''est pas dit explicitement : sous-entendu, position implicite, nuance — et écarter des propositions très proches les unes des autres.',
     'B2', 3, true),

    -- ---------------------------------------------------------------------
    -- Compréhension écrite
    -- ---------------------------------------------------------------------
    ('4750ab85-9bfe-5414-bb9c-2ce71f546640', 'CE', NULL, 'CE-A2',
     'Repérer une information explicite dans un texte',
     'Retrouver une information clairement écrite dans un message, une annonce ou un document simple.',
     'Localiser dans un document écrit une information donnée telle quelle : un lieu, une date, un prix, une consigne ou un détail concret.',
     'A2', 1, true),

    ('5f982e32-d1db-55ed-aa0d-af4699ca6bec', 'CE', NULL, 'CE-B1',
     'Comprendre l''idée principale et l''intention d''un texte',
     'Comprendre le sens global du document, son objectif et le lien entre les informations importantes.',
     'Dégager le sens global d''un document écrit, son objectif, et relier entre elles les informations qui comptent.',
     'B1', 2, true),

    ('77f9cc04-95cc-5f04-aaee-db07712a4774', 'CE', NULL, 'CE-B2',
     'Comprendre l''implicite et les nuances d''un texte',
     'Déduire une information, comprendre une formulation indirecte, une nuance ou distinguer des réponses très proches.',
     'Déduire une information non formulée, interpréter une tournure indirecte ou une nuance, et distinguer des propositions très proches les unes des autres.',
     'B2', 3, true)
ON CONFLICT (code) DO NOTHING;
