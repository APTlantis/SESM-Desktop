# SESM Desktop — Project Proposal

- Project class: Desktop application
- WGS lifecycle: active (implementation candidate; release acceptance pending)
- PPS readiness: ready for implementation planning
- Target: v0.1
- Governing delivery standard: DRS
- Specialized standard: SESM (candidate v0.3.0)
- Theme: Portable, self-describing SVG assets

## Problem
SVG authors currently need to manipulate embedded JSON/XML manually or build their own generators to apply SESM. This creates friction for independent users and for collections of generated SVG assets.

## Mission
Provide an independent, local-first, cross-platform desktop application for inspecting, authoring, validating, and embedding SESM metadata in individual SVGs and reviewed batches, without requiring the Aptlantis pipeline.

## Operational personas
SVG creator, developer, documentation maintainer, archivist, and theme/artifact producer.

## Technical direction
Rust SESM processing engine with Tauri desktop UI. Required release platforms: Windows, Linux, macOS. No mandatory network service. Optional Aptlantis-specific integration must not be a core dependency.

## Boundaries
See Scope-Boundary.md, Success-Criteria.md, Risk-Assessment.md, and Roadmap.md.

## Governance
PPS governs intent and scope; DRS governs desktop release readiness; SESM governs embedded metadata. Exact frontend library, installer channels, storage layout, and optional integration details remain implementation decisions.
