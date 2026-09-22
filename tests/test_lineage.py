from provenance.lineage import analyze, shingles


def test_identical_documents_have_full_containment():
    words = "one two three four five six seven eight nine".split()
    result = analyze({"a": words, "b": words})
    pair = result["pairs"][0]
    assert pair["containment_a_to_b"] == 1.0
    assert pair["containment_b_to_a"] == 1.0


def test_disjoint_documents_have_zero_scores():
    result = analyze(
        {
            "a": "one two three four five six seven eight".split(),
            "b": "red blue green yellow orange purple black white".split(),
        }
    )
    pair = result["pairs"][0]
    assert pair["containment_a_to_b"] == 0.0
    assert pair["jaccard"] == 0.0


def test_evidence_recovers_embedded_passage():
    passage = (
        "a long and carefully drafted legislative passage contains forty words "
        "that should be found in both documents and remains stable for evidence "
        "review across all of the matching text in this synthetic example today"
        " and remains useful for reviewers examining copied legislative language"
    ).split()
    left = ["intro"] * 4 + passage + ["ending"] * 4
    right = ["other"] * 3 + passage + ["tail"] * 3
    result = analyze({"left": left, "right": right})
    evidence = result["pairs"][0]["evidence"]
    assert evidence
    assert "carefully drafted legislative passage" in evidence[0]["text"]
    assert evidence[0]["word_count"] >= 40
    assert evidence[0]["a_start"] == 4
    assert evidence[0]["b_start"] == 3


def test_union_find_clusters_transitive_links():
    common = "alpha beta gamma delta epsilon zeta eta theta".split()
    result = analyze(
        {
            "a": common + "only a".split(),
            "b": common + "only b".split(),
            "c": common + "only c".split(),
        },
        threshold=0.5,
    )
    assert result["clusters"] == [["a", "b", "c"]]
    assert len(shingles(common)) == 1
