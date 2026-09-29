package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.config.DiagnosticProperties;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.manager.ProductionTaskManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Source unique du <em>contenu</em> du diagnostic : le code actif, sa version
 * active, ses sujets et leurs textes d'accompagnement.
 *
 * <p>Trois appelants la partagent — la création d'une session
 * ({@link DiagnosticSessionCreator}), sa restitution ({@link DiagnosticService})
 * et la lecture publique ({@link PublicDiagnosticService}). Ils doivent servir
 * exactement les mêmes sujets : un visiteur rédige sans compte, puis s'inscrit
 * et sa session est créée. Si les deux chemins résolvaient la version
 * séparément, une bascule de version entre les deux appels ferait soumettre une
 * production écrite pour un sujet que le candidat n'a jamais lu.
 *
 * <p>Cette classe ne connaît ni utilisateur, ni session : elle ne lit que le
 * catalogue seed-only ({@code diagnostic_code IS NOT NULL}).
 *
 * <h2>La FORME du diagnostic est une donnée, pas un drapeau (L3)</h2>
 * <p>Un diagnostic a une étape orale <b>si et seulement si</b> son couple
 * (code, version) porte un sujet {@code TCF_EO} actif. {@code INITIAL_TCF} v1
 * en a un ; {@code QUICK_TCF} v1 n'en a pas. Aucun booléen de configuration ne
 * double cette information : elle serait alors capable de contredire le
 * contenu réellement servi, et un candidat se verrait réclamer une production
 * orale dont le sujet n'existe pas.
 *
 * <p>C'est aussi ce qui rend le retour arrière gratuit — reposer
 * {@code sejourfr.diagnostic.initial-code} suffit, sans migration.
 */
@Component
@RequiredArgsConstructor
public class DiagnosticContentResolver {

    /** Accompagnement de l'étape écrite, identique sur la surface publique et authentifiée. */
    public static final String WRITTEN_HELPER =
            "Cet exercice nous aide à observer plusieurs compétences en une seule production.";

    /** Accompagnement de l'étape orale : le diagnostic est enregistré, pas dialogué. */
    public static final String ORAL_HELPER =
            "Enregistrez votre réponse : ce diagnostic n'utilise pas de conversation en temps réel.";

    private final DiagnosticProperties properties;
    private final ProductionTaskManager taskManager;

    /** Code du diagnostic servi aujourd'hui ({@code QUICK_TCF} par défaut). */
    public String activeCode() {
        return properties.getInitialCode();
    }

    /** Dernière version active de ce code. Absente = seed non appliqué (500 assumé). */
    public int activeVersion(String code) {
        return taskManager.findLatestActiveDiagnosticVersion(code)
                .orElseThrow(() -> new IllegalStateException("Aucun diagnostic actif : " + code));
    }

    /**
     * Le pool des sujets écrits de cette version, ordre déterministe. Jamais
     * vide : un diagnostic sans production écrite n'est pas un diagnostic.
     */
    public List<ProductionTask> writtenPool(String code, int version) {
        List<ProductionTask> pool =
                taskManager.findActiveDiagnosticPool(code, version, EpreuveType.TCF_EE);
        if (pool.isEmpty()) {
            throw new IllegalStateException(
                    "Aucun sujet écrit actif pour le diagnostic " + code + " v" + version);
        }
        return pool;
    }

    /**
     * <b>Tire</b> un sujet écrit au hasard dans le pool (10_ §3.3).
     *
     * <p>Le tirage vit ici et nulle part ailleurs : c'est la lecture publique
     * qui l'effectue, une fois, et le sujet tiré est ensuite <b>transmis</b> à
     * la création de session. Retirer au sort à la création donnerait au
     * candidat un énoncé différent de celui qu'il vient de lire et de traiter.
     */
    public ProductionTask drawWrittenTask(String code, int version) {
        List<ProductionTask> pool = writtenPool(code, version);
        return pool.get(ThreadLocalRandom.current().nextInt(pool.size()));
    }

    /**
     * Le sujet écrit <b>demandé</b> par le client, s'il appartient bien au pool
     * actif ; sinon un tirage.
     *
     * <p>🛑 <b>L'appartenance au pool est vérifiée serveur.</b> Un identifiant
     * reçu du client ne désigne jamais une tâche arbitraire du catalogue :
     * ce serait ouvrir le diagnostic sur n'importe quelle tâche officielle du
     * TCF, avec une allowlist de compétences qui n'est pas la sienne.
     *
     * <p>Un identifiant inconnu ne fait pas échouer le parcours : il retombe
     * sur un tirage. Le candidat qui reprend une rédaction sur un sujet
     * désactivé entre-temps ne doit pas se retrouver bloqué.
     */
    public ProductionTask writtenTaskOrDraw(String code, int version, UUID requested) {
        List<ProductionTask> pool = writtenPool(code, version);
        if (requested != null) {
            for (ProductionTask task : pool) {
                if (task.getId().equals(requested)) {
                    return task;
                }
            }
        }
        return pool.get(ThreadLocalRandom.current().nextInt(pool.size()));
    }

    /**
     * Le sujet écrit unique de cette version.
     *
     * <p>Conservé pour les diagnostics à un seul énoncé ; sur un pool, il rend
     * le premier dans l'ordre déterministe. Préférer
     * {@link #writtenTaskOrDraw} sur tout chemin candidat.
     */
    public ProductionTask writtenTask(String code, int version) {
        return writtenPool(code, version).getFirst();
    }

    /**
     * Le sujet oral, <b>s'il y en a un</b>.
     *
     * <p>🛑 {@code Optional.empty()} n'est pas une anomalie : c'est le
     * diagnostic rapide (L3), qui n'a qu'une production écrite. Ne jamais le
     * remplacer par un {@code orElseThrow} « pour simplifier ».
     */
    public Optional<ProductionTask> oralTask(String code, int version) {
        return taskManager.findActiveDiagnosticPool(code, version, EpreuveType.TCF_EO)
                .stream().findFirst();
    }

    /** Ce diagnostic comporte-t-il une étape orale ? Lu sur le contenu, jamais configuré. */
    public boolean hasOral(String code, int version) {
        return oralTask(code, version).isPresent();
    }

    /** Accompagnement à afficher pour l'épreuve d'un sujet diagnostic. */
    public static String helperText(EpreuveType epreuve) {
        return epreuve == EpreuveType.TCF_EE ? WRITTEN_HELPER : ORAL_HELPER;
    }
}
