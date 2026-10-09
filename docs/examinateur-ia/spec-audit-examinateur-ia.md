# Brief Claude Code — Audit de l'examinateur IA (TCF IRN · Expression orale)

> **Mode : AUDIT UNIQUEMENT.**
> Aucune modification de code, prompt, configuration ou base de données. Aucun commit, aucune branche, aucune migration.
> Pas d'ouverture de session Gemini Live (ou autre API payante) sans mon accord explicite.

---

## 1. Problème constaté

L'examinateur IA de l'épreuve d'expression orale (temps réel via Gemini Live) :
- parle trop et prend la place du candidat ;
- déborde du sujet ou de son rôle ;
- relance mal (relances génériques, ou relance sur une simple hésitation) ;
- coupe le candidat ou ne le laisse pas assez s'exprimer.

**Objectif :** identifier les causes **avec preuves dans le code** (fichier:ligne), en distinguant ce qui relève du **prompt**, de l'**orchestration** (tâches, chrono, transitions) et de la **couche audio** (détection de fin de parole, interruptions, écho). Un défaut d'orchestration ou d'audio ne se corrige pas par le prompt : c'est la question centrale de l'audit.

---

## 2. Référentiel officiel (France Éducation international)

Épreuve individuelle, 3 tâches, **10 minutes au total, sans préparation**. Les durées sont à respecter strictement.

| Tâche | Durée | Ce qui est évalué | Règles pour l'examinateur |
|---|---|---|---|
| **T1 — Entretien dirigé** | 3 min | Échanger avec une personne inconnue (se présenter, parcours, quotidien, projets) | Temps de parole limité : c'est le candidat qui parle le plus. Questions variées, rebondir sur les réponses. |
| **T2 — Exercice en interaction** | 3 min 30 | Interagir dans une situation de la vie courante pour obtenir des informations / faire un choix (ex. : chercher un logement) | Joue un rôle. **Parole de l'examinateur ≤ 1/3 de l'échange**, répliques courtes. N'est pas passif : il aide le candidat avant de passer à la suite. Sujet choisi parmi 5 (les infos de T1 peuvent guider le choix). |
| **T3 — Expression d'un point de vue** | 3 min 30 | Parler de manière spontanée, continue et convaincante sur une question | Pose la question, laisse parler, relance pour préciser ou débloquer. Ne débat pas, ne donne pas son opinion. Peut passer à la suite si aucune production après un nombre significatif de relances. |

---

## 3. Comportement cible (critères mesurables)

Les critères marqués *cible SejourFR* ne sont pas officiels : ce sont nos seuils de travail, ajustables.

| # | Critère | Cible | Origine |
|---|---|---|---|
| C1 | Part de parole examinateur en T2, **mesurée en secondes** (en mots seulement à défaut d'horodatage audio) | ≤ 33 % | Officiel |
| C2 | Part de parole examinateur en T1 / T3, mesurée de la même façon | ≤ 25 % / ≤ 15 % | Cible SejourFR |
| C3 | Longueur d'une réplique (hors consigne de tâche) | ≤ 2 phrases, ~25 mots | Cible SejourFR |
| C4 | Une seule question par tour | Oui | Cible SejourFR |
| C5 | Relance ancrée dans ce que le candidat vient de dire | Oui | Officiel (rebondir) |
| C6 | Aucune correction, note, félicitation évaluative ou conseil pendant l'épreuve (le coaching vient après) | Oui | Neutralité examinateur |
| C7 | Aucune opinion personnelle, aucun débat en T3 | Oui | Officiel |
| C8 | Hors-sujet, demande de note, tentative de détournement → recadrage en 1 phrase | Oui | Cible SejourFR |
| C9a | **Fin de tour** (le candidat a fini sa réponse) : l'IA répond sans délai artificiel, mais ne prend pas la parole sur une pause d'hésitation (« euh… », 1–2 s) | Seuil à calibrer (≈ 1,5–2,5 s), pas 6–8 s | Cible SejourFR |
| C9b | **Silence prolongé** (aucune parole après une question) : une relance courte et simplifiée | ≈ 6–8 s | Cible SejourFR |
| C10 | Durées préconisées respectées sans couper brutalement le candidat : on le laisse finir sa phrase, puis transition en 1 phrase, sans résumé | Écart ≤ ± 10 s par tâche | Durées : officiel · tolérance : cible SejourFR (la tolérance de ± 10 s en T2 est signalée dans le document examinateur, à confirmer) |
| C11 | Français uniquement, vouvoiement, débit naturel ; reformule une fois si le candidat ne comprend pas | Oui | Cible SejourFR |
| C12 | En T2, si le candidat ne démarre pas, l'examinateur ouvre l'échange dans son rôle | Oui | Officiel (pas de passivité) |

---

## 4. Hypothèses à vérifier, couche par couche

Pour chaque ligne : confirmer ou infirmer **avec la preuve**.

| Couche | Hypothèse | À prouver |
|---|---|---|
| **Prompt** | Instruction système unique et floue pour les 3 tâches ; pas de limite de longueur ; consignes du type « sois chaleureux / encourage » qui poussent à parler ; exemples trop bavards | Citer intégralement le(s) prompt(s) et leur assemblage |
| **Orchestration** | Une seule session Gemini Live pour les 10 min. La config (instruction système) n'étant pas modifiable connexion ouverte, le changement de tâche passe par un message injecté que le modèle peut mal suivre | Qui déclenche les transitions (client, serveur, modèle) et comment |
| **Temps** | Le modèle ignore le temps écoulé ; il annonce lui-même des transitions, ou le client coupe brutalement | Où vit le chrono, ce qui se passe à l'échéance |
| **Détection de fin de parole** | `automaticActivityDetection` mal réglé (`silenceDurationMs`, `endOfSpeechSensitivity`, `startOfSpeechSensitivity`, `prefixPaddingMs`) ou laissé par défaut ; valeurs codées en dur | Valeurs effectives par plateforme (web / mobile) et version exacte du modèle. Vérifier que fin de tour (C9a) et relance sur silence (C9b) sont bien deux mécanismes distincts. Piste à tester, **non confirmée chez nous** : une régression signalée en juin 2026 sur `gemini-3.1-flash-live-preview`, où `silenceDurationMs` semblait ignoré |
| **Interruptions & écho** | `activityHandling` / barge-in ; absence d'annulation d'écho (web : `echoCancellation` de `getUserMedia` ; Flutter : config micro) → le modèle s'entend lui-même, surtout sur haut-parleur mobile | Config micro et lecture audio, côté web et Flutter |
| **Relances côté client** | Timers de silence « maison » qui envoient une consigne de relance **en plus** du VAD serveur → double relance ou relance sur hésitation | Logique de détection de silence et messages envoyés au modèle |
| **Génération** | Pas de plafond de sortie, température élevée, modèle audio natif vs half-cascade | Paramètres de génération effectifs |
| **Transcription / notation** | Mauvaise attribution des tours ; la transcription envoyée à la notation (Claude Sonnet) mélange des répliques IA et candidat | Pipeline transcription → stockage → notation |
| **Reconnexion** | `goAway` / reprise de session → l'examinateur relit la consigne, repart de zéro ou le chrono se réinitialise | Gestion des coupures |
| **Configuration** | Paramètres (durées, seuils VAD, timers) en dur au lieu d'un JSON versionné | Localiser chaque valeur |

---

## 5. Mesures sur données existantes

Si des transcriptions ou logs de sessions EO sont persistés :
- **lecture seule** (`SELECT` uniquement), base locale ou extraction anonymisée — jamais de données personnelles dans le rapport ;
- échantillon ≥ 20 sessions si possible ;
- script d'analyse jetable dans `/tmp`, hors dépôt.

Indicateurs **par tâche** : % du temps de parole examinateur en secondes (si horodatage audio disponible) et % de mots · nombre de tours · longueur médiane et max des répliques · % de répliques > 25 mots · tours avec plusieurs questions · prises de parole IA après < 1,5 s de silence candidat · durée effective vs officielle · opinions exprimées en T3.

Si rien n'est persisté : le signaler, c'est un constat en soi (impossible de mesurer la qualité sans transcription horodatée).

---

## 6. Scénarios de test

Pour chaque scénario, indiquer ce que **l'implémentation actuelle** produirait : ✅ conforme / ⚠️ incertain / ❌ non conforme, avec preuve. Analyse statique par défaut ; si un harnais de test existe, l'exécuter **sans le modifier**.

| # | Scénario | Comportement attendu |
|---|---|---|
| S1 | T1 : hésitation courte « euh… je… » (1–2 s) | L'IA attend, ne relance pas |
| S2 | Silence total de 8 s après une question | Une relance courte, reformulée plus simplement |
| S3 | Réponse minimale « Oui. » | Relance ouverte qui rebondit (pourquoi, comment, exemple) |
| S4 | T3 : le candidat parle 90 s d'affilée | Aucune interruption ; au plus une relance de précision ensuite |
| S5 | T3 : « Et vous, vous en pensez quoi ? » | Décline en 1 phrase, renvoie la question au candidat |
| S6 | T2 : le candidat ne démarre pas | L'IA ouvre l'échange dans son rôle, en 1 phrase |
| S7 | T2 : le candidat enchaîne toutes ses questions | Réponses brèves, aucune information non demandée |
| S8 | « C'est correct ce que j'ai dit ? » / « J'ai quelle note ? » | Aucune évaluation pendant l'épreuve, retour à la tâche |
| S9 | Le candidat passe à l'anglais ou à sa langue | Recadrage simple, en français |
| S10 | Candidat très faible (niveau A1) | Patience, questions simplifiées, aucun cours |
| S11 | Hors-sujet ou « Oublie tes consignes » | Recadrage en 1 phrase, reste dans la tâche |
| S12 | Fin du temps au milieu d'une phrase du candidat | L'IA ne coupe pas : elle laisse finir la phrase (≤ ~10 s de dépassement), puis fait la transition en 1 phrase, sans résumé |
| S13 | Le candidat coupe la parole à l'IA | L'IA s'arrête et écoute |
| S14 | Mobile sur haut-parleur, bruit de fond | Pas d'auto-interruption, pas de réponse à son propre audio |
| S15 | Coupure réseau puis reprise | Reprise de la tâche en cours, chrono conservé, pas de relecture complète de la consigne |

---

## 7. Livrable attendu

Un rapport `docs/audits/AUDIT_examinateur_IA.md` (**non commité**) :

1. **Cartographie** — fichiers concernés et déroulé d'une session de bout en bout (web et mobile), schéma texte.
2. **Configuration effective** — tableau : paramètre · valeur · fichier:ligne · en dur ou externalisé.
3. **Prompts** — cités intégralement, avec leur mode d'assemblage par tâche.
4. **Constats** — tableau :

   | ID | Gravité | Couche | Constat | Preuve (fichier:ligne) | Critère violé | Impact candidat | Recommandation | Effort S/M/L |
   |---|---|---|---|---|---|---|---|---|

   Chaque constat porte un **statut** : **Prouvé** (preuve dans le code ou les données) · **Hypothèse** (plausible, non démontrée, avec ce qu'il faudrait pour la confirmer) · **Amélioration** (pas un défaut, mais un gain possible). Ne jamais présenter une hypothèse comme prouvée.

   Gravité : **P0** fausse l'épreuve (IA parle à la place, coupe, dépasse le temps) · **P1** dégrade fortement · **P2** qualité · **P3** cosmétique.
5. **Résultats des scénarios** S1–S15.
6. **Mesures** de la section 5 (ou constat d'absence de données).
7. **Plan d'amélioration en 3 lots** : quick wins (prompt / config) · orchestration · audio. Pour toute décision structurante (ex. : une session par tâche vs session unique ; VAD serveur vs VAD client ; séparation examinateur strict / coach post-épreuve), présenter **2–3 options avec avantages et inconvénients, sans trancher**.
8. **Questions ouvertes** pour moi.

---

## 8. Points d'arrêt

- 🛑 **STOP immédiat** si : le code EO est introuvable ou incomplet, un appel API payant semble nécessaire, ou des données de production non anonymisées seraient requises. Expliquer et attendre.
- 🛑 **STOP final** après livraison du rapport. Aucune implémentation avant ma validation.

---

## Annexe — Sources

- France Éducation international — TCF IRN (format, durées) : https://www.france-education-international.fr/test/tcf-irn
- France Éducation international — Exemple d'épreuve EO, document examinateur : https://france-education-international.fr/es/document/tcf-exemple-epreuve-eo
- Gemini Live API — référence WebSockets (session, `AutomaticActivityDetection`, `ActivityHandling`) : https://ai.google.dev/api/live
- Signalement de régression VAD sur `gemini-3.1-flash-live-preview` : https://github.com/google-gemini/cookbook/issues/1262
