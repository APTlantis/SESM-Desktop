"""Explicit development intake only. Never used by the installed application."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
FACTOR = Path('D:/CTS/Logos-And-Theming/output/apt-Factor')
sources = [
    (Path('D:/.city_hall/SESM/svg_asset.schema.json'), 'resources/sesm-0.3.0.schema.json', 'SESM candidate 0.3.0 runtime schema'),
    (FACTOR / 'palette.css', 'src/theme/palette.css', 'Aptlantis-Factor canonical palette'),
    (FACTOR / 'semantics.json', 'src/theme/semantics.json', 'Aptlantis-Factor semantic mappings'),
    (FACTOR / 'website/apt-factor-website.css', 'src/theme/apt-factor-website.css', 'Aptlantis-Factor accessible surface tokens'),
    (Path('A:/doc-sites/Logos-Themes/public/atlas/examples/apt-Factor/svg/apt-factor-svg-editorial-infographic.svg'), 'tests/fixtures/atlas-infographic.svg', 'Chromatic Atlas structured SVG'),
    (FACTOR / 'data_visualization/apt-factor-data-visualization-bars.svg', 'tests/fixtures/pipeline-bars.svg', 'Pipeline data graphic'),
    (FACTOR / 'svg/apt-factor-svg-product-illustration.svg', 'tests/fixtures/pipeline-artwork.svg', 'Pipeline vector artwork'),
]
records = []
for source, relative, purpose in sources:
    destination = ROOT / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, destination)
    records.append(dict(source=str(source), destination=relative, purpose=purpose, sha256=hashlib.sha256(source.read_bytes()).hexdigest()))
(ROOT / 'resources/source-receipts.json').write_text(json.dumps(dict(version=1, theme_identity='Aptlantis-Factor', physical_run='apt-Factor', records=records), indent=2) + '\n', encoding='utf-8')
