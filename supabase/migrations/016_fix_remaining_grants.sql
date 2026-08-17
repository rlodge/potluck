-- ============================================================
-- 016 — Fix remaining missing table-level grants
--
-- Same root cause as 015 (potlucks): anon/authenticated are missing
-- SELECT/INSERT/UPDATE/DELETE across every public table, confirmed by
-- auditing information_schema.role_table_grants. Grants below are
-- scoped to exactly what the app's direct (non-service-role) client
-- calls need — traced against every `.from(...)` call site.
--
-- Deliberately NOT granted, to preserve 013's security design:
--   - INSERT/DELETE on claims, offers, rsvps: the app only ever
--     writes these through service-role API routes (capacity checks,
--     rate limiting, guest capability tokens). Granting direct INSERT
--     would let a client bypass create_claim()'s capacity lock and
--     over-claim items.
--   - Any grant on points_ledger: only touched via the set_points()
--     RPC (security definer, service-role invoked). No direct client
--     reads or writes exist in the app.
--   - UPDATE on invites: only the service role updates `accepted`;
--     granting it to authenticated would expose the existing loose
--     "using (true)" update policy unnecessarily.
--   - INSERT on cohosts: only created via the service-role invite
--     accept flow, never through the plain client.
-- ============================================================

-- needs: public reads, host/cohost-managed writes (both via plain client)
grant select on public.needs to anon, authenticated;
grant insert, update, delete on public.needs to authenticated;

-- claims / offers / rsvps: column-scoped reads only (mirrors 013's
-- PII lockdown — guest_email/guest_token stay unreadable). Writes are
-- service-role-only in the app.
grant select (id, need_id, potluck_id, profile_id, guest_name,
              quantity, verified, points_awarded, created_at)
  on public.claims to anon, authenticated;

grant select (id, potluck_id, profile_id, guest_name, created_at)
  on public.rsvps to anon, authenticated;

grant select (id, potluck_id, profile_id, guest_name, emoji, name,
              description, verified, points_awarded, created_at)
  on public.offers to anon, authenticated;

-- profiles: column-scoped reads (mirrors 013); direct client updates
-- own row (display name / avatar_url) via "Users can update own
-- profile" RLS, so UPDATE needs a real table-level grant.
grant select (id, display_name, avatar_url, total_points)
  on public.profiles to anon, authenticated;
grant update on public.profiles to authenticated;

-- invites: host-only via RLS (email column included, but only ever
-- visible to the host who created it). Host lists/creates/removes
-- invites through the plain client.
grant select, insert, delete on public.invites to authenticated;

-- cohosts: publicly readable list (RLS "viewable by everyone"),
-- self/host removal via plain client. Row creation is service-role
-- only (accept-invite flow).
grant select on public.cohosts to anon, authenticated;
grant delete on public.cohosts to authenticated;

-- cohost_invites: manager-only reads (013), host creates/removes
-- invites through the plain client. Acceptance lookup by the invitee
-- is service-role (cohost-invite/[code]/page.tsx), so no anon grant.
grant select, insert, delete on public.cohost_invites to authenticated;
