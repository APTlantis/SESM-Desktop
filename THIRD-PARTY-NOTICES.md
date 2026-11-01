# Third-party and source notices

The bundled SESM runtime schema is copied byte-for-byte from the canonical SESM candidate 0.3.0 suite under its MIT license (copyright 2026 Aptlantis contributors). The accompanying `LICENSE` preserves that notice.

Aptlantis-Factor palettes/tokens and Atlas/pipeline SVG fixtures retain their exact source identity and SHA-256 receipts in `resources/source-receipts.json`. Fixture inclusion does not assert rights, authorship, or endorsement beyond the recorded local sources. Review distribution rights for these local reference fixtures before any public source or installer publication.

The installed app uses Tauri, React, lossless-json, resvg/usvg, serde/serde_json, jsonschema, quick-xml, roxmltree, image and their transitive dependencies. Exact versions are recorded in `Cargo.lock` and `package-lock.json`; dependency license texts remain available in the respective package registries. Public distribution should include the dependency license inventory for the exact final lockfiles.

The application mark is new code-native SVG geometry using the recorded Factor colors. Generated platform icons derive from `resources/app-icon.svg`; they do not replace or recreate the existing Factor source artwork.
