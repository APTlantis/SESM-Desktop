import {readFileSync,writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
const palette=readFileSync('src/theme/palette.css','utf8');
const colors=[...palette.matchAll(/--apt-color-(\d+):\s*(#[0-9A-F]{6})/g)];
if(colors.length!==32)throw new Error('Expected the canonical 32-color Factor palette.');
const board=`<svg xmlns="http://www.w3.org/2000/svg" width="640" height="320" viewBox="0 0 640 320"><title>Aptlantis-Factor palette fixture</title><metadata id="sesm"><![CDATA[{"sesm_version":"0.3.0","asset":{"id":"factor-palette-fixture","role":"theme-board"},"theme":{"id":"Aptlantis-Factor"}}]]></metadata>${colors.map(([,n,c],i)=>`<rect x="${i%8*80}" y="${Math.floor(i/8)*80}" width="80" height="80" fill="${c}"/>`).join('')}</svg>\n`;
const raster=`<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><title>Embedded raster fixture</title><image width="32" height="32" href="data:image/png;base64,${readFileSync('src-tauri/icons/32x32.png').toString('base64')}"/></svg>\n`;
const receipt=JSON.parse(readFileSync('resources/source-receipts.json','utf8'));
for(const [destination,bytes,source,purpose] of [
  ['tests/fixtures/factor-palette-board.svg',board,'src/theme/palette.css','Generated test fixture using the exact 32 canonical Factor colors; not a historical pipeline output'],
  ['tests/fixtures/embedded-raster.svg',raster,'src-tauri/icons/32x32.png','Synthetic embedded PNG fixture using the app icon generated from its own SVG mark'],
]){
 writeFileSync(destination,bytes);receipt.records=receipt.records.filter(r=>r.destination!==destination);
 receipt.records.push({source,destination,purpose,sha256:createHash('sha256').update(bytes).digest('hex')});
}
writeFileSync('resources/source-receipts.json',JSON.stringify(receipt,null,2)+'\n');
