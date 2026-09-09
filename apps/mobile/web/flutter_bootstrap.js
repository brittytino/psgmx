{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      useColorEmoji: true,
    });
    const loaderElement = document.getElementById('loading');
    if (loaderElement) loaderElement.remove();
    await appRunner.runApp();
  },
});
