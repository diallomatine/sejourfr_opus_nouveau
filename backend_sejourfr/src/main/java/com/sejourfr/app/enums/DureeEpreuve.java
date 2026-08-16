package com.sejourfr.app.enums;

/**
 * <b>Autorité unique de la durée d'une épreuve TCF.</b> Ce sont des données
 * d'examen, pas des réglages : elles vivent dans le code (même philosophie que
 * {@link BandeNoteTcf}), jamais dans {@code application.yaml}.
 *
 * <p>Une épreuve a la <b>même durée où qu'elle soit jouée</b> — en examen
 * blanc d'épreuve isolé comme en sous-épreuve d'un examen blanc TCF complet.
 * La compréhension écrite valait 35 min en standalone et 30 min en examen
 * complet (raccourcie pour tenir dans une enveloppe globale de 90 min, qui
 * n'existe plus) : les trois fronts en avaient recopié deux valeurs
 * différentes. Toute constante de durée d'épreuve ailleurs dans le code est un
 * bug — {@code ExamTemplate.durationSeconds} reste prioritaire quand un
 * template pilote l'examen, c'est la seule exception.
 *
 * <p><b>L'expression orale n'a volontairement pas de durée d'épreuve</b>
 * ({@link #secondes(EpreuveType)} rend {@code null}) : au TCF le temps se
 * compte <b>par tâche</b>, et il ne démarre qu'au moment où le candidat lance
 * la tâche (« Je suis prêt »). La borne est alors
 * {@code production_tasks.duree_max_sec} (180 / 210 / 210 s), pas un compte à
 * rebours global. Le seul plafond de session qui subsiste à l'oral est
 * {@link #EO_GARDE_SESSION_SECONDS}, un garde-fou anti-abus qui n'est jamais
 * exposé aux fronts.
 */
public enum DureeEpreuve {

    /** Compréhension orale : 25 QCM audio en 20 min. */
    CO(EpreuveType.TCF_CO, 20 * 60),

    /**
     * Compréhension écrite : 25 QCM en 35 min. <b>Partout</b>, y compris en
     * sous-épreuve d'examen complet (cf. javadoc de classe).
     */
    CE(EpreuveType.TCF_CE, 35 * 60),

    /** Structure de la langue : 20 min. Module bonus, jamais en examen complet. */
    STRUCTURE(EpreuveType.TCF_STRUCTURE, 20 * 60),

    /** Expression écrite : 30 min pour les 3 tâches, allocation libre. */
    EE(EpreuveType.TCF_EE, 30 * 60),

    /** Expression orale : aucune durée d'épreuve ne fait foi (cf. javadoc de classe). */
    EO(EpreuveType.TCF_EO, null);

    /**
     * Temps de parole cumulé des 3 tâches d'expression orale (180 + 210 +
     * 210 s). Ce n'est pas un chrono opposable : c'est la durée <b>annoncée</b>
     * au candidat (jalon du Plan, briefings). Le vrai plafond est posé tâche
     * par tâche depuis {@code production_tasks.duree_max_sec}.
     */
    public static final int EO_TEMPS_DE_PAROLE_SECONDS = 180 + 210 + 210;

    /**
     * <b>Garde-fou de session à l'oral — ce n'est PAS un chrono d'épreuve.</b>
     * Une session EO n'a pas de compte à rebours (le temps se compte par
     * tâche) ; sans aucune borne, elle resterait ouverte indéfiniment et un
     * compte gratuit pourrait y accumuler des évaluations IA payantes (Whisper
     * + LLM) longtemps après l'avoir abandonnée.
     *
     * <p>Dimensionnement : {@value #EO_TEMPS_DE_PAROLE_SECONDS} s de parole
     * (10 min) + la lecture et la préparation des 3 consignes + les
     * transitions et l'upload, soit ~30 min d'usage réel — porté à <b>2 h</b>,
     * douze fois le temps de parole, pour qu'une pause entre deux tâches ne
     * coûte jamais rien au candidat (l'abandon-reprise est officiellement
     * supporté). Le coût IA d'une session est de toute façon déjà borné par le
     * plafond « une soumission par tâche » (3 au maximum) : ce garde-fou
     * n'empêche que la session éternelle.
     *
     * <p>Il est <b>invisible des fronts</b> : il n'est jamais persisté dans
     * {@code attempts.time_limit_seconds} ni exposé dans un DTO, et n'est
     * opposé que par {@code ProductionAccessService}.
     */
    public static final int EO_GARDE_SESSION_SECONDS = 2 * 60 * 60;

    /**
     * Grâce accordée après l'échéance d'une épreuve, avant de refuser une
     * soumission ou de clôturer automatiquement : couvre la latence réseau de
     * l'auto-soumission déclenchée par les fronts à 0:00. Vaut pour les QCM
     * comme pour les productions — une seule valeur, jamais redéclarée.
     */
    public static final int GRACE_SOUMISSION_SECONDS = 60;

    private final EpreuveType epreuve;
    private final Integer secondes;

    DureeEpreuve(EpreuveType epreuve, Integer secondes) {
        this.epreuve = epreuve;
        this.secondes = secondes;
    }

    public EpreuveType getEpreuve() {
        return epreuve;
    }

    /** Durée de l'épreuve en secondes ; {@code null} pour l'expression orale. */
    public Integer getSecondes() {
        return secondes;
    }

    /**
     * Durée d'une épreuve, en secondes. {@code null} quand l'épreuve n'a pas de
     * chrono opposable ({@link EpreuveType#TCF_EO}) ou n'est pas une épreuve
     * TCF chronométrée ({@code CIVIQUE}, {@code TCF_COMPLET} — l'examen complet
     * n'a <b>plus</b> d'enveloppe globale, chaque épreuve porte la sienne).
     */
    public static Integer secondes(EpreuveType epreuve) {
        if (epreuve == null) return null;
        for (DureeEpreuve d : values()) {
            if (d.epreuve == epreuve) return d.secondes;
        }
        return null;
    }

    /**
     * Durée d'un examen blanc QCM d'épreuve TCF, désigné par son type de
     * question (CO / CE / STRUCTURE).
     *
     * @throws IllegalArgumentException si le type ne correspond à aucune
     *                                  épreuve QCM chronométrée.
     */
    public static int secondesPourQcm(QuestionType questionType) {
        EpreuveType epreuve = switch (questionType) {
            case CO, CO_IMAGE -> EpreuveType.TCF_CO;
            case CE -> EpreuveType.TCF_CE;
            case STRUCTURE -> EpreuveType.TCF_STRUCTURE;
            default -> null;
        };
        Integer secondes = secondes(epreuve);
        if (secondes == null) {
            throw new IllegalArgumentException(
                    "Aucune durée d'épreuve QCM pour le type de question " + questionType);
        }
        return secondes;
    }

    /**
     * Durée annoncée d'un examen blanc TCF complet : la somme des 4 épreuves,
     * l'oral comptant son temps de parole ({@link #EO_TEMPS_DE_PAROLE_SECONDS}).
     * C'est un <b>ordre de grandeur affiché</b>, pas un chrono : les 4 épreuves
     * courent chacune la leur, et rien ne se reporte de l'une à l'autre.
     */
    public static int secondesExamenComplet() {
        return secondes(EpreuveType.TCF_CO)
                + secondes(EpreuveType.TCF_CE)
                + secondes(EpreuveType.TCF_EE)
                + EO_TEMPS_DE_PAROLE_SECONDS;
    }
}
