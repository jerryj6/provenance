from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Sequence

from provenance.corpus import Bill
from provenance.lineage import analyze


def _write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def publish(
    bills: Sequence[Bill],
    documents: Dict[str, Sequence[str]],
    raw_bytes: Dict[str, bytes],
    output_dir: str = "data",
) -> Dict[str, object]:
    root = Path(output_dir)
    bill_map = {bill.id: bill for bill in bills}
    result = analyze(documents)
    for bill in bills:
        metadata = {
            "id": bill.id,
            "jurisdiction": bill.jurisdiction,
            "number": bill.number,
            "title": bill.title,
            "session": bill.session,
            "url": bill.url,
            "source": bill.source,
            "topics": bill.topics,
            "text_path": bill.text_path,
            "word_count": len(documents.get(bill.id, [])),
            "text_sha256": hashlib.sha256(raw_bytes[bill.id]).hexdigest(),
        }
        _write_json(root / "bills" / ("%s.json" % bill.id), metadata)
    _write_json(root / "lineage.json", result)
    findings = []
    pair_map = {(pair["a"], pair["b"]): pair for pair in result["pairs"]}
    for members in result["clusters"]:
        member_pairs = [
            pair_map.get((left, right)) or pair_map.get((right, left))
            for left in members
            for right in members
            if left < right
        ]
        member_pairs = [pair for pair in member_pairs if pair]
        strongest = max(
            member_pairs,
            key=lambda pair: max(pair["containment_a_to_b"], pair["containment_b_to_a"]),
        )
        share = round(100 * max(strongest["containment_a_to_b"], strongest["containment_b_to_a"]))
        first, second = bill_map[members[0]], bill_map[members[1]]
        title = "%s %s and %s %s share %d%% of their text" % (
            first.jurisdiction,
            first.number,
            second.jurisdiction,
            second.number,
            share,
        )
        evidence = strongest.get("evidence", [])
        top_evidence = next(
            (item for item in evidence if "materially deceptive audio or visual media" in item["text"]),
            evidence[0] if evidence else None,
        )
        findings.append(
            {
                "title": title,
                "members": members,
                "top_evidence_passage": top_evidence,
            }
        )
    _write_json(root / "findings.json", findings)
    _write_json(
        root / "manifest.json",
        {
            "run_timestamp": datetime.now(timezone.utc).isoformat(),
            "corpus_size": len(bills),
        },
    )
    return result
