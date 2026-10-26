{{flutter_js}}
{{flutter_build_config}}

(function () {
  var userAgent = (navigator && navigator.userAgent) ? navigator.userAgent : '';
  var isIOS = /iPad|iPhone|iPod/.test(userAgent) ||
    (userAgent.indexOf('Macintosh') !== -1 && navigator.maxTouchPoints > 1);

  // Unconditionally unregister all existing service workers and clear stale caches.
  // Stale service workers and cached assets trigger memory exhaustion / reload loops
  // in WebKit (Safari & Chrome on iOS), causing process termination ("Can't open this page").
  try {
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
  } catch (e) {
    // Ignore storage/worker access errors in private browsing
  }

  _flutter.loader.load({
    serviceWorkerSettings: null,
    onEntrypointLoaded: async function (engineInitializer) {
      try {
        var engineConfig = {
          useColorEmoji: true,
          canvasKitVariant: 'auto',
        };

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
        // Fallback: try basic CPU-only initialization if WebGL context failed
        if (engineInitializer && !window.__psgmx_fallback_attempted) {
          window.__psgmx_fallback_attempted = true;
          const fallbackRunner = await engineInitializer.initializeEngine({
            canvasKitForceCpuOnly: true,
          });
          await fallbackRunner.runApp();
        }
      }
    },
  });
})();
