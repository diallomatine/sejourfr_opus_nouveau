package com.sejourfr.app.util;

import java.text.Normalizer;
import java.util.Arrays;
import java.util.Locale;
import java.util.Optional;

/**
 * LA NORMALISATION DE TEXTE DU DEPOT, en un seul endroit.
 *
 * <h2>Deux couches, jamais melangees</h2>
 * <ul>
 *   <li><b>TYPOGRAPHIQUE</b> ({@link #de(String)}) : NFKC, apostrophes courbes
 *       ramenees a l'apostrophe droite, espaces insecables et sauts de ligne
 *       ramenes a une espace simple, tirets longs ramenes au trait d'union,
 *       ligatures oe/ae developpees, caracteres invisibles retires, suites de
 *       blancs reduites a une seule. <b>Les accents et la casse sont
 *       CONSERVES</b> : on neutralise ce que le clavier et le copier-coller
 *       changent, pas ce que le candidat a ecrit ;</li>
 *   <li><b>MOT</b> ({@link #mot(String)}) : la forme utilisee par le
 *       rapprochement de preuve, qui ajoute minuscules et suppression des
 *       accents. Elle vivait dans {@code EvaluationProofMatcher} ; elle est ici
 *       AU BIT PRES, et le matcher l'appelle.</li>
 * </ul>
 *
 * <h2>Pourquoi la couche typographique existe</h2>
 * Un extrait a surligner doit se retrouver dans le texte qui l'affiche. Le
 * controle etait strictement litteral, et le terrain est piegeux : la production
 * porte des apostrophes courbes, le texte modele des apostrophes droites, et rien
 * ne garantit qu'un modele soit coherent entre son texte et son extrait. Un
 * extrait JUSTE etait alors declare introuvable, et la section entiere
 * disparaissait de l'ecran du candidat.
 *
 * <h2>L'invariant : on RESTITUE l'original</h2>
 * {@link #sousChaineOriginale(String)} ne rend jamais la forme normalisee mais la
 * <b>sous-chaine exacte du texte source</b> — meme technique que
 * {@code AiEvaluationService.resolvePreuveSegments} et que le passage canonique du
 * rapprochement de preuve. Le front recoit donc toujours un extrait qui existe
 * litteralement dans le texte qu'il affiche.
 *
 * <p><b>Aucun appariement flou.</b> On cherche une egalite APRES neutralisation
 * typographique, contigue, rien d'autre : ni tolerance d'edition, ni elision, ni
 * recherche approchee. Ces techniques-la restent chez
 * {@code EvaluationProofMatcher}, ou elles sont bordees par leurs propres
 * garde-fous.
 */
public final class TexteNormalise {

    /** Toutes les formes d'apostrophe ramenees a {@code '}. */
    private static final String APOSTROPHES =
        "’‘‚‛ʼʹ′´`";
    /** Tirets et signes moins ramenes a {@code -}. */
    private static final String TIRETS =
        "‐‑‒–—―−";
    /** Guillemets ramenes a {@code "}. */
    private static final String GUILLEMETS =
        "«»“”„‟″";
    /** Caracteres sans rendu visible, purement et simplement retires. */
    private static final String INVISIBLES =
        "­​‌‍‎‏﻿";
    /**
     * Blancs que {@code Character.isWhitespace} ne reconnait PAS : espace
     * insecable, insecable etroite, espace tabulaire, liant de mots. Ce sont
     * exactement ceux qu'un copier-coller depuis un traitement de texte seme dans
     * un texte français (avant un point d'interrogation, apres un guillemet
     * ouvrant).
     */
    private static final String BLANCS_INSECABLES = "   ⁠";

    private final String original;
    private final String normalise;
    /** Index, dans {@link #original}, du debut du caractere source de chaque position normalisee. */
    private final int[] debuts;
    /** Index, dans {@link #original}, de la fin (exclusive) de ce meme caractere source. */
    private final int[] fins;

    private TexteNormalise(String original, String normalise, int[] debuts, int[] fins) {
        this.original = original;
        this.normalise = normalise;
        this.debuts = debuts;
        this.fins = fins;
    }

    /** Prepare un texte pour y chercher des extraits. Jamais null. */
    public static TexteNormalise de(String texte) {
        String source = texte == null ? "" : texte;
        StringBuilder sb = new StringBuilder(source.length());
        int[] debuts = new int[Math.max(16, source.length())];
        int[] fins = new int[debuts.length];
        int n = 0;
        int i = 0;
        while (i < source.length()) {
            int cp = source.codePointAt(i);
            int taille = Character.charCount(cp);
            String neutralise = neutralise(cp);
            for (int k = 0; k < neutralise.length(); k++) {
                char c = neutralise.charAt(k);
                // Les suites de blancs sont reduites a une seule espace, et les
                // blancs de tete disparaissent : une coupure de ligne au milieu
                // d'un texte modele ne doit pas rendre un extrait introuvable.
                if (c == ' ' && (sb.isEmpty() || sb.charAt(sb.length() - 1) == ' ')) continue;
                if (n == debuts.length) {
                    debuts = Arrays.copyOf(debuts, n * 2);
                    fins = Arrays.copyOf(fins, n * 2);
                }
                debuts[n] = i;
                fins[n] = i + taille;
                n++;
                sb.append(c);
            }
            i += taille;
        }
        return new TexteNormalise(source, sb.toString(),
            Arrays.copyOf(debuts, n), Arrays.copyOf(fins, n));
    }

    /**
     * Cherche {@code extrait} dans ce texte apres neutralisation typographique et
     * rend la <b>sous-chaine ORIGINALE exacte</b> correspondante.
     *
     * <p>Premiere occurrence en cas de repetition : le texte rendu est le meme a
     * la lettre pres, seule sa position change, et un surlignage n'a pas besoin
     * d'etre unique pour etre juste.
     *
     * @return vide si l'extrait est absent, vide, ou nul — jamais d'a-peu-pres.
     */
    public Optional<String> sousChaineOriginale(String extrait) {
        if (extrait == null || extrait.isBlank() || normalise.isEmpty()) return Optional.empty();
        String cible = de(extrait).normalise.strip();
        if (cible.isEmpty()) return Optional.empty();
        int debut = normalise.indexOf(cible);
        if (debut < 0) return Optional.empty();
        return Optional.of(original.substring(debuts[debut], fins[debut + cible.length() - 1]));
    }

    /** Vrai quand l'extrait figure dans le texte, apres neutralisation typographique. */
    public boolean contient(String extrait) {
        return sousChaineOriginale(extrait).isPresent();
    }

    /** Forme typographiquement neutralisee du texte source, pour un test ou un log. */
    public String normalise() {
        return normalise;
    }

    /**
     * FORME MOT : NFKC, minuscules, ligatures developpees, accents retires.
     * Deplacee ici depuis {@code EvaluationProofMatcher}, sans un octet de
     * changement — deux normalisations concurrentes finiraient par diverger.
     */
    public static String mot(String brut) {
        if (brut == null) return "";
        String compatible = Normalizer.normalize(brut, Normalizer.Form.NFKC)
            .toLowerCase(Locale.FRENCH)
            .replace("œ", "oe")
            .replace("æ", "ae");
        return Normalizer.normalize(compatible, Normalizer.Form.NFD)
            .replaceAll("\\p{M}+", "");
    }

    private static String neutralise(int cp) {
        if (Character.isWhitespace(cp)
            || (cp <= Character.MAX_VALUE && BLANCS_INSECABLES.indexOf((char) cp) >= 0)) {
            return " ";
        }
        String base = Normalizer.normalize(new String(Character.toChars(cp)), Normalizer.Form.NFKC);
        StringBuilder out = new StringBuilder(base.length());
        for (int i = 0; i < base.length(); i++) {
            char c = base.charAt(i);
            if (INVISIBLES.indexOf(c) >= 0) continue;
            if (APOSTROPHES.indexOf(c) >= 0) out.append('\'');
            else if (TIRETS.indexOf(c) >= 0) out.append('-');
            else if (GUILLEMETS.indexOf(c) >= 0) out.append('"');
            else if (c == 'œ') out.append("oe");
            else if (c == 'Œ') out.append("OE");
            else if (c == 'æ') out.append("ae");
            else if (c == 'Æ') out.append("AE");
            else if (Character.isWhitespace(c) || BLANCS_INSECABLES.indexOf(c) >= 0) out.append(' ');
            else out.append(c);
        }
        return out.toString();
    }
}
