# Plan — points ouverts

> Créé le **2026-09-13**, à la demande du propriétaire, à la sortie du chantier
> « 5 micro-sujets → vérification → recalcul » (`docs/regles/plan.md`).
>
> 🛑 **Rien n'est à coder ici.** Ce fichier tient les deux ceintures que ce
> chantier a laissées volontairement en place : elles ne se changent pas sans un
> scénario produit réel. Il est **court et factuel** ; les règles, elles, vivent
> dans `docs/regles/plan.md`.

---

## 1. Une tâche sans sujet de production publié

**Comportement actuel.** À `5/5`, `LearningPlanService` demande une vérification
à `ReassessmentExerciseSelector`. Si la `SkillTaskCode` de la compétence n'a
**aucun** sujet de production actif et non diagnostique, le sélecteur ne rend
rien — c'est sa 3ᵉ règle, et c'est un cas **normal**, pas une erreur. La carte
retombe alors sur son micro-exercice et le dit : la nature reste `A_RENFORCER`,
jamais `A_VERIFIER` sur un petit sujet. L'étape peut donc, dans ce seul cas,
reproposer un des cinq sujets déjà traités.

**Risque réel.** Faible aujourd'hui : les 48 compétences publiées ont toutes une
tâche pourvue (20 sujets sur EE tâche 3, par exemple), et
`PlanContentAvailability` journalise ce qu'il coupe. Le risque n'est pas
théorique pour autant — il naîtrait d'un **pourrissement du catalogue** (une
tâche dépubliée, une migration de contenu ratée), et il se manifesterait
exactement comme l'ancien défaut : un candidat tournant sur ses cinq sujets.

**Recommandation.** Ne rien coder. **Surveiller le catalogue**, pas le moteur :
toute ligne du log de `PlanContentAvailability` signale le pourrissement avant
qu'un candidat le voie. Si un jour ce cas devient réel, la bonne réponse est de
publier le sujet manquant, pas d'inventer un repli côté Plan.

**Priorité.** Basse — surveillance, pas développement.

---

## 2. La fenêtre de retour est celle de `transfer-proof-days` (60 j)

**Comportement actuel.** `SkillMasteryEngine.verificationSubmitted()` ne tient
une vérification pour rendue que si elle est encore dans
`sejourfr.learning-plan.mastery.transfer-proof-days` (**60 jours**). Passé ce
délai, la compétence redevient une priorité ordinaire, et — son étape étant
toujours terminée — le Plan lui repropose **une autre** production de
vérification, jamais les mêmes cinq petits sujets.

**Risque réel.** Faible, et le sens de l'erreur est le bon : au pire un candidat
revoit une compétence fragile un peu trop tôt ou un peu trop tard. 60 j est un
**emprunt** — c'est la fenêtre de « une réussite en situation compte encore » —,
pas une valeur calibrée sur « au bout de combien de temps faut-il revérifier ».
Les deux questions se ressemblent assez pour partager un seuil aujourd'hui ;
elles ne sont pas la même.

**Recommandation.** Ne rien coder. Si une mesure montre que le rythme de retour
est mauvais, ajouter **une clé distincte** sous
`sejourfr.learning-plan.mastery` (avec son défaut dans le POJO, comme tous les
autres nombres) plutôt que de bouger `transfer-proof-days` — celui-ci porte
aussi `transferProven`, et le déplacer changerait **qui est acquis**.

**Priorité.** Basse — à rouvrir seulement avec une mesure, jamais sur une
intuition.
