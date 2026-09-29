package com.sejourfr.app.service.email.event;

import com.sejourfr.app.enums.Module;
import com.sejourfr.app.util.LogMask;

import java.util.UUID;

/**
 * Un diagnostic vient de rendre le Plan d'un module disponible POUR LA PREMIERE
 * FOIS (arbitrage n°7). Publie seulement dans ce cas : un complet qui affine un
 * Plan existant ne publie rien.
 *
 * @param diagnosticId la session close, dans sa table
 * @param adoption     vrai quand c'est l'ADOPTION d'un diagnostic civique
 *                     d'invite : aucun mail, mais la cle du module est consommee
 *                     (complement C)
 */
public record DiagnosticPlanReadyEvent(UUID userId, String email, Module module,
                                       UUID diagnosticId, boolean adoption) {

    @Override
    public String toString() {
        return "DiagnosticPlanReadyEvent[user=" + userId + ", email=" + LogMask.email(email)
                + ", module=" + module + ", adoption=" + adoption + "]";
    }
}
