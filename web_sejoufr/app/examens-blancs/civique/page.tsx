import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { ExamsModuleView } from "@/app/_components/ExamsModuleView";

export default function CiviqueExamsPage() {
  return (
    <DualChromeShell>
      <ExamsModuleView module="CIVIQUE" />
    </DualChromeShell>
  );
}
