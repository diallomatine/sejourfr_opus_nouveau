import { LegalHeader } from "./LegalHeader";
import { LegalSidebar, type SidebarSection } from "./LegalSidebar";
import { LegalFooterNav } from "./LegalFooterNav";
import { BackToTopButton } from "./BackToTopButton";

interface Props {
  title: string;
  description?: string;
  sections: SidebarSection[];
  currentPath: "/mentions-legales" | "/cgu" | "/confidentialite";
  children: React.ReactNode;
}

export function LegalPageLayout({
  title,
  description,
  sections,
  currentPath,
  children,
}: Props) {
  return (
    <div className="legal-page container-x">
      <LegalHeader title={title} description={description} />

      <LegalSidebar sections={sections} variant="mobile" />

      <div className="legal-page-grid">
        <LegalSidebar sections={sections} variant="desktop" />
        <main className="legal-page-main">
          {children}
          <LegalFooterNav currentPath={currentPath} />
        </main>
      </div>

      <BackToTopButton />

      <style>{`
        .legal-page {
          padding-top: 32px;
          padding-bottom: 64px;
          max-width: 1180px;
        }
        @media (min-width: 768px) {
          .legal-page {
            padding-top: 48px;
            padding-bottom: 96px;
          }
        }
        .legal-page-grid {
          display: grid;
          grid-template-columns: 1fr;
          gap: 32px;
        }
        @media (min-width: 1024px) {
          .legal-page-grid {
            grid-template-columns: 240px 1fr;
            gap: 48px;
          }
        }
        .legal-page-main {
          min-width: 0;
        }
      `}</style>
    </div>
  );
}
