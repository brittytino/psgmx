-- Migration 14: Update app_config to v5.0.0 for mobile and web release
UPDATE public.app_config
SET
    latest_version = '5.0.0',
    min_required_version = '4.0.0',
    force_update = false,
    update_message = 'PSGMX v5.0.0 is live! New portal layout, DiceBear avatars, and improved performance.',
    github_release_url = 'https://github.com/brittytino/psgmx/releases/latest',
    android_download_url = 'https://github.com/brittytino/psgmx/releases/latest',
    updated_at = now();
