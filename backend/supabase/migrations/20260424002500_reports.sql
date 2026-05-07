-- =====================================================================
-- 25_reports : 신고 시스템 (Apple Guideline 1.2 / UGC 앱 필수)
--
--   - 사용자가 후기·보살·사용자를 신고
--   - 후기 신고 시 즉시 비공개(`reviews.is_public = false`) — admin 검토 후 복구
--   - admin은 reports 큐에서 처리
-- =====================================================================

create type public.report_target as enum ('review', 'bosal', 'user');
create type public.report_status as enum ('pending', 'resolved', 'dismissed');

create table public.reports (
  id            uuid                  primary key default gen_random_uuid(),
  reporter_id   uuid                  not null references auth.users(id) on delete cascade,
  target_kind   public.report_target  not null,
  target_id     uuid                  not null,
  reason        text                  not null,
  description   text,
  status        public.report_status  not null default 'pending',
  resolved_by   uuid                  references auth.users(id),
  resolved_at   timestamptz,
  resolution_note text,
  created_at    timestamptz           not null default now(),
  updated_at    timestamptz           not null default now()
);

create index reports_pending_idx
  on public.reports (status, created_at desc)
  where status = 'pending';
create index reports_target_idx
  on public.reports (target_kind, target_id);
create index reports_reporter_idx
  on public.reports (reporter_id, created_at desc);

create trigger reports_set_updated_at
  before update on public.reports
  for each row execute function public.tg_set_updated_at();


-- ---------- RLS ----------
alter table public.reports enable row level security;

-- 본인이 신고한 것만 조회 + admin은 모두
create policy reports_self_or_admin_select
  on public.reports for select
  using (reporter_id = auth.uid() or public.is_admin());

-- 누구나 자신을 reporter로 insert
create policy reports_self_insert
  on public.reports for insert
  with check (reporter_id = auth.uid());

-- 처리는 admin만
create policy reports_admin_update
  on public.reports for update
  using (public.is_admin())
  with check (public.is_admin());


-- ---------- 트리거: 후기 신고 즉시 비공개 ----------
create or replace function public.tg_reports_auto_hide_review()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.target_kind = 'review' then
    update public.reviews
       set is_public = false
     where id = new.target_id
       and is_public = true;  -- 이미 비공개면 noop
  end if;
  return new;
end;
$$;

drop trigger if exists reports_auto_hide_review on public.reports;
create trigger reports_auto_hide_review
  after insert on public.reports
  for each row execute function public.tg_reports_auto_hide_review();


-- ---------- admin RPC: 신고 처리 ----------
-- admin이 신고를 처리할 때 status 변경 + 후기인 경우 is_public 복구/유지 결정
create or replace function public.resolve_report(
  p_report_id uuid,
  p_resolution text,             -- 'resolved' | 'dismissed'
  p_restore_target boolean,      -- true면 후기 다시 공개 (dismissed인 경우 보통 true)
  p_note text default null
)
returns public.reports
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.reports%rowtype;
begin
  if not public.is_admin() then
    raise exception 'admin only' using errcode = '42501';
  end if;
  if p_resolution not in ('resolved', 'dismissed') then
    raise exception 'invalid resolution' using errcode = 'check_violation';
  end if;

  update public.reports
     set status = p_resolution::public.report_status,
         resolved_by = auth.uid(),
         resolved_at = now(),
         resolution_note = p_note
   where id = p_report_id
  returning * into v_row;

  if not found then
    raise exception 'report not found' using errcode = 'no_data_found';
  end if;

  -- 후기 복구 (기각 시 다시 공개)
  if v_row.target_kind = 'review' and p_restore_target then
    update public.reviews
       set is_public = true
     where id = v_row.target_id;
  end if;

  return v_row;
end;
$$;

revoke all on function public.resolve_report(uuid, text, boolean, text) from public;
grant execute on function public.resolve_report(uuid, text, boolean, text) to authenticated;
