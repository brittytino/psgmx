"""Generate Migration 24 with 320 original PSGMX stdin/stdout coding quests.

The catalogue uses common computer-science patterns, but all wording, datasets,
and expected outputs are generated for PSGMX. No third-party problem text or
test data is copied.
"""

from __future__ import annotations

import hashlib
import json
import random
from collections import Counter, deque
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "migrations" / "24_seed_original_codebox_bank.sql"
VARIANTS = 16

STARTERS = {
    "python": "import sys\n\ndef solve(data: str) -> str:\n    # Parse data and return the exact required output.\n    return \"\"\n\nprint(solve(sys.stdin.read()))\n",
    "javascript": "const fs = require('fs');\nconst input = fs.readFileSync(0, 'utf8');\n\nfunction solve(data) {\n  // Return the exact required output.\n  return '';\n}\n\nprocess.stdout.write(String(solve(input)));\n",
    "java": "import java.io.*;\nimport java.util.*;\n\npublic class Main {\n  public static void main(String[] args) throws Exception {\n    Scanner in = new Scanner(System.in);\n    // Parse stdin and print the exact required output.\n  }\n}\n",
    "cpp": "#include <bits/stdc++.h>\nusing namespace std;\n\nint main() {\n  ios::sync_with_stdio(false);\n  cin.tie(nullptr);\n  // Parse stdin and print the exact required output.\n  return 0;\n}\n",
}


def compact(value):
    return json.dumps(value, separators=(",", ":"))


def sql(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def array_input(values):
    return f"{len(values)}\n{' '.join(map(str, values))}"


def cases_array_sum(rng):
    result = []
    for n in [1, 4, 7, 10, 14]:
        values = [rng.randint(-40, 60) for _ in range(n)]
        result.append((array_input(values), str(sum(values))))
    return result


def cases_second_largest(rng):
    result = []
    for n in [4, 6, 8, 10, 12]:
        values = [rng.randint(-20, 30) for _ in range(n)]
        values[0], values[1] = 51, 37
        answer = sorted(set(values))[-2]
        result.append((array_input(values), str(answer)))
    return result


def cases_max_subarray(rng):
    result = []
    for n in [3, 5, 8, 11, 15]:
        values = [rng.randint(-12, 15) for _ in range(n)]
        best = current = values[0]
        for value in values[1:]:
            current = max(value, current + value)
            best = max(best, current)
        result.append((array_input(values), str(best)))
    return result


def cases_pair_sum(rng):
    result = []
    for n in [4, 6, 8, 10, 12]:
        values = rng.sample(range(-50, 80), n)
        i, j = sorted(rng.sample(range(n), 2))
        target = values[i] + values[j]
        # Regenerate until the selected pair is the only solution.
        while sum(1 for a in range(n) for b in range(a + 1, n) if values[a] + values[b] == target) != 1:
            values = rng.sample(range(-80, 120), n)
            target = values[i] + values[j]
        result.append((array_input(values) + f"\n{target}", compact([i, j])))
    return result


def cases_rotate(rng):
    result = []
    for n in [3, 5, 7, 9, 12]:
        values = [rng.randint(-20, 50) for _ in range(n)]
        k = rng.randint(0, n * 3)
        shift = k % n
        answer = values[-shift:] + values[:-shift] if shift else values
        result.append((array_input(values) + f"\n{k}", " ".join(map(str, answer))))
    return result


def cases_missing(rng):
    result = []
    for n in [2, 4, 7, 10, 15]:
        missing = rng.randint(0, n)
        values = [value for value in range(n + 1) if value != missing]
        rng.shuffle(values)
        result.append((array_input(values), str(missing)))
    return result


def cases_range_sums(rng):
    result = []
    for n in [4, 6, 8, 10, 14]:
        values = [rng.randint(-10, 30) for _ in range(n)]
        queries = []
        for _ in range(4):
            left = rng.randint(0, n - 1)
            right = rng.randint(left, n - 1)
            queries.append((left, right))
        stdin = array_input(values) + "\n4\n" + "\n".join(f"{a} {b}" for a, b in queries)
        stdout = "\n".join(str(sum(values[a:b + 1])) for a, b in queries)
        result.append((stdin, stdout))
    return result


def cases_palindrome(rng):
    bases = ["Never odd or even", "PSG MCA 2026", "A man, a plan, a canal: Panama!", "Data, atad!", "Placement ready"]
    rng.shuffle(bases)
    return [(text, "true" if (clean := "".join(ch.lower() for ch in text if ch.isalnum())) == clean[::-1] else "false") for text in bases]


def cases_anagram(rng):
    pairs = [("Dormitory", "Dirty room"), ("algorithm", "logarithm"), ("PSG Tech", "Tech PSG"), ("binary", "brainy"), ("coding", "decoding")]
    rng.shuffle(pairs)
    result = []
    for left, right in pairs:
        normalize = lambda value: sorted(ch.lower() for ch in value if ch.isalnum())
        result.append((f"{left}\n{right}", "true" if normalize(left) == normalize(right) else "false"))
    return result


def cases_frequency(rng):
    alphabet = "abcdefxyz"
    result = []
    for n in [5, 8, 12, 16, 22]:
        text = "".join(rng.choice(alphabet) for _ in range(n))
        counts = Counter(text)
        answer = ",".join(f"{key}:{counts[key]}" for key in sorted(counts))
        result.append((text, answer))
    return result


def cases_unique_window(rng):
    alphabet = "abcdeXYZ123"
    result = []
    for n in [4, 7, 10, 14, 20]:
        text = "".join(rng.choice(alphabet) for _ in range(n))
        best = 0
        for left in range(n):
            seen = set()
            for right in range(left, n):
                if text[right] in seen:
                    break
                seen.add(text[right])
                best = max(best, right - left + 1)
        result.append((text, str(best)))
    return result


def cases_brackets(rng):
    values = ["([]{})", "([)]", "(((())))", "{[()]}[]", "(()"]
    rng.shuffle(values)
    result = []
    for value in values:
        stack = []
        pairs = {")": "(", "]": "[", "}": "{"}
        valid = True
        for char in value:
            if char in "([{": stack.append(char)
            elif not stack or stack.pop() != pairs[char]: valid = False; break
        result.append((value, "true" if valid and not stack else "false"))
    return result


def cases_next_greater(rng):
    result = []
    for n in [3, 5, 7, 10, 14]:
        values = [rng.randint(-10, 40) for _ in range(n)]
        answer = []
        for i, value in enumerate(values):
            answer.append(next((other for other in values[i + 1:] if other > value), -1))
        result.append((array_input(values), " ".join(map(str, answer))))
    return result


def cases_binary_search(rng):
    result = []
    for n in [3, 5, 8, 11, 16]:
        values = sorted(rng.sample(range(-100, 150), n))
        if n % 2: target = values[rng.randrange(n)]
        else:
            target = 999
        answer = values.index(target) if target in values else -1
        result.append((array_input(values) + f"\n{target}", str(answer)))
    return result


def cases_merge_intervals(rng):
    result = []
    for n in [3, 4, 6, 8, 10]:
        intervals = []
        cursor = rng.randint(0, 3)
        for _ in range(n):
            start = cursor + rng.randint(0, 3)
            end = start + rng.randint(1, 5)
            intervals.append([start, end])
            cursor += rng.randint(1, 4)
        merged = []
        for start, end in sorted(intervals):
            if not merged or start > merged[-1][1]: merged.append([start, end])
            else: merged[-1][1] = max(merged[-1][1], end)
        stdin = str(n) + "\n" + "\n".join(f"{a} {b}" for a, b in intervals)
        result.append((stdin, compact(merged)))
    return result


def cases_islands(rng):
    result = []
    for rows, cols in [(2, 3), (3, 4), (4, 5), (5, 6), (6, 7)]:
        grid = [[1 if rng.random() < .42 else 0 for _ in range(cols)] for _ in range(rows)]
        seen = set(); count = 0
        for r in range(rows):
            for c in range(cols):
                if not grid[r][c] or (r, c) in seen: continue
                count += 1; queue = deque([(r, c)]); seen.add((r, c))
                while queue:
                    cr, cc = queue.popleft()
                    for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        nr, nc = cr + dr, cc + dc
                        if 0 <= nr < rows and 0 <= nc < cols and grid[nr][nc] and (nr, nc) not in seen:
                            seen.add((nr, nc)); queue.append((nr, nc))
        stdin = f"{rows} {cols}\n" + "\n".join(" ".join(map(str, row)) for row in grid)
        result.append((stdin, str(count)))
    return result


def cases_shortest_path(rng):
    result = []
    for n in [4, 6, 8, 10, 12]:
        edges = {(i, i + 1) for i in range(n - 1)}
        for _ in range(n):
            a, b = sorted(rng.sample(range(n), 2)); edges.add((a, b))
        source, target = rng.sample(range(n), 2)
        graph = [[] for _ in range(n)]
        for a, b in edges: graph[a].append(b); graph[b].append(a)
        distance = [-1] * n; distance[source] = 0; queue = deque([source])
        while queue:
            node = queue.popleft()
            for nxt in graph[node]:
                if distance[nxt] == -1: distance[nxt] = distance[node] + 1; queue.append(nxt)
        stdin = f"{n} {len(edges)}\n" + "\n".join(f"{a} {b}" for a, b in sorted(edges)) + f"\n{source} {target}"
        result.append((stdin, str(distance[target])))
    return result


def cases_min_coins(rng):
    result = []
    for count in [2, 3, 4, 5, 6]:
        coins = sorted(set([1] + [rng.randint(2, 12) for _ in range(count - 1)]))
        amount = rng.randint(12, 55)
        dp = [amount + 1] * (amount + 1); dp[0] = 0
        for value in range(1, amount + 1):
            for coin in coins:
                if coin <= value: dp[value] = min(dp[value], dp[value - coin] + 1)
        result.append((f"{len(coins)}\n{' '.join(map(str, coins))}\n{amount}", str(dp[amount] if dp[amount] <= amount else -1)))
    return result


def cases_lcs(rng):
    alphabet = "ABCDE"
    result = []
    for n, m in [(3, 4), (5, 5), (6, 8), (9, 7), (10, 11)]:
        left = "".join(rng.choice(alphabet) for _ in range(n)); right = "".join(rng.choice(alphabet) for _ in range(m))
        dp = [[0] * (m + 1) for _ in range(n + 1)]
        for i in range(1, n + 1):
            for j in range(1, m + 1):
                dp[i][j] = dp[i - 1][j - 1] + 1 if left[i - 1] == right[j - 1] else max(dp[i - 1][j], dp[i][j - 1])
        result.append((f"{left}\n{right}", str(dp[n][m])))
    return result


def cases_spiral(rng):
    result = []
    for rows, cols in [(1, 4), (2, 3), (3, 3), (3, 5), (5, 4)]:
        matrix = [[rng.randint(-9, 30) for _ in range(cols)] for _ in range(rows)]
        top, bottom, left, right = 0, rows - 1, 0, cols - 1; answer = []
        while top <= bottom and left <= right:
            answer.extend(matrix[top][left:right + 1]); top += 1
            for r in range(top, bottom + 1): answer.append(matrix[r][right])
            right -= 1
            if top <= bottom: answer.extend(reversed(matrix[bottom][left:right + 1])); bottom -= 1
            if left <= right:
                for r in range(bottom, top - 1, -1): answer.append(matrix[r][left])
                left += 1
        stdin = f"{rows} {cols}\n" + "\n".join(" ".join(map(str, row)) for row in matrix)
        result.append((stdin, " ".join(map(str, answer))))
    return result


FAMILIES = [
    ("array-sum", "Array Sum", "arrays", 1, "Read n integers and print their sum.", "Line 1: n. Line 2: n integers.", "One integer: the sum.", cases_array_sum),
    ("second-largest", "Second Distinct Maximum", "arrays", 2, "Print the second-largest distinct value. At least two distinct values are guaranteed.", "Line 1: n. Line 2: n integers.", "The second-largest distinct integer.", cases_second_largest),
    ("maximum-subarray", "Maximum Contiguous Sum", "dynamic-programming", 3, "Find the largest sum of a non-empty contiguous subarray.", "Line 1: n. Line 2: n integers.", "The maximum contiguous sum.", cases_max_subarray),
    ("pair-sum", "Pair Sum Indices", "hashing", 3, "Find the unique pair whose values sum to the target and print their zero-based indices as compact JSON.", "Line 1: n. Line 2: n integers. Line 3: target.", "Compact JSON array [i,j] with i < j.", cases_pair_sum),
    ("rotate-right", "Rotate Array Right", "arrays", 2, "Rotate the array to the right by k positions.", "Line 1: n. Line 2: n integers. Line 3: k.", "The rotated values separated by one space.", cases_rotate),
    ("missing-number", "Missing Number", "math", 1, "The input contains n distinct values selected from 0 through n. Print the missing value.", "Line 1: n. Line 2: n integers.", "The missing integer.", cases_missing),
    ("range-sums", "Inclusive Range Sums", "prefix-sum", 3, "Answer each zero-based inclusive range-sum query.", "Line 1: n. Line 2: n integers. Line 3: q. Next q lines: left right.", "One range sum per line.", cases_range_sums),
    ("normalised-palindrome", "Normalised Palindrome", "strings", 1, "Ignoring case and non-alphanumeric characters, decide whether the line is a palindrome.", "One text line.", "true or false in lowercase.", cases_palindrome),
    ("normalised-anagram", "Normalised Anagram", "strings", 1, "Ignoring case and non-alphanumeric characters, decide whether two lines are anagrams.", "Two text lines.", "true or false in lowercase.", cases_anagram),
    ("character-frequency", "Sorted Character Frequencies", "hashing", 2, "Count every character and print entries in ascending character order.", "One non-empty ASCII line without spaces.", "Comma-separated character:count entries.", cases_frequency),
    ("longest-unique-window", "Longest Unique Window", "sliding-window", 3, "Find the length of the longest substring with no repeated character.", "One text line.", "One integer length.", cases_unique_window),
    ("balanced-brackets", "Balanced Brackets", "stack", 2, "Decide whether every bracket is correctly matched and nested.", "One line containing only ()[]{}.", "true or false in lowercase.", cases_brackets),
    ("next-greater", "Next Greater Value", "stack", 3, "For each value, find the first greater value to its right, or -1 if none exists.", "Line 1: n. Line 2: n integers.", "n integers separated by one space.", cases_next_greater),
    ("binary-search", "Binary Search Position", "binary-search", 2, "Find a target in a strictly increasing array.", "Line 1: n. Line 2: n integers. Line 3: target.", "The zero-based index, or -1.", cases_binary_search),
    ("merge-intervals", "Merge Closed Intervals", "sorting", 3, "Merge every overlapping closed interval.", "Line 1: n. Next n lines: start end.", "Compact JSON array of merged intervals sorted by start.", cases_merge_intervals),
    ("island-count", "Four-Way Island Count", "graphs", 3, "Count connected components of 1 cells using only up, down, left, and right moves.", "Line 1: rows cols. Next rows lines: cols binary integers.", "The number of islands.", cases_islands),
    ("shortest-unweighted-path", "Shortest Unweighted Path", "graphs", 4, "Find the minimum edge count between two vertices in an undirected graph.", "Line 1: n m. Next m lines: u v. Final line: source target.", "The minimum edge count, or -1.", cases_shortest_path),
    ("minimum-coins", "Minimum Coin Count", "dynamic-programming", 4, "Find the minimum number of supplied coin values needed to form the amount, with unlimited reuse.", "Line 1: coin count. Line 2: coin values. Line 3: amount.", "The minimum count, or -1.", cases_min_coins),
    ("lcs-length", "Longest Common Subsequence Length", "dynamic-programming", 5, "Find the length of the longest subsequence common to both strings.", "Two uppercase text lines.", "One integer length.", cases_lcs),
    ("matrix-spiral", "Clockwise Matrix Spiral", "matrices", 3, "Print all matrix values in clockwise spiral order, starting at the top-left corner.", "Line 1: rows cols. Next rows lines: matrix values.", "Values separated by one space.", cases_spiral),
]


def build():
    quest_rows = []
    case_rows = []
    for family_index, (slug_base, title, topic, difficulty, summary, input_format, output_format, factory) in enumerate(FAMILIES):
        for variant in range(1, VARIANTS + 1):
            seed = int(hashlib.sha256(f"{slug_base}:{variant}".encode()).hexdigest()[:16], 16)
            rng = random.Random(seed)
            cases = factory(rng)
            slug = f"{slug_base}-{variant:02d}"
            statement = (
                f"## {title}\n\n{summary}\n\n"
                f"### Input\n{input_format}\n\n### Output\n{output_format}\n\n"
                f"This is PSGMX training dataset variant {variant:02d}. Submit a complete stdin/stdout program; "
                "do not hard-code the visible sample. Trailing whitespace is ignored."
            )
            sample = [{"input": cases[0][0], "expected_output": cases[0][1], "label": "Visible example"}]
            xp = 30 + difficulty * 10
            quest_rows.append(
                "(" + ",".join([
                    sql(slug), sql(f"{title} · Set {variant:02d}"), "'coding'", "'published'",
                    sql(statement), str(difficulty),
                    "ARRAY['python','java','cpp','javascript']::text[]", "3", "256",
                    sql(compact(sample)) + "::jsonb", "0.800", "5", "10", "NULL", "'{}'::uuid[]",
                    "ARRAY[" + sql(topic) + "]::text[]", str(xp), "true", sql("PSGMX original"),
                    sql(compact(STARTERS)) + "::jsonb", "'stdin_stdout'"
                ]) + ")"
            )
            for case_index, (stdin, stdout) in enumerate(cases):
                case_rows.append(
                    "(" + ",".join([sql(slug), str(case_index), sql(stdin), sql(stdout), "true" if case_index == 0 else "false"]) + ")"
                )

    header = """-- ============================================================
-- PSGMX Migration 24 — 320 original CodeBox quests
-- Generated by supabase/scripts/generate_codebox_seed.py.
-- All wording and deterministic datasets are original PSGMX material.
-- ============================================================

BEGIN;

INSERT INTO public.quests(
  slug, title, type, status, problem_md, difficulty, allowed_languages,
  time_limit_seconds, memory_limit_mb, sample_cases_json, min_pass_rate,
  min_ai_quality_score, max_attempts, target_batch_id, target_team_ids,
  topic_tags, xp_reward, is_system_seed, bank_origin, starter_code_json,
  solution_contract
) VALUES
"""
    quests_sql = ",\n".join(quest_rows) + "\nON CONFLICT (slug) WHERE slug IS NOT NULL DO UPDATE SET\n  title = EXCLUDED.title, problem_md = EXCLUDED.problem_md, difficulty = EXCLUDED.difficulty,\n  sample_cases_json = EXCLUDED.sample_cases_json, topic_tags = EXCLUDED.topic_tags,\n  starter_code_json = EXCLUDED.starter_code_json, status = 'published', is_system_seed = true;\n\n"
    tests_sql = "WITH seeded(slug, case_index, stdin, expected_stdout, is_sample) AS (VALUES\n" + ",\n".join(case_rows) + "\n)\nINSERT INTO public.quest_test_cases(quest_id, case_index, stdin, expected_stdout, is_sample)\nSELECT q.id, s.case_index, s.stdin, s.expected_stdout, s.is_sample\nFROM seeded s JOIN public.quests q ON q.slug = s.slug\nON CONFLICT (quest_id, case_index) DO UPDATE SET\n  stdin = EXCLUDED.stdin, expected_stdout = EXCLUDED.expected_stdout, is_sample = EXCLUDED.is_sample;\n\n"
    footer = """DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT count(*) INTO v_count FROM public.quests WHERE is_system_seed;
  IF v_count < 320 THEN
    RAISE EXCEPTION 'CodeBox seed incomplete: expected at least 320 system quests, found %', v_count;
  END IF;
END $$;

COMMIT;
"""
    OUTPUT.write_text(header + quests_sql + tests_sql + footer, encoding="utf-8")
    print(f"Generated {len(quest_rows)} quests and {len(case_rows)} test cases at {OUTPUT}")


if __name__ == "__main__":
    build()
