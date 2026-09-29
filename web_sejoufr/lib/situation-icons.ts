/**
 * **Les pictogrammes d'épreuve TCF et de thème civique** des cartes de niveau
 * — ceux de « Où vous en êtes » sur l'Accueil, repris tels quels par les écrans
 * de progression (les émojis des maquettes deviennent ces icônes Lucide).
 *
 * 🛑 Déclarés UNE fois : l'Accueil et les écrans de progression les lisent
 * ici. Miroir mobile : `_situationIcon` / `_situationThemeIcon`.
 */
import {
    BookOpen,
    Gavel,
    Globe,
    Headphones,
    Landmark,
    Mic,
    PenLine,
    Scale,
    Users,
    type LucideIcon,
} from "lucide-react";

export const SITUATION_EPREUVE_ICON: Record<string, LucideIcon> = {
    TCF_CO: Headphones,
    TCF_CE: BookOpen,
    TCF_EE: PenLine,
    TCF_EO: Mic,
};

export const SITUATION_THEME_ICON: Record<string, LucideIcon> = {
    CIV_PRINCIPES: Scale,
    CIV_INSTITUTIONS: Landmark,
    CIV_DROITS_DEVOIRS: Gavel,
    CIV_HISTOIRE_GEO: Globe,
    CIV_SOCIETE: Users,
};

/** Le pictogramme d'un code servi, avec un repli neutre. */
export function situationIcon(code: string): LucideIcon {
    return SITUATION_EPREUVE_ICON[code] ?? SITUATION_THEME_ICON[code] ?? BookOpen;
}
