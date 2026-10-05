import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}

export function buildPreviewUrl(bucketId: string, filePath: string) {
  if (!filePath) return "";
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!supabaseUrl) return "";
  
  return `${supabaseUrl}/storage/v1/object/public/${bucketId}/${filePath}`;
}
