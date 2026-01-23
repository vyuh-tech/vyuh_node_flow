<script lang="ts" setup>
import DefaultTheme from 'vitepress/theme';
import DemoBanner from './components/DemoBanner.vue';

const {Layout} = DefaultTheme;
</script>

<template>
  <Layout>
    <!-- Banner at the top of all pages -->
    <template #layout-top>
      <DemoBanner/>
    </template>
  </Layout>
</template>
