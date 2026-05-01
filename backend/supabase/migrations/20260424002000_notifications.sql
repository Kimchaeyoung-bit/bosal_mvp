-- =====================================================================
-- 20_notifications : user-scoped 알림 시스템
--
--   * notifications 테이블 + RLS (self-only select/update/delete)
--   * direct insert 금지 — RPC `enqueue_notification()` 또는 트리거만 작성
--   * mark_notification_read / mark_all_notifications_read RPC
--   * 예약 상태 변경 / 리뷰 작성 → 자동 알림 트리거
--   * Realtime publication 등록
--
--   설계 의도:
--   - type 은 text + CHECK 로 두어 신규 타입 추가 시 마이그레이션 없이도 가능
--     (단 frontend에서 분기하므로 함께 갱신 권장)
--   - data jsonb 로 deep-link 페이로드 자유 (예: reservation_id, bosal_id)
--   - read_at 컬럼으로 읽은 시각 별도 보존 (집계·리텐션 분석용)
--   - is_deleted 대신 hard delete (사용자 직접 삭제 가능)
-- =====================================================================

-- ---------- 테이블 ----------
create table if not exists public.notifications (
  id          uuid         primary key default gen_random_uuid(),
  user_id     uuid         not null references auth.users(id) on delete cascade,
  type        text         not null check (
    type in ('booking', 'review', 'system', 'invite')
  ),
  title       text         not null,
  body        text         not null,
  data        jsonb        not null default '{}'::jsonb,
  is_read     boolean      not null default false,
  read_at     timestamptz,
  created_at  timestamptz  not null default now(),
  updated_at  timestamptz  not null default now()
);

create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc);

create index if not exists notifications_user_unread_idx
  on public.notifications (user_id)
  where is_read = false;

create trigger notifications_set_updated_at
  before update on public.notifications
  for each row execute function public.tg_set_updated_at();


-- ---------- RLS ----------
alter table public.notifications enable row level security;

-- 본인 알림만 조회
create policy "notifications_self_select"
  on public.notifications for select
  using (user_id = auth.uid() or public.is_admin());

-- 클라이언트 직접 insert 금지 — RPC/트리거만 (admin 예외)
create policy "notifications_admin_insert"
  on public.notifications for insert
  with check (public.is_admin());

-- 본인은 is_read 만 수정 가능 (트리거로 강제)
create policy "notifications_self_update"
  on public.notifications for update
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

-- 본인은 자신의 알림 삭제 가능
create policy "notifications_self_delete"
  on public.notifications for delete
  using (user_id = auth.uid() or public.is_admin());


-- 본인 update 시 user_id / type / title / body / data 변경 차단 (read 토글만 허용)
create or replace function public.tg_notifications_immutable_fields()
returns trigger
language plpgsql as $$
begin
  if public.is_admin() then
    return new;
  end if;
  if new.user_id is distinct from old.user_id
     or new.type is distinct from old.type
     or new.title is distinct from old.title
     or new.body is distinct from old.body
     or new.data is distinct from old.data then
    raise exception 'only is_read/read_at may be updated' using errcode = '42501';
  end if;
  -- read_at 자동 보정
  if new.is_read and not old.is_read and new.read_at is null then
    new.read_at := now();
  end if;
  if not new.is_read then
    new.read_at := null;
  end if;
  return new;
end;
$$;

create trigger notifications_immutable_fields
  before update on public.notifications
  for each row execute function public.tg_notifications_immutable_fields();


-- ---------- RPC: 사용자가 호출 ----------

-- mark a single notification as read
create or replace function public.mark_notification_read(p_id uuid)
returns public.notifications
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.notifications%rowtype;
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  update public.notifications
     set is_read = true,
         read_at = now()
   where id = p_id
     and user_id = v_uid
  returning * into v_row;

  if not found then
    raise exception 'notification not found' using errcode = 'no_data_found';
  end if;
  return v_row;
end;
$$;

revoke all on function public.mark_notification_read(uuid) from public;
grant execute on function public.mark_notification_read(uuid) to authenticated;


-- mark all unread notifications as read for current user
create or replace function public.mark_all_notifications_read()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_count int;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  with upd as (
    update public.notifications
       set is_read = true,
           read_at = now()
     where user_id = v_uid
       and is_read = false
    returning 1
  )
  select count(*) into v_count from upd;
  return v_count;
end;
$$;

revoke all on function public.mark_all_notifications_read() from public;
grant execute on function public.mark_all_notifications_read() to authenticated;


-- ---------- 내부 헬퍼: 알림 발급 ----------
-- 트리거에서 사용. RLS 우회 (security definer).
create or replace function public.enqueue_notification(
  p_user_id uuid,
  p_type    text,
  p_title   text,
  p_body    text,
  p_data    jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  if p_user_id is null then
    return null; -- 수신자 미상이면 silent skip
  end if;
  insert into public.notifications (user_id, type, title, body, data)
       values (p_user_id, p_type, p_title, p_body, coalesce(p_data, '{}'::jsonb))
    returning id into v_id;
  return v_id;
end;
$$;

-- 내부 함수: 외부 호출 차단
revoke all on function public.enqueue_notification(uuid, text, text, text, jsonb) from public;


-- ---------- 트리거: 예약 상태 변경 → 알림 ----------
create or replace function public.tg_reservations_notify()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_bosal_owner_uid uuid;
  v_bosal_name      text;
  v_user_name       text;
begin
  -- 보살 소유자 (profiles.bosal_id == bosals.id) 식별
  select p.id into v_bosal_owner_uid
    from public.profiles p
   where p.bosal_id = coalesce(new.bosal_id, old.bosal_id)
   limit 1;

  select b.name into v_bosal_name
    from public.bosals b
   where b.id = coalesce(new.bosal_id, old.bosal_id)
   limit 1;

  select coalesce(p.display_name, '회원') into v_user_name
    from public.profiles p
   where p.id = coalesce(new.user_id, old.user_id)
   limit 1;

  if (TG_OP = 'INSERT') then
    -- 새 예약 요청 → 보살에게 알림
    perform public.enqueue_notification(
      v_bosal_owner_uid,
      'booking',
      '새 예약 요청',
      coalesce(v_user_name, '회원') || '님이 상담을 요청했습니다.',
      jsonb_build_object(
        'reservation_id', new.id,
        'bosal_id', new.bosal_id,
        'user_id', new.user_id,
        'status', new.status
      )
    );
    return new;
  end if;

  if (TG_OP = 'UPDATE') and new.status is distinct from old.status then
    -- 사용자에게 알림
    if new.status = 'confirmed' then
      perform public.enqueue_notification(
        new.user_id,
        'booking',
        '예약 확정',
        coalesce(v_bosal_name, '보살') || '님이 상담을 확정했습니다.',
        jsonb_build_object('reservation_id', new.id, 'bosal_id', new.bosal_id, 'status', 'confirmed')
      );
    elsif new.status = 'cancelled' then
      -- 누가 취소했는지에 따라 메시지 구분
      perform public.enqueue_notification(
        new.user_id,
        'booking',
        '예약 취소',
        '예약이 취소되었습니다.' ||
          coalesce(' 사유: ' || new.cancellation_reason, ''),
        jsonb_build_object(
          'reservation_id', new.id,
          'bosal_id', new.bosal_id,
          'status', 'cancelled',
          'reason', new.cancellation_reason
        )
      );
      -- 보살에게도 (사용자 취소인 경우)
      perform public.enqueue_notification(
        v_bosal_owner_uid,
        'booking',
        '예약 취소됨',
        coalesce(v_user_name, '회원') || '님의 예약이 취소되었습니다.',
        jsonb_build_object('reservation_id', new.id, 'user_id', new.user_id, 'status', 'cancelled')
      );
    elsif new.status = 'completed' then
      -- 사용자에게 후기 작성 유도
      perform public.enqueue_notification(
        new.user_id,
        'review',
        '후기를 남겨주세요',
        coalesce(v_bosal_name, '보살') || '님과의 상담은 어떠셨나요?',
        jsonb_build_object('reservation_id', new.id, 'bosal_id', new.bosal_id)
      );
    end if;
    return new;
  end if;

  return new;
end;
$$;

drop trigger if exists reservations_notify on public.reservations;
create trigger reservations_notify
  after insert or update on public.reservations
  for each row execute function public.tg_reservations_notify();


-- ---------- 트리거: 리뷰 작성 → 보살에게 알림 ----------
create or replace function public.tg_reviews_notify()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_bosal_owner_uid uuid;
  v_user_name       text;
begin
  if (TG_OP <> 'INSERT') then
    return new;
  end if;

  select p.id into v_bosal_owner_uid
    from public.profiles p where p.bosal_id = new.bosal_id limit 1;

  select coalesce(p.display_name, '회원') into v_user_name
    from public.profiles p where p.id = new.user_id limit 1;

  perform public.enqueue_notification(
    v_bosal_owner_uid,
    'review',
    '새 후기 도착',
    coalesce(v_user_name, '회원') || '님이 후기를 남겼습니다.',
    jsonb_build_object('review_id', new.id, 'bosal_id', new.bosal_id, 'rating', new.rating)
  );

  return new;
end;
$$;

drop trigger if exists reviews_notify on public.reviews;
create trigger reviews_notify
  after insert on public.reviews
  for each row execute function public.tg_reviews_notify();


-- ---------- Realtime publication ----------
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.notifications;
    exception when duplicate_object then
      null;
    end;
  end if;
end$$;
