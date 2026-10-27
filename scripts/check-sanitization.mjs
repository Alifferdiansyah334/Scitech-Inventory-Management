import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {parseEnv} from 'node:util';

// Output contains file paths and configuration names, never matching values.
const git=(...args)=>execFileSync('git',args,{encoding:'utf8',maxBuffer:64*1024*1024,windowsHide:true});
const secrets=[];
const environmentDirectory=process.env.SECRET_SCAN_ENV_DIR||'.';
for(const file of fs.readdirSync(environmentDirectory).filter(name=>name.startsWith('.env.')&&name!=='.env.example')){
  const values=parseEnv(fs.readFileSync(path.join(environmentDirectory,file),'utf8'));
  for(const [name,value]of Object.entries(values)){
    if(/KEY|SECRET|PASSWORD|TOKEN|DATABASE_URL/.test(name)&&value.length>=16)secrets.push({name,value:Buffer.from(value)});
  }
}
const files=[...new Set(git('ls-files','--cached','--others','--exclude-standard','-z').split('\0').filter(Boolean))];
const issues=[];
const forbidden=file=>/(^|\/)(changelog[^/]*|[^/]*audit[^/]*\.(md|json)|\.env(?:\..*)?|[^/]*\.backup)$/i.test(file)&&file!=='.env.example';
for(const file of files){
  if(forbidden(file))issues.push({file,reason:'private report or environment included in Git candidate files'});
  if(!fs.existsSync(file)||!fs.statSync(file).isFile())continue;
  const bytes=fs.readFileSync(file);
  for(const secret of secrets)if(bytes.includes(secret.value))issues.push({file,reason:`configuration value: ${secret.name}`});
}
const history=[];
for(const row of git('rev-list','--objects','--all').split('\n')){
  const match=row.match(/^([a-f0-9]+) (.+)$/);if(!match)continue;
  const [,id,file]=match;
  if(!/\.(?:[cm]?[jt]sx?|json|md|ya?ml|toml|sql|txt|env|backup)$|(^|\/)\.env/.test(file))continue;
  const bytes=execFileSync('git',['cat-file','-p',id],{maxBuffer:16*1024*1024,windowsHide:true});
  for(const secret of secrets)if(bytes.includes(secret.value))history.push({file,reason:`configuration value: ${secret.name}`});
}
const ignored=['changelog.md','docs/INTEGRATION_AUDIT_2026-10-26.md','output/dependency-audit.json','.env.local','.env.neon.backup'];
for(const file of ignored){try{git('check-ignore','--quiet',file);}catch{issues.push({file,reason:'not ignored'});}}
const result={checkedFiles:files.length,knownSecretValues:secrets.length,issues,history,checkedAt:new Date().toISOString()};
fs.mkdirSync('output',{recursive:true});fs.writeFileSync('output/sanitization-audit.json',JSON.stringify(result,null,2));
console.log(JSON.stringify(result,null,2));
if(issues.length||history.length)process.exitCode=1;
