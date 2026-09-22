# Provenance

Provenance is a small, reproducible pipeline for ingesting AI-related bills and
finding copied or model legislation through text similarity. Phase 1 contains
the corpus ingest and lineage engine; it does not include a web frontend.

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
