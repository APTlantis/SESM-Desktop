# Success and Failure Criteria

## v0.1 completion evidence
1. On each of Windows, Linux, and macOS, a user can open, inspect, and preview a supported SVG safely.
2. A user can author and revise SESM through structured and JSON views and export valid metadata.
3. Observable SVG properties can be extracted and proposed without fabricating semantic fields.
4. Reusable templates can be saved and applied while preserving file-specific values unless reviewed.
5. A batch can be reviewed file by file and exported with clear per-file validation results.
6. Existing SESM and unknown metadata fields survive supported round trips; unrelated visual SVG content remains intact.
7. Validation reports actionable errors and warnings under the documented supported SESM version.
8. Core functionality works offline without accounts or Aptlantis services.

## Failure conditions
- Core workflows require cloud connectivity or AI.
- Files are silently damaged, visually changed, or stripped of unrelated metadata.
- Batch processing commits unreviewed destructive changes.
- The application cannot demonstrate core workflows on any required OS.
- The tool becomes dependent on the Aptlantis pipeline.
