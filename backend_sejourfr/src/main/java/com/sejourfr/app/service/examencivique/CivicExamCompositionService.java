package com.sejourfr.app.service.examencivique;

import com.sejourfr.app.entity.CivicOfficialUnit;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.CivicExamFormat;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.CivicOfficialUnitManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.ThemeManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * <b>La composition CONFORME d'un examen civique</b> (P8.A, arbitrages D-29 et
 * D-38).
 *
 * <p>Source de droit : <b>arrete du 10 octobre 2025</b> (JORF n° 0240 du
 * 12 octobre 2025, NOR <b>INTV2527907A</b>), article 3 et <b>annexe I</b>.
 * Art. 3 : « Chaque candidat devra repondre a un <b>nombre equivalent de
 * questions par thematique et notion</b>. »
 *
 * <h2>🛑 Ce que ce service remplace, et pourquoi il a fallu le creer</h2>
 * <p>Avant lui, <b>aucun</b> des trois chemins de composition ne connaissait la
 * repartition officielle. Mesure sur les <b>33</b> examens de 40 questions deja
 * passes : <b>0 conforme</b>. Le produit tirait <b>8 / 8 / 8 / 8 / 8</b> la ou
 * l'arrete exige <b>11 / 6 / 11 / 8 / 4</b> ; il sortait <b>7,7</b> mises en
 * situation au lieu de <b>12</b> ; et <b>58 %</b> de celles tirees l'etaient dans
 * une thematique ou l'examen reel n'en pose <b>aucune</b>.
 *
 * <h2>🛑 Le quota est LU, jamais declare ici (D-38)</h2>
 * <p>Il vit dans {@code civic_official_units.exam_quota}, seule autorite.
 * {@link CivicExamFormat} porte ce qui n'est pas par unite — 40 questions, seuil
 * 32, 45 min, partage 28 / 12. Et les totaux par thematique
 * (11 / 6 / 11 / 8 / 4) ne sont declares <b>nulle part</b> : ils se
 * <b>derivent</b> par somme des quotas. Les ecrire en ferait une
 * 2<sup>e</sup> copie, et un jour l'une des deux aurait tort.
 *
 * <h2>🛑 Aucun filtre de mention (D-42, D-45)</h2>
 * <p>{@code difficulty} n'est <b>jamais</b> passe ici. L'arrete pose <b>un</b>
 * programme pour <b>toutes les mentions</b>, sur une <b>seule</b> annexe I. Et la
 * mesure l'impose autant que le texte : avec le filtre, un examen conforme est
 * <b>impossible</b> pour CSP (Laicite 1 question pour 2 exigees ; mises en
 * situation de Principes 1 pour 6) et pour NAT (1 pour 6 puis 5 pour 6). Seul CR
 * y parvenait.
 *
 * <h2>🛑 Il echoue BRUYAMMENT, il ne se degrade jamais (D-29, exigence 3)</h2>
 * <p>Un examen officiel qui ne peut pas satisfaire ses quotas <b>leve</b>. Le
 * defaut le plus grave releve par l'audit etait exactement l'inverse : le
 * fallback de {@code pickQuestionsForTemplate} completait hors regles <b>en
 * silence</b>, ce qui rendait toute regle future inoperante sans le dire.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CivicExamCompositionService {

    private final CivicOfficialUnitManager unitManager;
    private final QuestionManager questionManager;
    private final ThemeManager themeManager;

    /**
     * Un examen civique <b>conforme a l'arrete</b>, deja melange.
     *
     * <p>🛑 <b>Aucun parametre.</b> Ni taille, ni mention, ni theme : tout vient
     * du programme. Un examen officiel n'a pas de variante — c'est ce qui
     * distingue cette methode de l'ancienne
     * {@code composeCiviqueFullExam(difficulty, size)}, dont les deux parametres
     * etaient precisement les deux libertes que l'arrete ne donne pas.
     *
     * @throws BusinessException si une unite ne peut pas fournir son quota. 🛑 On
     *                           le DIT, on ne rend pas un examen presque conforme.
     */
    public List<Question> composerExamenConforme() {
        List<CivicOfficialUnit> unites = unitManager.findAllDansLOrdreDuProgramme();
        exigerLeProgrammeComplet(unites);

        Map<String, UUID> themesParCode = themeManager
                .findByModuleOrderedByDisplayOrder(com.sejourfr.app.enums.Module.CIVIQUE).stream()
                .collect(Collectors.toMap(Theme::getCode, Theme::getId));

        // LinkedHashSet : l'ordre du programme est conserve jusqu'au melange
        // final, ce qui rend un echec lisible (« c'est la 11e unite qui manque »).
        LinkedHashSet<Question> tirees = new LinkedHashSet<>(CivicExamFormat.QUESTIONS);
        List<UUID> exclues = new ArrayList<>(CivicExamFormat.QUESTIONS);

        for (CivicOfficialUnit unite : unites) {
            int quota = unite.getExamQuota();
            List<Question> lot = tirerPourUneUnite(unite, exclues, quota);

            if (lot.size() < quota) {
                // 🛑 D-29 exigence 3 : on leve, on ne complete pas hors regles.
                throw new BusinessException(
                        "Examen civique non composable : l'unite officielle « " + unite.getLabel()
                                + " » (" + unite.getCode() + ", thematique " + unite.getThemeCode()
                                + ") exige " + quota + " question(s) et n'en fournit que "
                                + lot.size() + ". L'arrete du 10 octobre 2025 fixe ce quota ; "
                                + "il manque du contenu, pas un reglage.");
            }
            for (Question q : lot) {
                if (tirees.add(q)) exclues.add(q.getId());
            }
        }

        // Garde-fou de sortie : la somme des quotas vaut 40 (test normatif du
        // seed), donc arriver ici avec autre chose signifierait qu'une unite a
        // rendu plus que son quota. Impossible par construction -- on le verifie
        // quand meme, parce que c'est l'examen d'un candidat.
        if (tirees.size() != CivicExamFormat.QUESTIONS) {
            throw new IllegalStateException(
                    "Examen civique compose a " + tirees.size() + " questions au lieu de "
                            + CivicExamFormat.QUESTIONS + " : la somme des quotas d'unite a derive.");
        }

        List<Question> examen = new ArrayList<>(tirees);
        // Sans ce remelange, le candidat enchainerait les thematiques dans
        // l'ordre, puis les mises en situation d'affilee.
        Collections.shuffle(examen);
        return examen;
    }

    /**
     * Le tirage d'<b>une</b> unite. 🛑 Deux chemins, parce que les deux familles
     * d'unites ne se rejoignent pas pareil : une unite de connaissance par la
     * <b>notion</b> de la question, une unite de mises en situation par le
     * <b>theme</b> — une mise en situation ne porte jamais de notion (D-35).
     */
    private List<Question> tirerPourUneUnite(
            CivicOfficialUnit unite, List<UUID> exclues, int quota) {
        // 🛑 `difficulty` a `null`, toujours : un programme pour toutes les
        // mentions (D-42). Ce n'est pas un oubli, c'est la regle.
        if (unite.getQuestionType() == QuestionType.MISE_SITUATION) {
            return questionManager.findRandomMisesEnSituationExcluding(
                    unite.getThemeCode(), null, exclues, quota);
        }
        return questionManager.findRandomByOfficialUnitExcluding(
                unite.getId(), null, exclues, quota);
    }

    /**
     * 🛑 Le programme doit etre <b>entier</b> avant de composer quoi que ce soit.
     *
     * <p>Une table des unites amputee — un seed partiel, une migration a moitie
     * appliquee — produirait un examen « conforme » a un programme qui n'est pas
     * celui de l'arrete. C'est le pire des echecs possibles ici : silencieux et
     * credible. Le test normatif du seed verrouille les 16 lignes ; ce garde
     * verifie qu'on les a bien lues.
     */
    private void exigerLeProgrammeComplet(List<CivicOfficialUnit> unites) {
        int somme = unites.stream().mapToInt(CivicOfficialUnit::getExamQuota).sum();
        if (somme != CivicExamFormat.QUESTIONS) {
            throw new IllegalStateException(
                    "Programme civique incomplet : " + unites.size() + " unite(s) lues, dont les "
                            + "quotas totalisent " + somme + " au lieu de "
                            + CivicExamFormat.QUESTIONS + ". L'arrete du 10 octobre 2025 "
                            + "(annexe I) en fixe 16, somme 40. Verifier le seed de V115.");
        }
        int mes = unites.stream()
                .filter(u -> u.getQuestionType() == QuestionType.MISE_SITUATION)
                .mapToInt(CivicOfficialUnit::getExamQuota).sum();
        if (mes != CivicExamFormat.MISES_EN_SITUATION) {
            throw new IllegalStateException(
                    "Programme civique incoherent : les mises en situation totalisent " + mes
                            + " au lieu de " + CivicExamFormat.MISES_EN_SITUATION
                            + " (6 en « Principes et valeurs », 6 en « Droits et devoirs »).");
        }
    }

    /**
     * La repartition <b>par thematique</b>, <b>derivee</b> des quotas d'unite.
     *
     * <p>🛑 <b>11 / 6 / 11 / 8 / 4 n'est declare nulle part</b> (D-38). Cette
     * methode le <b>calcule</b>, et c'est la seule facon d'y acceder. Elle sert
     * aux tests et aux mesures, jamais a composer — la composition itere sur les
     * unites, pas sur les thematiques.
     */
    public Map<String, Integer> repartitionParThematique() {
        return unitManager.findAllDansLOrdreDuProgramme().stream()
                .collect(Collectors.groupingBy(
                        CivicOfficialUnit::getThemeCode, java.util.LinkedHashMap::new,
                        Collectors.summingInt(CivicOfficialUnit::getExamQuota)));
    }

    /** Les unites du programme, par leur code — pour les mesures et les tests. */
    public Map<String, CivicOfficialUnit> unitesParCode() {
        return unitManager.findAllDansLOrdreDuProgramme().stream()
                .collect(Collectors.toMap(CivicOfficialUnit::getCode, Function.identity(),
                        (a, b) -> a, java.util.LinkedHashMap::new));
    }

    // ========================================================================
    // L'EXAMEN DE THEME — format SejourFR, structure officielle (D-31, D-47)
    // ========================================================================

    /**
     * Un examen de <b>thème</b> : 20 questions, aux <b>proportions officielles
     * internes</b> de cette thématique.
     *
     * <p>🛑 <b>Ce format n'existe pas dans l'arrete</b> — l'epreuve reelle porte
     * sur les cinq thematiques a la fois. Mais il en respecte la <b>structure</b>
     * (D-31) : les unites de la thematique, dans leurs proportions, et donc les
     * mises en situation <b>seulement</b> ou l'examen reel en pose.
     *
     * <p>🛑 <b>Il tire par UNITE, pas par {@code questions.theme_id}</b> (D-47) :
     * l'unite officielle est l'autorite du thematique dans tout ce qui compose ou
     * mesure le programme. Tirer par {@code theme_id} ramenait des questions que
     * l'arrete range dans une <b>autre</b> thematique — mesure : 22 questions de
     * {@code theme_id = CIV_PRINCIPES} relevent officiellement de « Droits
     * fondamentaux » (14) et de « Democratie et droit de vote » (8).
     *
     * @param themeCode la thematique visee ({@code CIV_PRINCIPES}…)
     * @throws BusinessException si une unite de la thematique ne peut pas fournir
     *                           sa part. Meme regle que l'examen global : on leve,
     *                           on ne se degrade pas.
     */
    public List<Question> composerExamenDeTheme(String themeCode) {
        return composerExamenDeTheme(themeCode, false);
    }

    /**
     * @param deterministe {@code true} pour l'examen joue <b>sans compte</b> : tri
     *                     stable et melange a graine fixe, donc rejouer redonne
     *                     le meme examen (2026-09-24, comme le slot 1 CO / CE).
     *                     La composition — unites, parts, levee — est la meme.
     */
    public List<Question> composerExamenDeTheme(String themeCode, boolean deterministe) {
        List<CivicOfficialUnit> unites = unitManager.findAllDansLOrdreDuProgramme().stream()
                .filter(u -> u.getThemeCode().equals(themeCode))
                .toList();
        if (unites.isEmpty()) {
            throw new BusinessException(
                    "Thematique civique inconnue du programme : « " + themeCode + " ». "
                            + "L'annexe I de l'arrete du 10 octobre 2025 en compte cinq.");
        }

        Map<String, Integer> parts = partsDeLExamenDeTheme(unites);
        LinkedHashSet<Question> tirees = new LinkedHashSet<>(CivicExamFormat.QUESTIONS_THEME);
        List<UUID> exclues = new ArrayList<>(CivicExamFormat.QUESTIONS_THEME);

        for (CivicOfficialUnit unite : unites) {
            int part = parts.get(unite.getCode());
            if (part <= 0) continue;
            List<Question> lot = deterministe
                    ? tirerDansLOrdre(unite, exclues, part)
                    : tirerPourUneUnite(unite, exclues, part);
            if (lot.size() < part) {
                throw new BusinessException(
                        "Examen de theme « " + themeCode + " » non composable : l'unite « "
                                + unite.getLabel() + " » (" + unite.getCode() + ") exige " + part
                                + " question(s) au prorata de son quota officiel ("
                                + unite.getExamQuota() + " sur 40) et n'en fournit que "
                                + lot.size() + ".");
            }
            for (Question q : lot) {
                if (tirees.add(q)) exclues.add(q.getId());
            }
        }

        List<Question> examen = new ArrayList<>(tirees);
        if (deterministe) {
            Collections.shuffle(examen, new java.util.Random(themeCode.hashCode()));
        } else {
            Collections.shuffle(examen);
        }
        return examen;
    }

    /**
     * Le tirage <b>deterministe</b> d'une unite : memes deux chemins que
     * {@link #tirerPourUneUnite}, en tri stable. L'exclusion se fait ici — on lit
     * de quoi la couvrir, puis on ecarte les deja tirees.
     */
    private List<Question> tirerDansLOrdre(CivicOfficialUnit unite, List<UUID> exclues, int quota) {
        int lecture = quota + exclues.size();
        List<Question> ordonnees = unite.getQuestionType() == QuestionType.MISE_SITUATION
                ? questionManager.findOrderedMisesEnSituation(unite.getThemeCode(), lecture)
                : questionManager.findOrderedByOfficialUnit(unite.getId(), lecture);
        return ordonnees.stream()
                .filter(q -> !exclues.contains(q.getId()))
                .limit(quota)
                .toList();
    }

    /**
     * La part de chaque unite dans un examen de theme de
     * {@link CivicExamFormat#QUESTIONS_THEME} questions.
     *
     * <p>🛑 <b>Methode des plus forts restes</b>, et il en fallait une : les
     * quotas officiels d'une thematique ne divisent pas 20. « Principes » vaut
     * 3 + 2 + 6 = 11 ; au prorata, 20 questions donnent 5,45 / 3,64 / 10,91. On
     * plancher, puis on distribue le reste aux plus grandes parties decimales —
     * c'est la seule regle d'arrondi qui garantisse a la fois la somme exacte et
     * l'ordre des proportions.
     *
     * <p>⚠️ <b>Arrondir chaque part separement ne marche pas</b> : 5 + 4 + 11 = 20
     * par plus forts restes, mais l'arrondi naif donne 5 + 4 + 11 ici et
     * 8 + 8 + 5 = 21 en « Histoire ». Une somme fausse est un examen faux.
     *
     * <p>« Vivre dans la societe francaise » tombe juste : 1 + 1 + 1 + 1 = 4, donc
     * 5 questions par unite.
     */
    private Map<String, Integer> partsDeLExamenDeTheme(List<CivicOfficialUnit> unites) {
        int totalQuota = unites.stream().mapToInt(CivicOfficialUnit::getExamQuota).sum();
        int cible = CivicExamFormat.QUESTIONS_THEME;

        Map<String, Integer> parts = new java.util.LinkedHashMap<>();
        List<double[]> restes = new ArrayList<>();   // [index, partie decimale]
        int attribue = 0;
        for (int i = 0; i < unites.size(); i++) {
            double exact = (double) unites.get(i).getExamQuota() * cible / totalQuota;
            int plancher = (int) Math.floor(exact);
            parts.put(unites.get(i).getCode(), plancher);
            attribue += plancher;
            restes.add(new double[] {i, exact - plancher});
        }
        // Le reste va aux plus grandes parties decimales ; a egalite, a l'unite
        // qui vient d'abord dans l'annexe I -- un ordre stable, donc un examen
        // reproductible a proportions egales.
        restes.sort((a, b) -> Double.compare(b[1], a[1]));
        for (int k = 0; attribue < cible; k++, attribue++) {
            String code = unites.get((int) restes.get(k % restes.size())[0]).getCode();
            parts.merge(code, 1, Integer::sum);
        }
        return parts;
    }

    /**
     * La <b>thematique officielle</b> d'une question civique — celle de son
     * unite, jamais son {@code theme_id} (D-47).
     *
     * <p>🛑 <b>C'est l'autorite du thematique a l'affichage.</b> 22 questions ont
     * un {@code theme_id} qui contredit l'annexe I : l'egalite, les libertes de la
     * DDHC et la Republique comme regime sont rangees sous « Principes » par notre
     * taxonomie editoriale, et sous « Droits fondamentaux » / « Democratie et droit
     * de vote » par l'arrete. Le classement de l'arrete l'emporte : le notre vient
     * du corpus, comme les 46 notions qu'on a deja ecartees comme autorite.
     *
     * <p>⚠️ {@code null} si la question n'est pas taguee — elle n'est alors dans
     * <b>aucune</b> unite, donc dans aucune thematique du programme. C'est
     * precisement pourquoi l'unite ne peut pas devenir l'autorite la ou il faut
     * compter le corpus ENTIER, tagues et non tagues (cf. D-47, les trois
     * surfaces remontees).
     */
    /**
     * <b>L'unite officielle dont releve cette question</b> — l'autorite du
     * PROGRAMME (D-48), jamais {@code theme_id}.
     *
     * <p>Deux chemins, et un seul par question :
     * <ul>
     *   <li>une <b>connaissance taguee</b> porte sa notion, qui porte son
     *       unite ;</li>
     *   <li>une <b>mise en situation</b> ne porte JAMAIS de notion (D-35) : elle
     *       releve de l'unite de mises en situation de SON theme — et la, son
     *       {@code theme_id} <b>est</b> l'autorite, parce que l'unite MES se
     *       rejoint par le theme.</li>
     * </ul>
     *
     * <p>🛑 {@code null} dit « <b>hors programme</b> », jamais « Principes » :
     * une connaissance non taguee n'est dans aucune unite, et une mise en
     * situation hors Principes / Droits non plus — l'arrete ne leur donne de
     * quota que dans ces deux thematiques (D-29).
     */
    public CivicOfficialUnit uniteOfficielle(Question question) {
        if (question.getCivicNotion() != null
                && question.getCivicNotion().getOfficialUnit() != null) {
            return question.getCivicNotion().getOfficialUnit();
        }
        if (question.getQuestionType() == QuestionType.MISE_SITUATION
                && question.getTheme() != null) {
            return unitesParCode().values().stream()
                    .filter(unite -> unite.getQuestionType() == QuestionType.MISE_SITUATION)
                    .filter(unite -> unite.getThemeCode().equals(question.getTheme().getCode()))
                    .findFirst()
                    .orElse(null);
        }
        return null;
    }

    public String thematiqueOfficielle(Question question) {
        if (question.getCivicNotion() != null
                && question.getCivicNotion().getOfficialUnit() != null) {
            return question.getCivicNotion().getOfficialUnit().getThemeCode();
        }
        // 🛑 Une mise en situation ne porte JAMAIS de notion (D-35) : elle releve
        // de l'unite de mises en situation de SON theme, et la son `theme_id`
        // EST l'autorite -- l'unite MES se rejoint par le theme, pas par la notion.
        if (question.getQuestionType() == QuestionType.MISE_SITUATION) {
            return question.getTheme() == null ? null : question.getTheme().getCode();
        }
        // Une connaissance non taguee n'est dans aucune unite, donc dans aucune
        // thematique DU PROGRAMME. `null` dit « inconnu », jamais « Principes ».
        return null;
    }
}
