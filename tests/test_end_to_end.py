from pathlib import Path

from provenance.lineage import analyze
from provenance.normalize import normalize


FIXTURES = Path(__file__).parent / "fixtures"
FILES = {
    "ca-2023-ab2655": ("ca_ab2655.html", "html"),
    "ca-2023-ab2839": ("ca_ab2839.html", "html"),
    "co-2024-sb205": ("co_sb205.txt", "txt"),
    "us-118-s4875": ("fed_nofakes.xml", "xml"),
    "fl-2024-hb919": ("fl_hb919.pdf", "pdf"),
    "mn-2023-hf1370": ("mn_hf1370.html", "html"),
    "tn-2023-hb2091": ("tn_hb2091.pdf", "pdf"),
    "ut-2024-sb149": ("ut_sb149.html", "html"),
    "wi-2023-act123": ("wi_act123.pdf", "pdf"),
}


def test_fixture_lineage():
    documents = {
        bill_id: normalize((FIXTURES / filename).read_bytes(), file_format)
        for bill_id, (filename, file_format) in FILES.items()
    }
    result = analyze(documents)
    ca_pair = next(
        pair
        for pair in result["pairs"]
        if {pair["a"], pair["b"]} == {"ca-2023-ab2655", "ca-2023-ab2839"}
    )
    assert ca_pair["containment_a_to_b"] > 0.25
    assert ca_pair["containment_b_to_a"] > 0.25
    assert any(
        "materially deceptive audio or visual media" in evidence["text"]
        for evidence in ca_pair["evidence"]
    )
    for pair in result["pairs"]:
        if pair is not ca_pair:
            assert pair["containment_a_to_b"] < 0.05
            assert pair["containment_b_to_a"] < 0.05
