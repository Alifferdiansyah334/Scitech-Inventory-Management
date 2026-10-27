import path from 'node:path';
import type { NextConfig } from 'next';
const config: NextConfig = {
  trailingSlash: true,
  experimental: { cpus: 1, serverActions: { bodySizeLimit: '5mb' } },
  outputFileTracingRoot: path.join(__dirname),
  outputFileTracingIncludes: { '/api/mobile/releases': ['./public/releases/**/*', './public/app/version.json'] },
  async rewrites() { return [{ source: '/app/', destination: '/app/index.html' }]; },
};
export default config;
