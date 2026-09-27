import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Note: 'standalone' output is intentionally NOT set here.
  // Vercel has its own serverless bundling system that is incompatible with
  // Next.js standalone mode. Firebase Hosting (server-side) uses standalone
  // via the Dockerfile, which is handled separately in the firebase workflow.
  poweredByHeader: false,
  allowedDevOrigins: ['127.0.0.1'],

  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'X-Frame-Options', value: 'DENY' },
          { key: 'Strict-Transport-Security', value: 'max-age=31536000; includeSubDomains' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
        ],
      },
    ];
  },
  experimental: {
    optimizePackageImports: ['lucide-react', 'framer-motion', 'recharts'],
    // The compiler API is more reliable across npm/CI environments.
    useTypeScriptCli: false,
  },
};

export default nextConfig;
