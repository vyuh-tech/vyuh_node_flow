<script setup lang="ts">
// Individual shield components following CDX pattern

withDefaults(
    defineProps<{
      package?: string;
      github?: string;
      showLikes?: boolean;
      showLicense?: boolean;
      showCoverage?: boolean;
    }>(),
    {
      package: 'vyuh_node_flow',
      github: 'vyuh-tech/vyuh_node_flow',
      showLikes: true,
      showLicense: true,
      showCoverage: true,
    }
);
</script>

<template>
  <div class="shields-group">
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
</style>
