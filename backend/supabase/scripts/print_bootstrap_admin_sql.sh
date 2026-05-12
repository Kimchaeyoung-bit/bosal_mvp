#!/usr/bin/env bash
# =====================================================================
# admin 부트스트랩 SQL 출력 — backend/supabase/.env 의 ADMIN_EMAIL 사용.
# 출력된 SQL 을 Supabase Dashboard → SQL Editor 에 붙여넣어 실행.
# =====================================================================

set -euo pipefail

env_file="$(cd "$(dirname "$0")/.." && pwd)/.env"

if [[ ! -f "$env_file" ]]; then
  echo "❌ $env_file 가 없습니다. backend/supabase/.env.example 을 복사해서 ADMIN_EMAIL 을 채우세요." >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a
source "$env_file"
set +a

if [[ -z "${ADMIN_EMAIL:-}" || "$ADMIN_EMAIL" == "admin@example.com" ]]; then
  echo "❌ backend/supabase/.env 의 ADMIN_EMAIL 을 실제 값으로 설정하세요." >&2
  exit 1
fi

cat <<SQL
-- 1) Supabase Dashboard → Auth → Users 에서 '$ADMIN_EMAIL' 로 사용자 생성 후
-- 2) 아래 SQL 을 SQL Editor 에 붙여넣고 실행:

update public.profiles
   set role = 'admin'
 where id = (select id from auth.users where email = '$ADMIN_EMAIL');

-- 검증:
select p.role, u.email
  from public.profiles p
  join auth.users u on u.id = p.id
 where u.email = '$ADMIN_EMAIL';
SQL
