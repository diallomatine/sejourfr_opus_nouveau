package com.sejourfr.app.dto;

import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.service.plancivique.CivicEtapeEtat;
import com.sejourfr.app.service.plancivique.CivicMaitrise;
import com.sejourfr.app.service.plancivique.CivicPlanGrain;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * <b>Le plan civique</b> (L10, {@code 20_} §6).
 *
 * <h2>Ce que ce DTO sert, et ce qu'il ne sert pas</h2>
 *
 * <p>🛑 <b>Des FAITS, jamais des phrases.</b> Aucun {@code reason_text} n'est
 * calcule ici, contrairement au schema de {@code 20_} §10 : les libelles vivent
 * dans les fronts, en miroir mot pour mot l'un de l'autre, comme pour le
 * diagnostic civique. Un texte compose serveur ne se traduit pas, ne se
 * relit pas dans deux mises en page differentes, et se dupliquerait de toute
 * facon des qu'un ecran voudrait le dire autrement.
 *
 * <p>🛑 <b>Rien n'est persiste.</b> Il n'existe ni table {@code civic_plan}, ni
 * {@code civic_plan_item}, ni {@code user_civic_notion_progress} : tout est
 * <b>relu</b> a chaque appel depuis l'historique des reponses. Le detail et ce
 * que ca rapporte : {@code CivicLeitnerResolver}.
 *
 * <p>🛑 <b>Le freemium porte sur l'ACTION, pas sur le constat.</b> Les priorites
 * sont servies entieres a tout le monde ({@code 20_} §6, variante non abonne) ;
 * c'est la serie ciblee qui porte {@code locked}. Un front ne deduit jamais un
 * verrou d'un rang.
 *
 * @param disponible      {@code false} quand aucun diagnostic civique n'est
 *                        termine. Le plan ne se batit pas sur une mesure qui
 *                        n'existe pas — l'appelant ouvre alors la seule porte
 *                        qui debloque
 * @param mention         la demarche sur laquelle le candidat est mesure
 * @param resultat        la derniere mesure comparable au seuil, ou {@code null}
 * @param prochaine       « A faire maintenant » : la cible de rang 1, ou
 *                        {@code null} si rien n'est proposable
 * @param priorites       les cibles a travailler, du plus couteux au moins.
 *                        🛑 <b>Plafond d'AFFICHAGE</b> : le moteur en a classe
 *                        davantage, et {@code autresPriorites} les compte
 * @param autresPriorites ce que la liste ne montre pas (« + 6 autres notions a
 *                        consolider »)
 * @param aRevoir         revisions d'entretien : des cibles maitrisees dont
 *                        l'echeance est franchie. 🛑 <b>Jamais une priorite
 *                        rouge</b> ({@code 20_} §5.2)
 * @param solides         ce qui est acquis, dit pour ce que ca vaut : le
 *                        candidat n'a pas besoin de tout reviser
 * @param grain           voir {@link Grain}
 */
public record CivicPlanDto(
        boolean disponible,
        Difficulty mention,
        Resultat resultat,
        Cible prochaine,
        List<Cible> priorites,
        int autresPriorites,
        List<Cible> aRevoir,
        List<Cible> solides,
        Grain grain,
        Instant calculeA
) {

    /**
     * La derniere mesure <b>comparable au seuil</b>.
     *
     * <p>🛑 <b>C'est le diagnostic, pas une estimation courante.</b>
     * {@code 20_} §6 bloc 1 parle d'un « resultat estime aujourd'hui » derive
     * des « dernieres reponses » : on ne le fabrique pas. Melanger des series
     * d'entrainement (correction immediate, questions choisies) a un examen
     * produirait un nombre qui ressemble a un score sans en etre un. Le
     * diagnostic, lui, pose le format entier : son score EST le resultat.
     *
     * @param bonnes  bonnes reponses du diagnostic
     * @param posees  questions reellement posees
     * @param seuil   32, la regle de l'epreuve — servi pour que l'ecran le DISE
     *                sans le connaitre
     * @param format  40, le format de l'epreuve
     */
    public record Resultat(int bonnes, int posees, int seuil, int format, Instant mesureA) {
    }

    /**
     * L'etat du tagging, et ce qu'il autorise.
     *
     * <p>🛑 <b>Le grain se MESURE, il ne se decrete pas</b> ({@code 20_} §3.3).
     * Au lancement de L10, 0 question civique sur 1 016 est taguee : les cinq
     * themes sont donc au grain {@code THEME}. C'est le mode <b>prevu</b> par la
     * spec (phase 1), et l'ecran le dit — il ne fait pas semblant de travailler
     * par notion.
     *
     * @param courant         {@code NOTION} seulement quand <b>tous</b> les
     *                        themes ont bascule. Le plan ne se dit pas plus
     *                        precis qu'il ne l'est
     * @param themesParNotion themes deja bascules
     * @param themesTotal     themes civiques
     * @param taguees         questions civiques actives deja taguees
     * @param total           questions civiques actives
     */
    public record Grain(
            CivicPlanGrain courant,
            int themesParNotion,
            int themesTotal,
            long taguees,
            long total) {
    }

    /**
     * Une cible du plan : une <b>notion</b>, ou un <b>theme</b> tant que le
     * tagging de ce theme n'a pas franchi le seuil.
     *
     * <p>🛑 <b>Tout est derive, rien n'est fige.</b> {@code boite},
     * {@code maitrise} et {@code prochaineRevue} se replient sur l'historique
     * des reponses a chaque lecture : le jour ou une question recoit sa notion,
     * les reponses deja donnees comptent pour elle.
     *
     * @param grain             a quel grain cette cible est travaillee
     * @param themeId           son theme, toujours present — au grain THEME,
     *                          {@code id} et {@code themeId} sont le meme
     * @param etatDuTheme       l'etat servi par le dernier diagnostic.
     *                          🛑 {@code NON_EVALUE} n'est pas « faible »
     * @param maitrise          l'etat pedagogique. 🛑 <b>Servi</b> : aucun front
     *                          ne classe un compteur en etat
     * @param boite             la boite Leitner (1 a 5). 🛑 <b>Ne s'affiche
     *                          jamais</b> ({@code 30_} §510) : elle est servie
     *                          pour l'admin et les tests. Ce que l'ecran montre,
     *                          c'est {@code parcours}
     * @param parcours          <b>ou en est le candidat</b>, etape par etape —
     *                          exactement 5 etats, du premier au dernier. 🛑
     *                          C'est ce qui rend l'effet Leitner <b>visible</b>
     *                          sans publier un numero de boite. Les libelles des
     *                          etapes sont geles cote front : ce DTO sert des
     *                          faits, jamais des phrases
     * @param reponses          reponses enregistrees sur cette cible
     * @param correctes         dont justes
     * @param erreursRecentes   erreurs sur 30 jours (ce que le score compte)
     * @param derniereErreur    {@code null} s'il n'y en a jamais eu
     * @param prochaineRevue    l'echeance Leitner. {@code null} = jamais vue,
     *                          donc jamais « en retard »
     * @param aRevoir           l'echeance est franchie
     * @param score             le rang chiffre ({@code 20_} §5.3). Servi pour
     *                          l'admin et les tests, jamais montre au candidat :
     *                          un score de priorite invite a comparer deux
     *                          nombres qui ne mesurent pas la meme chose
     * @param contenuInsuffisant  moins de questions que le minimum, POUR SA
     *                            MENTION. Une telle cible n'est jamais servie en
     *                            priorite ({@code 20_} §3.4)
     * @param questionsSerie    la taille de la serie ciblee proposee
     * @param dureeEstimeeSec   son ordre de grandeur, <b>derive</b> de la taille
     * @param locked            la serie est-elle reservee ? 🛑 Le constat, lui,
     *                          n'est jamais verrouille
     */
    public record Cible(
            UUID id,
            String code,
            String label,
            CivicPlanGrain grain,
            UUID themeId,
            String themeCode,
            String themeLabel,
            CivicThemeState etatDuTheme,
            CivicMaitrise maitrise,
            int boite,
            List<CivicEtapeEtat> parcours,
            int reponses,
            int correctes,
            int erreursRecentes,
            Instant derniereErreur,
            Instant prochaineRevue,
            boolean aRevoir,
            int score,
            boolean contenuInsuffisant,
            int questionsSerie,
            int dureeEstimeeSec,
            boolean locked
    ) {
    }
}
