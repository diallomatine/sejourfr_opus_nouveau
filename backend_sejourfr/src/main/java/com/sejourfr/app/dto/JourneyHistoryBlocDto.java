package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;

import java.util.List;

/**
 * <b>Ce qu'une epreuve a recu pendant un cycle ferme</b> : ses competences
 * travaillees, et ses examens.
 *
 * <p>🛑 <b>Un bloc sans competence cloturee n'est PAS servi</b> — et ce n'est pas
 * le meme contrat que {@code JourneyBlocDto}, qui sert <b>toujours</b> les quatre
 * epreuves parce qu'il decrit un plan <b>a faire</b>. Ici on raconte ce qui a
 * <b>ete fait</b> : afficher « Compréhension écrite — rien » dans un historique
 * n'apprend rien au candidat, et la maquette
 * ({@code docs/progression/histo_cycle.html}) ne montre que les epreuves
 * travaillees.
 *
 * <p>🛑 <b>Des faits, pas des phrases</b> (B-11) : « Compréhension orale » et
 * « CO · EE · EO » se composent dans les fronts, depuis {@link #examType()} et
 * les libelles miroirs ({@code lib/tcf-epreuves.ts} ⇄
 * {@code core/utils/tcf_epreuves.dart}).
 *
 * @param examType    l'epreuve du bloc. C'est <b>elle</b> que le candidat lit
 *                    partout (D-21).
 * @param skillTitles les titres des competences travaillees, <b>dans l'ordre de
 *                    la file</b> ({@code journey_step.position}). C'est
 *                    {@code skills.title}, un <b>fait editorial</b> deja servi
 *                    ailleurs ({@code JourneyStepDto.skillTitle}) : jamais
 *                    recopie sur l'etape, jamais recompose ici. ⚠️ En
 *                    comprehension, la competence <b>est le palier</b> (D-19) :
 *                    le titre servi est celui du palier, pas d'une
 *                    micro-competence.
 * @param examens     etapes {@code SECTION_EXAM} <b>cloturees</b> de cette
 *                    epreuve dans ce cycle.
 */
public record JourneyHistoryBlocDto(
        EpreuveType examType,
        List<String> skillTitles,
        int examens
) {}
