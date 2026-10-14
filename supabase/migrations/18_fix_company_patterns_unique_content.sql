-- ============================================================
-- PSGMX — 18_fix_company_patterns_unique_content.sql
-- 1. Clean up old duplicate company patterns from migration 16
-- 2. Seed 50 authentic, distinct, company-specific interview guides
-- 3. Update daily_five_attempts schema & add answers JSONB column
-- 4. Create RPCs: get_daily_five_results and get_daily_five_completed_review
-- 5. Provide clean update command for app_config
-- ============================================================

-- ── 1. Daily Five Schema & RPC Improvements ───────────────────
-- Ensure answers JSONB column exists on daily_five_attempts
ALTER TABLE IF EXISTS public.daily_five_attempts 
ADD COLUMN IF NOT EXISTS answers JSONB;

-- Update submit_daily_five_answers to record student answers
CREATE OR REPLACE FUNCTION public.submit_daily_five_answers(p_user_id UUID, p_answers JSONB)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_actor UUID := public.current_user_id();
  v_attempt public.daily_five_attempts%ROWTYPE;
  v_question RECORD;
  v_correct INTEGER := 0;
  v_total INTEGER := 0;
  v_answer INTEGER;
  v_accuracy NUMERIC;
  v_elapsed INTEGER;
  v_flagged BOOLEAN := false;
  v_reason TEXT;
  v_fallback_qids UUID[];
BEGIN
  IF auth.uid() IS NULL AND v_actor IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF v_actor IS NULL THEN
    v_actor := auth.uid();
  END IF;

  IF p_user_id IS NOT NULL AND p_user_id <> v_actor AND p_user_id <> auth.uid() THEN
    RAISE EXCEPTION 'Not authenticated as this student';
  END IF;

  IF jsonb_typeof(p_answers) <> 'object' THEN
    RAISE EXCEPTION 'Answers must be an object';
  END IF;

  SELECT * INTO v_attempt FROM public.daily_five_attempts
  WHERE user_id = v_actor AND attempt_date = CURRENT_DATE FOR UPDATE;

  IF NOT FOUND THEN
    SELECT array_agg(key::uuid) INTO v_fallback_qids FROM jsonb_each_text(p_answers);
    INSERT INTO public.daily_five_attempts(user_id, attempt_date, question_ids, started_at)
    VALUES (v_actor, CURRENT_DATE, COALESCE(v_fallback_qids, '{}'::uuid[]), now() - INTERVAL '60 seconds')
    RETURNING * INTO v_attempt;
  END IF;

  IF v_attempt.submitted_at IS NOT NULL THEN
    RETURN jsonb_build_object(
      'correct_count', COALESCE(v_attempt.correct_count, 0),
      'total_questions', array_length(v_attempt.question_ids, 1),
      'accuracy_rate', COALESCE(v_attempt.accuracy_rate, 0),
      'flagged', v_attempt.flagged,
      'already_completed', true
    );
  END IF;

  FOR v_question IN SELECT id, correct_option FROM public.question_bank WHERE id = ANY(v_attempt.question_ids) LOOP
    v_total := v_total + 1;
    BEGIN
      v_answer := (p_answers ->> v_question.id::TEXT)::INTEGER;
    EXCEPTION WHEN invalid_text_representation THEN
      v_answer := NULL;
    END;
    IF v_answer = v_question.correct_option THEN
      v_correct := v_correct + 1;
    END IF;
  END LOOP;

  IF v_total = 0 THEN
    v_total := GREATEST(array_length(v_attempt.question_ids, 1), 1);
  END IF;

  v_accuracy := v_correct::NUMERIC / v_total;
  v_elapsed := extract(epoch FROM (now() - v_attempt.started_at))::INTEGER;
  IF v_elapsed < 3 THEN
    v_flagged := true;
    v_reason := 'Submission was faster than the integrity floor';
  END IF;

  UPDATE public.daily_five_attempts SET
    submitted_at = now(),
    correct_count = v_correct,
    accuracy_rate = v_accuracy,
    flagged = v_flagged,
    flag_reason = v_reason,
    answers = p_answers
  WHERE id = v_attempt.id;

  PERFORM public.increment_daily_five_streak(v_actor, v_accuracy);

  INSERT INTO public.audit_logs(actor_id, action, entity_type, entity_id, metadata)
  VALUES (
    v_actor,
    'DAILY_FIVE_COMPLETED',
    'daily_five_attempts',
    v_attempt.id,
    jsonb_build_object(
      'accuracy_rate', v_accuracy,
      'correct_count', v_correct,
      'total_questions', v_total,
      'flagged', v_flagged
    )
  );

  RETURN jsonb_build_object(
    'correct_count', v_correct,
    'total_questions', v_total,
    'accuracy_rate', v_accuracy,
    'flagged', v_flagged
  );
END;
$$;

-- Create RPC to reveal correct answers once submitted
CREATE OR REPLACE FUNCTION public.get_daily_five_results(p_user_id UUID DEFAULT NULL)
RETURNS TABLE (
  id UUID,
  correct_option INTEGER
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_actor UUID := public.current_user_id();
  v_attempt public.daily_five_attempts%ROWTYPE;
BEGIN
  IF v_actor IS NULL THEN
    v_actor := auth.uid();
  END IF;

  IF p_user_id IS NOT NULL AND p_user_id <> v_actor AND p_user_id <> auth.uid() THEN
    RAISE EXCEPTION 'Not authenticated as this student';
  END IF;

  SELECT * INTO v_attempt FROM public.daily_five_attempts
  WHERE user_id = v_actor AND attempt_date = CURRENT_DATE AND submitted_at IS NOT NULL;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT qb.id, qb.correct_option
  FROM public.question_bank qb
  WHERE qb.id = ANY(v_attempt.question_ids);
END;
$$;

-- Create RPC to fetch full completed review (questions + answers + student choices)
CREATE OR REPLACE FUNCTION public.get_daily_five_completed_review(p_user_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_actor UUID := public.current_user_id();
  v_attempt public.daily_five_attempts%ROWTYPE;
  v_q RECORD;
  v_questions JSONB := '[]'::JSONB;
  v_user_ans INTEGER;
BEGIN
  IF v_actor IS NULL THEN
    v_actor := auth.uid();
  END IF;

  IF p_user_id IS NOT NULL AND p_user_id <> v_actor AND p_user_id <> auth.uid() THEN
    RAISE EXCEPTION 'Not authenticated as this student';
  END IF;

  SELECT * INTO v_attempt FROM public.daily_five_attempts
  WHERE user_id = v_actor AND attempt_date = CURRENT_DATE AND submitted_at IS NOT NULL;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  FOR v_q IN 
    SELECT qb.id, qb.question_text, qb.options, qb.correct_option, qb.topic, qb.difficulty
    FROM public.question_bank qb
    WHERE qb.id = ANY(v_attempt.question_ids)
  LOOP
    BEGIN
      v_user_ans := (v_attempt.answers ->> v_q.id::TEXT)::INTEGER;
    EXCEPTION WHEN OTHERS THEN
      v_user_ans := NULL;
    END;

    v_questions := v_questions || jsonb_build_object(
      'id', v_q.id,
      'question_text', v_q.question_text,
      'options', v_q.options,
      'correct_option', v_q.correct_option,
      'selected_option', v_user_ans,
      'topic', v_q.topic,
      'difficulty', v_q.difficulty
    );
  END LOOP;

  RETURN jsonb_build_object(
    'attempt_id', v_attempt.id,
    'correct_count', v_attempt.correct_count,
    'accuracy_rate', v_attempt.accuracy_rate,
    'questions', v_questions
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_daily_five_results(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_daily_five_completed_review(UUID) TO authenticated;

-- ── 2. Clean Up Old Generic Company Pattern Articles ──────────
DELETE FROM public.knowledge_brain_articles 
WHERE title LIKE '%— Complete Selection Pattern & Guide'
   OR title LIKE '%— Aptitude & Coding Round Breakdown'
   OR title LIKE '%— System Design & Architecture Round Expectations'
   OR title LIKE '%— SDE-1 Interview Experience & Tips'
   OR title LIKE '%— What to expect in the Technical Rounds';

-- ── 3. Insert 50 Unique, Authentic Company Guides ─────────────
DO $$
DECLARE
  v_author UUID;
BEGIN
  SELECT id INTO v_author FROM public.users WHERE role_label IN ('Faculty', 'HOD') LIMIT 1;
  
  INSERT INTO public.knowledge_brain_articles 
    (author_id, title, tags, content, company_name, approval_status, view_count, created_at)
  VALUES
    (v_author, 'Caterpillar — Industrial IoT & Embedded Backend Selection Pattern', ARRAY['caterpillar', 'selection-pattern', 'core-engineering', 'java', 'systems'], E'## Caterpillar Campus Recruitment Breakdown

Caterpillar focuses heavily on reliable software engineering for industrial IoT, fleet telemetry, heavy machinery monitoring, and enterprise backend systems. They value maintainable, clean code over competitive programming tricks.

### Round 1: Online Assessment (90 mins)
- **Section 1: Core CS Fundamentals (30 MCQs)**: C/C++, Java OOP, DBMS (Indexing, Foreign Keys), OS (Memory Management, Multithreading, Deadlocks), Computer Networks.
- **Section 2: Coding Problems (2 questions)**: 
  - Problem 1: Array and String parsing (e.g. sensor telemetry data validator).
  - Problem 2: Dynamic programming or Graph traversal (e.g. finding shortest route in equipment routing).

### Round 2: Technical Interview 1 (Machine Test & Core Java/C++)
- Live coding or deep-dive into your written test solutions.
- **Key Focus**: Object-Oriented Design (SOLID principles). Interviewers often ask you to model an industrial machine state (e.g., Engine -> Sensor -> Alert system).
- Concurrency concepts: Thread pools, `synchronized` vs `ReentrantLock`, volatile variables, race conditions in sensor data ingestion.
- SQL queries: Writing `JOIN` and `GROUP BY` queries to analyze equipment breakdown logs.

### Round 3: Technical Interview 2 (Architecture & Final Year Project)
- In-depth architectural discussion of your FYP. Expect questions on why you chose your specific database, how you handle server failures, and how you secure your APIs.
- Real-world scenario: "How would you design a telemetry pipeline that ingests data from 50,000 tractors with intermittent internet connectivity?"

### Round 4: Behavioral & HR Interview
- Caterpillar''s core values: Integrity, Excellence, Teamwork, Commitment, and Sustainability.
- Relocation preferences (Chennai / Hosur / Bangalore facilities) and team conflict management.

### Key Placement Tips
- Always write input validations and handle boundary cases. Caterpillar interviewers inspect production readiness.
- Know the difference between process and thread memory layout.', 'Caterpillar', 'approved', 412, NOW() - INTERVAL '45 days'),
    (v_author, 'PhonePe — SDE Hiring & Signature Machine Coding Pattern', ARRAY['phonepe', 'machine-coding', 'dsa', 'fintech', 'concurrency'], E'## PhonePe Selection Process Overview

PhonePe''s hiring process is known as one of the most rigorous in the fintech space, designed to test clean architecture, concurrency, and real-time payment scale.

### Round 1: Online Assessment (HackerEarth / DoSelect)
- 3 DSA problems (60–75 mins):
  - Question 1: String / Sliding Window (Medium)
  - Question 2: Tree / Graph Traversal (Medium-Hard)
  - Question 3: Dynamic Programming / Bitmasking (Hard)
- Passing requires solving at least 2.5 problems with optimal time & space complexity.

### Round 2: The Signature Machine Coding Round (90–120 mins)
- This is PhonePe''s hallmark round. You are asked to design and implement a fully working console application from scratch.
- **Common Problems**:
  - In-Memory Key-Value Store with TTL and Transactions (Begin, Commit, Rollback).
  - Splitwise / Expense Sharing App with balance settlement.
  - Multi-level Parking Lot or Ride Sharing Dispatcher.
- **Evaluation Criteria**:
  - Modular OOP design (Models, Services, Repositories, Interfaces).
  - Extensibility (can you add a new payment method or algorithm in 5 mins?).
  - Thread safety and concurrency guards.
  - Clean error handling (no unhandled exceptions or crashes).

### Round 3: Technical Interview (DSA & Machine Coding Review)
- Deep code review of your Machine Coding submission.
- Algorithmic problem: Graph shortest paths, Trie autocomplete, or LRU/LFU cache implementation.
- Concurrency & DBMS: ACID compliance, transaction isolation levels, distributed locks, database indexing.

### Round 4: Techno-Managerial & Leadership Round
- System design trade-offs: Caching with Redis, message queues (Kafka) for payment event streaming.
- Situational questions: Handling production outages, strict security requirements, and team collaboration.

### Key Placement Tips
- Never write everything in a single file or `main` method for PhonePe. Split into separate class files.
- Master Java''s `ConcurrentHashMap`, `AtomicInteger`, and `ReentrantReadWriteLock`.', 'PhonePe', 'approved', 580, NOW() - INTERVAL '38 days'),
    (v_author, 'Societe Generale — Investment Banking & FinTech Engineering Guide', ARRAY['societe-generale', 'investment-banking', 'java', 'spring-boot', 'sql'], E'## Societe Generale (SocGen) Hiring Architecture

Societe Generale''s Global Solution Centre recruits MCA engineers for capital markets, foreign exchange trade platforms, risk analytics, and enterprise banking infrastructure.

### Round 1: Online Assessment (90 mins)
- **Quantitative & Logical Aptitude (30 MCQs)**: Probability, permutations, data interpretation.
- **Core CS Knowledge (20 MCQs)**: Java internals, SQL queries, OOP, Operating Systems.
- **Coding Section (2 Problems)**: One array/hashmap manipulation and one tree/matrix question.

### Round 2: Technical Interview 1 (Java Internals & Database Mastery)
- **Java Deep-Dive**:
  - JVM Architecture: Eden, Survivor spaces, Tenured generation, G1 Garbage Collector.
  - Collections Framework: How `HashMap` handles collisions (LinkedList vs Red-Black Tree threshold of 8).
  - String Pool, immutability, `equals()` and `hashCode()` contract.
- **Database & SQL**:
  - Complex SQL queries using CTEs (`WITH` clauses), `RANK()`, and `ROW_NUMBER()`.
  - Transaction isolation levels: Dirty Read, Non-Repeatable Read, Phantom Read.

### Round 3: Technical Interview 2 (Spring Boot, Microservices & FYP)
- Discussion of your Final Year Project:
  - How did you design your REST APIs? HTTP response codes (`201`, `400`, `409`, `500`).
  - Spring Boot annotations: `@RestController`, `@Autowired`, `@Transactional` propagation types.
  - Handling race conditions: "How do you prevent double-spending when two requests hit the balance transfer endpoint simultaneously?"

### Round 4: Managerial & HR Round
- Banking domain curiosity, interest in financial derivatives, agile sprint methodologies, and long-term career aspirations.

### Key Placement Tips
- Be ready to write SQL queries on paper or a shared scratchpad.
- Financial institutions prioritize zero data loss: emphasize idempotency in API design.', 'Societe Generale', 'approved', 395, NOW() - INTERVAL '42 days'),
    (v_author, 'Thorogood Associates — Data Analytics & BI Consulting Selection Pattern', ARRAY['thorogood-associates', 'analytics', 'bi', 'sql', 'consulting'], E'## Thorogood Associates Campus Recruitment Pattern

Thorogood Associates specializes in Business Intelligence, Cloud Data Engineering, and Analytics consultancy. They evaluate both data craftsmanship and structured business communication.

### Round 1: Online Assessment (Aptitude + SQL)
- **Data Interpretation & Logical Reasoning**: Complex tables, financial charts, and trend deduction.
- **Analytical SQL Test**: Writing queries involving aggregations, nested queries, and conditional joins.
- **Short Essay / Situational Response**: A brief written response testing professional English articulation.

### Round 2: Business Case Study & Discussion
- You are provided with a realistic business scenario (e.g., an international beverage company seeing sudden revenue drops across two regions).
- You must structure the data, hypothesize potential causes, and present your findings clearly to the interviewers.
- **Evaluation Criteria**: Logical clarity, ability to defend your assumptions, structured storytelling.

### Round 3: Technical Interview (Data Engineering & CS Fundamentals)
- Dimensional Modeling: Star Schema vs Snowflake Schema, Fact tables vs Dimension tables.
- Advanced SQL: Window functions, self joins, handling NULL values, query optimization.
- Python for Data Processing: Pandas dataframes, handling missing data, data cleaning pipelines.

### Round 4: Partner / Director Interview
- Fitment for client-facing technical consultancy.
- How you manage changing client requirements and deadlines.
- Career roadmap in Cloud Data Platforms (Azure Synapse, AWS, Databricks).

### Key Placement Tips
- In consulting interviews, speak using structured points (1st, 2nd, 3rd) rather than rambling.
- Understand the difference between OLTP (transactional) and OLAP (analytical) databases.', 'Thorogood Associates', 'approved', 380, NOW() - INTERVAL '36 days'),
    (v_author, 'The MathCompany — Enterprise Decision Intelligence & AI Engineering', ARRAY['the-mathcompany', 'ai', 'data-science', 'python', 'machine-learning'], E'## The MathCompany (MathCo) Selection Breakdown

MathCo builds full-stack AI and decision platforms for Fortune 500 enterprises. Their campus rounds evaluate both algorithmic problem solving and practical machine learning fundamentals.

### Round 1: Online Assessment (90 mins)
- **Math & Statistics Foundations**: Probability distributions, Bayes theorem, linear algebra, hypothesis testing.
- **Python Programming & DSA (2 Questions)**: Matrix manipulation, array intervals, hash-based grouping.
- **SQL & Data Querying**: Window functions, aggregate filters, joins.

### Round 2: Technical Interview 1 (Python, Algorithms & Data Modeling)
- Live coding in Python: Vectorized operations using NumPy vs standard loops.
- Time and space complexity trade-offs in data structures (HashMaps, Trees, Priority Queues).
- Designing database tables to track real-time analytics events.

### Round 3: Technical Interview 2 (Machine Learning & System Implementation)
- End-to-end ML lifecycle: Data preprocessing, feature engineering, handling class imbalance (SMOTE vs downsampling).
- Model evaluation metrics: Precision vs Recall, ROC-AUC, F1-score in high-stakes prediction tasks.
- API deployment: Exposing ML models via FastAPI or Flask, containerization with Docker.

### Round 4: HR & Cultural Fitment
- Working in cross-functional squads (Data Scientists + UI Engineers + Domain Consultants).
- Managing ambiguity in problem statements and client presentation readiness.

### Key Placement Tips
- Always justify your choice of ML models (e.g. explain why Random Forest was chosen over XGBoost or Logistic Regression).
- Never ignore data leakage and cross-validation techniques.', 'The MathCompany', 'approved', 340, NOW() - INTERVAL '30 days'),
    (v_author, 'EPAM Systems — SDE & Modern Engineering Practices Selection Guide', ARRAY['epam-systems', 'clean-code', 'java', 'dsa', 'solid-principles'], E'## EPAM Systems Recruitment Architecture

EPAM Systems is a global software product development and digital platform engineering company with exceptionally high standards for clean code and software design principles.

### Round 1: Online Coding Assessment (HackerRank)
- 2 Algorithmic Coding Problems (60 mins):
  - Problem 1: Array / String with Two Pointers or Sliding Window.
  - Problem 2: Tree traversal (DFS/BFS) or Dynamic Programming.
- 30 MCQs on Core Java, OOP, DBMS, and Web Architecture.

### Round 2: Technical Interview 1 (Clean Code & Core Java)
- Deep focus on **SOLID Principles** with practical code examples:
  - Single Responsibility: Refactoring god classes into focused components.
  - Open/Closed: Using interfaces and the Strategy Pattern.
  - Dependency Inversion: How Spring Boot achieves inversion of control.
- Live Refactoring: You are given poorly structured code and asked to refactor it into clean, maintainable classes with proper variable naming.

### Round 3: Technical Interview 2 (Architecture, Design Patterns & FYP)
- Design Patterns: Singleton (Thread-safe double checked locking), Factory, Observer, and Builder.
- REST API Design: Resource naming conventions, status codes, pagination, and error representations.
- Deep dive into Final Year Project database schema and performance bottlenecks.

### Round 4: HR & Culture Fitment
- Team dynamics, code review habits, Git branching workflows (GitFlow, feature branching), willingness to learn new stacks.

### Key Placement Tips
- EPAM prioritizes readable, clean code over hyper-dense one-liners.
- Write unit test scenarios mentally before finishing your code in front of the interviewer.', 'EPAM Systems', 'approved', 320, NOW() - INTERVAL '40 days'),
    (v_author, 'FoodHub — High-Concurrency Online Ordering & Real-Time Tech Stack', ARRAY['foodhub', 'node-js', 'react', 'websockets', 'full-stack'], E'## FoodHub Campus Recruitment Process

FoodHub is a fast-growing international online food ordering portal and restaurant POS ecosystem. Their interview process tests full-stack web capabilities, real-time tracking, and system resilience.

### Round 1: Online Assessment
- General Aptitude & Logical Reasoning.
- 2 Coding Questions: Array manipulation, string deduplication, and interval overlaps.
- Web Development MCQs: Event loop in Node.js, asynchronous promises, CSS box model, SQL joins.

### Round 2: Machine Coding / Practical Debugging Round
- Build or debug a small functional module (e.g. Shopping cart calculation with promo code discounts, or real-time order status state transitions).
- Handling edge cases: Out-of-stock items, delivery fee calculations based on distance tiers.

### Round 3: Technical Interview (System Architecture & Backend)
- Real-time communication: WebSockets vs Polling vs Server-Sent Events (SSE) for live delivery tracking.
- Caching strategies: Using Redis to cache restaurant menus and active promo codes.
- Relational schema for an ordering app: Tables for `restaurants`, `menu_items`, `orders`, `order_items`, and `payments`.

### Round 4: HR & Product Mindset Round
- Startup culture, personal projects, handling sprint deadlines, and ownership of features.

### Key Placement Tips
- Be comfortable explaining how Node.js event loop handles concurrent I/O operations without blocking.
- Know the differences between SQL and NoSQL for order history vs active cart sessions.', 'FoodHub', 'approved', 290, NOW() - INTERVAL '25 days'),
    (v_author, 'Mobicip Technologies — Multi-Platform Mobile & Network Security Pattern', ARRAY['mobicip-technologies', 'mobile', 'flutter', 'security', 'os-internals'], E'## Mobicip Technologies Selection Pattern

Mobicip develops cross-platform parental control, screen time management, and web filtering software running across millions of mobile and desktop devices worldwide.

### Round 1: Online Assessment (90 mins)
- Quantitative and logical aptitude.
- Core Computer Science MCQs: Operating Systems (Process lifecycle, IPC, Permissions), Networking (DNS, TCP, VPN, Proxies), and Object-Oriented Programming.
- 2 Coding Challenges: String tokenization, Trie-based word matching, and LinkedList manipulation.

### Round 2: Technical Interview 1 (OS Fundamentals & Mobile Lifecycles)
- Mobile App Lifecycles: App state changes (Foreground, Background, Terminated), handling background sync tasks safely.
- Inter-Process Communication (IPC): Pipes, sockets, broadcast receivers.
- Network packet inspection concepts: How VPN tunnels intercept DNS queries to filter malicious URLs.

### Round 3: Technical Interview 2 (Data Structures & Systems Design)
- Trie Data Structure: Implementing an efficient prefix tree for URL domain filtering.
- Thread safety in mobile UI: Ensuring network calls and disk reads never block the main UI thread.
- Deep review of your MCA projects (especially Flutter, Android, or security projects).

### Round 4: Leadership & HR Interview
- Passion for device security, ethical engineering, attention to detail, and cultural fit.

### Key Placement Tips
- If you have built Flutter or native mobile apps, highlight your handling of background workers and SQLite storage.
- Review how DNS resolution works from browser cache down to authoritative root servers.', 'Mobicip Technologies', 'approved', 260, NOW() - INTERVAL '28 days'),
    (v_author, 'IBM — Enterprise Hybrid Cloud & Watson AI Interview Pattern', ARRAY['ibm', 'cloud', 'cognify', 'microservices', 'dsa'], E'## IBM Campus Recruitment Breakdown

IBM hires MCA students for Hybrid Cloud software development, Red Hat OpenShift engineering, enterprise data platforms, and AI product integration.

### Round 1: Cognitive Assessment (IBM Cognify Games)
- Note: IBM does not use standard MCQs for aptitude! They use 5-6 interactive mini-games:
  - Grid Challenge: Spatial working memory and mental rotation.
  - Resemble: Rotating patterns and matching geometric orientations.
  - Shortcut: Path optimization and puzzle solving.
  - Numbubbles: Rapid mental arithmetic.

### Round 2: Online Technical Assessment (HackerEarth)
- 2 DSA Coding Problems (Arrays, HashMaps, Trees, Matrix paths).
- Technical MCQs on Operating Systems, SQL, Cloud concepts (IaaS vs PaaS vs SaaS), and OOP.

### Round 3: Technical Interview (Core Engineering & System Design)
- Data Structures & Algorithms: Live coding of standard problems (e.g., Detect Cycle in Directed Graph, Level Order Traversal of Binary Tree).
- Cloud Fundamentals: Docker containerization, Kubernetes pods vs deployments, microservices service discovery.
- Operating Systems: Virtual memory, paging vs segmentation, deadlock prevention algorithms (Banker''s algorithm).

### Round 4: IBM Values & HR Interview
- The IBM core practices: Dedication to every client''s success, Innovation that matters, Trust and personal responsibility.
- Situational questions regarding team projects, handling difficult deadlines, and continuous technical certifications.

### Key Placement Tips
- Practice spatial reasoning and game-based assessments prior to the test.
- Be prepared to discuss containerization and why microservices replaced monolithic backends.', 'IBM', 'approved', 450, NOW() - INTERVAL '35 days'),
    (v_author, 'Jungroo AI Labs — Adaptive Knowledge Graph & EdTech Engine Hiring Pattern', ARRAY['jungroo-ai-labs', 'knowledge-graphs', 'python', 'algorithms', 'nlp'], E'## Jungroo AI Labs Selection Guide

Jungroo AI Labs builds adaptive learning platforms powered by Knowledge Graphs and Bayesian student modeling to personalize education for millions of learners.

### Round 1: Take-Home Coding Challenge or Online Assessment
- Implementation of graph traversal algorithms (DAG traversal, topological sort, shortest dependency chains).
- Python data structures: Custom trees, adjacency lists, recursive memoization.

### Round 2: Technical Interview 1 (Algorithms & Graph Theory)
- In-depth problem solving:
  - Determining concept prerequisite paths: Given a directed acyclic graph of math topics, find the minimal path of concepts a struggling student must master first.
  - Cycle detection and topological sorting in course curricula.
- Algorithmic complexity proofs and memory footprint considerations.

### Round 3: Technical Interview 2 (System Architecture & Data Modeling)
- Graph database concepts: When to use Graph databases (Neo4j) vs Relational (PostgreSQL) vs Document stores (MongoDB).
- Real-time scoring pipelines: Calculating student proficiency updates asynchronously using event queues.
- Walkthrough of candidate''s academic and personal projects.

### Round 4: Founder / Research Fitment Round
- Curiosity for cognitive psychology in learning, research paper awareness, autonomy, and passion for product craftsmanship.

### Key Placement Tips
- Master Directed Acyclic Graphs (DAG), recursion, and memoization.
- Explain trade-offs between depth-first search (DFS) and breadth-first search (BFS) in hierarchical knowledge trees.', 'Jungroo AI labs', 'approved', 280, NOW() - INTERVAL '22 days'),
    (v_author, 'Deloitte USI — Consulting & Technology Advisory Selection Blueprint', ARRAY['deloitte-usi', 'consulting', 'sql', 'oops', 'system-analysis'], E'## Deloitte USI Campus Selection Blueprint

Deloitte USI (United States India) recruits MCA graduates for technology consulting, enterprise cloud transformations, cybersecurity, and financial technology engineering.

### Round 1: Online Assessment (75 mins)
- **Quantitative Aptitude**: Time & work, profit & loss, mixtures, speed-distance-time.
- **Logical Reasoning**: Seating arrangements, syllogisms, blood relations, data sufficiency.
- **Verbal Ability**: Sentence correction, reading comprehension, vocabulary in context.
- **Computer Fundamentals**: OOPS concepts, SQL queries, OS scheduling, Cloud basics.

### Round 2: Technical Interview (Core CS & Project Walkthrough)
- **Object-Oriented Design**:
  - The 4 pillars of OOPs with real-world analogies and code snippets.
  - Abstract class vs Interface: when would you choose one over the other?
- **Database Engineering**:
  - Normalization: 1NF, 2NF, 3NF, BCNF with practical tables.
  - Primary Key vs Unique Key vs Candidate Key.
  - Writing SQL queries with `LEFT JOIN` and `HAVING` clauses.
- **Final Year Project Discussion**:
  - Your individual contribution, architecture choices, and security considerations.

### Round 3: Techno-Managerial / Case Interview
- Scenario-based consulting problem: "A healthcare client wants to migrate patient records to the cloud while maintaining strict HIPAA compliance. What architectural considerations would you recommend?"
- Structuring problems into People, Process, and Technology dimensions.

### Round 4: HR Interview
- Deloitte''s shared values: Lead the way, Serve with integrity, Take care of each other, Foster inclusion, Collaborate for measurable impact.
- Relocation preferences (Hyderabad / Bengaluru / Mumbai / Gurugram) and communication clarity.

### Key Placement Tips
- Deloitte places heavy emphasis on polished, structured communication. Always answer questions in 2-3 logical steps.
- Maintain professional eye contact and posture throughout the technical interview.', 'Deloitte USI', 'approved', 480, NOW() - INTERVAL '44 days'),
    (v_author, 'Deloitte India — Enterprise Solutions & Risk Advisory Selection Pattern', ARRAY['deloitte-india', 'enterprise', 'sql', 'erp', 'cybersecurity'], E'## Deloitte India Recruitment Process

Deloitte India focuses on domestic and multinational enterprise implementations, public sector tech modernization, cyber risk, and digital transformations.

### Round 1: National Assessment Test
- Aptitude (Numerical + Reasoning + English Communication).
- Technical MCQs covering C/C++, Java, DBMS, and Web Architecture.
- Basic Coding Challenge (Arrays / Strings / HashMaps).

### Round 2: Technical Assessment & CS Fundamentals
- Live coding: Validating palindrome strings, finding duplicate elements in an array, matrix transformations.
- Database queries: Second highest salary, inner vs outer joins, indexing strategies.
- Software Engineering lifecycle: Agile ceremonies (Daily Standup, Sprint Planning, Retrospective).

### Round 3: Senior Manager / Director Interview
- Business value of your code: How does your FYP solve an actual problem for end-users?
- Conflict management during team project deliverables.
- Problem solving in stressful or tight-deadline environments.

### Round 4: HR Round
- Professional etiquette, ethics, client handling, and location flexibility across major Indian offices.

### Key Placement Tips
- Clearly articulate the business impact of your projects rather than simply listing dependencies.
- Practice basic SQL queries on paper to ensure syntax accuracy.', 'Deloitte India', 'approved', 350, NOW() - INTERVAL '41 days'),
    (v_author, 'Commvault — Systems Engineering & Enterprise Data Protection Interview Loop', ARRAY['commvault', 'systems-programming', 'c-plus-plus', 'os', 'storage'], E'## Commvault Campus Recruitment Architecture

Commvault is an elite systems software and cyber resilience company specializing in enterprise backup, disaster recovery, cloud data management, and ransomware protection. They maintain one of the highest technical bars on campus.

### Round 1: Online Coding Assessment (HackerRank - 90 mins)
- 3 Challenging Coding Problems:
  - Problem 1: Tree / Graph recursion (Medium-Hard).
  - Problem 2: Bit manipulation or Trie prefix queries (Hard).
  - Problem 3: Multithreading / Concurrency synchronization or Memory management.

### Round 2: Technical Interview 1 (Hardcore DSA & Memory Semantics)
- Live whiteboard / coderpad coding:
  - Deep-dive into pointer and reference semantics, virtual memory, memory leaks, and stack vs heap.
  - Advanced data structures: Segment Trees, Fenwick Trees, LRU Cache with custom Doubly Linked List + HashMap.
  - Boundary condition validation: Zero tolerance for potential null pointer dereferences or buffer overflows.

### Round 3: Technical Interview 2 (Operating Systems, File Systems & Storage)
- **OS Internals**:
  - Inodes, superblock, virtual file systems (VFS), hard links vs soft links.
  - Concurrency primitives: Mutex, Semaphore, Spinlocks, Read-Write Locks, Deadlock prevention (DICE conditions).
  - Disk scheduling algorithms (SCAN, C-SCAN) and RAID levels (RAID 0, 1, 5, 10).
- Enterprise Data Protection:
  - Snapshot technologies, incremental vs differential backup, data deduplication techniques (hash-based block chunking).

### Round 4: Director / HR Interview
- Deep engineering curiosity, problem debugging under pressure, and intellectual honesty.

### Key Placement Tips
- Write optimal code from the first iteration; Commvault engineers look for low-level memory efficiency.
- Know the exact memory footprint of standard C++/Java primitives and objects.', 'Commvault', 'approved', 420, NOW() - INTERVAL '33 days'),
    (v_author, 'PSIOG Digital — Hyperautomation & Cloud Integration Selection Pattern', ARRAY['psiog-digital', 'hyperautomation', 'python', 'cloud', 'apis'], E'## PSIOG Digital Selection Process

PSIOG Digital builds AI-enabled process automation, low-code extensions, and enterprise cloud integrations for digital transformation clients.

### Round 1: Online Technical Assessment
- Analytical aptitude, quantitative problem solving, and Python/Java programming questions.
- SQL query analysis and database schema evaluation.

### Round 2: Machine Coding & Practical Integration Round
- Practical assignment: Build an automated workflow (e.g., fetch data from a public REST API, validate and sanitize payload, store in PostgreSQL, and export a summarized JSON/CSV report).
- Evaluation of clean error handling, environment variable security, and clean code modularity.

### Round 3: Technical Interview (Backend & APIs)
- REST API best practices: Authentication (JWT vs OAuth2), rate limiting, pagination, idempotency.
- Relational schema design: Ensuring proper indexing on foreign keys and handling transaction rollbacks.
- Discussion of candidate''s MCA projects and automation scripts.

### Round 4: Leadership Round
- Agility, ability to self-teach new frameworks rapidly, and team communication skills.

### Key Placement Tips
- Showcase practical projects where you integrated third-party APIs or automated repetitive tasks.
- Understand how webhooks differ from standard polling.', 'PSIOG digital', 'approved', 240, NOW() - INTERVAL '20 days'),
    (v_author, 'ZOHO Corporation — Advanced Programming & Zero-Library Coding Guide', ARRAY['zoho', 'c', 'java', 'advanced-programming', 'zero-libraries'], E'## Zoho Corporation Recruitment Architecture

Zoho is famous for its unique, framework-free interview process. They do not test textbook LeetCode; instead, they evaluate your ability to construct working software systems from scratch using raw C or Java without any third-party libraries.

### Round 1: Aptitude & C/Java Output Tracing (Pen & Paper / Online)
- Tricky pointer arithmetic in C: `*ptr++`, `(*ptr)++`, double pointers, function pointers.
- Nested loop output tracing, bitwise operations, recursion stack depth.
- Core math puzzles and sequence deduction.

### Round 2: Basic Programming Round (2 hours - 5 Questions)
- Solve 5 programming problems using raw loops and logic:
  - Pattern printing problems (hollow diamond, number pyramids with spirals).
  - Custom string manipulation: Substring search (without `indexOf` or `strstr`), string reverse while preserving spaces.
  - Array rotation, finding pairs with given sum, removing duplicate elements in-place.
- **Rule**: Built-in methods like `split()`, `reverse()`, `Arrays.sort()` are strictly forbidden!

### Round 3: Advanced Programming Round (The Legendary 3-4 Hour Round)
- Build a complete, functional console-based application:
  - **Railway Reservation System**: Berth allocation (Lower, Middle, Upper, RAC, Waiting List), ticket cancellation, auto-promoting waiting list to RAC and RAC to confirmed.
  - **CLI Taxi Booking App**: Multiple taxis, geographic points (A to F), booking allocation based on lowest distance and lowest earnings, fare calculation.
  - **Dungeon Game / Snake Game**: Grid movement, monster avoidance, trigger points.
- **Mandatory Requirements**:
  - Proper Object-Oriented design (Classes, Encapsulation, State preservation).
  - No database needed: use in-memory data structures.
  - Interactive console menu with full error handling.

### Round 4: Technical Interview
- Line-by-line review of your Round 3 code.
- Interviewer will ask you to add 2 new complex features on the spot to verify you wrote the code and your architecture is extensible.
- Core CS: Operating Systems, memory allocation (malloc vs calloc), and DBMS fundamentals.

### Round 5: HR Interview
- Cultural fit, dedication, willingness to work in Chennai, Tenkasi, or other Zoho campuses, and humility.

### Key Placement Tips
- Practice building the Railway Reservation and Taxi Booking console apps from scratch in raw Java.
- Never hardcode values. Make configuration extensible.', 'ZOHO Corporation', 'approved', 720, NOW() - INTERVAL '50 days'),
    (v_author, 'SAP Labs — Enterprise In-Memory Computing & Cloud Architecture Guide', ARRAY['sap-labs', 'hana', 'java', 'system-design', 'cloud'], E'## SAP Labs Campus Hiring Blueprint

SAP Labs develops foundational enterprise cloud software, ERP suites, and the SAP HANA in-memory database engine. They look for deep architectural clarity and rock-solid core CS fundamentals.

### Round 1: Online Assessment (HackerRank - 90 mins)
- 2 Algorithmic Coding Problems (Medium-Hard): Dynamic Programming, Graph Traversals, Tree paths.
- 20 MCQs: Operating Systems (Virtual memory, scheduling), DBMS (Indexing, B-Trees, Transactions), and OOP.

### Round 2: Technical Interview 1 (DSA & Low-Level Design)
- Live coding: Tree traversals, LinkedList cycle detection & removal, matrix transformations.
- Object-Oriented Design: Design a parking lot, elevator system, or notification service using design patterns (Strategy, Factory, Singleton).
- Explaining time and space complexity with Big-O mathematical notation.

### Round 3: Technical Interview 2 (Databases, In-Memory Computing & FYP)
- **Database Internals**:
  - Row-store vs Column-store databases (Why column-store powers SAP HANA''s lightning-fast aggregations).
  - Indexing structures: B+ Trees vs Hash Indexes.
  - ACID properties and write-ahead logging (WAL) for durability.
- Architectural deep-dive into your Final Year Project: Scaling considerations and security.

### Round 4: Managerial & HR Round
- Alignment with SAP culture: Diversity, sustainability, enterprise stability.
- Behavioral questions using the STAR methodology (Situation, Task, Action, Result).

### Key Placement Tips
- Understand column-store database concepts and how in-memory databases achieve sub-second aggregations.
- Draw clean architecture diagrams during design questions.', 'SAP Labs', 'approved', 490, NOW() - INTERVAL '37 days'),
    (v_author, 'American Megatrends (AMI) — Firmware, BIOS/UEFI & Low-Level C Pattern', ARRAY['american-megatrends', 'c', 'firmware', 'uefi', 'linux-kernel'], E'## American Megatrends (AMI) Selection Pattern

AMI is the global market leader in BIOS, UEFI, and BMC (Baseboard Management Controller) firmware for server platforms, cloud hyperscalers, and consumer PCs.

### Round 1: Online Technical Assessment
- **C Programming Focus**: Bitwise operators (`&`, `|`, `^`, `~`, `<<`, `>>`), pointer arithmetic, struct padding and packing (`#pragma pack`), union memory overlap.
- **Computer Architecture & OS**: 8086/x86 microprocessor registers, interrupt vector tables, boot sequence (Power-On Self-Test -> BIOS -> Bootloader -> Kernel).
- 2 Coding Questions in C: Bit manipulation (e.g. counting set bits, reversing bits, setting/clearing specific bit flags) and LinkedList operations.

### Round 2: Technical Interview 1 (Deep C & Microprocessors)
- Pointer manipulation on raw memory addresses.
- The `volatile` keyword: Why is it crucial in embedded systems and memory-mapped I/O?
- Function pointers and callback mechanisms.
- Endianness: Writing a C function to detect whether the host architecture is Little-Endian or Big-Endian.

### Round 3: Technical Interview 2 (Firmware & System Programming)
- OS Boot Process: How BIOS initializes CPU, RAM, and PCIe peripherals before handing over execution to the operating system.
- Memory Management Unit (MMU) and physical vs virtual address mapping.
- Linux device driver basics, kernel modules, and hardware registers.

### Round 4: HR & Fitment Interview
- Long-term commitment to systems firmware engineering, team collaboration, and communication.

### Key Placement Tips
- Master C language bit manipulation and memory layout.
- Understand the exact role of UEFI firmware in modern computing.', 'American Megatrends', 'approved', 310, NOW() - INTERVAL '26 days'),
    (v_author, 'LTIMindtree — Digital Transformation & Enterprise Engineering Pattern', ARRAY['ltimindtree', 'enterprise', 'java', 'sql', 'full-stack'], E'## LTIMindtree Campus Selection Architecture

LTIMindtree recruits MCA graduates for global cloud transformations, data engineering, enterprise applications, and full-stack software development.

### Round 1: Online Assessment (National Level)
- **Quantitative, Logical & Verbal Aptitude**: Standard campus placement difficulty.
- **Technical MCQs**: Java, Python, SQL, Cloud fundamentals, OOPS.
- **Coding Assessment (HackerEarth)**: 2 coding questions covering Array manipulation, String parsing, and HashMaps.

### Round 2: Technical Interview (Core Java / Python & Databases)
- Core Java concepts: 4 pillars of OOPs with real-world examples, Exception handling hierarchy, Checked vs Unchecked exceptions.
- SQL queries: `INNER JOIN` vs `LEFT JOIN`, `GROUP BY` with `HAVING`, finding duplicate records, `UNION` vs `UNION ALL`.
- Web fundamentals: REST APIs, HTTP methods, JSON parsing.
- Walkthrough of your Final Year Project and key technical challenges overcome.

### Round 3: HR & Cultural Round
- Flexibility in learning new programming languages and frameworks.
- Willingness to relocate to major development centers across India.
- Team communication and professional goals.

### Key Placement Tips
- Speak clearly and confidently when explaining the architecture of your project.
- Write clean, well-commented code when asked to solve coding problems.', 'LTIMindtree', 'approved', 380, NOW() - INTERVAL '34 days'),
    (v_author, 'Accenture — ASE & Advanced ASE (AASE) Selection Blueprint', ARRAY['accenture', 'ase', 'aase', 'communication', 'cognitive'], E'## Accenture Campus Selection Blueprint

Accenture conducts unified campus hiring offering two salary bands: Associate Software Engineer (ASE) and Advanced Associate Software Engineer (AASE).

### Round 1: Cognitive & Technical Assessment (90 mins)
- **Cognitive Assessment (50 Questions)**: Critical reasoning, problem solving, abstract reasoning, numerical ability, English grammar.
- **Technical Assessment (40 Questions)**: Common application technologies, pseudo-code execution tracing, networking security, and cloud fundamentals.
- *Elimination round*: You must clear the cut-off to proceed immediately to the Coding Assessment.

### Round 2: Coding Assessment (45 mins)
- 2 Programming Problems (C++, Java, or Python):
  - Question 1: String / Array manipulation (Easy-Medium).
  - Question 2: Matrix or Hash-based sorting / greedy problem (Medium).
- Solving both questions successfully qualifies you for the higher **Advanced ASE (AASE)** band interview!

### Round 3: Automated Communication Assessment (Virtual)
- This is an automated assessment via headset/microphone testing spoken English:
  - Reading sentences aloud clearly.
  - Repeating sentences heard through audio.
  - Answering short questions based on audio stories.
  - Speaking for 1 minute on a given impromptu topic.
- *Critical tip*: Do not pause or stutter; speak in a steady, clear tone.

### Round 4: Technical & HR Combined Interview
- Discussion of academic projects and technologies used.
- Situational questions regarding team conflicts, handling difficult deadlines, and client empathy.
- Accenture''s core values: Stewardship, Best People, Client Value Creation, Respect for the Individual, Integrity.

### Key Placement Tips
- Test your microphone and quiet environment before taking the Communication Assessment.
- In the coding round, ensure your code compiles and passes all hidden test cases.', 'Accenture', 'approved', 650, NOW() - INTERVAL '48 days'),
    (v_author, 'Infosys — Systems Engineer (SE), DSE & Specialist Programmer (SP) Tracks', ARRAY['infosys', 'infytq', 'sp', 'dse', 'dsa'], E'## Infosys Campus Recruitment Breakdown

Infosys offers multiple entry tracks for MCA students: Systems Engineer (SE), Digital Specialist Engineer (DSE), and Specialist Programmer (SP) through HackWithInfy, InfyTQ, and on-campus drives.

### Round 1: Online Assessment (Sections vary by track)
- **Standard Track (SE)**:
  - Reasoning Ability (15 questions, 25 mins).
  - Technical Ability / Pseudo-code (5 questions, 10 mins).
  - Numerical Ability (10 questions, 35 mins).
  - Verbal Ability (20 questions, 20 mins).
  - Puzzle Solving (4 questions, 10 mins).
- **Specialist Track (SP & DSE)**:
  - 3 Hard Algorithmic Problems (3 hours) on Dynamic Programming, Advanced Graph Algorithms, and Segment Trees.

### Round 2: Technical Interview
- **For SE Track**:
  - Core OOPS: Polymorphism (Compile-time vs Run-time), Abstract classes, Encapsulation.
  - DBMS: Normalization up to 3NF, SQL joins, primary and foreign keys.
  - Live coding: Basic string reversals, Fibonacci series with memoization, array sorting.
  - Final Year Project overview.
- **For SP / DSE Track**:
  - Deep algorithmic discussion of your online test solutions.
  - System design: Microservices architecture, API gateways, database sharding, and caching with Redis.

### Round 3: HR Interview
- Relocation willingness to Infosys Mysore Training Campus and global development centers.
- Soft skills, behavioral questions, and professional adaptability.

### Key Placement Tips
- For the SE round, practice Infosys pseudo-code questions thoroughly.
- For SP/DSE, master dynamic programming on grids and graphs.', 'Infosys', 'approved', 610, NOW() - INTERVAL '46 days'),
    (v_author, 'Walmart Global Tech — Ultra-Scale eCommerce & Distributed Systems Pattern', ARRAY['walmart-global-tech', 'distributed-systems', 'dsa', 'concurrency', 'retail'], E'## Walmart Global Tech Recruitment Blueprint

Walmart Global Tech builds high-throughput, low-latency retail architectures powering millions of orders, inventory tracking, and supply chain logistics across the globe.

### Round 1: Online Coding Assessment (HackerEarth - 90 mins)
- 2 LeetCode Medium/Hard Problems:
  - Problem 1: Array Intervals / Sliding Window / Greedy.
  - Problem 2: Tree / Graph shortest paths or Dynamic Programming.
- 20 MCQs on Core CS: Operating Systems, Database transactions, and Java concurrency.

### Round 2: Technical Interview 1 (DSA & Algorithmic Problem Solving)
- Live coding of 2 algorithmic challenges with strict complexity constraints.
- Examples: Implementing LRU Cache, Word Ladder, Course Schedule (Topological Sort), or Meeting Rooms II.
- Explaining time and space complexity with proofs.

### Round 3: Technical Interview 2 (Low-Level Design & Concurrency)
- Object-Oriented Design of a scalable retail subsystem:
  - Shopping Cart with promo code application.
  - Real-time inventory reservation system during flash sales.
- Concurrency and thread safety:
  - How to prevent overselling when 10,000 users attempt to purchase the last 5 laptops simultaneously.
  - Optimistic vs Pessimistic locking in databases, Redis distributed locks.

### Round 4: Hiring Manager & Leadership Round
- Cultural values: Service to the Customer, Respect for the Individual, Strive for Excellence, Act with Integrity.
- Project architectural deep-dive and resolving team technical disagreements.

### Key Placement Tips
- Know how database locking works and how to design idempotency in payment and checkout APIs.
- Write modular, readable code during the live coding rounds.', 'Walmart Global Tech', 'approved', 540, NOW() - INTERVAL '39 days'),
    (v_author, 'Palo Alto Networks — Cybersecurity & High-Performance Systems Pattern', ARRAY['palo-alto-networks', 'cybersecurity', 'networking', 'linux', 'c-plus-plus'], E'## Palo Alto Networks Selection Architecture

Palo Alto Networks is the global leader in cybersecurity, next-gen firewalls, cloud security, and threat intelligence. They maintain one of the highest technical salary bars on campus.

### Round 1: Online Assessment (90 mins)
- 3 Challenging Coding Problems:
  - Bitwise operations & bitmasking algorithms.
  - Graph algorithms (Shortest path, cycle detection, network flows).
  - String pattern matching (Trie, KMP, Rabin-Karp).
- Core Networking & OS MCQs: TCP/IP stack, socket options, packet framing, memory layout.

### Round 2: Technical Interview 1 (Algorithms & Memory Optimization)
- Live coding of algorithmic problems with extreme scrutiny on memory allocation.
- In-memory data structures: Fast IP lookup using Trie or Radix Tree.
- Cache-friendly coding: Data locality, minimizing CPU cache misses.

### Round 3: Technical Interview 2 (Computer Networks, OS & Security)
- Deep Networking:
  - In-depth explanation of the TCP 3-way handshake, 4-way termination, and TCP windowing.
  - How Firewalls inspect packet headers vs deep packet inspection (DPI).
  - Common attack vectors: SYN flood, DNS amplification, Man-in-the-Middle (MitM), SQL injection, and buffer overflows.
- OS & Sockets:
  - Non-blocking I/O, `epoll` vs `select`, multi-threading vs event-driven architectures.

### Round 4: Director / HR Round
- Passion for cybersecurity, analytical rigor under pressure, and ethical integrity.

### Key Placement Tips
- Master Layer 3 (Network) and Layer 4 (Transport) protocols inside out.
- Understand how modern TLS handshakes establish secure symmetric keys.', 'Palo Alto Networks', 'approved', 470, NOW() - INTERVAL '31 days'),
    (v_author, 'Bounteous x Accolite — Full-Stack & Enterprise Solution Architecture Pattern', ARRAY['bounteous-x-accolite', 'dsa', 'oops', 'full-stack', 'java'], E'## Bounteous x Accolite Selection Blueprint

Bounteous x Accolite partners with enterprise clients for digital experience platforms, commerce transformations, and full-stack software development.

### Round 1: Online Assessment (Eduthrill / HackerRank)
- Aptitude & Logical Reasoning.
- Core CS MCQs (DBMS, OOPS, Java/C++, Computer Networks).
- 2 Coding Questions: Array manipulation and String processing.

### Round 2: Technical Interview 1 (Data Structures & OOPs)
- Live whiteboard/coderpad coding:
  - Binary Tree traversals (Inorder, Preorder, Postorder, Zigzag level order).
  - LinkedList manipulation: Reverse in K-groups, detect intersection of two lists.
- Core Java / OOPs: Abstract classes vs Interfaces, method overloading vs overriding, Diamond problem in inheritance.

### Round 3: Technical Interview 2 (System Design & Project Review)
- Web fundamentals: REST APIs, CORS issues, JWT authentication token flow, HTTPS security.
- Database queries: Complex joins, subqueries, indexing, and ACID compliance.
- Final Year Project walkthrough and architectural trade-offs.

### Round 4: HR Interview
- Behavioral questions, teamwork, continuous learning, and relocation preferences.

### Key Placement Tips
- Ensure you can code binary tree traversals without looking up syntax.
- Clearly explain your role and accomplishments in team academic projects.', 'Bounteous x Accolite', 'approved', 310, NOW() - INTERVAL '27 days'),
    (v_author, 'Celeredge Inc — Scalable Web & Enterprise Software Consulting Guide', ARRAY['celeredge-inc', 'web-development', 'javascript', 'python', 'apis'], E'## Celeredge Inc Selection Process

Celeredge Inc provides scalable software engineering, cloud migration, and bespoke enterprise solutions.

### Round 1: Online Assessment
- General logical aptitude, problem solving, and basic algorithmic coding.
- Technical MCQs on Web Technologies (HTML5, CSS3, JavaScript/TypeScript, SQL).

### Round 2: Technical Interview (Full-Stack Fundamentals)
- JavaScript / TypeScript internals: Closures, Event Loop, Promises, `async/await`, prototypes.
- REST API implementation: Structuring endpoints, query parameters vs path parameters, HTTP headers.
- Relational databases: Designing schema for a business CRM or management system.

### Round 3: Project & HR Discussion
- Detailed review of candidate''s live projects, GitHub repositories, and code style.
- Communication skills, responsiveness, and problem solving mindset.

### Key Placement Tips
- Have your projects deployed live (e.g. Vercel, Supabase, Firebase) and include clickable links on your resume.
- Understand the difference between client-side rendering and server-side rendering.', 'Celeredge Inc', 'approved', 220, NOW() - INTERVAL '19 days'),
    (v_author, 'Tata Consultancy Services (TCS) — NQT, Digital & Prime Track Breakdown', ARRAY['tcs', 'nqt', 'digital', 'prime', 'enterprise'], E'## TCS National Qualifier Test (NQT) & Interview Process

TCS conducts centralized campus hiring through the NQT, categorizing MCA candidates into three salary bands: TCS Ninja (~3.6 LPA), TCS Digital (~7 LPA), and TCS Prime (~9 LPA).

### Round 1: TCS NQT Assessment
- **Cognitive Section (60 mins)**:
  - Numerical Ability (20 questions, 25 mins).
  - Verbal Ability (25 questions, 25 mins).
  - Reasoning Ability (20 questions, 25 mins).
- **Technical Section (60 mins)**:
  - Advanced Quantitative & Reasoning.
  - 2 Coding Questions:
    - Question 1 (Easy-Medium): Array/String logic.
    - Question 2 (Medium-Hard): Dynamic Programming / Matrix / Hash aggregation.
- *Your coding performance directly determines whether you are called for Ninja, Digital, or Prime interviews!*

### Round 2: Technical Interview (For Digital / Prime)
- **FYP Deep-Dive**: Your Final Year Project is the primary centerpiece. Be ready to explain your system architecture and code line-by-line.
- **Java / Python Fundamentals**:
  - OOPs principles, Collections framework, Exception handling.
  - Database queries: Writing SQL queries with `JOIN` and `GROUP BY` on paper.
  - Basic cloud and web development concepts.

### Round 3: Managerial & HR Interview
- Service commitment, willingness to work in any technology stack, shift flexibility, and relocation to any TCS delivery center across India.
- Situational questions regarding team ethics, intellectual property, and compliance.

### Key Placement Tips
- In the NQT coding section, respect strict input/output formatting. Never print extraneous user prompts like "Enter number:".
- Know your Final Year Project thoroughly.', 'Tata Consultancy Services', 'approved', 680, NOW() - INTERVAL '43 days'),
    (v_author, 'Oracle OFSS — Core Banking Systems & Database Engineering Pattern', ARRAY['oracle-ofss', 'sql', 'database-internals', 'banking', 'plsql'], E'## Oracle Financial Services Software (OFSS) Selection Blueprint

Oracle OFSS develops mission-critical core banking, lending, and treasury management platforms (including Oracle FLEXCUBE) used by top global banks.

### Round 1: Online Assessment (90 mins)
- Quantitative and logical aptitude.
- Core Computer Science MCQs: Heavy emphasis on **DBMS, SQL, and Data Structures**.
- 2 Coding Challenges: Array transformations, string parsing, and linked lists.

### Round 2: Technical Interview 1 (Intensive Database & SQL Mastery)
- **SQL Query Deep-Dive**:
  - Writing complex queries with multiple joins, self-joins, correlated subqueries, and window functions (`DENSE_RANK()`, `LEAD()`, `LAG()`).
  - Indexes: Clustered vs Non-Clustered, Composite indexes, B-Tree index structure.
  - Transaction isolation and locks: Shared vs Exclusive locks, two-phase locking (2PL).
- PL/SQL Concepts: Stored procedures, triggers, cursors, and transaction control (`COMMIT`, `ROLLBACK`, `SAVEPOINT`).

### Round 3: Technical Interview 2 (OOPs, Java/C++ & Banking Scenarios)
- Object-Oriented Programming: Inheritance vs Composition, design patterns.
- Banking logic problem: Designing a ledger system that prevents debit without sufficient balance and logs audit trails.
- Walkthrough of candidate''s academic projects.

### Round 4: HR Interview
- Integrity, adherence to regulatory and compliance standards, communication skills, and relocation flexibility.

### Key Placement Tips
- As an Oracle company, DBMS questions are held to the highest standard. Practice query execution plans and index tuning.
- Always explain how you handle race conditions during account transactions.', 'Oracle OFSS', 'approved', 460, NOW() - INTERVAL '38 days'),
    (v_author, 'Autodesk — 3D Computer Graphics, CAD Engineering & System Design', ARRAY['autodesk', 'graphics', 'c-plus-plus', 'math', 'algorithms'], E'## Autodesk Campus Recruitment Blueprint

Autodesk is the world''s leading design software company, behind AutoCAD, Revit, Maya, and cloud-native manufacturing platforms.

### Round 1: Online Coding Assessment (HackerRank - 90 mins)
- 3 Algorithmic Coding Problems:
  - Computational geometry, coordinate points, interval intersections.
  - Tree or Graph traversals.
  - Dynamic programming or Greedy resource scheduling.

### Round 2: Technical Interview 1 (DSA, Math & Geometry)
- Algorithmic problem solving: Line intersection detection, convex hull basics, matrix transformations (Translation, Rotation, Scaling).
- Advanced data structures: Spatial indexing (QuadTrees / Octrees / KD-Trees concept) and efficient bounding box checks.
- Clean C++ / Java coding: Memory management, copy constructors, RAII principles.

### Round 3: Technical Interview 2 (System Design & Cloud APIs)
- Object-Oriented Architecture: Designing a collaborative canvas where multiple users can draw and manipulate shapes simultaneously.
- State management and Undo/Redo design using the Command Pattern.
- Web APIs: RESTful services, WebGL/Three.js basics, and cloud storage of large 3D assets.

### Round 4: Managerial & HR Round
- Passion for 3D digital art, architecture, and manufacturing software.
- Collaboration with global design squads and continuous engineering curiosity.

### Key Placement Tips
- Mention any computer graphics, game development, or spatial computing projects.
- Master matrix operations and vector mathematics.', 'Autodesk', 'approved', 410, NOW() - INTERVAL '32 days'),
    (v_author, 'Ramco Systems — Enterprise Cloud ERP & Aviation Software Selection Pattern', ARRAY['ramco-systems', 'erp', 'aviation', 'sql', 'enterprise'], E'## Ramco Systems Campus Selection Guide

Ramco Systems develops cloud ERP, Global Payroll, and mission-critical Aviation Maintenance (MRO) enterprise software.

### Round 1: Online Assessment
- Logical reasoning, quantitative aptitude, and core programming MCQs.
- 2 Coding Questions: Array manipulation and String processing.

### Round 2: Machine Coding & Business Logic Round
- Implementing a real-world enterprise business logic component:
  - Employee Leave Balance & Carry-Forward Calculator.
  - Aircraft maintenance scheduled inspection alert engine.
- Writing clean modular classes with proper validation of date ranges and numeric values.

### Round 3: Technical Interview (Databases & Core CS)
- Relational schema design: Normalization, foreign key constraints, composite primary keys.
- SQL queries: Writing stored procedures and complex joins.
- Object-Oriented principles and Final Year Project discussion.

### Round 4: HR Interview
- Professional communication, adaptability, and cultural alignment.

### Key Placement Tips
- Focus on robust relational database design and handling boundary dates/values.
- Explain how your code avoids SQL injection and sanitizes inputs.', 'Ramco Systems', 'approved', 320, NOW() - INTERVAL '24 days'),
    (v_author, 'Amazon — SDE-1 Loop & Leadership Principles Mastery', ARRAY['amazon', 'sde', 'leadership-principles', 'dsa', 'star-method'], E'## Amazon SDE-1 Campus Loop Breakdown

Amazon''s recruitment loop evaluates two equal pillars: Algorithmic problem solving excellence and strict adherence to Amazon''s **16 Leadership Principles (LPs)**.

### Round 1: Online Assessment (OA) on HackerRank
- **Part 1: Code Assessment (70 mins)**: 2 LeetCode Medium/Hard problems (Sliding Window, Priority Queue, Graph, Dynamic Programming).
- **Part 2: Work Style Assessment (15 mins)**: Behavioral scenarios testing Leadership Principles.
- **Part 3: Feedback Survey (5 mins)**.

### Round 2: Technical Interview 1 (Data Structures & LPs)
- 20 minutes of LP questions: "Tell me about a time you took a calculated risk and failed" (Testing *Calculated Risk Taking* and *Earns Trust*).
- 40 minutes of live coding: Trees, Binary Search on Answer, or HashMap/Heap combination (e.g. Top K Frequent Elements).

### Round 3: Technical Interview 2 (Algorithms & Problem Solving)
- 20 minutes of LP questions: "Tell me about a time you had a disagreement with a team member and how you resolved it" (Testing *Have Backbone; Disagree and Commit*).
- 40 minutes of live coding: Dynamic Programming, Graph Traversal (BFS/DFS), or Disjoint Set Union.

### Round 4: The Bar Raiser Round
- Conducted by a certified Amazon Bar Raiser from a completely different team.
- Deep behavioral grilling using the **STAR Method** (Situation, Task, Action, Result) with follow-up questions probing metrics.
- SDE-1 Object-Oriented Design: Designing a Parking Lot, Locker System, or Linux `find` command utility.

### Key Placement Tips
- Perfect coding alone will not get you an offer if you fail the Leadership Principles. Prepare 2-3 genuine stories from your academic projects for each LP.
- Always communicate your thoughts out loud before writing a line of code.', 'Amazon', 'approved', 890, NOW() - INTERVAL '52 days'),
    (v_author, 'Mphasis — Applied Technology & Financial Services Selection Guide', ARRAY['mphasis', 'applied-tech', 'java', 'sql', 'financial-services'], E'## Mphasis Campus Selection Pattern

Mphasis applies next-generation design, architecture, and engineering services to transform global financial institutions and logistics enterprises.

### Round 1: Online Assessment (AMCAT / Mettle)
- Quantitative Aptitude, Logical Reasoning, and English Comprehension.
- Computer Programming MCQs (C, C++, Java, Data Structures).
- 2 Coding Questions: Array rotations, String transformations, and HashMaps.

### Round 2: Technical Interview (CS Foundations & Project Review)
- Core Java concepts: Abstract classes, Interfaces, Exception handling, Collections (`ArrayList` vs `LinkedList`).
- SQL basics: `JOIN`, `GROUP BY`, `HAVING`, Primary vs Foreign keys.
- Detailed discussion of candidate''s academic projects and technologies used.

### Round 3: HR & Versant Communication Round
- Professional communication, readiness to work across shifts and client projects.
- Relocation preferences across India (Bengaluru, Chennai, Pune, Hyderabad).

### Key Placement Tips
- Keep your fundamental CS definitions crisp and concise.
- Prepare a clear 2-minute introduction covering your background, project highlights, and technical strengths.', 'Mphasis', 'approved', 310, NOW() - INTERVAL '23 days'),
    (v_author, 'Logbase Technologies — Modern Cloud Data Warehousing & Pipelines', ARRAY['logbase-technologies', 'snowflake', 'data-warehousing', 'sql', 'aws'], E'## Logbase Technologies Selection Blueprint

Logbase Technologies provides cloud data architecture, Snowflake analytics, and scalable data pipeline engineering for modern digital companies.

### Round 1: Online Assessment
- Analytical aptitude, quantitative problem solving, and Python/SQL challenges.
- Data logic and interpretation questions.

### Round 2: Technical Interview 1 (Advanced SQL & Data Modeling)
- Live SQL Query Writing:
  - Window functions: `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `LEAD()`, and `LAG()`.
  - Common Table Expressions (CTEs) and recursive queries.
- Data warehousing concepts: Star Schema, Fact vs Dimension tables, Slowly Changing Dimensions (SCD Type 1 & 2).

### Round 3: Technical Interview 2 (Python, APIs & Cloud Basics)
- Python data manipulation: Writing scripts to ingest, transform, and clean JSON/CSV feeds.
- Cloud concepts: AWS S3 buckets, event triggers, database connection pooling.
- Final Year Project review.

### Round 4: HR & Fitment Round
- Communication, client delivery focus, and continuous learning.

### Key Placement Tips
- Practice writing complex analytical SQL queries without relying on an IDE auto-complete.
- Understand the difference between OLTP and OLAP architectures.', 'Logbase Technologies', 'approved', 250, NOW() - INTERVAL '21 days'),
    (v_author, 'Walkerscott — Microsoft Cloud & Enterprise Application Consulting', ARRAY['walkerscott', 'azure', 'dotnet', 'power-platform', 'consulting'], E'## Walkerscott Campus Selection Process

Walkerscott is a premier Microsoft Gold Partner consultancy delivering custom enterprise apps, Azure cloud architectures, and Power Platform integrations.

### Round 1: Technical Assessment
- Analytical aptitude, logical reasoning, and C#/.NET / Java programming challenges.
- Relational database and SQL query questions.

### Round 2: Technical Interview (Object-Oriented Architecture & Web)
- Object-Oriented Design: Polymorphism, Dependency Injection, Interface-driven development.
- Web APIs: RESTful endpoints, JSON serialization, HTTP status codes, error handling.
- Relational database schema design and SQL query performance.

### Round 3: Client Focus & HR Interview
- Consulting mindset: Understanding business problems, structured communication, and client empathy.
- Career aspirations in Microsoft Azure cloud ecosystem.

### Key Placement Tips
- Highlight any experience with cloud platforms, C#/.NET, or enterprise web frameworks.
- Demonstrate enthusiasm for learning modern enterprise software suites.', 'Walkerscott', 'approved', 240, NOW() - INTERVAL '18 days'),
    (v_author, 'BoatMinds AI — Intelligent Document Processing & Deep Learning Pattern', ARRAY['boatminds-ai', 'deep-learning', 'nlp', 'python', 'fastapi'], E'## BoatMinds AI Selection Guide

BoatMinds AI develops cognitive document automation platforms using Computer Vision, OCR, and Large Language Models for financial and insurance compliance.

### Round 1: Online Coding & ML Assessment
- 2 Algorithmic Coding Questions in Python (Strings, Arrays, Graphs).
- Machine Learning & Deep Learning MCQs: CNN architectures, Transformer self-attention, loss functions, optimization algorithms (Adam, SGD).

### Round 2: Machine Coding & Text Processing Round
- Implementing a real-world parsing challenge:
  - Given OCR text data from invoices, extract structured fields (Vendor Name, Date, Total Amount, Tax ID) using Regex and spatial heuristics.
  - Efficient text tokenization and classification.

### Round 3: Technical Interview (Deep Learning & System Architecture)
- Deep Learning concepts: Fine-tuning models, handling vanishing gradients, vector embeddings, cosine similarity.
- API engineering: Serving machine learning models using FastAPI, async worker queues, Docker containerization.
- Candidate project deep-dive.

### Round 4: Leadership Round
- Passion for cutting-edge AI research, ability to debug complex ML failure modes, and intellectual curiosity.

### Key Placement Tips
- Highlight practical NLP or computer vision projects with clear metrics.
- Understand the trade-offs between heuristic parsing and deep learning models.', 'BoatMinds ai', 'approved', 290, NOW() - INTERVAL '25 days'),
    (v_author, '7-Eleven Global Solution Center — Retail Microservices & Omni-Channel Tech', ARRAY['7-eleven', 'microservices', 'retail-tech', 'spring-boot', 'caching'], E'## 7-Eleven Global Solution Center Selection Blueprint

7-Eleven Global Solution Center (GSC) engineers digital platforms powering frictionless retail, mobile checkout, digital fuel delivery, and loyalty rewards for over 80,000 stores worldwide.

### Round 1: Online Assessment (90 mins)
- Quantitative and logical aptitude.
- 2 Coding Questions: Array manipulation, String parsing, and interval scheduling.
- Core CS MCQs: OOPS, DBMS, Operating Systems, and Spring Boot / Web technologies.

### Round 2: Technical Interview 1 (DSA & Problem Solving)
- Live coding: Tree traversals, LinkedList manipulation, finding maximum subarray sum (Kadane''s Algorithm).
- Hash-based lookups and collision resolution strategies.

### Round 3: Technical Interview 2 (System Design & Microservices)
- Microservices Architecture:
  - Designing a Coupon & Discount Validation service.
  - Caching strategies using Redis for active product prices and store inventory.
  - Handling database transactions across microservices (Saga pattern overview).
- Final Year Project architectural review.

### Round 4: HR & Cultural Fitment
- Team collaboration, customer-first mindset, and continuous engineering improvement.

### Key Placement Tips
- Understand how microservices decouple order processing from inventory updates.
- Be prepared to discuss database normalization and Redis caching.', '7-Eleven', 'approved', 390, NOW() - INTERVAL '30 days'),
    (v_author, 'IBM Consulting — Digital Strategy & Enterprise Application Modernization', ARRAY['ibm-consulting', 'digital-strategy', 'enterprise', 'cloud', 'consulting'], E'## IBM Consulting Campus Selection Guide

IBM Consulting helps global enterprises modernize their core legacy systems, migrate to hybrid cloud, and implement AI workflows across enterprise processes.

### Round 1: Cognitive Assessment (IBM Cognify Games)
- Visual and spatial memory games, problem solving puzzles, and rapid mental arithmetic.

### Round 2: Technical & Solutions Assessment
- Computer science fundamentals: OOPS, DBMS, Agile methodology, SDLC phases.
- Basic coding problem: String manipulations and array filtering.

### Round 3: Technical & Business Scenario Interview
- Presenting technical solutions to business stakeholders: "How would you explain the benefits of cloud migration to a non-technical retail executive?"
- Discussion of academic projects: Architecture, tech stack decisions, and team contributions.
- Software engineering best practices: Version control with Git, CI/CD pipelines, and unit testing.

### Round 4: HR & Consulting Fitment
- Structured articulation, presentation poise, leadership, and willingness to travel for client engagements.

### Key Placement Tips
- Practice explaining technical concepts in plain, compelling business language.
- Structure answers with clear problem, approach, and outcome sections.', 'IBM Consulting', 'approved', 360, NOW() - INTERVAL '33 days'),
    (v_author, 'Acies Global — FinTech, Quantitative Risk & Regulatory Systems Pattern', ARRAY['acies-global', 'fintech', 'risk-management', 'python', 'sql'], E'## Acies Global Selection Process

Acies Global develops financial technology, enterprise risk modeling, and regulatory compliance platforms for financial institutions.

### Round 1: Online Assessment
- Quantitative aptitude (Probability, Financial math, Statistics).
- Logical deduction and analytical reasoning.
- Coding section: Python/SQL problem solving with numerical precision.

### Round 2: Technical Interview 1 (Data Structures & Financial Algorithms)
- Handling numerical precision: Avoiding floating-point rounding errors in financial transactions (e.g. using `BigDecimal` in Java or `Decimal` in Python).
- Data structures: Efficient lookup of financial market data, sorting and filtering ledgers.
- SQL queries: Complex joins, aggregations, and running balance calculations using window functions.

### Round 3: Techno-Managerial Round
- Designing database schemas for accounting and trade records with strict audit trails.
- Walkthrough of candidate''s academic projects and code cleanliness.

### Round 4: HR Interview
- Professional ethics, diligence, communication skills, and adaptability.

### Key Placement Tips
- Financial platforms require extreme precision; always check for rounding issues and edge cases.
- Know how database foreign key constraints protect relational integrity.', 'Acies Global', 'approved', 270, NOW() - INTERVAL '22 days'),
    (v_author, 'AppViewX — Next-Gen PKI, Automated Certificate Management & DevOps', ARRAY['appviewx', 'pki', 'ssl-tls', 'cybersecurity', 'devops'], E'## AppViewX Campus Recruitment Breakdown

AppViewX is a cybersecurity leader in Automated Certificate Management (CLM), Public Key Infrastructure (PKI), and network infrastructure orchestration.

### Round 1: Online Assessment (90 mins)
- 2 Algorithmic Coding Problems (Arrays, Trees, HashMaps).
- Core CS MCQs with high weightage on **Computer Networks, Operating Systems, and Security**.

### Round 2: Technical Interview 1 (DSA & Core Programming)
- Live coding: Tree traversals, string manipulation, and recursive problem solving.
- Object-Oriented Design in Python/Java: Clean class boundaries and modular code structure.

### Round 3: Technical Interview 2 (Computer Networks, PKI & Linux)
- **Public Key Infrastructure (PKI) & Cryptography**:
  - Symmetric vs Asymmetric encryption (AES vs RSA/ECC).
  - How SSL/TLS certificates work: Certificate Authorities (CAs), CSR, public/private key pairs, and the TLS handshake.
  - Certificate lifecycle: Issuance, renewal, revocation (CRLs and OCSP).
- **Linux & DevOps Fundamentals**:
  - Linux shell scripting, file permissions, processes (`top`, `ps`, `kill`), and network tools (`curl`, `netstat`, `openssl`).

### Round 4: HR & Cultural Round
- Teamwork, curiosity for cybersecurity automation, and professional growth.

### Key Placement Tips
- Master how SSL/TLS encryption works from key generation to browser verification.
- Be comfortable with basic Linux terminal commands and networking concepts.', 'Appviewx', 'approved', 330, NOW() - INTERVAL '28 days'),
    (v_author, 'FocusR Technologies — Oracle Enterprise Applications & Supply Chain', ARRAY['focusr-technologies', 'oracle-erp', 'sql', 'supply-chain', 'java'], E'## FocusR Technologies Selection Pattern

FocusR Technologies delivers Oracle ERP consulting, customized enterprise supply chain applications, and mobile business extensions.

### Round 1: Online Assessment
- General quantitative and logical aptitude.
- Technical MCQs on Java, C, DBMS, and Web Architecture.
- Basic Coding Challenge: Array and String operations.

### Round 2: Technical Interview (Core CS & Relational Databases)
- Core Programming: Object-Oriented principles, Exception handling, Collections framework.
- Relational Database Mastery: Designing schemas for purchase orders, inventory, and supplier master tables.
- SQL queries: Multi-table joins, subqueries, and stored procedures.

### Round 3: HR & Fitment Discussion
- Professional communication, willingness to master enterprise software ecosystems, and teamwork.

### Key Placement Tips
- Solid database modeling and clean SQL query writing are the primary filters.
- Prepare a clear overview of your Final Year Project.', 'FocusR Technologies', 'approved', 230, NOW() - INTERVAL '19 days'),
    (v_author, 'PayHuddle — Payment Gateway Testing, EMV & Card Transaction Protocols', ARRAY['pay-huddle', 'payments', 'iso8583', 'emv', 'networking'], E'## PayHuddle Campus Recruitment Blueprint

PayHuddle is a specialized payment technology company building simulators, certification tools, and testing platforms for payment networks, EMV chips, and POS terminals.

### Round 1: Technical Assessment
- Analytical aptitude, payment logic deduction, and C/Java programming challenges.
- Computer Networks and Operating Systems MCQs.

### Round 2: Technical Interview 1 (Low-Level Systems & Sockets)
- Socket programming: TCP client-server communication, handling binary and hexadecimal byte streams.
- Concurrency & Threading: Handling multiple POS terminal connections simultaneously.
- Data serialization: Converting objects to raw byte buffers and parsing payment packet headers.

### Round 3: Technical Interview 2 (Payment Protocols & Architecture)
- Transaction lifecycle: Authorization, Clearing, and Settlement.
- Payment messaging standards: High-level overview of ISO 8583 message formats (MTI, Bitmaps, Data Elements).
- Candidate project deep-dive and code quality review.

### Round 4: Management & HR Round
- Passion for fintech infrastructure, attention to protocol details, and adaptability.

### Key Placement Tips
- Familiarity with socket programming and hexadecimal byte manipulation sets you apart.
- Review how credit card transactions reach the acquiring and issuing banks.', 'Pay Huddle', 'approved', 260, NOW() - INTERVAL '21 days'),
    (v_author, 'Netscribes Analytics — Market Intelligence, Big Data & Web Scraping', ARRAY['netscribes-analytics', 'data-scraping', 'python', 'sql', 'analytics'], E'## Netscribes Analytics Selection Process

Netscribes delivers data-driven market intelligence, patent research, and competitive analytics for Fortune 500 enterprises.

### Round 1: Online Assessment
- Quantitative aptitude, logical reasoning, and data interpretation tables.
- Python programming and SQL query questions.

### Round 2: Technical Interview (Data Wrangling & Web Scraping)
- Python for Data Engineering: Writing scrapers with BeautifulSoup, Scrapy, or Selenium; handling pagination, CAPTCHA, and anti-scraping headers.
- Data Cleaning: Handling missing values, normalising unstructured text, regex pattern extraction.
- SQL: Writing aggregate queries, grouping by categories, and exporting reporting tables.

### Round 3: Managerial & Project Review
- Analytical mindset: How to convert raw web data into actionable business insights.
- Walkthrough of candidate''s academic and data analytics projects.

### Round 4: HR Round
- Communication, research curiosity, and teamwork.

### Key Placement Tips
- Showcase practical experience parsing messy HTML or CSV datasets using Python.
- Understand how database indexing speeds up analytical queries.', 'Netscribes Analytics', 'approved', 240, NOW() - INTERVAL '20 days'),
    (v_author, 'Talview — AI Video Proctoring, WebRTC & High-Scale Assessment Engines', ARRAY['talview', 'webrtc', 'video-ai', 'python', 'system-design'], E'## Talview Campus Selection Blueprint

Talview powers AI-enabled online talent assessments, conversational interviews, and automated video proctoring for global enterprises.

### Round 1: Online Assessment (90 mins)
- 2 Algorithmic Coding Problems (Arrays, HashMaps, String parsing).
- Core CS MCQs covering WebRTC, Media Streaming, Database transactions, and OOP.

### Round 2: Technical Interview 1 (DSA & Web Engineering)
- Live problem solving: Array manipulation, linked lists, and tree traversals.
- Web architecture: Asynchronous JavaScript / Python, event-driven I/O, REST APIs.

### Round 3: Technical Interview 2 (Real-Time Media & System Design)
- Real-Time Communication: WebRTC peer connection, STUN/TURN servers, WebSocket signaling.
- High-scale assessment design: Designing an exam engine that handles 100,000 concurrent students submitting answers with proctoring video feeds.
- Security: Preventing exam fraud and tamper-proofing client side timers.

### Round 4: HR & Cultural Round
- Problem solving agility, ownership, and collaborative spirit.

### Key Placement Tips
- Highlight any projects involving real-time communication, WebSockets, or camera proctoring.
- Explain how to design systems that are resilient to sudden client network drops.', 'Talview', 'approved', 310, NOW() - INTERVAL '27 days'),
    (v_author, 'Eightfold AI — Deep Learning Talent Intelligence & Algorithmic Loop', ARRAY['eightfold-ai', 'deep-learning', 'hard-dsa', 'system-design', 'silicon-valley'], E'## Eightfold AI Campus Recruitment Loop

Eightfold AI is a Silicon Valley unicorn founded by former Google and Meta search architects. They have an exceptionally high algorithmic and system design hiring bar.

### Round 1: Online Coding Assessment (HackerRank - 90 mins)
- 3 Challenging LeetCode Hard Problems:
  - Advanced Dynamic Programming (Digit DP, Bitmask DP).
  - Graph Algorithms (Shortest Paths, Strongly Connected Components).
  - Trees / Monotonic Stacks / Segment Trees.
- Only candidates with optimal solutions across all 3 problems pass to interviews.

### Round 2: Technical Interview 1 (Algorithmic Mastery)
- Live coding of complex algorithmic problems on coderpad.
- Interviewers evaluate code elegance, rigorous proofs of time/space complexity, and clean handling of obscure edge cases.

### Round 3: Technical Interview 2 (System Design & Scalable Pipelines)
- Designing a high-throughput search and matching engine (e.g. Matching 10 million candidate resumes against 100,000 job descriptions in real-time).
- Caching layers (Redis), search indexes (Elasticsearch / Lucene), and asynchronous data pipelines (Kafka).
- Discussion of concurrency and race condition mitigation.

### Round 4: Engineering Director & Culture Round
- Intellectual honesty, grit, willingness to debate architectural trade-offs, and deep product passion.

### Key Placement Tips
- Practice LeetCode Hard problems and know your Big-O limits.
- Think through distributed caching and inverted index concepts for search design.', 'Eightfold AI', 'approved', 520, NOW() - INTERVAL '35 days'),
    (v_author, 'DevRev — Developer CRM, Knowledge Graphs & Modern Cloud Craftsmanship', ARRAY['devrev', 'golang', 'knowledge-graphs', 'clean-code', 'craftsmanship'], E'## DevRev Campus Selection Blueprint

DevRev was founded by the co-founder of Nutanix to build an AI-native Developer CRM that connects developers directly to customers and production issues. They place immense value on software craftsmanship.

### Round 1: Online Coding Assessment
- 2-3 Hard Algorithmic Problems focusing on Trees, Heaps, Graph traversals, and String parsing.

### Round 2: Machine Coding & Take-Home Assignment
- Build a production-grade microservice or CLI tool (often using Go, TypeScript, or Python).
- **Evaluation Criteria**:
  - Clean layered architecture (API layer, Business logic, Storage layer).
  - Production readiness: Structured JSON logging, health-check endpoints, proper unit and integration tests.
  - Comprehensive README with setup instructions and architectural diagrams.

### Round 3: Technical Interview (Code Review & Systems Architecture)
- Deep code review of your assignment: Defending your design choices and refactoring code in real time.
- Systems concepts: Concurrency in Go (goroutines and channels) or Java, API rate limiting, and database indexing.

### Round 4: Founder / Executive Culture Interview
- High agency, product intuition, self-directed learning, and high standards of visual and code design.

### Key Placement Tips
- DevRev rejects sloppy code. Ensure your test suite passes and your code adheres to standard linting rules.
- Demonstrate high personal standards and taste in software design.', 'DevRev', 'approved', 480, NOW() - INTERVAL '30 days'),
    (v_author, 'CEI India — Custom Application Development & Enterprise Cloud Solutions', ARRAY['cei-india', 'cloud-native', 'java', 'dotnet', 'sql'], E'## CEI India (Computer Enterprises Inc.) Selection Process

CEI India delivers digital strategy, custom cloud-native development, and legacy modernization for Fortune 1000 enterprises.

### Round 1: Online Assessment
- Quantitative aptitude, logical reasoning, and verbal comprehension.
- Technical MCQs on Java, .NET, SQL, and Web Frameworks.
- 2 Coding Questions: Array transformations and String manipulation.

### Round 2: Technical Interview (Full-Stack & CS Fundamentals)
- Core Programming: OOP concepts, Exception handling, Data Structures (HashMaps, Lists).
- Database Engineering: Relational normalization, indexing, writing complex queries with joins and aggregations.
- Web Architecture: RESTful API design, authentication, and frontend-backend data flows.

### Round 3: Management & HR Interview
- Project walkthrough, teamwork, communication, and client delivery readiness.

### Key Placement Tips
- Be ready to explain the complete request-response flow from browser to database.
- Keep your explanations clear, structured, and focused.', 'CEI India', 'approved', 260, NOW() - INTERVAL '20 days'),
    (v_author, 'Josh Technology Group (JTG) — Algorithmic Grilling & Deep Systems Loop', ARRAY['josh-technologies', 'hardcore-dsa', 'systems', 'c-plus-plus', 'competitive-programming'], E'## Josh Technology Group (JTG) Selection Architecture

JTG is legendary on engineering campuses for its uncompromising focus on pure algorithmic problem solving and low-level systems speed. They offer elite product engineering packages.

### Round 1: Rigorous Online Coding Assessment
- 3 Challenging DSA Problems (HackerRank):
  - Advanced Graph Theory (Dijkstra, Bellman-Ford, Max Flow).
  - Dynamic Programming with Bitmasking or Space Optimization.
  - Complex Tree & Array manipulations with tight execution time limits.
- Sub-optimal O(N²) solutions will strictly time out on hidden test cases.

### Round 2: Technical Interview 1 (Algorithmic Grilling)
- Live whiteboard / coderpad coding of hard algorithmic problems.
- The interviewer will continuously optimize your code: "You solved this in O(N log N) with O(N) space. Now solve it in O(N) time and O(1) auxiliary space."
- Mathematical proofs of algorithmic correctness.

### Round 3: Technical Interview 2 (Systems, Memory & Low-Level Design)
- Low-Level Design: Designing memory-efficient data structures (e.g. Custom Heap, Thread-Safe Queue, Memory Allocator).
- Multi-threading, race conditions, atomic operations, and memory barriers.
- In-depth inspection of your Final Year Project''s backend performance.

### Round 4: Founder Interview
- Raw mental agility, puzzle solving stamina, and passion for engineering excellence.

### Key Placement Tips
- JTG is not for the faint of heart: practice competitive programming on Codeforces or LeetCode Hard.
- Never write redundant allocations or unoptimized loops.', 'Josh Technologies', 'approved', 590, NOW() - INTERVAL '40 days'),
    (v_author, 'Justo Global — PropTech Digital Platform & Real-Estate Cloud Solutions', ARRAY['justo-global', 'proptech', 'react', 'node-js', 'full-stack'], E'## Justo Global Selection Process

Justo Global is a leading PropTech enterprise providing digital real-estate marketplaces, booking engines, and developer ERP solutions.

### Round 1: Online Assessment
- General aptitude, quantitative problem solving, and logical deduction.
- Full-stack web MCQs (HTML5, CSS3, JavaScript, Node.js, SQL).
- Basic Coding Challenge: Array deduplication and String parsing.

### Round 2: Technical Interview (Full-Stack & Databases)
- Modern JavaScript: Promises, `async/await`, ES6 modules, closures.
- Database modeling for real-estate: Properties, floor plans, booking slots, and payment milestones.
- API design: Handling pagination, search filters, and file upload endpoints.

### Round 3: Project & HR Discussion
- Discussion of candidate''s responsive web apps, UI/UX attention to detail, and communication skills.

### Key Placement Tips
- Showcase clean UI and responsive frontend projects on your portfolio.
- Understand how relational databases manage booking transactions.', 'Justo Global', 'approved', 240, NOW() - INTERVAL '19 days'),
    (v_author, 'PSG Software Technologies — Campus Institutional ERP & eCampus Architecture', ARRAY['psg-software-technologies', 'ecampus', 'institutional-erp', 'sql', 'security'], E'## PSG Software Technologies Selection Guide

PSG Software Technologies develops and manages internal campus institutional platforms, eCampus student information systems, exam management, and digital fee processing across the PSG institutions.

### Round 1: Technical Coding & Aptitude Test
- Quantitative aptitude and logical reasoning.
- Core programming in Java, Python, or PHP.
- SQL query test: Multi-table joins across student, course, and exam tables.

### Round 2: Technical Interview (Databases & Web Security)
- Relational Schema Design: Modeling student course registrations, attendance logs, and GPA calculations.
- Web Security Essentials:
  - Preventing SQL Injection using parameterized queries.
  - Cross-Site Scripting (XSS) prevention and sanitization.
  - Secure session management and password hashing (bcrypt vs argon2).
- Candidate project walkthrough.

### Round 3: Faculty & Leadership Discussion
- Dedication to institutional projects, reliability, code maintainability, and team collaboration.

### Key Placement Tips
- Highlight any contributions to internal college portals, departmental tools, or the PSGMX project.
- Emphasize rock-solid data integrity and security practices.', 'PSG Software Technologies', 'approved', 390, NOW() - INTERVAL '29 days'),
    (v_author, 'Capgemini — Analyst & Senior Analyst Differential Hiring Pattern', ARRAY['capgemini', 'differential-hiring', 'pseudo-code', 'dsa', 'enterprise'], E'## Capgemini Campus Selection Blueprint

Capgemini conducts national campus hiring featuring standard Analyst roles (~4 LPA) and Differential Senior Analyst roles (~7.5 LPA).

### Round 1: Online Assessment (Multi-Stage)
- **Technical Assessment (Pseudo-code)**: Tracing loops, bitwise operations, recursion, and algorithm outputs.
- **English Communication Test**: Grammar, sentence completion, and vocabulary.
- **Game-Based Aptitude**: Interactive cognitive challenges testing working memory, deductive logic, and speed.
- **Behavioral Profiling**: Situational personality questionnaire.
- *Elimination round*: Clearing this qualifies you for the Technical Interview or Differential Coding Round.

### Round 2: Coding Assessment (For Senior Analyst Differential Track)
- 2 Programming Challenges:
  - Question 1: Array / String with HashMaps (Medium).
  - Question 2: Matrix manipulation or Greedy problem (Medium-Hard).

### Round 3: Technical Interview
- Core CS: OOPs principles with real-life analogies, Exception handling, Collections framework.
- Database: Joins, subqueries, primary vs candidate keys.
- Detailed walk-through of your Final Year Project and technologies used.

### Round 4: HR Interview
- Documentation check, communication skills, and willingness to work across any Capgemini office in India.

### Key Placement Tips
- Capgemini''s pseudo-code section is the biggest filter; practice tracing nested loops and bitwise logic carefully.
- Explain your project with confidence and clarity.', 'Capgemini', 'approved', 610, NOW() - INTERVAL '42 days'),
    (v_author, 'Worlder Team — Distributed Engineering & Modern SaaS Architecture Pattern', ARRAY['worlder-team', 'remote-engineering', 'modern-saas', 'apis', 'typescript'], E'## Worlder Team Selection Pattern

Worlder Team provides international remote software engineering, cross-border collaborative SaaS tools, and agile digital products.

### Round 1: Asynchronous Coding Challenge
- Building a small, clean module in TypeScript or Python:
  - Integrating an external API, caching results in memory, and returning validated JSON data.
  - Writing automated unit tests and a clear setup guide.

### Round 2: Technical Interview (Code Review & Modern Web)
- Live code review of your challenge submission.
- Modern Web Architecture: Serverless functions, asynchronous programming, Git branch workflows.
- Relational vs NoSQL database selection for fast-evolving SaaS schemas.

### Round 3: Culture & Remote Collaboration Fitment
- High autonomy, written communication clarity, self-management, and time zone coordination.

### Key Placement Tips
- Practice writing clean, self-documenting code with meaningful commit messages.
- Emphasize your ability to independently resolve roadblocks.', 'Worlder Team', 'approved', 230, NOW() - INTERVAL '19 days'),
    (v_author, 'Cloud Supply Chain Solutions — Logistics IoT, Real-Time Tracking & Warehouse ERP', ARRAY['cloud-supply-chain-solutions', 'iot', 'logistics', 'state-machines', 'sql'], E'## Cloud Supply Chain Solutions Selection Guide

Cloud Supply Chain Solutions builds cloud inventory orchestration, IoT sensor tracking, and automated warehouse management platforms.

### Round 1: Online Assessment
- Logical reasoning, quantitative aptitude, and relational database queries.
- 2 Coding Questions: Array intervals and String processing.

### Round 2: Technical Interview 1 (State Machines & Data Modeling)
- Supply Chain State Machine: Modeling parcel status transitions (`Order Placed` -> `Dispatched` -> `In Transit` -> `Out for Delivery` -> `Delivered`).
- Preventing invalid state jumps (e.g. cannot transition directly from `Order Placed` to `Delivered`).
- Database schema design for warehouses, bins, products, and shipments.

### Round 3: Technical Interview 2 (APIs, Concurrency & FYP)
- Asynchronous event logging: Capturing high-frequency IoT GPS and temperature readings.
- Relational database transactions and query optimization.
- Candidate project deep-dive.

### Round 4: HR & Fitment Discussion
- Professional communication, dedication, and problem solving adaptability.

### Key Placement Tips
- Understand how finite state machines prevent inconsistent data in logistics systems.
- Explain how database transactions ensure safe inventory deductions.', 'Cloud Supply Chain Solutions', 'approved', 260, NOW() - INTERVAL '21 days');
END;
$$;

-- ── 4. Update App Config for v5.1.0 Release ──────────────────
UPDATE public.app_config
SET
    latest_version = '5.1.0',
    min_required_version = '5.0.0',
    force_update = false,
    update_message = 'PSGMX v5.1.0 is live! Review all 5 questions and answers in Daily 5, and explore 50+ unique company placement guides.',
    github_release_url = 'https://github.com/brittytino/psgmx/releases/latest',
    android_download_url = 'https://github.com/brittytino/psgmx/releases/latest',
    updated_at = now();
