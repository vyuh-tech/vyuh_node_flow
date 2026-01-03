import { ref, onMounted, onUnmounted, type Ref } from 'vue';

/**
 * Composable to track element visibility using Intersection Observer.
 * Useful for pausing animations when components are off-screen.
 *
 * @param elementRef - Ref to the DOM element to observe
 * @param options - IntersectionObserver options
 * @returns isVisible - Reactive boolean indicating visibility
 */
export function useVisibility(
  elementRef: Ref<HTMLElement | null>,
  options: IntersectionObserverInit = {}
) {
  const isVisible = ref(false);
  let observer: IntersectionObserver | null = null;

  const defaultOptions: IntersectionObserverInit = {
    rootMargin: '50px', // Small buffer for smoother transitions
    threshold: 0,
    ...options,
  };

  onMounted(() => {
    observer = new IntersectionObserver((entries) => {
      isVisible.value = entries[0].isIntersecting;
    }, defaultOptions);

    if (elementRef.value) {
      observer.observe(elementRef.value);
    }
  });

  onUnmounted(() => {
    observer?.disconnect();
  });

  return { isVisible };
}
