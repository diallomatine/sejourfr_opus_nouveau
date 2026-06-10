-- ============================================================================
-- V410 — TCF CE A2 — lot 10 (support : post-it / mémo)
-- ----------------------------------------------------------------------------
-- 10 items CE A2, theme 22222222-0000-0000-0000-000000000002.
-- Chaque item = un post-it ou mémo manuscrit original (SVG style « document »)
-- + 1 question sur UNE information explicite + 4 choix (1 correct).
-- UUID déterministes : questions 11111111-a00a-1000-…, medias 11111111-a00a-5000-…,
-- choices 11111111-a00a-2100/2200/2300/2400-… (display_order 1..4).
-- ============================================================================


-- medias (IMAGE) — post-it / mémos référencés par les questions ci-dessous
INSERT INTO medias
  (id, type, url, storage_key, original_filename, content_type, size_bytes, duration_sec,
   alt_text, created_at, transcript, inline_svg)
VALUES
  ('11111111-a00a-5000-0000-000000000001', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Post-it de Lucia pour son colocataire Diego : le plombier passe demain à 14h30 ; il faut laisser la clé chez Mme Brun, au 3e étage. Signé Lucia.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Post-it de Lucia pour Diego au sujet du passage du plombier</title><rect width="320" height="200" fill="#E8ECF8"/><g transform="rotate(-2 160 100)"><rect x="42" y="26" width="236" height="150" rx="3" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1.5"/><rect x="132" y="18" width="56" height="14" rx="2" fill="#E8A317"/><text x="58" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839">Diego,</text><text x="58" y="80" font-family="Arial" font-size="11" fill="#0F1839">Le plombier passe demain</text><text x="58" y="100" font-family="Arial" font-size="11" fill="#0F1839">à <tspan font-weight="700" fill="#168F5B">14h30</tspan>.</text><text x="58" y="120" font-family="Arial" font-size="11" fill="#0F1839">Laisse la clé chez Mme Brun,</text><text x="58" y="140" font-family="Arial" font-size="11" fill="#0F1839">au 3e étage.</text><text x="262" y="162" font-family="Arial" font-size="11" font-style="italic" fill="#1E3A8C" text-anchor="end">Merci ! — Lucia</text></g></svg>'),

  ('11111111-a00a-5000-0000-000000000002', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Mémo téléphonique laissé à Wei par Inès de l''accueil : M. Garnier a appelé à 10h15, il faut le rappeler avant 17h au 06 44 19 28 51 ; le dossier Morel est urgent.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Mémo téléphonique laissé à Wei par Inès de l''accueil</title><rect width="320" height="200" fill="#E8ECF8"/><g transform="rotate(1.5 160 100)"><rect x="42" y="26" width="236" height="150" rx="3" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1.5"/><circle cx="160" cy="33" r="6" fill="#1E3A8C"/><text x="58" y="56" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839">Wei,</text><text x="58" y="76" font-family="Arial" font-size="11" fill="#0F1839">M. Garnier a appelé à 10h15.</text><text x="58" y="96" font-family="Arial" font-size="11" fill="#0F1839"><tspan font-weight="700" fill="#168F5B">Rappelle-le avant 17h</tspan></text><text x="58" y="116" font-family="Arial" font-size="11" fill="#0F1839">au 06 44 19 28 51.</text><text x="58" y="136" font-family="Arial" font-size="11" fill="#0F1839">Dossier Morel : <tspan font-weight="700" fill="#E1372F">URGENT</tspan></text><text x="262" y="160" font-family="Arial" font-size="11" font-style="italic" fill="#1E3A8C" text-anchor="end">— Inès, accueil</text></g></svg>'),

  ('11111111-a00a-5000-0000-000000000003', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Post-it de Sara collé sur le réfrigérateur pour Amadou : elle a pris sa voiture pour aller chez le dentiste, elle rentre vers 18h ; le dîner est dans le four. Signé Sara.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Post-it de Sara sur le réfrigérateur pour Amadou</title><rect width="320" height="200" fill="#E8ECF8"/><g transform="rotate(-1.5 160 100)"><rect x="42" y="26" width="236" height="150" rx="3" fill="#FDECEB" stroke="#1E3A8C" stroke-width="1.5"/><rect x="132" y="18" width="56" height="14" rx="2" fill="#E8A317"/><text x="58" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839">Amadou,</text><text x="58" y="80" font-family="Arial" font-size="11" fill="#0F1839">J''ai pris ta voiture pour aller</text><text x="58" y="100" font-family="Arial" font-size="11" fill="#0F1839">chez le dentiste.</text><text x="58" y="120" font-family="Arial" font-size="11" fill="#0F1839">Je rentre vers 18h.</text><text x="58" y="140" font-family="Arial" font-size="11" fill="#0F1839">Le dîner est <tspan font-weight="700" fill="#168F5B">dans le four</tspan>.</text><text x="262" y="162" font-family="Arial" font-size="11" font-style="italic" fill="#1E3A8C" text-anchor="end">Bisous — Sara</text></g></svg>'),

  ('11111111-a00a-5000-0000-000000000004', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Mémo de Mme Diop, la gardienne, pour Mme Kovak : un colis est arrivé ce matin ; il faut venir le chercher à la loge avant samedi 19h.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Mémo de la gardienne pour Mme Kovak au sujet d''un colis</title><rect width="320" height="200" fill="#E8ECF8"/><g transform="rotate(2 160 100)"><rect x="42" y="26" width="236" height="150" rx="3" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1.5"/><circle cx="160" cy="33" r="6" fill="#1E3A8C"/><text x="58" y="56" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839">Mme Kovak,</text><text x="58" y="78" font-family="Arial" font-size="11" fill="#0F1839">Un colis est arrivé pour vous</text><text x="58" y="98" font-family="Arial" font-size="11" fill="#0F1839">ce matin.</text><text x="58" y="118" font-family="Arial" font-size="11" fill="#0F1839">Venez le chercher <tspan font-weight="700" fill="#168F5B">à la loge</tspan>,</text><text x="58" y="138" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">avant samedi 19h.</text><text x="262" y="160" font-family="Arial" font-size="11" font-style="italic" fill="#1E3A8C" text-anchor="end">— Mme Diop, gardienne</text></g></svg>'),

  ('11111111-a00a-5000-0000-000000000005', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Post-it de Rachid pour sa collègue Priya : la réunion de jeudi est déplacée en salle 12, à 9h45 ; il faut apporter le rapport bleu. Signé Rachid.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Post-it de Rachid pour Priya au sujet de la réunion déplacée</title><rect width="320" height="200" fill="#E8ECF8"/><g transform="rotate(-2 160 100)"><rect x="42" y="26" width="236" height="150" rx="3" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1.5"/><rect x="132" y="18" width="56" height="14" rx="2" fill="#E8A317"/><text x="58" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839">Priya,</text><text x="58" y="80" font-family="Arial" font-size="11" fill="#0F1839">La réunion de jeudi est déplacée</text><text x="58" y="100" font-family="Arial" font-size="11" fill="#0F1839"><tspan font-weight="700" fill="#168F5B">en salle 12</tspan>, à 9h45.</text><text x="58" y="124" font-family="Arial" font-size="11" fill="#0F1839">Apporte le rapport bleu.</text><text x="262" y="158" font-family="Arial" font-size="11" font-style="italic" fill="#1E3A8C" text-anchor="end">Merci — Rachid</text></g></svg>'),

  ('11111111-a00a-5000-0000-000000000006', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Note de Mme Lopez pour son voisin M. Diallo : son alarme a sonné ce matin pendant une heure ; elle lui demande de passer la voir ce soir après 19h, appartement 24.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Note de Mme Lopez pour son voisin M. Diallo</title><rect width="320" height="200" fill="#E8ECF8"/><g transform="rotate(1.5 160 100)"><rect x="42" y="26" width="236" height="150" rx="3" fill="#FDECEB" stroke="#1E3A8C" stroke-width="1.5"/><rect x="132" y="18" width="56" height="14" rx="2" fill="#E8A317"/><text x="58" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839">M. Diallo,</text><text x="58" y="80" font-family="Arial" font-size="11" fill="#0F1839">Votre alarme a sonné ce matin</text><text x="58" y="100" font-family="Arial" font-size="11" fill="#0F1839">pendant une heure.</text><text x="58" y="120" font-family="Arial" font-size="11" fill="#0F1839">Pouvez-vous passer me voir</text><text x="58" y="140" font-family="Arial" font-size="11" fill="#0F1839"><tspan font-weight="700" fill="#168F5B">ce soir après 19h</tspan> ?</text><text x="262" y="162" font-family="Arial" font-size="11" font-style="italic" fill="#1E3A8C" text-anchor="end">Appartement 24 — Mme Lopez</text></g></svg>'),

  ('11111111-a00a-5000-0000-000000000007', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Mémo de Fatou pour son fils Kofi : ne pas oublier le cours de guitare à 16h, le bus 7 part à 15h40 ; elle a laissé 5 euros sur la table. Signé Maman.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Mémo de Fatou pour son fils Kofi</title><rect width="320" height="200" fill="#E8ECF8"/><g transform="rotate(-1.5 160 100)"><rect x="42" y="26" width="236" height="150" rx="3" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1.5"/><circle cx="160" cy="33" r="6" fill="#1E3A8C"/><text x="58" y="56" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839">Kofi,</text><text x="58" y="78" font-family="Arial" font-size="11" fill="#0F1839">N''oublie pas ton cours de guitare</text><text x="58" y="98" font-family="Arial" font-size="11" fill="#0F1839">à 16h. Le bus 7 part à 15h40.</text><text x="58" y="120" font-family="Arial" font-size="11" fill="#0F1839">J''ai laissé <tspan font-weight="700" fill="#168F5B">5 euros</tspan></text><text x="58" y="140" font-family="Arial" font-size="11" fill="#0F1839">sur la table.</text><text x="262" y="162" font-family="Arial" font-size="11" font-style="italic" fill="#1E3A8C" text-anchor="end">Maman</text></g></svg>'),

  ('11111111-a00a-5000-0000-000000000008', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Post-it de Léna pour Hugo qui garde son chat Plume : donner le médicament à 20h, une demi-pipette seulement ; les croquettes sont dans le placard bleu. Elle revient jeudi.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Post-it de Léna pour Hugo qui garde le chat Plume</title><rect width="320" height="200" fill="#E8ECF8"/><g transform="rotate(2 160 100)"><rect x="42" y="26" width="236" height="150" rx="3" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1.5"/><rect x="132" y="18" width="56" height="14" rx="2" fill="#E8A317"/><text x="58" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839">Hugo,</text><text x="58" y="78" font-family="Arial" font-size="11" fill="#0F1839">Merci de garder Plume !</text><text x="58" y="98" font-family="Arial" font-size="11" fill="#0F1839">Son médicament : <tspan font-weight="700" fill="#168F5B">à 20h</tspan>,</text><text x="58" y="118" font-family="Arial" font-size="11" font-weight="700" fill="#E1372F">une demi-pipette seulement.</text><text x="58" y="138" font-family="Arial" font-size="11" fill="#0F1839">Croquettes dans le placard bleu.</text><text x="262" y="160" font-family="Arial" font-size="11" font-style="italic" fill="#1E3A8C" text-anchor="end">À jeudi — Léna</text></g></svg>'),

  ('11111111-a00a-5000-0000-000000000009', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Mémo de Karim pour sa collègue Nadia : le client de Toulouse arrive lundi à 11h ; il faut réserver la salle de réunion et commander 6 plateaux-repas. Signé Karim.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Mémo de Karim pour Nadia au sujet de la visite d''un client</title><rect width="320" height="200" fill="#E8ECF8"/><g transform="rotate(-2 160 100)"><rect x="42" y="26" width="236" height="150" rx="3" fill="#FDECEB" stroke="#1E3A8C" stroke-width="1.5"/><circle cx="160" cy="33" r="6" fill="#1E3A8C"/><text x="58" y="56" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839">Nadia,</text><text x="58" y="78" font-family="Arial" font-size="11" fill="#0F1839">Le client de Toulouse arrive</text><text x="58" y="98" font-family="Arial" font-size="11" fill="#0F1839">lundi à 11h.</text><text x="58" y="118" font-family="Arial" font-size="11" fill="#0F1839">Réserve la salle de réunion et</text><text x="58" y="138" font-family="Arial" font-size="11" fill="#0F1839">commande <tspan font-weight="700" fill="#168F5B">6 plateaux-repas</tspan>.</text><text x="262" y="160" font-family="Arial" font-size="11" font-style="italic" fill="#1E3A8C" text-anchor="end">Merci — Karim</text></g></svg>'),

  ('11111111-a00a-5000-0000-00000000000a', 'IMAGE', NULL, NULL, NULL, NULL, NULL, NULL,
   'Post-it du père de Sofia : il a déposé ses lunettes chez l''opticien, rue Carnot ; elles seront prêtes mercredi, le ticket est dans son tiroir. Signé Papa.',
   '2026-06-07 12:00:00+02', NULL,
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg" role="img"><title>Post-it du père de Sofia au sujet de ses lunettes</title><rect width="320" height="200" fill="#E8ECF8"/><g transform="rotate(1.5 160 100)"><rect x="42" y="26" width="236" height="150" rx="3" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1.5"/><rect x="132" y="18" width="56" height="14" rx="2" fill="#E8A317"/><text x="58" y="58" font-family="Arial" font-size="12" font-weight="700" fill="#0F1839">Sofia,</text><text x="58" y="80" font-family="Arial" font-size="11" fill="#0F1839">J''ai déposé tes lunettes</text><text x="58" y="100" font-family="Arial" font-size="11" fill="#0F1839">chez l''opticien, rue Carnot.</text><text x="58" y="120" font-family="Arial" font-size="11" fill="#0F1839">Elles seront prêtes <tspan font-weight="700" fill="#168F5B">mercredi</tspan>.</text><text x="58" y="140" font-family="Arial" font-size="11" fill="#0F1839">Le ticket est dans ton tiroir.</text><text x="262" y="162" font-family="Arial" font-size="11" font-style="italic" fill="#1E3A8C" text-anchor="end">Papa</text></g></svg>');

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('11111111-a00a-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00a-5000-0000-000000000001', 'A2', 'CE',
   'À quelle heure le plombier passe-t-il ?',
   'Le post-it indique « Le plombier passe demain **à 14h30** ». « 13h30 », « 15h30 » et « 14h » sont des horaires proches qui jouent sur la confusion des heures et des minutes, mais aucun ne figure sur la note. Le seul autre chiffre du document, « 3e étage », concerne l''adresse de Mme Brun, pas un horaire.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00a-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00a-5000-0000-000000000002', 'A2', 'CE',
   'Que doit faire Wei ?',
   'Le mémo demande explicitement « **Rappelle-le avant 17h** » : Wei doit rappeler M. Garnier. « Appeler l''accueil » confond avec la signature d''Inès, qui travaille à l''accueil et a seulement pris le message. « Apporter le dossier Morel à 10h15 » mélange l''heure de l''appel reçu et le dossier signalé comme urgent. « Attendre l''appel de M. Garnier » inverse l''action : c''est lui qui a déjà appelé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00a-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00a-5000-0000-000000000003', 'A2', 'CE',
   'Où Sara a-t-elle laissé le dîner ?',
   'La note précise « Le dîner est **dans le four** ». « Chez le dentiste » est l''endroit où Sara est allée, pas celui du repas. « Dans la voiture » désigne le véhicule qu''elle a emprunté à Amadou. « Dans le réfrigérateur » est un lieu plausible pour un plat, mais il n''est jamais mentionné sur le post-it.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00a-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00a-5000-0000-000000000004', 'A2', 'CE',
   'Où Mme Kovak doit-elle récupérer son colis ?',
   'Le mémo dit « Venez le chercher **à la loge**, avant samedi 19h » : c''est la loge de la gardienne, Mme Diop. « Au bureau de poste » et « dans sa boîte aux lettres » sont des lieux habituels pour un colis, mais ils n''apparaissent pas sur la note. « Chez une voisine » déforme le rôle de Mme Diop : c''est la gardienne de l''immeuble, et le colis est à la loge.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00a-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00a-5000-0000-000000000005', 'A2', 'CE',
   'Où aura lieu la réunion de jeudi ?',
   'Le post-it annonce « La réunion de jeudi est déplacée **en salle 12**, à 9h45 ». « En salle 9 » et « en salle 45 » recyclent les chiffres de l''horaire 9h45 : ce sont des pièges sur les nombres du document. « Au bureau de Rachid » est plausible car Rachid signe le mémo, mais aucun bureau n''est mentionné comme lieu de réunion.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00a-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00a-5000-0000-000000000006', 'A2', 'CE',
   'Quand M. Diallo doit-il passer voir Mme Lopez ?',
   'La note demande « Pouvez-vous passer me voir **ce soir après 19h** ? ». « Ce matin » est le moment où l''alarme a sonné, pas celui de la visite. « Demain matin » n''apparaît nulle part sur la note. « Samedi à 19h » conserve la bonne heure mais invente le jour : la demande concerne le soir même.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00a-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00a-5000-0000-000000000007', 'A2', 'CE',
   'Quelle somme Kofi va-t-il trouver sur la table ?',
   'Le mémo précise « J''ai laissé **5 euros** sur la table ». « 7 euros » reprend le numéro du bus 7, « 16 euros » l''heure du cours de guitare (16h) et « 15 euros » l''horaire de départ du bus (15h40) : ces trois distracteurs recyclent les autres chiffres de la note, qui ne sont pas des sommes d''argent.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00a-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00a-5000-0000-000000000008', 'A2', 'CE',
   'À quelle heure Hugo doit-il donner le médicament au chat ?',
   'Le post-it indique « Son médicament : **à 20h**, une demi-pipette seulement ». « À midi » et « le matin » ne sont mentionnés nulle part sur la note. « Jeudi » est le jour du retour de Léna (« À jeudi — Léna ») : ce distracteur répondrait à « quand Léna revient-elle ? », pas à la question de l''heure du médicament.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_reperage_explicite'),

  ('11111111-a00a-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00a-5000-0000-000000000009', 'A2', 'CE',
   'Combien de plateaux-repas Nadia doit-elle commander ?',
   'Le mémo demande « commande **6 plateaux-repas** ». « 11 » reprend l''heure d''arrivée du client (lundi à 11h) : c''est le piège principal sur les chiffres du document. « 4 » et « 16 » sont des quantités plausibles pour une réunion, mais elles n''apparaissent nulle part sur la note de Karim.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique'),

  ('11111111-a00a-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000002', NULL,
   '11111111-a00a-5000-0000-00000000000a', 'A2', 'CE',
   'Quand les lunettes de Sofia seront-elles prêtes ?',
   'Le post-it indique « Elles seront prêtes **mercredi** ». « Mardi » et « vendredi » sont des jours proches mais absents de la note : ils jouent sur la confusion des jours de la semaine. « Aujourd''hui » contredit le futur « seront prêtes » : le père vient seulement de déposer les lunettes chez l''opticien de la rue Carnot.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'ce_detail_specifique');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('11111111-a00a-2100-0000-000000000001', '11111111-a00a-1000-0000-000000000001', 'À 13h30', 'false', '1'),
  ('11111111-a00a-2200-0000-000000000001', '11111111-a00a-1000-0000-000000000001', 'À 14h30', 'true', '2'),
  ('11111111-a00a-2300-0000-000000000001', '11111111-a00a-1000-0000-000000000001', 'À 15h30', 'false', '3'),
  ('11111111-a00a-2400-0000-000000000001', '11111111-a00a-1000-0000-000000000001', 'À 14h', 'false', '4'),

  ('11111111-a00a-2100-0000-000000000002', '11111111-a00a-1000-0000-000000000002', 'Rappeler M. Garnier', 'true', '1'),
  ('11111111-a00a-2200-0000-000000000002', '11111111-a00a-1000-0000-000000000002', 'Appeler l''accueil', 'false', '2'),
  ('11111111-a00a-2300-0000-000000000002', '11111111-a00a-1000-0000-000000000002', 'Apporter le dossier Morel à 10h15', 'false', '3'),
  ('11111111-a00a-2400-0000-000000000002', '11111111-a00a-1000-0000-000000000002', 'Attendre l''appel de M. Garnier', 'false', '4'),

  ('11111111-a00a-2100-0000-000000000003', '11111111-a00a-1000-0000-000000000003', 'Chez le dentiste', 'false', '1'),
  ('11111111-a00a-2200-0000-000000000003', '11111111-a00a-1000-0000-000000000003', 'Dans la voiture', 'false', '2'),
  ('11111111-a00a-2300-0000-000000000003', '11111111-a00a-1000-0000-000000000003', 'Dans le four', 'true', '3'),
  ('11111111-a00a-2400-0000-000000000003', '11111111-a00a-1000-0000-000000000003', 'Dans le réfrigérateur', 'false', '4'),

  ('11111111-a00a-2100-0000-000000000004', '11111111-a00a-1000-0000-000000000004', 'Au bureau de poste', 'false', '1'),
  ('11111111-a00a-2200-0000-000000000004', '11111111-a00a-1000-0000-000000000004', 'Dans sa boîte aux lettres', 'false', '2'),
  ('11111111-a00a-2300-0000-000000000004', '11111111-a00a-1000-0000-000000000004', 'Chez une voisine', 'false', '3'),
  ('11111111-a00a-2400-0000-000000000004', '11111111-a00a-1000-0000-000000000004', 'À la loge de la gardienne', 'true', '4'),

  ('11111111-a00a-2100-0000-000000000005', '11111111-a00a-1000-0000-000000000005', 'En salle 12', 'true', '1'),
  ('11111111-a00a-2200-0000-000000000005', '11111111-a00a-1000-0000-000000000005', 'En salle 9', 'false', '2'),
  ('11111111-a00a-2300-0000-000000000005', '11111111-a00a-1000-0000-000000000005', 'Au bureau de Rachid', 'false', '3'),
  ('11111111-a00a-2400-0000-000000000005', '11111111-a00a-1000-0000-000000000005', 'En salle 45', 'false', '4'),

  ('11111111-a00a-2100-0000-000000000006', '11111111-a00a-1000-0000-000000000006', 'Ce matin', 'false', '1'),
  ('11111111-a00a-2200-0000-000000000006', '11111111-a00a-1000-0000-000000000006', 'Ce soir après 19h', 'true', '2'),
  ('11111111-a00a-2300-0000-000000000006', '11111111-a00a-1000-0000-000000000006', 'Demain matin', 'false', '3'),
  ('11111111-a00a-2400-0000-000000000006', '11111111-a00a-1000-0000-000000000006', 'Samedi à 19h', 'false', '4'),

  ('11111111-a00a-2100-0000-000000000007', '11111111-a00a-1000-0000-000000000007', '7 euros', 'false', '1'),
  ('11111111-a00a-2200-0000-000000000007', '11111111-a00a-1000-0000-000000000007', '16 euros', 'false', '2'),
  ('11111111-a00a-2300-0000-000000000007', '11111111-a00a-1000-0000-000000000007', '5 euros', 'true', '3'),
  ('11111111-a00a-2400-0000-000000000007', '11111111-a00a-1000-0000-000000000007', '15 euros', 'false', '4'),

  ('11111111-a00a-2100-0000-000000000008', '11111111-a00a-1000-0000-000000000008', 'À 20h', 'true', '1'),
  ('11111111-a00a-2200-0000-000000000008', '11111111-a00a-1000-0000-000000000008', 'À midi', 'false', '2'),
  ('11111111-a00a-2300-0000-000000000008', '11111111-a00a-1000-0000-000000000008', 'Le matin', 'false', '3'),
  ('11111111-a00a-2400-0000-000000000008', '11111111-a00a-1000-0000-000000000008', 'Jeudi', 'false', '4'),

  ('11111111-a00a-2100-0000-000000000009', '11111111-a00a-1000-0000-000000000009', '11', 'false', '1'),
  ('11111111-a00a-2200-0000-000000000009', '11111111-a00a-1000-0000-000000000009', '4', 'false', '2'),
  ('11111111-a00a-2300-0000-000000000009', '11111111-a00a-1000-0000-000000000009', '16', 'false', '3'),
  ('11111111-a00a-2400-0000-000000000009', '11111111-a00a-1000-0000-000000000009', '6', 'true', '4'),

  ('11111111-a00a-2100-0000-00000000000a', '11111111-a00a-1000-0000-00000000000a', 'Mardi', 'false', '1'),
  ('11111111-a00a-2200-0000-00000000000a', '11111111-a00a-1000-0000-00000000000a', 'Mercredi', 'true', '2'),
  ('11111111-a00a-2300-0000-00000000000a', '11111111-a00a-1000-0000-00000000000a', 'Vendredi', 'false', '3'),
  ('11111111-a00a-2400-0000-00000000000a', '11111111-a00a-1000-0000-00000000000a', 'Aujourd''hui', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 10 items (NN=01..0a), UUID déterministes uniques (questions 1000-,
--     medias 5000-, choices 2100/2200/2300/2400-).
-- [x] Tous les supports = post-it / mémos, 10 situations différentes
--     (plombier en colocation, mémo téléphonique au bureau, post-it frigo,
--     colis chez la gardienne, réunion déplacée, note de voisinage, mémo
--     parent-enfant, garde de chat, visite d''un client, lunettes chez
--     l''opticien). Aucun support interdit (pas de panneau d''horaires, SMS,
--     petite annonce, étiquette, affichette, menu, carte postale, etc.).
-- [x] 4 choix par question, exactement 1 correct ; distribution des bonnes
--     réponses : pos1=3 (items 2,5,8), pos2=3 (items 1,6,10), pos3=2 (items
--     3,7), pos4=2 (items 4,9) — max 3 par position, 4 positions utilisées.
-- [x] Questions sur UNE information explicite (heure, lieu, somme, jour,
--     quantité, action demandée) ; labels des choices = texte de la réponse ;
--     distracteurs = autres valeurs présentes sur la note ou plausibles.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chacun des
--     3 distracteurs, point clé en **gras**.
-- [x] SVG : viewBox="0 0 320 200", style post-it (note inclinée + scotch
--     ambre ou punaise navy), Arial, palette charte, rouge réservé aux infos
--     critiques (URGENT, date limite du colis, dose du médicament) ; balises
--     équilibrées ; alt_text descriptif complet sur chaque media. Texte utile
--     ~15-30 mots par note (conforme A2 : ~10-40 mots).
-- [x] Apostrophes SQL doublées ('') partout (SVG, alt_text, statements,
--     explanations, labels). Pas de JSONB (choices en lignes). Contenu 100%
--     original, prénoms variés (Lucia, Diego, Wei, Inès, Sara, Amadou, Olena
--     Kovak, Mme Diop, Rachid, Priya, M. Diallo, Mme Lopez, Fatou, Kofi,
--     Léna, Hugo, Karim, Nadia, Sofia), chiffres tous différents.
-- [x] competence_code : 5× ce_reperage_explicite (items 1,2,3,4,8),
--     5× ce_detail_specifique (items 5,6,7,9,10).
-- ============================================================================
