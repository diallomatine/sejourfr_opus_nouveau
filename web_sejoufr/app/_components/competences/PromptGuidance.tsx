"use client";

import {
  Check,
  Clock,
  FileText,
  Hash,
  Heart,
  History,
  ListOrdered,
  MapPin,
  MessageSquareText,
  Quote,
  Tag,
  User,
  type LucideIcon,
} from "lucide-react";
import {
  checklistOf,
  constraintTagsOf,
  lengthChipLabel,
} from "@/lib/skill-guidance";
import type {SkillConstraintIcon, SkillPromptDto} from "@/lib/types";
import s from "@/app/_components/skill-ui/skill.module.css";

/**
 * **Table unique** icône ⇄ famille de contrainte. Typée `Record<…>` sur la
 * liste fermée : ajouter une famille au contrat sans lui donner d'icône ne
 * compile plus. C'est ce qui garantit qu'elle reste exhaustive.
 */
const CONSTRAINT_ICON: Record<SkillConstraintIcon, LucideIcon> = {
  TONE: Heart,
  PERSON: User,
  TIME: Clock,
  PLACE: MapPin,
  NUMBER: Hash,
  TENSE: History,
  STRUCTURE: ListOrdered,
  EXAMPLE: Quote,
};

/** Icône neutre pour une famille que ce front ne connaît pas encore : le
 *  backend peut livrer une valeur avant que le web ne soit redéployé, et une
 *  étiquette sans icône vaut mieux qu'une étiquette manquante. */
const FALLBACK_ICON: LucideIcon = Tag;

/** Résout une valeur d'`icon` reçue du backend. Le paramètre est volontairement
 *  élargi à `string` : c'est du JSON, pas une union garantie à l'exécution. */
export function constraintIcon(icon: string): LucideIcon {
  return CONSTRAINT_ICON[icon as SkillConstraintIcon] ?? FALLBACK_ICON;
}

/**
 * Titre de la carte du contexte du sujet : c'est le **texte à traiter**, la
 * carte principale de l'écran. Miroir mot pour mot de `kSkillSituationTitle`
 * côté mobile (`competences/widgets/prompt_guidance.dart`).
 */
const SITUATION_TITLE = "Situation";

/** Intitulé du panneau de la check-list, miroir de `kSkillChecklistLabel`. */
const TODO_LABEL = "CE QU'IL FAUT FAIRE";

/** En-tête d'une carte de guidage : pastille d'icône + titre. */
function GuideHead({icon, title}: {icon: LucideIcon; title: string}) {
  const Icon = icon;
  return (
    <div className={s.guideHead}>
      <span className={s.guideIcon} aria-hidden>
        <Icon size={16} strokeWidth={2.2} />
      </span>
      <h2 className={s.guideTitle}>{title}</h2>
    </div>
  );
}

/**
 * Le guidage d'un petit sujet, tel que le propriétaire l'ordonne (2026-10-04) : **la
 * situation**, **ce qu'il faut faire**, puis les contraintes en puces. Il
 * remplace la carte d'exercice générique des formulaires partagés (prop
 * `promptSlot`) — l'écran ne raconte plus l'exercice, il le fait faire.
 *
 * Même bloc à l'écrit et à l'oral : seules la puce de longueur (mots vs
 * secondes) et la couleur d'accent changent.
 *
 * **Dégradation** (règles dans `lib/skill-guidance.ts`) : sans check-list, la
 * carte retombe sur la consigne du sujet — elle n'est jamais vide ; sans
 * contexte, la carte « Situation » n'est pas rendue ; sans étiquette, la rangée
 * ne porte que la longueur ; sans bornes ni étiquette, elle disparaît.
 */
export function PromptGuidance({prompt, oral}: {prompt: SkillPromptDto; oral: boolean}) {
  const checklist = checklistOf(prompt);
  const tags = constraintTagsOf(prompt);
  const length = lengthChipLabel(prompt, oral);
  const situation = prompt.context.trim();
  const LengthIcon = oral ? Clock : FileText;

  return (
    <>
      {/* La SITUATION d'abord, en carte principale (demande du propriétaire,
          2026-10-04) : c'est le texte à traiter. « Ce qu'il faut faire » suit,
          en panneau teinté. Miroir de `SkillSituationCard` / `SkillChecklistCard` côté mobile. */}
      {situation && (
        <section className={`${s.guideCard} ${s.guideCardLead}`}>
          <GuideHead icon={MessageSquareText} title={SITUATION_TITLE} />
          <p className={`${s.guideText} ${s.situationText}`}>{situation}</p>
        </section>
      )}

      <section className={s.situationPanel}>
        <span className={s.situationLabel}>{TODO_LABEL}</span>
        {checklist.length > 0 ? (
          <ul className={s.checklist}>
            {checklist.map((item, i) => (
              <li key={`${i}-${item}`} className={s.checkItem}>
                <span className={s.checkDot} aria-hidden>
                  <Check size={11} strokeWidth={3.2} />
                </span>
                {item}
              </li>
            ))}
          </ul>
        ) : (
          <p className={s.guideText}>{prompt.instruction}</p>
        )}
      </section>

      {(length != null || tags.length > 0) && (
        <div className={s.chipRow}>
          {length != null && (
            <span className={s.chipItem}>
              <LengthIcon size={13} strokeWidth={2.2} aria-hidden />
              {length}
            </span>
          )}
          {tags.map((tag, i) => {
            const Icon = constraintIcon(tag.icon);
            return (
              <span key={`${i}-${tag.label}`} className={s.chipItem}>
                <Icon size={13} strokeWidth={2.2} aria-hidden />
                {tag.label}
              </span>
            );
          })}
        </div>
      )}
    </>
  );
}
