import "server-only";
import { createHash } from "node:crypto";
import { createAdminClient } from "./admin";

// Only static, reviewed queries in transition_setup.sql can run. Raw SQL and
// the privileged key never cross the browser boundary.
export function database() {
  return async (strings: TemplateStringsArray, ...values: unknown[]): Promise<Record<string, any>[]> => {
    const parts = Array.from(strings, part => part.replace(/\r\n/g, "\n"));
    const id = createHash("sha256").update(JSON.stringify(parts)).digest("hex");
    const { data, error } = await createAdminClient().rpc("sims_query", { query_id: id, query_values: values });
    if (error) {
      if (error.code === "PGRST202" || error.code === "42883") throw new Error("Skema transisi Supabase belum dipasang. Jalankan supabase/transition_setup.sql di SQL Editor.");
      throw new Error("Operasi database gagal. Muat ulang data dan coba kembali.");
    }
    return data || [];
  };
}
