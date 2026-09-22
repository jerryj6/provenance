from __future__ import annotations

import html
import logging
import re
from html.parser import HTMLParser
from io import BytesIO
from typing import List

from pypdf import PdfReader

logging.getLogger("pypdf").setLevel(logging.ERROR)


class _VisibleHTML(HTMLParser):
    def __init__(self) -> None:
        HTMLParser.__init__(self)
        self.parts: List[str] = []
        self._hidden = 0

    def handle_starttag(self, tag: str, attrs: object) -> None:
        if tag.lower() in ("script", "style"):
            self._hidden += 1

    def handle_endtag(self, tag: str) -> None:
        if tag.lower() in ("script", "style") and self._hidden:
            self._hidden -= 1

    def handle_data(self, data: str) -> None:
        if not self._hidden:
            self.parts.append(data)


def html_to_text(raw: bytes) -> str:
    parser = _VisibleHTML()
    parser.feed(raw.decode("utf-8", errors="replace"))
    return " ".join(parser.parts)


def xml_to_text(raw: bytes) -> str:
    value = raw.decode("utf-8", errors="replace")
    return html.unescape(re.sub(r"<[^>]+>", " ", value))


def pdf_to_text(raw: bytes) -> str:
    reader = PdfReader(BytesIO(raw))
    return "\n".join(page.extract_text() or "" for page in reader.pages)


def to_text(raw: bytes, file_format: str) -> str:
    file_format = file_format.lower().lstrip(".")
    if file_format in ("html", "htm"):
        return html_to_text(raw)
    if file_format == "xml":
        return xml_to_text(raw)
    if file_format == "pdf":
        return pdf_to_text(raw)
    if file_format == "txt":
        return raw.decode("utf-8", errors="replace")
    raise ValueError("unsupported format: %s" % file_format)


def tokenize(text: str) -> List[str]:
    return re.sub(r"[^a-z0-9]+", " ", text.lower()).split()


def normalize(raw: bytes, file_format: str) -> List[str]:
    return tokenize(to_text(raw, file_format))
