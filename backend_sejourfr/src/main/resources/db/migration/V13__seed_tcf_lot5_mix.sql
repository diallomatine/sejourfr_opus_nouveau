-- ============================================================================
-- V13 : Lot 5 TCF — Mix image (CE A2/B1) + texte (CE B2 + STRUCTURE A2/B1/B2)
-- ============================================================================
-- 📋 24 questions : 8 avec image (CE A2 + CE B1), 16 texte
--
-- 🎯 Templates SVG utilisés :
--    • SMS / message court
--    • E-mail (boîte de réception)
--    • Petite annonce
--    • Billet de transport
--    • Panneau / affiche
--    • Capture de site web
--
-- ⚙️ Migration de schéma :
--    ALTER TABLE medias ADD COLUMN inline_svg TEXT (idempotent, on garde)
--
-- ✅ Checklist étendue aux questions image :
--    1. Phrase grammaticalement correcte avec la bonne réponse
--    2. Distracteurs strictement faux (raison précise)
--    3. Explication sans pléonasme ni faute
--    4. Accents/caractères spéciaux vérifiés
--    5. Pas d'ambiguïté de genre/nombre
--    6. (IMAGE) L'info qui sert à répondre est PRÉSENTE dans le SVG
--    7. (IMAGE) Les distracteurs sont plausibles au regard du SVG
--    8. (IMAGE) Aucun choix ne demande des connaissances hors image
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 🔧 1. ÉVOLUTION DE SCHÉMA (idempotent)
-- ----------------------------------------------------------------------------
ALTER TABLE medias ADD COLUMN IF NOT EXISTS inline_svg TEXT;
CREATE INDEX IF NOT EXISTS idx_medias_has_inline_svg
    ON medias((inline_svg IS NOT NULL));

-- Les medias SVG inline (CE A2/B1) n'ont pas d'url : on relache la contrainte.
ALTER TABLE medias ALTER COLUMN url DROP NOT NULL;


-- ============================================================================
-- 🖼️ 2. MEDIAS (8 SVG inline) — Plage : 33333333-0013-xxxx-...
-- ============================================================================

-- MEDIA 1 : SMS d'opérateur (Orange, forfait à 90%) — niveau A2
INSERT INTO medias (id, type, url, alt_text, inline_svg) VALUES (
    '33333333-0013-0000-0000-000000000010',
    'IMAGE',
    NULL,
    'Capture d''écran d''un SMS reçu de l''opérateur Orange : la consommation de données mobiles a atteint 90% du forfait mensuel.',
    '<svg width="100%" viewBox="0 0 680 660" role="img" xmlns="http://www.w3.org/2000/svg"><title>SMS Orange : forfait à 90%</title><desc>Écran de téléphone affichant un SMS de l''opérateur Orange indiquant que la consommation de données mobiles a atteint 90 pourcent du forfait mensuel.</desc><rect x="0" y="0" width="680" height="660" fill="#F5F5F7"/><rect x="170" y="40" width="340" height="600" rx="42" fill="#1A1A1A"/><rect x="180" y="80" width="320" height="560" rx="6" fill="#FFFFFF"/><rect x="280" y="50" width="120" height="26" rx="13" fill="#1A1A1A"/><circle cx="395" cy="63" r="4" fill="#2A2A2A"/><text x="200" y="108" font-family="Arial, sans-serif" font-size="14" font-weight="600" fill="#0F1839">9:42</text><g transform="translate(440, 96)"><rect x="0" y="0" width="3" height="8" rx="0.5" fill="#0F1839"/><rect x="5" y="-2" width="3" height="10" rx="0.5" fill="#0F1839"/><rect x="10" y="-4" width="3" height="12" rx="0.5" fill="#0F1839"/><rect x="15" y="-6" width="3" height="14" rx="0.5" fill="#0F1839"/></g><rect x="482" y="92" width="14" height="8" rx="2" fill="none" stroke="#0F1839" stroke-width="1"/><rect x="484" y="94" width="9" height="4" fill="#168F5B"/><rect x="180" y="124" width="320" height="44" fill="#FAFAFA"/><line x1="180" y1="168" x2="500" y2="168" stroke="#E5E5E7" stroke-width="0.5"/><path d="M 196 138 L 188 146 L 196 154" fill="none" stroke="#FF6B35" stroke-width="2" stroke-linecap="round"/><text x="210" y="151" font-family="Arial, sans-serif" font-size="13" fill="#FF6B35">Messages</text><text x="340" y="151" text-anchor="middle" font-family="Arial, sans-serif" font-size="15" font-weight="600" fill="#0F1839">Orange Info</text><g transform="translate(340, 200)"><circle cx="0" cy="0" r="24" fill="#FF6B35"/><text x="0" y="6" text-anchor="middle" font-family="Arial, sans-serif" font-size="18" font-weight="700" fill="#FFFFFF">O</text></g><text x="340" y="246" text-anchor="middle" font-family="Arial, sans-serif" font-size="13" font-weight="600" fill="#0F1839">Orange Info</text><text x="340" y="262" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" fill="#888888">SMS · 9:41</text><rect x="200" y="290" width="270" height="245" rx="14" fill="#E8E8ED"/><text x="216" y="316" font-family="Arial, sans-serif" font-size="12" font-weight="600" fill="#0F1839">Orange</text><text x="216" y="340" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Bonjour,</text><text x="216" y="362" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Vous avez utilisé</text><text x="216" y="378" font-family="Arial, sans-serif" font-size="12" font-weight="700" fill="#E1372F">90% de votre forfait</text><text x="216" y="394" font-family="Arial, sans-serif" font-size="12" font-weight="700" fill="#E1372F">internet mobile</text><text x="216" y="410" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">ce mois-ci.</text><text x="216" y="434" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Pour éviter une</text><text x="216" y="450" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">coupure, rechargez</text><text x="216" y="466" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">votre forfait sur</text><text x="216" y="482" font-family="Arial, sans-serif" font-size="12" font-weight="600" fill="#1E3A8C">orange.fr/recharge</text><text x="216" y="506" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Stop SMS au 38059</text><text x="216" y="522" font-family="Arial, sans-serif" font-size="11" fill="#888888">(gratuit)</text></svg>'
),

-- MEDIA 2 : Affiche événementielle (concert gratuit) — niveau A2
(
    '33333333-0013-0000-0000-000000000011',
    'IMAGE',
    NULL,
    'Affiche annonçant un concert gratuit le samedi 12 juillet à 21h dans le parc municipal de la ville, organisé par la mairie.',
    '<svg width="100%" viewBox="0 0 680 800" role="img" xmlns="http://www.w3.org/2000/svg"><title>Affiche concert gratuit en plein air</title><desc>Affiche annonçant un concert d''été gratuit le samedi 12 juillet à 21h au parc municipal de la ville, organisé par la mairie.</desc><rect x="0" y="0" width="680" height="800" fill="#1E3A8C"/><rect x="40" y="40" width="600" height="720" fill="#FDF6E3" stroke="#0F1839" stroke-width="2"/><rect x="60" y="60" width="560" height="60" fill="#E1372F"/><text x="340" y="100" text-anchor="middle" font-family="Georgia, serif" font-size="32" font-weight="700" fill="#FFFFFF">CONCERT D''ÉTÉ</text><text x="340" y="180" text-anchor="middle" font-family="Arial, sans-serif" font-size="22" fill="#0F1839">en plein air, sous les étoiles</text><g transform="translate(180, 240)"><rect x="0" y="0" width="320" height="100" fill="#FFFFFF" stroke="#E1372F" stroke-width="3"/><text x="160" y="40" text-anchor="middle" font-family="Arial, sans-serif" font-size="18" font-weight="700" fill="#0F1839">SAMEDI 12 JUILLET</text><line x1="60" y1="55" x2="260" y2="55" stroke="#E1372F" stroke-width="1"/><text x="160" y="80" text-anchor="middle" font-family="Arial, sans-serif" font-size="32" font-weight="700" fill="#E1372F">à 21h00</text></g><g transform="translate(340, 380)"><circle cx="0" cy="0" r="48" fill="#E1372F"/><text x="0" y="-4" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#FFFFFF">ENTRÉE</text><text x="0" y="20" text-anchor="middle" font-family="Arial, sans-serif" font-size="22" font-weight="700" fill="#FFFFFF">GRATUITE</text></g><text x="340" y="500" text-anchor="middle" font-family="Arial, sans-serif" font-size="20" fill="#0F1839">📍 Parc municipal — kiosque central</text><text x="340" y="540" text-anchor="middle" font-family="Arial, sans-serif" font-size="16" fill="#0F1839">Avenue des Tilleuls, 12 rue du Parc</text><line x1="140" y1="580" x2="540" y2="580" stroke="#0F1839" stroke-width="1" stroke-dasharray="4 4"/><text x="340" y="615" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" fill="#5C6573">Trois groupes locaux à l''affiche</text><text x="340" y="635" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" fill="#5C6573">Restauration sur place</text><text x="340" y="655" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" fill="#5C6573">En cas de pluie : reporté au dimanche</text><rect x="60" y="700" width="560" height="40" fill="#0F1839"/><text x="340" y="725" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#FFFFFF">Organisé par la mairie · plus d''infos : ville.fr/concerts</text></svg>'
),

-- MEDIA 3 : Panneau d'horaires bibliothèque — niveau A2
(
    '33333333-0013-0000-0000-000000000012',
    'IMAGE',
    NULL,
    'Panneau affichant les horaires d''ouverture de la bibliothèque municipale : du mardi au vendredi de 10h à 18h, samedi de 10h à 17h, fermée le dimanche et le lundi.',
    '<svg width="100%" viewBox="0 0 680 560" role="img" xmlns="http://www.w3.org/2000/svg"><title>Horaires d''ouverture bibliothèque municipale</title><desc>Panneau affichant les horaires d''ouverture de la bibliothèque municipale : du mardi au vendredi de 10h à 18h, samedi de 10h à 17h, fermée le dimanche et le lundi.</desc><rect x="0" y="0" width="680" height="560" fill="#E8ECF8"/><rect x="60" y="40" width="560" height="480" rx="8" fill="#FFFFFF" stroke="#15296B" stroke-width="3"/><rect x="60" y="40" width="560" height="80" fill="#1E3A8C"/><text x="340" y="80" text-anchor="middle" font-family="Georgia, serif" font-size="26" font-weight="700" fill="#FFFFFF">BIBLIOTHÈQUE MUNICIPALE</text><text x="340" y="105" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" fill="#FFFFFF">Horaires d''ouverture</text><g transform="translate(120, 160)"><line x1="0" y1="0" x2="440" y2="0" stroke="#0F1839" stroke-width="0.5"/><text x="0" y="32" font-family="Arial, sans-serif" font-size="17" fill="#7A8794">Lundi</text><text x="440" y="32" text-anchor="end" font-family="Arial, sans-serif" font-size="17" font-weight="700" fill="#E1372F">FERMÉ</text><line x1="0" y1="50" x2="440" y2="50" stroke="#0F1839" stroke-width="0.5"/><text x="0" y="82" font-family="Arial, sans-serif" font-size="17" font-weight="600" fill="#0F1839">Mardi</text><text x="440" y="82" text-anchor="end" font-family="Arial, sans-serif" font-size="17" font-weight="700" fill="#168F5B">10h — 18h</text><line x1="0" y1="100" x2="440" y2="100" stroke="#0F1839" stroke-width="0.5"/><text x="0" y="132" font-family="Arial, sans-serif" font-size="17" font-weight="600" fill="#0F1839">Mercredi</text><text x="440" y="132" text-anchor="end" font-family="Arial, sans-serif" font-size="17" font-weight="700" fill="#168F5B">10h — 18h</text><line x1="0" y1="150" x2="440" y2="150" stroke="#0F1839" stroke-width="0.5"/><text x="0" y="182" font-family="Arial, sans-serif" font-size="17" font-weight="600" fill="#0F1839">Jeudi</text><text x="440" y="182" text-anchor="end" font-family="Arial, sans-serif" font-size="17" font-weight="700" fill="#168F5B">10h — 18h</text><line x1="0" y1="200" x2="440" y2="200" stroke="#0F1839" stroke-width="0.5"/><text x="0" y="232" font-family="Arial, sans-serif" font-size="17" font-weight="600" fill="#0F1839">Vendredi</text><text x="440" y="232" text-anchor="end" font-family="Arial, sans-serif" font-size="17" font-weight="700" fill="#168F5B">10h — 18h</text><line x1="0" y1="250" x2="440" y2="250" stroke="#0F1839" stroke-width="0.5"/><text x="0" y="282" font-family="Arial, sans-serif" font-size="17" font-weight="600" fill="#0F1839">Samedi</text><text x="440" y="282" text-anchor="end" font-family="Arial, sans-serif" font-size="17" font-weight="700" fill="#168F5B">10h — 17h</text><line x1="0" y1="300" x2="440" y2="300" stroke="#0F1839" stroke-width="0.5"/><text x="0" y="332" font-family="Arial, sans-serif" font-size="17" fill="#7A8794">Dimanche</text><text x="440" y="332" text-anchor="end" font-family="Arial, sans-serif" font-size="17" font-weight="700" fill="#E1372F">FERMÉ</text><line x1="0" y1="350" x2="440" y2="350" stroke="#0F1839" stroke-width="0.5"/></g></svg>'
),

-- MEDIA 4 : Capture site web — horaires médecin — niveau A2
(
    '33333333-0013-0000-0000-000000000013',
    'IMAGE',
    NULL,
    'Capture d''écran du site Doctolib pour le cabinet du docteur Bernard, médecin généraliste, montrant les créneaux disponibles : pas de disponibilité aujourd''hui, premier rendez-vous possible demain à 11h30.',
    '<svg width="100%" viewBox="0 0 680 540" role="img" xmlns="http://www.w3.org/2000/svg"><title>Recherche de rendez-vous Doctolib chez un médecin</title><desc>Capture d''écran du site Doctolib pour le cabinet du docteur Bernard, médecin généraliste, montrant les créneaux disponibles : pas de disponibilité aujourd''hui, premier rendez-vous possible demain à 11h30.</desc><rect x="0" y="0" width="680" height="540" fill="#F4F8FB"/><rect x="20" y="20" width="640" height="500" rx="8" fill="#FFFFFF" stroke="#D5DDE3" stroke-width="1"/><rect x="20" y="20" width="640" height="50" rx="8" fill="#FFFFFF"/><rect x="20" y="60" width="640" height="10" fill="#FFFFFF"/><line x1="20" y1="70" x2="660" y2="70" stroke="#D5DDE3" stroke-width="1"/><text x="40" y="52" font-family="Arial, sans-serif" font-size="20" font-weight="700" fill="#107ACA">doctolib</text><g transform="translate(560, 32)"><rect x="0" y="0" width="60" height="28" rx="14" fill="#107ACA"/><text x="30" y="18" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="600" fill="#FFFFFF">Connexion</text></g><rect x="40" y="90" width="600" height="100" rx="6" fill="#F4F8FB"/><g transform="translate(60, 110)"><rect x="0" y="0" width="60" height="60" rx="30" fill="#D5DDE3"/><text x="30" y="38" text-anchor="middle" font-family="Arial, sans-serif" font-size="24" font-weight="700" fill="#5C6573">B</text></g><text x="140" y="130" font-family="Arial, sans-serif" font-size="18" font-weight="700" fill="#0F1839">Dr Bernard — Médecin généraliste</text><text x="140" y="152" font-family="Arial, sans-serif" font-size="13" fill="#5C6573">📍 24 rue Victor Hugo, 75011 Paris</text><text x="140" y="172" font-family="Arial, sans-serif" font-size="13" fill="#5C6573">Conventionné secteur 1 · Carte Vitale acceptée</text><text x="40" y="220" font-family="Arial, sans-serif" font-size="14" font-weight="600" fill="#0F1839">Prendre rendez-vous</text><g transform="translate(40, 240)"><rect x="0" y="0" width="120" height="40" rx="6" fill="#FFFFFF" stroke="#D5DDE3" stroke-width="1"/><text x="60" y="18" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" font-weight="600" fill="#5C6573">AUJOURD''HUI</text><text x="60" y="33" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="600" fill="#E1372F">complet</text></g><g transform="translate(170, 240)"><rect x="0" y="0" width="120" height="40" rx="6" fill="#107ACA"/><text x="60" y="18" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" font-weight="600" fill="#FFFFFF">DEMAIN</text><text x="60" y="33" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="600" fill="#FFFFFF">5 créneaux</text></g><g transform="translate(300, 240)"><rect x="0" y="0" width="120" height="40" rx="6" fill="#FFFFFF" stroke="#D5DDE3" stroke-width="1"/><text x="60" y="18" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" font-weight="600" fill="#5C6573">APRÈS-DEMAIN</text><text x="60" y="33" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="600" fill="#0F1839">8 créneaux</text></g><text x="40" y="320" font-family="Arial, sans-serif" font-size="13" font-weight="600" fill="#0F1839">Créneaux disponibles demain :</text><g transform="translate(40, 340)"><rect x="0" y="0" width="80" height="36" rx="4" fill="#FFFFFF" stroke="#107ACA" stroke-width="1.5"/><text x="40" y="22" text-anchor="middle" font-family="Arial, sans-serif" font-size="13" font-weight="600" fill="#107ACA">11h30</text></g><g transform="translate(130, 340)"><rect x="0" y="0" width="80" height="36" rx="4" fill="#FFFFFF" stroke="#107ACA" stroke-width="1.5"/><text x="40" y="22" text-anchor="middle" font-family="Arial, sans-serif" font-size="13" font-weight="600" fill="#107ACA">14h00</text></g><g transform="translate(220, 340)"><rect x="0" y="0" width="80" height="36" rx="4" fill="#FFFFFF" stroke="#107ACA" stroke-width="1.5"/><text x="40" y="22" text-anchor="middle" font-family="Arial, sans-serif" font-size="13" font-weight="600" fill="#107ACA">15h15</text></g><g transform="translate(310, 340)"><rect x="0" y="0" width="80" height="36" rx="4" fill="#FFFFFF" stroke="#107ACA" stroke-width="1.5"/><text x="40" y="22" text-anchor="middle" font-family="Arial, sans-serif" font-size="13" font-weight="600" fill="#107ACA">16h45</text></g><g transform="translate(400, 340)"><rect x="0" y="0" width="80" height="36" rx="4" fill="#FFFFFF" stroke="#107ACA" stroke-width="1.5"/><text x="40" y="22" text-anchor="middle" font-family="Arial, sans-serif" font-size="13" font-weight="600" fill="#107ACA">17h30</text></g><rect x="40" y="410" width="600" height="50" rx="6" fill="#FDECEB"/><text x="60" y="430" font-family="Arial, sans-serif" font-size="13" font-weight="600" fill="#E1372F">⚠ Annulez au moins 24h avant si vous ne pouvez pas venir.</text><text x="60" y="448" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">En cas d''urgence, contactez le 15 (SAMU) ou les urgences.</text></svg>'
),

-- MEDIA 5 : E-mail Alliance Française — niveau B1
(
    '33333333-0013-0000-0000-000000000020',
    'IMAGE',
    NULL,
    'Capture d''écran d''un client de messagerie affichant un e-mail reçu de l''Alliance Française confirmant l''inscription à un cours de français niveau B1, le mardi à 18h, à partir du 15 septembre.',
    '<svg width="100%" viewBox="0 0 680 540" role="img" xmlns="http://www.w3.org/2000/svg"><title>Email confirmation inscription cours de français B1</title><desc>Capture d''écran d''un client de messagerie affichant un email reçu de l''Alliance Française confirmant l''inscription à un cours de français niveau B1, le mardi à 18h, à partir du 15 septembre.</desc><rect x="0" y="0" width="680" height="540" fill="#F1F3F4"/><rect x="20" y="20" width="640" height="500" rx="8" fill="#FFFFFF" stroke="#DADCE0" stroke-width="1"/><line x1="20" y1="76" x2="660" y2="76" stroke="#DADCE0" stroke-width="0.5"/><g transform="translate(40, 38)"><rect x="0" y="4" width="20" height="2" fill="#5F6368" rx="1"/><rect x="0" y="11" width="20" height="2" fill="#5F6368" rx="1"/><rect x="0" y="18" width="20" height="2" fill="#5F6368" rx="1"/></g><text x="80" y="55" font-family="Arial, sans-serif" font-size="20" font-weight="500" fill="#5F6368">Boîte de réception</text><g transform="translate(560, 32)"><rect x="0" y="0" width="32" height="32" rx="16" fill="#1A73E8"/><text x="16" y="22" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" font-weight="600" fill="#FFFFFF">M</text></g><rect x="20" y="76" width="640" height="60" fill="#E8F0FE"/><line x1="20" y1="136" x2="660" y2="136" stroke="#DADCE0" stroke-width="0.5"/><g transform="translate(48, 95)"><path d="M 0 0 L 12 6 L 0 12 Z" fill="#FBBC04"/></g><g transform="translate(80, 95)"><circle cx="9" cy="9" r="9" fill="#1A73E8"/><text x="9" y="13" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" font-weight="600" fill="#FFFFFF">A</text></g><text x="115" y="110" font-family="Arial, sans-serif" font-size="14" font-weight="600" fill="#202124">Alliance Française</text><text x="115" y="126" font-family="Arial, sans-serif" font-size="13" fill="#202124">Confirmation de votre inscription au cours de français B1</text><text x="600" y="110" text-anchor="end" font-family="Arial, sans-serif" font-size="12" fill="#5F6368">14:23</text><rect x="40" y="160" width="600" height="340" fill="#FFFFFF"/><line x1="40" y1="200" x2="640" y2="200" stroke="#DADCE0" stroke-width="0.5"/><text x="40" y="184" font-family="Arial, sans-serif" font-size="18" font-weight="600" fill="#202124">Confirmation de votre inscription au cours de français B1</text><g transform="translate(40, 220)"><circle cx="20" cy="20" r="20" fill="#1A73E8"/><text x="20" y="26" text-anchor="middle" font-family="Arial, sans-serif" font-size="16" font-weight="600" fill="#FFFFFF">A</text></g><text x="90" y="232" font-family="Arial, sans-serif" font-size="14" font-weight="600" fill="#202124">Alliance Française</text><text x="220" y="232" font-family="Arial, sans-serif" font-size="13" fill="#5F6368">&lt;inscriptions@alliance-francaise.fr&gt;</text><text x="90" y="252" font-family="Arial, sans-serif" font-size="13" fill="#5F6368">à moi</text><text x="40" y="290" font-family="Arial, sans-serif" font-size="14" fill="#202124">Madame, Monsieur,</text><text x="40" y="316" font-family="Arial, sans-serif" font-size="14" fill="#202124">Nous vous confirmons votre inscription au cours de français de</text><text x="40" y="334" font-family="Arial, sans-serif" font-size="14" fill="#202124">niveau <tspan font-weight="700" fill="#1A73E8">B1</tspan>. Les cours auront lieu tous les <tspan font-weight="700" fill="#1A73E8">mardis de 18h à 20h</tspan>,</text><text x="40" y="352" font-family="Arial, sans-serif" font-size="14" fill="#202124">à partir du <tspan font-weight="700" fill="#1A73E8">15 septembre</tspan>, en salle 204.</text><text x="40" y="382" font-family="Arial, sans-serif" font-size="14" fill="#202124">Merci de vous présenter dix minutes avant le début du premier</text><text x="40" y="400" font-family="Arial, sans-serif" font-size="14" fill="#202124">cours avec une pièce d''identité et le reçu de paiement.</text><text x="40" y="430" font-family="Arial, sans-serif" font-size="14" fill="#202124">Cordialement,</text><text x="40" y="452" font-family="Arial, sans-serif" font-size="14" fill="#202124">Le secrétariat de l''Alliance Française</text></svg>'
),

-- MEDIA 6 : Petite annonce immobilière Lyon — niveau B1
(
    '33333333-0013-0000-0000-000000000021',
    'IMAGE',
    NULL,
    'Annonce immobilière en ligne pour la location d''un T2 de 42 mètres carrés à Lyon 7e arrondissement, à 780 euros par mois charges comprises, 3e étage avec ascenseur, métro à 5 minutes à pied.',
    '<svg width="100%" viewBox="0 0 680 720" role="img" xmlns="http://www.w3.org/2000/svg"><title>Petite annonce de location appartement Lyon</title><desc>Annonce immobilière en ligne pour la location d''un T2 de 42 mètres carrés à Lyon 7e arrondissement, à 780 euros par mois charges comprises.</desc><rect x="0" y="0" width="680" height="720" fill="#F7F8FA"/><rect x="20" y="20" width="640" height="56" rx="6" fill="#FFFFFF" stroke="#E0E2E7" stroke-width="1"/><text x="40" y="55" font-family="Georgia, serif" font-size="22" font-weight="700" fill="#E1372F">Loca</text><text x="92" y="55" font-family="Georgia, serif" font-size="22" font-weight="700" fill="#1E3A8C">Direct</text><rect x="20" y="96" width="640" height="600" rx="8" fill="#FFFFFF" stroke="#E0E2E7" stroke-width="1"/><rect x="20" y="96" width="640" height="180" rx="8" fill="#E8ECF8"/><g transform="translate(280, 140)"><rect x="0" y="40" width="120" height="80" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1.5"/><polygon points="0,40 60,0 120,40" fill="#E1372F" stroke="#B5251E" stroke-width="1"/><rect x="20" y="60" width="20" height="30" fill="#1E3A8C"/><rect x="60" y="60" width="20" height="20" fill="#1E3A8C"/><rect x="85" y="60" width="20" height="20" fill="#1E3A8C"/><rect x="60" y="90" width="20" height="20" fill="#1E3A8C"/><rect x="85" y="90" width="20" height="20" fill="#1E3A8C"/><rect x="55" y="36" width="10" height="10" fill="#0F1839"/></g><rect x="40" y="240" width="60" height="22" rx="11" fill="#168F5B"/><text x="70" y="256" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#FFFFFF">À louer</text><rect x="110" y="240" width="80" height="22" rx="11" fill="#FDECEB"/><text x="150" y="256" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#E1372F">Disponible</text><text x="40" y="310" font-family="Arial, sans-serif" font-size="24" font-weight="700" fill="#0F1839">Appartement T2 — 42 m²</text><text x="40" y="338" font-family="Arial, sans-serif" font-size="14" fill="#5C6573">Lyon 7e arrondissement · Quartier Jean Macé</text><text x="40" y="386" font-family="Arial, sans-serif" font-size="36" font-weight="700" fill="#1E3A8C">780 €</text><text x="170" y="386" font-family="Arial, sans-serif" font-size="16" fill="#5C6573">/ mois</text><text x="170" y="406" font-family="Arial, sans-serif" font-size="12" font-weight="600" fill="#168F5B">charges comprises</text><line x1="40" y1="430" x2="640" y2="430" stroke="#E0E2E7" stroke-width="1"/><g transform="translate(40, 460)"><rect x="0" y="0" width="280" height="60" rx="6" fill="#F7F8FA"/><text x="20" y="26" font-family="Arial, sans-serif" font-size="12" fill="#5C6573">Surface</text><text x="20" y="46" font-family="Arial, sans-serif" font-size="16" font-weight="700" fill="#0F1839">42 m²</text></g><g transform="translate(360, 460)"><rect x="0" y="0" width="280" height="60" rx="6" fill="#F7F8FA"/><text x="20" y="26" font-family="Arial, sans-serif" font-size="12" fill="#5C6573">Pièces</text><text x="20" y="46" font-family="Arial, sans-serif" font-size="16" font-weight="700" fill="#0F1839">2 pièces</text></g><g transform="translate(40, 530)"><rect x="0" y="0" width="280" height="60" rx="6" fill="#F7F8FA"/><text x="20" y="26" font-family="Arial, sans-serif" font-size="12" fill="#5C6573">Étage</text><text x="20" y="46" font-family="Arial, sans-serif" font-size="16" font-weight="700" fill="#0F1839">3e avec ascenseur</text></g><g transform="translate(360, 530)"><rect x="0" y="0" width="280" height="60" rx="6" fill="#F7F8FA"/><text x="20" y="26" font-family="Arial, sans-serif" font-size="12" fill="#5C6573">Métro</text><text x="20" y="46" font-family="Arial, sans-serif" font-size="16" font-weight="700" fill="#0F1839">à 5 min à pied</text></g><line x1="40" y1="610" x2="640" y2="610" stroke="#E0E2E7" stroke-width="1"/><text x="40" y="640" font-family="Arial, sans-serif" font-size="13" fill="#5C6573">Cuisine équipée, salle de bain rénovée, balcon donnant sur cour.</text><text x="40" y="660" font-family="Arial, sans-serif" font-size="13" fill="#5C6573">Idéal jeune couple ou personne seule. Animaux non acceptés.</text></svg>'
),

-- MEDIA 7 : Billet TGV — niveau B1
(
    '33333333-0013-0000-0000-000000000022',
    'IMAGE',
    NULL,
    'Billet électronique TGV INOUI 2e classe de Paris Gare de Lyon à Marseille Saint-Charles, vendredi 24 octobre, départ 14h08 arrivée 17h32, voiture 12 place 47, tarif Prem''s 49 euros.',
    '<svg width="100%" viewBox="0 0 680 440" role="img" xmlns="http://www.w3.org/2000/svg"><title>Billet TGV INOUI Paris-Marseille</title><desc>Billet électronique TGV INOUI de Paris Gare de Lyon à Marseille Saint-Charles, vendredi 24 octobre, départ 14h08 arrivée 17h32, voiture 12 place 47, classe 2.</desc><rect x="0" y="0" width="680" height="440" fill="#EBEEF2"/><rect x="40" y="40" width="600" height="360" rx="8" fill="#FFFFFF"/><line x1="460" y1="40" x2="460" y2="400" stroke="#EBEEF2" stroke-width="2" stroke-dasharray="4 4"/><rect x="40" y="40" width="420" height="60" rx="8" fill="#1E3A8C"/><rect x="40" y="80" width="420" height="20" fill="#1E3A8C"/><text x="60" y="78" font-family="Arial, sans-serif" font-size="22" font-weight="700" fill="#FFFFFF">TGV</text><text x="115" y="78" font-family="Georgia, serif" font-size="18" font-style="italic" font-weight="700" fill="#E1372F">INOUI</text><rect x="380" y="56" width="60" height="22" rx="11" fill="#FFFFFF"/><text x="410" y="71" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#1E3A8C">2e classe</text><text x="60" y="160" font-family="Arial, sans-serif" font-size="11" fill="#7A8794">DÉPART</text><text x="60" y="192" font-family="Arial, sans-serif" font-size="36" font-weight="700" fill="#0F1839">14h08</text><text x="60" y="220" font-family="Arial, sans-serif" font-size="15" font-weight="600" fill="#0F1839">Paris Gare de Lyon</text><text x="60" y="240" font-family="Arial, sans-serif" font-size="13" fill="#7A8794">Vendredi 24 octobre</text><g transform="translate(225, 180)"><line x1="0" y1="0" x2="50" y2="0" stroke="#1E3A8C" stroke-width="2" stroke-dasharray="3 3"/><circle cx="25" cy="0" r="10" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><path d="M 21 -3 L 28 0 L 21 3 Z" fill="#1E3A8C"/></g><text x="225" y="218" text-anchor="start" font-family="Arial, sans-serif" font-size="10" fill="#7A8794">3h24</text><text x="300" y="160" font-family="Arial, sans-serif" font-size="11" fill="#7A8794">ARRIVÉE</text><text x="300" y="192" font-family="Arial, sans-serif" font-size="36" font-weight="700" fill="#0F1839">17h32</text><text x="300" y="220" font-family="Arial, sans-serif" font-size="15" font-weight="600" fill="#0F1839">Marseille St-Charles</text><text x="300" y="240" font-family="Arial, sans-serif" font-size="13" fill="#7A8794">Vendredi 24 octobre</text><line x1="60" y1="270" x2="440" y2="270" stroke="#E0E2E7" stroke-width="1"/><text x="60" y="296" font-family="Arial, sans-serif" font-size="10" fill="#7A8794">VOITURE</text><text x="60" y="324" font-family="Arial, sans-serif" font-size="22" font-weight="700" fill="#0F1839">12</text><text x="150" y="296" font-family="Arial, sans-serif" font-size="10" fill="#7A8794">PLACE</text><text x="150" y="324" font-family="Arial, sans-serif" font-size="22" font-weight="700" fill="#0F1839">47</text><text x="240" y="296" font-family="Arial, sans-serif" font-size="10" fill="#7A8794">PLACEMENT</text><text x="240" y="324" font-family="Arial, sans-serif" font-size="15" font-weight="600" fill="#0F1839">Côté fenêtre</text><text x="60" y="360" font-family="Arial, sans-serif" font-size="10" fill="#7A8794">VOYAGEUR</text><text x="60" y="378" font-family="Arial, sans-serif" font-size="13" font-weight="600" fill="#0F1839">Mme DURAND Sophie</text><text x="240" y="360" font-family="Arial, sans-serif" font-size="10" fill="#7A8794">TARIF</text><text x="240" y="378" font-family="Arial, sans-serif" font-size="13" font-weight="600" fill="#0F1839">Prem''s — 49,00 €</text><rect x="490" y="290" width="120" height="80" rx="4" fill="#FDECEB" stroke="#E1372F" stroke-width="1"/><text x="550" y="310" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" font-weight="700" fill="#E1372F">À PRÉSENTER</text><text x="550" y="324" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" font-weight="700" fill="#E1372F">AVEC UNE PIÈCE</text><text x="550" y="338" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" font-weight="700" fill="#E1372F">D''IDENTITÉ</text></svg>'
),

-- MEDIA 8 : Site web — page d'un musée (tarifs et horaires) — niveau B1
(
    '33333333-0013-0000-0000-000000000023',
    'IMAGE',
    NULL,
    'Capture d''écran du site officiel d''un musée affichant les tarifs : plein tarif 12 euros, tarif réduit 8 euros, gratuit pour les moins de 18 ans et le premier dimanche du mois.',
    '<svg width="100%" viewBox="0 0 680 620" role="img" xmlns="http://www.w3.org/2000/svg"><title>Site web du musée d''Art moderne — tarifs</title><desc>Capture d''écran du site officiel d''un musée affichant les tarifs : plein tarif 12 euros, tarif réduit 8 euros, gratuit pour les moins de 18 ans et le premier dimanche du mois.</desc><rect x="0" y="0" width="680" height="620" fill="#FAFAFA"/><rect x="20" y="20" width="640" height="580" rx="6" fill="#FFFFFF" stroke="#D5D5D5" stroke-width="1"/><rect x="20" y="20" width="640" height="60" fill="#0F1839"/><text x="40" y="56" font-family="Georgia, serif" font-size="20" font-weight="700" fill="#FFFFFF">MUSÉE D''ART MODERNE</text><text x="40" y="73" font-family="Arial, sans-serif" font-size="11" fill="#A8B0C5">de la Ville</text><g transform="translate(450, 30)"><text x="0" y="22" font-family="Arial, sans-serif" font-size="12" fill="#FFFFFF">Collections</text><text x="80" y="22" font-family="Arial, sans-serif" font-size="12" fill="#FFFFFF">Expositions</text><text x="172" y="22" font-family="Arial, sans-serif" font-size="12" font-weight="700" fill="#E1372F">Tarifs</text></g><text x="40" y="120" font-family="Georgia, serif" font-size="26" font-weight="700" fill="#0F1839">Tarifs et horaires</text><line x1="40" y1="135" x2="120" y2="135" stroke="#E1372F" stroke-width="3"/><text x="40" y="172" font-family="Arial, sans-serif" font-size="16" font-weight="700" fill="#0F1839">Billets d''entrée</text><g transform="translate(40, 190)"><rect x="0" y="0" width="280" height="80" rx="6" fill="#F4F4F4"/><text x="20" y="30" font-family="Arial, sans-serif" font-size="14" fill="#5C6573">Plein tarif</text><text x="260" y="55" text-anchor="end" font-family="Arial, sans-serif" font-size="28" font-weight="700" fill="#0F1839">12 €</text></g><g transform="translate(360, 190)"><rect x="0" y="0" width="280" height="80" rx="6" fill="#F4F4F4"/><text x="20" y="30" font-family="Arial, sans-serif" font-size="14" fill="#5C6573">Tarif réduit</text><text x="20" y="48" font-family="Arial, sans-serif" font-size="11" fill="#7A8794">(étudiants, plus de 65 ans)</text><text x="260" y="55" text-anchor="end" font-family="Arial, sans-serif" font-size="28" font-weight="700" fill="#0F1839">8 €</text></g><g transform="translate(40, 290)"><rect x="0" y="0" width="600" height="100" rx="6" fill="#E6F5EC" stroke="#168F5B" stroke-width="1.5"/><g transform="translate(20, 22)"><rect x="0" y="0" width="60" height="22" rx="11" fill="#168F5B"/><text x="30" y="15" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#FFFFFF">GRATUIT</text></g><text x="100" y="38" font-family="Arial, sans-serif" font-size="14" font-weight="600" fill="#0F1839">Pour les moins de 18 ans</text><text x="100" y="58" font-family="Arial, sans-serif" font-size="14" font-weight="600" fill="#0F1839">Pour tous, le 1er dimanche de chaque mois</text><text x="100" y="78" font-family="Arial, sans-serif" font-size="12" fill="#5C6573">Pensez à venir tôt, l''affluence est forte ces jours-là.</text></g><text x="40" y="430" font-family="Arial, sans-serif" font-size="16" font-weight="700" fill="#0F1839">Horaires d''ouverture</text><g transform="translate(40, 450)"><rect x="0" y="0" width="600" height="120" rx="6" fill="#F4F4F4"/><text x="20" y="30" font-family="Arial, sans-serif" font-size="13" fill="#5C6573">Du mardi au dimanche</text><text x="580" y="30" text-anchor="end" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#168F5B">10h — 19h</text><line x1="20" y1="45" x2="580" y2="45" stroke="#D5D5D5" stroke-width="0.5"/><text x="20" y="70" font-family="Arial, sans-serif" font-size="13" fill="#5C6573">Nocturne le mercredi</text><text x="580" y="70" text-anchor="end" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#168F5B">jusqu''à 22h</text><line x1="20" y1="85" x2="580" y2="85" stroke="#D5D5D5" stroke-width="0.5"/><text x="20" y="110" font-family="Arial, sans-serif" font-size="13" fill="#5C6573">Lundi</text><text x="580" y="110" text-anchor="end" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#E1372F">fermé</text></g></svg>'
)
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- ❓ 3. QUESTIONS IMAGE (8) — CE A2 + CE B1
-- ============================================================================
-- Plage UUID : 55555555-0013-0000-...

-- ──────────────────────────────────────────────────────────────────────────
-- 🟢 CE A2 — 4 questions avec SVG
-- ──────────────────────────────────────────────────────────────────────────

-- Q1 : SMS Orange — repérage explicite
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000001', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_reperage_explicite',
    'Que dit ce SMS ?',
    'Le SMS indique en gras que « vous avez utilisé 90% de votre forfait internet mobile ce mois-ci ». Il informe donc d''une consommation élevée. Le forfait n''est ni gratuit, ni expiré, et il n''est pas question d''un nouveau forfait offert.',
    '33333333-0013-0000-0000-000000000010',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000001', 'Le client a presque épuisé son forfait internet',  true,  1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000001', 'Le forfait du client est devenu gratuit',          false, 2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000001', 'Le forfait du client a expiré',                    false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000001', 'L''opérateur offre un nouveau forfait au client',  false, 4);

-- Q2 : Affiche concert — détail spécifique (date)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000002', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Quand a lieu le concert ?',
    'L''affiche annonce clairement « SAMEDI 12 JUILLET à 21h00 ». Le concert a donc lieu le samedi 12 juillet. Les autres dates ne sont pas mentionnées. Le dimanche n''est cité que comme jour de report en cas de pluie.',
    '33333333-0013-0000-0000-000000000011',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000002', 'Vendredi 11 juillet',  false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000002', 'Samedi 12 juillet',    true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000002', 'Dimanche 13 juillet',  false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000002', 'Samedi 19 juillet',    false, 4);

-- Q3 : Panneau bibliothèque — détail spécifique (jours de fermeture)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000003', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Quels jours la bibliothèque est-elle fermée ?',
    'Le panneau indique en rouge « FERMÉ » en face de « Lundi » et « Dimanche ». La bibliothèque est donc fermée ces deux jours. Le mardi, mercredi, jeudi, vendredi et samedi sont ouverts.',
    '33333333-0013-0000-0000-000000000012',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000003', 'Le samedi et le dimanche',  false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000003', 'Le lundi et le dimanche',   true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000003', 'Le mardi et le jeudi',      false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000003', 'Le vendredi uniquement',    false, 4);

-- Q4 : Doctolib — repérage explicite (premier RDV)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000004', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_reperage_explicite',
    'Quel est le premier rendez-vous disponible chez le docteur Bernard ?',
    'La capture montre que la journée « AUJOURD''HUI » est marquée « complet » en rouge, et que pour « DEMAIN » 5 créneaux sont disponibles, le premier étant 11h30. Le premier rendez-vous possible est donc demain à 11h30. Aujourd''hui à 14h00 est impossible (journée complète), et les autres horaires (15h15, 17h30) sont également demain mais plus tard.',
    '33333333-0013-0000-0000-000000000013',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000004', 'Aujourd''hui à 14h00',  false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000004', 'Demain à 11h30',        true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000004', 'Demain à 17h30',        false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000004', 'Après-demain à 11h30',  false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🟡 CE B1 — 4 questions avec SVG
-- ──────────────────────────────────────────────────────────────────────────

-- Q5 : E-mail Alliance Française — détail spécifique (jour/heure)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000005', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_detail_specifique',
    'Quand auront lieu les cours de français ?',
    'L''e-mail précise en bleu : « Les cours auront lieu tous les mardis de 18h à 20h ». Les cours ont donc lieu le mardi soir. Les autres options (lundi, mercredi, samedi matin) ne sont pas mentionnées.',
    '33333333-0013-0000-0000-000000000020',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000005', 'Tous les lundis de 18h à 20h',     false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000005', 'Tous les mardis de 18h à 20h',     true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000005', 'Tous les mercredis de 14h à 16h',  false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000005', 'Tous les samedis matin',           false, 4);

-- Q6 : Annonce immobilière — inférence (à qui s'adresse l'annonce)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000006', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_inference_intention',
    'À qui cet appartement est-il déconseillé ?',
    'L''annonce précise en bas : « Animaux non acceptés ». L''appartement est donc déconseillé aux personnes qui ont un animal. Le texte mentionne aussi « idéal jeune couple ou personne seule » : il convient donc aux couples et aux personnes seules. La présence d''un ascenseur le rend accessible aux personnes âgées.',
    '33333333-0013-0000-0000-000000000021',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000006', 'À un jeune couple sans enfant',         false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000006', 'À une personne ayant un chien ou un chat', true, 2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000006', 'À une personne âgée',                   false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000006', 'À une personne seule',                   false, 4);

-- Q7 : Billet TGV — détail spécifique (durée du trajet)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000007', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_detail_specifique',
    'Combien de temps dure le trajet en TGV ?',
    'Le billet affiche entre le départ (14h08) et l''arrivée (17h32) la mention « 3h24 » au milieu de la flèche. La durée du trajet est donc de 3h24, qui correspond aussi au calcul direct (17h32 - 14h08 = 3h24).',
    '33333333-0013-0000-0000-000000000022',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000007', '2h24',  false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000007', '3h08',  false, 2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000007', '3h24',  true,  3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000007', '4h32',  false, 4);

-- Q8 : Site musée — inférence (économie possible)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000008', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_inference_intention',
    'Quand un adulte peut-il entrer gratuitement au musée ?',
    'Le bloc vert indique deux cas de gratuité : « pour les moins de 18 ans » et « pour tous, le 1er dimanche de chaque mois ». Pour un adulte (donc plus de 18 ans), la seule option de gratuité est le premier dimanche du mois. Les autres jours, l''entrée est payante (plein tarif ou tarif réduit selon les conditions).',
    '33333333-0013-0000-0000-000000000023',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000008', 'Tous les dimanches',                     false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000008', 'Le mercredi en nocturne',                false, 2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000008', 'Le 1er dimanche de chaque mois',         true,  3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000008', 'Jamais : c''est toujours payant',        false, 4);


-- ============================================================================
-- 📄 4. PASSAGES TEXTE (B2) — Plage : 44444444-0013-*
-- ============================================================================

INSERT INTO passages (id, type, content, theme_id) VALUES

-- Passage B2 — Vie professionnelle / sens du travail
(
    '44444444-0013-0000-0000-000000000001', 'TEXTE',
    E'On entend partout que les jeunes générations seraient devenues paresseuses, refusant le travail au profit de leurs loisirs. Le constat mérite d''être nuancé. Les enquêtes récentes montrent en réalité qu''elles ne refusent pas le travail, mais qu''elles cherchent davantage à lui donner du sens : conditions plus respectueuses, équilibre avec la vie personnelle, missions qui les engagent réellement. Loin du cliché des « tire-au-flanc », ces actifs questionnent simplement un modèle qui valorisait l''effort pour lui-même. Les entreprises capables d''entendre cette exigence s''adaptent ; les autres voient leurs talents partir ailleurs, parfois loin.',
    '22222222-0000-0000-0000-000000000002'
),

-- Passage B2 — Société / culture du livre
(
    '44444444-0013-0000-0000-000000000002', 'TEXTE',
    E'Contrairement aux prévisions les plus pessimistes, le livre papier ne s''est pas effondré face au numérique. Si la lecture sur écran progresse, en particulier chez les actifs pour des contenus courts, le livre imprimé conserve une place importante dans les habitudes. Plusieurs facteurs l''expliquent : un attachement sensoriel à l''objet, le confort visuel à la lecture longue, et le rôle social que joue encore la bibliothèque personnelle. Certains lecteurs combinent même les deux supports, profitant du numérique pour ses bibliothèques infinies, et revenant au papier dès qu''il s''agit d''un texte qu''ils souhaitent vraiment savourer.',
    '22222222-0000-0000-0000-000000000002'
)
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- ❓ 5. QUESTIONS TEXTE (16) — CE B2 + STRUCTURE A2/B1/B2
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────────
-- 🔴 CE B2 — 4 questions texte
-- ──────────────────────────────────────────────────────────────────────────

-- Q9 : CE B2 — Sens du travail (idée principale)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000009', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_idee_principale',
    'Quelle est l''idée principale défendue par l''auteur ?',
    'L''auteur écrit explicitement : « Le constat mérite d''être nuancé. Les enquêtes récentes montrent en réalité qu''elles ne refusent pas le travail, mais qu''elles cherchent davantage à lui donner du sens ». Il défend donc l''idée que les jeunes ne sont pas paresseux mais réclament du sens. Il ne valide pas le cliché de paresse, ne dit pas que les entreprises refusent ces aspirations (au contraire, certaines s''adaptent), et ne juge pas non plus le modèle traditionnel meilleur.',
    '44444444-0013-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000009', 'Les jeunes sont effectivement plus paresseux qu''avant',                  false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000009', 'Les jeunes ne refusent pas le travail mais en exigent davantage de sens', true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000009', 'Les entreprises refusent toujours d''entendre ces nouvelles aspirations',  false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000009', 'Le modèle ancien de valorisation de l''effort est largement supérieur',     false, 4);

-- Q10 : CE B2 — Sens du travail (reformulation des exigences)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000010', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_reformulation',
    'Que recherchent concrètement les jeunes actifs, selon le texte ?',
    'Le texte énumère trois attentes : « conditions plus respectueuses, équilibre avec la vie personnelle, missions qui les engagent réellement ». Le texte ne cite ni un salaire élevé, ni des promotions rapides, ni un télétravail intégral comme priorités.',
    '44444444-0013-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000010', 'Un salaire élevé et des promotions rapides',                            false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000010', 'De bonnes conditions, un équilibre vie pro/perso et des missions porteuses', true, 2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000010', 'Le télétravail intégral et la suppression du temps de présence',         false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000010', 'Une carrière internationale avec des déplacements fréquents',            false, 4);

-- Q11 : CE B2 — Livre papier (inférence)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000011', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_inference_intention',
    'Que peut-on conclure du comportement des lecteurs décrit dans le texte ?',
    'Le texte indique que « certains lecteurs combinent même les deux supports, profitant du numérique pour ses bibliothèques infinies, et revenant au papier dès qu''il s''agit d''un texte qu''ils souhaitent vraiment savourer ». La conclusion est donc que papier et numérique se complètent plutôt qu''ils ne s''excluent. Le texte ne dit pas que le numérique a définitivement gagné, que les lecteurs rejettent le numérique, ni que la lecture diminue globalement.',
    '44444444-0013-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000011', 'Le numérique a définitivement remplacé le papier',                  false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000011', 'Papier et numérique se complètent dans les usages',                  true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000011', 'Les lecteurs rejettent massivement le numérique',                    false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000011', 'La lecture, sous toutes ses formes, diminue fortement',              false, 4);

-- Q12 : CE B2 — Livre papier (reformulation des raisons)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000012', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_reformulation',
    'Pour quelles raisons le livre papier garde-t-il une place importante ?',
    'Le texte énumère trois facteurs : « un attachement sensoriel à l''objet, le confort visuel à la lecture longue, et le rôle social que joue encore la bibliothèque personnelle ». Le prix, le rejet du numérique ou un attachement traditionaliste ne sont pas évoqués comme explications.',
    '44444444-0013-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000012', 'Son prix inférieur à celui des livres numériques',                       false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000012', 'Un rapport sensoriel, le confort visuel et le rôle social de la bibliothèque', true, 2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000012', 'Un rejet de principe de toute technologie nouvelle',                     false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000012', 'Un attachement purement traditionaliste, sans raison pratique',          false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🟢 STRUCTURE A2 — 4 questions texte
-- ──────────────────────────────────────────────────────────────────────────

-- Q13 : STRUCT A2 — Pronom possessif "le mien"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000013', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_pronom_possessif_mien',
    'Complétez : « Ce vélo n''est pas à toi, c''est ___. »',
    '« Vélo » est un nom masculin singulier qui m''appartient (au locuteur) : le pronom possessif correct est « le mien ». « Le tien » désigne ce qui appartient à « tu » (l''interlocuteur, à qui justement on dit que le vélo n''appartient pas). « La mienne » est féminin singulier. « Les miens » est masculin pluriel.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000013', 'le tien',    false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000013', 'le mien',    true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000013', 'la mienne',  false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000013', 'les miens',  false, 4);

-- Q14 : STRUCT A2 — Verbe "faire" au présent (1re pers. pluriel)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000014', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_present_faire',
    'Complétez : « Le samedi, nous ___ les courses au marché. »',
    'Le verbe « faire » est irrégulier au présent. À la 1re personne du pluriel, la forme correcte est « faisons ». « Fasons » est mal orthographié (forme inexistante). « Faites » est la 2e personne du pluriel (vous faites). « Font » est la 3e personne du pluriel (ils font).',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000014', 'fasons',   false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000014', 'faisons',  true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000014', 'faites',   false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000014', 'font',     false, 4);

-- Q15 : STRUCT A2 — Quantité "beaucoup de"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000015', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_quantite_beaucoup_de',
    'Complétez : « Dans cette ville, il y a ___ touristes en été. »',
    'L''expression de quantité « beaucoup » s''emploie toujours avec « de » devant un nom, sans article (et sans s) : « beaucoup de touristes ». « Beaucoup des » ne s''emploie que pour désigner un ensemble particulier (beaucoup des touristes que j''ai vus). « Beaucoup les » est incorrect. « Beaucoup » seul ne peut pas précéder directement un nom.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000015', 'beaucoup',     false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000015', 'beaucoup de',  true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000015', 'beaucoup des', false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000015', 'beaucoup les', false, 4);

-- Q16 : STRUCT A2 — Préposition "chez"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000016', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_preposition_chez',
    'Complétez : « J''ai rendez-vous ___ le dentiste cet après-midi. »',
    'Devant le nom d''une personne ou d''un métier (dentiste, médecin, ami), on emploie la préposition « chez ». « À » s''emploie devant un lieu (à la pharmacie) ou une ville (à Paris). « Dans » s''emploie devant un lieu fermé (dans la maison). « Pour » exprime un but ou un destinataire.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000016', 'à',    false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000016', 'chez', true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000016', 'dans', false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000016', 'pour', false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🟡 STRUCTURE B1 — 4 questions texte
-- ──────────────────────────────────────────────────────────────────────────

-- Q17 : STRUCT B1 — Subjonctif "il est important que"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000017', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_subjonctif_important_que',
    'Complétez : « Il est important que vous ___ à l''heure pour l''entretien. »',
    'L''expression « il est important que » exprime la nécessité et est suivie du subjonctif. À la 2e personne du pluriel du verbe « être » au subjonctif présent : « soyez ». « Êtes » est l''indicatif présent. « Serez » est un futur simple. « Seriez » est un conditionnel présent. Aucun de ces temps ne s''emploie après « il est important que ».',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000017', 'êtes',   false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000017', 'soyez',  true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000017', 'serez',  false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000017', 'seriez', false, 4);

-- Q18 : STRUCT B1 — Pronom relatif "où" (temps)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000018', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_relatif_ou_temps',
    'Complétez : « Je me souviens du jour ___ nous nous sommes rencontrés. »',
    'Le pronom relatif « où » remplace ici un complément de temps (« le jour »). Il s''emploie aussi pour les compléments de lieu. « Que » remplace un complément d''objet direct, ce que « le jour » n''est pas ici. « Quand » est un mot interrogatif ou un adverbe, pas un pronom relatif dans cette construction. « Dont » remplace un complément introduit par « de ».',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000018', 'que',   false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000018', 'où',    true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000018', 'quand', false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000018', 'dont',  false, 4);

-- Q19 : STRUCT B1 — Cause "grâce à"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000019', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_cause_grace_a',
    'Complétez : « J''ai trouvé ce travail ___ mon ami Paul, qui m''a recommandé. »',
    '« Grâce à » introduit une cause à effet POSITIF (un coup de pouce, une aide qui produit un bon résultat). « À cause de » introduit aussi une cause, mais à effet négatif (à cause de la pluie, le concert a été annulé). « En raison de » est neutre et plus formel. « Malgré » introduit une concession, pas une cause.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000019', 'à cause de',    false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000019', 'grâce à',       true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000019', 'en raison de',  false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000019', 'malgré',        false, 4);

-- Q20 : STRUCT B1 — Pronom "le" qui reprend une idée
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000020', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_pronom_le_neutre',
    'Complétez : « — Tu sais que Pierre a déménagé ? — Oui, je ___ sais. »',
    'Le pronom « le » peut reprendre une proposition entière (ici : « que Pierre a déménagé »). On dit « je le sais » pour reprendre l''information. « La » serait un COD féminin singulier (incorrect ici). « Lui » est un pronom indirect (à lui/à elle). « Y » remplace un complément de lieu ou introduit par « à ».',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000020', 'la',   false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000020', 'le',   true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000020', 'lui',  false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000020', 'y',    false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🔴 STRUCTURE B2 — 4 questions texte
-- ──────────────────────────────────────────────────────────────────────────

-- Q21 : STRUCT B2 — Subjonctif après verbe d'opinion à la forme négative
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000021', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_subjonctif_opinion_negative',
    'Complétez : « Je ne pense pas qu''il ___ raison sur ce point. »',
    'Les verbes d''opinion (« penser », « croire », « trouver ») à la forme négative déclenchent le subjonctif (l''idée exprimée est mise en doute). « Ait » est la 3e personne du singulier du verbe « avoir » au subjonctif présent. « A » est l''indicatif présent. « Aurait » est un conditionnel. « Avait » est un imparfait. Aucun de ces trois temps n''est compatible avec « je ne pense pas que » au sens d''opinion mise en doute.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000021', 'a',      false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000021', 'ait',    true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000021', 'aurait', false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000021', 'avait',  false, 4);

-- Q22 : STRUCT B2 — Participe présent vs gérondif (cause)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000022', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_participe_present_cause',
    'Complétez : « ___ malade depuis plusieurs jours, il n''a pas pu venir travailler. »',
    'Pour exprimer une cause (état antérieur qui explique une conséquence), on emploie le participe présent « étant ». Le gérondif « en étant » exprimerait plutôt une simultanéité (« en étant malade, il continuait à travailler »), ce qui n''est pas le sens ici. « Été » est un participe passé, qui aurait besoin d''un auxiliaire pour fonctionner. « Soit » est un subjonctif présent, inadapté en tête de phrase ici.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000022', 'En étant', false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000022', 'Étant',    true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000022', 'Été',      false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000022', 'Soit',     false, 4);

-- Q23 : STRUCT B2 — Verbe pronominal de sens passif
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000023', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_pronominal_sens_passif',
    'Complétez : « Ce plat ___ avec un vin blanc sec, traditionnellement. »',
    'Le verbe pronominal « se servir » a ici un sens passif (= être servi). À la 3e personne du singulier du présent : « se sert ». « Sert » sans pronom réfléchi ne convient pas (un plat ne sert pas activement). « S''est servi » est un passé composé, qui changerait le sens (description d''une habitude générale demande le présent). « Se servait » est un imparfait, qui suggérerait une habitude révolue.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000023', 'sert',         false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000023', 'se sert',      true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000023', 's''est servi', false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000023', 'se servait',   false, 4);

-- Q24 : STRUCT B2 — Connecteur "en revanche"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0013-0000-0000-000000000024', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_connecteur_en_revanche',
    'Complétez : « Sophie adore le théâtre ; ___, elle n''apprécie pas du tout l''opéra. »',
    'Le contexte oppose deux préférences contraires (théâtre = positif, opéra = négatif) : on attend un connecteur d''opposition. « En revanche » exprime exactement cette opposition. « En effet » introduit une explication ou une confirmation. « Par conséquent » introduit une conséquence. « En outre » ajoute une idée dans le même sens.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000024', 'en effet',        false, 1),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000024', 'en revanche',     true,  2),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000024', 'par conséquent',  false, 3),
    (gen_random_uuid(), '55555555-0013-0000-0000-000000000024', 'en outre',        false, 4);
