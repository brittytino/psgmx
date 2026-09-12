-- ============================================================
-- PSGMX — 38_update_26mxg2_profiles.sql
-- ============================================================
-- Seeds GitHub, LeetCode username, and LinkedIn URL for all
-- 26MX G2 students from the official class roster (26MXG2 INFORMATION'S.xlsx).
-- Also upserts any missing whitelist entries so every student can log in.
-- Safe to run multiple times (idempotent).
-- Run AFTER 16_seed_students_26mx.sql.
-- ============================================================

BEGIN;

-- ── 1. Ensure all 26MX G2 students exist in the whitelist ────────────────────
-- This is the authoritative upsert — covers any student missing due to a
-- partial earlier seed or email mismatch.
INSERT INTO public.whitelist AS existing (
    email, personal_email, college_email, name, reg_no, batch, batch_id, team_id, roles
) VALUES
('abiramidevasenapathy@gmail.com',   'abiramidevasenapathy@gmail.com',   '26mx301@psgtech.ac.in', 'ABIRAMI D',                      '26MX301', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('balajiaditri28@gmail.com',         'balajiaditri28@gmail.com',         '26mx302@psgtech.ac.in', 'ADITRI BALAJI',                   '26MX302', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('aishwaryaaselvaraj@gmail.com',     'aishwaryaaselvaraj@gmail.com',     '26mx303@psgtech.ac.in', 'AISHWARYAA S K',                  '26MX303', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('akileshaki411@gmail.com',          'akileshaki411@gmail.com',          '26mx304@psgtech.ac.in', 'AKILESH N',                       '26MX304', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('ananthan672020@gmail.com',         'ananthan672020@gmail.com',         '26mx305@psgtech.ac.in', 'ANANTHA LAKSHMI A',               '26MX305', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('ashritaa2809@gmail.com',           'ashritaa2809@gmail.com',           '26mx306@psgtech.ac.in', 'ASHRITAA NAVANEETHA KRISHNAN',    '26MX306', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('gkashwinkumar@gmail.com',          'gkashwinkumar@gmail.com',          '26mx307@psgtech.ac.in', 'ASHWIN KUMAR G K',                '26MX307', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('asina200107@gmail.com',            'asina200107@gmail.com',            '26mx308@psgtech.ac.in', 'ASINA P',                         '26MX308', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('aswathck28@gmail.com',             'aswathck28@gmail.com',             '26mx309@psgtech.ac.in', 'ASWATH NARAYANAN A C',            '26MX309', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('balaaakash2005@gmail.com',         'balaaakash2005@gmail.com',         '26mx310@psgtech.ac.in', 'BALA SUBRAMANIAN B',              '26MX310', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('chakravarthydeepan584@gmail.com',  'chakravarthydeepan584@gmail.com',  '26mx311@psgtech.ac.in', 'DEEPAN CHAKRAVARTHI S',           '26MX311', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('dhanyalakshmi0103@gmail.com',      'dhanyalakshmi0103@gmail.com',      '26mx312@psgtech.ac.in', 'DHANYA LAKSHMI M U',              '26MX312', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('dharshinigsvd@gmail.com',          'dharshinigsvd@gmail.com',          '26mx313@psgtech.ac.in', 'DHARSHINI G S',                   '26MX313', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('rdharshinim@gmail.com',            'rdharshinim@gmail.com',            '26mx314@psgtech.ac.in', 'DHARSHINI R',                     '26MX314', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('dharunyamanikandan@gmail.com',     'dharunyamanikandan@gmail.com',     '26mx315@psgtech.ac.in', 'DHARUNYA M P',                    '26MX315', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('elakkiyac43@gmail.com',            'elakkiyac43@gmail.com',            '26mx316@psgtech.ac.in', 'ELAKKIYA C',                      '26MX316', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('esakirahul2@gmail.com',            'esakirahul2@gmail.com',            '26mx317@psgtech.ac.in', 'ESAKI RAHUL M',                   '26MX317', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('gayathrijanagaraj@gmail.com',      'gayathrijanagaraj@gmail.com',      '26mx318@psgtech.ac.in', 'GAYATHRI J',                      '26MX318', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('jairussj24@gmail.com',             'jairussj24@gmail.com',             '26mx319@psgtech.ac.in', 'JAIRUS S',                        '26MX319', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('jeevashanmugam7774@gmail.com',     'jeevashanmugam7774@gmail.com',     '26mx320@psgtech.ac.in', 'JEEVA S',                         '26MX320', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('joshikaramadoss29@gmail.com',      'joshikaramadoss29@gmail.com',      '26mx321@psgtech.ac.in', 'JOSHIKA R',                       '26MX321', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('kalaranirv@gmail.com',             'kalaranirv@gmail.com',             '26mx322@psgtech.ac.in', 'KALARANI R',                      '26MX322', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('kavipriyad1310@gmail.com',         'kavipriyad1310@gmail.com',         '26mx323@psgtech.ac.in', 'KAVI PRIYA DHARSHINI B',          '26MX323', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('keerthanaashokkumar25@gmail.com',  'keerthanaashokkumar25@gmail.com',  '26mx324@psgtech.ac.in', 'KEERTHANA A R',                   '26MX324', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('kkirubhakaran1@gmail.com',         'kkirubhakaran1@gmail.com',         '26mx325@psgtech.ac.in', 'KIRUBHAKARAN K',                  '26MX325', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('kriuthiyogitha@gmail.com',         'kriuthiyogitha@gmail.com',         '26mx326@psgtech.ac.in', 'KRIUTHI YOGITHA A',               '26MX326', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('meenakshimurali30@gmail.com',      'meenakshimurali30@gmail.com',      '26mx327@psgtech.ac.in', 'MEENAKSHI M',                     '26MX327', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('mounishamuthusamy@gmail.com',      'mounishamuthusamy@gmail.com',      '26mx328@psgtech.ac.in', 'MOUNISHA M',                      '26MX328', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('nabilabanu7618@gmail.com',         'nabilabanu7618@gmail.com',         '26mx329@psgtech.ac.in', 'NABILA BANU R',                   '26MX329', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('nadhishbaskar16@gmail.com',        'nadhishbaskar16@gmail.com',        '26mx330@psgtech.ac.in', 'NADHISH B',                       '26MX330', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('nareshwaran703@gmail.com',         'nareshwaran703@gmail.com',         '26mx331@psgtech.ac.in', 'NARESHWARAN J',                   '26MX331', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('muralidharannatesh@gmail.com',     'muralidharannatesh@gmail.com',     '26mx332@psgtech.ac.in', 'NATESH M',                        '26MX332', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('navyasureshkumar505@gmail.com',    'navyasureshkumar505@gmail.com',    '26mx333@psgtech.ac.in', 'NAVYA S K',                       '26MX333', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('nigithag79799@gmail.com',          'nigithag79799@gmail.com',          '26mx334@psgtech.ac.in', 'NIGITHA G',                       '26MX334', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('ushaa072005@gmail.com',            'ushaa072005@gmail.com',            '26mx335@psgtech.ac.in', 'P USHA NANDHINI',                 '26MX335', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('pavatharinikathirvel@gmail.com',   'pavatharinikathirvel@gmail.com',   '26mx336@psgtech.ac.in', 'PAVATHARINI K',                   '26MX336', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('poojamathesh6363@gmail.com',       'poojamathesh6363@gmail.com',       '26mx337@psgtech.ac.in', 'POOJA M',                         '26MX337', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('rajamadhangi3092005@gmail.com',    'rajamadhangi3092005@gmail.com',    '26mx338@psgtech.ac.in', 'RAJAMADHANGI G',                  '26MX338', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('rohinimurugathal@gmail.com',       'rohinimurugathal@gmail.com',       '26mx339@psgtech.ac.in', 'ROHINI A',                        '26MX339', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('roycejoe06@gmail.com',             'roycejoe06@gmail.com',             '26mx340@psgtech.ac.in', 'ROYCE JOE L',                     '26MX340', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('safeer2587@gmail.com',             'safeer2587@gmail.com',             '26mx341@psgtech.ac.in', 'SAFEER AHAMED B',                 '26MX341', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('shafeeqsha1510@gmail.com',         'shafeeqsha1510@gmail.com',         '26mx342@psgtech.ac.in', 'SHAFEEQ',                         '26MX342', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('shrutinimi345@gmail.com',          'shrutinimi345@gmail.com',          '26mx343@psgtech.ac.in', 'SHRUTI ARUMUGAM',                 '26MX343', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('bsivakalai10@gmail.com',           'bsivakalai10@gmail.com',           '26mx344@psgtech.ac.in', 'SIVAKALAI B',                     '26MX344', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('srithanvarsha25082005@gmail.com',  'srithanvarsha25082005@gmail.com',  '26mx345@psgtech.ac.in', 'SRI THANVARSHA C',                '26MX345', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('sridhanyachidambaram2005@gmail.com','sridhanyachidambaram2005@gmail.com','26mx346@psgtech.ac.in','SRIDHANYA C',                    '26MX346', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('srinithishjk@gmail.com',           'srinithishjk@gmail.com',           '26mx347@psgtech.ac.in', 'SRINITHISH J K',                  '26MX347', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('sruthishanmugasundaram8@gmail.com','sruthishanmugasundaram8@gmail.com','26mx348@psgtech.ac.in', 'SRUTHI S',                        '26MX348', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('newsudharshan1@gmail.com',         'newsudharshan1@gmail.com',         '26mx349@psgtech.ac.in', 'SUDHARSHAN K',                    '26MX349', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('swethapalanisamy81@gmail.com',     'swethapalanisamy81@gmail.com',     '26mx350@psgtech.ac.in', 'SWETHA P',                        '26MX350', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('theekshnashrim@gmail.com',         'theekshnashrim@gmail.com',         '26mx351@psgtech.ac.in', 'THEEKSHNASHRI M',                 '26MX351', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('valarilambiraiks@gmail.com',       'valarilambiraiks@gmail.com',       '26mx352@psgtech.ac.in', 'VALARILAMBIRAI K S',              '26MX352', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('vlvelayutham18@gmail.com',         'vlvelayutham18@gmail.com',         '26mx353@psgtech.ac.in', 'VELAYUTHAM V L',                  '26MX353', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('crvenkatesh24@gmail.com',          'crvenkatesh24@gmail.com',          '26mx354@psgtech.ac.in', 'VENKATESH C R',                   '26MX354', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('victorana7700@gmail.com',          'victorana7700@gmail.com',          '26mx355@psgtech.ac.in', 'VICTOR ANAND C',                  '26MX355', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('vidhyabalu2006@gmail.com',         'vidhyabalu2006@gmail.com',         '26mx356@psgtech.ac.in', 'VIDHYA B S',                      '26MX356', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('vishals18266@gmail.com',           'vishals18266@gmail.com',           '26mx357@psgtech.ac.in', 'VISHAL S',                        '26MX357', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb),
('vivedivina2005@gmail.com',         'vivedivina2005@gmail.com',         '26mx358@psgtech.ac.in', 'VIVE DIVINA J',                   '26MX358', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent":true,"isTeamLeader":false,"isCoordinator":false,"isPlacementRep":false}'::jsonb)
ON CONFLICT (reg_no) DO UPDATE SET
    personal_email = COALESCE(EXCLUDED.personal_email, existing.personal_email),
    college_email  = COALESCE(EXCLUDED.college_email,  existing.college_email),
    name           = EXCLUDED.name,
    batch          = EXCLUDED.batch,
    batch_id       = EXCLUDED.batch_id;

-- ── 2. Update GitHub, LeetCode, LinkedIn from official roster ─────────────────
UPDATE public.whitelist SET
    github_url     = 'https://github.com/Abiramidevasenapathy',
    leetcode_username = 'Abirami_Devasenapathy'
WHERE reg_no = '26MX301';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/aditribk',
    leetcode_username = 'aditribk',
    linkedin_url   = 'https://www.linkedin.com/in/aditri-bk28'
WHERE reg_no = '26MX302';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Aishwaryaa-selvaraj',
    leetcode_username = 'Aishwaryaa_selvaraj',
    linkedin_url   = 'https://www.linkedin.com/in/aishwaryaa-s-k-88120a430'
WHERE reg_no = '26MX303';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/akileshaki05',
    leetcode_username = 'akileshaki',
    linkedin_url   = 'https://www.linkedin.com/in/akilesh-n-a94375283'
WHERE reg_no = '26MX304';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/AnanthaLakshi'
WHERE reg_no = '26MX305';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Ashritaa-005',
    leetcode_username = 'Ashritaa'
WHERE reg_no = '26MX306';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Ashwin-stack2005',
    leetcode_username = 'bRaoPlMCd1'
WHERE reg_no = '26MX307';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Asiina-7',
    leetcode_username = 'AsinaP'
WHERE reg_no = '26MX308';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/balaaakash2005-bit',
    leetcode_username = 'bala_120405'
WHERE reg_no = '26MX310';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Deepannnn',
    leetcode_username = 'Deepan_chakravarthi'
WHERE reg_no = '26MX311';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Dharshini17-08',
    leetcode_username = 'R_DHARSHINI17'
WHERE reg_no = '26MX314';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/elakkiya0626',
    leetcode_username = 'ElakkiyaC'
WHERE reg_no = '26MX316';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Gayathrijanagaraj',
    leetcode_username = 'Gayu1803'
WHERE reg_no = '26MX318';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Jairussj',
    leetcode_username = 'Jairussj'
WHERE reg_no = '26MX319';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Jeeva7774',
    leetcode_username = 'Jeeva7774'
WHERE reg_no = '26MX320';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/joshikaramadoss29-boop',
    leetcode_username = 'joshikaa200629'
WHERE reg_no = '26MX321';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Kalarani04',
    leetcode_username = 'Kalarani04'
WHERE reg_no = '26MX322';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Kavipriyadharshini1310',
    leetcode_username = 'Kavi_1310'
WHERE reg_no = '26MX323';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Kerrthana25',
    leetcode_username = 'KeerthanaAR25'
WHERE reg_no = '26MX324';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/kkirubhakaran'
WHERE reg_no = '26MX325';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/kriuthiyogitha-ui',
    leetcode_username = 'KriuthiYogitha'
WHERE reg_no = '26MX326';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Meenakshimurali30',
    leetcode_username = 'meenakshimurali30'
WHERE reg_no = '26MX327';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/mounisha2306',
    leetcode_username = 'mounisha2006'
WHERE reg_no = '26MX328';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/nabilaa-12',
    leetcode_username = 'nabilabanu_12'
WHERE reg_no = '26MX329';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/nadhishbaskar16-glitch',
    leetcode_username = 'Nadhish_B'
WHERE reg_no = '26MX330';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/NARESHWARAN-25',
    leetcode_username = 'nareshwaran25'
WHERE reg_no = '26MX331';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/nateshm708',
    leetcode_username = 'muralidharannatesh'
WHERE reg_no = '26MX332';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/navyask-oss',
    leetcode_username = 'Navyask'
WHERE reg_no = '26MX333';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Nigitha-G',
    leetcode_username = 'nigitha-g'
WHERE reg_no = '26MX334';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/usha-nandhini07',
    leetcode_username = 'Usha_0705'
WHERE reg_no = '26MX335';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Pavatharini-04'
WHERE reg_no = '26MX336';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/poojamathesh7584',
    leetcode_username = 'poojamathesh'
WHERE reg_no = '26MX337';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Raja-madhangi',
    leetcode_username = 'madhangiganesan'
WHERE reg_no = '26MX338';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/RohiniMurugathal',
    leetcode_username = 'Rohinimurugathal'
WHERE reg_no = '26MX339';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/roycejoe06-bot',
    leetcode_username = 'roycejoe_06'
WHERE reg_no = '26MX340';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Safeer-Ahamed-B',
    leetcode_username = 'Safeer_Ahamed_B'
WHERE reg_no = '26MX341';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Shaefik',
    leetcode_username = 'ShafeeqS'
WHERE reg_no = '26MX342';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/shruti030405',
    leetcode_username = 'Shrutttii'
WHERE reg_no = '26MX343';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/sivakalaibalasundaram',
    leetcode_username = 'SivakalaiB'
WHERE reg_no = '26MX344';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/srithanvarsha',
    leetcode_username = 'Srithanvarsha'
WHERE reg_no = '26MX345';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/sridhanya08048',
    leetcode_username = 'sridhanya_123'
WHERE reg_no = '26MX346';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/SriNithish-JK',
    leetcode_username = 'Nithish_jk'
WHERE reg_no = '26MX347';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Srruthi348',
    leetcode_username = 'Sruthi8'
WHERE reg_no = '26MX348';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/newsudharshan1-lgtm',
    leetcode_username = 'sudharshan04k'
WHERE reg_no = '26MX349';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Swethap28',
    leetcode_username = 'swetha_2811'
WHERE reg_no = '26MX350';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Theeks7',
    leetcode_username = 'Theeks'
WHERE reg_no = '26MX351';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/valarilambiraiks',
    leetcode_username = 'Valarilambirai'
WHERE reg_no = '26MX352';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/vlvelayutham',
    leetcode_username = 'Vicky047'
WHERE reg_no = '26MX353';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/Venkatesh-C-R',
    leetcode_username = 'Venkatesh_CR'
WHERE reg_no = '26MX354';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/VictorAnand592',
    leetcode_username = 'Victor_Anand'
WHERE reg_no = '26MX355';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/viidhya',
    leetcode_username = 'viidhya'
WHERE reg_no = '26MX356';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/SVishal111',
    leetcode_username = 'SVishal111'
WHERE reg_no = '26MX357';

UPDATE public.whitelist SET
    github_url     = 'https://github.com/vivedivina11',
    leetcode_username = 'Vive_Divina01'
WHERE reg_no = '26MX358';

-- ── 3. Also seed users table for already-provisioned accounts ────────────────
-- If a student has signed in before (has a users row), sync their GitHub/LeetCode
UPDATE public.users u
SET
    github_url        = w.github_url,
    leetcode_username = w.leetcode_username,
    linkedin_url      = w.linkedin_url
FROM public.whitelist w
WHERE u.reg_no = w.reg_no
  AND w.reg_no LIKE '26MX3%'
  AND (w.github_url IS NOT NULL OR w.leetcode_username IS NOT NULL);

-- ── 4. Ensure 26MX batch is active_junior ────────────────────────────────────
UPDATE public.batches
SET status = 'active_junior', updated_at = now()
WHERE batch_code = '26MX' AND status != 'active_junior';

-- ── 5. Verify ────────────────────────────────────────────────────────────────
DO $$
DECLARE
    g2_count INT;
    otp_ready INT;
BEGIN
    SELECT COUNT(*) INTO g2_count  FROM public.whitelist WHERE reg_no LIKE '26MX3%';
    SELECT COUNT(*) INTO otp_ready FROM public.whitelist WHERE reg_no LIKE '26MX3%' AND personal_email IS NOT NULL;
    RAISE NOTICE '38_update_26mxg2_profiles.sql: % G2 students rostered, % OTP-ready', g2_count, otp_ready;
END $$;

COMMIT;
