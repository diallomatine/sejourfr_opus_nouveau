# Conversation — Tests JEV pour l'estimation des niveaux CECRL

> Transcription complète de la conversation visible, du premier échange sur le test de JEV jusqu'à la demande de sauvegarde en Markdown.

---

## Utilisateur

Je suis sur l'interface JEV, j'ai envie de tester pour savoir s'il identifie bien les textes de niveau A2, B1, B2.

Donc, je veux que tu me donne tout ce qu'il faut lui donner pour qu'il puisse bien repondre et coment, je peux lui donner ce texte.

## Assistant

Pour le tester proprement, il faut surtout éviter de lui envoyer seulement « quel est le niveau de ce texte ? ». Il faut lui donner **une grille de décision stable**, puis changer uniquement la production du candidat.

Oui. Pour tester JEV sérieusement, utilise **Choice** : il est justement conçu pour choisir entre plusieurs catégories et renvoie les probabilités de chaque choix. Dans le Playground, tu renseignes un **State**, puis une **Question** avec les choix possibles.

Pour SejourFR, je commencerais exactement comme ça.

### 1. Dans `State`

Colle un objet de ce type, en changeant uniquement `consigne` et `production` à chaque test :

```json
{
  "contexte": "TCF IRN - Expression écrite",
  "consigne": "Vous avez participé à une fête dans votre ville. Écrivez à un ami pour raconter cette expérience et expliquer ce que vous avez aimé.",
  "production": "Hier je suis allé à une fête dans ma ville. Il y avait beaucoup de personnes et de la musique. J'ai retrouvé mes amis et nous avons mangé ensemble. J'ai beaucoup aimé l'ambiance parce que tout le monde était content. Après, nous avons regardé un concert. C'était une très bonne soirée et je voudrais retourner l'année prochaine."
}
```

**Ne mets surtout pas** dans le State : `niveau attendu : B1`. Sinon tu risques d'influencer la décision.

### 2. Ajoute une question `Choice`

**Instructions :**

```text
Quel niveau CECRL la production du candidat démontre-t-elle réellement en expression écrite ?

Évalue uniquement les capacités effectivement démontrées dans la production.

Prends notamment en compte :
- la capacité à accomplir la consigne et transmettre clairement le message ;
- la construction et l'enchaînement des phrases ;
- la grammaire ;
- le vocabulaire ;
- les connecteurs et la cohérence ;
- la capacité à raconter, expliquer, justifier ou argumenter lorsque cela est nécessaire.

Les erreurs sont acceptables tant qu'elles ne compromettent pas fortement la communication.

Ne déduis pas le niveau uniquement à partir du nombre de mots, de la difficulté apparente du sujet ou du type de tâche.
```

### 3. Mets ces `Criteria`

```text
A2:
Peut écrire un texte simple sur des sujets familiers. Utilise principalement des phrases et structures simples, reliées par des connecteurs élémentaires comme "et", "mais", "parce que", "après". Le vocabulaire est courant et assez limité. Les erreurs grammaticales peuvent être nombreuses, mais le message reste généralement compréhensible.

B1:
Peut produire un texte simple mais suivi et cohérent. Peut raconter une expérience, décrire des événements, exprimer une opinion ou donner des raisons simples. Utilise plusieurs connecteurs et dispose d'un vocabulaire suffisant pour développer son message. Les erreurs restent présentes mais ne gênent généralement pas la compréhension.

B2:
Peut produire un texte clair, développé et structuré. Peut expliquer et défendre une opinion, développer plusieurs arguments, comparer des idées ou présenter des avantages et inconvénients. Utilise une gamme plus large de vocabulaire et de connecteurs. Montre un bon contrôle grammatical global malgré quelques erreurs occasionnelles.

INSUFFICIENT:
La production est trop courte, hors sujet ou contient trop peu d'éléments linguistiques pour permettre de distinguer raisonnablement A2, B1 ou B2.
```

J'ajouterais vraiment `INSUFFICIENT`. Sinon JEV sera **obligé de choisir A2/B1/B2 même quand il n'a pas assez d'informations**.

### Ce que tu regardes ensuite

JEV devrait te renvoyer quelque chose du genre :

```json
{
  "choice": "B1",
  "probabilities": {
    "A2": 0.18,
    "B1": 0.71,
    "B2": 0.09,
    "INSUFFICIENT": 0.02
  }
}
```

C'est justement le point intéressant pour SejourFR : **ne regarde pas seulement `B1`**, regarde la distribution.

Par exemple `A2 0.46 / B1 0.51` signifie plutôt **production frontière A2/B1** que « candidat clairement B1 ».

Je te conseille maintenant de lui envoyer **10 textes que toi tu connais déjà : 3 A2 clairs, 3 B1 clairs, 3 B2 clairs + 1 cas ambigu**, sans lui révéler leurs niveaux. C'est là qu'on verra réellement si JEV peut remplacer ou compléter ton calcul actuel.

---

## Utilisateur

[Image envoyée : interface JEV]

voici, l'interafce , j'ecrsi quoi où ?

## Assistant

Oui, sur ton écran c’est très simple :

1. **En haut à gauche — `State`**  
   Ce que tu as mis est déjà bon. Garde ici uniquement le contexte, la consigne et la production du candidat :

```json
{
  "contexte": "TCF IRN - Expression écrite",
  "consigne": "Vous avez participé à une fête dans votre ville. Écrivez à un ami pour raconter cette expérience et expliquer ce que vous avez aimé.",
  "production": "Hier je suis allé à une fête dans ma ville. Il y avait beaucoup de personnes et de la musique..."
}
```

2. **En bas à gauche — `Questions`**  
   Clique sur **`Choice`**.

Ensuite, dans la question, mets quelque chose de **court**, par exemple :

```text
Quel est le niveau CECRL réellement démontré par cette production écrite ?
```

Puis comme choix, mets :

```text
A2
B1
B2
INSUFFICIENT
```

Si l’interface te demande une description ou des critères pour les choix, mets :

```text
A2 : texte simple sur un sujet familier, phrases principalement simples,
vocabulaire courant, connecteurs élémentaires. Des erreurs sont possibles
mais le message reste compréhensible.

B1 : texte suivi et cohérent. Le candidat peut raconter, expliquer,
donner des raisons simples et relier plusieurs idées. Les erreurs ne gênent
généralement pas la compréhension.

B2 : texte clair, développé et structuré. Le candidat peut développer,
justifier ou comparer des idées avec un vocabulaire et des structures
plus variés et un bon contrôle global de la langue.

INSUFFICIENT : texte trop court, hors sujet ou ne contenant pas assez
d'éléments pour déterminer raisonnablement A2, B1 ou B2.
```

**Donc ton écran doit essentiellement être :**

```text
STATE
└── consigne
└── production

QUESTIONS
└── Choice
    └── "Quel est le niveau CECRL réellement démontré..."
        ├── A2
        ├── B1
        ├── B2
        └── INSUFFICIENT
```

Ne mets pas toute une longue grille dans la question pour le premier test. **Je voudrais d’abord voir comment Jev réagit avec une définition CECRL assez simple.**

👉 **Clique maintenant sur `Choice` et envoie-moi une capture de ce qui apparaît.** Je te dirai exactement quoi mettre dans chacun des champs.

---

## Utilisateur

[Image envoyée : interface JEV après clic sur Choice]

## Assistant

Oui, l’erreur vient juste du format : la zone **Questions attend du JSON**, pas une phrase directement.

Efface tout ce qu’il y a dans **Questions** et colle exactement ceci :

```json
{
  "niveau_cecrl": {
    "type": "choice",
    "instructions": "Quel est le niveau CECRL réellement démontré par cette production écrite ?",
    "criteria": {
      "A2": "Texte simple sur un sujet familier. Phrases principalement simples, vocabulaire courant, connecteurs élémentaires. Des erreurs sont possibles mais le message reste compréhensible.",
      "B1": "Texte suivi et cohérent. Le candidat peut raconter, expliquer, donner des raisons simples et relier plusieurs idées. Les erreurs ne gênent généralement pas la compréhension.",
      "B2": "Texte clair, développé et structuré. Le candidat peut développer, justifier ou comparer des idées avec un vocabulaire et des structures plus variés et un bon contrôle global de la langue.",
      "INSUFFICIENT": "Production trop courte, hors sujet ou contenant trop peu d'éléments pour déterminer raisonnablement un niveau A2, B1 ou B2."
    }
  }
}
```

Ton écran doit donc avoir :

**State** → ce que tu as déjà actuellement ✅

**Questions** → le JSON ci-dessus.

Ensuite clique sur **Run request**.

Jev devrait te retourner quelque chose avec un choix (`A2`, `B1`, etc.), les probabilités associées et un niveau de confiance.

Envoie-moi ensuite **la capture du résultat**, et on analysera si sa décision est cohérente.

---

## Utilisateur

voici un exemple de comment remplir la partie question

```json
{
  "sky_color": {
    "type": "choice",
    "instructions": "What color is the sky?",
    "criteria": {
      "indigo": "",
      "electric blue": "",
      "baby blue": "",
      "gray": "",
      "lavender": "",
      "salmon": "",
      "seafoam green": ""
    }
  },
  "sky_color_with_desc": {
    "type": "choice",
    "instructions": {
      "object": "sky",
      "question": "what color is `object`?"
    },
    "criteria": {
      "indigo": {
        "description": "very dark, deep blue, like fountain-pen ink",
        "hex": "#280868",
        "rgb": {
          "red": 40,
          "green": 8,
          "blue": 104
        },
        "hsl": {
          "hue": 260,
          "saturation": "86%",
          "lightness": "22%"
        }
      },
      "electric blue": {
        "description": "bright, punchy blue, like a swimming pool",
        "hex": "#1585E7",
        "rgb": {
          "red": 21,
          "green": 133,
          "blue": 231
        },
        "hsl": {
          "hue": 208,
          "saturation": "83%",
          "lightness": "49%"
        }
      },
      "baby blue": {
        "description": "a very pale, soft blue, like a robin's egg",
        "hex": "#C2E4F1",
        "rgb": {
          "red": 194,
          "green": 228,
          "blue": 241
        },
        "hsl": {
          "hue": 197,
          "saturation": "63%",
          "lightness": "85%"
        }
      },
      "gray": {
        "description": "a pale slate, like a heron's feathers",
        "hex": "#B1CBD1",
        "rgb": {
          "red": 177,
          "green": 203,
          "blue": 209
        },
        "hsl": {
          "hue": 191,
          "saturation": "26%",
          "lightness": "76%"
        }
      },
      "lavender": {
        "description": "a dusty blue-purple, like wisteria blossoms",
        "hex": "#847CBF",
        "rgb": {
          "red": 132,
          "green": 124,
          "blue": 191
        },
        "hsl": {
          "hue": 247,
          "saturation": "34%",
          "lightness": "62%"
        }
      },
      "salmon": {
        "description": "a warm, almost-orange pink, like coral",
        "hex": "#FB7A65",
        "rgb": {
          "red": 251,
          "green": 122,
          "blue": 101
        },
        "hsl": {
          "hue": 8,
          "saturation": "95%",
          "lightness": "69%"
        }
      },
      "seafoam green": {
        "description": "a muted, grayish green, like dried eucalyptus leaves",
        "hex": "#94BDB5",
        "rgb": {
          "red": 148,
          "green": 189,
          "blue": 181
        },
        "hsl": {
          "hue": 168,
          "saturation": "24%",
          "lightness": "66%"
        }
      }
    }
  }
}
```

reerit tout

## Assistant

Oui. Avec ton exemple, je ferais le test de façon plus propre en exploitant les **objets dans `instructions` et dans `criteria`**.

### 1. Dans `State`

Colle ceci :

```json
{
  "contexte": "TCF IRN - Expression écrite",
  "consigne": "Vous avez participé à une fête dans votre ville. Écrivez à un ami pour raconter cette expérience et expliquer ce que vous avez aimé.",
  "production": "Hier je suis allé à une fête dans ma ville. Il y avait beaucoup de personnes et de la musique. J'ai retrouvé mes amis et nous avons mangé ensemble. J'ai beaucoup aimé l'ambiance parce que tout le monde était content. Après, nous avons regardé un concert. C'était une très bonne soirée et je voudrais retourner l'année prochaine."
}
```

### 2. Dans `Questions`

Colle **exactement ceci** :

```json
{
  "niveau_cecrl": {
    "type": "choice",
    "instructions": {
      "objectif": "Déterminer le niveau CECRL réellement démontré par la production écrite du candidat.",
      "contexte": "Évaluation d'une production écrite en français dans le cadre du TCF IRN.",
      "regle": "Évaluer uniquement les capacités linguistiques effectivement démontrées dans la production. Ne pas déduire le niveau à partir du niveau supposé de la tâche.",
      "elements_a_observer": [
        "respect et compréhension de la consigne",
        "capacité à transmettre clairement le message",
        "construction des phrases",
        "grammaire",
        "vocabulaire",
        "cohérence et enchaînement des idées",
        "connecteurs",
        "capacité à raconter, expliquer, justifier ou argumenter"
      ],
      "tolerance": "Les erreurs grammaticales, lexicales ou orthographiques sont acceptables si elles ne compromettent pas fortement la compréhension."
    },
    "criteria": {
      "A2": {
        "description": "La production démontre principalement un niveau A2.",
        "communication": "Le candidat peut transmettre des informations simples sur des sujets familiers et accomplir une tâche quotidienne simple.",
        "phrases": "Les phrases sont principalement simples et relativement courtes.",
        "grammaire": "Le candidat maîtrise certaines structures simples mais commet régulièrement des erreurs.",
        "vocabulaire": "Le vocabulaire est courant et relativement limité, mais suffisant pour communiquer l'essentiel.",
        "coherence": "Les idées peuvent être reliées avec des connecteurs simples comme et, mais, parce que, puis ou après.",
        "developpement": "Le candidat décrit ou raconte simplement, avec peu de développement.",
        "erreurs": "Les erreurs peuvent être fréquentes mais le message reste globalement compréhensible."
      },
      "B1": {
        "description": "La production démontre principalement un niveau B1.",
        "communication": "Le candidat peut produire un texte compréhensible et suffisamment développé sur des sujets familiers.",
        "phrases": "Le candidat combine des phrases simples et certaines structures plus développées.",
        "grammaire": "Le contrôle grammatical est suffisant pour communiquer clairement malgré des erreurs régulières.",
        "vocabulaire": "Le vocabulaire est suffisamment varié pour raconter une expérience, expliquer une situation ou exprimer une opinion simple.",
        "coherence": "Les idées sont organisées dans un texte suivi avec plusieurs connecteurs.",
        "developpement": "Le candidat peut raconter, expliquer, donner des raisons simples et développer plusieurs idées.",
        "erreurs": "Les erreurs restent visibles mais ne gênent généralement pas la compréhension."
      },
      "B2": {
        "description": "La production démontre principalement un niveau B2.",
        "communication": "Le candidat produit un texte clair, développé et structuré.",
        "phrases": "Le candidat utilise une variété de structures simples et complexes avec une certaine souplesse.",
        "grammaire": "Le contrôle grammatical est globalement bon, même si quelques erreurs peuvent subsister.",
        "vocabulaire": "Le vocabulaire est assez étendu et précis pour développer et nuancer les idées.",
        "coherence": "Les idées sont organisées logiquement avec une gamme variée de connecteurs et d'articulateurs.",
        "developpement": "Le candidat peut expliquer, justifier, comparer ou développer une argumentation de manière claire.",
        "erreurs": "Les erreurs ne sont généralement pas systématiques et n'empêchent pas une communication précise."
      },
      "INSUFFICIENT": {
        "description": "La production ne permet pas d'établir raisonnablement un niveau A2, B1 ou B2.",
        "cas_possibles": [
          "production beaucoup trop courte",
          "production largement hors sujet",
          "texte essentiellement incompréhensible",
          "quantité de langue insuffisante pour observer les compétences"
        ]
      }
    }
  }
}
```

### Pourquoi je préfère cette version

Elle oblige JEV à distinguer **A2 / B1 / B2 sur plusieurs dimensions**, et non simplement à se dire :

> « C'est une tâche 2, donc probablement B1. »

Et surtout, pour tes futurs tests, **ne change plus la partie `Questions`**. Tu modifies seulement dans `State` :

```json
"consigne": "...",
"production": "..."
```

Comme ça, tu peux comparer 20 ou 50 productions avec **exactement le même juge et les mêmes règles**. C'est beaucoup plus intéressant pour savoir si JEV est suffisamment stable pour SejourFR.

---

## Utilisateur

- A2 : 70 %
- B1 : 30 %
- INSUFFICIENT : 0 %
- Confidence : 59 %

qu'en penses-tu ?

## Assistant

Oui, je trouve le résultat **plutôt cohérent**.

Pour ce texte, je le situerais aussi vers **A2 fort / B1 débutant**. Il y a déjà quelques éléments B1 : récit chronologique, passé composé, justification avec « parce que », enchaînement des idées, expression d’un souhait. Mais le texte reste très simple : structures peu variées, vocabulaire basique, développement limité.

Donc :

**A2 70 % / B1 30 %** → crédible.  
**Confidence 59 %** → intéressant aussi : JEV semble détecter que c’est un **cas frontière**, au lieu de prétendre que le niveau est évident.

Pour SejourFR, je ne transformerais donc pas automatiquement ça en « niveau A2 certain ». Je garderais plutôt une logique du genre :

```text
A2 90% / B1 10% → A2 assez clair

A2 70% / B1 30% → A2, proche du B1

A2 52% / B1 48% → niveau frontière, à confirmer

B1 85% / A2 15% → B1 assez clair
```

Le prochain test important serait maintenant de lui donner **un vrai B1 assez évident**, puis un **B2 évident**. S’il les sépare correctement, là ça devient vraiment intéressant pour ton système d’évaluation.

---

## Utilisateur

alors, donne moi un texte B1, evident.

## Assistant

Oui. Pour tester correctement JEV, garde **exactement la même consigne** et remplace seulement `production` par ce texte, volontairement **B1 assez net** :

```text
Samedi dernier, j’ai participé à une fête organisée dans ma ville. Je suis arrivé vers 18 heures avec deux amis et il y avait déjà beaucoup de monde. D’abord, nous avons fait le tour des stands pour découvrir les spécialités de la région. Ensuite, nous avons assisté à un concert sur la place principale.

J’ai particulièrement aimé l’ambiance parce que les habitants étaient très accueillants et tout le monde pouvait participer aux activités. Même s’il y avait beaucoup de personnes, l’organisation était bonne et nous n’avons pas attendu longtemps.

À la fin de la soirée, un feu d’artifice a été organisé. C’était vraiment un beau moment. J’aimerais participer de nouveau à cette fête l’année prochaine, car cela m’a permis de passer du temps avec mes amis et de découvrir ma ville autrement.
```

Pourquoi je le considère **B1 évident** : récit suivi, chronologie claire (`d’abord`, `ensuite`, `à la fin`), justification (`parce que`, `car`), concession (`même si`), ressenti et développement de plusieurs idées.

Il reste volontairement **simple et naturel** : je n’ai pas mis d’argumentation sophistiquée ni de vocabulaire particulièrement recherché qui pourrait le pousser vers B2.

👉 Envoie-le à JEV et donne-moi ses pourcentages. C’est là que le test devient intéressant.

---

## Utilisateur

voici :

- B1 : 76 %
- B2 : 23 %
- A2 : 1 %
- Confidence : 69 %

## Assistant

C’est plutôt encourageant.

**B1 76 % / B2 23 % / A2 1 %** montre qu’il distingue bien ce texte du précédent. Le **23 % de B2 ne me choque pas** : le texte est propre, structuré et assez fluide, donc il peut sembler proche du seuil B2 sans vraiment y être.

Le point intéressant est surtout la progression :

- texte précédent → **A2 70 % / B1 30 %**
- texte B1 → **B1 76 % / B2 23 %**

Donc JEV semble capter une vraie montée de niveau.

La **confidence à 69 %** reste moyenne : il voit encore une proximité B1/B2, ce qui est logique pour un bon B1.

Le prochain test utile est un **B2 vraiment évident**, avec argumentation, nuance, comparaison et structures plus complexes. Si JEV sort par exemple **B2 autour de 75–90 %**, ce sera un très bon signe.

---

## Utilisateur

ok, donne moi ce texte B2 evident.

## Assistant

Oui. Garde exactement la même consigne et remplace seulement la production par celle-ci :

```text
Samedi dernier, j’ai participé à une fête organisée dans ma ville. Même si ce type d’événement peut parfois sembler assez banal, j’ai été agréablement surpris par la qualité de l’organisation et par la diversité des activités proposées.

Ce que j’ai le plus apprécié, c’est que la fête ne se limitait pas seulement à des concerts ou à des stands de nourriture. Plusieurs associations locales étaient également présentes pour présenter leurs projets, ce qui permettait aux habitants de mieux connaître les initiatives de leur quartier. À mon avis, c’est justement ce type d’activité qui rend une fête vraiment intéressante, car elle permet à la fois de se divertir et de créer du lien entre les habitants.

Bien sûr, tout n’était pas parfait. Il y avait beaucoup de monde et certains espaces étaient difficiles d’accès. Cependant, ces quelques problèmes n’ont pas vraiment gâché l’expérience.

Je pense que la ville devrait continuer à organiser ce genre d’événements, tout en améliorant certains aspects pratiques. Cela permettrait non seulement d’attirer davantage de participants, mais aussi de renforcer la vie locale.
```

Celui-ci est clairement plus **B2** parce qu’il y a davantage de nuance, de justification, de concession, de développement et de structures comme :

`même si`, `ce qui permettait`, `à mon avis`, `bien sûr`, `cependant`, `non seulement... mais aussi`.

Envoie-moi le résultat JEV ensuite.

---

## Utilisateur

- B2 : 96 %
- B1 : 4 %
- INSUFFICIENT : 0 %
- Confidence : 94 %

## Assistant

Oui, là c’est très encourageant.

Sur les 3 tests :

- A2 attendu → **A2 70 %**
- B1 attendu → **B1 76 %**
- B2 attendu → **B2 96 %**

Et surtout, les probabilités évoluent de façon logique : le B1 garde un peu de B2, alors que le B2 est identifié de manière très nette.

Le point intéressant est aussi la **confidence** :
- cas frontière A2/B1 → **59 %**
- B1 assez clair → **69 %**
- B2 très clair → **94 %**

C’est exactement le comportement qu’on voudrait d’un évaluateur : être plus prudent quand le niveau est ambigu.

Par contre, 3 textes ne suffisent pas encore. Maintenant, je testerais surtout les cas difficiles : un **A2 avec très peu de fautes**, un **B1 avec beaucoup de fautes mais une bonne communication**, un **texte long mais faible**, un **texte court mais très bon**, et surtout des productions **frontières A2/B1 et B1/B2**.

C’est là qu’on verra si JEV peut vraiment être utile dans ton système, pas seulement sur des exemples “propres”.

---

## Utilisateur

Ok, donne moi ces textes, un par un. je lui donne et à chaque fois, je te donne la reponse et on continue, c'est par un, on y vas. soit vraiment dans la peau des candidats, pas des textes très bien oragnisé même en A2.

## Assistant

On commence par **Test 1 : un A2 avec peu de fautes**, mais qui ressemble vraiment à un candidat, pas à un texte fabriqué.

Garde la même consigne et mets uniquement cette production :

```text
Salut Marie,

Samedi je suis allé à la fête de ma ville avec ma sœur. Il y avait beaucoup de monde et de la musique. Nous avons mangé des crêpes et après nous avons regardé un petit concert.

J'ai bien aimé la fête parce que l'ambiance était sympa. J'ai aussi rencontré un ancien ami de l'école et nous avons parlé un peu.

Je suis rentré chez moi vers 23 heures. J'étais fatigué mais content. Je pense que je vais revenir l'année prochaine.
```

Ici, je vise **A2 assez net** : peu de fautes, mais vocabulaire simple, phrases courtes, développement limité et connecteurs très basiques.

Donne-moi simplement le résultat JEV, et je t'envoie le **test 2**.

---

## Utilisateur

- A2 : 60 %
- B1 : 40 %
- B2 : 0 %
- Confidence : 46 %

suivant

## Assistant

Parfait. **Test 2 : B1 avec pas mal de fautes, mais une communication solide.**

Garde la même consigne et remplace seulement la production par :

```text
Salut,

Samedi dernier je suis allé à la fête de ma ville avec deux amis. Au début on pensait rester seulement une heure mais finalement on est resté presque toute la soirée.

Il y avait beaucoup des choses à faire. On a regardé un concert, après on a mangé dans un stand et on a aussi participé à un jeu. J’ai préféré le concert parce que le groupe jouait des chansons que je connaissais.

Il y avait beaucoup de personnes et parfois c’était difficile pour marcher, mais l’ambiance était très bien. Les gens était gentils et tout le monde semblait content.

Je pense que cette fête est une bonne idée parce que ça permet aux habitants de se rencontrer. L’année prochaine je veux y retourner avec ma famille.
```

Ici, je vise **B1 malgré les erreurs** : le candidat raconte, développe, justifie et relie plusieurs idées, mais avec une grammaire encore instable.

Donne-moi le résultat JEV.

---

## Utilisateur

- B1 : 84 %
- A2 : 15 %
- B2 : 1 %
- Confidence : 79 %

## Assistant

Très intéressant : **B1 84 % malgré les fautes**, c’est exactement le comportement qu’on voulait vérifier. JEV semble bien distinguer **niveau linguistique** et **absence de fautes**.

### Test 3 — texte assez long, mais niveau faible

Ici, je veux voir s’il se laisse tromper par la longueur. Je vise **A2**, malgré un texte relativement long.

```text
Salut Marie,

Je veux te raconter la fête de ma ville. Je suis allé samedi avec ma famille. Il y avait beaucoup de personnes et beaucoup de choses. Il y avait la musique, des jeux, des boissons et aussi des choses pour manger.

D’abord nous avons marché dans la fête. Après nous avons mangé des sandwichs. Moi j’ai pris un sandwich au poulet parce que j’aime beaucoup le poulet. Après nous avons regardé la musique. Il y avait un groupe et les personnes dansaient. Moi je ne danse pas beaucoup mais ma sœur elle aime danser.

J’ai aimé cette fête parce que c’était bien et les personnes étaient gentilles. Il y avait aussi beaucoup d’enfants avec leurs parents. Après j’étais fatigué alors nous sommes rentré à la maison.

Je veux retourner l’année prochaine parce que j’aime les fêtes et c’est bien pour passer le temps avec ma famille.
```

Le piège : **beaucoup de mots**, mais beaucoup de répétitions, vocabulaire limité, phrases simples et peu de véritable développement.

Envoie-moi son résultat.

---

## Utilisateur

- A2 : 76 %
- B1 : 24 %
- INSUFFICIENT : 0 %
- Confidence : 68 %

## Assistant

Très bon signe encore : **A2 76 %** malgré la longueur. Il ne semble donc pas confondre « texte long » avec « niveau élevé ».

### Test 4 — texte court, mais bon niveau

Cette fois, je vise **B1 clair**, avec peu de mots mais de bonnes capacités linguistiques.

```text
Salut Marie,

Je suis allé à la fête de la ville samedi soir et, franchement, j’ai passé un très bon moment. Il y avait beaucoup de monde, mais l’ambiance restait agréable.

J’ai surtout aimé le concert organisé sur la grande place. Le groupe était excellent et les musiciens faisaient vraiment participer le public. Même si nous sommes arrivés un peu tard, nous avons réussi à trouver une bonne place.

Je pense que j’y retournerai l’année prochaine, surtout si la ville organise encore des concerts comme celui-là.
```

Il est **court**, mais on trouve de la concession (`même si`), de la justification, des phrases plus construites et un récit cohérent.

Envoie-moi le résultat JEV.

---

## Utilisateur

- B1 : 84 %
- B2 : 15 %
- A2 : 1 %
- Confidence : 78 %

## Assistant

Très bon : **B1 84 %** malgré le texte court. Pour l’instant, JEV réagit de façon assez cohérente.

### Test 5 — frontière A2 / B1

Là, je veux vraiment le mettre dans le doute. Texte de candidat assez naturel, pas parfaitement organisé, avec quelques erreurs, mais un peu plus de développement qu’un A2 classique.

```text
Salut Marie,

Samedi je suis allé à la fête de ma ville avec des amis. Au début je voulais pas rester longtemps parce que j’étais fatigué, mais finalement on est resté presque jusqu’à la fin.

Il y avait plusieurs choses à faire. On a mangé, après on a regardé un concert. J’ai bien aimé parce que le groupe mettait une bonne ambiance et les gens chantaient avec eux.

Par contre il y avait vraiment beaucoup de monde et parfois c’était difficile de passer. Je pense qu’ils peuvent mieux organiser ça l’année prochaine.

Mais en général j’ai passé une bonne soirée et je voudrais revenir.
```

Ici, j’attends quelque chose comme **A2/B1 assez partagé**, parce qu’il y a déjà justification, opposition, avis et petite suggestion, mais le niveau reste simple.

Envoie-moi le résultat.

---

## Utilisateur

- B1 : 77 %
- A2 : 22 %
- B2 : 1 %
- Confidence : 70 %

## Assistant

Intéressant : JEV le voit plutôt **B1 net**, pas vraiment frontière. Ça montre qu’il valorise assez vite la capacité à justifier et organiser un minimum.

### Test 6 — frontière B1 / B2

Ici, je veux quelque chose de plus réaliste : bon candidat, idées développées, mais pas un texte « scolaire parfait ».

```text
Salut Marie,

Samedi je suis allé à la fête organisée dans ma ville. Franchement, je pensais que ça allait être comme les autres années, mais cette fois j’ai trouvé qu’il y avait plus d’activités et une meilleure ambiance.

Ce que j’ai surtout aimé, c’est que les organisateurs avaient prévu des choses pour tout le monde. Il y avait des concerts, des jeux pour les enfants et aussi des stands avec des associations locales. Je trouve que c’est une bonne idée parce que ça permet aux habitants de se rencontrer et pas seulement de venir pour manger ou écouter de la musique.

Par contre, il y avait vraiment trop de monde vers 20 heures et on pouvait presque plus avancer dans certaines rues. Peut-être qu’ils devraient mieux organiser les entrées l’année prochaine.

Malgré ça, j’ai passé une très bonne soirée. Je pense que ce genre de fête est important pour une ville, surtout parce que les gens ont peu d’occasions de se retrouver comme ça.
```

Moi, je le vois **B1 fort / B2 débutant** : plus de nuance, avis développé, proposition, justification, mais le langage reste encore assez simple et naturel.

Donne-moi le résultat JEV.

---

## Utilisateur

- B1 : 55 %
- B2 : 45 %
- INSUFFICIENT : 0 %
- Confidence : 39 %

## Assistant

Là, c’est **très intéressant** : **B1 55 % / B2 45 % avec seulement 39 % de confiance**.

C’est exactement ce qu’on voulait provoquer : JEV détecte un vrai **cas frontière B1/B2**, au lieu de forcer un niveau avec beaucoup de certitude. Pour moi, ce résultat est très cohérent.

### Test 7 — vocabulaire un peu “avancé”, mais niveau réel plutôt B1

Je veux voir s’il se fait piéger par quelques expressions apprises par cœur.

```text
Salut Marie,

Samedi dernier je suis allé à la fête de ma ville. Dans l’ensemble, j’ai passé une bonne soirée et l’organisation était plutôt satisfaisante.

Tout d’abord, il y avait plusieurs activités intéressantes comme des concerts et des stands de nourriture. J’ai particulièrement apprécié le concert car la musique était très bonne et il y avait une ambiance chaleureuse.

Cependant, il y avait trop de personnes et parfois c’était compliqué pour circuler. À mon avis, les organisateurs devraient prévoir plus d’espace, afin que les visiteurs peuvent profiter mieux de la fête.

En conclusion, malgré quelques problèmes, cette fête était une bonne expérience. J’aimerais y retourner l’année prochaine parce que c’est une bonne occasion pour rencontrer les habitants et passer un bon moment ensemble.
```

Le piège : `dans l’ensemble`, `tout d’abord`, `cependant`, `à mon avis`, `afin que`, `en conclusion` donnent une impression assez avancée, mais derrière, les structures restent simples et il y a des maladresses typiques.

Moi, je vise **B1**, éventuellement avec une petite probabilité B2.

Donne-moi le résultat.

---

## Utilisateur

- B1 : 78 %
- B2 : 21 %
- A2 : 1 %
- Confidence : 71 %

## Assistant

Oui, très cohérent : **B1 78 % / B2 21 %**. Il ne s’est pas laissé impressionner par les connecteurs “scolaires”. C’est un bon signal.

### Test 8 — B2 dans le raisonnement, mais avec plusieurs erreurs

Je veux voir maintenant s’il sait reconnaître un niveau élevé **malgré une langue imparfaite**, ce qui sera fréquent avec de vrais candidats.

```text
Salut Marie,

Samedi je suis allé à la fête de la ville et j’ai été assez surpris parce que cette année ils ont essayé de faire quelque chose différent.

Ce que j’ai trouvé intéressant, c’est qu’il n’y avait pas seulement des concerts. Des associations étaient présent aussi et elles expliquaient leurs activités aux habitants. Je pense que c’est important car souvent les gens vivent dans la même ville mais ils ne connaissent même pas ce qui existe près de chez eux.

Par contre, l’organisation avait quelques problèmes. Il y avait trop de monde dans certaines rues et les personnes avec des enfants pouvait difficilement passer. À mon avis, la mairie aurait dû prévoir plus d’espace ou fermer d’autres rues pour que les visiteurs puissent circuler plus facilement.

Malgré ces problèmes, je trouve que l’événement était réussi. Ce genre de fête permet aux gens de se rencontrer et, même si ça demande beaucoup d’organisation, je pense que la ville devrait continuer à la faire chaque année.
```

Je vise **B2 plutôt que B1**, mais pas un B2 à 95 % : raisonnement, nuance, hypothèse et proposition sont là, avec plusieurs erreurs visibles.

Donne-moi le résultat JEV.

---

## Utilisateur

- B2 : 55 %
- B1 : 45 %
- INSUFFICIENT : 0 %
- Confidence : 40 %

## Assistant

C’est encore cohérent : **B2 55 % / B1 45 %**, avec seulement **40 % de confiance**. JEV comprend qu’il y a des capacités B2, mais que les erreurs rendent le classement fragile. C’est exactement le genre de cas intéressant pour SejourFR.

### Test 9 — production trop courte pour juger sérieusement

Même consigne, mais candidat qui écrit très peu :

```text
Salut Marie,

Samedi je suis allé à la fête de ma ville avec mes amis. Il y avait beaucoup de musique et beaucoup de monde. J’ai aimé le concert parce que c’était très bien.

À bientôt !
```

Ici, le vrai test est différent : **est-ce que JEV va oser dire `INSUFFICIENT`**, ou va-t-il automatiquement classer A2 ?

À mon sens, cette production montre quelques éléments A2, mais **il y a trop peu de matière pour estimer sérieusement le niveau global du candidat**.

Donne-moi son résultat.

---

## Utilisateur

- A2 : 96 %
- INSUFFICIENT : 3 %
- B1 : 1 %
- Confidence : 94 %

## Assistant

Là, c’est intéressant : **A2 96 % / confiance 94 %**.

Je ne considère pas forcément ça comme une erreur. Notre question demande le **niveau réellement démontré par le texte**. Même court, ce texte démontre clairement des capacités A2 ; il ne démontre simplement rien de B1. `INSUFFICIENT` devrait plutôt servir aux productions vraiment inutilisables : 5 mots, hors sujet total, texte incompréhensible, etc.

### Test 10 — niveau irrégulier dans le même texte

Cas très réaliste : le candidat commence correctement, puis son niveau devient beaucoup plus simple et instable.

```text
Salut Marie,

Samedi dernier je suis allé à la fête de ma ville avec quelques amis. Au début, je ne voulais pas vraiment y aller parce que j’étais fatigué après le travail, mais finalement je ne regrette pas.

On a commencé par regarder un concert qui était organisé sur la grande place. J’ai beaucoup aimé parce que le chanteur parlait avec le public et il y avait une bonne ambiance.

Après nous mangeons des sandwich et moi je prend poulet. Il y avait beaucoup les personnes. C'était difficile marcher parce que beaucoup de monde. Après mon ami veut aller voir les jeux mais moi fatigué alors je reste assis.

Mais je suis content de cette soirée. Je pense c'est bien faire des fêtes comme ça parce que les personnes peuvent être ensemble.
```

Ici, je m’attends à un **A2 fort / B1 fragile**, ou éventuellement B1 avec faible confiance. C’est typiquement le genre de production irrégulière qu’on rencontrera réellement.

Donne-moi le résultat.

---

## Utilisateur

- A2 : 66 %
- B1 : 34 %
- INSUFFICIENT : 0 %
- Confidence : 55 %

## Assistant

Oui, **A2 66 % / B1 34 % / confiance 55 %**, c’est cohérent avec le texte irrégulier. Il repère bien que le début montre davantage de B1, mais que la suite retombe nettement vers A2.

### Test 11 — langue correcte, mais consigne mal exploitée

Cette fois, je veux voir s’il prend vraiment en compte **l’accomplissement de la tâche**, et pas seulement la qualité du français.

```text
Salut Marie,

Samedi dernier, il y avait une grande fête dans ma ville. Elle a commencé vers 16 heures et s’est terminée assez tard dans la soirée. De nombreuses personnes étaient présentes et plusieurs rues du centre-ville avaient été fermées à la circulation.

Il y avait différents stands, des activités pour les enfants et plusieurs concerts. Les restaurants étaient également ouverts et beaucoup de familles se promenaient dans le centre.

La fête était organisée par la mairie avec la participation de plusieurs associations locales. Des policiers étaient aussi présents pour assurer la sécurité.

Voilà, je voulais simplement te raconter comment cette journée s’est déroulée.

À bientôt.
```

Le français est propre et relativement maîtrisé, mais le candidat **décrit surtout l’événement**. Il explique très peu ce qu’il a personnellement vécu ou aimé, alors que la consigne le demande.

Je voudrais voir si JEV lui donne un **B1**, s’il monte vers B2 à cause de la langue, ou s’il le pénalise pour l’accomplissement incomplet de la tâche.

---

## Utilisateur

- B1 : 62 %
- A2 : 35 %
- B2 : 3 %
- Confidence : 50 %

## Assistant

Oui, c’est cohérent.

**B1 62 % / A2 35 % / B2 3 %**, avec **50 % de confiance**, ça montre qu’il voit bien que le français est correct mais que la tâche est seulement partiellement exploitée. C’est plutôt bon signe, parce qu’il ne surévalue pas le texte en B2 juste parce qu’il est propre.

Le point à surveiller : il ne “punit” pas énormément le non-respect partiel de la consigne. Pour SejourFR, ça peut être acceptable si tu veux que le niveau CECRL reflète surtout **ce que le candidat sait faire linguistiquement**, et que le respect de la consigne soit évalué séparément.

### Test 12 — très bon français, mais réponse presque hors sujet

```text
Salut Marie,

Je voulais te parler de ma ville parce qu’elle a beaucoup changé ces dernières années. Avant, il y avait peu de commerces dans le centre, mais aujourd’hui on trouve davantage de restaurants, de cafés et d’espaces pour les familles.

Je trouve que ces changements sont plutôt positifs, même si certains habitants pensent que la ville a perdu une partie de son calme. Personnellement, je préfère qu’il y ait plus d’activités, car cela permet aux jeunes de sortir davantage sans devoir aller dans une autre ville.

Il reste cependant plusieurs problèmes, notamment la circulation et le manque de places de stationnement. J’espère que la mairie trouvera des solutions dans les prochaines années.

À bientôt.
```

Le français est plutôt **B1/B2**, mais la consigne sur la fête est pratiquement ignorée.

Envoie-moi le résultat.

---

## Utilisateur

- B1 : 59 %
- B2 : 34 %
- INSUFFICIENT : 5 %
- Confidence : 46 %

## Assistant

Là, on apprend quelque chose d’important : **JEV semble surtout évaluer le niveau linguistique démontré**, et beaucoup moins sanctionner le hors-sujet.

**B1 59 % / B2 34 %** est logique si on regarde uniquement la langue. Mais pour le TCF, je pense qu’on devra probablement séparer deux décisions :

```text
Niveau linguistique : B1
Respect / accomplissement de la consigne : insuffisant
```

Plutôt que de faire baisser artificiellement le CECRL à cause du hors-sujet.

### Test 13 — production réellement insuffisante

On va maintenant voir dans quel cas il utilise vraiment `INSUFFICIENT`.

```text
Salut Marie,

Samedi fête dans ma ville. Moi aller avec ami. Beaucoup personne et musique. C'était bien. Nous manger et après concert. Moi content parce que musique très bien.

Après beaucoup monde et moi fatigué. Nous rentrer maison. La fête bien et je veux encore aller prochaine année.

À bientôt.
```

Ici, il y a un message compréhensible, mais **très peu de maîtrise grammaticale et trop peu d’éléments pour démontrer correctement A2**.

Je veux surtout voir s’il répond **A2** ou s’il commence enfin à utiliser **INSUFFICIENT**.

---

## Utilisateur

- A2 : 99 %
- B1 : 1 %
- INSUFFICIENT : 0 %
- Confidence : 98 %

## Assistant

Là, on vient de trouver un **vrai problème dans notre protocole**, pas forcément chez JEV.

Ce texte est plutôt **A1 / A1+**, pas A2. Mais on ne lui propose que :

`A2 / B1 / B2 / INSUFFICIENT`

Donc JEV est quasiment obligé de choisir **A2**, car `INSUFFICIENT` signifie actuellement « pas assez de matière », pas « niveau inférieur à A2 ».

Je modifierais donc immédiatement les choix en ajoutant :

```json
"A1": {
  "description": "La production démontre principalement un niveau A1.",
  "communication": "Le candidat transmet quelques informations très simples et isolées.",
  "phrases": "Les énoncés sont très simples, souvent incomplets ou peu structurés.",
  "grammaire": "La maîtrise grammaticale est très limitée et les erreurs sont nombreuses.",
  "vocabulaire": "Le vocabulaire est très élémentaire et répétitif.",
  "coherence": "Les idées sont juxtaposées avec très peu de liens.",
  "developpement": "Le candidat peut donner quelques informations simples mais développe difficilement son message."
}
```

Et conserver `INSUFFICIENT` uniquement pour : texte vide, quelques mots, langue impossible à évaluer, etc.

C’est important, parce que sinon dans SejourFR un candidat **A1 sera artificiellement remonté en A2**.

Après cette modification, je te propose de **repasser exactement ce même texte**. C’est le meilleur test suivant : on saura immédiatement si JEV le replace correctement en A1.

---

## Utilisateur

j'ai changé et soumis, la même chose :

- A2 : 60 %
- A1 : 40 %
- INSUFFICIENT : 0 %
- Confidence : 49 %

## Assistant

Oui, et en réalité ce résultat est **beaucoup plus intéressant** que le précédent.

Avant : **A2 99 %**  
Après ajout de A1 : **A2 60 % / A1 40 % / confiance 49 %**

Donc JEV reconnaît maintenant que le texte est **à la frontière A1/A2**. C’est plutôt cohérent : malgré les grosses erreurs, le candidat raconte quand même une petite suite d’événements, exprime un ressenti et une intention.

Le prochain test doit être un **A1 évident**, pour vérifier qu’il sait vraiment utiliser cette catégorie.

```text
Salut Marie,

Moi samedi fête ville. Avec mon ami. Beaucoup musique. J'aime musique.

Nous manger pizza. Après concert. Beaucoup personnes. C'est bien.

Moi très content. Après maison.

À bientôt.
```

Là, j’attendrais **A1 très largement devant A2**. Donne-moi le résultat.

---

## Utilisateur

- A1 : 83 %
- A2 : 17 %
- B1 : 0 %
- Confidence : 78 %

## Assistant

Très bon signal : **A1 83 % / A2 17 %**, avec **78 % de confiance**.

Ça montre que l’ajout de `A1` était nécessaire. Maintenant JEV sait distinguer :
A1 très simple, A1/A2 frontière, A2, B1, B2, et production non évaluable.

### Test suivant — vrai `INSUFFICIENT`

Je veux maintenant vérifier si cette catégorie sert vraiment.

```text
Salut,

Fête samedi. Bien. Musique. Amis.

À bientôt.
```

Ici, il y a **trop peu de matière** pour estimer sérieusement un niveau.

J’attendrais cette fois **INSUFFICIENT largement devant A1**.

Envoie-moi le résultat.

---

## Utilisateur

- A1 : 60 %
- INSUFFICIENT : 40 %
- A2 : 0 %
- Confidence : 49 %

## Assistant

Là, c’est intéressant : **JEV hésite vraiment entre A1 et INSUFFICIENT**, avec seulement **49 % de confiance**.

Ça me paraît logique : il y a quand même quelques éléments linguistiques, donc il peut défendre A1, mais pas assez pour être sûr.

### Test suivant — insuffisant beaucoup plus net

```text
Salut Marie,

Fête bien.

À bientôt.
```

Ici, j’attends cette fois **INSUFFICIENT devant A1**.

Donne-moi le résultat et on continue.

---

## Utilisateur

- INSUFFICIENT : 92 %
- A1 : 8 %
- B2 : 0 %
- Confidence : 89 %

## Assistant

Oui, là `INSUFFICIENT` fonctionne comme prévu.

**INSUFFICIENT 92 % / confiance 89 %** : très bon signe. JEV semble maintenant distinguer :
A1 réel, A1/A2 frontière, A2, B1, B2, et production non évaluable.

### Test suivant — B2 avec fautes assez nombreuses

On pousse maintenant un cas plus difficile : **bonne capacité d’argumentation, mais beaucoup d’erreurs grammaticales**.

```text
Salut Marie,

Samedi je suis allé à la fête de la ville et j’ai trouvé que l’événement était très intéressant, même si l’organisation n’était pas toujours très bien.

Ce que j’ai apprécié surtout, c’est que plusieurs associations étaient présentes. Elles présentaient leurs activités et ça permettait aux habitants de découvrir des choses qu’ils connaissent pas toujours. À mon avis, c’est important parce qu’une ville ne doit pas seulement organiser des événements pour divertir les gens, mais aussi pour créer des relations entre eux.

Par contre, il y avait trop des personnes dans certaines rues et c’était difficile de circuler. Je pense que la mairie aurait pu prévoir plus des espaces ou organiser les activités dans plusieurs endroits, afin que tout le monde peut profiter mieux.

Malgré les problèmes, je considère que cette fête était une réussite. Si la ville améliore l’organisation, ça pourrait devenir un événement vraiment important pour les habitants.
```

Ici, je vise **B2 ou B1/B2 frontière** : le niveau de pensée et de développement est élevé, mais la langue reste imparfaite.

Donne-moi le résultat.

---

## Utilisateur

- B1 : 69 %
- B2 : 31 %
- INSUFFICIENT : 0 %
- Confidence : 61 %

## Assistant

Là, c’est un résultat très utile.

**B1 69 % / B2 31 %** montre que JEV pénalise assez fortement les erreurs grammaticales, même quand le candidat sait développer, nuancer et argumenter.

Je voudrais maintenant isoler **uniquement l’effet des fautes**. On garde presque exactement le même texte, mais on corrige la langue.

### Test suivant — même capacité, grammaire stabilisée

```text
Salut Marie,

Samedi, je suis allé à la fête de la ville et j’ai trouvé que l’événement était très intéressant, même si l’organisation n’était pas toujours parfaite.

Ce que j’ai surtout apprécié, c’est que plusieurs associations étaient présentes. Elles présentaient leurs activités et cela permettait aux habitants de découvrir des initiatives qu’ils ne connaissent pas toujours. À mon avis, c’est important parce qu’une ville ne doit pas seulement organiser des événements pour divertir les gens, mais aussi pour créer des liens entre eux.

Par contre, il y avait trop de personnes dans certaines rues et il était difficile de circuler. Je pense que la mairie aurait pu prévoir davantage d’espace ou organiser les activités dans plusieurs endroits afin que tout le monde puisse mieux en profiter.

Malgré ces problèmes, je considère que cette fête était une réussite. Si la ville améliore encore l’organisation, cela pourrait devenir un événement vraiment important pour les habitants.
```

Si celui-ci passe franchement **B2**, on aura une information importante : chez JEV, la **maîtrise grammaticale pèse beaucoup dans la frontière B1/B2**.

Donne-moi le résultat.

---

## Utilisateur

- B2 : 75 %
- B1 : 25 %
- A1 : 0 %
- Confidence : 68 %

## Assistant

Oui, là on a une information assez claire.

Le **même fond** est passé de :

**avec erreurs → B1 69 % / B2 31 %**  
**langue corrigée → B2 75 % / B1 25 %**

Donc JEV accorde visiblement **un poids important à la maîtrise grammaticale** pour franchir B1 → B2. Ça me paraît cohérent avec le CECRL, mais on devra vérifier qu’il ne devient pas trop sévère pour le TCF.

### Test suivant — B2 avec vocabulaire très simple

Je veux isoler maintenant le vocabulaire : bonne maîtrise, raisonnement développé, mais aucun mot particulièrement recherché.

```text
Salut Marie,

Samedi, je suis allé à la fête de ma ville et j’ai passé une bonne soirée. Ce que j’ai aimé, c’est qu’il y avait des activités pour des personnes très différentes. Les enfants pouvaient jouer pendant que les adultes regardaient les concerts ou discutaient avec les associations.

Je trouve que ce genre de fête est utile parce que les habitants ont rarement l’occasion de se rencontrer. On vit parfois dans la même rue sans vraiment connaître les autres. Une fête comme celle-ci peut donc aider les gens à parler ensemble et à créer de nouvelles relations.

Il y avait quand même un problème : à certains moments, il y avait tellement de monde qu’il devenait difficile de circuler. À la place de la mairie, j’aurais organisé les activités dans plusieurs endroits.

Malgré cela, j’aimerais que cette fête soit organisée chaque année, car elle apporte quelque chose de positif à la ville.
```

Ici, **vocabulaire volontairement courant**, mais bonnes structures, argumentation, hypothèse et nuance.

Je veux voir si JEV reconnaît quand même le **B2**, ou s’il exige un vocabulaire plus sophistiqué.

---

## Utilisateur

- B2 : 56 %
- B1 : 44 %
- A1 : 0 %
- Confidence : 44 %

## Assistant

Oui, celui-là est très instructif aussi.

**B2 56 % / B1 44 % / confiance 44 %** montre que JEV reconnaît bien le potentiel B2, mais qu’un vocabulaire très courant le rend beaucoup moins certain.

Donc, jusqu’ici, on voit quelque chose d’assez cohérent : pour passer franchement en **B2**, JEV semble attendre à la fois **développement + structures variées + grammaire assez stable + vocabulaire suffisamment riche**.

### Test suivant — vocabulaire riche, mais structure faible

Je veux faire l’inverse : mettre des mots plus avancés, mais une organisation et une maîtrise qui restent plutôt B1.

```text
Salut Marie,

Samedi dernier, j’ai participé à la fête de la ville. L’événement était vraiment dynamique et l’atmosphère était particulièrement conviviale.

Il y avait énormément d’animations intéressantes. Les concerts étaient remarquables et les stands étaient très variés. J’ai aussi trouvé l’organisation assez impressionnante.

Cependant, il y avait beaucoup de monde. C’était parfois compliqué. Les gens attendaient longtemps. Certains endroits étaient difficiles pour passer.

Je pense que cette manifestation est bénéfique pour la ville. Elle permet de créer une certaine cohésion entre les habitants. Personnellement, j’aimerais y retourner l’année prochaine parce que l’expérience était globalement très positive.
```

Ici, j’attends plutôt **B1**, malgré des mots comme `conviviale`, `remarquable`, `manifestation`, `cohésion`.

Envoie-moi le résultat.

---

## Utilisateur

- B1 : 51 %
- B2 : 49 %
- INSUFFICIENT : 0 %
- Confidence : 38 %

## Assistant

Là, c’est **très intéressant** : JEV est quasiment à égalité **B1 51 % / B2 49 %**, avec seulement **38 % de confiance**.

Donc le vocabulaire plus riche semble vraiment **tirer fortement vers B2**, même si la construction du texte reste assez simple. Ça mérite d’être testé une deuxième fois avant d’en tirer une conclusion.

### Test suivant — vocabulaire riche, mais candidat clairement limité dans la construction

```text
Salut Marie,

Samedi, j’ai participé à la fête de ma ville. L’ambiance était conviviale et les activités étaient vraiment diversifiées. Il y avait des animations culturelles, des concerts et plusieurs associations.

Personnellement, j’ai beaucoup apprécié les concerts. C’était remarquable. Les musiciens étaient talentueux. Le public était enthousiaste.

Par contre, l’organisation avait des difficultés. Beaucoup de monde. Des longues attentes. Pas facile de circuler dans certaines rues. À mon avis, il faut améliorer ça.

Cette manifestation est quand même bénéfique pour la ville parce que ça crée de la convivialité entre les habitants. Je souhaite participer encore l’année prochaine.
```

Ici, il y a des mots comme **conviviale, diversifiées, culturelles, remarquable, enthousiaste, manifestation, bénéfique**, mais la syntaxe, le développement et l’enchaînement restent assez limités.

👉 Moi, je viserais **B1 plus nettement**. Donne-moi son résultat.

---

## Utilisateur

- B1 : 78 %
- B2 : 17 %
- A2 : 5 %
- Confidence : 73 %

## Assistant

Oui, là c’est rassurant : **B1 78 % / B2 17 %**. Donc quelques mots sophistiqués ne suffisent pas à tromper JEV lorsque la syntaxe et le développement restent limités.

On teste maintenant quelque chose d’important pour de vrais candidats : **beaucoup de fautes d’orthographe, mais un niveau B1 réel**.

### Test suivant — B1 avec orthographe faible

```text
Salut Marie,

Samedi dernier je suis aller à la fête de ma ville avec deux amis. Au debut je pensais que sa allait être une petite fête, mais finalement il y avait beaucoup de monde et plusieurs activité.

On a d'abord regarder un concert et ensuite nous sommes aller manger. J'ai particulierement aimé l'ambiance parce que les gens étaient souriant et tout le monde participait.

Par contre, il y avait un problème avec l'organisation. Certaines rues étaient trop remplie et c'était difficile de circuler. Je pense que la mairie devrait prévoir plus d'espace l'année prochaine pour que les visiteurs peuvent se déplacer plus facilement.

Malgrès ces problèmes, j'ai passé une très bonne soirée et j'aimerais revenir l'année prochaine avec ma famille.
```

Je vise **B1**, malgré les fautes (`aller`, `sa`, accords, orthographe…). Le candidat sait raconter, justifier, opposer et proposer une amélioration.

👉 Donne-moi le résultat JEV.

---

## Utilisateur

- B1 : 79 %
- A2 : 20 %
- B2 : 1 %
- Confidence : 73 %

## Assistant

Très bon signe encore : **B1 79 % malgré beaucoup de fautes d’orthographe**. JEV semble donc bien distinguer orthographe imparfaite et niveau global.

### Test suivant — candidat qui utilise des phrases “apprises par cœur”

C’est très réaliste au TCF : certains candidats mémorisent des connecteurs et des tournures qui donnent une impression de niveau élevé, alors que le reste reste assez simple.

```text
Salut Marie,

Je voudrais te raconter la fête de ma ville. Tout d’abord, il est important de souligner que cette fête était très intéressante et qu’il y avait beaucoup de personnes.

Premièrement, j’ai regardé un concert avec mes amis. La musique était très bien et nous avons beaucoup aimé. Deuxièmement, nous avons mangé dans un stand parce que nous avions faim. Après, nous avons marché un peu dans la ville.

D’un côté, j’ai aimé l’ambiance car les gens étaient contents. D’un autre côté, il y avait trop de monde et c’était difficile de marcher.

En conclusion, je peux dire que cette fête était une expérience enrichissante et inoubliable. J’aimerais revenir l’année prochaine parce que j’ai passé un bon moment.
```

Je vise **B1**, pas B2 : les expressions comme *« il est important de souligner »*, *« d’un côté… d’un autre côté »*, *« expérience enrichissante »* semblent avancées, mais le contenu et les structures réelles restent assez simples.

Donne-moi le résultat JEV.

---

## Utilisateur

- B1 : 66 %
- A2 : 29 %
- B2 : 5 %
- Confidence : 57 %

## Assistant

Oui, c’est plutôt rassurant : **B1 66 %**, seulement **B2 5 %**. JEV ne s’est pas vraiment laissé tromper par les expressions apprises par cœur.

### Test suivant — A2 avec phrases “préfabriquées” de niveau élevé

Cas très réaliste : le candidat a mémorisé une introduction et une conclusion, mais son français réel reste A2.

```text
Salut Marie,

Tout d’abord, il est important de souligner que la fête de ma ville était une expérience très intéressante.

Samedi je suis allé avec mon frère. Il y avait beaucoup de personne et beaucoup musique. Nous avons manger pizza et après nous regardons un concert. J’aime le concert parce que les chansons était bien.

Après nous sommes allé voir les jeux. Moi je joue pas parce que j’étais fatigué. Il y avait trop de monde aussi et c’était difficile pour marcher.

En conclusion, malgré certains inconvénients, cette expérience restera gravée dans ma mémoire.

Je veux retourner l’année prochaine avec mes amis.
```

Ici, je vise **A2**, malgré les deux phrases très sophistiquées apprises par cœur.

C’est un test important : je veux voir si JEV regarde vraiment **l’ensemble de la production** plutôt que quelques formulations avancées.

---

## Utilisateur

- A2 : 81 %
- B1 : 18 %
- A1 : 1 %
- Confidence : 76 %

## Assistant

Très bon résultat : **A2 81 % / B1 18 %**. Donc JEV ne se laisse clairement pas tromper par deux phrases sophistiquées mémorisées. C’est un point très positif pour des candidats TCF réels.

### Test suivant — B2 réel, mais orthographe mauvaise

On veut maintenant isoler **l’orthographe** : contrairement au test précédent avec erreurs B1/B2, ici la syntaxe et le raisonnement restent solides.

```text
Salut Marie,

Samedi, je suis allé à la fête organisée par la ville et, dans l’ensemble, j’ai trouvé l’expérience vraiment interessante. Ce qui m’a surtout plu, c’est que l’événement ne proposait pas uniquement des concerts mais aussi des activités organisées par plusieurs associations.

Je trouve cette initiative importante parce qu’elle permet aux habitants de se rencontrer dans un autre contexte. On habite parfois dans le même quartier pendant plusieurs années sans vraiment connaitre les personnes qui vivent autour de nous. Ce genre d’événement peut donc contribuer à créer plus de liens entre les habitants.

Cependant, certains aspects auraient pu être mieux organisés. Il y avait tellement de monde dans certaines rues qu’il devenait difficile de circuler, surtout pour les familles avec des enfants. La mairie aurait peut être pu répartir les activités dans plusieurs endroits afin d’éviter ce problème.

Malgrés ces quelques défauts, je pense que l’événement mérite d’être renouvelé. Avec une meilleur organisation, il pourrait devenir un rendez-vous important pour la ville.
```

Ici, il y a volontairement des fautes : `interessante`, `connaitre`, `peut être`, `Malgrés`, `une meilleur organisation`…

Mais les **structures, le développement, la nuance et l’argumentation sont B2**.

👉 J’attendrais donc **B2 devant B1**. S’il tombe fortement en B1, on saura que JEV donne peut-être trop de poids à l’orthographe.

---

## Utilisateur

- B2 : 78 %
- B1 : 22 %
- INSUFFICIENT : 0 %
- Confidence : 72 %

## Assistant

Oui, très bon signal : **B2 78 % malgré les fautes d’orthographe**. Donc l’orthographe seule ne semble pas faire chuter artificiellement le niveau. JEV regarde bien davantage la construction, le développement et la capacité à argumenter.

### Test suivant — bon raisonnement, mais vocabulaire répétitif

Je veux voir maintenant jusqu’où un **vocabulaire peu varié** peut empêcher le B2.

```text
Salut Marie,

Samedi je suis allé à la fête de ma ville et j’ai trouvé que c’était une bonne fête. Il y avait beaucoup de choses à faire et beaucoup de personnes étaient venues.

Ce que j’ai trouvé bien, c’est que les activités étaient faites pour différentes personnes. Les enfants avaient des jeux, les jeunes avaient des concerts et les adultes pouvaient aussi discuter avec les associations. Je pense que c’est une bonne chose parce que les gens de la ville peuvent se rencontrer et faire des choses ensemble.

Mais il y avait aussi des choses moins bien. Il y avait vraiment beaucoup de monde et dans certaines rues c’était difficile de passer. Je pense que la ville pourrait faire les activités dans plusieurs endroits pour avoir moins de personnes au même endroit.

Même si tout n’était pas parfait, je trouve que cette fête est une bonne chose pour la ville et qu’il faut continuer à l’organiser.
```

Le raisonnement est assez développé : comparaison, problème → solution, concession, justification. Mais le candidat répète énormément **« bien », « chose », « personnes », « ville »**.

Je viserais **B1 fort / B2 possible**, pas un B2 net.

Donne-moi le résultat.

---

## Utilisateur

- B1 : 74 %
- A2 : 19 %
- B2 : 7 %
- Confidence : 67 %

## Assistant

Oui, là JEV sanctionne clairement le **manque de variété lexicale** : **B1 74 %**, alors que le raisonnement était plutôt développé. Ça me paraît cohérent.

### Test suivant — bon niveau de langue, mais texte mal organisé

Cas réaliste : candidat qui sait faire des phrases assez avancées, mais qui organise mal ses idées.

```text
Salut Marie,

Samedi je suis allé à la fête de la ville. J’ai beaucoup aimé le concert parce que le groupe était vraiment bon, même si au début je ne voulais pas rester longtemps.

Il y avait aussi plusieurs associations. D’ailleurs, je pense que ce genre d’événement est important pour les habitants, parce qu’on ne connaît pas toujours les personnes qui vivent près de chez nous. Après le concert, nous avons mangé quelque chose, mais il y avait énormément de monde.

Ce qui était dommage, c’est que certaines rues étaient presque bloquées. J’ai rencontré un ancien collègue que je n’avais pas vu depuis plusieurs années, donc finalement nous sommes restés plus longtemps que prévu.

À mon avis, la mairie devrait mieux répartir les activités. La fête était quand même réussie et j’aimerais revenir, surtout parce que l’ambiance était agréable et que ça change des soirées habituelles.
```

Ici, la langue est assez bonne, avec plusieurs structures intéressantes, mais **l’organisation est un peu dispersée** et les idées s’enchaînent moins proprement.

Je viserais **B1 fort / B2 possible**, avec hésitation.

Donne-moi le résultat.

---

## Utilisateur

- B1 : 64 %
- B2 : 35 %
- A2 : 1 %
- Confidence : 56 %

## Assistant

Oui, **B1 64 % / B2 35 % / confiance 56 %**, ça colle bien : JEV voit les capacités supérieures, mais l’organisation imparfaite l’empêche de basculer franchement B2.

### Test suivant — temps verbaux variés, mais niveau réel encore limité

Je veux voir s’il se fait impressionner par l’imparfait, le futur et quelques relatives alors que l’ensemble reste plutôt simple.

```text
Salut Marie,

Samedi je suis allé à la fête de ma ville. Quand j’étais petit, j’allais souvent à cette fête avec mes parents, donc je voulais voir si elle avait changé.

Cette année il y avait plus de choses. J’ai regardé un concert avec mon frère et après nous avons mangé. Le groupe qui jouait était bien mais il y avait trop de monde devant la scène.

J’ai aimé aussi les jeux parce que ça m’a rappelé quand j’étais jeune. Par contre, je trouve qu’il manque des endroits pour s’asseoir.

L’année prochaine, si je peux, je reviendrai avec mes amis. Je pense qu’on passera encore une bonne soirée.
```

Il utilise plusieurs temps et une relative (`qui jouait`), mais vocabulaire, développement et argumentation restent assez simples.

👉 Je viserais **A2 fort / B1 débutant**, pas un B1 évident. Donne-moi le résultat.

---

## Utilisateur

- B1 : 63 %
- A2 : 35 %
- B2 : 2 %
- Confidence : 53 %

## Assistant

Oui, ici JEV monte assez vite vers **B1 (63 %)**. Ça suggère que la capacité à manier plusieurs temps et à faire une petite comparaison passé/présent pèse assez lourd, même avec un vocabulaire simple.

### Test suivant — plusieurs temps, mais maîtrise fragile

On garde le côté réaliste d’un candidat qui essaie d’utiliser imparfait/futur, mais sans vraie maîtrise.

```text
Salut Marie,

Samedi je suis allé à la fête de ma ville. Quand j’étais petit je vais souvent avec mes parents et j’aimais beaucoup les jeux.

Cette année je suis allé avec mon ami. Nous avons regarder un concert et après on mange des sandwichs. Il y avait beaucoup de monde mais c’était bien.

J’ai aimé parce que la musique était sympa. Par contre il y avait pas beaucoup de place pour rester assis et nous étions fatigué.

L’année prochaine je vais revenir si je peux. Peut-être je viendrai avec ma famille parce que mes enfants va aimer aussi.
```

Ici, je vise plutôt **A2**, éventuellement avec une part de B1 : il essaie plusieurs temps, mais les structures restent simples et leur maîtrise est instable.

Donne-moi le résultat.

---

## Utilisateur

- A2 : 86 %
- B1 : 13 %
- A1 : 1 %
- Confidence : 81 %

## Assistant

Oui, **A2 86 % / confiance 81 %** est très bon. Ça confirme que JEV ne compte pas simplement les temps verbaux utilisés : il regarde s’ils sont réellement maîtrisés.

### Test suivant — B2 naturel, sans style “dissertation”

Je veux vérifier qu’il reconnaît un bon niveau même quand le candidat écrit spontanément, sans `premièrement`, `cependant`, `en conclusion`, etc.

```text
Salut Marie,

Je suis allé à la fête samedi et franchement, je ne pensais pas rester aussi longtemps. J’y suis allé surtout pour retrouver quelques amis, mais finalement il y avait pas mal de choses intéressantes.

J’ai beaucoup aimé le fait qu’ils aient invité des associations du quartier. Ça changeait un peu des fêtes où on trouve seulement de la musique et de la nourriture. J’ai discuté avec des bénévoles qui organisent des activités pour les jeunes et je ne savais même pas que ça existait près de chez moi.

Le seul problème, c’était la foule. À certains moments, on ne pouvait presque plus avancer et, avec des enfants, ça devait être encore plus compliqué. Ils pourraient peut-être répartir les activités dans plusieurs rues la prochaine fois.

En tout cas, j’y retournerais volontiers. Ça m’a donné une autre image de ma ville et j’ai vraiment passé une bonne soirée.
```

Ici je vise **B2**, mais un B2 naturel, pas académique. S’il le met B1 simplement parce qu’il n’y a pas de gros connecteurs ou de vocabulaire recherché, ce sera intéressant à noter.

Donne-moi le résultat.

---

## Utilisateur

- B1 : 55 %
- B2 : 45 %
- INSUFFICIENT : 0 %
- Confidence : 44 %

## Assistant

Là, on touche un point important : **JEV hésite beaucoup sur un B2 naturel**.

`B1 55 % / B2 45 % / confiance 44 %`

Il reconnaît clairement des capacités B2, mais semble demander **un peu plus de richesse ou de développement explicite** pour basculer. À surveiller, car au TCF un candidat B2 n’écrit pas forcément comme une dissertation.

### Test suivant — B2 naturel, mais plus clairement démontré

Toujours sans style scolaire :

```text
Salut Marie,

Je suis allé à la fête de la ville samedi et, pour une fois, je suis resté presque jusqu’à la fin. Au départ, j’y allais surtout parce que des amis m’avaient proposé de les rejoindre, mais finalement j’ai trouvé l’événement beaucoup plus intéressant que prévu.

Ce qui m’a plu, c’est qu’on pouvait vraiment choisir ce qu’on voulait faire. Certains restaient près des concerts alors que d’autres préféraient discuter avec les associations ou simplement se promener. J’ai notamment parlé avec une association qui aide les nouveaux habitants à mieux connaître la ville. Je trouve l’idée vraiment utile, surtout quand on vient d’arriver et qu’on ne connaît personne.

Il y avait quand même beaucoup trop de monde en début de soirée. À certains endroits, il fallait presque dix minutes pour avancer de quelques mètres. S’ils organisaient certaines activités dans d’autres quartiers, ce serait probablement plus agréable et ça permettrait aussi de faire découvrir d’autres endroits de la ville.

Malgré ça, j’ai vraiment apprécié la soirée. Je n’y serais sans doute pas allé tout seul, mais maintenant je pense que j’y retournerai volontiers l’année prochaine.
```

Ici, je vise **B2 plus clairement**, tout en restant naturel : hypothèse, nuance, opposition, conditionnel, recul personnel, développement — sans connecteurs artificiels de dissertation.

Donne-moi le résultat.

---

## Utilisateur

- B2 : 78 %
- B1 : 22 %
- INSUFFICIENT : 0 %
- Confidence : 73 %

## Assistant

Oui, là c’est rassurant : **B2 78 % / B1 22 %**. Donc JEV sait reconnaître un **B2 naturel**, sans exiger un style académique, à condition que les capacités B2 soient suffisamment présentes dans l’ensemble du texte.

### Test suivant — français très propre, mais niveau réellement B1

Je veux vérifier qu’un candidat qui fait **presque zéro faute** ne soit pas automatiquement poussé vers B2.

```text
Salut Marie,

Samedi, je suis allé à la fête de ma ville avec quelques amis. Nous sommes arrivés vers 18 heures et nous avons commencé par faire le tour des différents stands.

Ensuite, nous avons assisté à un concert sur la place principale. J’ai beaucoup aimé la musique parce que le groupe avait beaucoup d’énergie et que le public participait aussi.

Après le concert, nous avons mangé ensemble. Il y avait beaucoup de monde, alors nous avons dû attendre un peu, mais ce n’était pas vraiment un problème.

J’ai passé une très bonne soirée. J’aimerais revenir l’année prochaine parce que cette fête est une bonne occasion de sortir avec mes amis et de profiter de ma ville.
```

Ici, quasiment aucune faute, texte fluide et cohérent, mais **structures, vocabulaire et développement restent B1**.

👉 J’attends **B1 nettement devant B2**. Donne-moi son résultat.

---

## Utilisateur

- B1 : 72 %
- A2 : 22 %
- B2 : 6 %
- Confidence : 64 %

on s'arrête là ?, on a assez pour conclure non ?

## Assistant

Oui, on peut s’arrêter là. On a déjà assez de cas pour tirer une **conclusion exploratoire solide**.

Ce que les tests montrent :

- JEV distingue bien **A1 / A2 / B1 / B2**.
- Il gère plutôt bien les **cas frontières** avec des probabilités cohérentes.
- Il ne se laisse pas facilement tromper par :
  - la longueur du texte ;
  - quelques mots sophistiqués ;
  - des phrases apprises par cœur ;
  - beaucoup de fautes d’orthographe ;
  - l’utilisation de plusieurs temps verbaux.
- Il semble regarder réellement plusieurs dimensions : **grammaire, vocabulaire, développement, cohérence, structures et capacité à communiquer**.
- Les niveaux de confiance baissent justement quand on lui donne des productions ambiguës.
- `INSUFFICIENT` fonctionne, mais seulement quand il y a vraiment très peu de matière.

Le point le plus important qu’on a découvert : il fallait absolument ajouter **A1**. Sinon les productions faibles étaient artificiellement poussées vers A2.

Il y a quand même deux points à surveiller : JEV semble parfois assez exigeant pour faire passer un **B1 fort vers B2**, et il ne sanctionne pas énormément un **hors-sujet** lorsqu’il évalue le niveau linguistique. Pour moi, ce dernier point est plutôt une raison de séparer dans SejourFR :

```text
Niveau CECRL : B1

Accomplissement de la consigne : Partiel
```

plutôt que de mélanger les deux.

Donc ma conclusion actuelle : **JEV est suffisamment prometteur pour qu’on passe à l’étape suivante.** Je ne continuerais pas à fabriquer encore 30 textes artificiels.

La vraie validation maintenant serait de prendre, par exemple, **30 à 50 vraies productions anonymisées de candidats**, dont tu connais déjà le niveau estimé, et comparer :

```text
Niveau actuel SejourFR
vs
JEV
vs
évaluation humaine si disponible
```

C’est ce test-là qui permettra de décider si JEV doit **remplacer ton calcul backend, l’aider, ou simplement servir d’arbitre dans les cas douteux**.

---

## Utilisateur

je veux que tu me note toute cette conversation dans un .md.
tout, du début à la fin.
