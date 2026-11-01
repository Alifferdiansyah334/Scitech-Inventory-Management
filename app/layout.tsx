import type { Metadata, Viewport } from 'next';
export const metadata: Metadata = {
  title: 'SIMS Scitech',
  description: 'Inventaris dan peminjaman barang internal Scitech.',
  icons: { icon: '/app/favicon.png', apple: '/app/icons/Icon-192.png' },
};
export const viewport: Viewport = { themeColor: '#0F2C59' };
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="id"><body style={{ margin: 0, background: '#0F2C59' }}>{children}</body></html>;
}
