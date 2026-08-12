import assert from "node:assert/strict";
import test from "node:test";
import {
  AUDIENCE_EVENTS_BY_PATH,
  isAudienceEventAllowed,
  trafficSourceFromRaw,
  withTrafficSource,
} from "./audience-events.ts";
import {safeInternalPath} from "./security.ts";

test("la liste blanche web reflète les trois chemins suivis par le backend", () => {
  assert.deepEqual(Object.keys(AUDIENCE_EVENTS_BY_PATH).sort(), [
    "/diagnostic",
    "/plan",
    "/reussir",
  ]);
});

test("un événement ne peut pas être envoyé sur le mauvais écran", () => {
  assert.equal(isAudienceEventAllowed("/diagnostic", "DIAGNOSTIC_STARTED"), true);
  assert.equal(isAudienceEventAllowed("/plan", "PLAN_RECOMMENDED_EXERCISE_STARTED"), true);
  assert.equal(isAudienceEventAllowed("/reussir", "SOCIAL_LANDING_DIAGNOSTIC_CLICKED"), true);
  assert.equal(isAudienceEventAllowed("/reussir", "DIAGNOSTIC_STARTED"), false);
  assert.equal(isAudienceEventAllowed("/plan", "VIEW"), false);
});

test("la provenance sociale reste une dimension fermée et non personnelle", () => {
  assert.equal(trafficSourceFromRaw("Instagram"), "instagram");
  assert.equal(trafficSourceFromRaw("https://youtu.be/demo"), "youtube");
  assert.equal(trafficSourceFromRaw("newsletter-client-42"), null);
});

test("la provenance traverse le next d'authentification sans open redirect", () => {
  const diagnostic = withTrafficSource("/diagnostic", "instagram");
  assert.equal(diagnostic, "/diagnostic?src=instagram");
  assert.equal(safeInternalPath(diagnostic, "/dashboard"), diagnostic);
  assert.equal(
    `/inscription?next=${encodeURIComponent(diagnostic)}`,
    "/inscription?next=%2Fdiagnostic%3Fsrc%3Dinstagram",
  );
  assert.equal(withTrafficSource("https://evil.example/diagnostic", "instagram"), "/");
  assert.equal(withTrafficSource("//evil.example/diagnostic", "instagram"), "/");
});
