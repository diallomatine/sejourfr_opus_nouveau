import Link from "next/link";
import {
  ArrowRight,
  ArrowUp,
  Check,
  Landmark,
  Target,
} from "lucide-react";
import { AppleIcon, GooglePlayMonoIcon } from "../StoreBadge";
import { DIAGNOSTIC_RAPIDE_HREF, DIAGNOSTIC_RAPIDE_START_HREF } from "@/lib/preparation";
import { STORE_LINKS } from "@/lib/site";
import { HERO_TRUST, PROMISES } from "./landing-copy";
import { TrackedLink } from "./LandingTracking";
import styles from "./landing.module.css";

/**
 * Les sections éditoriales de l'accueil `/` (maquette « accueil v3 »,
 * 2026-09-26). Composants serveur : la mesure vit dans `TrackedLink`, les prix
 * dans `LandingPricing`. Les maquettes de téléphone et la carte de résultat du
 * diagnostic sont des ILLUSTRATIONS : `aria-hidden`, rien n'y est cliquable.
 */

const DIAGNOSTIC_CIVIQUE_HREF = "/diagnostic-civique";

function SectionHead({
  kicker,
  title,
  sub,
  big = false,
}: {
  kicker: string;
  title: React.ReactNode;
  sub?: string;
  big?: boolean;
}) {
  return (
    <div>
      <span className={styles.kicker}>{kicker}</span>
      <h2 className={`${styles.sectionTitle} ${big ? styles.bigTitle : ""}`}>{title}</h2>
      {sub ? <p className={styles.sectionSub}>{sub}</p> : null}
    </div>
  );
}

/* ==========================================================================
   Hero + bande de promesses
   ========================================================================== */

const HERO_CHIPS = ["Titre de séjour", "Carte de résident", "Naturalisation"];

export function Hero() {
  return (
    <section className={styles.hero}>
      <div className={`${styles.wrap} ${styles.heroGrid}`}>
        <div>
          <ul className={styles.chips} aria-label="Démarches concernées">
            {HERO_CHIPS.map((c) => (
              <li key={c} className={styles.chip}>
                <span className={styles.chipDot} aria-hidden />
                {c}
              </li>
            ))}
          </ul>

          <h1 className={styles.heroTitle}>
            Préparez les examens de votre <em>démarche en France.</em>
          </h1>
          <p className={styles.lead}>
            TCF IRN, examen civique : <strong>testez-vous gratuitement</strong>, découvrez
            votre niveau et révisez ensuite seulement ce dont vous avez besoin.
          </p>

          <div className={styles.heroButtons}>
            <TrackedLink
              href={DIAGNOSTIC_RAPIDE_HREF}
              kind="diagnostic"
              ctaLocation="HERO"
              className={`${styles.btn} ${styles.btnRed}`}
            >
              Faire mon diagnostic gratuit
              <ArrowRight size={16} aria-hidden />
            </TrackedLink>
            <Link href="/examens-blancs" className={`${styles.btn} ${styles.btnLight}`}>
              Voir les examens
            </Link>
          </div>

          <ul className={styles.trust}>
            {HERO_TRUST.map((t) => (
              <li key={t}>
                <span className={styles.trustIcon} aria-hidden>
                  <Check size={11} strokeWidth={3} />
                </span>
                {t}
              </li>
            ))}
          </ul>
        </div>

        <div className={styles.pathShell} aria-hidden>
          <div className={`${styles.floatNote} ${styles.noteOne}`}>
            <strong>Votre démarche</strong>Naturalisation
          </div>
          <div className={`${styles.floatNote} ${styles.noteTwo}`}>
            <strong>Diagnostic gratuit</strong>Niveau + priorités
          </div>

          <div className={styles.pathCard}>
            <div className={styles.overline}>Votre préparation</div>
            <div className={styles.pathTitle}>Un parcours clair, dès le départ.</div>
            <p className={styles.pathSub}>SejourFR relie votre démarche, vos examens et vos révisions.</p>

            <ul className={styles.flow}>
              <li className={styles.flowRow}>
                <span className={styles.flowIcon}>
                  <Landmark size={18} />
                </span>
                <span className={styles.flowCopy}>
                  <small>1 · Votre démarche</small>
                  <strong>Naturalisation française</strong>
                  <span>Vous savez ce que vous préparez.</span>
                </span>
                <span className={styles.flowBadge}>Choisi</span>
              </li>
              <li className={styles.flowRow}>
                <span className={styles.flowIcon}>FR</span>
                <span className={styles.flowCopy}>
                  <small>2 · Vos examens</small>
                  <strong>TCF IRN + Examen civique</strong>
                  <span>Tout est regroupé au même endroit.</span>
                </span>
                <span className={styles.flowBadge}>2 examens</span>
              </li>
              <li className={`${styles.flowRow} ${styles.flowActive}`}>
                <span className={styles.flowIcon}>
                  <Target size={18} />
                </span>
                <span className={styles.flowCopy}>
                  <small>3 · Commencez ici</small>
                  <strong>Diagnostic gratuit</strong>
                  <span>Votre niveau et vos priorités de révision.</span>
                </span>
                <span className={styles.flowBadge}>Gratuit</span>
              </li>
            </ul>

            <div className={styles.resultMini}>
              <div>
                <small>Après le diagnostic</small>
                <strong>Un plan adapté à votre niveau</strong>
              </div>
              <div className={styles.resultPills}>
                <span>Niveau</span>
                <span>Priorités</span>
                <span>Plan</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

export function PromiseStrip() {
  return (
    <div className={styles.promiseStrip}>
      <ul className={`${styles.wrap} ${styles.promiseGrid}`}>
        {PROMISES.map(({ Icon, title, text }) => (
          <li key={title} className={styles.promise}>
            <span className={styles.promiseIcon} aria-hidden>
              <Icon size={18} />
            </span>
            <div>
              <strong>{title}</strong>
              <span>{text}</span>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}

/* ==========================================================================
   Pourquoi SejourFR + les deux examens
   ========================================================================== */

const REASONS = [
  {
    title: "Je sais ce que je prépare",
    text: "TCF IRN, examen civique ou les deux selon ma démarche.",
  },
  {
    title: "Je connais mon point de départ",
    text: "Le diagnostic donne un niveau estimé et fait ressortir les priorités.",
  },
  {
    title: "Je révise dans le bon ordre",
    text: "Le plan évite de travailler au hasard et me montre la prochaine étape utile.",
  },
];

export function Reason() {
  return (
    <section className={`${styles.section} ${styles.bgPaper}`}>
      <div className={`${styles.wrap} ${styles.grid2}`}>
        <SectionHead
          kicker="Pensé pour votre démarche"
          title="Pas une plateforme de cours de français de plus."
          sub="SejourFR part de votre objectif administratif, vous aide à identifier les examens concernés, puis organise votre préparation autour de votre niveau réel."
        />
        <ol className={styles.reasonCards}>
          {REASONS.map((r, i) => (
            <li key={r.title} className={styles.reasonCard}>
              <span className={styles.numBadge} aria-hidden>
                {String(i + 1).padStart(2, "0")}
              </span>
              <div>
                <strong className={styles.cardTitle}>{r.title}</strong>
                <span className={styles.cardText}>{r.text}</span>
              </div>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}

export function Exams() {
  return (
    <section id="examens" className={styles.section}>
      <div className={styles.wrap}>
        <SectionHead
          kicker="Deux préparations, une seule application"
          title="Choisissez l’examen. SejourFR organise la suite."
          sub="Vous pouvez travailler chaque examen séparément ou les retrouver dans le même parcours."
        />

        <div className={styles.examGrid}>
          <article className={`${styles.examCard} ${styles.examPrimary}`}>
            <div className={styles.examTop}>
              <span className={styles.examLabel}>TCF IRN</span>
              <span className={styles.examMark} aria-hidden>
                FR
              </span>
            </div>
            <h3 className={styles.examTitle}>Préparez les 4 épreuves.</h3>
            <p className={styles.examText}>
              Compréhension orale, compréhension écrite, expression écrite et expression orale
              avec entraînements, analyse IA et examens blancs.
            </p>
            <ul className={styles.tagRow}>
              {["CO", "CE", "EE", "EO", "Analyse IA", "Entretien simulé"].map((t) => (
                <li key={t} className={styles.tag}>
                  {t}
                </li>
              ))}
            </ul>
            <TrackedLink
              href={DIAGNOSTIC_RAPIDE_START_HREF}
              kind="diagnostic"
              ctaLocation="MIDDLE"
              className={styles.examLink}
            >
              Tester mon niveau TCF
              <ArrowRight size={15} aria-hidden />
            </TrackedLink>
          </article>

          <article className={styles.examCard}>
            <div className={styles.examTop}>
              <span className={styles.examLabel}>Examen civique</span>
              <span className={styles.examMark} aria-hidden>
                <Check size={18} strokeWidth={2.6} />
              </span>
            </div>
            <h3 className={styles.examTitle}>Révisez les thèmes utiles.</h3>
            <p className={styles.examText}>
              Un espace simple pour revoir les notions, s’entraîner avec des questions et vérifier
              sa préparation avant l’examen.
            </p>
            <ul className={styles.tagRow}>
              {["Révisions", "QCM", "Progression", "Examens blancs"].map((t) => (
                <li key={t} className={styles.tag}>
                  {t}
                </li>
              ))}
            </ul>
            <TrackedLink
              href={DIAGNOSTIC_CIVIQUE_HREF}
              kind="civique"
              ctaLocation="MIDDLE"
              className={styles.examLink}
            >
              Commencer le civique
              <ArrowRight size={15} aria-hidden />
            </TrackedLink>
          </article>
        </div>
      </div>
    </section>
  );
}

/* ==========================================================================
   TCF IRN · 4 épreuves
   ========================================================================== */

const SKILLS = [
  {
    code: "CO",
    type: "QCM",
    title: "Compréhension orale",
    text: "Écoutez des dialogues, annonces et échanges puis repérez les informations essentielles dans le temps imparti.",
    tags: ["Audio", "Séries ciblées", "Examens blancs"],
  },
  {
    code: "CE",
    type: "QCM",
    title: "Compréhension écrite",
    text: "Lisez des messages, documents et textes variés pour identifier le sens global, les détails et les informations utiles.",
    tags: ["Lecture", "Séries ciblées", "Examens blancs"],
  },
  {
    code: "EO",
    type: "Analyse IA",
    title: "Expression orale",
    text: "Enregistrez vos réponses, entraînez-vous comme à l’examen et recevez une analyse claire de votre production.",
    tags: ["3 tâches", "Niveau estimé", "Correction"],
  },
  {
    code: "EE",
    type: "Analyse IA",
    title: "Expression écrite",
    text: "Rédigez vos réponses puis identifiez rapidement ce qui est acquis et ce qu’il faut améliorer pour progresser.",
    tags: ["3 tâches", "Niveau estimé", "Correction"],
  },
];

const AI_POINTS = [
  { title: "Niveau estimé", text: "Un repère simple entre votre niveau actuel et votre objectif." },
  { title: "Feedback utile", text: "Ce qui va déjà bien, et ce qui bloque encore votre progression." },
  { title: "Priorités claires", text: "Les résultats servent directement à organiser vos révisions." },
];

const REALTIME_STEPS = [
  "Vous répondez à des consignes et à des relances dans un format plus naturel.",
  "Vous vous habituez au rythme de parole et à l’enchaînement des questions.",
  "Vous progressez sur l’aisance, la clarté et la capacité à tenir l’échange.",
];

export function TcfDetail() {
  return (
    <section id="tcf" className={styles.section}>
      <div className={styles.wrap}>
        <div className={styles.headRow}>
          <SectionHead
            big
            kicker="Module TCF IRN"
            title="TCF IRN · 4 épreuves"
            sub="Travaillez chaque compétence sans vous disperser. L’oral et l’écrit sont renforcés par l’analyse IA, et l’oral peut être entraîné avec une simulation d’entretien en temps réel."
          />
          <p className={styles.sectionNote}>
            <strong>Votre plan reste simple :</strong>
            <br />
            SejourFR met en avant les épreuves qui demandent le plus de travail selon vos
            résultats.
          </p>
        </div>

        <div className={styles.skillsGrid}>
          {SKILLS.map((s) => (
            <article key={s.code} className={styles.skillCard}>
              <div className={styles.skillTop}>
                <span className={styles.skillIcon} aria-hidden>
                  {s.code}
                </span>
                <span className={styles.skillType}>{s.type}</span>
              </div>
              <h3 className={styles.skillTitle}>{s.title}</h3>
              <p className={styles.skillText}>{s.text}</p>
              <ul className={styles.skillFooter}>
                {s.tags.map((t) => (
                  <li key={t}>{t}</li>
                ))}
              </ul>
            </article>
          ))}
        </div>

        <div className={styles.aiGrid}>
          <article className={styles.aiPanel}>
            <div className={styles.panelHead}>
              <span className={styles.aiBadge} aria-hidden>
                IA
              </span>
              <h3 className={styles.panelTitle}>Une analyse IA qui sert vraiment à progresser.</h3>
            </div>
            <p className={styles.panelText}>
              SejourFR n’utilise pas l’IA pour faire joli. Elle sert à analyser vos productions,
              faire ressortir vos points forts, vos axes de progrès et alimenter la prochaine étape
              de votre plan.
            </p>
            <ul className={styles.aiList}>
              {AI_POINTS.map((p) => (
                <li key={p.title}>
                  <strong>{p.title}</strong>
                  <span>{p.text}</span>
                </li>
              ))}
            </ul>
          </article>

          <article className={styles.realtimePanel}>
            <h3 className={styles.panelTitle}>Entretien en temps réel</h3>
            <p className={styles.panelText}>
              Pour l’oral, SejourFR peut simuler un échange plus vivant afin de vous entraîner à
              répondre dans un contexte proche d’un vrai entretien.
            </p>
            <ul className={styles.onBlueChips}>
              {["Simulation d’entretien", "Réactivité orale", "Confiance"].map((c) => (
                <li key={c}>{c}</li>
              ))}
            </ul>
            <ol className={styles.steps}>
              {REALTIME_STEPS.map((t, i) => (
                <li key={t} className={styles.step}>
                  <span className={styles.stepNum} aria-hidden>
                    {String(i + 1).padStart(2, "0")}
                  </span>
                  <span>{t}</span>
                </li>
              ))}
            </ol>
          </article>
        </div>
      </div>
    </section>
  );
}

/* ==========================================================================
   Examen civique · 5 thèmes
   ========================================================================== */

const THEMES = [
  {
    title: "Principes et valeurs de la République",
    text: "Les symboles, principes fondamentaux et valeurs qui structurent la République française.",
  },
  {
    title: "Système institutionnel et politique",
    text: "Le fonctionnement des principales institutions françaises et les grands repères de la vie démocratique.",
  },
  {
    title: "Droits et devoirs du citoyen",
    text: "Les libertés, responsabilités et règles essentielles liées à la vie citoyenne en France.",
  },
  {
    title: "Histoire, géographie et culture",
    text: "Les repères historiques, géographiques et culturels utiles pour comprendre la France d’aujourd’hui.",
  },
  {
    title: "Vivre dans la société française",
    text: "Les situations concrètes de la vie quotidienne : services, travail, école, santé et vie en société.",
  },
];

export function CiviqueThemes() {
  return (
    <section id="civique" className={`${styles.section} ${styles.bgPaper}`}>
      <div className={styles.wrap}>
        <SectionHead
          big
          kicker="Révision civique"
          title="Examen civique · 5 thèmes"
          sub="Révisez thème par thème, entraînez-vous avec des questions et voyez rapidement les sujets qui demandent encore du travail."
        />

        <ol className={styles.themesGrid}>
          {THEMES.map((t, i) => (
            <li key={t.title} className={styles.themeCard}>
              <span className={styles.themeNo} aria-hidden>
                {String(i + 1).padStart(2, "0")}
              </span>
              <h3 className={styles.themeTitle}>{t.title}</h3>
              <p className={styles.themeText}>{t.text}</p>
            </li>
          ))}
        </ol>

        <div className={styles.civiqueBottom}>
          <div>
            <strong>Pas besoin de tout revoir au même rythme.</strong>
            <span>
              Vos statistiques par thème permettent de concentrer vos révisions là où elles sont
              utiles.
            </span>
          </div>
          <a href="#tarifs" className={`${styles.btn} ${styles.btnLight}`}>
            Voir l’accès Civique
            <ArrowRight size={16} aria-hidden />
          </a>
        </div>
      </div>
    </section>
  );
}

/* ==========================================================================
   Ce que l'IA apporte
   ========================================================================== */

const VALUE_ITEMS = [
  {
    badge: "IA",
    title: "Analyse de l’oral et de l’écrit",
    text: "Des retours lisibles sur ce qui est réussi et ce qui mérite du travail.",
  },
  {
    badge: "Niv",
    title: "Niveau estimé",
    text: "Un repère clair pour situer votre progression sans jargon compliqué.",
  },
  {
    badge: "Plan",
    title: "Révision ciblée",
    text: "Les analyses servent à construire un plan plus pertinent, au lieu de réviser au hasard.",
  },
];

const VALUE_BOXES = [
  {
    title: "L’IA doit être utile, pas envahissante.",
    text: "Elle intervient quand elle apporte de la valeur : pour corriger, expliquer, orienter la révision et simuler des échanges à l’oral.",
    highlight: true,
  },
  {
    title: "Vous comprenez vos résultats.",
    text: "Au lieu d’un simple score, vous voyez votre niveau, vos priorités et la prochaine étape concrète.",
  },
  {
    title: "Vous gagnez du temps.",
    text: "Moins de dispersion, plus de clarté : SejourFR aide à concentrer l’effort sur ce qui fait réellement avancer.",
  },
];

export function AiValue() {
  return (
    <section className={styles.section}>
      <div className={`${styles.wrap} ${styles.aiValueGrid}`}>
        <div className={styles.valueCard}>
          <div className={styles.panelHead}>
            <span className={styles.valueIcon} aria-hidden>
              <Target size={20} />
            </span>
            <h2 className={styles.valueCardTitle}>La vraie valeur du site : savoir quoi faire ensuite.</h2>
          </div>
          <p className={styles.panelText}>
            La plateforme ne se limite pas à des questions et des séries. Elle transforme vos
            résultats en informations actionnables pour mieux réviser.
          </p>
          <ul className={styles.valueList}>
            {VALUE_ITEMS.map((v) => (
              <li key={v.title} className={styles.valueItem}>
                <span className={styles.valueItemBadge} aria-hidden>
                  {v.badge}
                </span>
                <div>
                  <strong>{v.title}</strong>
                  <span>{v.text}</span>
                </div>
              </li>
            ))}
          </ul>
        </div>

        <div className={styles.valuePoints}>
          {VALUE_BOXES.map((b) => (
            <div
              key={b.title}
              className={`${styles.valueBox} ${b.highlight ? styles.valueBoxHighlight : ""}`}
            >
              <strong>{b.title}</strong>
              <span>{b.text}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ==========================================================================
   Application mobile
   ========================================================================== */

const MOBILE_POINTS = [
  {
    title: "Réviser en petites sessions",
    text: "Pratique pour avancer même quand vous n’avez pas beaucoup de temps.",
  },
  {
    title: "Continuer son plan partout",
    text: "Vos priorités et vos entraînements vous suivent sur mobile.",
  },
  {
    title: "S’entraîner simplement",
    text: "QCM, révisions, analyses et progression dans une interface pensée pour le quotidien.",
  },
];

export function MobileApp() {
  return (
    <section id="mobile" className={`${styles.section} ${styles.bgPaper}`}>
      <div className={`${styles.wrap} ${styles.grid2} ${styles.mobileGrid}`}>
        <div>
          <SectionHead
            kicker="Disponible aussi sur mobile"
            title="Travaillez partout, directement depuis votre téléphone."
            sub="SejourFR existe aussi en version mobile pour réviser plus facilement au quotidien : dans les transports, pendant une pause ou quand vous avez quelques minutes devant vous."
          />

          <div className={styles.storeRow}>
            <a
              href={STORE_LINKS.ios}
              target="_blank"
              rel="noopener noreferrer"
              className={styles.storeBadge}
              aria-label="Télécharger SejourFR sur l'App Store"
            >
              <span className={styles.storeIcon} aria-hidden>
                <AppleIcon />
              </span>
              <span>
                <strong>App Store</strong>
                <span>Version iPhone disponible</span>
              </span>
            </a>
            <a
              href={STORE_LINKS.android}
              target="_blank"
              rel="noopener noreferrer"
              className={styles.storeBadge}
              aria-label="Télécharger SejourFR sur Google Play"
            >
              <span className={styles.storeIcon} aria-hidden>
                <GooglePlayMonoIcon />
              </span>
              <span>
                <strong>Play Store</strong>
                <span>Version Android disponible</span>
              </span>
            </a>
          </div>

          <ol className={styles.mobilePoints}>
            {MOBILE_POINTS.map((p, i) => (
              <li key={p.title} className={styles.mobilePoint}>
                <span className={styles.mobilePointNum} aria-hidden>
                  {String(i + 1).padStart(2, "0")}
                </span>
                <div>
                  <strong>{p.title}</strong>
                  <span>{p.text}</span>
                </div>
              </li>
            ))}
          </ol>
        </div>

        <div className={styles.mobileVisual} aria-hidden>
          <div className={styles.phoneStack}>
            <div className={`${styles.phone} ${styles.phoneLarge}`}>
              <div className={styles.phoneScreen}>
                <div className={styles.appBar}>
                  <span>SejourFR</span>
                  <span>09:41</span>
                </div>
                <div className={styles.mockTitle}>Mon plan du jour</div>
                <div className={styles.mockCard}>
                  <strong>Niveau estimé · B1</strong>
                  <span>Objectif : B2 · Vos priorités sont déjà organisées.</span>
                  <div className={styles.mockPills}>
                    <span>Niveau</span>
                    <span>Priorités</span>
                    <span>Plan</span>
                  </div>
                </div>
                <div className={styles.mockCard}>
                  <strong>À faire maintenant</strong>
                  <span>Expression orale · Entretien simulé en temps réel</span>
                  <span className={styles.mockBtn}>Commencer</span>
                </div>
              </div>
            </div>
            <div className={`${styles.phone} ${styles.phoneSmall}`}>
              <div className={styles.phoneScreen}>
                <div className={styles.appBar}>
                  <span>Civique</span>
                  <span>En cours</span>
                </div>
                <div className={styles.mockTitle}>Examen civique</div>
                <div className={styles.mockCard}>
                  <strong>Thème 3</strong>
                  <span>Droits et devoirs du citoyen</span>
                </div>
                <div className={styles.mockCard}>
                  <strong>Progression</strong>
                  <span>Vous avez travaillé 3 thèmes cette semaine.</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ==========================================================================
   Diagnostic + CTA final
   ========================================================================== */

const DIAG_POINTS = [
  { title: "Niveau estimé", text: "Un repère simple pour comprendre votre situation." },
  { title: "Analyse IA utile", text: "Vous voyez ce qui va déjà bien et ce qu’il faut renforcer." },
  { title: "Plan adapté", text: "Votre parcours de révision démarre à partir de vos résultats." },
];

export function Diagnostic() {
  return (
    <section id="diagnostic" className={`${styles.section} ${styles.diagnostic}`}>
      <div className={`${styles.wrap} ${styles.diagnosticGrid}`}>
        <div className={styles.score} aria-hidden>
          <div className={styles.scoreHead}>
            <div>
              <span className={styles.scoreLabel}>Niveau estimé</span>
              <div className={styles.scoreLevel}>B1</div>
            </div>
            <div className={styles.scoreGoal}>
              <span className={styles.scoreLabel}>Objectif</span>
              <strong>B2</strong>
            </div>
          </div>
          <ul className={styles.scoreRows}>
            <li className={styles.scoreRow}>
              <span className={styles.scoreIcon}>
                <Check size={17} strokeWidth={2.6} />
              </span>
              <div>
                <strong>Déjà acquis</strong>
                <span>Vous transmettez clairement l’essentiel.</span>
              </div>
            </li>
            <li className={`${styles.scoreRow} ${styles.scoreRowWork}`}>
              <span className={styles.scoreIcon}>
                <ArrowUp size={17} strokeWidth={2.4} />
              </span>
              <div>
                <strong>Priorité actuelle</strong>
                <span>Développer davantage les idées et les enchaîner.</span>
              </div>
            </li>
            <li className={`${styles.scoreRow} ${styles.scoreRowWork}`}>
              <span className={styles.scoreIcon}>
                <ArrowRight size={17} strokeWidth={2.4} />
              </span>
              <div>
                <strong>Prochaine étape</strong>
                <span>Une série ciblée est ajoutée à votre plan.</span>
              </div>
            </li>
          </ul>
        </div>

        <div>
          <SectionHead
            kicker="Commencez gratuitement"
            title="Avant de réviser, découvrez où vous en êtes."
            sub="Le diagnostic sert de point de départ : il estime votre niveau, identifie ce qui bloque votre progression et construit la suite de votre préparation."
          />
          <ol className={styles.diagPoints}>
            {DIAG_POINTS.map((p, i) => (
              <li key={p.title} className={styles.diagPoint}>
                <span className={styles.diagPointNum} aria-hidden>
                  {String(i + 1).padStart(2, "0")}
                </span>
                <div>
                  <strong>{p.title}</strong>
                  <span>{p.text}</span>
                </div>
              </li>
            ))}
          </ol>
          <div className={styles.diagCta}>
            <TrackedLink
              href={DIAGNOSTIC_RAPIDE_HREF}
              kind="diagnostic"
              ctaLocation="MIDDLE"
              className={`${styles.btn} ${styles.btnRed}`}
            >
              Faire mon diagnostic gratuit
              <ArrowRight size={16} aria-hidden />
            </TrackedLink>
          </div>
        </div>
      </div>
    </section>
  );
}

export function FinalCta() {
  return (
    <section className={styles.final}>
      <div className={styles.wrap}>
        <div className={styles.finalBox}>
          <div>
            <h2 className={styles.finalTitle}>Vous ne savez pas encore par où commencer ?</h2>
            <p className={styles.finalText}>
              Faites d’abord le diagnostic gratuit. Vous verrez votre niveau, les priorités à
              travailler et la meilleure suite pour votre préparation.
            </p>
          </div>
          <TrackedLink
            href={DIAGNOSTIC_RAPIDE_HREF}
            kind="diagnostic"
            ctaLocation="FOOTER"
            className={`${styles.btn} ${styles.btnBlue}`}
          >
            Faire mon diagnostic
            <ArrowRight size={16} aria-hidden />
          </TrackedLink>
        </div>
      </div>
    </section>
  );
}
