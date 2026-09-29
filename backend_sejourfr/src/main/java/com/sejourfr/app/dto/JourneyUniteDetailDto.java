package com.sejourfr.app.dto;

/**
 * <b>L'unite travaillable, en DETAIL</b> — ce que l'ecran d'etape affiche sous
 * son titre.
 *
 * <p>🛑 <b>Pourquoi un record a part, et pas trois champs de plus sur
 * {@link JourneyUniteRefDto}.</b> Celui-la est servi sur la file <b>entiere</b>
 * ({@code JourneyStepDto}) : lui ajouter une description la ferait voyager sur
 * toutes les etapes de tous les cycles, pour un seul ecran qui la lit. Les deux
 * records derivent du <b>meme</b> endroit — {@code skills} cote TCF,
 * {@code civic_official_units} cote civique —, il n'y a donc aucune seconde
 * autorite, seulement deux vues.
 *
 * @param code        l'identifiant stable — {@code CO-B2}, {@code P2_LAICITE}.
 *                    Une <b>cle</b>, jamais un affichage.
 * @param label       ce que le <b>candidat lit</b> — « Comprendre l'implicite »,
 *                    « La laicite ».
 * @param description la phrase d'explication affichee sous le titre
 *                    (« Comprendre ce qui est suggere, pas seulement ce qui est
 *                    dit. »). 🛑 <b>Nullable</b> : {@code skills.description}
 *                    peut etre vide, et une <b>unite officielle civique n'en
 *                    porte aucune</b> ({@code civic_official_units} n'a pas la
 *                    colonne). L'ecran n'affiche alors <b>rien</b> — jamais un
 *                    bloc vide, et surtout jamais une phrase fabriquee.
 */
public record JourneyUniteDetailDto(String code, String label, String description) {}
