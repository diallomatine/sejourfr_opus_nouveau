-- ============================================================================
-- V874 — TCF CO B2 — lot 12 (thème : récit professionnel)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B2), format C : récit professionnel à la première
-- personne (~120-200 mots) + question implicite (cause réelle, intention du
-- locuteur, idée principale, conséquence non dite). Table audio_question_draft.
-- status='TEXT_VALIDATED', colonnes audio NULL (remplies par le batch admin
-- Azure). Contenu 100% original, locuteurs et situations inventés.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-c00c-1000-0000-000000000001', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Je m''appelle Wei Lin et je tiens une boulangerie à Périgueux depuis trois ans. Avant, j''étais comptable dans un grand cabinet parisien. Sur le papier, tout allait bien : un bon salaire, un bureau avec vue, des dossiers prestigieux. Pourtant, chaque dimanche soir, je sentais une boule au ventre en pensant à la semaine qui commençait. Pendant longtemps, j''ai mis ça sur le compte de la fatigue. Puis un matin, en validant le bilan d''une entreprise que je n''avais jamais visitée, j''ai réalisé que je passais ma vie à compter le travail des autres sans jamais rien produire de mes mains. Six mois plus tard, je m''inscrivais à un CAP de boulanger. Mes anciens collègues ont cru à un coup de tête ; ma banquière, à une folie. Aujourd''hui, je me lève à quatre heures, je gagne moins, et je n''ai plus jamais ressenti cette boule au ventre du dimanche soir.

Qu''est-ce qui a décidé Wei à changer de métier ?

A. Le besoin de créer quelque chose de concret de ses mains.
B. Une fatigue professionnelle accumulée au fil des années.
C. Un salaire devenu insuffisant pour vivre à Paris.
D. Les encouragements de ses collègues et de sa banquière.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je m''appelle Wei Lin et je tiens une boulangerie à Périgueux depuis trois ans. Avant, j''étais comptable dans un grand cabinet parisien. Sur le papier, tout allait bien : un bon salaire, un bureau avec vue, des dossiers prestigieux. Pourtant, chaque dimanche soir, je sentais une boule au ventre en pensant à la semaine qui commençait. Pendant longtemps, j''ai mis ça sur le compte de la fatigue. Puis un matin, en validant le bilan d''une entreprise que je n''avais jamais visitée, j''ai réalisé que je passais ma vie à compter le travail des autres sans jamais rien produire de mes mains. Six mois plus tard, je m''inscrivais à un CAP de boulanger. Mes anciens collègues ont cru à un coup de tête ; ma banquière, à une folie. Aujourd''hui, je me lève à quatre heures, je gagne moins, et je n''ai plus jamais ressenti cette boule au ventre du dimanche soir.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Qu''est-ce qui a décidé Wei à changer de métier ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le besoin de créer quelque chose de concret de ses mains.<break time="700ms"/>B.<break time="300ms"/>Une fatigue professionnelle accumulée au fil des années.<break time="700ms"/>C.<break time="300ms"/>Un salaire devenu insuffisant pour vivre à Paris.<break time="700ms"/>D.<break time="300ms"/>Les encouragements de ses collègues et de sa banquière.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question porte sur la **cause réelle du changement**, jamais énoncée comme telle : le déclic survient le matin du bilan (« compter le travail des autres sans jamais rien produire de mes mains ») et débouche « six mois plus tard » sur le CAP — A reformule ce besoin de produire du concret. B reprend la **cause que Wei écarte lui-même** (« pendant longtemps, j''ai mis ça sur le compte de la fatigue ») — piège entre cause supposée et cause réelle. C contredit le texte : il avait « un bon salaire » et accepte aujourd''hui de gagner moins. D inverse les réactions de l''entourage : collègues et banquière ont parlé de « coup de tête » et de « folie », ils ne l''ont pas encouragé.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00c-1000-0000-000000000002', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Je suis Aminata Touré, grutière au port du Havre depuis neuf ans. On me demande souvent de raconter mon premier jour, alors le voici. À l''époque, j''étais la seule femme de l''équipe. Quand je suis montée dans la cabine, à cinquante mètres du sol, le chef de quai a annoncé à la radio, devant tout le monde, qu''on allait « bien rigoler ». Ce matin-là, je devais décharger quarante conteneurs ; j''en ai déchargé quarante-six, sans une seule manœuvre reprise. Personne n''a applaudi, évidemment. Mais le lendemain, le même chef m''a confié le portique le plus délicat du terminal, celui qu''on ne donne jamais aux débutants. Il ne s''est jamais excusé, et je n''ai jamais rien demandé. Si je raconte cette histoire aux jeunes femmes qui visitent le port, ce n''est pas pour me plaindre du passé : c''est pour qu''elles sachent que la compétence finit par s''imposer, même là où on ne vous attend pas.

Pourquoi Aminata raconte-t-elle ce souvenir ?

A. Pour dénoncer publiquement l''attitude de son ancien chef de quai.
B. Pour décrire les difficultés techniques du déchargement des conteneurs.
C. Pour montrer aux jeunes femmes que la compétence finit par s''imposer.
D. Pour obtenir enfin les excuses qu''elle attend depuis ses débuts.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je suis Aminata Touré, grutière au port du Havre depuis neuf ans. On me demande souvent de raconter mon premier jour, alors le voici. À l''époque, j''étais la seule femme de l''équipe. Quand je suis montée dans la cabine, à cinquante mètres du sol, le chef de quai a annoncé à la radio, devant tout le monde, qu''on allait « bien rigoler ». Ce matin-là, je devais décharger quarante conteneurs ; j''en ai déchargé quarante-six, sans une seule manœuvre reprise. Personne n''a applaudi, évidemment. Mais le lendemain, le même chef m''a confié le portique le plus délicat du terminal, celui qu''on ne donne jamais aux débutants. Il ne s''est jamais excusé, et je n''ai jamais rien demandé. Si je raconte cette histoire aux jeunes femmes qui visitent le port, ce n''est pas pour me plaindre du passé : c''est pour qu''elles sachent que la compétence finit par s''imposer, même là où on ne vous attend pas.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi Aminata raconte-t-elle ce souvenir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour dénoncer publiquement l''attitude de son ancien chef de quai.<break time="700ms"/>B.<break time="300ms"/>Pour décrire les difficultés techniques du déchargement des conteneurs.<break time="700ms"/>C.<break time="300ms"/>Pour montrer aux jeunes femmes que la compétence finit par s''imposer.<break time="700ms"/>D.<break time="300ms"/>Pour obtenir enfin les excuses qu''elle attend depuis ses débuts.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Il faut identifier **l''intention de la locutrice**, livrée à la fin : « ce n''est pas pour me plaindre du passé, c''est pour qu''elles sachent que la compétence finit par s''imposer » — C la reformule fidèlement. A contredit ce refus explicite de se plaindre et le ton apaisé du récit (« je n''ai jamais rien demandé ») : dénoncer répondrait à une autre intention. B confond le **thème** (le travail de grutière, les conteneurs) avec le **propos** (la légitimité gagnée par la compétence) — piège B2 classique. D est un contresens : Aminata précise que le chef « ne s''est jamais excusé » et qu''elle n''a « jamais rien demandé » — elle n''attend aucune excuse.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00c-1000-0000-000000000003', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Je m''appelle Pavlo Marchenko, je suis interprète. Pendant quinze ans, j''ai traduit des contrats commerciaux depuis mon bureau de Lyon, un travail confortable et solitaire. Et puis il y a quatre ans, une nuit de janvier, un hôpital m''a appelé : une patiente venait d''arriver aux urgences, personne ne comprenait sa langue, et chaque minute comptait. J''ai traduit par téléphone, en pyjama, les questions du médecin et les réponses de cette femme terrifiée. L''intervention a duré vingt minutes ; je n''ai pas dormi du reste de la nuit. Dans les semaines qui ont suivi, j''ai décliné deux gros contrats juridiques pour suivre une formation d''interprétariat médical. Mon comptable m''a fait remarquer que mes revenus avaient baissé d''un tiers. C''est exact. Mais quand je raccroche après une garde aux urgences, je sais précisément à quoi mes mots ont servi, et aucun contrat commercial ne m''a jamais donné cela.

Quelle conséquence cet appel nocturne a-t-il eue sur la carrière de Pavlo ?

A. Il a complètement abandonné la traduction de contrats commerciaux.
B. Il a été recruté comme salarié par l''hôpital qui l''avait appelé.
C. Il a vu ses revenus augmenter grâce aux gardes médicales.
D. Il a réorienté une partie de son activité vers l''interprétariat médical.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je m''appelle Pavlo Marchenko, je suis interprète. Pendant quinze ans, j''ai traduit des contrats commerciaux depuis mon bureau de Lyon, un travail confortable et solitaire. Et puis il y a quatre ans, une nuit de janvier, un hôpital m''a appelé : une patiente venait d''arriver aux urgences, personne ne comprenait sa langue, et chaque minute comptait. J''ai traduit par téléphone, en pyjama, les questions du médecin et les réponses de cette femme terrifiée. L''intervention a duré vingt minutes ; je n''ai pas dormi du reste de la nuit. Dans les semaines qui ont suivi, j''ai décliné deux gros contrats juridiques pour suivre une formation d''interprétariat médical. Mon comptable m''a fait remarquer que mes revenus avaient baissé d''un tiers. C''est exact. Mais quand je raccroche après une garde aux urgences, je sais précisément à quoi mes mots ont servi, et aucun contrat commercial ne m''a jamais donné cela.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle conséquence cet appel nocturne a-t-il eue sur la carrière de Pavlo ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il a complètement abandonné la traduction de contrats commerciaux.<break time="700ms"/>B.<break time="300ms"/>Il a été recruté comme salarié par l''hôpital qui l''avait appelé.<break time="700ms"/>C.<break time="300ms"/>Il a vu ses revenus augmenter grâce aux gardes médicales.<break time="700ms"/>D.<break time="300ms"/>Il a réorienté une partie de son activité vers l''interprétariat médical.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La conséquence n''est jamais résumée en une phrase : il faut **relier des indices dispersés** — formation d''interprétariat médical, contrats déclinés, revenus en baisse d''un tiers, gardes aux urgences — pour inférer la réorientation partielle que D formule. A est trop absolue : une baisse « d''un tiers » seulement montre qu''il conserve une part de son activité commerciale — piège du **détail quantitatif qui limite la portée** d''une affirmation. B invente une embauche jamais mentionnée : il assure des gardes, rien n''indique un statut de salarié de l''hôpital. C inverse l''effet : ses revenus ont **baissé**, et c''est précisément le sens du récit (il a choisi le sens de son travail contre l''argent) — inversion cause/effet typique du B2.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00c-1000-0000-000000000004', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Je suis Daniela Costa, cheffe d''un restaurant à Biarritz. Le récit que je préfère raconter à mes apprentis n''est pas celui d''un succès. Il y a sept ans, un critique gastronomique réputé a réservé chez moi. J''ai voulu tellement bien faire que j''ai changé toute la carte la veille : des plats plus techniques, plus spectaculaires, que ma brigade n''avait jamais répétés. Le service a été un désastre : assiettes froides, cuissons ratées, quarante minutes d''attente. L''article a été cruel, et il était mérité. Pendant des semaines, j''ai voulu vendre le restaurant. Puis j''ai relu mes anciens menus, ceux qui remplissaient la salle, et j''ai compris que ce soir-là, je n''avais pas cuisiné pour mes clients : j''avais cuisiné pour impressionner un seul homme. Depuis, ma carte ne change que lorsque mes plats sont prêts, pas lorsque ma vanité l''exige. Le critique est revenu l''an dernier. Je n''ai rien modifié pour lui, et c''est sans doute pour ça qu''il a aimé.

Quelle leçon Daniela tire-t-elle de cette soirée ratée ?

A. Les critiques gastronomiques jugent toujours les restaurants injustement.
B. Mieux vaut rester fidèle à sa cuisine que chercher à impressionner.
C. Il faut renouveler sa carte souvent pour surprendre les clients.
D. Un service important exige une brigade mieux entraînée.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je suis Daniela Costa, cheffe d''un restaurant à Biarritz. Le récit que je préfère raconter à mes apprentis n''est pas celui d''un succès. Il y a sept ans, un critique gastronomique réputé a réservé chez moi. J''ai voulu tellement bien faire que j''ai changé toute la carte la veille : des plats plus techniques, plus spectaculaires, que ma brigade n''avait jamais répétés. Le service a été un désastre : assiettes froides, cuissons ratées, quarante minutes d''attente. L''article a été cruel, et il était mérité. Pendant des semaines, j''ai voulu vendre le restaurant. Puis j''ai relu mes anciens menus, ceux qui remplissaient la salle, et j''ai compris que ce soir-là, je n''avais pas cuisiné pour mes clients : j''avais cuisiné pour impressionner un seul homme. Depuis, ma carte ne change que lorsque mes plats sont prêts, pas lorsque ma vanité l''exige. Le critique est revenu l''an dernier. Je n''ai rien modifié pour lui, et c''est sans doute pour ça qu''il a aimé.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle leçon Daniela tire-t-elle de cette soirée ratée ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Les critiques gastronomiques jugent toujours les restaurants injustement.<break time="700ms"/>B.<break time="300ms"/>Mieux vaut rester fidèle à sa cuisine que chercher à impressionner.<break time="700ms"/>C.<break time="300ms"/>Il faut renouveler sa carte souvent pour surprendre les clients.<break time="700ms"/>D.<break time="300ms"/>Un service important exige une brigade mieux entraînée.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La leçon n''est pas énoncée comme une morale : elle se déduit de l''opposition finale — « je n''avais pas cuisiné pour mes clients, j''avais cuisiné pour impressionner un seul homme », puis « ma carte ne change que lorsque mes plats sont prêts, pas lorsque ma vanité l''exige » — B synthétise cette **idée principale**. A contredit « l''article a été cruel, et il était mérité » : Daniela ne conteste pas le jugement du critique. C est l''exact contresens de sa conclusion : changer toute la carte la veille est précisément l''erreur racontée. D transforme un **détail secondaire** (la brigade prise au dépourvu) en leçon générale, alors que la cause profonde désignée par la cheffe est sa propre vanité — piège détail vs idée principale.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00c-1000-0000-000000000005', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Je m''appelle Karim Haddad, j''ai été marin-pêcheur à Sète pendant vingt-deux ans. Mon histoire a basculé un matin d''octobre, à quarante milles des côtes. Une vague a balayé le pont et emporté mon second, Ilyes. Nous l''avons repêché vivant, par miracle, après onze minutes dans une eau à quatorze degrés. Onze minutes, je les compte encore. Sur le moment, on s''est dit qu''on avait eu de la chance. Mais en rentrant au port, j''ai vérifié nos équipements : les gilets dataient de dix ans, le radeau n''avait pas été révisé, et personne à bord, moi compris, n''avait répété les gestes d''urgence depuis des années. Cette chance, justement, je ne voulais plus en dépendre. J''ai vendu mon bateau il y a cinq ans. Aujourd''hui, je passe mes journées dans les criées et sur les quais, et je fais répéter aux équipages les gestes que nous n''avions jamais répétés. Certains patrons me trouvent envahissant. Ilyes, lui, vient m''aider chaque hiver.

Quelle activité Karim exerce-t-il aujourd''hui ?

A. Il forme les équipages aux gestes de sécurité en mer.
B. Il vend du matériel de sauvetage aux patrons pêcheurs.
C. Il pêche toujours, mais avec un équipement entièrement révisé.
D. Il inspecte officiellement les bateaux pour l''administration maritime.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je m''appelle Karim Haddad, j''ai été marin-pêcheur à Sète pendant vingt-deux ans. Mon histoire a basculé un matin d''octobre, à quarante milles des côtes. Une vague a balayé le pont et emporté mon second, Ilyes. Nous l''avons repêché vivant, par miracle, après onze minutes dans une eau à quatorze degrés. Onze minutes, je les compte encore. Sur le moment, on s''est dit qu''on avait eu de la chance. Mais en rentrant au port, j''ai vérifié nos équipements : les gilets dataient de dix ans, le radeau n''avait pas été révisé, et personne à bord, moi compris, n''avait répété les gestes d''urgence depuis des années. Cette chance, justement, je ne voulais plus en dépendre. J''ai vendu mon bateau il y a cinq ans. Aujourd''hui, je passe mes journées dans les criées et sur les quais, et je fais répéter aux équipages les gestes que nous n''avions jamais répétés. Certains patrons me trouvent envahissant. Ilyes, lui, vient m''aider chaque hiver.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle activité Karim exerce-t-il aujourd''hui ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il forme les équipages aux gestes de sécurité en mer.<break time="700ms"/>B.<break time="300ms"/>Il vend du matériel de sauvetage aux patrons pêcheurs.<break time="700ms"/>C.<break time="300ms"/>Il pêche toujours, mais avec un équipement entièrement révisé.<break time="700ms"/>D.<break time="300ms"/>Il inspecte officiellement les bateaux pour l''administration maritime.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'L''activité actuelle n''est jamais nommée : elle se déduit d''indices — bateau vendu, journées « dans les criées et sur les quais », « je fais répéter aux équipages les gestes » d''urgence — A reformule cette **fonction de formateur à la sécurité**, mécanisme B2 d''**inférence de rôle**. B invente un commerce : Karim a constaté des équipements vétustes sur son propre bateau, rien n''indique qu''il en vende. C contredit la rupture du récit : il a « vendu son bateau il y a cinq ans », il ne pêche plus — piège pour qui rate le basculement chronologique. D surinterprète sa présence sur les quais : aucun mandat officiel n''est évoqué, et le fait que « certains patrons le trouvent envahissant » suggère justement qu''il n''a aucune autorité administrative.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00c-1000-0000-000000000006', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Je m''appelle Yuki Sato, je restaure des montres anciennes à Morteau, dans le Doubs. À vingt-trois ans, je suis arrivée du Japon avec mon diplôme d''horlogère et la certitude de tout savoir. Monsieur Vuillemin, l''artisan qui m''a embauchée, m''a installée à un établi et, pendant six mois, il ne m''a laissée que démonter, nettoyer et remonter les mêmes mécanismes, sans jamais toucher une pièce de client. Je trouvais cela humiliant ; j''ai failli partir deux fois. Le septième mois, il a posé devant moi un chronographe de mille neuf cent vingt-huit, la pièce la plus précieuse de l''atelier, et il est parti déjeuner sans un mot. Mes mains ont travaillé seules : chaque geste répété pendant ces six mois était exactement celui qu''il fallait. J''ai compris ce jour-là qu''il ne m''avait pas mise à l''écart : il effaçait patiemment mes mauvaises habitudes d''école. Quand j''ai pris la tête de l''atelier, à son départ en retraite, j''ai imposé les mêmes six mois à mon premier apprenti.

Comment Yuki juge-t-elle aujourd''hui ses six premiers mois à l''atelier ?

A. Une période humiliante qu''elle a simplement fini par pardonner.
B. Une perte de temps due à la méfiance d''un artisan âgé.
C. Une véritable formation qui a corrigé ses habitudes d''école.
D. Un test destiné à vérifier la valeur de son diplôme étranger.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je m''appelle Yuki Sato, je restaure des montres anciennes à Morteau, dans le Doubs. À vingt-trois ans, je suis arrivée du Japon avec mon diplôme d''horlogère et la certitude de tout savoir. Monsieur Vuillemin, l''artisan qui m''a embauchée, m''a installée à un établi et, pendant six mois, il ne m''a laissée que démonter, nettoyer et remonter les mêmes mécanismes, sans jamais toucher une pièce de client. Je trouvais cela humiliant ; j''ai failli partir deux fois. Le septième mois, il a posé devant moi un chronographe de mille neuf cent vingt-huit, la pièce la plus précieuse de l''atelier, et il est parti déjeuner sans un mot. Mes mains ont travaillé seules : chaque geste répété pendant ces six mois était exactement celui qu''il fallait. J''ai compris ce jour-là qu''il ne m''avait pas mise à l''écart : il effaçait patiemment mes mauvaises habitudes d''école. Quand j''ai pris la tête de l''atelier, à son départ en retraite, j''ai imposé les mêmes six mois à mon premier apprenti.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment Yuki juge-t-elle aujourd''hui ses six premiers mois à l''atelier ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une période humiliante qu''elle a simplement fini par pardonner.<break time="700ms"/>B.<break time="300ms"/>Une perte de temps due à la méfiance d''un artisan âgé.<break time="700ms"/>C.<break time="300ms"/>Une véritable formation qui a corrigé ses habitudes d''école.<break time="700ms"/>D.<break time="300ms"/>Un test destiné à vérifier la valeur de son diplôme étranger.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le jugement actuel s''oppose au ressenti d''époque : « je trouvais cela humiliant » (imparfait, point de vue passé) bascule avec « j''ai compris ce jour-là qu''il ne m''avait pas mise à l''écart : il effaçait patiemment mes mauvaises habitudes d''école » — C reformule cette **réévaluation rétrospective**, confirmée par le fait qu''elle impose les mêmes six mois à son propre apprenti. A reste bloquée sur le **ressenti initial** : il ne s''agit plus de pardonner, mais de reconnaître une méthode pédagogique. B contredit la conclusion : des gestes devenus « exactement ceux qu''il fallait » ne sont pas une perte de temps, et aucune méfiance n''est prêtée à l''artisan. D invente un test du diplôme : le but était de corriger les habitudes d''école, pas d''en vérifier l''authenticité.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 6 items, UUID déterministes 66666666-c00c-1000-0000-000000000001..06.
-- [x] Format C exclusif (co_document_question), récit professionnel long :
--     longueurs comptées = 149 / 152 / 145 / 158 / 157 / 162 mots
--     (toutes dans la fourchette 120-200 mots B2).
-- [x] 6 récits inventés, tous différents : reconversion comptable→boulanger
--     (Périgueux), premier jour d''une grutière (Le Havre), interprète passé
--     au médical (Lyon), service raté d''une cheffe (Biarritz), marin-pêcheur
--     devenu formateur sécurité (Sète), apprentissage d''une horlogère
--     (Morteau). Prénoms variés : Wei, Aminata, Pavlo, Daniela, Karim, Yuki.
--     Aucun thème interdit (pas d''organisme/service, pas de témoignage
--     d''opinion, pas de conseil d''expert, pas de présentation de produit).
-- [x] 4 propositions / 1 correcte par item ; distribution des bonnes réponses :
--     A, C, D, B, A, C → pos1 (A) ×2, pos2 (B) ×1, pos3 (C) ×2, pos4 (D) ×1 —
--     max 2 par position, 4 positions utilisées.
-- [x] Compréhension implicite B2 : cause réelle vs supposée, intention de la
--     locutrice, conséquence non dite, idée principale vs détail, inférence de
--     rôle, réévaluation rétrospective ; distracteurs tous plausibles (thème
--     vs propos, détail secondaire vs idée principale, inversion cause/effet).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse + les 3
--     distracteurs, point clé en **gras**, mécanisme linguistique nommé.
-- [x] SSML équilibré (4 <voice>/4 </voice>, 4 <prosody>/4 </prosody> par item),
--     pauses conformes (1500ms / 1000ms / 700ms / 300ms), voix Denise (0.95)
--     + Henri/Vivienne (1.0) en alternance, voice_recommended = voix du récit.
-- [x] status='TEXT_VALIDATED', toutes colonnes audio NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées partout, JSONB valide, contenu 100% original.
-- ============================================================================
