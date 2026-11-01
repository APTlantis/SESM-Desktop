import { parse, stringify } from 'lossless-json';

export type Metadata = Record<string, unknown>;
export function readMetadata(raw: string): Metadata {
  const value = parse(raw);
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('SESM must be a JSON object.');
  return value as Metadata;
}
export function writeMetadata(value: Metadata): string { return stringify(value, null, 2)!; }
export function valueAt(value: Metadata, pointer: string): unknown {
  return pointer.split('/').filter(Boolean).reduce<unknown>((v, key) => v && typeof v === 'object' ? (v as Metadata)[key] : undefined, value);
}
export function changeField(raw: string, pointer: string, value: unknown): string {
  const model = readMetadata(raw);
  const parts = pointer.split('/').filter(Boolean); let cursor = model;
  for (const part of parts.slice(0, -1)) {
    if (cursor[part] === undefined) cursor[part] = {};
    if (!cursor[part] || typeof cursor[part] !== 'object' || Array.isArray(cursor[part])) throw new Error(`Edit ${pointer} in JSON: its parent is not an object.`);
    cursor = cursor[part] as Metadata;
  }
  if (value === undefined) delete cursor[parts.at(-1)!]; else cursor[parts.at(-1)!] = value;
  return writeMetadata(model);
}
export interface Finding { category: string; severity: string; code: string; message: string; path: string }
export interface Validation { profile: string; metadata_version: string | null; schema: string; schema_sha256: string; findings: Finding[]; exportable: boolean }
export interface Snapshot {
  id: string; name: string; source: string; source_sha256: string; draft: string; metadata_json: string;
  dirty: boolean; approved: boolean; revision: number; warnings_acknowledged: boolean;
  validation: Validation; observations: { property: string; value: string; source: string }[];
  changes: { path: string; before: string | null; after: string | null }[];
  preview: string | null; preview_error: string | null;
}
export interface EditorDocument extends Snapshot { localDraft: string; exportedRevision?: number }
export interface Template { version: number; name: string; patch_json: string }
export interface Preferences { version: number; preview_background: string; editor_tab: string }
export interface ExportReceipt { destination: string; cancelled: boolean; files: { filename: string; status: string; message: string | null; output_sha256: string | null }[] }
export const fields = [
  { title: 'Identity', entries: [['/asset/id', 'Asset ID'], ['/asset/role', 'Role'], ['/asset/title', 'Title'], ['/asset/description', 'Description'], ['/asset/ecosystem', 'Ecosystem'], ['/asset/tags', 'Tags']] },
  { title: 'Provenance', entries: [['/provenance/generated', 'Generated'], ['/provenance/generator/name', 'Generator'], ['/provenance/generator/version', 'Generator version'], ['/provenance/generator/language', 'Generator language'], ['/provenance/generated_at', 'Generated at (ISO 8601)'], ['/provenance/reproducible', 'Reproducible'], ['/provenance/build_id', 'Build ID'], ['/provenance/git_commit', 'Git commit'], ['/artifact/kind', 'Artifact kind'], ['/artifact/source_path', 'Source path']] },
  { title: 'Theme', entries: [['/theme/id', 'Theme ID'], ['/theme/name', 'Theme name'], ['/theme/version', 'Theme version'], ['/theme/mode', 'Mode'], ['/theme/palette_contract', 'Palette contract'], ['/theme/accent/hex', 'Accent hex']] },
  { title: 'Links', entries: ['canonical_html', 'jsonld', 'manifest', 'docs', 'download', 'source_repo', 'homepage', 'license'].map(k => [`/links/${k}`, k.replaceAll('_', ' ')]) },
  { title: 'Integrity references', entries: [['/integrity/manifest', 'Hash manifest'], ['/integrity/signed_manifest', 'Signed manifest'], ['/integrity/verification_notes', 'Verification notes']] },
];
export const roles = ['logo','icon','theme-board','dataset-card','dataset-header','pipeline-panel','stats-panel','navigation-card','graph-node','graph-panel','status-badge','download-card','schema-card','archive-summary','landing-hero','page-header','decorative','unknown'];
