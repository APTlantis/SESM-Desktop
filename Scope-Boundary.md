# Scope Boundary

## In scope for v0.1
- Import and preview individual SVG files.
- Detect, inspect, and preserve existing SESM.
- Edit SESM via structured forms and raw JSON.
- Extract directly observable SVG properties and propose metadata values for user review.
- Create, save, and apply reusable metadata templates.
- Import and process batches of SVGs with per-file review of proposed changes.
- Validate against a documented supported SESM specification version.
- Export SVGs with valid SESM while preserving unrelated content and unknown fields.
- Support Windows, Linux, and macOS.

## Out of scope
- Mandatory Aptlantis or Chromatic Atlas integration.
- Automatic palette/theme generation.
- AI-dependent semantic inference.
- Cloud accounts, sync, or hosted processing.
- Unattended folder monitoring and background pipeline orchestration.
- General-purpose SVG illustration editing.

## Guardrails
Templates must not silently overwrite unique per-file metadata. Extraction must distinguish observed facts from user-entered semantic interpretation. No unreviewed destructive batch writes. No requirement to support every installer or package manager.
