import { ref, onMounted } from 'vue';

export function usePubVersion(packageName: string) {
  const version = ref<string | null>(null);
  const loading = ref(true);
  const error = ref<string | null>(null);

  onMounted(async () => {
    try {
      // Use shields.io JSON endpoint - it's CORS-friendly and caches pub.dev responses
      const response = await fetch(
        `https://img.shields.io/pub/v/${packageName}.json`
      );
      if (!response.ok) throw new Error('Failed to fetch');
      const data = await response.json();
      // shields.io returns { name: "pub", value: "v0.15.0" }
      version.value = data.value?.replace(/^v/, '') || null;
    } catch (e) {
      error.value = 'Failed to fetch version';
      version.value = '0.20.0'; // Fallback to current version
    } finally {
      loading.value = false;
    }
  });

  return { version, loading, error };
}
