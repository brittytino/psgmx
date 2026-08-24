-- ============================================================
-- PSGMX SQL — FILE 01: Create Daily Content Tables
-- Run this FIRST in Supabase SQL Editor
-- ============================================================

-- 1. project_task_bank
CREATE TABLE IF NOT EXISTS project_task_bank (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    day_of_year     INT         NOT NULL CHECK (day_of_year BETWEEN 1 AND 366),
    title           TEXT        NOT NULL,
    description     TEXT        NOT NULL,
    category        TEXT        NOT NULL,
    difficulty      TEXT        NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    reference_link  TEXT,
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (day_of_year)
);
CREATE INDEX IF NOT EXISTS idx_project_task_bank_doy ON project_task_bank(day_of_year);

-- 2. apti_dsa_daily_bank
CREATE TABLE IF NOT EXISTS apti_dsa_daily_bank (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    day_of_year         INT         NOT NULL CHECK (day_of_year BETWEEN 1 AND 366),
    dsa_title           TEXT        NOT NULL,
    dsa_difficulty      TEXT        NOT NULL CHECK (dsa_difficulty IN ('easy', 'medium', 'hard')),
    dsa_topic           TEXT        NOT NULL,
    dsa_external_link   TEXT,
    dsa_hint            TEXT,
    aptitude_questions  JSONB       NOT NULL,
    is_active           BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (day_of_year)
);
CREATE INDEX IF NOT EXISTS idx_apti_dsa_daily_bank_doy ON apti_dsa_daily_bank(day_of_year);

-- 3. daily_content_completions
CREATE TABLE IF NOT EXISTS daily_content_completions (
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_type    TEXT        NOT NULL CHECK (content_type IN ('project_task', 'apti_dsa')),
    item_date       DATE        NOT NULL DEFAULT CURRENT_DATE,
    completed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes           TEXT,
    PRIMARY KEY (user_id, content_type, item_date)
);

-- 4. RLS Policies
ALTER TABLE project_task_bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE apti_dsa_daily_bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_content_completions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS project_task_bank_read ON project_task_bank;
CREATE POLICY project_task_bank_read ON project_task_bank
    FOR SELECT TO authenticated USING (is_active = TRUE);

DROP POLICY IF EXISTS apti_dsa_daily_bank_read ON apti_dsa_daily_bank;
CREATE POLICY apti_dsa_daily_bank_read ON apti_dsa_daily_bank
    FOR SELECT TO authenticated USING (is_active = TRUE);

DROP POLICY IF EXISTS daily_content_completions_own ON daily_content_completions;
CREATE POLICY daily_content_completions_own ON daily_content_completions
    FOR ALL TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

SELECT 'FILE 01 COMPLETE: Daily content tables created.' AS status;
-- ============================================================
-- PSGMX SQL — FILE 02: Fix Companies Table RLS & Realtime
-- Run this SECOND in Supabase SQL Editor
-- Fixes the RealtimeSubscribeException on the Log screen
-- ============================================================

-- Enable RLS on companies (may already be on)
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- Allow ALL authenticated users to read ALL company records
DROP POLICY IF EXISTS companies_read_all ON companies;
CREATE POLICY companies_read_all ON companies
    FOR SELECT TO authenticated USING (true);

-- Allow only users with manage_company_records permission to insert/update
DROP POLICY IF EXISTS companies_write ON companies;
CREATE POLICY companies_write ON companies
    FOR ALL TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM user_permissions
        WHERE user_id = auth.uid()
          AND permission = 'manage_company_records'
      )
    )
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM user_permissions
        WHERE user_id = auth.uid()
          AND permission = 'manage_company_records'
      )
    );

-- Enable Realtime on companies table
-- NOTE: In Supabase dashboard also go to Database > Replication and enable for 'companies' table
ALTER PUBLICATION supabase_realtime ADD TABLE companies;

-- Also fix placement_log_entries RLS
ALTER TABLE placement_log_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS placement_log_entries_read ON placement_log_entries;
CREATE POLICY placement_log_entries_read ON placement_log_entries
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS placement_log_entries_insert ON placement_log_entries;
CREATE POLICY placement_log_entries_insert ON placement_log_entries
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

SELECT 'FILE 02 COMPLETE: Companies RLS and realtime fixed.' AS status;
-- ============================================================
-- PSGMX SQL — FILE 03: Seed 365 Project Tasks
-- Run this THIRD in Supabase SQL Editor (after file 01)
-- ============================================================

INSERT INTO project_task_bank (day_of_year, title, description, category, difficulty, reference_link, is_active)
VALUES
(1, 'Build a responsive landing page with HTML/CSS Grid', 'Create a responsive landing page using CSS Grid layout. Include a hero section, features list, and footer. Must work on mobile and desktop.', 'Web Dev', 'easy', 'https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_grid_layout', TRUE),
(2, 'Create a multi-step form with validation', 'Build a multi-step registration form with client-side validation, progress indicator, and animated transitions between steps.', 'Web Dev', 'medium', 'https://developer.mozilla.org/en-US/docs/Learn/Forms', TRUE),
(3, 'Implement a REST API using Node.js and Express', 'Build a CRUD REST API for a blog system with endpoints for posts, comments, and tags. Include proper error handling.', 'Web Dev', 'medium', 'https://expressjs.com/en/starter/basic-routing.html', TRUE),
(4, 'Create a real-time chat UI using WebSockets concept', 'Design a chat interface that demonstrates understanding of WebSocket event flow. Mock the backend with a local event bus.', 'Web Dev', 'hard', 'https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API', TRUE),
(5, 'Build a weather dashboard using a public API', 'Fetch weather data from OpenWeatherMap API and display current weather, 5-day forecast, and a temperature chart.', 'Web Dev', 'easy', 'https://openweathermap.org/api', TRUE),
(6, 'Implement dark/light theme toggle with CSS variables', 'Add a theme toggle that switches between dark and light modes using CSS custom properties (variables) and localStorage persistence.', 'Web Dev', 'easy', 'https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties', TRUE),
(7, 'Build an infinite scroll list component', 'Create a paginated list that loads more items when the user scrolls to the bottom using Intersection Observer API.', 'Web Dev', 'medium', 'https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API', TRUE),
(8, 'Create a drag-and-drop Kanban board', 'Build a Kanban board with three columns (Todo, In Progress, Done) and drag-and-drop functionality using HTML5 drag events.', 'Web Dev', 'hard', 'https://developer.mozilla.org/en-US/docs/Web/API/HTML_Drag_and_Drop_API', TRUE),
(9, 'Build a markdown preview editor', 'Create a split-pane editor where the left side accepts markdown text and the right side renders live HTML preview.', 'Web Dev', 'medium', 'https://marked.js.org/', TRUE),
(10, 'Implement JWT authentication flow', 'Build a complete login/register flow with JWT tokens, refresh token logic, and protected routes. Mock the backend.', 'Web Dev', 'hard', 'https://jwt.io/introduction', TRUE),
(11, 'Design an ER diagram for a hospital management system', 'Create a complete ER diagram with entities: Patient, Doctor, Appointment, Ward, Medicine, Prescription. Show all relationships and cardinalities.', 'DBMS', 'easy', 'https://www.geeksforgeeks.org/er-model/', TRUE),
(12, 'Write complex SQL queries for a sales database', 'Given a sales DB schema (Customers, Orders, Products, OrderItems), write 10 queries using JOINs, GROUP BY, HAVING, subqueries, and window functions.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/tutorial-sql.html', TRUE),
(13, 'Normalize a given table to 3NF', 'Take an unnormalized spreadsheet of student enrollment data and normalize it through 1NF, 2NF, and 3NF. Show each step.', 'DBMS', 'medium', 'https://www.geeksforgeeks.org/normalization-of-database/', TRUE),
(14, 'Implement indexing strategy for a slow query', 'Analyze a slow query on a 1M-row orders table. Create appropriate indexes (B-Tree, composite, partial) and explain the execution plan difference.', 'DBMS', 'hard', 'https://use-the-index-luke.com/', TRUE),
(15, 'Build a stored procedure for student grade calculation', 'Write a PL/pgSQL stored procedure that calculates semester GPA, updates the students table, and logs changes to an audit table.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/plpgsql.html', TRUE),
(16, 'Design a database for an e-commerce platform', 'Design a complete relational schema for an e-commerce platform with Products, Variants, Inventory, Orders, Payments, Reviews, and Coupons.', 'DBMS', 'hard', 'https://www.vertabelo.com/blog/e-commerce-database/', TRUE),
(17, 'Write a trigger to prevent negative stock', 'Create a BEFORE INSERT/UPDATE trigger on an inventory table that raises an exception if stock would go below zero.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/sql-createtrigger.html', TRUE),
(18, 'Implement a recursive CTE for org chart traversal', 'Use a recursive Common Table Expression to traverse an employee hierarchy table and find all subordinates of a given manager.', 'DBMS', 'hard', 'https://www.postgresql.org/docs/current/queries-with.html', TRUE),
(19, 'Design a time-series schema for sensor data', 'Design and implement a schema optimized for storing IoT sensor readings with efficient range queries and aggregations.', 'DBMS', 'medium', 'https://www.timescale.com/blog/time-series-data/', TRUE),
(20, 'Build a full-text search query', 'Use PostgreSQL full-text search (tsvector, tsquery, GIN index) to implement smart search on a products table.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/textsearch.html', TRUE),
(21, 'Implement a generic Stack and Queue in Java', 'Create type-safe generic Stack and Queue implementations using arrays. Implement push, pop, peek, isEmpty, size methods with proper exception handling.', 'OOP-Java', 'easy', 'https://docs.oracle.com/en/java/docs/', TRUE),
(22, 'Design a library management system using OOP principles', 'Build a library system with classes: Book, Member, Librarian, Loan. Apply inheritance, encapsulation, and polymorphism. Include a simple CLI.', 'OOP-Java', 'medium', 'https://docs.oracle.com/javase/tutorial/java/concepts/', TRUE),
(23, 'Implement the Observer design pattern', 'Create an event notification system using the Observer pattern with multiple concrete subscribers for a news publishing system.', 'OOP-Java', 'medium', 'https://refactoring.guru/design-patterns/observer', TRUE),
(24, 'Build a thread-safe bank account system', 'Implement BankAccount with deposit, withdraw, transfer operations using synchronized methods and proper concurrency control to avoid race conditions.', 'OOP-Java', 'hard', 'https://docs.oracle.com/javase/tutorial/essential/concurrency/', TRUE),
(25, 'Implement a simple IoC container (Dependency Injection)', 'Build a basic dependency injection container that resolves constructor dependencies using reflection.', 'OOP-Java', 'hard', 'https://docs.oracle.com/javase/tutorial/reflect/', TRUE),
(26, 'Create a Builder pattern for a complex object', 'Implement the Builder pattern for constructing a complex Pizza order with optional toppings, size, crust type using fluent interface.', 'OOP-Java', 'easy', 'https://refactoring.guru/design-patterns/builder', TRUE),
(27, 'Build a simple expression evaluator using Composite pattern', 'Parse and evaluate mathematical expressions (+ - * /) using the Composite design pattern with leaf and branch nodes.', 'OOP-Java', 'medium', 'https://refactoring.guru/design-patterns/composite', TRUE),
(28, 'Implement a connection pool', 'Build a generic connection pool with configurable min/max pool size, idle timeout, and thread-safe borrowing/returning of connections.', 'OOP-Java', 'hard', 'https://en.wikipedia.org/wiki/Connection_pool', TRUE),
(29, 'Design an Animal hierarchy with abstract classes', 'Create an Animal hierarchy with abstract methods sound() and move(). Implement Dog, Cat, Bird, Fish subclasses. Override toString and equals.', 'OOP-Java', 'easy', 'https://docs.oracle.com/javase/tutorial/java/IandI/abstract.html', TRUE),
(30, 'Build a simple rule engine using Strategy pattern', 'Implement a discount rule engine for an e-commerce platform using the Strategy pattern. Rules: percentage off, flat discount, BOGO.', 'OOP-Java', 'medium', 'https://refactoring.guru/design-patterns/strategy', TRUE),
(31, 'Design URL Shortener (like bit.ly)', 'Design a scalable URL shortener service. Include: API design, database schema, hashing algorithm, caching layer, and scaling strategy.', 'System Design', 'medium', 'https://systemdesign.one/url-shortening-system-design/', TRUE),
(32, 'Design a notification delivery system', 'Design a system that sends email, SMS, and push notifications to millions of users. Cover: message queues, retry logic, rate limiting, fan-out.', 'System Design', 'hard', 'https://bytebytego.com/', TRUE),
(33, 'Design a rate limiter', 'Design a distributed rate limiter using token bucket algorithm. Show API design, Redis-based implementation, and edge cases.', 'System Design', 'medium', 'https://stripe.com/blog/rate-limiters', TRUE),
(34, 'Design a distributed cache', 'Design a distributed caching system (like Redis cluster). Cover: consistent hashing, cache eviction, cache-aside pattern, invalidation strategies.', 'System Design', 'hard', 'https://redis.io/docs/manual/scaling/', TRUE),
(35, 'Design a ride-sharing location service', 'Design the backend for tracking driver locations in real-time for a ride-sharing app. Focus on geospatial indexing and low-latency updates.', 'System Design', 'hard', 'https://geohash.softeng.co/', TRUE),
(36, 'Design a file storage system (like Google Drive)', 'Design a file storage and sharing service. Cover: chunked upload, deduplication, metadata DB, CDN, access control.', 'System Design', 'hard', 'https://systemdesign.one/google-drive-system-design/', TRUE),
(37, 'Design an API gateway', 'Design an API gateway for a microservices architecture. Include: routing, authentication, rate limiting, logging, circuit breaking.', 'System Design', 'medium', 'https://microservices.io/patterns/apigateway.html', TRUE),
(38, 'Design a search autocomplete system', 'Design a type-ahead search suggestion system for an e-commerce site handling 100K QPS. Include trie-based approach and Elasticsearch alternative.', 'System Design', 'medium', 'https://bytebytego.com/', TRUE),
(39, 'Design a message queue system', 'Design a persistent message queue (like Kafka). Cover: partitioning, replication, offset management, consumer groups, delivery semantics.', 'System Design', 'hard', 'https://kafka.apache.org/documentation/', TRUE),
(40, 'Design a leaderboard system', 'Design a real-time leaderboard for a gaming platform with 1M players. Use sorted sets (Redis ZSET) and handle score updates efficiently.', 'System Design', 'medium', 'https://redis.io/docs/data-types/sorted-sets/', TRUE),
(41, 'Set up a complete CI/CD pipeline with GitHub Actions', 'Create a GitHub Actions workflow that runs tests, lints code, builds Docker image, and deploys to a staging environment on PR merge.', 'Git-DevOps', 'medium', 'https://docs.github.com/en/actions', TRUE),
(42, 'Implement Git branching strategy for a team project', 'Document and implement a Git Flow branching strategy with main, develop, feature, release, and hotfix branches. Practice the full workflow.', 'Git-DevOps', 'easy', 'https://nvie.com/posts/a-successful-git-branching-model/', TRUE),
(43, 'Create a multi-stage Dockerfile', 'Write a multi-stage Dockerfile for a Node.js application: builder stage installs deps and builds, production stage copies only the built artifact.', 'Git-DevOps', 'medium', 'https://docs.docker.com/build/building/multi-stage/', TRUE),
(44, 'Write a Kubernetes Deployment manifest', 'Write Kubernetes YAML files for Deployment, Service, ConfigMap, and HorizontalPodAutoscaler for a web application.', 'Git-DevOps', 'medium', 'https://kubernetes.io/docs/concepts/workloads/controllers/deployment/', TRUE),
(45, 'Implement infrastructure as code with Terraform', 'Write Terraform configuration to provision an AWS VPC, EC2 instance, RDS database, and S3 bucket with proper security groups.', 'Git-DevOps', 'hard', 'https://developer.hashicorp.com/terraform/tutorials', TRUE),
(46, 'Set up monitoring with Prometheus and Grafana', 'Configure Prometheus to scrape metrics from a Node.js app and create Grafana dashboards for request rate, error rate, and latency (RED metrics).', 'Git-DevOps', 'hard', 'https://grafana.com/docs/grafana/latest/', TRUE),
(47, 'Automate database migrations in CI/CD', 'Integrate database migration tool (Flyway or Liquibase) into a CI pipeline so migrations run automatically before deployment.', 'Git-DevOps', 'medium', 'https://flywaydb.org/documentation/', TRUE),
(48, 'Create a git pre-commit hook for code quality', 'Write a git pre-commit hook script that runs ESLint/Prettier checks and blocks the commit if code quality checks fail.', 'Git-DevOps', 'easy', 'https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks', TRUE),
(49, 'Build a Docker Compose setup for local development', 'Create a docker-compose.yml that runs a web app, PostgreSQL, Redis, and a reverse proxy (Nginx) for local development.', 'Git-DevOps', 'easy', 'https://docs.docker.com/compose/', TRUE),
(50, 'Implement semantic versioning and changelog automation', 'Set up conventional commits and use semantic-release to automatically bump version and generate CHANGELOG.md on CI.', 'Git-DevOps', 'medium', 'https://semantic-release.gitbook.io/semantic-release', TRUE),
(51, 'Write unit tests for a calculator service', 'Write comprehensive JUnit/Jest unit tests for a calculator with add, subtract, multiply, divide, modulo. Include boundary cases and exception testing.', 'Testing', 'easy', 'https://junit.org/junit5/docs/current/user-guide/', TRUE),
(52, 'Write integration tests for a REST API', 'Write integration tests for a CRUD REST API covering all endpoints, including error cases, authentication, and database state verification.', 'Testing', 'medium', 'https://supertest.npmjs.com/', TRUE),
(53, 'Implement test-driven development (TDD) for a user service', 'Use TDD (Red-Green-Refactor) to build a UserService with register, login, update profile, delete account. Write failing tests first.', 'Testing', 'medium', 'https://www.agilealliance.org/glossary/tdd/', TRUE),
(54, 'Set up end-to-end testing with Playwright', 'Write Playwright E2E tests for a web application covering: login flow, form submission, navigation, and error states.', 'Testing', 'hard', 'https://playwright.dev/docs/writing-tests', TRUE),
(55, 'Write tests for concurrent code', 'Write tests that verify thread safety for a concurrent bank account implementation. Use multiple threads and assert no race conditions occur.', 'Testing', 'hard', 'https://www.baeldung.com/java-testing-multithreaded', TRUE),
(56, 'Implement a test doubles strategy (mocks, stubs, fakes)', 'Practice using mocks for external services, stubs for dependencies, and fakes for databases in a payment processing service.', 'Testing', 'medium', 'https://martinfowler.com/articles/mocksArentStubs.html', TRUE),
(57, 'Write property-based tests', 'Use a property-based testing library (QuickCheck/Hypothesis) to generate thousands of test cases for a sorting algorithm and string processing functions.', 'Testing', 'hard', 'https://hypothesis.readthedocs.io/', TRUE),
(58, 'Measure and improve code coverage', 'Add test coverage measurement to a project, identify untested branches, write tests to achieve 85%+ coverage, and integrate into CI.', 'Testing', 'medium', 'https://istanbul.js.org/', TRUE),
(59, 'Write performance tests with JMeter', 'Create a JMeter test plan to load test a REST API with 100 concurrent users, measure response times, and identify the breaking point.', 'Testing', 'hard', 'https://jmeter.apache.org/usermanual/get-started.html', TRUE),
(60, 'Implement contract testing with Pact', 'Write consumer-driven contract tests between a web frontend and a backend API using Pact to ensure API compatibility.', 'Testing', 'hard', 'https://docs.pact.io/', TRUE),
(61, 'Deploy a static website to AWS S3 + CloudFront', 'Deploy a static HTML/CSS/JS website to S3, configure static hosting, set up CloudFront distribution, and add a custom domain.', 'Cloud Basics', 'easy', 'https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html', TRUE),
(62, 'Set up a serverless function with AWS Lambda', 'Create a Lambda function triggered by an API Gateway that processes JSON input, calls a DynamoDB table, and returns a response.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/lambda/latest/dg/getting-started.html', TRUE),
(63, 'Configure AWS IAM roles and policies', 'Practice the principle of least privilege: create IAM roles with minimal permissions for an EC2 instance, Lambda, and RDS access.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html', TRUE),
(64, 'Deploy a containerized app to Google Cloud Run', 'Containerize a web app with Docker, push to Google Container Registry, and deploy to Cloud Run with auto-scaling configuration.', 'Cloud Basics', 'medium', 'https://cloud.google.com/run/docs/quickstarts', TRUE),
(65, 'Set up managed PostgreSQL on Supabase', 'Create a Supabase project, design a schema with RLS policies, connect from a web app, and test CRUD operations with the JavaScript client.', 'Cloud Basics', 'easy', 'https://supabase.com/docs', TRUE),
(66, 'Implement object storage with lifecycle policies', 'Configure S3 bucket with lifecycle rules: move objects to Glacier after 30 days, delete after 365 days. Test with simulated uploads.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html', TRUE),
(67, 'Set up autoscaling for a web application', 'Configure AWS Auto Scaling Group with launch template, scaling policies (target tracking), and load balancer health checks.', 'Cloud Basics', 'hard', 'https://docs.aws.amazon.com/autoscaling/ec2/userguide/get-started-with-ec2-auto-scaling.html', TRUE),
(68, 'Build a serverless image resizing pipeline', 'Create an event-driven pipeline: S3 upload triggers Lambda, Lambda resizes image using Sharp, saves thumbnails back to S3.', 'Cloud Basics', 'hard', 'https://aws.amazon.com/blogs/compute/resize-images-on-the-fly-with-amazon-s3-aws-lambda-and-amazon-api-gateway/', TRUE),
(69, 'Set up cloud monitoring and alerts', 'Configure CloudWatch metrics, create alarms for CPU >80% and error rate >5%, and set up SNS notifications for incidents.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/', TRUE),
(70, 'Implement multi-region failover', 'Design and implement an active-passive multi-region setup with Route53 health checks and automatic failover for a stateless web application.', 'Cloud Basics', 'hard', 'https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover.html', TRUE),
(71, 'Build a responsive landing page with HTML/CSS Grid', 'Create a responsive landing page using CSS Grid layout. Include a hero section, features list, and footer. Must work on mobile and desktop.', 'Web Dev', 'easy', 'https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_grid_layout', TRUE),
(72, 'Create a multi-step form with validation', 'Build a multi-step registration form with client-side validation, progress indicator, and animated transitions between steps.', 'Web Dev', 'medium', 'https://developer.mozilla.org/en-US/docs/Learn/Forms', TRUE),
(73, 'Implement a REST API using Node.js and Express', 'Build a CRUD REST API for a blog system with endpoints for posts, comments, and tags. Include proper error handling.', 'Web Dev', 'medium', 'https://expressjs.com/en/starter/basic-routing.html', TRUE),
(74, 'Create a real-time chat UI using WebSockets concept', 'Design a chat interface that demonstrates understanding of WebSocket event flow. Mock the backend with a local event bus.', 'Web Dev', 'hard', 'https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API', TRUE),
(75, 'Build a weather dashboard using a public API', 'Fetch weather data from OpenWeatherMap API and display current weather, 5-day forecast, and a temperature chart.', 'Web Dev', 'easy', 'https://openweathermap.org/api', TRUE),
(76, 'Implement dark/light theme toggle with CSS variables', 'Add a theme toggle that switches between dark and light modes using CSS custom properties (variables) and localStorage persistence.', 'Web Dev', 'easy', 'https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties', TRUE),
(77, 'Build an infinite scroll list component', 'Create a paginated list that loads more items when the user scrolls to the bottom using Intersection Observer API.', 'Web Dev', 'medium', 'https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API', TRUE),
(78, 'Create a drag-and-drop Kanban board', 'Build a Kanban board with three columns (Todo, In Progress, Done) and drag-and-drop functionality using HTML5 drag events.', 'Web Dev', 'hard', 'https://developer.mozilla.org/en-US/docs/Web/API/HTML_Drag_and_Drop_API', TRUE),
(79, 'Build a markdown preview editor', 'Create a split-pane editor where the left side accepts markdown text and the right side renders live HTML preview.', 'Web Dev', 'medium', 'https://marked.js.org/', TRUE),
(80, 'Implement JWT authentication flow', 'Build a complete login/register flow with JWT tokens, refresh token logic, and protected routes. Mock the backend.', 'Web Dev', 'hard', 'https://jwt.io/introduction', TRUE),
(81, 'Design an ER diagram for a hospital management system', 'Create a complete ER diagram with entities: Patient, Doctor, Appointment, Ward, Medicine, Prescription. Show all relationships and cardinalities.', 'DBMS', 'easy', 'https://www.geeksforgeeks.org/er-model/', TRUE),
(82, 'Write complex SQL queries for a sales database', 'Given a sales DB schema (Customers, Orders, Products, OrderItems), write 10 queries using JOINs, GROUP BY, HAVING, subqueries, and window functions.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/tutorial-sql.html', TRUE),
(83, 'Normalize a given table to 3NF', 'Take an unnormalized spreadsheet of student enrollment data and normalize it through 1NF, 2NF, and 3NF. Show each step.', 'DBMS', 'medium', 'https://www.geeksforgeeks.org/normalization-of-database/', TRUE),
(84, 'Implement indexing strategy for a slow query', 'Analyze a slow query on a 1M-row orders table. Create appropriate indexes (B-Tree, composite, partial) and explain the execution plan difference.', 'DBMS', 'hard', 'https://use-the-index-luke.com/', TRUE),
(85, 'Build a stored procedure for student grade calculation', 'Write a PL/pgSQL stored procedure that calculates semester GPA, updates the students table, and logs changes to an audit table.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/plpgsql.html', TRUE),
(86, 'Design a database for an e-commerce platform', 'Design a complete relational schema for an e-commerce platform with Products, Variants, Inventory, Orders, Payments, Reviews, and Coupons.', 'DBMS', 'hard', 'https://www.vertabelo.com/blog/e-commerce-database/', TRUE),
(87, 'Write a trigger to prevent negative stock', 'Create a BEFORE INSERT/UPDATE trigger on an inventory table that raises an exception if stock would go below zero.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/sql-createtrigger.html', TRUE),
(88, 'Implement a recursive CTE for org chart traversal', 'Use a recursive Common Table Expression to traverse an employee hierarchy table and find all subordinates of a given manager.', 'DBMS', 'hard', 'https://www.postgresql.org/docs/current/queries-with.html', TRUE),
(89, 'Design a time-series schema for sensor data', 'Design and implement a schema optimized for storing IoT sensor readings with efficient range queries and aggregations.', 'DBMS', 'medium', 'https://www.timescale.com/blog/time-series-data/', TRUE),
(90, 'Build a full-text search query', 'Use PostgreSQL full-text search (tsvector, tsquery, GIN index) to implement smart search on a products table.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/textsearch.html', TRUE),
(91, 'Implement a generic Stack and Queue in Java', 'Create type-safe generic Stack and Queue implementations using arrays. Implement push, pop, peek, isEmpty, size methods with proper exception handling.', 'OOP-Java', 'easy', 'https://docs.oracle.com/en/java/docs/', TRUE),
(92, 'Design a library management system using OOP principles', 'Build a library system with classes: Book, Member, Librarian, Loan. Apply inheritance, encapsulation, and polymorphism. Include a simple CLI.', 'OOP-Java', 'medium', 'https://docs.oracle.com/javase/tutorial/java/concepts/', TRUE),
(93, 'Implement the Observer design pattern', 'Create an event notification system using the Observer pattern with multiple concrete subscribers for a news publishing system.', 'OOP-Java', 'medium', 'https://refactoring.guru/design-patterns/observer', TRUE),
(94, 'Build a thread-safe bank account system', 'Implement BankAccount with deposit, withdraw, transfer operations using synchronized methods and proper concurrency control to avoid race conditions.', 'OOP-Java', 'hard', 'https://docs.oracle.com/javase/tutorial/essential/concurrency/', TRUE),
(95, 'Implement a simple IoC container (Dependency Injection)', 'Build a basic dependency injection container that resolves constructor dependencies using reflection.', 'OOP-Java', 'hard', 'https://docs.oracle.com/javase/tutorial/reflect/', TRUE),
(96, 'Create a Builder pattern for a complex object', 'Implement the Builder pattern for constructing a complex Pizza order with optional toppings, size, crust type using fluent interface.', 'OOP-Java', 'easy', 'https://refactoring.guru/design-patterns/builder', TRUE),
(97, 'Build a simple expression evaluator using Composite pattern', 'Parse and evaluate mathematical expressions (+ - * /) using the Composite design pattern with leaf and branch nodes.', 'OOP-Java', 'medium', 'https://refactoring.guru/design-patterns/composite', TRUE),
(98, 'Implement a connection pool', 'Build a generic connection pool with configurable min/max pool size, idle timeout, and thread-safe borrowing/returning of connections.', 'OOP-Java', 'hard', 'https://en.wikipedia.org/wiki/Connection_pool', TRUE),
(99, 'Design an Animal hierarchy with abstract classes', 'Create an Animal hierarchy with abstract methods sound() and move(). Implement Dog, Cat, Bird, Fish subclasses. Override toString and equals.', 'OOP-Java', 'easy', 'https://docs.oracle.com/javase/tutorial/java/IandI/abstract.html', TRUE),
(100, 'Build a simple rule engine using Strategy pattern', 'Implement a discount rule engine for an e-commerce platform using the Strategy pattern. Rules: percentage off, flat discount, BOGO.', 'OOP-Java', 'medium', 'https://refactoring.guru/design-patterns/strategy', TRUE),
(101, 'Design URL Shortener (like bit.ly)', 'Design a scalable URL shortener service. Include: API design, database schema, hashing algorithm, caching layer, and scaling strategy.', 'System Design', 'medium', 'https://systemdesign.one/url-shortening-system-design/', TRUE),
(102, 'Design a notification delivery system', 'Design a system that sends email, SMS, and push notifications to millions of users. Cover: message queues, retry logic, rate limiting, fan-out.', 'System Design', 'hard', 'https://bytebytego.com/', TRUE),
(103, 'Design a rate limiter', 'Design a distributed rate limiter using token bucket algorithm. Show API design, Redis-based implementation, and edge cases.', 'System Design', 'medium', 'https://stripe.com/blog/rate-limiters', TRUE),
(104, 'Design a distributed cache', 'Design a distributed caching system (like Redis cluster). Cover: consistent hashing, cache eviction, cache-aside pattern, invalidation strategies.', 'System Design', 'hard', 'https://redis.io/docs/manual/scaling/', TRUE),
(105, 'Design a ride-sharing location service', 'Design the backend for tracking driver locations in real-time for a ride-sharing app. Focus on geospatial indexing and low-latency updates.', 'System Design', 'hard', 'https://geohash.softeng.co/', TRUE),
(106, 'Design a file storage system (like Google Drive)', 'Design a file storage and sharing service. Cover: chunked upload, deduplication, metadata DB, CDN, access control.', 'System Design', 'hard', 'https://systemdesign.one/google-drive-system-design/', TRUE),
(107, 'Design an API gateway', 'Design an API gateway for a microservices architecture. Include: routing, authentication, rate limiting, logging, circuit breaking.', 'System Design', 'medium', 'https://microservices.io/patterns/apigateway.html', TRUE),
(108, 'Design a search autocomplete system', 'Design a type-ahead search suggestion system for an e-commerce site handling 100K QPS. Include trie-based approach and Elasticsearch alternative.', 'System Design', 'medium', 'https://bytebytego.com/', TRUE),
(109, 'Design a message queue system', 'Design a persistent message queue (like Kafka). Cover: partitioning, replication, offset management, consumer groups, delivery semantics.', 'System Design', 'hard', 'https://kafka.apache.org/documentation/', TRUE),
(110, 'Design a leaderboard system', 'Design a real-time leaderboard for a gaming platform with 1M players. Use sorted sets (Redis ZSET) and handle score updates efficiently.', 'System Design', 'medium', 'https://redis.io/docs/data-types/sorted-sets/', TRUE),
(111, 'Set up a complete CI/CD pipeline with GitHub Actions', 'Create a GitHub Actions workflow that runs tests, lints code, builds Docker image, and deploys to a staging environment on PR merge.', 'Git-DevOps', 'medium', 'https://docs.github.com/en/actions', TRUE),
(112, 'Implement Git branching strategy for a team project', 'Document and implement a Git Flow branching strategy with main, develop, feature, release, and hotfix branches. Practice the full workflow.', 'Git-DevOps', 'easy', 'https://nvie.com/posts/a-successful-git-branching-model/', TRUE),
(113, 'Create a multi-stage Dockerfile', 'Write a multi-stage Dockerfile for a Node.js application: builder stage installs deps and builds, production stage copies only the built artifact.', 'Git-DevOps', 'medium', 'https://docs.docker.com/build/building/multi-stage/', TRUE),
(114, 'Write a Kubernetes Deployment manifest', 'Write Kubernetes YAML files for Deployment, Service, ConfigMap, and HorizontalPodAutoscaler for a web application.', 'Git-DevOps', 'medium', 'https://kubernetes.io/docs/concepts/workloads/controllers/deployment/', TRUE),
(115, 'Implement infrastructure as code with Terraform', 'Write Terraform configuration to provision an AWS VPC, EC2 instance, RDS database, and S3 bucket with proper security groups.', 'Git-DevOps', 'hard', 'https://developer.hashicorp.com/terraform/tutorials', TRUE),
(116, 'Set up monitoring with Prometheus and Grafana', 'Configure Prometheus to scrape metrics from a Node.js app and create Grafana dashboards for request rate, error rate, and latency (RED metrics).', 'Git-DevOps', 'hard', 'https://grafana.com/docs/grafana/latest/', TRUE),
(117, 'Automate database migrations in CI/CD', 'Integrate database migration tool (Flyway or Liquibase) into a CI pipeline so migrations run automatically before deployment.', 'Git-DevOps', 'medium', 'https://flywaydb.org/documentation/', TRUE),
(118, 'Create a git pre-commit hook for code quality', 'Write a git pre-commit hook script that runs ESLint/Prettier checks and blocks the commit if code quality checks fail.', 'Git-DevOps', 'easy', 'https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks', TRUE),
(119, 'Build a Docker Compose setup for local development', 'Create a docker-compose.yml that runs a web app, PostgreSQL, Redis, and a reverse proxy (Nginx) for local development.', 'Git-DevOps', 'easy', 'https://docs.docker.com/compose/', TRUE),
(120, 'Implement semantic versioning and changelog automation', 'Set up conventional commits and use semantic-release to automatically bump version and generate CHANGELOG.md on CI.', 'Git-DevOps', 'medium', 'https://semantic-release.gitbook.io/semantic-release', TRUE),
(121, 'Write unit tests for a calculator service', 'Write comprehensive JUnit/Jest unit tests for a calculator with add, subtract, multiply, divide, modulo. Include boundary cases and exception testing.', 'Testing', 'easy', 'https://junit.org/junit5/docs/current/user-guide/', TRUE),
(122, 'Write integration tests for a REST API', 'Write integration tests for a CRUD REST API covering all endpoints, including error cases, authentication, and database state verification.', 'Testing', 'medium', 'https://supertest.npmjs.com/', TRUE),
(123, 'Implement test-driven development (TDD) for a user service', 'Use TDD (Red-Green-Refactor) to build a UserService with register, login, update profile, delete account. Write failing tests first.', 'Testing', 'medium', 'https://www.agilealliance.org/glossary/tdd/', TRUE),
(124, 'Set up end-to-end testing with Playwright', 'Write Playwright E2E tests for a web application covering: login flow, form submission, navigation, and error states.', 'Testing', 'hard', 'https://playwright.dev/docs/writing-tests', TRUE),
(125, 'Write tests for concurrent code', 'Write tests that verify thread safety for a concurrent bank account implementation. Use multiple threads and assert no race conditions occur.', 'Testing', 'hard', 'https://www.baeldung.com/java-testing-multithreaded', TRUE),
(126, 'Implement a test doubles strategy (mocks, stubs, fakes)', 'Practice using mocks for external services, stubs for dependencies, and fakes for databases in a payment processing service.', 'Testing', 'medium', 'https://martinfowler.com/articles/mocksArentStubs.html', TRUE),
(127, 'Write property-based tests', 'Use a property-based testing library (QuickCheck/Hypothesis) to generate thousands of test cases for a sorting algorithm and string processing functions.', 'Testing', 'hard', 'https://hypothesis.readthedocs.io/', TRUE),
(128, 'Measure and improve code coverage', 'Add test coverage measurement to a project, identify untested branches, write tests to achieve 85%+ coverage, and integrate into CI.', 'Testing', 'medium', 'https://istanbul.js.org/', TRUE),
(129, 'Write performance tests with JMeter', 'Create a JMeter test plan to load test a REST API with 100 concurrent users, measure response times, and identify the breaking point.', 'Testing', 'hard', 'https://jmeter.apache.org/usermanual/get-started.html', TRUE),
(130, 'Implement contract testing with Pact', 'Write consumer-driven contract tests between a web frontend and a backend API using Pact to ensure API compatibility.', 'Testing', 'hard', 'https://docs.pact.io/', TRUE),
(131, 'Deploy a static website to AWS S3 + CloudFront', 'Deploy a static HTML/CSS/JS website to S3, configure static hosting, set up CloudFront distribution, and add a custom domain.', 'Cloud Basics', 'easy', 'https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html', TRUE),
(132, 'Set up a serverless function with AWS Lambda', 'Create a Lambda function triggered by an API Gateway that processes JSON input, calls a DynamoDB table, and returns a response.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/lambda/latest/dg/getting-started.html', TRUE),
(133, 'Configure AWS IAM roles and policies', 'Practice the principle of least privilege: create IAM roles with minimal permissions for an EC2 instance, Lambda, and RDS access.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html', TRUE),
(134, 'Deploy a containerized app to Google Cloud Run', 'Containerize a web app with Docker, push to Google Container Registry, and deploy to Cloud Run with auto-scaling configuration.', 'Cloud Basics', 'medium', 'https://cloud.google.com/run/docs/quickstarts', TRUE),
(135, 'Set up managed PostgreSQL on Supabase', 'Create a Supabase project, design a schema with RLS policies, connect from a web app, and test CRUD operations with the JavaScript client.', 'Cloud Basics', 'easy', 'https://supabase.com/docs', TRUE),
(136, 'Implement object storage with lifecycle policies', 'Configure S3 bucket with lifecycle rules: move objects to Glacier after 30 days, delete after 365 days. Test with simulated uploads.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html', TRUE),
(137, 'Set up autoscaling for a web application', 'Configure AWS Auto Scaling Group with launch template, scaling policies (target tracking), and load balancer health checks.', 'Cloud Basics', 'hard', 'https://docs.aws.amazon.com/autoscaling/ec2/userguide/get-started-with-ec2-auto-scaling.html', TRUE),
(138, 'Build a serverless image resizing pipeline', 'Create an event-driven pipeline: S3 upload triggers Lambda, Lambda resizes image using Sharp, saves thumbnails back to S3.', 'Cloud Basics', 'hard', 'https://aws.amazon.com/blogs/compute/resize-images-on-the-fly-with-amazon-s3-aws-lambda-and-amazon-api-gateway/', TRUE),
(139, 'Set up cloud monitoring and alerts', 'Configure CloudWatch metrics, create alarms for CPU >80% and error rate >5%, and set up SNS notifications for incidents.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/', TRUE),
(140, 'Implement multi-region failover', 'Design and implement an active-passive multi-region setup with Route53 health checks and automatic failover for a stateless web application.', 'Cloud Basics', 'hard', 'https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover.html', TRUE),
(141, 'Build a responsive landing page with HTML/CSS Grid', 'Create a responsive landing page using CSS Grid layout. Include a hero section, features list, and footer. Must work on mobile and desktop.', 'Web Dev', 'easy', 'https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_grid_layout', TRUE),
(142, 'Create a multi-step form with validation', 'Build a multi-step registration form with client-side validation, progress indicator, and animated transitions between steps.', 'Web Dev', 'medium', 'https://developer.mozilla.org/en-US/docs/Learn/Forms', TRUE),
(143, 'Implement a REST API using Node.js and Express', 'Build a CRUD REST API for a blog system with endpoints for posts, comments, and tags. Include proper error handling.', 'Web Dev', 'medium', 'https://expressjs.com/en/starter/basic-routing.html', TRUE),
(144, 'Create a real-time chat UI using WebSockets concept', 'Design a chat interface that demonstrates understanding of WebSocket event flow. Mock the backend with a local event bus.', 'Web Dev', 'hard', 'https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API', TRUE),
(145, 'Build a weather dashboard using a public API', 'Fetch weather data from OpenWeatherMap API and display current weather, 5-day forecast, and a temperature chart.', 'Web Dev', 'easy', 'https://openweathermap.org/api', TRUE),
(146, 'Implement dark/light theme toggle with CSS variables', 'Add a theme toggle that switches between dark and light modes using CSS custom properties (variables) and localStorage persistence.', 'Web Dev', 'easy', 'https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties', TRUE),
(147, 'Build an infinite scroll list component', 'Create a paginated list that loads more items when the user scrolls to the bottom using Intersection Observer API.', 'Web Dev', 'medium', 'https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API', TRUE),
(148, 'Create a drag-and-drop Kanban board', 'Build a Kanban board with three columns (Todo, In Progress, Done) and drag-and-drop functionality using HTML5 drag events.', 'Web Dev', 'hard', 'https://developer.mozilla.org/en-US/docs/Web/API/HTML_Drag_and_Drop_API', TRUE),
(149, 'Build a markdown preview editor', 'Create a split-pane editor where the left side accepts markdown text and the right side renders live HTML preview.', 'Web Dev', 'medium', 'https://marked.js.org/', TRUE),
(150, 'Implement JWT authentication flow', 'Build a complete login/register flow with JWT tokens, refresh token logic, and protected routes. Mock the backend.', 'Web Dev', 'hard', 'https://jwt.io/introduction', TRUE),
(151, 'Design an ER diagram for a hospital management system', 'Create a complete ER diagram with entities: Patient, Doctor, Appointment, Ward, Medicine, Prescription. Show all relationships and cardinalities.', 'DBMS', 'easy', 'https://www.geeksforgeeks.org/er-model/', TRUE),
(152, 'Write complex SQL queries for a sales database', 'Given a sales DB schema (Customers, Orders, Products, OrderItems), write 10 queries using JOINs, GROUP BY, HAVING, subqueries, and window functions.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/tutorial-sql.html', TRUE),
(153, 'Normalize a given table to 3NF', 'Take an unnormalized spreadsheet of student enrollment data and normalize it through 1NF, 2NF, and 3NF. Show each step.', 'DBMS', 'medium', 'https://www.geeksforgeeks.org/normalization-of-database/', TRUE),
(154, 'Implement indexing strategy for a slow query', 'Analyze a slow query on a 1M-row orders table. Create appropriate indexes (B-Tree, composite, partial) and explain the execution plan difference.', 'DBMS', 'hard', 'https://use-the-index-luke.com/', TRUE),
(155, 'Build a stored procedure for student grade calculation', 'Write a PL/pgSQL stored procedure that calculates semester GPA, updates the students table, and logs changes to an audit table.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/plpgsql.html', TRUE),
(156, 'Design a database for an e-commerce platform', 'Design a complete relational schema for an e-commerce platform with Products, Variants, Inventory, Orders, Payments, Reviews, and Coupons.', 'DBMS', 'hard', 'https://www.vertabelo.com/blog/e-commerce-database/', TRUE),
(157, 'Write a trigger to prevent negative stock', 'Create a BEFORE INSERT/UPDATE trigger on an inventory table that raises an exception if stock would go below zero.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/sql-createtrigger.html', TRUE),
(158, 'Implement a recursive CTE for org chart traversal', 'Use a recursive Common Table Expression to traverse an employee hierarchy table and find all subordinates of a given manager.', 'DBMS', 'hard', 'https://www.postgresql.org/docs/current/queries-with.html', TRUE),
(159, 'Design a time-series schema for sensor data', 'Design and implement a schema optimized for storing IoT sensor readings with efficient range queries and aggregations.', 'DBMS', 'medium', 'https://www.timescale.com/blog/time-series-data/', TRUE),
(160, 'Build a full-text search query', 'Use PostgreSQL full-text search (tsvector, tsquery, GIN index) to implement smart search on a products table.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/textsearch.html', TRUE),
(161, 'Implement a generic Stack and Queue in Java', 'Create type-safe generic Stack and Queue implementations using arrays. Implement push, pop, peek, isEmpty, size methods with proper exception handling.', 'OOP-Java', 'easy', 'https://docs.oracle.com/en/java/docs/', TRUE),
(162, 'Design a library management system using OOP principles', 'Build a library system with classes: Book, Member, Librarian, Loan. Apply inheritance, encapsulation, and polymorphism. Include a simple CLI.', 'OOP-Java', 'medium', 'https://docs.oracle.com/javase/tutorial/java/concepts/', TRUE),
(163, 'Implement the Observer design pattern', 'Create an event notification system using the Observer pattern with multiple concrete subscribers for a news publishing system.', 'OOP-Java', 'medium', 'https://refactoring.guru/design-patterns/observer', TRUE),
(164, 'Build a thread-safe bank account system', 'Implement BankAccount with deposit, withdraw, transfer operations using synchronized methods and proper concurrency control to avoid race conditions.', 'OOP-Java', 'hard', 'https://docs.oracle.com/javase/tutorial/essential/concurrency/', TRUE),
(165, 'Implement a simple IoC container (Dependency Injection)', 'Build a basic dependency injection container that resolves constructor dependencies using reflection.', 'OOP-Java', 'hard', 'https://docs.oracle.com/javase/tutorial/reflect/', TRUE),
(166, 'Create a Builder pattern for a complex object', 'Implement the Builder pattern for constructing a complex Pizza order with optional toppings, size, crust type using fluent interface.', 'OOP-Java', 'easy', 'https://refactoring.guru/design-patterns/builder', TRUE),
(167, 'Build a simple expression evaluator using Composite pattern', 'Parse and evaluate mathematical expressions (+ - * /) using the Composite design pattern with leaf and branch nodes.', 'OOP-Java', 'medium', 'https://refactoring.guru/design-patterns/composite', TRUE),
(168, 'Implement a connection pool', 'Build a generic connection pool with configurable min/max pool size, idle timeout, and thread-safe borrowing/returning of connections.', 'OOP-Java', 'hard', 'https://en.wikipedia.org/wiki/Connection_pool', TRUE),
(169, 'Design an Animal hierarchy with abstract classes', 'Create an Animal hierarchy with abstract methods sound() and move(). Implement Dog, Cat, Bird, Fish subclasses. Override toString and equals.', 'OOP-Java', 'easy', 'https://docs.oracle.com/javase/tutorial/java/IandI/abstract.html', TRUE),
(170, 'Build a simple rule engine using Strategy pattern', 'Implement a discount rule engine for an e-commerce platform using the Strategy pattern. Rules: percentage off, flat discount, BOGO.', 'OOP-Java', 'medium', 'https://refactoring.guru/design-patterns/strategy', TRUE),
(171, 'Design URL Shortener (like bit.ly)', 'Design a scalable URL shortener service. Include: API design, database schema, hashing algorithm, caching layer, and scaling strategy.', 'System Design', 'medium', 'https://systemdesign.one/url-shortening-system-design/', TRUE),
(172, 'Design a notification delivery system', 'Design a system that sends email, SMS, and push notifications to millions of users. Cover: message queues, retry logic, rate limiting, fan-out.', 'System Design', 'hard', 'https://bytebytego.com/', TRUE),
(173, 'Design a rate limiter', 'Design a distributed rate limiter using token bucket algorithm. Show API design, Redis-based implementation, and edge cases.', 'System Design', 'medium', 'https://stripe.com/blog/rate-limiters', TRUE),
(174, 'Design a distributed cache', 'Design a distributed caching system (like Redis cluster). Cover: consistent hashing, cache eviction, cache-aside pattern, invalidation strategies.', 'System Design', 'hard', 'https://redis.io/docs/manual/scaling/', TRUE),
(175, 'Design a ride-sharing location service', 'Design the backend for tracking driver locations in real-time for a ride-sharing app. Focus on geospatial indexing and low-latency updates.', 'System Design', 'hard', 'https://geohash.softeng.co/', TRUE),
(176, 'Design a file storage system (like Google Drive)', 'Design a file storage and sharing service. Cover: chunked upload, deduplication, metadata DB, CDN, access control.', 'System Design', 'hard', 'https://systemdesign.one/google-drive-system-design/', TRUE),
(177, 'Design an API gateway', 'Design an API gateway for a microservices architecture. Include: routing, authentication, rate limiting, logging, circuit breaking.', 'System Design', 'medium', 'https://microservices.io/patterns/apigateway.html', TRUE),
(178, 'Design a search autocomplete system', 'Design a type-ahead search suggestion system for an e-commerce site handling 100K QPS. Include trie-based approach and Elasticsearch alternative.', 'System Design', 'medium', 'https://bytebytego.com/', TRUE),
(179, 'Design a message queue system', 'Design a persistent message queue (like Kafka). Cover: partitioning, replication, offset management, consumer groups, delivery semantics.', 'System Design', 'hard', 'https://kafka.apache.org/documentation/', TRUE),
(180, 'Design a leaderboard system', 'Design a real-time leaderboard for a gaming platform with 1M players. Use sorted sets (Redis ZSET) and handle score updates efficiently.', 'System Design', 'medium', 'https://redis.io/docs/data-types/sorted-sets/', TRUE),
(181, 'Set up a complete CI/CD pipeline with GitHub Actions', 'Create a GitHub Actions workflow that runs tests, lints code, builds Docker image, and deploys to a staging environment on PR merge.', 'Git-DevOps', 'medium', 'https://docs.github.com/en/actions', TRUE),
(182, 'Implement Git branching strategy for a team project', 'Document and implement a Git Flow branching strategy with main, develop, feature, release, and hotfix branches. Practice the full workflow.', 'Git-DevOps', 'easy', 'https://nvie.com/posts/a-successful-git-branching-model/', TRUE),
(183, 'Create a multi-stage Dockerfile', 'Write a multi-stage Dockerfile for a Node.js application: builder stage installs deps and builds, production stage copies only the built artifact.', 'Git-DevOps', 'medium', 'https://docs.docker.com/build/building/multi-stage/', TRUE),
(184, 'Write a Kubernetes Deployment manifest', 'Write Kubernetes YAML files for Deployment, Service, ConfigMap, and HorizontalPodAutoscaler for a web application.', 'Git-DevOps', 'medium', 'https://kubernetes.io/docs/concepts/workloads/controllers/deployment/', TRUE),
(185, 'Implement infrastructure as code with Terraform', 'Write Terraform configuration to provision an AWS VPC, EC2 instance, RDS database, and S3 bucket with proper security groups.', 'Git-DevOps', 'hard', 'https://developer.hashicorp.com/terraform/tutorials', TRUE),
(186, 'Set up monitoring with Prometheus and Grafana', 'Configure Prometheus to scrape metrics from a Node.js app and create Grafana dashboards for request rate, error rate, and latency (RED metrics).', 'Git-DevOps', 'hard', 'https://grafana.com/docs/grafana/latest/', TRUE),
(187, 'Automate database migrations in CI/CD', 'Integrate database migration tool (Flyway or Liquibase) into a CI pipeline so migrations run automatically before deployment.', 'Git-DevOps', 'medium', 'https://flywaydb.org/documentation/', TRUE),
(188, 'Create a git pre-commit hook for code quality', 'Write a git pre-commit hook script that runs ESLint/Prettier checks and blocks the commit if code quality checks fail.', 'Git-DevOps', 'easy', 'https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks', TRUE),
(189, 'Build a Docker Compose setup for local development', 'Create a docker-compose.yml that runs a web app, PostgreSQL, Redis, and a reverse proxy (Nginx) for local development.', 'Git-DevOps', 'easy', 'https://docs.docker.com/compose/', TRUE),
(190, 'Implement semantic versioning and changelog automation', 'Set up conventional commits and use semantic-release to automatically bump version and generate CHANGELOG.md on CI.', 'Git-DevOps', 'medium', 'https://semantic-release.gitbook.io/semantic-release', TRUE),
(191, 'Write unit tests for a calculator service', 'Write comprehensive JUnit/Jest unit tests for a calculator with add, subtract, multiply, divide, modulo. Include boundary cases and exception testing.', 'Testing', 'easy', 'https://junit.org/junit5/docs/current/user-guide/', TRUE),
(192, 'Write integration tests for a REST API', 'Write integration tests for a CRUD REST API covering all endpoints, including error cases, authentication, and database state verification.', 'Testing', 'medium', 'https://supertest.npmjs.com/', TRUE),
(193, 'Implement test-driven development (TDD) for a user service', 'Use TDD (Red-Green-Refactor) to build a UserService with register, login, update profile, delete account. Write failing tests first.', 'Testing', 'medium', 'https://www.agilealliance.org/glossary/tdd/', TRUE),
(194, 'Set up end-to-end testing with Playwright', 'Write Playwright E2E tests for a web application covering: login flow, form submission, navigation, and error states.', 'Testing', 'hard', 'https://playwright.dev/docs/writing-tests', TRUE),
(195, 'Write tests for concurrent code', 'Write tests that verify thread safety for a concurrent bank account implementation. Use multiple threads and assert no race conditions occur.', 'Testing', 'hard', 'https://www.baeldung.com/java-testing-multithreaded', TRUE),
(196, 'Implement a test doubles strategy (mocks, stubs, fakes)', 'Practice using mocks for external services, stubs for dependencies, and fakes for databases in a payment processing service.', 'Testing', 'medium', 'https://martinfowler.com/articles/mocksArentStubs.html', TRUE),
(197, 'Write property-based tests', 'Use a property-based testing library (QuickCheck/Hypothesis) to generate thousands of test cases for a sorting algorithm and string processing functions.', 'Testing', 'hard', 'https://hypothesis.readthedocs.io/', TRUE),
(198, 'Measure and improve code coverage', 'Add test coverage measurement to a project, identify untested branches, write tests to achieve 85%+ coverage, and integrate into CI.', 'Testing', 'medium', 'https://istanbul.js.org/', TRUE),
(199, 'Write performance tests with JMeter', 'Create a JMeter test plan to load test a REST API with 100 concurrent users, measure response times, and identify the breaking point.', 'Testing', 'hard', 'https://jmeter.apache.org/usermanual/get-started.html', TRUE),
(200, 'Implement contract testing with Pact', 'Write consumer-driven contract tests between a web frontend and a backend API using Pact to ensure API compatibility.', 'Testing', 'hard', 'https://docs.pact.io/', TRUE),
(201, 'Deploy a static website to AWS S3 + CloudFront', 'Deploy a static HTML/CSS/JS website to S3, configure static hosting, set up CloudFront distribution, and add a custom domain.', 'Cloud Basics', 'easy', 'https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html', TRUE),
(202, 'Set up a serverless function with AWS Lambda', 'Create a Lambda function triggered by an API Gateway that processes JSON input, calls a DynamoDB table, and returns a response.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/lambda/latest/dg/getting-started.html', TRUE),
(203, 'Configure AWS IAM roles and policies', 'Practice the principle of least privilege: create IAM roles with minimal permissions for an EC2 instance, Lambda, and RDS access.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html', TRUE),
(204, 'Deploy a containerized app to Google Cloud Run', 'Containerize a web app with Docker, push to Google Container Registry, and deploy to Cloud Run with auto-scaling configuration.', 'Cloud Basics', 'medium', 'https://cloud.google.com/run/docs/quickstarts', TRUE),
(205, 'Set up managed PostgreSQL on Supabase', 'Create a Supabase project, design a schema with RLS policies, connect from a web app, and test CRUD operations with the JavaScript client.', 'Cloud Basics', 'easy', 'https://supabase.com/docs', TRUE),
(206, 'Implement object storage with lifecycle policies', 'Configure S3 bucket with lifecycle rules: move objects to Glacier after 30 days, delete after 365 days. Test with simulated uploads.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html', TRUE),
(207, 'Set up autoscaling for a web application', 'Configure AWS Auto Scaling Group with launch template, scaling policies (target tracking), and load balancer health checks.', 'Cloud Basics', 'hard', 'https://docs.aws.amazon.com/autoscaling/ec2/userguide/get-started-with-ec2-auto-scaling.html', TRUE),
(208, 'Build a serverless image resizing pipeline', 'Create an event-driven pipeline: S3 upload triggers Lambda, Lambda resizes image using Sharp, saves thumbnails back to S3.', 'Cloud Basics', 'hard', 'https://aws.amazon.com/blogs/compute/resize-images-on-the-fly-with-amazon-s3-aws-lambda-and-amazon-api-gateway/', TRUE),
(209, 'Set up cloud monitoring and alerts', 'Configure CloudWatch metrics, create alarms for CPU >80% and error rate >5%, and set up SNS notifications for incidents.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/', TRUE),
(210, 'Implement multi-region failover', 'Design and implement an active-passive multi-region setup with Route53 health checks and automatic failover for a stateless web application.', 'Cloud Basics', 'hard', 'https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover.html', TRUE),
(211, 'Build a responsive landing page with HTML/CSS Grid', 'Create a responsive landing page using CSS Grid layout. Include a hero section, features list, and footer. Must work on mobile and desktop.', 'Web Dev', 'easy', 'https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_grid_layout', TRUE),
(212, 'Create a multi-step form with validation', 'Build a multi-step registration form with client-side validation, progress indicator, and animated transitions between steps.', 'Web Dev', 'medium', 'https://developer.mozilla.org/en-US/docs/Learn/Forms', TRUE),
(213, 'Implement a REST API using Node.js and Express', 'Build a CRUD REST API for a blog system with endpoints for posts, comments, and tags. Include proper error handling.', 'Web Dev', 'medium', 'https://expressjs.com/en/starter/basic-routing.html', TRUE),
(214, 'Create a real-time chat UI using WebSockets concept', 'Design a chat interface that demonstrates understanding of WebSocket event flow. Mock the backend with a local event bus.', 'Web Dev', 'hard', 'https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API', TRUE),
(215, 'Build a weather dashboard using a public API', 'Fetch weather data from OpenWeatherMap API and display current weather, 5-day forecast, and a temperature chart.', 'Web Dev', 'easy', 'https://openweathermap.org/api', TRUE),
(216, 'Implement dark/light theme toggle with CSS variables', 'Add a theme toggle that switches between dark and light modes using CSS custom properties (variables) and localStorage persistence.', 'Web Dev', 'easy', 'https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties', TRUE),
(217, 'Build an infinite scroll list component', 'Create a paginated list that loads more items when the user scrolls to the bottom using Intersection Observer API.', 'Web Dev', 'medium', 'https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API', TRUE),
(218, 'Create a drag-and-drop Kanban board', 'Build a Kanban board with three columns (Todo, In Progress, Done) and drag-and-drop functionality using HTML5 drag events.', 'Web Dev', 'hard', 'https://developer.mozilla.org/en-US/docs/Web/API/HTML_Drag_and_Drop_API', TRUE),
(219, 'Build a markdown preview editor', 'Create a split-pane editor where the left side accepts markdown text and the right side renders live HTML preview.', 'Web Dev', 'medium', 'https://marked.js.org/', TRUE),
(220, 'Implement JWT authentication flow', 'Build a complete login/register flow with JWT tokens, refresh token logic, and protected routes. Mock the backend.', 'Web Dev', 'hard', 'https://jwt.io/introduction', TRUE),
(221, 'Design an ER diagram for a hospital management system', 'Create a complete ER diagram with entities: Patient, Doctor, Appointment, Ward, Medicine, Prescription. Show all relationships and cardinalities.', 'DBMS', 'easy', 'https://www.geeksforgeeks.org/er-model/', TRUE),
(222, 'Write complex SQL queries for a sales database', 'Given a sales DB schema (Customers, Orders, Products, OrderItems), write 10 queries using JOINs, GROUP BY, HAVING, subqueries, and window functions.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/tutorial-sql.html', TRUE),
(223, 'Normalize a given table to 3NF', 'Take an unnormalized spreadsheet of student enrollment data and normalize it through 1NF, 2NF, and 3NF. Show each step.', 'DBMS', 'medium', 'https://www.geeksforgeeks.org/normalization-of-database/', TRUE),
(224, 'Implement indexing strategy for a slow query', 'Analyze a slow query on a 1M-row orders table. Create appropriate indexes (B-Tree, composite, partial) and explain the execution plan difference.', 'DBMS', 'hard', 'https://use-the-index-luke.com/', TRUE),
(225, 'Build a stored procedure for student grade calculation', 'Write a PL/pgSQL stored procedure that calculates semester GPA, updates the students table, and logs changes to an audit table.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/plpgsql.html', TRUE),
(226, 'Design a database for an e-commerce platform', 'Design a complete relational schema for an e-commerce platform with Products, Variants, Inventory, Orders, Payments, Reviews, and Coupons.', 'DBMS', 'hard', 'https://www.vertabelo.com/blog/e-commerce-database/', TRUE),
(227, 'Write a trigger to prevent negative stock', 'Create a BEFORE INSERT/UPDATE trigger on an inventory table that raises an exception if stock would go below zero.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/sql-createtrigger.html', TRUE),
(228, 'Implement a recursive CTE for org chart traversal', 'Use a recursive Common Table Expression to traverse an employee hierarchy table and find all subordinates of a given manager.', 'DBMS', 'hard', 'https://www.postgresql.org/docs/current/queries-with.html', TRUE),
(229, 'Design a time-series schema for sensor data', 'Design and implement a schema optimized for storing IoT sensor readings with efficient range queries and aggregations.', 'DBMS', 'medium', 'https://www.timescale.com/blog/time-series-data/', TRUE),
(230, 'Build a full-text search query', 'Use PostgreSQL full-text search (tsvector, tsquery, GIN index) to implement smart search on a products table.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/textsearch.html', TRUE),
(231, 'Implement a generic Stack and Queue in Java', 'Create type-safe generic Stack and Queue implementations using arrays. Implement push, pop, peek, isEmpty, size methods with proper exception handling.', 'OOP-Java', 'easy', 'https://docs.oracle.com/en/java/docs/', TRUE),
(232, 'Design a library management system using OOP principles', 'Build a library system with classes: Book, Member, Librarian, Loan. Apply inheritance, encapsulation, and polymorphism. Include a simple CLI.', 'OOP-Java', 'medium', 'https://docs.oracle.com/javase/tutorial/java/concepts/', TRUE),
(233, 'Implement the Observer design pattern', 'Create an event notification system using the Observer pattern with multiple concrete subscribers for a news publishing system.', 'OOP-Java', 'medium', 'https://refactoring.guru/design-patterns/observer', TRUE),
(234, 'Build a thread-safe bank account system', 'Implement BankAccount with deposit, withdraw, transfer operations using synchronized methods and proper concurrency control to avoid race conditions.', 'OOP-Java', 'hard', 'https://docs.oracle.com/javase/tutorial/essential/concurrency/', TRUE),
(235, 'Implement a simple IoC container (Dependency Injection)', 'Build a basic dependency injection container that resolves constructor dependencies using reflection.', 'OOP-Java', 'hard', 'https://docs.oracle.com/javase/tutorial/reflect/', TRUE),
(236, 'Create a Builder pattern for a complex object', 'Implement the Builder pattern for constructing a complex Pizza order with optional toppings, size, crust type using fluent interface.', 'OOP-Java', 'easy', 'https://refactoring.guru/design-patterns/builder', TRUE),
(237, 'Build a simple expression evaluator using Composite pattern', 'Parse and evaluate mathematical expressions (+ - * /) using the Composite design pattern with leaf and branch nodes.', 'OOP-Java', 'medium', 'https://refactoring.guru/design-patterns/composite', TRUE),
(238, 'Implement a connection pool', 'Build a generic connection pool with configurable min/max pool size, idle timeout, and thread-safe borrowing/returning of connections.', 'OOP-Java', 'hard', 'https://en.wikipedia.org/wiki/Connection_pool', TRUE),
(239, 'Design an Animal hierarchy with abstract classes', 'Create an Animal hierarchy with abstract methods sound() and move(). Implement Dog, Cat, Bird, Fish subclasses. Override toString and equals.', 'OOP-Java', 'easy', 'https://docs.oracle.com/javase/tutorial/java/IandI/abstract.html', TRUE),
(240, 'Build a simple rule engine using Strategy pattern', 'Implement a discount rule engine for an e-commerce platform using the Strategy pattern. Rules: percentage off, flat discount, BOGO.', 'OOP-Java', 'medium', 'https://refactoring.guru/design-patterns/strategy', TRUE),
(241, 'Design URL Shortener (like bit.ly)', 'Design a scalable URL shortener service. Include: API design, database schema, hashing algorithm, caching layer, and scaling strategy.', 'System Design', 'medium', 'https://systemdesign.one/url-shortening-system-design/', TRUE),
(242, 'Design a notification delivery system', 'Design a system that sends email, SMS, and push notifications to millions of users. Cover: message queues, retry logic, rate limiting, fan-out.', 'System Design', 'hard', 'https://bytebytego.com/', TRUE),
(243, 'Design a rate limiter', 'Design a distributed rate limiter using token bucket algorithm. Show API design, Redis-based implementation, and edge cases.', 'System Design', 'medium', 'https://stripe.com/blog/rate-limiters', TRUE),
(244, 'Design a distributed cache', 'Design a distributed caching system (like Redis cluster). Cover: consistent hashing, cache eviction, cache-aside pattern, invalidation strategies.', 'System Design', 'hard', 'https://redis.io/docs/manual/scaling/', TRUE),
(245, 'Design a ride-sharing location service', 'Design the backend for tracking driver locations in real-time for a ride-sharing app. Focus on geospatial indexing and low-latency updates.', 'System Design', 'hard', 'https://geohash.softeng.co/', TRUE),
(246, 'Design a file storage system (like Google Drive)', 'Design a file storage and sharing service. Cover: chunked upload, deduplication, metadata DB, CDN, access control.', 'System Design', 'hard', 'https://systemdesign.one/google-drive-system-design/', TRUE),
(247, 'Design an API gateway', 'Design an API gateway for a microservices architecture. Include: routing, authentication, rate limiting, logging, circuit breaking.', 'System Design', 'medium', 'https://microservices.io/patterns/apigateway.html', TRUE),
(248, 'Design a search autocomplete system', 'Design a type-ahead search suggestion system for an e-commerce site handling 100K QPS. Include trie-based approach and Elasticsearch alternative.', 'System Design', 'medium', 'https://bytebytego.com/', TRUE),
(249, 'Design a message queue system', 'Design a persistent message queue (like Kafka). Cover: partitioning, replication, offset management, consumer groups, delivery semantics.', 'System Design', 'hard', 'https://kafka.apache.org/documentation/', TRUE),
(250, 'Design a leaderboard system', 'Design a real-time leaderboard for a gaming platform with 1M players. Use sorted sets (Redis ZSET) and handle score updates efficiently.', 'System Design', 'medium', 'https://redis.io/docs/data-types/sorted-sets/', TRUE),
(251, 'Set up a complete CI/CD pipeline with GitHub Actions', 'Create a GitHub Actions workflow that runs tests, lints code, builds Docker image, and deploys to a staging environment on PR merge.', 'Git-DevOps', 'medium', 'https://docs.github.com/en/actions', TRUE),
(252, 'Implement Git branching strategy for a team project', 'Document and implement a Git Flow branching strategy with main, develop, feature, release, and hotfix branches. Practice the full workflow.', 'Git-DevOps', 'easy', 'https://nvie.com/posts/a-successful-git-branching-model/', TRUE),
(253, 'Create a multi-stage Dockerfile', 'Write a multi-stage Dockerfile for a Node.js application: builder stage installs deps and builds, production stage copies only the built artifact.', 'Git-DevOps', 'medium', 'https://docs.docker.com/build/building/multi-stage/', TRUE),
(254, 'Write a Kubernetes Deployment manifest', 'Write Kubernetes YAML files for Deployment, Service, ConfigMap, and HorizontalPodAutoscaler for a web application.', 'Git-DevOps', 'medium', 'https://kubernetes.io/docs/concepts/workloads/controllers/deployment/', TRUE),
(255, 'Implement infrastructure as code with Terraform', 'Write Terraform configuration to provision an AWS VPC, EC2 instance, RDS database, and S3 bucket with proper security groups.', 'Git-DevOps', 'hard', 'https://developer.hashicorp.com/terraform/tutorials', TRUE),
(256, 'Set up monitoring with Prometheus and Grafana', 'Configure Prometheus to scrape metrics from a Node.js app and create Grafana dashboards for request rate, error rate, and latency (RED metrics).', 'Git-DevOps', 'hard', 'https://grafana.com/docs/grafana/latest/', TRUE),
(257, 'Automate database migrations in CI/CD', 'Integrate database migration tool (Flyway or Liquibase) into a CI pipeline so migrations run automatically before deployment.', 'Git-DevOps', 'medium', 'https://flywaydb.org/documentation/', TRUE),
(258, 'Create a git pre-commit hook for code quality', 'Write a git pre-commit hook script that runs ESLint/Prettier checks and blocks the commit if code quality checks fail.', 'Git-DevOps', 'easy', 'https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks', TRUE),
(259, 'Build a Docker Compose setup for local development', 'Create a docker-compose.yml that runs a web app, PostgreSQL, Redis, and a reverse proxy (Nginx) for local development.', 'Git-DevOps', 'easy', 'https://docs.docker.com/compose/', TRUE),
(260, 'Implement semantic versioning and changelog automation', 'Set up conventional commits and use semantic-release to automatically bump version and generate CHANGELOG.md on CI.', 'Git-DevOps', 'medium', 'https://semantic-release.gitbook.io/semantic-release', TRUE),
(261, 'Write unit tests for a calculator service', 'Write comprehensive JUnit/Jest unit tests for a calculator with add, subtract, multiply, divide, modulo. Include boundary cases and exception testing.', 'Testing', 'easy', 'https://junit.org/junit5/docs/current/user-guide/', TRUE),
(262, 'Write integration tests for a REST API', 'Write integration tests for a CRUD REST API covering all endpoints, including error cases, authentication, and database state verification.', 'Testing', 'medium', 'https://supertest.npmjs.com/', TRUE),
(263, 'Implement test-driven development (TDD) for a user service', 'Use TDD (Red-Green-Refactor) to build a UserService with register, login, update profile, delete account. Write failing tests first.', 'Testing', 'medium', 'https://www.agilealliance.org/glossary/tdd/', TRUE),
(264, 'Set up end-to-end testing with Playwright', 'Write Playwright E2E tests for a web application covering: login flow, form submission, navigation, and error states.', 'Testing', 'hard', 'https://playwright.dev/docs/writing-tests', TRUE),
(265, 'Write tests for concurrent code', 'Write tests that verify thread safety for a concurrent bank account implementation. Use multiple threads and assert no race conditions occur.', 'Testing', 'hard', 'https://www.baeldung.com/java-testing-multithreaded', TRUE),
(266, 'Implement a test doubles strategy (mocks, stubs, fakes)', 'Practice using mocks for external services, stubs for dependencies, and fakes for databases in a payment processing service.', 'Testing', 'medium', 'https://martinfowler.com/articles/mocksArentStubs.html', TRUE),
(267, 'Write property-based tests', 'Use a property-based testing library (QuickCheck/Hypothesis) to generate thousands of test cases for a sorting algorithm and string processing functions.', 'Testing', 'hard', 'https://hypothesis.readthedocs.io/', TRUE),
(268, 'Measure and improve code coverage', 'Add test coverage measurement to a project, identify untested branches, write tests to achieve 85%+ coverage, and integrate into CI.', 'Testing', 'medium', 'https://istanbul.js.org/', TRUE),
(269, 'Write performance tests with JMeter', 'Create a JMeter test plan to load test a REST API with 100 concurrent users, measure response times, and identify the breaking point.', 'Testing', 'hard', 'https://jmeter.apache.org/usermanual/get-started.html', TRUE),
(270, 'Implement contract testing with Pact', 'Write consumer-driven contract tests between a web frontend and a backend API using Pact to ensure API compatibility.', 'Testing', 'hard', 'https://docs.pact.io/', TRUE),
(271, 'Deploy a static website to AWS S3 + CloudFront', 'Deploy a static HTML/CSS/JS website to S3, configure static hosting, set up CloudFront distribution, and add a custom domain.', 'Cloud Basics', 'easy', 'https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html', TRUE),
(272, 'Set up a serverless function with AWS Lambda', 'Create a Lambda function triggered by an API Gateway that processes JSON input, calls a DynamoDB table, and returns a response.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/lambda/latest/dg/getting-started.html', TRUE),
(273, 'Configure AWS IAM roles and policies', 'Practice the principle of least privilege: create IAM roles with minimal permissions for an EC2 instance, Lambda, and RDS access.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html', TRUE),
(274, 'Deploy a containerized app to Google Cloud Run', 'Containerize a web app with Docker, push to Google Container Registry, and deploy to Cloud Run with auto-scaling configuration.', 'Cloud Basics', 'medium', 'https://cloud.google.com/run/docs/quickstarts', TRUE),
(275, 'Set up managed PostgreSQL on Supabase', 'Create a Supabase project, design a schema with RLS policies, connect from a web app, and test CRUD operations with the JavaScript client.', 'Cloud Basics', 'easy', 'https://supabase.com/docs', TRUE),
(276, 'Implement object storage with lifecycle policies', 'Configure S3 bucket with lifecycle rules: move objects to Glacier after 30 days, delete after 365 days. Test with simulated uploads.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html', TRUE),
(277, 'Set up autoscaling for a web application', 'Configure AWS Auto Scaling Group with launch template, scaling policies (target tracking), and load balancer health checks.', 'Cloud Basics', 'hard', 'https://docs.aws.amazon.com/autoscaling/ec2/userguide/get-started-with-ec2-auto-scaling.html', TRUE),
(278, 'Build a serverless image resizing pipeline', 'Create an event-driven pipeline: S3 upload triggers Lambda, Lambda resizes image using Sharp, saves thumbnails back to S3.', 'Cloud Basics', 'hard', 'https://aws.amazon.com/blogs/compute/resize-images-on-the-fly-with-amazon-s3-aws-lambda-and-amazon-api-gateway/', TRUE),
(279, 'Set up cloud monitoring and alerts', 'Configure CloudWatch metrics, create alarms for CPU >80% and error rate >5%, and set up SNS notifications for incidents.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/', TRUE),
(280, 'Implement multi-region failover', 'Design and implement an active-passive multi-region setup with Route53 health checks and automatic failover for a stateless web application.', 'Cloud Basics', 'hard', 'https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover.html', TRUE),
(281, 'Build a responsive landing page with HTML/CSS Grid', 'Create a responsive landing page using CSS Grid layout. Include a hero section, features list, and footer. Must work on mobile and desktop.', 'Web Dev', 'easy', 'https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_grid_layout', TRUE),
(282, 'Create a multi-step form with validation', 'Build a multi-step registration form with client-side validation, progress indicator, and animated transitions between steps.', 'Web Dev', 'medium', 'https://developer.mozilla.org/en-US/docs/Learn/Forms', TRUE),
(283, 'Implement a REST API using Node.js and Express', 'Build a CRUD REST API for a blog system with endpoints for posts, comments, and tags. Include proper error handling.', 'Web Dev', 'medium', 'https://expressjs.com/en/starter/basic-routing.html', TRUE),
(284, 'Create a real-time chat UI using WebSockets concept', 'Design a chat interface that demonstrates understanding of WebSocket event flow. Mock the backend with a local event bus.', 'Web Dev', 'hard', 'https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API', TRUE),
(285, 'Build a weather dashboard using a public API', 'Fetch weather data from OpenWeatherMap API and display current weather, 5-day forecast, and a temperature chart.', 'Web Dev', 'easy', 'https://openweathermap.org/api', TRUE),
(286, 'Implement dark/light theme toggle with CSS variables', 'Add a theme toggle that switches between dark and light modes using CSS custom properties (variables) and localStorage persistence.', 'Web Dev', 'easy', 'https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties', TRUE),
(287, 'Build an infinite scroll list component', 'Create a paginated list that loads more items when the user scrolls to the bottom using Intersection Observer API.', 'Web Dev', 'medium', 'https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API', TRUE),
(288, 'Create a drag-and-drop Kanban board', 'Build a Kanban board with three columns (Todo, In Progress, Done) and drag-and-drop functionality using HTML5 drag events.', 'Web Dev', 'hard', 'https://developer.mozilla.org/en-US/docs/Web/API/HTML_Drag_and_Drop_API', TRUE),
(289, 'Build a markdown preview editor', 'Create a split-pane editor where the left side accepts markdown text and the right side renders live HTML preview.', 'Web Dev', 'medium', 'https://marked.js.org/', TRUE),
(290, 'Implement JWT authentication flow', 'Build a complete login/register flow with JWT tokens, refresh token logic, and protected routes. Mock the backend.', 'Web Dev', 'hard', 'https://jwt.io/introduction', TRUE),
(291, 'Design an ER diagram for a hospital management system', 'Create a complete ER diagram with entities: Patient, Doctor, Appointment, Ward, Medicine, Prescription. Show all relationships and cardinalities.', 'DBMS', 'easy', 'https://www.geeksforgeeks.org/er-model/', TRUE),
(292, 'Write complex SQL queries for a sales database', 'Given a sales DB schema (Customers, Orders, Products, OrderItems), write 10 queries using JOINs, GROUP BY, HAVING, subqueries, and window functions.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/tutorial-sql.html', TRUE),
(293, 'Normalize a given table to 3NF', 'Take an unnormalized spreadsheet of student enrollment data and normalize it through 1NF, 2NF, and 3NF. Show each step.', 'DBMS', 'medium', 'https://www.geeksforgeeks.org/normalization-of-database/', TRUE),
(294, 'Implement indexing strategy for a slow query', 'Analyze a slow query on a 1M-row orders table. Create appropriate indexes (B-Tree, composite, partial) and explain the execution plan difference.', 'DBMS', 'hard', 'https://use-the-index-luke.com/', TRUE),
(295, 'Build a stored procedure for student grade calculation', 'Write a PL/pgSQL stored procedure that calculates semester GPA, updates the students table, and logs changes to an audit table.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/plpgsql.html', TRUE),
(296, 'Design a database for an e-commerce platform', 'Design a complete relational schema for an e-commerce platform with Products, Variants, Inventory, Orders, Payments, Reviews, and Coupons.', 'DBMS', 'hard', 'https://www.vertabelo.com/blog/e-commerce-database/', TRUE),
(297, 'Write a trigger to prevent negative stock', 'Create a BEFORE INSERT/UPDATE trigger on an inventory table that raises an exception if stock would go below zero.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/sql-createtrigger.html', TRUE),
(298, 'Implement a recursive CTE for org chart traversal', 'Use a recursive Common Table Expression to traverse an employee hierarchy table and find all subordinates of a given manager.', 'DBMS', 'hard', 'https://www.postgresql.org/docs/current/queries-with.html', TRUE),
(299, 'Design a time-series schema for sensor data', 'Design and implement a schema optimized for storing IoT sensor readings with efficient range queries and aggregations.', 'DBMS', 'medium', 'https://www.timescale.com/blog/time-series-data/', TRUE),
(300, 'Build a full-text search query', 'Use PostgreSQL full-text search (tsvector, tsquery, GIN index) to implement smart search on a products table.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/textsearch.html', TRUE),
(301, 'Implement a generic Stack and Queue in Java', 'Create type-safe generic Stack and Queue implementations using arrays. Implement push, pop, peek, isEmpty, size methods with proper exception handling.', 'OOP-Java', 'easy', 'https://docs.oracle.com/en/java/docs/', TRUE),
(302, 'Design a library management system using OOP principles', 'Build a library system with classes: Book, Member, Librarian, Loan. Apply inheritance, encapsulation, and polymorphism. Include a simple CLI.', 'OOP-Java', 'medium', 'https://docs.oracle.com/javase/tutorial/java/concepts/', TRUE),
(303, 'Implement the Observer design pattern', 'Create an event notification system using the Observer pattern with multiple concrete subscribers for a news publishing system.', 'OOP-Java', 'medium', 'https://refactoring.guru/design-patterns/observer', TRUE),
(304, 'Build a thread-safe bank account system', 'Implement BankAccount with deposit, withdraw, transfer operations using synchronized methods and proper concurrency control to avoid race conditions.', 'OOP-Java', 'hard', 'https://docs.oracle.com/javase/tutorial/essential/concurrency/', TRUE),
(305, 'Implement a simple IoC container (Dependency Injection)', 'Build a basic dependency injection container that resolves constructor dependencies using reflection.', 'OOP-Java', 'hard', 'https://docs.oracle.com/javase/tutorial/reflect/', TRUE),
(306, 'Create a Builder pattern for a complex object', 'Implement the Builder pattern for constructing a complex Pizza order with optional toppings, size, crust type using fluent interface.', 'OOP-Java', 'easy', 'https://refactoring.guru/design-patterns/builder', TRUE),
(307, 'Build a simple expression evaluator using Composite pattern', 'Parse and evaluate mathematical expressions (+ - * /) using the Composite design pattern with leaf and branch nodes.', 'OOP-Java', 'medium', 'https://refactoring.guru/design-patterns/composite', TRUE),
(308, 'Implement a connection pool', 'Build a generic connection pool with configurable min/max pool size, idle timeout, and thread-safe borrowing/returning of connections.', 'OOP-Java', 'hard', 'https://en.wikipedia.org/wiki/Connection_pool', TRUE),
(309, 'Design an Animal hierarchy with abstract classes', 'Create an Animal hierarchy with abstract methods sound() and move(). Implement Dog, Cat, Bird, Fish subclasses. Override toString and equals.', 'OOP-Java', 'easy', 'https://docs.oracle.com/javase/tutorial/java/IandI/abstract.html', TRUE),
(310, 'Build a simple rule engine using Strategy pattern', 'Implement a discount rule engine for an e-commerce platform using the Strategy pattern. Rules: percentage off, flat discount, BOGO.', 'OOP-Java', 'medium', 'https://refactoring.guru/design-patterns/strategy', TRUE),
(311, 'Design URL Shortener (like bit.ly)', 'Design a scalable URL shortener service. Include: API design, database schema, hashing algorithm, caching layer, and scaling strategy.', 'System Design', 'medium', 'https://systemdesign.one/url-shortening-system-design/', TRUE),
(312, 'Design a notification delivery system', 'Design a system that sends email, SMS, and push notifications to millions of users. Cover: message queues, retry logic, rate limiting, fan-out.', 'System Design', 'hard', 'https://bytebytego.com/', TRUE),
(313, 'Design a rate limiter', 'Design a distributed rate limiter using token bucket algorithm. Show API design, Redis-based implementation, and edge cases.', 'System Design', 'medium', 'https://stripe.com/blog/rate-limiters', TRUE),
(314, 'Design a distributed cache', 'Design a distributed caching system (like Redis cluster). Cover: consistent hashing, cache eviction, cache-aside pattern, invalidation strategies.', 'System Design', 'hard', 'https://redis.io/docs/manual/scaling/', TRUE),
(315, 'Design a ride-sharing location service', 'Design the backend for tracking driver locations in real-time for a ride-sharing app. Focus on geospatial indexing and low-latency updates.', 'System Design', 'hard', 'https://geohash.softeng.co/', TRUE),
(316, 'Design a file storage system (like Google Drive)', 'Design a file storage and sharing service. Cover: chunked upload, deduplication, metadata DB, CDN, access control.', 'System Design', 'hard', 'https://systemdesign.one/google-drive-system-design/', TRUE),
(317, 'Design an API gateway', 'Design an API gateway for a microservices architecture. Include: routing, authentication, rate limiting, logging, circuit breaking.', 'System Design', 'medium', 'https://microservices.io/patterns/apigateway.html', TRUE),
(318, 'Design a search autocomplete system', 'Design a type-ahead search suggestion system for an e-commerce site handling 100K QPS. Include trie-based approach and Elasticsearch alternative.', 'System Design', 'medium', 'https://bytebytego.com/', TRUE),
(319, 'Design a message queue system', 'Design a persistent message queue (like Kafka). Cover: partitioning, replication, offset management, consumer groups, delivery semantics.', 'System Design', 'hard', 'https://kafka.apache.org/documentation/', TRUE),
(320, 'Design a leaderboard system', 'Design a real-time leaderboard for a gaming platform with 1M players. Use sorted sets (Redis ZSET) and handle score updates efficiently.', 'System Design', 'medium', 'https://redis.io/docs/data-types/sorted-sets/', TRUE),
(321, 'Set up a complete CI/CD pipeline with GitHub Actions', 'Create a GitHub Actions workflow that runs tests, lints code, builds Docker image, and deploys to a staging environment on PR merge.', 'Git-DevOps', 'medium', 'https://docs.github.com/en/actions', TRUE),
(322, 'Implement Git branching strategy for a team project', 'Document and implement a Git Flow branching strategy with main, develop, feature, release, and hotfix branches. Practice the full workflow.', 'Git-DevOps', 'easy', 'https://nvie.com/posts/a-successful-git-branching-model/', TRUE),
(323, 'Create a multi-stage Dockerfile', 'Write a multi-stage Dockerfile for a Node.js application: builder stage installs deps and builds, production stage copies only the built artifact.', 'Git-DevOps', 'medium', 'https://docs.docker.com/build/building/multi-stage/', TRUE),
(324, 'Write a Kubernetes Deployment manifest', 'Write Kubernetes YAML files for Deployment, Service, ConfigMap, and HorizontalPodAutoscaler for a web application.', 'Git-DevOps', 'medium', 'https://kubernetes.io/docs/concepts/workloads/controllers/deployment/', TRUE),
(325, 'Implement infrastructure as code with Terraform', 'Write Terraform configuration to provision an AWS VPC, EC2 instance, RDS database, and S3 bucket with proper security groups.', 'Git-DevOps', 'hard', 'https://developer.hashicorp.com/terraform/tutorials', TRUE),
(326, 'Set up monitoring with Prometheus and Grafana', 'Configure Prometheus to scrape metrics from a Node.js app and create Grafana dashboards for request rate, error rate, and latency (RED metrics).', 'Git-DevOps', 'hard', 'https://grafana.com/docs/grafana/latest/', TRUE),
(327, 'Automate database migrations in CI/CD', 'Integrate database migration tool (Flyway or Liquibase) into a CI pipeline so migrations run automatically before deployment.', 'Git-DevOps', 'medium', 'https://flywaydb.org/documentation/', TRUE),
(328, 'Create a git pre-commit hook for code quality', 'Write a git pre-commit hook script that runs ESLint/Prettier checks and blocks the commit if code quality checks fail.', 'Git-DevOps', 'easy', 'https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks', TRUE),
(329, 'Build a Docker Compose setup for local development', 'Create a docker-compose.yml that runs a web app, PostgreSQL, Redis, and a reverse proxy (Nginx) for local development.', 'Git-DevOps', 'easy', 'https://docs.docker.com/compose/', TRUE),
(330, 'Implement semantic versioning and changelog automation', 'Set up conventional commits and use semantic-release to automatically bump version and generate CHANGELOG.md on CI.', 'Git-DevOps', 'medium', 'https://semantic-release.gitbook.io/semantic-release', TRUE),
(331, 'Write unit tests for a calculator service', 'Write comprehensive JUnit/Jest unit tests for a calculator with add, subtract, multiply, divide, modulo. Include boundary cases and exception testing.', 'Testing', 'easy', 'https://junit.org/junit5/docs/current/user-guide/', TRUE),
(332, 'Write integration tests for a REST API', 'Write integration tests for a CRUD REST API covering all endpoints, including error cases, authentication, and database state verification.', 'Testing', 'medium', 'https://supertest.npmjs.com/', TRUE),
(333, 'Implement test-driven development (TDD) for a user service', 'Use TDD (Red-Green-Refactor) to build a UserService with register, login, update profile, delete account. Write failing tests first.', 'Testing', 'medium', 'https://www.agilealliance.org/glossary/tdd/', TRUE),
(334, 'Set up end-to-end testing with Playwright', 'Write Playwright E2E tests for a web application covering: login flow, form submission, navigation, and error states.', 'Testing', 'hard', 'https://playwright.dev/docs/writing-tests', TRUE),
(335, 'Write tests for concurrent code', 'Write tests that verify thread safety for a concurrent bank account implementation. Use multiple threads and assert no race conditions occur.', 'Testing', 'hard', 'https://www.baeldung.com/java-testing-multithreaded', TRUE),
(336, 'Implement a test doubles strategy (mocks, stubs, fakes)', 'Practice using mocks for external services, stubs for dependencies, and fakes for databases in a payment processing service.', 'Testing', 'medium', 'https://martinfowler.com/articles/mocksArentStubs.html', TRUE),
(337, 'Write property-based tests', 'Use a property-based testing library (QuickCheck/Hypothesis) to generate thousands of test cases for a sorting algorithm and string processing functions.', 'Testing', 'hard', 'https://hypothesis.readthedocs.io/', TRUE),
(338, 'Measure and improve code coverage', 'Add test coverage measurement to a project, identify untested branches, write tests to achieve 85%+ coverage, and integrate into CI.', 'Testing', 'medium', 'https://istanbul.js.org/', TRUE),
(339, 'Write performance tests with JMeter', 'Create a JMeter test plan to load test a REST API with 100 concurrent users, measure response times, and identify the breaking point.', 'Testing', 'hard', 'https://jmeter.apache.org/usermanual/get-started.html', TRUE),
(340, 'Implement contract testing with Pact', 'Write consumer-driven contract tests between a web frontend and a backend API using Pact to ensure API compatibility.', 'Testing', 'hard', 'https://docs.pact.io/', TRUE),
(341, 'Deploy a static website to AWS S3 + CloudFront', 'Deploy a static HTML/CSS/JS website to S3, configure static hosting, set up CloudFront distribution, and add a custom domain.', 'Cloud Basics', 'easy', 'https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html', TRUE),
(342, 'Set up a serverless function with AWS Lambda', 'Create a Lambda function triggered by an API Gateway that processes JSON input, calls a DynamoDB table, and returns a response.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/lambda/latest/dg/getting-started.html', TRUE),
(343, 'Configure AWS IAM roles and policies', 'Practice the principle of least privilege: create IAM roles with minimal permissions for an EC2 instance, Lambda, and RDS access.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html', TRUE),
(344, 'Deploy a containerized app to Google Cloud Run', 'Containerize a web app with Docker, push to Google Container Registry, and deploy to Cloud Run with auto-scaling configuration.', 'Cloud Basics', 'medium', 'https://cloud.google.com/run/docs/quickstarts', TRUE),
(345, 'Set up managed PostgreSQL on Supabase', 'Create a Supabase project, design a schema with RLS policies, connect from a web app, and test CRUD operations with the JavaScript client.', 'Cloud Basics', 'easy', 'https://supabase.com/docs', TRUE),
(346, 'Implement object storage with lifecycle policies', 'Configure S3 bucket with lifecycle rules: move objects to Glacier after 30 days, delete after 365 days. Test with simulated uploads.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html', TRUE),
(347, 'Set up autoscaling for a web application', 'Configure AWS Auto Scaling Group with launch template, scaling policies (target tracking), and load balancer health checks.', 'Cloud Basics', 'hard', 'https://docs.aws.amazon.com/autoscaling/ec2/userguide/get-started-with-ec2-auto-scaling.html', TRUE),
(348, 'Build a serverless image resizing pipeline', 'Create an event-driven pipeline: S3 upload triggers Lambda, Lambda resizes image using Sharp, saves thumbnails back to S3.', 'Cloud Basics', 'hard', 'https://aws.amazon.com/blogs/compute/resize-images-on-the-fly-with-amazon-s3-aws-lambda-and-amazon-api-gateway/', TRUE),
(349, 'Set up cloud monitoring and alerts', 'Configure CloudWatch metrics, create alarms for CPU >80% and error rate >5%, and set up SNS notifications for incidents.', 'Cloud Basics', 'medium', 'https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/', TRUE),
(350, 'Implement multi-region failover', 'Design and implement an active-passive multi-region setup with Route53 health checks and automatic failover for a stateless web application.', 'Cloud Basics', 'hard', 'https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover.html', TRUE),
(351, 'Build a responsive landing page with HTML/CSS Grid', 'Create a responsive landing page using CSS Grid layout. Include a hero section, features list, and footer. Must work on mobile and desktop.', 'Web Dev', 'easy', 'https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_grid_layout', TRUE),
(352, 'Create a multi-step form with validation', 'Build a multi-step registration form with client-side validation, progress indicator, and animated transitions between steps.', 'Web Dev', 'medium', 'https://developer.mozilla.org/en-US/docs/Learn/Forms', TRUE),
(353, 'Implement a REST API using Node.js and Express', 'Build a CRUD REST API for a blog system with endpoints for posts, comments, and tags. Include proper error handling.', 'Web Dev', 'medium', 'https://expressjs.com/en/starter/basic-routing.html', TRUE),
(354, 'Create a real-time chat UI using WebSockets concept', 'Design a chat interface that demonstrates understanding of WebSocket event flow. Mock the backend with a local event bus.', 'Web Dev', 'hard', 'https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API', TRUE),
(355, 'Build a weather dashboard using a public API', 'Fetch weather data from OpenWeatherMap API and display current weather, 5-day forecast, and a temperature chart.', 'Web Dev', 'easy', 'https://openweathermap.org/api', TRUE),
(356, 'Implement dark/light theme toggle with CSS variables', 'Add a theme toggle that switches between dark and light modes using CSS custom properties (variables) and localStorage persistence.', 'Web Dev', 'easy', 'https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties', TRUE),
(357, 'Build an infinite scroll list component', 'Create a paginated list that loads more items when the user scrolls to the bottom using Intersection Observer API.', 'Web Dev', 'medium', 'https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API', TRUE),
(358, 'Create a drag-and-drop Kanban board', 'Build a Kanban board with three columns (Todo, In Progress, Done) and drag-and-drop functionality using HTML5 drag events.', 'Web Dev', 'hard', 'https://developer.mozilla.org/en-US/docs/Web/API/HTML_Drag_and_Drop_API', TRUE),
(359, 'Build a markdown preview editor', 'Create a split-pane editor where the left side accepts markdown text and the right side renders live HTML preview.', 'Web Dev', 'medium', 'https://marked.js.org/', TRUE),
(360, 'Implement JWT authentication flow', 'Build a complete login/register flow with JWT tokens, refresh token logic, and protected routes. Mock the backend.', 'Web Dev', 'hard', 'https://jwt.io/introduction', TRUE),
(361, 'Design an ER diagram for a hospital management system', 'Create a complete ER diagram with entities: Patient, Doctor, Appointment, Ward, Medicine, Prescription. Show all relationships and cardinalities.', 'DBMS', 'easy', 'https://www.geeksforgeeks.org/er-model/', TRUE),
(362, 'Write complex SQL queries for a sales database', 'Given a sales DB schema (Customers, Orders, Products, OrderItems), write 10 queries using JOINs, GROUP BY, HAVING, subqueries, and window functions.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/tutorial-sql.html', TRUE),
(363, 'Normalize a given table to 3NF', 'Take an unnormalized spreadsheet of student enrollment data and normalize it through 1NF, 2NF, and 3NF. Show each step.', 'DBMS', 'medium', 'https://www.geeksforgeeks.org/normalization-of-database/', TRUE),
(364, 'Implement indexing strategy for a slow query', 'Analyze a slow query on a 1M-row orders table. Create appropriate indexes (B-Tree, composite, partial) and explain the execution plan difference.', 'DBMS', 'hard', 'https://use-the-index-luke.com/', TRUE),
(365, 'Build a stored procedure for student grade calculation', 'Write a PL/pgSQL stored procedure that calculates semester GPA, updates the students table, and logs changes to an audit table.', 'DBMS', 'medium', 'https://www.postgresql.org/docs/current/plpgsql.html', TRUE)
ON CONFLICT (day_of_year) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  category = EXCLUDED.category,
  difficulty = EXCLUDED.difficulty,
  reference_link = EXCLUDED.reference_link;

SELECT COUNT(*) AS project_tasks_seeded FROM project_task_bank;-- ============================================================
-- PSGMX SQL — FILE 04: Seed 365 Apti & DSA Daily Items
-- Run this FOURTH in Supabase SQL Editor (after file 01)
-- ============================================================

INSERT INTO apti_dsa_daily_bank (day_of_year, dsa_title, dsa_difficulty, dsa_topic, dsa_external_link, dsa_hint, aptitude_questions, is_active)
VALUES
(1, 'Two Sum', 'easy', 'Arrays', 'https://leetcode.com/problems/two-sum/', 'Use a hash map to store complement values as you iterate.', '[{"question": "What is the time complexity of linear search?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 2}, {"question": "Which data structure uses LIFO?", "options": ["Queue", "Stack", "Heap", "Tree"], "correct_option": 1}, {"question": "Train moves at 60 km/h for 2 hours. Distance?", "options": ["60 km", "90 km", "120 km", "180 km"], "correct_option": 2}]', TRUE),
(2, 'Best Time to Buy and Sell Stock', 'easy', 'Arrays', 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/', 'Track the minimum price seen so far and compute max profit at each step.', '[{"question": "Array index starts at?", "options": ["0", "1", "-1", "None"], "correct_option": 0}, {"question": "Which sorting is O(n log n) worst case?", "options": ["Bubble", "Selection", "Merge", "Insertion"], "correct_option": 2}, {"question": "A train travels 150 km in 3 hours. Speed?", "options": ["40 km/h", "45 km/h", "50 km/h", "55 km/h"], "correct_option": 2}]', TRUE),
(3, 'Contains Duplicate', 'easy', 'Arrays', 'https://leetcode.com/problems/contains-duplicate/', 'Use a HashSet — if element already exists, return true.', '[{"question": "HashSet uses which data structure internally?", "options": ["Array", "LinkedList", "HashMap", "Tree"], "correct_option": 2}, {"question": "Time complexity of HashSet lookup?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If 3 workers complete a job in 6 days, how many days for 2 workers?", "options": ["7", "8", "9", "10"], "correct_option": 2}]', TRUE),
(4, 'Product of Array Except Self', 'medium', 'Arrays', 'https://leetcode.com/problems/product-of-array-except-self/', 'Use prefix and suffix product arrays to avoid division.', '[{"question": "What does O(1) space mean?", "options": ["Constant space", "No space", "Linear space", "Log space"], "correct_option": 0}, {"question": "Prefix sum is useful for?", "options": ["Range queries", "Sorting", "Searching", "Hashing"], "correct_option": 0}, {"question": "A sum of first 10 natural numbers?", "options": ["45", "50", "55", "60"], "correct_option": 2}]', TRUE),
(5, 'Maximum Subarray (Kadane''s)', 'medium', 'Arrays', 'https://leetcode.com/problems/maximum-subarray/', 'Kadane''s algorithm: extend or restart subarray at each element.', '[{"question": "Kadane''s algorithm finds?", "options": ["Minimum subarray", "Maximum subarray", "Sorted subarray", "Empty subarray"], "correct_option": 1}, {"question": "Dynamic programming optimizes?", "options": ["Space", "Overlapping subproblems", "Sorting", "Recursion only"], "correct_option": 1}, {"question": "Profit if cost=200 and selling=250?", "options": ["25%", "30%", "35%", "40%"], "correct_option": 0}]', TRUE),
(6, 'Reverse Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/reverse-linked-list/', 'Use three pointers: prev, curr, next. Iterate and reverse links.', '[{"question": "Linked list node contains?", "options": ["Data only", "Data and pointer", "Pointer only", "Address only"], "correct_option": 1}, {"question": "Head of linked list points to?", "options": ["Last node", "First node", "Middle node", "Random node"], "correct_option": 1}, {"question": "LCM of 4 and 6?", "options": ["12", "18", "24", "8"], "correct_option": 0}]', TRUE),
(7, 'Merge Two Sorted Lists', 'easy', 'Linked Lists', 'https://leetcode.com/problems/merge-two-sorted-lists/', 'Use a dummy head and compare nodes from both lists iteratively.', '[{"question": "Dummy node technique helps with?", "options": ["Edge cases at head", "Tail insertion", "Middle insertion", "Sorting"], "correct_option": 0}, {"question": "Space complexity of iterative merge?", "options": ["O(1)", "O(n)", "O(log n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "Average of 10, 20, 30?", "options": ["15", "20", "25", "30"], "correct_option": 1}]', TRUE),
(8, 'Detect Cycle in Linked List', 'medium', 'Linked Lists', 'https://leetcode.com/problems/linked-list-cycle/', 'Floyd''s cycle detection: slow and fast pointers. If they meet, cycle exists.', '[{"question": "Floyd''s algorithm uses how many pointers?", "options": ["1", "2", "3", "4"], "correct_option": 1}, {"question": "Cycle detection time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "If x:y = 3:4 and x=12, y=?", "options": ["14", "16", "18", "20"], "correct_option": 1}]', TRUE),
(9, 'Find Middle of Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/middle-of-the-linked-list/', 'Use slow/fast pointer: slow moves 1 step, fast moves 2 steps.', '[{"question": "In a 5-node list, middle is at?", "options": ["Node 2", "Node 3", "Node 4", "Node 5"], "correct_option": 1}, {"question": "Two-pointer technique time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Train covers 200m in 10s. Speed in km/h?", "options": ["60", "70", "72", "80"], "correct_option": 2}]', TRUE),
(10, 'LRU Cache', 'hard', 'Linked Lists', 'https://leetcode.com/problems/lru-cache/', 'Combine HashMap and doubly linked list for O(1) get and put.', '[{"question": "LRU stands for?", "options": ["Least Recently Used", "Last Recently Updated", "Least Random Unit", "Last Reset Unit"], "correct_option": 0}, {"question": "HashMap gives O(1) for?", "options": ["Insert, Delete, Search", "Sort only", "Range queries", "Traversal"], "correct_option": 0}, {"question": "A pipe fills a tank in 4 hours, another in 6 hours. Together?", "options": ["2.4 hours", "2.6 hours", "3 hours", "5 hours"], "correct_option": 0}]', TRUE),
(11, 'Inorder Traversal of BST', 'easy', 'Trees', 'https://leetcode.com/problems/binary-tree-inorder-traversal/', 'Inorder: Left → Root → Right. Yields sorted output for BST.', '[{"question": "Inorder traversal gives BST in?", "options": ["Sorted order", "Reverse order", "Random order", "Level order"], "correct_option": 0}, {"question": "BST search time complexity?", "options": ["O(log n)", "O(n)", "O(1)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If coins doubled daily from 1, on day 10?", "options": ["512", "1024", "512", "256"], "correct_option": 0}]', TRUE),
(12, 'Maximum Depth of Binary Tree', 'easy', 'Trees', 'https://leetcode.com/problems/maximum-depth-of-binary-tree/', 'Recursively return 1 + max(left depth, right depth). Base case: null = 0.', '[{"question": "DFS uses which data structure?", "options": ["Queue", "Stack", "Array", "Heap"], "correct_option": 1}, {"question": "BFS uses which data structure?", "options": ["Stack", "Queue", "Heap", "LinkedList"], "correct_option": 1}, {"question": "35 is what percent of 700?", "options": ["3%", "4%", "5%", "6%"], "correct_option": 2}]', TRUE),
(13, 'Validate Binary Search Tree', 'medium', 'Trees', 'https://leetcode.com/problems/validate-binary-search-tree/', 'Pass min/max bounds to each node recursively. Left < node < Right.', '[{"question": "BST property: left subtree has?", "options": ["Values > root", "Values < root", "Values = root", "Random values"], "correct_option": 1}, {"question": "Which traversal checks BST validity?", "options": ["Inorder", "Preorder", "Postorder", "Level order"], "correct_option": 0}, {"question": "A man earns 15,000/month and saves 20%. Monthly savings?", "options": ["2,500", "3,000", "3,500", "4,000"], "correct_option": 1}]', TRUE),
(14, 'Level Order Traversal', 'medium', 'Trees', 'https://leetcode.com/problems/binary-tree-level-order-traversal/', 'Use a Queue. Process level by level, tracking level boundaries.', '[{"question": "BFS explores nodes?", "options": ["Depth first", "Level by level", "Randomly", "Root only"], "correct_option": 1}, {"question": "Queue is?", "options": ["LIFO", "FIFO", "LILO", "FILO"], "correct_option": 1}, {"question": "A 10% discount on 500?", "options": ["400", "450", "460", "480"], "correct_option": 1}]', TRUE),
(15, 'Lowest Common Ancestor of BST', 'medium', 'Trees', 'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/', 'If both p and q are less than root, go left. If both greater, go right. Else root is LCA.', '[{"question": "LCA of a tree means?", "options": ["Deepest common node", "Shallowest node", "Root always", "Leaf node"], "correct_option": 0}, {"question": "BST LCA time complexity?", "options": ["O(log n)", "O(n)", "O(n\u00b2)", "O(1)"], "correct_option": 0}, {"question": "Speed = Distance/Time. If d=120km, t=2h, speed?", "options": ["50 km/h", "55 km/h", "60 km/h", "65 km/h"], "correct_option": 2}]', TRUE),
(16, 'Climbing Stairs', 'easy', 'Dynamic Programming', 'https://leetcode.com/problems/climbing-stairs/', 'Fibonacci pattern: f(n) = f(n-1) + f(n-2). Use bottom-up DP.', '[{"question": "Memoization stores?", "options": ["Computed results", "Random data", "Sorted arrays", "Only inputs"], "correct_option": 0}, {"question": "Fibonacci relation is?", "options": ["f(n) = f(n-1) + f(n-2)", "f(n) = f(n-1) * 2", "f(n) = n!", "f(n) = 2^n"], "correct_option": 0}, {"question": "Pipes A and B fill tank in 3h and 6h. Together in?", "options": ["1.5h", "2h", "2.5h", "3h"], "correct_option": 1}]', TRUE),
(17, 'Coin Change', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/coin-change/', 'dp[i] = min coins to make amount i. Try each coin at each amount.', '[{"question": "Greedy always works for coin change?", "options": ["Yes", "No, only for canonical coin systems", "Yes, with sorting", "No, never"], "correct_option": 1}, {"question": "DP bottom-up vs top-down: bottom-up uses?", "options": ["Recursion", "Iteration", "Both", "Neither"], "correct_option": 1}, {"question": "HCF of 12 and 18?", "options": ["3", "6", "9", "12"], "correct_option": 1}]', TRUE),
(18, 'Longest Common Subsequence', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/longest-common-subsequence/', '2D DP: if chars match, dp[i][j] = dp[i-1][j-1] + 1, else max of top/left.', '[{"question": "LCS differs from LCS (substring) because?", "options": ["Must be contiguous", "Need not be contiguous", "Same thing", "Sorted only"], "correct_option": 1}, {"question": "LCS time complexity?", "options": ["O(n)", "O(n log n)", "O(nm)", "O(n\u00b2m)"], "correct_option": 2}, {"question": "Simple interest on 1000 at 5% for 2 years?", "options": ["50", "100", "150", "200"], "correct_option": 1}]', TRUE),
(19, '0/1 Knapsack', 'hard', 'Dynamic Programming', 'https://www.geeksforgeeks.org/0-1-knapsack-problem-dp-10/', 'For each item and capacity, choose max of (include item) or (exclude item).', '[{"question": "0/1 Knapsack: each item can be taken?", "options": ["Multiple times", "Exactly once", "Zero or many times", "Never"], "correct_option": 1}, {"question": "Knapsack time complexity?", "options": ["O(n)", "O(n*W)", "O(n\u00b2)", "O(W)"], "correct_option": 1}, {"question": "20% of 80 + 80% of 20 = ?", "options": ["16", "32", "40", "48"], "correct_option": 1}]', TRUE),
(20, 'Word Break', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/word-break/', 'dp[i] = true if s[0..i] can be segmented using wordDict. Check all prefixes.', '[{"question": "Word break is solved by?", "options": ["Greedy", "DP with boolean array", "Binary search", "Sorting"], "correct_option": 1}, {"question": "Backtracking explores?", "options": ["All possibilities", "Only optimal", "Greedy choices", "Random paths"], "correct_option": 0}, {"question": "Compound interest formula involves?", "options": ["Linear growth", "Exponential growth", "Constant growth", "Logarithmic growth"], "correct_option": 1}]', TRUE),
(21, 'Number of Islands (DFS/BFS)', 'medium', 'Graphs', 'https://leetcode.com/problems/number-of-islands/', 'DFS from each unvisited ''1'' cell, mark all connected cells as visited.', '[{"question": "DFS uses which traversal?", "options": ["Level order", "Depth first", "Breadth first", "Random"], "correct_option": 1}, {"question": "Graph edge connects?", "options": ["Two nodes", "Three nodes", "One node", "All nodes"], "correct_option": 0}, {"question": "If 5 machines make 5 items in 5 min, how many machines for 100 items in 100 min?", "options": ["5", "10", "20", "100"], "correct_option": 0}]', TRUE),
(22, 'Clone Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/clone-graph/', 'BFS/DFS with a HashMap to map original nodes to their clones.', '[{"question": "Deep copy vs shallow copy: deep copy?", "options": ["Copies references", "Copies values recursively", "Copies nothing", "Only copies root"], "correct_option": 1}, {"question": "HashMap in graph cloning ensures?", "options": ["No duplicate clones", "Sorted order", "Faster DFS", "Level order"], "correct_option": 0}, {"question": "A number increased by 20% = 120. Original?", "options": ["90", "95", "100", "110"], "correct_option": 2}]', TRUE),
(23, 'Course Schedule (Topological Sort)', 'medium', 'Graphs', 'https://leetcode.com/problems/course-schedule/', 'Build adjacency list, detect cycle using DFS with 3 states (unvisited, visiting, visited).', '[{"question": "Topological sort applies to?", "options": ["Undirected graphs", "DAGs", "Complete graphs", "Trees only"], "correct_option": 1}, {"question": "Cycle in directed graph means?", "options": ["No topological order", "Easy sorting", "DAG property", "Tree property"], "correct_option": 0}, {"question": "Work rate: A does job in 10 days, B in 15 days. Together?", "options": ["5 days", "6 days", "8 days", "9 days"], "correct_option": 1}]', TRUE),
(24, 'Dijkstra''s Shortest Path', 'hard', 'Graphs', 'https://leetcode.com/problems/network-delay-time/', 'Use min-heap priority queue. Relax edges greedily by choosing shortest known distance.', '[{"question": "Dijkstra works with?", "options": ["Negative weights", "Non-negative weights", "All graphs", "Only trees"], "correct_option": 1}, {"question": "Dijkstra uses?", "options": ["Stack", "Queue", "Priority Queue", "Array"], "correct_option": 2}, {"question": "Boat covers 10 km upstream in 2h, downstream in 1h. Current speed?", "options": ["2 km/h", "2.5 km/h", "3 km/h", "3.5 km/h"], "correct_option": 1}]', TRUE),
(25, 'Detect Cycle in Undirected Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/graph-valid-tree/', 'Use Union-Find or DFS with parent tracking to detect back edges.', '[{"question": "Union-Find detects cycles in?", "options": ["O(n\u00b2)", "O(n log n)", "O(n \u03b1(n)) amortized", "O(1)"], "correct_option": 2}, {"question": "A back edge in DFS indicates?", "options": ["Tree edge", "Cycle", "Cross edge", "No cycle"], "correct_option": 1}, {"question": "If salary is 25,000 and increased by 8%, new salary?", "options": ["26,500", "27,000", "27,200", "28,000"], "correct_option": 1}]', TRUE),
(26, 'Valid Anagram', 'easy', 'Strings', 'https://leetcode.com/problems/valid-anagram/', 'Use character frequency count (array or HashMap). Compare counts.', '[{"question": "Anagram has?", "options": ["Same characters different order", "Same order", "Different characters", "Different length"], "correct_option": 0}, {"question": "Frequency count uses?", "options": ["Sorting", "HashMap/Array", "Binary search", "Stack"], "correct_option": 1}, {"question": "Average of first 5 odd numbers?", "options": ["3", "5", "7", "9"], "correct_option": 1}]', TRUE),
(27, 'Longest Substring Without Repeating Characters', 'medium', 'Strings', 'https://leetcode.com/problems/longest-substring-without-repeating-characters/', 'Sliding window with a HashSet. Shrink window from left when duplicate found.', '[{"question": "Sliding window maintains?", "options": ["A range [left, right]", "A fixed window", "Sorted order", "Reversed string"], "correct_option": 0}, {"question": "Sliding window time complexity?", "options": ["O(n\u00b2)", "O(n)", "O(n log n)", "O(1)"], "correct_option": 1}, {"question": "P and Q start a business with 3:5 ratio. Profit 8000, Q''s share?", "options": ["3000", "4000", "5000", "6000"], "correct_option": 2}]', TRUE),
(28, 'Group Anagrams', 'medium', 'Strings', 'https://leetcode.com/problems/group-anagrams/', 'Sort each word as the key. All anagrams have same sorted key. Use HashMap<String, List>.', '[{"question": "Sorting a string of length k takes?", "options": ["O(k)", "O(k log k)", "O(k\u00b2)", "O(1)"], "correct_option": 1}, {"question": "HashMap key for grouping anagrams?", "options": ["Sorted string", "First char", "Length", "Frequency"], "correct_option": 0}, {"question": "Simple interest: P=5000, R=6%, T=3 years. SI=?", "options": ["800", "900", "1000", "1100"], "correct_option": 1}]', TRUE),
(29, 'Minimum Window Substring', 'hard', 'Strings', 'https://leetcode.com/problems/minimum-window-substring/', 'Two-pointer sliding window with frequency maps. Shrink when all chars satisfied.', '[{"question": "Minimum window problem is?", "options": ["Fixed window", "Variable sliding window", "Binary search", "Two-stack"], "correct_option": 1}, {"question": "When do we shrink the window?", "options": ["When window is invalid", "When constraint satisfied", "Always", "At start only"], "correct_option": 1}, {"question": "What is 15% of 240?", "options": ["30", "34", "36", "40"], "correct_option": 2}]', TRUE),
(30, 'Palindrome Check', 'easy', 'Strings', 'https://leetcode.com/problems/valid-palindrome/', 'Two pointers from both ends, skip non-alphanumeric chars, compare char by char.', '[{"question": "Palindrome reads same?", "options": ["Forwards", "Backwards", "Both forwards and backwards", "Only lowercase"], "correct_option": 2}, {"question": "Two-pointer approach for palindrome is?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Ratio 2:3:5, total 200. Largest share?", "options": ["50", "80", "100", "120"], "correct_option": 2}]', TRUE),
(31, 'Two Sum', 'easy', 'Arrays', 'https://leetcode.com/problems/two-sum/', 'Use a hash map to store complement values as you iterate.', '[{"question": "What is the time complexity of linear search?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 2}, {"question": "Which data structure uses LIFO?", "options": ["Queue", "Stack", "Heap", "Tree"], "correct_option": 1}, {"question": "Train moves at 60 km/h for 2 hours. Distance?", "options": ["60 km", "90 km", "120 km", "180 km"], "correct_option": 2}]', TRUE),
(32, 'Best Time to Buy and Sell Stock', 'easy', 'Arrays', 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/', 'Track the minimum price seen so far and compute max profit at each step.', '[{"question": "Array index starts at?", "options": ["0", "1", "-1", "None"], "correct_option": 0}, {"question": "Which sorting is O(n log n) worst case?", "options": ["Bubble", "Selection", "Merge", "Insertion"], "correct_option": 2}, {"question": "A train travels 150 km in 3 hours. Speed?", "options": ["40 km/h", "45 km/h", "50 km/h", "55 km/h"], "correct_option": 2}]', TRUE),
(33, 'Contains Duplicate', 'easy', 'Arrays', 'https://leetcode.com/problems/contains-duplicate/', 'Use a HashSet — if element already exists, return true.', '[{"question": "HashSet uses which data structure internally?", "options": ["Array", "LinkedList", "HashMap", "Tree"], "correct_option": 2}, {"question": "Time complexity of HashSet lookup?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If 3 workers complete a job in 6 days, how many days for 2 workers?", "options": ["7", "8", "9", "10"], "correct_option": 2}]', TRUE),
(34, 'Product of Array Except Self', 'medium', 'Arrays', 'https://leetcode.com/problems/product-of-array-except-self/', 'Use prefix and suffix product arrays to avoid division.', '[{"question": "What does O(1) space mean?", "options": ["Constant space", "No space", "Linear space", "Log space"], "correct_option": 0}, {"question": "Prefix sum is useful for?", "options": ["Range queries", "Sorting", "Searching", "Hashing"], "correct_option": 0}, {"question": "A sum of first 10 natural numbers?", "options": ["45", "50", "55", "60"], "correct_option": 2}]', TRUE),
(35, 'Maximum Subarray (Kadane''s)', 'medium', 'Arrays', 'https://leetcode.com/problems/maximum-subarray/', 'Kadane''s algorithm: extend or restart subarray at each element.', '[{"question": "Kadane''s algorithm finds?", "options": ["Minimum subarray", "Maximum subarray", "Sorted subarray", "Empty subarray"], "correct_option": 1}, {"question": "Dynamic programming optimizes?", "options": ["Space", "Overlapping subproblems", "Sorting", "Recursion only"], "correct_option": 1}, {"question": "Profit if cost=200 and selling=250?", "options": ["25%", "30%", "35%", "40%"], "correct_option": 0}]', TRUE),
(36, 'Reverse Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/reverse-linked-list/', 'Use three pointers: prev, curr, next. Iterate and reverse links.', '[{"question": "Linked list node contains?", "options": ["Data only", "Data and pointer", "Pointer only", "Address only"], "correct_option": 1}, {"question": "Head of linked list points to?", "options": ["Last node", "First node", "Middle node", "Random node"], "correct_option": 1}, {"question": "LCM of 4 and 6?", "options": ["12", "18", "24", "8"], "correct_option": 0}]', TRUE),
(37, 'Merge Two Sorted Lists', 'easy', 'Linked Lists', 'https://leetcode.com/problems/merge-two-sorted-lists/', 'Use a dummy head and compare nodes from both lists iteratively.', '[{"question": "Dummy node technique helps with?", "options": ["Edge cases at head", "Tail insertion", "Middle insertion", "Sorting"], "correct_option": 0}, {"question": "Space complexity of iterative merge?", "options": ["O(1)", "O(n)", "O(log n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "Average of 10, 20, 30?", "options": ["15", "20", "25", "30"], "correct_option": 1}]', TRUE),
(38, 'Detect Cycle in Linked List', 'medium', 'Linked Lists', 'https://leetcode.com/problems/linked-list-cycle/', 'Floyd''s cycle detection: slow and fast pointers. If they meet, cycle exists.', '[{"question": "Floyd''s algorithm uses how many pointers?", "options": ["1", "2", "3", "4"], "correct_option": 1}, {"question": "Cycle detection time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "If x:y = 3:4 and x=12, y=?", "options": ["14", "16", "18", "20"], "correct_option": 1}]', TRUE),
(39, 'Find Middle of Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/middle-of-the-linked-list/', 'Use slow/fast pointer: slow moves 1 step, fast moves 2 steps.', '[{"question": "In a 5-node list, middle is at?", "options": ["Node 2", "Node 3", "Node 4", "Node 5"], "correct_option": 1}, {"question": "Two-pointer technique time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Train covers 200m in 10s. Speed in km/h?", "options": ["60", "70", "72", "80"], "correct_option": 2}]', TRUE),
(40, 'LRU Cache', 'hard', 'Linked Lists', 'https://leetcode.com/problems/lru-cache/', 'Combine HashMap and doubly linked list for O(1) get and put.', '[{"question": "LRU stands for?", "options": ["Least Recently Used", "Last Recently Updated", "Least Random Unit", "Last Reset Unit"], "correct_option": 0}, {"question": "HashMap gives O(1) for?", "options": ["Insert, Delete, Search", "Sort only", "Range queries", "Traversal"], "correct_option": 0}, {"question": "A pipe fills a tank in 4 hours, another in 6 hours. Together?", "options": ["2.4 hours", "2.6 hours", "3 hours", "5 hours"], "correct_option": 0}]', TRUE),
(41, 'Inorder Traversal of BST', 'easy', 'Trees', 'https://leetcode.com/problems/binary-tree-inorder-traversal/', 'Inorder: Left → Root → Right. Yields sorted output for BST.', '[{"question": "Inorder traversal gives BST in?", "options": ["Sorted order", "Reverse order", "Random order", "Level order"], "correct_option": 0}, {"question": "BST search time complexity?", "options": ["O(log n)", "O(n)", "O(1)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If coins doubled daily from 1, on day 10?", "options": ["512", "1024", "512", "256"], "correct_option": 0}]', TRUE),
(42, 'Maximum Depth of Binary Tree', 'easy', 'Trees', 'https://leetcode.com/problems/maximum-depth-of-binary-tree/', 'Recursively return 1 + max(left depth, right depth). Base case: null = 0.', '[{"question": "DFS uses which data structure?", "options": ["Queue", "Stack", "Array", "Heap"], "correct_option": 1}, {"question": "BFS uses which data structure?", "options": ["Stack", "Queue", "Heap", "LinkedList"], "correct_option": 1}, {"question": "35 is what percent of 700?", "options": ["3%", "4%", "5%", "6%"], "correct_option": 2}]', TRUE),
(43, 'Validate Binary Search Tree', 'medium', 'Trees', 'https://leetcode.com/problems/validate-binary-search-tree/', 'Pass min/max bounds to each node recursively. Left < node < Right.', '[{"question": "BST property: left subtree has?", "options": ["Values > root", "Values < root", "Values = root", "Random values"], "correct_option": 1}, {"question": "Which traversal checks BST validity?", "options": ["Inorder", "Preorder", "Postorder", "Level order"], "correct_option": 0}, {"question": "A man earns 15,000/month and saves 20%. Monthly savings?", "options": ["2,500", "3,000", "3,500", "4,000"], "correct_option": 1}]', TRUE),
(44, 'Level Order Traversal', 'medium', 'Trees', 'https://leetcode.com/problems/binary-tree-level-order-traversal/', 'Use a Queue. Process level by level, tracking level boundaries.', '[{"question": "BFS explores nodes?", "options": ["Depth first", "Level by level", "Randomly", "Root only"], "correct_option": 1}, {"question": "Queue is?", "options": ["LIFO", "FIFO", "LILO", "FILO"], "correct_option": 1}, {"question": "A 10% discount on 500?", "options": ["400", "450", "460", "480"], "correct_option": 1}]', TRUE),
(45, 'Lowest Common Ancestor of BST', 'medium', 'Trees', 'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/', 'If both p and q are less than root, go left. If both greater, go right. Else root is LCA.', '[{"question": "LCA of a tree means?", "options": ["Deepest common node", "Shallowest node", "Root always", "Leaf node"], "correct_option": 0}, {"question": "BST LCA time complexity?", "options": ["O(log n)", "O(n)", "O(n\u00b2)", "O(1)"], "correct_option": 0}, {"question": "Speed = Distance/Time. If d=120km, t=2h, speed?", "options": ["50 km/h", "55 km/h", "60 km/h", "65 km/h"], "correct_option": 2}]', TRUE),
(46, 'Climbing Stairs', 'easy', 'Dynamic Programming', 'https://leetcode.com/problems/climbing-stairs/', 'Fibonacci pattern: f(n) = f(n-1) + f(n-2). Use bottom-up DP.', '[{"question": "Memoization stores?", "options": ["Computed results", "Random data", "Sorted arrays", "Only inputs"], "correct_option": 0}, {"question": "Fibonacci relation is?", "options": ["f(n) = f(n-1) + f(n-2)", "f(n) = f(n-1) * 2", "f(n) = n!", "f(n) = 2^n"], "correct_option": 0}, {"question": "Pipes A and B fill tank in 3h and 6h. Together in?", "options": ["1.5h", "2h", "2.5h", "3h"], "correct_option": 1}]', TRUE),
(47, 'Coin Change', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/coin-change/', 'dp[i] = min coins to make amount i. Try each coin at each amount.', '[{"question": "Greedy always works for coin change?", "options": ["Yes", "No, only for canonical coin systems", "Yes, with sorting", "No, never"], "correct_option": 1}, {"question": "DP bottom-up vs top-down: bottom-up uses?", "options": ["Recursion", "Iteration", "Both", "Neither"], "correct_option": 1}, {"question": "HCF of 12 and 18?", "options": ["3", "6", "9", "12"], "correct_option": 1}]', TRUE),
(48, 'Longest Common Subsequence', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/longest-common-subsequence/', '2D DP: if chars match, dp[i][j] = dp[i-1][j-1] + 1, else max of top/left.', '[{"question": "LCS differs from LCS (substring) because?", "options": ["Must be contiguous", "Need not be contiguous", "Same thing", "Sorted only"], "correct_option": 1}, {"question": "LCS time complexity?", "options": ["O(n)", "O(n log n)", "O(nm)", "O(n\u00b2m)"], "correct_option": 2}, {"question": "Simple interest on 1000 at 5% for 2 years?", "options": ["50", "100", "150", "200"], "correct_option": 1}]', TRUE),
(49, '0/1 Knapsack', 'hard', 'Dynamic Programming', 'https://www.geeksforgeeks.org/0-1-knapsack-problem-dp-10/', 'For each item and capacity, choose max of (include item) or (exclude item).', '[{"question": "0/1 Knapsack: each item can be taken?", "options": ["Multiple times", "Exactly once", "Zero or many times", "Never"], "correct_option": 1}, {"question": "Knapsack time complexity?", "options": ["O(n)", "O(n*W)", "O(n\u00b2)", "O(W)"], "correct_option": 1}, {"question": "20% of 80 + 80% of 20 = ?", "options": ["16", "32", "40", "48"], "correct_option": 1}]', TRUE),
(50, 'Word Break', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/word-break/', 'dp[i] = true if s[0..i] can be segmented using wordDict. Check all prefixes.', '[{"question": "Word break is solved by?", "options": ["Greedy", "DP with boolean array", "Binary search", "Sorting"], "correct_option": 1}, {"question": "Backtracking explores?", "options": ["All possibilities", "Only optimal", "Greedy choices", "Random paths"], "correct_option": 0}, {"question": "Compound interest formula involves?", "options": ["Linear growth", "Exponential growth", "Constant growth", "Logarithmic growth"], "correct_option": 1}]', TRUE),
(51, 'Number of Islands (DFS/BFS)', 'medium', 'Graphs', 'https://leetcode.com/problems/number-of-islands/', 'DFS from each unvisited ''1'' cell, mark all connected cells as visited.', '[{"question": "DFS uses which traversal?", "options": ["Level order", "Depth first", "Breadth first", "Random"], "correct_option": 1}, {"question": "Graph edge connects?", "options": ["Two nodes", "Three nodes", "One node", "All nodes"], "correct_option": 0}, {"question": "If 5 machines make 5 items in 5 min, how many machines for 100 items in 100 min?", "options": ["5", "10", "20", "100"], "correct_option": 0}]', TRUE),
(52, 'Clone Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/clone-graph/', 'BFS/DFS with a HashMap to map original nodes to their clones.', '[{"question": "Deep copy vs shallow copy: deep copy?", "options": ["Copies references", "Copies values recursively", "Copies nothing", "Only copies root"], "correct_option": 1}, {"question": "HashMap in graph cloning ensures?", "options": ["No duplicate clones", "Sorted order", "Faster DFS", "Level order"], "correct_option": 0}, {"question": "A number increased by 20% = 120. Original?", "options": ["90", "95", "100", "110"], "correct_option": 2}]', TRUE),
(53, 'Course Schedule (Topological Sort)', 'medium', 'Graphs', 'https://leetcode.com/problems/course-schedule/', 'Build adjacency list, detect cycle using DFS with 3 states (unvisited, visiting, visited).', '[{"question": "Topological sort applies to?", "options": ["Undirected graphs", "DAGs", "Complete graphs", "Trees only"], "correct_option": 1}, {"question": "Cycle in directed graph means?", "options": ["No topological order", "Easy sorting", "DAG property", "Tree property"], "correct_option": 0}, {"question": "Work rate: A does job in 10 days, B in 15 days. Together?", "options": ["5 days", "6 days", "8 days", "9 days"], "correct_option": 1}]', TRUE),
(54, 'Dijkstra''s Shortest Path', 'hard', 'Graphs', 'https://leetcode.com/problems/network-delay-time/', 'Use min-heap priority queue. Relax edges greedily by choosing shortest known distance.', '[{"question": "Dijkstra works with?", "options": ["Negative weights", "Non-negative weights", "All graphs", "Only trees"], "correct_option": 1}, {"question": "Dijkstra uses?", "options": ["Stack", "Queue", "Priority Queue", "Array"], "correct_option": 2}, {"question": "Boat covers 10 km upstream in 2h, downstream in 1h. Current speed?", "options": ["2 km/h", "2.5 km/h", "3 km/h", "3.5 km/h"], "correct_option": 1}]', TRUE),
(55, 'Detect Cycle in Undirected Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/graph-valid-tree/', 'Use Union-Find or DFS with parent tracking to detect back edges.', '[{"question": "Union-Find detects cycles in?", "options": ["O(n\u00b2)", "O(n log n)", "O(n \u03b1(n)) amortized", "O(1)"], "correct_option": 2}, {"question": "A back edge in DFS indicates?", "options": ["Tree edge", "Cycle", "Cross edge", "No cycle"], "correct_option": 1}, {"question": "If salary is 25,000 and increased by 8%, new salary?", "options": ["26,500", "27,000", "27,200", "28,000"], "correct_option": 1}]', TRUE),
(56, 'Valid Anagram', 'easy', 'Strings', 'https://leetcode.com/problems/valid-anagram/', 'Use character frequency count (array or HashMap). Compare counts.', '[{"question": "Anagram has?", "options": ["Same characters different order", "Same order", "Different characters", "Different length"], "correct_option": 0}, {"question": "Frequency count uses?", "options": ["Sorting", "HashMap/Array", "Binary search", "Stack"], "correct_option": 1}, {"question": "Average of first 5 odd numbers?", "options": ["3", "5", "7", "9"], "correct_option": 1}]', TRUE),
(57, 'Longest Substring Without Repeating Characters', 'medium', 'Strings', 'https://leetcode.com/problems/longest-substring-without-repeating-characters/', 'Sliding window with a HashSet. Shrink window from left when duplicate found.', '[{"question": "Sliding window maintains?", "options": ["A range [left, right]", "A fixed window", "Sorted order", "Reversed string"], "correct_option": 0}, {"question": "Sliding window time complexity?", "options": ["O(n\u00b2)", "O(n)", "O(n log n)", "O(1)"], "correct_option": 1}, {"question": "P and Q start a business with 3:5 ratio. Profit 8000, Q''s share?", "options": ["3000", "4000", "5000", "6000"], "correct_option": 2}]', TRUE),
(58, 'Group Anagrams', 'medium', 'Strings', 'https://leetcode.com/problems/group-anagrams/', 'Sort each word as the key. All anagrams have same sorted key. Use HashMap<String, List>.', '[{"question": "Sorting a string of length k takes?", "options": ["O(k)", "O(k log k)", "O(k\u00b2)", "O(1)"], "correct_option": 1}, {"question": "HashMap key for grouping anagrams?", "options": ["Sorted string", "First char", "Length", "Frequency"], "correct_option": 0}, {"question": "Simple interest: P=5000, R=6%, T=3 years. SI=?", "options": ["800", "900", "1000", "1100"], "correct_option": 1}]', TRUE),
(59, 'Minimum Window Substring', 'hard', 'Strings', 'https://leetcode.com/problems/minimum-window-substring/', 'Two-pointer sliding window with frequency maps. Shrink when all chars satisfied.', '[{"question": "Minimum window problem is?", "options": ["Fixed window", "Variable sliding window", "Binary search", "Two-stack"], "correct_option": 1}, {"question": "When do we shrink the window?", "options": ["When window is invalid", "When constraint satisfied", "Always", "At start only"], "correct_option": 1}, {"question": "What is 15% of 240?", "options": ["30", "34", "36", "40"], "correct_option": 2}]', TRUE),
(60, 'Palindrome Check', 'easy', 'Strings', 'https://leetcode.com/problems/valid-palindrome/', 'Two pointers from both ends, skip non-alphanumeric chars, compare char by char.', '[{"question": "Palindrome reads same?", "options": ["Forwards", "Backwards", "Both forwards and backwards", "Only lowercase"], "correct_option": 2}, {"question": "Two-pointer approach for palindrome is?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Ratio 2:3:5, total 200. Largest share?", "options": ["50", "80", "100", "120"], "correct_option": 2}]', TRUE),
(61, 'Two Sum', 'easy', 'Arrays', 'https://leetcode.com/problems/two-sum/', 'Use a hash map to store complement values as you iterate.', '[{"question": "What is the time complexity of linear search?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 2}, {"question": "Which data structure uses LIFO?", "options": ["Queue", "Stack", "Heap", "Tree"], "correct_option": 1}, {"question": "Train moves at 60 km/h for 2 hours. Distance?", "options": ["60 km", "90 km", "120 km", "180 km"], "correct_option": 2}]', TRUE),
(62, 'Best Time to Buy and Sell Stock', 'easy', 'Arrays', 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/', 'Track the minimum price seen so far and compute max profit at each step.', '[{"question": "Array index starts at?", "options": ["0", "1", "-1", "None"], "correct_option": 0}, {"question": "Which sorting is O(n log n) worst case?", "options": ["Bubble", "Selection", "Merge", "Insertion"], "correct_option": 2}, {"question": "A train travels 150 km in 3 hours. Speed?", "options": ["40 km/h", "45 km/h", "50 km/h", "55 km/h"], "correct_option": 2}]', TRUE),
(63, 'Contains Duplicate', 'easy', 'Arrays', 'https://leetcode.com/problems/contains-duplicate/', 'Use a HashSet — if element already exists, return true.', '[{"question": "HashSet uses which data structure internally?", "options": ["Array", "LinkedList", "HashMap", "Tree"], "correct_option": 2}, {"question": "Time complexity of HashSet lookup?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If 3 workers complete a job in 6 days, how many days for 2 workers?", "options": ["7", "8", "9", "10"], "correct_option": 2}]', TRUE),
(64, 'Product of Array Except Self', 'medium', 'Arrays', 'https://leetcode.com/problems/product-of-array-except-self/', 'Use prefix and suffix product arrays to avoid division.', '[{"question": "What does O(1) space mean?", "options": ["Constant space", "No space", "Linear space", "Log space"], "correct_option": 0}, {"question": "Prefix sum is useful for?", "options": ["Range queries", "Sorting", "Searching", "Hashing"], "correct_option": 0}, {"question": "A sum of first 10 natural numbers?", "options": ["45", "50", "55", "60"], "correct_option": 2}]', TRUE),
(65, 'Maximum Subarray (Kadane''s)', 'medium', 'Arrays', 'https://leetcode.com/problems/maximum-subarray/', 'Kadane''s algorithm: extend or restart subarray at each element.', '[{"question": "Kadane''s algorithm finds?", "options": ["Minimum subarray", "Maximum subarray", "Sorted subarray", "Empty subarray"], "correct_option": 1}, {"question": "Dynamic programming optimizes?", "options": ["Space", "Overlapping subproblems", "Sorting", "Recursion only"], "correct_option": 1}, {"question": "Profit if cost=200 and selling=250?", "options": ["25%", "30%", "35%", "40%"], "correct_option": 0}]', TRUE),
(66, 'Reverse Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/reverse-linked-list/', 'Use three pointers: prev, curr, next. Iterate and reverse links.', '[{"question": "Linked list node contains?", "options": ["Data only", "Data and pointer", "Pointer only", "Address only"], "correct_option": 1}, {"question": "Head of linked list points to?", "options": ["Last node", "First node", "Middle node", "Random node"], "correct_option": 1}, {"question": "LCM of 4 and 6?", "options": ["12", "18", "24", "8"], "correct_option": 0}]', TRUE),
(67, 'Merge Two Sorted Lists', 'easy', 'Linked Lists', 'https://leetcode.com/problems/merge-two-sorted-lists/', 'Use a dummy head and compare nodes from both lists iteratively.', '[{"question": "Dummy node technique helps with?", "options": ["Edge cases at head", "Tail insertion", "Middle insertion", "Sorting"], "correct_option": 0}, {"question": "Space complexity of iterative merge?", "options": ["O(1)", "O(n)", "O(log n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "Average of 10, 20, 30?", "options": ["15", "20", "25", "30"], "correct_option": 1}]', TRUE),
(68, 'Detect Cycle in Linked List', 'medium', 'Linked Lists', 'https://leetcode.com/problems/linked-list-cycle/', 'Floyd''s cycle detection: slow and fast pointers. If they meet, cycle exists.', '[{"question": "Floyd''s algorithm uses how many pointers?", "options": ["1", "2", "3", "4"], "correct_option": 1}, {"question": "Cycle detection time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "If x:y = 3:4 and x=12, y=?", "options": ["14", "16", "18", "20"], "correct_option": 1}]', TRUE),
(69, 'Find Middle of Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/middle-of-the-linked-list/', 'Use slow/fast pointer: slow moves 1 step, fast moves 2 steps.', '[{"question": "In a 5-node list, middle is at?", "options": ["Node 2", "Node 3", "Node 4", "Node 5"], "correct_option": 1}, {"question": "Two-pointer technique time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Train covers 200m in 10s. Speed in km/h?", "options": ["60", "70", "72", "80"], "correct_option": 2}]', TRUE),
(70, 'LRU Cache', 'hard', 'Linked Lists', 'https://leetcode.com/problems/lru-cache/', 'Combine HashMap and doubly linked list for O(1) get and put.', '[{"question": "LRU stands for?", "options": ["Least Recently Used", "Last Recently Updated", "Least Random Unit", "Last Reset Unit"], "correct_option": 0}, {"question": "HashMap gives O(1) for?", "options": ["Insert, Delete, Search", "Sort only", "Range queries", "Traversal"], "correct_option": 0}, {"question": "A pipe fills a tank in 4 hours, another in 6 hours. Together?", "options": ["2.4 hours", "2.6 hours", "3 hours", "5 hours"], "correct_option": 0}]', TRUE),
(71, 'Inorder Traversal of BST', 'easy', 'Trees', 'https://leetcode.com/problems/binary-tree-inorder-traversal/', 'Inorder: Left → Root → Right. Yields sorted output for BST.', '[{"question": "Inorder traversal gives BST in?", "options": ["Sorted order", "Reverse order", "Random order", "Level order"], "correct_option": 0}, {"question": "BST search time complexity?", "options": ["O(log n)", "O(n)", "O(1)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If coins doubled daily from 1, on day 10?", "options": ["512", "1024", "512", "256"], "correct_option": 0}]', TRUE),
(72, 'Maximum Depth of Binary Tree', 'easy', 'Trees', 'https://leetcode.com/problems/maximum-depth-of-binary-tree/', 'Recursively return 1 + max(left depth, right depth). Base case: null = 0.', '[{"question": "DFS uses which data structure?", "options": ["Queue", "Stack", "Array", "Heap"], "correct_option": 1}, {"question": "BFS uses which data structure?", "options": ["Stack", "Queue", "Heap", "LinkedList"], "correct_option": 1}, {"question": "35 is what percent of 700?", "options": ["3%", "4%", "5%", "6%"], "correct_option": 2}]', TRUE),
(73, 'Validate Binary Search Tree', 'medium', 'Trees', 'https://leetcode.com/problems/validate-binary-search-tree/', 'Pass min/max bounds to each node recursively. Left < node < Right.', '[{"question": "BST property: left subtree has?", "options": ["Values > root", "Values < root", "Values = root", "Random values"], "correct_option": 1}, {"question": "Which traversal checks BST validity?", "options": ["Inorder", "Preorder", "Postorder", "Level order"], "correct_option": 0}, {"question": "A man earns 15,000/month and saves 20%. Monthly savings?", "options": ["2,500", "3,000", "3,500", "4,000"], "correct_option": 1}]', TRUE),
(74, 'Level Order Traversal', 'medium', 'Trees', 'https://leetcode.com/problems/binary-tree-level-order-traversal/', 'Use a Queue. Process level by level, tracking level boundaries.', '[{"question": "BFS explores nodes?", "options": ["Depth first", "Level by level", "Randomly", "Root only"], "correct_option": 1}, {"question": "Queue is?", "options": ["LIFO", "FIFO", "LILO", "FILO"], "correct_option": 1}, {"question": "A 10% discount on 500?", "options": ["400", "450", "460", "480"], "correct_option": 1}]', TRUE),
(75, 'Lowest Common Ancestor of BST', 'medium', 'Trees', 'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/', 'If both p and q are less than root, go left. If both greater, go right. Else root is LCA.', '[{"question": "LCA of a tree means?", "options": ["Deepest common node", "Shallowest node", "Root always", "Leaf node"], "correct_option": 0}, {"question": "BST LCA time complexity?", "options": ["O(log n)", "O(n)", "O(n\u00b2)", "O(1)"], "correct_option": 0}, {"question": "Speed = Distance/Time. If d=120km, t=2h, speed?", "options": ["50 km/h", "55 km/h", "60 km/h", "65 km/h"], "correct_option": 2}]', TRUE),
(76, 'Climbing Stairs', 'easy', 'Dynamic Programming', 'https://leetcode.com/problems/climbing-stairs/', 'Fibonacci pattern: f(n) = f(n-1) + f(n-2). Use bottom-up DP.', '[{"question": "Memoization stores?", "options": ["Computed results", "Random data", "Sorted arrays", "Only inputs"], "correct_option": 0}, {"question": "Fibonacci relation is?", "options": ["f(n) = f(n-1) + f(n-2)", "f(n) = f(n-1) * 2", "f(n) = n!", "f(n) = 2^n"], "correct_option": 0}, {"question": "Pipes A and B fill tank in 3h and 6h. Together in?", "options": ["1.5h", "2h", "2.5h", "3h"], "correct_option": 1}]', TRUE),
(77, 'Coin Change', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/coin-change/', 'dp[i] = min coins to make amount i. Try each coin at each amount.', '[{"question": "Greedy always works for coin change?", "options": ["Yes", "No, only for canonical coin systems", "Yes, with sorting", "No, never"], "correct_option": 1}, {"question": "DP bottom-up vs top-down: bottom-up uses?", "options": ["Recursion", "Iteration", "Both", "Neither"], "correct_option": 1}, {"question": "HCF of 12 and 18?", "options": ["3", "6", "9", "12"], "correct_option": 1}]', TRUE),
(78, 'Longest Common Subsequence', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/longest-common-subsequence/', '2D DP: if chars match, dp[i][j] = dp[i-1][j-1] + 1, else max of top/left.', '[{"question": "LCS differs from LCS (substring) because?", "options": ["Must be contiguous", "Need not be contiguous", "Same thing", "Sorted only"], "correct_option": 1}, {"question": "LCS time complexity?", "options": ["O(n)", "O(n log n)", "O(nm)", "O(n\u00b2m)"], "correct_option": 2}, {"question": "Simple interest on 1000 at 5% for 2 years?", "options": ["50", "100", "150", "200"], "correct_option": 1}]', TRUE),
(79, '0/1 Knapsack', 'hard', 'Dynamic Programming', 'https://www.geeksforgeeks.org/0-1-knapsack-problem-dp-10/', 'For each item and capacity, choose max of (include item) or (exclude item).', '[{"question": "0/1 Knapsack: each item can be taken?", "options": ["Multiple times", "Exactly once", "Zero or many times", "Never"], "correct_option": 1}, {"question": "Knapsack time complexity?", "options": ["O(n)", "O(n*W)", "O(n\u00b2)", "O(W)"], "correct_option": 1}, {"question": "20% of 80 + 80% of 20 = ?", "options": ["16", "32", "40", "48"], "correct_option": 1}]', TRUE),
(80, 'Word Break', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/word-break/', 'dp[i] = true if s[0..i] can be segmented using wordDict. Check all prefixes.', '[{"question": "Word break is solved by?", "options": ["Greedy", "DP with boolean array", "Binary search", "Sorting"], "correct_option": 1}, {"question": "Backtracking explores?", "options": ["All possibilities", "Only optimal", "Greedy choices", "Random paths"], "correct_option": 0}, {"question": "Compound interest formula involves?", "options": ["Linear growth", "Exponential growth", "Constant growth", "Logarithmic growth"], "correct_option": 1}]', TRUE),
(81, 'Number of Islands (DFS/BFS)', 'medium', 'Graphs', 'https://leetcode.com/problems/number-of-islands/', 'DFS from each unvisited ''1'' cell, mark all connected cells as visited.', '[{"question": "DFS uses which traversal?", "options": ["Level order", "Depth first", "Breadth first", "Random"], "correct_option": 1}, {"question": "Graph edge connects?", "options": ["Two nodes", "Three nodes", "One node", "All nodes"], "correct_option": 0}, {"question": "If 5 machines make 5 items in 5 min, how many machines for 100 items in 100 min?", "options": ["5", "10", "20", "100"], "correct_option": 0}]', TRUE),
(82, 'Clone Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/clone-graph/', 'BFS/DFS with a HashMap to map original nodes to their clones.', '[{"question": "Deep copy vs shallow copy: deep copy?", "options": ["Copies references", "Copies values recursively", "Copies nothing", "Only copies root"], "correct_option": 1}, {"question": "HashMap in graph cloning ensures?", "options": ["No duplicate clones", "Sorted order", "Faster DFS", "Level order"], "correct_option": 0}, {"question": "A number increased by 20% = 120. Original?", "options": ["90", "95", "100", "110"], "correct_option": 2}]', TRUE),
(83, 'Course Schedule (Topological Sort)', 'medium', 'Graphs', 'https://leetcode.com/problems/course-schedule/', 'Build adjacency list, detect cycle using DFS with 3 states (unvisited, visiting, visited).', '[{"question": "Topological sort applies to?", "options": ["Undirected graphs", "DAGs", "Complete graphs", "Trees only"], "correct_option": 1}, {"question": "Cycle in directed graph means?", "options": ["No topological order", "Easy sorting", "DAG property", "Tree property"], "correct_option": 0}, {"question": "Work rate: A does job in 10 days, B in 15 days. Together?", "options": ["5 days", "6 days", "8 days", "9 days"], "correct_option": 1}]', TRUE),
(84, 'Dijkstra''s Shortest Path', 'hard', 'Graphs', 'https://leetcode.com/problems/network-delay-time/', 'Use min-heap priority queue. Relax edges greedily by choosing shortest known distance.', '[{"question": "Dijkstra works with?", "options": ["Negative weights", "Non-negative weights", "All graphs", "Only trees"], "correct_option": 1}, {"question": "Dijkstra uses?", "options": ["Stack", "Queue", "Priority Queue", "Array"], "correct_option": 2}, {"question": "Boat covers 10 km upstream in 2h, downstream in 1h. Current speed?", "options": ["2 km/h", "2.5 km/h", "3 km/h", "3.5 km/h"], "correct_option": 1}]', TRUE),
(85, 'Detect Cycle in Undirected Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/graph-valid-tree/', 'Use Union-Find or DFS with parent tracking to detect back edges.', '[{"question": "Union-Find detects cycles in?", "options": ["O(n\u00b2)", "O(n log n)", "O(n \u03b1(n)) amortized", "O(1)"], "correct_option": 2}, {"question": "A back edge in DFS indicates?", "options": ["Tree edge", "Cycle", "Cross edge", "No cycle"], "correct_option": 1}, {"question": "If salary is 25,000 and increased by 8%, new salary?", "options": ["26,500", "27,000", "27,200", "28,000"], "correct_option": 1}]', TRUE),
(86, 'Valid Anagram', 'easy', 'Strings', 'https://leetcode.com/problems/valid-anagram/', 'Use character frequency count (array or HashMap). Compare counts.', '[{"question": "Anagram has?", "options": ["Same characters different order", "Same order", "Different characters", "Different length"], "correct_option": 0}, {"question": "Frequency count uses?", "options": ["Sorting", "HashMap/Array", "Binary search", "Stack"], "correct_option": 1}, {"question": "Average of first 5 odd numbers?", "options": ["3", "5", "7", "9"], "correct_option": 1}]', TRUE),
(87, 'Longest Substring Without Repeating Characters', 'medium', 'Strings', 'https://leetcode.com/problems/longest-substring-without-repeating-characters/', 'Sliding window with a HashSet. Shrink window from left when duplicate found.', '[{"question": "Sliding window maintains?", "options": ["A range [left, right]", "A fixed window", "Sorted order", "Reversed string"], "correct_option": 0}, {"question": "Sliding window time complexity?", "options": ["O(n\u00b2)", "O(n)", "O(n log n)", "O(1)"], "correct_option": 1}, {"question": "P and Q start a business with 3:5 ratio. Profit 8000, Q''s share?", "options": ["3000", "4000", "5000", "6000"], "correct_option": 2}]', TRUE),
(88, 'Group Anagrams', 'medium', 'Strings', 'https://leetcode.com/problems/group-anagrams/', 'Sort each word as the key. All anagrams have same sorted key. Use HashMap<String, List>.', '[{"question": "Sorting a string of length k takes?", "options": ["O(k)", "O(k log k)", "O(k\u00b2)", "O(1)"], "correct_option": 1}, {"question": "HashMap key for grouping anagrams?", "options": ["Sorted string", "First char", "Length", "Frequency"], "correct_option": 0}, {"question": "Simple interest: P=5000, R=6%, T=3 years. SI=?", "options": ["800", "900", "1000", "1100"], "correct_option": 1}]', TRUE),
(89, 'Minimum Window Substring', 'hard', 'Strings', 'https://leetcode.com/problems/minimum-window-substring/', 'Two-pointer sliding window with frequency maps. Shrink when all chars satisfied.', '[{"question": "Minimum window problem is?", "options": ["Fixed window", "Variable sliding window", "Binary search", "Two-stack"], "correct_option": 1}, {"question": "When do we shrink the window?", "options": ["When window is invalid", "When constraint satisfied", "Always", "At start only"], "correct_option": 1}, {"question": "What is 15% of 240?", "options": ["30", "34", "36", "40"], "correct_option": 2}]', TRUE),
(90, 'Palindrome Check', 'easy', 'Strings', 'https://leetcode.com/problems/valid-palindrome/', 'Two pointers from both ends, skip non-alphanumeric chars, compare char by char.', '[{"question": "Palindrome reads same?", "options": ["Forwards", "Backwards", "Both forwards and backwards", "Only lowercase"], "correct_option": 2}, {"question": "Two-pointer approach for palindrome is?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Ratio 2:3:5, total 200. Largest share?", "options": ["50", "80", "100", "120"], "correct_option": 2}]', TRUE),
(91, 'Two Sum', 'easy', 'Arrays', 'https://leetcode.com/problems/two-sum/', 'Use a hash map to store complement values as you iterate.', '[{"question": "What is the time complexity of linear search?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 2}, {"question": "Which data structure uses LIFO?", "options": ["Queue", "Stack", "Heap", "Tree"], "correct_option": 1}, {"question": "Train moves at 60 km/h for 2 hours. Distance?", "options": ["60 km", "90 km", "120 km", "180 km"], "correct_option": 2}]', TRUE),
(92, 'Best Time to Buy and Sell Stock', 'easy', 'Arrays', 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/', 'Track the minimum price seen so far and compute max profit at each step.', '[{"question": "Array index starts at?", "options": ["0", "1", "-1", "None"], "correct_option": 0}, {"question": "Which sorting is O(n log n) worst case?", "options": ["Bubble", "Selection", "Merge", "Insertion"], "correct_option": 2}, {"question": "A train travels 150 km in 3 hours. Speed?", "options": ["40 km/h", "45 km/h", "50 km/h", "55 km/h"], "correct_option": 2}]', TRUE),
(93, 'Contains Duplicate', 'easy', 'Arrays', 'https://leetcode.com/problems/contains-duplicate/', 'Use a HashSet — if element already exists, return true.', '[{"question": "HashSet uses which data structure internally?", "options": ["Array", "LinkedList", "HashMap", "Tree"], "correct_option": 2}, {"question": "Time complexity of HashSet lookup?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If 3 workers complete a job in 6 days, how many days for 2 workers?", "options": ["7", "8", "9", "10"], "correct_option": 2}]', TRUE),
(94, 'Product of Array Except Self', 'medium', 'Arrays', 'https://leetcode.com/problems/product-of-array-except-self/', 'Use prefix and suffix product arrays to avoid division.', '[{"question": "What does O(1) space mean?", "options": ["Constant space", "No space", "Linear space", "Log space"], "correct_option": 0}, {"question": "Prefix sum is useful for?", "options": ["Range queries", "Sorting", "Searching", "Hashing"], "correct_option": 0}, {"question": "A sum of first 10 natural numbers?", "options": ["45", "50", "55", "60"], "correct_option": 2}]', TRUE),
(95, 'Maximum Subarray (Kadane''s)', 'medium', 'Arrays', 'https://leetcode.com/problems/maximum-subarray/', 'Kadane''s algorithm: extend or restart subarray at each element.', '[{"question": "Kadane''s algorithm finds?", "options": ["Minimum subarray", "Maximum subarray", "Sorted subarray", "Empty subarray"], "correct_option": 1}, {"question": "Dynamic programming optimizes?", "options": ["Space", "Overlapping subproblems", "Sorting", "Recursion only"], "correct_option": 1}, {"question": "Profit if cost=200 and selling=250?", "options": ["25%", "30%", "35%", "40%"], "correct_option": 0}]', TRUE),
(96, 'Reverse Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/reverse-linked-list/', 'Use three pointers: prev, curr, next. Iterate and reverse links.', '[{"question": "Linked list node contains?", "options": ["Data only", "Data and pointer", "Pointer only", "Address only"], "correct_option": 1}, {"question": "Head of linked list points to?", "options": ["Last node", "First node", "Middle node", "Random node"], "correct_option": 1}, {"question": "LCM of 4 and 6?", "options": ["12", "18", "24", "8"], "correct_option": 0}]', TRUE),
(97, 'Merge Two Sorted Lists', 'easy', 'Linked Lists', 'https://leetcode.com/problems/merge-two-sorted-lists/', 'Use a dummy head and compare nodes from both lists iteratively.', '[{"question": "Dummy node technique helps with?", "options": ["Edge cases at head", "Tail insertion", "Middle insertion", "Sorting"], "correct_option": 0}, {"question": "Space complexity of iterative merge?", "options": ["O(1)", "O(n)", "O(log n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "Average of 10, 20, 30?", "options": ["15", "20", "25", "30"], "correct_option": 1}]', TRUE),
(98, 'Detect Cycle in Linked List', 'medium', 'Linked Lists', 'https://leetcode.com/problems/linked-list-cycle/', 'Floyd''s cycle detection: slow and fast pointers. If they meet, cycle exists.', '[{"question": "Floyd''s algorithm uses how many pointers?", "options": ["1", "2", "3", "4"], "correct_option": 1}, {"question": "Cycle detection time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "If x:y = 3:4 and x=12, y=?", "options": ["14", "16", "18", "20"], "correct_option": 1}]', TRUE),
(99, 'Find Middle of Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/middle-of-the-linked-list/', 'Use slow/fast pointer: slow moves 1 step, fast moves 2 steps.', '[{"question": "In a 5-node list, middle is at?", "options": ["Node 2", "Node 3", "Node 4", "Node 5"], "correct_option": 1}, {"question": "Two-pointer technique time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Train covers 200m in 10s. Speed in km/h?", "options": ["60", "70", "72", "80"], "correct_option": 2}]', TRUE),
(100, 'LRU Cache', 'hard', 'Linked Lists', 'https://leetcode.com/problems/lru-cache/', 'Combine HashMap and doubly linked list for O(1) get and put.', '[{"question": "LRU stands for?", "options": ["Least Recently Used", "Last Recently Updated", "Least Random Unit", "Last Reset Unit"], "correct_option": 0}, {"question": "HashMap gives O(1) for?", "options": ["Insert, Delete, Search", "Sort only", "Range queries", "Traversal"], "correct_option": 0}, {"question": "A pipe fills a tank in 4 hours, another in 6 hours. Together?", "options": ["2.4 hours", "2.6 hours", "3 hours", "5 hours"], "correct_option": 0}]', TRUE),
(101, 'Inorder Traversal of BST', 'easy', 'Trees', 'https://leetcode.com/problems/binary-tree-inorder-traversal/', 'Inorder: Left → Root → Right. Yields sorted output for BST.', '[{"question": "Inorder traversal gives BST in?", "options": ["Sorted order", "Reverse order", "Random order", "Level order"], "correct_option": 0}, {"question": "BST search time complexity?", "options": ["O(log n)", "O(n)", "O(1)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If coins doubled daily from 1, on day 10?", "options": ["512", "1024", "512", "256"], "correct_option": 0}]', TRUE),
(102, 'Maximum Depth of Binary Tree', 'easy', 'Trees', 'https://leetcode.com/problems/maximum-depth-of-binary-tree/', 'Recursively return 1 + max(left depth, right depth). Base case: null = 0.', '[{"question": "DFS uses which data structure?", "options": ["Queue", "Stack", "Array", "Heap"], "correct_option": 1}, {"question": "BFS uses which data structure?", "options": ["Stack", "Queue", "Heap", "LinkedList"], "correct_option": 1}, {"question": "35 is what percent of 700?", "options": ["3%", "4%", "5%", "6%"], "correct_option": 2}]', TRUE),
(103, 'Validate Binary Search Tree', 'medium', 'Trees', 'https://leetcode.com/problems/validate-binary-search-tree/', 'Pass min/max bounds to each node recursively. Left < node < Right.', '[{"question": "BST property: left subtree has?", "options": ["Values > root", "Values < root", "Values = root", "Random values"], "correct_option": 1}, {"question": "Which traversal checks BST validity?", "options": ["Inorder", "Preorder", "Postorder", "Level order"], "correct_option": 0}, {"question": "A man earns 15,000/month and saves 20%. Monthly savings?", "options": ["2,500", "3,000", "3,500", "4,000"], "correct_option": 1}]', TRUE),
(104, 'Level Order Traversal', 'medium', 'Trees', 'https://leetcode.com/problems/binary-tree-level-order-traversal/', 'Use a Queue. Process level by level, tracking level boundaries.', '[{"question": "BFS explores nodes?", "options": ["Depth first", "Level by level", "Randomly", "Root only"], "correct_option": 1}, {"question": "Queue is?", "options": ["LIFO", "FIFO", "LILO", "FILO"], "correct_option": 1}, {"question": "A 10% discount on 500?", "options": ["400", "450", "460", "480"], "correct_option": 1}]', TRUE),
(105, 'Lowest Common Ancestor of BST', 'medium', 'Trees', 'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/', 'If both p and q are less than root, go left. If both greater, go right. Else root is LCA.', '[{"question": "LCA of a tree means?", "options": ["Deepest common node", "Shallowest node", "Root always", "Leaf node"], "correct_option": 0}, {"question": "BST LCA time complexity?", "options": ["O(log n)", "O(n)", "O(n\u00b2)", "O(1)"], "correct_option": 0}, {"question": "Speed = Distance/Time. If d=120km, t=2h, speed?", "options": ["50 km/h", "55 km/h", "60 km/h", "65 km/h"], "correct_option": 2}]', TRUE),
(106, 'Climbing Stairs', 'easy', 'Dynamic Programming', 'https://leetcode.com/problems/climbing-stairs/', 'Fibonacci pattern: f(n) = f(n-1) + f(n-2). Use bottom-up DP.', '[{"question": "Memoization stores?", "options": ["Computed results", "Random data", "Sorted arrays", "Only inputs"], "correct_option": 0}, {"question": "Fibonacci relation is?", "options": ["f(n) = f(n-1) + f(n-2)", "f(n) = f(n-1) * 2", "f(n) = n!", "f(n) = 2^n"], "correct_option": 0}, {"question": "Pipes A and B fill tank in 3h and 6h. Together in?", "options": ["1.5h", "2h", "2.5h", "3h"], "correct_option": 1}]', TRUE),
(107, 'Coin Change', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/coin-change/', 'dp[i] = min coins to make amount i. Try each coin at each amount.', '[{"question": "Greedy always works for coin change?", "options": ["Yes", "No, only for canonical coin systems", "Yes, with sorting", "No, never"], "correct_option": 1}, {"question": "DP bottom-up vs top-down: bottom-up uses?", "options": ["Recursion", "Iteration", "Both", "Neither"], "correct_option": 1}, {"question": "HCF of 12 and 18?", "options": ["3", "6", "9", "12"], "correct_option": 1}]', TRUE),
(108, 'Longest Common Subsequence', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/longest-common-subsequence/', '2D DP: if chars match, dp[i][j] = dp[i-1][j-1] + 1, else max of top/left.', '[{"question": "LCS differs from LCS (substring) because?", "options": ["Must be contiguous", "Need not be contiguous", "Same thing", "Sorted only"], "correct_option": 1}, {"question": "LCS time complexity?", "options": ["O(n)", "O(n log n)", "O(nm)", "O(n\u00b2m)"], "correct_option": 2}, {"question": "Simple interest on 1000 at 5% for 2 years?", "options": ["50", "100", "150", "200"], "correct_option": 1}]', TRUE),
(109, '0/1 Knapsack', 'hard', 'Dynamic Programming', 'https://www.geeksforgeeks.org/0-1-knapsack-problem-dp-10/', 'For each item and capacity, choose max of (include item) or (exclude item).', '[{"question": "0/1 Knapsack: each item can be taken?", "options": ["Multiple times", "Exactly once", "Zero or many times", "Never"], "correct_option": 1}, {"question": "Knapsack time complexity?", "options": ["O(n)", "O(n*W)", "O(n\u00b2)", "O(W)"], "correct_option": 1}, {"question": "20% of 80 + 80% of 20 = ?", "options": ["16", "32", "40", "48"], "correct_option": 1}]', TRUE),
(110, 'Word Break', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/word-break/', 'dp[i] = true if s[0..i] can be segmented using wordDict. Check all prefixes.', '[{"question": "Word break is solved by?", "options": ["Greedy", "DP with boolean array", "Binary search", "Sorting"], "correct_option": 1}, {"question": "Backtracking explores?", "options": ["All possibilities", "Only optimal", "Greedy choices", "Random paths"], "correct_option": 0}, {"question": "Compound interest formula involves?", "options": ["Linear growth", "Exponential growth", "Constant growth", "Logarithmic growth"], "correct_option": 1}]', TRUE),
(111, 'Number of Islands (DFS/BFS)', 'medium', 'Graphs', 'https://leetcode.com/problems/number-of-islands/', 'DFS from each unvisited ''1'' cell, mark all connected cells as visited.', '[{"question": "DFS uses which traversal?", "options": ["Level order", "Depth first", "Breadth first", "Random"], "correct_option": 1}, {"question": "Graph edge connects?", "options": ["Two nodes", "Three nodes", "One node", "All nodes"], "correct_option": 0}, {"question": "If 5 machines make 5 items in 5 min, how many machines for 100 items in 100 min?", "options": ["5", "10", "20", "100"], "correct_option": 0}]', TRUE),
(112, 'Clone Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/clone-graph/', 'BFS/DFS with a HashMap to map original nodes to their clones.', '[{"question": "Deep copy vs shallow copy: deep copy?", "options": ["Copies references", "Copies values recursively", "Copies nothing", "Only copies root"], "correct_option": 1}, {"question": "HashMap in graph cloning ensures?", "options": ["No duplicate clones", "Sorted order", "Faster DFS", "Level order"], "correct_option": 0}, {"question": "A number increased by 20% = 120. Original?", "options": ["90", "95", "100", "110"], "correct_option": 2}]', TRUE),
(113, 'Course Schedule (Topological Sort)', 'medium', 'Graphs', 'https://leetcode.com/problems/course-schedule/', 'Build adjacency list, detect cycle using DFS with 3 states (unvisited, visiting, visited).', '[{"question": "Topological sort applies to?", "options": ["Undirected graphs", "DAGs", "Complete graphs", "Trees only"], "correct_option": 1}, {"question": "Cycle in directed graph means?", "options": ["No topological order", "Easy sorting", "DAG property", "Tree property"], "correct_option": 0}, {"question": "Work rate: A does job in 10 days, B in 15 days. Together?", "options": ["5 days", "6 days", "8 days", "9 days"], "correct_option": 1}]', TRUE),
(114, 'Dijkstra''s Shortest Path', 'hard', 'Graphs', 'https://leetcode.com/problems/network-delay-time/', 'Use min-heap priority queue. Relax edges greedily by choosing shortest known distance.', '[{"question": "Dijkstra works with?", "options": ["Negative weights", "Non-negative weights", "All graphs", "Only trees"], "correct_option": 1}, {"question": "Dijkstra uses?", "options": ["Stack", "Queue", "Priority Queue", "Array"], "correct_option": 2}, {"question": "Boat covers 10 km upstream in 2h, downstream in 1h. Current speed?", "options": ["2 km/h", "2.5 km/h", "3 km/h", "3.5 km/h"], "correct_option": 1}]', TRUE),
(115, 'Detect Cycle in Undirected Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/graph-valid-tree/', 'Use Union-Find or DFS with parent tracking to detect back edges.', '[{"question": "Union-Find detects cycles in?", "options": ["O(n\u00b2)", "O(n log n)", "O(n \u03b1(n)) amortized", "O(1)"], "correct_option": 2}, {"question": "A back edge in DFS indicates?", "options": ["Tree edge", "Cycle", "Cross edge", "No cycle"], "correct_option": 1}, {"question": "If salary is 25,000 and increased by 8%, new salary?", "options": ["26,500", "27,000", "27,200", "28,000"], "correct_option": 1}]', TRUE),
(116, 'Valid Anagram', 'easy', 'Strings', 'https://leetcode.com/problems/valid-anagram/', 'Use character frequency count (array or HashMap). Compare counts.', '[{"question": "Anagram has?", "options": ["Same characters different order", "Same order", "Different characters", "Different length"], "correct_option": 0}, {"question": "Frequency count uses?", "options": ["Sorting", "HashMap/Array", "Binary search", "Stack"], "correct_option": 1}, {"question": "Average of first 5 odd numbers?", "options": ["3", "5", "7", "9"], "correct_option": 1}]', TRUE),
(117, 'Longest Substring Without Repeating Characters', 'medium', 'Strings', 'https://leetcode.com/problems/longest-substring-without-repeating-characters/', 'Sliding window with a HashSet. Shrink window from left when duplicate found.', '[{"question": "Sliding window maintains?", "options": ["A range [left, right]", "A fixed window", "Sorted order", "Reversed string"], "correct_option": 0}, {"question": "Sliding window time complexity?", "options": ["O(n\u00b2)", "O(n)", "O(n log n)", "O(1)"], "correct_option": 1}, {"question": "P and Q start a business with 3:5 ratio. Profit 8000, Q''s share?", "options": ["3000", "4000", "5000", "6000"], "correct_option": 2}]', TRUE),
(118, 'Group Anagrams', 'medium', 'Strings', 'https://leetcode.com/problems/group-anagrams/', 'Sort each word as the key. All anagrams have same sorted key. Use HashMap<String, List>.', '[{"question": "Sorting a string of length k takes?", "options": ["O(k)", "O(k log k)", "O(k\u00b2)", "O(1)"], "correct_option": 1}, {"question": "HashMap key for grouping anagrams?", "options": ["Sorted string", "First char", "Length", "Frequency"], "correct_option": 0}, {"question": "Simple interest: P=5000, R=6%, T=3 years. SI=?", "options": ["800", "900", "1000", "1100"], "correct_option": 1}]', TRUE),
(119, 'Minimum Window Substring', 'hard', 'Strings', 'https://leetcode.com/problems/minimum-window-substring/', 'Two-pointer sliding window with frequency maps. Shrink when all chars satisfied.', '[{"question": "Minimum window problem is?", "options": ["Fixed window", "Variable sliding window", "Binary search", "Two-stack"], "correct_option": 1}, {"question": "When do we shrink the window?", "options": ["When window is invalid", "When constraint satisfied", "Always", "At start only"], "correct_option": 1}, {"question": "What is 15% of 240?", "options": ["30", "34", "36", "40"], "correct_option": 2}]', TRUE),
(120, 'Palindrome Check', 'easy', 'Strings', 'https://leetcode.com/problems/valid-palindrome/', 'Two pointers from both ends, skip non-alphanumeric chars, compare char by char.', '[{"question": "Palindrome reads same?", "options": ["Forwards", "Backwards", "Both forwards and backwards", "Only lowercase"], "correct_option": 2}, {"question": "Two-pointer approach for palindrome is?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Ratio 2:3:5, total 200. Largest share?", "options": ["50", "80", "100", "120"], "correct_option": 2}]', TRUE),
(121, 'Two Sum', 'easy', 'Arrays', 'https://leetcode.com/problems/two-sum/', 'Use a hash map to store complement values as you iterate.', '[{"question": "What is the time complexity of linear search?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 2}, {"question": "Which data structure uses LIFO?", "options": ["Queue", "Stack", "Heap", "Tree"], "correct_option": 1}, {"question": "Train moves at 60 km/h for 2 hours. Distance?", "options": ["60 km", "90 km", "120 km", "180 km"], "correct_option": 2}]', TRUE),
(122, 'Best Time to Buy and Sell Stock', 'easy', 'Arrays', 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/', 'Track the minimum price seen so far and compute max profit at each step.', '[{"question": "Array index starts at?", "options": ["0", "1", "-1", "None"], "correct_option": 0}, {"question": "Which sorting is O(n log n) worst case?", "options": ["Bubble", "Selection", "Merge", "Insertion"], "correct_option": 2}, {"question": "A train travels 150 km in 3 hours. Speed?", "options": ["40 km/h", "45 km/h", "50 km/h", "55 km/h"], "correct_option": 2}]', TRUE),
(123, 'Contains Duplicate', 'easy', 'Arrays', 'https://leetcode.com/problems/contains-duplicate/', 'Use a HashSet — if element already exists, return true.', '[{"question": "HashSet uses which data structure internally?", "options": ["Array", "LinkedList", "HashMap", "Tree"], "correct_option": 2}, {"question": "Time complexity of HashSet lookup?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If 3 workers complete a job in 6 days, how many days for 2 workers?", "options": ["7", "8", "9", "10"], "correct_option": 2}]', TRUE),
(124, 'Product of Array Except Self', 'medium', 'Arrays', 'https://leetcode.com/problems/product-of-array-except-self/', 'Use prefix and suffix product arrays to avoid division.', '[{"question": "What does O(1) space mean?", "options": ["Constant space", "No space", "Linear space", "Log space"], "correct_option": 0}, {"question": "Prefix sum is useful for?", "options": ["Range queries", "Sorting", "Searching", "Hashing"], "correct_option": 0}, {"question": "A sum of first 10 natural numbers?", "options": ["45", "50", "55", "60"], "correct_option": 2}]', TRUE),
(125, 'Maximum Subarray (Kadane''s)', 'medium', 'Arrays', 'https://leetcode.com/problems/maximum-subarray/', 'Kadane''s algorithm: extend or restart subarray at each element.', '[{"question": "Kadane''s algorithm finds?", "options": ["Minimum subarray", "Maximum subarray", "Sorted subarray", "Empty subarray"], "correct_option": 1}, {"question": "Dynamic programming optimizes?", "options": ["Space", "Overlapping subproblems", "Sorting", "Recursion only"], "correct_option": 1}, {"question": "Profit if cost=200 and selling=250?", "options": ["25%", "30%", "35%", "40%"], "correct_option": 0}]', TRUE),
(126, 'Reverse Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/reverse-linked-list/', 'Use three pointers: prev, curr, next. Iterate and reverse links.', '[{"question": "Linked list node contains?", "options": ["Data only", "Data and pointer", "Pointer only", "Address only"], "correct_option": 1}, {"question": "Head of linked list points to?", "options": ["Last node", "First node", "Middle node", "Random node"], "correct_option": 1}, {"question": "LCM of 4 and 6?", "options": ["12", "18", "24", "8"], "correct_option": 0}]', TRUE),
(127, 'Merge Two Sorted Lists', 'easy', 'Linked Lists', 'https://leetcode.com/problems/merge-two-sorted-lists/', 'Use a dummy head and compare nodes from both lists iteratively.', '[{"question": "Dummy node technique helps with?", "options": ["Edge cases at head", "Tail insertion", "Middle insertion", "Sorting"], "correct_option": 0}, {"question": "Space complexity of iterative merge?", "options": ["O(1)", "O(n)", "O(log n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "Average of 10, 20, 30?", "options": ["15", "20", "25", "30"], "correct_option": 1}]', TRUE),
(128, 'Detect Cycle in Linked List', 'medium', 'Linked Lists', 'https://leetcode.com/problems/linked-list-cycle/', 'Floyd''s cycle detection: slow and fast pointers. If they meet, cycle exists.', '[{"question": "Floyd''s algorithm uses how many pointers?", "options": ["1", "2", "3", "4"], "correct_option": 1}, {"question": "Cycle detection time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "If x:y = 3:4 and x=12, y=?", "options": ["14", "16", "18", "20"], "correct_option": 1}]', TRUE),
(129, 'Find Middle of Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/middle-of-the-linked-list/', 'Use slow/fast pointer: slow moves 1 step, fast moves 2 steps.', '[{"question": "In a 5-node list, middle is at?", "options": ["Node 2", "Node 3", "Node 4", "Node 5"], "correct_option": 1}, {"question": "Two-pointer technique time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Train covers 200m in 10s. Speed in km/h?", "options": ["60", "70", "72", "80"], "correct_option": 2}]', TRUE),
(130, 'LRU Cache', 'hard', 'Linked Lists', 'https://leetcode.com/problems/lru-cache/', 'Combine HashMap and doubly linked list for O(1) get and put.', '[{"question": "LRU stands for?", "options": ["Least Recently Used", "Last Recently Updated", "Least Random Unit", "Last Reset Unit"], "correct_option": 0}, {"question": "HashMap gives O(1) for?", "options": ["Insert, Delete, Search", "Sort only", "Range queries", "Traversal"], "correct_option": 0}, {"question": "A pipe fills a tank in 4 hours, another in 6 hours. Together?", "options": ["2.4 hours", "2.6 hours", "3 hours", "5 hours"], "correct_option": 0}]', TRUE),
(131, 'Inorder Traversal of BST', 'easy', 'Trees', 'https://leetcode.com/problems/binary-tree-inorder-traversal/', 'Inorder: Left → Root → Right. Yields sorted output for BST.', '[{"question": "Inorder traversal gives BST in?", "options": ["Sorted order", "Reverse order", "Random order", "Level order"], "correct_option": 0}, {"question": "BST search time complexity?", "options": ["O(log n)", "O(n)", "O(1)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If coins doubled daily from 1, on day 10?", "options": ["512", "1024", "512", "256"], "correct_option": 0}]', TRUE),
(132, 'Maximum Depth of Binary Tree', 'easy', 'Trees', 'https://leetcode.com/problems/maximum-depth-of-binary-tree/', 'Recursively return 1 + max(left depth, right depth). Base case: null = 0.', '[{"question": "DFS uses which data structure?", "options": ["Queue", "Stack", "Array", "Heap"], "correct_option": 1}, {"question": "BFS uses which data structure?", "options": ["Stack", "Queue", "Heap", "LinkedList"], "correct_option": 1}, {"question": "35 is what percent of 700?", "options": ["3%", "4%", "5%", "6%"], "correct_option": 2}]', TRUE),
(133, 'Validate Binary Search Tree', 'medium', 'Trees', 'https://leetcode.com/problems/validate-binary-search-tree/', 'Pass min/max bounds to each node recursively. Left < node < Right.', '[{"question": "BST property: left subtree has?", "options": ["Values > root", "Values < root", "Values = root", "Random values"], "correct_option": 1}, {"question": "Which traversal checks BST validity?", "options": ["Inorder", "Preorder", "Postorder", "Level order"], "correct_option": 0}, {"question": "A man earns 15,000/month and saves 20%. Monthly savings?", "options": ["2,500", "3,000", "3,500", "4,000"], "correct_option": 1}]', TRUE),
(134, 'Level Order Traversal', 'medium', 'Trees', 'https://leetcode.com/problems/binary-tree-level-order-traversal/', 'Use a Queue. Process level by level, tracking level boundaries.', '[{"question": "BFS explores nodes?", "options": ["Depth first", "Level by level", "Randomly", "Root only"], "correct_option": 1}, {"question": "Queue is?", "options": ["LIFO", "FIFO", "LILO", "FILO"], "correct_option": 1}, {"question": "A 10% discount on 500?", "options": ["400", "450", "460", "480"], "correct_option": 1}]', TRUE),
(135, 'Lowest Common Ancestor of BST', 'medium', 'Trees', 'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/', 'If both p and q are less than root, go left. If both greater, go right. Else root is LCA.', '[{"question": "LCA of a tree means?", "options": ["Deepest common node", "Shallowest node", "Root always", "Leaf node"], "correct_option": 0}, {"question": "BST LCA time complexity?", "options": ["O(log n)", "O(n)", "O(n\u00b2)", "O(1)"], "correct_option": 0}, {"question": "Speed = Distance/Time. If d=120km, t=2h, speed?", "options": ["50 km/h", "55 km/h", "60 km/h", "65 km/h"], "correct_option": 2}]', TRUE),
(136, 'Climbing Stairs', 'easy', 'Dynamic Programming', 'https://leetcode.com/problems/climbing-stairs/', 'Fibonacci pattern: f(n) = f(n-1) + f(n-2). Use bottom-up DP.', '[{"question": "Memoization stores?", "options": ["Computed results", "Random data", "Sorted arrays", "Only inputs"], "correct_option": 0}, {"question": "Fibonacci relation is?", "options": ["f(n) = f(n-1) + f(n-2)", "f(n) = f(n-1) * 2", "f(n) = n!", "f(n) = 2^n"], "correct_option": 0}, {"question": "Pipes A and B fill tank in 3h and 6h. Together in?", "options": ["1.5h", "2h", "2.5h", "3h"], "correct_option": 1}]', TRUE),
(137, 'Coin Change', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/coin-change/', 'dp[i] = min coins to make amount i. Try each coin at each amount.', '[{"question": "Greedy always works for coin change?", "options": ["Yes", "No, only for canonical coin systems", "Yes, with sorting", "No, never"], "correct_option": 1}, {"question": "DP bottom-up vs top-down: bottom-up uses?", "options": ["Recursion", "Iteration", "Both", "Neither"], "correct_option": 1}, {"question": "HCF of 12 and 18?", "options": ["3", "6", "9", "12"], "correct_option": 1}]', TRUE),
(138, 'Longest Common Subsequence', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/longest-common-subsequence/', '2D DP: if chars match, dp[i][j] = dp[i-1][j-1] + 1, else max of top/left.', '[{"question": "LCS differs from LCS (substring) because?", "options": ["Must be contiguous", "Need not be contiguous", "Same thing", "Sorted only"], "correct_option": 1}, {"question": "LCS time complexity?", "options": ["O(n)", "O(n log n)", "O(nm)", "O(n\u00b2m)"], "correct_option": 2}, {"question": "Simple interest on 1000 at 5% for 2 years?", "options": ["50", "100", "150", "200"], "correct_option": 1}]', TRUE),
(139, '0/1 Knapsack', 'hard', 'Dynamic Programming', 'https://www.geeksforgeeks.org/0-1-knapsack-problem-dp-10/', 'For each item and capacity, choose max of (include item) or (exclude item).', '[{"question": "0/1 Knapsack: each item can be taken?", "options": ["Multiple times", "Exactly once", "Zero or many times", "Never"], "correct_option": 1}, {"question": "Knapsack time complexity?", "options": ["O(n)", "O(n*W)", "O(n\u00b2)", "O(W)"], "correct_option": 1}, {"question": "20% of 80 + 80% of 20 = ?", "options": ["16", "32", "40", "48"], "correct_option": 1}]', TRUE),
(140, 'Word Break', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/word-break/', 'dp[i] = true if s[0..i] can be segmented using wordDict. Check all prefixes.', '[{"question": "Word break is solved by?", "options": ["Greedy", "DP with boolean array", "Binary search", "Sorting"], "correct_option": 1}, {"question": "Backtracking explores?", "options": ["All possibilities", "Only optimal", "Greedy choices", "Random paths"], "correct_option": 0}, {"question": "Compound interest formula involves?", "options": ["Linear growth", "Exponential growth", "Constant growth", "Logarithmic growth"], "correct_option": 1}]', TRUE),
(141, 'Number of Islands (DFS/BFS)', 'medium', 'Graphs', 'https://leetcode.com/problems/number-of-islands/', 'DFS from each unvisited ''1'' cell, mark all connected cells as visited.', '[{"question": "DFS uses which traversal?", "options": ["Level order", "Depth first", "Breadth first", "Random"], "correct_option": 1}, {"question": "Graph edge connects?", "options": ["Two nodes", "Three nodes", "One node", "All nodes"], "correct_option": 0}, {"question": "If 5 machines make 5 items in 5 min, how many machines for 100 items in 100 min?", "options": ["5", "10", "20", "100"], "correct_option": 0}]', TRUE),
(142, 'Clone Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/clone-graph/', 'BFS/DFS with a HashMap to map original nodes to their clones.', '[{"question": "Deep copy vs shallow copy: deep copy?", "options": ["Copies references", "Copies values recursively", "Copies nothing", "Only copies root"], "correct_option": 1}, {"question": "HashMap in graph cloning ensures?", "options": ["No duplicate clones", "Sorted order", "Faster DFS", "Level order"], "correct_option": 0}, {"question": "A number increased by 20% = 120. Original?", "options": ["90", "95", "100", "110"], "correct_option": 2}]', TRUE),
(143, 'Course Schedule (Topological Sort)', 'medium', 'Graphs', 'https://leetcode.com/problems/course-schedule/', 'Build adjacency list, detect cycle using DFS with 3 states (unvisited, visiting, visited).', '[{"question": "Topological sort applies to?", "options": ["Undirected graphs", "DAGs", "Complete graphs", "Trees only"], "correct_option": 1}, {"question": "Cycle in directed graph means?", "options": ["No topological order", "Easy sorting", "DAG property", "Tree property"], "correct_option": 0}, {"question": "Work rate: A does job in 10 days, B in 15 days. Together?", "options": ["5 days", "6 days", "8 days", "9 days"], "correct_option": 1}]', TRUE),
(144, 'Dijkstra''s Shortest Path', 'hard', 'Graphs', 'https://leetcode.com/problems/network-delay-time/', 'Use min-heap priority queue. Relax edges greedily by choosing shortest known distance.', '[{"question": "Dijkstra works with?", "options": ["Negative weights", "Non-negative weights", "All graphs", "Only trees"], "correct_option": 1}, {"question": "Dijkstra uses?", "options": ["Stack", "Queue", "Priority Queue", "Array"], "correct_option": 2}, {"question": "Boat covers 10 km upstream in 2h, downstream in 1h. Current speed?", "options": ["2 km/h", "2.5 km/h", "3 km/h", "3.5 km/h"], "correct_option": 1}]', TRUE),
(145, 'Detect Cycle in Undirected Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/graph-valid-tree/', 'Use Union-Find or DFS with parent tracking to detect back edges.', '[{"question": "Union-Find detects cycles in?", "options": ["O(n\u00b2)", "O(n log n)", "O(n \u03b1(n)) amortized", "O(1)"], "correct_option": 2}, {"question": "A back edge in DFS indicates?", "options": ["Tree edge", "Cycle", "Cross edge", "No cycle"], "correct_option": 1}, {"question": "If salary is 25,000 and increased by 8%, new salary?", "options": ["26,500", "27,000", "27,200", "28,000"], "correct_option": 1}]', TRUE),
(146, 'Valid Anagram', 'easy', 'Strings', 'https://leetcode.com/problems/valid-anagram/', 'Use character frequency count (array or HashMap). Compare counts.', '[{"question": "Anagram has?", "options": ["Same characters different order", "Same order", "Different characters", "Different length"], "correct_option": 0}, {"question": "Frequency count uses?", "options": ["Sorting", "HashMap/Array", "Binary search", "Stack"], "correct_option": 1}, {"question": "Average of first 5 odd numbers?", "options": ["3", "5", "7", "9"], "correct_option": 1}]', TRUE),
(147, 'Longest Substring Without Repeating Characters', 'medium', 'Strings', 'https://leetcode.com/problems/longest-substring-without-repeating-characters/', 'Sliding window with a HashSet. Shrink window from left when duplicate found.', '[{"question": "Sliding window maintains?", "options": ["A range [left, right]", "A fixed window", "Sorted order", "Reversed string"], "correct_option": 0}, {"question": "Sliding window time complexity?", "options": ["O(n\u00b2)", "O(n)", "O(n log n)", "O(1)"], "correct_option": 1}, {"question": "P and Q start a business with 3:5 ratio. Profit 8000, Q''s share?", "options": ["3000", "4000", "5000", "6000"], "correct_option": 2}]', TRUE),
(148, 'Group Anagrams', 'medium', 'Strings', 'https://leetcode.com/problems/group-anagrams/', 'Sort each word as the key. All anagrams have same sorted key. Use HashMap<String, List>.', '[{"question": "Sorting a string of length k takes?", "options": ["O(k)", "O(k log k)", "O(k\u00b2)", "O(1)"], "correct_option": 1}, {"question": "HashMap key for grouping anagrams?", "options": ["Sorted string", "First char", "Length", "Frequency"], "correct_option": 0}, {"question": "Simple interest: P=5000, R=6%, T=3 years. SI=?", "options": ["800", "900", "1000", "1100"], "correct_option": 1}]', TRUE),
(149, 'Minimum Window Substring', 'hard', 'Strings', 'https://leetcode.com/problems/minimum-window-substring/', 'Two-pointer sliding window with frequency maps. Shrink when all chars satisfied.', '[{"question": "Minimum window problem is?", "options": ["Fixed window", "Variable sliding window", "Binary search", "Two-stack"], "correct_option": 1}, {"question": "When do we shrink the window?", "options": ["When window is invalid", "When constraint satisfied", "Always", "At start only"], "correct_option": 1}, {"question": "What is 15% of 240?", "options": ["30", "34", "36", "40"], "correct_option": 2}]', TRUE),
(150, 'Palindrome Check', 'easy', 'Strings', 'https://leetcode.com/problems/valid-palindrome/', 'Two pointers from both ends, skip non-alphanumeric chars, compare char by char.', '[{"question": "Palindrome reads same?", "options": ["Forwards", "Backwards", "Both forwards and backwards", "Only lowercase"], "correct_option": 2}, {"question": "Two-pointer approach for palindrome is?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Ratio 2:3:5, total 200. Largest share?", "options": ["50", "80", "100", "120"], "correct_option": 2}]', TRUE),
(151, 'Two Sum', 'easy', 'Arrays', 'https://leetcode.com/problems/two-sum/', 'Use a hash map to store complement values as you iterate.', '[{"question": "What is the time complexity of linear search?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 2}, {"question": "Which data structure uses LIFO?", "options": ["Queue", "Stack", "Heap", "Tree"], "correct_option": 1}, {"question": "Train moves at 60 km/h for 2 hours. Distance?", "options": ["60 km", "90 km", "120 km", "180 km"], "correct_option": 2}]', TRUE),
(152, 'Best Time to Buy and Sell Stock', 'easy', 'Arrays', 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/', 'Track the minimum price seen so far and compute max profit at each step.', '[{"question": "Array index starts at?", "options": ["0", "1", "-1", "None"], "correct_option": 0}, {"question": "Which sorting is O(n log n) worst case?", "options": ["Bubble", "Selection", "Merge", "Insertion"], "correct_option": 2}, {"question": "A train travels 150 km in 3 hours. Speed?", "options": ["40 km/h", "45 km/h", "50 km/h", "55 km/h"], "correct_option": 2}]', TRUE),
(153, 'Contains Duplicate', 'easy', 'Arrays', 'https://leetcode.com/problems/contains-duplicate/', 'Use a HashSet — if element already exists, return true.', '[{"question": "HashSet uses which data structure internally?", "options": ["Array", "LinkedList", "HashMap", "Tree"], "correct_option": 2}, {"question": "Time complexity of HashSet lookup?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If 3 workers complete a job in 6 days, how many days for 2 workers?", "options": ["7", "8", "9", "10"], "correct_option": 2}]', TRUE),
(154, 'Product of Array Except Self', 'medium', 'Arrays', 'https://leetcode.com/problems/product-of-array-except-self/', 'Use prefix and suffix product arrays to avoid division.', '[{"question": "What does O(1) space mean?", "options": ["Constant space", "No space", "Linear space", "Log space"], "correct_option": 0}, {"question": "Prefix sum is useful for?", "options": ["Range queries", "Sorting", "Searching", "Hashing"], "correct_option": 0}, {"question": "A sum of first 10 natural numbers?", "options": ["45", "50", "55", "60"], "correct_option": 2}]', TRUE),
(155, 'Maximum Subarray (Kadane''s)', 'medium', 'Arrays', 'https://leetcode.com/problems/maximum-subarray/', 'Kadane''s algorithm: extend or restart subarray at each element.', '[{"question": "Kadane''s algorithm finds?", "options": ["Minimum subarray", "Maximum subarray", "Sorted subarray", "Empty subarray"], "correct_option": 1}, {"question": "Dynamic programming optimizes?", "options": ["Space", "Overlapping subproblems", "Sorting", "Recursion only"], "correct_option": 1}, {"question": "Profit if cost=200 and selling=250?", "options": ["25%", "30%", "35%", "40%"], "correct_option": 0}]', TRUE),
(156, 'Reverse Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/reverse-linked-list/', 'Use three pointers: prev, curr, next. Iterate and reverse links.', '[{"question": "Linked list node contains?", "options": ["Data only", "Data and pointer", "Pointer only", "Address only"], "correct_option": 1}, {"question": "Head of linked list points to?", "options": ["Last node", "First node", "Middle node", "Random node"], "correct_option": 1}, {"question": "LCM of 4 and 6?", "options": ["12", "18", "24", "8"], "correct_option": 0}]', TRUE),
(157, 'Merge Two Sorted Lists', 'easy', 'Linked Lists', 'https://leetcode.com/problems/merge-two-sorted-lists/', 'Use a dummy head and compare nodes from both lists iteratively.', '[{"question": "Dummy node technique helps with?", "options": ["Edge cases at head", "Tail insertion", "Middle insertion", "Sorting"], "correct_option": 0}, {"question": "Space complexity of iterative merge?", "options": ["O(1)", "O(n)", "O(log n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "Average of 10, 20, 30?", "options": ["15", "20", "25", "30"], "correct_option": 1}]', TRUE),
(158, 'Detect Cycle in Linked List', 'medium', 'Linked Lists', 'https://leetcode.com/problems/linked-list-cycle/', 'Floyd''s cycle detection: slow and fast pointers. If they meet, cycle exists.', '[{"question": "Floyd''s algorithm uses how many pointers?", "options": ["1", "2", "3", "4"], "correct_option": 1}, {"question": "Cycle detection time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "If x:y = 3:4 and x=12, y=?", "options": ["14", "16", "18", "20"], "correct_option": 1}]', TRUE),
(159, 'Find Middle of Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/middle-of-the-linked-list/', 'Use slow/fast pointer: slow moves 1 step, fast moves 2 steps.', '[{"question": "In a 5-node list, middle is at?", "options": ["Node 2", "Node 3", "Node 4", "Node 5"], "correct_option": 1}, {"question": "Two-pointer technique time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Train covers 200m in 10s. Speed in km/h?", "options": ["60", "70", "72", "80"], "correct_option": 2}]', TRUE),
(160, 'LRU Cache', 'hard', 'Linked Lists', 'https://leetcode.com/problems/lru-cache/', 'Combine HashMap and doubly linked list for O(1) get and put.', '[{"question": "LRU stands for?", "options": ["Least Recently Used", "Last Recently Updated", "Least Random Unit", "Last Reset Unit"], "correct_option": 0}, {"question": "HashMap gives O(1) for?", "options": ["Insert, Delete, Search", "Sort only", "Range queries", "Traversal"], "correct_option": 0}, {"question": "A pipe fills a tank in 4 hours, another in 6 hours. Together?", "options": ["2.4 hours", "2.6 hours", "3 hours", "5 hours"], "correct_option": 0}]', TRUE),
(161, 'Inorder Traversal of BST', 'easy', 'Trees', 'https://leetcode.com/problems/binary-tree-inorder-traversal/', 'Inorder: Left → Root → Right. Yields sorted output for BST.', '[{"question": "Inorder traversal gives BST in?", "options": ["Sorted order", "Reverse order", "Random order", "Level order"], "correct_option": 0}, {"question": "BST search time complexity?", "options": ["O(log n)", "O(n)", "O(1)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If coins doubled daily from 1, on day 10?", "options": ["512", "1024", "512", "256"], "correct_option": 0}]', TRUE),
(162, 'Maximum Depth of Binary Tree', 'easy', 'Trees', 'https://leetcode.com/problems/maximum-depth-of-binary-tree/', 'Recursively return 1 + max(left depth, right depth). Base case: null = 0.', '[{"question": "DFS uses which data structure?", "options": ["Queue", "Stack", "Array", "Heap"], "correct_option": 1}, {"question": "BFS uses which data structure?", "options": ["Stack", "Queue", "Heap", "LinkedList"], "correct_option": 1}, {"question": "35 is what percent of 700?", "options": ["3%", "4%", "5%", "6%"], "correct_option": 2}]', TRUE),
(163, 'Validate Binary Search Tree', 'medium', 'Trees', 'https://leetcode.com/problems/validate-binary-search-tree/', 'Pass min/max bounds to each node recursively. Left < node < Right.', '[{"question": "BST property: left subtree has?", "options": ["Values > root", "Values < root", "Values = root", "Random values"], "correct_option": 1}, {"question": "Which traversal checks BST validity?", "options": ["Inorder", "Preorder", "Postorder", "Level order"], "correct_option": 0}, {"question": "A man earns 15,000/month and saves 20%. Monthly savings?", "options": ["2,500", "3,000", "3,500", "4,000"], "correct_option": 1}]', TRUE),
(164, 'Level Order Traversal', 'medium', 'Trees', 'https://leetcode.com/problems/binary-tree-level-order-traversal/', 'Use a Queue. Process level by level, tracking level boundaries.', '[{"question": "BFS explores nodes?", "options": ["Depth first", "Level by level", "Randomly", "Root only"], "correct_option": 1}, {"question": "Queue is?", "options": ["LIFO", "FIFO", "LILO", "FILO"], "correct_option": 1}, {"question": "A 10% discount on 500?", "options": ["400", "450", "460", "480"], "correct_option": 1}]', TRUE),
(165, 'Lowest Common Ancestor of BST', 'medium', 'Trees', 'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/', 'If both p and q are less than root, go left. If both greater, go right. Else root is LCA.', '[{"question": "LCA of a tree means?", "options": ["Deepest common node", "Shallowest node", "Root always", "Leaf node"], "correct_option": 0}, {"question": "BST LCA time complexity?", "options": ["O(log n)", "O(n)", "O(n\u00b2)", "O(1)"], "correct_option": 0}, {"question": "Speed = Distance/Time. If d=120km, t=2h, speed?", "options": ["50 km/h", "55 km/h", "60 km/h", "65 km/h"], "correct_option": 2}]', TRUE),
(166, 'Climbing Stairs', 'easy', 'Dynamic Programming', 'https://leetcode.com/problems/climbing-stairs/', 'Fibonacci pattern: f(n) = f(n-1) + f(n-2). Use bottom-up DP.', '[{"question": "Memoization stores?", "options": ["Computed results", "Random data", "Sorted arrays", "Only inputs"], "correct_option": 0}, {"question": "Fibonacci relation is?", "options": ["f(n) = f(n-1) + f(n-2)", "f(n) = f(n-1) * 2", "f(n) = n!", "f(n) = 2^n"], "correct_option": 0}, {"question": "Pipes A and B fill tank in 3h and 6h. Together in?", "options": ["1.5h", "2h", "2.5h", "3h"], "correct_option": 1}]', TRUE),
(167, 'Coin Change', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/coin-change/', 'dp[i] = min coins to make amount i. Try each coin at each amount.', '[{"question": "Greedy always works for coin change?", "options": ["Yes", "No, only for canonical coin systems", "Yes, with sorting", "No, never"], "correct_option": 1}, {"question": "DP bottom-up vs top-down: bottom-up uses?", "options": ["Recursion", "Iteration", "Both", "Neither"], "correct_option": 1}, {"question": "HCF of 12 and 18?", "options": ["3", "6", "9", "12"], "correct_option": 1}]', TRUE),
(168, 'Longest Common Subsequence', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/longest-common-subsequence/', '2D DP: if chars match, dp[i][j] = dp[i-1][j-1] + 1, else max of top/left.', '[{"question": "LCS differs from LCS (substring) because?", "options": ["Must be contiguous", "Need not be contiguous", "Same thing", "Sorted only"], "correct_option": 1}, {"question": "LCS time complexity?", "options": ["O(n)", "O(n log n)", "O(nm)", "O(n\u00b2m)"], "correct_option": 2}, {"question": "Simple interest on 1000 at 5% for 2 years?", "options": ["50", "100", "150", "200"], "correct_option": 1}]', TRUE),
(169, '0/1 Knapsack', 'hard', 'Dynamic Programming', 'https://www.geeksforgeeks.org/0-1-knapsack-problem-dp-10/', 'For each item and capacity, choose max of (include item) or (exclude item).', '[{"question": "0/1 Knapsack: each item can be taken?", "options": ["Multiple times", "Exactly once", "Zero or many times", "Never"], "correct_option": 1}, {"question": "Knapsack time complexity?", "options": ["O(n)", "O(n*W)", "O(n\u00b2)", "O(W)"], "correct_option": 1}, {"question": "20% of 80 + 80% of 20 = ?", "options": ["16", "32", "40", "48"], "correct_option": 1}]', TRUE),
(170, 'Word Break', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/word-break/', 'dp[i] = true if s[0..i] can be segmented using wordDict. Check all prefixes.', '[{"question": "Word break is solved by?", "options": ["Greedy", "DP with boolean array", "Binary search", "Sorting"], "correct_option": 1}, {"question": "Backtracking explores?", "options": ["All possibilities", "Only optimal", "Greedy choices", "Random paths"], "correct_option": 0}, {"question": "Compound interest formula involves?", "options": ["Linear growth", "Exponential growth", "Constant growth", "Logarithmic growth"], "correct_option": 1}]', TRUE),
(171, 'Number of Islands (DFS/BFS)', 'medium', 'Graphs', 'https://leetcode.com/problems/number-of-islands/', 'DFS from each unvisited ''1'' cell, mark all connected cells as visited.', '[{"question": "DFS uses which traversal?", "options": ["Level order", "Depth first", "Breadth first", "Random"], "correct_option": 1}, {"question": "Graph edge connects?", "options": ["Two nodes", "Three nodes", "One node", "All nodes"], "correct_option": 0}, {"question": "If 5 machines make 5 items in 5 min, how many machines for 100 items in 100 min?", "options": ["5", "10", "20", "100"], "correct_option": 0}]', TRUE),
(172, 'Clone Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/clone-graph/', 'BFS/DFS with a HashMap to map original nodes to their clones.', '[{"question": "Deep copy vs shallow copy: deep copy?", "options": ["Copies references", "Copies values recursively", "Copies nothing", "Only copies root"], "correct_option": 1}, {"question": "HashMap in graph cloning ensures?", "options": ["No duplicate clones", "Sorted order", "Faster DFS", "Level order"], "correct_option": 0}, {"question": "A number increased by 20% = 120. Original?", "options": ["90", "95", "100", "110"], "correct_option": 2}]', TRUE),
(173, 'Course Schedule (Topological Sort)', 'medium', 'Graphs', 'https://leetcode.com/problems/course-schedule/', 'Build adjacency list, detect cycle using DFS with 3 states (unvisited, visiting, visited).', '[{"question": "Topological sort applies to?", "options": ["Undirected graphs", "DAGs", "Complete graphs", "Trees only"], "correct_option": 1}, {"question": "Cycle in directed graph means?", "options": ["No topological order", "Easy sorting", "DAG property", "Tree property"], "correct_option": 0}, {"question": "Work rate: A does job in 10 days, B in 15 days. Together?", "options": ["5 days", "6 days", "8 days", "9 days"], "correct_option": 1}]', TRUE),
(174, 'Dijkstra''s Shortest Path', 'hard', 'Graphs', 'https://leetcode.com/problems/network-delay-time/', 'Use min-heap priority queue. Relax edges greedily by choosing shortest known distance.', '[{"question": "Dijkstra works with?", "options": ["Negative weights", "Non-negative weights", "All graphs", "Only trees"], "correct_option": 1}, {"question": "Dijkstra uses?", "options": ["Stack", "Queue", "Priority Queue", "Array"], "correct_option": 2}, {"question": "Boat covers 10 km upstream in 2h, downstream in 1h. Current speed?", "options": ["2 km/h", "2.5 km/h", "3 km/h", "3.5 km/h"], "correct_option": 1}]', TRUE),
(175, 'Detect Cycle in Undirected Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/graph-valid-tree/', 'Use Union-Find or DFS with parent tracking to detect back edges.', '[{"question": "Union-Find detects cycles in?", "options": ["O(n\u00b2)", "O(n log n)", "O(n \u03b1(n)) amortized", "O(1)"], "correct_option": 2}, {"question": "A back edge in DFS indicates?", "options": ["Tree edge", "Cycle", "Cross edge", "No cycle"], "correct_option": 1}, {"question": "If salary is 25,000 and increased by 8%, new salary?", "options": ["26,500", "27,000", "27,200", "28,000"], "correct_option": 1}]', TRUE),
(176, 'Valid Anagram', 'easy', 'Strings', 'https://leetcode.com/problems/valid-anagram/', 'Use character frequency count (array or HashMap). Compare counts.', '[{"question": "Anagram has?", "options": ["Same characters different order", "Same order", "Different characters", "Different length"], "correct_option": 0}, {"question": "Frequency count uses?", "options": ["Sorting", "HashMap/Array", "Binary search", "Stack"], "correct_option": 1}, {"question": "Average of first 5 odd numbers?", "options": ["3", "5", "7", "9"], "correct_option": 1}]', TRUE),
(177, 'Longest Substring Without Repeating Characters', 'medium', 'Strings', 'https://leetcode.com/problems/longest-substring-without-repeating-characters/', 'Sliding window with a HashSet. Shrink window from left when duplicate found.', '[{"question": "Sliding window maintains?", "options": ["A range [left, right]", "A fixed window", "Sorted order", "Reversed string"], "correct_option": 0}, {"question": "Sliding window time complexity?", "options": ["O(n\u00b2)", "O(n)", "O(n log n)", "O(1)"], "correct_option": 1}, {"question": "P and Q start a business with 3:5 ratio. Profit 8000, Q''s share?", "options": ["3000", "4000", "5000", "6000"], "correct_option": 2}]', TRUE),
(178, 'Group Anagrams', 'medium', 'Strings', 'https://leetcode.com/problems/group-anagrams/', 'Sort each word as the key. All anagrams have same sorted key. Use HashMap<String, List>.', '[{"question": "Sorting a string of length k takes?", "options": ["O(k)", "O(k log k)", "O(k\u00b2)", "O(1)"], "correct_option": 1}, {"question": "HashMap key for grouping anagrams?", "options": ["Sorted string", "First char", "Length", "Frequency"], "correct_option": 0}, {"question": "Simple interest: P=5000, R=6%, T=3 years. SI=?", "options": ["800", "900", "1000", "1100"], "correct_option": 1}]', TRUE),
(179, 'Minimum Window Substring', 'hard', 'Strings', 'https://leetcode.com/problems/minimum-window-substring/', 'Two-pointer sliding window with frequency maps. Shrink when all chars satisfied.', '[{"question": "Minimum window problem is?", "options": ["Fixed window", "Variable sliding window", "Binary search", "Two-stack"], "correct_option": 1}, {"question": "When do we shrink the window?", "options": ["When window is invalid", "When constraint satisfied", "Always", "At start only"], "correct_option": 1}, {"question": "What is 15% of 240?", "options": ["30", "34", "36", "40"], "correct_option": 2}]', TRUE),
(180, 'Palindrome Check', 'easy', 'Strings', 'https://leetcode.com/problems/valid-palindrome/', 'Two pointers from both ends, skip non-alphanumeric chars, compare char by char.', '[{"question": "Palindrome reads same?", "options": ["Forwards", "Backwards", "Both forwards and backwards", "Only lowercase"], "correct_option": 2}, {"question": "Two-pointer approach for palindrome is?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Ratio 2:3:5, total 200. Largest share?", "options": ["50", "80", "100", "120"], "correct_option": 2}]', TRUE),
(181, 'Two Sum', 'easy', 'Arrays', 'https://leetcode.com/problems/two-sum/', 'Use a hash map to store complement values as you iterate.', '[{"question": "What is the time complexity of linear search?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 2}, {"question": "Which data structure uses LIFO?", "options": ["Queue", "Stack", "Heap", "Tree"], "correct_option": 1}, {"question": "Train moves at 60 km/h for 2 hours. Distance?", "options": ["60 km", "90 km", "120 km", "180 km"], "correct_option": 2}]', TRUE),
(182, 'Best Time to Buy and Sell Stock', 'easy', 'Arrays', 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/', 'Track the minimum price seen so far and compute max profit at each step.', '[{"question": "Array index starts at?", "options": ["0", "1", "-1", "None"], "correct_option": 0}, {"question": "Which sorting is O(n log n) worst case?", "options": ["Bubble", "Selection", "Merge", "Insertion"], "correct_option": 2}, {"question": "A train travels 150 km in 3 hours. Speed?", "options": ["40 km/h", "45 km/h", "50 km/h", "55 km/h"], "correct_option": 2}]', TRUE),
(183, 'Contains Duplicate', 'easy', 'Arrays', 'https://leetcode.com/problems/contains-duplicate/', 'Use a HashSet — if element already exists, return true.', '[{"question": "HashSet uses which data structure internally?", "options": ["Array", "LinkedList", "HashMap", "Tree"], "correct_option": 2}, {"question": "Time complexity of HashSet lookup?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If 3 workers complete a job in 6 days, how many days for 2 workers?", "options": ["7", "8", "9", "10"], "correct_option": 2}]', TRUE),
(184, 'Product of Array Except Self', 'medium', 'Arrays', 'https://leetcode.com/problems/product-of-array-except-self/', 'Use prefix and suffix product arrays to avoid division.', '[{"question": "What does O(1) space mean?", "options": ["Constant space", "No space", "Linear space", "Log space"], "correct_option": 0}, {"question": "Prefix sum is useful for?", "options": ["Range queries", "Sorting", "Searching", "Hashing"], "correct_option": 0}, {"question": "A sum of first 10 natural numbers?", "options": ["45", "50", "55", "60"], "correct_option": 2}]', TRUE),
(185, 'Maximum Subarray (Kadane''s)', 'medium', 'Arrays', 'https://leetcode.com/problems/maximum-subarray/', 'Kadane''s algorithm: extend or restart subarray at each element.', '[{"question": "Kadane''s algorithm finds?", "options": ["Minimum subarray", "Maximum subarray", "Sorted subarray", "Empty subarray"], "correct_option": 1}, {"question": "Dynamic programming optimizes?", "options": ["Space", "Overlapping subproblems", "Sorting", "Recursion only"], "correct_option": 1}, {"question": "Profit if cost=200 and selling=250?", "options": ["25%", "30%", "35%", "40%"], "correct_option": 0}]', TRUE),
(186, 'Reverse Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/reverse-linked-list/', 'Use three pointers: prev, curr, next. Iterate and reverse links.', '[{"question": "Linked list node contains?", "options": ["Data only", "Data and pointer", "Pointer only", "Address only"], "correct_option": 1}, {"question": "Head of linked list points to?", "options": ["Last node", "First node", "Middle node", "Random node"], "correct_option": 1}, {"question": "LCM of 4 and 6?", "options": ["12", "18", "24", "8"], "correct_option": 0}]', TRUE),
(187, 'Merge Two Sorted Lists', 'easy', 'Linked Lists', 'https://leetcode.com/problems/merge-two-sorted-lists/', 'Use a dummy head and compare nodes from both lists iteratively.', '[{"question": "Dummy node technique helps with?", "options": ["Edge cases at head", "Tail insertion", "Middle insertion", "Sorting"], "correct_option": 0}, {"question": "Space complexity of iterative merge?", "options": ["O(1)", "O(n)", "O(log n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "Average of 10, 20, 30?", "options": ["15", "20", "25", "30"], "correct_option": 1}]', TRUE),
(188, 'Detect Cycle in Linked List', 'medium', 'Linked Lists', 'https://leetcode.com/problems/linked-list-cycle/', 'Floyd''s cycle detection: slow and fast pointers. If they meet, cycle exists.', '[{"question": "Floyd''s algorithm uses how many pointers?", "options": ["1", "2", "3", "4"], "correct_option": 1}, {"question": "Cycle detection time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "If x:y = 3:4 and x=12, y=?", "options": ["14", "16", "18", "20"], "correct_option": 1}]', TRUE),
(189, 'Find Middle of Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/middle-of-the-linked-list/', 'Use slow/fast pointer: slow moves 1 step, fast moves 2 steps.', '[{"question": "In a 5-node list, middle is at?", "options": ["Node 2", "Node 3", "Node 4", "Node 5"], "correct_option": 1}, {"question": "Two-pointer technique time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Train covers 200m in 10s. Speed in km/h?", "options": ["60", "70", "72", "80"], "correct_option": 2}]', TRUE),
(190, 'LRU Cache', 'hard', 'Linked Lists', 'https://leetcode.com/problems/lru-cache/', 'Combine HashMap and doubly linked list for O(1) get and put.', '[{"question": "LRU stands for?", "options": ["Least Recently Used", "Last Recently Updated", "Least Random Unit", "Last Reset Unit"], "correct_option": 0}, {"question": "HashMap gives O(1) for?", "options": ["Insert, Delete, Search", "Sort only", "Range queries", "Traversal"], "correct_option": 0}, {"question": "A pipe fills a tank in 4 hours, another in 6 hours. Together?", "options": ["2.4 hours", "2.6 hours", "3 hours", "5 hours"], "correct_option": 0}]', TRUE),
(191, 'Inorder Traversal of BST', 'easy', 'Trees', 'https://leetcode.com/problems/binary-tree-inorder-traversal/', 'Inorder: Left → Root → Right. Yields sorted output for BST.', '[{"question": "Inorder traversal gives BST in?", "options": ["Sorted order", "Reverse order", "Random order", "Level order"], "correct_option": 0}, {"question": "BST search time complexity?", "options": ["O(log n)", "O(n)", "O(1)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If coins doubled daily from 1, on day 10?", "options": ["512", "1024", "512", "256"], "correct_option": 0}]', TRUE),
(192, 'Maximum Depth of Binary Tree', 'easy', 'Trees', 'https://leetcode.com/problems/maximum-depth-of-binary-tree/', 'Recursively return 1 + max(left depth, right depth). Base case: null = 0.', '[{"question": "DFS uses which data structure?", "options": ["Queue", "Stack", "Array", "Heap"], "correct_option": 1}, {"question": "BFS uses which data structure?", "options": ["Stack", "Queue", "Heap", "LinkedList"], "correct_option": 1}, {"question": "35 is what percent of 700?", "options": ["3%", "4%", "5%", "6%"], "correct_option": 2}]', TRUE),
(193, 'Validate Binary Search Tree', 'medium', 'Trees', 'https://leetcode.com/problems/validate-binary-search-tree/', 'Pass min/max bounds to each node recursively. Left < node < Right.', '[{"question": "BST property: left subtree has?", "options": ["Values > root", "Values < root", "Values = root", "Random values"], "correct_option": 1}, {"question": "Which traversal checks BST validity?", "options": ["Inorder", "Preorder", "Postorder", "Level order"], "correct_option": 0}, {"question": "A man earns 15,000/month and saves 20%. Monthly savings?", "options": ["2,500", "3,000", "3,500", "4,000"], "correct_option": 1}]', TRUE),
(194, 'Level Order Traversal', 'medium', 'Trees', 'https://leetcode.com/problems/binary-tree-level-order-traversal/', 'Use a Queue. Process level by level, tracking level boundaries.', '[{"question": "BFS explores nodes?", "options": ["Depth first", "Level by level", "Randomly", "Root only"], "correct_option": 1}, {"question": "Queue is?", "options": ["LIFO", "FIFO", "LILO", "FILO"], "correct_option": 1}, {"question": "A 10% discount on 500?", "options": ["400", "450", "460", "480"], "correct_option": 1}]', TRUE),
(195, 'Lowest Common Ancestor of BST', 'medium', 'Trees', 'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/', 'If both p and q are less than root, go left. If both greater, go right. Else root is LCA.', '[{"question": "LCA of a tree means?", "options": ["Deepest common node", "Shallowest node", "Root always", "Leaf node"], "correct_option": 0}, {"question": "BST LCA time complexity?", "options": ["O(log n)", "O(n)", "O(n\u00b2)", "O(1)"], "correct_option": 0}, {"question": "Speed = Distance/Time. If d=120km, t=2h, speed?", "options": ["50 km/h", "55 km/h", "60 km/h", "65 km/h"], "correct_option": 2}]', TRUE),
(196, 'Climbing Stairs', 'easy', 'Dynamic Programming', 'https://leetcode.com/problems/climbing-stairs/', 'Fibonacci pattern: f(n) = f(n-1) + f(n-2). Use bottom-up DP.', '[{"question": "Memoization stores?", "options": ["Computed results", "Random data", "Sorted arrays", "Only inputs"], "correct_option": 0}, {"question": "Fibonacci relation is?", "options": ["f(n) = f(n-1) + f(n-2)", "f(n) = f(n-1) * 2", "f(n) = n!", "f(n) = 2^n"], "correct_option": 0}, {"question": "Pipes A and B fill tank in 3h and 6h. Together in?", "options": ["1.5h", "2h", "2.5h", "3h"], "correct_option": 1}]', TRUE),
(197, 'Coin Change', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/coin-change/', 'dp[i] = min coins to make amount i. Try each coin at each amount.', '[{"question": "Greedy always works for coin change?", "options": ["Yes", "No, only for canonical coin systems", "Yes, with sorting", "No, never"], "correct_option": 1}, {"question": "DP bottom-up vs top-down: bottom-up uses?", "options": ["Recursion", "Iteration", "Both", "Neither"], "correct_option": 1}, {"question": "HCF of 12 and 18?", "options": ["3", "6", "9", "12"], "correct_option": 1}]', TRUE),
(198, 'Longest Common Subsequence', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/longest-common-subsequence/', '2D DP: if chars match, dp[i][j] = dp[i-1][j-1] + 1, else max of top/left.', '[{"question": "LCS differs from LCS (substring) because?", "options": ["Must be contiguous", "Need not be contiguous", "Same thing", "Sorted only"], "correct_option": 1}, {"question": "LCS time complexity?", "options": ["O(n)", "O(n log n)", "O(nm)", "O(n\u00b2m)"], "correct_option": 2}, {"question": "Simple interest on 1000 at 5% for 2 years?", "options": ["50", "100", "150", "200"], "correct_option": 1}]', TRUE),
(199, '0/1 Knapsack', 'hard', 'Dynamic Programming', 'https://www.geeksforgeeks.org/0-1-knapsack-problem-dp-10/', 'For each item and capacity, choose max of (include item) or (exclude item).', '[{"question": "0/1 Knapsack: each item can be taken?", "options": ["Multiple times", "Exactly once", "Zero or many times", "Never"], "correct_option": 1}, {"question": "Knapsack time complexity?", "options": ["O(n)", "O(n*W)", "O(n\u00b2)", "O(W)"], "correct_option": 1}, {"question": "20% of 80 + 80% of 20 = ?", "options": ["16", "32", "40", "48"], "correct_option": 1}]', TRUE),
(200, 'Word Break', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/word-break/', 'dp[i] = true if s[0..i] can be segmented using wordDict. Check all prefixes.', '[{"question": "Word break is solved by?", "options": ["Greedy", "DP with boolean array", "Binary search", "Sorting"], "correct_option": 1}, {"question": "Backtracking explores?", "options": ["All possibilities", "Only optimal", "Greedy choices", "Random paths"], "correct_option": 0}, {"question": "Compound interest formula involves?", "options": ["Linear growth", "Exponential growth", "Constant growth", "Logarithmic growth"], "correct_option": 1}]', TRUE),
(201, 'Number of Islands (DFS/BFS)', 'medium', 'Graphs', 'https://leetcode.com/problems/number-of-islands/', 'DFS from each unvisited ''1'' cell, mark all connected cells as visited.', '[{"question": "DFS uses which traversal?", "options": ["Level order", "Depth first", "Breadth first", "Random"], "correct_option": 1}, {"question": "Graph edge connects?", "options": ["Two nodes", "Three nodes", "One node", "All nodes"], "correct_option": 0}, {"question": "If 5 machines make 5 items in 5 min, how many machines for 100 items in 100 min?", "options": ["5", "10", "20", "100"], "correct_option": 0}]', TRUE),
(202, 'Clone Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/clone-graph/', 'BFS/DFS with a HashMap to map original nodes to their clones.', '[{"question": "Deep copy vs shallow copy: deep copy?", "options": ["Copies references", "Copies values recursively", "Copies nothing", "Only copies root"], "correct_option": 1}, {"question": "HashMap in graph cloning ensures?", "options": ["No duplicate clones", "Sorted order", "Faster DFS", "Level order"], "correct_option": 0}, {"question": "A number increased by 20% = 120. Original?", "options": ["90", "95", "100", "110"], "correct_option": 2}]', TRUE),
(203, 'Course Schedule (Topological Sort)', 'medium', 'Graphs', 'https://leetcode.com/problems/course-schedule/', 'Build adjacency list, detect cycle using DFS with 3 states (unvisited, visiting, visited).', '[{"question": "Topological sort applies to?", "options": ["Undirected graphs", "DAGs", "Complete graphs", "Trees only"], "correct_option": 1}, {"question": "Cycle in directed graph means?", "options": ["No topological order", "Easy sorting", "DAG property", "Tree property"], "correct_option": 0}, {"question": "Work rate: A does job in 10 days, B in 15 days. Together?", "options": ["5 days", "6 days", "8 days", "9 days"], "correct_option": 1}]', TRUE),
(204, 'Dijkstra''s Shortest Path', 'hard', 'Graphs', 'https://leetcode.com/problems/network-delay-time/', 'Use min-heap priority queue. Relax edges greedily by choosing shortest known distance.', '[{"question": "Dijkstra works with?", "options": ["Negative weights", "Non-negative weights", "All graphs", "Only trees"], "correct_option": 1}, {"question": "Dijkstra uses?", "options": ["Stack", "Queue", "Priority Queue", "Array"], "correct_option": 2}, {"question": "Boat covers 10 km upstream in 2h, downstream in 1h. Current speed?", "options": ["2 km/h", "2.5 km/h", "3 km/h", "3.5 km/h"], "correct_option": 1}]', TRUE),
(205, 'Detect Cycle in Undirected Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/graph-valid-tree/', 'Use Union-Find or DFS with parent tracking to detect back edges.', '[{"question": "Union-Find detects cycles in?", "options": ["O(n\u00b2)", "O(n log n)", "O(n \u03b1(n)) amortized", "O(1)"], "correct_option": 2}, {"question": "A back edge in DFS indicates?", "options": ["Tree edge", "Cycle", "Cross edge", "No cycle"], "correct_option": 1}, {"question": "If salary is 25,000 and increased by 8%, new salary?", "options": ["26,500", "27,000", "27,200", "28,000"], "correct_option": 1}]', TRUE),
(206, 'Valid Anagram', 'easy', 'Strings', 'https://leetcode.com/problems/valid-anagram/', 'Use character frequency count (array or HashMap). Compare counts.', '[{"question": "Anagram has?", "options": ["Same characters different order", "Same order", "Different characters", "Different length"], "correct_option": 0}, {"question": "Frequency count uses?", "options": ["Sorting", "HashMap/Array", "Binary search", "Stack"], "correct_option": 1}, {"question": "Average of first 5 odd numbers?", "options": ["3", "5", "7", "9"], "correct_option": 1}]', TRUE),
(207, 'Longest Substring Without Repeating Characters', 'medium', 'Strings', 'https://leetcode.com/problems/longest-substring-without-repeating-characters/', 'Sliding window with a HashSet. Shrink window from left when duplicate found.', '[{"question": "Sliding window maintains?", "options": ["A range [left, right]", "A fixed window", "Sorted order", "Reversed string"], "correct_option": 0}, {"question": "Sliding window time complexity?", "options": ["O(n\u00b2)", "O(n)", "O(n log n)", "O(1)"], "correct_option": 1}, {"question": "P and Q start a business with 3:5 ratio. Profit 8000, Q''s share?", "options": ["3000", "4000", "5000", "6000"], "correct_option": 2}]', TRUE),
(208, 'Group Anagrams', 'medium', 'Strings', 'https://leetcode.com/problems/group-anagrams/', 'Sort each word as the key. All anagrams have same sorted key. Use HashMap<String, List>.', '[{"question": "Sorting a string of length k takes?", "options": ["O(k)", "O(k log k)", "O(k\u00b2)", "O(1)"], "correct_option": 1}, {"question": "HashMap key for grouping anagrams?", "options": ["Sorted string", "First char", "Length", "Frequency"], "correct_option": 0}, {"question": "Simple interest: P=5000, R=6%, T=3 years. SI=?", "options": ["800", "900", "1000", "1100"], "correct_option": 1}]', TRUE),
(209, 'Minimum Window Substring', 'hard', 'Strings', 'https://leetcode.com/problems/minimum-window-substring/', 'Two-pointer sliding window with frequency maps. Shrink when all chars satisfied.', '[{"question": "Minimum window problem is?", "options": ["Fixed window", "Variable sliding window", "Binary search", "Two-stack"], "correct_option": 1}, {"question": "When do we shrink the window?", "options": ["When window is invalid", "When constraint satisfied", "Always", "At start only"], "correct_option": 1}, {"question": "What is 15% of 240?", "options": ["30", "34", "36", "40"], "correct_option": 2}]', TRUE),
(210, 'Palindrome Check', 'easy', 'Strings', 'https://leetcode.com/problems/valid-palindrome/', 'Two pointers from both ends, skip non-alphanumeric chars, compare char by char.', '[{"question": "Palindrome reads same?", "options": ["Forwards", "Backwards", "Both forwards and backwards", "Only lowercase"], "correct_option": 2}, {"question": "Two-pointer approach for palindrome is?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Ratio 2:3:5, total 200. Largest share?", "options": ["50", "80", "100", "120"], "correct_option": 2}]', TRUE),
(211, 'Two Sum', 'easy', 'Arrays', 'https://leetcode.com/problems/two-sum/', 'Use a hash map to store complement values as you iterate.', '[{"question": "What is the time complexity of linear search?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 2}, {"question": "Which data structure uses LIFO?", "options": ["Queue", "Stack", "Heap", "Tree"], "correct_option": 1}, {"question": "Train moves at 60 km/h for 2 hours. Distance?", "options": ["60 km", "90 km", "120 km", "180 km"], "correct_option": 2}]', TRUE),
(212, 'Best Time to Buy and Sell Stock', 'easy', 'Arrays', 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/', 'Track the minimum price seen so far and compute max profit at each step.', '[{"question": "Array index starts at?", "options": ["0", "1", "-1", "None"], "correct_option": 0}, {"question": "Which sorting is O(n log n) worst case?", "options": ["Bubble", "Selection", "Merge", "Insertion"], "correct_option": 2}, {"question": "A train travels 150 km in 3 hours. Speed?", "options": ["40 km/h", "45 km/h", "50 km/h", "55 km/h"], "correct_option": 2}]', TRUE),
(213, 'Contains Duplicate', 'easy', 'Arrays', 'https://leetcode.com/problems/contains-duplicate/', 'Use a HashSet — if element already exists, return true.', '[{"question": "HashSet uses which data structure internally?", "options": ["Array", "LinkedList", "HashMap", "Tree"], "correct_option": 2}, {"question": "Time complexity of HashSet lookup?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If 3 workers complete a job in 6 days, how many days for 2 workers?", "options": ["7", "8", "9", "10"], "correct_option": 2}]', TRUE),
(214, 'Product of Array Except Self', 'medium', 'Arrays', 'https://leetcode.com/problems/product-of-array-except-self/', 'Use prefix and suffix product arrays to avoid division.', '[{"question": "What does O(1) space mean?", "options": ["Constant space", "No space", "Linear space", "Log space"], "correct_option": 0}, {"question": "Prefix sum is useful for?", "options": ["Range queries", "Sorting", "Searching", "Hashing"], "correct_option": 0}, {"question": "A sum of first 10 natural numbers?", "options": ["45", "50", "55", "60"], "correct_option": 2}]', TRUE),
(215, 'Maximum Subarray (Kadane''s)', 'medium', 'Arrays', 'https://leetcode.com/problems/maximum-subarray/', 'Kadane''s algorithm: extend or restart subarray at each element.', '[{"question": "Kadane''s algorithm finds?", "options": ["Minimum subarray", "Maximum subarray", "Sorted subarray", "Empty subarray"], "correct_option": 1}, {"question": "Dynamic programming optimizes?", "options": ["Space", "Overlapping subproblems", "Sorting", "Recursion only"], "correct_option": 1}, {"question": "Profit if cost=200 and selling=250?", "options": ["25%", "30%", "35%", "40%"], "correct_option": 0}]', TRUE),
(216, 'Reverse Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/reverse-linked-list/', 'Use three pointers: prev, curr, next. Iterate and reverse links.', '[{"question": "Linked list node contains?", "options": ["Data only", "Data and pointer", "Pointer only", "Address only"], "correct_option": 1}, {"question": "Head of linked list points to?", "options": ["Last node", "First node", "Middle node", "Random node"], "correct_option": 1}, {"question": "LCM of 4 and 6?", "options": ["12", "18", "24", "8"], "correct_option": 0}]', TRUE),
(217, 'Merge Two Sorted Lists', 'easy', 'Linked Lists', 'https://leetcode.com/problems/merge-two-sorted-lists/', 'Use a dummy head and compare nodes from both lists iteratively.', '[{"question": "Dummy node technique helps with?", "options": ["Edge cases at head", "Tail insertion", "Middle insertion", "Sorting"], "correct_option": 0}, {"question": "Space complexity of iterative merge?", "options": ["O(1)", "O(n)", "O(log n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "Average of 10, 20, 30?", "options": ["15", "20", "25", "30"], "correct_option": 1}]', TRUE),
(218, 'Detect Cycle in Linked List', 'medium', 'Linked Lists', 'https://leetcode.com/problems/linked-list-cycle/', 'Floyd''s cycle detection: slow and fast pointers. If they meet, cycle exists.', '[{"question": "Floyd''s algorithm uses how many pointers?", "options": ["1", "2", "3", "4"], "correct_option": 1}, {"question": "Cycle detection time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "If x:y = 3:4 and x=12, y=?", "options": ["14", "16", "18", "20"], "correct_option": 1}]', TRUE),
(219, 'Find Middle of Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/middle-of-the-linked-list/', 'Use slow/fast pointer: slow moves 1 step, fast moves 2 steps.', '[{"question": "In a 5-node list, middle is at?", "options": ["Node 2", "Node 3", "Node 4", "Node 5"], "correct_option": 1}, {"question": "Two-pointer technique time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Train covers 200m in 10s. Speed in km/h?", "options": ["60", "70", "72", "80"], "correct_option": 2}]', TRUE),
(220, 'LRU Cache', 'hard', 'Linked Lists', 'https://leetcode.com/problems/lru-cache/', 'Combine HashMap and doubly linked list for O(1) get and put.', '[{"question": "LRU stands for?", "options": ["Least Recently Used", "Last Recently Updated", "Least Random Unit", "Last Reset Unit"], "correct_option": 0}, {"question": "HashMap gives O(1) for?", "options": ["Insert, Delete, Search", "Sort only", "Range queries", "Traversal"], "correct_option": 0}, {"question": "A pipe fills a tank in 4 hours, another in 6 hours. Together?", "options": ["2.4 hours", "2.6 hours", "3 hours", "5 hours"], "correct_option": 0}]', TRUE),
(221, 'Inorder Traversal of BST', 'easy', 'Trees', 'https://leetcode.com/problems/binary-tree-inorder-traversal/', 'Inorder: Left → Root → Right. Yields sorted output for BST.', '[{"question": "Inorder traversal gives BST in?", "options": ["Sorted order", "Reverse order", "Random order", "Level order"], "correct_option": 0}, {"question": "BST search time complexity?", "options": ["O(log n)", "O(n)", "O(1)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If coins doubled daily from 1, on day 10?", "options": ["512", "1024", "512", "256"], "correct_option": 0}]', TRUE),
(222, 'Maximum Depth of Binary Tree', 'easy', 'Trees', 'https://leetcode.com/problems/maximum-depth-of-binary-tree/', 'Recursively return 1 + max(left depth, right depth). Base case: null = 0.', '[{"question": "DFS uses which data structure?", "options": ["Queue", "Stack", "Array", "Heap"], "correct_option": 1}, {"question": "BFS uses which data structure?", "options": ["Stack", "Queue", "Heap", "LinkedList"], "correct_option": 1}, {"question": "35 is what percent of 700?", "options": ["3%", "4%", "5%", "6%"], "correct_option": 2}]', TRUE),
(223, 'Validate Binary Search Tree', 'medium', 'Trees', 'https://leetcode.com/problems/validate-binary-search-tree/', 'Pass min/max bounds to each node recursively. Left < node < Right.', '[{"question": "BST property: left subtree has?", "options": ["Values > root", "Values < root", "Values = root", "Random values"], "correct_option": 1}, {"question": "Which traversal checks BST validity?", "options": ["Inorder", "Preorder", "Postorder", "Level order"], "correct_option": 0}, {"question": "A man earns 15,000/month and saves 20%. Monthly savings?", "options": ["2,500", "3,000", "3,500", "4,000"], "correct_option": 1}]', TRUE),
(224, 'Level Order Traversal', 'medium', 'Trees', 'https://leetcode.com/problems/binary-tree-level-order-traversal/', 'Use a Queue. Process level by level, tracking level boundaries.', '[{"question": "BFS explores nodes?", "options": ["Depth first", "Level by level", "Randomly", "Root only"], "correct_option": 1}, {"question": "Queue is?", "options": ["LIFO", "FIFO", "LILO", "FILO"], "correct_option": 1}, {"question": "A 10% discount on 500?", "options": ["400", "450", "460", "480"], "correct_option": 1}]', TRUE),
(225, 'Lowest Common Ancestor of BST', 'medium', 'Trees', 'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/', 'If both p and q are less than root, go left. If both greater, go right. Else root is LCA.', '[{"question": "LCA of a tree means?", "options": ["Deepest common node", "Shallowest node", "Root always", "Leaf node"], "correct_option": 0}, {"question": "BST LCA time complexity?", "options": ["O(log n)", "O(n)", "O(n\u00b2)", "O(1)"], "correct_option": 0}, {"question": "Speed = Distance/Time. If d=120km, t=2h, speed?", "options": ["50 km/h", "55 km/h", "60 km/h", "65 km/h"], "correct_option": 2}]', TRUE),
(226, 'Climbing Stairs', 'easy', 'Dynamic Programming', 'https://leetcode.com/problems/climbing-stairs/', 'Fibonacci pattern: f(n) = f(n-1) + f(n-2). Use bottom-up DP.', '[{"question": "Memoization stores?", "options": ["Computed results", "Random data", "Sorted arrays", "Only inputs"], "correct_option": 0}, {"question": "Fibonacci relation is?", "options": ["f(n) = f(n-1) + f(n-2)", "f(n) = f(n-1) * 2", "f(n) = n!", "f(n) = 2^n"], "correct_option": 0}, {"question": "Pipes A and B fill tank in 3h and 6h. Together in?", "options": ["1.5h", "2h", "2.5h", "3h"], "correct_option": 1}]', TRUE),
(227, 'Coin Change', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/coin-change/', 'dp[i] = min coins to make amount i. Try each coin at each amount.', '[{"question": "Greedy always works for coin change?", "options": ["Yes", "No, only for canonical coin systems", "Yes, with sorting", "No, never"], "correct_option": 1}, {"question": "DP bottom-up vs top-down: bottom-up uses?", "options": ["Recursion", "Iteration", "Both", "Neither"], "correct_option": 1}, {"question": "HCF of 12 and 18?", "options": ["3", "6", "9", "12"], "correct_option": 1}]', TRUE),
(228, 'Longest Common Subsequence', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/longest-common-subsequence/', '2D DP: if chars match, dp[i][j] = dp[i-1][j-1] + 1, else max of top/left.', '[{"question": "LCS differs from LCS (substring) because?", "options": ["Must be contiguous", "Need not be contiguous", "Same thing", "Sorted only"], "correct_option": 1}, {"question": "LCS time complexity?", "options": ["O(n)", "O(n log n)", "O(nm)", "O(n\u00b2m)"], "correct_option": 2}, {"question": "Simple interest on 1000 at 5% for 2 years?", "options": ["50", "100", "150", "200"], "correct_option": 1}]', TRUE),
(229, '0/1 Knapsack', 'hard', 'Dynamic Programming', 'https://www.geeksforgeeks.org/0-1-knapsack-problem-dp-10/', 'For each item and capacity, choose max of (include item) or (exclude item).', '[{"question": "0/1 Knapsack: each item can be taken?", "options": ["Multiple times", "Exactly once", "Zero or many times", "Never"], "correct_option": 1}, {"question": "Knapsack time complexity?", "options": ["O(n)", "O(n*W)", "O(n\u00b2)", "O(W)"], "correct_option": 1}, {"question": "20% of 80 + 80% of 20 = ?", "options": ["16", "32", "40", "48"], "correct_option": 1}]', TRUE),
(230, 'Word Break', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/word-break/', 'dp[i] = true if s[0..i] can be segmented using wordDict. Check all prefixes.', '[{"question": "Word break is solved by?", "options": ["Greedy", "DP with boolean array", "Binary search", "Sorting"], "correct_option": 1}, {"question": "Backtracking explores?", "options": ["All possibilities", "Only optimal", "Greedy choices", "Random paths"], "correct_option": 0}, {"question": "Compound interest formula involves?", "options": ["Linear growth", "Exponential growth", "Constant growth", "Logarithmic growth"], "correct_option": 1}]', TRUE),
(231, 'Number of Islands (DFS/BFS)', 'medium', 'Graphs', 'https://leetcode.com/problems/number-of-islands/', 'DFS from each unvisited ''1'' cell, mark all connected cells as visited.', '[{"question": "DFS uses which traversal?", "options": ["Level order", "Depth first", "Breadth first", "Random"], "correct_option": 1}, {"question": "Graph edge connects?", "options": ["Two nodes", "Three nodes", "One node", "All nodes"], "correct_option": 0}, {"question": "If 5 machines make 5 items in 5 min, how many machines for 100 items in 100 min?", "options": ["5", "10", "20", "100"], "correct_option": 0}]', TRUE),
(232, 'Clone Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/clone-graph/', 'BFS/DFS with a HashMap to map original nodes to their clones.', '[{"question": "Deep copy vs shallow copy: deep copy?", "options": ["Copies references", "Copies values recursively", "Copies nothing", "Only copies root"], "correct_option": 1}, {"question": "HashMap in graph cloning ensures?", "options": ["No duplicate clones", "Sorted order", "Faster DFS", "Level order"], "correct_option": 0}, {"question": "A number increased by 20% = 120. Original?", "options": ["90", "95", "100", "110"], "correct_option": 2}]', TRUE),
(233, 'Course Schedule (Topological Sort)', 'medium', 'Graphs', 'https://leetcode.com/problems/course-schedule/', 'Build adjacency list, detect cycle using DFS with 3 states (unvisited, visiting, visited).', '[{"question": "Topological sort applies to?", "options": ["Undirected graphs", "DAGs", "Complete graphs", "Trees only"], "correct_option": 1}, {"question": "Cycle in directed graph means?", "options": ["No topological order", "Easy sorting", "DAG property", "Tree property"], "correct_option": 0}, {"question": "Work rate: A does job in 10 days, B in 15 days. Together?", "options": ["5 days", "6 days", "8 days", "9 days"], "correct_option": 1}]', TRUE),
(234, 'Dijkstra''s Shortest Path', 'hard', 'Graphs', 'https://leetcode.com/problems/network-delay-time/', 'Use min-heap priority queue. Relax edges greedily by choosing shortest known distance.', '[{"question": "Dijkstra works with?", "options": ["Negative weights", "Non-negative weights", "All graphs", "Only trees"], "correct_option": 1}, {"question": "Dijkstra uses?", "options": ["Stack", "Queue", "Priority Queue", "Array"], "correct_option": 2}, {"question": "Boat covers 10 km upstream in 2h, downstream in 1h. Current speed?", "options": ["2 km/h", "2.5 km/h", "3 km/h", "3.5 km/h"], "correct_option": 1}]', TRUE),
(235, 'Detect Cycle in Undirected Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/graph-valid-tree/', 'Use Union-Find or DFS with parent tracking to detect back edges.', '[{"question": "Union-Find detects cycles in?", "options": ["O(n\u00b2)", "O(n log n)", "O(n \u03b1(n)) amortized", "O(1)"], "correct_option": 2}, {"question": "A back edge in DFS indicates?", "options": ["Tree edge", "Cycle", "Cross edge", "No cycle"], "correct_option": 1}, {"question": "If salary is 25,000 and increased by 8%, new salary?", "options": ["26,500", "27,000", "27,200", "28,000"], "correct_option": 1}]', TRUE),
(236, 'Valid Anagram', 'easy', 'Strings', 'https://leetcode.com/problems/valid-anagram/', 'Use character frequency count (array or HashMap). Compare counts.', '[{"question": "Anagram has?", "options": ["Same characters different order", "Same order", "Different characters", "Different length"], "correct_option": 0}, {"question": "Frequency count uses?", "options": ["Sorting", "HashMap/Array", "Binary search", "Stack"], "correct_option": 1}, {"question": "Average of first 5 odd numbers?", "options": ["3", "5", "7", "9"], "correct_option": 1}]', TRUE),
(237, 'Longest Substring Without Repeating Characters', 'medium', 'Strings', 'https://leetcode.com/problems/longest-substring-without-repeating-characters/', 'Sliding window with a HashSet. Shrink window from left when duplicate found.', '[{"question": "Sliding window maintains?", "options": ["A range [left, right]", "A fixed window", "Sorted order", "Reversed string"], "correct_option": 0}, {"question": "Sliding window time complexity?", "options": ["O(n\u00b2)", "O(n)", "O(n log n)", "O(1)"], "correct_option": 1}, {"question": "P and Q start a business with 3:5 ratio. Profit 8000, Q''s share?", "options": ["3000", "4000", "5000", "6000"], "correct_option": 2}]', TRUE),
(238, 'Group Anagrams', 'medium', 'Strings', 'https://leetcode.com/problems/group-anagrams/', 'Sort each word as the key. All anagrams have same sorted key. Use HashMap<String, List>.', '[{"question": "Sorting a string of length k takes?", "options": ["O(k)", "O(k log k)", "O(k\u00b2)", "O(1)"], "correct_option": 1}, {"question": "HashMap key for grouping anagrams?", "options": ["Sorted string", "First char", "Length", "Frequency"], "correct_option": 0}, {"question": "Simple interest: P=5000, R=6%, T=3 years. SI=?", "options": ["800", "900", "1000", "1100"], "correct_option": 1}]', TRUE),
(239, 'Minimum Window Substring', 'hard', 'Strings', 'https://leetcode.com/problems/minimum-window-substring/', 'Two-pointer sliding window with frequency maps. Shrink when all chars satisfied.', '[{"question": "Minimum window problem is?", "options": ["Fixed window", "Variable sliding window", "Binary search", "Two-stack"], "correct_option": 1}, {"question": "When do we shrink the window?", "options": ["When window is invalid", "When constraint satisfied", "Always", "At start only"], "correct_option": 1}, {"question": "What is 15% of 240?", "options": ["30", "34", "36", "40"], "correct_option": 2}]', TRUE),
(240, 'Palindrome Check', 'easy', 'Strings', 'https://leetcode.com/problems/valid-palindrome/', 'Two pointers from both ends, skip non-alphanumeric chars, compare char by char.', '[{"question": "Palindrome reads same?", "options": ["Forwards", "Backwards", "Both forwards and backwards", "Only lowercase"], "correct_option": 2}, {"question": "Two-pointer approach for palindrome is?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Ratio 2:3:5, total 200. Largest share?", "options": ["50", "80", "100", "120"], "correct_option": 2}]', TRUE),
(241, 'Two Sum', 'easy', 'Arrays', 'https://leetcode.com/problems/two-sum/', 'Use a hash map to store complement values as you iterate.', '[{"question": "What is the time complexity of linear search?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 2}, {"question": "Which data structure uses LIFO?", "options": ["Queue", "Stack", "Heap", "Tree"], "correct_option": 1}, {"question": "Train moves at 60 km/h for 2 hours. Distance?", "options": ["60 km", "90 km", "120 km", "180 km"], "correct_option": 2}]', TRUE),
(242, 'Best Time to Buy and Sell Stock', 'easy', 'Arrays', 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/', 'Track the minimum price seen so far and compute max profit at each step.', '[{"question": "Array index starts at?", "options": ["0", "1", "-1", "None"], "correct_option": 0}, {"question": "Which sorting is O(n log n) worst case?", "options": ["Bubble", "Selection", "Merge", "Insertion"], "correct_option": 2}, {"question": "A train travels 150 km in 3 hours. Speed?", "options": ["40 km/h", "45 km/h", "50 km/h", "55 km/h"], "correct_option": 2}]', TRUE),
(243, 'Contains Duplicate', 'easy', 'Arrays', 'https://leetcode.com/problems/contains-duplicate/', 'Use a HashSet — if element already exists, return true.', '[{"question": "HashSet uses which data structure internally?", "options": ["Array", "LinkedList", "HashMap", "Tree"], "correct_option": 2}, {"question": "Time complexity of HashSet lookup?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If 3 workers complete a job in 6 days, how many days for 2 workers?", "options": ["7", "8", "9", "10"], "correct_option": 2}]', TRUE),
(244, 'Product of Array Except Self', 'medium', 'Arrays', 'https://leetcode.com/problems/product-of-array-except-self/', 'Use prefix and suffix product arrays to avoid division.', '[{"question": "What does O(1) space mean?", "options": ["Constant space", "No space", "Linear space", "Log space"], "correct_option": 0}, {"question": "Prefix sum is useful for?", "options": ["Range queries", "Sorting", "Searching", "Hashing"], "correct_option": 0}, {"question": "A sum of first 10 natural numbers?", "options": ["45", "50", "55", "60"], "correct_option": 2}]', TRUE),
(245, 'Maximum Subarray (Kadane''s)', 'medium', 'Arrays', 'https://leetcode.com/problems/maximum-subarray/', 'Kadane''s algorithm: extend or restart subarray at each element.', '[{"question": "Kadane''s algorithm finds?", "options": ["Minimum subarray", "Maximum subarray", "Sorted subarray", "Empty subarray"], "correct_option": 1}, {"question": "Dynamic programming optimizes?", "options": ["Space", "Overlapping subproblems", "Sorting", "Recursion only"], "correct_option": 1}, {"question": "Profit if cost=200 and selling=250?", "options": ["25%", "30%", "35%", "40%"], "correct_option": 0}]', TRUE),
(246, 'Reverse Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/reverse-linked-list/', 'Use three pointers: prev, curr, next. Iterate and reverse links.', '[{"question": "Linked list node contains?", "options": ["Data only", "Data and pointer", "Pointer only", "Address only"], "correct_option": 1}, {"question": "Head of linked list points to?", "options": ["Last node", "First node", "Middle node", "Random node"], "correct_option": 1}, {"question": "LCM of 4 and 6?", "options": ["12", "18", "24", "8"], "correct_option": 0}]', TRUE),
(247, 'Merge Two Sorted Lists', 'easy', 'Linked Lists', 'https://leetcode.com/problems/merge-two-sorted-lists/', 'Use a dummy head and compare nodes from both lists iteratively.', '[{"question": "Dummy node technique helps with?", "options": ["Edge cases at head", "Tail insertion", "Middle insertion", "Sorting"], "correct_option": 0}, {"question": "Space complexity of iterative merge?", "options": ["O(1)", "O(n)", "O(log n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "Average of 10, 20, 30?", "options": ["15", "20", "25", "30"], "correct_option": 1}]', TRUE),
(248, 'Detect Cycle in Linked List', 'medium', 'Linked Lists', 'https://leetcode.com/problems/linked-list-cycle/', 'Floyd''s cycle detection: slow and fast pointers. If they meet, cycle exists.', '[{"question": "Floyd''s algorithm uses how many pointers?", "options": ["1", "2", "3", "4"], "correct_option": 1}, {"question": "Cycle detection time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "If x:y = 3:4 and x=12, y=?", "options": ["14", "16", "18", "20"], "correct_option": 1}]', TRUE),
(249, 'Find Middle of Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/middle-of-the-linked-list/', 'Use slow/fast pointer: slow moves 1 step, fast moves 2 steps.', '[{"question": "In a 5-node list, middle is at?", "options": ["Node 2", "Node 3", "Node 4", "Node 5"], "correct_option": 1}, {"question": "Two-pointer technique time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Train covers 200m in 10s. Speed in km/h?", "options": ["60", "70", "72", "80"], "correct_option": 2}]', TRUE),
(250, 'LRU Cache', 'hard', 'Linked Lists', 'https://leetcode.com/problems/lru-cache/', 'Combine HashMap and doubly linked list for O(1) get and put.', '[{"question": "LRU stands for?", "options": ["Least Recently Used", "Last Recently Updated", "Least Random Unit", "Last Reset Unit"], "correct_option": 0}, {"question": "HashMap gives O(1) for?", "options": ["Insert, Delete, Search", "Sort only", "Range queries", "Traversal"], "correct_option": 0}, {"question": "A pipe fills a tank in 4 hours, another in 6 hours. Together?", "options": ["2.4 hours", "2.6 hours", "3 hours", "5 hours"], "correct_option": 0}]', TRUE),
(251, 'Inorder Traversal of BST', 'easy', 'Trees', 'https://leetcode.com/problems/binary-tree-inorder-traversal/', 'Inorder: Left → Root → Right. Yields sorted output for BST.', '[{"question": "Inorder traversal gives BST in?", "options": ["Sorted order", "Reverse order", "Random order", "Level order"], "correct_option": 0}, {"question": "BST search time complexity?", "options": ["O(log n)", "O(n)", "O(1)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If coins doubled daily from 1, on day 10?", "options": ["512", "1024", "512", "256"], "correct_option": 0}]', TRUE),
(252, 'Maximum Depth of Binary Tree', 'easy', 'Trees', 'https://leetcode.com/problems/maximum-depth-of-binary-tree/', 'Recursively return 1 + max(left depth, right depth). Base case: null = 0.', '[{"question": "DFS uses which data structure?", "options": ["Queue", "Stack", "Array", "Heap"], "correct_option": 1}, {"question": "BFS uses which data structure?", "options": ["Stack", "Queue", "Heap", "LinkedList"], "correct_option": 1}, {"question": "35 is what percent of 700?", "options": ["3%", "4%", "5%", "6%"], "correct_option": 2}]', TRUE),
(253, 'Validate Binary Search Tree', 'medium', 'Trees', 'https://leetcode.com/problems/validate-binary-search-tree/', 'Pass min/max bounds to each node recursively. Left < node < Right.', '[{"question": "BST property: left subtree has?", "options": ["Values > root", "Values < root", "Values = root", "Random values"], "correct_option": 1}, {"question": "Which traversal checks BST validity?", "options": ["Inorder", "Preorder", "Postorder", "Level order"], "correct_option": 0}, {"question": "A man earns 15,000/month and saves 20%. Monthly savings?", "options": ["2,500", "3,000", "3,500", "4,000"], "correct_option": 1}]', TRUE),
(254, 'Level Order Traversal', 'medium', 'Trees', 'https://leetcode.com/problems/binary-tree-level-order-traversal/', 'Use a Queue. Process level by level, tracking level boundaries.', '[{"question": "BFS explores nodes?", "options": ["Depth first", "Level by level", "Randomly", "Root only"], "correct_option": 1}, {"question": "Queue is?", "options": ["LIFO", "FIFO", "LILO", "FILO"], "correct_option": 1}, {"question": "A 10% discount on 500?", "options": ["400", "450", "460", "480"], "correct_option": 1}]', TRUE),
(255, 'Lowest Common Ancestor of BST', 'medium', 'Trees', 'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/', 'If both p and q are less than root, go left. If both greater, go right. Else root is LCA.', '[{"question": "LCA of a tree means?", "options": ["Deepest common node", "Shallowest node", "Root always", "Leaf node"], "correct_option": 0}, {"question": "BST LCA time complexity?", "options": ["O(log n)", "O(n)", "O(n\u00b2)", "O(1)"], "correct_option": 0}, {"question": "Speed = Distance/Time. If d=120km, t=2h, speed?", "options": ["50 km/h", "55 km/h", "60 km/h", "65 km/h"], "correct_option": 2}]', TRUE),
(256, 'Climbing Stairs', 'easy', 'Dynamic Programming', 'https://leetcode.com/problems/climbing-stairs/', 'Fibonacci pattern: f(n) = f(n-1) + f(n-2). Use bottom-up DP.', '[{"question": "Memoization stores?", "options": ["Computed results", "Random data", "Sorted arrays", "Only inputs"], "correct_option": 0}, {"question": "Fibonacci relation is?", "options": ["f(n) = f(n-1) + f(n-2)", "f(n) = f(n-1) * 2", "f(n) = n!", "f(n) = 2^n"], "correct_option": 0}, {"question": "Pipes A and B fill tank in 3h and 6h. Together in?", "options": ["1.5h", "2h", "2.5h", "3h"], "correct_option": 1}]', TRUE),
(257, 'Coin Change', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/coin-change/', 'dp[i] = min coins to make amount i. Try each coin at each amount.', '[{"question": "Greedy always works for coin change?", "options": ["Yes", "No, only for canonical coin systems", "Yes, with sorting", "No, never"], "correct_option": 1}, {"question": "DP bottom-up vs top-down: bottom-up uses?", "options": ["Recursion", "Iteration", "Both", "Neither"], "correct_option": 1}, {"question": "HCF of 12 and 18?", "options": ["3", "6", "9", "12"], "correct_option": 1}]', TRUE),
(258, 'Longest Common Subsequence', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/longest-common-subsequence/', '2D DP: if chars match, dp[i][j] = dp[i-1][j-1] + 1, else max of top/left.', '[{"question": "LCS differs from LCS (substring) because?", "options": ["Must be contiguous", "Need not be contiguous", "Same thing", "Sorted only"], "correct_option": 1}, {"question": "LCS time complexity?", "options": ["O(n)", "O(n log n)", "O(nm)", "O(n\u00b2m)"], "correct_option": 2}, {"question": "Simple interest on 1000 at 5% for 2 years?", "options": ["50", "100", "150", "200"], "correct_option": 1}]', TRUE),
(259, '0/1 Knapsack', 'hard', 'Dynamic Programming', 'https://www.geeksforgeeks.org/0-1-knapsack-problem-dp-10/', 'For each item and capacity, choose max of (include item) or (exclude item).', '[{"question": "0/1 Knapsack: each item can be taken?", "options": ["Multiple times", "Exactly once", "Zero or many times", "Never"], "correct_option": 1}, {"question": "Knapsack time complexity?", "options": ["O(n)", "O(n*W)", "O(n\u00b2)", "O(W)"], "correct_option": 1}, {"question": "20% of 80 + 80% of 20 = ?", "options": ["16", "32", "40", "48"], "correct_option": 1}]', TRUE),
(260, 'Word Break', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/word-break/', 'dp[i] = true if s[0..i] can be segmented using wordDict. Check all prefixes.', '[{"question": "Word break is solved by?", "options": ["Greedy", "DP with boolean array", "Binary search", "Sorting"], "correct_option": 1}, {"question": "Backtracking explores?", "options": ["All possibilities", "Only optimal", "Greedy choices", "Random paths"], "correct_option": 0}, {"question": "Compound interest formula involves?", "options": ["Linear growth", "Exponential growth", "Constant growth", "Logarithmic growth"], "correct_option": 1}]', TRUE),
(261, 'Number of Islands (DFS/BFS)', 'medium', 'Graphs', 'https://leetcode.com/problems/number-of-islands/', 'DFS from each unvisited ''1'' cell, mark all connected cells as visited.', '[{"question": "DFS uses which traversal?", "options": ["Level order", "Depth first", "Breadth first", "Random"], "correct_option": 1}, {"question": "Graph edge connects?", "options": ["Two nodes", "Three nodes", "One node", "All nodes"], "correct_option": 0}, {"question": "If 5 machines make 5 items in 5 min, how many machines for 100 items in 100 min?", "options": ["5", "10", "20", "100"], "correct_option": 0}]', TRUE),
(262, 'Clone Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/clone-graph/', 'BFS/DFS with a HashMap to map original nodes to their clones.', '[{"question": "Deep copy vs shallow copy: deep copy?", "options": ["Copies references", "Copies values recursively", "Copies nothing", "Only copies root"], "correct_option": 1}, {"question": "HashMap in graph cloning ensures?", "options": ["No duplicate clones", "Sorted order", "Faster DFS", "Level order"], "correct_option": 0}, {"question": "A number increased by 20% = 120. Original?", "options": ["90", "95", "100", "110"], "correct_option": 2}]', TRUE),
(263, 'Course Schedule (Topological Sort)', 'medium', 'Graphs', 'https://leetcode.com/problems/course-schedule/', 'Build adjacency list, detect cycle using DFS with 3 states (unvisited, visiting, visited).', '[{"question": "Topological sort applies to?", "options": ["Undirected graphs", "DAGs", "Complete graphs", "Trees only"], "correct_option": 1}, {"question": "Cycle in directed graph means?", "options": ["No topological order", "Easy sorting", "DAG property", "Tree property"], "correct_option": 0}, {"question": "Work rate: A does job in 10 days, B in 15 days. Together?", "options": ["5 days", "6 days", "8 days", "9 days"], "correct_option": 1}]', TRUE),
(264, 'Dijkstra''s Shortest Path', 'hard', 'Graphs', 'https://leetcode.com/problems/network-delay-time/', 'Use min-heap priority queue. Relax edges greedily by choosing shortest known distance.', '[{"question": "Dijkstra works with?", "options": ["Negative weights", "Non-negative weights", "All graphs", "Only trees"], "correct_option": 1}, {"question": "Dijkstra uses?", "options": ["Stack", "Queue", "Priority Queue", "Array"], "correct_option": 2}, {"question": "Boat covers 10 km upstream in 2h, downstream in 1h. Current speed?", "options": ["2 km/h", "2.5 km/h", "3 km/h", "3.5 km/h"], "correct_option": 1}]', TRUE),
(265, 'Detect Cycle in Undirected Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/graph-valid-tree/', 'Use Union-Find or DFS with parent tracking to detect back edges.', '[{"question": "Union-Find detects cycles in?", "options": ["O(n\u00b2)", "O(n log n)", "O(n \u03b1(n)) amortized", "O(1)"], "correct_option": 2}, {"question": "A back edge in DFS indicates?", "options": ["Tree edge", "Cycle", "Cross edge", "No cycle"], "correct_option": 1}, {"question": "If salary is 25,000 and increased by 8%, new salary?", "options": ["26,500", "27,000", "27,200", "28,000"], "correct_option": 1}]', TRUE),
(266, 'Valid Anagram', 'easy', 'Strings', 'https://leetcode.com/problems/valid-anagram/', 'Use character frequency count (array or HashMap). Compare counts.', '[{"question": "Anagram has?", "options": ["Same characters different order", "Same order", "Different characters", "Different length"], "correct_option": 0}, {"question": "Frequency count uses?", "options": ["Sorting", "HashMap/Array", "Binary search", "Stack"], "correct_option": 1}, {"question": "Average of first 5 odd numbers?", "options": ["3", "5", "7", "9"], "correct_option": 1}]', TRUE),
(267, 'Longest Substring Without Repeating Characters', 'medium', 'Strings', 'https://leetcode.com/problems/longest-substring-without-repeating-characters/', 'Sliding window with a HashSet. Shrink window from left when duplicate found.', '[{"question": "Sliding window maintains?", "options": ["A range [left, right]", "A fixed window", "Sorted order", "Reversed string"], "correct_option": 0}, {"question": "Sliding window time complexity?", "options": ["O(n\u00b2)", "O(n)", "O(n log n)", "O(1)"], "correct_option": 1}, {"question": "P and Q start a business with 3:5 ratio. Profit 8000, Q''s share?", "options": ["3000", "4000", "5000", "6000"], "correct_option": 2}]', TRUE),
(268, 'Group Anagrams', 'medium', 'Strings', 'https://leetcode.com/problems/group-anagrams/', 'Sort each word as the key. All anagrams have same sorted key. Use HashMap<String, List>.', '[{"question": "Sorting a string of length k takes?", "options": ["O(k)", "O(k log k)", "O(k\u00b2)", "O(1)"], "correct_option": 1}, {"question": "HashMap key for grouping anagrams?", "options": ["Sorted string", "First char", "Length", "Frequency"], "correct_option": 0}, {"question": "Simple interest: P=5000, R=6%, T=3 years. SI=?", "options": ["800", "900", "1000", "1100"], "correct_option": 1}]', TRUE),
(269, 'Minimum Window Substring', 'hard', 'Strings', 'https://leetcode.com/problems/minimum-window-substring/', 'Two-pointer sliding window with frequency maps. Shrink when all chars satisfied.', '[{"question": "Minimum window problem is?", "options": ["Fixed window", "Variable sliding window", "Binary search", "Two-stack"], "correct_option": 1}, {"question": "When do we shrink the window?", "options": ["When window is invalid", "When constraint satisfied", "Always", "At start only"], "correct_option": 1}, {"question": "What is 15% of 240?", "options": ["30", "34", "36", "40"], "correct_option": 2}]', TRUE),
(270, 'Palindrome Check', 'easy', 'Strings', 'https://leetcode.com/problems/valid-palindrome/', 'Two pointers from both ends, skip non-alphanumeric chars, compare char by char.', '[{"question": "Palindrome reads same?", "options": ["Forwards", "Backwards", "Both forwards and backwards", "Only lowercase"], "correct_option": 2}, {"question": "Two-pointer approach for palindrome is?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Ratio 2:3:5, total 200. Largest share?", "options": ["50", "80", "100", "120"], "correct_option": 2}]', TRUE),
(271, 'Two Sum', 'easy', 'Arrays', 'https://leetcode.com/problems/two-sum/', 'Use a hash map to store complement values as you iterate.', '[{"question": "What is the time complexity of linear search?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 2}, {"question": "Which data structure uses LIFO?", "options": ["Queue", "Stack", "Heap", "Tree"], "correct_option": 1}, {"question": "Train moves at 60 km/h for 2 hours. Distance?", "options": ["60 km", "90 km", "120 km", "180 km"], "correct_option": 2}]', TRUE),
(272, 'Best Time to Buy and Sell Stock', 'easy', 'Arrays', 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/', 'Track the minimum price seen so far and compute max profit at each step.', '[{"question": "Array index starts at?", "options": ["0", "1", "-1", "None"], "correct_option": 0}, {"question": "Which sorting is O(n log n) worst case?", "options": ["Bubble", "Selection", "Merge", "Insertion"], "correct_option": 2}, {"question": "A train travels 150 km in 3 hours. Speed?", "options": ["40 km/h", "45 km/h", "50 km/h", "55 km/h"], "correct_option": 2}]', TRUE),
(273, 'Contains Duplicate', 'easy', 'Arrays', 'https://leetcode.com/problems/contains-duplicate/', 'Use a HashSet — if element already exists, return true.', '[{"question": "HashSet uses which data structure internally?", "options": ["Array", "LinkedList", "HashMap", "Tree"], "correct_option": 2}, {"question": "Time complexity of HashSet lookup?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If 3 workers complete a job in 6 days, how many days for 2 workers?", "options": ["7", "8", "9", "10"], "correct_option": 2}]', TRUE),
(274, 'Product of Array Except Self', 'medium', 'Arrays', 'https://leetcode.com/problems/product-of-array-except-self/', 'Use prefix and suffix product arrays to avoid division.', '[{"question": "What does O(1) space mean?", "options": ["Constant space", "No space", "Linear space", "Log space"], "correct_option": 0}, {"question": "Prefix sum is useful for?", "options": ["Range queries", "Sorting", "Searching", "Hashing"], "correct_option": 0}, {"question": "A sum of first 10 natural numbers?", "options": ["45", "50", "55", "60"], "correct_option": 2}]', TRUE),
(275, 'Maximum Subarray (Kadane''s)', 'medium', 'Arrays', 'https://leetcode.com/problems/maximum-subarray/', 'Kadane''s algorithm: extend or restart subarray at each element.', '[{"question": "Kadane''s algorithm finds?", "options": ["Minimum subarray", "Maximum subarray", "Sorted subarray", "Empty subarray"], "correct_option": 1}, {"question": "Dynamic programming optimizes?", "options": ["Space", "Overlapping subproblems", "Sorting", "Recursion only"], "correct_option": 1}, {"question": "Profit if cost=200 and selling=250?", "options": ["25%", "30%", "35%", "40%"], "correct_option": 0}]', TRUE),
(276, 'Reverse Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/reverse-linked-list/', 'Use three pointers: prev, curr, next. Iterate and reverse links.', '[{"question": "Linked list node contains?", "options": ["Data only", "Data and pointer", "Pointer only", "Address only"], "correct_option": 1}, {"question": "Head of linked list points to?", "options": ["Last node", "First node", "Middle node", "Random node"], "correct_option": 1}, {"question": "LCM of 4 and 6?", "options": ["12", "18", "24", "8"], "correct_option": 0}]', TRUE),
(277, 'Merge Two Sorted Lists', 'easy', 'Linked Lists', 'https://leetcode.com/problems/merge-two-sorted-lists/', 'Use a dummy head and compare nodes from both lists iteratively.', '[{"question": "Dummy node technique helps with?", "options": ["Edge cases at head", "Tail insertion", "Middle insertion", "Sorting"], "correct_option": 0}, {"question": "Space complexity of iterative merge?", "options": ["O(1)", "O(n)", "O(log n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "Average of 10, 20, 30?", "options": ["15", "20", "25", "30"], "correct_option": 1}]', TRUE),
(278, 'Detect Cycle in Linked List', 'medium', 'Linked Lists', 'https://leetcode.com/problems/linked-list-cycle/', 'Floyd''s cycle detection: slow and fast pointers. If they meet, cycle exists.', '[{"question": "Floyd''s algorithm uses how many pointers?", "options": ["1", "2", "3", "4"], "correct_option": 1}, {"question": "Cycle detection time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "If x:y = 3:4 and x=12, y=?", "options": ["14", "16", "18", "20"], "correct_option": 1}]', TRUE),
(279, 'Find Middle of Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/middle-of-the-linked-list/', 'Use slow/fast pointer: slow moves 1 step, fast moves 2 steps.', '[{"question": "In a 5-node list, middle is at?", "options": ["Node 2", "Node 3", "Node 4", "Node 5"], "correct_option": 1}, {"question": "Two-pointer technique time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Train covers 200m in 10s. Speed in km/h?", "options": ["60", "70", "72", "80"], "correct_option": 2}]', TRUE),
(280, 'LRU Cache', 'hard', 'Linked Lists', 'https://leetcode.com/problems/lru-cache/', 'Combine HashMap and doubly linked list for O(1) get and put.', '[{"question": "LRU stands for?", "options": ["Least Recently Used", "Last Recently Updated", "Least Random Unit", "Last Reset Unit"], "correct_option": 0}, {"question": "HashMap gives O(1) for?", "options": ["Insert, Delete, Search", "Sort only", "Range queries", "Traversal"], "correct_option": 0}, {"question": "A pipe fills a tank in 4 hours, another in 6 hours. Together?", "options": ["2.4 hours", "2.6 hours", "3 hours", "5 hours"], "correct_option": 0}]', TRUE),
(281, 'Inorder Traversal of BST', 'easy', 'Trees', 'https://leetcode.com/problems/binary-tree-inorder-traversal/', 'Inorder: Left → Root → Right. Yields sorted output for BST.', '[{"question": "Inorder traversal gives BST in?", "options": ["Sorted order", "Reverse order", "Random order", "Level order"], "correct_option": 0}, {"question": "BST search time complexity?", "options": ["O(log n)", "O(n)", "O(1)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If coins doubled daily from 1, on day 10?", "options": ["512", "1024", "512", "256"], "correct_option": 0}]', TRUE),
(282, 'Maximum Depth of Binary Tree', 'easy', 'Trees', 'https://leetcode.com/problems/maximum-depth-of-binary-tree/', 'Recursively return 1 + max(left depth, right depth). Base case: null = 0.', '[{"question": "DFS uses which data structure?", "options": ["Queue", "Stack", "Array", "Heap"], "correct_option": 1}, {"question": "BFS uses which data structure?", "options": ["Stack", "Queue", "Heap", "LinkedList"], "correct_option": 1}, {"question": "35 is what percent of 700?", "options": ["3%", "4%", "5%", "6%"], "correct_option": 2}]', TRUE),
(283, 'Validate Binary Search Tree', 'medium', 'Trees', 'https://leetcode.com/problems/validate-binary-search-tree/', 'Pass min/max bounds to each node recursively. Left < node < Right.', '[{"question": "BST property: left subtree has?", "options": ["Values > root", "Values < root", "Values = root", "Random values"], "correct_option": 1}, {"question": "Which traversal checks BST validity?", "options": ["Inorder", "Preorder", "Postorder", "Level order"], "correct_option": 0}, {"question": "A man earns 15,000/month and saves 20%. Monthly savings?", "options": ["2,500", "3,000", "3,500", "4,000"], "correct_option": 1}]', TRUE),
(284, 'Level Order Traversal', 'medium', 'Trees', 'https://leetcode.com/problems/binary-tree-level-order-traversal/', 'Use a Queue. Process level by level, tracking level boundaries.', '[{"question": "BFS explores nodes?", "options": ["Depth first", "Level by level", "Randomly", "Root only"], "correct_option": 1}, {"question": "Queue is?", "options": ["LIFO", "FIFO", "LILO", "FILO"], "correct_option": 1}, {"question": "A 10% discount on 500?", "options": ["400", "450", "460", "480"], "correct_option": 1}]', TRUE),
(285, 'Lowest Common Ancestor of BST', 'medium', 'Trees', 'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/', 'If both p and q are less than root, go left. If both greater, go right. Else root is LCA.', '[{"question": "LCA of a tree means?", "options": ["Deepest common node", "Shallowest node", "Root always", "Leaf node"], "correct_option": 0}, {"question": "BST LCA time complexity?", "options": ["O(log n)", "O(n)", "O(n\u00b2)", "O(1)"], "correct_option": 0}, {"question": "Speed = Distance/Time. If d=120km, t=2h, speed?", "options": ["50 km/h", "55 km/h", "60 km/h", "65 km/h"], "correct_option": 2}]', TRUE),
(286, 'Climbing Stairs', 'easy', 'Dynamic Programming', 'https://leetcode.com/problems/climbing-stairs/', 'Fibonacci pattern: f(n) = f(n-1) + f(n-2). Use bottom-up DP.', '[{"question": "Memoization stores?", "options": ["Computed results", "Random data", "Sorted arrays", "Only inputs"], "correct_option": 0}, {"question": "Fibonacci relation is?", "options": ["f(n) = f(n-1) + f(n-2)", "f(n) = f(n-1) * 2", "f(n) = n!", "f(n) = 2^n"], "correct_option": 0}, {"question": "Pipes A and B fill tank in 3h and 6h. Together in?", "options": ["1.5h", "2h", "2.5h", "3h"], "correct_option": 1}]', TRUE),
(287, 'Coin Change', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/coin-change/', 'dp[i] = min coins to make amount i. Try each coin at each amount.', '[{"question": "Greedy always works for coin change?", "options": ["Yes", "No, only for canonical coin systems", "Yes, with sorting", "No, never"], "correct_option": 1}, {"question": "DP bottom-up vs top-down: bottom-up uses?", "options": ["Recursion", "Iteration", "Both", "Neither"], "correct_option": 1}, {"question": "HCF of 12 and 18?", "options": ["3", "6", "9", "12"], "correct_option": 1}]', TRUE),
(288, 'Longest Common Subsequence', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/longest-common-subsequence/', '2D DP: if chars match, dp[i][j] = dp[i-1][j-1] + 1, else max of top/left.', '[{"question": "LCS differs from LCS (substring) because?", "options": ["Must be contiguous", "Need not be contiguous", "Same thing", "Sorted only"], "correct_option": 1}, {"question": "LCS time complexity?", "options": ["O(n)", "O(n log n)", "O(nm)", "O(n\u00b2m)"], "correct_option": 2}, {"question": "Simple interest on 1000 at 5% for 2 years?", "options": ["50", "100", "150", "200"], "correct_option": 1}]', TRUE),
(289, '0/1 Knapsack', 'hard', 'Dynamic Programming', 'https://www.geeksforgeeks.org/0-1-knapsack-problem-dp-10/', 'For each item and capacity, choose max of (include item) or (exclude item).', '[{"question": "0/1 Knapsack: each item can be taken?", "options": ["Multiple times", "Exactly once", "Zero or many times", "Never"], "correct_option": 1}, {"question": "Knapsack time complexity?", "options": ["O(n)", "O(n*W)", "O(n\u00b2)", "O(W)"], "correct_option": 1}, {"question": "20% of 80 + 80% of 20 = ?", "options": ["16", "32", "40", "48"], "correct_option": 1}]', TRUE),
(290, 'Word Break', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/word-break/', 'dp[i] = true if s[0..i] can be segmented using wordDict. Check all prefixes.', '[{"question": "Word break is solved by?", "options": ["Greedy", "DP with boolean array", "Binary search", "Sorting"], "correct_option": 1}, {"question": "Backtracking explores?", "options": ["All possibilities", "Only optimal", "Greedy choices", "Random paths"], "correct_option": 0}, {"question": "Compound interest formula involves?", "options": ["Linear growth", "Exponential growth", "Constant growth", "Logarithmic growth"], "correct_option": 1}]', TRUE),
(291, 'Number of Islands (DFS/BFS)', 'medium', 'Graphs', 'https://leetcode.com/problems/number-of-islands/', 'DFS from each unvisited ''1'' cell, mark all connected cells as visited.', '[{"question": "DFS uses which traversal?", "options": ["Level order", "Depth first", "Breadth first", "Random"], "correct_option": 1}, {"question": "Graph edge connects?", "options": ["Two nodes", "Three nodes", "One node", "All nodes"], "correct_option": 0}, {"question": "If 5 machines make 5 items in 5 min, how many machines for 100 items in 100 min?", "options": ["5", "10", "20", "100"], "correct_option": 0}]', TRUE),
(292, 'Clone Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/clone-graph/', 'BFS/DFS with a HashMap to map original nodes to their clones.', '[{"question": "Deep copy vs shallow copy: deep copy?", "options": ["Copies references", "Copies values recursively", "Copies nothing", "Only copies root"], "correct_option": 1}, {"question": "HashMap in graph cloning ensures?", "options": ["No duplicate clones", "Sorted order", "Faster DFS", "Level order"], "correct_option": 0}, {"question": "A number increased by 20% = 120. Original?", "options": ["90", "95", "100", "110"], "correct_option": 2}]', TRUE),
(293, 'Course Schedule (Topological Sort)', 'medium', 'Graphs', 'https://leetcode.com/problems/course-schedule/', 'Build adjacency list, detect cycle using DFS with 3 states (unvisited, visiting, visited).', '[{"question": "Topological sort applies to?", "options": ["Undirected graphs", "DAGs", "Complete graphs", "Trees only"], "correct_option": 1}, {"question": "Cycle in directed graph means?", "options": ["No topological order", "Easy sorting", "DAG property", "Tree property"], "correct_option": 0}, {"question": "Work rate: A does job in 10 days, B in 15 days. Together?", "options": ["5 days", "6 days", "8 days", "9 days"], "correct_option": 1}]', TRUE),
(294, 'Dijkstra''s Shortest Path', 'hard', 'Graphs', 'https://leetcode.com/problems/network-delay-time/', 'Use min-heap priority queue. Relax edges greedily by choosing shortest known distance.', '[{"question": "Dijkstra works with?", "options": ["Negative weights", "Non-negative weights", "All graphs", "Only trees"], "correct_option": 1}, {"question": "Dijkstra uses?", "options": ["Stack", "Queue", "Priority Queue", "Array"], "correct_option": 2}, {"question": "Boat covers 10 km upstream in 2h, downstream in 1h. Current speed?", "options": ["2 km/h", "2.5 km/h", "3 km/h", "3.5 km/h"], "correct_option": 1}]', TRUE),
(295, 'Detect Cycle in Undirected Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/graph-valid-tree/', 'Use Union-Find or DFS with parent tracking to detect back edges.', '[{"question": "Union-Find detects cycles in?", "options": ["O(n\u00b2)", "O(n log n)", "O(n \u03b1(n)) amortized", "O(1)"], "correct_option": 2}, {"question": "A back edge in DFS indicates?", "options": ["Tree edge", "Cycle", "Cross edge", "No cycle"], "correct_option": 1}, {"question": "If salary is 25,000 and increased by 8%, new salary?", "options": ["26,500", "27,000", "27,200", "28,000"], "correct_option": 1}]', TRUE),
(296, 'Valid Anagram', 'easy', 'Strings', 'https://leetcode.com/problems/valid-anagram/', 'Use character frequency count (array or HashMap). Compare counts.', '[{"question": "Anagram has?", "options": ["Same characters different order", "Same order", "Different characters", "Different length"], "correct_option": 0}, {"question": "Frequency count uses?", "options": ["Sorting", "HashMap/Array", "Binary search", "Stack"], "correct_option": 1}, {"question": "Average of first 5 odd numbers?", "options": ["3", "5", "7", "9"], "correct_option": 1}]', TRUE),
(297, 'Longest Substring Without Repeating Characters', 'medium', 'Strings', 'https://leetcode.com/problems/longest-substring-without-repeating-characters/', 'Sliding window with a HashSet. Shrink window from left when duplicate found.', '[{"question": "Sliding window maintains?", "options": ["A range [left, right]", "A fixed window", "Sorted order", "Reversed string"], "correct_option": 0}, {"question": "Sliding window time complexity?", "options": ["O(n\u00b2)", "O(n)", "O(n log n)", "O(1)"], "correct_option": 1}, {"question": "P and Q start a business with 3:5 ratio. Profit 8000, Q''s share?", "options": ["3000", "4000", "5000", "6000"], "correct_option": 2}]', TRUE),
(298, 'Group Anagrams', 'medium', 'Strings', 'https://leetcode.com/problems/group-anagrams/', 'Sort each word as the key. All anagrams have same sorted key. Use HashMap<String, List>.', '[{"question": "Sorting a string of length k takes?", "options": ["O(k)", "O(k log k)", "O(k\u00b2)", "O(1)"], "correct_option": 1}, {"question": "HashMap key for grouping anagrams?", "options": ["Sorted string", "First char", "Length", "Frequency"], "correct_option": 0}, {"question": "Simple interest: P=5000, R=6%, T=3 years. SI=?", "options": ["800", "900", "1000", "1100"], "correct_option": 1}]', TRUE),
(299, 'Minimum Window Substring', 'hard', 'Strings', 'https://leetcode.com/problems/minimum-window-substring/', 'Two-pointer sliding window with frequency maps. Shrink when all chars satisfied.', '[{"question": "Minimum window problem is?", "options": ["Fixed window", "Variable sliding window", "Binary search", "Two-stack"], "correct_option": 1}, {"question": "When do we shrink the window?", "options": ["When window is invalid", "When constraint satisfied", "Always", "At start only"], "correct_option": 1}, {"question": "What is 15% of 240?", "options": ["30", "34", "36", "40"], "correct_option": 2}]', TRUE),
(300, 'Palindrome Check', 'easy', 'Strings', 'https://leetcode.com/problems/valid-palindrome/', 'Two pointers from both ends, skip non-alphanumeric chars, compare char by char.', '[{"question": "Palindrome reads same?", "options": ["Forwards", "Backwards", "Both forwards and backwards", "Only lowercase"], "correct_option": 2}, {"question": "Two-pointer approach for palindrome is?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Ratio 2:3:5, total 200. Largest share?", "options": ["50", "80", "100", "120"], "correct_option": 2}]', TRUE),
(301, 'Two Sum', 'easy', 'Arrays', 'https://leetcode.com/problems/two-sum/', 'Use a hash map to store complement values as you iterate.', '[{"question": "What is the time complexity of linear search?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 2}, {"question": "Which data structure uses LIFO?", "options": ["Queue", "Stack", "Heap", "Tree"], "correct_option": 1}, {"question": "Train moves at 60 km/h for 2 hours. Distance?", "options": ["60 km", "90 km", "120 km", "180 km"], "correct_option": 2}]', TRUE),
(302, 'Best Time to Buy and Sell Stock', 'easy', 'Arrays', 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/', 'Track the minimum price seen so far and compute max profit at each step.', '[{"question": "Array index starts at?", "options": ["0", "1", "-1", "None"], "correct_option": 0}, {"question": "Which sorting is O(n log n) worst case?", "options": ["Bubble", "Selection", "Merge", "Insertion"], "correct_option": 2}, {"question": "A train travels 150 km in 3 hours. Speed?", "options": ["40 km/h", "45 km/h", "50 km/h", "55 km/h"], "correct_option": 2}]', TRUE),
(303, 'Contains Duplicate', 'easy', 'Arrays', 'https://leetcode.com/problems/contains-duplicate/', 'Use a HashSet — if element already exists, return true.', '[{"question": "HashSet uses which data structure internally?", "options": ["Array", "LinkedList", "HashMap", "Tree"], "correct_option": 2}, {"question": "Time complexity of HashSet lookup?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If 3 workers complete a job in 6 days, how many days for 2 workers?", "options": ["7", "8", "9", "10"], "correct_option": 2}]', TRUE),
(304, 'Product of Array Except Self', 'medium', 'Arrays', 'https://leetcode.com/problems/product-of-array-except-self/', 'Use prefix and suffix product arrays to avoid division.', '[{"question": "What does O(1) space mean?", "options": ["Constant space", "No space", "Linear space", "Log space"], "correct_option": 0}, {"question": "Prefix sum is useful for?", "options": ["Range queries", "Sorting", "Searching", "Hashing"], "correct_option": 0}, {"question": "A sum of first 10 natural numbers?", "options": ["45", "50", "55", "60"], "correct_option": 2}]', TRUE),
(305, 'Maximum Subarray (Kadane''s)', 'medium', 'Arrays', 'https://leetcode.com/problems/maximum-subarray/', 'Kadane''s algorithm: extend or restart subarray at each element.', '[{"question": "Kadane''s algorithm finds?", "options": ["Minimum subarray", "Maximum subarray", "Sorted subarray", "Empty subarray"], "correct_option": 1}, {"question": "Dynamic programming optimizes?", "options": ["Space", "Overlapping subproblems", "Sorting", "Recursion only"], "correct_option": 1}, {"question": "Profit if cost=200 and selling=250?", "options": ["25%", "30%", "35%", "40%"], "correct_option": 0}]', TRUE),
(306, 'Reverse Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/reverse-linked-list/', 'Use three pointers: prev, curr, next. Iterate and reverse links.', '[{"question": "Linked list node contains?", "options": ["Data only", "Data and pointer", "Pointer only", "Address only"], "correct_option": 1}, {"question": "Head of linked list points to?", "options": ["Last node", "First node", "Middle node", "Random node"], "correct_option": 1}, {"question": "LCM of 4 and 6?", "options": ["12", "18", "24", "8"], "correct_option": 0}]', TRUE),
(307, 'Merge Two Sorted Lists', 'easy', 'Linked Lists', 'https://leetcode.com/problems/merge-two-sorted-lists/', 'Use a dummy head and compare nodes from both lists iteratively.', '[{"question": "Dummy node technique helps with?", "options": ["Edge cases at head", "Tail insertion", "Middle insertion", "Sorting"], "correct_option": 0}, {"question": "Space complexity of iterative merge?", "options": ["O(1)", "O(n)", "O(log n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "Average of 10, 20, 30?", "options": ["15", "20", "25", "30"], "correct_option": 1}]', TRUE),
(308, 'Detect Cycle in Linked List', 'medium', 'Linked Lists', 'https://leetcode.com/problems/linked-list-cycle/', 'Floyd''s cycle detection: slow and fast pointers. If they meet, cycle exists.', '[{"question": "Floyd''s algorithm uses how many pointers?", "options": ["1", "2", "3", "4"], "correct_option": 1}, {"question": "Cycle detection time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "If x:y = 3:4 and x=12, y=?", "options": ["14", "16", "18", "20"], "correct_option": 1}]', TRUE),
(309, 'Find Middle of Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/middle-of-the-linked-list/', 'Use slow/fast pointer: slow moves 1 step, fast moves 2 steps.', '[{"question": "In a 5-node list, middle is at?", "options": ["Node 2", "Node 3", "Node 4", "Node 5"], "correct_option": 1}, {"question": "Two-pointer technique time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Train covers 200m in 10s. Speed in km/h?", "options": ["60", "70", "72", "80"], "correct_option": 2}]', TRUE),
(310, 'LRU Cache', 'hard', 'Linked Lists', 'https://leetcode.com/problems/lru-cache/', 'Combine HashMap and doubly linked list for O(1) get and put.', '[{"question": "LRU stands for?", "options": ["Least Recently Used", "Last Recently Updated", "Least Random Unit", "Last Reset Unit"], "correct_option": 0}, {"question": "HashMap gives O(1) for?", "options": ["Insert, Delete, Search", "Sort only", "Range queries", "Traversal"], "correct_option": 0}, {"question": "A pipe fills a tank in 4 hours, another in 6 hours. Together?", "options": ["2.4 hours", "2.6 hours", "3 hours", "5 hours"], "correct_option": 0}]', TRUE),
(311, 'Inorder Traversal of BST', 'easy', 'Trees', 'https://leetcode.com/problems/binary-tree-inorder-traversal/', 'Inorder: Left → Root → Right. Yields sorted output for BST.', '[{"question": "Inorder traversal gives BST in?", "options": ["Sorted order", "Reverse order", "Random order", "Level order"], "correct_option": 0}, {"question": "BST search time complexity?", "options": ["O(log n)", "O(n)", "O(1)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If coins doubled daily from 1, on day 10?", "options": ["512", "1024", "512", "256"], "correct_option": 0}]', TRUE),
(312, 'Maximum Depth of Binary Tree', 'easy', 'Trees', 'https://leetcode.com/problems/maximum-depth-of-binary-tree/', 'Recursively return 1 + max(left depth, right depth). Base case: null = 0.', '[{"question": "DFS uses which data structure?", "options": ["Queue", "Stack", "Array", "Heap"], "correct_option": 1}, {"question": "BFS uses which data structure?", "options": ["Stack", "Queue", "Heap", "LinkedList"], "correct_option": 1}, {"question": "35 is what percent of 700?", "options": ["3%", "4%", "5%", "6%"], "correct_option": 2}]', TRUE),
(313, 'Validate Binary Search Tree', 'medium', 'Trees', 'https://leetcode.com/problems/validate-binary-search-tree/', 'Pass min/max bounds to each node recursively. Left < node < Right.', '[{"question": "BST property: left subtree has?", "options": ["Values > root", "Values < root", "Values = root", "Random values"], "correct_option": 1}, {"question": "Which traversal checks BST validity?", "options": ["Inorder", "Preorder", "Postorder", "Level order"], "correct_option": 0}, {"question": "A man earns 15,000/month and saves 20%. Monthly savings?", "options": ["2,500", "3,000", "3,500", "4,000"], "correct_option": 1}]', TRUE),
(314, 'Level Order Traversal', 'medium', 'Trees', 'https://leetcode.com/problems/binary-tree-level-order-traversal/', 'Use a Queue. Process level by level, tracking level boundaries.', '[{"question": "BFS explores nodes?", "options": ["Depth first", "Level by level", "Randomly", "Root only"], "correct_option": 1}, {"question": "Queue is?", "options": ["LIFO", "FIFO", "LILO", "FILO"], "correct_option": 1}, {"question": "A 10% discount on 500?", "options": ["400", "450", "460", "480"], "correct_option": 1}]', TRUE),
(315, 'Lowest Common Ancestor of BST', 'medium', 'Trees', 'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/', 'If both p and q are less than root, go left. If both greater, go right. Else root is LCA.', '[{"question": "LCA of a tree means?", "options": ["Deepest common node", "Shallowest node", "Root always", "Leaf node"], "correct_option": 0}, {"question": "BST LCA time complexity?", "options": ["O(log n)", "O(n)", "O(n\u00b2)", "O(1)"], "correct_option": 0}, {"question": "Speed = Distance/Time. If d=120km, t=2h, speed?", "options": ["50 km/h", "55 km/h", "60 km/h", "65 km/h"], "correct_option": 2}]', TRUE),
(316, 'Climbing Stairs', 'easy', 'Dynamic Programming', 'https://leetcode.com/problems/climbing-stairs/', 'Fibonacci pattern: f(n) = f(n-1) + f(n-2). Use bottom-up DP.', '[{"question": "Memoization stores?", "options": ["Computed results", "Random data", "Sorted arrays", "Only inputs"], "correct_option": 0}, {"question": "Fibonacci relation is?", "options": ["f(n) = f(n-1) + f(n-2)", "f(n) = f(n-1) * 2", "f(n) = n!", "f(n) = 2^n"], "correct_option": 0}, {"question": "Pipes A and B fill tank in 3h and 6h. Together in?", "options": ["1.5h", "2h", "2.5h", "3h"], "correct_option": 1}]', TRUE),
(317, 'Coin Change', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/coin-change/', 'dp[i] = min coins to make amount i. Try each coin at each amount.', '[{"question": "Greedy always works for coin change?", "options": ["Yes", "No, only for canonical coin systems", "Yes, with sorting", "No, never"], "correct_option": 1}, {"question": "DP bottom-up vs top-down: bottom-up uses?", "options": ["Recursion", "Iteration", "Both", "Neither"], "correct_option": 1}, {"question": "HCF of 12 and 18?", "options": ["3", "6", "9", "12"], "correct_option": 1}]', TRUE),
(318, 'Longest Common Subsequence', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/longest-common-subsequence/', '2D DP: if chars match, dp[i][j] = dp[i-1][j-1] + 1, else max of top/left.', '[{"question": "LCS differs from LCS (substring) because?", "options": ["Must be contiguous", "Need not be contiguous", "Same thing", "Sorted only"], "correct_option": 1}, {"question": "LCS time complexity?", "options": ["O(n)", "O(n log n)", "O(nm)", "O(n\u00b2m)"], "correct_option": 2}, {"question": "Simple interest on 1000 at 5% for 2 years?", "options": ["50", "100", "150", "200"], "correct_option": 1}]', TRUE),
(319, '0/1 Knapsack', 'hard', 'Dynamic Programming', 'https://www.geeksforgeeks.org/0-1-knapsack-problem-dp-10/', 'For each item and capacity, choose max of (include item) or (exclude item).', '[{"question": "0/1 Knapsack: each item can be taken?", "options": ["Multiple times", "Exactly once", "Zero or many times", "Never"], "correct_option": 1}, {"question": "Knapsack time complexity?", "options": ["O(n)", "O(n*W)", "O(n\u00b2)", "O(W)"], "correct_option": 1}, {"question": "20% of 80 + 80% of 20 = ?", "options": ["16", "32", "40", "48"], "correct_option": 1}]', TRUE),
(320, 'Word Break', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/word-break/', 'dp[i] = true if s[0..i] can be segmented using wordDict. Check all prefixes.', '[{"question": "Word break is solved by?", "options": ["Greedy", "DP with boolean array", "Binary search", "Sorting"], "correct_option": 1}, {"question": "Backtracking explores?", "options": ["All possibilities", "Only optimal", "Greedy choices", "Random paths"], "correct_option": 0}, {"question": "Compound interest formula involves?", "options": ["Linear growth", "Exponential growth", "Constant growth", "Logarithmic growth"], "correct_option": 1}]', TRUE),
(321, 'Number of Islands (DFS/BFS)', 'medium', 'Graphs', 'https://leetcode.com/problems/number-of-islands/', 'DFS from each unvisited ''1'' cell, mark all connected cells as visited.', '[{"question": "DFS uses which traversal?", "options": ["Level order", "Depth first", "Breadth first", "Random"], "correct_option": 1}, {"question": "Graph edge connects?", "options": ["Two nodes", "Three nodes", "One node", "All nodes"], "correct_option": 0}, {"question": "If 5 machines make 5 items in 5 min, how many machines for 100 items in 100 min?", "options": ["5", "10", "20", "100"], "correct_option": 0}]', TRUE),
(322, 'Clone Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/clone-graph/', 'BFS/DFS with a HashMap to map original nodes to their clones.', '[{"question": "Deep copy vs shallow copy: deep copy?", "options": ["Copies references", "Copies values recursively", "Copies nothing", "Only copies root"], "correct_option": 1}, {"question": "HashMap in graph cloning ensures?", "options": ["No duplicate clones", "Sorted order", "Faster DFS", "Level order"], "correct_option": 0}, {"question": "A number increased by 20% = 120. Original?", "options": ["90", "95", "100", "110"], "correct_option": 2}]', TRUE),
(323, 'Course Schedule (Topological Sort)', 'medium', 'Graphs', 'https://leetcode.com/problems/course-schedule/', 'Build adjacency list, detect cycle using DFS with 3 states (unvisited, visiting, visited).', '[{"question": "Topological sort applies to?", "options": ["Undirected graphs", "DAGs", "Complete graphs", "Trees only"], "correct_option": 1}, {"question": "Cycle in directed graph means?", "options": ["No topological order", "Easy sorting", "DAG property", "Tree property"], "correct_option": 0}, {"question": "Work rate: A does job in 10 days, B in 15 days. Together?", "options": ["5 days", "6 days", "8 days", "9 days"], "correct_option": 1}]', TRUE),
(324, 'Dijkstra''s Shortest Path', 'hard', 'Graphs', 'https://leetcode.com/problems/network-delay-time/', 'Use min-heap priority queue. Relax edges greedily by choosing shortest known distance.', '[{"question": "Dijkstra works with?", "options": ["Negative weights", "Non-negative weights", "All graphs", "Only trees"], "correct_option": 1}, {"question": "Dijkstra uses?", "options": ["Stack", "Queue", "Priority Queue", "Array"], "correct_option": 2}, {"question": "Boat covers 10 km upstream in 2h, downstream in 1h. Current speed?", "options": ["2 km/h", "2.5 km/h", "3 km/h", "3.5 km/h"], "correct_option": 1}]', TRUE),
(325, 'Detect Cycle in Undirected Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/graph-valid-tree/', 'Use Union-Find or DFS with parent tracking to detect back edges.', '[{"question": "Union-Find detects cycles in?", "options": ["O(n\u00b2)", "O(n log n)", "O(n \u03b1(n)) amortized", "O(1)"], "correct_option": 2}, {"question": "A back edge in DFS indicates?", "options": ["Tree edge", "Cycle", "Cross edge", "No cycle"], "correct_option": 1}, {"question": "If salary is 25,000 and increased by 8%, new salary?", "options": ["26,500", "27,000", "27,200", "28,000"], "correct_option": 1}]', TRUE),
(326, 'Valid Anagram', 'easy', 'Strings', 'https://leetcode.com/problems/valid-anagram/', 'Use character frequency count (array or HashMap). Compare counts.', '[{"question": "Anagram has?", "options": ["Same characters different order", "Same order", "Different characters", "Different length"], "correct_option": 0}, {"question": "Frequency count uses?", "options": ["Sorting", "HashMap/Array", "Binary search", "Stack"], "correct_option": 1}, {"question": "Average of first 5 odd numbers?", "options": ["3", "5", "7", "9"], "correct_option": 1}]', TRUE),
(327, 'Longest Substring Without Repeating Characters', 'medium', 'Strings', 'https://leetcode.com/problems/longest-substring-without-repeating-characters/', 'Sliding window with a HashSet. Shrink window from left when duplicate found.', '[{"question": "Sliding window maintains?", "options": ["A range [left, right]", "A fixed window", "Sorted order", "Reversed string"], "correct_option": 0}, {"question": "Sliding window time complexity?", "options": ["O(n\u00b2)", "O(n)", "O(n log n)", "O(1)"], "correct_option": 1}, {"question": "P and Q start a business with 3:5 ratio. Profit 8000, Q''s share?", "options": ["3000", "4000", "5000", "6000"], "correct_option": 2}]', TRUE),
(328, 'Group Anagrams', 'medium', 'Strings', 'https://leetcode.com/problems/group-anagrams/', 'Sort each word as the key. All anagrams have same sorted key. Use HashMap<String, List>.', '[{"question": "Sorting a string of length k takes?", "options": ["O(k)", "O(k log k)", "O(k\u00b2)", "O(1)"], "correct_option": 1}, {"question": "HashMap key for grouping anagrams?", "options": ["Sorted string", "First char", "Length", "Frequency"], "correct_option": 0}, {"question": "Simple interest: P=5000, R=6%, T=3 years. SI=?", "options": ["800", "900", "1000", "1100"], "correct_option": 1}]', TRUE),
(329, 'Minimum Window Substring', 'hard', 'Strings', 'https://leetcode.com/problems/minimum-window-substring/', 'Two-pointer sliding window with frequency maps. Shrink when all chars satisfied.', '[{"question": "Minimum window problem is?", "options": ["Fixed window", "Variable sliding window", "Binary search", "Two-stack"], "correct_option": 1}, {"question": "When do we shrink the window?", "options": ["When window is invalid", "When constraint satisfied", "Always", "At start only"], "correct_option": 1}, {"question": "What is 15% of 240?", "options": ["30", "34", "36", "40"], "correct_option": 2}]', TRUE),
(330, 'Palindrome Check', 'easy', 'Strings', 'https://leetcode.com/problems/valid-palindrome/', 'Two pointers from both ends, skip non-alphanumeric chars, compare char by char.', '[{"question": "Palindrome reads same?", "options": ["Forwards", "Backwards", "Both forwards and backwards", "Only lowercase"], "correct_option": 2}, {"question": "Two-pointer approach for palindrome is?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Ratio 2:3:5, total 200. Largest share?", "options": ["50", "80", "100", "120"], "correct_option": 2}]', TRUE),
(331, 'Two Sum', 'easy', 'Arrays', 'https://leetcode.com/problems/two-sum/', 'Use a hash map to store complement values as you iterate.', '[{"question": "What is the time complexity of linear search?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 2}, {"question": "Which data structure uses LIFO?", "options": ["Queue", "Stack", "Heap", "Tree"], "correct_option": 1}, {"question": "Train moves at 60 km/h for 2 hours. Distance?", "options": ["60 km", "90 km", "120 km", "180 km"], "correct_option": 2}]', TRUE),
(332, 'Best Time to Buy and Sell Stock', 'easy', 'Arrays', 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/', 'Track the minimum price seen so far and compute max profit at each step.', '[{"question": "Array index starts at?", "options": ["0", "1", "-1", "None"], "correct_option": 0}, {"question": "Which sorting is O(n log n) worst case?", "options": ["Bubble", "Selection", "Merge", "Insertion"], "correct_option": 2}, {"question": "A train travels 150 km in 3 hours. Speed?", "options": ["40 km/h", "45 km/h", "50 km/h", "55 km/h"], "correct_option": 2}]', TRUE),
(333, 'Contains Duplicate', 'easy', 'Arrays', 'https://leetcode.com/problems/contains-duplicate/', 'Use a HashSet — if element already exists, return true.', '[{"question": "HashSet uses which data structure internally?", "options": ["Array", "LinkedList", "HashMap", "Tree"], "correct_option": 2}, {"question": "Time complexity of HashSet lookup?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If 3 workers complete a job in 6 days, how many days for 2 workers?", "options": ["7", "8", "9", "10"], "correct_option": 2}]', TRUE),
(334, 'Product of Array Except Self', 'medium', 'Arrays', 'https://leetcode.com/problems/product-of-array-except-self/', 'Use prefix and suffix product arrays to avoid division.', '[{"question": "What does O(1) space mean?", "options": ["Constant space", "No space", "Linear space", "Log space"], "correct_option": 0}, {"question": "Prefix sum is useful for?", "options": ["Range queries", "Sorting", "Searching", "Hashing"], "correct_option": 0}, {"question": "A sum of first 10 natural numbers?", "options": ["45", "50", "55", "60"], "correct_option": 2}]', TRUE),
(335, 'Maximum Subarray (Kadane''s)', 'medium', 'Arrays', 'https://leetcode.com/problems/maximum-subarray/', 'Kadane''s algorithm: extend or restart subarray at each element.', '[{"question": "Kadane''s algorithm finds?", "options": ["Minimum subarray", "Maximum subarray", "Sorted subarray", "Empty subarray"], "correct_option": 1}, {"question": "Dynamic programming optimizes?", "options": ["Space", "Overlapping subproblems", "Sorting", "Recursion only"], "correct_option": 1}, {"question": "Profit if cost=200 and selling=250?", "options": ["25%", "30%", "35%", "40%"], "correct_option": 0}]', TRUE),
(336, 'Reverse Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/reverse-linked-list/', 'Use three pointers: prev, curr, next. Iterate and reverse links.', '[{"question": "Linked list node contains?", "options": ["Data only", "Data and pointer", "Pointer only", "Address only"], "correct_option": 1}, {"question": "Head of linked list points to?", "options": ["Last node", "First node", "Middle node", "Random node"], "correct_option": 1}, {"question": "LCM of 4 and 6?", "options": ["12", "18", "24", "8"], "correct_option": 0}]', TRUE),
(337, 'Merge Two Sorted Lists', 'easy', 'Linked Lists', 'https://leetcode.com/problems/merge-two-sorted-lists/', 'Use a dummy head and compare nodes from both lists iteratively.', '[{"question": "Dummy node technique helps with?", "options": ["Edge cases at head", "Tail insertion", "Middle insertion", "Sorting"], "correct_option": 0}, {"question": "Space complexity of iterative merge?", "options": ["O(1)", "O(n)", "O(log n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "Average of 10, 20, 30?", "options": ["15", "20", "25", "30"], "correct_option": 1}]', TRUE),
(338, 'Detect Cycle in Linked List', 'medium', 'Linked Lists', 'https://leetcode.com/problems/linked-list-cycle/', 'Floyd''s cycle detection: slow and fast pointers. If they meet, cycle exists.', '[{"question": "Floyd''s algorithm uses how many pointers?", "options": ["1", "2", "3", "4"], "correct_option": 1}, {"question": "Cycle detection time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "If x:y = 3:4 and x=12, y=?", "options": ["14", "16", "18", "20"], "correct_option": 1}]', TRUE),
(339, 'Find Middle of Linked List', 'easy', 'Linked Lists', 'https://leetcode.com/problems/middle-of-the-linked-list/', 'Use slow/fast pointer: slow moves 1 step, fast moves 2 steps.', '[{"question": "In a 5-node list, middle is at?", "options": ["Node 2", "Node 3", "Node 4", "Node 5"], "correct_option": 1}, {"question": "Two-pointer technique time complexity?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Train covers 200m in 10s. Speed in km/h?", "options": ["60", "70", "72", "80"], "correct_option": 2}]', TRUE),
(340, 'LRU Cache', 'hard', 'Linked Lists', 'https://leetcode.com/problems/lru-cache/', 'Combine HashMap and doubly linked list for O(1) get and put.', '[{"question": "LRU stands for?", "options": ["Least Recently Used", "Last Recently Updated", "Least Random Unit", "Last Reset Unit"], "correct_option": 0}, {"question": "HashMap gives O(1) for?", "options": ["Insert, Delete, Search", "Sort only", "Range queries", "Traversal"], "correct_option": 0}, {"question": "A pipe fills a tank in 4 hours, another in 6 hours. Together?", "options": ["2.4 hours", "2.6 hours", "3 hours", "5 hours"], "correct_option": 0}]', TRUE),
(341, 'Inorder Traversal of BST', 'easy', 'Trees', 'https://leetcode.com/problems/binary-tree-inorder-traversal/', 'Inorder: Left → Root → Right. Yields sorted output for BST.', '[{"question": "Inorder traversal gives BST in?", "options": ["Sorted order", "Reverse order", "Random order", "Level order"], "correct_option": 0}, {"question": "BST search time complexity?", "options": ["O(log n)", "O(n)", "O(1)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If coins doubled daily from 1, on day 10?", "options": ["512", "1024", "512", "256"], "correct_option": 0}]', TRUE),
(342, 'Maximum Depth of Binary Tree', 'easy', 'Trees', 'https://leetcode.com/problems/maximum-depth-of-binary-tree/', 'Recursively return 1 + max(left depth, right depth). Base case: null = 0.', '[{"question": "DFS uses which data structure?", "options": ["Queue", "Stack", "Array", "Heap"], "correct_option": 1}, {"question": "BFS uses which data structure?", "options": ["Stack", "Queue", "Heap", "LinkedList"], "correct_option": 1}, {"question": "35 is what percent of 700?", "options": ["3%", "4%", "5%", "6%"], "correct_option": 2}]', TRUE),
(343, 'Validate Binary Search Tree', 'medium', 'Trees', 'https://leetcode.com/problems/validate-binary-search-tree/', 'Pass min/max bounds to each node recursively. Left < node < Right.', '[{"question": "BST property: left subtree has?", "options": ["Values > root", "Values < root", "Values = root", "Random values"], "correct_option": 1}, {"question": "Which traversal checks BST validity?", "options": ["Inorder", "Preorder", "Postorder", "Level order"], "correct_option": 0}, {"question": "A man earns 15,000/month and saves 20%. Monthly savings?", "options": ["2,500", "3,000", "3,500", "4,000"], "correct_option": 1}]', TRUE),
(344, 'Level Order Traversal', 'medium', 'Trees', 'https://leetcode.com/problems/binary-tree-level-order-traversal/', 'Use a Queue. Process level by level, tracking level boundaries.', '[{"question": "BFS explores nodes?", "options": ["Depth first", "Level by level", "Randomly", "Root only"], "correct_option": 1}, {"question": "Queue is?", "options": ["LIFO", "FIFO", "LILO", "FILO"], "correct_option": 1}, {"question": "A 10% discount on 500?", "options": ["400", "450", "460", "480"], "correct_option": 1}]', TRUE),
(345, 'Lowest Common Ancestor of BST', 'medium', 'Trees', 'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/', 'If both p and q are less than root, go left. If both greater, go right. Else root is LCA.', '[{"question": "LCA of a tree means?", "options": ["Deepest common node", "Shallowest node", "Root always", "Leaf node"], "correct_option": 0}, {"question": "BST LCA time complexity?", "options": ["O(log n)", "O(n)", "O(n\u00b2)", "O(1)"], "correct_option": 0}, {"question": "Speed = Distance/Time. If d=120km, t=2h, speed?", "options": ["50 km/h", "55 km/h", "60 km/h", "65 km/h"], "correct_option": 2}]', TRUE),
(346, 'Climbing Stairs', 'easy', 'Dynamic Programming', 'https://leetcode.com/problems/climbing-stairs/', 'Fibonacci pattern: f(n) = f(n-1) + f(n-2). Use bottom-up DP.', '[{"question": "Memoization stores?", "options": ["Computed results", "Random data", "Sorted arrays", "Only inputs"], "correct_option": 0}, {"question": "Fibonacci relation is?", "options": ["f(n) = f(n-1) + f(n-2)", "f(n) = f(n-1) * 2", "f(n) = n!", "f(n) = 2^n"], "correct_option": 0}, {"question": "Pipes A and B fill tank in 3h and 6h. Together in?", "options": ["1.5h", "2h", "2.5h", "3h"], "correct_option": 1}]', TRUE),
(347, 'Coin Change', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/coin-change/', 'dp[i] = min coins to make amount i. Try each coin at each amount.', '[{"question": "Greedy always works for coin change?", "options": ["Yes", "No, only for canonical coin systems", "Yes, with sorting", "No, never"], "correct_option": 1}, {"question": "DP bottom-up vs top-down: bottom-up uses?", "options": ["Recursion", "Iteration", "Both", "Neither"], "correct_option": 1}, {"question": "HCF of 12 and 18?", "options": ["3", "6", "9", "12"], "correct_option": 1}]', TRUE),
(348, 'Longest Common Subsequence', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/longest-common-subsequence/', '2D DP: if chars match, dp[i][j] = dp[i-1][j-1] + 1, else max of top/left.', '[{"question": "LCS differs from LCS (substring) because?", "options": ["Must be contiguous", "Need not be contiguous", "Same thing", "Sorted only"], "correct_option": 1}, {"question": "LCS time complexity?", "options": ["O(n)", "O(n log n)", "O(nm)", "O(n\u00b2m)"], "correct_option": 2}, {"question": "Simple interest on 1000 at 5% for 2 years?", "options": ["50", "100", "150", "200"], "correct_option": 1}]', TRUE),
(349, '0/1 Knapsack', 'hard', 'Dynamic Programming', 'https://www.geeksforgeeks.org/0-1-knapsack-problem-dp-10/', 'For each item and capacity, choose max of (include item) or (exclude item).', '[{"question": "0/1 Knapsack: each item can be taken?", "options": ["Multiple times", "Exactly once", "Zero or many times", "Never"], "correct_option": 1}, {"question": "Knapsack time complexity?", "options": ["O(n)", "O(n*W)", "O(n\u00b2)", "O(W)"], "correct_option": 1}, {"question": "20% of 80 + 80% of 20 = ?", "options": ["16", "32", "40", "48"], "correct_option": 1}]', TRUE),
(350, 'Word Break', 'medium', 'Dynamic Programming', 'https://leetcode.com/problems/word-break/', 'dp[i] = true if s[0..i] can be segmented using wordDict. Check all prefixes.', '[{"question": "Word break is solved by?", "options": ["Greedy", "DP with boolean array", "Binary search", "Sorting"], "correct_option": 1}, {"question": "Backtracking explores?", "options": ["All possibilities", "Only optimal", "Greedy choices", "Random paths"], "correct_option": 0}, {"question": "Compound interest formula involves?", "options": ["Linear growth", "Exponential growth", "Constant growth", "Logarithmic growth"], "correct_option": 1}]', TRUE),
(351, 'Number of Islands (DFS/BFS)', 'medium', 'Graphs', 'https://leetcode.com/problems/number-of-islands/', 'DFS from each unvisited ''1'' cell, mark all connected cells as visited.', '[{"question": "DFS uses which traversal?", "options": ["Level order", "Depth first", "Breadth first", "Random"], "correct_option": 1}, {"question": "Graph edge connects?", "options": ["Two nodes", "Three nodes", "One node", "All nodes"], "correct_option": 0}, {"question": "If 5 machines make 5 items in 5 min, how many machines for 100 items in 100 min?", "options": ["5", "10", "20", "100"], "correct_option": 0}]', TRUE),
(352, 'Clone Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/clone-graph/', 'BFS/DFS with a HashMap to map original nodes to their clones.', '[{"question": "Deep copy vs shallow copy: deep copy?", "options": ["Copies references", "Copies values recursively", "Copies nothing", "Only copies root"], "correct_option": 1}, {"question": "HashMap in graph cloning ensures?", "options": ["No duplicate clones", "Sorted order", "Faster DFS", "Level order"], "correct_option": 0}, {"question": "A number increased by 20% = 120. Original?", "options": ["90", "95", "100", "110"], "correct_option": 2}]', TRUE),
(353, 'Course Schedule (Topological Sort)', 'medium', 'Graphs', 'https://leetcode.com/problems/course-schedule/', 'Build adjacency list, detect cycle using DFS with 3 states (unvisited, visiting, visited).', '[{"question": "Topological sort applies to?", "options": ["Undirected graphs", "DAGs", "Complete graphs", "Trees only"], "correct_option": 1}, {"question": "Cycle in directed graph means?", "options": ["No topological order", "Easy sorting", "DAG property", "Tree property"], "correct_option": 0}, {"question": "Work rate: A does job in 10 days, B in 15 days. Together?", "options": ["5 days", "6 days", "8 days", "9 days"], "correct_option": 1}]', TRUE),
(354, 'Dijkstra''s Shortest Path', 'hard', 'Graphs', 'https://leetcode.com/problems/network-delay-time/', 'Use min-heap priority queue. Relax edges greedily by choosing shortest known distance.', '[{"question": "Dijkstra works with?", "options": ["Negative weights", "Non-negative weights", "All graphs", "Only trees"], "correct_option": 1}, {"question": "Dijkstra uses?", "options": ["Stack", "Queue", "Priority Queue", "Array"], "correct_option": 2}, {"question": "Boat covers 10 km upstream in 2h, downstream in 1h. Current speed?", "options": ["2 km/h", "2.5 km/h", "3 km/h", "3.5 km/h"], "correct_option": 1}]', TRUE),
(355, 'Detect Cycle in Undirected Graph', 'medium', 'Graphs', 'https://leetcode.com/problems/graph-valid-tree/', 'Use Union-Find or DFS with parent tracking to detect back edges.', '[{"question": "Union-Find detects cycles in?", "options": ["O(n\u00b2)", "O(n log n)", "O(n \u03b1(n)) amortized", "O(1)"], "correct_option": 2}, {"question": "A back edge in DFS indicates?", "options": ["Tree edge", "Cycle", "Cross edge", "No cycle"], "correct_option": 1}, {"question": "If salary is 25,000 and increased by 8%, new salary?", "options": ["26,500", "27,000", "27,200", "28,000"], "correct_option": 1}]', TRUE),
(356, 'Valid Anagram', 'easy', 'Strings', 'https://leetcode.com/problems/valid-anagram/', 'Use character frequency count (array or HashMap). Compare counts.', '[{"question": "Anagram has?", "options": ["Same characters different order", "Same order", "Different characters", "Different length"], "correct_option": 0}, {"question": "Frequency count uses?", "options": ["Sorting", "HashMap/Array", "Binary search", "Stack"], "correct_option": 1}, {"question": "Average of first 5 odd numbers?", "options": ["3", "5", "7", "9"], "correct_option": 1}]', TRUE),
(357, 'Longest Substring Without Repeating Characters', 'medium', 'Strings', 'https://leetcode.com/problems/longest-substring-without-repeating-characters/', 'Sliding window with a HashSet. Shrink window from left when duplicate found.', '[{"question": "Sliding window maintains?", "options": ["A range [left, right]", "A fixed window", "Sorted order", "Reversed string"], "correct_option": 0}, {"question": "Sliding window time complexity?", "options": ["O(n\u00b2)", "O(n)", "O(n log n)", "O(1)"], "correct_option": 1}, {"question": "P and Q start a business with 3:5 ratio. Profit 8000, Q''s share?", "options": ["3000", "4000", "5000", "6000"], "correct_option": 2}]', TRUE),
(358, 'Group Anagrams', 'medium', 'Strings', 'https://leetcode.com/problems/group-anagrams/', 'Sort each word as the key. All anagrams have same sorted key. Use HashMap<String, List>.', '[{"question": "Sorting a string of length k takes?", "options": ["O(k)", "O(k log k)", "O(k\u00b2)", "O(1)"], "correct_option": 1}, {"question": "HashMap key for grouping anagrams?", "options": ["Sorted string", "First char", "Length", "Frequency"], "correct_option": 0}, {"question": "Simple interest: P=5000, R=6%, T=3 years. SI=?", "options": ["800", "900", "1000", "1100"], "correct_option": 1}]', TRUE),
(359, 'Minimum Window Substring', 'hard', 'Strings', 'https://leetcode.com/problems/minimum-window-substring/', 'Two-pointer sliding window with frequency maps. Shrink when all chars satisfied.', '[{"question": "Minimum window problem is?", "options": ["Fixed window", "Variable sliding window", "Binary search", "Two-stack"], "correct_option": 1}, {"question": "When do we shrink the window?", "options": ["When window is invalid", "When constraint satisfied", "Always", "At start only"], "correct_option": 1}, {"question": "What is 15% of 240?", "options": ["30", "34", "36", "40"], "correct_option": 2}]', TRUE),
(360, 'Palindrome Check', 'easy', 'Strings', 'https://leetcode.com/problems/valid-palindrome/', 'Two pointers from both ends, skip non-alphanumeric chars, compare char by char.', '[{"question": "Palindrome reads same?", "options": ["Forwards", "Backwards", "Both forwards and backwards", "Only lowercase"], "correct_option": 2}, {"question": "Two-pointer approach for palindrome is?", "options": ["O(n)", "O(n\u00b2)", "O(log n)", "O(1)"], "correct_option": 0}, {"question": "Ratio 2:3:5, total 200. Largest share?", "options": ["50", "80", "100", "120"], "correct_option": 2}]', TRUE),
(361, 'Two Sum', 'easy', 'Arrays', 'https://leetcode.com/problems/two-sum/', 'Use a hash map to store complement values as you iterate.', '[{"question": "What is the time complexity of linear search?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 2}, {"question": "Which data structure uses LIFO?", "options": ["Queue", "Stack", "Heap", "Tree"], "correct_option": 1}, {"question": "Train moves at 60 km/h for 2 hours. Distance?", "options": ["60 km", "90 km", "120 km", "180 km"], "correct_option": 2}]', TRUE),
(362, 'Best Time to Buy and Sell Stock', 'easy', 'Arrays', 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/', 'Track the minimum price seen so far and compute max profit at each step.', '[{"question": "Array index starts at?", "options": ["0", "1", "-1", "None"], "correct_option": 0}, {"question": "Which sorting is O(n log n) worst case?", "options": ["Bubble", "Selection", "Merge", "Insertion"], "correct_option": 2}, {"question": "A train travels 150 km in 3 hours. Speed?", "options": ["40 km/h", "45 km/h", "50 km/h", "55 km/h"], "correct_option": 2}]', TRUE),
(363, 'Contains Duplicate', 'easy', 'Arrays', 'https://leetcode.com/problems/contains-duplicate/', 'Use a HashSet — if element already exists, return true.', '[{"question": "HashSet uses which data structure internally?", "options": ["Array", "LinkedList", "HashMap", "Tree"], "correct_option": 2}, {"question": "Time complexity of HashSet lookup?", "options": ["O(1)", "O(log n)", "O(n)", "O(n\u00b2)"], "correct_option": 0}, {"question": "If 3 workers complete a job in 6 days, how many days for 2 workers?", "options": ["7", "8", "9", "10"], "correct_option": 2}]', TRUE),
(364, 'Product of Array Except Self', 'medium', 'Arrays', 'https://leetcode.com/problems/product-of-array-except-self/', 'Use prefix and suffix product arrays to avoid division.', '[{"question": "What does O(1) space mean?", "options": ["Constant space", "No space", "Linear space", "Log space"], "correct_option": 0}, {"question": "Prefix sum is useful for?", "options": ["Range queries", "Sorting", "Searching", "Hashing"], "correct_option": 0}, {"question": "A sum of first 10 natural numbers?", "options": ["45", "50", "55", "60"], "correct_option": 2}]', TRUE),
(365, 'Maximum Subarray (Kadane''s)', 'medium', 'Arrays', 'https://leetcode.com/problems/maximum-subarray/', 'Kadane''s algorithm: extend or restart subarray at each element.', '[{"question": "Kadane''s algorithm finds?", "options": ["Minimum subarray", "Maximum subarray", "Sorted subarray", "Empty subarray"], "correct_option": 1}, {"question": "Dynamic programming optimizes?", "options": ["Space", "Overlapping subproblems", "Sorting", "Recursion only"], "correct_option": 1}, {"question": "Profit if cost=200 and selling=250?", "options": ["25%", "30%", "35%", "40%"], "correct_option": 0}]', TRUE)
ON CONFLICT (day_of_year) DO UPDATE SET
  dsa_title = EXCLUDED.dsa_title,
  dsa_difficulty = EXCLUDED.dsa_difficulty,
  dsa_topic = EXCLUDED.dsa_topic,
  dsa_external_link = EXCLUDED.dsa_external_link,
  dsa_hint = EXCLUDED.dsa_hint,
  aptitude_questions = EXCLUDED.aptitude_questions;

SELECT COUNT(*) AS apti_dsa_seeded FROM apti_dsa_daily_bank;-- ============================================================
-- PSGMX SQL — FILE: 05_seed_24MX_companies.sql
-- Seed Placement Logs for batch 24MX
-- ============================================================

DO $$
DECLARE
  new_company_id UUID;
  admin_user_id UUID;
BEGIN
  -- Use the first superadmin or placement_rep as creator
  SELECT id INTO admin_user_id FROM users WHERE role = 'hod' OR app_role = 'placement_rep' LIMIT 1;
  IF admin_user_id IS NULL THEN
    -- Fallback to any user if none found
    SELECT id INTO admin_user_id FROM users LIMIT 1;
  END IF;

  -- Insert Caterpillar Hackathon
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Caterpillar Hackathon',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    '16.3 LPA',
    'CGPA: 7.5+',
    '[{"name": "Selection Process", "description": "3 (MCQ prelims, Hackathon, F2F interview)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert PhonePe
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'PhonePe',
    CURRENT_DATE,
    ARRAY['SE Testing'],
    '23 LPA',
    '-',
    '[{"name": "Selection Process", "description": "2 (Online screening/Aptitude, Technical interview)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Societe Generale
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Societe Generale',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    '12 LPA',
    'minimum 70% across 10th, 12th, UG, PG without any backlogs',
    '[{"name": "Selection Process", "description": "2 (Aptitude+coding, Technical Interview)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Thorogood Associates Ltd, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Thorogood Associates Ltd, Bangalore',
    CURRENT_DATE,
    ARRAY['Data and AI Consultant'],
    '15 LPA',
    '-',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert The MathCompany - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'The MathCompany - Bangalore',
    CURRENT_DATE,
    ARRAY['Trainee Analyst'],
    '5.5 LPA',
    'minimum 65% across 10th, 12th, UG, PG',
    '[{"name": "Selection Process", "description": "4 (Aptitude, Communication test, Technical interview, Fitment Interview)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert EPAM Systems India Private Limited - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'EPAM Systems India Private Limited - Bangalore',
    CURRENT_DATE,
    ARRAY['FTE'],
    '8.48 LPA',
    'Minimum 70% in graduation, minimum 60% in 10th and 12th, without any backlogs. No gap between 10th & 12th, maximum 1-year gap between 12th and graduation',
    '[{"name": "Selection Process", "description": "5 (MCQ & coding, GD, Technical interview, Managerial interview, HR interview)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert FoodHub Software Solutions India Pvt Lts - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'FoodHub Software Solutions India Pvt Lts - Chennai',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    '13 LPA',
    'GitHub profile with open source contribution + 2 year Bond',
    '[{"name": "Selection Process", "description": "3(OA, Technical interview, HR interview)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Mobicip Technologies Pvt Ltd - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Mobicip Technologies Pvt Ltd - Bangalore',
    CURRENT_DATE,
    ARRAY['Developer'],
    'Intern Stipend: 15TPM, FTE: 8 LPA',
    '-',
    '[{"name": "Selection Process", "description": "3 (OA, Technical Interview, HR)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert STGI Technologies consulting - Chandigarh
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'STGI Technologies consulting - Chandigarh',
    CURRENT_DATE,
    ARRAY['-'],
    '8 LPA',
    'UG & PG CGPA: 8.5+',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert IBM
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'IBM',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    '12 LPA',
    'CGPA: 7.0+',
    '[{"name": "Selection Process", "description": "3 (OA, Technical Interview, HR interview)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert IBM India Pvt Ltd - Bangalore CIO
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'IBM India Pvt Ltd - Bangalore CIO',
    CURRENT_DATE,
    ARRAY['Software Developer'],
    '9 LPA',
    'CGPA: 7.0+',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Jungroo AI labs
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Jungroo AI labs',
    CURRENT_DATE,
    ARRAY['Software Developer'],
    '5.4 LPA',
    'No active backlogs',
    '[{"name": "Selection Process", "description": "3(OOPS, DSA, Interview)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Deloitte Consulting Pvt Ltd USI Hyderabad
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Deloitte Consulting Pvt Ltd USI Hyderabad',
    CURRENT_DATE,
    ARRAY['Analyst'],
    '8 LPA',
    'CGPA: 6.5+',
    '[{"name": "Selection Process", "description": "2(OA, virtual interview)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Deloitte Consulting Pvt Ltd India Hyderabad
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Deloitte Consulting Pvt Ltd India Hyderabad',
    CURRENT_DATE,
    ARRAY['Analyst-Technology & Transformation - EAD - ADMM'],
    '8 LPA',
    'CGPA: 6.5+',
    '[{"name": "Selection Process", "description": "3(OA, GD, Interview)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Commvault
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Commvault',
    CURRENT_DATE,
    ARRAY['SDE & SDET'],
    '33 LPA',
    '-',
    '[{"name": "Selection Process", "description": "3(OA+coding, interview)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert PSIOG digital
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'PSIOG digital',
    CURRENT_DATE,
    ARRAY['Developer (grad, Honours, Super Honours)'],
    '(4.7, 6.2, 8.2) LPA',
    'CGPA: 7.0+, 27 months',
    '[{"name": "Selection Process", "description": "2(OA, Interview)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert ZOHO Corporation
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'ZOHO Corporation',
    CURRENT_DATE,
    ARRAY['Software Developer'],
    '(5.6, 7, 8.4) LPA',
    '-',
    '[{"name": "Selection Process", "description": "4(Written test, l"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert SAP Labs India Private Limited - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'SAP Labs India Private Limited - Bangalore',
    CURRENT_DATE,
    ARRAY['Developer Associate'],
    '26 LPA',
    'Minimum 70% in 10th, 12th, ug, pg',
    '[{"name": "Selection Process", "description": "2 (OA, Interview)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert American Megatrends India Private Limited - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'American Megatrends India Private Limited - Chennai',
    CURRENT_DATE,
    ARRAY['System Software Engineer - Trainee'],
    '6 LPA',
    'No standing arrears',
    '[{"name": "Selection Process", "description": "Technical test basic, Technical test advance, adavnce technical interview 1, technical interview 2, hr interview"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert LTIMindtree Limited - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'LTIMindtree Limited - Bangalore',
    CURRENT_DATE,
    ARRAY['Graduate Engineering Trainee'],
    '4 LPA',
    '60% in 10th, 12th, ug, pg. Not more than 2 year academic gap allowed',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Accenture - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Accenture - Bangalore',
    CURRENT_DATE,
    ARRAY['None'],
    '4.5 LPA, 6.5 LPA, 10 LPA',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Infosys Limited - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Infosys Limited - Bangalore',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "Coding Round ,Technical Interview"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Walmart Global Tech India - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Walmart Global Tech India - Chennai',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Palo Alto Networks - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Palo Alto Networks - Bangalore',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Bounteous x Accolite - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Bounteous x Accolite - Bangalore',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Celeredge Inc
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Celeredge Inc',
    CURRENT_DATE,
    ARRAY['Engineer'],
    'Intern Stipend: 3-4 LPA, FTE: 10 - 12 LPA',
    '-',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Tata Consultancy Services, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Tata Consultancy Services, Chennai',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    'Prime, Digital, Ninja (11.59, 7.39, 3.62) LPA',
    '60 % in 10th, 12th, ug, pg. No standing backlogs',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Oracle OFSS
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Oracle OFSS',
    CURRENT_DATE,
    ARRAY['Associate Applications Developer'],
    '21-22 LPA',
    '-',
    '[{"name": "Selection Process", "description": "3 (OA, Interview, HR)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Autodesk India Pvt Ltd - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Autodesk India Pvt Ltd - Bangalore',
    CURRENT_DATE,
    ARRAY['Software Development Engineer, Software QA Engineer'],
    'Not Disclosed',
    '-',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Ramco Systems - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Ramco Systems - Chennai',
    CURRENT_DATE,
    ARRAY['None'],
    'Intern Stipend: 18 TPM, FTE: 8-11 LPA',
    'None',
    '[{"name": "Selection Process", "description": "5 (OA, Technical Assessment, Technical interview 1, Technical interview 2, HR)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Amazon Development Centre Pvt Ltd - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Amazon Development Centre Pvt Ltd - Bangalore',
    CURRENT_DATE,
    ARRAY['None'],
    'Intern Stipend: 1.1 LPM, FTE: 30 LPA',
    'None',
    '[{"name": "Selection Process", "description": "3 (OA, Technical Interview, HR)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Mphasis Limited - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Mphasis Limited - Bangalore',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Logbase Technologies - Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Logbase Technologies - Coimbatore',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Walkerscott Pvt Ltd
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Walkerscott Pvt Ltd',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert BoatMinds ai - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'BoatMinds ai - Chennai',
    CURRENT_DATE,
    ARRAY['Internship'],
    '8 - 12 LPA',
    '-',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert 7-Elevan - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    '7-Elevan - Bangalore',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert IBM Consulting - CIC - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'IBM Consulting - CIC - Bangalore',
    CURRENT_DATE,
    ARRAY['Associate System Engineer'],
    'Intern Stipend: 25TPM, FTE: 5 LPA',
    '6 CGPA+ in PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Acies Global Pvt Ltd
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Acies Global Pvt Ltd',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Appviewx Inc - Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Appviewx Inc - Coimbatore',
    CURRENT_DATE,
    ARRAY['3 (Logical Assessment, GD, multiple Interviews)'],
    'Intern Stipend: 18 TPM, FTE: 6 LPA',
    '-',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert FocusR Technologies - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'FocusR Technologies - Chennai',
    CURRENT_DATE,
    ARRAY['Trainee Consultant'],
    'Intern Stipend: 7.5 TPM, FTE: 4 LPA',
    '70% + in 10th, 12th, ug, pg. 3 year bond',
    '[{"name": "Selection Process", "description": "3(OA, GD, Interview)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Pay Huddle - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Pay Huddle - Bangalore',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Netscribes Analytics Private Limited - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Netscribes Analytics Private Limited - Bangalore',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "3 (OA, GD, Interview)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Talview India Pvt Ltd - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Talview India Pvt Ltd - Bangalore',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Eightfold AI India Pvt Ltd - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Eightfold AI India Pvt Ltd - Bangalore',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert DevRev - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'DevRev - Chennai',
    CURRENT_DATE,
    ARRAY['Software Engineering Intern'],
    'Intern Stipend: 50TPM, FTE: 12 LPA fixed + ESOP',
    '7.5 CGPA',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert CEI India Pvt Ltd - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'CEI India Pvt Ltd - Chennai',
    CURRENT_DATE,
    ARRAY['Trainee software engineer'],
    'Intern Stipend: 10TPM, FTE: 5 LPA',
    '2 year Bond',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Josh Technologies Group - Haryana
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Josh Technologies Group - Haryana',
    CURRENT_DATE,
    ARRAY['Software Developer'],
    'Intern Stipend: 22.5 TPM, FTE: 13.47 LPA',
    '-',
    '[{"name": "Selection Process", "description": "3(OA,subjective test, HR)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Justo Global - Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Justo Global - Coimbatore',
    CURRENT_DATE,
    ARRAY['Full Stack Developer'],
    'Intern Stipend: 25TPM, FTE: 7LPA',
    '85%+ in PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert PSG Software Technologies
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'PSG Software Technologies',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    '-',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Camgemini
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Camgemini',
    CURRENT_DATE,
    ARRAY['Analyst'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Worlder Team Ptd Ltd
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Worlder Team Ptd Ltd',
    CURRENT_DATE,
    ARRAY['Ui/Ux designer , Fontend Developer'],
    'Intern Stipend : 20 TPM, FTE : 6-7 LPA',
    'None',
    '[{"name": "Selection Process", "description": "Apptitude, Technical Interview"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Cloud Supply Chain Solutions-CSCS- Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Cloud Supply Chain Solutions-CSCS- Chennai',
    CURRENT_DATE,
    ARRAY['None'],
    'Intern Stipend : 10 TPM, FTE : 3-4 LPA',
    '7.5 in PG , 60% in 10th and 12th',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Verticurl Marketing
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Verticurl Marketing',
    CURRENT_DATE,
    ARRAY['Associate Engineer'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert ShopUp India Pvt Ltd
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'ShopUp India Pvt Ltd',
    CURRENT_DATE,
    ARRAY['Software Developement Engineer, Site Reliability Engineer, Data Scientist/ML Engineer , QA Automation Engineer,Data Analyst/Data Engineer'],
    'Stipend : 40T , FTE : 7-10 LPA',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Kumaran Systems Pvt Ltd
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Kumaran Systems Pvt Ltd',
    CURRENT_DATE,
    ARRAY['Engineer'],
    'Intern Stipend : 20T FTE : 7LPA',
    'None',
    '[{"name": "Selection Process", "description": "Aptitude,Technical Interview"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert rtCamp Solutions Pvt Ltd - Banglore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'rtCamp Solutions Pvt Ltd - Banglore',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert EPAM Systems India Private Limited - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'EPAM Systems India Private Limited - Bangalore',
    CURRENT_DATE,
    ARRAY['Trainee'],
    'Not Disclosed',
    '70% in PG ,60% in 10th and 12th',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Citi India - Mumbai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Citi India - Mumbai',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Ms Sambol Systems Pvt Ltd
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Ms Sambol Systems Pvt Ltd',
    CURRENT_DATE,
    ARRAY['None'],
    'Intern Stipend : 30 TPM, FTE : 7 LPA',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert 7EDGE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    '7EDGE',
    CURRENT_DATE,
    ARRAY['IT-Tools & Automation'],
    'Intern 9T-33T & FTE : 8LPA',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Super AGI
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Super AGI',
    CURRENT_DATE,
    ARRAY['SDE'],
    'FTE - 4LPA-5LPA',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Omnicom Global Solutions
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Omnicom Global Solutions',
    CURRENT_DATE,
    ARRAY['Graduate Trainee - Media Solutions'],
    'Intern : 14T, FTE : 5LPA',
    'None',
    '[{"name": "Selection Process", "description": "Aptitude+Coding round"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Morphle Labs
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Morphle Labs',
    CURRENT_DATE,
    ARRAY['Software Support Intern'],
    'Intern: 21T FTE : 4-6LPA',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert ZOHO Corporation - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'ZOHO Corporation - Chennai',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Infosys Equinox
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Infosys Equinox',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert QLeap10X LLP - Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'QLeap10X LLP - Coimbatore',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    '75% in PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Annam AI - IIT Ropar
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Annam AI - IIT Ropar',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert PayFx
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'PayFx',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Mako IT Lab - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1),
    'Mako IT Lab - Chennai',
    CURRENT_DATE,
    ARRAY['Data Analyst'],
    'Not Disclosed',
    'None',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

END $$;
SELECT 'FILE COMPLETE: 24MX companies seeded.' AS status;-- ============================================================
-- PSGMX SQL — FILE: 06_seed_23MX_companies.sql
-- Seed Placement Logs for batch 23MX
-- ============================================================

DO $$
DECLARE
  new_company_id UUID;
  admin_user_id UUID;
BEGIN
  -- Use the first superadmin or placement_rep as creator
  SELECT id INTO admin_user_id FROM users WHERE role = 'hod' OR app_role = 'placement_rep' LIMIT 1;
  IF admin_user_id IS NULL THEN
    -- Fallback to any user if none found
    SELECT id INTO admin_user_id FROM users LIMIT 1;
  END IF;

  -- Insert CATERPILLAR CODEATHON
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'CATERPILLAR CODEATHON',
    '2024-07-05'::DATE,
    ARRAY['SOFTWARE ENGINEER'],
    '14 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "3-( MCQ prelims,  Hackathon round, F2F interview)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert TheMathCompany TRIATHLON
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'TheMathCompany TRIATHLON',
    CURRENT_DATE,
    ARRAY['TRAINEE ANALYST'],
    '5.5LPA',
    'ABOVE 7.5 CGPA (PG)',
    '[{"name": "Selection Process", "description": "3 ( APTITUDE, COMMUNICATION, CASE STUDY - ALL ONLINE)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert GOOGLE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'GOOGLE',
    CURRENT_DATE,
    ARRAY['SOFTWARE ENGINEER'],
    '37 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "5.0"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert COMMVAULT
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'COMMVAULT',
    CURRENT_DATE,
    ARRAY['SDE'],
    '33 LPA',
    'ABOVE 7.0 CGPA (PG)',
    '[{"name": "Selection Process", "description": "-"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert PHONEPE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'PHONEPE',
    '2024-07-20'::DATE,
    ARRAY['Software Engineering In Testing'],
    '23 LPA',
    'ABOVE 6, NO ARREARS',
    '[{"name": "Selection Process", "description": "4 - ( Coding, Techincal interview, HR interview, 2nd HR interview )"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert THOROGOOD ASSOCIATES
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'THOROGOOD ASSOCIATES',
    CURRENT_DATE,
    ARRAY['Data And AI Consultant'],
    '15LPA',
    'ABOVE 7.5 CGPA (UG & PG) ',
    '[{"name": "Selection Process", "description": "3 - ( Advanced Aptitude round along with essay writing, 
HR interview, interview at Thorogood campus in Bangalore"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert SOCIETE GENERAL CAMPUS DRIVE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'SOCIETE GENERAL CAMPUS DRIVE',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    '12 LPA',
    'ABOVE 7 CGPA (10,12,UG,PG)',
    '[{"name": "Selection Process", "description": "2 - ( Online coding round, F2F interview )"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert V2K AI  COIMBATORE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'V2K AI  COIMBATORE',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    '20LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "3 - ( Coding round, Application development / Hackathon, Interview )"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert INFOSYS LIMITED BANGALORE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'INFOSYS LIMITED BANGALORE',
    CURRENT_DATE,
    ARRAY['Specialist Programmer'],
    '9.5 LPA',
    'ABOVE 60 / 6 CGPA  ( 10,12,UG,PG)',
    '[{"name": "Selection Process", "description": "2 ( online coding round, F2F interview at any one company locations )"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert ACCENTURE BANGALORE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'ACCENTURE BANGALORE',
    '2024-10-07'::DATE,
    ARRAY['Associate Software Engineer & 
Advanced Associate Software Engineer'],
    '4.5 LPA - 6.5LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "First Round: Aptitude
Second Round: Coding 2 qns
Third Round: Communication Round 
Fourth Round: Interview "}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert IBM India Pvt. Ltd., Bangalore (India Systems Development Lab)
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'IBM India Pvt. Ltd., Bangalore (India Systems Development Lab)',
    '2024-08-13'::DATE,
    ARRAY['Software Engineer'],
    '12 LPA',
    'ABOVE 7 CGPA (PG)',
    '[{"name": "Selection Process", "description": "2 - ( Online coding test, Interview )"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert CATERPILLAR ENGINEERING INDIA PVT LTD ( CAT DIGITAL)
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'CATERPILLAR ENGINEERING INDIA PVT LTD ( CAT DIGITAL)',
    '2024-08-06'::DATE,
    ARRAY['Developer /  
project management /
 product manangement'],
    '14 LPA',
    'ABOVE 7.5 CGPA (PG)',
    '[{"name": "Selection Process", "description": "4 ( MCQ test, Coding round, Group discussion, F2F interview )"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Zoho Corporation, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Zoho Corporation, Chennai',
    CURRENT_DATE,
    ARRAY['Software Developer'],
    '8.4 LPA , 7 LPA ,5.6 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "4 ( written aptitude and C technincal questions, 
coding, advanced coding, HR interview )"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Zoho Corporation, Chennai ( 2nd time)
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Zoho Corporation, Chennai ( 2nd time)',
    CURRENT_DATE,
    ARRAY['Software Developer'],
    '8.4 LPA , 7 LPA ,5.6 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "4 ( written aptitude and C technincal questions, 
coding, advanced coding, HR interview )"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Tech Mahindra Ltd., Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Tech Mahindra Ltd., Bangalore',
    CURRENT_DATE,
    ARRAY['Developer / Supercoder'],
    '3.3 LPA - 5.5 LPA',
    'ABOVE 7.0 ( 10,12 UG, PG )',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Quantiphi Analytics , Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Quantiphi Analytics , Bangalore',
    '2024-08-13'::DATE,
    ARRAY['ENGINEER'],
    '6 LPA',
    'ABOVE 7.0 ( 10,12 UG, PG ) 
and no history of arrears',
    '[{"name": "Selection Process", "description": "4 - ( online coding test which had aptitude,OS,JS,networks, DBMS 
+ 3 coding questions
second round was F2F interview / first techincal round
 Third round was Second technical round
Fourth round was HR round
"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Logbase Technologies, Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Logbase Technologies, Coimbatore',
    '2024-08-23'::DATE,
    ARRAY['Full stack developer'],
    '7 LPA',
    '70 % ( UG & PG )',
    '[{"name": "Selection Process", "description": "
5 - ( Aptitude and coding snippets + 3 coding questions, 
F2F interview, 
hackathon + 2 Coding questions round, 
Presentation, HR round ) 
"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Deloitte Consulting India Pvt. Ltd., Hyderabad ( USI )
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Deloitte Consulting India Pvt. Ltd., Hyderabad ( USI )',
    '2024-08-26'::DATE,
    ARRAY['Associate Analyst'],
    '7.6 LPA',
    'ABOVE 6.0 , No arrears',
    '[{"name": "Selection Process", "description": "2 - ( online aptitude, english comprehension, coding 
and then F2F interview)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Vanenburg Software (India) Private Limited, Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Vanenburg Software (India) Private Limited, Coimbatore',
    CURRENT_DATE,
    ARRAY['Associate Software Engineer '],
    '8 LPA',
    'ABOVE 7.0 CGPA',
    '[{"name": "Selection Process", "description": "1. Online Test/ pen & paper Aptitude, English Skills and Technical 
2. Technical Interview- to test coding skills. 
3. Techno Managerial cum HR Interview"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert RND Softech Pvt Ltd
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'RND Softech Pvt Ltd',
    CURRENT_DATE,
    ARRAY['ENGINEER'],
    '8 LPA - 10 LPA',
    'ABOVE 80 % / 8 CGPA',
    '[{"name": "Selection Process", "description": "2 ( 1st round - 20 mcqs based on DSA and ML. 

2nd round - self intro plus sharing of experience.  )"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Tata Consultancy Services ( TCS NQT )
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Tata Consultancy Services ( TCS NQT )',
    '2024-12-06'::DATE,
    ARRAY['NInja
Digital
Prime'],
    'Prime  11.5 LPA

Digital 7.6 LPA

Ninja  3.5 LPA',
    'ABOVE 60% / 6.0 CGPA',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Western DIgital, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Western DIgital, Bangalore',
    CURRENT_DATE,
    ARRAY['JD 1:  Professional 1, 
Information Technology
Automation + bot engineering Professional 1, 
Information Technology
Intern Python Developer
Information Technology :
SERVICENOW (SNOW) DEVELOPER

JD 2: IT- CI & AS: Engg
'],
    '14 LPA',
    'ABOVE 7.5 CGPA  (UG, PG )',
    '[{"name": "Selection Process", "description": "-"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert LTIMIndtree Limited , Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'LTIMIndtree Limited , Bangalore',
    '2024-10-21'::DATE,
    ARRAY['Graduate Engineer Trainee'],
    '4.1 LPA',
    'ABOVE 60% / 6.0 CGPA ( 10,12,UG,PG)',
    '[{"name": "Selection Process", "description": "1st round included 
Aptitude + Technical MCQs + Communication Assessment 

2nd Round - Technical HR

3rd Round - Final HR
(General questions)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert UNO MINDS
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'UNO MINDS',
    CURRENT_DATE,
    ARRAY['None'],
    'Not Disclosed',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert THE MATHCOMPANY CAMPUS DRIVE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'THE MATHCOMPANY CAMPUS DRIVE',
    '2024-08-19'::DATE,
    ARRAY['Trainee Analyst'],
    '5.5 LPA',
    'None',
    '[{"name": "Selection Process", "description": "3 ( APTITUDE, COMMUNICATION, CASE STUDY - ALL ONLINE)"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert SOCIETE GENERAL HACKATHON
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'SOCIETE GENERAL HACKATHON',
    CURRENT_DATE,
    ARRAY['Trainee Analyst'],
    '12 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "2 - ( First Hackathon round in which 3 problem statements were given, 
had to submit demo along with github link, second round 
was ppt presentation about the application developed ) "}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert C5I AI COIMBATORE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'C5I AI COIMBATORE',
    '2024-09-18'::DATE,
    ARRAY['Application Developers'],
    '7 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "Round 1: create a chatbot and ppt on it using 
the requirements and tools given by the company

Round 2: Group discussion 

Round 3: Technical interview 

Round 4: HR interview"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert VISA BANGALORE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'VISA BANGALORE',
    '2024-09-17'::DATE,
    ARRAY['Software engineer'],
    '34 LPA',
    '70 % ( UG & PG )',
    '[{"name": "Selection Process", "description": "Round 1 - Online Coding Test

Round 2 : Technical Interview 

Round 3 : Technical Interview 

Round 4 : Managerial Interview 
"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert ZScaler
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'ZScaler',
    CURRENT_DATE,
    ARRAY['Intern - software development'],
    'Not Disclosed',
    '70 % ( UG & PG )',
    '[{"name": "Selection Process", "description": "-"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert CEI  INDIA PVT LTD
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'CEI  INDIA PVT LTD',
    '2024-11-06'::DATE,
    ARRAY['Trainee Software Engineer'],
    '5 LPA',
    '60 % ( UG & PG )',
    '[{"name": "Selection Process", "description": "Round 1-Written test
Round-2 Technical interview
Round 3- HR interview
"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert INCTURE TECHNOLOGIES
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'INCTURE TECHNOLOGIES',
    '2024-09-28'::DATE,
    ARRAY['Associate Software Engineer - Trainee'],
    '8 LPA',
    '65% (10th, 12th, UG,PG)',
    '[{"name": "Selection Process", "description": "Round -1: Aptitude+ coding

Round-2 : System Design

Round 3: Technical Interview

Round 4: HR Interview"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert LOYALITICS CONSULTING, BANGALORE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'LOYALITICS CONSULTING, BANGALORE',
    CURRENT_DATE,
    ARRAY['Engineer'],
    '6 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert CROSSBOW LABS LLP, BANGALORE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'CROSSBOW LABS LLP, BANGALORE',
    CURRENT_DATE,
    ARRAY['Engineer'],
    '7 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert CAPGEMINI TECHNOLOGY SERVICES, BANGALORE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'CAPGEMINI TECHNOLOGY SERVICES, BANGALORE',
    '2024-11-16'::DATE,
    ARRAY['ANALYST - ₹ 4.3L PA

Analyst (Differential offering
 at the Analyst level - ₹ 5.8L PA

Senior Analyst -  ₹ 7.5L PA'],
    '4.3 LPA - 7.5 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "Assessment 1
Technical MCQ and Written English Test (WET) 

Assessment 2
Coding Assessment

Assessment 3
Spoken English Assessment
Mode-Virtual

F2F interview"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert FLEX TECHNOLOGIES
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'FLEX TECHNOLOGIES',
    '2024-11-26'::DATE,
    ARRAY['Associate Software Engineer - IT'],
    'Not Disclosed',
    'ABOVE 80% / 8 CGPA ',
    '[{"name": "Selection Process", "description": "Round 1: Online Test (MCQs)
Round 2 : Technical Round 1
Round 3 :  Technical Round 2
Round 4: HR round"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Wavicle Data Solutions, Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Wavicle Data Solutions, Coimbatore',
    '2024-10-29'::DATE,
    ARRAY['Engineer'],
    '6LPA - 8LPA',
    'No Minimum criteria for marks but 
should have no standing arrears

History of Backlogs allowed',
    '[{"name": "Selection Process", "description": "1. Round 1: Written test 

2. Round 2: Group discussion

3. Round 3: Technical interview .

4. Round 4: Managerial interview "}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Ankercloud Technologies,Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Ankercloud Technologies,Bangalore',
    CURRENT_DATE,
    ARRAY['Engineer'],
    '6 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Mobicip Technologies Pvt. Ltd., Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Mobicip Technologies Pvt. Ltd., Bangalore',
    '2024-11-27'::DATE,
    ARRAY['Engineer'],
    '8 LPA',
    '70% / 7 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Commonwealth Bank of Australia, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Commonwealth Bank of Australia, Bangalore',
    CURRENT_DATE,
    ARRAY['Graduate Software Engineer'],
    'Not Disclosed',
    '70% / 7 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "-"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Insight Global, Inc, Hyderabad
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Insight Global, Inc, Hyderabad',
    CURRENT_DATE,
    ARRAY['intern '],
    '6 LPA',
    '80% / 8 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert MSG Global Solutions India Pvt Ltd, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'MSG Global Solutions India Pvt Ltd, Bangalore',
    CURRENT_DATE,
    ARRAY['Multiple Profiles'],
    '6.5 LPA',
    '70% / 7 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Kovai.co., Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Kovai.co., Coimbatore',
    CURRENT_DATE,
    ARRAY['Intern – Product Management

Intern – Data Scientist'],
    '6 LPA',
    '60% / 6 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "Telephonic Interview 
Technical Interview 
Machine Test
Personal Interview"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Ford Motor Pvt Ltd., Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Ford Motor Pvt Ltd., Chennai',
    '2024-11-22'::DATE,
    ARRAY['GET'],
    'Not Disclosed',
    '60% / 6 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "Round 1:
Online assignment with 3 sections
1. Aptitude
2. Technical
3. Code
Round 2:
Interview + HR"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert ICU Medical India LLP, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'ICU Medical India LLP, Chennai',
    CURRENT_DATE,
    ARRAY['Engineer'],
    'Not Disclosed',
    '70% / 7 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert EPAM Systems India Private Limited, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'EPAM Systems India Private Limited, Bangalore',
    CURRENT_DATE,
    ARRAY['Sofware Engineer'],
    '8LPA',
    '70% / 7 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Codewalla Software Development Pvt. Ltd., Pune
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Codewalla Software Development Pvt. Ltd., Pune',
    CURRENT_DATE,
    ARRAY['Software Development Engineer - Intern / 
Software Development Engineer - Trainee'],
    '9 LPA',
    '75 % or 7.5 CGPA in 10th, 12th, UG, PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Hyundai Motor India Limited, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Hyundai Motor India Limited, Chennai',
    CURRENT_DATE,
    ARRAY['GET and PGET'],
    '8 LPA - 9.25 LPA',
    '60 % or 6 CGPA in 10th, 12th, UG, PG',
    '[{"name": "Selection Process", "description": "-"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Justo Global, Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Justo Global, Coimbatore',
    CURRENT_DATE,
    ARRAY['Intern Developers'],
    '7  - 13 LPA.',
    '80% / 8 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Ernst & Young Services Pvt Ltd,Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Ernst & Young Services Pvt Ltd,Bangalore',
    CURRENT_DATE,
    ARRAY['Associate Consultant'],
    'Not Disclosed',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "-"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Mobicip Technologies Pvt. Ltd., Bangalore ( new role )
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Mobicip Technologies Pvt. Ltd., Bangalore ( new role )',
    '2024-12-19'::DATE,
    ARRAY['Technical Support Engineer'],
    '5 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Kumaran System Pvt.Ltd, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Kumaran System Pvt.Ltd, Chennai',
    CURRENT_DATE,
    ARRAY['Software Developer'],
    '7 LPA',
    '60% / 6 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert AtoB Pvt.Ltd, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'AtoB Pvt.Ltd, Bangalore',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    '27 LPA',
    '80% / 8 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert L7 Informatics India Pvt Ltd, Bengalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'L7 Informatics India Pvt Ltd, Bengalore',
    '2024-12-21'::DATE,
    ARRAY['Software Engineer'],
    'Not Disclosed',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "3.0"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Computer Age Management Services Pvt Ltd
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Computer Age Management Services Pvt Ltd',
    CURRENT_DATE,
    ARRAY['PGET'],
    '6 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Turing, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Turing, Bangalore',
    CURRENT_DATE,
    ARRAY['Multiple Profiles'],
    '7.5 LPA',
    '60 % or 6 CGPA in 10th, 12th, UG, PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Gyansys infotech PVT LTD Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Gyansys infotech PVT LTD Bangalore',
    CURRENT_DATE,
    ARRAY['Engineer'],
    '6 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert BNP Paribas Bangalore ( Hackathon )
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'BNP Paribas Bangalore ( Hackathon )',
    '2025-01-18'::DATE,
    ARRAY['NA'],
    'Not Disclosed',
    'NA',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Bouteous X Accolite, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Bouteous X Accolite, Bangalore',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    '8LPA',
    '60 % or 6 CGPA in 10th, 12th, UG, PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Intellect Design Arena, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Intellect Design Arena, Chennai',
    CURRENT_DATE,
    ARRAY['Associate Consultant 
(Java Full Stack Developer)'],
    '4LPA',
    '60% / 6 CGPA in  PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Kalvium, Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Kalvium, Coimbatore',
    CURRENT_DATE,
    ARRAY['Program Architect'],
    '10LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Saama Technologies , Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Saama Technologies , Coimbatore',
    '2025-01-31'::DATE,
    ARRAY['Engineer'],
    '4.2lpa',
    '70% 0r 7CGPA in PG',
    '[{"name": "Selection Process", "description": "4.0"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Ivanti Technology India, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Ivanti Technology India, Bangalore',
    CURRENT_DATE,
    ARRAY['Engineer'],
    '5 LPA',
    '80% / 8 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Virtusa , Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Virtusa , Chennai',
    CURRENT_DATE,
    ARRAY['Associate Software Engineer '],
    '5 LPA',
    '80% / 8 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Mindgate Solutions, Pvt.Ltd, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Mindgate Solutions, Pvt.Ltd, Chennai',
    CURRENT_DATE,
    ARRAY['Trainee Developer'],
    '5LPA',
    '70% 0r 7CGPA in PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Cotiviti India Pvt. Ltd., Pune
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Cotiviti India Pvt. Ltd., Pune',
    CURRENT_DATE,
    ARRAY['Engineer'],
    '5.5 LPA',
    '70% 0r 7CGPA in PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Annalect India, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Annalect India, Bangalore',
    '2025-04-19'::DATE,
    ARRAY['Graduate Trainee (GT) – Media Services'],
    '4.5 LPA',
    '65% / 6.5 CGPA in  PG',
    '[{"name": "Selection Process", "description": "Aptitude , Technical Interview"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Goldman Sachs Technology Division, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Goldman Sachs Technology Division, Bangalore',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    '30 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert IRIS Business Services Limited ,Mumbai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'IRIS Business Services Limited ,Mumbai',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    'Not Disclosed',
    '70% 0r 7CGPA in PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Light Mechanics Pvt Ltd, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Light Mechanics Pvt Ltd, Bangalore',
    CURRENT_DATE,
    ARRAY['Engineer'],
    '3 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert NCompass TechStudio, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'NCompass TechStudio, Chennai',
    CURRENT_DATE,
    ARRAY['Software Developer'],
    'Not Disclosed',
    '70% 0r 7CGPA in PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert FocusR Technologies,Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'FocusR Technologies,Chennai',
    '2025-04-21'::DATE,
    ARRAY['Trainee Consultant / Trainee Developer.'],
    '4 LPA',
    '70% / 7 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "Aptitude , Group Discussion , Technical Interview"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Nibana Solutions Pvt.Ltd, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Nibana Solutions Pvt.Ltd, Chennai',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    '6 - 7 LPA',
    '70% 0r 7CGPA in PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Zeetaminds Technologies Pvt Ltd, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Zeetaminds Technologies Pvt Ltd, Chennai',
    CURRENT_DATE,
    ARRAY['Software Developer'],
    '6 LPA',
    '70% / 7 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Testpress, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Testpress, Chennai',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    '3.3 LPA',
    '70% 0r 7CGPA in PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

  -- Insert Sandhata Technologies Pvt.Ltd, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1),
    'Sandhata Technologies Pvt.Ltd, Chennai',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    '5 LPA',
    '70% 0r 7CGPA in PG',
    '[{"name": "Selection Process", "description": "None"}]'::JSONB,
    admin_user_id
  ) RETURNING id INTO new_company_id;

END $$;
SELECT 'FILE COMPLETE: 23MX companies seeded.' AS status;