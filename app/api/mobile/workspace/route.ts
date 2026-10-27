import {NextResponse} from 'next/server';
import {getBorrowerWorkspace} from '@/lib/backend/queries';
import {apiError} from '@/lib/backend/http';
export async function GET() {
  try { return NextResponse.json(await getBorrowerWorkspace()); }
  catch(error) { return apiError(error); }
}
