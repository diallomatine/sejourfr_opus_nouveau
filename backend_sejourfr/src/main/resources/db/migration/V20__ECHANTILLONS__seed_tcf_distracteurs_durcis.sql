-- ============================================================================
-- V20_ECHANTILLONS : 3 questions de validation — distracteurs durcis
-- ============================================================================
-- 📋 3 questions pour valider la nouvelle méthode :
--    Q1 : CE A2 texte  — distracteurs piégeux (pas évidents)
--    Q2 : CE B1 image  — annonce colocation, 2 distracteurs piégeux sur 3
--    Q3 : CE B2 image  — article de presse, réponse non littérale
--
-- 🎯 Nouvelles règles appliquées :
--    A2  : au moins 1 distracteur piégeux, pas de réponse évidente
--    B1  : ≥2 distracteurs piégeux sur 3, parmi 4 stratégies :
--          - vrai mais hors champ
--          - reformulation faussée
--          - inversion de locuteur
--          - presque-synonyme trompeur
--    B2  : ≥2 distracteurs piégeux sur 3, parmi 4 stratégies :
--          - littéral vs implicite
--          - vrai partout sauf ici
--          - demi-vérité
--          - position adjacente
--    B2  : la réponse ne figure JAMAIS mot pour mot dans le texte
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 📄 1. PASSAGES — Plage V20 : 44444444-0020-*
-- ----------------------------------------------------------------------------

INSERT INTO passages (id, type, content, theme_id) VALUES

-- Passage A2 — SMS pharmacie avec nuance (RDV samedi)
(
    '44444444-0020-0000-0000-000000000001', 'TEXTE',
    E'Pharmacie du Centre\n\n' ||
    E'Bonjour madame Petit, votre commande est arrivée. Vous pouvez la retirer à partir de mardi, du mardi au vendredi de 9h à 19h. Le samedi nous sommes ouverts mais sur rendez-vous uniquement.\n\n' ||
    E'Bonne journée.',
    '22222222-0000-0000-0000-000000000002'
)
ON CONFLICT (id) DO NOTHING;


-- ----------------------------------------------------------------------------
-- 🖼️ 2. MEDIAS — Plage V20 : 33333333-0020-*
-- ----------------------------------------------------------------------------

INSERT INTO medias (id, type, url, alt_text, inline_svg) VALUES

-- Media B1 — Annonce de colocation (4 conditions cumulatives)
(
    '33333333-0020-0000-0000-000000000001',
    'IMAGE',
    NULL,
    'Annonce de colocation à Paris 11e arrondissement, 480 euros par mois charges comprises, à partir du 1er octobre, ouverte uniquement aux étudiants non-fumeurs, bail solidaire de 9 mois minimum.',
    '<svg width="100%" viewBox="0 0 680 540" role="img" xmlns="http://www.w3.org/2000/svg"><title>Petite annonce de colocation</title><desc>Annonce immobilière en ligne pour une colocation dans le 11e arrondissement de Paris, 480 euros par mois charges comprises, à partir du 1er octobre, ouverte uniquement aux étudiants non-fumeurs.</desc><rect x="0" y="0" width="680" height="540" fill="#F7F8FA"/><rect x="20" y="20" width="640" height="500" rx="8" fill="#FFFFFF" stroke="#E0E2E7" stroke-width="1"/><rect x="20" y="20" width="640" height="60" rx="8" fill="#1E3A8C"/><text x="40" y="58" font-family="Georgia, serif" font-size="22" font-weight="700" fill="#FFFFFF">ColocFacile.fr</text><text x="600" y="58" text-anchor="end" font-family="Arial, sans-serif" font-size="13" fill="#FFFFFF" opacity="0.85">Annonce mise à jour aujourd''hui</text><g transform="translate(40, 100)"><rect x="0" y="0" width="80" height="24" rx="12" fill="#168F5B"/><text x="40" y="16" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#FFFFFF">Disponible</text><rect x="92" y="0" width="120" height="24" rx="12" fill="#FDECEB"/><text x="152" y="16" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#E1372F">Étudiants uniquement</text><rect x="224" y="0" width="100" height="24" rx="12" fill="#FEF5DD"/><text x="274" y="16" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#A36E0A">Non-fumeurs</text></g><text x="40" y="170" font-family="Arial, sans-serif" font-size="22" font-weight="700" fill="#0F1839">Chambre en colocation — 16 m²</text><text x="40" y="194" font-family="Arial, sans-serif" font-size="14" fill="#5C6573">Paris 11e arrondissement · proche métro Voltaire</text><text x="40" y="244" font-family="Arial, sans-serif" font-size="32" font-weight="700" fill="#1E3A8C">480 €</text><text x="148" y="244" font-family="Arial, sans-serif" font-size="14" fill="#5C6573">/ mois</text><text x="148" y="262" font-family="Arial, sans-serif" font-size="12" font-weight="600" fill="#168F5B">charges comprises (eau, électricité, internet)</text><line x1="40" y1="284" x2="640" y2="284" stroke="#E0E2E7" stroke-width="1"/><g transform="translate(40, 305)"><text x="0" y="0" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#0F1839">Conditions d''entrée</text><text x="0" y="28" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">• Disponible à partir du <tspan font-weight="700" fill="#1E3A8C">1er octobre</tspan></text><text x="0" y="50" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">• Caution : <tspan font-weight="700">2 mois de loyer</tspan> à verser à la signature</text><text x="0" y="72" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">• Bail solidaire de <tspan font-weight="700">9 mois minimum</tspan> (année universitaire)</text><text x="0" y="94" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">• Justificatif d''études ou carte étudiant <tspan font-weight="700" fill="#E1372F">obligatoire</tspan></text></g><line x1="40" y1="415" x2="640" y2="415" stroke="#E0E2E7" stroke-width="1"/><g transform="translate(40, 435)"><text x="0" y="0" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#0F1839">À savoir</text><text x="0" y="22" font-family="Arial, sans-serif" font-size="13" fill="#5C6573">Cuisine partagée avec 3 autres colocataires. Salle de bain privée.</text><text x="0" y="42" font-family="Arial, sans-serif" font-size="13" fill="#5C6573">Animaux non acceptés. Soirées tolérées en semaine après accord.</text></g></svg>'
),

-- Media B2 — Capture d'article de presse en ligne (télétravail nuancé)
(
    '33333333-0020-0000-0000-000000000002',
    'IMAGE',
    NULL,
    'Capture d''écran d''un article de presse en ligne intitulé "Télétravail : derrière la promesse, un bilan plus nuancé qu''attendu", analysant l''évolution du télétravail en France avec une position critique sur ses limites cachées.',
    '<svg width="100%" viewBox="0 0 680 820" role="img" xmlns="http://www.w3.org/2000/svg"><title>Article de presse en ligne sur le télétravail</title><desc>Capture d''écran d''un article de presse traitant de l''évolution du télétravail dans les entreprises françaises, avec une analyse nuancée des bénéfices et limites.</desc><rect x="0" y="0" width="680" height="820" fill="#F0F2F5"/><rect x="20" y="20" width="640" height="780" rx="6" fill="#FFFFFF" stroke="#D5D5D5" stroke-width="1"/><rect x="20" y="20" width="640" height="60" fill="#0F1839"/><text x="40" y="48" font-family="Georgia, serif" font-size="20" font-weight="700" fill="#FFFFFF">Le Quotidien</text><text x="40" y="66" font-family="Arial, sans-serif" font-size="10" fill="#A8B0C5">Société · Travail</text><text x="640" y="56" text-anchor="end" font-family="Arial, sans-serif" font-size="11" fill="#FFFFFF" opacity="0.8">Édition du 14 mars</text><g transform="translate(40, 100)"><rect x="0" y="0" width="90" height="22" rx="2" fill="#E1372F"/><text x="45" y="15" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" font-weight="700" fill="#FFFFFF">ANALYSE</text></g><text x="40" y="158" font-family="Georgia, serif" font-size="22" font-weight="700" fill="#0F1839">Télétravail : derrière la promesse,</text><text x="40" y="186" font-family="Georgia, serif" font-size="22" font-weight="700" fill="#0F1839">un bilan plus nuancé qu''attendu</text><line x1="40" y1="208" x2="120" y2="208" stroke="#E1372F" stroke-width="3"/><text x="40" y="234" font-family="Arial, sans-serif" font-size="12" fill="#5C6573">Par Camille Verdier · 8 min de lecture</text><text x="40" y="280" font-family="Georgia, serif" font-size="14" font-style="italic" fill="#0F1839">Présenté comme une révolution durable, le télétravail s''installe</text><text x="40" y="300" font-family="Georgia, serif" font-size="14" font-style="italic" fill="#0F1839">dans le paysage professionnel français. Mais derrière l''enthousiasme</text><text x="40" y="320" font-family="Georgia, serif" font-size="14" font-style="italic" fill="#0F1839">des premiers temps, les enquêtes les plus récentes invitent à un</text><text x="40" y="340" font-family="Georgia, serif" font-size="14" font-style="italic" fill="#0F1839">examen plus lucide.</text><text x="40" y="378" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">Trois ans après sa généralisation forcée, le télétravail reste plébiscité</text><text x="40" y="396" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">par les salariés : gain de temps, meilleure conciliation vie pro / vie</text><text x="40" y="414" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">privée, autonomie renforcée. Les chiffres sont éloquents : 78 % des</text><text x="40" y="432" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">cadres déclarent ne plus vouloir y renoncer.</text><text x="40" y="466" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">Pourtant, plusieurs signaux discrets méritent d''être entendus. La</text><text x="40" y="484" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">progression des troubles musculosquelettiques chez les télétravailleurs,</text><text x="40" y="502" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">l''isolement croissant des plus jeunes en début de carrière, et surtout</text><text x="40" y="520" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">la difficulté grandissante à transmettre les savoir-faire informels</text><text x="40" y="538" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">interrogent. Les managers eux-mêmes confient peiner à évaluer la</text><text x="40" y="556" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">contribution réelle de leurs équipes.</text><text x="40" y="590" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">Plutôt que d''opposer naïvement défenseurs et détracteurs, l''heure est</text><text x="40" y="608" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">venue de penser un télétravail intelligent : limité dans son volume,</text><text x="40" y="626" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">accompagné dans ses outils, et surtout pensé en fonction des métiers et</text><text x="40" y="644" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">des moments de la carrière. Le tout-distanciel a vécu ; reste à inventer</text><text x="40" y="662" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">le bon dosage.</text><rect x="40" y="700" width="600" height="56" rx="4" fill="#F4F8FB" stroke="#D5DDE3" stroke-width="1"/><text x="56" y="722" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#5C6573">À LIRE AUSSI</text><text x="56" y="744" font-family="Arial, sans-serif" font-size="12" font-weight="600" fill="#107ACA">→ Comment les start-ups réinventent la semaine de 4 jours</text></svg>'
)
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- ❓ 3. QUESTIONS — Plage V20 : 55555555-0020-*
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────────
-- 🟢 Q1 : CE A2 texte — pharmacie (distracteurs piégeux)
-- ──────────────────────────────────────────────────────────────────────────

INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000001', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Quand madame Petit peut-elle retirer sa commande sans rendez-vous ?',
    'Le SMS distingue deux créneaux : « du mardi au vendredi de 9h à 19h » (retrait libre) et « le samedi sur rendez-vous uniquement ». La réponse est donc du mardi au vendredi. Le choix A est faux car il inclut le samedi qui demande un RDV. Le choix C est vrai mais incomplet (le samedi existe mais avec une condition restrictive). Le choix D généralise abusivement à tous les jours, alors que lundi et dimanche ne sont pas mentionnés.',
    '44444444-0020-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000001', 'Du mardi au samedi sans condition',           false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000001', 'Du mardi au vendredi de 9h à 19h',             true,  2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000001', 'Le samedi uniquement',                          false, 3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000001', 'Tous les jours de 9h à 19h',                    false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🟡 Q2 : CE B1 image — colocation (3 distracteurs piégeux sur 3)
-- ──────────────────────────────────────────────────────────────────────────

INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000002', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_inference_intention',
    'Quel candidat peut postuler à cette colocation ?',
    'L''annonce impose quatre conditions cumulatives visibles dans les badges et les conditions d''entrée : « Étudiants uniquement », « Non-fumeurs », disponibilité « à partir du 1er octobre » et un bail de « 9 mois minimum (année universitaire) ». Seule la réponse C respecte ces quatre critères. La réponse A est une demi-vérité : étudiant oui, mais fumeur exclu et la caution est de 2 mois de loyer (soit 960 €, pas 480 €). La réponse B est une reformulation faussée : tout est correct sauf la date (le texte précise octobre, pas septembre). La réponse D est vraie sur le non-fumeur mais hors champ pour le reste : un jeune actif en CDI n''est pas « étudiant », ce qui est une condition exclusive.',
    '33333333-0020-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000002', 'Un étudiant fumeur qui peut payer une caution de 480 €',         false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000002', 'Un étudiant non-fumeur disponible dès septembre',                false, 2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000002', 'Un étudiant non-fumeur pour l''année universitaire dès octobre', true,  3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000002', 'Un jeune actif non-fumeur en CDI',                                false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🔴 Q3 : CE B2 image — article de presse (réponse non littérale)
-- ──────────────────────────────────────────────────────────────────────────

INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000003', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_ton_auteur',
    'Quelle est la position défendue par l''auteur dans cet article ?',
    'L''auteur reconnaît les bénéfices du télétravail (« plébiscité par les salariés », chiffres positifs) tout en pointant ses limites (troubles musculosquelettiques, isolement des jeunes, perte des savoir-faire informels). Il conclut explicitement : « Plutôt que d''opposer naïvement défenseurs et détracteurs, l''heure est venue de penser un télétravail intelligent : limité dans son volume, accompagné dans ses outils, et surtout pensé en fonction des métiers ». Il défend donc une position d''équilibre, qui appelle à un usage régulé du télétravail. La réponse A confond constat (le télétravail séduit les salariés) et position défendue (l''article ne plaide pas pour son extension). La réponse C est une demi-vérité : l''auteur évoque effectivement des limites mais n''appelle absolument pas à revenir au présentiel. La réponse D adopte une position adjacente mais trop tranchée : l''auteur ne dit pas que le télétravail est un échec, il appelle à l''ajuster.',
    '33333333-0020-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000003', 'Le télétravail doit être étendu, puisque les salariés le plébiscitent',          false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000003', 'Le télétravail doit être régulé et adapté à chaque métier et étape de carrière', true,  2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000003', 'Le télétravail montre ses limites, un retour au présentiel s''impose',            false, 3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000003', 'Le télétravail est un échec, l''enthousiasme initial était mal fondé',           false, 4);
