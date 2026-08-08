package com.sejourfr.app.enums;

/**
 * Démarche administrative visée par le candidat, et — porté par l'enum
 * lui-même — le <b>palier de français qu'elle exige</b>.
 *
 * <p><b>C'est LA source de vérité de la correspondance démarche → niveau</b> :
 * {@code CSP → A2}, {@code CR → B1}, {@code NAT → B2}. Seuils en vigueur depuis
 * le 1ᵉʳ janvier 2026 (loi n° 2024-42, décrets 2025-647 et 2025-648, arrêté du
 * 22 décembre 2025). Référentiel légal de trois lignes : il vit dans l'enum, pas
 * dans une table ni dans une configuration — même parti pris que
 * {@code SkillTaskCode}. Les trois fronts en tiennent un miroir <b>gelé par un
 * test de chaque côté</b>.
 *
 * <p><b>Ne jamais réécrire cette table ailleurs.</b> Elle a existé en six copies
 * (deux services Java, trois écrans web, deux getters Dart) et c'est ainsi qu'un
 * candidat visant la naturalisation s'est retrouvé tiré vers le B1 : la
 * correspondance était juste partout, mais personne ne la confrontait au
 * {@code targetLevel} stocké.
 */
public enum TargetProcedure {

    /** Carte de séjour pluriannuelle. */
    CSP(TargetLevel.A2),

    /** Carte de résident. */
    CR(TargetLevel.B1),

    /** Naturalisation. */
    NAT(TargetLevel.B2);

    private final TargetLevel requiredTcfLevel;

    TargetProcedure(TargetLevel requiredTcfLevel) {
        this.requiredTcfLevel = requiredTcfLevel;
    }

    /** Le palier de français que cette démarche exige. Jamais null. */
    public TargetLevel getRequiredTcfLevel() {
        return requiredTcfLevel;
    }

    /**
     * Le palier réellement VISÉ par un candidat : le plus haut entre ce que sa
     * démarche exige et ce qu'il a déclaré viser.
     *
     * <p><b>La démarche fait plancher</b>, jamais plafond :
     * <ul>
     *   <li>{@code NAT} + {@code B1} déclaré ⇒ <b>B2</b>. Sa démarche en demande
     *       un de plus : le féliciter d'avoir « atteint son objectif » à B1
     *       reviendrait à ne jamais le tirer vers le niveau dont il a besoin ;</li>
     *   <li>{@code CSP} + {@code B2} déclaré ⇒ <b>B2</b>. Viser plus haut que sa
     *       démarche est un choix légitime, on le respecte ;</li>
     *   <li>démarche absente ⇒ le niveau déclaré, seul (candidat TCF sans
     *       démarche civique) ;</li>
     *   <li>les deux absents ⇒ {@code null}, et l'appelant décide de son repli.
     *       On ne devine <b>jamais</b> une démarche à la place du candidat.</li>
     * </ul>
     *
     * <p>Comparaison sur l'ordre CECRL (l'ordre de déclaration de
     * {@link TargetLevel}), pas sur l'ordre alphabétique — qui donnerait
     * {@code B1 > A2} par chance et {@code B1 < B2} par chance, jusqu'au jour où
     * un palier s'intercale.
     */
    public static TargetLevel niveauVise(TargetProcedure procedure, TargetLevel declare) {
        if (procedure == null) return declare;
        TargetLevel exige = procedure.requiredTcfLevel;
        if (declare == null) return exige;
        return declare.ordinal() > exige.ordinal() ? declare : exige;
    }
}
