package com.sejourfr.app.service;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * MESURE — et rien d'autre — la part de francais DESACCENTUE dans le rapport
 * rendu au candidat.
 *
 * <h2>Pourquoi cet audit existe</h2>
 * Constat de production : le correcteur rend « Excuse formulee », « le passe
 * compose est maitrise », « J'espere que cette date te convient ». Pour un
 * produit qui enseigne le francais, corriger l'orthographe de quelqu'un dans un
 * francais mal orthographie est inacceptable. La correction vit dans les
 * rubriques v13 et le tool-schema v7 ; cet audit sert a savoir si elle a pris.
 *
 * <h2>Ce que cet audit NE fait PAS, volontairement</h2>
 * <b>Il ne refuse rien, ne modifie rien, ne rejoue rien.</b> Il n'entre dans
 * aucune validation, ne touche ni la note, ni le niveau, ni un champ de texte.
 * Faire echouer une soumission sur un indice heuristique couterait au candidat
 * infiniment plus cher que l'accent manquant qu'on veut corriger — le depot a
 * deja paye ce prix avec la contrainte de preuve litterale, dont le cout en
 * soumissions perdues est reste invisible des mois. On mesure d'abord ; on
 * durcira si la mesure le justifie.
 *
 * <h2>Regle de detection : en cas de doute, on ne signale rien</h2>
 * <ul>
 *   <li>liste FERMEE de formes ({@link #FORMES_DESACCENTUEES}) qui n'ont
 *       <b>aucune lecture francaise valable sans accent</b> — « ete », « apres »,
 *       « deja ». Toute forme qui reste un mot francais sans son accent
 *       (« tache », « cote », « a », « ou », « regle ») en est exclue, ainsi que
 *       les homographes d'un mot anglais courant (« experience »,
 *       « evaluation », « different »), qu'un rapport peut citer legitimement ;</li>
 *   <li>les champs qui CITENT le candidat ne sont jamais audites
 *       ({@link #CLES_IGNOREES}) : sa graphie est la sienne, accents manquants
 *       compris. Idem pour les champs poses par le serveur (libelle de critere,
 *       bande, avertissements), qui ne viennent pas du correcteur ;</li>
 *   <li>a l'interieur d'un champ, les passages entre guillemets sont retires
 *       avant la mesure : le correcteur y reprend souvent les mots du candidat.
 *       L'apostrophe simple est volontairement exclue de ces guillemets — en
 *       francais elle marque l'elision.</li>
 * </ul>
 */
public final class EvaluationAccentAudit {

    /**
     * Formes DESACCENTUEES sans lecture francaise valable et sans homographe
     * anglais courant. Liste fermee : elle ne cherche pas l'exhaustivite, elle
     * cherche a ne jamais se tromper. Un rapport correctement accentue n'en
     * contient aucune, par construction.
     */
    static final Set<String> FORMES_DESACCENTUEES = Set.of(
        "ete", "etait", "etaient", "etais", "etre", "meme", "memes",
        "apres", "tres", "deja", "eviter",
        "reussi", "reussie", "reussir", "reussite",
        "interet", "interets", "maitrise", "maitriser", "maitrisee", "maitrises",
        "elabore", "elaboree", "reponse", "reponses",
        "necessaire", "necessaires", "resultat", "resultats",
        "qualite", "qualites", "etudier", "etudie",
        "preciser", "precisee", "ameliorer", "ameliore", "amelioree", "amelioration",
        "expliquee", "expliquees", "proposee", "proposees", "formulee", "formulees",
        "seance", "seances", "recit", "recits", "espere", "esperer",
        "developpe", "developpee", "developpement", "deroulement",
        "idee", "idees", "clarte", "caractere", "caracteres",
        "eleve", "elevee", "probleme", "problemes", "systeme", "systemes",
        "premiere", "premieres", "derniere", "dernieres", "maniere", "manieres",
        "critere", "criteres", "consequence", "consequences", "etape", "etapes",
        "utilisee", "utilisees", "echange", "echanges",
        "francais", "francaise", "francaises",
        "ecrit", "ecrite", "ecrits", "ecrites",
        "periode", "periodes", "verifie", "verifier", "repete", "repetee",
        "terminee", "enonce", "subordonnee");

    /**
     * Cles jamais auditees : citations du candidat (sa graphie lui appartient),
     * identifiants et enums (pas du francais), textes poses par le SERVEUR
     * (deja accentues, et ils ne disent rien de ce que rend le correcteur).
     */
    static final Set<String> CLES_IGNOREES = Set.of(
        "avant", "original", "preuve", "preuve_segment",
        "code", "label", "bande", "niveau_cecrl", "confiance", "objectif",
        "obligatoire", "note_globale", "note_sur_20", "avertissements");

    /** Guillemets francais, droits et typographiques — jamais l'apostrophe. */
    private static final Pattern GUILLEMETS = Pattern.compile(
        "«[^«»]{0,400}»|\"[^\"]{0,400}\"|“[^”]{0,400}”");

    private static final Pattern MOT = Pattern.compile("\\p{L}+");

    private EvaluationAccentAudit() {
    }

    /**
     * @param occurrences   nombre de mots desaccentues rencontres
     * @param champsTouches nombre de champs de texte qui en portent au moins un
     * @param formes        formes distinctes rencontrees, dans l'ordre, pour le log
     */
    public record Resultat(int occurrences, int champsTouches, List<String> formes) {

        public boolean aDetecte() {
            return occurrences > 0;
        }
    }

    /** Audite un feedback complet (sortie du correcteur, deja normalisee). */
    public static Resultat analyser(Object feedback) {
        Compteur compteur = new Compteur();
        parcourir(feedback, compteur);
        return compteur.resultat();
    }

    private static void parcourir(Object node, Compteur compteur) {
        if (node instanceof Map<?, ?> map) {
            for (Map.Entry<?, ?> entry : map.entrySet()) {
                if (CLES_IGNOREES.contains(String.valueOf(entry.getKey()))) continue;
                parcourir(entry.getValue(), compteur);
            }
        } else if (node instanceof List<?> list) {
            for (Object item : list) parcourir(item, compteur);
        } else if (node instanceof String texte) {
            compteur.mesurer(texte);
        }
    }

    private static final class Compteur {

        private int occurrences;
        private int champsTouches;
        private final Set<String> formes = new LinkedHashSet<>();

        void mesurer(String texte) {
            if (texte == null || texte.isBlank()) return;
            String horsCitation = GUILLEMETS.matcher(texte).replaceAll(" ");
            var matcher = MOT.matcher(horsCitation);
            int avant = occurrences;
            while (matcher.find()) {
                String mot = matcher.group().toLowerCase(Locale.FRENCH);
                if (FORMES_DESACCENTUEES.contains(mot)) {
                    occurrences++;
                    formes.add(mot);
                }
            }
            if (occurrences > avant) champsTouches++;
        }

        Resultat resultat() {
            return new Resultat(occurrences, champsTouches, List.copyOf(new ArrayList<>(formes)));
        }
    }
}
