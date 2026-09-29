# GUIDE CE — Compréhension écrite (A2 / B1 / B2)

> À utiliser avec `GUIDE_00_COMMUN_conventions.md`. La CE présente un **document
> écrit** (texte ou support visuel), une **question**, et 4 propositions.

---

## Structure d'un item CE

Champs de contenu (à mapper sur la table `questions`/`choices` du projet, ou la
table de drafts CE si elle existe — suivre le format des migrations CE existantes) :

```
difficulty ('A2'|'B1'|'B2'), competence_code, theme_id,
document         -- le texte OU le support visuel (voir ci-dessous)
statement        -- la question posée
explanation      -- correction pédagogique
choices (jsonb)  -- 4 propositions, 1 correcte
```

### Comment représenter le document

- **Document court visuel** (panneau, horaires, petite annonce, étiquette, plaque,
  SMS, écran de messagerie) → le rendre en **`inline_svg`** stylisé façon
  « document » (carte, cadre), avec le texte utile lisible **dans** le SVG (police
  Arial). Toujours `image_alt_text`.
- **Document textuel long** (mail, lettre, article, forum) → le mettre en **texte**
  (champ document/passage), mis en forme (sauts de ligne, signature).

Le choix dépend du niveau : A2 = beaucoup de supports visuels courts ; B2 = surtout
des textes longs.

---

## Calibration par niveau

### A2 — supports courts, info littérale
- **Documents** : panneau d'information, horaires d'ouverture, petite annonce,
  SMS, étiquette de prix, consigne, affichette. ~10-40 mots.
- **Question** : porte sur une information **explicite et unique** (un horaire, un
  prix, un lieu, une action demandée).
- **Distracteurs** : valeurs proches mais nettement distinctes (autre horaire,
  autre jour, autre lieu).
- Exemple (original, support visuel en SVG) :
  - Document : panneau « Cabinet ouvert du lundi au vendredi, 9 h-12 h sur
    rendez-vous, 14 h-18 h sans rendez-vous. Fermé le samedi. »
  - Q : « Quand peut-on venir sans rendez-vous ? »
  - A. Le matin · B. L'après-midi ✅ · C. Le samedi · D. À tout moment.

### B1 — textes moyens, inférence simple
- **Documents** : e-mail personnel, message de service (administration, commerce),
  court article informatif, message de forum, lettre courte. ~60-120 mots.
- **Question** : info explicite **ou** déduction simple (ce que la personne doit
  faire, ce qu'on lui propose, l'objet du message).
- **Distracteurs** : tous liés au thème ; piège = confondre deux informations
  proches du texte.
- Exemple (original, texte) :
  - Document : un message d'amis proposant de rejoindre leurs vacances à une
    certaine date, en précisant que les enfants ne restent qu'une semaine.
  - Q : « Que proposent-ils à leur amie ? »
  - 4 propositions plausibles ; la bonne reformule l'invitation réelle.

### B2 — textes longs, sens implicite
- **Documents** : article de presse, éditorial, texte argumentatif, courrier
  formel élaboré, extrait informatif dense. ~150-280 mots.
- **Question** : **inférence, intention de l'auteur, idée principale, opinion,
  conséquence implicite**. Souvent « Qu'apprend-on… ? », « Que pense l'auteur… ? ».
- **Distracteurs** : reformulations subtiles ; pièges = sur-généralisation,
  inversion de cause/effet, détail vrai mais secondaire présenté comme principal.
- Exemple (original, texte) :
  - Document : article sur le manque de places en crèche malgré un fort taux
    d'emploi des femmes, l'essentiel de la garde reposant sur les proches, et un
    plan gouvernemental jugé insuffisant.
  - Q : « Qu'apprend-on dans ce texte ? »
  - 4 affirmations ; la bonne synthétise l'idée centrale (la majorité des enfants
    gardés par les proches), les autres déforment ou exagèrent.

---

## Règles de rédaction des documents

- **Authenticité** : imiter un vrai support (mise en forme d'un mail, ton d'une
  affichette administrative, registre d'un article). Inventer le contenu.
- **Une seule bonne réponse** vérifiable dans le document. Le document doit
  contenir l'information nécessaire (pas de connaissance externe requise).
- Pour B2, soigner la **densité** : le texte doit contenir un détail piège qui rend
  un distracteur tentant.

---

## SVG pour les documents visuels CE (A2 surtout)

Style « document » : fond clair, cadre, le texte utile en `Arial` lisible. Exemple
de structure pour un panneau d'horaires :
```svg
<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg">
  <rect width="320" height="200" fill="#E8ECF8"/>
  <rect x="30" y="30" width="260" height="140" rx="6" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/>
  <rect x="30" y="30" width="260" height="26" fill="#1E3A8C"/>
  <text x="160" y="48" font-family="Arial" font-size="13" fill="#FFFFFF" text-anchor="middle">HORAIRES</text>
  <text x="50" y="85" font-family="Arial" font-size="12" fill="#0F1839">Lun-Ven : 9h-12h sur RDV</text>
  <text x="50" y="110" font-family="Arial" font-size="12" fill="#0F1839">14h-18h sans RDV</text>
  <text x="50" y="135" font-family="Arial" font-size="12" fill="#E1372F">Fermé le samedi</text>
</svg>
```
(Le rouge n'est utilisé que pour l'information critique « fermé ».)

---

## Checklist spécifique CE

- [ ] Type de support adapté au niveau (visuel court en A2, texte long en B2).
- [ ] Document **original**, autosuffisant, une seule bonne réponse vérifiable.
- [ ] Type de compréhension conforme (explicite A2 / inférence B1 / implicite B2).
- [ ] Longueur du document conforme (~10-40 / ~60-120 / ~150-280 mots).
- [ ] SVG document propre + `image_alt_text` si support visuel.
- [ ] + checklist universelle du commun.
