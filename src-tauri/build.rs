fn main() {
    tauri_build::try_build(tauri_build::Attributes::new().app_manifest(
        tauri_build::AppManifest::new().commands(&[
            "open_documents",
            "edit_metadata",
            "apply_template",
            "approve_document",
            "remove_document",
            "list_templates",
            "save_template",
            "delete_template",
            "preferences",
            "save_preferences",
            "export_documents",
            "cancel_export",
        ]),
    ))
    .expect("Tauri build configuration");
}
