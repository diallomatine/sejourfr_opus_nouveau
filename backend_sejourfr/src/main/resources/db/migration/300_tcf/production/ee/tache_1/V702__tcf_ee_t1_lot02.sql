-- ============================================================================
-- V702 — TCF EE T1 — lot 02 (7 nouveaux sujets)
-- ----------------------------------------------------------------------------
-- Expression écrite, Tâche 1 : message court à un proche (30-60 mots).
-- Table production_tasks uniquement. 7 sujets, niveaux 3×A2 / 2×B1 / 2×B2.
-- Thèmes : s''excuser · confirmer ou annuler un engagement · partager un
-- conseil · inviter à un événement · demander de l''aide · présenter un projet
-- personnel · répondre à un reproche.
-- UUID déterministes 77777777-e102-1000-0000-0000000000NN (NN = 01..07).
-- ============================================================================

INSERT INTO production_tasks
  (id, epreuve, tache_numero, niveau_cible, consigne, contexte, duree_max_sec, mots_min,
   mots_max, is_active, created_at, duree_min_sec)
VALUES
  -- 01 — A2 — s''excuser
  ('77777777-e102-1000-0000-000000000001', 'TCF_EE', '1', 'A2',
   'Écrivez un message à Khalil pour vous excuser : expliquez pourquoi vous n''êtes pas venu et proposez une nouvelle séance cette semaine.',
   'Hier soir, vous deviez retrouver votre ami Khalil au cinéma à 20 heures. Vous vous êtes endormi après le travail et vous avez manqué le rendez-vous.',
   NULL, '30', '60', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 02 — A2 — confirmer un engagement
  ('77777777-e102-1000-0000-000000000002', 'TCF_EE', '1', 'A2',
   'Répondez à Sofia pour confirmer que vous gardez son chat : dites quand vous passerez prendre les clés et posez-lui une question sur les habitudes de l''animal.',
   'Votre voisine Sofia part trois jours chez sa sœur à Bordeaux. Vous avez promis de garder son chat pendant son absence. Elle vous a écrit : « C''est toujours bon pour ce week-end ? ».',
   NULL, '30', '60', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 03 — B1 — partager un conseil
  ('77777777-e102-1000-0000-000000000003', 'TCF_EE', '1', 'B1',
   'Répondez à Ibrahim : donnez-lui deux conseils tirés de votre propre expérience pour réussir un entretien d''embauche et terminez par une phrase pour le rassurer.',
   'Votre ami Ibrahim passe son premier entretien d''embauche lundi, pour un poste de vendeur. Il vous a écrit : « Toi qui as déjà passé des entretiens, tu as des conseils ? Je suis stressé ! ».',
   NULL, '30', '60', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 04 — A2 — inviter à un événement
  ('77777777-e102-1000-0000-000000000004', 'TCF_EE', '1', 'A2',
   'Écrivez un message à Pavel pour l''inviter à votre tournoi : indiquez le lieu et l''heure du premier match, et proposez-lui de manger ensemble après.',
   'Dimanche matin, vous jouez un tournoi de futsal avec votre équipe au gymnase Jean-Bouin. Vous aimeriez que votre ami Pavel vienne vous encourager.',
   NULL, '30', '60', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 05 — B1 — demander de l''aide
  ('77777777-e102-1000-0000-000000000005', 'TCF_EE', '1', 'B1',
   'Écrivez un message à Carmen pour lui demander de relire votre lettre de motivation : expliquez pourquoi ce poste compte pour vous, dites ce qui vous inquiète dans votre texte et proposez-lui un moment pour en parler.',
   'Vous postulez à une formation d''aide-soignant qui vous tient à cœur. Votre amie Carmen, qui écrit très bien en français, a déjà aidé plusieurs personnes à corriger leurs dossiers.',
   NULL, '30', '60', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 06 — B2 — présenter un projet personnel
  ('77777777-e102-1000-0000-000000000006', 'TCF_EE', '1', 'B2',
   'Écrivez un message à Yuki pour lui présenter votre projet : décrivez-le en quelques mots, expliquez ce qui vous motive et répondez par avance à l''objection qu''elle ne manquera pas de vous faire.',
   'Après huit ans comme employé dans une cantine scolaire, vous envisagez de créer votre petit service de traiteur à domicile. Votre amie Yuki, toujours prudente, trouve souvent vos idées trop risquées.',
   NULL, '30', '60', 'true', '2026-06-07 12:00:00+02', NULL),

  -- 07 — B2 — répondre à un reproche
  ('77777777-e102-1000-0000-000000000007', 'TCF_EE', '1', 'B2',
   'Répondez à Anya avec tact : reconnaissez votre maladresse, expliquez votre version des faits sans vous chercher d''excuses et proposez quelque chose pour regagner sa confiance.',
   'Votre amie Anya vous a écrit : « Tu as parlé de mon changement de travail à tout le monde, alors que je t''avais demandé de garder ça pour toi. Franchement, je suis déçue. ».',
   NULL, '30', '60', 'true', '2026-06-07 12:00:00+02', NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes 77777777-e102-1000-0000-0000000000NN (01..07),
--     tous uniques.
-- [x] Répartition niveau_cible : 3×A2 (01, 02, 04) / 2×B1 (03, 05) /
--     2×B2 (06, 07), gradation effective (actions concrètes et factuelles →
--     conseils argumentés et explication d''un enjeu → anticipation d''une
--     objection, tact face à un reproche, registre nuancé).
-- [x] Un sujet par thème imposé, dans l''ordre du bon de commande ; aucun
--     recouvrement avec les sujets existants (emménagement, événement de
--     quartier, réclamation) ni avec les 10 thèmes du lot 01 (inviter à un
--     pique-nique, décliner, bonne nouvelle, décrire, demander un service,
--     féliciter, remercier, donner des nouvelles, rendez-vous, demande
--     d''information).
-- [x] Schéma conforme à l''exemplaire V701 : mêmes colonnes, même ordre ;
--     contexte = mise en situation / message reçu, consigne = tâche (2-3
--     actions) ; pas de colonne declencheur.
-- [x] epreuve='TCF_EE', tache_numero=1, mots_min=30, mots_max=60,
--     duree_max_sec=NULL, duree_min_sec=NULL, is_active=true,
--     created_at='2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées partout ; SQL valide.
-- [x] Distribution des bonnes réponses : N/A (production_tasks, pas de QCM).
-- [x] SVG/SSML : N/A (épreuve écrite, aucun média).
-- [x] Contenu 100 % original ; situations toutes différentes ; prénoms variés
--     et distincts du lot 01 (Khalil, Sofia, Ibrahim, Pavel, Carmen, Yuki,
--     Anya).
-- ============================================================================
