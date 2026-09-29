package com.sejourfr.app.util;

import java.time.Instant;
import java.time.LocalTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;

/**
 * Plages horaires <b>UTC</b> declarees en configuration, format
 * {@code "01:00-04:00,06:00-10:00"}, bornes {@code [debut, fin[}.
 *
 * <p>Sert a resoudre les « heures pleines » d'un fournisseur de LLM au moment de
 * l'appel. Une plage qui enjambe minuit ({@code "22:00-02:00"}) est admise et
 * lue comme deux morceaux — aucun fournisseur ne la publie aujourd'hui, mais la
 * refuser ferait echouer un reglage parfaitement legitime.
 *
 * <p>Une entree illisible est <b>ignoree</b>, jamais fatale : cette valeur ne
 * decide que d'un montant estime persiste a titre d'analyse. La faire echouer au
 * boot punirait le candidat pour une virgule mal placee dans un {@code .env}.
 */
public final class PlagesHorairesUtc {

    private final List<LocalTime[]> plages;

    private PlagesHorairesUtc(List<LocalTime[]> plages) {
        this.plages = plages;
    }

    public static PlagesHorairesUtc parse(String declaration) {
        List<LocalTime[]> out = new ArrayList<>();
        if (declaration != null && !declaration.isBlank()) {
            for (String morceau : declaration.split(",")) {
                String plage = morceau.strip();
                if (plage.isEmpty()) continue;
                int tiret = plage.indexOf('-');
                if (tiret <= 0) continue;
                try {
                    LocalTime debut = LocalTime.parse(plage.substring(0, tiret).strip());
                    LocalTime fin = LocalTime.parse(plage.substring(tiret + 1).strip());
                    if (debut.equals(fin)) continue;
                    out.add(new LocalTime[] {debut, fin});
                } catch (RuntimeException ignore) {
                    // Reglage illisible : on ne facture pas d'heure pleine, on ne casse rien.
                }
            }
        }
        return new PlagesHorairesUtc(List.copyOf(out));
    }

    /** true si aucune plage n'est declaree — le fournisseur facture pareil a toute heure. */
    public boolean vide() {
        return plages.isEmpty();
    }

    /** true si l'instant donne tombe dans l'une des plages, heure UTC. */
    public boolean contient(Instant instant) {
        if (plages.isEmpty() || instant == null) return false;
        LocalTime heure = instant.atZone(ZoneOffset.UTC).toLocalTime();
        for (LocalTime[] p : plages) {
            LocalTime debut = p[0];
            LocalTime fin = p[1];
            boolean dedans = debut.isBefore(fin)
                ? !heure.isBefore(debut) && heure.isBefore(fin)
                // plage a cheval sur minuit : [debut, 24:00[ U [00:00, fin[
                : !heure.isBefore(debut) || heure.isBefore(fin);
            if (dedans) return true;
        }
        return false;
    }
}
