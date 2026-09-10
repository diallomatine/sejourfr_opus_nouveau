package com.sejourfr.app.service.diagnosticcivique;

import com.sejourfr.app.config.CivicDiagnosticProperties;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.ThemeManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Le tirage des 24 questions du diagnostic civique (20_ §4.2).
 *
 * <h2>Ce que la composition garantit, et pourquoi</h2>
 * <ul>
 *   <li><b>Couverture equilibree sur les 5 themes</b>, avec un minimum par
 *       theme. 🛑 Contrainte explicite de la spec : « <b>ne jamais evaluer un
 *       theme sur une seule question</b> ». Un theme juge sur une reponse
 *       produirait un etat qui ne veut rien dire, et c'est cet etat qui decide
 *       ensuite du plan.</li>
 *   <li><b>Des mises en situation comptees a part</b> (~29 %, le ratio de
 *       l'examen reel). Appliquer une regle a un cas concret est une competence
 *       distincte de la restituer.</li>
 *   <li><b>La mention du candidat seule</b> : un CSP ne doit pas etre mesure sur
 *       des questions de naturalisation.</li>
 * </ul>
 *
 * <h2>Mode degrade (20_ §3.4)</h2>
 * <p>🛑 <b>Un catalogue sous-dote ne fait jamais echouer le diagnostic.</b> Si
 * un theme n'a pas assez de questions sur cette mention, on prend ce qu'il y a
 * et le theme ressortira « non evalue » ou mesure sur moins de questions — ce
 * qui est <b>honnete</b>. Refuser d'ouvrir le diagnostic priverait le candidat
 * de tout, y compris de ce qui etait mesurable.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class CivicDiagnosticComposer {

    private final ThemeManager themeManager;
    private final QuestionManager questionManager;
    private final CivicDiagnosticProperties props;

    /**
     * Les questions du diagnostic, deja melangees.
     *
     * @param mention la demarche du candidat ({@code CSP} / {@code CR} /
     *                {@code NAT})
     */
    public List<Question> composer(Difficulty mention) {
        Set<UUID> pris = new HashSet<>();
        List<Question> questions = new ArrayList<>(
                props.getConnaissances() + props.getMisesEnSituation());

        // --- 1. Le plancher par theme d'abord. Il passe AVANT le complement :
        // remplir au hasard puis esperer que chaque theme soit servi laisserait
        // regulierement un theme a une seule question.
        List<Theme> themes = themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE);
        for (Theme theme : themes) {
            ajouter(questions, pris, questionManager.findRandomExcluding(
                    Module.CIVIQUE, theme.getId(), mention,
                    QuestionType.CONNAISSANCE, pris, props.getMinParTheme()));
        }

        // --- 2. Le complement de connaissances, tous themes confondus.
        int manque = props.getConnaissances() - questions.size();
        if (manque > 0) {
            ajouter(questions, pris, questionManager.findRandomExcluding(
                    Module.CIVIQUE, null, mention, QuestionType.CONNAISSANCE, pris, manque));
        }

        // --- 3. Les mises en situation, tirees a part : c'est ce qui permet de
        // les compter separement a l'arrivee.
        ajouter(questions, pris, questionManager.findRandomExcluding(
                Module.CIVIQUE, null, mention, QuestionType.MISE_SITUATION, pris,
                props.getMisesEnSituation()));

        if (questions.size() < props.getConnaissances() + props.getMisesEnSituation()) {
            // Mode degrade assume : on le TRACE, on ne bloque pas. Le candidat
            // aura un diagnostic plus court, et les themes non servis diront
            // « non evalue » plutot qu'un verdict invente.
            log.warn("Diagnostic civique sous-dote pour la mention {} : {} questions sur {}",
                    mention, questions.size(),
                    props.getConnaissances() + props.getMisesEnSituation());
        }

        // Sans ce remelange, le candidat enchainerait les themes dans l'ordre,
        // puis toutes les mises en situation d'affilee.
        Collections.shuffle(questions);
        return questions;
    }

    private static void ajouter(
            List<Question> cible, Set<UUID> pris, List<Question> candidates) {
        for (Question question : candidates) {
            if (pris.add(question.getId())) {
                cible.add(question);
            }
        }
    }
}
