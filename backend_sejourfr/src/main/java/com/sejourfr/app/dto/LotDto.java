package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Difficulty;

import java.time.Instant;
import java.util.UUID;

/**
 * Un "lot" est un chunk déterministe de questions filtrées par module,
 * épreuve (QuestionType) et niveau (Difficulty). Calculé à la volée par
 * {@code LotService} — pas de table dédiée. Le tri est stable
 * ({@code created_at ASC, id ASC}) donc Lot 1 = même série à chaque
 * appel tant que le pool ne change pas.
 *
 * <p>Taille par niveau (TCF) : A2 = 15, B1 = 20, B2 = 25.
 *
 * <p>Les champs `last*` sont remplis avec le dernier attempt fini du user
 * sur ce lot (null si jamais tenté) — sert au mobile pour différencier
 * visuellement les lots déjà faits avec leur score précédent.
 *
 * @param numero            numéro 1-indexé du lot dans le découpage
 * @param difficulty        niveau du lot (sert aussi à dériver sa taille)
 * @param totalQuestions    nombre de questions dans ce lot
 * @param lastScore         dernier score de l'utilisateur sur ce lot (null si jamais fait)
 * @param lastAttemptedAt   date du dernier attempt fini sur ce lot (null si jamais fait)
 * @param lastAttemptId     id du dernier attempt fini (null si jamais fait) — sert
 *                          au mobile pour ouvrir le bilan de lot sans re-lancer.
 */
public record LotDto(
        int numero,
        Difficulty difficulty,
        int totalQuestions,
        Integer lastScore,
        Instant lastAttemptedAt,
        UUID lastAttemptId
) {}
