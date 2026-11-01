import { createHash } from 'node:crypto';
import { readFileSync, mkdirSync, writeFileSync, statSync } from 'node:fs';
import { resolve, basename } from 'node:path';
const artifacts=process.argv.slice(2);
if(!artifacts.length)throw new Error('Pass one or more built artifact paths.');
const record={version:1,application_version:'0.1.0',recorded_at:new Date().toISOString(),artifacts:artifacts.map(p=>({path:resolve(p),name:basename(p),bytes:statSync(p).size,sha256:createHash('sha256').update(readFileSync(p)).digest('hex')}))};
mkdirSync('evidence/local',{recursive:true});writeFileSync('evidence/local/artifact-hashes.json',JSON.stringify(record,null,2)+'\n');
console.log(JSON.stringify(record,null,2));
