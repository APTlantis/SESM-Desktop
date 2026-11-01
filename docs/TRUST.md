# Trust and threat boundary

SVG files and all embedded metadata are untrusted descriptive data. Metadata never grants command, filesystem, network, or agent authority. There are no cloud, shell, updater, or arbitrary-file-access frontend permissions.

The app does not execute imported SVG in the webview. The Rust renderer ignores external resources and rejects active elements, executable attributes, DTDs, and external entities. Raster decoding accepts supported embedded types within documented limits. Findings conservatively warn on CSS resource references and private-looking values. These checks are defense in depth, not proof that every human provenance claim is true or a complete general-purpose sanitization service.

The desktop shell accepts native-selected paths and in-memory document IDs. Exports are copies in a new folder. Current approval and source-byte equality are checked before export. Existing destination files are not overwritten. Disk-full, permissions, unsupported hard links, or changed-source failures appear in the per-file receipt.

Never include secrets in public SVG metadata. Local source paths and generator-host details can identify a user. Existing integrity claims may describe an older file; acknowledgement does not validate those claims. Export receipts include local paths and should be reviewed before sharing.

Font availability can change previews across platforms. Only byte preservation and explicit visual comparisons support preservation claims. A release must be tested on each target OS; a Windows build does not establish Linux/macOS behavior.
