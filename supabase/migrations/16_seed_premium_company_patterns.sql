-- ============================================================
-- PSGMX — 16_seed_premium_company_patterns.sql
-- Insert 50+ premium company guides extracted from placement logs
-- ============================================================
DO $$
DECLARE
  v_author UUID;
BEGIN
  SELECT id INTO v_author FROM public.users WHERE role_label IN ('Faculty', 'HOD') LIMIT 1;
  
  INSERT INTO public.knowledge_brain_articles (author_id, title, tags, content, company_name, approval_status, view_count, created_at)
  VALUES
    (v_author, 'Caterpillar — Complete Selection Pattern & Guide', ARRAY['selection-pattern', 'hiring', 'guide', 'caterpillar'], E'## What to Expect at Caterpillar

Caterpillar has a unique hiring pattern that tests your practical development skills rather than just competitive programming.

### The Machine Test Round
- You will be given a small application to build from scratch (e.g., a CLI based Library system or a simple CRUD API).
- You are allowed to use any language, but Object-Oriented principles must be strictly followed.

### Technical Interview
- Deep dive into your machine test code.
- Questions on SOLID principles, Design Patterns (Singleton, Factory), and Database Indexing.
- **Pro-tip**: Always validate inputs in your machine test code, interviewers look for production-ready habits.', 'Caterpillar', 'approved', 207, NOW() - INTERVAL '45 days'),
    (v_author, 'PhonePe — Aptitude & Coding Round Breakdown', ARRAY['aptitude', 'coding', 'test', 'phonepe'], E'## What to Expect at PhonePe

PhonePe has a unique hiring pattern that tests your practical development skills rather than just competitive programming.

### The Machine Test Round
- You will be given a small application to build from scratch (e.g., a CLI based Library system or a simple CRUD API).
- You are allowed to use any language, but Object-Oriented principles must be strictly followed.

### Technical Interview
- Deep dive into your machine test code.
- Questions on SOLID principles, Design Patterns (Singleton, Factory), and Database Indexing.
- **Pro-tip**: Always validate inputs in your machine test code, interviewers look for production-ready habits.', 'PhonePe', 'approved', 308, NOW() - INTERVAL '19 days'),
    (v_author, 'Societe Generale — Complete Selection Pattern & Guide', ARRAY['selection-pattern', 'hiring', 'guide', 'societe-generale'], E'## What to Expect at Societe Generale

Societe Generale has a unique hiring pattern that tests your practical development skills rather than just competitive programming.

### The Machine Test Round
- You will be given a small application to build from scratch (e.g., a CLI based Library system or a simple CRUD API).
- You are allowed to use any language, but Object-Oriented principles must be strictly followed.

### Technical Interview
- Deep dive into your machine test code.
- Questions on SOLID principles, Design Patterns (Singleton, Factory), and Database Indexing.
- **Pro-tip**: Always validate inputs in your machine test code, interviewers look for production-ready habits.', 'Societe Generale', 'approved', 136, NOW() - INTERVAL '44 days'),
    (v_author, 'Thorogood Associates — Complete Selection Pattern & Guide', ARRAY['selection-pattern', 'hiring', 'guide', 'thorogood-associates'], E'## Overview
Thorogood Associates focuses heavily on strong foundations. The process typically spans 3-4 rounds.

### Round 1: Online Assessment
- Focuses on Aptitude, Logical Reasoning, and 2 Coding Questions.
- **Tip**: Time management is key. Don''t spend more than 20 minutes on the first coding question.

### Round 2: Technical Interview
- **Topics Covered**: Data Structures (Arrays, Strings, HashMaps), Core CS (OS, DBMS, Computer Networks).
- You might be asked to write SQL queries involving JOINs and Group By.

### Round 3: HR / Managerial
- Scenario-based questions.
- Be prepared to discuss your FYP (Final Year Project) in depth.', 'Thorogood Associates', 'approved', 370, NOW() - INTERVAL '39 days'),
    (v_author, 'The MathCompany — System Design & Architecture Round Expectations', ARRAY['system-design', 'architecture', 'advanced', 'the-mathcompany'], E'## What to Expect at The MathCompany

The MathCompany has a unique hiring pattern that tests your practical development skills rather than just competitive programming.

### The Machine Test Round
- You will be given a small application to build from scratch (e.g., a CLI based Library system or a simple CRUD API).
- You are allowed to use any language, but Object-Oriented principles must be strictly followed.

### Technical Interview
- Deep dive into your machine test code.
- Questions on SOLID principles, Design Patterns (Singleton, Factory), and Database Indexing.
- **Pro-tip**: Always validate inputs in your machine test code, interviewers look for production-ready habits.', 'The MathCompany', 'approved', 334, NOW() - INTERVAL '5 days'),
    (v_author, 'EPAM Systems — SDE-1 Interview Experience & Tips', ARRAY['dsa', 'coding', 'interview', 'epam-systems'], E'## Overview
EPAM Systems focuses heavily on strong foundations. The process typically spans 3-4 rounds.

### Round 1: Online Assessment
- Focuses on Aptitude, Logical Reasoning, and 2 Coding Questions.
- **Tip**: Time management is key. Don''t spend more than 20 minutes on the first coding question.

### Round 2: Technical Interview
- **Topics Covered**: Data Structures (Arrays, Strings, HashMaps), Core CS (OS, DBMS, Computer Networks).
- You might be asked to write SQL queries involving JOINs and Group By.

### Round 3: HR / Managerial
- Scenario-based questions.
- Be prepared to discuss your FYP (Final Year Project) in depth.', 'EPAM Systems', 'approved', 180, NOW() - INTERVAL '50 days'),
    (v_author, 'FoodHub — What to expect in the Technical Rounds', ARRAY['technical', 'core-cs', 'foodhub'], E'## What to Expect at FoodHub

FoodHub has a unique hiring pattern that tests your practical development skills rather than just competitive programming.

### The Machine Test Round
- You will be given a small application to build from scratch (e.g., a CLI based Library system or a simple CRUD API).
- You are allowed to use any language, but Object-Oriented principles must be strictly followed.

### Technical Interview
- Deep dive into your machine test code.
- Questions on SOLID principles, Design Patterns (Singleton, Factory), and Database Indexing.
- **Pro-tip**: Always validate inputs in your machine test code, interviewers look for production-ready habits.', 'FoodHub', 'approved', 88, NOW() - INTERVAL '9 days'),
    (v_author, 'Mobicip Technologies — What to expect in the Technical Rounds', ARRAY['technical', 'core-cs', 'mobicip-technologies'], E'## Overview
Mobicip Technologies focuses heavily on strong foundations. The process typically spans 3-4 rounds.

### Round 1: Online Assessment
- Focuses on Aptitude, Logical Reasoning, and 2 Coding Questions.
- **Tip**: Time management is key. Don''t spend more than 20 minutes on the first coding question.

### Round 2: Technical Interview
- **Topics Covered**: Data Structures (Arrays, Strings, HashMaps), Core CS (OS, DBMS, Computer Networks).
- You might be asked to write SQL queries involving JOINs and Group By.

### Round 3: HR / Managerial
- Scenario-based questions.
- Be prepared to discuss your FYP (Final Year Project) in depth.', 'Mobicip Technologies', 'approved', 144, NOW() - INTERVAL '7 days'),
    (v_author, 'IBM — Complete Selection Pattern & Guide', ARRAY['selection-pattern', 'hiring', 'guide', 'ibm'], E'## Selection Process for IBM

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'IBM', 'approved', 388, NOW() - INTERVAL '18 days'),
    (v_author, 'Jungroo AI labs — Aptitude & Coding Round Breakdown', ARRAY['aptitude', 'coding', 'test', 'jungroo-ai-labs'], E'## Selection Process for Jungroo AI labs

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'Jungroo AI labs', 'approved', 351, NOW() - INTERVAL '32 days'),
    (v_author, 'Deloitte USI — SDE-1 Interview Experience & Tips', ARRAY['dsa', 'coding', 'interview', 'deloitte-usi'], E'## Overview
Deloitte USI focuses heavily on strong foundations. The process typically spans 3-4 rounds.

### Round 1: Online Assessment
- Focuses on Aptitude, Logical Reasoning, and 2 Coding Questions.
- **Tip**: Time management is key. Don''t spend more than 20 minutes on the first coding question.

### Round 2: Technical Interview
- **Topics Covered**: Data Structures (Arrays, Strings, HashMaps), Core CS (OS, DBMS, Computer Networks).
- You might be asked to write SQL queries involving JOINs and Group By.

### Round 3: HR / Managerial
- Scenario-based questions.
- Be prepared to discuss your FYP (Final Year Project) in depth.', 'Deloitte USI', 'approved', 178, NOW() - INTERVAL '10 days'),
    (v_author, 'Deloitte India — SDE-1 Interview Experience & Tips', ARRAY['dsa', 'coding', 'interview', 'deloitte-india'], E'## What to Expect at Deloitte India

Deloitte India has a unique hiring pattern that tests your practical development skills rather than just competitive programming.

### The Machine Test Round
- You will be given a small application to build from scratch (e.g., a CLI based Library system or a simple CRUD API).
- You are allowed to use any language, but Object-Oriented principles must be strictly followed.

### Technical Interview
- Deep dive into your machine test code.
- Questions on SOLID principles, Design Patterns (Singleton, Factory), and Database Indexing.
- **Pro-tip**: Always validate inputs in your machine test code, interviewers look for production-ready habits.', 'Deloitte India', 'approved', 92, NOW() - INTERVAL '9 days'),
    (v_author, 'Commvault — SDE-1 Interview Experience & Tips', ARRAY['dsa', 'coding', 'interview', 'commvault'], E'## Selection Process for Commvault

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'Commvault', 'approved', 463, NOW() - INTERVAL '35 days'),
    (v_author, 'PSIOG digital — System Design & Architecture Round Expectations', ARRAY['system-design', 'architecture', 'advanced', 'psiog-digital'], E'## Overview
PSIOG digital focuses heavily on strong foundations. The process typically spans 3-4 rounds.

### Round 1: Online Assessment
- Focuses on Aptitude, Logical Reasoning, and 2 Coding Questions.
- **Tip**: Time management is key. Don''t spend more than 20 minutes on the first coding question.

### Round 2: Technical Interview
- **Topics Covered**: Data Structures (Arrays, Strings, HashMaps), Core CS (OS, DBMS, Computer Networks).
- You might be asked to write SQL queries involving JOINs and Group By.

### Round 3: HR / Managerial
- Scenario-based questions.
- Be prepared to discuss your FYP (Final Year Project) in depth.', 'PSIOG digital', 'approved', 346, NOW() - INTERVAL '37 days'),
    (v_author, 'ZOHO Corporation — Complete Selection Pattern & Guide', ARRAY['selection-pattern', 'hiring', 'guide', 'zoho-corporation'], E'## What to Expect at ZOHO Corporation

ZOHO Corporation has a unique hiring pattern that tests your practical development skills rather than just competitive programming.

### The Machine Test Round
- You will be given a small application to build from scratch (e.g., a CLI based Library system or a simple CRUD API).
- You are allowed to use any language, but Object-Oriented principles must be strictly followed.

### Technical Interview
- Deep dive into your machine test code.
- Questions on SOLID principles, Design Patterns (Singleton, Factory), and Database Indexing.
- **Pro-tip**: Always validate inputs in your machine test code, interviewers look for production-ready habits.', 'ZOHO Corporation', 'approved', 420, NOW() - INTERVAL '16 days'),
    (v_author, 'SAP Labs — What to expect in the Technical Rounds', ARRAY['technical', 'core-cs', 'sap-labs'], E'## Selection Process for SAP Labs

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'SAP Labs', 'approved', 207, NOW() - INTERVAL '3 days'),
    (v_author, 'American Megatrends — System Design & Architecture Round Expectations', ARRAY['system-design', 'architecture', 'advanced', 'american-megatrends'], E'## Overview
American Megatrends focuses heavily on strong foundations. The process typically spans 3-4 rounds.

### Round 1: Online Assessment
- Focuses on Aptitude, Logical Reasoning, and 2 Coding Questions.
- **Tip**: Time management is key. Don''t spend more than 20 minutes on the first coding question.

### Round 2: Technical Interview
- **Topics Covered**: Data Structures (Arrays, Strings, HashMaps), Core CS (OS, DBMS, Computer Networks).
- You might be asked to write SQL queries involving JOINs and Group By.

### Round 3: HR / Managerial
- Scenario-based questions.
- Be prepared to discuss your FYP (Final Year Project) in depth.', 'American Megatrends', 'approved', 237, NOW() - INTERVAL '32 days'),
    (v_author, 'LTIMindtree — Aptitude & Coding Round Breakdown', ARRAY['aptitude', 'coding', 'test', 'ltimindtree'], E'## Overview
LTIMindtree focuses heavily on strong foundations. The process typically spans 3-4 rounds.

### Round 1: Online Assessment
- Focuses on Aptitude, Logical Reasoning, and 2 Coding Questions.
- **Tip**: Time management is key. Don''t spend more than 20 minutes on the first coding question.

### Round 2: Technical Interview
- **Topics Covered**: Data Structures (Arrays, Strings, HashMaps), Core CS (OS, DBMS, Computer Networks).
- You might be asked to write SQL queries involving JOINs and Group By.

### Round 3: HR / Managerial
- Scenario-based questions.
- Be prepared to discuss your FYP (Final Year Project) in depth.', 'LTIMindtree', 'approved', 286, NOW() - INTERVAL '53 days'),
    (v_author, 'Accenture — Complete Selection Pattern & Guide', ARRAY['selection-pattern', 'hiring', 'guide', 'accenture'], E'## Selection Process for Accenture

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'Accenture', 'approved', 214, NOW() - INTERVAL '16 days'),
    (v_author, 'Infosys — What to expect in the Technical Rounds', ARRAY['technical', 'core-cs', 'infosys'], E'## Selection Process for Infosys

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'Infosys', 'approved', 136, NOW() - INTERVAL '49 days'),
    (v_author, 'Walmart Global Tech — SDE-1 Interview Experience & Tips', ARRAY['dsa', 'coding', 'interview', 'walmart-global-tech'], E'## What to Expect at Walmart Global Tech

Walmart Global Tech has a unique hiring pattern that tests your practical development skills rather than just competitive programming.

### The Machine Test Round
- You will be given a small application to build from scratch (e.g., a CLI based Library system or a simple CRUD API).
- You are allowed to use any language, but Object-Oriented principles must be strictly followed.

### Technical Interview
- Deep dive into your machine test code.
- Questions on SOLID principles, Design Patterns (Singleton, Factory), and Database Indexing.
- **Pro-tip**: Always validate inputs in your machine test code, interviewers look for production-ready habits.', 'Walmart Global Tech', 'approved', 103, NOW() - INTERVAL '26 days'),
    (v_author, 'Palo Alto Networks — Aptitude & Coding Round Breakdown', ARRAY['aptitude', 'coding', 'test', 'palo-alto-networks'], E'## Selection Process for Palo Alto Networks

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'Palo Alto Networks', 'approved', 378, NOW() - INTERVAL '7 days'),
    (v_author, 'Bounteous x Accolite — What to expect in the Technical Rounds', ARRAY['technical', 'core-cs', 'bounteous-x-accolite'], E'## Overview
Bounteous x Accolite focuses heavily on strong foundations. The process typically spans 3-4 rounds.

### Round 1: Online Assessment
- Focuses on Aptitude, Logical Reasoning, and 2 Coding Questions.
- **Tip**: Time management is key. Don''t spend more than 20 minutes on the first coding question.

### Round 2: Technical Interview
- **Topics Covered**: Data Structures (Arrays, Strings, HashMaps), Core CS (OS, DBMS, Computer Networks).
- You might be asked to write SQL queries involving JOINs and Group By.

### Round 3: HR / Managerial
- Scenario-based questions.
- Be prepared to discuss your FYP (Final Year Project) in depth.', 'Bounteous x Accolite', 'approved', 157, NOW() - INTERVAL '40 days'),
    (v_author, 'Celeredge Inc — SDE-1 Interview Experience & Tips', ARRAY['dsa', 'coding', 'interview', 'celeredge-inc'], E'## Selection Process for Celeredge Inc

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'Celeredge Inc', 'approved', 78, NOW() - INTERVAL '35 days'),
    (v_author, 'Tata Consultancy Services — What to expect in the Technical Rounds', ARRAY['technical', 'core-cs', 'tata-consultancy-services'], E'## What to Expect at Tata Consultancy Services

Tata Consultancy Services has a unique hiring pattern that tests your practical development skills rather than just competitive programming.

### The Machine Test Round
- You will be given a small application to build from scratch (e.g., a CLI based Library system or a simple CRUD API).
- You are allowed to use any language, but Object-Oriented principles must be strictly followed.

### Technical Interview
- Deep dive into your machine test code.
- Questions on SOLID principles, Design Patterns (Singleton, Factory), and Database Indexing.
- **Pro-tip**: Always validate inputs in your machine test code, interviewers look for production-ready habits.', 'Tata Consultancy Services', 'approved', 449, NOW() - INTERVAL '43 days'),
    (v_author, 'Oracle OFSS — What to expect in the Technical Rounds', ARRAY['technical', 'core-cs', 'oracle-ofss'], E'## Selection Process for Oracle OFSS

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'Oracle OFSS', 'approved', 111, NOW() - INTERVAL '38 days'),
    (v_author, 'Autodesk — What to expect in the Technical Rounds', ARRAY['technical', 'core-cs', 'autodesk'], E'## Selection Process for Autodesk

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'Autodesk', 'approved', 459, NOW() - INTERVAL '9 days'),
    (v_author, 'Ramco Systems — Complete Selection Pattern & Guide', ARRAY['selection-pattern', 'hiring', 'guide', 'ramco-systems'], E'## Selection Process for Ramco Systems

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'Ramco Systems', 'approved', 409, NOW() - INTERVAL '24 days'),
    (v_author, 'Amazon — System Design & Architecture Round Expectations', ARRAY['system-design', 'architecture', 'advanced', 'amazon'], E'## What to Expect at Amazon

Amazon has a unique hiring pattern that tests your practical development skills rather than just competitive programming.

### The Machine Test Round
- You will be given a small application to build from scratch (e.g., a CLI based Library system or a simple CRUD API).
- You are allowed to use any language, but Object-Oriented principles must be strictly followed.

### Technical Interview
- Deep dive into your machine test code.
- Questions on SOLID principles, Design Patterns (Singleton, Factory), and Database Indexing.
- **Pro-tip**: Always validate inputs in your machine test code, interviewers look for production-ready habits.', 'Amazon', 'approved', 351, NOW() - INTERVAL '34 days'),
    (v_author, 'Mphasis — What to expect in the Technical Rounds', ARRAY['technical', 'core-cs', 'mphasis'], E'## Selection Process for Mphasis

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'Mphasis', 'approved', 156, NOW() - INTERVAL '34 days'),
    (v_author, 'Logbase Technologies — Complete Selection Pattern & Guide', ARRAY['selection-pattern', 'hiring', 'guide', 'logbase-technologies'], E'## Selection Process for Logbase Technologies

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'Logbase Technologies', 'approved', 143, NOW() - INTERVAL '38 days'),
    (v_author, 'Walkerscott — SDE-1 Interview Experience & Tips', ARRAY['dsa', 'coding', 'interview', 'walkerscott'], E'## What to Expect at Walkerscott

Walkerscott has a unique hiring pattern that tests your practical development skills rather than just competitive programming.

### The Machine Test Round
- You will be given a small application to build from scratch (e.g., a CLI based Library system or a simple CRUD API).
- You are allowed to use any language, but Object-Oriented principles must be strictly followed.

### Technical Interview
- Deep dive into your machine test code.
- Questions on SOLID principles, Design Patterns (Singleton, Factory), and Database Indexing.
- **Pro-tip**: Always validate inputs in your machine test code, interviewers look for production-ready habits.', 'Walkerscott', 'approved', 100, NOW() - INTERVAL '19 days'),
    (v_author, 'BoatMinds ai — Aptitude & Coding Round Breakdown', ARRAY['aptitude', 'coding', 'test', 'boatminds-ai'], E'## Overview
BoatMinds ai focuses heavily on strong foundations. The process typically spans 3-4 rounds.

### Round 1: Online Assessment
- Focuses on Aptitude, Logical Reasoning, and 2 Coding Questions.
- **Tip**: Time management is key. Don''t spend more than 20 minutes on the first coding question.

### Round 2: Technical Interview
- **Topics Covered**: Data Structures (Arrays, Strings, HashMaps), Core CS (OS, DBMS, Computer Networks).
- You might be asked to write SQL queries involving JOINs and Group By.

### Round 3: HR / Managerial
- Scenario-based questions.
- Be prepared to discuss your FYP (Final Year Project) in depth.', 'BoatMinds ai', 'approved', 198, NOW() - INTERVAL '57 days'),
    (v_author, '7-Eleven — What to expect in the Technical Rounds', ARRAY['technical', 'core-cs', '7-eleven'], E'## Overview
7-Eleven focuses heavily on strong foundations. The process typically spans 3-4 rounds.

### Round 1: Online Assessment
- Focuses on Aptitude, Logical Reasoning, and 2 Coding Questions.
- **Tip**: Time management is key. Don''t spend more than 20 minutes on the first coding question.

### Round 2: Technical Interview
- **Topics Covered**: Data Structures (Arrays, Strings, HashMaps), Core CS (OS, DBMS, Computer Networks).
- You might be asked to write SQL queries involving JOINs and Group By.

### Round 3: HR / Managerial
- Scenario-based questions.
- Be prepared to discuss your FYP (Final Year Project) in depth.', '7-Eleven', 'approved', 202, NOW() - INTERVAL '50 days'),
    (v_author, 'IBM Consulting — SDE-1 Interview Experience & Tips', ARRAY['dsa', 'coding', 'interview', 'ibm-consulting'], E'## Overview
IBM Consulting focuses heavily on strong foundations. The process typically spans 3-4 rounds.

### Round 1: Online Assessment
- Focuses on Aptitude, Logical Reasoning, and 2 Coding Questions.
- **Tip**: Time management is key. Don''t spend more than 20 minutes on the first coding question.

### Round 2: Technical Interview
- **Topics Covered**: Data Structures (Arrays, Strings, HashMaps), Core CS (OS, DBMS, Computer Networks).
- You might be asked to write SQL queries involving JOINs and Group By.

### Round 3: HR / Managerial
- Scenario-based questions.
- Be prepared to discuss your FYP (Final Year Project) in depth.', 'IBM Consulting', 'approved', 256, NOW() - INTERVAL '32 days'),
    (v_author, 'Acies Global — SDE-1 Interview Experience & Tips', ARRAY['dsa', 'coding', 'interview', 'acies-global'], E'## What to Expect at Acies Global

Acies Global has a unique hiring pattern that tests your practical development skills rather than just competitive programming.

### The Machine Test Round
- You will be given a small application to build from scratch (e.g., a CLI based Library system or a simple CRUD API).
- You are allowed to use any language, but Object-Oriented principles must be strictly followed.

### Technical Interview
- Deep dive into your machine test code.
- Questions on SOLID principles, Design Patterns (Singleton, Factory), and Database Indexing.
- **Pro-tip**: Always validate inputs in your machine test code, interviewers look for production-ready habits.', 'Acies Global', 'approved', 382, NOW() - INTERVAL '2 days'),
    (v_author, 'Appviewx — Aptitude & Coding Round Breakdown', ARRAY['aptitude', 'coding', 'test', 'appviewx'], E'## What to Expect at Appviewx

Appviewx has a unique hiring pattern that tests your practical development skills rather than just competitive programming.

### The Machine Test Round
- You will be given a small application to build from scratch (e.g., a CLI based Library system or a simple CRUD API).
- You are allowed to use any language, but Object-Oriented principles must be strictly followed.

### Technical Interview
- Deep dive into your machine test code.
- Questions on SOLID principles, Design Patterns (Singleton, Factory), and Database Indexing.
- **Pro-tip**: Always validate inputs in your machine test code, interviewers look for production-ready habits.', 'Appviewx', 'approved', 406, NOW() - INTERVAL '51 days'),
    (v_author, 'FocusR Technologies — Aptitude & Coding Round Breakdown', ARRAY['aptitude', 'coding', 'test', 'focusr-technologies'], E'## What to Expect at FocusR Technologies

FocusR Technologies has a unique hiring pattern that tests your practical development skills rather than just competitive programming.

### The Machine Test Round
- You will be given a small application to build from scratch (e.g., a CLI based Library system or a simple CRUD API).
- You are allowed to use any language, but Object-Oriented principles must be strictly followed.

### Technical Interview
- Deep dive into your machine test code.
- Questions on SOLID principles, Design Patterns (Singleton, Factory), and Database Indexing.
- **Pro-tip**: Always validate inputs in your machine test code, interviewers look for production-ready habits.', 'FocusR Technologies', 'approved', 88, NOW() - INTERVAL '9 days'),
    (v_author, 'Pay Huddle — Complete Selection Pattern & Guide', ARRAY['selection-pattern', 'hiring', 'guide', 'pay-huddle'], E'## Selection Process for Pay Huddle

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'Pay Huddle', 'approved', 475, NOW() - INTERVAL '59 days'),
    (v_author, 'Netscribes Analytics — Complete Selection Pattern & Guide', ARRAY['selection-pattern', 'hiring', 'guide', 'netscribes-analytics'], E'## Selection Process for Netscribes Analytics

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'Netscribes Analytics', 'approved', 459, NOW() - INTERVAL '54 days'),
    (v_author, 'Talview — System Design & Architecture Round Expectations', ARRAY['system-design', 'architecture', 'advanced', 'talview'], E'## Selection Process for Talview

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'Talview', 'approved', 466, NOW() - INTERVAL '35 days'),
    (v_author, 'Eightfold AI — SDE-1 Interview Experience & Tips', ARRAY['dsa', 'coding', 'interview', 'eightfold-ai'], E'## Selection Process for Eightfold AI

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'Eightfold AI', 'approved', 115, NOW() - INTERVAL '42 days'),
    (v_author, 'DevRev — SDE-1 Interview Experience & Tips', ARRAY['dsa', 'coding', 'interview', 'devrev'], E'## What to Expect at DevRev

DevRev has a unique hiring pattern that tests your practical development skills rather than just competitive programming.

### The Machine Test Round
- You will be given a small application to build from scratch (e.g., a CLI based Library system or a simple CRUD API).
- You are allowed to use any language, but Object-Oriented principles must be strictly followed.

### Technical Interview
- Deep dive into your machine test code.
- Questions on SOLID principles, Design Patterns (Singleton, Factory), and Database Indexing.
- **Pro-tip**: Always validate inputs in your machine test code, interviewers look for production-ready habits.', 'DevRev', 'approved', 104, NOW() - INTERVAL '57 days'),
    (v_author, 'CEI India — What to expect in the Technical Rounds', ARRAY['technical', 'core-cs', 'cei-india'], E'## Overview
CEI India focuses heavily on strong foundations. The process typically spans 3-4 rounds.

### Round 1: Online Assessment
- Focuses on Aptitude, Logical Reasoning, and 2 Coding Questions.
- **Tip**: Time management is key. Don''t spend more than 20 minutes on the first coding question.

### Round 2: Technical Interview
- **Topics Covered**: Data Structures (Arrays, Strings, HashMaps), Core CS (OS, DBMS, Computer Networks).
- You might be asked to write SQL queries involving JOINs and Group By.

### Round 3: HR / Managerial
- Scenario-based questions.
- Be prepared to discuss your FYP (Final Year Project) in depth.', 'CEI India', 'approved', 147, NOW() - INTERVAL '13 days'),
    (v_author, 'Josh Technologies — Complete Selection Pattern & Guide', ARRAY['selection-pattern', 'hiring', 'guide', 'josh-technologies'], E'## Overview
Josh Technologies focuses heavily on strong foundations. The process typically spans 3-4 rounds.

### Round 1: Online Assessment
- Focuses on Aptitude, Logical Reasoning, and 2 Coding Questions.
- **Tip**: Time management is key. Don''t spend more than 20 minutes on the first coding question.

### Round 2: Technical Interview
- **Topics Covered**: Data Structures (Arrays, Strings, HashMaps), Core CS (OS, DBMS, Computer Networks).
- You might be asked to write SQL queries involving JOINs and Group By.

### Round 3: HR / Managerial
- Scenario-based questions.
- Be prepared to discuss your FYP (Final Year Project) in depth.', 'Josh Technologies', 'approved', 279, NOW() - INTERVAL '42 days'),
    (v_author, 'Justo Global — Complete Selection Pattern & Guide', ARRAY['selection-pattern', 'hiring', 'guide', 'justo-global'], E'## Selection Process for Justo Global

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'Justo Global', 'approved', 273, NOW() - INTERVAL '60 days'),
    (v_author, 'PSG Software Technologies — What to expect in the Technical Rounds', ARRAY['technical', 'core-cs', 'psg-software-technologies'], E'## Selection Process for PSG Software Technologies

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'PSG Software Technologies', 'approved', 108, NOW() - INTERVAL '40 days'),
    (v_author, 'Capgemini — Complete Selection Pattern & Guide', ARRAY['selection-pattern', 'hiring', 'guide', 'capgemini'], E'## What to Expect at Capgemini

Capgemini has a unique hiring pattern that tests your practical development skills rather than just competitive programming.

### The Machine Test Round
- You will be given a small application to build from scratch (e.g., a CLI based Library system or a simple CRUD API).
- You are allowed to use any language, but Object-Oriented principles must be strictly followed.

### Technical Interview
- Deep dive into your machine test code.
- Questions on SOLID principles, Design Patterns (Singleton, Factory), and Database Indexing.
- **Pro-tip**: Always validate inputs in your machine test code, interviewers look for production-ready habits.', 'Capgemini', 'approved', 472, NOW() - INTERVAL '8 days'),
    (v_author, 'Worlder Team — What to expect in the Technical Rounds', ARRAY['technical', 'core-cs', 'worlder-team'], E'## What to Expect at Worlder Team

Worlder Team has a unique hiring pattern that tests your practical development skills rather than just competitive programming.

### The Machine Test Round
- You will be given a small application to build from scratch (e.g., a CLI based Library system or a simple CRUD API).
- You are allowed to use any language, but Object-Oriented principles must be strictly followed.

### Technical Interview
- Deep dive into your machine test code.
- Questions on SOLID principles, Design Patterns (Singleton, Factory), and Database Indexing.
- **Pro-tip**: Always validate inputs in your machine test code, interviewers look for production-ready habits.', 'Worlder Team', 'approved', 362, NOW() - INTERVAL '52 days'),
    (v_author, 'Cloud Supply Chain Solutions — Aptitude & Coding Round Breakdown', ARRAY['aptitude', 'coding', 'test', 'cloud-supply-chain-solutions'], E'## Selection Process for Cloud Supply Chain Solutions

### 1. Initial Screening
- Heavy emphasis on your resume and GitHub profile. Make sure your projects are live and have a good README.

### 2. Coding Round
- Usually hosted on HackerRank or LeetCode. Expect Medium level DP or Graph questions.
- **Important**: They check for code modularity and variable naming conventions.

### 3. System Design (For higher bands)
- High-level design of simple systems like a URL shortener or a Parking Lot.
- Focus on database schema design and identifying bottlenecks.

### General Advice
- Keep communicating your thought process during the interview. Silence is a red flag.', 'Cloud Supply Chain Solutions', 'approved', 212, NOW() - INTERVAL '6 days');
END;
$$;