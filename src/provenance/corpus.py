from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional

SEED_QUERIES = [
    "artificial intelligence",
    "deepfake",
    "synthetic media",
    "automated decision",
    "algorithmic discrimination",
]
DEFAULT_STATES = ["CA", "CO", "FL", "MN", "TN", "UT", "WI", "US"]


@dataclass
class Bill:
    id: str
    jurisdiction: str
    number: str
    title: str
    session: str
    url: str
    source: str
    topics: List[str] = field(default_factory=list)
    text_path: Optional[str] = None


def _text_path(root: Path, item: Dict[str, object]) -> str:
    return str(root / "data" / "raw" / ("%s.%s" % (item["id"], item["format"])))


def load_seeds(path: str = "seeds/bills.json", root: str = ".") -> List[Bill]:
    root_path = Path(root)
    with open(root_path / path, encoding="utf-8") as handle:
        records = json.load(handle)
    return [
        Bill(
            id=item["id"],
            jurisdiction=item["jurisdiction"],
            number=item["number"],
            title=item["title"],
            session=item["session"],
            url=item["url"],
            source="public",
            topics=list(item.get("topics", [])),
            text_path=_text_path(root_path, item),
        )
        for item in records
    ]


def bills_by_id(bills: List[Bill]) -> Dict[str, Bill]:
    return {bill.id: bill for bill in bills}
