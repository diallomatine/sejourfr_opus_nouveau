import Image from "next/image";

interface Props {
  src: string;
  alt: string;
  caption?: string;
  width?: number;
  height?: number;
  /** Si true, l'image prend toute la largeur du conteneur (ratio 16/9). */
  fluid?: boolean;
}

export function ImageWithCaption({
  src,
  alt,
  caption,
  width = 1200,
  height = 675,
  fluid = false,
}: Props) {
  return (
    <figure className="mdx-figure">
      <div className={fluid ? "mdx-figure-wrap mdx-figure-wrap--fluid" : "mdx-figure-wrap"}>
        {fluid ? (
          <Image src={src} alt={alt} fill className="mdx-figure-img" />
        ) : (
          <Image
            src={src}
            alt={alt}
            width={width}
            height={height}
            className="mdx-figure-img"
          />
        )}
      </div>
      {caption && <figcaption className="mdx-figure-caption">{caption}</figcaption>}
      <style>{`
        .mdx-figure {
          margin: 32px 0;
        }
        @media (min-width: 1024px) {
          .mdx-figure {
            margin: 40px 0;
          }
        }
        .mdx-figure-wrap {
          overflow: hidden;
          border-radius: 14px;
          background: var(--color-paper-2);
        }
        @media (min-width: 1024px) {
          .mdx-figure-wrap {
            border-radius: 18px;
          }
        }
        .mdx-figure-wrap--fluid {
          position: relative;
          aspect-ratio: 16 / 9;
        }
        .mdx-figure-img {
          width: 100%;
          height: auto;
          display: block;
        }
        .mdx-figure-wrap--fluid .mdx-figure-img {
          object-fit: cover;
        }
        .mdx-figure-caption {
          margin-top: 12px;
          text-align: center;
          font-size: 13.5px;
          font-style: italic;
          color: var(--color-muted);
        }
      `}</style>
    </figure>
  );
}
