import {NextResponse} from 'next/server';
import {readFile,stat} from 'node:fs/promises';
import path from 'node:path';
import {parseAndroidRelease} from '@/lib/backend/app-releases';
export const runtime='nodejs';
export const dynamic='force-dynamic';

export async function GET(request:Request) {
  const platform=new URL(request.url).searchParams.get('platform') ?? 'android';
  if(!['android','web'].includes(platform))return NextResponse.json({error:'Platform tidak didukung.'},{status:400});
  try {
    if(platform==='web'){
      const version=JSON.parse(await readFile(path.join(process.cwd(),'public/app/version.json'),'utf8'));
      const number=Number(version.build_number);
      if(!Number.isSafeInteger(number)||number<1||!/^\d+\.\d+\.\d+$/.test(version.version))throw new Error('Invalid version');
      return NextResponse.json({platform,available:true,version:version.version,build_number:number,notes:'Pembaruan aplikasi tersedia.'},{headers:{'Cache-Control':'no-store'}});
    }
    const release=parseAndroidRelease(JSON.parse(await readFile(path.join(process.cwd(),'public/releases/android.json'),'utf8')));
    const artifact=await stat(path.join(process.cwd(),'public',release.apk_path.slice(1)));
    if(!artifact.isFile()||artifact.size!==release.size_bytes)throw new Error('Missing artifact');
    return NextResponse.json({platform,available:true,...release},{headers:{'Cache-Control':'no-store'}});
  } catch {
    // No fake package or URL is advertised before a signed release is published.
    return NextResponse.json({platform,available:false},{headers:{'Cache-Control':'no-store'}});
  }
}
