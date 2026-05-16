import React from "react";

/**
 * Mini-renderer markdown léger pour les réponses FAQ. Couvre :
 *   - paragraphes (séparés par lignes vides)
 *   - listes à puces ("- " en début de ligne)
 *   - listes numérotées ("1. " en début de ligne)
 *   - **gras**
 *   - [texte](url) — externes : target=_blank
 *
 * Pas de lib (markdown-it / remark) parce que c'est ~30 lignes pour ce qu'on
 * a vraiment besoin et ça reste type-safe + tree-shakable.
 *
 * Si `highlight` est fourni, le terme est encadré d'une balise <mark>.
 */
interface Props {
  source: string;
  highlight?: string;
}

interface Block {
  type: "p" | "ul" | "ol";
  lines: string[];
}

function parse(source: string): Block[] {
  const lines = source.split("\n");
  const blocks: Block[] = [];
  let buffer: Block | null = null;

  const flush = () => {
    if (buffer) {
      blocks.push(buffer);
      buffer = null;
    }
  };

  for (const raw of lines) {
    const line = raw;
    if (line.trim() === "") {
      flush();
      continue;
    }
    if (line.startsWith("- ")) {
      if (buffer && buffer.type === "ul") {
        buffer.lines.push(line.slice(2));
      } else {
        flush();
        buffer = { type: "ul", lines: [line.slice(2)] };
      }
      continue;
    }
    const olMatch = line.match(/^(\d+)\.\s+(.*)$/);
    if (olMatch) {
      if (buffer && buffer.type === "ol") {
        buffer.lines.push(olMatch[2]);
      } else {
        flush();
        buffer = { type: "ol", lines: [olMatch[2]] };
      }
      continue;
    }
    if (buffer && buffer.type === "p") {
      buffer.lines.push(line);
    } else {
      flush();
      buffer = { type: "p", lines: [line] };
    }
  }
  flush();
  return blocks;
}

/** Tokenize une string en alternant texte / balises inline (gras, lien). */
function renderInline(
  text: string,
  highlight: string | undefined,
  keyPrefix = "",
): React.ReactNode[] {
  // Pattern qui capture **gras** ou [label](url)
  const pattern = /(\*\*[^*]+\*\*|\[[^\]]+\]\([^)]+\))/g;
  const parts: React.ReactNode[] = [];
  let lastIdx = 0;
  let match: RegExpExecArray | null;
  let i = 0;

  while ((match = pattern.exec(text)) !== null) {
    if (match.index > lastIdx) {
      parts.push(
        renderHighlighted(
          text.slice(lastIdx, match.index),
          highlight,
          `${keyPrefix}-t-${i++}`,
        ),
      );
    }
    const token = match[0];
    if (token.startsWith("**") && token.endsWith("**")) {
      parts.push(
        <strong key={`${keyPrefix}-b-${i++}`} className="md-strong">
          {renderHighlighted(token.slice(2, -2), highlight, `${keyPrefix}-bi-${i}`)}
        </strong>,
      );
    } else {
      // [label](url)
      const linkMatch = token.match(/^\[([^\]]+)\]\(([^)]+)\)$/);
      if (linkMatch) {
        const [, label, url] = linkMatch;
        const isExternal = /^https?:\/\//.test(url);
        parts.push(
          <a
            key={`${keyPrefix}-a-${i++}`}
            href={url}
            target={isExternal ? "_blank" : undefined}
            rel={isExternal ? "noopener noreferrer" : undefined}
            className="md-link"
          >
            {renderHighlighted(label, highlight, `${keyPrefix}-ai-${i}`)}
          </a>,
        );
      }
    }
    lastIdx = match.index + token.length;
  }
  if (lastIdx < text.length) {
    parts.push(
      renderHighlighted(text.slice(lastIdx), highlight, `${keyPrefix}-t-${i++}`),
    );
  }
  return parts;
}

/** Surligne `highlight` dans `text` (insensible à la casse + accents). */
function renderHighlighted(
  text: string,
  highlight: string | undefined,
  key: string,
): React.ReactNode {
  if (!highlight) return <React.Fragment key={key}>{text}</React.Fragment>;
  const norm = (s: string) =>
    s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
  const haystack = norm(text);
  const needle = norm(highlight);
  if (!needle) return <React.Fragment key={key}>{text}</React.Fragment>;
  const idx = haystack.indexOf(needle);
  if (idx === -1) return <React.Fragment key={key}>{text}</React.Fragment>;
  return (
    <React.Fragment key={key}>
      {text.slice(0, idx)}
      <mark className="md-mark">
        {text.slice(idx, idx + highlight.length)}
      </mark>
      {renderHighlighted(text.slice(idx + highlight.length), highlight, key + "-r")}
    </React.Fragment>
  );
}

export function MarkdownLight({ source, highlight }: Props) {
  const blocks = parse(source);
  return (
    <div className="md-root">
      {blocks.map((b, idx) => {
        if (b.type === "p") {
          return (
            <p key={`p-${idx}`}>
              {renderInline(b.lines.join(" "), highlight, `p-${idx}`)}
            </p>
          );
        }
        if (b.type === "ul") {
          return (
            <ul key={`ul-${idx}`} className="md-list md-ul">
              {b.lines.map((line, j) => (
                <li key={`ul-${idx}-${j}`}>
                  {renderInline(line, highlight, `ul-${idx}-${j}`)}
                </li>
              ))}
            </ul>
          );
        }
        return (
          <ol key={`ol-${idx}`} className="md-list md-ol">
            {b.lines.map((line, j) => (
              <li key={`ol-${idx}-${j}`}>
                {renderInline(line, highlight, `ol-${idx}-${j}`)}
              </li>
            ))}
          </ol>
        );
      })}

      <style>{`
        .md-root {
          display: flex;
          flex-direction: column;
          gap: 14px;
          font-family: var(--font-sans);
          font-size: 15px;
          line-height: 1.65;
          color: var(--color-ink-2);
        }
        .md-root p { margin: 0; }
        .md-strong { font-weight: 600; color: var(--color-ink); }
        .md-link {
          color: var(--color-blue);
          text-decoration: underline;
          text-decoration-color: rgba(30, 58, 140, 0.35);
          text-underline-offset: 2px;
          transition: text-decoration-color 0.15s ease;
        }
        .md-link:hover {
          text-decoration-color: var(--color-blue);
        }
        .md-mark {
          background: rgba(232, 163, 23, 0.32);
          color: inherit;
          border-radius: 3px;
          padding: 0 2px;
        }
        .md-list {
          margin: 0;
          padding-left: 22px;
          display: flex;
          flex-direction: column;
          gap: 8px;
        }
        .md-list li::marker {
          color: var(--color-blue);
        }
        .md-ol li::marker {
          font-weight: 600;
        }
        @media (min-width: 1024px) {
          .md-root { font-size: 15.5px; }
          .md-list { padding-left: 24px; }
        }
      `}</style>
    </div>
  );
}
