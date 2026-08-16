"use client";

import {useEffect, useRef, useState} from "react";
import styles from "./production.module.css";

/**
 * Retour visuel de la capture micro : pastille d'état, forme d'onde **pilotée
 * par la voix réelle**, et aveu franc quand rien n'est capté.
 *
 * ⚠️ **Le mouvement suit la voix, il ne la simule pas.** Une animation
 * décorative à amplitude fixe est pire que rien : elle ondule pareil qu'on
 * parle ou qu'on se taise, donc un micro muet (onglet qui a perdu le flux,
 * permission révoquée en cours de route, mauvais périphérique d'entrée) devient
 * indiscernable d'un enregistrement qui marche — et le candidat ne l'apprend
 * qu'après analyse. La sinusoïde reste, elle donne la texture, mais **son
 * amplitude vient du niveau d'entrée mesuré**.
 *
 * Un plancher de mouvement de quelques pixels est conservé : une forme d'onde
 * **figée** se lit comme une page plantée, pas comme un silence.
 *
 * Miroir de `RecordingWaveform` / `RecordingPill` / `_VoiceHint` côté mobile,
 * **jusqu'aux seuils** : l'amplitude est ramenée à la même échelle 0..1 (dBFS
 * −60 → 0) avant d'appliquer le même plancher de bruit et le même seuil
 * d'audibilité, sinon les deux fronts diraient deux choses différentes du même
 * silence.
 */

/** Sous ce niveau normalisé, c'est du bruit de fond, pas de la voix. */
const NOISE_FLOOR = 0.25;

/** Au-dessus de ce niveau, la forme d'onde est à son amplitude maximale. */
const VOICE_CEILING = 0.8;

/** Au-dessus de ce niveau de voix, on considère que quelqu'un parle. */
const AUDIBLE_LEVEL = 0.06;

/**
 * Le silence n'est signalé qu'au bout de ce délai : une pause pour chercher ses
 * mots est normale à l'oral, et le public de la plateforme apprend le français.
 */
const SILENCE_GRACE_MS = 3000;

const BAR_COUNT = 33;

/** Hauteur maximale d'une barre, en px — doit suivre `.waveBar` dans le CSS. */
const BAR_MAX_PX = 62;

export const RECORDING_PILL_LABEL = "Enregistrement…";

/** Libellé gelé, miroir mot pour mot de `_VoiceHint` côté mobile. */
export const RECORDING_UNHEARD_LABEL =
  "On ne vous entend pas. Rapprochez-vous du micro ou parlez plus fort.";

/** Ramène une RMS 0..1 sur l'échelle d'amplitude du mobile (dBFS −60 → 0). */
function amplitudeFromRms(rms: number): number {
  if (rms <= 0) return 0;
  const dbfs = 20 * Math.log10(rms);
  return Math.min(1, Math.max(0, (dbfs + 60) / 60));
}

/** Amplitude brute 0..1 → **niveau de voix** 0..1, bruit de fond ramené à zéro. */
function voiceLevel(amplitude: number): number {
  return Math.min(1, Math.max(0, (amplitude - NOISE_FLOOR) / (VOICE_CEILING - NOISE_FLOOR)));
}

function audioContextCtor(): typeof AudioContext | null {
  if (typeof window === "undefined") return null;
  return (
    window.AudioContext ??
    (window as unknown as {webkitAudioContext?: typeof AudioContext}).webkitAudioContext ??
    null
  );
}

export function RecordingLevelMeter({stream}: {stream: MediaStream | null}) {
  const barsRef = useRef<(HTMLSpanElement | null)[]>([]);
  const [unheard, setUnheard] = useState(false);
  // Miroir du verdict courant : la boucle d'animation ne re-rend que sur
  // bascule, elle a donc besoin de savoir ce qui est déjà affiché — y compris
  // au tout premier tour d'un nouveau flux.
  const unheardRef = useRef(false);

  useEffect(() => {
    if (!stream) return;
    const Ctor = audioContextCtor();
    if (!Ctor) return;

    let ctx: AudioContext;
    try {
      ctx = new Ctor();
    } catch {
      return;
    }
    // Le candidat vient de cliquer pour enregistrer : le geste utilisateur est
    // acquis, mais un contexte peut naître `suspended` selon le navigateur.
    void ctx.resume().catch(() => undefined);

    const source = ctx.createMediaStreamSource(stream);
    const analyser = ctx.createAnalyser();
    analyser.fftSize = 1024;
    analyser.smoothingTimeConstant = 0.6;
    source.connect(analyser);

    const samples = new Uint8Array(analyser.fftSize);
    // Horloge monotone : `Date.now()` recule si l'horloge système est ajustée.
    let lastVoiceAt = performance.now();
    let announced = unheardRef.current;
    let frame = 0;
    let stopped = false;

    const tick = () => {
      if (stopped) return;
      frame = requestAnimationFrame(tick);

      analyser.getByteTimeDomainData(samples);
      let sum = 0;
      for (let i = 0; i < samples.length; i += 1) {
        const centered = (samples[i] - 128) / 128;
        sum += centered * centered;
      }
      const level = voiceLevel(amplitudeFromRms(Math.sqrt(sum / samples.length)));

      const now = performance.now();
      if (level > AUDIBLE_LEVEL) lastVoiceAt = now;
      const silent = now - lastVoiceAt >= SILENCE_GRACE_MS;
      // Le verdict change rarement ; le niveau, lui, arrive soixante fois par
      // seconde — on ne re-rend que sur bascule.
      if (silent !== announced) {
        announced = silent;
        unheardRef.current = silent;
        setUnheard(silent);
      }

      const phase = (now / 1200) * 2 * Math.PI;
      const swing = 4 + level * 22;
      for (let i = 0; i < BAR_COUNT; i += 1) {
        const bar = barsRef.current[i];
        if (!bar) continue;
        const wave = Math.abs(Math.sin(phase + i * 0.55)) * swing;
        const height = Math.min(BAR_MAX_PX, Math.max(6, 8 + level * 30 + wave));
        bar.style.transform = `scaleY(${(height / BAR_MAX_PX).toFixed(3)})`;
      }
    };
    frame = requestAnimationFrame(tick);

    return () => {
      stopped = true;
      cancelAnimationFrame(frame);
      try {
        source.disconnect();
        analyser.disconnect();
      } catch {
        // le flux peut déjà être coupé : rien à libérer de plus
      }
      void ctx.close().catch(() => undefined);
    };
  }, [stream]);

  return (
    <div className={styles.recLive}>
      <span className={styles.recPill} role="status">
        <span className={styles.recDot} aria-hidden />
        {RECORDING_PILL_LABEL}
      </span>

      <div className={styles.wave} aria-hidden>
        {Array.from({length: BAR_COUNT}, (_, i) => (
          <span
            key={i}
            className={styles.waveBar}
            ref={(el) => {
              barsRef.current[i] = el;
            }}
          />
        ))}
      </div>

      {unheard && (
        <p className={styles.recUnheard} role="status">
          {RECORDING_UNHEARD_LABEL}
        </p>
      )}
    </div>
  );
}
