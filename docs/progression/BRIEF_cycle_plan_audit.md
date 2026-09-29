# BRIEF — Moteur de cycle (Plan) — Phase 0 : AUDIT

Repo : `sejourfr_opus_nouveau` (monorepo).
Spec fonctionnelle de référence : `SPEC_cycle_plan.md`.

> ⛔ **HARD STOP.** Cette phase est **exclusivement un audit**. Aucun fichier de code, aucune migration, aucun test ne doit être créé ou modifié. Le seul livrable est `docs/audits/AUDIT_cycle_plan.md`. Après l'avoir écrit, arrête-toi et attends validation explicite avant toute implémentation.

---

## Objectif de l'audit

Déterminer ce qui existe déjà, ce qui manque et ce qui entre en conflit, avant d'écrire la moindre ligne du moteur de cycle. La spec décrit la cible ; l'audit décrit l'écart.

---

## 1. Modèle de données (backend)

Inspecter les entités JPA, les fichiers TopModel le cas échéant, et l'historique Flyway.

| À vérifier | Question à trancher dans le rapport |
|---|---|
| `Question`, `Choice`, `Theme`, `Passage` | Quelle granularité de rattachement existe aujourd'hui ? Un tag plus fin qu'un thème existe-t-il déjà (colonne, enum, table de liaison) ? |
| Entité `Competence` | Existe-t-elle sous un autre nom (skill, objectif, capacité, descripteur) ? |
| `QuestionCompetence` / `UserCompetenceStatus` | Existent ? Sinon, quelles tables devraient les porter ? |
| `UserQuestionStatus` | Que stocke-t-elle exactement ? Peut-elle servir de base au calcul « 2 séries réussies » (R2) ou faut-il un agrégat dédié ? |
| `Attempt`, `AttemptQuestion`, `Answer` | Un `Attempt` porte-t-il un type (entraînement libre / examen d'épreuve / examen complet / diagnostic) ? R1 en dépend directement. |
| `ExamTemplate`, `ExamTemplateRule` | Les règles de composition permettent-elles déjà de générer un examen **d'une seule épreuve** et un examen **complet** ? |
| `Attempt` ↔ épreuve/thème | Peut-on savoir, à partir d'un `Attempt` terminé, quelle(s) épreuve(s) il couvre ? |

Signaler explicitement toute entité de la spec (`Cycle`, `CycleBloc`, `CycleEtape`) qui n'a **aucun** équivalent.

## 2. Numérotation Flyway et conventions

- Dernier numéro de migration utilisé, convention de nommage, convention UUID en vigueur.
- Présence du pattern `is_active = FALSE` pour le contenu non validé.
- Contraintes d'unicité ou index qui gêneraient « un seul cycle `EN_COURS` et un seul `EN_ATTENTE` par module et par utilisateur ».

## 3. Couche métier existante

- Y a-t-il déjà un service de recommandation, de priorisation, de « prochaine action », ou un embryon de plan ? Chemin de fichier + ce qu'il fait réellement.
- Comment est calculé le niveau par épreuve (CO/CE/EE/EO) aujourd'hui ? Où vit ce calcul ?
- Où est branchée l'analyse IA (Claude Sonnet pour EE, Gemini Live pour EO) ? Quel objet la déclenche, quel objet stocke le résultat ?

## 4. Quotas et abonnement

- Où sont implémentés les quotas gratuits aujourd'hui (analyse IA/jour, accès contenu) ?
- Existe-t-il une notion de « première fois gratuite » réutilisable pour l'examen EE/EO offert ?
- `Plan` / `UserSubscription` : comment le back expose-t-il l'état d'abonnement au front ?

## 5. Configuration externalisée

- Lister les fichiers JSON de config déjà versionnés et leur mécanisme de chargement.
- Indiquer où devrait vivre le bloc `cycle.json` de la section 9 de la spec.

## 6. Front (web Next.js + mobile Flutter)

- Écrans Accueil et Plan existants : chemins, état de complétude, données consommées.
- Contrats d'API actuellement appelés par ces écrans.
- Mobile : ce que Drift stocke déjà localement, et ce que l'offline-first impliquerait pour un cycle (le cycle doit-il être calculé côté serveur uniquement, ou rejouable hors ligne ?). Donner ton avis argumenté, sans trancher.

## 7. Tests

- Couverture existante sur `Attempt` / scoring / quotas.
- Fixtures réutilisables pour simuler un parcours utilisateur complet.

---

## Livrable attendu

Fichier unique `docs/audits/AUDIT_cycle_plan.md`, structuré ainsi :

1. **Synthèse** — 10 lignes maximum : ce qui existe, ce qui manque, le principal risque.
2. **Inventaire** — un tableau par section ci-dessus : `élément attendu | existe (oui/non/partiel) | chemin | remarque`.
3. **Écarts bloquants** — ce qui empêche d'implémenter la spec en l'état, classé par gravité.
4. **Conflits** — code ou modèle existant que la spec contredit, avec l'option de résolution que tu recommandes (sans l'appliquer).
5. **Questions ouvertes** — ce que tu ne peux pas trancher seul, formulé en questions fermées.
6. **Découpage proposé** — les phases d'implémentation que tu recommandes, dans l'ordre, avec les points STOP suggérés. Proposition uniquement.

Pas de code dans le rapport, sauf extraits courts nécessaires pour justifier un constat.

---

> ⛔ **RAPPEL STOP.** Une fois `AUDIT_cycle_plan.md` écrit, termine ta réponse. N'enchaîne sur aucune phase d'implémentation, même si l'audit conclut que c'est trivial.
