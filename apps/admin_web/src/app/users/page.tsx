import { createSupabaseServerClient } from '@/lib/supabase/server';
import AdminShell from '@/components/admin-shell';
import UsersTable from './users-table';
import type { ProfileRow } from '@/lib/types';

export const metadata = {
  title: '사용자 관리 — 강남보살 관리자',
};

export const dynamic = 'force-dynamic';

export default async function UsersPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; role?: string }>;
}) {
  const sp = await searchParams;
  const q = (sp.q ?? '').trim();
  const role = sp.role;

  const supabase = await createSupabaseServerClient();
  let query = supabase
    .from('profiles')
    .select('id,role,display_name,bosal_id,avatar_url,created_at,deleted_at')
    .order('created_at', { ascending: false })
    .limit(500);
  if (q) query = query.ilike('display_name', `%${q}%`);
  if (role && role !== 'all') query = query.eq('role', role);
  const { data, error } = await query;

  return (
    <AdminShell active="/users">
      <h2 className="mb-4 text-xl font-bold text-slate-900">사용자 관리</h2>
      <form className="mb-4 flex flex-wrap items-center gap-2">
        <input
          type="search"
          name="q"
          defaultValue={q}
          placeholder="표시명 검색"
          className="w-64 rounded-md border border-slate-300 bg-white px-3 py-1.5 text-sm"
        />
        <select
          name="role"
          defaultValue={role ?? 'all'}
          className="rounded-md border border-slate-300 bg-white px-3 py-1.5 text-sm"
        >
          <option value="all">전체 역할</option>
          <option value="user">user</option>
          <option value="bosal">bosal</option>
          <option value="admin">admin</option>
        </select>
        <button
          type="submit"
          className="rounded-md border border-slate-300 bg-white px-3 py-1.5 text-sm font-semibold text-slate-700 hover:bg-slate-50"
        >
          검색
        </button>
      </form>

      {error ? (
        <div className="rounded-md border border-red-200 bg-red-50 p-4 text-sm text-red-700">
          {error.message}
        </div>
      ) : (
        <UsersTable rows={(data ?? []) as ProfileRow[]} />
      )}
    </AdminShell>
  );
}
