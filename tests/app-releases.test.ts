// @vitest-environment node
import {describe,it,expect,vi,afterEach} from 'vitest';
import {parseAndroidRelease,maxApkBytes} from '@/lib/backend/app-releases';
const io=vi.hoisted(()=>({readFile:vi.fn(),stat:vi.fn()}));
vi.mock('node:fs/promises',()=>({readFile:io.readFile,stat:io.stat}));
import {GET} from '@/app/api/mobile/releases/route';
const release={version:'1.0.1',build_number:4,apk_path:'/releases/sims-1.0.1-4.apk',sha256:'a'.repeat(64),size_bytes:1024,notes:'Perbaikan aplikasi.'};
afterEach(()=>vi.resetAllMocks());
describe('Signed release feed boundary',()=>{
  it('accepts only bounded same-origin APK metadata',()=>expect(parseAndroidRelease(release)).toEqual(release));
  it.each([{apk_path:'https://attacker.example/update.apk'},{apk_path:'/releases/../../private.apk'},{apk_path:'/releases/%2e%2e/private.apk'},{apk_path:'/releases/file.apk?token=secret'},{sha256:'invalid'},{size_bytes:maxApkBytes+1},{size_bytes:0},{build_number:-1},{version:'<script>'}])('rejects unsafe release metadata %j',patch=>expect(()=>parseAndroidRelease({...release,...patch})).toThrow());
  it('never advertises a package before a real artifact is published',async()=>{
    io.readFile.mockRejectedValue(new Error('private filesystem detail'));
    const result=await GET(new Request('https://sims.example/api/mobile/releases/?platform=android'));
    expect(await result.json()).toEqual({platform:'android',available:false});expect(result.headers.get('Cache-Control')).toBe('no-store');
  });
  it('rejects an artifact with a size different from the signed release manifest',async()=>{
    io.readFile.mockResolvedValue(JSON.stringify(release));io.stat.mockResolvedValue({isFile:()=>true,size:11});
    expect(await (await GET(new Request('https://sims.example/api/mobile/releases/'))).json()).toEqual({platform:'android',available:false});
  });
  it('publishes only verified release fields without local paths or secrets',async()=>{
    io.readFile.mockResolvedValue(JSON.stringify({...release,privateKey:'do-not-publish'}));io.stat.mockResolvedValue({isFile:()=>true,size:1024});
    const response=await GET(new Request('https://sims.example/api/mobile/releases/'));
    expect(await response.json()).toEqual({platform:'android',available:true,...release});
  });
});
