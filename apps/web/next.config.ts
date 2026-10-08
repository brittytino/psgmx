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
        source: '/api/:path*',
        headers: [
          { key: 'Access-Control-Allow-Origin', value: '*' },
          { key: 'Access-Control-Allow-Methods', value: 'GET, POST, PUT, PATCH, DELETE, OPTIONS' },
          { key: 'Access-Control-Allow-Headers', value: 'Content-Type, Authorization, x-client-info, apikey, x-request-id, X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Date, X-Api-Version, x-psgmx-client, X-Psgmx-Client' },
        ],
      },
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
