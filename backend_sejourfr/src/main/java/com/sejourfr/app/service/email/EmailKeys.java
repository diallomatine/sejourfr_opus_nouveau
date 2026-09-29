package com.sejourfr.app.service.email;

import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.enums.Module;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

/**
 * <b>Les cles anti-doublon</b>, construites (et relues) en un seul endroit.
 *
 * <p>Une cle dit « ce mail-la, pour ce fait-la, part une fois ». Elle est posee
 * par l'index unique partiel de V073 ; ce fichier n'en est que le format.
 */
public final class EmailKeys {

    private EmailKeys() {
    }

    public static String of(EmailType type, Object... parts) {
        StringBuilder sb = new StringBuilder(type.name());
        for (Object part : parts) {
            sb.append(':').append(part);
        }
        return sb.toString();
    }

    public static String welcome(UUID userId) {
        return of(EmailType.WELCOME, userId);
    }

    /** Une fois maximum PAR MODULE (complement B), quelle que soit la session. */
    public static String diagnosticPlanReady(UUID userId, Module module) {
        return of(EmailType.DIAGNOSTIC_PLAN_READY, userId, module);
    }

    public static String byReference(EmailType type, UUID referenceId) {
        return of(type, referenceId);
    }

    /** Episode d'inactivite : la date (Europe/Paris) qui l'a ouvert. */
    public static String episode(EmailType type, UUID userId, LocalDate date) {
        return of(type, userId, date);
    }

    /** Relit le module d'une cle {@code DIAGNOSTIC_PLAN_READY:{userId}:{module}}. */
    public static Optional<Module> moduleOf(String key) {
        if (key == null) return Optional.empty();
        int i = key.lastIndexOf(':');
        if (i < 0) return Optional.empty();
        try {
            return Optional.of(Module.valueOf(key.substring(i + 1)));
        } catch (IllegalArgumentException e) {
            return Optional.empty();
        }
    }
}
