-- ============================================================
-- PSGMX — 38_update_26mxg2_profiles.sql
-- ============================================================
-- Seeds all 58 26MX G2 students (26MX301-26MX358) into the whitelist
-- so every student can log in via OTP.
-- Also backfills github_url, leetcode_username, linkedin_url into the
-- users table for students who have already signed in.
--
-- whitelist columns: email, personal_email, college_email, name,
--   reg_no, batch, batch_id, team_id, roles, leetcode_username
-- users columns: email, reg_no, github_url, linkedin_url, leetcode_username
--
-- Safe to run multiple times (idempotent). Run AFTER 16_seed_students_26mx.sql
-- ============================================================

BEGIN;

-- ── 1. Upsert all 58 G2 students into whitelist ──────────────────────────────
INSERT INTO public.whitelist AS existing (
    email, personal_email, college_email, name, reg_no, batch, batch_id, team_id, roles, leetcode_username
) VALUES
('abiramidevasenapathy@gmail.com',    'abiramidevasenapathy@gmail.com',    '26mx301@psgtech.ac.in', 'ABIRAMI D',                    '26MX301', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Abirami_Devasenapathy'),
('balajiaditri28@gmail.com',          'balajiaditri28@gmail.com',          '26mx302@psgtech.ac.in', 'ADITRI BALAJI',                 '26MX302', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'aditribk'),
('aishwaryaaselvaraj@gmail.com',      'aishwaryaaselvaraj@gmail.com',      '26mx303@psgtech.ac.in', 'AISHWARYAA S K',                '26MX303', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Aishwaryaa_selvaraj'),
('akileshaki411@gmail.com',           'akileshaki411@gmail.com',           '26mx304@psgtech.ac.in', 'AKILESH N',                     '26MX304', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'akileshaki'),
('ananthan672020@gmail.com',          'ananthan672020@gmail.com',          '26mx305@psgtech.ac.in', 'ANANTHA LAKSHMI A',             '26MX305', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, NULL),
('ashritaa2809@gmail.com',            'ashritaa2809@gmail.com',            '26mx306@psgtech.ac.in', 'ASHRITAA NAVANEETHA KRISHNAN',  '26MX306', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Ashritaa'),
('gkashwinkumar@gmail.com',           'gkashwinkumar@gmail.com',           '26mx307@psgtech.ac.in', 'ASHWIN KUMAR G K',              '26MX307', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'bRaoPlMCd1'),
('asina200107@gmail.com',             'asina200107@gmail.com',             '26mx308@psgtech.ac.in', 'ASINA P',                       '26MX308', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'AsinaP'),
('aswathck28@gmail.com',              'aswathck28@gmail.com',              '26mx309@psgtech.ac.in', 'ASWATH NARAYANAN A C',          '26MX309', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, NULL),
('balaaakash2005@gmail.com',          'balaaakash2005@gmail.com',          '26mx310@psgtech.ac.in', 'BALA SUBRAMANIAN B',            '26MX310', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'bala_120405'),
('chakravarthydeepan584@gmail.com',   'chakravarthydeepan584@gmail.com',   '26mx311@psgtech.ac.in', 'DEEPAN CHAKRAVARTHI S',         '26MX311', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Deepan_chakravarthi'),
('dhanyalakshmi0103@gmail.com',       'dhanyalakshmi0103@gmail.com',       '26mx312@psgtech.ac.in', 'DHANYA LAKSHMI M U',            '26MX312', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, NULL),
('dharshinigsvd@gmail.com',           'dharshinigsvd@gmail.com',           '26mx313@psgtech.ac.in', 'DHARSHINI G S',                 '26MX313', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, NULL),
('rdharshinim@gmail.com',             'rdharshinim@gmail.com',             '26mx314@psgtech.ac.in', 'DHARSHINI R',                   '26MX314', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'R_DHARSHINI17'),
('dharunyamanikandan@gmail.com',      'dharunyamanikandan@gmail.com',      '26mx315@psgtech.ac.in', 'DHARUNYA M P',                  '26MX315', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, NULL),
('elakkiyac43@gmail.com',             'elakkiyac43@gmail.com',             '26mx316@psgtech.ac.in', 'ELAKKIYA C',                    '26MX316', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'ElakkiyaC'),
('esakirahul2@gmail.com',             'esakirahul2@gmail.com',             '26mx317@psgtech.ac.in', 'ESAKI RAHUL M',                 '26MX317', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, NULL),
('gayathrijanagaraj@gmail.com',       'gayathrijanagaraj@gmail.com',       '26mx318@psgtech.ac.in', 'GAYATHRI J',                    '26MX318', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Gayu1803'),
('jairussj24@gmail.com',              'jairussj24@gmail.com',              '26mx319@psgtech.ac.in', 'JAIRUS S',                      '26MX319', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Jairussj'),
('jeevashanmugam7774@gmail.com',      'jeevashanmugam7774@gmail.com',      '26mx320@psgtech.ac.in', 'JEEVA S',                       '26MX320', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Jeeva7774'),
('joshikaramadoss29@gmail.com',       'joshikaramadoss29@gmail.com',       '26mx321@psgtech.ac.in', 'JOSHIKA R',                     '26MX321', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'joshikaa200629'),
('kalaranirv@gmail.com',              'kalaranirv@gmail.com',              '26mx322@psgtech.ac.in', 'KALARANI R',                    '26MX322', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Kalarani04'),
('kavipriyad1310@gmail.com',          'kavipriyad1310@gmail.com',          '26mx323@psgtech.ac.in', 'KAVI PRIYA DHARSHINI B',        '26MX323', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Kavi_1310'),
('keerthanaashokkumar25@gmail.com',   'keerthanaashokkumar25@gmail.com',   '26mx324@psgtech.ac.in', 'KEERTHANA A R',                 '26MX324', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'KeerthanaAR25'),
('kkirubhakaran1@gmail.com',          'kkirubhakaran1@gmail.com',          '26mx325@psgtech.ac.in', 'KIRUBHAKARAN K',                '26MX325', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, NULL),
('kriuthiyogitha@gmail.com',          'kriuthiyogitha@gmail.com',          '26mx326@psgtech.ac.in', 'KRIUTHI YOGITHA A',             '26MX326', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'KriuthiYogitha'),
('meenakshimurali30@gmail.com',       'meenakshimurali30@gmail.com',       '26mx327@psgtech.ac.in', 'MEENAKSHI M',                   '26MX327', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'meenakshimurali30'),
('mounishamuthusamy@gmail.com',       'mounishamuthusamy@gmail.com',       '26mx328@psgtech.ac.in', 'MOUNISHA M',                    '26MX328', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'mounisha2006'),
('nabilabanu7618@gmail.com',          'nabilabanu7618@gmail.com',          '26mx329@psgtech.ac.in', 'NABILA BANU R',                 '26MX329', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'nabilabanu_12'),
('nadhishbaskar16@gmail.com',         'nadhishbaskar16@gmail.com',         '26mx330@psgtech.ac.in', 'NADHISH B',                     '26MX330', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Nadhish_B'),
('nareshwaran703@gmail.com',          'nareshwaran703@gmail.com',          '26mx331@psgtech.ac.in', 'NARESHWARAN J',                 '26MX331', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'nareshwaran25'),
('muralidharannatesh@gmail.com',      'muralidharannatesh@gmail.com',      '26mx332@psgtech.ac.in', 'NATESH M',                      '26MX332', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'muralidharannatesh'),
('navyasureshkumar505@gmail.com',     'navyasureshkumar505@gmail.com',     '26mx333@psgtech.ac.in', 'NAVYA S K',                     '26MX333', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Navyask'),
('nigithag79799@gmail.com',           'nigithag79799@gmail.com',           '26mx334@psgtech.ac.in', 'NIGITHA G',                     '26MX334', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'nigitha-g'),
('ushaa072005@gmail.com',             'ushaa072005@gmail.com',             '26mx335@psgtech.ac.in', 'P USHA NANDHINI',               '26MX335', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Usha_0705'),
('pavatharinikathirvel@gmail.com',    'pavatharinikathirvel@gmail.com',    '26mx336@psgtech.ac.in', 'PAVATHARINI K',                 '26MX336', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, NULL),
('poojamathesh6363@gmail.com',        'poojamathesh6363@gmail.com',        '26mx337@psgtech.ac.in', 'POOJA M',                       '26MX337', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'poojamathesh'),
('rajamadhangi3092005@gmail.com',     'rajamadhangi3092005@gmail.com',     '26mx338@psgtech.ac.in', 'RAJAMADHANGI G',                '26MX338', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'madhangiganesan'),
('rohinimurugathal@gmail.com',        'rohinimurugathal@gmail.com',        '26mx339@psgtech.ac.in', 'ROHINI A',                      '26MX339', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Rohinimurugathal'),
('roycejoe06@gmail.com',              'roycejoe06@gmail.com',              '26mx340@psgtech.ac.in', 'ROYCE JOE L',                   '26MX340', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'roycejoe_06'),
('safeer2587@gmail.com',              'safeer2587@gmail.com',              '26mx341@psgtech.ac.in', 'SAFEER AHAMED B',               '26MX341', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Safeer_Ahamed_B'),
('shafeeqsha1510@gmail.com',          'shafeeqsha1510@gmail.com',          '26mx342@psgtech.ac.in', 'SHAFEEQ',                       '26MX342', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'ShafeeqS'),
('shrutinimi345@gmail.com',           'shrutinimi345@gmail.com',           '26mx343@psgtech.ac.in', 'SHRUTI ARUMUGAM',               '26MX343', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Shrutttii'),
('bsivakalai10@gmail.com',            'bsivakalai10@gmail.com',            '26mx344@psgtech.ac.in', 'SIVAKALAI B',                   '26MX344', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'SivakalaiB'),
('srithanvarsha25082005@gmail.com',   'srithanvarsha25082005@gmail.com',   '26mx345@psgtech.ac.in', 'SRI THANVARSHA C',              '26MX345', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Srithanvarsha'),
('sridhanyachidambaram2005@gmail.com','sridhanyachidambaram2005@gmail.com','26mx346@psgtech.ac.in', 'SRIDHANYA C',                   '26MX346', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'sridhanya_123'),
('srinithishjk@gmail.com',            'srinithishjk@gmail.com',            '26mx347@psgtech.ac.in', 'SRINITHISH J K',                '26MX347', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Nithish_jk'),
('sruthishanmugasundaram8@gmail.com', 'sruthishanmugasundaram8@gmail.com', '26mx348@psgtech.ac.in', 'SRUTHI S',                      '26MX348', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Sruthi8'),
('newsudharshan1@gmail.com',          'newsudharshan1@gmail.com',          '26mx349@psgtech.ac.in', 'SUDHARSHAN K',                  '26MX349', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'sudharshan04k'),
('swethapalanisamy81@gmail.com',      'swethapalanisamy81@gmail.com',      '26mx350@psgtech.ac.in', 'SWETHA P',                      '26MX350', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'swetha_2811'),
('theekshnashrim@gmail.com',          'theekshnashrim@gmail.com',          '26mx351@psgtech.ac.in', 'THEEKSHNASHRI M',               '26MX351', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Theeks'),
('valarilambiraiks@gmail.com',        'valarilambiraiks@gmail.com',        '26mx352@psgtech.ac.in', 'VALARILAMBIRAI K S',            '26MX352', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Valarilambirai'),
('vlvelayutham18@gmail.com',          'vlvelayutham18@gmail.com',          '26mx353@psgtech.ac.in', 'VELAYUTHAM V L',                '26MX353', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Vicky047'),
('crvenkatesh24@gmail.com',           'crvenkatesh24@gmail.com',           '26mx354@psgtech.ac.in', 'VENKATESH C R',                 '26MX354', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Venkatesh_CR'),
('victorana7700@gmail.com',           'victorana7700@gmail.com',           '26mx355@psgtech.ac.in', 'VICTOR ANAND C',                '26MX355', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Victor_Anand'),
('vidhyabalu2006@gmail.com',          'vidhyabalu2006@gmail.com',          '26mx356@psgtech.ac.in', 'VIDHYA B S',                    '26MX356', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'viidhya'),
('vishals18266@gmail.com',            'vishals18266@gmail.com',            '26mx357@psgtech.ac.in', 'VISHAL S',                      '26MX357', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'SVishal111'),
('vivedivina2005@gmail.com',          'vivedivina2005@gmail.com',          '26mx358@psgtech.ac.in', 'VIVE DIVINA J',                 '26MX358', 'G2', (SELECT id FROM public.batches WHERE batch_code='26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb, 'Vive_Divina01')
ON CONFLICT (reg_no) DO UPDATE SET
    personal_email    = COALESCE(EXCLUDED.personal_email, existing.personal_email),
    college_email     = COALESCE(EXCLUDED.college_email,  existing.college_email),
    name              = EXCLUDED.name,
    batch             = EXCLUDED.batch,
    batch_id          = EXCLUDED.batch_id,
    roles             = EXCLUDED.roles,
    leetcode_username = COALESCE(EXCLUDED.leetcode_username, existing.leetcode_username);

-- ── 2. Update users table (github_url, linkedin_url, leetcode_username) ───────
-- Only runs for students who have already signed in (have a users row).
UPDATE public.users u
SET
    github_url        = v.github_url,
    leetcode_username = v.leetcode_username,
    linkedin_url      = v.linkedin_url
FROM (VALUES
    ('26MX301', 'https://github.com/Abiramidevasenapathy',   'Abirami_Devasenapathy', NULL),
    ('26MX302', 'https://github.com/aditribk',               'aditribk',              'https://www.linkedin.com/in/aditri-bk28'),
    ('26MX303', 'https://github.com/Aishwaryaa-selvaraj',    'Aishwaryaa_selvaraj',   'https://www.linkedin.com/in/aishwaryaa-s-k-88120a430'),
    ('26MX304', 'https://github.com/akileshaki05',            'akileshaki',            'https://www.linkedin.com/in/akilesh-n-a94375283'),
    ('26MX305', 'https://github.com/AnanthaLakshi',           NULL,                    NULL),
    ('26MX306', 'https://github.com/Ashritaa-005',            'Ashritaa',              NULL),
    ('26MX307', 'https://github.com/Ashwin-stack2005',        'bRaoPlMCd1',            NULL),
    ('26MX308', 'https://github.com/Asiina-7',                'AsinaP',                NULL),
    ('26MX309', NULL,                                          NULL,                    NULL),
    ('26MX310', 'https://github.com/balaaakash2005-bit',      'bala_120405',           NULL),
    ('26MX311', 'https://github.com/Deepannnn',               'Deepan_chakravarthi',   NULL),
    ('26MX312', NULL,                                          NULL,                    NULL),
    ('26MX313', NULL,                                          NULL,                    NULL),
    ('26MX314', 'https://github.com/Dharshini17-08',          'R_DHARSHINI17',         NULL),
    ('26MX315', NULL,                                          NULL,                    NULL),
    ('26MX316', 'https://github.com/elakkiya0626',             'ElakkiyaC',             NULL),
    ('26MX317', NULL,                                          NULL,                    NULL),
    ('26MX318', 'https://github.com/Gayathrijanagaraj',       'Gayu1803',              NULL),
    ('26MX319', 'https://github.com/Jairussj',                'Jairussj',              NULL),
    ('26MX320', 'https://github.com/Jeeva7774',               'Jeeva7774',             NULL),
    ('26MX321', 'https://github.com/joshikaramadoss29-boop',  'joshikaa200629',        NULL),
    ('26MX322', 'https://github.com/Kalarani04',              'Kalarani04',            NULL),
    ('26MX323', 'https://github.com/Kavipriyadharshini1310',  'Kavi_1310',             NULL),
    ('26MX324', 'https://github.com/Kerrthana25',             'KeerthanaAR25',         NULL),
    ('26MX325', 'https://github.com/kkirubhakaran',           NULL,                    NULL),
    ('26MX326', 'https://github.com/kriuthiyogitha-ui',       'KriuthiYogitha',        NULL),
    ('26MX327', 'https://github.com/Meenakshimurali30',       'meenakshimurali30',     NULL),
    ('26MX328', 'https://github.com/mounisha2306',            'mounisha2006',          NULL),
    ('26MX329', 'https://github.com/nabilaa-12',              'nabilabanu_12',         NULL),
    ('26MX330', 'https://github.com/nadhishbaskar16-glitch',  'Nadhish_B',             NULL),
    ('26MX331', 'https://github.com/NARESHWARAN-25',          'nareshwaran25',         NULL),
    ('26MX332', 'https://github.com/nateshm708',               'muralidharannatesh',    NULL),
    ('26MX333', 'https://github.com/navyask-oss',              'Navyask',               NULL),
    ('26MX334', 'https://github.com/Nigitha-G',                'nigitha-g',             NULL),
    ('26MX335', 'https://github.com/usha-nandhini07',          'Usha_0705',             NULL),
    ('26MX336', 'https://github.com/Pavatharini-04',           NULL,                    NULL),
    ('26MX337', 'https://github.com/poojamathesh7584',         'poojamathesh',          NULL),
    ('26MX338', 'https://github.com/Raja-madhangi',            'madhangiganesan',       NULL),
    ('26MX339', 'https://github.com/RohiniMurugathal',         'Rohinimurugathal',      NULL),
    ('26MX340', 'https://github.com/roycejoe06-bot',           'roycejoe_06',           NULL),
    ('26MX341', 'https://github.com/Safeer-Ahamed-B',          'Safeer_Ahamed_B',       NULL),
    ('26MX342', 'https://github.com/Shaefik',                  'ShafeeqS',              NULL),
    ('26MX343', 'https://github.com/shruti030405',              'Shrutttii',             NULL),
    ('26MX344', 'https://github.com/sivakalaibalasundaram',    'SivakalaiB',            NULL),
    ('26MX345', 'https://github.com/srithanvarsha',            'Srithanvarsha',         NULL),
    ('26MX346', 'https://github.com/sridhanya08048',           'sridhanya_123',         NULL),
    ('26MX347', 'https://github.com/SriNithish-JK',            'Nithish_jk',            NULL),
    ('26MX348', 'https://github.com/Srruthi348',               'Sruthi8',               NULL),
    ('26MX349', 'https://github.com/newsudharshan1-lgtm',      'sudharshan04k',         NULL),
    ('26MX350', 'https://github.com/Swethap28',                'swetha_2811',           NULL),
    ('26MX351', 'https://github.com/Theeks7',                  'Theeks',                NULL),
    ('26MX352', 'https://github.com/valarilambiraiks',          'Valarilambirai',        NULL),
    ('26MX353', 'https://github.com/vlvelayutham',              'Vicky047',              NULL),
    ('26MX354', 'https://github.com/Venkatesh-C-R',            'Venkatesh_CR',          NULL),
    ('26MX355', 'https://github.com/VictorAnand592',           'Victor_Anand',          NULL),
    ('26MX356', 'https://github.com/viidhya',                  'viidhya',               NULL),
    ('26MX357', 'https://github.com/SVishal111',               'SVishal111',            NULL),
    ('26MX358', 'https://github.com/vivedivina11',             'Vive_Divina01',         NULL)
) AS v(reg_no, github_url, leetcode_username, linkedin_url)
WHERE u.reg_no = v.reg_no
  AND (v.github_url IS NOT NULL OR v.leetcode_username IS NOT NULL);

-- ── 3. Ensure 26MX batch is active_junior ────────────────────────────────────
UPDATE public.batches
SET status = 'active_junior', updated_at = now()
WHERE batch_code = '26MX' AND status != 'active_junior';

-- ── 4. Verify ────────────────────────────────────────────────────────────────
DO $$
DECLARE
    g2_count  INT;
    otp_ready INT;
BEGIN
    SELECT COUNT(*) INTO g2_count  FROM public.whitelist WHERE reg_no LIKE '26MX3%';
    SELECT COUNT(*) INTO otp_ready FROM public.whitelist WHERE reg_no LIKE '26MX3%' AND personal_email IS NOT NULL;
    RAISE NOTICE '38_update_26mxg2_profiles: % G2 students rostered, % OTP-ready (all 58 should be OTP-ready)', g2_count, otp_ready;
END $$;

COMMIT;
