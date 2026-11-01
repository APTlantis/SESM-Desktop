import { describe, it, expect } from 'vitest';
import { changeField, readMetadata, writeMetadata } from './model';
describe('Lossless form and JSON editing', () => {
  it('preserves unknown nested fields and arbitrary precision', () => {
    const raw = '{"sesm_version":"0.3.0","extra":{"large":9007199254740993123456789,"precise":0.12345678901234567890123456789},"asset":{"id":"one","role":"unknown"}}';
    const result = changeField(raw, '/asset/title', 'A title');
    expect(result).toContain('9007199254740993123456789');
    expect(result).toContain('0.12345678901234567890123456789');
    expect(readMetadata(result).asset).toMatchObject({ id: 'one', role: 'unknown', title: 'A title' });
  });
  it('rejects invalid or non-object drafts without silently replacing them', () => {
    expect(() => readMetadata('{')).toThrow(); expect(() => readMetadata('[]')).toThrow(); expect(() => readMetadata('null')).toThrow();
  });
  it('does not coerce malformed parent values during structured editing', () => {
    expect(() => changeField('{"asset":"keep this"}', '/asset/title', 'x')).toThrow();
  });
  it('retains arrays and supports explicit field removal', () => {
    const raw = changeField('{"extra":{"array":[1,"two",true]},"asset":{"id":"x"}}', '/asset/id', undefined);
    expect(writeMetadata(readMetadata(raw))).toContain('"array"'); expect(raw).not.toContain('"id"');
  });
});
