# Provenance

Provenance is a small, reproducible pipeline for ingesting AI-related bills and
finding copied or model legislation through text similarity. Phase 1 contains
the corpus ingest and lineage engine plus a native iOS app that presents the
analysis as a forensic document viewer.

## Run locally

```sh
python3 -m venv .venv
. .venv/bin/activate
pip install -e ".[dev]"
provenance run
python3 -m pytest -q
```

`provenance fetch` downloads the public seed corpus. `provenance analyze`
normalizes the downloaded files and writes the analysis outputs. `provenance
run` performs both steps. A LegiScan API key can be placed in `LEGISCAN_API_KEY`
or `.env`; without it, public seeds still run normally.

## Data sources

The initial corpus is nine public bill documents listed in `seeds/bills.json`.
They come from California's legislative information service, Utah, Tennessee,
the federal GovInfo XML archive, Colorado, Florida, Minnesota, and Wisconsin.
The optional LegiScan source searches configured states for a small set of
AI-policy terms while capping results per query to respect API quota.

Downloaded source files are kept in `data/raw/` (ignored by git). Derived,
reviewable metadata and lineage results are committed under `data/`.

## Methodology

Each source is adapted from HTML, XML, PDF, or plain text into words by
lowercasing and replacing non-alphanumeric runs with spaces. The engine builds
8-word shingles, calculates directional containment (the fraction of one
document's shingles present in another) and Jaccard similarity, and links
documents when either directional containment is at least 0.15. Linked pairs
include the three longest matching consecutive passages with word offsets.
Connected components of linked documents form clusters. Outputs intentionally
store hashes, counts, metadata, scores, and evidence, not full source text.

## iOS app (`mobile/`)

A native SwiftUI app ships in `mobile/` and renders the committed pipeline
outputs — no backend required. It bundles `data/manifest.json`,
`data/lineage.json`, `data/findings.json`, and `data/bills/*.json` as app
resources and decodes them offline at launch.

- **Findings** — corpus-wide map: a tappable 9×9 similarity matrix, cluster
  stat tiles, and a card per linked pair with a verbatim-match excerpt.
- **Pair analysis** — directional containment bars for each bill inside the
  other, Jaccard/shingle/passage metrics, the longest shared passages with
  per-bill word offsets, an explicit "similarity is not provenance" caveat,
  and links to the official bill texts.
- **Corpus** — every bill under analysis grouped by jurisdiction, with
  per-bill profiles (word counts, topics, lineage, source URL, text SHA-256).
- **Method** — the normalize/shingle/compare pipeline and honest limitations.

Build it with XcodeGen + Xcode:

```sh
cd mobile
xcodegen generate
open Provenance.xcodeproj   # run on any iPhone simulator, iOS 18+
```
