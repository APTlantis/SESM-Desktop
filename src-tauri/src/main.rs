#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
use serde::{Deserialize, Serialize};
use sesm_engine::{Document, ExportReceipt, Snapshot, Template};
use std::{
    collections::BTreeMap,
    fs,
    path::{Path, PathBuf},
    sync::{
        atomic::{AtomicBool, AtomicU64, Ordering},
        Mutex,
    },
};
use tauri::{Emitter, Manager, State};
use tauri_plugin_dialog::DialogExt;

#[derive(Default)]
struct Workspace {
    documents: Mutex<BTreeMap<String, Document>>,
    counter: AtomicU64,
    exporting: AtomicBool,
    cancel: AtomicBool,
}
#[derive(Serialize)]
struct OpenResult {
    documents: Vec<Snapshot>,
    errors: Vec<String>,
}
#[derive(Serialize)]
struct ApplyResult {
    document: Snapshot,
    conflicts: Vec<String>,
}
#[derive(Clone, Serialize, Deserialize)]
struct Preferences {
    version: u32,
    preview_background: String,
    editor_tab: String,
}
impl Default for Preferences {
    fn default() -> Self {
        Self {
            version: 1,
            preview_background: "checker".into(),
            editor_tab: "fields".into(),
        }
    }
}
fn app_data(app: &tauri::AppHandle) -> Result<PathBuf, String> {
    app.path().app_data_dir().map_err(|e| e.to_string())
}
fn template_dir(app: &tauri::AppHandle) -> Result<PathBuf, String> {
    Ok(app_data(app)?.join("templates"))
}
fn store(path: &Path, bytes: &[u8]) -> Result<(), String> {
    fs::create_dir_all(path.parent().ok_or("Invalid storage path")?).map_err(|e| e.to_string())?;
    let temp = path.with_extension("partial");
    {
        use std::io::Write;
        let mut f = fs::File::create(&temp).map_err(|e| e.to_string())?;
        f.write_all(bytes)
            .and_then(|_| f.sync_all())
            .map_err(|e| e.to_string())?;
    }
    fs::rename(temp, path).map_err(|e| e.to_string())
}
fn lock(
    state: &Workspace,
) -> Result<std::sync::MutexGuard<'_, BTreeMap<String, Document>>, String> {
    state
        .documents
        .lock()
        .map_err(|_| "Workspace lock failed; reopen the application.".into())
}
fn mutating(state: &Workspace) -> Result<(), String> {
    if state.exporting.load(Ordering::SeqCst) {
        Err("Wait for export to finish or cancel it.".into())
    } else {
        Ok(())
    }
}
fn doc<'a>(map: &'a mut BTreeMap<String, Document>, id: &str) -> Result<&'a mut Document, String> {
    map.get_mut(id)
        .ok_or_else(|| "Document is no longer open.".into())
}

#[tauri::command]
async fn open_documents(
    app: tauri::AppHandle,
    state: State<'_, Workspace>,
) -> Result<OpenResult, String> {
    mutating(&state)?;
    let picked = app
        .dialog()
        .file()
        .add_filter("SVG", &["svg"])
        .blocking_pick_files();
    let mut result = OpenResult {
        documents: Vec::new(),
        errors: Vec::new(),
    };
    for file in picked.unwrap_or_default() {
        let path = file.into_path().map_err(|e| e.to_string())?;
        let outcome = (|| -> Result<Snapshot, String> {
            let path = path.canonicalize().map_err(|e| e.to_string())?;
            if path
                .extension()
                .and_then(|s| s.to_str())
                .is_none_or(|s| !s.eq_ignore_ascii_case("svg"))
            {
                return Err("Select an .svg file.".into());
            }
            let bytes = sesm_engine::read_svg(&path)?;
            let mut docs = lock(&state)?;
            if let Some(existing) = docs.values().find(|d| d.path == path) {
                return Ok(existing.snapshot(true));
            }
            let id = format!("document-{}", state.counter.fetch_add(1, Ordering::SeqCst));
            let d = Document::from_bytes(id.clone(), path, bytes);
            let snapshot = d.snapshot(true);
            docs.insert(id, d);
            Ok(snapshot)
        })();
        match outcome {
            Ok(d) => result.documents.push(d),
            Err(e) => result.errors.push(format!("{}: {e}", path.display())),
        }
    }
    Ok(result)
}
#[tauri::command]
fn edit_metadata(state: State<Workspace>, id: String, draft: String) -> Result<Snapshot, String> {
    mutating(&state)?;
    if draft.len() > 256 * 1024 {
        return Err("Editor draft exceeds 256 KiB; reduce it below 64 KiB for export.".into());
    }
    let mut docs = lock(&state)?;
    let d = doc(&mut docs, &id)?;
    d.edit(draft);
    Ok(d.snapshot(false))
}
#[tauri::command]
fn approve_document(
    state: State<Workspace>,
    id: String,
    revision: u64,
    acknowledge: bool,
) -> Result<Snapshot, String> {
    mutating(&state)?;
    let mut docs = lock(&state)?;
    let d = doc(&mut docs, &id)?;
    d.approve(revision, acknowledge)?;
    Ok(d.snapshot(false))
}
#[tauri::command]
fn remove_document(state: State<Workspace>, id: String) -> Result<(), String> {
    mutating(&state)?;
    lock(&state)?.remove(&id);
    Ok(())
}
#[tauri::command]
fn list_templates(app: tauri::AppHandle) -> Result<Vec<Template>, String> {
    let dir = template_dir(&app)?;
    if !dir.exists() {
        return Ok(Vec::new());
    }
    let mut templates = Vec::new();
    for item in fs::read_dir(dir).map_err(|e| e.to_string())? {
        let path = item.map_err(|e| e.to_string())?.path();
        if path.extension().is_some_and(|x| x == "json") {
            let bytes = fs::read(&path).map_err(|e| e.to_string())?;
            let t: Template = serde_json::from_slice(&bytes)
                .map_err(|e| format!("Invalid saved template {}: {e}", path.display()))?;
            if t.version != 1 {
                return Err(format!(
                    "Unsupported template version in {}",
                    path.display()
                ));
            }
            templates.push(t);
        }
    }
    templates.sort_by(|a, b| a.name.cmp(&b.name));
    Ok(templates)
}
fn template_path(app: &tauri::AppHandle, name: &str) -> Result<PathBuf, String> {
    Ok(template_dir(app)?.join(format!("{}.json", sesm_engine::hash(name.as_bytes()))))
}
#[tauri::command]
fn save_template(
    app: tauri::AppHandle,
    state: State<Workspace>,
    id: String,
    name: String,
) -> Result<Template, String> {
    let name = name.trim();
    if name.is_empty() || name.len() > 100 {
        return Err("Template name must contain 1–100 bytes.".into());
    }
    let mut docs = lock(&state)?;
    let d = doc(&mut docs, &id)?;
    if !d.validation().exportable {
        return Err("Resolve document errors before saving a template.".into());
    }
    let path = template_path(&app, name)?;
    if path.exists() {
        return Err(
            "That template name already exists; choose another name or delete the old template."
                .into(),
        );
    }
    let t = Template::from_metadata(name.into(), &d.metadata);
    store(
        &path,
        &serde_json::to_vec_pretty(&t).map_err(|e| e.to_string())?,
    )?;
    Ok(t)
}
#[tauri::command]
fn delete_template(app: tauri::AppHandle, name: String) -> Result<(), String> {
    fs::remove_file(template_path(&app, &name)?).map_err(|e| e.to_string())
}
#[tauri::command]
fn apply_template(
    app: tauri::AppHandle,
    state: State<Workspace>,
    id: String,
    name: String,
    overwrite: Vec<String>,
) -> Result<ApplyResult, String> {
    mutating(&state)?;
    let t: Template =
        serde_json::from_slice(&fs::read(template_path(&app, &name)?).map_err(|e| e.to_string())?)
            .map_err(|e| e.to_string())?;
    let mut docs = lock(&state)?;
    let d = doc(&mut docs, &id)?;
    let conflicts = t.apply(d, &overwrite)?;
    Ok(ApplyResult {
        document: d.snapshot(false),
        conflicts,
    })
}
#[tauri::command]
fn preferences(app: tauri::AppHandle) -> Result<Preferences, String> {
    let p = app_data(&app)?.join("preferences.json");
    if !p.exists() {
        return Ok(Preferences::default());
    }
    serde_json::from_slice(&fs::read(p).map_err(|e| e.to_string())?).map_err(|e| e.to_string())
}
#[tauri::command]
fn save_preferences(app: tauri::AppHandle, preferences: Preferences) -> Result<(), String> {
    if preferences.version != 1
        || !["checker", "dark", "light"].contains(&preferences.preview_background.as_str())
        || !["fields", "json"].contains(&preferences.editor_tab.as_str())
    {
        return Err("Unsupported preference value.".into());
    }
    store(
        &app_data(&app)?.join("preferences.json"),
        &serde_json::to_vec_pretty(&preferences).map_err(|e| e.to_string())?,
    )
}

#[tauri::command]
async fn export_documents(
    app: tauri::AppHandle,
    state: State<'_, Workspace>,
) -> Result<Option<ExportReceipt>, String> {
    if state.exporting.swap(true, Ordering::SeqCst) {
        return Err("Export already running.".into());
    }
    state.cancel.store(false, Ordering::SeqCst);
    // The dialog returns a selected parent; the engine creates a new, uniquely named child.
    let result = async {
        let picked = app.dialog().file().blocking_pick_folder();
        let Some(picked) = picked else {
            return Ok(None);
        };
        let parent = picked.into_path().map_err(|e| e.to_string())?;
        let documents: Vec<Document> = lock(&state)?
            .values()
            .filter(|d| d.approved)
            .cloned()
            .collect();
        let serial = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map_err(|e| e.to_string())?
            .as_millis();
        let destination = parent.join(format!("SESM-Export-{serial}"));
        let app_clone = app.clone();
        tauri::async_runtime::spawn_blocking(move || {
            let state = app_clone.state::<Workspace>();
            sesm_engine::export(&documents, &destination, &state.cancel, |completed| {
                let _ = app_clone.emit("export-progress", completed);
            })
        })
        .await
        .map_err(|e| e.to_string())?
        .map(Some)
    }
    .await;
    state.exporting.store(false, Ordering::SeqCst);
    result
}
#[tauri::command]
fn cancel_export(state: State<Workspace>) {
    state.cancel.store(true, Ordering::SeqCst);
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .manage(Workspace::default())
        .invoke_handler(tauri::generate_handler![
            open_documents,
            edit_metadata,
            approve_document,
            remove_document,
            list_templates,
            save_template,
            delete_template,
            apply_template,
            preferences,
            save_preferences,
            export_documents,
            cancel_export
        ])
        .run(tauri::generate_context!())
        .expect("SESM Desktop could not start");
}
