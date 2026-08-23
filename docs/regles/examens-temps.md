# Temps des examens blancs — un chrono par épreuve

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Contenu verbatim, aucune réécriture.**
> Origine : lignes 555-643 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier porte la loi de ce sous-système : on l'ouvre **quand on travaille dedans**.
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

## Temps des examens blancs — un chrono PAR ÉPREUVE (2026-08-15)

🛑 **Le chrono global de 90 min n'existe plus.** Le temps restant d'une épreuve
**ne se transfère jamais** à la suivante, et l'abandon / reprise entre épreuves
est officiellement supporté : un décompte global devenait absurde (reprendre le
lendemain aurait trouvé l'examen expiré). `FULL_EXAM_TOTAL_SECONDS` est
supprimée, `parent.timer_started_at` survit comme **trace du début réel**, plus
comme ancre d'un décompte. Ne pas la réintroduire.

- **`DureeEpreuve` est la seule autorité** (enum, pas de config : c'est une
  donnée d'examen, pas un réglage) : CO 20 min · **CE 35 min** · EE 30 min ·
  STRUCTURE 20 min. Aucune constante de durée ailleurs.
  `ExamTemplate.durationSeconds` reste prioritaire quand un template pilote
  l'examen. ⚠️ **`FULL_EXAM_CE_SECONDS` est supprimée** : la CE était raccourcie
  à 30 min dans l'examen complet pour tenir dans les 90 min — **une épreuve a la
  même durée où qu'elle soit jouée**, c'est la règle « les conditions
  s'appliquent au module ». Total indicatif ≈ **95 min**, jamais opposable.
- **`FullTcfExamResponse.SubAttempt` porte son temps** : `timeLimitSeconds`,
  `timerStartedAt`, `deadlineAt`. **`deadlineAt` est l'unique base du compte à
  rebours** des 3 fronts — aucun ne recalcule d'échéance, sinon le temps
  cesserait de courir pendant une absence. C'est l'absence de ces champs qui
  avait forcé les durées en dur, et fait diverger web et mobile (CE annoncée
  30 min ici, 35 min là).
- **Un score QCM TCF s'affiche TOUJOURS sur 100-499**, jamais sur le pondéré
  interne. `SubAttempt` porte `calibratedScore` (nullable), rempli par
  `FullTcfExamResponseBuilder` **en déléguant à `TcfLevelEstimatorService`** —
  la formule (correction du hasard 25 %, bornes 100-499) ne se recopie jamais.
  `null` pour EE/EO, pour une épreuve `locked`, et quand le pondéré manque : le
  service rendrait sinon sa borne basse et l'écran afficherait « 100/499 » là où
  on ne sait rien. Repli déclaré une fois par front (`qcmScoreLabel`, miroirs
  `web/lib/exam-levels.ts` ⇄ `mobile/core/models/full_tcf_exam.dart`) : calibré
  ⇒ `x/499`, sinon le brut `x/maxScore`, **jamais un `/499` fabriqué à partir
  d'un pondéré**. `score`/`maxScore` restent servis. ⚠️ Ne vaut que pour le
  **TCF** — le civique se lit sur `/40` ou `/20`.
- **`POST /begin?epreuve=…` est appelé sur les 4 épreuves** (obligatoire pour
  l'EE, qui n'avait **aucune** échéance avant). Idempotent par ancre : reprendre
  une épreuve ne remet pas son chrono à zéro.
- **L'ORAL n'a pas de chrono d'épreuve** (`timeLimitSeconds` = `null`), calqué
  sur le vrai TCF : la consigne s'affiche **sans aucun décompte**, et le temps ne
  part qu'au **lancement de la tâche** (« Je suis prêt · Commencer la tâche »),
  sur `production_tasks.duree_max_sec` (180 / 210 / 210 s). Auto-stop, puis tâche
  suivante. Reste un **garde-fou de session de 2 h**
  (`DureeEpreuve.EO_GARDE_SESSION_SECONDS`), **invisible des fronts et jamais
  présenté comme un chrono** : sans lui une session EO reste ouverte
  indéfiniment et un compte gratuit y accumule des évaluations IA payantes. Il
  ne s'applique pas aux sous-épreuves d'un examen complet.
- **Le chrono QCM est enfin opposable serveur** : `POST /api/attempts/{id}/answers`
  (et sa jumelle publique) rend **422** après échéance + `SUBMIT_GRACE_SECONDS`
  (60 s, réutilisée). Il n'était lu que par les fronts — le respecter était une
  politesse du client. Le refus porte sur **une réponse**, jamais sur la session.
- **Clôture automatique paresseuse à la lecture** (`GET /attempts/{id}`,
  `GET /full-tcf-exams/{id}`), sans job planifié — même mécanique que
  l'expiration des abonnements (`SubscriptionService.isCovering`) : un attempt
  hors délai est terminé + scoré sur les réponses existantes. Un retour dans
  l'app peut donc rendre une épreuve déjà `finishedAt` : **c'est normal**.
- **Abandon / reprise — le temps est la seule autorité, quitter ne suspend
  rien.** Une épreuve terminée est conservée. Revenir **avant** l'échéance rend
  le temps réellement restant ; **après**, l'épreuve est clôturée avec ce qui
  était enregistré. 🛑 **Il n'existe AUCUN flux « recommencer une épreuve
  interrompue » — ne pas en construire** : le chrono qui continue de tourner
  suffit à garantir la fiabilité de la simulation, et faire tout refaire à qui a
  reçu un appel téléphonique serait une punition sans contrepartie.
  **Exception EO** : le temps ne courant que pendant une tâche lancée, quitter
  sur l'écran de consigne ne coûte rien et les tâches rendues sont conservées.
- ⚠️ **Trou connu et assumé : une EE abandonnée se clôture VIDE.** Aucune
  persistance de brouillon n'existe (`production_submissions.texte_soumis` n'est
  écrit qu'à l'envoi final, aucun autosave, aucune table) — « clôturée avec ce
  qui était enregistré » signifie donc *rien* à l'écrit : 3 tâches à 0, bilan
  `A1_NON_ATTEINT`. **Ne pas construire de système de brouillon sans arbitrage
  produit explicite** (colonne + endpoint d'autosave + décision sur ce qu'on
  évalue d'un texte non envoyé).
- **`ContinuiteSimulation`, dérivé serveur et jamais persisté** (philosophie
  `SkillStatusResolver` / `SituationDansNiveau`) : `SESSION_UNIQUE`
  (« Simulation complète — conditions examen ») / `PLUSIEURS_SESSIONS`
  (« Simulation complétée en plusieurs sessions »), **null tant que l'examen
  n'est pas terminé**. Bascule au-delà de `PAUSE_MAX_ENTRE_EPREUVES` = **15 min**
  entre la fin d'une épreuve et le lancement de la suivante. Libellés gelés par
  `ContinuiteSimulationTest`, miroirs manuels web (`FULL_TCF_EXAM_CONTINUITE_LABEL`,
  `lib/types.ts`) et mobile (`label` de l'enum). Le 3ᵉ cas de la spec (« pas de
  résultat global définitif ») **existe déjà** : `finalLevelPartial` /
  `epreuvesCountedInFinalLevel` — **ne pas créer de notion parallèle**.
- **Miroir de durée côté fronts** : `web_sejoufr/lib/exam-durations.ts` et
  `mobile_sejourfr/lib/core/utils/epreuve_duration.dart`, **une seule table
  chacun**, réservée aux écrans **antérieurs à l'examen** (briefings, vitrines —
  aucun DTO n'existe encore à ce moment). Dès qu'un objet serveur existe, c'est
  `timeLimitSeconds` qui fait foi. Le total annoncé est **recalculé**, jamais
  écrit. Le temps conseillé EE (7 / 10 / 13 min) est **éditorial**, purement
  indicatif, et sa somme vaut exactement les 30 min réelles.
