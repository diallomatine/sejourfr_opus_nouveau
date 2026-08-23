# Journal — mesure d'audience et analytics

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Journal daté, verbatim et intégral.**
> Origine : lignes 277-346 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier consigne les arbitrages et révocations : on l'ouvre **avant de changer une règle**, pas pour l'appliquer.
> Fichier jumeau : `docs/regles/mesure-audience.md`
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

> ⚠ **SUSPECTÉ PÉRIMÉ — non vérifié au 2026-08-23, ne pas appliquer sans confirmation.**
> Suspicion #4 — motif et liste complète : `docs/decisions/suspects-perimes.md`.

## Mesure d'audience des landings (sans traceur)

Compteur **maison**, sans service tiers, pour savoir combien de visiteurs
consultent une page de campagne (`/reussir`, le lien de bio réseaux) et combien
cliquent son CTA, découpé par réseau de provenance.

- **Table `page_views` (V020)** : agrégat, pas journal — une ligne par
  (page, source, événement, jour), incrémentée par `INSERT … ON CONFLICT DO
  UPDATE` (atomique). La table est donc **bornée** par construction, à
  l'inverse du problème des attempts invités signalé plus haut.
- ⚠️ **RÈGLE RÉVOQUÉE le 2026-08-21 — lire la section *Analytics* plus bas.**
  Ce système ne déposait rien sur le terminal du visiteur (ni cookie, ni
  localStorage, ni sessionStorage) et ne comptait donc que des **vues**, jamais
  des visiteurs uniques. Le chantier Analytics **dépose désormais un identifiant
  de mesure d'audience first-party**, sous l'**exemption CNIL** (jamais partagé,
  jamais cross-site, rétention 13 mois, aucun recoupement externe) — donc
  **toujours aucun bandeau de consentement**, et `/confidentialite` a été
  réécrite dans la même passe. Ne pas réintroduire l'ancienne formule au motif
  qu'elle traîne encore quelque part. **Reste vrai et doit le rester** : aucun
  outil tiers, aucun partage, aucun suivi entre sites, aucune CMP.
- 🛑 **Ce système est LEGACY depuis le 2026-08-21.** `page_views`,
  `PageViewService`, `PublicPageViewController`, `AdminPageViewController`,
  `PageViewEvent` et `PageViewStatsResponse` sont **supprimés** ; la **table
  reste en base**, plus jamais écrite, plus mappée — c'est de la donnée réelle
  (~700 hits), même doctrine que `cout_estime_centimes`. Aucune migration
  destructive, aucun recalcul. Ce qui suit décrit l'état d'avant, conservé pour
  relire l'historique.
- **Deux allowlists** dans `PageViewService` : `EVENTS_BY_PATH` borne à la fois
  les chemins et les événements admis sur chaque écran, `KNOWN_SOURCES` borne
  les provenances (tout le reste devient `autre`). L'endpoint d'écriture étant
  public, elles empêchent un tiers de créer des dimensions à volonté. Les pages
  suivies sont `/reussir`, `/diagnostic` et `/plan`.
- **Web** : `lib/audience.ts` garde la détection de provenance ;
  `lib/audience-events.ts` envoie les événements typés. Le funnel diagnostic
  ajoute dix événements : vue/démarrage, fin EE, fin EO, fin d'analyse, vue du
  résultat, ouverture du Plan, lancement de l'exercice recommandé, clic landing
  sociale vers le diagnostic et clic diagnostic/Plan vers Premium.
- **Admin** : `features/audience/` — vues, clics, taux de clic par réseau,
  série journalière et compte brut de chaque événement du funnel, sur 7 / 30 /
  90 jours. `PageViewStatsResponse.events` est un `Map<String, Long>` ; ne pas
  reconstruire le funnel depuis les deux anciens totaux `views`/`ctaClicks`.
- Reste à faire avant l'ouverture publique : un **rate-limit par IP** sur
  `POST /api/public/page-views`, même chantier que la démo invitée. Sans lui, un
  bot peut gonfler un compteur — donnée fausse, mais ni fuite ni inflation de
  stockage.
- **Chemins suivis** : `/reussir`, `/diagnostic`, `/plan`, plus `/tarifs` et
  `/paiement` (`VIEW` + `CTA`, 2026-08-19) — ces deux derniers mesurent les
  visiteurs qui regardent les prix **sans jamais créer de compte**, angle mort
  jusque-là.
- **`/reussir` a DEUX portes d'entrée, comptées séparément** (2026-08-21) :
  `SOCIAL_LANDING_DIAGNOSTIC_CLICKED` (diagnostic TCF) et
  **`SOCIAL_LANDING_CIVIQUE_CLICKED`** (« Passer l'examen découverte »). Réutiliser le premier
  aurait gonflé la mesure du diagnostic avec des clics qui n'y mènent pas — le civique n'a ni
  production, ni niveau CECRL, ni diagnostic. Les deux comptent comme des **clics** dans
  l'agrégat et restent **distincts** dans `events`. Aucune migration :
  `page_views.event` est en `varchar(64)` depuis V030.
- **Fenêtre de lecture** : les deux endpoints admin acceptent `from`/`to`
  (ISO `yyyy-MM-dd`, **Europe/Paris**, bornes **incluses**) **ou** `days`
  (défaut 30, clamp 1..365). `from`/`to` l'emportent ; **une seule borne, `from
  > to`, ou plus de 365 jours ⇒ 400 nommé** — jamais un repli muet sur `days`,
  qui rendrait des chiffres qu'on croirait filtrés. Une borne future est
  ramenée à aujourd'hui (l'admin peut cliquer un jour à venir, ce n'est pas une
  faute). Autorité unique : **`util/FenetreMesure`**, partagée par les deux
  endpoints. Les réponses **rendent les bornes appliquées** (`cohortFrom`/
  `cohortTo`, et `from`/`to` ajoutés à `PageViewStatsResponse`) : l'écran
  affiche la période d'après le **serveur**, jamais d'après ce que le client
  croit avoir demandé. `daily` est **continue des deux côtés** (un point par
  jour, zéros compris) — sans ça, `from == to` sur une journée creuse rendait
  une série vide.
