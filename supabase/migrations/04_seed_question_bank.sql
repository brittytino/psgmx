-- ============================================================
-- PSGMX — 04_seed_question_bank.sql
-- 50 real placement-preparation questions for the Daily Five quiz.
-- Distribution: 10 aptitude, 10 verbal, 10 DSA,
--               5 DBMS, 5 OS, 5 networks, 5 OOP/Python/Java mixed
-- All questions verified for correctness.
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- APTITUDE (10 questions)
-- ──────────────────────────────────────────────────────────────

INSERT INTO question_bank (question_text, option_a, option_b, option_c, option_d, correct_option, topic, difficulty) VALUES
(
  'A train 100 m long is travelling at 60 km/h. How many seconds does it take to cross a 200 m long bridge?',
  '12 seconds', '18 seconds', '15 seconds', '10 seconds',
  'b', 'aptitude', 'medium'
),
(
  'If the ratio of two numbers is 3:5 and their LCM is 120, what is their HCF?',
  '6', '8', '10', '12',
  'b', 'aptitude', 'medium'
),
(
  'A shopkeeper marks his goods 40% above cost price and gives a 20% discount. What is his profit percentage?',
  '10%', '12%', '14%', '16%',
  'b', 'aptitude', 'medium'
),
(
  'If a = 2 and b = 3, what is the value of (a³ + b³) / (a² - ab + b²)?',
  '3', '4', '5', '6',
  'c', 'aptitude', 'easy'
),
(
  'A pipe can fill a tank in 4 hours and another pipe can empty it in 6 hours. If both are opened together, how long to fill the tank from empty?',
  '8 hours', '10 hours', '12 hours', '14 hours',
  'c', 'aptitude', 'medium'
),
(
  'What is the probability of getting a sum of 8 when two dice are rolled?',
  '5/36', '4/36', '6/36', '7/36',
  'a', 'aptitude', 'medium'
),
(
  'The average of 5 numbers is 30. If one number is excluded, the average becomes 28. What is the excluded number?',
  '38', '40', '42', '44',
  'b', 'aptitude', 'easy'
),
(
  'A can do a piece of work in 15 days and B can do it in 20 days. They work together for 6 days and then A leaves. In how many more days will B finish the remaining work?',
  '8 days', '10 days', '12 days', '14 days',
  'b', 'aptitude', 'hard'
),
(
  'What is the compound interest on Rs 8000 at 10% per annum for 2 years, compounded annually?',
  'Rs 1680', 'Rs 1600', 'Rs 1800', 'Rs 1760',
  'a', 'aptitude', 'easy'
),
(
  'If CLOCK is coded as KCOLC in a certain code, how is BRAND coded?',
  'DNARB', 'DNRAB', 'DNARB', 'BNARB',
  'a', 'aptitude', 'easy'
);

-- ──────────────────────────────────────────────────────────────
-- VERBAL (10 questions)
-- ──────────────────────────────────────────────────────────────

INSERT INTO question_bank (question_text, option_a, option_b, option_c, option_d, correct_option, topic, difficulty) VALUES
(
  'Choose the word most similar in meaning to OBSTINATE.',
  'Flexible', 'Stubborn', 'Generous', 'Timid',
  'b', 'verbal', 'easy'
),
(
  'Choose the word most opposite in meaning to EPHEMERAL.',
  'Brief', 'Temporary', 'Permanent', 'Fleeting',
  'c', 'verbal', 'medium'
),
(
  'Select the correctly spelt word.',
  'Accomodation', 'Accommodation', 'Accomadation', 'Accommdation',
  'b', 'verbal', 'easy'
),
(
  'Choose the correct word to fill in the blank: "The committee has _____ the new proposal."',
  'accepted', 'excepted', 'expected', 'accessed',
  'a', 'verbal', 'easy'
),
(
  'Identify the error in: "He is one of the student who have passed the test."',
  'He is', 'one of the', 'student who have', 'passed the test',
  'c', 'verbal', 'medium'
),
(
  'Choose the correct passive voice of: "The manager approved the request."',
  'The request has been approved by the manager.',
  'The request was approved by the manager.',
  'The request is approved by the manager.',
  'The request had been approved by the manager.',
  'b', 'verbal', 'medium'
),
(
  'Select the best synonym for AMELIORATE.',
  'Worsen', 'Improve', 'Maintain', 'Ignore',
  'b', 'verbal', 'medium'
),
(
  'Identify the correctly punctuated sentence.',
  'Its a lovely day isnt it?',
  'It''s a lovely day, isn''t it?',
  'Its a lovely day, isnt it?',
  'It''s a lovely day isnt it?',
  'b', 'verbal', 'easy'
),
(
  'Choose the word that best completes the analogy: Doctor : Hospital :: Teacher : ?',
  'Books', 'School', 'Student', 'Learning',
  'b', 'verbal', 'easy'
),
(
  'Which part of the following sentence contains an error? "Neither the manager nor the employees was present at the meeting."',
  'Neither the manager', 'nor the employees', 'was present', 'at the meeting',
  'c', 'verbal', 'medium'
);

-- ──────────────────────────────────────────────────────────────
-- DSA — Data Structures and Algorithms (10 questions)
-- ──────────────────────────────────────────────────────────────

INSERT INTO question_bank (question_text, option_a, option_b, option_c, option_d, correct_option, topic, difficulty) VALUES
(
  'What is the time complexity of binary search on a sorted array of n elements?',
  'O(n)', 'O(log n)', 'O(n log n)', 'O(1)',
  'b', 'dsa', 'easy'
),
(
  'Which data structure is used by a function call stack?',
  'Queue', 'Stack', 'Heap', 'Tree',
  'b', 'dsa', 'easy'
),
(
  'What is the worst-case time complexity of QuickSort?',
  'O(n log n)', 'O(n²)', 'O(n)', 'O(log n)',
  'b', 'dsa', 'medium'
),
(
  'In a binary search tree, an in-order traversal yields:',
  'Elements in random order', 'Elements in sorted ascending order', 'Elements in sorted descending order', 'Root first, then leaves',
  'b', 'dsa', 'easy'
),
(
  'What is the space complexity of merge sort?',
  'O(1)', 'O(log n)', 'O(n)', 'O(n²)',
  'c', 'dsa', 'medium'
),
(
  'Given a graph with V vertices and E edges, what is the time complexity of Breadth-First Search (BFS)?',
  'O(V)', 'O(E)', 'O(V + E)', 'O(V × E)',
  'c', 'dsa', 'medium'
),
(
  'Which algorithm is used to find the shortest path in a weighted graph with non-negative edges?',
  'BFS', 'DFS', 'Dijkstra''s', 'Bellman-Ford',
  'c', 'dsa', 'medium'
),
(
  'What is the maximum number of nodes at level k in a binary tree (root is at level 0)?',
  'k', '2k', '2^k', 'k²',
  'c', 'dsa', 'medium'
),
(
  'Which of the following is NOT a property of a min-heap?',
  'The root has the minimum value', 'It is a complete binary tree', 'Every parent node is smaller than its children', 'In-order traversal gives sorted output',
  'd', 'dsa', 'hard'
),
(
  'What is the amortized time complexity of a push operation on a dynamic array (e.g., Python list)?',
  'O(n)', 'O(log n)', 'O(1)', 'O(n²)',
  'c', 'dsa', 'hard'
);

-- ──────────────────────────────────────────────────────────────
-- DBMS — Database Management Systems (5 questions)
-- ──────────────────────────────────────────────────────────────

INSERT INTO question_bank (question_text, option_a, option_b, option_c, option_d, correct_option, topic, difficulty) VALUES
(
  'Which normal form eliminates transitive functional dependencies?',
  '1NF', '2NF', '3NF', 'BCNF',
  'c', 'dbms', 'medium'
),
(
  'What does ACID stand for in database transactions?',
  'Atomicity, Consistency, Isolation, Durability', 'Availability, Consistency, Integrity, Durability', 'Atomicity, Concurrency, Isolation, Dependency', 'Availability, Concurrency, Integrity, Dependency',
  'a', 'dbms', 'easy'
),
(
  'In SQL, which clause is used to filter groups after a GROUP BY?',
  'WHERE', 'FILTER', 'HAVING', 'ORDER BY',
  'c', 'dbms', 'easy'
),
(
  'What type of join returns all records from the left table and matched records from the right table?',
  'INNER JOIN', 'RIGHT JOIN', 'LEFT JOIN', 'FULL OUTER JOIN',
  'c', 'dbms', 'easy'
),
(
  'Which index type is best suited for range queries (e.g., price BETWEEN 100 AND 500)?',
  'Hash Index', 'B-Tree Index', 'Bitmap Index', 'Full-text Index',
  'b', 'dbms', 'medium'
);

-- ──────────────────────────────────────────────────────────────
-- OS — Operating Systems (5 questions)
-- ──────────────────────────────────────────────────────────────

INSERT INTO question_bank (question_text, option_a, option_b, option_c, option_d, correct_option, topic, difficulty) VALUES
(
  'Which CPU scheduling algorithm can cause starvation?',
  'Round Robin', 'FCFS', 'Priority Scheduling', 'Shortest Job First (preemptive)',
  'c', 'os', 'medium'
),
(
  'What is a deadlock? Choose the most accurate definition.',
  'A process waiting for user input', 'A circular wait where each process holds a resource needed by the next', 'A process consuming 100% CPU', 'Two processes sharing the same memory page',
  'b', 'os', 'easy'
),
(
  'Which page replacement algorithm replaces the page that will not be used for the longest time in the future?',
  'FIFO', 'LRU', 'Optimal (OPT)', 'Clock',
  'c', 'os', 'medium'
),
(
  'What is the purpose of the Translation Lookaside Buffer (TLB)?',
  'To store recently used disk blocks', 'To cache recent virtual-to-physical address translations', 'To manage the process control block', 'To buffer I/O operations',
  'b', 'os', 'medium'
),
(
  'In Unix/Linux, what system call creates a new process?',
  'exec()', 'spawn()', 'fork()', 'create()',
  'c', 'os', 'easy'
);

-- ──────────────────────────────────────────────────────────────
-- NETWORKS — Computer Networks (5 questions)
-- ──────────────────────────────────────────────────────────────

INSERT INTO question_bank (question_text, option_a, option_b, option_c, option_d, correct_option, topic, difficulty) VALUES
(
  'Which OSI layer is responsible for end-to-end communication and reliability?',
  'Network Layer', 'Data Link Layer', 'Transport Layer', 'Session Layer',
  'c', 'networks', 'easy'
),
(
  'What is the default port number for HTTPS?',
  '80', '8080', '443', '8443',
  'c', 'networks', 'easy'
),
(
  'Which protocol is used to map IP addresses to MAC addresses?',
  'DNS', 'DHCP', 'ARP', 'RARP',
  'c', 'networks', 'medium'
),
(
  'In TCP, what is the purpose of the three-way handshake?',
  'To encrypt the connection', 'To authenticate the user', 'To establish a reliable connection between client and server', 'To compress data before transmission',
  'c', 'networks', 'medium'
),
(
  'What does CIDR notation /24 mean in 192.168.1.0/24?',
  '24 available host addresses', 'The first 24 bits are the network portion', '24 subnets available', 'The last 24 bits are the network portion',
  'b', 'networks', 'medium'
);

-- ──────────────────────────────────────────────────────────────
-- OOP / Python / Java mixed (5 questions)
-- ──────────────────────────────────────────────────────────────

INSERT INTO question_bank (question_text, option_a, option_b, option_c, option_d, correct_option, topic, difficulty) VALUES
(
  'In Python, what is the output of: print(type(5/2))?',
  '<class ''int''>', '<class ''float''>', '<class ''double''>', '<class ''number''>',
  'b', 'python', 'easy'
),
(
  'Which OOP principle describes the ability of a method to behave differently based on the object calling it?',
  'Encapsulation', 'Abstraction', 'Inheritance', 'Polymorphism',
  'd', 'oop', 'easy'
),
(
  'In Java, which keyword is used to prevent a method from being overridden by a subclass?',
  'static', 'abstract', 'final', 'private',
  'c', 'java', 'medium'
),
(
  'What is the difference between == and .equals() in Java when comparing Strings?',
  'No difference — both compare character content', '== compares object references; .equals() compares character content', '== compares character content; .equals() compares references', '.equals() is deprecated in Java 17+',
  'b', 'java', 'medium'
),
(
  'In Python, what is a decorator?',
  'A design pattern for adding a border to widgets', 'A function that wraps another function to modify its behaviour', 'A type of class that inherits from multiple parents', 'A special comment used for documentation',
  'b', 'python', 'medium'
);
