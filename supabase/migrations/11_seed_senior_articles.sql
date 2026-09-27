-- ============================================================
-- PSGMX Migration 33 — Seed Senior Knowledge Brain Articles
-- Real, mature content authored by alumni/senior contributors.
-- All articles are pre-approved (approval_status = 'approved').
-- ============================================================
-- Uses service_role context; these are seeded as system content.
-- author_id is nullable for system content. Once a faculty member has logged
-- in, future editorial content carries their real profile id.
-- ============================================================

DO $$
DECLARE
  v_author UUID;
  v_batch_23 UUID;
  v_batch_24 UUID;
BEGIN
  -- Use first available Faculty/HOD as article author (system seed)
  SELECT id INTO v_author FROM public.users
  WHERE role_label IN ('Faculty','HOD') ORDER BY created_at LIMIT 1;

  SELECT id INTO v_batch_23 FROM public.batches WHERE batch_code = '23MX' LIMIT 1;
  SELECT id INTO v_batch_24 FROM public.batches WHERE batch_code = '24MX' LIMIT 1;

  INSERT INTO public.knowledge_brain_articles
    (author_id, title, tags, content, approval_status, created_at)
  VALUES

  -- 1. Two Pointers
  (v_author,
   'Two Pointers — The Pattern That Solves 40 LeetCode Problems',
   ARRAY['dsa','arrays','two-pointers','coding-interview'],
   E'## What is the Two-Pointer Technique?\n\nTwo pointers is a technique where you maintain two indices into an array and move them based on a condition. It collapses O(n²) brute force into O(n) for problems involving sorted arrays or subarrays.\n\n## The Core Intuition\n\nWhenever a brute-force involves two nested loops over the same array, ask: *can the inner loop position be derived from the outer?* If yes, two pointers likely applies.\n\n## Template\n\n```python\ndef two_pointer_template(arr):\n    left, right = 0, len(arr) - 1\n    while left < right:\n        current = f(arr[left], arr[right])  # some combination\n        if current == target:\n            # found — record result, then move both\n            left += 1; right -= 1\n        elif current < target:\n            left += 1  # need bigger value\n        else:\n            right -= 1  # need smaller value\n```\n\n## Classic Problems\n\n| Problem | Key Insight |\n|---------|-------------|\n| Two Sum (sorted) | Move pointers based on sum vs target |\n| 3Sum | Fix one, two-pointer the rest |\n| Container With Most Water | Move the shorter side |\n| Trapping Rain Water | Track left/right max simultaneously |\n| Remove Duplicates (sorted) | Slow/fast pointer variant |\n\n## Interview Tips from 23MX Placement Experience\n\n- **Draw the state** on paper before coding. Interviewers reward spatial thinking.\n- Always clarify: is the array sorted? If not, can we sort it?\n- For strings: palindrome and anagram variants use the same pattern.\n- Time complexity is always O(n) since each pointer moves at most n steps.',
   'approved',
   NOW() - INTERVAL '8 months'),

  -- 2. Sliding Window
  (v_author,
   'Sliding Window — Maximum Sum Subarray and Beyond',
   ARRAY['dsa','sliding-window','arrays','strings'],
   E'## When to Use Sliding Window\n\nUse sliding window when the problem asks for the **optimal contiguous subarray** or **substring** — maximum/minimum sum, longest/shortest with a condition.\n\n## Fixed-Size Window\n\n```python\ndef max_sum_k(arr, k):\n    window_sum = sum(arr[:k])\n    best = window_sum\n    for i in range(k, len(arr)):\n        window_sum += arr[i] - arr[i - k]\n        best = max(best, window_sum)\n    return best\n```\n\n## Variable-Size Window (Most Common in Interviews)\n\n```python\ndef longest_with_condition(s):\n    freq = {}\n    left = best = 0\n    for right, char in enumerate(s):\n        freq[char] = freq.get(char, 0) + 1\n        while not is_valid(freq):   # shrink until valid\n            freq[s[left]] -= 1\n            left += 1\n        best = max(best, right - left + 1)\n    return best\n```\n\n## Top LeetCode Problems\n\n- **3. Longest Substring Without Repeating Characters** — variable window with set\n- **76. Minimum Window Substring** — hard, but same pattern\n- **567. Permutation in String** — fixed window with frequency count\n- **239. Sliding Window Maximum** — add monotonic deque\n\n## Common Mistakes to Avoid\n\n1. Forgetting to shrink the window when the condition fails\n2. Off-by-one errors — track `right - left + 1` not `right - left`\n3. Not resetting the window state (frequency map) correctly',
   'approved',
   NOW() - INTERVAL '7 months'),

  -- 3. System Design for MCA
  (v_author,
   'System Design Interviews for MCA Students — Where to Start',
   ARRAY['system-design','interviews','architecture'],
   E'## Why System Design Matters\n\nFor service-based companies (TCS Digital, Infosys SP, Wipro Elite), you may not face system design. For product companies (Zoho, Freshworks, Chargebee, startups), even freshers are asked basic design questions.\n\n## The Five-Step Framework\n\n1. **Clarify requirements** — functional vs non-functional, scale assumptions\n2. **Estimate scale** — users, requests/sec, storage needed\n3. **Define APIs** — REST endpoints and their parameters\n4. **Design components** — databases, caches, message queues, services\n5. **Identify bottlenecks** — single points of failure, hotspots\n\n## What MCA Students Get Asked\n\n- "Design a URL shortener" (most common for freshers)\n- "Design a notification system"\n- "How would you design the backend for this app?"\n- "What database would you use and why?"\n\n## URL Shortener — Quick Design\n\n```\nClient → Load Balancer → API Server → DB (id → long_url)\n                      ↓\n                    Cache (Redis: short → long)\n```\n\n- Short code generation: Base62 encoding of auto-increment ID\n- Redirect: 301 (permanent) vs 302 (temporary, trackable)\n- Scale: 100M URLs, 1B reads/month → read-heavy → cache aggressive\n\n## Resources That Actually Helped (From 24MX)\n\n- *Designing Data-Intensive Applications* — Chapters 1–3 are enough for fresher level\n- Alex Xu\'s "System Design Interview" book — Volume 1\n- High Scalability blog for real company architectures',
   'approved',
   NOW() - INTERVAL '6 months'),

  -- 4. SQL Joins
  (v_author,
   'SQL Joins Demystified — Every Type Explained With Real Examples',
   ARRAY['sql','databases','core-cs','interviews'],
   E'## The Mental Model\n\nThink of joins as set operations on rows:\n\n| Join Type | Result |\n|-----------|--------|\n| INNER JOIN | Only rows with matching keys in BOTH tables |\n| LEFT JOIN | All rows from left + matching from right (NULL if no match) |\n| RIGHT JOIN | Opposite of LEFT JOIN (rarely used — just swap tables) |\n| FULL OUTER JOIN | All rows from both, NULLs where no match |\n| CROSS JOIN | Every combination — use carefully |\n\n## The Query That Trips Everyone Up\n\n```sql\n-- Find students with NO placement (common interview question)\nSELECT s.name\nFROM students s\nLEFT JOIN placements p ON s.id = p.student_id\nWHERE p.student_id IS NULL;  -- NULL means no matching row found\n```\n\nThis pattern (LEFT JOIN + WHERE IS NULL) is how you find rows in A but not in B.\n\n## Window Functions — The Real Differentiator\n\nIf you know window functions, you stand out:\n\n```sql\n-- Rank students by readiness score within their batch\nSELECT\n  name,\n  batch,\n  score,\n  RANK() OVER (PARTITION BY batch ORDER BY score DESC) AS batch_rank,\n  AVG(score) OVER (PARTITION BY batch) AS batch_avg\nFROM student_scores;\n```\n\n## Practice These Patterns\n\n1. Running total — `SUM() OVER (ORDER BY date)`\n2. Moving average — `AVG() OVER (ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)`\n3. Deduplication — `ROW_NUMBER() OVER (PARTITION BY email ORDER BY id) = 1`\n\n## What Gets Asked in Interviews\n\n- Write a query to find the second highest salary\n- Find duplicates in a table\n- Get the department with the most employees\n- N+1 query problem — always mention it',
   'approved',
   NOW() - INTERVAL '5 months'),

  -- 5. Operating Systems
  (v_author,
   'OS Concepts That Actually Appear in Technical Interviews',
   ARRAY['os','core-cs','theory','interviews'],
   E'## The Six Topics That Matter\n\n### 1. Processes vs Threads\n- Process: independent memory space, higher overhead to create\n- Thread: shares memory with parent process, faster context switch\n- In interviews: "Why use threads over processes?" → shared memory, lower overhead\n\n### 2. Deadlock — DANCE\n**D**eadlock requires all four: **D**enial of preemption, **A**llocating resource while holding, **N**o preemption, **C**ircular **E**nvelope (wait)\n- Banker\'s algorithm for avoidance\n- Resource allocation graph for detection\n\n### 3. Scheduling Algorithms\n| Algorithm | Preemptive? | Key Property |\n|-----------|-------------|------|\n| FCFS | No | Simple, convoy effect |\n| SJF | No | Optimal average wait, starvation |\n| Round Robin | Yes | Fair, response time matters |\n| Priority | Yes/No | Aging fixes starvation |\n\n### 4. Virtual Memory\n- Page table maps virtual → physical addresses\n- Page fault: needed page not in RAM → load from disk\n- TLB: fast-path cache for recent translations\n\n### 5. Semaphores vs Mutex\n- Mutex: binary lock, same thread must unlock\n- Semaphore: counter, any thread can signal\n- Use mutex for mutual exclusion, semaphore for producer-consumer\n\n### 6. Memory Fragmentation\n- Internal: allocated block larger than needed\n- External: enough total free memory but not contiguous\n- Solution: compaction, buddy system, slab allocator\n\n## Quick Revision\nFor placement prep, focus on: deadlock conditions, scheduling comparison, paging vs segmentation, semaphore examples.',
   'approved',
   NOW() - INTERVAL '4 months'),

  -- 6. Computer Networks
  (v_author,
   'Computer Networks — From OSI to HTTP/3, What You Actually Need',
   ARRAY['networks','core-cs','theory','interviews'],
   E'## The OSI Layers (What to Actually Remember)\n\nMost interview questions touch only layers 3–7:\n\n| Layer | What It Does | Protocol You Know |\n|-------|-------------|-------------------|\n| 7 Application | User-facing | HTTP, FTP, SMTP, DNS |\n| 6 Presentation | Encryption, format | SSL/TLS, JPEG |\n| 5 Session | Connection management | NetBIOS |\n| 4 Transport | End-to-end delivery | TCP, UDP |\n| 3 Network | Routing between networks | IP, ICMP, ARP |\n| 2 Data Link | Node-to-node on LAN | Ethernet, MAC |\n| 1 Physical | Bits on wire | Cables, signals |\n\n## TCP vs UDP — The Classic Question\n\n| TCP | UDP |\n|-----|-----|\n| Connection-oriented (3-way handshake) | Connectionless |\n| Reliable, ordered, error-checked | Best-effort, may drop |\n| Slower (overhead) | Faster |\n| HTTP, SSH, FTP | DNS, video streaming, gaming |\n\n## What Happens When You Type google.com\n\n1. DNS resolution (local cache → ISP DNS → root → TLD → authoritative)\n2. TCP handshake (SYN, SYN-ACK, ACK)\n3. TLS handshake if HTTPS\n4. HTTP request sent\n5. Server responds, connection stays alive (HTTP/1.1 keep-alive, HTTP/2 multiplexing)\n\n**This answer, given fluently, impresses every interviewer.**\n\n## HTTP Status Codes You Must Know\n\n- 200 OK, 201 Created, 204 No Content\n- 301 Moved Permanently, 302 Found (redirect)\n- 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found\n- 500 Internal Server Error, 503 Service Unavailable\n\n## Subnetting Quick Reference\n\n/24 = 256 addresses (254 usable)\n/25 = 128 addresses, /26 = 64, /27 = 32',
   'approved',
   NOW() - INTERVAL '3 months'),

  -- 7. Resume Tips
  (v_author,
   'Resume Writing for MCA Freshers — What Actually Gets Shortlisted',
   ARRAY['resume','career','placement','soft-skills'],
   E'## The 30-Second Test\n\nRecruiters spend 30 seconds on a first pass. Your resume must answer in that time:\n1. What has this person built?\n2. What technologies do they know?\n3. Do they have relevant experience?\n\n## Structure That Works\n\n```\nName | Email | LinkedIn | GitHub | Phone\n─────────────────────────────────────────\nEDUCATION\n  MCA — PSG Tech | 2024–2026 | CGPA: 8.4/10\n  B.Sc. CS — ... | 2021–2024 | 82%\n─────────────────────────────────────────\nSKILLS\n  Languages: Python, Java, JavaScript\n  Frameworks: React, Django, Spring Boot\n  Tools: Git, Docker, Postman, MySQL\n─────────────────────────────────────────\nPROJECTS (Most Important Section)\n  PSGMX — MCA Placement Companion [GitHub]\n  • Built Flutter mobile app for 250+ students\n  • Integrated Supabase real-time database with RLS policies\n  • Reduced manual admin work by 80% through automation\n─────────────────────────────────────────\nINTERNSHIPS (if any)\nCERTIFICATIONS\nACHIEVEMENTS\n```\n\n## Bullet Point Formula\n\n**Action verb + What you did + Result/Scale**\n\n❌ "Worked on backend development"\n✅ "Designed REST API serving 10K+ requests/day using Node.js + PostgreSQL"\n\n❌ "Helped in building the project"\n✅ "Implemented JWT authentication reducing unauthorized access incidents to zero"\n\n## What Gets Rejected Immediately\n\n- Objective statement ("Seeking a challenging role...")\n- Responsibilities instead of achievements\n- Skills listed without projects using them\n- Typos — use Grammarly\n- Photo on resume (for IT roles)\n- More than 1 page for freshers\n\n## The FYP Project Presentation Tip\n\nYour final year project is your biggest differentiator. Always prepare:\n1. What problem it solves and why it matters\n2. The technical stack and why you chose it\n3. Challenges you faced and how you solved them\n4. Metrics: users, performance, uptime, scale',
   'approved',
   NOW() - INTERVAL '2 months'),

  -- 8. Dynamic Programming
  (v_author,
   'Dynamic Programming — Recognize It, Template It, Solve It',
   ARRAY['dsa','dynamic-programming','coding-interview','hard'],
   E'## When Is It DP?\n\nDP applies when:\n1. The problem has **optimal substructure** — optimal answer uses optimal answers to subproblems\n2. There are **overlapping subproblems** — the same subproblem is solved multiple times\n\nRecognition signals:\n- "Maximum/minimum number of ..."\n- "Number of ways to ..."\n- "Is it possible to ..."\n\n## Top-Down vs Bottom-Up\n\n```python\n# Top-down (memoization) — intuitive, recursive\nfrom functools import lru_cache\n@lru_cache(maxsize=None)\ndef dp(i, remaining):\n    if base_case: return base_value\n    return max(choice1, choice2)\n\n# Bottom-up (tabulation) — space-efficient, iterative\ndp = [0] * (n + 1)\nfor i in range(1, n + 1):\n    dp[i] = max(dp[i-1], dp[i-2] + val[i])\n```\n\n## The Must-Know Problems\n\n| Problem | Recurrence |\n|---------|------------|\n| Fibonacci | dp[i] = dp[i-1] + dp[i-2] |\n| 0/1 Knapsack | dp[i][w] = max(dp[i-1][w], dp[i-1][w-wt]+val) |\n| Longest Common Subsequence | dp[i][j] = dp[i-1][j-1]+1 if match else max(dp[i-1][j], dp[i][j-1]) |\n| Coin Change | dp[i] = min(dp[i], dp[i-coin]+1) |\n| House Robber | dp[i] = max(dp[i-1], dp[i-2]+nums[i]) |\n\n## Interview Approach\n\n1. State: what does dp[i] represent? Be exact.\n2. Transition: how does dp[i] depend on earlier states?\n3. Base case: what is dp[0] or dp[0][0]?\n4. Answer: which cell is the final answer?\n\nSay all four out loud before coding. Most interviewers award partial credit for correct recurrence even if your code has a bug.',
   'approved',
   NOW() - INTERVAL '6 weeks'),

  -- 9. Communication in Interviews
  (v_author,
   'How to Communicate in Technical Interviews — The Skill No One Teaches',
   ARRAY['communication','interviews','soft-skills','career'],
   E'## The Communication Problem\n\nMost MCA students can solve the problem but lose the offer because they code in silence. Interviewers want to see your thinking process, not just your output.\n\n## The Talk-While-You-Think Framework\n\n### 1. Understand the Problem (2 minutes)\n"Let me make sure I understand. We have an array of integers and we need to find the maximum sum subarray. Can the array have negative numbers? What should we return if all numbers are negative — the least negative or zero?"\n\n**Why it works**: Shows you think about edge cases before you code.\n\n### 2. State Your Approach\n"I\'m thinking of a brute force approach first — O(n²) — check every subarray. But we can do better with Kadane\'s algorithm in O(n) by tracking the current maximum as we scan."\n\n**Why it works**: Shows structured thinking. Interviewers love the brute force → optimization arc.\n\n### 3. Code with Commentary\n"I\'m initializing current_sum and max_sum to the first element so I handle the all-negative case. At each step, I decide: should I extend the current subarray or start fresh?"\n\n### 4. Test with Examples\n"Let me trace through [-2, 1, -3, 4, -1, 2, 1, -5, 4]. After index 3, current_sum is 4..."\n\n## Phrases That Work\n\n- "One thing I want to verify before I code is..."\n- "I\'m going to start with a simpler approach and optimize"\n- "The edge case I\'m thinking about here is..."\n- "Does this approach match what you had in mind?"\n\n## The Silence Rule\n\nNever be silent for more than 30 seconds. If you\'re stuck, say it: "I\'m thinking about whether a hashmap helps here — give me a moment to work through the state I\'d store."',
   'approved',
   NOW() - INTERVAL '5 weeks'),

  -- 10. DBMS Transactions
  (v_author,
   'DBMS Transactions and ACID — A Practical Guide for Interviews',
   ARRAY['dbms','core-cs','transactions','theory'],
   E'## ACID Properties\n\n| Property | Meaning | Example |\n|----------|---------|----------|\n| **A**tomicity | All or nothing | Bank transfer: both debit and credit complete, or neither |\n| **C**onsistency | DB moves from one valid state to another | Account balance never goes negative |\n| **I**solation | Concurrent transactions don\'t see each other\'s intermediate state | Two users withdrawing simultaneously |\n| **D**urability | Committed changes survive crashes | Power cut after COMMIT — data not lost |\n\n## Isolation Levels — The Hierarchy\n\n```\nHigher isolation ← stricter, slower → Lower concurrency\n\nSERIALIZABLE  — No anomalies. Transactions appear sequential.\nREPEATABLE READ — Phantom reads possible\nREAD COMMITTED  — Non-repeatable reads possible (PostgreSQL default)\nREAD UNCOMMITTED — Dirty reads possible (avoid in production)\n```\n\n## Anomalies to Know\n\n- **Dirty Read**: read uncommitted data from another transaction\n- **Non-repeatable Read**: read same row twice, get different values\n- **Phantom Read**: range query returns different rows on second read\n\n## Indexing Questions\n\n"Why is your query slow?" is a common interview question.\n\n```sql\n-- Slow (no index, full table scan)\nSELECT * FROM orders WHERE customer_id = 42;\n\n-- After CREATE INDEX idx_orders_customer ON orders(customer_id);\n-- B-tree lookup: O(log n) instead of O(n)\n```\n\n**When NOT to index**:\n- Columns with very low cardinality (e.g., boolean, gender)\n- Tables that are written to far more than read\n- Small tables where full scan is faster',
   'approved',
   NOW() - INTERVAL '4 weeks'),

  -- 11. Aptitude Preparation
  (v_author,
   'Aptitude Preparation for MCA — The 12-Topic Plan That Covers 90% of Questions',
   ARRAY['aptitude','placement','quantitative','reasoning'],
   E'## Why Aptitude Matters More Than You Think\n\nFor service-based companies, aptitude is the first filter. 80% of students who can code get eliminated at the aptitude stage because they didn\'t prepare.\n\n## The 12 Topics (Ranked by Frequency)\n\n1. **Number System** — divisibility, HCF/LCM, remainders\n2. **Percentages** — profit/loss, discount, successive percentages\n3. **Ratios and Proportions** — mixture, alligation\n4. **Time, Speed, Distance** — relative speed, trains, boats\n5. **Work and Time** — men/days, pipes and cisterns\n6. **Permutations and Combinations** — arrangements, selections\n7. **Probability** — basic events, conditional probability\n8. **Data Interpretation** — bar charts, pie charts, tables\n9. **Logical Reasoning** — seating, blood relations, directions\n10. **Verbal Analogies** — word relationships\n11. **Syllogisms** — Venn diagram logic\n12. **Series Completion** — number and letter series\n\n## The 2-Week Sprint Plan\n\n**Week 1**: Topics 1–6. Solve 30 questions each.\n**Week 2**: Topics 7–12. Solve 20 questions each. Take 2 mock tests.\n\n## Resources That Worked for 23MX\n\n- IndiaBix.com — unlimited free practice, company-specific tests\n- RS Aggarwal "Quantitative Aptitude" — skip theory, just solve exercises\n- AMCAT mock tests — closest to actual company format\n- FACE Prep — good for TCS, Infosys patterns\n\n## The Speed Secret\n\nAptitude is not about knowing the formula — it\'s about recognizing the pattern instantly. The first 5 seconds of reading a problem should give you the method. This only comes from repeated practice.',
   'approved',
   NOW() - INTERVAL '3 weeks'),

  -- 12. Git workflow
  (v_author,
   'Git Workflow for MCA Projects — What Every Developer Must Know',
   ARRAY['git','tools','development','projects'],
   E'## Why Git Matters in Interviews\n\n"Walk me through your Git workflow" is a common technical screen question. A confident answer separates people who have used Git for real projects from those who just pushed to main.\n\n## The Commands You Use 95% of the Time\n\n```bash\n# Start working\ngit checkout -b feature/add-login    # new branch for every feature\n\n# Work cycle\ngit add -p                           # stage changes interactively\ngit commit -m "feat: add JWT authentication"\ngit push origin feature/add-login\n\n# Sync with main\ngit fetch origin\ngit rebase origin/main               # prefer rebase over merge for clean history\n\n# Fix last commit (before push only)\ngit commit --amend\n\n# Undo uncommitted changes\ngit restore <file>                   # discard working directory changes\ngit restore --staged <file>          # unstage a file\n\n# See what changed\ngit log --oneline --graph --all      # visual branch history\ngit diff HEAD~1 HEAD                 # diff since last commit\n```\n\n## Commit Message Convention\n\nUse Conventional Commits:\n- `feat:` new feature\n- `fix:` bug fix\n- `refactor:` code change without new feature\n- `docs:` documentation only\n- `test:` adding tests\n\nBad: "fixed stuff"  \nGood: "fix: resolve null pointer in user authentication flow"\n\n## The Branch Strategy for FYP Projects\n\n```\nmain          ← production/submission\n├── develop   ← integration branch\n│   ├── feature/auth\n│   ├── feature/dashboard\n│   └── fix/login-error\n```\n\n## What Impresses in an Interview\n\n- "We used feature branches and opened pull requests for peer review"\n- "We had CI that ran our tests before merging"\n- "I resolved a merge conflict by rebasing onto the latest main"',
   'approved',
   NOW() - INTERVAL '2 weeks'),

  -- 13. Graphs
  (v_author,
   'Graph Algorithms — BFS, DFS, and the Problems They Solve',
   ARRAY['dsa','graphs','bfs','dfs','coding-interview'],
   E'## The Graph Mindset\n\nBefore you can solve a graph problem, you must recognize it''s a graph problem. These disguises are common:\n- "Islands" → connected components\n- "Dependencies" → topological sort (DAG)\n- "Shortest path" → BFS (unweighted) or Dijkstra (weighted)\n- "Cycles" → DFS with coloring\n\n## BFS Template\n\n```python\nfrom collections import deque\n\ndef bfs(graph, start):\n    visited = {start}\n    queue = deque([start])\n    while queue:\n        node = queue.popleft()\n        for neighbor in graph[node]:\n            if neighbor not in visited:\n                visited.add(neighbor)\n                queue.append(neighbor)\n    return visited\n```\n\n**Use BFS when**: shortest path, minimum steps, level-order traversal.\n\n## DFS Template\n\n```python\ndef dfs(graph, node, visited=None):\n    if visited is None:\n        visited = set()\n    visited.add(node)\n    for neighbor in graph[node]:\n        if neighbor not in visited:\n            dfs(graph, neighbor, visited)\n    return visited\n```\n\n**Use DFS when**: cycle detection, topological sort, connected components, backtracking.\n\n## Problems by Pattern\n\n| Problem | Algorithm |\n|---------|-----------|\n| Number of Islands | DFS/BFS on grid |\n| Shortest Path in Binary Matrix | BFS |\n| Course Schedule | Topological Sort (Kahn\'s) |\n| Clone Graph | BFS + hash map |\n| Word Ladder | BFS + set |\n\n## Grid = Graph\n\nFor grid problems, neighbors are (up, down, left, right). Same BFS/DFS applies:\n```python\ndirections = [(0,1),(0,-1),(1,0),(-1,0)]\n```',
   'approved',
   NOW() - INTERVAL '10 days'),

  -- 14. FYP guidance
  (v_author,
   'FYP — How to Choose a Project That Actually Gets You Hired',
   ARRAY['fyp','projects','career','portfolio'],
   E'## The FYP Is Your Proof\n\nEvery student on every resume says "good problem-solving skills." Your FYP is the only thing that proves it with evidence.\n\n## Project Selection Criteria\n\nA good FYP ticks these boxes:\n1. **Solves a real problem** — not a tutorial clone\n2. **Uses technology relevant to jobs you want** — research company stacks\n3. **Has measurable outcomes** — X users, Y% improvement, Z API calls/day\n4. **Is deployable** — on the internet, not just localhost\n\n## Project Ideas That Actually Got Students Hired (From 23MX and 24MX)\n\n| Domain | Project | Stack |\n|--------|---------|-------|\n| Web | College admission management with AI counsellor | React + Node.js + MongoDB |\n| Mobile | Hostel food review + waste reduction tracker | Flutter + Supabase |\n| AI/ML | Resume screener with JD matching | Python + spaCy + FastAPI |\n| Data | Stock sentiment dashboard from Twitter | Pandas + Streamlit + Supabase |\n\n## The GitHub Profile Rule\n\nYour FYP repo must have:\n- ✅ Clear README with demo GIF/screenshot\n- ✅ Project architecture diagram\n- ✅ Setup instructions that actually work\n- ✅ Meaningful commit history (not 3 commits: "first", "second", "final")\n\n## The FYP Story Template for Interviews\n\n"I built [project name] that solves [problem]. The core technical challenge was [X]. We approached it by [Y]. The result was [Z measurable outcome]. The thing I\'d do differently is [honest reflection]."\n\nPractice this until it comes out in under 90 seconds.',
   'approved',
   NOW() - INTERVAL '8 days'),

  -- 15. Mock interviews
  (v_author,
   'Mock Interviews — The Only Way to Not Freeze on Interview Day',
   ARRAY['interviews','practice','career','soft-skills'],
   E'## Why You Freeze\n\nFreezing happens when your working memory is overloaded. You''re solving the problem AND managing nerves AND watching the interviewer''s face AND tracking time. The only fix is making the problem-solving so automatic that it doesn''t need full attention.\n\n## The Mock Interview Protocol\n\n### Setup\n- Use your laptop camera — simulate the real environment\n- Time yourself: 5 min understanding, 20 min coding, 5 min questions\n- Record it — watch it back. It''s uncomfortable but essential.\n\n### During the Mock\n1. Read the problem aloud\n2. State your brute force approach before touching keyboard\n3. Code out loud — narrate every decision\n4. Test with the given examples THEN an edge case\n5. Ask: "Is there anything you''d like me to optimize?"\n\n### After the Mock\nScore yourself on:\n- Did I understand the problem correctly? (1–5)\n- Was my approach before coding correct? (1–5)\n- Did my code run on the first example? (1–5)\n- Was my communication clear? (1–5)\n\n## Where to Find Mock Partners\n\n- Your batch squadmates in PSGMX\n- Pramp.com — free peer mock interviews\n- Interviewing.io — free async interview practice\n- Department WhatsApp group\n\n## The Feedback Loop That Works\n\nDo a mock → identify the weakest link (approach? coding? communication?) → practice that specific thing for a week → do another mock. Not random practice. Targeted practice.',
   'approved',
   NOW() - INTERVAL '5 days'),

  -- 16. Binary Search
  (v_author,
   'Binary Search — Beyond Simple Sorted Arrays',
   ARRAY['dsa','binary-search','algorithms','coding-interview'],
   E'## The Core Idea\n\nBinary search works on any **monotonic condition** — not just sorted arrays. The template: if a condition is false for all values below X and true for all values above X, binary search finds X.\n\n## The Bug-Free Template\n\n```python\ndef binary_search(arr, target):\n    left, right = 0, len(arr) - 1\n    while left <= right:\n        mid = left + (right - left) // 2  # avoids integer overflow\n        if arr[mid] == target:\n            return mid\n        elif arr[mid] < target:\n            left = mid + 1\n        else:\n            right = mid - 1\n    return -1  # not found\n```\n\n## The "Find First True" Template (For Complex Problems)\n\n```python\ndef find_first_true(condition, lo, hi):\n    # Finds smallest x in [lo, hi] where condition(x) is True\n    while lo < hi:\n        mid = (lo + hi) // 2\n        if condition(mid):\n            hi = mid       # keep looking left\n        else:\n            lo = mid + 1   # condition False, go right\n    return lo\n```\n\n## Non-Obvious Applications\n\n- **Koko Eating Bananas** — binary search on eating speed\n- **Find Minimum in Rotated Array** — binary search with pivot logic\n- **Median of Two Sorted Arrays** — binary search on partition position\n- **Capacity to Ship Packages** — binary search on capacity value\n\n## The Pattern Recognition Signal\n\n"What is the minimum/maximum value X such that [condition holds]?" → binary search on the answer space.',
   'approved',
   NOW() - INTERVAL '3 days')

  ON CONFLICT DO NOTHING;

END;
$$;
