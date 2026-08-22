# SejourFR — Brief Claude Code
## Dashboard Analytics Acquisition → Diagnostic → Inscription → Premium → Paiement

> **Objectif**
>
> Implémenter l’écran Analytics conçu par Claude Design afin de permettre à l’administration SejourFR de comprendre rapidement :
>
> - combien de visiteurs arrivent ;
> - d’où ils viennent ;
> - combien commencent / terminent le diagnostic ;
> - où ils abandonnent ;
> - combien s’inscrivent ;
> - combien cliquent sur Premium ;
> - combien commencent le checkout ;
> - combien paient réellement ;
> - quelles sources, campagnes, pays et plateformes convertissent le mieux ;
> - quels parcours amènent réellement au paiement.
>
> Claude Code recevra également le **HTML / prototype final Claude Design**.
>
> **Le design Claude Design est la source de vérité visuelle.**
>
> Le travail demandé ici porte sur :
>
> 1. la reprise fidèle du design ;
> 2. l’instrumentation analytics ;
> 3. la persistance des événements ;
> 4. les règles d’attribution ;
> 5. les agrégations ;
> 6. les API ;
> 7. les filtres ;
> 8. les funnels ;
> 9. les comparaisons de période ;
> 10. les tests et la fiabilité des données.

---

# 0. Règle absolue : respecter le design Claude Design

Le HTML / prototype fourni par Claude Design est la référence obligatoire.

Claude Code doit :

- reproduire la même hiérarchie ;
- conserver le même niveau premium ;
- conserver les cards, espacements, tailles, couleurs et densité ;
- conserver les graphiques prévus ;
- conserver la navigation Analytics ;
- conserver les filtres globaux ;
- conserver l’organisation desktop ;
- conserver le comportement responsive prévu ;
- ne pas remplacer le design par un dashboard Bootstrap générique ;
- ne pas improviser un autre écran sous prétexte de simplicité technique.

Le design peut être traduit dans les composants frontend existants, mais le rendu final doit rester **fidèle à Claude Design**.

---

# 1. Stack et contraintes techniques

Projet SejourFR :

- Spring Boot 4 ;
- Java 21 ;
- PostgreSQL ;
- Flyway ;
- frontend existant à auditer et réutiliser ;
- paiements / abonnements existants à auditer ;
- diagnostic existant ;
- examens / modules existants ;
- utilisateurs existants ;
- web + mobile.

Ne pas introduire un nouveau fournisseur analytics externe si ce n’est pas nécessaire.

L’objectif est d’avoir une **source de vérité interne** exploitable dans l’admin SejourFR.

Si une solution analytics existe déjà dans le repository, l’auditer avant de créer une nouvelle infrastructure.

---

# 2. Principe produit

Le dashboard doit répondre en moins de 30 secondes à :

```text
Combien de personnes arrivent ?
D’où viennent-elles ?
Que font-elles ?
Où abandonnent-elles ?
Combien s’inscrivent ?
Combien montrent une intention d’achat ?
Combien paient ?
Quelle source produit réellement du revenu ?
```

Le dashboard ne doit pas être une collection de chiffres sans contexte.

Chaque bloc doit répondre à une question business.

---

# 3. Périmètre MVP

Le MVP Analytics couvre principalement :

```text
Acquisition
→ Landing
→ Diagnostic
→ Inscription
→ Rapport
→ CTA Premium
→ Checkout
→ Paiement
```

Préparer l’architecture pour accueillir plus tard :

```text
Rétention
Usage produit
Renouvellements
Churn
D1 / D7 / D30
Examens blancs
Plan adaptatif
Engagement premium
```

mais ne pas surcharger la première version.

---

# 4. Audit obligatoire avant implémentation

Claude Code doit commencer par inspecter l’existant.

## Backend

Chercher :

- User / Account ;
- tables d’inscription ;
- date de création des comptes ;
- diagnostic ;
- submissions EE / EO ;
- CO / CE ;
- Attempt ;
- paiements ;
- abonnements ;
- checkout ;
- webhooks paiement ;
- éventuelle table analytics / events ;
- éventuelles UTM déjà persistées ;
- referrer ;
- sessions ;
- device / platform ;
- country ;
- source d’acquisition ;
- landing `/reussir` ;
- pricing ;
- paywall diagnostic ;
- Plan verrouillé ;
- événements frontend existants.

## Frontend

Chercher :

- routes admin ;
- composants graphiques ;
- librairie chart existante ;
- filtres date ;
- composants table ;
- système responsive ;
- analytics existant ;
- tracking existant ;
- landing `/reussir` ;
- diagnostic ;
- rapport ;
- paywalls ;
- checkout.

## Livrable audit

Avant les changements structurants, produire :

```text
1. Ce qui existe déjà
2. Ce qui peut être réutilisé
3. Ce qui manque
4. Les migrations nécessaires
5. Les événements déjà traçables
6. Les trous de données historiques
7. Mapping du design Claude Design vers les composants existants
8. Plan d’implémentation
```

---

# 5. Principe central : événements + entités métier

Ne pas essayer de reconstruire tout le funnel uniquement à partir des tables métier.

Il faut distinguer :

## A. Événements comportementaux

Exemples :

```text
landing_viewed
diagnostic_cta_clicked
diagnostic_started
diagnostic_report_viewed
premium_cta_clicked
checkout_viewed
```

## B. Événements métier autoritatifs

Exemples :

```text
user_registered
diagnostic_completed
subscription_created
payment_succeeded
payment_failed
```

Les clics peuvent venir du frontend.

Les paiements réussis doivent provenir du backend / webhook paiement, jamais d’un simple événement frontend.

---

# 6. Table analytics_event

Si aucune structure équivalente fiable n’existe, créer une table dédiée.

Exemple conceptuel :

```sql
analytics_event
---------------
id
event_name
occurred_at

anonymous_id nullable
session_id nullable
user_id nullable

source nullable
medium nullable
campaign nullable
content nullable
term nullable

referrer nullable
landing_path nullable
current_path nullable

platform nullable
device_type nullable
app_platform nullable

country_code nullable

properties jsonb

deduplication_key nullable
created_at
```

Adapter aux conventions du repository.

---

# 7. anonymous_id : indispensable

Un visiteur venant de TikTok peut :

```text
ouvrir /reussir
→ commencer le diagnostic
→ faire EE
→ faire EO
→ voir son rapport
→ créer son compte
→ payer
```

Une partie du parcours se déroule avant qu’un `user_id` existe.

Il faut donc un identifiant anonyme stable :

```text
anonymous_id
```

sur Web.

Il doit survivre au parcours avant inscription.

Après inscription :

```text
anonymous_id
→ lié au user_id
```

afin de reconstituer le parcours complet.

Ne pas perdre les événements pré-inscription.

---

# 8. Session

Prévoir également :

```text
session_id
```

pour distinguer plusieurs visites.

Une définition simple et cohérente peut être utilisée, par exemple nouvelle session après une longue période d’inactivité.

Ne pas dépendre du `session_id` pour l’attribution utilisateur globale.

---

# 9. Fusion anonyme → utilisateur

Lors de l’inscription / connexion :

1. récupérer `anonymous_id` courant ;
2. associer les événements anonymes récents au `user_id` ou conserver le lien de résolution ;
3. ne pas dupliquer les événements ;
4. conserver l’historique source / UTM original.

Éviter une mise à jour lourde de millions de lignes si une table de liaison est plus propre.

Exemple conceptuel :

```text
analytics_identity
anonymous_id
user_id
linked_at
```

À choisir selon l’architecture.

---

# 10. Attribution acquisition : First Touch ET Last Touch

Pour chaque utilisateur / visiteur, conserver deux lectures.

## First Touch

Première source connue ayant amené la personne.

Exemple :

```text
TikTok
```

C’est la métrique principale pour répondre :

> D’où viennent mes utilisateurs ?

## Last Touch

Dernière source / campagne connue avant une conversion.

Exemple :

```text
Google
```

C’est utile pour répondre :

> Quelle source a précédé immédiatement l’achat ?

Le dashboard doit par défaut utiliser **First Touch** pour les tableaux d’acquisition.

---

# 11. Détermination de la source

Priorité recommandée :

```text
1. utm_source explicite
2. referrer connu
3. app campaign / deep link si disponible
4. direct
5. unknown
```

Normaliser les valeurs :

```text
tiktok
instagram
facebook
google
youtube
direct
other
unknown
```

Ne pas laisser plusieurs variantes représenter la même source.

---

# 12. UTM à conserver

Persister :

```text
utm_source
utm_medium
utm_campaign
utm_content
utm_term
```

Le cas le plus important :

```text
TikTok
→ vidéo A
→ landing
→ diagnostic
→ paiement
```

doit être reconstituable.

`utm_content` peut notamment distinguer les vidéos / créas.

---

# 13. Capture de l’attribution sur `/reussir`

Dès la première visite :

1. lire UTM ;
2. lire referrer ;
3. normaliser source ;
4. enregistrer `landing_viewed` ;
5. persister first touch si absent ;
6. mettre à jour last touch si pertinent ;
7. ne pas écraser first touch à chaque page.

---

# 14. Événements minimum — Acquisition / Landing

Prévoir :

```text
landing_viewed
diagnostic_cta_clicked
pricing_cta_clicked
login_clicked
signup_cta_clicked
```

`diagnostic_cta_clicked` doit pouvoir contenir :

```json
{
  "cta_location": "hero|middle|sticky|footer",
  "landing_variant": "...",
  "diagnostic_type": "rapid|complete|unknown"
}
```

---

# 15. Événements minimum — Diagnostic

Prévoir :

```text
diagnostic_started

diagnostic_ee_started
diagnostic_ee_completed

diagnostic_eo_started
diagnostic_eo_completed

diagnostic_co_started
diagnostic_co_completed

diagnostic_ce_started
diagnostic_ce_completed

diagnostic_completed
diagnostic_report_viewed
```

Ajouter :

```text
diagnostic_type = RAPID | COMPLETE | PROGRESSIVE
```

---

# 16. Diagnostic rapide

Considéré terminé lorsque :

```text
EE terminée
AND
EO terminée
```

selon les règles produit réelles.

Ne pas considérer une production vide / non évaluable comme une réussite silencieuse.

Prévoir un statut exploitable :

```text
completed
skipped
not_evaluable
abandoned
```

si le domaine existant le permet.

---

# 17. Diagnostic complet

Terminé lorsque les quatre domaines attendus sont terminés :

```text
EE
EO
CO
CE
```

Ne pas confondre :

```text
diagnostic_started
```

avec :

```text
diagnostic_completed
```

---

# 18. Événements inscription

Prévoir :

```text
signup_started
user_registered
login_succeeded
```

`user_registered` doit être autoritatif côté backend.

Propriété utile :

```text
registration_context
```

Valeurs possibles :

```text
landing
before_diagnostic
during_diagnostic
after_diagnostic
diagnostic_report
pricing
mobile_app
other
```

---

# 19. Premium / intention d’achat

Prévoir :

```text
premium_cta_clicked
pricing_viewed
checkout_started
```

`premium_cta_clicked` doit contenir :

```json
{
  "cta_location": "diagnostic_report|locked_plan|pricing|ai_correction|mock_exam|other",
  "offer_id": "...",
  "screen": "..."
}
```

---

# 20. Paiement : source autoritative

Prévoir des événements backend :

```text
payment_succeeded
payment_failed
subscription_created
subscription_cancelled
```

Pour cette première page, le principal événement est :

```text
payment_succeeded
```

Il doit provenir :

- du backend ;
- du provider paiement ;
- idéalement du webhook confirmé.

Jamais du simple retour frontend « success ».

---

# 21. Dédoublonnage paiement

Utiliser une clé stable :

```text
payment_provider_event_id
payment_id
invoice_id
```

ou équivalent.

Un webhook retry ne doit pas produire plusieurs paiements.

---

# 22. Montants

Pour chaque paiement réussi stocker / rendre exploitable :

```text
amount
currency
product / plan
subscription_id
```

Le dashboard doit calculer le revenu de la période.

---

# 23. Timezone

L’administration SejourFR utilise par défaut :

```text
Europe/Paris
```

Les timestamps en base restent selon les conventions existantes, idéalement UTC.

Les regroupements affichés doivent être calculés proprement dans le fuseau du dashboard.

---

# 24. Filtre de période global

Supporter :

```text
Aujourd’hui
7 jours
30 jours
90 jours
Personnalisé
```

Le backend reçoit conceptuellement :

```text
from
to
timezone
```

---

# 25. Comparaison avec période précédente

Pour une période :

```text
[from, to]
```

calculer une période précédente de même durée.

Retourner :

```text
currentValue
previousValue
deltaAbsolute
deltaPercent
```

Attention à la division par zéro.

---

# 26. KPI principaux

Prévoir :

```text
Visiteurs
Nouvelles inscriptions
Diagnostics commencés
Diagnostics terminés
Clics Premium
Nouveaux abonnés payants
Revenu
Utilisateurs inscrits au total
```

Les KPI de période doivent être distincts du total historique.

---

# 27. KPI — Visiteurs

Définition recommandée :

```text
nombre de visiteurs uniques
```

sur la période, à partir de l’identité anonyme / utilisateur.

Ne pas utiliser uniquement le nombre de pageviews.

---

# 28. KPI — Nouveaux inscrits

```text
count(users created_at in selected period)
```

ou événement autoritatif `user_registered`.

---

# 29. KPI — Utilisateurs inscrits au total

Ce chiffre est « à date », pas limité au filtre de période.

---

# 30. KPI — Diagnostics commencés

Nombre de diagnostics distincts ayant reçu :

```text
diagnostic_started
```

sur la période.

Idéalement utiliser un `diagnostic_id`.

---

# 31. KPI — Diagnostics terminés

Nombre de diagnostics ayant atteint :

```text
diagnostic_completed
```

Prévoir la ventilation :

```text
rapid
complete
```

---

# 32. KPI — Clics Premium

Sur les KPI principaux, privilégier :

```text
utilisateurs uniques ayant cliqué
```

Dans le détail, permettre aussi le volume brut de clics.

---

# 33. KPI — Nouveaux abonnés payants

Définition :

```text
utilisateurs distincts dont le premier paiement d’abonnement réussi se situe dans la période
```

Ne pas compter un renouvellement comme nouvel abonné.

---

# 34. KPI — Revenu

Somme des paiements réussis pertinents sur la période.

Nommer clairement :

```text
revenu brut
```

ou autre métrique réellement disponible.

---

# 35. Taux principaux

Prévoir les ratios :

```text
Visitor → Signup
Diagnostic Started → Completed
Diagnostic Completed → Premium Click
Premium Click → Checkout
Checkout → Payment
Signup → Payment
Visitor → Payment
```

Les définitions doivent rester cohérentes partout.

---

# 36. Funnel principal

Calculer à partir d’acteurs distincts :

```text
Landing visitors
↓
Diagnostic CTA clicked
↓
Diagnostic started
↓
Diagnostic completed
↓
Report viewed
↓
Premium CTA clicked
↓
Checkout started
↓
Payment succeeded
```

L’inscription peut intervenir à plusieurs moments.

Ne pas imposer artificiellement une séquence unique.

---

# 37. Funnel diagnostic détaillé

Prévoir :

```text
Diagnostic CTA
→ Diagnostic started
→ EE started
→ EE completed
→ EO started
→ EO completed
→ CO started
→ CO completed
→ CE started
→ CE completed
→ Report viewed
→ Premium clicked
→ Payment
```

Pour le diagnostic rapide, CO/CE ne sont pas attendus.

---

# 38. Diagnostic rapide vs complet

Retourner séparément :

```text
rapid.started
rapid.completed
rapid.completionRate
rapid.premiumClicks
rapid.checkouts
rapid.payers
rapid.paymentConversion
```

et :

```text
complete.started
complete.completed
complete.completionRate
complete.premiumClicks
complete.checkouts
complete.payers
complete.paymentConversion
```

---

# 39. Abandons diagnostic

Le backend doit calculer les pertes entre étapes.

Format conceptuel :

```json
[
  {
    "step": "DURING_EE",
    "entered": 100,
    "continued": 80,
    "dropoff": 20,
    "dropoffRate": 0.20
  }
]
```

---

# 40. Acquisition par source

Pour chaque source :

```text
visitors
registeredUsers
diagnosticStarted
diagnosticCompleted
premiumClickers
checkoutStarters
newPayers
revenue
```

et les taux :

```text
visitorToSignup
visitorToDiagnostic
diagnosticToPremiumClick
signupToPayment
visitorToPayment
```

---

# 41. Table Acquisition

Le design peut afficher :

```text
Source
Visiteurs
Inscrits
Diagnostic terminé
Payants
Conversion payante
Revenu
```

Le backend doit permettre le tri.

---

# 42. Filtre par source

Quand on choisit :

```text
TikTok
```

tous les principaux blocs doivent être recalculés avec :

```text
source=tiktok
```

Même principe pour Instagram, Facebook, Google, Direct, etc.

---

# 43. Campagnes / UTM

Créer une vue agrégée par :

```text
source
campaign
content
```

Métriques identiques à Acquisition.

---

# 44. Parcours principaux

Calculer des chemins simplifiés.

Exemples :

```text
TikTok → Landing → Diagnostic rapide → Inscription
Google → Landing → Diagnostic complet → Inscription
TikTok → Landing → Diagnostic → Rapport → Premium → Paiement
```

Ne pas rendre chaque pageview.

---

# 45. Milestones de parcours

Taxonomie possible :

```text
SOURCE
LANDING
SIGNUP
DIAGNOSTIC_RAPID
DIAGNOSTIC_COMPLETE
REPORT
PREMIUM_CLICK
CHECKOUT
PAYMENT
```

Réduire le bruit et les clics répétés.

---

# 46. Top journeys

Retourner les 5 ou 10 parcours les plus fréquents avec :

```text
count
share
payments
paymentRate
```

---

# 47. Inscription par contexte

Mesurer :

```text
before_diagnostic
during_diagnostic
after_diagnostic
diagnostic_report
landing
mobile_app
other
```

Afficher :

```text
count
percentage
```

---

# 48. CTA Premium par emplacement

Agrégation :

```text
diagnostic_report
locked_plan
pricing
ai_correction
mock_exam
other
```

Pour chacun :

```text
uniqueClickers
clicks
checkouts
payers
conversionClickToPayment
revenue
```

---

# 49. Attribution paiement au CTA

Pour la table CTA :

```text
dernier premium_cta_clicked avant checkout / payment
```

dans une fenêtre raisonnable.

Ne pas utiliser cette logique pour remplacer l’attribution acquisition first-touch.

---

# 50. Courbe temporelle

Supporter :

```text
visitors
registrations
diagnosticsStarted
diagnosticsCompleted
premiumClickers
payers
revenue
```

---

# 51. Bucketing temporel

Automatique :

```text
Aujourd’hui / très courte période → heure
7–45 jours → jour
longue période → semaine
```

---

# 52. Annotations produit / marketing

Préparer une structure simple pour afficher sur les courbes :

```text
Lien TikTok ajouté
Nouvelle landing
Nouveau paywall diagnostic
Nouveau prix
Nouvelle version app
```

Table conceptuelle :

```text
analytics_annotation
id
occurred_at
title
description nullable
category
created_by
```

---

# 53. Audience par pays

N’utiliser un pays que si la donnée est déjà disponible de manière fiable et légitime.

Ne pas ajouter une collecte intrusive uniquement pour remplir le dashboard.

Prévoir :

```text
UNKNOWN
```

---

# 54. Pays — métriques

Par pays :

```text
visitors
registrations
diagnosticCompleted
payers
revenue
visitorToPayment
signupToPayment
```

---

# 55. Device / plateforme

Normaliser :

```text
mobile_web
desktop_web
ios
android
tablet_web
unknown
```

Afficher :

```text
visitors
diagnosticCompletionRate
registrationRate
paymentRate
```

---

# 56. Insights automatiques

Créer un service déterministe, sans LLM.

Exemples :

```text
TikTok apporte 61 % des nouveaux inscrits mais 20 % des nouveaux payants.
```

```text
Le principal abandon du diagnostic se produit entre EE et EO.
```

```text
Google convertit 3,4× mieux en paiement que TikTok.
```

Afficher maximum 3 à 4 insights.

Ne pas générer d’insight sur de trop petits volumes.

---

# 57. API — vue d’ensemble

Endpoint conceptuel :

```text
GET /admin/analytics/overview
```

Paramètres :

```text
from
to
timezone
source optional
country optional
platform optional
campaign optional
```

Retour :

```text
period
comparisonPeriod
kpis
mainFunnel
insights
timeseriesPreview
```

---

# 58. API — acquisition

```text
GET /admin/analytics/acquisition
```

Retour :

```text
sources
campaigns
countries
platforms
topJourneys
```

---

# 59. API — diagnostic

```text
GET /admin/analytics/diagnostic
```

Retour :

```text
rapid
complete
stepFunnel
dropoffs
premiumConversion
```

---

# 60. API — conversion

```text
GET /admin/analytics/conversion
```

Retour :

```text
premiumFunnel
ctaLocations
checkout
payments
revenue
```

---

# 61. API — timeseries

```text
GET /admin/analytics/timeseries
```

Paramètres :

```text
metric
from
to
granularity optional
filters
```

---

# 62. API — journeys

```text
GET /admin/analytics/journeys
```

Retour top parcours.

---

# 63. Autorisation

Tous les endpoints Analytics sont réservés aux comptes admin autorisés.

Réutiliser le système de rôles existant.

Ne jamais exposer publiquement les données admin.

---

# 64. Dashboard agrégé

Ne pas afficher dans la vue principale :

- nom ;
- email ;
- adresse ;
- données personnelles inutiles.

Cette page sert à l’analyse agrégée.

---

# 65. Index PostgreSQL

Créer les index réellement utiles, par exemple :

```text
(event_name, occurred_at)
(occurred_at)
(user_id, occurred_at)
(anonymous_id, occurred_at)
(source, occurred_at)
```

Ne pas sur-indexer sans mesure.

---

# 66. Performance

Ne pas faire 40 requêtes coûteuses à chaque ouverture.

Faire les agrégations principalement en PostgreSQL.

Ne pas charger tous les événements en Java pour les grouper en mémoire.

Utiliser au besoin :

- requêtes agrégées ;
- CTE ;
- vues ;
- cache court.

---

# 67. Cache

Un cache de :

```text
30–120 secondes
```

est acceptable pour les vues agrégées si nécessaire.

---

# 68. Event ingestion

Si nécessaire :

```text
POST /analytics/events
```

Contraintes :

- whitelist d’events ;
- payload limité ;
- validation ;
- pas de données sensibles ;
- protection anti-abus.

---

# 69. Whitelist d’événements

Créer un enum / registry.

Exemple :

```text
LANDING_VIEWED
DIAGNOSTIC_CTA_CLICKED
DIAGNOSTIC_STARTED
...
```

Ne pas accepter des noms arbitraires.

---

# 70. Validation properties

Chaque event doit avoir des propriétés autorisées et typées.

Ne pas stocker des objets frontend libres sans contrôle.

---

# 71. Idempotence

Pour les événements serveur, utiliser :

```text
deduplication_key
```

si nécessaire.

Exemple :

```text
payment_succeeded:<paymentId>
```

---

# 72. Données historiques

Le nouveau tracking ne permettra pas forcément de reconstruire le passé.

Backfill autorisé uniquement pour :

- users.created_at ;
- diagnostics existants ;
- paiements ;
- abonnements ;

si les données sont fiables.

Ne pas fabriquer :

```text
landing_viewed
utm_source
TikTok
```

historiques si ces informations n’existent pas.

---

# 73. Frontend — structure principale

Respecter Claude Design.

Conceptuellement :

```text
Analytics
→ période / filtres
→ KPIs
→ Funnel
→ Insights
→ Évolution
→ Acquisition
→ Diagnostic
→ Conversion Premium
→ Audience
→ Parcours
```

---

# 74. KPI Cards

Chaque card peut contenir :

```text
label
value
delta
secondary metric
```

Exemple :

```text
Nouvelles inscriptions
286
↑ 18 %
5,9 % des visiteurs
```

---

# 75. Couleurs des deltas

Une hausse n’est pas toujours positive.

Prévoir :

```text
positive
negative
neutral
```

Exemple :

```text
abandon +20 %
```

= négatif.

---

# 76. Funnel visuel

Le frontend reçoit :

```text
label
count
conversionFromPrevious
dropoff
```

Le design met en évidence la fuite majeure.

---

# 77. Table Acquisition interactive

Fonctions :

- tri ;
- clic source ;
- filtre global appliqué ;
- pagination si nécessaire.

---

# 78. Diagnostic section

Afficher clairement :

```text
Rapide
Complet
```

avec :

```text
started
completed
completion rate
premium click
payment
```

---

# 79. CTA conversion table

Afficher :

```text
CTA
Unique clickers
Checkout
Payers
Conversion
Revenue
```

Labels métier français :

```text
Rapport diagnostic
Plan verrouillé
Page tarifs
Correction IA
Examen blanc
```

---

# 80. Courbe principale

Permettre le choix :

```text
Visiteurs
Inscriptions
Diagnostics
Clics Premium
Payants
Revenu
```

Éviter un graphique illisible avec trop de lignes.

---

# 81. Responsive

Priorité desktop pour l’admin.

Mais mobile :

- KPI lisibles ;
- funnel lisible ;
- tables adaptées ;
- filtres accessibles ;
- graphes utilisables.

Suivre le responsive Claude Design.

---

# 82. Empty state

Si peu de données :

```text
Pas encore assez de données sur cette période.
```

Ne pas afficher de graphes cassés.

---

# 83. Unknown source

Ne jamais cacher :

```text
unknown
```

Un volume important de `unknown` est lui-même un problème de tracking.

---

# 84. Direct ≠ Unknown

```text
direct
```

= visite sans source connue mais cohérente.

```text
unknown
```

= attribution non déterminée / donnée manquante.

---

# 85. Exclure les données de test

Ne pas mélanger :

```text
production
staging
development
```

Éviter que comptes admin / tests internes polluent la production si possible.

---

# 86. Tests attribution

Tester :

```text
?utm_source=tiktok
→ tiktok
```

```text
referrer instagram
→ instagram
```

```text
aucun UTM + aucun referrer
→ direct
```

```text
UTM TikTok puis retour direct
→ firstTouch TikTok
```

---

# 87. Tests identité

Tester :

```text
anonymous
→ diagnostic
→ signup
→ user
→ payment
```

Le dashboard doit reconstituer un seul parcours.

---

# 88. Tests paiement

Webhook reçu deux fois :

```text
1 paiement seulement
```

---

# 89. Tests diagnostic rapide

```text
started
EE completed
EO completed
report viewed
```

→ diagnostic rapide completed.

---

# 90. Tests diagnostic complet

Sans CE :

```text
pas completed
```

si le parcours déclaré est complet.

---

# 91. Tests funnel

Fixture :

```text
100 visitors
80 CTA
60 started
40 completed
20 premium
10 checkout
2 payers
```

Les taux doivent être exacts.

---

# 92. Tests source

Exemple :

```text
TikTok 100 visitors / 2 payers
Google 20 visitors / 2 payers
```

Le dashboard doit rendre immédiatement visible :

```text
TikTok = volume
Google = meilleure conversion
```

---

# 93. Tests période

Tester :

- bornes ;
- timezone Europe/Paris ;
- comparaison précédente ;
- changement d’heure ;
- buckets.

---

# 94. Tests CTA

Un utilisateur clique 5 fois puis paie.

Doit permettre :

```text
clicks = 5
uniqueClickers = 1
payers = 1
```

---

# 95. Sécurité analytics

Ne jamais stocker dans `analytics_event.properties` :

- mot de passe ;
- contenu EE complet ;
- transcription EO complète ;
- coordonnées bancaires ;
- token ;
- données sensibles inutiles.

Les analytics doivent stocker des métadonnées.

---

# 96. Exemple landing

```json
{
  "eventName": "LANDING_VIEWED",
  "anonymousId": "...",
  "sessionId": "...",
  "occurredAt": "...",
  "properties": {
    "landingPath": "/reussir"
  }
}
```

---

# 97. Exemple premium click

```json
{
  "eventName": "PREMIUM_CTA_CLICKED",
  "properties": {
    "ctaLocation": "DIAGNOSTIC_REPORT",
    "offerId": "monthly",
    "screen": "diagnostic_result"
  }
}
```

---

# 98. Exemple paiement serveur

```json
{
  "eventName": "PAYMENT_SUCCEEDED",
  "userId": "...",
  "properties": {
    "paymentId": "...",
    "subscriptionId": "...",
    "plan": "monthly",
    "amountMinor": 1499,
    "currency": "EUR"
  }
}
```

---

# 99. Performance SQL

Toujours filtrer la période le plus tôt possible.

Faire les agrégations en base.

Si le volume devient important plus tard, préparer éventuellement des agrégats journaliers.

---

# 100. Analytics events recommandés

Liste minimale consolidée :

```text
LANDING_VIEWED
DIAGNOSTIC_CTA_CLICKED

DIAGNOSTIC_STARTED
DIAGNOSTIC_EE_STARTED
DIAGNOSTIC_EE_COMPLETED
DIAGNOSTIC_EO_STARTED
DIAGNOSTIC_EO_COMPLETED
DIAGNOSTIC_CO_STARTED
DIAGNOSTIC_CO_COMPLETED
DIAGNOSTIC_CE_STARTED
DIAGNOSTIC_CE_COMPLETED
DIAGNOSTIC_COMPLETED
DIAGNOSTIC_REPORT_VIEWED

SIGNUP_STARTED
USER_REGISTERED
LOGIN_SUCCEEDED

PREMIUM_CTA_CLICKED
PRICING_VIEWED
CHECKOUT_STARTED

PAYMENT_SUCCEEDED
PAYMENT_FAILED
SUBSCRIPTION_CREATED
SUBSCRIPTION_CANCELLED
```

---

# 101. Event properties importantes

Standardiser autant que possible :

```text
source
medium
campaign
content
term

screen
path
cta_location

diagnostic_id
diagnostic_type

offer_id
plan_id

platform
device_type
country_code
```

---

# 102. Analytics dimensions principales

Le backend doit pouvoir croiser :

```text
date
source
campaign
content
country
platform
diagnostic_type
cta_location
```

avec les principales métriques.

---

# 103. Priorités d’implémentation

## Phase 1
Audit.

## Phase 2
Modèle events + identité anonyme + attribution.

## Phase 3
Tracking `/reussir`.

## Phase 4
Tracking diagnostic.

## Phase 5
Tracking inscription.

## Phase 6
Tracking Premium / checkout.

## Phase 7
Paiement serveur autoritatif.

## Phase 8
Agrégations.

## Phase 9
API admin.

## Phase 10
Reproduction fidèle du HTML Claude Design.

## Phase 11
Filtres / campagnes / parcours.

## Phase 12
Tests.

---

# 104. Critère d’acceptation — TikTok complet

URL :

```text
/reussir?utm_source=tiktok&utm_campaign=b2&utm_content=video_14
```

Utilisateur :

```text
visite
→ clique diagnostic
→ diagnostic rapide
→ EE
→ EO
→ rapport
→ inscription
→ Premium
→ checkout
→ paiement
```

Le dashboard doit pouvoir montrer :

```text
Source = TikTok
Campaign = b2
Content = video_14
Diagnostic = rapid
Registered = yes
Premium click = diagnostic report
Paid = yes
Revenue = montant réel
```

sans perdre les événements pré-inscription.

---

# 105. Critère d’acceptation — abandon EO

```text
TikTok
→ diagnostic
→ EE completed
→ EO started
→ quitte
```

Le dashboard doit montrer la perte entre :

```text
EO started
→ EO completed
```

---

# 106. Critère d’acceptation — diagnostic complet

```text
Instagram
→ diagnostic complet
→ EE
→ EO
→ CO
→ CE
→ report
```

Il doit être compté dans :

```text
Diagnostic complet
```

et non comme `rapid completed`.

---

# 107. Critère d’acceptation — multi-session

Jour 1 :

```text
TikTok
→ diagnostic
→ inscription
```

Jour 3 :

```text
Direct
→ login
→ Premium
→ paiement
```

First touch :

```text
TikTok
```

Last touch :

```text
Direct
```

Acquisition principale :

```text
TikTok
```

---

# 108. Critère d’acceptation — ancien utilisateur sans attribution

Ne pas inventer une source.

Afficher :

```text
unknown
```

si nécessaire.

---

# 109. Ce qu’il ne faut pas faire

Claude Code ne doit pas :

- refaire le design ;
- hardcoder les chiffres de Claude Design ;
- compter les pageviews comme visiteurs ;
- compter les clics bruts comme utilisateurs uniques ;
- utiliser le frontend comme source de vérité du paiement ;
- perdre les événements anonymes après inscription ;
- écraser first touch à chaque visite ;
- inventer des sources historiques ;
- utiliser un LLM pour calculer les stats ;
- agréger des millions d’events en Java ;
- exposer les endpoints sans rôle admin ;
- stocker les réponses EE/EO dans analytics ;
- confondre direct et unknown ;
- compter un renouvellement comme nouvel abonné ;
- considérer un diagnostic started comme completed ;
- imposer signup avant diagnostic ;
- afficher des insights sur des volumes ridicules ;
- dupliquer les systèmes métier existants.

---

# 110. Definition of Done

## UI

- rendu fidèle à Claude Design ;
- filtres fonctionnels ;
- graphiques avec vraies données ;
- funnel fonctionnel ;
- tables interactives ;
- responsive propre.

## Tracking

- acquisition ;
- UTM ;
- anonymous identity ;
- signup ;
- diagnostic ;
- Premium ;
- checkout ;
- paiement serveur.

## Analytics

- KPIs période ;
- comparaison précédente ;
- funnel principal ;
- rapide vs complet ;
- abandons ;
- acquisition source ;
- campagnes ;
- pays si disponibles ;
- plateforme ;
- CTA Premium ;
- paiements ;
- revenus ;
- parcours ;
- insights.

## Qualité

- tests backend ;
- tests frontend ;
- paiements dédupliqués ;
- données historiques non inventées ;
- performances correctes ;
- permissions admin ;
- erreurs propres.

---

# 111. Résultat produit attendu

Je veux pouvoir ouvrir cette page et comprendre immédiatement :

> Cette semaine, TikTok a généré 3 200 visiteurs et 210 inscriptions. 138 personnes ont terminé leur diagnostic. 29 ont cliqué sur Premium et 3 ont payé. La plus grosse perte intervient après le rapport diagnostic. Google apporte moins de trafic, mais ses visiteurs convertissent nettement mieux en abonnés.

Puis cliquer sur :

```text
TikTok
```

et voir :

```text
TikTok
→ Landing
→ Diagnostic
→ Inscription
→ Premium
→ Paiement
```

Puis ouvrir Diagnostic et voir :

```text
EE
→ EO
→ Rapport
```

avec les abandons.

Puis ouvrir Conversion et voir si le problème se situe entre :

```text
Rapport
→ CTA
→ Checkout
→ Paiement
```

---

# 112. Principe final

Le dashboard n’est pas conçu pour répondre :

> Combien d’événements avons-nous enregistré ?

Il doit répondre :

> **Pourquoi mes visiteurs ne deviennent-ils pas abonnés, et quel levier dois-je améliorer en priorité ?**

Toute décision technique et UI doit servir cette question.
