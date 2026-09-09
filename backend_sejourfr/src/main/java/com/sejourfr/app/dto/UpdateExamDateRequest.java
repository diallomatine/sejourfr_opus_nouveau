package com.sejourfr.app.dto;

import java.time.LocalDate;

/**
 * Payload pour {@code PUT /api/me/exam-date}.
 *
 * <p>🛑 <b>Endpoint separe de {@code /target-path}, et il doit le rester.</b>
 * Loger la date dans la mise a jour de la demarche ferait effacer la date a
 * chaque changement de procedure — un effet de bord silencieux sur une donnee
 * que le candidat a saisie a la main. Ici, la seule facon d'effacer la date est
 * de le demander explicitement.
 *
 * <p>{@code examDate} vaut {@code null} pour effacer (« pas encore de date »),
 * ce qui est une reponse pleine et la plus frequente. La question est
 * facultative et ne bloque jamais le tunnel.
 */
public record UpdateExamDateRequest(
        LocalDate examDate
) {
}
