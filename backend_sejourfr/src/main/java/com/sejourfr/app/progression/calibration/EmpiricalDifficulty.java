package com.sejourfr.app.progression.calibration;

import com.sejourfr.app.enums.DifficultyBand;

import java.util.UUID;

/**
 * Ce que les candidats ont réellement fait d'une question (V4.2 §7).
 *
 * @param reponses      la taille de l'échantillon — exposée à côté du taux, et
 *                      pas cachée : un taux sur trois réponses ne veut rien
 *                      dire, et c'est l'appelant qui décide de son seuil.
 * @param tauxReussite  {@code null} quand personne n'y a encore répondu.
 *                      <b>Absence de mesure, jamais 0 %.</b>
 * @param bandeDeclaree la bande posée à la main, {@code null} si non taguée.
 */
public record EmpiricalDifficulty(
        UUID questionId,
        long reponses,
        Double tauxReussite,
        DifficultyBand bandeDeclaree
) {

    /**
     * La bande que les données <b>suggèrent</b>, ou {@code null} si
     * l'échantillon est trop mince pour dire quoi que ce soit.
     *
     * <p>🛑 <b>Suggère. Elle ne pose rien.</b> §7 dit qu'à terme la difficulté
     * empirique pourra remplacer les tags manuels — « pourra », et c'est une
     * décision produit, pas un effet de bord d'un job. Une bande qui changerait
     * toute seule ferait bouger la calibration des séries, donc le
     * {@code sourceType} des preuves, donc des paliers déjà acquis : le candidat
     * verrait un acquis disparaître sans avoir rien fait.
     *
     * <p>Les seuils ci-dessous sont volontairement <b>hors</b> de
     * {@code progression-config-v1.json} : contrairement au bloc
     * {@code aiScoring}, ils ne multiplient rien et n'entrent dans aucun calcul
     * de progression — ils ne servent qu'à proposer une bande à un humain. Les y
     * mettre laisserait croire qu'un changement ici a un effet sur les états, ce
     * qui est exactement faux : l'effet ne vient que du tag qu'un humain
     * décidera de poser.
     */
    public DifficultyBand bandeSuggeree() {
        if (tauxReussite == null || reponses < MIN_REPONSES) {
            return null;
        }
        // Bornes arbitrées le 2026-08-23 : EASY p > 0,75 · MEDIUM 0,45 ≤ p ≤ 0,75
        // · HARD p < 0,45. Les égalités tombent volontairement dans MEDIUM —
        // une question pile au seuil n'est ni franchement facile ni franchement
        // dure, et c'est la bande la moins engageante des trois.
        if (tauxReussite > 0.75d) return DifficultyBand.EASY;
        if (tauxReussite >= 0.45d) return DifficultyBand.MEDIUM;
        return DifficultyBand.HARD;
    }

    /** La bande déclarée contredit-elle ce que les candidats montrent ? */
    public boolean enDesaccord() {
        DifficultyBand suggeree = bandeSuggeree();
        return suggeree != null && bandeDeclaree != null && suggeree != bandeDeclaree;
    }

    /**
     * En dessous, un taux de réussite est du bruit. Trente réponses ne font pas
     * une certitude non plus — c'est un plancher, pas une garantie.
     */
    public static final int MIN_REPONSES = 30;
}
