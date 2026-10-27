import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';

// Only genuine, signed release APKs are eligible for the app update feed.
const input=process.argv[2],aapt=process.argv[3],signer=process.argv[4];
if(!input||!aapt||!signer)throw new Error('Pass APK, Android build-tools aapt executable, and lib/apksigner.jar.');
for(const file of [input,aapt,signer])if(!fs.existsSync(file))throw new Error('A required release tool or APK is missing.');
const run=(exe,args)=>{
 const result=spawnSync(exe,args,{encoding:'utf8',windowsHide:true,shell:false});
 if(result.status!==0)throw new Error('Android release verification failed.');return result.stdout;
};
const metadata=run(aapt,['dump','badging',path.resolve(input)]);
const signed=run('java',['-jar',path.resolve(signer),'verify','--verbose','--print-certs',path.resolve(input)]);
if(/application-debuggable/.test(metadata)||/CN=Android Debug|CN=AndroidDebug/i.test(signed))throw new Error('Debug APKs cannot be published as updates.');
const match=metadata.match(/package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'/);
if(!match||match[1]!=='com.example.app_inventory')throw new Error('Unexpected APK identity.');
const pubspec=fs.readFileSync('app_inventory/pubspec.yaml','utf8').match(/^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$/m);
if(!pubspec||match[2]!==pubspec[2]||match[3]!==pubspec[1])throw new Error('APK version differs from the source release.');
const bytes=fs.readFileSync(input);if(bytes.length>150*1024*1024)throw new Error('APK exceeds the update size limit.');
const folder=path.resolve('public/releases');fs.mkdirSync(folder,{recursive:true});
const name=`sims-${match[3]}-${match[2]}.apk`;
fs.writeFileSync(path.join(folder,name),bytes);
fs.writeFileSync(path.join(folder,'android.json'),JSON.stringify({version:match[3],build_number:Number(match[2]),apk_path:'/releases/'+name,sha256:createHash('sha256').update(bytes).digest('hex'),size_bytes:bytes.length,notes:'Pembaruan SIMS '+match[3]+'.'},null,2));
console.log('Signed Android release prepared. The APK and private signing material are excluded from Git.');
