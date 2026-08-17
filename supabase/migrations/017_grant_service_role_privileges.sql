-- ============================================================
-- 017 — Grant service_role its missing table privileges
--
-- Same root cause as 015/016: this project's default privileges
-- (ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public) only
-- hand anon/authenticated/service_role TRUNCATE/REFERENCES/TRIGGER on
-- newly created tables — never SELECT/INSERT/UPDATE/DELETE. 015 and
-- 016 patched anon/authenticated per-table, but neither granted
-- service_role anything, so it was left with zero read/write access
-- to any table it created via migration.
--
-- service_role is how every participant write (rsvps/claims/offers),
-- host verification, invite acceptance, and co-host acceptance route
-- reaches the database (see participant-api.ts, verify/route.ts,
-- invite/[code]/accept/route.ts, cohost-invite/[code]/route.ts). All
-- of them have been failing since 013 introduced the lockdown:
-- resolveWriteContext's `potlucks` lookup silently returns no row
-- (permission denied, error ignored), so every RSVP/claim/offer
-- write 404s or 500s before it ever reaches an insert.
--
-- service_role bypasses RLS by design — it only runs after the route
-- has independently authorized the caller — so unlike anon/
-- authenticated it gets full CRUD on every table it actually touches,
-- with no column/row scoping needed. points_ledger is deliberately
-- excluded: it's only ever touched via the set_points() RPC, which is
-- security definer and runs as its owner (postgres), so service_role
-- never needs a direct table grant there.
-- ============================================================

grant select, insert, update, delete on
  public.potlucks,
  public.needs,
  public.claims,
  public.offers,
  public.rsvps,
  public.profiles,
  public.invites,
  public.cohosts,
  public.cohost_invites
to service_role;
