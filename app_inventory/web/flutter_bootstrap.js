{{flutter_js}}
{{flutter_build_config}}

// Only remove this app's legacy worker; never clear account storage or other apps.
window.simsApplyWebUpdate = async function () {
  if ('serviceWorker' in navigator) {
    const appBase = new URL(document.querySelector('base').href);
    for (const registration of await navigator.serviceWorker.getRegistrations()) {
      const scope = new URL(registration.scope);
      if (scope.origin === appBase.origin && scope.pathname === appBase.pathname) {
        await registration.unregister();
      }
    }
  }
  window.location.reload();
};

// Serve the rendering engine with the app, so startup does not depend on
// access to Google's CanvasKit CDN (which can be unavailable on this network).
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
