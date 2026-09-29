package com.sejourfr.app.service.diagnostic.exemplecible;

import com.sejourfr.app.util.SegmentsSurlignage;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.LongAdder;

/**
 * CE QUE LE BLOC « AVANT / APRES » DU DIAGNOSTIC PERD EN CHEMIN, compte par
 * motif.
 *
 * <p>Famille de compteurs volontairement <b>separee</b> des autres — les melanger
 * rendrait chacune illisible :
 * <ul>
 *   <li>{@code EvaluationRefusalMetrics} : un <b>refus</b> rejette la sortie du
 *       correcteur et peut couter la tache au candidat ;</li>
 *   <li>{@code EvaluationPurgeMetrics} : une <b>purge</b> retire une phrase d'un
 *       rapport par ailleurs intact ;</li>
 *   <li>{@code VersionCibleeMetrics} et {@code CompetenceNiveauViseMetrics} : la
 *       meme mesure, mais sur le second appel des <b>productions</b> et sur celui
 *       du module <b>Competences</b>. Trois ecrans differents, trois compteurs —
 *       sinon on ne saurait plus lequel perd son bloc ;</li>
 *   <li>ici : le bloc de conversion de l'ecran de <b>resultat du diagnostic</b>
 *       qui n'arrive pas jusqu'a l'ecran, un <b>appel de reparation paye</b>, un
 *       <b>passage surligne retire</b>. Rien de tout cela ne touche l'analyse
 *       diagnostique, ses priorites ni le Plan.</li>
 * </ul>
 */
@Component
public class DiagnosticExempleCibleMetrics {

    /** POURQUOI le bloc est tombe, ou ce qu'une reparation a redemande. */
    public enum Motif {
        /** Sortie vide ou sans aucun des trois champs : rien n'est exploitable. */
        SORTIE_HORS_CONTRAT,
        /** Champ absent, vide, mal type, cle en trop : rien a reparer mecaniquement. */
        STRUCTURE,
        /** Numero de phrase absent, non entier, ou hors des bornes du decoupage. */
        SEGMENT_NUMERO,
        /** Texte reecrit hors des bornes de longueur de la tache. */
        LONGUEUR_TEXTE
    }

    private final Map<String, LongAdder> compteurs = new ConcurrentHashMap<>();

    /**
     * Le bloc ENTIER n'arrive pas a l'ecran.
     *
     * <p>Il n'y a pas de compteur « par section » ici : le bloc n'a qu'une piece
     * maitresse, la phrase reecrite. Le seul element qui peut disparaitre seul est
     * un <b>segment</b> de surlignage, compte a part.
     */
    public void blocAbandonne(Motif motif) {
        ajouter("BLOC_ABANDONNE/" + motif.name());
    }

    /** UN appel de reparation a ete paye. Le motif dit ce qu'on a redemande. */
    public void reparationPayee(Motif motif) {
        ajouter("REPARATION/" + motif.name());
    }

    /**
     * Un passage a surligner est retire, le texte reecrit restant servi. Le motif
     * vient du filet PARTAGE avec les deux autres surfaces : la mecanique du
     * surlignage est commune, le comptage reste propre a chacune.
     */
    public void segmentRetire(SegmentsSurlignage.Motif motif) {
        ajouter("SEGMENT_RETIRE/" + motif.name());
    }

    private void ajouter(String cle) {
        compteurs.computeIfAbsent(cle, k -> new LongAdder()).increment();
    }

    /** Compteurs cumules, tries, pour le log. */
    public Map<String, Long> compteurs() {
        Map<String, Long> out = new LinkedHashMap<>();
        compteurs.entrySet().stream()
            .sorted(Map.Entry.comparingByKey())
            .forEach(e -> out.put(e.getKey(), e.getValue().sum()));
        return out;
    }

    /** Remise a zero — reservee aux tests. */
    public void reset() {
        compteurs.clear();
    }

    /**
     * Motif DOMINANT d'une liste de violations. Une sortie hors contrat prime sur
     * un champ fautif, et un defaut MECANIQUE (numero, longueur) est nomme tel
     * quel : les trois abandonnent le bloc, mais seuls les deux derniers valent
     * une reparation.
     */
    static Motif motif(List<String> violations) {
        if (violations == null || violations.isEmpty()) return Motif.STRUCTURE;
        for (String violation : violations) {
            if (violation != null
                && violation.startsWith(DiagnosticExempleCibleValidator.VIOLATION_SORTIE_VIDE)) {
                return Motif.SORTIE_HORS_CONTRAT;
            }
        }
        for (String violation : violations) {
            if (violation != null
                && violation.startsWith(DiagnosticExempleCibleValidator.VIOLATION_NUMERO)) {
                return Motif.SEGMENT_NUMERO;
            }
        }
        for (String violation : violations) {
            if (violation != null
                && violation.startsWith(DiagnosticExempleCibleValidator.VIOLATION_LONGUEUR)) {
                return Motif.LONGUEUR_TEXTE;
            }
        }
        return Motif.STRUCTURE;
    }
}
