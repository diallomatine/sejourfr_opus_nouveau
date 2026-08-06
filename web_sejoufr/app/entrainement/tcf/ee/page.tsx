import {redirect} from "next/navigation";
import {EE_CONFIG, productionEntryHref} from "@/app/_components/production/config";

/** L'épreuve n'a pas d'écran d'accueil : on ouvre directement l'espace de
 *  travail de la tâche 1. La route reste servie parce qu'elle est référencée
 *  ailleurs (tableau de bord, landing `/reussir`, `?back=`). */
export default function EeEntryPage() {
  redirect(productionEntryHref(EE_CONFIG.base));
}
