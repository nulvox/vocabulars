{{flutter_js}}
{{flutter_build_config}}

(async () => {
  // Clear registrations left by older Flutter builds before starting the app.
  if ('serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(registrations.map((registration) => registration.unregister()));
  }
  if (window.caches) {
    await Promise.all((await caches.keys()).map((cache) => caches.delete(cache)));
  }

  const loadingText = document.querySelector('#loadingText');
  _flutter.loader.load({
    onEntrypointLoaded: async (engineInitializer) => {
      loadingText.textContent = 'Initializing engine...';
      const appRunner = await engineInitializer.initializeEngine();
      loadingText.textContent = 'Starting app...';
      await appRunner.runApp();
    },
  });
})();
