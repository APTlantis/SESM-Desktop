import React, { useEffect, useRef, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { getCurrentWindow } from '@tauri-apps/api/window';
import { call, isDesktop } from './api';
import { changeField, fields, readMetadata, roles, valueAt, type EditorDocument, type ExportReceipt, type Preferences, type Snapshot, type Template } from './model';
import './style.css';

const defaults: Preferences = { version: 1, preview_background: 'checker', editor_tab: 'fields' };
function App() {
  const [documents, setDocuments] = useState<EditorDocument[]>([]);
  const [selected, setSelected] = useState('');
  const [templates, setTemplates] = useState<Template[]>([]);
  const [template, setTemplate] = useState('');
  const [templateName, setTemplateName] = useState('');
  const [conflicts, setConflicts] = useState<string[]>([]);
  const [overwrite, setOverwrite] = useState<string[]>([]);
  const [prefs, setPrefs] = useState(defaults);
  const [busy, setBusy] = useState(false);
  const [exporting, setExporting] = useState(false);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [ack, setAck] = useState(false);
  const [receipt, setReceipt] = useState<ExportReceipt | null>(null);
  const receiptDialog = useRef<HTMLDialogElement>(null);
  const ref = useRef(documents); ref.current = documents;
  const exportingRef = useRef(false); exportingRef.current = exporting;
  const current = documents.find(d => d.id === selected);
  const pending = !!current && current.localDraft !== current.draft;
  let model = null; try { if (current) model = readMetadata(current.localDraft); } catch { /* raw draft retains invalid text */ }
  const warnings = current?.validation.findings.filter(f => f.severity === 'warning') ?? [];
  function upsert(s: Snapshot) {
    setDocuments(ds => {
      const old = ds.find(d => d.id === s.id);
      const next = { ...s, preview: s.preview ?? old?.preview ?? null, preview_error: s.preview_error ?? old?.preview_error ?? null, localDraft: s.draft, exportedRevision: old?.exportedRevision };
      return old ? ds.map(d => d.id === s.id ? next : d) : [...ds, next];
    });
  }
  async function task(action: () => Promise<void>) {
    setBusy(true); setError(''); setNotice('');
    try { await action(); } catch (e) { setError(String(e)); } finally { setBusy(false); }
  }
  useEffect(() => {
    if (!isDesktop()) return;
    Promise.all([call<Template[]>('list_templates'), call<Preferences>('preferences')]).then(([t,p]) => { setTemplates(t); setPrefs(p); }).catch(e => setError(String(e)));
    let off: (() => void) | undefined; let disposed = false;
    getCurrentWindow().onCloseRequested(async event => {
      if (exportingRef.current) { event.preventDefault(); setError('Cancel the export and wait for its receipt before closing.'); return; }
      if (ref.current.some(d => (d.dirty && d.exportedRevision !== d.revision) || d.localDraft !== d.draft)) {
        event.preventDefault();
        if (window.confirm('Close SESM Desktop and discard unexported edits? Source files are unchanged.')) await getCurrentWindow().destroy();
      }
    }).then(fn => { if (disposed) fn(); else off = fn; });
    const before = (e: BeforeUnloadEvent) => { if (ref.current.some(d => (d.dirty && d.exportedRevision !== d.revision) || d.localDraft !== d.draft)) e.preventDefault(); };
    window.addEventListener('beforeunload', before);
    return () => { disposed = true; off?.(); window.removeEventListener('beforeunload', before); };
  }, []);
  useEffect(() => { setAck(false); setConflicts([]); setOverwrite([]); }, [selected]);
  useEffect(() => { setAck(false); }, [current?.revision]);
  useEffect(() => { if (receipt && receiptDialog.current && !receiptDialog.current.open) receiptDialog.current.showModal(); }, [receipt]);
  async function preference(update: Partial<Preferences>) {
    const next = { ...prefs, ...update }; setPrefs(next);
    if (isDesktop()) await call('save_preferences', { preferences: next });
  }
  function draft(value: string) {
    if (!current) return;
    setAck(false); setConflicts([]); setOverwrite([]);
    setDocuments(ds => ds.map(d => d.id === current.id ? { ...d, localDraft: value, approved: false } : d));
  }
  function field(pointer: string, value: unknown) { if (current) { try { draft(changeField(current.localDraft, pointer, value)); } catch (e) { setError(String(e)); } } }
  async function flush(d: EditorDocument): Promise<Snapshot> {
    if (d.localDraft === d.draft) return d;
    const s = await call<Snapshot>('edit_metadata', { id: d.id, draft: d.localDraft }); upsert(s); return s;
  }
  const approved = documents.filter(d => d.approved && d.localDraft === d.draft).length;
  return <div className="app">
    <header className="topbar">
      <div className="brand"><span className="brand-mark" aria-hidden="true">S</span><div><h1>SESM Desktop <small>0.1</small></h1><p>Portable, self-describing SVG assets</p></div></div>
      <div className="toolbar"><span className="offline">● Local & offline</span><button disabled={busy} onClick={() => task(async () => {
        const result = await call<{ documents: Snapshot[]; errors: string[] }>('open_documents');
        result.documents.forEach(upsert); if (result.documents.length) setSelected(result.documents[0].id); if (result.errors.length) setError(result.errors.join('\n'));
      })}>＋ Open SVGs</button><button className="primary" disabled={busy || approved === 0} onClick={() => task(async () => {
        for (const d of documents) if (d.localDraft !== d.draft) await flush(d);
        setExporting(true); try { const r = await call<ExportReceipt | null>('export_documents'); setReceipt(r); if(r) {setNotice(`Export finished: ${r.files.filter(f => f.status === 'exported').length} copied.`);setDocuments(ds=>ds.map(d=>r.files.some(f=>f.status==='exported'&&(f as {document_id?:string}).document_id===d.id)?{...d,exportedRevision:d.revision}:d));} } finally { setExporting(false); }
      })}>Export {approved > 0 ? approved : ''} approved {approved === 1 ? 'copy' : 'copies'} →</button></div>
    </header>
    {!isDesktop() && <div className="notice">Interface preview · Run <code>npm run tauri dev</code> for local file workflows.</div>}
    {error && <div role="alert" className="error banner"><span>{error}</span><button onClick={() => setError('')} aria-label="Dismiss error">×</button></div>}
    {notice && <div role="status" className="notice">{notice}</div>}
    {exporting && <div className="notice" role="status">Exporting reviewed copies… <button onClick={() => call('cancel_export').catch(e => setError(String(e)))}>Cancel remaining files</button></div>}
    <main className="workspace">
      <aside className="queue" aria-label="File queue"><div className="section-heading"><h2>Files</h2><span>{documents.length}</span></div>
        <p className="muted hint">Review each SVG before export.</p>
        <nav aria-label="Open SVG files">{documents.map(d => <div className={`file ${d.id === selected ? 'selected' : ''}`} key={d.id}>
          <button className="file-select" onClick={() => setSelected(d.id)} disabled={busy}><strong>{d.name}</strong><span>{d.approved ? '✓ Approved' : d.validation.exportable ? '○ Needs review' : '⚠ Needs attention'}</span>{(d.dirty || d.localDraft !== d.draft) && <small>Edited copy</small>}</button>
          <button className="remove" aria-label={`Remove ${d.name}`} disabled={busy} onClick={() => task(async () => {
            if (((d.dirty && d.exportedRevision !== d.revision) || d.localDraft !== d.draft) && !window.confirm(`Discard unexported edits to ${d.name}?`)) return;
            await call('remove_document',{ id:d.id });setDocuments(ds=>ds.filter(x=>x.id!==d.id));if(selected===d.id)setSelected(documents.find(x=>x.id!==d.id)?.id??'');
          })}>×</button>
        </div>)}</nav>
        {!documents.length && <div className="queue-empty">No SVGs open.<br/>Select one file or a batch.</div>}
        <div className="queue-footer"><strong>Aptlantis-Factor</strong><p>SESM 0.3.0 · 0.2.0 compatible</p><p>Source files stay untouched.</p></div>
      </aside>
      <section className="preview-column" aria-label="SVG preview and review">
        <div className="section-heading"><h2>{current?.name ?? 'Your SVG, with its story attached'}</h2>{current && <label className="inline">Canvas <select aria-label="Preview background" value={prefs.preview_background} onChange={e=>preference({preview_background:e.target.value}).catch(e=>setError(String(e)))}><option value="checker">Checker</option><option value="dark">Dark</option><option value="light">Light</option></select></label>}</div>
        <div className={`canvas ${prefs.preview_background}`}>
          {current?.preview ? <img alt={`Raster preview of ${current.name}`} src={current.preview}/> : <div className="empty-state"><span className="svg-symbol" aria-hidden="true">&lt;svg&gt;</span><h3>{current ? 'Preview unavailable' : 'Make SVGs easier to understand'}</h3><p>{current?.preview_error ?? (current ? 'Inspect the validation findings below.' : 'Inspect existing metadata, add context, and export reviewed copies. Everything stays on your device.')}</p></div>}
        </div>
        {current ? <div className="review">
          <div className="section-heading"><h2>Validation</h2><span className="badge">{pending ? 'Draft changed' : current.validation.profile}</span></div>
          <p className="muted hint">XML · SESM schema · safe profile{pending ? ' — validate to refresh results' : ''}</p>
          {!current.validation.findings.length && <p className="pass">✓ No findings in the validated metadata revision.</p>}
          <ul className="findings">{current.validation.findings.map((f,i)=><li key={i} className={f.severity}><strong>{f.severity==='error'?'⚠':'△'} {f.category} · {f.code}</strong><p>{f.message}</p><code>{f.path}</code></li>)}</ul>
          <details open><summary>Proposed changes <span>{current.changes.length}</span></summary>{pending && <p className="muted">Validate your draft to refresh this diff.</p>}{current.changes.map(c=><div className="change" key={c.path}><code>{c.path || '/'}</code><del>{c.before ?? '(absent)'}</del><ins>{c.after ?? '(removed)'}</ins></div>)}</details>
          <details><summary>Observed SVG properties <span>{current.observations.length}</span></summary><p className="hint muted">Observed values are suggestions, not inferred meaning.</p>{current.observations.map((o,i)=><div className="observation" key={i}><strong>{o.property}</strong><code>{o.value}</code><small>{o.source}</small>{['title','desc'].includes(o.property) && <button disabled={busy || !model} onClick={()=>field(o.property==='title'?'/asset/title':'/asset/description',o.value)}>Use as {o.property==='title'?'title':'description'}</button>}</div>)}</details>
          <details><summary>Source & validation identity</summary><p className="break">{current.source}</p><p className="hint">Source SHA-256</p><code className="break">{current.source_sha256}</code><p className="hint">Schema SHA-256</p><code className="break">{current.validation.schema_sha256}</code></details>
        </div> : <div className="intro-grid"><article><h3>01 · Inspect</h3><p>See the artwork and its embedded context.</p></article><article><h3>02 · Describe</h3><p>Edit fields or JSON. Reuse reviewed templates.</p></article><article><h3>03 · Export</h3><p>Approve each file and save new copies.</p></article></div>}
      </section>
      <section className="editor" aria-label="Metadata editor">
        <div className="section-heading"><h2>Metadata</h2><span className="muted">{current?.validation.metadata_version ?? 'SESM'}</span></div>
        <div className="tabs" role="tablist" aria-label="Metadata views">{['fields','json'].map(tab=><button key={tab} role="tab" aria-selected={prefs.editor_tab===tab} onClick={()=>preference({editor_tab:tab}).catch(e=>setError(String(e)))}>{tab==='fields'?'Structured fields':'Raw JSON'}</button>)}</div>
        {current ? <>
          <div className="editor-scroll" role="tabpanel" aria-label={prefs.editor_tab==='fields'?'Structured fields':'Raw JSON'}>
            {prefs.editor_tab==='json' ? <><label htmlFor="json-draft" className="hint muted">Unknown fields and numeric precision are preserved.</label><textarea id="json-draft" className="json" spellCheck={false} disabled={busy} value={current.localDraft} onChange={e=>draft(e.target.value)}/></> : model ? fields.map(group=><details key={group.title} open={group.title==='Identity'}><summary>{group.title}</summary>{group.title==='Integrity references' && <p className="hint muted">Claims are preserved without verification. No whole-file hash is embedded.</p>}{group.entries.map(([pointer,label])=>{
              const value=valueAt(model!,pointer); const bool=['/provenance/generated','/provenance/reproducible'].includes(pointer);
              const values=pointer==='/asset/role'?roles:pointer==='/theme/mode'?['dark','light']:bool?['true','false']:null;
              return <label className="field" key={pointer}><span>{label}</span>{values ? <select disabled={busy} value={value===undefined?'':String(value)} onChange={e=>field(pointer,e.target.value===''?undefined:bool?e.target.value==='true':e.target.value)}><option value="">Not set</option>{values.map(v=><option key={v}>{v}</option>)}</select> : pointer==='/asset/description' ? <textarea disabled={busy} rows={3} value={typeof value==='string'?value:''} onChange={e=>field(pointer,e.target.value)}/> : <input disabled={busy} value={pointer==='/asset/tags'&&Array.isArray(value)?value.join(', '):typeof value==='string'?value:''} onChange={e=>field(pointer,pointer==='/asset/tags'?e.target.value.split(',').map(x=>x.trim()).filter(Boolean):e.target.value)}/>}<small>{pointer}</small></label>;
            })}</details>) : <p className="error">The raw JSON draft is invalid. Repair it in Raw JSON; the last valid metadata model is retained.</p>}
            <details className="templates" open><summary>Reusable templates</summary><p className="hint muted">Fill missing values. Unique file IDs, paths, links and integrity claims are excluded when saving.</p>
              <label className="field"><span>Saved template</span><select disabled={busy} value={template} onChange={e=>{setTemplate(e.target.value);setConflicts([]);setOverwrite([]);}}><option value="">Choose a template</option>{templates.map(t=><option key={t.name}>{t.name}</option>)}</select></label>
              <div className="button-row"><button disabled={busy||!template} onClick={()=>task(async()=>{
                await flush(current);const r=await call<{document:Snapshot;conflicts:string[]}>('apply_template',{id:current.id,name:template,overwrite});upsert(r.document);setConflicts(r.conflicts);setOverwrite([]);setNotice('Template applied. Existing values were preserved unless explicitly selected.');
              })}>{overwrite.length?'Apply selected replacements':'Fill missing fields'}</button><button disabled={busy||!template} onClick={()=>task(async()=>{if(!window.confirm(`Delete template “${template}”?`))return;await call('delete_template',{name:template});setTemplates(await call('list_templates'));setTemplate('');})}>Delete</button></div>
              {conflicts.length>0 && <fieldset><legend>Existing values kept — select any to replace</legend>{conflicts.map(p=><label className="checkbox" key={p}><input type="checkbox" checked={overwrite.includes(p)} onChange={e=>setOverwrite(xs=>e.target.checked?[...xs,p]:xs.filter(x=>x!==p))}/><code>{p}</code></label>)}</fieldset>}
              <label className="field"><span>Save current metadata as a template</span><input placeholder="Template name" disabled={busy} value={templateName} onChange={e=>setTemplateName(e.target.value)}/></label><button disabled={busy||!templateName.trim()} onClick={()=>task(async()=>{await flush(current);await call('save_template',{id:current.id,name:templateName});setTemplates(await call('list_templates'));setTemplateName('');setNotice('Template saved locally.');})}>Save template</button>
            </details>
          </div>
          <div className="approval"><button disabled={busy||!pending} onClick={()=>task(async()=>{await flush(current);setNotice('Draft validated. Review findings and proposed changes.');})}>Validate draft</button>
            {warnings.length>0 && <label className="checkbox"><input type="checkbox" disabled={busy||pending} checked={ack} onChange={e=>setAck(e.target.checked)}/>I reviewed this file’s warnings.</label>}
            <button className="primary" disabled={busy||pending||!current.validation.exportable||current.approved||(warnings.length>0&&!ack)} onClick={()=>task(async()=>{const s=await call<Snapshot>('approve_document',{id:current.id,revision:current.revision,acknowledge:ack});upsert(s);setNotice('File approved for copy export.');})}>{current.approved?'✓ Approved for export':'Approve this file'}</button><p className="hint muted">Changing metadata requires a fresh review.</p>
          </div>
        </> : <div className="editor-empty"><h3>Context travels with the SVG.</h3><p>Open an SVG to inspect or author its SESM metadata.</p><div className="code-sample"><code>{'{\n  "sesm_version": "0.3.0"\n}'}</code></div><p className="hint muted">No account. No upload. No dependency on the Aptlantis pipeline.</p></div>}
      </section>
    </main>
    {receipt && <dialog ref={receiptDialog} onKeyDown={e=>{if(e.key==='Tab'){e.preventDefault();receiptDialog.current?.querySelector('button')?.focus();}}} onCancel={()=>setReceipt(null)} className="receipt" aria-label="Export results"><div className="section-heading"><h2>Export results</h2><button autoFocus onClick={()=>setReceipt(null)}>Close</button></div><p className="break">{receipt.destination}</p>{receipt.cancelled&&<p>Export cancelled. Completed copies remain available.</p>}<ul>{receipt.files.map((f,i)=><li key={i}><strong>{f.status} · {f.filename}</strong>{f.message&&<p>{f.message}</p>}{f.output_sha256&&<code className="break">{f.output_sha256}</code>}</li>)}</ul><p className="muted hint">The destination contains a JSON receipt with validation results and hashes.</p></dialog>}
    <footer className="statusbar"><span>{documents.length} open · {approved} approved</span><span>Copy-only export · UTF-8 SVG · Offline validation</span></footer>
  </div>;
}
createRoot(document.getElementById('root')!).render(<App/>);
