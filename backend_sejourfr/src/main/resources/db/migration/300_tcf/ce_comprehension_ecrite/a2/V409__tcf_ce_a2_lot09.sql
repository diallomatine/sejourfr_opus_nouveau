-- ============================================================================
-- V409 — TCF CE A2 — lot 09 (support : carte postale)
-- ----------------------------------------------------------------------------
-- 10 items CE A2, theme 22222222-0000-0000-0000-000000000002.
-- Chaque item = une carte postale originale (SVG style « document » : message
-- à gauche, timbre + adresse à droite) + 1 question sur UNE information
-- explicite + 4 choix (1 correct).
-- UUID déterministes : questions 11111111-a009-1000-…, medias 11111111-a009-5000-…,
-- choices 11111111-a009-2100/2200/2300/2400-… (display_order 1..4).
-- ============================================================================


-- medias (IMAGE) — cartes postales référencées par les questions ci-dessous
INSERT INTO medias
  (id, type, url, storage_key, original_filename, content_type, size_bytes, duration_sec,
   alt_text, created_at, transcript, inline_svg)
VALUES
  ('11111111-a009-5000-0000-000000000001', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Carte postale envoyée de Nice le 12 juillet par Olena à Camille Robert à Dijon : il fait très beau, elle se baigne tous les matins à la plage et elle rentre samedi par le train de 17h.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Carte postale de Nice envoyée par Olena</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="12" y="12" width="296" height="176" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><line x1="196" y1="26" x2="196" y2="174" stroke="#E8ECF8" stroke-width="2"/><rect x="258" y="24" width="36" height="30" rx="2" fill="#E8A317"/><rect x="263" y="29" width="26" height="20" fill="none" stroke="#FFFFFF" stroke-width="1"/><circle cx="248" cy="42" r="11" fill="none" stroke="#1E3A8C" stroke-width="1" stroke-dasharray="3 2"/><text x="204" y="74" font-family="Arial" font-size="8" fill="#1E3A8C" letter-spacing="2">CARTE POSTALE</text><text x="204" y="112" font-family="Arial" font-size="10" fill="#0F1839">Camille Robert</text><text x="204" y="128" font-family="Arial" font-size="10" fill="#0F1839">8 rue des Acacias</text><text x="204" y="144" font-family="Arial" font-size="10" fill="#0F1839">21000 Dijon</text><text x="24" y="34" font-family="Arial" font-size="10" font-style="italic" fill="#1E3A8C">Nice, le 12 juillet</text><text x="24" y="56" font-family="Arial" font-size="10" fill="#0F1839">Chère Camille,</text><text x="24" y="72" font-family="Arial" font-size="10" fill="#0F1839">Il fait très beau à Nice.</text><text x="24" y="88" font-family="Arial" font-size="10" fill="#0F1839">Je me baigne tous les matins</text><text x="24" y="104" font-family="Arial" font-size="10" fill="#0F1839">à la plage.</text><text x="24" y="120" font-family="Arial" font-size="10" fill="#0F1839">Je rentre samedi par le</text><text x="24" y="136" font-family="Arial" font-size="10" font-weight="700" fill="#168F5B">train de 17h.</text><text x="24" y="156" font-family="Arial" font-size="10" font-style="italic" fill="#0F1839">Bisous, Olena</text></svg>'),

  ('11111111-a009-5000-0000-000000000002', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Carte postale envoyée d''Annecy le 8 août par Amadou à Issa Diallo à Paris : le lac d''Annecy est magnifique, hier il a fait une randonnée en montagne, il rentre le 14 août.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Carte postale d''Annecy envoyée par Amadou</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="12" y="12" width="296" height="176" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><line x1="196" y1="26" x2="196" y2="174" stroke="#E8ECF8" stroke-width="2"/><rect x="258" y="24" width="36" height="30" rx="2" fill="#168F5B"/><rect x="263" y="29" width="26" height="20" fill="none" stroke="#FFFFFF" stroke-width="1"/><circle cx="248" cy="42" r="11" fill="none" stroke="#1E3A8C" stroke-width="1" stroke-dasharray="3 2"/><text x="204" y="74" font-family="Arial" font-size="8" fill="#1E3A8C" letter-spacing="2">CARTE POSTALE</text><text x="204" y="112" font-family="Arial" font-size="10" fill="#0F1839">Issa Diallo</text><text x="204" y="128" font-family="Arial" font-size="10" fill="#0F1839">25 avenue des Ternes</text><text x="204" y="144" font-family="Arial" font-size="10" fill="#0F1839">75017 Paris</text><text x="24" y="34" font-family="Arial" font-size="10" font-style="italic" fill="#1E3A8C">Annecy, le 8 août</text><text x="24" y="56" font-family="Arial" font-size="10" fill="#0F1839">Salut Issa,</text><text x="24" y="72" font-family="Arial" font-size="10" fill="#0F1839">Le lac d''Annecy est</text><text x="24" y="88" font-family="Arial" font-size="10" fill="#0F1839">magnifique. Hier, j''ai fait</text><text x="24" y="104" font-family="Arial" font-size="10" font-weight="700" fill="#168F5B">une randonnée en montagne.</text><text x="24" y="120" font-family="Arial" font-size="10" fill="#0F1839">Je rentre le 14 août.</text><text x="24" y="140" font-family="Arial" font-size="10" font-style="italic" fill="#0F1839">À bientôt, Amadou</text></svg>'),

  ('11111111-a009-5000-0000-000000000003', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Carte postale envoyée de Saint-Malo le 25 juillet par Lucia à Nora Benali à Lyon : elle passe une semaine chez sa tante et invite Nora à venir fêter son anniversaire le 3 août chez elle.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Carte postale de Saint-Malo envoyée par Lucia</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="12" y="12" width="296" height="176" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><line x1="196" y1="26" x2="196" y2="174" stroke="#E8ECF8" stroke-width="2"/><rect x="258" y="24" width="36" height="30" rx="2" fill="#1E3A8C"/><rect x="263" y="29" width="26" height="20" fill="none" stroke="#FFFFFF" stroke-width="1"/><circle cx="248" cy="42" r="11" fill="none" stroke="#1E3A8C" stroke-width="1" stroke-dasharray="3 2"/><text x="204" y="74" font-family="Arial" font-size="8" fill="#1E3A8C" letter-spacing="2">CARTE POSTALE</text><text x="204" y="112" font-family="Arial" font-size="10" fill="#0F1839">Nora Benali</text><text x="204" y="128" font-family="Arial" font-size="10" fill="#0F1839">4 rue de la Soie</text><text x="204" y="144" font-family="Arial" font-size="10" fill="#0F1839">69003 Lyon</text><text x="24" y="34" font-family="Arial" font-size="10" font-style="italic" fill="#1E3A8C">Saint-Malo, le 25 juillet</text><text x="24" y="56" font-family="Arial" font-size="10" fill="#0F1839">Chère Nora,</text><text x="24" y="72" font-family="Arial" font-size="10" fill="#0F1839">Je passe une semaine chez</text><text x="24" y="88" font-family="Arial" font-size="10" fill="#0F1839">ma tante à Saint-Malo.</text><text x="24" y="104" font-family="Arial" font-size="10" font-weight="700" fill="#1E3A8C">Viens fêter mon anniversaire</text><text x="24" y="120" font-family="Arial" font-size="10" font-weight="700" fill="#1E3A8C">le 3 août chez moi !</text><text x="24" y="140" font-family="Arial" font-size="10" font-style="italic" fill="#0F1839">Réponds-moi vite. Lucia</text></svg>'),

  ('11111111-a009-5000-0000-000000000004', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Carte postale envoyée de Strasbourg le 9 décembre par Wei à Léa Fontaine à Bordeaux : le marché de Noël est superbe, il a acheté des cadeaux pour toute la famille et il rentre dimanche soir vers 21h.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Carte postale de Strasbourg envoyée par Wei</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="12" y="12" width="296" height="176" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><line x1="196" y1="26" x2="196" y2="174" stroke="#E8ECF8" stroke-width="2"/><rect x="258" y="24" width="36" height="30" rx="2" fill="#E8A317"/><rect x="263" y="29" width="26" height="20" fill="none" stroke="#FFFFFF" stroke-width="1"/><circle cx="248" cy="42" r="11" fill="none" stroke="#1E3A8C" stroke-width="1" stroke-dasharray="3 2"/><text x="204" y="74" font-family="Arial" font-size="8" fill="#1E3A8C" letter-spacing="2">CARTE POSTALE</text><text x="204" y="112" font-family="Arial" font-size="10" fill="#0F1839">Léa Fontaine</text><text x="204" y="128" font-family="Arial" font-size="10" fill="#0F1839">12 cours Pasteur</text><text x="204" y="144" font-family="Arial" font-size="10" fill="#0F1839">33000 Bordeaux</text><text x="24" y="34" font-family="Arial" font-size="10" font-style="italic" fill="#1E3A8C">Strasbourg, le 9 décembre</text><text x="24" y="56" font-family="Arial" font-size="10" fill="#0F1839">Salut Léa,</text><text x="24" y="72" font-family="Arial" font-size="10" fill="#0F1839">Le marché de Noël est</text><text x="24" y="88" font-family="Arial" font-size="10" fill="#0F1839">superbe. J''ai acheté des</text><text x="24" y="104" font-family="Arial" font-size="10" fill="#0F1839">cadeaux pour toute la famille.</text><text x="24" y="120" font-family="Arial" font-size="10" fill="#0F1839">Je rentre</text><text x="24" y="136" font-family="Arial" font-size="10" font-weight="700" fill="#168F5B">dimanche soir, vers 21h.</text><text x="24" y="156" font-family="Arial" font-size="10" font-style="italic" fill="#0F1839">Wei</text></svg>'),

  ('11111111-a009-5000-0000-000000000005', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Carte postale envoyée de La Rochelle le 19 juillet par Rachid à ses parents M. et Mme Haddad à Tours : le camping est agréable et près de la mer, les enfants font du vélo tous les jours, la famille reste encore deux semaines.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Carte postale de La Rochelle envoyée par Rachid</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="12" y="12" width="296" height="176" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><line x1="196" y1="26" x2="196" y2="174" stroke="#E8ECF8" stroke-width="2"/><rect x="258" y="24" width="36" height="30" rx="2" fill="#168F5B"/><rect x="263" y="29" width="26" height="20" fill="none" stroke="#FFFFFF" stroke-width="1"/><circle cx="248" cy="42" r="11" fill="none" stroke="#1E3A8C" stroke-width="1" stroke-dasharray="3 2"/><text x="204" y="74" font-family="Arial" font-size="8" fill="#1E3A8C" letter-spacing="2">CARTE POSTALE</text><text x="204" y="112" font-family="Arial" font-size="10" fill="#0F1839">M. et Mme Haddad</text><text x="204" y="128" font-family="Arial" font-size="10" fill="#0F1839">9 rue des Halles</text><text x="204" y="144" font-family="Arial" font-size="10" fill="#0F1839">37000 Tours</text><text x="24" y="34" font-family="Arial" font-size="10" font-style="italic" fill="#1E3A8C">La Rochelle, le 19 juillet</text><text x="24" y="56" font-family="Arial" font-size="10" fill="#0F1839">Chers parents,</text><text x="24" y="72" font-family="Arial" font-size="10" fill="#0F1839">Le camping est très agréable</text><text x="24" y="88" font-family="Arial" font-size="10" fill="#0F1839">et près de la mer.</text><text x="24" y="104" font-family="Arial" font-size="10" font-weight="700" fill="#168F5B">Les enfants font du vélo</text><text x="24" y="120" font-family="Arial" font-size="10" font-weight="700" fill="#168F5B">tous les jours.</text><text x="24" y="136" font-family="Arial" font-size="10" fill="#0F1839">Nous restons encore deux</text><text x="24" y="152" font-family="Arial" font-size="10" fill="#0F1839">semaines.</text><text x="24" y="170" font-family="Arial" font-size="10" font-style="italic" fill="#0F1839">Je vous embrasse, Rachid</text></svg>'),

  ('11111111-a009-5000-0000-000000000006', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Carte postale envoyée de Paris le 4 mai par Priya à madame Garnier à Angers : Paris est magnifique mais il pleut beaucoup ; Priya demande à sa voisine d''arroser ses plantes mardi.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Carte postale de Paris envoyée par Priya</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="12" y="12" width="296" height="176" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><line x1="196" y1="26" x2="196" y2="174" stroke="#E8ECF8" stroke-width="2"/><rect x="258" y="24" width="36" height="30" rx="2" fill="#1E3A8C"/><rect x="263" y="29" width="26" height="20" fill="none" stroke="#FFFFFF" stroke-width="1"/><circle cx="248" cy="42" r="11" fill="none" stroke="#1E3A8C" stroke-width="1" stroke-dasharray="3 2"/><text x="204" y="74" font-family="Arial" font-size="8" fill="#1E3A8C" letter-spacing="2">CARTE POSTALE</text><text x="204" y="112" font-family="Arial" font-size="10" fill="#0F1839">Mme Garnier</text><text x="204" y="128" font-family="Arial" font-size="10" fill="#0F1839">3 impasse du Moulin</text><text x="204" y="144" font-family="Arial" font-size="10" fill="#0F1839">49000 Angers</text><text x="24" y="34" font-family="Arial" font-size="10" font-style="italic" fill="#1E3A8C">Paris, le 4 mai</text><text x="24" y="56" font-family="Arial" font-size="10" fill="#0F1839">Chère madame Garnier,</text><text x="24" y="72" font-family="Arial" font-size="10" fill="#0F1839">Paris est magnifique mais</text><text x="24" y="88" font-family="Arial" font-size="10" fill="#0F1839">il pleut beaucoup.</text><text x="24" y="104" font-family="Arial" font-size="10" font-weight="700" fill="#1E3A8C">Pouvez-vous arroser mes</text><text x="24" y="120" font-family="Arial" font-size="10" font-weight="700" fill="#1E3A8C">plantes mardi ?</text><text x="24" y="140" font-family="Arial" font-size="10" font-style="italic" fill="#0F1839">Merci beaucoup ! Priya</text></svg>'),

  ('11111111-a009-5000-0000-000000000007', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Carte postale envoyée de Biarritz le 11 août par Diego à Karim Ziani à Lille : il prend des cours de surf tous les après-midis, son hôtel est juste en face de la plage, il rentre le 20 août en avion.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Carte postale de Biarritz envoyée par Diego</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="12" y="12" width="296" height="176" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><line x1="196" y1="26" x2="196" y2="174" stroke="#E8ECF8" stroke-width="2"/><rect x="258" y="24" width="36" height="30" rx="2" fill="#E8A317"/><rect x="263" y="29" width="26" height="20" fill="none" stroke="#FFFFFF" stroke-width="1"/><circle cx="248" cy="42" r="11" fill="none" stroke="#1E3A8C" stroke-width="1" stroke-dasharray="3 2"/><text x="204" y="74" font-family="Arial" font-size="8" fill="#1E3A8C" letter-spacing="2">CARTE POSTALE</text><text x="204" y="112" font-family="Arial" font-size="10" fill="#0F1839">Karim Ziani</text><text x="204" y="128" font-family="Arial" font-size="10" fill="#0F1839">18 rue Nationale</text><text x="204" y="144" font-family="Arial" font-size="10" fill="#0F1839">59000 Lille</text><text x="24" y="34" font-family="Arial" font-size="10" font-style="italic" fill="#1E3A8C">Biarritz, le 11 août</text><text x="24" y="56" font-family="Arial" font-size="10" fill="#0F1839">Salut Karim,</text><text x="24" y="72" font-family="Arial" font-size="10" font-weight="700" fill="#168F5B">Je prends des cours de surf</text><text x="24" y="88" font-family="Arial" font-size="10" fill="#0F1839">tous les après-midis.</text><text x="24" y="104" font-family="Arial" font-size="10" fill="#0F1839">L''hôtel est juste en face</text><text x="24" y="120" font-family="Arial" font-size="10" fill="#0F1839">de la plage. Je rentre le</text><text x="24" y="136" font-family="Arial" font-size="10" fill="#0F1839">20 août en avion.</text><text x="24" y="156" font-family="Arial" font-size="10" font-style="italic" fill="#0F1839">Diego</text></svg>'),

  ('11111111-a009-5000-0000-000000000008', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Carte postale envoyée de Chamonix le 16 février par Fatou à Awa Sow à Rouen : la montagne est splendide avec beaucoup de neige ; Fatou demande à Awa de venir la chercher à la gare vendredi à 18h.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Carte postale de Chamonix envoyée par Fatou</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="12" y="12" width="296" height="176" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><line x1="196" y1="26" x2="196" y2="174" stroke="#E8ECF8" stroke-width="2"/><rect x="258" y="24" width="36" height="30" rx="2" fill="#1E3A8C"/><rect x="263" y="29" width="26" height="20" fill="none" stroke="#FFFFFF" stroke-width="1"/><circle cx="248" cy="42" r="11" fill="none" stroke="#1E3A8C" stroke-width="1" stroke-dasharray="3 2"/><text x="204" y="74" font-family="Arial" font-size="8" fill="#1E3A8C" letter-spacing="2">CARTE POSTALE</text><text x="204" y="112" font-family="Arial" font-size="10" fill="#0F1839">Awa Sow</text><text x="204" y="128" font-family="Arial" font-size="10" fill="#0F1839">21 rue Beauvoisine</text><text x="204" y="144" font-family="Arial" font-size="10" fill="#0F1839">76000 Rouen</text><text x="24" y="34" font-family="Arial" font-size="10" font-style="italic" fill="#1E3A8C">Chamonix, le 16 février</text><text x="24" y="56" font-family="Arial" font-size="10" fill="#0F1839">Chère Awa,</text><text x="24" y="72" font-family="Arial" font-size="10" fill="#0F1839">La montagne est splendide,</text><text x="24" y="88" font-family="Arial" font-size="10" fill="#0F1839">il y a beaucoup de neige.</text><text x="24" y="104" font-family="Arial" font-size="10" fill="#0F1839">Peux-tu venir me chercher</text><text x="24" y="120" font-family="Arial" font-size="10" font-weight="700" fill="#E1372F">à la gare vendredi à 18h ?</text><text x="24" y="140" font-family="Arial" font-size="10" font-style="italic" fill="#0F1839">Merci ! Fatou</text></svg>'),

  ('11111111-a009-5000-0000-000000000009', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Carte postale envoyée d''Ajaccio le 22 juin par Aïcha à Inès Morel à Nancy : la Corse est magnifique, hier elle a fait une promenade en bateau, elle rentre jeudi par le ferry de nuit.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Carte postale d''Ajaccio envoyée par Aïcha</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="12" y="12" width="296" height="176" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><line x1="196" y1="26" x2="196" y2="174" stroke="#E8ECF8" stroke-width="2"/><rect x="258" y="24" width="36" height="30" rx="2" fill="#168F5B"/><rect x="263" y="29" width="26" height="20" fill="none" stroke="#FFFFFF" stroke-width="1"/><circle cx="248" cy="42" r="11" fill="none" stroke="#1E3A8C" stroke-width="1" stroke-dasharray="3 2"/><text x="204" y="74" font-family="Arial" font-size="8" fill="#1E3A8C" letter-spacing="2">CARTE POSTALE</text><text x="204" y="112" font-family="Arial" font-size="10" fill="#0F1839">Inès Morel</text><text x="204" y="128" font-family="Arial" font-size="10" fill="#0F1839">6 place Stanislas</text><text x="204" y="144" font-family="Arial" font-size="10" fill="#0F1839">54000 Nancy</text><text x="24" y="34" font-family="Arial" font-size="10" font-style="italic" fill="#1E3A8C">Ajaccio, le 22 juin</text><text x="24" y="56" font-family="Arial" font-size="10" fill="#0F1839">Chère Inès,</text><text x="24" y="72" font-family="Arial" font-size="10" fill="#0F1839">La Corse est magnifique !</text><text x="24" y="88" font-family="Arial" font-size="10" fill="#0F1839">Hier, nous avons fait une</text><text x="24" y="104" font-family="Arial" font-size="10" fill="#0F1839">promenade en bateau.</text><text x="24" y="120" font-family="Arial" font-size="10" fill="#0F1839">Nous rentrons jeudi par le</text><text x="24" y="136" font-family="Arial" font-size="10" font-weight="700" fill="#168F5B">ferry de nuit.</text><text x="24" y="156" font-family="Arial" font-size="10" font-style="italic" fill="#0F1839">Aïcha</text></svg>'),

  ('11111111-a009-5000-0000-00000000000a', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Carte postale envoyée d''Avignon le 17 juillet par Yasmine à Paul Lemoine à Clermont-Ferrand : elle visite le festival avec sa classe de théâtre, ils ont vu trois spectacles formidables et rentrent mercredi en bus.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Carte postale d''Avignon envoyée par Yasmine</title><rect width="320" height="200" fill="#E8ECF8"/><rect x="12" y="12" width="296" height="176" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><line x1="196" y1="26" x2="196" y2="174" stroke="#E8ECF8" stroke-width="2"/><rect x="258" y="24" width="36" height="30" rx="2" fill="#E8A317"/><rect x="263" y="29" width="26" height="20" fill="none" stroke="#FFFFFF" stroke-width="1"/><circle cx="248" cy="42" r="11" fill="none" stroke="#1E3A8C" stroke-width="1" stroke-dasharray="3 2"/><text x="204" y="74" font-family="Arial" font-size="8" fill="#1E3A8C" letter-spacing="2">CARTE POSTALE</text><text x="204" y="112" font-family="Arial" font-size="10" fill="#0F1839">Paul Lemoine</text><text x="204" y="128" font-family="Arial" font-size="10" fill="#0F1839">30 rue des Gras</text><text x="204" y="144" font-family="Arial" font-size="10" fill="#0F1839">63000 Clermont-Ferrand</text><text x="24" y="34" font-family="Arial" font-size="10" font-style="italic" fill="#1E3A8C">Avignon, le 17 juillet</text><text x="24" y="56" font-family="Arial" font-size="10" fill="#0F1839">Cher Paul,</text><text x="24" y="72" font-family="Arial" font-size="10" fill="#0F1839">Je visite le festival avec</text><text x="24" y="88" font-family="Arial" font-size="10" fill="#0F1839">ma classe de théâtre.</text><text x="24" y="104" font-family="Arial" font-size="10" font-weight="700" fill="#168F5B">Nous avons vu trois</text><text x="24" y="120" font-family="Arial" font-size="10" font-weight="700" fill="#168F5B">spectacles formidables.</text><text x="24" y="136" font-family="Arial" font-size="10" fill="#0F1839">Nous rentrons mercredi</text><text x="24" y="152" font-family="Arial" font-size="10" fill="#0F1839">en bus.</text><text x="24" y="170" font-family="Arial" font-size="10" font-style="italic" fill="#0F1839">Yasmine</text></svg>');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-a009-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a009-5000-0000-000000000001', 'A2', 'CE',
   'Comment Olena rentre-t-elle de Nice ?',
   'Olena écrit « Je rentre samedi **par le train de 17h** » : elle rentre donc en train. L''avion, la voiture et le bus ne sont mentionnés nulle part sur la carte : ce sont des moyens de transport plausibles pour rentrer de Nice, mais aucun n''apparaît dans le message. Attention, « samedi » répondrait à « quand rentre-t-elle ? », pas à « comment ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a009-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a009-5000-0000-000000000002', 'A2', 'CE',
   'Qu''est-ce qu''Amadou a fait hier ?',
   'Amadou écrit « Hier, j''ai fait **une randonnée en montagne** ». « Une baignade dans le lac » confond avec la phrase « le lac d''Annecy est magnifique », qui décrit le paysage, pas une activité. Le vélo et la visite de musée ne sont mentionnés nulle part : ce sont des activités de vacances plausibles mais absentes de la carte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a009-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a009-5000-0000-000000000003', 'A2', 'CE',
   'Que demande Lucia à Nora ?',
   'Lucia écrit « **Viens fêter mon anniversaire le 3 août** chez moi ! » : elle invite Nora à son anniversaire. « Visiter Saint-Malo avec elle » confond avec le lieu où Lucia passe ses vacances, mais ce n''est pas la demande. « Écrire à sa tante » mélange « réponds-moi vite » et « chez ma tante ». Le gâteau n''est mentionné nulle part sur la carte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a009-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a009-5000-0000-000000000004', 'A2', 'CE',
   'Quand Wei rentre-t-il à Bordeaux ?',
   'Wei écrit « Je rentre **dimanche soir**, vers 21h ». « Samedi soir » et « lundi soir » sont des jours proches mais différents de celui annoncé sur la carte. « Dimanche matin » garde le bon jour mais change le moment de la journée : le message précise bien « soir, vers 21h ». Seul « dimanche soir » correspond exactement à la carte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a009-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a009-5000-0000-000000000005', 'A2', 'CE',
   'Que font les enfants tous les jours ?',
   'Rachid écrit « Les enfants font **du vélo** tous les jours ». La natation et la pêche sont plausibles dans un camping « près de la mer », mais elles n''apparaissent pas sur la carte : cette mention décrit seulement l''emplacement du camping. Les jeux de plage ne sont pas mentionnés non plus : seul le vélo est cité comme activité quotidienne.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a009-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a009-5000-0000-000000000006', 'A2', 'CE',
   'Que demande Priya à madame Garnier ?',
   'Priya demande « Pouvez-vous **arroser mes plantes** mardi ? ». Garder un chat, relever le courrier et fermer les volets sont des services de voisinage très courants pendant une absence, mais aucun n''est écrit sur la carte : ces trois distracteurs sont plausibles sans être vérifiables dans le document. Seules les plantes sont mentionnées.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a009-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a009-5000-0000-000000000007', 'A2', 'CE',
   'Quel sport Diego apprend-il à Biarritz ?',
   'Diego écrit « Je prends des **cours de surf** tous les après-midis ». La voile, la natation et la plongée sont d''autres sports nautiques plausibles à Biarritz, mais aucun n''apparaît sur la carte. La mention « en face de la plage » décrit la position de l''hôtel, elle n''indique pas un sport : seul le surf est explicitement cité.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a009-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a009-5000-0000-000000000008', 'A2', 'CE',
   'À quelle heure Awa doit-elle venir chercher Fatou à la gare ?',
   'Fatou demande « Peux-tu venir me chercher à la gare **vendredi à 18h** ? ». « À 8h » joue sur la confusion visuelle entre 8h et 18h. « À 16h » et « à 20h » sont des heures proches mais absentes de la carte. Aucune autre heure n''est mentionnée dans le message : seul 18h correspond à la demande écrite par Fatou.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a009-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a009-5000-0000-000000000009', 'A2', 'CE',
   'Comment Aïcha rentre-t-elle de Corse ?',
   'Aïcha écrit « Nous rentrons jeudi par le **ferry de nuit** ». Attention : la « promenade en bateau » d''hier est une activité de vacances, pas le moyen de retour. L''avion est un moyen plausible pour quitter la Corse mais il n''est pas mentionné. La voiture et le train ne figurent nulle part sur la carte : seul le ferry est annoncé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a009-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a009-5000-0000-00000000000a', 'A2', 'CE',
   'Combien de spectacles Yasmine a-t-elle vus à Avignon ?',
   'Yasmine écrit « Nous avons vu **trois spectacles** formidables ». « Deux » et « quatre » sont des nombres proches mais absents de la carte. « Un seul » contredit directement le pluriel et le chiffre indiqué. Ne pas confondre avec les autres chiffres du message : « le 17 juillet » est la date d''envoi et « mercredi » le jour du retour en bus.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('11111111-a009-2100-0000-000000000001', '11111111-a009-1000-0000-000000000001', 'En avion', 'false', '1'),
  ('11111111-a009-2200-0000-000000000001', '11111111-a009-1000-0000-000000000001', 'En train', 'true', '2'),
  ('11111111-a009-2300-0000-000000000001', '11111111-a009-1000-0000-000000000001', 'En voiture', 'false', '3'),
  ('11111111-a009-2400-0000-000000000001', '11111111-a009-1000-0000-000000000001', 'En bus', 'false', '4'),

  ('11111111-a009-2100-0000-000000000002', '11111111-a009-1000-0000-000000000002', 'Une baignade dans le lac', 'false', '1'),
  ('11111111-a009-2200-0000-000000000002', '11111111-a009-1000-0000-000000000002', 'Du vélo', 'false', '2'),
  ('11111111-a009-2300-0000-000000000002', '11111111-a009-1000-0000-000000000002', 'Une randonnée en montagne', 'true', '3'),
  ('11111111-a009-2400-0000-000000000002', '11111111-a009-1000-0000-000000000002', 'Une visite de musée', 'false', '4'),

  ('11111111-a009-2100-0000-000000000003', '11111111-a009-1000-0000-000000000003', 'De venir à son anniversaire', 'true', '1'),
  ('11111111-a009-2200-0000-000000000003', '11111111-a009-1000-0000-000000000003', 'De visiter Saint-Malo avec elle', 'false', '2'),
  ('11111111-a009-2300-0000-000000000003', '11111111-a009-1000-0000-000000000003', 'D''écrire à sa tante', 'false', '3'),
  ('11111111-a009-2400-0000-000000000003', '11111111-a009-1000-0000-000000000003', 'De lui apporter un gâteau', 'false', '4'),

  ('11111111-a009-2100-0000-000000000004', '11111111-a009-1000-0000-000000000004', 'Samedi soir', 'false', '1'),
  ('11111111-a009-2200-0000-000000000004', '11111111-a009-1000-0000-000000000004', 'Dimanche matin', 'false', '2'),
  ('11111111-a009-2300-0000-000000000004', '11111111-a009-1000-0000-000000000004', 'Lundi soir', 'false', '3'),
  ('11111111-a009-2400-0000-000000000004', '11111111-a009-1000-0000-000000000004', 'Dimanche soir', 'true', '4'),

  ('11111111-a009-2100-0000-000000000005', '11111111-a009-1000-0000-000000000005', 'De la natation', 'false', '1'),
  ('11111111-a009-2200-0000-000000000005', '11111111-a009-1000-0000-000000000005', 'De la pêche', 'false', '2'),
  ('11111111-a009-2300-0000-000000000005', '11111111-a009-1000-0000-000000000005', 'Du vélo', 'true', '3'),
  ('11111111-a009-2400-0000-000000000005', '11111111-a009-1000-0000-000000000005', 'Des jeux de plage', 'false', '4'),

  ('11111111-a009-2100-0000-000000000006', '11111111-a009-1000-0000-000000000006', 'D''arroser ses plantes', 'true', '1'),
  ('11111111-a009-2200-0000-000000000006', '11111111-a009-1000-0000-000000000006', 'De garder son chat', 'false', '2'),
  ('11111111-a009-2300-0000-000000000006', '11111111-a009-1000-0000-000000000006', 'De relever son courrier', 'false', '3'),
  ('11111111-a009-2400-0000-000000000006', '11111111-a009-1000-0000-000000000006', 'De fermer ses volets', 'false', '4'),

  ('11111111-a009-2100-0000-000000000007', '11111111-a009-1000-0000-000000000007', 'La voile', 'false', '1'),
  ('11111111-a009-2200-0000-000000000007', '11111111-a009-1000-0000-000000000007', 'La natation', 'false', '2'),
  ('11111111-a009-2300-0000-000000000007', '11111111-a009-1000-0000-000000000007', 'La plongée', 'false', '3'),
  ('11111111-a009-2400-0000-000000000007', '11111111-a009-1000-0000-000000000007', 'Le surf', 'true', '4'),

  ('11111111-a009-2100-0000-000000000008', '11111111-a009-1000-0000-000000000008', 'À 8h', 'false', '1'),
  ('11111111-a009-2200-0000-000000000008', '11111111-a009-1000-0000-000000000008', 'À 18h', 'true', '2'),
  ('11111111-a009-2300-0000-000000000008', '11111111-a009-1000-0000-000000000008', 'À 16h', 'false', '3'),
  ('11111111-a009-2400-0000-000000000008', '11111111-a009-1000-0000-000000000008', 'À 20h', 'false', '4'),

  ('11111111-a009-2100-0000-000000000009', '11111111-a009-1000-0000-000000000009', 'En avion', 'false', '1'),
  ('11111111-a009-2200-0000-000000000009', '11111111-a009-1000-0000-000000000009', 'En voiture', 'false', '2'),
  ('11111111-a009-2300-0000-000000000009', '11111111-a009-1000-0000-000000000009', 'En ferry', 'true', '3'),
  ('11111111-a009-2400-0000-000000000009', '11111111-a009-1000-0000-000000000009', 'En train', 'false', '4'),

  ('11111111-a009-2100-0000-00000000000a', '11111111-a009-1000-0000-00000000000a', 'Trois', 'true', '1'),
  ('11111111-a009-2200-0000-00000000000a', '11111111-a009-1000-0000-00000000000a', 'Deux', 'false', '2'),
  ('11111111-a009-2300-0000-00000000000a', '11111111-a009-1000-0000-00000000000a', 'Quatre', 'false', '3'),
  ('11111111-a009-2400-0000-00000000000a', '11111111-a009-1000-0000-00000000000a', 'Un seul', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 10 items (NN=01..0a), UUID déterministes uniques (questions 1000-,
--     medias 5000-, choices 2100/2200/2300/2400-).
-- [x] Tous les supports = cartes postales, 10 situations différentes
--     (Nice/retour en train, Annecy/randonnée, Saint-Malo/invitation
--     anniversaire, Strasbourg/marché de Noël, La Rochelle/camping en famille,
--     Paris/service entre voisines, Biarritz/cours de surf, Chamonix/venir
--     chercher à la gare, Ajaccio/ferry de nuit, Avignon/festival de théâtre).
--     Aucun support interdit (pas d'horaires, annonce, SMS, menu, invitation
--     imprimée, etc. — uniquement des cartes postales manuscrites).
-- [x] 4 choix par question, exactement 1 correct ; distribution des bonnes
--     réponses : pos1=3 (items 3,6,10), pos2=2 (items 1,8), pos3=3 (items
--     2,5,9), pos4=2 (items 4,7) — max 3 par position, 4 positions utilisées.
-- [x] Questions sur UNE information explicite (moyen de transport, activité,
--     demande, jour/heure de retour, nombre) ; labels des choices = texte de
--     la réponse ; distracteurs = autres valeurs présentes ou plausibles.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**.
-- [x] SVG : viewBox="0 0 320 200", Arial, palette charte, mise en page carte
--     postale (message à gauche, séparateur, timbre + cachet + adresse à
--     droite) ; rouge réservé à l'unique info critique (rendez-vous gare 18h,
--     item 8) ; balises équilibrées ; alt_text descriptif complet sur chaque
--     media. Texte utile ~25-35 mots par carte (calibre A2).
-- [x] Apostrophes SQL doublées ('') partout (SVG, alt_text, statements,
--     explanations, labels). Pas de JSONB (choices en lignes). Contenu 100%
--     original, prénoms/villes variés (Olena, Amadou, Lucia, Wei, Rachid,
--     Priya, Diego, Fatou, Aïcha, Yasmine — Nice, Annecy, Saint-Malo,
--     Strasbourg, La Rochelle, Paris, Biarritz, Chamonix, Ajaccio, Avignon).
-- [x] competence_code : 5× ce_reperage_explicite (items 1,3,6,7,9),
--     5× ce_detail_specifique (items 2,4,5,8,10).
-- ============================================================================
