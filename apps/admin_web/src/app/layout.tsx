import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: '강남보살 관리자',
  description: '강남보살 운영 어드민 — 미공개',
  robots: { index: false, follow: false },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko" className="h-full antialiased">
      <body className="min-h-full flex flex-col bg-slate-50 text-slate-900">
        {children}
      </body>
    </html>
  );
}
