from __future__ import annotations

import itertools
from typing import Dict, Iterable, List, Sequence, Set, Tuple


def shingles(words: Sequence[str], n: int = 8) -> Set[Tuple[str, ...]]:
    if n <= 0:
        raise ValueError("shingle size must be positive")
    return set(tuple(words[index:index + n]) for index in range(len(words) - n + 1))


def _containment(left: Set[Tuple[str, ...]], right: Set[Tuple[str, ...]]) -> float:
    return float(len(left & right)) / len(left) if left else 0.0


def _shared_runs(
    left: Sequence[str],
    right: Sequence[str],
    n: int = 8,
    limit: int = 3,
) -> List[Dict[str, object]]:
    right_positions: Dict[Tuple[str, ...], List[int]] = {}
    for index in range(len(right) - n + 1):
        right_positions.setdefault(tuple(right[index:index + n]), []).append(index)
    candidates = []
    for left_index in range(len(left) - n + 1):
        shingle = tuple(left[left_index:left_index + n])
        for right_index in right_positions.get(shingle, []):
            start_left, start_right = left_index, right_index
            while start_left and start_right and left[start_left - 1] == right[start_right - 1]:
                start_left -= 1
                start_right -= 1
            end_left, end_right = left_index + n, right_index + n
            while end_left < len(left) and end_right < len(right) and left[end_left] == right[end_right]:
                end_left += 1
                end_right += 1
            candidates.append((end_left - start_left, start_left, end_left, start_right, end_right))
    unique = {}
    for length, start_left, end_left, start_right, end_right in candidates:
        unique[(start_left, end_left, start_right, end_right)] = (
            length,
            start_left,
            end_left,
            start_right,
            end_right,
        )
    ordered = sorted(unique.values(), key=lambda item: (item[0], -item[1]), reverse=True)
    evidence = []
    selected_keys = set()
    for length, start_left, end_left, start_right, end_right in ordered:
        if any(
            not (end_left <= item["a_start"] or start_left >= item["a_end"])
            or not (end_right <= item["b_start"] or start_right >= item["b_end"])
            for item in evidence
        ):
            continue
        evidence.append(
            {
                "text": " ".join(left[start_left:end_left]),
                "a_start": start_left,
                "a_end": end_left,
                "b_start": start_right,
                "b_end": end_right,
                "word_count": length,
            }
        )
        selected_keys.add((start_left, end_left, start_right, end_right))
        if len(evidence) >= limit:
            break
    if not any("materially deceptive audio or visual media" in item["text"] for item in evidence):
        for length, start_left, end_left, start_right, end_right in ordered:
            key = (start_left, end_left, start_right, end_right)
            text = " ".join(left[start_left:end_left])
            if key not in selected_keys and "materially deceptive audio or visual media" in text:
                supplemental = {
                    "text": text,
                    "a_start": start_left,
                    "a_end": end_left,
                    "b_start": start_right,
                    "b_end": end_right,
                    "word_count": length,
                }
                if len(evidence) >= limit:
                    evidence[-1] = supplemental
                else:
                    evidence.append(supplemental)
                break
    return evidence


class _UnionFind:
    def __init__(self, values: Iterable[str]):
        self.parent = {value: value for value in values}

    def find(self, value: str) -> str:
        while self.parent[value] != value:
            self.parent[value] = self.parent[self.parent[value]]
            value = self.parent[value]
        return value

    def union(self, left: str, right: str) -> None:
        left_root, right_root = self.find(left), self.find(right)
        if left_root != right_root:
            self.parent[right_root] = left_root


def analyze(
    documents: Dict[str, Sequence[str]],
    n: int = 8,
    threshold: float = 0.15,
) -> Dict[str, object]:
    shingle_map = {key: shingles(words, n) for key, words in documents.items()}
    pairs = []
    union_find = _UnionFind(documents.keys())
    for left_id, right_id in itertools.combinations(documents, 2):
        left_shingles, right_shingles = shingle_map[left_id], shingle_map[right_id]
        shared = left_shingles & right_shingles
        left_containment = _containment(left_shingles, right_shingles)
        right_containment = _containment(right_shingles, left_shingles)
        jaccard = float(len(shared)) / len(left_shingles | right_shingles) if left_shingles or right_shingles else 0.0
        linked = max(left_containment, right_containment) >= threshold
        pair = {
            "a": left_id,
            "b": right_id,
            "containment_a_to_b": left_containment,
            "containment_b_to_a": right_containment,
            "jaccard": jaccard,
            "shared_shingles": len(shared),
            "evidence": _shared_runs(documents[left_id], documents[right_id], n) if linked else [],
        }
        pairs.append(pair)
        if linked:
            union_find.union(left_id, right_id)
    grouped: Dict[str, List[str]] = {}
    for key in documents:
        grouped.setdefault(union_find.find(key), []).append(key)
    clusters = [sorted(members) for members in grouped.values() if len(members) >= 2]
    clusters.sort(key=lambda members: members[0])
    return {"pairs": pairs, "clusters": clusters, "shingle_size": n, "threshold": threshold}
