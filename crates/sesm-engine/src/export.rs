use crate::{hash, Document, Validation, MAX_SVG};
use serde::{Deserialize, Serialize};
use std::{
    collections::HashSet,
    fs::{self, File, OpenOptions},
    io::{Read, Write},
    path::{Path, PathBuf},
    sync::atomic::{AtomicBool, Ordering},
};

pub fn read_svg(path: &Path) -> Result<Vec<u8>, String> {
    let f = File::open(path).map_err(|e| e.to_string())?;
    if !f.metadata().map_err(|e| e.to_string())?.is_file() {
        return Err("Select a regular SVG file.".into());
    }
    let mut bytes = Vec::new();
    f.take((MAX_SVG + 1) as u64)
        .read_to_end(&mut bytes)
        .map_err(|e| e.to_string())?;
    if bytes.len() > MAX_SVG {
        return Err("SVG exceeds 5 MiB.".into());
    }
    Ok(bytes)
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ExportEntry {
    pub document_id: String,
    pub filename: String,
    pub status: String,
    pub source_sha256: String,
    pub output_sha256: Option<String>,
    pub warnings_acknowledged: bool,
    pub validation: Validation,
    pub message: Option<String>,
}
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ExportReceipt {
    pub version: u32,
    pub application_version: String,
    pub destination: String,
    pub cancelled: bool,
    pub files: Vec<ExportEntry>,
}

pub fn export(
    documents: &[Document],
    destination: &Path,
    cancel: &AtomicBool,
    mut progress: impl FnMut(usize),
) -> Result<ExportReceipt, String> {
    if documents.is_empty() {
        return Err("Approve at least one file before exporting.".into());
    }
    if destination.exists() {
        return Err(
            "Choose a new destination folder; existing destinations are never replaced.".into(),
        );
    }
    let parent = destination
        .parent()
        .ok_or("Destination needs an existing parent directory.")?
        .canonicalize()
        .map_err(|e| e.to_string())?;
    let name = destination
        .file_name()
        .ok_or("Invalid destination folder name.")?;
    let destination = parent.join(name);
    let mut names = HashSet::new();
    names.insert("sesm-export-receipt.json".to_string());
    for d in documents {
        if !d.approved {
            return Err(format!("{} is not approved.", d.path.display()));
        }
        if !d.validation().exportable {
            return Err("An approved document is no longer valid.".into());
        }
        let name = d
            .path
            .file_name()
            .and_then(|s| s.to_str())
            .ok_or("Filename must be Unicode.")?;
        // Portable filenames avoid platform-dependent collisions, reserved device names, and ADS.
        let stem = name.split('.').next().unwrap_or("").to_uppercase();
        if name
            .chars()
            .any(|c| c.is_control() || "<>:\"/\\|?*".contains(c))
            || name.ends_with(['.', ' '])
            || [
                "CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7",
                "COM8", "COM9", "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8",
                "LPT9",
            ]
            .contains(&stem.as_str())
        {
            return Err(format!("Filename is not portable: {name}"));
        }
        if !names.insert(name.to_lowercase()) {
            return Err(format!("Case-insensitive filename collision: {name}"));
        }
        let source = d.path.canonicalize().map_err(|e| e.to_string())?;
        if source == destination || destination.join(name) == source {
            return Err("Destination aliases a source.".into());
        }
    }
    fs::create_dir(&destination).map_err(|e| e.to_string())?;
    let mut receipt = ExportReceipt {
        version: 1,
        application_version: env!("CARGO_PKG_VERSION").into(),
        destination: destination.to_string_lossy().into(),
        cancelled: false,
        files: Vec::new(),
    };
    for (index, d) in documents.iter().enumerate() {
        let cancelled = cancel.load(Ordering::SeqCst);
        let filename = d.path.file_name().unwrap().to_string_lossy().into_owned();
        let mut entry = ExportEntry {
            document_id: d.id.clone(),
            filename: filename.clone(),
            status: "failed".into(),
            source_sha256: hash(&d.original),
            output_sha256: None,
            warnings_acknowledged: d.warnings_acknowledged,
            validation: d.validation(),
            message: None,
        };
        if cancelled {
            entry.status = "cancelled".into();
            receipt.cancelled = true;
        } else {
            let temp = destination.join(format!(".sesm-{index}.partial"));
            let result = (|| -> Result<String, String> {
                if read_svg(&d.path)? != d.original {
                    return Err("Source changed after import; reopen and review it.".into());
                }
                let bytes = d.output()?;
                let check =
                    Document::from_bytes(d.id.clone(), PathBuf::from(&filename), bytes.clone());
                if !check.validation().exportable {
                    return Err("Staged SVG failed revalidation.".into());
                }
                let before = crate::render(&d.original)
                    .map_err(|e| format!("Cannot verify original appearance: {e}"))?;
                let after = crate::render(&bytes)
                    .map_err(|e| format!("Cannot verify edited appearance: {e}"))?;
                if before != after {
                    return Err("Embedding metadata changes the rendered appearance, possibly through structural CSS selectors. Export was blocked; source is unchanged.".into());
                }
                let mut file = OpenOptions::new()
                    .create_new(true)
                    .write(true)
                    .open(&temp)
                    .map_err(|e| e.to_string())?;
                file.write_all(&bytes)
                    .and_then(|_| file.sync_all())
                    .map_err(|e| e.to_string())?;
                drop(file);
                if cancel.load(Ordering::SeqCst) {
                    return Err("Export cancelled before commit.".into());
                }
                // Hard link is an atomic no-clobber commit on all three desktop platforms.
                fs::hard_link(&temp, destination.join(&filename)).map_err(|e| e.to_string())?;
                fs::remove_file(&temp).map_err(|e| e.to_string())?;
                Ok(hash(&bytes))
            })();
            match result {
                Ok(h) => {
                    entry.status = "exported".into();
                    entry.output_sha256 = Some(h);
                }
                Err(e) => {
                    entry.message = Some(e);
                    if cancel.load(Ordering::SeqCst) {
                        entry.status = "cancelled".into();
                        receipt.cancelled = true;
                    }
                }
            }
            let _ = fs::remove_file(&temp);
        }
        receipt.files.push(entry);
        // Persist after every file so a later cancellation/crash retains completed-file evidence.
        write_receipt(&destination, &receipt).map_err(|e| format!("Receipt write failed in {} after {} file results: {e}. Keep the destination and inspect completed copies before retrying into a new folder.",destination.display(),receipt.files.len()))?;
        progress(index + 1);
    }
    Ok(receipt)
}
fn write_receipt(destination: &Path, receipt: &ExportReceipt) -> Result<(), String> {
    let path = destination.join("sesm-export-receipt.json");
    let temp = destination.join(".sesm-receipt.partial");
    let bytes = serde_json::to_vec_pretty(receipt).map_err(|e| e.to_string())?;
    let mut f = File::create(&temp).map_err(|e| e.to_string())?;
    f.write_all(&bytes)
        .and_then(|_| f.sync_all())
        .map_err(|e| e.to_string())?;
    drop(f);
    fs::rename(temp, path).map_err(|e| e.to_string())
}
