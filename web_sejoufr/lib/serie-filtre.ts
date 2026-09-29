/**
 * **Le filtre des listes de séries** — TCF (CO / CE / Structure, par niveau) et
 * chaque thème civique.
 *
 * 🛑 **« Faite » se lit sur un FAIT SERVI** : `lastScore`, le score du dernier
 * attempt terminé sur ce lot, que le backend joint à la liste. Ni un compteur
 * local, ni un marqueur posé par le front — un candidat qui change d'appareil
 * retrouve exactement les mêmes séries cochées.
 *
 * ⚠️ **Une série faite reste refaisable** : le filtre range, il n'interdit
 * rien. C'est pourquoi « À faire » ne veut pas dire « autorisé », et le verrou
 * freemium reste ailleurs (le rang du lot, opposé par le serveur).
 *
 * Miroir mobile : `screens/module_detail/serie_filtre.dart`.
 */

import type {LotDto} from "./types";

export const SERIE_FILTRES = ["TOUS", "A_FAIRE", "FAITES"] as const;
export type SerieFiltre = (typeof SERIE_FILTRES)[number];

export function serieAccepte(lot: LotDto, filtre: SerieFiltre): boolean {
    switch (filtre) {
        case "A_FAIRE":
            return lot.lastScore == null;
        case "FAITES":
            return lot.lastScore != null;
        default:
            return true;
    }
}

/**
 * Les trois libellés, **compteur compris** — « À faire · 4 ». Un compteur qui
 * vit dans la puce évite de faire compter le candidat, et il dit tout de suite
 * si le filtre a quelque chose à montrer.
 */
export function serieFiltreLabels(lots: readonly LotDto[]): string[] {
    const faites = lots.filter((l) => l.lastScore != null).length;
    return [
        `Toutes · ${lots.length}`,
        `À faire · ${lots.length - faites}`,
        `Faites · ${faites}`,
    ];
}

/**
 * Le sous-ensemble à afficher. 🛑 **L'ordre servi est conservé** : on filtre,
 * on ne retrie jamais — les séries se suivent par numéro.
 */
export function serieFiltrer(lots: readonly LotDto[], filtre: SerieFiltre): LotDto[] {
    return lots.filter((l) => serieAccepte(l, filtre));
}

/** Ce qu'on dit quand le filtre ne retient aucune série. */
export const SERIE_FILTRE_VIDE = "Aucune série dans ce filtre.";
