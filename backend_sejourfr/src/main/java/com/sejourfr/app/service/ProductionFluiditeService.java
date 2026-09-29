package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Indice de FLUIDITE d'une production orale, calcule a partir des donnees deja
 * disponibles : la duree parlee ({@code submission.mediaDurationSec}) et le
 * nombre de mots de la transcription — plus, quand la transcription porte des
 * horodatages exploitables, un compte de <b>pauses longues</b>.
 *
 * <p><b>Ce sont des donnees factuelles, pas une note.</b> Le bloc produit ici
 * est injecte tel quel dans le feedback ; aucun calcul de note, de competence
 * ou de niveau ne le lit. C'est volontaire : le debit est un indice objectif et
 * <b>neutre vis-a-vis de l'accent</b>, contrairement a une analyse de
 * prononciation, mais il ne devient un critere note que sur decision produit
 * explicite.
 *
 * <p>Pilote par {@code sejourfr.production-evaluation.fluidite.enabled}
 * (defaut <b>false</b>) : desactive, ce service ne produit rien du tout.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProductionFluiditeService {

    /**
     * Message accompagnant les mesures, pour qu'aucun front ne les presente
     * comme un jugement.
     */
    static final String MENTION_INFORMATIVE =
        "Ces mesures sont purement indicatives : elles décrivent votre débit, elles "
            + "n'entrent pas dans votre note ni dans votre niveau.";

    /**
     * Segment horodate façon Whisper SRT/VTT : {@code 00:00:01,240 --> 00:00:04,800}.
     * Seul ce format donne un DEBUT et une FIN par segment, donc de vrais
     * silences entre segments. Un simple marqueur {@code [01:23]} ne permet pas
     * de distinguer une pause d'un passage parle : on ne l'exploite pas.
     */
    private static final Pattern SEGMENT_HORODATE = Pattern.compile(
        "(\\d{1,2}):([0-5]\\d):([0-5]\\d)[.,](\\d{1,3})\\s*-->\\s*"
            + "(\\d{1,2}):([0-5]\\d):([0-5]\\d)[.,](\\d{1,3})");

    /** Un "mot" = une suite de lettres/chiffres/apostrophes/traits d'union. */
    private static final Pattern MOT = Pattern.compile("[\\p{L}\\p{N}][\\p{L}\\p{N}'’-]*");

    private final ProductionEvaluationProperties props;

    /**
     * Bloc {@code fluidite} a injecter dans le feedback, ou {@code null} quand
     * il n'y a rien de fiable a dire : drapeau eteint, epreuve ecrite, duree
     * absente ou trop courte, transcription vide.
     */
    public Map<String, Object> indicateurs(ProductionSubmission sub, ProductionTask task, String transcription) {
        ProductionEvaluationProperties.Fluidite cfg = props.getFluidite();
        if (!cfg.isEnabled()) return null;
        if (task == null || task.getEpreuve() != EpreuveType.TCF_EO) return null;

        Integer duree = sub == null ? null : sub.getMediaDurationSec();
        if (duree == null || duree < cfg.getDureeMinSec()) return null;

        int mots = compterMots(transcription);
        if (mots == 0) return null;

        BigDecimal debit = BigDecimal.valueOf(mots)
            .multiply(BigDecimal.valueOf(60))
            .divide(BigDecimal.valueOf(duree), 0, RoundingMode.HALF_UP);

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("mots", mots);
        out.put("duree_sec", duree);
        out.put("debit_mots_par_minute", debit.intValue());

        Pauses pauses = compterPausesLongues(transcription, cfg.getPauseLongueSeuilSec());
        if (pauses == null) {
            out.put("pauses_longues", null);
            out.put("pauses_raison_indisponible",
                "La transcription ne porte pas d'horodatages : les silences ne sont pas mesurables.");
        } else {
            out.put("pauses_longues", pauses.nombre());
            out.put("pause_la_plus_longue_sec", pauses.plusLongueSec());
            out.put("pause_longue_seuil_sec", cfg.getPauseLongueSeuilSec());
        }

        out.put("informatif", true);
        out.put("mention", MENTION_INFORMATIVE);
        log.debug("Fluidite calculee submission={} mots={} duree={}s debit={} mots/min pauses={}",
            sub.getId(), mots, duree, debit, out.get("pauses_longues"));
        return out;
    }

    /** Nombre de mots exploitables d'une transcription (0 si vide/nulle). */
    static int compterMots(String texte) {
        if (texte == null || texte.isBlank()) return 0;
        Matcher m = MOT.matcher(texte);
        int n = 0;
        while (m.find()) n++;
        return n;
    }

    /**
     * Silences entre segments horodates, au-dela de {@code seuilSec}. Retourne
     * {@code null} si la transcription ne porte pas au moins deux segments
     * horodates : on ne devine pas une pause, on la mesure ou on se tait.
     */
    static Pauses compterPausesLongues(String texte, double seuilSec) {
        if (texte == null || texte.isBlank()) return null;
        List<double[]> segments = new ArrayList<>();
        Matcher m = SEGMENT_HORODATE.matcher(texte);
        while (m.find()) {
            double debut = secondes(m.group(1), m.group(2), m.group(3), m.group(4));
            double fin = secondes(m.group(5), m.group(6), m.group(7), m.group(8));
            if (fin >= debut) segments.add(new double[]{debut, fin});
        }
        if (segments.size() < 2) return null;

        segments.sort((a, b) -> Double.compare(a[0], b[0]));
        int nombre = 0;
        double plusLongue = 0;
        for (int i = 1; i < segments.size(); i++) {
            double silence = segments.get(i)[0] - segments.get(i - 1)[1];
            if (silence <= 0) continue;
            if (silence >= seuilSec) nombre++;
            if (silence > plusLongue) plusLongue = silence;
        }
        BigDecimal plusLongueArrondie = BigDecimal.valueOf(plusLongue).setScale(1, RoundingMode.HALF_UP);
        return new Pauses(nombre, plusLongueArrondie);
    }

    private static double secondes(String h, String min, String s, String millis) {
        // Le groupe millisecondes peut avoir 1 a 3 chiffres : on le normalise.
        String ms = (millis + "00").substring(0, 3);
        return Integer.parseInt(h) * 3600L
            + Integer.parseInt(min) * 60L
            + Integer.parseInt(s)
            + Integer.parseInt(ms) / 1000.0;
    }

    /** Compte de silences longs + duree du plus long (secondes, 1 decimale). */
    record Pauses(int nombre, BigDecimal plusLongueSec) {
    }
}
