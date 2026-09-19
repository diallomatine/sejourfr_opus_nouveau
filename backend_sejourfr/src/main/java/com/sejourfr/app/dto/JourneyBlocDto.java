package com.sejourfr.app.dto;

import com.sejourfr.app.enums.JourneyBlocStatus;

import java.util.List;

/**
 * <b>Un bloc du cycle : une epreuve.</b>
 *
 * <p>🛑 <b>Le bloc n'est pas une table</b> (D-12) : c'est la lecture par
 * epreuve des etapes du cycle. {@code journey_step.position} reste
 * <b>monotone et globale</b>, jamais renumerotee — le groupement est une
 * lecture, il ne reecrit pas la file.
 *
 * <p>🛑 <b>Toujours QUATRE blocs, dans l'ordre {@code TcfDomainProfileDto#ORDRE}
 * (CO, CE, EO, EE)</b> — autorite unique et <b>non configurable</b> (D-9, D-20).
 * Un bloc sans etape est servi quand meme : le candidat doit voir ses quatre
 * epreuves, pas celles que la file a deja peuplees.
 *
 * <p>🛑 <b>Des faits, pas des phrases</b> (B-11) : « 1 compétence restante · puis
 * examen » et « VERROUILLÉ » appartiennent aux fronts.
 *
 * <p>⚠️ <b>Une exception, depuis 2026-09-19 : le LIBELLE DU BLOC est servi</b>
 * ({@link JourneyBlocRefDto}). Il fallait choisir entre servir le libelle et
 * faire brancher chaque front sur le module pour choisir sa table de miroirs --
 * une epreuve TCF cote enum, une thematique civique cote donnee. Servir est la
 * doctrine du depot ; brancher l'aurait contournee. Les miroirs
 * ({@code lib/tcf-epreuves.ts} ⇄ {@code core/utils/tcf_epreuves.dart}) restent
 * pour leurs autres emplois.
 *
 * @param bloc                 le bloc, <b>servi</b> : sa nature (epreuve TCF ou
 *                             thematique civique), son code et son <b>libelle</b>.
 *                             C'est <b>lui</b> que le candidat lit partout (D-21,
 *                             transpose par D-47). 🛑 Le front affiche
 *                             {@code bloc.label} et ne branche <b>jamais</b> sur le
 *                             module -- un front qui branche finit par afficher
 *                             autre chose que son jumeau.
 * @param status               derive a la lecture, jamais persiste.
 * @param competencesRestantes etapes {@code TRAIN_SKILL} encore ouvertes dans ce
 *                             bloc. C'est ce nombre qui verrouille l'examen
 *                             (D-15) : tant qu'il n'est pas nul, l'examen du
 *                             bloc n'est pas passable <b>au sens du cycle</b>.
 * @param steps                les etapes d'entrainement du bloc, dans l'ordre
 *                             de la file, <b>obsoletes exclues</b>. L'examen
 *                             n'y figure pas : il est servi a part, parce que
 *                             l'ecran l'imbrique en fin de bloc et non dans la
 *                             liste.
 * @param exam                 l'examen du bloc — l'etape {@code SECTION_EXAM}
 *                             <b>ouverte</b> s'il y en a une, sinon la derniere
 *                             cloturee. {@code null} quand le bloc n'en porte
 *                             pas encore.
 */
public record JourneyBlocDto(
        JourneyBlocRefDto bloc,
        JourneyBlocStatus status,
        int competencesRestantes,
        List<JourneyStepDto> steps,
        JourneyStepDto exam
) {}
