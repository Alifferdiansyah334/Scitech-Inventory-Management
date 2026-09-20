"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { loginSchema, registerSchema } from "@/lib/validators/auth";
import { activeUserSchema, roleUpdateSchema } from "@/lib/validators/users";
import type { ActionResult, Profile, SessionCookie } from "@/types";

export async function registerUser(input: unknown): Promise<ActionResult<Profile>> {
  try {
    const values = registerSchema.parse(input);

    const supabase = await createClient();
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: values.email,
      password: values.password,
    });

    if (authError || !authData.user) {
      return { success: false, error: authError?.message || "Registrasi gagal di level autentikasi." };
    }

    const adminClient = await createAdminClient();
    const profilePayload = {
      user_id: authData.user.id,
      full_name: values.full_name,
      email: values.email,
      role: "client" as const,
      department: values.department || "",
      avatar_url: "",
      created_at: new Date().toISOString()
    };
    
    // Supabase will automatically insert if we use the admin client
    // Or we could have trigger on auth.users in Supabase, but let's do it manually for explicit control.
    const { data: profileData, error: profileError } = await adminClient
      .from("profiles")
      .insert(profilePayload)
      .select()
      .single();

    if (profileError) {
      // Rollback might be needed in a real app, but for now we return error
      return { success: false, error: profileError.message };
    }

    return { success: true, data: profileData as Profile };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Registrasi gagal." };
  }
}

export async function loginUser(input: unknown): Promise<ActionResult<Profile>> {
  try {
    const values = loginSchema.parse(input);

    const supabase = await createClient();
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: values.email,
      password: values.password,
    });

    if (authError || !authData.user) {
      return { success: false, error: authError?.message || "Login gagal." };
    }

    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("*")
      .eq("user_id", authData.user.id)
      .single();

    if (profileError || !profile) {
      return { success: false, error: "Profil pengguna tidak ditemukan." };
    }

    return { success: true, data: profile as Profile };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Login gagal." };
  }
}

export async function logoutUser() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}

export async function updateUserRole(input: unknown): Promise<ActionResult> {
  try {
    const values = roleUpdateSchema.parse(input);

    const adminClient = await createAdminClient();
    
    const { error } = await adminClient
      .from("profiles")
      .update({ role: values.role })
      .eq("user_id", values.userId);

    if (error) {
      return { success: false, error: error.message };
    }

    return { success: true, data: values };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Gagal mengubah role." };
  }
}

export async function setUserActive(input: unknown): Promise<ActionResult> {
  try {
    const values = activeUserSchema.parse(input);

    const adminClient = await createAdminClient();
    const { error } = await adminClient
      .from("profiles")
      .update({ is_active: values.isActive })
      .eq("user_id", values.userId);
      
    if (error) {
      return { success: false, error: error.message };
    }
    
    return { success: true, data: values };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Gagal mengubah status pengguna." };
  }
}

export async function updateOwnProfile(input: Partial<Profile>): Promise<ActionResult<Profile>> {
  try {
    const supabase = await createClient();
    const { data: authData } = await supabase.auth.getUser();
    
    if (!authData.user) {
      return { success: false, error: "Tidak dapat mengidentifikasi pengguna." };
    }
    
    const { data, error } = await supabase
      .from("profiles")
      .update(input)
      .eq("user_id", authData.user.id)
      .select()
      .single();
      
    if (error) {
      return { success: false, error: error.message };
    }

    return { success: true, data: data as Profile };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Gagal memperbarui profil." };
  }
}
