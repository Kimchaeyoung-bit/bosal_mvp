import { cookies } from 'next/headers';
import { createServerClient } from '@supabase/ssr';

/// Server Component / Route Handler / Server Action 용 Supabase 클라이언트.
///
/// Next.js 15+에서 cookies() 가 async 라 await 필요. 호출 컴포넌트도 async.
export async function createSupabaseServerClient() {
  const cookieStore = await cookies();
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            for (const { name, value, options } of cookiesToSet) {
              cookieStore.set(name, value, options);
            }
          } catch {
            // Server Component에서 호출되면 set 불가 — middleware가 처리.
          }
        },
      },
    },
  );
}
