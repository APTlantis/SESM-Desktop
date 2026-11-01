import {readFileSync,writeFileSync,existsSync} from 'node:fs';
import {relative,resolve} from 'node:path';
const record=JSON.parse(readFileSync('evidence/local/artifact-hashes.json','utf8'));
const installer=record.artifacts.find(a=>a.name.endsWith('.msix'));
if(!installer)throw new Error('No MSIX hash record.');
const path=relative(process.cwd(),installer.path).replaceAll('\\','/');
if(path.startsWith('../'))throw new Error('Artifact must be inside this project.');
let manifest=readFileSync('SESM-Desktop.manifest.toml','utf8');
const signingPath='evidence/local/signing.json';
const signing=existsSync(signingPath)?JSON.parse(readFileSync(signingPath,'utf8')):null;
if(signing && resolve(signing.artifact)!==resolve(installer.path))throw new Error('Signing evidence belongs to another installer.');
for(const [key,value] of [['path',`"${path}"`],['size_bytes',String(installer.bytes)],['sha256',`"${installer.sha256.toUpperCase()}"`],['signing',JSON.stringify(signing?.status??'unsigned')]]) {
 const pattern=new RegExp(`(\\[release\\.installer\\][\\s\\S]*?\\n${key} = )[^\\n]+`);
 if(!pattern.test(manifest))throw new Error(`Installer field missing: ${key}`);
 manifest=manifest.replace(pattern,`$1${value}`);
}
manifest=manifest.replace(/^signing_authority = .*$/m,`signing_authority = ${JSON.stringify(signing?.status??'unsigned-internal')}`);
writeFileSync('SESM-Desktop.manifest.toml',manifest);
let stages=readFileSync('docs/Release-Stage-Evidence.toml','utf8').replace(/^artifact_sha256 = .*$/m,`artifact_sha256 = "${installer.sha256.toUpperCase()}"`);
writeFileSync('docs/Release-Stage-Evidence.toml',stages);
writeFileSync('evidence/artifacts.json',JSON.stringify({...record,artifacts:record.artifacts.map(a=>({...a,path:relative(process.cwd(),a.path).replaceAll('\\','/')}))},null,2)+'\n');
if(signing)writeFileSync('evidence/signing.json',JSON.stringify({...signing,artifact:path},null,2)+'\n');
console.log(`Bound candidate manifest and stage evidence to ${installer.sha256}. Native acceptance remains pending.`);
