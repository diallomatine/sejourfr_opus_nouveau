# Bascule des prix Intégral — ce qu'il reste à faire

Nouvelle grille **Intégral** (le catalogue **Civique ne change pas**) :

| Pass                | `Plan.code`        | Product ID store   | Prix    | Durée | Simulations orales |
|---------------------|--------------------|--------------------|---------|-------|--------------------|
| Intégral 7 jours    | `INTEGRAL_PASS_7J` | `integral_pass_7j` | 9,99 €  | 7 j   | 5                  |
| Intégral 1 mois     | `INTEGRAL_PASS_1M` | `integral_pass_1m` | 19,99 € | 30 j  | 15                 |
| Intégral 2 mois ★   | `INTEGRAL_PASS_2M` | `integral_pass_2m` | 29,99 € | 60 j  | 25                 |

★ = pass mis en avant « le plus populaire » sur le web **et** le paywall mobile.

Civique, inchangé : `civique_pass_3m` 9,99 € / 90 j · `civique_pass_1y` 29,99 € / 365 j.

Anciens passes Intégral, **désactivés en base mais conservés** :
`integral_pass_sprint` (42 j / 19,99 €), `integral_pass_3m` (90 j / 34,99 €),
`integral_pass_1y` (365 j / 79,99 €).

---

## Déjà fait dans le code (rien à refaire)

- **Migration `V114`** (`100_reference/`) : insère les 3 nouveaux passes avec leur
  prix, leur durée, leurs quotas de simulations orales **et leurs deux product IDs
  de store** ; désactive les 3 anciens (`is_active = false`, jamais supprimés).
  Elle s'applique toute seule au démarrage du backend.
- **Web** : `/paiement`, `/tarifs` et `/reussir` lisent la grille depuis
  `GET /api/billing/plans` — aucun prix n'est écrit en dur. Le badge « populaire »
  pointe sur `INTEGRAL_PASS_2M`, le libellé de durée sait dire « 7 jours », le
  comparatif et la FAQ tarifs ont été réécrits, et les CGU citent les bonnes durées.
- **Mobile** : le paywall lit les mêmes données ; le badge « populaire » et le
  libellé de durée sont alignés mot pour mot avec le web.
- **Admin** : la console Plans affiche et édite déjà prix / durée / product IDs —
  rien de spécifique à ajouter.

---

## 1. Déployer le backend, puis vérifier la base

```sql
SELECT code, price, duration_days, realtime_eo_sessions, is_active,
       apple_product_id, google_product_id
  FROM plans
 WHERE purchase_type = 'ONE_TIME'
 ORDER BY module_access, duration_days;
```

Attendu : **5 lignes actives** (2 Civique + 3 Intégral) et **3 inactives** (les
anciens Intégral). Si les product IDs sont vides sur les nouvelles lignes, le
paywall mobile ne les affichera pas : les corriger en console admin.

> Les simulations orales (5 / 15 / 25) sont **éditables à chaud** depuis l'admin
> (Plans) — c'est un plafond commercial, pas une règle figée dans le code.

---

## 2. Apple — App Store Connect

**Créer les 3 nouveaux produits** (`Mes apps → SejourFR → Monétisation → Achats
intégrés → +`) :

| Type            | ID de produit      | Prix    | Nom affiché (FR)      | Description (FR)                                      |
|-----------------|--------------------|---------|-----------------------|-------------------------------------------------------|
| **Consommable** | `integral_pass_7j` | 9,99 €  | Pass Intégral 7 jours | Accès complet Civique + TCF IRN pendant 7 jours.       |
| **Consommable** | `integral_pass_1m` | 19,99 € | Pass Intégral 1 mois  | Accès complet Civique + TCF IRN pendant 1 mois.        |
| **Consommable** | `integral_pass_2m` | 29,99 € | Pass Intégral 2 mois  | Accès complet Civique + TCF IRN pendant 2 mois.        |

⚠️ **Le type doit être « Consommable »**, jamais « Non-consommable » : un
non-consommable est possédé à vie, Apple refuse le rachat et restaure la
transaction d'origine — le backend la traite alors en doublon et **ne prolonge
rien**. La durée d'accès est posée par notre serveur, Apple n'encaisse qu'un
paiement.

⚠️ **Un ID de produit Apple supprimé n'est jamais réutilisable.** Si l'un de ces
trois IDs a déjà existé sous une autre forme, il faut en choisir un nouveau —
et le reporter dans `plans.apple_product_id` (console admin).

**Retirer les anciens de la vente, sans les supprimer** : sur
`integral_pass_sprint`, `integral_pass_3m`, `integral_pass_1y` → section
**Disponibilité** → retirer tous les pays (ou passer le produit en « Supprimé du
Store »). **Ne pas les effacer** : leurs identifiants doivent rester résolvables
pour les remboursements et les notifications des achats déjà encaissés.

Ensuite :
1. Chaque produit doit atteindre l'état **« Prêt à soumettre »** (nom, description,
   capture de la sheet d'achat si Apple la demande).
2. Les soumettre à la revue — comptez **24 à 48 h**. Tant qu'ils ne sont pas
   approuvés, ils n'apparaissent **qu'en sandbox**.
3. Tester l'achat en **sandbox** (Utilisateurs et accès → Sandbox → Testeurs, puis
   TestFlight) : la sheet doit s'ouvrir, et après achat l'accès Premium doit
   apparaître dans l'app **et** en base (`user_subscriptions`, `ends_at` = jour de
   l'achat + 7 / 30 / 60 jours).

---

## 3. Google — Play Console

**Créer les 3 produits intégrés** (`Monétiser → Produits → Produits intégrés →
Créer un produit`), IDs en **minuscules obligatoirement** :

| ID de produit      | Prix    | Nom                   |
|--------------------|---------|-----------------------|
| `integral_pass_7j` | 9,99 €  | Pass Intégral 7 jours |
| `integral_pass_1m` | 19,99 € | Pass Intégral 1 mois  |
| `integral_pass_2m` | 29,99 € | Pass Intégral 2 mois  |

Chacun doit être passé en **Actif** après enregistrement.

**Désactiver les 3 anciens** (`integral_pass_sprint`, `integral_pass_3m`,
`integral_pass_1y`) : bouton **Désactiver** sur la fiche produit. Là encore, **ne
pas les supprimer** — les achats déjà encaissés et leurs remboursements passent
par ces identifiants.

Puis tester via la **piste de test interne** avec un compte testeur Google.

---

## 4. Stripe (web) — rien à créer

Le checkout web utilise un montant dynamique construit à partir de `plans.price` :
**aucun Price Stripe à créer ni à modifier**. Le nouveau prix s'applique dès que la
migration est passée.

À vérifier une fois : le webhook `https://api.sejourfr.fr/api/billing/webhook`
écoute bien `checkout.session.completed` et `charge.refunded`.

---

## 5. Recette après mise en ligne

- [ ] `/tarifs` affiche 3 passes Intégral (9,99 / 19,99 / 29,99) et 2 Civique,
      badge « populaire » sur le 2 mois.
- [ ] `/paiement` : le pass 7 jours affiche **« 7 jours »** (pas « 1 semaines »)
      et **aucun** équivalent mensuel ; le 2 mois affiche « soit 15 €/mois ».
- [ ] Achat web réel ou test : accès ouvert pour la bonne durée, email
      d'activation reçu.
- [ ] Paywall mobile (iOS et Android) : les 3 passes apparaissent avec les prix du
      store. S'ils manquent, c'est que le product ID de la plateforme ne
      correspond pas à celui saisi dans la console — comparer avec
      `GET /api/billing/plans`.
- [ ] Un achat mobile ouvre l'accès et le décompte de simulations orales
      correspond au pass (5 / 15 / 25).

---

## Points de vigilance

- **Les clients déjà servis ne sont pas touchés.** Un pass Intégral 3 mois acheté
  avant la bascule continue de courir jusqu'à sa date de fin : la durée a été
  copiée dans `user_subscriptions.ends_at` au moment du paiement, elle ne se relit
  pas dans `plans`. C'est aussi pourquoi on n'a pas modifié les anciennes lignes.
- **Ne rien supprimer** — ni les plans en base, ni les produits dans les stores.
  Toute la réversibilité du modèle (retour aux abonnements, remboursements
  tardifs) en dépend.
- **Retour arrière** : `UPDATE plans SET is_active = true WHERE code IN
  ('INTEGRAL_PASS_SPRINT','INTEGRAL_PASS_3M','INTEGRAL_PASS_1Y');` et `false` sur
  les trois nouveaux, plus la remise en vente côté stores. Aucune migration à
  écrire.
- **Prix affichés dans les stores** : Apple et Google convertissent eux-mêmes pour
  les autres devises ; le prix affiché au candidat vient du store, pas de notre
  base. Si les deux divergent, c'est le store qui a raison à l'écran — corriger le
  palier de prix côté console.
