-- ============================================================
-- PSGMX Migration 44 — 44_device_tokens.sql
-- ============================================================
-- PRD Ch. 13.1: push notifications go through FCM, with the device token
-- stored "in a device_tokens table, one row per user-device pair." That
-- table never existed — apps/mobile/lib/services/notification_service.dart
-- only ever delivered pushes while the app was in the foreground (via a
-- Realtime subscription) or through client-scheduled local notifications.
-- A backgrounded or killed app received nothing. This table plus the
-- send-push Edge Function (supabase/functions/send-push) close that gap.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.device_tokens (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  token         TEXT NOT NULL UNIQUE,
  platform      TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON public.device_tokens(user_id);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "device_tokens_own_read" ON public.device_tokens
  FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "device_tokens_own_write" ON public.device_tokens
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "device_tokens_own_update" ON public.device_tokens
  FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "device_tokens_own_delete" ON public.device_tokens
  FOR DELETE TO authenticated USING (user_id = auth.uid());

CREATE TRIGGER set_device_tokens_updated_at
  BEFORE UPDATE ON public.device_tokens
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
