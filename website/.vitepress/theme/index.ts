import DefaultTheme from 'vitepress/theme';
import type { Theme } from 'vitepress';
import CustomHome from './CustomHome.vue';
import PackageShields from './components/PackageShields.vue';
import PubVersion from './components/PubVersion.vue';
import './custom.css';

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('CustomHome', CustomHome);
    app.component('PackageShields', PackageShields);
    app.component('PubVersion', PubVersion);
  },
} satisfies Theme;
