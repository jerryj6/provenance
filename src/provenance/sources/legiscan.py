from __future__ import annotations

import base64
import logging
import os
from typing import Any, Dict, List, Optional

import requests

from provenance.corpus import DEFAULT_STATES, SEED_QUERIES

LOG = logging.getLogger(__name__)
API_URL = "https://api.legiscan.com/"


class LegiScanClient:
    def __init__(self, api_key: Optional[str] = None, session: Optional[requests.Session] = None):
        self.api_key = api_key or os.environ.get("LEGISCAN_API_KEY")
        self.session = session or requests.Session()

    @property
    def enabled(self) -> bool:
        return bool(self.api_key)

    def _call(self, action: str, **params: Any) -> Dict[str, Any]:
        if not self.api_key:
            raise RuntimeError("LEGISCAN_API_KEY is not configured")
        payload = dict(params)
        payload["op"] = action
        payload["key"] = self.api_key
        response = self.session.post(API_URL, data=payload, timeout=30)
        response.raise_for_status()
        result = response.json()
        if result.get("status") not in (None, "OK"):
            raise RuntimeError("LegiScan %s failed: %s" % (action, result))
        return result

    def get_search(self, state: str, query: str) -> Dict[str, Any]:
        return self._call("getSearch", state=state, query=query)

    def get_bill(self, bill_id: int) -> Dict[str, Any]:
        return self._call("getBill", id=bill_id)

    def get_bill_text(self, doc_id: int) -> bytes:
        result = self._call("getBillText", id=doc_id)
        text = result.get("text") or result.get("doc", {}).get("text", "")
        return base64.b64decode(text)

    def search(
        self,
        states: Optional[List[str]] = None,
        queries: Optional[List[str]] = None,
        limit: int = 25,
    ) -> List[Dict[str, Any]]:
        if not self.enabled:
            LOG.info("LEGISCAN_API_KEY is missing; skipping LegiScan search")
            return []
        results = []
        for state in states or DEFAULT_STATES:
            for query in queries or SEED_QUERIES:
                payload = self.get_search(state, query)
                rows = payload.get("searchresult", {}).get("results", [])
                results.extend(rows[:limit])
        return results
