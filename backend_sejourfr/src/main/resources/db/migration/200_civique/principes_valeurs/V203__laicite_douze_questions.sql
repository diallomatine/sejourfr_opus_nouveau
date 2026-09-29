-- ============================================================================
-- V203 — Civique : les 12 questions de l'unite officielle « Laicite » (P2_LAICITE)
-- ----------------------------------------------------------------------------
-- P8.8. L'unite passait sous le seuil de R2 : 9 questions actives, dont un
-- doublon desactive par V299. 8 + 12 = 20, le seuil est atteint exactement.
--
-- 🛑 `difficulty` vaut 'CR' sur les douze, ET CETTE VALEUR NE SIGNIFIE RIEN.
--    Depuis P8.2b le tirage civique passe TOUJOURS `difficulty = null`
--    (D-42 : un seul programme pour les trois mentions, le filtre de mention
--    a ete retire). La colonne est `NOT NULL`, donc il faut l'ecrire ; 'CR'
--    est un REMPLISSAGE. ⛔ Ne pas lire ces douze questions comme visant la
--    carte de resident.
--
-- 🛑 Le rattachement se fait par CODE de notion, jamais par uuid ecrit a la
--    main : un uuid recopie survit a un renommage et designe la mauvaise
--    ligne. Si `pv_laicite` n'existait pas, l'INSERT n'ecrirait RIEN et le
--    garde de fin de fichier ferait echouer la migration.
--
-- ⚠️ Les identifiants sont EXPLICITES, comme dans tout le dossier 200_civique
--    (V201, V202…). La forme montree au proprietaire employait
--    `gen_random_uuid()` et rattachait les choix par leur enonce : la
--    convention de la maison est meilleure, elle supprime ce lien fragile.
-- ============================================================================

INSERT INTO questions
  (id, module, theme_id, difficulty, question_type, statement, explanation,
   is_active, status, civic_notion_id, created_at)
SELECT v.id, 'CIVIQUE',
       (SELECT id FROM themes WHERE code = 'CIV_PRINCIPES'),
       'CR', 'CONNAISSANCE', v.statement, v.explanation,
       true, 'ACTIVE', n.id, now()
  FROM (VALUES
    ('c8800001-0000-0000-0000-000000000001'::uuid,
     'Quelle loi organise la séparation des Églises et de l''État en France ?',
     'La loi du 9 décembre 1905 sépare les Églises et l''État. Elle garantit la liberté de conscience et met fin à la reconnaissance officielle des cultes par l''État.'),
    ('c8800001-0000-0000-0000-000000000002'::uuid,
     'Que dit l''article 1er de la Constitution française à propos de la République ?',
     'La Constitution de 1958 énonce dès son article 1er que la France est une République indivisible, laïque, démocratique et sociale. La laïcité n''est donc pas seulement une loi, c''est un principe constitutionnel.'),
    ('c8800001-0000-0000-0000-000000000003'::uuid,
     'Que garantit la laïcité à chaque personne vivant en France ?',
     'La laïcité protège autant qu''elle encadre : chacun est libre de croire, de ne pas croire, de pratiquer ou de changer de religion. L''État ne s''en mêle pas.'),
    ('c8800001-0000-0000-0000-000000000004'::uuid,
     'Un agent d''un service public peut-il porter un signe religieux visible pendant son service ?',
     'Un agent public représente l''État pendant son service : il doit rester neutre et ne peut pas afficher ses convictions religieuses. Cette règle vaut pour tous les agents, quel que soit leur poste.'),
    ('c8800001-0000-0000-0000-000000000005'::uuid,
     'Une personne peut-elle porter un signe religieux visible dans la rue ou dans une université publique ?',
     'La neutralité s''impose aux agents publics, pas aux usagers. Dans la rue, dans les transports ou à l''université, chacun peut manifester sa religion, dans le respect de l''ordre public.'),
    ('c8800001-0000-0000-0000-000000000006'::uuid,
     'La loi du 15 mars 2004 interdit-elle tout signe religieux aux élèves des écoles publiques ?',
     'La loi de 2004 interdit les signes qui manifestent ostensiblement une appartenance religieuse. Un signe discret, comme une petite médaille portée sous un vêtement, reste autorisé.'),
    ('c8800001-0000-0000-0000-000000000007'::uuid,
     'Les élèves d''une école privée sous contrat avec l''État sont-ils soumis à l''interdiction des signes religieux ostensibles ?',
     'L''interdiction de 2004 vise les écoles, collèges et lycées publics. Les établissements privés sous contrat fixent leurs propres règles dans leur règlement intérieur.'),
    ('c8800001-0000-0000-0000-000000000008'::uuid,
     'Que prévoit la loi de 1905 sur le financement des religions par l''État ?',
     'Depuis 1905, l''État ne salarie ni ne subventionne aucun culte. Les religions se financent par les dons de leurs fidèles.'),
    ('c8800001-0000-0000-0000-000000000009'::uuid,
     'Qui entretient les églises construites avant 1905 en France ?',
     'Les églises bâties avant 1905 sont devenues propriété des communes ou de l''État, qui les entretiennent en tant que propriétaires. Elles restent affectées au culte. C''est l''exception la plus visible au principe de non-financement.'),
    ('c8800001-0000-0000-0000-00000000000a'::uuid,
     'Peut-on parler des religions dans un cours d''histoire à l''école publique ?',
     'Enseigner le fait religieux n''est pas enseigner une religion. À l''école publique, les religions sont étudiées comme des faits d''histoire, de littérature ou d''art, sans prosélytisme.'),
    ('c8800001-0000-0000-0000-00000000000b'::uuid,
     'La laïcité signifie-t-elle que l''État impose l''athéisme ?',
     'Laïcité ne veut pas dire athéisme. L''État ne privilégie ni ne combat aucune croyance : il garantit à chacun la liberté de croire ou de ne pas croire.'),
    ('c8800001-0000-0000-0000-00000000000c'::uuid,
     'Un patient peut-il exiger d''être soigné par une personne du même sexe que lui pour un motif religieux ?',
     'À l''hôpital public, les convictions du patient sont respectées, mais elles ne permettent pas de choisir son soignant ni de refuser un soin urgent. L''organisation du service et l''égalité d''accès priment.')
  ) AS v(id, statement, explanation)
  CROSS JOIN (SELECT id FROM civic_notions WHERE code = 'pv_laicite') AS n;

-- Les 4 choix de chaque question : `display_order` 0 -> 3, UN SEUL `is_correct`.
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES
  ('c8800002-0000-0000-0000-000000000001',
   'c8800001-0000-0000-0000-000000000001',
   'La loi du 9 décembre 1905', true, 0),

  ('c8800002-0000-0000-0000-000000000002',
   'c8800001-0000-0000-0000-000000000001',
   'La loi du 15 mars 2004', false, 1),

  ('c8800002-0000-0000-0000-000000000003',
   'c8800001-0000-0000-0000-000000000001',
   'La Déclaration des droits de l''homme et du citoyen de 1789', false, 2),

  ('c8800002-0000-0000-0000-000000000004',
   'c8800001-0000-0000-0000-000000000001',
   'La Constitution du 4 octobre 1958', false, 3),

  ('c8800002-0000-0000-0000-000000000005',
   'c8800001-0000-0000-0000-000000000002',
   'Elle est indivisible, laïque, démocratique et sociale', true, 0),

  ('c8800002-0000-0000-0000-000000000006',
   'c8800001-0000-0000-0000-000000000002',
   'Elle est catholique et républicaine', false, 1),

  ('c8800002-0000-0000-0000-000000000007',
   'c8800001-0000-0000-0000-000000000002',
   'Elle est neutre en matière politique', false, 2),

  ('c8800002-0000-0000-0000-000000000008',
   'c8800001-0000-0000-0000-000000000002',
   'Elle ne se prononce pas sur les religions', false, 3),

  ('c8800002-0000-0000-0000-000000000009',
   'c8800001-0000-0000-0000-000000000003',
   'La liberté de croire, de ne pas croire et de changer de religion', true, 0),

  ('c8800002-0000-0000-0000-00000000000a',
   'c8800001-0000-0000-0000-000000000003',
   'L''obligation de déclarer sa religion à la mairie', false, 1),

  ('c8800002-0000-0000-0000-00000000000b',
   'c8800001-0000-0000-0000-000000000003',
   'Le droit de ne pas respecter les lois pour motif religieux', false, 2),

  ('c8800002-0000-0000-0000-00000000000c',
   'c8800001-0000-0000-0000-000000000003',
   'La reconnaissance officielle de quatre religions', false, 3),

  ('c8800002-0000-0000-0000-00000000000d',
   'c8800001-0000-0000-0000-000000000004',
   'Non, il est tenu à la neutralité', true, 0),

  ('c8800002-0000-0000-0000-00000000000e',
   'c8800001-0000-0000-0000-000000000004',
   'Oui, s''il l''annonce à son supérieur', false, 1),

  ('c8800002-0000-0000-0000-00000000000f',
   'c8800001-0000-0000-0000-000000000004',
   'Oui, sans aucune condition', false, 2),

  ('c8800002-0000-0000-0000-000000000010',
   'c8800001-0000-0000-0000-000000000004',
   'Seulement s''il travaille dans une mairie', false, 3),

  ('c8800002-0000-0000-0000-000000000011',
   'c8800001-0000-0000-0000-000000000005',
   'Oui, la liberté de manifester sa religion s''applique', true, 0),

  ('c8800002-0000-0000-0000-000000000012',
   'c8800001-0000-0000-0000-000000000005',
   'Non, c''est interdit dans tout l''espace public', false, 1),

  ('c8800002-0000-0000-0000-000000000013',
   'c8800001-0000-0000-0000-000000000005',
   'Seulement pendant les fêtes religieuses', false, 2),

  ('c8800002-0000-0000-0000-000000000014',
   'c8800001-0000-0000-0000-000000000005',
   'Seulement avec une autorisation de la préfecture', false, 3),

  ('c8800002-0000-0000-0000-000000000015',
   'c8800001-0000-0000-0000-000000000006',
   'Non, elle interdit les signes ostensibles, pas les signes discrets', true, 0),

  ('c8800002-0000-0000-0000-000000000016',
   'c8800001-0000-0000-0000-000000000006',
   'Oui, tout signe religieux est interdit', false, 1),

  ('c8800002-0000-0000-0000-000000000017',
   'c8800001-0000-0000-0000-000000000006',
   'Non, elle ne concerne que les enseignants', false, 2),

  ('c8800002-0000-0000-0000-000000000018',
   'c8800001-0000-0000-0000-000000000006',
   'Oui, y compris en dehors de l''établissement', false, 3),

  ('c8800002-0000-0000-0000-000000000019',
   'c8800001-0000-0000-0000-000000000007',
   'Non, cette interdiction vise les écoles publiques', true, 0),

  ('c8800002-0000-0000-0000-00000000001a',
   'c8800001-0000-0000-0000-000000000007',
   'Oui, toutes les écoles sont concernées', false, 1),

  ('c8800002-0000-0000-0000-00000000001b',
   'c8800001-0000-0000-0000-000000000007',
   'Oui, mais seulement au collège', false, 2),

  ('c8800002-0000-0000-0000-00000000001c',
   'c8800001-0000-0000-0000-000000000007',
   'Cela dépend de la commune', false, 3),

  ('c8800002-0000-0000-0000-00000000001d',
   'c8800001-0000-0000-0000-000000000008',
   'L''État ne salarie ni ne subventionne aucun culte', true, 0),

  ('c8800002-0000-0000-0000-00000000001e',
   'c8800001-0000-0000-0000-000000000008',
   'L''État finance les religions à parts égales', false, 1),

  ('c8800002-0000-0000-0000-00000000001f',
   'c8800001-0000-0000-0000-000000000008',
   'L''État finance uniquement la religion majoritaire', false, 2),

  ('c8800002-0000-0000-0000-000000000020',
   'c8800001-0000-0000-0000-000000000008',
   'L''État verse un salaire aux ministres du culte', false, 3),

  ('c8800002-0000-0000-0000-000000000021',
   'c8800001-0000-0000-0000-000000000009',
   'Les communes ou l''État, qui en sont propriétaires', true, 0),

  ('c8800002-0000-0000-0000-000000000022',
   'c8800001-0000-0000-0000-000000000009',
   'Le Vatican', false, 1),

  ('c8800002-0000-0000-0000-000000000023',
   'c8800001-0000-0000-0000-000000000009',
   'Les fidèles uniquement', false, 2),

  ('c8800002-0000-0000-0000-000000000024',
   'c8800001-0000-0000-0000-000000000009',
   'Personne, elles sont abandonnées', false, 3),

  ('c8800002-0000-0000-0000-000000000025',
   'c8800001-0000-0000-0000-00000000000a',
   'Oui, le fait religieux est enseigné comme un objet de connaissance', true, 0),

  ('c8800002-0000-0000-0000-000000000026',
   'c8800001-0000-0000-0000-00000000000a',
   'Non, c''est interdit par la laïcité', false, 1),

  ('c8800002-0000-0000-0000-000000000027',
   'c8800001-0000-0000-0000-00000000000a',
   'Seulement dans les écoles privées', false, 2),

  ('c8800002-0000-0000-0000-000000000028',
   'c8800001-0000-0000-0000-00000000000a',
   'Seulement avec l''accord des parents', false, 3),

  ('c8800002-0000-0000-0000-000000000029',
   'c8800001-0000-0000-0000-00000000000b',
   'Non, l''État est neutre : il ne favorise ni ne combat aucune croyance', true, 0),

  ('c8800002-0000-0000-0000-00000000002a',
   'c8800001-0000-0000-0000-00000000000b',
   'Oui, l''État encourage l''athéisme', false, 1),

  ('c8800002-0000-0000-0000-00000000002b',
   'c8800001-0000-0000-0000-00000000000b',
   'Oui, les religions sont interdites en France', false, 2),

  ('c8800002-0000-0000-0000-00000000002c',
   'c8800001-0000-0000-0000-00000000000b',
   'Non, l''État reconnaît officiellement une religion', false, 3),

  ('c8800002-0000-0000-0000-00000000002d',
   'c8800001-0000-0000-0000-00000000000c',
   'Non, il ne peut pas choisir son soignant pour ce motif', true, 0),

  ('c8800002-0000-0000-0000-00000000002e',
   'c8800001-0000-0000-0000-00000000000c',
   'Oui, c''est un droit garanti', false, 1),

  ('c8800002-0000-0000-0000-00000000002f',
   'c8800001-0000-0000-0000-00000000000c',
   'Oui, dans les hôpitaux privés seulement', false, 2),

  ('c8800002-0000-0000-0000-000000000030',
   'c8800001-0000-0000-0000-00000000000c',
   'Oui, s''il le demande à l''avance', false, 3);

-- ============================================================================
-- LE GARDE — la migration ECHOUE plutot que de laisser un etat a moitie ecrit.
-- Meme patron que le garde des 16 unites officielles (V068) : ce qui n'est pas
-- verifie a l'ecriture se decouvre a l'ecran, des mois plus tard.
-- ============================================================================
DO $$
DECLARE
    neuves int;
    choix int;
    sans_bonne int;
BEGIN
    SELECT count(*) INTO neuves FROM questions
     WHERE id::text LIKE 'c8800001-%';
    IF neuves <> 12 THEN
        RAISE EXCEPTION 'V203 : % question(s) ecrite(s) au lieu de 12', neuves;
    END IF;

    SELECT count(*) INTO choix FROM choices
     WHERE question_id::text LIKE 'c8800001-%';
    IF choix <> 48 THEN
        RAISE EXCEPTION 'V203 : % choix ecrit(s) au lieu de 48', choix;
    END IF;

    -- Une question a UNE bonne reponse. Un QCM a deux bonnes reponses
    -- corrigerait faux sans que rien ne le dise.
    SELECT count(*) INTO sans_bonne FROM (
        SELECT c.question_id FROM choices c
         WHERE c.question_id::text LIKE 'c8800001-%'
         GROUP BY c.question_id
        HAVING count(*) FILTER (WHERE c.is_correct) <> 1) t;
    IF sans_bonne > 0 THEN
        RAISE EXCEPTION 'V203 : % question(s) sans bonne reponse unique', sans_bonne;
    END IF;
END $$;
