package com.sejourfr.app.service.progres;

import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.StatutObjectif;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticLevelResolver;
import org.springframework.stereotype.Component;

/**
 * « Ou en suis-je par rapport a mon objectif ? », epreuve par epreuve
 * (spec V2 §2).
 *
 * <p><b>Composant pur</b> : deux paliers entrent, un statut sort. Ni base, ni
 * horloge — c'est ce qui le rend testable exactement aux frontieres qui font
 * mal (le cran juste en dessous, l'epreuve jamais mesuree, la demarche non
 * declaree).
 *
 * <p>🛑 <b>L'ordre CECRL n'est pas recopie ici</b> : il est demande a
 * {@link TcfDiagnosticLevelResolver#rang}, la meme autorite que
 * {@code TcfDiagnosticProgressionResolver.evolution}. Une seconde table de
 * paliers finirait par classer autrement que l'ecran d'a cote — c'est le defaut
 * le plus cher du depot.
 *
 * <p>🛑 <b>Un derive se relit, il ne se persiste pas.</b> Rien n'est stocke :
 * changer d'objectif (la demarche du candidat) reclasse les quatre epreuves au
 * prochain appel, sans migration.
 */
@Component
public class StatutObjectifResolver {

    /**
     * Le statut d'une epreuve.
     *
     * <p>🛑 <b>Aucun objectif declare ⇒ {@code null}</b>, jamais
     * {@code TO_REINFORCE} : sans demarche, il n'y a pas de palier exige, donc
     * rien a renforcer <i>vers</i> quoi que ce soit. {@code null} = inconnu,
     * jamais mauvais.
     *
     * <p>⚠️ <b>Une epreuve jamais mesuree rend bien {@code TO_REINFORCE}</b>
     * (table de la spec V2 §2) : c'est le travail qui reste, pas un verdict. La
     * distinction « jamais mesure » / « mesure faible » reste lisible a cote,
     * sur le niveau servi, qui vaut alors {@code null}.
     *
     * @param actuel   le palier mesure, ou {@code null} si l'epreuve n'a jamais
     *                 ete evaluee
     * @param objectif le palier exige par la demarche
     *                 ({@code TargetProcedure.niveauVise}), ou {@code null}
     */
    public StatutObjectif resoudre(NiveauCecrl actuel, NiveauCecrl objectif) {
        if (objectif == null) {
            return null;
        }
        if (actuel == null) {
            return StatutObjectif.TO_REINFORCE;
        }
        int ecart = TcfDiagnosticLevelResolver.rang(actuel)
                - TcfDiagnosticLevelResolver.rang(objectif);
        if (ecart >= 0) return StatutObjectif.TARGET_REACHED;
        if (ecart == -1) return StatutObjectif.CLOSE_TO_TARGET;
        return StatutObjectif.TO_REINFORCE;
    }
}
