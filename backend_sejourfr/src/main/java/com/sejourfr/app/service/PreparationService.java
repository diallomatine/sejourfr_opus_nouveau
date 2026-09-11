package com.sejourfr.app.service;

import com.sejourfr.app.dto.PreparationDto;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.PreparationEtape;
import com.sejourfr.app.enums.TcfDiagnosticSectionState;
import com.sejourfr.app.enums.TcfDiagnosticStatus;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.CivicDiagnosticSessionManager;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.TcfDiagnosticSessionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticViewService;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticReadService;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * <b>Ou en sont les deux preparations du candidat</b> — l'etat unique.
 *
 * <h2>🛑 UN SEUL ETAT, TROIS PORTES</h2>
 * <p>L'Accueil (« quelle est ma prochaine action ? »), le Plan (« pourquoi
 * n'est-il pas encore pret ? ») et les Examens (« ou retrouver mon
 * diagnostic ? ») lisent tous les trois <b>ce</b> service. Trois ecrans qui
 * deduiraient chacun leur version finiraient par proposer trois choses
 * differentes au meme candidat — c'est exactement ce que l'arbitrage du
 * 2026-09-10 interdit.
 *
 * <h2>Asymetrie assumee</h2>
 * <p>Le TCF a <b>deux</b> diagnostics (rapide puis complet), le civique
 * <b>un</b>. Ce n'est pas une incoherence : le civique est du QCM
 * deterministe, rapide et sans cout LLM, un pre-diagnostic n'y apporterait rien
 * et dupliquerait le tunnel du TCF.
 *
 * <p>🛑 <b>Ce service ne calcule aucun niveau.</b> Il lit ce que les moteurs
 * existants servent deja et ne fait qu'assembler. Une seconde derivation du
 * palier finirait par contredire l'ecran de resultat.
 */
@Service
@RequiredArgsConstructor
public class PreparationService {

    private final UserManager userManager;
    private final DiagnosticSessionManager diagnosticSessionManager;
    private final TcfDiagnosticSessionManager tcfDiagnosticManager;
    private final TcfDiagnosticReadService tcfReadService;
    private final TcfDiagnosticService tcfDiagnosticService;
    private final CivicDiagnosticSessionManager civicDiagnosticManager;
    private final CivicDiagnosticViewService civicViewService;
    private final com.sejourfr.app.service.diagnostic.DiagnosticContentResolver content;

    @Transactional(readOnly = true)
    public PreparationDto lire(UUID userId) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));
        return new PreparationDto(tcf(userId, user), civique(userId));
    }

    /**
     * Le TCF : rapide, puis complet, puis plan.
     *
     * <p>🛑 <b>Le diagnostic complet n'est plus un prerequis d'acces au
     * Plan</b> (arbitrage du proprietaire, 2026-09-12). Des que le diagnostic
     * <b>rapide</b> est clos, le Plan existe : {@code planDisponible} passe a
     * vrai, et le complet devient un moyen de l'<b>affiner</b>.
     *
     * <p>⚠️ Le commentaire precedent — « construire un plan sur le rapide
     * reviendrait a decider de l'oral et des deux comprehensions sans les avoir
     * mesures » — se trompait de cible. Le moteur n'a <b>jamais</b> fait ca :
     * {@code PlanAcquisitionSelector} n'ouvre un domaine que s'il a « deja ete
     * mesure », et {@code LearningPlanPriorityResolver} ne travaille que sur
     * des observations reelles. Un domaine que le rapide n'a pas touche reste
     * <b>inconnu</b> — il ressort dans {@code domainesAEvaluer} (« A evaluer »),
     * jamais en fragilite. C'etait donc cette porte-ci, et elle seule, qui
     * privait le candidat d'un plan vrai.
     */
    private PreparationDto.ModulePreparation tcf(UUID userId, User user) {
        NiveauCecrl cible = tcfDiagnosticService.cible(user).orElse(null);

        // 🛑 Le diagnostic RAPIDE clos se lit INDEPENDAMMENT de l'etape, et
        // avant elle. Il decidait autrefois de l'etape seulement quand aucun
        // complet n'existait ; des que le complet demarrait, son identifiant
        // disparaissait de la reponse et son rapport — le seul resultat que le
        // candidat possede alors — devenait introuvable pour les fronts. Le
        // fait « une estimation existe » ne depend pas de l'etape courante.
        // Cout : une lecture indexee de plus, assumee, parce qu'un champ qui
        // ne dit vrai qu'a certaines etapes finit par etre lu aux autres.
        UUID estimation = diagnosticSessionManager.findLatestCompleted(userId)
                .map(DiagnosticSession::getId)
                .orElse(null);

        // 🛑 LE PLAN EXISTE DES QUE LE RAPIDE EST CLOS — et cette ligne rend,
        // mot pour mot, la condition de LearningPlanService.get() (« un
        // DiagnosticSession COMPLETED existe-t-il ? »). Ne pas la remplacer par
        // une lecture de `etape` : un ecran qui promettrait un plan que le
        // moteur refuse de construire est exactement la contradiction que
        // l'etat unique existe pour empecher.
        boolean planDisponible = estimation != null;

        // --- Le diagnostic COMPLET decide de l'etape des qu'il existe.
        Optional<TcfDiagnosticSession> complet = tcfDiagnosticManager.findLatest(userId);
        if (complet.isPresent()) {
            TcfDiagnosticSession session = complet.get();
            List<TcfDiagnosticReadService.Section> sections = tcfReadService.sections(session);
            int terminees = (int) sections.stream()
                    .filter(s -> s.etat() == TcfDiagnosticSectionState.TERMINEE)
                    .count();
            boolean clos = session.getStatus() == TcfDiagnosticStatus.COMPLETED;
            return new PreparationDto.ModulePreparation(
                    clos ? PreparationEtape.PLAN_PRET : PreparationEtape.DIAGNOSTIC_EN_COURS,
                    terminees,
                    sections.size(),
                    session.getId(),
                    clos ? tcfReadService.niveauGlobal(sections).orElse(null) : null,
                    cible,
                    null,
                    estimation,
                    planDisponible,
                    // Ou l'on reprend : la premiere epreuve non terminee, dans
                    // l'ordre serveur. 🛑 Rien a reprendre quand le complet est
                    // clos — et surtout pas la premiere epreuve, qui relancerait
                    // le diagnostic depuis le debut.
                    clos ? null : prochaineEpreuve(sections));
        }

        // --- Sinon, le diagnostic RAPIDE porte l'etape lui-meme.
        if (estimation != null) {
            return new PreparationDto.ModulePreparation(
                    PreparationEtape.ESTIMATION_FAITE,
                    // Le complet n'a jamais demarre : ZERO epreuve sur QUATRE.
                    // C'est un fait, pas un decor — et c'est le serveur qui
                    // porte le denominateur, jamais le front.
                    0, TcfDiagnosticReadService.EPREUVES.size(),
                    estimation, null, cible, null, estimation,
                    true,
                    // 🛑 Aucune « prochaine epreuve » : le complet n'a pas encore
                    // de sous-epreuves tirees, en nommer une serait l'inventer.
                    null);
        }

        // 🛑 La session du diagnostic rapide se retrouve par (code, version) —
        // c'est l'unicite que le depot garantit, et c'est la MEME autorite de
        // contenu que le reste du parcours. La chercher autrement risquerait de
        // rendre une session d'une version que le candidat n'a jamais vue.
        String code = content.activeCode();
        Optional<DiagnosticSession> enCours = diagnosticSessionManager
                .findByUserAndVersionWithContent(userId, code, content.activeVersion(code))
                .filter(d -> d.getStatus() != DiagnosticSessionStatus.COMPLETED);
        return enCours
                .map(session -> new PreparationDto.ModulePreparation(
                        PreparationEtape.DIAGNOSTIC_EN_COURS,
                        null, null, session.getId(), null, cible, null, null, false, null))
                .orElseGet(() -> new PreparationDto.ModulePreparation(
                        PreparationEtape.DIAGNOSTIC_A_FAIRE,
                        null, null, null, null, cible, null, null, false, null));
    }

    /**
     * Par ou « Continuer le diagnostic » reprend : la premiere epreuve non
     * terminee, dans l'ordre serveur des 4 epreuves.
     *
     * <p>🛑 Une section <b>absente du tirage</b> (mode degrade : aucun audio CO,
     * aucun sujet EO) est {@code A_FAIRE} et reste donc candidate — elle n'a pas
     * echoue, elle n'a pas ete jouee. {@code null} quand les quatre sont
     * terminees.
     */
    private static EpreuveType prochaineEpreuve(List<TcfDiagnosticReadService.Section> sections) {
        return sections.stream()
                .filter(s -> s.etat() != TcfDiagnosticSectionState.TERMINEE)
                .map(TcfDiagnosticReadService.Section::epreuve)
                .findFirst()
                .orElse(null);
    }

    /**
     * Le civique : <b>un seul</b> diagnostic, puis le plan.
     *
     * <p>🛑 {@code aRenforcer} reste {@code null} tant qu'aucun diagnostic
     * n'est clos : {@code 0} voudrait dire « tout est deja solide », ce qui est
     * une tout autre nouvelle que « on n'a rien mesure ».
     */
    private PreparationDto.ModulePreparation civique(UUID userId) {
        Optional<CivicDiagnosticSession> session = civicDiagnosticManager.findLatest(userId);
        if (session.isEmpty()) {
            return new PreparationDto.ModulePreparation(
                    PreparationEtape.DIAGNOSTIC_A_FAIRE,
                    null, null, null, null, null, null, null, false, null);
        }

        CivicDiagnosticSession diagnostic = session.get();
        var vue = civicViewService.vue(diagnostic);
        if (diagnostic.getStatus() != TcfDiagnosticStatus.COMPLETED) {
            return new PreparationDto.ModulePreparation(
                    PreparationEtape.DIAGNOSTIC_EN_COURS,
                    vue.repondues(), vue.total(), diagnostic.getId(),
                    null, null, null, null, false, null);
        }

        int aRenforcer = (int) civicViewService.resultat(diagnostic).themes().stream()
                .filter(t -> t.etat() == CivicThemeState.FAIBLE
                        || t.etat() == CivicThemeState.A_RENFORCER)
                .count();
        // Le civique n'a qu'UN diagnostic : son plan existe des qu'il est clos,
        // et il n'y a jamais rien a « affiner » derriere.
        return new PreparationDto.ModulePreparation(
                PreparationEtape.PLAN_PRET,
                vue.repondues(), vue.total(), diagnostic.getId(),
                null, null, aRenforcer, null, true, null);
    }
}
