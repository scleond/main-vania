"""Throwaway reproducible export; point at matching official Godot tools."""
import argparse
import pathlib
import re
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--godot", required=True, help="Godot 4.7.2 executable")
parser.add_argument("--templates", required=True, help="Directory containing web_nothreads_*.zip")
args = parser.parse_args()
root = pathlib.Path(__file__).resolve().parent
preset = root / "export_presets.cfg"
original = preset.read_text()
configured = original
for mode in ("debug", "release"):
    template = pathlib.Path(args.templates).resolve() / f"web_nothreads_{mode}.zip"
    if not template.is_file():
        raise SystemExit(f"Missing matching non-threaded template: {template}")
    configured = re.sub(rf'custom_template/{mode}="[^"]*"', f'custom_template/{mode}="{template}"', configured)
(root / "build").mkdir(exist_ok=True)
try:
    preset.write_text(configured)
    subprocess.run([args.godot, "--headless", "--path", str(root), "--export-release", "Web", str(root / "build/index.html")], check=True)
finally:
    preset.write_text(original)
