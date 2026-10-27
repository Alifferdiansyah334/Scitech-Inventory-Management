// Legacy Neon proxy retired. Authentication now uses Supabase server clients.
export async function GET() { return Response.json({ error: "Endpoint tidak tersedia." }, { status: 404 }); }
export const POST = GET;
