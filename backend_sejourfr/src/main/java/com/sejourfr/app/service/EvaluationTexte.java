package com.sejourfr.app.service;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.regex.Pattern;

/**
 * Outillage TEXTE commun aux filets deterministes de restitution
 * ({@link EvaluationOralArtifactFilter}, {@link EvaluationPalierMarqueurFilter}) :
 * decoupage en phrases et normalisation pour la recherche de marqueurs.
 *
 * <p>Extrait a la DEUXIEME occurrence, comme le veut le depot : deux filets qui
 * purgent « la phrase, pas le champ » doivent decouper les phrases exactement de
 * la meme façon, sinon deux remarques identiques se purgent differemment selon le
 * filet qui les voit.
 *
 * <p><b>Classe rendue publique le 2026-08-14</b> pour une TROISIEME surface, le
 * volet oral du diagnostic ({@code service.diagnostic.DiagnosticOralArtifactFilter}),
 * qui purge lui aussi « la phrase, pas le champ » depuis un autre paquet. Seul
 * {@link #phrases(String)} est ouvert : le reste reste interne au paquet.
 */
public final class EvaluationTexte {

    /** Ponctuation forte : candidate a une fin de phrase. */
    private static final String PONCTUATION_FORTE = ".!?…";

    /** Apostrophes typographiques ou droites, ramenees a un blanc pour la detection. */
    private static final Pattern APOSTROPHES = Pattern.compile("['’‘]");

    private EvaluationTexte() {
    }

    /**
     * Decoupage en phrases sur la ponctuation forte, <b>hors citation et hors
     * parenthese</b>. Sans cette precaution, « Un passage en néerlandais ('Ja.
     * Dus kan nog sorteer de weekenden') qui interrompt... » — un verbatim REEL —
     * se coupait au point de « Ja. », la premiere moitie partait a la purge et le
     * candidat recevait le debris restant.
     */
    public static List<String> phrases(String texte) {
        List<String> out = new ArrayList<>();
        int debut = 0;
        int parentheses = 0;
        boolean dansGuillemetsFr = false;
        boolean dansGuillemetsDroits = false;
        boolean dansGuillemetsCourbes = false;
        for (int i = 0; i < texte.length(); i++) {
            char c = texte.charAt(i);
            switch (c) {
                case '(' -> parentheses++;
                case ')' -> parentheses = Math.max(0, parentheses - 1);
                case '«' -> dansGuillemetsFr = true;
                case '»' -> dansGuillemetsFr = false;
                case '"' -> dansGuillemetsDroits = !dansGuillemetsDroits;
                case '“' -> dansGuillemetsCourbes = true;
                case '”' -> dansGuillemetsCourbes = false;
                default -> {
                    // rien : seul un separateur ouvre ou ferme un contexte
                }
            }
            boolean protege = parentheses > 0 || dansGuillemetsFr
                || dansGuillemetsDroits || dansGuillemetsCourbes;
            if (protege || PONCTUATION_FORTE.indexOf(c) < 0) continue;
            int j = i + 1;
            while (j < texte.length() && PONCTUATION_FORTE.indexOf(texte.charAt(j)) >= 0) j++;
            if (j >= texte.length() || !Character.isWhitespace(texte.charAt(j))) continue;
            out.add(texte.substring(debut, j));
            while (j < texte.length() && Character.isWhitespace(texte.charAt(j))) j++;
            debut = j;
            i = j - 1;
        }
        if (debut < texte.length()) out.add(texte.substring(debut));
        return out;
    }

    /** Minuscules, accents retires, apostrophes ramenees a un blanc. */
    static String normaliserPourMarqueur(String text) {
        String sansAccents = Normalizer
            .normalize(APOSTROPHES.matcher(text).replaceAll(" "), Normalizer.Form.NFD)
            .replaceAll("\\p{M}+", "");
        return sansAccents.toLowerCase(Locale.FRENCH).replaceAll("\\s+", " ");
    }

    static String texte(Object raw) {
        return raw == null ? "" : raw.toString();
    }
}
