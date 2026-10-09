# Audit de l'examinateur IA — TCF IRN · Expression orale (temps réel)

> **Audit en lecture seule**, mené le **2026-10-09** sur `develop` (`ed65c6e3`).
> Brief : `docs/examinateur-ia/spec-audit-examinateur-ia.md`.
> Aucun fichier de code, prompt, configuration ou base n'a été modifié. Aucun commit.
> **Aucune session Gemini Live ouverte**, aucun appel payant. Mesures par `SELECT` sur la
> base locale `sejourfr_db`, script jetable hors dépôt.
> Audit voisin, à lire en complément (notation, pas conduite) : `docs/audit/AUDIT_EO.md` (2026-09-21).

---

## 0. Verdict en cinq lignes

1. **Le principal défaut n'est pas dans le prompt.** L'examinateur reprend la parole après
   **500 ms de silence** (`silenceDurationMs`), alors que la cible de fin de tour est
   ≈ 1,5–2,5 s (C9a). Sur un apprenant qui cherche ses mots, c'est le mécanisme qui lui
   « prend la place ». Aucun mot du prompt (« Ne réponds qu'après un vrai silence ») ne peut
   le corriger : le modèle ne décide pas quand le tour du candidat finit, la VAD décide.
2. **Il n'existe aucun mécanisme de relance sur silence (C9b).** Ni minuteur client, ni
   VAD : si le candidat se tait, l'examinateur se tait aussi. Les consignes « silence
   prolongé → relance douce » du prompt sont inatteignables.
3. **À 0:00, le micro du candidat est coupé net**, en pleine phrase (C10/S12).
4. **Le prompt T2 interdit à l'examinateur toute initiative** (« tu ne mènes pas »), à
   rebours du référentiel (« n'est pas passif ») — et rien ne le relance en cas de blanc.
5. **Rien ne permet de mesurer la qualité en secondes** : la transcription n'a aucun
   horodatage par tour. En **mots**, sur un petit échantillon interne (§6), l'examinateur
   dit **~39 % des mots en T1** (cible ≤ 25 %) et **~57 % en T2** (cible officielle ≤ 33 %),
   et 18 % de ses répliques T1 sont des appréciations (« C'est un très beau projet »).

L'hypothèse du brief « une seule session de 10 min, transitions injectées » est
**infirmée** : il y a **une session Gemini par tâche**, et **seules T1 et T2** ont un
examinateur ; **T3 est un enregistrement solo**, sans examinateur.

---

## 1. Cartographie

### 1.1 Fichiers concernés

| Couche | Backend | Web | Mobile |
|---|---|---|---|
| Prompt (persona) | `backend_sejourfr/src/main/resources/prompts/realtime-personas-v3.json` (v1, v2 conservées) · `service/realtime/RealtimePersonaTemplates.java` (chargement) · `service/realtime/RealtimePersonaBuilder.java` (assemblage) | — | — |
| Config fournisseur | `config/RealtimeProperties.java` · `application.yaml:1129-1243` · `service/realtime/GeminiTokenBroker.java` (setup verrouillé dans le token) | — | — |
| Orchestration session | `service/realtime/RealtimeSessionService.java` · `controller/RealtimeEoController.java` | `app/_components/production/RealtimeEoRunner.tsx` (chrono, clôture, reprise, relais) · `useRealtimeEo.ts` · `ProductionSession.tsx` (enchaînement des tâches d'examen) | `screens/tcf_production/realtime/realtime_eo_controller.dart` · `realtime_eo_screen.dart` · `realtime_launch*.dart` |
| Protocole WS + audio | — | `lib/realtime/geminiLive.ts` | `lib/core/realtime/gemini_live_client.dart` |
| Transcription → notation | `RealtimeSessionService.appendTranscript/finish` · `ProductionEvaluationService.evaluateRealtimeTranscript:249` · `ProductionValidityService` (tours `Candidat :`) · `EvaluationOralArtifactFilter` | relais dans `RealtimeEoRunner.tsx:200-258` | relais dans `realtime_eo_controller.dart:436-510` |
| Persistance | `realtime_sessions` (V016, V032) · `production_submissions` (`source = REALTIME`) · `transcriptions` (`modele_utilise = 'realtime'`) | — | — |

Les deux fronts sont **en parité** sur tout ce qui touche à la conduite : même half-duplex,
même amorce « Bonjour. », même message de fin de temps (miroir déclaré), mêmes délais
(1 200 ms de repos, 12 s de plafond, relais 1 200 ms, tenue micro 120 ms).

### 1.2 Déroulé d'une session (identique web / mobile)

```
Candidat choisit « avec un examinateur » sur T1 ou T2 (T3 : enregistrement seul)
  │
  ├─ POST /api/realtime/eo/sessions ─────────────────────────────── backend
  │     RealtimeSessionService.start:70
  │       ├─ tâche TCF_EO n°1 ou 2, sinon 422                         (:73-79)
  │       ├─ quota / clé absente → ASYNC_FALLBACK (enregistrement solo) (:91-94)
  │       ├─ persona = règles communes + gabarit T1 ou T2 (+ fiche T2)  RealtimePersonaBuilder.build:53
  │       └─ GeminiTokenBroker.mint : token éphémère CONTRAINT qui verrouille
  │            modèle, AUDIO, voix, température, systemInstruction, VAD,
  │            transcription in/out, reprise, compression       (:134-185)
  │
  ├─ client : micro d'abord (AEC/NS/AGC), puis WebSocket ; setup minimal {model}
  │     setupComplete → envoi d'un tour texte « Bonjour. » (amorce)   geminiLive.ts:446 · dart:784
  │     micro COUPÉ jusqu'au 1er audio examinateur (garde-fou 8 s)
  │
  ├─ 1er audio examinateur → état « live » → le CHRONO démarre        RealtimeEoRunner.tsx:446-455 · controller:255-263
  │
  ├─ boucle d'échange
  │     micro → PCM16 16 kHz par paquets de 40 ms → realtimeInput.audio
  │       SAUF pendant que l'examinateur parle + 120 ms (HALF-DUPLEX) geminiLive.ts:505-520 · dart:637-656
  │     VAD SERVEUR Gemini : fin de tour candidat après 500 ms de silence
  │     modèle répond (audio 24 kHz + outputTranscription)
  │     turnComplete → 1 ligne « Candidat » puis 1 ligne « Examinateur »
  │     relais toutes les 1,2 s → POST /sessions/{id}/transcript (turnIndex idempotent)
  │       → realtime_sessions.transcript += "Candidat : …" / "Examinateur : …"
  │
  ├─ chrono ≥ durée de la tâche (T1 180 s, T2 210 s)
  │     micro candidat COUPÉ immédiatement + tour texte
  │     « [Le temps de cette partie est écoulé. Remerciez brièvement le candidat et concluez maintenant.] »
  │     clôture quand l'examinateur a parlé puis s'est tu 1,2 s, plafond 12 s
  │
  ├─ coupure réseau → chrono en pause → POST /sessions/{id}/resume (nouveau token
  │     portant le dernier handle) → même socket client rouvert ; ≤ 3 reprises
  │
  └─ POST /sessions/{id}/finish → COMPLETED → submission REALTIME
        → transcription = dialogue complet → notation Claude (tours Candidat isolés côté serveur)

Examen blanc : T1 (session 1) → T2 (session 2, nouvelle persona, aucune mémoire de T1)
               → T3 (enregistrement solo, pas d'examinateur)
```

**Qui déclenche les transitions ?** Uniquement le **client** (minuteur local). Le modèle
n'a aucune notion du temps : il ne reçoit qu'un tour texte à l'échéance. Le serveur n'oppose
aucune durée (déjà relevé en D6 de `AUDIT_EO.md`). Il n'y a pas de transition T1→T2 dans
une même session : chaque tâche est une session distincte, ouverte par le candidat.

---

## 2. Configuration effective

Valeurs par défaut du dépôt. ⚠️ Les variables d'environnement de **production** ne sont pas
dans le dépôt : seule la valeur du modèle en **dev** est connue (`.env:183`). Voir Q1.

| Paramètre | Valeur | Fichier:ligne | En dur / externalisé |
|---|---|---|---|
| Modèle | `gemini-live-2.5-flash-native-audio` (défaut) · **dev : `gemini-2.5-flash-native-audio-latest`** | `application.yaml:1166` · `RealtimeProperties.java:76` · `backend_sejourfr/.env:183` | env `REALTIME_GEMINI_MODEL` |
| Type de modèle | audio **natif** (pas half-cascade) | idem | — |
| Endpoint | `…v1alpha…BidiGenerateContentConstrained` | `application.yaml:1158` | yaml |
| Voix | `Aoede` | `application.yaml:1167` | env `REALTIME_GEMINI_VOICE` |
| Température | **0.7** | `application.yaml:1168` · `RealtimeProperties.java:78` | **en dur dans le yaml** (pas de variable d'env) |
| `maxOutputTokens` | **absent** | `GeminiTokenBroker.java:137-144` | — |
| Proactivité / dialogue affectif | **absents** | idem | — |
| Persona | `v3` (yaml) · **`v1` (défaut du POJO)** | `application.yaml:1151` · `RealtimeProperties.java:30` | env `REALTIME_PERSONA_VERSION` |
| VAD `disabled` | `false` | `application.yaml:1191` | env |
| VAD `startOfSpeechSensitivity` | `START_SENSITIVITY_HIGH` | `application.yaml:1192` · `RealtimeProperties.java:187` | env |
| VAD `endOfSpeechSensitivity` | `END_SENSITIVITY_LOW` | `application.yaml:1193` · `RealtimeProperties.java:188` | env |
| VAD `prefixPaddingMs` | 300 | `application.yaml:1194` | env |
| **VAD `silenceDurationMs`** | **500** — une seule valeur pour tous les niveaux | `application.yaml:1195` · `RealtimeProperties.java:196` | env `REALTIME_GEMINI_VAD_SILENCE_DURATION_MS` |
| `activityHandling` (barge-in serveur) | **non posé** → défaut fournisseur | `GeminiTokenBroker.java:194-202` | — |
| `turnCoverage` | non posé | idem | — |
| Transcription entrée / sortie | activées (`{}`), sans langue (l'API n'en accepte pas) | `GeminiTokenBroker.java:154-155` | en dur |
| Reprise de session | activée, 3 reprises max | `application.yaml:1205-1206` | env |
| Compression de contexte | 25 600 → 12 800 tokens | `application.yaml:1214-1216` | env |
| Token : usages / ouverture / vie | 3 / 600 s / 1 800 s | `application.yaml:1223-1229` | env |
| Audio entrée / sortie | PCM 16 kHz / 24 kHz | `application.yaml:1233-1235` | yaml |
| Durée T1 / T2 | 180 s / 210 s (base : `production_tasks.duree_max_sec`) | données ; repli client 180 s `RealtimeEoRunner.tsx:50` · `controller:164` | base |
| Amorce d'accueil | tour texte « Bonjour. » | `geminiLive.ts:446-454` · `gemini_live_client.dart:784-798` | **en dur ×2** (miroirs) |
| Garde-fou d'accueil | 8 s | `geminiLive.ts:390` · `gemini_live_client.dart:57` | en dur ×2 |
| Paquet micro | 40 ms (web) / 1 280 (Android 40 ms, iOS ≈ 27 ms) | `geminiLive.ts:28` · `dart:28` | en dur |
| Half-duplex : tenue micro après l'examinateur | 120 ms | `geminiLive.ts:50` · `dart:50` | en dur ×2 |
| Annulation d'écho | web `echoCancellation/noiseSuppression/autoGainControl: true` · mobile `echoCancel/noiseSuppress/autoGain: true` + iOS `voiceChat` / Android `voiceCommunication` | `geminiLive.ts:465-467` · `dart:627-631, 812-830` | en dur |
| Message de fin de temps | « [Le temps de cette partie est écoulé. Remerciez brièvement le candidat et concluez maintenant.] » | `geminiLive.ts:677` · `gemini_live_client.dart:63-65` | en dur ×2 (miroirs) |
| Repos avant clôture / plafond | 1 200 ms / 12 s | `RealtimeEoRunner.tsx:32-33` · `controller:151, 155` | en dur ×2 |
| Relance sur silence (C9b) | **inexistante** | — | — |

**Constat de configuration.** Les réglages **serveur** (VAD, modèle, reprise) sont
externalisés et surchargeables sans recompilation — c'est un acquis. Les réglages de
**conduite côté client** (fin de temps, amorce, clôture, half-duplex) sont en dur, en double,
tenus en parité par commentaire. Il n'existe pas de « JSON versionné de conduite » qui
regrouperait durées, seuils et messages.

---

## 3. Prompts

### 3.1 Assemblage

`RealtimePersonaBuilder.build` (`:53-62`) :

```
systemInstruction = regles(dureeSec)  +  "\n\n"  +  ( tâche 2 ? t2(contexte, consigne) + fiche : t1 )
```

- `{dureeSec}` = `production_tasks.duree_max_sec` (repli 180).
- T2 : `{contexte}` = rôle joué par l'examinateur, `{consigne}` = situation du candidat ;
  `{ficheScenario}` remplacé par le bloc `t2Fiche` rempli depuis
  `production_tasks.agent_role_card` (les 20 sujets T2 actifs en ont une ; aucun T1).
- Le prompt est **verrouillé dans le token** à l'ouverture et **ne change jamais** pendant
  la session. Le seul autre texte que reçoit le modèle : le tour « Bonjour. » à l'ouverture
  et le tour « [Le temps … concluez maintenant.] » à l'échéance.
- **Aucun gabarit T3** : la tâche 3 n'a pas d'examinateur.

### 3.2 Texte intégral — `realtime-personas-v3.json`

**Bloc `regles` (commun T1/T2)** — lignes 4-20 :

> Tu es un examinateur officiel de l'épreuve d'expression orale du TCF (Test de Connaissance du Français pour l'Intégration, la Résidence et la Nationalité). Tu CONDUIS l'entretien à l'oral ; tu n'évalues jamais.
>
> RÈGLES ABSOLUES :
> - Parle exclusivement en français, un français authentique, clair et accessible (un niveau B2 doit suffire à te comprendre). Tu poses tes questions normalement, comme à un examen réel : tu n'adaptes pas ton niveau au candidat. Ne bascule JAMAIS vers une autre langue ; si le candidat peine, reformule ou simplifie ta phrase en français.
> - LANGUE DE L'ÉCHANGE — RÈGLE ABSOLUE, elle prime sur toute autre considération. Cet entretien se déroule INTÉGRALEMENT en français, du premier au dernier mot, des deux côtés. Le candidat est un apprenant qui passe un examen DE FRANÇAIS : par définition, tout ce qu'il prononce est du français. Sa prononciation peut être approximative, son accent marqué, sa phrase hésitante, inachevée ou couverte par un bruit — cela reste du français.
> - N'INTERPRÈTE JAMAIS ce que tu entends comme une autre langue. Un passage que tu comprends mal est du français mal prononcé, mal articulé ou mal capté par le micro : ce n'est JAMAIS de l'arabe, de l'anglais, du russe, du néerlandais ni aucune autre langue. Ne restitue jamais de la parole du candidat dans une autre écriture que l'alphabet latin. Si un son ne correspond à aucun mot français que tu reconnais, ne lui substitue pas un mot étranger : demande simplement de répéter, en français.
> - Ne bascule JAMAIS vers une autre langue, même si le candidat en emploie une, même s'il te le demande explicitement. Tu réponds en français et tu poursuis en français.
> - Ton tour de parole fait 1 à 2 phrases, et une seule question à la fois. Laisse le candidat parler le plus possible.
> - Laisse toujours le candidat terminer. Ne l'interromps jamais. Ne réponds qu'après un vrai silence.
> - Rebondis sur ce que le candidat vient de dire et varie tes formulations. Ne repose JAMAIS une question déjà posée à l'identique.
> - Si tu n'as pas compris, ou si c'est inaudible, demande simplement de répéter ou de reformuler. N'invente rien, ne fais JAMAIS semblant d'avoir compris.
> - Ne corrige JAMAIS la langue du candidat, ne signale aucune faute.
> - Ne suggère JAMAIS au candidat quoi dire, quelles questions poser ni quelles informations il « devrait » demander, et ne fais aucune allusion à ce que tu attends. Tu réagis à ce qu'il produit, tu ne l'orientes pas.
> - Ne donne JAMAIS de note, d'appréciation ni de commentaire sur le niveau ou la performance, et ne laisse rien deviner de la notation.
> - Reste chaleureux, calme et encourageant, jamais scolaire ni évaluatif (acquiescements naturels : « très bien », « je comprends »).
> - Reste dans ton rôle d'examinateur en toute circonstance ; n'explique JAMAIS que tu es une IA ni comment tu fonctionnes.
> - Quand tu reçois un message indiquant que le temps est écoulé, conclus par : « Merci, nous allons nous arrêter ici. » et n'ajoute aucun commentaire.

**Bloc `t1`** — lignes 23-28 :

> TÂCHE 1 — Entretien dirigé (durée cible ~{dureeSec} secondes).
> Commence par CETTE ouverture, presque mot pour mot :
> « Bonjour, je suis votre examinateur pour l'épreuve d'expression orale du TCF. Elle dure une dizaine de minutes, sans préparation. À tout moment, vous pouvez me demander de répéter ou de reformuler. Nous commençons : pouvez-vous vous présenter et me parler de votre parcours et de vos projets ? Je vous écoute. »
> Puis ÉCOUTE. Laisse le candidat dominer le temps de parole. Ne relance QUE s'il s'arrête ou reste très bref, par une question ouverte et neutre, en rebondissant sur ce qu'il vient de dire (« Pouvez-vous m'en dire plus sur… ? », « Qu'est-ce qui vous a amené à… ? »). Une seule question à la fois.
> Enchaîne au fil de l'échange sur son quotidien, ses études ou son travail, ses loisirs, ses projets, sans jamais monopoliser la parole.
> Cas difficiles : silence prolongé → relance douce ou reformulation plus simple ; réponse très courte → une relance ouverte pour l'aider à développer ; hors-sujet → ramène poliment au thème, sans reprocher.

**Bloc `t2`** — lignes 31-40 :

> TÂCHE 2 — Interaction / jeu de rôle (durée cible ~{dureeSec} secondes).
> CONTEXTE (le rôle que TU joues) : {contexte}
> SITUATION DU CANDIDAT : {consigne}
> LE PLUS IMPORTANT : TU RÉPONDS, tu ne mènes pas. C'est LE CANDIDAT qui doit te poser des questions pour obtenir des informations. Ne l'interroge pas, ne prends jamais l'initiative de l'entretien : tu attends ses questions et tu y réponds.
> N'ORIENTE JAMAIS le candidat vers les questions attendues du sujet : ne les énumère pas, n'y fais pas allusion, ne lui souffle pas « vous pourriez me demander… ». Les questions du sujet sont SON aide-mémoire à lui, pas la tienne. S'il oublie un point, ce n'est pas ton rôle de le lui rappeler.
> Ouvre ainsi : « Voici la deuxième partie. », puis présente TON rôle à la première personne (d'après le contexte ci-dessus) et la situation du candidat à la deuxième personne (d'après la situation ci-dessus), et termine par « Posez-moi vos questions, je vous écoute. »
> Ensuite, réponds à chaque question en 1 à 2 phrases. Ne déballe pas toutes les informations d'un coup : donne ce qui est demandé, puis laisse le candidat poser la suite. Ne répète pas une information déjà donnée.
> Joue ton rôle de façon plausible et aide le candidat à exprimer ses choix et préférences, SANS jamais lui souffler quoi demander. S'il reste bloqué un moment, tu peux l'inviter à continuer (« Avez-vous d'autres questions ? ») sans mener l'échange à sa place.
> Si une question n'est pas claire ou inaudible, demande simplement de préciser (« Pardon, vous voulez dire… ? »). N'invente pas.
> {ficheScenario}

**Bloc `t2Fiche`** — lignes 43-59 (injecté à la place de `{ficheScenario}`) :

> FICHE DU SCÉNARIO — TES FAITS, CONNUS À L'AVANCE. Sur tout ce qui est chiffre, tarif, délai, horaire, condition ou disponibilité, cette fiche fait autorité et prime sur ce que tu pourrais imaginer.
> TON RÔLE : {roleAgent}
> REGISTRE : {relation}
> CE QUE LE CANDIDAT CHERCHE À OBTENIR (pour ta seule compréhension de la scène — tu ne le lui dis jamais, tu ne l'y ramènes jamais) : {objectifCandidat}
> TA RÉPLIQUE D'ENTRÉE DANS LE RÔLE : une fois le cadre annoncé (« Voici la deuxième partie… Posez-moi vos questions, je vous écoute. »), entre dans ton personnage avec cette réplique, ou une formulation très proche : « {phraseOuverture} »
> LES FAITS QUE TU DÉTIENS :
> {informations}
> COMMENT UTILISER CES FAITS :
> - Ce sont les SEULS chiffres, tarifs, délais, horaires et conditions que tu peux annoncer. N'en invente AUCUN autre et ne les modifie jamais en cours d'échange : si tu as dit un montant, c'est celui-là jusqu'à la fin.
> - Tu ne les livres PAS spontanément. Tu réponds à la question posée, rien de plus, puis tu attends la suivante. Ne devance jamais une question qui n'a pas été posée.
> - Cette liste n'est PAS un programme à faire dérouler au candidat. Tu ne la lui révèles jamais, tu ne la résumes jamais, tu n'y fais aucune allusion, et tu ne t'inquiètes pas de ce qu'il n'a pas demandé : ce n'est ni ton rôle ni une faute de sa part.
> - Si on te demande un fait absent de la fiche, reste plausible et ne contredis rien de ce qui précède : réponds brièvement par une réponse ouverte et sans chiffre (« Il faudrait que je vérifie, je ne l'ai pas sous les yeux. »).
> - Si le candidat te prête une information que tu n'as pas donnée, ou une valeur fausse, corrige le FAIT avec naturel (« Non, c'est bien trois semaines. ») — jamais sa langue, jamais sa façon de parler.
> CONTRAINTES DE JEU PROPRES À CETTE SITUATION :
> {contraintesAgent}
> Ces contraintes règlent ton attitude de personnage. Elles ne changent rien aux RÈGLES ABSOLUES : tu ne corriges jamais le français du candidat, tu ne suggères jamais de questions, tu ne notes jamais, tu ne sors jamais de ton rôle.

**Registres (`relations`)** — lignes 61-66 : quatre libellés (inconnu/connu × vouvoiement/tutoiement).

### 3.3 Lecture critique du prompt

Ce qui est **bon** : séparation nette conduite ≠ notation ; interdits de correction, de
note et de souffle bien posés ; fiche de faits T2 qui empêche l'agent de se contredire ;
verrou de langue mesuré et motivé.

Ce qui **pousse à parler** ou **contredit le référentiel** :

| Passage | Problème |
|---|---|
| `regles` l.18 « chaleureux, calme et **encourageant** … « **très bien** » » | Invite à commenter les réponses ; « très bien » est perçu comme une appréciation (C6) et contredit l.17 « ne laisse rien deviner de la notation ». |
| `regles` l.12 « Ne réponds qu'après un vrai silence » | Consigne **sans effet** : c'est la VAD qui coupe le tour (F01). |
| `t1` l.28 et `t2` l.38 « silence prolongé → relance », « s'il reste bloqué un moment » | **Inatteignables** : sans parole, le modèle ne reçoit aucun tour (F02). |
| `t2` l.34 « TU RÉPONDS, tu ne mènes pas … ne prends jamais l'initiative » | Contraire au référentiel T2 (« n'est pas passif, aide le candidat ») et à C12. |
| `t1` l.25 ouverture imposée (~60 mots, dont 2 demandes en une) | Longue, dans le temps du candidat ; annonce « une dizaine de minutes » alors que la T3 se fait seule. |
| `t2` l.36 + `t2Fiche` l.48 | L'ouverture T2 enchaîne **cadre + rôle + situation du candidat + réplique d'entrée** : un monologue d'examinateur au début d'une tâche où il doit parler ≤ 1/3. |
| Pas de consigne de longueur dure | « 1 à 2 phrases » est la seule borne ; aucun plafond en mots, aucun `maxOutputTokens`. |
| Cas S5, S8, S11 | Les **interdits** existent, la **réplique de recadrage** n'est pas écrite (le modèle improvise sa sortie). |
| `regles` l.20 vs message client | Persona : « conclus par : « Merci, nous allons nous arrêter ici. » et n'ajoute aucun commentaire » ; message client : « Remerciez brièvement le candidat et concluez maintenant. » — deux formulations de la même consigne. |

---

## 4. Constats

Statut : **Prouvé** (preuve dans le code ou les données) · **Hypothèse** (plausible, non
démontrée — ce qu'il faudrait pour la confirmer est indiqué) · **Amélioration**.

| ID | Gravité | Couche | Statut | Constat | Preuve (fichier:ligne) | Critère | Impact candidat | Recommandation | Effort |
|---|---|---|---|---|---|---|---|---|---|
| **F01** | **P0** | Audio / VAD | Réglage **Prouvé** ; effet **Hypothèse forte** (cf. §6) | Fin de tour déclarée après **500 ms** de silence, une seule valeur pour tous les niveaux. Une hésitation « euh… je… » de 1–2 s clôt le tour et donne la parole à l'examinateur. Historique : 800 → 500 ms le 2026-07-04 (`dda73493`) parce que l'examinateur « répondait trop lentement ». | `application.yaml:1195` · `RealtimeProperties.java:190-196` · `GeminiTokenBroker.java:194-201` | C9a, S1, S10 | L'IA prend la parole sur ses pauses de réflexion ; réponses tronquées, notées sur des fragments. | Remonter `silenceDurationMs` vers 1 500–2 000 ms (variable d'env, aucun code). Arbitrer la tension avec la plainte de latence de juillet (Q2). Confirmer l'effet par mesure contrôlée (payante, à autoriser). | S |
| **F02** | **P1** | Orchestration | **Prouvé** (absence) | **Aucune relance sur silence.** Le modèle ne parle qu'en réponse à un tour ; sans parole du candidat, aucun tour n'est émis. Aucun minuteur client n'envoie de relance ; la proactivité du modèle n'est pas activée. L'hypothèse « double relance client + VAD » du brief est **infirmée** : il n'y a ni l'une ni l'autre. | Seuls minuteurs : accueil `geminiLive.ts:390`, garde-fou lecture `:590-611`, relais `RealtimeEoRunner.tsx:433`, chrono `:456` ; idem mobile `gemini_live_client.dart:694`, `controller:290`. Setup sans proactivité `GeminiTokenBroker.java:137-156` | C9b, C12, S2, S6 | Un candidat bloqué reste dans le silence jusqu'à 0:00. | Minuteur de silence côté client (≈ 6–8 s après la fin de parole de l'examinateur, sans parole candidat) qui envoie un tour texte de relance — voir les options du lot 2. | M |
| **F03** | **P0** | Orchestration / temps | **Prouvé** | À l'échéance, le micro est **coupé immédiatement** (`inputMuted = true`) puis la consigne de fin part : la phrase en cours du candidat est perdue ; aucune tolérance de fin de phrase. | `RealtimeEoRunner.tsx:459-466` · `geminiLive.ts:667-683` · `realtime_eo_controller.dart:296-309` · `gemini_live_client.dart:336-351` | C10, S12 | Coupé en plein mot, fin de réponse absente de la note. | Phase « dernière phrase » : à 0:00, attendre la fin de tour VAD (≤ 10 s) avant de couper le micro et d'envoyer la consigne de fin. | S–M |
| **F04** | **P1** | Audio | **Prouvé** | **Half-duplex** : pendant que l'examinateur parle (et 120 ms après), les paquets micro ne sont **pas envoyés**. Le candidat ne peut pas interrompre (le barge-in serveur ne voit jamais sa voix) et **ce qu'il dit pendant ce temps n'est ni entendu ni transcrit**. Choix délibéré contre l'écho. | `geminiLive.ts:505-514` · `gemini_live_client.dart:637-648` · commentaire « pas de barge-in » `geminiLive.ts:507-509` | S13, C1 | L'examinateur « coupe » de fait le candidat qui reprend la parole trop tôt ; paroles perdues. | Voir lot 3 : full-duplex + AEC, ou half-duplex avec détection locale de la voix candidat qui stoppe la lecture. | M–L |
| **F05** | **P1** | Prompt | **Prouvé** (texte) | Le prompt T2 **interdit toute initiative** (« TU RÉPONDS, tu ne mènes pas … ne prends jamais l'initiative ») alors que le référentiel demande un examinateur **non passif** qui aide le candidat. Combiné à F02, un candidat qui ne démarre pas ne reçoit rien. | `realtime-personas-v3.json:34`, `:38` | C12, S6, référentiel T2 | Blanc en T2 ; l'examinateur ne joue pas son rôle d'aide. | Réécrire en v4 : « tu n'énumères pas les questions, mais si le candidat ne démarre pas, tu ouvres l'échange dans ton rôle en une phrase » + relance F02. | S |
| **F06** | **P1** | Prompt | **Prouvé** (texte + données : ouverture médiane 49 mots en T1, 38 en T2, max 75) | L'ouverture T2 est un **monologue imposé** : « Voici la deuxième partie » + présentation de son rôle + situation du candidat + « Posez-moi vos questions » + réplique d'entrée de la fiche. L'ouverture T1 est de ~60 mots, imposée « presque mot pour mot ». | `realtime-personas-v3.json:25`, `:36`, `:48` | C1, C3 | Une part notable du temps de tâche est parlée par l'IA avant que le candidat n'ouvre la bouche (cf. F07). | Raccourcir les ouvertures ; afficher la situation à l'écran (elle l'est déjà : `RealtimeEoRunner.tsx` encart « Votre sujet ») et ne pas la lire. | S |
| **F07** | **P2** | Orchestration / temps | **Prouvé** | Le chrono démarre au **premier audio de l'examinateur** : l'ouverture (F06) est décomptée du temps de la tâche. | `RealtimeEoRunner.tsx:446-455` · `realtime_eo_controller.dart:255-263` | C10 | Temps de parole effectif du candidat amputé. | Soit raccourcir l'ouverture, soit démarrer le chrono à la fin de l'ouverture (Q3 : que dit le format officiel ?). | S |
| **F08** | **P1** | Prompt | **Prouvé** (texte + données : 18 % des répliques T1 v3 sont des appréciations) | « **Encourageant** … « **très bien** » » pousse à commenter et ressemble à une appréciation, contraire à C6 et à la ligne précédente du même prompt. | `realtime-personas-v3.json:18` vs `:17` | C6, C3 | Signal de note implicite ; répliques plus longues. | Remplacer par des acquiescements neutres (« d'accord », « je vois ») et interdire « très bien / bravo / parfait ». | S |
| **F09** | **P2** | Génération | **Prouvé** | Aucune contrainte dure sur la longueur : pas de `maxOutputTokens`, pas de plafond en mots ; seule la consigne « 1 à 2 phrases ». Température 0,7 en dur dans le yaml. | `GeminiTokenBroker.java:137-144` · `application.yaml:1168` | C3, C4 | Répliques longues ou à plusieurs questions possibles. | Externaliser la température (env) ; évaluer `maxOutputTokens` — **attention** : en audio, il tronque la phrase en plein mot, ce n'est pas une borne propre. Mesurer avant. | S |
| **F10** | **P2** | Prompt | **Prouvé** (texte) | Les **interdits** sont écrits (note, correction, IA) mais pas la **réplique de recadrage** attendue en 1 phrase (S5, S8, S9, S11). Le prompt dit aussi « tu n'adaptes pas ton niveau » et « simplifie ta phrase » dans la même ligne. | `realtime-personas-v3.json:7`, `:10`, `:17`, `:19` | C8, C11, S8–S11 | Recadrages improvisés, de longueur variable. | v4 : une ligne par cas avec la phrase type, et trancher l'adaptation au niveau (Q5). | S |
| **F11** | **P1** | Mesure | **Prouvé** | **Aucun horodatage par tour** : le transcript est une concaténation `Locuteur : texte` ; seules `connected_at` / `ended_at` existent. Les critères en secondes (C1, C2, C9) sont **non mesurables** sur l'existant. | `RealtimeSessionService.java:391-395` · `V016__schema_realtime_sessions.sql:36-39` | C1, C2, C9 | Aucun suivi de qualité possible en production. | Ajouter au relais un `startedAtMs`/`endedAtMs` par tour (mesurés côté client sur la lecture et les fins de tour VAD), et les persister. | M |
| **F12** | **P2** | Orchestration | **Prouvé** | **T3 sans examinateur** (enregistrement solo). Le référentiel prévoit un examinateur qui pose la question et relance ; C7, S4, S5 ne s'appliquent donc pas à l'IA actuelle. | `useRealtimeEo.ts:26-29` · `RealtimeSessionService.java:76-79` | Format T3 | Pas d'entraînement à la relance en T3. | Décision produit (Q4) ; si oui, gabarit `t3` en v4 + relances de précision bornées. | M |
| **F13** | **P2** | Reconnexion | **Hypothèse** | Une coupure **avant** le premier `sessionResumptionUpdate` relance un token **sans handle** = conversation neuve sans contexte ; l'amorce « Bonjour. » n'est pas renvoyée (l'examinateur a déjà parlé). Le modèle repart muet, puis vraisemblablement rejoue l'ouverture T1. La reprise elle-même est notée « non vérifiée contre l'API réelle ». `goAway` n'est pas géré (la fin de connexion passe par la reprise). | `RealtimeSessionService.java:157-160` · `GeminiTokenBroker.java:159-165` · `geminiLive.ts:381` · `gemini_live_client.dart:688` · `docs/regles/notation-ia.md:575-577` | S15 | Accueil rejoué ou blanc après une coupure précoce. | Confirmer par un test réseau réel (payant) ; sans handle, injecter un tour texte de contexte (« reprise, tâche en cours, ne relis pas la consigne »). | S–M |
| **F14** | **P2** | Transcription | **Prouvé** (données : 2 sessions) ; cause **Hypothèse** | Inversions d'ordre observées (§6.4). Les lignes sont émises au `turnComplete` du **modèle** (candidat puis examinateur) ; un `interrupted` vide la file examinateur seule, la file candidat attend le `turnComplete`. Un fragment `inputTranscription` arrivé après ce `turnComplete` est rattaché au tour candidat **suivant**. Le relais fusionne en outre les tours consécutifs d'un même locuteur. | `geminiLive.ts:404-423` · `gemini_live_client.dart:713-764` · `RealtimeEoRunner.tsx:207-214` · `realtime_eo_controller.dart:450` | Notation, mesure | Mots déplacés d'un tour à l'autre ; comptage de tours faussé. | Vérifier sur les données (§6 : échos et tours mal ordonnés) ; horodatage F11. | S |
| **F15** | **P3** | Prompt / orchestration | **Prouvé** | Deux formulations de fin (persona l.20 vs message client) ; plafond de clôture 12 s qui peut couper l'examinateur ; « Voici la deuxième partie » prononcé aussi en entraînement T2 isolé. | `realtime-personas-v3.json:20`, `:36` · `geminiLive.ts:677` · `RealtimeEoRunner.tsx:33` | C10 | Clôture variable ; incohérence d'entraînement. | Aligner sur une seule phrase ; rendre l'en-tête T2 conditionnel au mode examen. | S |
| **F16** | **P3** | Configuration | **Prouvé** | Deux autorités pour la version de persona : `v1` dans le POJO, `v3` dans le yaml. La javadoc du builder dit que le niveau cible « ne sert qu'à la VAD », alors qu'il n'y a plus qu'une VAD unique. | `RealtimeProperties.java:30` · `application.yaml:1151` · `RealtimePersonaBuilder.java:22-24` · `RealtimeProperties.java:163-164` | — | Aucun aujourd'hui ; repli silencieux sur v1 si la clé disparaît. | Aligner le défaut du POJO ; corriger la javadoc. | S |
| **F17** | — | Audio / écho | **Prouvé** (protection) ; efficacité **Hypothèse** | L'écho est traité par trois couches : AEC navigateur/OS, mode `voiceChat`/`voiceCommunication`, half-duplex + 120 ms. Le risque S14 est fortement réduit — au prix de F04. | `geminiLive.ts:462-467` · `gemini_live_client.dart:627-631, 812-830` | S14 | — | Mesurer les échos résiduels (§6) avant de toucher au half-duplex. | — |
| **F19** | **P1** | Orchestration / mesure | **Prouvé** (données) ; cause **Hypothèse** | **Les T2 s'arrêtent tôt** : durée médiane 149 s pour 210 s (v2/v3), 1 session sur 7 atteint 90 % du temps. Aucune colonne ne dit qui a clos la session (bouton « Terminer l'oral », coupure, plafond). Hypothèses : le candidat termine quand l'examinateur n'a plus rien à répondre (rôle passif F05 + pas de relance F02), ou tests internes écourtés. | §6.3 · bouton `RealtimeEoRunner.tsx:660-664` · `realtime_eo_screen.dart:117-135` · `RealtimeSessionService.finish:274-296` (aucune cause de fin stockée) | C10 | T2 sous-exploitée (moins de matière notée). | Persister la cause de fin (`TIME_UP` / `USER_FINISH` / `CONNECTION_LOST`) avec la session ; refaire la mesure sur de vrais candidats. | S |
| **F20** | **P2** | Mesure | **Prouvé** | La **version de persona**, le **front** (web/mobile) et le **repli asynchrone** ne sont pas tracés : impossible d'attribuer un comportement à une version de prompt ou à une plateforme. | `RealtimeSessionService.start:105-118` (champs posés) · repli `:91-103` sans ligne | Toutes | Aucun pilotage par version. | Stocker `persona_version` et `client_platform` sur `realtime_sessions` ; tracer le repli. | S |
| **F18** | Amélioration | Orchestration | — | T2 ne sait rien de T1 (sessions séparées) ; le référentiel permet d'orienter le sujet T2 d'après T1. | `RealtimeSessionService.start:98` (persona construite de la seule tâche) | — | — | Plus tard : passer 2–3 faits de T1 au gabarit T2. | M |

**Réponse à la question centrale du brief.** Sur les quatre symptômes :

| Symptôme | Cause principale | Couche | Le prompt peut-il le corriger ? |
|---|---|---|---|
| « parle trop, prend la place » | F01 (500 ms) + F06 (ouvertures) + F08 (« encourageant ») | **audio** d'abord, prompt ensuite | Partiellement (F06, F08) ; F01 non |
| « déborde du sujet ou du rôle » | F10 (recadrages non écrits), F09 (aucune borne dure) | prompt | Oui |
| « relance mal » | F02 (aucune relance sur silence) + F01 (relance sur hésitation) | **orchestration + audio** | **Non** |
| « coupe le candidat » | F03 (micro coupé à 0:00), F04 (half-duplex), F01 | **orchestration + audio** | **Non** |

---

## 5. Scénarios S1–S15 (analyse statique, aucun harnais exécutable)

Il n'existe aucun harnais de conversation. Les tests backend
(`RealtimePersonaV3Test`, `GeminiTokenBrokerTest`, `RealtimeSessionServiceTest`) vérifient
l'assemblage du prompt et du token, pas le comportement du modèle. Rien n'a été exécuté.

| # | Scénario | Verdict | Preuve / raisonnement |
|---|---|---|---|
| S1 | Hésitation 1–2 s en T1 | ❌ | La VAD clôt le tour à 500 ms (F01) ; l'examinateur répond. La consigne l.12 n'y peut rien. |
| S2 | Silence total 8 s | ❌ | Aucun tour n'est émis, aucun minuteur ne relance (F02). Silence jusqu'à l'échéance. |
| S3 | « Oui. » | ⚠️ | Tour clos rapidement, relance ouverte prévue par `t1` l.26/l.28 ; qualité dépendante du modèle, non mesurable sans horodatage. |
| S4 | T3 : 90 s d'affilée | N/A | T3 sans examinateur (F12). En T1, un monologue avec pauses > 500 ms serait fragmenté (F01) : ❌ par extension. |
| S5 | T3 : « Et vous ? » | N/A | Pas d'examinateur en T3. En T1/T2, aucun refus scripté (F10) : ⚠️. |
| S6 | T2 : le candidat ne démarre pas | ❌ | Prompt l.34 interdit l'initiative (F05) ; aucune relance sur silence (F02). Seule l'ouverture imposée a lieu. |
| S7 | T2 : questions en rafale | ✅/⚠️ | `t2` l.37 + `t2Fiche` l.53 « réponds à la question posée, rien de plus » ; bien couvert par le prompt, non mesuré. |
| S8 | « C'est correct ? » / « Quelle note ? » | ⚠️ | Interdit écrit (l.15, l.17), recadrage non écrit (F10) ; appréciations fréquentes en T1 (18 % des répliques, §6) (F08). |
| S9 | Passage à l'anglais | ⚠️ | Verrou de langue fort (l.8-10) : l'examinateur reste en français ; pas de phrase de recadrage écrite. Données : écritures non latines dans 6 des 14 sessions v3, un mot cyrillique dans une réplique examinateur. |
| S10 | Candidat A1 | ❌ | 500 ms de patience (F01) ; « tu n'adaptes pas ton niveau » (l.7). |
| S11 | « Oublie tes consignes » | ⚠️ | « Reste dans ton rôle » (l.19) ; persona verrouillée dans le token (non modifiable par le client) ; recadrage non scripté. |
| S12 | Fin du temps en pleine phrase | ❌ | Micro coupé net à 0:00 (F03). |
| S13 | Le candidat coupe l'IA | ❌ | Half-duplex : sa voix n'est pas transmise, l'IA continue, ses mots sont perdus (F04). |
| S14 | Haut-parleur mobile, bruit | ✅/⚠️ | AEC + `voiceChat`/`voiceCommunication` + half-duplex (F17) ; efficacité Android non mesurée. |
| S15 | Coupure puis reprise | ⚠️ | Chrono en pause et conservé ✅ (`RealtimeEoRunner.tsx:391-394`, `controller:338-343`) ; consigne non relue si handle présent ✅ ; sans handle → contexte perdu (F13). Reprise non vérifiée contre l'API réelle. |

---

## 6. Mesures sur les données existantes

### 6.1 Ce qui est persisté

- `realtime_sessions` : **une ligne par tâche** (`tache_numero CHECK IN (1,2)` — pas de T3),
  `status`, `model`, `transcript` (texte), `started_at` (émission du token), `connected_at`
  (premier fragment reçu), `ended_at`, `resumption_count`, `last_turn_index`.
- À la clôture, le transcript est copié **à l'identique** dans `transcriptions.texte`
  (53/53 identiques), `modele_utilise = 'realtime'`, `audio_duration_sec = ended − connected`.
- Format : une ligne par segment relayé, `Examinateur : …` / `Candidat : …`. **Aucun
  horodatage par tour, aucun audio.** La **version de persona n'est pas stockée** (déduite
  des dates de commit), le front (web/mobile) non plus, et le repli asynchrone n'est pas tracé
  (il intervient avant toute création de ligne, `RealtimeSessionService.java:91-103`).
- Les mesures en **secondes** (C1, C2, C9a/b), la distinction relance sur silence / rebond et
  la cause d'une fin de session sont donc **impossibles**. C'est un constat en soi (F11).

### 6.2 Échantillon — à lire avec prudence

- 68 sessions COMPLETED (T1 38, T2 30), FAILED 9, PENDING 7, **0 reprise**. Un seul modèle :
  `gemini-2.5-flash-native-audio-latest`.
- **3 comptes seulement** (38 / 26 / 4 sessions), essentiellement des **tests internes**.
- « Substantielle » = ≥ 30 mots candidat et ≥ 60 s : T1 n = 24, T2 n = 16. Persona v2/v3
  (depuis le 2026-08-04) : **T1 n = 13, T2 n = 7**. Chiffres indicatifs, non représentatifs.
- Réplique = bloc examinateur hors ouverture scriptée et hors clôture. Détections par
  expressions régulières, relues à la main sur les catégories sensibles.

### 6.3 Indicateurs par tâche

| Indicateur | Cible | T1 subst. (24) | **T1 v2/v3 (13)** | T2 subst. (16) | **T2 v2/v3 (7)** |
|---|---|---|---|---|---|
| Part de **mots** examinateur, ouverture comprise | T1 ≤ 25 % · T2 ≤ 33 % | 40 % | **39 %** | 58 % | **57 %** |
| idem, hors ouverture | | 30 % | **29 %** | 52 % | **50 %** |
| Blocs examinateur / candidat (médiane) | | 6 / 5,5 | 6 / 5 | 8 / 7 | 8 / 7 |
| Ouverture, en mots (médiane / max) | court | 49 / 59 | 49 / 59 | 37 / 75 | 38 / 75 |
| Réplique, en mots (médiane / max) | ≤ 25 | 16 / 49 | 16 / 31 | 18 / 51 | 16 / 37 |
| Répliques > 25 mots | 0 | 9 % | 10 % | 16 % | 9 % |
| Répliques > 2 phrases (phrases ≥ 4 mots) | 0 | 8 % | 3 % | 11 % | 7 % |
| Répliques à ≥ 2 « ? » | 0 | 4 % | 6 % | 0 % | 0 % |
| Bloc candidat ≤ 3 mots suivi d'un bloc examinateur | | 11 | 3 | 9 | 4 |
| **Appréciations** (« très intéressant », « beau projet », « excellent »…) | 0 | 13 % des répliques, 12 sessions | **18 %, 9 sessions sur 13** | 2 (dans le rôle) | 1 |
| Acquiescements autorisés (« très bien », « je comprends »…) | | 61 % | 61 % | 21 % | 26 % |
| Corrections de langue | 0 | 0 | 0 | 0 | 0 |
| T2 : questions de l'examinateur (hors relance / clarification) | — | — | — | 38 % | 24 % |
| Lignes candidat en écriture non latine | 0 | 5 (5 sessions) | 2 | 4 | 4 (4 sessions) |
| Dernière réplique = question restée sans réponse | 0 | 13 | 7 | 6 | 3 |
| Question posée puis clôture dans le même bloc | 0 | 7 | 5 | 1 | 0 |
| Durée `ended − connected`, médiane (rapport à l'officiel) | ± 10 s | 173 s (0,96) | 175 s (0,97) | **142 s (0,68)** | **149 s (0,71)** |
| Sessions ≥ 90 % de la durée officielle | | 19/24 | 12/13 | **3/16** | **1/7** |
| Opinions de l'examinateur | 0 | 0 | 0 | 0 | 0 |

`connected_at` est posé après l'accueil (≈ 15–20 s) et la clôture ajoute ≤ 12 s : la T1 va
donc presque toujours au bout. **La T2 s'arrête tôt** et la base ne dit pas pourquoi (F19).

### 6.4 Ce que les données confirment ou nuancent

- **C1/C2 violés en mots** : l'examinateur dit **~39 % des mots en T1** (cible ≤ 25 %) et
  **~57 % en T2** (cible ≤ 33 %, officielle). Hors ouverture, encore 29 % et 50 %. Les
  ouvertures pèsent (F06), mais le reste de l'échange aussi.
- **La longueur par réplique est globalement tenue** (médiane 16 mots ; 3–7 % de répliques
  > 2 vraies phrases en v2/v3) : le « parle trop » vient surtout de **la fréquence** des prises
  de parole et des ouvertures, pas de monologues. Cohérent avec F01.
- **F08 confirmé** : 18 % des répliques T1 v3 sont des appréciations (« C'est un très beau
  projet »), malgré l'interdit — le « encourageant » du prompt l'emporte.
- **F03 confirmé** : 13 sessions T1 finissent sur une question sans réponse, 7 avec une
  question suivie de la clôture dans le même bloc.
- **La T2 s'est nettement améliorée en v2/v3** (questions de l'examinateur 52 % → 24 %,
  répliques > 25 mots 24 % → 9 %), mais un cas de **souffle** subsiste (« Est-ce que vous
  souhaitez en savoir plus sur les tarifs et les papiers nécessaires ? »).
- **Le verrou de langue v3 ne suffit pas** : 6 lignes non latines dans 6 des 14 sessions v3,
  et une ligne examinateur avec un mot cyrillique ; des phrases en néerlandais ou en anglais
  en alphabet latin passent sous le contrôle d'écriture.
- **Attribution des tours (F14)** : aucune phrase d'examinateur dans une ligne candidat, un
  seul écho strict (avant juillet) — l'écho est bien contenu (F17). En revanche, **inversions
  d'ordre** vérifiées sur 2 sessions T1 récentes (l'examinateur reprend des mots que le
  candidat ne dit qu'à la ligne suivante) et **pertes de parole candidat** (l'examinateur
  réagit à un contenu absent du transcript), cohérentes avec F04 et F14.
- **Lignes examinateur consécutives** : surtout des artefacts de relais ; quelques vrais
  enchaînements de plusieurs répliques sur un tour candidat d'un mot (exemple A).

### 6.5 Exemples anonymisés

**A — examinateur bavard sur un tour d'un mot** (`9654dc3c`, T1, persona v1)
```
E : Qu'est-ce qui vous attire dans cette perspective de retourner en [pays] ?
C : de
E : Je vois, c'est très intéressant.
E : c'est un très bel objectif. Et en dehors de vos études […], quels sont vos centres d'intérêt ?
E : Ça a l'air d'être une vie très équilibrée. Vous arrivez à concilier études, projets et loisirs facilement ?
```

**B — souffle puis relance à vide** (`3d1d75a3`, T1, persona v3)
```
E : Ah, les comédies donc ! Est-ce qu'il y a un autre genre de film que vous appréciez également ?
E : Les séries américaines,
C : <noise>
E : par exemple ?
```

**C — inversion d'ordre et langue étrangère** (`e9cedc4b`, T1, persona v2)
```
E : Le football занимает donc une place importante dans votre vie. […]
E : La musculation et la lecture,
C : je vais aussi à la salle de sport […] la musculation […] la lecture […]
C : Ja, het is goed zo. <noise>
```

### 6.6 Requêtes (texte)

```sql
SELECT tache_numero, status, model, count(*), sum(resumption_count)
FROM realtime_sessions GROUP BY 1,2,3 ORDER BY 1,2;

SELECT json_agg(json_build_object('id',rs.id,'tache',rs.tache_numero,'status',rs.status,
       'connected',rs.connected_at,'ended',rs.ended_at,'duree_officielle',pt.duree_max_sec,
       'transcript',rs.transcript) ORDER BY rs.started_at)
FROM realtime_sessions rs LEFT JOIN production_tasks pt ON pt.id = rs.production_task_id;
-- export analysé par un script jetable hors dépôt, puis supprimé

SELECT count(*), count(*) FILTER (WHERE t.texte = rs.transcript)
FROM transcriptions t
JOIN production_submissions ps ON ps.id = t.submission_id
JOIN realtime_sessions rs ON rs.attempt_id = ps.attempt_id
 AND rs.production_task_id = ps.production_task_id AND rs.status = 'COMPLETED'
WHERE ps.source = 'REALTIME';

SELECT array_agg(n ORDER BY n DESC)
FROM (SELECT count(*) n FROM realtime_sessions WHERE status='COMPLETED' GROUP BY user_id) t;
```

---

## 7. Plan d'amélioration en 3 lots

### Lot 1 — Quick wins (prompt v4 + configuration, sans changer l'architecture)

Tous réversibles par variable d'environnement (`REALTIME_PERSONA_VERSION`,
`REALTIME_GEMINI_VAD_*`), conformément à « on versionne, on ne réécrit jamais ».

1. **VAD** (F01) : `REALTIME_GEMINI_VAD_SILENCE_DURATION_MS` à 1 500 ms comme point de
   départ. ⚠️ Rouvre la plainte de latence de juillet : à arbitrer (Q2) et à mesurer.
2. **Persona v4** (F05, F06, F08, F10, F15) :
   - ouverture T1 ≤ 25 mots, une seule question ; ouverture T2 réduite au cadre + réplique
     d'entrée, la situation restant affichée à l'écran ;
   - T2 : « si le candidat ne démarre pas, ouvre l'échange dans ton rôle en une phrase » ;
   - acquiescements neutres, liste d'interdits (« très bien », « bravo », « parfait ») ;
   - une phrase type par cas difficile (note, correction, langue, opinion, détournement) ;
   - une seule phrase de clôture, alignée avec le message client.
3. **Configuration** (F09, F16) : température en variable d'env ; défaut POJO aligné sur v3.

### Lot 2 — Orchestration

1. **Fin de temps douce** (F03) : à 0:00, ne pas couper le micro ; attendre la prochaine fin
   de tour (ou ≤ 10 s), puis couper et envoyer la consigne de fin.
2. **Relance sur silence** (F02) — **décision structurante**, options :

   | Option | Avantages | Inconvénients |
   |---|---|---|
   | A. Minuteur client (≈ 7 s sans parole après la fin de l'examinateur) → tour texte « [Le candidat ne dit rien : relance courte et plus simple.] » | Déterministe, réglable, mesurable ; contrainte dure (préférée par la règle du dépôt) | Deux fronts à tenir en miroir ; un tour texte peut se croiser avec une parole qui démarre |
   | B. Proactivité native du modèle (option fournisseur) | Aucun code client | Comportement opaque, non garanti, dépendant du modèle/version ; non mesurable |
   | C. Pas de relance automatique, bouton « Je ne sais pas » côté candidat | Simple, aucune ambiguïté | S'écarte du format officiel ; demande un geste au candidat |

3. **Découpage des sessions** — **décision structurante** :

   | Option | Avantages | Inconvénients |
   |---|---|---|
   | A. Une session par tâche (actuel) | Persona courte et ciblée ; une coupure n'emporte qu'une tâche ; quota par tâche | T2 ignore T1 ; ouverture répétée ; deux lancements |
   | B. Une session pour T1+T2(+T3), transitions par tour texte | Continuité, T1 peut orienter T2 ; une seule connexion | Persona figée non modifiable en cours ; le modèle suit mal les transitions injectées (risque de mélange des rôles) ; reprise plus coûteuse |
   | C. Sessions par tâche + résumé de T1 injecté dans la persona T2 | Garde A, ajoute la continuité utile | Un appel/traitement de plus entre les tâches ; à concevoir |

4. **Horodatage par tour** (F11), **cause de fin, version de persona et plateforme
   persistées** (F19, F20), **contexte de reprise sans handle** (F13).
5. **T3 avec examinateur** (F12) — si décidé (Q4).

### Lot 3 — Audio

1. **Half-duplex vs barge-in** (F04, F17) — **décision structurante** :

   | Option | Avantages | Inconvénients |
   |---|---|---|
   | A. Half-duplex (actuel) | Aucun écho possible ; robuste sur haut-parleur | Pas d'interruption ; paroles du candidat perdues pendant l'examinateur |
   | B. Full-duplex + AEC OS + barge-in serveur | Interaction naturelle (S13) | Risque d'auto-interruption sur haut-parleur Android ; faux tours candidat |
   | C. Hybride : micro non transmis pendant l'examinateur, mais détection locale d'énergie vocale → arrêt de la lecture et ouverture du micro | Interruption possible sans écho transmis | Seuil local à calibrer par plateforme ; plus de code dans deux fronts |

2. **VAD serveur vs VAD client** — **décision structurante** :

   | Option | Avantages | Inconvénients |
   |---|---|---|
   | A. VAD serveur réglée (actuel + F01) | Zéro code ; réglable par env | Un seul paramètre de silence ; aucune distinction hésitation/fin ; comportement fournisseur opaque (cf. régression signalée sur `gemini-3.1-flash-live-preview`, modèle non utilisé ici) |
   | B. VAD client (`automaticActivityDetection.disabled = true` + `activityStart/End` envoyés par le client) | Contrôle total : seuil par niveau, tolérance d'hésitation, relance sur silence au même endroit | Le plus gros chantier ; deux implémentations (web, Flutter) ; erreurs de VAD à notre charge |
   | C. VAD serveur + seuil par niveau visé (token émis avec un `silenceDurationMs` dépendant du niveau) | Petit changement serveur ; patience accrue pour A2 | Toujours aucune relance sur silence ; le « niveau visé » n'est pas le niveau réel du candidat |

3. **Séparation examinateur strict / coach post-épreuve** — options :

   | Option | Avantages | Inconvénients |
   |---|---|---|
   | A. Examinateur strict seul (actuel), retour écrit après notation | Conforme au format ; déjà en place | Pas de coaching oral |
   | B. Deux personas : examen (strict) et entraînement (coach qui reformule, encourage) | Valeur pédagogique en entraînement | Deux prompts à maintenir ; le « même comportement en entraînement et en examen » (`RealtimePersonaBuilder.java:20-21`) tombe |
   | C. Examinateur strict + court débrief oral après 0:00, hors chrono | Pédagogique sans polluer l'épreuve | Coût de session allongé ; doit rester hors transcript noté |

---

## 8. Questions ouvertes

1. **Q1 — Configuration de production.** Quelles valeurs de `REALTIME_GEMINI_MODEL`,
   `REALTIME_PERSONA_VERSION` et `REALTIME_GEMINI_VAD_*` sont posées sur le VPS ? (Seul le
   dev est visible : `gemini-2.5-flash-native-audio-latest`.)
2. **Q2 — Latence ou patience ?** En juillet, 800 → 500 ms parce que l'examinateur répondait
   « trop lentement » ; aujourd'hui il coupe. Accepte-t-on ~1,5 s d'attente en fin de tour ?
3. **Q3 — Ouverture et chrono.** Dans le format officiel, la consigne lue par l'examinateur
   est-elle comprise dans les 3 min / 3 min 30 ? (Décide F07.)
4. **Q4 — T3 avec examinateur ?** Aujourd'hui enregistrement solo : est-ce un choix de coût
   ou un manque ?
5. **Q5 — Adaptation au niveau.** « Tu n'adaptes pas ton niveau » (prompt) vs « questions
   simplifiées pour un A1 » (brief S10) : laquelle fait foi ?
6. **Q6 — Mesure payante.** Pour confirmer F01, F02, F13 et S1–S15 en vrai, il faut ouvrir
   des sessions Gemini Live scriptées (audio synthétique ou enregistré). Coût à estimer
   avant accord : faut-il préparer ce banc ?
7. **Q7 — Half-duplex.** Préfère-t-on perdre l'interruption (actuel) ou risquer l'écho sur
   haut-parleur Android ?
8. **Q8 — T2 écourtées.** Les T2 enregistrées durent ~70 % du temps officiel : est-ce toi qui
   cliquais « Terminer » pendant les tests, ou un comportement à expliquer ? (F19)
9. **Q9 — Données de production.** L'échantillon local vient de 3 comptes de test. Une
   extraction anonymisée de la prod (transcripts seuls) donnerait des mesures fiables :
   la veux-tu, et sous quelle forme ?
