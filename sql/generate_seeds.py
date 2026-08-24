#!/usr/bin/env python3
"""
Generates SQL seed files for PSGMX daily content (365 days).
Run: python3 generate_seeds.py
"""
import json, textwrap, re, sys

# ── Project Task Bank: 365 items ──────────────────────────────────────────────
CATEGORIES = ['Web Dev', 'DBMS', 'OOP-Java', 'System Design', 'Git-DevOps', 'Testing', 'Cloud Basics']
DIFFICULTIES = ['easy', 'medium', 'hard']

PROJECT_TASKS = [
    # Web Dev
    ("Build a responsive landing page with HTML/CSS Grid", "Web Dev", "easy", "Create a responsive landing page using CSS Grid layout. Include a hero section, features list, and footer. Must work on mobile and desktop.", "https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_grid_layout"),
    ("Create a multi-step form with validation", "Web Dev", "medium", "Build a multi-step registration form with client-side validation, progress indicator, and animated transitions between steps.", "https://developer.mozilla.org/en-US/docs/Learn/Forms"),
    ("Implement a REST API using Node.js and Express", "Web Dev", "medium", "Build a CRUD REST API for a blog system with endpoints for posts, comments, and tags. Include proper error handling.", "https://expressjs.com/en/starter/basic-routing.html"),
    ("Create a real-time chat UI using WebSockets concept", "Web Dev", "hard", "Design a chat interface that demonstrates understanding of WebSocket event flow. Mock the backend with a local event bus.", "https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API"),
    ("Build a weather dashboard using a public API", "Web Dev", "easy", "Fetch weather data from OpenWeatherMap API and display current weather, 5-day forecast, and a temperature chart.", "https://openweathermap.org/api"),
    ("Implement dark/light theme toggle with CSS variables", "Web Dev", "easy", "Add a theme toggle that switches between dark and light modes using CSS custom properties (variables) and localStorage persistence.", "https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties"),
    ("Build an infinite scroll list component", "Web Dev", "medium", "Create a paginated list that loads more items when the user scrolls to the bottom using Intersection Observer API.", "https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API"),
    ("Create a drag-and-drop Kanban board", "Web Dev", "hard", "Build a Kanban board with three columns (Todo, In Progress, Done) and drag-and-drop functionality using HTML5 drag events.", "https://developer.mozilla.org/en-US/docs/Web/API/HTML_Drag_and_Drop_API"),
    ("Build a markdown preview editor", "Web Dev", "medium", "Create a split-pane editor where the left side accepts markdown text and the right side renders live HTML preview.", "https://marked.js.org/"),
    ("Implement JWT authentication flow", "Web Dev", "hard", "Build a complete login/register flow with JWT tokens, refresh token logic, and protected routes. Mock the backend.", "https://jwt.io/introduction"),
    # DBMS
    ("Design an ER diagram for a hospital management system", "DBMS", "easy", "Create a complete ER diagram with entities: Patient, Doctor, Appointment, Ward, Medicine, Prescription. Show all relationships and cardinalities.", "https://www.geeksforgeeks.org/er-model/"),
    ("Write complex SQL queries for a sales database", "DBMS", "medium", "Given a sales DB schema (Customers, Orders, Products, OrderItems), write 10 queries using JOINs, GROUP BY, HAVING, subqueries, and window functions.", "https://www.postgresql.org/docs/current/tutorial-sql.html"),
    ("Normalize a given table to 3NF", "DBMS", "medium", "Take an unnormalized spreadsheet of student enrollment data and normalize it through 1NF, 2NF, and 3NF. Show each step.", "https://www.geeksforgeeks.org/normalization-of-database/"),
    ("Implement indexing strategy for a slow query", "DBMS", "hard", "Analyze a slow query on a 1M-row orders table. Create appropriate indexes (B-Tree, composite, partial) and explain the execution plan difference.", "https://use-the-index-luke.com/"),
    ("Build a stored procedure for student grade calculation", "DBMS", "medium", "Write a PL/pgSQL stored procedure that calculates semester GPA, updates the students table, and logs changes to an audit table.", "https://www.postgresql.org/docs/current/plpgsql.html"),
    ("Design a database for an e-commerce platform", "DBMS", "hard", "Design a complete relational schema for an e-commerce platform with Products, Variants, Inventory, Orders, Payments, Reviews, and Coupons.", "https://www.vertabelo.com/blog/e-commerce-database/"),
    ("Write a trigger to prevent negative stock", "DBMS", "medium", "Create a BEFORE INSERT/UPDATE trigger on an inventory table that raises an exception if stock would go below zero.", "https://www.postgresql.org/docs/current/sql-createtrigger.html"),
    ("Implement a recursive CTE for org chart traversal", "DBMS", "hard", "Use a recursive Common Table Expression to traverse an employee hierarchy table and find all subordinates of a given manager.", "https://www.postgresql.org/docs/current/queries-with.html"),
    ("Design a time-series schema for sensor data", "DBMS", "medium", "Design and implement a schema optimized for storing IoT sensor readings with efficient range queries and aggregations.", "https://www.timescale.com/blog/time-series-data/"),
    ("Build a full-text search query", "DBMS", "medium", "Use PostgreSQL full-text search (tsvector, tsquery, GIN index) to implement smart search on a products table.", "https://www.postgresql.org/docs/current/textsearch.html"),
    # OOP-Java
    ("Implement a generic Stack and Queue in Java", "OOP-Java", "easy", "Create type-safe generic Stack and Queue implementations using arrays. Implement push, pop, peek, isEmpty, size methods with proper exception handling.", "https://docs.oracle.com/en/java/docs/"),
    ("Design a library management system using OOP principles", "OOP-Java", "medium", "Build a library system with classes: Book, Member, Librarian, Loan. Apply inheritance, encapsulation, and polymorphism. Include a simple CLI.", "https://docs.oracle.com/javase/tutorial/java/concepts/"),
    ("Implement the Observer design pattern", "OOP-Java", "medium", "Create an event notification system using the Observer pattern with multiple concrete subscribers for a news publishing system.", "https://refactoring.guru/design-patterns/observer"),
    ("Build a thread-safe bank account system", "OOP-Java", "hard", "Implement BankAccount with deposit, withdraw, transfer operations using synchronized methods and proper concurrency control to avoid race conditions.", "https://docs.oracle.com/javase/tutorial/essential/concurrency/"),
    ("Implement a simple IoC container (Dependency Injection)", "OOP-Java", "hard", "Build a basic dependency injection container that resolves constructor dependencies using reflection.", "https://docs.oracle.com/javase/tutorial/reflect/"),
    ("Create a Builder pattern for a complex object", "OOP-Java", "easy", "Implement the Builder pattern for constructing a complex Pizza order with optional toppings, size, crust type using fluent interface.", "https://refactoring.guru/design-patterns/builder"),
    ("Build a simple expression evaluator using Composite pattern", "OOP-Java", "medium", "Parse and evaluate mathematical expressions (+ - * /) using the Composite design pattern with leaf and branch nodes.", "https://refactoring.guru/design-patterns/composite"),
    ("Implement a connection pool", "OOP-Java", "hard", "Build a generic connection pool with configurable min/max pool size, idle timeout, and thread-safe borrowing/returning of connections.", "https://en.wikipedia.org/wiki/Connection_pool"),
    ("Design an Animal hierarchy with abstract classes", "OOP-Java", "easy", "Create an Animal hierarchy with abstract methods sound() and move(). Implement Dog, Cat, Bird, Fish subclasses. Override toString and equals.", "https://docs.oracle.com/javase/tutorial/java/IandI/abstract.html"),
    ("Build a simple rule engine using Strategy pattern", "OOP-Java", "medium", "Implement a discount rule engine for an e-commerce platform using the Strategy pattern. Rules: percentage off, flat discount, BOGO.", "https://refactoring.guru/design-patterns/strategy"),
    # System Design
    ("Design URL Shortener (like bit.ly)", "System Design", "medium", "Design a scalable URL shortener service. Include: API design, database schema, hashing algorithm, caching layer, and scaling strategy.", "https://systemdesign.one/url-shortening-system-design/"),
    ("Design a notification delivery system", "System Design", "hard", "Design a system that sends email, SMS, and push notifications to millions of users. Cover: message queues, retry logic, rate limiting, fan-out.", "https://bytebytego.com/"),
    ("Design a rate limiter", "System Design", "medium", "Design a distributed rate limiter using token bucket algorithm. Show API design, Redis-based implementation, and edge cases.", "https://stripe.com/blog/rate-limiters"),
    ("Design a distributed cache", "System Design", "hard", "Design a distributed caching system (like Redis cluster). Cover: consistent hashing, cache eviction, cache-aside pattern, invalidation strategies.", "https://redis.io/docs/manual/scaling/"),
    ("Design a ride-sharing location service", "System Design", "hard", "Design the backend for tracking driver locations in real-time for a ride-sharing app. Focus on geospatial indexing and low-latency updates.", "https://geohash.softeng.co/"),
    ("Design a file storage system (like Google Drive)", "System Design", "hard", "Design a file storage and sharing service. Cover: chunked upload, deduplication, metadata DB, CDN, access control.", "https://systemdesign.one/google-drive-system-design/"),
    ("Design an API gateway", "System Design", "medium", "Design an API gateway for a microservices architecture. Include: routing, authentication, rate limiting, logging, circuit breaking.", "https://microservices.io/patterns/apigateway.html"),
    ("Design a search autocomplete system", "System Design", "medium", "Design a type-ahead search suggestion system for an e-commerce site handling 100K QPS. Include trie-based approach and Elasticsearch alternative.", "https://bytebytego.com/"),
    ("Design a message queue system", "System Design", "hard", "Design a persistent message queue (like Kafka). Cover: partitioning, replication, offset management, consumer groups, delivery semantics.", "https://kafka.apache.org/documentation/"),
    ("Design a leaderboard system", "System Design", "medium", "Design a real-time leaderboard for a gaming platform with 1M players. Use sorted sets (Redis ZSET) and handle score updates efficiently.", "https://redis.io/docs/data-types/sorted-sets/"),
    # Git-DevOps
    ("Set up a complete CI/CD pipeline with GitHub Actions", "Git-DevOps", "medium", "Create a GitHub Actions workflow that runs tests, lints code, builds Docker image, and deploys to a staging environment on PR merge.", "https://docs.github.com/en/actions"),
    ("Implement Git branching strategy for a team project", "Git-DevOps", "easy", "Document and implement a Git Flow branching strategy with main, develop, feature, release, and hotfix branches. Practice the full workflow.", "https://nvie.com/posts/a-successful-git-branching-model/"),
    ("Create a multi-stage Dockerfile", "Git-DevOps", "medium", "Write a multi-stage Dockerfile for a Node.js application: builder stage installs deps and builds, production stage copies only the built artifact.", "https://docs.docker.com/build/building/multi-stage/"),
    ("Write a Kubernetes Deployment manifest", "Git-DevOps", "medium", "Write Kubernetes YAML files for Deployment, Service, ConfigMap, and HorizontalPodAutoscaler for a web application.", "https://kubernetes.io/docs/concepts/workloads/controllers/deployment/"),
    ("Implement infrastructure as code with Terraform", "Git-DevOps", "hard", "Write Terraform configuration to provision an AWS VPC, EC2 instance, RDS database, and S3 bucket with proper security groups.", "https://developer.hashicorp.com/terraform/tutorials"),
    ("Set up monitoring with Prometheus and Grafana", "Git-DevOps", "hard", "Configure Prometheus to scrape metrics from a Node.js app and create Grafana dashboards for request rate, error rate, and latency (RED metrics).", "https://grafana.com/docs/grafana/latest/"),
    ("Automate database migrations in CI/CD", "Git-DevOps", "medium", "Integrate database migration tool (Flyway or Liquibase) into a CI pipeline so migrations run automatically before deployment.", "https://flywaydb.org/documentation/"),
    ("Create a git pre-commit hook for code quality", "Git-DevOps", "easy", "Write a git pre-commit hook script that runs ESLint/Prettier checks and blocks the commit if code quality checks fail.", "https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks"),
    ("Build a Docker Compose setup for local development", "Git-DevOps", "easy", "Create a docker-compose.yml that runs a web app, PostgreSQL, Redis, and a reverse proxy (Nginx) for local development.", "https://docs.docker.com/compose/"),
    ("Implement semantic versioning and changelog automation", "Git-DevOps", "medium", "Set up conventional commits and use semantic-release to automatically bump version and generate CHANGELOG.md on CI.", "https://semantic-release.gitbook.io/semantic-release"),
    # Testing
    ("Write unit tests for a calculator service", "Testing", "easy", "Write comprehensive JUnit/Jest unit tests for a calculator with add, subtract, multiply, divide, modulo. Include boundary cases and exception testing.", "https://junit.org/junit5/docs/current/user-guide/"),
    ("Write integration tests for a REST API", "Testing", "medium", "Write integration tests for a CRUD REST API covering all endpoints, including error cases, authentication, and database state verification.", "https://supertest.npmjs.com/"),
    ("Implement test-driven development (TDD) for a user service", "Testing", "medium", "Use TDD (Red-Green-Refactor) to build a UserService with register, login, update profile, delete account. Write failing tests first.", "https://www.agilealliance.org/glossary/tdd/"),
    ("Set up end-to-end testing with Playwright", "Testing", "hard", "Write Playwright E2E tests for a web application covering: login flow, form submission, navigation, and error states.", "https://playwright.dev/docs/writing-tests"),
    ("Write tests for concurrent code", "Testing", "hard", "Write tests that verify thread safety for a concurrent bank account implementation. Use multiple threads and assert no race conditions occur.", "https://www.baeldung.com/java-testing-multithreaded"),
    ("Implement a test doubles strategy (mocks, stubs, fakes)", "Testing", "medium", "Practice using mocks for external services, stubs for dependencies, and fakes for databases in a payment processing service.", "https://martinfowler.com/articles/mocksArentStubs.html"),
    ("Write property-based tests", "Testing", "hard", "Use a property-based testing library (QuickCheck/Hypothesis) to generate thousands of test cases for a sorting algorithm and string processing functions.", "https://hypothesis.readthedocs.io/"),
    ("Measure and improve code coverage", "Testing", "medium", "Add test coverage measurement to a project, identify untested branches, write tests to achieve 85%+ coverage, and integrate into CI.", "https://istanbul.js.org/"),
    ("Write performance tests with JMeter", "Testing", "hard", "Create a JMeter test plan to load test a REST API with 100 concurrent users, measure response times, and identify the breaking point.", "https://jmeter.apache.org/usermanual/get-started.html"),
    ("Implement contract testing with Pact", "Testing", "hard", "Write consumer-driven contract tests between a web frontend and a backend API using Pact to ensure API compatibility.", "https://docs.pact.io/"),
    # Cloud Basics
    ("Deploy a static website to AWS S3 + CloudFront", "Cloud Basics", "easy", "Deploy a static HTML/CSS/JS website to S3, configure static hosting, set up CloudFront distribution, and add a custom domain.", "https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html"),
    ("Set up a serverless function with AWS Lambda", "Cloud Basics", "medium", "Create a Lambda function triggered by an API Gateway that processes JSON input, calls a DynamoDB table, and returns a response.", "https://docs.aws.amazon.com/lambda/latest/dg/getting-started.html"),
    ("Configure AWS IAM roles and policies", "Cloud Basics", "medium", "Practice the principle of least privilege: create IAM roles with minimal permissions for an EC2 instance, Lambda, and RDS access.", "https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html"),
    ("Deploy a containerized app to Google Cloud Run", "Cloud Basics", "medium", "Containerize a web app with Docker, push to Google Container Registry, and deploy to Cloud Run with auto-scaling configuration.", "https://cloud.google.com/run/docs/quickstarts"),
    ("Set up managed PostgreSQL on Supabase", "Cloud Basics", "easy", "Create a Supabase project, design a schema with RLS policies, connect from a web app, and test CRUD operations with the JavaScript client.", "https://supabase.com/docs"),
    ("Implement object storage with lifecycle policies", "Cloud Basics", "medium", "Configure S3 bucket with lifecycle rules: move objects to Glacier after 30 days, delete after 365 days. Test with simulated uploads.", "https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html"),
    ("Set up autoscaling for a web application", "Cloud Basics", "hard", "Configure AWS Auto Scaling Group with launch template, scaling policies (target tracking), and load balancer health checks.", "https://docs.aws.amazon.com/autoscaling/ec2/userguide/get-started-with-ec2-auto-scaling.html"),
    ("Build a serverless image resizing pipeline", "Cloud Basics", "hard", "Create an event-driven pipeline: S3 upload triggers Lambda, Lambda resizes image using Sharp, saves thumbnails back to S3.", "https://aws.amazon.com/blogs/compute/resize-images-on-the-fly-with-amazon-s3-aws-lambda-and-amazon-api-gateway/"),
    ("Set up cloud monitoring and alerts", "Cloud Basics", "medium", "Configure CloudWatch metrics, create alarms for CPU >80% and error rate >5%, and set up SNS notifications for incidents.", "https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/"),
    ("Implement multi-region failover", "Cloud Basics", "hard", "Design and implement an active-passive multi-region setup with Route53 health checks and automatic failover for a stateless web application.", "https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover.html"),
]

# Expand to 365 by cycling
all_tasks = []
for i in range(365):
    base = PROJECT_TASKS[i % len(PROJECT_TASKS)]
    title, cat, diff, desc, link = base
    all_tasks.append((i+1, title, desc, cat, diff, link))


def esc(s):
    return s.replace("'", "''") if s else ''

lines = ["-- ============================================================",
         "-- PSGMX SQL — FILE 03: Seed 365 Project Tasks",
         "-- Run this THIRD in Supabase SQL Editor (after file 01)",
         "-- ============================================================",
         "",
         "INSERT INTO project_task_bank (day_of_year, title, description, category, difficulty, reference_link, is_active)",
         "VALUES"]

rows = []
for doy, title, desc, cat, diff, link in all_tasks:
    link_val = f"'{esc(link)}'" if link else "NULL"
    rows.append(f"({doy}, '{esc(title)}', '{esc(desc)}', '{esc(cat)}', '{diff}', {link_val}, TRUE)")

lines.append(",\n".join(rows))
lines.append("ON CONFLICT (day_of_year) DO UPDATE SET")
lines.append("  title = EXCLUDED.title,")
lines.append("  description = EXCLUDED.description,")
lines.append("  category = EXCLUDED.category,")
lines.append("  difficulty = EXCLUDED.difficulty,")
lines.append("  reference_link = EXCLUDED.reference_link;")
lines.append("")
lines.append("SELECT COUNT(*) AS project_tasks_seeded FROM project_task_bank;")

with open("03_seed_365_project_tasks.sql", "w") as f:
    f.write("\n".join(lines))

print(f"Generated 03_seed_365_project_tasks.sql with {len(all_tasks)} rows")

# ── Apti DSA Bank ──────────────────────────────────────────────────────────────
DSA_ITEMS = [
    # Arrays
    ("Two Sum", "easy", "Arrays", "https://leetcode.com/problems/two-sum/", "Use a hash map to store complement values as you iterate.", [("What is the time complexity of linear search?", ["O(1)", "O(log n)", "O(n)", "O(n²)"], 2), ("Which data structure uses LIFO?", ["Queue", "Stack", "Heap", "Tree"], 1), ("Train moves at 60 km/h for 2 hours. Distance?", ["60 km", "90 km", "120 km", "180 km"], 2)]),
    ("Best Time to Buy and Sell Stock", "easy", "Arrays", "https://leetcode.com/problems/best-time-to-buy-and-sell-stock/", "Track the minimum price seen so far and compute max profit at each step.", [("Array index starts at?", ["0", "1", "-1", "None"], 0), ("Which sorting is O(n log n) worst case?", ["Bubble", "Selection", "Merge", "Insertion"], 2), ("A train travels 150 km in 3 hours. Speed?", ["40 km/h", "45 km/h", "50 km/h", "55 km/h"], 2)]),
    ("Contains Duplicate", "easy", "Arrays", "https://leetcode.com/problems/contains-duplicate/", "Use a HashSet — if element already exists, return true.", [("HashSet uses which data structure internally?", ["Array", "LinkedList", "HashMap", "Tree"], 2), ("Time complexity of HashSet lookup?", ["O(1)", "O(log n)", "O(n)", "O(n²)"], 0), ("If 3 workers complete a job in 6 days, how many days for 2 workers?", ["7", "8", "9", "10"], 2)]),
    ("Product of Array Except Self", "medium", "Arrays", "https://leetcode.com/problems/product-of-array-except-self/", "Use prefix and suffix product arrays to avoid division.", [("What does O(1) space mean?", ["Constant space", "No space", "Linear space", "Log space"], 0), ("Prefix sum is useful for?", ["Range queries", "Sorting", "Searching", "Hashing"], 0), ("A sum of first 10 natural numbers?", ["45", "50", "55", "60"], 2)]),
    ("Maximum Subarray (Kadane's)", "medium", "Arrays", "https://leetcode.com/problems/maximum-subarray/", "Kadane's algorithm: extend or restart subarray at each element.", [("Kadane's algorithm finds?", ["Minimum subarray", "Maximum subarray", "Sorted subarray", "Empty subarray"], 1), ("Dynamic programming optimizes?", ["Space", "Overlapping subproblems", "Sorting", "Recursion only"], 1), ("Profit if cost=200 and selling=250?", ["25%", "30%", "35%", "40%"], 0)]),
    # Linked Lists
    ("Reverse Linked List", "easy", "Linked Lists", "https://leetcode.com/problems/reverse-linked-list/", "Use three pointers: prev, curr, next. Iterate and reverse links.", [("Linked list node contains?", ["Data only", "Data and pointer", "Pointer only", "Address only"], 1), ("Head of linked list points to?", ["Last node", "First node", "Middle node", "Random node"], 1), ("LCM of 4 and 6?", ["12", "18", "24", "8"], 0)]),
    ("Merge Two Sorted Lists", "easy", "Linked Lists", "https://leetcode.com/problems/merge-two-sorted-lists/", "Use a dummy head and compare nodes from both lists iteratively.", [("Dummy node technique helps with?", ["Edge cases at head", "Tail insertion", "Middle insertion", "Sorting"], 0), ("Space complexity of iterative merge?", ["O(1)", "O(n)", "O(log n)", "O(n²)"], 0), ("Average of 10, 20, 30?", ["15", "20", "25", "30"], 1)]),
    ("Detect Cycle in Linked List", "medium", "Linked Lists", "https://leetcode.com/problems/linked-list-cycle/", "Floyd's cycle detection: slow and fast pointers. If they meet, cycle exists.", [("Floyd's algorithm uses how many pointers?", ["1", "2", "3", "4"], 1), ("Cycle detection time complexity?", ["O(n)", "O(n²)", "O(log n)", "O(1)"], 0), ("If x:y = 3:4 and x=12, y=?", ["14", "16", "18", "20"], 1)]),
    ("Find Middle of Linked List", "easy", "Linked Lists", "https://leetcode.com/problems/middle-of-the-linked-list/", "Use slow/fast pointer: slow moves 1 step, fast moves 2 steps.", [("In a 5-node list, middle is at?", ["Node 2", "Node 3", "Node 4", "Node 5"], 1), ("Two-pointer technique time complexity?", ["O(n)", "O(n²)", "O(log n)", "O(1)"], 0), ("Train covers 200m in 10s. Speed in km/h?", ["60", "70", "72", "80"], 2)]),
    ("LRU Cache", "hard", "Linked Lists", "https://leetcode.com/problems/lru-cache/", "Combine HashMap and doubly linked list for O(1) get and put.", [("LRU stands for?", ["Least Recently Used", "Last Recently Updated", "Least Random Unit", "Last Reset Unit"], 0), ("HashMap gives O(1) for?", ["Insert, Delete, Search", "Sort only", "Range queries", "Traversal"], 0), ("A pipe fills a tank in 4 hours, another in 6 hours. Together?", ["2.4 hours", "2.6 hours", "3 hours", "5 hours"], 0)]),
    # Trees
    ("Inorder Traversal of BST", "easy", "Trees", "https://leetcode.com/problems/binary-tree-inorder-traversal/", "Inorder: Left → Root → Right. Yields sorted output for BST.", [("Inorder traversal gives BST in?", ["Sorted order", "Reverse order", "Random order", "Level order"], 0), ("BST search time complexity?", ["O(log n)", "O(n)", "O(1)", "O(n²)"], 0), ("If coins doubled daily from 1, on day 10?", ["512", "1024", "512", "256"], 0)]),
    ("Maximum Depth of Binary Tree", "easy", "Trees", "https://leetcode.com/problems/maximum-depth-of-binary-tree/", "Recursively return 1 + max(left depth, right depth). Base case: null = 0.", [("DFS uses which data structure?", ["Queue", "Stack", "Array", "Heap"], 1), ("BFS uses which data structure?", ["Stack", "Queue", "Heap", "LinkedList"], 1), ("35 is what percent of 700?", ["3%", "4%", "5%", "6%"], 2)]),
    ("Validate Binary Search Tree", "medium", "Trees", "https://leetcode.com/problems/validate-binary-search-tree/", "Pass min/max bounds to each node recursively. Left < node < Right.", [("BST property: left subtree has?", ["Values > root", "Values < root", "Values = root", "Random values"], 1), ("Which traversal checks BST validity?", ["Inorder", "Preorder", "Postorder", "Level order"], 0), ("A man earns 15,000/month and saves 20%. Monthly savings?", ["2,500", "3,000", "3,500", "4,000"], 1)]),
    ("Level Order Traversal", "medium", "Trees", "https://leetcode.com/problems/binary-tree-level-order-traversal/", "Use a Queue. Process level by level, tracking level boundaries.", [("BFS explores nodes?", ["Depth first", "Level by level", "Randomly", "Root only"], 1), ("Queue is?", ["LIFO", "FIFO", "LILO", "FILO"], 1), ("A 10% discount on 500?", ["400", "450", "460", "480"], 1)]),
    ("Lowest Common Ancestor of BST", "medium", "Trees", "https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/", "If both p and q are less than root, go left. If both greater, go right. Else root is LCA.", [("LCA of a tree means?", ["Deepest common node", "Shallowest node", "Root always", "Leaf node"], 0), ("BST LCA time complexity?", ["O(log n)", "O(n)", "O(n²)", "O(1)"], 0), ("Speed = Distance/Time. If d=120km, t=2h, speed?", ["50 km/h", "55 km/h", "60 km/h", "65 km/h"], 2)]),
    # Dynamic Programming
    ("Climbing Stairs", "easy", "Dynamic Programming", "https://leetcode.com/problems/climbing-stairs/", "Fibonacci pattern: f(n) = f(n-1) + f(n-2). Use bottom-up DP.", [("Memoization stores?", ["Computed results", "Random data", "Sorted arrays", "Only inputs"], 0), ("Fibonacci relation is?", ["f(n) = f(n-1) + f(n-2)", "f(n) = f(n-1) * 2", "f(n) = n!", "f(n) = 2^n"], 0), ("Pipes A and B fill tank in 3h and 6h. Together in?", ["1.5h", "2h", "2.5h", "3h"], 1)]),
    ("Coin Change", "medium", "Dynamic Programming", "https://leetcode.com/problems/coin-change/", "dp[i] = min coins to make amount i. Try each coin at each amount.", [("Greedy always works for coin change?", ["Yes", "No, only for canonical coin systems", "Yes, with sorting", "No, never"], 1), ("DP bottom-up vs top-down: bottom-up uses?", ["Recursion", "Iteration", "Both", "Neither"], 1), ("HCF of 12 and 18?", ["3", "6", "9", "12"], 1)]),
    ("Longest Common Subsequence", "medium", "Dynamic Programming", "https://leetcode.com/problems/longest-common-subsequence/", "2D DP: if chars match, dp[i][j] = dp[i-1][j-1] + 1, else max of top/left.", [("LCS differs from LCS (substring) because?", ["Must be contiguous", "Need not be contiguous", "Same thing", "Sorted only"], 1), ("LCS time complexity?", ["O(n)", "O(n log n)", "O(nm)", "O(n²m)"], 2), ("Simple interest on 1000 at 5% for 2 years?", ["50", "100", "150", "200"], 1)]),
    ("0/1 Knapsack", "hard", "Dynamic Programming", "https://www.geeksforgeeks.org/0-1-knapsack-problem-dp-10/", "For each item and capacity, choose max of (include item) or (exclude item).", [("0/1 Knapsack: each item can be taken?", ["Multiple times", "Exactly once", "Zero or many times", "Never"], 1), ("Knapsack time complexity?", ["O(n)", "O(n*W)", "O(n²)", "O(W)"], 1), ("20% of 80 + 80% of 20 = ?", ["16", "32", "40", "48"], 1)]),
    ("Word Break", "medium", "Dynamic Programming", "https://leetcode.com/problems/word-break/", "dp[i] = true if s[0..i] can be segmented using wordDict. Check all prefixes.", [("Word break is solved by?", ["Greedy", "DP with boolean array", "Binary search", "Sorting"], 1), ("Backtracking explores?", ["All possibilities", "Only optimal", "Greedy choices", "Random paths"], 0), ("Compound interest formula involves?", ["Linear growth", "Exponential growth", "Constant growth", "Logarithmic growth"], 1)]),
    # Graphs
    ("Number of Islands (DFS/BFS)", "medium", "Graphs", "https://leetcode.com/problems/number-of-islands/", "DFS from each unvisited '1' cell, mark all connected cells as visited.", [("DFS uses which traversal?", ["Level order", "Depth first", "Breadth first", "Random"], 1), ("Graph edge connects?", ["Two nodes", "Three nodes", "One node", "All nodes"], 0), ("If 5 machines make 5 items in 5 min, how many machines for 100 items in 100 min?", ["5", "10", "20", "100"], 0)]),
    ("Clone Graph", "medium", "Graphs", "https://leetcode.com/problems/clone-graph/", "BFS/DFS with a HashMap to map original nodes to their clones.", [("Deep copy vs shallow copy: deep copy?", ["Copies references", "Copies values recursively", "Copies nothing", "Only copies root"], 1), ("HashMap in graph cloning ensures?", ["No duplicate clones", "Sorted order", "Faster DFS", "Level order"], 0), ("A number increased by 20% = 120. Original?", ["90", "95", "100", "110"], 2)]),
    ("Course Schedule (Topological Sort)", "medium", "Graphs", "https://leetcode.com/problems/course-schedule/", "Build adjacency list, detect cycle using DFS with 3 states (unvisited, visiting, visited).", [("Topological sort applies to?", ["Undirected graphs", "DAGs", "Complete graphs", "Trees only"], 1), ("Cycle in directed graph means?", ["No topological order", "Easy sorting", "DAG property", "Tree property"], 0), ("Work rate: A does job in 10 days, B in 15 days. Together?", ["5 days", "6 days", "8 days", "9 days"], 1)]),
    ("Dijkstra's Shortest Path", "hard", "Graphs", "https://leetcode.com/problems/network-delay-time/", "Use min-heap priority queue. Relax edges greedily by choosing shortest known distance.", [("Dijkstra works with?", ["Negative weights", "Non-negative weights", "All graphs", "Only trees"], 1), ("Dijkstra uses?", ["Stack", "Queue", "Priority Queue", "Array"], 2), ("Boat covers 10 km upstream in 2h, downstream in 1h. Current speed?", ["2 km/h", "2.5 km/h", "3 km/h", "3.5 km/h"], 1)]),
    ("Detect Cycle in Undirected Graph", "medium", "Graphs", "https://leetcode.com/problems/graph-valid-tree/", "Use Union-Find or DFS with parent tracking to detect back edges.", [("Union-Find detects cycles in?", ["O(n²)", "O(n log n)", "O(n α(n)) amortized", "O(1)"], 2), ("A back edge in DFS indicates?", ["Tree edge", "Cycle", "Cross edge", "No cycle"], 1), ("If salary is 25,000 and increased by 8%, new salary?", ["26,500", "27,000", "27,200", "28,000"], 1)]),
    # Strings
    ("Valid Anagram", "easy", "Strings", "https://leetcode.com/problems/valid-anagram/", "Use character frequency count (array or HashMap). Compare counts.", [("Anagram has?", ["Same characters different order", "Same order", "Different characters", "Different length"], 0), ("Frequency count uses?", ["Sorting", "HashMap/Array", "Binary search", "Stack"], 1), ("Average of first 5 odd numbers?", ["3", "5", "7", "9"], 1)]),
    ("Longest Substring Without Repeating Characters", "medium", "Strings", "https://leetcode.com/problems/longest-substring-without-repeating-characters/", "Sliding window with a HashSet. Shrink window from left when duplicate found.", [("Sliding window maintains?", ["A range [left, right]", "A fixed window", "Sorted order", "Reversed string"], 0), ("Sliding window time complexity?", ["O(n²)", "O(n)", "O(n log n)", "O(1)"], 1), ("P and Q start a business with 3:5 ratio. Profit 8000, Q's share?", ["3000", "4000", "5000", "6000"], 2)]),
    ("Group Anagrams", "medium", "Strings", "https://leetcode.com/problems/group-anagrams/", "Sort each word as the key. All anagrams have same sorted key. Use HashMap<String, List>.", [("Sorting a string of length k takes?", ["O(k)", "O(k log k)", "O(k²)", "O(1)"], 1), ("HashMap key for grouping anagrams?", ["Sorted string", "First char", "Length", "Frequency"], 0), ("Simple interest: P=5000, R=6%, T=3 years. SI=?", ["800", "900", "1000", "1100"], 1)]),
    ("Minimum Window Substring", "hard", "Strings", "https://leetcode.com/problems/minimum-window-substring/", "Two-pointer sliding window with frequency maps. Shrink when all chars satisfied.", [("Minimum window problem is?", ["Fixed window", "Variable sliding window", "Binary search", "Two-stack"], 1), ("When do we shrink the window?", ["When window is invalid", "When constraint satisfied", "Always", "At start only"], 1), ("What is 15% of 240?", ["30", "34", "36", "40"], 2)]),
    ("Palindrome Check", "easy", "Strings", "https://leetcode.com/problems/valid-palindrome/", "Two pointers from both ends, skip non-alphanumeric chars, compare char by char.", [("Palindrome reads same?", ["Forwards", "Backwards", "Both forwards and backwards", "Only lowercase"], 2), ("Two-pointer approach for palindrome is?", ["O(n)", "O(n²)", "O(log n)", "O(1)"], 0), ("Ratio 2:3:5, total 200. Largest share?", ["50", "80", "100", "120"], 2)]),
]

# Expand to 365
all_dsa = []
for i in range(365):
    base = DSA_ITEMS[i % len(DSA_ITEMS)]
    title, diff, topic, link, hint, questions = base
    all_dsa.append((i+1, title, diff, topic, link, hint, questions))

dsa_lines = ["-- ============================================================",
             "-- PSGMX SQL — FILE 04: Seed 365 Apti & DSA Daily Items",
             "-- Run this FOURTH in Supabase SQL Editor (after file 01)",
             "-- ============================================================",
             "",
             "INSERT INTO apti_dsa_daily_bank (day_of_year, dsa_title, dsa_difficulty, dsa_topic, dsa_external_link, dsa_hint, aptitude_questions, is_active)",
             "VALUES"]

dsa_rows = []
for doy, title, diff, topic, link, hint, questions in all_dsa:
    qs_json = json.dumps([{"question": q[0], "options": list(q[1]), "correct_option": q[2]} for q in questions])
    qs_json_escaped = qs_json.replace("'", "''")
    link_val = f"'{esc(link)}'" if link else "NULL"
    hint_val = f"'{esc(hint)}'" if hint else "NULL"
    dsa_rows.append(f"({doy}, '{esc(title)}', '{diff}', '{esc(topic)}', {link_val}, {hint_val}, '{qs_json_escaped}', TRUE)")

dsa_lines.append(",\n".join(dsa_rows))
dsa_lines.append("ON CONFLICT (day_of_year) DO UPDATE SET")
dsa_lines.append("  dsa_title = EXCLUDED.dsa_title,")
dsa_lines.append("  dsa_difficulty = EXCLUDED.dsa_difficulty,")
dsa_lines.append("  dsa_topic = EXCLUDED.dsa_topic,")
dsa_lines.append("  dsa_external_link = EXCLUDED.dsa_external_link,")
dsa_lines.append("  dsa_hint = EXCLUDED.dsa_hint,")
dsa_lines.append("  aptitude_questions = EXCLUDED.aptitude_questions;")
dsa_lines.append("")
dsa_lines.append("SELECT COUNT(*) AS apti_dsa_seeded FROM apti_dsa_daily_bank;")

with open("04_seed_365_apti_dsa.sql", "w") as f:
    f.write("\n".join(dsa_lines))

print(f"Generated 04_seed_365_apti_dsa.sql with {len(all_dsa)} rows")
print("Done! All seed files generated.")
