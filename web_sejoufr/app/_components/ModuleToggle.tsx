"use client";

/**
 * **La bascule de parcours d'un VISITEUR** sur `/examens-blancs` : TCF IRN |
 * Examen civique.
 *
 * Navigation v2 (2026-10-03) : un compte n'en a plus — la barre latérale porte
 * une entrée « Examens » par module. Un visiteur n'a pas cette barre : sans
 * bascule, l'examen civique offert lui serait inaccessible. Elle reste donc,
 * pour lui seul, et devient des **liens** (`?module=`), plus un état local :
 * l'adresse est l'unique autorité du parcours affiché.
 *
 * 🛑 Les couleurs sont celles des MODULES (X1-A) : TCF = bleu, civique =
 * rouge, lues sur `--color-module-*` — jamais un bleu / rouge en dur.
 */
import Link from "next/link";
import {Lightbulb, Waves} from "lucide-react";
import type {ParcoursModule} from "@/lib/module-switch";

export function ModuleToggle({
    active,
    hrefFor,
}: {
    active: ParcoursModule;
    hrefFor: (m: ParcoursModule) => string;
}) {
    return (
        <>
            <div className="mtg" role="tablist" aria-label="Choisir un parcours">
                <Link
                    href={hrefFor("TCF")}
                    role="tab"
                    aria-selected={active === "TCF"}
                    className={`mtg-btn mtg-btn-tcf${active === "TCF" ? " is-active" : ""}`}
                    scroll={false}
                >
                    <Waves size={16} strokeWidth={1.8} aria-hidden />
                    TCF IRN
                </Link>
                <Link
                    href={hrefFor("CIVIQUE")}
                    role="tab"
                    aria-selected={active === "CIVIQUE"}
                    className={`mtg-btn mtg-btn-civique${active === "CIVIQUE" ? " is-active" : ""}`}
                    scroll={false}
                >
                    <Lightbulb size={16} strokeWidth={1.8} aria-hidden />
                    Examen civique
                </Link>
            </div>
            <Styles />
        </>
    );
}

/**
 * 🛑 **`<style>` SANS l'attribut `jsx`, et ce n'est pas un oubli.**
 *
 * styled-jsx scope ses règles aux éléments rendus par **le même** composant :
 * dans un `Styles()` qui ne rend que la balise, aucun élément ne reçoit la
 * classe de scope, et **aucune règle ne s'applique**. Le reste du dépôt utilise
 * `<style>` global : on s'y aligne, et les classes sont préfixées.
 */
function Styles() {
    return (
        <style>{`
  .mtg {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 4px;
    padding: 4px;
    margin-bottom: 20px;
    max-width: 440px;
    background: var(--color-white);
    border: 1px solid var(--color-line);
    border-radius: 14px;
  }
  .mtg-btn {
    min-width: 0;
    min-height: 42px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 7px;
    padding: 8px 10px;
    border-radius: 10px;
    font-family: var(--font-sans);
    font-size: 14px;
    font-weight: 700;
    line-height: 1;
    white-space: nowrap;
    color: var(--color-muted);
    text-decoration: none;
    transition: color 0.15s ease, background 0.15s ease;
  }
  .mtg-btn svg { flex-shrink: 0; }
  .mtg-btn:hover { color: var(--color-ink); }
  .mtg-btn.is-active { color: var(--color-white); }
  .mtg-btn-tcf.is-active { background: var(--color-module-tcf); }
  .mtg-btn-civique.is-active { background: var(--color-module-civique); }
  @media (max-width: 380px) {
    .mtg-btn { font-size: 13px; gap: 6px; padding: 8px 6px; }
  }
`}</style>
    );
}
