/// Ce qui reste des règles d'affichage du diagnostic TCF 4 épreuves — **pures**.
///
/// 🛑 **Le PARCOURS du diagnostic complet est retiré des fronts depuis le
/// 2026-09-26** (décision du propriétaire) : plus d'écran des 4 sections, plus
/// d'écran de résultat, plus de route `/diagnostic-tcf` (elle redirige vers le
/// Plan). Les épreuves que le diagnostic rapide ne mesure pas se mesurent par
/// l'**examen blanc** que propose le Plan. Ne pas recréer ces écrans.
///
/// Ne subsistent ici que les libellés de priorité de l'écran de déblocage du
/// Plan (`plan_unlock_screen.dart`), qui relit un résultat de complet **déjà
/// obtenu**. Miroir de `web_sejoufr/lib/tcf-diagnostic.ts`. Aucun état
/// pédagogique n'est dérivé ici : le rang arrive servi.
library;

/// « Expression orale — Tâche 3 ». La tâche est nommée, jamais la compétence.
String prioriteIntitule(String epreuveLabel, String? taskCode) =>
    taskCode == null
        ? epreuveLabel
        : '$epreuveLabel — Tâche ${taskCode.substring(taskCode.length - 1)}';

/// Le ton d'une mention. `hot` = ce qui bloque le plus.
enum EpreuveMentionTone { ok, warn, hot }

typedef EpreuveMention = ({String label, EpreuveMentionTone tone});

/// La pastille d'une ligne du mini-plan : le rang 1 est le seul « Prioritaire ».
EpreuveMention prioritePastille(int rang) => rang == 1
    ? (label: 'Prioritaire', tone: EpreuveMentionTone.hot)
    : (label: 'À renforcer', tone: EpreuveMentionTone.warn);
