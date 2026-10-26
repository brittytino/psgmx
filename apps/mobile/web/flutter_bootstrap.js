{{flutter_js}}
{{flutter_build_config}}

(function () {
  var userAgent = (navigator && navigator.userAgent) ? navigator.userAgent : '';
  var isIOS = /iPad|iPhone|iPod/.test(userAgent) ||
    (userAgent.indexOf('Macintosh') !== -1 && navigator.maxTouchPoints > 1);

  // If iOS Safari experienced repeated reloads/crashes, clear stale Service Worker caches
  try {
    var bootCount = parseInt(sessionStorage.getItem('psgmx_webkit_boot_attempts') || '0', 10);
    if (bootCount >= 2) {
      sessionStorage.removeItem('psgmx_webkit_boot_attempts');
      if ('serviceWorker' in navigator) {
        navigator.serviceWorker.getRegistrations().then(function (registrations) {
          for (var i = 0; i < registrations.length; i++) {
            registrations[i].unregister();
          }
        });
      }
      if ('caches' in window) {
        caches.keys().then(function (names) {
          for (var i = 0; i < names.length; i++) {
            caches.delete(names[i]);
          }
        });
      }
    } else {
      sessionStorage.setItem('psgmx_webkit_boot_attempts', String(bootCount + 1));
    }
  } catch (e) {
    // Ignore private browsing storage errors
  }

  _flutter.loader.load({
    onEntrypointLoaded: async function (engineInitializer) {
      try {
        // Enforce strict WebGL/CanvasKit overlay limits on mobile WebKit to
        // prevent exceeding iOS Safari's GPU texture and memory quotas.
        var engineConfig = {
          useColorEmoji: true,
          canvasKitMaximumSurfaces: isIOS ? 1 : 2,
          canvasKitVariant: 'auto',
        };

        const appRunner = await engineInitializer.initializeEngine(engineConfig);

        // Clear crash counter once engine is successfully running
        try {
          sessionStorage.removeItem('psgmx_webkit_boot_attempts');
        } catch (e) {}

        const loaderElement = document.getElementById('loading');
        if (loaderElement) {
          loaderElement.style.transition = 'opacity 0.25s ease';
          loaderElement.style.opacity = '0';
          setTimeout(() => { loaderElement.remove(); }, 280);
        }

        await appRunner.runApp();
      } catch (err) {
        console.error('[PSGMX Engine Initialization Error]', err);
        // Fallback: try basic single-surface initialization if default failed
        if (engineInitializer && !window.__psgmx_fallback_attempted) {
          window.__psgmx_fallback_attempted = true;
          const fallbackRunner = await engineInitializer.initializeEngine({
            canvasKitMaximumSurfaces: 1,
          });
          await fallbackRunner.runApp();
        }
      }
    },
  });
})();
