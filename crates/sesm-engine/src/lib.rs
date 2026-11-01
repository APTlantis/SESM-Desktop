//! Offline, byte-preserving SESM authoring. Desktop permissions are outside this crate.
mod export;
mod json;
mod preview;
mod svg;
pub use export::*;
pub use preview::render;
pub use svg::{analyze, Analysis, Observation};

use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use sha2::{Digest, Sha256};
use std::{path::PathBuf, sync::LazyLock};

pub const MAX_SVG: usize = 5 * 1024 * 1024;
pub const MAX_METADATA: usize = 64 * 1024;
pub const MAX_PIXELS: u64 = 16_000_000;
pub const SCHEMA: &str = include_str!("../../../resources/sesm-0.3.0.schema.json");
static VALIDATOR: LazyLock<jsonschema::Validator> = LazyLock::new(|| {
    jsonschema::options()
        .with_draft(jsonschema::Draft::Draft202012)
        .should_validate_formats(true)
        .offline()
        .build(&serde_json::from_str(SCHEMA).unwrap())
        .expect("bundled SESM schema must compile without remote resolvers")
});

pub fn hash(bytes: &[u8]) -> String {
    format!("{:x}", Sha256::digest(bytes))
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct Finding {
    pub category: String,
    pub severity: String,
    pub code: String,
    pub message: String,
    pub path: String,
}
impl Finding {
    pub fn new(
        category: &str,
        severity: &str,
        code: &str,
        message: impl Into<String>,
        path: impl Into<String>,
    ) -> Self {
        Self {
            category: category.into(),
            severity: severity.into(),
            code: code.into(),
            message: message.into(),
            path: path.into(),
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Validation {
    pub profile: String,
    pub schema: String,
    pub schema_sha256: String,
    pub metadata_version: Option<String>,
    pub findings: Vec<Finding>,
    pub exportable: bool,
}

#[derive(Clone, Debug, Serialize)]
pub struct Change {
    pub path: String,
    pub before: Option<String>,
    pub after: Option<String>,
}

pub fn diff(before: &Value, after: &Value, path: &str, changes: &mut Vec<Change>) {
    if before == after {
        return;
    }
    if let (Some(a), Some(b)) = (before.as_object(), after.as_object()) {
        let mut keys: Vec<_> = a.keys().chain(b.keys()).collect();
        keys.sort();
        keys.dedup();
        for key in keys {
            let p = format!("{}/{}", path, key.replace('~', "~0").replace('/', "~1"));
            match (a.get(key), b.get(key)) {
                (Some(x), Some(y)) => diff(x, y, &p, changes),
                (x, y) => changes.push(Change {
                    path: p,
                    before: x.map(Value::to_string),
                    after: y.map(Value::to_string),
                }),
            }
        }
    } else {
        changes.push(Change {
            path: path.into(),
            before: Some(before.to_string()),
            after: Some(after.to_string()),
        });
    }
}

#[derive(Clone)]
pub struct Document {
    pub id: String,
    pub path: PathBuf,
    pub original: Vec<u8>,
    pub analysis: Analysis,
    pub metadata: Value,
    pub draft: String,
    pub revision: u64,
    pub approved: bool,
    pub warnings_acknowledged: bool,
    original_metadata: Value,
    original_draft: String,
}

#[derive(Clone, Serialize)]
pub struct Snapshot {
    pub id: String,
    pub name: String,
    pub source: String,
    pub source_sha256: String,
    pub draft: String,
    pub metadata_json: String,
    pub dirty: bool,
    pub approved: bool,
    pub revision: u64,
    pub warnings_acknowledged: bool,
    pub validation: Validation,
    pub observations: Vec<Observation>,
    pub changes: Vec<Change>,
    pub preview: Option<String>,
    pub preview_error: Option<String>,
}

impl Document {
    pub fn from_bytes(id: String, path: PathBuf, original: Vec<u8>) -> Self {
        let analysis = analyze(&original);
        let original_draft = analysis.metadata_text.clone().unwrap_or_default();
        let draft = analysis
            .metadata_text
            .clone()
            .unwrap_or_else(|| "{\n  \"sesm_version\": \"0.3.0\"\n}".into());
        let metadata: Value = json::parse(&draft).unwrap_or(json!({"sesm_version":"0.3.0"}));
        let original_metadata = json::parse(&original_draft).unwrap_or(json!({}));
        Self {
            id,
            path,
            original,
            analysis,
            original_metadata,
            original_draft,
            metadata,
            draft,
            revision: 0,
            approved: false,
            warnings_acknowledged: false,
        }
    }
    pub fn edit(&mut self, draft: String) {
        if self.draft == draft {
            return;
        }
        if draft.len() <= MAX_METADATA {
            if let Ok(v @ Value::Object(_)) = json::parse(&draft) {
                self.metadata = v;
            }
        }
        self.draft = draft;
        self.revision += 1;
        self.approved = false;
        self.warnings_acknowledged = false;
    }
    pub fn validation(&self) -> Validation {
        let mut findings = self.analysis.findings.clone();
        if self.draft.len() > MAX_METADATA {
            findings.push(Finding::new(
                "schema",
                "error",
                "metadata-size",
                "SESM JSON exceeds 64 KiB.",
                "/sesm",
            ));
        } else {
            match json::parse(&self.draft) {
                Ok(v) if v.is_object() => {
                    let wrapper = json!({"type":"asset", "asset_type":"svg", "slug":"desktop-asset", "source":{"format":"svg","content":""}, "sesm":v});
                    for e in VALIDATOR.iter_errors(&wrapper) {
                        findings.push(Finding::new(
                            "schema",
                            "error",
                            "schema-validation",
                            e.to_string(),
                            e.instance_path().to_string(),
                        ));
                    }
                    inspect_metadata(&v, "", &mut findings);
                }
                Ok(_) => findings.push(Finding::new(
                    "schema",
                    "error",
                    "metadata-object",
                    "SESM must be a JSON object.",
                    "/sesm",
                )),
                Err(e) => findings.push(Finding::new(
                    "schema",
                    "error",
                    "metadata-json",
                    e.to_string(),
                    "/sesm",
                )),
            }
        }
        let exportable = !findings.iter().any(|f| f.severity == "error");
        let profile = if findings
            .iter()
            .any(|f| f.severity == "error" && f.category != "schema")
        {
            "sesm-unsafe"
        } else if !exportable || !findings.is_empty() {
            "sesm-unverified"
        } else {
            "sesm-safe"
        };
        Validation {
            profile: profile.into(),
            schema: "SESM 0.3.0 (0.2.0 compatible)".into(),
            schema_sha256: hash(SCHEMA.as_bytes()),
            metadata_version: self
                .metadata
                .get("sesm_version")
                .and_then(Value::as_str)
                .map(str::to_owned),
            findings,
            exportable,
        }
    }
    pub fn approve(&mut self, revision: u64, acknowledge: bool) -> Result<(), String> {
        if revision != self.revision {
            return Err("The document changed; review the current revision.".into());
        }
        let validation = self.validation();
        if !validation.exportable {
            return Err("Resolve validation errors before approving.".into());
        }
        let warnings = validation.findings.iter().any(|f| f.severity == "warning");
        if warnings && !acknowledge {
            return Err("Acknowledge this file's warnings before approving.".into());
        }
        self.approved = true;
        self.warnings_acknowledged = warnings && acknowledge;
        Ok(())
    }
    pub fn output(&self) -> Result<Vec<u8>, String> {
        if !self.validation().exportable {
            return Err("Document is not exportable.".into());
        }
        let original = std::str::from_utf8(&self.original).map_err(|e| e.to_string())?;
        let json = serde_json::to_string_pretty(&self.metadata).map_err(|e| e.to_string())?;
        let json = json.replace("]]>", "]]]]><![CDATA[>");
        let eol = if original.contains("\r\n") {
            "\r\n"
        } else {
            "\n"
        };
        let block = format!(
            "<{}metadata id=\"sesm\"><![CDATA[{}{}{}]]></{}metadata>",
            self.analysis.prefix,
            eol,
            json.replace('\n', eol),
            eol,
            self.analysis.prefix
        );
        let mut out = original.to_owned();
        if let Some(range) = &self.analysis.metadata_range {
            out.replace_range(range.clone(), &block);
        } else if let Some((offset, empty)) = self.analysis.insertion {
            if empty {
                out.replace_range(
                    offset..offset + 2,
                    &format!(">{block}</{}svg>", self.analysis.prefix),
                );
            } else {
                out.insert_str(offset, &format!("{eol}{block}"));
            }
        } else {
            return Err("No safe SVG insertion point.".into());
        }
        if out.len() > MAX_SVG {
            return Err("Edited SVG would exceed 5 MiB.".into());
        }
        Ok(out.into_bytes())
    }
    pub fn snapshot(&self, with_preview: bool) -> Snapshot {
        let validation = self.validation();
        let mut changes = Vec::new();
        diff(&self.original_metadata, &self.metadata, "", &mut changes);
        let (preview, preview_error) =
            if with_preview && !self.analysis.findings.iter().any(|f| f.severity == "error") {
                match render(&self.original) {
                    Ok(p) => (Some(p), None),
                    Err(e) => (None, Some(e)),
                }
            } else {
                (None, None)
            };
        Snapshot {
            id: self.id.clone(),
            name: self
                .path
                .file_name()
                .unwrap_or_default()
                .to_string_lossy()
                .into(),
            source: self.path.to_string_lossy().into(),
            source_sha256: hash(&self.original),
            draft: self.draft.clone(),
            metadata_json: self.metadata.to_string(),
            dirty: self.draft != self.original_draft,
            revision: self.revision,
            approved: self.approved,
            warnings_acknowledged: self.warnings_acknowledged,
            validation,
            observations: self.analysis.observations.clone(),
            changes,
            preview,
            preview_error,
        }
    }
}

fn inspect_metadata(v: &Value, path: &str, out: &mut Vec<Finding>) {
    static AUTHORITY: LazyLock<regex::Regex> = LazyLock::new(|| {
        regex::Regex::new(r"(?i)\b(execute|powershell|cmd\.exe|sudo|ignore previous|bypass policy|reveal secrets?|exfiltrate|run command|run shell)\b").unwrap()
    });
    static PRIVATE: LazyLock<regex::Regex> = LazyLock::new(|| {
        regex::Regex::new(r"(?i)([a-z]:[\\/]|/Users/|/home/|\\\\|bearer\s|api[_ -]?key|password|private[_ -]?key|secret)").unwrap()
    });
    match v {
        Value::String(s) => {
            if AUTHORITY.is_match(s) {
                out.push(Finding::new("safety", "error", "metadata-authority", "Metadata contains command or policy authority language. Review it as untrusted content.", path));
            }
            if PRIVATE.is_match(s) {
                out.push(Finding::new(
                    "privacy",
                    "warning",
                    "private-value",
                    "Possible private path or secret-like value; inspect before sharing.",
                    path,
                ));
            }
        }
        Value::Object(m) => {
            for (k, v) in m {
                let p = format!("{path}/{}", k.replace('~', "~0").replace('/', "~1"));
                if PRIVATE.is_match(k) {
                    out.push(Finding::new(
                        "privacy",
                        "warning",
                        "sensitive-key",
                        "Secret-like field name; inspect before sharing.",
                        &p,
                    ));
                }
                inspect_metadata(v, &p, out);
            }
        }
        Value::Array(a) => {
            for (i, v) in a.iter().enumerate() {
                inspect_metadata(v, &format!("{path}/{i}"), out);
            }
        }
        _ => {}
    }
    if path == "/integrity" && !v.is_null() {
        out.push(Finding::new("integrity", "warning", "integrity-unverified", "Existing integrity claims are preserved, not verified. Embedding can invalidate whole-file hashes.", path));
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Template {
    pub version: u32,
    pub name: String,
    pub patch_json: String,
}
impl Template {
    pub fn from_metadata(name: String, metadata: &Value) -> Self {
        let mut patch = metadata.clone();
        for pointer in [
            "/asset/id",
            "/artifact/artifact_id",
            "/artifact/source_id",
            "/artifact/source_path",
            "/artifact/output_path",
            "/artifact/template_path",
            "/provenance/input_records",
            "/provenance/generated_at",
            "/provenance/build_id",
            "/provenance/git_commit",
            "/provenance/host",
        ] {
            if let Some((parent, key)) = pointer.rsplit_once('/') {
                if let Some(m) = patch.pointer_mut(parent).and_then(Value::as_object_mut) {
                    m.remove(key);
                }
            }
        }
        if let Some(m) = patch.as_object_mut() {
            m.remove("integrity");
            m.remove("links");
        }
        Self {
            version: 1,
            name,
            patch_json: patch.to_string(),
        }
    }
    pub fn apply(
        &self,
        document: &mut Document,
        overwrite: &[String],
    ) -> Result<Vec<String>, String> {
        if self.version != 1 {
            return Err("Unsupported template version.".into());
        }
        let patch: Value = json::parse(&self.patch_json).map_err(|e| e.to_string())?;
        if !patch.is_object() {
            return Err("Template patch must be an object.".into());
        }
        if !matches!(json::parse(&document.draft), Ok(Value::Object(_))) {
            return Err("Repair the JSON object draft before applying a template.".into());
        }
        let mut next = document.metadata.clone();
        let mut conflicts = Vec::new();
        merge(&mut next, &patch, "", overwrite, &mut conflicts);
        document.edit(serde_json::to_string_pretty(&next).unwrap());
        Ok(conflicts)
    }
}
fn merge(
    target: &mut Value,
    patch: &Value,
    path: &str,
    overwrite: &[String],
    conflicts: &mut Vec<String>,
) {
    if overwrite.iter().any(|p| p == path) {
        *target = patch.clone();
        return;
    }
    if let (Some(t), Some(p)) = (target.as_object_mut(), patch.as_object()) {
        for (k, v) in p {
            let pointer = format!("{path}/{}", k.replace('~', "~0").replace('/', "~1"));
            if let Some(old) = t.get_mut(k) {
                merge(old, v, &pointer, overwrite, conflicts);
            } else {
                t.insert(k.clone(), v.clone());
            }
        }
    } else if target != patch {
        conflicts.push(path.into());
    }
}
