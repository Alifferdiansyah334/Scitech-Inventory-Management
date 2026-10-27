import fs from "node:fs";
import path from "node:path";
import nextEnv from "@next/env";
nextEnv.loadEnvConfig(process.cwd());
const dir=path.resolve('public/app');
if(!fs.existsSync(path.join(dir,'index.html')))throw new Error('Flutter release is not bundled.');
const privateNames=['SUPABASE_SERVICE_ROLE_KEY','BREVO_API_KEY','APP_SESSION_SECRET'];
let checked=0;
function walk(folder){
  for(const entry of fs.readdirSync(folder,{withFileTypes:true})){
    const file=path.join(folder,entry.name);
    if(entry.isDirectory()){walk(file);continue;}
    const data=fs.readFileSync(file);checked++;
    for(const key of privateNames){const value=process.env[key];if(value&&data.includes(Buffer.from(value)))throw new Error(`Private configuration ${key} found in client output.`);}
    if(/\.js$/.test(file)&&(data.includes(Buffer.from('Mode Admin (Demo)'))||data.includes(Buffer.from('admin123'))))throw new Error('Legacy demo access found in client output.');
  }
}
walk(dir);
console.log(`Checked ${checked} Flutter output files: no server secrets or demo access strings.`);
if(process.argv.includes('--services')){
  const {spawnSync}=await import('node:child_process');
  const result=spawnSync(process.execPath,['scripts/check-services.mjs'],{stdio:'inherit'});
  if(result.status!==0)throw new Error('Production release blocked: complete the Supabase setup first.');
}
