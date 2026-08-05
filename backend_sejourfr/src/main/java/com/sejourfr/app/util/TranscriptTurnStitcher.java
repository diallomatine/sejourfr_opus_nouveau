package com.sejourfr.app.util;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Recolle les tours CONSECUTIFS d'un MEME locuteur dans un transcript dialogue.
 *
 * <p><b>Pourquoi</b> : la transcription d'expression orale en temps reel cloture
 * un tour sur le signal de fin de tour du MODELE, qui n'est pas la fin de la
 * phrase du CANDIDAT. Un enonce unique ressort donc scinde a une frontiere
 * arbitraire :
 *
 * <pre>
 * Candidat : … qui m'ont qui m'ont pousse a l'air. Ah.
 * Candidat : aller vers l'informatique.
 * </pre>
 *
 * <p><b>Ou vit la regle</b> : ICI, et nulle part ailleurs. Elle est appliquee en
 * UN seul point — {@code TranscriptionManager#findLatestTexteBySubmissionId} —
 * donc en amont de TOUS les consommateurs : le prompt envoye au correcteur, le
 * controle de preuve ({@code EvaluationProofMatcher}) et le DTO servi aux trois
 * fronts. Web et mobile recoivent le texte recolle sans une ligne de code en
 * plus.
 *
 * <p><b>Invariant central</b> : le texte sur lequel les preuves sont citees est
 * EXACTEMENT celui que le candidat relit. C'est la consequence directe du point
 * d'application unique — si le DTO et le correcteur voyaient deux textes
 * differents, une preuve a cheval sur une frontiere recollee serait citee sans
 * etre visible a l'ecran, et la garantie d'opposabilite des preuves tomberait.
 *
 * <p><b>Non destructif</b> : rien n'est reecrit en base. Ni
 * {@code realtime_sessions.transcript}, ni {@code transcriptions.texte} : le
 * recollage se fait a la lecture, a chaque fois. Le drapeau
 * {@code sejourfr.production-evaluation.recollage-tours.enabled} (livre ACTIF)
 * rend le comportement historique a l'identique.
 *
 * <h2>Regle de fusion — EN CAS DE DOUTE, ON NE FUSIONNE PAS</h2>
 *
 * <p><b>Le sens de l'erreur est assume.</b> Sur un texte qui fait foi pour la
 * note ET que le candidat relit, une fusion FAUSSE est pire qu'une fusion
 * MANQUEE : une fusion manquee ramene au comportement d'avant le recollage, une
 * fusion fausse <b>fabrique de la parole</b>. Chaque garde-fou ci-dessous
 * tranche donc dans le sens du non-recollage.
 *
 * <ul>
 *   <li>on ne fusionne que des tours consecutifs du <b>meme locuteur</b> ;</li>
 *   <li><b>jamais a travers un tour de l'examinateur</b> : un tour
 *       {@code Examinateur :} intercale coupe net la fusion. C'est le garde-fou
 *       qui empeche de fabriquer une phrase que personne n'a dite quand le
 *       candidat s'est repris apres une relance ;</li>
 *   <li><b>jamais quand une phrase parait terminee et qu'une nouvelle
 *       commence</b> : fragment precedent qui se termine par une
 *       {@link #PONCTUATION_FORTE} ET fragment suivant qui commence par une
 *       MAJUSCULE. Les deux ensemble signent un enonce acheve suivi d'un
 *       nouveau depart, c'est-a-dire deux tentatives distinctes du candidat
 *       ({@code … s'il vous plait.} + {@code Oui, c'est quoi le tarif.}) et non
 *       une phrase coupee en deux. Une seule des deux conditions ne suffit pas :
 *       la fragmentation qu'on corrige laisse presque toujours le second morceau
 *       en minuscule ({@code … pousse a l'air. Ah.} + {@code aller vers
 *       l'informatique.}) ;</li>
 *   <li><b>jamais autour d'un fragment sans aucun caractere alphanumerique</b>
 *       ({@code . . . .}, marqueurs isoles). Il n'apporte rien au sens et le
 *       fusionner ne ferait que deplacer du bruit A L'INTERIEUR d'un enonce
 *       propre. Il reste un <b>tour isole</b> : on ne le retire pas du texte
 *       servi, car ce serait supprimer de la donnee produite par le
 *       transcripteur — le recollage n'enleve que des FRONTIERES, jamais du
 *       contenu ;</li>
 *   <li>on ne <b>repare pas</b> les mots coupes en plein milieu
 *       ({@code voi ture}) : ce bug a ete corrige en amont le 2026-07-04, les
 *       occurrences restantes lui sont anterieures et les deviner est hors de
 *       question sur un texte qui fait foi.</li>
 * </ul>
 *
 * <p><b>Ce que ces garde-fous ne rattrapent pas, volontairement</b> : les
 * transcriptions ratees de bout en bout ({@code stanno mal.} au milieu d'une
 * phrase francaise, marqueurs contenant des lettres comme {@code <noise>}).
 * Ce ne sont pas des enonces que NOTRE decoupage a casses ; les recoller ne les
 * degrade pas davantage, et vouloir les detecter demanderait de juger la qualite
 * d'une transcription — ce qui n'est pas le role de ce composant.
 *
 * <h2>Regle de jonction</h2>
 * On ne <b>supprime</b> et on n'<b>ajoute</b> aucun caractere des fragments :
 * le seul caractere introduit est un <b>espace simple</b>, et le seul supprime
 * est le blanc de la frontiere elle-meme (le retour a la ligne et le marqueur de
 * tour). En particulier, une <b>ponctuation forte en fin de premier fragment est
 * CONSERVEE</b> : elle a ete produite par le transcripteur, la retirer serait
 * une reecriture et un pari sur ce que le candidat a dit. Elle est par ailleurs
 * sans effet sur les preuves, {@code EvaluationProofMatcher} ne tokenisant que
 * lettres et chiffres.
 *
 * <p>L'espace est omis dans les seuls cas ou le francais le proscrit, pour ne
 * pas fabriquer une graphie que personne n'a ecrite : fragment suivant qui
 * commence par une ponctuation collante ({@link #PONCTUATION_COLLEE_A_GAUCHE}),
 * ou fragment precedent qui se termine par une elision ou un trait d'union
 * ({@link #LIAISONS_FINALES}).
 *
 * <p>Le resultat est le transcript d'entree dans lequel seules les frontieres
 * fusionnees ont ete remplacees : tout le reste est identique octet pour octet,
 * ce qui garantit qu'un transcript propre, ou un monologue Whisper sans
 * marqueurs de tour, ressort strictement inchange.
 */
@Component
@RequiredArgsConstructor
public class TranscriptTurnStitcher {

    /**
     * Marqueur de tour, identique a celui de {@code EvaluationProofMatcher} :
     * les deux doivent decouper le dialogue exactement de la meme facon.
     */
    private static final Pattern TURN_MARKER = Pattern.compile(
        "(?im)^[\\h]*(examinateur|candidat)[\\h]*:[\\h]*");

    /** Ponctuations qui, en francais, se collent au mot qui precede. */
    private static final String PONCTUATION_COLLEE_A_GAUCHE = ",.…)]}%";

    /** Ponctuations qui closent un enonce. */
    private static final String PONCTUATION_FORTE = ".!?…";

    /**
     * Fins de fragment qui se lient au mot suivant (elision, trait d'union).
     * {@code Je suis l'} + {@code employe} donne {@code Je suis l'employe}.
     */
    private static final String LIAISONS_FINALES = "'’-";

    private final ProductionEvaluationProperties props;

    /**
     * @param transcript transcript brut, tel qu'il est en base.
     * @return le meme transcript, tours consecutifs d'un meme locuteur recolles.
     *         Retourne l'entree telle quelle si le drapeau est eteint, si le
     *         texte est vide, ou s'il ne porte pas au moins deux marqueurs de
     *         tour (monologue Whisper, texte EE).
     */
    public String stitch(String transcript) {
        if (transcript == null || transcript.isBlank()) return transcript;
        if (!props.getRecollageTours().isEnabled()) return transcript;

        List<Turn> turns = turns(transcript);
        if (turns.size() < 2) return transcript;

        StringBuilder out = new StringBuilder(transcript.length());
        int copiedUpTo = 0;
        for (int i = 1; i < turns.size(); i++) {
            Turn precedent = turns.get(i - 1);
            Turn courant = turns.get(i);
            // Les trois garde-fous, dans l'ordre du moins au plus couteux. Tous
            // tranchent dans le meme sens : au moindre doute, on laisse les deux
            // tours separes — c'est le comportement d'avant le recollage, donc
            // au pire on ne repare pas, jamais on n'abime.
            if (!courant.speaker().equals(precedent.speaker())) continue;
            if (sansContenu(transcript, precedent) || sansContenu(transcript, courant)) continue;
            if (ouvreUnNouvelEnonce(transcript, precedent, courant)) continue;

            int contentStart = courant.contentStart();
            // Fin reelle du fragment precedent : dernier caractere non blanc
            // avant le marqueur, sans jamais mordre sur le marqueur precedent
            // (un tour au contenu vide laisse `fin == debut de son contenu`).
            int floor = precedent.contentStart();
            int prevEnd = courant.markerStart();
            while (prevEnd > floor && Character.isWhitespace(transcript.charAt(prevEnd - 1))) {
                prevEnd--;
            }

            out.append(transcript, copiedUpTo, prevEnd);
            out.append(separator(transcript, prevEnd, contentStart));
            copiedUpTo = contentStart;
        }
        if (copiedUpTo == 0) return transcript;

        out.append(transcript, copiedUpTo, transcript.length());
        return out.toString();
    }

    private static List<Turn> turns(String transcript) {
        Matcher matcher = TURN_MARKER.matcher(transcript);
        List<int[]> bornes = new ArrayList<>();
        List<String> locuteurs = new ArrayList<>();
        while (matcher.find()) {
            bornes.add(new int[]{matcher.start(), matcher.end()});
            locuteurs.add(matcher.group(1).toLowerCase(Locale.ROOT));
        }
        List<Turn> turns = new ArrayList<>(bornes.size());
        for (int i = 0; i < bornes.size(); i++) {
            int contentEnd = i + 1 < bornes.size() ? bornes.get(i + 1)[0] : transcript.length();
            turns.add(new Turn(locuteurs.get(i), bornes.get(i)[0], bornes.get(i)[1], contentEnd));
        }
        return turns;
    }

    private static String contenu(String transcript, Turn turn) {
        return transcript.substring(turn.contentStart(), turn.contentEnd()).strip();
    }

    /**
     * Fragment qui porte des caracteres mais AUCUN alphanumerique
     * ({@code . . . .}). Le fusionner deplacerait du bruit a l'interieur d'un
     * enonce propre, sans rien apporter au sens.
     *
     * <p>Un fragment <b>vide</b> n'est pas concerne : il n'a rien a deplacer, et
     * le laisser en tour isole n'afficherait qu'un « Candidat : » orphelin.
     */
    private static boolean sansContenu(String transcript, Turn turn) {
        String corps = contenu(transcript, turn);
        if (corps.isEmpty()) return false;
        for (int i = 0; i < corps.length(); i++) {
            if (Character.isLetterOrDigit(corps.charAt(i))) return false;
        }
        return true;
    }

    /**
     * Vrai quand la frontiere separe un enonce ACHEVE d'un NOUVEAU DEPART :
     * ponctuation forte a gauche ET majuscule a droite. C'est la signature de
     * deux tentatives distinctes du candidat, pas d'une phrase que le detecteur
     * de fin de tour a coupee en deux.
     */
    private static boolean ouvreUnNouvelEnonce(String transcript, Turn precedent, Turn courant) {
        String avant = contenu(transcript, precedent);
        String apres = contenu(transcript, courant);
        if (avant.isEmpty() || apres.isEmpty()) return false;
        return PONCTUATION_FORTE.indexOf(avant.charAt(avant.length() - 1)) >= 0
            && Character.isUpperCase(apres.charAt(0));
    }

    /**
     * Separateur a poser a la place de la frontiere supprimee. Jamais autre
     * chose qu'un espace simple ou rien : aucune ponctuation n'est inventee.
     */
    private static String separator(String transcript, int prevEnd, int contentStart) {
        if (prevEnd <= 0 || contentStart >= transcript.length()) return "";
        char suivant = transcript.charAt(contentStart);
        // Fragment suivant vide (le marqueur est immediatement suivi d'un retour
        // a la ligne) : rien a separer, sinon on laisserait un espace en trop.
        if (Character.isWhitespace(suivant)) return "";
        if (PONCTUATION_COLLEE_A_GAUCHE.indexOf(suivant) >= 0) return "";

        char precedent = transcript.charAt(prevEnd - 1);
        // Fragment precedent vide : le blanc du marqueur (« Candidat : ») separe deja.
        if (Character.isWhitespace(precedent)) return "";
        if (LIAISONS_FINALES.indexOf(precedent) >= 0) return "";
        return " ";
    }

    private record Turn(String speaker, int markerStart, int contentStart, int contentEnd) {
    }
}
