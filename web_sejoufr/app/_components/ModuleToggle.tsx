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
                    <Waves size={18} strokeWidth={1.8} aria-hidden />
                    TCF IRN
                </button>
                <button
                    type="button"
                    role="tab"
                    aria-selected={active === "CIVIQUE"}
                    className={`mtg-btn mtg-btn-blue${active === "CIVIQUE" ? " is-active" : ""}`}
                    onClick={() => onChange("CIVIQUE")}
                >
                    <Lightbulb size={18} strokeWidth={1.8} aria-hidden />
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
    display: flex;
    gap: 10px;
    margin-bottom: 22px;
  }
  .mtg-btn {
    flex: 1 1 0;
    min-width: 0;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 9px;
    padding: 14px 16px;
    border-radius: 14px;
    border: 1px solid var(--color-line);
    background: #fff;
    font-family: var(--font-sans);
    font-size: 15px;
    font-weight: 700;
    color: var(--color-muted);
    cursor: pointer;
    transition: color 0.15s ease, background 0.15s ease, border-color 0.15s ease;
  }
  .mtg-btn svg { flex-shrink: 0; }
  .mtg-btn:hover {
    color: var(--color-ink);
    border-color: color-mix(in srgb, var(--color-ink) 18%, transparent);
  }
  .mtg-btn.is-active {
    color: #fff;
    border-color: transparent;
  }
  /* Les deux couleurs du produit : rouge = TCF, bleu = civique. */
  .mtg-btn-red.is-active { background: var(--color-red); }
  .mtg-btn-blue.is-active { background: var(--color-blue); }
`}</style>
    );
}
