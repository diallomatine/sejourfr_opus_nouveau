-- ---------------------------------------------------------------------------
-- V035 — Le cout d'une TRANSCRIPTION cesse d'etre arrondi au CENTIME SUPERIEUR.
--
-- Suite directe de V034, et dernier endroit du depot qui arrondissait une
-- facture au centime. V034 avait laisse `transcriptions.cout_estime_centimes`
-- active, au motif qu'elle vient de Whisper — facture a la MINUTE d'audio et
-- non au token, donc etrangere aux tarifs d'un LLM. C'est exact sur la
-- FORMULE, mais l'UNITE et l'ARRONDI, eux, sont une decision du depot :
-- `Math.ceil` au centime sur un tarif de 0,006 $/minute facture 1 centime un
-- audio de 95 s (la mediane du depot) qui en vaut 0,95, soit ~5 % de trop.
-- Sans commune mesure avec le facteur ~8 des micro-analyses LLM, mais c'etait
-- la derniere colonne du depot a mentir sur ce qu'on depense.
--
-- La colonne porte donc le cout en MICRO-DOLLARS (millioniemes de dollar) :
-- un entier, additionnable sans erreur de virgule flottante, et assez fin pour
-- qu'une transcription d'une seconde en vaille encore 100. L'arrondi reste au
-- SUPERIEUR — la prudence historique est conservee, a une granularite 10 000
-- fois plus fine. Regle partagee avec les appels LLM : `util/MicroDollars`,
-- appelee par `CoutAppelLlm` (au token) comme par `CoutTranscription` (a la
-- minute). Les deux FORMULES restent distinctes, seule l'unite est commune.
--
-- RIEN N'EST REECRIT. `cout_estime_centimes` garde ses valeurs : c'est
-- l'historique, ecrit avec le tarif et l'arrondi de son epoque. Elle devient
-- LEGACY — plus jamais ecrite, plus mappee par JPA. Ne pas ecrire de migration
-- de purge ni de recalcul retroactif : le tarif du jour n'a jamais ete stocke a
-- cote de la duree, donc un recalcul serait une invention. Meme doctrine que
-- V034.
--
-- Le tarif a la minute vit desormais en configuration
-- (`sejourfr.openai.whisper.cost-per-minute-usd`, variable
-- OPENAI_WHISPER_COST_PER_MINUTE) et non plus en constante Java : il voyage
-- avec le modele, dans la meme source, exactement comme les tarifs des
-- correcteurs.
-- ---------------------------------------------------------------------------

ALTER TABLE transcriptions
    ADD COLUMN cout_micro_usd bigint;

COMMENT ON COLUMN transcriptions.cout_micro_usd IS
    'Cout estime de la transcription en MILLIONIEMES de dollar (duree x tarif/minute, arrondi au superieur). Remplace cout_estime_centimes, laissee LEGACY.';
COMMENT ON COLUMN transcriptions.cout_estime_centimes IS
    'LEGACY, plus jamais ecrite depuis V035. Lire cout_micro_usd.';
