<script setup lang="ts">
import {computed, nextTick, onMounted, ref} from 'vue';
import {Icon} from '@iconify/vue';

export interface CommunityProject {
  title: string;
  description: string;
  authorHandle: string;
  href: string;
  media: {
    type: 'image' | 'video';
    src: string;
    alt: string;
    poster?: string;
  };
}

const props = defineProps<{
  projects: CommunityProject[];
}>();

const track = ref<HTMLElement | null>(null);
const activeIndex = ref(0);

const placeholderProjects: CommunityProject[] = [
  {
    title: 'Your visual tool',
    description:
      'Show the community what you built with Vyuh Node Flow and the problem it helps people solve.',
    authorHandle: '@author_handle',
    href: 'https://github.com/vyuh-tech/vyuh_node_flow/issues/new?title=Community%20showcase%20submission',
    media: {
      type: 'image',
      src: '',
      alt: 'Reserved space for a community project image or video',
    },
  },
  {
    title: 'A workflow that ships',
    description:
      'Share a short demo, the decisions behind your flow, and a link where people can explore it.',
    authorHandle: '@author_handle',
    href: 'https://github.com/vyuh-tech/vyuh_node_flow/issues/new?title=Community%20showcase%20submission',
    media: {
      type: 'video',
      src: '',
      alt: 'Reserved space for a community project image or video',
    },
  },
  {
    title: 'An idea made interactive',
    description:
      'From visual programming to system maps, this carousel is ready for projects of every shape.',
    authorHandle: '@author_handle',
    href: 'https://github.com/vyuh-tech/vyuh_node_flow/issues/new?title=Community%20showcase%20submission',
    media: {
      type: 'image',
      src: '',
      alt: 'Reserved space for a community project image or video',
    },
  },
];

const isPlaceholder = computed(() => props.projects.length === 0);
const visibleProjects = computed(() =>
  isPlaceholder.value ? placeholderProjects : props.projects,
);

function updateActiveIndex() {
  if (!track.value) return;

  const firstCard = track.value.querySelector<HTMLElement>('[data-project-card]');
  if (!firstCard) return;

  const styles = window.getComputedStyle(track.value);
  const gap = Number.parseFloat(styles.columnGap || styles.gap || '0');
  const cardWidth = firstCard.offsetWidth + gap;
  activeIndex.value = Math.min(
    visibleProjects.value.length - 1,
    Math.max(0, Math.round(track.value.scrollLeft / cardWidth)),
  );
}

function move(direction: -1 | 1) {
  if (!track.value) return;

  const firstCard = track.value.querySelector<HTMLElement>('[data-project-card]');
  if (!firstCard) return;

  const styles = window.getComputedStyle(track.value);
  const gap = Number.parseFloat(styles.columnGap || styles.gap || '0');
  const prefersReducedMotion = window.matchMedia(
    '(prefers-reduced-motion: reduce)',
  ).matches;

  track.value.scrollBy({
    left: direction * (firstCard.offsetWidth + gap),
    behavior: prefersReducedMotion ? 'auto' : 'smooth',
  });
}

function goTo(index: number) {
  if (!track.value) return;

  const firstCard = track.value.querySelector<HTMLElement>('[data-project-card]');
  if (!firstCard) return;

  const styles = window.getComputedStyle(track.value);
  const gap = Number.parseFloat(styles.columnGap || styles.gap || '0');
  track.value.scrollTo({left: index * (firstCard.offsetWidth + gap)});
}

onMounted(() => nextTick(updateActiveIndex));
</script>

<template>
  <div class="community-showcase">
    <div
      ref="track"
      class="community-track"
      role="region"
      aria-label="Community projects carousel"
      tabindex="0"
      @scroll.passive="updateActiveIndex"
    >
      <article
        v-for="(project, index) in visibleProjects"
        :key="`${project.authorHandle}-${project.title}`"
        class="community-card"
        data-project-card
      >
        <div class="community-media">
          <video
            v-if="project.media.type === 'video' && project.media.src"
            :src="project.media.src"
            :poster="project.media.poster"
            :aria-label="project.media.alt"
            controls
            muted
            playsinline
            preload="metadata"
          />
          <img
            v-else-if="project.media.src"
            :src="project.media.src"
            :alt="project.media.alt"
            loading="lazy"
          />
          <div v-else class="community-media-placeholder" aria-hidden="true">
            <div class="placeholder-node placeholder-node-a" />
            <div class="placeholder-node placeholder-node-b" />
            <div class="placeholder-node placeholder-node-c" />
            <svg viewBox="0 0 480 280" preserveAspectRatio="none">
              <path d="M92 94 C 184 94, 160 190, 258 190" />
              <path d="M258 190 C 344 190, 316 98, 400 98" />
            </svg>
            <span>
              <Icon
                :icon="project.media.type === 'video' ? 'ph:play-fill' : 'ph:image-fill'"
              />
              {{ project.media.type === 'video' ? 'Video' : 'Image' }}
            </span>
          </div>
          <span v-if="isPlaceholder" class="community-status">Reserved</span>
          <span class="community-count">{{ String(index + 1).padStart(2, '0') }}</span>
        </div>

        <div class="community-copy">
          <a
            v-if="!isPlaceholder"
            class="community-author"
            :href="`https://x.com/${project.authorHandle.replace('@', '')}`"
            target="_blank"
            rel="noopener noreferrer"
          >
            <Icon icon="simple-icons:x" />
            {{ project.authorHandle }}
          </a>
          <span v-else class="community-author">
            <Icon icon="simple-icons:x" />
            {{ project.authorHandle }}
          </span>

          <h3>{{ project.title }}</h3>
          <p>{{ project.description }}</p>

          <a
            v-if="!isPlaceholder"
            class="community-link"
            :href="project.href"
            target="_blank"
            rel="noopener noreferrer"
          >
            Explore the project
            <Icon icon="ph:arrow-up-right-bold" />
          </a>
        </div>
      </article>
    </div>

    <div class="community-controls">
      <div
        v-if="visibleProjects.length > 3"
        class="community-dots"
        aria-label="Choose a carousel slide"
      >
        <button
          v-for="(_, index) in visibleProjects"
          :key="index"
          type="button"
          :class="{active: activeIndex === index}"
          :aria-label="`Go to project ${index + 1}`"
          :aria-current="activeIndex === index ? 'true' : undefined"
          @click="goTo(index)"
        />
      </div>
      <div class="community-arrows">
        <button type="button" aria-label="Previous project" @click="move(-1)">
          <Icon icon="ph:arrow-left-bold" />
        </button>
        <button type="button" aria-label="Next project" @click="move(1)">
          <Icon icon="ph:arrow-right-bold" />
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
@reference "../style.css";

.community-showcase {
  @apply mt-12;
}

.community-track {
  @apply grid grid-flow-col gap-5 overflow-x-auto pt-1 pb-4 snap-x snap-mandatory;
  grid-auto-columns: minmax(22rem, 42%);
  scrollbar-width: none;
  overscroll-behavior-inline: contain;
}

.community-track::-webkit-scrollbar {
  display: none;
}

.community-track:focus-visible {
  @apply outline-2 outline-offset-4 outline-blue-600 rounded-2xl;
}

.community-card {
  @apply min-w-0 overflow-hidden rounded-2xl border border-slate-200 bg-white snap-start;
  @apply dark:border-zinc-700 dark:bg-zinc-900;
  transition: transform 160ms var(--vn-ease-out), border-color 160ms ease-out, box-shadow 160ms ease-out;
}

.community-card:hover,
.community-card:focus-within {
  @apply -translate-y-1 border-blue-600/35 shadow-lg;
  @apply dark:border-blue-400/35;
}

.community-media {
  @apply relative aspect-[16/10] overflow-hidden bg-slate-100;
  @apply dark:bg-zinc-800;
}

.community-media img,
.community-media video {
  @apply size-full object-cover;
}

.community-media img {
  transition: transform 220ms var(--vn-ease-out);
}

.community-card:hover .community-media img,
.community-card:focus-within .community-media img {
  transform: scale(1.015);
}

.community-media-placeholder {
  @apply relative size-full overflow-hidden bg-slate-950;
}

.community-media-placeholder svg {
  @apply absolute inset-0 size-full;
}

.community-media-placeholder path {
  fill: none;
  stroke: #3b82f6;
  stroke-width: 2;
  vector-effect: non-scaling-stroke;
}

.community-media-placeholder span {
  @apply absolute bottom-4 left-4 inline-flex items-center gap-2 rounded-full bg-white px-3 py-1.5 text-xs font-semibold text-slate-900;
}

.community-media-placeholder span svg {
  @apply static inset-auto size-3.5 shrink-0;
}

.placeholder-node {
  @apply absolute z-10 h-12 rounded-lg border border-slate-600 bg-slate-800;
}

.placeholder-node::after {
  content: '';
  @apply absolute -right-1.5 top-1/2 size-3 -translate-y-1/2 rounded-full border-2 border-slate-950 bg-blue-500;
}

.placeholder-node-a {
  @apply left-[8%] top-[25%] w-[22%];
}

.placeholder-node-b {
  @apply left-[48%] top-[58%] w-[22%];
}

.placeholder-node-c {
  @apply right-[8%] top-[27%] w-[18%];
}

.community-status,
.community-count {
  @apply absolute top-4 rounded-full border border-white/20 bg-slate-950/80 px-3 py-1 text-xs font-semibold text-white;
}

.community-status {
  @apply left-4;
}

.community-count {
  @apply right-4 font-mono tabular-nums;
}

.community-copy {
  @apply flex min-h-64 flex-col p-6;
}

.community-author {
  @apply mb-4 inline-flex w-fit items-center gap-2 text-sm font-semibold text-blue-700 no-underline;
  @apply dark:text-blue-400;
}

.community-copy h3 {
  @apply m-0 text-balance text-2xl font-bold leading-tight text-slate-950;
  @apply dark:text-zinc-50;
}

.community-copy p {
  @apply mt-3 mb-6 text-pretty text-sm leading-6 text-slate-600;
  @apply dark:text-zinc-400;
}

.community-link {
  @apply mt-auto inline-flex w-fit items-center gap-2 text-sm font-semibold text-slate-950 no-underline;
  @apply dark:text-zinc-50;
}

.community-link svg {
  transition: transform 160ms ease-out;
}

.community-link:hover svg {
  transform: translate(2px, -2px);
}

.community-controls {
  @apply mt-5 flex items-center justify-between;
}

.community-dots {
  @apply flex gap-2;
}

.community-dots button {
  @apply size-2 rounded-full border-0 bg-slate-300 p-0 cursor-pointer;
  @apply dark:bg-zinc-600;
  transition: transform 160ms ease-out, background-color 160ms ease-out;
}

.community-dots button.active {
  @apply bg-blue-600;
  transform: scale(1.4);
}

.community-arrows {
  @apply ml-auto flex gap-2;
}

.community-arrows button {
  @apply inline-flex size-11 items-center justify-center rounded-full border border-slate-300 bg-white text-slate-900 cursor-pointer;
  @apply dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-50;
  transition: transform 160ms ease-out, border-color 160ms ease-out;
}

.community-arrows button:hover {
  @apply border-blue-600;
  transform: translateY(-2px);
}

.community-dots button:focus-visible,
.community-arrows button:focus-visible,
.community-link:focus-visible,
.community-author:focus-visible {
  @apply outline-2 outline-offset-2 outline-blue-600;
}

@media (max-width: 1023px) {
  .community-track {
    grid-auto-columns: minmax(20rem, 68%);
  }
}

@media (max-width: 639px) {
  .community-track {
    grid-auto-columns: minmax(17rem, 88%);
  }

  .community-copy {
    @apply min-h-60 p-5;
  }
}
</style>
