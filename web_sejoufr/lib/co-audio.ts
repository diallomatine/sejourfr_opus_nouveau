/**
 * **L'élément audio PARTAGÉ de la compréhension orale** : le lecteur
 * d'examen (écoute unique) comme le lecteur d'entraînement (contrôles libres)
 * de `MediaView` jouent sur lui, et tous deux démarrent seuls.
 *
 * 🛑 Les navigateurs (iOS Safari et Chrome iOS surtout) refusent un `play()`
 * qui ne vient pas d'un geste de l'utilisateur. À la PREMIÈRE question d'une
 * série ou d'un examen, aucun geste n'a eu lieu sur la page depuis la
 * navigation : l'autoplay échouait et le lecteur tombait sur « Appuyez pour
 * lancer l'écoute ». iOS accorde en revanche la lecture à un ÉLÉMENT une fois
 * qu'il a joué dans un geste — d'où un élément unique, au niveau du module
 * (hors React, il survit à la navigation client), déverrouillé DANS le clic
 * qui lance la session (`unlockCoAudio`), puis réutilisé par le lecteur pour
 * toutes les questions.
 *
 * **Écran allumé pendant l'écoute** : tant que l'élément JOUE (`playing`),
 * il détient un Screen Wake Lock (`lib/wake-lock.ts`), relâché sur `pause`,
 * `ended` ou `emptied` — ce qui couvre la fin, la pause d'entraînement, le
 * changement de question et la sortie de l'écran (les deux lecteurs de
 * `MediaView` font `pause()` au démontage). Branché UNE fois, sur l'élément :
 * examen comme entraînement, aucun composant n'a à s'en soucier.
 *
 * Aucun import React : ce module est chargé par des écrans et des hooks.
 */

import { holdScreenWakeLock } from "./wake-lock";

let element: HTMLAudioElement | null = null;
let silentSrc: string | null = null;

/** Un WAV PCM 8 bits, mono, 0,1 s de silence. */
function silence(): string {
  if (silentSrc) return silentSrc;
  const samples = 800;
  const bytes = new Uint8Array(44 + samples);
  const view = new DataView(bytes.buffer);
  const ascii = (offset: number, text: string) => {
    for (let i = 0; i < text.length; i++) bytes[offset + i] = text.charCodeAt(i);
  };
  ascii(0, "RIFF");
  view.setUint32(4, 36 + samples, true);
  ascii(8, "WAVEfmt ");
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);
  view.setUint16(22, 1, true);
  view.setUint32(24, 8000, true);
  view.setUint32(28, 8000, true);
  view.setUint16(32, 1, true);
  view.setUint16(34, 8, true);
  ascii(36, "data");
  view.setUint32(40, samples, true);
  bytes.fill(0x80, 44);
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  silentSrc = `data:audio/wav;base64,${btoa(binary)}`;
  return silentSrc;
}

function keepScreenAwakeWhilePlaying(el: HTMLAudioElement): void {
  let release: (() => void) | null = null;
  const stop = () => {
    release?.();
    release = null;
  };
  el.addEventListener("playing", () => {
    // Le silence de déverrouillage ne dure que 0,1 s : rien à maintenir.
    if (release || el.src === silentSrc) return;
    release = holdScreenWakeLock();
  });
  el.addEventListener("pause", stop);
  el.addEventListener("ended", stop);
  el.addEventListener("emptied", stop);
}

/** L'élément partagé, créé à la demande (jamais au SSR). */
export function sharedCoAudio(): HTMLAudioElement | null {
  if (typeof window === "undefined" || typeof Audio === "undefined") return null;
  if (!element) {
    element = new Audio();
    element.preload = "auto";
    keepScreenAwakeWhilePlaying(element);
  }
  return element;
}

/**
 * **À appeler SYNCHRONEMENT dans le gestionnaire de clic** qui lance une
 * session TCF où de la CO peut se jouer (série d'entraînement ou examen) —
 * avant tout `await`, sinon le geste est perdu. Joue un silence puis s'arrête : l'élément est alors autorisé pour
 * les `play()` suivants. Sans effet si l'élément sert déjà une question.
 */
export function unlockCoAudio(): void {
  const el = sharedCoAudio();
  if (!el) return;
  if (el.src && el.src !== silentSrc && !el.paused) return;
  const src = silence();
  el.src = src;
  el.play()
    .then(() => {
      // Le lecteur a pu prendre l'élément entre-temps : on ne coupe que le silence.
      if (el.src === src) el.pause();
    })
    .catch(() => {
      // Refus ou interruption : le lecteur gardera son repli « Appuyez pour lancer ».
    });
}
