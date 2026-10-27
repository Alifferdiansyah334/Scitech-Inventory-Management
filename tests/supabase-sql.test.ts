// @vitest-environment node
import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import fs from "node:fs";
import { PGlite } from "@electric-sql/pglite";

const state = vi.hoisted(() => ({ rpc: vi.fn(), admin: false }));
const adminId = "11111111-1111-4111-8111-111111111111";
const clientId = "33333333-3333-4333-8333-333333333333";
const itemId = "22222222-2222-4222-8222-222222222222";
vi.mock("server-only", () => ({}));
vi.mock("@/lib/supabase/admin", () => ({ createAdminClient: () => ({ rpc: state.rpc }) }));
vi.mock("@/lib/auth/session", () => ({
  requireProfile: async () => state.admin ? ({ user_id:"11111111-1111-4111-8111-111111111111",role:"admin" }) : ({ user_id: "33333333-3333-4333-8333-333333333333", role: "client" }),
  requireAdmin: async () => ({ user_id: "11111111-1111-4111-8111-111111111111", role: "admin" }),
}));
import { approveLoan, createLoanRequest, markLoanReturned, requestReturn } from "@/lib/actions/loans";
import { cancelLoan, handoverLoan } from "@/lib/actions/mobile-loans";
import { createItem, updateItem } from "@/lib/actions/items";
import { getCatalogItems } from "@/lib/backend/queries";
const db = new PGlite();

beforeAll(async () => {
  // The live project's inspected initial schema, with no remote credentials.
  await db.exec(`
    CREATE ROLE anon; CREATE ROLE authenticated; CREATE ROLE service_role BYPASSRLS;
    GRANT USAGE ON SCHEMA public TO service_role;
    CREATE SCHEMA auth; CREATE TABLE auth.users(id uuid PRIMARY KEY);
    CREATE TYPE public.user_role AS ENUM ('admin','client');
    CREATE TYPE public.loan_status AS ENUM ('pending','approved','rejected','returned','overdue','returning');
    CREATE TABLE profiles (id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid UNIQUE, full_name text NOT NULL,email text UNIQUE NOT NULL,
      role user_role DEFAULT 'client',department text DEFAULT '',avatar_url text DEFAULT '',is_active boolean DEFAULT true,created_at timestamptz DEFAULT now());
    CREATE TABLE items (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL,description text,category text NOT NULL,
      quantity_total integer NOT NULL DEFAULT 1,quantity_available integer NOT NULL DEFAULT 1,image_id text,image_url text,is_available boolean DEFAULT true,created_at timestamptz DEFAULT now());
    CREATE TABLE loans (id uuid PRIMARY KEY DEFAULT gen_random_uuid(),item_id uuid REFERENCES items(id),borrower_id uuid REFERENCES profiles(user_id),
      quantity integer NOT NULL,purpose text NOT NULL,borrow_date timestamptz,return_date timestamptz,actual_return_date timestamptz,status loan_status DEFAULT 'pending',
      admin_id uuid REFERENCES profiles(user_id),admin_note text,return_image_id text,return_image_url text,user_note text,created_at timestamptz DEFAULT now());
  `);
  await db.exec(fs.readFileSync("supabase/transition_setup.sql", "utf8"));
  state.rpc.mockImplementation(async (name: string, args: { query_id: string; query_values: unknown[] }) => {
    try {
      const result = await db.query<{ result: unknown[] }>("SELECT sims_query($1::text,$2::jsonb) AS result", [args.query_id, JSON.stringify(args.query_values)]);
      return { data: result.rows[0].result, error: null };
    } catch (error) { return { data: null, error }; }
  });
}, 60_000);
beforeEach(async () => {
  state.admin = false;
  await db.exec("RESET ROLE; TRUNCATE loans, images, mobile_sessions, procurements, items, profiles CASCADE; TRUNCATE sims_private.otp_challenges;");
  await db.query('INSERT INTO auth.users(id) VALUES($1),($2) ON CONFLICT DO NOTHING',[adminId,clientId]);
  await db.query("INSERT INTO profiles(user_id,full_name,email,role) VALUES($1,'Admin','admin@example.com','admin'),($2,'Client','client@example.com','client')", [adminId, clientId]);
  await db.query("INSERT INTO items(id,name,category,quantity_total,quantity_available) VALUES($1,'Test item','Tools',5,5)", [itemId]);
  await db.exec("SET ROLE service_role");
});
afterAll(async () => { await db.close(); });

async function stock() {
  const result = await db.query<{ quantity_available: number }>("SELECT quantity_available FROM items WHERE id=$1", [itemId]);
  return result.rows[0].quantity_available;
}
async function loan() {
  const result = await createLoanRequest({ item_id: itemId, quantity: 2, purpose: "Pengujian alat", borrow_date: new Date(Date.now()+3600000).toISOString(), return_date: new Date(Date.now()+7200000).toISOString() });
  expect(result.success).toBe(true);
  return (result.data as { id: string }).id;
}

describe("Supabase transition SQL on local PostgreSQL", () => {
  it("updates inventory quantities with explicitly typed SQL values", async () => {
    const result=await updateItem(itemId,{name:'Barang diperbarui',category:'Peralatan',quantity_total:7,quantity_available:7,is_available:true});
    expect(result.success).toBe(true);
    expect(await stock()).toBe(7);
  });
  it("restores stock exactly once when an admin cancels an approved legacy loan", async () => {
    const id=await loan();
    await approveLoan({loanId:id});
    await db.query('UPDATE loans SET approved_at=NULL WHERE id=$1',[id]);
    state.admin=true;
    expect((await cancelLoan({loanId:id,admin_note:'Pembatalan uji'})).success).toBe(true);
    expect(await stock()).toBe(5);
    expect((await cancelLoan({loanId:id,admin_note:'Pembatalan ulang'})).success).toBe(false);
    expect(await stock()).toBe(5);
  });
  it("enforces the shared per-source rate limit and resets expired windows", async () => {
    const query = "SELECT sims_rate_limit('rate-fixture',2,60) AS allowed";
    expect((await db.query<{allowed:boolean}>(query)).rows[0].allowed).toBe(true);
    expect((await db.query<{allowed:boolean}>(query)).rows[0].allowed).toBe(true);
    expect((await db.query<{allowed:boolean}>(query)).rows[0].allowed).toBe(false);
    await db.exec("UPDATE sims_private.request_windows SET expires_at=now()-interval '1 second' WHERE key_hash='rate-fixture'");
    expect((await db.query<{allowed:boolean}>(query)).rows[0].allowed).toBe(true);
  });
  it("makes an admin-created item available through the borrower catalog query", async () => {
    const result = await createItem({ name: "Barang Uji Admin", category: "Peralatan", quantity_total: 4, quantity_available: 4, is_available: true });
    expect(result.success).toBe(true);
    const catalog = await getCatalogItems();
    expect(catalog.find(item => item.name === "Barang Uji Admin")?.quantity_available).toBe(4);
  });
  it("installs idempotently without resetting inventory", async () => {
    await db.exec("RESET ROLE");
    await db.exec(fs.readFileSync("supabase/transition_setup.sql", "utf8"));
    await db.exec("SET ROLE service_role");
    expect(await stock()).toBe(5);
  });
  it("quotes hostile input as data and preserves tables", async () => {
    const name = "quote '; DROP TABLE profiles; -- {{0}}";
    const result = await createItem({ name, category: "Tools", quantity_total: 3, quantity_available: 3, is_available: true });
    expect(result.success).toBe(true);
    const row = await db.query<{ name: string }>("SELECT name FROM items WHERE name=$1", [name]);
    expect(row.rows[0].name).toBe(name);
    expect((await db.query("SELECT * FROM profiles")).rows).toHaveLength(2);
  });
  it("decrements stock only once on duplicate approval", async () => {
    const id = await loan();
    expect((await approveLoan({ loanId: id })).success).toBe(true);
    expect((await approveLoan({ loanId: id })).success).toBe(false);
    expect(await stock()).toBe(3);
  });
  it("does not approve more stock than available", async () => {
    const ids = [await loan(), await loan(), await loan()];
    expect((await approveLoan({ loanId: ids[0] })).success).toBe(true);
    expect((await approveLoan({ loanId: ids[1] })).success).toBe(true);
    expect((await approveLoan({ loanId: ids[2] })).success).toBe(false);
    expect(await stock()).toBe(1);
  });
  it("prevents a borrower from cancelling an approved loan and restoring stock", async () => {
    const id = await loan();
    await approveLoan({ loanId: id });
    // The cancellation action uses the borrower identity: approved loans require admin.
    expect((await cancelLoan({ loanId: id, admin_note: "Batalkan pinjaman" })).success).toBe(false);
    expect(await stock()).toBe(3);
  });
  it("completes handover and return without double-restoring stock", async () => {
    const id = await loan();
    await approveLoan({ loanId: id });
    const beforePhoto = "44444444-4444-4444-8444-444444444444";
    const afterPhoto = "55555555-5555-4555-8555-555555555555";
    await db.query("INSERT INTO images(id,owner_id,bucket,content_type,data) VALUES($1,$2,'return-images','image/jpeg',decode('ffd8ff','hex')),($3,$4,'return-images','image/jpeg',decode('ffd8ff','hex'))", [beforePhoto,adminId,afterPhoto,clientId]);
    expect((await handoverLoan({ loanId: id, admin_image_id: beforePhoto })).success).toBe(true);
    expect((await requestReturn({ loanId: id, return_image_id: afterPhoto })).success).toBe(true);
    expect((await markLoanReturned({ loanId: id, actual_return_date: new Date().toISOString() })).success).toBe(true);
    expect((await markLoanReturned({ loanId: id, actual_return_date: new Date().toISOString() })).success).toBe(false);
    expect(await stock()).toBe(5);
  });
  it("prevents browser roles from invoking privileged RPCs or changing profiles", async () => {
    await db.exec("RESET ROLE; SET ROLE anon");
    await expect(db.query("SELECT sims_query('unknown','[]'::jsonb)")).rejects.toThrow(/permission denied/);
    await expect(db.query("UPDATE profiles SET role='admin'")).rejects.toThrow(/permission denied/);
    await db.exec("RESET ROLE; SET ROLE authenticated");
    await expect(db.query("SELECT sims_issue_otp('x@example.com','login','hash',NULL)")).rejects.toThrow(/permission denied/);
    await expect(db.query("SELECT * FROM mobile_sessions")).rejects.toThrow(/permission denied/);
  });
  it("rejects query IDs outside the allowlist", async () => {
    await expect(db.query("SELECT sims_query('untrusted SQL','[]'::jsonb)")).rejects.toThrow("Unknown application query");
  });
  it("enforces resend cooldown and five sends per hour", async () => {
    const issue = () => db.query<{ ok: boolean }>("SELECT sims_issue_otp('client@example.com','login','hash',$1) AS ok", [clientId]);
    expect((await issue()).rows[0].ok).toBe(true);
    expect((await issue()).rows[0].ok).toBe(false);
    for (let i=0;i<4;i++) {
      await db.exec("UPDATE sims_private.otp_challenges SET sent_at=now()-interval '61 seconds'");
      expect((await issue()).rows[0].ok).toBe(true);
    }
    await db.exec("UPDATE sims_private.otp_challenges SET sent_at=now()-interval '61 seconds'");
    expect((await issue()).rows[0].ok).toBe(false);
  });
  it("locks a challenge after five wrong guesses", async () => {
    await db.query("SELECT sims_issue_otp('client@example.com','login','correct',$1)", [clientId]);
    for (let i=0;i<5;i++) await db.query("SELECT sims_check_otp('client@example.com','login','wrong',true)");
    const result = await db.query<{ id: string | null }>("SELECT sims_check_otp('client@example.com','login','correct',true) AS id");
    expect(result.rows[0].id).toBeNull();
  });
  it("consumes an accepted OTP exactly once", async () => {
    await db.query("SELECT sims_issue_otp('client@example.com','login','correct',$1)", [clientId]);
    const query = "SELECT sims_check_otp('client@example.com','login','correct',true) AS id";
    expect((await db.query<{ id: string }>(query)).rows[0].id).toBe(clientId);
    expect((await db.query<{ id: string | null }>(query)).rows[0].id).toBeNull();
  });
  it("allows password-reset verification and consumption after four wrong guesses",async()=>{
    await db.query("SELECT sims_issue_otp('client@example.com','forgot_password','correct',$1)",[clientId]);
    for(let i=0;i<4;i++)await db.query("SELECT sims_check_otp('client@example.com','forgot_password','wrong',false)");
    expect((await db.query<{id:string}>("SELECT sims_check_otp('client@example.com','forgot_password','correct',false) AS id")).rows[0].id).toBe(clientId);
    expect((await db.query<{id:string}>("SELECT sims_check_otp('client@example.com','forgot_password','correct',true) AS id")).rows[0].id).toBe(clientId);
  });
});
