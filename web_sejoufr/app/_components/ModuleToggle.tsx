"use client";

/**
 * **Le toggle de parcours** : TCF IRN | Examen civique.
 *
 * 🛑 **Un seul composant pour tous les écrans qui portent les deux parcours.**
 * Il vivait dans `/examens-blancs` ; le Plan en avait besoin à l'identique, et
 * une seconde copie aurait fini par diverger — c'est le défaut le plus cher de
 * ce dépôt. À la 2ᵉ occurrence, on extrait.
 *
 * 🛑 **Deux couleurs, et elles ne sont pas décoratives** : le rouge est celui du
 * TCF, le bleu celui du civique, partout dans le produit (`ebh-module-icon-red`
 * / `-blue`, les cartes de Progrès, les pastilles de thème). Un candidat
 * reconnaît son parcours à la couleur avant de lire le mot.
 */
import {Lightbulb, Waves} from "lucide-react";

export type ParcoursModule = "TCF" | "CIVIQUE";

export function ModuleToggle({
    active,
    onChange,
}: {
    active: ParcoursModule;
    onChange: (m: ParcoursModule) => void;
}) {
    return (
        <>
            <div className="mtg" role="tablist" aria-label="Choisir un parcours">
                <button
                    type="button"
                    role="tab"
                    aria-selected={active === "TCF"}
                    className={`mtg-btn mtg-btn-red${active === "TCF" ? " is-active" : ""}`}
                    onClick={() => onChange("TCF")}
                >
                    <Waves size={16} strokeWidth={1.8} aria-hidden />
                    TCF IRN
                </button>
                <button
                    type="button"
                    role="tab"
                    aria-selected={active === "CIVIQUE"}
                    className={`mtg-btn mtg-btn-blue${active === "CIVIQUE" ? " is-active" : ""}`}
                    onClick={() => onChange("CIVIQUE")}
                >
                    <Lightbulb size={16} strokeWidth={1.8} aria-hidden />
                    Examen civique
                </button>
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
    background: #fff;
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
    border: 0;
    border-radius: 10px;
    background: transparent;
    font-family: var(--font-sans);
    font-size: 14px;
    font-weight: 700;
    line-height: 1;
    white-space: nowrap;
    color: var(--color-muted);
    cursor: pointer;
    transition: color 0.15s ease, background 0.15s ease;
  }
  .mtg-btn svg { flex-shrink: 0; }
  .mtg-btn:hover { color: var(--color-ink); }
  .mtg-btn.is-active { color: #fff; }
  /* Les deux couleurs du produit : rouge = TCF, bleu = civique. */
  .mtg-btn-red.is-active { background: var(--color-red); }
  .mtg-btn-blue.is-active { background: var(--color-blue); }
  @media (max-width: 380px) {
    .mtg-btn { font-size: 13px; gap: 6px; padding: 8px 6px; }
  }
`}</style>
    );
}
