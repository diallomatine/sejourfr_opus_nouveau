package com.sejourfr.app.util;

import com.sejourfr.app.enums.SuiviPeriodPreset;

import java.time.LocalDate;

/**
 * Periode demandee a une console admin (Suivi, Activite, Productions IA) : un
 * preset <b>ou</b> une paire {@code from}/{@code to}, jamais les deux.
 * <b>Autorite unique</b> de cette lecture : les ecrans partagent la meme table
 * de presets ({@link SuiviPeriodPreset#window}) et les memes refus.
 *
 * @param preset {@code null} pour une periode personnalisee
 * @param window jours couverts, Europe/Paris
 */
public record PeriodeAdmin(SuiviPeriodPreset preset, FenetreMesure window) {

    /**
     * @param today aujourd'hui a Paris
     * @throws IllegalArgumentException (→ 400) preset inconnu, periode
     *         incoherente, ou preset fourni avec {@code from}/{@code to}
     */
    public static PeriodeAdmin resolve(String preset, String from, String to, LocalDate today) {
        boolean custom = !blank(from) || !blank(to);
        if (custom && !blank(preset)) {
            throw new IllegalArgumentException(
                    "Indiquez soit « preset », soit « from » et « to », pas les deux.");
        }
        if (custom) {
            return new PeriodeAdmin(null, FenetreMesure.resolve(from, to, 1));
        }
        SuiviPeriodPreset applied = blank(preset) ? SuiviPeriodPreset.TODAY : SuiviPeriodPreset.parse(preset);
        return new PeriodeAdmin(applied, applied.window(today));
    }

    /**
     * Comme {@link #resolve}, mais <b>rien demande = aucune borne</b> ({@code null})
     * au lieu d'« aujourd'hui » : la liste des productions IA et son encart
     * (DI-35, decision du proprietaire du 2026-10-07 : « Tout » par defaut).
     *
     * @throws IllegalArgumentException (→ 400) memes refus que {@link #resolve}
     */
    public static PeriodeAdmin resolveOuSansBorne(String preset, String from, String to, LocalDate today) {
        if (blank(preset) && blank(from) && blank(to)) return null;
        return resolve(preset, from, to, today);
    }

    private static boolean blank(String value) {
        return value == null || value.isBlank();
    }
}
