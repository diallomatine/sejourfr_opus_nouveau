package com.sejourfr.app.enums;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

/**
 * L'examen blanc TCF complet a-t-il été joué <b>d'une traite</b> ou repris
 * entre plusieurs épreuves ? Statut de restitution, <b>dérivé serveur à la
 * lecture et jamais persisté</b> — même philosophie que
 * {@code SkillStatusResolver} et {@code SituationDansNiveau} : recalibrer le
 * seuil relit l'historique au prochain appel, sans migration ni job. Aucun
 * front ne le recalcule ; ils affichent {@link #getLabel()} tel quel (miroir
 * manuel, gelé par {@code ContinuiteSimulationTest}).
 *
 * <p><b>Deux valeurs seulement.</b> Le troisième cas de restitution — « pas de
 * résultat global définitif » — existe déjà et ne se dédouble pas ici : c'est
 * {@code FullTcfExamResponse.finalLevelPartial} /
 * {@code epreuvesCountedInFinalLevel}, qui disent sur combien d'épreuves porte
 * réellement le niveau plancher.
 *
 * <p>Quitter ne suspend rien : sur CO / CE / EE le chrono d'une épreuve
 * <b>lancée</b> continue de tourner pendant l'absence, et le temps restant ne
 * se transfère jamais à l'épreuve suivante. C'est ce qui rend cette
 * distinction honnête : reprendre l'examen le lendemain reste légitime, mais
 * ce n'est plus une simulation en conditions d'examen.
 */
public enum ContinuiteSimulation {

    /** Les 4 épreuves enchaînées sans interruption notable. */
    SESSION_UNIQUE("Simulation complète — conditions examen"),

    /** Au moins une reprise entre deux épreuves. */
    PLUSIEURS_SESSIONS("Simulation complétée en plusieurs sessions");

    /**
     * Pause maximale tolérée entre la fin d'une épreuve et le lancement de la
     * suivante sans déclasser la simulation.
     *
     * <p>15 minutes : au vrai TCF le candidat reste dans la salle et les
     * épreuves s'enchaînent avec une transition de quelques minutes
     * (installation, consignes de l'examinateur, changement de support). Chez
     * nous s'y ajoutent la relecture du briefing d'épreuve et, sur mobile, une
     * reconnexion réseau ou un rechargement d'application. Un quart d'heure
     * couvre tout cela largement ; au-delà, le candidat a quitté et repris —
     * c'est une autre session, et le dire est plus utile que de le flatter.
     */
    public static final Duration PAUSE_MAX_ENTRE_EPREUVES = Duration.ofMinutes(15);

    private final String label;

    ContinuiteSimulation(String label) {
        this.label = label;
    }

    /** Libellé FR affiché au candidat. Contrat gelé, miroir manuel sur les 3 fronts. */
    public String getLabel() {
        return label;
    }

    /**
     * Une épreuve réellement jouée : l'instant où le candidat l'a <b>lancée</b>
     * ({@code attempts.timer_started_at}) et celui où elle s'est terminée.
     * Une épreuve jamais lancée (verrouillée par le freemium, ou abandonnée
     * avant d'avoir été ouverte) n'a pas de début connu et ne participe pas au
     * calcul.
     */
    public record Etape(Instant debut, Instant fin) {
    }

    /**
     * Dérive la continuité d'une suite d'épreuves données <b>dans l'ordre
     * canonique</b> (CO → CE → EE → EO).
     *
     * <p>Règle : la simulation reste {@link #SESSION_UNIQUE} tant qu'aucun
     * écart entre la fin d'une épreuve et le lancement de la suivante ne
     * dépasse {@link #PAUSE_MAX_ENTRE_EPREUVES}. Les étapes sans début ni fin
     * connus sont ignorées — on ne déclasse jamais sur une donnée absente,
     * puisqu'une absence n'est pas la preuve d'une interruption.
     */
    public static ContinuiteSimulation of(List<Etape> etapes) {
        if (etapes == null) return SESSION_UNIQUE;
        Instant finPrecedente = null;
        for (Etape etape : etapes) {
            if (etape == null) continue;
            if (etape.debut() != null && finPrecedente != null
                    && Duration.between(finPrecedente, etape.debut())
                    .compareTo(PAUSE_MAX_ENTRE_EPREUVES) > 0) {
                return PLUSIEURS_SESSIONS;
            }
            if (etape.fin() != null) {
                finPrecedente = etape.fin();
            }
        }
        return SESSION_UNIQUE;
    }
}
