-- Keep notification read state attached to the one logical PSGMX identity,
-- even when a student signs in through a personal or future college alias.
DROP POLICY IF EXISTS "notification_reads_own" ON public.notification_reads;

CREATE POLICY "notification_reads_own"
ON public.notification_reads
FOR ALL
TO authenticated
USING (user_id = public.current_user_id())
WITH CHECK (user_id = public.current_user_id());

