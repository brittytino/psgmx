-- ============================================================
-- PSGMX — 16_seed_students_26mx.sql
-- ============================================================
-- Validated 26MX G1/G2 roster supplied in August 2026.
-- Personal email is the initial OTP identity. The predictable college email
-- is also registered now; either identity resolves to one logical profile.
-- Run AFTER 15_identity_batch_team_hardening.sql.
-- ============================================================

BEGIN;

INSERT INTO public.whitelist AS existing (
    email, personal_email, college_email, name, reg_no, batch, batch_id,
    team_id, roles
) VALUES
('agileshnv2005@gmail.com', 'agileshnv2005@gmail.com', NULL, 'Agilesh N V', '26MX101', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('11aloysh2001@gmail.com', '11aloysh2001@gmail.com', NULL, 'Aloysus maria raj A', '26MX102', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('amrithasenthilkumar7@gmail.com', 'amrithasenthilkumar7@gmail.com', NULL, 'Amritha varshini S', '26MX103', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('bharathisivakumarias@gmail.com', 'bharathisivakumarias@gmail.com', NULL, 'BHARATHI S', '26MX104', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('nrdharshanranganathan@gmail.com', 'nrdharshanranganathan@gmail.com', NULL, 'Dharshan Ranganathan NR', '26MX105', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('dheenadhayaldheena@gmail.com', 'dheenadhayaldheena@gmail.com', NULL, 'Dheena dhayal M', '26MX106', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('harish7122004@gmail.com', 'harish7122004@gmail.com', NULL, 'Harishkumar S', '26MX107', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('jayeshclg07@gmail.com', 'jayeshclg07@gmail.com', NULL, 'Jayakumar M', '26MX108', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('nagarajkarthikaa@gmail.com', 'nagarajkarthikaa@gmail.com', NULL, 'N.KARTHIKAA', '26MX109', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('karthikeyan30507@gmail.com', 'karthikeyan30507@gmail.com', NULL, 'Karthikeyan S', '26MX110', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('karthikeyinikumaresan05@gmail.com', 'karthikeyinikumaresan05@gmail.com', NULL, 'KARTHIKEYINI K', '26MX111', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('kavyadharshini573@gmail.com', 'kavyadharshini573@gmail.com', NULL, 'Kavyadharshini S', '26MX112', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('mayukasundararaj@gmail.com', 'mayukasundararaj@gmail.com', NULL, 'MAYUKA S', '26MX113', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('meghavarshini0921@gmail.com', 'meghavarshini0921@gmail.com', NULL, 'Megha Varshini S', '26MX114', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('abdulbasith20061976@gmail.com', 'abdulbasith20061976@gmail.com', NULL, 'MOHAMED ABDUL BASITH A A', '26MX115', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('mridulathulasirajan@gmail.com', 'mridulathulasirajan@gmail.com', NULL, 'Mridula ST', '26MX116', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('niviie245@gmail.com', 'niviie245@gmail.com', NULL, 'Nivedhitha G', '26MX117', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('parithi567@gmail.com', 'parithi567@gmail.com', NULL, 'Parithi R', '26MX118', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('pooranichinnusamymkc@gmail.com', 'pooranichinnusamymkc@gmail.com', NULL, 'Poorani C', '26MX119', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('pd121061@gmail.com', 'pd121061@gmail.com', NULL, 'PRIYA DHARSHINI R', '26MX120', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('rebakhasnowitm@gmail.com', 'rebakhasnowitm@gmail.com', NULL, 'REBAKHA SNOWIT M', '26MX121', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('sanjay2006krishnan@gmail.com', 'sanjay2006krishnan@gmail.com', NULL, 'Sanjay K', '26MX122', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('s98042079@gmail.com', 's98042079@gmail.com', NULL, 'Santhosh Sivaraman', '26MX123', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('sharmilarajendran05@gmail.com', 'sharmilarajendran05@gmail.com', NULL, 'SHARMILA R', '26MX124', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('sivaranjanrajavelu29@gmail.com', 'sivaranjanrajavelu29@gmail.com', NULL, 'SIVARANJAN', '26MX125', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('sivasudhan7374@gmail.com', 'sivasudhan7374@gmail.com', NULL, 'Sivasudhan Rajasekar', '26MX126', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('vyshnavikumaresan2005@gmail.com', 'vyshnavikumaresan2005@gmail.com', NULL, 'Vyshnavi K', '26MX127', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('yajatdev10@gmail.com', 'yajatdev10@gmail.com', NULL, 'Yajat Dev V', '26MX128', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('yuvanprasath2005@gmail.com', 'yuvanprasath2005@gmail.com', NULL, 'YUVAN PRASATH B', '26MX129', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('sameemaffu@gmail.com', 'sameemaffu@gmail.com', NULL, 'Affrin Jawahar S', '26MX201', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('anandhalakshmi.b5@gmail.com', 'anandhalakshmi.b5@gmail.com', NULL, 'Anandha Lakshmi B', '26MX202', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('deepadharshini05@gmail.com', 'deepadharshini05@gmail.com', NULL, 'Deepa Dharshini.G', '26MX203', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('dhayaanandhan7@gmail.com', 'dhayaanandhan7@gmail.com', NULL, 'Dhayaanandhan V', '26MX204', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('10126haresh@gmail.com', '10126haresh@gmail.com', NULL, 'HARESH S', '26MX205', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('hariprasanthsettu@gmail.com', 'hariprasanthsettu@gmail.com', NULL, 'HARI PRASANTH S', '26MX206', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('harshini06062005@gmail.com', 'harshini06062005@gmail.com', NULL, 'HARSHINI G', '26MX207', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('kavyatharshinipg@gmail.com', 'kavyatharshinipg@gmail.com', NULL, 'Kavyatharshini P', '26MX208', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('blaxman1806@gmail.com', 'blaxman1806@gmail.com', NULL, 'LAXMAN B', '26MX209', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('mirdullasateesh@gmail.com', 'mirdullasateesh@gmail.com', NULL, 'MIRDULLA S', '26MX210', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('mohanrajnagaraj2005@gmail.com', 'mohanrajnagaraj2005@gmail.com', NULL, 'MOHANRAJ N', '26MX211', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('nyantaralakshmi@gmail.com', 'nyantaralakshmi@gmail.com', NULL, 'Nyantara Lakshmi D S', '26MX212', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('pooja27253@gmail.com', 'pooja27253@gmail.com', NULL, 'Pooja S', '26MX213', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('itzpoojasrisuresh@gmail.com', 'itzpoojasrisuresh@gmail.com', NULL, 'Poojasri S', '26MX214', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('rathnashri45@gmail.com', 'rathnashri45@gmail.com', NULL, 'RATHNA SHRI B', '26MX215', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('samrithiramesh26725@gmail.com', 'samrithiramesh26725@gmail.com', NULL, 'Samrithi Ramesh', '26MX216', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('sanjivvv19@gmail.com', 'sanjivvv19@gmail.com', NULL, 'SANJIVKUMAR A', '26MX217', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('santhiyathirunavukarasu05@gmail.com', 'santhiyathirunavukarasu05@gmail.com', NULL, 'Santhiya T', '26MX218', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('shwethaparthasarathi@gmail.com', 'shwethaparthasarathi@gmail.com', NULL, 'Shwetha P', '26MX219', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('sprasath12121@gmail.com', 'sprasath12121@gmail.com', NULL, 'SIVA PRASATH SIVAKUMAR', '26MX220', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('sofiyaleo2005@gmail.com', 'sofiyaleo2005@gmail.com', NULL, 'Sofiya A', '26MX221', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('srigowshikramd@gmail.com', 'srigowshikramd@gmail.com', NULL, 'Srigowshikram D', '26MX222', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('sukanthasc01@gmail.com', 'sukanthasc01@gmail.com', NULL, 'Sukantha S C', '26MX223', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('varshanithiyanandham@gmail.com', 'varshanithiyanandham@gmail.com', NULL, 'VARSHA N', '26MX224', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('varshanaraju@gmail.com', 'varshanaraju@gmail.com', NULL, 'Varshana R', '26MX225', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('shithuu1005@gmail.com', 'shithuu1005@gmail.com', NULL, 'Varshitaa SH', '26MX226', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('vigneshwarsuresh21@gmail.com', 'vigneshwarsuresh21@gmail.com', NULL, 'Vigneshwar S', '26MX227', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('vigneshwarans0603@gmail.com', 'vigneshwarans0603@gmail.com', NULL, 'VIGNESHWARAN S', '26MX228', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('nivethikargm@gmail.com', 'nivethikargm@gmail.com', NULL, 'Vijayanivethika R G M', '26MX229', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('yuvashrims2006@gmail.com', 'yuvashrims2006@gmail.com', NULL, 'YUVASHRI M S', '26MX230', 'G1', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('abiramidevasenapathy@gmail.com', 'abiramidevasenapathy@gmail.com', NULL, 'ABIRAMI D', '26MX301', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('balajiaditri28@gmail.com', 'balajiaditri28@gmail.com', NULL, 'ADITRI BALAJI', '26MX302', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('aishwaryaaselvaraj@gmail.com', 'aishwaryaaselvaraj@gmail.com', NULL, 'AISHWARYAA S K', '26MX303', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('akileshaki411@gmail.com', 'akileshaki411@gmail.com', NULL, 'AKILESH N', '26MX304', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('ananthan672020@gmail.com', 'ananthan672020@gmail.com', NULL, 'ANANTHA LAKSHMI A', '26MX305', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('ashritaa2809@gmail.com', 'ashritaa2809@gmail.com', NULL, 'ASHRITAA NAVANEETHA KRISHNAN', '26MX306', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('gkashwinkumar@gmail.com', 'gkashwinkumar@gmail.com', NULL, 'ASHWIN KUMAR G K', '26MX307', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('asina200107@gmail.com', 'asina200107@gmail.com', NULL, 'ASINA P', '26MX308', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('aswathck28@gmail.com', 'aswathck28@gmail.com', NULL, 'ASWATH NARAYANAN A C', '26MX309', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('balaaakash2005@gmail.com', 'balaaakash2005@gmail.com', NULL, 'BALA SUBRAMANIAN B', '26MX310', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('chakravarthydeepan584@gmail.com', 'chakravarthydeepan584@gmail.com', NULL, 'DEEPAN CHAKRAVARTHI S', '26MX311', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('dhanyalakshmi0103@gmail.com', 'dhanyalakshmi0103@gmail.com', NULL, 'DHANYA LAKSHMI M U', '26MX312', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('dharshinigsvd@gmail.com', 'dharshinigsvd@gmail.com', NULL, 'DHARSHINI G S', '26MX313', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('rdharshinim@gmail.com', 'rdharshinim@gmail.com', NULL, 'DHARSHINI R', '26MX314', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('dharunyamanikandan@gmail.com', 'dharunyamanikandan@gmail.com', NULL, 'DHARUNYA M P', '26MX315', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('elakkiyac43@gmail.com', 'elakkiyac43@gmail.com', NULL, 'ELAKKIYA C', '26MX316', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('esakirahul2@gmail.com', 'esakirahul2@gmail.com', NULL, 'ESAKI RAHUL M', '26MX317', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('gayathrijanagaraj@gmail.com', 'gayathrijanagaraj@gmail.com', NULL, 'GAYATHRI J', '26MX318', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('jairussj24@gmail.com', 'jairussj24@gmail.com', NULL, 'JAIRUS S', '26MX319', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('jeevashanmugam7774@gmail.com', 'jeevashanmugam7774@gmail.com', NULL, 'JEEVA S', '26MX320', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('joshikaramadoss29@gmail.com', 'joshikaramadoss29@gmail.com', NULL, 'JOSHIKA R', '26MX321', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('kalaranirv@gmail.com', 'kalaranirv@gmail.com', NULL, 'KALARANI R', '26MX322', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('kavipriyad1310@gmail.com', 'kavipriyad1310@gmail.com', NULL, 'KAVI PRIYA DHARSHINI B', '26MX323', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('keerthanaashokkumar25@gmail.com', 'keerthanaashokkumar25@gmail.com', NULL, 'KEERTHANA A R', '26MX324', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('kkirubhakaran1@gmail.com', 'kkirubhakaran1@gmail.com', NULL, 'KIRUBHAKARAN K', '26MX325', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('kriuthiyogitha@gmail.com', 'kriuthiyogitha@gmail.com', NULL, 'KRIUTHI YOGITHA A', '26MX326', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('meenakshimurali30@gmail.com', 'meenakshimurali30@gmail.com', NULL, 'MEENAKSHI M', '26MX327', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('mounishamuthusamy@gmail.com', 'mounishamuthusamy@gmail.com', NULL, 'MOUNISHA M', '26MX328', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('nabilabanu7618@gmail.com', 'nabilabanu7618@gmail.com', NULL, 'NABILA BANU R', '26MX329', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('nadhishbaskar16@gmail.com', 'nadhishbaskar16@gmail.com', NULL, 'NADHISH B', '26MX330', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('nareshwaran703@gmail.com', 'nareshwaran703@gmail.com', '26mx331@psgtech.ac.in', 'NARESHWARAN J', '26MX331', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('muralidharannatesh@gmail.com', 'muralidharannatesh@gmail.com', NULL, 'NATESH M', '26MX332', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('navyasureshkumar505@gmail.com', 'navyasureshkumar505@gmail.com', NULL, 'NAVYA S K', '26MX333', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('nigithag79799@gmail.com', 'nigithag79799@gmail.com', NULL, 'NIGITHA G', '26MX334', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('ushaa072005@gmail.com', 'ushaa072005@gmail.com', NULL, 'P USHA NANDHINI', '26MX335', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('pavatharinikathirvel@gmail.com', 'pavatharinikathirvel@gmail.com', NULL, 'PAVATHARINI K', '26MX336', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('poojamathesh6363@gmail.com', 'poojamathesh6363@gmail.com', NULL, 'POOJA M', '26MX337', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('rajamadhangi3092005@gmail.com', 'rajamadhangi3092005@gmail.com', NULL, 'RAJAMADHANGI G', '26MX338', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('rohinimurugathal@gmail.com', 'rohinimurugathal@gmail.com', NULL, 'ROHINI A', '26MX339', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('roycejoe06@gmail.com', 'roycejoe06@gmail.com', NULL, 'ROYCE JOE L', '26MX340', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('safeer2587@gmail.com', 'safeer2587@gmail.com', NULL, 'SAFEER AHAMED B', '26MX341', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('shafeeqsha1510@gmail.com', 'shafeeqsha1510@gmail.com', NULL, 'SHAFEEQ', '26MX342', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('shrutinimi345@gmail.com', 'shrutinimi345@gmail.com', NULL, 'SHRUTI ARUMUGAM', '26MX343', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('bsivakalai10@gmail.com', 'bsivakalai10@gmail.com', NULL, 'SIVAKALAI B', '26MX344', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('srithanvarsha25082005@gmail.com', 'srithanvarsha25082005@gmail.com', NULL, 'SRI THANVARSHA C', '26MX345', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('sridhanyachidambaram2005@gmail.com', 'sridhanyachidambaram2005@gmail.com', NULL, 'SRIDHANYA C', '26MX346', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('srinithishjk@gmail.com', 'srinithishjk@gmail.com', NULL, 'SRINITHISH J K', '26MX347', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('sruthishanmugasundaram8@gmail.com', 'sruthishanmugasundaram8@gmail.com', NULL, 'SRUTHI S', '26MX348', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('newsudharshan1@gmail.com', 'newsudharshan1@gmail.com', NULL, 'SUDHARSHAN K', '26MX349', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('swethapalanisamy81@gmail.com', 'swethapalanisamy81@gmail.com', NULL, 'SWETHA P', '26MX350', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('theekshnashrim@gmail.com', 'theekshnashrim@gmail.com', NULL, 'THEEKSHNASHRI M', '26MX351', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('valarilambiraiks@gmail.com', 'valarilambiraiks@gmail.com', NULL, 'VALARILAMBIRAI K S', '26MX352', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('vlvelayutham18@gmail.com', 'vlvelayutham18@gmail.com', NULL, 'VELAYUTHAM V L', '26MX353', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('crvenkatesh24@gmail.com', 'crvenkatesh24@gmail.com', NULL, 'VENKATESH C R', '26MX354', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('victorana7700@gmail.com', 'victorana7700@gmail.com', NULL, 'VICTOR ANAND C', '26MX355', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('vidhyabalu2006@gmail.com', 'vidhyabalu2006@gmail.com', NULL, 'VIDHYA B S', '26MX356', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('vishals18266@gmail.com', 'vishals18266@gmail.com', NULL, 'VISHAL S', '26MX357', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
('vivedivina2005@gmail.com', 'vivedivina2005@gmail.com', NULL, 'VIVE DIVINA J', '26MX358', 'G2', (SELECT id FROM public.batches WHERE batch_code = '26MX'), NULL, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb)
ON CONFLICT (reg_no) DO UPDATE SET
    personal_email = COALESCE(EXCLUDED.personal_email, existing.personal_email),
    college_email = COALESCE(existing.college_email, EXCLUDED.college_email),
    name = EXCLUDED.name,
    batch = EXCLUDED.batch,
    batch_id = EXCLUDED.batch_id,
    roles = EXCLUDED.roles;

-- Future-ready college identity for every 26MX student. The alias trigger
-- registers these addresses without replacing the personal-email identity.
UPDATE public.whitelist
SET college_email = lower(reg_no) || '@psgtech.ac.in'
WHERE reg_no ~ '^26MX[0-9]{3}$';

-- One supplied student has an additional personal address. Both addresses
-- are accepted for OTP and resolve to the same register number.
INSERT INTO public.whitelist_email_aliases (email, whitelist_email, email_type)
SELECT 'aditrib04@gmail.com', w.email, 'personal' FROM public.whitelist w WHERE w.reg_no = '26MX302'
ON CONFLICT (email) DO NOTHING;

UPDATE public.batches
SET status = 'active_junior', updated_at = now()
WHERE batch_code = '26MX';

DO $$
DECLARE
    roster_count INT;
    otp_ready_count INT;
BEGIN
    SELECT COUNT(*) INTO roster_count
    FROM public.whitelist
    WHERE reg_no LIKE '26MX%';

    SELECT COUNT(*) INTO otp_ready_count
    FROM public.whitelist
    WHERE reg_no LIKE '26MX%' AND personal_email IS NOT NULL;

    IF roster_count <> 117 THEN
        RAISE EXCEPTION '26MX roster validation failed: expected 117 rows, found %', roster_count;
    END IF;

    IF otp_ready_count <> 117 THEN
        RAISE EXCEPTION '26MX email validation failed: expected 117 OTP-ready rows, found %', otp_ready_count;
    END IF;

    RAISE NOTICE '16_seed_students_26mx.sql complete — % rostered, % OTP-ready.', roster_count, otp_ready_count;
END $$;

COMMIT;
