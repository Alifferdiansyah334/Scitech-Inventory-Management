// @vitest-environment node
import { afterEach, beforeEach, expect, it, vi } from "vitest";
import { GET } from "@/app/api/health/route";
beforeEach(() => {
  for (const key of ["NEXT_PUBLIC_SUPABASE_URL","NEXT_PUBLIC_SUPABASE_ANON_KEY","SUPABASE_SERVICE_ROLE_KEY","BREVO_API_KEY","BREVO_SENDER_EMAIL"]) vi.stubEnv(key,"test-only");
  vi.stubEnv("APP_SESSION_SECRET","test-only-long-server-secret-at-least-32-chars");
});
afterEach(()=>{vi.unstubAllEnvs();vi.unstubAllGlobals();});
it("refuses readiness before the remote transaction and OTP schema is installed",async()=>{
  vi.stubGlobal("fetch",vi.fn().mockResolvedValue({ok:true,json:async()=>({paths:{'/profiles':{},'/items':{},'/loans':{}}})}));
  const response=await GET();expect(response.status).toBe(503);expect(await response.json()).toEqual({status:'setup_required'});
});
it("reports readiness only when every required table and RPC is exposed to the server role",async()=>{
  const paths=Object.fromEntries(['profiles','items','loans','images','mobile_sessions','procurements'].map(name=>['/'+name,{}]));
  for(const name of ['sims_query','sims_issue_otp','sims_check_otp','sims_rate_limit'])paths['/rpc/'+name]={};
  vi.stubGlobal("fetch",vi.fn().mockResolvedValue({ok:true,json:async()=>({paths})}));
  const response=await GET();expect(response.status).toBe(200);expect(await response.json()).toEqual({status:'ready'});
});
it("does not leak credentials when the provider cannot be reached",async()=>{
  vi.stubGlobal("fetch",vi.fn().mockRejectedValue(new Error('secret connection details')));
  const response=await GET();expect(response.status).toBe(503);expect(await response.text()).not.toContain('secret');
});
