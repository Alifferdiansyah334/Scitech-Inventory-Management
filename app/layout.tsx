import type { Metadata, Viewport } from 'next';
export const metadata: Metadata = {
  title: 'SIMS Scitech',
  description: 'Inventaris dan peminjaman barang internal Scitech.',
  icons: { icon: '/app/favicon.png', apple: '/app/icons/Icon-192.png' },
};
export const viewport: Viewport = { themeColor: '#F7FAF4' };
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="id"><body style={{ margin: 0, background: '#F7FAF4' }}>{children}</body></html>;
}
