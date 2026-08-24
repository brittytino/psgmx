-- ============================================================
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
SELECT 'FILE COMPLETE: 24MX companies seeded.' AS status;