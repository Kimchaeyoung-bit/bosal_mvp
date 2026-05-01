-- =====================================================================
-- 21_admin_analytics
--
--   어드민 전용 보살별 분석 RPC.
--   - 기존 집계 뷰 (v_bosal_call_stats, v_bosal_reservation_button_stats)
--     를 bosals 테이블과 LEFT JOIN 하여 0건 보살도 누락 없이 반환.
--   - SECURITY DEFINER + is_admin() 가드 — call_events RLS(admin-only) 우회.
-- =====================================================================

create or replace function public.admin_list_bosal_analytics()
returns table (
  bosal_id              uuid,
  bosal_name            text,
  is_published          boolean,
  rating_avg            numeric,
  review_count          int,
  consult_request_count int,
  call_total            int,
  call_24h              int,
  call_7d               int,
  call_30d              int,
  resv_btn_total        int,
  resv_btn_24h          int,
  resv_btn_7d           int,
  resv_btn_30d          int
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'admin only' using errcode = '42501';
  end if;

  return query
  select
    b.id                                          as bosal_id,
    b.name                                        as bosal_name,
    b.is_published                                as is_published,
    coalesce(b.rating_avg, 0)::numeric            as rating_avg,
    coalesce(b.review_count, 0)::int              as review_count,
    coalesce(b.consult_request_count, 0)::int     as consult_request_count,
    coalesce(c.total_calls, 0)::int               as call_total,
    coalesce(c.calls_24h, 0)::int                 as call_24h,
    coalesce(c.calls_7d, 0)::int                  as call_7d,
    coalesce(c.calls_30d, 0)::int                 as call_30d,
    coalesce(r.total_taps, 0)::int                as resv_btn_total,
    coalesce(r.taps_24h, 0)::int                  as resv_btn_24h,
    coalesce(r.taps_7d, 0)::int                   as resv_btn_7d,
    coalesce(r.taps_30d, 0)::int                  as resv_btn_30d
  from public.bosals b
  left join public.v_bosal_call_stats c
         on c.bosal_id = b.id
  left join public.v_bosal_reservation_button_stats r
         on r.bosal_id = b.id
  where b.deleted_at is null
  order by call_24h desc, b.created_at desc;
end;
$$;

revoke all on function public.admin_list_bosal_analytics() from public;
grant execute on function public.admin_list_bosal_analytics() to authenticated;
