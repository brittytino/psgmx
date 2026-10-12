-- ============================================================
-- PSGMX — 15_cleanup_and_seed_premium_articles.sql
-- Fix: Remove old fake mock data (23MX, 24MX, dummy companies) 
-- and insert premium, industry-standard interview patterns.
-- ============================================================

-- 1. Remove old mock/fake data containing 23MX, 24MX, or specific dummy companies
DELETE FROM public.knowledge_brain_articles
WHERE 
  title ILIKE '%23MX%' OR title ILIKE '%24MX%'
  OR title ILIKE '%Walmart Global Tech India%'
  OR title ILIKE '%CROSSBOW LABS%'
  OR title ILIKE '%Sandhata Technologies%'
  OR title ILIKE '%ACCENTURE BANGALORE%';

-- 2. Insert mature, industry-standard interview patterns and guides
DO $$
DECLARE
  v_author UUID;
BEGIN
  -- Get an admin or HOD as the default author, or leave NULL (system generated)
  SELECT id INTO v_author FROM public.users WHERE role_label IN ('Faculty', 'HOD') LIMIT 1;
  
  INSERT INTO public.knowledge_brain_articles (author_id, title, tags, content, company_name, approval_status, view_count, created_at)
  VALUES
  (
    v_author,
    'Amazon SDE-1 Interview Pattern & Behavioral (LP) Guide',
    ARRAY['interview-pattern', 'amazon', 'dsa', 'behavioral'],
    E'## Amazon Interview Structure\n\nAmazon heavily indexes on their 16 Leadership Principles (LPs). A typical SDE-1 loop consists of 4 rounds:\n\n### 1. Online Assessment (OA)\n- 2 LeetCode Medium/Hard problems (usually graph, sliding window, or priority queue).\n- Time: 90 mins.\n- **Pro-tip**: Optimize for passing all edge-case test cases. Time complexity matters.\n\n### 2. Technical Round 1 (Data Structures)\n- Focus: Arrays, Strings, Trees, and Hash Maps.\n- Expect 20 minutes of LP questions (e.g., "Tell me about a time you had a conflict with a teammate").\n- Followed by 1 DSA question. You must code a working solution.\n\n### 3. Technical Round 2 (Algorithms & Problem Solving)\n- Focus: Dynamic Programming, Graph Traversals (BFS/DFS).\n- Standard questions: Number of Islands, Word Ladder, LRU Cache.\n- 20 minutes of LP questions (e.g., "Tell me about a time you failed").\n\n### 4. Bar Raiser Round\n- The Bar Raiser ensures you are better than 50% of current Amazon employees.\n- Heavy focus on behavioral questions and system design basics (for SDE-1, they expect Object-Oriented Design like designing a Parking Lot).\n\n## How to Answer LP Questions\nAlways use the **STAR Method**:\n- **S**ituation: Set the context.\n- **T**ask: What was the goal?\n- **A**ction: What did *you* do specifically?\n- **R**esult: Quantifiable metrics (e.g., "Reduced latency by 20%").',
    'Amazon',
    'approved',
    420,
    NOW() - INTERVAL '2 days'
  ),
  (
    v_author,
    'Zoho Advanced Programming Round — Surviving the 3-Hour Coding Marathon',
    ARRAY['zoho', 'coding-interview', 'c', 'java', 'hard'],
    E'## Zoho\'s Unique Interview Process\n\nZoho does not follow the standard LeetCode pattern. They want to see if you can build software from scratch without external libraries.\n\n### Round 1: Aptitude & C Output Tracing\n- Mostly C-language pointers, nested macros, and tricky output questions.\n- Practice pointer arithmetic extensively.\n\n### Round 2: Advanced Programming (The 3-Hour Round)\n- You will be given a real-world scenario (e.g., "Build a Railway Reservation System", "Design a CLI Taxi Booking App", or "Implement an In-Memory File System").\n- **Rules**:\n  - No frameworks, no external libraries.\n  - Core Java, C++, or C only.\n  - Must use proper Object-Oriented principles (Encapsulation, Polymorphism).\n\n### Key Modules to Build During the Round\nIf you get "Railway Reservation System":\n1. `Passenger` Class (Name, Age, Berth Preference).\n2. `Ticket` Class (PNR, Status: RAC/WL/CNF).\n3. `BookingSystem` Class (Handles logic, seat availability, waitlist movement).\n\n### Common Mistakes to Avoid\n- Hardcoding values instead of making them configurable.\n- Not handling edge cases (What happens if a user cancels a WL ticket?).\n- Writing everything in a single `main()` function.\n\n**Preparation Strategy**: Spend 3 days building a CLI-based Library Management system and a CLI Snake Game from scratch in Java.',
    'Zoho',
    'approved',
    315,
    NOW() - INTERVAL '5 days'
  ),
  (
    v_author,
    'Morgan Stanley — System Design & Spring Boot Expectations',
    ARRAY['morgan-stanley', 'java', 'spring-boot', 'architecture'],
    E'## What Morgan Stanley Looks For\n\nInvestment banks look for candidates who understand concurrency, transaction safety, and backend fundamentals. Java is their primary stack.\n\n### 1. Core Java Fundamentals\nExpect deep-dive questions on:\n- **Multithreading**: `ExecutorService`, `ConcurrentHashMap`, Volatile vs Synchronized, Deadlocks.\n- **Garbage Collection**: How the JVM handles memory, G1GC, Memory Leaks.\n- **Collections Internal Working**: How does `HashMap` handle collisions internally in Java 8+? (Answer: converts LinkedList to Red-Black Tree when bucket size > 8).\n\n### 2. Spring Boot & Microservices\nIf you have Spring Boot on your resume, they will grill you:\n- Difference between `@Component`, `@Service`, and `@Repository`.\n- How Dependency Injection works under the hood (ApplicationContext).\n- Transaction management (`@Transactional` propagation levels).\n\n### 3. Database & SQL\n- ACID Properties in depth.\n- Writing complex queries involving `GROUP BY`, `HAVING`, and `LEFT JOIN`.\n- Indexing: Clustered vs Non-Clustered indexes. How B-Trees work.\n\n### Interview Tip\nWhen asked to solve a DSA problem, write thread-safe code if applicable. Mentioning time complexity is standard, but mentioning space complexity and thread-safety will set you apart for fintech roles.',
    'Morgan Stanley',
    'approved',
    280,
    NOW() - INTERVAL '1 week'
  ),
  (
    v_author,
    'TCS Digital / Ninja — Mastering the NQT Coding Section',
    ARRAY['tcs', 'nqt', 'coding-interview', 'arrays', 'strings'],
    E'## TCS NQT Overview\n\nThe TCS National Qualifier Test (NQT) is the gateway to TCS Ninja (base package) and TCS Digital (premium package). To get Digital, you MUST ace the coding section.\n\n### The Coding Section Format\n- Usually 2 questions to be solved in 45-60 minutes.\n- Question 1: Easy/Medium (Arrays, Strings, Basic Math).\n- Question 2: Medium/Hard (Dynamic Programming, Matrices, Hash Maps).\n\n### High-Frequency TCS Digital Patterns\n1. **Array Manipulation**: Rotating matrices, finding subarrays with given sum, prefix sums.\n2. **String Parsing**: Compressing strings, finding anagrams, validating IPv4 addresses.\n3. **Greedy Algorithms**: Activity selection, minimum coins.\n\n### Secret to Passing the Test Cases\n- TCS compilers are notorious for strict I/O formats. Do NOT print extra things like "Enter the number:" unless specified.\n- Read the input correctly. Often inputs are given as comma-separated values (`1,2,3,4`), which you must split and parse.\n- Handle boundary cases: What if the array is empty? What if N = 1?\n\n### Example Problem & Approach\n*Problem*: Given an array of integers, find the equilibrium index (sum of left elements == sum of right elements).\n*Optimal O(N) Approach*: \n1. Calculate total sum of array.\n2. Iterate through array keeping track of `left_sum`.\n3. `right_sum = total_sum - left_sum - current_element`. If `left_sum == right_sum`, return index.',
    'TCS',
    'approved',
    510,
    NOW() - INTERVAL '2 weeks'
  ),
  (
    v_author,
    'Google Summer Selection — Mastering Dynamic Programming',
    ARRAY['google', 'dsa', 'dynamic-programming', 'hard'],
    E'## The Google Standard\n\nGoogle interviews are almost exclusively data structures and algorithms. They test your ability to take a vague problem, clarify it, and optimize the solution.\n\n### Dynamic Programming (DP) is Crucial\nYou will likely face at least one DP problem. They rarely ask standard textbook DP problems (like Knapsack); instead, they disguise them.\n\n### 4-Step DP Framework for Google\n1. **Define the State**: What does `DP[i][j]` represent? (e.g., minimum cost to reach cell i,j).\n2. **Find the Recurrence Relation**: How do you calculate `DP[i][j]` from previous states? (e.g., `DP[i][j] = matrix[i][j] + min(DP[i-1][j], DP[i][j-1])`).\n3. **Identify Base Cases**: What are the starting values? (e.g., `DP[0][0] = matrix[0][0]`).\n4. **Optimize Space**: Do you need the whole 2D matrix, or just the previous row?\n\n### Common Google Themes\n- **Trees & Graphs**: Lowest Common Ancestor, Topological Sort, Dijkstra''s.\n- **Tries**: Autocomplete systems, word search games.\n- **Binary Search on Answer**: Finding the minimum capacity/time required to complete a task.\n\n### Communication\nGoogle evaluates your "Googliness" and communication. Think out loud. If you realize your approach is wrong halfway through, say: "Wait, I just realized this approach will fail for negative numbers because... Let me pivot to a different strategy."',
    'Google',
    'approved',
    605,
    NOW() - INTERVAL '1 month'
  );
END;
$$;
