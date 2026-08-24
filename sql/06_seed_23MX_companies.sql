-- ============================================================
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