"""Regenerate the iOS app's normalized text bundle from the fetched corpus.

Run after `provenance fetch` (or `provenance run`):

    .venv/bin/python3 scripts/export_app_texts.py

Reads each bill's raw document (text_path), normalizes it with the same
`provenance.normalize.normalize` the pipeline uses, and writes the
space-joined word stream to mobile/Provenance/Data/texts/<bill id>.txt.
The app ships these to power the on-device Compare engine.
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "src"))

from provenance.normalize import normalize  # noqa: E402

BILLS_DIR = ROOT / "data" / "bills"
OUT_DIR = ROOT / "mobile" / "Provenance" / "Data" / "texts"


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for bill_file in sorted(BILLS_DIR.glob("*.json")):
        bill = json.loads(bill_file.read_text())
        raw = ROOT / bill["text_path"]
        words = normalize(raw.read_bytes(), raw.suffix.lstrip("."))
        (OUT_DIR / f"{bill['id']}.txt").write_text(" ".join(words))
        print(bill["id"], len(words), "words")


if __name__ == "__main__":
    main()
