package com.sejourfr.app.enums;

import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Optional;
import java.util.Set;

/**
 * Les <b>ecrans metier</b> dont on compte l'affichage ({@code SCREEN_VIEWED},
 * chantier « Activite utilisateurs », D7) — <b>autorite unique</b> de leur
 * chemin suivi et de leur libelle. {@code AnalyticsPaths.KNOWN} s'en nourrit :
 * un ecran declare ici est admis a l'ingestion, et seulement lui.
 *
 * <p>Les chemins sont des <b>gabarits</b>, jamais des URL concretes : un
 * segment dynamique est un {@code :param} en minuscules (la normalisation de
 * {@code AnalyticsPaths} met tout en minuscules). Un meme ecran a un chemin web
 * et un chemin app distincts quand les deux fronts n'ont pas la meme route ;
 * {@code null} = l'ecran n'existe pas sur ce front.
 *
 * <p>Ajouter un ecran = une constante ici <b>et</b> une ligne dans le front
 * concerne, dans la meme passe. Libelles geles par {@code AnalyticsLabelsTest}.
 */
public enum TrackedScreen {

    VITRINE("Vitrine", "/", null),
    LANDING_REUSSIR("Landing « Réussir »", "/reussir", null),
    ACCUEIL("Accueil", "/dashboard", "/home"),
    CONNEXION("Connexion", "/connexion", "/login"),
    INSCRIPTION("Inscription", "/inscription", "/register"),
    DIAGNOSTIC_TCF("Diagnostic TCF rapide", "/diagnostic", "/diagnostic"),
    DIAGNOSTIC_TCF_RESULTAT("Résultat du diagnostic TCF", "/diagnostic/resultat", null),
    DIAGNOSTIC_CIVIQUE("Diagnostic civique", "/diagnostic-civique", "/diagnostic-civique"),
    DIAGNOSTIC_CIVIQUE_RESULTAT("Résultat du diagnostic civique", "/diagnostic-civique/resultat",
            "/diagnostic-civique/resultat"),
    PLAN("Plan", "/plan", "/plan"),
    PLAN_ETAPE("Étape du Plan", "/plan/etape/:id", "/plan/etape/:id"),
    PLAN_DOMAINE("Domaine du Plan", "/plan/domaine/:domaine", "/plan/domaine/:domaine"),
    PLAN_DEBLOQUER("Débloquer le Plan", "/plan/debloquer", "/plan/debloquer"),
    PLAN_PROGRESSION("Cycles du Plan", "/plan/progression", "/plan/progression"),
    PROGRESSION_TCF("Ma progression TCF", "/progression/tcf", "/progression/tcf"),
    PROGRESSION_TCF_EPREUVE("Progression d'une épreuve", "/progression/tcf/:epreuve", "/progression/tcf/:epreuve"),
    PROGRESSION_CIVIQUE("Ma progression civique", "/progression/civique", "/progression/civique"),
    PROGRESSION_CIVIQUE_THEME("Progression d'un thème", "/progression/civique/:theme",
            "/progression/civique/:theme"),
    REVISER("Réviser", "/entrainement", "/reviser"),
    THEME_CIVIQUE("Thème civique", "/entrainement/civique/:theme", "/civique/theme/:theme"),
    EPREUVE_TCF("Épreuve TCF (CO, CE, structure)", "/entrainement/tcf/:epreuve", "/tcf/:epreuve"),
    LOTS_NIVEAU("Lots par niveau", "/entrainement/tcf/:epreuve/:niveau", "/tcf/:epreuve/niveau/:niveau"),
    EE_HUB("Expression écrite", "/entrainement/tcf/ee", "/tcf/ee"),
    EO_HUB("Expression orale", "/entrainement/tcf/eo", "/tcf/eo"),
    EE_TACHE("Tâche d'expression écrite", "/entrainement/tcf/ee/tache/:tache", "/tcf/ee/tache/:tache"),
    EO_TACHE("Tâche d'expression orale", "/entrainement/tcf/eo/tache/:tache", "/tcf/eo/tache/:tache"),
    COMPETENCES_TACHE("Compétences d'une tâche", "/entrainement/tcf/:epreuve/tache/:tache/competences",
            "/tcf/:epreuve/tache/:tache/competences"),
    SEANCE_QCM("Séance d'entraînement", "/sessions/:id", "/runner/:id"),
    RESULTAT_EE("Résultat d'expression écrite", "/entrainement/tcf/ee/resultats/:id",
            "/tcf/expression-ecrite/resultats/:id"),
    RESULTAT_EO("Résultat d'expression orale", "/entrainement/tcf/eo/resultats/:id",
            "/tcf/expression-orale/resultats/:id"),
    EXAMENS_BLANCS("Examens blancs", "/examens-blancs", "/examens"),
    EXAMEN_TCF("Examen blanc TCF complet", "/examens-blancs/tcf/:id", "/tcf/examen-blanc/:id"),
    EXAMEN_TCF_BILAN("Bilan d'examen blanc", "/examens-blancs/tcf/:id/bilan", "/tcf/examen-blanc/:id/bilan"),
    TARIFS("Tarifs", "/tarifs", null),
    PAIEMENT("Paiement", "/paiement", null),
    PROFIL("Profil", "/profil", "/profile");

    private final String label;
    private final String webPath;
    private final String appPath;

    TrackedScreen(String label, String webPath, String appPath) {
        this.label = label;
        this.webPath = webPath;
        this.appPath = appPath;
    }

    public String getLabel() { return label; }

    /** Chemin suivi cote web, {@code null} si l'ecran n'existe pas sur le web. */
    public String getWebPath() { return webPath; }

    /** Chemin suivi cote app, {@code null} si l'ecran n'existe pas dans l'app. */
    public String getAppPath() { return appPath; }

    /** Tous les chemins declares (web puis app), sans doublon. */
    public static Set<String> allPaths() {
        Set<String> paths = new LinkedHashSet<>();
        for (TrackedScreen screen : values()) {
            if (screen.webPath != null) paths.add(screen.webPath);
            if (screen.appPath != null) paths.add(screen.appPath);
        }
        return Collections.unmodifiableSet(paths);
    }

    /** L'ecran dont c'est le chemin web ({@code app = false}) ou app ({@code app = true}). */
    public static Optional<TrackedScreen> byPath(String path, boolean app) {
        if (path == null) return Optional.empty();
        return Arrays.stream(values())
                .filter(s -> path.equals(app ? s.appPath : s.webPath))
                .findFirst();
    }
}
