{{flutter_js}}
{{flutter_build_config}}

(function () {
  var userAgent = (navigator && navigator.userAgent) ? navigator.userAgent : '';
  var isIOS = /iPad|iPhone|iPod/.test(userAgent) ||
    (userAgent.indexOf('Macintosh') !== -1 && navigator.maxTouchPoints > 1);

  // Set early global Flutter configuration for CanvasKit
  window.flutterConfiguration = {
    canvasKitForceCpuOnly: isIOS,
    canvasKitMaximumSurfaces: isIOS ? 1 : 2,
    canvasKitVariant: 'auto',
  };

  // Safe one-time legacy cache and worker cleanup
  try {
    var CLEANUP_KEY = 'psgmx_cleanup_v20261027';
    if (!localStorage.getItem(CLEANUP_KEY)) {
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
      localStorage.setItem(CLEANUP_KEY, 'true');
    }
  } catch (e) {
    // Ignore storage/worker access errors in private browsing
  }

  var engineConfig = {
    useColorEmoji: true,
    canvasKitVariant: 'auto',
    canvasKitForceCpuOnly: isIOS,
    canvasKitMaximumSurfaces: isIOS ? 1 : 2,
  };

  _flutter.loader.load({
    config: engineConfig,
    serviceWorkerSettings: null,
    onEntrypointLoaded: async function (engineInitializer) {
      try {
        const appRunner = await engineInitializer.initializeEngine(engineConfig);

        const loaderElement = document.getElementById('loading');
        if (loaderElement) {
          loaderElement.style.transition = 'opacity 0.25s ease';
          loaderElement.style.opacity = '0';
          setTimeout(() => { loaderElement.remove(); }, 280);
        }

        await appRunner.runApp();
      } catch (err) {
        console.error('[PSGMX Engine Initialization Error]', err);
        // Fallback: try basic CPU-only single-surface initialization
        if (engineInitializer && !window.__psgmx_fallback_attempted) {
          window.__psgmx_fallback_attempted = true;
          const fallbackRunner = await engineInitializer.initializeEngine({
            canvasKitForceCpuOnly: true,
            canvasKitMaximumSurfaces: 1,
          });
          await fallbackRunner.runApp();
        }
      }
    },
  });
})();

