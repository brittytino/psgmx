-- ========================================
-- PSG MX PLACEMENT APP - SEED LIVE USERS
-- ========================================
-- This script safely bypasses OTP by directly 
-- populating the auth.users and auth.identities 
-- tables for all 123 whitelisted students.
-- 
-- Run this in your Supabase SQL Editor AFTER 01_MASTER_SETUP.sql
-- ========================================

DO $$
DECLARE
    r RECORD;
    v_uid UUID;
BEGIN
    FOR r IN SELECT * FROM public.whitelist LOOP
        -- Check if user already exists
        SELECT id INTO v_uid FROM auth.users WHERE email = r.email;
        
        IF v_uid IS NULL THEN
            v_uid := gen_random_uuid();
            
            INSERT INTO auth.users (
                instance_id, id, aud, role, email, encrypted_password, 
                email_confirmed_at, recovery_sent_at, last_sign_in_at, 
                raw_app_meta_data, raw_user_meta_data, created_at, updated_at, 
                confirmation_token, email_change, email_change_token_new, recovery_token
            ) VALUES (
                '00000000-0000-0000-0000-000000000000',
                v_uid,
                'authenticated',
                'authenticated',
                r.email,
                crypt('password123', gen_salt('bf')), -- Default password, though app uses OTP
                now(),
                now(),
                now(),
                '{"provider":"email","providers":["email"]}',
                '{}',
                now(),
                now(),
                '',
                '',
                '',
                ''
            );

            INSERT INTO auth.identities (
                id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
            ) VALUES (
                gen_random_uuid(), 
                v_uid, 
                format('{"sub":"%s","email":"%s"}', v_uid::text, r.email)::jsonb, 
                'email', 
                r.email, -- provider_id is typically the email for the 'email' provider
                now(), 
                now(), 
                now()
            );
            
            RAISE NOTICE 'Created auth user for: %', r.email;
        ELSE
            RAISE NOTICE 'Auth user already exists for: %', r.email;
        END IF;
    END LOOP;
END $$;
