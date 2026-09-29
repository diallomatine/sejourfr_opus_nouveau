"use client";

import { useState } from "react";
import { Check, Copy, Mail, Share2 } from "lucide-react";

interface Props {
  title: string;
  url: string;
}

function TwitterIcon({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden
      className={className}
    >
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231 5.451-6.231Zm-1.161 17.52h1.833L7.084 4.126H5.117L17.083 19.77Z" />
    </svg>
  );
}

function LinkedInIcon({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden
      className={className}
    >
      <path d="M4.98 3.5C4.98 4.881 3.87 6 2.5 6S.02 4.881.02 3.5C.02 2.12 1.13 1 2.5 1s2.48 1.12 2.48 2.5ZM.25 8h4.5v14H.25V8Zm7.5 0h4.32v1.93h.06c.6-1.13 2.07-2.33 4.27-2.33 4.57 0 5.42 3 5.42 6.92V22h-4.5v-6.92c0-1.65-.03-3.78-2.3-3.78-2.31 0-2.67 1.8-2.67 3.66V22H7.75V8Z" />
    </svg>
  );
}

function FacebookIcon({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden
      className={className}
    >
      <path d="M24 12.073C24 5.405 18.627 0 12 0S0 5.405 0 12.073C0 18.1 4.388 23.094 10.125 24v-8.437H7.078v-3.49h3.047V9.412c0-3.014 1.792-4.678 4.532-4.678 1.313 0 2.686.235 2.686.235v2.962h-1.513c-1.49 0-1.955.93-1.955 1.886v2.265h3.328l-.532 3.49h-2.796V24C19.612 23.094 24 18.1 24 12.073Z" />
    </svg>
  );
}

export function ShareButtons({ title, url }: Props) {
  const [copied, setCopied] = useState(false);
  const enc = encodeURIComponent;

  const handleNativeShare = async () => {
    if (typeof navigator !== "undefined" && "share" in navigator) {
      try {
        await navigator.share({ title, url });
      } catch {
        /* user dismissed */
      }
    } else {
      handleCopy();
    }
  };

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      /* clipboard unavailable */
    }
  };

  const links: {
    label: string;
    href: string;
    icon: React.ComponentType<{ className?: string }>;
  }[] = [
    {
      label: "Partager sur X",
      href: `https://twitter.com/intent/tweet?text=${enc(title)}&url=${enc(url)}`,
      icon: TwitterIcon,
    },
    {
      label: "Partager sur LinkedIn",
      href: `https://www.linkedin.com/sharing/share-offsite/?url=${enc(url)}`,
      icon: LinkedInIcon,
    },
    {
      label: "Partager sur Facebook",
      href: `https://www.facebook.com/sharer/sharer.php?u=${enc(url)}`,
      icon: FacebookIcon,
    },
    {
      label: "Partager par email",
      href: `mailto:?subject=${enc(title)}&body=${enc(url)}`,
      icon: Mail,
    },
  ];

  return (
    <div className="share-buttons">
      <button
        type="button"
        onClick={handleNativeShare}
        className="share-buttons-mobile"
      >
        <Share2 className="share-buttons-mobile-icon" />
        Partager l&apos;article
      </button>

      <div className="share-buttons-desktop">
        {links.map((l) => {
          const Icon = l.icon;
          return (
            <a
              key={l.label}
              href={l.href}
              target="_blank"
              rel="noopener noreferrer"
              aria-label={l.label}
              className="share-buttons-item"
            >
              <Icon className="share-buttons-item-icon" />
            </a>
          );
        })}
        <button
          type="button"
          onClick={handleCopy}
          aria-label={copied ? "Lien copié" : "Copier le lien"}
          className="share-buttons-item"
        >
          {copied ? (
            <Check className="share-buttons-item-icon share-buttons-item-icon--success" />
          ) : (
            <Copy className="share-buttons-item-icon" />
          )}
        </button>
      </div>

      <style>{`
        .share-buttons {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: 8px;
        }
        .share-buttons-mobile {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          padding: 11px 18px;
          min-height: 44px;
          width: 100%;
          border: 0;
          border-radius: 10px;
          background: var(--color-blue);
          color: #fff;
          font-family: var(--font-sans);
          font-size: 14px;
          font-weight: 600;
          letter-spacing: -0.005em;
          cursor: pointer;
        }
        @media (min-width: 640px) {
          .share-buttons-mobile {
            display: none;
          }
        }
        .share-buttons-mobile-icon {
          width: 16px;
          height: 16px;
        }
        .share-buttons-desktop {
          display: none;
        }
        @media (min-width: 640px) {
          .share-buttons-desktop {
            display: inline-flex;
            align-items: center;
            gap: 8px;
          }
        }
        .share-buttons-item {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 40px;
          height: 40px;
          border-radius: 10px;
          background: #fff;
          border: 1px solid var(--color-line);
          color: var(--color-muted);
          cursor: pointer;
          transition: border-color 0.15s, color 0.15s;
          text-decoration: none;
        }
        .share-buttons-item:hover {
          border-color: var(--color-blue);
          color: var(--color-blue);
        }
        .share-buttons-item-icon {
          width: 16px;
          height: 16px;
        }
        .share-buttons-item-icon--success {
          color: var(--color-green);
        }
      `}</style>
    </div>
  );
}
