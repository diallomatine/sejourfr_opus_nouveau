package com.sejourfr.app.enums;

/**
 * De quelle <b>nature</b> est l'axe d'un bloc de cycle.
 *
 * <p>🛑 <b>Un bloc est une unite d'organisation du parcours, et sa nature depend
 * du module</b> — c'est le seul endroit du moteur ou les deux modules divergent
 * structurellement :
 *
 * <ul>
 *   <li>{@link #EPREUVE} — TCF : CO, CE, EO, EE. Une valeur d'enum
 *       ({@code EpreuveType}), et l'ordre est {@code TcfDomainProfileDto.ORDRE},
 *       autorite unique et non configurable (D-9, D-20) ;</li>
 *   <li>{@link #THEMATIQUE} — civique : les 5 thematiques officielles. Une
 *       <b>donnee</b> de {@code themes}, pas une valeur d'enum, et l'ordre est
 *       {@code themes.display_order}.</li>
 * </ul>
 *
 * <p>🛑 <b>Pourquoi cet enum existe plutot qu'un branchement sur le module.</b>
 * Le moteur portait {@code EpreuveType} en 57 endroits. Chacun aurait du
 * apprendre a lire un theme <b>en plus</b>, et une occurrence manquee ne se
 * decouvre que trois phases plus tard. En nommant la NATURE de l'axe, le moteur
 * lit un {@code JourneyBlocRefDto} et ne sait plus de quel module il parle.
 */
public enum JourneyBlocKind {

    /** Une epreuve du TCF IRN. */
    EPREUVE,

    /** Une thematique officielle de l'examen civique. */
    THEMATIQUE
}
