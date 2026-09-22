from __future__ import annotations

import logging
import time
from pathlib import Path
from typing import Optional

import requests

from provenance.corpus import Bill

LOG = logging.getLogger(__name__)
USER_AGENT = "Provenance/0.1 (public legislative corpus; research)"


def fetch_bill(
    bill: Bill,
    retries: int = 3,
    timeout: int = 30,
    session: Optional[requests.Session] = None,
) -> Path:
    target = Path(bill.text_path or ("data/raw/%s" % bill.id))
    target.parent.mkdir(parents=True, exist_ok=True)
    client = session or requests.Session()
    last_error = None
    for attempt in range(retries):
        try:
            response = client.get(
                bill.url,
                headers={"User-Agent": USER_AGENT},
                timeout=timeout,
            )
            response.raise_for_status()
            target.write_bytes(response.content)
            return target
        except requests.RequestException as error:
            last_error = error
            if attempt + 1 < retries:
                time.sleep(2 ** attempt)
    raise RuntimeError("failed to fetch %s: %s" % (bill.id, last_error))
