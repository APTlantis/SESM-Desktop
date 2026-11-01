import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
const receipt = JSON.parse(readFileSync(new URL('../resources/source-receipts.json', import.meta.url)));
for (const record of receipt.records) {
  const bytes = readFileSync(new URL(`../${record.destination}`, import.meta.url));
  if (createHash('sha256').update(bytes).digest('hex') !== record.sha256) throw new Error(`Source receipt mismatch: ${record.destination}`);
}
console.log(`Verified ${receipt.records.length} vendored runtime/fixture/theme source hashes; no original source access needed.`);
