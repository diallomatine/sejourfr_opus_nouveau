# BRIEF — Moteur de cycle CIVIQUE — Phase 0 : DIAGNOSTIC + AUDIT

Repo : `sejourfr_opus_nouveau`.
Spec de référence : `SPEC_cycle_plan_civique.md` (+ `SPEC_cycle_plan.md` pour le moteur TCF).
Décisions en vigueur : `docs/decisions/plan-parcours-tcf.md` et `REPONSES_AUDIT_cycle_plan.md`.

> ⛔ **HARD STOP.** Lecture et requêtes de lecture seulement. **Aucun fichier de code, aucune migration,
> aucun test créé ou modifié.** Livrable unique : `docs/audits/AUDIT_cycle_plan_civique.md`.
> Arrête-toi après l'avoir écrit et attends le go explicite avant toute implémentation.

---

## 1. Diagnostic du contenu — à faire en premier

C'est le préalable : si le tagging n'est pas complet, R2 est faux et le reste de l'audit est théorique.

Produire des **chiffres réels** issus de la base (requêtes de lecture uniquement), pas une lecture de code :

| Mesure | Attendu dans le rapport |
|---|---|
| Couverture du tagging | Nombre et **pourcentage** de `questions` civiques actives avec `civic_notion_id` renseigné. Global, puis **par thématique**, puis **par mention** (CSP / CR / NAT). |
| Notions orphelines | Les `civic_notions` actives ayant **0** question rattachée, et celles en ayant **moins de 20** (une notion ne peut pas alimenter 2 séries réussies si elle n'a pas assez de questions). |
| Répartition par thème | Nombre de questions par thématique et par notion, avec l'écart type. Signaler tout thème trop pauvre pour composer un examen de 20 questions. |
| Mises en situation | Comment le type « mise en situation » est-il porté aujourd'hui (colonne, enum, `question_type`) ? Combien y en a-t-il, et sont-elles taguées à une notion ? Sont-elles réparties sur les 5 thèmes ou concentrées ? |
| `question_notion_suggestions` | Table encore vide, ou alimentée depuis ? Le tagging a-t-il été fait à la main, par script, ou par LLM ? Chemin du script le cas échéant. |
| Cohérence thème ↔ notion | Existe-t-il des questions dont le `civic_notion_id` appartient à une notion d'un **autre** thème que le `theme_id` de la question ? Les lister. |
| `is_active` | Les compteurs ci-dessus excluent-ils bien le contenu non validé (`is_active = FALSE`, `status`) ? Donner les deux chiffres. |

**Conclusion attendue** : le tagging permet-il, oui ou non, d'appliquer R2 au grain de la notion sur les
5 thèmes et les 3 mentions ? Si non, dire exactement ce qui manque, en nombre de questions.

---

## 2. Répondre aux questions ouvertes de la spec §5

Pour chacune : ce que dit l'existant, les options, celle que tu recommandes, et son coût. **Sans trancher.**

1. **Où vit la notion dans le moteur** — `skills` est TCF-only (`chk_skills_section`),
   `learning_plan_observations.skill_id` est une FK réelle. Option A : généraliser `skills` (colonne
   `module`, CHECK relâché) et importer les 40 notions. Option B : garder `civic_notions` et rendre
   l'observation polymorphe. Chiffrer l'impact de B sur le nombre de requêtes et de services touchés.
2. **Plan civique existant** — `service/plancivique/` (13 fichiers, Leitner 5 boîtes, 100 % dérivé) :
   le cycle s'y superpose, ou le Leitner est retiré ? Dire précisément ce que le Leitner pilote
   aujourd'hui et ce qui casserait s'il disparaissait.
3. **Mises en situation** — option A (type de question présent dans chaque bloc) ou option B (6ᵉ bloc
   transversal), à la lumière des chiffres du §1.
4. **Examen de thème** — confirmer le format réel en base (20 questions / seuil 16 attendu) et dire s'il
   est composé dynamiquement ou par `ExamTemplate`. L'audit TCF notait « aucun template thème ».
5. **Changement de mention en cours de cycle** — que fait le code aujourd'hui quand la mention change ?
   Y a-t-il un historique de mention ? Historiser le cycle est-il faisable sans perte ?

---

## 3. Inventaire technique

Même méthode que l'audit TCF, restreinte à ce qui diffère :

- **Schéma** : prochain numéro de migration, contraintes qui gênent un cycle civique
  (`journey.target_level` CECRL, `journey_lot.exam_type` CHECK sur les 4 épreuves TCF, `chk_skills_section`).
  Ce que la colonne `module` livrée en P2 permet déjà, et ce qu'il reste.
- **Métier** : `service/diagnosticcivique/*`, `service/plancivique/*`, `CivicExamFormat`,
  composition des examens civiques, endpoint `GET /api/me/civic-plan`.
- **Freemium** : ce qui est ouvert au gratuit côté civique aujourd'hui, et ce que le ledger
  `free_entitlement_usage` (livré en P2) couvre déjà pour « 1 examen de thème offert à vie ».
- **Fronts** : `CivicPlanPanel.tsx` ⇄ `civic_plan_view.dart`, écart avec les blocs de thème attendus,
  et quelles primitives de kit livrées en P5 sont réutilisables telles quelles.
- **Tests** : couverture existante sur le civique, fixtures réutilisables, fabriques manquantes.

---

## 4. Livrable

`docs/audits/AUDIT_cycle_plan_civique.md` :

1. **Diagnostic du contenu** — les tableaux du §1, avec les chiffres, et la conclusion oui/non sur R2.
2. **Réponses aux 5 questions** du §2, format : existant / options / reco / coût.
3. **Inventaire** — `élément attendu | existe | chemin | remarque`.
4. **Écarts bloquants**, classés par gravité.
5. **Conflits** avec les décisions TCF déjà datées, avec l'option de résolution recommandée, non appliquée.
6. **Questions fermées** restantes, formulées en oui/non.
7. **Découpage proposé**, avec les points STOP suggérés.

Rappels :
- La page **historique des cycles** reste bloquée : template non fourni. Ne rien concevoir dessus.
  ⚠️ *(Périmé : blocage **levé** le 2026-09-20, P8.9 livrée. Brief conservé tel quel, daté.)*
- Le moteur civique **ne réinvente aucune règle** : R1, R2, R3, déblocage, cycle en attente,
  historisation sont ceux du TCF. Tout écart proposé doit être signalé comme un conflit, pas appliqué.

> ⛔ **RAPPEL STOP.** Termine après le rapport. N'ouvre aucune phase d'implémentation, même si le
> diagnostic conclut que le tagging est complet et le chantier trivial.
