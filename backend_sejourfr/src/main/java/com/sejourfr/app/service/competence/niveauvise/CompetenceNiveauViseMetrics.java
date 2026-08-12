package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.util.SegmentsSurlignage;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.LongAdder;

/**
 * CE QUE LE BLOC « POUR VISER X » PERD EN CHEMIN, compte par motif.
 *
 * <p>Famille de compteurs volontairement <b>separee</b> des autres — les melanger
 * rendrait chacune illisible :
 * <ul>
 *   <li>{@code EvaluationRefusalMetrics} : un <b>refus</b> rejette la sortie du
 *       correcteur et peut couter la tache au candidat ;</li>
 *   <li>{@code EvaluationPurgeMetrics} : une <b>purge</b> retire une phrase d'un
 *       rapport par ailleurs intact ;</li>
 *   <li>{@code VersionCibleeMetrics} : la meme mesure, mais sur le second appel
 *       des <b>productions</b>. Deux ecrans differents, deux compteurs — sinon on
 *       ne saurait plus lequel des deux perd son bloc ;</li>
 *   <li>ici : le bloc de confort du module <b>Competences</b> qui n'arrive pas
 *       jusqu'a l'ecran, un <b>appel de reparation paye</b>, un <b>segment de
 *       surlignage retire</b>. Rien de tout cela ne touche le verdict, le niveau
 *       ni l'analyse.</li>
 * </ul>
 *
 * <p><b>Pourquoi ils existent.</b> Le bloc « pour viser » disparaissait de l'ecran
 * sans qu'on puisse dire combien de candidats le perdaient, ni pourquoi : deux
 * {@code log.warn} et rien d'autre. Aucune des decisions prises dessus (tolerance
 * reelle des petits plafonds, segments rendus facultatifs, comparaison apres
 * normalisation) ne pourra etre jugee sur des chiffres sans eux. C'est la doctrine
 * du depot : un filet muet ne peut ni se durcir ni se desarmer.
 */
@Component
public class CompetenceNiveauViseMetrics {

    /** POURQUOI le bloc est tombe, ou ce qu'une reparation a redemande. */
    public enum Motif {
        /** Sortie vide ou sans aucune des trois cles : rien n'est exploitable. */
        SORTIE_HORS_CONTRAT,
        /** Champ absent, vide, mal type, cle en trop, cardinalite fausse, plafond depasse. */
        STRUCTURE,
        /** Leviers retires par le filet des marqueurs A2, sous leur minimum. */
        PURGE_LEVIERS
    }

    private final Map<String, LongAdder> compteurs = new ConcurrentHashMap<>();

    /**
     * Le bloc ENTIER n'arrive pas a l'ecran.
     *
     * <p>Il n'y a pas de compteur « par section » ici, contrairement aux
     * productions : le contrat de ce module n'a aucune partie facultative — ses
     * trois champs sont requis ensemble, donc le bloc tombe d'un bloc. Le seul
     * element qui peut disparaitre seul est un <b>segment</b>, compte a part.
     */
    public void blocAbandonne(Motif motif) {
        ajouter("BLOC_ABANDONNE/" + motif.name());
    }

    /** UN appel de reparation a ete paye. Le motif dit ce qu'on a redemande. */
    public void reparationPayee(Motif motif) {
        ajouter("REPARATION/" + motif.name());
    }

    /**
     * Un passage a surligner est retire, le texte modele restant servi. Le motif
     * vient du filet PARTAGE avec les productions : la mecanique du surlignage est
     * commune aux deux surfaces, le comptage reste propre a chacune.
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
     * un champ fautif : les deux abandonnent le bloc, mais ne se corrigent pas de
     * la meme façon.
     */
    static Motif motif(List<String> violations) {
        if (violations == null || violations.isEmpty()) return Motif.PURGE_LEVIERS;
        for (String violation : violations) {
            if (violation != null
                && violation.startsWith(CompetenceNiveauViseValidator.VIOLATION_SORTIE_VIDE)) {
                return Motif.SORTIE_HORS_CONTRAT;
            }
        }
        return Motif.STRUCTURE;
    }
}
