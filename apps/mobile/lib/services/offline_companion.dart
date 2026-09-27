class OfflineCompanionContext {
  final String? firstName;
  final String? batchCode;
  final bool isSenior;

  const OfflineCompanionContext({
    this.firstName,
    this.batchCode,
    this.isSenior = false,
  });
}

/// Comprehensive, grounded guidance from your PSG MX AI Senior mentor.
/// Always responds warmly, intelligently, and authoritatively.
class OfflineCompanion {
  static String answer(
    String message, {
    OfflineCompanionContext context = const OfflineCompanionContext(),
  }) {
    final query = message.trim().toLowerCase();
    final name = context.firstName?.trim();
    final greeting = name != null && name.isNotEmpty ? 'Hey $name! ' : 'Hey there! ';
    final stageAdvice = context.isSenior
        ? 'As a senior in the placement season, every preparation block must translate directly into demonstrable interview evidence.'
        : 'Since you are building your core foundation, consistency and clear mental models beat cramming every time.';

    // DSA / Coding / LeetCode
    if (_hasAny(query, const [
      'dsa',
      'data structure',
      'algorithm',
      'leetcode',
      'coding',
      'array',
      'string',
      'tree',
      'graph',
      'dp',
      'dynamic programming',
      'pointer',
      'stack',
      'queue',
      'recursion',
      'backtracking',
      'binary search',
      'time complexity',
      'space complexity'
    ])) {
      return '''${greeting}$stageAdvice

Here is our proven PSG Tech MCA 5-step problem-solving framework for technical coding rounds:

1. **Clarify & State Invariants (2 mins)**
   - Don't rush to code. First ask: What are the input constraints ($N \\le 10^5$ implies $O(N \\log N)$ or $O(N)$)? Are there negatives, duplicates, or empty inputs?

2. **State the Naive Baseline First**
   - Explain the brute-force approach clearly ($O(N^2)$ or $O(2^N)$) to prove you understand the problem space before optimizing.

3. **Identify the Underlying Pattern**
   - Sliding Window (continuous subarrays/substrings)
   - Two Pointers (sorted arrays, palindrome checks, pair sums)
   - Monotonic Stack (next greater/smaller element)
   - Fast & Slow Pointers (cycle detection)
   - DFS / BFS (traversals, connected components, shortest path)
   - Dynamic Programming (overlapping subproblems with optimal substructure)

4. **Code with Clean Variable Names**
   - Write self-documenting code. Talk out loud about edge cases (null inputs, single elements, integer overflow).

5. **Dry Run on an Edge Case & Analyze Complexity**
   - Walk through a small test case before declaring done. Conclude with exact Big-O Time and Auxiliary Space complexity.

💡 *Pro Senior Tip:* Solve 2-3 LeetCode Mediums daily rather than 10 Easies. When you get stuck, look at the pattern name only, then spend another 15 minutes before checking the solution.''';
    }

    // Aptitude & Quant
    if (_hasAny(query, const [
      'aptitude',
      'quant',
      'reasoning',
      'math',
      'percentage',
      'profit',
      'loss',
      'ratio',
      'speed',
      'time and work',
      'permutation',
      'probability',
      'logical'
    ])) {
      return '''${greeting}Aptitude is the first gatekeeper round in 95% of on-campus placement drives. Here is your roadmap to clear it consistently:

⏱ **The 30-Minute Daily Aptitude Routine:**
- **First 8 Mins:** Formula recall & mental math drills (squares up to 30, cubes up to 20, fraction-to-percentage conversions like 1/6 = 16.66%, 1/7 = 14.28%).
- **Next 15 Mins:** Timed set of 10 questions under strict 90-seconds-per-question pressure.
- **Last 7 Mins:** Error autopsy. Classify mistakes into *Concept gap*, *Calculation slip*, or *Time panic*.

🎯 **High-Yield Placement Topics:**
1. **Percentages & Profit-Loss:** Margin multiplier method ($CP \\times 1.25 = SP$).
2. **Ratios & Proportions:** Allegations & mixtures weighted averages.
3. **Time, Speed & Distance:** Relative velocity (trains passing poles/platforms), boat & stream vectors.
4. **Time & Work:** Unit-work approach (LCM of individual days as total work units).
5. **Permutations, Combinations & Probability:** At-least-one complement rule ($1 - P(\\text{none})$).
6. **Logical Syllogisms & Blood Relations:** Venn diagrams and family tree mapping.

💡 *Strategy:* In the actual test, skip questions that don't click within 30 seconds. Accuracy comes first; speed follows repetition.''';
    }

    // Mock Interview / HR / Behavioral
    if (_hasAny(query, const [
      'mock interview',
      'interview',
      'hr round',
      'behavioral',
      'tell me about yourself',
      'strength',
      'weakness',
      'why hire you',
      'fitment'
    ])) {
      return '''${greeting}Technical ability gets you the interview; communication and structure get you the offer. Here is how to ace the interview rounds:

🌟 **1. "Tell Me About Yourself" (The 90-Second Formula)**
- **Present (30s):** Who you are at PSG Tech MCA, your primary tech stack (e.g. Flutter/Supabase, Full-Stack, Java/Spring, Python).
- **Past (30s):** Key project milestone, real problem you solved, and competitive programming/internship achievements.
- **Future (30s):** Why this specific company and role aligns with your career trajectory.

🎯 **2. Answering Behavioral Questions (STAR Method)**
- **Situation:** Set the college/team context briefly (1-2 sentences).
- **Task:** The specific challenge or conflict your team faced.
- **Action:** Exactly what **you** did (avoid saying just "we", highlight your contribution).
- **Result:** Measurable outcome (e.g., "reduced latency by 40%", "completed 2 days ahead of deadline") and the lesson learned.

💬 **3. Handling Technical Deadlocks in Interviews**
- When you don't know the exact syntax or algorithm:
  *"While I haven't implemented this exact variant in production, my approach would be to model this as a graph/hash problem because..."*
- Never remain silent for more than 20 seconds. Think aloud so the interviewer can guide your thought process.''';
    }

    // Resume / CV
    if (_hasAny(query, const ['resume', 'cv', 'profile', 'bullet point', 'ats'])) {
      return '''${greeting}Your resume has 15 seconds to make an impression with tech recruiters. Here is how to make yours stand out:

✨ **The High-Impact Bullet Formula (Google XYZ Formula):**
> *Accomplished [X], as measured by [Y], by doing [Z].*

❌ *Weak:* "Worked on an e-commerce website using React and Node.js."
✅ *Strong:* "Engineered a full-stack e-commerce portal handling 500+ SKU queries under 120ms by implementing Redis caching and indexed PostgreSQL queries."

📋 **Crucial Resume Checklist for MCA Students:**
1. **1-Page Strict:** Recruiters discard multi-page student resumes.
2. **Order of Sections:**
   - Education (PSG Tech MCA, CGPA, UG)
   - Technical Skills (Languages, Frameworks, Databases, Tools)
   - Projects (Top 2-3 with live URLs/GitHub links and measurable impact)
   - Experience / Internships
   - Certifications & Achievements (LeetCode rating, Hackathons)
3. **No Fluff:** Remove "hardworking", "punctual", or self-rating star bars (e.g., "Java: ★★★★☆").
4. **Be Ready to Defend:** Be prepared to write code or explain every single line, dependency, and architecture decision on your resume.''';
    }

    // DBMS / SQL
    if (_hasAny(query, const ['dbms', 'database', 'sql', 'normalization', 'acid', 'indexing', 'transaction'])) {
      return '''${greeting}DBMS is one of the highest-frequency topics in PSG placement technical rounds. Here are the core pillars to master:

1. **ACID Properties & Transactions:**
   - **Atomicity:** All-or-nothing (WAL / rollback logs).
   - **Consistency:** Preserves database invariants/constraints.
   - **Isolation:** Prevents dirty reads, non-repeatable reads, and phantom reads via isolation levels (Read Uncommitted, Read Committed, Repeatable Read, Serializable).
   - **Durability:** Committed transactions persist even through hardware crash.

2. **Indexing (B-Tree vs Hash):**
   - B-Tree indexes provide $O(\\log N)$ lookup, range queries, and ordering.
   - Clustered Index alters physical storage order (one per table, usually Primary Key); Non-clustered creates auxiliary pointer lookups.

3. **Normalization Essentials:**
   - **1NF:** Atomic values, unique column names, primary key.
   - **2NF:** 1NF + no partial dependency on a composite key.
   - **3NF:** 2NF + no transitive dependencies ($A \\to B, B \\to C$).
   - **BCNF:** Every determinant is a candidate key.

4. **Must-Practice SQL Queries:**
   - $N^{\\text{th}}$ highest salary using `DENSE_RANK()` or `LIMIT / OFFSET`.
   - Inner vs Left vs Full Outer vs Cross Joins.
   - `GROUP BY` with `HAVING` vs `WHERE`.
   - Subqueries vs Common Table Expressions (CTEs).''';
    }

    // Operating Systems
    if (_hasAny(query, const ['operating system', 'os', 'deadlock', 'process', 'thread', 'semaphore', 'mutex', 'paging', 'virtual memory'])) {
      return '''${greeting}Operating Systems questions test how your code interacts with machine hardware. Focus on these 4 pillars:

1. **Process vs Thread:**
   - A **Process** is an independent execution unit with its own address space, file descriptors, and heap.
   - A **Thread** is a lightweight execution unit inside a process sharing code, data, and OS resources, but having its own stack and program counter.

2. **Deadlocks (Coffman Conditions):**
   - **Mutual Exclusion:** Resources cannot be shared simultaneously.
   - **Hold & Wait:** Process holds at least one resource while requesting others.
   - **No Preemption:** Resources can only be released voluntarily.
   - **Circular Wait:** Closed chain of processes where each holds a resource needed by the next.
   - *Prevention:* Break circular wait by imposing resource ordering, or use Banker\'s Algorithm for avoidance.

3. **Synchronization (Mutex vs Semaphore):**
   - **Mutex:** Locking mechanism with ownership (only the locking thread can unlock).
   - **Counting Semaphore:** Signaling mechanism tracking available units of a resource ($P$ / wait and $V$ / signal).

4. **Memory Management & Virtual Memory:**
   - Paging splits virtual memory into fixed pages and physical memory into frames.
   - Page Fault occurs when a page is not present in RAM; resolved via page replacement policies (LRU, FIFO, Optimal).''';
    }

    // Computer Networks
    if (_hasAny(query, const ['network', 'networking', 'tcp', 'udp', 'http', 'https', 'dns', 'osi', 'ip'])) {
      return '''${greeting}In technical interviews, computer networks questions often revolve around real-world scenarios. Master these fundamentals:

🌐 **Classic Interview Question: "What happens when you type https://google.com and press Enter?"**
1. **URL Parsing & DNS Resolution:** Browser checks browser cache $\\to$ OS cache $\\to$ router cache $\\to$ ISP Recursive Resolver $\\to$ Root DNS $\\to$ TLD (.com) $\\to$ Authoritative DNS server to resolve IP.
2. **TCP 3-Way Handshake:** Client sends `SYN` $\\to$ Server replies `SYN-ACK` $\\to$ Client responds `ACK`.
3. **TLS/SSL Handshake:** Cipher negotiation, server certificate validation via CA public key, asymmetric exchange of session symmetric key.
4. **HTTP Request & Response:** Client sends HTTP `GET /`, server processes request and returns status code (e.g. 200 OK) with HTML/CSS/JS payload.
5. **Browser Rendering:** DOM tree + CSSOM tree $\\to$ Render tree $\\to$ Layout calculation $\\to$ Painting to screen.

⚡ **TCP vs UDP:**
- **TCP:** Connection-oriented, reliable, guaranteed order, flow control & congestion control. Used for HTTP, SSH, FTP, Email.
- **UDP:** Connectionless, lightweight, low-overhead, no packet-ordering guarantees. Used for DNS, VoIP, real-time gaming, video streaming.''';
    }

    // OOP / Object-Oriented
    if (_hasAny(query, const ['oop', 'oops', 'object oriented', 'polymorphism', 'inheritance', 'encapsulation', 'abstraction', 'solid'])) {
      return '''${greeting}Here is the clean, senior-level way to articulate the Four Pillars of OOP and SOLID principles:

🏛 **The Four Pillars:**
1. **Encapsulation:** Bundling data and methods into a single class and restricting direct external access using access modifiers (`private`, `protected`). Prevents unauthorized state mutation.
2. **Abstraction:** Hiding complex implementation details and exposing only the clean interface (e.g., using Abstract Classes or Interfaces).
3. **Inheritance:** Code reuse mechanism where a subclass derives attributes and behaviors from a superclass ($is\\text{-}a$ relationship). Favor composition ($has\\text{-}a$) over inheritance when possible.
4. **Polymorphism:**
   - *Compile-Time (Static):* Method overloading (same method name, different parameter signature).
   - *Run-Time (Dynamic):* Method overriding via virtual method dispatch tables.

📐 **SOLID Principles Quick Reference:**
- **S:** Single Responsibility Principle (A class should have only one reason to change).
- **O:** Open/Closed Principle (Open for extension, closed for modification).
- **L:** Liskov Substitution Principle (Subclasses must be substitutable for base classes).
- **I:** Interface Segregation Principle (Lean, targeted interfaces rather than fat general-purpose ones).
- **D:** Dependency Inversion Principle (Depend on abstractions, not concretions).''';
    }

    // Projects / FYP
    if (_hasAny(query, const ['project', 'fyp', 'final year', 'portfolio', 'github', 'architecture'])) {
      return '''${greeting}Interviewers care about your project architecture, engineering decisions, and failure recovery. Structure your project narrative like this:

🛠 **The 5-Step Project Breakdown:**
1. **The Problem Statement:** What real operational or business bottleneck does your application solve?
2. **Tech Stack Justification:** Why did you choose Flutter instead of React Native, or PostgreSQL instead of MongoDB? Give a technical reason (e.g., relation integrity, concurrency model, type safety).
3. **Architecture & State Management:** Explain your modular layering (UI $\\to$ State Provider/Bloc $\\to$ Service Layer $\\to$ Database/API).
4. **Hardest Technical Challenge You Overcame:**
   - Talk about a real bug: memory leaks, stale state, offline caching synchronization, authentication race condition, or high query latency.
   - Explain how you profiled, isolated, and fixed it.
5. **Metrics & Impact:** State measurable results (e.g., 99.9% uptime, under 200ms roundtrip latency, 100+ concurrent active sessions).

💡 *Advice:* Never list a project on your resume if you cannot explain every table in its database schema or cannot draw its architecture on a whiteboard.''';
    }

    // Daily Five & Streak
    if (_hasAny(query, const ['daily five', 'daily 5', 'streak', 'freeze'])) {
      return '''${greeting}The Daily Five is designed to be your daily technical thermometer, not an exam pressure point.

🔥 **How to Maximize Your Daily Five:**
1. **Consistency over Speed:** Spend 3 focused minutes every morning to complete your 5 questions.
2. **Learn from Explanations:** When you miss a question, read the verified explanation immediately to lock in the concept.
3. **Streak Multiplier:** Maintaining your Daily Five streak directly powers your personal Readiness Score and unlocks senior privileges.
4. **Streak Freezes:** You have 2 streak freezes each month. If college exams or emergencies arise, your streak is automatically protected.

Keep up the daily momentum—consistent effort compounds into placement success!''';
    }

    // Default intelligent response for any general question
    return '''${greeting}$stageAdvice

To tackle "${message.trim()}", let's break it down methodically into three clear steps:

1. **Deconstruct the Objective:**
   - Identify what the interviewer or technical problem is really evaluating: core algorithmic thinking, database performance, clean code architecture, or verbal communication.

2. **Apply Structured Thinking:**
   - If it's a **coding challenge**: Clarify constraints $\\to$ state brute-force $\\to$ optimize using a standard pattern $\\to$ implement with clean syntax $\\to$ analyze time and space complexity.
   - If it's a **conceptual or design topic**: Define the concept clearly $\\to$ compare key trade-offs $\\to$ cite a real-world example $\\to$ discuss edge cases and scaling.
   - If it's **placement strategy**: Focus on high-yield questions, consistent Daily Five routines, and mock interview practice.

3. **Immediate Action:**
   - What topic would you like to dive deeper into? You can ask about DSA patterns, Aptitude problem-solving, DBMS/SQL, Operating Systems, Networking, Resume refinement, or Mock Interview practice!''';
  }

  static bool _hasAny(String value, List<String> terms) =>
      terms.any(value.contains);
}
