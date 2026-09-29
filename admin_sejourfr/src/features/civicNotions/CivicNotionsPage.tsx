import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { civicNotionsApi } from "../../api/civicNotionsApi";
import { PageHeader } from "../../components/ui/PageHeader";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import type {
  CivicNotionDto,
  CivicTaggingGesteVerdict,
  CivicTaggingQuestion,
  CivicTaggingSuggestion,
} from "../../types/api";
import tableStyles from "../../components/ui/DataTable.module.css";
import styles from "./CivicNotionsPage.module.css";

/**
 * `50_` §6.1.2 : commencer par les thèmes les mieux dotés pour **calibrer la
 * méthode** avant `CIV_PRINCIPES`, plus petit et plus sujet aux recouvrements.
 * L'ordre de cette liste est donc l'ordre de travail recommandé, pas
 * l'alphabet.
 */
/**
 * 🛑 `""` = TOUS LES THÈMES, et ce n'est pas un confort.
 *
 * Une campagne de pré-tagging ne suit pas le découpage par thème : le pilote
 * v4 portait sur « Droits et devoirs » ET « Vivre en société ». Un écran qui
 * s'ouvre sur un thème fixe montre alors une file vide et laisse croire qu'il
 * n'y a rien à relire — c'est arrivé, à 46 questions en attente.
 */
const THEMES = [
  { code: "", label: "Tous les thèmes" },
  { code: "CIV_HISTOIRE_GEO", label: "Histoire, géo et culture" },
  { code: "CIV_INSTITUTIONS", label: "Institutions" },
  { code: "CIV_DROITS_DEVOIRS", label: "Droits et devoirs" },
  { code: "CIV_SOCIETE", label: "Vivre en société" },
  { code: "CIV_PRINCIPES", label: "Principes et valeurs" },
] as const;

const PAGE = 25;

/**
 * Seuils de lecture de `50_` §6.1 — **affichage uniquement**.
 *
 * 🛑 Ils ne sont appliqués nulle part côté serveur, et c'est voulu : la règle
 * dégrade **par notion ET par mention**, et le serveur sert les comptes pour
 * que chaque appelant tranche pour SA mention. Ici on les utilise seulement
 * pour colorer une ligne du tableau de couverture.
 */
const SEUIL_PLEINEMENT_UTILISABLE = 5;
const SEUIL_CANDIDATE_FUSION = 12;

/** Au-dessus, le modèle est sûr de lui ; en dessous, la relecture est le vrai travail. */
const CONFIANCE_FORTE = 0.8;
const CONFIANCE_MOYENNE = 0.55;

const LETTRES = ["A", "B", "C", "D", "E", "F"];

/**
 * 🛑 Ce que le SERVEUR a écrit, jamais ce que le client croit avoir fait :
 * `VALIDATED` / `CORRECTED` sont sa décision. Une valeur inconnue d'un backend
 * plus récent se lit « Déjà relue » plutôt que de casser la carte.
 */
const VERDICTS: Record<string, string> = {
  VALIDATED: "Déjà relue · suggestion retenue",
  CORRECTED: "Déjà relue · corrigée à la main",
  REJECTED: "Déjà relue · aucune notion ne convenait",
  SKIPPED: "Déjà vue · laissée en attente",
};

/**
 * ⚠️ Le MÊME verdict serveur ne dit pas la même chose selon la suggestion qui
 * le porte. Un `VALIDATED` posé sur une suggestion « aucune notion » ne veut
 * pas dire « une notion a été retenue » : il veut dire que le relecteur a
 * **confirmé un trou du référentiel**. Sans cette table, le badge mentirait sur
 * ce qui s'est passé la veille — exactement ce qu'il existe pour éviter.
 */
const VERDICTS_AUCUNE_NOTION: Record<string, string> = {
  VALIDATED: "Déjà relue · trou du référentiel confirmé",
  CORRECTED: "Déjà relue · trou infirmé, notion posée à la main",
};

function libelleVerdict(verdict: string, aucuneNotion: boolean): string {
  if (aucuneNotion && VERDICTS_AUCUNE_NOTION[verdict]) {
    return VERDICTS_AUCUNE_NOTION[verdict];
  }
  return VERDICTS[verdict] ?? "Déjà relue";
}

interface Geste {
  questionId: string;
  notionCode: string | null;
  /**
   * 🛑 Typé `CivicTaggingGesteVerdict` et non `string` : `VALIDATED` et
   * `CORRECTED` sont la décision du serveur et deviennent ainsi inexprimables
   * ici. Une contrainte dure vaut mieux qu'une consigne.
   */
  verdict: CivicTaggingGesteVerdict | null;
}

/**
 * 🛑 **L'unique lecture du fait.** `notionCode === null` sur une suggestion =
 * le modèle a conclu qu'**aucune notion du référentiel ne convient**. C'est un
 * verdict, pas une absence : `confidence` et `rationale` l'accompagnent.
 *
 * ⚠️ À ne pas confondre avec `suggestions: []` — « le pré-tagging n'a pas
 * couvert cette question », qui est une absence de verdict. Deux états
 * différents, deux rendus différents.
 */
function estAucuneNotion(suggestion: CivicTaggingSuggestion): boolean {
  return suggestion.notionCode === null;
}

/**
 * Ce que « Valider » écrit — **un seul endroit**, partagé par le bouton et par
 * le raccourci `V`, sinon les deux finiraient par diverger sur le cas rare.
 *
 * `null` = il n'y a rien à valider (aucune suggestion du tout).
 */
function gesteDeValidation(question: CivicTaggingQuestion): Geste | null {
  const meilleure = question.suggestions[0];
  if (!meilleure) return null;
  if (estAucuneNotion(meilleure)) {
    // Le relecteur confirme le modèle : il acte un TROU du référentiel. Le
    // serveur traduit ce geste en `VALIDATED` et refuse en 400 si la meilleure
    // suggestion n'était pas « aucune notion ».
    return { questionId: question.questionId, notionCode: null, verdict: "CONFIRM_NONE" };
  }
  return {
    questionId: question.questionId,
    notionCode: meilleure.notionCode,
    verdict: null,
  };
}

/** Le libellé porté par une suggestion, jamais « null » à l'écran. */
function libelleSuggestion(suggestion: CivicTaggingSuggestion): string {
  return suggestion.notionLabel ?? suggestion.notionCode ?? "notion inconnue";
}

function niveauDeConfiance(confidence: number): { mot: string; classe: string } {
  if (confidence >= CONFIANCE_FORTE) return { mot: "confiance forte", classe: styles.jaugeForte };
  if (confidence >= CONFIANCE_MOYENNE)
    return { mot: "confiance moyenne", classe: styles.jaugeMoyenne };
  return { mot: "confiance faible", classe: styles.jaugeFaible };
}

/**
 * La suggestion qui porte le verdict vaut pour la question — on rend la
 * suggestion elle-même, pas seulement son verdict : le libellé du badge dépend
 * aussi de ce sur quoi le verdict a été rendu (une notion, ou « aucune »).
 */
function suggestionRelue(question: CivicTaggingQuestion): CivicTaggingSuggestion | null {
  return question.suggestions.find((s) => s.reviewVerdict) ?? null;
}

/**
 * **Le référentiel de notions civiques et son tagging** (lot L8).
 *
 * C'est l'outil du chantier **éditorial** qui est sur le chemin critique :
 * 1 016 questions à rattacher à une notion. Le code ne fait pas ce travail, il
 * l'outille — donc sa seule métrique est le temps par question.
 *
 * 🛑 **Le job propose, un humain valide** (`50_` §6.1.3). Aucune suggestion
 * n'est pré-sélectionnée, aucune fusion n'est appliquée automatiquement.
 *
 * 🛑 **Aucun appel LLM n'est déclenché depuis cet écran.**
 */
export function CivicNotionsPage() {
  const [theme, setTheme] = useState<string>(THEMES[0].code);
  const [offset, setOffset] = useState(0);
  const [actif, setActif] = useState(0);
  const [aideVisible, setAideVisible] = useState(false);
  const [erreur, setErreur] = useState<string | null>(null);
  /**
   * Les questions traitées **dans cette session**, cachées de la file sans
   * attendre le rechargement. Deux raisons, pas une : la carte disparaît au
   * geste (c'est le gain de temps), et une question `REJECTED` / `SKIPPED`
   * reste `tagged=false` côté serveur — sans ce filtre elle remonterait aussitôt
   * en tête et le relecteur tournerait en rond.
   */
  const [traitees, setTraitees] = useState<ReadonlySet<string>>(new Set());

  /**
   * 🛑 Le mode « relire une campagne ». Sans lui, les 50 questions d'un pilote
   * sont noyées dans les 215 non taguées de leur thème — cinq ou six par page
   * de vingt-cinq — et retrouver une campagne est impossible. Actif, la file ne
   * garde que les questions PRÉ-TAGUÉES, **confiances les plus basses en
   * tête** : c'est là que le relecteur apporte quelque chose, une suggestion à
   * 0,97 se confirme d'un coup d'œil.
   */
  const [suggereesSeules, setSuggereesSeules] = useState(true);
  const queryClient = useQueryClient();
  const cartes = useRef(new Map<string, HTMLElement>());

  const referentiel = useQuery({
    queryKey: ["civic-notions"],
    queryFn: ({ signal }) => civicNotionsApi.referentiel(signal),
  });

  const file = useQuery({
    queryKey: ["civic-tagging", theme, offset, suggereesSeules],
    queryFn: ({ signal }) =>
      civicNotionsApi.file(
        { theme, tagged: false, suggerees: suggereesSeules, limit: PAGE, offset },
        signal,
      ),
  });

  const taguer = useMutation({
    mutationFn: ({ questionId, notionCode, verdict }: Geste) =>
      civicNotionsApi.taguer(questionId, notionCode, verdict),
    onMutate: ({ questionId }: Geste) => {
      setErreur(null);
      setTraitees((prev) => new Set(prev).add(questionId));
    },
    onSuccess: () => {
      // Les deux vues bougent ensemble : la file se vide, la couverture monte.
      void queryClient.invalidateQueries({ queryKey: ["civic-tagging"] });
      void queryClient.invalidateQueries({ queryKey: ["civic-notions"] });
    },
    onError: (error: Error, { questionId }: Geste) => {
      // Rien n'a été écrit : la carte revient, sinon le relecteur croirait
      // avoir tranché une question qui l'attend toujours.
      setTraitees((prev) => {
        const suivant = new Set(prev);
        suivant.delete(questionId);
        return suivant;
      });
      setErreur(error.message || "L'enregistrement a échoué.");
    },
  });

  /**
   * Les notions proposables, par thème.
   *
   * 🛑 **Indexées sur le thème de la QUESTION, pas sur l'onglet.** Une question
   * d'histoire ne se tague pas sur une notion d'institutions ; mais depuis que
   * la file peut couvrir tous les thèmes à la fois, l'onglet ne dit plus de
   * quel thème est la carte qu'on a sous les yeux. Les lier ferait proposer à
   * une question de société les notions d'un autre thème.
   *
   * Les notions FUSIONNÉES sont exclues : on ne corrige pas vers une notion
   * que le référentiel a retirée.
   */
  const notionsParTheme = useMemo(() => {
    const par = new Map<string, CivicNotionDto[]>();
    for (const n of referentiel.data ?? []) {
      if (!n.active) continue;
      const liste = par.get(n.themeCode);
      if (liste) liste.push(n);
      else par.set(n.themeCode, [n]);
    }
    return par;
  }, [referentiel.data]);

  const questions = useMemo(
    () => (file.data?.questions ?? []).filter((q) => !traitees.has(q.questionId)),
    [file.data, traitees],
  );

  const fenetreEpuisee =
    !!file.data && file.data.questions.length > 0 && questions.length === 0;
  const finDeFile = !!file.data && file.data.questions.length < PAGE;

  const indexActif = questions.length === 0 ? 0 : Math.min(actif, questions.length - 1);
  const questionActive = questions[indexActif];

  const changerTheme = (code: string) => {
    setTheme(code);
    setOffset(0);
    setActif(0);
  };

  // Changer de mode rebat la file : on repart du haut, sinon l'offset courant
  // pointe dans une liste qui n'a plus la même longueur.
  const changerMode = (seules: boolean) => {
    setSuggereesSeules(seules);
    // Relire une campagne, c'est relire CE QUE LE MODÈLE A PROPOSÉ, où qu'il
    // l'ait proposé. Rester sur un thème qui n'en porte aucune donne une file
    // vide sans rien expliquer.
    if (seules) setTheme("");
    setOffset(0);
    setActif(0);
    setTraitees(new Set());
  };

  /**
   * La question dont la liste de correction est OUVERTE, s'il y en a une.
   *
   * 🛑 **Corriger est un geste, pas l'état par défaut de l'écran.** Le
   * `<select>` des notions vivait en permanence au premier plan de chaque
   * carte, plus large que les boutons : le relecteur lisait « choisis une
   * notion » là où le pré-tagging lui promettait « confirme ou corrige ». Il
   * re-taguait à la main ce que le modèle avait déjà proposé. La liste
   * n'apparaît donc plus que sur demande — et une seule à la fois, parce que
   * deux listes ouvertes redonnent un écran de saisie.
   */
  const [correction, setCorrection] = useState<string | null>(null);

  const mutate = taguer.mutate;
  const executer = useCallback(
      (geste: Geste) => {
        // Le geste tranché referme la liste : la laisser ouverte sur une
        // question déjà relue invite à trancher deux fois.
        setCorrection(null);
        mutate(geste);
      },
      [mutate]);

  // Ouvrir la liste au clavier ne sert à rien si le focus reste ailleurs : le
  // relecteur devrait attraper la souris, ce que le raccourci evitait.
  useEffect(() => {
    if (!correction) return;
    cartes.current.get(correction)?.querySelector<HTMLSelectElement>("select")?.focus();
  }, [correction]);

  /**
   * Raccourcis. Ils ne se déclenchent jamais quand le focus est dans un champ
   * (le `<select>` des notions garde ses propres flèches) ni sous un
   * modificateur — un `⌘R` doit rester un rechargement.
   */
  useEffect(() => {
    function onKeyDown(event: KeyboardEvent) {
      if (event.ctrlKey || event.metaKey || event.altKey) return;
      const cible = event.target as HTMLElement | null;
      if (cible) {
        const balise = cible.tagName;
        if (
          balise === "INPUT" ||
          balise === "TEXTAREA" ||
          balise === "SELECT" ||
          cible.isContentEditable
        ) {
          if (event.key === "Escape") cible.blur();
          return;
        }
      }

      if (event.key === "?") {
        setAideVisible((v) => !v);
        event.preventDefault();
        return;
      }
      if (!questionActive) return;

      const touche = event.key.toLowerCase();
      const alternative = questionActive.suggestions[1];

      if (event.key === "ArrowDown" || touche === "j") {
        setActif((i) => Math.min(i + 1, questions.length - 1));
        event.preventDefault();
      } else if (event.key === "ArrowUp" || touche === "k") {
        setActif((i) => Math.max(i - 1, 0));
        event.preventDefault();
      } else if (touche === "v" || event.key === "Enter") {
        // Sur une carte « aucune notion », le même geste écrit `CONFIRM_NONE` :
        // c'est `gesteDeValidation` qui tranche, pas ce bloc.
        const geste = gesteDeValidation(questionActive);
        if (!geste) return;
        executer(geste);
        event.preventDefault();
      } else if (touche === "a") {
        // Un « aucune notion » en n°2 ne se « retient » pas : le serveur ne
        // sait confirmer un trou que sur la suggestion la mieux notée.
        if (!alternative || estAucuneNotion(alternative)) return;
        executer({
          questionId: questionActive.questionId,
          notionCode: alternative.notionCode,
          verdict: null,
        });
        event.preventDefault();
      } else if (touche === "c") {
        setCorrection(questionActive.questionId);
        event.preventDefault();
      } else if (touche === "r") {
        executer({
          questionId: questionActive.questionId,
          notionCode: null,
          verdict: "REJECTED",
        });
        event.preventDefault();
      } else if (touche === "p") {
        executer({
          questionId: questionActive.questionId,
          notionCode: null,
          verdict: "SKIPPED",
        });
        event.preventDefault();
      }
    }

    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [executer, questionActive, questions.length]);

  useEffect(() => {
    if (!questionActive) return;
    cartes.current
      .get(questionActive.questionId)
      ?.scrollIntoView({ block: "nearest", behavior: "smooth" });
  }, [questionActive]);

  return (
    <>
      <PageHeader
        eyebrow="Contenu civique"
        title="Référentiel de "
        emphasis="notions"
        actions={
          <div className={styles.themes}>
            {THEMES.map((t) => (
              <button
                key={t.code}
                type="button"
                className={t.code === theme ? styles.themeActive : styles.theme}
                onClick={() => changerTheme(t.code)}
              >
                {t.label}
              </button>
            ))}
          </div>
        }
      />

      <Panel
        title="À taguer"
        sub={
          file.data
            ? suggereesSeules
              ? "Les questions PRÉ-TAGUÉES de ce thème, confiances les plus basses en tête — c'est là que la relecture apporte le plus."
              : `${file.data.resteATaguer} question(s) civique(s) active(s) encore sans notion, tous thèmes confondus.`
            : undefined
        }
        actions={
          <button
            type="button"
            className={styles.aideBouton}
            onClick={() => setAideVisible((v) => !v)}
          >
            {aideVisible ? "Masquer les raccourcis" : "Raccourcis clavier"}
          </button>
        }
        noPadding
      >
        <div className={styles.modeFile} role="group" aria-label="Contenu de la file">
          <button
            type="button"
            className={suggereesSeules ? styles.modeActif : styles.mode}
            aria-pressed={suggereesSeules}
            onClick={() => changerMode(true)}
          >
            Relire une campagne
          </button>
          <button
            type="button"
            className={suggereesSeules ? styles.mode : styles.modeActif}
            aria-pressed={!suggereesSeules}
            onClick={() => changerMode(false)}
          >
            Toutes les questions à taguer
          </button>
        </div>

        {aideVisible && <AideClavier />}

        {erreur && (
          <div className={styles.erreur} role="alert">
            {erreur} — la question est revenue dans la file.
          </div>
        )}

        <div className={styles.fenetre}>
          <span className={styles.fenetreEtat}>
            Fenêtre {offset + 1}–{offset + PAGE} de la file
          </span>
          {/* Le filtre est `tagged=false` : une question validée QUITTE la file
              et tout ce qui suit remonte d'un cran. Un « page suivante »
              classique sauterait donc des questions en silence — on ne l'offre
              qu'une fois la fenêtre vidée, et uniquement pour enjamber ce qu'on
              a délibérément laissé en attente. */}
          <span className={styles.fenetreNote}>
            la file se vide par le haut : ce qui est tagué en sort, ce qui est
            rejeté ou passé y reste.
          </span>
          {offset > 0 && (
            <button
              type="button"
              className={styles.fenetreBouton}
              onClick={() => {
                setOffset(0);
                setActif(0);
              }}
            >
              Revenir en tête de file
            </button>
          )}
        </div>

        {file.isLoading && <Spinner />}

        {file.data && file.data.questions.length === 0 && (
          <EmptyState
            title="Rien à taguer sur ce thème."
            description={
              offset > 0
                ? "La fenêtre courante est au-delà de la fin de la file — revenir en tête."
                : undefined
            }
          />
        )}

        {fenetreEpuisee && (
          <EmptyState
            title="Fenêtre traitée."
            description={
              finDeFile
                ? "Il ne reste rien d'autre sur ce thème pour cette fenêtre."
                : "Les questions rejetées ou passées restent dans la file : avancer la fenêtre permet de les enjamber."
            }
          />
        )}

        {fenetreEpuisee && !finDeFile && (
          <div className={styles.fenetreActions}>
            <button
              type="button"
              className={styles.fenetreBoutonFort}
              onClick={() => {
                setOffset(offset + PAGE);
                setActif(0);
              }}
            >
              Enjamber vers les {PAGE} suivantes
            </button>
          </div>
        )}

        {questions.length > 0 && (
          <div className={styles.file}>
            {questions.map((question, index) => (
              <CarteRelecture
                key={question.questionId}
                question={question}
                rang={offset + index + 1}
                actif={index === indexActif}
                notions={notionsParTheme.get(question.themeCode) ?? []}
                onFocus={() => setActif(index)}
                onGeste={executer}
                correctionOuverte={correction === question.questionId}
                onCorriger={() => setCorrection(question.questionId)}
                onFermerCorrection={() => setCorrection(null)}
                enregistrer={(element) => {
                  if (element) cartes.current.set(question.questionId, element);
                  else cartes.current.delete(question.questionId);
                }}
              />
            ))}
          </div>
        )}
      </Panel>

      <Panel
        title="Couverture mesurée"
        sub="C'est ce tableau qui alimente la porte de revue (§6.1.3) : trop peu de questions ⇒ candidate à la fusion, trop ⇒ candidate à la scission."
        noPadding
      >
        {referentiel.isLoading && <Spinner />}
        {referentiel.data && <Couverture notions={referentiel.data} />}
      </Panel>
    </>
  );
}

function AideClavier() {
  const raccourcis: [string, string][] = [
    ["↓ / J", "question suivante"],
    ["↑ / K", "question précédente"],
    ["V · Entrée", "valider la suggestion n°1 — ou confirmer le trou si elle conclut « aucune notion »"],
    ["A", "retenir l'alternative (suggestion n°2), sauf si elle conclut « aucune notion »"],
    ["C", "corriger — ouvrir la liste des notions du thème"],
    ["R", "rejeter — aucune notion ne convient"],
    ["P", "passer — je ne tranche pas"],
    ["?", "afficher ou masquer cette aide"],
  ];
  return (
    <div className={styles.aide}>
      {raccourcis.map(([touche, quoi]) => (
        <div key={touche} className={styles.aideLigne}>
          <kbd className={styles.touche}>{touche}</kbd>
          <span>{quoi}</span>
        </div>
      ))}
      <div className={styles.aideNote}>
        Les raccourcis se taisent dès que le focus est dans un champ.
      </div>
    </div>
  );
}

interface CarteProps {
  question: CivicTaggingQuestion;
  rang: number;
  actif: boolean;
  notions: CivicNotionDto[];
  onFocus: () => void;
  onGeste: (geste: Geste) => void;
  correctionOuverte: boolean;
  onCorriger: () => void;
  onFermerCorrection: () => void;
  enregistrer: (element: HTMLElement | null) => void;
}

/**
 * Une question = une carte de relecture, pas une ligne de tableau.
 *
 * Le relecteur voit ce que le modèle a lu : énoncé, propositions, bonne
 * réponse, explication. Sans ce contexte, l'énoncé seul (≈ 60 caractères) ne
 * suffit pas à identifier la notion et la relecture devient une devinette.
 */
function CarteRelecture({
  question,
  rang,
  actif,
  notions,
  onFocus,
  onGeste,
  correctionOuverte,
  onCorriger,
  onFermerCorrection,
  enregistrer,
}: CarteProps) {
  const meilleure = question.suggestions[0];
  const alternative = question.suggestions[1];
  const relue = suggestionRelue(question);
  /** Le modèle dit qu'aucune notion ne convient : « Valider » acte un trou. */
  const confirmeUnTrou = !!meilleure && estAucuneNotion(meilleure);
  const gesteValider = gesteDeValidation(question);

  return (
    <article
      ref={enregistrer}
      className={`${styles.carte} ${actif ? styles.carteActive : ""}`}
      onMouseDown={onFocus}
    >
      <header className={styles.carteHaut}>
        <span className={styles.rang}>#{rang}</span>
        <span className={styles.mention}>{question.mention}</span>
        <span className={styles.themeCell}>{question.themeCode}</span>
        {question.notionLabel && (
          <span className={styles.notionPosee}>Taguée : {question.notionLabel}</span>
        )}
        {/* ⚠️ Une question déjà relue le DIT : sinon le relecteur qui revient
            ne sait pas ce qu'il a déjà écarté et refait le même arbitrage. */}
        {relue?.reviewVerdict && (
          <span className={styles.verdict}>
            {libelleVerdict(relue.reviewVerdict, estAucuneNotion(relue))}
          </span>
        )}
      </header>

      <p className={styles.enonce}>{question.enonce}</p>

      {question.choix.length > 0 && (
        <ul className={styles.choix}>
          {question.choix.map((choix, index) => (
            <li
              key={`${choix.label}-${index}`}
              className={`${styles.choixItem} ${choix.correct ? styles.choixCorrect : ""}`}
            >
              {/* La bonne réponse ne se distingue jamais par la seule couleur :
                  glyphe + libellé explicite + graisse. */}
              <span className={styles.choixMarque} aria-hidden="true">
                {choix.correct ? "✓" : "·"}
              </span>
              <span className={styles.choixLettre}>{LETTRES[index] ?? "?"}</span>
              <span className={styles.choixLabel}>{choix.label}</span>
              {choix.correct && <span className={styles.choixTag}>bonne réponse</span>}
            </li>
          ))}
        </ul>
      )}

      {question.explication && (
        <div className={styles.explication}>
          <span className={styles.blocTitre}>Explication</span>
          <p className={styles.explicationTexte}>{question.explication}</p>
        </div>
      )}

      <div className={styles.suggestionBloc}>
        <span className={styles.blocTitre}>Suggestion du modèle</span>
        {meilleure ? (
          <>
            <Suggestion suggestion={meilleure} />
            {alternative && (
              <div className={styles.alternative}>
                <span className={styles.alternativeTitre}>Alternative</span>
                <Suggestion suggestion={alternative} />
                {estAucuneNotion(alternative) ? (
                  <p className={styles.alternativeNote}>
                    Un « aucune notion » ne se confirme qu'en suggestion n°1 : si
                    vraiment aucune notion du thème ne convient, c'est
                    « Rejeter ».
                  </p>
                ) : (
                  <button
                    type="button"
                    className={styles.alternativeBouton}
                    onClick={() =>
                      onGeste({
                        questionId: question.questionId,
                        notionCode: alternative.notionCode,
                        verdict: null,
                      })
                    }
                  >
                    Retenir cette alternative <kbd className={styles.touche}>A</kbd>
                  </button>
                )}
              </div>
            )}
          </>
        ) : (
          // ⚠️ ABSENCE de verdict, à ne pas confondre avec le verdict
          // « aucune notion » rendu juste au-dessus : ici le modèle n'a rien dit
          // du tout. 🛑 Vide est l'état NORMAL : rien ne remplit la table de
          // suggestions sans décision du propriétaire, parce que la remplir coûte.
          <div className={styles.sansSuggestion}>
            <span className={styles.sansSuggestionTitre}>
              Pas de verdict du modèle
            </span>
            <p className={styles.sansSuggestionTexte}>
              Le pré-tagging n'a pas couvert cette question — ce n'est pas un
              « aucune notion ». Choisir la notion à la main.
            </p>
          </div>
        )}
      </div>

      <div className={styles.actions}>
        {/* 🛑 L'ORDRE DIT LE GESTE ATTENDU. Le bouton principal vient en
            premier et NOMME ce qu'il valide ; la liste des notions n'apparaît
            que derrière « Corriger ». Le pré-tagging ne demande pas de taguer,
            il demande de confirmer ou de corriger — un écran qui met le
            `<select>` au premier plan demande l'inverse. */}
        <div className={styles.boutons}>
          <button
            type="button"
            className={`${styles.valider} ${confirmeUnTrou ? styles.validerTrou : ""}`}
            disabled={!gesteValider}
            title={
              !meilleure
                ? "Aucune suggestion à valider : choisir la notion à la main"
                : confirmeUnTrou
                  ? "Confirmer que le modèle a raison : aucune notion du référentiel ne couvre cette question. C'est un trou du référentiel à combler, pas un tag."
                  : `Retenir « ${libelleSuggestion(meilleure)} »`
            }
            onClick={() => gesteValider && onGeste(gesteValider)}
          >
            {confirmeUnTrou
              ? "Confirmer : aucune notion correspondante"
              : "✓ Valider cette suggestion"}{" "}
            <kbd className={styles.touche}>V</kbd>
          </button>
          {/* Sans suggestion il n'y a rien à corriger : la liste est déjà
              ouverte plus bas, et un bouton qui la « rouvre » mentirait. */}
          {meilleure && !correctionOuverte && (
            <button
              type="button"
              className={styles.corriger}
              title={
                confirmeUnTrou
                  ? "Le modèle se trompe : une notion du thème convient"
                  : "Une autre notion convient mieux"
              }
              onClick={onCorriger}
            >
              {confirmeUnTrou ? "Attribuer une notion" : "Corriger"}{" "}
              <kbd className={styles.touche}>C</kbd>
            </button>
          )}
          <button
            type="button"
            className={styles.rejeter}
            title="Aucune notion du thème ne convient"
            onClick={() =>
              onGeste({
                questionId: question.questionId,
                notionCode: null,
                verdict: "REJECTED",
              })
            }
          >
            Rejeter <kbd className={styles.touche}>R</kbd>
          </button>
          <button
            type="button"
            className={styles.passer}
            title="Je ne tranche pas maintenant"
            onClick={() =>
              onGeste({
                questionId: question.questionId,
                notionCode: null,
                verdict: "SKIPPED",
              })
            }
          >
            Passer <kbd className={styles.touche}>P</kbd>
          </button>
        </div>

        {(correctionOuverte || !meilleure) && (
          <div className={styles.correction}>
            <label className={styles.champ}>
              <span className={styles.champTitre}>
                {!meilleure
                  ? "Notions du thème"
                  : confirmeUnTrou
                    ? "Le modèle se trompe : quelle notion convient ?"
                    : "Corriger : quelle notion convient mieux ?"}
              </span>
              <select
                className={styles.select}
                value=""
                onChange={(event) => {
                  if (!event.target.value) return;
                  onGeste({
                    questionId: question.questionId,
                    notionCode: event.target.value,
                    verdict: null,
                  });
                }}
              >
                <option value="">— choisir une notion —</option>
                {notions.map((n) => (
                  <option key={n.code} value={n.code}>
                    {n.label}
                  </option>
                ))}
              </select>
            </label>
            {meilleure && (
              <button
                type="button"
                className={styles.annulerCorrection}
                onClick={onFermerCorrection}
              >
                Annuler
              </button>
            )}
          </div>
        )}
      </div>
    </article>
  );
}

/**
 * La confiance pilote l'attention : elle se lit en un coup d'œil (jauge +
 * pourcentage + mot). Une confiance faible n'est pas une erreur, c'est
 * l'endroit où le relecteur doit vraiment lire.
 */
function Suggestion({ suggestion }: { suggestion: CivicTaggingSuggestion }) {
  const pourcent = Math.round(Math.max(0, Math.min(1, suggestion.confidence)) * 100);
  const niveau = niveauDeConfiance(suggestion.confidence);
  const aucune = estAucuneNotion(suggestion);

  return (
    <div className={`${styles.suggestion} ${aucune ? styles.suggestionAucune : ""}`}>
      <div className={styles.suggestionTete}>
        {aucune ? (
          <>
            <span className={styles.aucuneNotionTitre}>
              Aucune notion correspondante
            </span>
            <span className={styles.aucuneMarque}>verdict du modèle</span>
          </>
        ) : (
          <>
            <span className={styles.suggestionNotion}>
              {libelleSuggestion(suggestion)}
            </span>
            {suggestion.notionCode && (
              <span className={styles.suggestionCode}>{suggestion.notionCode}</span>
            )}
          </>
        )}
        {suggestion.reviewVerdict && (
          <span className={styles.verdict}>
            {libelleVerdict(suggestion.reviewVerdict, aucune)}
          </span>
        )}
      </div>
      <div className={styles.jaugeLigne}>
        <span className={styles.jaugePiste}>
          <span
            className={`${styles.jaugeBarre} ${niveau.classe}`}
            style={{ width: `${pourcent}%` }}
          />
        </span>
        <span className={styles.jaugeTexte}>
          {pourcent} % · {niveau.mot}
        </span>
      </div>
      {suggestion.rationale && (
        <p className={styles.rationale}>{suggestion.rationale}</p>
      )}
      {aucune && (
        <p className={styles.aucuneNote}>
          Le modèle a lu la question et n'a trouvé aucune notion du référentiel
          pour la porter. Confirmer, c'est acter un trou du référentiel ; choisir
          une notion ci-dessous, c'est dire qu'il s'est trompé.
        </p>
      )}
    </div>
  );
}

function Couverture({ notions }: { notions: CivicNotionDto[] }) {
  const mentions = useMemo(() => {
    const set = new Set<string>();
    notions.forEach((n) => n.parMention.forEach((m) => set.add(m.mention)));
    return [...set].sort();
  }, [notions]);

  return (
    <div className={tableStyles.tableWrap}>
      <table className={`${tableStyles.table} ${tableStyles.cardTable}`}>
        <thead>
          <tr>
            <th>Notion</th>
            <th>Thème</th>
            <th>Total</th>
            {mentions.map((m) => (
              <th key={m}>{m}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {notions.map((notion) => (
            <tr key={notion.code} className={notion.active ? undefined : styles.fusionnee}>
              <td>
                {notion.label}
                {notion.mergedIntoCode && (
                  <span className={styles.fusionNote}>
                    {" "}→ fusionnée dans {notion.mergedIntoCode}
                  </span>
                )}
              </td>
              <td data-label="Thème" className={styles.themeCell}>
                {notion.themeCode}
              </td>
              <td
                data-label="Total"
                className={
                  notion.questionsTaguees < SEUIL_CANDIDATE_FUSION ? styles.alerte : undefined
                }
              >
                {notion.questionsTaguees}
              </td>
              {mentions.map((mention) => {
                const compte =
                  notion.parMention.find((m) => m.mention === mention)?.questions ?? 0;
                return (
                  <td
                    key={mention}
                    data-label={mention}
                    className={compte < SEUIL_PLEINEMENT_UTILISABLE ? styles.attenue : undefined}
                  >
                    {compte}
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
