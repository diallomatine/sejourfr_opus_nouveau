# Contradictions ouvertes du dépôt

> **Créé le 2026-08-23**, à la restructuration de `CLAUDE.md` racine.
> Ces trois points sont des endroits où le dépôt **se dit deux choses différentes**. La
> restructuration ne les a **pas tranchés** — sauf #1, qui l'était déjà dans le texte lui-même.
> **Lu à la demande.** À ouvrir avant de trancher un de ces points.
>
> Chaque entrée donne les **deux formulations verbatim**, leur emplacement d'origine dans
> l'ancien `CLAUDE.md`, leur emplacement actuel, et la date de chacune.

---

## #1 — Freemium du Plan : « entièrement visible » vs « on floute l'action » ✅ TRANCHÉE

**Statut : APPLIQUÉE le 2026-08-23.** Le texte se tranchait déjà lui-même — la formulation B
révoquait explicitement la formulation A. La révocation a donc été appliquée : A est retirée du
fichier de règles, et consignée ici.

### Formulation A — RETIRÉE (posée avant le 2026-08-21)

Origine : `CLAUDE.md` racine **l. 178-181**, section *Freemium*, puce « Compte gratuit, Plan
personnalisé ». Aujourd'hui : retirée de `docs/regles/freemium.md`, remplacée par un renvoi ici.

> **Compte gratuit, Plan personnalisé** : le Plan est **entièrement visible**,
> diagnostic compris. Aucune priorité, aucune compétence observée, aucun
> compteur n'est masqué — seul un `locked` est posé.

### Formulation B — EN VIGUEUR (arbitrage du propriétaire, 2026-08-21)

Origine : `CLAUDE.md` racine **l. 944-949**, section *Diagnostic initial TCF et Plan
personnalisé*. Aujourd'hui : `docs/regles/plan.md`.

> **On floute l'ACTION pas encore accessible, jamais le RÉSULTAT mesuré**
> (arbitrage du propriétaire, 2026-08-21). ⚠️ Cette règle **révoque** la
> formulation précédente — « le Plan reste intégralement visible sans
> abonnement, aucune priorité, aucune compétence observée, aucun compteur n'est
> masqué ». Ne pas la réintroduire au motif qu'elle est encore écrite quelque
> part : ce qui suit fait foi, et trois commits en dépendent.

### Pourquoi c'était grave

La formulation B disait « ne pas la réintroduire au motif qu'elle est encore écrite quelque
part » — et A était **encore écrite dans le même fichier, 766 lignes plus haut**. Un agent qui
lisait §3 sans lire §9 appliquait la règle révoquée. C'est le défaut qui a motivé la
restructuration entière.

### Ce qui fait foi aujourd'hui

Le Plan reste **lisible** en entier pour un compte gratuit ; sont **floutés** les items de
séance et les lignes de priorité **verrouillés**, plus la liste que reprend la modale
« Pourquoi cette séance ? ». Détail exhaustif : `docs/regles/plan.md`.

---

## #2 — Tests front : interdits, mais encore cités comme garde-fous ⛔ NON TRANCHÉE

### Formulation A — la règle générale (posée le 2026-08-09)

Origine : `CLAUDE.md` racine **l. 4047-4057**, section *Préférences de collaboration → Tests*.
Aujourd'hui : `docs/regles/collaboration.md`.

> 🛑 **On n'écrit plus AUCUN test sur les fronts.** Ni `web_sejoufr`, ni `admin_sejourfr`, ni
> `mobile_sejourfr` : pas de `*.test.ts`, pas de `flutter_test`, pas de test de widget, pas de
> test de libellé gelé, pas de test de layout. **Les seuls tests du dépôt sont ceux du
> backend** […] Cette règle **prime** sur toute consigne de test écrite ailleurs dans ce
> fichier ou dans un `CLAUDE.md` local.

### Formulation B — les garde-fous encore nommés

Origine 1 : `CLAUDE.md` racine **l. 2668**, section *Notation IA*.
Aujourd'hui : `docs/regles/notation-ia.md`.

> **Repli obligatoire quand le titre manque** : « Sujet N » + consigne, déclaré une seule fois
> par front (`productionSubjectTitle`, `lib/types.ts` ⇄ `widgets/production_common.dart`,
> libellé gelé par test des deux côtés).

Origine 2 : `CLAUDE.md` racine **l. 3795-3811**, section *Module Compétences TCF*.
Aujourd'hui : `docs/regles/competences.md`.

> Elles sont figées par un test **par couche**, sur exactement les mêmes chaînes :
> `SkillLabelsTest` (backend), `lib/skill-labels.test.ts` (web),
> `test/skill_models_test.dart` (mobile). Un libellé qui bouge, ce sont **quatre**
> fichiers à changer dans la même passe.

### État de la contradiction

Le texte s'auto-corrige **partiellement** juste après l'origine 2 :

> ⚠️ **Les tests front cités ici sont un héritage** : depuis le 2026-08-09 on n'écrit plus de
> test sur les fronts […] le gel de libellé n'y est donc plus reproduit pour un nouveau
> contrat — seul `SkillLabelsTest` continue de l'assurer côté backend.

Mais l'origine 1 (`notation-ia`) ne porte **aucune** nuance : elle affirme encore qu'un libellé
est « gelé par test des deux côtés ».

### La question à trancher

Est-ce que ces mentions décrivent des tests qui **existent encore** (auquel cas la règle
« aucun test front » a des exceptions héritées, et il faut le dire), ou est-ce du texte
**périmé** à réécrire en « miroir vérifié à la lecture » ? Vérification possible :
`ls web_sejoufr/lib/*.test.ts mobile_sejourfr/test/*_test.dart`.

---

## #3 — Coût du Plan : 20 requêtes, +1, ou 19 ? ⛔ NON TRANCHÉE

Trois chiffres pour le **même** compteur, tous dans la section *Plan adaptatif*, tous présentés
comme « verrouillé par un test qui compte les statements ».

### Formulation A (2026-08-21)

Origine : `CLAUDE.md` racine **l. 1566-1568**. Aujourd'hui : `docs/regles/plan.md`.

> **Coût** : le Plan complet fait **20 requêtes, constantes** avec 2 ou 20 compétences
> observées — verrouillé par deux tests qui comptent les statements. La passe séance +
> changements a ajouté **zéro** requête ; la passe « à acquérir » en a ajouté **une** (le
> référentiel du palier, chargé en un lot — cf. la section suivante).

### Formulation B (2026-08-21, section « Trois catégories »)

Origine : `CLAUDE.md` racine **l. 1671-1678**. Aujourd'hui : `docs/regles/plan.md`.

> **Coût : +1 requête, constante.** Le référentiel du palier se charge en **un lot**.
> 🛑 **Cette requête est INCONDITIONNELLE dès qu'un palier se construit** […]

### Formulation C (2026-08-22, section « Mon diagnostic se lit par épreuve »)

Origine : `CLAUDE.md` racine **l. 1783-1789**. Aujourd'hui : `docs/regles/plan.md`.

> **Coût inchangé : 19 requêtes avant, 19 après.** Le `GROUP BY` `countActiveByTaskCode` est
> **remplacé** par un lot `findActiveExpression()` (48 lignes) […] Les deux tests de coût
> gardent leur **égalité**.

### La question à trancher

A dit 20 **après** la passe « à acquérir » ; C dit 19 avant **et** après une passe ultérieure.
Soit A comptait déjà le +1 de B et C compte autre chose, soit l'un des trois est faux. Le
chiffre qui fait foi est celui du **test de coût** dans le backend — c'est lui qu'il faut lire
pour trancher, et ensuite ne garder qu'une seule mention dans `docs/regles/plan.md`.

---

## Comment se sert de ce fichier

- **Ne pas trancher une de ces contradictions au passage**, dans une tâche qui porte sur autre
  chose. Chacune touche une règle produit ou un invariant de coût.
- Quand une est tranchée : appliquer la décision dans le `docs/regles/*.md` concerné, retirer
  le marqueur `⚠ CONTRADICTION #n`, et **conserver l'entrée ici** en la marquant ✅ TRANCHÉE
  avec la date — comme #1. On garde la trace, on ne l'efface pas.
