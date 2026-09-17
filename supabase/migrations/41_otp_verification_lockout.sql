-- Server-enforced OTP verification lockout shared by web and mobile clients.
CREATE TABLE IF NOT EXISTS public.otp_verification_attempts (
  email TEXT PRIMARY KEY,
  failed_count INTEGER NOT NULL DEFAULT 0 CHECK (failed_count >= 0),
  last_failed_at TIMESTAMPTZ,
  locked_until TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.otp_verification_attempts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.otp_verification_attempts FROM anon, authenticated;
GRANT ALL ON public.otp_verification_attempts TO service_role;

COMMENT ON TABLE public.otp_verification_attempts IS
  'Service-role-only OTP failure state. Three invalid attempts lock an email for 15 minutes.';
