package com.sejourfr.app.dto;

import com.sejourfr.app.enums.TargetLevel;

import java.time.Instant;
import java.util.List;

/**
 * <b>Un cycle ferme</b>, tel que la page Progression le montre.
 *
 * <p>🛑 <b>Des faits, pas des phrases</b> (B-11) : « 4–16 septembre »,
 * « Cycle 2 », « 6 compétences · 3 examens » et « A2 → B1 » se composent dans
 * les fronts.
 *
 * @param numero      le rang du cycle dans l'ordre chronologique de creation, le
 *                    premier valant {@code 1} — <b>la meme semantique</b> que
 *                    {@link JourneyCycleDto#numero()}, et la <b>meme regle</b> :
 *                    {@code JourneyCycleRank}. Deux lectures du meme nombre ne
 *                    peuvent donc pas diverger.
 * @param debut       {@code journey.created_at}.
 * @param fin         {@code journey.historise_at}. Jamais {@code null} sur un
 *                    cycle historise : {@code chk_journey_historisation} l'exige.
 * @param competences etapes {@code TRAIN_SKILL} <b>cloturees</b> du cycle,
 *                    obsoletes exclues. Une etape encore ouverte ne compte
 *                    jamais — on ne felicite pas un candidat pour du travail
 *                    qu'il n'a pas fait.
 * @param examens     etapes {@code SECTION_EXAM} <b>cloturees</b> du cycle, meme
 *                    regle. ⚠️ Ce nombre peut depasser la somme des
 *                    {@link JourneyHistoryBlocDto#examens()} : un bloc sans
 *                    aucune competence travaillee n'est pas servi (cf.
 *                    {@link JourneyHistoryBlocDto}), alors que son examen, lui,
 *                    a bien ete passe.
 * @param entryLevel  le niveau global au demarrage du cycle, <b>lu tel quel</b>
 *                    sur la ligne. 🛑 {@code null} = <b>inconnu, jamais
 *                    mauvais</b> — jamais « A2 par defaut », et jamais recalcule
 *                    retroactivement (D-12, A35) : c'est un fait date, que le
 *                    recalibrage du moteur du jour ne doit pas reinterpreter.
 * @param exitLevel   le niveau global <b>ecrit a l'historisation</b>, meme
 *                    regle. Reste {@code null} si rien n'avait ete mesure — ou
 *                    si le niveau mesure etait <b>sous l'A2</b>, que la colonne
 *                    ne sait pas dire (A35).
 * @param blocs       les competences travaillees <b>groupees par epreuve</b>,
 *                    dans l'ordre {@code TcfDomainProfileDto.ORDRE}.
 */
public record JourneyHistoryCycleDto(
        int numero,
        Instant debut,
        Instant fin,
        int competences,
        int examens,
        TargetLevel entryLevel,
        TargetLevel exitLevel,
        List<JourneyHistoryBlocDto> blocs
) {}
