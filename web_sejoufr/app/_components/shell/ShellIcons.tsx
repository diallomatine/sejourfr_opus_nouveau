/**
 * Les pictogrammes de la maquette « Navigation v2 » (trait 2 px, arrondis),
 * repris tels quels. `currentColor` partout : la couleur vient du contexte.
 */
import type {ReactNode} from "react";

function Svg({children}: {children: ReactNode}) {
    return (
        <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth={2}
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden
        >
            {children}
        </svg>
    );
}

export function IconHome() {
    return (
        <Svg>
            <path d="m3 10 9-7 9 7" />
            <path d="M5 9.5V21h14V9.5" />
            <path d="M9 21v-6h6v6" />
        </Svg>
    );
}

/** La carte dépliée : le module TCF et son Plan. */
export function IconMap() {
    return (
        <Svg>
            <path d="M4 6.5 9 4l6 2.5L20 4v13.5L15 20l-6-2.5L4 20V6.5Z" />
            <path d="M9 4v13.5" />
            <path d="M15 6.5V20" />
        </Svg>
    );
}

export function IconTarget() {
    return (
        <Svg>
            <circle cx="12" cy="12" r="8" />
            <circle cx="12" cy="12" r="4" />
            <circle cx="12" cy="12" r="1" />
        </Svg>
    );
}

export function IconSheet() {
    return (
        <Svg>
            <path d="M5 4h14v16H5z" />
            <path d="M9 8h6" />
            <path d="M9 12h6" />
            <path d="M9 16h3" />
        </Svg>
    );
}

export function IconChart() {
    return (
        <Svg>
            <path d="M4 20V10" />
            <path d="M10 20V4" />
            <path d="M16 20v-7" />
            <path d="M22 20H2" />
        </Svg>
    );
}

/** Le bouclier coché : le module civique et son Plan. */
export function IconShield() {
    return (
        <Svg>
            <path d="M12 3 4 7v5c0 5 3.4 8.1 8 9 4.6-.9 8-4 8-9V7l-8-4Z" />
            <path d="m9.5 12 1.6 1.6 3.6-3.6" />
        </Svg>
    );
}

export function IconBook() {
    return (
        <Svg>
            <path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H11v16H6.5A2.5 2.5 0 0 0 4 21.5v-16Z" />
            <path d="M20 5.5A2.5 2.5 0 0 0 17.5 3H13v16h4.5A2.5 2.5 0 0 1 20 21.5v-16Z" />
        </Svg>
    );
}

export function IconClock() {
    return (
        <Svg>
            <path d="M12 8v5l3 2" />
            <circle cx="12" cy="12" r="8" />
        </Svg>
    );
}

export function IconUser() {
    return (
        <Svg>
            <circle cx="12" cy="8" r="4" />
            <path d="M4.5 21a7.5 7.5 0 0 1 15 0" />
        </Svg>
    );
}

export function IconBurger() {
    return (
        <Svg>
            <path d="M4 7h16" />
            <path d="M4 12h16" />
            <path d="M4 17h16" />
        </Svg>
    );
}

export function IconClose() {
    return (
        <Svg>
            <path d="M6 6l12 12" />
            <path d="M18 6 6 18" />
        </Svg>
    );
}

export function IconChevronRight() {
    return (
        <Svg>
            <path d="m9 6 6 6-6 6" />
        </Svg>
    );
}

export function IconArrowLeft() {
    return (
        <Svg>
            <path d="M19 12H5" />
            <path d="m10 7-5 5 5 5" />
        </Svg>
    );
}
