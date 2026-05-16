import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { ExamsModuleView } from "@/app/_components/ExamsModuleView";

export default function TcfExamsPage() {
  return (
    <DualChromeShell>
      <ExamsModuleView module="TCF" />
    </DualChromeShell>
  );
}
