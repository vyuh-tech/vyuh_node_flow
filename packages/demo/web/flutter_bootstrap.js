{{flutter_js}}
{{flutter_build_config}}

(function() {
  var loader = document.getElementById('loader');
  var progressBar = document.getElementById('progress-bar');
  var progressText = document.getElementById('progress-text');

  function updateProgress(progress, text) {
    if (progressBar) {
      progressBar.style.width = Math.round(progress * 100) + '%';
    }
    if (progressText && text) {
      progressText.textContent = text;
    }
  }

  function hideLoader() {
    if (loader) {
      loader.classList.add('fade-out');
      setTimeout(function() { loader.remove(); }, 500);
    }
  }

  // Start with initial progress
  updateProgress(0.2, 'Loading');

  _flutter.loader.load({
    onEntrypointLoaded: async function(engineInitializer) {
      updateProgress(0.5, 'Initializing');

      var appRunner = await engineInitializer.initializeEngine();

      updateProgress(0.8, 'Starting');

      await appRunner.runApp();

      updateProgress(1, 'Ready');
      setTimeout(hideLoader, 300);
    }
  });
})();
