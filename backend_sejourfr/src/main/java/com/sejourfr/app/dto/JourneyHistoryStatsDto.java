package com.sejourfr.app.dto;

/**
 * <b>« Tout ce que vous avez déjà travaillé »</b> — les trois compteurs de
 * l'en-tete de la page Progression.
 *
 * <h2>🛑 Deux compteurs sur TOUS les cycles, un seul sur les cycles clos</h2>
 * <p>{@link #competencesTravaillees()} et {@link #examensPasses()} comptent le
 * <b>cycle en cours compris</b>. C'est une decision de produit, pas une facilite
 * de calcul : le titre de l'ecran dit « tout ce que vous avez <b>deja</b>
 * travaille », pas « ce que vous avez travaille dans vos cycles clos ». Les
 * exclure aurait fait reculer un compteur au demarrage du cycle suivant, et
 * donne a un candidat en plein premier cycle un ecran qui lui dit « 0 » alors
 * qu'il vient de clore quatre competences.
 *
 * <p>{@link #cyclesTermines()}, lui, ne compte que ce qui est <b>ferme</b> :
 * c'est exactement {@code cycles.size()}, et le cycle en cours n'est pas
 * termine. Les deux lectures sont donc coherentes avec ce qu'elles nomment.
 *
 * <p>⚠️ Le cycle <b>EN ATTENTE</b> n'entre dans aucun des trois : il est
 * invisible du candidat (D-13) et ses etapes ne sont jamais executees, donc
 * jamais cloturees. Le compter n'ajouterait rien et exposerait un objet dont
 * l'existence ne se raconte pas.
 *
 * @param competencesTravaillees etapes {@code TRAIN_SKILL} <b>cloturees</b>,
 *                               tous cycles du module confondus, obsoletes
 *                               exclues.
 * @param examensPasses          etapes {@code SECTION_EXAM} <b>cloturees</b>,
 *                               meme perimetre. ⚠️ Ce n'est pas « tous les
 *                               examens passes par le candidat » : un examen
 *                               joue hors du plan ne clot une etape que si elle
 *                               etait debloquee (D-15). Ce compteur dit ce que
 *                               le <b>parcours</b> a valide.
 * @param cyclesTermines         cycles {@code HISTORISE} du module.
 */
public record JourneyHistoryStatsDto(
        int competencesTravaillees,
        int examensPasses,
        int cyclesTermines
) {}
