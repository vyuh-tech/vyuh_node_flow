<script setup lang="ts">
import {Icon} from '@iconify/vue';
import {onMounted, ref} from 'vue';

// Individual shield components following CDX pattern

const props = withDefaults(
    defineProps<{
      package?: string;
      github?: string;
      showLikes?: boolean;
      showVersion?: boolean;
      showLicense?: boolean;
      showCoverage?: boolean;
      compact?: boolean;
    }>(),
    {
      package: 'vyuh_node_flow',
      github: 'vyuh-tech/vyuh_node_flow',
      showLikes: true,
      showVersion: true,
      showLicense: true,
      showCoverage: true,
      compact: false,
    }
);

const githubStars = ref<string | null>(null);
const pubLikes = ref<string | null>(null);

const fetchMetric = async (url: string): Promise<string | null> => {
  const response = await fetch(url);
  if (!response.ok) return null;

  const metric = await response.json();
  return typeof metric.value === 'string' ? metric.value : null;
};

onMounted(async () => {
  if (!props.compact) return;

  const [starsResult, likesResult] = await Promise.allSettled([
    fetchMetric(`https://img.shields.io/github/stars/${props.github}.json`),
    fetchMetric(`https://img.shields.io/pub/likes/${props.package}.json`),
  ]);

  if (starsResult.status === 'fulfilled') {
    githubStars.value = starsResult.value;
  }

  if (likesResult.status === 'fulfilled') {
    pubLikes.value = likesResult.value;
  }
});
</script>

<template>
  <div v-if="compact" class="proof-chips" aria-label="Package adoption">
    <a
      :href="`https://github.com/${github}`"
      target="_blank"
      rel="noopener noreferrer"
      class="proof-chip"
      :aria-label="githubStars ? `${githubStars} GitHub stars` : 'GitHub stars'"
      :title="githubStars ? `${githubStars} GitHub stars` : 'GitHub stars'"
    >
      <span class="proof-chip-icon proof-chip-icon-github" aria-hidden="true">
        <Icon icon="simple-icons:github" />
      </span>
      <span class="proof-chip-copy">
        <span class="proof-chip-label">GitHub stars</span>
        <strong>{{ githubStars ?? '—' }}</strong>
      </span>
    </a>

    <a
      :href="`https://pub.dev/packages/${package}/score`"
      target="_blank"
      rel="noopener noreferrer"
      class="proof-chip"
      :aria-label="pubLikes ? `${pubLikes} pub.dev likes` : 'pub.dev likes'"
      :title="pubLikes ? `${pubLikes} pub.dev likes` : 'pub.dev likes'"
    >
      <span class="proof-chip-icon proof-chip-icon-pub" aria-hidden="true">
        <Icon icon="simple-icons:dart" />
      </span>
      <span class="proof-chip-copy">
        <span class="proof-chip-label">pub.dev likes</span>
        <strong>{{ pubLikes ?? '—' }}</strong>
      </span>
    </a>
  </div>

  <div v-else class="shields-group">
    <!-- GitHub stars badge -->
    <a
        :href="`https://github.com/${github}`"
        target="_blank"
        rel="noopener noreferrer"
        class="shield-link"
    >
      <img alt="GitHub Repo stars"
           class="shield-badge"
           :src="`https://img.shields.io/github/stars/${github}?style=for-the-badge&logo=github&labelColor=grey`">
    </a>

    <!-- pub.dev version badge -->
    <a
        v-if="showVersion"
        :href="`https://pub.dev/packages/${package}`"
        target="_blank"
        rel="noopener noreferrer"
        class="shield-link"
    >
      <img
          :src="`https://img.shields.io/pub/v/${package}?style=for-the-badge&logo=dart&logoColor=white&color=0175C2`"
          alt="Pub Version"
          class="shield-badge"
      />
    </a>

    <!-- pub.dev likes badge -->
    <a
        v-if="showLikes"
        :href="`https://pub.dev/packages/${package}/score`"
        target="_blank"
        rel="noopener noreferrer"
        class="shield-link"
    >
      <img
          :src="`https://img.shields.io/pub/likes/${package}?style=for-the-badge&logo=dart&logoColor=white&label=likes&color=0175C2`"
          alt="Pub Likes"
          class="shield-badge"
      />
    </a>

    <!-- License badge -->
    <a
        v-if="showLicense"
        :href="`https://github.com/${github}/blob/main/LICENSE`"
        target="_blank"
        rel="noopener noreferrer"
        class="shield-link"
    >
      <img
          :src="`https://img.shields.io/github/license/${github}?style=for-the-badge&color=yellow`"
          alt="License"
          class="shield-badge"
      />
    </a>

    <a
        v-if="showCoverage"
        href="https://codecov.io/gh/vyuh-tech/vyuh_node_flow"
       target="_blank"
       rel="noopener noreferrer"
       class="shield-link"
    >
      <img alt="Codecov"
           src="https://img.shields.io/codecov/c/github/vyuh-tech/vyuh_node_flow?token=IXKTYE4ENW&style=for-the-badge&logo=codecov">
    </a>

  </div>
</template>

<style scoped>
.shields-group {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
}

.shield-link {
  display: inline-block;
  text-decoration: none;
  transition: transform 0.15s ease, opacity 0.15s ease;
}

.shield-link:hover {
  transform: translateY(-2px);
  opacity: 0.9;
}

.shield-badge {
  display: inline-block;
  height: auto;
}

.proof-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 0.625rem;
  margin-bottom: 0;
}

.proof-chip {
  display: inline-flex;
  min-height: 42px;
  align-items: center;
  gap: 0.625rem;
  padding: 0.375rem 0.75rem 0.375rem 0.375rem;
  color: #0f172a;
  text-decoration: none;
  background: #ffffff;
  border: 1px solid rgba(148, 163, 184, 0.42);
  border-radius: 12px;
  box-shadow: 0 10px 24px -20px rgba(15, 23, 42, 0.65);
  transition: transform 160ms var(--vn-ease-out), border-color 160ms ease-out, box-shadow 160ms ease-out;
}

.proof-chip:hover {
  color: #0f172a;
  border-color: rgba(37, 99, 235, 0.55);
  box-shadow:
    0 14px 30px -20px rgba(37, 99, 235, 0.65),
    0 0 0 3px rgba(37, 99, 235, 0.07);
  transform: translateY(-2px);
}

.proof-chip:focus-visible {
  outline: 2px solid #2563eb;
  outline-offset: 2px;
}

.proof-chip-icon {
  display: grid;
  width: 30px;
  height: 30px;
  flex: 0 0 30px;
  place-items: center;
  color: white;
  border-radius: 8px;
}

.proof-chip-icon svg {
  width: 15px;
  height: 15px;
}

.proof-chip-icon-github {
  background: #24292f;
}

.proof-chip-icon-pub {
  background: #0175c2;
}

.proof-chip-copy {
  display: grid;
  grid-template-columns: auto auto;
  align-items: baseline;
  column-gap: 0.5rem;
  line-height: 1;
}

.proof-chip-label {
  font-size: 0.75rem;
  font-weight: 600;
  color: #475569;
}

.proof-chip strong {
  font-size: 0.875rem;
  font-variant-numeric: tabular-nums;
  color: #0f172a;
}

.dark .proof-chip {
  color: #f8fafc;
  background: #18181b;
  border-color: rgba(113, 113, 122, 0.62);
}

.dark .proof-chip:hover {
  color: #f8fafc;
  border-color: rgba(96, 165, 250, 0.68);
}

.dark .proof-chip-label {
  color: #a1a1aa;
}

.dark .proof-chip strong {
  color: #f8fafc;
}

@media (max-width: 389px) {
  .proof-chips {
    width: 100%;
  }

  .proof-chip {
    flex: 1 1 100%;
  }
}
</style>
