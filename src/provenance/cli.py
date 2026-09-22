from __future__ import annotations

import argparse
import logging
from pathlib import Path
from typing import Dict, List

from provenance.corpus import Bill, load_seeds
from provenance.normalize import normalize
from provenance.publish import publish
from provenance.sources.legiscan import LegiScanClient
from provenance.sources.public import fetch_bill

LOG = logging.getLogger(__name__)


def fetch_public(bills: List[Bill]) -> None:
    for bill in bills:
        path = Path(bill.text_path or "")
        if path.exists() and path.stat().st_size:
            LOG.info("using existing %s", path)
            continue
        LOG.info("fetching %s", bill.id)
        fetch_bill(bill)


def analyze_corpus(bills: List[Bill]) -> None:
    documents: Dict[str, List[str]] = {}
    raw_bytes: Dict[str, bytes] = {}
    for bill in bills:
        path = Path(bill.text_path or "")
        raw = path.read_bytes()
        raw_bytes[bill.id] = raw
        documents[bill.id] = normalize(raw, path.suffix)
    publish(bills, documents, raw_bytes)


def main(argv: List[str] = None) -> int:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    parser = argparse.ArgumentParser(prog="provenance")
    parser.add_argument("command", choices=("fetch", "analyze", "run"))
    args = parser.parse_args(argv)
    bills = load_seeds()
    if args.command in ("fetch", "run"):
        fetch_public(bills)
        LegiScanClient().search()
    if args.command in ("analyze", "run"):
        analyze_corpus(bills)
    return 0
