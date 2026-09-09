# Décisions prises pendant l'implémentation, sans arbitrage du propriétaire

> **À quoi sert ce document.** Le propriétaire a demandé que les lots
> s'enchaînent sans l'attendre. Chaque fois qu'un choix ne se déduisait **pas**
> de `50_` (qui fait autorité), de `40_AUDIT`, ni d'un invariant déjà écrit dans
> `CLAUDE.md`, il est consigné ici : **ce qui a été décidé, l'alternative
> écartée, et ce que coûte le retour arrière**. Rien ici n'est définitif : c'est
> une liste de choses à confirmer ou à corriger.
>
> Il ne consigne **pas** les décisions qui découlaient directement d'une spec ou
> d'un invariant du dépôt — celles-là sont dans le code et dans `docs/regles/`.
>
> Ordre : par lot, le plus récent en bas.

---

# L7 — la boucle de réévaluation

## D-L7-1 · L'éligibilité est une **route dédiée**, pas un champ du diagnostic

**Décidé** : `GET /api/tcf-diagnostics/eligibility`, un DTO à part
(`TcfReassessmentEligibilityDto`).

**Alternative écartée** : ajouter `canReassess` / `locked` sur
`TcfDiagnosticDto`. Refusé parce que la question se pose **aussi quand il n'y a
aucun diagnostic** (le `/current` rend alors 204) : le champ aurait été
inatteignable exactement dans le cas où l'écran doit décider quoi afficher.

**Retour arrière** : trivial tant que rien d'autre ne consomme la route.

## D-L7-2 · Une priorité terminée ouvre la porte du **délai**, jamais celle du paiement

`10_` §4.6 dit « 1 tous les 14 jours, **ou** déclenchée par le plan quand une
priorité est terminée », sans préciser si la dérogation vaut aussi pour
l'abonnement.

**Décidé** : elle ne vaut que pour le délai. Un compte gratuit qui termine une
priorité voit toujours le paywall.

**Pourquoi** : l'inverse rendrait la réévaluation gratuite pour quiconque
termine une étape — c'est-à-dire pour la cible même du produit. Ce serait un
changement de modèle économique, pas un détail d'implémentation.

**Si le propriétaire veut l'inverse** : une ligne dans `TcfReassessmentService`
(inverser l'ordre des deux portes). Verrouillé par le test
`lePlanNouvrePasLaPorteCommerciale`.

## D-L7-3 · « Priorité terminée » = **étape franchie du Plan**, lue et non redéfinie

**Décidé** : `LearningPlanPriorityResolver.franchies` (transfert prouvé), avec
une observation postérieure au dernier diagnostic.

**Alternative écartée** : une définition propre à la réévaluation (« la priorité
n°1 a changé », « une compétence est passée SOLID »). Refusé : deux lectures du
même historique se sont déjà contredites en production sur ce dépôt, et le
journal de `franchies` documente l'incident.

**Coût mesuré** : une requête d'historique (index existant) + deux fonctions
pures, à chaque lecture de l'éligibilité. Pas de construction du Plan complet.

## D-L7-4 · L'écran T11 remplace la liste des sections quand le diagnostic est **clos**

Avant L7, un diagnostic terminé affichait quatre cartes « Terminée » et un
bouton « Voir mon résultat ». `30_` §5.6 décrit un écran différent (T11).

**Décidé** : `status == COMPLETED` ⇒ T11, sur web **et** mobile.

**Ce qui n'a pas été touché** : rien du parcours de passation.

## D-L7-5 · Le paywall de réévaluation réutilise `DIAGNOSTIC_REPORT`

**Décidé** : `ctaLocation = DIAGNOSTIC_REPORT`, distingué par
`screen = "diagnostic_tcf_reevaluation"` côté web.

**Alternative écartée** : une valeur d'enum `REASSESSMENT`. Refusé pour ce lot :
elle touche le backend et les trois fronts, et l'analyse du funnel garde le
grain nécessaire par `screen`.

**À trancher** si le propriétaire veut une ligne dédiée dans la table « quel
écran déclenche l'achat ? ».

## D-L7-6 · Le bloc « Progrès TCF » (T28) n'est **pas** dans ce lot

`30_` §7 demande un historique des estimations et une évolution par épreuve sur
l'écran Progrès. Ce lot livre la **comparaison entre deux diagnostics**, sur
l'écran de résultat.

**Décidé** : T28 reste dans **L11** (« Examens blancs branchés + Progrès
unifié », `50_` §8), qui est le lot de cet écran. Livrer une moitié de T28 ici
aurait créé deux endroits qui affichent la même évolution.

## D-L7-7 · Une **baisse** de niveau est servie et affichée

Aucune spec ne dit quoi faire quand une réévaluation mesure moins bien.

**Décidé** : `BAISSE` existe, est servie, et les fronts l'affichent (« Votre
niveau a baissé »), sans dramatiser (pas de rouge, pas d'alerte).

**Pourquoi** : masquer une baisse rendrait invendable exactement ce que la
réévaluation payante promet de mesurer.

**Si le propriétaire préfère un autre ton**, c'est un libellé dans
`lib/tcf-diagnostic.ts` + son miroir Dart, rien d'autre.

## Réserve ouverte

Le champ `daysUntilAvailable` est servi **aussi** quand le Plan a ouvert la
porte en avance (avec `triggeredByPlan = true`), pour que l'écran puisse dire
*pourquoi* le bouton est là. Aucun écran ne l'utilise encore dans ce sens : ils
affichent la phrase du Plan. À supprimer si ça reste inutilisé.
