from pathlib import Path

from provenance.normalize import normalize, to_text


FIXTURES = Path(__file__).parent / "fixtures"


def test_html_drops_script_and_style_content():
    words = normalize(
        b"<html><style>leaked style words</style><script>leaked js words</script>"
        b"<body>Visible bill language</body></html>",
        "html",
    )
    assert words == ["visible", "bill", "language"]


def test_xml_pdf_and_txt_adapters_produce_words():
    xml_words = normalize(b"<bill><section>Artificial intelligence</section></bill>", "xml")
    assert xml_words == ["artificial", "intelligence"]
    pdf_words = normalize((FIXTURES / "tn_hb2091.pdf").read_bytes(), "pdf")
    assert len(pdf_words) > 20
    assert normalize(b"Plain text passthrough", "txt") == ["plain", "text", "passthrough"]


def test_fixture_formats_are_normalizable():
    assert len(normalize((FIXTURES / "ca_ab2655.html").read_bytes(), "html")) > 100
    assert len(normalize((FIXTURES / "fed_nofakes.xml").read_bytes(), "xml")) > 100
    assert len(normalize((FIXTURES / "co_sb205.txt").read_bytes(), "txt")) > 100
    assert "artificial" in to_text((FIXTURES / "ut_sb149.html").read_bytes(), "html").lower()
