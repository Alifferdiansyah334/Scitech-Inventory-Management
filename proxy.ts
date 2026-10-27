import type { NextRequest } from 'next/server';
import { apiCors } from '@/lib/http/cors';
export default function proxy(request: NextRequest) { return apiCors(request); }
export const config = { matcher: ['/api/:path*'] };
