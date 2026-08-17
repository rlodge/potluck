-- ============================================================
-- 018 — RSVP party size
--
-- Lets an RSVP report how many people are coming (including the
-- RSVPer), not just a single headcount per RSVP row. Defaults to 1
-- so existing rows remain valid. Not guest-specific PII, so it's
-- safe to expose through the same column-scoped grants as guest_name
-- (see 013/016).
-- ============================================================

alter table public.rsvps
  add column if not exists guest_count integer not null default 1;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'rsvps_guest_count_positive'
  ) then
    alter table public.rsvps
      add constraint rsvps_guest_count_positive check (guest_count >= 1);
  end if;
end $$;

grant select (guest_count) on public.rsvps to anon, authenticated;
