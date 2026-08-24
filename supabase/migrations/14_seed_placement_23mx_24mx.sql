-- ============================================================
-- PSGMX — 14_seed_placement_23mx_24mx.sql
-- ============================================================
-- Historical placement-drive company records for the 23MX and 24MX
-- (graduated) batches, sourced from 23MX.json / 24MX.json.
--
-- Regenerated from scratch via a fixed version of the old
-- sql/generate_placement_seeds.py (see sql/generate_placement_seeds.py,
-- also fixed in this same change). Original bug: looked up an admin user
-- via `WHERE role = 'hod' OR app_role = 'placement_rep'` — those columns
-- never existed on the live schema (the exact error this whole rebuild
-- was triggered by). Fixed to use role_label, and created_by falls back to
-- NULL (companies.created_by is nullable) rather than erroring, since this
-- seed runs before any real HOD/placement-rep has ever logged in.
--
-- Run AFTER 13_seed_students_25mx.sql.
-- ============================================================

DO $$
DECLARE
  admin_user_id UUID;
  batch_uuid    UUID;
BEGIN
  -- ── 24MX: 69 companies ──
  admin_user_id := (SELECT id FROM users WHERE role_label IN ('HOD', 'Faculty') LIMIT 1);
  batch_uuid := (SELECT id FROM batches WHERE batch_code = '24MX' LIMIT 1);

  -- Caterpillar Hackathon
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Caterpillar Hackathon',
    '2025-07-12'::DATE,
    ARRAY['Software Engineer'],
    '16.3 LPA',
    'CGPA: 7.5+',
    '[{"name": "Selection Process", "description": "3 (MCQ prelims, Hackathon, F2F interview)"}]'::JSONB,
    admin_user_id
  );

  -- PhonePe
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'PhonePe',
    '2025-07-23'::DATE,
    ARRAY['SE Testing'],
    '23 LPA',
    '-',
    '[{"name": "Selection Process", "description": "2 (Online screening/Aptitude, Technical interview)"}]'::JSONB,
    admin_user_id
  );

  -- Societe Generale
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Societe Generale',
    '2025-07-22'::DATE,
    ARRAY['Software Engineer'],
    '12 LPA',
    'minimum 70% across 10th, 12th, UG, PG without any backlogs',
    '[{"name": "Selection Process", "description": "2 (Aptitude+coding, Technical Interview)"}]'::JSONB,
    admin_user_id
  );

  -- Thorogood Associates Ltd, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Thorogood Associates Ltd, Bangalore',
    '2025-09-07T00:00:00'::DATE,
    ARRAY['Data and AI Consultant'],
    '15 LPA',
    '-',
    '[]'::JSONB,
    admin_user_id
  );

  -- The MathCompany - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'The MathCompany - Bangalore',
    '2025-07-26'::DATE,
    ARRAY['Trainee Analyst'],
    '5.5 LPA',
    'minimum 65% across 10th, 12th, UG, PG',
    '[{"name": "Selection Process", "description": "4 (Aptitude, Communication test, Technical interview, Fitment Interview)"}]'::JSONB,
    admin_user_id
  );

  -- EPAM Systems India Private Limited - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'EPAM Systems India Private Limited - Bangalore',
    '2025-07-19'::DATE,
    ARRAY['FTE'],
    '8.48 LPA',
    'Minimum 70% in graduation, minimum 60% in 10th and 12th, without any backlogs. No gap between 10th & 12th, maximum 1-year gap between 12th and graduation',
    '[{"name": "Selection Process", "description": "5 (MCQ & coding, GD, Technical interview, Managerial interview, HR interview)"}]'::JSONB,
    admin_user_id
  );

  -- FoodHub Software Solutions India Pvt Lts - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'FoodHub Software Solutions India Pvt Lts - Chennai',
    '2025-07-19'::DATE,
    ARRAY['Software Engineer'],
    '13 LPA',
    'GitHub profile with open source contribution + 2 year Bond',
    '[{"name": "Selection Process", "description": "3(OA, Technical interview, HR interview)"}]'::JSONB,
    admin_user_id
  );

  -- Mobicip Technologies Pvt Ltd - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Mobicip Technologies Pvt Ltd - Bangalore',
    '2025-11-08'::DATE,
    ARRAY['Developer'],
    'Intern Stipend: 15TPM, FTE: 8 LPA',
    '-',
    '[{"name": "Selection Process", "description": "3 (OA, Technical Interview, HR)"}]'::JSONB,
    admin_user_id
  );

  -- STGI Technologies consulting - Chandigarh
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'STGI Technologies consulting - Chandigarh',
    '2025-07-31'::DATE,
    ARRAY['-'],
    '8 LPA',
    'UG & PG CGPA: 8.5+',
    '[]'::JSONB,
    admin_user_id
  );

  -- IBM
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'IBM',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    '12 LPA',
    'CGPA: 7.0+',
    '[{"name": "Selection Process", "description": "3 (OA, Technical Interview, HR interview)"}]'::JSONB,
    admin_user_id
  );

  -- IBM India Pvt Ltd - Bangalore CIO
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'IBM India Pvt Ltd - Bangalore CIO',
    '2025-08-13'::DATE,
    ARRAY['Software Developer'],
    '9 LPA',
    'CGPA: 7.0+',
    '[]'::JSONB,
    admin_user_id
  );

  -- Jungroo AI labs
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Jungroo AI labs',
    CURRENT_DATE,
    ARRAY['Software Developer'],
    '5.4 LPA',
    'No active backlogs',
    '[{"name": "Selection Process", "description": "3(OOPS, DSA, Interview)"}]'::JSONB,
    admin_user_id
  );

  -- Deloitte Consulting Pvt Ltd USI Hyderabad
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Deloitte Consulting Pvt Ltd USI Hyderabad',
    '2025-08-26'::DATE,
    ARRAY['Analyst'],
    '8 LPA',
    'CGPA: 6.5+',
    '[{"name": "Selection Process", "description": "2(OA, virtual interview)"}]'::JSONB,
    admin_user_id
  );

  -- Deloitte Consulting Pvt Ltd India Hyderabad
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Deloitte Consulting Pvt Ltd India Hyderabad',
    '2025-03-09'::DATE,
    ARRAY['Analyst-Technology & Transformation - EAD - ADMM'],
    '8 LPA',
    'CGPA: 6.5+',
    '[{"name": "Selection Process", "description": "3(OA, GD, Interview)"}]'::JSONB,
    admin_user_id
  );

  -- Commvault
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Commvault',
    CURRENT_DATE,
    ARRAY['SDE & SDET'],
    '33 LPA',
    '-',
    '[{"name": "Selection Process", "description": "3(OA+coding, interview)"}]'::JSONB,
    admin_user_id
  );

  -- PSIOG digital
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'PSIOG digital',
    '2025-04-08T00:00:00'::DATE,
    ARRAY['Developer (grad, Honours, Super Honours)'],
    '(4.7, 6.2, 8.2) LPA',
    'CGPA: 7.0+, 27 months',
    '[{"name": "Selection Process", "description": "2(OA, Interview)"}]'::JSONB,
    admin_user_id
  );

  -- ZOHO Corporation
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'ZOHO Corporation',
    '2025-08-19'::DATE,
    ARRAY['Software Developer'],
    '(5.6, 7, 8.4) LPA',
    '-',
    '[{"name": "Selection Process", "description": "4(Written test, l"}]'::JSONB,
    admin_user_id
  );

  -- SAP Labs India Private Limited - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'SAP Labs India Private Limited - Bangalore',
    '2025-08-29'::DATE,
    ARRAY['Developer Associate'],
    '26 LPA',
    'Minimum 70% in 10th, 12th, ug, pg',
    '[{"name": "Selection Process", "description": "2 (OA, Interview)"}]'::JSONB,
    admin_user_id
  );

  -- American Megatrends India Private Limited - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'American Megatrends India Private Limited - Chennai',
    '2025-08-25'::DATE,
    ARRAY['System Software Engineer - Trainee'],
    '6 LPA',
    'No standing arrears',
    '[{"name": "Selection Process", "description": "Technical test basic, Technical test advance, adavnce technical interview 1, technical interview 2, hr interview"}]'::JSONB,
    admin_user_id
  );

  -- LTIMindtree Limited - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'LTIMindtree Limited - Bangalore',
    '2025-09-17'::DATE,
    ARRAY['Graduate Engineering Trainee'],
    '4 LPA',
    '60% in 10th, 12th, ug, pg. Not more than 2 year academic gap allowed',
    '[]'::JSONB,
    admin_user_id
  );

  -- Accenture - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Accenture - Bangalore',
    '2025-10-24'::DATE,
    ARRAY['Software Engineer'],
    '4.5 LPA, 6.5 LPA, 10 LPA',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- Infosys Limited - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Infosys Limited - Bangalore',
    '2025-12-09T00:00:00'::DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[{"name": "Selection Process", "description": "Coding Round ,Technical Interview"}]'::JSONB,
    admin_user_id
  );

  -- Walmart Global Tech India - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Walmart Global Tech India - Chennai',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- Palo Alto Networks - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Palo Alto Networks - Bangalore',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- Bounteous x Accolite - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Bounteous x Accolite - Bangalore',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- Celeredge Inc
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Celeredge Inc',
    '2025-07-10'::DATE,
    ARRAY['Engineer'],
    'Intern Stipend: 3-4 LPA, FTE: 10 - 12 LPA',
    '-',
    '[]'::JSONB,
    admin_user_id
  );

  -- Tata Consultancy Services, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Tata Consultancy Services, Chennai',
    '2025-06-11'::DATE,
    ARRAY['Software Engineer'],
    'Prime, Digital, Ninja (11.59, 7.39, 3.62) LPA',
    '60 % in 10th, 12th, ug, pg. No standing backlogs',
    '[]'::JSONB,
    admin_user_id
  );

  -- Oracle OFSS
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Oracle OFSS',
    '2025-09-10'::DATE,
    ARRAY['Associate Applications Developer'],
    '21-22 LPA',
    '-',
    '[{"name": "Selection Process", "description": "3 (OA, Interview, HR)"}]'::JSONB,
    admin_user_id
  );

  -- Autodesk India Pvt Ltd - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Autodesk India Pvt Ltd - Bangalore',
    '2025-10-15'::DATE,
    ARRAY['Software Development Engineer, Software QA Engineer'],
    'Intern Stipend: 55 TPM',
    '-',
    '[]'::JSONB,
    admin_user_id
  );

  -- Ramco Systems - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Ramco Systems - Chennai',
    '2025-09-29'::DATE,
    ARRAY['Software Engineer'],
    'Intern Stipend: 18 TPM, FTE: 8-11 LPA',
    'None',
    '[{"name": "Selection Process", "description": "5 (OA, Technical Assessment, Technical interview 1, Technical interview 2, HR)"}]'::JSONB,
    admin_user_id
  );

  -- Amazon Development Centre Pvt Ltd - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Amazon Development Centre Pvt Ltd - Bangalore',
    '2025-06-10'::DATE,
    ARRAY['Software Engineer'],
    'Intern Stipend: 1.1 LPM, FTE: 30 LPA',
    'None',
    '[{"name": "Selection Process", "description": "3 (OA, Technical Interview, HR)"}]'::JSONB,
    admin_user_id
  );

  -- Mphasis Limited - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Mphasis Limited - Bangalore',
    '2025-07-11'::DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- Logbase Technologies - Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Logbase Technologies - Coimbatore',
    '2025-07-10'::DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- Walkerscott Pvt Ltd
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Walkerscott Pvt Ltd',
    '2025-10-24'::DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- BoatMinds ai - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'BoatMinds ai - Chennai',
    '2025-08-10T00:00:00'::DATE,
    ARRAY['Internship'],
    '8 - 12 LPA',
    '-',
    '[]'::JSONB,
    admin_user_id
  );

  -- 7-Elevan - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    '7-Elevan - Bangalore',
    '2025-10-17'::DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- IBM Consulting - CIC - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'IBM Consulting - CIC - Bangalore',
    '2025-10-22'::DATE,
    ARRAY['Associate System Engineer'],
    'Intern Stipend: 25TPM, FTE: 5 LPA',
    '6 CGPA+ in PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Acies Global Pvt Ltd
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Acies Global Pvt Ltd',
    '2025-10-23'::DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- Appviewx Inc - Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Appviewx Inc - Coimbatore',
    '2025-10-29'::DATE,
    ARRAY['3 (Logical Assessment, GD, multiple Interviews)'],
    'Intern Stipend: 18 TPM, FTE: 6 LPA',
    '-',
    '[]'::JSONB,
    admin_user_id
  );

  -- FocusR Technologies - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'FocusR Technologies - Chennai',
    '2025-10-27'::DATE,
    ARRAY['Trainee Consultant'],
    'Intern Stipend: 7.5 TPM, FTE: 4 LPA',
    '70% + in 10th, 12th, ug, pg. 3 year bond',
    '[{"name": "Selection Process", "description": "3(OA, GD, Interview)"}]'::JSONB,
    admin_user_id
  );

  -- Pay Huddle - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Pay Huddle - Bangalore',
    '2025-10-28'::DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- Netscribes Analytics Private Limited - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Netscribes Analytics Private Limited - Bangalore',
    '2025-10-31'::DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[{"name": "Selection Process", "description": "3 (OA, GD, Interview)"}]'::JSONB,
    admin_user_id
  );

  -- Talview India Pvt Ltd - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Talview India Pvt Ltd - Bangalore',
    '2025-04-11'::DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- Eightfold AI India Pvt Ltd - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Eightfold AI India Pvt Ltd - Bangalore',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- DevRev - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'DevRev - Chennai',
    '2025-11-10'::DATE,
    ARRAY['Software Engineering Intern'],
    'Intern Stipend: 50TPM, FTE: 12 LPA fixed + ESOP',
    '7.5 CGPA',
    '[]'::JSONB,
    admin_user_id
  );

  -- CEI India Pvt Ltd - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'CEI India Pvt Ltd - Chennai',
    '2025-08-18'::DATE,
    ARRAY['Trainee software engineer'],
    'Intern Stipend: 10TPM, FTE: 5 LPA',
    '2 year Bond',
    '[]'::JSONB,
    admin_user_id
  );

  -- Josh Technologies Group - Haryana
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Josh Technologies Group - Haryana',
    '2025-08-18'::DATE,
    ARRAY['Software Developer'],
    'Intern Stipend: 22.5 TPM, FTE: 13.47 LPA',
    '-',
    '[{"name": "Selection Process", "description": "3(OA,subjective test, HR)"}]'::JSONB,
    admin_user_id
  );

  -- Justo Global - Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Justo Global - Coimbatore',
    '2025-08-26'::DATE,
    ARRAY['Full Stack Developer'],
    'Intern Stipend: 25TPM, FTE: 7LPA',
    '85%+ in PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- PSG Software Technologies
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'PSG Software Technologies',
    '2025-12-15'::DATE,
    ARRAY['Software Engineer'],
    'None',
    '-',
    '[]'::JSONB,
    admin_user_id
  );

  -- Camgemini
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Camgemini',
    '2025-10-12'::DATE,
    ARRAY['Analyst'],
    'ANALYST - ₹ 4.3L PA , Analyst (Differential offering at the Analyst level - ₹ 5.8L PA , Senior Analyst - ₹ 7.5L PA',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- Worlder Team Ptd Ltd
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Worlder Team Ptd Ltd',
    '2026-12-01'::DATE,
    ARRAY['Ui/Ux designer , Fontend Developer'],
    'Intern Stipend : 20 TPM, FTE : 6-7 LPA',
    'None',
    '[{"name": "Selection Process", "description": "Apptitude, Technical Interview"}]'::JSONB,
    admin_user_id
  );

  -- Cloud Supply Chain Solutions-CSCS- Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Cloud Supply Chain Solutions-CSCS- Chennai',
    '2026-08-01'::DATE,
    ARRAY['Software Engineer'],
    'Intern Stipend : 10 TPM, FTE : 3-4 LPA',
    '7.5 in PG , 60% in 10th and 12th',
    '[]'::JSONB,
    admin_user_id
  );

  -- Verticurl Marketing
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Verticurl Marketing',
    CURRENT_DATE,
    ARRAY['Associate Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- ShopUp India Pvt Ltd
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'ShopUp India Pvt Ltd',
    '2026-01-19'::DATE,
    ARRAY['Software Developement Engineer, Site Reliability Engineer, Data Scientist/ML Engineer , QA Automation Engineer,Data Analyst/Data Engineer'],
    'Stipend : 40T , FTE : 7-10 LPA',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- Kumaran Systems Pvt Ltd
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Kumaran Systems Pvt Ltd',
    '2026-06-03'::DATE,
    ARRAY['Engineer'],
    'Intern Stipend : 20T FTE : 7LPA',
    'None',
    '[{"name": "Selection Process", "description": "Aptitude,Technical Interview"}]'::JSONB,
    admin_user_id
  );

  -- rtCamp Solutions Pvt Ltd - Banglore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'rtCamp Solutions Pvt Ltd - Banglore',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- EPAM Systems India Private Limited - Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'EPAM Systems India Private Limited - Bangalore',
    CURRENT_DATE,
    ARRAY['Trainee'],
    'None',
    '70% in PG ,60% in 10th and 12th',
    '[]'::JSONB,
    admin_user_id
  );

  -- Citi India - Mumbai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Citi India - Mumbai',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- Ms Sambol Systems Pvt Ltd
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Ms Sambol Systems Pvt Ltd',
    '2025-12-12'::DATE,
    ARRAY['Software Engineer'],
    'Intern Stipend : 30 TPM, FTE : 7 LPA',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- 7EDGE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    '7EDGE',
    '2026-01-26'::DATE,
    ARRAY['IT-Tools & Automation'],
    'Intern 9T-33T & FTE : 8LPA',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- Super AGI
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Super AGI',
    '2026-02-16'::DATE,
    ARRAY['SDE'],
    'FTE - 4LPA-5LPA',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- Omnicom Global Solutions
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Omnicom Global Solutions',
    '2026-02-24'::DATE,
    ARRAY['Graduate Trainee - Media Solutions'],
    'Intern : 14T, FTE : 5LPA',
    'None',
    '[{"name": "Selection Process", "description": "Aptitude+Coding round"}]'::JSONB,
    admin_user_id
  );

  -- Morphle Labs
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Morphle Labs',
    '2026-02-16'::DATE,
    ARRAY['Software Support Intern'],
    'Intern: 21T FTE : 4-6LPA',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- ZOHO Corporation - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'ZOHO Corporation - Chennai',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- Infosys Equinox
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Infosys Equinox',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- QLeap10X LLP - Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'QLeap10X LLP - Coimbatore',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    'None',
    '75% in PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Annam AI - IIT Ropar
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Annam AI - IIT Ropar',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- PayFx
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'PayFx',
    CURRENT_DATE,
    ARRAY['Software Engineer'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- Mako IT Lab - Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Mako IT Lab - Chennai',
    CURRENT_DATE,
    ARRAY['Data Analyst'],
    'None',
    'None',
    '[]'::JSONB,
    admin_user_id
  );

  -- ── 23MX: 75 companies ──
  admin_user_id := (SELECT id FROM users WHERE role_label IN ('HOD', 'Faculty') LIMIT 1);
  batch_uuid := (SELECT id FROM batches WHERE batch_code = '23MX' LIMIT 1);

  -- CATERPILLAR CODEATHON
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'CATERPILLAR CODEATHON',
    '2024-07-05'::DATE,
    ARRAY['SOFTWARE ENGINEER'],
    '14 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "3-( MCQ prelims,  Hackathon round, F2F interview)"}]'::JSONB,
    admin_user_id
  );

  -- TheMathCompany TRIATHLON
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'TheMathCompany TRIATHLON',
    '2024-07-07'::DATE,
    ARRAY['TRAINEE ANALYST'],
    '5.5LPA',
    'ABOVE 7.5 CGPA (PG)',
    '[{"name": "Selection Process", "description": "3 ( APTITUDE, COMMUNICATION, CASE STUDY - ALL ONLINE)"}]'::JSONB,
    admin_user_id
  );

  -- GOOGLE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'GOOGLE',
    '2024-07-05'::DATE,
    ARRAY['SOFTWARE ENGINEER'],
    '37 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "5.0"}]'::JSONB,
    admin_user_id
  );

  -- COMMVAULT
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'COMMVAULT',
    '2024-07-10'::DATE,
    ARRAY['SDE'],
    '33 LPA',
    'ABOVE 7.0 CGPA (PG)',
    '[{"name": "Selection Process", "description": "-"}]'::JSONB,
    admin_user_id
  );

  -- PHONEPE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'PHONEPE',
    '2024-07-20'::DATE,
    ARRAY['Software Engineering In Testing'],
    '23 LPA',
    'ABOVE 6, NO ARREARS',
    '[{"name": "Selection Process", "description": "4 - ( Coding, Techincal interview, HR interview, 2nd HR interview )"}]'::JSONB,
    admin_user_id
  );

  -- THOROGOOD ASSOCIATES
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'THOROGOOD ASSOCIATES',
    '2024-07-13'::DATE,
    ARRAY['Data And AI Consultant'],
    '15LPA',
    'ABOVE 7.5 CGPA (UG & PG) ',
    '[{"name": "Selection Process", "description": "3 - ( Advanced Aptitude round along with essay writing,  HR interview, interview at Thorogood campus in Bangalore"}]'::JSONB,
    admin_user_id
  );

  -- SOCIETE GENERAL CAMPUS DRIVE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'SOCIETE GENERAL CAMPUS DRIVE',
    '2024-07-15'::DATE,
    ARRAY['Software Engineer'],
    '12 LPA',
    'ABOVE 7 CGPA (10,12,UG,PG)',
    '[{"name": "Selection Process", "description": "2 - ( Online coding round, F2F interview )"}]'::JSONB,
    admin_user_id
  );

  -- V2K AI  COIMBATORE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'V2K AI  COIMBATORE',
    '2024-07-16'::DATE,
    ARRAY['Software Engineer'],
    '20LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "3 - ( Coding round, Application development / Hackathon, Interview )"}]'::JSONB,
    admin_user_id
  );

  -- INFOSYS LIMITED BANGALORE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'INFOSYS LIMITED BANGALORE',
    '2024-07-16'::DATE,
    ARRAY['Specialist Programmer'],
    '9.5 LPA',
    'ABOVE 60 / 6 CGPA  ( 10,12,UG,PG)',
    '[{"name": "Selection Process", "description": "2 ( online coding round, F2F interview at any one company locations )"}]'::JSONB,
    admin_user_id
  );

  -- ACCENTURE BANGALORE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'ACCENTURE BANGALORE',
    '2024-10-07'::DATE,
    ARRAY['Associate Software Engineer & 
Advanced Associate Software Engineer'],
    '4.5 LPA - 6.5LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "First Round: Aptitude Second Round: Coding 2 qns Third Round: Communication Round  Fourth Round: Interview "}]'::JSONB,
    admin_user_id
  );

  -- IBM India Pvt. Ltd., Bangalore (India Systems Development Lab)
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'IBM India Pvt. Ltd., Bangalore (India Systems Development Lab)',
    '2024-08-13'::DATE,
    ARRAY['Software Engineer'],
    '12 LPA',
    'ABOVE 7 CGPA (PG)',
    '[{"name": "Selection Process", "description": "2 - ( Online coding test, Interview )"}]'::JSONB,
    admin_user_id
  );

  -- CATERPILLAR ENGINEERING INDIA PVT LTD ( CAT DIGITAL)
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'CATERPILLAR ENGINEERING INDIA PVT LTD ( CAT DIGITAL)',
    '2024-08-06'::DATE,
    ARRAY['Developer /  
project management /
 product manangement'],
    '14 LPA',
    'ABOVE 7.5 CGPA (PG)',
    '[{"name": "Selection Process", "description": "4 ( MCQ test, Coding round, Group discussion, F2F interview )"}]'::JSONB,
    admin_user_id
  );

  -- Zoho Corporation, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Zoho Corporation, Chennai',
    '2024-08-01'::DATE,
    ARRAY['Software Developer'],
    '8.4 LPA , 7 LPA ,5.6 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "4 ( written aptitude and C technincal questions,  coding, advanced coding, HR interview )"}]'::JSONB,
    admin_user_id
  );

  -- Zoho Corporation, Chennai ( 2nd time)
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Zoho Corporation, Chennai ( 2nd time)',
    '2024-08-01'::DATE,
    ARRAY['Software Developer'],
    '8.4 LPA , 7 LPA ,5.6 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "4 ( written aptitude and C technincal questions,  coding, advanced coding, HR interview )"}]'::JSONB,
    admin_user_id
  );

  -- Tech Mahindra Ltd., Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Tech Mahindra Ltd., Bangalore',
    '2024-08-01'::DATE,
    ARRAY['Developer / Supercoder'],
    '3.3 LPA - 5.5 LPA',
    'ABOVE 7.0 ( 10,12 UG, PG )',
    '[]'::JSONB,
    admin_user_id
  );

  -- Quantiphi Analytics , Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Quantiphi Analytics , Bangalore',
    '2024-08-13'::DATE,
    ARRAY['ENGINEER'],
    '6 LPA',
    'ABOVE 7.0 ( 10,12 UG, PG ) 
and no history of arrears',
    '[{"name": "Selection Process", "description": "4 - ( online coding test which had aptitude,OS,JS,networks, DBMS  + 3 coding questions second round was F2F interview / first techincal round  Third round was Second technical round Fourth round was HR round "}]'::JSONB,
    admin_user_id
  );

  -- Logbase Technologies, Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Logbase Technologies, Coimbatore',
    '2024-08-23'::DATE,
    ARRAY['Full stack developer'],
    '7 LPA',
    '70 % ( UG & PG )',
    '[{"name": "Selection Process", "description": " 5 - ( Aptitude and coding snippets + 3 coding questions,  F2F interview,  hackathon + 2 Coding questions round,  Presentation, HR round )  "}]'::JSONB,
    admin_user_id
  );

  -- Deloitte Consulting India Pvt. Ltd., Hyderabad ( USI )
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Deloitte Consulting India Pvt. Ltd., Hyderabad ( USI )',
    '2024-08-26'::DATE,
    ARRAY['Associate Analyst'],
    '7.6 LPA',
    'ABOVE 6.0 , No arrears',
    '[{"name": "Selection Process", "description": "2 - ( online aptitude, english comprehension, coding  and then F2F interview)"}]'::JSONB,
    admin_user_id
  );

  -- Vanenburg Software (India) Private Limited, Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Vanenburg Software (India) Private Limited, Coimbatore',
    '2024-09-10'::DATE,
    ARRAY['Associate Software Engineer '],
    '8 LPA',
    'ABOVE 7.0 CGPA',
    '[{"name": "Selection Process", "description": "1. Online Test/ pen & paper Aptitude, English Skills and Technical  2. Technical Interview- to test coding skills.  3. Techno Managerial cum HR Interview"}]'::JSONB,
    admin_user_id
  );

  -- RND Softech Pvt Ltd
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'RND Softech Pvt Ltd',
    '2024-08-23'::DATE,
    ARRAY['ENGINEER'],
    '8 LPA - 10 LPA',
    'ABOVE 80 % / 8 CGPA',
    '[{"name": "Selection Process", "description": "2 ( 1st round - 20 mcqs based on DSA and ML.   2nd round - self intro plus sharing of experience.  )"}]'::JSONB,
    admin_user_id
  );

  -- Tata Consultancy Services ( TCS NQT )
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Tata Consultancy Services ( TCS NQT )',
    '2024-12-06'::DATE,
    ARRAY['NInja
Digital
Prime'],
    'Prime  11.5 LPA

Digital 7.6 LPA

Ninja  3.5 LPA',
    'ABOVE 60% / 6.0 CGPA',
    '[]'::JSONB,
    admin_user_id
  );

  -- Western DIgital, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Western DIgital, Bangalore',
    '2024-08-23'::DATE,
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
  );

  -- LTIMIndtree Limited , Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'LTIMIndtree Limited , Bangalore',
    '2024-10-21'::DATE,
    ARRAY['Graduate Engineer Trainee'],
    '4.1 LPA',
    'ABOVE 60% / 6.0 CGPA ( 10,12,UG,PG)',
    '[{"name": "Selection Process", "description": "1st round included  Aptitude + Technical MCQs + Communication Assessment   2nd Round - Technical HR  3rd Round - Final HR (General questions)"}]'::JSONB,
    admin_user_id
  );

  -- UNO MINDS
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'UNO MINDS',
    '2024-08-24'::DATE,
    ARRAY['Software Engineer'],
    'None',
    'NO CRITERIA',
    '[]'::JSONB,
    admin_user_id
  );

  -- THE MATHCOMPANY CAMPUS DRIVE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'THE MATHCOMPANY CAMPUS DRIVE',
    '2024-08-19'::DATE,
    ARRAY['Trainee Analyst'],
    '5.5 LPA',
    'None',
    '[{"name": "Selection Process", "description": "3 ( APTITUDE, COMMUNICATION, CASE STUDY - ALL ONLINE)"}]'::JSONB,
    admin_user_id
  );

  -- SOCIETE GENERAL HACKATHON
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'SOCIETE GENERAL HACKATHON',
    '2024-07-08'::DATE,
    ARRAY['Trainee Analyst'],
    '12 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "2 - ( First Hackathon round in which 3 problem statements were given,  had to submit demo along with github link, second round  was ppt presentation about the application developed ) "}]'::JSONB,
    admin_user_id
  );

  -- C5I AI COIMBATORE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'C5I AI COIMBATORE',
    '2024-09-18'::DATE,
    ARRAY['Application Developers'],
    '7 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "Round 1: create a chatbot and ppt on it using  the requirements and tools given by the company  Round 2: Group discussion   Round 3: Technical interview   Round 4: HR interview"}]'::JSONB,
    admin_user_id
  );

  -- VISA BANGALORE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'VISA BANGALORE',
    '2024-09-17'::DATE,
    ARRAY['Software engineer'],
    '34 LPA',
    '70 % ( UG & PG )',
    '[{"name": "Selection Process", "description": "Round 1 - Online Coding Test  Round 2 : Technical Interview   Round 3 : Technical Interview   Round 4 : Managerial Interview  "}]'::JSONB,
    admin_user_id
  );

  -- ZScaler
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'ZScaler',
    '2024-09-14'::DATE,
    ARRAY['Intern - software development'],
    '75 TPM',
    '70 % ( UG & PG )',
    '[{"name": "Selection Process", "description": "-"}]'::JSONB,
    admin_user_id
  );

  -- CEI  INDIA PVT LTD
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'CEI  INDIA PVT LTD',
    '2024-11-06'::DATE,
    ARRAY['Trainee Software Engineer'],
    '5 LPA',
    '60 % ( UG & PG )',
    '[{"name": "Selection Process", "description": "Round 1-Written test Round-2 Technical interview Round 3- HR interview "}]'::JSONB,
    admin_user_id
  );

  -- INCTURE TECHNOLOGIES
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'INCTURE TECHNOLOGIES',
    '2024-09-28'::DATE,
    ARRAY['Associate Software Engineer - Trainee'],
    '8 LPA',
    '65% (10th, 12th, UG,PG)',
    '[{"name": "Selection Process", "description": "Round -1: Aptitude+ coding  Round-2 : System Design  Round 3: Technical Interview  Round 4: HR Interview"}]'::JSONB,
    admin_user_id
  );

  -- LOYALITICS CONSULTING, BANGALORE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'LOYALITICS CONSULTING, BANGALORE',
    '2024-09-25'::DATE,
    ARRAY['Engineer'],
    '6 LPA',
    'NO CRITERIA',
    '[]'::JSONB,
    admin_user_id
  );

  -- CROSSBOW LABS LLP, BANGALORE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'CROSSBOW LABS LLP, BANGALORE',
    '2024-10-02'::DATE,
    ARRAY['Engineer'],
    '7 LPA',
    'NO CRITERIA',
    '[]'::JSONB,
    admin_user_id
  );

  -- CAPGEMINI TECHNOLOGY SERVICES, BANGALORE
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'CAPGEMINI TECHNOLOGY SERVICES, BANGALORE',
    '2024-11-16'::DATE,
    ARRAY['ANALYST - ₹ 4.3L PA

Analyst (Differential offering
 at the Analyst level - ₹ 5.8L PA

Senior Analyst -  ₹ 7.5L PA'],
    '4.3 LPA - 7.5 LPA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "Assessment 1 Technical MCQ and Written English Test (WET)   Assessment 2 Coding Assessment  Assessment 3 Spoken English Assessment Mode-Virtual  F2F interview"}]'::JSONB,
    admin_user_id
  );

  -- FLEX TECHNOLOGIES
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'FLEX TECHNOLOGIES',
    '2024-11-26'::DATE,
    ARRAY['Associate Software Engineer - IT'],
    '₹ 5.2L PA',
    'ABOVE 80% / 8 CGPA ',
    '[{"name": "Selection Process", "description": "Round 1: Online Test (MCQs) Round 2 : Technical Round 1 Round 3 :  Technical Round 2 Round 4: HR round"}]'::JSONB,
    admin_user_id
  );

  -- Wavicle Data Solutions, Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Wavicle Data Solutions, Coimbatore',
    '2024-10-29'::DATE,
    ARRAY['Engineer'],
    '6LPA - 8LPA',
    'No Minimum criteria for marks but 
should have no standing arrears

History of Backlogs allowed',
    '[{"name": "Selection Process", "description": "1. Round 1: Written test   2. Round 2: Group discussion  3. Round 3: Technical interview .  4. Round 4: Managerial interview "}]'::JSONB,
    admin_user_id
  );

  -- Ankercloud Technologies,Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Ankercloud Technologies,Bangalore',
    '2024-10-13'::DATE,
    ARRAY['Engineer'],
    '6 LPA',
    'NO CRITERIA',
    '[]'::JSONB,
    admin_user_id
  );

  -- Mobicip Technologies Pvt. Ltd., Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Mobicip Technologies Pvt. Ltd., Bangalore',
    '2024-11-27'::DATE,
    ARRAY['Engineer'],
    '8 LPA',
    '70% / 7 CGPA in UG and PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Commonwealth Bank of Australia, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Commonwealth Bank of Australia, Bangalore',
    '2024-10-17'::DATE,
    ARRAY['Graduate Software Engineer'],
    '₹ 10L - 12L PA',
    '70% / 7 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "-"}]'::JSONB,
    admin_user_id
  );

  -- Insight Global, Inc, Hyderabad
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Insight Global, Inc, Hyderabad',
    '2024-10-18'::DATE,
    ARRAY['intern '],
    '6 LPA',
    '80% / 8 CGPA in UG and PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- MSG Global Solutions India Pvt Ltd, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'MSG Global Solutions India Pvt Ltd, Bangalore',
    '2024-10-20'::DATE,
    ARRAY['Multiple Profiles'],
    '6.5 LPA',
    '70% / 7 CGPA in UG and PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Kovai.co., Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Kovai.co., Coimbatore',
    '2024-10-29'::DATE,
    ARRAY['Intern – Product Management

Intern – Data Scientist'],
    '6 LPA',
    '60% / 6 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "Telephonic Interview  Technical Interview  Machine Test Personal Interview"}]'::JSONB,
    admin_user_id
  );

  -- Ford Motor Pvt Ltd., Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Ford Motor Pvt Ltd., Chennai',
    '2024-11-22'::DATE,
    ARRAY['GET'],
    '6.3L - 9L PA',
    '60% / 6 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "Round 1: Online assignment with 3 sections 1. Aptitude 2. Technical 3. Code Round 2: Interview + HR"}]'::JSONB,
    admin_user_id
  );

  -- ICU Medical India LLP, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'ICU Medical India LLP, Chennai',
    '2024-11-12'::DATE,
    ARRAY['Engineer'],
    '25T PM',
    '70% / 7 CGPA in UG and PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- EPAM Systems India Private Limited, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'EPAM Systems India Private Limited, Bangalore',
    '2024-11-12'::DATE,
    ARRAY['Sofware Engineer'],
    '8LPA',
    '70% / 7 CGPA in UG and PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Codewalla Software Development Pvt. Ltd., Pune
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Codewalla Software Development Pvt. Ltd., Pune',
    '2024-11-13'::DATE,
    ARRAY['Software Development Engineer - Intern / 
Software Development Engineer - Trainee'],
    '9 LPA',
    '75 % or 7.5 CGPA in 10th, 12th, UG, PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Hyundai Motor India Limited, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Hyundai Motor India Limited, Chennai',
    '2024-11-15'::DATE,
    ARRAY['GET and PGET'],
    '8 LPA - 9.25 LPA',
    '60 % or 6 CGPA in 10th, 12th, UG, PG',
    '[{"name": "Selection Process", "description": "-"}]'::JSONB,
    admin_user_id
  );

  -- Justo Global, Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Justo Global, Coimbatore',
    '2024-11-19'::DATE,
    ARRAY['Intern Developers'],
    '7  - 13 LPA.',
    '80% / 8 CGPA in UG and PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Ernst & Young Services Pvt Ltd,Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Ernst & Young Services Pvt Ltd,Bangalore',
    '2024-11-21'::DATE,
    ARRAY['Associate Consultant'],
    '9.2L PA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "-"}]'::JSONB,
    admin_user_id
  );

  -- Mobicip Technologies Pvt. Ltd., Bangalore ( new role )
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Mobicip Technologies Pvt. Ltd., Bangalore ( new role )',
    '2024-12-19'::DATE,
    ARRAY['Technical Support Engineer'],
    '5 LPA',
    'NO CRITERIA',
    '[]'::JSONB,
    admin_user_id
  );

  -- Kumaran System Pvt.Ltd, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Kumaran System Pvt.Ltd, Chennai',
    '2024-03-12T00:00:00'::DATE,
    ARRAY['Software Developer'],
    '7 LPA',
    '60% / 6 CGPA in UG and PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- AtoB Pvt.Ltd, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'AtoB Pvt.Ltd, Bangalore',
    '2024-03-12T00:00:00'::DATE,
    ARRAY['Software Engineer'],
    '27 LPA',
    '80% / 8 CGPA in UG and PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- L7 Informatics India Pvt Ltd, Bengalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'L7 Informatics India Pvt Ltd, Bengalore',
    '2024-12-21'::DATE,
    ARRAY['Software Engineer'],
    '6.5L PA',
    'NO CRITERIA',
    '[{"name": "Selection Process", "description": "3.0"}]'::JSONB,
    admin_user_id
  );

  -- Computer Age Management Services Pvt Ltd
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Computer Age Management Services Pvt Ltd',
    '2024-12-12T00:00:00'::DATE,
    ARRAY['PGET'],
    '6 LPA',
    'NO CRITERIA',
    '[]'::JSONB,
    admin_user_id
  );

  -- Turing, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Turing, Bangalore',
    '2024-12-17'::DATE,
    ARRAY['Multiple Profiles'],
    '7.5 LPA',
    '60 % or 6 CGPA in 10th, 12th, UG, PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Gyansys infotech PVT LTD Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Gyansys infotech PVT LTD Bangalore',
    '2024-12-23'::DATE,
    ARRAY['Engineer'],
    '6 LPA',
    'NO CRITERIA',
    '[]'::JSONB,
    admin_user_id
  );

  -- BNP Paribas Bangalore ( Hackathon )
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'BNP Paribas Bangalore ( Hackathon )',
    '2025-01-18'::DATE,
    ARRAY['NA'],
    'NA',
    'NA',
    '[]'::JSONB,
    admin_user_id
  );

  -- Bouteous X Accolite, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Bouteous X Accolite, Bangalore',
    '2025-03-01T00:00:00'::DATE,
    ARRAY['Software Engineer'],
    '8LPA',
    '60 % or 6 CGPA in 10th, 12th, UG, PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Intellect Design Arena, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Intellect Design Arena, Chennai',
    '2024-12-24'::DATE,
    ARRAY['Associate Consultant 
(Java Full Stack Developer)'],
    '4LPA',
    '60% / 6 CGPA in  PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Kalvium, Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Kalvium, Coimbatore',
    '2025-06-01T00:00:00'::DATE,
    ARRAY['Program Architect'],
    '10LPA',
    'NO CRITERIA',
    '[]'::JSONB,
    admin_user_id
  );

  -- Saama Technologies , Coimbatore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Saama Technologies , Coimbatore',
    '2025-01-31'::DATE,
    ARRAY['Engineer'],
    '4.2lpa',
    '70% 0r 7CGPA in PG',
    '[{"name": "Selection Process", "description": "4.0"}]'::JSONB,
    admin_user_id
  );

  -- Ivanti Technology India, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Ivanti Technology India, Bangalore',
    '2025-01-02T00:00:00'::DATE,
    ARRAY['Engineer'],
    '5 LPA',
    '80% / 8 CGPA in UG and PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Virtusa , Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Virtusa , Chennai',
    '2025-02-02T00:00:00'::DATE,
    ARRAY['Associate Software Engineer '],
    '5 LPA',
    '80% / 8 CGPA in UG and PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Mindgate Solutions, Pvt.Ltd, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Mindgate Solutions, Pvt.Ltd, Chennai',
    '2025-07-02T00:00:00'::DATE,
    ARRAY['Trainee Developer'],
    '5LPA',
    '70% 0r 7CGPA in PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Cotiviti India Pvt. Ltd., Pune
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Cotiviti India Pvt. Ltd., Pune',
    '2025-02-17'::DATE,
    ARRAY['Engineer'],
    '5.5 LPA',
    '70% 0r 7CGPA in PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Annalect India, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Annalect India, Bangalore',
    '2025-04-19'::DATE,
    ARRAY['Graduate Trainee (GT) – Media Services'],
    '4.5 LPA',
    '65% / 6.5 CGPA in  PG',
    '[{"name": "Selection Process", "description": "Aptitude , Technical Interview"}]'::JSONB,
    admin_user_id
  );

  -- Goldman Sachs Technology Division, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Goldman Sachs Technology Division, Bangalore',
    '2025-04-04T00:00:00'::DATE,
    ARRAY['Software Engineer'],
    '30 LPA',
    'NO CRITERIA',
    '[]'::JSONB,
    admin_user_id
  );

  -- IRIS Business Services Limited ,Mumbai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'IRIS Business Services Limited ,Mumbai',
    '2025-12-03T00:00:00'::DATE,
    ARRAY['Software Engineer'],
    '3.8L - 8L PA',
    '70% 0r 7CGPA in PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Light Mechanics Pvt Ltd, Bangalore
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Light Mechanics Pvt Ltd, Bangalore',
    '2025-03-21'::DATE,
    ARRAY['Engineer'],
    '3 LPA',
    'NO CRITERIA',
    '[]'::JSONB,
    admin_user_id
  );

  -- NCompass TechStudio, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'NCompass TechStudio, Chennai',
    '2025-03-19'::DATE,
    ARRAY['Software Developer'],
    '6.5L PA',
    '70% 0r 7CGPA in PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- FocusR Technologies,Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'FocusR Technologies,Chennai',
    '2025-04-21'::DATE,
    ARRAY['Trainee Consultant / Trainee Developer.'],
    '4 LPA',
    '70% / 7 CGPA in UG and PG',
    '[{"name": "Selection Process", "description": "Aptitude , Group Discussion , Technical Interview"}]'::JSONB,
    admin_user_id
  );

  -- Nibana Solutions Pvt.Ltd, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Nibana Solutions Pvt.Ltd, Chennai',
    '2025-04-03'::DATE,
    ARRAY['Software Engineer'],
    '6 - 7 LPA',
    '70% 0r 7CGPA in PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Zeetaminds Technologies Pvt Ltd, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Zeetaminds Technologies Pvt Ltd, Chennai',
    '2025-04-04'::DATE,
    ARRAY['Software Developer'],
    '6 LPA',
    '70% / 7 CGPA in UG and PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Testpress, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Testpress, Chennai',
    '2025-04-19'::DATE,
    ARRAY['Software Engineer'],
    '3.3 LPA',
    '70% 0r 7CGPA in PG',
    '[]'::JSONB,
    admin_user_id
  );

  -- Sandhata Technologies Pvt.Ltd, Chennai
  INSERT INTO companies (batch_id, name, visit_date, roles_offered, package_band, eligibility, rounds, created_by)
  VALUES (
    batch_uuid,
    'Sandhata Technologies Pvt.Ltd, Chennai',
    '2025-04-24'::DATE,
    ARRAY['Software Engineer'],
    '5 LPA',
    '70% 0r 7CGPA in PG',
    '[]'::JSONB,
    admin_user_id
  );

END $$;

DO $$
BEGIN
    RAISE NOTICE '✅ 14_seed_placement_23mx_24mx.sql complete — 69 (24MX) + 75 (23MX) companies seeded.';
    RAISE NOTICE 'Full rebuild sequence complete.';
END $$;
