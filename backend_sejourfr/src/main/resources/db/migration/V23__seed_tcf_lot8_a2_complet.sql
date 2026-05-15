-- ============================================================================
-- V22 : Lot 8 TCF — A2 complet avec distracteurs durcis (adaptés)
-- ============================================================================
-- 📋 24 questions A2 :
--    - 12 questions image (SMS, affiches, panneaux, étiquettes, etc.)
--    - 12 questions texte (passages courts 50-80 mots)
--
-- 🎯 Règles A2 (durcissement adapté) :
--    - ≥1 distracteur piégeux sur 3 (vs 2 sur 3 en B1/B2)
--    - Réponse peut être littérale, mais piégée par lecture rapide
--    - Stratégies A2 :
--      * info présente mais mal attribuée
--      * nombre/heure proche mais incorrect
--      * vrai mais répond à une autre question
--      * mot du texte sorti de son contexte
--    - Vocabulaire courant, phrases simples
--    - Pas d'inférence complexe
--
-- 📊 Répartition des compétences :
--    - ce_detail_specifique     : 10
--    - ce_reperage_explicite    : 8
--    - ce_reformulation         : 4
--    - ce_inference_intention   : 2
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 📄 1. PASSAGES TEXTE (6) — Plage V22 : 44444444-0022-*
-- ----------------------------------------------------------------------------

INSERT INTO passages (id, type, content, theme_id) VALUES

-- ────────── Passage 1 — Livraison colis SMS (Q13-Q14) ──────────
(
    '44444444-0022-0000-0000-000000000001', 'TEXTE',
    E'Bonjour Madame Garcia,\n\n' ||
    E'Votre colis sera livré demain mercredi. Choisissez un créneau de livraison :\n' ||
    E'- entre 9h et 12h\n' ||
    E'- entre 14h et 17h\n' ||
    E'- entre 17h et 20h\n\n' ||
    E'Répondez à ce message avec votre choix avant ce soir 18h.\n\n' ||
    E'Service livraison Express',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── Passage 2 — Mémo garde d'enfants (Q15-Q16) ──────────
(
    '44444444-0022-0000-0000-000000000002', 'TEXTE',
    E'Pour Léa,\n\n' ||
    E'Merci de garder Tom ce soir. Quelques infos importantes :\n\n' ||
    E'Le repas est dans le frigo : pâtes au jambon, à réchauffer 2 minutes au micro-ondes.\n\n' ||
    E'Tom doit aller au lit à 20h30, pas plus tard. Il peut regarder un dessin animé avant.\n\n' ||
    E'Si problème, mon numéro est sur la porte du frigo.\n\n' ||
    E'À tout à l''heure,\nSophie',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── Passage 3 — Annonce chambre étudiante (Q17-Q18) ──────────
(
    '44444444-0022-0000-0000-000000000003', 'TEXTE',
    E'Chambre à louer dans appartement étudiant.\n\n' ||
    E'15 m², meublée avec un lit, un bureau et une armoire. Cuisine et salle de bain partagées avec deux autres étudiantes.\n\n' ||
    E'Loyer : 380 € par mois, charges comprises.\n\n' ||
    E'Disponible à partir du 1er septembre. Bail de 9 mois minimum.\n\n' ||
    E'Contact : Marie au 06 12 34 56 78 (préférer les SMS).',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── Passage 4 — Mot d'absence enseignant (Q19-Q20) ──────────
(
    '44444444-0022-0000-0000-000000000004', 'TEXTE',
    E'Chers élèves,\n\n' ||
    E'Je serai absente ce jeudi 14 mars. Le cours de français de 10h est annulé.\n\n' ||
    E'À la place, vous avez deux exercices à faire dans le cahier rouge : pages 42 et 43. À rendre lundi prochain.\n\n' ||
    E'Le cours de vendredi 15 mars aura lieu normalement.\n\n' ||
    E'Bon courage,\nMadame Lefèvre',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── Passage 5 — Annonce perdu/trouvé (Q21-Q22) ──────────
(
    '44444444-0022-0000-0000-000000000005', 'TEXTE',
    E'PERDU\n\n' ||
    E'J''ai perdu mon chat samedi dernier dans le quartier. Il s''appelle Mistigri.\n\n' ||
    E'C''est un chat noir et blanc, avec un collier rouge. Il est très peureux.\n\n' ||
    E'Si vous le voyez, merci de m''appeler au 07 89 12 34 56. Récompense de 50 € promise.\n\n' ||
    E'Famille Dubois (appartement 12)',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── Passage 6 — SMS confirmation cours de sport (Q23-Q24) ──────────
(
    '44444444-0022-0000-0000-000000000006', 'TEXTE',
    E'Bonjour Karim,\n\n' ||
    E'Confirmation de votre inscription au cours de natation du mardi soir, de 19h à 20h.\n\n' ||
    E'Premier cours mardi prochain. Apportez votre maillot de bain, un bonnet et une serviette.\n\n' ||
    E'Le club est ouvert de 17h à 22h en semaine. Pensez à arriver 15 minutes avant le cours.\n\n' ||
    E'Club Aqua-Forme',
    '22222222-0000-0000-0000-000000000002'
)
ON CONFLICT (id) DO NOTHING;


-- ----------------------------------------------------------------------------
-- 🖼️ 2. MEDIAS (6 SVG) — Plage V22 : 33333333-0022-*
-- ----------------------------------------------------------------------------

INSERT INTO medias (id, type, url, alt_text, inline_svg) VALUES

-- ────────── Media 1 : SMS rappel rendez-vous dentiste ──────────
(
    '33333333-0022-0000-0000-000000000001',
    'IMAGE',
    NULL,
    'SMS de rappel d''un cabinet dentaire pour un rendez-vous prévu le mardi 19 mars à 14h30, avec consigne d''arriver 10 minutes en avance et possibilité d''annuler 24h avant.',
    '<svg width="100%" viewBox="0 0 680 580" role="img" xmlns="http://www.w3.org/2000/svg"><title>SMS de rappel rendez-vous dentiste</title><desc>SMS rappelant un rendez-vous dentaire le mardi 19 mars à 14h30.</desc><rect x="0" y="0" width="680" height="580" fill="#F5F5F7"/><rect x="170" y="40" width="340" height="520" rx="36" fill="#1A1A1A"/><rect x="180" y="80" width="320" height="480" rx="4" fill="#FFFFFF"/><rect x="280" y="50" width="120" height="22" rx="11" fill="#1A1A1A"/><text x="200" y="104" font-family="Arial, sans-serif" font-size="13" font-weight="600" fill="#0F1839">9:42</text><g transform="translate(440, 92)"><rect x="0" y="0" width="3" height="8" rx="0.5" fill="#0F1839"/><rect x="5" y="-2" width="3" height="10" rx="0.5" fill="#0F1839"/><rect x="10" y="-4" width="3" height="12" rx="0.5" fill="#0F1839"/><rect x="15" y="-6" width="3" height="14" rx="0.5" fill="#0F1839"/></g><rect x="180" y="120" width="320" height="44" fill="#FAFAFA"/><line x1="180" y1="164" x2="500" y2="164" stroke="#E5E5E7" stroke-width="0.5"/><text x="340" y="147" text-anchor="middle" font-family="Arial, sans-serif" font-size="15" font-weight="600" fill="#0F1839">Cabinet Dr Martin</text><g transform="translate(340, 195)"><circle cx="0" cy="0" r="24" fill="#1E3A8C"/><text x="0" y="6" text-anchor="middle" font-family="Arial, sans-serif" font-size="18" font-weight="700" fill="#FFFFFF">+</text></g><text x="340" y="240" text-anchor="middle" font-family="Arial, sans-serif" font-size="13" font-weight="600" fill="#0F1839">Cabinet Dr Martin</text><text x="340" y="256" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" fill="#888888">SMS · Aujourd''hui</text><rect x="200" y="285" width="270" height="200" rx="14" fill="#E8E8ED"/><text x="216" y="310" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Bonjour Mme Petit,</text><text x="216" y="334" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Rappel de votre rendez-vous</text><text x="216" y="352" font-family="Arial, sans-serif" font-size="12" font-weight="700" fill="#1E3A8C">mardi 19 mars à 14h30</text><text x="216" y="370" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">avec le Dr Martin.</text><text x="216" y="396" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Merci d''arriver</text><text x="216" y="414" font-family="Arial, sans-serif" font-size="12" font-weight="700" fill="#0F1839">10 minutes en avance</text><text x="216" y="432" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">pour les formalités.</text><text x="216" y="458" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">Annulation possible jusqu''à</text><text x="216" y="473" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">24h avant : 01 23 45 67 89</text><text x="340" y="510" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" fill="#888888">Hier · 18:32</text></svg>'
),

-- ────────── Media 2 : Affiche promo supermarché ──────────
(
    '33333333-0022-0000-0000-000000000002',
    'IMAGE',
    NULL,
    'Affiche de promotion du supermarché annonçant trois produits en promo cette semaine : tomates à 1,50€/kg, lait 2 euros le pack de 6, pain de mie 1,80 euros au lieu de 2,50 euros.',
    '<svg width="100%" viewBox="0 0 680 600" role="img" xmlns="http://www.w3.org/2000/svg"><title>Affiche promo supermarché</title><desc>Promotion de la semaine au supermarché : tomates, lait et pain de mie en réduction.</desc><rect x="0" y="0" width="680" height="600" fill="#FDECEB"/><rect x="40" y="40" width="600" height="520" fill="#FFFFFF" stroke="#E1372F" stroke-width="3"/><rect x="40" y="40" width="600" height="80" fill="#E1372F"/><text x="340" y="80" text-anchor="middle" font-family="Georgia, serif" font-size="28" font-weight="700" fill="#FFFFFF">SUPER PROMO</text><text x="340" y="105" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" fill="#FFFFFF">Cette semaine au Marché du Coin</text><text x="340" y="160" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#0F1839">Du lundi au samedi</text><g transform="translate(70, 200)"><rect x="0" y="0" width="170" height="180" fill="#E8F5EE" stroke="#168F5B" stroke-width="2"/><g transform="translate(85, 50)"><circle cx="0" cy="0" r="30" fill="#E1372F"/><circle cx="-10" cy="-8" r="3" fill="#FFFFFF" opacity="0.5"/><path d="M -5 -22 L 0 -28 L 5 -22" fill="#168F5B" stroke="#0F1839" stroke-width="1"/></g><text x="85" y="120" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#0F1839">Tomates</text><text x="85" y="138" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" fill="#5C6573">au kilo</text><text x="85" y="166" text-anchor="middle" font-family="Arial, sans-serif" font-size="22" font-weight="700" fill="#E1372F">1,50 €</text></g><g transform="translate(255, 200)"><rect x="0" y="0" width="170" height="180" fill="#E8ECF8" stroke="#1E3A8C" stroke-width="2"/><g transform="translate(85, 50)"><rect x="-25" y="-30" width="50" height="55" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="-25" y="-30" width="50" height="12" fill="#1E3A8C"/><text x="0" y="-20" text-anchor="middle" font-family="Arial, sans-serif" font-size="7" font-weight="700" fill="#FFFFFF">LAIT</text><text x="0" y="-5" text-anchor="middle" font-family="Arial, sans-serif" font-size="8" font-weight="700" fill="#1E3A8C">×6</text></g><text x="85" y="120" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#0F1839">Lait demi-écrémé</text><text x="85" y="138" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" fill="#5C6573">pack de 6 bouteilles</text><text x="85" y="166" text-anchor="middle" font-family="Arial, sans-serif" font-size="22" font-weight="700" fill="#1E3A8C">2,00 €</text></g><g transform="translate(440, 200)"><rect x="0" y="0" width="170" height="180" fill="#FEF5DD" stroke="#A36E0A" stroke-width="2"/><g transform="translate(85, 50)"><rect x="-30" y="-15" width="60" height="35" fill="#E8A317" stroke="#0F1839" stroke-width="1.5"/><rect x="-30" y="-15" width="60" height="6" fill="#A36E0A"/></g><text x="85" y="120" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#0F1839">Pain de mie</text><text x="85" y="138" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" fill="#5C6573">grand format 500g</text><g transform="translate(50, 158)"><text x="0" y="0" font-family="Arial, sans-serif" font-size="13" fill="#888888" text-decoration="line-through">2,50 €</text><text x="36" y="0" font-family="Arial, sans-serif" font-size="22" font-weight="700" fill="#A36E0A">1,80 €</text></g></g><rect x="100" y="420" width="480" height="60" rx="6" fill="#E1372F"/><text x="340" y="448" text-anchor="middle" font-family="Arial, sans-serif" font-size="15" font-weight="700" fill="#FFFFFF">Profitez-en jusqu''au samedi 23 mars</text><text x="340" y="468" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#FFFFFF">Dans la limite des stocks disponibles</text><text x="340" y="520" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-style="italic" fill="#5C6573">Marché du Coin · 5 rue de la Mairie · ouvert 7j/7</text></svg>'
),

-- ────────── Media 3 : Panneau horaires poste ──────────
(
    '33333333-0022-0000-0000-000000000003',
    'IMAGE',
    NULL,
    'Panneau d''horaires d''ouverture d''un bureau de poste : ouvert du lundi au vendredi de 9h à 12h30 et de 14h à 18h, samedi matin de 9h à 12h, fermé le dimanche.',
    '<svg width="100%" viewBox="0 0 680 540" role="img" xmlns="http://www.w3.org/2000/svg"><title>Horaires bureau de poste</title><desc>Panneau d''horaires d''ouverture d''un bureau de poste.</desc><rect x="0" y="0" width="680" height="540" fill="#FEF5DD"/><rect x="60" y="40" width="560" height="460" rx="8" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="3"/><rect x="60" y="40" width="560" height="80" fill="#FFCD00"/><text x="340" y="80" text-anchor="middle" font-family="Georgia, serif" font-size="26" font-weight="700" fill="#1E3A8C">BUREAU DE POSTE</text><text x="340" y="105" text-anchor="middle" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">Place de la République · 75011 Paris</text><text x="340" y="160" text-anchor="middle" font-family="Arial, sans-serif" font-size="15" font-weight="700" fill="#1E3A8C">HORAIRES D''OUVERTURE</text><line x1="240" y1="170" x2="440" y2="170" stroke="#FFCD00" stroke-width="3"/><g transform="translate(120, 200)"><line x1="0" y1="0" x2="440" y2="0" stroke="#0F1839" stroke-width="0.5"/><text x="0" y="32" font-family="Arial, sans-serif" font-size="16" font-weight="600" fill="#0F1839">Lundi — Vendredi</text><text x="240" y="32" font-family="Arial, sans-serif" font-size="15" font-weight="700" fill="#168F5B">9h — 12h30</text><text x="370" y="32" font-family="Arial, sans-serif" font-size="13" fill="#5C6573">et</text><text x="395" y="32" font-family="Arial, sans-serif" font-size="15" font-weight="700" fill="#168F5B">14h — 18h</text><line x1="0" y1="52" x2="440" y2="52" stroke="#0F1839" stroke-width="0.5"/><text x="0" y="86" font-family="Arial, sans-serif" font-size="16" font-weight="600" fill="#0F1839">Samedi</text><text x="240" y="86" font-family="Arial, sans-serif" font-size="15" font-weight="700" fill="#168F5B">9h — 12h</text><text x="350" y="86" font-family="Arial, sans-serif" font-size="11" font-style="italic" fill="#5C6573">(matin uniquement)</text><line x1="0" y1="106" x2="440" y2="106" stroke="#0F1839" stroke-width="0.5"/><text x="0" y="140" font-family="Arial, sans-serif" font-size="16" fill="#7A8794">Dimanche</text><text x="240" y="140" font-family="Arial, sans-serif" font-size="15" font-weight="700" fill="#E1372F">FERMÉ</text><line x1="0" y1="160" x2="440" y2="160" stroke="#0F1839" stroke-width="0.5"/></g><rect x="120" y="400" width="440" height="60" rx="4" fill="#FFCD00"/><text x="340" y="425" text-anchor="middle" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#1E3A8C">JOURS FÉRIÉS : FERMETURE EXCEPTIONNELLE</text><text x="340" y="445" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">Boîte aux lettres extérieure accessible 24h/24</text></svg>'
),

-- ────────── Media 4 : WhatsApp annulation dîner ──────────
(
    '33333333-0022-0000-0000-000000000004',
    'IMAGE',
    NULL,
    'Conversation WhatsApp dans laquelle Julie écrit à son amie pour annuler le dîner du samedi soir car elle est malade, et propose de se voir le week-end suivant.',
    '<svg width="100%" viewBox="0 0 680 760" role="img" xmlns="http://www.w3.org/2000/svg"><title>Conversation WhatsApp annulation dîner</title><desc>Conversation WhatsApp où Julie annule un dîner pour cause de maladie.</desc><rect x="0" y="0" width="680" height="760" fill="#F5F5F7"/><rect x="170" y="40" width="340" height="700" rx="36" fill="#1A1A1A"/><rect x="180" y="80" width="320" height="660" rx="4" fill="#ECE5DD"/><rect x="280" y="50" width="120" height="22" rx="11" fill="#1A1A1A"/><rect x="180" y="80" width="320" height="60" fill="#075E54"/><text x="200" y="105" font-family="Arial, sans-serif" font-size="14" font-weight="600" fill="#FFFFFF">9:42</text><g transform="translate(440, 96)"><rect x="0" y="0" width="3" height="8" rx="0.5" fill="#FFFFFF"/><rect x="5" y="-2" width="3" height="10" rx="0.5" fill="#FFFFFF"/><rect x="10" y="-4" width="3" height="12" rx="0.5" fill="#FFFFFF"/><rect x="15" y="-6" width="3" height="14" rx="0.5" fill="#FFFFFF"/></g><rect x="180" y="140" width="320" height="60" fill="#128C7E"/><g transform="translate(195, 158)"><path d="M 6 0 L 0 8 L 6 16" fill="none" stroke="#FFFFFF" stroke-width="2"/></g><g transform="translate(220, 158)"><circle cx="12" cy="12" r="12" fill="#FFCD00"/><text x="12" y="17" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#0F1839">J</text></g><text x="252" y="174" font-family="Arial, sans-serif" font-size="14" font-weight="600" fill="#FFFFFF">Julie</text><text x="252" y="190" font-family="Arial, sans-serif" font-size="11" fill="#A8E0D8">en ligne</text><g transform="translate(200, 220)"><rect x="0" y="0" width="220" height="60" rx="8" fill="#FFFFFF"/><path d="M 0 8 L -8 0 L 0 0 Z" fill="#FFFFFF"/><text x="14" y="22" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">Salut ma belle ! Toujours OK</text><text x="14" y="38" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">pour samedi soir ? 😊</text><text x="200" y="54" text-anchor="end" font-family="Arial, sans-serif" font-size="9" fill="#888888">10:14</text></g><g transform="translate(260, 295)"><rect x="0" y="0" width="220" height="80" rx="8" fill="#DCF8C6"/><path d="M 220 8 L 228 0 L 220 0 Z" fill="#DCF8C6"/><text x="14" y="22" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">Coucou 😷</text><text x="14" y="40" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">Justement je t''écrivais...</text><text x="14" y="58" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">Je suis malade depuis hier,</text><text x="14" y="74" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">je préfère annuler ce soir.</text><text x="190" y="76" font-family="Arial, sans-serif" font-size="8" fill="#666666">10:31 ✓✓</text></g><g transform="translate(260, 390)"><rect x="0" y="0" width="220" height="60" rx="8" fill="#DCF8C6"/><text x="14" y="22" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">Je suis vraiment désolée 😞</text><text x="14" y="40" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">On peut peut-être se voir</text><text x="14" y="58" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#0F1839">le week-end prochain ?</text><text x="190" y="58" font-family="Arial, sans-serif" font-size="8" fill="#666666">10:32 ✓✓</text></g><g transform="translate(200, 465)"><rect x="0" y="0" width="220" height="40" rx="8" fill="#FFFFFF"/><path d="M 0 8 L -8 0 L 0 0 Z" fill="#FFFFFF"/><text x="14" y="20" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">Oh non ! Soigne-toi bien 💕</text><text x="14" y="35" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">Pas de souci pour samedi prochain</text><text x="200" y="33" text-anchor="end" font-family="Arial, sans-serif" font-size="9" fill="#888888">10:33</text></g><g transform="translate(200, 520)"><rect x="0" y="0" width="200" height="40" rx="8" fill="#FFFFFF"/><text x="14" y="20" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">Je passe à la pharmacie</text><text x="14" y="35" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">si tu as besoin de quelque chose</text></g><rect x="190" y="700" width="290" height="34" rx="17" fill="#FFFFFF" stroke="#D5D5D5" stroke-width="0.5"/><text x="208" y="722" font-family="Arial, sans-serif" font-size="12" fill="#888888">Message</text></svg>'
),

-- ────────── Media 5 : Étiquette boîte de soupe ──────────
(
    '33333333-0022-0000-0000-000000000005',
    'IMAGE',
    NULL,
    'Étiquette d''une boîte de soupe aux légumes : marque Saveurs du Sud, 50 cl, contient des tomates, des carottes et du basilic, sans gluten, à consommer avant le 15 août, prix 2,80 euros.',
    '<svg width="100%" viewBox="0 0 680 540" role="img" xmlns="http://www.w3.org/2000/svg"><title>Étiquette boîte de soupe</title><desc>Étiquette d''une boîte de soupe aux légumes.</desc><rect x="0" y="0" width="680" height="540" fill="#FEF5DD"/><rect x="60" y="40" width="560" height="460" rx="12" fill="#FFFFFF" stroke="#168F5B" stroke-width="3"/><rect x="60" y="40" width="560" height="100" rx="12" fill="#168F5B"/><text x="340" y="80" text-anchor="middle" font-family="Georgia, serif" font-size="26" font-weight="700" fill="#FFFFFF">Saveurs du Sud</text><text x="340" y="108" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" font-style="italic" fill="#E8F5EE">le bon goût des légumes</text><text x="60" y="180" text-anchor="start" font-family="Arial, sans-serif" font-size="12" font-weight="700" fill="#168F5B" transform="translate(20,0)">PRODUIT</text><text x="80" y="220" font-family="Georgia, serif" font-size="28" font-weight="700" fill="#0F1839">Soupe aux légumes</text><text x="80" y="248" font-family="Georgia, serif" font-size="16" font-style="italic" fill="#5C6573">tomates, carottes &amp; basilic</text><text x="80" y="296" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#168F5B">CONTENU : 50 cl</text><text x="80" y="316" font-family="Arial, sans-serif" font-size="11" fill="#5C6573">soit environ 2 personnes</text><rect x="380" y="180" width="220" height="160" rx="8" fill="#E8F5EE"/><text x="490" y="208" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#168F5B">CARACTÉRISTIQUES</text><g transform="translate(400, 226)"><rect x="0" y="0" width="80" height="22" rx="11" fill="#168F5B"/><text x="40" y="15" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#FFFFFF">SANS GLUTEN</text></g><g transform="translate(490, 226)"><rect x="0" y="0" width="100" height="22" rx="11" fill="#1E3A8C"/><text x="50" y="15" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#FFFFFF">100% LÉGUMES</text></g><text x="400" y="280" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">• Sans conservateur</text><text x="400" y="300" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">• Adapté aux végétariens</text><text x="400" y="320" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">• Cultivé en France</text><line x1="80" y1="370" x2="600" y2="370" stroke="#D5D5D5" stroke-width="1"/><text x="80" y="400" font-family="Arial, sans-serif" font-size="12" font-weight="700" fill="#E1372F">⚠ À CONSOMMER AVANT LE 15 AOÛT</text><text x="80" y="420" font-family="Arial, sans-serif" font-size="11" fill="#5C6573">Après ouverture, conserver au frais et consommer dans les 48h</text><rect x="450" y="385" width="140" height="60" rx="6" fill="#168F5B"/><text x="520" y="408" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" fill="#FFFFFF">PRIX</text><text x="520" y="436" text-anchor="middle" font-family="Arial, sans-serif" font-size="22" font-weight="700" fill="#FFFFFF">2,80 €</text><text x="340" y="478" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" font-style="italic" fill="#5C6573">Saveurs du Sud · 14 rue des Oliviers · Aix-en-Provence</text></svg>'
),

-- ────────── Media 6 : Carte invitation anniversaire enfant ──────────
(
    '33333333-0022-0000-0000-000000000006',
    'IMAGE',
    NULL,
    'Carte d''invitation à l''anniversaire d''Emma qui fête ses 7 ans, samedi 6 avril à 15h, au parc des Lilas, avec demande de confirmation avant le 1er avril et précision sur le goûter offert.',
    '<svg width="100%" viewBox="0 0 680 580" role="img" xmlns="http://www.w3.org/2000/svg"><title>Invitation anniversaire enfant</title><desc>Carte d''invitation à l''anniversaire d''Emma, 7 ans.</desc><rect x="0" y="0" width="680" height="580" fill="#FBE7EE"/><rect x="60" y="40" width="560" height="500" rx="16" fill="#FFFFFF" stroke="#D4537E" stroke-width="3"/><g transform="translate(80, 60)"><circle cx="20" cy="20" r="15" fill="#FFCD00" opacity="0.6"/><circle cx="50" cy="40" r="10" fill="#F09595" opacity="0.6"/><circle cx="80" cy="20" r="12" fill="#1D9E75" opacity="0.6"/></g><g transform="translate(520, 60)"><circle cx="20" cy="20" r="15" fill="#85B7EB" opacity="0.6"/><circle cx="50" cy="40" r="10" fill="#F09595" opacity="0.6"/><circle cx="80" cy="20" r="12" fill="#FFCD00" opacity="0.6"/></g><text x="340" y="150" text-anchor="middle" font-family="Georgia, serif" font-size="20" font-style="italic" fill="#993556">Tu es invité(e) à</text><text x="340" y="200" text-anchor="middle" font-family="Georgia, serif" font-size="34" font-weight="700" fill="#D4537E">l''anniversaire d''Emma</text><text x="340" y="240" text-anchor="middle" font-family="Georgia, serif" font-size="18" font-style="italic" fill="#5C6573">qui fête ses 7 ans 🎂</text><rect x="180" y="280" width="320" height="100" rx="8" fill="#FBE7EE" stroke="#D4537E" stroke-width="1"/><text x="340" y="306" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#993556">QUAND ?</text><text x="340" y="332" text-anchor="middle" font-family="Georgia, serif" font-size="18" font-weight="700" fill="#0F1839">Samedi 6 avril, à 15h</text><text x="340" y="358" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#5C6573">de 15h à 18h</text><text x="340" y="420" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#993556">OÙ ?</text><text x="340" y="444" text-anchor="middle" font-family="Georgia, serif" font-size="16" font-weight="700" fill="#0F1839">Parc des Lilas · entrée nord</text><text x="340" y="464" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#5C6573">avenue Camille Pelletan</text><rect x="120" y="486" width="440" height="36" rx="4" fill="#993556"/><text x="340" y="510" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" font-weight="700" fill="#FFFFFF">RSVP avant le 1er avril au 06 78 90 12 34</text></svg>'
)
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- ❓ 3. QUESTIONS IMAGE (12) — CE A2 image
-- ============================================================================
-- Plage UUID : 55555555-0022-0000-...

-- ──────────────────────────────────────────────────────────────────────────
-- 📱 Media 1 : SMS rappel dentiste (Q1-Q2)
-- ──────────────────────────────────────────────────────────────────────────

-- Q1 : détail (date et heure du rendez-vous)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000001', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Quel jour et à quelle heure est le rendez-vous de Mme Petit ?',
    'Le SMS indique en gras « mardi 19 mars à 14h30 ». La réponse C est correcte. La réponse A confond le « 19 mars » avec une autre date. La réponse B est piégeuse : 14h20 est proche de 14h30 (lecture rapide), mais le SMS dit bien 14h30 et précise d''arriver 10 minutes avant (donc à 14h20, mais ce n''est pas l''heure du rendez-vous). La réponse D inverse le jour de la semaine.',
    '33333333-0022-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000001', 'Mardi 9 mars à 14h30',   false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000001', 'Mardi 19 mars à 14h20',  false, 2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000001', 'Mardi 19 mars à 14h30',  true,  3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000001', 'Jeudi 19 mars à 14h30',  false, 4);

-- Q2 : inférence (comment annuler)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000002', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_inference_intention',
    'Comment Mme Petit peut-elle annuler son rendez-vous ?',
    'Le SMS dit : « Annulation possible jusqu''à 24h avant : 01 23 45 67 89 ». Il faut donc appeler au moins un jour avant. La réponse B reformule cette information. La réponse A est piégeuse : 10 minutes avant est cité, mais c''est pour arriver en avance, pas pour annuler. La réponse C invente une option (SMS) non mentionnée. La réponse D est trop tranchée : l''annulation est possible, à condition de respecter le délai.',
    '33333333-0022-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000002', 'En appelant 10 minutes avant le rendez-vous',                  false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000002', 'En appelant au moins 24 heures avant le rendez-vous',          true,  2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000002', 'En envoyant un SMS au cabinet',                                false, 3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000002', 'Elle ne peut pas annuler ce rendez-vous',                       false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 🛒 Media 2 : Affiche promo supermarché (Q3-Q4)
-- ──────────────────────────────────────────────────────────────────────────

-- Q3 : détail (prix d'un produit)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000003', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Combien coûte le pain de mie en promotion ?',
    'L''affiche montre le pain de mie à 1,80 € (l''ancien prix de 2,50 € est barré). La réponse B est correcte. La réponse A reprend l''ancien prix barré : c''est le prix avant promo, pas le prix actuel. La réponse C donne le prix du lait, pas du pain de mie. La réponse D donne le prix des tomates.',
    '33333333-0022-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000003', '2,50 €',  false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000003', '1,80 €',  true,  2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000003', '2,00 €',  false, 3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000003', '1,50 €',  false, 4);

-- Q4 : repérage (durée de la promotion)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000004', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_reperage_explicite',
    'Jusqu''à quand peut-on profiter de ces promotions ?',
    'L''affiche indique « Profitez-en jusqu''au samedi 23 mars ». La réponse C est correcte. La réponse A est piégeuse : le supermarché est ouvert 7j/7 (mention en bas), mais la promo s''arrête le samedi 23. La réponse B est piégeuse : du lundi au samedi est le créneau d''ouverture cité en haut, mais ce n''est pas la fin de la promo. La réponse D invente une date proche mais incorrecte.',
    '33333333-0022-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000004', 'Toute l''année',                              false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000004', 'Du lundi au samedi seulement',                false, 2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000004', 'Jusqu''au samedi 23 mars',                     true,  3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000004', 'Jusqu''au dimanche 24 mars',                   false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📮 Media 3 : Horaires bureau de poste (Q5-Q6)
-- ──────────────────────────────────────────────────────────────────────────

-- Q5 : repérage (ouverture le samedi)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000005', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_reperage_explicite',
    'Le bureau de poste est-il ouvert le samedi après-midi ?',
    'Le panneau précise pour le samedi : « 9h — 12h (matin uniquement) ». L''après-midi est donc fermé. La réponse A reformule cette information. La réponse B est piégeuse : ces horaires (9h-12h30 et 14h-18h) concernent uniquement le lundi-vendredi. La réponse C inverse la règle : le matin est ouvert, mais c''est l''après-midi qui ne l''est pas. La réponse D est piégeuse : la mention « jours fériés » concerne une fermeture exceptionnelle, mais pas la règle générale du samedi.',
    '33333333-0022-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000005', 'Non, le samedi il est ouvert uniquement le matin',                          true,  1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000005', 'Oui, de 9h à 12h30 puis de 14h à 18h',                                       false, 2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000005', 'Oui, mais le matin il est fermé',                                            false, 3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000005', 'Cela dépend des jours fériés',                                                false, 4);

-- Q6 : détail (boîte aux lettres)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000006', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Peut-on déposer une lettre le dimanche ?',
    'Le panneau indique en bas : « Boîte aux lettres extérieure accessible 24h/24 ». On peut donc déposer une lettre le dimanche dans la boîte extérieure, même si le bureau est fermé. La réponse C reformule cette information. La réponse A est trop tranchée : le bureau est fermé, mais pas la boîte aux lettres. La réponse B invente une condition (ticket) non mentionnée. La réponse D mélange deux infos : le dimanche est fermé toute la journée, pas seulement l''après-midi.',
    '33333333-0022-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000006', 'Non, le bureau est fermé toute la journée',                                  false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000006', 'Oui, à condition d''avoir un ticket prépayé',                                 false, 2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000006', 'Oui, dans la boîte aux lettres extérieure',                                   true,  3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000006', 'Oui, mais seulement le matin',                                                false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 💬 Media 4 : WhatsApp annulation dîner (Q7-Q8)
-- ──────────────────────────────────────────────────────────────────────────

-- Q7 : reformulation (pourquoi Julie annule)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000007', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_reformulation',
    'Pourquoi Julie annule-t-elle le dîner ?',
    'Julie écrit : « Je suis malade depuis hier, je préfère annuler ce soir. ». La raison est donc une maladie. La réponse C reformule cette information. La réponse A invente une raison non mentionnée. La réponse B est piégeuse : Julie propose un autre week-end, mais ce n''est pas la raison de l''annulation. La réponse D est piégeuse : Julie va à la pharmacie (pour elle), mais ce n''est pas la raison principale.',
    '33333333-0022-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000007', 'Elle a un imprévu de travail',                              false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000007', 'Elle préfère se voir le week-end prochain',                 false, 2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000007', 'Elle est malade',                                            true,  3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000007', 'Elle doit aller à la pharmacie',                              false, 4);

-- Q8 : inférence (proposition de Julie)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000008', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_inference_intention',
    'Que propose Julie à son amie ?',
    'Julie écrit : « On peut peut-être se voir le week-end prochain ? ». Elle propose donc de reporter d''une semaine. La réponse C reformule cette proposition. La réponse A est une généralisation trop forte : Julie n''annule pas définitivement, elle propose une nouvelle date. La réponse B est piégeuse : c''est l''amie qui parle de pharmacie à la fin, pas Julie comme proposition. La réponse D inverse le sens : Julie ne demande pas d''aller voir un médecin.',
    '33333333-0022-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000008', 'D''annuler définitivement leur sortie',                                          false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000008', 'De passer à la pharmacie pour elle',                                              false, 2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000008', 'De reporter leur dîner au week-end suivant',                                       true,  3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000008', 'D''aller voir un médecin ensemble',                                                false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 🥫 Media 5 : Étiquette boîte de soupe (Q9-Q10)
-- ──────────────────────────────────────────────────────────────────────────

-- Q9 : détail (date limite)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000009', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Avant quelle date faut-il consommer cette soupe ?',
    'L''étiquette indique en rouge : « À CONSOMMER AVANT LE 15 AOÛT ». La réponse B est correcte. La réponse A est piégeuse : 48h est cité, mais c''est pour conserver le produit APRÈS ouverture, pas la date limite de consommation. La réponse C est trop vague et inexacte (la date est précise). La réponse D inverse les mois.',
    '33333333-0022-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000009', 'Dans les 48 heures après ouverture',     false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000009', 'Avant le 15 août',                        true,  2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000009', 'Avant la fin de l''année',                 false, 3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000009', 'Avant le 15 avril',                        false, 4);

-- Q10 : repérage (caractéristique du produit)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000010', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_reperage_explicite',
    'Cette soupe convient-elle à une personne intolérante au gluten ?',
    'L''étiquette comporte un badge vert clair indiquant « SANS GLUTEN ». La réponse B est correcte. La réponse A est piégeuse : la soupe est sans conservateur (cité dans les caractéristiques), mais cela ne concerne pas le gluten. La réponse C inverse l''information : la soupe est précisément sans gluten. La réponse D est piégeuse : la soupe est végétarienne, mais ça ne répond pas à la question sur le gluten.',
    '33333333-0022-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000010', 'Oui, elle est sans conservateur',                              false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000010', 'Oui, elle est indiquée sans gluten',                            true,  2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000010', 'Non, elle contient du gluten',                                  false, 3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000010', 'Non, mais elle est végétarienne',                                false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 🎂 Media 6 : Invitation anniversaire Emma (Q11-Q12)
-- ──────────────────────────────────────────────────────────────────────────

-- Q11 : détail (date et heure)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000011', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Quand a lieu l''anniversaire d''Emma ?',
    'La carte indique « Samedi 6 avril, à 15h » et précise « de 15h à 18h ». La réponse C reformule fidèlement. La réponse A est piégeuse : le 1er avril est cité, mais c''est la date limite pour répondre, pas la date de la fête. La réponse B inverse l''horaire (la fête commence à 15h, pas à 18h). La réponse D est piégeuse : 7 ans est l''âge d''Emma, ce n''est pas un jour.',
    '33333333-0022-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000011', 'Le 1er avril à 15h',                false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000011', 'Le 6 avril à 18h',                   false, 2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000011', 'Le samedi 6 avril à 15h',             true,  3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000011', 'Le samedi 7 avril à 15h',             false, 4);

-- Q12 : repérage (que faut-il faire avant le 1er avril)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000012', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_reperage_explicite',
    'Que faut-il faire avant le 1er avril ?',
    'La bandeau rouge en bas indique : « RSVP avant le 1er avril au 06 78 90 12 34 ». RSVP signifie « répondre s''il vous plaît » : il faut donc confirmer sa présence. La réponse B reformule cette information. La réponse A est piégeuse : on doit répondre au numéro de téléphone, ce n''est pas l''objet du RSVP. La réponse C est piégeuse : le 6 avril est la date de la fête, pas une démarche à faire avant. La réponse D invente un cadeau jamais mentionné.',
    '33333333-0022-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000012', 'Appeler le 06 78 90 12 34 pour des informations',                            false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000012', 'Confirmer sa présence à la fête',                                              true,  2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000012', 'Aller au parc des Lilas',                                                      false, 3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000012', 'Acheter un cadeau pour Emma',                                                  false, 4);


-- ============================================================================
-- ❓ 4. QUESTIONS TEXTE (12) — CE A2 texte
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 1 : Livraison colis (Q13-Q14)
-- ──────────────────────────────────────────────────────────────────────────

-- Q13 : détail (jour de livraison)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000013', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Quand le colis de Mme Garcia sera-t-il livré ?',
    'Le SMS indique : « Votre colis sera livré demain mercredi ». La réponse B est correcte. La réponse A est piégeuse : « ce soir 18h » est cité comme heure limite pour répondre au SMS, pas pour la livraison. La réponse C est piégeuse : les créneaux du soir vont jusqu''à 20h, mais ce sont des plages de livraison du mercredi, pas le jour. La réponse D invente un jour non mentionné.',
    '44444444-0022-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000013', 'Aujourd''hui à 18h',                false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000013', 'Demain, mercredi',                   true,  2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000013', 'Demain entre 17h et 20h',            false, 3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000013', 'Jeudi prochain',                      false, 4);

-- Q14 : repérage (que doit faire Mme Garcia)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000014', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_reperage_explicite',
    'Que doit faire Mme Garcia avant ce soir 18h ?',
    'Le SMS dit : « Répondez à ce message avec votre choix avant ce soir 18h ». Elle doit donc choisir un créneau et l''indiquer en réponse. La réponse B reformule cette demande. La réponse A est piégeuse : être à la maison est nécessaire pour la livraison demain, mais pas avant 18h ce soir. La réponse C inverse l''ordre : on ne paie pas avant la livraison dans ce SMS. La réponse D invente un appel au service alors que le SMS demande de répondre au message.',
    '44444444-0022-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000014', 'Être à la maison',                                            false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000014', 'Choisir un créneau de livraison et répondre au SMS',           true,  2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000014', 'Payer le colis',                                                false, 3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000014', 'Appeler le service de livraison',                                false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 2 : Mémo garde d'enfants (Q15-Q16)
-- ──────────────────────────────────────────────────────────────────────────

-- Q15 : détail (heure du coucher)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000015', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'À quelle heure Tom doit-il aller au lit ?',
    'Le mémo dit : « Tom doit aller au lit à 20h30, pas plus tard ». La réponse C est correcte. La réponse A inverse une heure proche mais incorrecte. La réponse B est piégeuse : 2 minutes est cité, mais c''est pour réchauffer les pâtes, pas pour l''heure du coucher. La réponse D est trop tardive et contredit explicitement « pas plus tard ».',
    '44444444-0022-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000015', 'À 20h00',                                          false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000015', 'À 21h30, après le dessin animé',                    false, 2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000015', 'À 20h30 au plus tard',                              true,  3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000015', 'À 22h00',                                          false, 4);

-- Q16 : repérage (où trouver le numéro de Sophie)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000016', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_reperage_explicite',
    'Où Léa peut-elle trouver le numéro de Sophie en cas de problème ?',
    'Le mémo dit : « mon numéro est sur la porte du frigo ». La réponse C est correcte. La réponse A est piégeuse : le frigo contient les pâtes (cité juste avant), mais le numéro est SUR la porte, pas dans le frigo. La réponse B confond avec la position du repas. La réponse D invente le téléphone alors que le numéro est affiché.',
    '44444444-0022-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000016', 'Dans le frigo, avec les pâtes',                              false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000016', 'Sur la table de la cuisine',                                  false, 2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000016', 'Sur la porte du frigo',                                        true,  3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000016', 'Sur le téléphone fixe de la maison',                            false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 3 : Chambre étudiante (Q17-Q18)
-- ──────────────────────────────────────────────────────────────────────────

-- Q17 : détail (loyer)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000017', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Combien coûte cette chambre par mois ?',
    'L''annonce indique : « Loyer : 380 € par mois, charges comprises ». La réponse B est correcte. La réponse A confond avec la surface (15 m²). La réponse C est piégeuse : 9 est le nombre de mois minimum du bail, pas un prix. La réponse D mélange deux chiffres en ajoutant un prix imaginaire pour les charges.',
    '44444444-0022-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000017', '150 € par mois',                                  false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000017', '380 € par mois, charges comprises',                true,  2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000017', '90 € par mois',                                    false, 3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000017', '380 € plus 50 € de charges',                        false, 4);

-- Q18 : repérage (comment contacter Marie)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000018', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_reperage_explicite',
    'Comment faut-il contacter Marie pour la chambre ?',
    'L''annonce précise : « Contact : Marie au 06 12 34 56 78 (préférer les SMS) ». Marie préfère donc les SMS. La réponse C est correcte. La réponse A est piégeuse : le numéro est bien le sien, mais elle préfère les SMS aux appels. La réponse B invente un mail non mentionné. La réponse D invente une visite directe non proposée.',
    '44444444-0022-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000018', 'En l''appelant directement au téléphone',                        false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000018', 'En lui envoyant un mail',                                        false, 2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000018', 'En lui envoyant un SMS',                                          true,  3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000018', 'En venant directement à l''appartement',                          false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 4 : Mot d'absence enseignant (Q19-Q20)
-- ──────────────────────────────────────────────────────────────────────────

-- Q19 : détail (que doivent faire les élèves)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000019', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Que doivent faire les élèves pendant le cours annulé du jeudi ?',
    'Le mot indique : « vous avez deux exercices à faire dans le cahier rouge : pages 42 et 43 ». La réponse C reformule cette consigne. La réponse A est piégeuse : le cours est annulé, donc rien à faire à 10h. La réponse B inverse les pages : 42 et 43 (pas 24 et 34). La réponse D introduit une confusion : le cours de vendredi a lieu normalement, pas de préparation spéciale demandée.',
    '44444444-0022-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000019', 'Venir en classe à 10h comme d''habitude',                          false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000019', 'Faire les exercices pages 24 et 34 du cahier rouge',               false, 2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000019', 'Faire les exercices pages 42 et 43 du cahier rouge',                true,  3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000019', 'Préparer le cours du vendredi 15 mars',                              false, 4);

-- Q20 : repérage (date de rendu)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000020', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_reperage_explicite',
    'Quand les exercices doivent-ils être rendus ?',
    'Le mot dit : « À rendre lundi prochain ». La réponse C est correcte. La réponse A est piégeuse : le 14 mars est la date d''absence, pas la date de rendu. La réponse B est piégeuse : le vendredi 15 mars est cité (cours de vendredi), mais ce n''est pas la date de rendu. La réponse D est trop éloigné et non mentionné.',
    '44444444-0022-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000020', 'Jeudi 14 mars',                          false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000020', 'Vendredi 15 mars',                        false, 2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000020', 'Lundi prochain',                          true,  3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000020', 'À la fin du mois',                        false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 5 : Annonce chat perdu (Q21-Q22)
-- ──────────────────────────────────────────────────────────────────────────

-- Q21 : reformulation (description du chat)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000021', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_reformulation',
    'À quoi ressemble Mistigri ?',
    'L''annonce décrit Mistigri comme « un chat noir et blanc, avec un collier rouge. Il est très peureux ». La réponse C reformule fidèlement ces 3 éléments. La réponse A inverse les couleurs (collier noir au lieu de rouge). La réponse B est piégeuse : « Mistigri » est le nom, mais ce n''est pas une description physique. La réponse D inverse le tempérament (peureux ≠ agressif).',
    '44444444-0022-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000021', 'Un chat noir et blanc avec un collier noir',                              false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000021', 'Un chat appelé Mistigri',                                                false, 2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000021', 'Un chat noir et blanc, peureux, avec un collier rouge',                    true,  3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000021', 'Un chat noir et blanc, agressif',                                          false, 4);

-- Q22 : détail (récompense)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000022', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Que reçoit la personne qui retrouve le chat ?',
    'L''annonce dit : « Récompense de 50 € promise ». La réponse C est correcte. La réponse A est piégeuse : 12 est le numéro de l''appartement, pas un montant. La réponse B est piégeuse : la famille (citée à la fin) ne propose pas un repas, mais 50 €. La réponse D inverse la nature de la récompense (argent ≠ chat).',
    '44444444-0022-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000022', '12 € en récompense',                                    false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000022', 'Un repas chez la famille Dubois',                         false, 2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000022', '50 € en récompense',                                      true,  3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000022', 'Un chaton de la même famille',                            false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 6 : SMS confirmation natation (Q23-Q24)
-- ──────────────────────────────────────────────────────────────────────────

-- Q23 : détail (jour et heure du cours)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000023', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Quand Karim aura-t-il son cours de natation ?',
    'Le SMS dit : « cours de natation du mardi soir, de 19h à 20h ». La réponse C combine correctement le jour et l''heure. La réponse A est piégeuse : le club est ouvert de 17h à 22h, mais 17h n''est pas l''heure du cours. La réponse B inverse le jour (le mercredi n''est pas mentionné). La réponse D est piégeuse : 15 minutes avant le cours est cité, mais c''est pour arriver en avance, pas l''heure du cours.',
    '44444444-0022-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000023', 'Le mardi soir à 17h',                                          false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000023', 'Le mercredi soir de 19h à 20h',                                 false, 2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000023', 'Le mardi soir de 19h à 20h',                                     true,  3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000023', 'Le mardi soir à 18h45',                                          false, 4);

-- Q24 : repérage (ce qu'il faut apporter)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0022-0000-0000-000000000024', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_reperage_explicite',
    'Que doit apporter Karim au premier cours ?',
    'Le SMS précise : « Apportez votre maillot de bain, un bonnet et une serviette ». La réponse C liste ces trois éléments. La réponse A est piégeuse : elle oublie le maillot de bain (élément essentiel). La réponse B invente des lunettes non mentionnées et omet le bonnet. La réponse D mélange : le club est ouvert mais ne fournit pas le matériel, c''est au contraire à Karim de tout apporter.',
    '44444444-0022-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000024', 'Un bonnet et une serviette uniquement',                                   false, 1),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000024', 'Un maillot, des lunettes et une serviette',                                false, 2),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000024', 'Un maillot de bain, un bonnet et une serviette',                            true,  3),
    (gen_random_uuid(), '55555555-0022-0000-0000-000000000024', 'Rien, le matériel est fourni par le club',                                  false, 4);
