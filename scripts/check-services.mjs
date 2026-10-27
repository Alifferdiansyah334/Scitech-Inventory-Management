import nextEnv from "@next/env";
nextEnv.loadEnvConfig(process.cwd());
const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) throw new Error("Supabase server configuration missing.");
const headers = { apikey: key, Authorization: "Bearer " + key };
let pending = false;
try {
  const response = await fetch(url + "/rest/v1/", { headers, signal: AbortSignal.timeout(15000) });
  if (!response.ok) throw new Error("Supabase API rejected the configuration (" + response.status + ").");
  const spec = await response.json();
  console.log("Supabase API: connected.");
  for (const name of ["profiles", "items", "loans", "images", "mobile_sessions", "procurements"]) {
    const present = !!spec.paths?.["/" + name];
    console.log(name + ": " + (present ? "available" : "setup required"));
    if (!present) pending = true;
  }
  for (const name of ["sims_query", "sims_issue_otp", "sims_check_otp", "sims_rate_limit"]) {
    const present = !!spec.paths?.["/rpc/" + name];
    console.log(name + ": " + (present ? "available" : "setup required"));
    if (!present) pending = true;
  }
  const settings = await fetch(url + "/auth/v1/settings", { headers: { apikey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY }, signal: AbortSignal.timeout(15000) });
  console.log("Supabase Auth: " + (settings.ok ? "reachable" : "unavailable"));
  if (!settings.ok) pending = true;
  const brevo = await fetch("https://api.brevo.com/v3/senders", { headers: { "api-key": process.env.BREVO_API_KEY }, signal: AbortSignal.timeout(15000) });
  if (!brevo.ok) throw new Error("Brevo configuration rejected (" + brevo.status + ").");
  const senders = await brevo.json();
  const active = senders.senders?.some(sender => sender.email === process.env.BREVO_SENDER_EMAIL && sender.active);
  console.log("Brevo configured sender: " + (active ? "active" : "activation required"));
  if (!active) pending = true;
  console.log("No emails sent; no data changed.");
  if (pending) { console.log("Owner action: run supabase/transition_setup.sql in SQL Editor."); process.exitCode = 2; }
} catch { console.error("Service check failed. Verify connectivity and configuration; credentials are not logged."); process.exitCode = 1; }
