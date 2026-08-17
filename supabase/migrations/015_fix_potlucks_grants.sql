-- ============================================================
-- 015 — Fix missing table-level grants on public.potlucks
--
-- anon/authenticated were missing SELECT/INSERT/UPDATE/DELETE on
-- potlucks (only had TRUNCATE/REFERENCES/TRIGGER, likely from an
-- accidental revoke or a default-privilege gap). RLS policies were
-- never the problem; Postgres was rejecting the query before RLS
-- ever got evaluated. Several other tables' RLS policies (needs,
-- offers, invites, rsvps) run raw subqueries against potlucks as the
-- calling role, so this one gap surfaced as failures across the app,
-- not just on direct potlucks queries.
-- ============================================================

grant select on public.potlucks to anon, authenticated;
grant insert, update, delete on public.potlucks to authenticated;
