package com.sejourfr.app.service.competence;

import com.sejourfr.app.enums.NiveauCecrl;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.LongAdder;

/**
 * COMBIEN DE FOIS le serveur a abaisse un niveau faute de preuve, et pourquoi.
 *
 * <p>Troisieme famille de compteurs du depot, et elle est <b>volontairement
 * distincte</b> des deux autres :
 * <ul>
 *   <li>un <b>refus</b> ({@code EvaluationRefusalMetrics}) rejette la sortie du
 *       correcteur et peut couter la tache au candidat ;</li>
 *   <li>une <b>purge</b> ({@code EvaluationPurgeMetrics}) retire une phrase du
 *       rapport et ne touche ni note, ni niveau ;</li>
 *   <li>un <b>abaissement</b> (ici) ne rejette rien et ne retire aucune phrase :
 *       il change le NIVEAU affiche au candidat.</li>
 * </ul>
 * Les melanger rendrait indechiffrable la seule question qui compte sur ce
 * garde-fou : « le correcteur annonce-t-il des paliers qu'il ne sait pas
 * montrer, et a quelle frequence ? ».
 *
 * <p>Sans ce compteur, le filet serait muet : on ne saurait ni le durcir (par
 * exemple abaisser de deux paliers) ni le desarmer sur des chiffres, et la
 * doctrine du depot est de ne rien regler au jugement.
 */
@Component
public class CompetenceLevelDowngradeMetrics {

    /** Pourquoi la preuve n'a pas pu etre retenue. */
    public enum Motif {
        /** Le correcteur n'a designe aucun segment sur un B1/B2. */
        PREUVE_ABSENTE,
        /** Le numero designe n'existe pas dans cette production. */
        PREUVE_HORS_BORNES,
        /** Le champ n'etait pas un entier (du texte, un decimal, une citation). */
        PREUVE_NON_ENTIERE
    }

    private final Map<String, LongAdder> compteurs = new ConcurrentHashMap<>();

    /**
     * @param motif  ce qui manquait a la preuve, apres l'unique reparation.
     * @param avant  niveau annonce par le correcteur.
     * @param apres  niveau retenu par le serveur (toujours strictement inferieur).
     */
    public void enregistrer(Motif motif, NiveauCecrl avant, NiveauCecrl apres) {
        ajouter(motif.name());
        ajouter(motif.name() + "/" + avant + "->" + apres);
    }

    private void ajouter(String cle) {
        compteurs.computeIfAbsent(cle, k -> new LongAdder()).increment();
    }

    /** Compteurs cumules {@code "MOTIF[/avant->apres]" -> n}, tries, pour le log. */
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
}
