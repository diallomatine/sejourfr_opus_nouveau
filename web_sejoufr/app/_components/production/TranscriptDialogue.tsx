"use client";

export type TranscriptTurn = {speaker: "CANDIDATE" | "EXAMINER"; text: string};

/**
 * Parse une transcription realtime « Candidat : … / Examinateur : … » en tours.
 * Retourne null si aucun marqueur de dialogue (monologue Whisper classique) →
 * l'appelant l'affiche alors en texte simple.
 */
export function parseTranscript(raw: string): TranscriptTurn[] | null {
    const turns: TranscriptTurn[] = [];
    let sawLabel = false;
    for (const line of raw.split("\n")) {
        const row = line.trim();
        if (!row) continue;
        if (row.startsWith("Candidat :")) {
            sawLabel = true;
            turns.push({speaker: "CANDIDATE", text: row.slice("Candidat :".length).trim()});
        } else if (row.startsWith("Examinateur :")) {
            sawLabel = true;
            turns.push({speaker: "EXAMINER", text: row.slice("Examinateur :".length).trim()});
        } else if (turns.length) {
            turns[turns.length - 1].text += ` ${row}`;
        }
    }
    if (!sawLabel) return null;
    return turns.filter((t) => t.text);
}

/**
 * Rend une transcription en dialogue de bulles (examinateur à gauche/bleu,
 * candidat à droite/rouge). Accepte soit des tours structurés (`lines`, session
 * live), soit la chaîne stockée (`raw`, rapport) — un monologue sans marqueurs
 * est rendu en texte simple.
 */
export function TranscriptDialogue({lines, raw}: {lines?: TranscriptTurn[]; raw?: string}) {
    const turns = lines ?? (raw !== undefined ? parseTranscript(raw) : null);

    return (
        <div className="td">
            {turns === null ? (
                <p className="td-mono">{raw}</p>
            ) : (
                turns.map((t, i) => (
                    <div key={i} className={`td-bubble${t.speaker === "CANDIDATE" ? " is-you" : " is-exam"}`}>
                        <span className="td-who">{t.speaker === "CANDIDATE" ? "Vous" : "Examinateur"}</span>
                        <p className="td-text">{t.text}</p>
                    </div>
                ))
            )}
            <style>{`
                .td { display: flex; flex-direction: column; gap: 10px; }
                .td-mono { margin: 0; font-size: 14px; line-height: 1.5; color: var(--color-ink); white-space: pre-wrap; overflow-wrap: anywhere; }
                .td-bubble { max-width: 80%; padding: 9px 13px; border-radius: 14px; display: flex; flex-direction: column; gap: 3px; }
                .td-bubble.is-exam { align-self: flex-start; background: var(--color-blue-light); border-bottom-left-radius: 4px; }
                .td-bubble.is-you { align-self: flex-end; background: var(--color-red-light); border-bottom-right-radius: 4px; }
                .td-who { font-family: var(--font-mono); font-weight: 700; font-size: 10px; letter-spacing: 0.04em; text-transform: uppercase; }
                .td-bubble.is-exam .td-who { color: var(--color-blue); }
                .td-bubble.is-you .td-who { color: var(--color-red-dark); }
                .td-text { margin: 0; font-size: 14px; line-height: 1.45; color: var(--color-ink); white-space: pre-wrap; overflow-wrap: anywhere; }
            `}</style>
        </div>
    );
}
