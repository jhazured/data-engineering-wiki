#!/usr/bin/env python3
"""
Check microsoft-learn-dp600-assessment.md for duplicate questions.
Extracts the bold question text (before **Answer:**), normalizes it, and reports duplicates.
"""
import re
from pathlib import Path

FILE = Path(__file__).resolve().parent / "microsoft-learn-dp600-assessment.md"

def normalize(t: str) -> str:
    """Lowercase, collapse whitespace, remove asterisks."""
    t = t.strip().lower()
    t = re.sub(r'\*+', '', t)
    t = re.sub(r'\s+', ' ', t)
    return t.strip()

def main():
    content = FILE.read_text(encoding="utf-8")
    # Split by ### N. headers (keep header with block)
    blocks = re.split(r'\n(?=### \d+\. )', content)
    questions = []  # (num, title, full_question_normalized, full_question_raw_first_line)
    for block in blocks:
        m = re.match(r'^### (\d+)\. (.+?)\n\n', block)
        if not m:
            continue
        num, title = m.group(1), m.group(2)
        # Question is the first bold paragraph before **Answer:**
        q_match = re.search(r'\n\n\*\*([^*]+(?:\*\*[^*]*)*)\*\*\s*\n\n\*\*Answer:', block, re.DOTALL)
        if not q_match:
            # Fallback: line(s) starting with ** until **Answer:
            lines = []
            in_q = False
            for line in block.splitlines():
                if line.strip().startswith('**Answer:'):
                    break
                if line.strip().startswith('**') and not line.strip().startswith('**Answer'):
                    in_q = True
                    lines.append(line.strip())
                elif in_q and lines and not line.strip().startswith('**'):
                    # continuation of question (some questions span lines)
                    lines.append(line.strip())
            q_raw = ' '.join(lines).strip()
            q_raw = re.sub(r'^\*+|\*+$', '', q_raw)
        else:
            q_raw = q_match.group(1).replace('**', ' ').strip()
            q_raw = re.sub(r'\s+', ' ', q_raw)
        q_norm = normalize(q_raw)
        first_line = q_raw[:80] + '...' if len(q_raw) > 80 else q_raw
        questions.append((int(num), title, q_norm, first_line))

    # Find duplicates: exact normalized match
    by_norm = {}
    for num, title, q_norm, _ in questions:
        key = q_norm[:200]  # use first 200 chars as key to catch same scenario
        if key not in by_norm:
            by_norm[key] = []
        by_norm[key].append((num, title))

    exact_dupes = {k: v for k, v in by_norm.items() if len(v) > 1}

    # Also check: one question's normalized text contained in another (subset duplicates)
    subset_dupes = []
    for i, (n1, t1, q1, _) in enumerate(questions):
        for j, (n2, t2, q2, _) in enumerate(questions):
            if i >= j or n1 == n2:
                continue
            # q1 contained in q2 or vice versa (and not identical)
            if len(q1) > 50 and len(q2) > 50:
                if q1 in q2 or q2 in q1:
                    subset_dupes.append((n1, t1, n2, t2))

    # Report
    print("=" * 60)
    print("DUPLICATE CHECK: microsoft-learn-dp600-assessment.md")
    print("=" * 60)
    print(f"Total questions parsed: {len(questions)}\n")

    if exact_dupes:
        print("--- EXACT / NEAR-EXACT DUPLICATES (same first 200 chars normalized) ---")
        for key, pairs in sorted(exact_dupes.items(), key=lambda x: x[1][0][0]):
            print(f"  Questions: {[p[0] for p in pairs]}  ({', '.join(p[1][:50] + '...' if len(p[1]) > 50 else p[1] for p in pairs)})")
            print(f"  Preview: {key[:120]}...")
            print()
    else:
        print("No exact duplicates found (by first 200 normalized chars).\n")

    if subset_dupes:
        print("--- SUBSET DUPLICATES (one question text contained in another) ---")
        seen = set()
        for n1, t1, n2, t2 in subset_dupes:
            pair = tuple(sorted([(n1, t1), (n2, t2)]))
            if pair in seen:
                continue
            seen.add(pair)
            print(f"  Q{n1} & Q{n2}:")
            print(f"    {t1[:60]}...")
            print(f"    {t2[:60]}...")
            print()
    else:
        print("No subset duplicates found.\n")

    # Similarity by title (same topic)
    print("--- POSSIBLE SAME-TOPIC (similar titles) - review manually ---")
    titles_lower = [(num, title.lower()) for num, title, _, _ in questions]
    for i, (n1, t1) in enumerate(titles_lower):
        for j, (n2, t2) in enumerate(titles_lower):
            if i >= j:
                continue
            # Same key words in title
            w1 = set(t1.replace('–', ' ').replace('-', ' ').split())
            w2 = set(t2.replace('–', ' ').replace('-', ' ').split())
            overlap = len(w1 & w2) / max(len(w1), len(w2), 1)
            if overlap >= 0.6 and n1 != n2:
                print(f"  Q{n1} / Q{n2} (title overlap {overlap:.0%}): {t1[:55]}... | {t2[:55]}...")

if __name__ == "__main__":
    main()
