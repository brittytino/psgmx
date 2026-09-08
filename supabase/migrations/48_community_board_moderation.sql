-- ============================================================
-- PSGMX Migration 48 — 48_community_board_moderation.sql
-- ============================================================
-- PRD Ch. 14.3 (Community Board): "project collaboration, open source
-- opportunities, alumni-hosted learning events, career information
-- sessions... mentoring circles. Every post is moderated. Posts resembling
-- official drive announcements are removed." The backing table
-- (collaboration_posts, migration 04) already exists and already isn't
-- restricted to alumni at the RLS level despite being named/commented as
-- an "alumni marketplace" — but it has no moderation column at all, and no
-- mobile UI ever read it (only apps/web/app/alumni/marketplace/page.tsx did,
-- alumni-routed only).
--
-- Rather than a full pre-publish approval queue (a cold-start problem for a
-- <250-person department community — nothing would ever be visible until a
-- moderator acts), this adds post-hoc moderation: posts are visible
-- immediately, and faculty/HOD/PR can hide one that shouldn't be there
-- (e.g. resembles an official drive announcement). That is a deliberate,
-- documented deviation from a strict pre-publish reading of "every post is
-- moderated" — flagging it rather than silently redefining the term, same
-- as the announcement-templates deviation noted earlier this project.
-- ============================================================

ALTER TABLE public.collaboration_posts
  ADD COLUMN IF NOT EXISTS moderation_status TEXT NOT NULL DEFAULT 'approved'
    CHECK (moderation_status IN ('approved', 'hidden')),
  ADD COLUMN IF NOT EXISTS moderated_by UUID REFERENCES public.users(id),
  ADD COLUMN IF NOT EXISTS moderated_at TIMESTAMPTZ;

-- Replace the SELECT policy so a hidden post disappears for everyone except
-- its author and moderators (moderators covered by the new policy below).
DROP POLICY IF EXISTS "collaboration_posts_select" ON collaboration_posts;
CREATE POLICY "collaboration_posts_select" ON collaboration_posts FOR SELECT TO authenticated
    USING (
        is_active = true
        AND (moderation_status = 'approved' OR posted_by = auth.uid())
        AND (
            visibility = 'department'
            OR posted_by = auth.uid()
            OR EXISTS (
                SELECT 1 FROM users u1, users u2
                WHERE u1.id = auth.uid() AND u2.id = collaboration_posts.posted_by
                  AND visibility = 'batch' AND u1.batch_id = u2.batch_id
            )
        )
    );

CREATE POLICY "collaboration_posts_moderate" ON collaboration_posts FOR SELECT TO authenticated
    USING (is_faculty_or_hod(auth.uid()) OR is_placement_rep(auth.uid()));

CREATE OR REPLACE FUNCTION public.moderate_collaboration_post(p_post_id UUID, p_hide BOOLEAN)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT (is_faculty_or_hod(auth.uid()) OR is_placement_rep(auth.uid())) THEN
    RAISE EXCEPTION 'Not authorized to moderate the community board';
  END IF;

  UPDATE public.collaboration_posts
  SET moderation_status = CASE WHEN p_hide THEN 'hidden' ELSE 'approved' END,
      moderated_by = auth.uid(),
      moderated_at = now()
  WHERE id = p_post_id;
END;
$$;

REVOKE ALL ON FUNCTION public.moderate_collaboration_post(UUID, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.moderate_collaboration_post(UUID, BOOLEAN) TO authenticated;
