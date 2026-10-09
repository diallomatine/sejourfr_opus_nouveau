# Décisions — Corrections examinateur IA

Brief : `docs/examinateur-ia/spec-corrections-examinateur-ia.md`. Audit de référence :
`docs/examinateur-ia/AUDIT_examinateur_IA.md`. Branche : `feat/examinateur-ia-v4`.

| Statut | Nombre |
|---|---|
| À valider | 0 |
| Bloqué — nécessite ton accord | 0 |

---

## D-01 · [Phase 0] Chemin de l'audit de référence
- **Statut :** À valider
- **Question :** le brief cite `docs/audits/AUDIT_examinateur_IA.md`, le rapport vit dans `docs/examinateur-ia/`.
- **Options envisagées :**
  - A. Déplacer l'audit vers `docs/audits/`
  - B. Laisser l'audit où il est (demande initiale : « même répertoire ») et lire le brief en conséquence
- **Décision :** B
- **Pourquoi :** c'est l'emplacement que tu as demandé à la première étape ; tous les livrables du chantier sont au même endroit.
- **Réversible ?** Oui (déplacement de fichier).
- **Fichiers :** aucun
- **Ton avis :** ☐ OK  ☐ À changer → …

## D-02 · [Phase 0] Tests front demandés par le brief vs règle du dépôt
- **Statut :** À valider
- **Question :** le §4.4 demande des tests TypeScript et Dart de la logique de conduite ; le `CLAUDE.md` racine interdit tout NOUVEAU test front (« cette règle prime sur toute consigne de test écrite ailleurs », arbitrage du 2026-09-10).
- **Options envisagées :**
  - A. Ajouter des tests front versionnés (`*.test.ts`, `*_test.dart`)
  - B. Ne rien versionner : la logique de conduite est isolée dans un module PUR par front (aucun réseau, aucune horloge réelle), et les 9 cas du §4.4 sont exécutés par un script de vérification **jetable, hors dépôt**, sur les deux fronts ; le résultat est consigné dans le rapport
  - C. Tester la logique uniquement côté backend
- **Décision :** B
- **Pourquoi :** respecte la règle du dépôt sans renoncer à la vérification des cas ; si tu lèves la règle pour ce chantier, les scripts deviennent des tests versionnés en quelques minutes.
- **Réversible ?** Oui.
- **Fichiers :** `web_sejoufr/lib/realtime/conduct.ts`, `mobile_sejourfr/lib/core/realtime/realtime_conduct.dart` (modules purs)
- **Ton avis :** ☐ OK  ☐ À changer → …

## D-03 · [Phase 0] Constats F01–F20 sur le HEAD
- **Statut :** À valider
- **Question :** les constats sont-ils toujours valides ?
- **Options envisagées :** —
- **Décision :** branche créée depuis `develop` @ `ed65c6e3`, le commit même de l'audit : aucun fichier concerné n'a bougé, tous les constats et leurs lignes restent valides. Le plan n'est pas adapté.
- **Pourquoi :** vérifié par `git log ed65c6e3..HEAD` (vide) avant le premier changement.
- **Réversible ?** —
- **Fichiers :** —
- **Ton avis :** ☐ OK  ☐ À changer → …

## D-04 · [Lot M] Stockage des tours horodatés
- **Statut :** À valider
- **Question :** table dédiée ou colonne JSONB sur `realtime_sessions` ?
- **Options envisagées :**
  - A. Table `realtime_session_turns` — requêtes SQL simples, index possibles
  - B. JSONB — pas de nouvelle table, requêtes plus lourdes
- **Décision :** A. Une ligne par SEGMENT relayé (ce que le client envoie déjà : tours consécutifs d'un même locuteur fusionnés), avec `seq` (ordre serveur), `turn_index` (client, nullable), `speaker`, `text`, `word_count`, `started_at_ms`, `ended_at_ms` (nullables). Écrite dans la même transaction que l'ajout au transcript, après le même contrôle d'idempotence.
- **Pourquoi :** `indicateurs.sql` agrège par tour ; une table rend les requêtes lisibles. Le transcript texte reste la seule source de la notation, inchangé.
- **Réversible ?** Oui avant mise en prod ; ensuite migration nécessaire.
- **Fichiers :** `V090__realtime_mesure_examinateur.sql`, `RealtimeSessionTurn.java`, `RealtimeMesureManager.java`, `RealtimeSessionService.java`
- **Ton avis :** ☐ OK  ☐ À changer → …

## D-05 · [Lot M] Plateforme du client
- **Statut :** À valider
- **Question :** comment connaître `client_platform` sans casser les anciens clients ?
- **Options envisagées :**
  - A. Nouveau champ `clientPlatform` dans `POST /sessions`
  - B. Réutiliser l'en-tête `X-Sejourfr-Client` que les deux fronts posent déjà sur TOUTES les requêtes (`ClientContextResolver`)
- **Décision :** B. Valeurs stockées : celles de l'enum existante `ClientPlatform` — `WEB`, `IOS`, `ANDROID`, plus `MOBILE` (anciennes apps qui ne distinguent pas le système) et `UNKNOWN` (en-tête absent).
- **Pourquoi :** aucune modification client, fonctionne déjà pour les apps en circulation, même convention que `user_login_event` (V087). `MOBILE`/`UNKNOWN` sont honnêtes : on ne devine pas le système.
- **Réversible ?** Oui.
- **Fichiers :** `RealtimeEoController.java`, `RealtimeSessionService.java`
- **Ton avis :** ☐ OK  ☐ À changer → …

## D-06 · [Lot M] Instant zéro et unité des horodatages
- **Statut :** À valider
- **Question :** « relatifs à l'instant connected de la session » — quel instant, côté client ?
- **Options envisagées :**
  - A. La réception de `setupComplete` (socket réellement établi), première connexion
  - B. Le premier fragment relayé (ce que le serveur appelle `connected_at`)
- **Décision :** A, en millisecondes, horloge monotone (`performance.now()` web, `Stopwatch` mobile). Une reprise ne remet pas le zéro à zéro.
- **Pourquoi :** c'est l'instant observable le plus tôt et identique sur les deux fronts ; B dépend de la cadence du relais (1,2 s). L'écart entre les deux horloges n'importe pas : toutes les mesures sont des différences entre tours d'une même session.
- **Réversible ?** Oui (côté client seulement).
- **Fichiers :** `geminiLive.ts`, `gemini_live_client.dart`
- **Ton avis :** ☐ OK  ☐ À changer → …

## D-07 · [Lot M] Approximation des temps candidat
- **Statut :** À valider
- **Question :** quels instants pour le début et la fin d'un tour candidat ?
- **Options envisagées :**
  - A. Premier → dernier fragment `inputTranscription` du tour
  - B. Détection locale d'énergie du micro (disponible seulement au lot 2)
- **Décision :** A, et elle reste A après le lot 2.
- **Pourquoi :** c'est la meilleure approximation disponible au lot M, et la garder ensuite préserve la comparabilité avec la base de mesure du lot M. Biais connu, documenté dans les deux fronts : la transcription arrive avec un retard (début et fin décalés d'autant), donc le délai « fin candidat → début examinateur » est SOUS-estimé d'environ ce retard, de la même façon avant et après.
- **Réversible ?** Oui.
- **Fichiers :** `geminiLive.ts`, `gemini_live_client.dart`
- **Ton avis :** ☐ OK  ☐ À changer → …

## D-08 · [Lot M] Transport des événements de conduite et de la cause de fin
- **Statut :** À valider
- **Question :** comment remonter `end_cause`, les relances, la grâce de fin de temps, les reprises ?
- **Options envisagées :**
  - A. Un endpoint d'événements dédié, appelé au fil de l'eau
  - B. Un corps OPTIONNEL sur `POST /sessions/{id}/finish` : `{endCause, events[]}` ; les reprises (avec ou sans handle) sont tracées par le SERVEUR, qui est le seul à savoir quel handle il a verrouillé
- **Décision :** B. Table `realtime_session_events` (`type`, `at_ms`, `value_ms`).
- **Pourquoi :** aucun aller-retour de plus ; `finish` est déjà idempotent et rejoué une fois. Limite assumée : une session jamais close (onglet fermé) perd ses événements client — elle reste visible par `end_cause IS NULL`.
- **Réversible ?** Oui.
- **Fichiers :** `FinishRealtimeSessionRequest.java`, `RealtimeEoController.java`, `RealtimeSessionService.java`
- **Ton avis :** ☐ OK  ☐ À changer → …

## D-09 · [Lot M] `end_cause = ERROR`
- **Statut :** À valider
- **Question :** aujourd'hui, une erreur fatale (micro perdu…) laisse la session ouverte (`ACTIVE`/`PENDING`) sans jamais appeler `finish`. Comment la compter ?
- **Options envisagées :**
  - A. Les fronts appellent `finish` avec `endCause = ERROR` (sans attendre la réponse) ; le serveur clôt alors la session en `FAILED` **sans notation** (le candidat bascule de toute façon sur l'enregistrement classique : noter le dialogue créerait une seconde soumission)
  - B. Ne rien changer et compter les sessions jamais closes
- **Décision :** A.
- **Pourquoi :** comptable et sans effet visible ; le quota est un compteur débité à la connexion, le statut `FAILED` ne le rembourse ni ne le débite (vérifié dans `RealtimeQuotaService`).
- **Réversible ?** Oui.
- **Fichiers :** `RealtimeSessionService.java`, `RealtimeEoRunner.tsx`, `realtime_eo_controller.dart`
- **Ton avis :** ☐ OK  ☐ À changer → …

## D-10 · [Lot M] Traçage du repli asynchrone
- **Statut :** À valider
- **Question :** ligne, statut ou log structuré ?
- **Options envisagées :**
  - A. Nouveau statut sur `realtime_sessions` — fausserait toutes les lectures qui comptent les sessions
  - B. Log structuré — pas comptable en SQL
  - C. Table `realtime_fallbacks` (`user_id`, tâche, `reason` : `QUOTA` / `NOT_CONFIGURED` / `MINT_FAILED` / `RESUME_MINT_FAILED`)
- **Décision :** C, supprimée en cascade avec le compte.
- **Pourquoi :** comptable sans toucher au sens de `realtime_sessions`.
- **Réversible ?** Oui.
- **Fichiers :** `V090__…sql`, `RealtimeSessionService.java`
- **Ton avis :** ☐ OK  ☐ À changer → …

## D-11 · [Lot M] Versionner les documents du chantier
- **Statut :** À valider
- **Question :** le brief d'audit demandait un rapport « non commité » ; ce brief demande un commit par lot.
- **Options envisagées :**
  - A. Laisser `docs/examinateur-ia/` hors commits
  - B. Le versionner avec le lot M (briefs, audit, `indicateurs.sql`, `DECISIONS.md`, `RAPPORT_FINAL.md`), puis mettre à jour à chaque lot
- **Décision :** B
- **Pourquoi :** `indicateurs.sql` est exécuté par un test (`RealtimeMesureIT`) et doit voyager avec la migration ; le journal et le rapport doivent suivre les lots qu'ils décrivent. Rien n'est poussé.
- **Réversible ?** Oui (`git rm --cached`).
- **Fichiers :** `docs/examinateur-ia/*`
- **Ton avis :** ☐ OK  ☐ À changer → …
