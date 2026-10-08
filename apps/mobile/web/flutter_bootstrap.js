{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      useColorEmoji: true,
    });
    // Remove the loading spinner only after the engine has initialised.
    // On slow connections / iOS, this prevents a flash of empty white space.
    const loaderElement = document.getElementById('loading');
    if (loaderElement) {
      loaderElement.style.transition = 'opacity 0.3s ease';
      loaderElement.style.opacity = '0';
      setTimeout(() => { loaderElement.remove(); }, 350);
    }
    await appRunner.runApp();
  },
});
