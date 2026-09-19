package com.sejourfr.app.dto;

import com.sejourfr.app.enums.JourneyObjectifKind;

/**
 * <b>L'objectif d'un cycle, servi</b> — ce vers quoi le candidat travaille.
 *
 * <p>🛑 <b>Le patron du bloc servi</b> ({@link JourneyBlocRefDto}, D-47 / A47),
 * applique au dernier champ du contrat qui etait encore type TCF. Un cycle
 * civique ne pouvait pas s'exprimer dans un {@code TargetLevel} : son objectif
 * est une <b>mention</b>, et {@code chk_journey_objectif} (V069) exige
 * exactement un des deux.
 *
 * <p>🛑 <b>Le libelle est SERVI</b>, comme celui du bloc. Il est le mot du
 * livret, celui que les deux fronts affichent deja
 * ({@code MENTION_LABEL} / {@code mentionLabel}) : le servir garantit qu'une
 * mention et un palier s'affichent par le <b>meme chemin</b>.
 *
 * @param kind  la nature de l'objectif — elle choisit la tournure, jamais le
 *              module.
 * @param code  {@code A2} / {@code B1} / {@code B2}, ou {@code CSP} /
 *              {@code CR} / {@code NAT}.
 * @param label le mot du candidat : « B2 », « Naturalisation ».
 */
public record JourneyObjectifRefDto(
        JourneyObjectifKind kind,
        String code,
        String label
) {}
