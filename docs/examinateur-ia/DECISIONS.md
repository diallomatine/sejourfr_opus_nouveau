# Décisions — Corrections examinateur IA

Brief : `docs/examinateur-ia/spec-corrections-examinateur-ia.md`. Audit de référence :
`docs/examinateur-ia/AUDIT_examinateur_IA.md`. Branche : `feat/examinateur-ia-v4`.

| Statut | Nombre |
|---|---|
| Validé (revue du 2026-10-09) | 23 |
| Tranché par le propriétaire (D-02, D-07, D-18) | 3 |
| Pris en charge par le propriétaire (D-27, D-28) | 2 |

---

## D-01 · [Phase 0] Chemin de l'audit de référence
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** le brief cite `docs/audits/AUDIT_examinateur_IA.md`, le rapport vit dans `docs/examinateur-ia/`.
- **Options envisagées :**
  - A. Déplacer l'audit vers `docs/audits/`
  - B. Laisser l'audit où il est (demande initiale : « même répertoire ») et lire le brief en conséquence
- **Décision :** B
- **Pourquoi :** c'est l'emplacement que tu as demandé à la première étape ; tous les livrables du chantier sont au même endroit.
- **Réversible ?** Oui (déplacement de fichier).
- **Fichiers :** aucun
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-02 · [Phase 0] Tests front demandés par le brief vs règle du dépôt
- **Statut :** Tranché par le propriétaire (revue du 2026-10-09)
- **Question :** le §4.4 demande des tests TypeScript et Dart de la logique de conduite ; le `CLAUDE.md` racine interdit tout NOUVEAU test front (« cette règle prime sur toute consigne de test écrite ailleurs », arbitrage du 2026-09-10).
- **Options envisagées :**
  - A. Ajouter des tests front versionnés (`*.test.ts`, `*_test.dart`)
  - B. Ne rien versionner : la logique de conduite est isolée dans un module PUR par front (aucun réseau, aucune horloge réelle), et les 9 cas du §4.4 sont exécutés par un script de vérification **jetable, hors dépôt**, sur les deux fronts ; le résultat est consigné dans le rapport
  - C. Tester la logique uniquement côté backend
- **Décision :** B
- **Pourquoi :** respecte la règle du dépôt sans renoncer à la vérification des cas ; si tu lèves la règle pour ce chantier, les scripts deviennent des tests versionnés en quelques minutes.
- **Réversible ?** Oui.
- **Fichiers :** `web_sejoufr/lib/realtime/conduct.ts`, `mobile_sejourfr/lib/core/realtime/realtime_conduct.dart` (modules purs)
- **Arbitrage :** « exception accordée pour ce chantier. Versionne les tests des modules purs `conduct.ts` et `realtime_conduct.dart` (les 9 cas du §4.4), et note l'exception dans CLAUDE.md. » → **A**, limitée aux 9 cas : `web_sejoufr/lib/realtime-conduct.test.ts` ⇄ `mobile_sejourfr/test/realtime_conduct_test.dart`, mêmes cas, mêmes noms. Exception notée dans le `CLAUDE.md` racine et dans ceux des deux fronts.
- **Ton avis :** ☐ OK  ☑ À changer → cf. « Arbitrage » ci-dessus

## D-03 · [Phase 0] Constats F01–F20 sur le HEAD
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** les constats sont-ils toujours valides ?
- **Options envisagées :** —
- **Décision :** branche créée depuis `develop` @ `ed65c6e3`, le commit même de l'audit : aucun fichier concerné n'a bougé, tous les constats et leurs lignes restent valides. Le plan n'est pas adapté.
- **Pourquoi :** vérifié par `git log ed65c6e3..HEAD` (vide) avant le premier changement.
- **Réversible ?** —
- **Fichiers :** —
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-04 · [Lot M] Stockage des tours horodatés
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** table dédiée ou colonne JSONB sur `realtime_sessions` ?
- **Options envisagées :**
  - A. Table `realtime_session_turns` — requêtes SQL simples, index possibles
  - B. JSONB — pas de nouvelle table, requêtes plus lourdes
- **Décision :** A. Une ligne par SEGMENT relayé (ce que le client envoie déjà : tours consécutifs d'un même locuteur fusionnés), avec `seq` (ordre serveur), `turn_index` (client, nullable), `speaker`, `text`, `word_count`, `started_at_ms`, `ended_at_ms` (nullables). Écrite dans la même transaction que l'ajout au transcript, après le même contrôle d'idempotence.
- **Pourquoi :** `indicateurs.sql` agrège par tour ; une table rend les requêtes lisibles. Le transcript texte reste la seule source de la notation, inchangé.
- **Réversible ?** Oui avant mise en prod ; ensuite migration nécessaire.
- **Fichiers :** `V090__realtime_mesure_examinateur.sql`, `RealtimeSessionTurn.java`, `RealtimeMesureManager.java`, `RealtimeSessionService.java`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-05 · [Lot M] Plateforme du client
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** comment connaître `client_platform` sans casser les anciens clients ?
- **Options envisagées :**
  - A. Nouveau champ `clientPlatform` dans `POST /sessions`
  - B. Réutiliser l'en-tête `X-Sejourfr-Client` que les deux fronts posent déjà sur TOUTES les requêtes (`ClientContextResolver`)
- **Décision :** B. Valeurs stockées : celles de l'enum existante `ClientPlatform` — `WEB`, `IOS`, `ANDROID`, plus `MOBILE` (anciennes apps qui ne distinguent pas le système) et `UNKNOWN` (en-tête absent).
- **Pourquoi :** aucune modification client, fonctionne déjà pour les apps en circulation, même convention que `user_login_event` (V087). `MOBILE`/`UNKNOWN` sont honnêtes : on ne devine pas le système.
- **Réversible ?** Oui.
- **Fichiers :** `RealtimeEoController.java`, `RealtimeSessionService.java`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-06 · [Lot M] Instant zéro et unité des horodatages
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** « relatifs à l'instant connected de la session » — quel instant, côté client ?
- **Options envisagées :**
  - A. La réception de `setupComplete` (socket réellement établi), première connexion
  - B. Le premier fragment relayé (ce que le serveur appelle `connected_at`)
- **Décision :** A, en millisecondes, horloge monotone (`performance.now()` web, `Stopwatch` mobile). Une reprise ne remet pas le zéro à zéro.
- **Pourquoi :** c'est l'instant observable le plus tôt et identique sur les deux fronts ; B dépend de la cadence du relais (1,2 s). L'écart entre les deux horloges n'importe pas : toutes les mesures sont des différences entre tours d'une même session.
- **Réversible ?** Oui (côté client seulement).
- **Fichiers :** `geminiLive.ts`, `gemini_live_client.dart`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-07 · [Lot M] Approximation des temps candidat
- **Statut :** Tranché par le propriétaire (revue du 2026-10-09)
- **Question :** quels instants pour le début et la fin d'un tour candidat ?
- **Options envisagées :**
  - A. Premier → dernier fragment `inputTranscription` du tour
  - B. Détection locale d'énergie du micro (disponible seulement au lot 2)
- **Décision :** A, et elle reste A après le lot 2.
- **Pourquoi :** c'est la meilleure approximation disponible au lot M, et la garder ensuite préserve la comparabilité avec la base de mesure du lot M. Biais connu, documenté dans les deux fronts : la transcription arrive avec un retard (début et fin décalés d'autant), donc le délai « fin candidat → début examinateur » est SOUS-estimé d'environ ce retard, de la même façon avant et après.
- **Réversible ?** Oui.
- **Fichiers :** `geminiLive.ts`, `gemini_live_client.dart`
- **Arbitrage :** « garde A comme mesure de référence, et ajoute à partir du lot 2 les temps candidat issus de la détection locale (`started_at_ms_vad`, `ended_at_ms_vad`, nullables) et l'indicateur correspondant dans `indicateurs.sql`. » → **A + B à côté.** V091 ajoute les deux colonnes ; `AppendTranscriptRequest` gagne `startedAtMsVad` / `endedAtMsVad` (facultatifs, ignorés sur un tour examinateur) ; les fronts les mesurent avec le détecteur local, ramenés à l'instant RÉEL de la transition (le début est confirmé 200 ms après le premier paquet au-dessus du seuil, la fin 600 ms après le dernier : le détecteur rend ce décalage, `sinceMs`) ; premier début et dernière fin du tour, fin = « maintenant » si le candidat parle encore à la clôture du tour. Indicateur 9 de `indicateurs.sql` : délai fin de parole mesurée au micro → reprise de l'examinateur (médiane, p90, part < 1,5 s), à lire à côté de l'indicateur 3.
- **Ton avis :** ☐ OK  ☑ À changer → cf. « Arbitrage » ci-dessus

## D-08 · [Lot M] Transport des événements de conduite et de la cause de fin
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** comment remonter `end_cause`, les relances, la grâce de fin de temps, les reprises ?
- **Options envisagées :**
  - A. Un endpoint d'événements dédié, appelé au fil de l'eau
  - B. Un corps OPTIONNEL sur `POST /sessions/{id}/finish` : `{endCause, events[]}` ; les reprises (avec ou sans handle) sont tracées par le SERVEUR, qui est le seul à savoir quel handle il a verrouillé
- **Décision :** B. Table `realtime_session_events` (`type`, `at_ms`, `value_ms`).
- **Pourquoi :** aucun aller-retour de plus ; `finish` est déjà idempotent et rejoué une fois. Limite assumée : une session jamais close (onglet fermé) perd ses événements client — elle reste visible par `end_cause IS NULL`.
- **Réversible ?** Oui.
- **Fichiers :** `FinishRealtimeSessionRequest.java`, `RealtimeEoController.java`, `RealtimeSessionService.java`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-09 · [Lot M] `end_cause = ERROR`
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** aujourd'hui, une erreur fatale (micro perdu…) laisse la session ouverte (`ACTIVE`/`PENDING`) sans jamais appeler `finish`. Comment la compter ?
- **Options envisagées :**
  - A. Les fronts appellent `finish` avec `endCause = ERROR` (sans attendre la réponse) ; le serveur clôt alors la session en `FAILED` **sans notation** (le candidat bascule de toute façon sur l'enregistrement classique : noter le dialogue créerait une seconde soumission)
  - B. Ne rien changer et compter les sessions jamais closes
- **Décision :** A.
- **Pourquoi :** comptable et sans effet visible ; le quota est un compteur débité à la connexion, le statut `FAILED` ne le rembourse ni ne le débite (vérifié dans `RealtimeQuotaService`).
- **Réversible ?** Oui.
- **Fichiers :** `RealtimeSessionService.java`, `RealtimeEoRunner.tsx`, `realtime_eo_controller.dart`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-10 · [Lot M] Traçage du repli asynchrone
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** ligne, statut ou log structuré ?
- **Options envisagées :**
  - A. Nouveau statut sur `realtime_sessions` — fausserait toutes les lectures qui comptent les sessions
  - B. Log structuré — pas comptable en SQL
  - C. Table `realtime_fallbacks` (`user_id`, tâche, `reason` : `QUOTA` / `NOT_CONFIGURED` / `MINT_FAILED` / `RESUME_MINT_FAILED`)
- **Décision :** C, supprimée en cascade avec le compte.
- **Pourquoi :** comptable sans toucher au sens de `realtime_sessions`.
- **Réversible ?** Oui.
- **Fichiers :** `V090__…sql`, `RealtimeSessionService.java`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-11 · [Lot M] Versionner les documents du chantier
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** le brief d'audit demandait un rapport « non commité » ; ce brief demande un commit par lot.
- **Options envisagées :**
  - A. Laisser `docs/examinateur-ia/` hors commits
  - B. Le versionner avec le lot M (briefs, audit, `indicateurs.sql`, `DECISIONS.md`, `RAPPORT_FINAL.md`), puis mettre à jour à chaque lot
- **Décision :** B
- **Pourquoi :** `indicateurs.sql` est exécuté par un test (`RealtimeMesureIT`) et doit voyager avec la migration ; le journal et le rapport doivent suivre les lots qu'ils décrivent. Rien n'est poussé.
- **Réversible ?** Oui (`git rm --cached`).
- **Fichiers :** `docs/examinateur-ia/*`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-12 · [Lot 1] Écart au texte cible v4 — ligne 7 du verrou de langue
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** la ligne 7 de la v3 contenait deux phrases en tension avec la nouvelle règle « NIVEAU DE LANGUE » : « tu n'adaptes pas ton niveau au candidat » (à remplacer, demandé) et « si le candidat peine, reformule ou simplifie ta phrase en français » (non mentionnée).
- **Options envisagées :**
  - A. Ne retirer que la première phrase et garder la seconde
  - B. Retirer les deux : la règle « tu reformules UNE fois, plus simplement » les remplace
- **Décision :** B. Ligne 7 v4 : « Parle exclusivement en français, un français authentique, clair et accessible (un niveau B2 doit suffire à te comprendre). Ne bascule JAMAIS vers une autre langue. » Lignes 8 à 10 reprises au caractère près (vérifié par `RealtimePersonaV4Test`).
- **Pourquoi :** garder « reformule ou simplifie » sans limite contredirait « UNE fois » et réintroduirait la contradiction F10.
- **Réversible ?** Oui (nouvelle version de persona).
- **Fichiers :** `prompts/realtime-personas-v4.json`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-13 · [Lot 1] Écart au texte cible v4 — articulation langue / « En français, s'il vous plaît »
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** comment garantir dans le texte que la phrase « En français, s'il vous plaît. » ne s'applique pas à un passage mal compris ?
- **Options envisagées :**
  - A. Texte du brief tel quel
  - B. Ajouter une parenthèse au cas prévu : « (Un passage que tu comprends mal n'entre PAS dans ce cas : c'est du français mal capté, demande de répéter.) »
- **Décision :** B. En outre, le titre de section « LANGUE DE L'ÉCHANGE — RÈGLES ABSOLUES » est devenu « FRANÇAIS UNIQUEMENT », pour ne pas doubler le titre de la ligne 8 de la v3, reprise telle quelle.
- **Pourquoi :** le brief exige que les deux règles ne se contredisent pas dans le texte final ; le modèle lit les cas prévus isolément, la précision doit y être.
- **Réversible ?** Oui.
- **Fichiers :** `prompts/realtime-personas-v4.json`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-14 · [Lot 1] Formulation de `{enteteExamen}`
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** le brief donne la valeur « Voici la deuxième partie. » ; injectée telle quelle avant « Entre dans ton rôle… », elle se lit comme une instruction ambiguë, pas comme une phrase à prononcer.
- **Options envisagées :**
  - A. « Voici la deuxième partie. » brut
  - B. « Dis d'abord : « Voici la deuxième partie. » Puis : » (chaîne `enteteExamen` du JSON v4)
- **Décision :** B. Ce que le candidat entend est inchangé : « Voici la deuxième partie. »
- **Pourquoi :** lever l'ambiguïté entre consigne et réplique.
- **Réversible ?** Oui.
- **Fichiers :** `prompts/realtime-personas-v4.json`, `RealtimePersonaTemplates.java`, `RealtimePersonaBuilder.java`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-15 · [Lot 1] Ce qu'est un « examen blanc » pour l'en-tête T2
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** tous les attempts de production sont de type `TRAINING` ; comment savoir qu'une T2 est jouée en examen blanc ?
- **Options envisagées :**
  - A. Un drapeau envoyé par le client
  - B. L'autorité serveur existante `ProductionAccessService.isExamSession(attempt)` (slot d'examen posé, ou sous-attempt d'un examen complet)
- **Décision :** B, pour l'ouverture et pour la reprise.
- **Pourquoi :** dérivé serveur, une seule autorité (celle des quotas d'examen) ; un client ancien n'a rien à envoyer.
- **Réversible ?** Oui.
- **Fichiers :** `RealtimeSessionService.java`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-16 · [Lot 1] JSON de conduite lié à la persona, et conduite « v0 » de retour arrière
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** les messages `[SILENCE]`, `[FIN]`, `[REPRISE]` n'ont de sens que pour la persona v4. Un retour à `REALTIME_PERSONA_VERSION=v3` enverrait `[FIN]` à une persona qui ne le connaît pas.
- **Options envisagées :**
  - A. JSON de conduite indépendant de la persona
  - B. Champ supplémentaire `personas` dans le JSON (versions pilotées), contrôlé au BOOT, plus un `realtime-conduct-v0.json` qui reproduit l'ancien comportement (message de fin d'avant, relance désactivée `maxConsecutive: 0`, pas de grâce `graceMaxMs: 0`, plafond de clôture 12 s, pas de message de reprise)
- **Décision :** B. Défauts : persona v4 + conduite v1 ; retour arrière : persona v3 + conduite v0. Un `message` vide désactive le mécanisme (au lieu de `null`, pour un typage simple des deux côtés).
- **Pourquoi :** une contrainte dure plutôt qu'une procédure à retenir ; même philosophie que les rubriques (une configuration incohérente échoue au démarrage).
- **Réversible ?** Oui.
- **Fichiers :** `prompts/realtime-conduct-v0.json`, `prompts/realtime-conduct-v1.json`, `RealtimeConductConfig.java`, `RealtimeProperties.java`, `application.yaml`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-17 · [Lot 1] Le plafond de clôture passe de 12 à 15 s
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** le JSON du brief fixe `closeMaxMs: 15000` ; le code utilisait 12 s.
- **Options envisagées :** A. garder 12 s · B. appliquer 15 s
- **Décision :** B, valeur du brief (v1) ; la v0 garde 12 s.
- **Pourquoi :** c'est un plafond de sécurité (l'examinateur ne conclut pas), rarement atteint ; 15 s laisse finir la phrase de clôture sur un réseau lent.
- **Réversible ?** Oui (JSON).
- **Fichiers :** `prompts/realtime-conduct-v1.json`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-18 · [Lot 1] Ouvertures T2 de plus de 35 mots
- **Statut :** Tranché par le propriétaire (revue du 2026-10-09)
- **Question :** quels sujets dépassent ?
- **Options envisagées :** —
- **Décision :** aucun. Sur les 20 sujets T2 actifs, l'ouverture en examen blanc (en-tête 4 mots + réplique d'entrée + « Je vous écoute. ») fait 12 à 25 mots. Verrouillé par `RealtimePersonaV4SujetsIT` sur les vrais sujets seedés. Remarque sans action : 5 répliques d'entrée finissent déjà par « je vous écoute » ou « je réponds à vos questions » ; l'examinateur dira alors deux fois « je vous écoute » (à raccourcir en données si la recette le confirme).
- **Pourquoi :** —
- **Réversible ?** —
- **Fichiers :** `RealtimePersonaV4SujetsIT.java`
- **Arbitrage :** « ajoute dans t2 de la persona v4 : « puis « Je vous écoute. », sauf si ta réplique d'entrée invite déjà le candidat à parler ». Mets à jour le test. » → fait dans `realtime-personas-v4.json` (v4 n'est pas encore livrée : pas de v5), `RealtimePersonaV4Test` vérifie la clause, `docs/notation-ia-eo-ee.md` suit.
- **Ton avis :** ☐ OK  ☑ À changer → cf. « Arbitrage » ci-dessus

## D-19 · [Lot 2] Borne de l'attente « l'examinateur finit sa phrase »
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** le brief dit « si l'examinateur parle à l'échéance, attendre la fin de sa lecture », sans borne.
- **Options envisagées :** A. attente illimitée · B. attente bornée par `timeUp.graceMaxMs` (10 s)
- **Décision :** B. Au-delà, `[FIN]` part quand même.
- **Pourquoi :** une lecture qui ne se termine jamais (événement de fin perdu) ne doit pas retenir la clôture ; même borne que la phrase du candidat, aucune valeur de plus dans le JSON.
- **Réversible ?** Oui.
- **Fichiers :** `conduct.ts`, `realtime_conduct.dart`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-20 · [Lot 2] Conduite v0 = coupure immédiate
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** que fait la fin de temps quand la conduite ne prévoit aucune grâce (`graceMaxMs: 0`, conduite v0) ?
- **Options envisagées :** A. appliquer quand même l'attente de l'examinateur · B. reproduire exactement l'ancien comportement : micro coupé et message envoyé tout de suite
- **Décision :** B.
- **Pourquoi :** la v0 existe pour le retour arrière ; elle doit rendre le comportement d'avant, pas un mélange.
- **Réversible ?** Oui.
- **Fichiers :** `conduct.ts`, `realtime_conduct.dart`, `realtime-conduct-v0.json`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-21 · [Lot 2] Quand le minuteur de relance démarre
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** faut-il aussi relancer quand le candidat a parlé puis s'est tu sans que l'examinateur ne réponde ?
- **Options envisagées :** A. minuteur armé aussi à la fin de la parole du candidat · B. minuteur armé seulement à la fin de la lecture de l'examinateur (texte du brief)
- **Décision :** B.
- **Pourquoi :** c'est le texte du brief ; après une prise de parole, c'est à l'examinateur de répondre (VAD serveur, 1,5 s) — une relance par-dessus créerait une double prise de parole. À revoir si la recette montre des silences après une réponse du candidat.
- **Réversible ?** Oui (une ligne dans les deux modules).
- **Fichiers :** `conduct.ts`, `realtime_conduct.dart`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-22 · [Lot 2] Course « le candidat commence à parler à l'instant où la relance part »
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** comment empêcher la relance de partir pendant les 200 ms où une prise de parole n'est pas encore confirmée (`minSpeechMs`) ?
- **Options envisagées :** A. ne regarder que la parole confirmée · B. regarder aussi l'énergie du DERNIER paquet micro (`candidateEnergyNow`) au moment où le minuteur expire
- **Décision :** B. Si l'énergie est au-dessus du seuil, la relance est abandonnée (pas reportée) ; le minuteur sera réarmé à la prochaine fin de parole de l'examinateur. Le même test sert à la fin de temps : un candidat qui démarre sa phrase à 0:00 obtient sa grâce.
- **Pourquoi :** le pire cas (parler par-dessus le candidat) est exactement ce que l'audit reproche ; un bruit annule au pire une relance, sans gravité (biais assumé par le brief).
- **Réversible ?** Oui.
- **Fichiers :** `conduct.ts`, `realtime_conduct.dart`, `geminiLive.ts`, `gemini_live_client.dart`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-23 · [Lot 2] La détection locale ne lit que ce qui serait émis
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** faut-il mesurer l'énergie du micro pendant que l'examinateur parle ?
- **Options envisagées :** A. toujours · B. seulement quand le micro serait émis (pas pendant la lecture de l'examinateur ni ses 120 ms de tenue, ni avant l'accueil, ni après `[FIN]`) ; ailleurs le détecteur est remis à zéro
- **Décision :** B.
- **Pourquoi :** pendant la lecture, le micro capte surtout l'écho résiduel ; le compter comme parole annulerait les relances et ouvrirait des grâces à tort. Cohérent avec le half-duplex, hors périmètre de ce chantier.
- **Réversible ?** Oui.
- **Fichiers :** `geminiLive.ts`, `gemini_live_client.dart`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-24 · [Lot 2] Le temps restant se lit à l'instant voulu
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** le chrono ne bat qu'une fois par seconde ; « pas de relance dans les 15 dernières secondes » se lisait au dernier tic.
- **Options envisagées :** A. dernier tic · B. reste = dernier tic − temps écoulé depuis ; et une relance qui TOMBERAIT dans les 15 dernières secondes n'est pas armée du tout
- **Décision :** B (trouvé par la vérification des cas : la version A laissait partir une relance à 13 s de la fin).
- **Pourquoi :** exactitude ; aucune valeur nouvelle.
- **Réversible ?** Oui.
- **Fichiers :** `conduct.ts`, `realtime_conduct.dart`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-25 · [Lot 2] Qui sait qu'une reprise est « sans handle »
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** le client peut-il décider seul qu'il faut `[REPRISE]` ?
- **Options envisagées :** A. le client regarde s'il possède un handle · B. le serveur le dit : `RealtimeSessionDescriptor.contextRestored` (champ additif, nul à l'ouverture), vrai seulement quand il a verrouillé un handle dans le token de reprise
- **Décision :** B.
- **Pourquoi :** dérivé serveur, une seule autorité — c'est le serveur qui verrouille le handle et trace `RESUME_WITH/WITHOUT_HANDLE`. Un client ancien ignore le champ.
- **Réversible ?** Oui.
- **Fichiers :** `RealtimeSessionDescriptor.java`, `RealtimeSessionService.java`, `lib/types.ts`, `realtime_models.dart`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-26 · [Lot 2] Forme du tour `[REPRISE]`
- **Statut :** Validé (revue du 2026-10-09)
- **Question :** comment transmettre les 3 derniers tours ?
- **Options envisagées :** A. trois tours de dialogue rejoués · B. un seul tour texte : `[REPRISE]` puis une ligne par tour, `Examinateur : …` / `Candidat : …` (le format du transcript)
- **Décision :** B, envoyé dès l'établissement du nouveau socket, à la place de l'amorce « Bonjour. ». Rien n'est envoyé si la conduite désactive la reprise (message vide).
- **Pourquoi :** un tour unique ne peut pas être pris pour plusieurs prises de parole ; le format est celui que le modèle connaît déjà par la persona.
- **Réversible ?** Oui.
- **Fichiers :** `conduct.ts` (`resumePrimer`), `realtime_conduct.dart`, `geminiLive.ts`, `gemini_live_client.dart`
- **Ton avis :** ☑ OK  ☐ À changer → …

## D-27 · [Lot 2] Recette réelle et mesures avant/après
- **Statut :** Pris en charge par le propriétaire (revue du 2026-10-09)
- **Question :** les comportements du lot 1 (persona v4, 1,5 s) et du lot 2 (grâce, relance, reprise) ne se valident qu'avec de vraies sessions Gemini Live, et le seuil d'énergie (0,02) doit être calibré sur web, Android et iOS.
- **Options envisagées :** —
- **Décision :** rien n'a été ouvert (aucune session Gemini, aucun appel payant). Le protocole et la grille sont prêts dans `RECETTE.md` ; la mesure avant/après se fait avec `indicateurs.sql` une fois le lot M déployé seul.
- **Pourquoi :** règle du brief et du dépôt.
- **Réversible ?** —
- **Fichiers :** `RECETTE.md`, `indicateurs.sql`
- **Ton avis :** « je m'en charge »

## D-28 · [Final] Push, merge et variables de production
- **Statut :** Pris en charge par le propriétaire (revue du 2026-10-09)
- **Question :** les trois commits sont locaux ; les variables d'environnement de production ne sont pas connues (Q1).
- **Options envisagées :** —
- **Décision :** rien n'est poussé ni fusionné. La liste des variables à poser/vérifier sur le VPS est dans `RAPPORT_FINAL.md` ; ordre conseillé : déployer le lot M seul (mesure de base), puis le lot 1, puis le lot 2, chacun après sa recette.
- **Pourquoi :** règle du brief.
- **Réversible ?** —
- **Fichiers :** —
- **Ton avis :** « je m'en charge »
