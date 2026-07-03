// ecosystem.config.js — PM2 single-process config for production
// Usage on server:
//   pm2 delete all          # Kill all old duplicate stacks
//   pm2 start ecosystem.config.js
//   pm2 save

module.exports = {
  apps: [
    {
      name: 'psgmx',
      script: './node_modules/.bin/next',
      args: 'start',
      cwd: __dirname,

      // Single instance — Next.js handles its own internal concurrency.
      // DO NOT use cluster_mode here; it spawns multiple next-server processes
      // which is exactly the CPU issue you had.
      instances: 1,
      exec_mode: 'fork',

      env: {
        NODE_ENV: 'production',
        PORT: 3000,
      },

      // Auto-restart if RAM exceeds 400MB (safety net on 1 vCPU VPS)
      max_memory_restart: '400M',

      // Log management
      out_file:  './logs/out.log',
      error_file: './logs/error.log',
      merge_logs: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss',

      // Graceful restart settings
      kill_timeout: 5000,
      wait_ready:   true,
      listen_timeout: 10000,
    },
  ],
};
