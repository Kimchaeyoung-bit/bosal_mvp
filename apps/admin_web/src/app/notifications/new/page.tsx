import AdminShell from '@/components/admin-shell';
import BroadcastForm from './broadcast-form';

export const metadata = {
  title: '공지 발송 — 강남보살 관리자',
};

export default function NewNotificationPage() {
  return (
    <AdminShell active="/">
      <h2 className="mb-2 text-xl font-bold text-slate-900">공지 발송</h2>
      <p className="mb-6 text-sm text-slate-500">
        선택한 대상에게 시스템 알림을 발송합니다. 발송 후 모바일 앱에서 In-app
        알림 화면 + 미읽음 배지에 즉시 반영됩니다.
      </p>
      <BroadcastForm />
    </AdminShell>
  );
}
