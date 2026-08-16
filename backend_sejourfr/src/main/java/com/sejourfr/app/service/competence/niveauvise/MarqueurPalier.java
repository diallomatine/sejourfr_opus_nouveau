package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.enums.TargetLevel;

import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

/**
 * LES PROCEDES OBSERVABLES qu'un texte modele doit REELLEMENT porter pour qu'on
 * ait le droit d'annoncer un palier — et le palier a partir duquel chacun
 * commence a prouver quelque chose.
 *
 * <h2>Pourquoi cette enum existe</h2>
 * Mesure faite en base sur un cas reel : le candidat a recopie tel quel le
 * {@code exemple_cible.texte} qu'on lui servait comme « version pour viser B2 »,
 * l'a resoumis, et le correcteur l'a reevalue <b>A2</b> — le texte modele
 * n'etait pas au niveau qu'il annonçait. Rien ne l'y obligeait : {@code texte}
 * etait une simple chaine bornee en caracteres, sans aucun controle serveur, et
 * la consigne tirait meme dans l'autre sens (« longueur PROCHE de la sienne »).
 *
 * <p>La reponse suit l'ordre de preference du depot — <b>la contrainte dure
 * avant la consigne</b> : le contrat v2 exige deux a trois
 * {@code marqueurs_du_palier}, chacun etant un passage <b>recopie du texte</b>
 * plus le procede qu'il illustre. Le modele ne peut donc plus <i>souhaiter</i>
 * le palier, il doit placer la matiere dans son texte puis la designer, et le
 * serveur verifie que le passage s'y trouve vraiment.
 *
 * <h2>Ce que « palier minimum » veut dire</h2>
 * C'est le palier a partir duquel le procede devient une preuve. Un marqueur
 * dont le palier minimum est <b>au-dessus</b> du palier cible sur-vend : viser
 * l'A2 ne se demontre pas en « traitant une objection ». Ce marqueur-la est
 * <b>retire</b> ({@link CompetenceNiveauViseMarqueurFilter}) — jamais refuse,
 * jamais payant : il ne coute que sa propre mise en evidence, exactement comme
 * un segment de surlignage introuvable.
 *
 * <p><b>Un marqueur AU-DESSOUS du palier cible reste valable</b> : un texte qui
 * vise le B1 peut parfaitement continuer d'ajuster son registre. On ne purge que
 * la sur-vente, dans le sens sûr.
 *
 * <p>La table est <b>miroir de la grille</b> ({@code commun.marqueurs_palier} des
 * rubriques v2) et {@link CompetenceNiveauViseRubricsProvider} <b>oppose les deux
 * au BOOT</b> : une divergence fait echouer le demarrage, jamais un repli muet.
 */
public enum MarqueurPalier {

    /**
     * Le salut, la formule de politesse et le ton conviennent au destinataire.
     * Attendu des l'A2, ou le CECRL demande deja des formules sociales de base.
     */
    REGISTRE_AJUSTE(TargetLevel.A2),

    /**
     * Les idees sont reliees et ordonnees. A2 tant qu'il s'agit de « et »,
     * « mais », « alors » ; c'est le procede, pas le mot, qui est classe ici.
     */
    ARTICULATION_LOGIQUE(TargetLevel.A2),

    /** Une subordonnee la ou l'A2 juxtaposerait (« bien que », « ce qui »). */
    SUBORDINATION(TargetLevel.B1),

    /** Un terme precis a la place d'un mot passe-partout. */
    LEXIQUE_PRECIS(TargetLevel.B1),

    /** Une position nuancee ou conditionnee (« a condition que », « meme si »). */
    NUANCE(TargetLevel.B2),

    /** Une objection annoncee puis traitee — la conduite d'argumentation du B2. */
    OBJECTION_TRAITEE(TargetLevel.B2);

    private final TargetLevel palierMinimum;

    MarqueurPalier(TargetLevel palierMinimum) {
        this.palierMinimum = palierMinimum;
    }

    /** Palier a partir duquel ce procede prouve quelque chose. */
    public TargetLevel palierMinimum() {
        return palierMinimum;
    }

    /**
     * Vrai quand ce procede peut legitimement demontrer le palier vise, c'est-a-dire
     * quand il ne le sur-vend pas.
     */
    public boolean demontre(TargetLevel palierCible) {
        return palierCible != null && palierMinimum.ordinal() <= palierCible.ordinal();
    }

    /** Le procede designe par ce code, insensible a la casse. Vide si inconnu. */
    public static Optional<MarqueurPalier> de(String code) {
        if (code == null || code.isBlank()) return Optional.empty();
        String normalise = code.trim().toUpperCase(Locale.ROOT);
        return Arrays.stream(values()).filter(m -> m.name().equals(normalise)).findFirst();
    }

    /** La table {@code code -> palier minimum}, dans l'ordre de declaration. */
    public static Map<String, String> table() {
        Map<String, String> out = new LinkedHashMap<>();
        for (MarqueurPalier marqueur : values()) {
            out.put(marqueur.name(), marqueur.palierMinimum.name());
        }
        return Map.copyOf(out);
    }
}
